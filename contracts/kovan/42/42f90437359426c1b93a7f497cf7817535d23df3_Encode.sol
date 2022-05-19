/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Encode {
function encode(string memory _string1, uint _uint, string memory _string2) public pure returns (bytes memory) {
        return (abi.encode(_string1, _uint, _string2));
    }
function decode(bytes memory data) public pure returns (string memory _str1, uint _number, string memory _str2) {
        (_str1, _number, _str2) = abi.decode(data, (string, uint, string));            
    }
}