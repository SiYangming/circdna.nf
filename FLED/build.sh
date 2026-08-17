#!/bin/bash
# Install FLED plus deps that are missing from the conda channels:
#   - pyspoa 0.0.6 is pip-only
#   - pysam 0.22 has no py39 conda build, so pin the runtime to py38
#   - FLED imports the legacy `progressbar` module (the conda `progressbar2`
#     package pulls a python_utils incompatible with python 3.8)
# The build sandbox has no network, so everything is installed from the
# vendored wheels/sdist under ./wheels.
${PREFIX}/bin/pip install --no-deps --no-build-isolation ./wheels/pyspoa-0.0.6-cp38-cp38-manylinux2010_x86_64.whl
${PREFIX}/bin/pip install --no-deps --no-build-isolation ./wheels/pysam-0.22.0-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
${PREFIX}/bin/pip install --no-deps --no-build-isolation ./wheels/progressbar-2.5.tar.gz
${PREFIX}/bin/python -m pip install --no-deps --no-build-isolation .
