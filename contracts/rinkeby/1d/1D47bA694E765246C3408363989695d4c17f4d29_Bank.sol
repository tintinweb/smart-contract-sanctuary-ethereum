/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Bank {

    //Properties
    address public owner;
    mapping(address => uint) public addressToBalance;
    
    //Modifiers
    modifier isOwner() {
        require(msg.sender == owner , "Sender is not owner");
        _;
    }

    //Events
    event BalanceIncreased(address target, uint256 balance);
    event OwnerChanged(address oldOwner, address newOwner);

    //Constructor
    constructor() {
        owner = msg.sender;
    }

    //Public functions
    function addBalance(address to, uint value) public isOwner{
        //adicionar um saldo para uma carteira
        addressToBalance[address(to)] += value;
        //emitir um evento
        emit BalanceIncreased(to, value);
    }

    function changeOwner(address newOwnerContract) public isOwner{
        emit OwnerChanged(owner, newOwnerContract);
        owner = newOwnerContract;
    }
}