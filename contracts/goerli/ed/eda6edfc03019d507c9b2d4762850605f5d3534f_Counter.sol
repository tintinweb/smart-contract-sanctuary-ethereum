/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Counter{
    uint public counter;

    constructor(){
        counter = 0;
    }
    function incr() public{
        counter = counter+1;
    }

    function addX(uint x) public{
        counter = counter+x;
    }

    function read() public view returns(uint){
        return counter;
    }
}