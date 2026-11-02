## Holds the Side enum shared by processing scripts. Kept in its own script so it doesn't depend on any other class.
class_name ShipSide extends RefCounted

## A side of the ship. The values double as a direction on the x axis (left is negative).
enum Side { LEFT = -1, RIGHT = 1 }
