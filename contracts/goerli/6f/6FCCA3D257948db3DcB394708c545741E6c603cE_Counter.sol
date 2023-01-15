//SPDX-License-Identifier: MIT


pragma solidity 0.8.17;


contract Counter{
    uint count = 0;

    function counter() public{
        count++;
    }
    function getCount() public view returns(uint){
        return count;
    }
}