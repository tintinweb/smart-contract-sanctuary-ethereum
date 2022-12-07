/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
// 20221207_TEX 
pragma solidity 0.8.0;

// 모든 국민의 재산정보를 파악
contract Goverment {
    /*
    Bank public bank;

    // 국민
    struct citizen {
        string name;
        uint bankDeposit;
        uint points;
    }
    mapping (address => citizen) citizenList;

    function updateBankDepositPlus(uint _amount) public {
        citizenList[msg.sender].bankDeposit += _amount;
    }

    function updateBankDepositMinus(uint _amount) public {
        citizenList[msg.sender].bankDeposit -= _amount;
    }

    // 안건
    enum Status { in_progress, register, dismiss }

    struct agenda {
        uint number;
        string title;
        string contents;
        address proposer;
        uint agree_num;
        uint disagree_num;
        Status status;
    }

    agenda[] Agendas;

    // 안건 만들기
    function setAgenda(string memory _title, string memory _contents) public {
        Agendas.push(agenda(Agendas.length+1, _title, _contents, msg.sender, 0, 0, Status.register));
    }
    */
}