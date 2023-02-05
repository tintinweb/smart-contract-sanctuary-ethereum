// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PLSDStaker {
    uint256 public lockingPeriod; // period users are allowed to deposit/withdraw their stake without penalty (in seconds)
    uint256 public lockedPeriod; // staking duration (in seconds)
    uint256 public emergencyUnlockFeeBps; // emergency unlock fee in percentage basis points
    uint256 public lockingCost; // cost for locking (in terms of CARN)
    uint256 public lockingStart; // start of locking period as timestamp
    uint256 public lockingEnd; // end of locking period as timestamp
    
    uint256 public plsdRewardPool; // keeps track of the plsd rewards
    uint256 public plsdPendingRewards; // keeps track of plsd contributions to the reward pool made during locking period
    uint256 public plsdRewardPoolTotal; // Total plsd reward for the last stake

    uint256 public plsbRewardPool; // keeps track of the plsb rewards
    uint256 public plsbPendingRewards; // keeps track of plsb contributions to the reward pool made during locking period
    uint256 public plsbRewardPoolTotal; // Total plsb reward for the last stake

    uint256 public asicRewardPool; // keeps track of the asic rewards
    uint256 public asicPendingRewards; // keeps track of asic contributions to the reward pool made during locking period
    uint256 public asicRewardPoolTotal; // Total asic reward for the last stake

    address public CARN; // Token used as locking cost
    address public PLSD; // Token to stake
    address public PLSB; // Reward token
    address public ASIC; // Reward token

    address public CARNSplitter; // address to send the accumulated CARN tokens for further processing

    enum State {
        LockingPeriod,
        LockedPeriod
    }

    struct Stake {
        uint256 amount;
        uint256 stakeId;
    }

    State public state; // keeps track of the current state of the contract

    mapping(address=>Stake) public stakes; // keeps track of stakes of each user
    mapping(uint256=>uint256) public stakePool; // keeps track of the available pool for a given stakeId

    uint256 public currentStakeId; // keeps track of current stake Id
    uint256 public unclaimedAmount; // keeps track of unclaimed amount from stake pool

    event NewStake(address indexed staker, uint256 indexed stakeId, uint256 amount);
    event PLSDRewardClaimed(address indexed staker, uint256 indexed stakeId, uint256 amount);
    event PLSBRewardClaimed(address indexed staker, uint256 indexed stakeId, uint256 amount);
    event ASICRewardClaimed(address indexed staker, uint256 indexed stakeId, uint256 amount);
    event RewardReset(address indexed staker, uint256 indexed stakeId);
    event EmergencyWithdraw(address indexed staker, uint256 indexed stakeId, uint256 withdrawAmount, uint256 penaltyAmount);
    event PLSDDeposited(address indexed depositor, uint256 depositAmount);
    event PLSBDeposited(address indexed depositor, uint256 depositAmount);
    event ASICDeposited(address indexed depositor, uint256 depositAmount);

    event LockedPeriodStarted(address indexed caller, uint256 id, uint256 timestamp);
    event LockingPeriodStarted(address indexed caller, uint256 id, uint256 timestamp);

    event CarnSent(address indexed caller, uint256 amount);

    constructor(uint256 _firstLockingPeriod, uint256 _lockingPeriod, uint256 _lockedPeriod, uint256 _emergencyUnlockFeeBps, uint256 _lockingCost, address _CARN, address _PLSD, address _PLSB, address _ASIC, address _CARNSplitter) {
        lockingPeriod = _lockingPeriod;
        lockedPeriod = _lockedPeriod;
        emergencyUnlockFeeBps = _emergencyUnlockFeeBps;
        lockingCost = _lockingCost;
        lockingStart = block.timestamp;
        lockingEnd = block.timestamp+_firstLockingPeriod;
        CARN = _CARN;
        PLSD = _PLSD;
        PLSB = _PLSB;
        ASIC = _ASIC;
        CARNSplitter = _CARNSplitter;
        currentStakeId = 1;
    }

    function stake(uint256 _amount) public {
        if(block.timestamp > lockingEnd && state == State.LockingPeriod) {
            // lockingPeriod ended, start lockedPeriod
            startLockedPeriod();
        } else {
            if(block.timestamp > lockingStart && state != State.LockingPeriod) {
                // lockedPeriod ended, start lockingPeriod
                startLockingPeriod();
            }

            if(stakes[msg.sender].amount == 0 && stakes[msg.sender].stakeId != currentStakeId) {
                // new staker/staker don't have any pending claims, update stakeId
                stakes[msg.sender].stakeId = currentStakeId;
            }

            require(state == State.LockingPeriod, "Can't stake during locked period");
            require(_amount>0, "Amount should be greater than zero");
            require(stakes[msg.sender].stakeId == currentStakeId, "Please claim rewards for your previous stake");

            // Transfer the locking cost to contract
            IERC20(CARN).transferFrom(msg.sender, address(this), lockingCost);

            // Transfer the stake to contract
            IERC20(PLSD).transferFrom(msg.sender, address(this), _amount);

            stakePool[currentStakeId] += _amount;
            stakes[msg.sender].amount += _amount;

            emit NewStake(msg.sender, currentStakeId, _amount);
        }
    }

    // function to trigger the locked period
    function startLockedPeriod() public {
        require(state != State.LockedPeriod, "Already in locked period");
        require(block.timestamp > lockingEnd, "Locking period not ended");

        lockingStart = block.timestamp + lockedPeriod;
        lockingEnd = lockingStart + lockingPeriod;

        // add pending rewards and unclaimed amounts to the reward pool
        plsdRewardPool += plsdPendingRewards + unclaimedAmount;
        plsdRewardPoolTotal = plsdRewardPool;
        plsdPendingRewards = 0;

        plsbRewardPool += plsbPendingRewards;
        plsbRewardPoolTotal = plsbRewardPool;
        plsbPendingRewards = 0;

        asicRewardPool += asicPendingRewards;
        asicRewardPoolTotal = asicRewardPool;
        asicPendingRewards = 0;

        // update unclaimed amounts for next stake
        unclaimedAmount = stakePool[currentStakeId];

        // update stakeId and state
        currentStakeId++;
        state = State.LockedPeriod;

        emit LockedPeriodStarted(msg.sender, currentStakeId-1, block.timestamp);
    }

    function startLockingPeriod() public {
        require(state != State.LockingPeriod, "Already in locking period");
        require(block.timestamp > lockingStart, "Locked period not ended");

        // update start and end timestamps
        lockingStart = block.timestamp;
        lockingEnd = lockingStart + lockingPeriod;

        // update state
        state = State.LockingPeriod;
        emit LockingPeriodStarted(msg.sender, currentStakeId, block.timestamp);
    }

    // function to end the stake during locked period in case of any emergency (emergency unlock fee is deducted)
    function emergencyEnd() public {
        require(state == State.LockedPeriod, "Not in locked period");

        uint256 penaltyAmount = stakes[msg.sender].amount*emergencyUnlockFeeBps/10000;
        uint256 amountToTransfer = stakes[msg.sender].amount - penaltyAmount;

        stakePool[currentStakeId-1] -= stakes[msg.sender].amount;

        plsdRewardPool += penaltyAmount;
        plsdRewardPoolTotal = plsdRewardPool;

        delete stakes[msg.sender];

        IERC20(PLSD).transfer(msg.sender, amountToTransfer);
        emit EmergencyWithdraw(msg.sender, currentStakeId-1, amountToTransfer, penaltyAmount);
    }

    // function to contribute plsd to the reward pool
    function depositPLSD(uint256 _amount) public {
        if(state == State.LockingPeriod) {
            plsdPendingRewards += _amount;
        } else {
            plsdRewardPool += _amount;
            plsdRewardPoolTotal = plsdRewardPool;
        }

        IERC20(PLSD).transferFrom(msg.sender, address(this), _amount);
        emit PLSDDeposited(msg.sender, _amount);
    }

    
    // function to contribute plsb to the reward pool
    function depositPLSB(uint256 _amount) public {
        if(state == State.LockingPeriod) {
            plsbPendingRewards += _amount;
        } else {
            plsbRewardPool += _amount;
            plsbRewardPoolTotal = plsbRewardPool;
        }

        IERC20(PLSB).transferFrom(msg.sender, address(this), _amount);
        emit PLSBDeposited(msg.sender, _amount);
    }

    // function to contribute asic to the reward pool
    function depositASIC(uint256 _amount) public {
        if(state == State.LockingPeriod) {
            asicPendingRewards += _amount;
        } else {
            asicRewardPool += _amount;
            asicRewardPoolTotal = asicRewardPool;
        }

        IERC20(ASIC).transferFrom(msg.sender, address(this), _amount);
        emit ASICDeposited(msg.sender, _amount);
    }

    // function to claim rewards once staking ends
    function claimRewards() public {
        if(block.timestamp > lockingEnd && state == State.LockingPeriod) {
            // lockingPeriod ended, start lockedPeriod
            startLockedPeriod();
        } else {
            if(block.timestamp > lockingStart && state != State.LockingPeriod) {
                // lockedPeriod ended, start lockingPeriod
                startLockingPeriod();
            }

            require(state == State.LockingPeriod, "Can't claim during locked period");
            require(stakes[msg.sender].amount > 0, "No stakes");

            if(stakes[msg.sender].stakeId == currentStakeId-1){
                // normal case - user can claim their rewards
                uint256 _plsdReward = plsdRewardPoolTotal*stakes[msg.sender].amount/stakePool[currentStakeId-1];
                uint256 _plsdAmount = stakes[msg.sender].amount + _plsdReward;
                plsdRewardPool -= _plsdReward;

                uint256 _plsbReward = plsbRewardPoolTotal*stakes[msg.sender].amount/stakePool[currentStakeId-1];
                plsbRewardPool -= _plsbReward;

                uint256 _asicReward = asicRewardPoolTotal*stakes[msg.sender].amount/stakePool[currentStakeId-1];
                asicRewardPool -= _asicReward;

                unclaimedAmount -= stakes[msg.sender].amount;
                stakes[msg.sender].amount = 0;
                stakes[msg.sender].stakeId = currentStakeId;

                IERC20(PLSD).transfer(msg.sender, _plsdAmount);
                IERC20(PLSB).transfer(msg.sender, _plsbReward);
                IERC20(ASIC).transfer(msg.sender, _asicReward);

                emit PLSDRewardClaimed(msg.sender, currentStakeId-1, _plsdAmount);
                emit PLSBRewardClaimed(msg.sender, currentStakeId-1, _plsbReward);
                emit ASICRewardClaimed(msg.sender, currentStakeId-1, _asicReward);
            } else if(stakes[msg.sender].stakeId == currentStakeId) {
                revert("Staking for this id is not finished yet");
            } else {
                // Invalid stakeId - reset user's amount and stakeId
                stakes[msg.sender].amount = 0;
                stakes[msg.sender].stakeId = currentStakeId;

                emit RewardReset(msg.sender, currentStakeId);
            }
        }
    }

    // function to send the accumulated CARN tokens to the CARNSplitter for processing further
    function sendOutCarn() public {
        uint256 _amount = IERC20(CARN).balanceOf(address(this));
        require(_amount>0, "Nothing to send");
        IERC20(CARN).transfer(CARNSplitter, _amount);
        emit CarnSent(msg.sender, _amount);
    }
}