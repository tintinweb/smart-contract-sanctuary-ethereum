/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin Coin_tFLX
 * Coin Address : 0x16020e7af845572c9F1E11DB7ac0387b18f8E818
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
*/

interface ERC20{
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	uint256 public principalTaxBank = uint256(0);
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; uint256 amtWithdrawn; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
	uint256 public totalWithdrawals = uint256(0);
	event Staked (address indexed account);
	event Unstaked (address indexed account);

	constructor() {
		owner = msg.sender;
	}

	//This function allows the owner to specify an address that will take over ownership rights instead. Please double check the address provided as once the function is executed, only the new owner will be able to change the address back.
	function changeOwner(address _newOwner) public onlyOwner {
		owner = _newOwner;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

/**
 * Function stake
 * Minimum Stake Period : 30 days
 * Address Map : addressMap
 * ERC20 Transfer : 0x16020e7af845572c9F1E11DB7ac0387b18f8E818, _stakeAmt
 * The function takes in 1 variable, zero or a positive integer _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _stakeAmt is strictly greater than 0
 * checks that (thisRecord with element stakeAmt) is equals to 0
 * updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function
 * updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)
 * updates addressMap (Element the address that called this function) as Struct comprising current time, (((_stakeAmt) * ((1000000) - (100000))) / (1000000)), current time, 0, 0
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * updates principalTaxBank as (principalTaxBank) + ((thisRecord with element stakeAmt) / (10))
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		require((thisRecord.stakeAmt == uint256(0)), "Need to unstake staked amount before staking");
		addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
		numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		addressMap[msg.sender]  = record (block.timestamp, ((_stakeAmt * (uint256(1000000) - uint256(100000))) / uint256(1000000)), block.timestamp, uint256(0), uint256(0));
		ERC20(0x16020e7af845572c9F1E11DB7ac0387b18f8E818).transferFrom(msg.sender, address(this), _stakeAmt);
		principalTaxBank  = (principalTaxBank + (thisRecord.stakeAmt / uint256(10)));
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, zero or a positive integer _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * checks that ((current time) - ((3000) * (864))) is greater than or equals to (thisRecord with element stakeTime)
 * checks that ((current time) - ((500) * (864))) is greater than or equals to (thisRecord with element lastUpdateTime)
 * creates an internal variable interestToRemove with initial value ((thisRecord with element accumulatedInterestToUpdateTime) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as (((_unstakeAmt) * ((1000000) - (100000))) / (1000000)) + (interestToRemove)
 * updates totalWithdrawals as (totalWithdrawals) + (interestToRemove)
 * updates principalTaxBank as (principalTaxBank) + ((thisRecord with element stakeAmt) / (10))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((thisRecord with element accumulatedInterestToUpdateTime) - (interestToRemove)), ((thisRecord with element amtWithdrawn) + (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - (uint256(3000) * uint256(864))) >= thisRecord.stakeTime), "Insufficient stake period");
		require(((block.timestamp - (uint256(500) * uint256(864))) >= thisRecord.lastUpdateTime), "Insufficient cool down period");
		uint256 interestToRemove = ((thisRecord.accumulatedInterestToUpdateTime * _unstakeAmt) / thisRecord.stakeAmt);
		ERC20(0x16020e7af845572c9F1E11DB7ac0387b18f8E818).transfer(msg.sender, (((_unstakeAmt * (uint256(1000000) - uint256(100000))) / uint256(1000000)) + interestToRemove));
		totalWithdrawals  = (totalWithdrawals + interestToRemove);
		principalTaxBank  = (principalTaxBank + (thisRecord.stakeAmt / uint256(10)));
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (thisRecord.accumulatedInterestToUpdateTime - interestToRemove), (thisRecord.amtWithdrawn + interestToRemove));
		emit Unstaked(msg.sender);
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
				if ((addressStore[i0] == msg.sender)){
					addressStore[i0]  = addressStore[(numberOfAddressesCurrentlyStaked - uint256(1))];
					numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked - uint256(1));
					break;
				}
			}
		}
	}

/**
 * Function deposit
 * ERC20 Transfer : 0x16020e7af845572c9F1E11DB7ac0387b18f8E818, _depositAmt
 * The function takes in 1 variable, zero or a positive integer _depositAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _depositAmt
 * creates an internal variable accumulatedParts with initial value 0
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable aSender with initial value addressStore with element Loop Variable i0; then creates an internal variable thisRecord with initial value addressMap with element aSender; then creates an internal variable stakedPeriod with initial value (current time) - (thisRecord with element stakeTime); then if stakedPeriod is strictly greater than ((100) * (864)) then (updates stakedPeriod as (100) * (864)); and then updates accumulatedParts as (accumulatedParts) + ((stakedPeriod) * (thisRecord with element stakeAmt)))
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable aSender with initial value addressStore with element Loop Variable i0; then creates an internal variable thisRecord with initial value addressMap with element aSender; then creates an internal variable stakedPeriod with initial value (current time) - (thisRecord with element stakeTime); then if stakedPeriod is strictly greater than ((100) * (864)) then (updates stakedPeriod as (100) * (864)); and then updates addressMap (Element aSender) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((thisRecord with element accumulatedInterestToUpdateTime) + (((stakedPeriod) * (thisRecord with element stakeAmt) * (_depositAmt)) / (accumulatedParts))), (thisRecord with element amtWithdrawn))
*/
	function deposit(uint256 _depositAmt) public {
		ERC20(0x16020e7af845572c9F1E11DB7ac0387b18f8E818).transferFrom(msg.sender, address(this), _depositAmt);
		uint256 accumulatedParts = uint256(0);
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			address aSender = addressStore[i0];
			record memory thisRecord = addressMap[aSender];
			uint256 stakedPeriod = (block.timestamp - thisRecord.stakeTime);
			if ((stakedPeriod > (uint256(100) * uint256(864)))){
				stakedPeriod  = (uint256(100) * uint256(864));
			}
			accumulatedParts  = (accumulatedParts + (stakedPeriod * thisRecord.stakeAmt));
		}
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			address aSender = addressStore[i0];
			record memory thisRecord = addressMap[aSender];
			uint256 stakedPeriod = (block.timestamp - thisRecord.stakeTime);
			if ((stakedPeriod > (uint256(100) * uint256(864)))){
				stakedPeriod  = (uint256(100) * uint256(864));
			}
			addressMap[aSender]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (thisRecord.accumulatedInterestToUpdateTime + ((stakedPeriod * thisRecord.stakeAmt * _depositAmt) / accumulatedParts)), thisRecord.amtWithdrawn);
		}
	}

/**
 * Function withdrawInterestWithoutUnstaking
 * The function takes in 1 variable, zero or a positive integer _withdrawalAmt. It can only be called by functions outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * creates an internal variable totalInterestEarnedTillNow with initial value thisRecord with element accumulatedInterestToUpdateTime
 * checks that _withdrawalAmt is less than or equals to totalInterestEarnedTillNow
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((totalInterestEarnedTillNow) - (_withdrawalAmt)), ((thisRecord with element amtWithdrawn) + (_withdrawalAmt))
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _withdrawalAmt
 * updates totalWithdrawals as (totalWithdrawals) + (_withdrawalAmt)
*/
	function withdrawInterestWithoutUnstaking(uint256 _withdrawalAmt) external {
		record memory thisRecord = addressMap[msg.sender];
		uint256 totalInterestEarnedTillNow = thisRecord.accumulatedInterestToUpdateTime;
		require((_withdrawalAmt <= totalInterestEarnedTillNow), "Withdrawn amount must be less than withdrawable amount");
		addressMap[msg.sender]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (totalInterestEarnedTillNow - _withdrawalAmt), (thisRecord.amtWithdrawn + _withdrawalAmt));
		ERC20(0x16020e7af845572c9F1E11DB7ac0387b18f8E818).transfer(msg.sender, _withdrawalAmt);
		totalWithdrawals  = (totalWithdrawals + _withdrawalAmt);
	}

/**
 * Function withdrawPrincipalTax
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as principalTaxBank
 * updates principalTaxBank as 0
*/
	function withdrawPrincipalTax() public onlyOwner {
		ERC20(0x16020e7af845572c9F1E11DB7ac0387b18f8E818).transfer(msg.sender, principalTaxBank);
		principalTaxBank  = uint256(0);
	}

/**
 * Function withdrawToken
 * The function takes in 1 variable, zero or a positive integer _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _amt
*/
	function withdrawToken(uint256 _amt) public onlyOwner {
		ERC20(0x16020e7af845572c9F1E11DB7ac0387b18f8E818).transfer(msg.sender, _amt);
	}
}