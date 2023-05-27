// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract buyMeCoffee {
    event donatedCoffee(address indexed donor, uint256 indexed amount);
    address private immutable i_owner;
    struct Message {
        string note;
        uint256 amount;
    }

    constructor() {
        i_owner = msg.sender;
    }

    mapping(address => Message) donors;
    modifier isOwner() {
        require(msg.sender == i_owner);
        _;
    }

    function buyCoffee(string memory message,uint256 amount) public payable {
        (payable(address(this))).transfer(amount);
        donors[msg.sender].amount = amount;
        donors[msg.sender].note = message;
        emit donatedCoffee(msg.sender, amount);
    }

    function takeDonation() public payable isOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function owner() public view returns (address) {
        return i_owner;
    }
}