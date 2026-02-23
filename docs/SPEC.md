# anycard — Specyfikacja

## 1. Cel projektu

Aplikacja iOS umożliwiająca użytkownikowi dodanie dowolnej karty lojalnościowej do Apple Wallet bez potrzeby dedykowanej aplikacji sklepu.

## 2. Wymagania funkcjonalne

### 2.1 Dodawanie karty

| Funkcja | Opis |
|---------|------|
| Skanowanie | Użytkownik skanuje kod kreskowy/QR istniejącej karty kamerą |
| Ręczne wprowadzanie | Alternatywnie wpisuje numer/kod ręcznie |
| Nazwa karty | Użytkownik nadaje nazwę (np. "IKEA Family") |
| Format kodu | Wybór: Code128, EAN13, QR Code, PDF417, Aztec |

### 2.2 Personalizacja

| Funkcja | Opis |
|---------|------|
| Własna grafika | Upload obrazka jako tło/logo karty |
| Kolory | Wybór kolorów tekstu i tła |
| Podgląd | Live preview karty przed dodaniem |

### 2.3 Zarządzanie kartami

| Funkcja | Opis |
|---------|------|
| Lista kart | Widok wszystkich dodanych kart |
| Edycja | Modyfikacja istniejącej karty |
| Usuwanie | Usunięcie karty (z app i opcjonalnie z Wallet) |
| Duplikowanie | Kopia karty z możliwością edycji |

### 2.4 Apple Wallet

| Funkcja | Opis |
|---------|------|
| Dodawanie do Wallet | Generowanie PKPass i dodanie do Wallet |
| Aktualizacja | Po edycji w app → aktualizacja w Wallet |
| Usuwanie | Opcja usunięcia z Wallet |

## 3. Wymagania niefunkcjonalne

### 3.1 Offline-first
- Wszystkie karty działają bez internetu
- Dane przechowywane lokalnie (SwiftData)
- Brak wymaganego backendu

### 3.2 Prywatność
- Dane nie opuszczają urządzenia
- Brak analityki/trackingu
- Brak kont użytkowników

### 3.3 Wydajność
- Szybki start (<2s)
- Instant camera scanning
- Płynne animacje (60fps)

## 4. Architektura

### 4.1 Warstwy

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

### 4.2 Kluczowe komponenty

| Komponent | Odpowiedzialność |
|-----------|------------------|
| `ScannerService` | Skanowanie barcode/QR z kamery |
| `PassGeneratorService` | Generowanie PKPass |
| `StorageService` | Persystencja kart (SwiftData) |
| `ImagePickerService` | Wybór grafiki z galerii |

## 5. Model danych

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

## 6. Ekrany (UI)

### 6.1 Lista kart (Home)
- Grid/lista wszystkich kart
- Floating action button → dodaj kartę
- Swipe to delete
- Tap → szczegóły/edycja

### 6.2 Dodawanie karty
- Krok 1: Skanuj lub wpisz kod
- Krok 2: Nazwa i typ kodu
- Krok 3: Personalizacja (kolory, grafika)
- Krok 4: Podgląd + "Dodaj do Wallet"

### 6.3 Skaner
- Fullscreen camera view
- Overlay z ramką
- Auto-detect barcode type
- Latarka toggle

### 6.4 Edycja karty
- Formularz z live preview
- Image picker dla grafiki
- Color pickers
- "Zapisz" / "Usuń"

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

### 7.3 Wymagania Apple

| Requirement | Status |
|-------------|--------|
| Apple Developer Account | Required |
| Pass Type ID | Create in Dev Portal |
| Signing Certificate | Required for PKPass |
| Team ID | From Dev Portal |

## 8. Fazy rozwoju

### Phase 1: MVP
- [ ] Podstawowy UI (lista + dodawanie)
- [ ] Ręczne wprowadzanie kodu
- [ ] Generowanie PKPass (Code128 + QR)
- [ ] Dodawanie do Wallet
- [ ] Lokalne przechowywanie

### Phase 2: Scanning
- [ ] Skanowanie barcode kamerą
- [ ] Auto-detect code type
- [ ] Skanowanie QR

### Phase 3: Personalization
- [ ] Custom colors
- [ ] Upload własnej grafiki
- [ ] Live preview

### Phase 4: Polish
- [ ] Edycja istniejących kart
- [ ] Haptic feedback
- [ ] Animacje
- [ ] App icon + splash

### Future (maybe)
- [ ] iCloud sync
- [ ] Widget
- [ ] Apple Watch companion
- [ ] Share cards

## 9. Wymagania systemowe

- iOS 17.0+
- iPhone only (no iPad initially)
- Camera required for scanning

## 10. Open Questions

1. **Pass Type ID** — czy masz Apple Developer Account? Potrzebny do podpisywania passes.

2. **App Icon** — design?

3. **Nazwa w App Store** — "anycard"? Może być zajęte.

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
