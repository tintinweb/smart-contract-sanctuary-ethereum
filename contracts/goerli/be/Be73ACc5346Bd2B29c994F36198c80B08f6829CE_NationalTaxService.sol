/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract NationalTaxService {
    struct Citizen {
        string name;
        uint256[] balances; // amount deposited in each bank
    }

    mapping(address => Citizen) public citizens; // address => Citizen

    function payTax(uint256 amount) public {
        // 2% of total amount held
        uint256 tax = amount * 2 / 100;

        // pay tax
        citizens[msg.sender].balances[0] -= tax;
    }

    mapping(address => uint256) public balances; // address => balance

    function deposit(uint256 amount) public {
        balances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) public {
        // check if sender has enough balance
        require(balances[msg.sender] >= amount, "Insufficient balance.");

        balances[msg.sender] -= amount;
    }


    struct Agenda {
        uint256 id;
        string name;
        string title;
        string content;
        uint256 proConsRatio;
        bool status;
    }

}