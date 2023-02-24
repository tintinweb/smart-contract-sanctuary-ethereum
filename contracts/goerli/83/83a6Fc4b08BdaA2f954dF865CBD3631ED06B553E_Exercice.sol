/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Exercice {

    string lastName;
    string firstName;
    address ethereumAddress;

    function setLastName(string memory _lastName) public {
        lastName = _lastName;
    }

    function setFirstName(string memory _firstName) public {
        firstName = _firstName;
    }

    function setEthereumAddress() public {
        ethereumAddress = msg.sender;
    }

    function getLastName() view public returns (string memory) {
        return lastName;
    }

    function getFirstName() view public returns (string memory) {
        return firstName;
    }

    function getEthereumAddress() view public returns (address) {
        return ethereumAddress;
    }

}