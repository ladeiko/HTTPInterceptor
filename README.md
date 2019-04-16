# HTTPInterceptor

[![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg?colorA=28a745&colorB=4E4E4E)](https://img.shields.io/badge/Platform-iOS-lightgrey.svg?colorA=28a745&colorB=4E4E4E)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/HTTPInterceptor.svg?style=flat&label=CocoaPods&colorA=28a745&&colorB=4E4E4E)](https://cocoapods.org/pods/HTTPInterceptor)
[![Swift support](https://img.shields.io/badge/Swift-4.0%20%7C%204.1%20%7C%204.2%20%7C%205.0-lightgrey.svg?colorA=28a745&colorB=4E4E4E)](#swift-versions-support)
[![Build Status](https://travis-ci.org/ladeiko/HTTPInterceptor.svg?branch=master)](https://travis-ci.org/ladeiko/HTTPInterceptor)

## Introduction

Helps to setup interceptor for HTTP(s) requests, modify them, return custom response.

## Changelog

See [CHANGELOG](CHANGELOG.md)

## Installation

### Cocoapods
> This is the recommended way of installing this package.

* Add the following line to your Podfile

``` ruby
pod 'HTTPInterceptor'
```
* Run the following command to fetch and build your dependencies

``` bash
pod install
```

### Manually
If you prefer to install this package manually, just follow these steps:

* Make sure your project is a git repository. If it isn't, just run this command from your project root folder:

``` bash
git init
```

* Add HTTPInterceptor as a git submodule by running the following command.

``` bash
git submodules add https://github.com/ladeiko/HTTPInterceptor.git
```
* Add files from *'submodules/HTTPInterceptor/Sources'* folder to your project.

## Usage

See usage examples in [HTTPInterceptorDemoTests.swift](Demo/HTTPInterceptorDemoTests/HTTPInterceptorDemoTests.swift)

## LICENSE
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
