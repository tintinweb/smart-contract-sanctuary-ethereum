/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract QuizContract {
    struct Quiz {
        uint256 startedAt;
        uint256 guessingPeriod;
        uint256 proofPeriod;
        address quizOwner;
        uint256 bid;
        bytes32 proofHash;
        uint256 maxAttempt;
        uint256 interval;
        uint256 attemptCost;
        uint256 secret;
        address winner;
        uint256 bank;
        address responder;
        uint256 currentAttempt;
        mapping(uint256 => uint256) variants;
        string proof;
        bool status;
    }

    address public owner;
    uint256 private ownerBalance;
    uint256 public counter;
    uint8 public immutable commission;
    mapping(uint256 => Quiz) private quizes;

    constructor(uint8 _commission) {
        owner = msg.sender;
        commission = _commission;
    }

    function startQuiz(
        uint256 _guessingPeriod,
        uint256 _proofPeriod,
        bytes32 _proofHash,
        uint256 _maxAttempt,
        uint256 _interval,
        uint256 _attemptCost
    ) public payable returns (uint256) {
        quizes[counter].quizOwner = msg.sender;
        quizes[counter].guessingPeriod = _guessingPeriod;
        quizes[counter].proofPeriod = _proofPeriod;
        quizes[counter].proofHash = _proofHash;
        quizes[counter].maxAttempt = _maxAttempt;
        quizes[counter].interval = _interval;
        quizes[counter].attemptCost = _attemptCost;
        quizes[counter].bid = msg.value;

        uint256 ownersCommission = (commission * msg.value) / 100;
        ownerBalance += ownersCommission;
        quizes[counter].bank = msg.value - ownersCommission;

        quizes[counter].startedAt = block.timestamp;
        quizes[counter].status = true;

        emit quizStarted(counter, block.timestamp);

        counter++;

        return counter - 1;
    }

    function solveQuiz(uint8 _quizID, uint256 _answer) public payable {
        require(quizes[_quizID].quizOwner != address(0), "Quiz isn't exist");
        require(
            (quizes[_quizID].responder == address(0)) ||
                (quizes[_quizID].responder == msg.sender),
            "Another responder already found"
        );
        require(
            quizes[_quizID].currentAttempt < quizes[_quizID].maxAttempt,
            "Number of tries out"
        );
        require(
            (quizes[_quizID].startedAt + quizes[_quizID].guessingPeriod) >
                block.timestamp,
            "Answers time is ended"
        );
        require(msg.value == quizes[_quizID].attemptCost, "Wrong payment");

        uint256 ownersCommission = (commission * msg.value) / 100;
        ownerBalance += ownersCommission;
        quizes[_quizID].bank += msg.value - ownersCommission;

        if (quizes[_quizID].responder == address(0))
            quizes[_quizID].responder = msg.sender;

        quizes[_quizID].variants[quizes[_quizID].currentAttempt] = _answer;

        quizes[_quizID].currentAttempt++;

        emit answerAdded(_quizID, _answer);
    }

    function proofQuiz(
        uint8 _quizID,
        uint256 _secret,
        string memory _proof
    ) public {
        require(
            quizes[_quizID].responder != address(0),
            "The quiz did not take place"
        );
        require(
            quizes[_quizID].quizOwner == msg.sender,
            "You're not a quiz owner"
        );
        require(
            (quizes[_quizID].startedAt + quizes[_quizID].guessingPeriod) <=
                block.timestamp,
            "Proof time isn't started"
        );
        require(
            (quizes[_quizID].startedAt +
                quizes[_quizID].guessingPeriod +
                quizes[_quizID].proofPeriod) > block.timestamp,
            "Proof time is ended"
        );
        require(_secret < quizes[_quizID].interval, "The secret isn't correct");
        require(
            keccak256(abi.encode(_proof, _secret)) == quizes[_quizID].proofHash,
            "The proof isn't true"
        );
        require(!isQuizSolved(_quizID, _secret), "The quiz is solved");

        quizes[_quizID].secret = _secret;
        quizes[_quizID].proof = _proof;
        quizes[_quizID].winner = msg.sender;

        emit proofAdded(_quizID, _secret, _proof);
    }

    function isQuizSolved(
        uint8 _quizID,
        uint256 _secret
    ) private view returns (bool) {
        for (uint256 i = 0; i < quizes[_quizID].currentAttempt; i++) {
            if (_secret == quizes[_quizID].variants[i]) return true;
        }
        return false;
    }

    function getQuizOwnerPrize(uint256 _quizID) public {
        require(
            quizes[_quizID].quizOwner == msg.sender,
            "You're not a quiz owner"
        );
        require(quizes[_quizID].status, "Prize already received");
        require(
            ((quizes[_quizID].responder == address(0)) &&
                ((quizes[_quizID].startedAt + quizes[_quizID].guessingPeriod) <=
                    block.timestamp)) || (quizes[_quizID].winner == msg.sender),
            "You are not a winner"
        );

        uint256 bank = quizes[_quizID].bank;
        quizes[_quizID].bank = 0;
        quizes[_quizID].status = false;
        payable(msg.sender).transfer(bank);

        emit quizEnded(_quizID, block.timestamp);
    }

    function getResponderPrize(uint256 _quizID) public {
        require(
            quizes[_quizID].responder == msg.sender,
            "You're not a responder"
        );
        require(quizes[_quizID].status, "Prize already received");
        require(
            ((quizes[_quizID].startedAt +
                quizes[_quizID].guessingPeriod +
                quizes[_quizID].proofPeriod) <= block.timestamp) &&
                (quizes[_quizID].winner == address(0)),
            "You are not a winner"
        );

        uint256 bank = quizes[_quizID].bank;
        quizes[_quizID].bank = 0;
        quizes[_quizID].winner = msg.sender;
        quizes[_quizID].status = false;
        payable(msg.sender).transfer(bank);

        emit quizEnded(_quizID, block.timestamp);
    }

    function getQuizOwner(uint256 _quizID) public view returns (address) {
        return quizes[_quizID].quizOwner;
    }

    function getQuizGuessingPeriod(
        uint256 _quizID
    ) public view returns (uint256) {
        return quizes[_quizID].guessingPeriod;
    }

    function getQuizProofPeriod(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].proofPeriod;
    }

    function getQuizProofHash(uint256 _quizID) public view returns (bytes32) {
        return quizes[_quizID].proofHash;
    }

    function getQuizMaxAttempt(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].maxAttempt;
    }

    function getQuizInterval(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].interval;
    }

    function getQuizAttemptCost(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].attemptCost;
    }

    function getQuizBid(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].bid;
    }

    function getQuizBank(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].bank;
    }

    function getQuizStartedAt(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].startedAt;
    }

    function getQuizSecret(uint256 _quizID) public view returns (uint256) {
        return quizes[_quizID].secret;
    }

    function getQuizWinner(uint256 _quizID) public view returns (address) {
        return quizes[_quizID].winner;
    }

    function getQuizResponder(uint256 _quizID) public view returns (address) {
        return quizes[_quizID].responder;
    }

    function getQuizCurrentAttempt(
        uint256 _quizID
    ) public view returns (uint256) {
        return quizes[_quizID].currentAttempt;
    }

    function getQuizAnswers(
        uint256 _quizID
    ) public view returns (uint256[] memory) {
        uint256[] memory answers = new uint256[](
            quizes[_quizID].currentAttempt
        );

        for (uint256 i = 0; i < quizes[_quizID].currentAttempt; i++) {
            answers[i] = quizes[_quizID].variants[i];
        }

        return answers;
    }

    function getQuizProof(uint256 _quizID) public view returns (string memory) {
        return quizes[_quizID].proof;
    }

    function getQuizStatus(uint256 _quizID) public view returns (bool) {
        return quizes[_quizID].status;
    }

    function showCommission() public view onlyOwner returns (uint256) {
        return ownerBalance;
    }

    function withdrawCommission() public onlyOwner {
        uint256 ownerCommission;

        ownerCommission = ownerBalance;
        ownerBalance = 0;
        payable(msg.sender).transfer(ownerCommission);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the contract owner!");
        _;
    }

    function calculateHash(
        uint256 _secret,
        string memory _proof
    ) public pure returns (bytes32) {
        return keccak256(abi.encode(_proof, _secret));
    }

    event quizStarted(uint256 indexed quizID, uint256 startedAt);
    event quizEnded(uint256 indexed quizID, uint256 endedAt);
    event answerAdded(uint256 indexed quizID, uint256 answer);
    event proofAdded(uint256 indexed quizID, uint256 secret, string proof);
}