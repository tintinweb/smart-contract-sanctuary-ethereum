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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GcityStakings is Ownable, ReentrancyGuard{

    event FeeUpdated(uint256 previousFee, uint256 updatedFee);
    event PlanDisabled(bool status);
    event Staking(address userAddress, uint256 level, uint256 amount, uint256 endtime);
    event Withdraw(address userAddress, uint256 withdrawAmount, uint256 rewardAmount);
    event TokenRecovered(address tokenAddress, address walletAddress);

    IERC20 public immutable GcityToken;
    uint256 public penaltyFeePermile;
    uint256 internal tokenDecimal =  1 * 10 ** 18;
    uint256 public reserveAmount;

    struct UserDetail {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool status;
    }

    struct Stake {
        uint256 rewardPercent;
        uint256 stakeLimit;
        uint256 minStake;
        uint256 maxStake;
        bool active;
    }

    mapping(address =>mapping(uint256 => UserDetail)) internal users;
    mapping(uint256 => Stake) internal stakingDetails;

    constructor (IERC20 _token, uint256 _penaltyFeePermile) {
        GcityToken = _token;
        penaltyFeePermile = _penaltyFeePermile;
        stakingDetails[1] = Stake(5, 60 seconds, 1 * tokenDecimal, 10 * tokenDecimal, true);
        stakingDetails[2] = Stake(10, 182 seconds, 10 * tokenDecimal, 100 * tokenDecimal, true);
        stakingDetails[3] = Stake(15, 365 seconds, 100 * tokenDecimal, 1000 * tokenDecimal, true);
    }

    function updatePenaltyFee(uint256 fee) external onlyOwner {
        emit FeeUpdated(penaltyFeePermile, fee);
        penaltyFeePermile = fee;
    }

    function stake(uint256 amount, uint256 level) external returns(bool) {
        require(stakingDetails[level].active , "disabled level");
        require(level > 0 && level <= 3, "Invalid level");
        require(!(users[msg.sender][level].status),"user already exist");
        require(amount >= stakingDetails[level].minStake && amount <= stakingDetails[level].maxStake, "invalid amount");
        users[msg.sender][level].amount = amount;
        users[msg.sender][level].level = level;
        users[msg.sender][level].endTime = block.timestamp + stakingDetails[level].stakeLimit;
        users[msg.sender][level].initialTime = block.timestamp;
        users[msg.sender][level].status = true;
        GcityToken.transferFrom(msg.sender, address(this), amount);
        addReserve(level);
        emit Staking(msg.sender, level, amount, users[msg.sender][level].endTime);
        return true;
    }

    function withdraw(uint256 level) external  nonReentrant returns(bool) {
        require(level > 0 && level <= 3, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        require(users[msg.sender][level].endTime <= block.timestamp, "staking end time is not reached");
        uint256 rewardAmount = getRewards(msg.sender, level);
        uint256 amount = rewardAmount + users[msg.sender][level].amount;
        GcityToken.transfer(msg.sender, amount);
        uint256 rAmount = rewardAmount + users[msg.sender][level].rewardAmount;
        uint256 wAmount = amount + users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(0, 0, 0, 0, rAmount, wAmount, false);
        emit Withdraw(msg.sender, amount, rewardAmount);
        return true;
    }

    function emergencyWithdraw(uint256 level) external  nonReentrant returns(uint256) {
        require(level > 0 && level <= 3, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        require(users[msg.sender][level].endTime >= block.timestamp, "staking ended");
        uint256 stakedAmount = users[msg.sender][level].amount;
        uint256 penalty = stakedAmount * penaltyFeePermile / 1000;
        uint256 transferAmt = stakedAmount - penalty ;
        GcityToken.transfer(msg.sender, transferAmt);
        GcityToken.transfer(owner(), penalty);
        uint256 rewardAmount = users[msg.sender][level].rewardAmount;
        uint256 withdrawAmount = users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(0, 0, 0, 0, rewardAmount, withdrawAmount, false);
        emit Withdraw(msg.sender, transferAmt, 0);
        return transferAmt;
    }


    function disablePlan(uint256 level, bool status) external onlyOwner returns(bool) {
        require(level > 0 && level <= 3, "Invalid level");
        stakingDetails[level].active =  status;
        emit PlanDisabled(status);
        return true;
    }

    function recoverToken(address to)
        external
        onlyOwner
    {
        require(to != address(0), "Null address");
        require(IERC20(GcityToken).balanceOf(address(this)) > reserveAmount, "Insufficient amount");
        uint256 amount = IERC20(GcityToken).balanceOf(address(this)) - reserveAmount;
        bool success = IERC20(GcityToken).transfer(
            to,
            amount
        );
        require(success, "tx failed");
        emit TokenRecovered(address(GcityToken), to);
    }

    function renounceOwnership() public virtual override onlyOwner{
          //functionality disabled
          revert("disabled");
    }

    function getUserDetails(address account, uint256 level) external view returns(UserDetail memory, uint256 rewardAmount) {
        uint256 reward = getRewards(account, level);
        return (users[account][level], reward);
    }

    function getPlanDetails(uint256 level) external view returns(Stake memory) {
            return stakingDetails[level];
    }

    function calculateReward(address account, uint256 level) public view returns(uint256) {
        uint256 stakeAmount = users[account][level].amount;
        uint256 rewardRate = stakingDetails[level].rewardPercent;
        uint256 duration = stakingDetails[level].stakeLimit;
        uint256 rewardAmount = stakeAmount * rewardRate * duration / 365 seconds / 100;
        return rewardAmount;
    }

    function getRewards(address account, uint256 level) internal view returns(uint256) {
       if(users[account][level].endTime <= block.timestamp) {
             return calculateReward( account, level);
       }
        else {
            return (0);
        }
    }

    function addReserve(uint256 level) internal {
        uint256 amount = users[msg.sender][level].amount * stakingDetails[level].rewardPercent * stakingDetails[level].stakeLimit / 365 seconds /100;
        reserveAmount += (users[msg.sender][level].amount + amount);
    }

    function removeReserve(uint256 level) internal {
        uint256 amount = users[msg.sender][level].amount * stakingDetails[level].rewardPercent * stakingDetails[level].stakeLimit / 365 seconds /100;
        reserveAmount -= (users[msg.sender][level].amount + amount);
    }

}