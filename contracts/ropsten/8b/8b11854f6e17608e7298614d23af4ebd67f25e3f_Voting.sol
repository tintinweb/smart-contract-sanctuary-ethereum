/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Voting {
    //후보자 이름 배열로 저장
    string[] public candidateList;
    enum VoteStatus {
        STATUS_PENDING,
        STATUS_VOTING,
        STATUS_END,
        STATUS_ERROR
    }
    VoteStatus public voteStatus = VoteStatus.STATUS_PENDING;

    //후보자 리스트는 Deploy 할때 생성자에서 초기화 해준다.
    constructor(string[] memory _candidateNames) {
        candidateList = _candidateNames;
    }

    //후보자가 받은 총 투표수를 저장하는 변수 , 0으로 자동 초기화 된다.
    mapping(string => uint256) public voteReceived;
    mapping(string => uint8) public voteUser;

    //유저가 입력한 후보자명이 후보자 리스트에 있는지 확인한다.
    modifier isValidCandidate(string memory _name) {
        require(voteReceived[_name] > 0);
        _;
    }

    //투표 시작 함수
    function voteStart() public {
        require((voteStatus == VoteStatus.STATUS_PENDING));
        //투표 시작과 동시에 한표씩 준다. - 이유는 이후 투표대상을 찾는 연산 간소화 때문
        for (uint256 i = 0; i < candidateList.length; i++) {
            voteForCandidate(candidateList[i]);
        }
        voteStatus = VoteStatus.STATUS_VOTING;
    }

    //투표 종료
    function voteEnd() public {
        require((voteStatus == VoteStatus.STATUS_VOTING));
        voteStatus = VoteStatus.STATUS_END;
    }

    //후보자 득표수 증가 함수
    function regVote(string memory _caName) public isValidCandidate(_caName) {
        require((voteStatus == VoteStatus.STATUS_VOTING));
        //if (voteUser[msg.sender] == 0) {
         //   voteUser[msg.sender] = 1;
            voteReceived[_caName]++;
        //}
    }

    function voteForCandidate(string memory _candidate) public {
        require((voteStatus == VoteStatus.STATUS_PENDING));
        voteReceived[_candidate]++;
    }

    //각 후보자들의 투표 갯수 알아보기
    //후보자명을 넣어주면 결과값으로 투표갯수를 리턴해주기
    function totalVotesFor(string memory _name) public view returns (uint256) {
        //여기서 filesystem을 사용할 수 있어서 storage를 사용하면 파일에 저장이 된다.
        return voteReceived[_name];
    }
}