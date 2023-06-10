/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract actividadContract {
    string private greeting;
    address private owner;

    event GreetingChanged(address indexed _address, string _oldGreeting, string _newGreeting);
    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el owner puede llamar a esta funcion.");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Address invalida.");
        _;
    }

    constructor() {
        greeting = "Hello Ethereum";
        owner = msg.sender;
    }

    function cambiarGreeting(string memory _newGreeting) public onlyOwner {
        emit GreetingChanged(msg.sender, greeting, _newGreeting);
        greeting = _newGreeting;
    }

    function cambiarOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    function getGreeting() public view returns (string memory) {
        return greeting;
    }

    function getOwner() public view returns (address) {
        return owner;
    }
}