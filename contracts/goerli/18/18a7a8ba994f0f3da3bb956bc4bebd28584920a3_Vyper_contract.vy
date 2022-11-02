# @version 0.3.7

# HOLOCLEAR

from vyper.interfaces import ERC20

implements: ERC20


interface IFactory:
	def createPair(tokenA: address, tokenB: address) -> address: nonpayable
	def getPair(tokenA: address, tokenB: address) -> address: view

interface IRouter:
	def factory() -> address: view
	def WETH() -> address: view
	def addLiquidity(tokenA: address, tokenB: address, amountA: uint256, amountB: uint256, amountAMin: uint256, amountBMin: uint256, to: address, deadline: uint256) -> (uint256, uint256, uint256): nonpayable
	def swapExactTokensForETH(amountIn: uint256, amountOutMin: uint256, path:  DynArray[address, 5], to: address, deadline: uint256) -> DynArray[uint256, 5]: nonpayable
	def swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn: uint256, amountOutMin: uint256, path:  DynArray[address, 5], to: address, deadline: uint256): nonpayable

# ===== EVENTS ===== #

event Transfer:
	_from: indexed(address)
	_to: indexed(address)
	_value: uint256

event RemoveLimits:
    maxTx: uint256
    maxWallet: uint256

event Approval:
	_owner: indexed(address)
	_spender: indexed(address)
	_value: uint256

event Liquify:
	_weth: DynArray[uint256, 5]

event Payment:
	amount: uint256
	sender: indexed(address)

event here:
	_here: bool

event Log:
    message: String[100]
    val: uint256

# ===== STATE VARIABLES ===== #

owner: immutable(address)

vault: address
bank: address
_pair_address: address 
swap_locked: bool
fee_denom: constant(uint256) = 10 ** 18
is_excluded: HashMap[address, bool]
is_blacklisted: HashMap[address, bool]
routerAddress: address

name: public(String[64])
symbol: public(String[32])
decimals: public(uint8)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
pair_address: public(address)
live: public(bool)
has_interacted: public(HashMap[address, HashMap[address, bool]])
swap_limit: public(uint256)
buy_fee: public(uint256)
sell_fee: public(uint256)


FACTORY_ADDRESS: constant(address) = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
ROUTER_ADDRESS: constant(address) = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
# ===== INIT ===== #

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint8,  _supply: uint256):
	
	init_supply: uint256 = _supply * 10 ** convert(_decimals, uint256)

	self.name = _name
	self.symbol = _symbol
	self.decimals = _decimals
	self.balanceOf[msg.sender] = init_supply
	self.totalSupply = init_supply
	owner = msg.sender
	self.bank = msg.sender
	self.is_excluded[owner] = True
	self.is_excluded[self] = True
	self.is_excluded[self.bank] = True
	factory: IFactory = IFactory(FACTORY_ADDRESS)
	router: IRouter = IRouter(ROUTER_ADDRESS)
	self.pair_address = factory.createPair(self, router.WETH())


	log Transfer(empty(address), msg.sender, init_supply)

# ===== MUTATIVE ===== #

@internal
def _swap_tokens_for_eth(_amount: uint256):

	self._approve(self, ROUTER_ADDRESS, _amount)
	router: IRouter = IRouter(ROUTER_ADDRESS)
	router.swapExactTokensForETHSupportingFeeOnTransferTokens(_amount, 0, [self, router.WETH()], self, block.timestamp)
	send(self.bank, self.balance)

@internal
def _transfer(_from: address, _to: address, _val: uint256) -> bool:

	assert not self.is_blacklisted[_from]
	assert not self.is_blacklisted[_to]
	assert _to != empty(address)
	assert _from != empty(address)

	if not self.live:
		assert (_from == owner) or (_to == owner)

	if (self.balanceOf[self] > self.swap_limit) and (not self.swap_locked) and (_from != self.pair_address):
		self.swap_locked = True
		self._swap_tokens_for_eth(self.swap_limit)
		self.swap_locked = False

	self._token_transfer(_from, _to, _val)
	return True

@internal
def _token_transfer(_from: address, _to: address, _val: uint256):

	if self.is_excluded[_to] or self.is_excluded[_from]:
		self._excluded_transfer(_from, _to, _val)
	else:
		self._standard_transfer(_from, _to, _val)

@internal
def _excluded_transfer(_from: address, _to: address, _val: uint256):

	self.balanceOf[_from] -= _val
	self.balanceOf[_to] += _val
	log Transfer(_from, _to, _val)

@internal
def which_fee_pct(_from: address, _to: address) -> uint256:

	fee_pct: uint256 = 0

	if (self.pair_address == empty(address)):
		return fee_pct

	elif _to == self.pair_address:
		fee_pct = self.sell_fee
		return fee_pct

	elif _from == self.pair_address:
		fee_pct = self.buy_fee
		return fee_pct

	else:
		fee_pct = 0
		return fee_pct

@internal
def calculate_fee(_val: uint256, _fee_pct: uint256) -> uint256:

	fee: uint256 = (_val * _fee_pct) / fee_denom
	return fee

@internal
def _standard_transfer(_from: address, _to: address, _val: uint256):

	fee_pct: uint256 = self.which_fee_pct(_from, _to)
	fee: uint256 = self.calculate_fee(_val, fee_pct)

	self.balanceOf[_from] -= _val
	self.balanceOf[_to] += (_val - fee)
	self.balanceOf[self] += fee

	log Transfer(_from, _to, _val - fee)
	log Transfer(_from, self, fee)

@internal
def _approve(_owner: address, _spender: address, _val: uint256):
	self.allowance[_owner][_spender] = _val
	log Approval(msg.sender, _spender, _val)


@internal
def _burn(_to: address, _val: uint256):

	assert _to != empty(address)
	self.totalSupply -= _val
	self.balanceOf[_to] -= _val

	log Transfer(_to, empty(address), _val)

@external
def transfer(_to: address, _val: uint256) -> bool:

	return self._transfer(msg.sender, _to, _val)

@external
def transferFrom(_from: address, _to: address, _val: uint256) -> bool:

	return self._transfer(_from, _to, _val)

@external
def approve(_spender : address, _val : uint256) -> bool:

	self._approve(msg.sender, _spender, _val)
	return True

@external
def approve_max(_spender: address) -> bool:

	self._approve(msg.sender, _spender, max_value(uint256))

	self.has_interacted[msg.sender][_spender] = True

	return True

@external
def increaseAllowance( _spender: address, _val: uint256) -> bool:
	
	self._approve(msg.sender, _spender, self.allowance[msg.sender][_spender] + _val)

	if (self.allowance[msg.sender][_spender] + _val) == max_value(uint256):
		self.has_interacted[msg.sender][_spender] = True

	return True

@external
def decreaseAllowance(_spender: address, _val: uint256) -> bool:

	self.allowance[msg.sender][_spender] -= _val

	log Approval(msg.sender, _spender, self.allowance[msg.sender][_spender])

	return True


@external
def mint(_to: address, _val: uint256) -> bool:

	assert (msg.sender == owner) or (msg.sender == self.vault)
	assert _to != empty(address)

	self.totalSupply += _val
	self.balanceOf[_to] += _val

	log Transfer(empty(address), _to, _val)

	return True


@external
def burn(_val: uint256) -> bool:

	self._burn(msg.sender, _val)

	return True

@external
def burnFrom(_to: address, _val: uint256) -> bool:

	if self.allowance[_to][msg.sender] != max_value(uint256):
		self.allowance[_to][msg.sender] -= _val

		log Approval(_to, msg.sender, self.allowance[_to][msg.sender])

	self._burn(_to, _val)

	return True

@external
@payable
def __default__():
	log Payment(msg.value, msg.sender)

# ===== SET PARAMETERS ===== #


@external
def set_buy_fee(_buy_fee: uint256):

	assert msg.sender == owner

	self.buy_fee = _buy_fee

@external
def set_sell_fee(_sell_fee: uint256):

	assert msg.sender == owner

	self.sell_fee = _sell_fee


@external
def set_swap_limit(_swap_limit: uint256):

	assert msg.sender == owner

	self.swap_limit = _swap_limit


@external
def excludeAddress(_who: address, _bool: bool):

	assert msg.sender == owner

	self.is_excluded[_who] = _bool


@external
def set_bank(_bank: address):

	assert msg.sender == owner
	assert _bank != empty(address)

	self.bank = _bank

@external
def blacklist_wallet(_who: address, _bool: bool):

	assert msg.sender == owner

	self.is_blacklisted[_who] = _bool

@external
def set_live(_bool: bool):

	assert msg.sender == owner

	self.live = _bool