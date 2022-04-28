# @version 0.3.3
# @dev Implementation of ERC-721 non-fungible token standard.
# @author pacdao.eth
# @license MIT
# Modified from: https://github.com/vyperlang/vyper/blob/de74722bf2d8718cca46902be165f9fe0e3641dd/examples/tokens/ERC721.vy

# This is an UNAUDITED implementation of an ERC721 contract.

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC721
implements: ERC165

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            operator: address,
            sender: address,
            tokenId: uint256,
            data: Bytes[1024]
        ) -> bytes32: view


event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004
MAX_SUPPLY: constant(uint256) = 1000

idToOwner: HashMap[uint256, address]
idToApprovals: HashMap[uint256, address]
ownerToNFTokenCount: HashMap[address, uint256]
ownerToOperators: HashMap[address, HashMap[address, bool]]

owner: public(address)
minter: public(address)

totalMinted: public(uint256)
totalBurned: uint256

NAME: immutable(String[32])
SYMBOL: immutable(String[32])

defaultURI: public(String[128])
baseURI: public(String[10])
goldURI: public(String[128])
customURI: HashMap[uint256, String[128]]
goldTokens: HashMap[uint256, bool]
contractStemURI: String[128]

# supported ERC165 interface IDs
SUPPORTED_INTERFACES: constant(bytes4[5]) = [
    0x01FFC9A7,  # ERC165
    0x80AC58CD,  # ERC721
    0x150B7A02,  # ERC721TokenReceiver
    0x5B5E139F,  # ERC721Metadata
    0x780E9D63,  # ERC721Enumerable
]


@external
def __init__(_name: String[32], _symbol: String[32]):
    self.owner = msg.sender
    self.minter = msg.sender
    NAME = _name
    SYMBOL = _symbol
    self.baseURI = "ipfs://"
    self.contractStemURI = "QmUKHs5tM2wikjce3EfzbjCBC738pzE5yXr9i29eSMf4R5"
    self.defaultURI = "QmQ7KYqYMfCtKUKUoVLw6Kane7ZZBZ7pNhffXUeVVyTyH7"
    self.goldURI = "QmPBmyenadjRNPJ4pfuejqJwGzPXxEMtd966qMUruznCk7"


@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES


### VIEW FUNCTIONS ###


@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]


@view
@external
def ownerOf(tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `tokenId` is not a valid NFT.
    @param tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[tokenId]
    # Throws if `tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS

    return owner


@view
@external
def getApproved(tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `tokenId` is not a valid NFT.
    @param tokenId ID of the NFT to query the approval of.
    """
    # Throws if `tokenId` is not a valid NFT
    assert self.idToOwner[tokenId] != ZERO_ADDRESS
    return self.idToApprovals[tokenId]


@view
@external
def isApprovedForAll(owner: address, operator: address) -> bool:
    """
    @dev Checks if `operator` is an approved operator for `owner`.
    @param owner The address that owns the NFTs.
    @param operator The address that acts on behalf of the owner.
    """
    return (self.ownerToOperators[owner])[operator]


### TRANSFER FUNCTION HELPERS ###


@view
@internal
def _isApprovedOrOwner(spender: address, tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[tokenId]
    spenderIsOwner: bool = owner == spender
    spenderIsApproved: bool = spender == self.idToApprovals[tokenId]
    spenderIsApprovedForAll: bool = self.ownerToOperators[owner][spender]

    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll


@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_tokenId` is owned by someone.
    """
    # Throws if `_tokenId` is owned by someone
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    # Change the owner
    self.idToOwner[_tokenId] = _to
    # Change count tracking
    self.ownerToNFTokenCount[_to] += 1


@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    # Throws if `_from` is not the current owner
    assert self.idToOwner[_tokenId] == _from
    # Change the owner
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    # Change count tracking
    self.ownerToNFTokenCount[_from] -= 1


@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """
    # Throws if `_owner` is not the current owner
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        # Reset approvals
        self.idToApprovals[_tokenId] = ZERO_ADDRESS


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
    # Check requirements
    assert self._isApprovedOrOwner(_sender, _tokenId)
    # Throws if `_to` is the zero address
    assert _to != ZERO_ADDRESS
    # Clear approval. Throws if `_from` is not the current owner
    self._clearApproval(_from, _tokenId)
    # Remove NFT. Throws if `_tokenId` is not a valid NFT
    self._removeTokenFrom(_from, _tokenId)
    # Add NFT
    self._addTokenTo(_to, _tokenId)
    # Log the transfer
    log Transfer(_from, _to, _tokenId)


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
    if _to.is_contract:  # check if `_to` is a contract address
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(
            msg.sender, _from, _tokenId, _data
        )
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id(
            "onERC721Received(address,address,uint256,bytes)", output_type=bytes32
        )


@external
def approve(_approved: address, _tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _approved Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    # Throws if `_approved` is the current owner
    assert _approved != owner
    # Check requirements
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert senderIsOwner or senderIsApprovedForAll
    # Set the approval
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)


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
    # Throws if `_operator` is the `msg.sender`
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


### MINT & BURN FUNCTIONS ###


@external
def mint(receiver: address, isGold: bool) -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
    @return A boolean that indicates if the operation was successful.
    """
    assert msg.sender == self.minter or msg.sender == self.owner # dev: Only Admin
    assert receiver != empty(address) # dev: Cannot mint to empty address
    assert self.totalMinted < MAX_SUPPLY # dev: Minted must be less than MAX_SUPPLY

    tokenId: uint256 = self.totalMinted
    # Add NFT. Throws if `_tokenId` is owned by someone
    self._addTokenTo(receiver, tokenId)
    log Transfer(empty(address), receiver, tokenId)
    self.totalMinted += 1
    if isGold:
        self.goldTokens[tokenId] = True
    return True


@external
def transferMinter(newAddr: address):
    """
    @dev Update the address authorized to mint (Admin only)
    @param newAddr New minter address
    """

    assert msg.sender == self.owner or msg.sender == self.minter  # dev: Only Admin
    self.minter = newAddr



#@external
#def burn(tokenId: uint256) -> bool:
#    """
#    @dev Burns a specific ERC721 token.
#         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
#         address for this NFT.
#         Throws if `tokenId` is not a valid NFT.
#    @param tokenId uint256 id of the ERC721 token to be burned.
#    """
#    # Check requirements
#    assert self._isApprovedOrOwner(msg.sender, tokenId)
#    
#    owner: address = self.idToOwner[tokenId]
#
#    # Throws if `tokenId` is not a valid NFT
#    assert owner != empty(address)
#
#    self._clearApproval(owner, tokenId)
#    self._removeTokenFrom(owner, tokenId)
#
#    log Transfer(owner, empty(address), tokenId)
#
#    return True


@external
@view
def name() -> String[32]:
    return NAME


@external
@view
def symbol() -> String[32]:
    return SYMBOL


@internal
@pure
def _uint_to_string(_value: uint256) -> String[78]:
    if _value == 0:
        return "0"

    buffer: Bytes[78] = b""
    digits: uint256 = 78

    for i in range(78):
        # go forward to find the # of digits, and set it
        # only if we have found the last index
        if digits == 78 and _value / 10 ** i == 0:
            digits = i

        val: uint256 = ((_value / 10 ** (77 - i)) % 10) + 48
        char: Bytes[1] = slice(convert(val, bytes32), 31, 1)
        buffer = raw_call(
            IDENTITY_PRECOMPILE,
            concat(buffer, char),
            max_outsize=78,
            is_static_call=True,
        )

    return convert(slice(buffer, 78 - digits, digits), String[78])


### ERC721-METADATA FUNCTIONS ###


@external
@view
def tokenURI(tokenId: uint256) -> String[138]:
    if self.customURI[tokenId] != "":
        return self.customURI[tokenId]
    elif self.goldTokens[tokenId] == True:
        return concat(self.baseURI, self.goldURI)
    else:
        return concat(self.baseURI, self.defaultURI)


@external
@view
def contractURI() -> String[138]:
    return concat(self.baseURI, self.contractStemURI)


@internal
@view
def _exists(tokenId: uint256) -> bool:
    if tokenId >= self.totalMinted:
        return False

    if self.idToOwner[tokenId] == ZERO_ADDRESS:
        return False

    return True


@external
def setTokenURI(tokenId: uint256, newURI: String[128]):
    assert msg.sender == self.owner or msg.sender == self.minter  # dev: Only Admin
    assert self._exists(tokenId)
    self.customURI[tokenId] = newURI


@external
def setContractURI(newURI: String[128]):
    assert msg.sender == self.owner or msg.sender == self.minter  # dev: Only Admin
    self.contractStemURI = newURI


@external
def setDefaultMetadata(newURI: String[128]):
    assert msg.sender == self.owner or msg.sender == self.minter # dev: Only Admin
    self.defaultURI = newURI


### ERC721-OWNABLE FUNCTIONS ###


@external
def transferOwner(newAddr: address):
    assert msg.sender == self.owner  # dev: Only Owner
    self.owner = newAddr


### ERC721-ENUMERABLE FUNCTIONS ###


@external
@view
def totalSupply() -> uint256:
    return self.totalMinted - self.totalBurned


@external
@view
def tokenByIndex(index: uint256) -> uint256:
    counter: uint256 = 0
    for i in range(MAX_SUPPLY):
        if self.idToOwner[i] != ZERO_ADDRESS:
            if counter == index:
                return i
            counter += 1
        if i > self.totalMinted:
            assert False, "ERC721Enumerable: global index out of bounds"

    assert False, "ERC721Enumerable: global index out of bounds"
    return 0


@external
@view
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
    counter: uint256 = 0
    for i in range(MAX_SUPPLY):
        if self.idToOwner[i] == owner:
            if counter == index:
                return i
            counter += 1

        if i > self.totalMinted:
            assert False, "ERC721Enumerable: global index out of bounds"

    assert False, "ERC721Enumerable: global index out of bounds"
    return 0