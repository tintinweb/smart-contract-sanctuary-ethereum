# @version 0.3.3
# @License Copyright (c) Swap.Dance, 2022 - all rights reserved
# @Author Alexey K
# Swap.Dance SuperPool v.1.0

from vyper.interfaces import ERC20

interface ERC20D:
    def decimals() -> uint256: view

event Reward:
    token: indexed(address)
    receiver: indexed(address)
    amount: uint256

event LockPool:
    owner: indexed(address)
    lock_status: uint256

event NewOwner:
    old_owner: indexed(address)
    new_owner: indexed(address)


# Variables
lock: public(bool)
owner: public(address)
lock_time: public(uint256)
cycle_count: public(uint256)
tokens_count: public(uint256)
burn_percent: public(uint256)
total_balance: public(uint256)
balances: public(HashMap[address, uint256])
approved_tokens: public(HashMap[address, bool])
distribution_balances: public(HashMap[uint256, uint256])

# Constants
TIME: immutable(uint256) # 86400
SWD_TOKEN: immutable(address)
DENOMINATOR: constant(uint256) = 10000


@external
def __init__(swd: address, lock_time: uint256):
    self.lock = False
    self.owner = msg.sender
    self.burn_percent = 0
    SWD_TOKEN = swd
    TIME = lock_time


@external
def update_owner(new_owner: address) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    self.owner = new_owner
    log NewOwner(msg.sender, new_owner)
    return True


@external
def update_lock(lock: uint256) -> bool:
    # NOTE. Unlock(0) - Deposits
    # Lock(1) - Distribution
    assert lock <= 1, "1 Locked, 0 Unlocked"
    assert msg.sender == self.owner, "Deployer only"
    assert block.timestamp > self.lock_time, "min lock time"
    assert convert(lock, bool) != self.lock, "Already this phase"
    self.lock = convert(lock, bool)
    
    if lock == 0:
        self.total_balance = 0
        if self.burn_percent != 10000:
            self.burn_percent += 100 # +1%
    else:
        # save total token balance and increace cycle count
        SWD_BALANCE: uint256 = ERC20(SWD_TOKEN).balanceOf(self)
        assert SWD_BALANCE > 0, "Too early to lock, empty Super Balance"
        self.total_balance = SWD_BALANCE
        self.cycle_count += 1
        self.lock_time = TIME + block.timestamp

    log LockPool(msg.sender, lock)
    return True


@external
def add_approved_tokens(new_token: address) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    assert new_token != ZERO_ADDRESS, "ZERO ADDRESS"
    assert not self.approved_tokens[new_token]
    self.approved_tokens[new_token] = True
    self.tokens_count += 1
    return True


@external
def remove_approved_tokens(new_token: address) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    assert self.approved_tokens[new_token]
    self.approved_tokens[new_token] = False
    self.tokens_count -= 1
    return True


@external
@nonreentrant("Life is a game. Money is how we keep score.")
def deposit(amount: uint256, expiry: uint256) -> bool:
    assert amount > 0, "Zero deposit"
    assert not self.lock, "Pool locked"
    assert expiry >= block.timestamp, "Expiry Time"
    response_in: Bytes[32] = raw_call(
        SWD_TOKEN,
        _abi_encode(
            msg.sender,
            self,
            amount,
            method_id=method_id("transferFrom(address,address,uint256)")
        ),
        max_outsize=32,
    )
    if len(response_in) > 0:
        assert convert(response_in, bool), "SWD transfer failed!"
    # add Balance to var
    self.balances[msg.sender] += amount
    return True


@external
@nonreentrant("Life is a game. Money is how we keep score.")
def get_reward_and_withdraw(tokens_map: address[10], expiry: uint256):
    token_array: address[10] = empty(address[10]) # check addresses on doubles
    idx: uint256 = 0
    assert self.lock, "Pool unlocked"
    assert expiry >= block.timestamp, "Expiry Time"
    old_balance: uint256 = self.balances[msg.sender]
    assert old_balance > 0, "User balance zero"
    self.balances[msg.sender] = 0
    SWDB: uint256 = self.total_balance
    # NOTE. Every time when reward was released (lock/unlock period)
    # burn count increases +1%
    cycle: uint256 = self.cycle_count  
    burn: uint256 = self.burn_percent
    burn_fees: uint256 = empty(uint256)
    if burn > 0:
        burn_fees = (old_balance * burn) / DENOMINATOR
        swd_token_burn: Bytes[32] = raw_call(
            SWD_TOKEN,
            _abi_encode(
                burn_fees,
                method_id=method_id("burn(uint256)")
            ),
            max_outsize=32,
        )
        if len(swd_token_burn) > 0:
            assert convert(swd_token_burn, bool), "SWD burn failed!"

    balance_after_burn: uint256 = old_balance - burn_fees
    # if balance after burn is zero do nothing
    if balance_after_burn > 0: 
        swd_token_response: Bytes[32] = raw_call(
            SWD_TOKEN,
            _abi_encode(
                msg.sender,
                balance_after_burn,
                method_id=method_id("transfer(address,uint256)")
            ),
            max_outsize=32,
        )
        if len(swd_token_response) > 0:
            assert convert(swd_token_response, bool), "SWD transfer failed!"

    for i in range(10):
        token: address = tokens_map[i]
        assert self.approved_tokens[token], "This token not approved"
        # check doubles
        idy: uint256 = 0
        for k in range(10):
            # get array 
            temp_addr: address = token_array[idy]
            if temp_addr == ZERO_ADDRESS:
                break
            assert token != temp_addr, "You can't withdraw token twice"
            idy += 1
        # add token to array after check
        token_array[idx] = token
        idx += 1

        # NOTE. Use cycle count for each token address
        # to avoid dynamic balance after withdraw
        # user who first withdraw token
        # pay more gas to write token balance to db

        # get cycle id for current token
        token_cycle_id: uint256 = bitwise_xor(cycle, convert(token, uint256))
        # read token balance
        token_balance: uint256 = self.distribution_balances[token_cycle_id]
        if token_balance == 0:
            token_balance = ERC20(token).balanceOf(self)
            # 10 % LP must stay in the super pool
            # to guarantee steady growth of LP token
            token_balance = token_balance - (token_balance / 10)
            self.distribution_balances[token_cycle_id] = token_balance

        user_reward: uint256 = old_balance * token_balance / SWDB
        # transfer reward
        reward_out_response: Bytes[32] = raw_call(
            token,
            _abi_encode(
                msg.sender,
                user_reward,
                method_id=method_id("transfer(address,uint256)")
            ),
            max_outsize=32,
        )
        if len(reward_out_response) > 0:
            assert convert(reward_out_response, bool), "Reward transfer failed!"

        #log here
        log Reward(token, msg.sender, user_reward)


@external
@nonreentrant("Life is a game. Money is how we keep score.")
def withdraw_without_reward(expiry: uint256):
    assert expiry >= block.timestamp, "Expiry Time"
    assert not self.lock, "Pool locked"
    old_balance: uint256 = self.balances[msg.sender]
    assert old_balance > 0, "Zero balance"
    self.balances[msg.sender] = 0
    swd_response: Bytes[32] = raw_call(
        SWD_TOKEN,
        _abi_encode(
            msg.sender,
            old_balance,
            method_id=method_id("transfer(address,uint256)")
        ),
        max_outsize=32,
    )
    if len(swd_response) > 0:
        assert convert(swd_response, bool), "SWD transfer failed!"


@external
def drop_distribution_balances(tokens_map: address[10]):
    # NOTE. Before new cycle check off-chain distribution_balances
    # if any token balance on a new phase will have non zero balance
    # owner must drop balance(s) through this function
    assert msg.sender == self.owner, "Deployer only"
    token: address = empty(address)
    token_balance: uint256 = empty(uint256)
    token_cycle_id: uint256 = empty(uint256)
    new_cycle: uint256 = self.cycle_count + 1
    for i in range(10):
        token = tokens_map[i]
        if token != ZERO_ADDRESS:
            token_cycle_id = bitwise_xor(new_cycle, convert(token, uint256))
            token_balance = self.distribution_balances[token_cycle_id]
            assert token_balance > 0, "can't reset 0 balance"
            self.distribution_balances[token_cycle_id] = 0
        else:
            break


@external
@view
def check_estimate_reward(
    amount: uint256, 
    token_to_check: address
) -> uint256:

    SWDB: uint256 = empty(uint256)
    user_reward: uint256 = empty(uint256)
    token_balance: uint256 = empty(uint256)

    if self.lock == True:
        # Distribution. Use msg.sender balance
        SWDB = self.total_balance
        cycle: uint256 = self.cycle_count
        user_balance: uint256 = self.balances[msg.sender]
        token_cycle_id: uint256 = bitwise_xor(cycle, convert(token_to_check, uint256))
        # read token balance
        token_balance = self.distribution_balances[token_cycle_id]
        if token_balance == 0:
            token_balance = ERC20(token_to_check).balanceOf(self)
            token_balance = token_balance - (token_balance / 10)

        user_reward = user_balance * token_balance / SWDB
        
    else:
        # LP-Forming cycle, use _amount to get estimate reward
        SWDB = ERC20(SWD_TOKEN).balanceOf(self)
        token_balance = ERC20(token_to_check).balanceOf(self)
        token_balance = token_balance - (token_balance / 10)

        if SWDB > 0:
            user_reward = amount * token_balance / (SWDB + amount)
        else:
            user_reward = token_balance - (token_balance / 10)
    
    return user_reward