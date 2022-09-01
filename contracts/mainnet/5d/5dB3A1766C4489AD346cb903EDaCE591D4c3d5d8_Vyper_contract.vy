# @version 0.3.1
"""
@notice Curve Arbitrum Bridge Wrapper
"""
from vyper.interfaces import ERC20


interface GatewayRouter:
    def getGateway(_token: address) -> address: view
    def outboundTransferCustomRefund(  # emits DepositInitiated event with Inbox sequence #
        _token: address,
        _refund_to: address,
        _to: address,
        _amount: uint256,
        _max_gas: uint256,
        _gas_price_bid: uint256,
        _data: Bytes[128],  # _max_submission_cost, _extra_data
    ): payable
    def getOutboundCalldata(
        _token: address,
        _from: address,
        _to: address,
        _amount: uint256,
        _data: Bytes[128]
    ) -> (uint256, uint256): view  # actually returns bytes, but we just need the size

interface Inbox:
    def calculateRetryableSubmissionFee(_data_length: uint256, _base_fee: uint256) -> uint256: view


event TransferOwnership:
    _old_owner: address
    _new_owner: address

event UpdateSubmissionData:
    _old_submission_data: uint256[2]
    _new_submission_data: uint256[2]


CRV20: constant(address) = 0xD533a949740bb3306d119CC777fa900bA034cd52
GATEWAY: constant(address) = 0xa3A7B6F88361F48403514059F1F16C8E78d60EeC
GATEWAY_ROUTER: constant(address) = 0x72Ce9c846789fdB6fC1f34aC4AD25Dd9ef7031ef
INBOX: constant(address) = 0x4Dbd4fc535Ac27206064B68FfCf827b0A60BAB3f


# [gas_limit uint128][gas_price uint128]
submission_data: uint256
is_approved: public(HashMap[address, bool])
is_killed: public(bool)

owner: public(address)
future_owner: public(address)


@external
def __init__(_gas_limit: uint256, _gas_price: uint256):
    for value in [_gas_limit, _gas_price]:
        assert value < 2 ** 128

    self.submission_data = shift(_gas_limit, 128) + _gas_price
    log UpdateSubmissionData([0, 0], [_gas_limit, _gas_price])

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
    assert not self.is_killed
    assert ERC20(_token).transferFrom(msg.sender, self, _amount)

    if _token != CRV20 and not self.is_approved[_token]:
        assert ERC20(_token).approve(GatewayRouter(GATEWAY_ROUTER).getGateway(_token), MAX_UINT256)
        self.is_approved[_token] = True

    data: uint256 = self.submission_data
    gas_limit: uint256 = shift(data, -128)
    gas_price: uint256 = data % 2 ** 128
    submission_cost: uint256 = Inbox(INBOX).calculateRetryableSubmissionFee(
        GatewayRouter(GATEWAY_ROUTER).getOutboundCalldata(
            _token,
            self,
            msg.sender,
            _amount,
            b"",
        )[1] + 256,
        block.basefee
    )

    # NOTE: Excess ETH fee is refunded to this bridger's address on L2.
    # After bridging, the token should arrive on Arbitrum within 10 minutes. If it
    # does not, the L2 transaction may have failed due to an insufficient amount
    # within `max_submission_cost + (gas_limit * gas_price)`
    # In this case, the transaction can be manually broadcasted on Arbitrum by calling
    # `ArbRetryableTicket(0x000000000000000000000000000000000000006e).redeem(redemption-TxID)`
    # The calldata for this manual transaction is easily obtained by finding the reverted
    # transaction in the tx history for 0x000000000000000000000000000000000000006e on Arbiscan.
    # https://developer.offchainlabs.com/docs/l1_l2_messages#retryable-transaction-lifecycle
    GatewayRouter(GATEWAY_ROUTER).outboundTransferCustomRefund(
        _token,
        self.owner,
        _to,
        _amount,
        gas_limit,
        gas_price,
        _abi_encode(submission_cost, b""),
        value=gas_limit * gas_price + submission_cost
    )

    send(msg.sender, self.balance)


@view
@external
def cost() -> uint256:
    """
    @notice Cost in ETH to bridge
    """
    submission_cost: uint256 = Inbox(INBOX).calculateRetryableSubmissionFee(
        GatewayRouter(GATEWAY_ROUTER).getOutboundCalldata(
            CRV20,
            self,
            msg.sender,
            10 ** 36,
            b"",
        )[1] + 256,
        block.basefee
    )
    data: uint256 = self.submission_data
    # gas_limit * gas_price
    return shift(data, -128) * data % 2 ** 128 + submission_cost


@pure
@external
def check(_account: address) -> bool:
    """
    @notice Verify if `_account` is allowed to bridge using `transmit_emissions`
    @param _account The account calling `transmit_emissions`
    """
    return True


@external
def set_submission_data(_gas_limit: uint256, _gas_price: uint256):
    """
    @notice Update the arb retryable ticket submission data
    @param _gas_limit The gas limit for the retryable ticket tx
    @param _gas_price The gas price for the retryable ticket tx
    """
    assert msg.sender == self.owner

    for value in [_gas_limit, _gas_price]:
        assert value < 2 ** 128

    data: uint256 = self.submission_data
    self.submission_data = shift(_gas_limit, 128) + _gas_price
    log UpdateSubmissionData(
        [shift(data, -128), data % 2 ** 128],
        [_gas_limit, _gas_price]
    )


@external
def set_killed(_is_killed: bool):
    assert msg.sender == self.owner
    
    self.is_killed = _is_killed


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
    assert not msg.sender.is_contract

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
    return self.submission_data % 2 ** 128