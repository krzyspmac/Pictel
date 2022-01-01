-- Create an animator from 0 to 255 over a 2 second period.
fadeInAnimation = AnimationFactory:CreateLinear(0, 255, 0.5,
	function(val)
		-- process the current value
		print("Current value =" .. val)
	end,
	function()
		-- if not using the animator again, release it
		-- and don't reference it ever again
		fadeInAnimation:ReleaseMem()
		fadeInAnimation = nil
	end
)

-- Start the animation
fadeInAnimation.Start()
