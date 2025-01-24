
import json
from typing import List, TypedDict
import yaml


class ApiConfig(TypedDict):
    environments: List[str]

class ProductConfig(TypedDict):
    environments: List[str]

class Config(TypedDict):
    apis: dict[str, ApiConfig]
    products: dict[str, ProductConfig]

def load_config(config_path: str) -> Config:
    if config_path.endswith('.json'):
        with open(config_path, 'r') as config_file:
            config = json.load(config_file)
    elif config_path.endswith('.yml') or config_path.endswith('.yaml'):
        with open(config_path, 'r') as config_file:
            config = yaml.safe_load(config_file)
    else:
        raise ValueError("Unsupported config file format. Only .json, .yml, and .yaml are supported.")

    # TODO - validate config

    return config