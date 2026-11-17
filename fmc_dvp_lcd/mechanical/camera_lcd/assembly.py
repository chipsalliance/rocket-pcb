"""Generate screw-retained FDM camera and LCD supports.

Run with FreeCADCmd or the mechanical CMake target. Part STEP files use
assembly coordinates. STL files use the recorded flat printing orientation.
Reference modules are nominal. Cable travel and physical fit need validation.
"""
from pathlib import Path
import hashlib
import json
import math
import os
import sys

import FreeCAD as A
import Mesh
import MeshPart
import Part

S = Path(__file__).resolve().parent
P = S.parents[1]
R = Path(os.environ.get('FMC_MECHANICAL_OUTPUT', str(P / 'build/mechanical/camera_lcd'))).resolve()
R.mkdir(parents=True, exist_ok=True)
config = json.loads((S / 'parameters.json').read_text())
V = A.Vector
parts = []
pivots = {'camera': config['camera_pivot_cad_mm'], 'lcd': config['lcd_pivot_cad_mm']}


def box(x, y, z, w, d, h):
    return Part.makeBox(w, d, h, V(x, y, z))


def cyl(x, y, z, radius, length, axis=V(0, 0, 1)):
    return Part.makeCylinder(radius, length, V(x, y, z), axis)


def union(shapes):
    result = shapes[0]
    for shape in shapes[1:]:
        result = result.fuse(shape)
    return result.removeSplitter()


def rounded_plate(x, y, z, width, depth, height, radius=1.2):
    return union([
        box(x + radius, y, z, width - 2 * radius, depth, height),
        box(x, y + radius, z, width, depth - 2 * radius, height),
        *[cyl(xx, yy, z, radius, height)
          for xx in [x + radius, x + width - radius]
          for yy in [y + radius, y + depth - radius]],
    ])


def prism_x(points, x, length):
    vertices = [V(x, y, z) for y, z in points]
    return Part.Face(Part.makePolygon(vertices + vertices[:1])).extrude(V(length, 0, 0))


def link_yz(x, length, p, q, radius):
    dy, dz = q[0] - p[0], q[1] - p[1]
    scale = radius / math.hypot(dy, dz)
    ny, nz = -dz * scale, dy * scale
    return union([
        prism_x([(p[0] + ny, p[1] + nz), (q[0] + ny, q[1] + nz),
                 (q[0] - ny, q[1] - nz), (p[0] - ny, p[1] - nz)], x, length),
        cyl(x, *p, radius, length, V(1, 0, 0)),
        cyl(x, *q, radius, length, V(1, 0, 0)),
    ])


def axle_hole(x, y, z, length, roof=False):
    hole = cyl(x, y, z, 1.3, length, V(1, 0, 0))
    if roof:
        # The cup prints with -Z upward. A 45-degree roof replaces the
        # unsupported circular hole crown. The metal M2 axle stays round.
        r = 1.3
        hole = hole.fuse(prism_x([
            (y - r / math.sqrt(2), z - r / math.sqrt(2)),
            (y + r / math.sqrt(2), z - r / math.sqrt(2)),
            (y, z - r * math.sqrt(2)),
        ], x, length))
    return hole


def countersunk_hole(x, y, bottom, top):
    return cyl(x, y, bottom, 1.3, top - bottom + .1).fuse(
        Part.makeCone(1.3, 2.1, .8, V(x, y, top - .8)))


def add(name, shape, color='#c4cbd0', group='fixed', kind='print', up='+Z'):
    shape = shape.removeSplitter()
    if kind == 'print':
        assert shape.isValid() and len(shape.Solids) == 1, name
        print(name, round(shape.Volume, 2), 'mm3', flush=True)
    parts.append(dict(name=name, shape=shape, color=color, group=group, kind=kind, up=up))
    return shape


# Four small planar brackets use the existing H5-H8 holes.
# Integral feet eliminate loose printed standoffs. Print each outside face down.
cy, cz = pivots['camera'][1:]
ly, lz = pivots['lcd'][1:]
mounts = [
    ('camera left', -15.0, -13, -30.5, cy, cz, -35, -32.8, -27.4, '+X'),
    ('camera right', 12.2, 13, -30.5, cy, cz, -35, -32.8, -27.4, '-X'),
    ('LCD left', -24.2, -22, -28.5, ly, lz, -34.5, -31.6, -25.4, '+X'),
    ('LCD right', 20.4, 21, -28.5, ly, lz, -34.5, -31.6, -25.4, '-X'),
]
for label, x, mx, my, y, z, tail, front, back, up in mounts:
    camera = label.startswith('camera')
    foot_x = mx - (2.0 if mx < 0 else 3.2) if camera else mx - (2.2 if mx < 0 else 2.6)
    foot_width = 5.2 if camera else 4.8
    anchor = (tail + 1.0, 1.8)
    bracket = union([
        link_yz(x, 2.8, (y, z), anchor, 1.6 if camera else 1.8),
        cyl(x, y, z, 3.0 if camera else 4.0, 2.8, V(1, 0, 0)),
        box(x, tail, .8, 2.8, back - tail, 2.0),
        box(foot_x, front, .8, foot_width, back - front, 2.0),
    ])
    bracket = bracket.cut(axle_hole(x - .1, y, z, 3.0))
    bracket = bracket.cut(cyl(mx, my, .7, 1.3, 2.2))
    # A broad open tool clearance also clears the loose washer and nut.
    bracket = bracket.cut(cyl(mx, my, 2.8, 2.7, 5.8))
    if label == 'LCD right':
        bracket = bracket.cut(box(18.3, -27.8, .7, 1.1, 3.0, 2.3))
    bracket = bracket.common(box(-40, -60, .8, 80, 120, 100))
    add('01 ' + label + ' support', bracket, up=up)

# The LCD cup prints face down. The hinge ears grow from this same plane.
# Four short corner fences locate the glass with 0.4/0.5 mm nominal play.
lcd = rounded_plate(-27.5, -34.8, 21.2, 54, 80.4, 1.2, 1.6)
lcd = lcd.cut(box(-23.9, -27.6, 21.1, 46.8, 66.0, 1.4))
lcd = lcd.cut(box(-13.5, -38, 21.1, 26, 8.3, 1.4))
for x in [-20.9, 17.1]:
    lcd = lcd.fuse(box(x, ly - 4, lz, 2.8, 8, 22.4 - lz))
    lcd = lcd.fuse(cyl(x, ly, lz, 4, 2.8, V(1, 0, 0)))
    lcd = lcd.cut(axle_hole(x - .1, ly, lz, 3.0, roof=True))
for x in [-27.5, 24.9]:
    for y in [-29.7, 34.5]:
        lcd = lcd.fuse(box(x, y, 18.4, 1.6, 6, 2.8))
for x in [-26.1, 19.9]:
    for y in [-31.3, 40.5]:
        lcd = lcd.fuse(box(x, y, 18.4, 5.2, 1.6, 2.8))
for x in [-15, 14]:
    for y in [-32.2, 43.0]:
        lcd = lcd.fuse(cyl(x, y, 18.4, 2.6, 2.8))
        lcd = lcd.cut(countersunk_hole(x, y, 18.3, 22.4))
add('03 LCD front carrier', lcd, '#d5dade', 'lcd', up='-Z')

# Four identical flat tabs retain the LCD from behind. Their wide clearance
# holes and loose nuts require no fitted snap, sliding rail or nut pocket.
tab = rounded_plate(-2.6, -2.6, 16.8, 5.2, 8.6, 1.6, .8)
tab = tab.cut(cyl(0, 0, 16.7, 1.3, 1.8))
for x in [-15, 14]:
    for y, angle in [(-32.2, 0), (43.0, 180)]:
        shape = tab.copy()
        shape.rotate(V(), V(0, 0, 1), angle)
        shape.translate(V(x, y, 0))
        add('04 LCD ' + ('lower ' if y < 0 else 'upper ') + ('left' if x < 0 else 'right') + ' retaining tab', shape, group='lcd')

# Camera cup and rear plate use two M2 screws. No moving AF surface is clamped.
cam = union([
    rounded_plate(-10.5, -35.8, 10.1, 21, 11.1, 1.6, 1.6),
    rounded_plate(-11.7, cy - 3, 10.1, 23.4, 6, 1.6, 1.0),
])
cam = cam.cut(cyl(0, -30.25, 10.0, 4.5, 1.8))
cam = cam.cut(box(-8, cy - 3.1, 10, 16, 3.0, 1.8))
for x in [-11.7, 8.9]:
    cam = cam.fuse(box(x, cy - 3, cz, 2.8, 6, 10.1 - cz))
    cam = cam.fuse(cyl(x, cy, cz, 3, 2.8, V(1, 0, 0)))
    cam = cam.cut(axle_hole(x - .1, cy, cz, 3.0, roof=True))
for x in [-5.85, 4.65]:
    for y in [-34.9, -28.8]:
        cam = cam.fuse(box(x, y, 5.2, 1.2, 3.2, 4.9))
for x in [-7.5, 7.5]:
    cam = cam.fuse(cyl(x, -29.8, 5.2, 2.6, 4.9))
    cam = cam.cut(countersunk_hole(x, -29.8, 5.1, 11.7))
add('05 camera front carrier', cam, '#d5dade', 'camera', up='-Z')
rear = union([
    rounded_plate(-5.9, -34.4, 3.8, 11.8, 8.9, 1.4, .8),
    *[cyl(x, -29.8, 3.8, 2.8, 1.4) for x in [-7.5, 7.5]],
])
for x in [-7.5, 7.5]:
    rear = rear.cut(cyl(x, -29.8, 3.7, 1.3, 1.6))
add('06 camera rear plate', rear, group='camera')

# Standard loose hardware. No printed thread or close-fitting nut pocket.
def nut_x(x, y, z):
    radius = 4 / math.sqrt(3)
    return prism_x([(y + radius * math.cos(i * math.pi / 3),
                     z + radius * math.sin(i * math.pi / 3)) for i in range(6)], x, 1.6).cut(
        cyl(x - .1, y, z, .85, 1.8, V(1, 0, 0)))


def nut_z(x, y, z):
    n = nut_x(0, 0, 0)
    n.rotate(V(), V(0, 1, 0), -90)
    n.translate(V(x, y, z))
    return n


# Camera axle. The two independent LCD hinge screws leave its center open.
axle = cyl(-15.3, cy, cz, 1, 35, V(1, 0, 0)).fuse(cyl(-16.8, cy, cz, 1.9, 1.5, V(1, 0, 0)))
add('camera M2x35 axle', axle, '#929da5', kind='fastener')
add('camera M2 axle nut', nut_x(15.3, cy, cz), '#929da5', kind='fastener')
for x in [-15.3, 15.0]:
    add('camera outer M2 washer', cyl(x, cy, cz, 2.5, .3, V(1, 0, 0)).cut(cyl(x - .1, cy, cz, 1.1, .7, V(1, 0, 0))), '#929da5', kind='fastener')
for x in [-12.2, 11.7]:
    add('camera nylon friction washer', cyl(x, cy, cz, 2.5, .5, V(1, 0, 0)).cut(cyl(x - .1, cy, cz, 1.1, .7, V(1, 0, 0))), '#536977', kind='fastener')
for x, direction in [(-24.5, 1), (23.5, -1)]:
    axle = cyl(x, ly, lz, 1, 8, V(direction, 0, 0)).fuse(cyl(x - 1.5 * direction, ly, lz, 1.9, 1.5, V(direction, 0, 0)))
    add('LCD M2x8 hinge screw', axle, '#929da5', kind='fastener')
for x in [-24.5, 23.2]:
    add('LCD outer M2 washer', cyl(x, ly, lz, 2.5, .3, V(1, 0, 0)).cut(cyl(x - .1, ly, lz, 1.1, .7, V(1, 0, 0))), '#929da5', kind='fastener')
for x in [-21.4, 19.9]:
    add('LCD nylon friction washer', cyl(x, ly, lz, 2.5, .5, V(1, 0, 0)).cut(cyl(x - .1, ly, lz, 1.1, .7, V(1, 0, 0))), '#536977', kind='fastener')
for x in [-18.1, 15.5]:
    add('LCD hinge M2 nut', nut_x(x, ly, lz), '#929da5', 'lcd', 'fastener')
for x, y in [(-13, -30.5), (13, -30.5), (-22, -28.5), (21, -28.5)]:
    add('PCB M2x6 screw', cyl(x, y, -.8, 1, 6).fuse(cyl(x, y, -2.3, 1.9, 1.5)), '#929da5', kind='fastener')
    add('PCB M2 nut', nut_z(x, y, 3.1), '#929da5', kind='fastener')
    add('PCB M2 washer', cyl(x, y, 2.8, 2.5, .3).cut(cyl(x, y, 2.7, 1.1, .7)), '#929da5', kind='fastener')
for group, coords, top, length, nut_bottom in [
    ('lcd', [(x, y) for x in [-15, 14] for y in [-32.2, 43.0]], 22.4, 8, 15.2),
    ('camera', [(x, -29.8) for x in [-7.5, 7.5]], 11.7, 10, 2.2),
]:
    for x, y in coords:
        screw = cyl(x, y, top - length, 1, length - .8).fuse(Part.makeCone(1.3, 2.1, .8, V(x, y, top - .8)))
        add(group + ' countersunk M2 screw', screw, '#929da5', group, 'fastener')
        add(group + ' retaining M2 nut', nut_z(x, y, nut_bottom), '#929da5', group, 'fastener')

# The reference file is stored at the original upright pose. Undo that pose
# around its original axes before applying this design's hinge axes.
reference = A.openDocument(str(S / 'reference.FCStd'))
for obj in reference.Objects:
    shape = obj.Shape.copy()
    group = obj.MotionGroup
    if group != 'fixed':
        shape.rotate(V(*config['reference_pivots_cad_mm'][group]), V(1, 0, 0), -90)
        shape.translate(V(*config['module_offsets_cad_mm'][group]))
    add(obj.Label, shape, obj.ColorHex, group, obj.PartKind)
add('camera FH34 placement envelope', box(-7, -27.153656, .8, 14, 3.8, 1), '#303d46', kind='connector')
add('LCD FH12 placement envelope', box(-10.2, -21.903656, .8, 19.4, 3.6, 4.85), '#303d46', kind='connector')
u = config['usb']
add('Centered underside USB shell', box(*u['shell_min_cad_mm'], *u['shell_size_mm']), '#465460', kind='connector')
add('Assumed USB plug', box(*u['assumed_plug_min_cad_mm'], *u['assumed_plug_size_mm']), '#6093ac', kind='envelope')
add('camera trapped back pad', box(-4.2, -34.3, 5.2, 8.4, 8.1, .45), '#637582', 'camera', 'pad')
for x in [-17, 12]:
    for y in [-29.2, 38]:
        add('LCD trapped back pad', box(x, y, 18.4, 4, 2, .53), '#637582', 'lcd', 'pad')


def posed(shape, group, angle):
    shape = shape.copy()
    if group != 'fixed':
        shape.rotate(V(*pivots[group]), V(1, 0, 0), angle)
    return shape


# Remove obsolete exports owned by this generator when the part set changes.
dest = R / 'parts'
dest.mkdir(exist_ok=True)
expected = {p['name'].replace(' ', '_') for p in parts if p['kind'] == 'print'}
for output in dest.iterdir():
    if output.suffix in ['.step', '.stl'] and output.stem not in expected:
        output.unlink()
orientations = []
doc = A.newDocument('FMC_DVP_LCD_FDM')
for p in parts:
    obj = doc.addObject('PartDesign::Feature', 'Part')
    obj.Label = p['name']
    obj.Shape = posed(p['shape'], p['group'], config['assembly_pose_deg'])
    for prop, value in [('MotionGroup', p['group']), ('PartKind', p['kind']), ('ColorHex', p['color'])]:
        obj.addProperty('App::PropertyString', prop)
        setattr(obj, prop, value)
    if p['kind'] != 'print':
        continue
    dest = R / 'parts'
    dest.mkdir(exist_ok=True)
    stem = p['name'].replace(' ', '_')
    p['shape'].exportStep(str(dest / (stem + '.step')))
    shape = p['shape'].copy()
    direction = {'+X': V(1, 0, 0), '-X': V(-1, 0, 0), '+Z': V(0, 0, 1), '-Z': V(0, 0, -1)}[p['up']]
    shape.Placement = A.Placement(V(), A.Rotation(direction, V(0, 0, 1))).multiply(shape.Placement)
    b = shape.BoundBox
    shape.translate(V(-b.XMin, -b.YMin, -b.ZMin))
    mesh = MeshPart.meshFromShape(Shape=shape, LinearDeflection=.025, AngularDeflection=.1, Relative=False)
    mesh.write(str(dest / (stem + '.stl')))
    assert Mesh.Mesh(str(dest / (stem + '.stl'))).isSolid(), stem + ' STL is not closed'
    orientations.append(dict(name=p['name'], original_up=p['up'], stl_on_bed=True,
                             volume_mm3=p['shape'].Volume, quantity=1))
doc.recompute()
doc.saveAs(str(R / 'camera_lcd.FCStd'))
Part.export(list(doc.Objects), str(R / 'camera_lcd.step'))
data = {'parts': [], 'pivots': pivots, 'rotation_sign': {'camera': 1, 'lcd': 1}}
for p in parts:
    vertices, faces = p['shape'].tessellate(.08)
    data['parts'].append({k: p[k] for k in ['name', 'color', 'group', 'kind']} |
                        {'vertices': [list(v) for v in vertices], 'faces': [list(f) for f in faces]})
(R / 'model.json').write_text(json.dumps(data, separators=(',', ':')))
(R / 'print-orientations.json').write_text(json.dumps(orientations, indent=2) + '\n')
(R / 'design-parameters.json').write_text(json.dumps({
    'printed_parts': len(orientations), 'retention': 'M2 screws and loose nuts, no snap fits or printed threads',
    'screws': {'M2x6_PCB': 4, 'M2x35_camera_axle': 1, 'M2x8_LCD_hinges': 2, 'M2x8_countersunk_LCD': 4, 'M2x10_countersunk_camera': 2},
    'PCB_screw_holes_native': ['H5', 'H6', 'H7', 'H8'], 'original_four_mounts_unchanged': True,
    'bores_mm': 2.6, 'steel_washer_thickness_mm': .3, 'friction_washer_OD_ID_thickness_mm': [5, 2.2, .5],
    'LCD_side_clearance_mm': .4, 'LCD_end_clearance_mm': .5, 'camera_side_clearance_mm': .4,
    'countersunk_head_max_diameter_mm': 4.2, 'countersunk_head_height_mm': .8,
    'back_pad_installed_thickness_mm': {'camera': .45, 'lcd': .53},
    'back_pad_nominal_free_thickness_mm': .8,
    'pad_free_thickness_and_compression_require_selection': True,
    'physical_print_and_clamp_forces_validated': False, 'FPC_travel_verified': False,
}, indent=2) + '\n')
(R / 'source-manifest.json').write_text(json.dumps({
    'inputs': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in
               [S / 'assembly.py', S / 'parameters.json', S / 'reference.FCStd', P / 'fmc_dvp_lcd.kicad_pcb']},
    'output_directory': str(R), 'USB': u, 'physical_fit_tested': False, 'FPC_travel_verified': False,
}, indent=2) + '\n')
print('BUILD COMPLETE', R, flush=True)
sys.exit(0)
