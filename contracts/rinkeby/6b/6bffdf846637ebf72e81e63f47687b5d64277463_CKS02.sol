/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

abstract contract Auth {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
    function transferOwnership(address payable _newOwner) external onlyOwner { owner = _newOwner; emit OwnershipTransferred(_newOwner); }
    event OwnershipTransferred(address owner);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract CKS02 is Auth {
    uint256 private _settingsWindowDuration = 86400; // settings get unlocked only for 24 hours (86400), then will be locked again
    uint256 private _settingsUnlockTimer = 180; //settings unlock wait time - 30 sec local, 3 minutes (180) in testnet, 7 days (604800) in mainnet

    uint256 private _migrationMinUnlockWait = 180; //TODO: 30s in local test, 3 mins (180) in testnet, 14 days (14 * 86400) in Mainnet
    uint256 private _migrationTimerStarted;
    uint256 private _migrationUnlocksOn;

    uint256 private _balanceRewardsPool;
    uint256 private _balanceStakedTokens;
    uint256 private _stakedWalletsCount; //TODO: missing function that adds and removes wallets as they newly stake, or claim and unstake everything

    struct StakingSettings {
        uint256 settingsUnlockWindowStart;
        uint256 settingsUnlockWindowEnd;

        address caToken; // main token contract
        address caTreasuryDAO; // DAO contract that acts as a treasury

        uint256 unstakeCooldownDuration; //14 minutes in testnet, 14 days in mainnet
        // uint16 rewardsAPR; // 30% per year
        uint256 rewardsAPR; // 30% per year
        uint16 prematureClaimPenalty; // 30 % of all tokens (staked and accrued reward) will be taken in a premature claim
        uint32 rewardsUpdatePeriod;
    }

    uint256 private _dailyDividend;
    uint256 private _dailyDivisor;

    StakingSettings public stakingSettings;

    mapping(address => uint256) private _firstSeen;

    struct StakingData {
        // uint256 firstSeen; //write-once timestamp the first time wallet ever staked
        uint256 stakingStartTime; //when did staking start on this wallet
        uint256 lastUpdateTime; //if you add more tokens to stake, record this here while locking the rewards
        uint256 unstakeLockedUntil; //for special accounts that are locked (i.e. vested presale), normal accounts have value 0
        uint256 lockedAmount; //amount of locked tokens

        uint256 stakedTokens; //how much was deposited for staking by lastUpdateTime
        uint256 rewardTokensOwned; //whenever staked balance changes or stake/unstake is called, accrued rewards are locked in here

        uint256 unstakeRequestedOn;
        uint256 unstakeAmountRequested;
        uint256 unstakeCooldownFinish;
        uint256 claimedOn;

        // uint256 activeAPR; //in case global APR rate changes the staking continues until people unstake/restake
        // uint16 activeAPR; //in case global APR rate changes the staking continues until people unstake/restake

        uint256 dayDividend;
        uint256 dayDivisor;

        bool claimedWithPenalty;
    }

    address[] public walletList; //holds a list of all wallets that ever staked, 

    mapping(address => StakingData) private _stakingData;

    event SettingsUnlockTimerStarted(uint256 requestedOn, uint256 unlocksOn);
    event SettingsLocked(uint256 lockedOn);
    event SettingsUpdated(address caToken, address caTreasuryDAO, uint256 unstakeCooldownDuration, uint256 rewardsAPR, uint16 prematureClaimPenalty);

    event TokensAddedToRewardsPool(address source, uint256 amount);
    event TokensStaked(address wallet, uint256 amount);
    event UnstakeRequested(address wallet, uint256 amount);
    event UnstakeRequestedCancelled(address wallet);
    event TokensClaimed(address wallet, uint256 amount, bool claimedWithPenalty);
    event RestakeRewards(address wallet, uint256 amount);
    // event ClaimRewards(address wallet, uint256 amount);
    event VestedStakingAirdrop(address source, uint256 walletCount, uint256 totalTokenAmount, uint256 lockedUntil);

    event MigrationLocked(uint256 lockedOn);
    event MigrationUnlockTimerStarted(uint256 startedOn, uint256 duration, uint256 unlocksOn);
    event MigrationTransferredBalanceETH(address recipient, uint256 amount);
    event MigrationTransferredTokenBalance(address ercTokenCA, address recipient, uint256 amount);

    //////////////////////////////////////////////////////////////// CONSTRUCTOR ////////////////////////////////////////////////////////////////
    constructor() Auth(msg.sender) {    
        stakingSettings.settingsUnlockWindowEnd = block.timestamp + (7*86400); //after deploying the contract, initial settings are unlocked for 7 days to be configured and locked post launch
        stakingSettings.unstakeCooldownDuration = 14*60; //TODO 14 minutes in testnet, 14 days in mainnet 14*86400
        _dailyDividend = 1000822; //for 30% APY and 34.97% APY
        _dailyDivisor = 1000000; //for 30% APY and 34.97% APY
        stakingSettings.rewardsAPR = 30; //30% per year
        stakingSettings.prematureClaimPenalty = 30; // 30 % of all tokens (staked and accrued reward) will be taken in a premature unstake
        stakingSettings.rewardsUpdatePeriod = 237; //TODO: 86400 - 1 day in mainnet, in testnet we simulate 1 year lasts 1 day, so 1 day is about 3m57s == 237

        // FOR TEST REMOVE SOON:
        // _stakingData[owner].stakingStartTime = block.timestamp;
        // _stakingData[owner].lastUpdateTime = block.timestamp;
        // _stakingData[owner].stakedTokens = 1_000_000 * 10**9;
        // _stakingData[owner].dayDividend = _dailyDividend;
        // _stakingData[owner].dayDivisor = _dailyDivisor;
        // _balanceRewardsPool = 250_000_000 * 10**9;
    }

    receive() external payable {} //allows this contract to receive ETH in case it's ever needed
    function getOwner() external view returns (address) { return owner; }

    //////////////////////////////// SETTINGS MANAGEMENT ////////////////////////////////
    function settingsUnlockStartTimer() external onlyOwner {
        //settings can be changed after being unlocked, unlock is on a timer - 5 minutes in testnet, 7 days in mainnet
        if (stakingSettings.settingsUnlockWindowStart > block.timestamp && stakingSettings.settingsUnlockWindowEnd > stakingSettings.settingsUnlockWindowStart) { revert("Unlock timer already running"); }
        else if (stakingSettings.settingsUnlockWindowStart <= block.timestamp && stakingSettings.settingsUnlockWindowEnd > block.timestamp) { revert("Settings already unlocked"); }
        else {
            stakingSettings.settingsUnlockWindowStart = block.timestamp + _settingsUnlockTimer;
            stakingSettings.settingsUnlockWindowEnd = block.timestamp + _settingsUnlockTimer + _settingsWindowDuration;
        }
        emit SettingsUnlockTimerStarted(block.timestamp, stakingSettings.settingsUnlockWindowStart);
    }

    function settingsLockNow() external onlyOwner {
        //if settings are unlocked, they can be re-locked at any time
        require(stakingSettings.settingsUnlockWindowEnd > block.timestamp, "Settings already locked");
        stakingSettings.settingsUnlockWindowStart = block.timestamp - 2;
        stakingSettings.settingsUnlockWindowEnd = block.timestamp - 1;
        emit SettingsLocked(block.timestamp);
    }

    function settingsChange(address caToken, address caTreasuryDAO, uint256 unstakeCooldownDuration, uint256 dailyDividend, uint256 dailyDivisor, uint16 prematureClaimPenalty) external onlyOwner {
        require(stakingSettings.settingsUnlockWindowStart <= block.timestamp && stakingSettings.settingsUnlockWindowEnd > block.timestamp, "Settings locked");
        
        require(caToken != address(0) && caTreasuryDAO != address(0), "Zero address not allowed");
        stakingSettings.caToken = caToken;
        stakingSettings.caTreasuryDAO = caTreasuryDAO;

        require(unstakeCooldownDuration >= 60, "Unstaking cooldown can't be shorter than 1 minute"); //TODO - 5 minutes in testnet, will be changed to 1 day in mainnet
        stakingSettings.unstakeCooldownDuration = unstakeCooldownDuration; //how long is the unstake cooldown
        // require(rewardsAPR > 0, "APR must be higher than 0%"); //TODO - check and change to 20? 30 ? 
        // require(rewardsAPR <= 1000, "APR must be lower than 1000%"); //TODO - check and change to 20? 30 ? 
        _dailyDividend = dailyDividend; //1000822 - for 30% APR
        _dailyDivisor = dailyDivisor; //1000000 - for 30% APR
        stakingSettings.rewardsAPR = (dailyDividend*365) / (dailyDivisor/100) - (365*100); //set new APR based on the daily dividend and divisor
        require(stakingSettings.rewardsAPR>0, "APR must be >0");
        require(stakingSettings.rewardsAPR<500, "APR must be <500");

        require(prematureClaimPenalty <= 75, "Premature unstake penalty must be lower than 75%"); //TODO - check and change to the default 30 ? 
        stakingSettings.prematureClaimPenalty = prematureClaimPenalty; //set new APR, probably won't change but keep the ability to do so
        
        emit SettingsUpdated(caToken, caTreasuryDAO, unstakeCooldownDuration, stakingSettings.rewardsAPR, prematureClaimPenalty);
    }

    //////////////////////////////// Migration section ////////////////////////////////   
    function _migrationLocked() internal view returns (bool) {
        bool lockResult = true;
        if (_migrationUnlocksOn != 0 && _migrationUnlocksOn <= block.timestamp) { lockResult = false; }
        return lockResult;
    }

    function migrationStatus() public view returns (bool locked, bool unlockTimerRunning, uint256 unlockTimerStartedOn, uint256 unlocksOn, uint256 unlockTimeRemaining ) {
        bool timerRunning = false;
        uint256 unlockTimeLeft = 0; 
        if (_migrationUnlocksOn > 0 && block.timestamp < _migrationUnlocksOn) {
            timerRunning = true;
            unlockTimeLeft = _migrationUnlocksOn - block.timestamp;
        }
        return (_migrationLocked(), timerRunning, _migrationTimerStarted, _migrationUnlocksOn, unlockTimeLeft );
    }

    function migrationLockNow() external onlyOwner {
        _migrationTimerStarted = 0;
        _migrationUnlocksOn = 0;
        emit MigrationLocked(block.timestamp);
    }

    function migrationUnlockStartTimer(uint256 waitTime) external onlyOwner {
        if ( _migrationUnlocksOn > block.timestamp ) { revert("Unlock timer already running"); }
        else if ( _migrationUnlocksOn != 0 ) { revert("Migration already unlocked"); }

        require(waitTime >= _migrationMinUnlockWait, "Wait time cannot be less than 14 days");

        _migrationTimerStarted = block.timestamp;
        _migrationUnlocksOn = block.timestamp + waitTime;
        emit MigrationUnlockTimerStarted(_migrationTimerStarted, waitTime, _migrationUnlocksOn);
    }

    function migrationTransferBalanceETH(address payable recipient) external onlyOwner {
        require( !_migrationLocked(), "Migration is locked!" );
        uint256 ethBalance = address(this).balance;
        recipient.transfer(ethBalance);

        emit MigrationTransferredBalanceETH(recipient, ethBalance);
    }

    function migrationTransferBalanceERCtokens(address tokenCA, address recipient) external onlyOwner {
        require( !_migrationLocked(), "Migration is locked!" );

        IERC20 ercToken = IERC20(tokenCA);
        uint256 tokenBalance = ercToken.balanceOf(address(this));
        ercToken.transfer(recipient, tokenBalance);

        emit MigrationTransferredTokenBalance(tokenCA, recipient, tokenBalance);
    }


    //////////////////////////////// Staking section ////////////////////////////////

    function getGlobalStats() external view returns (uint256 stakedWallets, uint256 stakedTokens, uint256 rewardsPoolBalance) {
        return ( _stakedWalletsCount, _balanceStakedTokens, _balanceRewardsPool );
    }

    function addTokensToRewardsPool(uint256 amount) external onlyOwner {
        IERC20 tokenContract = IERC20(stakingSettings.caToken);
        require( tokenContract.allowance(msg.sender, address(this)) >= amount, "Token allowance too low" );
        uint256 oldTokenBalance = tokenContract.balanceOf(address(this));
        tokenContract.transferFrom(msg.sender, address(this), amount);
        uint256 newTokenBalance = tokenContract.balanceOf(address(this));
        require (newTokenBalance - oldTokenBalance == amount, "Amount mismatch post-transfer");
        _balanceRewardsPool += amount;
        emit TokensAddedToRewardsPool(msg.sender, amount);
    }

    function _getRewardsPaused(address staker) internal view returns (bool) {
        bool paused = false;
        if (_stakingData[staker].unstakeRequestedOn > 0) {
            if (_stakingData[staker].claimedOn > 0 && _stakingData[staker].claimedOn < block.timestamp) { paused = false; }
            else { paused = true; }
        }
        return paused;
    }

    // function _calculateRewardsNONCOMPOUNDED(address staker) internal view returns (uint256) {
    //     uint256 maxAnnualReward = _stakingData[staker].stakedTokens * _stakingData[staker].activeAPR / 100;
    //     uint256 actualReward;
    //     if ( _stakingData[staker].lastUpdateTime == 0 || _stakingData[staker].lastUpdateTime > block.timestamp || _getRewardsPaused(staker) ) { actualReward = 0; }
    //     else { actualReward = ( maxAnnualReward * ((block.timestamp - _stakingData[staker].lastUpdateTime)/stakingSettings.rewardsUpdatePeriod) ) / ((365 * 86400) / stakingSettings.rewardsUpdatePeriod) ; }
    //     return actualReward;
    // }

    function _calculateRewardsCOMPOUNDED(address staker) internal view returns (uint256) {
        uint256 actualRewards;
        uint256 currentlyOwned = _stakingData[staker].stakedTokens + _stakingData[staker].rewardTokensOwned;
        if ( currentlyOwned == 0 || _stakingData[staker].lastUpdateTime == 0 || _stakingData[staker].lastUpdateTime > block.timestamp || _getRewardsPaused(staker) ) { actualRewards = 0; }
        else { 
            uint256 daysPassed = (block.timestamp - _stakingData[staker].lastUpdateTime) / stakingSettings.rewardsUpdatePeriod;
            if (daysPassed == 0) { actualRewards = 0; }
            else {
                if (daysPassed > 365) { daysPassed = 365; } //max 1 year compounding, then user has to unstake or restake just to reset the timer to make sure the FOR loop doesn't cause extreme gas

                for(uint i=0; i < daysPassed; i++) {
                    currentlyOwned += currentlyOwned * (_dailyDividend-_dailyDivisor) / _dailyDivisor;
                }
                actualRewards = currentlyOwned - _stakingData[staker].stakedTokens - _stakingData[staker].rewardTokensOwned;
            }
        }
        return actualRewards;
    }

    function _lockRewards(address staker) internal {
        uint256 newRewardAmount  = _calculateRewardsCOMPOUNDED(staker);
        _stakingData[staker].rewardTokensOwned += newRewardAmount;
        _balanceRewardsPool -= newRewardAmount;
        // _stakingData[staker].activeAPR = stakingSettings.rewardsAPR;
        _stakingData[staker].dayDividend = _dailyDividend;
        _stakingData[staker].dayDivisor = _dailyDivisor;
        _stakingData[staker].lastUpdateTime = block.timestamp;
    }

    function _calcActiveAPR(address staker) internal view returns (uint256) {
        if (_stakingData[staker].dayDivisor == 0) { return 0; }
        else { return ( (_stakingData[staker].dayDividend*365) / (_stakingData[staker].dayDivisor/100) - (365*100) ); }
    }

    function getLockInfo(address staker) external view returns (uint256 lockResult, uint256 lockedTokenAmount) {
        return ( _stakingData[staker].unstakeLockedUntil, _stakingData[staker].lockedAmount);
    }

    function getStakingInfo(address staker) external view returns (uint256 started, uint256 lastChanged, uint256 stakedTokens, uint256 rewardsAccrued, uint256 activeAPR, bool rewardsPausedByUnstake ) {
        return (
            _stakingData[staker].stakingStartTime, 
            _stakingData[staker].lastUpdateTime, 
            _stakingData[staker].stakedTokens, 
            _stakingData[staker].rewardTokensOwned + _calculateRewardsCOMPOUNDED(staker),
            _calcActiveAPR(staker),
            _getRewardsPaused(staker)
        );
    }

    function getUnstakingInfo(address staker) external view returns (uint256 unstakeRequestedOn, uint256 unstakeAmount, uint256 unstakeCooldownFinish, uint256 unstakeCooldownTimeRemaining, uint256 claimedOn, bool claimedWithPenalty ) {
        uint256 remainingTime = 0;
        if (_stakingData[staker].unstakeCooldownFinish > block.timestamp) { remainingTime = _stakingData[staker].unstakeCooldownFinish - block.timestamp; }
        return (
            _stakingData[staker].unstakeRequestedOn, 
            _stakingData[staker].unstakeAmountRequested,
            _stakingData[staker].unstakeCooldownFinish,
            remainingTime, 
            _stakingData[staker].claimedOn,
            _stakingData[staker].claimedWithPenalty
        );
    }

    function _resetUnstaking(address staker) internal {
        _stakingData[staker].unstakeRequestedOn = 0;
        _stakingData[staker].unstakeAmountRequested = 0;
        _stakingData[staker].unstakeCooldownFinish = 0;
        _stakingData[staker].claimedOn = 0;
        _stakingData[staker].claimedWithPenalty = false;
        _stakingData[staker].lastUpdateTime = block.timestamp;
    }

    function _increaseStaking(address staker, uint256 amount) internal {
        require(amount>0, "Cannot stake 0 tokens");

        if (_firstSeen[staker] == 0) {
            //this wallet never staked before so set value and push it in the wallet list
            _firstSeen[staker] = block.timestamp;
            walletList.push(staker);
        }

        if (_stakingData[staker].stakedTokens == 0) {
            _stakingData[staker].stakingStartTime = block.timestamp;
            _stakingData[staker].rewardTokensOwned = 0;
            _stakedWalletsCount++;
        } else {
            _lockRewards(staker);
        }
        _stakingData[staker].lastUpdateTime = block.timestamp;
        // _stakingData[staker].activeAPR = stakingSettings.rewardsAPR;
        _stakingData[staker].dayDividend = _dailyDividend;
        _stakingData[staker].dayDivisor = _dailyDivisor;

        _stakingData[staker].stakedTokens += amount;

        _balanceStakedTokens += amount;
        _resetUnstaking(staker);
    }

    function _stakeTokens(address tokenSourceWallet, address staker, uint256 amount) internal {
        IERC20 tokenContract = IERC20(stakingSettings.caToken);

        require( tokenContract.allowance(tokenSourceWallet, address(this)) >= amount, "Token allowance too low" );

        uint256 oldTokenBalance = tokenContract.balanceOf(address(this));
        tokenContract.transferFrom(tokenSourceWallet, address(this), amount);
        uint256 newTokenBalance = tokenContract.balanceOf(address(this));
        require (newTokenBalance - oldTokenBalance == amount, "Delivered token amount mismatch!" );

        _increaseStaking(staker, amount);
        emit TokensStaked(staker, amount);
    }


    function stakeTokensDirect(uint256 amount) external {
        // direct call from user to staking contract
        _stakeTokens(msg.sender, msg.sender, amount);
    }

    function stakeTokensByProxy(address tokenOwner, uint256 amount) external returns (bool) {
        // call comes proxied through the main token contract which will first automatically set the allowance for the wallet that sent the transaction 
        require(msg.sender == stakingSettings.caToken, "Can only be called by main token contract");
        require(tokenOwner == tx.origin, "Can only stake for wallet that signed the transaction");
        _stakeTokens(tokenOwner, tokenOwner, amount);
        return true;
    }

    function stakeTokensOnBehalf(address[] calldata addresses, uint256 amountNonDecimal, uint256 lockedUntil) external onlyOwner {
        //contract owner will stake tokens on behalf of private and presale so they can see them on their dashboard but will have them locked, uses direct
        require(addresses.length > 0, "No addresses provided");
        require(lockedUntil>block.timestamp,"Lock must be in the future");
        require(addresses.length <= 100,"Wallet count over 100 (gas risk)");
        uint256 amount = amountNonDecimal * 10**9;
        uint256 totalAmount = amount * addresses.length;
        for(uint i=0; i < addresses.length; i++) {
            _stakeTokens(msg.sender, addresses[i], amount);
            if ( _stakingData[ addresses[i] ].unstakeLockedUntil != 0 ) { 
                //there is already some token lock present, in this case we cannot change the lock time, we can only add tokens
                require(_stakingData[ addresses[i] ].unstakeLockedUntil == lockedUntil,"Lock time mismatch");
            }
            _stakingData[ addresses[i] ].lockedAmount += amount;
        }
        emit VestedStakingAirdrop(msg.sender, addresses.length, totalAmount, lockedUntil);
    }

    function unstakeTokens(uint256 amount) external {
        require(amount>0, "Amount cannot be 0");
        address staker = msg.sender;
        // require(block.timestamp > _stakingData[staker].unstakeLockedUntil, "Staked tokens are currently locked");

        //doing lockRewards early so we don't double the big gas for loop in calculateRewards...
        _lockRewards(staker);
        uint256 tokensAvailable = _stakingData[staker].stakedTokens + _stakingData[staker].rewardTokensOwned + _calculateRewardsCOMPOUNDED(staker);

        if (block.timestamp < _stakingData[staker].unstakeLockedUntil) {
            require( _stakingData[staker].lockedAmount < tokensAvailable - amount, "Cannot unstake locked amount" );
        } else {
            if (_stakingData[staker].unstakeLockedUntil > 0) { _stakingData[staker].unstakeLockedUntil = 0; }
        }

        if (tokensAvailable < amount) { revert("Staking balance too low"); }
        else if ( tokensAvailable > amount && (tokensAvailable - amount) < 10**9) {
            //difference is less than 1 token, user likely requested to claim everything
            amount = tokensAvailable;
        }

        // _lockRewards(staker);
        _stakingData[staker].unstakeRequestedOn = block.timestamp;
        _stakingData[staker].unstakeCooldownFinish = block.timestamp + stakingSettings.unstakeCooldownDuration;
        _stakingData[staker].unstakeAmountRequested = amount;
        _stakingData[staker].claimedOn = 0;
        _stakingData[staker].claimedWithPenalty = false;
        emit UnstakeRequested(staker, amount);
    }

    function unstakeTokensCancel() external {
        //user will call this if he requested unstake, but changed his mind and wants to start accruing rewards again.
        _resetUnstaking(msg.sender);
        emit UnstakeRequestedCancelled(msg.sender);
    }


    function stakeAccruedRewards() external {
        address staker = msg.sender;
        _lockRewards(staker);
        uint256 rewardsBalance = _stakingData[staker].rewardTokensOwned;
        _balanceRewardsPool -= rewardsBalance;
        _stakingData[staker].rewardTokensOwned -= rewardsBalance; //remove tokens from owned rewards
        _increaseStaking(staker, rewardsBalance); //add into staked tokens

        emit RestakeRewards(staker, rewardsBalance);
    }

    // function claimAccruedRewards() external {
    //     address staker = msg.sender;
    //     _lockRewards(staker);
    //     uint256 rewardsBalance = _stakingData[staker].rewardTokensOwned;
    //     _balanceRewardsPool -= rewardsBalance;
    //     _stakingData[staker].rewardTokensOwned -= rewardsBalance; //remove tokens from owned rewards

    //     IERC20 tokenContract = IERC20(stakingSettings.caToken);
    //     tokenContract.transfer(staker, rewardsBalance);

    //     emit ClaimRewards(staker, rewardsBalance);
    // }

    function _removeStakedTokens(address staker, uint256 amount) internal {
        require(amount <= _stakingData[staker].stakedTokens + _stakingData[staker].rewardTokensOwned, "Not enough tokens to claim");
        uint256 amountLeft = amount;
        //first remove tokens from rewards
        if (amountLeft >= _stakingData[staker].rewardTokensOwned) {
            _balanceRewardsPool -= _stakingData[staker].rewardTokensOwned;
            amountLeft -= _stakingData[staker].rewardTokensOwned;
            _stakingData[staker].rewardTokensOwned = 0;
        } else {
            _balanceRewardsPool -= amountLeft;
            _stakingData[staker].rewardTokensOwned -= amountLeft;
            amountLeft = 0;
        }
        //then if needed remove staked tokens
        if (amountLeft >= _stakingData[staker].stakedTokens) {
            _balanceStakedTokens -= _stakingData[staker].stakedTokens;
            amountLeft -= _stakingData[staker].stakedTokens;
            _stakingData[staker].stakedTokens = 0;
        } else {
            _balanceStakedTokens -= amountLeft;
            _stakingData[staker].stakedTokens -= amountLeft;
            amountLeft = 0;
        }
        require(amountLeft == 0, "Not all tokens have been removed");
    }

    function claimUnstakedTokens() external {
        address staker = msg.sender;
        require(block.timestamp > _stakingData[staker].unstakeRequestedOn + 60, "Claim too soon, wait 1 minute");
        require(_stakingData[staker].unstakeAmountRequested > 0, "No tokens requested to unstake");

        _lockRewards(staker);

        uint256 withdrawBalance = _stakingData[staker].unstakeAmountRequested;

        // require(block.timestamp > _stakingData[staker].unstakeLockedUntil, "Staked tokens are currently locked");
        if (block.timestamp < _stakingData[staker].unstakeLockedUntil) {
            // uint256 tokensAvailable = _stakingData[staker].stakedTokens;
            uint256 tokensAvailable = _stakingData[staker].stakedTokens + _stakingData[staker].rewardTokensOwned + _calculateRewardsCOMPOUNDED(staker);
            require( _stakingData[staker].lockedAmount < tokensAvailable - withdrawBalance, "Cannot claim locked amount" );
        }

        _removeStakedTokens(staker, withdrawBalance); 

        uint256 penalty;
        IERC20 tokenContract = IERC20(stakingSettings.caToken);

        if (_stakingData[staker].unstakeCooldownFinish > block.timestamp) {
            //premature claim with penalty
            penalty = withdrawBalance * stakingSettings.prematureClaimPenalty / 100;
            if (penalty>0) { tokenContract.transfer(stakingSettings.caTreasuryDAO, penalty); } //send penalty to Treasury DAO contract 
            withdrawBalance -= penalty; //update remaining withdraw balance by removing penalty tokens
            _stakingData[staker].claimedWithPenalty = true;
        }

        tokenContract.transfer(staker, withdrawBalance); //send remaining balance to the wallet making the claim
        _stakingData[staker].claimedOn = block.timestamp;
        if (_stakingData[staker].stakedTokens == 0) {
            //wallet has now zero staked balance, remove it from staked wallet count
            _stakedWalletsCount--;
        }

        emit TokensClaimed(staker, _stakingData[staker].unstakeAmountRequested, _stakingData[staker].claimedWithPenalty);
    }
}