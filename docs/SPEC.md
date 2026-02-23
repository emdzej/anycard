# anycard — Specification

## 1. Project Goal

iOS app enabling users to add any loyalty card to Apple Wallet without needing the store's dedicated app.

## 2. Functional Requirements

### 2.1 Adding Cards

| Feature | Description |
|---------|-------------|
| Scanning | User scans existing card's barcode/QR with camera |
| Manual entry | Alternatively enters number/code manually |
| Card name | User assigns a name (e.g., "IKEA Family") |
| Code format | Choice: Code128, EAN13, QR Code, PDF417, Aztec |

### 2.2 Personalization

| Feature | Description |
|---------|-------------|
| Custom graphics | Upload image as card background/logo |
| Colors | Choose text and background colors |
| Preview | Live preview of card before adding |

### 2.3 Card Management

| Feature | Description |
|---------|-------------|
| Card list | View all added cards |
| Edit | Modify existing card |
| Delete | Remove card (from app and optionally from Wallet) |
| Duplicate | Copy card with ability to edit |

### 2.4 Apple Wallet

| Feature | Description |
|---------|-------------|
| Add to Wallet | Generate PKPass and add to Wallet |
| Update | After editing in app → update in Wallet |
| Remove | Option to remove from Wallet |

## 3. Non-Functional Requirements

### 3.1 Offline-first
- All cards work without internet
- Data stored locally (SwiftData)
- No backend required

### 3.2 Privacy
- Data never leaves the device
- No analytics/tracking
- No user accounts

### 3.3 Performance
- Fast launch (<2s)
- Instant camera scanning
- Smooth animations (60fps)

## 4. Architecture

### 4.1 Layers

```
┌─────────────────────────────────────┐
│            UI (SwiftUI)             │
├─────────────────────────────────────┤
│          ViewModels (MVVM)          │
├─────────────────────────────────────┤
│            Services                 │
│  ┌─────────┬─────────┬───────────┐  │
│  │ Scanner │ PassGen │ Storage   │  │
│  │ Service │ Service │ Service   │  │
│  └─────────┴─────────┴───────────┘  │
├─────────────────────────────────────┤
│         System Frameworks           │
│  AVFoundation │ PassKit │ SwiftData │
└─────────────────────────────────────┘
```

### 4.2 Key Components

| Component | Responsibility |
|-----------|----------------|
| `ScannerService` | Barcode/QR scanning from camera |
| `PassGeneratorService` | PKPass generation |
| `StorageService` | Card persistence (SwiftData) |
| `ImagePickerService` | Image selection from gallery |

## 5. Data Model

### 5.1 Card

```swift
@Model
class Card {
    var id: UUID
    var name: String
    var code: String
    var codeType: CodeType  // barcode, qr, etc.
    var backgroundColor: String  // hex color
    var textColor: String
    var customImage: Data?  // user-uploaded image
    var createdAt: Date
    var updatedAt: Date
}

enum CodeType: String, Codable {
    case code128
    case ean13
    case qrCode
    case pdf417
    case aztec
}
```

## 6. Screens (UI)

### 6.1 Card List (Home)
- Grid/list of all cards
- Floating action button → add card
- Swipe to delete
- Tap → details/edit

### 6.2 Add Card
- Step 1: Scan or enter code
- Step 2: Name and code type
- Step 3: Personalization (colors, graphics)
- Step 4: Preview + "Add to Wallet"

### 6.3 Scanner
- Fullscreen camera view
- Overlay with frame
- Auto-detect barcode type
- Flashlight toggle

### 6.4 Edit Card
- Form with live preview
- Image picker for graphics
- Color pickers
- "Save" / "Delete"

## 7. PassKit Integration

### 7.1 PKPass Structure

```
card.pkpass/
├── pass.json          # Pass metadata
├── icon.png           # App icon (required)
├── icon@2x.png
├── logo.png           # Card logo (optional)
├── strip.png          # Background strip (optional)
└── manifest.json      # File hashes
```

### 7.2 pass.json Template

```json
{
  "formatVersion": 1,
  "passTypeIdentifier": "pass.com.anycard.loyalty",
  "teamIdentifier": "TEAM_ID",
  "organizationName": "anycard",
  "description": "{{card.name}}",
  "serialNumber": "{{card.id}}",
  "foregroundColor": "{{card.textColor}}",
  "backgroundColor": "{{card.backgroundColor}}",
  "storeCard": {
    "primaryFields": [
      {
        "key": "card-number",
        "label": "CARD NUMBER",
        "value": "{{card.code}}"
      }
    ]
  },
  "barcode": {
    "format": "{{card.codeType}}",
    "message": "{{card.code}}",
    "messageEncoding": "iso-8859-1"
  }
}
```

### 7.3 Apple Requirements

| Requirement | Status |
|-------------|--------|
| Apple Developer Account | Required |
| Pass Type ID | Create in Dev Portal |
| Signing Certificate | Required for PKPass |
| Team ID | From Dev Portal |

## 8. Development Phases

### Phase 1: MVP
- [ ] Basic UI (list + adding)
- [ ] Manual code entry
- [ ] PKPass generation (Code128 + QR)
- [ ] Add to Wallet
- [ ] Local storage

### Phase 2: Scanning
- [ ] Barcode scanning with camera
- [ ] Auto-detect code type
- [ ] QR scanning

### Phase 3: Personalization
- [ ] Custom colors
- [ ] Upload custom graphics
- [ ] Live preview

### Phase 4: Polish
- [ ] Edit existing cards
- [ ] Haptic feedback
- [ ] Animations
- [ ] App icon + splash

### Future (maybe)
- [ ] iCloud sync
- [ ] Widget
- [ ] Apple Watch companion
- [ ] Share cards

## 9. System Requirements

- iOS 17.0+
- iPhone only (no iPad initially)
- Camera required for scanning

## 10. Open Questions

1. **Pass Type ID** — Do you have Apple Developer Account? Required for signing passes.

2. **App Icon** — Design?

3. **App Store name** — "anycard"? May be taken.

## 11. Development Setup

### Signing

| Phase | Signing | Notes |
|-------|---------|-------|
| Development | Personal Team | Free, 7-day cert |
| Wallet Integration | Apple Developer Program | $99/year, required for Pass Type ID |

### MVP without Developer Account

1. ✅ UI (SwiftUI)
2. ✅ Camera scanning (AVFoundation)
3. ✅ Local storage (SwiftData)
4. ✅ Pass preview (mock - shows how card will look)
5. ❌ Add to Wallet (disabled until Developer Account)

## 12. Design

### App Icon
- Style: Single card with diagonal stripe
- Color: Blue gradient
- Format: 1024x1024 PNG (App Store), @1x/@2x/@3x for app

### Color Palette
- Primary: #007AFF (iOS blue)
- Secondary: #5856D6 (purple accent)
- Background: #F2F2F7 (system gray 6)
- Card default: #1C1C1E (dark)
