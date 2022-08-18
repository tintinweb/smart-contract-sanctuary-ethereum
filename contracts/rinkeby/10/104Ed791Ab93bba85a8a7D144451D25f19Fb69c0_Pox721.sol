// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import './PoxStorage.sol';
import './PoxLib.sol';
import './meta/OnChainMeta.sol';

error AlreadyInitialized();
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

contract Pox721 is ERC165, IERC721, IERC721Metadata, Ownable, OnChainMeta {
  using Address for address;
  using PoxLib for address;
  using Strings for uint256;
  address pStorage;

  /**
    A modifier to see if a caller is an approved administrator.
  */
  modifier onlyAdmin () {
    bool isAdmin = pStorage.getBool(keccak256(abi.encode('administrators', _msgSender())));
    if (_msgSender() != owner() && !isAdmin) {
      revert NotAnAdmin();
    }
    _;
  }

  function initialize(
    address _pStorage,
    string memory _name,
    string memory _symbol,
    uint256 _cap
  ) public onlyOwner {
    // bool initialized = pStorage.getBool(keccak256('initialized'));
    // if (initialized) { revert AlreadyInitialized(); }

    pStorage = _pStorage;
    pStorage.setString(keccak256('name'), _name);
    pStorage.setString(keccak256('symbol'), _symbol);
    pStorage.setNumber(keccak256('cap'), _cap);

    pStorage.setBool(keccak256('initialized'), true);
  }
  /**
   * @dev Resets the starting index for token ids.
   */
  function resetNextId() public onlyOwner {
    pStorage.setNumber(keccak256('nextId'), 1);
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return pStorage.getString(keccak256('name'));
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return pStorage.getString(keccak256('symbol'));
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
    return pStorage.getNumber(keccak256('nextId')) - 1;
  }

  /**
    Retrieve the number of distinct token IDs held by `_owner`.

    @param _owner The address to retrieve a count of held tokens for.

    @return The number of tokens held by `_owner`.
  */
  function balanceOf (
    address _owner
  ) external view override returns (uint256) {
    return pStorage.getNumber(keccak256(abi.encode('balances', _owner)));
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
        owner = pStorage.getAddress(keccak256(abi.encode('owners', curr)));
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
    return _id > 0 && _id < pStorage.getNumber(keccak256('nextId'));
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
    return pStorage.getAddress(keccak256(abi.encode('tokenApprovals', _id)));
    //return tokenApprovals[_id];
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
    return pStorage.getBool(keccak256(abi.encode('operatorApprovals', _owner, _operator)));
    //return operatorApprovals[_owner][_operator];
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
    // string memory metadataUri = pStorage.getString(keccak256('metadataURI'));
    // if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }
    // return bytes(metadataUri).length != 0
    //   ? string(abi.encodePacked(metadataUri, _id.toString()))
    //   : '';
    if (!_exists(_id)) { revert URIQueryForNonexistentToken(); }
    address owner = _ownershipOf(_id);
    return _buildMeta(_id, owner);
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
    pStorage.setAddress(keccak256(abi.encode('tokenApprovals', _id)), _to);
    //tokenApprovals[_id] = _to;
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
    pStorage.setBool(keccak256(abi.encode('operatorApprovals', _msgSender(), _operator)), _approved);
    //operatorApprovals[_msgSender()][_operator] = _approved;
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

    bool allTransfersLocked = pStorage.getBool(keccak256('allTransfersLocked'));
    if (allTransfersLocked) { revert TransferIsLockedGlobally(); }

    bool transfersLocked = pStorage.getBool(keccak256(abi.encode('transferLocks', _id)));
    if (transfersLocked) { revert TransferIsLocked(); }

    // Clear any token approval set by the previous owner.
    _approve(previousOwner, address(0), _id);

    /*
      Another Chiru Labs tip: we may safely use unchecked math here given the
      sender balance check and the limited range of our expected token ID space.
    */
    unchecked {
      uint256 fromBalance = pStorage.getNumber(keccak256(abi.encode('balances', _from)));
      pStorage.setNumber(keccak256(abi.encode('balances', _from)), fromBalance - 1);
      //balances[_from] -= 1;
      uint256 toBalance = pStorage.getNumber(keccak256(abi.encode('balances', _to)));
      pStorage.setNumber(keccak256(abi.encode('balances', _to)), toBalance - 1);
      //balances[_to] += 1;
      pStorage.setAddress(keccak256(abi.encode('owners', _id)), _to);
      //owners[_id] = _to;

      /*
        The way the gappy token ownership list is setup, we can tell that
        `_from` owns the next token ID if it has a zero address owner. This also
        happens to be what limits an efficient burn implementation given the
        current setup of this contract. We need to update this spot in the list
        to mark `_from`'s ownership of this portion of the token range.
      */
      uint256 nextTokenId = _id + 1;
      address ownersNext = pStorage.getAddress(keccak256(abi.encode('owners', nextTokenId)));
      if (ownersNext == address(0) && _exists(nextTokenId)) {
        pStorage.setAddress(keccak256(abi.encode('owners', nextTokenId)), previousOwner);
        //owners[nextTokenId] = previousOwner;
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
    pStorage.setBool(keccak256(abi.encode('administrators', _newAdmin)), _isAdmin);
    // administrators[_newAdmin] = _isAdmin;
  }

  /**
    Allow the item collection owner to update the metadata URI of this
    collection.

    @param _uri The new URI to update to.
  */
  function setURI (
    string calldata _uri
  ) external virtual onlyOwner {
    pStorage.setString(keccak256('metadataURI'), _uri);
    // metadataUri = _uri;
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
    pStorage.setBool(keccak256('allTransfersLocked'), _locked);
    //allTransfersLocked = _locked;
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
    pStorage.setBool(keccak256(abi.encode('transferLocks', _id)), _locked);
    // transferLocks[_id] = _locked;
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
  function mint (
    address _recipient,
    uint256 _amount
  ) external onlyAdmin {
    if (_recipient == address(0)) { revert MintToZeroAddress(); }
    if (_amount == 0) { revert MintZeroQuantity(); }
    uint256 nextId = pStorage.getNumber(keccak256('nextId'));
    uint256 cap = pStorage.getNumber(keccak256('cap'));
    if (nextId - 1 + _amount > cap) { revert CapExceeded(); }

    /**
      Inspired by the Chiru Labs implementation, we use unchecked math here.
      Only enormous minting counts that are unrealistic for our purposes would
      cause an overflow.
    */
    uint256 startTokenId = nextId;
    unchecked {
      uint256 recipBal = pStorage.getNumber(keccak256(abi.encode('balances', _recipient)));
      pStorage.setNumber(keccak256(abi.encode('balances', _recipient)), recipBal + _amount);
      //balances[_recipient] += _amount;
      pStorage.setAddress(keccak256(abi.encode('owners', startTokenId)), _recipient);
      //owners[startTokenId] = _recipient;

      uint256 updatedIndex = startTokenId;
      for (uint256 i; i < _amount; i++) {
        emit Transfer(address(0), _recipient, updatedIndex);
        updatedIndex++;
      }
      pStorage.setNumber(keccak256('nextId'), updatedIndex);
      //nextId = updatedIndex;

    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

contract PoxStorage {
  mapping(address => bool) Writers;

  mapping(bytes32 => uint256) UintStorage;

  function getUintValue( bytes32 _record ) public view returns (uint256) {
    return UintStorage[_record];
  }

  function setUintValue( bytes32 _record, uint256 _value ) public {
    UintStorage[_record] = _value;
  }

  mapping(bytes32 => address) AddressStorage;

  function getAddressValue( bytes32 _record ) public view returns (address) {
    return AddressStorage[_record];
  }

  function setAddressValue( bytes32 _record, address _value ) public {
    AddressStorage[_record] = _value;
  }

  mapping(bytes32 => string) StringStorage;

  function getStringValue( bytes32 _record ) public view returns (string memory) {
    return StringStorage[_record];
  }

  function setStringValue( bytes32 _record, string memory _value ) public {
    StringStorage[_record] = _value;
  }

  mapping(bytes32 => bool) BoolStorage;

  function getBoolValue( bytes32 _record ) public view returns (bool) {
    return BoolStorage[_record];
  }

  function setBoolValue( bytes32 _record, bool _value ) public {
    BoolStorage[_record] = _value;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;
import './PoxStorage.sol';

library PoxLib {
  function getBool(address _poxStorage, bytes32 _key) public view returns (bool) {
    return bool(PoxStorage(_poxStorage).getBoolValue( _key ));
  }

  function setBool(address _poxStorage, bytes32 _key, bool _value) public {
    return PoxStorage(_poxStorage).setBoolValue( _key, _value );
  }

  function getNumber(address _poxStorage, bytes32 _key) public view returns (uint256) {
    return PoxStorage(_poxStorage).getUintValue( _key );
  }

  function setNumber(address _poxStorage, bytes32 _key, uint256 _number) public {
    return PoxStorage(_poxStorage).setUintValue( _key, _number );
  }

  function getAddress(address _poxStorage, bytes32 _key) public view returns (address) {
    return PoxStorage(_poxStorage).getAddressValue( _key );
  }

  function setAddress(address _poxStorage, bytes32 _key, address _address) public {
    return PoxStorage(_poxStorage).setAddressValue( _key, _address );
  }

  function getString(address _poxStorage, bytes32 _key) public view returns (string memory) {
    return PoxStorage(_poxStorage).getStringValue( _key );
  }

  function setString(address _poxStorage, bytes32 _key, string memory _value) public {
    return PoxStorage(_poxStorage).setStringValue( _key, _value );
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './NFTSVG.sol';

contract OnChainMeta {
    using Strings for uint256;

    /// @dev A mask for isolating an item's group ID.
    uint256 private constant GROUP_MASK = uint256(type(uint128).max) << 128;

    string public metaDescription = 'This was inevitable.';

    function _buildMeta(uint256 _tokenId, address _owner) internal view returns (string memory) {

      string memory imageDat = string(abi.encodePacked(
        '{"name":"SEAGLASS #',
          _tokenId.toString(),
          '",',
          '"description":"',
             metaDescription,
          '",',
          '"image":"',
          'data:image/svg+xml;base64,',
            Base64.encode(bytes(_generateSVGImage(_tokenId, _owner))),
          '", "attributes":[',
             _getMetadata(_tokenId),
          ']',
        '}')
      );

      string memory image = string(abi.encodePacked(
        'data:application/json;base64,',
        Base64.encode(bytes(imageDat))
      ));

      return image;
    }

    function _getMetadata(uint256 _tokenId) internal pure returns (string memory) {
      uint256 groupId = (_tokenId & GROUP_MASK) >> 128;
      uint256 id = _tokenId << 128 >> 128;
      string memory metadata = string(abi.encodePacked(
        _wrapTrait("Generation", groupId.toString()),',',
        _wrapTrait("Identifier", id.toString())
      ));

      return metadata;
    }

    function _wrapTrait(string memory trait, string memory value) internal pure returns(string memory) {
        return string(abi.encodePacked(
            '{"trait_type":"',
            trait,
            '","value":"',
            value,
            '"}'
        ));
    }

    function _generateSVGImage(uint256 _tokenId, address _owner) internal view returns (string memory svg) {
      NFTSVG.SVGParams memory svgParams =
        NFTSVG.SVGParams({
          tokenId: _tokenId,
          block: block.number,
          owner: _owner
        });

      return NFTSVG.generateSVG(svgParams);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.11;

import '@openzeppelin/contracts/utils/Strings.sol';

library NFTSVG {
  using Strings for uint256;

  struct SVGParams {
    uint256 tokenId;
    uint256 block;
    address owner;
  }

  function generateSVG(SVGParams memory params) internal view returns (string memory svg) {
    ( , string memory base ) = idToColor(params.tokenId + 1, params.tokenId, params.owner);

    return
      string(
        abi.encodePacked(
          '<svg version="1.1" width="580" height="580" viewBox="0 0 580 580" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          '<rect width="580" height="580" x="0" y="0" fill="',
          base,
          '" />',
          _generateSVGPaths(params),
          '</svg>'
        )
      );
  }

  function _generateSVGPaths(SVGParams memory params) private view returns (string memory) {
    string memory svgPaths;

    uint256 pos_x = 40;
    uint256 pos_y = 40;
    uint256 w = 80;
    uint256 po = 40;
    ( , string memory base ) = idToColor(params.tokenId, params.tokenId + 1, params.owner);

    for(uint256 r = 0; r < 10; ++r){
      pos_x = 40;
      for(uint256 c = 0; c < 10; ++c){
        ( uint256 duration, string memory rgb ) = idToColor(params.tokenId, r*c+pos_x*pos_y*pos_y+pos_x+r, params.owner);
        //( uint256 duration2, string memory rgb2 ) = idToColor(params.tokenId, r*c+duration, params.owner);
        string memory pattern = string(abi.encodePacked(rgb, ';', base, ';', rgb));
        svgPaths = string(abi.encodePacked(
          svgPaths,
          '<rect width="',
          (duration+w).toString(),
          '" height="',
          (duration+w).toString(),
          '" x="',
          pos_x.toString(),
          '" y="',
          pos_y.toString(),
        //  '" style="stroke-width:3;stroke:rgb(0,0,0)">',

          // '<animateTransform attributeName="transform" type="scale" from="0.1" to="7.9" dur="',
          // (duration + c).toString(),
          // 's" repeatCount="indefinite" />'
          '" opacity=".2" rx="',
          (duration/4).toString(),
          '"><animate attributeName="fill" values="',
          pattern,
          '" dur="',
          (3+(duration/(c+1))).toString(),
          's" repeatCount="indefinite" /></rect>'
        ));
        pos_x = pos_x + po;
      }
      pos_y = pos_y + po;
    }

    return svgPaths;
  }

  function idToColor(uint256 _id, uint256 _cell, address _owner) public view returns (uint256, string memory) {
    uint256 seed = uint256(keccak256(abi.encodePacked(_id, _owner, _cell, address(this))));

    uint256 firstChunk = seed % 256;
    uint256 secondChunk = ((seed - firstChunk) / 256) % 256;
    uint256 thirdChunk = ((((seed- firstChunk) / 256) - secondChunk ) / 256) % 256;

    string memory rgbString = string(abi.encodePacked(
      'rgb(',
      firstChunk.toString(),
      ', ',
      secondChunk.toString(),
      ', ',
      thirdChunk.toString(),
      ')'
    ));

    if(thirdChunk > secondChunk){
      if(thirdChunk - secondChunk < 10){
        rgbString = string(abi.encodePacked('rgb(0,0,255)'));
      }
    }

    firstChunk = 256 - firstChunk;

    return (10 + (firstChunk * firstChunk % 64), rgbString);
   }
}