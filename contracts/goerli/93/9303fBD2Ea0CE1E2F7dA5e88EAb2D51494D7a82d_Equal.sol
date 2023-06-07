/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.18;


contract Equal {
    function getStringNum(string memory _name) public pure returns(uint) {
        if(equal(_name, "hello")) {
            return 1;
        } else if (equal(_name, "hi")) {
            return 2;
        } else if (equal(_name, "move")) {
            return 3;
        } else {
            return 4;
        }
    }

    function equal(string memory str1, string memory str2) internal pure returns (bool) {
        //가스 최적화
         if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}