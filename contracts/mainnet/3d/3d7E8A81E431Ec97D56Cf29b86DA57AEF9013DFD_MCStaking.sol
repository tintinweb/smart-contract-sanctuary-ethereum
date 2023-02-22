/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Extended is IERC20 {
    function stakingReward(address _to, uint256 _amount) external;
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract MCStaking is Ownable {
    using SafeMath for uint256;

    address public token;
    uint256 public totalRewarded;
    uint256 public plentyPercent;
    uint256 public totalWithdrawn;
    uint256 public totalStakedTokens;

    uint256[2] public planAPY;
    uint256[2] public planDuration;

    uint256 internal constant PERCENT_DIVIDER = 100000;

    struct Stake {
        uint256 planId;
        uint256 amount;
        uint256 reward;
        bool isWithdrawn;
        uint256 stakeTime;
        uint256 unlockTime;
    }

    struct User {
        uint256 stakeCount;
        uint256 totalStaked;
        uint256 totalRewarded;
        uint256 totalWithdrawn;
        mapping(uint256 => Stake) stakes;
    }
    mapping(address => User) public users;

    event RESTAKE(uint256 stakeId, uint256 _amount);
    event WITHDRAW(uint256 unstakedAt, uint256 stakeId);
    event STAKE(uint256 _amount, uint256 stakedAt, uint256 planId);

    constructor(address _token) {
        token = _token;

        plentyPercent = 15000;
        planAPY = [35000, 150000];
        planDuration = [7 days, 30 days];
    }

    function stake(uint256 planId, uint256 _amnt) external {
        require(planId < planDuration.length, "Invalid Plan");

        IERC20(token).transferFrom(msg.sender, address(this), _amnt);
        User storage _user = users[msg.sender];
        uint256 currentId = ++_user.stakeCount;

        _user.stakes[currentId].planId = planId;
        _user.stakes[currentId].amount = _amnt;
        _user.stakes[currentId].reward = getRewardAmountPerSecond(planId, _amnt)
            .mul(planDuration[planId]);
        _user.stakes[currentId].stakeTime = block.timestamp;
        _user.stakes[currentId].unlockTime = block.timestamp.add(
            planDuration[planId]
        );

        _user.totalStaked = _user.totalStaked.add(_amnt);
        totalStakedTokens = totalStakedTokens.add(_amnt);

        emit STAKE(_amnt, block.timestamp, planId);
    }

    function restake(uint256 stakeId) external {
        User storage _user = users[msg.sender];
        require(
            stakeId != 0 && stakeId <= _user.stakeCount,
            "Invalid Stake Id"
        );
        require(!_user.stakes[stakeId].isWithdrawn, "Already withdrawn");
        require(
            block.timestamp < _user.stakes[stakeId].unlockTime,
            "Already unlocked for withdraw!"
        );
        uint256 elapsedDuration = block.timestamp -
            _user.stakes[stakeId].stakeTime;
        uint256 remainingDuration = _user.stakes[stakeId].unlockTime -
            block.timestamp;
        uint256 rewardPerSecond = getRewardAmountPerSecond(
            _user.stakes[stakeId].planId,
            _user.stakes[stakeId].amount
        );
        uint256 restakingAmount = rewardPerSecond.mul(elapsedDuration);

        _user.stakes[stakeId].amount = _user.stakes[stakeId].amount.add(
            restakingAmount
        );
        _user.stakes[stakeId].reward = getRewardAmountPerSecond(
            _user.stakes[stakeId].planId,
            _user.stakes[stakeId].amount
        ).mul(remainingDuration);
        _user.stakes[stakeId].stakeTime = block.timestamp;

        _user.totalStaked = _user.totalStaked.add(restakingAmount);
        totalStakedTokens = totalStakedTokens.add(restakingAmount);

        IERC20Extended(token).stakingReward(address(this), restakingAmount);
        emit RESTAKE(stakeId, restakingAmount);
    }

    function withdraw(uint256 stakeId) external {
        User storage _user = users[msg.sender];
        require(
            stakeId != 0 && stakeId <= _user.stakeCount,
            "Invalid Stake Id"
        );
        require(!_user.stakes[stakeId].isWithdrawn, "Already withdrawn");

        uint256 rewardAmnt;
        uint256 withdrawingAmnt;
        uint256 plentyFee;
        if (block.timestamp < _user.stakes[stakeId].unlockTime) {
            plentyFee = _user.stakes[stakeId].amount.mul(plentyPercent).div(
                PERCENT_DIVIDER
            );
            withdrawingAmnt = _user.stakes[stakeId].amount.sub(plentyFee);
        } else {
            rewardAmnt = _user.stakes[stakeId].reward;
            withdrawingAmnt = _user.stakes[stakeId].amount;
            IERC20Extended(token).stakingReward(msg.sender, rewardAmnt);
        }

        _user.stakes[stakeId].isWithdrawn = true;
        _user.totalRewarded = _user.totalRewarded.add(rewardAmnt);
        _user.totalWithdrawn = _user.totalWithdrawn.add(withdrawingAmnt);

        IERC20(token).transfer(msg.sender, withdrawingAmnt);
        if (plentyFee != 0) {
            IERC20(token).transfer(owner(), plentyFee);
        }

        emit WITHDRAW(block.timestamp, stakeId);
    }

    function getRewardAmountPerSecond(uint256 planId, uint256 _amnt)
        internal
        view
        returns (uint256 rewardPerSecond)
    {
        rewardPerSecond = _amnt.mul(planAPY[planId]).div(PERCENT_DIVIDER).div(
            365 * 86400
        );
    }

    function getStakeInfo(address _usr, uint256 stakeId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            uint256,
            uint256
        )
    {
        User storage _user = users[_usr];
        require(
            stakeId != 0 && stakeId <= _user.stakeCount,
            "Invalid Stake Id"
        );

        return (
            _user.stakes[stakeId].planId,
            _user.stakes[stakeId].amount,
            _user.stakes[stakeId].reward,
            _user.stakes[stakeId].isWithdrawn,
            _user.stakes[stakeId].stakeTime,
            _user.stakes[stakeId].unlockTime
        );
    }

    function calculateReward(address _user)
        external
        view
        returns (uint256 reward)
    {
        User storage user = users[_user];
        for (uint256 i = 1; i <= user.stakeCount; i++) {
            if (!user.stakes[i].isWithdrawn) {
                uint256 duration = block.timestamp - user.stakes[i].stakeTime;
                if (block.timestamp > user.stakes[i].unlockTime) {
                    reward += user.stakes[i].reward;
                } else {
                    reward += (
                        user.stakes[i].reward.div(
                            planDuration[user.stakes[i].planId]
                        )
                    ).mul(duration);
                }
            }
        }
    }

    function updatePlentyFee(uint256 _fee) external onlyOwner {
        plentyPercent = _fee;
    }

    function withdrawStuckTokens(
        address _token,
        address _account,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }

    function SetStakeDuration(uint256 first, uint256 second)
        external
        onlyOwner
    {
        planDuration[0] = first;
        planDuration[1] = second;
    }

    function SetPlanAPY(uint256 first, uint256 second) external onlyOwner {
        planAPY[0] = first;
        planAPY[1] = second;
    }
}