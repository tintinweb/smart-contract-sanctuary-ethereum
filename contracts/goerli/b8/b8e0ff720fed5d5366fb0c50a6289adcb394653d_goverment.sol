/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract Bank{

    mapping(address=>uint) account;

    function deposit(address _ad,uint value)public{
        account[_ad]=value;
    }

    function withdrawal(address _ad)public{

    }

}

contract KBank is Bank{

}

contract KB is Bank{

}

contract goverment{

    struct person{
        string name;
        Bank bank;
    }

    enum Status{
        register,
        voting
    }

    struct agenda{
        uint num;
        string name;
        string title;
        string contents;
        uint ratioProCon;
        Status status;
        uint timeLimit;
    }

    mapping(string=>agenda) agendas;    
    mapping(address=>person) people;
    uint index;

    //안건등록
    function registerAgenda(string memory _title,string memory contents)public{
        // uint len = agendas[_title].length;
        agendas[_title]=agenda(index++,people[msg.sender].name,_title,contents,0,Status.register,(block.timestamp+5 minutes));
    }

    //투표
    function voitingStart(string memory _title,bool result)public{
        require(block.timestamp<agendas[_title].timeLimit);

    }
    //세금 납부
    function taxPayment()public payable{
        
    }
    //은행 계좌 생성
    function createAccount(string memory title)public{
        people[msg.sender]=person(title,new Bank());
    }
    //은행 이체
    function bankDeposit()public payable{
        // people[msg.sender]
    }

}