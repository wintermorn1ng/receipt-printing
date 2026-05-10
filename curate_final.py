#!/usr/bin/env python3
"""
精细筛选：从3064条候选中选出360条高质量小票诗句
标准：积极向上、完整自洽、长度适中(6-16字)、无晦涩词
"""
import json, random, re
from collections import defaultdict, Counter

import opencc
converter = opencc.OpenCC('t2s')
to_simp = converter.convert

# 加载原始池
with open('/Users/victor/Documents/codes/flutter/receipt-printing/poetry_pool_raw.json', encoding='utf-8') as f:
    raw = json.load(f)
print(f"Loaded {len(raw)} raw entries")

# ── 精细过滤规则 ─────────────────────────────────────
NEGATIVE = set(['愁','怨','恨','悲','哭','亡','鬼','坟','墓','骨','泪','孤',
                 '独','寂','灭','苦','痛','病','穷','饥','寒','哀','怜','伤',
                 '凄','断肠','心碎','绝望','颓','堕','朽','污','秽','妖',
                 '贼','盗','匪','奸','邪','佞'])

# 太悲凉/消沉的词
SAD_MODIFIERS = ['萧瑟','萧条','凄凉','凄迷','惨淡','惨然','惘然','茫然',
                  '消魂','断魂','伤神','伤心','碎心','寒心','灰心','死心',
                  '泪','泣','啼','嚎','哀嚎']

# 太长/太短
TOO_LONG = 24   # 超过24字不要
TOO_SHORT = 6   # 少于6字不要

# 不适合小票的碎片词
BAD_TAIL = ['何时','几时','何妨','且莫','莫是','应是','疑是','却是',
            '却被','更被','却被','都被','都来','算来','浑如','争似',
            '谁肯','谁会','谁道','争奈','可奈','如何','怎生','甚时',
            '甚底','恁底','端的','遮莫','元来','元来','原来','则个']

BAD_HEAD = ['却笑','却道','更那堪','最怜','可奈','争奈','端的','遮莫',
            '长是','镇日','无个','不因','剩馥','半点','一寸','消得',
            '拚却','赢得','认得','都来','算来','浑若似','怎奈',
            '况值','且与','还似','还似','未省','那知','那管','不如']

# 标点类字符
PUNCT_START = set('，。、；：""''（）【』「」『')
PUNCT_END   = set('，、；：""''（）【』「」『')

# ── 辅助函数 ─────────────────────────────────────────
def is_good(text):
    """严格判断是否为适合小票的精品诗句"""
    # 长度
    if len(text) < TOO_SHORT or len(text) > TOO_LONG:
        return False
    # 标点起止
    if text[0] in PUNCT_START or text[-1] in PUNCT_END:
        return False
    # 碎片词
    for b in BAD_TAIL:
        if text.endswith(b):
            return False
    for b in BAD_HEAD:
        if text.startswith(b):
            return False
    # 负面词
    for n in NEGATIVE:
        if n in text:
            return False
    # 太悲凉的修饰词
    for s in SAD_MODIFIERS:
        if s in text:
            return False
    return True

def get_tag(text):
    """从内容推断节气/节日标签"""
    tags = []
    # 精确匹配季节
    if any(k in text for k in ['春','春风','春雨','春光','春色','春日','芳春','早春','新春']):
        tags.append('spring')
    elif any(k in text for k in ['夏','夏日','夏风','夏雨','暑气','清凉','荷香','莲']):
        tags.append('summer')
    elif any(k in text for k in ['秋','秋风','秋月','秋色','秋光','秋思','金秋','桂花','菊']):
        tags.append('autumn')
    elif any(k in text for k in ['冬','冬日','冬雪','瑞雪','寒','雪','霜','冰']):
        tags.append('winter')
    # 节日
    if any(k in text for k in ['除夕','新年','元日','元宵','灯','端午','重阳','中秋','月圆',
                                 '清明','踏青','七夕','鹊桥','春联','年节']):
        tags.append('festival')
    # 朝暮
    if any(k in text for k in ['晨','朝','晓','日出','曙光','晨光','破晓','黎明']):
        tags.append('morning')
    if any(k in text for k in ['夜','晚','暮','夕','黄昏','夕阳','月明','星光']):
        tags.append('evening')
    # 自然
    if any(k in text for k in ['山','水','江','海','湖','云','风','霞','烟','松','竹','梅','兰','菊',
                                 '桃','桂','荷','莲','泉','石','鸟','鱼','舟','帆','花','柳']):
        tags.append('nature')
    # 吉祥
    if any(k in text for k in ['福','喜','乐','丰','盈','满','金','玉','彩','瑞','祥','和','泰','盛',
                                 '华','新','明','光','清','飞','跃','腾','龙','凤','鹤','寿','康']):
        tags.append('blessing')
    return tags if tags else ['general']

def curate(entries):
    """精筛"""
    good = []
    for e in entries:
        text = e['text']
        if not is_good(text):
            continue
        tags = get_tag(text)
        e['tags'] = tags
        good.append(e)
    return good

# ── 筛选 ────────────────────────────────────────────
print("Curating...")
curated = curate(raw)
print(f"After curation: {len(curated)}")

# 按 tag 分布
tag_dist = Counter()
for p in curated:
    for t in p['tags']:
        tag_dist[t] += 1
print(f"Tag dist: {dict(tag_dist.most_common())}")

# ── 目标：每类取够，最后总数约360 ──────────────────
# 分配目标数量
TAG_TARGETS = {
    'spring':    40,
    'summer':    30,
    'autumn':    30,
    'winter':    30,
    'festival':  35,
    'morning':   25,
    'evening':   25,
    'nature':    60,
    'blessing':  70,
    'general':   40,
}

by_tag = defaultdict(list)
for p in curated:
    for t in p['tags']:
        by_tag[t].append(p)

selected = []
used_keys = set()

for tag, target in TAG_TARGETS.items():
    pool = by_tag.get(tag, [])
    # 打乱
    random.seed(42 + hash(tag) % 1000)
    random.shuffle(pool)
    count = 0
    for p in pool:
        key = p['text'][:6]
        if key in used_keys:
            continue
        used_keys.add(key)
        selected.append(p)
        count += 1
        if count >= target:
            break
    print(f"  {tag}: {count}/{target} (pool had {len(pool)})")

# 最终打乱
random.seed(2025)
random.shuffle(selected)
print(f"\nTotal selected: {len(selected)}")

# ── 长度分布 ─────────────────────────────────────────
len_dist = Counter()
for p in selected:
    l = len(p['text'])
    if l <= 8:   lens = '6-8'
    elif l <= 12: lens = '9-12'
    elif l <= 16: lens = '13-16'
    elif l <= 20: lens = '17-20'
    else:          lens = '21+'
    len_dist[lens] += 1
print(f"Length dist: {dict(sorted(len_dist.items()))}")

# ── 保存 ─────────────────────────────────────────────
out = '/Users/victor/Documents/codes/flutter/receipt-printing/poetry_pool_final.json'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(selected, f, ensure_ascii=False, indent=2)
print(f"\nSaved to {out}")

# ── 输出（按标签分组展示）────────────────────────────
print("\n" + "="*70)
for tag in ['spring','summer','autumn','winter','festival','morning','evening','nature','blessing','general']:
    pool = by_tag.get(tag, [])
    sel = [p for p in selected if tag in p.get('tags', [])]
    if not sel:
        continue
    print(f"\n══ {tag.upper()} ({len(sel)}条) ══════════════════════════")
    for p in sel:
        print(f"  [{len(p['text']):2d}] {p['text']}  —{p['author']}《{p['title']}》")
