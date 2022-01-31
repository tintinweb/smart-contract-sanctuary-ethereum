// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    @author humanshield85  
*/

import "./utils/SafeERC20.sol";
import "./interfaces/IFarm.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
    Farm distribute rewards on stake pools 
    every pool can have its own lock period 
    lock period can not be changed after a pool creation (to prevent owner from taking users hostages users know before hand the period and that period can not change)
    a penalty can be set for early unstaking penalty percentage is set at pool creation
    penalty can be distributed on stakers and also send to feeWallet ratio is adjustable at pool creation
 */

contract CorsacFarm is Ownable, Pausable, IFarm {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant DAY_IN_SECONDS = 24 * 60 * 60;

    // Address of the ERC20 Token contract. 
    IERC20 public CORSACv2ERC20;
    // total amount of ERC20 rewards that this contract will distributed from start to endBlock
    uint256 public totalERC20Rewards;
    // The total amount of ERC20 that's paid out as reward.
    uint256 public paidOut;
    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock;

    // block where the last rewardPerBlock has changed
    uint256 public lastEmissionChange;
    // all pending rewards before from last block rewards change
    uint256 public rewardsAmountBeforeLastChange;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // userInfo
    // index => userDeposit info
    mapping(uint256 => DepositInfo) public usersDeposits;
    uint256 depositsLength;
    // Info of each user that stakes LP tokens.
    // poolId => user => userInfoId's
    mapping(uint256 => mapping(address => UserInfo)) usersInfos;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The block number when farming starts.
    uint256 public startBlock;
    // The block number when farming ends.
    uint256 public endBlock;

    //fee wallet's address
    address public feeWallet;

    // used to track if the farm is initialized
    bool private init;

    // in case of emergency users will be able to unstake all their tokens
    // ignoring penalties and forfiting any pending rewards
    bool public inEmergency;

    constructor(
        IERC20 _erc20,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        address _feeWalletAddr
    ) {
        CORSACv2ERC20 = _erc20;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        lastEmissionChange = _startBlock;
        endBlock = _startBlock;
        feeWallet = _feeWalletAddr;

        init =
            _erc20 != IERC20(address(0)) &&
            endBlock != 0 &&
            _startBlock != 0;
    }

    modifier onlyAfterInit() {
        require(init, "CorsacFarm: init the farm first");
        _;
    }

    modifier onlyInEmergency() {
        require(inEmergency, "CorsacFarm: only in emergency");
        _;
    }

    modifier onlyNotInEmergency() {
        require(!inEmergency, "CorsacFarm: only when not in emergency");
        _;
    }

    /**
        @dev Initializes the farm this is used to initialize the farm in case it was not initialized on deployment can only be initialized once
        @param rewardToken_ the address of the erc20 token that will be used as rewards 
        @param rewardPerBlock_ The amount of tokenReward per block 
        @param startBlock_  The starting block (nust be in the future)
        @param feeWalletAddr_ The wallet that collects the fees (prenalty fees )
     */
    function initializeFarm(
        IERC20 rewardToken_,
        uint256 rewardPerBlock_,
        uint256 startBlock_,
        address feeWalletAddr_
    ) external override onlyOwner {
        require(!init, "CorsacFarm: Already initialized");

        CORSACv2ERC20 = rewardToken_;
        rewardPerBlock = rewardPerBlock_;
        startBlock = startBlock_;
        lastEmissionChange = startBlock_;
        endBlock = startBlock_;
        feeWallet = feeWalletAddr_;

        init =
            rewardToken_ != IERC20(address(0)) &&
            endBlock != 0 &&
            startBlock_ != 0;
    }

    /**
        @dev Pauses the contract stoping deposits and widrawals 
     */
    function pause() external override  onlyOwner {
        _pause();
    }

    /**
        @dev unpause the contracts
     */
    function unPause() external override onlyOwner {
        _unpause();
    }

    /**
        @dev change feeWallet (the one that receives the fees)
        @param newFeeWallet_ the new fee wallet address
    */
    function changeFeeWallet(address newFeeWallet_) external override onlyOwner {
        require(
            newFeeWallet_ != address(0),
            "changeFeeWallet: can't be zero address"
        );
        feeWallet = newFeeWallet_;
    }

    /**
        @dev Fund the farm, increase the end block m keep in mind that this function expect you to have aproved this ammount
        @param amount_ Amount of rewards token to fund (will be transfered from the caller's balance)
     */
    function fund(uint256 amount_) external override onlyOwner onlyAfterInit {
        require(
            block.number < endBlock || startBlock == endBlock,
            "fund: too late, the farm is closed"
        );
        // avoid precision loss only transfer what is devidable by the number of blocks
        uint256 leftOver = amount_.mod(rewardPerBlock);

        uint256 balanceBefore = CORSACv2ERC20.balanceOf(address(this));

        CORSACv2ERC20.transferFrom(
            address(msg.sender),
            address(this),
            amount_.sub(leftOver)
        );

        uint256 diff = CORSACv2ERC20.balanceOf(address(this)) - balanceBefore;
        require(amount_.sub(leftOver) == diff, "Farm: detected fee on tx");

        endBlock += diff.div(rewardPerBlock);
        totalERC20Rewards += diff;
    }

    /**
        @dev Add a new pool to the farm. Can only be called by the owner.
        @param allocPoint_ allocation points for this pool (allocation points will decide the amount of rewards per block assigned to this pool rewardsForThisPool = rewardsPerBlock*allocationPoints/totalAllocationPoints)
        @param lpToken_ The address of the token that will be stake in this pool 
        @param lockPeriodInDays_ The amount of days this pool locks the stake put 0 for no lock
        @param earlyUnlockPenalty_ The percentage that will be taken as penalty for early unstake
        @param penaltyStakers_ The percentage of the penalty amount that will be distributed on all stakers in this pool (if this is 70 it means 70% of the penalty will be redistributed and 30% will be sent to feeWallet)
     */

    function addPool(
        uint256 allocPoint_,
        IERC20 lpToken_,
        uint256 lockPeriodInDays_,
        uint256 earlyUnlockPenalty_,
        uint256 penaltyStakers_
    ) external override onlyOwner onlyAfterInit {
        require(earlyUnlockPenalty_ < 100,"earlyUnlockPenaltyPercentage_ should be < 100");
        require(penaltyStakers_ <= 100,"panalty distribution !=100");
        massUpdatePools();

        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(allocPoint_);
        poolInfo.push(
            PoolInfo({
                lpToken: lpToken_,
                allocPoint: allocPoint_,
                lastRewardBlock: lastRewardBlock,
                accERC20PerShare: 0,
                stakedAmount: 0,
                lockPeriod: lockPeriodInDays_, // lock period in days
                penalty: earlyUnlockPenalty_, 
                penaltyStakers: penaltyStakers_, 
                accLPPerShare: 0, 
                totalLPRewards: 0,
                lpRewardsClaimed: 0
            })
        );
    }

    /**
        @dev Update the given pool's ERC20 allocation point.
        @param poolId_ pool id (index of the pool)
        @param allocPoint_ new allocation points to be assigned to this pool
     */
    function updateAllocationPoints(
        uint256 poolId_,
        uint256 allocPoint_
    ) external override onlyOwner onlyAfterInit {
        massUpdatePools();

        totalAllocPoint = totalAllocPoint.sub(poolInfo[poolId_].allocPoint).add(allocPoint_);
        poolInfo[poolId_].allocPoint = allocPoint_;
    }

    /**
        @dev Update reward variables for all pools. Be careful of gas spending!
     */
    function massUpdatePools() override public {
        for (uint256 pid = 0; pid < poolInfo.length; ++pid) {
            updatePool(pid);
        }
    }

    /**
        Update reward variables of the given pool to be up-to-date.
        @param poolPid_ pool index
     */
    function updatePool(uint256 poolPid_) override public {
        PoolInfo storage pool = poolInfo[poolPid_];
        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;

        if (lastBlock <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.stakedAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = lastBlock;
            return;
        }

        uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
        uint256 erc20Reward = nrOfBlocks
            .mul(rewardPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);

        pool.accERC20PerShare = pool.accERC20PerShare.add(
            erc20Reward.mul(1e36).div(lpSupply)
        );
        pool.lastRewardBlock = lastBlock;
    }

    /**
        Deposit LP tokens to Pool for
        @param poolPid_ pool index
        @param amount_ amount to be deposited (this contract should be aproved before hand)
     */
    function stakeInPool(uint256 poolPid_, uint256 amount_)
        external
        override 
        onlyAfterInit
        whenNotPaused
        onlyNotInEmergency
    {
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][msg.sender];
        updatePool(poolPid_);

        if (user.amount > 0) {
            // claim  rewards without updating debt we update debt after updating user and pool with the new deposit
            _claimPending(poolPid_, msg.sender);
        }

        if (amount_ > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(msg.sender, address(this), amount_);
            uint256 netDeposit = pool.lpToken.balanceOf(address(this)).sub(
                balanceBefore
            );
            // update pool's info
            pool.stakedAmount += netDeposit;
            // update user's info
            user.amount = user.amount.add(netDeposit);

            user.deposits.push(depositsLength);
            usersDeposits[depositsLength] = DepositInfo(
                netDeposit, //amount;
                block.timestamp, //depositTime;
                block.timestamp + DAY_IN_SECONDS * pool.lockPeriod //unlockTime;
            );

            emit Deposit(msg.sender, poolPid_, netDeposit);

            depositsLength++;
        }

        // user has claimed all pending reward so lets reflect that in his info
        user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
        user.lpRewardsDebt = user.amount.mul(pool.accLPPerShare).div(1e36);
    }

    /**
        unstake a deposit that is unlocked 
        @param poolPid_ pool index
        @param userDepositIndex_ deposit index in usersInfos[poolPid_][msg.sender].deposits
     */
    function withdrawUnlockedDeposit(
        uint256 poolPid_,
        uint256 userDepositIndex_
    ) external onlyNotInEmergency whenNotPaused override {
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][msg.sender];
        DepositInfo storage deposit = usersDeposits[
            user.deposits[userDepositIndex_]
        ];

        require(
            deposit.unlockTime <= block.timestamp,
            "withdraw: can't withdraw deposit before unlock time"
        );

        updatePool(poolPid_);

        // claim
        _claimPending(poolPid_, msg.sender);
        // end claim

        pool.lpToken.safeTransfer(
            address(msg.sender),
            deposit.amount
        );

        emit Withdraw(msg.sender, poolPid_, deposit.amount);

        _removeDeposit(poolPid_, msg.sender, userDepositIndex_);
    }

    /**
        Withdraw without caring about rewards and lock penalty  . EMERGENCY ONLY.
     */ 
    function emergencyWithdraw(uint256 poolPid_) external override onlyInEmergency {
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][msg.sender];

        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, poolPid_, user.amount);
        pool.stakedAmount = pool.stakedAmount.sub(user.amount);

        for (uint256 i = 0; i < user.deposits.length; i++) {
            delete usersDeposits[user.deposits[i]]; // refunds gas
        }

        delete usersInfos[poolPid_][msg.sender]; // refunds gas
    }

    /**
        @dev instake with a penalty 
     */
    function unstakeWithPenalty(
        uint256 poolPid_,
        uint256 userDepositIndex_
    ) external override onlyNotInEmergency whenNotPaused{
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][msg.sender];
        DepositInfo storage deposit = usersDeposits[user.deposits[userDepositIndex_]];

        require(deposit.unlockTime > block.timestamp,"unstakeWithPenalty: unlocked!");

        updatePool(poolPid_);

        // claim pending rewards
        _claimPending(poolPid_, msg.sender);
        // end claim

        uint256 penaltyAmount = deposit.amount.mul(pool.penalty).div(100);
        uint256 stakersShare = penaltyAmount.mul(pool.penaltyStakers).div(100);
        uint256 adminFeeShare = penaltyAmount.sub(stakersShare); 
        // send tokens to user
        pool.lpToken.safeTransfer(address(msg.sender),deposit.amount.sub(penaltyAmount));
        // send adminShare to feeWallet
        if(adminFeeShare > 0)
            pool.lpToken.safeTransfer(feeWallet, adminFeeShare);
        // distribute LP on stakers

        emit WithdrawWithPenalty(msg.sender, poolPid_, deposit.amount);
        _removeDeposit(poolPid_, msg.sender, userDepositIndex_);

        if(stakersShare > 0)
            _distributeLPPenalty(poolPid_, stakersShare);
    }

    /**
        @dev recover any ERC20 tokens sent by mistake or recover rewards 
        after all farms have ended and all users have unstaked
        technically can be called while farming is still active
        owner can in no way take users staked token or rewards
    */
    function recoverTokens(IERC20 erc20_, address to_) external override onlyOwner {
        // check if this _erc20 has pools and users are still staked in those pools
        uint256 userStakeLeft;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].lpToken == erc20_)
                userStakeLeft += poolInfo[i].stakedAmount;
        }

        // if
        if (erc20_ == CORSACv2ERC20) {
            require(block.number > endBlock, "Farming is not ended yet.");
            userStakeLeft += totalPending();
        }

        // only transfer the amount not belonging to users
        uint256 amount = erc20_.balanceOf(address(this)) - userStakeLeft;
        if (amount > 0) erc20_.transfer(to_, amount);
    }

    /**
        @dev recover anything that is left after everyone unstaked
        @param erc20_ the erc20 to be transfered 
        @param to_ the address to receive this token
     */
    function recoverAll(IERC20 erc20_, address to_) external override onlyOwner {
        // check if this _erc20 has pools and users are still staked in those pools
        uint256 userStakeLeft;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            userStakeLeft += poolInfo[i].stakedAmount;
        }

        if(userStakeLeft == 0)
            erc20_.safeTransfer(to_, erc20_.balanceOf(address(this)));
    }

    /**
        @dev sets emergency 
        if emergency no depoist or unsatke or claim is allowed 
        emergency widrawal is allowed but it will ignore lock and rewards
     */
    function setInEmergency(bool isInEmergency_) external override onlyOwner {
        inEmergency = isInEmergency_;
    }

    /**
        Changes the rewardPerBlock reducing the rewards will make the endBlock go further into the future and reduced the APY 
        increasing this will make the endBlock closer and will increase APY 
        to prevent accidental ending of the farm if the rewardsPerBlock increase will put the end block closer than a day away it will revert
        @param _rewardPerBlock new rewards per block
     */
    function changeRewardPerBlock(uint256 _rewardPerBlock)
        external
        onlyOwner
        onlyAfterInit
        override 
    {
        require(
            block.number < endBlock,
            "changeRewardPerBlock: Too late farming ended"
        );
        uint256 totalRewardsTillNow = _totalPastRewards();
        uint256 leftRewards = totalERC20Rewards - totalRewardsTillNow;
        uint256 newLeftBlocks = leftRewards.div(_rewardPerBlock);
        uint256 leftoverRewards = leftRewards.mod(_rewardPerBlock);
        uint256 newEndBlock = block.number > startBlock
            ? block.number + newLeftBlocks
            : startBlock + newLeftBlocks;

        if (_rewardPerBlock > rewardPerBlock)
            // 21600 blocks should be roughly 24 hours
            require(
                newEndBlock > block.number + 21600,
                "Please fund the contract before increasing the rewards per block"
            );

        massUpdatePools();

        // push this change into history
        if (block.number >= startBlock) {
            lastEmissionChange = block.number;
            rewardsAmountBeforeLastChange = totalRewardsTillNow;
        }

        endBlock = newEndBlock;
        rewardPerBlock = _rewardPerBlock;
        // send any excess rewards to fee (caused by rewards % rewardperblock != 0)
        if (leftoverRewards > 0) {
            // this is not a payout hence the 'false'
            _transferRewardToken(feeWallet, leftoverRewards, false);
            totalERC20Rewards -= leftoverRewards;
        }
    }

    /**
        @dev view function returns the userInfo for the given user at the given poolId
        @param poolPid_ pool index
        @param user_ user wallet address 
        
    */
    function getUserInfo(uint256 poolPid_, address user_) external override view returns(UserInfo memory){
        return usersInfos[poolPid_][user_];
    }

    /** 
      @dev Number of LP pools
    */
    function poolLength() external override view returns (uint256) {
        return poolInfo.length;
    }

    /** 
        @dev View function to see a user's stake in a pool.
        @param poolId_ pool id (index)
        @param user_ user's wallet address
    */
    function totalDeposited(
        uint256 poolId_,
        address user_
    ) external override view returns (uint256) {
        UserInfo storage user = usersInfos[poolId_][user_];
        return user.amount;
    }

    /**
        @dev View function to see all deposits for a user in a staking pool this iss used to display on UIs.
        @param poolId_ pool id (index)
        @param user_ user's wallet address
    */
    function getUserDeposits(
        uint256 poolId_,
        address user_
    ) external override view returns (DepositInfo[] memory) {

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
    function pending(
        uint256 poolId_,
        address user_
    ) external override view returns (uint256) {
        PoolInfo storage pool = poolInfo[poolId_];
        UserInfo storage user = usersInfos[poolId_][user_];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.stakedAmount;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 lastBlock = block.number < endBlock
                ? block.number
                : endBlock;
            uint256 nrOfBlocks = lastBlock.sub(pool.lastRewardBlock);
            uint256 erc20Reward = nrOfBlocks
                .mul(rewardPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accERC20PerShare = accERC20PerShare.add(
                erc20Reward.mul(1e36).div(lpSupply)
            );
        }

        return user.amount.mul(accERC20PerShare).div(1e36).sub(user.rewardDebt);
    }

    /**
        @dev View function to see pending LP rewards for a user (rewards coming from early unstake).
        @param poolPid_ pool id (index)
        @param user_ user's wallet address
    */    
    function pendingInLPRewards(
        uint256 poolPid_,
        address user_
    ) external override view returns (uint256) {
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][user_];
        return
            user.amount.mul(pool.accLPPerShare).div(1e36).sub(
                user.lpRewardsDebt
            );
    }

    /**
        @dev View function for total reward the farm has yet to pay out.
    */
    function totalPending() public override view returns (uint256) {
        if (block.number <= startBlock) {
            return 0;
        }
        return _totalPastRewards().sub(paidOut);
    }

    /** 
        @dev View function for total reward the farm has yet to pay out.
    */
    function totalPendingInLP(uint256 poolPid_) public view override returns (uint256) {
        PoolInfo storage pool = poolInfo[poolPid_];
        return pool.totalLPRewards.sub(pool.lpRewardsClaimed);
    }


    /**
        @dev distribute amount on the pool (used to distribute early unstake )
        @param poolPid_ poolIndex where LP penalty is going to be distributed 
        @param amount_ amount of lp token to be redistributed 
     */
    function _distributeLPPenalty(uint256 poolPid_, uint256 amount_) internal {
        PoolInfo storage pool = poolInfo[poolPid_];
        // if there are no stakers in the pool the penalty is sent to the feeWallet instead
        if (pool.stakedAmount > 0) {
            pool.accLPPerShare = pool.accLPPerShare.add(
                amount_.mul(1e36).div(pool.stakedAmount)
            );
            pool.totalLPRewards = pool.totalLPRewards.add(amount_);
        } else pool.lpToken.safeTransfer(feeWallet, amount_);
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
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][user_];
        DepositInfo storage deposit = usersDeposits[
            user.deposits[userDepositIndex_]
        ];

        user.amount = user.amount.sub(deposit.amount);
        pool.stakedAmount = pool.stakedAmount.sub(deposit.amount);

        delete usersDeposits[user.deposits[userDepositIndex_]]; // refunds gas for zeroing a non zero field

        if (user.amount > 0) {
            user.rewardDebt = user.amount.mul(pool.accERC20PerShare).div(1e36);
            user.lpRewardsDebt = user.amount.mul(pool.accLPPerShare).div(1e36);
            user.deposits[userDepositIndex_] = user.deposits[
                user.deposits.length - 1
            ];
            user.deposits.pop();
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
    function _claimPending(
        uint256 poolPid_,
        address user_
    ) internal {
        PoolInfo storage pool = poolInfo[poolPid_];
        UserInfo storage user = usersInfos[poolPid_][user_];

        uint256 pendingAmount = user
            .amount
            .mul(pool.accERC20PerShare)
            .div(1e36)
            .sub(user.rewardDebt);

        _transferRewardToken(msg.sender, pendingAmount, true);
        // claim LP rewards
        pendingAmount = user.amount.mul(pool.accLPPerShare).div(1e36).sub(
            user.lpRewardsDebt
        );
        pool.lpToken.safeTransfer(msg.sender, pendingAmount);
        pool.lpRewardsClaimed = pool.lpRewardsClaimed.add(pendingAmount);
    }

    /**
        helper function for changing rewards per block
    */
    function _totalPastRewards() internal view returns (uint256) {
        if (block.number < startBlock) return 0;

        uint256 lastBlock = block.number < endBlock ? block.number : endBlock;
        return
            rewardsAmountBeforeLastChange.add(
                rewardPerBlock.mul(lastBlock - lastEmissionChange)
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
        CORSACv2ERC20.safeTransfer(to_, amount_);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../data/Structs.sol";

interface IFarm {

    event Deposit(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed amount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed amount
    );

    event WithdrawWithPenalty(
        address indexed user,
        uint256 indexed pid,
        uint256 indexed amount
    );

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    
   // Number of LP pools
    function poolLength() external view returns (uint256);

    function initializeFarm(
        IERC20 rewardToken_,
        uint256 rewardPerBlock_,
        uint256 startBlock_,
        address feeWalletAddr_
    ) external;

    function pause() external;

    function unPause() external;

    // change feeWallet (the one that receives the fees)
    function changeFeeWallet(address newFeeWallet_) external;

    // Fund the farm, increase the end block
    function fund(uint256 amount_) external;

    // Add a new lp to the pool. Can only be called by the owner.
    function addPool(
        uint256 allocPoint_,
        IERC20 lpToken_,
        uint256 lockPeriodInDays_,
        uint256 earlyUnlockPenalty_,
        uint256 penaltyStakers_
    ) external;

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    function updateAllocationPoints(uint256 poolId_, uint256 allocPoint_) external;

    function totalDeposited(uint256 poolId_, address user_) external view returns (uint256);

    function getUserDeposits(uint256 poolId_,address user_) external view returns (DepositInfo[] memory);

    function pending(uint256 pid_, address user_) external view returns (uint256);

    function pendingInLPRewards(uint256 poolPid_,address user_) external view returns (uint256);

    function totalPending() external view returns (uint256);

    function totalPendingInLP(uint256 poolPid_) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 pid_) external;

    function stakeInPool(uint256 poolPid_, uint256 amount_) external;

    function withdrawUnlockedDeposit(uint256 poolPid_,uint256 userDepositIndex_) external;

    function emergencyWithdraw(uint256 poolPid_) external;

    function unstakeWithPenalty(uint256 poolPid_,uint256 userDepositIndex_) external;

    function recoverTokens(IERC20 _erc20, address _to) external ;

    function setInEmergency(bool isInEmergency_) external;

    function changeRewardPerBlock(uint256 _rewardPerBlock) external;

    function getUserInfo(uint256 pid_, address user_) external view returns(UserInfo memory);

    function recoverAll(IERC20 erc20_, address to_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Info of each user.
struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
    uint256 lpRewardsDebt;
    uint256[] deposits; // indexes of deposits belonging to this user
}

// each user deposit is saved in an object like this
struct DepositInfo {
    uint256 amount;
    uint256 depositTime;
    uint256 unlockTime;
}

    // Info of each pool.
struct PoolInfo {
    IERC20 lpToken; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
    uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
    uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
    uint256 stakedAmount; // Amount of @lpToken staked in this pool
    uint256 lockPeriod; // lock period in days
    uint256 penalty; // percentage penalty for early unstake
    uint256 penaltyStakers; // percentage of the penalty that will be re-distributed to stakers 
    uint256 accLPPerShare; // accumulated LP rewardss per share (from penalties)
    uint256 totalLPRewards; 
    uint256 lpRewardsClaimed;
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