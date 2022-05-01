pragma solidity ^0.8.0;


contract RescueContract {
    string deployed;
    address owner;

    constructor() {
        deployed = "I'm ALive!";
        owner = msg.sender;
    }

    function withdraw() external {
        require(msg.sender == owner);
        uint256 balance = address(this).balance;
        address wallet = msg.sender;
        payable(wallet).transfer(balance);
    }
}