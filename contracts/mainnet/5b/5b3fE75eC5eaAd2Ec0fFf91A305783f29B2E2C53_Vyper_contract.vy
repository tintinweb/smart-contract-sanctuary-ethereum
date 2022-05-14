# @version 0.3.3
# @License Copyright (c) Swap.Dance, 2022 - all rights reserved
# @Author Alexey K
# Swap.Dance Token (Ticker: DANCE)

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event Salary:
    receiver: indexed(address)
    value: uint256

event NewSalaryRate:
    owner: indexed(address)
    new_rate: uint256

event NewOwner:
    old_owner: indexed(address)
    new_owner: indexed(address)
    
event NewGuardian:
    guardian: indexed(address)

# SWD Settings
done: bool
done_guard: bool
owner_agree: bool
guardian_agree: bool
owner: public(address)
guardian: public(address)
deployer: public(address)
lock_time: public(uint256)
totalSupply: public(uint256)
salary_rate: public(uint256)
balanceOf: public(HashMap[address, uint256])
exchange_list: public(HashMap[address, address])
station_code_hash: public(HashMap[address, bytes32])
allowance: public(HashMap[address, HashMap[address, uint256]])

# Constants
NAME: immutable(String[32])
SYMBOL: immutable(String[32])
DECIMALS: immutable(uint8)
MAX_GAS: immutable(uint256) # 30000000
BASE_MINT: immutable(uint256) # 1000000000
TIME: constant(uint256) = 2419200
DENOMINATOR: constant(uint256) = 10000


@external
def __init__(
    name: String[32], 
    symbol: String[32], 
    supply: uint256, 
    max_gas: uint256, 
    base_mint: uint256
):
    init_supply: uint256 = supply * 10 ** 18
    NAME = name
    SYMBOL = symbol
    DECIMALS = 18
    self.balanceOf[msg.sender] = init_supply
    self.totalSupply = init_supply
    self.owner = msg.sender
    self.salary_rate = 50 # 0.5%
    BASE_MINT = base_mint
    MAX_GAS = max_gas
    log Transfer(ZERO_ADDRESS, msg.sender, init_supply)


@external
@view
def name() -> String[32]:
    return NAME


@external
@view
def symbol() -> String[32]:
    return SYMBOL


@external
@view
def decimals() -> uint8:
    return DECIMALS


@internal
def _transfer(sender: address, receiver: address, amount: uint256):
    assert receiver not in [self, ZERO_ADDRESS]
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    log Transfer(sender, receiver, amount)


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self._transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    if (self.allowance[sender][msg.sender] < MAX_UINT256):
        allowance: uint256 = self.allowance[sender][msg.sender] - amount
        self.allowance[sender][msg.sender] = allowance
        # NOTE: Allows log filters to have a full accounting of allowance changes
        log Approval(sender, msg.sender, allowance)
    self._transfer(sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def increaseAllowance(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] += amount
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@external
def decreaseAllowance(spender: address, amount: uint256) -> bool:
    self.allowance[msg.sender][spender] -= amount
    log Approval(msg.sender, spender, self.allowance[msg.sender][spender])
    return True


@internal
def _mint(receiver: address, amount: uint256):
    self.balanceOf[receiver] += amount
    self.totalSupply += amount
    log Transfer(ZERO_ADDRESS, receiver, amount)


@internal
def _burn(sender: address, amount: uint256):
    self.balanceOf[sender] -= amount
    self.totalSupply -= amount
    log Transfer(sender, ZERO_ADDRESS, amount)


@external
def burn(_value: uint256):
    self._burn(msg.sender, _value)


@external
def mint_proof_of_trade(trade_count: uint256) -> bool:
    pot: address = self.exchange_list[msg.sender]
    assert pot != ZERO_ADDRESS, "PoT doesn't exist"
    mint_pool_reward: uint256 = empty(uint256)
    if msg.gas > MAX_GAS:
        mint_pool_reward = (msg.gas - MAX_GAS) * BASE_MINT * trade_count
    elif msg.gas == MAX_GAS:
        mint_pool_reward = BASE_MINT * trade_count
    else:
        mint_pool_reward = ((MAX_GAS - msg.gas) * BASE_MINT) * trade_count
    self._mint(pot, mint_pool_reward)
    return True


@external
def dev_salary(to: address, amount: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert to not in [self, ZERO_ADDRESS]
    assert ((self.totalSupply * self.salary_rate) / DENOMINATOR) >= amount
    assert block.timestamp > self.lock_time, "Salary time"
    self._mint(to, amount)
    self.lock_time = TIME + block.timestamp
    log Salary(to, amount)


@external
def new_deployer(deployer: address):
    assert msg.sender == self.owner, "Owner only"
    assert not self.done, "Deployer already registred"
    self.deployer = deployer
    self.done = True


@external
def update_deployer():
    assert msg.sender == self.owner, "Owner only"
    assert self.done, "Deployer not registred"
    assert self.guardian_agree, "Guardian not agree"
    self.done = False


@external
def register_deployer() -> bool:
    assert msg.sender == self.deployer, "Deployer only"
    assert self.station_code_hash[msg.sender] == EMPTY_BYTES32
    self.station_code_hash[msg.sender] = msg.sender.codehash
    return True


@external
def register_pot(
        pool: address,
        proof_of_trade: address
) -> bool:
    assert msg.sender.codehash == self.station_code_hash[msg.sender], "Deployer only"
    assert self.exchange_list[pool] == ZERO_ADDRESS, "PoT already registred"
    self.exchange_list[pool] = proof_of_trade
    return True


@external
def increase_salary_rate(new_rate: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert new_rate >= 50, "Wrong rate"
    assert new_rate <= 200, "Wrong rate"
    self.salary_rate = new_rate
    log NewSalaryRate(msg.sender, new_rate)


@external
def update_owner(new_owner: address):
    assert msg.sender == self.owner, "Owner only"
    assert self.owner_agree, "Owner not agree"
    assert self.guardian_agree, "Guardian not agree"
    self.owner = new_owner
    self.owner_agree = False
    self.guardian_agree = False
    log NewOwner(msg.sender, new_owner)


@external
def set_guardian(guardian: address):
    assert msg.sender == self.owner, "Owner only"
    assert not self.done_guard, "Guardian already registred"
    assert guardian != ZERO_ADDRESS
    self.guardian_agree = False
    self.owner_agree = False
    self.guardian = guardian
    self.done_guard = True
    log NewGuardian(guardian)


@external
def update_guardian():
    assert msg.sender == self.owner, "Owner only"
    assert self.done_guard, "Guardian not registred"
    assert self.owner_agree, "Owner not agree"
    assert self.guardian_agree, "Guardian not agree"
    self.done_guard = False


@external
def ask_guardian(agree: uint256):
    assert msg.sender == self.guardian, "Guardian only"
    assert self.owner_agree, "Owner not agree"
    assert agree <= 1, "1 Yes, 0 No"
    self.guardian_agree = convert(agree, bool)


@external
def ask_owner(agree: uint256):
    assert msg.sender == self.owner, "Owner only"
    assert agree <= 1, "1 Yes, 0 No"
    self.owner_agree = convert(agree, bool)