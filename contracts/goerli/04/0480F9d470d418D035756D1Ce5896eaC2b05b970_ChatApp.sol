// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ChatApp {
    address owner;
    string message;
    event chat(address from, address to, string message);
    mapping(address => string) public addressToMessage;

    constructor() {
        owner = msg.sender;
        message = "Default";
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    function sendMess(address _to, string memory _mess) public onlyOwner {
        emit chat(msg.sender, _to, _mess);
        addressToMessage[_to] = _mess;
        message = _mess;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}