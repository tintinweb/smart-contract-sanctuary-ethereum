# @version >=0.3.3
from vyper.interfaces import ERC165

LEGACY_EXTENSION_INTERFACE: constant(bytes4) = 0x7005caad
ERC165_INTERFACE: constant(bytes4) = 0x01ffc9a7
MAX_URI_LENGTH: constant(uint256) = 1024

interface IERC721CreatorCore:
    def mintExtension(to: address ) -> uint256 : nonpayable
    def setBaseTokenURIExtension(uri: String[MAX_URI_LENGTH]) : nonpayable


tokenAmountTracker: public(uint8)
maxSupply: immutable(uint8)
creator: immutable(IERC721CreatorCore)
owner: immutable(address)

SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    # ERC165 interface ID of ERC165
    LEGACY_EXTENSION_INTERFACE,
    # ERC165 interface ID of ERC721
    ERC165_INTERFACE ,
]

implements: ERC165

@external
def __init__( maxSupply_: uint8, creatorAddress: address):
  self.tokenAmountTracker = 0
  maxSupply = maxSupply_
  creator= IERC721CreatorCore(creatorAddress)
  owner = msg.sender

@external
@payable
def mint() :
 assert(self.tokenAmountTracker < maxSupply) #MaximumSupplyReached()
 creator.mintExtension(msg.sender)
 self.tokenAmountTracker+=1

@external
def setBaseTokenURI(uri: String[MAX_URI_LENGTH]):
  assert msg.sender == owner
  creator.setBaseTokenURIExtension(uri)

@external
def withdraw():
  assert msg.sender == owner
  send(owner, self.balance)

@pure
@external
def supportsInterface(interface_id: bytes4) -> bool :
  return interface_id in SUPPORTED_INTERFACES