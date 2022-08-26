// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IPYESlice.sol";
import "./interfaces/IApple.sol";

contract SmartChefPYE is Ownable, ReentrancyGuard, ERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The address of the smart chef factory
    address public SMART_CHEF_FACTORY;

    // PYESliceToken for stakers
    address public pyeSlice;
    IPYESlice PYESliceInterface;

    // donation state variables
    uint256 public totalDonations; // (sum of below)
    uint256 public pyeSwapDonations;
    uint256 public pyeLabDonations;
    uint256 public miniPetsDonations;
    uint256 public pyeWalletDonations;
    uint256 public pyeChartsDonations;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when Apple mining ends.
    uint256 public bonusEndBlock;

    // The block number when Apple mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // Apple tokens created per block.
    uint256 public rewardPerBlock;

    // The time for lock funds.
    uint256 public lockTime;

    // Dev fee.
    uint256 public devfee = 1000;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IApple public rewardToken;

    // The weth token and USDC token
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    // The staked token
    IERC20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided
        uint256 rewardDebt; // Reward debt
        uint256 depositTime;    // The last time when the user deposit funds
    }

    struct Share {
        uint256 amount;
        uint256 totalExcludedWETH;
        uint256 totalRealisedWETH;
        uint256 totalExcludedUSDC;
        uint256 totalRealisedUSDC; 
    }

    // Dev address.
    address public devaddr;
    //address public rewardDistributor;

    address[] stakers;
    mapping (address => uint256) stakerIndexes;
    mapping (address => uint256) stakerClaims;
    mapping (address => bool) isRewardExempt;

    mapping (address => Share) public shares;
// ----------------- BEGIN WETH Variables -----------

    uint256 public unallocatedWETHRewards;
    uint256 public totalShares;
    uint256 public totalRewardsWETH;
    uint256 public totalDistributedWETH;
    uint256 public rewardsPerShareWETH;
    uint256 public rewardsPerShareAccuracyFactor = 10 ** 36; // Keeping same accuracy factor in the USDC Token Variables

// ----------------- BEGIN USDC Token Variables -----------

    uint256 public unallocatedUSDCRewards;
    uint256 public totalRewardsUSDC;
    uint256 public totalDistributedUSDC;
    uint256 public rewardsPerShareUSDC;
    uint256 public totalStakedTokens;

// ----------------- END USDC Token Variables -----------    

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);
    event NewRewardPerBlock(uint256 rewardPerBlock);
    event NewPoolLimit(uint256 poolLimitPerUser);
    event RewardsStop(uint256 blockNumber);
    event Withdraw(address indexed user, uint256 amount);
    event NewLockTime(uint256 lockTime);
    event setLockTime(address indexed user, uint256 lockTime);
    event StakedAndMinted(address indexed _address, uint256 _blockTimestamp);
    event UnstakedAndBurned(address indexed _address, uint256 _blockTimestamp);

    constructor(IERC20 _stakedToken, IApple _rewardToken, uint256 _rewardPerBlock, uint256 _startBlock, uint256 _lockTime, address _pyeSlice) ERC20("","") {

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = 999999999;
        lockTime = _lockTime;
        devaddr = msg.sender;
        pyeSlice = _pyeSlice;

        PYESliceInterface = IPYESlice(_pyeSlice);

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        isRewardExempt[msg.sender] = true;
        isRewardExempt[address(this)] = true;
    }

    modifier onlyToken {
        require(msg.sender == address(stakedToken));
        _;
    }
    
    function deposit(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        if (hasUserLimit) {
            require(_amount.add(user.amount) <= poolLimitPerUser, "User amount above limit");
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                safeappleTransfer(msg.sender, pending);
            }
        }

        if (_amount > 0) {

            // begin slice logic
            uint256 currentStakedBalance = user.amount; // current staked balance
            uint256 currentPYESliceBalance = IERC20(pyeSlice).balanceOf(msg.sender);

            if (currentStakedBalance == 0 && currentPYESliceBalance == 0) {
                _beforeTokenTransfer(msg.sender, address(this), _amount);
                stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amount = user.amount.add(_amount);
                PYESliceInterface.mintPYESlice(msg.sender, 1);
                totalStakedTokens = totalStakedTokens.add(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
                user.depositTime = block.timestamp;
                emit StakedAndMinted(msg.sender, block.timestamp);
            } else {
                _beforeTokenTransfer(msg.sender, address(this), _amount);
                stakedToken.safeTransferFrom(address(msg.sender), address(this), _amount);
                user.amount = user.amount.add(_amount);
                totalStakedTokens = totalStakedTokens.add(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
                user.depositTime = block.timestamp; 
            }
        } else {
            distributeRewardWETH(msg.sender);
            distributeRewardUSDC(msg.sender);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(msg.sender, _amount);
    }

    function harvest() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
            if (pending > 0) {
                safeappleTransfer(msg.sender, pending);
            }
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Amount to withdraw too high");
        require(user.depositTime + lockTime < block.timestamp, "Can not withdraw in lock period");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {

            // begin slice logic
            uint256 currentStakedBalance = user.amount; // current staked balance
            uint256 currentPYESliceBalance = IERC20(pyeSlice).balanceOf(msg.sender);

            if (currentStakedBalance.sub(_amount) == 0 && currentPYESliceBalance > 0) {
                user.amount = user.amount.sub(_amount);
                _beforeTokenTransfer(address(this), msg.sender, _amount);
                stakedToken.safeTransfer(address(msg.sender), _amount);
                PYESliceInterface.burnPYESlice(msg.sender, currentPYESliceBalance);
                totalStakedTokens = totalStakedTokens.sub(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
                emit UnstakedAndBurned(msg.sender, block.timestamp);
            } else {
                user.amount = user.amount.sub(_amount);
                _beforeTokenTransfer(address(this), msg.sender, _amount);
                stakedToken.safeTransfer(address(msg.sender), _amount);
                totalStakedTokens = totalStakedTokens.sub(_amount);
                if(!isRewardExempt[msg.sender]){ setShare(msg.sender, user.amount); }
            }
        }

        if (pending > 0) {
            safeappleTransfer(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Withdraw(msg.sender, _amount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 currentPYESliceBalance = IERC20(pyeSlice).balanceOf(msg.sender);
        _beforeTokenTransfer(address(this), msg.sender, user.amount);

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(msg.sender), amountToTransfer);
            PYESliceInterface.burnPYESlice(msg.sender, currentPYESliceBalance);
            totalStakedTokens = totalStakedTokens.sub(amountToTransfer);
            emit UnstakedAndBurned(msg.sender, block.timestamp);
        }

        if(!isRewardExempt[msg.sender]){ setShare(msg.sender, 0); }

        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.transfer(address(msg.sender), _amount);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");
        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        require(hasUserLimit, "Must be set");
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");
            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            poolLimitPerUser = 0;
        }
        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update lock time
     * @dev Only callable by owner.
     * @param _lockTime: the time in seconds that staked tokens are locked
     */
    function updateLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;
        emit NewLockTime(_lockTime);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        
        if (block.number > lastRewardBlock && totalStakedTokens != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
            uint256 appleReward = multiplier.mul(rewardPerBlock);
            uint256 adjustedTokenPerShare =
            accTokenPerShare.add(appleReward.mul(PRECISION_FACTOR).div(totalStakedTokens));
            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        } else {
            return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }
    }

    // Safe apple transfer function, just in case if rounding error causes pool to not have enough apple.
    function safeappleTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBalance = rewardToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > tokenBalance) {
            transferSuccess = rewardToken.transfer(_to, tokenBalance);
        } else {
            transferSuccess = rewardToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStakedTokens == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);
        uint256 appleReward = multiplier.mul(rewardPerBlock);
        rewardToken.mint(devaddr, appleReward.mul(devfee).div(10000));
        rewardToken.mint(address(this), appleReward);
        accTokenPerShare = accTokenPerShare.add(appleReward.mul(PRECISION_FACTOR).div(totalStakedTokens));
        lastRewardBlock = block.number;
    }
    
    /*
     * @notice Return reward multiplier over the given _from to _to block.
     * @param _from: block to start
     * @param _to: block to finish
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from);
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock.sub(_from);
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return isRewardExempt[account];
    }

    function setIsRewardExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this));
        UserInfo storage user = userInfo[holder];
        isRewardExempt[holder] = exempt;
        if(exempt){
            setShare(holder, 0);
        }else{
            setShare(holder, user.amount);
        }
    }
    
    function setShare(address staker, uint256 amount) internal {
        if(shares[staker].amount > 0){
            distributeRewardWETH(staker);
            distributeRewardUSDC(staker);
        }

        if(amount > 0 && shares[staker].amount == 0){
            addStaker(staker);
        }else if(amount == 0 && shares[staker].amount > 0){
            removeStaker(staker);
        }

        totalShares = totalShares.sub(shares[staker].amount).add(amount);
        shares[staker].amount = amount;
        shares[staker].totalExcludedWETH = getCumulativeRewardsWETH(shares[staker].amount);
        shares[staker].totalExcludedUSDC = getCumulativeRewardsUSDC(shares[staker].amount);
    }
    
    // WETH STUFF

    function distributeRewardWETH(address staker) internal {
        if(shares[staker].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsWETH(staker);
        if(amount > 0){
            totalDistributedWETH = totalDistributedWETH.add(amount);
            IERC20(WETH).transfer(staker, amount);
            stakerClaims[staker] = block.timestamp;
            shares[staker].totalRealisedWETH = shares[staker].totalRealisedWETH.add(amount);
            shares[staker].totalExcludedWETH = getCumulativeRewardsWETH(shares[staker].amount);
        }
    }

    function claimWETH() external {
        distributeRewardWETH(msg.sender);
    }

    function getUnpaidEarningsWETH(address staker) public view returns (uint256) {
        if(shares[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewardsWETH = getCumulativeRewardsWETH(shares[staker].amount);
        uint256 stakerTotalExcludedWETH = shares[staker].totalExcludedWETH;

        if(stakerTotalRewardsWETH <= stakerTotalExcludedWETH){ return 0; }

        return stakerTotalRewardsWETH.sub(stakerTotalExcludedWETH);
    }

    function getCumulativeRewardsWETH(uint256 share) internal view returns (uint256) {
        return share.mul(rewardsPerShareWETH).div(rewardsPerShareAccuracyFactor);
    }

    function addStaker(address staker) internal {
        stakerIndexes[staker] = stakers.length;
        stakers.push(staker);
    }

    function removeStaker(address staker) internal {
        stakers[stakerIndexes[staker]] = stakers[stakers.length-1];
        stakerIndexes[stakers[stakers.length-1]] = stakerIndexes[staker];
        stakers.pop();
    }

    // Rescue eth that is sent here by mistake
    function rescueETH(uint256 amount, address to) external onlyOwner{
        payable(to).transfer(amount);
      }

    function setFee(address _feeAddress, uint256 _devfee) public onlyOwner {
        devaddr = _feeAddress;
        devfee = _devfee;
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyWETHWithdraw(uint256 _amount) external onlyOwner {
        IERC20(WETH).transfer(address(msg.sender), _amount);
    }


// ------------------- BEGIN USDC TOKEN FUNCTIONS ---------------

    function depositUSDCToStakingContract(uint256 _amountUSDC) external onlyToken {
        if (totalShares == 0) {unallocatedUSDCRewards = unallocatedUSDCRewards.add(_amountUSDC); return; } 
        
        if (unallocatedUSDCRewards > 0) {
            uint256 amount = _amountUSDC.add(unallocatedUSDCRewards);
            totalRewardsUSDC = totalRewardsUSDC.add(amount);
            rewardsPerShareUSDC = rewardsPerShareUSDC.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
            unallocatedUSDCRewards = 0;
        } else {
            totalRewardsUSDC = totalRewardsUSDC.add(_amountUSDC);
            rewardsPerShareUSDC = rewardsPerShareUSDC.add(rewardsPerShareAccuracyFactor.mul(_amountUSDC).div(totalShares));
        }   
    }

    function depositUSDC(uint256 _amount) external onlyOwner {
        uint256 balanceBefore = IERC20(address(USDC)).balanceOf(address(this));

        IERC20(USDC).transferFrom(address(msg.sender), address(this), _amount);

        uint256 amount = IERC20(address(USDC)).balanceOf(address(this)).sub(balanceBefore);

        totalRewardsUSDC = totalRewardsUSDC.add(amount);
        rewardsPerShareUSDC = rewardsPerShareUSDC.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        
    }

    function getCumulativeRewardsUSDC(uint256 share) internal view returns (uint256) {
        return share.mul(rewardsPerShareUSDC).div(rewardsPerShareAccuracyFactor);
    }

    function getUnpaidEarningsUSDC(address staker) public view returns (uint256) {
        if(shares[staker].amount == 0){ return 0; }

        uint256 stakerTotalRewardsUSDC = getCumulativeRewardsUSDC(shares[staker].amount);
        uint256 stakerTotalExcludedUSDC = shares[staker].totalExcludedUSDC;

        if(stakerTotalRewardsUSDC <= stakerTotalExcludedUSDC){ return 0; }

        return stakerTotalRewardsUSDC.sub(stakerTotalExcludedUSDC);
    }

    function distributeRewardUSDC(address staker) internal {
        if(shares[staker].amount == 0){ return; }

        uint256 amount = getUnpaidEarningsUSDC(staker);
        if(amount > 0){
            totalDistributedUSDC = totalDistributedUSDC.add(amount);
            IERC20(USDC).transfer(staker, amount);
            stakerClaims[staker] = block.timestamp;
            shares[staker].totalRealisedUSDC = shares[staker].totalRealisedUSDC.add(amount);
            shares[staker].totalExcludedUSDC = getCumulativeRewardsUSDC(shares[staker].amount);
        }
    }

    function claimUSDC() external {
        distributeRewardUSDC(msg.sender);
    }

    //--------------------- BEGIN DONATION FUNCTIONS -------------

    function addPYESwapDonation(uint256 _pyeSwapDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeSwapDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeSwapDonations += amount;
    }

    function addPYELabDonation(uint256 _pyeLabDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeLabDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeLabDonations += amount;
    }

    function addMiniPetsDonation(uint256 _miniPetsDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _miniPetsDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        miniPetsDonations += amount;
    }

    function addPYEWalletDonation(uint256 _pyeWalletDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeWalletDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeWalletDonations += amount;
    }

    function addPYEChartsDonation(uint256 _pyeChartsDonation) external nonReentrant {
        uint256 balanceBefore = IERC20(address(WETH)).balanceOf(address(this));
        IERC20(WETH).transferFrom(address(msg.sender), address(this), _pyeChartsDonation);
        uint256 amount = IERC20(address(WETH)).balanceOf(address(this)).sub(balanceBefore);
        totalRewardsWETH = totalRewardsWETH.add(amount);
        rewardsPerShareWETH = rewardsPerShareWETH.add(rewardsPerShareAccuracyFactor.mul(amount).div(totalShares));
        totalDonations += amount;
        pyeChartsDonations += amount;
    }

    //--------------------BEGIN MODIFIED SNAPSHOT FUNCITONALITY---------------

    // @dev a modified implementation of ERC20 Snapshot to keep track of staked balances (shares) rather than balanceOf (total token ownership). 
    // ERC20 Snapshot import/inheritance is avoided in this contract to avoid issues with interface conflicts and to directly control private 
    // functionality to keep snapshots of staked balances instead.
    // copied from source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/ERC20Snapshot.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;
    Counters.Counter private _currentSnapshotId;

    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalStakedSnapshots;

    // @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
    event Snapshot(uint256 id);

    // generate a snapshot, calls internal _snapshot().
    function snapshot() public onlyOwner {
        _snapshot();
    }

    function _snapshot() internal returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    function _getCurrentSnapshotId() internal view returns (uint256) {
        return _currentSnapshotId.current();
    }

    // @dev returns shares of a holder, not balanceOf, at a certain snapshot.
    function sharesOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : shares[account].amount;
    }

    // @dev returns totalStakedTokens at a certain snapshot
    function totalStakedAt(uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalStakedSnapshots);

        return snapshotted ? value : totalStakedTokens;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalStakedSnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalStakedSnapshot();
        } else if (to == address(this)) {
            // user is staking
            _updateAccountSnapshot(from);
            _updateTotalStakedSnapshot();
        } else if (from == address(this)) {
            // user is unstaking
            _updateAccountSnapshot(to);
            _updateTotalStakedSnapshot();
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], shares[account].amount);
    }

    function _updateTotalStakedSnapshot() private {
        _updateSnapshot(_totalStakedSnapshots, totalStakedTokens);
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }

    // ------------------ BEGIN PRESALE TOKEN FUNCTIONALITY -------------------

    // @dev struct containing all elements of pre-sale token. 
    struct presaleToken {
        string presaleTokenName;
        address presaleTokenAddress;
        uint256 presaleTokenBalance;
        uint256 presaleTokenRewardsPerShare; 
        uint256 presaleTokenTotalDistributed;
        uint256 presaleTokenSnapshotId;
    }

    // @dev dynamic array of struct presaleToken
    presaleToken[] public presaleTokenList;
    bool checkDuplicateEnabled; 
    mapping (address => uint256) entitledTokenReward;
    mapping (address => mapping (address => bool)) hasClaimed;

    //------------------- BEGIN PRESALE-TOKEN ARRAY MODIFIERS AND GETTERS--------------------

    // performs safety checks when depositing.
    modifier depositCheck(address _presaleTokenAddress, uint256 _amount) {
        require(IERC20(_presaleTokenAddress).balanceOf(msg.sender) >= _amount , "Deposit amount exceeds balance!"); 
        require(msg.sender != address(0) || msg.sender != 0x000000000000000000000000000000000000dEaD , "Cannot deposit from address(0)!");
        require(_amount != 0 , "Cannot deposit 0 tokens!");
        require(totalStakedTokens != 0 , "Nobody is staked!");
            _;
    }

    // @dev deletes the last struct in the presaleTokenList. 
    function popToken() internal {
        presaleTokenList.pop();
    }

    // returns number of presale Tokens stored.
    function getTokenArrayLength() public view returns (uint256) {
        return presaleTokenList.length;
    }

    // @dev enter the address of token to delete. avoids empty gaps in the middle of the array.
    function deleteToken(address _address) public onlyOwner {
        uint tokenLength = presaleTokenList.length;
        for(uint i = 0; i < tokenLength; i++) {
            if (_address == presaleTokenList[i].presaleTokenAddress) {
                if (1 < presaleTokenList.length && i < tokenLength-1) {
                    presaleTokenList[i] = presaleTokenList[tokenLength-1]; }
                    delete presaleTokenList[tokenLength-1];
                    popToken();
                    break;
            }
        }
    }

    // @dev create presale token and fund it. requires allowance approval from token. 
    function createAndFundPresaleToken(string memory _presaleTokenName, address _presaleTokenAddress, uint256 _amount) external onlyOwner depositCheck(_presaleTokenAddress, _amount) {
        // check duplicates
        if (checkDuplicateEnabled) { checkDuplicates(_presaleTokenAddress); }

        // deposit the token
        IERC20(_presaleTokenAddress).transferFrom(address(msg.sender), address(this), _amount);
        // store staked balances at time of reward token deposit
        _snapshot();
        // push new struct, with most recent snapshot ID
        presaleTokenList.push(presaleToken(
            _presaleTokenName, 
            _presaleTokenAddress, 
            _amount, 
            (rewardsPerShareAccuracyFactor.mul(_amount).div(totalStakedTokens)), 
            0,
            _getCurrentSnapshotId()));
    }

    // @dev change whether or not createAndFundToken should check for duplicate presale tokens
    function shouldCheckDuplicates(bool _bool) external onlyOwner {
        checkDuplicateEnabled = _bool;
    }

    // @dev internal helper function that checks the array for preexisting addresses
    function checkDuplicates(address _presaleTokenAddress) internal view {
        for(uint i = 0; i < presaleTokenList.length; i++) {
            if (_presaleTokenAddress == presaleTokenList[i].presaleTokenAddress) {
                revert("Token already exists!");
            }
        }
    }

    //------------------- BEGIN PRESALE-TOKEN TRANSFER FXNS AND STRUCT MODIFIERS --------------------

    // @dev update an existing token's balance based on index.
    function fundExistingToken(uint256 _index, uint256 _amount) external onlyOwner depositCheck(presaleTokenList[_index].presaleTokenAddress, _amount) {
        require(_index <= presaleTokenList.length , "Index out of bounds!");

        if ((bytes(presaleTokenList[_index].presaleTokenName)).length == 0 || presaleTokenList[_index].presaleTokenAddress == address(0)) {
            revert("Attempting to fund a token with no name, or with an address of 0.");
        }

        // do the transfer
        uint256 presaleTokenBalanceBefore = presaleTokenList[_index].presaleTokenBalance;
        uint256 presaleTokenRewardsPerShareBefore = presaleTokenList[_index].presaleTokenRewardsPerShare;
        IERC20(presaleTokenList[_index].presaleTokenAddress).transferFrom(address(msg.sender), address(this), _amount);
        _snapshot();
        // update struct balances to add amount
        presaleTokenList[_index].presaleTokenBalance = presaleTokenBalanceBefore.add(_amount);
        presaleTokenList[_index].presaleTokenRewardsPerShare = presaleTokenRewardsPerShareBefore.add((rewardsPerShareAccuracyFactor.mul(_amount).div(totalStakedTokens)));
        
    }

    // remove unsafe or compromised token from availability
    function withdrawExistingToken(uint256 _index) external onlyOwner {
        require(_index <= presaleTokenList.length , "Index out of bounds!");
        
        if ((bytes(presaleTokenList[_index].presaleTokenName)).length == 0 || presaleTokenList[_index].presaleTokenAddress == address(0)) {
            revert("Attempting to withdraw from a token with no name, or with an address of 0.");
        }

        // do the transfer
        IERC20(presaleTokenList[_index].presaleTokenAddress).transfer(address(msg.sender), presaleTokenList[_index].presaleTokenBalance);
        // update struct balances to subtract amount
        presaleTokenList[_index].presaleTokenBalance = 0;
        presaleTokenList[_index].presaleTokenRewardsPerShare = 0;
    }

    //-------------------------------- BEGIN PRESALE TOKEN REWARD FUNCTION-----------

    function claimPresaleToken(uint256 _index) external nonReentrant {
        require(_index <= presaleTokenList.length , "Index out of bounds!");
        require(!hasClaimed[msg.sender][presaleTokenList[_index].presaleTokenAddress] , "You have already claimed your reward!");
        // calculate reward based on share at time of current snapshot (which is when a token is funded or created)
        if(sharesOfAt(msg.sender, presaleTokenList[_index].presaleTokenSnapshotId) == 0){ 
            entitledTokenReward[msg.sender] = 0; } 
            else { entitledTokenReward[msg.sender] = sharesOfAt(msg.sender, presaleTokenList[_index].presaleTokenSnapshotId).mul(presaleTokenList[_index].presaleTokenRewardsPerShare).div(rewardsPerShareAccuracyFactor); }
        
        require(presaleTokenList[_index].presaleTokenBalance >= entitledTokenReward[msg.sender]);
        // struct balances before transfer
        uint256 presaleTokenBalanceBefore = presaleTokenList[_index].presaleTokenBalance;
        uint256 presaleTokenTotalDistributedBefore = presaleTokenList[_index].presaleTokenTotalDistributed;
        // transfer
        IERC20(presaleTokenList[_index].presaleTokenAddress).transfer(address(msg.sender), entitledTokenReward[msg.sender]);
        hasClaimed[msg.sender][presaleTokenList[_index].presaleTokenAddress] = true;
        // update struct balances 
        presaleTokenList[_index].presaleTokenBalance = presaleTokenBalanceBefore.sub(entitledTokenReward[msg.sender]);
        presaleTokenList[_index].presaleTokenTotalDistributed = presaleTokenTotalDistributedBefore.add(entitledTokenReward[msg.sender]);       
    }

    // allows user to see their entitled presaleToken reward based on staked balance at time of token creation
    function getUnpaidEarningsPresale(uint256 _index, address staker) external view returns (uint256) {
        uint256 entitled;
        if (hasClaimed[staker][presaleTokenList[_index].presaleTokenAddress]) {
            entitled = 0;
        } else {
            entitled = sharesOfAt(staker, presaleTokenList[_index].presaleTokenSnapshotId).mul(presaleTokenList[_index].presaleTokenRewardsPerShare).div(rewardsPerShareAccuracyFactor);
        }
        return entitled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IApple {
    function getOwnedBalance(address account) external view returns (uint256);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function mint(address to, uint value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPYESlice {
    function burnPYESlice(address _staker, uint256 _amount) external;
    function mintPYESlice(address _depositor, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}