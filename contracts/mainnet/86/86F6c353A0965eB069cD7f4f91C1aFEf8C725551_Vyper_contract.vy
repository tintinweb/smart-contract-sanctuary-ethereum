# @version 0.3.1
# @notice Wrapper contract for the Balancer Liquidity Gauge.
# @author bulbozaur <[email protected]>
# @license MIT

from vyper.interfaces import ERC20


struct BalancerReward:
    token: address
    distributor: address
    period_finish: uint256
    rate: uint256
    last_update: uint256
    integral: uint256


interface BalancerLiquidityGauge:
    def reward_data(addr: address) -> BalancerReward: view
    def deposit_reward_token(_reward_token: address, _amount: uint256): nonpayable
    def set_reward_distributor(_reward_token: address, _distributor: address): nonpayable


event RewardsContractUpdated:
    newRewardsContract: indexed(address)


event RewardsContractTransferred:
    newDistributor: indexed(address)


event WeeklyRewardsAmountUpdated:
    newWeeklyRewardsAmount: uint256


event NewRewardsPeriodStarted:
    amount: uint256


event ERC20Recovered:
    token: indexed(address)
    amount: uint256
    recipient: indexed(address)


rewards_contract: public(address)
weekly_amount: public(uint256)
rewards_iteration: public(uint256)
min_rewards_amount: immutable(uint256)
owner: immutable(address)
LDO_TOKEN: constant(address) = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32
SECONDS_PER_WEEK: constant(uint256) = 7 * 24 * 60 * 60
WEEKS_PER_PERIOD: constant(uint256) = 4


@external
def __init__(
    _owner: address, 
    _min_rewards_amount: uint256, 
    _rewards_contract: address
):
    owner = _owner
    min_rewards_amount = _min_rewards_amount
    self.rewards_contract = _rewards_contract

    log RewardsContractUpdated(_rewards_contract)


@view
@external
def owner() -> address:
    return owner


@view
@internal
def _balancer_period_finish(rewards_contract: address) -> uint256:
    reward_data: BalancerReward = BalancerLiquidityGauge(rewards_contract).reward_data(LDO_TOKEN)
    return reward_data.period_finish


@view
@internal
def _is_balancer_rewards_period_finished(rewards_contract: address) -> bool:
    return block.timestamp >= self._balancer_period_finish(rewards_contract)


@view
@external
def is_balancer_rewards_period_finished() -> bool:
    """
    @notice Whether the current rewards period has finished.
    """
    return self._is_balancer_rewards_period_finished(self.rewards_contract)


@view
@external
def balancer_period_finish() -> uint256:
    """
    @notice Returns end of the rewards period of BalancerLiquidityGauge contract
    """
    return self._balancer_period_finish(self.rewards_contract)


@external
def start_next_rewards_period():
    """
    @notice
        Starts the next rewards period of duration `rewards_contract.deposit_reward_token(address, uint256)`,
        distributing `self.weekly_amount` tokens throughout each week of the period. The current
        rewards period must be finished by this time and LDO balance not lower then `self.weekly_amount`.
        Ones per 4 calls recalculates `self.weekly_amount` based on self LDO balance. Balance required 
        not to be lower then `min_rewards_amount`
    """
    rewards_contract: address = self.rewards_contract
    amount: uint256 = ERC20(LDO_TOKEN).balanceOf(self)
    iteration: uint256 = self.rewards_iteration    
    rewards_amount: uint256 = 0

    assert rewards_contract != ZERO_ADDRESS, "manager: rewards disabled"
    assert self._is_balancer_rewards_period_finished(rewards_contract), "manager: rewards period not finished"

    if iteration == 0:
        assert amount >= min_rewards_amount, "manager: low balance"
        
        rewards_amount = amount / WEEKS_PER_PERIOD
        self.weekly_amount = rewards_amount

        log WeeklyRewardsAmountUpdated(rewards_amount)
    else:
        rewards_amount = self.weekly_amount

    assert rewards_amount > 0, "manager: rewards disabled"
    assert amount >= rewards_amount, "manager: low balance"

    self.rewards_iteration = (iteration + 1) % WEEKS_PER_PERIOD

    ERC20(LDO_TOKEN).approve(rewards_contract, rewards_amount)
    BalancerLiquidityGauge(rewards_contract).deposit_reward_token(LDO_TOKEN, rewards_amount)

    log NewRewardsPeriodStarted(rewards_amount)


@view
@internal
def _period_finish() -> uint256:
    return self._balancer_period_finish(self.rewards_contract) + \
        ((WEEKS_PER_PERIOD - self.rewards_iteration) % WEEKS_PER_PERIOD) * SECONDS_PER_WEEK


@view
@external
def period_finish() -> uint256:
    """
    @notice Returns end of the rewards period of BalancerLiquidityGauge contract
    """
    return self._period_finish()


@view
@external
def is_rewards_period_finished() -> bool:
    """
    @notice Whether the current rewards period has finished.
    """
    return block.timestamp >= self._period_finish()
    

@external
def replace_me_by_other_distributor(_to: address):
    """
    @notice Changes the reward contracts distributor. Can only be called by the current owner.
    """
    assert msg.sender == owner, "not permitted"
    assert _to != ZERO_ADDRESS, "zero address not allowed"
    BalancerLiquidityGauge(self.rewards_contract).set_reward_distributor(LDO_TOKEN, _to)

    log RewardsContractTransferred(_to)


@external
def set_rewards_contract(_rewards_contract: address):
    """
    @notice Sets the rewards contract. Can only be called by the owner.
    """
    assert msg.sender == owner, "not permitted"
    self.rewards_contract = _rewards_contract

    log RewardsContractUpdated(_rewards_contract)


@internal
def _safe_transfer(_token: address, _to: address, _value: uint256) -> bool:
    _response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) > 0:
        assert convert(_response, bool), "Transfer failed!"

    return True


@external
def recover_erc20(_token: address, _amount: uint256, _recipient: address = msg.sender):
    """
    @notice
        Transfers the given _amount of the given ERC20 token from self
        to the recipient. Can only be called by the owner.
    """
    assert msg.sender == owner, "not permitted"
    assert _recipient != ZERO_ADDRESS, "zero address not allowed"
    if _amount != 0:
        self._safe_transfer(_token, _recipient, _amount)
        log ERC20Recovered(_token, _amount, _recipient)