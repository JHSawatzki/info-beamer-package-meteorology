#!/bin/sh
cat debs-to-download.txt | xargs --verbose apt-get download