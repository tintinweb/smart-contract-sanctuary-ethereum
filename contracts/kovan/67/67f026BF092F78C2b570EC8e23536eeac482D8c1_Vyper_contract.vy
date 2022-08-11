# @version >=0.3.4

MAX_RAFF: constant(uint256) = 42069

owner: public(address)
blockRaff: public(uint256)
ended: public(bool)

############### events ###############
event NewRando:
	rando: uint256

############### init and internal functions ###############

@external
def __init__():
	self.owner = msg.sender


############### raffle functions ###############

@external
def setBlockRaff():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.blockRaff == 0, "can't set blockRaff twice"
	self.blockRaff = block.number + 100

@external
def runRaffle():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.balance >= as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	assert self.blockRaff > 0, "blockRaff must be initialized"
	assert block.number > self.blockRaff, "Current block must be higher than blockRaff"
	source: uint256 = convert(blockhash(self.blockRaff), uint256)
	for i in range(1, 100):
		source = source ^ convert(blockhash(self.blockRaff - i), uint256)
	random: uint256 = source % MAX_RAFF
	log NewRando(random)
	self.ended = True

@external
def reset():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	self.blockRaff = 0
	self.ended = False

####### testnet self-destruct ########
@external
def destroy():
	"""
	@dev just to use while testing
	"""
	assert self.owner == msg.sender, "Owneable: caller is not the owner"
	selfdestruct(self.owner)