# @version >=0.3.4

MAX_RAFF: constant(uint256) = 4

owner: public(address)

raffleAddr: DynArray[address, MAX_RAFF]

############### events ###############
event NewRando:
	rando: uint256

event RaffleWinner:
	winner: address

############### init and internal functions ###############

@external
def __init__():
	self.owner = msg.sender
	self.raffleAddr.append(0xe4Cb6c60d6Cf1cdeDc56A6Bd1ff4b4f64003c74C)
	self.raffleAddr.append(0x582a42455486D9884b19e19F7FeA4221b8B814F5)
	self.raffleAddr.append(0x004767FC32C283Ecf29e2f4a202DE2CDDe803C9e)
	self.raffleAddr.append(0x52256313Aa12108ae50D4F49578769fc6bE8ffFf)

############### raffle functions ###############

@external
def runRando():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	source: uint256 = convert(blockhash(block.number - 1), uint256)
	for i in range(2, 100):
		source = source ^ convert(blockhash(block.number - i), uint256)
	random: uint256 = source % MAX_RAFF
	log NewRando(random)
	log RaffleWinner(self.raffleAddr[random])

####### testnet self-destruct ########
@external
def destroy():
	"""
	@dev just to use while testing
	"""
	assert self.owner == msg.sender, "Owneable: caller is not the owner"
	selfdestruct(self.owner)