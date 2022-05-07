# @version 0.3.1
"""
@title Root Liquidity Gauge Factory
@license MIT
@author Curve Finance
"""


interface Bridger:
    def check(_addr: address) -> bool: view

interface RootGauge:
    def bridger() -> address: view
    def initialize(_bridger: address, _chain_id: uint256): nonpayable
    def transmit_emissions(): nonpayable

interface CallProxy:
    def anyCall(
        _to: address, _data: Bytes[1024], _fallback: address, _to_chain_id: uint256
    ): nonpayable


event BridgerUpdated:
    _chain_id: indexed(uint256)
    _old_bridger: address
    _new_bridger: address

event DeployedGauge:
    _implementation: indexed(address)
    _chain_id: indexed(uint256)
    _deployer: indexed(address)
    _salt: bytes32
    _gauge: address

event TransferOwnership:
    _old_owner: address
    _new_owner: address

event UpdateCallProxy:
    _old_call_proxy: address
    _new_call_proxy: address

event UpdateImplementation:
    _old_implementation: address
    _new_implementation: address


call_proxy: public(address)

get_bridger: public(HashMap[uint256, address])
get_implementation: public(address)

get_gauge: public(HashMap[uint256, address[MAX_UINT256]])
get_gauge_count: public(HashMap[uint256, uint256])
is_valid_gauge: public(HashMap[address, bool])

owner: public(address)
future_owner: public(address)


@external
def __init__(_call_proxy: address, _owner: address):
    self.call_proxy = _call_proxy
    log UpdateCallProxy(ZERO_ADDRESS, _call_proxy)

    self.owner = _owner
    log TransferOwnership(ZERO_ADDRESS, _owner)


@external
def transmit_emissions(_gauge: address):
    """
    @notice Call `transmit_emissions` on a root gauge
    @dev Entrypoint for anycall to request emissions for a child gauge.
        The way that gauges work, this can also be called on the root
        chain without a request.
    """
    # in most cases this will return True
    # for special bridges *cough cough Multichain, we can only do
    # one bridge per tx, therefore this will verify msg.sender in [tx.origin, self.call_proxy]
    assert Bridger(RootGauge(_gauge).bridger()).check(msg.sender)
    RootGauge(_gauge).transmit_emissions()


@payable
@external
def deploy_gauge(_chain_id: uint256, _salt: bytes32) -> address:
    """
    @notice Deploy a root liquidity gauge
    @param _chain_id The chain identifier of the counterpart child gauge
    @param _salt A value to deterministically deploy a gauge
    """
    bridger: address = self.get_bridger[_chain_id]
    assert bridger != ZERO_ADDRESS  # dev: chain id not supported

    implementation: address = self.get_implementation
    gauge: address = create_forwarder_to(
        implementation,
        value=msg.value,
        salt=keccak256(_abi_encode(_chain_id, msg.sender, _salt))
    )

    idx: uint256 = self.get_gauge_count[_chain_id]
    self.get_gauge[_chain_id][idx] = gauge
    self.get_gauge_count[_chain_id] = idx + 1
    self.is_valid_gauge[gauge] = True

    RootGauge(gauge).initialize(bridger, _chain_id)

    log DeployedGauge(implementation, _chain_id, msg.sender, _salt, gauge)
    return gauge


@external
def deploy_child_gauge(_chain_id: uint256, _lp_token: address, _salt: bytes32, _manager: address = msg.sender):
    bridger: address = self.get_bridger[_chain_id]
    assert bridger != ZERO_ADDRESS  # dev: chain id not supported

    CallProxy(self.call_proxy).anyCall(
        self,
        _abi_encode(
            _lp_token,
            _salt,
            _manager,
            method_id=method_id("deploy_gauge(address,bytes32,address)")
        ),
        ZERO_ADDRESS,
        _chain_id
    )


@external
def set_bridger(_chain_id: uint256, _bridger: address):
    """
    @notice Set the bridger for `_chain_id`
    @param _chain_id The chain identifier to set the bridger for
    @param _bridger The bridger contract to use
    """
    assert msg.sender == self.owner  # dev: only owner

    log BridgerUpdated(_chain_id, self.get_bridger[_chain_id], _bridger)
    self.get_bridger[_chain_id] = _bridger


@external
def set_implementation(_implementation: address):
    """
    @notice Set the implementation
    @param _implementation The address of the implementation to use
    """
    assert msg.sender == self.owner  # dev: only owner

    log UpdateImplementation(self.get_implementation, _implementation)
    self.get_implementation = _implementation


@external
def set_call_proxy(_new_call_proxy: address):
    """
    @notice Set the address of the call proxy used
    @dev _new_call_proxy should adhere to the same interface as defined
    @param _new_call_proxy Address of the cross chain call proxy
    """
    assert msg.sender == self.owner

    log UpdateCallProxy(self.call_proxy, _new_call_proxy)
    self.call_proxy = _new_call_proxy


@external
def commit_transfer_ownership(_future_owner: address):
    """
    @notice Transfer ownership to `_future_owner`
    @param _future_owner The account to commit as the future owner
    """
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    """
    @notice Accept the transfer of ownership
    @dev Only the committed future owner can call this function
    """
    assert msg.sender == self.future_owner  # dev: only future owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender