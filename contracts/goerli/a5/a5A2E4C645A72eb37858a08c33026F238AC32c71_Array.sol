// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

library Array {

    function includesAddress(address[] memory wallets, address wallet) public pure returns(bool) {
        for (uint i=0; i < wallets.length; i++) {
            if(wallets[i] == wallet) return true;
        }
        return false;
    }

    function includesNumber(uint[] memory numbers, uint number) public pure returns(bool) {
        for (uint i=0; i < numbers.length; i++) {
            if(numbers[i] == number) return true;
        }
        return false;
    }

    function includesString(string[] memory strs, string memory str) public pure returns(bool) {
        for (uint i=0; i < strs.length; i++) {
            if(keccak256(bytes(strs[i])) == keccak256(bytes(str))) return true;
        }
        return false;
    }
    
}