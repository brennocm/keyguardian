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
  * **pointycastle:** AES-256-GCM and SHA-256 primitives for the vault encryption (see below).
  * **flutter_secure_storage:** secure local storage.

## How the vault is encrypted

Passwords are encrypted on the device; Firestore only ever stores ciphertext.

* **Key derivation:** the master key is stretched with **PBKDF2-HMAC-SHA256**, **600,000 iterations** (the OWASP recommendation) and a random 16-byte salt per user. The derivation runs in a background isolate so the UI stays responsive. The master key is never stored or sent anywhere.
* **Encryption:** each password is sealed with **AES-256-GCM**, using a fresh random 96-bit nonce and a 128-bit authentication tag. Tampered or swapped ciphertext fails to decrypt instead of returning garbage.
* **Binding:** the GCM associated data includes the user ID and the field, so a ciphertext copied into another account or field is rejected.
* **Unlock check:** `users/{uid}` stores the KDF parameters and a sealed verification value. A wrong master key fails the GCM tag check. Parameters weaker than 600,000 iterations are refused, so whoever can write that document cannot downgrade the KDF.
* **Stored format:** `v2:<base64 nonce>:<base64 ciphertext+tag>`.
* **Migration:** vaults created with the first version (AES-CBC with the master key used directly as the key) are re-encrypted with the scheme above on the first unlock, in a single atomic Firestore batch.

The crypto core lives in `lib/core/crypto/vault_crypto.dart` and has no Flutter dependency. `test/vault_crypto_test.dart` checks it against the RFC 7914 PBKDF2 vectors, against pointycastle on random inputs, for tamper and wrong-key rejection, and against a value produced by the old scheme:

```bash
flutter test
```

Out of scope for this project: Firestore security rules are configured in the Firebase console (each user should only read and write `users/{their uid}/**`), and the master key is not recoverable: forgetting it means losing the vault.

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
