// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.0;

library Stringhelper {

    function stringCompare(string memory a, string memory b) public pure returns(bool) {

        if (keccak256(bytes(a)) == keccak256(bytes(b)))
            return true;
        else
            return false;

    }

    
    function concate(string memory a, string memory b, bool hasBlank) public pure returns(string memory) {

        string memory concateStr;
        if (hasBlank)
            concateStr = string(abi.encodePacked(a, " ", b));
        else
            concateStr = string(abi.encodePacked(a, b));
        return concateStr;

    }
    
}