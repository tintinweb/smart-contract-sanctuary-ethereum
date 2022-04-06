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
    mapping (address => uint) public balance;

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
    	BetStatus betStatus;
        PredictionStatus predictionStatus;
        mapping(address => uint) betAmountYes;
        mapping(address => uint) betAmountNo;
    	uint listPointer;
    }

    event MarketCreated(uint id, string name);
    event PayoutSent(uint id, address sender, uint amount);
    event Predict(uint id, address sender, uint amountBetted, bool result);
    event MarketSettled(uint id, bool anwser);

     modifier marketLive(uint _marketId) {
        require(markets[_marketId].startTime >= block.timestamp,"Market is not accepting prediction anymore");
        require(markets[_marketId].predictionStatus == PredictionStatus.Live,"Market is not accepting prediction anymore");
         require(markets[_marketId].betStatus == BetStatus.Pending,"Market is not accepting prediction anymore");
        _;
    }
    
    modifier marketInSettled(uint _marketId) {
        require(markets[_marketId].endTime < block.timestamp,"Market is Insettle");
        require(markets[_marketId].predictionStatus == PredictionStatus.InSettlement,"Market is Market is Insettle");
        _;
    }
    
   

    // Admins / owner functions

    function createMarket(string memory _question)
        onlyAdmin
    	public
    	returns (uint _questionId)
    {
        Marketdetails memory question;
        question.question = _question;
        question.betStatus = BetStatus.Pending;
        question.predictionStatus = PredictionStatus.Live;
        markets.push(question);
        uint questionId = markets.length - 1;
        markets[questionId].listPointer = questionId;
        MarketCreated(questionId, _question);
        return questionId;
    }

    function settleMarket(uint id, bool _result)
        public
        onlyTrustedSource
        returns(bool success)
    {
        require(isMarket(id),"Invalid market id");

        markets[id].result = _result;
        markets[id].betStatus = BetStatus.Resolved;
        markets[id].predictionStatus = PredictionStatus.Settled;
        MarketSettled(id, _result);
        return true;
    }

    function updateMarketToInSettle(uint id)
        public
        onlyTrustedSource
        returns(bool success)
    {
        require(isMarket(id),"Invalid market id");

        markets[id].predictionStatus = PredictionStatus.InSettlement;
        return true;
    }

    // Public functions

    function predictMarket(uint id, bool _vote)
    	payable
    	public
      
    	returns (bool success)
    {
        require(msg.value>0);
        require(isMarket(id));
        require(markets[id].startTime >= block.timestamp,"Market is not accepting prediction anymore");
        require(markets[id].predictionStatus == PredictionStatus.Live,"Market is not accepting prediction anymore");
        require(markets[id].betStatus == BetStatus.Pending,"Market is not accepting prediction anymore");
       
        require(markets[id].predictionStatus == PredictionStatus.Live,"Market is not accepting prediction anymore");
        // Can't vote twice on the same question
        require(markets[id].betAmountYes[msg.sender]==0 && markets[id].betAmountNo[msg.sender]==0);
       
        markets[id].betAmount += msg.value;
        markets[id].betCount += 1;
        
        if (_vote) {
            markets[id].betCountYes += 1;
            markets[id].betAmountYesTot += msg.value;
            markets[id].betAmountYes[msg.sender] = msg.value;
        } else {
            markets[id].betCountNo += 1;
            markets[id].betAmountNoTot += msg.value;
            markets[id].betAmountNo[msg.sender] = msg.value;
        }
        
        Predict(id, msg.sender, msg.value, _vote);
        return true;
    }

    function withdraw(uint id) 
        public
        nonReentrant
        returns(bool success)
    {
    	require(isMarket(id),"Invalid market id");
        require(markets[id].predictionStatus == PredictionStatus.Settled,"Market is still active");
        require(markets[id].betAmountYes[msg.sender] != 0x0 || markets[id].betAmountNo[msg.sender] != 0x0);

        if(!updatePredictorBalance(msg.sender, id)) revert();
        
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0 ;
        msg.sender.transfer(amount);
        PayoutSent(id, msg.sender, amount);
        return true;
    }

    // Private function

    function updatePredictorBalance(address gambler, uint qId)
        private
        returns(bool success)
    {
        require(markets[qId].betStatus == BetStatus.Resolved);
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

    // Getter & utils

    function getMarket(uint id)
    	view
    	public
    	returns (uint qId, string memory name, uint betStatus, uint betAmount, uint betCount, uint betAmountYes, uint betCountYes,
            uint betAmountNo, uint betCountNo, bool result)
    {
    	Marketdetails memory question = markets[id];
    	return (question.listPointer,
                question.question, 
                uint(question.betStatus),
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