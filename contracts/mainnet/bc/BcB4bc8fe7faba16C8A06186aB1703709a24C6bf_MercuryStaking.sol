/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/MercuryStaking.sol


pragma solidity ^0.8.0;




contract MercuryStaking is ReentrancyGuard, Ownable {
    event Staked(address indexed user, uint256 amount);

    event Unstaked(address indexed user, uint256 amount);

    event RewardPaid(address indexed user, uint256 amount);

    event EmergencyWithdrawalInitiated();

    uint64 POINT_BASE = 1000;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    struct UserStakingData {
        uint256 amountStaked;
        uint256 guaranteedReward;
        uint256 storedReward;
        uint256 storedRewardUpdatedOn;
        uint256 firstActiveStakeIndex; // for gas optimization if many stakes
        Stake[] stakes;
    }

    uint256 public constant YIELD_PERIOD = 15552000; //180 days;

    IERC20 public stakingToken;
    IERC20 public rewardToken;
    bool internal _stakingTokenIsRewardToken;
    uint256 public rewardNumerator;
    uint256 public rewardDenominator;

    uint256 public minStakeAmount = 10_000 ether; // should be at least 1
    bool public emergencyWithdrawalInProgress = false;
    bool public paused = false;

    mapping(address => UserStakingData) stakingDataByUser;

    uint256 public totalPenaltyAmount = 0;

    uint256 public totalAmountStaked = 0;
    uint256 public totalGuaranteedReward = 0;
    uint256 public totalStoredReward = 0;

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardNumerator,
        uint256 _rewardDenominator
    ) Ownable() {
        require(_rewardNumerator != 0, "Reward numerator cannot be 0"); // would mean zero reward
        require(_rewardDenominator != 0, "Reward denominator cannot be 0"); // would mean division by zero

        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        _stakingTokenIsRewardToken = _stakingToken == _rewardToken;

        rewardNumerator = _rewardNumerator;
        rewardDenominator = _rewardDenominator;
    }

    /**
     * PUBLIC USER API
     */
    function stake(uint256 amount) public virtual nonReentrant {
        require(
            !paused,
            "Staking is temporarily paused, no new stakes accepted"
        );
        require(
            !emergencyWithdrawalInProgress,
            "Emergency withdrawal in progress, no new stakes accepted"
        );
        require(amount > 0, "Minimum stake amount not met");

        /**
         * This needs to be checked before accepting the stake,
         * in case stakedToken and rewardToken are the same
         */
        require(
            availableToStake() >= amount,
            "Not enough rewards left to accept new stakes for given amount"
        );
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "Cannot transfer balance"
        );

        UserStakingData storage userData = stakingDataByUser[msg.sender];

        // Update stored reward, in case the user has already staked
        _updateStoredReward(userData);

        userData.stakes.push(
            Stake({amount: amount, timestamp: block.timestamp})
        );

        userData.amountStaked += amount;
        totalAmountStaked += amount;
        uint256 rewardAmount = (amount * rewardNumerator) / rewardDenominator;

        require(rewardAmount > 0, "Zero reward amount");

        userData.guaranteedReward += (rewardAmount * 5) / 100;
        totalGuaranteedReward += (rewardAmount * 5) / 100;
        // may waste some gas, but would rather be safe than sorry
        userData.storedRewardUpdatedOn = block.timestamp;

        emit Staked(msg.sender, amount);
    }

    function claimReward() public virtual nonReentrant {
        _rewardUser(msg.sender);
    }

    function unstake(uint256 amount) public virtual nonReentrant {
        _unstakeUser(msg.sender, amount);
    }

    function exit() public virtual nonReentrant {
        UserStakingData storage userData = stakingDataByUser[msg.sender];
        if (userData.amountStaked > 0) {
            _unstakeUser(msg.sender, userData.amountStaked);
        }
        _rewardUser(msg.sender);
        delete stakingDataByUser[msg.sender];
    }

    /**
     * PUBLIC VIEWS AND UTILITIES
     */

    function availableToStake() public view returns (uint256 stakeable) {
        stakeable = ((rewardToken.balanceOf(address(this)) - totalLockedReward())/ 5) * 100;
        if (_stakingTokenIsRewardToken) {
            stakeable -= totalAmountStaked;
        }
        stakeable = (stakeable * rewardDenominator) / rewardNumerator;
    }    
    
    function availableToReward() public view returns (uint256 rewardable) {
        rewardable = rewardToken.balanceOf(address(this)) - totalLockedReward();
        if (_stakingTokenIsRewardToken) {
            rewardable -= totalAmountStaked;
        }
        rewardable = (rewardable * rewardDenominator) / rewardNumerator;
    }

    function totalLockedReward() public view returns (uint256 locked) {
        locked = totalStoredReward + totalGuaranteedReward;
    }

    function rewardClaimable(address user)
        public
        view
        returns (uint256 reward)
    {
        UserStakingData storage userData = stakingDataByUser[user];
        reward = userData.storedReward;
        reward += _calculateStoredRewardToAdd(userData);
    }

    function staked(address user) public view returns (uint256 amount) {
        UserStakingData storage userData = stakingDataByUser[user];
        return userData.amountStaked;
    }

    // OWNER API
    // =========

    function payRewardToUser(address user)
        public
        virtual
        onlyOwner
        nonReentrant
    {
        _rewardUser(user);
    }

    function withdrawTokens(address token, uint256 amount)
        public
        virtual
        onlyOwner
        nonReentrant
    {
        if (token == address(rewardToken)) {
            require(
                amount <= availableToReward(),
                "Can only withdraw up to balance minus locked amount"
            );
        } else if (token == address(stakingToken)) {
            uint256 maxAmount = stakingToken.balanceOf(address(this)) -
                totalAmountStaked;
            require(amount <= maxAmount, "Cannot withdraw staked tokens");
        }
        IERC20(token).transfer(msg.sender, amount);
    }

    function setMinStakeAmount(uint256 newMinStakeAmount)
        public
        virtual
        onlyOwner
        nonReentrant
    {
        require(
            newMinStakeAmount > 0,
            "Minimum stake amount must be at least 1"
        );
        minStakeAmount = newMinStakeAmount;
    }

    function setPaused(bool newPaused) public virtual onlyOwner nonReentrant {
        paused = newPaused;
    }

    function initiateEmergencyWithdrawal()
        public
        virtual
        onlyOwner
        nonReentrant
    {
        require(
            !emergencyWithdrawalInProgress,
            "Emergency withdrawal already in progress"
        );
        emergencyWithdrawalInProgress = true;
        emit EmergencyWithdrawalInitiated();
    }

    function forceExitUser(address user) public virtual onlyOwner nonReentrant {
        /**
         * NOTE: this pays all of guaranteed reward to the user,
         * even ahead of schedule with humongous APY!
         */
        require(
            emergencyWithdrawalInProgress,
            "Emergency withdrawal not in progress"
        );
        UserStakingData storage userData = stakingDataByUser[user];
        if (userData.amountStaked > 0) {
            totalAmountStaked -= userData.amountStaked;
            stakingToken.transfer(user, userData.amountStaked);
            emit Unstaked(user, userData.amountStaked);
            //userData.amountStaked = 0;
        }
        uint256 userReward = userData.storedReward + userData.guaranteedReward;
        if (userReward > 0) {
            rewardToken.transfer(user, userReward);
            totalStoredReward -= userData.storedReward;
            totalGuaranteedReward -= userData.guaranteedReward;
            emit RewardPaid(user, userReward);
        }
        // delete the whole thing to set everything as 0 and to save on gas
        delete stakingDataByUser[user];
    }

    // INTERNAL API
    // ============

    function _rewardUser(address user) internal {
        UserStakingData storage userData = stakingDataByUser[user];
        _updateStoredReward(userData);

        uint256 reward = userData.storedReward;
        if (reward == 0) {
            return;
        }

        userData.storedReward = 0;
        totalStoredReward -= reward;

        require(rewardToken.transfer(user, reward), "Sending reward failed");

        emit RewardPaid(user, reward);
    }

    function _unstakeUser(address user, uint256 amount) private {
        require(amount > 0, "Cannot unstake zero amount");

        UserStakingData storage userData = stakingDataByUser[user];
        _updateStoredReward(userData);

        uint256 amountLeft = amount;
        uint256 penaltyAmount = 0;
        uint256 i = userData.firstActiveStakeIndex;
        uint256 userDataStakesLength = userData.stakes.length;
        for (; i < userDataStakesLength; i++) {
            if (userData.stakes[i].amount == 0) {
                continue;
            }
            if (userData.stakes[i].amount > amountLeft) {
                userData.stakes[i].amount -= amountLeft;
                amountLeft = 0;
                break;
            } else {
                // stake amount equal to or smaller than amountLeft
                amountLeft -= userData.stakes[i].amount;
                userData.stakes[i].amount = 0;
            }
            //calculate penalty amount
            uint256 daysStaked = (block.timestamp -
                userData.stakes[i].timestamp) / 86400; // epoch equal 1 day
            if (daysStaked < 90) {
                penaltyAmount += (amount * 20) / 100;
            } else if (daysStaked >= 90 && daysStaked < 150) {
                penaltyAmount += (amount * 15) / 100;
            } else if (daysStaked >= 150 && daysStaked < 180) {
                penaltyAmount += (amount * 10) / 100;
            }
            totalPenaltyAmount += penaltyAmount;
        }

        require(
            amountLeft == 0,
            "Not enough staked balance left to unstake all of wanted amount"
        );

        userData.firstActiveStakeIndex = i;
        userData.amountStaked -= amount;
        totalAmountStaked -= amount;
        /**
         * We need to make sure the user is left with no guaranteed reward if they have unstaked everything
         * -- in that case, just add to stored reward.
         */
        if (userData.guaranteedReward > 0 && i == userData.stakes.length) {
            userData.storedReward += userData.guaranteedReward;
            totalStoredReward += userData.guaranteedReward;

            totalGuaranteedReward -= userData.guaranteedReward;
            userData.guaranteedReward = 0;

            userData.storedRewardUpdatedOn = block.timestamp;
        }

        require(
            stakingToken.transfer(msg.sender, amount - penaltyAmount),
            "Transferring staked token back to sender failed"
        );

        emit Unstaked(msg.sender, amount);
    }

    function _updateStoredReward(UserStakingData storage userData) internal {
        uint256 calcStoredReward = _calculateStoredRewardToAdd(userData);
        if (calcStoredReward != 0) {
            userData.storedReward += calcStoredReward;
            totalStoredReward += calcStoredReward;

            if (calcStoredReward > userData.guaranteedReward) {
                totalGuaranteedReward -= userData.guaranteedReward;
                userData.guaranteedReward = 0;
            } else {
                userData.guaranteedReward -= calcStoredReward;
                totalGuaranteedReward -= calcStoredReward;
            }

            userData.storedRewardUpdatedOn = block.timestamp;
        }
    }

    function _calculateStoredRewardToAdd(UserStakingData storage userData)
        internal
        view
        returns (uint256 storedRewardToAdd)
    {
        if (
            userData.storedRewardUpdatedOn == 0 ||
            userData.storedRewardUpdatedOn == block.timestamp
        ) {
            /**
             * safety check -- don't want to accidentally multiply everything by the unix epoch
             * instead of time passed
             */
            return 0;
        }
        uint256 timePassedFromLastUpdate = block.timestamp -
            userData.storedRewardUpdatedOn;

        uint256 localStoredRewardToAdd = (((userData.amountStaked *
            rewardNumerator *
            timePassedFromLastUpdate) / rewardDenominator) /
            (YIELD_PERIOD * 2)) / 100;

        //We can pay only guaranteedReward as maximum reward payment
        if (localStoredRewardToAdd > userData.guaranteedReward) {
            storedRewardToAdd = userData.guaranteedReward;
        } else {
            storedRewardToAdd = localStoredRewardToAdd * POINT_BASE;
        }
    }
}