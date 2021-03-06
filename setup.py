#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from codecs import open
import os.path as osp
import re

from setuptools import setup, find_packages


with open('click_example/__init__.py', 'r') as fd:
    version = re.search(r'^__version__\s*=\s*[\'"]([^\'"]*)[\'"]',
                        fd.read(), re.MULTILINE).group(1)

here = osp.abspath(osp.dirname(__file__))
with open(osp.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='click_example',
    version=version,
    description='Modules related to EnterDescriptionHere',
    author='Timothy Helton',
    author_email='timothy.j.helton@gmail.com',
    license='BSD',
    classifiers=[
        'Development Status :: 1 - Planning',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved',
        'Natural Language :: English',
        'Operating System :: OS Independent',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.6',
        'Topic :: Software Development :: Build Tools',
        ],
    keywords='EnterKeywordsHere',
    packages=find_packages(exclude=[
        'data',
        'docker',
        'docs',
        'notebooks',
        'wheels',
        '*tests',
        ]
    ),
    install_requires=[
        'click',
        ],
    extras_require={
        'docs': ['sphinx', 'sphinx_rtd_theme'],
        'notebook': ['jupyter'],
        'test': ['pytest', 'pytest-pep8'],
    },
    package_dir={'click_example': 'click_example'},
    include_package_data=True,
    entry_points={
        'console_scripts': [
            'count=click_example.cli:count',
        ]
    }
)


if __name__ == '__main__':
    pass
