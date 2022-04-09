// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "Strings.sol";
import "SafeCast.sol";

    
    /// @title Accessory SVG generator
    contract smallHelmet0 {
        uint256 public libraryCount = 2;
        /// @dev Accessory N°1 => Classic
        function gearSvg0(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "1Bun",
                    string(
                    abi.encodePacked(
                       "<defs><linearGradient id='linear-gradient' x1='960.13' y1='511.14' x2='960.13' y2='204.52' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='0.5'/><stop offset='0.14' stop-opacity='0.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g id='_4-HelmetSmall' data-name='4-HelmetSmall'><g id='_1Bun' data-name='1Bun'><path id='GB-03-Solid' d='M857.69,435.71c-56.16-47.18-49.42-140.27,0-188l2-1.92c58.28-54.44,150.84-58.11,209.81,7.25,44.07,48.85,43.72,140-4.26,182.63Z' style='fill:#",
                        PRIMARY,
                        "'/><path id='GB-04-Solid' d='M1043.28,425c27,11,41.34,30,36.34,55.33-4.37,22.16-23,31.38-42.89,30.73-12.17-.39-35.05-5.83-76.52-5.83s-64.36,5.44-76.52,5.83c-19.93.65-38.53-8.57-42.89-30.73C835.8,455,850.14,436,877.14,425c25.26-10.29,67.12-12.31,83.07-12.31S1018,414.75,1043.28,425Z' style='fill:#",
                        SECONDARY,
                        "'/><path id='Grad' d='M1064.27,436.71c50-45,49.33-134.78,5.26-183.63-59-65.36-151.53-61.69-209.81-7.25l-2,1.92c-49.42,47.69-56.16,140.78,0,188-11.39,7.35-20.06,26.69-16.89,44.66,3.92,22.24,23,31.38,42.89,30.73,12.16-.39,35-5.83,76.52-5.83s64.35,5.44,76.52,5.83c19.93.65,38.31-8.61,42.89-30.73C1083.63,461,1077.63,447.05,1064.27,436.71Z' style='fill:url(#linear-gradient)'/><path id='Shad' d='M1064,437.71c-38-32.21-166.41-32.65-206.35-2-34.73-30.2-42.33-70.23-38.14-110.5-6.74,64.84,98.13,75.35,140.22,75.35,44.69,0,143.16-12.38,140.68-76C1104.64,364.81,1094.6,411,1064,437.71Zm-9.09-7c13.2,8.66,19.31,20.42,15.94,34.8-4.05,17.31-21.28,24.51-39.76,24-11.27-.31-32.48-4.56-70.92-4.56s-59.65,4.25-70.92,4.56c-18.48.5-35.71-6.7-39.76-24-3.37-14.38,2.74-26.14,15.94-34.8-19.33,11.36-28.89,28.23-24.67,49.62,4.36,22.16,23,31.38,42.89,30.73,12.16-.39,35-5.83,76.52-5.83s64.35,5.44,76.52,5.83c19.93.65,38.52-8.57,42.89-30.73C1083.84,459,1074.28,442.11,1055,430.75Z' style='opacity:0.2'/><path id='Hi' d='M900.39,419.89a293.19,293.19,0,0,1,60.78-5.83c11.32.06,36.44,1.66,61.92,6.29,25.22,4.58,18.93,26.6-5.88,21.31-38.34-8.17-76.23-6.6-114.6.48C877.45,446.78,876.35,424.62,900.39,419.89Zm19.76-179.37c4.29,11.21,23,15.2,34.51,15.76,12.89.64,34.23-1.43,42.88-12.47,7.71-9.83.36-19.21-10.17-24.12-11.75-5.47-32.07-6-44.47-3C932.24,219.27,915.16,227.45,920.15,240.52Z' style='fill:#fff;opacity:0.2'/><path id='Outline' d='M1043.28,425c27,11,41.34,30,36.34,55.33-4.37,22.16-23,31.38-42.89,30.73-12.17-.39-35.05-5.83-76.52-5.83s-64.36,5.44-76.52,5.83c-19.93.65-38.53-8.57-42.89-30.73C835.8,455,850.14,436,877.14,425c25.26-10.29,67.12-12.31,83.07-12.31S1018,414.75,1043.28,425ZM857.69,435.71c-56.16-47.18-49.42-140.27,0-188l2-1.92c58.28-54.44,150.84-58.11,209.81,7.25,44.07,48.85,43.72,140-4.26,182.63' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
                    )
                 )
                );
            }

       
        /// @dev Accessory N°1 => Classic
        function gearSvg1(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "2balls",
                    string(abi.encodePacked(
                         "<defs><linearGradient id='linear-gradient' x1='963.1' y1='533.39' x2='963.1' y2='362.97' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='0.5'/><stop offset='0.14' stop-opacity='0.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g id='_4-HelmetSmall' data-name='4-HelmetSmall'><g id='_2Ball' data-name='2Ball'><path id='GB-03-Solid' d='M797.73,363a78.78,78.78,0,0,1,68.75,44.3c12.61,25.53,12.33,56.86-1.8,81.72-21.39,37.6-72.64,56.61-111.89,35.77-31.35-16.65-49.46-54.6-43.95-89.48a81.12,81.12,0,0,1,17.16-38C743.12,375.92,770.23,362.26,797.73,363Zm271,34.28a81.12,81.12,0,0,0-17.16,38c-5.51,34.88,12.6,72.83,44,89.48,39.24,20.84,90.49,1.83,111.88-35.77,14.13-24.86,14.41-56.19,1.8-81.72a78.78,78.78,0,0,0-68.75-44.3C1113,362.26,1085.84,375.92,1068.72,397.28Z' style='fill:#",
                            PRIMARY,
                            "'/><path id='Grad' d='M797.73,363a78.78,78.78,0,0,1,68.75,44.3c12.61,25.53,12.33,56.86-1.8,81.72-21.39,37.6-72.64,56.61-111.89,35.77-31.35-16.65-49.46-54.6-43.95-89.48a81.12,81.12,0,0,1,17.16-38C743.12,375.92,770.23,362.26,797.73,363Zm271,34.28a81.12,81.12,0,0,0-17.16,38c-5.51,34.88,12.6,72.83,44,89.48,39.24,20.84,90.49,1.83,111.88-35.77,14.13-24.86,14.41-56.19,1.8-81.72a78.78,78.78,0,0,0-68.75-44.3C1113,362.26,1085.84,375.92,1068.72,397.28Z' style='fill:url(#linear-gradient)'/><path id='Shad' d='M864.08,490c-21.73,36.92-72.4,55.4-111.29,34.75-17.86-9.49-31.42-25.89-38.76-44.7a91.84,91.84,0,0,0,35.41,28.58C787.35,526,834.93,515.73,864.08,490Zm228.08,18.63a91.84,91.84,0,0,1-35.41-28.58c7.35,18.81,20.9,35.21,38.77,44.7,38.88,20.65,89.55,2.17,111.28-34.75C1177.65,515.73,1130.07,526,1092.16,508.67Z' style='opacity:0.2'/><path id='Hi' d='M711,425.92a83,83,0,0,1,15-28.64c17.12-21.36,44.23-35,71.73-34.28a78.78,78.78,0,0,1,68.75,44.3,88.52,88.52,0,0,1,5.4,13.8c-.09-.17-.17-.35-.27-.52-14-26.48-31.87-50.73-77-49.54C728.52,372.77,713.85,420.46,711,425.92Zm118.12-5.56c7.63,9.42,22,13.09,21.72-1.74-.19-9.82-13.68-26.2-23.68-20C819.64,403.29,823.86,413.92,829.07,420.36Zm224.6,5.56a83,83,0,0,1,15-28.64c17.12-21.36,44.23-35,71.73-34.28a78.78,78.78,0,0,1,68.75,44.3,87.54,87.54,0,0,1,5.4,13.8c-.09-.17-.17-.35-.27-.52-14-26.48-31.87-50.73-77-49.54C1071.24,372.77,1056.57,420.46,1053.67,425.92Zm118.12-5.56c7.63,9.42,22,13.09,21.72-1.74-.19-9.82-13.68-26.2-23.68-20C1162.36,403.29,1166.58,413.92,1171.79,420.36Z' style='fill:#fff;opacity:0.2'/><path id='Outline' d='M797.73,363a78.78,78.78,0,0,1,68.75,44.3c12.61,25.53,12.33,56.86-1.8,81.72-21.39,37.6-72.64,56.61-111.89,35.77-31.35-16.65-49.46-54.6-43.95-89.48a81.12,81.12,0,0,1,17.16-38C743.12,375.92,770.23,362.26,797.73,363Zm271,34.28a81.12,81.12,0,0,0-17.16,38c-5.51,34.88,12.6,72.83,44,89.48,39.24,20.84,90.49,1.83,111.88-35.77,14.13-24.86,14.41-56.19,1.8-81.72a78.78,78.78,0,0,0-68.75-44.3C1113,362.26,1085.84,375.92,1068.72,397.28Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"

                    ))
                );
            }


        function getLibraryCount() public view returns (uint256 ) {
                return libraryCount;

        }

        function getHelmetSvg(string memory classOne, string memory classTwo, uint256 rand) public pure returns (string memory, string memory ) {
            if (rand == 1) {
                return gearSvg1(classOne, classTwo);
            } else {
                return gearSvg0(classOne, classTwo);
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