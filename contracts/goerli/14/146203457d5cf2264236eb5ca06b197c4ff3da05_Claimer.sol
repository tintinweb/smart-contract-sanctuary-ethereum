// SPDX-License-Identifier: MIT
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
library EnumerableSet {
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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
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
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function values(AddressSet storage set) internal view returns (address[] memory) {
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
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
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
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

/// @dev Will not work with negative bases, only use when x is positive.
function wadPow(int256 x, int256 y) pure returns (int256) {
    // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
    return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

import {wadDiv, wadMul} from "@solmate/src/utils/SignedWadMath.sol";
import {Owned} from "@solmate/src/auth/Owned.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IDNft, Permission} from "../interfaces/IDNft.sol";
import {IClaimer} from "../interfaces/IClaimer.sol";

// Automatically calls `claim` for all dNFTs in the set of Claimers
contract Claimer is IClaimer, Owned {
  using EnumerableSet for EnumerableSet.UintSet;

  int public constant MAX_FEE = 0.1e18; // 1000 bps or 10%

  EnumerableSet.UintSet private claimers; // set of dNFT ids that `claim` is going to be called for

  IDNft  public dNft;
  Config public config;

  modifier onlyNftOwner(uint id) {
    if (dNft.ownerOf(id) != msg.sender) revert NotNFTOwner(id);
    _;
  }

  constructor(IDNft _dnft, Config memory _config) Owned(msg.sender) {
    dNft   = _dnft;
    config = _config;
  }

  function setConfig(Config memory _config) external onlyOwner {
    if (_config.fee <= MAX_FEE) revert InvalidFee(_config.fee);
    config = _config;
    emit ConfigSet(_config);
  }

  // add DNft to set of Claimers
  function add(uint id) external onlyNftOwner(id) { 
    if (claimers.length() >= config.maxClaimers) revert TooManyClaimers();
    if (!_hasPermissions(id))                    revert MissingPermissions();
    if (!claimers.add(id))                       revert IdAlreadyInSet(id);
    emit Added(id);
  }

  // remove DNft from set of Claimers
  function remove(uint id) external onlyNftOwner(id) {
    _remove(id);
  }

  function _remove(uint id) internal {
    if (!claimers.remove(id)) revert IdNotInSet(id);
    emit Removed(id);
  }

  // Claim for all dNFTs in the Claimers set
  function claimAll() external {
    uint[] memory ids = claimers.values();
    for (uint i = 0; i < ids.length; ) {
      uint id = ids[i];
      try dNft.claim(id) returns (int share) { 
        // a fee is only collected if dyad is added to the dNFT deposit
        if (share > 0) {
          int fee = wadMul(share, config.fee);
          if (fee > 0) { 
            try dNft.move(id, config.feeCollector, fee) {} catch { _remove(id); }
          }
        }
      } catch { _remove(id); }
      unchecked { ++i; }
    }
    emit ClaimedAll();
  }

  //Check if the dNFT id is in the set of Claimers
  function contains(uint id) external view returns (bool) {
    return claimers.contains(id);
  }

  function _hasPermissions(uint id) internal view returns (bool) {
    Permission[] memory reqPermissions = new Permission[](2);
    reqPermissions[0] = Permission.CLAIM;
    reqPermissions[1] = Permission.MOVE;
    bool[] memory permissions = dNft.hasPermissions(id, address(this), reqPermissions);
    return (permissions[0] && permissions[1]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

interface IClaimer {

  struct Config {
    int  fee;          // fee collected for every claim. for example 0.1e18 = 10%
    uint feeCollector; // dNFT that gets the fee
    uint maxClaimers;  // maximum number of dNfts that can be claimed for
  }

  event ConfigSet (Config _config);
  event Added     (uint indexed id);
  event Removed   (uint indexed id);
  event ClaimedAll();

  error InvalidFee        (int fee);
  error TooManyClaimers   ();
  error MissingPermissions();
  error NotNFTOwner       (uint id);
  error IdAlreadyInSet    (uint id);
  error IdNotInSet        (uint id);

  /**
   * @notice Set the config
   * @dev Will revert:
   *      - If it is not called by the owner
   *      - If the new fee is higher than the max fee as specified by `MAX_FEE`
   * @dev Emits:
   *      - ConfigSet(Config config)
   * @param config The new config that will replace the current config
   */
  function setConfig(Config memory config) external;

  /**
   * @notice Add dNFT to set of Claimers
   * @dev Will revert:
   *      - If it is not called by the owner of the dNFT
   *      - If the dNFT is already in the set of Claimers
   *      - If the max number of claimers is reached
   *      - If the dNFT is missing the required permissions
   * @dev Emits:
   *      - Added(uint id)
   * @param id The id of the dNFT to add
   */
  function add(uint id) external;

  /**
   * @notice Remove dNFT from set of Claimers
   * @dev Will revert:
   *      - If it is not called by the owner of the dNFT
   *      - If the dNFT is not in the set of Claimers
   * @dev Emits:
   *      - Removed(uint id)
   * @param id The id of the dNFT to remove
   */
  function remove(uint id) external;

  /**
   * @notice Claim for all dNFTs in the Claimers set
   * @dev Emits:
   *      - ClaimedAll()
   * @dev Note: The dNFT will be removed from the set of claimers if the `claim`
   *      or `move` function reverts for it
   */
  function claimAll() external;

  /**
   * @notice Check if the dNFT id is in the set of Claimers
   * @param id The id of the dNFT to check for
   * @return True if the dNFT is in the set of Claimers, false otherwise
   */
  function contains(uint id) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

enum Permission { ACTIVATE, DEACTIVATE, EXCHANGE, DEPOSIT, MOVE, WITHDRAW, REDEEM, CLAIM }

struct PermissionSet {
  address operator;         // The address of the operator
  Permission[] permissions; // The permissions given to the operator
}

interface IDNft {
  struct NftPermission {
    uint8   permissions;
    uint248 lastUpdated; // The block number when it was last updated
  }

  struct Nft {
    uint xp;
    int  deposit;
    uint withdrawal;
    uint lastOwnershipChange; 
    bool isActive;
  }

  error MaxSupply           ();
  error SyncTooSoon         ();
  error DyadTotalSupplyZero ();
  error DepositIsNegative   ();
  error EthPriceUnchanged   ();
  error DepositedInSameBlock();
  error CannotSnipeSelf     ();
  error AlreadySniped       ();
  error DepositTooLow       ();
  error NotLiquidatable     ();
  error DNftDoesNotExist    (uint id);
  error NotNFTOwner         (uint id);
  error WithdrawalsNotZero  (uint id);
  error IsActive            (uint id);
  error IsInactive          (uint id);
  error ExceedsAverageTVL   (uint averageTVL);
  error CrTooLow            (uint cr);
  error ExceedsDeposit      (int deposit);
  error ExceedsWithdrawal   (uint amount);
  error AlreadyClaimed      (uint id, uint syncedBlock);
  error MissingPermission   (uint id, Permission permission);

  // view functions
  function MAX_SUPPLY()     external view returns (uint);
  function MINT_MINIMUM()   external view returns (uint);
  function XP_MINT_REWARD() external view returns (uint);
  function XP_SYNC_REWARD() external view returns (uint);
  function maxXp()          external view returns (uint);
  function idToNft(uint id) external view returns (Nft memory);
  function dyadDelta()      external view returns (int);
  function totalXp()        external view returns (uint);
  function syncedBlock()    external view returns (uint);
  function prevSyncedBlock()external view returns (uint);
  function ethPrice()       external view returns (uint);
  function totalDeposit()   external view returns (int);
  function hasPermission(uint id, address operator, Permission) external view returns (bool);
  function hasPermissions(uint id, address operator, Permission[] calldata) external view returns (bool[] calldata);
  function idToNftPermission(uint id, address operator) external view returns (NftPermission memory);

  /**
   * @notice Mint a new dNFT
   * @dev Will revert:
   *      - If `msg.value` is not enough to cover the deposit minimum
   *      - If the max supply of dNFTs has been reached
   *      - If `to` is the zero address
   * @dev Emits:
   *      - Minted
   *      - DyadMinted
   * @param to The address to mint the dNFT to
   * @return id Id of the new dNFT
   */
  function mint(address to) external payable returns (uint id);

  /**
   * @notice Exchange ETH for DYAD deposit
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `EXCHANGE` permission
   *      - dNFT is inactive
   * @dev Emits:
   *      - Exchanged
   * @dev For Auditors:
   *      - To save gas it does not check if `msg.value` is zero 
   * @param id Id of the dNFT that gets the deposited DYAD
   * @return amount Amount of DYAD deposited
   */
  function exchange(uint id) external payable returns (int);

  /**
   * @notice Deposit `amount` of DYAD back into dNFT
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `DEPOSIT` permission
   *      - dNFT is inactive
   *      - `amount` to deposit exceeds the dNFT withdrawals
   *      - if `msg.sender` does not have a DYAD balance of at least `amount`
   * @dev Emits:
   *      - Deposited
   * @dev For Auditors:
   *      - To save gas it does not check if `amount` is zero 
   * @param id Id of the dNFT that gets the deposited DYAD
   * @param amount Amount of DYAD to deposit
   */
  function deposit(uint id, uint amount) external;

  /**
   * @notice Move `amount` `from` one dNFT deposit `to` another dNFT deposit
   * @dev Will revert:
   *      - `amount` is not greater than zero
   *      - If `msg.sender` is not the owner of the `from` dNFT AND does not have the
   *        `MOVE` permission for the `from` dNFT
   *      - `amount` to move exceeds the `from` dNFT deposit 
   * @dev Emits:
   *      - Moved(uint indexed from, uint indexed to, int amount)
   * @dev For Auditors:
   *      - `amount` is int not uint because it saves us a lot of gas in doing
   *        the int to uint conversion. But thats means we have to put in the 
   *        `require(_amount > 0)` check.
   *      - To save gas it does not check if `from` == `to`, which is not a 
   *        problem because `move` is symmetrical.
   * @param from Id of the dNFT to move the deposit from
   * @param to Id of the dNFT to move the deposit to
   * @param amount Amount of DYAD to move
   */
  function move(uint from, uint to, int amount) external;

  /**
   * @notice Withdraw `amount` of DYAD from dNFT
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `WITHDRAW` permission
   *      - dNFT is inactive
   *      - If DYAD was deposited into the dNFt in the same block. Needed to
   *        prevent flash-loan attacks
   *      - If `amount` to withdraw is larger than the dNFT deposit
   *      - If Collateralization Ratio is is less than the min collaterization 
   *        ratio after the withdrawal
   *      - If dNFT withdrawal is larger than the average TVL after the 
   *        withdrawal
   * @dev Emits:
   *      - Withdrawn(uint indexed from, address indexed to, uint amount)
   * @dev For Auditors:
   *      - To save gas it does not check if `amount` is 0 
   *      - To save gas it does not check if `from` == `to`
   *      - To prevent flash-loan attacks, (`exchange` or `deposit`) and `withdraw` can not be
   *        called for the same dNFT in the same block
   * @param from Id of the dNFT to withdraw from
   * @param to Address to send the DYAD to
   * @param amount Amount of DYAD to withdraw
   * @return collatRatio New Collateralization Ratio after the withdrawal
   */
  function withdraw(uint from, address to, uint amount) external returns (uint);

  /**
   * @notice Redeem `amount` of DYAD for ETH
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `REDEEM` permission
   *      - If dNFT is inactive
   *      - If DYAD to redeem is larger than the dNFT withdrawal
   *      - If the ETH transfer fails
   * @dev Emits:
   *      - Redeemed(address indexed to, uint indexed id, uint amount)
   * @dev For Auditors:
   *      - To save gas it does not check if `amount` is 0 
   *      - There is a re-entrancy risk while transfering the ETH, that is why the 
   *        `nonReentrant` modifier is used and all state changes are done before
   *         the ETH transfer
   *      - We do not restrict the amount of gas that can be consumed by the ETH
   *        transfer. This is intentional, as the user calling this function can
   *        always decide who should get the funds. 
   * @param from Id of the dNFT to redeem from
   * @param to Address to send the ETH to
   * @param amount Amount of DYAD to redeem
   * @return eth Amount of ETH redeemed for DYAD
   */
  function redeem(uint from, address to, uint amount) external returns (uint);

  /**
   * @notice Determine amount of claimable DYAD 
   * @dev Will revert:
   *      - If dNFT with `id` is not active
   *      - If the total supply of DYAD is 0
   *      - Is called to soon after last sync as determined by `MIN_TIME_BETWEEN_SYNC`
   *      - If the new ETH price is the same as the one from the previous sync
   * @dev Emits:
   *      - Synced(uint id)
   * @dev For Auditors:
   *      - No need to check if the dNFT exists because a dNFT that does not exist
   *        is inactive
   *      - Amount to mint/burn is based only on withdrawn DYAD
   *      - The chainlink update threshold is currently set to 50 bps
   * @param id Id of the dNFT that gets a boost
   * @return dyadDelta Amount of claimable DYAD
   */
  function sync(uint id) external returns (int);

  /**
   * @notice Claim DYAD from the current sync window
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `CLAIM` permission
   *      - If dNFT is inactive
   *      - If `claim` was already called for that dNFT in this sync window
   *      - If dNFT deposit is negative
   *      - If DYAD will be burned and `totalDeposit` is negative
   * @dev Emits:
   *      - Claimed
   * @dev For Auditors:
   *      - `timeOfLastSync` is not set deliberately in the constructor. `sync`
   *        should be callable as fast as possible after deployment.
   * @param id Id of the dNFT that gets claimed for
   * @return share Amount of DYAD claimed
   */
  function claim(uint id) external returns (int);

  /**
   * @notice Snipe DYAD from previouse sync window to get a bonus
   * @dev Will revert:
   *      - If `from` dNFT is inactive
   *      - If `to` dNFT is inactive
   *      - If `from` equals `to`
   *      - If `snipe` was already called for that dNFT in this sync window
   *      - If dNFT deposit is negative
   *      - If DYAD will be burned and `totalDeposit` is negative
   * @dev Emits:
   *      - Sniped
   * @param from Id of the dNFT that gets sniped
   * @param to Id of the dNFT that gets the snipe reward
   * @return share Amount of DYAD sniped
   */
  function snipe(uint from, uint to) external returns (int);

  /**
   * @notice Liquidate dNFT by covering its negative deposit and transfering it 
   *         to a new owner
   * @dev Will revert:
   *      - If dNFT deposit is not negative
   *      - If ETH sent is not enough to cover the negative dNFT deposit
   * @dev Emits:
   *      - Liquidated
   * @dev For Auditors:
   *      - No need to check if the dNFT exists because a dNFT that does not exist
   *        can not have a negative deposit
   *      - We can calculate the absolute deposit value by multiplying with -1 because it
   *        is always negative
   *      - No need to delete `idToNft`, because its data is kept as it is or overwritten
   *      - All permissions for this dNFT are reset because `_transfer` calls `_beforeTokenTransfer`
   *        which updates the `lastOwnershipChange`
   * @param id Id of the dNFT to liquidate
   * @param to Address to send the dNFT to
   */
  function liquidate(uint id, address to) external payable;

  /**
   * @notice Activate dNFT
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `ACTIVATE` permission
   *      - dNFT is active already
   * @dev Emits:
   *      - Activated
   * @param id Id of the dNFT to activate
   */
  function activate(uint id) external;

  /**
   * @notice Deactivate dNFT
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT AND does not have the
   *        `DEACTIVATE` permission
   *      - dNFT is inactive already
   *      - dNFT withdrawal is larger than 0
   *      - dNFT deposit is negative
   * @dev Emits:
   *      - Deactivated
   * @param id Id of the dNFT to deactivate
   */
  function deactivate(uint id) external;

  /**
   * @notice Grant and/or revoke permissions
   * @dev Will revert:
   *      - If `msg.sender` is not the owner of the dNFT  
   * @dev Emits:
   *      - Modified
   * @dev To remove all permissions for a specific operator pass in an empty Permission array
   *      for that PermissionSet
   * @param id Id of the dNFT's permissions to modify
   * @param permissionSets Permissions to grant and revoke fro specific operators
   */
  function grant(uint id, PermissionSet[] calldata permissionSets) external;


  // ERC721
  function ownerOf(uint tokenId) external view returns (address);
  function balanceOf(address owner) external view returns (uint256 balance);
  function approve(address spender, uint256 id) external;
  function transferFrom(address from, address to, uint256 id) external;

  // ERC721Enumerable
  function totalSupply() external view returns (uint256);
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
  function tokenByIndex(uint256 index) external view returns (uint256);
}