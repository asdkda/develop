#!/usr/bin/python
number = 23
#guess = int(raw_input('Enter an integer : '))
#if guess == number:
#	print 'Congratulations, you guessed it.' # New block starts here
#elif guess < number:
#	print 'No, it is higher than that.' # Another block
	# You can do whatever you want in a block ...
#else:
#	print 'No, it is lower than that.'
	# you must have guess > number to reach this block
#	print 'Done'
	# This last statement is separate from the if statement,
	# and since it is present in the main block, it is always executed.
	
	
def test_ok(prompt, retries=4, message='Try again!\n'):
	while 1:
		guess = int(raw_input(prompt))
		if guess == number:
			print 'Congratulations, you guessed it.' # New block starts here
			return 1
		elif guess < number:
			print 'No, it is higher than that.' # Another block
		elif guess > number:
			print 'No, it is lower than that.' # Another block

		retries = retries - 1
		if retries < 0: raise IOError, 'refusenik user'
		print message

test_ok("Enter an integer : ")
