// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IQuizGameV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract QuizGameV2 is IQuizGameV2, Ownable {
    bytes32 public salt = bytes32("123123123");
    uint256 public quizIds;
    mapping(uint256 => Quiz) public idToQuiz;
    mapping(address => mapping(uint256 => bool)) public withdrawResults;
    mapping(address => mapping(uint256 => bool)) public participated;
    mapping(address => mapping(uint256 => bytes32[])) public answers;
    bool public isQuizRunning;
    uint256 public quizRunning;

    // EVENTS
    event NewQuiz(IERC20 _token, uint256 _tokenReward, string[] _questions);
    event StartQuiz(uint256 _quizID);
    event Guess(uint256 _quizID, bytes32[] _answers);
    event FinishQuiz(uint256 _quizID, bytes32[] answers);
    event UpdateTotalWinners(uint256 _quizId, uint256 _totWinners);
    event WinnerWithdraw(uint256 _quizId, address winner, uint256 amount);

    struct Quiz {
        uint256 id;
        IERC20 token;
        uint256 tokenReward;
        string[] questions;
        bytes32[] answers;
        Status status;
        address[] players;
        uint256 totWinners;
    }

    constructor() {
        quizIds = 0;
    }

    // VIEW FUNCTIONS
    function hashString(string memory str) external view returns (bytes32) {
        return keccak256(abi.encodePacked(salt, str));
    }

    // GET QUIZ INFO
    function getInfo(uint256 _quizId)
        public
        view
        returns (
            IERC20 token,
            uint256 tokenReward,
            string[] memory questions,
            bytes32[] memory _answers,
            Status status,
            address[] memory players,
            uint256 totWinners
        )
    {
        Quiz memory quiz = idToQuiz[_quizId];
        return (
            quiz.token,
            quiz.tokenReward,
            quiz.questions,
            quiz.answers,
            quiz.status,
            quiz.players,
            quiz.totWinners
        );
    }

    function getTotalWinners(uint256 _quizId)
        public
        view
        returns (uint256 totalWinners)
    {
        Quiz memory quiz = idToQuiz[_quizId];
        require(
            quiz.status == Status.Finished,
            "Quiz status should be Finished"
        );
        for (uint i = 0; i < quiz.players.length; i++) {
            bool winner = _getPlayerResult(_quizId, quiz.players[i]);
            if (winner) {
                totalWinners = totalWinners + 1;
            }
        }
    }

    function getPlayerResult(uint256 _quizId, address _player)
        external
        view
        returns (bool)
    {
        return _getPlayerResult(_quizId, _player);
    }

    /* PUBLIC FUNCTIONS TO BE CALL BY OWNER */

    // CREATE QUIZ (ONLY OWNER)
    function createNewQuiz(
        IERC20 _token,
        uint256 _tokenReward,
        string[] calldata _questions
    ) external onlyOwner returns (uint256) {
        address[] memory thePlayers;
        bytes32[] memory theAnswers;
        Quiz memory newQuiz = Quiz({
            id: quizIds,
            token: _token,
            tokenReward: _tokenReward,
            questions: _questions,
            answers: theAnswers,
            status: Status.NotStarted,
            players: thePlayers,
            totWinners: 0
        });
        idToQuiz[quizIds] = newQuiz;
        quizIds = quizIds + 1;
        _token.transferFrom(msg.sender, address(this), _tokenReward);
        emit NewQuiz(_token, _tokenReward, _questions);
        return newQuiz.id;
    }

    // START QUIZ (ONLY OWNER)
    function startQuiz(uint256 _quizId) external onlyOwner {
        require(isQuizRunning == false, "Only one quiz at a time");
        Quiz storage quiz = idToQuiz[_quizId];
        require(
            quiz.status == Status.NotStarted,
            "Quiz status should be NotStarted"
        );
        quiz.status = Status.Started;
        isQuizRunning = true;
        quizRunning = _quizId;
        emit StartQuiz(_quizId);
    }

    // FINISH QUIZ (ONLY OWNER)
    function finishQuiz(uint256 _quizId, bytes32[] calldata _answers)
        external
        onlyOwner
    {
        Quiz storage quiz = idToQuiz[_quizId];
        require(quiz.status == Status.Started, "Quiz status should be Started");
        quiz.status = Status.Finished;
        isQuizRunning = false;
        quiz.answers = _answers;
        emit FinishQuiz(_quizId, _answers);
    }

    // UPDATE TOTAL WINNERS (ONLY OWNER)
    function updateTotalWinners(uint256 _quizId, uint256 _totWinners)
        public
        onlyOwner
    {
        Quiz storage quiz = idToQuiz[_quizId];
        require(
            quiz.status == Status.Finished,
            "Quiz status should be Finished"
        );
        quiz.status = Status.WinnersUpdated;
        quiz.totWinners = _totWinners;
        emit UpdateTotalWinners(_quizId, _totWinners);
    }

    // EMERGENCY WITHDRAW (ONLY OWNER)
    function emergencyWithdraw(IERC20 _token) external onlyOwner {
        uint256 totalBalance = _token.balanceOf(address(this));
        _token.transfer(msg.sender, totalBalance);
    }

    /* PUBLIC FUNCTIONS */

    // GUESS ANSWERS (PLAYERS)
    function guess(uint256 _quizID, bytes32[] calldata _answers) external {
        Quiz storage quiz = idToQuiz[_quizID];
        require(quiz.status == Status.Started, "Quiz status should be Started");
        require(participated[msg.sender][_quizID] == false, "Already guess");
        require(quizRunning == _quizID, "quiz not running");
        participated[msg.sender][_quizID] = true;
        quiz.players.push(msg.sender);
        answers[msg.sender][_quizID] = _answers;

        emit Guess(_quizID, _answers);
    }

    // WITHDRAW REWARDS (PLAYERS)
    function withdraw(uint256 _quizId) public {
        Quiz memory quiz = idToQuiz[_quizId];
        require(
            quiz.status == Status.WinnersUpdated,
            "Quiz status should be Finished"
        );
        require(_getPlayerResult(_quizId, msg.sender) == true, "Not a winner");
        require(
            withdrawResults[msg.sender][_quizId] == false,
            "Already withdraw prize"
        );

        withdrawResults[msg.sender][_quizId] = true;

        uint256 winnerReward = _transferWinnerPrize(
            quiz.token,
            quiz.tokenReward,
            quiz.totWinners
        );

        emit WinnerWithdraw(_quizId, msg.sender, winnerReward);
    }

    /* PRIVATE FUNCTIONS */

    // GET PLAYERS RESULT
    function _getPlayerResult(uint256 _quizId, address _player)
        private
        view
        returns (bool winner)
    {
        Quiz memory quiz = idToQuiz[_quizId];
        if (
            participated[_player][_quizId] &&
            (quiz.status == Status.Finished ||
                quiz.status == Status.WinnersUpdated)
        ) {
            bytes32[] memory quizAnswers = quiz.answers;
            bytes32[] memory senderAnswers = answers[_player][_quizId];
            for (uint i = 0; i < quizAnswers.length; i++) {
                if (quizAnswers[i] != senderAnswers[i]) {
                    return false;
                }
            }
            winner = true;
            return winner;
        }
        return false;
    }

    // TRANSFER REWARD TO WINNER
    function _transferWinnerPrize(
        IERC20 token,
        uint256 tokenPrize,
        uint256 totWinners
    ) private returns (uint256) {
        uint256 winnerPrize = tokenPrize / totWinners;
        uint256 balanceLeft = token.balanceOf(address(this));
        if (balanceLeft < winnerPrize) {
            token.transfer(msg.sender, balanceLeft);
            return balanceLeft;
        }
        token.transfer(msg.sender, winnerPrize);
        return winnerPrize;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IQuizGameV2 {
    enum Status {
        NotStarted,
        Started,
        Finished,
        WinnersUpdated
    }

    function getInfo(uint256 _quizId)
        external
        view
        returns (
            IERC20 token,
            uint256 tokenReward,
            string[] memory questions,
            bytes32[] memory _answers,
            Status status,
            address[] memory players,
            uint256 totWinners
        );

    function getTotalWinners(uint256 _quizId)
        external
        view
        returns (uint256 totalWinners);

    function getPlayerResult(uint256 _quizId, address _player)
        external
        view
        returns (bool);

    function createNewQuiz(
        IERC20 _token,
        uint256 _tokenReward,
        string[] calldata _questions
    ) external returns (uint256);

    function startQuiz(uint256 _quizId) external;

    function guess(uint256 _quizID, bytes32[] calldata _answers) external;

    function finishQuiz(uint256 _quizId, bytes32[] calldata _answers) external;

    function updateTotalWinners(uint256 _quizId, uint256 _totWinners) external;

    function withdraw(uint256 _quizId) external;

    function emergencyWithdraw(IERC20 _token) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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