# Python3 and rrdtool squashfs overlay for info-beamer
An info-beamer squashfs overlay for python3 and rrdtool support.

This branch is part of the info-beamer package "meteorology info screen".

This package bundles a Python3 runtime and rrdtool into a
[overlay.squashfs file](https://info-beamer.com/doc/package-services#customoverlay).
info-beamer OS will detect this file and mount it as an overlay into the
package service's filesystem. This makes Python3.11 available for use in
your `service`.

The first time python3 is invoked it will precompile some python modules
and save the result in the package's
[scratch directory](https://info-beamer.com/doc/package-services#scratchdirectory).

## Using in your own package

1. Copy `overlay.squashfs` into your package. 
1. Invoke `python3` as your package service's interpreter.

## Building this package

The included build-overlay and Makefile can be used to create the included
`overlay.squashfs`. Right now Raspbian OS (bookworm) binary packages are used
instead of building its own. On Raspbian OS use the `download-packages.sh`
in directory `debs` to download all needed packages.

Then invoke `make` and you'll end up with a new version of `overlay.squashfs`.

