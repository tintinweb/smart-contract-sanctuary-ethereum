# @version 0.3.3

# Interfaces
# ==========

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC165
implements: ERC721

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes4: view

# Events
# ======

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

# Fields
# ======

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: public(HashMap[uint256, address])

# @dev Mapping from NFT ID to approved address.
idToApprovals: HashMap[uint256, address]

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: HashMap[address, uint256]

# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[2]) = [
    # ERC165 interface ID of ERC165
    0x01ffc9a7,
    # ERC165 interface ID of ERC721
    0x80ac58cd,
]

# @dev NFT contract owner
owner: public(address)

# @dev NFT mint price for each number of letters
prices: public(uint256[5])

# @dev Maximum amount of tokens to be minted for each number of letters
MAX_SUPPLIES: constant(uint256[5]) = [
    16 * 5**0,
    16 * 5**1,
    16 * 5**2,
    16 * 5**3,
    16 * 5**4,
]

# @dev Current Token Index and Total Supply for each number of letters
totalUnnamedMinted: public(uint256[5])

# @dev Registered names
registeredNames: HashMap[uint128, bool]

# Util
# ====

@pure
@internal
def _byte_to_hex(_byte: uint8) -> String[2]:
    fst_octect: uint8 = _byte / 16
    snd_octect: uint8 = _byte % 16
    char1: uint8 = 0
    char2: uint8 = 0
    if fst_octect < 10:
        char1 = (fst_octect + 48)
    else:
        char1 = (fst_octect - 10 + 97)
    if snd_octect < 10:
        char2 = (snd_octect + 48)
    else:
        char2 = (snd_octect - 10 + 97)
    w1: bytes32 = convert(char1, bytes32)
    w2: bytes32 = convert(char2, bytes32)
    b1: Bytes[1] = slice(w1, 31, 1)
    b2: Bytes[1] = slice(w2, 31, 1)
    s1: String[1] = convert(b1, String[1])
    s2: String[1] = convert(b2, String[1])
    return concat(s1, s2)

@pure
@internal
def _get_byte(val: uint256, idx: uint256) -> uint8:
    return convert((val / (2**(8*idx))) % 256, uint8)

@view
@internal
def _word_to_hex(word: uint256) -> String[66]:
    return concat(
        "0x",
        self._byte_to_hex(self._get_byte(word, 31)),
        self._byte_to_hex(self._get_byte(word, 30)),
        self._byte_to_hex(self._get_byte(word, 29)),
        self._byte_to_hex(self._get_byte(word, 28)),
        self._byte_to_hex(self._get_byte(word, 27)),
        self._byte_to_hex(self._get_byte(word, 26)),
        self._byte_to_hex(self._get_byte(word, 25)),
        self._byte_to_hex(self._get_byte(word, 24)),
        self._byte_to_hex(self._get_byte(word, 23)),
        self._byte_to_hex(self._get_byte(word, 22)),
        self._byte_to_hex(self._get_byte(word, 21)),
        self._byte_to_hex(self._get_byte(word, 20)),
        self._byte_to_hex(self._get_byte(word, 19)),
        self._byte_to_hex(self._get_byte(word, 18)),
        self._byte_to_hex(self._get_byte(word, 17)),
        self._byte_to_hex(self._get_byte(word, 16)),
        self._byte_to_hex(self._get_byte(word, 15)),
        self._byte_to_hex(self._get_byte(word, 14)),
        self._byte_to_hex(self._get_byte(word, 13)),
        self._byte_to_hex(self._get_byte(word, 12)),
        self._byte_to_hex(self._get_byte(word, 11)),
        self._byte_to_hex(self._get_byte(word, 10)),
        self._byte_to_hex(self._get_byte(word, 9)),
        self._byte_to_hex(self._get_byte(word, 8)),
        self._byte_to_hex(self._get_byte(word, 7)),
        self._byte_to_hex(self._get_byte(word, 6)),
        self._byte_to_hex(self._get_byte(word, 5)),
        self._byte_to_hex(self._get_byte(word, 4)),
        self._byte_to_hex(self._get_byte(word, 3)),
        self._byte_to_hex(self._get_byte(word, 2)),
        self._byte_to_hex(self._get_byte(word, 1)),
        self._byte_to_hex(self._get_byte(word, 0)),
    )

@pure
@internal
def _validate_name(num_chars: uint8, name: uint128) -> bool:
    """
    @dev Validates the number of characters in a name.
    @param  num_chars   The number of chars of the name.
    @param  name        The encoded name.
    @return  True if the name is valid, false otherwise.
    """
    assert 1 <= num_chars and num_chars <= 10, "Number of chars must be in the range 1 to 10, inclusive."

    word: uint256 = convert(name, uint256)
    assert shift(word, -120) == 0, "Name must use at most 120 bits."

    # Check if the name has more or equal than `num_char` charaters.
    tail_size: int8 = convert((num_chars - 1) * 6, int8)     # 6 bits per char
    head: uint256 = shift(word, -tail_size)
    return head > 1

@pure
@internal
def _extract_token_fields(token_id: uint256) -> (bool, uint8, uint128):
    """
    @dev Extracts fields from token id.
    @return (named, num_chars, idx, name).
        named:     True if it's a named token.
        num_chars: The number of characters.
        rest:
            If unnamed: Index of the token in the total supply.
            If named:   Encoded name.
    """
    named: bool = convert(shift(token_id, -(31*8)), bool)
    num_chars: uint8 = convert(bitwise_or(shift(token_id, -(30)), 255), uint8)
    rest: uint128 = convert(shift(token_id, -128), uint128)
    return (named, num_chars, rest)

# Metadata
# ========

# @dev NFT symbol
symbol: public(String[3])

# @dev NFT symbol
name: public(String[16])

@view
@external
def tokenURI(_tokenId: uint256) -> String[107]:
    return concat("https://knt.preview.kindelia.org/api/knt/", self._word_to_hex(_tokenId))

# EIP712
# ======

DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)')
DOMAIN_SEPARATOR: immutable(bytes32)

# Base
# ====

@external
def __init__():
    """
    @dev Contract constructor.
    """
    self.owner = msg.sender
    self.symbol = "KNT"
    self.name = "Kind Name Tests"
    basePrice: uint256 = 2 * 10**13
    self.prices = [
        basePrice * 5**4,
        basePrice * 5**3,
        basePrice * 5**2,
        basePrice * 5**1,
        basePrice * 5**0,
    ]
    # EIP-712
    DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("Kindelia Name Tokens", Bytes[20])),
            convert(chain.id, bytes32),
            convert(self, bytes32),
        )
    )

@external
def setPrice(charIdx: uint8, price: uint256): 
    assert msg.sender == self.owner
    self.prices[charIdx] = price

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
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
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
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
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
def _addTokenTo(to: address, tokenId: uint256) -> uint256:
    """
    @dev Add a NFT to a given address
    """
    # Change the owner
    self.idToOwner[tokenId] = to
    # Change count tracking
    self.ownerToNFTokenCount[to] += 1

    return tokenId


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
    @dev Execute transfer of an NFT.
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
        assert returnValue == SUPPORTED_INTERFACES[0]


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


### MINT & BURN FUNCTIONS ###

@view
@internal
def _make_named_token_id(num_chars: uint8, name: uint128) -> uint256:
    "@dev  Builds token ID for a named token. Checks if name is valid."
    assert self._validate_name(num_chars, name), "Invalid name for given number of chars."
    # `named` flag and number of chars
    token_id: uint256 = bitwise_or(shift(1, 248), shift(convert(num_chars, uint256), 240)) 
    token_id = bitwise_or(token_id, convert(name, uint256))
    return token_id

@internal
def _register_named_token(num_chars: uint8, name: uint128) -> uint256:
    """
    @dev Validates, registers name and returns new token ID.
        Throws if `num_chars` and `name` combination is not valid.
        Throws if `name` is already registered.
    @param  name  Name to be registered.
    """
    # Checks if name is already registered
    assert self.registeredNames[name] == False, "Named is already registered."
    # Registers the name
    self.registeredNames[name] = True
    # Builds a new token id from the name
    token_id: uint256 = self._make_named_token_id(num_chars, name)
    return token_id

@internal
def _mint(to: address, token_id: uint256) -> uint256:
    self._addTokenTo(to, token_id)
    log Transfer(ZERO_ADDRESS, to, token_id)
    return token_id

@external
@nonreentrant('lock')
def mint_named(num_chars: uint8, name: uint128, to: address = msg.sender) -> uint256:
    assert msg.sender == self.owner, "Only the owner can mint directly."
    assert to != ZERO_ADDRESS, "Cannot mint to the zero address."

    token_id: uint256 = self._register_named_token(num_chars, name)
    return self._mint(to, token_id)

@external
@nonreentrant('lock')
def mint_unnamed(num_chars: uint8, to: address = msg.sender) -> uint256:
    assert msg.sender == self.owner, "Only the owner can mint directly."
    assert to != ZERO_ADDRESS, "Cannot mint to the zero address."
    # Throws if number of chars is outside the valid range (1 to 5)
    assert 1 <= num_chars and num_chars <= 10, "Number of chars must be in the range 1 to 10, inclusive."

    # Index corresponding to the given number of chars
    chars_idx: uint8 = num_chars - 1

    # Throws if max supply for given number of chars was reached
    assert self.totalUnnamedMinted[chars_idx] < MAX_SUPPLIES[chars_idx], "Mint ended for this number of chars."

    token_idx: uint256 = self.totalUnnamedMinted[chars_idx]
    token_id: uint256 = bitwise_or(
        shift(convert(num_chars, uint256), 240), # shift 30 bytes to the left
        token_idx
    )

    return self._mint(to, token_id)

@payable
@external
@nonreentrant('lock')
def mint(chars: uint8, to: address = msg.sender) -> uint256:
    """
    @dev Function to mint tokens
         Throws if `to` is zero address.
         Throws if `MAX_SUPPLY` is reached.
         Throws if the max supply for the given chars number is reached.
    @param chars The number of chars of the token to mint.
    @param to The address that will receive the minted token.
    @return A boolean that indicates if the operation was successful.
    """
    assert to != ZERO_ADDRESS, "Cannot mint to the zero address."
    # Throws if number of chars is outside the valid range (1 to 5)
    assert 1 <= chars and chars <= 5, "Number of chars must be in the range 1 to 5, inclusive."
    # Index corresponding to the given number of chars
    chars_idx: uint8 = chars - 1
    # Throws if max supply for given number of chars was reached
    assert self.totalUnnamedMinted[chars_idx] < MAX_SUPPLIES[chars_idx], "Mint ended for this number of chars."
    # Throws if not enough tokens are sent
    assert msg.value == self.prices[chars_idx], "Price is wrong."

    token_idx: uint256 = self.totalUnnamedMinted[chars_idx]
    self.totalUnnamedMinted[chars_idx] += 1

    token_id: uint256 = bitwise_or(shift(convert(chars, uint256), 240), token_idx) # shift 30 bytes to the left

    return self._mint(to, token_id)

@internal
def _burn(_tokenId: uint256):
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)

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
    self._burn(_tokenId)

# Name claiming
# =============

struct Allowance:
    signer: address
    token_id: uint256
    name: uint128

ALLOWANCE_TYPE_HASH: constant(bytes32) = keccak256("Allowance(address signer,uint256 token_id,uint128 name)")

@pure
@internal
def _Allowance_digest(allow: Allowance) -> bytes32:
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            DOMAIN_SEPARATOR,
            keccak256(
                concat(
                    ALLOWANCE_TYPE_HASH,
                    convert(allow.signer, bytes32),
                    convert(allow.token_id, bytes32),
                    convert(allow.name, bytes32),
                )
            )
        )
    )
    return digest

@pure
@internal
def _extract_signature(signature: Bytes[65]) -> (uint256, uint256, uint256):
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    return r, s, v

@view
@internal
def _recover_address(digest: bytes32, signature: Bytes[65]) -> address:
    r: uint256 = 0
    s: uint256 = 0
    v: uint256 = 0
    r, s, v = self._extract_signature(signature)
    return ecrecover(digest, v, s, r)

@external
def covert_to_named(
    master_addr: address,
    minter_addr: address,
    master_sign: Bytes[65],
    minter_sign: Bytes[65],
    token_id: uint256,
    name: uint128,
) -> uint256:
    assert master_addr != ZERO_ADDRESS
    assert minter_addr != ZERO_ADDRESS
    digest_master: bytes32 = self._Allowance_digest(Allowance({signer: master_addr, token_id: token_id, name: name}))
    digest_sender: bytes32 = self._Allowance_digest(Allowance({signer: minter_addr, token_id: token_id, name: name}))
    assert self._recover_address(digest_master, master_sign) == master_addr, "Master signature is not valid."
    assert self._recover_address(digest_sender, minter_sign) == minter_addr, "Minter signature is not valid."

    assert master_addr == self.owner
    assert self._isApprovedOrOwner(minter_addr, token_id)

    named: bool = False
    num_chars: uint8 = 0
    rest: uint128 = 0
    (named, num_chars, rest) = self._extract_token_fields(token_id)

    # # TODO: should we disallow renaming?
    # assert not named, "Token is already named."

    # Validates and register the name
    new_token_id: uint256 = self._register_named_token(num_chars, name)

    self._burn(token_id)
    return self._mint(minter_addr, new_token_id)

# Withdrawal
# ==========

@nonpayable
@external
def withdraw(to: address = msg.sender):
    assert msg.sender == self.owner
    send(to, self.balance)