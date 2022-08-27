/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

interface IToHack {
    function enter(bytes8 _gateKey) external;
}

contract Hack {
    IToHack public constant receiver = IToHack(0x6c9a66450B7356e23391ba8E0E58C920D2b06cd6);

    constructor() {
        /*uint256 gas = gasleft() - 20000;
        gas -= gas % 8191;
        require(gas > 1000000, "No enough gas");
        gas += 
        bytes8 value = bytes8(
            uint64(
                uint16(
                    uint160(msg.sender)
                )
            ) + 2**63
        );*/
        //receiver.enter{ gas: gas }(value);
    }

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }


    uint256 x;
    function test() external gateOne gateTwo {
        x = 1;
    }

    event Found(uint256 value);
    function test2(uint256 from, uint256 to) external {
        /*uint256 gas = gasleft() - 100000;
        gas -= gas % 8191;
        require(gas > 1000000, "No enough gas1");*/
        //gas += add;
        for(uint256 i = from; i < to; ++i) {
            uint256 gas = gasleft() - 100000;
            gas -= gas % 8191;
            require(gas > 1000000, "No enough gas1");

            (bool success,) = address(this).call(abi.encodeWithSelector(Hack.test.selector));
            if (success) {
                emit Found(i);
                return;
            }
        }
    }
}