/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract Arr {
    uint[] array;
    string[] NameArray;

    function pushNameArray(string memory _n) public {
        NameArray.push(_n);
    }

    function getNameArray(uint _n) public view returns(string memory) {
        return NameArray[_n-1];
    }

    function nameArrayLength() public view returns(uint) {
        return NameArray.length;
    }

}