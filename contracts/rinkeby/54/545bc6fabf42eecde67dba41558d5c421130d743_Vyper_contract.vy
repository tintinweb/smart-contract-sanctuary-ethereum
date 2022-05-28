# @version 0.3.3

from vyper.interfaces import ERC20

##############
# STRUCTURES #
##############

struct Request:
	token: address
	amount: uint256
	signs: bool[2]

###################
# STATE VARIABLES #
###################

owner: public(address)
signers: public(address[2])
request: public(Request)
is_init: public(bool)

######################
# INTERNAL FUNCTIONS #
######################

@nonpayable
@internal
def reset_request():
	self.request.token = ZERO_ADDRESS
	self.request.amount = 0
	self.request.signs[0] = False
	self.request.signs[1] = False

######################
# EXTERNAL FUNCTIONS #
######################

@nonpayable
@external
def initialize(_signer1: address, _signer2: address):
	assert _signer1 != _signer2
	self.owner = msg.sender
	self.signers[0] = _signer1 
	self.signers[1] = _signer2
	assert self.owner != self.signers[0] and self.owner != self.signers[1]
	self.is_init = True

@nonpayable
@external
def deposit(_token: address, _amount: uint256):
	# add assert msg.sender == self.OWNER?
	assert self.is_init == True
	ERC20(_token).transferFrom(msg.sender, self, _amount)

@nonpayable
@external
def request_withdrawal(_token: address, _amount: uint256):
	assert self.is_init == True
	assert msg.sender == self.owner
	self.reset_request()
	self.request.token = _token
	self.request.amount = _amount

@nonpayable
@external
def validate_withdrawal():
	assert self.is_init == True
	assert msg.sender == self.signers[0] or msg.sender == self.signers[1]
	if msg.sender == self.signers[0]:
		self.request.signs[0] = True
	else:
		self.request.signs[1] = True

@nonpayable
@external
def withdraw(_token: address, _amount: uint256):
	assert self.is_init == True
	assert msg.sender == self.owner
	assert self.request.signs[0] == True and self.request.signs[1] == True
	ERC20(_token).transfer(msg.sender, _amount)