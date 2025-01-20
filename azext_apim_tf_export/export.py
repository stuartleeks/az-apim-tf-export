from knack.help_files import helps

from azure.mgmt.apimanagement import ApiManagementClient

from azext_apim_tf_export.config import load_config
from azext_apim_tf_export.exporter import Exporter

helps['apim export-to-terraform'] = """
    type: command
    short-summary: Exports APIM APIs and Products to Terraform (Experimental!)
"""

# https://github.com/Azure/azure-cli/blob/main/doc/authoring_command_modules/authoring_commands.md#write-the-command-loader


def export_to_terraform(client: ApiManagementClient, resource_group_name, service_name, output_folder, config):
    print('** NOTE: this extension is experimental, not supported, and may not work as expected! **')
    print('Exporting API Management configuration to Terraform...')

    config = load_config(config)

    exporter = Exporter(client, resource_group_name,
                        service_name, output_folder, config)
    exporter()
