# AddMemoryScreen

A comprehensive Flutter screen for adding memories with media upload functionality.

## Features

### 🎯 **Media Selection**
- **Photos**: Camera or gallery selection using `image_picker`
- **Videos**: Gallery selection with duration limits
- **Audio**: File picker for audio files (MP3, WAV, AAC, etc.)

### 📱 **User Interface**
- **Modern Design**: Card-based layout with deep purple theme
- **File Preview**: Shows selected file with icon, name, and size
- **Type Selection**: Choice chips for memory types (photo, video, audio, text)
- **Form Validation**: Required title field with validation
- **Date Picker**: Optional release date selection

### ☁️ **Cloud Integration**
- **Cloudinary Upload**: Automatic file upload to Cloudinary
- **Firestore Storage**: Saves metadata to `users/{uid}/memories`
- **Progress Indicators**: Loading states for upload and save operations

## Usage

### Navigation
```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (context) => const AddMemoryScreen(),
  ),
);
```

### Data Structure
Memories are stored in Firestore under:
```
users/{uid}/memories/{memoryId}
```

With the following fields:
- `title`: String (required)
- `type`: String (photo|video|audio|text)
- `cloudinaryUrl`: String (from upload)
- `releaseDate`: String? (optional, ISO format)
- `createdAt`: String (ISO format)
- `createdBy`: String (user UID)
- `linkedUserIds`: Array<String> (initially contains creator UID)

## Dependencies

- `image_picker`: For photo and video selection
- `file_picker`: For audio file selection
- `cloudinary_flutter`: For file uploads
- `firebase_auth`: For user authentication
- `cloud_firestore`: For data storage

## Error Handling

- **File Selection Errors**: User-friendly error messages
- **Upload Failures**: Detailed error logging and user feedback
- **Validation Errors**: Form validation with clear messages
- **Network Issues**: Graceful handling of connectivity problems

## Success Flow

1. User selects media file
2. User fills in title and optional release date
3. User taps "Upload Memory"
4. File uploads to Cloudinary
5. Metadata saves to Firestore
6. Success message shows
7. User navigates back to home screen

## Customization

The screen uses a consistent theme with:
- **Primary Color**: Deep Purple
- **Card Elevation**: 4
- **Border Radius**: 12px
- **Button Height**: 56px for main actions, 60px for home screen

## File Type Support

### Images
- JPG, JPEG, PNG, GIF, WebP, BMP, SVG, TIFF

### Videos  
- MP4, AVI, MOV, WMV, FLV, WebM, MKV, 3GP, M4V

### Audio
- MP3, WAV, AAC, OGG, FLAC, M4A, WMA, AIFF

## Future Enhancements

- [ ] Batch file upload
- [ ] Memory editing capabilities
- [ ] Advanced metadata fields
- [ ] Memory sharing functionality
- [ ] Offline support
