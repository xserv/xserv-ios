<p align="center" >
  <img src="http://mobile-italia.com/xserv/assets/images/logo-big.png?t=3" alt="Xserv" title="Xserv">
</p>

<br>

This library is client that allows iOS clients to connect to the [Xserv](http://mobile-italia.com/xserv/) WebSocket API.<br>
[Xserv](http://mobile-italia.com/xserv/) provides a complete solution to implement the backend of all your applications such as web, mobile, desktop, embedded or otherwise.

## How To Get Started

- [Download xserv-ios](https://github.com/xserv/xserv-ios/archive/master.zip) and try out the included iPhone example apps.
- Read the ["Getting Started" guide](http://mobile-italia.com/xserv/docs#).

## Installation
Xserv supports multiple methods for installing the library in a project.

## Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries like Xserv in your projects. See the ["Getting Started" guide for more information](). You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 0.39.0+ is required to build Xserv 0.1.4+.

### Podfile

To integrate Xserv into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

pod 'Xserv'
```

Then, run the following command:

```bash
$ pod install
```

## Credits

Xserv is owned and maintained by the [mobile-italia.com] (http://mobile-italia.com).

Dependencies:

https://github.com/square/SocketRocket

### Security Disclosure

If you believe you have identified a security vulnerability with Xserv, you should report it as soon as possible via email to xserv.dev@gmail.com. Please do not post it to a public issue tracker.

## License

Xserv is released under the GNU General Public License Version 3. See LICENSE for details.
