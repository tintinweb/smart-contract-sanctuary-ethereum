# @title ERC-721 NFT token implementation for nft marketplace
# @dev ERC-721 Token




from vyper.interfaces  import ERC721

implements: ERC721

# Interface to answer requests of 'safeTransferFrom()' from another NFT contract
interface ERC721Receiver:
    def onERC721Received(_operator : address, _from : address, _tokenId : uint256, _data : Bytes[1024]) -> bytes32:view

# Events

# @dev Emits when ownership of NFT changes, and when new nft are created or destroyed
# @param _from The sender of the NFT
# @param _to The receiver of the NFT
# @param _tokenId The NFT that got transferred

event Transfer:
    sender : indexed(address)
    receiver :indexed(address)
    tokenId : indexed(uint256)


# @dev Emits when the approved address for an NFT is changed or reaffirmed. 
# @dev When a Transfer event emits, this also indicates that the approved address for the NFT has been reset to none
# @param _owner Owner of NFT
# @param _approved Address which we are approving 
# @param _tokenId NFT we are approving 
event Approval:
    owner  :indexed(address)
    approved  :indexed(address)
    tokenId  :indexed(uint256)


# @dev This emits when an operator is enabled or disabled for an owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool



# State Variables

idToOwner : HashMap[uint256, address]
idToApprovals  : HashMap[uint256, address]
ownerToNFTokenCount : HashMap[address, uint256]
ownerToOperators : HashMap[address,HashMap[address,bool]]
minter : address
extraMinters : HashMap[address,bool]
name : public(String[16]) 
tokenURI : public(HashMap[uint256, String[256]])

supportedInterfaces : HashMap[bytes32, bool]
ERC165_INTERFACE_ID : constant(bytes32) =    0x0000000000000000000000000000000000000000000000000000000001ffc9a7
ERC721_INTERFACE_ID: constant(bytes32) = 0x0000000000000000000000000000000000000000000000000000000080ac58cd


# Functions 
@external
def __init__():
    self.supportedInterfaces[ERC165_INTERFACE_ID] = True
    self.supportedInterfaces[ERC721_INTERFACE_ID] = True
    self.minter = msg.sender
    self.name = "NeftySea NFT"

@view
@external
def supportsInterface( _interfaceID  : bytes32) -> bool  :
    return self.supportedInterfaces[_interfaceID]


# @dev Returns the number of NFTs owned by _owner
@view
@external
def balanceOf( _owner : address)->uint256:
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]


# @dev Returns of the owner of NFT with _tokenId
@view
@external
def ownerOf(_tokenId : uint256) -> address:
    owner  :address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    return owner


# @dev Returns the operator for a single NFT with _tokenId
@view
@external
def getApproved(_tokenId : uint256)-> address:
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]


# @dev Checks if _operator is an approved operator of _owner
@view
@external
def isApprovedForAll(_owner: address, _operator  :address)->bool:
    return (self.ownerToOperators[_owner])[_operator]


#### TRANSFER FUNCTION HELPERS ####

@internal
def _isApprovedOrOwner( _spender : address, _tokenId  :uint256)-> bool:
    owner : address = self.idToOwner[_tokenId]
    spenderIsOwner : bool = owner == _spender
    spenderIsApproved : bool = self.idToApprovals[_tokenId] == _spender
    spenderIsApprovedForAll : bool =( self.ownerToOperators[owner])[_spender]
    return ( spenderIsOwner or spenderIsApproved or spenderIsApprovedForAll)

@internal
def _addTokenTo( _to : address, _tokenId : uint256):
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    self.idToOwner[_tokenId] = _to
    self.ownerToNFTokenCount[_to] += 1

@internal
def _removeTokenFrom( _from : address, _tokenId : uint256):
    assert self.idToOwner[_tokenId] == _from
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    self.ownerToNFTokenCount[_from] -= 1

@internal
def _clearApproval(_owner: address, _tokenId : uint256):
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
        self.idToApprovals[_tokenId] = ZERO_ADDRESS


@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    assert self._isApprovedOrOwner(_sender, _tokenId)
    assert _to != ZERO_ADDRESS
    self._clearApproval(_from, _tokenId)
    self._removeTokenFrom(_from, _tokenId)
    self._addTokenTo(_to, _tokenId)
    log Transfer(_from, _to, _tokenId)


### TRANSFER FUNCTIONS ###

@external
def transferFrom( _from : address, _to : address, _tokenId : uint256 ):
    self._transferFrom( _from, _to, _tokenId, msg.sender)


@external
def safeTransferFrom( _from : address, _to  :address, _tokenId : uint256, _data : Bytes[1024]=b""):
    self._transferFrom( _from  , _to, _tokenId, msg.sender)
    if _to.is_contract :
        returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)


@external
def approve( _approved : address, _tokenId : uint256):
    owner : address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    assert _approved != owner

    senderIsOwner : bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll : bool  = (self.ownerToOperators[owner])[msg.sender]
    assert ( senderIsOwner or senderIsApprovedForAll)

    self.idToApprovals[_tokenId] = _approved
    log Approval(owner,_approved,_tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)



### MINT AND DESTROY ###

@external
def mint( _to : address, _tokenId : uint256, _tokenURI : String[256]) -> bool :
    # assert ( self.minter == msg.sender  or self.extraMinters[msg.sender])
    assert _to != ZERO_ADDRESS
    assert _to == msg.sender, 'You can only mint for yourself'
    self._addTokenTo(_to, _tokenId)
    self.tokenURI[_tokenId] = _tokenURI
    log Transfer( ZERO_ADDRESS, _to, _tokenId )
    return True


@external
def burn(_tokenId: uint256):
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)

@external
def addMinter( _minter : address ):
    assert self.minter == msg.sender
    assert _minter != ZERO_ADDRESS
    self.extraMinters[_minter] = True