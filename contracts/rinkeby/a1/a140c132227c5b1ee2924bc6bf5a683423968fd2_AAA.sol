/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract AAA {
    string[] sarray;
    uint[] array;

    function pushName(string memory s) public {
        sarray.push(s);
    }

    function getString(uint _n) public view returns(string memory) {
        return sarray[_n-1];
    }

    function getArrayLength() public view returns(uint) {
        return sarray.length;
    }

    function lastNumber() public view returns(uint) {
        return array[array.length-1];
    }

}