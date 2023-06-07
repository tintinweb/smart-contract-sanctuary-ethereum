// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./PolyOneDrop.sol";
import "../interfaces/IPolyOneDrop.sol";

/**
 * @title PolyOne Fixed Price Drop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Implements the functionality required for Fixed Priced sales in the PolyOne contract ecosystem
 */
contract FixedPriceDrop is IPolyOneDrop, PolyOneDrop {
  constructor(address _polyOneCore) PolyOneDrop(_polyOneCore) {}

  function registerPurchaseIntent(
    uint256 _dropId,
    uint256 _tokenIndex,
    address, // _bidder
    uint256 _amount,
    bytes calldata
  ) external payable onlyPolyOneCore returns (bool, address, string memory, Royalties memory) {
    Drop memory drop = _validatePurchaseIntent(_dropId, _tokenIndex);
    if (_amount != drop.startingPrice) {
      revert InvalidPurchasePrice(_amount);
    }
    claimed[_dropId][_tokenIndex] = true;
    return (true, drop.collection, drop.baseTokenURI, drop.royalties);
  }

  function validateTokenClaim(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _claimant,
    bytes calldata
  ) external pure returns (address, string memory, Bid memory, Royalties memory) {
    revert InvalidClaim(_dropId, _tokenIndex, _claimant);
  }

  function listingActive(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return
      !claimed[_dropId][_tokenIndex] &&
      PolyOneLibrary.isDateInPast(drops[_dropId].startDate) &&
      !PolyOneLibrary.isDateInPast(drops[_dropId].startDate + drops[_dropId].dropLength);
  }

  function listingEnded(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return claimed[_dropId][_tokenIndex] || PolyOneLibrary.isDateInPast(drops[_dropId].startDate + drops[_dropId].dropLength);
  }

  function listingClaimed(uint256 _dropId, uint256 _tokenIndex) external view returns (bool) {
    return claimed[_dropId][_tokenIndex];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Core creator interface
 */
interface ICreatorCore is IERC165 {

    event ExtensionRegistered(address indexed extension, address indexed sender);
    event ExtensionUnregistered(address indexed extension, address indexed sender);
    event ExtensionBlacklisted(address indexed extension, address indexed sender);
    event MintPermissionsUpdated(address indexed extension, address indexed permissions, address indexed sender);
    event RoyaltiesUpdated(uint256 indexed tokenId, address payable[] receivers, uint256[] basisPoints);
    event DefaultRoyaltiesUpdated(address payable[] receivers, uint256[] basisPoints);
    event ApproveTransferUpdated(address extension);
    event ExtensionRoyaltiesUpdated(address indexed extension, address payable[] receivers, uint256[] basisPoints);
    event ExtensionApproveTransferUpdated(address indexed extension, bool enabled);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing ICreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external;

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external;

    /**
     * @dev blacklist an extension.  Can only be called by contract owner or admin.
     * This function will destroy all ability to reference the metadata of any tokens created
     * by the specified extension. It will also unregister the extension if needed.
     * Returns True if removed, False if already removed.
     */
    function blacklistExtension(address extension) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     */
    function setBaseTokenURIExtension(string calldata uri) external;

    /**
     * @dev set the baseTokenURI of an extension.  Can only be called by extension.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external;

    /**
     * @dev set the common prefix of an extension.  Can only be called by extension.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefixExtension(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token extension.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of a token extension for multiple tokens.  Can only be called by extension that minted token.
     */
    function setTokenURIExtension(uint256[] memory tokenId, string[] calldata uri) external;

    /**
     * @dev set the baseTokenURI for tokens with no extension.  Can only be called by owner/admin.
     * For tokens with no uri configured, tokenURI will return "uri+tokenId"
     */
    function setBaseTokenURI(string calldata uri) external;

    /**
     * @dev set the common prefix for tokens with no extension.  Can only be called by owner/admin.
     * If configured, and a token has a uri set, tokenURI will return "prefixURI+tokenURI"
     * Useful if you want to use ipfs/arweave
     */
    function setTokenURIPrefix(string calldata prefix) external;

    /**
     * @dev set the tokenURI of a token with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external;

    /**
     * @dev set the tokenURI of multiple tokens with no extension.  Can only be called by owner/admin.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external;

    /**
     * @dev set a permissions contract for an extension.  Used to control minting.
     */
    function setMintPermissions(address extension, address permissions) external;

    /**
     * @dev Configure so transfers of tokens created by the caller (must be extension) gets approval
     * from the extension before transferring
     */
    function setApproveTransferExtension(bool enabled) external;

    /**
     * @dev get the extension of a given token
     */
    function tokenExtension(uint256 tokenId) external view returns (address);

    /**
     * @dev Set default royalties
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of a token
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Set royalties of an extension
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external;

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    
    // Royalty support for various other standards
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
    function royaltyInfo(uint256 tokenId, uint256 value) external view returns (address, uint256);

    /**
     * @dev Set the default approve transfer contract location.
     */
    function setApproveTransfer(address extension) external; 

    /**
     * @dev Get the default approve transfer contract location.
     */
    function getApproveTransfer() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @title Interface for PolyOneCreator
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Interface for the PolyOneCreator Proxy contract
 */
interface IPolyOneCreator {
  /**
   * @notice The original creator of the contract. This is the only address that can reclaim ownership of the contract from PolyOneCore
   * @return The address of the creator
   */
  function creator() external view returns (address);

  /**
   * @notice The address of the Manifold implementation contract (ERC721CreatorImplementation or ERC1155CreatorImplementation)
   * @return The address of the implementation contract
   */
  function implementation() external view returns (address);
}

/**
 * @title PolyOneCreator
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @custom:contributor manifoldxyz (manifold.xyz)
 * @notice Deployable Proxy contract that delagates implementation to Manifold Core and registers the PolyOneCore contract as administrator
 */
contract PolyOneCreator is Proxy, IPolyOneCreator {
  address public immutable creator;

  /**
   * @param _name The name of the collection
   * @param _symbol The symbol for the collection
   * @param _implementationContract The address of the Manifold implementation contract (ERC721CreatorImplementation or ERC1155CreatorImplementation)
   * @param _polyOneCore The address of the PolyOneCore contract
   */
  constructor(string memory _name, string memory _symbol, address _implementationContract, address _polyOneCore) {
    assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = _implementationContract;

    require(_implementationContract != address(0), "Implementation cannot be 0x0");
    (bool initSuccess, ) = _implementationContract.delegatecall(abi.encodeWithSignature("initialize(string,string)", _name, _symbol));
    require(initSuccess, "Initialization failed");

    require(_polyOneCore != address(0), "PolyOneCore cannot be 0x0");
    (bool approvePolyOneSuccess, ) = _implementationContract.delegatecall(
      abi.encodeWithSignature("transferOwnership(address)", _polyOneCore)
    );
    require(approvePolyOneSuccess, "PolyOneCore transfer failed");

    creator = msg.sender;
  }

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function implementation() public view returns (address) {
    return _implementation();
  }

  function _implementation() internal view override returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../implementations/PolyOneCreator.sol";
import "../interfaces/IPolyOneCore.sol";
import "../interfaces/IPolyOneDrop.sol";
import "../libraries/PolyOneLibrary.sol";

/**
 * @title PolyOneDrop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Partial abstract implementation of shared functionality for drop contracts
 */
abstract contract PolyOneDrop is IPolyOneDrop, ERC165 {
  IPolyOneCore public polyOneCore;

  mapping(uint256 dropId => Drop dropParameters) public drops;
  mapping(uint256 dropId => mapping(uint256 tokenIndex => bool isClaimed)) public claimed;

  constructor(address _polyOneCore) {
    PolyOneLibrary.checkZeroAddress(_polyOneCore, "poly one core");
    polyOneCore = IPolyOneCore(_polyOneCore);
  }

  function createDrop(uint256 _dropId, Drop calldata _drop, bytes calldata) external onlyPolyOneCore {
    PolyOneLibrary.checkZeroAddress(_drop.collection, "collection");
    if (_dropExists(_dropId)) {
      revert DropAlreadyExists(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(_drop.startDate)) {
      revert InvalidDate(_drop.startDate);
    }

    drops[_dropId] = _drop;
  }

  function updateDrop(uint256 _dropId, Drop calldata _drop, bytes calldata) external onlyPolyOneCore {
    if (!_dropExists(_dropId)) {
      revert DropNotFound(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(drops[_dropId].startDate)) {
      revert DropInProgress(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(_drop.startDate)) {
      revert InvalidDate(_drop.startDate);
    }

    drops[_dropId] = Drop(
      _drop.startingPrice,
      _drop.bidIncrement,
      _drop.qty,
      _drop.startDate,
      _drop.dropLength,
      drops[_dropId].collection,
      _drop.baseTokenURI,
      _drop.royalties
    );
  }

  function updateDropRoyalties(uint256 _dropId, Royalties calldata _royalties) external onlyPolyOneCore {
    if (!_dropExists(_dropId)) {
      revert DropNotFound(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(drops[_dropId].startDate)) {
      revert DropInProgress(_dropId);
    }

    drops[_dropId].royalties = _royalties;
  }

  /**
   * @dev Validate the purchase intent of a token in a drop
   * @param _dropId The drop id
   * @param _tokenIndex The index of the token in the drop
   * @return The drop parameters
   */
  function _validatePurchaseIntent(uint256 _dropId, uint256 _tokenIndex) internal view returns (Drop memory) {
    if (!_dropExists(_dropId)) {
      revert DropNotFound(_dropId);
    }
    Drop memory drop = drops[_dropId];
    if (_tokenIndex > drop.qty) {
      revert TokenNotFoundInDrop(_dropId, _tokenIndex);
    }
    if (claimed[_dropId][_tokenIndex]) {
      revert TokenAlreadyClaimed(_dropId, _tokenIndex);
    }
    if (!PolyOneLibrary.isDateInPast(drop.startDate)) {
      revert DropNotStarted(_dropId);
    }
    if (PolyOneLibrary.isDateInPast(drop.startDate + drop.dropLength)) {
      revert DropFinished(_dropId);
    }
    return drop;
  }

  /**
   * @dev Check if a drop has been previously created on this contract
   */
  function _dropExists(uint256 _dropId) internal view returns (bool) {
    return drops[_dropId].collection != address(0);
  }

  /**
   * @dev Validate a claim on behalf of a claimant
   *      This should allow the creator or an admin of PolyOneCore to initiate the claim process
   * @param _dropId The id of the drop to validate
   * @param _caller The address of the caller
   * @return True if the claim is valid
   */
  function _validateDelegatedClaim(uint256 _dropId, address _caller) internal view returns (bool) {
    return
      (IAccessControl(address(polyOneCore)).hasRole(polyOneCore.POLY_ONE_ADMIN_ROLE(), _caller)) ||
      _caller == IPolyOneCreator(drops[_dropId].collection).creator();
  }

  /**
   * @dev Functions with the onlyPolyOneCore modifier attached should only be callable by the PolyOne Core contract
   */
  modifier onlyPolyOneCore() {
    if (msg.sender != address(polyOneCore)) {
      revert PolyOneLibrary.InvalidCaller(msg.sender);
    }
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IPolyOneDrop).interfaceId || super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../interfaces/IPolyOneDrop.sol";

/**
 * @title Interface for PolyOne Core
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Performs core functionality to faciliate the creation of drops, listings and administrative functions
 */
interface IPolyOneCore {
  /**
   * @dev Structure of the parameters required for the registering of a new collection
   * @param registered Whether the collection is registered
   * @param isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   * @param tokenIds Mapping of dropIds to tokenIds for ERC1155 collections. (Set by the first token mint for a drop)
   */
  struct Collection {
    bool registered;
    bool isERC721;
  }

  /**
   * @notice Thrown if a contract address is already registered
   * @param contractAddress The address of the contract
   */
  error AddressAlreadyRegistered(address contractAddress);

  /**
   * @notice Thrown if a collection was expected to be registered but currently isn't
   * @param collection The address of the collection contract
   */
  error CollectionNotRegistered(address collection);

  /**
   * @notice Thrown if an unregistered contract is being used to create a drop
   * @param dropContract The address of the unregistered contract
   */
  error DropContractNotRegistered(address dropContract);

  /**
   * @dev Thrown if a transfer of eth fails
   * @param destination The intented recipient
   * @param amount The amount of eth to be transferred
   */
  error EthTransferFailed(address destination, uint256 amount);

  /**
   * @dev Thrown if attempting to transfer an invalid eth amount
   */
  error InvalidEthAmount();

  /**
   * @dev Thrown if attempting to interact with a collection that is not of the expected type
   * @param collection The address of the collection contract
   */
  error CollectionTypeMismatch(address collection);

  /**
   * @dev Thrown if attempting to create or update a drop with invalid royalty settings
   */
  error InvalidRoyaltySettings();

  /**
   * @dev Thrown if attempting to create or update a drop with invalid PolyOne fee settings
   */
  error InvalidPolyOneFee();

  /**
   * @dev Thrown if attempting to create or udpate a drop without including the PolyOne fee wallet
   */
  error FeeWalletNotIncluded();

  /**
   * @dev Thrown if an arbitrary call to a collection contract fails
   * @param error The error thrown by the contract being called
   */
  error CallCollectionFailed(bytes error);

  /**
   * @notice Emitted when a creator is allowed to access the PolyOne contract ecosystem
   * @param creator address of the creator
   */
  event CreatorAllowed(address indexed creator);

  /**
   * @notice Emitted when a creator is revoked access to the PolyOne contract ecosystem
   * @param creator address of the creator
   */
  event CreatorRevoked(address indexed creator);

  /**
   * @notice Emitted when a drop contract is registered
   * @param dropContract The address of the drop contract implementation
   */
  event DropContractRegistered(address indexed dropContract);

  /**
   * @notice Emitted when a new token collection is registered
   * @param collection The address of the collection contract
   * @param creator The address of the creator who owns the contract
   * @param isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  event CollectionRegistered(address indexed collection, address indexed creator, bool isERC721);

  /**
   * @notice Emitted when a new drop is created for a collection
   * @param dropContract The address of the drop contract for which the drop was created
   * @param dropId the id of the newly created drop
   */
  event DropCreated(address indexed dropContract, uint256 dropId);

  /**
   * @notice Emitted when a purchase intent is created for an auction or fixed price drop
   * @param dropContract The address of the drop contract for which the purchase intent was created
   * @param dropId The id of the drop for which the purchase intent was created
   * @param tokenIndex The index of the token in the drop for which the purchase intent was created
   * @param bidder The address of the bidder who registered the purchase intent
   * @param amount The amount of the purchase
   */
  event PurchaseIntentRegistered(address indexed dropContract, uint256 dropId, uint256 tokenIndex, address indexed bidder, uint256 amount);

  /**
   * @notice Emitted when a token is claimed by a claimant
   * @param collection The address of the token contract
   * @param tokenId The id of the newly minted token
   * @param dropId The id of the drop from which the token was minted
   * @param tokenIndex The index of the token in the drop
   * @param claimant The address of the claimant
   */
  event TokenClaimed(address indexed collection, uint256 tokenId, uint256 dropId, uint256 tokenIndex, address indexed claimant);

  /**
   * @notice Emitted when an existing drop is updated
   * @param dropContract The address of the drop contract for which teh drop was updated
   * @param _dropId The id of the drop that was updated
   */
  event DropUpdated(address indexed dropContract, uint256 _dropId);

  /**
   * @notice Emitted when the PolyOne fee wallet is updated
   * @param feeWallet The new PolyOne fee wallet
   */
  event FeeWalletUpdated(address feeWallet);

  /**
   * @notice Emitted when the PolyOne default primary or secondary fees are updated
   * @param primaryFee The new primary sale fee
   * @param secondaryFee The new secondary sale fee
   */
  event DefaultFeesUpdated(uint16 primaryFee, uint16 secondaryFee);

  /**
   * @notice Emitted when a collection contract is called with arbitrary calldata
   * @param collection The address of the collection contract
   * @param caller The address of the caller
   * @param data The data passed to the collection contract
   */
  event CollectionContractCalled(address indexed collection, address indexed caller, bytes data);

  /**
   * @notice Allow a creator to access the PolyOne contract ecosystem
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CreatorAllowed} event
   * @param _creator address of the creator
   */
  function allowCreator(address _creator) external;

  /**
   * @notice Revoke creator access from the PolyOne contract ecosystem
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CreatorRevoked} event
   * @param _creator address of the creator
   */
  function revokeCreator(address _creator) external;

  /**
   * @notice Register a new drop contract implementation to be used for Poly One token drops
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {DropContractRegistered} event
   *      _dropContract must implement the IPolyOneDrop interface
   * @param _dropContract The address of the drop contract implementation
   */
  function registerDropContract(address _dropContract) external;

  /**
   * @notice Register an ERC721 or ERC1155 collection to the PolyOne ecosystem
   * @dev The contract must extend the ERC721Creator or ERC1155Creator contracts to be compatible.
   *      Only callable by the POLY_ONE_CREATOR_ROLE, and caller must be the contract owner.
   *      The PolyOneCore contract must be assigned as an admin in the collection contract.
   *      Emits a {CollectionRegistered} event.
   * @param _collection The address of the token contract to register
   * @param _isERC721 Is the contract an ERC721 standard (true) or ERC1155 (false)
   */
  function registerCollection(address _collection, bool _isERC721) external;

  /**
   * @notice Create a new drop for an already registered collection and tokens that are already minted
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Caller must be assigned as the owner of the contract in the PolyOneCore contract
   *      Emits a {DropCreated} event
   * @param _dropContract The implementation contract for the drop to be created
   * @param _drop The drop parameters (see {NewDrop} struct)
   * @param _data Any additional data that should be passed to the drop contract
   * */
  function createDrop(address _dropContract, IPolyOneDrop.Drop memory _drop, bytes calldata _data) external;

  /**
   * @notice Update an existing drop.
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Caller must be assigned as the owner of the contract in the PolyOneCore contract
   *      Emits a {DropUpdated} event
   *      The collection address will be excluded from the update
   *      The drop must not have started yet
   * @param _dropId The id of the previously created drop to update
   * @param _dropContract The address of the drop contract to which the drop is registered
   * @param _drop The updated drop information (not that collection address will be excluded)
   * @param _data Any additional data that should be passed to the drop contract
   */
  function updateDrop(uint256 _dropId, address _dropContract, IPolyOneDrop.Drop memory _drop, bytes calldata _data) external;

  /**
   * @notice Update the royalties
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   *      Emits a {DropUpdatedEvent}
   *      The drop must not have started yet
   *      Only the total of saleReceivers are validated, there is not validation that PolyOne fees are included
   * @param _dropId The id of the previously created drop to update
   * @param _dropContract The address of the drop contract to which the drop is registered
   * @param _royalties The updated royalties information
   */
  function updateDropRoyalties(uint256 _dropId, address _dropContract, IPolyOneDrop.Royalties memory _royalties) external;

  /**
   * @notice Register a bid for an existing drop
   * @dev Will call to an external contract for the bidding implementation depending on the drop type
   *      Emits a {PurchaseIntentRegistered} event
   * @param _dropId The id of the drop to register a bid for
   * @param _dropContract The contract for the type of drop to claim a token from
   * @param _tokenIndex The index of the token in the drop to bid on
   * @param _data Any additional data that should be passed to the drop contract
   */
  function registerPurchaseIntent(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data) external payable;

  /**
   * @notice Claim a token that has been won in an auction style drop
   * @dev This will always revert for fixed price (instant) style drops as the token has already been claimed
   *      Only callable by the winner of the sale
   * @param _dropId The id of the drop to claim a token from
   * @param _dropContract The contract for the type of drop to claim a token from
   * @param _tokenIndex The index in the drop of the token to claim
   * @param _data Any additional data that should be passed to the drop contract
   */
  function claimToken(uint256 _dropId, address _dropContract, uint256 _tokenIndex, bytes calldata _data) external;

  /**
   * @notice Mint new tokens to an existing registered ERC721 collection.
   *         This can be called by the creator of the collection to mint individual tokens that are not listed
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   * @param _collection The address of the collection to mint the token for
   * @param _recipient The recipient of the tokens
   * @param _qty The number of tokens being minted
   * @param _baseTokenURI The base tokenURI the tokens to be minted
   * @param _royaltyReceivers The addresses to receive seconary royalties (not including PolyOne fees)
   * @param _royaltyBasisPoints The percentage of royalties for each wallet to receive (in bps)
   */
  function mintTokensERC721(
    address _collection,
    address _recipient,
    uint256 _qty,
    string calldata _baseTokenURI,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints
  ) external;

  /**
   * @notice Mint new tokens to an existing registered ERC1155 collection.
   *         This can be called by the creator of the collection to mint individual tokens that are not listed
   * @dev Only callable by the POLY_ONE_CREATOR_ROLE
   * @param _collection The address of the collection to mint the token for
   * @param _tokenURIs The base tokenURI for each new token to be minted
   * @param _tokenIds The ids of the tokens to mint
   * @param _royaltyReceivers The addresses to receive seconary royalties (not including PolyOne fees)
   * @param _royaltyBasisPoints The percentage of royalties for each wallet to receive (in bps)
   * @param _receivers The addresses to mint tokens to
   * @param _amounts The amounts of tokens to mint to each address
   * @param _existingTokens Is the set of tokens already existing in the collection (true) or a new batch of tokens (false). Cannot be mixed
   */
  function mintTokensERC1155(
    address _collection,
    string[] calldata _tokenURIs,
    uint256[] calldata _tokenIds,
    address payable[] memory _royaltyReceivers,
    uint256[] memory _royaltyBasisPoints,
    address[] calldata _receivers,
    uint256[] calldata _amounts,
    bool _existingTokens
  ) external;

  /**
   * @notice Make an arbitrary contract call to the collection contract
   * @dev Only callable by the POLY_ONE_ADMIN_ROLE
   *      Emits a {CollectionContractCalled} event
   * @param _data The data to call the collection contract with
   */
  function callCollectionContract(address _collection, bytes calldata _data) external;

  /**
   * @notice Mapping of drop contracts to whether they are registered
   * @param _dropContract The address of the drop contract
   * @return A boolean indicating whether the drop contract is registered
   */
  function dropContracts(address _dropContract) external view returns (bool);

  /**
   * @notice Mapping of token contract addresses to their collection data
   * @param _collection The address of the collection token contract
   * @return registered Whether the collection is registered
   * @return isERC721 Whether the collection is an ERC721 (true) or ERC1155 (false)
   */
  function collections(address _collection) external view returns (bool registered, bool isERC721);

  /**
   * @notice Mapping of dropIds to the tokenId assigned to the drop for ERC1155 mints to differentiate between new and existing mint cases
   * @param _dropId The id of the drop to get the token id for
   * @return The tokenId assigned to the drop
   */
  function dropTokenIds(uint256 _dropId) external view returns (uint256);

  /**
   * @notice The number of drops that have been created. This counter is used to create incremental ids for each new drop registered
   * @dev The counter is incremented before the new drop is created, hence the first drop is always 1
   */
  function dropCounter() external view returns (uint256);

  /**
   * @notice The PolyOne fee wallet to collection primary and secondary sales
   */
  function feeWallet() external view returns (address payable);

  /**
   * @notice The default primary sale fee to apply to new collections and drops (in bps)
   */
  function defaultPrimaryFee() external view returns (uint16);

  /**
   * @notice The default secondary sale fee to apply to new collections and drops (in bps)
   */
  function defaultSecondaryFee() external view returns (uint16);

  /**
   * @notice Set the address for PolyOne fees from primary and secondary sales to be sent to
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _feeWallet The new fee wallet
   */
  function setFeeWallet(address payable _feeWallet) external;

  /**
   * @notice Set the default primary fee that is applied to new collections
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _newFee The new fee to set
   */
  function setDefaultPrimaryFee(uint16 _newFee) external;

  /**
   * @notice Set the default secondary fee that is applied to new collection
   * @dev Only callable by POLY_ONE_ADMIN_ROLE
   * @param _newFee The new fee to set
   */
  function setDefaultSecondaryFee(uint16 _newFee) external;

  /**
   * @notice Send eth to an address including error handling
   * @dev Only callable internally or by registered PolyOneDrop contracts
   * @param _destination The address to send the amount to
   * @param _amount The amount to send (in wei)
   */
  function transferEth(address _destination, uint256 _amount) external;

  /**
   * @notice Poly One Administrators allowed to perform administrative functions
   * @return The bytes32 representation of the POLY_ONE_ADMIN_ROLE
   */
  function POLY_ONE_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Poly One Creators allowed to mint new collections and create listings for their tokens
   * @return The bytes32 representation of the POLY_ONE_CREATOR_ROLE
   */
  function POLY_ONE_CREATOR_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title Interface for PolyOne Drop
 * @author Developed by Labrys on behalf of PolyOne
 * @custom:contributor mfbevan (mfbevan.eth)
 * @notice Base interface for the creation of PolyOne drop listing contracts
 */
interface IPolyOneDrop {
  /**
   * @dev Structure of parameters required for the creation of a new drop
   * @param startingPrice The starting price of the drop
   * @param bidIncrement The bid increment of the drop (can be left as zero for fixed-price drops)
   * @param qty The quantity of tokens in the drop
   * @param startDate The start date of the drop (in seconds)
   * @param dropLength The length of the drop (in seconds)
   * @param collection The address of the collection that the drop was created for
   * @param baseTokenURI The tokenURI that the drop will use for the minted token metadata
   * @param royalties THe primary and secondary royalties for the drop
   */
  struct Drop {
    uint256 startingPrice;
    uint128 bidIncrement;
    uint128 qty;
    uint64 startDate;
    uint64 dropLength;
    address collection;
    string baseTokenURI;
    Royalties royalties;
  }

  /**
   * @dev Structure of parameters required for primary sale and secondary royalties
   *      This must include PolyOne's primary sale and secondary royalties
   *      The secondary royalties are optional but the primary sale royalties are not (they must total 100% in bps)
   * @param royaltyReceivers The addresses of the secondary royalty receivers. The PolyOne fee wallet should be the first in the array
   * @param royaltyBasisPoints The basis points of each of the secondary royalty receivers
   * @param saleReceivers The addresses of the primary sale receivers. The PolyOne fee wallet should be the first in the array
   * @param saleBasisPoints The basis points of each of the primary sale receivers
   */
  struct Royalties {
    address payable[] royaltyReceivers;
    uint256[] royaltyBasisPoints;
    address payable[] saleReceivers;
    uint256[] saleBasisPoints;
  }

  /**
   * @dev Structure of parameters required for a bid on a drop
   * @param bidder The address of the bidder
   * @param amount The value of the bid in wei
   */
  struct Bid {
    address bidder;
    uint256 amount;
  }

  /**
   * @dev Thrown if a drop is being access that does not exist on the drop contract
   * @param dropId The id of the drop that does not exist
   */
  error DropNotFound(uint256 dropId);

  /**
   * @dev Thrown if a token is being accessed that does not exist in a drop (i.e token index out of the drop range)
   * @param dropId The id of the drop being accessed
   * @param tokenIndex The index of the token being accessed
   */
  error TokenNotFoundInDrop(uint256 dropId, uint256 tokenIndex);

  /**
   * @dev Thrown if a drop is being created that already exists on the drop contract
   * @param dropId The id of the drop that already exists
   */
  error DropAlreadyExists(uint256 dropId);

  /**
   * @dev Thrown when attempting to modify a date that is not permitted (e.g a date in the past)
   * @param date The date that is invalid
   */
  error InvalidDate(uint256 date);

  /**
   * @dev Thrown if attempting to purchase a drop which has not started yet
   * @param dropId The id of the drop
   */
  error DropNotStarted(uint256 dropId);

  /**
   * @dev Thrown if attempting to purchase a drop which has already finished
   * @param dropId The id of the drop
   */
  error DropFinished(uint256 dropId);

  /**
   * @dev Thrown if attempting to claim a drop which has not yet finished
   * @param dropId The id of the drop
   */
  error DropInProgress(uint256 dropId);

  /**
   * @dev Thrown if attempting to purchase or bid on a token with an invalid amount
   * @param price The price that was attempted to be paid
   */
  error InvalidPurchasePrice(uint256 price);

  /**
   * @dev Thrown if attempting to purchase or claim a token that has already been claimed
   * @param dropId The id of the drop
   * @param tokenIndex The index of the token in the drop
   */
  error TokenAlreadyClaimed(uint256 dropId, uint256 tokenIndex);

  /**
   * @dev Thrown if attempting to purchase or claim a token that has already been claimed or is not claimable by the caller
   * @param dropId The id of the drop
   * @param tokenIndex The index of the token
   * @param claimant The address attempting to claim a token
   */
  error InvalidClaim(uint256 dropId, uint256 tokenIndex, address claimant);

  /**
   * @notice Registers a new upcoming drop
   * @param _dropId The id of the new drop to create
   * @param _drop The parameters for the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function createDrop(uint256 _dropId, Drop calldata _drop, bytes calldata _data) external;

  /**
   * @notice Update an existing drop
   * @param _dropId The id of the existing drop
   * @param _drop The updated parameters for the drop
   * @param _data Any additional data that should be passed to the drop contract
   */
  function updateDrop(uint256 _dropId, Drop calldata _drop, bytes calldata _data) external;

  /**
   * @notice Update the royalties for an existing drop
   * @param _dropId The id of the existing drop
   * @param _royalties The updated royalties for the drop
   */
  function updateDropRoyalties(uint256 _dropId, Royalties calldata _royalties) external;

  /**
   * @notice Register a bid (or intent to purchase) a token from PolyOne
   * @dev For fixed price drops, the amount must be equal to the starting price, and the token will be transferred instantly.
   *      For auction style drops, the amount must be greater than the starting price.
   * @param _dropId The id of the drop to place a purchase for
   * @param _tokenIndex The index of the token to purchase in this drop
   * @param _bidder The address of the bidder
   * @param _amount The amount of the purchase intent (in wei)
   * @param _data Any additional data that should be passed to the drop contract
   * @return instantClaim Whether this should be an instant claim (for fixed priced drop) or not (for auction style drops)
   * @return collection The collection address of the new token to be minted (if instant claim is also true)
   * @return tokenURI The token URI of the new token to be minted (if instant claim is also true)
   * @return royalties The royalties for the new token to be minted (if instant claim is also true)
   */
  function registerPurchaseIntent(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _bidder,
    uint256 _amount,
    bytes calldata _data
  ) external payable returns (bool instantClaim, address collection, string memory tokenURI, Royalties memory royalties);

  /**
   * @notice Validates that a token is allowed to be claimed by the claimant based on the status of the drop
   * @dev This will always revert for fixed price drops (where the bid increment is zero)
   *      This will return the claim data for fixed price drops if the token has been won by the claimaint and the auction has ended
   * @param _dropId The id of the drop to claim a token from
   * @param _tokenIndex The index of the token to claim
   * @param _caller The address of the claimant
   * @param _data Any additional data that should be passed to the drop contract
   * @return collection The collection address of the new token to be minted
   * @return tokenURI The token URI of the new token to be minted
   * @return claim The winning claim information (bidder and bid amount)
   * @return royalties The royalties for the new token to be minted
   */
  function validateTokenClaim(
    uint256 _dropId,
    uint256 _tokenIndex,
    address _caller,
    bytes calldata _data
  ) external returns (address collection, string memory tokenURI, Bid memory claim, Royalties memory royalties);

  /**
   * @notice Mapping of drop ids to the drop parameters
   * @param startingPrice The starting price of the drop
   * @param bidIncrement The bid increment of the drop (can be left as zero for fixed-price drops)
   * @param qty The quantity of tokens in the drop
   * @param startDate The start date of the drop (in seconds)
   * @param dropLength The length of the drop (in seconds)
   * @param collection The address of the collection that the drop was created for
   * @param baseTokenURI The tokenURI that the drop will use for the minted token metadata
   * @param royalties THe primary and secondary royalties for the drop
   */
  function drops(
    uint256 _id
  )
    external
    view
    returns (
      uint256 startingPrice,
      uint128 bidIncrement,
      uint128 qty,
      uint64 startDate,
      uint64 dropLength,
      address collection,
      string memory baseTokenURI,
      Royalties memory royalties
    );

  /**
   * @notice Check if there is a currently active listing for a token
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingActive(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);

  /**
   * @notice Check if a token was previously listed and it has now ended either due to time or being claimed
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingEnded(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);

  /**
   * @notice Check the current claimed status of a listing
   * @param _dropId The id of the drop
   * @param _tokenIndex The index of the token in the drop
   */
  function listingClaimed(uint256 _dropId, uint256 _tokenIndex) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@manifoldxyz/creator-core-solidity/contracts/core/ICreatorCore.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../implementations/PolyOneCreator.sol";
import "../interfaces/IPolyOneDrop.sol";

/**
 * @notice Shared helpers for Poly One contracts
 */
library PolyOneLibrary {
  /**
   * @dev Thrown whenever a zero-address check fails
   * @param field The name of the field on which the zero-address check failed
   */
  error ZeroAddress(string field);

  /**
   * @notice Thrown when attempting to validate a collection which is not of the expected ERC721Creator or ERC1155Creator type
   */
  error InvalidContractType();

  /**
   * @notice Throw if the caller is not the expected caller
   * @param _caller The caller of the function
   */
  error InvalidCaller(address _caller);

  /**
   * @notice Thrown if the total sale distribution percentage is not 100
   */
  error InvalidSaleDistribution();

  /**
   * @notice Thrown if an array total does not match
   */
  error ArrayTotalMismatch();

  /**
   * @notice Check if a field is the zero address, if so revert with the field name
   * @param _address The address to check
   * @param _field The name of the field to check
   */
  function checkZeroAddress(address _address, string memory _field) internal pure {
    if (_address == address(0)) {
      revert ZeroAddress(_field);
    }
  }

  bytes4 constant ERC721_INTERFACE_ID = type(IERC721Metadata).interfaceId;
  bytes4 constant ERC1155_INTERFACE_ID = type(IERC1155MetadataURI).interfaceId;
  bytes4 constant CREATOR_CORE_INTERFACE_ID = type(ICreatorCore).interfaceId;

  /**
   * @notice Validate that a contract conforms to the expected standard by validating the interface support of an implementation contract
   *         via ERC165 `supportInterface` (see https://eips.ethereum.org/EIPS/eip-165)
   * @dev This will throw an unexpected error if the contract does not support ERC165
   * @param _contractAddress The address of the contract to validate
   * @param _isERC721 Whether the contract is an ERC721 (true) or ERC1155 (false)
   */
  function validateProxyCreatorContract(address _contractAddress, bool _isERC721) internal view {
    bytes4 expectedInterfaceId = _isERC721 ? ERC721_INTERFACE_ID : ERC1155_INTERFACE_ID;
    IERC165 implementation = IERC165(IPolyOneCreator(_contractAddress).implementation());
    if (!implementation.supportsInterface(expectedInterfaceId) || !implementation.supportsInterface(CREATOR_CORE_INTERFACE_ID)) {
      revert InvalidContractType();
    }
  }

  /**
   * @notice Validate that a contract implements the IPolyOneDrop interface
   * @param _contractAddress The address of the contract to validate
   */
  function validateDropContract(address _contractAddress) internal view {
    IERC165 implementation = IERC165(_contractAddress);
    if (!implementation.supportsInterface(type(IPolyOneDrop).interfaceId)) {
      revert InvalidContractType();
    }
  }

  /**
   * @notice Validate that a caller is the owner of a collection
   * @dev The contract address being check must inerit the OpenZeppelin Ownable standard
   * @param _contractAddress The address of the collection to validate
   * @param _caller The address of the owner to validate
   * @return True if the caller is the owner of the contract
   */
  function validateContractOwner(address _contractAddress, address _caller) internal view returns (bool) {
    address owner = Ownable(_contractAddress).owner();
    if (owner != _caller) {
      revert InvalidCaller(_caller);
    }
    return true;
  }

  /**
   * @notice Validate that a caller is the creator of a PolyOneCreator contract
   * @param _contractAddress The address of the collection to validate
   * @param _caller The address of the caller to validate
   * @return True if the caller is the creator of the contract
   */
  function validateContractCreator(address _contractAddress, address _caller) internal view returns (bool) {
    address creator = IPolyOneCreator(_contractAddress).creator();
    if (creator != _caller) {
      revert InvalidCaller(_caller);
    }
    return true;
  }

  /**
   * @notice Check if a date is in the past (before the current block timestamp)
   *         If the timestamps are equal, this is considered to be in the future
   */
  function isDateInPast(uint256 _date) internal view returns (bool) {
    return block.timestamp > _date;
  }

  /**
   * @dev Validate that the sum of all items in a uint array is equal to a given total
   * @param _array The array to validate
   * @param _total The total to validate against
   */
  function validateArrayTotal(uint256[] memory _array, uint256 _total) internal pure {
    uint256 total = 0;
    for (uint i = 0; i < _array.length; i++) {
      total += _array[i];
    }
    if (total != _total) {
      revert ArrayTotalMismatch();
    }
  }

  /**
   * @dev Convert an address to an array of length 1 with a single address
   * @param _address The address to convert
   * @return A length 1 array containing _address
   */
  function addressToAddressArray(address _address) internal pure returns (address[] memory) {
    address[] memory array = new address[](1);
    array[0] = _address;
    return array;
  }

  /**
   * @dev Convert a uint to an array of length 1 with a single address
   * @param _uint The uint to convert
   * @return A length 1 array containing _uint
   */
  function uintToUintArray(uint256 _uint) internal pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = _uint;
    return array;
  }

  /**
   * @dev Convert a string array to an array of length 1 with a single string
   * @param _string The string to convert
   * @return A length 1 array containing _string
   */
  function stringToStringArray(string memory _string) internal pure returns (string[] memory) {
    string[] memory array = new string[](1);
    array[0] = _string;
    return array;
  }
}