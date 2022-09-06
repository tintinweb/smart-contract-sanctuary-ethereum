/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

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

contract QuizGameV2 {
    bytes32 public salt = bytes32("123123123");
    address public manager;
    uint256 public quizIds;
    Quiz[] public quizzes;
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

    enum Status {
        NotStarted,
        Started,
        Finished,
        WinnersUpdated
    }
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

    modifier onlyOwner() {
        require(msg.sender == manager, "Only Manager");
        _;
    }

    constructor() {
        manager = msg.sender;
        quizIds = 0;
    }

    function hashString(string memory str) public view returns (bytes32) {
        return keccak256(abi.encodePacked(salt, str));
    }

    // Agregar max players limit
    function createNewQuiz(
        IERC20 _token,
        uint256 _tokenReward,
        string[] calldata _questions
    ) public onlyOwner returns (uint256) {
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
        quizzes.push(newQuiz);
        idToQuiz[quizIds] = newQuiz;
        quizIds = quizIds + 1;
        _token.transferFrom(msg.sender, address(this), _tokenReward);
        emit NewQuiz(_token, _tokenReward, _questions);
        return newQuiz.id;
    }

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

    function guess(uint256 _quizID, bytes32[] calldata _answers) public {
        Quiz storage quiz = idToQuiz[_quizID];
        require(quiz.status == Status.Started, "Quiz status should be Started");
        require(participated[msg.sender][_quizID] == false, "Already guess");
        require(quizRunning == _quizID, "quiz not running");
        participated[msg.sender][_quizID] = true;
        quiz.players.push(msg.sender);
        answers[msg.sender][_quizID] = _answers;

        emit Guess(_quizID, _answers);
    }

    function finishQuiz(uint256 _quizId, bytes32[] calldata _answers)
        public
        onlyOwner
    {
        Quiz storage quiz = idToQuiz[_quizId];
        require(quiz.status == Status.Started, "Quiz status should be Started");
        quiz.status = Status.Finished;
        isQuizRunning = false;
        quiz.answers = _answers;
        emit FinishQuiz(_quizId, _answers);
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

        // need to reestric number of players
        for (uint i = 0; i < quiz.players.length; i++) {
            bool winner = _getPlayerResult(_quizId, quiz.players[i]);
            if (winner) {
                totalWinners = totalWinners + 1;
            }
        }
    }

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

    function getPlayerResult(uint256 _quizId) external view returns (bool) {
        return _getPlayerResult(_quizId, msg.sender);
    }

    function _getPlayerResult(uint256 _quizId, address player)
        public
        view
        returns (bool winner)
    {
        Quiz memory quiz = idToQuiz[_quizId];
        if (
            participated[player][_quizId] &&
            (quiz.status == Status.Finished ||
                quiz.status == Status.WinnersUpdated)
        ) {
            bytes32[] memory quizAnswers = quiz.answers;
            bytes32[] memory senderAnswers = answers[player][_quizId];
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

    function emergencyWithdraw(IERC20 _token) external onlyOwner {
        uint256 totalBalance = _token.balanceOf(address(this));
        _token.transfer(msg.sender, totalBalance);
    }

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
}