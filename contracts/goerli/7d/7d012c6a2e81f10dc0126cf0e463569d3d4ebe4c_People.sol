/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/*
각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. 
각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 
이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 
특정 안건에 대해서 투표하는 기능도 구현하고 각 안건은 번호, 제안자 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다. 
안건이 등록되면 등록, 투표중이면 투표, 5분 동안 투표를 진행하는데 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 


안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고, 안건을 등록할 때마다 0.25 이더씩 깎인다. 
세금 납부는 갖고 있는 총 금액의 2%를 실시한다.

(예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급)
*/





/*

// 각 은행은(은행 contract) 예치, 인출의 기능
contract Banks {

    function deposit() public payable {    }
    
    function withdraw(uint256 amount) public {

    }
}


// 국세청은(정부 contract) 모든 국민의 재산정보를 파악
contract Government {

    Banks public Bank = new Banks();

    // 각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체
    struct Citizen {
        string name;
        uint256[] bankBalances;
    }

    // 각 안건은 번호, 제안자 이름, 제목, 내용, 찬-반 비율, 상태로 구성
    struct Proposal {
        uint256 id;
        string name;
        string title;
        string content;
        uint256 agree;
        uint256 disagree;
        bool passed;
    }

    // Citizen 구조체는 mapping을 이용해 address를 키로 하는 배열로 정의
    // 이는 국민의 주소를 이용해 해당 국민의 정보를 저장
    mapping(address => Citizen) public citizens;
    Proposal[] public proposals;

    // payTaxes() 함수에서는 국민의 은행 계좌에 있는 모든 금액을 합산한 뒤, 
    // 지불할 세금의 비율대로 각 은행 계좌에서 세금을 차감하는 작업을 수행합니다.
    function payTaxes(uint256 amount) public {
        
        require(amount >= 1);
        uint256 totalBalance = 0;
        for (uint256 i = 0; i < citizens[msg.sender].bankBalances.length; i++) {
            totalBalance += citizens[msg.sender].bankBalances[i];
        }
        require(totalBalance >= amount);

        // 세금 납부는 갖고 있는 총 금액의 2%를 실시한다.
        for (uint256 i = 0; i < citizens[msg.sender].bankBalances.length; i++) {
            Bank(i).withdraw(amount * citizens[msg.sender].bankBalances[i] / totalBalance);  <<<<<<<<<< 문제입니다.
        }
    }
    // newProposal() 함수에서는 안건을 등록하기 위해 세금을 1 이더 이상 납부해야 하며, 
    // 안건이 등록되면 proposals 배열에 새로운 안건을 추가합니다. 안건의 상태는 등록된 직후에는 투표중
    function newProposal(string memory _name, string memory _title, string memory _content) public {
    // 안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있음
    require(payTaxes(1) == true);
    require(payTaxes(0.25) == true);
    proposals.push(Proposal({
        id: proposals.length + 1,
        name: _name,
        title: _title,
        content: _content,
        yea: 0,
        nay: 0,
        passed: false
    }));
}
    // 특정 안건에 대해서 투표하는 기능
    // 5분 동안 투표가 진행되며, 그 결과에 따라 통과 또는 기각
    function vote(uint256 proposalId, bool support) public {
        // 안건이 등록되면 등록, 투표중이면 투표
        Proposal storage proposal = proposals[proposalId];
        // 5분 동안 투표를 진행 투표가 진행되는 동안, 각 찬-반의 투표 수를 계속 증가시키며, 
        // 5분이 지나면 투표가 종료되고 찬-반 비율을 계산합니다. 
        require(proposal.agree + proposal.disagree < now + 300);
        if (support) {
            proposal.agree += 1;
        } else {
            proposal.disagree += 1;
        }
        // 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다.
        if (proposal.agree / (proposal.agree + proposal.disagree) > 0.6) { 
            proposal.passed = true;
        }
    }
}

*/


contract People {

    // 안건을 등록하는 함수
    function register(uint amount) public {
        // 세금 납부
        uint tax = amount * 2 / 100;
        // address(msg.sender).transfer(tax);  <<<<<<

        // 세금을 납부한 사람만이 안건을 등록할 수 있음
        require(tax > 0, "Tax has not been paid");
        // 안건 등록 수수료 0.25 이더 감소
        // amount -= 0.25;                     <<<<<<
    }
}