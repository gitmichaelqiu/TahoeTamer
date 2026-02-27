# TahoeTamer

**TahoeTamer** is a lightweight macOS shell script designed to bypass the "Liquid Glass" visual effects introduced in macOS Tahoe. By spoofing the Mach-O SDK header of an application, it forces the system to render windows using the classic, sharp-cornered aesthetic of previous macOS versions.


https://github.com/user-attachments/assets/4114f7a6-7bcf-46f6-96b6-68e07d52676b


## How It Works

The script performs a 6-step transformation on your target `.app` bundle:

1. **Duplicate**: Copies the application to your chosen output directory.
2. **De-Quarantine**: Removes the `com.apple.quarantine` attribute.
3. **Modify ID**: Updates the `Info.plist` with a new "Tamed" bundle ID.
4. **Thin Binary**: Strips the binary down to `x86_64` (Intel) architecture.
5. **Spoof Header**: Uses `vtool` to replace the Build SDK version with 15.0.
6. **Re-sign**: Deep-signs the modified bundle with an ad-hoc signature.

## Prerequisites

To use TahoeTamer, you must have the **Xcode Command Line Tools** installed for the following utilities:

- `vtool`
- `lipo`
- `codesign`
- `plutil`

## Usage

1. **Download** the `main.sh` script.
2. **Make it executable**:
```bash
chmod +x main.sh

```

3. **Run the script**:
```bash
./main.sh

```

4. **Follow the prompts**: Drag and drop your desired `.app` and the destination folder into the terminal window when asked.

## Disclaimer

> This tool modifies application binaries and removes original code signatures. Use it at your own risk. Certain apps with hardened runtime requirements or complex internal checks may not function correctly after modification.
