# @version 0.3.7
"""
@title Arbitrum Broadcaster
@author CurveFi
"""


interface IArbInbox:
    def calculateRetryableSubmissionFee(_data_length: uint256, _base_fee: uint256) -> uint256: view


event ApplyAdmins:
    admins: AdminSet

event CommitAdmins:
    future_admins: AdminSet

event SetArbInbox:
    arb_inbox: address

event SetArbRefund:
    arb_refund: address


enum Agent:
    OWNERSHIP
    PARAMETER
    EMERGENCY


struct AdminSet:
    ownership: address
    parameter: address
    emergency: address

struct Message:
    target: address
    data: Bytes[MAX_BYTES]


MAX_BYTES: constant(uint256) = 1024
MAX_MESSAGES: constant(uint256) = 8
MAXSIZE: constant(uint256) = 16384


admins: public(AdminSet)
future_admins: public(AdminSet)

agent: HashMap[address, Agent]

arb_inbox: public(address)
arb_refund: public(address)


@payable
@external
def __init__(_admins: AdminSet, _arb_inbox: address, _arb_refund: address):
    assert _admins.ownership != _admins.parameter  # a != b
    assert _admins.ownership != _admins.emergency  # a != c
    assert _admins.parameter != _admins.emergency  # b != c

    self.admins = _admins

    self.agent[_admins.ownership] = Agent.OWNERSHIP
    self.agent[_admins.parameter] = Agent.PARAMETER
    self.agent[_admins.emergency] = Agent.EMERGENCY

    self.arb_inbox = _arb_inbox
    self.arb_refund = _arb_refund

    log ApplyAdmins(_admins)
    log SetArbInbox(_arb_inbox)
    log SetArbRefund(_arb_refund)


@external
def broadcast(_messages: DynArray[Message, MAX_MESSAGES], _gas_limit: uint256, _max_fee_per_gas: uint256):
    """
    @notice Broadcast a sequence of messeages.
    @param _messages The sequence of messages to broadcast.
    @param _gas_limit The gas limit for the execution on L2.
    @param _max_fee_per_gas The maximum gas price bid for the execution on L2.
    """
    agent: Agent = self.agent[msg.sender]
    assert agent != empty(Agent)

    # define all variables here before expanding memory enormously
    arb_inbox: address = self.arb_inbox
    arb_refund: address = self.arb_refund
    submission_cost: uint256 = 0

    data: Bytes[MAXSIZE] = _abi_encode(
        agent,
        _messages,
        method_id=method_id("relay(uint256,(address,bytes)[])"),
    )
    submission_cost = IArbInbox(arb_inbox).calculateRetryableSubmissionFee(len(data), block.basefee)

    # NOTE: using `unsafeCreateRetryableTicket` so that refund address is not aliased
    raw_call(
        arb_inbox,
        _abi_encode(
            self,  # to
            empty(uint256),  # l2CallValue
            submission_cost,  # maxSubmissionCost
            arb_refund,  # excessFeeRefundAddress
            arb_refund,  # callValueRefundAddress
            _gas_limit,
            _max_fee_per_gas,
            data,
            method_id=method_id("unsafeCreateRetryableTicket(address,uint256,uint256,address,address,uint256,uint256,bytes)"),
        ),
        value=submission_cost + _gas_limit * _max_fee_per_gas,
    )


@external
def set_arb_inbox(_arb_inbox: address):
    assert msg.sender == self.admins.ownership

    self.arb_inbox = _arb_inbox
    log SetArbInbox(_arb_inbox)


@external
def set_arb_refund(_arb_refund: address):
    assert msg.sender == self.admins.ownership

    self.arb_refund = _arb_refund
    log SetArbRefund(_arb_refund)


@external
def commit_admins(_future_admins: AdminSet):
    """
    @notice Commit an admin set to use in the future.
    """
    assert msg.sender == self.admins.ownership

    assert _future_admins.ownership != _future_admins.parameter  # a != b
    assert _future_admins.ownership != _future_admins.emergency  # a != c
    assert _future_admins.parameter != _future_admins.emergency  # b != c

    self.future_admins = _future_admins
    log CommitAdmins(_future_admins)


@external
def apply_admins():
    """
    @notice Apply the future admin set.
    """
    admins: AdminSet = self.admins
    assert msg.sender == admins.ownership

    # reset old admins
    self.agent[admins.ownership] = empty(Agent)
    self.agent[admins.parameter] = empty(Agent)
    self.agent[admins.emergency] = empty(Agent)

    # set new admins
    future_admins: AdminSet = self.future_admins
    self.agent[future_admins.ownership] = Agent.OWNERSHIP
    self.agent[future_admins.parameter] = Agent.PARAMETER
    self.agent[future_admins.emergency] = Agent.EMERGENCY

    self.admins = future_admins
    log ApplyAdmins(future_admins)


@payable
@external
def __default__():
    assert len(msg.data) == 0