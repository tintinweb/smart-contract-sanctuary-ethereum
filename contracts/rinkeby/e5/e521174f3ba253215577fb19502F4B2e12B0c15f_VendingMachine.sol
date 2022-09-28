/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract VendingMachine {
    address public owner;
    mapping (address => uint) public donutBalances;

    constructor() {
        owner = msg.sender;
        donutBalances[address(this)] = 100;
    }

    function getVendingMachineBalance() public view returns(uint) {
        return donutBalances[address(this)];
    }

    function restock(uint _amount) public {
        require(msg.sender == owner, "Only owner can restock");
        donutBalances[address(this)] += _amount;
    }

    function purchase(uint _numberOfDonuts) public payable {
        require(msg.value >= _numberOfDonuts * 0.5 ether, "You need 0.5 ether per donut");
        require(donutBalances[address(this)] >= _numberOfDonuts, "Out of stock. Ask owner to restock");
        donutBalances[address(this)] -= _numberOfDonuts;
        donutBalances[msg.sender] += _numberOfDonuts;
    }
}