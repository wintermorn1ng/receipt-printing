#!/usr/bin/env python3
"""最终清理 + 生成 Dart 常量文件"""
import json, re

# 需要剔除的诗句（人工审核后确认太悲/太散的）
REMOVE = {
    '春心莫共花争发，一寸相思一寸灰',  # 太悲情
    '春梦秋云，聚散真容易',              # 太感慨聚散
    '离人心上秋',                         # 谐音"离人"，略伤感
    '春草明年绿，王孙归不归',            # 思念主题
    '多情只有春庭月，犹为离人照落花',    # 离人
    '年年越溪女，相忆采芙蓉',            # 思念
    '东舟西舫悄无言，唯见江心秋月白',    # 太静谧忧郁
    '人生在世不称意，明朝散发弄扁舟',    # 消极避世
    '世间行乐亦如此，古来万事东流水',    # 消极
    '醉不成欢惨将别，别时茫茫江浸月',    # 太伤感
    '寓目魂将断，经年怨亦深',            # 太怨
    '故欹单枕梦中寻，梦又不成灯又尽',    # 太悲
    '今为羗笛出塞声，使我三军泪如雨',    # 太悲壮
    '变调如闻杨柳春，上林繁花照眼新',    # OK but 略弱
    '念永昼春闲，人倦如何度',            # 太慵懒
    '春山眉黛低',                         # 碎片
    '已失春风一半',                       # 伤感
    '城下烟波春拍岸',                     # 一般
    '闲花淡淡春',                         # 碎片
    '春来遍是桃花水，不辨仙源何处寻',    # 略虚无
    '朱颜空自改，向年年、芳意长新',      # 感慨衰老
    '无情有思',                           # 碎片
    '如今鬓影凄红',                       # 缺前文
    '垂杨暗吴苑',                         # 碎片
    '玉纤曾擘黄柑，柔香系幽素',          # 尚可但偏脂粉气
}

with open('/Users/victor/Documents/codes/flutter/receipt-printing/poetry_pool_final.json', encoding='utf-8') as f:
    pool = json.load(f)

# 剔除
clean = [p for p in pool if p['text'] not in REMOVE]
print(f"After removal: {len(pool)} -> {len(clean)}")

# 重新去重（按前8字）
seen = set()
deduped = []
for p in clean:
    key = p['text'][:8]
    if key not in seen:
        seen.add(key)
        deduped.append(p)

print(f"After dedup: {len(deduped)}")

# 按 tag 统计
from collections import Counter, defaultdict
tag_count = Counter()
for p in deduped:
    for t in p['tags']:
        tag_count[t] += 1
print(f"Tag dist: {dict(tag_count.most_common())}")

# ── 生成 Dart 文件 ────────────────────────────────────
dart_lines = []
dart_lines.append("// GENERATED from 唐诗三百首 + 宋词三百首 — do not edit manually")
dart_lines.append("// Total: {} poems".format(len(deduped)))
dart_lines.append("")
dart_lines.append("class ClassicalPoetry {")
dart_lines.append("  final String text;")
dart_lines.append("  final String author;")
dart_lines.append("  final String title;")
dart_lines.append("  final List<String> tags;")
dart_lines.append("")
dart_lines.append("  const ClassicalPoetry({")
dart_lines.append("    required this.text,")
dart_lines.append("    required this.author,")
dart_lines.append("    required this.title,")
dart_lines.append("    required this.tags,")
dart_lines.append("  });")
dart_lines.append("}")
dart_lines.append("")
dart_lines.append("const List<String> _poetryTags = [")
tag_order = ['spring','summer','autumn','winter','festival','morning','evening','nature','blessing','general']
for tag in tag_order:
    if tag in tag_count:
        dart_lines.append(f"  // {tag}: {tag_count[tag]}")
        break

# 按 tag 分组写入
by_tag = defaultdict(list)
for p in deduped:
    for t in p['tags']:
        by_tag[t].append(p)

# 写入 allPoems
dart_lines.append("];")
dart_lines.append("")
dart_lines.append("const List<ClassicalPoetry> allPoems = [")
for p in deduped:
    tags_str = "[" + ", ".join(f"'{t}'" for t in p['tags']) + "]"
    dart_lines.append(
        f"  ClassicalPoetry(text: '{p['text']}', author: '{p['author']}', "
        f"title: '{p['title']}', tags: {tags_str}),"
    )
dart_lines.append("];")
dart_lines.append("")

# 按 tag 分组列表
for tag in tag_order:
    if tag in by_tag and by_tag[tag]:
        dart_lines.append(f"// {tag.upper()} ({len(by_tag[tag])} poems)")
        dart_lines.append(f"const List<ClassicalPoetry> poems{tag.capitalize()} = [")
        for p in by_tag[tag]:
            tags_str = "[" + ", ".join(f"'{t}'" for t in p['tags']) + "]"
            dart_lines.append(
                f"  ClassicalPoetry(text: '{p['text']}', author: '{p['author']}', "
                f"title: '{p['title']}', tags: {tags_str}),"
            )
        dart_lines.append("];")
        dart_lines.append("")

dart_content = "\n".join(dart_lines)

out_dart = '/Users/victor/Documents/codes/flutter/receipt-printing/lib/data/classical_poetry.dart'
with open(out_dart, 'w', encoding='utf-8') as f:
    f.write(dart_content)
print(f"\nDart file saved to {out_dart}")

# 同时保存一份 JSON
out_json = '/Users/victor/Documents/codes/flutter/receipt-printing/poetry_pool_clean.json'
with open(out_json, 'w', encoding='utf-8') as f:
    json.dump(deduped, f, ensure_ascii=False, indent=2)
print(f"JSON saved to {out_json}")
print(f"\nFinal poem count: {len(deduped)}")
