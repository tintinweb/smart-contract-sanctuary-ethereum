/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract EthWallet {
    // contract which can store ether for an owner

    address payable owner;
    string name;

    constructor(string memory _name) {
        owner = payable(msg.sender); //deployer
        name = _name;
    }

    function withdrawAll() external {
        uint bal = address(this).balance; //balance of contract
        owner.transfer(bal);
    }

    function withdraw(uint _val /*wei*/) external {
        owner.transfer(_val);
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

    event Receipt(uint _val);
    receive() external payable {
        emit Receipt(msg.value);
    }
}