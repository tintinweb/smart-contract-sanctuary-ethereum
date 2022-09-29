# @version >=0.3.7
"""
@title Where in the World is Kwon Zhu Davieago?
@dev Introducing my new gps web3 game. It's simple.
@dev Send 0.1 ETH, a lat-long coordinate, and the addr of the front-end you used.
@dev Congrats you are now the mayor of lat-long.
@dev If Kwon, Zhu, or Davies reemerges publicly and you're closest to them, congrats! You win a 1/6th of the pot for each.
@dev 40% goes to charities. 5% to the front end provider with the most entries. 5% to me for more smart contract bullshit.
@dev This is an insane, untested contract.
@author Josh Cincinnati (github: @acityinohio, website: https://bitbanter.com/)
"""

############### variables ###############
# the contract owner
owner: public(address)

# whether the game has ended (defaults to false)
ended: public(bool)

# struct of guesser/front end
struct GF:
	guesser: address
	front: address

# map of guesses, lat, long,
guesses: HashMap[int128, HashMap[int128, GF]]

# do winner
kwon: address

# su winner
zhu: address

# kyle winner
davies: address

# frontend winner
front: address

############### events ###############
# when someone says governance and we nuke everything, as a treat
event SomeoneSaidGovernance: pass

# new guess
event NewGuess:
	lat: int128
	long: int128
	guesser: address
	front: address

# various winners
event FoundDo:
	lat: int128
	long: int128
	kwonFinder: address

event FoundSu:
	lat: int128
	long: int128
	zhuFinder: address

event FoundKyle:
	lat: int128
	long: int128
	daviesFinder: address

############### init and internal functions ###############

@external
def __init__():
	"""
	@dev contract initialization on deployment
	@dev set sender as owner
	"""
	self.owner = msg.sender


############### other functions ###############

@external
@payable
def makeGuess(lat: int128, long: int128, frontend: address):
	"""
	@dev become mayor of a lat-long!
	"""
	assert msg.value == as_wei_value(0.1, "ether"), "You can only send 0.1 ETH"
	assert self.guesses[lat][long].guesser == empty(address), "Someone is already mayor"
	assert lat >= -90 and lat <= 90, "Latitude must be integer between -90 and 90"
	assert long >= -180 and long <= 180, "Longitude must be integer between -180 and 180"
	self.guesses[lat][long] = GF({guesser: msg.sender, front: frontend})
	log NewGuess(lat, long, msg.sender, frontend)

@external
def doWinner(lat: int128, long: int128):
	"""
	@dev using the magic of off-chain computation, we define the Do winner
	@dev based on coordinate pair
	"""
	assert msg.sender == self.owner, "You must be owner to define the winner"
	assert self.guesses[lat][long].guesser != empty(address), "no guess at this lat/long"
	self.kwon = self.guesses[lat][long].guesser
	log FoundDo(lat, long, self.kwon)

@external
def suWinner(lat: int128, long: int128):
	"""
	@dev using the magic of off-chain computation, we define the Su winner
	@dev based on coordinate pair
	"""
	assert msg.sender == self.owner, "You must be owner to define the winner"
	assert self.guesses[lat][long].guesser != empty(address), "no guess at this lat/long"
	self.zhu = self.guesses[lat][long].guesser
	log FoundSu(lat, long, self.zhu)

@external
def kyleWinner(lat: int128, long: int128):
	"""
	@dev using the magic of off-chain computation, we define the Kyle winner
	@dev based on coordinate pair
	"""
	assert msg.sender == self.owner, "You must be owner to define the winner"
	assert self.guesses[lat][long].guesser != empty(address), "no guess at this lat/long"
	self.davies = self.guesses[lat][long].guesser
	log FoundKyle(lat, long, self.davies)

@external
def playUsOutKeyboardCat(frontend: address):
	"""
	@dev GAME OVER MAN, GAME OVER
	"""
	assert msg.sender == self.owner, "You must be the owner blah blah blah"
	assert self.davies != empty(address) and self.zhu != empty(address) and self.kwon != empty(address), "winners must be decided"
	### pay everyone out
	# for the good people doing good things
	high_five: uint256 = self.balance/10
	# congrats on guessing Dubai or Singapore
	winner_pot: uint256 = self.balance/6
	# frontend winner
	frontend_pot: uint256 = self.balance/20
	# look at us, funding good things non-quadratically
	# zachxbt
	send(0x9D727911B54C455B0071A7B682FcF4Bc444B5596, high_five)
	# coin center
	send(0x15322B546e31F5Bfe144C4ae133A9Db6F0059fe3, high_five)
	# give directly
	send(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C, high_five)
	# internet archive
	send(0xFA8E3920daF271daB92Be9B87d9998DDd94FEF08, high_five)
	# winners!
	send(self.kwon, winner_pot)
	send(self.zhu, winner_pot)
	send(self.davies, winner_pot)
	# front ender
	send(frontend, frontend_pot)
	# thanks for playing
	selfdestruct(self.owner)