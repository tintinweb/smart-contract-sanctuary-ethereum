/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
 
pragma solidity >=0.8.0 <0.9.0;

contract Counter {
 
    event Increment (
        address indexed sender,
        uint256 oldVal,
        uint256 newVal
    );
 
    uint256 private counter;
 
    function increment() public {
        emit Increment(msg.sender,counter,counter + 1);
        counter++;
    }
 
    function read() public view returns (uint256) {
        return counter;
    }
   
}