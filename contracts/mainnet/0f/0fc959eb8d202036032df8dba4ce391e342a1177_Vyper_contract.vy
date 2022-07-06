# @version 0.3.1
"""
@title Gas Escrow
@author Versailles heroes
@license MIT
@notice Gas have a weight depending on time.
@dev Gas weight decays linearly over time. Burn time must be 4 years.
"""

struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block
# We cannot really do block numbers per se b/c slope is per time, not per block
# and per block could be fairly bad b/c Ethereum changes blocktimes.
# What we can do is to extrapolate ***At functions

struct BurnedBalance:
    amount: int128
    end: uint256


interface ERC20:
    def decimals() -> uint256: view
    def name() -> String[64]: view
    def symbol() -> String[32]: view
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def transferFrom(spender: address, to: address, amount: uint256) -> bool: nonpayable


# Interface for checking whether address belongs to a whitelisted
# type of a smart wallet.
# When new types are added - the whole contract is changed
# The check() method is modifying to be able to use caching
# for individual wallet addresses
interface SmartWalletChecker:
    def check(addr: address) -> bool: nonpayable

CREATE_BURN_TYPE: constant(int128) = 1
INCREASE_BURN_AMOUNT: constant(int128) = 2


event CommitOwnership:
    admin: address

event ApplyOwnership:
    admin: address

event Deposit:
    provider: indexed(address)
    value: uint256
    burntime: indexed(uint256)
    type: int128
    ts: uint256

event ClearGas:
    provider: indexed(address)
    value: uint256
    ts: uint256

event Supply:
    prevSupply: uint256
    supply: uint256


WEEK: constant(uint256) = 7 * 86400  # all future times are rounded by week
MAXTIME: constant(uint256) = 4 * 365 * 86400  # 4 years
MULTIPLIER: constant(uint256) = 10 ** 18

token: public(address)
supply: public(uint256)

burned: public(HashMap[address, BurnedBalance])

epoch: public(uint256)
point_history: public(Point[100000000000000000000000000000])  # epoch -> unsigned point
user_point_history: public(HashMap[address, Point[1000000000]])  # user -> Point[user_epoch]
user_point_epoch: public(HashMap[address, uint256])
slope_changes: public(HashMap[uint256, int128])  # time -> signed slope change

name: public(String[64])
symbol: public(String[32])
version: public(String[32])
decimals: public(uint256)

# Checker for whitelisted (smart contract) wallets which are allowed to deposit
# The goal is to prevent tokenizing the escrow
future_smart_wallet_checker: public(address)
smart_wallet_checker: public(address)

admin: public(address)  # Can and will be a smart contract
future_admin: public(address)


@external
def __init__():
    """
    @notice Contract constructor
    """
    self.admin = msg.sender


@external
@nonreentrant('lock')
def initialize(_admin: address, _token: address, _name: String[64], _symbol: String[32]) -> bool:
    """
    @notice Contract constructor, called by GuildController
    @param _admin Admin address
    @param _token Token address
    @param _name Token name
    @param _symbol Token symbol
    """
    assert self.admin == ZERO_ADDRESS # can only initialize once
    assert _admin != ZERO_ADDRESS
    assert _token != ZERO_ADDRESS

    self.admin = _admin
    self.token = _token
    self.point_history[0].blk = block.number
    self.point_history[0].ts = block.timestamp
    
    _decimals: uint256 = ERC20(self.token).decimals()
    assert _decimals <= 255
    self.decimals = _decimals

    self.name = _name
    self.symbol = _symbol

    return True


@external
def commit_transfer_ownership(addr: address):
    """
    @notice Transfer ownership of GasEscrow contract to `addr`
    @param addr Address to have ownership transferred to
    """
    assert msg.sender == self.admin  # dev: admin only
    self.future_admin = addr
    log CommitOwnership(addr)


@external
def apply_transfer_ownership():
    """
    @notice Apply ownership transfer
    """
    assert msg.sender == self.admin  # dev: admin only
    _admin: address = self.future_admin
    assert _admin != ZERO_ADDRESS  # dev: admin not set
    self.admin = _admin
    log ApplyOwnership(_admin)


@external
def commit_smart_wallet_checker(addr: address):
    """
    @notice Set an external contract to check for approved smart contract wallets
    @param addr Address of Smart contract checker
    """
    assert msg.sender == self.admin
    self.future_smart_wallet_checker = addr


@external
def apply_smart_wallet_checker():
    """
    @notice Apply setting external contract to check approved smart contract wallets
    """
    assert msg.sender == self.admin
    self.smart_wallet_checker = self.future_smart_wallet_checker


@internal
def assert_not_contract(addr: address):
    """
    @notice Check if the call is from a whitelisted smart contract, revert if not
    @param addr Address to be checked
    """
    if addr != tx.origin:
        checker: address = self.smart_wallet_checker
        if checker != ZERO_ADDRESS:
            if SmartWalletChecker(checker).check(addr):
                return
        raise "Smart contract depositors not allowed"


@external
@view
def get_last_user_slope(addr: address) -> int128:
    """
    @notice Get the most recently recorded rate of gas power decrease for `addr`
    @param addr Address of the user wallet
    @return Value of the slope
    """
    uepoch: uint256 = self.user_point_epoch[addr]
    return self.user_point_history[addr][uepoch].slope


@external
@view
def user_point_history__ts(_addr: address, _idx: uint256) -> uint256:
    """
    @notice Get the timestamp for checkpoint `_idx` for `_addr`
    @param _addr User wallet address
    @param _idx User epoch number
    @return Epoch time of the checkpoint
    """
    return self.user_point_history[_addr][_idx].ts


@external
@view
def burned__end(_addr: address) -> uint256:
    """
    @notice Get timestamp when `_addr`'s burn finishes
    @param _addr User wallet
    @return Epoch time of the burn end
    """
    return self.burned[_addr].end


@internal
def _checkpoint(addr: address, old_burned: BurnedBalance, new_burned: BurnedBalance):
    """
    @notice Record global and per-user data to checkpoint
    @param addr User's wallet address. No user checkpoint if 0x0
    @param old_burned Pevious burned amount / end burn time for the user
    @param new_burned New burned amount / end burn time for the user
    """
    u_old: Point = empty(Point)
    u_new: Point = empty(Point)
    old_dslope: int128 = 0
    new_dslope: int128 = 0
    _epoch: uint256 = self.epoch

    if addr != ZERO_ADDRESS:
        # Calculate slopes and biases
        # Kept at zero when they have to
        if old_burned.end > block.timestamp and old_burned.amount > 0:
            u_old.slope = old_burned.amount / MAXTIME
            u_old.bias = u_old.slope * convert(old_burned.end - block.timestamp, int128)
        if new_burned.end > block.timestamp and new_burned.amount > 0:
            u_new.slope = new_burned.amount / MAXTIME
            u_new.bias = u_new.slope * convert(new_burned.end - block.timestamp, int128)

        # Read values of scheduled changes in the slope
        # old_burned.end can be in the past and in the future
        # new_burned.end can ONLY by in the FUTURE unless everything expired: than zeros
        old_dslope = self.slope_changes[old_burned.end]
        if new_burned.end != 0:
            if new_burned.end == old_burned.end:
                new_dslope = old_dslope
            else:
                new_dslope = self.slope_changes[new_burned.end]

    last_point: Point = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number})
    if _epoch > 0:
        last_point = self.point_history[_epoch]
    last_checkpoint: uint256 = last_point.ts
    # initial_last_point is used for extrapolation to calculate block number
    # (approximately, for *At methods) and save them
    # as we cannot figure that out exactly from inside the contract
    initial_last_point: Point = last_point
    block_slope: uint256 = 0  # dblock/dt
    if block.timestamp > last_point.ts:
        block_slope = MULTIPLIER * (block.number - last_point.blk) / (block.timestamp - last_point.ts)
    # If last point is already recorded in this block, slope=0
    # But that's ok b/c we know the block in such case

    # Go over weeks to fill history and calculate what the current point is
    t_i: uint256 = (last_checkpoint / WEEK) * WEEK
    for i in range(255):
        # Hopefully it won't happen that this won't get used in 5 years!
        # If it does, users will be able to clear gas but gas will be broken
        t_i += WEEK
        d_slope: int128 = 0
        if t_i > block.timestamp:
            t_i = block.timestamp
        else:
            d_slope = self.slope_changes[t_i]
        last_point.bias -= last_point.slope * convert(t_i - last_checkpoint, int128)
        last_point.slope += d_slope
        if last_point.bias < 0:  # This can happen
            last_point.bias = 0
        if last_point.slope < 0:  # This cannot happen - just in case
            last_point.slope = 0
        last_checkpoint = t_i
        last_point.ts = t_i
        last_point.blk = initial_last_point.blk + block_slope * (t_i - initial_last_point.ts) / MULTIPLIER
        _epoch += 1
        if t_i == block.timestamp:
            last_point.blk = block.number
            break
        else:
            self.point_history[_epoch] = last_point

    self.epoch = _epoch
    # Now point_history is filled until t=now

    if addr != ZERO_ADDRESS:
        # If last point was in this block, the slope change has been applied already
        # But in such case we have 0 slope(s)
        last_point.slope += (u_new.slope - u_old.slope)
        last_point.bias += (u_new.bias - u_old.bias)
        if last_point.slope < 0:
            last_point.slope = 0
        if last_point.bias < 0:
            last_point.bias = 0

    # Record the changed point into history
    self.point_history[_epoch] = last_point

    if addr != ZERO_ADDRESS:
        # Schedule the slope changes (slope is going down)
        # We subtract new_user_slope from [new_burned.end]
        # and add old_user_slope to [old_burned.end]
        if old_burned.end > block.timestamp:
            # old_dslope was <something> - u_old.slope, so we cancel that
            old_dslope += u_old.slope
            if new_burned.end == old_burned.end:
                old_dslope -= u_new.slope  # It was a new deposit, not extension
            self.slope_changes[old_burned.end] = old_dslope

        if new_burned.end > block.timestamp:
            if new_burned.end > old_burned.end:
                new_dslope -= u_new.slope  # old slope disappeared at this point
                self.slope_changes[new_burned.end] = new_dslope
            # else: we recorded it already in old_dslope

        # Now handle user history
        user_epoch: uint256 = self.user_point_epoch[addr] + 1

        self.user_point_epoch[addr] = user_epoch
        u_new.ts = block.timestamp
        u_new.blk = block.number
        self.user_point_history[addr][user_epoch] = u_new


@internal
def _deposit_for(_addr: address, _value: uint256, end_time: uint256, burned_balance: BurnedBalance, type: int128):
    """
    @notice Deposit and burn tokens for a user
    @param _addr User's wallet address
    @param _value Amount to deposit
    @param end_time New time when to burn the tokens, or 0 if unchanged
    @param burned_balance Previous burned amount / timestamp
    """
    _burned: BurnedBalance = burned_balance
    supply_before: uint256 = self.supply

    self.supply = supply_before + _value
    old_burned: BurnedBalance = _burned
    # Adding to existing burn, or if a burn is expired - creating a new one
    _burned.amount += convert(_value, int128)
    if end_time != 0:
        _burned.end = end_time
    self.burned[_addr] = _burned

    # Possibilities:
    # Both old_burned.end could be current or expired (>/< block.timestamp)
    # value == 0 (extend burn) or value > 0 (add to burn)
    # _burned.end > block.timestamp (always)
    self._checkpoint(_addr, old_burned, _burned)

    if _value != 0:
        assert ERC20(self.token).transferFrom(_addr, ZERO_ADDRESS, _value) # burn the tokens

    log Deposit(_addr, _value, _burned.end, type, block.timestamp)
    log Supply(supply_before, supply_before + _value)


@external
def checkpoint():
    """
    @notice Record global data to checkpoint
    """
    self._checkpoint(ZERO_ADDRESS, empty(BurnedBalance), empty(BurnedBalance))


@external
@nonreentrant('lock')
def create_gas(_value: uint256):
    """
    @notice Deposit `_value` tokens for `msg.sender` and burn for 4yrs
    @param _value Amount to deposit
    """
    self.assert_not_contract(msg.sender)
    end_time: uint256 = ((block.timestamp + MAXTIME) / WEEK) * WEEK # Burntime is rounded down to weeks
    _burned: BurnedBalance = self.burned[msg.sender]

    assert _value > 0  # dev: need non-zero value
    assert _burned.amount == 0, "old gas burn not finished"
    assert end_time > block.timestamp, "Can only burn until time in the future"

    self._deposit_for(msg.sender, _value, end_time, _burned, CREATE_BURN_TYPE)


@external
@nonreentrant('lock')
def increase_amount(_value: uint256):
    """
    @notice Deposit `_value` additional tokens for `msg.sender`
            without modifying the burn time
    @param _value Amount of tokens to deposit and add to the burn
    """
    self.assert_not_contract(msg.sender)
    _burned: BurnedBalance = self.burned[msg.sender]

    assert _value > 0  # dev: need non-zero value
    assert _burned.amount > 0, "No existing burn found"
    assert _burned.end > block.timestamp, "Cannot add to expired burn"

    self._deposit_for(msg.sender, _value, 0, _burned, INCREASE_BURN_AMOUNT)

@external
@nonreentrant('lock')
def clear_gas():
    """
    @notice clear all tokens for `msg.sender`
    @dev Only possible if the burn has expired
    """
    _burned: BurnedBalance = self.burned[msg.sender]
    assert block.timestamp >= _burned.end, "The burn didn't expire"
    value: uint256 = convert(_burned.amount, uint256)

    old_burned: BurnedBalance = _burned
    _burned.end = 0
    _burned.amount = 0
    self.burned[msg.sender] = _burned
    supply_before: uint256 = self.supply
    self.supply = supply_before - value

    # old_burned can have either expired <= timestamp or zero end
    # _burned has only 0 end
    # Both can have >= 0 amount
    self._checkpoint(msg.sender, old_burned, _burned)

    log ClearGas(msg.sender, value, block.timestamp)
    log Supply(supply_before, supply_before - value)


# The following ERC20/minime-compatible methods are not real balanceOf and supply!
# They measure the weights for the purpose of gas, so they don't represent
# real coins.

@internal
@view
def find_block_epoch(_block: uint256, max_epoch: uint256) -> uint256:
    """
    @notice Binary search to estimate timestamp for block number
    @param _block Block to find
    @param max_epoch Don't go beyond this epoch
    @return Approximate timestamp for block
    """
    # Binary search
    _min: uint256 = 0
    _max: uint256 = max_epoch
    for i in range(128):  # Will be always enough for 128-bit numbers
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 1) / 2
        if self.point_history[_mid].blk <= _block:
            _min = _mid
        else:
            _max = _mid - 1
    return _min


@external
@view
def balanceOf(addr: address, _t: uint256 = block.timestamp) -> uint256:
    """
    @notice Get the current GAS for `msg.sender`
    @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    @param addr User wallet address
    @param _t Epoch time to return gas power at
    @return User gas power
    """
    _epoch: uint256 = self.user_point_epoch[addr]
    if _epoch == 0:
        return 0
    else:
        last_point: Point = self.user_point_history[addr][_epoch]
        last_point.bias -= last_point.slope * convert(_t - last_point.ts, int128)
        if last_point.bias < 0:
            last_point.bias = 0
        return convert(last_point.bias, uint256)


@external
@view
def balanceOfAt(addr: address, _block: uint256) -> uint256:
    """
    @notice Measure gas power of `addr` at block height `_block`
    @dev Adheres to MiniMe `balanceOfAt` interface: https://github.com/Giveth/minime
    @param addr User's wallet address
    @param _block Block to calculate the gas power at
    @return gas power
    """
    # Copying and pasting totalSupply code because Vyper cannot pass by
    # reference yet
    assert _block <= block.number

    # Binary search
    _min: uint256 = 0
    _max: uint256 = self.user_point_epoch[addr]
    for i in range(128):  # Will be always enough for 128-bit numbers
        if _min >= _max:
            break
        _mid: uint256 = (_min + _max + 1) / 2
        if self.user_point_history[addr][_mid].blk <= _block:
            _min = _mid
        else:
            _max = _mid - 1

    upoint: Point = self.user_point_history[addr][_min]

    max_epoch: uint256 = self.epoch
    _epoch: uint256 = self.find_block_epoch(_block, max_epoch)
    point_0: Point = self.point_history[_epoch]
    d_block: uint256 = 0
    d_t: uint256 = 0
    if _epoch < max_epoch:
        point_1: Point = self.point_history[_epoch + 1]
        d_block = point_1.blk - point_0.blk
        d_t = point_1.ts - point_0.ts
    else:
        d_block = block.number - point_0.blk
        d_t = block.timestamp - point_0.ts
    block_time: uint256 = point_0.ts
    if d_block != 0:
        block_time += d_t * (_block - point_0.blk) / d_block

    upoint.bias -= upoint.slope * convert(block_time - upoint.ts, int128)
    if upoint.bias >= 0:
        return convert(upoint.bias, uint256)
    else:
        return 0


@internal
@view
def supply_at(point: Point, t: uint256) -> uint256:
    """
    @notice Calculate total gas power at some point in the past
    @param point The point (bias/slope) to start search from
    @param t Time to calculate the total gas power at
    @return Total gas power at that time
    """
    last_point: Point = point
    t_i: uint256 = (last_point.ts / WEEK) * WEEK
    for i in range(255):
        t_i += WEEK
        d_slope: int128 = 0
        if t_i > t:
            t_i = t
        else:
            d_slope = self.slope_changes[t_i]
        last_point.bias -= last_point.slope * convert(t_i - last_point.ts, int128)
        if t_i == t:
            break
        last_point.slope += d_slope
        last_point.ts = t_i

    if last_point.bias < 0:
        last_point.bias = 0
    return convert(last_point.bias, uint256)


@external
@view
def totalSupply(t: uint256 = block.timestamp) -> uint256:
    """
    @notice Calculate total gas power
    @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
    @return Total gas power
    """
    _epoch: uint256 = self.epoch
    last_point: Point = self.point_history[_epoch]
    return self.supply_at(last_point, t)


@external
@view
def totalSupplyAt(_block: uint256) -> uint256:
    """
    @notice Calculate total gas power at some point in the past
    @param _block Block to calculate the total gas power at
    @return Total gas power at `_block`
    """
    assert _block <= block.number
    _epoch: uint256 = self.epoch
    target_epoch: uint256 = self.find_block_epoch(_block, _epoch)

    point: Point = self.point_history[target_epoch]
    dt: uint256 = 0
    if target_epoch < _epoch:
        point_next: Point = self.point_history[target_epoch + 1]
        if point.blk != point_next.blk:
            dt = (_block - point.blk) * (point_next.ts - point.ts) / (point_next.blk - point.blk)
    else:
        if point.blk != block.number:
            dt = (_block - point.blk) * (block.timestamp - point.ts) / (block.number - point.blk)
    # Now dt contains info on how far are we beyond point

    return self.supply_at(point, point.ts + dt)