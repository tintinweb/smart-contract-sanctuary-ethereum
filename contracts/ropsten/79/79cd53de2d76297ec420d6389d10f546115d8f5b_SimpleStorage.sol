/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storeData;

    function set(uint x) public{
        storeData = x;
    }

    function get() public view returns(uint){
        return storeData;
    }

    //he
}