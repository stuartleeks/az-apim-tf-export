import fnmatch
import json
import os
import shutil

from jinja2 import Environment, PackageLoader, select_autoescape

from azure.mgmt.apimanagement import ApiManagementClient
from azure.core.exceptions import ResourceNotFoundError

from azext_apim_tf_export.config import Config
from azext_apim_tf_export.helpers import last_segment, quote, to_terraform_bool, to_terraform_id

# TODO - split progress output from the exporter


class Exporter:
    def __init__(
            self,
            client: ApiManagementClient,
            resource_group_name: str,
            service_name: str,
            output_folder: str,
            config: Config
    ):
        self.client = client
        self.resource_group_name = resource_group_name
        self.service_name = service_name
        self.output_folder = output_folder
        self.config = config

        jinjaEnv = Environment(
            loader=PackageLoader("azext_apim_tf_export", "templates"),
            autoescape=select_autoescape()
        )
        jinjaEnv.filters["quote"] = quote
        jinjaEnv.filters["to_terraform_id"] = to_terraform_id
        jinjaEnv.filters["last_segment"] = last_segment
        jinjaEnv.filters["to_terraform_bool"] = to_terraform_bool
        jinjaEnv.filters["str"] = lambda value: str(value)
        jinjaEnv.filters["empty_to_none"] = lambda value: None if value == "" else value

        self.jinjaEnv = jinjaEnv

    def __call__(self):
        self._initialize_output_folder()

        self._export_products()
        api_version_set_environment_map = self._export_apis()
        self._export_api_version_sets(api_version_set_environment_map)

    def _initialize_output_folder(self):
        output_folder = os.path.abspath(self.output_folder)
        if os.path.exists(output_folder):
            shutil.rmtree(output_folder)
        os.makedirs(output_folder)
        os.makedirs(os.path.join(output_folder, "apis"))
        os.makedirs(os.path.join(output_folder, "products"))

        with open(os.path.join(self.output_folder, "README.md"), "w") as f:
            f.write("This folder contains generated API Management configuration - do not manually edit these files as changes will be overwritten.")

        with open(os.path.join(self.output_folder, "main.tf"), "w") as f:
            f.write("""
data "azurerm_api_management" "apim" {
  resource_group_name = var.resource_group_name
  name                = var.api_management_name
}
""")

        with open(os.path.join(self.output_folder, "variables.tf"), "w") as f:
            f.write("""
variable "location" {
  type        = string
  description = "The Azure location in which the deployment is happening"
  default     = "francecentral"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which the resources are deployed"
}

variable "api_management_name"{
  type        = string
  description = "The name of the API Management service"
}

variable "environment" {
  type        = string
  description = "The environment for which the resources are being deployed"
}
""")
            
        with open(os.path.join(self.output_folder, "versions.tf"), "w") as f:
            f.write("""
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.70"
      # configuration_aliases = [azurerm.key_vault]
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">=1.13.1"
    }
  }

  required_version = ">= 1.8"
}
""")

    def _export_products(self):
        """
        Export products to Terraform
        """
        products = self.client.product.list_by_service(
            self.resource_group_name, self.service_name)
        print("\n========== Exporting Products ==========")
        for product in products:
            product_short_id = last_segment(product.id)
            print("Product: " + product_short_id)

            product_environments = self._get_environments_for_product(
                product_short_id)
            if product_environments is None:
                print(f"  No environments - skipping")
                continue
            print(f"  Environments: {product_environments}")

            product_policy_path = self._save_product_policy(product_short_id)

            # print(json.dumps(product.as_dict(), indent=2))

            # Determine the APIs associated with this product
            # and their target environments
            all_product_apis = [a for a in self.client.product_api.list_by_product(
                self.resource_group_name, self.service_name, product_short_id)]

            product_apis = {}
            for product_api in all_product_apis:
                api_short_id = last_segment(product_api.id)
                api_environments = self._get_environments_for_api(api_short_id)
                product_api_environments = list(set(product_environments) & set(api_environments or []))
                if api_environments:
                    product_apis[product_api.id] = product_api_environments

            product_template = self.jinjaEnv.get_template("product.tf")
            with open(os.path.join(self.output_folder, f"product_{to_terraform_id(product_short_id)}.tf"), "w") as f:
                f.write(
                    product_template.render(
                        product=product,
                        environments=product_environments,
                        product_policy_path=product_policy_path,
                        product_apis=product_apis
                    )
                )

    def _export_apis(self) -> dict[str, set[str]]:
        """
        Export APIs to Terraform
        Returns a map of API Version Set ID to environments (key: version set id, value: set of environments)
        """

        # key - version set id, value - set of environments
        api_version_set_environment_map = {}

        apis = self.client.api.list_by_service(
            self.resource_group_name, self.service_name)
        print("\n========== Exporting APIs ==========")
        for api in apis:
            api_short_id = last_segment(api.id)
            print("API: " + api_short_id)

            api_environments = self._get_environments_for_api(api_short_id)
            if api_environments is None:
                print(f"  No environments - skipping")
                continue
            print(f"  Environments: {api_environments}")

            if api.api_revision != "1":
                print("!! This API uses revisions which are not currently supported - exiting")
                exit(-1)

            if api.api_version_set_id:
                # merge the environments from the API and the API Version Set
                api_version_set_environments = api_version_set_environment_map.get(
                    api.api_version_set_id, set())
                api_version_set_environments = api_version_set_environments | set(
                    api_environments)
                api_version_set_environment_map[api.api_version_set_id] = api_version_set_environments

            api_policy_path = self._save_api_policy(api_short_id)

            operations = [o for o in self.client.api_operation.list_by_api(
                self.resource_group_name, self.service_name, api_short_id)]
            operation_policy_paths = {}  # Key - operation id, value - policy path

            # save operation policies
            for operation in operations:
                operation_short_id = last_segment(operation.id)
                print("  Operation: " + operation_short_id)
                operation_policy_path = self._save_api_operation_policy(
                    api_short_id, operation_short_id)
                if operation_policy_path:
                    operation_policy_paths[operation.id] = operation_policy_path

            # save schemas
            api_schemas = [s for s in self.client.api_schema.list_by_api(
                self.resource_group_name, self.service_name, api_short_id)]
            api_schema_paths = {}  # Key - schema id, value - schema path
            for schema in api_schemas:
                schema_short_id = last_segment(schema.id)
                print("  Schema: " + schema_short_id)
                schema_relative_path = self._save_schema(
                    api_short_id, schema_short_id)
                api_schema_paths[schema.id] = schema_relative_path

            diagnostics = [d for d in self.client.api_diagnostic.list_by_service(
                self.resource_group_name, self.service_name, api_short_id)]

            # write api terraform
            api_template = self.jinjaEnv.get_template("api.tf")
            with open(os.path.join(self.output_folder, f"api_{to_terraform_id(api_short_id)}.tf"), "w") as f:
                f.write(
                    api_template.render(
                        api=api,
                        operations=operations,
                        environments=api_environments,
                        api_policy_path=api_policy_path,
                        operation_policy_paths=operation_policy_paths,
                        schemas=api_schemas,
                        schema_paths=api_schema_paths,
                        diagnostics=diagnostics,
                    )
                )

        return api_version_set_environment_map

    def _export_api_version_sets(
            self,
            api_version_set_environment_map: dict[str, set[str]]):
        """
        Export API Version Sets to Terraform
        """
        all_api_version_sets = [
            vs
            for vs in self.client.api_version_set.list_by_service(
                self.resource_group_name, self.service_name
            )]
        print("\n========== Exporting API Version Sets ==========")
        for api_version_set in all_api_version_sets:
            api_version_set_short_id = last_segment(api_version_set.id)
            print("API Version Set: " + api_version_set_short_id)

            api_version_set_environments = api_version_set_environment_map.get(
                api_version_set.id, None)
            if api_version_set_environments is None:
                print(f"  No environments - skipping")
                continue
            api_version_set_environments = list(api_version_set_environments)
            print(f"  Environments: {api_version_set_environments}")

            api_version_set_template = self.jinjaEnv.get_template(
                "api_version_set.tf")
            with open(os.path.join(self.output_folder, f"api_version_set_{to_terraform_id(api_version_set_short_id)}.tf"), "w") as f:
                f.write(
                    api_version_set_template.render(
                        api_version_set=api_version_set,
                        environments=api_version_set_environments
                    )
                )

    def _get_environments_for_api(self, id):
        apis = self.config['apis']

        api = apis.get(id, None)
        if api:
            return api['environments']

        # No exact match, try wildcard
        for key in apis.keys():
            if fnmatch.fnmatch(id, key):
                return apis[key]['environments']

        return None

    def _get_environments_for_product(self, id):
        products = self.config['products']

        product = products.get(id, None)
        if product:
            return product['environments']

        # No exact match, try wildcard
        for key in products.keys():
            if fnmatch.fnmatch(id, key):
                return products[key]['environments']

        return None

    def _save_product_policy(self, product_id):
        """Save the Product policy to a file and return the path (or None if not policy)"""
        try:
            policy = self.client.product_policy.get(
                self.resource_group_name,
                self.service_name,
                product_id,
                "policy",
                format="rawxml"
            )
            relative_policy_path = os.path.join(
                "products", f"{to_terraform_id(product_id)}_policy.xml")
            policy_path = os.path.join(
                self.output_folder, relative_policy_path)
            with open(policy_path, "w") as f:
                f.write(policy.value)
        except ResourceNotFoundError as e:
            relative_policy_path = None

        return relative_policy_path

    def _save_api_policy(self, api_id):
        """Save the API policy to a file and return the path (or None if not policy)"""
        try:
            policy = self.client.api_policy.get(
                self.resource_group_name,
                self.service_name,
                api_id,
                "policy",
                format="rawxml"
            )
            relative_policy_path = os.path.join(
                "apis", f"{to_terraform_id(api_id)}_policy.xml")
            policy_path = os.path.join(
                self.output_folder, relative_policy_path)
            with open(policy_path, "w") as f:
                f.write(policy.value)
        except ResourceNotFoundError as e:
            relative_policy_path = None

        return relative_policy_path

    def _save_api_operation_policy(self, api_id, operation_id):
        """Save the API operation policy to a file and return the path (or None if not policy)"""
        try:
            policy = self.client.api_operation_policy.get(
                self.resource_group_name,
                self.service_name,
                api_id,
                operation_id,
                "policy",
                format="rawxml"
            )
            relative_policy_path = os.path.join(
                "apis", f"{to_terraform_id(api_id)}_{to_terraform_id(operation_id)}_policy.xml")
            policy_path = os.path.join(
                self.output_folder, relative_policy_path)
            with open(policy_path, "w") as f:
                f.write(policy.value)
        except ResourceNotFoundError as e:
            relative_policy_path = None

        return relative_policy_path

    def _save_schema(self, api_id, schema_id):
        # list doesn't get full schema so get individual schema
        schema = self.client.api_schema.get(
            self.resource_group_name, self.service_name, api_id, schema_id,
            api_version="2021-08-01")
        schema_relative_path = os.path.join(
            "apis", f"{to_terraform_id(api_id)}_schema_{to_terraform_id(schema_id)}.json")
        schema_path = os.path.join(self.output_folder, schema_relative_path)

        with open(schema_path, "w") as f:
            f.write(json.dumps(schema.components, indent=2))
        return schema_relative_path
