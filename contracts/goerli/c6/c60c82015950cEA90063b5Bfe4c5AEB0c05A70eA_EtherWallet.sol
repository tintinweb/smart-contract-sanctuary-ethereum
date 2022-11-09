// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract EtherWallet {
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;
    }

    function deposit() public payable {}

    function send(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    function balanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }
}