/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.12;

contract Bank {
    mapping(address => uint) depositMap;

    function deposit() public payable {
        depositMap[msg.sender] += msg.value;
    }

    function _withdraw(address target, uint amount) private {
        require(depositMap[target] >= amount, "not enough deposit");

        depositMap[target] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function withdraw(uint amount) public {
        _withdraw(msg.sender, amount);
    }

    // 예금 조회
    function inquiryBalance(address guest) public view returns(uint) {
        return depositMap[guest];
    }

    // 자동이체 - 세금 납부용
    function eft(address target, uint amount) public {
        // require(자동이체 등록했는가?, "permission denied");
        _withdraw(target, amount);
    }
}

contract Revenue {

    struct Citizen {
        string name;
        uint totalBalance;
        uint tax;
    }

    enum AgendaStatus {
        Registered, Voting, Accepted, Dismissed
    }

    struct Agenda {
        uint no;
        string title;
        string content;
        uint agree;
        uint disagree;
        uint agreeRatio;// 백분율
        AgendaStatus status;
    }

    Bank[] banks;
    mapping(address => Citizen) citizenMap;
    Agenda[] agendas;

    function getTotalBalance(address citizenAddress) private view returns(uint) {
        uint totalBalance;

        for(uint i = 0; i < banks.length; i++) {
            totalBalance += banks[i].inquiryBalance(citizenAddress);
        }

        return totalBalance;
    }

    function payTax(address citizenAddress, uint amount) private {
        for(uint i = 0; i < banks.length; i++) {
            uint balance = banks[i].inquiryBalance(citizenAddress);
            if(balance < amount) {
                uint _balance = amount - balance;
                banks[i].eft(citizenAddress, _balance);
                amount -= _balance;
            } else {
                banks[i].eft(citizenAddress, amount);
                break;
            }
        }
    }

    function registCitizen(string memory name) public {
        uint totalBalance = getTotalBalance(msg.sender);
        uint tax = totalBalance * 2 / 100;// totalBalance * 0.02;
        payTax(msg.sender, tax);
        totalBalance -= tax;

        citizenMap[msg.sender] = Citizen(name, totalBalance, tax);
    }

    uint ETH = 1000000000000000000;

    function propose(string memory title, string memory content) public {
        require(citizenMap[msg.sender].tax > ETH, "permission denied");

        agendas.push(Agenda(agendas.length + 1, title, content, 0, 0, 0, AgendaStatus.Registered));

        citizenMap[msg.sender].tax -= ETH * 25 / 100;// ETH * 0.25;
    }

    function beginVote(uint agendaNo) public {
        require(agendas[agendaNo - 1].status == AgendaStatus.Registered, "already end or voting");

        agendas[agendaNo - 1].status = AgendaStatus.Voting;
    }

    function vote(uint agendaNo, bool agree) public {
        uint idx = agendaNo - 1;
        
        require(agendas[idx].status == AgendaStatus.Voting, "is not in voting");

        if(agree) agendas[idx].agree++;
        else agendas[idx].disagree++;

        uint _agree = agendas[idx].agree;
        uint _disagree = agendas[idx].disagree;
        agendas[idx].agreeRatio = (_agree / (_agree + _disagree)) * 100;// 백분율로 계산
    }

    // 5분후 실행되도록 설정 필요
    function endVote(uint agendaNo) private {
        agendas[agendaNo - 1].status = (
            agendas[agendaNo - 1].agreeRatio > 60
            ? AgendaStatus.Accepted
            : AgendaStatus.Dismissed
        );
    }
}