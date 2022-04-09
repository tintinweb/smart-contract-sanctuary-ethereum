// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

pragma abicoder v2;

import "Strings.sol";
import "SafeCast.sol";


    
    /// @title Accessory SVG generator
    contract bigHelmet1 {
        uint256 public libraryCount = 2;
        /// @dev Accessory N°1 => Classic
        function gearSvg0(
            string memory PRIMARY,
            string memory SECONDARY
        ) internal pure returns (string memory, string memory)
            {
            return
                ( "2Buns",
                    string(
                    abi.encodePacked(
                        "<defs><linearGradient id='a' x1='960' y1='425.23' x2='960' y2='122.52' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.5'/><stop offset='.14' stop-opacity='.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g data-name='4-HelmetBig'><g data-name='2Buns'><path d='M664.69 353.71c-56.16-47.19-49.42-140.27 0-188l2-1.92c58.28-54.44 150.84-58.11 209.81 7.25 44.07 48.85 43.72 140-4.26 182.63Zm383 0c-48-42.67-48.33-133.78-4.26-182.63 59-65.36 151.53-61.69 209.81-7.25l2 1.92c49.42 47.69 56.16 140.77 0 188Z' style='fill:#",
                            PRIMARY,
                            "'/><path d='M1253.43 424.23s-188.26.34-198.73 1c-10.4-4.57-18.43-13.29-21.11-26.87-5-25.34 9.34-44.34 36.34-55.33 25.27-10.29 67.12-12.32 83.07-12.32s57.81 2 83.07 12.32c27 11 41.34 30 36.35 55.33-2.5 12.64-9.63 21.08-18.99 25.87Zm-586.3.28c5.45-.18 200.29-.28 200.29-.28 9.37-4.79 16.5-13.21 19-25.86 5-25.34-9.34-44.34-36.34-55.33C824.8 332.75 783 330.72 767 330.72s-57.81 2-83.07 12.32c-27 11-41.34 30-36.35 55.33 2.55 12.9 9.91 21.4 19.55 26.14Z' style='fill:#",
                            SECONDARY,
                            "'/><path d='M1255.45 353.71c11.39 7.35 20 26.69 16.89 44.66-2.23 12.67-9.38 21.08-18.8 25.86 0 0-188.39.34-198.84 1-10.37-4.57-18.37-13.3-21.19-26.86-4-19.33 2-33.33 15.35-43.66-50-45-49.33-134.78-5.25-183.63 59-65.36 151.52-61.69 209.81-7.25l2 1.92c49.44 47.69 56.18 140.77.03 187.96Zm-590.9 0c-11.39 7.35-20 26.69-16.89 44.66 2.28 12.93 9.67 21.42 19.37 26.15 5.5-.19 200.37-.29 200.37-.29 9.34-4.79 16.47-13.23 19.09-25.86 4-19.33-2-33.33-15.35-43.66 50-45 49.33-134.78 5.25-183.63-59-65.36-151.52-61.69-209.81-7.25l-2 1.92c-49.44 47.69-56.18 140.77-.03 187.96Z' style='fill:url(#a)'/><path d='M1255.24 353.71c-38.82-29.79-161.27-30.21-203-.62a50.61 50.61 0 0 1 5.69-4.34 67.28 67.28 0 0 0-9.43 6.65c-30.29-26.72-40.24-72.74-36.07-112.86-2.48 63.64 96 76 140.69 76 42.08 0 147-10.51 140.22-75.35 4.23 40.29-3.34 80.32-38.1 110.52Zm-205.79 2-.34-.31c-12.88 10.91-18.7 25.42-15.24 43 2.67 13.58 10.7 22.3 21.11 26.87 10.47-.67 198.72-1 198.72-1 9.37-4.79 16.5-13.21 19-25.86 4.22-21.39-5.34-38.26-24.67-49.62 13.2 8.66 19.31 20.42 15.94 34.8-4 17.31-21.28 24.51-39.76 24-11.27-.31-32.48-4.56-70.92-4.56s-59.65 4.25-70.92 4.56c-18.48.5-35.71-6.7-39.76-24-2.84-12.11 1.07-22.35 10.25-30.46-1.21.81-2.35 1.68-3.41 2.58Zm-181.74-2.62c9.17 8.11 13.08 18.35 10.25 30.46-4.05 17.31-21.28 24.51-39.76 24-11.27-.31-32.48-4.56-70.92-4.56s-59.65 4.25-70.93 4.56c-18.47.5-35.71-6.7-39.76-24-3.36-14.38 2.75-26.14 15.94-34.8-19.32 11.36-28.88 28.23-24.67 49.62 2.54 12.9 9.91 21.4 19.55 26.14 5.44-.18 200.29-.28 200.29-.28 9.36-4.79 16.5-13.21 19-25.86 3.46-17.55-2.36-32.06-15.24-43l-.35.31c-1.11-.87-2.21-1.74-3.4-2.59Zm-203 .62c38.82-29.79 161.27-30.21 203-.62a50.61 50.61 0 0 0-5.69-4.34 67.28 67.28 0 0 1 9.43 6.65c30.29-26.72 40.24-72.74 36.07-112.86 2.48 63.64-96 76-140.69 76-42.08 0-147-10.51-140.22-75.35-4.18 40.29 3.39 80.32 38.15 110.52Z' style='opacity:.2'/><path d='M706.28 337.89a293.19 293.19 0 0 1 60.78-5.83c11.32.06 36.45 1.66 61.92 6.29 25.22 4.58 18.93 26.6-5.88 21.31-38.34-8.17-76.23-6.6-114.59.48-25.17 4.64-26.27-17.52-2.23-22.25ZM726 158.52c4.29 11.21 23 15.2 34.51 15.76 12.89.64 34.23-1.43 42.89-12.47 7.7-9.83.35-19.21-10.18-24.12-11.75-5.47-32.06-6-44.47-3-10.62 2.58-27.7 10.76-22.75 23.83Zm485.45 201.62c-38.36-7.08-76.25-8.65-114.59-.48-24.81 5.29-31.1-16.73-5.88-21.31 25.47-4.63 50.6-6.23 61.92-6.29a293.19 293.19 0 0 1 60.78 5.83c24.08 4.73 22.98 26.89-2.19 22.25Zm-40.28-225.46c-12.41-3-32.72-2.46-44.47 3-10.53 4.91-17.88 14.29-10.18 24.12 8.66 11 30 13.11 42.89 12.47 11.5-.56 30.22-4.55 34.51-15.76 5.08-13.06-12.05-21.24-22.71-23.83Z' style='fill:#fff;opacity:.2'/><path d='M664.69 353.71c-56.16-47.19-49.42-140.27 0-188l2-1.92c58.28-54.44 150.84-58.11 209.81 7.25 44.07 48.85 43.72 140-4.26 182.63m175.46 0c-48-42.67-48.33-133.78-4.26-182.63 59-65.36 151.53-61.69 209.81-7.25l2 1.92c49.42 47.69 56.16 140.77 0 188m16.9 44.66c5-25.34-9.35-44.34-36.35-55.33-25.26-10.29-67.12-12.32-83.07-12.32s-57.8 2-83.07 12.32c-27 11-41.33 30-36.34 55.33 2.68 13.58 10.71 22.3 21.11 26.87 10.47-.67 198.73-1 198.73-1 9.42-4.8 16.55-13.24 19.05-25.87Zm-604.81 26.14c5.45-.18 200.29-.28 200.29-.28 9.37-4.79 16.5-13.21 19-25.86 5-25.34-9.34-44.34-36.34-55.33-25.27-10.29-67.12-12.32-83.07-12.32s-57.81 2-83.07 12.32c-27 11-41.34 30-36.35 55.33 2.54 12.9 9.9 21.4 19.54 26.14Z' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g></g>"
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
                ( "Agro",
                    string(abi.encodePacked(
                       "<defs><linearGradient id='a-helmet' x1='960' y1='902.28' x2='960' y2='317.76' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.5'/><stop offset='1' stop-opacity='0'/></linearGradient><linearGradient id='b-gear' x1='960' y1='1211.87' x2='960' y2='72.33' gradientUnits='userSpaceOnUse'><stop offset='0' stop-opacity='.5'/><stop offset='.14' stop-opacity='.23'/><stop offset='1' stop-opacity='0'/></linearGradient></defs><g data-name='4-HelmetBig'><path d='M1227.74 317.76c170.68 25.68 400.07 142.82 446.91 216.44 46.59 73.23 31.23 111.56-10.05 149.48s-393.37 218.6-704.6 218.6-663.33-180.67-704.6-218.6-56.64-76.25-10.05-149.48c46.84-73.62 276.23-190.76 446.91-216.44Z' style='fill:#",
                            PRIMARY,
                            "'/><path d='M828.2 555.07c-55.2-67.26-97.43-136.91-126.87-205.38-29-67.42 20.5-97.74 79.27-117.31 21.52-7.16 37.23-11 54.66-39.8 14.77-24.42 28.39-44.23 47.2-70.05C906 90.26 934.34 72.33 960 72.33s54 17.93 77.54 50.2c18.81 25.82 32.43 45.63 47.2 70.05 17.43 28.83 33.14 32.64 54.66 39.8 58.77 19.57 108.26 49.89 79.27 117.31-29.44 68.47-71.7 138.12-126.87 205.38-38.68 47.14-69.07 79.48-129.31 79.48s-95.61-32.34-134.29-79.48ZM231.63 658c-22.31 38-81.11 140.6-55.76 295.65 24.38 149.05 115.24 230.91 179.94 253.22 50.68 17.47 87.72-11.65 127.16-73.64 78.08-122.71 123.56-291.55 123.56-291.55C437.36 780.89 302.9 734.24 231.63 658Zm1083 183.3S1359 1010.52 1437 1133.23c39.44 62 76.48 91.11 127.16 73.64 64.7-22.31 155.56-104.17 179.94-253.22 25.35-155-33.45-257.69-55.76-295.62-48.7 57.32-152.21 105.32-373.74 183.3Z' style='fill:#",
                            SECONDARY,
                            "'/><path data-name='Grad' d='M1227.74 317.76c170.68 25.68 400.07 142.82 446.91 216.44 46.59 73.23 31.23 111.56-10.05 149.48s-393.37 218.6-704.6 218.6-663.33-180.67-704.6-218.6-56.64-76.25-10.05-149.48c46.84-73.62 276.23-190.76 446.91-216.44Z' style='opacity:.30000000000000004;fill:url(#a-helmet)'/><path data-name='Grad' d='M828.2 555.07c-55.2-67.26-97.43-136.91-126.87-205.38-29-67.42 20.5-97.74 79.27-117.31 21.52-7.16 37.23-11 54.66-39.8 14.77-24.42 28.39-44.23 47.2-70.05C906 90.26 934.34 72.33 960 72.33s54 17.93 77.54 50.2c18.81 25.82 32.43 45.63 47.2 70.05 17.43 28.83 33.14 32.64 54.66 39.8 58.77 19.57 108.26 49.89 79.27 117.31-29.44 68.47-71.7 138.12-126.87 205.38-38.68 47.14-69.07 79.48-129.31 79.48s-95.61-32.34-134.29-79.48ZM231.63 658c-22.31 38-81.11 140.6-55.76 295.65 24.38 149.05 115.24 230.91 179.94 253.22 50.68 17.47 87.72-11.65 127.16-73.64 78.08-122.71 116.95-270.91 116.95-270.91C430.75 801.54 302.9 734.24 231.63 658Zm1088.45 204.32s38.87 148.2 117 270.91c39.44 62 76.48 91.11 127.16 73.64 64.7-22.31 155.56-104.17 179.94-253.22 25.35-155-33.45-257.69-55.76-295.62-48.78 57.32-146.82 126.31-368.34 204.29Z' style='fill:url(#b-gear)'/><path d='M875.54 322.61c25.28-24.55-20.83-49.08-2.13-102.59 10.45-29.93 19.71-54.32 32.76-86 16.31-39.63-.21-43.73-23.71-11.46-18.81 25.82-32.43 45.62-47.2 70.05-10.94 18.1-23.58 29.89-43.86 36.56-24.8 8.16-57.71 18.57-82.45 41.42-19.33 17.85-15.69 47-16.81 47.2l-12.13 2c-7.93 42.64 75.21 170.72 133.32 245.89 40.73 52.69 85.73 92.29 149.17 92.29s104.25-41 145-93.68c58.12-75.17 139.74-201.75 132.8-244.4l-12.65-2.09c1.21-14-3.25-24.44-8.43-34.44 11.66 39.51-72.35 157.47-127.52 217.11-38.68 41.81-69.07 70.49-129.31 70.49s-95.61-28.68-134.28-70.49c-21.6-23.34-41.76-48.11-59.07-74.82-15.81-24.39-35.69-55.16-39.92-84.43-3.51-24.2 13.61-45 37.29-49.72 11.39-2.25 22.56 4 31.62 10.21 18.51 12.77 55.2 42.55 77.51 20.9ZM1688.26 658l5.61 9.58c-17.78 43-138.76 121.89-334.48 185.12 19.86 68.55 98.59 318.66 173.38 360.06 0 0-22.8 17.25-60.15-7.62-76.3-50.82-146-221.43-173.35-302.79-70.81 16.93-250.7 27.53-339.39 27.79-89.4.27-269.08-9.65-339.27-26-26.47 82.46-104.29 254.21-173.13 300.8-36.92 25-62.42 7.06-62.42 7.06 79-52.93 151.33-292.1 169.6-359-186.17-60.91-300.37-135.13-328.78-185l5.63-10c-13.85-26.82-21.48-49.86-5.11-88.71-2.59 29.3 12.87 51 38.06 72.63 41 35.1 386.62 216.83 695.42 216.83S1614.35 677.05 1655.3 642c25.19-21.59 40.65-43.32 38.07-72.62 16.48 39.08 9.37 66.19-5.11 88.62Z' style='opacity:.2'/><path d='M1746.71 837.27c6.12 43.37-.59 167-56.41 255.27-21.8 34.47-43.08 24.19-24.23-11.41 48.65-91.84 54.44-177 54.65-234.92.11-30.64 19.93-51.83 25.99-8.94Zm-1572.94 4.94c-6.33 42.7-.26 164.24 55 250.81 21.58 33.79 42.89 23.58 24.25-11.35-48.11-90.09-53.45-173.84-53.37-230.8.07-30.14-19.65-50.87-25.88-8.66Zm936.45-601.53c-39.87-10.1-46.15-32.25-80.73-94.72-14.79-26.7-36.54-19.92-27.35 9.81 17.31 56 42.21 100.16 70.86 114 34.59 16.74 69.83-20.83 37.22-29.09ZM988.56 91.05c-25.39-11.35-21.36 32.71 5.52 29.65 10.76-1.7 10.9-13 5.63-20.09-5.06-6.8-3.52-6.15-11.15-9.56Z' style='fill:#fff;opacity:.2'/><path d='M828.2 555.07c-55.2-67.26-97.43-136.91-126.87-205.38-29-67.42 20.5-97.74 79.27-117.31 21.52-7.16 37.23-11 54.66-39.8 14.77-24.42 28.39-44.23 47.2-70.05C906 90.26 934.34 72.33 960 72.33s54 17.93 77.54 50.2c18.81 25.82 32.43 45.63 47.2 70.05 17.43 28.83 33.14 32.64 54.66 39.8 58.77 19.57 108.26 49.89 79.27 117.31-29.44 68.47-71.7 138.12-126.87 205.38-38.68 47.14-69.07 79.48-129.31 79.48s-95.61-32.34-134.29-79.48Zm399.54-237.31c170.68 25.68 400.07 142.82 446.91 216.44 46.59 73.23 31.23 111.56-10.05 149.48s-393.37 218.6-704.6 218.6-663.33-180.67-704.6-218.6-56.64-76.25-10.05-149.48c46.84-73.62 276.23-190.76 446.91-216.44M231.63 658c-22.31 38-81.11 140.6-55.76 295.65 24.38 149.05 115.24 230.91 179.94 253.22 50.68 17.47 87.72-11.65 127.16-73.64 78.08-122.71 116.95-270.91 116.95-270.91m720.16 0s38.87 148.2 117 270.91c39.44 62 76.48 91.11 127.16 73.64 64.7-22.31 155.56-104.17 179.94-253.22 25.35-155-33.45-257.69-55.76-295.62' style='fill:none;stroke:#000;stroke-linecap:round;stroke-linejoin:round;stroke-width:4px'/></g>"
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