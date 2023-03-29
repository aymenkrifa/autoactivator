import os
from typing import List
from setuptools import find_packages, setup


def _parse_requirements(path: str) -> List[str]:
    """Returns content of given requirements file."""
    with open(os.path.join(path)) as f:
        return [
            line.rstrip() for line in f if not (line.isspace() or line.startswith("#"))
        ]


_PACKAGE_DIR = os.path.dirname(os.path.abspath(__file__))

setup(
    name="autoactivator",
    packages=find_packages(),
    version="0.1.0",
    description="",
    author="Aymen Krifa",
    install_requires=_parse_requirements(
        os.path.join(_PACKAGE_DIR, "requirements.txt")
    ),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Operating System :: POSIX :: Linux",
    ],
)