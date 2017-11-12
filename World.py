# World Python 3 Module
# Rhorix: An interface between quantum chemical topology and the 3D graphics program Blender

import bpy
import mathutils
import math

# This function sets up default render options, lights, camera to match the Morphy GUI
def setup(center,radius):

    # quick fix for zero radius (single CP) case
    #if radius == 0.0:
    #    radius = 1.0

    cam_ob = createCamera(center,radius)
    createLights(cam_ob.location,center,radius)
    defaultRenderSettings()

def createCamera(center,radius):

    cam = bpy.data.cameras.new("Cam")
    cam.clip_end = 1000.0
    cam_ob = bpy.data.objects.new("Cam", cam)
    cam_ob.location=(center[0],center[1],(4.0 * radius))
    bpy.context.scene.objects.link(cam_ob)
    return cam_ob

def createLights(cam_location,center,radius):

    rad45 = 45.0*(3.141519265359/180.0)
    rad90 = 90.0*(3.141519265359/180.0)
    sin45 = math.sin(rad45)

    def createKeyLight():

        # Must create spotlight for key light at camera position, pointing in camera direction
        bpy.ops.object.lamp_add(type='SPOT',location=cam_location)
        # move to the left (-ve x-direction), +ve along z and +ve along y
        x = -cam_location[2]*sin45
        y = radius
        z = cam_location[2]*sin45
        bpy.context.active_object.location = (x, y, z)


        angle = rad90 - math.atan(abs(x)/abs(y)) 
        bpy.context.active_object.rotation_euler = mathutils.Euler((0.0,-rad45,-angle),'XYZ')

        bpy.context.active_object.data.distance = cam_location[2]
        bpy.context.active_object.data.energy = 15
        bpy.context.active_object.data.spot_size = 1.0 # rads!

    # and repeat this for the fill light, move in +ve x-direction. +ve along z and +ve y-direction
    # and light should be weaker
    def createFillLight():

        bpy.ops.object.lamp_add(type='SPOT',location=cam_location)
        x = cam_location[2]*sin45
        y = radius
        z = x
        bpy.context.active_object.location = (x, y, z)

        angle = rad90 - math.atan(abs(x)/abs(y)) 
        bpy.context.active_object.rotation_euler = mathutils.Euler((0.0,rad45,angle),'XYZ')

        bpy.context.active_object.data.distance = cam_location[2]
        bpy.context.active_object.data.energy = 5
        bpy.context.active_object.data.spot_size = 1.0 # rads!

    def createRimLight():
        # and now the rim light
        bpy.ops.object.lamp_add(type='SPOT',location=cam_location)
        bpy.context.active_object.location.z = -4.0*radius
        bpy.context.active_object.rotation_euler = mathutils.Euler((3.141519265359,0.0,0.0),'XYZ')

        bpy.context.active_object.data.distance = cam_location[2]
        bpy.context.active_object.data.energy = 5
        bpy.context.active_object.data.spot_size = 1.0 # rads!

    createKeyLight()
    createFillLight()
    createRimLight()

def defaultRenderSettings():

    bpy.context.scene.render.resolution_x = 1000
    bpy.context.scene.render.resolution_y = 1000    
    bpy.context.scene.render.resolution_percentage = 50

    bpy.context.scene.render.use_antialiasing = True
    bpy.context.scene.render.antialiasing_samples = '8'
    bpy.context.scene.render.use_full_sample = True
    bpy.context.scene.render.pixel_filter_type = 'MITCHELL' #GAUSSIAN|CATMULLROM|CUBIC|QUADRATIC|TENT|BOX
    bpy.context.scene.render.image_settings.file_format = 'PNG'
    bpy.context.scene.render.image_settings.color_depth = '16'
    bpy.context.scene.render.image_settings.compression = 0

    #Provide light coming from all directions using the ambient param of materials
    #Also set the light energy and colour source. Turned off in favour of 3-point lights!
    #bpy.context.scene.world.light_settings.use_environment_light = True
    #bpy.context.scene.world.light_settings.environment_energy = 0.65
    #bpy.context.scene.world.light_settings.environment_color = 'PLAIN' #|SKY_COLOR | SKY_TEXTURE

    #set the background to be plain and flat RGB
    bpy.context.scene.world.horizon_color = (0.05, 0.20, 0.35)

    #set the AO colour to outdoor midday
    #bpy.context.scene.world.ambient_color = (0.90, 0.90, 0.80)
    #bpy.context.scene.world.light_settings.use_ambient_occlusion = True
    #bpy.context.scene.world.light_settings.ao_factor = 1.00
    #bpy.context.scene.world.light_settings.ao_blend_type = 'MULTIPLY' #ADD

    #Set up the quality of the ambient, indirect and AO
    #Turn ray-tracing on for AO and env lighting
    bpy.context.scene.render.use_raytrace = True
    bpy.context.scene.world.light_settings.gather_method = 'RAYTRACE'
    bpy.context.scene.world.light_settings.samples = 6


