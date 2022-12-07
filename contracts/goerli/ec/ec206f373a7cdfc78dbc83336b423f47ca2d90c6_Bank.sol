/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Bank {
    
    enum Status { register, onging }
    
    struct Person{
        string name;
        uint money;
    }

    
    struct Agenda {
        uint num;
        string name;
        string title;
        string contents;
        uint percent;
        Status status;
    }

    mapping(address => Person) people;
    mapping(string => Agenda) agendas;
    uint index;

    mapping(address => uint) tex;
    function setPerson(string memory _name, uint _money) public {
        people[msg.sender].name = _name;
        people[msg.sender].money = _money;
    }

    function getPerson() public view returns(Person memory){
        return people[msg.sender];
    }

    function setAgenda(string memory _name, string memory _title, string memory _contents) public payable{
        require(tex[msg.sender] >= 1 ether);
        tex[msg.sender] -= 0.25 ether;
        agendas[_title].num = index++;
        agendas[_title].name = _name;
        agendas[_title].title = _title;
        agendas[_title].contents = _contents;
        agendas[_title].status = Status.register;
    }

    function payTex() public payable{
        people[msg.sender].money -= 2/people[msg.sender].money * 100;
        tex[msg.sender] += 2/people[msg.sender].money * 100;
    }


    // function vote(string memory _title, bool _vote) public {
    //     if(_vote == true){
    //         agendas[_title].percent = ;
    //     }


    // } 


}