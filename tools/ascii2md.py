#!/usr/bin/env python3
# ================================================================================
# PATH:        tools/ascii2md.py
# PURPOSE:     Convert Simple ASCII Text Format files (.txt) to Markdown (.md).
# TARGET:      Developer environment, AI agents, automated documentation pipeline.
# LINEAGE:     fekerr-dev / irislime Tooling
# UPDATED:     20260718_120000
# Integrity-Hash: 4a8b79219e8316500c2971a98d26ede9c1f9c8db123bf7948d8a28b0b292845b
# ================================================================================
import sys
import re
import argparse
from pathlib import Path

def parse_ascii_to_markdown(text_content: str) -> str:
    """
    Parses simple ASCII structured text into GitHub Flavored Markdown format.
    Handles header/footer blocks, rule headers, section titles, and list items.
    """
    lines = text_content.splitlines()
    md_lines = []
    
    in_header_block = False
    in_code_block = False
    
    for line in lines:
        stripped = line.strip()
        
        # Detect ASCII boundary separator lines
        if re.match(r"^={5,}$", stripped):
            if not in_header_block:
                in_header_block = True
                md_lines.append("---")
            else:
                in_header_block = False
                md_lines.append("---")
            continue
            
        # Parse metadata header fields inside separator blocks
        if in_header_block:
            meta_match = re.match(r"^(PATH|PURPOSE|TARGET|LINEAGE|UPDATED|Integrity-Hash|EOF):\s*(.*)$", stripped)
            if meta_match:
                key, val = meta_match.groups()
                md_lines.append(f"**{key}**: `{val}`  ")
                continue
                
        # Handle rule headers like "RULE 1: TITLE"
        rule_match = re.match(r"^RULE\s+(\d+):\s*(.*)$", stripped, re.IGNORECASE)
        if rule_match:
            num, title = rule_match.groups()
            md_lines.append(f"\n### Rule {num}: {title}\n")
            continue

        # Handle section headers like "SECTION: TITLE" or "1. SECTION TITLE"
        sec_match = re.match(r"^(SECTION|\d+\.|\b[A-Z0-9_\s]{4,}\b:)\s*(.*)$", stripped)
        if sec_match and not stripped.startswith("*") and not stripped.startswith("-"):
            if stripped.isupper() and len(stripped) > 3 and ":" in stripped:
                md_lines.append(f"\n## {stripped}\n")
                continue

        # Preserve standard list items (* or -)
        if stripped.startswith("* ") or stripped.startswith("- "):
            md_lines.append(line)
            continue

        # Code block fence toggle (e.g. ```)
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            md_lines.append(line)
            continue
            
        md_lines.append(line)
        
    return "\n".join(md_lines)

def process_file(input_file: Path, output_file: Path):
    """Reads ASCII text file and writes Markdown output."""
    content = input_file.read_text(encoding="utf-8", errors="ignore")
    md_content = parse_ascii_to_markdown(content)
    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(md_content, encoding="utf-8")
    print(f"[+] Converted ASCII '{input_file}' -> Markdown '{output_file}'")

def main():
    parser = argparse.ArgumentParser(
        description="Convert Simple ASCII Text Format files to Markdown."
    )
    parser.add_argument("input", type=Path, help="Input ASCII file or directory")
    parser.add_argument("output", type=Path, nargs="?", help="Output Markdown file or directory")
    
    args = parser.parse_args()
    
    if args.input.is_file():
        out_path = args.output if args.output else args.input.with_suffix(".md")
        process_file(args.input, out_path)
    elif args.input.is_dir():
        out_dir = args.output if args.output else args.input
        for file in args.input.glob("**/*.txt"):
            rel = file.relative_to(args.input)
            out_file = out_dir / rel.with_suffix(".md")
            process_file(file, out_file)
    else:
        print(f"[X] Input path '{args.input}' does not exist.")
        sys.exit(1)

if __name__ == "__main__":
    main()
