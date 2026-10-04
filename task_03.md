Add one moving enemy to `tower_placement.tscn`. Have a simple sphere follow the visible `PlacementPath` using `PathFollow3D`, with an adjustable movement speed. Make placed towers detect, turn toward, and damage that enemy using the existing tower rules. Show its health and provide a reset button so the interaction can be tested repeatedly. Keep waves and economy out of this test scene, and add focused tests for path movement and tower attacks.

Have a button to spawn a new enemy instance. 
Have the movement speeds be adjustable.
Create a second sphere (one is red the other is blue and slightly larger).
Have the size scalable (not diameter, it's for visuals later).
The enemy can be selected from a dropdown similar as the towers are selected in the tower demmo scene.  
