/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/access/[email protected]
// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

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
interface IERC165Upgradeable {
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

// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {}

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

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
abstract contract AccessControlUpgradeable is
    Initializable,
    ContextUpgradeable,
    IAccessControlUpgradeable,
    ERC165Upgradeable
{
    function __AccessControl_init() internal onlyInitializing {}

    function __AccessControl_init_unchained() internal onlyInitializing {}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File @openzeppelin/contracts-upgradeable/access/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is
    Initializable,
    IAccessControlEnumerableUpgradeable,
    AccessControlUpgradeable
{
    function __AccessControlEnumerable_init() internal onlyInitializing {}

    function __AccessControlEnumerable_init_unchained()
        internal
        onlyInitializing
    {}

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet)
        private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId ==
            type(IAccessControlEnumerableUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

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
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File @openzeppelin/contracts-upgradeable/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(
            nonceAfter == nonceBefore + 1,
            "SafeERC20: permit did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File @openzeppelin/contracts/utils/introspection/[email protected]

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

// File @openzeppelin/contracts/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

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
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

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
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

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

// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File @openzeppelin/contracts/utils/math/[email protected]

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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

// File @openzeppelin/contracts/token/ERC721/[email protected]

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

// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(
            leavesLen + proof.length - 1 == totalHashes,
            "MerkleProof: invalid multiproof"
        );

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen
                ? leaves[leafPos++]
                : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// File contracts/interfaces/ICollection.sol

pragma solidity 0.8.16;

interface ICollection {
    enum TokenType {
        ERC721,
        ERC1155
    }

    struct WhitelistParams {
        bytes32 merkleRoot;
        uint256 endTime;
        uint256 startTime;
    }

    struct Collection {
        string title;
        TokenType tokenType;
        string description;
        string thumbnail;
        string bgImage;
        string bgColor;
        uint256[] tokenIds;
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        int256 userPurchaseLimit;
        int256 allowedPurchaseLimit;
        uint256 primarySoldCount;
        WhitelistParams[] whitelistParams;
        bool exists;
    }

    /**
     * @dev Returns the collection data of a erc721 token.
     * @param _id the id of the collection to fetch data
     * @return Collection the collection data associated with {_id}
     */
    function getCollectionData(uint256 _id)
        external
        returns (Collection memory);

    /**
     * @dev Returns the collection id of a erc721 token.
     * @param _id the id of the collection to fetch data
     * @return Collection the collection data associated with {_id}
     */
    function getERC721CollectionId(uint256 _id) external returns (uint256);

    /**
     * @dev Returns the collection id of a erc1155 token.
     * @param _id the id of the collection to fetch data
     * @return Collection the collection data associated with {_id}
     */
    function getERC1155CollectionId(uint256 _id) external returns (uint256);

    /**
     * @dev Updates the collection after the primary sales.
     * @param account Address of the account which is to be updated
     * @param _collectionId the id of the collection to update
     */
    function updateCollectionAfterPrimarySale(
        address account,
        uint256 _collectionId
    ) external returns (bool);

    /**
     * @dev Returns the primary sale user counts.
     * @param account Address of the account which is to be updated
     * @param _collectionId the id of the collection to update
     */
    function getPrimarySaleUserCount(address account, uint256 _collectionId)
        external
        view
        returns (uint256);
}

// File contracts/interfaces/IERC1155Custom.sol
pragma solidity 0.8.16;

interface IERC1155Custom {
    struct WhitelistParams {
        bytes32 merkleRoot;
        uint256 endTime;
        uint256 startTime;
    }

    struct Collection {
        string title;
        string description;
        string thumbnail;
        string bgImage;
        string bgColor;
        uint256[] tokenIds;
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        int256 userPurchaseLimit;
        int256 allowedPurchaseLimit;
        uint256 primarySoldCount;
        WhitelistParams[] whitelistParams;
        // mapping(address => uint256) primarySaleUserCount;
    }

    /**
     * @dev Returns the First owner address of an {_id}.
     * @param _id the id of the collection to fetch data
     */
    function getFirstOwner(uint256 _id) external returns (address);

    /**
     * @dev Returns the primary sale purchase limit per token of an {_id}.
     * @param _tokenId the id of the token which is to be checked.
     */
    function getPrimarySalePurchaseLimitPerToken(uint256 _tokenId)
        external
        view
        returns (int256);

    /**
     * @dev Returns the primary sale user count per token of an {_id}.
     * @param account Address of the account which is to be checked.
     * @param _tokenId the id of the token which's sale count to be checked.
     */
    function getPrimarySaleUserCountPerToken(address account, uint256 _tokenId)
        external
        view
        returns (uint256);

    /**
     * @dev Updates the primary sale user count per token of an {_id}.
     * @param account Address of the account which is to updated.
     * @param _tokenId the id of the token which's sale should updated.
     * @param quantity Number of count to be increased.
     */
    function updatePrimarySaleUserCountPerToken(
        address account,
        uint256 _tokenId,
        uint256 quantity
    ) external returns (bool);
}

// File contracts/interfaces/IERC721Custom.sol

pragma solidity 0.8.16;

interface IERC721Custom {
    struct WhitelistParams {
        bytes32 merkleRoot;
        uint256 endTime;
        uint256 startTime;
    }

    struct Collection {
        string title;
        string description;
        string thumbnail;
        string bgImage;
        string bgColor;
        uint256[] tokenIds;
        address owner;
        uint256 createdAt;
        uint256 updatedAt;
        int256 userPurchaseLimit;
        int256 allowedPurchaseLimit;
        uint256 primarySoldCount;
        WhitelistParams[] whitelistParams;
    }

    /**
     * @dev Returns the First owner address of an {_id}.
     * @param _id the id of the collection to fetch data
     */
    function getFirstOwner(uint256 _id) external returns (address);
}

// File contracts/interfaces/IMarketPlace.sol

pragma solidity 0.8.16;

interface IMarketplace {
    /// @notice Type of the tokens that can be listed for sale.
    enum TokenType {
        ERC721,
        ERC1155
    }

    /**
     *  @notice The two types of listings.
     *          `Direct`: NFTs listed for sale at a fixed price.
     *          `Auction`: NFTs listed for sale in an auction.
     */
    enum ListingType {
        Direct,
        Auction
    }

    /**
     *  @notice The two types of listings.
     *          `Direct`: NFTs listed for sale at a fixed price.
     *          `Auction`: NFTs listed for sale in an auction.
     */
    enum SaleType {
        Primary,
        Secondary
    }

    /**
     *  @notice The two types of Asset Types.
     *          `NFT`: ERC721 type asset.
     *          `Currency`: ERC20 type asset.
     */
    enum AssetType {
        NFT,
        CURRENCY
    }

    /**
     * @dev For use in `createListing` as a parameter type.
     *
     * @param assetContract         The contract address of the NFT to list for sale.
     * @param tokenId               The tokenId on `assetContract` of the NFT to list for sale.
     *
     * @param quantityToList        The quantity of NFT of ID `tokenId` on the given `assetContract` to list. For
     *                              ERC 721 tokens to list for sale, the contract strictly defaults this to `1`,
     *                              Regardless of the value of `quantityToList` passed.
     *
     * @param currencyToAccept      For direct listings: the currency in which a buyer must pay the listing's fixed price
     *                              to buy the NFT(s). For auctions: the currency in which the bidders must make bids.
     *
     * @param buyoutPrice           For direct listings: interpreted as 'price per token' listed. For auctions: if
     *                              `buyoutPricePerToken` is greater than 0, and a bidder's bid is at least as great as
     *                              `buyoutPricePerToken * quantityToList`, the bidder wins the auction, and the auction
     *                              is closed.
     *
     * @param listingType           The type of listing to create - a direct listing or an auction.
     */
    struct ListingParameters {
        address assetContract;
        uint256 tokenId;
        uint256 quantityToList;
        address currencyToAccept;
        uint256 buyoutPrice;
        ListingType listingType;
        address tokenOwner;
    }

    /**
     * @notice The information related to a listing; either (1) a direct listing, or (2) an auction listing.
     */
    struct Listing {
        uint256 listingId;
        address tokenOwner;
        address assetContract;
        uint256 tokenId;
        uint256 quantity;
        address currency;
        uint256 buyoutPrice;
        TokenType tokenType;
        ListingType listingType;
        SaleType saleType;
    }

    /// @dev Emitted when a new listing is created.
    event NewListing(
        uint256 indexed listingId,
        address indexed assetContract,
        uint256 tokenId,
        address indexed lister,
        Listing listing
    );

    /**
     * @dev Emitted when a buyer buys from a direct listing, or a lister accepts some
     *      buyer's offer to their direct listing.
     */
    event NewSale(
        uint256 indexed listingId,
        address indexed assetContract,
        uint256 tokenId,
        address indexed lister,
        address buyer,
        uint256 quantityBought,
        uint256 pricePaid
    );

    /**
     * @dev Emitted when an admin withdraws the fund to an address.
     */
    event FundsWithdrawn(
        address indexed to,
        address indexed currency,
        uint256 amount
    );

    /**
     * @dev Emitted when an asset is whitelisted.
     */
    event AssetWhitelisted(
        address indexed assetContract,
        AssetType assetType,
        address listedBy,
        bool isWhitelisted
    );

    /**
     * @dev Emitted when a listing is removed.
     */
    event ListingRemoved(uint256 listingId);

    /**
     * @dev Emitted when a listing is modified.
     */
    event ListingModified(
        uint256 listingId,
        uint256 buyoutPrice,
        uint256 quantityToList
    );

    /**
     * @notice Lets a token (ERC 721 or ERC 1155) owner list tokens for sale in a direct listing, or an auction.
     * @param _params The parameters that govern the listing to be created.
     * @dev The values of `_params` are passsed to this function in a `ListingParameters` struct, instead of
     *      directly due to Solidity's limit of the no. of local variables that can be used in a function.
     * @dev NFTs to list for sale in an auction are escrowed in Marketplace. For direct listings, the contract
     *      only checks whether the listing's creator owns and has approved Marketplace to transfer the NFTs to list.
     */
    function createListing(ListingParameters memory _params) external;

    /**
     * @notice Lets someone buy a given quantity of tokens from a direct listing by paying the fixed price.
     *
     * @param _listingId The unique ID of the direct lisitng to buy from.
     *
     * @dev A sale will fail to execute if either:
     *          (1) buyer does not own or has not approved Marketplace to transfer the appropriate
     *              amount of currency (or hasn't sent the appropriate amount of native tokens)
     *
     *          (2) the lister does not own or has removed Markeplace's
     *              approval to transfer the tokens listed for sale.
     */
    function buy(
        uint256 _listingId,
        address _currency,
        uint256 _price,
        uint256 _quantityToBuy,
        bytes32[] memory _proof,
        uint256 _signatureTimestamp,
        bytes memory signature
    ) external payable;

    /**
     * @notice Lets someone buy a given quantity of tokens to another approve account from a direct listing by paying the fixed price.
     *
     * @param _listingId The unique ID of the direct lisitng to buy from.
     *
     * @dev A sale will fail to execute if either:
     *          (1) buyer does not own or has not approved Marketplace to transfer the appropriate
     *              amount of currency (or hasn't sent the appropriate amount of native tokens)
     *
     *          (2) the lister does not own or has removed Markeplace's
     *              approval to transfer the tokens listed for sale.
     */
    function delegatedBuy(
        uint256 _listingId,
        address _currency,
        uint256 _price,
        uint256 _quantityToBuy,
        address _buyer,
        bytes32[] memory _proof,
        uint256 _signatureTimestamp,
        bytes memory signature
    ) external payable;
}

// File contracts/interfaces/INFTCustom.sol

pragma solidity 0.8.16;

interface INFTCustom {
    function getFirstOwner(uint256 _id) external returns (address);
}

// File contracts/interfaces/IWETH.sol

pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);
}

// File contracts/utils/Authenticator.sol

pragma solidity ^0.8.16;

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

contract Authenticator is AccessControlEnumerableUpgradeable {
    address internal _privilegedSigner;

    constructor(address _privilegedSignerAddress) {
        _privilegedSigner = _privilegedSignerAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Check whether the caller is a protocol admin
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ONLY ADMIN");
        _;
    }

    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(address _to, uint256 _timestamp)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _timestamp));
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        address _signer,
        address _to,
        uint256 _timestamp,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _timestamp);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    /**
     * @dev Sets the privilegedSigner address.
     * @param _signer Address of signer.
     */
    function setPrivilegedSigner(address _signer)
        external
        onlyAdmin
        returns (bool)
    {
        require(_signer != address(0), "ZERO_ADDRESS");
        _privilegedSigner = _signer;
        return true;
    }

    /**
     * @dev Returns the privilegedSigner address.
     */
    function getPrivilegedSigner() public view returns (address) {
        return _privilegedSigner;
    }
}

// File contracts/utils/Errors.sol

pragma solidity 0.8.16;

// Library

/**
 * @dev Abstarct for managing error messages.
 *
 */
abstract contract ErrorCodes {
    int32 internal constant ONLY_ADMIN = 0;
    int32 internal constant ONLY_MINTER = 1;
    int32 internal constant ONLY_WHITE_LISTER = 2;
    int32 internal constant ONLY_TOKEN_OWNER = 3;
    int32 internal constant ZERO_ADDRESS = 4;
    int32 internal constant BPS_EXCEEDS_10000 = 5;
    int32 internal constant TOKEN_NOT_EXISTS = 6;
    int32 internal constant URI_QUERY_NON_EXISTENT_TOKEN = 7;
    int32 internal constant URI_NOT_SET = 8;
    int32 internal constant ASSET_NOT_WHITELISTED = 9;
    int32 internal constant CURRENCY_NOT_WHITELISTED = 10;
    int32 internal constant INVALID_TOKEN_AMOUNT = 11;
    int32 internal constant CANT_MODIFY_LISTING_ASSET = 12;
    int32 internal constant CANT_MODIFY_LISTING_TOKEN_ID = 13;
    int32 internal constant CANT_MODIFY_LISTING_TOKEN_TYPE = 14;
    int32 internal constant CURRENCY_OR_PRICE_DOES_NOT_MATCH_LISTING = 15;
    int32 internal constant OWNER_BUYER_CONFLICT = 16;
    int32 internal constant ASSET_INSUFFICIENT_ALLOWANCE_BALANCE = 17;
    int32 internal constant FEES_EXCEEDS_PRICE = 18;
    int32 internal constant TRANSFER_FAILED = 19;
    int32 internal constant BID_AMOUNT_MISMATCH_FROM_LISTING = 20;
    int32
        internal constant INVALID_ASSET_OWNERSHIP_OR_INSUFFICIENT_ALLOWANCE_BALANCE =
        21;
    int32 internal constant INSUFFICIENT_ALLOWANCE_BALANCE_FOR_MARKET = 22;
    int32 internal constant CANT_BUY_LISTING_FROM_AUCTION = 23;
    int32 internal constant BUYING_INVALID_ASSET_AMOUNT = 24;
    int32 internal constant NATIVE_TOKEN_AMOUNT_MISMATCH_FROM_LISTING = 25;
    int32 internal constant TOKEN_INSUFFICIENT_ALLOWANCE_BALANCE = 26;
    int32 internal constant WITHDRAW_ZERO_AMOUNT = 27;
    int32 internal constant WITHDRAW_FAILED = 28;
    int32 internal constant ASSET_ALREADY_WHITELISTED = 29;
    int32 internal constant CURRENCY_ALREADY_WHITELISTED = 30;
    int32 internal constant EITHER_ADMIN_OR_FIRST_OWNER = 31;
    int32 internal constant BURN_AMOUNT_EXCEEDS_BALANCE_OR_ID_NOT_FOUND = 32;
    int32 internal constant INSUFFICIENT_BALANCE_FOR_TRANSFER_OR_ID_NOT_FOUND =
        33;
    int32 internal constant TOKEN_ID_NOT_FOUND = 34;
    int32 internal constant NO_IDS_FOUND = 35;
    int32 internal constant ALREADY_LISTED = 36;
    int32 internal constant SECONDARY_SALE_NOT_SUPPORTED = 37;
    int32 internal constant MARKET_ADDRESS_CANNOT_BE_ZERO_ADDRESS = 38;
    int32 internal constant LISTING_ID_NOT_FOUND = 39;
    int32 internal constant FUNCTION_NOT_EXECUTABLE = 40;
    int32 internal constant UNAUTHORISED_ACCESS = 41;
    int32 internal constant CANNOT_MODIFY_INACTIVE_SALE = 42;
    int32 internal constant QUANTITY_MUST_BE_GREATER_THAN_EQUAL_TO_ONE = 43;
    int32 internal constant TOKEN_ID_DOESNOT_EXIST = 44;
    int32 internal constant MAX_QUANTITY_MUST_BE_GREATER_THAN_ZERO = 45;
    int32 internal constant MAX_QUANTITY_ALLOWANCE_LIMIT_REACHED = 46;
    int32 internal constant ONLY_MAINTAINER = 47;
    int32 internal constant INVALID_TOKEN_OWNER = 48;
    int32 internal constant ADDRESS_NOT_WHITELISTED = 49;
    int32 internal constant EXCEEDED_PRIMARY_PURCHASE_LIMIT = 50;
    int32 internal constant INVALID_COLLECTION_DETAIL = 51;
    int32 internal constant COLLECTION_ID_CANNOT_BE_LESS_THAN_ZERO = 52;
    int32 internal constant INVALID_OWNER = 53;
    int32 internal constant INVALID_WHITELIST_PARAMS = 54;
    int32 internal constant TOKEN_IDS_REQUIRED = 55;
    int32 internal constant SENDER_SHOULD_BE_MARKETPLACE_CONTRACT = 56;
    int32 internal constant INVALID_FUNCTION_PARAMS = 57;
    int32 internal constant ERC721_CANNOT_BE_ZERO_ADDRESS = 58;
    int32 internal constant ERC1155_CANNOT_BE_ZERO_ADDRESS = 59;
    int32 internal constant COLLECTION_DOES_NOT_EXIST = 60;
    int32 internal constant COLLECTION_CONTRACT_CANNOT_BE_ZERO_ADDRESS = 61;
    int32 internal constant INVALID_TOKEN_TYPE = 62;
    int32 internal constant MAXIMUM_PURCHASE_QUANTITY_PER_TOKEN_LIMIT_REACHED =
        63;

    int32 internal constant INVALID_PAYABLE_AMOUNT = 64;
    int32 internal constant INVALID_WITHDRAWABLE_AMOUNT = 65;
    int32 internal constant EXCEEDED_TOKEN_LIMIT = 66;
    int32 internal constant EXCEEDED_MINT_LIMIT = 67;
    int32 internal constant EXCEEDED_INDIVIDUAL_TOKEN_LIMIT = 68;
    int32 internal constant NAME_CANNOT_BE_EMPTY = 69;
    int32 internal constant SYMBOL_CANNOT_BE_EMPTY = 70;
    int32 internal constant INVALID_ROYALTY_BPS = 71;
    int32 internal constant INVALID_MINT_PRICE = 72;
    int32 internal constant INVALID_TOKEN_SUPPLY_CAP = 73;
    int32 internal constant INVALID_USER_PURCHASE_LIMIT = 74;
    int32 internal constant WHITELIST_STARTTIME_MUST_BE_LESS_THAN_ENDTIME = 75;
    int32 internal constant SIGNATURE_MUST_BE_USED_WITHIN_30_MINUTES = 76;

    function throwError(int32 _errCode) public pure returns (string memory) {
        return Strings.toString(uint32(_errCode));
    }
}

// File contracts/TokenTraxxMarket.sol

pragma solidity 0.8.16;

// Royalty

// Security

// Upgrades

// Utils

/**
 * @title Marketplace Contract
 * @author Tokentraxx Team
 * @dev This contract is used to create a listing of of ERC721 and ERC1155 token, which users can buy in direct sale.
 * It supports native currency and whitelisted ERC20 currency to list and make purchases.
 */

contract TokenTraxxMarketplace is
    Initializable,
    IMarketplace,
    AccessControlEnumerableUpgradeable,
    IERC721Receiver,
    ReentrancyGuardUpgradeable,
    ErrorCodes
{
    // using library to safely interact with ERC-20 tokens.
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 public constant WHITE_LISTER = keccak256("WHITE_LISTER");

    /// @dev The address of the native token wrapper contract.
    address public nativeTokenWrapper;

    /// @dev The address of royalty treasury.
    address public royaltyTreasury;

    /// @dev The max bps of the contract. So, 10_000 == 100 %
    uint64 public constant MAX_BPS = 10_000;

    /// @dev The marketplace fee.
    uint64 public marketFeeBps;

    /// @dev The primary fee.
    uint64 public primaryFeeBps;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of ERC20 => whitelisted
    mapping(address => bool) public wlistToken;

    /// @dev The address of NFT => whitelisted
    mapping(address => bool) public wlistAsset;

    /// @dev listingId => listing info.
    mapping(uint256 => Listing) public listings;

    /// @dev safe listing token => prevent multiple listings with same token.
    mapping(uint256 => bool) public safeListing;

    /// @dev Total number of listings on market.
    uint256 public listingIdTracker;

    /// @dev Check whether the caller is a protocol admin
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    /**
     * @dev Method to initialize the contract.
     * @param _nativeTokenWrapper address of the native currency.
     * @param _primaryMarketFeeBps Primary market fees to be set in Bps
     * @param _marketFeeBps Market fees to be set in Bps
     * @param _initialCurrency address of the initial currency.
     * @param _collectionContract address of the collection contract.
     * Requirement:
     * {_nativetokenWrapper} address should not be zero address
     * {_collectionContract} address should not be zero address
     * {_primaryMarketFeeBps} should be less than Max market Fee
     * {_initialCurrency} address should not be zero address
     */
    function initialize(
        address _nativeTokenWrapper,
        uint64 _primaryMarketFeeBps,
        uint64 _marketFeeBps,
        address _initialCurrency,
        address _collectionContract
    ) external initializer {
        __ReentrancyGuard_init();
        _nonZeroAddress(_nativeTokenWrapper, ZERO_ADDRESS);
        _nonZeroAddress(_collectionContract, ZERO_ADDRESS);
        require(
            _primaryMarketFeeBps <= MAX_BPS && _marketFeeBps <= MAX_BPS,
            throwError(BPS_EXCEEDS_10000)
        );
        _nonZeroAddress(_initialCurrency, ZERO_ADDRESS);
        nativeTokenWrapper = _nativeTokenWrapper;
        primaryFeeBps = _primaryMarketFeeBps;
        marketFeeBps = _marketFeeBps;
        royaltyTreasury = address(this);
        collectionContract = _collectionContract;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(WHITE_LISTER, msg.sender);

        wlistToken[_initialCurrency] = true;
    }

    /**
     * @dev This function sets the collection contract
     * @param _collectionContract address of the collection contract.
     * Rquirement:
     * Only admin can call this function
     */
    function setCollectionContract(address _collectionContract)
        external
        onlyAdmin
    {
        _nonZeroAddress(_collectionContract, ZERO_ADDRESS);
        collectionContract = _collectionContract;
    }

    /**
     * @dev Lets a token owner list tokens for sale: Direct Listing or Auction.
     * @param _params datas to be passed for create listing in tuple format.
     * Requirement:
     * Asset should be whitelisted before listing
     * currency should be whitelisted before listing
     * Already listed asset cannot be listed again
     */
    function createListing(ListingParameters calldata _params)
        external
        override
    {
        // Get values to populate `Listing`.
        (uint256 totalListing, ) = getTokenListingCount(
            _params.assetContract,
            _params.tokenId
        );
        require(
            _checkIfZero(totalListing),
            throwError(SECONDARY_SALE_NOT_SUPPORTED)
        );
        require(
            wlistAsset[_params.assetContract],
            throwError(ASSET_NOT_WHITELISTED)
        );
        require(
            wlistToken[_params.currencyToAccept],
            throwError(CURRENCY_NOT_WHITELISTED)
        );

        address tokenOwner;
        TokenType listTokenType = getTokenType(_params.assetContract);

        if (listTokenType == TokenType.ERC721) {
            tokenOwner = IERC721(_params.assetContract).ownerOf(
                _params.tokenId
            );
        } else if (listTokenType == TokenType.ERC1155) {
            tokenOwner = _params.tokenOwner;
        }

        uint256 tokenAmountToList = getSafeQuantity(
            listTokenType,
            _params.quantityToList
        );

        require(tokenAmountToList > 0, throwError(INVALID_TOKEN_AMOUNT));

        validateUserOwnershipAndApproval(
            tokenOwner,
            _params.assetContract,
            _params.tokenId,
            tokenAmountToList,
            listTokenType
        );

        require(
            validateApproval(
                tokenOwner,
                _params.assetContract,
                _params.tokenId,
                listTokenType,
                address(this)
            ),
            throwError(INSUFFICIENT_ALLOWANCE_BALANCE_FOR_MARKET)
        );

        // Defaulting SaleType to Primary, determine based on listingCount when enabling secondary sales
        SaleType saleType = SaleType.Primary;

        Listing memory newListing = Listing({
            listingId: listingIdTracker,
            tokenOwner: tokenOwner,
            assetContract: _params.assetContract,
            tokenId: _params.tokenId,
            quantity: _params.quantityToList,
            currency: _params.currencyToAccept,
            buyoutPrice: _params.buyoutPrice,
            tokenType: listTokenType,
            listingType: _params.listingType,
            saleType: saleType
        });

        listings[listingIdTracker] = newListing;

        _tokenListings[_params.assetContract][_params.tokenId].push(
            listingIdTracker
        );

        emit NewListing(
            listingIdTracker,
            _params.assetContract,
            _params.tokenId,
            tokenOwner,
            newListing
        );

        listingIdTracker += 1;
    }

    /**
     * @dev Lets a token owner modify his listing.
     * @param _listingId listing Id which is to be modified.
     * @param _params datas to be passed for create listing in tuple format.
     */

    function modifyListing(uint256 _listingId, ListingParameters memory _params)
        external
    {
        Listing memory listing = listings[_listingId];
        TokenType _tokenType = getTokenType(_params.assetContract);
        address tokenOwner = _params.tokenOwner;
        if (_tokenType == TokenType.ERC721) {
            tokenOwner = IERC721(_params.assetContract).ownerOf(
                _params.tokenId
            );
        }
        require(
            listing.assetContract == _params.assetContract,
            throwError(CANT_MODIFY_LISTING_ASSET)
        );
        require(
            listing.tokenId == _params.tokenId,
            throwError(CANT_MODIFY_LISTING_TOKEN_ID)
        );
        validateUserOwnershipAndApproval(
            tokenOwner,
            _params.assetContract,
            _params.tokenId,
            _params.quantityToList,
            _tokenType
        );
        require(
            validateApproval(
                tokenOwner,
                _params.assetContract,
                _params.tokenId,
                _tokenType,
                address(this)
            ),
            throwError(INSUFFICIENT_ALLOWANCE_BALANCE_FOR_MARKET)
        );

        require(listing.quantity > 0, throwError(CANNOT_MODIFY_INACTIVE_SALE));

        listing.buyoutPrice = _params.buyoutPrice;
        listing.quantity = _params.quantityToList;
        listings[_listingId] = listing;

        emit ListingModified(
            _listingId,
            _params.buyoutPrice,
            _params.quantityToList
        );
    }

    /**
     * @dev Lets a user buy a token for another approved account.
     * @param _listingId listing Id which is to be bought.
     * @param _currency address of the currency which is used to buy that asset.
     * @param _price Price of the asset which is to buy
     * @param _quantityToBuy Number of assets to be bought.
     * @param _proof Proof should be passed in bytes32
     * Requirement:
     * currency should be valid
     * owner should not be the buyer
     */
    function delegatedBuy(
        uint256 _listingId,
        address _currency,
        uint256 _price,
        uint256 _quantityToBuy,
        address _buyer,
        bytes32[] memory _proof,
        uint256 _signatureTimestamp,
        bytes memory signature
    ) external payable override nonReentrant {
        Listing memory targetListing = listings[_listingId];
        // address buyer = _buyer;
        // Validate passed params based on membership status and listing info
        bool isPrivileged = validateBuyParams(
            _listingId,
            _currency,
            _price,
            _buyer,
            _quantityToBuy,
            _signatureTimestamp,
            signature
        );

        validateSaleParameters(targetListing, _proof, _buyer, _quantityToBuy);

        executeSale(
            targetListing,
            _buyer,
            targetListing.currency,
            _price * _quantityToBuy,
            _quantityToBuy,
            isPrivileged
        );
    }

    ///@dev verifies the whitelisted wallet
    function verifyWalletWhitelist(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    ///@dev validates the sale parameters
    function validateSaleParameters(
        Listing memory listingData,
        bytes32[] memory proof,
        address buyer,
        uint256 quantityToBuy
    ) internal {
        ICollection collectionContractInstance = ICollection(
            collectionContract
        );

        uint256 collectionId = listingData.tokenType == TokenType.ERC721
            ? collectionContractInstance.getERC721CollectionId(
                listingData.tokenId
            )
            : collectionContractInstance.getERC1155CollectionId(
                listingData.tokenId
            );

        ICollection.Collection
            memory collectionData = collectionContractInstance
                .getCollectionData(collectionId);

        if (
            collectionData.allowedPurchaseLimit != -1 &&
            collectionData.allowedPurchaseLimit > 0
        ) {
            require(
                (collectionData.primarySoldCount + quantityToBuy) <=
                    uint256(collectionData.allowedPurchaseLimit),
                throwError(MAX_QUANTITY_ALLOWANCE_LIMIT_REACHED)
            );
        }

        bytes32 merkleRoot = 0x00;

        for (uint256 i; i < collectionData.whitelistParams.length; ++i) {
            if (
                block.timestamp > collectionData.whitelistParams[i].startTime &&
                block.timestamp < collectionData.whitelistParams[i].endTime
            ) {
                merkleRoot = collectionData.whitelistParams[i].merkleRoot;
                break;
            }
        }

        if (merkleRoot != 0x00) {
            require(
                verifyWalletWhitelist(
                    proof,
                    merkleRoot,
                    keccak256(abi.encodePacked(msg.sender))
                ),
                throwError(ADDRESS_NOT_WHITELISTED)
            );
        }

        if (
            INFTCustom(listingData.assetContract).getFirstOwner(
                listingData.tokenId
            ) == collectionData.owner
        ) {
            if (collectionData.userPurchaseLimit != -1) {
                require(
                    collectionContractInstance.getPrimarySaleUserCount(
                        msg.sender,
                        collectionId
                    ) +
                        quantityToBuy <=
                        uint256(collectionData.userPurchaseLimit),
                    throwError(EXCEEDED_PRIMARY_PURCHASE_LIMIT)
                );
            }
        }

        if (listingData.tokenType == TokenType.ERC1155) {
            if (
                IERC1155Custom(listingData.assetContract)
                    .getPrimarySalePurchaseLimitPerToken(listingData.tokenId) >
                0
            ) {
                require(
                    (IERC1155Custom(listingData.assetContract)
                        .getPrimarySaleUserCountPerToken(
                            buyer,
                            listingData.tokenId
                        ) + quantityToBuy) <=
                        uint256(
                            IERC1155Custom(listingData.assetContract)
                                .getPrimarySalePurchaseLimitPerToken(
                                    listingData.tokenId
                                )
                        ),
                    throwError(
                        MAXIMUM_PURCHASE_QUANTITY_PER_TOKEN_LIMIT_REACHED
                    )
                );
            }
        }
    }

    /**
     * @dev Lets a user buy a listed asset.
     * @param _listingId listing Id which is to be bought.
     * @param _currency address of the currency which is used to buy that asset.
     * @param _price Price of the asset
     * @param _quantityToBuy Number of assets to be bought
     * @param proof Proof should be passed in bytes32
     * Requirement:
     * currency should be valid
     * owner should not be the buyer
     */
    function buy(
        uint256 _listingId,
        address _currency,
        uint256 _price,
        uint256 _quantityToBuy,
        bytes32[] memory proof,
        uint256 _signatureTimestamp,
        bytes memory signature
    ) external payable override nonReentrant {
        require(
            _listingId < listingIdTracker,
            throwError(LISTING_ID_NOT_FOUND)
        );
        Listing memory targetListing = listings[_listingId];
        address buyer = _msgSender();

        // Validate passed params based on membership status and listing info
        bool isPrivileged = validateBuyParams(
            _listingId,
            _currency,
            _price,
            buyer,
            _quantityToBuy,
            _signatureTimestamp,
            signature
        );

        validateSaleParameters(targetListing, proof, buyer, _quantityToBuy);

        executeSale(
            targetListing,
            buyer,
            targetListing.currency,
            _price * _quantityToBuy,
            _quantityToBuy,
            isPrivileged
        );
    }

    /// @dev Lets the contract accept ether.
    receive() external payable {}

    /// @dev Performs a direct listing sale.

    function executeSale(
        Listing memory _targetListing,
        address _buyer,
        address _currency,
        uint256 _currencyAmountToTransfer,
        uint256 _quantity,
        bool _isDiscounted
    ) internal {
        validateDirectListingSale(
            _targetListing,
            _quantity,
            _currencyAmountToTransfer
        );

        _targetListing.quantity -= _quantity;
        listings[_targetListing.listingId].quantity = _targetListing.quantity;
        if (_currencyAmountToTransfer > 0) {
            payout(
                msg.sender,
                _targetListing.tokenOwner,
                _currency,
                _currencyAmountToTransfer,
                _targetListing,
                _isDiscounted
            );
        }
        transferListingTokens(_buyer, _quantity, _targetListing);

        ICollection collectionContractInstance = ICollection(
            collectionContract
        );

        uint256 collectionId = _targetListing.tokenType == TokenType.ERC721
            ? collectionContractInstance.getERC721CollectionId(
                _targetListing.tokenId
            )
            : collectionContractInstance.getERC1155CollectionId(
                _targetListing.tokenId
            );

        ICollection.Collection
            memory collectionData = collectionContractInstance
                .getCollectionData(collectionId);

        if (
            INFTCustom(_targetListing.assetContract).getFirstOwner(
                _targetListing.tokenId
            ) == collectionData.owner
        ) {
            collectionContractInstance.updateCollectionAfterPrimarySale(
                msg.sender,
                collectionId
            );
        }

        if (_targetListing.tokenType == TokenType.ERC1155) {
            IERC1155Custom(_targetListing.assetContract)
                .updatePrimarySaleUserCountPerToken(
                    _buyer,
                    _targetListing.tokenId,
                    _quantity
                );
        }

        emit NewSale(
            _targetListing.listingId,
            _targetListing.assetContract,
            _targetListing.tokenId,
            _targetListing.tokenOwner,
            _buyer,
            _quantity,
            _currencyAmountToTransfer
        );
    }

    /**
     * @dev Transfers tokens listed for sale in a direct or auction listing.
     * @param _to address of which token listing should be transferred
     * @param _quantity Number of assets should be transferred.
     * @param _listing listing type of the asset
     * Requirement:
     * quantity should be valid
     */
    function transferListingTokens(
        address _to,
        uint256 _quantity,
        Listing memory _listing
    ) internal {
        require(
            _quantity >= 1,
            throwError(QUANTITY_MUST_BE_GREATER_THAN_EQUAL_TO_ONE)
        );

        if (_listing.tokenType == TokenType.ERC721) {
            IERC721(_listing.assetContract).safeTransferFrom(
                _listing.tokenOwner,
                _to,
                _listing.tokenId,
                ""
            );
        } else if (_listing.tokenType == TokenType.ERC1155) {
            IERC1155(_listing.assetContract).safeTransferFrom(
                _listing.tokenOwner,
                _to,
                _listing.tokenId,
                _quantity,
                ""
            );
        }
    }

    /// @dev Enforces quantity == 1 if tokenType is TokenType.ERC721.
    function getSafeQuantity(TokenType _tokenType, uint256 _quantityToCheck)
        internal
        pure
        returns (uint256 safeQuantity)
    {
        if (_checkIfZero(_quantityToCheck)) {
            safeQuantity = 0;
        } else {
            safeQuantity = _tokenType == TokenType.ERC721
                ? 1
                : _quantityToCheck;
        }
    }

    /// @dev Payout stakeholders on sale
    function payout(
        address _payer,
        address _payee,
        address _currencyToUse,
        uint256 _totalPayoutAmount,
        Listing memory _listing,
        bool _isDiscounted
    ) internal {
        // Collect protocol fee
        uint256 marketCut;
        uint256 _transferAmount;

        if (!_isDiscounted) {
            if (_listing.saleType == SaleType.Primary)
                marketCut = (_totalPayoutAmount * primaryFeeBps) / MAX_BPS;
            else marketCut = (_totalPayoutAmount * marketFeeBps) / MAX_BPS;
        }

        uint256 remainder = _totalPayoutAmount - marketCut;

        if (_listing.saleType == SaleType.Secondary) {
            // Distribute royalties. See Sushiswap's https://github.com/sushiswap/shoyu/blob/master/contracts/base/BaseExchange.sol#L296
            try
                IERC2981(_listing.assetContract).royaltyInfo(
                    _listing.tokenId,
                    _totalPayoutAmount
                )
            returns (address royaltyFeeRecipient, uint256 royaltyFeeAmount) {
                if (royaltyFeeAmount > 0) {
                    require(
                        royaltyFeeAmount + marketCut <= _totalPayoutAmount,
                        throwError(FEES_EXCEEDS_PRICE)
                    );
                    remainder -= royaltyFeeAmount;
                    _transferAmount += royaltyFeeAmount;
                    tShares[royaltyFeeRecipient][
                        _currencyToUse
                    ] += royaltyFeeAmount;
                }
            } catch {}
        } else {
            _transferAmount += marketCut;
            tShares[royaltyTreasury][_currencyToUse] += marketCut;
        }
        // Store remaining funds.
        transferCurrency(
            _currencyToUse,
            _payer,
            royaltyTreasury,
            _transferAmount
        );

        // Distribute price to token owner
        transferCurrency(_currencyToUse, _payer, _payee, remainder);
    }

    /**
     * @dev Transfers a given amount of currency.
     * @param _currency address of currency which is be transferred.
     * @param _from address of which the currency should be transferred.
     * @param _to address of which the currency is to be sent
     * @param _amount Amount of currency which is to be transferred.
     * Requirement:
     * Amount should be valid
     */
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_checkIfZero(_amount)) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeToken(_to, _amount);
            } else if (_to == address(this)) {
                // store native currency in weth
                require(
                    _amount <= msg.value,
                    throwError(BID_AMOUNT_MISMATCH_FROM_LISTING)
                );
                _depositToIWETH(_amount);
                // IWETH(nativeTokenWrapper).deposit{value: _amount}();
            } else {
                // passthrough for native token transfer from buyer to the seller
                safeTransferNativeToken(_to, _amount);
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /**
     * @dev Transfer `amount` of ERC20 token from `from` to `to`.
     * @param _currency address of ERC20 token which is be transferred.
     * @param _from address of which the token should be transferred.
     * @param _to address of which the token is to be sent
     * @param _amount Amount of token which is to be transferred.
     * Requirement:
     * There should be enough balance.
     */
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }
        uint256 balBefore = IERC20Upgradeable(_currency).balanceOf(_to);
        _from == address(this)
            ? IERC20Upgradeable(_currency).safeTransfer(_to, _amount)
            : IERC20Upgradeable(_currency).safeTransferFrom(
                _from,
                _to,
                _amount
            );
        uint256 balAfter = IERC20Upgradeable(_currency).balanceOf(_to);

        require(balAfter == balBefore + _amount, throwError(TRANSFER_FAILED));
    }

    /**
     * @dev  Transfers `amount` of native token to `to`.
     * @param to address of which token is to be transferred.
     * @param value amount of the token to be transferred.
     */
    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        if (!success) {
            _depositToIWETH(value);
            // IWETH(nativeTokenWrapper).deposit{value: value}();
            safeTransferERC20(nativeTokenWrapper, address(this), to, value);
        }
    }

    /**
     * @dev  Validates that `_tokenOwner` owns and has approved to lister / minter to live asset.
     * @param _tokenOwner address of token owner which is to be validated.
     * @param _assetContract address of the asset contract.
     * @param _tokenId Id of the token to be validated
     * @param _quantity Number of tokens
     * @param _tokenType Type of token whether its ERC20/721/1155
     * Requirement:
     * Token owner should be valid
     */
    function validateUserOwnershipAndApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        uint256 _quantity,
        TokenType _tokenType
    ) internal view {
        // address sender = msg.sender;
        if (_tokenType == TokenType.ERC721) {
            require(
                _tokenOwner == msg.sender ||
                    IERC721(_assetContract).isApprovedForAll(
                        _tokenOwner,
                        msg.sender
                    ) ||
                    IERC721(_assetContract).getApproved(_tokenId) == msg.sender,
                throwError(
                    INVALID_ASSET_OWNERSHIP_OR_INSUFFICIENT_ALLOWANCE_BALANCE
                )
            );
        } else if (_tokenType == TokenType.ERC1155) {
            require(
                (_tokenOwner == msg.sender ||
                    IERC1155(_assetContract).isApprovedForAll(
                        _tokenOwner,
                        msg.sender
                    )) &&
                    (IERC1155(_assetContract).balanceOf(
                        _tokenOwner,
                        _tokenId
                    ) >= _quantity),
                throwError(
                    INVALID_ASSET_OWNERSHIP_OR_INSUFFICIENT_ALLOWANCE_BALANCE
                )
            );
        }
    }

    /**
     * @dev  validates the approval of an account.
     * @param _tokenOwner address of token Owner.
     * @param _assetContract address of the asset contract.
     * @param _tokenId Id of the token to be validated
     * @param _tokenType Type of the token whether its ERC20/721/1155
     * @param operator Address of the current operator.
     */
    function validateApproval(
        address _tokenOwner,
        address _assetContract,
        uint256 _tokenId,
        TokenType _tokenType,
        address operator
    ) internal view returns (bool flag) {
        if (_tokenType == TokenType.ERC721) {
            if (
                IERC721(_assetContract).isApprovedForAll(
                    _tokenOwner,
                    operator
                ) || IERC721(_assetContract).getApproved(_tokenId) == operator
            ) {
                return true;
            } else {
                return false;
            }
        } else if (_tokenType == TokenType.ERC1155) {
            if (
                IERC1155(_assetContract).isApprovedForAll(_tokenOwner, operator)
            ) {
                return true;
            } else {
                return false;
            }
        }
    }

    /**
     * @dev  Validates conditions of a direct listing sale.
     * @param _listing Type of the listing.
     * @param _quantityToBuy Number of tokens to be purchased
     * @param settledTotalPrice Total price to be settled.
     * Requirement:
     * Token amount should be valid
     * Cannot buy assets which are in Auction
     */
    function validateDirectListingSale(
        Listing memory _listing,
        uint256 _quantityToBuy,
        uint256 settledTotalPrice
    ) internal {
        require(
            _listing.listingType == ListingType.Direct,
            throwError(CANT_BUY_LISTING_FROM_AUCTION)
        );

        // Check whether a valid quantity of listed tokens is being bought.
        require(
            _listing.quantity > 0 &&
                _quantityToBuy > 0 &&
                _quantityToBuy <= _listing.quantity,
            throwError(BUYING_INVALID_ASSET_AMOUNT)
        );

        // Check: buyer owns and has approved sufficient currency for sale.
        if (_listing.currency == NATIVE_TOKEN) {
            require(
                msg.value == settledTotalPrice,
                throwError(NATIVE_TOKEN_AMOUNT_MISMATCH_FROM_LISTING)
            );
        } else {
            if (settledTotalPrice > 0) {
                validateERC20BalAndAllowance(
                    msg.sender,
                    _listing.currency,
                    settledTotalPrice
                );
            }
        }

        // Check iwhether token owner owns and has approved `quantityToBuy` amount of listing tokens from the listing.
        require(
            validateApproval(
                _listing.tokenOwner,
                _listing.assetContract,
                _listing.tokenId,
                _listing.tokenType,
                address(this)
            ),
            throwError(INSUFFICIENT_ALLOWANCE_BALANCE_FOR_MARKET)
        );
    }

    /// @dev Returns the interface supported by a contract.
    function getTokenType(address _assetContract)
        internal
        view
        returns (TokenType tokenType)
    {
        if (
            IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId)
        ) {
            tokenType = TokenType.ERC721;
        } else if (
            IERC165(_assetContract).supportsInterface(
                type(IERC1155).interfaceId
            )
        ) {
            tokenType = TokenType.ERC1155;
        } else {
            revert MustImplementERC721();
        }
    }

    /**
     * @dev  Sets the Royalty Treasury .
     * @param _treasury addres of the treasury account
     * Requirement:
     * Only admin can call this function
     * treasury address should be valid
     */
    function setRoyaltyTreasury(address _treasury) external onlyAdmin {
        _nonZeroAddress(_treasury, ZERO_ADDRESS);
        royaltyTreasury = _treasury;
    }

    /**
     * @dev  Validates that `_addrToCheck` owns and has approved markeplace to transfer the appropriate amount of currency
     * @param _addrToCheck address to be checked.
     * @param _currency address of the currency.
     * @param _currencyAmountToCheckAgainst address of the currency to be checked against.
     */
    function validateERC20BalAndAllowance(
        address _addrToCheck,
        address _currency,
        uint256 _currencyAmountToCheckAgainst
    ) internal view {
        require(
            IERC20Upgradeable(_currency).balanceOf(_addrToCheck) >=
                _currencyAmountToCheckAgainst &&
                IERC20Upgradeable(_currency).allowance(
                    _addrToCheck,
                    address(this)
                ) >=
                _currencyAmountToCheckAgainst,
            throwError(TOKEN_INSUFFICIENT_ALLOWANCE_BALANCE)
        );
    }

    /**
     *   ERC 721 Receiver functions.
     **/

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /// @dev Lets a protocol admin withdraw tokens from this contract.
    function withdrawFunds(address to, address currency) external nonReentrant {
        _nonZeroAddress(to, ZERO_ADDRESS);
        uint256 amount = tShares[msg.sender][currency];
        tShares[msg.sender][currency] = 0;
        _withdraw(to, currency, amount);
    }

    /**
     * @dev  Lets a protocol admin withdraw treasury amount.
     * @param to address of which token is to be withdrawed.
     * @param currency address of the currency.
     * Requirement:
     * Currency should be valid.
     * Only admin can call the function
     */
    function withdrawTreasury(address to, address currency)
        external
        onlyAdmin
        nonReentrant
    {
        _nonZeroAddress(to, ZERO_ADDRESS);
        uint256 amount = tShares[royaltyTreasury][currency];
        tShares[royaltyTreasury][currency] = 0;
        _withdraw(to, currency, amount);
    }

    /**
     * @dev  Lets a protocol admin withdraw amount.
     * @param to address of which token is to be withdrawed.
     * @param currency address of the currency.
     * @param amount amount to be withdrawn
     * Requirement:
     * Currency should be valid.
     */
    function _withdraw(
        address to,
        address currency,
        uint256 amount
    ) internal {
        IERC20Upgradeable _currency = IERC20Upgradeable(currency);
        bool isNativeToken = _isNativeToken(currency);

        bool transferSuccess;
        require(amount > 0, throwError(WITHDRAW_ZERO_AMOUNT));
        if (royaltyTreasury == address(this)) {
            if (isNativeToken) {
                IWETH(nativeTokenWrapper).withdraw(amount);
                (transferSuccess, ) = payable(to).call{value: amount}("");
            } else {
                _currency.safeTransfer(to, amount);
                transferSuccess = true;
            }
        } else {
            if (isNativeToken) {
                if (
                    IWETH(nativeTokenWrapper).allowance(
                        royaltyTreasury,
                        address(this)
                    ) >= amount
                ) {
                    bool ifWithdrawn = IWETH(nativeTokenWrapper).transferFrom(
                        royaltyTreasury,
                        address(this),
                        amount
                    );
                    if (ifWithdrawn)
                        (transferSuccess, ) = payable(to).call{value: amount}(
                            ""
                        );
                }
            } else {
                _currency.safeTransferFrom(royaltyTreasury, to, amount);
                transferSuccess = true;
            }
        }

        require(transferSuccess, throwError(WITHDRAW_FAILED));
        emit FundsWithdrawn(to, currency, amount);
    }

    /// @dev Checks whether an address is to be interpreted as the native token
    function _isNativeToken(address _toCheck) internal pure returns (bool) {
        return _toCheck == NATIVE_TOKEN || _toCheck == address(0);
    }

    /**
     * @dev Whitelist asset contract [NFT]
     * @param _assetContract address of the asset contract.
     * @param _type Type of the asset whether its NFT or Currency
     * @param _value whether to whitelist or Not.
     * Requirement:
     * Only privileged accounts can call the function
     * asset should not be already whitelisted
     * currency should not be already whitelisted
     */
    function whiteListAsset(
        address _assetContract,
        AssetType _type,
        bool _value
    ) external {
        require(
            hasRole(WHITE_LISTER, msg.sender),
            throwError(ONLY_WHITE_LISTER)
        );
        if (_type == AssetType.NFT) {
            require(
                !wlistAsset[_assetContract],
                throwError(ASSET_ALREADY_WHITELISTED)
            );
            wlistAsset[_assetContract] = _value;
        } else {
            require(
                !wlistToken[_assetContract],
                throwError(CURRENCY_ALREADY_WHITELISTED)
            );
            wlistToken[_assetContract] = _value;
        }

        emit AssetWhitelisted(_assetContract, _type, msg.sender, _value);
    }

    /**
     * @dev  Allows  the admin to remove the listing .
     * @param listingId Id of the listing.
     * Requirement:
     * Only admin can call the function.
     */
    function removeListing(uint256 listingId) external {
        Listing memory listing = listings[listingId];
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                listing.tokenOwner == msg.sender ||
                validateApproval(
                    listing.tokenOwner,
                    listing.assetContract,
                    listing.tokenId,
                    listing.tokenType,
                    msg.sender
                ),
            throwError(UNAUTHORISED_ACCESS)
        );
        address assetContract = listing.assetContract;
        uint256 tokenId = listing.tokenId;
        // Iterate over listing Ids when supporting secondary sale and multiple listings can exist
        require(
            listing.assetContract != address(0),
            throwError(LISTING_ID_NOT_FOUND)
        );
        _tokenListings[assetContract][tokenId].pop();
        delete listings[listingId];
        emit ListingRemoved(listingId);
    }

    ///@dev Gets the token Listing from "_assetcontract" and its "_tokenId".
    function getTokenListingCount(address _assetContract, uint256 _tokenId)
        internal
        view
        returns (uint256 listingCount, uint256 activeCount)
    {
        listingCount = _tokenListings[_assetContract][_tokenId].length;

        for (uint256 i; i < listingCount; ++i) {
            uint256 listingId = _tokenListings[_assetContract][_tokenId][i];
            Listing memory currentListing = listings[listingId];
            if (currentListing.quantity > 0) {
                activeCount++;
            }
        }
    }

    /**
     * @dev Returns latest active listings of the given tokenId, assetContract.
     * @param _assetContract Address of the asset contract.
     * @param _tokenId TokenId of the asset.
     */
    function getTokenListing(address _assetContract, uint256 _tokenId)
        public
        view
        returns (Listing[] memory activeListings)
    {
        (uint256 totalListing, uint256 activeCount) = getTokenListingCount(
            _assetContract,
            _tokenId
        );
        // If there are no listing, return empty array.
        // If there are no active listings, return last completed index.
        // Else return all the active listings array.
        if (_checkIfZero(totalListing)) return activeListings;
        else if (_checkIfZero(activeCount)) activeListings = new Listing[](1);
        else activeListings = new Listing[](activeCount);

        uint256 validIndex;

        for (
            uint256 i;
            i < _tokenListings[_assetContract][_tokenId].length;
            ++i
        ) {
            Listing memory currentListing = listings[
                _tokenListings[_assetContract][_tokenId][i]
            ];
            activeListings[validIndex] = currentListing;
            if (currentListing.quantity > 0) {
                validIndex++;
            }
        }
    }

    /**
     * @dev Sets the authenticator contract address.
     * @param _authenticator Address of authenticator contract.
     */
    function setAuthenticatorContract(address _authenticator)
        external
        onlyAdmin
        returns (bool)
    {
        _nonZeroAddress(_authenticator, ZERO_ADDRESS);
        _authenticatorAddress = _authenticator;
        return true;
    }

    function validateBuyParams(
        uint256 _listingId,
        address _currency,
        uint256 _price,
        address _buyer,
        uint256 _quantityToBuy,
        uint256 _signatureTimestamp,
        bytes memory signature
    ) private view returns (bool) {
        Listing memory targetListing = listings[_listingId];
        bool isPrivileged = false;
        // Check if buyer is a privileged member
        if (signature.length > 0) {
            require(
                block.timestamp <= _signatureTimestamp + 30 minutes,
                throwError(SIGNATURE_MUST_BE_USED_WITHIN_30_MINUTES)
            );
            Authenticator authenticatorContractInstance = Authenticator(
                _authenticatorAddress
            );
            isPrivileged = authenticatorContractInstance.verify(
                authenticatorContractInstance.getPrivilegedSigner(),
                _buyer,
                _signatureTimestamp,
                signature
            );
        }

        // Check whether the settled total price and currency to use are correct.
        if (isPrivileged) {
            require(
                _currency == targetListing.currency &&
                    _price >=
                    targetListing.buyoutPrice -
                        ((targetListing.buyoutPrice * primaryFeeBps) / MAX_BPS),
                throwError(CURRENCY_OR_PRICE_DOES_NOT_MATCH_LISTING)
            );
        } else {
            require(
                _currency == targetListing.currency &&
                    _price == targetListing.buyoutPrice,
                throwError(CURRENCY_OR_PRICE_DOES_NOT_MATCH_LISTING)
            );
        }
        require(
            _buyer != targetListing.tokenOwner,
            throwError(OWNER_BUYER_CONFLICT)
        );
        if (listings[_listingId].tokenType == TokenType.ERC721) {
            //tokenowner at the time of listing is the current owner
            require(
                targetListing.tokenOwner ==
                    IERC721(targetListing.assetContract).ownerOf(
                        targetListing.tokenId
                    ),
                throwError(INVALID_TOKEN_OWNER)
            );
        } else if (targetListing.tokenType == TokenType.ERC1155) {
            //tokenowner at the time of listing is the current owner
            require(
                IERC1155(targetListing.assetContract).balanceOf(
                    targetListing.tokenOwner,
                    listings[_listingId].tokenId
                ) >= _quantityToBuy,
                throwError(INVALID_TOKEN_OWNER)
            );
        }
        return isPrivileged;
    }

    function _onlyAdmin() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            throwError(ONLY_ADMIN)
        );
    }

    function _nonZeroAddress(address _toCheck, int32 _errorCode) private pure {
        require(_toCheck != address(0), throwError(_errorCode));
    }

    function _checkIfZero(uint256 _toCheck) private pure returns (bool) {
        return _toCheck == 0;
    }

    function _depositToIWETH(uint256 _amount) private {
        IWETH(nativeTokenWrapper).deposit{value: _amount}();
    }

    /**
     * @dev Error message - Market: must implement ERC 721.
     * @notice You can use this for reverting when condition fails for ERC721 Implementation required
     */
    error MustImplementERC721();

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    mapping(address => mapping(address => uint256)) public tShares;

    /// @dev safe listing token => prevent multiple listings with same token.
    mapping(address => mapping(uint256 => bool)) private _safeListing;

    // Keep only active listings in this and listing details in db.
    mapping(address => mapping(uint256 => uint256[])) private _tokenListings;

    /// @dev The address of collection contract
    address public collectionContract;

    /// @dev The address of the authenticator contract
    address public _authenticatorAddress;
}