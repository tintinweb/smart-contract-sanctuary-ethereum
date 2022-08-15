# @version 0.2.8
# @author Lido <[email protected]>
# @licence MIT
from vyper.interfaces import ERC20


# Lido DAO Vault (Agent) contract
interface Vault:
    def deposit(_token: address, _value: uint256): payable

# The purchase has been executed exchanging DAI to vested LDO
event PurchaseExecuted:
    # the address that has received the vested LDO tokens
    ldo_receiver: indexed(address)
    # the number of LDO tokens vested to ldo_receiver
    ldo_allocation: uint256
    # the amount of DAI that was paid and forwarded to the DAO
    dai_cost: uint256
    # the vesting id to be used with the DAO's TokenManager contract
    vesting_id: uint256

# The offer was started
event OfferStarted:
    # timestamp of the offer start
    started_at: uint256
    # timestamp of the offer expiry
    expires_at: uint256

# The ERC20 token was transferred from the contract's address to the Lido treasury address
event ERC20Recovered:
    # the address calling `recover_erc20` function
    requested_by: indexed(address)
    # the token address
    token: indexed(address)
    # the token amount
    amount: uint256 

MAX_PURCHASERS: constant(uint256) = 50
DAI_TO_LDO_RATE_PRECISION: constant(uint256) = 10**18

LDO_TOKEN: constant(address) = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32
DAI_TOKEN: constant(address) = 0x6B175474E89094C44Da98b954EedeAC495271d0F
LIDO_DAO_TOKEN_MANAGER: constant(address) = 0xf73a1260d222f447210581DDf212D915c09a3249
LIDO_DAO_VAULT: constant(address) = 0x3e40D73EB977Dc6a537aF587D48316feE66E9C8c


# how much LDO in one DAI, DAI_TO_LDO_RATE_PRECISION being 1
dai_to_ldo_rate: public(uint256)
ldo_allocations: public(HashMap[address, uint256])
ldo_allocations_total: public(uint256)

# in seconds
offer_expiration_delay: public(uint256)
offer_started_at: public(uint256)
offer_expires_at: public(uint256)
vesting_start_delay: public(uint256)
vesting_end_delay: public(uint256)


@external
def __init__(
    _dai_to_ldo_rate: uint256,
    _vesting_start_delay: uint256,
    _vesting_end_delay: uint256,
    _offer_expiration_delay: uint256,
    _ldo_purchasers: address[MAX_PURCHASERS],
    _ldo_allocations: uint256[MAX_PURCHASERS],
    _ldo_allocations_total: uint256
):
    """
    @param _dai_to_ldo_rate How much LDO one gets for one DAI (multiplied by 10**18)
    @param _vesting_start_delay Delay from the purchase moment to the vesting start moment, in seconds
    @param _vesting_end_delay Delay from the purchase moment to the vesting end moment, in seconds
    @param _offer_expiration_delay Delay from the contract deployment to offer expiration, in seconds
    @param _ldo_purchasers List of valid LDO purchasers, padded by zeroes to the length of 50
    @param _ldo_allocations List of LDO token allocations, padded by zeroes to the length of 50
    @param _ldo_allocations_total Checksum of LDO token allocations
    """
    assert _dai_to_ldo_rate > 0
    assert _vesting_end_delay >= _vesting_start_delay
    assert _offer_expiration_delay > 0
    assert _ldo_allocations_total > 0

    self.dai_to_ldo_rate = _dai_to_ldo_rate
    self.vesting_start_delay = _vesting_start_delay
    self.vesting_end_delay = _vesting_end_delay
    self.offer_expiration_delay = _offer_expiration_delay
    self.ldo_allocations_total = _ldo_allocations_total

    allocations_sum: uint256 = 0

    for i in range(MAX_PURCHASERS):
        purchaser: address = _ldo_purchasers[i]
        if purchaser == ZERO_ADDRESS:
            break
        assert self.ldo_allocations[purchaser] == 0
        allocation: uint256 = _ldo_allocations[i]
        assert allocation > 0
        self.ldo_allocations[purchaser] = allocation
        allocations_sum += allocation

    assert allocations_sum == _ldo_allocations_total


@internal
@view
def _get_allocation(_ldo_receiver: address) -> (uint256, uint256):
    ldo_allocation: uint256 = self.ldo_allocations[_ldo_receiver]
    dai_cost: uint256 = (ldo_allocation * DAI_TO_LDO_RATE_PRECISION) / self.dai_to_ldo_rate
    return (ldo_allocation, dai_cost)


@external
@view
def offer_started() -> bool:
    """
    @return Whether the offer has started.
    """
    return self.offer_started_at != 0


@internal
@view
def _offer_expired() -> bool:
    return self.offer_started_at != 0 and block.timestamp >= self.offer_expires_at


@external
@view
def offer_expired() -> bool:
    """
    @return Whether the offer has expired.
    """
    return self._offer_expired()


@internal
def _start_unless_started():
    if self.offer_started_at == 0:
        assert ERC20(LDO_TOKEN).balanceOf(self) >= self.ldo_allocations_total, "not funded"
        started_at: uint256 = block.timestamp
        expires_at: uint256 = started_at + self.offer_expiration_delay
        self.offer_started_at = started_at
        self.offer_expires_at = expires_at
        log OfferStarted(started_at, expires_at)


@external
def start():
    """
    @notice Starts the offer if it 1) hasn't been started yet and 2) has received funding in full.
    """
    self._start_unless_started()


@external
@view
def get_allocation(_ldo_receiver: address = msg.sender) -> (uint256, uint256):
    """
    @param _ldo_receiver The LDO purchaser address to check
    @return
        A tuple: the first element is the amount of LDO available for purchase (zero if
        the purchase was already executed for that address), the second element is the
        DAI cost of the purchase.
    """
    return self._get_allocation(_ldo_receiver)


@external
def execute_purchase(_ldo_receiver: address = msg.sender) -> uint256:
    """
    @notice Purchases LDO for the specified address (defaults to message sender) in exchange for DAI.
    @param _ldo_receiver The address the purchase is executed for. Must be a valid purchaser.
    @return Vesting ID to be used with the DAO's `TokenManager` contract.
    """
    self._start_unless_started()
    assert block.timestamp < self.offer_expires_at, "offer expired"

    # We don't use any reentrancy lock here because we only make external calls
    # after state mutations.

    ldo_allocation: uint256 = 0
    dai_cost: uint256 = 0
    ldo_allocation, dai_cost = self._get_allocation(_ldo_receiver)

    assert ldo_allocation > 0, "no allocation"

    # clear the purchaser's allocation
    self.ldo_allocations[_ldo_receiver] = 0

    # receive DAI payment
    ERC20(DAI_TOKEN).transferFrom(msg.sender, self, dai_cost)
    ERC20(DAI_TOKEN).approve(LIDO_DAO_VAULT, dai_cost)

    # forward the received DAI to the DAO treasury contract
    Vault(LIDO_DAO_VAULT).deposit(DAI_TOKEN, dai_cost)

    vesting_start: uint256 = block.timestamp + self.vesting_start_delay
    vesting_end: uint256 = block.timestamp + self.vesting_end_delay
    vesting_cliff: uint256 = vesting_start

    # TokenManager can only assign vested tokens from its own balance
    assert ERC20(LDO_TOKEN).transfer(LIDO_DAO_TOKEN_MANAGER, ldo_allocation)

    # assign vested LDO tokens to the purchaser from the DAO treasury reserves
    # Vyper has no uint64 data type so we have to use raw_call instead of an interface
    call_result: Bytes[32] = raw_call(
        LIDO_DAO_TOKEN_MANAGER,
        concat(
            method_id('assignVested(address,uint256,uint64,uint64,uint64,bool)'),
            convert(_ldo_receiver, bytes32),
            convert(ldo_allocation, bytes32),
            convert(vesting_start, bytes32),
            convert(vesting_cliff, bytes32),
            convert(vesting_end, bytes32),
            convert(False, bytes32)
        ),
        max_outsize=32
    )
    vesting_id: uint256 = convert(extract32(call_result, 0), uint256)

    log PurchaseExecuted(_ldo_receiver, ldo_allocation, dai_cost, vesting_id)

    return vesting_id


@external
def recover_erc20(_token: address, _amount: uint256):
    """
    @notice Transfers ERC20 tokens from the contract's balance to the DAO treasury.
    @dev May only be called after the offer expires.
    """
    assert self._offer_expired() # dev: offer not expired
    ERC20(_token).transfer(LIDO_DAO_VAULT, _amount)
    log ERC20Recovered(msg.sender, _token, _amount)


@external
@payable
def __default__():
    raise "not allowed"