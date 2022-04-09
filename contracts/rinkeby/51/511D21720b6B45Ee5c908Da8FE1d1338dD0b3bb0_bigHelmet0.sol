// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "Strings.sol";
import "SafeCast.sol";



    /// @title Accessory SVG generator
    contract bigHelmet0 {
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
                        "<defs><linearGradient id='linear-gradient' x1='960.23' y1='424.23' x2='960.23' y2='123.52' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='0.5'/><stop offset='0.14' stop-opacity='0.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g id='_4-HelmetBig' data-name='4-HelmetBig'><g id='_1Bun' data-name='1Bun'><path id='GB-03-Solid' d='M857.92,354.71c-56.16-47.19-49.42-140.27,0-188l2-1.92c58.28-54.44,150.84-58.11,209.81,7.25,44.07,48.85,43.72,140-4.26,182.63Z' style='fill:#",
                        PRIMARY,
                        "'/><path id='GB-04-Solid' d='M858,424.23H1062.5c8.45-4.92,14.82-13.06,17.14-24.86,5-25.34-9.34-44.34-36.34-55.33-25.26-10.3-67.12-12.32-83.07-12.32s-57.8,2-83.07,12.32c-27,11-41.34,30-36.34,55.33C843.14,411.17,849.51,419.31,858,424.23Z' style='fill:#",
                        SECONDARY,
                        "'/><path id='Grad' d='M857.79,354.71c-11.4,7.35-20.06,26.69-16.9,44.66,2.09,11.82,8.45,19.95,16.94,24.86h204.64c8.43-4.93,14.8-13.07,17.25-24.86,4-19.33-2-33.33-15.35-43.66,50-45,49.33-134.78,5.26-183.63-59-65.36-151.53-61.69-209.81-7.25l-2,1.92C808.37,214.44,801.63,307.52,857.79,354.71Z' style='fill:url(#linear-gradient)'/><path id='Shad' d='M1064.34,356.71l.34-.31c12.88,10.91,18.7,25.42,15.24,43-2.33,11.8-8.69,19.94-17.15,24.86H858.24c-8.45-4.92-14.82-13.06-17.15-24.86-4.21-21.39,5.35-38.26,24.68-49.62-13.2,8.66-19.31,20.42-15.94,34.8,4,17.31,21.28,24.51,39.76,24,11.27-.31,32.48-4.56,70.92-4.56s59.65,4.25,70.92,4.56c18.48.5,35.71-6.7,39.76-24,2.83-12.11-1.07-22.35-10.25-30.46C1062.14,354.94,1063.28,355.81,1064.34,356.71Zm-206.35-2c38.82-29.79,161.27-30.21,203-.62a50.61,50.61,0,0,0-5.69-4.34,66.69,66.69,0,0,1,9.43,6.65c30.29-26.72,40.24-72.74,36.07-112.86,2.48,63.64-96,76-140.69,76-42.08,0-147-10.51-140.21-75.35C815.66,284.48,823.26,324.51,858,354.71Z' style='opacity:0.2'/><path id='Hi' d='M899.51,338.89a293.19,293.19,0,0,1,60.78-5.83c11.32.06,36.45,1.66,61.92,6.29,25.22,4.58,18.93,26.59-5.87,21.31-38.35-8.17-76.24-6.6-114.6.48C876.57,365.78,875.48,343.62,899.51,338.89Zm19.77-179.37c4.28,11.21,23,15.2,34.5,15.76,12.89.64,34.23-1.43,42.89-12.47,7.71-9.83.36-19.21-10.18-24.12-11.75-5.47-32.06-6-44.47-3C931.36,138.27,914.28,146.45,919.28,159.52Z' style='fill:#fff;opacity:0.2'/><path id='Outline' d='M857.92,354.71c-56.16-47.19-49.42-140.27,0-188l2-1.92c58.28-54.44,150.84-58.11,209.81,7.25,44.07,48.85,43.72,140-4.26,182.63M858.17,424.23h204.54c8.45-4.92,14.82-13.06,17.14-24.86,5-25.34-9.34-44.34-36.34-55.33-25.27-10.3-67.12-12.32-83.07-12.32s-57.81,2-83.07,12.32c-27,11-41.34,30-36.34,55.33C843.35,411.17,849.72,419.31,858.17,424.23Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"  
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
                ( "2Balls",
                    string(abi.encodePacked(
                      "<defs><linearGradient id='linear-gradient' x1='960' y1='424.14' x2='960' y2='232.92' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='0.5'/><stop offset='0.14' stop-opacity='0.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g id='_4-HelmetBig' data-name='4-HelmetBig'><g id='_2Ball' data-name='2Ball'><path id='GB-03-Solid' d='M775.22,233a88.37,88.37,0,0,1,77.14,49.71c14.15,28.63,13.84,63.79-2,91.68-24,42.19-81.5,63.52-125.54,40.14-35.17-18.68-55.5-61.27-49.32-100.4a91.13,91.13,0,0,1,19.26-42.68C714,247.46,744.36,232.12,775.22,233Zm302.52,38.45a91.13,91.13,0,0,0-19.26,42.68c-6.18,39.13,14.15,81.72,49.32,100.4,44,23.38,101.54,2.05,125.54-40.14,15.86-27.89,16.17-63.05,2-91.68A88.37,88.37,0,0,0,1158.22,233C1127.36,232.12,1097,247.46,1077.74,271.41Z' style='fill:#",
                        PRIMARY,
                        "'/><path id='Grad' d='M775.22,233a88.37,88.37,0,0,1,77.14,49.71c14.15,28.63,13.84,63.79-2,91.68-24,42.19-81.5,63.52-125.54,40.14-35.17-18.68-55.5-61.27-49.32-100.4a91.13,91.13,0,0,1,19.26-42.68C714,247.46,744.36,232.12,775.22,233Zm302.52,38.45a91.13,91.13,0,0,0-19.26,42.68c-6.18,39.13,14.15,81.72,49.32,100.4,44,23.38,101.54,2.05,125.54-40.14,15.86-27.89,16.17-63.05,2-91.68A88.37,88.37,0,0,0,1158.22,233C1127.36,232.12,1097,247.46,1077.74,271.41Z' style='fill:url(#linear-gradient)'/><path id='Shad' d='M1232.66,375.5c-38.88,66.71-141.38,64.67-168.35-11.17C1101.8,418.11,1188,416.78,1232.66,375.5ZM721,396.4a103,103,0,0,1-39.73-32.07c27,75.87,129.49,77.84,168.35,11.17C817,404.32,763.58,415.89,721,396.4Z' style='opacity:0.2'/><path id='Hi' d='M1193.39,297.32c-5.85-7.23-10.58-19.15-2.2-24.38,11.22-7,26.35,11.41,26.56,22.42C1218.08,312,1201.94,307.88,1193.39,297.32Zm-117.8-23.12a92.52,92.52,0,0,0-14.74,29.35c17.07-61,138.49-99.9,180.57-5.4h0C1218.66,221,1121.21,212.24,1075.59,274.2Zm-383,0a92.52,92.52,0,0,0-14.74,29.35c17.07-61,138.49-99.9,180.57-5.4C835.66,221,738.21,212.24,692.59,274.2Zm142.16,21.16c-.21-11-15.34-29.4-26.56-22.42-8.38,5.23-3.65,17.15,2.2,24.38C818.94,307.88,835.08,312,834.75,295.36Z' style='fill:#fff;opacity:0.2'/><path id='Outline' d='M775.22,233a88.37,88.37,0,0,1,77.14,49.71c14.15,28.63,13.84,63.79-2,91.68-24,42.19-81.5,63.52-125.54,40.14-35.17-18.68-55.5-61.27-49.32-100.4a91.13,91.13,0,0,1,19.26-42.68C714,247.46,744.36,232.12,775.22,233Zm302.52,38.45a91.13,91.13,0,0,0-19.26,42.68c-6.18,39.13,14.15,81.72,49.32,100.4,44,23.38,101.54,2.05,125.54-40.14,15.86-27.89,16.17-63.05,2-91.68A88.37,88.37,0,0,0,1158.22,233C1127.36,232.12,1097,247.46,1077.74,271.41Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
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