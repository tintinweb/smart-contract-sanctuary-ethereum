/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;
contract A {
    /**
     * @dev
     * 안건을 올리고 이에 대한 찬성과 반대를 할 수 있는 기능을 구현하세요. 안건은 번호, 제목, 내용, 제안자 그리고 찬성자 수와 반대자 수로 이루어져 있습니다.(구조체)
     * 안건들을 모아놓은 array도 같이 구현하세요. 각 안건의 현재상황(찬,반 투표수)을 알려주는 함수를 구현하세요.
     * 사용자는 자신의 이름과 자신이 만든 안건 그리고 자신이 투표한 안건과 어떻게 투표했는지(찬/반)에 대한 정보로 이루어져 있습니다.(구조체)
     * 투표는 누구나 할 수 있습니다. 투표하는 사람은 제목으로 검색하고 투표를 할 수 있습니다. 제목과 의사표현을 입력값으로 구현하세요.
     * 아래는 추가문제입니다. 위의 기본문제를 모두 해결한 후에 시간이 남는다면 구현해주세요.
     * +1) 한번 투표한 안건에는 중복으로 투표할 수 없도록 하세요. (기존의 자료구조를 변경시켜도 됩니다.)
     * +2) 안건의 투표자가 10명 이상이며 찬성 비율이 70% 이상이면 안건이 통과되도록, 이하면 기각되도록 구현하세요. (추가 배열 등을 구현하셔도 됩니다.)
     */

     /**
      * @dev
      * 실습과정
      * 1 - user 등록 : A,B,C
      * 2 - A 지갑으로 aa,bb,cc poll 등록
      * 3 - B 지갑으로 각각 찬,반,찬 투표
      * 4 - C 지갑으로 각각 찬,찬,찬 투표
      * 5 - B,C 지갑으로 각각 getUser1,2 해보기
      */

    /* Polls */
    mapping(string => PollStruct) pollsMap;
    struct PollStruct {
        uint num;
        address addr;
        string content;
        uint upVotes;
        uint downVotes;
    }

    /* Users */
    mapping(address => user) usersMap;
    struct user {
        string[] createdPolls;
        mapping(string => VoteStatusEnum) votedPollsMap;
    }
    enum VoteStatusEnum {
        NotVoted,
        UpVoted,
        DownVoted
    }


    /* ---------------------------------------------------------------- */
    /* ---------------------------- POLLS ----------------------------- */
    /* ---------------------------------------------------------------- */

    /* Create poll */
    uint pollNum;
    function setPoll(string memory _title, string memory _content) public {
        uint _num = pollNum + 1;
        address _addr = address(msg.sender);
        uint _upVotes;
        uint _downVotes;
        pollsMap[_title] = PollStruct(_num, _addr, _content, _upVotes, _downVotes);
        usersMap[_addr].createdPolls.push(_title);
    }

    /* Update poll - Vote */
    function voteToPoll(string memory _title, bool _bool) public {
        // Initialized _addr
        address _addr = address(msg.sender);
        // Duplicate voting not allowed
        require(usersMap[msg.sender].votedPollsMap[_title] == VoteStatusEnum.NotVoted, "Already voted");
        // Update poll and user
        if (_bool == true) { 
            pollsMap[_title].upVotes++; // Update poll
            usersMap[_addr].votedPollsMap[_title] = VoteStatusEnum.UpVoted; // Update user
        } else {
            pollsMap[_title].downVotes++; // Update poll
            usersMap[_addr].votedPollsMap[_title] = VoteStatusEnum.DownVoted; // Update user
        }
    }

    function determineVerdict(string memory _title) public view returns(bool) {
        // Initialize variables
        uint upVotes = pollsMap[_title].upVotes;
        uint downVotes = pollsMap[_title].upVotes;
        // Requirement
        require(upVotes + downVotes >= 10, "At least 10 votes required to proceed");
        // Determine verdidct
        if (upVotes * 100 / (upVotes + downVotes) >= 70) {
            return true;
        } else {
            return false;
        }
    }

    /* Read poll */
    function getPoll(string memory _title) public view returns(uint, address, string memory, uint, uint) {
        return(
            pollsMap[_title].num, 
            pollsMap[_title].addr, 
            pollsMap[_title].content, 
            pollsMap[_title].upVotes, 
            pollsMap[_title].downVotes 
        );
    }

    /* ---------------------------------------------------------------- */
    /* ---------------------------- USERS ----------------------------- */
    /* ---------------------------------------------------------------- */

    /* Create user */
    function setUser() public view {
        address _addr = address(msg.sender);
        usersMap[_addr];
    }

    /* Read user */
    function getUser(address _addr) public view returns(string[] memory) {
        return usersMap[_addr].createdPolls;
    }
    function getUserVotes(address _addr, string memory _title) public view returns(VoteStatusEnum) {
        return usersMap[_addr].votedPollsMap[_title];
    }

}