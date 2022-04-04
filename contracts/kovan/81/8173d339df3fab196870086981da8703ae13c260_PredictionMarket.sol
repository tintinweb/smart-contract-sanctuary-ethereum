/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// File: AdminManaged.sol

pragma solidity ^0.4.2;

contract AdminManaged {

	mapping (address => bool) public administratorsMap;
	mapping (address => bool) public trustedSources;
	address public owner;

	event LogAdminAdded(address sender, address admin);
	event LogAdminRemoved(address sender, address admin);
	event LogTrustedSourceAdded(address sender, address trustedSource);
	event LogTrustedSourceRemoved(address sender, address trustedSource);

	function AdminManaged(){
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
		LogTrustedSourceAdded(msg.sender, trustedSource);
		return true;
	}

	function removeTrustedSource(address trustedSource)
		public
		onlyAdmin
		returns(bool success)
	{
		require(trustedSource != owner);
		trustedSources[trustedSource] = false;
		LogTrustedSourceRemoved(msg.sender, trustedSource);
		return true;
	}

	function isTrustedSource(address trustedSource)
		public
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
		LogAdminAdded(msg.sender, admin);
		return true;
	}

	function removeAdmin(address admin)
		public
		onlyOwner
		returns(bool adminDeleted)
	{
		administratorsMap[admin] = false;
		LogAdminRemoved(msg.sender, admin);
		return true;
	}

	function isAdmin(address admin)
		public
		returns(bool isIndeed)
	{
		return administratorsMap[admin];
	}

}
// File: PredictionMarket.sol

pragma solidity ^0.4.2;


contract PredictionMarket is AdminManaged {

    QuestionStruct[] public questionStructs;
    enum BetStatus { Pending, Canceled, Resolved }
    mapping (address => uint) public balance;

    struct QuestionStruct {
    	string question;
    	uint betAmount;
    	uint betCount;
    	uint betAmountYesTot;
    	uint betCountYes;
    	uint betAmountNoTot;
    	uint betCountNo;
    	bool answer;
    	BetStatus betStatus;
        mapping(address => uint) betAmountYes;
        mapping(address => uint) betAmountNo;
    	uint listPointer;
    }

    event LogQuestionAdded(uint id, string name);
    event LogQuestionAnswered(uint id, string answer);
    event LogPayoutSent(uint id, address sender, uint amount);
    event LogQuestionBetted(uint id, address sender, uint amountBetted, bool answer);
    event LogQuestionResolved(uint id, bool anwser);

    // Admins / owner functions

    function addQuestion(string _question)
        onlyAdmin
    	public
    	returns (uint _questionId)
    {
        QuestionStruct memory question;
        question.question = _question;
        question.betStatus = BetStatus.Pending;

        uint questionId = questionStructs.push(question) - 1;
        questionStructs[questionId].listPointer = questionId;
        LogQuestionAdded(questionId, _question);
        return questionId;
    }

    function setQuestionAnswer(uint id, bool _answer)
        public
        onlyTrustedSource
        returns(bool success)
    {
        require(isQuestion(id));

        questionStructs[id].answer = _answer;
        questionStructs[id].betStatus = BetStatus.Resolved;

        LogQuestionResolved(id, _answer);
        return true;
    }

    // Public functions

    function betQuestionId(uint id, bool _vote)
    	payable
    	public
    	returns (bool success)
    {
        require(msg.value>0);
        require(isQuestion(id));
        require(questionStructs[id].betStatus == BetStatus.Pending);
        // Can't vote twice on the same question
        require(questionStructs[id].betAmountYes[msg.sender]==0 && questionStructs[id].betAmountNo[msg.sender]==0);
       
        questionStructs[id].betAmount += msg.value;
        questionStructs[id].betCount += 1;
        
        if (_vote) {
            questionStructs[id].betCountYes += 1;
            questionStructs[id].betAmountYesTot += msg.value;
            questionStructs[id].betAmountYes[msg.sender] = msg.value;
        } else {
            questionStructs[id].betCountNo += 1;
            questionStructs[id].betAmountNoTot += msg.value;
            questionStructs[id].betAmountNo[msg.sender] = msg.value;
        }
        
        LogQuestionBetted(id, msg.sender, msg.value, _vote);
        return true;
    }

    function requestPayoutQid(uint id) 
        public
        returns(bool success)
    {
    	require(isQuestion(id));
        require(questionStructs[id].betAmountYes[msg.sender] != 0x0 || questionStructs[id].betAmountNo[msg.sender] != 0x0);

        if(!updateGamblerBalance(msg.sender, id)) revert();
        
        uint amount = balance[msg.sender];
        balance[msg.sender] = 0 ;
        msg.sender.transfer(amount);
        LogPayoutSent(id, msg.sender, amount);
        return true;
    }

    // Private function

    function updateGamblerBalance(address gambler, uint qId)
        private
        returns(bool success)
    {
        require(questionStructs[qId].betStatus == BetStatus.Resolved);
        bool qAnswer = questionStructs[qId].answer;
        uint reward;
        uint ratio;

        if (qAnswer && questionStructs[qId].betAmountYes[gambler] != 0x0) 
        {
            uint valueBetY = questionStructs[qId].betAmountYes[gambler];
            uint ttlValueBetY = questionStructs[qId].betAmountYesTot;
            
            ratio = percent(valueBetY, ttlValueBetY, 3);
            reward = ratio * questionStructs[qId].betAmount;
            reward = reward / 1000;
            
            balance[gambler] += reward;
            
            questionStructs[qId].betAmountYes[gambler] = 0;
            return true;
        } else if (!qAnswer && (questionStructs[qId].betAmountNo[gambler] != 0x0)) 
        {
            uint valueBetN = questionStructs[qId].betAmountNo[gambler];
            uint ttlValueBetN = questionStructs[qId].betAmountNoTot;
           
            ratio = percent(valueBetN, ttlValueBetN, 3);
            reward = ratio * questionStructs[qId].betAmount;
            reward = reward / 1000;
       
            balance[gambler] += reward;
            
            // set vote AmountBetted to 0, so he cannot withdraw again
            questionStructs[qId].betAmountNo[gambler] = 0;
            return true;
        }
        
    	 return false;   
    }

    // Getter & utils

    function getQuestion(uint id)
    	constant
    	public
    	returns (uint qId, string name, uint betStatus, uint betAmount, uint betCount, uint betAmountYes, uint betCountYes,
            uint betAmountNo, uint betCountNo, bool answer)
    {
    	QuestionStruct question = questionStructs[id];
    	return (question.listPointer,
                question.question, 
                uint(question.betStatus),
                question.betAmount,
                question.betCount,
                question.betAmountYesTot,
                question.betCountYes,
                question.betAmountNoTot,
                question.betCountNo,
                question.answer);
    }

    function getQuestionsCount()
        public
        constant
        returns(uint count)
    {
        return questionStructs.length;
    }

    function isQuestion(uint id) 
        public 
        constant 
        returns(bool isIndeed)
    {
        if(questionStructs.length == 0) return false;
        return (questionStructs[id].listPointer == id);
    }

    function percent(uint numerator, uint denominator, uint precision)
        public 
        constant 
        returns(uint quotient) 
    {
         // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }

}