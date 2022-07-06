# @version ^0.3.3
"""
@title The Shot That Rang Round The World
@license WTFPL
@author We The People
@notice Voting Dapp to choose a new currency name and symbol for most stable,
inflation, and deflation resistent currency to ever be created, because it is
backed by the value created by the hard work of Americans.  In other words, its
value is backed by The People, of The People, and for The People.
"""

struct Symbol:
	is_created: bool
	value: String[5]
	upvotes: int256  # count of up votes
	downvotes: int256  # count of down votes

event SymbolCreated:
	is_created: bool
	value: String[5]
	upvotes: int256
	downvotes: int256
	name: String[32]

event SymbolUpdated:
	is_created: bool
	value: String[5]
	upvotes: int256
	downvotes: int256
	name: String[32]

@internal
def get_symbol_id(symbol: String[5]) -> bytes32:
	"""
	@notice Return the ID of a given currency symbol.
	@return bytes32
	"""
	return keccak256(symbol)

struct Name:
	is_created: bool
	value: String[32]
	upvotes: int256
	downvotes: int256

event NameCreated:
	is_created: bool
	value: String[32]
	upvotes: int256
	downvotes: int256
	symbol: String[5]

event NameUpdated:
	is_created: bool
	value: String[32]
	upvotes: int256
	downvotes: int256
	symbol: String[5]

@internal
def get_name_id(symbol: String[5], name: String[32]) -> bytes32:
	"""
	@notice Return the ID of a given currency name.
	@return bytes32
	"""
	return keccak256(concat(symbol, name))

owner: public(address)
DEADLINE: constant(uint256) = 1665201600

funders: public(HashMap[address, uint256]) # {funder.address: amount_donated}

symbol_ids: public(DynArray[bytes32, 2**128-1]) # [symbol_id, ...]
symbols: public(HashMap[bytes32, Symbol]) # {symbol_id: Symbol}

name_ids: public(DynArray[bytes32, 2**128-1]) # [name_id, ...]
names: public(HashMap[bytes32, Name]) # {name_id: Name}

lovers: public(HashMap[bytes32, HashMap[address, uint256]]) # {name_id: {lover_addy: amount_of_love}}
haters: public(HashMap[bytes32, HashMap[address, uint256]]) # {name_id: {hater_addy: amount_of_hate}}

@external
def __init__():
	self.owner = msg.sender
	return

@internal
def symbol_exists(symbol_id: bytes32) -> bool:
	return self.symbols[symbol_id].is_created

@internal
def name_exists(name_id: bytes32) -> bool:
	return self.names[name_id].is_created

@internal
def _raise_if_expired():
	if block.timestamp > DEADLINE:
		raise 'The deadline has passed, but thank you for your patriotism!'

@internal
def _raise_if_symbol_not_exists(symbol_id: bytes32):
	if not self.symbol_exists(symbol_id):
		raise 'Currency symbol has not been created'

@internal
def _raise_if_duplicate_currency(name_id: bytes32):
	if self.name_exists(name_id):
		raise 'Currency with the same symbol and name has already been created'

@internal
def _raise_if_name_not_exists(name_id: bytes32):
	if not self.name_exists(name_id):
		raise 'Currency name has not been created'

@external
@payable
def __default__():
	"""
	@notice Accept a donation and record who donated and how much.
	"""
	self._raise_if_expired()
	self.funders[msg.sender] += msg.value
	return

@internal
def _raise_if_currency_does_not_exist(symbol_id: bytes32, name_id: bytes32):
	self._raise_if_symbol_not_exists(symbol_id)
	self._raise_if_name_not_exists(name_id)

@external
@payable
def create_currency(symbol: String[5], name: String[32]):
	"""
	@notice Propose a new currency symbol and name pair for others to vote on.
	@dev msg.value Show your confidence in your currency by adding a bit of
	extra love to it.
	"""
	self._raise_if_expired()
	symbol_id: bytes32 = self.get_symbol_id(symbol)
	name_id: bytes32 = self.get_name_id(symbol, name)
	self._raise_if_duplicate_currency(name_id)
	self.symbol_ids.append(symbol_id)
	self.name_ids.append(name_id)
	self.symbols[symbol_id] = Symbol({
		is_created: True,
		value: symbol,
		upvotes: 1,
		downvotes: 0,
	})
	log SymbolCreated(
		self.symbols[symbol_id].is_created,
		self.symbols[symbol_id].value,
		self.symbols[symbol_id].upvotes,
		self.symbols[symbol_id].downvotes,
		name,
	)
	self.names[name_id] = Name({
		is_created: True,
		value: name,
		upvotes: 1,
		downvotes: 0,
	})
	log NameCreated(
		self.names[name_id].is_created,
		self.names[name_id].value,
		self.names[name_id].upvotes,
		self.names[name_id].downvotes,
		symbol,
	)
	if msg.value > 0:
		self.lovers[name_id][msg.sender] = msg.value
		self.funders[msg.sender] += msg.value
	return

@external
def payout(to: address, amount: uint256):
	assert self.owner == msg.sender, "Ahh, ahh, ahh, you didn't say the magic word!"
	send(to, amount)
	return

@external
@payable
def upvote(symbol: String[5], name: String[32]):
	"""
	@notice Vote for a currency symbol and name.
	@dev msg.value Show the world how much you approve of a currency by
	adding a bit of extra love to your vote.
	"""
	self._raise_if_expired()
	symbol_id: bytes32 = self.get_symbol_id(symbol)
	name_id: bytes32 = self.get_name_id(symbol, name)
	self._raise_if_currency_does_not_exist(symbol_id, name_id)
	self.symbols[symbol_id].upvotes += 1
	log	SymbolUpdated(
		self.symbols[symbol_id].is_created,
		self.symbols[symbol_id].value,
		self.symbols[symbol_id].upvotes,
		self.symbols[symbol_id].downvotes,
		name,
	)
	self.names[name_id].upvotes += 1
	log	NameUpdated(
		self.names[name_id].is_created,
		self.names[name_id].value,
		self.names[name_id].upvotes,
		self.names[name_id].downvotes,
		symbol,
	)
	if msg.value > 0:
		self.lovers[name_id][msg.sender] += msg.value
		self.funders[msg.sender] += msg.value
	return

@external
@payable
def downvote(symbol: String[5], name: String[32]):
	"""
	@notice Vote against a currency symbol and name.
	@dev msg.value Show the world how much you disapprove of a currency by
	adding a bit of extra hate to your vote.
	"""
	self._raise_if_expired()
	symbol_id: bytes32 = self.get_symbol_id(symbol)
	name_id: bytes32 = self.get_name_id(symbol, name)
	self._raise_if_currency_does_not_exist(symbol_id, name_id)
	self.symbols[symbol_id].downvotes += 1
	log	SymbolUpdated(
		self.symbols[symbol_id].is_created,
		self.symbols[symbol_id].value,
		self.symbols[symbol_id].upvotes,
		self.symbols[symbol_id].downvotes,
		name,
	)
	self.names[name_id].downvotes += 1
	log	NameUpdated(
		self.names[name_id].is_created,
		self.names[name_id].value,
		self.names[name_id].upvotes,
		self.names[name_id].downvotes,
		symbol,
	)
	if msg.value > 0:
		self.haters[name_id][msg.sender] += msg.value
		self.funders[msg.sender] += msg.value
	return