/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
// 각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. 

// 각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 

// 이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 

// 특정 안건에 대해서 투표하는 기능도 구현하고 각 안건은 번호, 제안자 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다. 안건이 등록되면 등록, 투표중이면 투표, 5분 동안 투표를 진행하는데 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 

// 안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고, 안건을 등록할 때마다 0.25 이더씩 깎인다. 세금 납부는 갖고 있는 총 금액의 2%를 실시한다.
// (예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급)
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

    mapping(address => uint) tax;
    function setPerson(string memory _name, uint _money) public {
        people[msg.sender].name = _name;
        people[msg.sender].money = _money;
    }

    function getPerson() public view returns(Person memory){
        return people[msg.sender];
    }

    function setAgenda(string memory _name, string memory _title, string memory _contents) public payable{
        require(tax[msg.sender] >= 1 ether);
        tax[msg.sender] -= 0.25 ether;
        agendas[_title].num = index++;
        agendas[_title].name = _name;
        agendas[_title].title = _title;
        agendas[_title].contents = _contents;
        agendas[_title].status = Status.register;
    }

    // function payTex() public payable{
    //     people[msg.sender].money -= people[msg.sender].money * 0.02;
    //     tax[msg.sender] += people[msg.sender].money * 0.02;
    // }


    // function vote(string memory _title, bool _vote) public {
    //     if(_vote == true){
    //         agendas[_title].percent = ;
    //     }


    // } 


}