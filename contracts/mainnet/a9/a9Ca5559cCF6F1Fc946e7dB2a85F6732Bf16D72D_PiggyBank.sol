/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract PiggyBank {

    address payable internal owner;

    constructor () payable {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
       require(msg.sender == owner, "Try again, something went wrong");
       _;
    }

    // change Owner - the one who contributed the most to this PiggyBank is the owner
    function changeOwner() public payable {
        if(msg.value >= address(this).balance && msg.value >= 0.05 ether) {
            owner = payable(msg.sender);
        }
    }

    // withdraw onlyOwner
    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getCurrentBalance() public view returns (uint) {
        return address(this).balance;
    }

    function resolve() external onlyOwner {
        selfdestruct(owner);
    }

    // fallback
    fallback() external payable {}
    receive() external payable {}
}