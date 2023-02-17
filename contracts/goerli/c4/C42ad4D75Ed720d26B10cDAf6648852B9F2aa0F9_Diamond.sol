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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@forge-std/src/console.sol";

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {DiamondStorage} from "./types/diamond/DiamondStorage.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "./facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "./facets/DiamondLoupeFacet.sol";
import {ERC165Facet} from "./facets/ERC165Facet.sol";
import {FacetCut, FacetCutAction} from "./types/diamond/Facet.sol";
import {LibAccessControl} from "./libraries/LibAccessControl.sol";
import {AccessControlFacet} from "./facets/AccessControlFacet.sol";
import {DEFAULT_ADMIN_ROLE} from "./types/access/AccessControlStorage.sol";
import {LibHamachi} from "./libraries/LibHamachi.sol";
import {HamachiStorage} from "./types/hamachi/HamachiStorage.sol";
import {LibReward} from "./libraries/LibReward.sol";
import {RewardStorage} from "./types/reward/RewardStorage.sol";
import {LibUniswap} from "./libraries/LibUniswap.sol";
import {UniswapStorage} from "./types/uniswap/UniswapStorage.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

// When no function exists for function called
error FunctionNotFound(bytes4 functionSignature);

contract Diamond {
  constructor(
    address liquidityWallet,
    address defaultRouter,
    address defaultPair,
    address contractAdmin,
    address diamondCutFacet_,
    address diamondLoupeFacet_,
    address accessControlFacet_,
    address erc165Facet_,
    address methodsExposureFacetAddress_
  ) payable {
    LibAccessControl.grantRole(DEFAULT_ADMIN_ROLE, contractAdmin);

    HamachiStorage storage hs = LibHamachi.DS();
    RewardStorage storage rs = LibReward.DS();
    UniswapStorage storage us = LibUniswap.DS();

    hs.fee.liquidityBuyFee = 100;
    hs.fee.rewardBuyFee = 600;

    hs.fee.liquiditySellFee = 100;
    hs.fee.rewardSellFee = 600;

    hs.numTokensToSwap = 5_000_000 * 10**18;
    hs.maxTokenPerWallet = 250_000_000 * 10**18; // Max holding limit, 0.5% of supply
    hs.swapRouters[defaultRouter] = true;

    us.defaultRouter = defaultRouter;
    us.liquidityWallet = liquidityWallet;

    hs.processingGas = 750_000;
    hs.processingFees = false;

    rs.minRewardBalance = 1000 * 10**18;
    rs.claimTimeout = 3600;

    hs.methodsExposureFacetAddress = methodsExposureFacetAddress_;

    rs.rewardToken.token = address(this);
    rs.rewardToken.router = defaultRouter;
    rs.rewardToken.path = [defaultPair, address(this)];

    rs.goHam.token = address(this);
    rs.goHam.router = defaultRouter;
    rs.goHam.path = [defaultPair, address(this)];

    IUniswapV2Router02 router = IUniswapV2Router02(defaultRouter);
    address swapPair = IUniswapV2Factory(router.factory()).createPair(address(this), defaultPair);
    hs.lpPools[address(swapPair)] = true;

    // Add the diamondCut external function from the diamondCutFacet
    FacetCut[] memory cut = new FacetCut[](1);
    bytes4[] memory functionSelectors = new bytes4[](1);
    functionSelectors[0] = IDiamondCut.diamondCut.selector;
    cut[0] = FacetCut({
      facetAddress: diamondCutFacet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");

    // Add the diamondLoupe external functions from the diamondLoupeFacet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](4);
    functionSelectors[0] = DiamondLoupeFacet.facets.selector;
    functionSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
    functionSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
    functionSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
    cut[0] = FacetCut({
      facetAddress: diamondLoupeFacet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");

    // Add the access control external functions from the accessControlFacet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](5);
    functionSelectors[0] = AccessControlFacet.hasRole.selector;
    functionSelectors[1] = AccessControlFacet.getRoleAdmin.selector;
    functionSelectors[2] = AccessControlFacet.grantRole.selector;
    functionSelectors[3] = AccessControlFacet.revokeRole.selector;
    functionSelectors[4] = AccessControlFacet.renounceRole.selector;
    cut[0] = FacetCut({
      facetAddress: accessControlFacet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");

    // Add the ERC165 external functions from the erc165Facet
    cut = new FacetCut[](1);
    functionSelectors = new bytes4[](1);
    functionSelectors[0] = ERC165Facet.supportsInterface.selector;
    cut[0] = FacetCut({
      facetAddress: erc165Facet_,
      action: FacetCutAction.Add,
      functionSelectors: functionSelectors
    });
    LibDiamond.diamondCut(cut, address(0), "");
  }

  // Find facet for function that is called and execute the
  // function if a facet is found and return any value.
  fallback() external payable {
    DiamondStorage storage ds;
    // get diamond storage
    bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
    // get facet from function selector
    address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
    if (facet == address(0)) revert FunctionNotFound(msg.sig);
    // Execute external function from facet using delegatecall and return any value.
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

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IAccessControlEnumerable} from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import {LibAccessControl, WithRoles} from "../libraries/LibAccessControl.sol";
import {AccessControlStorage, DEFAULT_ADMIN_ROLE, EXCLUDED_FROM_FEE_ROLE, EXCLUDED_FROM_MAX_WALLET_ROLE, EXCLUDED_FROM_REWARD_ROLE} from "../types/access/AccessControlStorage.sol";
import {BURN_ADDRESS} from "../types/hamachi/HamachiStorage.sol";
import {LibHamachi} from "../libraries/LibHamachi.sol";
import {LibERC165} from "../libraries/LibERC165.sol";

contract AccessControlFacet is IAccessControl, IAccessControlEnumerable, WithRoles {
  function hasRole(bytes32 _role, address _account) external view override returns (bool) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].members[_account];
  }

  function getRoleAdmin(bytes32 _role) external view override returns (bytes32) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].adminRole;
  }

  function grantRole(bytes32 _role, address _account) external override {
    LibAccessControl.grantRole(_role, _account);
  }

  function revokeRole(bytes32 _role, address _account) external override {
    LibAccessControl.revokeRole(_role, _account);
  }

  function renounceRole(bytes32 _role, address _account) external override {
    LibAccessControl.renounceRole(_role, _account);
  }

  function getRoleMember(bytes32 _role, uint256 _index) external view override returns (address) {
    return LibAccessControl.getRoleMember(_role, _index);
  }

  function getRoleMemberCount(bytes32 _role) external view override returns (uint256) {
    return LibAccessControl.getRoleMemberCount(_role);
  }

  function getRoleMembers(bytes32 _role) external view returns (address[] memory) {
    return LibAccessControl.getRoleMembers(_role);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {FacetCut} from "../types/diamond/Facet.sol";
import {WithRoles} from "./AccessControlFacet.sol";

import {DEFAULT_ADMIN_ROLE} from "../types/access/AccessControlStorage.sol";

contract DiamondCutFacet is IDiamondCut, WithRoles {
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
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    LibDiamond.diamondCut(_diamondCut, _init, _calldata);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {DiamondStorage} from "../types/diamond/DiamondStorage.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";

import {Facet} from "../types/diamond/Facet.sol";

contract DiamondLoupeFacet is IDiamondLoupe {
  // Diamond Loupe Functions
  ////////////////////////////////////////////////////////////////////
  /// These functions are expected to be called frequently by tools.
  //
  // struct Facet {
  //     address facetAddress;
  //     bytes4[] functionSelectors;
  // }

  /// @notice Gets all facets and their selectors.
  /// @return facets_ Facet
  function facets() external view override returns (Facet[] memory facets_) {
    DiamondStorage storage ds = LibDiamond.DS();
    uint256 numFacets = ds.facetAddresses.length;
    facets_ = new Facet[](numFacets);
    for (uint256 i; i < numFacets; i++) {
      address facetAddress_ = ds.facetAddresses[i];
      facets_[i].facetAddress = facetAddress_;
      facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
    }
  }

  /// @notice Gets all the function selectors provided by a facet.
  /// @param _facet The facet address.
  /// @return facetFunctionSelectors_
  function facetFunctionSelectors(
    address _facet
  ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
    DiamondStorage storage ds = LibDiamond.DS();
    facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
  }

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetAddresses_
  function facetAddresses() external view override returns (address[] memory facetAddresses_) {
    DiamondStorage storage ds = LibDiamond.DS();
    facetAddresses_ = ds.facetAddresses;
  }

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param _functionSelector The function selector.
  /// @return facetAddress_ The facet address.
  function facetAddress(
    bytes4 _functionSelector
  ) external view override returns (address facetAddress_) {
    DiamondStorage storage ds = LibDiamond.DS();
    facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibERC165, ERC165Storage} from "../libraries/LibERC165.sol";
import {IERC165} from "../interfaces/IERC165.sol";

contract ERC165Facet is IERC165 {
  // This implements ERC-165.
  function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
    ERC165Storage storage ds = LibERC165.DS();
    return ds.supportedInterfaces[_interfaceId];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FacetCut} from "../types/diamond/Facet.sol";

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
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
pragma solidity ^0.8.0;

import {Facet} from "../types/diamond/Facet.sol";

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
  /// These functions are expected to be called frequently
  /// by tools.

  /// @notice Gets all facet addresses and their four byte function selectors.
  /// @return facets_ Facet
  function facets() external view returns (Facet[] memory facets_);

  /// @notice Gets all the function selectors supported by a specific facet.
  /// @param _facet The facet address.
  /// @return facetFunctionSelectors_
  function facetFunctionSelectors(
    address _facet
  ) external view returns (bytes4[] memory facetFunctionSelectors_);

  /// @notice Get all the facet addresses used by a diamond.
  /// @return facetAddresses_
  function facetAddresses() external view returns (address[] memory facetAddresses_);

  /// @notice Gets the facet that supports the given selector.
  /// @dev If facet is not found return address(0).
  /// @param _functionSelector The function selector.
  /// @return facetAddress_ The facet address.
  function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
  /// @notice Query if a contract implements an interface
  /// @param interfaceId The interface identifier, as specified in ERC-165
  /// @dev Interface identification is specified in ERC-165. This function
  ///  uses less than 30,000 gas.
  /// @return `true` if the contract implements `interfaceID` and
  ///  `interfaceID` is not 0xffffffff, `false` otherwise
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVestingSchedule {
    function getVestingSchedule(address _beneficiary)
        external
        view
        returns (
            bool initialized,
            address beneficiary,
            uint256 cliff,
            uint256 start,
            uint256 duration,
            uint256 slicePeriodSeconds,
            uint256 amountTotal,
            uint256 released
        );

    function computeReleasableAmount(address _beneficiary)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControlStorage, DEFAULT_ADMIN_ROLE} from "../types/access/AccessControlStorage.sol";
import {AddressArrayLibUtils} from "../../libraries/ArrayLibUtils.sol";

contract WithRoles {
  modifier onlyRole(bytes32 role) {
    LibAccessControl.checkRole(role);
    _;
  }
}

library LibAccessControl {
  using AddressArrayLibUtils for address[];
  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

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

  bytes32 internal constant ACCESS_CONTROL_STORAGE_POSITION =
    keccak256("diamond.standard.accesscontrol.storage");

  function DS() internal pure returns (AccessControlStorage storage ds) {
    bytes32 position = ACCESS_CONTROL_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function hasRole(bytes32 role, address account) internal view returns (bool) {
    return DS().roles[role].members[account];
  }

  function checkRole(bytes32 role, address account) internal view {
    require(hasRole(role, account), "AccessControl: account does not have role");
  }

  function checkRole(bytes32 role) internal view {
    checkRole(role, msg.sender);
  }

  function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
    return DS().roles[role].adminRole;
  }

  function grantRole(bytes32 role, address account) internal {
    if (!hasRole(role, account)) {
      DS().roles[role].members[account] = true;
      DS().roles[role].membersList.push(account);
      emit RoleGranted(role, account, msg.sender);
    }
  }

  function revokeRole(bytes32 role, address account) internal {
    if (hasRole(role, account)) {
      DS().roles[role].members[account] = false;
      DS().roles[role].membersList.swapOut(account);
      emit RoleRevoked(role, account, msg.sender);
    }
  }

  function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
    emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
    DS().roles[role].adminRole = adminRole;
  }

  function renounceRole(bytes32 role, address account) internal {
    require(account == msg.sender, "AccessControl: can only renounce roles for self");

    revokeRole(role, account);
  }

  function getRoleMember(bytes32 _role, uint256 _index) internal view returns (address) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].membersList[_index];
  }

  function getRoleMemberCount(bytes32 _role) internal view returns (uint256) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].membersList.length;
  }

  function getRoleMembers(bytes32 _role) internal view returns (address[] memory) {
    AccessControlStorage storage ds = LibAccessControl.DS();
    return ds.roles[_role].membersList;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {FacetCut, FacetCutAction} from "../types/diamond/Facet.sol";
import {DiamondStorage} from "../types/diamond/DiamondStorage.sol";

library LibDiamond {
  error InValidFacetCutAction();
  error NoSelectorsInFacet();
  error NoZeroAddress();
  error SelectorExists(bytes4 selector);
  error SameSelectorReplacement(bytes4 selector);
  error MustBeZeroAddress();
  error NoCode();
  error NonExistentSelector(bytes4 selector);
  error ImmutableFunction(bytes4 selector);
  error NonEmptyCalldata();
  error EmptyCalldata();
  error InitCallFailed();

  bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  function DS() internal pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(
    FacetCut[] memory _diamondCut,
    address _init,
    bytes memory _calldata
  ) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == FacetCutAction.Add) {
        addFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == FacetCutAction.Replace) {
        replaceFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else if (action == FacetCutAction.Remove) {
        removeFunctions(
          _diamondCut[facetIndex].facetAddress,
          _diamondCut[facetIndex].functionSelectors
        );
      } else {
        revert InValidFacetCutAction();
      }
    }
    emit DiamondCut(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = DS();
    if (_facetAddress == address(0)) revert NoZeroAddress();
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      if (oldFacetAddress != address(0)) revert SelectorExists(selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = DS();
    if (_facetAddress == address(0)) revert NoZeroAddress();
    uint96 selectorPosition = uint96(
      ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
    );
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      if (oldFacetAddress == _facetAddress) revert SameSelectorReplacement(selector);
      removeFunction(ds, oldFacetAddress, selector);
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
    DiamondStorage storage ds = DS();
    // if function does not exist then do nothing and return
    if (_facetAddress != address(0)) revert MustBeZeroAddress();
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress);
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(
    DiamondStorage storage ds,
    bytes4 _selector,
    uint96 _selectorPosition,
    address _facetAddress
  ) internal {
    ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(
    DiamondStorage storage ds,
    address _facetAddress,
    bytes4 _selector
  ) internal {
    if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
    // an immutable function is a function defined directly in a diamond
    if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds
      .facetFunctionSelectors[_facetAddress]
      .functionSelectors
      .length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
        lastSelectorPosition
      ];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(
        selectorPosition
      );
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

  function initializeDiamondCut(address _init, bytes memory _calldata) internal {
    if (_init == address(0)) {
      if (_calldata.length > 0) revert NonEmptyCalldata();
    } else {
      if (_calldata.length == 0) revert EmptyCalldata();
      if (_init != address(this)) {
        enforceHasContractCode(_init);
      }
      (bool success, bytes memory error) = _init.delegatecall(_calldata);
      if (!success) {
        if (error.length > 0) {
          // bubble up the error
          revert(string(error));
        } else {
          revert InitCallFailed();
        }
      }
    }
  }

  function enforceHasContractCode(address _contract) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    if (contractSize <= 0) revert NoCode();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC165Storage} from "../types/erc165/ERC165Storage.sol";

library LibERC165 {
  bytes32 internal constant ERC165_STORAGE_POSITION = keccak256("diamond.standard.erc165.storage");

  function DS() internal pure returns (ERC165Storage storage ds) {
    bytes32 position = ERC165_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function addSupportedInterfaces(bytes4[] memory _interfaces) internal {
    ERC165Storage storage ds = DS();
    for (uint256 i; i < _interfaces.length; i++) {
      ds.supportedInterfaces[_interfaces[i]] = true;
    }
  }

  function addSupportedInterface(bytes4 _interface) internal {
    ERC165Storage storage ds = DS();
    ds.supportedInterfaces[_interface] = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20Storage} from "../types/token/erc20/ERC20Storage.sol";
import {LibHamachi} from "../libraries/LibHamachi.sol";
import {LibReward} from "../libraries/LibReward.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {PERCENTAGE_DENOMINATOR} from "../types/hamachi/HamachiStorage.sol";
import {EXCLUDED_FROM_MAX_WALLET_ROLE} from "../types/access/AccessControlStorage.sol";

error MaxWallet(string message);

library LibERC20 {
  bytes32 internal constant ERC20_STORAGE_POSITION = keccak256("diamond.standard.erc20.storage");

  function DS() internal pure returns (ERC20Storage storage ds) {
    bytes32 position = ERC20_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function _checkMaxWallet(address recipient, uint256 amount) internal view {
    if (
      !LibAccessControl.hasRole(EXCLUDED_FROM_MAX_WALLET_ROLE, recipient) &&
      LibERC20.balanceOf(recipient) + amount > LibHamachi.DS().maxTokenPerWallet
    ) revert MaxWallet("Max wallet exceeded");
  }

  // This implements ERC-20.
  function totalSupply() internal view returns (uint256) {
    ERC20Storage storage ds = LibERC20.DS();
    return ds.totalSupply;
  }

  // This implements ERC-20.
  function balanceOf(address _owner) internal view returns (uint256) {
    ERC20Storage storage ds = LibERC20.DS();
    return ds.balances[_owner];
  }

  // This implements ERC-20.
  function transfer(address to, uint256 amount) internal returns (bool) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  // This implements ERC-20.
  function allowance(address _owner, address _spender) internal view returns (uint256) {
    ERC20Storage storage ds = LibERC20.DS();
    return ds.allowances[_owner][_spender];
  }

  // This implements ERC-20.
  function approve(
    address _owner,
    address _spender,
    uint256 _value
  ) internal returns (bool) {
    ERC20Storage storage ds = LibERC20.DS();
    ds.allowances[_owner][_spender] = _value;
    emit Approval(_owner, _spender, _value);
    return true;
  }

  // This implements ERC-20.
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    _spendAllowance(from, msg.sender, amount);
    _transfer(from, to, amount);
    return true;
  }

  // This implements ERC-20.
  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    _checkMaxWallet(to, amount);

    bool processingFees = LibHamachi.DS().processingFees;
    (uint256 taxFee, bool isSell) = LibHamachi.determineFee(from, to);
    if (taxFee > 0) {
      uint256 taxAmount = amount / (PERCENTAGE_DENOMINATOR + taxFee);
      taxAmount = amount - (taxAmount * PERCENTAGE_DENOMINATOR);

      if (taxAmount > 0) {
        _transfer(from, address(this), taxAmount);
      }

      uint256 sendAmount = amount - taxAmount;
      if (sendAmount > 0) {
        _transferInternal(from, to, sendAmount);
      }
    } else {
      _transferInternal(from, to, amount);
    }

    LibReward.setRewardBalance(from, balanceOf(from));
    LibReward.setRewardBalance(to, balanceOf(to));

    if (isSell && !processingFees && LibHamachi.DS().processRewards) {
      LibReward.processRewards();
    }

    return true;
  }

  function _transferInternal(
    address from,
    address to,
    uint256 amount
  ) internal {
    ERC20Storage storage ds = LibERC20.DS();
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    uint256 fromBalance = ds.balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      ds.balances[from] = fromBalance - amount;
      // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
      // decrementing then incrementing.
      ds.balances[to] += amount;
    }

    emit Transfer(from, to, amount);
  }

  function mint(address _account, uint256 _amount) internal {
    ERC20Storage storage ds = LibERC20.DS();
    require(_account != address(0), "ERC20: mint to the zero address");
    ds.totalSupply += _amount;
    ds.balances[_account] += _amount;
    emit Transfer(address(0), _account, _amount);
  }

  function burn(address _account, uint256 _amount) internal {
    ERC20Storage storage ds = LibERC20.DS();
    require(_account != address(0), "ERC20: burn from the zero address");
    require(ds.balances[_account] >= _amount, "ERC20: burn amount exceeds balance");
    ds.totalSupply -= _amount;
    ds.balances[_account] -= _amount;
    emit Transfer(_account, address(0), _amount);
  }

  function increaseAllowance(
    address _owner,
    address _spender,
    uint256 _addedValue
  ) internal returns (bool) {
    ERC20Storage storage ds = LibERC20.DS();
    ds.allowances[_owner][_spender] += _addedValue;
    emit Approval(_owner, _spender, ds.allowances[_owner][_spender]);
    return true;
  }

  function decreaseAllowance(
    address _owner,
    address _spender,
    uint256 _subtractedValue
  ) internal returns (bool) {
    ERC20Storage storage ds = LibERC20.DS();
    uint256 oldValue = ds.allowances[_owner][_spender];
    if (_subtractedValue >= oldValue) {
      ds.allowances[_owner][_spender] = 0;
    } else {
      ds.allowances[_owner][_spender] -= _subtractedValue;
    }
    emit Approval(_owner, _spender, ds.allowances[_owner][_spender]);
    return true;
  }

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        approve(owner, spender, currentAllowance - amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {HamachiStorage} from "../types/hamachi/HamachiStorage.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {LibERC20} from "./LibERC20.sol";
import {LibReward} from "./LibReward.sol";
import {LibUniswap} from "./LibUniswap.sol";
import {EXCLUDED_FROM_FEE_ROLE} from "../types/access/AccessControlStorage.sol";

library LibHamachi {
  modifier lockTheSwap() {
    LibHamachi.DS().processingFees = true;
    _;
    LibHamachi.DS().processingFees = false;
  }

  bytes32 internal constant DIAMOND_STORAGE_POSITION =
    keccak256("diamond.standard.hamachi.storage");

  function DS() internal pure returns (HamachiStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function buyFees() internal view returns (uint256, uint256) {
    return (LibHamachi.DS().fee.liquidityBuyFee, LibHamachi.DS().fee.rewardBuyFee);
  }

  function totalBuyFees() internal view returns (uint32) {
    return LibHamachi.DS().fee.rewardBuyFee + LibHamachi.DS().fee.liquidityBuyFee;
  }

  function totalSellFees() internal view returns (uint32) {
    return LibHamachi.DS().fee.rewardSellFee + LibHamachi.DS().fee.liquiditySellFee;
  }

  function isExcludedFromFee(address account) internal view returns (bool) {
    return LibAccessControl.hasRole(EXCLUDED_FROM_FEE_ROLE, account);
  }

  function determineFee(address from, address to) internal view returns (uint32, bool) {
    if (LibHamachi.DS().lpPools[to] && !isExcludedFromFee(from) && !isExcludedFromFee(to)) {
      return (totalSellFees(), true);
    } else if (
      LibHamachi.DS().lpPools[from] && !isExcludedFromFee(to) && !LibHamachi.DS().swapRouters[to]
    ) {
      return (totalBuyFees(), false);
    }

    return (0, false);
  }

  function calculateLiquidifyAmounts(uint256 tokenAmount) internal lockTheSwap returns (uint256, uint256) {
    (uint256 liquidityBuyFee, uint256 rewardBuyFee) = buyFees();
    uint256 totalTax = liquidityBuyFee + rewardBuyFee;
    uint256 liquidityAmount = (tokenAmount * liquidityBuyFee) / totalTax;
    uint256 liquidityTokens = liquidityAmount / 2;
    uint256 rewardAmount = (tokenAmount * rewardBuyFee) / totalTax;
    uint256 sellIntoETH = (liquidityAmount + rewardAmount) - liquidityTokens;

    return (sellIntoETH, liquidityTokens);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// import "@forge-std/src/console.sol";

import {RewardStorage, RewardToken, Map, MAGNITUDE} from "../types/reward/RewardStorage.sol";
import {LibUniswap} from "./LibUniswap.sol";
import {LibHamachi} from "./LibHamachi.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {EXCLUDED_FROM_REWARD_ROLE} from "../types/access/AccessControlStorage.sol";
import {IVestingSchedule} from "../interfaces/IVestingSchedule.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

error InvalidClaimTime();
error NoSupply();
error NullAddress();

library LibReward {
  event UpdateRewardToken(address token);
  event RewardProcessed(address indexed owner, uint256 value, address indexed token);

  bytes32 internal constant REWARD_STORAGE_POSITION = keccak256("diamond.standard.reward.storage");

  function DS() internal pure returns (RewardStorage storage rs) {
    bytes32 position = REWARD_STORAGE_POSITION;
    assembly {
      rs.slot := position
    }
  }

  // ==================== DividendPayingToken ==================== //

  /// @return dividends The amount of rewards that `_owner` has withdrawn
  function withdrawnDividendOf(address _owner) internal view returns (uint256 dividends) {
    return LibReward.DS().withdrawnReward[_owner];
  }

  /// @return accumulated The total accumulated rewards for a address
  function accumulativeDividendOf(address _owner) internal view returns (uint256 accumulated) {
    return
      SafeCast.toUint256(
        SafeCast.toInt256(LibReward.DS().magnifiedRewardPerShare * rewardBalanceOf(_owner)) +
          LibReward.DS().magnifiedReward[_owner]
      ) / MAGNITUDE;
  }

  /// @return withdrawable The total withdrawable rewards for a address
  function withdrawableDividendOf(address _owner) internal view returns (uint256 withdrawable) {
    return accumulativeDividendOf(_owner) - LibReward.DS().withdrawnReward[_owner];
  }

  // ==================== Views ==================== //

  function rewardBalanceOf(address account) internal view returns (uint256) {
    return LibReward.DS().rewardBalances[account];
  }

  function getIndexOfKey(address key) internal view returns (int256 index) {
    return
      LibReward.DS().rewardHolders.inserted[key]
        ? int256(LibReward.DS().rewardHolders.indexOf[key])
        : -1;
  }

  // ==================== Management ==================== //

  /// @notice Adds incoming funds to the rewards per share
  function accrueReward(uint256 amount) internal {
    uint256 rewardSupply = LibReward.DS().totalRewardSupply;
    if (rewardSupply <= 0) revert NoSupply();

    if (amount > 0) {
      LibReward.DS().magnifiedRewardPerShare += (amount * MAGNITUDE) / rewardSupply;
      LibReward.DS().totalAccruedReward += amount;
    }
  }

  function setRewardToken(
    address token,
    address router,
    address[] memory path,
    bool _useV3,
    bytes memory pathV3
  ) internal {
    if (token == address(0)) revert NullAddress();
    RewardToken storage rewardToken = DS().rewardToken;

    rewardToken.token = token;
    rewardToken.router = router;
    rewardToken.path = path;
    rewardToken.useV3 = _useV3;
    rewardToken.pathV3 = pathV3;

    emit UpdateRewardToken(token);
  }

  // This function uses a set amount of gas to process rewards for as many wallets as it can
  function processRewards() internal {
    uint256 gas = LibHamachi.DS().processingGas;
    if (gas == 0) return;

    uint256 numHolders = LibReward.DS().rewardHolders.keys.length;
    uint256 _lastProcessedIndex = LibReward.DS().lastProcessedIndex;
    uint256 gasUsed = 0;
    uint256 gasLeft = gasleft();
    uint256 iterations = 0;

    while (gasUsed < gas && iterations < numHolders) {
      ++iterations;
      if (++_lastProcessedIndex >= LibReward.DS().rewardHolders.keys.length) {
        _lastProcessedIndex = 0;
      }
      address account = LibReward.DS().rewardHolders.keys[_lastProcessedIndex];

      if (LibReward.DS().manualClaim[account]) continue;

      if (!_canAutoClaim(LibReward.DS().claimTimes[account])) continue;
      _processAccount(account, false, 0);

      uint256 newGasLeft = gasleft();
      if (gasLeft > newGasLeft) {
        gasUsed += gasLeft - newGasLeft;
      }
      gasLeft = newGasLeft;
    }
    LibReward.DS().lastProcessedIndex = _lastProcessedIndex;
  }

  /// @param newBalance The new balance to set for the account.
  function setRewardBalance(address account, uint256 newBalance) internal {
    if (LibAccessControl.hasRole(EXCLUDED_FROM_REWARD_ROLE, account)) return;

    if (LibHamachi.DS().vestingContract != address(0)) {
      (, , , , , , uint256 amountTotal, uint256 released) = IVestingSchedule(
        LibHamachi.DS().vestingContract
      ).getVestingSchedule(account);
      if (amountTotal > 0) {
        newBalance += amountTotal - released;
      }
    }

    if (newBalance >= LibReward.DS().minRewardBalance) {
      _setBalance(account, newBalance);
      _set(account, newBalance);
    } else {
      _setBalance(account, 0);
      _remove(account);
      _processAccount(account, false, 0);
    }
  }

  function _canAutoClaim(uint256 lastClaimTime) internal view returns (bool) {
    return
      lastClaimTime > block.timestamp
        ? false
        : block.timestamp - lastClaimTime >= LibReward.DS().claimTimeout;
  }

  function _processAccount(
    address _owner,
    bool _goHami,
    uint256 _expectedOutput
  ) internal {
    uint256 _withdrawableReward = withdrawableDividendOf(_owner);
    if (_withdrawableReward <= 0) return;

    LibReward.DS().withdrawnReward[_owner] += _withdrawableReward;
    LibReward.DS().claimTimes[_owner] = block.timestamp;

    RewardToken memory rewardToken = _goHami ? LibReward.DS().goHam : LibReward.DS().rewardToken;

    bool success = false;
    if (rewardToken.useV3 && !_goHami) {
      success = LibUniswap.swapUsingV3(rewardToken, _withdrawableReward, _owner, _expectedOutput);
    } else {
      success = LibUniswap.swapUsingV2(rewardToken, _withdrawableReward, _owner, _expectedOutput);
    }
    if (success) {
      emit RewardProcessed(_owner, _withdrawableReward, rewardToken.token);
    } else {
      LibReward.DS().withdrawnReward[_owner] -= _withdrawableReward;
    }
  }

  function _setBalance(address _owner, uint256 _newBalance) internal {
    uint256 currentBalance = rewardBalanceOf(_owner);
    LibReward.DS().totalRewardSupply =
      LibReward.DS().totalRewardSupply +
      _newBalance -
      currentBalance;

    if (_newBalance > currentBalance) {
      _add(_owner, _newBalance - currentBalance);
    } else if (_newBalance < currentBalance) {
      _subtract(_owner, currentBalance - _newBalance);
    } else {
      return;
    }
  }

  function _set(address key, uint256 val) internal {
    Map storage rewardHolders = LibReward.DS().rewardHolders;
    if (rewardHolders.inserted[key]) {
      rewardHolders.values[key] = val;
    } else {
      rewardHolders.inserted[key] = true;
      rewardHolders.values[key] = val;
      rewardHolders.indexOf[key] = rewardHolders.keys.length;
      rewardHolders.keys.push(key);
    }
  }

  function _remove(address key) internal {
    Map storage rewardHolders = LibReward.DS().rewardHolders;
    if (!rewardHolders.inserted[key]) {
      return;
    }

    delete rewardHolders.inserted[key];
    delete rewardHolders.values[key];

    uint256 index = rewardHolders.indexOf[key];
    uint256 lastIndex = rewardHolders.keys.length - 1;
    address lastKey = rewardHolders.keys[lastIndex];

    rewardHolders.indexOf[lastKey] = index;
    delete rewardHolders.indexOf[key];

    rewardHolders.keys[index] = lastKey;
    rewardHolders.keys.pop();
  }

  function _add(address _owner, uint256 value) internal {
    LibReward.DS().magnifiedReward[_owner] -= SafeCast.toInt256(
      LibReward.DS().magnifiedRewardPerShare * value
    );
    LibReward.DS().rewardBalances[_owner] += value;
  }

  function _subtract(address _owner, uint256 value) internal {
    LibReward.DS().magnifiedReward[_owner] += SafeCast.toInt256(
      LibReward.DS().magnifiedRewardPerShare * value
    );
    LibReward.DS().rewardBalances[_owner] -= value;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RewardToken} from "@contracts/hamachi/types/reward/RewardStorage.sol";
import {LibERC20} from "./LibERC20.sol";
import {UniswapStorage} from "../types/uniswap/UniswapStorage.sol";

import {IUniswapV2Router02} from "../interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

library LibUniswap {
  event AddLiquidity(uint256 tokenAmount, uint256 ethAmount);

  bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.uniswap.storage");

  function DS() internal pure returns (UniswapStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function swapTokensForEth(uint256 tokenAmount) internal {
    address router = DS().defaultRouter;
    LibERC20.approve(address(this), address(router), tokenAmount);

    // generate the swap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = IUniswapV2Router02(router).WETH();

    // make the swap
    IUniswapV2Router02(router).swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 _value) internal {
    address router = DS().defaultRouter;
    LibERC20.approve(address(this), address(router), tokenAmount);
    IUniswapV2Router02(router).addLiquidityETH{value: _value}(
      address(this),
      tokenAmount,
      0,
      0,
      DS().liquidityWallet,
      block.timestamp
    );
    emit AddLiquidity(tokenAmount, _value);
  }

  function swapUsingV2(
    RewardToken memory rewardToken,
    uint256 _value,
    address _owner,
    uint256 _expectedOutput
  ) internal returns (bool) {
    try
      IUniswapV2Router02(rewardToken.router).swapExactETHForTokensSupportingFeeOnTransferTokens{
        value: _value
      }(_expectedOutput, rewardToken.path, _owner, block.timestamp)
    {
      return true;
    } catch {
      return false;
    }
  }

  function swapUsingV3(
    RewardToken memory rewardToken,
    uint256 _value,
    address _owner,
    uint256 _expectedOutput
  ) internal returns (bool) {
    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: rewardToken.pathV3,
      recipient: address(_owner),
      deadline: block.timestamp,
      amountIn: _value,
      amountOutMinimum: _expectedOutput
    });

    try ISwapRouter(rewardToken.router).exactInput{value: _value}(params) {
      return true;
    } catch {
      return false;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct RoleData {
  mapping(address => bool) members;
  bytes32 adminRole;
  address[] membersList;
}

struct AccessControlStorage {
  mapping(bytes32 => RoleData) roles;
}

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant VESTING_ROLE = keccak256("VESTING_ROLE");
bytes32 constant EXCLUDED_FROM_FEE_ROLE = keccak256("EXCLUDED_FROM_FEE_ROLE");
bytes32 constant EXCLUDED_FROM_MAX_WALLET_ROLE = keccak256("EXCLUDED_FROM_MAX_WALLET_ROLE");
bytes32 constant EXCLUDED_FROM_REWARD_ROLE = keccak256("EXCLUDED_FROM_REWARD_ROLE");
bytes32 constant PROCESS_FEE_ROLE = keccak256("PROCESS_FEE_ROLE");
bytes32 constant CLAIM_REWARD_ROLE = keccak256("CLAIM_REWARD_ROLE");

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FacetAddressAndPosition, FacetFunctionSelectors} from "./Facet.sol";

struct DiamondStorage {
  // maps function selector to the facet address and
  // the position of the selector in the facetFunctionSelectors.selectors array
  mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
  // maps facet addresses to function selectors
  mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
  // facet addresses
  address[] facetAddresses;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Facet {
  address facetAddress;
  bytes4[] functionSelectors;
}

struct FacetCut {
  address facetAddress;
  FacetCutAction action;
  bytes4[] functionSelectors;
}

enum FacetCutAction {
  // Add=0, Replace=1, Remove=2
  Add,
  Replace,
  Remove
}

struct FacetAddressAndPosition {
  address facetAddress;
  uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
}

struct FacetFunctionSelectors {
  bytes4[] functionSelectors;
  uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct ERC165Storage {
  // Used to query if a contract implements an interface.
  // Used to implement ERC-165.
  mapping(bytes4 => bool) supportedInterfaces;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Fee {
  uint32 liquidityBuyFee;
  uint32 rewardBuyFee;
  uint32 liquiditySellFee;
  uint32 rewardSellFee;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Fee} from "../fee/Fee.sol";

struct HamachiStorage {
  address methodsExposureFacetAddress;
  uint256 numTokensToSwap;
  uint256 maxTokenPerWallet;
  mapping(address => bool) lpPools;
  mapping(address => bool) swapRouters;
  uint32 processingGas;
  bool processingFees;
  Fee fee;
  bool processRewards;
  address vestingContract;
}

uint32 constant PERCENTAGE_DENOMINATOR = 10000;
address constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

uint256 constant MAGNITUDE = 2 ** 128;

struct RewardToken {
  address token;
  address router;
  address[] path;
  bool useV3;
  bytes pathV3;
}

struct Map {
  address[] keys;
  mapping(address => uint256) values;
  mapping(address => uint256) indexOf;
  mapping(address => bool) inserted;
}

struct RewardStorage {
  mapping(address => int256) magnifiedReward;
  mapping(address => uint256) withdrawnReward;
  mapping(address => uint256) claimTimes;
  mapping(address => bool) manualClaim;
  mapping(address => uint256) rewardBalances;
  uint256 totalRewardSupply;
  RewardToken rewardToken;
  RewardToken goHam;
  Map rewardHolders;
  uint256 magnifiedRewardPerShare;
  uint256 minRewardBalance;
  uint256 totalAccruedReward;
  uint256 lastProcessedIndex;
  uint32 claimTimeout;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct ERC20Storage {
  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowances;
  uint256 totalSupply;
  string name;
  string symbol;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Fee} from "../fee/Fee.sol";

struct UniswapStorage {
  address liquidityWallet;
  address defaultRouter;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Bytes4ArrayLibUtils {
  function indexOf(bytes4[] memory array, bytes4 value) internal pure returns (uint256) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == value) {
        return i;
      }
    }
    return type(uint256).max;
  }

  function filterOut(bytes4[] memory array, bytes4 value) internal pure returns (bytes4[] memory) {
    uint256 index = indexOf(array, value);
    if (index == type(uint256).max) {
      return array;
    }
    bytes4[] memory newArray = new bytes4[](array.length - 1);
    for (uint256 i = 0; i < index; i++) {
      newArray[i] = array[i];
    }
    for (uint256 i = index; i < newArray.length; i++) {
      newArray[i] = array[i + 1];
    }
    return newArray;
  }
}

library AddressArrayLibUtils {
  function indexOf(address[] memory array, address value) internal pure returns (uint256) {
    for (uint256 i = 0; i < array.length; i++) {
      if (array[i] == value) {
        return i;
      }
    }
    return type(uint256).max;
  }

  function filterOut(
    address[] memory array,
    address value
  ) internal pure returns (address[] memory) {
    uint256 index = indexOf(array, value);
    if (index == type(uint256).max) {
      return array;
    }
    address[] memory newArray = new address[](array.length - 1);
    for (uint256 i = 0; i < index; i++) {
      newArray[i] = array[i];
    }
    for (uint256 i = index; i < newArray.length; i++) {
      newArray[i] = array[i + 1];
    }
    return newArray;
  }

  function swapOut(address[] storage array, address value) internal {
    uint256 index = indexOf(array, value);
    address last = array[array.length - 1];
    array[index] = last;
    array.pop();
  }
}