// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    function pay() public payable{}

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function transfer(address to) public payable {
        payable(to).transfer(0.1 ether);
    }
    
}