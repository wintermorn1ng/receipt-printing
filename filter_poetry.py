#!/usr/bin/env python3
"""
从 chinese-poetry 语料库中筛选适合小票的诗句（简体、短小、积极、偏完整）
目标：~360条，带节气/节日分类标签
"""
import json, random, os, re
from collections import defaultdict

import opencc
converter = opencc.OpenCC('t2s')
def to_simp(text):
    return converter.convert(text)

# ── 过滤规则 ─────────────────────────────────────────
NEGATIVE = set(['愁','怨','恨','悲','哭','亡','鬼','坟','墓','骨','泪','孤',
                 '独','寂','灭','苦','痛','病','穷','饥','寒','哀','怜','伤',
                 '凄','断肠','心碎','绝望','无聊'])

# 烂大街排除
COMMON = ['床前明月光','疑是地上霜','举头望明月','低头思故乡',
    '春眠不觉晓','处处闻啼鸟','夜来风雨声','花落知多少',
    '白日依山尽','黄河入海流','欲穷千里目','更上一层楼',
    '锄禾日当午','汗滴禾下土','谁知盘中餐','粒粒皆辛苦',
    '千山鸟飞绝','万径人踪灭','孤舟蓑笠翁','独钓寒江雪',
    '月落乌啼霜满天','江枫渔火对愁眠','姑苏城外寒山寺',
    '寻寻觅觅冷冷清清','凄凄惨惨戚戚',
    '问君能有几多愁','恰似一江春水向东流',
    '莫等闲白了少年头','空悲切','人生自古谁无死','留取丹心照汗青',
    '但愿人长久','千里共婵娟','大江东去','浪淘尽千古风流人物',
    '明月几时有','把酒问青天','人有悲欢离合','月有阴晴圆缺',
    '春花秋月何时了','往事知多少','昨夜西风凋碧树','独上高楼望尽天涯路',
    '莫听穿林打叶声','何妨吟啸且徐行',
    '竹杖芒鞋轻胜马','谁怕一蓑烟雨任平生',
    '人生如逆旅','我亦是行人','世事一场大梦','人生几度秋凉',
    '小舟从此逝','江海寄余生','执手相看泪眼','竟无语凝噎',
    '今宵酒醒何处','杨柳岸晓风残月']

# ── 节气/节日标签 ────────────────────────────────────
SEASONAL_TAGS = {
    'spring':    ['春','春风','春雨','春光','春日','春色','春暖','春来','春归',
                   '芳春','早春','新春','初春','孟春','阳春','花开','桃红','柳绿',
                   '燕','莺','蝶','蜂','草长','花开','花枝','花香','花影','花落'],
    'summer':    ['夏','夏日','夏风','夏雨','暑','清凉','荷','莲','池','蝉',
                   '风扇','空调','薰风','赤日','炎'],
    'autumn':    ['秋','秋风','秋月','秋色','秋光','秋思','秋日','深秋','金秋',
                   '桂花','菊','黄叶','落叶','枫','红叶','天高','云淡','雁',
                   '芦','重阳','登高'],
    'winter':    ['冬','冬日','冬雪','瑞雪','寒','雪','霜','冰','寒风','凛',
                   '红炉','围炉','温酒','年节','除夕','新年','迎春'],
    'festival':  ['除夕','新年','元日','元','元宵','上元','灯','烟火','春联',
                   '端午','粽','艾','重阳','登高','中秋','月圆','团圆',
                   '清明','寒食','踏青','七夕','鹊桥','重阳','菊'],
    'morning':   ['晨','朝','晓','日出','曙光','晨光','破晓','闻鸡','鸡鸣'],
    'evening':   ['夜','晚','暮','夕','黄昏','夕阳','暮色','晚霞','星辰','月明','月光'],
    'nature':    ['山','水','江','海','湖','云','风','雨','霞','烟','松','竹',
                   '梅','兰','菊','桃','桂','荷','莲','泉','石','鸟','鱼','舟'],
    'positive':  ['福','喜','乐','丰','盈','满','金','玉','彩','瑞','祥','和',
                   '泰','盛','昌','荣','华','新','明','光','清','飞','跃','腾',
                   '龙','凤','鹤','松','竹','心','意','情','志','气','神',
                   '酒','茶','花','果','禾','稻','麦','家','门','堂','楼',
                   '年','岁','时','节','健','康','寿'],
}

def get_seasonal_tag(text):
    """给诗句打上节气/节日标签"""
    tags = []
    for tag, keywords in SEASONAL_TAGS.items():
        if any(kw in text for kw in keywords):
            tags.append(tag)
    return tags if tags else ['general']

# ── 完整句判定 ───────────────────────────────────────
# 排除明显是半句/上阙/下阙开头的碎片
FRAGMENT_PATTERNS = [
    re.compile(r'^[，。；：、\s]+'),   # 以标点开头
    re.compile(r'[，。；：、\s]+$'),   # 以标点结尾（已有，这行多余）
]
# 标点结尾才像完整句
ENDS_WITH_PUNCT = re.compile(r'[。！？]$')

def is_good_line(text):
    """判断是否是一条好的、完整的、可独立存在的诗句"""
    # 太短
    if len(text) < 6:
        return False
    # 太长（超过26字基本是超长句）
    if len(text) > 28:
        return False
    # 以标点开头或结尾（基本是碎片）
    if text[0] in '，。、；：""''（）【】' or text[-1] in '，、；：""''（）【':
        return False
    # 包含碎片的典型词
    fragments = ['却笑', '却道', '更那堪', '最怜', '可奈', '争奈', '端的', '遮莫',
                 '长是', '镇日', '无个', '不因', '贳得', '剩馥', '半点', '一寸',
                 '消得', '拚却', '赢得', '认得', '都来', '算来', '浑若是', '怎奈']
    for frag in fragments:
        if text.startswith(frag) or text.endswith(frag):
            return False
    return True

def passes(text, orig_text=None):
    if orig_text is None:
        orig_text = text
    if any(k in orig_text for k in NEGATIVE):
        return False
    if any(k in orig_text for k in COMMON):
        return False
    if not is_good_line(text):
        return False
    return True

# ── 数据加载 ─────────────────────────────────────────
def load_file(path):
    if os.path.getsize(path) < 100:
        return []
    with open(path, encoding='utf-8') as f:
        content = f.read().strip()
    if not content:
        return []
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        poems = []
        for line in content.split('\n'):
            line = line.strip()
            if line:
                try:
                    poems.append(json.loads(line))
                except:
                    pass
        return poems

seen_keys = {}
candidates = []

def add_candidates(poems, source):
    for p in poems:
        try:
            paras = p.get('paragraphs', [])
        except:
            continue
        for line in paras:
            orig = line.strip()
            if len(orig) < 4:
                continue
            simp = to_simp(orig)
            if not passes(simp, orig):
                continue
            key = simp[:8]
            if key in seen_keys:
                continue
            seen_keys[key] = True
            tags = get_seasonal_tag(simp)
            candidates.append({
                'text': simp,
                'author': to_simp(p.get('author','')),
                'title': to_simp(p.get('title') or p.get('rhythmic','')),
                'source': source,
                'tags': tags,
            })

# ── 处理所有文件 ─────────────────────────────────────
print("Processing Tang poems...")
for tf in sorted(os.listdir('/tmp')):
    if tf.startswith('tang_') and tf.endswith('.json') and os.path.getsize(f'/tmp/{tf}') > 1000:
        data = load_file(f'/tmp/{tf}')
        if data:
            add_candidates(data, '唐诗')
print(f"  Tang candidates: {len(candidates)}")

print("Processing Tang300...")
data = load_file('/tmp/tang300.json')
if data: add_candidates(data, '唐诗三百首')
print(f"  Tang300 candidates: {len(candidates)}")

print("Processing Song Ci...")
for cf in sorted(os.listdir('/tmp')):
    if cf.startswith('ci_') and cf.endswith('.json') and os.path.getsize(f'/tmp/{cf}') > 1000:
        data = load_file(f'/tmp/{cf}')
        if data:
            add_candidates(data, '宋词')
print(f"  Ci candidates: {len(candidates)}")

print("Processing Ci300...")
data = load_file('/tmp/ci300.json')
if data: add_candidates(data, '宋词三百首')
print(f"  Total candidates: {len(candidates)}")

# ── 按 source 均衡采样，目标 360+ ────────────────────
by_source = defaultdict(list)
for c in candidates:
    by_source[c['source']].append(c)

# 分配采样数：三百首质量高，给更多配额
SOURCE_QUOTA = {
    '唐诗三百首': 80,
    '宋词三百首': 80,
    '唐诗': 100,
    '宋词': 100,
}

final = []
for src, items in by_source.items():
    quota = SOURCE_QUOTA.get(src, 40)
    n = min(quota, len(items))
    sampled = random.sample(items, n) if items else []
    final.extend(sampled)
    print(f"  {src}: {len(items)} candidates, sampled {n}")

random.seed(2025)
random.shuffle(final)
print(f"\nFinal count: {len(final)}")

# ── 长度分布 ─────────────────────────────────────────
len_dist = defaultdict(int)
for p in final:
    blen = len(p['text'])
    if blen <= 10:   bucket = '≤10'
    elif blen <= 14:  bucket = '11-14'
    elif blen <= 18:  bucket = '15-18'
    elif blen <= 24:  bucket = '19-24'
    else:              bucket = '>24'
    len_dist[bucket] += 1
print(f"Length distribution: {dict(sorted(len_dist.items()))}")

# ── 按 tag 分布 ──────────────────────────────────────
tag_dist = defaultdict(int)
for p in final:
    for tag in p['tags']:
        tag_dist[tag] += 1
print(f"Tag distribution: {dict(sorted(tag_dist.items(), key=lambda x:-x[1]))}")

# ── 保存 ─────────────────────────────────────────────
out = '/Users/victor/Documents/codes/flutter/receipt-printing/poetry_pool_raw.json'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(final, f, ensure_ascii=False, indent=2)
print(f"\nSaved to {out}")

# ── 预览（按tag分组） ────────────────────────────────
print("\n=== 预览（按标签分组）===")
by_tag = defaultdict(list)
for p in final:
    for tag in p['tags']:
        by_tag[tag].append(p)

for tag in ['spring','summer','autumn','winter','festival','morning','evening','nature','positive','general']:
    if tag in by_tag and by_tag[tag]:
        print(f"\n── {tag.upper()} ({len(by_tag[tag])}条) ──")
        for p in by_tag[tag][:20]:
            print(f"  [{len(p['text']):2d}] {p['text']}  —{p['author']}《{p['title']}》")
