/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;


contract AAA {
    uint[] array; 
    string[] sarray;

    function Name(string memory s) public {
        sarray.push(s);
    }

    function getNumber(uint _n) public view returns(uint) {
        return array[_n-1];
    }

    function getString(uint _n) public view returns(string memory) {
        return sarray[_n-1];
    }

    function getArrayLength() public view returns(uint) {
        return array.length;
    }
}