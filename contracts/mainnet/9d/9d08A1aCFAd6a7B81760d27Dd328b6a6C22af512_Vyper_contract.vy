# @version >=0.3.7
"""
@title The Bitbanter Raffle (v2)
@dev A contract to run a raffle to win a book I haven't yet written (or to allow some rich jerk to rugpull everyone else).
@dev No matter what, a portion of the proceeds goes to good people doing good work, and everyone who participated gets what will surely be a priceless, pixelated tulip NFT.
@dev If the raffle doesn't meet its arbitrary goal, the rest of the ETH is burned.
@dev If the raffle does meet its arbitrary goal (or some rich jerk rugpulls), someone receives a golden, pixelated tulip NFT, and the book will be encrypted against the public key of whoever holds it in 4 years time.
@dev The old version had a crazy forced leverage thing, but honestly that was too Rube-Goldberg even for me. 
@dev This is (still) an insane contract.
@author Josh Cincinnati (twitter: @acityinohio, website: https://bitbanter.com/)
"""
############### variables ###############
# Bitbanter Tulip Contract Address
BITTULIP_ADDR: constant(address) = 0x38b61e9047425F6353C6d4Cf3D7249429AD1F818

# Golden Bitbanter Tulip Contract Address
GOLDEN_BITTULIP_ADDR: constant(address) = 0x5B227f996b5d903EDCeAB6766E90c0C54a352d0B

# Maximum number of participants/how much it costs (in ETH) to rugpull everyone
MAX_RAFF: constant(uint256) = 10000

# Base cost for raffle spot, 0.0001 ETH in wei
# Cost for entry scales as more people enter (BASE_COST * raffleSpot)
BASE_COST: constant(uint256) = 100000000000000

# the contract owner
owner: public(address)

# whether the raffle has ended (defaults to false)
ended: public(bool)

# current spot on the raffle
raffleSpot: public(uint256)

# participating rafflers stored in an array, MAX_RAFF-able
# if they participate multiple times, appended to array
raffleAddr: DynArray[address, MAX_RAFF]

############### events ###############
# when someone says governance and we nuke everything, as a treat
event SomeoneSaidGovernance: pass

# someone added their address to the raffle!
event NewRaffler:
	raffler: address

# someonne won the raffle! get ready to be disappointed in 4 years
event RaffleWinner:
	winner: address

# some rich person short-circuited the raffle! get ready to be _expensively_ disappointed in 4 years
event RichyRugpull:
	fatCat: address

############### interfaces ###############
# for the ERC-1155 tulips
# subset of methods
interface Tulip:
	def pause(): nonpayable
	def unpause(): nonpayable
	def paused() -> bool: view
	def renounceOwnership(): nonpayable
	def mint(receiver: address, id: uint256, amount: uint256, data: bytes32): nonpayable

############### init and internal functions ###############

@external
def __init__():
	"""
	@dev contract initialization on deployment
	@dev set sender as owner, set raffleSpot to 1
	"""
	self.owner = msg.sender
	self.raffleSpot = 1

## mop up, we're done with the raffle
@internal
def _cleanUpAisleTen():
	"""
	@dev unpauses the nfts, disowns them
	@dev (with a little something something for good people)
	"""
	# good people doing good work deserve good things
	# look at us, funding good things non-quadratically
	high_five: uint256 = self.balance/10
	# zachxbt
	send(0x9D727911B54C455B0071A7B682FcF4Bc444B5596, high_five)
	# coin center
	send(0x15322B546e31F5Bfe144C4ae133A9Db6F0059fe3, high_five)
	# give directly
	send(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C, high_five)
	# internet archive
	send(0x1B40ed3d89fd40f875bF62A0ce79f562714d011E, high_five)
	# unpause bit tulips, if paused
	if Tulip(BITTULIP_ADDR).paused():
		Tulip(BITTULIP_ADDR).unpause()
	# unown
	Tulip(BITTULIP_ADDR).renounceOwnership()
	Tulip(GOLDEN_BITTULIP_ADDR).renounceOwnership()
	# end raffle
	self.ended = True


############### raffle functions ###############

## someone said governance...or I got bored.
## anyway burn this place (and its ETH) to the ground.
## it's over. it's so over.
@external
def someoneSaidGovernance():
	"""
	@dev I'm so done. Keep your tulips, and I'll keep mine. Let (my) ETH burn.
	@dev Unpauses the ERC-1155s, mints the golden tulip to me if the raffle hasn't happened and the goal hasn't been reached.
	@dev Revokes ownership to make them fully dEcEnTrAlIzEd, self-destructs this contract.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "Raffle already over, stop trying to mint more golden bit tulips"
	assert self.raffleSpot <= MAX_RAFF,  "Stop trying to cheat the raffle design Josh"
	# mint golden tulip to me
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.owner, 1, 1, empty(bytes32))
	# clean up the raffle
	self._cleanUpAisleTen()
	# log it
	log SomeoneSaidGovernance()
	# send it (my eth) to ZERO
	selfdestruct(empty(address))

## or the raffle or richy rugpull ended successfully, send the ETH and let it all go
@external
def missionAccomplishedBanner():
	"""
	@dev run after the raffle is over, or someone richy rugpulled
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.ended, "Raffle not over yet, stop trying to cheat the raffle design Josh"
	## send the ETH to the owner after the contract is done
	selfdestruct(self.owner)

## add your lucky address to the lucky list
## are you feeling lucky? ...you shouldn't tbh
@external
@payable
def updateRaffle():
	"""
	@dev If it doesn't already exist, adds sender's address to the raffle list 
	@dev User allowed to contribute more in successive transactions if they want (why they would I have no idea).
	@dev Must send at least BASE_COST * raffleSpot ETH to enter
	"""
	assert not self.ended, "The raffle has ended, you can't update it after it's already over" 
	assert msg.value >= BASE_COST * self.raffleSpot, "You must send at least BASE_COST * raffleSpot ETH to enter"
	assert self.raffleSpot <= MAX_RAFF, "Insanely, this contract already has met its goal, so you can't participate"
	## it's time to update raffleAddr and raffleSpot
	self.raffleAddr.append(msg.sender)
	self.raffleSpot += 1
	# unpause bit tulips (check to see if paused first)
	if Tulip(BITTULIP_ADDR).paused():
		Tulip(BITTULIP_ADDR).unpause()
	# mint their tulip
	Tulip(BITTULIP_ADDR).mint(msg.sender, 1, 1, empty(bytes32))
	# pause bit tulips
	Tulip(BITTULIP_ADDR).pause()
	# log the new raffler
	log NewRaffler(msg.sender)

## oh look at you big shot
## you want the golden tulip? fine
@external
@payable
def richyRugpull():
	"""
	@dev When a whale wants to buy your book at the market-clearing price, you let them.
	@dev But hey, if they rugpull you, look on the bright side:
	@dev ...at least you got a bitbanter tulip NFT out of it?
	"""
	assert not self.ended, "The raffle has ended, rugpulls are impossible in this new paradigm"
	assert msg.value >= as_wei_value(MAX_RAFF, "ether"), "You need to send more, cheapskate"
	# they're the totally fair winner, based on equal parts skill and luck!
	# mint the golden tulip 
	Tulip(GOLDEN_BITTULIP_ADDR).mint(msg.sender, 1, 1, empty(bytes32))
	# log the richy rugpull
	log RichyRugpull(msg.sender)
	# clean up the raffle/end it
	self._cleanUpAisleTen()

## then we run the raffle
## sourcing the randomness from current block number and 100 trailing blocks
## yeah it's not perfect but look this isn't exactly meant to be a perfect contract
@external
def runRaffle():
	"""
	@dev time to run this very well designed random raffle that can't possibly be cheated
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.raffleSpot > MAX_RAFF, "Stop trying to cheat the raffle design Josh"
	## source randomness from 100 block hashes trailing current block - 1
	## yeah I know, this isn't robust, there are many things wrong with this, a miner could be bribed etc
	## but I refuse to pay for the chainlink VRF
	## furthermore I'm not convinced the chainlink randomness isn't just Sergey flipping a coin 
	## anyway this will select a number from 0 inclusive to MAX_RAFF-1
	source: uint256 = convert(blockhash(block.number - 1), uint256)
	for i in range(2, 100):
		source = source ^ convert(blockhash(block.number - i), uint256)
	random: uint256 = source % MAX_RAFF
	## since the raffleAddrs are in an array up to length MAX_RAFF, we simply mint the golden tulip to the winner and end the raffle
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.raffleAddr[random], 1, 1, empty(bytes32))
	# log the winner!
	log RaffleWinner(self.raffleAddr[random])
	# clean up the raffle
	self._cleanUpAisleTen()