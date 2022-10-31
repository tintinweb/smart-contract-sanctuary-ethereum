// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract KNOV1 {
    address immutable admin;

    uint256 private totalQuestionNumber;
    uint256 private totalAnswerNumber;

    mapping(address => User) users; // user registry info

    mapping(address => uint256[]) userQuestionList; // address -> qids
    mapping(address => uint256[]) userAnswerList; // address -> aids

    mapping(uint256 => Question) questionList; // qid -> Question
    mapping(uint256 => uint256[]) answeredList; // qid -> aid list
    mapping(uint256 => Answer) answerList; // aid -> Answer

    struct User {
        address userWalletAddress;
        string nickname;
        bool isRegistered;
    }

    struct Question {
        address author;
        uint256 qid;
        string cid;
        bool isSelected;
        uint256 selectedAnswerId;
        uint256 reward; // reward will be transfered to selected answer's auther
    }

    struct Answer {
        address author;
        uint256 qid;
        uint256 aid;
        string cid;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(string calldata nickname) external returns (bool) {
        require(!users[msg.sender].isRegistered, "User already registered");
        users[msg.sender] = User(msg.sender, nickname, true);
        return true;
    }

    /* ---------- getter functions ----------- */

    /* getter functions for User info */
    function getIsRegistered(address userAddr) external view returns (bool) {
        return users[userAddr].isRegistered;
    }

    function getUserNickname(address userAddr)
        external
        view
        returns (string memory)
    {
        User memory user = users[userAddr];
        require(user.isRegistered, "User not registered");
        return user.nickname;
    }

    function getUserQids() external view returns (uint256[] memory) {
        return userQuestionList[msg.sender];
    }

    function getUserAids() external view returns (uint256[] memory) {
        return userAnswerList[msg.sender];
    }

    /* getter function for Questions */
    function getTotalQuestionNumber() external view returns (uint256) {
        return totalQuestionNumber;
    }

    function getQuestion(uint256 qid) external view returns (Question memory) {
        return questionList[qid];
    }

    function getQuestionCid(uint256 qid) external view returns (string memory) {
        return questionList[qid].cid;
    }

    function getIsAuthor(uint256 qid) external view returns (bool) {
        if (questionList[qid].author == msg.sender) {
            return true;
        } else {
            return false;
        }
    }

    /* getter functions for Answers */
    function getTotalAnswerNumber() external view returns (uint256) {
        return totalAnswerNumber;
    }

    function getAnswer(uint256 aid) external view returns (Answer memory) {
        return answerList[aid];
    }

    function getIsSelected(uint256 qid) external view returns (bool) {
        return questionList[qid].isSelected;
    }

    function getSelectedAnswerId(uint256 qid) external view returns (uint256) {
        return questionList[qid].selectedAnswerId;
    }

    function getQuestionAids(uint256 qid)
        external
        view
        returns (uint256[] memory)
    {
        return answeredList[qid];
    }

    function getAnswerCid(uint256 aid) external view returns (string memory) {
        return answerList[aid].cid;
    }

    /* ---------- setter functions ----------- */
    function postQuestion(string calldata cid) external returns (bool) {
        questionList[totalQuestionNumber] = Question(
            msg.sender,
            totalQuestionNumber,
            cid,
            false,
            0,
            100
        );
        userQuestionList[msg.sender].push(totalQuestionNumber);
        totalQuestionNumber++; // increase qid

        return true;
    }
        //! TODO: should reward the user with KNO Token

        //! TODO: should implement reward lockup

    function postAnswer(uint256 qid, string calldata cid) external {
        answerList[totalAnswerNumber] = Answer(
            msg.sender,
            qid,
            totalAnswerNumber,
            cid
        );
        answeredList[qid].push(totalAnswerNumber);
        userAnswerList[msg.sender].push(totalAnswerNumber);
        totalAnswerNumber++;
    }

    function selectAnswer(uint256 qid, uint256 aid) external returns (bool) {
        // checks if msg.sender is the author of this qid
        require(questionList[qid].author == msg.sender, "Not the author");

        // checks if this aid is answerd to the qid
        bool exist = false;
        uint256[] memory answers = answeredList[qid];

        for (uint256 i = 0; i < answers.length; i++) {
            if (answers[i] == aid) {
                exist = true;
            }
        }

        require(exist, "Not answerd to this qid");

        // update selected Answer
        questionList[qid].isSelected = true;
        questionList[qid].selectedAnswerId = aid;

        //! TODO: transfer KNO token to the author of selected answer

        return true;
    }
}