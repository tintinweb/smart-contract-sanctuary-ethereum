// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "Strings.sol";
import "SafeCast.sol";

    /// @title Accessory SVG generator
    contract BeansVibe {
        uint256 public libraryCount = 2;
        /// @dev Accessory N°1 => Classic


        function getGoodVibes(
            string memory PRIMARY
        ) internal pure returns (string memory)
            {
            return
                ( 
                    string(
                    abi.encodePacked(
                        "<g id='_5-Eyes' data-name='5-Eyes'><g id='GoodVibe'><path id='GA-02-Solid' d='M664.45,1174.67C515.1,1174.67,394,1053.59,394,904.24S515.1,633.81,664.45,633.81,934.88,754.88,934.88,904.24,813.8,1174.67,664.45,1174.67ZM1526,904.24c0-149.36-121.08-270.43-270.43-270.43S985.12,754.88,985.12,904.24s121.08,270.43,270.43,270.43S1526,1053.59,1526,904.24Z' style='fill:#",
                        PRIMARY,
                        "'/><path id='Eyes' d='M645.87,1010.61l-21.94-8.51c-120-49.69-199.1-133.78-176.72-187.83,20.91-50.5,123.05-56.89,234.24-17Zm644.54-228.8A499.5,499.5,0,0,0,1215,806.38c-120,49.68-199.1,133.77-176.72,187.82,19.71,47.59,111.56,56,215.15,23.41Z' style='fill:#fff'/><path id='Pupils' d='M1472.79,814.27c22.38,54.05-56.74,138.14-176.72,187.83-14.32,5.93-28.57,11.09-42.61,15.51a164.76,164.76,0,0,1,37-235.8C1380.05,760.52,1455.19,771.77,1472.79,814.27ZM705,806.38q-11.81-4.89-23.53-9.08a164.79,164.79,0,0,0-35.58,213.31c111.8,40.55,214.81,34.33,235.82-16.41C904.07,940.15,825,856.06,705,806.38Z'/><path id='Brows' d='M842.4,807.59H796.71a17.82,17.82,0,0,1-17.77-17.77h0a17.83,17.83,0,0,1,17.77-17.77H842.4a17.83,17.83,0,0,1,17.77,17.77h0A17.82,17.82,0,0,1,842.4,807.59Zm298.66-17.77h0a17.83,17.83,0,0,0-17.77-17.77H1077.6a17.83,17.83,0,0,0-17.77,17.77h0a17.82,17.82,0,0,0,17.77,17.77h45.69A17.82,17.82,0,0,0,1141.06,789.82Z'/><path id='Mouth' d='M986.35,1038.39l.1.33a5.29,5.29,0,0,1-3.79,6.7,96,96,0,0,1-45.3,0,5.27,5.27,0,0,1-3.81-6.68l.1-.33a5.3,5.3,0,0,1,6.36-3.55,84.92,84.92,0,0,0,40-.06A5.31,5.31,0,0,1,986.35,1038.39Z'/></g></g>" 
                        )
                        )
                );
            }

        function getBadVibes(
            string memory PRIMARY
        ) internal pure returns (string memory)
            {
            return
                (
                    string(
                    abi.encodePacked(
                       "<g id='_5-Eyes' data-name='5-Eyes'><g id='BadVibe'><path id='GA-02-Solid' d='M664.45,1174.67C515.1,1174.67,394,1053.59,394,904.24S515.1,633.81,664.45,633.81,934.88,754.88,934.88,904.24,813.8,1174.67,664.45,1174.67ZM1526,904.24c0-149.36-121.08-270.43-270.43-270.43S985.12,754.88,985.12,904.24s121.08,270.43,270.43,270.43S1526,1053.59,1526,904.24Z' style='fill:#",
                            PRIMARY,
                            "'/><path id='Eyes' d='M645.87,1010.61l-21.94-8.51c-120-49.69-199.1-133.78-176.72-187.83,20.91-50.5,123.05-56.89,234.24-17Zm644.54-228.8A499.5,499.5,0,0,0,1215,806.38c-120,49.68-199.1,133.77-176.72,187.82,19.71,47.59,111.56,56,215.15,23.41Z' style='fill:#fff'/><path id='Pupils' d='M1472.79,814.27c22.38,54.05-56.74,138.14-176.72,187.83-14.32,5.93-28.57,11.09-42.61,15.51a164.76,164.76,0,0,1,37-235.8C1380.05,760.52,1455.19,771.77,1472.79,814.27ZM705,806.38q-11.81-4.89-23.53-9.08a164.79,164.79,0,0,0-35.58,213.31c111.8,40.55,214.81,34.33,235.82-16.41C904.07,940.15,825,856.06,705,806.38Z'/><path id='Brows' d='M842.4,807.59H796.71a17.82,17.82,0,0,1-17.77-17.77h0a17.83,17.83,0,0,1,17.77-17.77H842.4a17.83,17.83,0,0,1,17.77,17.77h0A17.82,17.82,0,0,1,842.4,807.59Zm298.66-17.77h0a17.83,17.83,0,0,0-17.77-17.77H1077.6a17.83,17.83,0,0,0-17.77,17.77h0a17.82,17.82,0,0,0,17.77,17.77h45.69A17.82,17.82,0,0,0,1141.06,789.82Z'/><path id='Mouth' d='M933.65,1044.46l-.1-.33a5.29,5.29,0,0,1,3.79-6.7,96,96,0,0,1,45.3,0,5.27,5.27,0,0,1,3.81,6.68l-.1.33a5.3,5.3,0,0,1-6.36,3.55,84.92,84.92,0,0,0-40,.06A5.31,5.31,0,0,1,933.65,1044.46Z'/></g></g>"
                            )
                        )
                );
            }





        function getVibe(string memory classOne, string memory classTwo, uint256 vibeId) public view returns (string memory) {

                if (vibeId == 0) {
                    return(string(abi.encodePacked(getGoodVibes(classOne), '</svg>')));
                } else {
                    return(string(abi.encodePacked(getBadVibes(classOne), '</svg>')));
                }

        }
    }

// SPDX-License-Identifier: MIT

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}