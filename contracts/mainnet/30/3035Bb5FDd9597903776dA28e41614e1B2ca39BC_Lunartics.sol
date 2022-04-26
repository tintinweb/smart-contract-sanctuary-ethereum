// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

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
contract Lunartics is
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

  /// Whether or not the transfer of a particular token ID is locked.
  mapping ( uint256 => bool ) private transferLocks;

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
        The way the gappy token ownership list is setup, we can tell that `_from` owns the next token ID if it has a zero address owner. This also happens to be what limits an efficient burn implementation given the current setup of this contract. We need to update this spot in the list to mark `_from`'s ownership of this portion of the token range.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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