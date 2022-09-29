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
 * @title UOwnable
 * @notice Library to manage the ownership lifecycle of upgradeable contracts.
 * @dev This contract has been extended from the Open Zeppelin library to include an
 *      unstructured storage pattern so that it can be safely mixed in with upgradeable
 *      contracts without affecting their storage patterns through inheritance.
 */
abstract contract UOwnable is UInitializable {
    event OwnerUpdated(address indexed newOwner);
    event PendingOwnerUpdated(address indexed newPendingOwner);

    error UOwnableNotOwnerError(address sender);
    error UOwnableNotPendingOwnerError(address sender);

    /// @dev The owner address
    AddressStorage private constant _owner = AddressStorage.wrap(keccak256("equilibria.root.UOwnable.owner"));
    function owner() public view returns (address) { return _owner.read(); }

    /// @dev The pending owner address
    AddressStorage private constant _pendingOwner = AddressStorage.wrap(keccak256("equilibria.root.UOwnable.pendingOwner"));
    function pendingOwner() public view returns (address) { return _pendingOwner.read(); }

    /**
     * @notice Initializes the contract setting `msg.sender` as the initial owner
     */
    function __UOwnable__initialize() internal onlyInitializer {
        _updateOwner(msg.sender);
    }

    /**
     * @notice Updates the new pending owner
     * @dev Can only be called by the current owner
     *      New owner does not take affect until that address calls `acceptOwner()`
     * @param newPendingOwner New pending owner address
     */
    function updatePendingOwner(address newPendingOwner) public onlyOwner {
        _pendingOwner.store(newPendingOwner);
        emit PendingOwnerUpdated(newPendingOwner);
    }

    /**
     * @notice Accepts and transfers the ownership of the contract to the pending owner
     * @dev Can only be called by the pending owner to ensure correctness
     */
    function acceptOwner() external {
        if (msg.sender != pendingOwner()) revert UOwnableNotPendingOwnerError(msg.sender);

        _updateOwner(pendingOwner());
        updatePendingOwner(address(0));
    }

    /**
     * @notice Updates the owner address
     * @param newOwner New owner address
     */
    function _updateOwner(address newOwner) private {
        _owner.store(newOwner);
        emit OwnerUpdated(newOwner);
    }

    /// @dev Throws if called by any account other than the owner
    modifier onlyOwner() {
        if (owner() != msg.sender) revert UOwnableNotOwnerError(msg.sender);
        _;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../number/types/UFixed18.sol";

/// @dev Token6
type Token6 is address;
using Token6Lib for Token6 global;
type Token6Storage is bytes32;
using Token6StorageLib for Token6Storage global;

/**
 * @title Token6Lib
 * @notice Library to manage 6-decimal ERC20s that is compliant with the fixed-decimal types.
 * @dev Automatically converts from Base-6 token amounts to Base-18 UFixed18 amounts, with optional rounding
 */
library Token6Lib {
    using SafeERC20 for IERC20;

    Token6 public constant ZERO = Token6.wrap(address(0));

    uint256 private constant OFFSET = 1e12;

    /**
     * @notice Returns whether a token is the zero address
     * @param self Token to check for
     * @return Whether the token is the zero address
     */
    function isZero(Token6 self) internal pure returns (bool) {
        return Token6.unwrap(self) == Token6.unwrap(ZERO);
    }

    /**
     * @notice Returns whether the two tokens are equal
     * @param a First token to compare
     * @param b Second token to compare
     * @return Whether the two tokens are equal
     */
    function eq(Token6 a, Token6 b) internal pure returns (bool) {
        return Token6.unwrap(a) ==  Token6.unwrap(b);
    }

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     */
    function approve(Token6 self, address grantee) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token6 self, address grantee, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, toTokenAmount(amount, false));
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @param self Token to transfer
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function approve(Token6 self, address grantee, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token6 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token6 self, address recipient, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransfer(recipient, toTokenAmount(amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function push(Token6 self, address recipient, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeTransfer(recipient, toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token6 self, address benefactor, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, address(this), toTokenAmount(amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function pull(Token6 self, address benefactor, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, address(this), toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token6 self, address benefactor, address recipient, UFixed18 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, recipient, toTokenAmount(amount, false));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     * @param roundUp Whether to round decimal token amount up to the next unit
     */
    function pullTo(Token6 self, address benefactor, address recipient, UFixed18 amount, bool roundUp) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, recipient, toTokenAmount(amount, roundUp));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token6 self) internal view returns (string memory) {
        return IERC20Metadata(Token6.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token6 self) internal view returns (string memory) {
        return IERC20Metadata(Token6.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token6 self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token6 self, address account) internal view returns (UFixed18) {
        return fromTokenAmount(IERC20(Token6.unwrap(self)).balanceOf(account));
    }

    /**
     * @notice Converts the unsigned fixed-decimal amount into the token amount according to
     *         it's defined decimals
     * @dev Provides the ability to "round up" the token amount which is useful in situations where
     *      are swapping one token for another and don't want to give away "free" units due to rounding
     *      errors in the favor of the user.
     * @param amount Amount to convert
     * @param roundUp Whether to round decimal token amount up to the next unit
     * @return Normalized token amount
     */
    function toTokenAmount(UFixed18 amount, bool roundUp) private pure returns (uint256) {
        return roundUp ? Math.ceilDiv(UFixed18.unwrap(amount), OFFSET) : UFixed18.unwrap(amount) / OFFSET;
    }

    /**
     * @notice Converts the token amount into the unsigned fixed-decimal amount according to
     *         it's defined decimals
     * @param amount Token amount to convert
     * @return Normalized unsigned fixed-decimal amount
     */
    function fromTokenAmount(uint256 amount) private pure returns (UFixed18) {
        return UFixed18.wrap(amount * OFFSET);
    }
}

library Token6StorageLib {
    function read(Token6Storage self) internal view returns (Token6 value) {
        assembly {
            value := sload(self)
        }
    }

    function store(Token6Storage self, Token6 value) internal {
        assembly {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/token/types/Token6.sol";
import "@equilibria/root/control/unstructured/UOwnable.sol";
import "../interfaces/IBatcher.sol";

abstract contract Batcher is IBatcher, UOwnable {
    using UFixed18Lib for UFixed18;
    using Token18Lib for Token18;
    using Token6Lib for Token6;

    IEmptySetReserve public immutable RESERVE;
    Token18 public immutable DSU;
    Token6 public immutable USDC;

    constructor(IEmptySetReserve reserve, Token18 dsu, Token6 usdc) {
        RESERVE = reserve;
        DSU = dsu;
        USDC = usdc;

        DSU.approve(address(RESERVE));
        USDC.approve(address(RESERVE));

        __UOwnable__initialize();
    }

    function totalBalance() public view returns (UFixed18) {
        return DSU.balanceOf().add(USDC.balanceOf());
    }

    function wrap(UFixed18 amount, address to) external {
        _wrap(amount, to);
        emit Wrap(to, amount);
    }

    function _wrap(UFixed18 amount, address to) virtual internal {
        USDC.pull(msg.sender, amount, true);
        DSU.push(to, amount);
    }

    function unwrap(UFixed18 amount, address to) external {
        _unwrap(amount, to);
        emit Unwrap(to, amount);
    }

    function _unwrap(UFixed18 amount, address to) virtual internal {
        DSU.pull(msg.sender, amount);
        USDC.push(to, amount);
    }

    function rebalance() external {
        (UFixed18 usdcBalance, UFixed18 dsuBalance) = (USDC.balanceOf(), DSU.balanceOf());

        _rebalance(USDC.balanceOf(), DSU.balanceOf());

        (UFixed18 oldBalance, UFixed18 newBalance) = (usdcBalance.add(dsuBalance), totalBalance());
        if (!oldBalance.eq(newBalance)) revert BatcherBalanceMismatchError(oldBalance, newBalance);

        emit Rebalance(usdcBalance, UFixed18Lib.ZERO);
    }

    function _rebalance(UFixed18 usdcBalance, UFixed18 dsuBalance) virtual internal;

    function close() external onlyOwner {
        UFixed18 usdcBalance = USDC.balanceOf();
        if (!usdcBalance.isZero()) RESERVE.mint(usdcBalance);

        UFixed18 dsuBalance = DSU.balanceOf();
        UFixed18 repayAmount = UFixed18Lib.min(RESERVE.debt(address(this)), dsuBalance);
        UFixed18 returnAmount = dsuBalance.sub(repayAmount);

        RESERVE.repay(address(this), repayAmount);
        if (!returnAmount.isZero()) DSU.push(address(RESERVE), dsuBalance.sub(repayAmount));

        emit Close(dsuBalance);
    }
}

interface IEmptySetReserve {
    function debt(address borrower) external view returns (UFixed18);
    function repay(address borrower, UFixed18 amount) external;
    function mint(UFixed18 amount) external;
    function redeem(UFixed18 amount) external;
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/token/types/Token6.sol";
import "./Batcher.sol";

contract WrapOnlyBatcher is Batcher {
    using UFixed18Lib for UFixed18;
    using Token18Lib for Token18;
    using Token6Lib for Token6;

    constructor(IEmptySetReserve reserve, Token18 dsu, Token6 usdc)
    Batcher(reserve, dsu, usdc)
    { }

    function _unwrap(UFixed18 amount, address to) override internal {
        revert BatcherNotImplementedError();
    }

    function _rebalance(UFixed18 usdcBalance, UFixed18 dsuBalance) override internal {
        if (usdcBalance.isZero()) return;

        RESERVE.mint(usdcBalance);
    }
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";

interface IBatcher {
    event Wrap(address indexed to, UFixed18 amount);
    event Unwrap(address indexed to, UFixed18 amount);
    event Rebalance(UFixed18 newMinted, UFixed18 newRedeemed);
    event Close(UFixed18 amount);

    error BatcherNotImplementedError();
    error BatcherBalanceMismatchError(UFixed18 oldBalance, UFixed18 newBalance);

    function totalBalance() external view returns (UFixed18);
    function wrap(UFixed18 amount, address to) external;
    function unwrap(UFixed18 amount, address to) external;
    function rebalance() external;
}