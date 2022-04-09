// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "Strings.sol";
import "SafeCast.sol";

    /// @title Accessory SVG generator
    contract BaseBean {
        uint256 public libraryCount = 2;
        /// @dev Accessory N°1 => Classic


        function getBackground(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory)
            {
            return
                (
                    string(
                    abi.encodePacked(
                        "<defs><linearGradient id='background' x1='960' x2='960' y2='1920' gradientUnits='userSpaceOnUse'><stop offset='.2'/><stop offset='.75' stop-color='#",
                            PRIMARY,
                            "'/><stop offset='1' stop-color='#",
                            SECONDARY,
                            "'/></linearGradient></defs><path style='fill:url(#background)' data-name='0-Background' d='M0 0h1920v1920H0z'/>"
                            )
                        )
                );
            }


        
        function getBody(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory)
            {
            return
                ( 
                    string(
                    abi.encodePacked(
                        "<defs><radialGradient id='a-body' cx='960' cy='1800.52' r='204.9' gradientTransform='matrix(0 -1 1.48 0 -1706.3 2770.52)' gradientUnits='userSpaceOnUse'><stop offset='.1' stop-color='#",
                        PRIMARY,
                        "'/><stop offset='.85' stop-color='#00000'/><stop offset='1' stop-color='#",
                        SECONDARY,
                        "'/></radialGradient><radialGradient id='b-body' cx='960' cy='1559.52' r='204.9' gradientTransform='matrix(0 -1 1.48 0 -1349.42 2519.52)' xlink:href='#a-body'/></defs><g data-name='2-Body'><g data-name='2-Body-Highlight'><rect data-name='2-Body-Bot' x='666.51' y='1671.69' width='586.98' height='251.32' rx='125.66' transform='rotate(-180 960 1797.35)' style='fill:url(#a-body)'/><rect data-name='2-Body-Top' x='666.51' y='1420.69' width='586.98' height='251.32' rx='125.66' style='fill:url(#b-body)'/></g><path d='M792.17 1671.85c-69.11 0-125.66 56.39-125.66 125.5h0c0 69.11 56.55 125.66 125.66 125.66h335.66c69.11 0 125.66-56.55 125.66-125.66h0c0-69.11-56.55-125.48-125.66-125.48h0c69.11 0 125.66-56.41 125.66-125.52h0c0-69.11-56.55-125.66-125.66-125.66H792.17c-69.11 0-125.66 56.55-125.66 125.66h0c0 69.11 56.55 125.5 125.66 125.5h335.66' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"
                        )
                        )
                );
            }

        function getBigHead(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory)
            {
            return
                (
                    string(
                    abi.encodePacked(
                    "<defs><radialGradient id='a' cx='960' cy='922.3' r='825.16' gradientTransform='matrix(1 0 0 .7 0 276.69)' gradientUnits='userSpaceOnUse'><stop offset='.1' stop-color='#",
                        PRIMARY,
                        "'/><stop offset='.85' stop-color='#00000'/><stop offset='1' stop-color='#",
                        SECONDARY,
                        "'/></radialGradient></defs><g data-name='1-HeadBig'><rect x='193.87' y='424.23' width='1532.26' height='996.14' rx='498.07' style='fill:url(#a)'/><path d='M1228.06 1420.37H691.94c-273.94 0-498.07-224.13-498.07-498.07h0c0-273.94 224.13-498.07 498.07-498.07l536.12-.54c273.94 0 498.07 224.67 498.07 498.61h0c0 273.94-224.13 498.07-498.07 498.07Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"
                        )
                        )
                );
            }

        function getSmallHead(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory)
            {
            return
                ( 
                    string(
                    abi.encodePacked(
                         "<defs><radialGradient id='radial-gradient' cx='958' cy='968.96' r='458.4' gradientTransform='translate(0 -96.9) scale(1 1.1)' gradientUnits='userSpaceOnUse'><stop offset='0.2' stop-color='#",
                        PRIMARY,
                        "'/><stop offset='0.85' stop-color='#00000'/><stop offset='1' stop-color='#",
                        SECONDARY,
                        "'/></radialGradient></defs><g id='_1-HeadSmall' data-name='1-HeadSmall'><path id='Small' d='M960,505.61c-253.71,0-459.38,205.67-459.38,459.38,0,233.09,173.6,425.62,398.56,455.38h121.64c225-29.76,398.56-222.29,398.56-455.38C1419.38,711.28,1213.71,505.61,960,505.61Z' style='fill:url(#radial-gradient)'/><circle id='Outline' cx='960' cy='964.99' r='459.38' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"

                         )
                        )
                );
            }



        function getGearCount() public view returns (uint256 ) {
                return libraryCount;

        }



        function getSize(string memory classOne, string memory classTwo, uint256 sizeId) public pure returns (string memory) {

                if (sizeId > 0) {
                    return(getBigHead(classOne, classTwo));
                } else {
                    return(getSmallHead(classOne, classTwo));
                }

        }

        function getBaseSvg(string memory classOne, string memory classTwo, uint256 sizeId) public pure returns (string memory ) {
            
            string memory size = getSize(classOne, classTwo, sizeId);
            string memory background = getBackground(classOne, classTwo);
            string memory body = getBody(classOne, classTwo);

            return string(abi.encodePacked('<svg id="Bean-Blueprint" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 1920 1920">', background , size, body));


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