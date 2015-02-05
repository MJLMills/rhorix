import bpy

class QCTBlender(bpy.types.Operator):
 bl_idname = "qct.import_topology"
 bl_label = "Import Topology"
 
 filepath = bpy.props.StringProperty(subtype="FILE_PATH")
 
 def execute(self, context):
  print("Script Executed")
  return{'FINISHED'}
  
 def invoke(self, context, event):
  print("Script Invoked")
  context.window_manager.fileselect_add(self)
  return {'RUNNING_MODAL'}
  
bpy.utils.register_class(QCTBlender)
