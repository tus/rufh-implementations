# iOS Resumable Upload Client

This examples contains an iOS app using Swift for demonstrating resumable file uploads. The user can start, pause and resume an upload. This is powered by the new resumable upload capabilities of `URLSession` as presented at [Apple's WWDC23](https://developer.apple.com/videos/play/wwdc2023/10006/).

## Directory Structure

- `ResumableUploadExample/ContentView.swift` contains the main logic for upload handling.

## Requirements

The new resumable upload APIs are only available in iOS 17+, which is not released as of writing this. To run it, you need the Xcode 15 beta release and a iOS device (or simulator) running iOS 17.
