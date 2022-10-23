// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Counter {
    uint256 counter;

    constructor(){
        counter = 10;
    }

    function incrementCounter() public view{
        counter + 1;
    }

    function getCounter() public view returns(uint256 ){
        return counter;
    }
}