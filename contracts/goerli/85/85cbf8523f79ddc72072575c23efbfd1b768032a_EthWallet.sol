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

    event Withdraw(address indexed User, address indexed Owner, uint Amount);

    function withdrawAll() external {
        uint bal = address(this).balance;
        owner.transfer(bal);
        emit Withdraw(msg.sender, owner, bal);
    }

    function withdraw(uint _amount) external {
        owner.transfer(_amount);
        emit Withdraw(msg.sender, owner, _amount);
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