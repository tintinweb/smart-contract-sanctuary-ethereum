/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Gov {
    struct User {
        string name;
        uint bal;
        uint tax;
    }
    mapping (address => User) userMap;

    enum AgendaStatus { on, vote, off }
    struct Agenda {
        uint id;
        string byName;
        string title;
        string content;
        uint ratio;
        uint total;
        uint good;
        uint endTime;
        AgendaStatus status;
    }
    mapping (string => Agenda) agendaMap;
    uint agendaIndex;

    function setAgenda(string memory _title, string memory _content) public {
        require(userMap[msg.sender].tax > 2 * (10 ** 18));
        userMap[msg.sender].tax -= 25 * (10 ** 16);
        agendaMap[_title] = Agenda(++agendaIndex, userMap[msg.sender].name, _title, _content, 0,0,0,0, AgendaStatus.on);
    }

    function startVote(string memory _title) public {
        require(agendaMap[_title].status == AgendaStatus.on);
        agendaMap[_title].status = AgendaStatus.vote;
        agendaMap[_title].endTime = block.timestamp + 300;
    }

    function vote(string memory _title, bool _isGood) public {
        require(agendaMap[_title].status == AgendaStatus.vote);
        require(agendaMap[_title].endTime > block.timestamp);
        if(_isGood){
            agendaMap[_title].good += 1 * userMap[msg.sender].tax;
        }
        agendaMap[_title].total += 1 * userMap[msg.sender].tax;
        agendaMap[_title].ratio = agendaMap[_title].good * 100 / agendaMap[_title].total;
    }

    function getVoteResult(string memory _title) public returns(bool) {
        require(agendaMap[_title].status == AgendaStatus.vote);
        require(agendaMap[_title].endTime < block.timestamp);
        agendaMap[_title].status = AgendaStatus.off;
        if(agendaMap[_title].ratio > 60){
            return true;
        }else{
            return false;
        }
    }

    function setUser(string memory _name) public {
        userMap[msg.sender] = User(_name, 0, 0);
    }

    function getUser() public view returns(User memory){
        return userMap[msg.sender];
    }

    function deposit(address _addr, uint _value) external {
        userMap[_addr].bal += _value;
    }

    function withdraw(address _addr, uint _value) external {
        userMap[_addr].bal -= _value;
    }

    function payTax(address _bankAddr) public {
        uint tax = userMap[msg.sender].bal * 2 / 100;
        Bank JB = Bank(_bankAddr);
        JB.payTax(msg.sender, tax);
    }

}

contract Bank {
    Gov public gov; 
    constructor(address govAddr) {
        gov = Gov(govAddr);
    }

    mapping (address => uint) userBalance;

    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
        gov.deposit(msg.sender, msg.value);
    }

    function withdraw(uint _value) public {
        userBalance[msg.sender] -= _value;
        gov.withdraw(msg.sender, _value);
        payable(msg.sender).transfer(_value);
    }

    function payTax(address _addr, uint _value) external {
        userBalance[_addr] -= _value;
        gov.withdraw(_addr, _value);
        payable(msg.sender).transfer(_value);
    }

    function getBal(address _addr) public view returns(uint){
        return userBalance[_addr];
    }
}