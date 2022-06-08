// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Rescue {
    
    address owner;

    constructor() {
      owner = msg.sender;   
   }

    function deposit() public payable {}

    function withdraw() external {
        require(msg.sender == owner);
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success);
    }
}