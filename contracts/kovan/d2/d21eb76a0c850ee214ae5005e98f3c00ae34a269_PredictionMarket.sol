/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

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
    	uint maketId;
    }
    
    IERC20 public token;

    event MarketCreated(uint id, string name,string description,uint startTime, uint endTime,string state,string marketType);
    event PayoutSent(uint id, address sender, uint amount);
    event Predict(uint id, address sender, uint amountBetted, bool result,uint time,string desc);
    event MarketSettled(uint id, bool anwser, uint time, string desc) ;

     modifier marketLive(uint _marketId) {
        require(markets[_marketId].startTime > block.timestamp,"Market is not accepting prediction anymore");
        _;
    }
    
    modifier marketInSettled(uint _marketId) {
        require(markets[_marketId].endTime < block.timestamp,"Market is Insettle");
        require(markets[_marketId].predictionStatus == PredictionStatus.InSettlement,"Market is Market is Insettle");
        _;
    }
    modifier marketSettled(uint _marketId) {
        require(markets[_marketId].endTime < block.timestamp,"Market is Insettle");
        require(markets[_marketId].predictionStatus == PredictionStatus.Settled,"Market is Insettle");
        _;
    }
    
   constructor (
        IERC20 _tokenAddress
        
    ) public {
        token = _tokenAddress;
    }

    // Admins / owner functions

    function createMarket(string memory _question,string memory _description,uint [] calldata _marketTimes,uint _type)
        onlyAdmin
    	public
    	returns (uint _questionId)
    {
        Marketdetails memory market;
        market.question = _question;
        market.predictionStatus = PredictionStatus.InSettlement;
        market.startTime = _marketTimes[0];
        market.endTime = market.startTime +_marketTimes[1];
        string memory marketType ="sports";
        if(_type == 0){
         market.marketType = MarketType.Rapid;
        }else if(_type == 1){
         market.marketType = MarketType.Hourly;
        }else if(_type == 2){
            market.marketType = MarketType.Weekly;
         }else if(_type == 3){
            market.marketType = MarketType.Sports;
        }
        markets.push(market);
        uint id = markets.length - 1;
        markets[id].maketId = id;
        emit MarketCreated(id, _question,_description,_marketTimes[0],_marketTimes[1],"Insettlement",marketType);
        return id;
    }
    //  function createMarketWithVariableLiquidity(string memory _question,string memory _description,uint [] calldata _marketTimes,uint _type,uint _amount)
    //     onlyAdmin
    // 	public
    // 	returns (uint _questionId)
    // {
    //     Marketdetails memory market;
    //     market.question = _question;
    //     market.predictionStatus = PredictionStatus.Live;
    //     market.startTime = _marketTimes[0];
    //     market.endTime = _marketTimes[1];
    //     string memory marketType ="sports";
    //     if(_type == 0){
    //      market.marketType = MarketType.Rapid;
    //     }else if(_type == 1){
    //      market.marketType = MarketType.Hourly;
    //     }else if(_type == 2){
    //         market.marketType = MarketType.Weekly;
    //      }else if(_type == 3){
    //         market.marketType = MarketType.Sports;
    //     }
    //     markets.push(market);
    //     uint id = markets.length - 1;
    //     markets[id].maketId = id;
    //     predictMarket(id, true, _amount);
    //     predictMarket(id, false, _amount);
    //     emit MarketCreated(id, _question,_description,_marketTimes[0],_marketTimes[1],"Insettlement",marketType);
    //     return id;
    // }

    function settleMarket(uint _id, bool _result, string memory _desc)
        public
        onlyTrustedSource
        marketInSettled(_id)
        returns(bool success)
    {
        require(isMarket(_id),"Invalid market id");

        markets[_id].result = _result;
        markets[_id].predictionStatus = PredictionStatus.Settled;
        updatePredictorWinners(_id);
        
        emit MarketSettled(_id, _result,block.timestamp,_desc);
        return true;
    }

    // Public functions

    function predictMarket(uint _id, bool _result, uint amount,string memory _desc)
    	public
        marketLive(_id)
        returns (bool success)
    {
        require(amount>0);
        require(isMarket(_id));
        // Can't vote twice on the same question
        require(markets[_id].betAmountYes[msg.sender]==0 && markets[_id].betAmountNo[msg.sender]==0);
       
        markets[_id].betAmount += amount;
        markets[_id].betCount += 1;
        markets[_id].betters.push(msg.sender);
        if (_result) {
            markets[_id].betCountYes += 1;
            markets[_id].betAmountYesTot += amount;
            markets[_id].betAmountYes[msg.sender] = amount;
        } else {
            markets[_id].betCountNo += 1;
            markets[_id].betAmountNoTot += amount;
            markets[_id].betAmountNo[msg.sender] = amount;
        }
        token.transferFrom(msg.sender,address(this),amount);
        emit Predict(_id, msg.sender, amount, _result,block.timestamp,_desc);
        return true;
    }

    function withdrawByMarket(uint _id) 
        public
        nonReentrant
        marketInSettled(_id)
        returns(bool success)
    {
    	require(isMarket(_id),"Invalid market id");
        require(markets[_id].betAmountYes[msg.sender] != 0x0 || markets[_id].betAmountNo[msg.sender] != 0x0);
        require(markets[_id].winningAmount[msg.sender] != 0 );

        if(!updatePredictorBalance(msg.sender, _id)) revert();
        uint betAmount = 0;
        if(markets[_id].betAmountYes[msg.sender] != 0x0){
            betAmount = markets[_id].betAmountYes[msg.sender];
        }else if(markets[_id].betAmountNo[msg.sender] != 0x0){
            betAmount = markets[_id].betAmountNo[msg.sender];
        }
        uint amount = markets[_id].winningAmount[msg.sender] + betAmount;
        unClaimedBalance[msg.sender] -= amount;
        balance[msg.sender] = 0 ;
        markets[_id].winningAmount[msg.sender] = 0 ;
        token.transfer(msg.sender,amount);
        emit PayoutSent(_id, msg.sender, amount);
        return true;
    }

    // Private function

    function updatePredictorBalance(address gambler, uint _id)
        private
        returns(bool success)
    {
        require(markets[_id].predictionStatus == PredictionStatus.Settled);
        bool _result = markets[_id].result;
        uint reward;
        uint ratio;

        if (_result && markets[_id].betAmountYes[gambler] != 0x0) 
        {
            uint valueBetY = markets[_id].betAmountYes[gambler];
            uint ttlValueBetY = markets[_id].betAmountYesTot;
            
            ratio = percent(valueBetY, ttlValueBetY, 3);
            reward = ratio * markets[_id].betAmount;
            reward = reward / 1000;
            
            balance[gambler] += reward;
            markets[_id].betAmountYes[gambler] = 0;
            
            return true;
        } else if (!_result && (markets[_id].betAmountNo[gambler] != 0x0)) 
        {
            uint valueBetN = markets[_id].betAmountNo[gambler];
            uint ttlValueBetN = markets[_id].betAmountNoTot;
           
            ratio = percent(valueBetN, ttlValueBetN, 3);
            reward = ratio * markets[_id].betAmount;
            reward = reward / 1000;
       
            balance[gambler] += reward;
            
            // set vote AmountBetted to 0, so he cannot withdraw again
            markets[_id].betAmountNo[gambler] = 0;
            return true;
        }
        
    	 return false;   
    }

    // Private function

    function updatePredictorWinners(uint _id)
        internal
        returns(bool success)
    {
        require(markets[_id].predictionStatus == PredictionStatus.Settled);
        bool _result = markets[_id].result;
        uint reward;
        uint ratio;
        for(uint i =0 ; i < markets[_id].betters.length;i++){
            if(_result){
            if((markets[_id].betAmountYes[markets[_id].betters[i]] !=0x0)){
            uint valueBetY = markets[_id].betAmountYes[markets[_id].betters[i]];
            uint ttlValueBetY = markets[_id].betAmountYesTot;
             ratio = percent(valueBetY, ttlValueBetY, 3);
            reward = ratio * markets[_id].betAmount;
            reward = reward / 1000;
            unClaimedBalance[markets[_id].betters[i]] += reward;
            markets[_id].winningAmount[markets[_id].betters[i]] = reward;

         }
            
        }
        else 
            {
            if((markets[_id].betAmountNo[markets[_id].betters[i]] !=0x0)){
             uint valueBetN = markets[_id].betAmountNo[markets[_id].betters[i]];
            uint ttlValueBetN = markets[_id].betAmountNoTot;
            ratio = percent(valueBetN, ttlValueBetN, 3);
            reward = ratio * markets[_id].betAmount;
            reward = reward / 1000;
            unClaimedBalance[markets[_id].betters[i]] += reward;
            markets[_id].winningAmount[markets[_id].betters[i]] = reward;
            }
            
            }
           
          }
          return true;
         
    }


    function getMarket(uint _id)
    	view
    	public
    	returns (uint id, string memory name, uint predictionStatus, uint betAmount, uint betCount, uint betAmountYes, uint betCountYes,
            uint betAmountNo, uint betCountNo, bool result)
    {
    	Marketdetails memory question = markets[_id];
    	return (question.maketId,
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

    function isMarket(uint _id) 
        public 
        view 
        returns(bool isIndeed)
    {
        if(markets.length == 0) return false;
        return (markets[_id].maketId == _id);
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