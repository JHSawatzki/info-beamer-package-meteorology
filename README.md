# info-beamer-package-meteorology
A meteorology info screen for info-beamer

[![Import](https://cdn.infobeamer.com/s/img/import.png)](https://info-beamer.com/use?url=https://github.com/JHSawatzki/info-beamer-package-meteorology)

## TODO
 * Add more sensor types
 * Cut off strings that are too long
 * Handle connection Timeouts correctly
 * and more... see TODO comments in source...

## Changelog

### Version 0.4.0

 * Fixed changing order of sensors
 * Addded pagination for larger sensor setups
   The number of sensors to be displayed per page is configurable, but may be overriden by the actual screen limitations regarding available space.
   Pages are periodically switched in a configurable time interval
 * Added support for storage and display of historic data using rrdtool (loaded via squashfs overlay)
 * Switched to python3 using squashfs overlay

### Version 0.3.5

 * Updated infobeamer hosted API
 * Added support for sensor SHT3X

### Version 0.3.0

 * Display of more than one sensor at a time possible
 * Multi threaded sensor data requests

### Version 0.2.0

 * Added options to control what information will be shown

### Version 0.1.0

 * First alpha release, Ouput for one sensor is working.
 * Only ESP8266 Firmware Tasmota with template Sonoff TH and SI7021 sensor currently supported

