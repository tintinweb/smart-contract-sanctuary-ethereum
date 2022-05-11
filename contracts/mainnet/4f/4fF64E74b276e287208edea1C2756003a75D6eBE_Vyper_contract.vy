# @version 0.3.1
"""
@notice Curve Arbitrum Bridge Wrapper
"""
from vyper.interfaces import ERC20


interface GatewayRouter:
    def getGateway(_token: address) -> address: view
    def outboundTransfer(  # emits DepositInitiated event with Inbox sequence #
        _token: address,
        _to: address,
        _amount: uint256,
        _max_gas: uint256,
        _gas_price_bid: uint256,
        _data: Bytes[128],  # _max_submission_cost, _extra_data
    ): payable


event TransferOwnership:
    _old_owner: address
    _new_owner: address

event UpdateSubmissionData:
    _old_submission_data: uint256[3]
    _new_submission_data: uint256[3]


CRV20: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
GATEWAY: constant(address) = 0xa3A7B6F88361F48403514059F1F16C8E78d60EeC
GATEWAY_ROUTER: constant(address) = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef


# [gas_limit uint64][gas_price uint64][max_submission_cost uint64]
submission_data: uint256
is_approved: public(HashMap[address, bool])

owner: public(address)
future_owner: public(address)


@external
def __init__(_gas_limit: uint256, _gas_price: uint256, _max_submission_cost: uint256):
    for value in [_gas_limit, _gas_price, _max_submission_cost]:
        assert value < 2 ** 64

    self.submission_data = shift(_gas_limit, 128) + shift(_gas_price, 64) + _max_submission_cost
    log UpdateSubmissionData([0, 0, 0], [_gas_limit, _gas_price, _max_submission_cost])

    assert ERC20(CRV20).approve(GATEWAY, MAX_UINT256)
    self.is_approved[CRV20] = True

    self.owner = msg.sender
    log TransferOwnership(ZERO_ADDRESS, msg.sender)


@payable
@external
def bridge(_token: address, _to: address, _amount: uint256):
    """
    @notice Bridge an ERC20 token using the Arbitrum standard bridge
    @param _token The address of the token to bridge
    @param _to The address to deposit token to on L2
    @param _amount The amount of `_token` to deposit
    """
    assert ERC20(_token).transferFrom(msg.sender, self, _amount)

    if _token != CRV20 and not self.is_approved[_token]:
        assert ERC20(_token).approve(GatewayRouter(GATEWAY_ROUTER).getGateway(_token), MAX_UINT256)
        self.is_approved[_token] = True

    data: uint256 = self.submission_data
    gas_limit: uint256 = shift(data, -128)
    gas_price: uint256 = shift(data, -64) % 2 ** 64
    max_submission_cost: uint256 = data % 2 ** 64

    # NOTE: Excess ETH fee is refunded to this bridger's address on L2.
    # After bridging, the token should arrive on Arbitrum within 10 minutes. If it
    # does not, the L2 transaction may have failed due to an insufficient amount
    # within `max_submission_cost + (gas_limit * gas_price)`
    # In this case, the transaction can be manually broadcasted on Arbitrum by calling
    # `ArbRetryableTicket(0x000000000000000000000000000000000000006e).redeem(redemption-TxID)`
    # The calldata for this manual transaction is easily obtained by finding the reverted
    # transaction in the tx history for 0x000000000000000000000000000000000000006e on Arbiscan.
    # https://developer.offchainlabs.com/docs/l1_l2_messages#retryable-transaction-lifecycle
    GatewayRouter(GATEWAY_ROUTER).outboundTransfer(
        _token,
        _to,
        _amount,
        gas_limit,
        gas_price,
        _abi_encode(max_submission_cost, b""),
        value=gas_limit * gas_price + max_submission_cost
    )


@view
@external
def cost() -> uint256:
    """
    @notice Cost in ETH to bridge
    """
    data: uint256 = self.submission_data
    # gas_limit * gas_price + max_submission_cost
    return shift(data, -128) * (shift(data, -64) % 2 ** 64) + data % 2 ** 64


@pure
@external
def check(_account: address) -> bool:
    """
    @notice Verify if `_account` is allowed to bridge using `transmit_emissions`
    @param _account The account calling `transmit_emissions`
    """
    return True


@external
def set_submission_data(_gas_limit: uint256, _gas_price: uint256, _max_submission_cost: uint256):
    """
    @notice Update the arb retryable ticket submission data
    @param _gas_limit The gas limit for the retryable ticket tx
    @param _gas_price The gas price for the retryable ticket tx
    @param _max_submission_cost The max submission cost for the retryable ticket
    """
    assert msg.sender == self.owner

    for value in [_gas_limit, _gas_price, _max_submission_cost]:
        assert value < 2 ** 64

    data: uint256 = self.submission_data
    self.submission_data = shift(_gas_limit, 128) + shift(_gas_price, 64) + _max_submission_cost
    log UpdateSubmissionData(
        [shift(data, -128), shift(data, -64) % 2 ** 64, data % 2 ** 64],
        [_gas_limit, _gas_price, _max_submission_cost]
    )


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


@view
@external
def gas_limit() -> uint256:
    """
    @notice Get gas limit used for L2 retryable ticket
    """
    return shift(self.submission_data, -128)


@view
@external
def gas_price() -> uint256:
    """
    @notice Get gas price used for L2 retryable ticket
    """
    return shift(self.submission_data, -64) % 2 ** 64


@view
@external
def max_submission_cost() -> uint256:
    """
    @notice Get max submission cost for L2 retryable ticket
    """
    return self.submission_data % 2 ** 64