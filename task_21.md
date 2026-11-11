
# bug fix aiming system
I noticed that the tower let's go of a target when a new target enters the view while an existing (wounded target) is still available. Let's hold on to a locked target until it is no longer in range or defeated and then use the logic rules to find a new target. 
Check if I'm correct first, then fix it.


# level progression

  Let's start setting up the progression

  duplicate level 1 and make it the test level on top of the level selection.

  We'll hide it later. The towers in teh test level are all unlocked and cost 1 credit, same for upgrades. 


# part 1
  Next we are going to track which towers are available for the player. When starting out it will just be the laser tower. Towers will become available after certain achievements. Like finishing level 1 will make another tower available. It will then also be available for replays in level 1.

# part 2
  We'll also introduce a 3-star system. 
  Currently the setup will be when the level has been completed you'll get 1 star. When you have finished the level without any loss of health you'll get two stars.
  I still need to think of 3-star achievements.

# part 3
level one should be: 
3 waves of robots and a final round of race cars, which on first try the race cars will come through. But winning the level will grant you a new tower that is better against faster units than the laser tower.

