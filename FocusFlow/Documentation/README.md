# FocusFlow

FocusFlow is a SwiftUI productivity app for iPhone and iPad that helps users manage focus sessions, review progress, and reflect on completed work.

This project was built as an iOS application sample for an apprenticeship application in software development, with a focus on clean structure, native Apple UI patterns, and practical product thinking.

## Overview

FocusFlow combines a lightweight focus timer with session tracking, notes, mood tagging, statistics, and CSV import/export.

The app was designed with different interaction models for iPhone and iPad:

- **iPhone:** tab-based navigation with separate sections for Home, History, Stats, and Settings
- **iPad:** split view layout with a sidebar and detail area

## Features

### Timer
- Focus / Short Break / Long Break sessions
- Circular animated progress ring
- Session-based color changes
- Haptic feedback on completion
- Optional automatic reset after a session ends

### Session Tracking
- Completed focus sessions are stored locally
- Today's focus time is summarized on the home screen
- Recent session preview on iPhone
- Full history overview with searchable entries

### Session Details
- Mood selection per session
- Tags for categorization
- Free-form notes
- Native detail editing flow

### Statistics
- Summary cards for:
  - today's focus time
  - total sessions
  - total focus minutes
- 7-day chart using Swift Charts

### Data Handling
- Local persistence with `UserDefaults`
- CSV export
- CSV import
- Search and filtering for history entries

### Settings
- Haptics on/off
- Auto-reset on/off
- Version watermark on/off
- Adjustable standard durations
- Adjustable developer/test durations
- Immediate settings updates without restarting the app

## Technical Highlights

- Built with **SwiftUI**
- Uses **MVVM-style separation**
- Adaptive layouts for iPhone and iPad
- Native Apple frameworks:
  - `SwiftUI`
  - `Combine`
  - `Charts`
  - `UIKit` (for haptics)
  - `UniformTypeIdentifiers`
- Local data persistence via `UserDefaults`
- CSV-based import/export workflow

## Project Structure

```text
FocusFlow
├── App
├── Models
├── ViewModels
├── Views
│   ├── Components
│   └── Screens
├── Resources
└── Documentation
