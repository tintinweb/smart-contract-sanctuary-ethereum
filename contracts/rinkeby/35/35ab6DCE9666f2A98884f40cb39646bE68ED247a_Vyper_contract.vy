# @dev Implementation of ERC-721 non-fungible token standard.
# @author Amajid Sinar
# Modified from: https://github.com/vyperlang/vyper/blob/de74722bf2d8718cca46902be165f9fe0e3641dd/examples/tokens/ERC721.vy
# @version 0.3.3
from vyper.interfaces import ERC721

implements: ERC721


interface ERC721Receiver:
    def onERC721Received(
        _operator: address, _from: address, _tokenId: uint256, _data: Bytes[1024]
    ) -> bytes32:
        view


# @dev
#     Emits when ownership of any NFT changes by any mechanism.
#     created(`from` == 0) and destroyed (`to` == 0)
# @param sender
#     sender of the NFT. If the address is zero address it indicates token creation
# @param receiver
#     receiver of the NFT. If the address is zero address it indicates token destruction
# @param tokenId
#     the NFT that got transferred


event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _token_id: indexed(uint256)


# @dev
#     Emits when the approved address for and NFT is changed or reaffirmed. The zero address indicates
#     that there is no approved address. In other words, this is emitted when a specific address is allowed to transfer a specific token
# @param owner
#     Owner of the NFT
# @param approved
#     Address that is given acess to
# @param token_id
#     NFT that is being approved


event Approval:
    owner: indexed(address)
    approved: indexed(address)
    token_id: indexed(uint256)


# @dev
#   Emits when an address is given granted or be revoked from `Operator`
#   An operator is allowed to transfer all tokens of the sender on their behalf
# @param owner
#     Owner of the NFT
# @param operator
#     Address given access or revoked from its authorithy
# @param approved


event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004

# @dev Mapping from NFT ID to the address that owns it
id_to_owner: HashMap[uint256, address]

# @dev Mapping from NFT ID to the approved address
id_to_approvals: HashMap[uint256, address]

# @dev Mapping from owner address to ocount of its token
owner_to_nft_token_count: HashMap[address, uint256]

# @dev Mapping from owner address to mapping of operator addresses
owner_to_operators: HashMap[address, HashMap[address, bool]]

# @dev Mapping from NFT id to URI
id_to_uri: HashMap[uint256, String[1024]]

# @dev Address of minter, who can mint the token
minter: public(address)

name: public(String[32])

symbol: public(String[32])

base_uri: public(String[128])

token_id_counter: public(uint256)
# @dev Mapping of interface id to bool about whether or not ist supported
supported_interfaces: HashMap[bytes32, bool]

# @dev ERC165 interface ID
ERC165_INTERFACE_ID: constant(
    bytes32
) = 0x0000000000000000000000000000000000000000000000000000000001FFC9A7

# @dev ERC721 interface ID
ERC721_INTERFACE_ID: constant(
    bytes32
) = 0x0000000000000000000000000000000000000000000000000000000080AC58CD


@external
def __init__(_name: String[32], _symbol: String[32], _base_uri: String[128]):
    self.name = _name
    self.symbol = _symbol
    self.base_uri = _base_uri

    # self.supported_interfaces[ERC165_INTERFACE_ID] = True
    # self.supported_interfaces[ERC721_INTERFACE_ID] = True

    self.token_id_counter = 0
    self.minter = msg.sender

@view
@external
def supportsInterface(_interface_id: bytes32) -> bool:
    """
    @dev interface identification specified in ERC-165
    @param _interface_id of the interface
    """
    return self.supported_interfaces[_interface_id]


### VIEW FUNCTIONS ###

@view
@external
def balanceOf(_owner: address) -> uint256:
    assert _owner != ZERO_ADDRESS, "ERC721: balance query for the zero address"
    return self.owner_to_nft_token_count[_owner]


@view
@external
def ownerOf(_token_id: uint256) -> address:
    owner: address = self.id_to_owner[_token_id]
    assert owner != ZERO_ADDRESS, "ERC721: owner query for nonexistent token"
    return owner


@view
@external
def getApproved(_token_id: uint256) -> address:
    """
    @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
    """
    assert self.id_to_owner[_token_id] != ZERO_ADDRESS
    return self.id_to_approvals[_token_id]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    return (self.owner_to_operators[_owner])[_operator]


### TRANSFER FUNCTION HELPERS ###


@view
@internal
def _is_approved_or_owner(_spender: address, _token_id: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.id_to_owner[_token_id]
    spender_is_owner: bool = owner == _spender
    spender_is_approved: bool = _spender == self.id_to_approvals[_token_id]
    spender_is_approved_for_all: bool = (self.owner_to_operators[owner])[_spender]
    return (spender_is_owner or spender_is_approved) or spender_is_approved_for_all


@internal
def _add_token_to(_to: address, _token_id: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_tokenId` is owned by someone.
         Throws if `_to` is ZERO ADDRESS
    """
    assert self.id_to_owner[_token_id] == ZERO_ADDRESS, "ERC721: token already minted"
    assert _to != ZERO_ADDRESS, "ERC721: mint to the zero address"
    self.id_to_owner[_token_id] = _to
    self.owner_to_nft_token_count[_to] += 1


@internal
def _remove_token_from(_from: address, _token_id: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    assert self.id_to_owner[_token_id] == _from, "ERC721: caller is not owner"
    self.id_to_owner[_token_id] = ZERO_ADDRESS
    self.owner_to_nft_token_count[_from] -= 1


@internal
def _approve(_to: address, _tokenId: uint256, sender: address):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _to Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """
    owner: address = self.id_to_owner[_tokenId]
    assert (
        sender == owner or self.owner_to_operators[owner][sender]
    ), "ERC721: approve caller is not owner nor operator"
    self.id_to_approvals[_tokenId] = _to
    log Approval(owner, _to, _tokenId)


@internal
def _clear_approval(_token_id: uint256):
    """
    @dev Clear an approval of a given address
    """
    self._approve(ZERO_ADDRESS, _token_id, self.id_to_owner[_token_id])


@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    """
    @dev Exeute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `_to` is the zero address.
         Throws if `_from` is not the current owner.
         Throws if `_tokenId` is not a valid NFT.
    """

    assert self._is_approved_or_owner(
        _sender, _tokenId
    ), "ERC721: transfer caller is not owner nor approved"
    self._clear_approval(_tokenId)
    self._remove_token_from(_from, _tokenId)
    self._add_token_to(_to, _tokenId)
    log Transfer(_from, _to, _tokenId)


@internal
def _checkOnERC721Received(
    _from: address,
    _to: address,
    _token_id: uint256,
    _data: Bytes[1024],
    _sender: address,
) -> bool:
    if _to.is_contract:  # check if `_to` is a contract address
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert ERC721Receiver(_to).onERC721Received(
            _sender, _from, _token_id, _data
        ) == method_id(
            "onERC721Received(address,address,uint256,bytes)", output_type=bytes32
        ), "ERC721: transfer to non ERC721Receiver implementer"
    return True


### TRANSFER FUNCTIONS ###


@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)


@external
def safeTransferFrom(
    _from: address, _to: address, _tokenId: uint256, _data: Bytes[1024] = b""
):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
         If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    assert self._checkOnERC721Received(_from, _to, _tokenId, _data, msg.sender)



@external
def approve(_to: address, _tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _to Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """
    self._approve(_to, _tokenId, msg.sender)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @dev Enables or disables approval for a third party ("operator") to manage all of
         `msg.sender`'s assets. It also emits the ApprovalForAll event.
         Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    @notice This works even if sender doesn't own any tokens at the time.
    @param _operator Address to add to the set of authorized operators.
    @param _approved True if the operators is approved, false to revoke approval.
    """
    assert _operator != msg.sender, "ERC721: approve to caller/owner"
    self.owner_to_operators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


### MINT & BURN FUNCTIONS ###
# Taken from https://github.com/curvefi/curve-veBoost/blob/0e51be10638df2479d9e341c07fafa940ef58596/contracts/VotingEscrowDelegation.vy#L423
@pure
@internal
def _uint_to_string(_value: uint256) -> String[78]:
    # NOTE: Odd that this works with a raw_call inside, despite being marked
    # a pure function
    if _value == 0:
        return "0"

    buffer: Bytes[78] = b""
    digits: uint256 = 78

    for i in range(78):
        # go forward to find the # of digits, and set it
        # only if we have found the last index
        if digits == 78 and _value / 10 ** i == 0:
            digits = i

        value: uint256 = ((_value / 10 ** (77 - i)) % 10) + 48
        char: Bytes[1] = slice(convert(value, bytes32), 31, 1)
        buffer = raw_call(
            IDENTITY_PRECOMPILE,
            concat(buffer, char),
            max_outsize=78,
            is_static_call=True
        )

    return convert(slice(buffer, 78 - digits, digits), String[78])


@internal
def _tokenURI(_tokenId: uint256) -> String[256]:
    owner: address = self.id_to_owner[_tokenId]
    assert owner != ZERO_ADDRESS, "ERC721: owner query for nonexistent token"
    # return concat(self.base_URI, token_id, ".jpeg")
    return concat(self.base_uri, self._uint_to_string(_tokenId))


@internal
def _mint(_to: address, sender: address):
    assert sender == self.minter, "ERC721: caller is not allowed to mint"
    token_id: uint256 = self.token_id_counter
    self._add_token_to(_to, token_id)
    self.id_to_uri[token_id] = self._tokenURI(token_id)
    self.token_id_counter += 1
    log Transfer(ZERO_ADDRESS, _to, token_id)


@external
@view
def tokenURI(_tokenId: uint256) -> String[256]:
    owner: address = self.id_to_owner[_tokenId]
    assert owner != ZERO_ADDRESS, "ERC721: owner query for nonexistent token"
    # return concat(self.base_URI, token_id, ".jpeg")
    return concat(self.base_uri, self._uint_to_string(_tokenId))


@external
def mint(_to: address) -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
    @param _to The address that will receive the minted tokens.
    @return A boolean that indicates if the operation was successful.
    """
    self._mint(_to, msg.sender)
    return True


@external
def safeMint(_to: address, _data: Bytes[1024] = b"") -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
    @param _to The address that will receive the minted tokens.
    If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @return A boolean that indicates if the operation was successful.
    """
    token_id: uint256 = self.token_id_counter
    self._mint(_to, msg.sender)
    assert self._checkOnERC721Received(ZERO_ADDRESS, _to, token_id, _data, msg.sender)
    return True


@external
def burn(_token_id: uint256) -> bool:
    """
    @dev Burns a specific ERC721 token.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _token_id uint256 id of the ERC721 token to be burned.
    """
    owner: address = self.id_to_owner[_token_id]
    assert owner != ZERO_ADDRESS, "ERC721: operator query for nonexistent token"
    assert self._is_approved_or_owner(
        msg.sender, _token_id
    ), "ERC721: transfer caller is not owner nor approved"

    self._clear_approval(_token_id)
    self._remove_token_from(owner, _token_id)

    log Transfer(owner, ZERO_ADDRESS, _token_id)
    return True