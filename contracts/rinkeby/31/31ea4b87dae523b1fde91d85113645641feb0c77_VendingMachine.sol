/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract VendingMachine {
    address payable public owner;
    uint public numSodas;

    // Similar to Javascript HashTable, which is a JS Object by default
    mapping(address => uint) public sodasPurchased;

    constructor(uint _numSodas) {
        // whoever deploys this contract = owner
        owner = payable(msg.sender);
        numSodas = _numSodas;
    }

    function purchase() public payable {
        require(msg.value >= 1000 wei, "You must deposit at least 1000 wei");
        require(numSodas > 0, "Out of sodas");
        numSodas--;
        sodasPurchased[msg.sender]++;
    }

    function withrawEarnings() public {
        require(msg.sender == owner, "Only the owner can withdraw earnings!");
        owner.transfer(address(this).balance);
    }
}