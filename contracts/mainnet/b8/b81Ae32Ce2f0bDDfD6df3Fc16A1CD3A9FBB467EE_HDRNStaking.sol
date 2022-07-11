// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IHedron {
    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

interface ISwap {
    function convertEthToHedronDistribute() external returns (uint256);

    function convertEthToHedronBurn() external returns (uint256);
}

contract HDRNStaking is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    ISwap internal swap;
    uint256 internal LAUNCH_TIME = block.timestamp; // The time at which this staking contract launch on blockchain
    IHedron internal hdrnToken;
    uint256 public totalHedronStaked;
    uint256 public accHedronRewardRate;
    uint256 public totalRewardTobeDistributed;
    uint256 public totalHedronBurned;
    uint256 public stakingPeriod = 3 hours; // 3 hours for testing then it will be changed to 369 days

    mapping(uint256 => StakeDepositData) public stakers;
    mapping(address => StakeDepositData[]) public stakes;
    mapping(uint256 => uint256) public dayToRatioMapping;

    struct StakeDepositData {
        uint256 stakeId;
        address wallet;
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
        uint256 claimedRewards;
        uint256 rewardDebt;
        uint256 unstakedStatus;
        bool activeStaked;
    }

    StakeDepositData[] public stakersData;

    //Initialize the contract and set the Hedron token address
    constructor(address _hdrnToken, address _swapContractAddress) {
        require(
            _hdrnToken != address(0),
            "Hedron Token address cannot be zero"
        );
        require(
            _swapContractAddress != address(0),
            "Swap Token address cannot be zero"
        );
        hdrnToken = IHedron(_hdrnToken); // Hedron token address.
        swap = ISwap(_swapContractAddress);
    }

    receive() external payable {}

    event stakeAdded(
        uint256 stakeId,
        address wallet,
        uint256 amount,
        uint256 startDate,
        uint256 endDate
    );
    event stakeRemoved(
        uint256 stakeId,
        address wallet,
        uint256 totalAmountClaimed
    );
    event claimedReward(uint256 stakeId, address wallet, uint256 amountClaimed);
    event emergencyEndStaked(
        uint256 stakeId,
        address wallet,
        uint256 amountClaimed
    );
    event recompounded(
        uint256 stakeId,
        address wallet,
        uint256 amountRecompound
    );

    //Modifier to check if msg.sender has an active stake
    modifier hasStaked(uint256 stakeId) {
        require(stakers[stakeId].activeStaked, "Stake is not active");
        _;
    }

    /* ======== USER FUNCTIONS ======== */

    /*
     *@notice To stake hedron
     *@param amount uint256, Amount of hedron in 9 decimal(GWEI)
     *@return uint(newStakeId)
     */
    function stake(uint256 amount) external nonReentrant returns (uint256) {
        require(amount > 0, "Amount should be greater than 0");
        require(
            IHedron(hdrnToken).allowance(msg.sender, address(this)) >= amount,
            "No allowance. Please grant hedron allowance"
        );
        require(
            IHedron(hdrnToken).balanceOf(msg.sender) >= amount,
            "Cannot stake more than the balance"
        );

        IHedron(hdrnToken).transferFrom(msg.sender, address(this), amount);

        uint256 newStakeId = stakersData.length;
        stakers[newStakeId] = StakeDepositData({
            stakeId: newStakeId,
            wallet: msg.sender,
            amount: amount,
            startDate: block.timestamp,
            endDate: block.timestamp + stakingPeriod,
            claimedRewards: 0,
            rewardDebt: amount.mul(accHedronRewardRate).div(1e9),
            unstakedStatus: 0, //0 -> default, 1 -> Unstaked, 2 -> Emergency end stake
            activeStaked: true
        });

        stakes[msg.sender].push(stakers[newStakeId]);
        stakersData.push(stakers[newStakeId]);

        assert(stakersData[newStakeId].wallet == msg.sender);
        totalHedronStaked = totalHedronStaked.add(amount);

        emit stakeAdded(
            newStakeId,
            msg.sender,
            amount,
            stakersData[newStakeId].startDate,
            stakersData[newStakeId].endDate
        );

        return newStakeId;
    }

    /*
     *@notice To unstake hedron once staking period is completed
     *@param stakeId uint256, Stake Id
     */
    function unstake(uint256 stakeId) external nonReentrant hasStaked(stakeId) {
        require(msg.sender == stakers[stakeId].wallet, "Wrong wallet address");
        require(
            hasCompletedStakingPeriod(stakeId),
            "Staking period is not over"
        );

        uint256 reward = calculateRewards(stakeId);
        uint256 total_amount = stakers[stakeId].amount.add(reward);

        stakers[stakeId].activeStaked = false;
        stakers[stakeId].unstakedStatus = 1;
        stakersData[stakeId].activeStaked = false;
        stakersData[stakeId].unstakedStatus = 1;

        totalHedronStaked = totalHedronStaked.sub(stakers[stakeId].amount);
        totalRewardTobeDistributed = totalRewardTobeDistributed.sub(reward);

        IHedron(hdrnToken).transfer(stakers[stakeId].wallet, total_amount);
        emit stakeRemoved(stakeId, stakers[stakeId].wallet, total_amount);
    }

    /*
     *@notice To end the stake before the staking period is over. User will have to pay 50% of the staked  amount as penalty
     *@param stakeId uint256, Stake Id
     */
    function emergencyEndStake(uint256 stakeId)
        external
        nonReentrant
        hasStaked(stakeId)
    {
        require(msg.sender == stakers[stakeId].wallet, "Wrong wallet address");
        require(
            !hasCompletedStakingPeriod(stakeId),
            "Staking period is over cannot ESS now"
        );

        uint256 reward = calculateRewards(stakeId);
        uint256 rewardOfESS = stakers[stakeId].amount.div(2);
        uint256 total_amount = (rewardOfESS).add(reward);

        stakers[stakeId].activeStaked = false;
        stakers[stakeId].unstakedStatus = 2;
        stakersData[stakeId].activeStaked = false;
        stakersData[stakeId].unstakedStatus = 2;

        if (totalActiveStakes() != 0) {
            accHedronRewardRate = accHedronRewardRate.add(
                (rewardOfESS.mul(1e9)).div(totalActiveStakes())
            );
            totalRewardTobeDistributed = totalRewardTobeDistributed
                .add(rewardOfESS)
                .sub(reward);
        } else {
            totalRewardTobeDistributed = totalRewardTobeDistributed.sub(reward);
        }

        dayToRatioMapping[currentDay()] = accHedronRewardRate;
        totalHedronStaked = totalHedronStaked.sub(stakers[stakeId].amount);

        IHedron(hdrnToken).transfer(stakers[stakeId].wallet, total_amount);
        emit emergencyEndStaked(stakeId, stakers[stakeId].wallet, total_amount);
    }

    /*
     *@notice To fetch the reward from HSIM FeeCollector contract and convert them to equivalent hedron using Uniwap V3 protocol
     */
    function fetchRewards() external {
        uint256 hedronReceived = swap.convertEthToHedronDistribute();

        totalRewardTobeDistributed = totalRewardTobeDistributed.add(
            hedronReceived
        );
        accHedronRewardRate = accHedronRewardRate.add(
            hedronReceived.mul(1e9).div(totalActiveStakes())
        );
        dayToRatioMapping[currentDay()] = accHedronRewardRate;
    }

    /*
     *@notice To fetch the reward from HSIM FeeCollector contract and convert them to equivalent hedron using Uniwap V3 protocol and burn Hedron to zero address
     */
    function BuyAndBurn() external {
        uint256 hedronBurn = swap.convertEthToHedronBurn();

        totalHedronBurned = totalHedronBurned.add(hedronBurn);
    }

    /*
     *@notice To claim the reward. User can claim reward at any point of time before unstake or emergency end stake
     *@param stakeId uint256, Stake Id
     */
    function claimReward(uint256 stakeId)
        public
        nonReentrant
        hasStaked(stakeId)
    {
        uint256 reward = calculateRewards(stakeId);
        require(reward > 0, "No reward available to claim");

        stakers[stakeId].claimedRewards = stakers[stakeId].claimedRewards.add(
            reward
        );
        stakers[stakeId].rewardDebt = stakers[stakeId].rewardDebt.add(reward);
        totalRewardTobeDistributed = totalRewardTobeDistributed.sub(reward);

        IHedron(hdrnToken).transfer(stakers[stakeId].wallet, reward);
        emit claimedReward(stakeId, stakers[stakeId].wallet, reward);
    }

    /*
     *@notice To re-invest the reward in the current stake without resetting the staking period. User can compound reward at any point of time before unstake or emergency end stake
     *@param stakeId uint256, Stake Id
     */
    function CompoundReward(uint256 stakeId) external hasStaked(stakeId) {
        uint256 reward = calculateRewards(stakeId);
        require(reward > 0, "No reward available to compound");
        stakers[stakeId].claimedRewards = stakers[stakeId].claimedRewards.add(
            reward
        );
        stakers[stakeId].amount = stakers[stakeId].amount.add(reward);
        stakersData[stakeId].amount = stakersData[stakeId].amount.add(reward);
        totalHedronStaked = totalHedronStaked.add(reward);
        totalRewardTobeDistributed = totalRewardTobeDistributed.sub(reward);

        uint256 newDebt = calculateRewards(stakeId);
        stakers[stakeId].rewardDebt = stakers[stakeId].rewardDebt.add(newDebt);

        emit recompounded(stakeId, stakers[stakeId].wallet, reward);
    }

    /*
     *@notice To update staking period.
     *@param newStakingPeriodInDays uint256, No. of days
     */
    function updateStakingPeriod(uint256 newStakingPeriodInDays)
        external
        onlyOwner
    {
        require(
            newStakingPeriodInDays != stakingPeriod,
            "Add a different staking period"
        );

        stakingPeriod = newStakingPeriodInDays * 86400; //test this implementation
    }

    /*
     *@notice To update staking period.
     *@param newStakingPeriodInDays uint256, No. of days
     */

    function updateSwapAddress(address _newSwapAddress) external onlyOwner {
        require(_newSwapAddress != address(0), "Cannot add zero address");
        swap = ISwap(_newSwapAddress);
    }

    /*
     *@notice To get total active staked hedron amount at current time
     *@return uint(totalStakes)
     */
    function totalActiveStakes() public view returns (uint256) {
        uint256 totalStakes;

        for (uint256 i = 0; i < stakersData.length; i++) {
            if (stakersData[i].activeStaked) {
                if (!hasCompletedStakingPeriod(stakersData[i].stakeId)) {
                    totalStakes = totalStakes.add(stakersData[i].amount);
                }
            }
        }

        return totalStakes;
    }

    /*
     *@notice To get the current Day of the contract
     *@return uint256(currentDay)
     */
    function currentDay() public view returns (uint256) {
        return _currentDay();
    }

    /*
     *@notice To get all the stakes stake by a given wallet address
     *@param wallet address, Wallet address
     *@return StakeDepositData[]
     */
    function getStakes(address wallet)
        external
        view
        returns (StakeDepositData[] memory)
    {
        return stakes[wallet];
    }

    /*
     *@notice To calculate the reward for a given stake
     *@param stakeId uint256, Stake Id
     *@return uint256(reward)
     */
    function calculateRewards(uint256 stakeId) public view returns (uint256) {
        uint256 reward;
        StakeDepositData memory s = stakers[stakeId];
        require(s.activeStaked, "Stake is not active");

        if (hasCompletedStakingPeriod(stakeId)) {
            uint256 endDate = ((s.endDate - s.startDate).div(1 days)).add(
                (s.startDate - LAUNCH_TIME).div(1 days)
            );
            for (uint256 i = endDate; i >= 0; i--) {
                if (dayToRatioMapping[i] > 0) {
                    reward = s.amount.mul(dayToRatioMapping[i]).div(1e9).sub(
                        s.rewardDebt
                    );
                    break;
                }
            }
        } else {
            reward = s.amount.mul(accHedronRewardRate).div(1e9).sub(
                s.rewardDebt
            );
        }

        return reward;
    }

    /*
     *@notice Internal function to get the current Day of the contract
     *@return uint256(currentDay)
     */
    function _currentDay() internal view returns (uint256) {
        return (block.timestamp.sub(LAUNCH_TIME)).div(1 days);
    }

    /*
     *@notice To check if the staking period is over for a given stake
     *@param stakeId uint256, Stake Id
     *@return bool
     */
    function hasCompletedStakingPeriod(uint256 stakeId)
        internal
        view
        returns (bool)
    {
        if (block.timestamp >= stakers[stakeId].endDate) {
            return true;
        } else {
            return false;
        }
    }

    function claimDust() external onlyOwner {
        uint256 amount = getClaimAndDustAmount();
        require(amount > 0, "No dust available");

        IHedron(hdrnToken).transfer(msg.sender, amount);
    }

    function getClaimAndDustAmount() public view returns (uint256) {
        uint256 amount = IHedron(hdrnToken).balanceOf(address(this)).sub(
            totalHedronStaked.add(totalRewardTobeDistributed)
        );
        return amount;
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