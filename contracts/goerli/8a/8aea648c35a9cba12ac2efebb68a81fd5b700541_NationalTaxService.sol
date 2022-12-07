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

    Agenda[] public agendas; // array of agendas

    function registerAgenda(string memory _name, string memory _title, string memory _content) public {
        // check if sender has paid more than 1 Ether
        //require(NationalTaxService.balances[msg.sender] > 1 ether, "Must have paid more than 1 Ether to register an agenda.");

        // deduct 0.25 Ether
        //NationalTaxService.balances[msg.sender] -= 0.25 ether;

        // add agenda to array
        agendas.push(Agenda({
            id: agendas.length + 1,
            name: _name,
            title: _title,
            content: _content,
            proConsRatio: 0,
            status: false
        }));
    }

    function vote(uint256 _id, bool _vote) public {
        Agenda memory agenda = agendas[_id];

        // check if agenda is in the voting phase
        require(agenda.status == false, "Agenda is not in the voting phase.");

        // update pro-cons ratio
        if (_vote) {
            agenda.proConsRatio++;
        } else {
            agenda.proConsRatio--;
        }

        // check if the agenda passed or failed
        if (agenda.proConsRatio >= 60) {
            agenda.status = true;
        } else if (agenda.proConsRatio <= 40) {
            agenda.status = false;
        }
    
    }
}