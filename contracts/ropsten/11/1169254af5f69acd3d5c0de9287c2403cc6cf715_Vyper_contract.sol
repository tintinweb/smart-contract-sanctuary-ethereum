# @version ^0.2.16
"""
@title PACDAO/LEXPUNK ACTION
@author pacdao.eth
@license MIT
"""

from vyper.interfaces import ERC721

implements: ERC721


merkle_root: bytes32 
owner: public(address)
counter: public(uint256)

# ERC721 Variables
_contractURI: String[64]


# @dev ERC165 interface ID of ERC165
ERC165_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000001ffc9a7


# @dev ERC615 interface ID of ERC615
ERC615_INTERFACE_ID: constant(bytes32) = 0x000000000000000000000000000000000000000000000000000000005b5e139f


# @dev ERC165 interface ID of ERC721
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd


name: public(String[64])
symbol: public(String[64])
_baseURI: String[64] 
_defaultURI: String[64]

# INTERNAL FUNCTIONS

@internal
@view
def _calcMerkleRoot(_leaf: bytes32, _index: uint256, _proof: bytes32[10]) -> bytes32:
    """
    @dev Compute the merkle root
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bytes32 Computed root of the Merkle tree.
    """
    computedHash: bytes32 = _leaf
    index: uint256 = _index

    for proofElement in _proof:
        if proofElement != 0x0000000000000000000000000000000000000000000000000000000000000000:
                if index % 2 == 0:
                        computedHash = keccak256(concat(computedHash, proofElement))
                else:
                        computedHash = keccak256(concat(proofElement, computedHash))
                index /= 2
    
    return computedHash


# CONSTRUCTOR

@external
def __init__(): 
    """
    @notice Contract constructor
    """
    self.owner = msg.sender
    self.minter = msg.sender
    self.name = "PACDAO/LEXPUNK ACTION"
    self.symbol = "PACLEX-A1"

    self._baseURI = "ipfs://"
    self._defaultURI = "QmPthQZ6tiqaUoXGRPRpAvFQcg9ALPtJ8wesWccYrqKy16"
    self._contractURI = "QmSzCP9KJBSjvmqoPt7Fjm21bDsC6BVtyKeRCi5tRkLwgT"
    self.merkle_root = 0x1ed1b1f3afb572d18a80eda8e4b687e1fc751e44175cca5b45b7e68ca5a7731c


# EXTERNAL FUNCTIONS

@external
@view
def totalSupply() -> uint256:
    return self.counter 

# ERC721 Functionality
@external
@view
def balanceOf(hodler: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `hodler`.
         Throws if `hodler` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param hodler Address for whom to query the balance.
    """

    assert hodler != ZERO_ADDRESS, "ERC721: balance query for the zero address"
    return self.ownerToNFTokenCount[hodler]


@external
@view
def ownerOf(seat_id: uint256) -> address:
    owner: address = self.idToOwner[seat_id]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    return owner

@external
@view
def contractURI() -> String[64]:
    return self._contractURI


@external
@view
def tokenURI(token_id : uint256) -> String[128]:
    assert self.idToOwner[token_id] != ZERO_ADDRESS, "Invalid NFT"
    return concat(self._baseURI, self._defaultURI)


@external
@view
def defaultURI() -> String[64]:
    return self._defaultURI

@external
def setDefaultURI(new_default: String[64]):
    assert msg.sender == self.owner
    self._defaultURI = new_default


@external
@view
def baseURI() -> String[64]:
    return self._baseURI

@external
def setBaseURI(new_base: String[64]):
    assert msg.sender == self.owner
    self._baseURI = new_base



# Copy of prior interface
# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view

# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param _from Sender of NFT (if address is zero address it indicates token creation).
# @param _to Receiver of NFT (if address is zero address it indicates token destruction).
# @param _tokenId The NFT that got transfered.
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _tokenId NFT which we are approving.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)


event Byt:
    byt: bytes32

# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# @dev Tokens Internal Array
EnumerableTokens: HashMap[uint256, uint256]

# @dev Tokens Owners Array
EnumerableOwnedTokens: HashMap[address, HashMap[uint256, uint256]]

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]

# @dev Mapping from NFT ID to approved address.
idToApprovals: public(HashMap[uint256, address])

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: HashMap[address, uint256]

# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]

# @dev Address of minter, who can mint a token
minter: address

@external
def debut(byt: bytes32):
    log Byt(byt)

@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param _interfaceID Id of the interface
    """
    if _interfaceID in [ERC165_INTERFACE_ID, ERC615_INTERFACE_ID, ERC721_INTERFACE_ID]:
        return True
    else:
        return False



### VIEW FUNCTIONS ###

@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS, "Invalid NFT"
    return self.idToApprovals[_tokenId]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @dev Checks if `_operator` is an approved operator for `_owner`.
    @param _owner The address that owns the NFTs.
    @param _operator The address that acts on behalf of the owner.
    """
    return (self.ownerToOperators[_owner])[_operator]


### ENUMERABLE FUNCTIONS ###

@view
@external
def tokenByIndex(_index: uint256) -> (uint256):
    """    
    @notice Enumerate valid NFTs
    @dev Throws if `_index` >= `totalSupply()`.
    @param _index A counter less than `totalSupply()`
    @return The token identifier for the `_index`th NFT,  (sort order not specified)
    """

    assert _index < self.counter, "Invalid number"
    return self.EnumerableTokens[_index]

@view
@external
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> (uint256):
    """   
    @notice Enumerate NFTs assigned to an owner
    @dev Throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address, representing invalid NFTs.
    @param _owner An address where we are interested in NFTs owned by them
    @param _index A counter less than `balanceOf(_owner)`
    @return The token identifier for the `_index`th NFT assigned to `_owner`, (sort order not specified)
    """

    assert _index < self.ownerToNFTokenCount[_owner]
    return self.EnumerableOwnedTokens[_owner][_index]



### TRANSFER FUNCTION HELPERS ###

@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
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
    self.EnumerableTokens[self.counter] = _tokenId
    self.EnumerableOwnedTokens[_to][self.ownerToNFTokenCount[_to]] = _tokenId

    # Change count tracking
    self.ownerToNFTokenCount[_to] += 1
    self.counter += 1


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
    assert self._isApprovedOrOwner(_sender, _tokenId), "Lacks Approval"
    # Throws if `_to` is the zero address
    assert _to != ZERO_ADDRESS, "Cannot Transfer to NULL"

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
        _from: address,
        _to: address,
        _tokenId: uint256,
        _data: Bytes[1024]=b""
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
    if _to.is_contract: # check if `_to` is a contract address
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)


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
    assert owner != ZERO_ADDRESS, 'Invalid NFT'

    # Throws if `_approved` is the current owner
    assert _approved != owner, "Owner Approval"
    
    # Check requirements
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    log ApprovalForAll(msg.sender, msg.sender, senderIsOwner)
    assert (senderIsOwner or senderIsApprovedForAll), "Lacks Approval"
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
def mint(leaf: bytes32, index: uint256, proof: bytes32[10]):
    assert self._calcMerkleRoot(leaf, index - (index / 1000 * 1000), proof) == self.merkle_root, "Invalid Hash"
    self._addTokenTo(msg.sender, index)
    log Transfer(ZERO_ADDRESS, msg.sender, index)

@external
def mint_for(_to: address, _tokenId: uint256) -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
    @param _to The address that will receive the minted tokens.
    @param _tokenId The token id to mint.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _to != ZERO_ADDRESS
    # Add NFT. Throws if `_tokenId` is owned by someone
    self._addTokenTo(_to, _tokenId)

    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True


@external
def burn(_tokenId: uint256):
    """
    @dev Burns a specific ERC721 token.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId uint256 id of the ERC721 token to be burned.
    """
    # Check requirements
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)



@external
@view
def calcMerkleRoot(_leaf: bytes32, _index: uint256, _proof: bytes32[10]) -> bytes32:
    """
    @dev Compute the merkle root
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree, which starts with 1.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bytes32 Computed root of the Merkle tree.
    """
    return self._calcMerkleRoot(_leaf, _index, _proof)


@external
@view
def verifyMerkleProof(_leaf: bytes32, _index: uint256, _rootHash: bytes32, _proof: bytes32[10]) -> bool:
    """
    @dev Checks that a leaf hash is contained in a root hash.
    @param _leaf Leaf hash to verify.
    @param _index Position of the leaf hash in the Merkle tree, which starts with 1.
    @param _rootHash Root of the Merkle tree.
    @param _proof A Merkle proof demonstrating membership of the leaf hash.
    @return bool whether the leaf hash is in the Merkle tree.
    """
    return self._calcMerkleRoot(_leaf, _index, _proof) == _rootHash