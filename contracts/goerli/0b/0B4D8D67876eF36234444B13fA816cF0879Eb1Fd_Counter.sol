// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract Counter{
    uint public counter;
    address public owner;
    constructor(){
        counter=0;
        owner=msg.sender;
    }

    function count() public {
        counter = counter + 1;
    }

    function add(uint x) external onlyOwner {
        counter = counter + x;
    }

    modifier onlyOwner(){
        require(msg.sender == owner,"this function is restricted to the owner");
        _; // will be replaced by the code of the function
    }
}