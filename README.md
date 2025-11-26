# USB Share Platform

[![Build USB Share](https://github.com/centopw/Portless/actions/workflows/build.yml/badge.svg)](https://github.com/centopw/Portless/actions/workflows/build.yml)

A cross-platform desktop application that enables users to share USB dongles and devices over networks. The platform provides seamless emulation, making remote USB connections work transparently.

## Features

- **Single unified application** - One download that works as Host (share devices) or Client (access devices)
- **Zero-configuration local mode** - Works out of the box on local networks via mDNS discovery
- **OTP-based authentication** - Secure one-time passwords for connection authorization
- **TLS encryption** - All data encrypted with TLS 1.3
- **Cross-platform** - Supports macOS, Windows, and Linux

## Downloads

Pre-built binaries are available from the [binaries](binaries/) page:

| Platform | Download |
|----------|----------|
| macOS (Apple Silicon) | `USB Share_x.x.x_aarch64.dmg` |
| macOS (Intel) | `USB Share_x.x.x_x64.dmg` |
| Windows | `USB Share_x.x.x_x64-setup.exe` or `.msi` |
| Linux | `.AppImage`, `.deb`, or `.rpm` |

## How It Works

### Host Mode
1. Application enumerates connected USB devices
2. User selects devices to share
3. Host advertises availability via mDNS
4. When a client requests connection, host generates OTP
5. User shares OTP with client (verbally/physically)
6. Upon verification, USB data is tunneled over encrypted connection

### Client Mode
1. Application discovers hosts on local network via mDNS
2. User selects a device to connect to
3. Client enters OTP provided by host user
4. Virtual USB device is created on client machine (requires driver - future phase)
5. USB traffic is tunneled to/from host

## Configuration

Settings are stored in:
- **macOS**: `~/Library/Application Support/usbshare/config.toml`
- **Windows**: `%APPDATA%\usbshare\config.toml`
- **Linux**: `~/.config/usbshare/config.toml`

## License

MIT
