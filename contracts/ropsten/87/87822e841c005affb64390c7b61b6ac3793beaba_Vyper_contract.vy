# @version 0.3.3

from vyper.interfaces import ERC721
from vyper.interfaces import ERC165

implements: ERC721
implements: ERC165


# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view

interface AddressValidator:
    def isValidContract(_bookName: String[16], _addressName: String[16]) -> bool: view


# EVENTS
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

event BookCreation:
    owner: indexed(address)
    tokenId: indexed(uint256)
    bookName: String[16]
    _timestamp: uint256

event AddressSetup:
    owner: indexed(address)
    tokenId: indexed(uint256)
    bookName: String[16]
    addressName: String[16]
    _timestamp: uint256


# STORAGE
idToApprovals: HashMap[uint256, address]
ownerToOperators: HashMap[address, HashMap[address, bool]]
ownerOf: public(HashMap[uint256, address])
balanceOf: public(HashMap[address, uint256])

# ERC721Metadata Interface
name: public(String[32])
symbol: public(String[32])
tokenUri: public(String[128])

totalSupply: public(uint256)
ownerTokenAt: HashMap[address, HashMap[uint256, uint256]]

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    # ERC165 interface ID of ERC165
    0x01ffc9a7,
    # ERC165 interface ID of ERC721
    0x80ac58cd,
]

pendingOwner: public(address)
owner: public(address)

minPrice: public(uint256)

bookId: public(HashMap[String[16], uint256])
bookName: public(HashMap[uint256, String[16]])
dAddressOf: public(HashMap[String[16], HashMap[String[16], address]])


@external
def __init__(_name: String[32], _symbol: String[32], _tokenUri: String[128], _minPrice: uint256):
    self.name = _name
    self.symbol = _symbol
    self.tokenUri = _tokenUri
    self.owner = msg.sender
    self.minPrice = _minPrice

@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES


@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.ownerOf[_tokenId] != ZERO_ADDRESS
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
    owner: address = self.ownerOf[_tokenId]
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
    assert self.ownerOf[_tokenId] == ZERO_ADDRESS
    # Change the owner
    self.ownerOf[_tokenId] = _to
    # Change count tracking
    self.ownerTokenAt[_to][self.balanceOf[_to]] =_tokenId
    self.balanceOf[_to] += 1

@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    # Throws if `_from` is not the current owner
    assert self.ownerOf[_tokenId] == _from
    # Change the owner
    self.ownerOf[_tokenId] = ZERO_ADDRESS
    # Change count tracking
    self.balanceOf[_from] -= 1
    
    found: bool = False    
    for i in range(MAX_UINT256):
        if i == self.balanceOf[_from]:
            break
        
        value: uint256 = self.ownerTokenAt[_from][i]
        if _tokenId == self.ownerTokenAt[_from][i]:
            found = True
        if found:
            value = self.ownerTokenAt[_from][i+1]
        self.ownerTokenAt[_from][i] = value
    
    self.ownerTokenAt[_from][self.balanceOf[_from]] = 0

@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """
    # Throws if `_owner` is not the current owner
    assert self.ownerOf[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        # Reset approvals
        self.idToApprovals[_tokenId] = ZERO_ADDRESS

@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    """
    @dev Exeute transfer of a NFT.
         Throws if contract is paused.
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
    owner: address = self.ownerOf[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    # Throws if `_approved` is the current owner
    assert _approved != owner
    # Check requirements
    senderIsOwner: bool = self.ownerOf[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
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


@view
@external
def tokenByIndex(index: uint256) -> uint256:
    """
    @dev Returns the token ID of the token at the given index.
    @param index The index of the token.
    @return The token ID of the token at the given index.
    """
    assert index >= 0 and index <= self.totalSupply
    return index


@view
@external
def tokenOfOwnerByIndex(_owner: address, index: uint256) -> uint256:
    assert self.balanceOf[_owner] > index
    return self.ownerTokenAt[_owner][index]


@payable
@external
def mint(_to: address, _bookName: String[16]) -> uint256:
    """
    @dev Function to mint tokens
    """

    assert _bookName != "", "Book name cannot be empty"
    assert self.bookId[_bookName] == 0, "Book name already taken"
    assert self.minPrice <= msg.value, "Value sent is not enough"

    self.totalSupply += 1
    tokenId: uint256 = self.totalSupply

    self.ownerOf[tokenId] = _to
    self.bookId[_bookName] = tokenId
    self.bookName[tokenId] = _bookName

    self.ownerTokenAt[_to][self.balanceOf[_to]] = tokenId
    self.balanceOf[_to] += 1

    log Transfer(ZERO_ADDRESS, _to, tokenId)
    log BookCreation(_to, tokenId, _bookName, block.timestamp)
    
    return tokenId


@external
def updateTokenUri(_tokenUri: String[128]):
    """
    @dev Function to update the base URI of a token
    """
    assert msg.sender == self.owner
    self.tokenUri = _tokenUri


@external
def updateOwner(_owner: address):
    """
    @dev Function to update the owner of the contract
    """
    assert msg.sender == self.owner
    self.pendingOwner = _owner


@external
def acceptOwnership():
    """
    @dev Function to accept the ownership of the contract
    """
    assert msg.sender == self.pendingOwner
    self.owner = self.pendingOwner
    self.pendingOwner = ZERO_ADDRESS


@external
def updateMinPrice(_minPrice: uint256):
    """
    @dev Function to update the minimum price to mint a token
    """
    assert msg.sender == self.owner
    self.minPrice = _minPrice


@external
def setAddress(_bookName: String[16], _addressName: String[16], _address: address, _shouldValidate: bool = False):
    """
    @dev Function to set an address
    """
    tokenId: uint256 = self.bookId[_bookName]
    
    assert tokenId > 0, 'Invalid Address Book'
    assert self._isApprovedOrOwner(msg.sender, tokenId)

    if _shouldValidate and _address.is_contract:
        assert AddressValidator(_address).isValidContract(_bookName, _addressName) == True

    self.dAddressOf[_bookName][_addressName] = _address
    
    log AddressSetup(self.ownerOf[tokenId], tokenId, _bookName, _addressName, block.timestamp)


@view
@external
def validateContract(_bookName: String[16], _addressName: String[16]) -> bool:
    """
    @dev Function to verify if a contract implements the AddressValidator interface
    """
    _address: address = self.dAddressOf[_bookName][_addressName]

    assert _address.is_contract, "Not a contract"
    assert AddressValidator(_address).isValidContract(_bookName, _addressName) == True, "Not valid"

    return True


@nonpayable
@external
def withdraw():
    """
    @dev Function to withdraw the contract balance to the contract owner
    """
    send(self.owner, self.balance)