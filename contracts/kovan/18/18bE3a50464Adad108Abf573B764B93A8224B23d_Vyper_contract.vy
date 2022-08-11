# @version >=0.3.4

MAX_RAFF: constant(uint256) = 42069

owner: public(address)

############### events ###############
event NewRando:
	rando: uint256

############### init and internal functions ###############

@external
def __init__():
	self.owner = msg.sender


############### raffle functions ###############

@external
def runRando():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	source: uint256 = convert(blockhash(block.number - 1), uint256)
	for i in range(2, 100):
		source = source ^ convert(blockhash(block.number - i), uint256)
	random: uint256 = source % MAX_RAFF
	log NewRando(random)

####### testnet self-destruct ########
@external
def destroy():
	"""
	@dev just to use while testing
	"""
	assert self.owner == msg.sender, "Owneable: caller is not the owner"
	selfdestruct(self.owner)