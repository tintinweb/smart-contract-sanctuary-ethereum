/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract bank {
    struct people {
        string name;
        uint money;
    }
    mapping(address => people) People; 
    function deposit() public payable {
        People[msg.sender].money += msg.value;
    }
    function Withdrawal(uint _money) public {
        People[msg.sender].money -= _money;
    }
    

}

contract government is bank{

    bank bk = new bank();
    function getPeople(address addr) public returns(string memory, uint) {
        return (People[msg.sender].name, People[msg.sender].money);
    }
    
    mapping(address => uint) tax;
    function taxPayment() public payable{
        // tax[msg.sender] += People[msg.sender].money * 0.02;
    }
    enum Status {regist, voting, pass, dismissal}
    struct agenda {
        uint a_num;
        address proposer;
        string title;
        string content;
        uint[] thumbs;
        Status status;
    }
    mapping(string => agenda) Agenda;
    function setVote(string memory _title, string memory _content) public {
        require(tax[msg.sender] > 10**18);
        Agenda[_title].a_num++;
        // Agenda[_title].proposer = People[msg.sender];
        Agenda[_title].title = _title;
        Agenda[_title].content = _content;
        Agenda[_title].status = Status.regist;
        People[msg.sender].money -= 0.25 ether;
    }

    function voting(string memory _title, bool _thumb) public {
        if(_thumb) {
            Agenda[_title].thumbs[0] += 1;
            Agenda[_title].status = Status.voting;
        } else {
            Agenda[_title].thumbs[1] -= 1;
            Agenda[_title].status = Status.voting;
        }
    }
}