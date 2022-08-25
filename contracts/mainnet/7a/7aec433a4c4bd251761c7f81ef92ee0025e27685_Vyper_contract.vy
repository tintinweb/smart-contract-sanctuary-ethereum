# @version 0.3.3
# @title PAC DAO 2022 Congressional Scorecard
# @notice Crowdsourced Scorecard of Crypto Friendliness of 117th US Congress
# @dev Implementation of ERC-721 non-fungible token standard
# @author pacdao.eth
# @license MIT
#
#                        ::
#                        ::
#                       .::.
#                     ..::::..
#                    .:-::::-:.
#                   .::::::::::.
#                   :+========+:
#                   ::.:.::.:.::
#            ..     :+========+:    ..
# @@@@@@@...........:.:.:..:.:.:[email protected]@@@@@@@
# @@@@@@@@@@* :::. .:.:.:..:.:.:   . .  [email protected]@@@@@@@@
# @@@@@@@@@@@@@***: :....::-.:.:.:.:[email protected]@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@..+==========+...:@@@@@@@@@@@@@@@


from vyper.interfaces import ERC20
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


# @dev Emits when ownership of any NFT changes by any mechanism. 
#      This event emits when NFTs are created (`from` == 0) and destroyed (`to` == 0). 
#      Exception: during contract creation, any number of NFTs may be created and assigned without emitting. 
#      At the time of any transfer, the approved address for that NFT (if any) is reset to none.
# @param _from Sender of NFT (if address is zero address it indicates token creation).
# @param _to Receiver of NFT (if address is zero address it indicates token destruction).
# @param _tokenId The NFT that got transfered.

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _tokenId: indexed(uint256)


# @dev This emits when the approved address for an NFT is changed or reaffirmed. 
#      The zero address indicates there is no approved address. 
#      When a Transfer event emits, this also indicates any approved address resets to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _tokenId NFT which we are approving.

event Approval:
    _owner: indexed(address)
    _approved: indexed(address)
    _tokenId: indexed(uint256)


# @dev This emits when an operator is enabled or disabled for an owner. 
#      The operator can manage all NFTs of the owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights (true if operator rights given, false if revoked).

event ApprovalForAll:
    _owner: indexed(address)
    _operator: indexed(address)
    _approved: bool

IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004

# Metadata
symbol: public(String[32])
name: public(String[32])

# Permission
owner: public(address)
minter: public(address)

# URI
base_uri: public(String[128])
contract_uri: String[128]

# NFT Data
token_log: DynArray[uint256, 1000]

owned_tokens: HashMap[uint256, address]                       # @dev NFT ID to the address that owns it.
token_approvals: HashMap[uint256, address]                    # @dev NFT ID to approved address.
operator_approvals: HashMap[address, HashMap[address, bool]]  # @dev Owner address to mapping of operator addresses.
balances: HashMap[address, uint256]                           # @dev Owner address to token count.

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[6]) = [
    0x01FFC9A7,  # ERC165
    0x80AC58CD,  # ERC721
    0x150B7A02,  # ERC721TokenReceiver
    0x5B5E166F,  # ERC721Metadata
    0x780E9D63,  # ERC721Enumerable
    0x5B5E139F,  # ERC721Enumerable
]


@external
def __init__():
    """
    @dev Contract constructor.
    """
    self.symbol = "PHATCAT"
    self.name = "PAC DAO PHATCATS"

    self.owner = msg.sender
    self.minter = msg.sender

    self.base_uri = (
        "ipfs://bafybeicrbcbmxaeluzapoczl3tt3a23hj6crx3lzgvcilbccjzs2srhksy/"
    )
    self.contract_uri = (
        "ipfs://bafkreigq4v4daqdfiiw77zea36m7y3i2gediy36m2btrdpndbw5xnug3ru"
    )


@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @notice Query if a contract implements an interface.
    @dev Interface identification is specified in ERC-165.
    @param interface_id Bytes4 representing the interface.
    @return bool True if supported.
    """

    return interface_id in SUPPORTED_INTERFACES


### VIEW FUNCTIONS ###


@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @notice Count all NFTs assigned to an owner.
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. 
         NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    @return The address of the owner of the NFT
    """

    assert _owner != empty(address) # dev: "ERC721: balance query for the zero address"
    return self.balances[_owner]


@view
@external
def ownerOf(token_id: uint256) -> address:
    """
    @notice Find the owner of an NFT.
    @dev Returns the address of the owner of the NFT.
         Throws if `token_id` is not a valid NFT.
    @param token_id The identifier for an NFT.
    @return The address of the owner of the NFT
    """

    owner: address = self.owned_tokens[token_id]
    assert owner != empty(address) # dev: "ERC721: owner query for nonexistent token"
    return owner


@view
@external
def getApproved(token_id: uint256) -> address:
    """
    @notice Get the approved address for a single NFT
    @dev Get the approved address for a single NFT.
         Throws if `token_id` is not a valid NFT.
    @param token_id ID of the NFT for which to query approval.
    @return The approved address for this NFT, or the zero address if there is none
    """

    assert self.owned_tokens[token_id] != empty(address) # dev: "ERC721: approved query for nonexistent token"
    return self.token_approvals[token_id]


@view
@external
def isApprovedForAll(owner: address, operator: address) -> bool:
    """
    @notice Query if an address is an authorized operator for another address
    @dev Checks if `operator` is an approved operator for `owner`.
    @param owner The address that owns the NFTs.
    @param operator The address that acts on behalf of the owner.
    @return True if `_operator` is an approved operator for `_owner`, false otherwise
    """

    return (self.operator_approvals[owner])[operator]


### TRANSFER FUNCTION HELPERS ###


@view
@internal
def _is_approved_or_owner(spender: address, token_id: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param token_id uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """

    owner: address = self.owned_tokens[token_id]
    spender_is_owner: bool = owner == spender
    spender_is_approved: bool = spender == self.token_approvals[token_id]
    spender_is_approved_for_all: bool = self.operator_approvals[owner][spender]

    return (spender_is_owner or spender_is_approved) or spender_is_approved_for_all


@internal
def _add_token_to(_to: address, _token_id: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_token_id` is owned by someone.
    """

    # Throws if `_token_id` is owned by someone
    assert self.owned_tokens[_token_id] == empty(address) 

    # Change the owner
    self.owned_tokens[_token_id] = _to

    # Change count tracking
    self.balances[_to] += 1


@internal
def _remove_token_from(_from: address, _token_id: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """

    # Throws if `_from` is not the current owner
    assert self.owned_tokens[_token_id] == _from

    # Change the owner
    self.owned_tokens[_token_id] = empty(address)

    # Change count tracking
    self.balances[_from] -= 1


@internal
def _clear_approval(_owner: address, _token_id: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """

    # Throws if `_owner` is not the current owner
    assert self.owned_tokens[_token_id] == _owner
    if self.token_approvals[_token_id] != empty(address):
        # Reset approvals
        self.token_approvals[_token_id] = empty(address)


@internal
def _transfer_from(_from: address, _to: address, _token_id: uint256, _sender: address):
    """
    @dev Execute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `_to` is the zero address.
         Throws if `_from` is not the current owner.
         Throws if `_token_id` is not a valid NFT.
    """

    # Throws if `_to` is the zero address
    assert _to != empty(address) # dev : "ERC721: transfer to the zero address"

    # Check requirements
    assert self._is_approved_or_owner(_sender, _token_id) # dev : "ERC721: transfer caller is not owner nor approved"

    # Clear approval. Throws if `_from` is not the current owner
    self._clear_approval(_from, _token_id)

    # Remove NFT. Throws if `_token_id` is not a valid NFT
    self._remove_token_from(_from, _token_id)

    # Add NFT
    self._add_token_to(_to, _token_id)

    # Log the transfer
    log Transfer(_from, _to, _token_id)


### TRANSFER FUNCTIONS ###


@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else they maybe be permanently lost.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    """

    self._transfer_from(_from, _to, _tokenId, msg.sender)


@external
def safeTransferFrom(
    _from: address, _to: address, _tokenId: uint256, _data: Bytes[1024] = b""
):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
         If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """

    self._transfer_from(_from, _to, _tokenId, msg.sender)

    if _to.is_contract:  # check if `_to` is a contract address
        return_value: bytes32 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)

        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert return_value == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32)


@external
def approve(_approved: address, _tokenId: uint256):
    """
    @notice Change or reaffirm the approved address for an NFT
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _approved Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """

    owner: address = self.owned_tokens[_tokenId]

    # Throws if `_tokenId` is not a valid NFT
    assert owner != empty(address) # dev: "ERC721: owner query for nonexistent token"

    # Throws if `_approved` is the current owner
    assert _approved != owner # dev: "ERC721: approval to current owner"

    # Check requirements
    is_owner: bool = self.owned_tokens[_tokenId] == msg.sender
    is_approved_all: bool = (self.operator_approvals[owner])[msg.sender]
    assert is_owner or is_approved_all # dev: "ERC721: approve caller is not owner nor approved for all"

    # Set the approval
    self.token_approvals[_tokenId] = _approved

    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @notice notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
    @dev Enables or disables approval for a third party ("operator") to manage all of`msg.sender`'s assets. It also emits the ApprovalForAll event.
         Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    This works even if sender doesn't own any tokens at the time.
    @param _operator Address to add to the set of authorized operators.
    @param _approved True if the operators is approved, false to revoke approval.
    """

    # Throws if `_operator` is the `msg.sender`
    assert _operator != msg.sender
    self.operator_approvals[msg.sender][_operator] = _approved

    log ApprovalForAll(msg.sender, _operator, _approved)


### MINT FUNCTIONS ###


@external
def mint(receiver: address, seat_id : uint256):
    """
    @notice Function to mint a token
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
    """

    # Checks
    assert msg.sender in [self.minter, self.owner]
    assert receiver != empty(address) # dev: Cannot mint to empty address

    # Add NFT. Throws if `_token_id` is owned by someone
    self._add_token_to(receiver, seat_id)
    self.token_log.append(seat_id)
    log Transfer(empty(address), receiver, seat_id)



### ERC721-URI STORAGE FUNCTIONS ###


@internal
@pure
def uint2str(_value: uint256) -> String[78]:
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


@external
@view
def tokenURI(token_id: uint256) -> String[256]:
    """
    @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC 6686. The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
    """
    if self.owned_tokens[token_id] == empty(address):
        raise # dev: "ERC721URIStorage: URI query for nonexistent token"

    return concat(self.base_uri, self.uint2str(token_id))


@external
@view
def contractURI() -> String[128]:
    """
    @notice URI for contract level metadata
    """
    return self.contract_uri



### ADMIN FUNCTIONS

@external
def set_base_uri(base_uri: String[128]):
    """
    @notice Admin function to set a new Base URI for
    @dev Globally prepended to token_uri and contract_uri
    @param base_uri New URI for the token

    """
    assert msg.sender == self.owner
    self.base_uri = base_uri


@external
def set_contract_uri(new_uri: String[66]):
    """
    @notice Admin function to set a new contract URI
    @dev Appended to base_uri
    @param new_uri New URI for the contract
    """

    assert msg.sender in [self.owner, self.minter] # dev: Only Admin
    self.contract_uri = new_uri


@external
def set_owner(new_addr: address):
    """
    @notice Admin function to update owner
    @param new_addr The new owner address to take over immediately
    """
       
    assert msg.sender == self.owner  # dev: Only Owner
    self.owner = new_addr


@external
def set_minter(new_address: address):
    """
    @notice Admin function to set a new minter address
    @dev Update the address authorized to mint 
    @param new_address New minter address
    """

    assert msg.sender in [self.owner, self.minter]
    self.minter = new_address


@external
def withdraw_erc20(coin: address, target: address, amount: uint256):
   """
   @notice Withdraw ERC20 tokens accidentally sent to contract
   @param coin ERC20 address
   @param target Address to receive
   @param amount Wei
   """
   assert self.owner == msg.sender # dev: "Admin Only"
   ERC20(coin).transfer(target, amount)



## ERC-721 Enumerable Functions


@external
@view
def totalSupply() -> uint256:
    """
    @notice Enumerate valid NFTs
    @dev Throws if `_index` >= `totalSupply()`.
    @return The token identifier for the `_index`th NFT
    """
    return len(self.token_log)


@external
@view
def tokenByIndex(_index: uint256) -> uint256:
    """
    @notice Enumerate valid NFTs
    @dev Better not call this from another smart contract.  Gas hog
    @param _index A counter less than `totalSupply()`
    @return The token identifier for the `_index`th NFT,
    """

    return self.token_log[_index]
   

@external
@view
def tokenOfOwnerByIndex(_owner: address, _index: uint256) -> uint256:
    """
    @notice Enumerate NFTs assigned to an owner
    @dev Throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address, representing invalid NFTs.
    @param _owner An address where we are interested in NFTs owned by them
    @param _index A counter less than `balanceOf(_owner)`
    @return The token identifier for the `_index`th NFT assigned to `_owner`, (sort order not specified)
    """

    counter: uint256 = 0
    retval: uint256 = 1001 

    for i in self.token_log:
        if self.owned_tokens[i] == _owner:
            if counter == _index:
                retval = i
            counter += 1

    if retval == 1001:
        raise "ERC721Enumerable: global index out of bounds"
    
    return retval