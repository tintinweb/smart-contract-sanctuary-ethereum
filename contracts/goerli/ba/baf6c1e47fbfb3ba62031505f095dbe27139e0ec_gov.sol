/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// // SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
// //20221207

contract gov {
    struct citizen {
        string name;
        uint [] balance;
        uint point;
    }

    mapping (address => citizen) citizens;

    struct proposal {
        uint number;
        address proposer;
        string title;
        string content;
        uint pros;
        uint cons;
        uint ratio;
        Status status;
    }

    mapping (string => proposal) proposals;

    uint index;

    enum Status {registered, voting, accepted, dismissed}

    function regCitizen (string memory _name) public {
        citizens[msg.sender] = citizen(_name, new uint[](0), 0);
    }

// 에러 나서 주석처리 했습니다... 왜 내가 할 때는 이렇게 에러가 많이 나는 걸까...(이마짚)
    // function regProposal (string memory _title, string memory _con) public {
    //     require (citizens[msg.sender].point >= 0.25);
    //     proposals[_title] = proposal(index++, msg.sender, _title, _con, 0, 0, 0, Status.registered);
    //     citizens[msg.sender].point -= 0.25;    
    // }

    // function votePros (string memory _title) {
    //     require (citizen[msg.sender].point > 0);

    // } 
// 시간 부족이어서... 일단 한 곳까지 올리고 이후로도 더 해보겠습니다.

}