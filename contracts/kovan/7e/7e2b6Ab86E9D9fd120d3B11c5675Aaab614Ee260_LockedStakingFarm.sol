// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./utils/SafeERC20.sol";
import "./interfaces/IFarm.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/CustomOwnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
    Locked farm with deposit and early widthrawal fees 
 */

contract LockedStakingFarm is CustomOwnable, Pausable, IFarm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant DAY_IN_SECONDS = 24 * 60 * 60;

    // Address of the ERC20 Token contract.
    IERC20 public immutable rewardToken;
    // total amount of reward token funded to this contract
    uint256 public totalERC20Rewards;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut;
    // amount of rewardToken distributed per Second.
    uint256 public rewardPerSecond;

    // time when the last rewardPerSecond has changed
    uint256 public lastEmissionChange;
    // all pending rewards before last rewards per second change
    uint256 public rewardsAmountBeforeLastChange;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // userInfo
    // index => userDeposit info
    mapping(uint256 => DepositInfo) public usersDeposits;
    uint256 private _depositsLength;

    // Info of each user that stakes LP tokens.
    // poolId => user => userInfoId's
    mapping(uint256 => mapping(address => UserInfo)) usersInfos;

    // Total Multiplier. Must be the sum of all Multipliers in all pools.
    uint256 public totalMultiplier;

    // The time when farming starts.
    uint256 public startTime;

    // The time when farming ends.
    uint256 public endTime;

    //fee wallet's address
    address public feeCollector;

    constructor(IERC20 rewardTokenAddress_,address owner_, address feeCollector_) CustomOwnable(owner_){
        rewardToken = rewardTokenAddress_;
        feeCollector = feeCollector_;
    }

    function setStartTime(uint256 epochTimestamp_) external onlyOwner {
        require(startTime == 0 || block.timestamp < startTime);
        uint256 duration = endTime - startTime;
        startTime = epochTimestamp_;

        //pool.lastRewardTime = startTime;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            poolInfo[i].lastRewardTime = startTime;
        }
        lastEmissionChange = startTime;

        endTime = duration < type(uint256).max
            ? epochTimestamp_ + duration
            : duration;
    }

    /**
        in case where the owner wants to end the farm early and recover the rewards funded
     */
    function setEndTime(uint256 epochTimestamp_) external onlyOwner {
        require(
            epochTimestamp_ < endTime,
            "can't extend the farm without funding"
        );
        uint256 left;

        if (rewardPerSecond == 0) {
            left = totalERC20Rewards - _totalPastRewards();
        } else {
            uint256 secondsToNewEnd = epochTimestamp_ - block.timestamp;
            uint256 rewards = rewardPerSecond.mul(secondsToNewEnd);
            left = totalERC20Rewards - _totalPastRewards() - rewards;
        }
        endTime = epochTimestamp_;

        _transferRewardToken(msg.sender, left, false);
        totalERC20Rewards -= left;
    }

    /**
        @dev Pauses the contract stoping deposits and widrawals and opens emergency widrawals that will ignore penalty and forfeit the rewards 
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
        @dev unpause the contracts
     */
    function unPause() external onlyOwner {
        _unpause();
    }

    /**
        @dev change feeCollector (the one that receives the fees) 
        this address have no control in this farm it is only used
        to send fees collected
        @param newfeeCollector_ the new fee wallet address
    */
    function changefeeCollector(address newfeeCollector_)
        external
        override
        onlyOwner
    {
        require(
            newfeeCollector_ != address(0),
            "changefeeCollector: can't be zero address"
        );
        feeCollector = newfeeCollector_;
    }

    /**
        @dev Fund the farm, increases the endTime, keep in mind that this function expect you to have aproved this ammount
        @param amount_ Amount of rewards token to fund (will be transfered from the caller's balance)
     */
    function fund(uint256 amount_) external override onlyOwner {
        // avoid precision loss only transfer what is devidable by rewardsPerSecond
        require(
            block.timestamp < endTime || startTime == endTime,
            "fund: too late, the farm is closed"
        );
        uint256 leftOver;

        if (rewardPerSecond != 0) {
            leftOver = amount_.mod(rewardPerSecond);
        }

        uint256 balanceBefore = rewardToken.balanceOf(address(this));

        rewardToken.transferFrom(
            address(msg.sender),
            address(this),
            amount_.sub(leftOver)
        );

        uint256 diff = rewardToken.balanceOf(address(this)) - balanceBefore;
        require(amount_.sub(leftOver) == diff, "Farm: detected fee on tx");
        
        endTime += rewardPerSecond > 0
            ? diff.div(rewardPerSecond)
            : type(uint256).max;

        totalERC20Rewards += diff;
    }

    /**
        @dev Add a new pool to the farm. Can only be called by the owner.
        @param multiplier_ pool multiplier
        @param lpToken_ The address of the token that will be stake in this pool
        @param depositFee_ percentage of the deposit as fee (this will apply directly when people stake on their capital )  
        @param lockPeriodInDays_ The amount of days this pool locks the stake put 0 for no lock
        @param earlyUnlockPenalty_ The percentage that will be taken as penalty for early unstake
     */

    function addPool(
        IERC20 lpToken_,
        uint256 multiplier_,
        uint256 depositFee_,
        uint256 lockPeriodInDays_,
        uint256 earlyUnlockPenalty_
    ) external override onlyOwner {
        require(
            earlyUnlockPenalty_ < 100,
            "earlyUnlockPenaltyPercentage_ should be < 100"
        );
        massUpdatePools();

        uint256 lastRewardTime = block.timestamp > startTime
            ? block.timestamp
            : startTime;
        totalMultiplier = totalMultiplier.add(multiplier_);
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken_,
                multiplier: multiplier_,
                lastRewardTime: lastRewardTime,
                accERC20PerShare: 0,
                stakedAmount: 0,
                stakeFee: depositFee_,
                lockPeriod: lockPeriodInDays_, // lock period in days
                penalty: earlyUnlockPenalty_
            })
        );
        uint256 pid = poolInfo.length-1;
        emit PoolCreated(pid, address(lpToken_));
        emit MultiplierUpdates(pid, 0, multiplier_);
    }

    /**
        @dev Update the given pool's multiplier X.
        @param poolId_ pool id (index of the pool)
        @param multiplier_ new multiplier to be assigned to this pool
     */
    function updateMultiplier(uint256 poolId_, uint256 multiplier_)
        external
        override
        onlyOwner
    {
        massUpdatePools();
        
        emit MultiplierUpdates(poolId_, poolInfo[poolId_].multiplier, multiplier_);

        totalMultiplier = totalMultiplier.sub(poolInfo[poolId_].multiplier).add(
                multiplier_
            );
        poolInfo[poolId_].multiplier = multiplier_;
    }

    /**
        @dev Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() public override {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    /**
        Update reward variables of the given pool to be up-to-date.
        @param poolPid_ pool index
     */
    function updatePool(uint256 poolPid_) public override {
        uint256 lastTime = block.timestamp < endTime
            ? block.timestamp
            : endTime;
        uint256 lastRewardTime = poolInfo[poolPid_].lastRewardTime;

        if (lastTime <= lastRewardTime) {
            return;
        }

        uint256 lpSupply = poolInfo[poolPid_].stakedAmount;
        if (lpSupply == 0 || totalMultiplier == 0) {
            poolInfo[poolPid_].lastRewardTime = lastTime;
            return;
        }

        uint256 erc20Reward = lastTime
            .sub(lastRewardTime)
            .mul(rewardPerSecond)
            .mul(poolInfo[poolPid_].multiplier)
            .div(totalMultiplier);

        poolInfo[poolPid_].accERC20PerShare = poolInfo[poolPid_]
            .accERC20PerShare
            .add(erc20Reward.mul(1e36).div(lpSupply));

        poolInfo[poolPid_].lastRewardTime = lastTime;
    }

    /**
        Deposit LP tokens to Pool for
        @param poolPid_ pool index
        @param amount_ amount to be deposited (this contract should be aproved before hand)
     */
    function stakeInPool(uint256 poolPid_, uint256 amount_)
        external
        override
        whenNotPaused
    {
        //PoolInfo storage pool = poolInfo[poolPid_];
        uint256 amount = usersInfos[poolPid_][msg.sender].amount;
        IERC20 lpToken = poolInfo[poolPid_].lpToken;
        uint256 fee = poolInfo[poolPid_].stakeFee;
        //UserInfo storage user = usersInfos[poolPid_][msg.sender];
        updatePool(poolPid_);

        if (amount > 0) {
            // claim  rewards without updating debt we update debt after updating user and pool with the new deposit
            _claimPending(poolPid_, msg.sender);
        }

        if (amount_ > 0) {
            // take deposit fee
            uint256 depositFee;
            if (fee > 0) {
                depositFee = amount_.mul(poolInfo[poolPid_].stakeFee).div(100);
                lpToken.safeTransferFrom(msg.sender, feeCollector, depositFee);
                emit PaidStakeFee(msg.sender, poolPid_, depositFee);
            }
            // transfer
            uint256 balanceBefore = lpToken.balanceOf(address(this));
            lpToken.safeTransferFrom(
                msg.sender,
                address(this),
                amount_.sub(depositFee)
            );
            uint256 netDeposit = lpToken.balanceOf(address(this)).sub(
                balanceBefore
            );
            // update pool's info
            poolInfo[poolPid_].stakedAmount += netDeposit;
            // update user's info
            amount = amount.add(netDeposit);
            uint256 length = _depositsLength;
            usersInfos[poolPid_][msg.sender].deposits.push(length);
            usersDeposits[length] = DepositInfo(
                netDeposit, //amount;
                block.timestamp //depositTime;
            );

            emit Deposit(msg.sender, poolPid_, netDeposit);
            _depositsLength = length + 1;
        }

        // user has claimed all pending reward so lets reflect that in his info
        usersInfos[poolPid_][msg.sender].rewardDebt = amount
            .mul(poolInfo[poolPid_].accERC20PerShare)
            .div(1e36);
        usersInfos[poolPid_][msg.sender].amount = amount;
    }

    /**
        unstake a deposit that is unlocked 
        @param poolPid_ pool index
        @param userDepositIndex_ deposit index in usersInfos[poolPid_][msg.sender].deposits
     */
    function withdrawUnlockedDeposit(
        uint256 poolPid_,
        uint256 userDepositIndex_
    ) external override whenNotPaused {
        uint256 amount = usersDeposits[
            usersInfos[poolPid_][msg.sender].deposits[userDepositIndex_]
        ].amount;
        require(
            usersDeposits[
                usersInfos[poolPid_][msg.sender].deposits[userDepositIndex_]
            ].depositTime +
                DAY_IN_SECONDS *
                poolInfo[poolPid_].lockPeriod <=
                block.timestamp,
            "withdraw: can't withdraw deposit before unlock time"
        );

        updatePool(poolPid_);

        // claim
        _claimPending(poolPid_, msg.sender);
        // end claim

        poolInfo[poolPid_].lpToken.safeTransfer(address(msg.sender), amount);

        emit Withdraw(msg.sender, poolPid_, amount);

        _removeDeposit(poolPid_, msg.sender, userDepositIndex_);
    }

    /**
        Withdraw without caring about rewards and lock penalty  . EMERGENCY ONLY.
     */
    function emergencyWithdraw(uint256 poolPid_) external override whenPaused {
        //UserInfo storage user = usersInfos[poolPid_][msg.sender];
        uint256 amount = usersInfos[poolPid_][msg.sender].amount;

        poolInfo[poolPid_].lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, poolPid_, amount);
        poolInfo[poolPid_].stakedAmount = poolInfo[poolPid_].stakedAmount.sub(
            amount
        );

        uint256 length = usersInfos[poolPid_][msg.sender].deposits.length;

        for (uint256 i = 0; i < length; i++) {
            delete usersDeposits[usersInfos[poolPid_][msg.sender].deposits[i]]; // refunds gas
        }

        delete usersInfos[poolPid_][msg.sender]; // refunds gas
    }

    /**
        @dev instake with a penalty 
     */
    function unstakeWithPenalty(uint256 poolPid_, uint256 userDepositIndex_)
        external
        override
        whenNotPaused
    {
        uint256 amount = usersDeposits[
            usersInfos[poolPid_][msg.sender].deposits[userDepositIndex_]
        ].amount;
        require(
            usersDeposits[
                usersInfos[poolPid_][msg.sender].deposits[userDepositIndex_]
            ].depositTime +
                DAY_IN_SECONDS *
                poolInfo[poolPid_].lockPeriod >
                block.timestamp,
            "unstakeWithPenalty: unlocked!"
        );

        updatePool(poolPid_);

        // claim pending rewards
        _claimPending(poolPid_, msg.sender);
        // end claim

        uint256 penaltyAmount = amount.mul(poolInfo[poolPid_].penalty).div(100);

        // send tokens to user
        IERC20 lpToken = poolInfo[poolPid_].lpToken;
        lpToken.safeTransfer(address(msg.sender), amount.sub(penaltyAmount));
        // send adminShare to feeCollector
        if (penaltyAmount > 0)
            lpToken.safeTransfer(feeCollector, penaltyAmount);
        // distribute LP on stakers

        _removeDeposit(poolPid_, msg.sender, userDepositIndex_);

        emit WithdrawWithPenalty(msg.sender, poolPid_, amount.sub(penaltyAmount));
        emit PaidEarlyPenalty(msg.sender, poolPid_, penaltyAmount);
    }

    /**
        @dev recover any ERC20 tokens sent by mistake or recover rewards 
        after all farms have ended and all users have unstaked
        technically can be called while farming is still active
        owner can in no way take users staked token or rewards
    */
    function recoverTokens(IERC20 tokenAddresss_, address to_)
        external
        override
        onlyOwner
    {
        // check if this _erc20 has pools and users are still staked in those pools
        uint256 userStakeLeft;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].lpToken == tokenAddresss_)
                userStakeLeft += poolInfo[i].stakedAmount;
        }

        // if
        if (tokenAddresss_ == rewardToken) {
            require(block.timestamp > endTime, "Farming is not ended yet.");
            userStakeLeft += totalPending();
        }

        // only transfer the amount not belonging to users
        uint256 amount = tokenAddresss_.balanceOf(address(this)) -
            userStakeLeft;
        if (amount > 0) tokenAddresss_.transfer(to_, amount);
    }

    /**
        Changes the rewardPerSecond reducing the rewards will make the endTime go further into the future and reduced the APY 
        increasing this will make the endTime closer and will increase APY 
        to prevent accidental ending of the farm if the rewardsPerSecond increase will put the endTime closer than a day away it will revert
        @param rewardPerSecond_ new rewards per second
     */
    function changeRewardPerSecond(uint256 rewardPerSecond_)
        external
        override
        onlyOwner
    {
        require(block.timestamp < endTime, "Too late farming ended");
        uint256 totalRewardsTillNow = _totalPastRewards();
        uint256 leftRewards = totalERC20Rewards - totalRewardsTillNow;
        uint256 newLeftBlocks = rewardPerSecond_ > 0
            ? leftRewards.div(rewardPerSecond_)
            : type(uint256).max;
        uint256 leftoverRewards = rewardPerSecond_ > 0
            ? leftRewards.mod(rewardPerSecond_)
            : 0;
        uint256 newEndBlock = rewardPerSecond_ > 0
            ? block.timestamp > startTime
                ? block.timestamp + newLeftBlocks
                : startTime + newLeftBlocks
            : type(uint256).max;

        
        if (rewardPerSecond_ > rewardPerSecond)
            require(
                newEndBlock > block.timestamp,
                "rewards are not sufficient"
            );

        massUpdatePools();

        // push this change into history
        if (block.timestamp >= startTime) {
            lastEmissionChange = block.timestamp;
            rewardsAmountBeforeLastChange = totalRewardsTillNow;
        }

        endTime = newEndBlock;
        uint256 oldRewardsPerSecond = rewardPerSecond;
        rewardPerSecond = rewardPerSecond_;
        // send any excess rewards to fee (caused by rewards % rewardperSecond != 0) to prevent precision loss
        if (leftoverRewards > 0) {
            // this is not a payout hence the 'false'
            _transferRewardToken(feeCollector, leftoverRewards, false);
            totalERC20Rewards -= leftoverRewards;
        }
        emit RewardsPerSecondChanged(rewardPerSecond , oldRewardsPerSecond);
    }

    /**
        @dev view function returns the userInfo for the given user at the given poolId
        @param poolPid_ pool index
        @param user_ user wallet address 
        
    */
    function getUserInfo(uint256 poolPid_, address user_)
        external
        view
        override
        returns (UserInfo memory)
    {
        return usersInfos[poolPid_][user_];
    }

    /** 
      @dev Number of LP pools
    */
    function poolLength() external view override returns (uint256) {
        return poolInfo.length;
    }

    /** 
        @dev View function to see a user's stake in a pool.
        @param poolId_ pool id (index)
        @param user_ user's wallet address
    */
    function totalDeposited(uint256 poolId_, address user_)
        external
        view
        override
        returns (uint256)
    {
        UserInfo storage user = usersInfos[poolId_][user_];
        return user.amount;
    }

    /**
        @dev View function to see all deposits for a user in a staking pool this iss used to display on UIs.
        @param poolId_ pool id (index)
        @param user_ user's wallet address
    */
    function getUserDeposits(uint256 poolId_, address user_)
        external
        view
        override
        returns (DepositInfo[] memory)
    {
        UserInfo storage user = usersInfos[poolId_][user_];
        DepositInfo[] memory userDeposits = new DepositInfo[](
            user.deposits.length
        );

        for (uint8 i = 0; i < user.deposits.length; i++) {
            userDeposits[i] = usersDeposits[user.deposits[i]];
        }

        return userDeposits;
    }

    /**
        View function to see pending ERC20 rewards for a user.
        @param poolId_ pool id (index)
        @param user_ user's wallet address
    */
    function pending(uint256 poolId_, address user_)
        external
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[poolId_];
        UserInfo storage user = usersInfos[poolId_][user_];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.stakedAmount;

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 lastTime = block.timestamp < endTime
                ? block.timestamp
                : endTime;
            uint256 nrOfBlocks = lastTime.sub(pool.lastRewardTime);
            uint256 erc20Reward = nrOfBlocks
                .mul(rewardPerSecond)
                .mul(pool.multiplier)
                .div(totalMultiplier);
            accERC20PerShare = accERC20PerShare.add(
                erc20Reward.mul(1e36).div(lpSupply)
            );
        }

        return user.amount.mul(accERC20PerShare).div(1e36).sub(user.rewardDebt);
    }

    /**
       @dev View function for total reward the farm has yet to pay out.
    */
    function totalPending() public view override returns (uint256) {
        if (block.timestamp <= startTime) {
            return 0;
        }
        return _totalPastRewards().sub(paidOut);
    }

    /**
        remove a deposit from memory and change the state accordingly
        @param poolPid_ pool index
        @param user_ user wallet address
        @param userDepositIndex_ user deposit index in usersInfos[poolPid_][user_].deposits
    */
    function _removeDeposit(
        uint256 poolPid_,
        address user_,
        uint256 userDepositIndex_
    ) internal {
        uint256 depositAmount = usersDeposits[
            usersInfos[poolPid_][user_].deposits[userDepositIndex_]
        ].amount;
        uint256 amount = usersInfos[poolPid_][user_].amount;

        amount = amount.sub(depositAmount);
        poolInfo[poolPid_].stakedAmount = poolInfo[poolPid_].stakedAmount.sub(
            depositAmount
        );

        delete usersDeposits[
            usersInfos[poolPid_][user_].deposits[userDepositIndex_]
        ]; // refunds gas for zeroing a non zero field

        if (amount > 0) {
            usersInfos[poolPid_][user_].rewardDebt = amount
                .mul(poolInfo[poolPid_].accERC20PerShare)
                .div(1e36);

            usersInfos[poolPid_][user_].deposits[
                userDepositIndex_
            ] = usersInfos[poolPid_][user_].deposits[
                usersInfos[poolPid_][user_].deposits.length - 1
            ];
            usersInfos[poolPid_][user_].deposits.pop();
            usersInfos[poolPid_][user_].amount = amount;
        } else {
            // if this user has no more deposits delete his entry in the mapping (refunds gas for zeroing non zero field)
            delete usersInfos[poolPid_][msg.sender];
        }
    }

    /**
        @dev claimed pending for user (in case of extending this function and using it somewhere else please remember to recalculate the rewards debt for this user)
        @param poolPid_ pool index
        @param user_ user wallet address 
     */
    function _claimPending(uint256 poolPid_, address user_) internal {
        //PoolInfo storage pool = poolInfo[poolPid_];

        uint256 amount = usersInfos[poolPid_][user_].amount;
        uint256 pendingAmount = amount
            .mul(poolInfo[poolPid_].accERC20PerShare)
            .div(1e36)
            .sub(usersInfos[poolPid_][user_].rewardDebt);
        if (pendingAmount > 0) {
            _transferRewardToken(msg.sender, pendingAmount, true);
            emit ClaimRewards(user_, poolPid_, pendingAmount);
        }
    }

    /**
        helper function for changing rewards per block
    */
    function _totalPastRewards() internal view returns (uint256) {
        if (block.timestamp < startTime) return 0;

        uint256 lastTime = block.timestamp < endTime
            ? block.timestamp
            : endTime;

        return
            rewardsAmountBeforeLastChange.add(
                rewardPerSecond.mul(lastTime - lastEmissionChange)
            );
    }

    /** 
        @dev Transfer ERC20 and update the required ERC20 to payout all rewards
        @param to_ address to send to
        @param amount_ amount to be sent 
        @param isPayout_ is this is a payout or not (prcession loss and token recovery use this too)
    */
    function _transferRewardToken(
        address to_,
        uint256 amount_,
        bool isPayout_
    ) internal {
        rewardToken.safeTransfer(to_, amount_);
        if (isPayout_) paidOut += amount_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
abstract contract CustomOwnable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner_) {
        _transferOwnership(owner_);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../data/Structs.sol";

interface IFarm {
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event WithdrawWithPenalty(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event ClaimRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event ClaimLPRewards(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event RewardsPerSecondChanged(uint256 oldRewardsPerSecond, uint256 newRewardsPerSecond);

    event PoolCreated(uint256 pid,address token);

    event MultiplierUpdates(uint256 indexed pid,uint256 oldMultiplier, uint256 newMultiplier);

    event PaidStakeFee(
        address indexed user,
        uint256 indexed poolId,
        uint256 amount
    );

    event PaidEarlyPenalty(
        address indexed user,
        uint256 indexed poolId,
        uint256 penaltyAmount
    );

    // Number of LP pools
    function poolLength() external view returns (uint256);

    function pause() external;

    function unPause() external;

    // change FeeCollector Wallet (the one that receives the fees)
    function changefeeCollector(address newFeeWallet_) external;

    // Fund the farm, increase the end block
    function fund(uint256 amount_) external;

    // create a new Pool for LP 
    function addPool(
        IERC20 lpToken_,
        uint256 multiplier_,
        uint256 depositFee_,
        uint256 lockPeriodInDays_,
        uint256 earlyUnlockPenalty_
        ) external;

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    function updateMultiplier(uint256 poolId_, uint256 allocPoint_) external;

    function totalDeposited(uint256 poolId_, address user_)
        external
        view
        returns (uint256);

    function getUserDeposits(uint256 poolId_, address user_)
        external
        view
        returns (DepositInfo[] memory);

    function pending(uint256 pid_, address user_)
        external
        view
        returns (uint256);

    function totalPending() external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 pid_) external;

    function stakeInPool(uint256 poolPid_, uint256 amount_) external;

    function withdrawUnlockedDeposit(
        uint256 poolPid_,
        uint256 userDepositIndex_
    ) external;

    function emergencyWithdraw(uint256 poolPid_) external;

    function unstakeWithPenalty(uint256 poolPid_, uint256 userDepositIndex_)
        external;

    function recoverTokens(IERC20 _erc20, address _to) external;

    function changeRewardPerSecond(uint256 _rewardPerBlock) external;

    function getUserInfo(uint256 pid_, address user_)
        external
        view
        returns (UserInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Info of each user.
struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256[] deposits; // indexes of deposits belonging to this user
}

// each user deposit is saved in an object like this
struct DepositInfo {
    uint256 amount;
    uint256 depositTime;
}

// Info of each pool.
struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 multiplier; // How many allocation points assigned to this pool
    uint256 lastRewardTime; // Last time where ERC20s distribution occurs.
    uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
    uint256 stakedAmount; // Amount of @lpToken staked in this pool
    uint256 stakeFee; // fee on staking percentage
    uint256 lockPeriod; // lock period in days
    uint256 penalty; // percentage penalty for early unstake
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}