"""Turns analyzer and test output into one GitHub Actions error annotation.

Annotations show up on the run's summary page and through the GitHub API,
which makes failures easy to read without opening the full log.

Usage:
  python3 .github/scripts/annotate.py analyze analyze.txt
  python3 .github/scripts/annotate.py tests test-report.json
"""

import json
import sys

LIMIT = 30000


def emit(title, text):
    text = text.strip()[:LIMIT] or 'No details were captured.'
    text = text.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    print(f'::error title={title}::{text}')


def analyze(path):
    with open(path, encoding='utf-8', errors='replace') as file:
        lines = [line.strip() for line in file]
    issues = [line for line in lines if ' • ' in line]
    emit('flutter analyze', '\n'.join(issues) if issues else '\n'.join(lines))


def tests(path):
    names = {}
    output = {}
    failed = []
    with open(path, encoding='utf-8', errors='replace') as file:
        for raw in file:
            raw = raw.strip()
            if not raw.startswith('{'):
                continue
            try:
                event = json.loads(raw)
            except ValueError:
                continue
            kind = event.get('type')
            if kind == 'testStart':
                test = event.get('test', {})
                names[test.get('id')] = test.get('name', '?')
            elif kind == 'print':
                output.setdefault(event.get('testID'), []).append(
                    event.get('message', ''))
            elif kind == 'error':
                test_id = event.get('testID')
                stack = '\n'.join(event.get('stackTrace', '').splitlines()[:12])
                output.setdefault(test_id, []).append(
                    event.get('error', '') + '\n' + stack)
            elif kind == 'testDone' and event.get('result') != 'success':
                if not event.get('hidden'):
                    failed.append(event.get('testID'))
    parts = []
    for test_id in failed:
        details = '\n'.join(output.get(test_id, []))
        parts.append(f'### {names.get(test_id, test_id)}\n{details[:6000]}')
    emit(f'{len(failed)} failing tests', '\n\n'.join(parts))


def publish(path):
    with open(path, encoding='utf-8', errors='replace') as file:
        lines = [line.rstrip() for line in file]
    start = next((i for i, line in enumerate(lines)
                  if 'validation' in line.lower() or 'warning' in line.lower()),
                 max(0, len(lines) - 60))
    emit('pub publish --dry-run', '\n'.join(lines[start:]))


if __name__ == '__main__':
    {'analyze': analyze, 'tests': tests, 'publish': publish}[sys.argv[1]](
        sys.argv[2])
