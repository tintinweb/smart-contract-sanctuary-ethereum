/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/*
각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. 

각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 

이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 

특정 안건에 대해서 투표하는 기능도 구현하고 각 안건은 번호, 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다.
안건이 등록되면 등록, 투표중이면 투표, 5분 동안 투표를 진행하는데 찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 

안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고, 안건을 등록할 때마다 0.25 이더씩 깎인다. 세금 납부는 갖고 있는 총 금액의 2%를 실시한다.
(예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급)
*/

// contract Bank{
//     Gov public gov = new Gov;
//     function setDeposit(uint _money) public payable returns(uint){

//     }
//     function withdraw(uint _money) public payable returns(uint) {
        
//     }
//     // function getBalance(msg.sender) public view returns(string memory, uint){
//     //     return gov.getCitizen(name, deposit);
//     // }

// }
contract Gov{
    // Bank public bank = new Bank();

    struct citizen {
        string name;
        uint deposit;
    }
    mapping (address => citizen)Citizens;

    // function setCitizen(string memory _name) public {
    //     Citizens[msg.sender] = citizen(_name, bank.getBalance(_name));

    // }
    function getCitizen(address _a)public view returns(string memory, uint){
        return (Citizens[_a].name, Citizens[_a].deposit);
    }

    enum Status {updated, voting, passed, dismissed}
    struct agenda {
        uint number;
        string proposer;
        string title;
        string content;
        uint ratio;
        Status status;        
    }

}