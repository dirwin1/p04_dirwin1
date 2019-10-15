Welcome to Tetris Attack for iOS v0.9.1.21!!

This is a clone of the SNES game Tetris Attack for iOS written using swift
and SpriteKit.

While not all features have been implemented, my version includes:
    -Random starting configuration that guarantees no matches
    -Swipe left/right on the block you want to swap to swap blocks
    -matches of 3 or more will disappear with a cool animation
        -matches may be of two different block types as well, if they are made
        on the same swipe, then they count towards the same combo
        -support for different shapes of matches as well
    -blocks will fall down if there is nothing underneath them
    -falling blocks create opportunities to create chains, where falling blocks
    can create new matches
