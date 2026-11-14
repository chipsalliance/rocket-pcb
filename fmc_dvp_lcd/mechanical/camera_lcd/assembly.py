"""Generate the six-part camera/LCD prototype and its printable exports.

Run with FreeCADCmd. Outputs stay under the board build/mechanical directory.
Reference geometry is nominal and does not establish FPC or carrier fit.
"""
from pathlib import Path
import json,math,sys,os,hashlib
import FreeCAD as A,Part,MeshPart
S=Path(__file__).resolve().parent
P=S.parents[1]
R=Path(os.environ.get('FMC_MECHANICAL_OUTPUT',str(P/'build/mechanical/camera_lcd'))).resolve()
R.mkdir(parents=True,exist_ok=True)
config=json.loads((S/'parameters.json').read_text())
V=A.Vector
parts=[];pivots={'camera':config['camera_pivot_cad_mm'],'lcd':config['lcd_pivot_cad_mm']}
def box(x,y,z,w,d,h):return Part.makeBox(w,d,h,V(x,y,z))
def cyl(x,y,z,r,h,axis=V(0,0,1)):return Part.makeCylinder(r,h,V(x,y,z),axis)
def union(ss):
 s=ss[0]
 for q in ss[1:]:s=s.fuse(q)
 return s.removeSplitter()
def prism_x(points,x,length):
 ps=[V(x,y,z) for y,z in points];return Part.Face(Part.makePolygon(ps+[ps[0]])).extrude(V(length,0,0))
def prism_y(points,y,length):
 ps=[V(x,y,z) for x,z in points];return Part.Face(Part.makePolygon(ps+[ps[0]])).extrude(V(0,length,0))
def hex_x(x,y,z,r,length):
 ps=[V(x,y+r*math.cos(i*math.pi/3),z+r*math.sin(i*math.pi/3)) for i in range(6)]
 return Part.Face(Part.makePolygon(ps+[ps[0]])).extrude(V(length,0,0))
def add(name,shape,color,group='fixed',kind='print'):
 shape=shape.removeSplitter();parts.append({'name':name,'shape':shape,'color':color,'group':group,'kind':kind})
 if kind=='print':
  print(name,shape.isValid(),len(shape.Solids),shape.Volume,flush=True)
  assert shape.isValid() and len(shape.Solids)==1,name
 return shape

# One base uses two dedicated M2 support holes as screws. Two other M2 holes
# receive printed locating pegs. Original four M2.5 holes remain accessible.
bases=[box(-15.6,-33.1,.85,5.1,9.3,3.65),box(10.5,-33.1,.85,5.1,9.3,3.65),
 box(-24.5,-24.3,3.3,43.9,1.6,1.8),box(-24.5,-31,.85,5,7.2,3.65),
 box(19.2,-31,.85,5,7.2,3.65),
 box(-22.5,-26.5,.85,12,2.7,3.65),box(10.5,-26.5,.85,9.0,2.7,3.65),
 box(-11.6,-38.9,.85,4.4,15.1,6.25),box(7.2,-38.9,.85,3.0,15.1,6.25),
 box(-15.6,-32.5,.85,8.4,3.0,2.5),box(7.2,-32.5,.85,8.4,3.0,2.5)]
# Rear-set foot and a high bridge leave a front USB opening on either PCB face.
bases += [box(-24,-30.5,3.3,3,4.3,6.9),box(-24,-33.8,8.2,3,7.6,2),
 box(-28.5,-33.8,8.2,7.5,2.6,2),box(-28.5,-35.8,9.8,2.7,4.6,7.0)]
base=union(bases)
# Integral friction faces remove the need for separate washers.
base=base.fuse(cyl(-25.8,-33.5,14,2.1,.25,V(1,0,0)))
base=base.fuse(cyl(-7.2,-35.5,4,2.1,.15,V(1,0,0))).fuse(cyl(7.05,-35.5,4,2.1,.15,V(1,0,0)))
# Recess the underside over the actual front ESD and CC resistor courtyards.
base=base.cut(box(15.3,-30.3,.7,2.9,3.6,1.6)).cut(box(16.7,-27.5,.7,2.4,5.0,1.6))
for x in [-13,13]:
 base=base.cut(cyl(x,-30.5,.7,1.1,7)).cut(cyl(x,-30.5,2.6,2.1,5))
for x in [-22,21]:base=base.fuse(cyl(x,-28.5,-.65,.9,1.7))
base=base.cut(cyl(-12,-35.5,4,1.1,24,V(1,0,0)))
base=base.cut(cyl(-11.7,-35.5,4,2.1,1.7,V(1,0,0)))
base=base.cut(hex_x(8.4,-35.5,4,2.55,2.0))
base=base.cut(cyl(-29,-33.5,14,1.1,9,V(1,0,0)))
base=base.cut(cyl(-28.6,-33.5,14,2.1,1.7,V(1,0,0)))
tc=21.7
female=[(tc-1.5,1.45),(tc+1.5,1.45),(tc+1.0,3.45),(tc+1.0,4.7),(tc-1.0,4.7),(tc-1.0,3.45)]
base=base.cut(prism_y(female,-30.95,7.3))
# Relieve the lower inlet edges for the assumed plug and print tolerances.
u=config['usb']
base=base.cut(box(*u['relief_min_cad_mm'],*u['relief_size_mm']))
add('01 shared base',base,'#c3c8cb')

# Dovetail bearing tower slides in from the rear. The captured LCD stub and
# left M2 hinge screw prevent it from withdrawing after assembly.
male=[(tc-1.3,1.65),(tc+1.3,1.65),(tc+.8,3.25),(tc+.7,4.7),(tc-.7,4.7),(tc-.8,3.25)]
tower=union([prism_y(male,-30.75,6.7),box(tc-.7,-30.5,4.6,1.4,4.3,.4),
 box(tc-1.3,-30.5,4.7,2.6,4.3,5.5),box(tc-1.3,-33.8,8.2,2.6,7.6,2),
 box(tc-1.3,-33.8,8.2,27.6-(tc-1.3),2.6,2),box(24.8,-35.8,9.8,2.8,4.6,7.0)])
tower=tower.cut(cyl(24.7,-33.5,14,1.6,3.1,V(1,0,0)))
add('02 LCD dovetail bearing',tower,'#c3c8cb')

# LCD U-channel holds the bare module at the unchanged F-revision position.
lcd_bits=[box(-27,-30.4,17.1,3.2,70.6,1.2),box(22.8,-30.4,17.1,3.2,70.6,1.2),
 box(-27,-30.4,18.3,1.3,70.6,4.2),box(24.7,-30.4,18.3,1.3,70.6,4.2),
 box(-25.7,-30.4,21.3,1.2,70.6,1.2),box(23.5,-30.4,21.3,1.2,70.6,1.2),
 box(-27,-30.4,17.1,53,1.0,5.4),box(-27,-29.4,21.3,53,1.2,1.2),
 box(-27,40.2,17.1,4.2,2.0,3.7),box(21.8,40.2,17.1,4.2,2.0,3.7)]
for x,width,r in [(-25.5,4.9,3.35),(21.5,3.0,2.4)]:
 lcd_bits += [cyl(x,-33.5,14,r,width,V(1,0,0)),box(x,-33.5,14,width,5.3,4.3)]
lcd=union(lcd_bits).cut(box(-9.5,-30.6,17.0,18,3,4.3))
for x in [-27,22.8]:lcd=lcd.cut(box(x,38.8,20.8,3.2,1.5,2.0))
lcd=lcd.cut(cyl(-25.6,-33.5,14,1.1,5.2,V(1,0,0))).cut(hex_x(-22.4,-33.5,14,2.55,1.9))
lcd=lcd.fuse(cyl(24.45,-33.5,14,1.4,2.25,V(1,0,0)))
for cx in [-24.9,23.9]:
 female=[(cx-.9,17.85),(cx+.9,17.85),(cx+1.3,19.85),(cx-1.3,19.85)]
 lcd=lcd.cut(prism_y(female,40.2,2.15))
# Detent notch accepts a relaxed side latch, rather than holding it bent.
lcd=lcd.cut(box(25.65,30.8,20.75,.5,1.5,1.6))
add('03 LCD slim U frame',lcd,'#d8dbda','lcd')

cap_bits=[box(-27,42.2,18.3,53,1.2,4.2),box(-22.6,40.2,18.3,44.2,2.1,4.2),
 box(-27,39.0,21.3,53,4.4,1.2),box(26,42.0,20.9,1.0,1.4,1.3),
 box(26.15,31.0,20.9,.8,11.3,1.2)]
for cx in [-24.9,23.9]:
 male=[(cx-.7,18.05),(cx+.7,18.05),(cx+1.1,19.65),(cx-1.1,19.65)]
 cap_bits.append(prism_y(male,40.4,1.95))
# Hook ramp, extruded vertically. It flexes outward while the cap slides in.
ps=[V(26.15,31,20.9),V(25.8,31.6,20.9),V(25.8,32,20.9),V(26.15,32,20.9)]
lcd_nub=Part.Face(Part.makePolygon(ps+[ps[0]])).extrude(V(0,0,1.2))
cap=union(cap_bits+[lcd_nub]);add('04 LCD sliding lock bar',cap,'#c3c8cb','lcd')

# Camera front bezel is integral. The camera enters from the open back.
cam=box(-6,-35.7,3.8,12,10.9,7.55).cut(box(-4.45,-34.7,3.7,8.9,8.9,6.45))
cam=cam.cut(cyl(0,-30.25,10.14,4.4,1.4))
for x in [-7,5.5]:cam=cam.fuse(cyl(x,-35.5,4,2.25,1.5,V(1,0,0)))
cam=cam.cut(cyl(-7.1,-35.5,4,1.1,14.2,V(1,0,0)))
cam=cam.cut(box(-5.25,-36.9,3.7,10.5,2.7,1.6))
for x in [-5.2,4.4]:cam=cam.cut(box(x,-34.2,4.0,.8,9.6,1.2))
cam=cam.cut(box(-6.1,-26,3.9,12.2,1.4,1.5))
cam=cam.cut(box(-6.1,-32.2,4.0,.5,1.6,1.3))
add('05 camera integral face frame',cam,'#d8dbda','camera')
rear_bits=[box(-4.35,-34.1,4.2,8.7,8.7,1),box(-5,-34.1,4.2,.7,8.7,.8),
 box(4.3,-34.1,4.2,.7,8.7,.8),box(-5.9,-25.4,3.9,11.8,.6,1.3),
 box(-6.8,-32,4.2,.7,7.2,.8),box(-6.8,-25.4,4.2,1.0,.6,.8)]
ps=[V(-6.1,-32,4.2),V(-5.8,-31.6,4.2),V(-5.8,-31.1,4.2),V(-6.1,-31.1,4.2)]
cam_nub=Part.Face(Part.makePolygon(ps+[ps[0]])).extrude(V(0,0,.8))
rear=union(rear_bits+[cam_nub]);add('06 camera slide back',rear,'#c3c8cb','camera')

# Four M2 screws remain. No exterior bezel or camera-retaining screws.
for x in [-13,13]:
 s=cyl(x,-30.5,-3.4,1,6).fuse(cyl(x,-30.5,2.6,1.9,1.5));add('PCB M2x6 screw',s,'#aeb6bc',kind='fastener')
 add('PCB M2 nut',cyl(x,-30.5,-2.4,2.05,1.6).cut(cyl(x,-30.5,-2.5,.85,1.8)),'#aeb6bc',kind='fastener')
add('camera M2x20 hinge screw',cyl(-10,-35.5,4,1,20,V(1,0,0)).fuse(cyl(-11.5,-35.5,4,1.9,1.5,V(1,0,0))),'#aeb6bc',kind='fastener')
add('camera captive nut',hex_x(8.5,-35.5,4,4/math.sqrt(3),1.6).cut(cyl(8.4,-35.5,4,.85,1.8,V(1,0,0))),'#aeb6bc',kind='fastener')
add('LCD M2x8 hinge screw',cyl(-26.9,-33.5,14,1,8,V(1,0,0)).fuse(cyl(-28.4,-33.5,14,1.9,1.5,V(1,0,0))),'#aeb6bc',kind='fastener')
add('LCD captive nut',hex_x(-22.3,-33.5,14,4/math.sqrt(3),1.6).cut(cyl(-22.4,-33.5,14,.85,1.8,V(1,0,0))),'#aeb6bc','lcd','fastener')

# Reuse the exact module and board shapes from the previous editable model.
reference=A.openDocument(str(S/'reference.FCStd'))
for obj in reference.Objects:
 s=obj.Shape.copy();group=obj.MotionGroup
 if group!='fixed':s.rotate(V(*pivots[group]),V(1,0,0),-90)
 add(obj.Label,s,obj.ColorHex,group,obj.PartKind)
add('camera FH34 placement envelope',box(-7,-27.153656,.8,14,3.8,1),'#303d46',kind='connector')
add('LCD FH12 placement envelope',box(-10.2,-21.903656,.8,19.4,3.6,4.85),'#303d46',kind='connector')
add('Centered underside USB shell',box(*u['shell_min_cad_mm'],*u['shell_size_mm']),'#465460',kind='connector')
add('Assumed USB plug',box(*u['assumed_plug_min_cad_mm'],*u['assumed_plug_size_mm']),'#6093ac',kind='envelope')
for x in [-24.8,22.8]:add('LCD trapped back strip',box(x,-25,18.3,1,60,.3),'#7a8791','lcd','pad')
add('camera trapped back pad',box(-4.2,-34.1,5.2,8.4,8.1,.2),'#7a8791','camera','pad')

def tf(s,g,a):
 s=s.copy()
 if g!='fixed':s.rotate(V(*pivots[g]),V(1,0,0),a)
 return s
doc=A.newDocument('FMC_DVP_LCD_Simple')
for i,p in enumerate(parts):
 o=doc.addObject('PartDesign::Feature','Part');o.Label=p['name'];o.Shape=tf(p['shape'],p['group'],config['assembly_pose_deg'])
 o.addProperty('App::PropertyString','MotionGroup');o.MotionGroup=p['group']
 o.addProperty('App::PropertyString','PartKind');o.PartKind=p['kind']
 if p['kind']=='print':
  dest=R/'parts';dest.mkdir(exist_ok=True)
  p['shape'].exportStep(str(dest/(p['name'].replace(' ','_')+'.step')))
  mesh=MeshPart.meshFromShape(Shape=p['shape'],LinearDeflection=.05,AngularDeflection=.15,Relative=False)
  mesh.write(str(dest/(p['name'].replace(' ','_')+'.stl')))
doc.recompute();doc.saveAs(str(R/'camera_lcd.FCStd'))
Part.export([o for o in doc.Objects],str(R/'camera_lcd.step'))
data={'parts':[],'pivots':pivots,'rotation_sign':{'camera':1,'lcd':1}}
for p in parts:
 vs,fs=p['shape'].tessellate(.12)
 data['parts'].append({k:p[k] for k in ['name','color','group','kind']}|{'vertices':[[v.x,v.y,v.z] for v in vs],'faces':[list(f) for f in fs]})
(R/'model.json').write_text(json.dumps(data,separators=(',',':')))
(R/'design-parameters.json').write_text(json.dumps({'printed_parts':6,'screws':{'M2x6_PCB':2,'M2x20_camera_hinge':1,'M2x8_LCD_hinge':1},'PCB_screw_holes_native':['H5','H6'],'PCB_locating_peg_holes_native':['H7','H8'],'original_four_mounts_unchanged':True,'module_positions_and_hinge_axes_unchanged':True,'screen_body_nominal_mm':[50,69.2,2.25],'camera_body_nominal_mm':[8.5,8.5,4.95],'dovetail_clearance_per_side_mm':.2,'nominal_LCD_glass_clearance_mm':.43,'nominal_camera_fixed_shell_clearance_mm':.3,'friction_faces':'Integral annular faces, with 0.05 mm nominal axial take-up before clamping.','LCD_latch_mm':{'beam_length':10.6,'beam_thickness':.8,'required_deflection':.2},'camera_latch_mm':{'beam_length':6.7,'beam_thickness':.7,'required_deflection':.2},'head_max_diameter_mm':3.8,'head_max_height_mm':1.5,'captive_nut_nominal_across_flats_mm':4.0,'captive_nut_pocket_across_flats_mm':2*2.55*math.cos(math.pi/6),'physical_print_and_clamp_forces_validated':False},indent=2)+'\n')
(R/'source-manifest.json').write_text(json.dumps({'inputs':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [S/'assembly.py',S/'parameters.json',S/'reference.FCStd',P/'fmc_dvp_lcd.kicad_pcb']},'output_directory':str(R),'USB':u,'physical_fit_tested':False,'FPC_travel_verified':False},indent=2)+'\n')
print('BUILD COMPLETE',R,flush=True)
sys.exit(0)
