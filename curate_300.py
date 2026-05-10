#!/usr/bin/env python3
"""
从「唐诗三百首」「宋词三百首」中精选高质量单句（简体、积极、短小、偏完整）
"""
import json, random, re
import opencc

converter = opencc.OpenCC('t2s')
to_simp = converter.convert

NEGATIVE = set(['愁','怨','恨','悲','哭','亡','鬼','坟','墓','骨','泪','孤',
                 '独','寂','灭','苦','痛','病','穷','饥','寒','哀','怜','伤',
                 '凄','断肠','心碎','绝望','无聊','颓','堕','腐','朽'])

COMMON = ['床前明月光','疑是地上霜','举头望明月','低头思故乡',
    '春眠不觉晓','处处闻啼鸟','夜来风雨声','花落知多少',
    '白日依山尽','黄河入海流','欲穷千里目','更上一层楼',
    '锄禾日当午','汗滴禾下土','谁知盘中餐','粒粒皆辛苦',
    '千山鸟飞绝','万径人踪灭','孤舟蓑笠翁','独钓寒江雪',
    '月落乌啼霜满天','江枫渔火对愁眠',
    '寻寻觅觅冷冷清清','凄凄惨惨戚戚',
    '问君能有几多愁','恰似一江春水向东流',
    '莫等闲白了少年头','空悲切','人生自古谁无死','留取丹心照汗青',
    '但愿人长久','千里共婵娟','大江东去','浪淘尽千古风流人物',
    '明月几时有','把酒问青天','人有悲欢离合','月有阴晴圆缺',
    '春花秋月何时了','往事知多少',
    '昨夜西风凋碧树','独上高楼望尽天涯路',
    '莫听穿林打叶声','何妨吟啸且徐行',
    '竹杖芒鞋轻胜马','谁怕一蓑烟雨任平生',
    '人生如逆旅','我亦是行人',
    '世事一场大梦','人生几度秋凉',
    '小舟从此逝','江海寄余生',
    '执手相看泪眼','竟无语凝噎',
    '今宵酒醒何处','杨柳岸晓风残月',
    '一蓑烟雨任平生','也无风雨也无晴']

SEASONAL_KEYWORDS = {
    'spring':    ['春','春风','春雨','春光','春日','春色','春暖','春来','芳春','早春','新春',
                   '桃红','柳绿','燕','莺','蝶','蜂','花开','花枝','花香','草长','杨柳','杏花','海棠'],
    'summer':    ['夏','夏日','夏风','夏雨','暑','清凉','荷','莲','池','蝉','薰风','赤日','炎'],
    'autumn':    ['秋','秋风','秋月','秋色','秋光','秋思','秋日','深秋','金秋','桂花','菊','黄叶',
                   '落叶','枫','红叶','天高','云淡','雁','芦','登高','重阳'],
    'winter':    ['冬','冬日','冬雪','瑞雪','寒','雪','霜','冰','寒风','凛冽','红炉','围炉','温酒',
                   '年节','除夕','新年','迎春','梅花'],
    'festival':  ['除夕','新年','元日','元','元宵','灯','烟火','春联','端午','粽','艾',
                   '重阳','登高','中秋','月圆','团圆','清明','踏青','七夕','鹊桥'],
    'morning':   ['晨','朝','晓','日出','曙光','晨光','破晓','闻鸡','鸡鸣','黎明'],
    'evening':   ['夜','晚','暮','夕','黄昏','暮色','夕阳','晚霞','星辰','月明','月光','夜深'],
    'nature':    ['山','水','江','海','湖','云','风','雨','霞','烟','松','竹',
                   '梅','兰','菊','桃','桂','荷','莲','泉','石','鸟','鱼','舟','帆'],
    'blessing':  ['福','喜','乐','丰','盈','满','金','玉','彩','瑞','祥','和','泰','盛','昌','荣',
                   '华','新','明','光','清','飞','跃','腾','龙','凤','鹤','心','意','情','志',
                   '气','神','酒','茶','花','果','禾','稻','家','年','岁','寿','康','健'],
}

def get_tags(text):
    tags = []
    for tag, kws in SEASONAL_KEYWORDS.items():
        if any(k in text for k in kws):
            tags.append(tag)
    return tags if tags else ['general']

def good_line(text):
    """判断是否为一条好的独立诗句"""
    # 长度合理
    if len(text) < 6 or len(text) > 26:
        return False
    # 不以标点开头/结尾
    if text[0] in '，。、；：""''（）【':
        return False
    if text[-1] in '，、；：""''（）【':
        return False
    # 不是碎片化词句
    bad_fragments = ['却笑','却道','更那堪','最怜','可奈','争奈','端的','遮莫',
                     '长是','镇日','无个','不因','贳得','剩馥','半点','一寸',
                     '消得','拚却','赢得','认得','都来','算来','浑若似','怎奈',
                     '向人','于人','于人','从他','从他']
    for bf in bad_fragments:
        if text.startswith(bf) or text.endswith(bf):
            return False
    return True

def passes(text, orig):
    if any(k in orig for k in NEGATIVE):
        return False
    if any(k in orig for k in COMMON):
        return False
    if not good_line(text):
        return False
    return True

def extract_lines(poems, source):
    results = []
    seen_keys = set()
    for p in poems:
        paras = p.get('paragraphs', [])
        for line in paras:
            orig = line.strip()
            if len(orig) < 4:
                continue
            simp = to_simp(orig)
            if not passes(simp, orig):
                continue
            key = simp[:6]
            if key in seen_keys:
                continue
            seen_keys.add(key)
            tags = get_tags(simp)
            results.append({
                'text': simp,
                'author': to_simp(p.get('author','')),
                'title': to_simp(p.get('title') or p.get('rhythmic','')),
                'source': source,
                'tags': tags,
            })
    return results

# 加载数据
print("Loading 唐诗三百首...")
with open('/tmp/tang300.json', encoding='utf-8') as f:
    tang300 = json.load(f)
print(f"  {len(tang300)} poems")

print("Loading 宋词三百首...")
with open('/tmp/ci300.json', encoding='utf-8') as f:
    ci300 = json.load(f)
print(f"  {len(ci300)} poems")

# 提取
tang_lines = extract_lines(tang300, '唐诗三百首')
ci_lines = extract_lines(ci300, '宋词三百首')

print(f"\n唐诗三百首 extracted: {len(tang_lines)} good lines")
print(f"宋词三百首 extracted: {len(ci_lines)} good lines")

all_lines = tang_lines + ci_lines
print(f"Total: {len(all_lines)}")

# 随机打乱后取全部（这两个精选集质量高，全部保留）
random.seed(2025)
random.shuffle(all_lines)
print(f"Final count: {len(all_lines)}")

# 长度分布
from collections import Counter
lens = Counter()
for p in all_lines:
    l = len(p['text'])
    if l <= 8:    lens['6-8'] += 1
    elif l <= 12: lens['9-12'] += 1
    elif l <= 16: lens['13-16'] += 1
    elif l <= 20: lens['17-20'] += 1
    else:         lens['21+'] += 1
print(f"Length dist: {dict(lens)}")

# Tag分布
tags_count = Counter()
for p in all_lines:
    for t in p['tags']:
        tags_count[t] += 1
print(f"Tag dist: {dict(tags_count.most_common())}")

# 保存
out = '/Users/victor/Documents/codes/flutter/receipt-printing/poetry_pool_raw.json'
with open(out, 'w', encoding='utf-8') as f:
    json.dump(all_lines, f, ensure_ascii=False, indent=2)
print(f"\nSaved to {out}")

# 预览
print("\n=== 预览 ===")
for i, p in enumerate(all_lines[:200]):
    print(f"[{i:3d}][{len(p['text']):2d}] {p['text']}  —{p['author']}《{p['title']}》[{','.join(p['tags'])}]")
