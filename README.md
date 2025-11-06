## Transliterator (English → Devanagari) for LibreOffice Writer

This is a LibreOffice/OpenOffice Basic macro that transliterates ASCII/Latin text to Devanagari (Hindi/Marathi). It works on Linux (and other OSes) inside LibreOffice Writer.

### Features
- Transliterate selection or entire document
- Optional preview-and-edit dialog before applying
- Language toggle: Hindi or Marathi (stored in macro; default Hindi)
- Simple ITRANS-like scheme:
  - Consonants: k, kh, g, gh, ch, chh, j, jh, t, th, d, dh, n, p, ph, b, bh, m, y, r, l, v/w, s, sh, shh, h, ksh, gy, tr, ny, ng
  - Vowels: a, aa, i, ii/ee, u, uu/oo, e, ai, o, au
  - Marks: .n/.m → anusvara (ं), ~n → chandrabindu (ँ), .h → visarga (ः), OM → ॐ, | → ।, || → ॥
- Heuristic handling of consonant clusters with virama (्)

Note: This is a practical transliterator, not a full phonetic parser. You can tweak mappings inside `Transliterator.bas`.

### Installation (Linux)
1. Open LibreOffice Writer.
2. Tools → Macros → Organize Macros → LibreOffice Basic...
3. In the dialog, pick `My Macros` → `Standard` (or create a new library), click `Edit` to open the Basic IDE.
4. In the editor: File → Open, and open the provided `Transliterator.bas` from this repository (`libreoffice/transliterator/Transliterator.bas`). Copy its contents into a new module (Insert → Module) named `Transliterator` and save.
5. Optionally assign a keyboard shortcut: Tools → Customize → Keyboard → Category `LibreOffice Macros` → select `Transliterator.TransliterateSelectionOrDocument` → Add → OK.

Alternative (file copy):
```
mkdir -p ~/.config/libreoffice/4/user/basic/Transliterator
cp Transliterator.bas ~/.config/libreoffice/4/user/basic/Transliterator/
```
Then restart LibreOffice and ensure the module is visible under `My Macros`.

### Usage
1. Set language (optional):
   - Run `Transliterator.SetLanguageHindi` or `Transliterator.SetLanguageMarathi` (Tools → Macros → Run Macro…).
2. Type ASCII text using the scheme above (e.g., `namaste`, `bharat`, `shakti`, `kshama`).
3. Select the text and run either macro:
   - `Transliterator.TransliterateSelectionOrDocument` (applies immediately)
   - `Transliterator.TransliterateWithPreview` (opens editable preview)
4. If nothing is selected, the whole document is transliterated.

### Examples
- `namaste` → `नमस्ते`
- `bharat` → `भारत`
- `shakti` → `शक्ति`
- `kshama` → `क्षमा`
- `OM` → `ॐ`
 - Marathi lateral: `Lata` → `ळत`

### Customization
Open `Transliterator.bas` and adjust:
- Consonant mappings in `ConsonantLatin`/`ConsonantDev`
- Vowel mappings in `VowelLatin`/`VowelDev`
- Matras in `MatraLatin`/`MatraDev`
- Marks/punctuation in `OtherLatin`/`OtherDev`

### Notes & Limitations
- Retroflex vs. dental distinctions are not explicitly modeled (both `t`/`d` map to dental by default). You can extend mappings to support capitalized tokens if desired.
- The engine assumes an implicit short `a` after consonants unless a vowel matra follows; clusters insert `्` automatically.




