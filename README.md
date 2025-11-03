# | ----------  AudioRecorderApp  ------------- |

A SwiftUI-based iOS application that allows users to record, play-back, and upload audio sessions using API integration.  
It includes real-time waveform visualization, authentication, session management, and file uploads with progress tracking.

## 🧠 Architecture:

The app follows the **MVVM (Model–View–ViewModel)** pattern:
- **Model** – Defines data and API models  
- **ViewModel** – Handles app logic, API calls, and state management  
- **View** – SwiftUI UI components bound to ViewModels  
- **Services** – Manage networking, authentication, and audio recording  
- **Extensions** – Contain reusable waveform UI 


