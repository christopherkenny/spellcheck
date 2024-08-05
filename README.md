# spellcheck Extension For Quarto

This extension provides a filter to run [Hunspell](https://hunspell.github.io/) every time a `.qmd` file is rendered and prints any misspellings to the console.

You must have Hunspell installed for this to run.
For Windows, the [portable version from Chocolately](https://community.chocolatey.org/packages/hunspell.portable) seems to run well (`choco install hunspell.portable`).
On Mac, you can install with Homebrew (`brew install hunspell`).

## Installing

From a directory with an existing Quarto file or project, run:

```bash
quarto add christopherkenny/spellcheck
```
This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

Add the following to your metadata after installing as above.

```yaml
filters:
  - spellcheck
```

This will print to the console, something which looks like:

```bash
Possibly misspelled words:
--------------------------
consol
listd
spelld
--------------------------
```

The default language used is `en_US`. This can be configured by setting:

```yaml
spellcheck-lang: en_US
```

If you specify a spelling language which cannot be found by Hunspell, the program will error.

You can also specify words to ignore:

```yaml
spellcheck-ignore:
  - words
```

Note: This will create a file `.spellcheck.txt` in the current directory which will be automaticaly removed, during normal functioning. If it fails during the Hunspell step, then you may need to remove that file.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

## Licensing

The original Lua filter for pandoc is licensed under MIT from [John MacFarlane](https://github.com/pandoc/lua-filters/blob/master/spellcheck/spellcheck.lua).
All modifications by me are licensed under the MIT license.
See the [license file](LICENSE) for futher details.
