/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract vote {
    // 안건 구조체체
    struct poll {
        uint number;
        string title;
        string content;
        address proposer;
        uint pros;
        uint cons;
        bool isPass;
        mapping (address => bool) doVote;
    }
    mapping(string => poll) Polls; // 여러 안건 저장
    uint index; // number의 값 대입을 위해

    // 유저 구조체
    struct user {
        string name;
        string[] myPolls;
        mapping (string => bool) myVotingPolls;
    }
    mapping (address => user) Users;

    // 안건 생성
    function setPoll(string memory _title, string memory _content) public {
        Polls[_title].number = ++index;
        Polls[_title].title = _title;
        Polls[_title].content = _content;
        Polls[_title].proposer = msg.sender;
        Users[msg.sender].myPolls.push(_title);
    }

    // 안건 이름으로 안건 받아오기
    function getPoll(string memory _title) public view returns(uint, string memory, string memory, address, uint, uint, bool) {
        return (Polls[_title].number, Polls[_title].title, Polls[_title].content, Polls[_title].proposer, Polls[_title].pros, Polls[_title].cons, Polls[_title].isPass);
    }

    // function getVoting(uint _number) public view returns(uint, uint) {
    //     return (Polls[_number-1].pros, Polls[_number-1].cons);
    // }
    
    // 유저 생성
    function setUser(string memory _name) public {
        Users[msg.sender].name = _name;
    }
    
    // 현재 주소의 유저 정보를 받아오기기
    function getUser(string memory _title) public view returns(string memory, string[] memory, bool) {
        return (Users[msg.sender].name, Users[msg.sender].myPolls, Users[msg.sender].myVotingPolls[_title]);
    }

    // 안건을 통해 내가 투표한 결과 반환
    function getUser2(string memory _title) public view returns(bool) {
        return Users[msg.sender].myVotingPolls[_title];
    }

    // 내가 해당하는 안건에 대해 투표
    function DoVoting(string memory _title, bool _myOpinion) public {
        require(keccak256(bytes(Polls[_title].title)) == keccak256(bytes(_title)), "Poll isn't exist");
        require(Polls[_title].doVote[msg.sender] == true, "Already Voting");    // 한번 투표한 안건에는 중복으로 투표할 수 없도록 하세요.

        Users[msg.sender].myVotingPolls[_title] = _myOpinion;
        Polls[_title].doVote[msg.sender] = true;
        
        if (_myOpinion == true) {
            Polls[_title].pros ++;
        } else {
            Polls[_title].cons ++;
        }
    }

    // 안건 투표자 10명 이상이며 찬성 비율이 70% 이상이면 통과, 이하면 기각.
    function passOrReject(string memory _title) public {
        uint total = Polls[_title].pros + Polls[_title].cons;
        require(total >= 10, "Not Yet");
        uint prosRating = 100 * Polls[_title].pros / total;

        if (prosRating >= 70) Polls[_title].isPass = true;
        else Polls[_title].isPass = false;
    }
}