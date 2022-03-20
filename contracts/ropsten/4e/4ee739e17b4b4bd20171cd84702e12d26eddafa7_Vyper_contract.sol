# @version ^0.3.1
# Crypto Ninja main smart contract entry point

# Invoice interface
interface Invoice:
	def setup(
		_invoice_id: uint256,
		_currency: String[CURRENCY_LENGTH],
		_amount_due: uint256,
		_rate: decimal,
		_send_to: address,
	): nonpayable
CURRENCY_LENGTH: constant(uint256) = 20

# Owner of the Crypto Ninja smart contract
owner: address
invoice_contract: address # implemention address for Invoice logic
send_to: address # address payment should be forwarded to for liquidation

# the User object
struct User:
	is_registered: bool

# the Merchant object
struct Merchant:
	is_registered: bool
	spread_pct: decimal
	last_invoice_number: uint256

# merchants as {merchant_id: Merchant, ...}
merchants: HashMap[address, Merchant]
# merchant's authorized users
#  as {merchant_id: {user_id: User, ...}, ...}
merchant_users: HashMap[address, HashMap[address, User]]
# all users as {user_id: is_registered, ...}
#  this helps us verify a user does not register with more than
#  one merchant.
users: HashMap[address, User]
# invoices as {merchant_id: {invoice_number: invoice_address, ...}, ...}
invoices: HashMap[address, HashMap[uint256, address]]

@external
def __init__(_invoice_contract: address, _send_to: address):
	assert _invoice_contract != ZERO_ADDRESS
	assert _send_to != ZERO_ADDRESS
	self.invoice_contract = _invoice_contract
	self.owner = tx.origin
	self.send_to = _send_to
	return

@external
def transfer_ownership(_new_owner: address):
	assert tx.origin == self.owner
	self.owner = _new_owner
	return

@external
def upgrade_invoice_implementation(_new_invoice_address: address):
	assert _new_invoice_address != ZERO_ADDRESS
	self.invoice_contract = _new_invoice_address
	return

@internal
def _verify_not_existing_merchant(_merchant_id: address):
	# make sure the merchant is not already a registered merchant
	assert self.merchants[_merchant_id].is_registered == False
	return

@internal
def _verify_not_existing_user(_user_id: address):
	# make sure the merchant is not already a user
	assert self.users[_user_id].is_registered == False
	return

@internal
def _authenticate_user(_user_id: address, _merchant_id: address):
	# verify merchant is registered
	assert self.merchants[_merchant_id].is_registered == True
	# authenticate user is authorized for the merchant
	assert self.merchant_users[_merchant_id][_user_id].is_registered == True
	return

@internal
def _get_next_invoice_id(_merchant_id: address) -> uint256:
	return self.merchants[_merchant_id].last_invoice_number + 1

@external
def register_new_merchant():
	self._verify_not_existing_merchant(tx.origin)
	self._verify_not_existing_user(tx.origin)
	# create the new user variable
	user: User = User({
		is_registered: True,
	})
	# create the new merchant variable
	merchant: Merchant = Merchant({
		is_registered: True,
		spread_pct: 0.0025, # default spread percentage
		last_invoice_number: 0,
	})
	# store the new merchant in this contract
	self.merchants[tx.origin] = merchant
	self.merchant_users[tx.origin][tx.origin] = user
	# register the merchant as a user
	self.users[tx.origin].is_registered = True
	return

# Can only be called by a registered merchant.
@external
def register_new_user(_user_id: address):
	# make sure sender is a registered merchant
	assert self.merchants[tx.origin].is_registered == True
	# verify user is not already a user for the merchant
	assert self.merchant_users[tx.origin][_user_id].is_registered == False
	# make sure user is not already a registered user
	assert self.users[_user_id].is_registered == False
	user: User = User({
		is_registered: True,
	})
	# store the new user in the merchant object
	self.merchant_users[tx.origin][_user_id] = user
	# store the new user ID in the all users object
	self.users[_user_id] = user
	return

@external
@nonreentrant('lock')
def create_invoice(
	_merc_id: address,
	_amount_due: uint256,
	_rate: decimal,
	_currency: String[CURRENCY_LENGTH],
) -> address:
	# authenticate user is authorized by the merchant
	self._authenticate_user(tx.origin, _merc_id)
	# create the invoice
	invoice_id: uint256 = self._get_next_invoice_id(_merc_id)
	inv_addr: address = create_forwarder_to(self.invoice_contract)
	Invoice(inv_addr).setup(
		invoice_id,
		_currency,
		_amount_due,
		_rate,
		self.send_to,
	)

	# store invoice on blockchain
	self.invoices[_merc_id][invoice_id] = inv_addr
	# increment last invoice number of Merchant object
	self.merchants[_merc_id].last_invoice_number = invoice_id
	return inv_addr