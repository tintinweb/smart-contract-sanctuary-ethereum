/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract Hello{
    uint private num;

    function set(uint _num) public{
        num = _num;
    }

    function get() view  public returns(uint){
        return num;
    }
}