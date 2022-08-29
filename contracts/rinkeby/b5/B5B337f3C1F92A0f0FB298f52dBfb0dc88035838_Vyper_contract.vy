# @version ^0.3.4
# @dev Implementation of ERC-721 non-fungible token standard for DYAD protocol
# @author z80 (@0xz80)

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721
from vyper.interfaces import ERC20

################################################################
#                          INTERFACES                          #
################################################################

interface Pool:
    def mintDyad(wethAmt: uint256, recipient: address = msg.sender) -> uint256: nonpayable
    def withdraw(amtDyad: uint256, recipient: address = msg.sender) -> uint256: nonpayable
    def deposit(_amount: uint256 = max_value(uint256)) -> uint256: nonpayable
    def addXp(amount: uint256): nonpayable
    def lastCheckpointIndex() -> uint256: nonpayable
    def poolBalanceAtCheckpoint(checkpoint: uint256) -> uint256: nonpayable
    def poolDeltaAtCheckpoint(checkpoint: uint256) -> int256: nonpayable
    def totalXpAtCheckpoint(checkpoint: uint256) -> uint256: nonpayable

implements: ERC721
implements: ERC165

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes4: view

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[5]) = [
    0x01FFC9A7,  # ERC165
    0x80AC58CD,  # ERC721
    0x150B7A02,  # ERC721TokenReceiver
    0x5B5E139F,  # ERC721Metadata
    0x780E9D63,  # ERC721Enumerable
]

################################################################
#                            EVENTS                            #
################################################################

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

# TODO: implement tracking total dyad printed per dNFT

# TODO: implement redemption for ETH

################################################################
#                         ERC721 STATE                         #
################################################################

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]

# @dev Mapping from NFT ID to approved address.
idToApprovals: HashMap[uint256, address]

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: public(HashMap[address, uint256])

# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]

# @dev Address of minter, who can mint a token
minter: address

baseURL: String[53]

totalSupply: public(uint256)

MAX_SUPPLY: constant(uint256) = 10000

NAME: constant(String[32]) = "dyad NFT"
SYMBOL: constant(String[32]) = "dNFT"

################################################################
#                          dNFT STATE                          #
################################################################

dyad: ERC20
weth: ERC20

# @dev Address where deposited DYAD should be sent to, and withdrawn from
dyad_pool: Pool

# @dev last calculated DYAD balance for a tokenId
virtualDyadBalance: public(HashMap[uint256, int256])

# @dev last calculated XP balance for a tokenId
xp: public(HashMap[uint256, uint256])

# @dev qty of DYAD minted per dNFT
dyadMinted: public(HashMap[uint256, uint256])

# @dev for each tokenId, check when we last updated its virtual DYAD and XP attributes
lastCheckpointForTokenId: public(HashMap[uint256, uint256])

@external
def __init__(dyad: address, weth: address):
    """
    @dev Contract constructor.
    """
    self.minter = msg.sender
    self.baseURL = "https://api.babby.xyz/metadata/"
    self.dyad = ERC20(dyad)
    self.weth = ERC20(weth)

@external
def setPool(pool: address):
    assert msg.sender == self.minter
    self.dyad_pool = Pool(pool)

@external
def deposit(tokenId: uint256, amount: uint256):
    self.erc20_safe_transferFrom(self.dyad.address, msg.sender, self, amount)
    self.dyad.approve(self.dyad_pool.address, amount)
    self.dyad_pool.deposit(amount)
    self.virtualDyadBalance[tokenId] += convert(amount, int256)

@external
def withdraw(tokenId: uint256, amount: uint256):
    assert msg.sender == self.idToOwner[tokenId]
    self.dyad_pool.withdraw(amount, msg.sender)

@external
def mintDyad(tokenId: uint256, wethAmt: uint256):
    assert msg.sender == self.idToOwner[tokenId]

    # take weth
    self.erc20_safe_transferFrom(self.weth.address, msg.sender, self, wethAmt)

    # mint dyad from pool; pool takes weth, dNFT contract gets dyad
    self.weth.approve(self.dyad_pool.address, wethAmt)
    new_dyad: uint256 = self.dyad_pool.mintDyad(wethAmt)
    self.dyadMinted[tokenId] += new_dyad

    self.dyad.approve(self.dyad_pool.address, new_dyad)
    self.dyad_pool.deposit(new_dyad)
    self.virtualDyadBalance[tokenId] += convert(new_dyad, int256)

@external
def syncTokenId(tokenId: uint256):
    # carry out per-dNFT accounting
    # increase or decrease virtualDyadBalance according to pct. ownership
    # of dyad pool, and xp
    next_checkpoint: uint256  = self.lastCheckpointForTokenId[tokenId] + 1
    last_checkpoint: uint256 = self.dyad_pool.lastCheckpointIndex()
    total_in_pool: uint256 = 0
    delta: int256 = 0
    virtual_delta: int256 = 0
    for i in range(next_checkpoint, next_checkpoint+1024):
        # check % ownership at checkpoint
        if i > last_checkpoint:
            break
        total_in_pool = self.dyad_pool.poolBalanceAtCheckpoint(i)
        delta = self.dyad_pool.poolDeltaAtCheckpoint(i)
        # this below is simple pct ownership calculation; all dNFT virtual balances
        # adjusted equally regardless of xp
        virtual_delta = self.virtualDyadBalance[tokenId] * delta / convert(total_in_pool, int256)
        self.virtualDyadBalance[tokenId] += virtual_delta
        if delta < 0:
            self.xp[tokenId] += convert((virtual_delta * -1), uint256)
        # increase virtual DYAD according to % ownership and xp if mint
        # decrease virtual DYAD according to % ownership and increment xp if burn

################################################################
#                       HELPER FUNCTIONS                       #
################################################################

@internal
def erc20_safe_transfer(token: address, receiver: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"


@internal
def erc20_safe_transferFrom(token: address, sender: address, receiver: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(sender, bytes32),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"


@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES

################################################################
#                        VIEW FUNCTIONS                        #
################################################################

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != empty(address)
    return self.ownerToNFTokenCount[_owner]


@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != empty(address)
    return owner


@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.idToOwner[_tokenId] != empty(address)
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


################################################################
#                  TRANSFER FUNCTION HELPERS                   #
################################################################

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
    assert self.idToOwner[_tokenId] == empty(address)
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
    self.idToOwner[_tokenId] = empty(address)
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
    if self.idToApprovals[_tokenId] != empty(address):
        # Reset approvals
        self.idToApprovals[_tokenId] = empty(address)


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
    assert _to != empty(address)
    # Clear approval. Throws if `_from` is not the current owner
    self._clearApproval(_from, _tokenId)
    # Remove NFT. Throws if `_tokenId` is not a valid NFT
    self._removeTokenFrom(_from, _tokenId)
    # Add NFT
    self._addTokenTo(_to, _tokenId)
    # Log the transfer
    log Transfer(_from, _to, _tokenId)


################################################################
#                      TRANSFER FUNCTIONS                      #
################################################################

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
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract: # check if `_to` is a contract address
        returnValue: bytes4 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4)


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
    assert owner != empty(address)
    # Throws if `_approved` is the current owner
    assert _approved != owner
    # Check requirements
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
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


################################################################
#                    MINT & BURN FUNCTIONS                     #
################################################################

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
    # Throws if `msg.sender` is not the minter
    # assert msg.sender == self.minter # disabled during testing
    # Throws if `_to` is zero address
    assert _to != empty(address)
    # Add NFT. Throws if `_tokenId` is owned by someone
    self._addTokenTo(_to, self.totalSupply)
    self.dyad_pool.addXp(100)
    self.xp[self.totalSupply] += 100
    log Transfer(empty(address), _to, self.totalSupply)
    self.totalSupply += 1
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
    assert owner != empty(address)
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, empty(address), _tokenId)


@view
@external
def tokenURI(tokenId: uint256) -> String[132]:
    return concat(self.baseURL, uint2str(tokenId))

################################################################
#                 ERC721-ENUMERABLE FUNCTIONS                  #
################################################################

@external
@view
def tokenByIndex(index: uint256) -> uint256:
    counter: uint256 = 0
    for i in range(MAX_SUPPLY):
        if self.idToOwner[i] != empty(address):
            if counter == index:
                return i
            counter += 1
        if i > self.totalSupply:
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

        if i > self.totalSupply:
            assert False, "ERC721Enumerable: global index out of bounds"

    assert False, "ERC721Enumerable: global index out of bounds"
    return 0