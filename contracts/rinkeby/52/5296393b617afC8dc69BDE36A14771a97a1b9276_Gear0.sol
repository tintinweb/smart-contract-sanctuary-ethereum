// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "Strings.sol";
import "SafeCast.sol";

// The internal noun ID tracker
    
    /// @title Accessory SVG generator
    contract Gear0 {
        uint256 public libraryCount = 2;
        /// @dev Accessory N°1 => Classic
        function gearSvg0(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "Acorn",
                    string(
                    abi.encodePacked(
                        "<defs><linearGradient id='a-gear' x1='960' y1='1415.41' x2='960' y2='1844.83' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.7'/><stop offset='.14' stop-opacity='.33'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g data-name='3-Gear'><path d='M784.49 1415.41c-78.22 0-126 51-128.22 119-.89 27.06 13.23 44 47.23 53 97.58 25.83 219.22-17 256.5-110.17 37.28 93.16 158.92 136 256.5 110.17 34-9 48.12-26 47.23-53-2.22-68-49-119-128.22-119Zm0 250c-78.22 0-126 51-128.22 119-.89 27.06 13.23 44 47.23 53 97.58 25.82 219.22-17 256.5-110.18 37.28 93.16 158.92 136 256.5 110.18 34-9 48.12-26 47.23-53-2.22-68-49-119-128.22-119Z' style='fill:#",
                        PRIMARY,
                        "'/><path d='M784.49 1415.41c-78.22 0-126 51-128.22 119-.89 27.06 13.23 44 47.23 53 97.58 25.83 219.22-17 256.5-110.17 37.28 93.16 158.92 136 256.5 110.17 34-9 48.12-26 47.23-53-2.22-68-49-119-128.22-119Zm0 250c-78.22 0-126 51-128.22 119-.89 27.06 13.23 44 47.23 53 97.58 25.82 219.22-17 256.5-110.18 37.28 93.16 158.92 136 256.5 110.18 34-9 48.12-26 47.23-53-2.22-68-49-119-128.22-119Z' style='opacity:.7000000000000001;fill:url(#a-gear)'/><path d='m1251.43 1570.48-4 16.37c-7.5 6.56-17.72 11.68-31 15.49-97.58 28.06-219.22-12.95-256.5-100.95-33.71 90-158.92 129-256.5 100.95-13.24-3.81-23.46-8.93-31-15.49l-3.33-15.69c-8.92-9.75-14.59-22.41-12.45-35.24 4.59 16.45 19.68 27.4 46.74 33.82 89.12 21.16 201.13-21 245-94.27 8.5-14.19 14.72-14.42 23.49.63 42.9 73.56 155.69 114.74 244.55 93.64 27.06-6.42 42.15-17.38 46.74-33.83 1.45 8.79-1.88 25.45-11.74 34.57Zm11.81 219.43c-4.59 16.45-19.68 27.41-46.74 33.83-88.86 21.1-201.65-20.08-244.55-93.64-8.77-15-15-14.82-23.49-.63-43.83 73.23-155.84 115.43-245 94.27-27.06-6.42-42.15-17.38-46.74-33.82-2.14 12.83 3.53 25.49 12.45 35.24l3.33 15.68c7.5 6.57 17.72 11.69 31 15.5 97.58 28.06 222.79-11 256.5-100.95 37.28 88 158.92 129 256.5 100.95 13.24-3.81 23.46-8.93 31-15.5l4-16.36c9.79-9.12 13.12-25.78 11.74-34.57Z' style='opacity:.2'/><path d='M1173 1435.28c-11.41-3.52-28.28-4.87-43.51-4.87H790.55c-35.07 0-63.8 11-84.73 29.59-24.15 21.44-33.64 5.44-7.89-16 21.58-18 50.9-28.57 86.56-28.57h351c15.94 0 31.88 2.87 42.56 6.53 11.63 3.97 6.32 16.83-5.05 13.32Zm30.54 16c19.47 11.79 30.16 29.24 38.87 52.45 7 18.7 19.53 10.4 14-6.06-8.29-24.73-19.74-45.27-42-59.84-16.63-10.83-24.92 4.93-10.91 13.42Zm-25.43 220.69c-10.68-3.66-26.62-6.53-42.56-6.53h-351c-35.66 0-65 10.6-86.56 28.57-25.75 21.46-16.26 37.46 7.89 16 20.93-18.59 49.66-29.59 84.73-29.59h338.9c15.23 0 32.1 1.35 43.51 4.87s16.66-9.36 5.05-13.35Zm25.43 29.31c19.47 11.79 30.16 29.24 38.87 52.45 7 18.7 19.53 10.4 14-6.06-8.29-24.73-19.74-45.27-42-59.84-16.63-10.83-24.92 4.93-10.91 13.42Z' style='fill:#fff;opacity:.2'/><path d='M784.49 1415.41c-78.22 0-126 51-128.22 119-.89 27.06 13.23 44 47.23 53 97.58 25.83 219.22-17 256.5-110.17 37.28 93.16 158.92 136 256.5 110.17 34-9 48.12-26 47.23-53-2.22-68-49-119-128.22-119Zm0 250c-78.22 0-126 51-128.22 119-.89 27.06 13.23 44 47.23 53 97.58 25.82 219.22-17 256.5-110.18 37.28 93.16 158.92 136 256.5 110.18 34-9 48.12-26 47.23-53-2.22-68-49-119-128.22-119Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"
                        )));
            }


        /// @dev Accessory N°1 => Classic
        function gearSvg1(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "Aeri",
                    string(
                    abi.encodePacked(
                        "<defs><linearGradient id='a-gear' x1='960' y1='1420.37' x2='960' y2='1797.35' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.5'/><stop offset='.14' stop-opacity='.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g data-name='3-Gear'><path d='M1121.63 1420.37c73 0 376 9.6 397 68.6s-33 155.44-105 182.72-131 .28-142 11.28-61.09 114.38-311.63 114.38S659.37 1694 648.37 1683s-70 16-142-11.28-126-123.72-105-182.72 324-68.6 397-68.6Z' style='fill:#",
                        PRIMARY,
                        "'/><path d='M958.55 1705.25c240.54 0 288.69-117.52 275.18-172s-193.71-56-275.18-56-261.67 1.53-275.18 56 34.63 172 275.18 172Z' style='fill:#",
                        SECONDARY,
                        "'/><path d='M1121.63 1420.37c73 0 376 9.6 397 68.6s-33 155.44-105 182.72-131 .28-142 11.28-61.09 114.38-311.63 114.38S659.37 1694 648.37 1683s-70 16-142-11.28-126-123.72-105-182.72 324-68.6 397-68.6Z' style='fill:url(#a-gear)'/><path d='M1523 1515.81c-.44 59-45.27 130-108.92 155.41-72 28.78-131 .3-142 11.9-3.71 3.92-20 23.54-38.85 41.74l5.39 11.8c-37.86 35.41-116 81.32-278.61 81.32-162.38 0-240.56-45.8-278.47-81.19l5.29-11.9c-22-16.23-34.65-37.91-38.45-41.92-11-11.6-70 16.88-142-11.9-63.65-25.44-111.38-98.38-109.38-155.26 3.52 52 50.4 115.29 109.36 135.86 72 25.11 131 .26 142 10.38s61.1 105.26 311.64 105.26 300.63-95.14 311.63-105.26 70 14.73 142-10.38c58.96-20.57 105.84-83.81 109.37-135.86Zm-288.28 26.92c-3.11 53.46-65.39 135.25-276.16 135.25s-273-81.79-276.15-135.25c-9.72 60.67 42.27 180.58 276.15 180.58s285.86-119.91 276.15-180.58Z' style='opacity:.2'/><path d='M426 1466.68c77.94-39.25 309.78-46.31 372.39-46.31h323.26c62.32 0 292.29 7 371.29 45.76 13.53 6.64 11.36 20.91-4.85 13.74-83.16-36.77-305.35-43.5-366.44-43.5H798.37c-61.09 0-283.24 6.72-366.42 43.49-16.22 7.14-18.9-6.67-5.95-13.18Zm356.12 56.4c8.66-17.09 76.9-27.57 176.45-27.57s167.77 10.49 176.43 27.57-22.21 43.92-176.45 43.92-185.11-26.84-176.45-43.92Z' style='fill:#fff;opacity:.2'/><path d='M1121.63 1420.37c73 0 376 9.6 397 68.6s-33 155.44-105 182.72-131 .28-142 11.28-61.09 114.38-311.63 114.38S659.37 1694 648.37 1683s-70 16-142-11.28-126-123.72-105-182.72 324-68.6 397-68.6Zm-163.08 284.88c240.54 0 288.69-117.52 275.18-172s-193.71-56-275.18-56-261.67 1.53-275.18 56 34.63 172 275.18 172Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"
                                    )
                            )
                );
            }


        
        function getLibraryCount() public view returns (uint256 ) {
                return libraryCount;

        }

        function getGearSvg(string memory classOne, string memory classTwo, uint256 rand) public pure returns (string memory, string memory ) {
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