/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//20221207

// 각 은행은(은행 contract) 예치, 인출의 기능을 가지고 있고 국세청은(정부 contract) 모든 국민의 재산정보를 파악하고 있다. => ??

// (예: 100이더 보유 -> 2이더 납부 -> 안건 2개 등록 -> 1.5 납부로 취급)

contract Government {

    // 각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 
    struct nation {
        string name;
        uint amountOfStaking;  
        uint amountOfTax;
    }

    enum Status {registered, voting, citated, rejected}

    // 각 안건은 번호, 이름, 제목, 내용, 찬-반 비율, 상태로 구성되어 있다. 
    struct poll {
        uint no;
        string name;
        string title;
        string content;
        uint ratioOfPaC;
        uint Pros;
        uint Cons;
        Status status;
    }
    
    mapping (address => nation) Nations;
    mapping (string => poll) Polls;
    uint index; 

    function setNation(string memory _name) public {
        Nations[msg.sender] = nation(_name, 0,0);
        autoTax();
    }

    function setDeposit() public payable {
        Nations[msg.sender].amountOfStaking += msg.value;
        autoTax();
    }
    
    // 안건이 등록되면 등록, 
    // 안건은 1이더 이상 세금을 납부한 사람만이 등록할 수 있고, 안건을 등록할 때마다 0.25 이더씩 깎인다. 
    function registerPoll(string memory _title, string memory _content) public {
        require(Nations[msg.sender].amountOfTax >= 1 ether);
        Nations[msg.sender].amountOfTax -= 0.25 ether;
        string memory _name = Nations[msg.sender].name;
        Polls[_title] = poll(index++, _name, _title, _content,0,0,0, Status.registered);
    }

    // 특정 안건에 대해서 투표하는 기능도 구현하고 
    function votePoll(string memory _title) public {
        Polls[_title].status = Status.voting;
        
        //5분 동안 투표를 진행하는데 => ???
    
        // 투표중이면 투표,  찬-반 비율이 60%가 넘어가면 통과. 60% 가 안되었으면 기각이 된다. 
        Polls[_title].ratioOfPaC * 5/3 > 0
        ? Polls[_title].status = Status.citated
        : Polls[_title].status = Status.rejected;
    }

    function votePros(string memory _title) public {
        Polls[_title].Pros += Nations[msg.sender].amountOfTax;  // 이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 
        autoRatioOfPaC(_title);
    }

    function voteCons(string memory _title) public {
        Polls[_title].Cons += Nations[msg.sender].amountOfTax;  // 이 나라는 1인 1표가 아닌 납부한 세금만큼 투표권을 얻어가는 특이한 나라이다. 
        autoRatioOfPaC(_title);
    }

    function autoTax() public {
        Nations[msg.sender].amountOfTax = Nations[msg.sender].amountOfStaking * 2 /100 ether; // 세금 납부는 갖고 있는 총 금액의 2%를 실시한다. 
    }

    function autoRatioOfPaC(string memory _title) internal {
        Polls[_title].ratioOfPaC = Polls[_title].Pros / Polls[_title].Cons;
    }
}

// contract Bank {
//     // 각 국민은 이름, 각 은행에 예치한 금액으로 이루어진 구조체이다. 
//     struct nation {
//         string name;
//         uint amountOfStaking;  
//         uint amountOfTax;
//     }
//     mapping (address => nation) Nations;
    
//     Government public government;

//     function setNation(string memory _name) public {
//         Nations[msg.sender] = nation(_name, 0,0);
//         government.autoTax();
//     }

//     function setDeposit() public payable {
//         Nations[msg.sender].amountOfStaking += msg.value;
//     }
// }