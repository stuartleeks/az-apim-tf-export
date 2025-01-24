from knack.help_files import helps
from knack.prompting import prompt_y_n

from azure.mgmt.apimanagement import ApiManagementClient

from azext_apim_tf_export.config import ApiConfig, Config, ProductConfig, load_config
from azext_apim_tf_export.exporter import Exporter

helps['apim export-to-terraform'] = """
    type: command
    short-summary: Exports APIM APIs and Products to Terraform (Experimental, not supported!)
"""

# https://github.com/Azure/azure-cli/blob/main/doc/authoring_command_modules/authoring_commands.md#write-the-command-loader


def export_to_terraform(
        client: ApiManagementClient,
        resource_group_name: str,
        service_name: str,
        output_folder: str,
        config : str | None = None,
        yes: bool = False):
    print('** NOTE: this extension is experimental, not supported, and may not work as expected! **')

    msg = 'WARNING: This will delete the output folder and all its contents. Are you sure you want to continue? (y/n)'
    if not yes and not prompt_y_n():
        return None
    
    print('Exporting API Management configuration to Terraform...')

    if config:
        config = load_config(config)
    else:
        # Create default config
        print("Using default config (export all APIs and Products)")
        config = Config(
            apis={"*": ApiConfig(environments=["all"])},
            products={"*": ProductConfig(environments=["all"])},
        )

    exporter = Exporter(client, resource_group_name,
                        service_name, output_folder, config)
    exporter()
