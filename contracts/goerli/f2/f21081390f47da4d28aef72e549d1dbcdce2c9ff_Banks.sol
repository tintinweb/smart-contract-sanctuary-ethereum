/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

// 각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고
// 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. 

// 각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 

// 이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 

// 특정 안건에 대해서 투표하는 기능도 구현하고
// 각 안건은 번호, 제안자 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다.
// 안건이 등록되면 등록, 투표중이면 투표, 5분 동안 투표를 진행하는데
// 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 

// 안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고,
// 안건을 등록할 때마다 0.25 이더씩 깎인다.
// 세금 납부는 갖고 있는 총 금액의 2%를 실시한다.
// (예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급)

contract Banks {
    address bankAddr;
    constructor(){
        bankAddr = msg.sender;
    }
    Gov govContract;

    function deposit() public payable {
        // govContract.getCivils(msg.sender);
    }

    function withdraw(uint _amount) public {
        payable(msg.sender).transfer(_amount);
    }

    function setGovContract(address _govContractAddress) public {
        require(msg.sender == bankAddr);
        govContract = Gov(_govContractAddress);
    }
    
}

contract Gov {
    struct User {
        string name;
        mapping (string => uint) accounts;
    }

    mapping (address => User) civils;

    Banks bank = new Banks();

    struct Agenda {
        uint num;
        address agendaSetter;
        string title;
        string content;
        uint agree;
        uint disagree;
        STATUS status;
        uint endTime;
    }
    enum STATUS {ONGOING, DONE, PASS, DISMISS}

    mapping(string => Agenda) agendas;
    uint agendaCnt;

    function setTax() public payable{
        
    }

    function setAgenda(string memory _title, string memory _content) public payable {
        // 이더 납부 말고 포인트 사용 개념으로 변경해야 함.
        require(address(msg.sender).balance >= 1 ether, "YOU MUST PAY TAX MORE THAN 1 ETHER");
        require(msg.value == 0.25 ether, "YOU MUST PAY 0.25 ETHER");
        if(agendas[_title].endTime <= block.timestamp){
            agendas[_title].status = STATUS.DONE;
        }
        require(agendas[_title].status == STATUS.ONGOING, "THIS AGENDA IS ALREADY DONE");
        
        agendaCnt++;
        // 30초 후 끝으로 테스트
        agendas[_title] = Agenda(agendaCnt, msg.sender, _title, _content, 0,0,STATUS.ONGOING, block.timestamp + 30);        
    }

    function vote() public payable {

    }

    function endVote(string memory _title) public {
        if(agendas[_title].endTime <= block.timestamp){
            agendas[_title].status = STATUS.DONE;
        }

        require(agendas[_title].status == STATUS.DONE, "NOT DONE YET");
        if( agendas[_title].agree * 10 >= agendas[_title].disagree * 15){
            agendas[_title].status = STATUS.PASS;
        } else{
            agendas[_title].status = STATUS.DISMISS;
        }
    }

    // function getCivils(address _civilAddr) public returns(User memory){
    //     return civils[_civilAddr];
    // }

}