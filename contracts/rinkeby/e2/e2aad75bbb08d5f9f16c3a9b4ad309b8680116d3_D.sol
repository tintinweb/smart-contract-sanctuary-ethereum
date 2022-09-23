/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract D{
    string[] names;

    function push(string memory name)public{
        names.push(name);
    }

    function length()public view returns(uint){
        return names.length;
    }

    function showName(uint _n)public view returns(string memory){
        return names[_n];
    }
}