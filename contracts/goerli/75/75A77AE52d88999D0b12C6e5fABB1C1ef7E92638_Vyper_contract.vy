# @version 0.3.7

"""
@title GateSeal
@author mymphe
@notice A one-time panic button for pausable contracts
@dev GateSeal is an one-time immediate emergency pause for pausable contracts.
     It must be operated by a multisig committee, though the code does not
     perform any such checks. Bypassing the DAO vote, GateSeal pauses 
     the contract(s) immediately for a set duration, e.g. one week, which gives
     the DAO the time to analyze the situation, decide on the course of action,
     hold a vote, implement fixes, etc. GateSeal can only be used once.
     GateSeal assumes that they have the permission to pause the contracts.

     GateSeals are only a temporary solution and will be deprecated in the future,
     as it is undesireable for the protocol to rely on a multisig. This is why
     each GateSeal has an expiry date. Once expired, GateSeal is no longer
     usable and a new GateSeal must be set up with a new multisig committee. This
     works as a kind of difficulty bomb, a device that encourages the protocol
     to get rid of GateSeals sooner rather than later.

     In the context of GateSeals, sealing is synonymous with pausing the contracts,
     sealables are pausable contracts that implement `pauseFor(duration)` interface.
"""


event Sealed:
    gate_seal: address
    sealed_by: address
    sealed_for: uint256
    sealable: address


event ExpiredPrematurely:
    expired_timestamp: uint256


interface IPausableUntil:
    def pauseFor(_duration: uint256): nonpayable
    def isPaused() -> bool: view

SECONDS_PER_DAY: constant(uint256) = 60 * 60 * 24

# The maximum allowed seal duration is 14 days.
# Anything higher than that may be too long of a disruption for the protocol.
# Keep in mind, that the DAO still retains the ability to resume the contracts
# (or, in the GateSeal terms, "break the seal") prematurely.
MAX_SEAL_DURATION_DAYS: constant(uint256) = 14
MAX_SEAL_DURATION_SECONDS: constant(uint256) = SECONDS_PER_DAY * MAX_SEAL_DURATION_DAYS

# The maximum number of sealables is 8.
# GateSeals were originally designed to pause WithdrawalQueue and ValidatorExitBus,
# however, there is a non-zero chance that there might be more in the future, which
# is why we've opted to use a dynamic-size array.
MAX_SEALABLES: constant(uint256) = 8

# The maximum GateSeal expiry duration is 1 year.
MAX_EXPIRY_PERIOD_DAYS: constant(uint256) = 365
MAX_EXPIRY_PERIOD_SECONDS: constant(uint256) = SECONDS_PER_DAY * MAX_EXPIRY_PERIOD_DAYS

# To simplify the code, we chose not to implement committees in GateSeals.
# Instead, GateSeals are operated by a single account which must be a multisig.
# The code does not perform any such checks but we pinky-promise that
# the sealing committee will always be a multisig. 
SEALING_COMMITTEE: immutable(address)

# The duration of the seal in seconds. This period cannot exceed 14 days. 
# The DAO may decide to resume the contracts prematurely via the DAO voting process.
SEAL_DURATION_SECONDS: immutable(uint256)

# The addresses of pausable contracts. The gate seal must have the permission to
# pause these contracts at the time of the sealing.
# Sealing can be partial, meaning the committee may decide to pause only a subset of this list,
# though GateSeal will still expire immediately.
sealables: DynArray[address, MAX_SEALABLES]

# A unix epoch timestamp starting from which GateSeal is completely unusable
# and a new GateSeal will have to be set up. This timestamp will be changed
# upon sealing to expire GateSeal immediately which will revert any consecutive sealings.
expiry_timestamp: uint256


@external
def __init__(
    _sealing_committee: address,
    _seal_duration_seconds: uint256,
    _sealables: DynArray[address, MAX_SEALABLES],
    _expiry_timestamp: uint256
):
    assert _sealing_committee != empty(address), "sealing committee: zero address"
    assert _seal_duration_seconds != 0, "seal duration: zero"
    assert _seal_duration_seconds <= MAX_SEAL_DURATION_SECONDS, "seal duration: exceeds max"
    assert len(_sealables) > 0, "sealables: empty list"
    assert _expiry_timestamp > block.timestamp, "expiry timestamp: must be in the future"
    assert _expiry_timestamp <= block.timestamp + MAX_EXPIRY_PERIOD_SECONDS, "expiry timestamp: exceeds max expiry period"

    SEALING_COMMITTEE = _sealing_committee
    SEAL_DURATION_SECONDS = _seal_duration_seconds

    for sealable in _sealables:
        assert sealable != empty(address), "sealables: includes zero address"
        self.sealables.append(sealable)
    
    self.expiry_timestamp = _expiry_timestamp


@external
@view
def get_sealing_committee() -> address:
    return SEALING_COMMITTEE


@external
@view
def get_seal_duration_seconds() -> uint256:
    return SEAL_DURATION_SECONDS


@external
@view
def get_sealables() -> DynArray[address, MAX_SEALABLES]:
    return self.sealables


@external
@view
def get_expiry_timestamp() -> uint256:
    return self.expiry_timestamp


@external
@view
def is_expired() -> bool:
    return self._is_expired()


@external
def seal(_sealables: DynArray[address, MAX_SEALABLES]):
    """
    @notice Seal the contract(s).
    @dev    Immediately expires GateSeal and, thus, can only be called once.
    @param _sealables a proper/improper subset of sealables.
    """
    assert msg.sender == SEALING_COMMITTEE, "sender: not SEALING_COMMITTEE"
    assert not self._is_expired(), "gate seal: expired"
    assert len(_sealables) > 0, "sealables: empty subset"

    self._expire_immediately()
    
    # keep track of sealables which have already been sealed to revert on duplicates
    sealed: DynArray[address, MAX_SEALABLES] = []

    for sealable in _sealables:
        assert sealable in self.sealables, "sealables: includes a non-sealable"
        assert not sealable in sealed, "sealables: includes duplicates"
        sealed.append(sealable)

        pausable: IPausableUntil = IPausableUntil(sealable)
        pausable.pauseFor(SEAL_DURATION_SECONDS)
        assert pausable.isPaused(), "sealables: failed to seal"

        log Sealed(self, SEALING_COMMITTEE, SEAL_DURATION_SECONDS, sealable)

    log ExpiredPrematurely(block.timestamp)

@internal
@view
def _is_expired() -> bool:
    return block.timestamp > self.expiry_timestamp


@internal
def _expire_immediately():
    self.expiry_timestamp = 0