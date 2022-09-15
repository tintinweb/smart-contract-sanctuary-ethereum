# @version 0.3.6
# @title MEV Boost Relay Allowed List
# @notice Storage of the allowed list MEV-Boost relays.
# @license MIT
# @author Lido <[email protected]>
# @dev Relay data modification is supposed to be done by remove and add,
#      to reduce the number of lines of code of the contract.


# The relay was added
event RelayAdded:
    uri_hash: indexed(String[MAX_STRING_LENGTH])
    relay: Relay

# The relay was removed
event RelayRemoved:
    uri_hash: indexed(String[MAX_STRING_LENGTH])
    uri: String[MAX_STRING_LENGTH]

# Emitted every time the allowed list is changed
event AllowedListUpdated:
    allowed_list_version: indexed(uint256)

# Emitted when the contract owner is changed
event OwnerChanged:
    new_owner: indexed(address)

# Emitted when the contract manager is set or dismissed
# When the manager is dismissed the address is zero
event ManagerChanged:
    new_manager: indexed(address)

# The ERC20 token was transferred from the contract to the recipient
event ERC20Recovered:
    # the token address
    token: indexed(address)
    # the token amount
    amount: uint256
    # recipient of the recovery token transfer
    recipient: indexed(address)


struct Relay:
    uri: String[MAX_STRING_LENGTH]
    operator: String[MAX_STRING_LENGTH]
    is_mandatory: bool
    description: String[MAX_STRING_LENGTH]


# Just some sane limit
MAX_STRING_LENGTH: constant(uint256) = 1024

# Just some sane limit
MAX_NUM_RELAYS: constant(uint256) = 40

# Can change the allowed list, change the manager and call recovery functions
owner: address

# Manager can change the allowed list as well as the owner
# Can be assigned and dismissed by the owner
# Zero manager means manager is not assigned
manager: address

# List of the relays. Order might be arbitrary
relays: DynArray[Relay, MAX_NUM_RELAYS]

# Incremented each time the list of relays is modified.
# Introduced to facilitate easy versioning of the allowed list
allowed_list_version: uint256


@external
def __init__(owner: address):
    assert owner != empty(address), "zero owner address"
    self.owner = owner


@view
@external
def get_relays_amount() -> uint256:
    """
    @notice Return number of the allowed relays
    @return The number of the allowed relays
    """
    return len(self.relays)


@view
@external
def get_owner() -> address:
    """Return the address of owner of the contract"""
    return self.owner


@view
@external
def get_manager() -> address:
    """Return the address of manager of the contract"""
    return self.manager


@view
@external
def get_relays() -> DynArray[Relay, MAX_NUM_RELAYS]:
    """Return list of the allowed relays"""
    return self.relays


@view
@external
def get_relay_by_uri(relay_uri: String[MAX_STRING_LENGTH]) -> Relay:
    """Find allowed relay by URI. Revert if no relay found"""
    index: uint256 = self._find_relay(relay_uri)
    assert index != max_value(uint256), "no relay with the URI"
    return self.relays[index]


@view
@external
def get_allowed_list_version() -> uint256:
    """
    @notice Return version of the allowed list
    @dev The version is incremented on every relays list update
    """
    return self.allowed_list_version


@external
def add_relay(
    uri: String[MAX_STRING_LENGTH],
    operator: String[MAX_STRING_LENGTH],
    is_mandatory: bool,
    description: String[MAX_STRING_LENGTH]
):
    """
    @notice Add relay to the allowed list. Can be executed only by the owner or
            manager. Reverts if relay with the URI is already allowed.
    @param uri URI of the relay. Must be non-empty
    @param operator Name of the relay operator
    @param is_mandatory If the relay is mandatory for usage for Lido Node Operator
    @param description Description of the relay in free format
    """
    self._check_sender_is_owner_or_manager()
    assert uri != empty(String[MAX_STRING_LENGTH]), "relay URI must not be empty"
    assert len(self.relays) < MAX_NUM_RELAYS, "already max number of relays"

    index: uint256 = self._find_relay(uri)
    assert index == max_value(uint256), "relay with the URI already exists"

    relay: Relay = Relay({
        uri: uri,
        operator: operator,
        is_mandatory: is_mandatory,
        description: description,
    })
    self.relays.append(relay)
    self._bump_version()

    log RelayAdded(uri, relay)


@external
def remove_relay(uri: String[MAX_STRING_LENGTH]):
    """
    @notice Remove relay from the allowed list. Can be executed only by the the owner or
            manager. Reverts if there is no such relay.
            Order of the relays might get changed.
    @param uri URI of the relay. Must be non-empty
    """
    self._check_sender_is_owner_or_manager()
    assert uri != empty(String[MAX_STRING_LENGTH]), "relay URI must not be empty"

    num_relays: uint256 = len(self.relays)
    index: uint256 = self._find_relay(uri)
    assert index < num_relays, "no relay with the URI"

    if index != (num_relays - 1):
        self.relays[index] = self.relays[num_relays - 1]

    self.relays.pop()
    self._bump_version()

    log RelayRemoved(uri, uri)


@external
def change_owner(owner: address):
    """
    @notice Change contract owner.
    @param owner Address of the new owner. Must be non-zero and
           not same as the current owner.
    """
    self._check_sender_is_owner()
    assert owner != empty(address), "zero owner address"
    assert owner != self.owner, "same owner"

    self.owner = owner
    log OwnerChanged(owner)


@external
def set_manager(manager: address):
    """
    @notice Set contract manager. Zero address is not allowed.
            Can update manager if it is already set.
            Can be called only by the owner.
    @param manager Address of the new manager
    """
    self._check_sender_is_owner()
    assert manager != empty(address), "zero manager address"
    assert manager != self.manager, "same manager"

    self.manager = manager
    log ManagerChanged(manager)


@external
def dismiss_manager():
    """
    @notice Dismiss the manager. Reverts if no manager set.
            Can be called only by the owner.
    """
    self._check_sender_is_owner()
    assert self.manager != empty(address), "no manager set"

    self.manager = empty(address)
    log ManagerChanged(empty(address))


@external
def recover_erc20(token: address, amount: uint256, recipient: address):
    """
    @notice Transfer ERC20 tokens from the contract's balance to the recipient.
            Can be called only by the owner.
    @param token Address of the token to recover. Must be non-zero
    @param amount Amount of the token to recover
    @param recipient Recipient of the token transfer. Must be non-zero
    """
    self._check_sender_is_owner()
    assert token != empty(address), "zero token address"
    assert recipient != empty(address), "zero recipient address"
    assert token.is_contract, "eoa token address"

    if amount > 0:
        self._safe_erc20_transfer(token, recipient, amount)
        log ERC20Recovered(token, amount, recipient)


@external
def __default__():
    """Prevent receiving ether"""
    raise


@view
@internal
def _find_relay(uri: String[MAX_STRING_LENGTH]) -> uint256:
    index: uint256 = max_value(uint256)
    i: uint256 = 0
    for r in self.relays:
        if r.uri == uri:
            index = i
            break
        i = i + 1
    return index


@internal
def _check_sender_is_owner_or_manager():
    assert (
        msg.sender == self.owner
        or
        (msg.sender == self.manager and msg.sender != empty(address))
    ), "msg.sender not owner or manager"


@internal
def _check_sender_is_owner():
    assert msg.sender == self.owner, "msg.sender not owner"


@internal
def _bump_version():
   new_version: uint256 = self.allowed_list_version + 1
   self.allowed_list_version = new_version
   log AllowedListUpdated(new_version)


@internal
def _safe_erc20_transfer(token: address, recipient: address, amount: uint256):
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(recipient, bytes32),
            convert(amount, bytes32)
        ),
        max_outsize=32
    )
    if len(response) > 0:
        assert convert(response, bool), "erc20 transfer failed"