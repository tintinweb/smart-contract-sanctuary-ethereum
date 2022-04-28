// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./IERC721Metadata.sol";
import "./Address.sol";
import "./Strings.sol";
import "./ERC165.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract. Thanks, Chiru Labs!
*/
error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error CapExceeded();
error MintedQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error NotAnAdmin();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferIsLockedGlobally();
error TransferIsLocked();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
  @title A minimalistic, gas-efficient ERC-721 implementation forked from the
    `Super721` ERC-721 implementation used by SuperFarm.
  @author Tim Clancy
  @author 0xthrpw
  @author Qazawat Zirak
  @author Rostislav Khlebnikov

  Compared to the original `Super721` implementation that this contract forked
  from, this is a very pared-down contract that includes simple delegated
  minting and transfer locks.

  This contract includes the gas efficiency techniques graciously shared with
  the world in the specific ERC-721 implementation by Chiru Labs that is being
  called "ERC-721A" (https://github.com/chiru-labs/ERC721A). We have validated
  this contract against their test cases.

  February 8th, 2022.
*/
contract ImpostorsClone is
  ERC165, IERC721, IERC721Metadata, Ownable
{
  using Address for address;
  using Strings for uint256;

  /// The name of this ERC-721 contract.
  string public name;

  /// The symbol associated with this ERC-721 contract.
  string public symbol;

  /**
    The metadata URI to which token IDs are appended for generating `tokenUri`
    results. The URI will always naively slap a decimal token ID to the end of
    this provided URI.
  */
  string public metadataUri;

  /// The maximum number of this NFT that may be minted.
  uint256 public immutable cap;

  /**
    The ID of the next token that will be minted. Our range of token IDs begins
    at one in order to avoid downstream errors with uninitialized mappings.
  */
  uint256 private nextId = 1;

  /**
    A mapping from token IDs to their holding addresses. If the holding address
    is the zero address, that does not necessarily mean that the token is
    unowned; the ID space of owned tokens is gappy. The `_ownershipOf` function
    handles these gaps for determining the appropriate owners.
  */
  mapping ( uint256 => address ) private owners;

  /// A mapping from an address to the balance of tokens held by that address.
  mapping ( address => uint256 ) private balances;

  /**
    A mapping from each token ID to an approved address for that specific ID. An
    approved address is allowed to transfer the token with the specified ID on
    behalf of that token's owner.
  */
  mapping ( uint256 => address ) private tokenApprovals;

  /**
    A mapping from each address to per-address operator approvals. Operators are
    those addresses that have been approved to transfer tokens of any ID on
    behalf of the approver.
  */
  mapping ( address => mapping( address => bool )) private operatorApprovals;

  /// A mapping to track administrative callers who have been set by the owner.
  mapping ( address => bool ) private administrators;

  /// Whether or not transfer is locked for all items.
  bool public allTransfersLocked;

  /// Whether or not the transfer of a particular token ID is locked.
  mapping ( uint256 => bool ) public transferLocks;

  /**
    A modifier to see if a caller is an approved administrator.
  */
  modifier onlyAdmin () {
    if (_msgSender() != owner() && !administrators[_msgSender()]) {
      revert NotAnAdmin();
    }
    _;
  }

  /**
    Construct a new instance of this ERC-721 contract.

    @param _name The name to assign to this item collection contract.
    @param _symbol The ticker symbol of this item collection.
    @param _metadataURI The metadata URI to perform later token ID substitution
      with.
    @param _cap The maximum number of tokens that may be minted.
  */
  constructor (
    string memory _name,
    string memory _symbol,
    string memory _metadataURI,
    uint256 _cap
  ) {
    name = _name;
    symbol = _symbol;
    metadataUri = _metadataURI;
    cap = _cap;
  }

  /**
    Flag this contract as supporting the ERC-721 standard, the ERC-721 metadata
    extension, and the enumerable ERC-721 extension.

    @param _interfaceId The identifier, as defined by ERC-165, of the contract
      interface to support.

    @return Whether or not the interface being tested is supported.
  */
  function supportsInterface (
    bytes4 _interfaceId
  ) public view virtual override(ERC165, IERC165) returns (bool) {
    return (_interfaceId == type(IERC721).interfaceId)
      || (_interfaceId == type(IERC721Metadata).interfaceId)
      || (super.supportsInterface(_interfaceId));
  }

  /**
    Return the total number of this token that have ever been minted.

    @return The total supply of minted tokens.
  */
  function totalSupply () public view returns (uint256) {
    return nextId - 1;
  }

  /**
    Retrieve the number of distinct token IDs held by `_owner`.

    @param _owner The address to retrieve a count of held tokens for.

    @return The number of tokens held by `_owner`.
  */
  function balanceOf (
    address _owner
  ) external view override returns (uint256) {
    return balances[_owner];
  }

  /**
    Just as Chiru Labs does, we maintain a sparse list of token owners; for
    example if Alice owns tokens with ID #1 through #3 and Bob owns tokens #4
    through #5, the ownership list would look like:

    [ 1: Alice, 2: 0x0, 3: 0x0, 4: Bob, 5: 0x0, ... ].

    This function is able to consume that sparse list for determining an actual
    owner. Chiru Labs says that the gas spent here starts off proportional to
    the maximum mint batch size and gradually moves to O(1) as tokens get
    transferred.

    @param _id The ID of the token which we are finding the owner for.

    @return owner The owner of the token with ID of `_id`.
  */
  function _ownershipOf (
    uint256 _id
  ) private view returns (address owner) {
    if (!_exists(_id)) { revert OwnerQueryForNonexistentToken(); }
    unchecked {
      for (uint256 curr = _id;; curr--) {
        owner = owners[curr];
        if (owner != address(0)) {
          return owner;
        }
      }
    }
  }

  /**
    Return the address that holds a particular token ID.

    @param _id The token ID to check for the holding address of.

    @return The address that holds the token with ID of `_id`.
  */
  function ownerOf (
    uint256 _id
  ) external view override returns (address) {
    return _ownershipOf(_id);
  }

  /**
    Return whether a particular token ID has been minted or not.

    @param _id The ID of a specific token to check for existence.

    @return Whether or not the token of ID `_id` exists.
  */
  function _exists (
    uint256 _id
  ) public view returns (bool) {
    return _id > 0 && _id < nextId;
  }

  /**
    Return the address approved to perform transfers on behalf of the owner of
    token `_id`. If no address is approved, this returns the zero address.

    @param _id The specific token ID to check for an approved address.

    @return The address that may operate on token `_id` on its owner's behalf.
  */
  function getApproved (
    uint256 _id
  ) public view override returns (address) {
    if (!_exists(_id)) { revert ApprovalQueryForNonexistentToken(); }
    return tokenApprovals[_id];
  }

  /**
    This function returns true if `_operator` is approved to transfer items
    owned by `_owner`.

    @param _owner The owner of items to check for transfer ability.
    @param _operator The potential transferrer of `_owner`'s items.

    @return Whether `_operator` may transfer items owned by `_owner`.
  */
  function isApprovedForAll (
    address _owner,
    address _operator
  ) public view virtual override returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

  /**
    Return the token URI of the token with the specified `_id`. The token URI is
    dynamically constructed from this contract's `metadataUri`.

    @param _id The ID of the token to retrive a metadata URI for.

    @return The metadata URI of the token with the ID of `_id`.
  */
  function tokenURI (
    uint256 _id
  ) external view virtual override returns (string memory) {
    if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }
    return bytes(metadataUri).length != 0
      ? string(abi.encodePacked(metadataUri, _id.toString()))
      : '';
  }

  /**
    This private helper function updates the token approval address of the token
    with ID of `_id` to the address `_to` and emits an event that the address
    `_owner` triggered this approval. This function emits an {Approval} event.

    @param _owner The owner of the token with the ID of `_id`.
    @param _to The address that is being granted approval to the token `_id`.
    @param _id The ID of the token that is having its approval granted.
  */
  function _approve (
    address _owner,
    address _to,
    uint256 _id
  ) private {
    tokenApprovals[_id] = _to;
    emit Approval(_owner, _to, _id);
  }

  /**
    Allow the owner of a particular token ID, or an approved operator of the
    owner, to set the approved address of a particular token ID.

    @param _approved The address being approved to transfer the token of ID `_id`.
    @param _id The token ID with its approved address being set to `_approved`.
  */
  function approve (
    address _approved,
    uint256 _id
  ) external override {
    address owner = _ownershipOf(_id);
    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }
    _approve(owner, _approved, _id);
  }

  /**
    Enable or disable approval for a third party `_operator` address to manage
    all of the caller's tokens.

    @param _operator The address to grant management rights over all of the
      caller's tokens.
    @param _approved The status of the `_operator`'s approval for the caller.
  */
  function setApprovalForAll (
    address _operator,
    bool _approved
  ) external override {
    operatorApprovals[_msgSender()][_operator] = _approved;
    emit ApprovalForAll(_msgSender(), _operator, _approved);
  }

  /**
    This private helper function handles the portion of transferring an ERC-721
    token that is common to both the unsafe `transferFrom` and the
    `safeTransferFrom` variants.

    This function does not support burning tokens and emits a {Transfer} event.

    @param _from The address to transfer the token with ID of `_id` from.
    @param _to The address to transfer the token to.
    @param _id The ID of the token to transfer.
  */
  function _transfer (
    address _from,
    address _to,
    uint256 _id
  ) private {
    address previousOwner = _ownershipOf(_id);
    bool isApprovedOrOwner = (_msgSender() == previousOwner)
      || (isApprovedForAll(previousOwner, _msgSender()))
      || (getApproved(_id) == _msgSender());

    if (!isApprovedOrOwner) { revert TransferCallerNotOwnerNorApproved(); }
    if (previousOwner != _from) { revert TransferFromIncorrectOwner(); }
    if (_to == address(0)) { revert TransferToZeroAddress(); }
    if (allTransfersLocked) { revert TransferIsLockedGlobally(); }
    if (transferLocks[_id]) { revert TransferIsLocked(); }

    // Clear any token approval set by the previous owner.
    _approve(previousOwner, address(0), _id);

    /*
      Another Chiru Labs tip: we may safely use unchecked math here given the
      sender balance check and the limited range of our expected token ID space.
    */
    unchecked {
      balances[_from] -= 1;
      balances[_to] += 1;
      owners[_id] = _to;

      /*
        The way the gappy token ownership list is setup, we can tell that
        `_from` owns the next token ID if it has a zero address owner. This also
        happens to be what limits an efficient burn implementation given the
        current setup of this contract. We need to update this spot in the list
        to mark `_from`'s ownership of this portion of the token range.
      */
      uint256 nextTokenId = _id + 1;
      if (owners[nextTokenId] == address(0) && _exists(nextTokenId)) {
        owners[nextTokenId] = previousOwner;
      }
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _id);
  }

  /**
    This function performs an unsafe transfer of token ID `_id` from address
    `_from` to address `_to`. The transfer is considered unsafe because it does
    not validate that the receiver can actually take proper receipt of an
    ERC-721 token.

    @param _from The address to transfer the token from.
    @param _to The address to transfer the token to.
    @param _id The ID of the token being transferred.
  */
  function transferFrom (
    address _from,
    address _to,
    uint256 _id
  ) external virtual override {
    _transfer(_from, _to, _id);
  }

  /**
    This is an private helper function used to, if the transfer destination is
    found to be a smart contract, check to see if that contract reports itself
    as safely handling ERC-721 tokens by returning the magical value from its
    `onERC721Received` function.

    @param _from The address of the previous owner of token `_id`.
    @param _to The destination address that will receive the token.
    @param _id The ID of the token being transferred.
    @param _data Optional data to send along with the transfer check.

    @return Whether or not the destination contract reports itself as being able
      to handle ERC-721 tokens.
  */
  function _checkOnERC721Received(
    address _from,
    address _to,
    uint256 _id,
    bytes memory _data
  ) private returns (bool) {
    if (_to.isContract()) {
      try IERC721Receiver(_to).onERC721Received(_msgSender(), _from, _id, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(_to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) revert TransferToNonERC721ReceiverImplementer();
        else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
    This function performs transfer of token ID `_id` from address `_from` to
    address `_to`. This function validates that the receiving address reports
    itself as being able to properly handle an ERC-721 token.

    @param _from The address to transfer the token from.
    @param _to The address to transfer the token to.
    @param _id The ID of the token being transferred.
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id
  ) public virtual override {
    safeTransferFrom(_from, _to, _id, '');
  }

  /**
    This function performs transfer of token ID `_id` from address `_from` to
    address `_to`. This function validates that the receiving address reports
    itself as being able to properly handle an ERC-721 token. This variant also
    sends `_data` along with the transfer check.

    @param _from The address to transfer the token from.
    @param _to The address to transfer the token to.
    @param _id The ID of the token being transferred.
    @param _data Optional data to send along with the transfer check.
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _id,
    bytes memory _data
  ) public override {
    _transfer(_from, _to, _id);
    if (!_checkOnERC721Received(_from, _to, _id, _data)) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
    This function allows permissioned minters of this contract to mint one or
    more tokens dictated by the `_amount` parameter. Any minted tokens are sent
    to the `_recipient` address.

    Note that tokens are always minted sequentially starting at one. That is,
    the list of token IDs is always increasing and looks like [ 1, 2, 3... ].
    Also note that per our use cases the intended recipient of these minted
    items will always be externally-owned accounts and not other contracts. As a
    result there is no safety check on whether or not the mint destination can
    actually correctly handle an ERC-721 token.

    @param _recipient The recipient of the tokens being minted.
    @param _amount The amount of tokens to mint.
  */
  function mint_Qgo (
    address _recipient,
    uint256 _amount
  ) external onlyAdmin {
    if (_recipient == address(0)) { revert MintToZeroAddress(); }
    if (_amount == 0) { revert MintZeroQuantity(); }
    if (nextId - 1 + _amount > cap) { revert CapExceeded(); }

    /**
      Inspired by the Chiru Labs implementation, we use unchecked math here.
      Only enormous minting counts that are unrealistic for our purposes would
      cause an overflow.
    */
    uint256 startTokenId = nextId;
    unchecked {
      balances[_recipient] += _amount;
      owners[startTokenId] = _recipient;

      uint256 updatedIndex = startTokenId;
      for (uint256 i; i < _amount; i++) {
        emit Transfer(address(0), _recipient, updatedIndex);
        updatedIndex++;
      }
      nextId = updatedIndex;
    }
  }

  /**
    This function allows the original owner of the contract to add or remove
    other addresses as administrators. Administrators may perform mints and may
    lock token transfers.

    @param _newAdmin The new admin to update permissions for.
    @param _isAdmin Whether or not the new admin should be an admin.
  */
  function setAdmin (
    address _newAdmin,
    bool _isAdmin
  ) external onlyOwner {
    administrators[_newAdmin] = _isAdmin;
  }

  /**
    Allow the item collection owner to update the metadata URI of this
    collection.

    @param _uri The new URI to update to.
  */
  function setURI (
    string calldata _uri
  ) external virtual onlyOwner {
    metadataUri = _uri;
  }

  /**
    This function allows the owner to lock the transfer of all token IDs. This
    is designed to prevent whitelisted presale users from using the secondary
    market to undercut the auction before the sale has ended.

    @param _locked The status of the lock; true to lock, false to unlock.
  */
  function lockAllTransfers (
    bool _locked
  ) external onlyOwner {
    allTransfersLocked = _locked;
  }

  /**
    This function allows an administrative caller to lock the transfer of
    particular token IDs. This is designed for a non-escrow staking contract
    that comes later to lock a user's NFT while still letting them keep it in
    their wallet.

    @param _id The ID of the token to lock.
    @param _locked The status of the lock; true to lock, false to unlock.
  */
  function lockTransfer (
    uint256 _id,
    bool _locked
  ) external onlyAdmin {
    transferLocks[_id] = _locked;
  }
}