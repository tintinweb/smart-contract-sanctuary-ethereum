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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/SelfMulticall.sol";
import "./RoleDeriver.sol";
import "./interfaces/IAccessControlRegistryAdminned.sol";
import "./interfaces/IAccessControlRegistry.sol";

/// @title Contract to be inherited by contracts whose adminship functionality
/// will be implemented using AccessControlRegistry
contract AccessControlRegistryAdminned is
    SelfMulticall,
    RoleDeriver,
    IAccessControlRegistryAdminned
{
    /// @notice AccessControlRegistry contract address
    address public immutable override accessControlRegistry;

    /// @notice Admin role description
    string public override adminRoleDescription;

    bytes32 internal immutable adminRoleDescriptionHash;

    /// @dev Contracts deployed with the same admin role descriptions will have
    /// the same roles, meaning that granting an account a role will authorize
    /// it in multiple contracts. Unless you want your deployed contract to
    /// share the role configuration of another contract, use a unique admin
    /// role description.
    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription
    ) {
        require(_accessControlRegistry != address(0), "ACR address zero");
        require(
            bytes(_adminRoleDescription).length > 0,
            "Admin role description empty"
        );
        accessControlRegistry = _accessControlRegistry;
        adminRoleDescription = _adminRoleDescription;
        adminRoleDescriptionHash = keccak256(
            abi.encodePacked(_adminRoleDescription)
        );
    }

    /// @notice Derives the admin role for the specific manager address
    /// @param manager Manager address
    /// @return adminRole Admin role
    function _deriveAdminRole(
        address manager
    ) internal view returns (bytes32 adminRole) {
        adminRole = _deriveRole(
            _deriveRootRole(manager),
            adminRoleDescriptionHash
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../../utils/interfaces/IExpiringMetaTxForwarder.sol";
import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistry is
    IAccessControl,
    IExpiringMetaTxForwarder,
    ISelfMulticall
{
    event InitializedManager(
        bytes32 indexed rootRole,
        address indexed manager,
        address sender
    );

    event InitializedRole(
        bytes32 indexed role,
        bytes32 indexed adminRole,
        string description,
        address sender
    );

    function initializeManager(address manager) external;

    function initializeRoleAndGrantToSender(
        bytes32 adminRole,
        string calldata description
    ) external returns (bytes32 role);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/interfaces/ISelfMulticall.sol";

interface IAccessControlRegistryAdminned is ISelfMulticall {
    function accessControlRegistry() external view returns (address);

    function adminRoleDescription() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contract to be inherited by contracts that will derive
/// AccessControlRegistry roles
/// @notice If a contract interfaces with AccessControlRegistry and needs to
/// derive roles, it should inherit this contract instead of re-implementing
/// the logic
contract RoleDeriver {
    /// @notice Derives the root role of the manager
    /// @param manager Manager address
    /// @return rootRole Root role
    function _deriveRootRole(
        address manager
    ) internal pure returns (bytes32 rootRole) {
        rootRole = keccak256(abi.encodePacked(manager));
    }

    /// @notice Derives the role using its admin role and description
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param description Human-readable description of the role
    /// @return role Role
    function _deriveRole(
        bytes32 adminRole,
        string memory description
    ) internal pure returns (bytes32 role) {
        role = _deriveRole(adminRole, keccak256(abi.encodePacked(description)));
    }

    /// @notice Derives the role using its admin role and description hash
    /// @dev This implies that roles adminned by the same role cannot have the
    /// same description
    /// @param adminRole Admin role
    /// @param descriptionHash Hash of the human-readable description of the
    /// role
    /// @return role Role
    function _deriveRole(
        bytes32 adminRole,
        bytes32 descriptionHash
    ) internal pure returns (bytes32 role) {
        role = keccak256(abi.encodePacked(adminRole, descriptionHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../access-control-registry/interfaces/IAccessControlRegistryAdminned.sol";

interface IRequesterAuthorizerWithErc721 is
    IERC721Receiver,
    IAccessControlRegistryAdminned
{
    enum DepositState {
        Inactive,
        Active,
        WithdrawalInitiated
    }

    event SetWithdrawalLeadTime(
        address indexed airnode,
        uint32 withdrawalLeadTime,
        address sender
    );

    event SetRequesterBlockStatus(
        address indexed airnode,
        address indexed requester,
        uint256 chainId,
        bool status,
        address sender
    );

    event SetDepositorFreezeStatus(
        address indexed airnode,
        address indexed depositor,
        bool status,
        address sender
    );

    event DepositedToken(
        address indexed airnode,
        address indexed requester,
        address indexed depositor,
        uint256 chainId,
        address token,
        uint256 tokenId,
        uint256 tokenDepositCount
    );

    event UpdatedDepositRequesterFrom(
        address indexed airnode,
        address indexed requester,
        address indexed depositor,
        uint256 chainId,
        address token,
        uint256 tokenId,
        uint256 tokenDepositCount
    );

    event UpdatedDepositRequesterTo(
        address indexed airnode,
        address indexed requester,
        address indexed depositor,
        uint256 chainId,
        address token,
        uint256 tokenId,
        uint256 tokenDepositCount
    );

    event InitiatedTokenWithdrawal(
        address indexed airnode,
        address indexed requester,
        address indexed depositor,
        uint256 chainId,
        address token,
        uint256 tokenId,
        uint32 earliestWithdrawalTime,
        uint256 tokenDepositCount
    );

    event WithdrewToken(
        address indexed airnode,
        address indexed requester,
        address indexed depositor,
        uint256 chainId,
        address token,
        uint256 tokenId,
        uint256 tokenDepositCount
    );

    event RevokedToken(
        address indexed airnode,
        address indexed requester,
        address indexed depositor,
        uint256 chainId,
        address token,
        uint256 tokenId,
        uint256 tokenDepositCount
    );

    function setWithdrawalLeadTime(
        address airnode,
        uint32 withdrawalLeadTime
    ) external;

    function setRequesterBlockStatus(
        address airnode,
        uint256 chainId,
        address requester,
        bool status
    ) external;

    function setDepositorFreezeStatus(
        address airnode,
        address depositor,
        bool status
    ) external;

    function updateDepositRequester(
        address airnode,
        uint256 chainIdPrevious,
        address requesterPrevious,
        uint256 chainIdNext,
        address requesterNext,
        address token
    ) external;

    function initiateTokenWithdrawal(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external returns (uint32 earliestWithdrawalTime);

    function withdrawToken(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external;

    function revokeToken(
        address airnode,
        uint256 chainId,
        address requester,
        address token,
        address depositor
    ) external;

    function airnodeToChainIdToRequesterToTokenToDepositorToDeposit(
        address airnode,
        uint256 chainId,
        address requester,
        address token,
        address depositor
    )
        external
        view
        returns (
            uint256 tokenId,
            uint32 withdrawalLeadTime,
            uint32 earliestWithdrawalTime,
            DepositState depositState
        );

    function isAuthorized(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external view returns (bool);

    function deriveWithdrawalLeadTimeSetterRole(
        address airnode
    ) external view returns (bytes32 withdrawalLeadTimeSetterRole);

    function deriveRequesterBlockerRole(
        address airnode
    ) external view returns (bytes32 requesterBlockerRole);

    function deriveDepositorFreezerRole(
        address airnode
    ) external view returns (bytes32 depositorFreezerRole);

    // solhint-disable-next-line func-name-mixedcase
    function WITHDRAWAL_LEAD_TIME_SETTER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function REQUESTER_BLOCKER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    // solhint-disable-next-line func-name-mixedcase
    function DEPOSITOR_FREEZER_ROLE_DESCRIPTION()
        external
        view
        returns (string memory);

    function airnodeToChainIdToRequesterToTokenAddressToTokenDeposits(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external view returns (uint256 tokenDepositCount);

    function airnodeToWithdrawalLeadTime(
        address airnode
    ) external view returns (uint32 withdrawalLeadTime);

    function airnodeToChainIdToRequesterToBlockStatus(
        address airnode,
        uint256 chainId,
        address requester
    ) external view returns (bool isBlocked);

    function airnodeToDepositorToFreezeStatus(
        address airnode,
        address depositor
    ) external view returns (bool isFrozen);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "../access-control-registry/AccessControlRegistryAdminned.sol";
import "./interfaces/IRequesterAuthorizerWithErc721.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Authorizer contract that users can deposit the ERC721 tokens
/// recognized by the Airnode to receive authorization for the requester
/// contract on the chain
/// @notice For an Airnode to treat an ERC721 token deposit as a valid reason
/// for the respective requester contract to be authorized, it needs to be
/// configured at deploy-time to (1) use this contract as an authorizer,
/// (2) recognize the respectice ERC721 token contract.
/// It can be expected for Airnodes to be configured to only recognize the
/// respective NFT keys that their operators have issued, but this is not
/// necessarily true, i.e., an Airnode can be configured to recognize an
/// arbitrary ERC721 token.
/// This contract allows Airnodes to block specific requester contracts. It can
/// be expected for Airnodes to only do this when the requester is breaking
/// T&C. The tokens that have been deposited to authorize requesters that have
/// been blocked can be revoked, which transfers them to the Airnode account.
/// This can be seen as a staking/slashing mechanism. Accordingly, users should
/// not deposit ERC721 tokens to receive authorization from Airnodes that they
/// suspect may abuse this mechanic.
/// @dev Airnode operators are strongly recommended to only use a single
/// instance of this contract as an authorizer. If multiple instances are used,
/// the state between the instances should be kept consistent. For example, if
/// a requester on a chain is to be blocked, all instances of this contract
/// that are used as authorizers for the chain should be updated. Otherwise,
/// the requester to be blocked can still be authorized via the instances that
/// have not been updated.
contract RequesterAuthorizerWithErc721 is
    ERC2771Context,
    AccessControlRegistryAdminned,
    IRequesterAuthorizerWithErc721
{
    struct TokenDeposits {
        uint256 count;
        mapping(address => Deposit) depositorToDeposit;
    }

    struct Deposit {
        uint256 tokenId;
        uint32 withdrawalLeadTime;
        uint32 earliestWithdrawalTime;
        DepositState state;
    }

    /// @notice Withdrawal lead time setter role description
    string
        public constant
        override WITHDRAWAL_LEAD_TIME_SETTER_ROLE_DESCRIPTION =
        "Withdrawal lead time setter";
    /// @notice Requester blocker role description
    string public constant override REQUESTER_BLOCKER_ROLE_DESCRIPTION =
        "Requester blocker";
    /// @notice Depositor freezer role description
    string public constant override DEPOSITOR_FREEZER_ROLE_DESCRIPTION =
        "Depositor freezer";

    bytes32 private constant WITHDRAWAL_LEAD_TIME_SETTER_ROLE_DESCRIPTION_HASH =
        keccak256(
            abi.encodePacked(WITHDRAWAL_LEAD_TIME_SETTER_ROLE_DESCRIPTION)
        );
    bytes32 private constant REQUESTER_BLOCKER_ROLE_DESCRIPTION_HASH =
        keccak256(abi.encodePacked(REQUESTER_BLOCKER_ROLE_DESCRIPTION));
    bytes32 private constant DEPOSITOR_FREEZER_ROLE_DESCRIPTION_HASH =
        keccak256(abi.encodePacked(DEPOSITOR_FREEZER_ROLE_DESCRIPTION));

    /// @notice Deposits of the token with the address made for the Airnode to
    /// authorize the requester address on the chain
    mapping(address => mapping(uint256 => mapping(address => mapping(address => TokenDeposits))))
        public
        override airnodeToChainIdToRequesterToTokenAddressToTokenDeposits;

    /// @notice Withdrawal lead time of the Airnode. This creates the window of
    /// opportunity during which a requester can be blocked for breaking T&C
    /// and the respective token can be revoked.
    /// The withdrawal lead time at deposit-time will apply to a specific
    /// deposit.
    mapping(address => uint32) public override airnodeToWithdrawalLeadTime;

    /// @notice If the Airnode has blocked the requester on the chain. In the
    /// context of the respective Airnode, no one can deposit for a blocked
    /// requester, make deposit updates that relate to a blocked requester, or
    /// withdraw a token deposited for a blocked requester. Anyone can revoke
    /// tokens that are already deposited for a blocked requester. Existing
    /// deposits for a blocked requester do not provide authorization.
    mapping(address => mapping(uint256 => mapping(address => bool)))
        public
        override airnodeToChainIdToRequesterToBlockStatus;

    /// @notice If the Airnode has frozen the depositor. In the context of the
    /// respective Airnode, a frozen depositor cannot deposit, make deposit
    /// updates or withdraw.
    mapping(address => mapping(address => bool))
        public
        override airnodeToDepositorToFreezeStatus;

    /// @param _accessControlRegistry AccessControlRegistry contract address
    /// @param _adminRoleDescription Admin role description
    constructor(
        address _accessControlRegistry,
        string memory _adminRoleDescription
    )
        ERC2771Context(_accessControlRegistry)
        AccessControlRegistryAdminned(
            _accessControlRegistry,
            _adminRoleDescription
        )
    {}

    /// @notice Called by the Airnode or its withdrawal lead time setters to
    /// set withdrawal lead time
    /// @param airnode Airnode address
    /// @param withdrawalLeadTime Withdrawal lead time
    function setWithdrawalLeadTime(
        address airnode,
        uint32 withdrawalLeadTime
    ) external override {
        require(
            airnode == _msgSender() ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    deriveWithdrawalLeadTimeSetterRole(airnode),
                    _msgSender()
                ),
            "Sender cannot set lead time"
        );
        require(withdrawalLeadTime <= 30 days, "Lead time too long");
        airnodeToWithdrawalLeadTime[airnode] = withdrawalLeadTime;
        emit SetWithdrawalLeadTime(airnode, withdrawalLeadTime, _msgSender());
    }

    /// @notice Called by the Airnode or its requester blockers to set
    /// the block status of the requester
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param requester Requester address
    /// @param status Block status
    function setRequesterBlockStatus(
        address airnode,
        uint256 chainId,
        address requester,
        bool status
    ) external override {
        require(
            airnode == _msgSender() ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    deriveRequesterBlockerRole(airnode),
                    _msgSender()
                ),
            "Sender cannot block requester"
        );
        require(chainId != 0, "Chain ID zero");
        require(requester != address(0), "Requester address zero");
        airnodeToChainIdToRequesterToBlockStatus[airnode][chainId][
            requester
        ] = status;
        emit SetRequesterBlockStatus(
            airnode,
            requester,
            chainId,
            status,
            _msgSender()
        );
    }

    /// @notice Called by the Airnode or its depositor freezers to set the
    /// freeze status of the depositor
    /// @param airnode Airnode address
    /// @param depositor Depositor address
    /// @param status Freeze status
    function setDepositorFreezeStatus(
        address airnode,
        address depositor,
        bool status
    ) external override {
        require(
            airnode == _msgSender() ||
                IAccessControlRegistry(accessControlRegistry).hasRole(
                    deriveDepositorFreezerRole(airnode),
                    _msgSender()
                ),
            "Sender cannot freeze depositor"
        );
        require(depositor != address(0), "Depositor address zero");
        airnodeToDepositorToFreezeStatus[airnode][depositor] = status;
        emit SetDepositorFreezeStatus(airnode, depositor, status, _msgSender());
    }

    /// @notice Called by the ERC721 contract upon `safeTransferFrom()` to this
    /// contract to deposit a token to authorize the requester
    /// @dev The first argument is the operator, which we do not need
    /// @param _from Account from which the token is transferred
    /// @param _tokenId Token ID
    /// @param _data Airnode address, chain ID and requester address in
    /// ABI-encoded form
    /// @return `onERC721Received()` function selector
    function onERC721Received(
        address,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        require(_data.length == 96, "Unexpected data length");
        (address airnode, uint256 chainId, address requester) = abi.decode(
            _data,
            (address, uint256, address)
        );
        require(airnode != address(0), "Airnode address zero");
        require(chainId != 0, "Chain ID zero");
        require(requester != address(0), "Requester address zero");
        require(
            !airnodeToChainIdToRequesterToBlockStatus[airnode][chainId][
                requester
            ],
            "Requester blocked"
        );
        require(
            !airnodeToDepositorToFreezeStatus[airnode][_from],
            "Depositor frozen"
        );
        TokenDeposits
            storage tokenDeposits = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainId][requester][_msgSender()];
        uint256 tokenDepositCount;
        unchecked {
            tokenDepositCount = ++tokenDeposits.count;
        }
        require(
            tokenDeposits.depositorToDeposit[_from].state ==
                DepositState.Inactive,
            "Token already deposited"
        );
        tokenDeposits.depositorToDeposit[_from] = Deposit({
            tokenId: _tokenId,
            withdrawalLeadTime: airnodeToWithdrawalLeadTime[airnode],
            earliestWithdrawalTime: 0,
            state: DepositState.Active
        });
        emit DepositedToken(
            airnode,
            requester,
            _from,
            chainId,
            _msgSender(),
            _tokenId,
            tokenDepositCount
        );
        return this.onERC721Received.selector;
    }

    /// @notice Called by a token depositor to update the requester for which
    /// they have deposited the token for
    /// @dev This is especially useful for not having to wait when the Airnode
    /// has set a non-zero withdrawal lead time
    /// @param airnode Airnode address
    /// @param chainIdPrevious Previous chain ID
    /// @param requesterPrevious Previous requester address
    /// @param chainIdNext Next chain ID
    /// @param requesterNext Next requester address
    /// @param token Token address
    function updateDepositRequester(
        address airnode,
        uint256 chainIdPrevious,
        address requesterPrevious,
        uint256 chainIdNext,
        address requesterNext,
        address token
    ) external override {
        require(chainIdNext != 0, "Chain ID zero");
        require(requesterNext != address(0), "Requester address zero");
        require(
            !(chainIdPrevious == chainIdNext &&
                requesterPrevious == requesterNext),
            "Does not update requester"
        );
        require(
            !airnodeToChainIdToRequesterToBlockStatus[airnode][chainIdPrevious][
                requesterPrevious
            ],
            "Previous requester blocked"
        );
        require(
            !airnodeToChainIdToRequesterToBlockStatus[airnode][chainIdNext][
                requesterNext
            ],
            "Next requester blocked"
        );
        require(
            !airnodeToDepositorToFreezeStatus[airnode][_msgSender()],
            "Depositor frozen"
        );
        TokenDeposits
            storage requesterPreviousTokenDeposits = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainIdPrevious][requesterPrevious][token];
        Deposit
            storage requesterPreviousDeposit = requesterPreviousTokenDeposits
                .depositorToDeposit[_msgSender()];
        if (requesterPreviousDeposit.state != DepositState.Active) {
            if (requesterPreviousDeposit.state == DepositState.Inactive) {
                revert("Token not deposited");
            } else {
                revert("Withdrawal initiated");
            }
        }
        TokenDeposits
            storage requesterNextTokenDeposits = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainIdNext][requesterNext][token];
        require(
            requesterNextTokenDeposits.depositorToDeposit[_msgSender()].state ==
                DepositState.Inactive,
            "Token already deposited"
        );
        uint256 requesterNextTokenDepositCount = ++requesterNextTokenDeposits
            .count;
        requesterNextTokenDeposits.count = requesterNextTokenDepositCount;
        uint256 requesterPreviousTokenDepositCount = --requesterPreviousTokenDeposits
                .count;
        requesterPreviousTokenDeposits
            .count = requesterPreviousTokenDepositCount;
        uint256 tokenId = requesterPreviousDeposit.tokenId;
        requesterNextTokenDeposits.depositorToDeposit[_msgSender()] = Deposit({
            tokenId: tokenId,
            withdrawalLeadTime: requesterPreviousDeposit.withdrawalLeadTime,
            earliestWithdrawalTime: 0,
            state: DepositState.Active
        });
        requesterPreviousTokenDeposits.depositorToDeposit[
            _msgSender()
        ] = Deposit({
            tokenId: 0,
            withdrawalLeadTime: 0,
            earliestWithdrawalTime: 0,
            state: DepositState.Inactive
        });
        emit UpdatedDepositRequesterTo(
            airnode,
            requesterNext,
            _msgSender(),
            chainIdNext,
            token,
            tokenId,
            requesterNextTokenDepositCount
        );
        emit UpdatedDepositRequesterFrom(
            airnode,
            requesterPrevious,
            _msgSender(),
            chainIdPrevious,
            token,
            tokenId,
            requesterPreviousTokenDepositCount
        );
    }

    /// @notice Called by a token depositor to initiate withdrawal
    /// @dev The depositor is allowed to initiate a withdrawal even if the
    /// respective requester is blocked. However, the withdrawal will not be
    /// executable as long as the requester is blocked.
    /// Token withdrawals can be initiated even if withdrawal lead time is
    /// zero.
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param requester Requester address
    /// @param token Token address
    /// @return earliestWithdrawalTime Earliest withdrawal time
    function initiateTokenWithdrawal(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external override returns (uint32 earliestWithdrawalTime) {
        TokenDeposits
            storage tokenDeposits = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainId][requester][token];
        Deposit storage deposit = tokenDeposits.depositorToDeposit[
            _msgSender()
        ];
        if (deposit.state != DepositState.Active) {
            if (deposit.state == DepositState.Inactive) {
                revert("Token not deposited");
            } else {
                revert("Withdrawal already initiated");
            }
        }
        uint256 tokenDepositCount;
        unchecked {
            tokenDepositCount = --tokenDeposits.count;
        }
        earliestWithdrawalTime = SafeCast.toUint32(
            block.timestamp + deposit.withdrawalLeadTime
        );
        deposit.earliestWithdrawalTime = earliestWithdrawalTime;
        deposit.state = DepositState.WithdrawalInitiated;
        emit InitiatedTokenWithdrawal(
            airnode,
            requester,
            _msgSender(),
            chainId,
            token,
            deposit.tokenId,
            earliestWithdrawalTime,
            tokenDepositCount
        );
    }

    /// @notice Called by a token depositor to withdraw
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param requester Requester address
    /// @param token Token address
    function withdrawToken(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external override {
        require(
            !airnodeToChainIdToRequesterToBlockStatus[airnode][chainId][
                requester
            ],
            "Requester blocked"
        );
        require(
            !airnodeToDepositorToFreezeStatus[airnode][_msgSender()],
            "Depositor frozen"
        );
        TokenDeposits
            storage tokenDeposits = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainId][requester][token];
        Deposit storage deposit = tokenDeposits.depositorToDeposit[
            _msgSender()
        ];
        require(deposit.state != DepositState.Inactive, "Token not deposited");
        uint256 tokenDepositCount;
        if (deposit.state == DepositState.Active) {
            require(
                deposit.withdrawalLeadTime == 0,
                "Withdrawal not initiated"
            );
            unchecked {
                tokenDepositCount = --tokenDeposits.count;
            }
        } else {
            require(
                block.timestamp >= deposit.earliestWithdrawalTime,
                "Cannot withdraw yet"
            );
            unchecked {
                tokenDepositCount = tokenDeposits.count;
            }
        }
        uint256 tokenId = deposit.tokenId;
        tokenDeposits.depositorToDeposit[_msgSender()] = Deposit({
            tokenId: 0,
            withdrawalLeadTime: 0,
            earliestWithdrawalTime: 0,
            state: DepositState.Inactive
        });
        emit WithdrewToken(
            airnode,
            requester,
            _msgSender(),
            chainId,
            token,
            tokenId,
            tokenDepositCount
        );
        IERC721(token).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    /// @notice Called to revoke the token deposited to authorize a requester
    /// that is blocked now
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param requester Requester address
    /// @param token Token address
    /// @param depositor Depositor address
    function revokeToken(
        address airnode,
        uint256 chainId,
        address requester,
        address token,
        address depositor
    ) external override {
        require(
            airnodeToChainIdToRequesterToBlockStatus[airnode][chainId][
                requester
            ],
            "Airnode did not block requester"
        );
        TokenDeposits
            storage tokenDeposits = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainId][requester][token];
        Deposit storage deposit = tokenDeposits.depositorToDeposit[depositor];
        require(deposit.state != DepositState.Inactive, "Token not deposited");
        uint256 tokenDepositCount;
        if (deposit.state == DepositState.Active) {
            unchecked {
                tokenDepositCount = --tokenDeposits.count;
            }
        } else {
            unchecked {
                tokenDepositCount = tokenDeposits.count;
            }
        }
        uint256 tokenId = deposit.tokenId;
        tokenDeposits.depositorToDeposit[depositor] = Deposit({
            tokenId: 0,
            withdrawalLeadTime: 0,
            earliestWithdrawalTime: 0,
            state: DepositState.Inactive
        });
        emit RevokedToken(
            airnode,
            requester,
            depositor,
            chainId,
            token,
            tokenId,
            tokenDepositCount
        );
        IERC721(token).safeTransferFrom(address(this), airnode, tokenId);
    }

    /// @notice Returns the deposit of the token with the address made by the
    /// depositor for the Airnode to authorize the requester address on the
    /// chain
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param requester Requester address
    /// @param token Token address
    /// @param depositor Depositor address
    /// @return tokenId Token ID
    /// @return withdrawalLeadTime Withdrawal lead time captured at
    /// deposit-time
    /// @return earliestWithdrawalTime Earliest withdrawal time
    function airnodeToChainIdToRequesterToTokenToDepositorToDeposit(
        address airnode,
        uint256 chainId,
        address requester,
        address token,
        address depositor
    )
        external
        view
        override
        returns (
            uint256 tokenId,
            uint32 withdrawalLeadTime,
            uint32 earliestWithdrawalTime,
            DepositState state
        )
    {
        Deposit
            storage deposit = airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[
                airnode
            ][chainId][requester][token].depositorToDeposit[depositor];
        (tokenId, withdrawalLeadTime, earliestWithdrawalTime, state) = (
            deposit.tokenId,
            deposit.withdrawalLeadTime,
            deposit.earliestWithdrawalTime,
            deposit.state
        );
    }

    /// @notice Returns if the requester on the chain is authorized for the
    /// Airnode due to a token with the address being deposited
    /// @param airnode Airnode address
    /// @param chainId Chain ID
    /// @param requester Requester address
    /// @param token Token address
    /// @return Authorization status
    function isAuthorized(
        address airnode,
        uint256 chainId,
        address requester,
        address token
    ) external view override returns (bool) {
        return
            !airnodeToChainIdToRequesterToBlockStatus[airnode][chainId][
                requester
            ] &&
            airnodeToChainIdToRequesterToTokenAddressToTokenDeposits[airnode][
                chainId
            ][requester][token].count >
            0;
    }

    /// @notice Derives the withdrawal lead time setter role for the Airnode
    /// @param airnode Airnode address
    /// @return withdrawalLeadTimeSetterRole Withdrawal lead time setter role
    function deriveWithdrawalLeadTimeSetterRole(
        address airnode
    ) public view override returns (bytes32 withdrawalLeadTimeSetterRole) {
        withdrawalLeadTimeSetterRole = _deriveRole(
            _deriveAdminRole(airnode),
            WITHDRAWAL_LEAD_TIME_SETTER_ROLE_DESCRIPTION_HASH
        );
    }

    /// @notice Derives the requester blocker role for the Airnode
    /// @param airnode Airnode address
    /// @return requesterBlockerRole Requester blocker role
    function deriveRequesterBlockerRole(
        address airnode
    ) public view override returns (bytes32 requesterBlockerRole) {
        requesterBlockerRole = _deriveRole(
            _deriveAdminRole(airnode),
            REQUESTER_BLOCKER_ROLE_DESCRIPTION_HASH
        );
    }

    /// @notice Derives the depositor freezer role for the Airnode
    /// @param airnode Airnode address
    /// @return depositorFreezerRole Depositor freezer role
    function deriveDepositorFreezerRole(
        address airnode
    ) public view override returns (bytes32 depositorFreezerRole) {
        depositorFreezerRole = _deriveRole(
            _deriveAdminRole(airnode),
            DEPOSITOR_FREEZER_ROLE_DESCRIPTION_HASH
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExpiringMetaTxForwarder {
    event ExecutedMetaTx(bytes32 indexed metaTxHash);

    event CanceledMetaTx(bytes32 indexed metaTxHash);

    struct ExpiringMetaTx {
        address from;
        address to;
        bytes data;
        uint256 expirationTimestamp;
    }

    function execute(
        ExpiringMetaTx calldata metaTx,
        bytes calldata signature
    ) external returns (bytes memory returndata);

    function cancel(ExpiringMetaTx calldata metaTx) external;

    function metaTxWithHashIsExecutedOrCanceled(
        bytes32 metaTxHash
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISelfMulticall {
    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory returndata);

    function tryMulticall(
        bytes[] calldata data
    ) external returns (bool[] memory successes, bytes[] memory returndata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ISelfMulticall.sol";

/// @title Contract that enables calls to the inheriting contract to be batched
/// @notice Implements two ways of batching, one requires none of the calls to
/// revert and the other tolerates individual calls reverting
/// @dev This implementation uses delegatecall for individual function calls.
/// Since delegatecall is a message call, it can only be made to functions that
/// are externally visible. This means that a contract cannot multicall its own
/// functions that use internal/private visibility modifiers.
/// Refer to OpenZeppelin's Multicall.sol for a similar implementation.
contract SelfMulticall is ISelfMulticall {
    /// @notice Batches calls to the inheriting contract and reverts as soon as
    /// one of the batched calls reverts
    /// @param data Array of calldata of batched calls
    /// @return returndata Array of returndata of batched calls
    function multicall(
        bytes[] calldata data
    ) external override returns (bytes[] memory returndata) {
        uint256 callCount = data.length;
        returndata = new bytes[](callCount);
        for (uint256 ind = 0; ind < callCount; ) {
            bool success;
            // solhint-disable-next-line avoid-low-level-calls
            (success, returndata[ind]) = address(this).delegatecall(data[ind]);
            if (!success) {
                bytes memory returndataWithRevertData = returndata[ind];
                if (returndataWithRevertData.length > 0) {
                    // Adapted from OpenZeppelin's Address.sol
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        let returndata_size := mload(returndataWithRevertData)
                        revert(
                            add(32, returndataWithRevertData),
                            returndata_size
                        )
                    }
                } else {
                    revert("Multicall: No revert string");
                }
            }
            unchecked {
                ind++;
            }
        }
    }

    /// @notice Batches calls to the inheriting contract but does not revert if
    /// any of the batched calls reverts
    /// @param data Array of calldata of batched calls
    /// @return successes Array of success conditions of batched calls
    /// @return returndata Array of returndata of batched calls
    function tryMulticall(
        bytes[] calldata data
    )
        external
        override
        returns (bool[] memory successes, bytes[] memory returndata)
    {
        uint256 callCount = data.length;
        successes = new bool[](callCount);
        returndata = new bytes[](callCount);
        for (uint256 ind = 0; ind < callCount; ) {
            // solhint-disable-next-line avoid-low-level-calls
            (successes[ind], returndata[ind]) = address(this).delegatecall(
                data[ind]
            );
            unchecked {
                ind++;
            }
        }
    }
}