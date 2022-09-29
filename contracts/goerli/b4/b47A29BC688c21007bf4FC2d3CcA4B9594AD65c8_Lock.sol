// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    // function pay() public payable{}
    address public admin;
    
    constructor() payable {
        admin = msg.sender;
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function transfer() public payable {
        payable(admin).transfer(0.1 ether);
    }
    
}