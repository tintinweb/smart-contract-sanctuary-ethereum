# @version 0.3.1
"""
@title Versailles heroes DAO token
@author Versailles heroes
@license MIT
@notice ERC20 with piecewise-linear mining supply.
"""

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event UpdateMiningParameters:
    time: uint256
    rate: uint256
    supply: uint256

event SetMinter:
    minter: address

event SetAdmin:
    admin: address

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
minter: public(address)
admin: public(address)

YEAR: constant(uint256) = 86400 * 365
INITIAL_SUPPLY: constant(uint256) = 727_200_000
INITIAL_RATE: constant(uint256) = 121_587_840 * 10 ** 18 / YEAR
RATE_REDUCTION_TIME: constant(uint256) = YEAR
RATE_REDUCTION_COEFFICIENT: constant(uint256) = 1189207115002721024  # 2 ** (1/4) * 1e18
RATE_DENOMINATOR: constant(uint256) = 10 ** 18
INFLATION_DELAY: constant(uint256) = 86400

rate: public(uint256)
mining_epoch: public(int128)
start_epoch_time: public(uint256)
start_epoch_supply: uint256

@external
def __init__(_name: String[64], _symbol: String[32], _decimals: uint256):
    init_supply: uint256 = INITIAL_SUPPLY * 10 ** _decimals
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.admin = msg.sender
    self.rate = 0
    self.mining_epoch = -1
    self.start_epoch_time = block.timestamp + INFLATION_DELAY - RATE_REDUCTION_TIME
    self.start_epoch_supply = init_supply
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@internal
def _update_mining_parameters():
    _rate: uint256 = self.rate
    _start_epoch_supply: uint256 = self.start_epoch_supply

    self.start_epoch_time += RATE_REDUCTION_TIME
    self.mining_epoch += 1

    if _rate == 0:
        _rate = INITIAL_RATE
    else:
        _start_epoch_supply += _rate * RATE_REDUCTION_TIME
        self.start_epoch_supply = _start_epoch_supply
        _rate = _rate * RATE_DENOMINATOR / RATE_REDUCTION_COEFFICIENT

    self.rate = _rate

    log UpdateMiningParameters(block.timestamp, _rate, _start_epoch_supply)


@external
def update_mining_parameters():
    assert block.timestamp >= self.start_epoch_time + RATE_REDUCTION_TIME
    self._update_mining_parameters()


@external
def start_epoch_time_write() -> uint256:
    '''
    @notice Get timestamp of the current mining epoch start while simultaneously updating mining parameters
    @return Timestamp of the epoch
    '''
    _start_epoch_time: uint256 = self.start_epoch_time
    if block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME:
        self._update_mining_parameters()
        return self.start_epoch_time
    else:
        return _start_epoch_time


@external
def future_epoch_time_write() -> uint256:
    '''
    @notice Get timestamp of the next mining epoch start while simultaneously updating mining parameters
    @return Timestamp of the next epoch
    '''
    _start_epoch_time: uint256 = self.start_epoch_time
    if block.timestamp >= _start_epoch_time + RATE_REDUCTION_TIME:
        self._update_mining_parameters()
        return self.start_epoch_time + RATE_REDUCTION_TIME
    else:
        return _start_epoch_time + RATE_REDUCTION_TIME


@internal
@view
def _available_supply() -> uint256:
    return self.start_epoch_supply + (block.timestamp - self.start_epoch_time) * self.rate


@external
@view
def available_supply() -> uint256:
    return self._available_supply()


@external
def transfer(_to : address, _value : uint256) -> bool:
    '''
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    '''
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    '''
    @dev Transfer tokens from one address to another.
    @param _from address The address which you want to send tokens from
    @param _to address The address which you want to transfer to
    @param _value uint256 the amount of tokens to be transferred
    '''
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance

    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True


@external
def approve(_spender : address, _value : uint256) -> bool:
    '''
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
        #Beware that changing an allowance with this method brings the risk that someone may use both the old
        #and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
        #race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
        #https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    '''
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
@view
def mintable_in_timeframe(start: uint256, end: uint256) -> uint256:
    """
    @notice How much supply is mintable from start timestamp till end timestamp
    @param start Start of the time interval (timestamp)
    @param end End of the time interval (timestamp)
    @return Tokens mintable from `start` till `end`
    """
    assert start <= end  # dev: start > end
    to_mint: uint256 = 0
    current_epoch_time: uint256 = self.start_epoch_time
    current_rate: uint256 = self.rate

    # Special case if end is in future (not yet minted) epoch
    if end > current_epoch_time + RATE_REDUCTION_TIME:
        current_epoch_time += RATE_REDUCTION_TIME
        current_rate = current_rate * RATE_DENOMINATOR / RATE_REDUCTION_COEFFICIENT

    assert end <= current_epoch_time + RATE_REDUCTION_TIME  # dev: too far in future

    for i in range(999):  # Curve will not work in 1000 years. Darn!
        if end >= current_epoch_time:
            current_end: uint256 = end
            if current_end > current_epoch_time + RATE_REDUCTION_TIME:
                current_end = current_epoch_time + RATE_REDUCTION_TIME

            current_start: uint256 = start
            if current_start >= current_epoch_time + RATE_REDUCTION_TIME:
                break  # We should never get here but what if...
            elif current_start < current_epoch_time:
                current_start = current_epoch_time

            to_mint += current_rate * (current_end - current_start)

            if start >= current_epoch_time:
                break

        current_epoch_time -= RATE_REDUCTION_TIME
        current_rate = current_rate * RATE_REDUCTION_COEFFICIENT / RATE_DENOMINATOR  # double-division with rounding made rate a bit less => good
        assert current_rate <= INITIAL_RATE  # This should never happen

    return to_mint


@external
def set_minter(_minter: address):
    assert msg.sender == self.admin
    assert self.minter == ZERO_ADDRESS
    self.minter = _minter
    log SetMinter(_minter)


@external
def set_admin(_admin: address):
    assert msg.sender == self.admin
    self.admin = _admin
    log SetAdmin(_admin)


@external
def mint(_to: address, _value: uint256) -> bool:
    '''
    @dev Mint an amount of the token and assigns it to an account.
        #This encapsulates the modification of balances such that the
        #proper events are emitted.
    @param _to The account that will receive the created tokens.
    @param _value The amount that will be created.
    '''
    assert msg.sender == self.minter
    assert _to != ZERO_ADDRESS

    if block.timestamp >= self.start_epoch_time + RATE_REDUCTION_TIME:
        self._update_mining_parameters()
    
    _total_supply: uint256 = self.totalSupply + _value
    assert _total_supply <= self._available_supply() # dev: exceeds allowable mint amount
    self.totalSupply = _total_supply

    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

    return True


@internal
def _burn(_to: address, _value: uint256):
    '''
    @dev Internal function that burns an amount of the token of a given
        #account.
    @param _to The account whose tokens will be burned.
    @param _value The amount that will be burned.
    '''
    assert _to != ZERO_ADDRESS
    self.totalSupply -= _value
    self.balanceOf[_to] -= _value
    log Transfer(_to, ZERO_ADDRESS, _value)


@external
def burn(_value: uint256):
    '''
    @dev Burn an amount of the token of msg.sender.
    @param _value The amount that will be burned.
    '''
    self._burn(msg.sender, _value)