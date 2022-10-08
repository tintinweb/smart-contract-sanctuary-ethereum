# @version 0.3.7
"""
@title L1 Optimism Governance Proxy
"""


interface CrossDomainMessenger:
    def sendMessage(_target: address, _message: Bytes[MAXSIZE], _gas_limit: uint32): nonpayable

interface CanonicalTransactionChain:
    def enqueueL2GasPrepaid() -> uint32: view


event CommitAdmins:
    future_admins: AdminSet

event ApplyAdmins:
    admins: AdminSet

event SetMessenger:
    messenger: CrossDomainMessenger

event SetTransactionChain:
    transaction_chain: CanonicalTransactionChain


enum AdminType:
    OWNERSHIP
    PARAMETER
    EMERGENCY


struct AdminSet:
    ownership: address
    parameter: address
    emergency: address


MAXSIZE: constant(uint256) = 2**16 - 1
MAXSIZE_MESSAGE: constant(uint256) = 2**15 - 1


admins: public(AdminSet)
future_admins: public(AdminSet)

messenger: public(CrossDomainMessenger)
transaction_chain: public(CanonicalTransactionChain)

types: HashMap[address, AdminType]


@external
def __init__(_admins: AdminSet, _messenger: CrossDomainMessenger, _transaction_chain: CanonicalTransactionChain):
    self.admins = _admins
    self.messenger = _messenger
    self.transaction_chain = _transaction_chain

    self.types[_admins.ownership] = AdminType.OWNERSHIP
    self.types[_admins.parameter] = AdminType.PARAMETER
    self.types[_admins.emergency] = AdminType.EMERGENCY

    log ApplyAdmins(_admins)
    log SetMessenger(_messenger)
    log SetTransactionChain(_transaction_chain)


@external
def send_message(_target: address, _message: Bytes[MAXSIZE_MESSAGE], _gas_limit: uint32 = 0):
    """
    @notice Send a cross-chain message to Optimism
    @dev Only callable by an admin
    @param _target The L2 contract on optimism to call
    @param _message The calldata to call `_target` with
    @param _gas_limit Gas limit for the L2 cross-chain call's execution
    """
    admin_type: AdminType = self.types[msg.sender]
    assert admin_type in (AdminType.OWNERSHIP | AdminType.PARAMETER | AdminType.EMERGENCY)

    # https://community.optimism.io/docs/developers/bridge/messaging/#for-l1-%E2%87%92-l2-transactions
    gas_limit: uint32 = _gas_limit
    if gas_limit == 0:
        gas_limit = self.transaction_chain.enqueueL2GasPrepaid()

    # receive_message(_admin_type: AdminType, _target: address, _message: Bytes[MAXSIZE]): nonpayable
    self.messenger.sendMessage(
        self,
        _abi_encode(
            admin_type,
            _target,
            _message,
            method_id=method_id("receive_message(uint256,address,bytes)")
        ),
        gas_limit
    )


@external
def set_messenger(_messenger: CrossDomainMessenger):
    """
    @notice Set the OVM messenger
    """
    assert msg.sender == self.admins.ownership

    self.messenger = _messenger
    log SetMessenger(_messenger)


@external
def set_transaction_chain(_transaction_chain: CanonicalTransactionChain):
    """
    @notice Set the OVM CTC
    """
    assert msg.sender == self.admins.ownership

    self.transaction_chain = _transaction_chain
    log SetTransactionChain(_transaction_chain)


@external
def commit_admins(_admins: AdminSet):
    """
    @notice Commit future admins
    """
    assert msg.sender == self.admins.ownership

    self.future_admins = _admins
    log CommitAdmins(_admins)


@external
def apply_admins():
    """
    @notice Apply future admins
    """
    admins: AdminSet = self.admins
    assert msg.sender == admins.ownership

    self.types[admins.ownership] = empty(AdminType)
    self.types[admins.parameter] = empty(AdminType)
    self.types[admins.emergency] = empty(AdminType)

    # if the same address is used for multiple roles (ownership / parameter / emg)
    # only the last update will be in effect
    # therefore, each admin should be a unique address
    future_admins: AdminSet = self.future_admins
    self.types[future_admins.ownership] = AdminType.OWNERSHIP
    self.types[future_admins.parameter] = AdminType.PARAMETER
    self.types[future_admins.emergency] = AdminType.EMERGENCY

    self.admins = future_admins
    log ApplyAdmins(future_admins)