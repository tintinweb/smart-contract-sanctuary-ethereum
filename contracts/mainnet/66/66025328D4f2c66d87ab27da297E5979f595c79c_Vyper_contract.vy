# @version ^0.3.7

from vyper.interfaces import ERC20

CURRENCY: immutable(ERC20)
API_VERSION: immutable(String[8])

struct Plan:
    is_active: bool
    price: uint256

is_active: bool
owner: address
num_plans: uint8
plans: HashMap[uint8, Plan]
subscriptions: HashMap[uint8, HashMap[address, uint256]]

event NewSubscriber:
    plan_id: uint8
    subscriber: address
    duration: uint256

event PlanCreated:
    plan_id: uint8
    price: uint256

event PlanActivated:
    plan_id: uint8
    
event PlanRetired:
    plan_id: uint8

event SubscriberRetired:
    pass

@external
def __init__(currency: address):
    self.owner = msg.sender
    self.is_active = True
    CURRENCY = ERC20(currency)
    API_VERSION = "0.0.0"

##################
# View functions #
##################

@view
@external
def get_plan(plan_id: uint8) -> Plan:
    return self.plans[plan_id]

@view
@external
def plan_count() -> uint8:
    return self.num_plans

@view
@external
def subscription_end(plan_id: uint8, subscriber: address) -> uint256:
    return self.subscriptions[plan_id][subscriber]

########################
# Subscriber functions #
########################

@external
def subscribe(plan_id: uint8, amount: uint256) -> uint256:
    return self._subscribe(plan_id, amount, msg.sender)

@external
def subscribe_for(plan_id: uint8, amount: uint256, wallet: address) -> uint256:
    return self._subscribe(plan_id, amount, wallet)

######################
# Internal functions #
######################

@internal
def _subscribe(plan_id: uint8, amount: uint256, subscriber: address) -> uint256:
    assert self.is_active, "Subscription contract has been retired"
    plan: Plan = self.plans[plan_id]
    assert plan.is_active, "Plan does not exist or has been retired."
    CURRENCY.transferFrom(subscriber, self, amount)
    duration: uint256 = amount / plan.price
    log NewSubscriber(plan_id, subscriber, duration)
    end_timestamp: uint256 = block.timestamp + duration
    self.subscriptions[plan_id][subscriber] = end_timestamp
    return end_timestamp

###################
# Owner functions #
###################

@external
def create_plan(price: uint256) -> Plan:
    '''
    'price' the price per second for your plan, denominated in CURRENCY.
    '''
    assert self.is_active, "Subscription contract has been retired"
    assert self.owner == msg.sender, "You are not the owner."
    plan: Plan = Plan({is_active: False, price: price})
    plan_id: uint8 = self.num_plans + 1
    self.plans[plan_id] = plan
    self.num_plans = plan_id
    log PlanCreated(plan_id, price)
    return plan

@external
def activate_plan(plan_id: uint8):
    assert self.is_active, "Subscription contract has been retired"
    assert self.owner == msg.sender, "You are not the owner."
    plan: Plan = self.plans[plan_id]
    assert plan.price > 0, "Plan does not exist."
    assert not plan.is_active, "Plan is already active."
    self.plans[plan_id].is_active = True
    log PlanActivated(plan_id)

@external
def retire_plan(plan_id: uint8):
    """
    'plan_id': the plan id of the Plan you wish to retire.
    """
    
    assert self.is_active, "Subscription contract has been retired"
    assert self.owner == msg.sender, "You are not the owner."
    plan: Plan = self.plans[plan_id]
    assert plan.is_active, "Plan is not active."
    plan.is_active = False
    log PlanRetired(plan_id)

@external
def retire_contract():
    assert self.is_active, "Subscription contract has been retired"
    assert self.owner == msg.sender, "You are not the owner."
    self.is_active = False
    log SubscriberRetired()