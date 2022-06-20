/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

// File: contracts/HeadsTails.sol


pragma solidity ^0.8.9;




contract HeadsTails is Ownable {

    using Counters for Counters.Counter;

    struct QuestionFee {
        uint256 contractFee;            // contract fee
        uint256 submitterFee;            // submitter fee
        address submitter;               // submitter
    }

    struct QuestionStatus {
        bool started;                   // started
        bool answered;                  // answered
        bool stakeable;                 // stakeable
        bool canceled;                  // canceled
    }

    struct Question {
        uint256 index;                  // index
        address token;                  // token address

        uint256 trueAmount;             // true amount
        uint256 trueCounter;            // true counter
        uint256 falseAmount;            // false amount
        uint256 falseCounter;           // false counter

        uint256 startDate;              // start date
        uint256 endDate;                // end date

        QuestionFee questionFee;        // question fee
        
        bool answer;                    // answer
        uint256 answeredDate;           // answered date

        uint256 canceledDate;           // answered date

        QuestionStatus status;          // status
    }

    struct StakeTokenInfo {
        uint256 index;                  // index
        address token;                  // token address
        uint256 maxStakeAmount;         // max stake amount
        uint256 minStakeAmount;         // min stake amount

        uint256 totalStakeAmount;       // total stake amount
        uint256 totalWinningAmount;     // total winning amount
        uint256 commissionAmount;       // commission amount

        bool enabled;                   // enabled
    }

    struct StakeInfo {
        uint256 amount;                 // amount
        bool answer;                    // answer
        bool processed;                 // processed
    }

    Counters.Counter public questionCounter;

    Counters.Counter public stakeTokenCounter;

    Counters.Counter public clientCounter;

    // contract fee percent (1~1000 / 10000 => [0.1% ~ 10%])
    uint256 public contractFee;

    // submitter fee percent (1~100 / 10000 => [0.1% ~ 1%])
    uint256 public submitterFee;

    uint256 public ANSWERING_PERIOD;

    // questionCounter => Question
    mapping(uint256 => Question) public questionList;

    // client address => questionId => StakeInfo
    mapping(address => mapping(uint256 => StakeInfo)) public stakingList;

    // address => bool
    mapping(address => bool) public clientList;

    // token => StakeToken
    mapping(address => StakeTokenInfo) public tokenList;

    // token index => token address
    mapping(uint256 => address) public stakeTokenIndices;

    event SetContractFee(uint256 contractFee);
    event SetSubmitterFee(uint256 submitterFee);
    event CreateQuestion(uint256 index, address indexed token, uint256 endDate, address indexed submitter);
    event StakeToken(uint256 questionId, address indexed client, bool answer, uint256 stakeAmount);
    event AddStakeToken(address indexed token, uint256 maxStakeAmount, uint256 minStakeAmount);
    event SetMaxStakeAmount(address indexed token, uint256 maxStakeAmount);
    event SetMinStakeAmount(address indexed token, uint256 minStakeAmount);
    event SetStakeTokenStatus(address indexed token, bool status);
    event SetStakeable(uint256 questionId, bool stakeable);
    event AnswerQuestion(uint256 questionId, bool answer, uint256 contractFee, uint256 submitterFee);
    event CancelQuestion(uint256 questionId);
    event Unstake(uint256 questionId, address indexed client);
    event Harvest(uint256 questionId, address indexed client, uint256 amount);
    event WithDraw(address indexed token, address indexed to, uint256 amount);

    constructor() {
        contractFee = 500;
        ANSWERING_PERIOD = 60 * 60 * 24 * 7;
        submitterFee = 10;
    }

    /**
    * @param _contractFee 1 ~ 1000 / 10000 (0.01% ~ 10%)
    **/
    function setContractFee(uint256 _contractFee) external onlyOwner {
        require(_contractFee > 0, "HeadsTails: Contract fee should be a positive number.");
        require(_contractFee <= 1000, "HeadsTails: Contract fee should be less than 10%.");

        contractFee = _contractFee;

        emit SetContractFee(_contractFee);
    }

    /**
    * @param _submitterFee 1 ~ 100 / 10000 => (0.01% ~ 1%)
    **/
    function setSubmitterFee(uint256 _submitterFee) external onlyOwner {
        require(_submitterFee > 0, "HeadsTails: Submitter fee should be a positive number.");
        require(_submitterFee <= 100, "HeadsTails: Submitter fee should be less than 1%.");

        submitterFee = _submitterFee;

        emit SetSubmitterFee(_submitterFee);
    }

    function addStakeToken(address token, uint256 maxStakeAmount, uint256 minStakeAmount) external onlyOwner {
        require( token != address(0), 
            "HeadsTails: The zero address should not be a stake token.");
        require( token != stakeTokenIndices[tokenList[token].index], 
            "HeadsTails: Token has been already added.");
        require( minStakeAmount > 0, 
            "HeadsTails: Min stake amount should be a positive number.");
        if(maxStakeAmount > 0) {
            require( minStakeAmount <= maxStakeAmount, 
                "HeadsTails: Min stake amount should be smaller than max stake amount.");
        }
        
        StakeTokenInfo memory _stakeToken = StakeTokenInfo({
            index: stakeTokenCounter.current(),
            token: token,
            maxStakeAmount: maxStakeAmount,
            minStakeAmount: minStakeAmount,
            totalStakeAmount: 0,
            totalWinningAmount: 0,
            commissionAmount: 0,
            enabled: true
        });

        stakeTokenIndices[stakeTokenCounter.current()] = token;

        tokenList[token] = _stakeToken;

        stakeTokenCounter.increment();

        emit AddStakeToken(token, maxStakeAmount, minStakeAmount);
    }

    /**
    * @param token token address
    * @param maxStakeAmount max stake amount
    **/
    function setMaxStakeAmount(address token, uint256 maxStakeAmount) external onlyOwner{
        StakeTokenInfo storage tokenInfo = tokenList[token];
        require( token != address(0), 
            "HeadsTails: The zero address should not be a stake token.");
        require( token == stakeTokenIndices[tokenList[token].index], 
            "HeadsTails: The token is not added as a supported token.");
        if(maxStakeAmount > 0){
            require(maxStakeAmount >= tokenInfo.minStakeAmount, 
                "HeadsTails: Max stake amount should be greater than min stake amount.");
        }
        
        tokenList[token].maxStakeAmount = maxStakeAmount;

        emit SetMaxStakeAmount(token, maxStakeAmount);
    }

    /**
    * @param token token address
    * @param minStakeAmount max stake amount
    **/
    function setMinStakeAmount(address token, uint256 minStakeAmount) external onlyOwner{
        StakeTokenInfo storage tokenInfo = tokenList[token];
        require( token != address(0), 
            "HeadsTails: The zero address should not be a stake token.");
        require( token == stakeTokenIndices[tokenList[token].index], 
            "HeadsTails: The token is not added as a supported token.");
        require( minStakeAmount > 0, 
            "HeadsTails: Min stake amount should be a positive number.");
        if(tokenInfo.maxStakeAmount > 0){
            require( minStakeAmount <= tokenInfo.maxStakeAmount, 
                "HeadsTails: Min stake amount should be smaller than max stake amount.");
        }
        
        tokenList[token].minStakeAmount = minStakeAmount;

        emit SetMinStakeAmount(token, minStakeAmount);
    }

    /**
    * @param token token address
    * @param status status
    **/
    function setStakeTokenStatus(address token, bool status) external onlyOwner {
        require( token != address(0),
            "HeadsTails: The zero address should not be a stake token.");
        require( token == stakeTokenIndices[tokenList[token].index], 
            "HeadsTails: The token is not added as a supported token.");
        
        tokenList[token].enabled = status;

        emit SetStakeTokenStatus(token, status);
    }

    /**
    * @param questionId question id
    * @param stakeable bool
    **/
    function setStakeable(uint256 questionId, bool stakeable) external onlyOwner {
        Question storage question = questionList[questionId];
        require(question.status.started == true, 
            "HeadsTails: Question is not started.");
        require(question.status.answered == false, 
            "HeadsTails: Question has already been answered.");
        require(block.timestamp <= question.endDate, 
            "HeadsTails: Question has already ended.");
        
        question.status.stakeable = stakeable;

        emit SetStakeable(questionId, stakeable);
    }

    /**
    * @param endDate question closed date
    * @param token token address
    * @param submitter submitter address
    **/    
    function createQuestion(
        address token,
        uint256 endDate,
        address submitter
    )
        external
        onlyOwner
    {
        require(tokenList[token].enabled == true, 
            "HeadsTails: The token is not enabled as a staked token.");
        require(endDate > block.timestamp, 
            "HeadsTails: End date should be greater than the current time.");

        QuestionFee memory questionFee = QuestionFee({
            contractFee: contractFee,
            submitterFee: submitterFee,
            submitter: submitter
        });

        QuestionStatus memory questionStatus = QuestionStatus({
            started: true,
            answered: false,
            stakeable: true,
            canceled: false
        });

        Question memory question = Question({
            index: questionCounter.current(),
            startDate: block.timestamp,
            endDate: endDate,
            questionFee: questionFee,
            answeredDate: 0,
            canceledDate: 0,
            trueAmount: 0,
            falseAmount: 0,
            trueCounter: 0,
            falseCounter: 0,
            token: token,
            answer: false,
            status: questionStatus
        });

        questionList[questionCounter.current()] = question;

        questionCounter.increment();

        emit CreateQuestion(question.index, token, endDate, submitter);
    }

    /**
    * @param questionId question id
    * @param answer client answer
    * @param stakeAmount amount
    **/
    function stakeToken(
        uint256 questionId,
        bool answer,
        uint256 stakeAmount
    ) 
        external
        payable
    {
        Question storage question = questionList[questionId];
        StakeInfo storage stakeInfo = stakingList[msg.sender][questionId];
        StakeTokenInfo storage tokenInfo = tokenList[question.token];
        uint256 _stakeAmount = question.token == address(this) ? msg.value : stakeAmount;
        require(question.status.started == true, 
            "HeadsTails: Question has not started.");
        require(question.status.answered == false, 
            "HeadsTails: Question has already been answered.");
        require(question.status.canceled == false, 
            "HeadsTails: Question has already been canceled.");
        require(question.status.stakeable == true, 
            "HeadsTails: Staking is no longer allowed for this Question");
        require(block.timestamp <= question.endDate, 
            "HeadsTails: Question has ended already.");
        require(stakeAmount >= tokenInfo.minStakeAmount, 
            "HeadsTails: Stake amount should be greater than the token min stake amount.");
        if(stakeInfo.amount > 0){
            require(stakeInfo.answer == answer, 
                "HeadsTails: You cannot change the answer.");
        }
        if(tokenList[question.token].maxStakeAmount > 0){
            require(tokenList[question.token].maxStakeAmount >= (stakeInfo.amount + _stakeAmount), 
                "HeadsTails: Stake amount should be smaller than the available amount.");
        }
        if(question.token == address(this)){
            require(msg.value >= stakeAmount, 
                "HeadsTails: Your native token amount is insufficient for this stake.");
        }else{
            require(IERC20(question.token).balanceOf(msg.sender) >= stakeAmount, 
                "HeadsTails: Your token balance is insufficient for this stake.");
            require(IERC20(question.token).allowance(msg.sender, address(this)) >= stakeAmount, 
                "HeadsTails: Your token allowance amount is insufficient for this stake.");
        }
        
        answer ? question.trueAmount += _stakeAmount : question.falseAmount += _stakeAmount;

        if(!clientList[msg.sender]){
            clientCounter.increment();
            clientList[msg.sender] = true;
        }

        if(stakeInfo.amount == 0){
            StakeInfo memory _stakeInfo = StakeInfo({
                amount: 0,
                answer: answer,
                processed: false
            });

            stakingList[msg.sender][questionId] = _stakeInfo;

            answer ? question.trueCounter++ : question.falseCounter++;
        }
        
        stakeInfo.amount += _stakeAmount;

        tokenList[question.token].totalStakeAmount += _stakeAmount;

        if(question.token != address(this)){
            IERC20(question.token).transferFrom(msg.sender, address(this), _stakeAmount);
        }

        emit StakeToken(questionId, msg.sender, answer, _stakeAmount);
    }

    /**
    * @param questionId question id
    **/
    function unstake(uint256 questionId) external {
        Question storage question = questionList[questionId];
        StakeInfo storage stakeInfo = stakingList[msg.sender][questionId];
        uint256 drawDate = question.endDate + ANSWERING_PERIOD;

        require(question.status.answered == false , 
            "HeadsTails: Question has been already answered.");
        if(question.status.canceled == false){
            require(block.timestamp > drawDate,
                "HeadsTails: You can unstake if the question is not answered after 1 week of the end date");
        }
        require(!stakeInfo.processed, 
            "HeadsTails: You have already unstaked.");
        require(stakeInfo.amount > 0,
            "HeadsTails: You have not staked tokens in this Question");
        if(question.token == address(this)){
            require(address(this).balance >= stakeInfo.amount,
                        "HeadsTails: Out of native token balance.");
        }else{
            require(IERC20(question.token).balanceOf(address(this)) >= stakeInfo.amount,
                        "HeadsTails: Out of balance.");
        }
        
        stakeInfo.processed = true;

        if(question.token == address(this)){
            (bool success, ) = (msg.sender).call{value: stakeInfo.amount}("");
            require(success, "HeadsTails: Unstake failed");
        }else{
            IERC20(question.token).transfer(msg.sender, stakeInfo.amount);
        }

        emit Unstake(questionId, msg.sender);
    }

    /**
    * @param questionId question id
    **/
    function harvest(uint256 questionId) external {
        Question storage question = questionList[questionId];
        StakeInfo storage stakeInfo = stakingList[msg.sender][questionId];

        require(question.status.answered == true,
            "HeadsTails: Question has not been answered.");
        require(question.status.canceled == false,
            "HeadsTails: Question has not been canceled.");
        require(question.answer == stakeInfo.answer,
            "HeadsTails: Your answer is wrong.");
        require(stakeInfo.amount > 0,
            "HeadsTails: You have not staked tokens in this Question");
        require(!stakeInfo.processed, 
            "HeadsTails: You have already claimed your profits.");
        require(question.trueCounter > 0, 
            "HeadsTails: There is not any client to take part in the TRUE side.");
        require(question.falseCounter > 0, 
            "HeadsTails: There is not any client to take part in the FALSE side.");

        QuestionFee memory questionFee = question.questionFee;

        uint256 _totalAmount = (question.trueAmount + question.falseAmount) * (10000 - questionFee.contractFee - questionFee.submitterFee) / 10000;
        uint256 _winningAmount = question.answer ? question.trueAmount : question.falseAmount;
        uint256 _amount = _totalAmount * stakeInfo.amount / _winningAmount;

        if(question.token == address(this)){
            require(address(this).balance >= _amount,
                        "HeadsTails: Out of native token balance.");
        }else{
            require(IERC20(question.token).balanceOf(address(this)) >= _amount,
                        "HeadsTails: Out of balance.");
        }
        
        stakeInfo.processed = true;

        if(question.token == address(this)){
            (bool success, ) = (msg.sender).call{value: _amount}("");
            require(success, "HeadsTails: Harvest failed");
        }else{
            IERC20(question.token).transfer(msg.sender, _amount);
        }

        emit Harvest(questionId, msg.sender, _amount);

    }

    /**
    * @param questionId question id
    * @param answer answer
    **/
    function answerQuestion(
        uint256 questionId, 
        bool answer
    ) 
        external
        onlyOwner
    {
        Question storage question = questionList[questionId];
        require(question.status.started == true, 
            "HeadsTails: Question has not started.");
        require(question.status.answered == false, 
            "HeadsTails: Question has been answered.");
        require(block.timestamp >= question.endDate,
            "HeadsTails: The End Date has not been reached for this question");
        require(block.timestamp <= question.endDate + ANSWERING_PERIOD,
            "HeadsTails: As 7 Days have passed after end date, its too late to answer this question.");
        
        question.answer = answer;
        question.answeredDate = block.timestamp;
        question.status.answered = true;

        address _submitter = question.questionFee.submitter;

        uint256 _totalAmount = question.trueAmount + question.falseAmount;
        uint256 _commissionAmount = _totalAmount * contractFee / 10000;
        uint256 _submitterAmount = _submitter != address(0) ? _totalAmount * submitterFee / 10000 : 0;
        uint256 _winningAmount = _totalAmount - _commissionAmount - _submitterAmount;

        StakeTokenInfo storage _stakeTokenInfo = tokenList[question.token];
        _stakeTokenInfo.totalWinningAmount += _winningAmount;
        _stakeTokenInfo.commissionAmount += _commissionAmount;

        if(_submitterAmount > 0){
            if(question.token == address(this)){
                require(address(this).balance >= _submitterAmount, 
                    "HeadsTails: Out of native token balance.");
                (bool success, ) = (_submitter).call{value: _submitterAmount}("");
                require(success, "HeadsTails: Answer failed");
            }else{
                require(IERC20(question.token).balanceOf(address(this)) >= _submitterAmount, 
                "HeadsTails: Out of balance.");
                
                IERC20(question.token).transfer(_submitter, _submitterAmount);
            }
        }

        emit AnswerQuestion(questionId, answer, contractFee, submitterFee);

    }

    /**
    * @param questionId question id
    **/
    function cancelQuestion(
        uint256 questionId
    ) 
        external
        onlyOwner
    {
        Question storage question = questionList[questionId];
        require(question.status.started == true, 
            "HeadsTails: Question has not started.");
        require(question.status.answered == false, 
            "HeadsTails: Question has been answered.");
        require(question.status.canceled == false, 
            "HeadsTails: Question has been canceled.");
        require(block.timestamp >= question.endDate,
            "HeadsTails: You can cancel the question after the end date.");
        require(question.trueCounter == 0 || question.falseCounter == 0,
            "HeadsTails: You can cancel the question when the true counter equals zero or the false counter equals zero.");
        
        question.status.canceled = true;
        question.canceledDate = block.timestamp;

        emit CancelQuestion(questionId);

    }

    /**
    * @param token token address
    * @param to address
    **/
    function withdraw(address token, address payable to) external onlyOwner {
        require( token != address(0), 
            "HeadsTails: The zero address should not be a stake token.");
        require( to != address(0), 
            "HeadsTails: The zero address should not be a transfer address.");

        StakeTokenInfo storage _stakeTokenInfo = tokenList[token];
        uint256 _amount = _stakeTokenInfo.commissionAmount;
        if(_stakeTokenInfo.maxStakeAmount > 0 && _stakeTokenInfo.commissionAmount > _stakeTokenInfo.maxStakeAmount)
            _amount = _stakeTokenInfo.maxStakeAmount;
        
        require( _amount > 0, 
            "HeadsTails: Amount should be a postive number.");
        if(token == address(this)){
            require(address(this).balance >= _amount, 
                "HeadsTails: Out of native token balance.");
        }else{
            require( IERC20(token).balanceOf(address(this)) >= _amount, 
                "HeadsTails: Out of balance.");
        }

        _stakeTokenInfo.commissionAmount -= _amount;

        if(token == address(this)) {
            (bool success, ) = (to).call{value: _amount}("");
            require(success, "HeadsTails: Withdraw failed");
        }else{
            IERC20(token).transfer(to, _amount);
        }

        emit WithDraw(token, to, _amount);
    }

}