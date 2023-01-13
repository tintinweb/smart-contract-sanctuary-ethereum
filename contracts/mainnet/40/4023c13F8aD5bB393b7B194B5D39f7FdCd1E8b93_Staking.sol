/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * Contract Type : Staking
 * Staking of : Coin LPIS
 * Coin Address : 0x78B16594aB2A431bBbCB2784CaF3157981112d2B
 * Number of schemes : 1
 * Scheme 1 functions : stake, unstake
 * Referral Scheme : .01
*/

interface ERC20{
	function balanceOf(address account) external view returns (uint256);
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking {

	address owner;
	uint256 public interestTaxBank = uint256(0);
	uint256 public principalTaxBank = uint256(0);
	struct record { uint256 stakeTime; uint256 stakeAmt; uint256 lastUpdateTime; uint256 accumulatedInterestToUpdateTime; uint256 amtWithdrawn; }
	mapping(address => record) public addressMap;
	mapping(uint256 => address) public addressStore;
	uint256 public numberOfAddressesCurrentlyStaked = uint256(0);
	uint256 public principalCommencementTax = uint256(100);
	uint256 public interestTax = uint256(100);
	uint256 public minStakePeriod = (uint256(9000) * uint256(864));
	uint256 public totalWithdrawals = uint256(0);
	struct referralRecord { bool hasDeposited; address referringAddress; uint256 unclaimedRewards; }
	mapping(address => referralRecord) public referralRecordMap;
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
 * This function allows the owner to change the value of principalCommencementTax.
 * Notes for _principalCommencementTax : 10000 is one percent
*/
	function changeValueOf_principalCommencementTax (uint256 _principalCommencementTax) external onlyOwner {
		 principalCommencementTax = _principalCommencementTax;
	}

	

/**
 * This function allows the owner to change the value of interestTax.
 * Notes for _interestTax : 10000 is one percent
*/
	function changeValueOf_interestTax (uint256 _interestTax) external onlyOwner {
		 interestTax = _interestTax;
	}

	

/**
 * This function allows the owner to change the value of minStakePeriod.
 * Notes for _minStakePeriod : 1 day is represented by 86400 (seconds)
*/
	function changeValueOf_minStakePeriod (uint256 _minStakePeriod) external onlyOwner {
		 minStakePeriod = _minStakePeriod;
	}

/**
 * Function withdrawReferral
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that (referralRecordMap with element the address that called this function with element unclaimedRewards) is greater than or equals to _amt
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to _amt
 * transfers _amt of the native currency to the address that called this function
 * updates referralRecordMap (Element the address that called this function) (Entity unclaimedRewards) as (referralRecordMap with element the address that called this function with element unclaimedRewards) - (_amt)
*/
	function withdrawReferral(uint256 _amt) public {
		require((referralRecordMap[msg.sender].unclaimedRewards >= _amt), "Insufficient referral rewards to withdraw");
		require((address(this).balance >= _amt), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(_amt);
		referralRecordMap[msg.sender].unclaimedRewards  = (referralRecordMap[msg.sender].unclaimedRewards - _amt);
	}

/**
 * Function addReferral
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can only be called by other functions in this contract. It does the following :
 * creates an internal variable referringAddress with initial value referralRecordMap with element the address that called this function with element referringAddress
 * if not referralRecordMap with element the address that called this function with element hasDeposited then (updates referralRecordMap (Element the address that called this function) (Entity hasDeposited) as true)
 * if referringAddress is equals to Address 0 then ()
 * updates referralRecordMap (Element referringAddress) (Entity unclaimedRewards) as (referralRecordMap with element referringAddress with element unclaimedRewards) + ((_amt) / (100))
 * updates referringAddress as referralRecordMap with element referringAddress with element referringAddress
*/
	function addReferral(uint256 _amt) internal {
		address referringAddress = referralRecordMap[msg.sender].referringAddress;
		if (!(referralRecordMap[msg.sender].hasDeposited)){
			referralRecordMap[msg.sender].hasDeposited  = true;
		}
		if ((referringAddress == address(0))){
			return;
		}
		referralRecordMap[referringAddress].unclaimedRewards  = (referralRecordMap[referringAddress].unclaimedRewards + (_amt / uint256(100)));
		referringAddress  = referralRecordMap[referringAddress].referringAddress;
	}

/**
 * Function addReferralAddress
 * The function takes in 1 variable, (an address) _referringAddress. It can only be called by functions outside of this contract. It does the following :
 * checks that referralRecordMap with element _referringAddress with element hasDeposited
 * checks that not _referringAddress is equals to (the address that called this function)
 * checks that (referralRecordMap with element the address that called this function with element referringAddress) is equals to Address 0
 * updates referralRecordMap (Element the address that called this function) (Entity referringAddress) as _referringAddress
*/
	function addReferralAddress(address _referringAddress) external {
		require(referralRecordMap[_referringAddress].hasDeposited, "Referring Address has not made a deposit");
		require(!((_referringAddress == msg.sender)), "Self-referrals are not allowed");
		require((referralRecordMap[msg.sender].referringAddress == address(0)), "User has previously indicated a referral address");
		referralRecordMap[msg.sender].referringAddress  = _referringAddress;
	}

/**
 * Function stake
 * Daily Interest Rate : 0.01
 * This interest rate is modified under certain circumstances, as articulated in the consolidatedInterestRate function
 * Minimum Stake Period : Variable minStakePeriod
 * Address Map : addressMap
 * ERC20 Transfer : 0x78B16594aB2A431bBbCB2784CaF3157981112d2B, _stakeAmt
 * The function takes in 1 variable, (zero or a positive integer) _stakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that _stakeAmt is strictly greater than 0
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that (thisRecord with element stakeAmt) is equals to 0
 * updates addressMap (Element the address that called this function) as Struct comprising current time, (((_stakeAmt) * ((1000000) - (principalCommencementTax))) / (1000000)), current time, 0, 0
 * updates addressStore (Element numberOfAddressesCurrentlyStaked) as the address that called this function
 * updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) + (1)
 * calls ERC20's transferFrom function  with variable sender as the address that called this function, variable recipient as the address of this contract, variable amount as _stakeAmt
 * calls addReferral with variable _amt as _stakeAmt
 * updates principalTaxBank as (principalTaxBank) + (((_stakeAmt) * (principalCommencementTax)) / (1000000))
 * emits event Staked with inputs the address that called this function
*/
	function stake(uint256 _stakeAmt) public {
		require((_stakeAmt > uint256(0)), "Staked amount needs to be greater than 0");
		record memory thisRecord = addressMap[msg.sender];
		require((thisRecord.stakeAmt == uint256(0)), "Need to unstake before restaking");
		addressMap[msg.sender]  = record (block.timestamp, ((_stakeAmt * (uint256(1000000) - principalCommencementTax)) / uint256(1000000)), block.timestamp, uint256(0), uint256(0));
		addressStore[numberOfAddressesCurrentlyStaked]  = msg.sender;
		numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked + uint256(1));
		ERC20(0x78B16594aB2A431bBbCB2784CaF3157981112d2B).transferFrom(msg.sender, address(this), _stakeAmt);
		addReferral(_stakeAmt);
		principalTaxBank  = (principalTaxBank + ((_stakeAmt * principalCommencementTax) / uint256(1000000)));
		emit Staked(msg.sender);
	}

/**
 * Function unstake
 * The function takes in 1 variable, (zero or a positive integer) _unstakeAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * checks that _unstakeAmt is less than or equals to (thisRecord with element stakeAmt)
 * checks that ((current time) - (minStakePeriod)) is greater than or equals to (thisRecord with element stakeTime)
 * creates an internal variable newAccum with initial value (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000))
 * creates an internal variable interestToRemove with initial value ((newAccum) * (_unstakeAmt)) / (thisRecord with element stakeAmt)
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to (((interestToRemove) * ((1000000) - (interestTax))) / (1000000))
 * transfers ((interestToRemove) * ((1000000) - (interestTax))) / (1000000) of the native currency to the address that called this function
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to _unstakeAmt
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as _unstakeAmt
 * updates totalWithdrawals as (totalWithdrawals) + (((interestToRemove) * ((1000000) - (interestTax))) / (1000000))
 * updates interestTaxBank as (interestTaxBank) + (((interestToRemove) * (interestTax)) / (1000000))
 * if _unstakeAmt is equals to (thisRecord with element stakeAmt) then (repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (if (addressStore with element Loop Variable i0) is equals to (the address that called this function) then (updates addressStore (Element Loop Variable i0) as addressStore with element (numberOfAddressesCurrentlyStaked) - (1); then updates numberOfAddressesCurrentlyStaked as (numberOfAddressesCurrentlyStaked) - (1); and then terminates the for-next loop)))
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), ((thisRecord with element stakeAmt) - (_unstakeAmt)), (thisRecord with element lastUpdateTime), ((newAccum) - (interestToRemove)), ((thisRecord with element amtWithdrawn) + (interestToRemove))
 * emits event Unstaked with inputs the address that called this function
*/
	function unstake(uint256 _unstakeAmt) public {
		record memory thisRecord = addressMap[msg.sender];
		require((_unstakeAmt <= thisRecord.stakeAmt), "Withdrawing more than staked amount");
		require(((block.timestamp - minStakePeriod) >= thisRecord.stakeTime), "Insufficient stake period");
		uint256 newAccum = (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
		uint256 interestToRemove = ((newAccum * _unstakeAmt) / thisRecord.stakeAmt);
		require((address(this).balance >= ((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000))), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000)));
		require((ERC20(0x78B16594aB2A431bBbCB2784CaF3157981112d2B).balanceOf(address(this)) >= _unstakeAmt), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x78B16594aB2A431bBbCB2784CaF3157981112d2B).transfer(msg.sender, _unstakeAmt);
		totalWithdrawals  = (totalWithdrawals + ((interestToRemove * (uint256(1000000) - interestTax)) / uint256(1000000)));
		interestTaxBank  = (interestTaxBank + ((interestToRemove * interestTax) / uint256(1000000)));
		if ((_unstakeAmt == thisRecord.stakeAmt)){
			for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
				if ((addressStore[i0] == msg.sender)){
					addressStore[i0]  = addressStore[(numberOfAddressesCurrentlyStaked - uint256(1))];
					numberOfAddressesCurrentlyStaked  = (numberOfAddressesCurrentlyStaked - uint256(1));
					break;
				}
			}
		}
		addressMap[msg.sender]  = record (thisRecord.stakeTime, (thisRecord.stakeAmt - _unstakeAmt), thisRecord.lastUpdateTime, (newAccum - interestToRemove), (thisRecord.amtWithdrawn + interestToRemove));
		emit Unstaked(msg.sender);
	}

/**
 * Function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn
 * The function takes in 1 variable, (an address) _address. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable thisRecord with initial value addressMap with element _address
 * returns (thisRecord with element accumulatedInterestToUpdateTime) + (((thisRecord with element stakeAmt) * ((current time) - (thisRecord with element lastUpdateTime)) * (consolidatedInterestRate with variable _stakedAmt as thisRecord with element stakeAmt)) / (86400000000)) as output
*/
	function interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(address _address) public view returns (uint256) {
		record memory thisRecord = addressMap[_address];
		return (thisRecord.accumulatedInterestToUpdateTime + ((thisRecord.stakeAmt * (block.timestamp - thisRecord.lastUpdateTime) * consolidatedInterestRate(thisRecord.stakeAmt)) / uint256(86400000000)));
	}

/**
 * Function withdrawInterestWithoutUnstaking
 * The function takes in 1 variable, (zero or a positive integer) _withdrawalAmt. It can only be called by functions outside of this contract. It does the following :
 * creates an internal variable totalInterestEarnedTillNow with initial value interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _address as the address that called this function
 * checks that _withdrawalAmt is less than or equals to totalInterestEarnedTillNow
 * creates an internal variable thisRecord with initial value addressMap with element the address that called this function
 * updates addressMap (Element the address that called this function) as Struct comprising (thisRecord with element stakeTime), (thisRecord with element stakeAmt), current time, ((totalInterestEarnedTillNow) - (_withdrawalAmt)), ((thisRecord with element amtWithdrawn) + (_withdrawalAmt))
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to (((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000))
 * transfers ((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000) of the native currency to the address that called this function
 * updates interestTaxBank as (interestTaxBank) + (((_withdrawalAmt) * (interestTax)) / (1000000))
 * updates totalWithdrawals as (totalWithdrawals) + (((_withdrawalAmt) * ((1000000) - (interestTax))) / (1000000))
*/
	function withdrawInterestWithoutUnstaking(uint256 _withdrawalAmt) external {
		uint256 totalInterestEarnedTillNow = interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(msg.sender);
		require((_withdrawalAmt <= totalInterestEarnedTillNow), "Withdrawn amount must be less than withdrawable amount");
		record memory thisRecord = addressMap[msg.sender];
		addressMap[msg.sender]  = record (thisRecord.stakeTime, thisRecord.stakeAmt, block.timestamp, (totalInterestEarnedTillNow - _withdrawalAmt), (thisRecord.amtWithdrawn + _withdrawalAmt));
		require((address(this).balance >= ((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000))), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000)));
		interestTaxBank  = (interestTaxBank + ((_withdrawalAmt * interestTax) / uint256(1000000)));
		totalWithdrawals  = (totalWithdrawals + ((_withdrawalAmt * (uint256(1000000) - interestTax)) / uint256(1000000)));
	}

/**
 * Function totalStakedAmount
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable total with initial value 0
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (creates an internal variable thisRecord with initial value addressMap with element addressStore with element Loop Variable i0; and then updates total as (total) + (thisRecord with element stakeAmt))
 * returns total as output
*/
	function totalStakedAmount() public view returns (uint256) {
		uint256 total = uint256(0);
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			record memory thisRecord = addressMap[addressStore[i0]];
			total  = (total + thisRecord.stakeAmt);
		}
		return total;
	}

/**
 * Function totalAccumulatedInterest
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * creates an internal variable total with initial value 0
 * repeat numberOfAddressesCurrentlyStaked times with loop variable i0 :  (updates total as (total) + (interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn with variable _address as addressStore with element Loop Variable i0))
 * returns total as output
*/
	function totalAccumulatedInterest() public view returns (uint256) {
		uint256 total = uint256(0);
		for (uint i0 = 0; i0 < numberOfAddressesCurrentlyStaked; i0++){
			total  = (total + interestEarnedUpToNowBeforeTaxesAndNotYetWithdrawn(addressStore[i0]));
		}
		return total;
	}

/**
 * Function consolidatedInterestRate
 * The function takes in 1 variable, (zero or a positive integer) _stakedAmt. It can be called by functions both inside and outside of this contract. It does the following :
 * if _stakedAmt is greater than or equals to 5000000000000000000000 then (returns 2000 as output)
 * if _stakedAmt is greater than or equals to 4000000000000000000000 then (returns 170 as output)
 * if _stakedAmt is greater than or equals to 3000000000000000000000 then (returns 160 as output)
 * if _stakedAmt is greater than or equals to 2000000000000000000000 then (returns 150 as output)
 * if _stakedAmt is greater than or equals to 1000000000000000000000 then (returns 120 as output)
 * if _stakedAmt is less than or equals to 499000000000000000000 then (returns 100 as output)
 * returns 100 as output
*/
	function consolidatedInterestRate(uint256 _stakedAmt) public pure returns (uint256) {
		if ((_stakedAmt >= uint256(5000000000000000000000))){
			return uint256(2000);
		}
		if ((_stakedAmt >= uint256(4000000000000000000000))){
			return uint256(170);
		}
		if ((_stakedAmt >= uint256(3000000000000000000000))){
			return uint256(160);
		}
		if ((_stakedAmt >= uint256(2000000000000000000000))){
			return uint256(150);
		}
		if ((_stakedAmt >= uint256(1000000000000000000000))){
			return uint256(120);
		}
		if ((_stakedAmt <= uint256(499000000000000000000))){
			return uint256(100);
		}
		return uint256(100);
	}

/**
 * Function withdrawPrincipalTax
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (ERC20's balanceOf function  with variable recipient as the address of this contract) is greater than or equals to principalTaxBank
 * calls ERC20's transfer function  with variable recipient as the address that called this function, variable amount as principalTaxBank
 * updates principalTaxBank as 0
*/
	function withdrawPrincipalTax() public onlyOwner {
		require((ERC20(0x78B16594aB2A431bBbCB2784CaF3157981112d2B).balanceOf(address(this)) >= principalTaxBank), "Insufficient amount of the token in this contract to transfer out. Please contact the contract owner to top up the token.");
		ERC20(0x78B16594aB2A431bBbCB2784CaF3157981112d2B).transfer(msg.sender, principalTaxBank);
		principalTaxBank  = uint256(0);
	}

/**
 * Function withdrawInterestTax
 * The function takes in 0 variables. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to interestTaxBank
 * transfers interestTaxBank of the native currency to the address that called this function
 * updates interestTaxBank as 0
*/
	function withdrawInterestTax() public onlyOwner {
		require((address(this).balance >= interestTaxBank), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(interestTaxBank);
		interestTaxBank  = uint256(0);
	}

/**
 * Function withdrawNativeCurrency
 * The function takes in 1 variable, (zero or a positive integer) _amt. It can be called by functions both inside and outside of this contract. It does the following :
 * checks that the function is called by the owner of the contract
 * checks that (amount of native currency owned by the address of this contract) is greater than or equals to _amt
 * transfers _amt of the native currency to the address that called this function
*/
	function withdrawNativeCurrency(uint256 _amt) public onlyOwner {
		require((address(this).balance >= _amt), "Insufficient amount of native currency in this contract to transfer out. Please contact the contract owner to top up the native currency.");
		payable(msg.sender).transfer(_amt);
	}

	function sendMeNativeCurrency() external payable {
	}
}