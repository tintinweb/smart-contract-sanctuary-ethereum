# @version 0.3.7
"""
@title Optimism Broadcaster
@author CurveFi
"""


interface OVMChain:
    def enqueueL2GasPrepaid() -> uint32: view


event ApplyAdmins:
    admins: AdminSet

event CommitAdmins:
    future_admins: AdminSet

event SetOVMChain:
    ovm_chain: address

event SetOVMMessenger:
    ovm_messenger: address


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


admins: public(AdminSet)
future_admins: public(AdminSet)

agent: HashMap[address, Agent]

ovm_chain: public(address)  # CanonicalTransactionChain
ovm_messenger: public(address)  # CrossDomainMessenger


@external
def __init__(_admins: AdminSet, _ovm_chain: address, _ovm_messenger: address):
    assert _admins.ownership != _admins.parameter  # a != b
    assert _admins.ownership != _admins.emergency  # a != c
    assert _admins.parameter != _admins.emergency  # b != c

    self.admins = _admins

    self.agent[_admins.ownership] = Agent.OWNERSHIP
    self.agent[_admins.parameter] = Agent.PARAMETER
    self.agent[_admins.emergency] = Agent.EMERGENCY

    self.ovm_chain = _ovm_chain
    self.ovm_messenger = _ovm_messenger

    log ApplyAdmins(_admins)
    log SetOVMChain(_ovm_chain)
    log SetOVMMessenger(_ovm_messenger)


@external
def broadcast(_messages: DynArray[Message, MAX_MESSAGES], _gas_limit: uint32 = 0):
    """
    @notice Broadcast a sequence of messeages.
    @param _messages The sequence of messages to broadcast.
    @param _gas_limit The L2 gas limit required to execute the sequence of messages.
    """
    agent: Agent = self.agent[msg.sender]
    assert agent != empty(Agent)

    # https://community.optimism.io/docs/developers/bridge/messaging/#for-l1-%E2%87%92-l2-transactions
    gas_limit: uint32 = _gas_limit
    if gas_limit == 0:
        gas_limit = OVMChain(self.ovm_chain).enqueueL2GasPrepaid()

    raw_call(
        self.ovm_messenger,
        _abi_encode(  # sendMessage(address,bytes,uint32)
            self,
            _abi_encode(  # relay(uint256,(address,bytes)[])
                agent,
                _messages,
                method_id=method_id("relay(uint256,(address,bytes)[])"),
            ),
            gas_limit,
            method_id=method_id("sendMessage(address,bytes,uint32)"),
        ),
    )


@external
def set_ovm_chain(_ovm_chain: address):
    """
    @notice Set the OVM Canonical Transaction Chain storage variable.
    """
    assert msg.sender == self.admins.ownership

    self.ovm_chain = _ovm_chain
    log SetOVMChain(_ovm_chain)


@external
def set_ovm_messenger(_ovm_messenger: address):
    """
    @notice Set the OVM Cross Domain Messenger storage variable.
    """
    assert msg.sender == self.admins.ownership

    self.ovm_messenger = _ovm_messenger
    log SetOVMMessenger(_ovm_messenger)


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