#!/usr/bin/env python3
"""
Convert Claude conversations export (conversations.json) to org-mode entries.

Usage:
    python3 claude_to_org.py conversations.json [projects_dir] > claude-chats.org
    python3 claude_to_org.py conversations.json [projects_dir] --after 2026-01-01

The optional projects_dir should point to the 'projects' folder from the export,
which maps conversation UUIDs to project names.
"""

import json
import sys
import argparse
from datetime import datetime, timezone


def parse_date(date_str):
    """Parse ISO8601 date string to datetime."""
    # Handle both with and without microseconds
    date_str = date_str.rstrip("Z")
    for fmt in ("%Y-%m-%dT%H:%M:%S.%f", "%Y-%m-%dT%H:%M:%S"):
        try:
            return datetime.strptime(date_str, fmt).replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None


def format_org_date(dt):
    """Format datetime as org inactive timestamp [YYYY-MM-DD Day]."""
    return dt.strftime("[%Y-%m-%d %a]")


def first_human_message(conversation):
    """Extract the text of the first human message."""
    for msg in conversation.get("chat_messages", []):
        if msg.get("sender") == "human":
            text = msg.get("text", "").strip()
            if text:
                # Truncate long opening messages
                if len(text) > 200:
                    text = text[:197] + "..."
                return text
    return ""


def make_org_entry(conv):
    """Generate a single org entry string for a conversation."""
    uuid = conv["uuid"]
    name = conv.get("name", "Untitled").strip()
    created = parse_date(conv.get("created_at", ""))
    updated = parse_date(conv.get("updated_at", ""))
    url = f"https://claude.ai/chat/{uuid}"
    summary = conv.get("summary", "").strip()
    opening = first_human_message(conv)

    created_str = format_org_date(created) if created else ""
    updated_str = format_org_date(updated) if updated else ""

    lines = []
    lines.append(f"* ACTIVE {name} :ai:")
    lines.append(f"  :PROPERTIES:")
    lines.append(f"  :URL:      {url}")
    lines.append(f"  :PROJECT:  ")
    if created_str:
        lines.append(f"  :OPENED:   {created_str}")
    if updated_str:
        lines.append(f"  :UPDATED:  {updated_str}")
    lines.append(f"  :END:")

    if opening:
        lines.append(f"  /{opening}/")
        lines.append("")

    if summary:
        # Take just the first sentence or up to 300 chars of the summary
        import re
        short = re.sub(r'\*+', '', summary)   # strip bold/italic markers
        short = re.sub(r'#+\s*', '', short)   # strip markdown headers
        short = re.sub(r'\s+', ' ', short).strip()
        if len(short) > 300:
            # Try to cut at a sentence boundary
            cutoff = short.find(". ", 150)
            if cutoff > 0:
                short = short[:cutoff + 1]
            else:
                short = short[:297] + "..."
        lines.append(f"  {short}")
        lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Convert Claude export to org-mode")
    parser.add_argument("conversations", help="Path to conversations.json")
    parser.add_argument("--after", help="Only include conversations updated after this date (YYYY-MM-DD)")
    parser.add_argument("--state", default="ACTIVE",
                        help="TODO state to assign (default: ACTIVE)")
    args = parser.parse_args()

    with open(args.conversations) as f:
        conversations = json.load(f)

    after_dt = None
    if args.after:
        after_dt = datetime.strptime(args.after, "%Y-%m-%d").replace(tzinfo=timezone.utc)

    # Sort by created_at ascending so oldest entries come first
    conversations.sort(key=lambda c: c.get("created_at", ""))

    header = f"""#+TITLE: Claude Chats
#+TODO: ACTIVE WAITING | DONE NOTDOING
#+STARTUP: overview

"""
    print(header, end="")

    count = 0
    skipped = 0
    for conv in conversations:
        updated = parse_date(conv.get("updated_at", ""))
        if after_dt and updated and updated < after_dt:
            skipped += 1
            continue

        print(make_org_entry(conv))
        count += 1

    sys.stderr.write(f"Wrote {count} entries")
    if skipped:
        sys.stderr.write(f", skipped {skipped} older than {args.after}")
    sys.stderr.write("\n")


if __name__ == "__main__":
    main()
