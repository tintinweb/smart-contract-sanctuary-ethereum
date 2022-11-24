/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage{
    uint myData;
    function setData(uint newData) public {
        myData = newData;
    }
    function getData() public view returns(uint) {
        return myData;
    }
}