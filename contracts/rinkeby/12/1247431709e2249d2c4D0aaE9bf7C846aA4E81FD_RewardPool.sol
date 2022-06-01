// SPDX-License-Identifier: MIT

// Rewards Pool is a community based experiment project.

pragma solidity 0.8.13;

import "./RewardDistributor.sol";
import "./interfaces/IRewardPool.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IRewardDistributor.sol";
import "./library/IterableMapping.sol";
import "./library/SafeMathInt.sol";
import "./library/SafeMathUint.sol";
import "./RewardDistributor.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardPool is Initializable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using SafeMath for uint256;   
    using SafeMathInt for int256; 
    using SafeMathUint for uint256;
    using IterableMapping for IterableMapping.Map;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    address public nativeAsset;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD; 
    uint256 internal constant magnitude = 2**128;
    uint256 internal constant distributeSharePrecision = 100;
    uint256 public buyBackWait;
    uint256 public lastBuyBackTimestamp;
    uint256 public minimumCoinBalanceForBuyback;
    uint256 public maximumCoinBalanceForBuyback;
    uint256 public gasForProcessing;
    uint8 public totalRewardDistributor;

    bool private swapping;

    struct rewardStore {
        address rewardDistributor;
        uint256 distributeShare;
        uint256 claimWait;
        uint256 lastProcessedIndex;
        uint256 minimumTokenBalanceForRewards;
        uint256 magnifiedRewardPerShare;
        uint256 totalRewardsDistributed;
        uint256 totalSupply;
        bool isActive;
    }

    struct distributeStore {
        uint256 lastClaimTimes;
        int256 magnifiedRewardCorrections;
        uint256 withdrawnRewards;
        uint256 balanceOf;
    }

    mapping (address => rewardStore) private _rewardInfo;
    mapping (uint8 => address) private _rewardAsset; 
    mapping (bytes32 => distributeStore) private _distributeInfo; 
    mapping (address => bool) private excludedFromRewards;
    mapping (address => IterableMapping.Map) private tokenHoldersMap;

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SendRewards(uint256 tokensSwapped,uint256 amount);
    event Claim(address indexed account, uint256 amount, bool indexed automatic); 
    event RewardsDistributed(address indexed from,uint256 weiAmount);
    event RewardWithdrawn(address indexed to,uint256 weiAmount,bool status);
    event ProcessedDistributorTracker(uint256 iterations,uint256 claims,uint256 lastProcessedIndex,bool indexed automatic,uint256 gas,address indexed processor);

    receive() external payable {}

    modifier onlyOperator() {
        require((msg.sender == owner()) || 
                (msg.sender == nativeAsset), "unable to access");
        _;
    }

    function initialize(address _nativeAsset) initializer public {
        __Pausable_init();
        __Ownable_init();

        nativeAsset = _nativeAsset;
        buyBackWait = 86400;
        minimumCoinBalanceForBuyback = 10;
        maximumCoinBalanceForBuyback = 80;
        gasForProcessing = 300000;

        // uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Testnet
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(uniswapV2Router.WETH(),_nativeAsset);

        _excludedFromRewards(address(this),true);
        _excludedFromRewards(owner(),true);
        _excludedFromRewards(deadWallet,true);
        _excludedFromRewards(address(uniswapV2Router),true);
        _excludedFromRewards(address(uniswapV2Pair),true);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function recoverLeftOverCoinAmount(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

    function recoverLeftOverToken(address token,uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(),amount);
    }

    function setBalanceForBuyback(uint256 newMinValue,uint256 newMaxValue) external onlyOwner {
        require(newMinValue != 0 && newMaxValue != 0, "RewardPool: Can't be zero");
        require(newMinValue < newMaxValue, "RewardPool: Invalid Amount");

        minimumCoinBalanceForBuyback = newMinValue;
        maximumCoinBalanceForBuyback = newMaxValue;
    }

    function setMinimumTokenBalanceForRewards(address reward,uint256 newValue) external onlyOwner {
        _rewardInfo[reward].minimumTokenBalanceForRewards = newValue;
    }

    function validateDistributeShare(uint256 newShare) public view returns (bool) {
        uint256 currenShares = newShare;
        for(uint8 i;i<totalRewardDistributor;i++) {
            currenShares = currenShares.add(_rewardInfo[_rewardAsset[i]].distributeShare);
        }
        return (currenShares <= distributeSharePrecision);
    }

    function setDistributeShare(address rewardToken,uint256 newShare) external onlyOwner {
        require(_rewardInfo[rewardToken].isActive, "RewardPool: Reward Token is invalid");
        _rewardInfo[rewardToken].distributeShare = newShare;
        require(validateDistributeShare(0), "RewardPool: DistributeShare is invalid");
    }

    function setBuyBackWait(uint256 newBuyBackWait) external onlyOwner {
        buyBackWait = newBuyBackWait;
    }

    function createRewardDistributor(
        address _rewardToken,
        uint256 _distributeShare,
        uint256 _claimWait,
        uint256 _minimumTokenBalanceForRewards
    ) external onlyOwner returns (address){
        require(validateDistributeShare(_distributeShare), "RewardPool: DistributeShare is invalid");
        require(_rewardInfo[_rewardToken].rewardDistributor == address(0), "RewardPool: RewardDistributor is already exist");
        require(totalRewardDistributor < 9, "RewardPool: Reward token limit exceed");

        RewardDistributor newRewardsDistributor = new RewardDistributor(_rewardToken);

        _rewardAsset[totalRewardDistributor] = _rewardToken;
        _rewardInfo[_rewardToken] = (
            rewardStore({
                rewardDistributor: address(newRewardsDistributor),
                distributeShare: _distributeShare,
                claimWait: _claimWait,
                lastProcessedIndex : 0,
                minimumTokenBalanceForRewards : _minimumTokenBalanceForRewards,
                magnifiedRewardPerShare : 0,
                totalRewardsDistributed : 0,
                totalSupply: 0,
                isActive: true
            })
        ); 
        totalRewardDistributor++;

        // exclude from receiving rewards
        _excludedFromRewards((address(newRewardsDistributor)),true);

        return address(newRewardsDistributor);
    }

    function updateRewardDistributor(address rewardToken,address newRewardsDistributor) external onlyOwner {
        require(_rewardInfo[rewardToken].rewardDistributor != address(0), "RewardPool: Reward is not exist");

        _rewardInfo[rewardToken].rewardDistributor = newRewardsDistributor;
        _excludedFromRewards((address(newRewardsDistributor)),true);
    }

    function setRewardActiveStatus(address rewardAsset,bool status) external onlyOwner {
        _rewardInfo[rewardAsset].isActive = status;
    }

    function getBuyBackLimit(uint256 currentBalance) internal view returns (uint256,uint256) {
        return (currentBalance.mul(minimumCoinBalanceForBuyback).div(1e2),
                currentBalance.mul(maximumCoinBalanceForBuyback).div(1e2));
    }

    function generateBuyBackForOpen() external whenNotPaused nonReentrant {
        require(lastBuyBackTimestamp.add(buyBackWait) < block.timestamp, "RewardPool: buybackclaim still not over");

        uint256 initialBalance = address(this).balance;

        (uint256 _minimumCoinBalanceForBuyback,) = getBuyBackLimit(initialBalance);

        require(initialBalance >= _minimumCoinBalanceForBuyback, "RewardPool: Required Minimum BuyBack Amount");
        lastBuyBackTimestamp = block.timestamp;

        for(uint8 i; i<totalRewardDistributor; i++) {
            address rewardToken = _rewardAsset[i];
            if(_rewardInfo[rewardToken].isActive) {                
                swapAndSendReward(
                    rewardToken,
                    _minimumCoinBalanceForBuyback.mul(_rewardInfo[rewardToken].distributeShare).div(1e2)
                );
            }
        }
    }

    function generateBuyBack(uint256 buyBackAmount) external whenNotPaused onlyOwner nonReentrant {
        require(lastBuyBackTimestamp.add(buyBackWait) < block.timestamp, "RewardPool: buybackclaim still not over");

        uint256 initialBalance = address(this).balance;

        (uint256 _minimumCoinBalanceForBuyback,uint256 _maximumCoinBalanceForBuyback) = getBuyBackLimit(initialBalance);

        require(initialBalance > _minimumCoinBalanceForBuyback, "RewardPool: Required Minimum BuyBack Amount");

        lastBuyBackTimestamp = block.timestamp;
        buyBackAmount = buyBackAmount > _maximumCoinBalanceForBuyback ? 
                            _maximumCoinBalanceForBuyback : 
                            buyBackAmount > _minimumCoinBalanceForBuyback ? buyBackAmount : _minimumCoinBalanceForBuyback;
        
        for(uint8 i; i<totalRewardDistributor; i++) {
            address rewardToken = _rewardAsset[i];
            if(_rewardInfo[rewardToken].isActive) {                
                swapAndSendReward(
                    rewardToken,
                    buyBackAmount.mul(_rewardInfo[rewardToken].distributeShare).div(1e2)
                );
            }
        }
    }

    function setPair() public onlyOwner {
        require(address(uniswapV2Pair) == address(0), "RewardPool: Pair is already updated");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(uniswapV2Router.WETH(),nativeAsset);

        _excludedFromRewards(address(uniswapV2Router),true);
        _excludedFromRewards(address(uniswapV2Pair),true);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue != gasForProcessing, "RewardPool: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(address rewardToken,uint256 claimWait) external onlyOwner {
        _rewardInfo[rewardToken].claimWait = claimWait;
    }

    function getClaimWait(address rewardToken) external view returns(uint256) {
        return _rewardInfo[rewardToken].claimWait;        
    }

    function getTotalRewardsDistributed(address reward) external view returns (uint256) {
        return IRewardDistributor(_rewardInfo[reward].rewardDistributor).totalRewardsDistributed();
    }

    function _excludedFromRewards(address account,bool status) internal {
        excludedFromRewards[account] = status;

        if(status) {
            for(uint8 i;i<totalRewardDistributor;i++) {
                address reward = _rewardAsset[i];
                bytes32 slot = getDistributeSlot(reward,account);
                
                tokenHoldersMap[reward].remove(account);
                _setBalance(reward,slot,0);
            }
        }else {
            uint256 newBalance = IERC20(nativeAsset).balanceOf(account);

            for(uint8 i;i<totalRewardDistributor;i++) {
                address reward = _rewardAsset[i];
                bytes32 slot = getDistributeSlot(reward,account);

                if(newBalance >= _rewardInfo[reward].minimumTokenBalanceForRewards) {
                    tokenHoldersMap[reward].set(account, newBalance);
                    _setBalance(reward,slot,newBalance);
                }else {
                    tokenHoldersMap[reward].remove(account);
                    _setBalance(reward,slot,0);
                }
            }
        }
    }

	function excludeFromRewards(address account) external onlyOwner{
        _excludedFromRewards(account,true);
	}

    function includeInRewards(address account) external onlyOwner{
       _excludedFromRewards(account,false);
	}
    	
    function getAccountRewardsInfo(address reward,address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableRewards,
            uint256 totalRewards,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap[reward].getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > _rewardInfo[reward].lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(_rewardInfo[reward].lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap[reward].keys.length > _rewardInfo[reward].lastProcessedIndex ? 
                            tokenHoldersMap[reward].keys.length.sub(_rewardInfo[reward].lastProcessedIndex) : 0;
                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }

        bytes32 slot = getDistributeSlot(reward,account);
        withdrawableRewards = withdrawableRewardOf(reward,account);
        totalRewards = accumulativeRewardOf(reward,slot);

        lastClaimTime = _distributeInfo[slot].lastClaimTimes;

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(_rewardInfo[reward].claimWait) : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function accumulativeRewardOf(address reward,bytes32 slot) internal view returns (uint256) {
        return (
        (_rewardInfo[reward].magnifiedRewardPerShare.mul(_distributeInfo[slot].balanceOf).toInt256Safe()
             .add(_distributeInfo[slot].magnifiedRewardCorrections).toUint256Safe() / magnitude)
        );
    }

    function getAccountRewardsInfoAtIndex(address reward,uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap[reward].size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap[reward].getKeyAtIndex(index);

        return getAccountRewardsInfo(reward,account);
    }

    function singleRewardClaimByUser(address rewardToken) external whenNotPaused nonReentrant{
        require(_rewardInfo[rewardToken].isActive, "RewardPool: Pool is not active");
        _updateBalance(msg.sender,IERC20(nativeAsset).balanceOf(msg.sender));
        _withdrawRewardsOfUser(rewardToken,_msgSender(),false);
    }

    function multipleRewardClaimByUser() external whenNotPaused nonReentrant{
        address user = _msgSender();
        _updateBalance(user,IERC20(nativeAsset).balanceOf(user));
        for(uint8 i;i<totalRewardDistributor;i++) {
            if(_rewardInfo[_rewardAsset[i]].isActive) { 
                _withdrawRewardsOfUser(_rewardAsset[i],user,false);
            }
        }  
    }

    function getLastProcessedIndex(address rewardToken) external view returns(uint256) {
    	return _rewardInfo[rewardToken].lastProcessedIndex;
    }

    function totalHolderSupply(address rewardToken) external view returns (uint256) {
        return _rewardInfo[rewardToken].totalSupply;
    }

    function getNumberOfTokenHolders(address reward) public view returns(uint256) {
        return tokenHoldersMap[reward].keys.length;
    }

    function canAutoClaim(uint256 claimWait,uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
 
    function autoDistribute(address rewardToken) external returns (uint256, uint256, uint256) {
        uint256 gas = gasForProcessing;
    	uint256 numberOfTokenHolders = tokenHoldersMap[rewardToken].keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, _rewardInfo[rewardToken].lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = _rewardInfo[rewardToken].lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap[rewardToken].keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap[rewardToken].keys[_lastProcessedIndex];
    		
    		if(_withdrawRewardsOfUser(rewardToken,account, true)) {
    				claims++;
    		}
    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	_rewardInfo[rewardToken].lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, _rewardInfo[rewardToken].lastProcessedIndex);
    }

    function setBalance(address account, uint256 newBalance) external onlyOperator {
        _updateBalance(account,newBalance);
    }

    function updateBalance() external whenNotPaused{
        _updateBalance(_msgSender(),IERC20(nativeAsset).balanceOf(_msgSender()));
    }

    function _updateBalance(address account, uint256 newBalance) internal {
    	if(excludedFromRewards[account]) {
    		return;
    	}

        for(uint8 i;i<totalRewardDistributor;i++) {
            address reward = _rewardAsset[i];
            bytes32 slot = getDistributeSlot(reward,account);

            if(newBalance >= _rewardInfo[reward].minimumTokenBalanceForRewards) {
            	tokenHoldersMap[reward].set(account, newBalance);
                _setBalance(reward,slot,newBalance);
            }else {
            	tokenHoldersMap[reward].remove(account);
                _setBalance(reward,slot,0);
            }
        }    	
    }


    function _setBalance(address reward,bytes32 slot,uint256 newBalance) internal {      
        uint256 currentBalance = _distributeInfo[slot].balanceOf;

        if(newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _distributeInfo[slot].balanceOf += mintAmount;
            _distributeInfo[slot].magnifiedRewardCorrections = _distributeInfo[slot].magnifiedRewardCorrections.sub(
                (_rewardInfo[reward].magnifiedRewardPerShare.mul(mintAmount)).toInt256Safe()
            ); 
            _rewardInfo[reward].totalSupply += mintAmount;
        }else if(newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            require(currentBalance >= burnAmount, "ERC20: burn amount exceeds balance");
            _distributeInfo[slot].balanceOf = currentBalance - burnAmount;
            _distributeInfo[slot].magnifiedRewardCorrections = _distributeInfo[slot].magnifiedRewardCorrections.add(
                (_rewardInfo[reward].magnifiedRewardPerShare.mul(burnAmount)).toInt256Safe()
            );

            _rewardInfo[reward].totalSupply -= burnAmount;
        }        
    }

    function _withdrawRewardsOfUser(address reward,address account,bool automatic) internal returns (bool) {
        bytes32 slot = getDistributeSlot(reward,account);
        if(!(canAutoClaim(_rewardInfo[reward].claimWait,_distributeInfo[slot].lastClaimTimes)) ||
            _rewardInfo[reward].minimumTokenBalanceForRewards > _distributeInfo[slot].balanceOf) {
            return false;
        }
        uint256 _withdrawableReward = _withdrawableRewardOf(
                                        _rewardInfo[reward].magnifiedRewardPerShare,
                                        slot
                                        );
        if (_withdrawableReward > 0) {
            _distributeInfo[slot].withdrawnRewards = _distributeInfo[slot].withdrawnRewards.add(_withdrawableReward);

            bool success = IRewardDistributor(_rewardInfo[reward].rewardDistributor).distributeReward(account,_withdrawableReward);
            emit RewardWithdrawn(account, _withdrawableReward,success);

            if(!success) {
                _distributeInfo[slot].withdrawnRewards =  _distributeInfo[slot].withdrawnRewards.sub(_withdrawableReward);
                return false;
            }

            _distributeInfo[slot].lastClaimTimes = block.timestamp;
            emit Claim(account, _withdrawableReward, automatic);

            return true;
        }

        return false;
    }
    
    function withdrawableRewardOf(address reward,address account) public view returns(uint256) {
        return _withdrawableRewardOf(
            _rewardInfo[reward].magnifiedRewardPerShare,
            getDistributeSlot(reward,account));
  	}

    function rewardOf(address reward,address account) external view returns(uint256) {
        return _withdrawableRewardOf(
            _rewardInfo[reward].magnifiedRewardPerShare,
            getDistributeSlot(reward,account));
    }

    function _withdrawableRewardOf(uint256 magnifiedRewardPerShare,bytes32 slot) internal view returns(uint256) {
        return (magnifiedRewardPerShare.mul(_distributeInfo[slot].balanceOf).toInt256Safe()
        .add(_distributeInfo[slot].magnifiedRewardCorrections).toUint256Safe() / magnitude
        ).sub(_distributeInfo[slot].withdrawnRewards);
    }

    function withdrawnRewardOf(address reward,address user) external view returns(uint256) {
        return _distributeInfo[getDistributeSlot(reward,user)].withdrawnRewards;
    }

    function swapCoinForReward(address rewardAsset,uint256 coinAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = rewardAsset;

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: coinAmount}(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAndSendReward(address rewardAsset,uint256 coinAmount) internal {
        swapCoinForReward(rewardAsset,coinAmount);
        uint256 rewards = IERC20(rewardAsset).balanceOf(address(this));
        bool success = IERC20(rewardAsset).transfer(_rewardInfo[rewardAsset].rewardDistributor, rewards);
		
        if (success) {
            distributeRewards(rewardAsset,rewards);
            emit SendRewards(coinAmount, rewards);
        }
    }

    function distributeRewards(address reward,uint256 amount) internal{
        require(_rewardInfo[reward].totalSupply > 0, "Rewards: Supply is Zero");

        if (amount > 0) {
        _rewardInfo[reward].magnifiedRewardPerShare = _rewardInfo[reward].magnifiedRewardPerShare.add(
            (amount).mul(magnitude) / _rewardInfo[reward].totalSupply
        );
        emit RewardsDistributed(msg.sender, amount);

        _rewardInfo[reward].totalRewardsDistributed = _rewardInfo[reward].totalRewardsDistributed.add(amount);      
        }
    }

    function getRewardsDistributor(address rewardAsset) external view returns (address) {
        return _rewardInfo[rewardAsset].rewardDistributor;     
    }

    function getRewardDistributorInfo(address rewardAsset) external view returns (
        address rewardDistributor,
        uint256 distributeShare,
        bool isActive
    ) {
        return (
            _rewardInfo[rewardAsset].rewardDistributor,
            _rewardInfo[rewardAsset].distributeShare,
            _rewardInfo[rewardAsset].isActive
        );
    }

    function getTotalNumberofRewardsDistributor() external view returns (uint256) {
        return totalRewardDistributor;
    }

    function getPoolStatus(address rewardAsset) external view returns (bool isActive) {
        return _rewardInfo[rewardAsset].isActive;
    }

    function rewardsDistributorAt(uint8 index) external view returns (address) {
        return  _rewardInfo[_rewardAsset[index]].rewardDistributor;
    }

    function getAllRewardsDistributor() external view returns (address[] memory rewardDistributors) {
        rewardDistributors = new address[](totalRewardDistributor);
        for(uint8 i; i<totalRewardDistributor; i++) {
            rewardDistributors[i] = _rewardInfo[_rewardAsset[i]].rewardDistributor;
        }
    }

    function getDistributeSlot(address rewardToken,address user) internal pure returns (bytes32) {
        return (
            keccak256(abi.encode(rewardToken,user))
        );
    }

    function getMinmumAndMaximumBuyback() external view returns (uint256 _minimumCoinBalanceForBuyback,uint256 _maximumCoinBalanceForBuyback) {
        return (getBuyBackLimit(address(this).balance));
    }

    function rewardInfo(address rewardToken) external view returns (
        address rewardDistributor,
        uint256 distributeShare,
        uint256 claimWait,
        uint256 lastProcessedIndex,
        uint256 minimumTokenBalanceForRewards,
        uint256 magnifiedRewardPerShare,
        uint256 totalRewardsDistributed,
        uint256 totalSupply,
        bool isActive
    ) {
        rewardStore memory store = _rewardInfo[rewardToken];
        return (
            store.rewardDistributor,
            store.distributeShare,
            store.claimWait,
            store.lastProcessedIndex,
            store.minimumTokenBalanceForRewards,
            store.magnifiedRewardPerShare,
            store.totalRewardsDistributed,
            store.totalSupply,
            store.isActive
        );
    }

    function distributeInfo(address reward,address user) external view returns (
        uint256 lastClaimTimes,
        int256 magnifiedRewardCorrections,
        uint256 withdrawnRewards,
        uint256 balanceOf
    ) {
        bytes32 slot = getDistributeSlot(reward,user);
        return (
            _distributeInfo[slot].lastClaimTimes,
            _distributeInfo[slot].magnifiedRewardCorrections,
            _distributeInfo[slot].withdrawnRewards,
            _distributeInfo[slot].balanceOf
        );
    }

    function coinBalance() external view returns (uint256) {
        return (address(this).balance);
    }

    function isExcludedFromReward(address account) external view returns(bool) {
        return excludedFromRewards[account];
    }

    function rewardAssetAt(uint8 index) external view returns (address) {
        return _rewardAsset[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IRewardPool.sol";

contract RewardDistributor is Ownable {
    using Address for address payable;
    using SafeMath for uint256;

    IERC20 public rewardToken;
    IRewardPool public rewardPool;
    uint256 public totalRewardsDistributed;

    constructor(address _rewardToken) {
        rewardPool = IRewardPool(_msgSender());
        rewardToken = IERC20(_rewardToken);
    }

    modifier onlyOperator() {
        require(_msgSender() == address(rewardPool) ,"onlyOperator");
        _;
    }

    function distributeReward(address account,uint256 amount) external onlyOperator returns (bool){
        rewardToken.transfer(account, amount);

        totalRewardsDistributed = totalRewardsDistributed.add(amount); 

        return true;     
    }
    function recoverLeftOverBNB(uint256 amount) external onlyOwner {
        payable(owner()).sendValue(amount);
    }

    function recoverLeftOverToken(address token,uint256 amount) external onlyOwner {
        IERC20(token).transfer(owner(),amount);
    }

    function rewardOf(address account) external view returns(uint256) {
        return rewardPool.rewardOf(address(rewardToken),account);
    }

    function withdrawnRewardOf(address account) external view returns(uint256) {
        return rewardPool.withdrawnRewardOf(address(rewardToken),account);
    }   
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./IRewardDistributor.sol";

interface IRewardPool {
    function rewardOf(address reward,address account) external view returns(uint256);
    function withdrawnRewardOf(address reward,address user) external view returns(uint256);
    function setBalance(address account, uint256 newBalance) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRewardDistributor {
    function totalRewardsDistributed() external view returns (uint256);
    function distributeReward(address account,uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function isHolder(Map storage map,address key) public view returns (bool) {
        return map.inserted[key];
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

pragma solidity 0.8.13;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}