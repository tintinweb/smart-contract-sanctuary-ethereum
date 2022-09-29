// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Lock {
    address public admin;

    constructor() payable {
        admin = msg.sender;
    }

    receive() external payable {}

    function adminBalanceOf() public view returns (uint) {
        return address(admin).balance;
    }

	function userBalanceOf(address to) public view returns (uint) {
        return address(to).balance;
    }

    function transfer(address to) public {
        payable(to).transfer(0.001 ether);
    }
}