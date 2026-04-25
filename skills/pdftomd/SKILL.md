---
name: pdftomd
description: Convert PDF files to Markdown while preserving content accuracy and document structure. Use when the user asks for `/pdftomd`, PDF to Markdown conversion, or wants a PDF transformed into one or more Markdown files.
---

# PDF to Markdown

Use this workflow when the user wants a PDF converted to Markdown.

## Workflow

1. Verify the PDF path exists.
2. Extract text with an available PDF tool such as `pdftotext`, or use a PDF-capable extraction workflow when text extraction is insufficient.
3. Preserve the original content accurately. Do not summarize unless the user explicitly asks.
4. Reflect the document structure with Markdown headings, lists, tables, and code blocks where appropriate.
5. If the PDF is long, split output into sensible Markdown files by chapter, section, or page range.
6. Report output file paths and any extraction limitations.

## Quality Rules

- Keep wording faithful to the PDF.
- Preserve list nesting and table relationships where practical.
- Mark uncertain OCR or extraction artifacts instead of silently inventing text.
- Do not delete repeated headers, footers, or page numbers unless they clearly harm readability and are not content.
