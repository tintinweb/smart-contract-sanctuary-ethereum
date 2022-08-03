MAX_RAFF: constant(uint256) = 100

blockRaff: public(uint256)

owner: public(address)

event LogRandom:
	rando: uint256

@external
def __init():
	self.owner = msg.sender

@external
def setBlockRaff():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.blockRaff == 0, "can't set it twice"
	# locks randomness source to current block number + 10
	self.blockRaff = block.number + 10

@external
def genRando():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.blockRaff > 0, "blockRaff must be initialized"
	assert block.number > self.blockRaff, "Current block must be higher than blockRaff"
	source: uint256 = convert(blockhash(self.blockRaff), uint256)
	for i in range(1, 10):
		source = source ^ convert(blockhash(self.blockRaff - i), uint256)
	random: uint256 = source % MAX_RAFF
	log LogRandom(random)

@external
def reset():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	self.blockRaff = 0

@external
def destroy():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	selfdestruct(self.owner)