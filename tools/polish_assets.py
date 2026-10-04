"""Build the game's small, editable vector props and minimal HUD scene."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
SPRITES = ROOT / 'assets/sprites'

def svg(name, width, height, content):
    (SPRITES / (name + '.svg')).write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">'
        f'<g stroke="#111111" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">{content}</g></svg>', encoding='utf-8')

svg('tree', 40, 44, '<path d="M17 27h7v14h-7z" fill="#a87038"/><path d="M8 30C-2 24 4 13 10 13C8 0 29-1 31 13C42 14 42 28 32 31C25 35 17 35 8 30Z" fill="#36c653"/>')
for role, color in [('blue', '#0066ff'), ('red', '#ff323d'), ('peaceful', '#fff9ed')]:
    svg('person_' + role, 32, 36,
        f'<path d="M10 18C4 20 4 27 7 28L11 25M22 18C28 20 28 27 25 28L21 25" fill="{color}"/>'
        f'<path d="M10 17h12l1 10C23 37 9 37 9 27Z" fill="{color}"/>'
        f'<ellipse cx="16" cy="11" rx="13" ry="9" fill="{color}"/>'
        '<ellipse cx="12" cy="11" rx="1.5" ry="2.5" fill="#111111" stroke="none"/>'
        '<ellipse cx="20" cy="11" rx="1.5" ry="2.5" fill="#111111" stroke="none"/>')
for team, color in [('blue', '#0066ff'), ('red', '#ff323d')]:
    svg('gate_' + team, 44, 48, f'<path d="M5 44V20C5 0 39 0 39 20V44h-9V21C30 10 14 10 14 21v23Z" fill="{color}"/><path d="M17 7l5 5 5-5" fill="none" stroke="#fff" stroke-width="2"/>')
    svg('camp_' + team, 72, 80, f'<path d="M6 70L36 23 66 70Z" fill="{color}"/><path d="M36 39L25 70h22Z" fill="#252b34"/><path d="M36 4v21" fill="none"/><path d="M37 5h24l-6 8 6 8H37Z" fill="{color}"/><path d="M3 71h66" fill="none"/>')
svg('village', 112, 76, '<rect x="8" y="35" width="30" height="30" rx="2" fill="#fff2cc"/><path d="M3 36l20-19 20 19Z" fill="#36c653"/><rect x="36" y="26" width="40" height="40" rx="2" fill="#fff2cc"/><path d="M30 27L56 5l26 22Z" fill="#36c653"/><rect x="75" y="35" width="29" height="30" rx="2" fill="#fff2cc"/><path d="M70 36l20-19 20 19Z" fill="#36c653"/><path d="M48 66V45q8-9 16 0v21" fill="#a87038"/><path d="M19 65V51h9v14M85 65V51h9v14" fill="#a87038"/><circle cx="56" cy="30" r="4" fill="#ffce38"/>')
svg('seed', 20, 24, '<path d="M10 3C2 8 1 14 5 19C9 24 17 20 17 14C17 9 13 6 10 3Z" fill="#ffce38"/><path d="M7 15l5-7" fill="none" stroke="#fff2cc" stroke-width="2"/>')
svg('sword', 16, 34, '<path d="M5 23V7l3-5 3 5v16Z" fill="#e9f4ff" stroke-width="2"/><path d="M2 23h12M8 24v7" fill="none" stroke="#111" stroke-width="3"/><path d="M8 25v4" stroke="#ffce38" stroke-width="3"/>')
svg('peace_halo', 30, 12, '<ellipse cx="15" cy="6" rx="12" ry="3" fill="none" stroke="#ffce38" stroke-width="2"/>')
svg('anomaly_marker', 36, 40, '<path d="M4 12L1 4l9 3M26 7l9-3-3 8" fill="#ffce38" stroke-width="2"/>')
svg('ring', 44, 44, '<circle cx="22" cy="22" r="18" fill="none" stroke="#fff" stroke-width="2"/>')
svg('placement', 40, 40, '<rect x="3" y="3" width="34" height="34" rx="9" fill="#fff" fill-opacity=".12" stroke="#fff" stroke-width="2"/><path d="M20 13v14M13 20h14" stroke="#fff" stroke-width="2"/>')

parts = ['[gd_scene load_steps=3 format=3]', '[ext_resource type="Script" path="res://scripts/ui/hud.gd" id="1"]', '[ext_resource type="Theme" path="res://resources/ui_theme.tres" id="2"]']
def node(name, kind, parent=None, props=''):
    parts.append(f'[node name="{name}" type="{kind}"' + (f' parent="{parent}"' if parent else '') + ']\n' + props)
def rect(x,y,w,h):
    return f'offset_left = {float(x)}\noffset_top = {float(y)}\noffset_right = {float(x+w)}\noffset_bottom = {float(y+h)}\n'
def label(name,parent,x,y,w,h,text,size=14,center=False,light=False):
    node(name,'Label',parent,rect(x,y,w,h)+f'mouse_filter = 2\ntheme_override_font_sizes/font_size = {size}\ntext = {json.dumps(text, ensure_ascii=False)}\n' + ('horizontal_alignment = 1\n' if center else '') + ('theme_override_colors/font_color = Color(1, 0.96, 0.89, 1)\n' if light else ''))
def button(name,parent,x,y,w,h,text):
    node(name,'Button',parent,rect(x,y,w,h)+f'focus_mode = 0\ntext = "{text}"\n')
node('HUD','CanvasLayer',props='script = ExtResource("1")')
node('Root','Control','.', 'layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 2\ntheme = ExtResource("2")')
node('TopBar','ColorRect','Root',rect(0,0,1080,48)+'mouse_filter = 0\ncolor = Color(0.98, 0.96, 0.90, 1)')
label('Title','Root/TopBar',20,9,190,30,'ART OF PEACE',18)
label('Level','Root/TopBar',215,12,100,24,'LEVEL 1')
label('Seeds','Root/TopBar',330,10,130,28,'Seeds 0',16)
label('Alive','Root/TopBar',485,10,190,28,'Rescued 0 / 5',16)
node('Progress','ProgressBar','Root/TopBar',rect(485,39,175,3)+'mouse_filter = 2\nshow_percentage = false')
button('SpeedButton','Root/TopBar',710,7,65,34,'1x')
button('MarchButton','Root/TopBar',785,7,76,34,'Pause')
button('RestartButton','Root/TopBar',871,7,86,34,'Restart')
button('SoundButton','Root/TopBar',967,7,93,34,'Sound on')
label('Message','Root',125,733,825,22,'Hover seeds to collect · Click to plant · Right-click to remove',12,True)
node('StartPanel','ColorRect','Root', 'anchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 0\ncolor = Color(0.07, 0.12, 0.09, 0.50)')
node('Card','Panel','Root/StartPanel',rect(305,190,470,365))
label('Title','Root/StartPanel/Card',20,28,430,55,'ART OF PEACE',34,True)
label('Goal','Root/StartPanel/Card',30,92,410,32,'Guide 5 people home.',19,True)
label('Instructions','Root/StartPanel/Card',30,141,410,80,'Plant trees to guide each army through its color gate.\nKeep peaceful people safe until they reach the village.\n\nHover: collect seeds   ·   Click: plant   ·   Right-click: remove',13,True)
button('StartButton','Root/StartPanel/Card',125,257,220,54,'Start match')
label('Hint','Root/StartPanel/Card',30,321,410,24,'Space: pause   ·   F: speed   ·   R: restart',12,True)
node('GameOver','ColorRect','Root', 'visible = false\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nmouse_filter = 0\ncolor = Color(0.07, 0.12, 0.09, 0.86)')
label('Title','Root/GameOver',220,236,640,55,'PEACE RESTORED',32,True,True)
label('Details','Root/GameOver',220,310,640,55,'Everyone made it home.',18,True,True)
label('Hint','Root/GameOver',220,380,640,28,'Level 1',14,True,True)
button('ContinueButton','Root/GameOver',430,438,220,54,'Next level')
button('RetryButton','Root/GameOver',430,438,220,54,'Try again')
(ROOT / 'scenes/ui/hud.tscn').write_text('\n\n'.join(parts).rstrip()+'\n', encoding='utf-8')

for path in [ROOT/'scenes/entities'/n for n in ['tree.tscn','village.tscn','army_camp.tscn','peace_gate.tscn','seed.tscn','ripple.tscn','person.tscn']] + [ROOT/'scripts/entities/camp.gd', ROOT/'scripts/entities/gate.gd', ROOT/'scenes/world/forest.tscn',ROOT/'main.tscn']:
    text = path.read_text(encoding='utf-8-sig')
    for asset in ['tree','village','camp_blue','camp_red','gate_blue','gate_red','seed','ring','peace_halo','anomaly_marker','placement']:
        text = text.replace(f'assets/sprites/{asset}.png', f'assets/sprites/{asset}.svg')
    path.write_text(text, encoding='utf-8')

# All three authored characters now share the visible sprite, so conversion swaps correctly.
for name, props in [('blue_soldier',''),('red_soldier','team = 1\n'),('peaceful_person','team = -1\npeaceful = true\n')]:
    path=ROOT/f'scenes/entities/{name}.tscn'
    path.write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="PackedScene" path="res://scenes/entities/person.tscn" id="1"]\n\n[node name="'+''.join(w.title() for w in name.split('_'))+'" instance=ExtResource("1")]\n'+props, encoding='utf-8')

print('Built matching vector props and minimal HUD.')
