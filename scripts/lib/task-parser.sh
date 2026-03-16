#!/bin/bash
# task-parser.sh — Parse tasks.md into structured data for pre-computed task briefs
# Sources into other scripts. Not meant to be run standalone.

# Parse tasks.md and output structured JSON for all tasks
# Usage: parse_all_tasks <tasks.md path>
parse_all_tasks() {
  local tasks_file="$1"
  python3 -c "
import re, json, sys

content = open('$tasks_file').read()
tasks = []
# Match ### T-<id>: <title> blocks
pattern = r'### (T-\d+):\s*(.+?)(?=\n)'
blocks = list(re.finditer(pattern, content))

for i, match in enumerate(blocks):
    task_id = match.group(1)
    title = match.group(2).strip()
    # Get the block content until next task or end
    start = match.end()
    end = blocks[i+1].start() if i+1 < len(blocks) else len(content)
    block = content[start:end]
    
    # Parse fields
    status = re.search(r'\*\*Status\*\*:\s*(\S+)', block)
    wired = re.search(r'\*\*Wired\*\*:\s*(\S+)', block)
    verified = re.search(r'\*\*Verified\*\*:\s*(\S+)', block)
    reqs = re.search(r'\*\*Requirements\*\*:\s*(.+)', block)
    desc = re.search(r'\*\*Description\*\*:\s*(.+)', block)
    acceptance = re.search(r'\*\*Acceptance\*\*:\s*(.+)', block)
    deps = re.search(r'\*\*Dependencies\*\*:\s*(.+)', block)
    
    # Detect phase from preceding ## Phase header
    phase_match = None
    phase_section = content[:match.start()]
    for pm in re.finditer(r'## Phase \d+:\s*(.+)', phase_section):
        phase_match = pm
    phase = phase_match.group(1).strip() if phase_match else 'Unknown'
    
    tasks.append({
        'id': task_id,
        'title': title,
        'status': status.group(1) if status else 'pending',
        'wired': wired.group(1) if wired else 'no',
        'verified': verified.group(1) if verified else 'no',
        'requirements': reqs.group(1).strip() if reqs else '',
        'description': desc.group(1).strip() if desc else '',
        'acceptance': acceptance.group(1).strip() if acceptance else '',
        'dependencies': deps.group(1).strip() if deps else 'none',
        'phase': phase
    })

print(json.dumps(tasks))
"
}

# Get the next actionable task using smart priority heuristic
# Priority = (number of tasks this unblocks) / (1 + dependency depth)
# Usage: get_next_task <tasks.md path>
get_next_task() {
  local tasks_file="$1"
  python3 -c "
import re, json, sys

content = open('$tasks_file').read()
tasks = []
pattern = r'### (T-\d+):\s*(.+?)(?=\n)'
blocks = list(re.finditer(pattern, content))

for i, match in enumerate(blocks):
    task_id = match.group(1)
    title = match.group(2).strip()
    start = match.end()
    end = blocks[i+1].start() if i+1 < len(content) and i+1 < len(blocks) else len(content)
    block = content[start:end]
    
    status = re.search(r'\*\*Status\*\*:\s*(\S+)', block)
    wired = re.search(r'\*\*Wired\*\*:\s*(\S+)', block)
    verified = re.search(r'\*\*Verified\*\*:\s*(\S+)', block)
    deps = re.search(r'\*\*Dependencies\*\*:\s*(.+)', block)
    reqs = re.search(r'\*\*Requirements\*\*:\s*(.+)', block)
    desc = re.search(r'\*\*Description\*\*:\s*(.+)', block)
    acceptance = re.search(r'\*\*Acceptance\*\*:\s*(.+)', block)
    
    phase_match = None
    phase_section = content[:match.start()]
    for pm in re.finditer(r'## Phase \d+:\s*(.+)', phase_section):
        phase_match = pm
    phase = phase_match.group(1).strip() if phase_match else 'Unknown'
    
    tasks.append({
        'id': task_id,
        'title': title,
        'status': status.group(1) if status else 'pending',
        'wired': wired.group(1) if wired else 'no',
        'verified': verified.group(1) if verified else 'no',
        'dependencies': deps.group(1).strip() if deps else 'none',
        'requirements': reqs.group(1).strip() if reqs else '',
        'description': desc.group(1).strip() if desc else '',
        'acceptance': acceptance.group(1).strip() if acceptance else '',
        'phase': phase
    })

task_map = {t['id']: t for t in tasks}
completed = {t['id'] for t in tasks if t['verified'] == 'yes' or t['status'] == 'completed'}

# Build reverse dependency graph: who does each task unblock?
unblocks = {t['id']: 0 for t in tasks}
for t in tasks:
    if t['dependencies'] != 'none':
        dep_ids = [d.strip() for d in t['dependencies'].split(',')]
        for did in dep_ids:
            did = did.strip()
            if did in unblocks:
                unblocks[did] += 1

# Find actionable tasks: pending/in_progress with all deps met
actionable = []
for t in tasks:
    if t['status'] in ('completed',) and t['verified'] == 'yes':
        continue  # already done
    if t['status'] == 'completed' and t['wired'] == 'yes' and t['verified'] == 'yes':
        continue
    # Check deps are met
    if t['dependencies'] != 'none':
        dep_ids = [d.strip() for d in t['dependencies'].split(',')]
        deps_met = all(d.strip() in completed for d in dep_ids)
        if not deps_met:
            continue
    # Priority score: tasks that unblock more are higher priority
    score = unblocks.get(t['id'], 0)
    actionable.append((score, t))

if not actionable:
    print(json.dumps(None))
    sys.exit(0)

# Sort by score descending (highest unblock potential first)
actionable.sort(key=lambda x: -x[0])
best = actionable[0][1]
print(json.dumps(best))
"
}

# Find independent task groups (tasks with no mutual dependencies that can run in parallel)
# Usage: get_parallel_groups <tasks.md path>
get_parallel_groups() {
  local tasks_file="$1"
  python3 -c "
import re, json, sys

content = open('$tasks_file').read()
tasks = []
pattern = r'### (T-\d+):\s*(.+?)(?=\n)'
blocks = list(re.finditer(pattern, content))

for i, match in enumerate(blocks):
    task_id = match.group(1)
    title = match.group(2).strip()
    start = match.end()
    end = blocks[i+1].start() if i+1 < len(blocks) else len(content)
    block = content[start:end]
    
    status = re.search(r'\*\*Status\*\*:\s*(\S+)', block)
    deps = re.search(r'\*\*Dependencies\*\*:\s*(.+)', block)
    verified = re.search(r'\*\*Verified\*\*:\s*(\S+)', block)
    
    tasks.append({
        'id': task_id,
        'title': title,
        'status': status.group(1) if status else 'pending',
        'verified': verified.group(1) if verified else 'no',
        'dependencies': deps.group(1).strip() if deps else 'none'
    })

completed = {t['id'] for t in tasks if t['verified'] == 'yes' or (t['status'] == 'completed' and t['verified'] == 'yes')}

# Find all actionable tasks
actionable = []
for t in tasks:
    if t['status'] == 'completed' and t['verified'] == 'yes':
        continue
    if t['dependencies'] != 'none':
        dep_ids = [d.strip() for d in t['dependencies'].split(',')]
        if not all(d in completed for d in dep_ids):
            continue
    actionable.append(t)

# Group tasks that don't depend on each other
# Two tasks can run in parallel if neither depends on the other
# and neither depends on an incomplete task that the other also depends on
dep_graph = {}
for t in tasks:
    if t['dependencies'] != 'none':
        dep_graph[t['id']] = set(d.strip() for d in t['dependencies'].split(','))
    else:
        dep_graph[t['id']] = set()

def can_parallel(a, b):
    \"\"\"Two tasks can run in parallel if neither depends on the other (transitively).\"\"\"
    # Check direct and transitive deps
    def all_deps(tid, visited=None):
        if visited is None:
            visited = set()
        if tid in visited:
            return visited
        visited.add(tid)
        for d in dep_graph.get(tid, set()):
            all_deps(d, visited)
        return visited
    
    a_deps = all_deps(a['id'])
    b_deps = all_deps(b['id'])
    return b['id'] not in a_deps and a['id'] not in b_deps

groups = []
used = set()
for i, t in enumerate(actionable):
    if t['id'] in used:
        continue
    group = [t]
    used.add(t['id'])
    for j, t2 in enumerate(actionable):
        if t2['id'] in used:
            continue
        if all(can_parallel(t2, g) for g in group):
            group.append(t2)
            used.add(t2['id'])
    groups.append([g['id'] for g in group])

print(json.dumps(groups))
"
}

# Find batchable tasks (same phase, similar type, no mutual dependencies)
# Usage: get_batch_tasks <tasks.md path> [max_batch_size]
get_batch_tasks() {
  local tasks_file="$1"
  local max_batch="${2:-3}"
  python3 -c "
import re, json, sys

content = open('$tasks_file').read()
tasks = []
pattern = r'### (T-\d+):\s*(.+?)(?=\n)'
blocks = list(re.finditer(pattern, content))

for i, match in enumerate(blocks):
    task_id = match.group(1)
    title = match.group(2).strip()
    start = match.end()
    end = blocks[i+1].start() if i+1 < len(blocks) else len(content)
    block = content[start:end]
    
    status = re.search(r'\*\*Status\*\*:\s*(\S+)', block)
    deps = re.search(r'\*\*Dependencies\*\*:\s*(.+)', block)
    verified = re.search(r'\*\*Verified\*\*:\s*(\S+)', block)
    desc = re.search(r'\*\*Description\*\*:\s*(.+)', block)
    
    phase_match = None
    phase_section = content[:match.start()]
    for pm in re.finditer(r'## Phase \d+:\s*(.+)', phase_section):
        phase_match = pm
    phase = phase_match.group(1).strip() if phase_match else 'Unknown'
    
    tasks.append({
        'id': task_id,
        'title': title,
        'status': status.group(1) if status else 'pending',
        'verified': verified.group(1) if verified else 'no',
        'dependencies': deps.group(1).strip() if deps else 'none',
        'description': desc.group(1).strip() if desc else '',
        'phase': phase
    })

completed = {t['id'] for t in tasks if t['verified'] == 'yes'}

# Find actionable tasks grouped by phase
phase_groups = {}
for t in tasks:
    if t['status'] == 'completed' and t['verified'] == 'yes':
        continue
    if t['dependencies'] != 'none':
        dep_ids = [d.strip() for d in t['dependencies'].split(',')]
        if not all(d in completed for d in dep_ids):
            continue
    phase_groups.setdefault(t['phase'], []).append(t)

# Find the largest batchable group from the same phase
best_batch = []
for phase, group in phase_groups.items():
    if len(group) >= 2:
        # Check they don't depend on each other
        group_ids = {g['id'] for g in group}
        independent = []
        for g in group:
            dep_ids = set(d.strip() for d in g['dependencies'].split(',')) if g['dependencies'] != 'none' else set()
            if not dep_ids.intersection(group_ids - {g['id']}):
                independent.append(g)
        if len(independent) > len(best_batch):
            best_batch = independent[:$max_batch]

if len(best_batch) < 2:
    # Not enough for a batch, return the single next task
    print(json.dumps(None))
else:
    print(json.dumps([b['id'] for b in best_batch]))
"
}

# Generate a compact task brief for a specific task ID
# Usage: generate_task_brief <tasks.md path> <task_id> [design.md path]
generate_task_brief() {
  local tasks_file="$1"
  local task_id="$2"
  local design_file="${3:-}"
  python3 -c "
import re, json, sys

content = open('$tasks_file').read()

# Find the specific task block
pattern = r'### ($task_id):\s*(.+?)(?=\n)'
match = re.search(pattern.replace('\$task_id', '$task_id'), content)
if not match:
    print('')
    sys.exit(1)

task_id = match.group(1)
title = match.group(2).strip()
start = match.end()

# Find end of this task block
next_task = re.search(r'### T-\d+:', content[start:])
end = start + next_task.start() if next_task else len(content)
block = content[start:end]

status = re.search(r'\*\*Status\*\*:\s*(\S+)', block)
reqs = re.search(r'\*\*Requirements\*\*:\s*(.+)', block)
desc = re.search(r'\*\*Description\*\*:\s*(.+)', block)
acceptance = re.search(r'\*\*Acceptance\*\*:\s*(.+)', block)
deps = re.search(r'\*\*Dependencies\*\*:\s*(.+)', block)

brief = {
    'task_id': task_id,
    'title': title,
    'description': desc.group(1).strip() if desc else '',
    'acceptance': acceptance.group(1).strip() if acceptance else '',
    'requirements': reqs.group(1).strip() if reqs else '',
    'dependencies': deps.group(1).strip() if deps else 'none'
}

print(json.dumps(brief))
"
}

# Count task statuses for progress.json
# Usage: count_task_statuses <tasks.md path>
count_task_statuses() {
  local tasks_file="$1"
  python3 -c "
import re, json

content = open('$tasks_file').read()
tasks = []
pattern = r'### (T-\d+):\s*(.+?)(?=\n)'
blocks = list(re.finditer(pattern, content))

total = len(blocks)
completed = 0
verified = 0
pending = 0
in_progress = 0
blocked = 0

for i, match in enumerate(blocks):
    start = match.end()
    end = blocks[i+1].start() if i+1 < len(blocks) else len(content)
    block = content[start:end]
    
    status = re.search(r'\*\*Status\*\*:\s*(\S+)', block)
    ver = re.search(r'\*\*Verified\*\*:\s*(\S+)', block)
    s = status.group(1) if status else 'pending'
    v = ver.group(1) if ver else 'no'
    
    if s == 'blocked':
        blocked += 1
    elif s == 'completed' and v == 'yes':
        verified += 1
    elif s == 'completed':
        completed += 1
    elif s == 'in_progress':
        in_progress += 1
    else:
        pending += 1

print(json.dumps({
    'total': total,
    'verified': verified,
    'completed': completed,
    'in_progress': in_progress,
    'pending': pending,
    'blocked': blocked
}))
"
}
