# Firebase credential rotation handoff

The Firebase environment file is no longer tracked by Git and is ignored locally. Removing it from the current branch does **not** remove its contents from earlier Git history or invalidate any existing Firebase credentials.

Before sharing this repository or merging the branch:

1. In the Firebase and Google Cloud consoles, identify the credentials and API keys used by the old Godot Firebase environment file.
2. Revoke or rotate them, then apply application and API restrictions appropriate to the Reel It In iOS bundle identifier.
3. Replace the local Firebase environment file only if the pre-migration build still needs to run; do not recommit it.
4. After the ASP.NET/Swift replacement is verified on a physical device, delete the Firebase project configuration from the app and disable unused Firebase services.

Do not paste replacement values into issues, chat, commits, screenshots, or the repository.
