# @version 0.3.3
# @License Copyright (c) Swap.Dance, 2022 - all rights reserved
# @Author Alexey K
# Proof of Trade Swap.Dance Station Template

from vyper.interfaces import ERC20

interface ERC20D:
    def symbol() -> String[32]: view
    def deployer() -> address: view

event RegisterStaker:
    staker: indexed(address)
    pool_token_amounts_in: uint256

event UnregisterStaker:
    staker: indexed(address)
    pool_token_amounts_out: uint256

event RewardPayout:
    staker: indexed(address)
    reward_amounts_out: uint256

event LockStation:
    owner: indexed(address)
    lock_status: uint256

event NewOwner:
    old_owner: indexed(address)
    new_owner: indexed(address)

# PoT Variables
lock: public(bool)
owner: public(address)
pool_token: public(address)
SWD_TOKEN: immutable(address)
symbol: public(String[32])

# PoT Settings
max_id_now: public(uint256)
total_withdrawn_reward: public(uint256)
total_deposited_tokens: public(uint256)
balances: public(HashMap[address, uint256])
reward_sum: public(HashMap[uint256, uint256])
reward_rate: public(HashMap[uint256, uint256])
user_position: public(HashMap[address, uint256])
reward_position: public(HashMap[uint256, uint256])


@external
def __init__(swd: address):
    # init proof of trade params
    self.lock = True
    self.owner = msg.sender
    SWD_TOKEN = swd


@external
def setup(pool_token: address) -> bool:
    assert self.owner == ZERO_ADDRESS, "Zero Address"
    assert msg.sender == ERC20D(SWD_TOKEN).deployer()
    # Station details
    self.lock = False
    self.owner = msg.sender
    self.max_id_now = 0
    self.pool_token = pool_token
    self.symbol = ERC20D(pool_token).symbol()
    return True


@internal
@view
def get_round_reward(sender: address) -> uint256:
    max_id: uint256 = self.max_id_now
    user_balance: uint256 = self.balances[sender]
    position: uint256 = self.user_position[sender]
    actual_reward_balance: uint256 = ERC20(SWD_TOKEN).balanceOf(self)
    reward_available: uint256 = ((actual_reward_balance + self.total_withdrawn_reward) 
        - self.reward_position[max_id])
    reward_rate: uint256 = ((10 ** 18) * reward_available) / self.total_deposited_tokens
    return (reward_rate * user_balance)


@external
@nonreentrant("Money, like vodka, turns a person into an eccentric.")
def stake(amount_in: uint256, expiry: uint256):
    assert not self.lock, "PoT locked"
    assert amount_in > 0, "Deposit Zero"
    assert expiry >= block.timestamp, "Expiry Time"
    old_balance: uint256 = self.balances[msg.sender]
    response_in: Bytes[32] = raw_call(
        self.pool_token,
        _abi_encode(
            msg.sender,
            self,
            amount_in,
            method_id=method_id("transferFrom(address,address,uint256)")
        ),
        max_outsize=32,
    )
    if len(response_in) > 0:
        assert convert(response_in, bool), "Transfer pool token failed!"

    if old_balance != 0:
        old_max_id: uint256 = self.max_id_now
        old_user_id: uint256 = self.user_position[msg.sender]
        round_reward: uint256 = self.get_round_reward(msg.sender)

        amount_rewards_out: uint256 = ((
            (self.reward_sum[old_max_id] - self.reward_sum[old_user_id])
            * old_balance) + round_reward) / (10 ** 18)

        self.user_position[msg.sender] = old_max_id
        if amount_rewards_out > 0:
            response_out_reward: Bytes[32] = raw_call(
                SWD_TOKEN,
                _abi_encode(
                    msg.sender,
                    amount_rewards_out,
                    method_id=method_id("transfer(address,uint256)")
                ),
                max_outsize=32,
            )
            if len(response_out_reward) > 0:
                assert convert(response_out_reward, bool), "Transfer SWD reward failed!"

            self.total_withdrawn_reward += amount_rewards_out
            log RewardPayout(msg.sender, amount_rewards_out)

    self.max_id_now += 1
    max_id: uint256 = self.max_id_now
    self.user_position[msg.sender] = max_id
    
    reward_rate_now: uint256 = empty(uint256)
    total_deposited: uint256 = self.total_deposited_tokens
    total_withdrawn: uint256 = self.total_withdrawn_reward
    actual_reward_balance: uint256 = ERC20(SWD_TOKEN).balanceOf(self)

    if total_deposited == 0:
        reward_rate_now = 0
    else:
        reward_rate_now = ((10 ** 18) * ((
            actual_reward_balance + total_withdrawn)
            - self.reward_position[max_id - 1])) / total_deposited

    self.reward_rate[max_id] = reward_rate_now
    self.reward_sum[max_id] = self.reward_sum[max_id - 1] + reward_rate_now
    self.reward_position[max_id] = (actual_reward_balance + total_withdrawn)
    self.total_deposited_tokens += amount_in
    self.balances[msg.sender] += amount_in
    log RegisterStaker(msg.sender, amount_in)


@external
@nonreentrant("Money, like vodka, turns a person into an eccentric.")
def get_reward(expiry: uint256):
    # NOTE. Without round reward. 
    # Unstake to get all. Or wait.
    assert expiry >= block.timestamp, "Expiry Time"
    max_id: uint256 = self.max_id_now
    amount_out: uint256 = self.balances[msg.sender]
    user_id: uint256 = self.user_position[msg.sender]
    
    amount_rewards_out: uint256 = ((
        self.reward_sum[max_id] 
        - self.reward_sum[user_id]) 
        * amount_out) / (10 ** 18) 
        
    assert amount_rewards_out > 0, "Reward is zero"
    self.user_position[msg.sender] = max_id
    if amount_rewards_out > 0:
        reward_out_response: Bytes[32] = raw_call(
            SWD_TOKEN,
            _abi_encode(
                msg.sender,
                amount_rewards_out,
                method_id=method_id("transfer(address,uint256)")
            ),
            max_outsize=32,
        )
        if len(reward_out_response) > 0:
            assert convert(reward_out_response, bool), "Transfer SWD reward failed!"

        self.total_withdrawn_reward += amount_rewards_out
        log RewardPayout(msg.sender, amount_rewards_out)


@external
@view
def user_round_reward(sender: address) -> uint256:
    if self.balances[sender] != 0:
        return (self.get_round_reward(sender) / (10 ** 18))
    else:
        return 0


@external
@view
def actual_reward(sender: address) -> uint256:
    if self.balances[sender] != 0:
        actual_reward_balance: uint256 = ERC20(SWD_TOKEN).balanceOf(self)
        max_id: uint256 = self.max_id_now
        amount_out: uint256 = self.balances[sender]
        user_id: uint256 = self.user_position[sender]
        round_reward: uint256 = self.get_round_reward(sender)
        amount_rewards_out: uint256 = (((
            self.reward_sum[max_id] 
            - self.reward_sum[user_id]) 
            * amount_out) + round_reward) / (10 ** 18)
        return amount_rewards_out
    else: 
        return 0


@external
@nonreentrant("Money, like vodka, turns a person into an eccentric.")
def unstake(expiry: uint256):
    assert expiry >= block.timestamp, "Expiry Time"
    assert self.balances[msg.sender] != 0, "Zero balance"
    max_id: uint256 = self.max_id_now
    amount_out: uint256 = self.balances[msg.sender]
    old_balance: uint256 = self.balances[msg.sender]
    user_id: uint256 = self.user_position[msg.sender]
    round_reward: uint256 = self.get_round_reward(msg.sender)
        
    reward_rate_now: uint256 = empty(uint256)
    total_deposited: uint256 = self.total_deposited_tokens
    total_withdrawn: uint256 = self.total_withdrawn_reward
    actual_reward_balance: uint256 = ERC20(SWD_TOKEN).balanceOf(self)

    if total_deposited == 0:
        reward_rate_now = 0
    else:
        reward_rate_now = ((10 ** 18) * ((
            actual_reward_balance + total_withdrawn)
            - self.reward_position[max_id])) / total_deposited
    
    self.balances[msg.sender] = 0
    self.user_position[msg.sender] = 0
    
    amount_rewards_out: uint256 = (((
        self.reward_sum[max_id] 
        - self.reward_sum[user_id]) 
        * amount_out) + round_reward) / (10 ** 18)

    pool_token_out_response: Bytes[32] = raw_call(
        self.pool_token,
        _abi_encode(
            msg.sender,
            old_balance,
            method_id=method_id("transfer(address,uint256)")
        ),
        max_outsize=32,
    )
    if len(pool_token_out_response) > 0:
        assert convert(pool_token_out_response, bool), "Transfer pool token failed!"

    if amount_rewards_out > 0:

        reward_out_response: Bytes[32] = raw_call(
            SWD_TOKEN,
            _abi_encode(
                msg.sender,
                amount_rewards_out,
                method_id=method_id("transfer(address,uint256)")
            ),
            max_outsize=32,
        )
        if len(reward_out_response) > 0:
            assert convert(reward_out_response, bool), "Transfer SWD reward failed!"

    self.max_id_now += 1
    max_id_new: uint256 = self.max_id_now
    self.reward_rate[max_id_new] = reward_rate_now
    self.reward_sum[max_id_new] = self.reward_sum[max_id_new - 1] + reward_rate_now
    self.reward_position[max_id_new] = (actual_reward_balance + total_withdrawn)

    self.total_deposited_tokens -= old_balance
    self.total_withdrawn_reward += amount_rewards_out

    log RewardPayout(msg.sender, amount_rewards_out)
    log UnregisterStaker(msg.sender, old_balance)


@external
def update_lock(lock: uint256) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    assert lock <= 1, "1 Locked, 0 Unlocked"
    self.lock = convert(lock, bool)
    log LockStation(msg.sender, lock)
    return True


@external
def update_owner(new_owner: address) -> bool:
    assert msg.sender == self.owner, "Deployer only"
    self.owner = new_owner
    log NewOwner(msg.sender, new_owner)
    return True