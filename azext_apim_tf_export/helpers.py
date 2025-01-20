import re
from typing import Iterable

def to_terraform_id(id: str) -> str:
    return re.sub(r'[^a-zA-Z0-9_-]', '_', id)

def to_terraform_bool(value: bool) -> str:
	return "true" if value else "false"

def last_segment(id: str) -> str:
    return id.split('/')[-1]


def quote(values: str | Iterable[str]) -> Iterable[str]:
    if values is None:
        return "null"
    if isinstance(values, str):
        return f'"{values}"'
    return map(lambda v: f'"{v}"' if v else "null", values)

