/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SmartContract {

    uint number;
    address account1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    struct Person {
        string name;
        address adresa;
    }
    Person public viktor = Person("viktor",0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db);

    constructor(uint _number) payable {
        number = _number;
    }

    function withdraw(uint amount) public payable {
        payable (msg.sender).transfer(amount * 10**18);
    }

    function deposit() public payable {}
}