// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../storage/UStorage.sol";

/**
 * @title UInitializable
 * @notice Library to manage the initialization lifecycle of upgradeable contracts
 * @dev `UInitializable` allows the creation of pseudo-constructors for upgradeable contracts. One
 *      `initializer` should be declared per top-level contract. Child contracts can use the `onlyInitializer`
 *      modifier to tag their internal initialization functions to ensure that they can only be called
 *      from a top-level `initializer` or a constructor.
 */
abstract contract UInitializable {
    error UInitializableZeroVersionError();
    error UInitializableAlreadyInitializedError(uint256 version);
    error UInitializableNotInitializingError();

    /// @dev The initialized flag
    Uint256Storage private constant _version = Uint256Storage.wrap(keccak256("equilibria.root.UInitializable.version"));

    /// @dev The initializing flag
    BoolStorage private constant _initializing = BoolStorage.wrap(keccak256("equilibria.root.UInitializable.initializing"));

    /// @dev Can only be called once per version, `version` is 1-indexed
    modifier initializer(uint256 version) {
        if (version == 0) revert UInitializableZeroVersionError();
        if (_version.read() >= version) revert UInitializableAlreadyInitializedError(version);

        _version.store(version);
        _initializing.store(true);

        _;

        _initializing.store(false);
    }

    /// @dev Can only be called from an initializer or constructor
    modifier onlyInitializer() {
        if (!_constructing() && !_initializing.read()) revert UInitializableNotInitializingError();
        _;
    }

    /**
     * @notice Returns whether the contract is currently being constructed
     * @dev {Address.isContract} returns false for contracts currently in the process of being constructed
     * @return Whether the contract is currently being constructed
     */
    function _constructing() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./UInitializable.sol";
import "../../storage/UStorage.sol";

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
 *
 * NOTE: This contract has been extended from the Open Zeppelin library to include an
 *       unstructured storage pattern, so that it can be safely mixed in with upgradeable
 *       contracts without affecting their storage patterns through inheritance.
 */
abstract contract UReentrancyGuard is UInitializable {
    error UReentrancyGuardReentrantCallError();

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    /**
     * @dev unstructured storage slot for the reentrancy status
     */
    Uint256Storage private constant _status = Uint256Storage.wrap(keccak256("equilibria.root.UReentrancyGuard.status"));

    /**
     * @dev Initializes the contract setting the status to _NOT_ENTERED.
     */
    function __UReentrancyGuard__initialize() internal onlyInitializer {
        _status.store(_NOT_ENTERED);
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        if (_status.read() == _ENTERED) revert UReentrancyGuardReentrantCallError();

        // Any calls to nonReentrant after this point will fail
        _status.store(_ENTERED);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status.store(_NOT_ENTERED);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./UFixed18.sol";
import "./PackedFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
type Fixed18Storage is bytes32;
using Fixed18StorageLib for Fixed18Storage global;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);
    error Fixed18PackingOverflowError(int256 value);
    error Fixed18PackingUnderflowError(int256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);
    Fixed18 public constant MAX = Fixed18.wrap(type(int256).max);
    Fixed18 public constant MIN = Fixed18.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) return Fixed18.wrap(-1 * Fixed18.unwrap(from(m)));
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a packed signed fixed-decimal from an signed fixed-decimal
     * @param a signed fixed-decimal
     * @return New packed signed fixed-decimal
     */
    function pack(Fixed18 a) internal pure returns (PackedFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value > type(int128).max) revert Fixed18PackingOverflowError(value);
        if (value < type(int128).min) revert Fixed18PackingUnderflowError(value);
        return PackedFixed18.wrap(int128(value));
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldiv(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / Fixed18.unwrap(c));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.min(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.max(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(SignedMath.abs(Fixed18.unwrap(a)));
    }
}

library Fixed18StorageLib {
    function read(Fixed18Storage self) internal view returns (Fixed18 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Fixed18Storage self, Fixed18 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Fixed18.sol";

/// @dev PackedFixed18 type
type PackedFixed18 is int128;
using PackedFixed18Lib for PackedFixed18 global;

/**
 * @title PackedFixed18Lib
 * @dev A packed version of the Fixed18 which takes up half the storage space (two PackedFixed18 can be packed
 *      into a single slot). Only valid within the range -1.7014118e+20 <= x <= 1.7014118e+20.
 * @notice Library for the packed signed fixed-decimal type.
 */
library PackedFixed18Lib {
    PackedFixed18 public constant MAX = PackedFixed18.wrap(type(int128).max);
    PackedFixed18 public constant MIN = PackedFixed18.wrap(type(int128).min);

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param self Sign
     * @return New signed fixed-decimal
     */
    function unpack(PackedFixed18 self) internal pure returns (Fixed18) {
        return Fixed18.wrap(int256(PackedFixed18.unwrap(self)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./UFixed18.sol";

/// @dev PackedUFixed18 type
type PackedUFixed18 is uint128;
using PackedUFixed18Lib for PackedUFixed18 global;

/**
 * @title PackedUFixed18Lib
 * @dev A packed version of the UFixed18 which takes up half the storage space (two PackedUFixed18 can be packed
 *      into a single slot). Only valid within the range 0 <= x <= 3.4028237e+20.
 * @notice Library for the packed unsigned fixed-decimal type.
 */
library PackedUFixed18Lib {
    PackedUFixed18 public constant MAX = PackedUFixed18.wrap(type(uint128).max);

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param self Sign
     * @return New signed fixed-decimal
     */
    function unpack(PackedUFixed18 self) internal pure returns (UFixed18) {
        return UFixed18.wrap(uint256(PackedUFixed18.unwrap(self)));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Fixed18.sol";
import "./PackedUFixed18.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;
using UFixed18Lib for UFixed18 global;
type UFixed18Storage is bytes32;
using UFixed18StorageLib for UFixed18Storage global;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);
    error UFixed18PackingOverflowError(uint256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);
    UFixed18 public constant MAX = UFixed18.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a packed unsigned fixed-decimal from an unsigned fixed-decimal
     * @param a unsigned fixed-decimal
     * @return New packed unsigned fixed-decimal
     */
    function pack(UFixed18 a) internal pure returns (PackedUFixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > type(uint128).max) revert UFixed18PackingOverflowError(value);
        return PackedUFixed18.wrap(uint128(value));
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldiv(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / UFixed18.unwrap(c));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.min(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.max(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

library UFixed18StorageLib {
    function read(UFixed18Storage self) internal view returns (UFixed18 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(UFixed18Storage self, UFixed18 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed18.sol";

type BoolStorage is bytes32;
using BoolStorageLib for BoolStorage global;
type Uint256Storage is bytes32;
using Uint256StorageLib for Uint256Storage global;
type Int256Storage is bytes32;
using Int256StorageLib for Int256Storage global;
type AddressStorage is bytes32;
using AddressStorageLib for AddressStorage global;
type Bytes32Storage is bytes32;
using Bytes32StorageLib for Bytes32Storage global;

library BoolStorageLib {
    function read(BoolStorage self) internal view returns (bool value) {
        assembly {
            value := sload(self)
        }
    }

    function store(BoolStorage self, bool value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

library Uint256StorageLib {
    function read(Uint256Storage self) internal view returns (uint256 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Uint256Storage self, uint256 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

library Int256StorageLib {
    function read(Int256Storage self) internal view returns (int256 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Int256Storage self, int256 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

library AddressStorageLib {
    function read(AddressStorage self) internal view returns (address value) {
        assembly {
            value := sload(self)
        }
    }

    function store(AddressStorage self, address value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

library Bytes32StorageLib {
    function read(Bytes32Storage self) internal view returns (bytes32 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Bytes32Storage self, bytes32 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../number/types/UFixed18.sol";

/// @dev Token18
type Token18 is address;
using Token18Lib for Token18 global;
type Token18Storage is bytes32;
using Token18StorageLib for Token18Storage global;

/**
 * @title Token18Lib
 * @notice Library to manage 18-decimal ERC20s that is compliant with the fixed-decimal types.
 * @dev Maintains significant gas savings over other Token implementations since no conversion take place
 */
library Token18Lib {
    using SafeERC20 for IERC20;

    Token18 public constant ZERO = Token18.wrap(address(0));

    /**
     * @notice Returns whether a token is the zero address
     * @param self Token to check for
     * @return Whether the token is the zero address
     */
    function isZero(Token18 self) internal pure returns (bool) {
        return Token18.unwrap(self) == Token18.unwrap(ZERO);
    }

    /**
     * @notice Returns whether the two tokens are equal
     * @param a First token to compare
     * @param b Second token to compare
     * @return Whether the two tokens are equal
     */
    function eq(Token18 a, Token18 b) internal pure returns (bool) {
        return Token18.unwrap(a) ==  Token18.unwrap(b);
    }

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     */
    function approve(Token18 self, address grantee) internal {
        IERC20(Token18.unwrap(self)).safeApprove(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token18 self, address grantee, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeApprove(grantee, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token18 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token18 self, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransfer(recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token18 self, address benefactor, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, address(this), UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token18 self, address benefactor, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token18 self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token18 self, address account) internal view returns (UFixed18) {
        return UFixed18.wrap(IERC20(Token18.unwrap(self)).balanceOf(account));
    }
}

library Token18StorageLib {
    function read(Token18Storage self) internal view returns (Token18 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Token18Storage self, Token18 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@equilibria/root/control/unstructured/UInitializable.sol";
import "@equilibria/root/storage/UStorage.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/IController.sol";
import "../interfaces/IProduct.sol";

/**
 * @title UControllerProvider
 * @notice Mix-in that manages a controller pointer and associated permissioning modifiers.
 * @dev Uses unstructured storage so that it is safe to mix-in to upgreadable contracts without modifying
 *      their storage layout.
 */
abstract contract UControllerProvider is UInitializable {
    error AlreadyInitializedError();
    error NotOwnerError(uint256 coordinatorId);
    error NotProductError(IProduct product);
    error NotCollateralError();
    error NotProductOwnerError(IProduct product);
    error PausedError();
    error InvalidControllerError();

    /// @dev The controller contract address
    AddressStorage private constant _controller = AddressStorage.wrap(keccak256("equilibria.perennial.UControllerProvider.controller"));
    function controller() public view returns (IController) { return IController(_controller.read()); }

    /**
     * @notice Initializes the contract state
     * @param controller_ Protocol Controller contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __UControllerProvider__initialize(IController controller_) internal onlyInitializer {
        if (!Address.isContract(address(controller_))) revert InvalidControllerError();
        _controller.store(address(controller_));
    }

    /// @dev Only allow a valid product contract to call
    modifier onlyProduct {
        if (!controller().isProduct(IProduct(msg.sender))) revert NotProductError(IProduct(msg.sender));

        _;
    }

    /// @dev Verify that `product` is a valid product contract
    modifier isProduct(IProduct product) {
        if (!controller().isProduct(product)) revert NotProductError(product);

        _;
    }

    /// @dev Only allow the Collateral contract to call
    modifier onlyCollateral {
        if (msg.sender != address(controller().collateral())) revert NotCollateralError();

        _;
    }

    /// @dev Only allow the protocol owner to call
    modifier onlyOwner(uint256 coordinatorId) {
        if (msg.sender != controller().owner(coordinatorId)) revert NotOwnerError(coordinatorId);

        _;
    }

    /// @dev Only allow if the protocol is currently unpaused
    modifier notPaused() {
        if (controller().paused()) revert PausedError();

        _;
    }

    /// @dev Only allow if both the protocol and the product are currently unpaused
    modifier notPausedProduct(IProduct product) {
        if (controller().paused(product)) revert PausedError();

        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/number/types/Fixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "./IController.sol";
import "./IProduct.sol";

interface ICollateral {
    event Deposit(address indexed user, IProduct indexed product, UFixed18 amount);
    event Withdrawal(address indexed user, IProduct indexed product, UFixed18 amount);
    event AccountSettle(IProduct indexed product, address indexed account, Fixed18 amount, UFixed18 newShortfall);
    event ProductSettle(IProduct indexed product, UFixed18 protocolFee, UFixed18 productFee);
    event Liquidation(address indexed user, IProduct indexed product, address liquidator, UFixed18 fee);
    event ShortfallResolution(IProduct indexed product, UFixed18 amount);
    event FeeClaim(address indexed account, UFixed18 amount);

    error CollateralCantLiquidate(UFixed18 totalMaintenance, UFixed18 totalCollateral);
    error CollateralInsufficientCollateralError();
    error CollateralUnderLimitError();
    error CollateralZeroAddressError();

    function token() external view returns (Token18);
    function fees(address account) external view returns (UFixed18);
    function initialize(IController controller_) external;
    function depositTo(address account, IProduct product, UFixed18 amount) external;
    function withdrawTo(address account, IProduct product, UFixed18 amount) external;
    function liquidate(address account, IProduct product) external;
    function settleAccount(address account, Fixed18 amount) external;
    function settleProduct(UFixed18 amount) external;
    function collateral(address account, IProduct product) external view returns (UFixed18);
    function collateral(IProduct product) external view returns (UFixed18);
    function shortfall(IProduct product) external view returns (UFixed18);
    function liquidatable(address account, IProduct product) external view returns (bool);
    function liquidatableNext(address account, IProduct product) external view returns (bool);
    function resolveShortfall(IProduct product, UFixed18 amount) external;
    function claimFee() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "./ICollateral.sol";
import "./IIncentivizer.sol";
import "./IProduct.sol";
import "./IProductProvider.sol";

interface IController {
    /// @dev Coordinator of a one or many products
    struct Coordinator {
        /// @dev Pending owner of the product, can accept ownership
        address pendingOwner;

        /// @dev Owner of the product, allowed to update select parameters
        address owner;

        /// @dev Treasury of the product, collects fees
        address treasury;

        /// @dev the address that is allowed to pause the coordinated products (0-address defaults to owner)
        address pauser;

        /// @dev Whether the coordinated products are paused
        bool paused;
    }

    event CollateralUpdated(ICollateral newCollateral);
    event IncentivizerUpdated(IIncentivizer newIncentivizer);
    event ProductBeaconUpdated(IBeacon newProductBeacon);
    event ProtocolFeeUpdated(UFixed18 newProtocolFee);
    event MinFundingFeeUpdated(UFixed18 newMinFundingFee);
    event LiquidationFeeUpdated(UFixed18 newLiquidationFee);
    event IncentivizationFeeUpdated(UFixed18 newIncentivizationFee);
    event MinCollateralUpdated(UFixed18 newMinCollateral);
    event ProgramsPerProductUpdated(uint256 newProgramsPerProduct);
    event CoordinatorPendingOwnerUpdated(uint256 indexed coordinatorId, address newPendingOwner);
    event CoordinatorOwnerUpdated(uint256 indexed coordinatorId, address newOwner);
    event CoordinatorTreasuryUpdated(uint256 indexed coordinatorId, address newTreasury);
    event CoordinatorPauserUpdated(uint256 indexed coordinatorId, address pauser);
    event CoordinatorPausedUpdated(uint256 indexed coordinatorId, bool paused);
    event CoordinatorCreated(uint256 indexed coordinatorId, address owner);
    event ProductCreated(IProduct indexed product, IProductProvider provider);

    error ControllerAlreadyInitializedError();
    error ControllerNoZeroCoordinatorError();
    error ControllerNotPauserError(uint256 coordinatorId);
    error ControllerNotOwnerError(uint256 controllerId);
    error ControllerNotPendingOwnerError(uint256 controllerId);
    error ControllerInvalidProtocolFeeError();
    error ControllerInvalidMinFundingFeeError();
    error ControllerInvalidLiquidationFeeError();
    error ControllerInvalidIncentivizationFeeError();

    function collateral() external view returns (ICollateral);
    function incentivizer() external view returns (IIncentivizer);
    function productBeacon() external view returns (IBeacon);
    function coordinators(uint256 collateralId) external view returns (Coordinator memory);
    function coordinatorFor(IProduct product) external view returns (uint256);
    function protocolFee() external view returns (UFixed18);
    function minFundingFee() external view returns (UFixed18);
    function liquidationFee() external view returns (UFixed18);
    function incentivizationFee() external view returns (UFixed18);
    function minCollateral() external view returns (UFixed18);
    function programsPerProduct() external view returns (uint256);
    function initialize(ICollateral collateral_, IIncentivizer incentivizer_, IBeacon productBeacon_) external;
    function createCoordinator(address coordinatorOwner) external returns (uint256);
    function updateCoordinatorPendingOwner(uint256 coordinatorId, address newPendingOwner) external;
    function acceptCoordinatorOwner(uint256 coordinatorId) external;
    function updateCoordinatorTreasury(uint256 coordinatorId, address newTreasury) external;
    function updateCoordinatorPauser(uint256 coordinatorId, address newPauser) external;
    function updateCoordinatorPaused(uint256 coordinatorId, bool newPaused) external;
    function createProduct(uint256 coordinatorId, IProductProvider provider) external returns (IProduct);
    function updateCollateral(ICollateral newCollateral) external;
    function updateIncentivizer(IIncentivizer newIncentivizer) external;
    function updateProductBeacon(IBeacon newProductBeacon) external;
    function updateProtocolFee(UFixed18 newProtocolFee) external;
    function updateMinFundingFee(UFixed18 newMinFundingFee) external;
    function updateLiquidationFee(UFixed18 newLiquidationFee) external;
    function updateIncentivizationFee(UFixed18 newIncentivizationFee) external;
    function updateMinCollateral(UFixed18 newMinCollateral) external;
    function updateProgramsPerProduct(uint256 newProductsPerProduct) external;
    function isProduct(IProduct product) external view returns (bool);
    function owner() external view returns (address);
    function owner(uint256 coordinatorId) external view returns (address);
    function owner(IProduct product) external view returns (address);
    function treasury() external view returns (address);
    function treasury(uint256 coordinatorId) external view returns (address);
    function treasury(IProduct product) external view returns (address);
    function pauser() external view returns (address);
    function pauser(uint256 coordinatorId) external view returns (address);
    function pauser(IProduct product) external view returns (address);
    function paused() external view returns (bool);
    function paused(uint256 coordinatorId) external view returns (bool);
    function paused(IProduct product) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/number/types/UFixed18.sol";
import "./types/ProgramInfo.sol";
import "./IOracleProvider.sol";
import "./IController.sol";
import "./IProduct.sol";

interface IIncentivizer {
    event ProgramCreated(IProduct indexed product, uint256 indexed programId, uint256 coordinatorId, Token18 token, UFixed18 amountMaker, UFixed18 amountTaker, uint256 start, uint256 duration, UFixed18 programFeeAmount);
    event ProgramStarted(IProduct indexed product, uint256 indexed programId, uint256 version);
    event ProgramComplete(IProduct indexed product, uint256 indexed programId, uint256 version);
    event Claim(IProduct indexed product, address indexed account, uint256 indexed programId, UFixed18 amount);
    event FeeClaim(Token18 indexed token, UFixed18 amount);

    error IncentivizerNotAllowedError(IProduct product);
    error IncentivizerTooManyProgramsError();
    error IncentivizerNotProgramOwnerError(IProduct product, uint256 programId);
    error IncentivizerInvalidProgramError(IProduct product, uint256 programId);

    function programInfos(IProduct product, uint256 programId) external view returns (ProgramInfo memory);
    function fees(Token18 token) external view returns (UFixed18);
    function initialize(IController controller_) external;
    function create(IProduct product, ProgramInfo calldata info) external returns (uint256);
    function complete(IProduct product, uint256 programId) external;
    function sync(IOracleProvider.OracleVersion memory currentOracleVersion) external;
    function syncAccount(address account, IOracleProvider.OracleVersion memory currentOracleVersion) external;
    function claim(IProduct product, uint256[] calldata programIds) external;
    function claim(IProduct[] calldata products, uint256[][] calldata programIds) external;
    function claimFee(Token18[] calldata tokens) external;
    function active(IProduct product) external view returns (uint256);
    function count(IProduct product) external view returns (uint256);
    function unclaimed(IProduct product, address account, uint256 programId) external view returns (UFixed18);
    function available(IProduct product, uint256 programId) external view returns (UFixed18);
    function versionStarted(IProduct product, uint256 programId) external view returns (uint256);
    function versionComplete(IProduct product, uint256 programId) external view returns (uint256);
    function owner(IProduct product, uint256 programId) external view returns (address);
    function treasury(IProduct product, uint256 programId) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed18.sol";

interface IOracleProvider {
    /// @dev A singular oracle version with its corresponding data
    struct OracleVersion {
        /// @dev The iterative version
        uint256 version;

        /// @dev the timestamp of the oracle update
        uint256 timestamp;

        /// @dev The oracle price of the corresponding version
        Fixed18 price;
    }

    function sync() external returns (OracleVersion memory);
    function currentVersion() external view returns (OracleVersion memory);
    function atVersion(uint256 oracleVersion) external view returns (OracleVersion memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "./types/Position.sol";
import "./types/PrePosition.sol";
import "./types/Accumulator.sol";
import "./IProductProvider.sol";

interface IProduct {
    event Settle(uint256 preVersion, uint256 toVersion);
    event AccountSettle(address indexed account, uint256 preVersion, uint256 toVersion);
    event MakeOpened(address indexed account, uint256 version, UFixed18 amount);
    event TakeOpened(address indexed account, uint256 version, UFixed18 amount);
    event MakeClosed(address indexed account, uint256 version, UFixed18 amount);
    event TakeClosed(address indexed account, uint256 version, UFixed18 amount);

    error ProductInsufficientLiquidityError(UFixed18 socializationFactor);
    error ProductDoubleSidedError();
    error ProductOverClosedError();
    error ProductInsufficientCollateralError();
    error ProductInLiquidationError();
    error ProductMakerOverLimitError();
    error ProductOracleBootstrappingError();

    function productProvider() external view returns (IProductProvider);
    function initialize(IProductProvider productProvider_) external;
    function settle() external;
    function settleAccount(address account) external;
    function openTake(UFixed18 amount) external;
    function closeTake(UFixed18 amount) external;
    function openMake(UFixed18 amount) external;
    function closeMake(UFixed18 amount) external;
    function closeAll(address account) external;
    function maintenance(address account) external view returns (UFixed18);
    function maintenanceNext(address account) external view returns (UFixed18);
    function isClosed(address account) external view returns (bool);
    function isLiquidating(address account) external view returns (bool);
    function position(address account) external view returns (Position memory);
    function pre(address account) external view returns (PrePosition memory);
    function latestVersion() external view returns (uint256);
    function positionAtVersion(uint256 oracleVersion) external view returns (Position memory);
    function pre() external view returns (PrePosition memory);
    function valueAtVersion(uint256 oracleVersion) external view returns (Accumulator memory);
    function shareAtVersion(uint256 oracleVersion) external view returns (Accumulator memory);
    function latestVersion(address account) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/number/types/Fixed18.sol";
import "./types/Position.sol";
import "./IOracleProvider.sol";

interface IProductProvider is IOracleProvider {
    function oracle() external view returns (IOracleProvider);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function rate(Position memory position) external view returns (Fixed18);
    function maintenance() external view returns (UFixed18);
    function fundingFee() external view returns (UFixed18);
    function makerFee() external view returns (UFixed18);
    function takerFee() external view returns (UFixed18);
    function makerLimit() external view returns (UFixed18);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed18.sol";
import "./PackedAccumulator.sol";

/// @dev Accumulator type
struct Accumulator {
    /// @dev maker accumulator per share
    Fixed18 maker;
    /// @dev taker accumulator per share
    Fixed18 taker;
}
using AccumulatorLib for Accumulator global;

/**
 * @title AccountAccumulatorLib
 * @notice Library that surfaces math operations for the Accumulator type.
 * @dev Accumulators track the cumulative change in position value over time for the maker and taker positions
 *      respectively. Account-level accumulators can then use two of these values `a` and `a'` to compute the
 *      change in position value since last sync. This change in value is then used to compute P&L and fees.
 */
library AccumulatorLib {
    /**
     * @notice Creates a packed accumulator from an accumulator
     * @param self an accumulator
     * @return New packed accumulator
     */
    function pack(Accumulator memory self) internal pure returns (PackedAccumulator memory) {
        return PackedAccumulator({maker: self.maker.pack(), taker: self.taker.pack()});
    }

    /**
     * @notice Adds two accumulators together
     * @param a The first accumulator to sum
     * @param b The second accumulator to sum
     * @return The resulting summed accumulator
     */
    function add(Accumulator memory a, Accumulator memory b) internal pure returns (Accumulator memory) {
        return Accumulator({maker: a.maker.add(b.maker), taker: a.taker.add(b.taker)});
    }

    /**
     * @notice Subtracts accumulator `b` from `a`
     * @param a The accumulator to subtract from
     * @param b The accumulator to subtract
     * @return The resulting subtracted accumulator
     */
    function sub(Accumulator memory a, Accumulator memory b) internal pure returns (Accumulator memory) {
        return Accumulator({maker: a.maker.sub(b.maker), taker: a.taker.sub(b.taker)});
    }

    /**
     * @notice Multiplies two accumulators together
     * @param a The first accumulator to multiply
     * @param b The second accumulator to multiply
     * @return The resulting multiplied accumulator
     */
    function mul(Accumulator memory a, Accumulator memory b) internal pure returns (Accumulator memory) {
        return Accumulator({maker: a.maker.mul(b.maker), taker: a.taker.mul(b.taker)});
    }

    /**
     * @notice Sums the maker and taker together from a single accumulator
     * @param self The struct to operate on
     * @return The sum of its maker and taker
     */
    function sum(Accumulator memory self) internal pure returns (Fixed18) {
        return self.maker.add(self.taker);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/PackedFixed18.sol";
import "./Accumulator.sol";

/// @dev PackedAccumulator type
struct PackedAccumulator {
    /// @dev maker accumulator per share
    PackedFixed18 maker;
    /// @dev taker accumulator per share
    PackedFixed18 taker;
}
using PackedAccumulatorLib for PackedAccumulator global;

/**
 * @title PackedAccumulatorLib
 * @dev A packed version of the Accumulator which takes up a single storage slot using `PackedFixed18` values.
 * @notice Library for the packed Accumulator type.
 */
library PackedAccumulatorLib {
    /**
     * @notice Creates an accumulator from a packed accumulator
     * @param self packed accumulator
     * @return New accumulator
     */
    function unpack(PackedAccumulator memory self) internal pure returns (Accumulator memory) {
        return Accumulator({maker: self.maker.unpack(), taker: self.taker.unpack()});
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/PackedUFixed18.sol";
import "./Position.sol";

/// @dev PackedPosition type
struct PackedPosition {
    /// @dev Quantity of the maker position
    PackedUFixed18 maker;
    /// @dev Quantity of the taker position
    PackedUFixed18 taker;
}
using PackedPositionLib for PackedPosition global;

/**
 * @title PackedPositionLib
 * @dev A packed version of the Position which takes up a single storage slot using `PackedFixed18` values.
 * @notice Library for the packed Position type.
 */
library PackedPositionLib {
    /**
     * @notice Creates an position from a packed position
     * @param self packed position
     * @return New position
     */
    function unpack(PackedPosition memory self) internal pure returns (Position memory) {
        return Position({maker: self.maker.unpack(), taker: self.taker.unpack()});
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@equilibria/root/number/types/UFixed18.sol";
import "./Accumulator.sol";
import "./PrePosition.sol";
import "./PackedPosition.sol";

/// @dev Position type
struct Position {
    /// @dev Quantity of the maker position
    UFixed18 maker;
    /// @dev Quantity of the taker position
    UFixed18 taker;
}
using PositionLib for Position global;

/**
 * @title PositionLib
 * @notice Library that surfaces math and settlement computations for the Position type.
 * @dev Positions track the current quantity of the account's maker and taker positions respectively
 *      denominated as a unit of the product's payoff function.
 */
library PositionLib {
    /**
     * @notice Creates a packed position from an position
     * @param self A position
     * @return New packed position
     */
    function pack(Position memory self) internal pure returns (PackedPosition memory) {
        return PackedPosition({maker: self.maker.pack(), taker: self.taker.pack()});
    }

    /**
     * @notice Returns whether the position is fully empty
     * @param self A position
     * @return Whether the position is empty
     */
    function isEmpty(Position memory self) internal pure returns (bool) {
        return self.maker.isZero() && self.taker.isZero();
    }

    /**
     * @notice Adds position `a` and `b` together, returning the result
     * @param a The first position to sum
     * @param b The second position to sum
     * @return Resulting summed position
     */
    function add(Position memory a, Position memory b) internal pure returns (Position memory) {
        return Position({maker: a.maker.add(b.maker), taker: a.taker.add(b.taker)});
    }

    /**
     * @notice Subtracts position `b` from `a`, returning the result
     * @param a The position to subtract from
     * @param b The position to subtract
     * @return Resulting subtracted position
     */
    function sub(Position memory a, Position memory b) internal pure returns (Position memory) {
        return Position({maker: a.maker.sub(b.maker), taker: a.taker.sub(b.taker)});
    }

    /**
     * @notice Multiplies position `self` by accumulator `accumulator` and returns the resulting accumulator
     * @param self The Position to operate on
     * @param accumulator The accumulator to multiply by
     * @return Resulting multiplied accumulator
     */
    function mul(Position memory self, Accumulator memory accumulator) internal pure returns (Accumulator memory) {
        return Accumulator({
            maker: Fixed18Lib.from(self.maker).mul(accumulator.maker),
            taker: Fixed18Lib.from(self.taker).mul(accumulator.taker)
        });
    }

    /**
     * @notice Scales position `self` by fixed-decimal `scale` and returns the resulting position
     * @param self The Position to operate on
     * @param scale The Fixed-decimal to scale by
     * @return Resulting scaled position
     */
    function mul(Position memory self, UFixed18 scale) internal pure returns (Position memory) {
        return Position({maker: self.maker.mul(scale), taker: self.taker.mul(scale)});
    }

    /**
     * @notice Divides position `self` by `b` and returns the resulting accumulator
     * @param self The Position to operate on
     * @param b The number to divide by
     * @return Resulting divided accumulator
     */
    function div(Position memory self, uint256 b) internal pure returns (Accumulator memory) {
        return Accumulator({
            maker: Fixed18Lib.from(self.maker).div(Fixed18Lib.from(UFixed18Lib.from(b))),
            taker: Fixed18Lib.from(self.taker).div(Fixed18Lib.from(UFixed18Lib.from(b)))
        });
    }

    /**
     * @notice Returns the maximum of `self`'s maker and taker values
     * @param self The struct to operate on
     * @return Resulting maximum value
     */
    function max(Position memory self) internal pure returns (UFixed18) {
        return UFixed18Lib.max(self.maker, self.taker);
    }

    /**
     * @notice Sums the maker and taker together from a single position
     * @param self The struct to operate on
     * @return The sum of its maker and taker
     */
    function sum(Position memory self) internal pure returns (UFixed18) {
        return self.maker.add(self.taker);
    }

    /**
     * @notice Computes the next position after the pending-settlement position delta is included
     * @param self The current Position
     * @param pre The pending-settlement position delta
     * @return Next Position
     */
    function next(Position memory self, PrePosition memory pre) internal pure returns (Position memory) {
        return sub(add(self, pre.openPosition), pre.closePosition);
    }

    /**
     * @notice Returns the settled position at oracle version `toOracleVersion`
     * @dev Checks if a new position is ready to be settled based on the provided `toOracleVersion`
     *      and `pre` and returns accordingly
     * @param self The current Position
     * @param pre The pending-settlement position delta
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to settle to
     * @return Settled position at oracle version
     * @return Fee accrued from opening or closing the position
     * @return Whether a new position was settled
     */
    function settled(
        Position memory self,
        PrePosition memory pre,
        IProductProvider provider,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) internal view returns (Position memory, UFixed18, bool) {
        return pre.canSettle(toOracleVersion) ? (next(self, pre), pre.computeFee(provider, toOracleVersion), true) : (self, UFixed18Lib.ZERO, false);
    }

    /**
     * @notice Returns the socialization factor for the current position
     * @dev Socialization account for the case where `taker` > `maker` temporarily due to a liquidation
     *      on the maker side. This dampens the taker's exposure pro-rata to ensure that the maker side
     *      is never exposed over 1 x short.
     * @param self The Position to operate on
     * @return Socialization factor
     */
    function socializationFactor(Position memory self) internal pure returns (UFixed18) {
        return self.taker.isZero() ? UFixed18Lib.ONE : UFixed18Lib.min(UFixed18Lib.ONE, self.maker.div(self.taker));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./Position.sol";
import "./ProductProvider.sol";

/// @dev PrePosition type
struct PrePosition {
    /// @dev Oracle version at which the new position delta was recorded
    uint256 oracleVersion;

    /// @dev Size of position to open at oracle version
    Position openPosition;

    /// @dev Size of position to close at oracle version
    Position closePosition;
}
using PrePositionLib for PrePosition global;

/**
 * @title PrePositionLib
 * @notice Library that manages a pre-settlement position delta.
 * @dev PrePositions track the currently awaiting-settlement deltas to a settled Position. These are
 *      Primarily necessary to introduce lag into the settlement system such that oracle lag cannot be
 *      gamed to a user's advantage. When a user opens or closes a new position, it sits as a PrePosition
 *      for one oracle version until it's settle into the Position, making it then effective. PrePositions
 *      are automatically settled at the correct oracle version even if a flywheel call doesn't happen until
 *      several version into the future by using the historical version lookups in the corresponding "Versioned"
 *      global state types.
 */
library PrePositionLib {
    using ProductProviderLib for IProductProvider;

    /**
     * @notice Returns whether there is no pending-settlement position delta
     * @dev Can be "empty" even with a non-zero oracleVersion if a position is opened and
     *      closed in the same version netting out to a zero position delta
     * @param self The struct to operate on
     * @return Whether the pending-settlement position delta is empty
     */
    function isEmpty(PrePosition memory self) internal pure returns (bool) {
        return self.openPosition.isEmpty() && self.closePosition.isEmpty();
    }

    /**
     * @notice Increments the maker side of the open position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The position amount to open
     */
    function openMake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.openPosition.maker = self.openPosition.maker.add(amount);
        self.oracleVersion = currentVersion;
        _netMake(self);
    }

    /**
     * @notice Increments the maker side of the close position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The maker position amount to close
     */
    function closeMake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.closePosition.maker = self.closePosition.maker.add(amount);
        self.oracleVersion = currentVersion;
        _netMake(self);
    }

    /**
     * @notice Increments the taker side of the open position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The taker position amount to open
     */
    function openTake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.openPosition.taker = self.openPosition.taker.add(amount);
        self.oracleVersion = currentVersion;
        _netTake(self);
    }

    /**
     * @notice Increments the taker side of the close position delta
     * @dev Nets out open and close deltas to minimize the size of each
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @param amount The taker position amount to close
     */
    function closeTake(PrePosition storage self, uint256 currentVersion, UFixed18 amount) internal {
        self.closePosition.taker = self.closePosition.taker.add(amount);
        self.oracleVersion = currentVersion;
        _netTake(self);
    }

    /**
     * @notice Nets out the open and close on the maker side of the position delta
     * @param self The struct to operate on
     */
    function _netMake(PrePosition storage self) private {
        if (self.openPosition.maker.gt(self.closePosition.maker)) {
            self.openPosition.maker = self.openPosition.maker.sub(self.closePosition.maker);
            self.closePosition.maker = UFixed18Lib.ZERO;
        } else {
            self.closePosition.maker = self.closePosition.maker.sub(self.openPosition.maker);
            self.openPosition.maker = UFixed18Lib.ZERO;
        }
    }

    /**
     * @notice Nets out the open and close on the taker side of the position delta
     * @param self The struct to operate on
     */
    function _netTake(PrePosition storage self) private {
        if (self.openPosition.taker.gt(self.closePosition.taker)) {
            self.openPosition.taker = self.openPosition.taker.sub(self.closePosition.taker);
            self.closePosition.taker = UFixed18Lib.ZERO;
        } else {
            self.closePosition.taker = self.closePosition.taker.sub(self.openPosition.taker);
            self.openPosition.taker = UFixed18Lib.ZERO;
        }
    }

    /**
     * @notice Returns whether the the pending position delta can be settled at version `toOracleVersion`
     * @dev Pending-settlement positions deltas can be settled (1) oracle version after they are recorded
     * @param self The struct to operate on
     * @param toOracleVersion The potential oracle version to settle
     * @return Whether the position delta can be settled
     */
    function canSettle(
        PrePosition memory self,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) internal pure returns (bool) {
        return !isEmpty(self) && toOracleVersion.version > self.oracleVersion;
    }

    /**
     * @notice Computes the fee incurred for opening or closing the pending-settlement position
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version at which settlement takes place
     * @return positionFee The maker / taker fee incurred
     */
    function computeFee(
        PrePosition memory self,
        IProductProvider provider,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) internal view returns (UFixed18) {
        Position memory positionDelta = self.openPosition.add(self.closePosition);

        (UFixed18 makerNotional, UFixed18 takerNotional) = (
            Fixed18Lib.from(positionDelta.maker).mul(toOracleVersion.price).abs(),
            Fixed18Lib.from(positionDelta.taker).mul(toOracleVersion.price).abs()
        );

        return makerNotional.mul(provider.safeMakerFee()).add(takerNotional.mul(provider.safeTakerFee()));
    }

    /**
     * @notice Computes the next oracle version to settle
     * @dev - If there is no pending-settlement position delta, returns the current oracle version
     *      - Otherwise returns the oracle version at which the pending-settlement position delta can be first settled
     *
     *      Corresponds to point (b) in the Position settlement flow
     * @param self The struct to operate on
     * @param currentVersion The current oracle version index
     * @return Next oracle version to settle
     */
    function settleVersion(PrePosition storage self, uint256 currentVersion) internal view returns (uint256) {
        uint256 _oracleVersion = self.oracleVersion;
        return _oracleVersion == 0 ? currentVersion : _oracleVersion + 1;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "../IProductProvider.sol";
import "../IController.sol";

/**
 * @title ProductProviderLib
 * @notice Library that adds a safeguard wrapper to certain product parameters.
 * @dev Product providers are semi-untrusted as they contain custom code from the product owners. Owners
 *      have full control over this parameter-setting code, however there are some "known ranges" that
 *      a parameter cannot be outside of (i.e. a fee being over 100%).
 */
library ProductProviderLib {
    /**
     * @notice Returns the minimum funding fee parameter with a capped range for safety
     * @dev Caps controller.minFundingFee() <= self.minFundingFee() <= 1
     * @param self The parameter provider to operate on
     * @param controller The protocol Factory contract
     * @return Safe minimum funding fee parameter
     */
    function safeFundingFee(IProductProvider self, IController controller) internal view returns (UFixed18) {
        return self.fundingFee().max(controller.minFundingFee()).min(UFixed18Lib.ONE);
    }

    /**
     * @notice Returns the maker fee parameter with a capped range for safety
     * @dev Caps self.makerFee() <= 1
     * @param self The parameter provider to operate on
     * @return Safe maker fee parameter
     */
    function safeMakerFee(IProductProvider self) internal view returns (UFixed18) {
        return self.makerFee().min(UFixed18Lib.ONE);
    }

    /**
     * @notice Returns the taker fee parameter with a capped range for safety
     * @dev Caps self.takerFee() <= 1
     * @param self The parameter provider to operate on
     * @return Safe taker fee parameter
     */
    function safeTakerFee(IProductProvider self) internal view returns (UFixed18) {
        return self.takerFee().min(UFixed18Lib.ONE);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/token/types/Token18.sol";
import "../IProduct.sol";
import "./Position.sol";
import "./Accumulator.sol";

/// @dev ProgramInfo type
struct ProgramInfo {
    /// @dev Coordinator for this program
    uint256 coordinatorId;

    /// @dev Amount of total maker and taker rewards
    Position amount;

    /// @dev start timestamp of the program
    uint256 start;

    /// @dev duration of the program (in seconds)
    uint256 duration;

    /// @dev Reward ERC20 token contract
    Token18 token;
}
using ProgramInfoLib for ProgramInfo global;

/**
 * @title ProgramInfoLib
 * @notice Library that snapshots the static information for a single program.
 * @dev This information does not change during the operation of a program.
 */
library ProgramInfoLib {
    uint256 private constant MIN_DURATION = 1 days;
    uint256 private constant MAX_DURATION = 2 * 365 days;

    error ProgramInvalidStartError();
    error ProgramInvalidDurationError();

    /**
     * @notice Validates and creates a new Program
     * @dev Reverts for invalid programInfos
     * @param programInfo Un-sanitized static program information
     */
    function validate(ProgramInfo memory programInfo) internal view {
        if (isStarted(programInfo, block.timestamp)) revert ProgramInvalidStartError();
        if (programInfo.duration < MIN_DURATION || programInfo.duration > MAX_DURATION) revert ProgramInvalidDurationError();
    }

    /**
     * @notice Computes a new program info with the fee taken out of the amount
     * @param programInfo Original program info
     * @param incentivizationFee The incentivization fee
     * @return New program info
     * @return Fee amount
     */
    function deductFee(ProgramInfo memory programInfo, UFixed18 incentivizationFee)
    internal pure returns (ProgramInfo memory, UFixed18) {
        Position memory newProgramAmount = programInfo.amount.mul(UFixed18Lib.ONE.sub(incentivizationFee));
        UFixed18 programFeeAmount = programInfo.amount.sub(newProgramAmount).sum();
        programInfo.amount = newProgramAmount;
        return (programInfo, programFeeAmount);
    }

    /**
     * @notice Returns the maker and taker amounts per position share
     * @param self The ProgramInfo to operate on
     * @return programFee Amounts per share
     */
    function amountPerShare(ProgramInfo memory self) internal pure returns (Accumulator memory) {
        return self.amount.div(self.duration);
    }

    /**
     * @notice Returns whether the program has started by timestamp `timestamp`
     * @param self The ProgramInfo to operate on
     * @param timestamp Timestamp to check for
     * @return Whether the program has started
     */
    function isStarted(ProgramInfo memory self, uint256 timestamp) internal pure returns (bool) {
        return timestamp >= self.start;
    }

    /**
     * @notice Returns whether the program is completed by timestamp `timestamp`
     * @param self The ProgramInfo to operate on
     * @param timestamp Timestamp to check for
     * @return Whether the program is completed
     */
    function isComplete(ProgramInfo memory self, uint256 timestamp) internal pure returns (bool) {
        return timestamp >= (self.start + self.duration);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@equilibria/root/control/unstructured/UInitializable.sol";
import "@equilibria/root/control/unstructured/UReentrancyGuard.sol";
import "./types/position/AccountPosition.sol";
import "./types/accumulator/AccountAccumulator.sol";
import "../controller/UControllerProvider.sol";

/**
 * @title Product
 * @notice Manages logic and state for a single product market.
 * @dev Cloned by the Controller contract to launch new product markets.
 */
contract Product is IProduct, UInitializable, UControllerProvider, UReentrancyGuard {
    /// @dev The parameter provider of the product market
    IProductProvider public productProvider;

    /// @dev The individual position state for each account
    mapping(address => AccountPosition) private _positions;

    /// @dev The global position state for the product
    VersionedPosition private _position;

    /// @dev The individual accumulator state for each account
    mapping(address => AccountAccumulator) private _accumulators;

    /// @dev The global accumulator state for the product
    VersionedAccumulator private _accumulator;

    /**
     * @notice Initializes the contract state
     * @param productProvider_ Product provider contract address
     */
    function initialize(IProductProvider productProvider_) external initializer(1) {
        __UControllerProvider__initialize(IController(msg.sender));
        __UReentrancyGuard__initialize();

        productProvider = productProvider_;
    }

    /**
     * @notice Surfaces global settlement externally
     */
    function settle() external nonReentrant notPausedProduct(IProduct(this)) {
        settleInternal();
    }

    /**
     * @notice Core global settlement flywheel
     * @dev
     *  a) last settle oracle version
     *  b) latest pre position oracle version
     *  c) current oracle version
     *
     *  Settles from a->b then from b->c if either interval is non-zero to account for a change
     *  in position quantity at (b).
     *
     *  Syncs each to instantaneously after the oracle update.
     */
    function settleInternal() internal returns (IOracleProvider.OracleVersion memory currentOracleVersion) {
        (IProductProvider _provider, IController _controller) = (productProvider, controller());

        // Get current oracle version
        currentOracleVersion = _provider.sync();

        // Get latest oracle version
        uint256 _latestVersion = latestVersion();
        if (_latestVersion == currentOracleVersion.version) return currentOracleVersion; // short circuit entirely if a == c
        IOracleProvider.OracleVersion memory latestOracleVersion = _provider.atVersion(_latestVersion);

        // Get settle oracle version
        uint256 _settleVersion = _position.pre.settleVersion(currentOracleVersion.version);
        IOracleProvider.OracleVersion memory settleOracleVersion = _settleVersion == currentOracleVersion.version ?
            currentOracleVersion : // if b == c, don't re-call provider for oracle version
            _provider.atVersion(_settleVersion);

        // Initiate
        _controller.incentivizer().sync(currentOracleVersion);
        UFixed18 accumulatedFee;

        // value a->b
        accumulatedFee = accumulatedFee.add(_accumulator.accumulate(_controller, _provider, _position, latestOracleVersion, settleOracleVersion));

        // position a->b
        accumulatedFee = accumulatedFee.add(_position.settle(_provider, _latestVersion, settleOracleVersion));

        // short-circuit from a->c if b == c
        if (settleOracleVersion.version != currentOracleVersion.version) {

            // value b->c
            accumulatedFee = accumulatedFee.add(_accumulator.accumulate(_controller, _provider, _position, settleOracleVersion, currentOracleVersion));

            // position b->c (every accumulator version needs a position stamp)
            _position.settle(_provider, settleOracleVersion.version, currentOracleVersion);
        }

        // settle collateral
        _controller.collateral().settleProduct(accumulatedFee);

        emit Settle(settleOracleVersion.version, currentOracleVersion.version);
    }

    /**
     * @notice Surfaces account settlement externally
     * @param account Account to settle
     */
    function settleAccount(address account) external nonReentrant notPausedProduct(IProduct(this)) {
        IOracleProvider.OracleVersion memory currentOracleVersion = settleInternal();
        settleAccountInternal(account, currentOracleVersion);
    }

    /**
     * @notice Core account settlement flywheel
     * @param account Account to settle
     * @dev
     *  a) last settle oracle version
     *  b) latest pre position oracle version
     *  c) current oracle version
     *
     *  Settles from a->b then from b->c if either interval is non-zero to account for a change
     *  in position quantity at (b).
     *
     *  Syncs each to instantaneously after the oracle update.
     */
    function settleAccountInternal(address account, IOracleProvider.OracleVersion memory currentOracleVersion) internal {
        (IProductProvider _provider, IController _controller) = (productProvider, controller());

        // Get latest oracle version
        if (latestVersion(account) == currentOracleVersion.version) return; // short circuit entirely if a == c

        // Get settle oracle version
        uint256 _settleVersion = _positions[account].pre.settleVersion(currentOracleVersion.version);
        IOracleProvider.OracleVersion memory settleOracleVersion = _settleVersion == currentOracleVersion.version ?
            currentOracleVersion : // if b == c, don't re-call provider for oracle version
            _provider.atVersion(_settleVersion);

        // initialize
        Fixed18 accumulated;

        // sync incentivizer before accumulator
        _controller.incentivizer().syncAccount(account, settleOracleVersion);

        // value a->b
        accumulated = accumulated.add(
            _accumulators[account].syncTo(_accumulator, _positions[account], settleOracleVersion.version).sum());

        // position a->b
        accumulated = accumulated.sub(Fixed18Lib.from(_positions[account].settle(_provider, settleOracleVersion)));

        // short-circuit if a->c
        if (settleOracleVersion.version != currentOracleVersion.version) {
            // sync incentivizer before accumulator
            _controller.incentivizer().syncAccount(account, currentOracleVersion);

            // value b->c
            accumulated = accumulated.add(
                _accumulators[account].syncTo(_accumulator, _positions[account], currentOracleVersion.version).sum());
        }

        // settle collateral
        _controller.collateral().settleAccount(account, accumulated);

        emit AccountSettle(account, settleOracleVersion.version, currentOracleVersion.version);
    }

    /**
     * @notice Opens a taker position for `msg.sender`
     * @param amount Amount of the position to open
     */
    function openTake(UFixed18 amount)
    external
    nonReentrant
    notPausedProduct(IProduct(this))
    settleForAccount(msg.sender)
    takerInvariant
    positionInvariant
    liquidationInvariant
    maintenanceInvariant
    {
        uint256 _latestVersion = latestVersion();

        _positions[msg.sender].pre.openTake(_latestVersion, amount);
        _position.pre.openTake(_latestVersion, amount);

        emit TakeOpened(msg.sender, _latestVersion, amount);
    }

    /**
     * @notice Closes a taker position for `msg.sender`
     * @param amount Amount of the position to close
     */
    function closeTake(UFixed18 amount)
    external
    nonReentrant
    notPausedProduct(IProduct(this))
    settleForAccount(msg.sender)
    closeInvariant
    liquidationInvariant
    {
        closeTakeInternal(msg.sender, amount);
    }

    function closeTakeInternal(address account, UFixed18 amount) internal {
        uint256 _latestVersion = latestVersion();

        _positions[account].pre.closeTake(_latestVersion, amount);
        _position.pre.closeTake(_latestVersion, amount);

        emit TakeClosed(account, _latestVersion, amount);
    }

    /**
     * @notice Opens a maker position for `msg.sender`
     * @param amount Amount of the position to open
     */
    function openMake(UFixed18 amount)
    external
    nonReentrant
    notPausedProduct(IProduct(this))
    settleForAccount(msg.sender)
    nonZeroVersionInvariant
    makerInvariant
    positionInvariant
    liquidationInvariant
    maintenanceInvariant
    {
        uint256 _latestVersion = latestVersion();

        _positions[msg.sender].pre.openMake(_latestVersion, amount);
        _position.pre.openMake(_latestVersion, amount);

        emit MakeOpened(msg.sender, _latestVersion, amount);
    }

    /**
     * @notice Closes a maker position for `msg.sender`
     * @param amount Amount of the position to close
     */
    function closeMake(UFixed18 amount)
    external
    nonReentrant
    notPausedProduct(IProduct(this))
    settleForAccount(msg.sender)
    takerInvariant
    closeInvariant
    liquidationInvariant
    {
        closeMakeInternal(msg.sender, amount);
    }

    function closeMakeInternal(address account, UFixed18 amount) internal {
        uint256 _latestVersion = latestVersion();

        _positions[account].pre.closeMake(_latestVersion, amount);
        _position.pre.closeMake(_latestVersion, amount);

        emit MakeClosed(account, _latestVersion, amount);
    }

    /**
     * @notice Closes all open and pending positions, locking for liquidation
     * @dev Only callable by the Collateral contract as part of the liquidation flow
     * @param account Account to close out
     */
    function closeAll(address account) external onlyCollateral settleForAccount(account) {
        AccountPosition storage accountPosition = _positions[account];
        Position memory p = accountPosition.position.next(_positions[account].pre);

        // Close all positions
        closeMakeInternal(account, p.maker);
        closeTakeInternal(account, p.taker);

        // Mark liquidation to lock position
        accountPosition.liquidation = true;
    }

    /**
     * @notice Returns the maintenance requirement for `account`
     * @param account Account to return for
     * @return The current maintenance requirement
     */
    function maintenance(address account) external view returns (UFixed18) {
        return _positions[account].maintenance(productProvider);
    }

    /**
     * @notice Returns the maintenance requirement for `account` after next settlement
     * @dev Assumes no price change and no funding, used to protect user from over-opening
     * @param account Account to return for
     * @return The next maintenance requirement
     */
    function maintenanceNext(address account) external view returns (UFixed18) {
        return _positions[account].maintenanceNext(productProvider);
    }

    /**
     * @notice Returns whether `account` has a completely zero'd position
     * @param account Account to return for
     * @return The the account is closed
     */
    function isClosed(address account) external view returns (bool) {
        return _positions[account].isClosed();
    }

    /**
     * @notice Returns whether `account` is currently locked for an in-progress liquidation
     * @param account Account to return for
     * @return Whether the account is in liquidation
     */
    function isLiquidating(address account) external view returns (bool) {
        return _positions[account].liquidation;
    }

    /**
     * @notice Returns `account`'s current position
     * @param account Account to return for
     * @return Current position of the account
     */
    function position(address account) external view returns (Position memory) {
        return _positions[account].position;
    }

    /**
     * @notice Returns `account`'s current pending-settlement position
     * @param account Account to return for
     * @return Current pre-position of the account
     */
    function pre(address account) external view returns (PrePosition memory) {
        return _positions[account].pre;
    }

    /**
     * @notice Returns the global latest settled oracle version
     * @return Latest settled oracle version of the product
     */
    function latestVersion() public view returns (uint256) {
        return _accumulator.latestVersion;
    }

    /**
     * @notice Returns the global position at oracleVersion `oracleVersion`
     * @dev Only valid for the version at which a global settlement occurred
     * @param oracleVersion Oracle version to return for
     * @return Global position at oracle version
     */
    function positionAtVersion(uint256 oracleVersion) public view returns (Position memory) {
        return _position.positionAtVersion(oracleVersion);
    }

    /**
     * @notice Returns the current global pending-settlement position
     * @return Global pending-settlement position
     */
    function pre() external view returns (PrePosition memory) {
        return _position.pre;
    }

    /**
     * @notice Returns the global accumulator value at oracleVersion `oracleVersion`
     * @dev Only valid for the version at which a global settlement occurred
     * @param oracleVersion Oracle version to return for
     * @return Global accumulator value at oracle version
     */
    function valueAtVersion(uint256 oracleVersion) external view returns (Accumulator memory) {
        return _accumulator.valueAtVersion(oracleVersion);
    }

    /**
     * @notice Returns the global accumulator share at oracleVersion `oracleVersion`
     * @dev Only valid for the version at which a global settlement occurred
     * @param oracleVersion Oracle version to return for
     * @return Global accumulator share at oracle version
     */
    function shareAtVersion(uint256 oracleVersion) external view returns (Accumulator memory) {
        return _accumulator.shareAtVersion(oracleVersion);
    }

    /**
     * @notice Returns `account`'s latest settled oracle version
     * @param account Account to return for
     * @return Latest settled oracle version of the account
     */
    function latestVersion(address account) public view returns (uint256) {
        return _accumulators[account].latestVersion;
    }

    /// @dev Limit total maker for guarded rollouts
    modifier makerInvariant {
        _;

        Position memory next = positionAtVersion(latestVersion()).next(_position.pre);

        if (next.maker.gt(productProvider.makerLimit())) revert ProductMakerOverLimitError();
    }

    /// @dev Limit maker short exposure to the range 0.0-1.0x of their position
    modifier takerInvariant {
        _;

        Position memory next = positionAtVersion(latestVersion()).next(_position.pre);
        UFixed18 socializationFactor = next.socializationFactor();

        if (socializationFactor.lt(UFixed18Lib.ONE)) revert ProductInsufficientLiquidityError(socializationFactor);
    }

    /// @dev Ensure that the user has only taken a maker or taker position, but not both
    modifier positionInvariant {
        _;

        if (_positions[msg.sender].isDoubleSided()) revert ProductDoubleSidedError();
    }

    /// @dev Ensure that the user hasn't closed more than is open
    modifier closeInvariant {
        _;

        if (_positions[msg.sender].isOverClosed()) revert ProductOverClosedError();
    }

    /// @dev Ensure that the user will have sufficient margin for maintenance after next settlement
    modifier maintenanceInvariant {
        _;

        if (controller().collateral().liquidatableNext(msg.sender, IProduct(this)))
            revert ProductInsufficientCollateralError();
    }

    /// @dev Ensure that the user is not currently being liquidated
    modifier liquidationInvariant {
        if (_positions[msg.sender].liquidation) revert ProductInLiquidationError();

        _;
    }

    /// @dev Helper to fully settle an account's state
    modifier settleForAccount(address account) {
        IOracleProvider.OracleVersion memory currentVersion = settleInternal();
        settleAccountInternal(account, currentVersion);

        _;
    }

    /// @dev Ensure we have bootstraped the oracle before creating positions
    modifier nonZeroVersionInvariant {
        if (latestVersion() == 0) revert ProductOracleBootstrappingError();

        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "../../../interfaces/types/Accumulator.sol";
import "../position/AccountPosition.sol";
import "./VersionedAccumulator.sol";

/// @dev AccountAccumulator type
struct AccountAccumulator {
    /// @dev latest version that the account was synced too
    uint256 latestVersion;
}
using AccountAccumulatorLib for AccountAccumulator global;

/**
 * @title AccountAccumulatorLib
 * @notice Library that manages syncing an account-level accumulator.
 */
library AccountAccumulatorLib {
    /**
     * @notice Syncs the account to oracle version `versionTo`
     * @param self The struct to operate on
     * @param global Pointer to global accumulator
     * @param position Pointer to global position
     * @param versionTo Oracle version to sync account to
     * @return value The value accumulated sync last sync
     */
    function syncTo(
        AccountAccumulator storage self,
        VersionedAccumulator storage global,
        AccountPosition storage position,
        uint256 versionTo
    ) internal returns (Accumulator memory value) {
        Accumulator memory valueAccumulated = global.valueAtVersion(versionTo)
            .sub(global.valueAtVersion(self.latestVersion));
        value = position.position.mul(valueAccumulated);
        self.latestVersion = versionTo;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "../../../interfaces/types/Accumulator.sol";
import "../../../interfaces/types/ProductProvider.sol";
import "../position/VersionedPosition.sol";

/// @dev VersionedAccumulator type
struct VersionedAccumulator {
    /// @dev Latest synced oracle version
    uint256 latestVersion;

    /// @dev Mapping of accumulator value at each settled oracle version
    mapping(uint256 => PackedAccumulator) _valueAtVersion;

    /// @dev Mapping of accumulator share at each settled oracle version
    mapping(uint256 => PackedAccumulator) _shareAtVersion;
}
using VersionedAccumulatorLib for VersionedAccumulator global;

/**
 * @title VersionedAccumulatorLib
 * @notice Library that manages global versioned accumulator state.
 * @dev Manages two accumulators: value and share. The value accumulator measures the change in position value
 *      over time. The share accumulator measures the change in liquidity ownership over time (for tracking
 *      incentivization rewards).
 *
 *      Both accumulators are stamped for historical lookup anytime there is a global settlement, which services
 *      the delayed-position accounting. It is not guaranteed that every version will have a value stamped, but
 *      only versions when a settlement occurred are needed for this historical computation.
 */
library VersionedAccumulatorLib {
    using ProductProviderLib for IProductProvider;

    /**
     * @notice Returns the stamped value accumulator at `oracleVersion`
     * @param self The struct to operate on
     * @param oracleVersion The oracle version to retrieve the value at
     * @return The stamped value accumulator at the requested version
     */
    function valueAtVersion(VersionedAccumulator storage self, uint256 oracleVersion) internal view returns (Accumulator memory) {
        return self._valueAtVersion[oracleVersion].unpack();
    }

    /**
     * @notice Returns the stamped share accumulator at `oracleVersion`
     * @param self The struct to operate on
     * @param oracleVersion The oracle version to retrieve the share at
     * @return The stamped share accumulator at the requested version
     */
    function shareAtVersion(VersionedAccumulator storage self, uint256 oracleVersion) internal view returns (Accumulator memory) {
        return self._shareAtVersion[oracleVersion].unpack();
    }

    /**
     * @notice Globally accumulates all value (position + funding) and share since last oracle update
     * @param self The struct to operate on
     * @param controller The Controller contract of the protocol
     * @param provider The parameter provider of the product
     * @param position Pointer to global position
     * @param latestOracleVersion The oracle version to accumulate from
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedFee The total fee accrued from accumulation
     */
    function accumulate(
        VersionedAccumulator storage self,
        IController controller,
        IProductProvider provider,
        VersionedPosition storage position,
        IOracleProvider.OracleVersion memory latestOracleVersion,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) internal returns (UFixed18 accumulatedFee) {
        Position memory latestPosition = position.positionAtVersion(latestOracleVersion.version);

        // accumulate funding
        Accumulator memory accumulatedPosition;
        (accumulatedPosition, accumulatedFee) =
            _accumulateFunding(controller, provider, latestPosition, latestOracleVersion, toOracleVersion);

        // accumulate position
        accumulatedPosition = accumulatedPosition.add(
            _accumulatePosition(latestPosition, latestOracleVersion, toOracleVersion));

        // accumulate share
        Accumulator memory accumulatedShare =
            _accumulateShare(latestPosition, latestOracleVersion, toOracleVersion);

        // save update
        self._valueAtVersion[toOracleVersion.version] = valueAtVersion(self, latestOracleVersion.version)
            .add(accumulatedPosition)
            .pack();
        self._shareAtVersion[toOracleVersion.version] = shareAtVersion(self, latestOracleVersion.version)
            .add(accumulatedShare)
            .pack();
        self.latestVersion = toOracleVersion.version;
    }

    /**
     * @notice Globally accumulates all funding since last oracle update
     * @dev If an oracle version is skipped due to no pre positions, funding will continue to be
     *      pegged to the price of the last snapshotted oracleVersion until a new one is accumulated.
     *      This is an acceptable approximation.
     * @param controller The Controller contract of the protocol
     * @param provider The parameter provider of the product
     * @param latestPosition The latest global position
     * @param latestOracleVersion The oracle version to accumulate from
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedFunding The total amount accumulated from funding
     * @return accumulatedFee The total fee accrued from funding accumulation
     */
    function _accumulateFunding(
        IController controller,
        IProductProvider provider,
        Position memory latestPosition,
        IOracleProvider.OracleVersion memory latestOracleVersion,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) private view returns (Accumulator memory accumulatedFunding, UFixed18 accumulatedFee) {
        if (latestPosition.taker.isZero()) return (Accumulator(Fixed18Lib.ZERO, Fixed18Lib.ZERO), UFixed18Lib.ZERO);
        if (latestPosition.maker.isZero()) return (Accumulator(Fixed18Lib.ZERO, Fixed18Lib.ZERO), UFixed18Lib.ZERO);

        uint256 elapsed = toOracleVersion.timestamp - latestOracleVersion.timestamp;

        UFixed18 takerNotional = Fixed18Lib.from(latestPosition.taker).mul(latestOracleVersion.price).abs();
        UFixed18 socializedNotional = takerNotional.mul(latestPosition.socializationFactor());

        Fixed18 rateAccumulated = provider.rate(latestPosition).mul(Fixed18Lib.from(UFixed18Lib.from(elapsed)));
        Fixed18 fundingAccumulated = rateAccumulated.mul(Fixed18Lib.from(socializedNotional));
        accumulatedFee = fundingAccumulated.abs().mul(provider.safeFundingFee(controller));

        Fixed18 fundingIncludingFee = Fixed18Lib.from(
            fundingAccumulated.sign(),
            fundingAccumulated.abs().sub(accumulatedFee)
        );

        accumulatedFunding.maker = fundingIncludingFee.div(Fixed18Lib.from(latestPosition.maker));
        accumulatedFunding.taker = fundingIncludingFee.div(Fixed18Lib.from(latestPosition.taker)).mul(Fixed18Lib.NEG_ONE);
    }

    /**
     * @notice Globally accumulates position PNL since last oracle update
     * @param latestPosition The latest global position
     * @param latestOracleVersion The oracle version to accumulate from
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedPosition The total amount accumulated from position PNL
     */
    function _accumulatePosition(
        Position memory latestPosition,
        IOracleProvider.OracleVersion memory latestOracleVersion,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) private pure returns (Accumulator memory accumulatedPosition) {
        if (latestPosition.taker.isZero()) return Accumulator(Fixed18Lib.ZERO, Fixed18Lib.ZERO);
        if (latestPosition.maker.isZero()) return Accumulator(Fixed18Lib.ZERO, Fixed18Lib.ZERO);

        Fixed18 oracleDelta = toOracleVersion.price.sub(latestOracleVersion.price);
        Fixed18 totalTakerDelta = oracleDelta.mul(Fixed18Lib.from(latestPosition.taker));
        Fixed18 socializedTakerDelta = totalTakerDelta.mul(Fixed18Lib.from(latestPosition.socializationFactor()));

        accumulatedPosition.maker = socializedTakerDelta.div(Fixed18Lib.from(latestPosition.maker)).mul(Fixed18Lib.NEG_ONE);
        accumulatedPosition.taker = socializedTakerDelta.div(Fixed18Lib.from(latestPosition.taker));
    }

    /**
     * @notice Globally accumulates position's share of the total market since last oracle update
     * @dev This is used to compute incentivization rewards based on market participation
     * @param latestPosition The latest global position
     * @param latestOracleVersion The oracle version to accumulate from
     * @param toOracleVersion The oracle version to accumulate to
     * @return accumulatedShare The total share amount accumulated per position
     */
    function _accumulateShare(
        Position memory latestPosition,
        IOracleProvider.OracleVersion memory latestOracleVersion,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) private pure returns (Accumulator memory accumulatedShare) {
        uint256 elapsed = toOracleVersion.timestamp - latestOracleVersion.timestamp;

        accumulatedShare.maker = latestPosition.maker.isZero() ?
            Fixed18Lib.ZERO :
            Fixed18Lib.from(UFixed18Lib.from(elapsed).div(latestPosition.maker));
        accumulatedShare.taker = latestPosition.taker.isZero() ?
            Fixed18Lib.ZERO :
            Fixed18Lib.from(UFixed18Lib.from(elapsed).div(latestPosition.taker));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "../../../interfaces/types/PrePosition.sol";

/// @dev AccountPosition type
struct AccountPosition {
    /// @dev The current settled position of the account
    Position position;

    /// @dev The current position delta pending-settlement
    PrePosition pre;

    /// @dev Whether the account is currently locked for liquidation
    bool liquidation;
}
using AccountPositionLib for AccountPosition global;

/**
 * @title AccountPositionLib
 * @notice Library that manages an account-level position.
 */
library AccountPositionLib {
    /**
     * @notice Settled the account's position to oracle version `toOracleVersion`
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @param toOracleVersion The oracle version to accumulate to
     * @return positionFee The fee accrued from opening or closing a new position
     */
    function settle(
        AccountPosition storage self,
        IProductProvider provider,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) internal returns (UFixed18 positionFee) {
        bool settled;
        (self.position, positionFee, settled) = self.position.settled(self.pre, provider, toOracleVersion);
        if (settled) {
            delete self.pre;
            self.liquidation = false;
        }
    }

    /**
     * @notice Returns the current maintenance requirement for the account
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @return Current maintenance requirement for the account
     */
    function maintenance(AccountPosition storage self, IProductProvider provider) internal view returns (UFixed18) {
        if (self.liquidation) return UFixed18Lib.ZERO;
        return _maintenance(self.position, provider);
    }

    /**
     * @notice Returns the maintenance requirement after the next oracle version settlement
     * @dev Includes the current pending-settlement position delta, assumes no price change
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @return Next maintenance requirement for the account
     */
    function maintenanceNext(AccountPosition storage self, IProductProvider provider) internal view returns (UFixed18) {
        return _maintenance(self.position.next(self.pre), provider);
    }

    /**
     * @notice Returns the maintenance requirement for a given `position`
     * @dev Internal helper
     * @param position The position to compete the maintenance requirement for
     * @param provider The parameter provider of the product
     * @return Next maintenance requirement for the account
     */
    function _maintenance(Position memory position, IProductProvider provider) private view returns (UFixed18) {
        Fixed18 oraclePrice = provider.currentVersion().price;
        UFixed18 notionalMax = Fixed18Lib.from(position.max()).mul(oraclePrice).abs();
        return notionalMax.mul(provider.maintenance());
    }

    /**
     * @notice Returns whether an account is completely closed, i.e. no position or pre-position
     * @param self The struct to operate on
     * @return Whether the account is closed
     */
    function isClosed(AccountPosition memory self) internal pure returns (bool) {
        return self.pre.isEmpty() && self.position.isEmpty();
    }

    /**
     * @notice Returns whether an account has opened position on both sides of the market (maker vs taker)
     * @dev Used to verify the invariant that a single account can only have a position on one side of the
     *      market at a time
     * @param self The struct to operate on
     * @return Whether the account is currently doubled sided
     */
    function isDoubleSided(AccountPosition storage self) internal view returns (bool) {
        bool makerEmpty = self.position.maker.isZero() && self.pre.openPosition.maker.isZero() && self.pre.closePosition.maker.isZero();
        bool takerEmpty = self.position.taker.isZero() && self.pre.openPosition.taker.isZero() && self.pre.closePosition.taker.isZero();

        return !makerEmpty && !takerEmpty;
    }

    /**
     * @notice Returns whether the account's pending-settlement delta closes more position than is open
     * @dev Used to verify the invariant that an account cannot settle into having a negative position
     * @param self The struct to operate on
     * @return Whether the account is currently over closed
     */
    function isOverClosed(AccountPosition storage self) internal view returns (bool) {
        Position memory nextOpen = self.position.add(self.pre.openPosition);

        return  self.pre.closePosition.maker.gt(nextOpen.maker) || self.pre.closePosition.taker.gt(nextOpen.taker);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "../../../interfaces/types/PrePosition.sol";
import "../../../interfaces/types/PackedPosition.sol";

//// @dev VersionedPosition type
struct VersionedPosition {
    /// @dev Mapping of global position at each version
    mapping(uint256 => PackedPosition) _positionAtVersion;

    /// @dev Current global pending-settlement position delta
    PrePosition pre;
}
using VersionedPositionLib for VersionedPosition global;

/**
 * @title VersionedPositionLib
 * @notice Library that manages global position state.
 * @dev Global position state is used to compute utilization rate and socialization, and to account for and
 *      distribute fees globally.
 *
 *      Positions are stamped for historical lookup anytime there is a global settlement, which services
 *      the delayed-position accounting. It is not guaranteed that every version will have a value stamped, but
 *      only versions when a settlement occurred are needed for this historical computation.
 */
library VersionedPositionLib {
    /**
     * @notice Returns the current global position
     * @return Current global position
     */
    function positionAtVersion(VersionedPosition storage self, uint256 oracleVersion) internal view returns (Position memory) {
        return self._positionAtVersion[oracleVersion].unpack();
    }

    /**
     * @notice Settled the global position to oracle version `toOracleVersion`
     * @param self The struct to operate on
     * @param provider The parameter provider of the product
     * @param latestVersion The latest settled oracle version
     * @param toOracleVersion The oracle version to settle to
     * @return positionFee The fee accrued from opening or closing a new position
     */
    function settle(
        VersionedPosition storage self,
        IProductProvider provider,
        uint256 latestVersion,
        IOracleProvider.OracleVersion memory toOracleVersion
    ) internal returns (UFixed18) {
        (Position memory newPosition, UFixed18 positionFee, bool settled) =
            positionAtVersion(self, latestVersion).settled(self.pre, provider, toOracleVersion);

        self._positionAtVersion[toOracleVersion.version] = newPosition.pack();
        if (settled) delete self.pre;

        return positionFee;
    }
}