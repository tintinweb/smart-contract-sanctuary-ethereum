# @version 0.3.3
"""
@title Vyper NFT
@license MIT
@author Jasper
@notice ERC721 vyper impl with a variation of a dutch auction
"""

from vyper.interfaces import ERC721

implements: ERC721

interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
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

_name: String[32]
_symbol: String[32]
baseURI: String[128]

idToOwner: HashMap[uint256, address]
idToApprovals: HashMap[uint256, address]
ownerToTokenCount: HashMap[address, uint256]
ownerToOperators: HashMap[address, HashMap[address, bool]]

royaltyFee: uint256

currentId: uint256 

dev: address
artist: address

MAX_PURCHASE: constant(uint256) = 5
MAX_ID: constant(uint256) = 1000

IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004

SUPPORTED_INTERFACES: constant(bytes4[4]) = [
                      0x01ffc9a7, #ERC 165
                      0x80ac58cd, #ERC 721
                      0x5b5e139f, #ERC 721 Metadata
                      0x2a55205a, #ERC 2981
]     

@external
def __init__():
    self.dev = msg.sender
    self.artist = msg.sender
    self.currentId = 1
    self.lastPurchaseBlock = block.number
    self._name = "VyperNFT"
    self._symbol = "VyNFT"
    self.baseURI = "QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq"
    self.royaltyFee = 200 # 200 / 10000 = 2%
    self.lastPrice = 1000000000000000000

#ERC165
#https://eips.ethereum.org/EIPS/eip-165
@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev https://eips.ethereum.org/EIPS/eip-165
    @param interface_id The interface identifier, as specified in ERC-165
    """
    return interface_id in SUPPORTED_INTERFACES

#ERC721
#https://eips.ethereum.org/EIPS/eip-721
@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @notice Count all NFTs assigned to '_owner'
    @dev NFTs assigned to the zero address are considered invalid and this function throws for queries of the zero address
    @param _owner an address to query 
    @return The number of NFTs assigned to '_owner' 
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToTokenCount[_owner]

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @notice Find who owns the NFT with id '_tokenId'
    @dev NFTs assigned to the zero address are considered invalid and this function throws if owner is zero address
    @param _tokenId the unique identifier for each NFT
    @return The address who owns the NFT with id '_tokenId'
    """
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    return owner

@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @notice Get the approved address for the NFT with id '_tokenId'
    @dev Throws if not a valid NFT
    @param _tokenId the unique identifier for each NFT
    @return The approved address for this NFT, will be the zero address if none are approved
    """
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToApprovals[_tokenId]

@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @notice Query if an address is an authorized operator for another address
    @param _owner the address that owns the NFT
    @param _operator the address the acts on behalf of the owner
    @return True if '_operator' is an approved operator for '_owner', false otherwise
    """
    return (self.ownerToOperators[_owner])[_operator]

@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    """
    @notice Transfer ownership of NFT from address '_from' to address '_to'
    @dev Throws unless msg.sender is the owner, an authorized operator, or the approved address for this NFT.
         Throws if '_from' is not the current owner.
         Throws if '_to' is the zero address.
         Throws if '_tokenId' is not a valid NFT.
         Emits Transfer event
    @param _from the current owner of the NFT
    @param _to the new owner 
    @param _tokenId the NFT to transfer
    @param _sender sender of the transaction 
    """
    owner: address = self.idToOwner[_tokenId]
    senderIsOwner: bool = owner == _sender
    senderIsApproved: bool = _sender == self.idToApprovals[_tokenId]
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_sender]
    assert (senderIsOwner or senderIsApproved) or senderIsApprovedForAll
    assert _to != ZERO_ADDRESS
    if self.idToApprovals[_tokenId] != ZERO_ADDRESS:
       self.idToApprovals[_tokenId] = ZERO_ADDRESS
    assert _from == owner
    self.ownerToTokenCount[_from] -= 1
    self.ownerToTokenCount[_to] += 1
    self.idToOwner[_tokenId] = _to
    log Transfer(_from, _to, _tokenId)

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @notice Transfer ownership of NFT from address '_from' to address '_to'
    @dev Throws unless msg.sender is the owner, an authorized operator, or the approved address for this NFT.
         Throws if '_from' is not the current owner.
         Throws if '_to' is the zero address.
         Throws if '_tokenId' is not a valid NFT.
         Emits Transfer event
    @param _from the current owner of the NFT
    @param _to the new owner 
    @param _tokenId the NFT to transfer
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)

@external
def safeTransferFrom(_from: address, _to: address, _tokenId: uint256, _data: Bytes[1024] = b""):
    """
    @notice Transfers ownership of an NFT from address '_from' to address '_to'
    @dev Same throws as transferFrom.
         After transfer this function checks if '_to' is a smart contract. If so it calls 'onERc721received' on '_to' and throws if the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
         NOTE: bytes4 is represented by bytes32 with padding
         Emits Transfer event
    @param _from the current owner of the NFT
    @param _to the new owner of the NFT
    @param _tokenId the NFT to transfer 
    @param _data Additional data with no specified format, sent in call to '_to'
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    
    if _to.is_contract:
       returnValue: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
       assert returnValue == method_id("onERc721received(address,address,uint256,bytes)", output_type=bytes32)

@external
def approve(_approved: address, _tokenId: uint256):
    """
    @notice Change or reaffirm the approved address for an NFT
    @dev The zero address indicates there is no approved address.
         Throws unless 'msg.sender' is the current NFT owner, or an authorized operator of the current owner.
         Throws if '_tokenId' is not a valid NFT
         Throws if '_approved' is the owner
         Emits Approval event 
    @param _approved the new approved NFT controller
    @param _tokenId the NFT to approve 
    """
    owner: address = self.idToOwner[_tokenId]
    assert owner != ZERO_ADDRESS
    assert _approved != owner
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)
    
@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @notice Enable or disable approval for a third party ("operator") to manage all NFTs owned by 'msg.sender'
    @dev Allows for multiple operators per owner.
         Throws if '_operator' is 'msg.sender'
         Emits ApprovalForAll event
    @param _operator address to add to the set of authorized operators
    @param _approved True if operator is to be approved, false to revoke approval
    """
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)

@internal
def _mint(_to: address):
    """
    @notice Mints an NFT
    @dev owners token balance is updated in the purchaseTokens function  
    @param _to the owner of the freshly minted NFT
    """
    self.idToOwner[self.currentId] = _to
    self.currentId += 1

#needed for metadata
@pure
@internal
def _uint_to_string(_value: uint256) -> String[78]:
    """
    @notice turns a uint256 into a String
    @dev thank you @skellet0r
    @param _value the uint256 to be converted into a String
    @return The String representation of '_value'
    """
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

#ERC721 Metadata extension
@view
@external
def name() -> String[32]:
    """
    @notice full name of this NFT collection
    """
    return self._name

@view
@external
def symbol() -> String[32]:
    """
    @notice Abbreviated name of this NFT collection
    """
    return self._symbol

@view
@external
def tokenURI(id: uint256) -> String[214]:
    """
    @notice A distinct Uniform Resource Identifier (URI) for each NFT in this collection
    @dev Throws if 'id' is not a valid NFT
    """
    assert id <= self.currentId
    tokenId: String[78] = self._uint_to_string(id)
    uri: String[214] = concat("ipfs://", self.baseURI, "/" ,tokenId)
    return uri

@view
@external
def totalSupply() -> uint256:
    """
    @notice The number of NFTs tracked by this contract
    @return A count of valid NFTs tracked by this contact, 
            where each one of them has an assigned and queryable owner not equal to the zero address     
    """
    return self.currentId

#ERC2981 NFT royalty standard
#https://eips.ethereum.org/EIPS/eip-2981
@view
@external
def royaltyInfo(_tokenId: uint256, _salePrice: uint256) -> (address, uint256):
    """
    @notice Called with the sale price to determine how much royalty is owed and to whom.
    @param _tokenId The NFT queried for royalty information
    @param _salePrice The sale price of the NFT specified by '_tokenId'
    @return receiver Address who should be sent royalty payment
    @return royaltyAmount The royalty payment amount for '_salePrice' 
    """
    receiver: address = self.dev
    royaltyAmount: uint256 = _salePrice * self.royaltyFee / 10000
    return (receiver, royaltyAmount)

#nft distribution logic 
@external
def devMint():
    """
    @notice mint some NFTs for the team.
    @dev throws if 'msg.sender' is not the dev.
         throws if mint amount is greater than number of NFTs still available in this collection
    """
    assert msg.sender == self.dev
    assert self.currentId + 200 <= MAX_ID  
    for i in range(200):
       self._mint(self.dev)
    self.ownerToTokenCount[self.dev] = 200
    
lastPurchaseBlock: uint256
lastPrice: uint256
MIN_PRICE: constant(uint256) = 100000000000000000
PRICE_TICK: constant(uint256) = 100000000000000000
#inspired by https://www.paradigm.xyz/2022/04/gda    
@view
@internal
def _purchasePrice(numTokens: uint256) -> uint256[2]:
    """
    @notice Calculates the purchase price for an amount of tokens
`   @dev Throws if 'numTokens' is 0,
         Throws if 'numTokens' is greater than maximum purchase amount.
         blocksElapsed is calculated from the last token purchase.
         The price decreases by 'PRICE_TICK' every 10 blocksElapsed down to a minimum of 'MIN_PRICE'.
         The price increases by 'PRICE_TICK' with every NFT purchase 
    @param numTokens the amount of tokens to calculate the purchase price for
    @return The total price for 'numtokens' being purchased and the price of the last NFT in 'numTokens'
    """
    assert numTokens >= 1 and numTokens <= MAX_PURCHASE
    blocksElapsed: uint256 = block.number - self.lastPurchaseBlock
    price: uint256 = self.lastPrice
    decay: uint256 = PRICE_TICK * (blocksElapsed / 10) #decay one price tick every ten blocks
    if (decay >= price):
       price = MIN_PRICE
    if (decay < price):
       if ((price - decay) > MIN_PRICE):
          price -= decay
       else:
          price = MIN_PRICE
          
    totalPrice: uint256 = 0
    for i in range(MAX_PURCHASE):
        if (i >= numTokens):
           break
        totalPrice += price
        price += PRICE_TICK
        
    return [totalPrice, price]


@view
@external
def purchasePrice(numTokens: uint256) -> uint256:
   """
   @notice Calculates the purchase price for an amount of tokens
   @dev same as _purchasePrice
   @param numTokens the amount of tokens to calculate the purchase price for
   @return The price of 'numTokens' NFTs
   """
   priceData: uint256[2] = self._purchasePrice(numTokens)
   return priceData[0]

@external
@payable
@nonreentrant("lock")
def purchaseTokens(numTokens: uint256, to: address):
    """
    @notice purchase some NFTs
    @dev Throws if 'msg.value' is less than the purchase price of 'numTokens'.
         Throws if trying to purchase more NFTs than are available.
         Same throws as _purchasePrice.
         Any ether sent greater than the purchase price is refunded.
    @param numTokens the number of NFTs to purchase
    @param to The address that will own the NFTs being purchased  
    """
    priceData: uint256[2] = self._purchasePrice(numTokens)
    assert msg.value >= priceData[0]
    assert self.currentId + numTokens <= MAX_ID  
    for i in range(MAX_PURCHASE):

        if (i >= numTokens):
           break
          
        self._mint(to)

    self.ownerToTokenCount[to] += numTokens
    self.lastPrice = priceData[1]
    self.lastPurchaseBlock = block.number

    refund: uint256 = msg.value - priceData[0]
    send(to, refund)      


@external
def withdraw():
    """
    @notice pay the team
    @dev Throws if 'msg.sender' is not dev or artist 
    """
    assert msg.sender == self.dev or msg.sender == self.artist
    artistPay: uint256 = self.balance / 2
    send(self.artist, artistPay)
    send(self.dev, self.balance)