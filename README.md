# 🌾 Farm Voice

**AI-powered crop diagnosis and voice advisory for Indian farmers built for Build with AI: Code for Communities (Track 4 — Kisan Alert), by Google Cloud & Hack2Skill.**

Farm Voice puts a multilingual agricultural expert in every farmer's pocket. Photograph a sick crop and get an instant AI diagnosis, or simply speak a question in your own language and get a clear, practical answer back spoken aloud, no reading required.

---

## 📌 Why This Exists

Farmers routinely lose crops to preventable disease and make planting/irrigation decisions based on habit or hearsay rather than data, not because the knowledge doesn't exist, but because it's locked behind text, English, and internet-search literacy that many small and marginal farmers don't have easy access to. Farm Voice closes that gap using Gemini's multimodal AI as the actual engine: point a camera at a leaf, or just talk, and get an answer in your own language, spoken back to you.

---

## 🚀 Features

- **📸 Scan Crop** — Take a photo of a diseased or struggling crop and get an instant AI diagnosis: likely disease, confidence, and clear remediation steps.
- **🎙️ Tap & Speak** — Ask a farming question by voice or by typing, in your preferred language, and get a short, practical advisory back.
- **🔊 Voice-First, Not Text-First** — Every AI response can be read aloud via text to speech, so literacy is never a barrier to getting help.
- **🌐 Multilingual by Design** — Select from Indic languages (Hindi, Tamil, Telugu, Marathi, Kannada, English) for both speech recognition and spoken responses.
- **📋 Expert Escalation (Prototype)** — Flag a diagnosis for human follow up, simulating a direct link to a local Rythu Seva Kendra (Farmer Service Centre) for cases needing expert attention.
- **⚡ Fast, Focused UX** — A two-button home dashboard gets farmers into the flow they need in one tap, with clear loading and error states throughout.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart) |
| **AI / Diagnosis & Advisory** | Google Gemini API (`google_generative_ai`) — multimodal vision + text generation |
| **Speech Recognition** | `speech_to_text` |
| **Text-to-Speech** | `flutter_tts` |
| **Image Capture** | `image_picker` |

---

## 📂 Project Structure

```
lib/
├── main.dart                      # Application entry point
├── app.dart                       # Root widget, theme setup
├── secrets.dart                   # 🔒 Your local Gemini API key (gitignored, not committed)
├── secrets.example.dart           # Template showing what secrets.dart should contain
│
├── core/
│   └── theme/
│       ├── app_theme.dart         # App-wide Material theme
│       └── app_colors.dart        # Color palette
│
├── models/
│   └── language_option.dart       # Supported languages for voice input/output
│
├── services/
│   └── gemini_service.dart        # All Gemini API calls (vision diagnosis + text advisory)
│
├── screens/
│   ├── home_screen.dart           # Two-button dashboard: Scan Crop / Tap & Speak
│   ├── camera_screen.dart         # Photo capture → Gemini vision analysis
│   ├── crop_result_screen.dart    # Diagnosis result, TTS playback, expert escalation
│   ├── voice_screen.dart          # Language picker, mic, typed-query fallback
│   └── voice_result_screen.dart   # Advisory result, chat-bubble style, TTS playback
│
└── widgets/                       # Shared UI components (buttons, cards, bubbles, overlays)
```

---

## ⚙️ Setup & Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- A Google Gemini API key ([get one free here](https://aistudio.google.com/app/apikey))

### 1. Clone the repository

```bash
git clone <repo_url>
cd kisan-support
flutter pub get
```

### 2. 🔑 Set up your Gemini API key (required)

> **This project strictly keeps secrets out of source control.** The real API key lives only in a local, gitignored file — it is never committed or pushed to GitHub.

1. Copy the example file to create your local secrets file:
   ```bash
   cp lib/secrets.example.dart lib/secrets.dart
   ```
2. Open `lib/secrets.dart` and paste in your own Gemini API key:
   ```dart
   const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
   ```
3. That's it — `lib/secrets.dart` is listed in `.gitignore`, so your key stays local to your machine and is never uploaded.

**Never commit `lib/secrets.dart` or paste a real key into any file that gets pushed to GitHub.** If you ever suspect a key has been exposed, revoke and regenerate it immediately at [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey).

### 3. Run the app

```bash
flutter run
```

> 📷 Camera and 🎙️ microphone permissions are required. Make sure `android.permission.CAMERA` / `android.permission.RECORD_AUDIO` (AndroidManifest.xml) and `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` (Info.plist) are set up for your platform.

---

## 🔒 Security Notes

- **API keys are never hardcoded or committed.** All secrets live in `lib/secrets.dart`, which is explicitly excluded via `.gitignore`.
- All Gemini calls are wrapped with timeouts and error handling in `GeminiService`, so a failed request or lost connection never crashes the app — the farmer always sees a clear, readable message instead.

---

## 🗺️ Roadmap / What's Next

- [ ] Smart crop recommendation engine using satellite and soil data
- [ ] Real-time dry-spell and irrigation advisory alerts
- [ ] Live integration with Rythu Seva Kendra systems (currently a UI prototype)
- [ ] WhatsApp/SMS gateway for low-connectivity access
- [ ] Offline-first support for areas with limited internet access

---

## 🏆 Built For

**Build with AI: Code for Communities** — a national hackathon by Google Cloud connecting builders directly with sitting Members of Parliament to solve real, on-the-ground governance problems.

**Track 4: Kisan Alert** — *Smart Water, Crop & Advisory System*

---

## 📄 License

This project was built for hackathon purposes. License to be finalized.
