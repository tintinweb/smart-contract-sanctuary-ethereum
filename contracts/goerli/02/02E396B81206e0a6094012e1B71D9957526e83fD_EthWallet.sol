/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract EthWallet {
    address payable owner;
    string name;

    constructor(string memory _name) {
        owner = payable(msg.sender);
        name = _name;
    }

    function withdraw() external {
        uint bal = address(this).balance;
        owner.transfer(bal);
    }

    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    function editName(string memory _newName) external {
        name = _newName;
    }

    function getName() external view returns (string memory) {
        return name;
    }

    event Receipt(uint value);

    receive() external payable {
        emit Receipt(msg.value);
    }
}