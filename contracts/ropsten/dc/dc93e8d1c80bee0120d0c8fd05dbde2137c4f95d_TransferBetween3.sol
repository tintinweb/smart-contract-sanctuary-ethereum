/**
 *Submitted for verification at Etherscan.io on 2022-07-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TransferBetween3 {
    uint256 contract_balance;
    address payable [3] accountAddress;

    constructor (address payable alice, address payable bob, address payable tom) payable {
        accountAddress[0] = alice;
        accountAddress[1] = bob;
        accountAddress[2] = tom;
        contract_balance = 0;
    }

    // This function for alice to put the money for her family
    function put_money() public payable {
        // The sender of the money should be alice
        require(msg.sender == accountAddress[0]);
        // The sender should send some amount of money
        require(msg.value >0, "Send some money");
        // add the money to the contract balance
        contract_balance += msg.value;
    }

    // This function is for bob to withdraw some money from the contract
    function withdraw(uint amount) public {
        // The sender of the money should be bob
        require(msg.sender == accountAddress[1]);
        // The requested amount should be available on the contract balance
        require(contract_balance >= amount, "not enough monye on account");
        contract_balance -= amount;
        payable(msg.sender).transfer(amount);
    }

     // This function is for pop to send some money from the contract to tom
    function transfer_to_tom(uint amount) public {
        // The sender of the money should be bob
        require(msg.sender == accountAddress[1]);
        // The requested amount should be available on the contract balance
        require(contract_balance >= amount, "not enough monye on account");
        contract_balance -= amount;
        // transfer money to tom
        payable(accountAddress[2]).transfer(amount);
    }

    function current_contract_balance() view public returns (uint) {
        return  address(this).balance;
    }
}