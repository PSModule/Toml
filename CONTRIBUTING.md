# Contributing to Toml

Thank you for your interest in improving the Toml module!

## Reporting issues

If you find a bug, have a feature request, or notice something unclear in the documentation, please open an issue in the [issue tracker](https://github.com/PSModule/Toml/issues).

Include as much detail as possible, such as:

- The version of the module you are using.
- The version of PowerShell you are running (`$PSVersionTable`).
- A minimal TOML snippet or script that reproduces the issue.
- The expected behavior and the actual behavior.

## Submitting changes

1. Fork the repository and create a feature branch from `main`.
2. Make focused, well-scoped changes.
3. Add or update tests in `tests/` for any changed behavior.
4. Run the local build and test suite:

   ```powershell
   pwsh -File .\build.ps1
   Import-Module .\output\Toml\Toml.psd1 -Force
   Invoke-Pester -Path .\tests\Toml.Tests.ps1
   ```

5. Ensure `PSScriptAnalyzer` reports no errors or warnings:

   ```powershell
   Invoke-ScriptAnalyzer -Path .\src -Recurse -Severity Error,Warning
   ```

6. Open a pull request with a clear description of the change and the problem it solves.

## Coding conventions

- Follow the existing file and folder structure under `src/`.
- Keep functions small and focused.
- Use `[ordered]` hashtables where key order matters.
- Add comment-based help to public functions.
- Write Pester tests for public commands and parser edge cases.

## Code of conduct

Be respectful and constructive. We welcome contributors of all experience levels.
