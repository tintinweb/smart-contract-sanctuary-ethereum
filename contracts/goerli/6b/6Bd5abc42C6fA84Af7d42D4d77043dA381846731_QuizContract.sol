/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/quiz.sol



pragma solidity ^0.8.17;


contract QuizContract is Ownable {

    struct Quiz {
        uint8[] rightAnswers;
        uint256 startTime;
        uint256 endTime;
    }

    struct Result {
        bytes32 quizId;
        address user;
        uint8[] answers;
        uint8 numberOfRightAnswers;
        uint256 createdAt;
    }

    mapping (bytes32 => Quiz) public quizs;
    mapping (address => Result[]) public userResults;

    event AnswerEvent(address user, bytes32 quizId, uint256 numberOfRightAnswers, uint256 createdAt);

    constructor() {}

    function addQuiz(bytes32 quizId, uint8[] memory answers, uint256 startTime, uint256 endTime) external onlyOwner {
        Quiz memory _quiz = Quiz(answers, startTime, endTime);
        quizs[quizId] = _quiz;
    }

    function _isDoneQuiz(address user, bytes32 quizId) private view returns (bool) {
        Result[] memory _results = userResults[user];
        for (uint i=0; i < _results.length; i++) {
            if (_results[i].quizId == quizId) { 
                return true;
            }
        }
        return false;
    }

    function isDoneQuiz(address user, bytes32 quizId) public view returns (bool) {
        return _isDoneQuiz(user, quizId);
    }

    function getUsersQuizs(address user) public view returns (uint256) {
        return userResults[user].length;
    }

    function answerQuestions(bytes32 quizId, uint8[] calldata answers) external {
        Quiz memory _quiz = quizs[quizId];

        require(!_isDoneQuiz(msg.sender, quizId), "You did the quiz already!");
        require(_quiz.rightAnswers.length == answers.length, "You need to answer all questions!");
        require(_quiz.startTime < block.timestamp, "Quiz haven't started yet!");
        require(_quiz.endTime > block.timestamp, "Quiz has ended already!");

        uint8 _numberOfRightAnswers;
        for (uint i=0; i < answers.length; i++) {
            if (answers[i] == _quiz.rightAnswers[i]) {
                _numberOfRightAnswers++;
            }
        }

        Result memory _result = Result({ 
            quizId : quizId,
            user: msg.sender,
            answers: answers,
            numberOfRightAnswers: _numberOfRightAnswers,
            createdAt: block.timestamp
        });
        userResults[msg.sender].push(_result);

        emit AnswerEvent(msg.sender, quizId, _numberOfRightAnswers, block.timestamp);
    }
}