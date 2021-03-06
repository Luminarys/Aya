# Aya

[![Inline docs](http://inch-ci.org/github/Luminarys/Aya.svg)](http://inch-ci.org/github/Luminarys/Aya)
[![Build Status](https://travis-ci.org/Luminarys/Aya.svg)](https://travis-ci.org/Luminarys/Aya)

Aya is a small, fast, and distributed torrent tracker. It is currently is in early alpha, but supports most of the BitTorrent specification along with the IPv6 extension.

### Current features:
* Full public tracker support
* Optional backend driver for use with a database
* IPv6 support
* Basic test coverage
* Basic benchmarks
* Distributable

### Planned features:
* Administrative API

### Usage:
* Configure options in config/config.exs
* Generate a release with `mix release`
* Run the proper binary located in `rel/aya/bin/`
* If you want to run Aya in a distributed way, please read DISTRIBUTED.md

## General TODO:
* More documentation
* More tests
* More profiling and benchmarking
* Planned features
