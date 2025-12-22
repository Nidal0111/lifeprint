# Gemini API Setup Guide

## ✅ **UPDATE: Gemini URL is Now Hardcoded!**

Your chatbot service now has the Gemini URL directly hardcoded:
- ✅ **Gemini API URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent`
- 🔑 **API Key**: Only this needs to be provided via environment variable

## Quick Setup - Only Add Your API Key

### Method 1: Build Commands (Simplest)

**Android:**
```bash
flutter run --dart-define=GEMINI_API_KEY="your_actual_api_key_here"
```

**iOS:**
```bash
flutter run --dart-define=GEMINI_API_KEY="your_actual_api_key_here"
```

**Web:**
```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY="your_actual_api_key_here"
```

### Method 2: VS Code launch.json

Create `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "flutter run",
            "request": "launch",
            "type": "dart",
            "program": "lib/main.dart",
            "args": [
                "--dart-define=GEMINI_API_KEY=your_actual_api_key_here"
            ]
        }
    ]
}
```

### Method 3: Environment Variables

**Windows:**
```cmd
set GEMINI_API_KEY=your_actual_api_key_here
flutter run
```

**macOS/Linux:**
```bash
export GEMINI_API_KEY="your_actual_api_key_here"
flutter run
```

## Getting Your Gemini API Key

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click "Get API Key"
4. Create a new API key
5. Copy the key

## Security Notes

⚠️ **IMPORTANT:**
- Never commit API keys to version control
- Add `.env` files to `.gitignore`
- Use different keys for development and production

## Testing

After adding your API key:

```bash
flutter run
```

Try asking:
- "Hello"
- "Show me my memories"
- "What events do I have?"

You'll get intelligent responses powered by Gemini 2.0 Flash!
