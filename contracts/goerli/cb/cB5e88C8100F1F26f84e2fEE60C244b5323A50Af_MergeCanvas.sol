// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IMergeCanvas.sol";

contract MergeCanvas is IMergeCanvas {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    uint16 public immutable CANVAS_DIMENSION;
    address immutable OWNER_ADDRESS;
    // TODO: directly measure closeness to merge
    // uint256 immutable DEPLOY_TIMESTAMP;

    uint256 immutable ESTIMATED_CLOSE_TIMESTAMP = 1663088400; // September 13, 2022 12:00:00 PM GMT-05:00
    uint256 immutable MIN_BID_AMOUNT = 1 ether / 1000; // 0.001 ether min bid

    bool private merged = false;
    bool private batchAllowed = true;

    mapping(bytes32 => address) private pixel_owner;
    // Colors represented as rgb values
    mapping(bytes32 => RGB) private pixel_color;
    mapping(bytes32 => uint256) private pixel_price_paid;
    // Quick look-up of pixel(s) owned by an address
    // The 16 most significant bits will be the x-coordinate
    // The 16 least significant bits will be the y-coordinate
    // Note: Encoding the (x,y) values would result in bytes instead of bytes32
    mapping(address => EnumerableSet.UintSet) private pixel_lookup;

    modifier OnlyOwner() {
        if (msg.sender != OWNER_ADDRESS) {
            revert MergeCanvas_NotOwner(msg.sender);
        }
        _;
    }

    modifier ValidCoordinates(uint16 _x, uint16 _y) {
        if (_x > (CANVAS_DIMENSION - 1)) {
            revert MergeCanvas_XCoordinateOutOfBounds(_x, CANVAS_DIMENSION);
        } else if (_y > (CANVAS_DIMENSION - 1)) {
            revert MergeCanvas_YCoordinateOutOfBounds(_y, CANVAS_DIMENSION);
        }
        _;
    }

    function hasContributed(address _address) external view returns (bool) {
        if (pixel_lookup[_address].length() == 0) {
            revert MergeCanvas_NotContributor(_address);
        }
        return true;
    }

    modifier SufficientBid(uint16 _x, uint16 _y) {
        uint256 pixel_price = _calculatePixelPrice(_x, _y);
        uint256 val = msg.value; // https://github.com/crytic/slither/wiki/Detector-Documentation/#msgvalue-inside-a-loop
        if (pixel_price > 0 && val <= pixel_price) {
            revert MergeCanvas_InsufficientBid(val, pixel_price);
        }
        _;
    }

    //OPTIONAL: Limit the number of pixels an address can own
    modifier NotAtMaxPixelCapacity() {
        uint256 address_pixel_capacity = pixel_lookup[msg.sender].length();
        if (address_pixel_capacity >= CANVAS_DIMENSION) {
            revert MergeCanvas_AddressAtMaxPixelCapacity(msg.sender);
        }
        _;
    }

    // TODO: Logic to ensure that change takes place before merge
    modifier BeforeMerge() {
        if (merged) {
            revert MergeCanvas_AlreadyMerged("Merge has occurred");
        }
        _;
    }

    constructor(uint16 _canvas_dimension) {
        OWNER_ADDRESS = msg.sender;
        CANVAS_DIMENSION = _canvas_dimension;
        // DEPLOY_TIMESTAMP = block.timestamp;
    }

    function _calculateCoordinatesHash(uint16 _x, uint16 _y)
        internal
        view
        ValidCoordinates(_x, _y)
        returns (bytes32 coordinates_hash)
    {
        coordinates_hash = keccak256(abi.encode(_x, _y));
        return coordinates_hash;
    }

    function _calculatePixelPrice(uint16 _x, uint16 _y)
        internal
        view
        returns (uint256 pixel_price)
    {
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);
        return pixel_price_paid[coordinates_hash];
    }

    function _changePixelColor(
        uint16 _x,
        uint16 _y,
        RGB calldata _new_color,
        uint256 _new_price,
        uint256 _remainder
    )
        internal
        returns (bool)
    {
        // Get the hash of the (x,y) coordinates
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);

        uint256 old_price = pixel_price_paid[coordinates_hash];
        address old_owner = pixel_owner[coordinates_hash];

        if (
            // either old price is 0 (no price set)
            // or new price exceeds (old price + min bid) && user has balance to pay
            old_price == 0
            || (_new_price >= old_price + MIN_BID_AMOUNT && _remainder >= _new_price)
        ) {
            // Update pixel price, owner, and color
            pixel_price_paid[coordinates_hash] = _new_price;
            pixel_owner[coordinates_hash] = msg.sender;
            pixel_color[coordinates_hash] = _new_color;

            // Update the address mapping
            uint256 pixel_encoded = (uint32(_x) << 16) + _y;
            pixel_lookup[old_owner].remove(pixel_encoded);
            pixel_lookup[msg.sender].add(pixel_encoded);

            emit PixelChange(_x, _y, _new_color, msg.sender, _new_price);

            // Refund all new money to previous owner, at last for CIE pattern
            if (_new_price > 0) {
                if (old_owner != address(0)) {
                    (bool sent, ) = old_owner.call{value: _new_price}("");
                    if (!sent) {
                        revert MergeCanvas_FailedBidRefund();
                    }
                }
            }
            return true;
        } else {
            emit PixelChangeFail(_x, _y, _new_color, old_owner, msg.sender);
            return false;
        }
    }

    function changePixelColor(
        uint16 _x,
        uint16 _y,
        RGB calldata _new_color
    )
        external
        payable
        BeforeMerge
        NotAtMaxPixelCapacity
        SufficientBid(_x, _y)
    {
        _changePixelColor(_x, _y, _new_color, msg.value, msg.value);
    }

    //
    // @dev Change color of multiple pixels
    //
    function changePixelsColor(
        uint16[] memory _x,
        uint16[] memory _y,
        RGB[] calldata _new_color,
        uint256[] memory _prices
    )
        external
        payable
        BeforeMerge
        NotAtMaxPixelCapacity
    {
        require(batchAllowed, "Batch change color paused!");
        require(_x.length == _y.length && _x.length == _new_color.length && _x.length == _prices.length);

        // first iteration to check info
        // NOTE: https://github.com/crytic/slither/wiki/Detector-Documentation/#msgvalue-inside-a-loop
//        uint256 remainder = msg.value;
//        for (uint i = 0; i < _x.length; i++) {
//            uint256 pixel_price = _calculatePixelPrice(_x[i], _y[i]);
//            if (pixel_price > 0) {
//                if (_prices[i] <= pixel_price + MIN_BID_AMOUNT) {
//                    revert MergeCanvas_InsufficientBid(_prices[i], pixel_price);
//                }
//                require(remainder > pixel_price + MIN_BID_AMOUNT, "Insufficient balance for batch change");
//            } else {
//                require(remainder >= pixel_price, "Insufficient balance for batch change");
//            }
//            remainder -= _prices[i];
//        }

        uint256 remainder = msg.value;
        for (uint i = 0; i < _x.length; i++) {
            bool changed = _changePixelColor(_x[i], _y[i], _new_color[i], _prices[i], remainder);
            if (changed) {
                remainder -= _prices[i];
            }
        }

        // Refund whatever remainder from failing bids
        (bool sent, ) = msg.sender.call{value: remainder}("");
        require(sent, "Failed to refund any unused bid!");
    }

    function getPixelOwner(uint16 _x, uint16 _y)
        external
        view
        returns (address owner)
    {
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);
        owner = pixel_owner[coordinates_hash];
    }

    function getPixelColor(uint16 _x, uint16 _y)
        external
        view
        returns (RGB memory color)
    {
        bytes32 coordinates_hash = _calculateCoordinatesHash(_x, _y);
        color = pixel_color[coordinates_hash];
    }

    function getPixelPrice(uint16 _x, uint16 _y)
        external
        view
        returns (uint256 pixel_price)
    {
        pixel_price = _calculatePixelPrice(_x, _y);
    }

    // Could remove function and instead use getPixelsForAddress()
    function getAddressPixels(address _address)
        external
        view
        returns (uint256[] memory address_pixels)
    {
        address_pixels = pixel_lookup[_address].values();
    }

    function numberOfPixels(address _address) external view returns (uint256) {
        uint256[] memory address_pixels = pixel_lookup[_address].values();
        return address_pixels.length;
    }

    function mergeNow() external OnlyOwner {
        require(block.timestamp >= ESTIMATED_CLOSE_TIMESTAMP, "Not at the estimated close timestamp!");
        merged = true;
    }

    function mergeStatus() external view returns (bool) {
        return merged;
    }

    function setBatchAllowed(bool _allow) external OnlyOwner {
        batchAllowed = _allow;
    }

    function withdraw() external OnlyOwner {
        require(merged, "Merge has to happen!");
        (bool sent, ) = OWNER_ADDRESS.call{value: address(this).balance}("");
        if (!sent) {
            revert MergeCanvas_FailedBidRefund();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

error MergeCanvas_AlreadyMerged(string reason);
error MergeCanvas_NotOwner(address sender);
error MergeCanvas_XCoordinateOutOfBounds(uint16 x, uint16 max_value);
error MergeCanvas_YCoordinateOutOfBounds(uint16 y, uint16 max_value);
error MergeCanvas_InvalidRGBColor(uint16 invalid_num);
error MergeCanvas_InsufficientBid(uint256 bid, uint256 curr_price);
error MergeCanvas_FailedBidRefund();
error MergeCanvas_NotContributor(address sender);
error MergeCanvas_AddressAtMaxPixelCapacity(address sender);

interface IMergeCanvas {
    struct RGB {
        uint8 R;
        uint8 G;
        uint8 B;
    }

    event PixelChange(
        uint16 x,
        uint16 y,
        RGB new_color,
        address indexed new_owner,
        uint256 new_price
    );

    event PixelChangeFail(
        uint16 x,
        uint16 y,
        RGB new_color,
        address indexed old_owner,
        address indexed new_owner
    );

    function hasContributed(address _address) external view returns (bool);

    function changePixelColor(
        uint16 _x,
        uint16 _y,
        RGB calldata _new_color
    )
    external
    payable;

    //
    // @dev Change color of multiple pixels
    //
    function changePixelsColor(
        uint16[] memory _x,
        uint16[] memory _y,
        RGB[] calldata _new_color,
        uint256[] memory _prices
    )
    external
    payable;

    function getPixelOwner(uint16 _x, uint16 _y)
    external
    view
    returns (address owner);

    function getPixelColor(uint16 _x, uint16 _y)
    external
    view
    returns (RGB memory color);

    function getPixelPrice(uint16 _x, uint16 _y)
    external
    view
    returns (uint256 pixel_price);

    // Could remove function and instead use getPixelsForAddress()
    function getAddressPixels(address _address)
    external
    view
    returns (uint256[] memory address_pixels);

    function numberOfPixels(address _address) external view returns (uint256);

    function mergeNow() external;

    function withdraw() external;

    function mergeStatus() external view returns (bool);

    function setBatchAllowed(bool _allow) external;
}