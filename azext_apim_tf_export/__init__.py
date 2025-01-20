from knack.help_files import helps

from azure.cli.core import AzCommandsLoader
# from azure.cli.core.command_modules.apim import apim_get

helps['apim export-to-terraform'] = """
    type: command
    short-summary: Exports APIM APIs and Products to Terraform
"""

# https://github.com/Azure/azure-cli/blob/main/doc/authoring_command_modules/authoring_commands.md#write-the-command-loader

def export(resource_group_name, service_name, output_folder):
    print('Exporting API Management configuration to Terraform')
    print('Resource Group: ' + resource_group_name)
    print('Service Name: ' + service_name)
    print('Output Folder: ' + output_folder)

class ApimExportCommandsLoader(AzCommandsLoader):

    def __init__(self, cli_ctx=None):
        from azure.cli.core.commands import CliCommandType
        custom_type = CliCommandType(operations_tmpl='azext_apim_tf_export#{}')
        super(ApimExportCommandsLoader, self).__init__(cli_ctx=cli_ctx,
                                                       custom_command_type=custom_type)

    def load_command_table(self, args):
        with self.command_group('apim') as g:
            g.custom_command('export-to-terraform', 'export')
        return self.command_table

    def load_arguments(self, _):
        pass

COMMAND_LOADER_CLS = ApimExportCommandsLoader
