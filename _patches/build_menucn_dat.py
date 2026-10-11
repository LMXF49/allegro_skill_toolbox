# -*- coding: utf-8 -*-
# 构建 menucn_zh.dat：英文标签|中文标签（GBK）
#   中文来源优先级：① 17.4 官方中文 dump（按 command 对齐）
#                  ② translate_men166_labels.py 的手工映射（按标签对齐）
import re, sys, io
sys.path.insert(0, r'G:\ASTB\_patches')
import importlib.util
spec = importlib.util.spec_from_file_location("tm", r'G:\ASTB\_patches\translate_men166_labels.py')
tm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tm)   # 会顺便重写 16.6 的 cuimenus_zh 文件，无妨（目录已删则重建）
HAND = tm.MAP

MEN166 = r'D:\Cadence\SPB_16.6\share\pcb\text\cuimenus\allegro.men'
ZHDUMP = r'D:\Temp\menu_dump.txt'
OUT    = r'G:\ASTB\skill_src\config\menucn_zh.dat'

item = re.compile(r'^\s*(?:POPUP|MENUITEM)\s+"([^"]*)"(?:\s*,\s*"([^"]*)")?')

# ① 官方中文：command -> zhLabel
zh_by_cmd = {}
zh_popup_labels = set()
for line in io.open(ZHDUMP, encoding='gbk'):
    m = item.match(line)
    if not m: continue
    lab, cmd = m.group(1), m.group(2)
    if cmd:
        zh_by_cmd.setdefault(cmd.strip(), lab)
    else:
        zh_popup_labels.add(lab)

# 16.6 英文标签全集（按出现序）
en_labels = []
en_cmd = {}
for line in io.open(MEN166, encoding='ascii'):
    m = item.match(line)
    if not m: continue
    lab, cmd = m.group(1), m.group(2)
    if lab not in en_cmd:
        en_labels.append(lab)
        en_cmd[lab] = (cmd or '').strip()

official, hand, miss = 0, 0, []
rows = []
for lab in en_labels:
    cmd = en_cmd[lab]
    zh = None
    if cmd and cmd in zh_by_cmd:
        zh = zh_by_cmd[cmd]; official += 1
    elif lab in HAND:
        zh = HAND[lab]; hand += 1
    if zh:
        rows.append('%s|%s' % (lab, zh))
    else:
        miss.append(lab)

with open(OUT, 'wb') as f:
    f.write(('# ASTB 菜单汉化映射（16.6 运行期重标签用）\n'
             '# 格式: 英文标签|中文标签   生成: build_menucn_dat.py\n').encode('gbk'))
    f.write(('\n'.join(rows) + '\n').encode('gbk'))
print('official:', official, 'hand:', hand, 'miss:', len(miss), 'rows:', len(rows))
for x in miss[:15]:
    print('MISS:', x)
