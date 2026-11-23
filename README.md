# KeyGuardian

KeyGuardian is a password vault for mobile, built with Flutter. Credentials are encrypted on the device before they are stored in Firebase, and a master key guards access to the vault. The project is finished and covers the whole flow, from sign-up to managing credentials.

## Features

The app is organized in modules:

* **Authentication (`auth`)**
  * **Welcome screen:** starting point with sign-in and sign-up.
  * **Sign-in and sign-up:** user authentication with Firebase Auth.
  * **Password recovery:** reset by e-mail.
  * **User profile:** view and manage account data.

* **Security (`master_key`)**
  * **Master key:** an extra layer of protection. The user creates and confirms a master key that is required to open the vault, so only the owner reaches the sensitive data.

* **Credential vault (`credentials`)**
  * **Home:** list of every saved credential.
  * **Add credential:** form to save new logins and passwords.
  * **Credential details:** view and edit login information.

* **Tools (`generator`)**
  * **Password generator:** strong passwords with configurable length, special characters, numbers and so on.

## Project structure

The code is organized by **feature**, which keeps it easy to maintain and extend. Inside `lib/`:

* **`lib/features/`**: the app's main modules.
  * **`auth/`**: authentication screens and logic (sign-in, sign-up, profile).
  * **`credentials/`**: credential management (home, add, details).
  * **`master_key/`**: master key logic and screens.
  * **`generator/`**: the password generator.
* **`lib/main.dart`**: entry point, Firebase setup and themes.

Each feature is usually split into `view` (screens and widgets), `bloc`/`controller` (state management) and `data` (repositories and models).

## Stack

* **Flutter** for the UI.
* **Firebase**
  * **Authentication:** user management.
  * **Firestore:** NoSQL database for the (encrypted) credentials.
* **State management:** **Bloc/Cubit**.
* **Security**
  * **flutter_secure_storage:** secure local storage.
  * **encrypt:** encrypts sensitive data before it is sent to the database.

## Running it

1. **Requirements:** the Flutter SDK, installed and configured.
2. **Clone the repository:**
    ```bash
    git clone https://github.com/brennocm/keyguardian.git
    cd keyguardian
    ```
3. **Install the dependencies:**
    ```bash
    flutter pub get
    ```
4. **Firebase:** the repository ships the configuration of the original Firebase project (`lib/firebase_options.dart` and `android/app/google-services.json`). To use your own project, create one in the Firebase console with Authentication (e-mail and password) and Firestore, then regenerate the files:
    ```bash
    dart pub global activate flutterfire_cli
    flutterfire configure
    ```
5. **Run the app:**
    ```bash
    flutter run
    ```

## License

[MIT](LICENSE)
