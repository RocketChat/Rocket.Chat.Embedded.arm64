"""This plugin is kind of a PoC, not currently being used"""

from snapcraft.plugins.v2 import PluginV2
from snapcraft.internal import errors

import logging
import pathlib
import tempfile
import sys
import os
import time
from typing import Union, Dict, Any, Set, List

# it's a pain having to write logger.debug every time
# so, d
d = logging.getLogger(__name__).debug


class VersionFetchFailureException(errors.SnapcraftException):
    def get_brief(self) -> str:
        return "Failed to run plugin, couldn't fetch version from https://releases.rocket.chat"

    def get_resolution(self) -> str:
        return (
            "explicitely set version via the `version` tag or change release stage via the `release` tag"
            "release: ['stage', 'release-candidate'"
        )


class NoCallFifosException(errors.SnapcraftException):
    def get_brief(self) -> str:
        return (
            "Failed to run plugin, error in build environment generation: "
            "expected one named pipe for snapcraft's internal function call, found none"
        )

    def get_resolution(self) -> str:
        return "use `override-build` and run `snapcraftctl build` from there"


class NoFeedbackFifosException(errors.SnapcraftError):
    def get_brief(self) -> str:
        return (
            "Failed to run plugin, error in build environment generation: "
            "expected one named pipe for snapcraft's internal function feedback, found none"
        )

    def get_resolution(self) -> str:
        return "use `override-build` and run `snapcraftctl build` from there"


class MultipleCallFifosException(errors.SnapcraftException):
    def get_brief(self) -> str:
        return (
            "Failed to run plugin, error in build environment generation:\n"
            "expected one named pipe for snapcraft's internal function call, got {count}\n"
            "{files}"
        ).format(files=self._files, count=len(self._files))

    def get_resolution(self) -> str:
        return "no suggestions for now"

    def __init__(self, files: List[str]) -> None:
        self._files = files


class MultipleFeedbackFifosException(errors.SnapcraftException):
    def get_brief(self) -> str:
        return (
            "Failed to run plugin, error in build environment generation:\n"
            "expected one named pipe for snapcraft's internal function feedback, got {count}\n"
            "{files}"
        ).format(files=self._files, count=len(self._files))

    def get_resolution(self) -> str:
        return "no suggestions for now"

    def __init__(self, files: List[str]) -> None:
        self._files = files


# This is for core20, but lacks access to a lot of system resources unfortunately
# only if I could still access them
class PluginImpl(PluginV2):
    @classmethod
    def get_schema(cls) -> Dict[str, Any]:
        return {
            "$schema": "http://json-schema.org/draft-04/schema#",
            "type": "object",
            "additionalProperties": False,
            "properties": {
                "version": {"type": "string"},
                "release": {"type": "string"},
                "node": {"type": "string"},
            },
        }

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)
        self._partsdir: pathlib.Path = (
            pathlib.Path(os.getcwd()) / ".." / "parts"
        ).resolve()
        self._version: str = self.options.version or self._get_version()
        self._arch: str = os.environ["SNAP_ARCH"]

    def _get_fifo_path_from_glob(
        self,
        startloc: pathlib.Path,
        fifoname: str,
        no_file_exception: Union[NoCallFifosException, NoFeedbackFifosException],
        multiple_file_exception: Union[
            MultipleCallFifosException, MultipleFeedbackFifosException
        ],
    ) -> str:
        globbed = startloc.glob(f"{tempfile.gettempprefix()}*/{fifoname}")
        fifo: str
        _not_be_fifo: pathlib.Path
        try:
            fifo = next(globbed).as_posix()
        except StopIteration:
            raise no_file_exception()
        try:
            _not_be_fifo = next(globbed)
        except StopIteration:
            # this is good for health
            return fifo
        else:
            raise multiple_file_exception(
                [fifo, _not_be_fifo.as_posix(), *[_.as_posix() for _ in globbed]]
            )

    @property
    def call_fifo(self) -> str:
        return self._get_fifo_path_from_glob(
            self._partsdir,
            "function_call",
            NoCallFifosException,
            MultipleCallFifosException,
        )

    @property
    def feedback_fifo(self) -> str:
        return self._get_fifo_path_from_glob(
            self._partsdir,
            "call_feedback",
            NoFeedbackFifosException,
            MultipleFeedbackFifosException,
        )

    @property
    def _download_and_extract_node_archive_command(self) -> str:
        return f"curl -fsSL {self._get_node_uri()} | tar zx --strip-components=1 --"

    @property
    def _download_and_extract_rocketchat_archive_command(self) -> str:
        return (
            f"curl -fsSL https://releases.rocket.chat/{self._version}/download"
            "|"
            "tar zx --strip-components=1 --"
        )

    @property
    def _cd_to_where_package_json_is(self) -> str:
        return "cd programs/server"

    @property
    def _npm_install(self) -> str:
        return "npm i --unsafe-perm"

    @property
    def _cd_to_snapcraft_part_build(self) -> str:
        return "cd $SNAPCRAFT_PART_BUILD"

    @property
    def _copy_to_snapcraft_part_install(self) -> str:
        return "cp . $SNAPCRAFT_PART_INSTALL --dereference -rp"

    def _get_node_uri(self) -> str:
        arch = (
            "x64"
            if self._arch == "amd64"
            else self._arch
            if self._arch == "arm64"
            else None
        )
        if arch is None:
            pass
        return f"https://nodejs.org/dist/v{self.options.node}/node-v{self.options.node}-linux-{arch}.tar.gz"

    def _get_version(self) -> str:
        from urllib import request

        response = request.urlopen(
            f"https://releases.rocket.chat/{self.options.release or 'stable'}/info"
        )
        if response.code != 200:
            raise VersionFetchFailureException()

        import json

        return json.loads(response.read().decode()).get("tag", "latest")

    def _set_snap_version(self) -> None:
        existing_path: str = os.environ["PATH"]
        snapcraft_path: str = f"{os.environ['SNAP']}/bin"
        snapcraftctl_path: str = f"{snapcraft_path}/scriptlet-bin"
        os.spawnvpe(
            os.P_NOWAIT | os.P_NOWAITO,
            "snapcraftctl",
            ["snapcraftctl", "set-version", self._version],
            {
                **os.environ.copy(),
                "SNAPCRAFTCTL_CALL_FIFO": self.call_fifo,
                "SNAPCRAFTCTL_FEEDBACK_FIFO": self.feedback_fifo,
                "SNAPCRAFT_INTERPRETER": sys.executable,
                "PATH": f"{existing_path}:{snapcraft_path}:{snapcraftctl_path}",
            },
        )

    def get_build_snaps(self) -> Set[str]:
        return set()

    def get_build_packages(self) -> Set[str]:
        packages = {"build-essential", "curl"}
        if self._arch == "arm64":
            packages.update({"autoconf", "automake", "libtool"})
        return packages

    def get_build_environment(self) -> Dict[str, str]:
        return {"PATH": "$PATH:$SNAPCRAFT_PART_BUILD/bin"}

    def get_build_commands(self) -> List[str]:
        # push set_version on the stack
        self._set_snap_version()

        # making sure the previous command actually pushes set-version to stack
        d("waiting 5 seconds before build start")
        time.sleep(5)

        return [
            self._download_and_extract_node_archive_command,
            self._download_and_extract_rocketchat_archive_command,
            self._cd_to_where_package_json_is,
            self._npm_install,
            self._cd_to_snapcraft_part_build,
            self._copy_to_snapcraft_part_install,
        ]
