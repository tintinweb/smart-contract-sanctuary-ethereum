/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Bank {
    mapping (address => uint) accounts;

    function savings(address _addr, uint _amount) public payable {
        require(_amount == msg.value);
        accounts[_addr] += _amount;
    }

    function withdrawals(address _addr, uint _amount) public payable {
        require(_amount == msg.value);
        require(accounts[_addr] >= _amount);

        accounts[_addr] -= _amount;
        payable(_addr).transfer(_amount);
    }
}

contract NTS {
    struct person {
        string name;
        uint[] bank_balance;
        uint voting_num;
    }
    mapping (address => person) People;

    enum Status {registration, vote, pass, reject}
    struct agenda {
        uint number;
        string proposer;
        string title;
        string content;
        uint ratio;
        Status status;
    }
    mapping (string => agenda) Agendas;
    mapping (string => uint) AgendaDeadline;
    mapping (string => uint) AgendaAgree;
    mapping (string => uint) AgendaDisagree;

    Bank public bank;

    // 안건 등록
    // 1이더 이상 납부한 사람 통과
    uint index;
    function setAgenda(string memory _name, string memory _title, string memory _content) public {
        Agendas[_title] = agenda(++index, _name, _title, _content, 0, Status.registration);
        AgendaDeadline[_title] = block.timestamp + 5 minutes;
    }

    // 투표
    // 투표권 만큼만 투표하도록
    function voting(string memory _title, uint agree, uint disagree) public {
        require(keccak256(bytes(Agendas[_title].title)) == keccak256(bytes(_title)), "Poll isn't exist");
        require(Agendas[_title].status == Status.registration || Agendas[_title].status == Status.vote);

        if (AgendaDeadline[_title] < block.timestamp) {
            uint _ratio = 100 * AgendaAgree[_title] / (AgendaAgree[_title] + AgendaDisagree[_title]);
            Agendas[_title].ratio = _ratio;
            if (_ratio > 60) {
                Agendas[_title].status = Status.pass;
            } else {
                Agendas[_title].status = Status.reject;
            }
        }

        AgendaAgree[_title] += agree;
        AgendaDisagree[_title] += disagree;
        Agendas[_title].status = Status.vote;
    }

    // 은행 저축
    function bank_saving(address _addr, uint _amount) public {
        bank = Bank(_addr);

        bank.savings(msg.sender, _amount);
    }

    // 예금 인출
    function bank_withdrawal(address _addr, uint _amount) public {
        bank = Bank(_addr);

        bank.withdrawals(msg.sender, _amount);
    }

    // 세금 납부 후 투표권 받기
    function taxPayment() public view returns(uint){
        return address(msg.sender).balance;
    }
}

/*
각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. 

각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 

이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 

특정 안건에 대해서 투표하는 기능도 구현하고 각 안건은 번호, 제안자 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다. 안건이 등록되면 등록, 투표중이면 투표, 5분 동안 투표를 진행하는데 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 

안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고, 안건을 등록할 때마다 0.25 이더씩 깎인다. 세금 납부는 갖고 있는 총 금액의 2%를 실시한다.
(예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급) 
*/