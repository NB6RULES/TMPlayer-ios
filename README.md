# TMPlayer iOS

An unofficial iOS port of [TMPlayer](https://github.com/dracu-lah/TMPlayer), a Telegram video streaming client.

*Disclaimer: This is an unofficial third-party client and is not affiliated with Telegram.*

## Features

- Sign in via Telegram QR code.
- Browse your Telegram chats.
- View and instantly stream videos from chats without waiting for full downloads.
- Seeks re-aim the download dynamically.

## Building

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) and [TDLibKit](https://github.com/Swiftgram/TDLibKit).
You can build this on macOS or via the included GitHub Actions workflow.

1. Ensure Xcode is installed.
2. Install XcodeGen (`brew install xcodegen`).
3. Run `xcodegen generate` in this directory to generate `TMPlayer.xcodeproj`.
4. Open the project in Xcode and build.

Or push to GitHub to have the CI generate an unsigned `.ipa` for sideloading/Live Container.

## License

This project is licensed under the GPL-3.0 License. See the `LICENSE` file for details.
