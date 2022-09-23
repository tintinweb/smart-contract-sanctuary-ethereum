/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
//20220923
pragma solidity 0.8.0;

contract WHO {
    string[] array;

    function pushName(string memory _n) public {
        array.push(_n);
    }

    function getArrayLength() public view returns(uint) {
        return array.length;
    }

    function getName(uint _n) public view returns(string memory) {
        return array[_n-1];
    }
}