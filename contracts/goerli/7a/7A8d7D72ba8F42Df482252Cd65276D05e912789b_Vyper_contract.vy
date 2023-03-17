# @version 0.3.7

"""
@title GateSealFactory
@author mymphe
@notice A factory contract for GateSeals
@dev This contract is meant to simplify the GateSeal deploy.
     The factory features a single write function that deploys
     a new GateSeal with the given parameters based
     on the blueprint provided at the factory construction
     using `create_from_blueprint`.

     The blueprint must follow EIP-5202 and, thus, is not a
     functioning GateSeal itself but only its initcode.

     More on blueprints
     https://docs.vyperlang.org/en/v0.3.7/built-in-functions.html#chain-interaction

     More on EIP-5202
     https://eips.ethereum.org/EIPS/eip-5202
"""

event GateSealCreated:
    gate_seal: address


# First 3 bytes of the blueprint is the EIP-5202 header;
# The actual code of the contract starts at 4th byte
EIP5202_CODE_OFFSET: constant(uint256) = 3

# The maximum number of sealables is 8.
# GateSeals were originally designed to pause WithdrawalQueue and ValidatorExitBus,
# however, there is a non-zero chance that there might be more in the future, which
# is why we've opted to use a dynamic-size array.
MAX_SEALABLES: constant(uint256) = 8

# Address of the blueprint that must be deployed beforehand
BLUEPRINT: immutable(address)

@external
def __init__(_blueprint: address):
    assert _blueprint != empty(address), "blueprint: zero address"
    BLUEPRINT = _blueprint


@external
@view
def get_blueprint() -> address:
    return BLUEPRINT


@external
def create_gate_seal(
    _sealing_committee: address,
    _seal_duration_seconds: uint256,
    _sealables: DynArray[address, MAX_SEALABLES],
    _expiry_timestamp: uint256
):
    """
    @notice Create a new GateSeal.
    @dev    All of the security checks are done inside the GateSeal constructor.
    @param _sealing_committee address of the multisig committee
    @param _seal_duration_seconds duration of the seal in seconds
    @param _sealables addresses of pausable contracts
    @param _expiry_timestamp unix timestamp when the GateSeal will naturally expire
    """
    gate_seal: address = create_from_blueprint(
        BLUEPRINT,
        _sealing_committee,
        _seal_duration_seconds,
        _sealables,
        _expiry_timestamp,
        code_offset=EIP5202_CODE_OFFSET,
    )

    log GateSealCreated(gate_seal)