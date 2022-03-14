//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Quiz is Ownable {
    uint256 public constant quizFee = 10000;
    uint256 public constant winningAmount = 20000;

    struct Question {
        bytes32 question;
        bytes32[4] answers;
        uint8 correct;
    }

    struct Player {
        address account;
        mapping(uint256 => uint8) answers;
    }

    bool public quizStarted = false;
    bool public quizFinished = false;

    uint256 public totalQuestions = 0;
    mapping(uint256 => Question) quiz;

    uint256 public totalPlayers = 0;
    mapping(uint256 => Player) players;
    mapping(address => uint256) playerIndices;

    function addQuestion(
        bytes32 question,
        bytes32 answer1,
        bytes32 answer2,
        bytes32 answer3,
        bytes32 answer4,
        uint8 correct
    ) public onlyOwner {
        require(!quizStarted, "Quiz Has Been Started. Can Not Add Questions");
        require(!quizFinished, "Quiz Has Been Finished");

        totalQuestions++;
        quiz[totalQuestions] = Question(
            question,
            [answer1, answer2, answer3, answer4],
            correct
        );
    }

    function revealQuestion(uint256 id)
        public
        view
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes32
        )
    {
        require(id <= totalQuestions && id != 0, "Invalid Question ID");
        require(quizStarted, "Quiz Has Not Been Started yet");
        require(!quizFinished, "Quiz Has Been Finished");

        return (
            quiz[id].question,
            quiz[id].answers[0],
            quiz[id].answers[1],
            quiz[id].answers[2],
            quiz[id].answers[3]
        );
    }

    function startQuiz() public onlyOwner {
        require(!quizStarted, "Quiz Already In Progress");
        require(!quizFinished, "Quiz Has Been Finished");
        quizStarted = true;
    }

    function joinQuiz() public payable {
        require(quizStarted, "Quiz Has Not Been Started Yet");
        require(!quizFinished, "Quiz Has Been Finished");
        require(msg.value >= quizFee, "Insufficient Quiz Fee");

        totalPlayers++;
        playerIndices[msg.sender] = totalPlayers;

        Player storage player = players[totalPlayers];
        player.account = msg.sender;
    }

    function isEnrolled() public view returns (bool) {
        if (playerIndices[msg.sender] != 0) return true;
        return false;
    }

    function answerQuestion(uint256 questionID, uint8 answerID) public {
        require(playerIndices[msg.sender] != 0, "Quiz Not Joined Yet");
        require(
            questionID <= totalQuestions && questionID != 0,
            "Invalid Question ID"
        );
        require(answerID >= 1 && answerID <= 4, "Invalid Answer ID");

        players[playerIndices[msg.sender]].answers[questionID] = answerID;
    }

    function endQuiz() public onlyOwner {
        require(quizStarted, "Quiz Not In Progress");
        require(!quizFinished, "Quiz Has Already Been Finished");

        quizStarted = false;
        quizFinished = true;

        for (uint256 pid = 1; pid <= totalPlayers; pid++) {
            uint256 correctAnswers = 0;
            for (uint256 qid = 1; qid <= totalQuestions; qid++) {
                if (players[pid].answers[qid] == quiz[qid].correct)
                    correctAnswers++;
            }

            if (correctAnswers == totalQuestions)
                payable(players[pid].account).transfer(winningAmount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}