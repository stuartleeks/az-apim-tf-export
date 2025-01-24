from .export import export_to_terraform
import importlib

from azure.cli.core import AzCommandsLoader
from azure.cli.command_modules.apim._client_factory import cf_apim

# Imported modules must implement load_command_table and load_arguments
module_names = ['export']

modules = list(map(importlib.import_module, map(
    lambda m: '{}.{}'.format('azext_apim_tf_export', m), module_names)))


__all__ = ['export_to_terraform']


class ApimExportCommandsLoader(AzCommandsLoader):

    def __init__(self, cli_ctx=None):
        from azure.cli.core.commands import CliCommandType
        custom_type = CliCommandType(
            operations_tmpl='azext_apim_tf_export#{}', client_factory=cf_apim)
        super(ApimExportCommandsLoader, self).__init__(cli_ctx=cli_ctx,
                                                       custom_command_type=custom_type)

    def load_command_table(self, args):
        with self.command_group('apim') as g:
            g.custom_command('export-to-terraform', 'export_to_terraform')

        for m in modules:
            if hasattr(m, 'load_command_table'):
                m.load_command_table(self, args)

        return self.command_table

    def load_arguments(self, command):
        with self.argument_context('apim export-to-terraform') as c:
            c.argument('service_name',
                       options_list=['--service-name'],
                       help='Name of the API Management service'
                       )
            c.argument(
                'config',
                options_list=['--config'],
                help='Path to the config file (JSON or YAML)'
            )
            c.argument(
                'output_folder',
                options_list=['--output-folder'],
                help='Path to the output folder (will be deleted and recreated as part of the export process)'
            )
            c.argument(
                "yes",
                options_list=["--yes", "-y"],
                help="Do not prompt for confirmation.",
                action="store_true",
            )

        for m in modules:
            if hasattr(m, 'load_arguments'):
                m.load_arguments(self, command)


COMMAND_LOADER_CLS = ApimExportCommandsLoader


# class ApimExportCommandsLoader(AzCommandsLoader):

#     def __init__(self, cli_ctx=None):
#         from azure.cli.core.commands import CliCommandType
#         custom_type = CliCommandType(operations_tmpl='azext_apim_tf_export#{}')
#         super(ApimExportCommandsLoader, self).__init__(cli_ctx=cli_ctx,
#                                                        custom_command_type=custom_type)

#     def load_command_table(self, args):
#         with self.command_group('apim') as g:
#             g.custom_command('export-to-terraform', 'export')
#         return self.command_table

#     def load_arguments(self, _):
#         pass

# COMMAND_LOADER_CLS = ApimExportCommandsLoader
