/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;


contract ZFHelloWorld {
    uint256 public count = 0;

    function toString(uint256 value) internal pure returns (string memory) {
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

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }

    function helloWorld() public view returns (string memory){
        return append("Hello, World! [", toString(count), "]");
    }

    function increment() public {
        count += 1;
    }

    function reset() public {
        count = 0;
    }

    function getCountPlusN(uint256 n) public view returns (uint256){
        return count + n;
    }
}