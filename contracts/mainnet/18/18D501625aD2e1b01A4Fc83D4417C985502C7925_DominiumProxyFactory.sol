// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
                        Strings.toHexString(uint160(account), 20),
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract ExtendedAccessControl is AccessControl {
    function _grantRole(bytes32 role, address[] memory accounts) internal {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(
                accounts[i] != address(0),
                "ExtendedAccessControl: Address zero"
            );

            _grantRole(role, accounts[i]);
        }
    }

    /// @dev Overriding to disallow revoking the DEFAULT_ADMIN_ROLE role
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            role != DEFAULT_ADMIN_ROLE,
            "ExtendedAccessControl: incapable of renouncing default admin"
        );

        AccessControl.renounceRole(role, account);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ExtendedAccessControl} from "./ExtendedAccessControl.sol";

/// @author Amit Molek
/// @dev Role-based managment based on OpenZeppelin's AccessControl.
/// This contract gives 2 roles: the `admin` and `managers`. Both of them
/// can access restricted functions but only the `admin` can add/remove `managers`
/// and create new roles.
contract Manageable is ExtendedAccessControl {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    constructor(address admin, address[] memory managers) {
        require(admin != address(0), "Manageable: admin address zero");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MANAGER_ROLE, managers);
    }

    modifier onlyAuthorized() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(MANAGER_ROLE, msg.sender),
            "Manageable: Unauthorized access"
        );
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Antic fee collector address provider interface
/// @author Amit Molek
interface IAnticFeeCollectorProvider {
    /// @dev Emitted on transfer of the Antic's fee collector address
    /// @param previousCollector The previous fee collector
    /// @param newCollector The new fee collector
    event AnticFeeCollectorTransferred(
        address indexed previousCollector,
        address indexed newCollector
    );

    /// @dev Emitted on changing the Antic fees
    /// @param oldJoinFee The previous join fee percentage out of 1000
    /// @param newJoinFee The new join fee percentage out of 1000
    /// @param oldSellFee The previous sell fee percentage out of 1000
    /// @param newSellFee The new sell fee percentage out of 1000
    event AnticFeeChanged(
        uint16 oldJoinFee,
        uint16 newJoinFee,
        uint16 oldSellFee,
        uint16 newSellFee
    );

    /// @notice Transfer Antic's fee collector address
    /// @param newCollector The address of the new Antic fee collector
    function transferAnticFeeCollector(address newCollector) external;

    /// @notice Change Antic fees
    /// @param newJoinFee Antic join fee percentage out of 1000
    /// @param newSellFee Antic sell/receive fee percentage out of 1000
    function changeAnticFee(uint16 newJoinFee, uint16 newSellFee) external;

    /// @return The address of Antic's fee collector
    function anticFeeCollector() external view returns (address);

    /// @return joinFee The fee amount in percentage (out of 1000) that Antic takes for joining
    /// @return sellFee The fee amount in percentage (out of 1000) that Antic takes for selling
    function anticFees() external view returns (uint16 joinFee, uint16 sellFee);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        require(
            _newOwner != address(0),
            "LibDiamond: Owner can't be zero address"
        );

        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Replace facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Deployment refund actions
interface IDeploymentRefund {
    /// @dev Emitted on deployer withdraws deployment refund
    /// @param account the deployer that withdraw
    /// @param amount the refund amount
    event WithdrawnDeploymentRefund(address account, uint256 amount);

    /// @dev Emitted on deployment cost initialization
    /// @param gasUsed gas used in the group contract deployment
    /// @param gasPrice gas cost in the deployment
    /// @param deployer the account that deployed the group
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );

    /// @dev Emitted on deployer joins the group
    /// @param ownershipUnits amount of ownership units acquired
    event DeployerJoined(uint256 ownershipUnits);

    /// @return The refund amount needed to be paid based on `units`.
    /// If the refund was fully funded, this will return 0
    /// If the refund amount is bigger than what is left to be refunded, this will return only
    /// what is left to be refunded. e.g. Need to refund 100 wei and 70 wei was already paid,
    /// if a new member joins and buys 40% ownership he will only need to pay 30 wei (100-70).
    function calculateDeploymentCostRefund(uint256 units)
        external
        view
        returns (uint256);

    /// @return The deployment cost needed to be refunded
    function deploymentCostToRefund() external view returns (uint256);

    /// @return The deployment cost already paid
    function deploymentCostPaid() external view returns (uint256);

    /// @return The refund amount that can be withdrawn by the deployer
    function refundable() external view returns (uint256);

    /// @notice Deployment cost refund withdraw (collected so far)
    /// @dev Refunds the deployer with the collected deployment cost
    /// Emits `WithdrawnDeploymentRefund` event
    function withdrawDeploymentRefund() external;

    /// @return The address of the contract/group deployer
    function deployer() external view returns (address);

    /// @dev Initializes the deployment cost.
    /// SHOULD be called together with the deployment of the contract, because this function uses
    /// `tx.gasprice`. So for the best accuracy initialize the contract and call this function in the same transaction.
    /// @param deploymentGasUsed Gas used to deploy the contract/group
    /// @param deployer_ The address who deployed the contract/group
    function initDeploymentCost(uint256 deploymentGasUsed, address deployer_)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Group managment interface
/// @author Amit Molek
interface IGroup {
    /// @dev Emitted when a member joins the group
    /// @param account the member that joined the group
    /// @param ownershipUnits number of ownership units bought
    event Joined(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member acquires more ownership units
    /// @param account the member that acquired more
    /// @param ownershipUnits number of ownership units bought
    event AcquiredMore(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member leaves the group
    /// @param account the member that leaved the group
    event Left(address account);

    /// @notice Join the group
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `Joined` event
    function join(bytes memory data) external payable;

    /// @notice Acquire more ownership units
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `AcquiredMore` event
    function acquireMore(bytes memory data) external payable;

    /// @notice Leave the group
    /// @dev The member will be refunded with his join contribution and Antic fee
    /// Emits `Leaved` event
    function leave() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Proxy initialization
interface IProxyInitializer {
    /// @dev Initializes the proxy
    /// @param anticFeeCollector Address that the Antic fees will be sent to
    /// @param anticJoinFeePercentage Antic join fee percentage out of 1000
    /// e.g. 25 -> 25/1000 = 2.5%
    /// @param anticSellFeePercentage Antic sell/receive fee percentage out of 1000
    /// e.g. 25 -> 25/1000 = 2.5%
    /// @param data Proxy initialization data
    function proxyInit(
        address anticFeeCollector,
        uint16 anticJoinFeePercentage,
        uint16 anticSellFeePercentage,
        bytes memory data
    ) external;

    /// @return True, if the proxy is initialized
    function initialized() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageDominiumProxy} from "../storage/StorageDominiumProxy.sol";
import {IDiamondLoupe} from "../external/diamond/interfaces/IDiamondLoupe.sol";
import {LibDiamond} from "../external/diamond/libraries/LibDiamond.sol";

/// @author Amit Molek
/// @dev This contract is designed to forward all calls to the Dominium contract.
/// Please take a look at the Dominium contract.
///
/// The fallback works in two steps:
///     1. Calls the DiamondLoupe to get the facet that implements the called function
///     2. Delegatecalls the facet
///
/// The first step is necessary because the DiamondLoupe stores the facets addresses
/// in storage.
contract DominiumProxy {
    constructor(address implementation) {
        StorageDominiumProxy.DiamondStorage storage ds = StorageDominiumProxy
            .diamondStorage();

        ds.implementation = implementation;
    }

    fallback() external payable {
        // get loupe from storage
        StorageDominiumProxy.DiamondStorage storage ds = StorageDominiumProxy
            .diamondStorage();

        // get facet from loupe and verify for existence
        address facet = IDiamondLoupe(ds.implementation).facetAddress(msg.sig);
        LibDiamond.enforceHasContractCode(
            facet,
            "DominiumProxy: Function does not exist"
        );

        // execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {DominiumProxy} from "./DominiumProxy.sol";
import {Manageable} from "../access/Manageable.sol";
import {IProxyInitializer} from "../interfaces/IProxyInitializer.sol";
import {IGroup} from "../interfaces/IGroup.sol";
import {IDeploymentRefund} from "../interfaces/IDeploymentRefund.sol";
import {IAnticFeeCollectorProvider} from "../external/diamond/interfaces/IAnticFeeCollectorProvider.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/// @author Amit Molek
/// @dev Factory to replicate DominiumProxy contracts
contract DominiumProxyFactory is Manageable {
    /// @dev Emitted on instantiating a new `DominiumProxy` clone
    /// @param clone The `DominiumProxy` clone address
    /// @param implementation The implementation the proxy points to
    event Cloned(DominiumProxy clone, address implementation);

    /// @dev Emitted on `cloneAndJoin`
    /// @param clone The `DominiumProxy` clone address
    /// @param gasUsed The gas used to instantiate and initialize the clone
    event GasUsed(DominiumProxy clone, uint256 gasUsed);

    /// @dev Emitted on `changeImplementation`
    /// @param newImpl The address of the new implementation
    /// @param oldImpl The address of the old implementation
    event ImplementationChanged(address newImpl, address oldImpl);

    address public implementation;

    constructor(
        address admin,
        address[] memory managers,
        address implementation_
    ) Manageable(admin, managers) {
        _validImplementationGuard(implementation_);

        implementation = implementation_;
    }

    /// @dev The caller also joins the group
    /// @return instance an initialized `DominiumProxy` with the caller as the first member
    function cloneAndJoin(
        bytes32 salt,
        bytes memory initData,
        bytes memory joinData
    )
        external
        payable
        returns (DominiumProxy instance, uint256 deploymentGasUsed)
    {
        uint256 gasBefore = gasleft();
        instance = _replicate(salt, initData);
        deploymentGasUsed = gasBefore - gasleft();

        emit GasUsed(instance, deploymentGasUsed);

        // Initialize the deployment cost
        IDeploymentRefund(address(instance)).initDeploymentCost(
            deploymentGasUsed,
            msg.sender
        );

        // Member joins the group
        IGroup(address(instance)).join{value: msg.value}(joinData);
    }

    /// @dev Can revert:
    ///     - "Missing initialization data": If `data` is empty
    ///     - "Empty salt": if `salt_` is the empty hash
    /// @dev Emits `Cloned`
    function _replicate(bytes32 salt_, bytes memory data)
        internal
        returns (DominiumProxy instance)
    {
        require(data.length > 0, "Missing initialization data");
        require(salt_ != bytes32(0), "Empty salt");

        // The salt is unique to the deployer/caller
        bytes32 deployerSalt = _deploySalt(msg.sender, salt_);

        // Deploy `DominiumProxy` using create2, so we can get
        // the precalculated address
        instance = new DominiumProxy{salt: deployerSalt}(implementation);

        emit Cloned(instance, implementation);

        // Fetch fee info provider
        IAnticFeeCollectorProvider feeCollectorProvider = IAnticFeeCollectorProvider(
                implementation
            );

        // Fetch Antic's fee collector address
        address anticFeeCollector = feeCollectorProvider.anticFeeCollector();

        // Fetch Antic's join & sell fees
        (uint16 joinFee, uint16 sellFee) = feeCollectorProvider.anticFees();

        // Initialize clone
        IProxyInitializer(address(instance)).proxyInit(
            anticFeeCollector,
            joinFee,
            sellFee,
            data
        );
    }

    /// @return the address of the contract if it will be deployed using `clone` & `cloneAndJoin`
    /// with `salt`
    function computeAddress(address deployer, bytes32 salt)
        external
        view
        returns (address)
    {
        bytes memory proxyBytecode = _proxyCreationBytecode(implementation);
        bytes32 deployerSalt = _deploySalt(deployer, salt);

        bytes32 _data = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                deployerSalt,
                keccak256(proxyBytecode)
            )
        );
        return address(uint160(uint256(_data)));
    }

    /// @return the `DominiumProxy`'s creation code
    function _proxyCreationBytecode(address implementation_)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                type(DominiumProxy).creationCode,
                abi.encode(implementation_)
            );
    }

    /// @return the salt that will be used for cloning if `deployer`
    /// is the caller and `salt` is passed
    function _deploySalt(address deployer, bytes32 salt)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(deployer, salt));
    }

    function changeImplementation(address implementation_)
        external
        onlyAuthorized
    {
        _validImplementationGuard(implementation_);

        emit ImplementationChanged(implementation_, implementation);

        implementation = implementation_;
    }

    /// @dev Reverts if `implementation_` is not a valid implementation
    function _validImplementationGuard(address implementation_) internal view {
        require(
            ERC165Checker.supportsInterface(
                implementation_,
                type(IAnticFeeCollectorProvider).interfaceId
            ),
            "Implementation must support IAnticFeeCollectorProvider"
        );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for DominiumProxy contract
library StorageDominiumProxy {
    struct DiamondStorage {
        address implementation;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.DominiumProxy");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}