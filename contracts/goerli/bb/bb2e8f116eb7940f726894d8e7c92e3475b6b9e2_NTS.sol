/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract Bank {
    
    NTS nts;
    constructor(address _a) {
        nts = NTS(_a);
    }

    // 유저정보 (누구한테 얼마있어?)
    mapping(address => uint) userBalance;

    // 예치
    function deposit() public payable {
        userBalance[msg.sender] += msg.value;
    }

    // 인출
    function withdrawal(address requester, uint _w_amount) private  {
        payable(requester).transfer(_w_amount);
    }

    // 고객이 본인 돈 인출
    function withdrawal_User(uint _w_amount) public  {
        require(userBalance[msg.sender] >= _w_amount);
        withdrawal(msg.sender, _w_amount);
        userBalance[msg.sender] -= _w_amount;
    }

    // 조회
    function getBalance(address _user) public view returns(uint) {
        return userBalance[_user];
    }

    // 세금 납부
    function texPay(address _govern) public {
        // 추가 수정
        // amount는 특정 유저의 잔고의 2% amount = userBalance[address] * 0.02
        /*
        2. 특정 시민 지목 (?)
        */
        uint _tax = address(this).balance/50;
        require(msg.sender == address(nts));
        withdrawal(_govern, _tax);
    }
}

contract NTS {
    struct poll {
        uint num;
        address preseneter;
        // string name;
        string title;
        string content;
        uint pros;
        uint cons;
        uint startTime;
        Status status;
    }
    poll[] Polls; // mapping으로 변경?
    Bank[] banks;

    struct citizen {
        address addr; //이름 대용
        uint payedtax;
        // 은행별 예치금
        // 자신이 투표한 혹은 만든 안건들
    }

    enum Status {registered, voting, passed, failed}

    //은행 등록
    function setBank(address _a) public {
        banks.push(Bank(_a));
    }

    //banks length
    function getBankslength() public view returns(uint) {
        banks.length;
    }

    // 안건 등록
    /*
    시점을 설정하고
    */
    function setPoll(string memory _title, string memory _content) public {
        // require(세금 포인트가 0.25보다 많이 남아있어야 함)
        Polls.push(poll(Polls.length+1, msg.sender, _title, _content, 0, 0, block.timestamp, Status.registered));
        // 납부한 세금 포인트 -0.25 ether
    }

    // 안건에 투표
    /*
    위에서 설정한 시점을 특정 조건에 맞게 제한하기
    */
    function votePoll(uint _a, bool pro) public {
        // 투표권수만큼 하기 제한-> 세금 내서 쌓아놓은 포인트 
        if(pro /*pro == true*/) {
            Polls[_a-1].pros++;
        } else {
            Polls[_a-1].cons++;
        }
    }
    // 
}