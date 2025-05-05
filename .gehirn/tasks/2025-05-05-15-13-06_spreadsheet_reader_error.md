# SpreadsheetReader Fatal Error Investigation

## Error Details
- Error Code: BAD-EMU-8769
- Location: application/Spreadsheet/SpreadsheetReader.php line 535
- Type: Fatal Error
- Impact: Request could not be completed

## Root Cause
- The error occurs in SpreadsheetReader.php when trying to use PHP's Normalizer class
- The Normalizer class is part of the PHP intl extension
- The intl extension is not installed in the Docker container
- Line causing error: `$cellValue = hardTrueFalse(Normalizer::normalize((string)$cell->getValue(), Normalizer::FORM_C));`

## Tasks
- [x] Locate and examine SpreadsheetReader.php file
- [x] Analyze code at line 535 and surrounding context
- [x] Check Dockerfile for required extensions
- [x] Add intl extension to Dockerfile:
  ```dockerfile
  RUN apt-get update && apt-get install -y \
      libicu-dev \
      && docker-php-ext-install intl
  ```
- [ ] Rebuild Docker container with new extension
- [ ] Test spreadsheet functionality after rebuild
- [ ] Update documentation to include intl extension requirement

## Next Actions
1. [x] Add the intl extension installation to the Dockerfile
2. [ ] Execute `docker-compose build formr_app` to rebuild the container
3. [ ] Restart the application stack with `docker-compose up -d`
4. [ ] Test spreadsheet import functionality to verify the fix
5. [x] Document the intl extension requirement in project README.md

## Solution Impact
- Installing intl extension will provide the required Normalizer class
- No code changes needed in SpreadsheetReader.php
- Will require container rebuild

## Notes
- This is a dependency issue rather than a code bug
- The error occurs during Unicode normalization of spreadsheet cell values
- The fix is straightforward: add missing PHP extension