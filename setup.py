from codecs import open
from setuptools import setup, find_packages

VERSION = "0.0.1"

CLASSIFIERS = [
    'Development Status :: 4 - Beta',
    'Intended Audience :: Developers',
    'Intended Audience :: System Administrators',
    'Programming Language :: Python',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.4',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
    'License :: OSI Approved :: MIT License',
]

DEPENDENCIES = []

setup(
    name='apim_tf_export',
    version=VERSION,
    description='Export API Management configuration to Terraform',
    long_description='An extension to export API Management API and Product configuration to Terraform',
    license='MIT',
    author='',
    author_email='stuartle@microsoft.com',
    url='https://github.com/stuartleeks/apim_tf_export',
    classifiers=CLASSIFIERS,
    packages=find_packages(),
    install_requires=DEPENDENCIES
)