/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Government {

    enum State {
        Registered,
        Voting,
        Passed,
        Rejected
    }

    struct Motion {
        uint number;
        string name;
        string title;
        string content;
        uint agreeRatio;
        State state;
        uint agree;
        uint disagree;
    }
    // 은행 컨트랙트
    address[] banks;

    function registerBank() public {
        banks.push(msg.sender);
    }

   uint index = 1;

    // 안건 목록
    mapping(uint => Motion) public motions;

    // 안건 등록
    function registerMotion(string memory _name, string memory _title, string memory _content) public payable{
        // 안건을 등록하고, 세금 0.25 이더를 깎습니다.
        require(msg.value == 0.25 ether);
        motions[index].number = index;
        motions[index].name = _name;
        motions[index].title = _title;
        motions[index].content = _content;
        motions[index].state = State.Registered;
        index++;
    }

    // 투표
    function vote(uint _motionNumber, string memory _opinion) public {
        require(motions[_motionNumber].state == State.Registered || motions[_motionNumber].state == State.Voting );
        require( keccak256(bytes(_opinion)) == keccak256(bytes("agree")) ||  keccak256(bytes(_opinion)) == keccak256(bytes("disagree")));
        
        // 투표를 진행하고, 5분 동안 찬반 비율을 계산합니다.
        // 60%가 넘어가면 통과, 아니면 기각으로 처리합니다.

        if (keccak256(bytes(_opinion)) == keccak256(bytes("agree"))) {
            motions[index].agree += 1;
        } else {
            motions[index].disagree += 1;
        }


    }
}