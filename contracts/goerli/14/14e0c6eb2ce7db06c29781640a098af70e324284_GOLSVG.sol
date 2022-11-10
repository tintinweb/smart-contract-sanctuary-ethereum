/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT
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


// File contracts/GOLSVG.sol

// License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract GOLSVG {
    uint256 constant W = 8;
    uint256 constant H = 8;
    uint256 constant CELL_W = 10;
    uint256 constant CELL_H = 10;
    uint256 constant TEMPLATE_COUNT = 19;
    uint256 constant END_TEMPLATE_COUNT = 19;

    using Strings for uint256;

    string constant SVG_A = '<svg viewBox="0 0 100 100">';
    string constant SVG_B = '</svg>';

    function svg(uint256 n, uint256 data) external pure returns (string memory) {
        return string.concat(
            SVG_A,
            defs(),
            uses(n, data),
            text(n),
            SVG_B
        );
    }

    string constant TEXT_A = '<text font-family="monospace"text-anchor="middle"x="50"y="100"width="100"font-size="8">#';
    string constant TEXT_B = '</text>';

    function text(uint256 n) public pure returns (string memory) {
        return string.concat(
            TEXT_A,
            n.toString(),
            TEXT_B
        );
    }
    
    function defs() public pure returns (string memory) {
        return '<defs><rect id="r0"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/></rect><rect id="r1"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/></rect><rect id="r2"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r3"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/></rect><rect id="r4"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/></rect><rect id="r5"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r6"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r7"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/></rect><rect id="r8"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r9"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/></rect><rect id="r10"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/></rect><rect id="r11"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/></rect><rect id="r12"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r13"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r14"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/></rect><rect id="r15"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/></rect><rect id="r16"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/></rect><rect id="r17"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/></rect><rect id="r18"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/></rect><rect id="e0"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e1"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e2"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e3"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e4"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e5"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e6"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e7"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e8"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e9"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e10"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e11"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e12"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e13"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e14"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e15"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.4s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e16"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.0s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="2.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="2.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e17"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.8s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.0s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect><rect id="e18"width="10"height="10"fill="#fff"stroke="#111"><animate attributename="fill"to="#7232f2"dur="0.2s"begin="0.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="0.6s"fill="freeze"/><animate attributename="fill"to="#7232f2"dur="0.2s"begin="1.2s"fill="freeze"/><animate attributename="fill"to="#fff"dur="0.2s"begin="1.4s"fill="freeze"/><animate attributename="fill"to="#111"dur="0.4s"begin="2.4s"fill="freeze"/></rect></defs>';
    }
    
    string constant USES_A='<use id="';
    string constant USES_B='"x="';
    string constant USES_C='"y="';
    string constant USES_D='"href="#';
    string constant USES_E='"/>';

    function uses(uint256 n, uint256 data) public pure returns (string memory returnVal) {
        uint256 rnd = uint256(keccak256(abi.encodePacked(n, data)));
        uint256 i = 0;
        
        for (uint256 x = 0; x < W; x++) {
            for (uint256 y = 0; y < H; y++) {
                returnVal = string.concat(
                    returnVal,
                    USES_A,
                    x.toString(),
                    "-",
                    y.toString(),
                    USES_B,
                    ((x + 1) * CELL_W).toString(),
                    USES_C,
                    ((y + 1) * CELL_H).toString(),
                    USES_D
                );

                bool isAlive = (data >> (y + x * H)) & 1 == 1;
                if (isAlive) {
                    returnVal = string.concat(
                        returnVal,
                        "e",
                        (((rnd >> i) & 255) % END_TEMPLATE_COUNT).toString(),
                        USES_E
                    );
                }
                else {
                    returnVal = string.concat(
                        returnVal,
                        "r",
                        (((rnd >> i) & 255) % TEMPLATE_COUNT).toString(),
                        USES_E
                    );
                }

                i++;
                i = i % 256;
            } 
        }
    }
}