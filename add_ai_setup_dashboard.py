import os

base = r'thepg\lib\features\setup_dashboard\screens'

ai_sliver = (
    "              // \u2500\u2500\u2500 AI Insights \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n"
    "              SliverToBoxAdapter(\n"
    "                child: Consumer<AIInsightsNotifier>(\n"
    "                  builder: (context, ai, _) {\n"
    "                    if (ai.insights.isEmpty) return const SizedBox.shrink();\n"
    "                    return Padding(\n"
    "                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),\n"
    "                      child: Container(\n"
    "                        decoration: BoxDecoration(\n"
    "                          color: kSetupColor.withOpacity(0.07),\n"
    "                          borderRadius: BorderRadius.circular(10),\n"
    "                        ),\n"
    "                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),\n"
    "                        child: Row(\n"
    "                          children: [\n"
    "                            const Icon(Icons.auto_awesome, size: 14, color: kSetupColor),\n"
    "                            const SizedBox(width: 8),\n"
    "                            Expanded(\n"
    "                              child: Text(\n"
    "                                'AI: ${ai.insights.first[\\'title\\'] ?? \\'\\'}',\n"
    "                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: kSetupColor),\n"
    "                                maxLines: 1, overflow: TextOverflow.ellipsis,\n"
    "                              ),\n"
    "                            ),\n"
    "                          ],\n"
    "                        ),\n"
    "                      ),\n"
    "                    );\n"
    "                  },\n"
    "                ),\n"
    "              ),\n"
)

fixed = 0
skipped = 0
for fname in sorted(os.listdir(base)):
    if not fname.endswith('.dart'):
        continue
    fpath = os.path.join(base, fname)
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    if 'Consumer<AIInsightsNotifier>' in content:
        skipped += 1
        print(f'SKIP (already has): {fname}')
        continue
    # Try inserting before first SliverPadding
    if 'SliverPadding(' in content:
        idx = content.index('SliverPadding(')
        line_start = content.rfind('\n', 0, idx) + 1
        new_content = content[:line_start] + ai_sliver + content[line_start:]
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'FIXED (SliverPadding): {fname}')
        fixed += 1
    elif 'SliverToBoxAdapter(' in content:
        first_idx = content.index('SliverToBoxAdapter(')
        if 'SliverToBoxAdapter(' in content[first_idx + 1:]:
            second_idx = content.index('SliverToBoxAdapter(', first_idx + 1)
            line_start = content.rfind('\n', 0, second_idx) + 1
            new_content = content[:line_start] + ai_sliver + content[line_start:]
        else:
            # Only one SliverToBoxAdapter - insert after it
            end_idx = content.index('SliverToBoxAdapter(') + len('SliverToBoxAdapter(')
            # find closing ),
            line_start = content.index('\n', end_idx) + 1
            new_content = content[:line_start] + ai_sliver + content[line_start:]
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f'FIXED (SliverToBoxAdapter): {fname}')
        fixed += 1
    else:
        print(f'WARN (no anchor found): {fname}')

print(f'\nDone: {fixed} fixed, {skipped} already had Consumer')
