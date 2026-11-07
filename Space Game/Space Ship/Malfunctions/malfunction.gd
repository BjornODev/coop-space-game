## The four kinds of ship malfunction. Each one has its own failure meter in MalfunctionManager.
class_name Malfunction extends RefCounted

enum Type { FIRE, OXYGEN, COMMS, HULL }

## Every type, in the order meters are shown on the HUD.
const ALL_TYPES: Array[Type] = [Type.FIRE, Type.OXYGEN, Type.COMMS, Type.HULL]
