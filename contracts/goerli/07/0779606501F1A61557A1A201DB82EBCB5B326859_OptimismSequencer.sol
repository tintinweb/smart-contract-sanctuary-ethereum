// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./storages/OptimismSequencerStorage.sol";
import "./Staking.sol";
import "./Sequencer.sol";
import "./libraries/LibOptimism.sol";
import "./interfaces/IOptimismSequencer.sol";
// import "hardhat/console.sol";

contract OptimismSequencer is Staking, Sequencer, OptimismSequencerStorage, IOptimismSequencer {
    using BytesParserLib for bytes;
    using SafeERC20 for IERC20;

    /* ========== DEPENDENCIES ========== */

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */


    /* ========== only TON ========== */

    /// @inheritdoc IOptimismSequencer
    function onApprove(
        address sender,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external override(Sequencer, IOptimismSequencer) returns (bool) {
        require(ton == msg.sender, "EA");
        require(existedIndex(data.toUint32(0)), 'non-registered layer');

        // data : (32 bytes) index
        uint32 _index = data.toUint32(0);
        if(amount != 0) IERC20(ton).safeTransferFrom(sender, address(this), amount);
        _stake(_index, 0, sender, amount, address(0), 0);

        return true;
    }

    /* ========== only LayerManager ========== */

    /// @inheritdoc IOptimismSequencer
    function create(uint32 _index, bytes memory _layerInfo)
        external onlyLayer2Manager override(Sequencer, IOptimismSequencer) returns (bool)
    {
        require(_layerInfo.length == 80, "wrong layerInfo");
        require(layerInfo[_index].length == 0, "already created");
        layerInfo[_index] = _layerInfo;

        return true;
    }

    /* ========== Anyone can execute ========== */

    /// @inheritdoc IOptimismSequencer
    function stake(uint32 _index, uint256 amount) external override(Sequencer, IOptimismSequencer)
    {
        require(existedIndex(_index), 'non-registered layer');
        require(amount >= IERC20(ton).allowance(msg.sender, address(this)), "allowance allowance is insufficient is insufficient");

        stake_(_index, 0, amount, address(0), 0);
    }

    /// @inheritdoc IOptimismSequencer
    function unstake(uint32 _index, uint256 lton_) external override
    {
        _unstake(_index, 0, lton_, FwReceiptI(fwReceipt).debtInStaked(false, _index, msg.sender));
    }

    /// @inheritdoc IOptimismSequencer
    function existedIndex(uint32 _index) public view override(Sequencer, IOptimismSequencer) returns (bool) {
        require(Layer2ManagerI(layer2Manager).existedLayer2Index(_index), 'non-registered layer');
        return true;
    }

    /// @inheritdoc IOptimismSequencer
    function getLayerInfo(uint32 _index)
        public view override returns (LibOptimism.Info memory _layerInfo)
    {
        _layerInfo = LibOptimism.parseKey(layerInfo[_index]);
    }

    function getLayerKey(uint32 _index) public view virtual override(Sequencer, IOptimismSequencer) returns (bytes32 layerKey_) {
        layerKey_ = keccak256(layerInfo[_index]);
    }

    /// @inheritdoc IOptimismSequencer
    function getTvl(uint32 _index) public view override(Sequencer, IOptimismSequencer) returns (uint256 amount) {

        LibOptimism.Info memory _layerInfo = getLayerInfo(_index);
        try
            L1BridgeI(L1StandardBridge(_layerInfo.addressManager)).deposits(ton, _layerInfo.l2ton) returns (uint256 a) {
                amount = a;
        } catch (bytes memory ) {
            amount = 0;
        }
    }

    /// @inheritdoc IOptimismSequencer
    function getTvl(address l1Bridge, address l2ton) public view override returns (uint256 amount) {
        try
            L1BridgeI(l1Bridge).deposits(ton, l2ton) returns (uint256 a) {
                amount = a;
        } catch (bytes memory ) {
            amount = 0;
        }
    }

    /// @inheritdoc IOptimismSequencer
    function sequencer(uint32 _index) public view override(Sequencer, IOptimismSequencer) returns (address sequencer_) {
        address manager = LibOptimism.getAddressManager(layerInfo[_index]);
        if (manager == address(0)) return address(0);
        try
            AddressManagerI(LibOptimism.getAddressManager(layerInfo[_index])).getAddress('OVM_Sequencer') returns (address a) {
                sequencer_ = a;
        } catch (bytes memory ) {
            sequencer_ = address(0);
        }
    }

    /// @inheritdoc IOptimismSequencer
    function sequencer(address addressManager) public view override returns (address sequencer_) {
        try
            AddressManagerI(addressManager).getAddress('OVM_Sequencer') returns (address a) {
                sequencer_ = a;
        } catch (bytes memory ) {
            sequencer_ = address(0);
        }
    }

    /// @inheritdoc IOptimismSequencer
    function L1CrossDomainMessenger(address addressManager) public view returns (address account_) {
        try
            AddressManagerI(addressManager).getAddress('OVM_L1CrossDomainMessenger') returns (address a) {
                account_ = a;
        } catch (bytes memory ) {
            account_ = address(0);
        }
    }

    /// @inheritdoc IOptimismSequencer
    function L1StandardBridge(address addressManager) public view override returns (address account_) {
        if (addressManager == address(0)) return address(0);
        try
            AddressManagerI(addressManager).getAddress('Proxy__OVM_L1StandardBridge') returns (address a) {
                account_ = a;
        } catch (bytes memory ) {
            account_ = address(0);
        }
    }

    /// @inheritdoc IOptimismSequencer
    function bridges(uint32 _index) public view override returns (address, address) {
        LibOptimism.Info memory _layerInfo = LibOptimism.parseKey(layerInfo[_index]);
        return (_layerInfo.l1Bridge, _layerInfo.l2Bridge) ;
    }

    /* ========== internal ========== */


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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./AccessRoleCommon.sol";

contract AccessibleCommon is AccessRoleCommon, AccessControl {
    modifier onlyOwner() {
        require(isAdmin(msg.sender), "Accessible: Caller is not an admin");
        _;
    }

    /// @dev add admin
    /// @param account  address to add
    function addAdmin(address account) public virtual onlyOwner {
        grantRole(ADMIN_ROLE, account);
    }

    /// @dev remove admin
    /// @param account  address to remove
    function removeAdmin(address account) public virtual onlyOwner {
        renounceRole(ADMIN_ROLE, account);
    }

    /// @dev transfer admin
    /// @param newAdmin new admin address
    function transferAdmin(address newAdmin) external virtual onlyOwner {
        require(newAdmin != address(0), "Accessible: zero address");
        require(msg.sender != newAdmin, "Accessible: same admin");

        grantRole(ADMIN_ROLE, newAdmin);
        renounceRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev whether admin
    /// @param account  address to check
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AccessRoleCommon {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant POLICY_ROLE = keccak256("POLICY_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burn(address account, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/LibOptimism.sol";

/**
 * @title   OptimismSequencer
 * @dev     create sequencer, stake , get sequencer address and tvl
 */
interface IOptimismSequencer {

    /* ========== only TON ========== */

    /**
     * @dev                 The stake function is executed through the approveAndCall function of TON.
     * @param sender        sender address
     * @param spender       the calling address
     * @param amount        approved amount, amount to be used
     * @param data          data bytes needed when calling a function
     * @return result       true
     */
    function onApprove(
        address sender,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);


    /* ========== only Layer2Manager ========== */

    /**
     * @dev                 create the sequencer contract
     * @param _index        the sequencer index
     * @param _layerInfo    the layer2(sequencer) information (80 bytes)
     *                      addressManager address (20bytes), l1Bridge address (20bytes), l2Bridge address (20bytes), l2ton address (20bytes)
     * @return result       true
     */
    function create(uint32 _index, bytes memory _layerInfo) external returns (bool);

    /* ========== Anyone can execute ========== */

    /**
     * @dev                 stake TON
     * @param _index        the sequencer index
     * @param amount        the amount of TON what want to stake
     */
    function stake(uint32 _index, uint256 amount) external ;

    /**
     * @dev                 unstake TON
     * @param _index        the sequencer index
     * @param lton_         the amount of LTON what want to unstake
     */
    function unstake(uint32 _index, uint256 lton_) external ;

    /* ========== VIEW ========== */

    /**
     * @dev                 whether the sequencer index existed
     * @param _index        the sequencer index
     * @return result       if exist, true , otherwise false
     */
    function existedIndex(uint32 _index) external view returns (bool) ;

     /**
     * @dev                 view the sequencer information
     * @param _index        the sequencer index
     * @return _layerInfo   addressManager, l1Bridge, l2Bridge , l2ton
     */
    function getLayerInfo(uint32 _index) external view returns (LibOptimism.Info memory _layerInfo);

    /**
     * @dev                 view the layer(sequencer) key
     * @param _index        the sequencer index
     * @return layerKey_    the keccak256 of layerInfo bytes
     */
    function getLayerKey(uint32 _index) external view returns (bytes32 layerKey_);

    /**
     * @dev                 view the layer(sequencer)'s total value locked
     * @param _index        the sequencer index
     * @return amount       the amount of deposited at sequencer (TVL)
     */
    function getTvl(uint32 _index) external view returns (uint256 amount) ;

    /**
     * @dev                 view the layer(sequencer)'s total value locked
     * @param l1Bridge      the sequencer's l1bridge address
     * @param l2ton         the sequencer's l2 TON address
     * @return amount       the amount of deposited at sequencer (TVL)
     */
    function getTvl(address l1Bridge, address l2ton) external view returns (uint256 amount) ;

    /**
     * @dev                 view the sequencer address
     * @param _index        the sequencer index
     * @return sequencer_   the sequencer address
     */
    function sequencer(uint32 _index) external view returns (address sequencer_) ;

    /**
     * @dev                     view the sequencer address
     * @param addressManager    the sequencer index
     * @return sequencer_       the sequencer address
     */
    function sequencer(address addressManager) external view returns (address sequencer_);

    /**
     * @dev                     view the L1 crossDomainMessenger address
     * @param addressManager    the addressManager address
     * @return account_         the L1 crossDomainMessenger address
     */
    function L1CrossDomainMessenger(address addressManager) external view returns (address account_) ;

    /**
     * @dev                     view the L1 bridge address
     * @param addressManager    the addressManager address
     * @return account_         the L1 bridge address
     */
    function L1StandardBridge(address addressManager) external view returns (address account_);

    /**
     * @dev                     view the bridge addresses
     * @param _index            the sequencer index
     * @return l1bridge         the L1 bridge address
     * @return l21bridge        the L2 bridge address
     */
    function bridges(uint32 _index) external view returns (address, address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../libraries/LibStake.sol";

/**
 * @title   Staking
 * @dev     There are stake, unsatke, withdraw, fast withdraw functions.
 */
interface IStaking {

    /**
     * @dev                     event that occur when staking
     * @param sequencerIndex    the sequencer index
     * @param candidateIndex    the candidate index
     * @param sender            sender address
     * @param amount            the TON amount of staking
     * @param lton              the lton amount
     * @param commissionTo      address receiving commission
     * @param commissionLton    the lton of commission
     */
    event Staked(uint32 sequencerIndex, uint32 candidateIndex, address sender, uint256 amount, uint256 lton, address commissionTo, uint256 commissionLton);

    /**
     * @dev                     event that occur when unstaking
     * @param sequencerIndex    the sequencer index
     * @param candidateIndex    the candidate index
     * @param sender            sender address
     * @param amount            the TON amount of unstaking
     * @param lton              the lton amount
     */
    event Unstaked(uint32 sequencerIndex, uint32 candidateIndex, address sender, uint256 amount, uint256 lton);

    /**
     * @dev                     event that occur when restaking
     * @param sequencerIndex    the sequencer index
     * @param candidateIndex    the candidate index
     * @param sender            sender address
     * @param amount            the TON amount of restaking
     * @param lton              the lton amount
     */
    event Restaked(uint32 sequencerIndex, uint32 candidateIndex, address sender, uint256 amount, uint256 lton);

    /**
     * @dev                     event that occur when withdrawal
     * @param sequencerIndex    the sequencer index
     * @param candidateIndex    the candidate index
     * @param sender            sender address
     * @param amount            the TON amount of withdrawal
     */
    event Withdrawal(uint32 sequencerIndex, uint32 candidateIndex, address sender, uint256 amount);

    /**
     * @dev                     an event that occurs when the liquidity provided amount is sended to requestor when liquidity is provided
     * @param hashMessage       hashMessage of fast withdrawal
     * @param layerIndex        the sequencer index
     * @param from              the from address (liquidity provider)
     * @param to                the to address (requestor of fast withdrawal)
     * @param amount            the sending amount to requestor
     */
    event FastWithdrawalClaim(bytes32 hashMessage, uint32 layerIndex, address from, address to, uint256 amount);

    /**
     * @dev                     an event that occurs when the liquidity provided amount is staked at finalizing after liquidity is provided to fast withdrawal
     * @param hashMessage       hashMessage of fast withdrawal
     * @param layerIndex        the sequencer index
     * @param staker            the staker address (liquidity provider)
     * @param amount            the TON amount
     * @param lton              the lton amount
     */
    event FastWithdrawalStaked(bytes32 hashMessage, uint32 layerIndex, address staker, uint256 amount, uint256 lton);


    /* ========== only Receipt ========== */

    /**
     * @dev                     the liquidity provided amount is sended to requestor when liquidity is provided
     * @param hashMessage       hashMessage of fast withdrawal
     * @param layerIndex        the sequencer index
     * @param from              the from address (liquidity provider)
     * @param to                the to address (requestor of fast withdrawal)
     * @param amount            the sending amount to requestor
     * @return result           result
     */
    function fastWithdrawClaim(bytes32 hashMessage, uint32 layerIndex, address from, address to, uint256 amount) external returns (bool);

    /**
     * @dev                     the liquidity provided amount is staked at finalizing after liquidity is provided to fast withdrawal
     * @param hashMessage       hashMessage of fast withdrawal
     * @param layerIndex        the sequencer index
     * @param staker            the staker address (liquidity provider)
     * @param amount            the TON amount
     * @return result           result
     */
    function fastWithdrawStake(bytes32 hashMessage, uint32 layerIndex, address staker, uint256 amount) external returns (bool);


    /* ========== Anyone can execute ========== */

    /**
     * @dev                     restaking
     * @param _index            the sequencer index or candidate index
     * @param isCandidate       if it's true, it is a candidate, otherwise it's a sequencer
     */
    function restake(uint32 _index, bool isCandidate) external;

    /**
     * @dev                     multi-restaking
     * @param _index            the sequencer index or candidate index
     * @param n                 hashMessage of fast withdrawal
     * @param isCandidate       if it's true, it is a candidate, otherwise it's a sequencer
     */
    function restakeMulti(uint32 _index, uint256 n, bool isCandidate) external;

    /**
     * @dev                     withdrawal
     * @param _index            the sequencer index or candidate index
     * @param isCandidate       if it's true, it is a candidate, otherwise it's a sequencer
     */
    function withdraw(uint32 _index, bool isCandidate) external ;

    /* ========== VIEW ========== */

    /**
     * @dev                     view the number of pending withdrawals after unstaking
     * @param layerIndex        the sequencer index or candidate index
     * @param account           account address
     * @return totalRequests    the number of total requests
     * @return withdrawIndex    the start index of pending withdraw request
     * @return pendingLength    the length of pending
     */
    function numberOfPendings(uint32 layerIndex, address account)
        external view returns (uint256 totalRequests, uint256 withdrawIndex, uint256 pendingLength);

    /**
     * @dev                                 view the amount of pending withdrawals after unstaking
     * @param layerIndex                    the sequencer index or candidate index
     * @param account                       account address
     * @return amount                       the amount of pending withdraw request
     * @return startIndex                   the start index of pending withdraw request
     * @return len                          the length of pending
     * @return nextWithdrawableBlockNumber  the next withdrawable blockNumber
     */
    function amountOfPendings(uint32 layerIndex, address account)
        external view returns (uint256 amount, uint32 startIndex, uint32 len, uint32 nextWithdrawableBlockNumber);

    /**
     * @dev                     view the amount available for withdrawal
     * @param _index            the sequencer index or candidate index
     * @param account           account address
     * @return amount           the amount available for withdrawal
     * @return startIndex       the start index of available withdrawal
     * @return len              the length of available withdrawal
     */
    function availableWithdraw(uint32 _index, address account)
        external view returns (uint256 amount, uint32 startIndex, uint32 len);

    /**
     * @dev                     the total amount of lton staked of all sequencer or all candidate
     * @return amount           the total amount of lton
     */
    function totalStakedLton() external view returns (uint256 amount);

    /**
     * @dev                     the total amount of lton staked of all sequencer or all candidate at special snapshot id
     * @param snapshotId        snapshot id
     * @return amount           the total amount of lton
     */
    function totalStakedLtonAt(uint256 snapshotId) external view returns (uint256 amount) ;

    /**
     * @dev                     whether it was snapshotted and the total amount of lton staked of all sequencer or all candidate at special snapshot id
     * @param snapshotId        snapshot id
     * @return snapshotted      whether it was snapshotted
     * @return amount           the total amount of lton
     */
    function totalStakedLtonAtSnapshot(uint256 snapshotId) external view returns (bool snapshotted, uint256 amount) ;

    /**
     * @dev                     the amount of lton staked of special sequencer or candidate
     * @param _index            the sequencer index or candidate index
     * @return amount           the amount of lton
     */
    function balanceOfLton(uint32 _index) external view returns (uint256 amount) ;

    /**
     * @dev                     the amount of lton staked of special sequencer or candidate  at special snapshot id
     * @param _index            the sequencer index or candidate index
     * @param snapshotId        snapshot id
     * @return amount           the amount of lton
     */
    function balanceOfLtonAt(uint32 _index, uint256 snapshotId) external view returns (uint256 amount) ;

    /**
     * @dev                     whether it was snapshotted and the amount of lton staked of special sequencer or candidate  at special snapshot id
     * @param _index            the sequencer index or candidate index
     * @param snapshotId        snapshot id
     * @return snapshotted      whether it was snapshotted
     * @return amount           the amount of lton
     */
    function balanceOfLtonAtSnapshot(uint32 _index, uint256 snapshotId) external view returns (bool snapshotted, uint256 amount) ;

    /**
     * @dev                     the amount of lton staked of special sequencer's account or candidate's account
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @return amount           the amount of lton
     */
    function balanceOfLton(uint32 _index, address account) external view returns (uint256 amount);

    /**
     * @dev                     the amount of lton staked of special sequencer's account or candidate's account at special snapshot id
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @param snapshotId        snapshot id
     * @return amount           the amount of lton
     */
    function balanceOfLtonAt(uint32 _index, address account, uint256 snapshotId) external view returns (uint256 amount);

    /**
     * @dev                     whether it was snapshotted and the amount of lton staked of special sequencer's account or candidate's account at special snapshot id
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @param snapshotId        snapshot id
     * @return snapshotted      whether it was snapshotted
     * @return amount           the amount of lton
     */
    function balanceOfLtonAtSnapshot(uint32 _index, address account, uint256 snapshotId) external view returns (bool snapshotted, uint256 amount) ;

    /**
     * @dev                     view the stake infomation of sequencer or canddiate
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @return info             stakePrincipal : the TON amount of staked principal
     *                          stakelton : the ltonamount of staked
     *                          stake : whether account has ever staked
     */
    function getLayerStakes(uint32 _index, address account) external view returns (LibStake.StakeInfo memory info) ;

    /**
     * @dev                     view the amount staked in TON
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @return amount           the amount staked in TON
     */
    function balanceOf(uint32 _index, address account) external view returns (uint256 amount);

    /**
     * @dev                     view the amount staked in TON at special snapshot id
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @param snapshotId        snapshot id
     * @return amount           the amount staked in TON
     */
    function balanceOfAt(uint32 _index, address account, uint256 snapshotId) external view returns (uint256 amount);

    /**
     * @dev                     view the current total layer2's deposit amount
     * @return amount           the amount staked in TON of all layer2's
     */
    function totalLayer2Deposits() external view returns (uint256 amount) ;

    /**
     * @dev                     view the deposit amount of special layer2(sequencer)
     * @param _index            the sequencer index
     * @return amount           the TON amount staked of special layer2(sequencer)
     */
    function layer2Deposits(uint32 _index) external view returns (uint256 amount) ;

    /**
     * @dev                     view the number of staked addresses
     * @return total            the number of staked addresses
     */
    function totalStakeAccountList() external view returns (uint256) ;

    /**
     * @dev                     the total amount of lton staked of all sequencer or all candidate
     * @return amount           the total amount of lton staked
     */
    function getTotalLton() external view returns (uint256);

    /**
     * @dev                     view the list of staked addresses
     * @return accounts         the array of staked addresses
     */
    function getStakeAccountList() external view returns (address[] memory) ;

    /**
     * @dev                     view pending amount for withdrawal after unstaking
     * @param _index            the sequencer index or candidate index
     * @param account           the account address
     * @return amount           the pending amount in TON
     */
    function getPendingUnstakedAmount(uint32 _index, address account) external view returns (uint256) ;

    /**
     * @dev                     view the current snapshot id
     * @return snapshotId       the snapshot id
     */
    function getCurrentSnapshotId() external view returns (uint256);

}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.0;
// pragma solidity >=0.5.0 <0.8.0;

library BytesParserLib {

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    /*
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
    */
    // 바이트의 첫 슬롯에 길이가 없다고 가정할때
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address addressOutput) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');

        assembly {
            addressOutput := mload(add(add(_bytes,0x14),_start))
        }
    }

    // 32 byte에 맞게 가져올때,
    function convertAddressToBytes(address a) public pure returns (bytes memory aaa) {
        assembly {
            aaa := shr(96, mload(add(a, 32)))
        }
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, 'toUint8_overflow');
        require(_bytes.length >= _start + 1, 'toUint8_outOfBounds');
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toBool(bytes memory _bytes, uint256 _start) internal pure returns (bool) {
        require(_start + 1 >= _start, 'toBool_overflow');
        require(_bytes.length >= _start + 1, 'toBool_overflow');
        bool tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_start + 2 >= _start, 'toUint16_overflow');
        require(_bytes.length >= _start + 2, 'toUint16_outOfBounds');
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_start + 4 >= _start, 'toUint32_overflow');
        require(_bytes.length >= _start + 4, 'toUint32_outOfBounds');
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }


    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_start + 32 >= _start, 'toUint256_overflow');
        require(_bytes.length >= _start + 32, 'toUint256_outOfBounds');
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Layer2
{

    struct Layer2Info {
        address layers;
        uint32 index;
    }

    struct Layer2Holdings {
        uint256 securityDeposit;     // ton unit
        uint256 seigs;               // ton unit
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Arrays.sol)
pragma solidity ^0.8.4;

import "./LibStorageSlot.sol";
import "./LibMath.sol";

// import "hardhat/console.sol";

/**
 * @dev Collection of functions related to array types.
 */
library LibArrays {
    using LibStorageSlot for bytes32;


    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = LibMath.average(low, high);

            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }

    }

    function findIndex(uint256[] storage array, uint256 element
    ) internal view returns (uint256) {
        if (array.length == 0) return 0;

        // Shortcut for the actual value
        if (element >= array[array.length-1])
            return (array.length-1);
        if (element < array[0]) return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = array.length-1;
        while (max > min) {
            uint mid = (max + min + 1)/ 2;

            if (array[mid] <= element) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return min;
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (LibStorageSlot.AddressSlot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getAddressSlot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (LibStorageSlot.Bytes32Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getBytes32Slot();
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     *
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (LibStorageSlot.Uint256Slot storage) {
        bytes32 slot;
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0, arr.slot)
            slot := add(keccak256(0, 0x20), pos)
        }
        return slot.getUint256Slot();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.4;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library LibMath {
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
pragma solidity ^0.8.4;

import "./BytesParserLib.sol";

library LibOptimism
{
    using BytesParserLib for bytes;

    struct Info {
        address addressManager;
        address l1Bridge;
        address l2Bridge;
        address l2ton;
    }

    function getKey(
        address addressManager,
        address l1Bridge,
        address l2Bridge,
        address l2ton
    ) external pure returns (bytes32 key_) {
        key_ = bytes32(keccak256(abi.encodePacked(addressManager, l1Bridge, l2Bridge, l2ton)));
    }

    function parseKey(bytes memory data) public pure returns (Info memory info){
         if (data.length > 79) {
            info = Info({
                addressManager : data.toAddress(0),
                l1Bridge : data.toAddress(20),
                l2Bridge : data.toAddress(40),
                l2ton : data.toAddress(60)
            });
         }
    }

    function getAddressManager(bytes memory data) public pure returns (address addr){
         if (data.length > 20) {
            addr = data.toAddress(0);
         }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibStake
{
    struct StakeInfo {
        uint256 stakePrincipal;
        uint256 stakelton;
        bool stake;
    }

    struct WithdrawalReqeust {
        uint32 withdrawableBlockNumber;
        uint128 amount;
        bool processed;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
pragma solidity ^0.8.4;

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
library LibStorageSlot {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract BaseProxyStorage  {

    bool public pauseProxy;

    mapping(uint256 => address) public proxyImplementation;
    mapping(address => bool) public aliveImplementation;
    mapping(bytes4 => address) public selectorImplementation;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Sequencer  {
    /* ========== DEPENDENCIES ========== */

    /* ========== CONSTRUCTOR ========== */

    /* ========== onlyOwner ========== */

    /* ========== only TON ========== */
    function onApprove(
        address sender,
        address spender,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (bool) ;

    /* ========== only Layer2Manager ========== */
    function create (uint32 _index, bytes memory _layerInfo) external virtual returns (bool) ;

    /* ========== Anyone can execute ========== */
    function stake(uint32 _index, uint256 amount) external virtual;

    /* ========== VIEW ========== */
    function existedIndex(uint32 _index) public virtual returns (bool);
    function getLayerKey(uint32 _index) public virtual returns (bytes32 layerKey_);
    function getTvl(uint32 _index) public virtual returns (uint256);
    function sequencer(uint32 _index) public virtual returns (address);

    /* ========== internal ========== */


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./storages/StakingStorage.sol";
import "./proxy/BaseProxyStorage.sol";
import "./common/AccessibleCommon.sol";
import "./libraries/BytesParserLib.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/LibArrays.sol";
import "./interfaces/IStaking.sol";
// import "hardhat/console.sol";

interface L1BridgeI {
    function deposits(address l1token, address l2token) external view returns (uint256);
}

interface AddressManagerI {
    function getAddress(string memory _name) external view returns (address);
}

interface FwReceiptI {
    function debtInStaked(bool isCandidate, uint32 layerIndex, address account) external view returns (uint256);
}

interface SeigManagerV2I {
    function getLtonToTon(uint256 lton) external view returns (uint256);
    function getTonToLton(uint256 amount) external view returns (uint256);

    function updateSeigniorage() external returns (bool);
    function claim(address to, uint256 amount) external;

    function getCurrentSnapshotId() external view returns (uint256);
    function snapshot() external returns (uint256);
    function getLtonToTonAt(uint256 lton, uint256 snapshotId) external view returns (uint256);
    function getTonToLtonAt(uint256 amount, uint256 snapshotId) external view returns (uint256);
}

interface Layer2ManagerI {
    function delayBlocksForWithdraw() external view returns (uint256 amount);
    function totalSecurityDeposit() external view returns (uint256 amount);
    function totalLayer2Deposits() external view returns (uint256 amount);
    function existedLayer2Index(uint32 _index) external view returns (bool exist_);
    function existedCandidateIndex(uint32 _index) external view returns (bool exist_);

    function securityDeposit(uint32 layerIndex) external view returns (uint256 amount);
    function layer2Deposits(uint32 layerIndex) external view returns (uint256 amount);

    function minimumDepositForCandidate() external view returns (uint256);
}


contract Staking is AccessibleCommon, BaseProxyStorage, StakingStorage, IStaking {
    /* ========== DEPENDENCIES ========== */
    using SafeERC20 for IERC20;
    using BytesParserLib for bytes;
    using LibArrays for uint256[];

    /* ========== CONSTRUCTOR ========== */
    constructor() {
    }

    /* ========== onlyOwner ========== */


    /* ========== onlySeigManagerV2 ========== */

    /* ========== only Receipt ========== */

    /// @inheritdoc IStaking
    function fastWithdrawClaim(bytes32 hashMessage, uint32 layerIndex, address from, address to, uint256 amount) external override ifFree returns (bool){
        require(fwReceipt == msg.sender, "FW_CALLER_ERR");
        require(balanceOf(layerIndex, from) >= amount, "liquidity is insufficient");
        _beforeUpdate(layerIndex, from);

        uint256 bal = IERC20(ton).balanceOf(address(this));

        if (bal < amount) {
            if (bal > 0) IERC20(ton).safeTransfer(to, bal);
            SeigManagerV2I(seigManagerV2).claim(to, (amount - bal));
        } else {
            IERC20(ton).safeTransfer(to, amount);
        }

        emit FastWithdrawalClaim(hashMessage, layerIndex, from, to, amount);
        return true;
    }

    /// @inheritdoc IStaking
    function fastWithdrawStake(bytes32 hashMessage, uint32 layerIndex, address staker, uint256 _amount) external override returns (bool){
        require(fwReceipt == msg.sender, "FW_CALLER_ERR");
        _beforeUpdate(layerIndex, staker);

        uint256 lton_ = SeigManagerV2I(seigManagerV2).getTonToLton(_amount);
        layerStakedLton[layerIndex] += lton_;
        _totalStakedLton += lton_;
        LibStake.StakeInfo storage info_ = layerStakes[layerIndex][staker];
        info_.stakePrincipal += _amount;
        info_.stakelton += lton_;
        emit FastWithdrawalStaked(hashMessage, layerIndex, staker, _amount, lton_);
        return true;
    }

    /* ========== Anyone can execute ========== */

    /// @inheritdoc IStaking
    function restake(uint32 _index, bool isCandidate) public override {
        // require(SeigManagerV2I(seigManagerV2).updateSeigniorage(), 'fail updateSeig');
        uint256 i = withdrawalRequestIndex[_index][msg.sender];

        if (isCandidate) require(_restake(0, _index, msg.sender, i, 1),'SL_E_RESTAKE');
        else require(_restake(_index, 0, msg.sender, i, 1),'SL_E_RESTAKE');
    }

    /// @inheritdoc IStaking
    function restakeMulti(uint32 _index, uint256 n, bool isCandidate) external override {
        // require(SeigManagerV2I(seigManagerV2).updateSeigniorage(), 'fail updateSeig');
        uint256 i = withdrawalRequestIndex[_index][msg.sender];
        if (isCandidate)  require(_restake(0, _index, msg.sender, i, n),'SL_E_RESTAKE');
        else require(_restake(_index, 0, msg.sender, i, n),'SL_E_RESTAKE');
    }

    /// @inheritdoc IStaking
    function withdraw(uint32 _index, bool isCandidate) public override ifFree {
        address sender = msg.sender;

        uint256 totalRequests = withdrawalRequests[_index][sender].length;
        uint256 len = 0;
        uint256 amount = 0;

        for(uint256 i = withdrawalRequestIndex[_index][sender]; i < totalRequests ; i++){
            LibStake.WithdrawalReqeust storage r = withdrawalRequests[_index][sender][i];
            if (r.withdrawableBlockNumber < block.number && r.processed == false) {
                r.processed = true;
                amount += uint256(r.amount);
                len++;
            } else {
                break;
            }
        }
        require (amount > 0, 'zero available withdrawal amount');

        withdrawalRequestIndex[_index][sender] += len;
        pendingUnstaked[_index][sender] -= amount;
        pendingUnstakedLayer2[_index] -= amount;
        pendingUnstakedAccount[sender] -= amount;

        uint256 bal = IERC20(ton).balanceOf(address(this));

        if (bal < amount) {
            if (bal > 0) IERC20(ton).safeTransfer(sender, bal);
            SeigManagerV2I(seigManagerV2).claim(sender, (amount - bal));
        } else {
            IERC20(ton).safeTransfer(sender, amount);
        }

        if (isCandidate) emit Withdrawal(0, _index, sender, amount);
        else emit Withdrawal(_index, 0, sender, amount);
    }

    /* ========== VIEW ========== */

    /// @inheritdoc IStaking
    function numberOfPendings(uint32 layerIndex, address account)
        public view override returns (uint256 totalRequests, uint256 withdrawIndex, uint256 pendingLength)
    {
        totalRequests = withdrawalRequests[layerIndex][account].length;
        withdrawIndex = withdrawalRequestIndex[layerIndex][account];
        if (totalRequests >= withdrawIndex) pendingLength = totalRequests - withdrawIndex;
    }

    /// @inheritdoc IStaking
    function amountOfPendings(uint32 layerIndex, address account)
        public view override returns (uint256 amount, uint32 startIndex, uint32 len, uint32 nextWithdrawableBlockNumber)
    {
        uint256 totalRequests = withdrawalRequests[layerIndex][account].length;
        startIndex = uint32(withdrawalRequestIndex[layerIndex][account]);

        for (uint256 i = startIndex; i < totalRequests; i++) {
            LibStake.WithdrawalReqeust memory r = withdrawalRequests[layerIndex][account][i];
            if (r.processed == false) {
                if (nextWithdrawableBlockNumber == 0) nextWithdrawableBlockNumber = r.withdrawableBlockNumber;
                amount += uint256(r.amount);
                len += 1;
            }
        }
    }

    /// @inheritdoc IStaking
    function availableWithdraw(uint32 _index, address account)
        public view override returns (uint256 amount, uint32 startIndex, uint32 len)
    {
        uint256 totalRequests = withdrawalRequests[_index][account].length;
        startIndex = uint32(withdrawalRequestIndex[_index][account]);

        for (uint256 i = startIndex; i < totalRequests; i++) {
            LibStake.WithdrawalReqeust memory r = withdrawalRequests[_index][account][i];
            if (r.withdrawableBlockNumber < block.number && r.processed == false) {
                amount += uint256(r.amount);
                len += 1;
            } else {
                break;
            }
        }
    }

    /// @inheritdoc IStaking
    function totalStakedLton() public view override returns (uint256 amount) {
        return _totalStakedLton;
    }

    /// @inheritdoc IStaking
    function totalStakedLtonAt(uint256 snapshotId) public view override returns (uint256 amount) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalStakedLtonSnapshot);
        return snapshotted ? value : totalStakedLton();
    }

    /// @inheritdoc IStaking
    function totalStakedLtonAtSnapshot(uint256 snapshotId) public view override returns (bool snapshotted, uint256 amount) {
        return _valueAt(snapshotId, _totalStakedLtonSnapshot);
    }

    /// @inheritdoc IStaking
    function balanceOfLton(uint32 _index) public view override returns (uint256 amount) {
        amount = layerStakedLton[_index];
    }

    /// @inheritdoc IStaking
    function balanceOfLtonAt(uint32 _index, uint256 snapshotId) public view override returns (uint256 amount) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _layerStakedLtonSnapshot[_index]);

        return snapshotted ? value : balanceOfLton(_index);
    }

    /// @inheritdoc IStaking
    function balanceOfLtonAtSnapshot(uint32 _index, uint256 snapshotId) public view override returns (bool snapshotted, uint256 amount) {
        return _valueAt(snapshotId, _layerStakedLtonSnapshot[_index]);
    }

    /// @inheritdoc IStaking
    function balanceOfLton(uint32 _index, address account) public view override returns (uint256 amount) {
        LibStake.StakeInfo memory info = layerStakes[_index][account];
        amount = info.stakelton;
    }

    /// @inheritdoc IStaking
    function balanceOfLtonAt(uint32 _index, address account, uint256 snapshotId) public view override returns (uint256 amount) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _layerStakesSnapshot[_index][account]);
        return snapshotted ? value :  balanceOfLton(_index, account);
    }

    /// @inheritdoc IStaking
    function balanceOfLtonAtSnapshot(uint32 _index, address account, uint256 snapshotId) public view override returns (bool snapshotted, uint256 amount) {
        return _valueAt(snapshotId, _layerStakesSnapshot[_index][account]);
    }

    /// @inheritdoc IStaking
    function getLayerStakes(uint32 _index, address account) public view override returns (LibStake.StakeInfo memory info) {
        info = layerStakes[_index][account];
    }

    /// @inheritdoc IStaking
    function balanceOf(uint32 _index, address account) public view override returns (uint256 amount) {
        amount = SeigManagerV2I(seigManagerV2).getLtonToTon(balanceOfLton(_index, account));
    }

    /// @inheritdoc IStaking
    function balanceOfAt(uint32 _index, address account, uint256 snapshotId) public view override returns (uint256 amount) {
        amount = SeigManagerV2I(seigManagerV2).getLtonToTonAt(balanceOfLtonAt(_index, account, snapshotId), snapshotId);
    }

    /// @inheritdoc IStaking
    function totalLayer2Deposits() public view override returns (uint256 amount) {
        amount = Layer2ManagerI(layer2Manager).totalLayer2Deposits();
    }

    /// @inheritdoc IStaking
    function layer2Deposits(uint32 _index) public view override returns (uint256 amount) {
        amount = Layer2ManagerI(layer2Manager).layer2Deposits(_index);
    }

    /// @inheritdoc IStaking
    function totalStakeAccountList() public view override returns (uint256) {
        return stakeAccountList.length;
    }

    /// @inheritdoc IStaking
    function getTotalLton() public view override returns (uint256) {
        return _totalStakedLton;
    }

    /// @inheritdoc IStaking
    function getStakeAccountList() public view returns (address[] memory) {
        return stakeAccountList;
    }

    /// @inheritdoc IStaking
    function getPendingUnstakedAmount(uint32 _index, address account) public view returns (uint256) {
        return pendingUnstaked[_index][account];
    }

    /// @inheritdoc IStaking
    function getCurrentSnapshotId() public view virtual returns (uint256) {
        return SeigManagerV2I(seigManagerV2).getCurrentSnapshotId();
    }

    /* ========== internal ========== */

    function stake_(uint32 _sequencerIndex, uint32 _candidateIndex, uint256 amount, address commissionTo, uint16 commission) internal
    {
        IERC20(ton).safeTransferFrom(msg.sender, address(this), amount);
        _stake(_sequencerIndex, _candidateIndex, msg.sender, amount, commissionTo, commission);
    }

    function _stake(uint32 _sequencerIndex, uint32 _candidateIndex, address sender, uint256 amount, address commissionTo, uint16 commission) internal ifFree nonZero(amount)
    {
        uint32 _index = _sequencerIndex;
        if (_candidateIndex != 0) _index = _candidateIndex;
        _beforeUpdate(_index, sender);

        uint256 lton_ = SeigManagerV2I(seigManagerV2).getTonToLton(amount);
        layerStakedLton[_index] += lton_;
        _totalStakedLton += lton_;

        LibStake.StakeInfo storage info_ = layerStakes[_index][sender];

        if (!info_.stake) {
            info_.stake = true;
            stakeAccountList.push(sender);
        }

        uint256 commissionLton = 0;
        if (commission != 0 && commissionTo != address(0) && commission < 10000) {
            commissionLton = lton_ * commission / 10000;
            lton_ -= commissionLton;

            uint256 amount1 = SeigManagerV2I(seigManagerV2).getLtonToTon(lton_);
            info_.stakePrincipal += amount1;
            info_.stakelton += lton_;

            LibStake.StakeInfo storage commissionInfo_ = layerStakes[_index][commissionTo];
            commissionInfo_.stakePrincipal += (amount - amount1);
            commissionInfo_.stakelton += commissionLton;

        } else {
            info_.stakePrincipal += amount;
            info_.stakelton += lton_;
        }

        emit Staked(_sequencerIndex, _candidateIndex, sender, amount, lton_, commissionTo, commissionLton);
    }

    function _unstake(uint32 _sequencerIndex, uint32 _candidateIndex, uint256 lton_, uint256 _debtTon) internal ifFree nonZero(lton_)
    {
        // require(SeigManagerV2I(seigManagerV2).updateSeigniorage(), 'fail updateSeig');
        uint32 _index = _sequencerIndex;
        if (_candidateIndex != 0) _index = _candidateIndex;

        address sender = msg.sender;
        _beforeUpdate(_index, sender);

        uint256 amount = SeigManagerV2I(seigManagerV2).getLtonToTon(lton_);

        LibStake.StakeInfo storage info_ = layerStakes[_index][sender];

        if (_debtTon != 0) {
            require(lton_ + SeigManagerV2I(seigManagerV2).getTonToLton(_debtTon) <= info_.stakelton,'unstake_err_1');
        } else {
            require(lton_ <= info_.stakelton,'unstake_err_2');
        }

        info_.stakelton -= lton_;
        if (info_.stakePrincipal < amount) info_.stakePrincipal = 0;
        else info_.stakePrincipal -= amount;

        layerStakedLton[_index] -= lton_;
        _totalStakedLton -= lton_;

        uint256 delay = Layer2ManagerI(layer2Manager).delayBlocksForWithdraw();

        withdrawalRequests[_index][sender].push(LibStake.WithdrawalReqeust({
            withdrawableBlockNumber: uint32(block.number + delay),
            amount: uint128(amount),
            processed: false
        }));

        pendingUnstaked[_index][sender] += amount;
        pendingUnstakedLayer2[_index] += amount;
        pendingUnstakedAccount[sender] += amount;

        emit Unstaked(_sequencerIndex, _candidateIndex, sender, amount, lton_);
    }

    function _restake(uint32 _sequencerIndex, uint32 _candidateIndex, address sender, uint256 i, uint256 nlength) internal ifFree returns (bool) {
        uint32 _index = _sequencerIndex;
        if (_candidateIndex != 0) _index = _candidateIndex;

        _beforeUpdate(_index, sender);

        uint256 accAmount;
        uint256 totalRequests = withdrawalRequests[_index][sender].length;

        require(totalRequests > 0, "no unstake");
        require(totalRequests - i >= nlength, "n exceeds num of pending");

        uint256 e = i + nlength;
        for (; i < e; i++) {
            LibStake.WithdrawalReqeust storage r = withdrawalRequests[_index][sender][i];
            uint256 amount = r.amount;
            require(!r.processed, "already withdrawal");
            if (amount > 0) accAmount += amount;
            r.processed = true;
        }

        require(accAmount > 0, "no valid restake amount");

        // deposit-related storages
        uint256 lton_ = SeigManagerV2I(seigManagerV2).getTonToLton(accAmount);
        LibStake.StakeInfo storage info_ = layerStakes[_index][sender];
        info_.stakePrincipal += accAmount;
        info_.stakelton += lton_;
        layerStakedLton[_index] += lton_;
        _totalStakedLton += lton_;

        // withdrawal-related storages
        pendingUnstaked[_index][sender] -= accAmount;
        pendingUnstakedLayer2[_index] -= accAmount;
        pendingUnstakedAccount[sender] -= accAmount;

        withdrawalRequestIndex[_index][sender] += nlength;

        emit Restaked(_sequencerIndex, _candidateIndex, sender, accAmount, lton_);
        return true;
    }

    function _beforeUpdate(uint32 _layerIndex, address account) internal {
        _updateSnapshot(_totalStakedLtonSnapshot, totalStakedLton());
        _updateSnapshot(_layerStakedLtonSnapshot[_layerIndex], balanceOfLton(_layerIndex));
        _updateSnapshot(_layerStakesSnapshot[_layerIndex][account], balanceOfLton(_layerIndex, account));
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        // require(snapshotId > 0, "Snapshot: id is 0");
        require(snapshotId <= getCurrentSnapshotId(), "Snapshot: nonexistent id");

        if (snapshots.ids.length > 0 && snapshotId > snapshots.ids[snapshots.ids.length-1])
            return (false, snapshots.values[snapshots.ids.length-1]);

        uint256 index = snapshots.ids.findIndex(snapshotId);

        if (index >= snapshots.ids.length) return (false, 0);
        return (true, snapshots.values[index]);

    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = getCurrentSnapshotId();

        if (snapshots.ids.length == 0 || _lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OptimismSequencerStorage  {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Layer2} from "../libraries/Layer2.sol";
import "../libraries/LibStake.sol";

contract StakingStorage {

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    bytes4 constant ERC20_ONAPPROVE = 0x4273ca16;
     // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 internal constant InterfaceId_Invalid = 0xffffffff;
    bytes4 internal constant InterfaceId_ERC165 = 0x01ffc9a7;
    mapping(bytes4 => bool) internal _supportedInterfaces;

    bool internal free = true;
    // bool public up;

    address public ton;
    address public seigManagerV2;
    address public layer2Manager;
    address public fwReceipt;
    uint256 internal _totalStakedLton;
    Snapshots internal _totalStakedLtonSnapshot;

    mapping (uint32 => uint256) public layerStakedLton;
    mapping (uint32 => Snapshots) internal _layerStakedLtonSnapshot;

    // layer2Index => account => StakeInfo
    mapping (uint32 => mapping(address => LibStake.StakeInfo)) public layerStakes; // ltos uint
    mapping (uint32 => mapping(address => Snapshots)) internal _layerStakesSnapshot;

    // layer2Index => msg.sender => withdrawal requests (언스테이크시 등록 )
    mapping (uint32 => mapping (address => LibStake.WithdrawalReqeust[])) public withdrawalRequests;
    // layer2Index => msg.sender => index
    mapping (uint32 => mapping (address => uint256)) public withdrawalRequestIndex;

    // pending unstaked amount
    // layer2Index => msg.sender => ton amount
    mapping (uint32 => mapping (address => uint256)) public pendingUnstaked;
    // layer2Index => ton amount
    mapping (uint32 => uint256) public pendingUnstakedLayer2;
    // msg.sender =>  ton amount
    mapping (address => uint256) public pendingUnstakedAccount;

    // layer2Index - info
    mapping (uint32 => bytes) public layerInfo;

    address[] public stakeAccountList;

    modifier nonZero(uint256 value) {
        require(value != 0, "Z1");
        _;
    }

    modifier nonZeroAddress(address account) {
        require(account != address(0), "Z2");
        _;
    }

    modifier onlyLayer2Manager() {
        require(msg.sender == layer2Manager, "not Layer2Manager");
        _;
    }

    modifier ifFree {
        require(free, "lock");
        free = false;
        _;
        free = true;
    }

}