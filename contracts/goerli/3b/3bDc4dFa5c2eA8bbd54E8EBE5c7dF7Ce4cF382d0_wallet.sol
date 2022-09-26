// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract wallet {
    address payable public owner;

    constructor()  {

        owner = payable(msg.sender);
    }

    receive() external payable{}

    function withdraw(uint _amount) external {

        require(msg.sender == owner, "You aren't the owner");
        payable(msg.sender).transfer(_amount);

    }
}