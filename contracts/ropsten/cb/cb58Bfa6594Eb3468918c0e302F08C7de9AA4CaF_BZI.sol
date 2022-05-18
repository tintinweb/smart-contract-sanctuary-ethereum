/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "./BZIBase.sol";


// Implements rewards & burns
contract BZI is BZIBase  {

	mapping (address => bool) public automatedMarketMakerPairs;//AMM
	event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
	// REWARD CYCLE
	uint256 private _rewardCyclePeriod = 43200; // The duration of the reward cycle (e.g. can claim rewards once 12 hours)
	uint256 private _rewardCycleExtensionThreshold; // If someone sends or receives more than a % of their balance in a transaction, their reward cycle date will increase accordingly
	mapping(address => uint256) private _nextAvailableClaimDate; // The next available reward claim date for each address

	uint256 private _totaltrxLiquidityAddedFromFees; // The total number of trx added to the pool through fees
	uint256 private _totaltrxClaimed; // The total number of trx claimed by all addresses
	uint256 private _totaltrxAsBZIClaimed; // The total number of trx that was converted to BZI and claimed by all addresses
	mapping(address => uint256) private _trxRewardClaimed; // The amount of trx claimed by each address
	mapping(address => uint256) private _trxAsBZIClaimed; // The amount of trx converted to BZI and claimed by each address
	mapping(address => bool) private _addressesExcludedFromRewards; // The list of addresses excluded from rewards
	mapping(address => mapping(address => bool)) private _rewardClaimApprovals; //Used to allow an address to claim rewards on behalf of someone else
	mapping(address => uint256) private _claimRewardAsTokensPercentage; //Allows users to optionally use a % of the reward pool to buy BZI automatically
	uint256 private _minRewardBalance; //The minimum balance required to be eligible for rewards
	uint256 private _maxClaimAllowed = 100 ; // Can only claim up to 100 trx at a time.
	uint256 private _globalRewardDampeningPercentage = 3; // Rewards are reduced by 3% at the start to fill the main trx pool faster and ensure consistency in rewards
	uint256 private _maintrxPoolSize = 5000; // Any excess trx after the main pool will be used as reserves to ensure consistency in rewards
	bool private _rewardAsTokensEnabled; //If enabled, the contract will give out tokens instead of trx according to the preference of each user
	uint256 private _gradualBurnMagnitude; // The contract can optionally burn tokens (By buying them from reward pool).  This is the magnitude of the burn (1 = 0.01%).
	uint256 private _gradualBurnTimespan = 1 days; //Burn every 1 day by default
	uint256 private _lastBurnDate; //The last burn date

	// AUTO-CLAIM
	bool private _autoClaimEnabled;
	uint256 private _maxGasForAutoClaim = 600000; // The maximum gas to consume for processing the auto-claim queue
	address[] _rewardClaimQueue;
	mapping(address => uint) _rewardClaimQueueIndices;
	uint256 private _rewardClaimQueueIndex;
	mapping(address => bool) _addressesInRewardClaimQueue; // Mapping between addresses and false/true depending on whether they are queued up for auto-claim or not
	bool private _reimburseAfterBZIClaimFailure; // If true, and BZI reward claim portion fails, the portion will be given as trx instead
	bool private _processingQueue; //Flag that indicates whether the queue is currently being processed and sending out rewards
	mapping(address => bool) private _whitelistedExternalProcessors; //Contains a list of addresses that are whitelisted for low-gas queue processing 
	uint256 private _sendWeiGasLimit;
	bool private _excludeNonHumansFromRewards = true;

	//anti-bot
	uint256 public antiBlockNum = 3;
	bool public antiEnabled;
	uint256 private antiBotTimestamp;

	event RewardClaimed(address recipient, uint256 amounttrx, uint256 amountTokens, uint256 nextAvailableClaimDate); 
	event Burned(uint256 trxAmount);

 function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        TestToken_v2_init_main();
        super.TestToken_v2_init_base();

    }

    function TestToken_v2_init_main() internal initializer {

		_addressesExcludedFromRewards[BURN_WALLET] = true;
		_addressesExcludedFromRewards[owner()] = true;
		_addressesExcludedFromRewards[address(this)] = true;
		_addressesExcludedFromRewards[address(0)] = true;
    }
	


	// This function is used to enable all functions of the contract, after the setup of the token sale (e.g. Liquidity) is completed
	function onActivated() internal override {
		super.onActivated();

		setRewardAsTokensEnabled(true);
		setAutoClaimEnabled(true);
		setReimburseAfterBZIClaimFailure(true);
		setMinRewardBalance(50000 * 10**decimals());  //At least 50000 tokens are required to be eligible for rewards
		setGradualBurnMagnitude(1); //Buy tokens using 0.01% of reward pool and burn them
		_lastBurnDate = block.timestamp;
		updateAntiBotStatus(true);
	}

	function onBeforeTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onBeforeTransfer(sender, recipient, amount);

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

        // Extend the reward cycle according to the amount transferred.  This is done so that users do not abuse the cycle (buy before it ends & sell after they claim the reward)
		_nextAvailableClaimDate[recipient] += calculateRewardCycleExtension(balanceOf(recipient), amount);
		_nextAvailableClaimDate[sender] += calculateRewardCycleExtension(balanceOf(sender), amount);
		
		bool isSelling = isbaoziSwapPair(recipient);
		if (!isSelling) {
			// Wait for a dip, stellar diamond hands
			return;
		}

		// Process gradual burns
		bool burnTriggered = processGradualBurn();

		// Do not burn & process queue in the same transaction
		if (!burnTriggered && isAutoClaimEnabled()) {
			// Trigger auto-claim
			try this.processRewardClaimQueue(_maxGasForAutoClaim) { } catch { }
		}
    }


	function onTransfer(address sender, address recipient, uint256 amount) internal override {
        super.onTransfer(sender, recipient, amount);

		if (!isMarketTransfer(sender, recipient)) {
			return;
		}

		// Update auto-claim queue after balances have been updated
		updateAutoClaimQueue(sender);
		updateAutoClaimQueue(recipient);
    }
	
	
	function processGradualBurn() private returns(bool) {
		if (!shouldBurn()) {
			return false;
		}

		uint256 burnAmount = address(this).balance * _gradualBurnMagnitude / 10000;
		doBuyAndBurn(burnAmount);
		return true;
	}


	function updateAutoClaimQueue(address user) private {
		bool isQueued = _addressesInRewardClaimQueue[user];

		if (!isIncludedInRewards(user)) {
			if (isQueued) {
				// Need to dequeue
				uint index = _rewardClaimQueueIndices[user];
				address lastUser = _rewardClaimQueue[_rewardClaimQueue.length - 1];

				// Move the last one to this index, and pop it
				_rewardClaimQueueIndices[lastUser] = index;
				_rewardClaimQueue[index] = lastUser;
				_rewardClaimQueue.pop();

				// Clean-up
				delete _rewardClaimQueueIndices[user];
				delete _addressesInRewardClaimQueue[user];
			}
		} else {
			if (!isQueued) {
				// Need to enqueue
				_rewardClaimQueue.push(user);
				_rewardClaimQueueIndices[user] = _rewardClaimQueue.length - 1;
				_addressesInRewardClaimQueue[user] = true;
			}
		}
	}


    function claimReward() isHuman nonReentrant external {
		claimReward(msg.sender);
	}


	function claimReward(address user) public {
		require(msg.sender == user || isClaimApproved(user, msg.sender), "");
		require(isRewardReady(user), "");
		require(isIncludedInRewards(user), "");

		bool success = doClaimReward(user);
		require(success, "");
	}


	function doClaimReward(address user) private returns (bool) {
		// Update the next claim date & the total amount claimed
		_nextAvailableClaimDate[user] = block.timestamp + rewardCyclePeriod();

		(uint256 claimtrx, uint256 claimtrxAsTokens, uint256 taxFee) = calculateClaimRewards(user);
        
        claimtrx = claimtrx - claimtrx * taxFee / 100;
        claimtrxAsTokens = claimtrxAsTokens - claimtrxAsTokens * taxFee / 100;
        
		bool tokenClaimSuccess = true;
        // Claim BZI tokens
		if (!claimBZI(user, claimtrxAsTokens)) {
			// If token claim fails for any reason, award whole portion as trx
			if (_reimburseAfterBZIClaimFailure) {
				claimtrx += claimtrxAsTokens;
			} else {
				tokenClaimSuccess = false;
			}

			claimtrxAsTokens = 0;
		}

		// Claim trx
		bool trxClaimSuccess = claimTRX(user, claimtrx);

		// Fire the event in case something was claimed
		if (tokenClaimSuccess || trxClaimSuccess) {
			emit RewardClaimed(user, claimtrx, claimtrxAsTokens, _nextAvailableClaimDate[user]);
		}
		
		return trxClaimSuccess && tokenClaimSuccess;
	}


	function claimTRX(address user, uint256 trxAmount) private returns (bool) {
		if (trxAmount == 0) {
			return true;
		}

		// Send the reward to the caller
		if (_sendWeiGasLimit > 0) {
			(bool sent,) = user.call{value : trxAmount, gas: _sendWeiGasLimit}("");
			if (!sent) {
				return false;
			}
		} else {
			(bool sent,) = user.call{value : trxAmount}("");
			if (!sent) {
				return false;
			}
		}

	
		_trxRewardClaimed[user] += trxAmount;
		_totaltrxClaimed += trxAmount;
		return true;
	}


	function claimBZI(address user, uint256 trxAmount) private returns (bool) {
		if (trxAmount == 0) {
			return true;
		}

		bool success = swapTRXForTokens(trxAmount, user);
		if (!success) {
			return false;
		}

		_trxAsBZIClaimed[user] += trxAmount;
		_totaltrxAsBZIClaimed += trxAmount;
		return true;
	}


	// Processes users in the claim queue and sends out rewards when applicable. The amount of users processed depends on the gas provided, up to 1 cycle through the whole queue. 
	// Note: Any external processor can process the claim queue (e.g. even if auto claim is disabled from the contract, an external contract/user/service can process the queue for it 
	// and pay the gas cost). "gas" parameter is the maximum amount of gas allowed to be consumed
	function processRewardClaimQueue(uint256 gas) public {
		require(gas > 0, "");

		uint256 queueLength = _rewardClaimQueue.length;

		if (queueLength == 0) {
			return;
		}

		uint256 gasUsed = 0;
		uint256 gasLeft = gasleft();
		uint256 iteration = 0;
		_processingQueue = true;

		// Keep claiming rewards from the list until we either consume all available gas or we finish one cycle
		while (gasUsed < gas && iteration < queueLength) {
			if (_rewardClaimQueueIndex >= queueLength) {
				_rewardClaimQueueIndex = 0;
			}

			address user = _rewardClaimQueue[_rewardClaimQueueIndex];
			if (isRewardReady(user) && isIncludedInRewards(user)) {
				doClaimReward(user);
			}

			uint256 newGasLeft = gasleft();
			
			if (gasLeft > newGasLeft) {
				uint256 consumedGas = gasLeft - newGasLeft;
				gasUsed += consumedGas;
				gasLeft = newGasLeft;
			}

			iteration++;
			_rewardClaimQueueIndex++;
		}

		_processingQueue = false;
	}

	// Allows a whitelisted external contract/user/service to process the queue and have a portion of the gas costs refunded.
	// This can be used to help with transaction fees and payout response time when/if the queue grows too big for the contract.
	// "gas" parameter is the maximum amount of gas allowed to be used.
	function processRewardClaimQueueAndRefundGas(uint256 gas) external {
		require(_whitelistedExternalProcessors[msg.sender], "");

		uint256 startGas = gasleft();
		processRewardClaimQueue(gas);
		uint256 gasUsed = startGas - gasleft();

		payable(msg.sender).transfer(gasUsed);
	}


	function isRewardReady(address user) public view returns(bool) {
		return _nextAvailableClaimDate[user] <= block.timestamp;
	}


	function isIncludedInRewards(address user) public view returns(bool) {
		if (_excludeNonHumansFromRewards) {
			if (isContract(user)) {
				return false;
			}
		}

		return balanceOf(user) >= _minRewardBalance && !_addressesExcludedFromRewards[user];
	}


	// This function calculates how much (and if) the reward cycle of an address should increase based on its current balance and the amount transferred in a transaction
	function calculateRewardCycleExtension(uint256 balance, uint256 amount) public view returns (uint256) {
		uint256 basePeriod = rewardCyclePeriod();

		if (balance == 0) {
			// Receiving $BZI on a zero balance address:
			// This means that either the address has never received tokens before (So its current reward date is 0) in which case we need to set its initial value
			// Or the address has transferred all of its tokens in the past and has now received some again, in which case we will set the reward date to a date very far in the future
			return block.timestamp + basePeriod;
		}

		uint256 rate = amount * 100 / balance;

		// Depending on the % of $BZI tokens transferred, relative to the balance, we might need to extend the period
		if (rate >= _rewardCycleExtensionThreshold) {

			// If new balance is X percent higher, then we will extend the reward date by X percent
			uint256 extension = basePeriod * rate / 100;

			// Cap to the base period
			if (extension >= basePeriod) {
				extension = basePeriod;
			}

			return extension;
		}

		return 0;
	}


	function calculateClaimRewards(address ofAddress) public view returns (uint256, uint256, uint256) {
		uint256 reward = calculatetrxReward(ofAddress);
        uint256 taxFee = 0;
        if (reward >= 35 * 10**16) {
            taxFee = 20;
        } else if(reward >= 20 * 10**16) {
            taxFee = 10;
        }
		uint256 claimtrxAsTokens = 0;
		if (_rewardAsTokensEnabled) {
			uint256 percentage = _claimRewardAsTokensPercentage[ofAddress];
			claimtrxAsTokens = reward * percentage / 100;
		} 

		uint256 claimtrx = reward - claimtrxAsTokens;

		return (claimtrx, claimtrxAsTokens, taxFee);
	}


	function calculatetrxReward(address ofAddress) public view returns (uint256) {
		uint256 holdersAmount = totalAmountOfTokensHeld();

		uint256 balance = balanceOf(ofAddress);
		uint256 trxPool =  address(this).balance * (100 - _globalRewardDampeningPercentage) / 100;

		// Limit to main pool size.  The rest of the pool is used as a reserve to improve consistency
		if (trxPool > _maintrxPoolSize) {
			trxPool = _maintrxPoolSize;
		}

		// If an address is holding X percent of the supply, then it can claim up to X percent of the reward pool
		uint256 reward = trxPool * balance / holdersAmount;

		if (reward > _maxClaimAllowed) {
			reward = _maxClaimAllowed;
		}

		return reward;
	}


	function onBaoziSwapRouterUpdated() internal override { 
		_addressesExcludedFromRewards[baoziSwapRouterAddress()] = true;
		_addressesExcludedFromRewards[baoziSwapPairAddress()] = true;
	}


	function isMarketTransfer(address sender, address recipient) internal override view returns(bool) {
		// Not a market transfer when we are burning or sending out rewards
		return super.isMarketTransfer(sender, recipient) && !isBurnTransfer(sender, recipient) && !_processingQueue;
	}


	function isBurnTransfer(address sender, address recipient) private view returns (bool) {
		return isbaoziSwapPair(sender) && recipient == BURN_WALLET;
	}


	function shouldBurn() public view returns(bool) {
		return _gradualBurnMagnitude > 0 && block.timestamp - _lastBurnDate > _gradualBurnTimespan;
	}


	// Up to 1% manual buyback & burn
	function buyAndBurn(uint256 trxAmount) external onlyOwner {
		require(trxAmount <= address(this).balance / 100, "");
		require(trxAmount > 0, "");

		doBuyAndBurn(trxAmount);
	}


	function doBuyAndBurn(uint256 trxAmount) private {
		if (trxAmount > address(this).balance) {
			trxAmount = address(this).balance;
		}

		if (trxAmount == 0) {
			return;
		}

		if (swapTRXForTokens(trxAmount, BURN_WALLET)) {
			emit Burned(trxAmount);
		}

		_lastBurnDate = block.timestamp;
	}


	function isContract(address account) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
	}


	function totalAmountOfTokensHeld() public view returns (uint256) {
		return totalSupply() - balanceOf(address(0)) - balanceOf(BURN_WALLET) - balanceOf(baoziSwapPairAddress());
	}


    function trxRewardClaimed(address byAddress) public view returns (uint256) {
		return _trxRewardClaimed[byAddress];
	}


    function trxRewardClaimedAsBZI(address byAddress) public view returns (uint256) {
		return _trxAsBZIClaimed[byAddress];
	}


    function totaltrxClaimed() public view returns (uint256) {
		return _totaltrxClaimed;
	}


    function totaltrxClaimedAsBZI() public view returns (uint256) {
		return _totaltrxAsBZIClaimed;
	}


    function rewardCyclePeriod() public view returns (uint256) {
		return _rewardCyclePeriod;
	}


	function setRewardCyclePeriod(uint256 period) public onlyOwner {
		require(period >= 3600 && period <= 86400, "");
		_rewardCyclePeriod = period;
	}


	function setRewardCycleExtensionThreshold(uint256 threshold) public onlyOwner {
		_rewardCycleExtensionThreshold = threshold;
	}


	function nextAvailableClaimDate(address ofAddress) public view returns (uint256) {
		return _nextAvailableClaimDate[ofAddress];
	}


	function maxClaimAllowed() public view returns (uint256) {
		return _maxClaimAllowed;
	}


	function setMaxClaimAllowed(uint256 value) public onlyOwner {
		require(value > 0, "");
		_maxClaimAllowed = value;
	}


	function minRewardBalance() public view returns (uint256) {
		return _minRewardBalance;
	}


	function setMinRewardBalance(uint256 balance) public onlyOwner {
		_minRewardBalance = balance;
	}


	function maxGasForAutoClaim() public view returns (uint256) {
		return _maxGasForAutoClaim;
	}


	function setMaxGasForAutoClaim(uint256 gas) public onlyOwner {
		_maxGasForAutoClaim = gas;
	}


	function isAutoClaimEnabled() public view returns (bool) {
		return _autoClaimEnabled;
	}


	function setAutoClaimEnabled(bool isEnabled) public onlyOwner {
		_autoClaimEnabled = isEnabled;
	}


	function isExcludedFromRewards(address addr) public view returns (bool) {
		return _addressesExcludedFromRewards[addr];
	}


	// Will be used to exclude unicrypt fees/token vesting addresses from rewards
	function setExcludedFromRewards(address addr, bool isExcluded) public onlyOwner {
		_addressesExcludedFromRewards[addr] = isExcluded;
		updateAutoClaimQueue(addr);
	}


	function globalRewardDampeningPercentage() public view returns(uint256) {
		return _globalRewardDampeningPercentage;
	}


	function setGlobalRewardDampeningPercentage(uint256 value) public onlyOwner {
		require(value <= 90, "");
		_globalRewardDampeningPercentage = value;
	}


	function approveClaim(address byAddress, bool isApproved) public {
		require(byAddress != address(0), "");
		_rewardClaimApprovals[msg.sender][byAddress] = isApproved;
	}


	function isClaimApproved(address ofAddress, address byAddress) public view returns(bool) {
		return _rewardClaimApprovals[ofAddress][byAddress];
	}


	function isRewardAsTokensEnabled() public view returns(bool) {
		return _rewardAsTokensEnabled;
	}


	function setRewardAsTokensEnabled(bool isEnabled) public onlyOwner {
		_rewardAsTokensEnabled = isEnabled;
	}


	function gradualBurnMagnitude() public view returns (uint256) {
		return _gradualBurnMagnitude;
	}


	function setGradualBurnMagnitude(uint256 magnitude) public onlyOwner {
		require(magnitude <= 100, "");
		_gradualBurnMagnitude = magnitude;
	}


	function gradualBurnTimespan() public view returns (uint256) {
		return _gradualBurnTimespan;
	}


	function setGradualBurnTimespan(uint256 timespan) public onlyOwner {
		require(timespan >= 5 minutes, "");
		_gradualBurnTimespan = timespan;
	}


	function claimRewardAsTokensPercentage(address ofAddress) public view returns(uint256) {
		return _claimRewardAsTokensPercentage[ofAddress];
	}


	function setClaimRewardAsTokensPercentage(uint256 percentage) public {
		require(percentage <= 100, "");
		_claimRewardAsTokensPercentage[msg.sender] = percentage;
	}


	function maintrxPoolSize() public view returns (uint256) {
		return _maintrxPoolSize;
	}


	function setMaintrxPoolSize(uint256 size) public onlyOwner {
		require(size >= 10 , "");
		_maintrxPoolSize = size;
	}


	function isInRewardClaimQueue(address addr) public view returns(bool) {
		return _addressesInRewardClaimQueue[addr];
	}

	
	function reimburseAfterBZIClaimFailure() public view returns(bool) {
		return _reimburseAfterBZIClaimFailure;
	}


	function setReimburseAfterBZIClaimFailure(bool value) public onlyOwner {
		_reimburseAfterBZIClaimFailure = value;
	}


	function lastBurnDate() public view returns(uint256) {
		return _lastBurnDate;
	}


	function rewardClaimQueueLength() public view returns(uint256) {
		return _rewardClaimQueue.length;
	}


	function rewardClaimQueueIndex() public view returns(uint256) {
		return _rewardClaimQueueIndex;
	}


	function isWhitelistedExternalProcessor(address addr) public view returns(bool) {
		return _whitelistedExternalProcessors[addr];
	}


	function setWhitelistedExternalProcessor(address addr, bool isWhitelisted) public onlyOwner {
		 require(addr != address(0), "");
		_whitelistedExternalProcessors[addr] = isWhitelisted;
	}
	

	function setSendWeiGasLimit(uint256 amount) public onlyOwner {
		_sendWeiGasLimit = amount;
	}
	

	function setExcludeNonHumansFromRewards(bool exclude) public onlyOwner {
		_excludeNonHumansFromRewards = exclude;
	}
	

	function setAntiBotEnabled(bool _isEnabled) public onlyOwner {
		updateAntiBotStatus(_isEnabled);
	}


	function updateAntiBotStatus(bool _flag) private {
		antiEnabled = _flag;
		antiBotTimestamp = block.timestamp + antiBlockNum;
	}


	function updateBlockNum(uint256 _blockNum) public onlyOwner {
		antiBlockNum = _blockNum;
	}

	
	function onBeforeCalculateFeeRate() internal override view returns (bool) {
		if (antiEnabled && block.timestamp < antiBotTimestamp) {
			return true;
		}
	    return super.onBeforeCalculateFeeRate();
	}

	function _setAutomatedMarketMakerPair(address pair, bool value) private onlyOwner {
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            _addressesExcludedFromFees[pair]=true;
            _addressesExcludedFromHold[pair]=true;
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }
}