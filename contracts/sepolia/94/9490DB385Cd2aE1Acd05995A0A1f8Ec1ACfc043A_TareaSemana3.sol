/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract TareaSemana3 {

    string private greeting;
    address owner;


    constructor() {
        greeting = "Hello Ethereum";
        owner = msg.sender;
    }

    function getGreeting() public view returns(string memory) {
        return greeting;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    modifier ValidaOwner {
        require(owner == msg.sender, "No eres el owner de SC");
        _;
    }

    modifier ValidaDireccion(address _owner) {
        require(_owner != address(0), "No se puede utilizar un direccion vacia");
        _;
    }

    event infoChangeGreeting(address direccion, string oldGreeting, string newGreeting);

    function setGreeting(string memory _greeting) external ValidaOwner ValidaDireccion(msg.sender) {
        emit infoChangeGreeting(owner, greeting, _greeting);
        greeting = _greeting;
    }

    event infoChangeOwner(address oldOwner, address newOwner);

    function setOwner(address _owner) external ValidaOwner ValidaDireccion(msg.sender) {
        emit infoChangeOwner(owner, _owner);
        owner = _owner;
    }
}