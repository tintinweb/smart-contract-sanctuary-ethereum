# @version 0.3.7

"""
@title Bare-bones Token implementation
@notice Based on the ERC-20 token standard as defined at
        https://eips.ethereum.org/EIPS/eip-20
"""

from vyper.interfaces import ERC20

interface IUniswapV2Router02:
    def WETH() -> address: view

    def addLiquidityETH(
        _token: address,
        _amountTokenDesired: uint256,
        _amountTokenMin: uint256,
        _amountETHMin: uint256,
        _to: address,
        _deadline: uint256
    ) -> (uint256, uint256, uint256): payable

    def swapExactTokensForETHSupportingFeeOnTransferTokens(
        _amountIn: uint256,
        _amountOutMin: uint256,
        _path: DynArray[address, 3],
        _to: address,
        _deadline: uint256
    ): nonpayable

interface IUniswapV2Factory:
    def createPair(
        _tokenA: address,
        _tokenB: address
    ) -> address: nonpayable

implements: ERC20

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event SetRouter:
    newRouter: indexed(address)

event SetSwapThreshold:
    value: uint256

event RemoveLimits:
    maxTx: uint256
    maxWallet: uint256

event SetTaxes:
    buyTax: uint256
    sellTax: uint256

event IsTrading:
    hasPaused: bool

event StartTrading:
    startBlock: uint256
    canTrade: bool    

# Public generated getters
name: public(immutable(String[64]))
symbol: public(immutable(String[32]))
decimals: public(immutable(uint8))
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
buyTax: public(uint256)
sellTax: public(uint256)
isTrading: public(bool)
owner: public(address)
devWallet: public(address)
launchedAt: public(uint256)
swapThreshold: public(uint256)
txLimit: public(uint256)
walletCap: public(uint256)
routerAddress: public(address)

# Internal use var
WETH: immutable(address)
FACTORY_ADDRESS: immutable(IUniswapV2Factory)
TRADING_PAIR: immutable(address)
MAX_TAX: immutable(uint256)
amountReceive: uint256
inSwap: bool
pauseCounter: uint8

@external
def __init__(
    _name: String[64], 
    _symbol: String[32], 
    _decimals: uint8, 
    _total_supply: uint256):
    init_supply: uint256 = _total_supply * 10 ** convert(_decimals, uint256)
    name = _name
    symbol = _symbol
    decimals = _decimals
    WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    FACTORY_ADDRESS = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
    TRADING_PAIR = FACTORY_ADDRESS.createPair(self, WETH)
    MAX_TAX = 25
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.owner = msg.sender
    self.txLimit = self.totalSupply * 2 / 100
    self.walletCap = self.totalSupply * 2 / 100
    log Transfer(empty(address), msg.sender, init_supply)

##########
# @dev Functions below for internal use
##########

@internal
def _checkOwner():
    """
    @dev Internal bool check for owner assert
    """
    assert msg.sender == self.owner, "ah ah ah, you didn't say the magic word"

@internal
def _distributeSellTax(_from: address, _to: address, _value: uint256):
    """
    @dev Internal function for the tax math distribution
    """
    sellFeeAmount: uint256 = _value * self.sellTax / 100
    if self.allowance[_from][msg.sender] != max_value(uint256):
        self._decreaseAllowance(_from, msg.sender, _value)
    self.balanceOf[_from] -= _value
    self.balanceOf[self] += sellFeeAmount  # Transfer tax amount to self(contract)
    self.balanceOf[_to] += _value - sellFeeAmount # Transfer token amount minus tax to holder
    self.inSwap = False
    log Transfer(_from, _to, _value)

@internal
def _distributeBuyTax(_from: address, _to: address, _value: uint256):
    """
    @dev Internal function for the tax math distribution
    """
    buyFeeAmount: uint256 = _value * self.buyTax / 100
    self.balanceOf[_from] -= _value
    self.balanceOf[self] += buyFeeAmount  # Transfer tax amount to self(contract)
    self.balanceOf[_to] += _value - buyFeeAmount # Transfer token amount minus tax to holder
    log Transfer(_from, _to, _value)
    

@internal 
def _transfer(_from: address, _to: address, _value: uint256) -> bool:
    assert _from != empty(address)
    assert _to != empty(address)
    if _from == self.owner or _to == self.owner:
        self._basicTransfer(_from, _to, _value)
    else:
        assert self.isTrading == True
        assert _value > 0 and _value <= self.txLimit
        if _to == TRADING_PAIR:
            if not self.inSwap and self.balanceOf[self] >= self.swapThreshold:
                self._swapBack()
            self._distributeSellTax(_from, _to, _value)
        else:
            assert self.balanceOf[_to] + _value <= self.walletCap
            self._distributeBuyTax(_from, _to, _value)
    return True

@internal 
def _basicTransfer(_from: address,_to: address,_value: uint256):
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)

@internal 
def _swapBack():
    """
    @dev Internal function for swapping contract tokens for eth
         using uniswap router
    """
    self.inSwap = True
    self._approve(self, self.routerAddress, self.swapThreshold)
    router: IUniswapV2Router02 = IUniswapV2Router02(self.routerAddress)
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        self.swapThreshold,
        0,
        [self, WETH],
        self,
        block.timestamp + 4
    )

@internal
def _approve(_owner: address, _spender: address, _value: uint256):
    self.allowance[_owner][_spender] = _value
    log Approval(_owner, _spender, _value)

@internal 
def _decreaseAllowance(_owner: address, _spender: address, _subtractedValue: uint256):
    """
    @dev Internal function to atomically decrease allowance if not max_value(uint356)
    """
    _currentAllowance: uint256 = self.allowance[_owner][_spender]
    assert _currentAllowance >= _subtractedValue
    self._approve(_owner, _spender, _currentAllowance - _subtractedValue)

##########
# @dev Functions below are public functions
##########

@external
@payable
def __default__():
    pass

@external
def approve(_spender : address, _value : uint256) -> bool:
    """
    @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
    @dev Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    @return Success boolean
    """
    self._approve(msg.sender, _spender, _value)
    return True

@external
def transfer(_to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _to The address to transfer to
    @param _value The amount to be transferred
    @return Internal _transfer
    """
    return self._transfer(msg.sender, _to, _value)

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param _from The address which you want to send tokens from
    @param _to The address which you want to transfer to
    @param _value The amount of tokens to be transferred
    @return Internal _transfer
    """
    return self._transfer(_from, _to, _value)
    
##########
# @dev Functions below are owner only
##########

@external
def canTrade():
    """
    @dev Owner only function to enable trading
    """
    self._checkOwner()
    self.launchedAt = block.timestamp
    self.isTrading = True
    log StartTrading(self.launchedAt, self.isTrading)

@external
def pauseTrading():
    """
    @dev Owner only function that only be called once for emergency use.
         self.isTrading will change to false. Setting the pauseCounter to 1 
         will allow the contract to only be paused once and will be able to 
         resume, but thereafter will revert
    """
    self._checkOwner()
    if self.pauseCounter < 1:
        self.pauseCounter += 1
        self.isTrading = False
        log IsTrading(self.isTrading)
    elif self.pauseCounter == 1:
        self.isTrading = True
        log IsTrading(self.isTrading)
    else:
        raise "Can only pause once"

@external
def setSwapThreshold(_value: uint256):
    """
    @dev Owner only function to set swap threshold for tax sells
         Tax amount must be less than 1% of total supply
    @param _value is an int less than ten. This is a percentage
            based on 1000 points  
    """
    self._checkOwner()
    assert _value < 10
    self.swapThreshold = self.totalSupply * _value / 1000
    log SetSwapThreshold(self.swapThreshold)       

@external
def setTaxes(_buyTaxValue: uint256, _sellTaxValue: uint256):
    """
    @dev Owner only function to set tax amounts
        cannot exceed 25
    @param _buyTaxValue set buy tax
    @param _sellTaxValue set sell tax
    """
    self._checkOwner()
    assert _sellTaxValue + _buyTaxValue <= MAX_TAX
    self.buyTax = _buyTaxValue
    self.sellTax = _sellTaxValue
    log SetTaxes(self.buyTax, self.sellTax)

    
@external
def setDevWallet(_newWallet: address) -> bool:
    """
    @dev Owner only function to set new developer wallet
    @param _newWallet new wallet to send tax to
    """
    self._checkOwner()
    assert _newWallet != empty(address)
    assert _newWallet != self.devWallet
    self.devWallet = _newWallet
    return True

@external
def setRouter(_address: address) -> bool:
    """
    @dev Set router in case of uniswap upgrade
    @param _address Router address 
    """
    self._checkOwner()
    assert _address != empty(address)
    assert _address != self.routerAddress
    self.routerAddress = _address
    log SetRouter(_address)
    return True

@external
@payable
@nonreentrant("lock")
def manualSend() -> bool:
    """
    @dev Owner only function to send collected eth from contract to dev wallet
    """
    self._checkOwner()
    send(self.devWallet, self.balance)
    return True

@external
def removeLimits() -> bool:
    """
    @dev Owner only function to remove hard coded txn limits
    """
    self._checkOwner()
    self.txLimit = max_value(uint256)
    self.walletCap = max_value(uint256)
    log RemoveLimits( self.txLimit, self.walletCap)
    return True