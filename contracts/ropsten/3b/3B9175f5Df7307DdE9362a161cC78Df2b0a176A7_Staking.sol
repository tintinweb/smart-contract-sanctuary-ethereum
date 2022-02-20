pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './IVesting.sol';

contract Staking is Ownable {
    using SafeMath for uint256;

    enum VestingId { EMPTY, DAYS_30, DAYS_60 }

    struct Stake {
        uint initialSize;
        uint currentSize;
        uint startTime;
    }

    struct Staker {
        Stake stake;
        VestingId vesting;
        uint rewardsPerToken;
        uint unclaimedRewards;
    }

    struct Vesting {
        IVesting strategy;
        uint rewardsPerDay;
        uint lastUpdateTime;
        uint rewardsPerToken;
    }

    struct NewUser {
        address addr;
        uint stakeSize;
        VestingId vesting;
    }

    IERC20 public rewardToken;
    mapping(VestingId => Vesting) public vestings;
    mapping(VestingId => uint) public totalStaked;

    address[] public whitelisted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => Staker) public stakers;
    mapping(address => uint) public claimedRewards;

    uint public rewardsPool;
    bool public isStarted;
    uint public startTime;

    constructor(address _owner, IERC20 _rewardToken) {
        if (_owner != msg.sender) {
            _transferOwnership(_owner);
        }

        rewardToken = _rewardToken;
    }

    function initializeVesting(VestingId vestingId, IVesting vestingContract, uint rewardsPerDay) external onlyOwner notStarted {
        require(vestingId != VestingId.EMPTY, 'Wrong vesting');

        Vesting storage vesting = vestings[vestingId];
        vesting.rewardsPerDay = rewardsPerDay;
        vesting.strategy = vestingContract;
    }

    function initializeUsers(NewUser[] calldata users) external onlyOwner notStarted {
        require(users.length <= 20, 'Array of new users is too big');

        for (uint i = 0; i < users.length; i++) {
            NewUser calldata user = users[i];

            addToWhitelist(user.addr);
            Staker storage staker = stakers[user.addr];
            staker.stake.initialSize = user.stakeSize;
            staker.stake.currentSize = user.stakeSize;
            staker.vesting = user.vesting;
            rewardToken.transferFrom(msg.sender, address(this), user.stakeSize);

            totalStaked[user.vesting] = totalStaked[user.vesting].add(user.stakeSize);
        }
    }

    function addToWhitelist(address addr) public onlyOwner {
        require(isWhitelisted[addr] == false, 'Address is already in whitelist');

        whitelisted.push(addr);
        isWhitelisted[addr] = true;
    }

    function removeFromWhitelist(address addr) external onlyOwner {
        require(isWhitelisted[addr], 'Address must be whitelisted');
        isWhitelisted[addr] = false;

        for (uint i = 0; i < whitelisted.length; i++) {
            Staker storage staker = stakers[addr];
            if (whitelisted[i] == addr && staker.vesting != VestingId.EMPTY) {
                totalStaked[staker.vesting] = totalStaked[staker.vesting].sub(staker.stake.currentSize);

                whitelisted[i] = whitelisted[whitelisted.length - 1];
                whitelisted.pop();
                break;
            }
        }
    }

    modifier onlyWhitelisted {
        require(isWhitelisted[msg.sender]);
        _;
    }

    function start(uint initRewardsPool) external onlyOwner notStarted initialized {
        rewardToken.transferFrom(msg.sender, address(this), initRewardsPool);
        rewardsPool = initRewardsPool;

        startTime = block.timestamp;
        vestings[VestingId.DAYS_30].lastUpdateTime = block.timestamp;
        vestings[VestingId.DAYS_60].lastUpdateTime = block.timestamp;

        isStarted = true;
    }

    function stake(VestingId vesting, uint amount) external onlyWhitelisted newUser started {
        require(vesting != VestingId.EMPTY, 'Wrong vesting');

        Staker storage staker = stakers[msg.sender];
        rewardToken.transferFrom(msg.sender, address(this), amount);

        _updateRewardsPerToken(vesting);
        totalStaked[vesting] = totalStaked[vesting].add(amount);

        staker.rewardsPerToken = vestings[vesting].rewardsPerToken;
        staker.stake.initialSize = amount;
        staker.stake.currentSize = amount;
        staker.stake.startTime = block.timestamp;

        staker.vesting = vesting;
    }

    function unstake(uint amount) external userIsStaking started {
        Staker storage staker = stakers[msg.sender];

        if (staker.stake.startTime == 0) {
            staker.stake.startTime = startTime;
        }

        require(staker.stake.currentSize >= amount, 'Balance is not sufficient');

        Vesting storage vesting = vestings[staker.vesting];

        uint stakerAllowedToUnstake = _howMuchToClaimIsLeft(msg.sender);
        require(stakerAllowedToUnstake >= amount, 'Such amount of tokens are not vested yet');

        _updateRewards(msg.sender);
        totalStaked[staker.vesting] = totalStaked[staker.vesting].sub(amount);

        rewardToken.transfer(msg.sender, amount);
        staker.stake.currentSize = staker.stake.currentSize.sub(amount);        
        staker.rewardsPerToken = vesting.rewardsPerToken;
    }

    function claimRewards() public onlyWhitelisted started {
        _updateRewards(msg.sender);
        Staker storage staker = stakers[msg.sender];

        if (staker.unclaimedRewards > 0) {
            require(rewardsPool >= staker.unclaimedRewards, 'Reward pool must be sufficient');

            rewardToken.transfer(msg.sender, staker.unclaimedRewards);
            rewardsPool = rewardsPool.sub(staker.unclaimedRewards);
            claimedRewards[msg.sender] = claimedRewards[msg.sender].add(staker.unclaimedRewards);

            staker.unclaimedRewards = 0;
        }
    }

    function calcAPY() external view started userIsStaking returns(uint) {
        VestingId vesting = stakers[msg.sender].vesting;

        return vestings[vesting].rewardsPerDay.mul(365).mul(100).div(totalStaked[vesting]);
    }

    function calcAPY(VestingId vesting, uint stakeSize) external view started returns(uint) {
        require(vesting != VestingId.EMPTY, 'WrongVesting');

        return vestings[vesting].rewardsPerDay.mul(365).mul(100).div(totalStaked[vesting].add(stakeSize));
    }

    function fullAmountOfTokens() external view returns(uint) {
        return rewardToken.totalSupply();
    }

    function howMuchToClaimIsLeft() external view started userIsStaking returns(uint) {
        return _howMuchToClaimIsLeft(msg.sender);
    }

    function _howMuchToClaimIsLeft(address addr) internal view returns(uint) {
        Staker storage staker = stakers[addr];
        IVesting vesting = vestings[staker.vesting].strategy;

        return vesting.calcVestedAmount(staker.stake.startTime, staker.stake.initialSize)
                      .sub(staker.stake.initialSize.sub(staker.stake.currentSize));
    }

    function increaseRewardsPool(uint amount) external onlyOwner {
        rewardToken.transferFrom(msg.sender, address(this), amount);
        rewardsPool = rewardsPool.add(amount);
    }

    function _updateRewardsPerToken(VestingId vestingId) internal {
        Vesting storage vesting = vestings[vestingId];

        if (block.timestamp > vesting.lastUpdateTime && totalStaked[vestingId] > 0) {
            vesting.rewardsPerToken = vesting.rewardsPerToken.add(
                ((block.timestamp).sub(vesting.lastUpdateTime)).mul(1e18).div(totalStaked[vestingId])
            );

            vesting.lastUpdateTime = block.timestamp;
        }
    }

    function _updateRewards(address addr) internal {
        Staker storage staker = stakers[addr];
        _updateRewardsPerToken(staker.vesting);

        staker.unclaimedRewards = _calcRewards(addr);
        staker.rewardsPerToken = vestings[staker.vesting].rewardsPerToken;
    }

    function _calcRewards(address addr) internal view returns(uint) {
        Staker storage staker = stakers[addr];
        Vesting storage vesting = vestings[staker.vesting];
        
        return staker.unclaimedRewards.add(
            vesting.rewardsPerDay.mul(staker.stake.currentSize)
                                 .mul(vesting.rewardsPerToken.sub(staker.rewardsPerToken))
                                 .div(1e18).div(1 days)
        );
    }

    modifier started {
        require(isStarted == true, 'Staking not started yet');
        _;
    }

    modifier notStarted {
        require(isStarted == false, 'Staking already started');
        _;
    }

    modifier initialized {
        require(
            address(vestings[VestingId.DAYS_30].strategy) != address(0) &&
            address(vestings[VestingId.DAYS_30].strategy) != address(0),
            'Staking not initialized'
        );
        _;
    }

    modifier newUser {
        require(stakers[msg.sender].vesting == VestingId.EMPTY, 'User already participates in staking');
        _;
    }

    modifier userIsStaking {
        require(stakers[msg.sender].vesting != VestingId.EMPTY, "User haven't staked yet");
        _;
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: Unlicensed

interface IVesting {
    function calcVestedAmount(uint _startTime, uint _allowance) external view returns(uint);
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