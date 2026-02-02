from __future__ import annotations

import json
import os
import random
import uuid
from pprint import pprint
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any, Literal, TypedDict

import boto3


SubmissionStatus = Literal["submitted", "draft", "rejected", "archived"]

WaterFilterType = Literal["none", "candle", "ceramic", "ro", "biosand", "other"]

PrimaryWaterSource = Literal[

    "piped", "protected_well", "unprotected_well", "spring", "river", "tanker", "other"
]

Sex = Literal["male", "female", "other"]

WaterSourceType = Literal["tapstand", "handpump", "spring", "well", "river_intake", "other"]


class Member(TypedDict):
    household_id: str
    submission_id: str
    member_index: int
    member_name: str
    sex: Sex
    age_years: int
    had_diarrhoea_14d: bool


class Household(TypedDict):
    household_id: str
    submission_id: str
    ward_id: str
    household_head_name: str
    phone_last4: str
    hh_size_reported: int
    water_filter_type: WaterFilterType
    primary_water_source: PrimaryWaterSource
    has_toilet: bool
    members: list[Member]


class WaterPoint(TypedDict):
    water_point_id: str
    submission_id: str
    ward_id: str
    source_type: WaterSourceType
    functional: bool
    distance_minutes: int
    gps_lat: float
    gps_lon: float


class Submission(TypedDict):
    submission_id: str
    status: SubmissionStatus
    submitted_at: str
    collected_at: str
    enumerator_id: str
    device_id: str
    ward_id: str
    municipality: str
    district: str
    gps_lat: float
    gps_lon: float
    consent: bool

    _loaded_at: str
    _batch_id: str
    _source_file: str
    _is_deleted: bool

    household: Household
    water_point: WaterPoint

@dataclass(frozen=True)
class GeneratorConfig:
    n_households: int = 10
    bad_row_rate: float = 0.12
    max_members_per_household: int = 7

    wards: tuple[str, ...] = ("01", "02", "03", "04", "05", "06", "07", "08", "09")
    municipality_pool: tuple[str, ...] = ("Dhulikhel", "Panauti", "Banepa", "Panchkhal")
    district: str = "Kavrepalanchok"


FIRST_NAMES = (
    "Sita", "Gita", "Maya", "Anita", "Sunita", "Rita", "Bina", "Laxmi", "Nirmala",
    "Ramesh", "Suresh", "Bikash", "Prakash", "Deepak", "Hari", "Krishna", "Nabin",
)

LAST_NAMES = (
    "Ghimire", "Wagle", "Sharma", "Karki", "Thapa", "Adhikari", "Gurung", "Tamang", "Rai",
    "Magar", "Poudel", "Bhattarai", "Shrestha",
)

FILTER_TYPES: tuple[WaterFilterType, ...] = ("none", "candle", "ceramic", "ro", "biosand", "other")

WATER_SOURCES: tuple[PrimaryWaterSource, ...] = (
    "piped", "protected_well", "spring", "unprotected_well", "river", "tanker", "other"
)

WATERPOINT_TYPES: tuple[WaterSourceType, ...] = (
    "tapstand", "handpump", "spring", "well", "river_intake", "other"
)

_s3 = boto3.client("s3")


def _iso(dt: datetime) -> str:
    return dt.isoformat().replace("+00:00", "Z")


def _now_utc() -> datetime:
    return datetime.now(UTC)


def _rand_name() -> str:
    return f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"


def _rand_device_id() -> str:
    return f"android-{random.randint(10_000, 99_999)}"


def _rand_enumerator_id() -> str:
    return f"enum-{random.randint(1001, 1099)}"


def _rand_phone_last4() -> str:
    return f"{random.randint(0, 9999):04d}"


def _rand_gps_nepalish() -> tuple[float, float]:
    lat = round(random.uniform(26.5, 28.8), 6)
    lon = round(random.uniform(80.0, 88.2), 6)
    return lat, lon


def _weighted_bool(p_true: float) -> bool:
    return random.random() < p_true


def _s3_key(prefix: str, now: datetime, batch_id: str) -> str:
    return (
        f"{prefix.rstrip('/')}/"
        f"{now:%Y/%m/%d}/"
        f"wash_submissions_{now:%H%M%S}_{batch_id}.json"
    )

def _inject_bad_data(sub: Submission) -> None:
    """
    Injects a few intentional issues so some records land in staging rejected.
    These are chosen to be typical staging DQ failures.
    """
    case = random.choice(
        [
            "bad_ward",
            "bad_gps",
            "bad_submitted_at",
            "consent_null",
            "phone_bad",
            "hh_size_negative",
            "member_bad_bool_type",
            "waterpoint_distance_negative",
        ]
    )

    if case == "bad_ward":
        sub["ward_id"] = "99"
        sub["household"]["ward_id"] = "99"
        sub["water_point"]["ward_id"] = "99"

    elif case == "bad_gps":
        sub["gps_lat"] = 123.456
        sub["gps_lon"] = 987.654

    elif case == "bad_submitted_at":
        sub["submitted_at"] = "02-02-2026 10:00"  # not ISO 8601

    elif case == "consent_null":
        sub["consent"] = None  # type: ignore[assignment]

    elif case == "phone_bad":
        sub["household"]["phone_last4"] = "12A4"

    elif case == "hh_size_negative":
        sub["household"]["hh_size_reported"] = -3

    elif case == "member_bad_bool_type":
        if sub["household"]["members"]:
            sub["household"]["members"][0]["had_diarrhoea_14d"] = "yes"  # type: ignore[assignment]

    elif case == "waterpoint_distance_negative":
        sub["water_point"]["distance_minutes"] = -5


def _make_members(*, household_id: str, submission_id: str, hh_size: int, max_members: int) -> list[Member]:
    n_members = max(1, min(hh_size, random.randint(2, max_members)))
    out: list[Member] = []

    for idx in range(1, n_members + 1):
        age = random.randint(0, 80)
        had_diarrhoea = _weighted_bool(0.12 if age < 5 else 0.08)
        out.append(
            {
                "household_id": household_id,
                "submission_id": submission_id,
                "member_index": idx,
                "member_name": _rand_name(),
                "sex": random.choice(["male", "female", "other"]),
                "age_years": age,
                "had_diarrhoea_14d": had_diarrhoea,
            }
        )

    return out

# generator

def generate_submissions(
    *,
    cfg: GeneratorConfig,
    batch_id: str,
    loaded_at: str,
    source_file: str,
) -> list[Submission]:
    out: list[Submission] = []

    for _ in range(cfg.n_households):
        submission_id = str(uuid.uuid4())
        household_id = str(uuid.uuid4())
        ward_id = random.choice(cfg.wards)
        municipality = random.choice(cfg.municipality_pool)

        s_lat, s_lon = _rand_gps_nepalish()

        collected_at = _iso(_now_utc() - timedelta(minutes=random.randint(10, 240)))
        submitted_at = _iso(_now_utc() - timedelta(minutes=random.randint(0, 60)))

        hh_size = random.randint(2, 9)

        household: Household = {
            "household_id": household_id,
            "submission_id": submission_id,
            "ward_id": ward_id,
            "household_head_name": _rand_name(),
            "phone_last4": _rand_phone_last4(),
            "hh_size_reported": hh_size,
            "water_filter_type": random.choices(
                population=list(FILTER_TYPES),
                weights=[55, 20, 10, 5, 4, 6],
                k=1,
            )[0],
            "primary_water_source": random.choices(
                population=list(WATER_SOURCES),
                weights=[30, 18, 16, 12, 10, 8, 6],
                k=1,
            )[0],
            "has_toilet": _weighted_bool(0.78),
            "members": _make_members(
                household_id=household_id,
                submission_id=submission_id,
                hh_size=hh_size,
                max_members=cfg.max_members_per_household,
            ),
        }

        wp_lat = round(s_lat + random.uniform(-0.005, 0.005), 6)
        wp_lon = round(s_lon + random.uniform(-0.005, 0.005), 6)

        water_point: WaterPoint = {
            "water_point_id": str(uuid.uuid4()),
            "submission_id": submission_id,
            "ward_id": ward_id,
            "source_type": random.choice(WATERPOINT_TYPES),
            "functional": _weighted_bool(0.86),
            "distance_minutes": random.randint(2, 45),
            "gps_lat": wp_lat,
            "gps_lon": wp_lon,
        }

        sub: Submission = {
            "submission_id": submission_id,
            "status": "submitted",
            "submitted_at": submitted_at,
            "collected_at": collected_at,
            "enumerator_id": _rand_enumerator_id(),
            "device_id": _rand_device_id(),
            "ward_id": ward_id,
            "municipality": municipality,
            "district": cfg.district,
            "gps_lat": s_lat,
            "gps_lon": s_lon,
            "consent": _weighted_bool(0.92),
            "_loaded_at": loaded_at,
            "_batch_id": batch_id,
            "_source_file": source_file,
            "_is_deleted": False,
            "household": household,
            "water_point": water_point,
        }

        if random.random() < cfg.bad_row_rate:
            _inject_bad_data(sub)

        out.append(sub)

    return out


# lambda handler

def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """
    Env vars:
      - RAW_BUCKET (required)
      - RAW_PREFIX (optional, default: raw/)
      - N_HOUSEHOLDS (optional, default: 10)
      - BAD_ROW_RATE (optional, default: 0.12)
      - RNG_SEED (optional)
    """

    bucket = os.environ["RAW_BUCKET"]
    prefix = os.environ.get("RAW_PREFIX", "raw/")

    n_households = int(os.environ.get("N_HOUSEHOLDS", "10"))
    bad_rate = float(os.environ.get("BAD_ROW_RATE", "0.12"))

    seed = os.environ.get("RNG_SEED")
    if seed is not None and seed.strip():
        random.seed(seed)

    now = _now_utc()
    batch_id = str(uuid.uuid4())[:10]
    key = _s3_key(prefix, now, batch_id)


    loaded_at = _iso(now)

    submissions = generate_submissions(
        cfg=GeneratorConfig(n_households=n_households, bad_row_rate=bad_rate),
        batch_id=batch_id,
        loaded_at=loaded_at,
        source_file=key,
    )

    body = json.dumps(
        {
            "batch_meta": {
                "generated_at": loaded_at,
                "batch_id": batch_id,
                "n_households": n_households,
                "bad_row_rate": bad_rate,
            },
            "submissions": submissions,
        },
        ensure_ascii=False,
    ).encode("utf-8")

    _s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=body,
        ContentType="application/json",
    )

    return {
        "status": "ok",
        "bucket": bucket,
        "key": key,
        "batch_id": batch_id,
        "n_households": n_households,
        "bad_row_rate": bad_rate,
    }