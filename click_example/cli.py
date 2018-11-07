#! /usr/bin/env python
# -*- coding: utf-8 -*-

""" Commandline Interface Module

.. moduleauthor:: Timothy Helton <timothy.j.helton@gmail.com>
"""
import logging
import time

import click


@click.command()
@click.argument('number')
@click.option('-q', '--quiet', is_flag=True, multiple=True)
@click.option('-v', '--verbose', is_flag=True, multiple=True)
def count(number: int, quiet, verbose):
    """
    Display progressbar while counting to a user provided number.
    """
    click.clear()
    logging_level = logging.INFO + 10 * len(quiet) - 10 * len(verbose)
    logging.basicConfig(level=logging_level)
    with click.progressbar(range(int(number)), label='Counting') as bar:
        for n in bar:
            click.secho(f'\n\nProcessing: {n}', fg='green')
            time.sleep(0.5)


if __name__ == '__main__':
    pass