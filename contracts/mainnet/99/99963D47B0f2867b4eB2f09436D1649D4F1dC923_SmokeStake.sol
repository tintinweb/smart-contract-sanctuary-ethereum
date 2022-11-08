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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SmokeStake is Ownable, ReentrancyGuard {
    struct user {
        uint256 id;
        uint256 totalStakedBalance;
        uint256 totalClaimedRewards;
        uint256 createdTime;
    }

    struct stakePool {
        uint256 id;
        uint256 duration;
        uint256 APY; // Used for fixed APY
        uint256 withdrawalFee;
        uint256 unstakePenalty;
        uint256 stakedTokens;
        uint256 claimedRewards;
        uint256 status; //1: created, 2: active, 3: cancelled
        address creator;
        uint256 createdTime;
    }

    stakePool[] private stakePoolArray;

    struct userStake {
        uint256 id;
        uint256 stakePoolId;
        uint256 stakeBalance;
        uint256 totalClaimedRewards;
        uint256 lastClaimedTime;
        uint256 status; //0 : Unstaked, 1 : Staked
        address owner;
        uint256 createdTime;
        uint256 unlockTime;
        uint256 lockDuration;
    }

    userStake[] private userStakeArray;

    mapping(uint256 => stakePool) private stakePoolsById;
    mapping(uint256 => userStake) private userStakesById;

    mapping(address => uint256[]) private userStakeIds;
    mapping(address => userStake[]) private userStakeLists;

    mapping(address => user) users;

    uint256 public totalStakedBalance;
    uint256 public totalClaimedBalance;
    uint256 private constant magnitude = 100000000;

    uint256 private userIndex; // 0 by default
    uint256 private poolIndex; // 0 by default
    uint256 private stakeIndex; // 0 by default

    // bool public dynamicApy = false;
    bool public unstakePenalty = true;
    bool public isPaused = false;
    address private sessionsWallet;

    IERC20 immutable stakeToken;

    IERC20 immutable rewardToken;

    modifier unpaused() {
        require(isPaused == false);
        _;
    }

    modifier paused() {
        require(isPaused == true);
        _;
    }

    constructor(address _sessionsWallet, address _baseTokenAddress) {
        sessionsWallet = _sessionsWallet;
        stakeToken = IERC20(_baseTokenAddress);
        rewardToken = IERC20(_baseTokenAddress); // reward and stake tokens are same

        //Pool 1 => 30 Days 69% APY
        addStakePool(
            30, // Duration in days
            69, // APY % -- applicable for fixed APY pools only
            0, // Withdrawal Fee %
            334 // Unstaking Penalty 33.4% - of initial tokens staked.
        );

        //Pool 2 => 90 Days 100% APY
        addStakePool(90, 100, 0, 334);

        //Pool 3 => 180 DAYS 420% APY
        addStakePool(180, 420, 0, 334);
    }

    function addStakePool(
        uint256 _duration,
        uint256 _apy,
        uint256 _withdrawalFee,
        uint256 _unstakePenalty
    ) public onlyOwner returns (bool) {
        stakePool memory stakePoolDetails;

        stakePoolDetails.id = poolIndex; // 0th index for the first Staking Pool
        stakePoolDetails.duration = _duration;
        stakePoolDetails.APY = _apy;
        stakePoolDetails.withdrawalFee = _withdrawalFee;
        stakePoolDetails.unstakePenalty = _unstakePenalty;
        stakePoolDetails.creator = msg.sender;
        stakePoolDetails.createdTime = block.timestamp;

        stakePoolArray.push(stakePoolDetails);
        stakePoolsById[poolIndex++] = stakePoolDetails;

        return true;
    }

    function getFixedAPY(uint256 _stakePoolId) private view returns (uint256) {
        stakePool memory stakePoolDetails = getStakePoolDetailsById(_stakePoolId);
        return stakePoolDetails.APY;
    }

    function getDPR(uint256 _stakePoolId) internal view returns (uint256) {
        uint256 apy;
        uint256 dpr;

        apy = getFixedAPY(_stakePoolId);
        dpr = (apy * magnitude) / 360; // daily percentage return

        return dpr;
    }

    function getStakePoolDetailsById(uint256 _stakePoolId) public view returns (stakePool memory) {
        return (stakePoolArray[_stakePoolId]);
    }

    function getElapsedTime(uint256 _stakeId) private view returns (uint256) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        if (userStakeDetails.lastClaimedTime == 0) {
            uint256 lapsedDays = ((block.timestamp - userStakeDetails.createdTime) / 3600) / 24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
            return lapsedDays;
        } else {
            uint256 lapsedDays = ((block.timestamp - userStakeDetails.lastClaimedTime) / 3600) / 24; //3600 seconds per hour so: lapsed days = lapsed time * (3600seconds /24hrs)
            return lapsedDays;
        }
    }

    function stake(uint256 _stakePoolId, uint256 _amount)
        external
        nonReentrant
        unpaused
        returns (bool)
    {
        require(
            stakeToken.allowance(msg.sender, address(this)) >= _amount,
            "Insufficient Allowance"
        );

        bool success = stakeToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token Transfer failed.");

        stakePool memory stakePoolDetails = stakePoolsById[_stakePoolId];
        userStake memory userStakeDetails;

        uint256 userStakeid = ++stakeIndex; // stakes start from 1
        userStakeDetails.id = userStakeid;
        userStakeDetails.stakePoolId = _stakePoolId;
        userStakeDetails.stakeBalance = _amount;
        userStakeDetails.status = 1;
        userStakeDetails.owner = msg.sender;
        userStakeDetails.createdTime = block.timestamp;
        userStakeDetails.unlockTime = block.timestamp + (stakePoolDetails.duration * 86400); // days * (seconds in 1 day) to get total time in seconds
        userStakeDetails.lockDuration = stakePoolDetails.duration;
        userStakeDetails.lastClaimedTime = block.timestamp;

        userStakesById[userStakeid] = userStakeDetails;

        uint256[] storage userStakeIdsArray = userStakeIds[msg.sender];

        userStakeIdsArray.push(userStakeid);
        userStakeArray.push(userStakeDetails);

        userStake[] storage userStakeList = userStakeLists[msg.sender];
        userStakeList.push(userStakeDetails);

        user memory userDetails = users[msg.sender];

        if (userDetails.id == 0) {
            userDetails.id = block.timestamp;
            userDetails.createdTime = block.timestamp;
        }

        userDetails.totalStakedBalance = userDetails.totalStakedBalance + _amount;

        users[msg.sender] = userDetails;

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens + _amount;

        stakePoolsById[_stakePoolId] = stakePoolDetails;

        totalStakedBalance = totalStakedBalance + _amount;

        return true;
    }

    function unstake(uint256 _stakeId) external nonReentrant unpaused returns (bool) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        uint256 stakePoolId = userStakeDetails.stakePoolId;
        uint256 stakeBalance = userStakeDetails.stakeBalance;
        uint256 unstakableBalance = stakeBalance;

        require(userStakeDetails.owner == msg.sender, "You don't own this stake");

        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

        require(
            stakeToken.balanceOf(address(this)) >= stakeBalance,
            "Insufficient contract stake token balance"
        );

        if (isStakeLocked(_stakeId)) {
            uint256 penaltyAmount = (stakeBalance * stakePoolDetails.unstakePenalty) / (1000);
            unstakableBalance = stakeBalance - penaltyAmount;
            //Take % of initial tokens staked, if unstaking early as penalty, the amount of tokens are transfered to sessions burn wallet
            bool pSuccess = stakeToken.transfer(sessionsWallet, penaltyAmount);
            require(pSuccess, "Penalty StakeToken Transfer failed.");

            //to sessions 33.4% Of Unclaimed Rewards & keep 66.6% Of Unclaimed Rewards in the pool
            uint256 unclaimed = getUnclaimedRewards(_stakeId);
            if (unclaimed > 0) {
                uint256 toBurnAmount = (unclaimed * 334) / (1000); // divide by 1000 to cover .4% as well
                rewardToken.transfer(sessionsWallet, toBurnAmount);
            }
        }

        // 0 balance will also set unclaimedRewards to 0 as 0*n = 0
        delete userStakesById[_stakeId];
        uint256 stakeInd = _stakeId - 1; // always 1 less as stakes(mapping can) start with 1 but not arrays
        delete userStakeArray[stakeInd]; // resets userStake values but keeps array length
        delete userStakeLists[msg.sender][stakeInd];
        delete userStakeIds[msg.sender][stakeInd];

        stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens - stakeBalance;

        user memory userDetails = users[msg.sender];
        userDetails.totalStakedBalance = userDetails.totalStakedBalance - stakeBalance;

        users[msg.sender] = userDetails;
        stakePoolsById[stakePoolId] = stakePoolDetails;

        totalStakedBalance = totalStakedBalance - stakeBalance;

        bool success = stakeToken.transfer(msg.sender, unstakableBalance);
        require(success, "Token Transfer failed.");

        return true;
    }

    function isStakeLocked(uint256 _stakeId) private view returns (bool) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        if (block.timestamp < userStakeDetails.unlockTime) {
            return true;
        } else {
            return false;
        }
    }

    function getStakePoolIdByStakeId(uint256 _stakeId) public view returns (uint256) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.stakePoolId;
    }

    function getUserStakeIdsByAddress(address _userAddress) public view returns (uint256[] memory) {
        return (userStakeIds[_userAddress]);
    }

    function getUserStakeDetailsByStakeId(uint256 _stakeId)
        public
        view
        returns (userStake memory, stakePool memory)
    {
        userStake memory userStakeDetails = userStakeArray[_stakeId - 1];
        uint256 userStakePoolId = userStakeDetails.stakePoolId;
        return (userStakeDetails, stakePoolArray[userStakePoolId]);
    }

    function getUserAllStakeDetailsByAddress(address _userAddress)
        public
        view
        returns (userStake[] memory)
    {
        return (userStakeLists[_userAddress]);
    }

    function getUserStakeOwner(uint256 _stakeId) public view returns (address) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.owner;
    }

    function getUserStakeBalance(uint256 _stakeId) public view returns (uint256) {
        userStake memory userStakeDetails = userStakesById[_stakeId];
        return userStakeDetails.stakeBalance;
    }

    // get unclaimedRewards of a specific user Stake in a pool
    function getUnclaimedRewards(uint256 _stakeId) public view returns (uint256) {
        userStake memory userStakeDetails = userStakeArray[_stakeId - 1];
        uint256 stakePoolId = userStakeDetails.stakePoolId;

        stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];
        uint256 stakeApr = getDPR(stakePoolDetails.id);

        uint256 applicableRewards = (userStakeDetails.stakeBalance * stakeApr) / (magnitude * 100); //divided by 10000 to handle decimal percentages like 0.1%
        uint256 unclaimedRewards = (applicableRewards * getElapsedTime(_stakeId));

        return unclaimedRewards;
    }

    function getTotalUnclaimedRewardsByAddress(address _userAddress) public view returns (uint256) {
        uint256[] memory stakeIds = getUserStakeIdsByAddress(_userAddress);
        uint256 totalUnclaimedRewards;
        for (uint256 i = 0; i < stakeIds.length; i++) {
            if (stakeIds[i] == 0) continue;
            totalUnclaimedRewards += getUnclaimedRewards(stakeIds[i]);
        }
        return totalUnclaimedRewards;
    }

    function getAllPoolDetails() public view returns (stakePool[] memory) {
        return (stakePoolArray);
    }

    function claimRewards(uint256 _stakeId) external nonReentrant unpaused returns (bool) {
        address userStakeOwner = getUserStakeOwner(_stakeId);
        require(userStakeOwner == msg.sender, "You don't own this stake");

        userStake memory userStakeDetails = userStakesById[_stakeId];

        require(
            ((block.timestamp - userStakeDetails.lastClaimedTime) / 3600) > 24,
            "You already claimed rewards today"
        );

        uint256 unclaimedRewards = getUnclaimedRewards(_stakeId);

        userStakeDetails.totalClaimedRewards =
            userStakeDetails.totalClaimedRewards +
            unclaimedRewards;
        userStakeDetails.lastClaimedTime = block.timestamp;
        userStakesById[_stakeId] = userStakeDetails;

        totalClaimedBalance += unclaimedRewards;

        user memory userDetails = users[msg.sender];
        userDetails.totalClaimedRewards += unclaimedRewards;

        users[msg.sender] = userDetails;

        require(
            rewardToken.balanceOf(address(this)) >= unclaimedRewards,
            "Insufficient contract reward token balance"
        );

        bool success = rewardToken.transfer(msg.sender, unclaimedRewards);
        require(success, "Token Transfer failed.");

        return true;
    }

    function getUserDetailsByAddress(address _userAddress) external view returns (user memory) {
        user memory userDetails = users[_userAddress];
        return (userDetails);
    }

    function pauseStake() public onlyOwner {
        isPaused = true;
    }

    function unpauseStake() public onlyOwner {
        isPaused = false;
    }

    function emergencyUnstake() public paused {
        userStake[] memory userAllStakes = userStakeLists[msg.sender];

        for (uint256 i = 0; i < userAllStakes.length; i++) {
            uint256 _stakeId = userAllStakes[i].id;
            userStake memory userStakeDetails = userStakesById[_stakeId];
            uint256 stakePoolId = userStakeDetails.stakePoolId;
            uint256 stakeBalance = userStakeDetails.stakeBalance;

            if (stakeBalance == 0) continue;
            require(userStakeDetails.owner == msg.sender, "You don't own this stake");

            stakePool memory stakePoolDetails = stakePoolsById[stakePoolId];

            uint256 unstakableBalance = stakeBalance;
            userStakeDetails.stakeBalance = 0;
            userStakeDetails.status = 0;

            userStakesById[_stakeId] = userStakeDetails;

            stakePoolDetails.stakedTokens = stakePoolDetails.stakedTokens - stakeBalance;

            userStakesById[_stakeId] = userStakeDetails;

            user memory userDetails = users[msg.sender];
            userDetails.totalStakedBalance = userDetails.totalStakedBalance - unstakableBalance;

            users[msg.sender] = userDetails;
            stakePoolsById[stakePoolId] = stakePoolDetails;

            totalStakedBalance = totalStakedBalance - unstakableBalance;

            require(
                stakeToken.balanceOf(address(this)) >= unstakableBalance,
                "Insufficient contract stake token balance"
            );

            bool success = stakeToken.transfer(msg.sender, unstakableBalance);
            require(success, "Token Transfer failed.");
        }
    }

    function withdrawContractETH() public onlyOwner paused returns (bool) {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");

        return true;
    }

    function withdrawContractRewardTokens() public onlyOwner paused returns (bool) {
        //IERC20 token = IERC20(baseTokenAddress);

        bool success = rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
        require(success, "Token Transfer failed.");

        return true;
    }

    // change the burn sessionsWalet
    function setSessionsWallet(address _newSessionsWallet) public onlyOwner {
        sessionsWallet = _newSessionsWallet;
    }

    receive() external payable {}
}