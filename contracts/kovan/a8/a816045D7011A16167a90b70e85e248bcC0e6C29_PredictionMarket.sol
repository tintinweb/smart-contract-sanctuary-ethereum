/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: PredictionMarket.sol

/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/


pragma solidity ^0.6.2;

abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

     constructor () public  {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}




contract AdminManaged {

	mapping (address => bool) public administratorsMap;
	mapping (address => bool) public trustedSources;
	address public owner;

	event LogAdminAdded(address sender, address admin);
	event LogAdminRemoved(address sender, address admin);
	event LogTrustedSourceAdded(address sender, address trustedSource);
	event LogTrustedSourceRemoved(address sender, address trustedSource);

	constructor () public{
		owner = msg.sender;
		administratorsMap[msg.sender] = true;
		trustedSources[msg.sender] = true;
	}

	// Modifiers

	modifier onlyAdmin{
		require(isAdmin(msg.sender));
		_;
	}

	modifier onlyOwner{
		require(msg.sender == owner);
		_;
	}

	modifier onlyTrustedSource{
		require(isTrustedSource(msg.sender));
		_;
	}

	// Trusted Sources management

	function addTrustedSource(address trustedSource)
		public
		onlyAdmin
		returns(bool success)
	{
		trustedSources[trustedSource] = true;
		emit LogTrustedSourceAdded(msg.sender, trustedSource);
		return true;
	}

	function removeTrustedSource(address trustedSource)
		public
		onlyAdmin
		returns(bool success)
	{
		require(trustedSource != owner);
		trustedSources[trustedSource] = false;
		emit LogTrustedSourceRemoved(msg.sender, trustedSource);
		return true;
	}

	function isTrustedSource(address trustedSource)
		public
        view
		returns(bool isIndeed)
	{
		return trustedSources[trustedSource];
	}

	// Admin management

	function addAdmin(address admin)
		public
		onlyOwner
		returns(bool adminAdded)
	{
		administratorsMap[admin] = true;
		emit LogAdminAdded(msg.sender, admin);
		return true;
	}

	function removeAdmin(address admin)
		public
		onlyOwner
		returns(bool adminDeleted)
	{
		administratorsMap[admin] = false;
		emit LogAdminRemoved(msg.sender, admin);
		return true;
	}

	function isAdmin(address admin)
		public
        view
		returns(bool isIndeed)
	{
		return administratorsMap[admin];
	}

}




contract PredictionMarket is AdminManaged,ReentrancyGuard {
    Marketdetails[] public markets;
    enum BetStatus { Pending, Canceled, Resolved }
    enum PredictionStatus {
      Live,
      InSettlement,
      Settled
    }
    enum MarketType {
      Rapid,
      Hourly,
      Weekly,
      Sports
    }
    mapping (address => uint) public balance;
    mapping (address => uint) public unClaimedBalance;

    struct Marketdetails {
    	string question;
    	uint betAmount;
    	uint betCount;
    	uint betAmountYesTot;
    	uint betCountYes;
    	uint betAmountNoTot;
    	uint betCountNo;
        uint startTime;
        uint endTime;
    	bool result;
        PredictionStatus predictionStatus;
        MarketType marketType;
        mapping(address => uint) betAmountYes;
        mapping(address => uint) winningAmount;
        address  [] betters;
        mapping(address => uint) betAmountNo;
    	uint listPointer;
    }
    
    IERC20 public token;

    event MarketCreated(uint id, string name,string description,uint startTime, uint endTime, MarketType marketType);
    event PayoutSent(uint id, address sender, uint amount);
    event Predict(uint id, address sender, uint amountBetted, bool result);
    event MarketSettled(uint id, bool anwser, uint time) ;

     modifier marketLive(uint _marketId) {
        require(markets[_marketId].startTime >= block.timestamp,"Market is not accepting prediction anymore");
        require(markets[_marketId].predictionStatus == PredictionStatus.Live,"Market is not accepting prediction anymore");
        _;
    }
    
    modifier marketInSettled(uint _marketId) {
        require(markets[_marketId].endTime < block.timestamp,"Market is Insettle");
        require(markets[_marketId].predictionStatus == PredictionStatus.InSettlement,"Market is Market is Insettle");
        _;
    }
    
   constructor (
        IERC20 _tokenAddress
        
    ) public {
        token = _tokenAddress;
    }

    // Admins / owner functions

    function createMarket(string memory _question,uint [] calldata _marketTimes,uint _type)
        onlyAdmin
    	public
    	returns (uint _questionId)
    {
        Marketdetails memory question;
        question.question = _question;
        question.predictionStatus = PredictionStatus.Live;
        question.startTime = _marketTimes[0];
        question.endTime = _marketTimes[1];
        if(_type == 0){
         question.marketType = MarketType.Rapid;
        }else if(_type == 1){
         question.marketType = MarketType.Hourly;
        }else if(_type == 2){
            question.marketType = MarketType.Weekly;
         }else{
            question.marketType = MarketType.Sports;
        }
        markets.push(question);
        uint questionId = markets.length - 1;
        markets[questionId].listPointer = questionId;
        emit MarketCreated(questionId, _question,_question,_marketTimes[0],_marketTimes[1],question.marketType);
        return questionId;
    }

    function settleMarket(uint id, bool _result)
        public
        onlyTrustedSource
        returns(bool success)
    {
        require(isMarket(id),"Invalid market id");

        markets[id].result = _result;
        markets[id].predictionStatus = PredictionStatus.Settled;
        updatePredictorWinners(id);
        
        emit MarketSettled(id, _result,block.timestamp);
        return true;
    }


    // Public functions

    function predictMarket(uint id, bool _vote, uint amount)
    	public
        returns (bool success)
    {
        require(amount>0);
        require(isMarket(id));
        require(markets[id].startTime >= block.timestamp,"Market is not accepting prediction anymore");
        require(markets[id].predictionStatus == PredictionStatus.Live,"Market is not accepting prediction anymore");
       
        require(markets[id].predictionStatus == PredictionStatus.Live,"Market is not accepting prediction anymore");
        // Can't vote twice on the same question
        require(markets[id].betAmountYes[msg.sender]==0 && markets[id].betAmountNo[msg.sender]==0);
       
        markets[id].betAmount += amount;
        markets[id].betCount += 1;
        markets[id].betters.push(msg.sender);
        if (_vote) {
            markets[id].betCountYes += 1;
            markets[id].betAmountYesTot += amount;
            markets[id].betAmountYes[msg.sender] = amount;
        } else {
            markets[id].betCountNo += 1;
            markets[id].betAmountNoTot += amount;
            markets[id].betAmountNo[msg.sender] = amount;
        }
        token.transferFrom(msg.sender,address(this),amount);
        emit Predict(id, msg.sender, amount, _vote);
        return true;
    }

    function withdrawByMarket(uint id) 
        public
        nonReentrant
        returns(bool success)
    {
    	require(isMarket(id),"Invalid market id");
        require(markets[id].predictionStatus == PredictionStatus.Settled,"Market is still active");
        require(markets[id].betAmountYes[msg.sender] != 0x0 || markets[id].betAmountNo[msg.sender] != 0x0);
        require(markets[id].winningAmount[msg.sender] != 0 );

        if(!updatePredictorBalance(msg.sender, id)) revert();
        uint betAmount = 0;
        if(markets[id].betAmountYes[msg.sender] != 0x0){
            betAmount = markets[id].betAmountYes[msg.sender];
        }else if(markets[id].betAmountNo[msg.sender] != 0x0){
            betAmount = markets[id].betAmountNo[msg.sender];
        }
        uint amount = markets[id].winningAmount[msg.sender] + betAmount;
        unClaimedBalance[msg.sender] -= amount;
        balance[msg.sender] = 0 ;
        markets[id].winningAmount[msg.sender] = 0 ;
        token.transfer(msg.sender,amount);
        emit PayoutSent(id, msg.sender, amount);
        return true;
    }

    // Private function

    function updatePredictorBalance(address gambler, uint qId)
        private
        returns(bool success)
    {
        require(markets[qId].predictionStatus == PredictionStatus.Settled);
        bool qAnswer = markets[qId].result;
        uint reward;
        uint ratio;

        if (qAnswer && markets[qId].betAmountYes[gambler] != 0x0) 
        {
            uint valueBetY = markets[qId].betAmountYes[gambler];
            uint ttlValueBetY = markets[qId].betAmountYesTot;
            
            ratio = percent(valueBetY, ttlValueBetY, 3);
            reward = ratio * markets[qId].betAmount;
            reward = reward / 1000;
            
            balance[gambler] += reward;
            markets[qId].betAmountYes[gambler] = 0;
            
            return true;
        } else if (!qAnswer && (markets[qId].betAmountNo[gambler] != 0x0)) 
        {
            uint valueBetN = markets[qId].betAmountNo[gambler];
            uint ttlValueBetN = markets[qId].betAmountNoTot;
           
            ratio = percent(valueBetN, ttlValueBetN, 3);
            reward = ratio * markets[qId].betAmount;
            reward = reward / 1000;
       
            balance[gambler] += reward;
            
            // set vote AmountBetted to 0, so he cannot withdraw again
            markets[qId].betAmountNo[gambler] = 0;
            return true;
        }
        
    	 return false;   
    }

    // Private function

    function updatePredictorWinners(uint qId)
        internal
        returns(bool success)
    {
        require(markets[qId].predictionStatus == PredictionStatus.Settled);
        bool qAnswer = markets[qId].result;
        uint reward;
        uint ratio;
        for(uint i =0 ; i < markets[qId].betters.length;i++){
            if(qAnswer){
            if((markets[qId].betAmountYes[markets[qId].betters[i]] !=0x0)){
            uint valueBetY = markets[qId].betAmountYes[markets[qId].betters[i]];
            uint ttlValueBetY = markets[qId].betAmountYesTot;
             ratio = percent(valueBetY, ttlValueBetY, 3);
            reward = ratio * markets[qId].betAmount;
            reward = reward / 1000;
            unClaimedBalance[markets[qId].betters[i]] += reward;
            markets[qId].winningAmount[markets[qId].betters[i]] = reward;

         }
            
        }
        else 
            {
            if((markets[qId].betAmountNo[markets[qId].betters[i]] !=0x0)){
             uint valueBetN = markets[qId].betAmountNo[markets[qId].betters[i]];
            uint ttlValueBetN = markets[qId].betAmountNoTot;
            ratio = percent(valueBetN, ttlValueBetN, 3);
            reward = ratio * markets[qId].betAmount;
            reward = reward / 1000;
            unClaimedBalance[markets[qId].betters[i]] += reward;
            markets[qId].winningAmount[markets[qId].betters[i]] = reward;
            }
            
            }
           
          }
          return true;
         
    }

    // Private function

    

    // Getter & utils

    function getMarket(uint id)
    	view
    	public
    	returns (uint qId, string memory name, uint predictionStatus, uint betAmount, uint betCount, uint betAmountYes, uint betCountYes,
            uint betAmountNo, uint betCountNo, bool result)
    {
    	Marketdetails memory question = markets[id];
    	return (question.listPointer,
                question.question, 
                uint(question.predictionStatus),
                question.betAmount,
                question.betCount,
                question.betAmountYesTot,
                question.betCountYes,
                question.betAmountNoTot,
                question.betCountNo,
                question.result);
    }

    function getMarketCount()
        public
        view
        returns(uint count)
    {
        return markets.length;
    }

    function isMarket(uint id) 
        public 
        view 
        returns(bool isIndeed)
    {
        if(markets.length == 0) return false;
        return (markets[id].listPointer == id);
    }

    function percent(uint numerator, uint denominator, uint precision)
        public 
        pure 
        returns(uint quotient) 
    {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

}