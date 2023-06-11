// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract VendingMachine {

    // state variables
    address public owner;
    mapping (address => uint) public donutCustomerVolume; //volume of donuts purchased by address
    mapping (address => uint) public sconeCustomerVolume; //volume of scones purchased by address
    mapping (address => uint) public donutCustomerRevenue; //donuts spend by address
    mapping (address => uint) public sconeCustomerRevenue; //scone spend by address
    uint donutPrice;
    uint sconePrice;

    event Purchase(uint amount, uint when);
    event Restock(uint _amount, uint _total);

    // set the owner as the address that deployed the contract
    // set the initial vending machine balance to 100
    constructor(uint256 startBalance, uint256 price) payable {
        owner = msg.sender;
        donutCustomerVolume[address(this)] = startBalance;
        donutPrice = price;
    }

    function getVendingMachineCurrentVolume() public view returns (uint) {
        return donutCustomerVolume[address(this)];
    }

    // Let the owner restock the vending machine
    function restock(uint restockAmount) public returns (bool) {
        require(msg.sender == owner, "Only the owner can restock.");
        donutCustomerVolume[address(this)] += restockAmount;
        emit Restock(restockAmount, donutCustomerVolume[address(this)]);
        return true;
    }

    // Purchase as many donuts possible given the spend amount
    function purchase(uint cashIn) public payable returns (bool) {
        require(cashIn >= donutPrice, "You don't have enough funds to buy at least 1 donut!!");
        uint purchaseVolume = cashIn/donutPrice;
        require(donutCustomerVolume[address(this)] >= purchaseVolume, "Not enough donuts in stock to complete this purchase");
        donutCustomerVolume[address(this)] -= purchaseVolume; //take donut volume from vending machine volume
        donutCustomerVolume[msg.sender] += purchaseVolume; //move donut volume to purchaser 
        emit Purchase(address(this).balance, block.timestamp);
        return true;
    }
}