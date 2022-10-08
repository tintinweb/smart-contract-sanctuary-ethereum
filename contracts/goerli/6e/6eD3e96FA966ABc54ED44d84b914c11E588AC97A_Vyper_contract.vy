# @version 0.3.1
"""
@title Reward Vesting Escrow
@author Versailles heroes
@license MIT
@notice Reward Vesting 70% `ERC20VRH` tokens between checkpoints
"""

struct VestingInfo:
    amount: uint256
    start: uint256
    end: uint256
    slope: uint256
    claimed: uint256

event Vesting:
    recipient: indexed(address)
    start: uint256
    end: uint256
    slope: uint256
    amount: uint256

event Claim:
    recipient: indexed(address)
    claimed: uint256
    start: uint256
    end: uint256

event ClaimInfo:
    recipient: indexed(address)
    epoch: uint256
    remain_amount: uint256
    claimed_amount: uint256
    claimable: uint256
    amt: uint256
    start: uint256

event SetMinter:
    minter: address

event SetAdmin:
    admin: address

admin: public(address)
minter: public(address)
token: public(address)
balanceOf: public(HashMap[address, uint256])
total_claimed: public(HashMap[address, uint256])
user_vesting_epoch: public(HashMap[address, uint256])
user_vesting_history: public(HashMap[address, VestingInfo[1000000000]]) # user -> Vesting[user_epoch]

PERIOD: constant(uint256) = 2419200 # 86400 * 7 * 4 (28 days)
VESTING_PERIOD: constant(uint256) = PERIOD * 6 # 168 days
VESTING_RATIO: constant(uint256) = 70

@external
def __init__():
    self.admin = msg.sender

@external
@nonreentrant('lock')
def vesting(_recipient: address, _amount: uint256) -> uint256:
    assert msg.sender == self.minter

    vested_amount: uint256 = _amount * VESTING_RATIO / 100
    self.balanceOf[_recipient] += vested_amount
    start_time: uint256 = ( (block.timestamp / PERIOD) + 1 ) * PERIOD
    user_epoch: uint256 = self.user_vesting_epoch[_recipient]
    user_vesting: VestingInfo = empty(VestingInfo)

    if user_epoch > 0: # user has existing vesting
        user_vesting = self.user_vesting_history[_recipient][user_epoch]

        if user_vesting.start == start_time: # if start time is the same, accumulate the vesting amt
            user_vesting.amount += vested_amount
            user_vesting.slope = user_vesting.amount / VESTING_PERIOD
        else:
            user_epoch += 1
            user_vesting = VestingInfo({
                amount: vested_amount,
                start: start_time,
                end: start_time + VESTING_PERIOD,
                slope: vested_amount / VESTING_PERIOD,
                claimed: 0
            })
            self.user_vesting_epoch[_recipient] = user_epoch
    else: # new vesting
        user_epoch = 1
        user_vesting.amount = vested_amount
        user_vesting.start = start_time
        user_vesting.end = start_time + VESTING_PERIOD
        user_vesting.slope = vested_amount / VESTING_PERIOD
        
        self.user_vesting_epoch[_recipient] = user_epoch

    self.user_vesting_history[_recipient][user_epoch] = user_vesting
    
    log Vesting(_recipient, user_vesting.start, user_vesting.end, user_vesting.slope, user_vesting.amount)

    return vested_amount

@internal
def _claimable_tokens(addr: address, _update: bool) -> uint256:
    user_epoch: uint256 = self.user_vesting_epoch[addr]
    user_vesting: VestingInfo = empty(VestingInfo)
    claimable: uint256 = 0

    epoch: uint256 = user_epoch
    if epoch > 0:
        for i in range(1, 255):
            user_vesting = self.user_vesting_history[addr][epoch]

            if user_vesting.amount > 0: # vesting still in progress
                if user_vesting.start < block.timestamp:
                    amt: uint256 = user_vesting.amount

                    if user_vesting.end > block.timestamp: # if vesting has not completed yet
                        amt = ( user_vesting.slope * (block.timestamp - user_vesting.start) ) - user_vesting.claimed
                    
                    # update the remaining vested amt
                    user_vesting.amount -= amt
                    user_vesting.claimed += amt

                    # accumulate total claimable amt
                    claimable += amt
                    log ClaimInfo(addr, epoch, user_vesting.amount, user_vesting.claimed, claimable, amt, user_vesting.start)

                    if _update:
                        # update the vesting record
                        self.user_vesting_history[addr][epoch] = user_vesting
            else:
                break # amount is zero so break the search

            epoch -= 1

            if epoch == 0:
                break
    
    return claimable


@external
@view
def get_claimable_tokens(addr: address) -> uint256:
    user_epoch: uint256 = self.user_vesting_epoch[addr]
    user_vesting: VestingInfo = empty(VestingInfo)
    claimable: uint256 = 0

    epoch: uint256 = user_epoch
    if epoch > 0:
        for i in range(1, 255):
            user_vesting = self.user_vesting_history[addr][epoch]

            if user_vesting.amount > 0: # vesting still in progress
                if user_vesting.start < block.timestamp:
                    amt: uint256 = user_vesting.amount

                    if user_vesting.end > block.timestamp: # if vesting has not completed yet
                        amt = ( user_vesting.slope * (block.timestamp - user_vesting.start) ) - user_vesting.claimed
                    
                    # update the remaining vested amt
                    user_vesting.amount -= amt
                    user_vesting.claimed += amt

                    # accumulate total claimable amt
                    claimable += amt

            else:
                break # amount is zero so break the search

            epoch -= 1

            if epoch == 0:
                break
    
    return claimable

@external
# how to change @view?
def claimable_tokens(addr: address) -> uint256:
    claimable: uint256 = self._claimable_tokens(addr, False)

    return claimable

@external
@nonreentrant('lock')
def claim(addr: address) -> uint256:
    """
    @notice Claim tokens which have vested
    """
    assert msg.sender == self.minter
    claimable: uint256 = self._claimable_tokens(addr, True)

    self.balanceOf[addr] -= claimable
    self.total_claimed[addr] += claimable

    # log Claim(addr, claimable, start, block.timestamp)
    return claimable

@external
def set_minter(_minter: address):
    assert msg.sender == self.admin
    assert self.minter == ZERO_ADDRESS # TODO: to be reviewed, whether minter is allowed to be changed
    self.minter = _minter
    log SetMinter(_minter)

@external
def set_admin(_admin: address):
    assert msg.sender == self.admin
    self.admin = _admin
    log SetAdmin(_admin)