// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IVirtualBalanceWrapper.sol";
import "./IBaseReward.sol";

contract BaseReward is ReentrancyGuard, IBaseReward {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardToken;
    uint256 public constant duration = 7 days;

    // address public owner;
    mapping(address => bool) private owners;
    address public virtualBalance;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user);
    event Withdrawn(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);
    event NewOwner(address indexed sender, address operator);
    event RemoveOwner(address indexed sender, address operator);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyOwners() {
        require(isOwner(msg.sender), "BaseReward: caller is not an owner");
        _;
    }

    constructor(
        address _reward,
        address _virtualBalance,
        address _owner
    ) public {
        rewardToken = _reward;
        virtualBalance = _virtualBalance;
        owners[_owner] = true;
    }

    function totalSupply() public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).totalSupply();
    }

    function balanceOf(address _for) public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view override returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function addOwner(address _newOwner) public override onlyOwners {
        require(!isOwner(_newOwner), "BaseReward: address is already owner");

        owners[_newOwner] = true;

        emit NewOwner(msg.sender, _newOwner);
    }

    function addOwners(address[] calldata _newOwners) external override onlyOwners {
        for (uint256 i = 0; i < _newOwners.length; i++) {
            addOwner(_newOwners[i]);
        }
    }

    function removeOwner(address _owner) external override onlyOwners {
        require(isOwner(_owner), "BaseReward: address is not owner");

        owners[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function isOwner(address _owner) public view override returns (bool) {
        return owners[_owner];
    }

    function stake(address _for) public override updateReward(_for) onlyOwners {
        emit Staked(_for);
    }

    function withdraw(address _for)
        public
        override
        updateReward(_for)
        onlyOwners
    {
        emit Withdrawn(_for);
    }

    function getReward(address _for)
        public
        override
        nonReentrant
        updateReward(_for)
    {
        uint256 reward = earned(_for);

        if (reward > 0) {
            rewards[_for] = 0;

            if (rewardToken != address(0)) {
                IERC20(rewardToken).safeTransfer(_for, reward);
            } else {
                require(
                    address(this).balance >= reward,
                    "BaseReward: !address(this).balance"
                );

                payable(_for).sendValue(reward);
            }

            emit RewardPaid(_for, reward);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        updateReward(address(0))
        onlyOwners
    {
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(
            reward < uint256(-1) / 1e18,
            "the notified reward cannot invoke multiplication overflow"
        );

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IVirtualBalanceWrapperFactory {
    function createWrapper(address _op) external returns (address);
}

interface IVirtualBalanceWrapper {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function stakeFor(address _for, uint256 _amount) external returns (bool);
    function withdrawFor(address _for, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IBaseReward {
    function earned(address account) external view returns (uint256);
    function stake(address _for) external;
    function withdraw(address _for) external;
    function getReward(address _for) external;
    function notifyRewardAmount(uint256 reward) external;
    function addOwner(address _newOwner) external;
    function addOwners(address[] calldata _newOwners) external;
    function removeOwner(address _owner) external;
    function isOwner(address _owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../common/IVirtualBalanceWrapper.sol";
import "../common/BaseReward.sol";

contract SupplyRewardFactory {
    event NewOwner(address indexed sender, address operator);
    event RemoveOwner(address indexed sender, address operator);
    event CreateReward(address pool, address rewardToken);

    mapping(address => bool) private owners;

    modifier onlyOwners() {
        require(
            isOwner(msg.sender),
            "SupplyRewardFactory: caller is not an owner"
        );
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address _newOwner) public onlyOwners {
        require(
            !isOwner(_newOwner),
            "SupplyRewardFactory: address is already owner"
        );

        owners[_newOwner] = true;

        emit NewOwner(msg.sender, _newOwner);
    }

    function addOwners(address[] calldata _newOwners) external onlyOwners {
        for (uint256 i = 0; i < _newOwners.length; i++) {
            addOwner(_newOwners[i]);
        }
    }

    function removeOwner(address _owner) external onlyOwners {
        require(isOwner(_owner), "SupplyRewardFactory: address is not owner");

        owners[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) public onlyOwners returns (address) {
        BaseReward pool = new BaseReward(
            _rewardToken,
            _virtualBalance,
            _owner
        );

        emit CreateReward(address(pool), _rewardToken);

        return address(pool);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/
pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./common/IVirtualBalanceWrapper.sol";
import "./supply/SupplyInterfaces.sol";

contract SupplyBooster is Initializable, ReentrancyGuard, ISupplyBooster {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    address public supplyRewardFactory;
    address public virtualBalanceWrapperFactory;
    address public extraReward;
    uint256 public launchTime;
    uint256 public version;

    address payable public teamFeeAddress;
    address public lendingMarket;

    address public owner;
    address public governance;

    struct PoolInfo {
        address underlyToken;
        address rewardInterestPool;
        address supplyTreasuryFund;
        address virtualBalance;
        bool isErc20;
        bool shutdown;
    }

    enum LendingInfoState {
        NONE,
        LOCK,
        UNLOCK,
        LIQUIDATE
    }

    struct LendingInfo {
        uint256 pid;
        address user;
        address underlyToken;
        uint256 lendingAmount;
        uint256 borrowNumbers;
        uint256 startedBlock;
        LendingInfoState state;
    }

    address public constant ZERO_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MIN_INTEREST_PERCENT = 0;
    uint256 public constant MAX_INTEREST_PERCENT = 100;
    uint256 public constant FEE_PERCENT = 10;
    uint256 public constant PERCENT_DENOMINATOR = 100;

    PoolInfo[] public override poolInfo;

    uint256 public interestPercent;

    mapping(uint256 => uint256) public frozenTokens; /* pool id => amount */
    mapping(bytes32 => LendingInfo) public lendingInfos;
    mapping(uint256 => uint256) public interestTotal;

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);

    event Borrow(
        address indexed user,
        uint256 indexed pid,
        bytes32 indexed lendingId,
        uint256 lendingAmount,
        uint256 lendingInterest,
        uint256 borrowNumbers
    );
    event RepayBorrow(
        bytes32 indexed lendingId,
        address indexed user,
        uint256 lendingAmount,
        uint256 lendingInterest,
        bool isErc20
    );
    event Liquidate(
        bytes32 indexed lendingId,
        uint256 lendingAmount,
        uint256 lendingInterest
    );
    event Initialized(address indexed thisAddress);
    event ToggleShutdownPool(uint256 pid, bool shutdown);
    event SetOwner(address owner);
    event SetGovernance(address governance);

    modifier onlyOwner() {
        require(owner == msg.sender, "SupplyBooster: caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "SupplyBooster: caller is not the governance"
        );
        _;
    }

    modifier onlyLendingMarket() {
        require(
            lendingMarket == msg.sender,
            " SupplyBooster: caller is not the lendingMarket"
        );

        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    /* 
    The default governance user is GenerateLendingPools contract.
    It will be set to DAO in the future 
    */
    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function setLendingMarket(address _v) public onlyOwner {
        require(_v != address(0), "!_v");

        lendingMarket = _v;
    }

    function setExtraReward(address _v) public onlyOwner {
        require(_v != address(0), "!_v");

        extraReward = _v;
    }

    function initialize(
        address _owner,
        address _virtualBalanceWrapperFactory,
        address _supplyRewardFactory,
        address payable _teamFeeAddress
    ) public initializer {
        owner = _owner;
        governance = _owner;
        virtualBalanceWrapperFactory = _virtualBalanceWrapperFactory;
        supplyRewardFactory = _supplyRewardFactory;
        teamFeeAddress = _teamFeeAddress;
        launchTime = block.timestamp;
        version = 1;
        interestPercent = 50;

        emit Initialized(address(this));
    }

    function addSupplyPool(address _underlyToken, address _supplyTreasuryFund)
        public
        override
        onlyGovernance
        returns (bool)
    {
        bool isErc20 = _underlyToken == ZERO_ADDRESS ? false : true;
        address virtualBalance = IVirtualBalanceWrapperFactory(
            virtualBalanceWrapperFactory
        ).createWrapper(address(this));

        ISupplyTreasuryFund(_supplyTreasuryFund).initialize(
            virtualBalance,
            _underlyToken,
            isErc20
        );

        address rewardInterestPool;

        if (isErc20) {
            rewardInterestPool = ISupplyRewardFactory(supplyRewardFactory)
                .createReward(_underlyToken, virtualBalance, address(this));
        } else {
            rewardInterestPool = ISupplyRewardFactory(supplyRewardFactory)
                .createReward(address(0), virtualBalance, address(this));
        }

        if (extraReward != address(0)) {
            ISupplyPoolExtraReward(extraReward).addExtraReward(
                poolInfo.length,
                _underlyToken,
                virtualBalance,
                isErc20
            );
        }

        poolInfo.push(
            PoolInfo({
                underlyToken: _underlyToken,
                rewardInterestPool: rewardInterestPool,
                supplyTreasuryFund: _supplyTreasuryFund,
                virtualBalance: virtualBalance,
                isErc20: isErc20,
                shutdown: false
            })
        );

        return true;
    }

    function updateSupplyTreasuryFund(
        uint256 _pid,
        address _supplyTreasuryFund,
        bool _setReward
    ) public onlyOwner nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 bal = ISupplyTreasuryFund(pool.supplyTreasuryFund).migrate(
            _supplyTreasuryFund,
            _setReward
        );

        ISupplyTreasuryFund(_supplyTreasuryFund).initialize(
            pool.virtualBalance,
            pool.underlyToken,
            pool.isErc20
        );

        pool.supplyTreasuryFund = _supplyTreasuryFund;

        if (pool.isErc20) {
            sendToken(pool.underlyToken, pool.supplyTreasuryFund, bal);

            ISupplyTreasuryFund(pool.supplyTreasuryFund).depositFor(
                address(0),
                bal
            );
        } else {
            ISupplyTreasuryFund(pool.supplyTreasuryFund).depositFor{value: bal}(
                address(0)
            );
        }
    }

    function toggleShutdownPool(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        pool.shutdown = !pool.shutdown;

        if (extraReward != address(0)) {
            ISupplyPoolExtraReward(extraReward).toggleShutdownPool(
                _pid,
                pool.shutdown
            );
        }

        emit ToggleShutdownPool(_pid, pool.shutdown);
    }

    function _deposit(uint256 _pid, uint256 _amount) internal nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];

        require(!pool.shutdown, "SupplyBooster: !shutdown");
        require(_amount > 0, "SupplyBooster: !_amount");

        if (!pool.isErc20) {
            require(
                msg.value == _amount,
                "SupplyBooster: !msg.value == _amount"
            );
        }

        if (pool.isErc20) {
            IERC20(pool.underlyToken).safeTransferFrom(
                msg.sender,
                pool.supplyTreasuryFund,
                _amount
            );

            ISupplyTreasuryFund(pool.supplyTreasuryFund).depositFor(
                msg.sender,
                _amount
            );
        } else {
            ISupplyTreasuryFund(pool.supplyTreasuryFund).depositFor{
                value: _amount
            }(msg.sender);
        }

        IBaseReward(pool.rewardInterestPool).stake(msg.sender);

        if (extraReward != address(0)) {
            ISupplyPoolExtraReward(extraReward).beforeStake(_pid, msg.sender);
        }

        IVirtualBalanceWrapper(pool.virtualBalance).stakeFor(
            msg.sender,
            _amount
        );

        if (extraReward != address(0)) {
            ISupplyPoolExtraReward(extraReward).afterStake(_pid, msg.sender);
        }

        emit Deposited(msg.sender, _pid, _amount);
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        _deposit(_pid, _amount);
    }

    function deposit(uint256 _pid) public payable {
        _deposit(_pid, msg.value);
    }

    function withdraw(uint256 _pid, uint256 _amount)
        public
        nonReentrant
        returns (bool)
    {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 depositAmount = IVirtualBalanceWrapper(pool.virtualBalance)
            .balanceOf(msg.sender);

        require(_amount <= depositAmount, "SupplyBooster: !depositAmount");

        IBaseReward(pool.rewardInterestPool).withdraw(msg.sender);

        ISupplyTreasuryFund(pool.supplyTreasuryFund).withdrawFor(
            msg.sender,
            _amount
        );

        if (extraReward != address(0)) {
            ISupplyPoolExtraReward(extraReward).beforeWithdraw(
                _pid,
                msg.sender
            );
        }

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(
            msg.sender,
            _amount
        );

        if (extraReward != address(0)) {
            ISupplyPoolExtraReward(extraReward).afterWithdraw(_pid, msg.sender);
        }

        emit Withdrawn(msg.sender, _pid, _amount);

        return true;
    }

    receive() external payable {}

    function claimTreasuryFunds() public nonReentrant {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].shutdown) {
                continue;
            }

            uint256 interest = ISupplyTreasuryFund(
                poolInfo[i].supplyTreasuryFund
            ).claim();

            if (interest > 0) {
                if (poolInfo[i].isErc20) {
                    sendToken(
                        poolInfo[i].underlyToken,
                        poolInfo[i].rewardInterestPool,
                        interest
                    );
                } else {
                    sendToken(
                        address(0),
                        poolInfo[i].rewardInterestPool,
                        interest
                    );
                }

                IBaseReward(poolInfo[i].rewardInterestPool).notifyRewardAmount(
                    interest
                );
            }
        }
    }

    function getRewards(uint256[] memory _pids) public nonReentrant {
        for (uint256 i = 0; i < _pids.length; i++) {
            PoolInfo storage pool = poolInfo[_pids[i]];

            if (pool.shutdown) continue;

            ISupplyTreasuryFund(pool.supplyTreasuryFund).getReward(msg.sender);

            if (IBaseReward(pool.rewardInterestPool).earned(msg.sender) > 0) {
                IBaseReward(pool.rewardInterestPool).getReward(msg.sender);
            }

            if (extraReward != address(0)) {
                ISupplyPoolExtraReward(extraReward).getRewards(
                    _pids[i],
                    msg.sender
                );
            }
        }
    }

    function setInterestPercent(uint256 _v) public onlyGovernance {
        require(
            _v >= MIN_INTEREST_PERCENT && _v <= MAX_INTEREST_PERCENT,
            "!_v"
        );

        interestPercent = _v;
    }

    function setTeamFeeAddress(address _v) public {
        require(msg.sender == teamFeeAddress, "!teamAddress");
        require(_v != address(0), "!_v");

        teamFeeAddress = payable(_v);
    }

    function calculateAmount(
        uint256 _bal,
        bool _fee,
        bool _interest,
        bool _extra
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = _fee ? _bal.mul(FEE_PERCENT).div(PERCENT_DENOMINATOR) : 0;
        uint256 interest = _bal.sub(fee).mul(interestPercent).div(
            PERCENT_DENOMINATOR
        );
        uint256 extra = _bal.sub(fee).sub(interest);

        if (!_extra) extra = 0;
        if (!_interest) interest = 0;

        return (fee, interest, extra);
    }

    function sendToken(
        address _token,
        address _receiver,
        uint256 _amount
    ) internal {
        if (_token == address(0) || _token == ZERO_ADDRESS) {
            payable(_receiver).sendValue(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    function sendBalanceEther(
        uint256 _pid,
        uint256 _bal,
        bool _fee,
        bool _interest,
        bool _extra
    ) internal {
        if (_bal == 0) return;

        PoolInfo storage pool = poolInfo[_pid];

        (uint256 fee, uint256 interest, uint256 extra) = calculateAmount(
            _bal,
            _fee,
            _interest,
            _extra
        );

        if (fee > 0) {
            sendToken(pool.underlyToken, teamFeeAddress, fee);
        }

        if (extraReward == address(0)) {
            interest = interest.add(extra);
        } else {
            ISupplyPoolExtraReward(extraReward).notifyRewardAmount{
                value: extra
            }(_pid, address(0), extra);
        }

        if (interest > 0) {
            sendToken(pool.underlyToken, pool.rewardInterestPool, interest);

            IBaseReward(pool.rewardInterestPool).notifyRewardAmount(interest);
        }
    }

    function sendBalanceErc20(
        uint256 _pid,
        uint256 _bal,
        bool _fee,
        bool _interest,
        bool _extra
    ) internal {
        if (_bal == 0) return;

        PoolInfo storage pool = poolInfo[_pid];

        (uint256 fee, uint256 interest, uint256 extra) = calculateAmount(
            _bal,
            _fee,
            _interest,
            _extra
        );

        if (fee > 0) {
            sendToken(pool.underlyToken, teamFeeAddress, fee);
        }

        if (extraReward == address(0)) {
            interest = interest.add(extra);
        } else {
            sendToken(pool.underlyToken, extraReward, extra);

            ISupplyPoolExtraReward(extraReward).notifyRewardAmount(
                _pid,
                pool.underlyToken,
                extra
            );
        }

        if (interest > 0) {
            sendToken(pool.underlyToken, pool.rewardInterestPool, interest);

            IBaseReward(pool.rewardInterestPool).notifyRewardAmount(interest);
        }
    }

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest,
        uint256 _borrowNumbers
    ) public override onlyLendingMarket nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];

        require(!pool.shutdown, "SupplyBooster: !shutdown");

        ISupplyTreasuryFund(pool.supplyTreasuryFund).borrow(
            _user,
            _lendingAmount,
            _lendingInterest
        );

        frozenTokens[_pid] = frozenTokens[_pid].add(_lendingAmount);
        interestTotal[_pid] = interestTotal[_pid].add(_lendingInterest);

        LendingInfo memory lendingInfo;

        lendingInfo.pid = _pid;
        lendingInfo.user = _user;
        lendingInfo.underlyToken = pool.underlyToken;
        lendingInfo.lendingAmount = _lendingAmount;
        lendingInfo.borrowNumbers = _borrowNumbers;
        lendingInfo.startedBlock = block.number;
        lendingInfo.state = LendingInfoState.LOCK;

        lendingInfos[_lendingId] = lendingInfo;

        if (pool.isErc20) {
            sendBalanceErc20(
                lendingInfo.pid,
                _lendingInterest,
                true,
                true,
                true
            );
        } else {
            sendBalanceEther(
                lendingInfo.pid,
                _lendingInterest,
                true,
                true,
                true
            );
        }

        emit Borrow(
            _user,
            _pid,
            _lendingId,
            _lendingAmount,
            _lendingInterest,
            _borrowNumbers
        );
    }

    function _repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) internal nonReentrant {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];
        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        require(
            lendingInfo.state == LendingInfoState.LOCK,
            "SupplyBooster: !LOCK"
        );
        require(
            _lendingAmount >= lendingInfo.lendingAmount,
            "SupplyBooster: !_lendingAmount"
        );

        frozenTokens[lendingInfo.pid] = frozenTokens[lendingInfo.pid].sub(
            lendingInfo.lendingAmount
        );
        interestTotal[lendingInfo.pid] = interestTotal[lendingInfo.pid].sub(
            _lendingInterest
        );

        if (pool.isErc20) {
            sendToken(
                pool.underlyToken,
                pool.supplyTreasuryFund,
                lendingInfo.lendingAmount
            );

            ISupplyTreasuryFund(pool.supplyTreasuryFund).repayBorrow(
                lendingInfo.lendingAmount
            );
        } else {
            ISupplyTreasuryFund(pool.supplyTreasuryFund).repayBorrow{
                value: lendingInfo.lendingAmount
            }();
        }

        lendingInfo.state = LendingInfoState.UNLOCK;

        emit RepayBorrow(
            _lendingId,
            _user,
            _lendingAmount,
            _lendingInterest,
            pool.isErc20
        );
    }

    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingInterest
    ) external payable override onlyLendingMarket {
        _repayBorrow(_lendingId, _user, msg.value, _lendingInterest);
    }

    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) external override onlyLendingMarket {
        _repayBorrow(_lendingId, _user, _lendingAmount, _lendingInterest);
    }

    function liquidate(bytes32 _lendingId, uint256 _lendingInterest)
        public
        payable
        override
        onlyLendingMarket
        nonReentrant
        returns (address)
    {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];
        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        if (!pool.isErc20) {
            require(
                msg.value > 0,
                "SupplyBooster: msg.value must be greater than 0"
            );
        }

        require(
            lendingInfo.state == LendingInfoState.LOCK,
            "SupplyBooster: !LOCK"
        );

        frozenTokens[lendingInfo.pid] = frozenTokens[lendingInfo.pid].sub(
            lendingInfo.lendingAmount
        );
        interestTotal[lendingInfo.pid] = interestTotal[lendingInfo.pid].sub(
            _lendingInterest
        );

        if (pool.isErc20) {
            sendToken(
                pool.underlyToken,
                pool.supplyTreasuryFund,
                lendingInfo.lendingAmount
            );

            ISupplyTreasuryFund(pool.supplyTreasuryFund).repayBorrow(
                lendingInfo.lendingAmount
            );

            uint256 bal = IERC20(pool.underlyToken).balanceOf(address(this));

            sendBalanceErc20(lendingInfo.pid, bal, true, true, true);
        } else {
            ISupplyTreasuryFund(pool.supplyTreasuryFund).repayBorrow{
                value: lendingInfo.lendingAmount
            }();

            uint256 bal = address(this).balance;

            sendBalanceEther(lendingInfo.pid, bal, true, true, true);
        }

        lendingInfo.state = LendingInfoState.LIQUIDATE;

        emit Liquidate(_lendingId, lendingInfo.lendingAmount, _lendingInterest);
    }

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function getUtilizationRate(uint256 _pid)
        public
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 currentBal = ISupplyTreasuryFund(pool.supplyTreasuryFund)
            .getBalance();

        if (currentBal.add(frozenTokens[_pid]) == 0) {
            return 0;
        }

        return
            frozenTokens[_pid].mul(1e18).div(
                currentBal.add(frozenTokens[_pid])
            );
    }

    function getBorrowRatePerBlock(uint256 _pid)
        public
        view
        override
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];

        return
            ISupplyTreasuryFund(pool.supplyTreasuryFund)
                .getBorrowRatePerBlock();
    }

    function getLendingUnderlyToken(bytes32 _lendingId)
        public
        view
        override
        returns (address)
    {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];

        return (lendingInfo.underlyToken);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "../common/IBaseReward.sol";
import "./ISupplyBooster.sol";

interface ISupplyPoolExtraReward {
    function addExtraReward( uint256 _pid, address _lpToken, address _virtualBalance, bool _isErc20) external;
    function toggleShutdownPool(uint256 _pid, bool _state) external;
    function getRewards(uint256 _pid,address _for) external;
    function beforeStake(uint256 _pid, address _for) external;
    function afterStake(uint256 _pid, address _for) external;
    function beforeWithdraw(uint256 _pid, address _for) external;
    function afterWithdraw(uint256 _pid, address _for) external;
    function notifyRewardAmount( uint256 _pid, address _underlyToken, uint256 _amount) external payable;
}

interface ISupplyTreasuryFund {
    function initialize(address _virtualBalance, address _underlyToken, bool _isErc20) external;
    function depositFor(address _for) external payable;
    function depositFor(address _for, uint256 _amount) external;
    function withdrawFor(address _to, uint256 _amount) external  returns (uint256);
    function borrow(address _to, uint256 _lendingAmount,uint256 _lendingInterest) external returns (uint256);
    function repayBorrow() external payable;
    function repayBorrow(uint256 _lendingAmount) external;
    function claimComp(address _comp, address _comptroller, address _to) external returns (uint256, bool);
    function getBalance() external view returns (uint256);
    function getBorrowRatePerBlock() external view returns (uint256);
    function claim() external returns(uint256);
    function migrate(address _newTreasuryFund, bool _setReward) external returns(uint256);
    function getReward(address _for) external;
}

interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface ISupplyBooster {
    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address underlyToken,
            address rewardInterestPool,
            address supplyTreasuryFund,
            address virtualBalance,
            bool isErc20,
            bool shutdown
        );

    function liquidate(bytes32 _lendingId, uint256 _lendingInterest)
        external
        payable
        returns (address);

    function getLendingUnderlyToken(bytes32 _lendingId)
        external
        view
        returns (address);

    function borrow(
        uint256 _pid,
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest,
        uint256 _borrowNumbers
    ) external;

    // ether
    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingInterest
    ) external payable;

    // erc20
    function repayBorrow(
        bytes32 _lendingId,
        address _user,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) external;

    function addSupplyPool(address _underlyToken, address _supplyTreasuryFund)
        external
        returns (bool);

    function getBorrowRatePerBlock(uint256 _pid)
        external
        view
        returns (uint256);

    function getUtilizationRate(uint256 _pid) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../common/IVirtualBalanceWrapper.sol";
import "../common/IBaseReward.sol";
import "./ISupplyBooster.sol";

interface ILendFlareGauge {
    function updateReward(address addr) external returns (bool);
}

interface ILendFlareMinter {
    function mintFor(address gauge_addr, address _for) external;
}

interface ILendflareToken {
    function minter() external view returns (address);
}

interface ISupplyPoolGaugeFactory {
    function createGauge(
        address _virtualBalance,
        address _lendflareToken,
        address _lendflareVotingEscrow,
        address _lendflareGaugeModel,
        address _lendflareTokenMinter
    ) external returns (address);
}

interface ILendflareGaugeModel {
    function addGauge(address _gauge, uint256 _weight) external;

    function toggleGauge(address _gauge, bool _state) external;
}

interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}

contract SupplyPoolExtraRewardFactory is ReentrancyGuard {
    using Address for address payable;
    using SafeERC20 for IERC20;

    address public owner;

    address public supplyBooster;
    address public supplyRewardFactory;
    address public supplyPoolGaugeFactory;
    address public lendflareVotingEscrow;
    address public lendflareToken;
    address public lendflareGaugeModel;

    mapping(uint256 => address) public veLendFlarePool; // pid => extra rewards
    mapping(uint256 => address) public gaugePool; // pid => extra rewards

    constructor(
        address _supplyBooster,
        address _supplyRewardFactory,
        address _supplyPoolGaugeFactory,
        address _lendflareGaugeModel,
        address _lendflareVotingEscrow,
        address _lendflareToken
    ) public {
        owner = msg.sender;

        supplyBooster = _supplyBooster;
        supplyRewardFactory = _supplyRewardFactory;
        supplyPoolGaugeFactory = _supplyPoolGaugeFactory;
        lendflareVotingEscrow = _lendflareVotingEscrow;
        lendflareToken = _lendflareToken;
        lendflareGaugeModel = _lendflareGaugeModel;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "SupplyPoolExtraRewardFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createPool(
        uint256 _pid,
        address _underlyToken,
        address _virtualBalance,
        bool _isErc20
    ) internal {
        address lendflareMinter = ILendflareToken(lendflareToken).minter();
        require(lendflareMinter != address(0), "!lendflareMinter");

        address poolGauge = ISupplyPoolGaugeFactory(supplyPoolGaugeFactory)
            .createGauge(
                _virtualBalance,
                lendflareToken,
                lendflareVotingEscrow,
                lendflareGaugeModel,
                lendflareMinter
            );

        // default weight = 100 * 1e18
        ILendflareGaugeModel(lendflareGaugeModel).addGauge(poolGauge, 100e18);

        address rewardVeLendFlarePool;

        if (_isErc20) {
            rewardVeLendFlarePool = ISupplyRewardFactory(supplyRewardFactory)
                .createReward(
                    _underlyToken,
                    lendflareVotingEscrow,
                    address(this)
                );
        } else {
            rewardVeLendFlarePool = ISupplyRewardFactory(supplyRewardFactory)
                .createReward(address(0), lendflareVotingEscrow, address(this));
        }

        IBaseReward(rewardVeLendFlarePool).addOwner(lendflareVotingEscrow);

        veLendFlarePool[_pid] = rewardVeLendFlarePool;
        gaugePool[_pid] = poolGauge;
    }

    function updateOldPool(uint256 _pid) public {
        require(
            msg.sender == owner,
            "SupplyPoolExtraRewardFactory: !authorized updateOldPool"
        );
        require(veLendFlarePool[_pid] == address(0), "!veLendFlarePool");
        require(gaugePool[_pid] == address(0), "!gaugePool");

        (
            address underlyToken,
            ,
            ,
            address virtualBalance,
            bool isErc20,

        ) = ISupplyBooster(supplyBooster).poolInfo(_pid);

        createPool(_pid, underlyToken, virtualBalance, isErc20);
    }

    function addExtraReward(
        uint256 _pid,
        address _lpToken,
        address _virtualBalance,
        bool _isErc20
    ) public {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized addExtraReward"
        );

        createPool(_pid, _lpToken, _virtualBalance, _isErc20);
    }

    function toggleShutdownPool(uint256 _pid, bool _state) public {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized toggleShutdownPool"
        );

        ILendflareGaugeModel(lendflareGaugeModel).toggleGauge(
            gaugePool[_pid],
            _state
        );
    }

    function getRewards(uint256 _pid, address _for) public nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized getRewards"
        );

        address lendflareMinter = ILendflareToken(lendflareToken).minter();

        if (lendflareMinter != address(0)) {
            ILendFlareMinter(lendflareMinter).mintFor(gaugePool[_pid], _for);
        }
    }

    function beforeStake(uint256 _pid, address _for) public nonReentrant {}

    function afterStake(uint256 _pid, address _for) public nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized afterStake"
        );

        ILendFlareGauge(gaugePool[_pid]).updateReward(_for);
    }

    function beforeWithdraw(uint256 _pid, address _for) public nonReentrant {}

    function afterWithdraw(uint256 _pid, address _for) public nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized afterWithdraw"
        );

        ILendFlareGauge(gaugePool[_pid]).updateReward(_for);
    }

    function getVeLFTUserRewards(uint256[] memory _pids) public nonReentrant {
        for (uint256 i = 0; i < _pids.length; i++) {
            if (IBaseReward(veLendFlarePool[_pids[i]]).earned(msg.sender) > 0) {
                IBaseReward(veLendFlarePool[_pids[i]]).getReward(msg.sender);
            }
        }
    }

    function notifyRewardAmount(
        uint256 _pid,
        address _underlyToken,
        uint256 _amount
    ) public payable nonReentrant {
        require(
            msg.sender == supplyBooster,
            "SupplyPoolExtraRewardFactory: !authorized notifyRewardAmount"
        );

        if (_underlyToken == address(0)) {
            payable(veLendFlarePool[_pid]).sendValue(_amount);
        } else {
            IERC20(_underlyToken).safeTransfer(veLendFlarePool[_pid], _amount);
        }

        IBaseReward(veLendFlarePool[_pid]).notifyRewardAmount(_amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "./common/IBaseReward.sol";

contract LendFlareVotingEscrow is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 constant WEEK = 1 weeks; // all future times are rounded by week
    uint256 constant MAXTIME = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIER = 10**18;

    uint256 private _totalSupply;

    string private constant _name = "Vote-escrowed LFT";
    string private constant _symbol = "VeLFT";
    uint8 private constant _decimals = 18;
    string private _version;
    address public token;
    uint256 public epoch;

    enum DepositTypes {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    struct Point {
        uint256 bias;
        uint256 slope; // dweight / dt
        uint256 ts; // timestamp
        uint256 blk; // block number
    }

    struct LockedBalance {
        uint256 amount;
        uint256 end;
    }

    IBaseReward[] public reward_pools;

    mapping(uint256 => Point) public point_history; // epoch -> unsigned point
    mapping(address => mapping(uint256 => Point)) public user_point_history; // user -> Point[user_epoch]
    mapping(address => uint256) public user_point_epoch;
    mapping(uint256 => uint256) public slope_changes; // time -> signed slope change
    mapping(address => LockedBalance) public locked;

    address public owner;

    event Deposit(
        address indexed provider,
        uint256 value,
        uint256 indexed locktime,
        DepositTypes depositTypes,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event SetMinter(address minter);
    event SetOwner(address owner);

    function initialize(
        string memory version_,
        address token_addr_,
        address owner_
    ) public initializer {
        _version = version_;
        token = token_addr_;
        owner = owner_;
    }

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "LendFlareVotingEscrow: caller is not the owner"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function rewardPoolsLength() external view returns (uint256) {
        return reward_pools.length;
    }

    function addRewardPool(address _v) external onlyOwner returns (bool) {
        require(_v != address(0), "!_v");

        reward_pools.push(IBaseReward(_v));

        return true;
    }

    function clearRewardPools() external onlyOwner {
        delete reward_pools;
    }

    function getLastUserSlope(address addr) external view returns (uint256) {
        uint256 uepoch = user_point_epoch[addr];

        return user_point_history[addr][uepoch].slope;
    }

    function userPointHistoryTs(address _addr, uint256 _idx)
        external
        view
        returns (uint256)
    {
        return user_point_history[_addr][_idx].ts;
    }

    function lockedEnd(address _addr) external view returns (uint256) {
        return locked[_addr].end;
    }

    function _checkpoint(
        address addr,
        LockedBalance memory old_locked,
        LockedBalance storage new_locked
    ) internal {
        Point memory u_old;
        Point memory u_new;
        uint256 old_dslope = 0;
        uint256 new_dslope = 0;

        if (addr != address(0)) {
            if (old_locked.end > block.timestamp && old_locked.amount > 0) {
                u_old.slope = old_locked.amount / MAXTIME;
                u_old.bias = u_old.slope * (old_locked.end - block.timestamp);
            }

            if (new_locked.end > block.timestamp && new_locked.amount > 0) {
                u_new.slope = new_locked.amount / MAXTIME;
                u_new.bias = u_new.slope * (new_locked.end - block.timestamp);
            }

            old_dslope = slope_changes[old_locked.end];

            if (new_locked.end != 0) {
                if (new_locked.end == old_locked.end) new_dslope = old_dslope;
                else new_dslope = slope_changes[new_locked.end];
            }
        }

        Point memory last_point = Point({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number
        });

        if (epoch > 0) {
            last_point = point_history[epoch];
        }

        uint256 last_checkpoint = last_point.ts;
        Point memory initial_last_point = last_point;
        uint256 block_slope = 0; // dblock/dt

        if (block.timestamp > last_point.ts) {
            block_slope =
                (MULTIPLIER * (block.number - last_point.blk)) /
                (block.timestamp - last_point.ts);
        }

        uint256 t_i = (last_checkpoint / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            uint256 d_slope = 0;
            t_i += WEEK;

            if (t_i > block.timestamp) t_i = block.timestamp;
            else d_slope = slope_changes[t_i];

            last_point.bias -= last_point.slope * (t_i - last_checkpoint);
            last_point.slope += d_slope;

            if (last_point.bias < 0) last_point.bias = 0;

            if (last_point.slope < 0) last_point.slope = 0;

            last_checkpoint = t_i;
            last_point.ts = t_i;
            last_point.blk =
                initial_last_point.blk +
                (block_slope * (t_i - initial_last_point.ts)) /
                MULTIPLIER;
            epoch += 1;

            if (t_i == block.timestamp) {
                last_point.blk = block.number;
                break;
            } else {
                point_history[epoch] = last_point;
            }
        }

        if (addr != address(0)) {
            last_point.slope += (u_new.slope - u_old.slope);
            last_point.bias += (u_new.bias - u_old.bias);

            if (last_point.slope < 0) last_point.slope = 0;
            if (last_point.bias < 0) last_point.bias = 0;
        }

        // Record the changed point into history
        point_history[epoch] = last_point;

        if (addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [new_locked.end]
            // and add old_user_slope to [old_locked.end]
            if (old_locked.end > block.timestamp) {
                // old_dslope was <something> - u_old.slope, so we cancel that
                old_dslope += u_old.slope;

                if (new_locked.end == old_locked.end) old_dslope -= u_new.slope; // It was a new deposit, not extension

                slope_changes[old_locked.end] = old_dslope;
            }

            if (new_locked.end > block.timestamp) {
                if (new_locked.end > old_locked.end) {
                    new_dslope -= u_new.slope; // old slope disappeared at this point
                    slope_changes[new_locked.end] = new_dslope;
                }
            }

            // Now handle user history
            uint256 user_epoch = user_point_epoch[addr] + 1;

            user_point_epoch[addr] = user_epoch;
            u_new.ts = block.timestamp;
            u_new.blk = block.number;
            user_point_history[addr][user_epoch] = u_new;
        }
    }

    function _depositFor(
        address _addr,
        uint256 _value,
        uint256 unlock_time,
        LockedBalance storage _locked,
        DepositTypes depositTypes
    ) internal {
        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before + _value;
        LockedBalance memory old_locked = _locked;

        _locked.amount += _value;

        if (unlock_time != 0) {
            _locked.end = unlock_time;
        }

        for (uint256 i = 0; i < reward_pools.length; i++) {
            reward_pools[i].stake(_addr);
        }

        _checkpoint(_addr, old_locked, _locked);

        if (_value != 0) {
            IERC20(token).safeTransferFrom(_addr, address(this), _value);
        }

        emit Deposit(_addr, _value, _locked.end, depositTypes, block.timestamp);
        emit Supply(supply_before, supply_before + _value);
    }

    function depositFor(address _addr, uint256 _value) external nonReentrant {
        LockedBalance storage _locked = locked[_addr];

        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "no existing lock found");
        require(
            _locked.end > block.timestamp,
            "cannot add to expired lock. Withdraw"
        );

        _depositFor(
            _addr,
            _value,
            0,
            _locked,
            DepositTypes.DEPOSIT_FOR_TYPE
        );
    }

    function createLock(uint256 _value, uint256 _unlock_time)
        external
        nonReentrant
    {
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;
        LockedBalance storage _locked = locked[msg.sender];

        require(_value > 0, "need non-zero value");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(
            unlock_time > block.timestamp,
            "can only lock until time in the future"
        );
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            _value,
            unlock_time,
            _locked,
            DepositTypes.CREATE_LOCK_TYPE
        );
    }

    function increaseAmount(uint256 _value) external nonReentrant {
        LockedBalance storage _locked = locked[msg.sender];
        require(_value > 0, "need non-zero value");
        require(_locked.amount > 0, "No existing lock found");
        require(
            _locked.end > block.timestamp,
            "Cannot add to expired lock. Withdraw"
        );

        _depositFor(
            msg.sender,
            _value,
            0,
            _locked,
            DepositTypes.INCREASE_LOCK_AMOUNT
        );
    }

    function increaseUnlockTime(uint256 _unlock_time) external nonReentrant {
        LockedBalance storage _locked = locked[msg.sender];
        uint256 unlock_time = (_unlock_time / WEEK) * WEEK;

        require(_locked.end > block.timestamp, "Lock expired");
        require(_locked.amount > 0, "Nothing is locked");
        require(unlock_time > _locked.end, "Can only increase lock duration");
        require(
            unlock_time <= block.timestamp + MAXTIME,
            "Voting lock can be 4 years max"
        );

        _depositFor(
            msg.sender,
            0,
            unlock_time,
            _locked,
            DepositTypes.INCREASE_UNLOCK_TIME
        );
    }

    function withdraw() public nonReentrant {
        LockedBalance storage _locked = locked[msg.sender];

        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 locked_amount = _locked.amount;

        LockedBalance memory old_locked = _locked;

        _locked.end = 0;
        _locked.amount = 0;

        uint256 supply_before = _totalSupply;

        _totalSupply = supply_before - locked_amount;

        _checkpoint(msg.sender, old_locked, _locked);

        IERC20(token).safeTransfer(msg.sender, locked_amount);

        for (uint256 i = 0; i < reward_pools.length; i++) {
            reward_pools[i].withdraw(msg.sender);
        }

        emit Withdraw(msg.sender, locked_amount, block.timestamp);
        emit Supply(supply_before, supply_before - locked_amount);
    }

    function findBlockEpoch(uint256 _block, uint256 max_epoch)
        internal
        view
        returns (uint256)
    {
        uint256 _min = 0;
        uint256 _max = max_epoch;

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (point_history[_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        return _min;
    }

    function balanceOf(address addr, uint256 _t) public view returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = user_point_epoch[addr];

        if (_epoch == 0) {
            return 0;
        } else {
            Point memory last_point = user_point_history[addr][_epoch];

            require(_t >= last_point.ts, "!_t");

            last_point.bias -= last_point.slope * (_t - last_point.ts);

            if (last_point.bias < 0) {
                last_point.bias = 0;
            }

            return last_point.bias;
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return balanceOf(account, block.timestamp);
    }

    function balanceOfAt(address addr, uint256 _block)
        public
        view
        returns (uint256)
    {
        require(_block <= block.number);

        uint256 _min = 0;
        uint256 _max = user_point_epoch[addr];

        for (uint256 i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }

            uint256 _mid = (_min + _max + 1) / 2;

            if (user_point_history[addr][_mid].blk <= _block) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }

        Point memory upoint = user_point_history[addr][_min];

        uint256 current_point = findBlockEpoch(_block, epoch);
        Point memory point_0 = point_history[current_point];
        uint256 d_block = 0;
        uint256 d_t = 0;

        if (current_point < epoch) {
            Point memory point_1 = point_history[current_point + 1];
            d_block = point_1.blk - point_0.blk;
            d_t = point_1.ts - point_0.ts;
        } else {
            d_block = block.number - point_0.blk;
            d_t = block.timestamp - point_0.ts;
        }

        uint256 block_time = point_0.ts;

        if (d_block != 0) {
            block_time += (d_t * (_block - point_0.blk)) / d_block;
        }

        upoint.bias -= upoint.slope * (block_time - upoint.ts);

        if (upoint.bias >= 0) {
            return upoint.bias;
        } else {
            return 0;
        }
    }

    function supplyAt(Point memory point, uint256 t)
        internal
        view
        returns (uint256)
    {
        uint256 t_i = (point.ts / WEEK) * WEEK;

        for (uint256 i = 0; i < 255; i++) {
            t_i += WEEK;
            uint256 d_slope = 0;

            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = slope_changes[t_i];
            }

            require(t_i >= point.ts, "!t_i");

            point.bias -= point.slope * (t_i - point.ts);

            if (t_i == t) break;

            point.slope += d_slope;
            point.ts = t_i;
        }

        if (point.bias < 0) {
            point.bias = 0;
        }

        return point.bias;
    }

    function totalSupply(uint256 t) public view returns (uint256) {
        if (t == 0) {
            t = block.timestamp;
        }

        Point memory last_point = point_history[epoch];

        return supplyAt(last_point, t);
    }

    function totalSupplyAt(uint256 _block) public view returns (uint256) {
        require(_block <= block.number);

        uint256 target_epoch = findBlockEpoch(_block, epoch);

        Point memory point = point_history[target_epoch];
        uint256 dt = 0;

        if (target_epoch < epoch) {
            Point memory point_next = point_history[target_epoch + 1];

            if (point.blk != point_next.blk) {
                dt =
                    ((_block - point.blk) * (point_next.ts - point.ts)) /
                    (point_next.blk - point.blk);
            }
        } else {
            if (point.blk != block.number) {
                dt =
                    ((_block - point.blk) * (block.timestamp - point.ts)) /
                    (block.number - point.blk);
            }
        }

        return supplyAt(point, point.ts + dt);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./convex/IConvexBooster.sol";
import "./supply/ISupplyBooster.sol";

interface ICurveSwap {
    function calc_withdraw_one_coin(uint256 _tokenAmount, int128 _tokenId)
        external
        view
        returns (uint256);
}

interface ILendingSponsor {
    function addSponsor(bytes32 _lendingId, address _user) external payable;

    function payFee(bytes32 _lendingId, address payable _user) external;
}

contract LendingMarket is Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public convexBooster;
    address public supplyBooster;
    address public lendingSponsor;

    uint256 public liquidateThresholdBlockNumbers;
    uint256 public version;

    address public owner;
    address public governance;

    enum UserLendingState {
        LENDING,
        EXPIRED,
        LIQUIDATED
    }

    struct PoolInfo {
        uint256 convexPid;
        uint256[] supportPids;
        int128[] curveCoinIds;
        uint256 lendingThreshold;
        uint256 liquidateThreshold;
        uint256 borrowIndex;
    }

    struct UserLending {
        bytes32 lendingId;
        uint256 token0;
        uint256 token0Price;
        uint256 lendingAmount;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 supportPid;
        int128 curveCoinId;
        uint256 borrowNumbers;
    }

    struct LendingInfo {
        address user;
        uint256 pid;
        uint256 userLendingIndex;
        uint256 borrowIndex;
        uint256 startedBlock;
        uint256 utilizationRate;
        uint256 supplyRatePerBlock;
        UserLendingState state;
    }

    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 supplyAmount;
    }

    struct Statistic {
        uint256 totalCollateral;
        uint256 totalBorrow;
        uint256 recentRepayAt;
    }

    struct LendingParams {
        uint256 lendingAmount;
        uint256 borrowAmount;
        uint256 borrowInterest;
        uint256 lendingRate;
        uint256 utilizationRate;
        uint256 supplyRatePerBlock;
        address lpToken;
        uint256 token0Price;
    }

    PoolInfo[] public poolInfo;

    address public constant ZERO_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant MIN_LIQUIDATE_BLOCK_NUMBERS = 50;
    uint256 public constant MIN_LENDING_THRESHOLD = 100;
    uint256 public constant MIN_LIQUIDATE_THRESHOLD = 50;
    uint256 public constant MAX_LIQUIDATE_BLOCK_NUMBERS = 100;
    uint256 public constant MAX_LENDING_THRESHOLD = 300;
    uint256 public constant MAX_LIQUIDATE_THRESHOLD = 300;
    uint256 public constant SUPPLY_RATE_DENOMINATOR = 1e18;
    uint256 public constant MAX_LENDFLARE_TOTAL_RATE = 0.5 * 1e18;
    uint256 public constant THRESHOLD_DENOMINATOR = 1000;
    uint256 public constant BLOCKS_PER_YEAR = 2102400; // Reference Compound WhitePaperInterestRateModel contract
    uint256 public constant BLOCKS_PER_DAY = 5760;
    // user address => container
    mapping(address => UserLending[]) public userLendings;
    // lending id => user address
    mapping(bytes32 => LendingInfo) public lendings;
    // pool id => (borrowIndex => user lendingId)
    mapping(uint256 => mapping(uint256 => bytes32)) public poolLending;
    mapping(bytes32 => BorrowInfo) public borrowInfos;
    mapping(bytes32 => Statistic) public myStatistics;
    // number => bool
    mapping(uint256 => bool) public borrowBlocks;

    event LendingBase(
        bytes32 indexed lendingId,
        uint256 marketPid,
        uint256 supplyPid,
        int128 curveCoinId,
        uint256 borrowBlocks
    );

    event Borrow(
        bytes32 indexed lendingId,
        address indexed user,
        uint256 pid,
        uint256 token0,
        uint256 token0Price,
        uint256 lendingAmount,
        uint256 borrowNumber
    );
    event Initialized(address indexed thisAddress);
    event RepayBorrow(
        bytes32 indexed lendingId,
        address user,
        UserLendingState state
    );

    event Liquidate(
        bytes32 indexed lendingId,
        address user,
        uint256 liquidateAmount,
        uint256 gasSpent,
        UserLendingState state
    );

    event SetOwner(address owner);
    event SetGovernance(address governance);
    event SetBorrowBlock(uint256 borrowBlock, bool state);

    modifier onlyOwner() {
        require(owner == msg.sender, "LendingMarket: caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "LendingMarket: caller is not the governance"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    /* 
    The default governance user is GenerateLendingPools contract.
    It will be set to DAO in the future 
    */
    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function initialize(
        address _owner,
        address _lendingSponsor,
        address _convexBooster,
        address _supplyBooster
    ) public initializer {
        owner = _owner;
        governance = _owner;
        lendingSponsor = _lendingSponsor;
        convexBooster = _convexBooster;
        supplyBooster = _supplyBooster;

        

        setBorrowBlock(BLOCKS_PER_DAY * 90, true);
        setBorrowBlock(BLOCKS_PER_DAY * 180, true);
        setBorrowBlock(BLOCKS_PER_YEAR, true);

        liquidateThresholdBlockNumbers = 50;
        version = 1;

        emit Initialized(address(this));
    }

    function borrow(
        uint256 _pid,
        uint256 _token0,
        uint256 _borrowBlock,
        uint256 _supportPid
    ) public payable nonReentrant {
        require(borrowBlocks[_borrowBlock], "!borrowBlocks");
        require(msg.value == 0.1 ether, "!lendingSponsor");

        _borrow(_pid, _supportPid, _borrowBlock, _token0);
    }

    function _getCurveInfo(
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _token0
    ) internal view returns (address lpToken, uint256 token0Price) {
        address curveSwapAddress;

        (, curveSwapAddress, lpToken, , , , , , ) = IConvexBooster(
            convexBooster
        ).poolInfo(_convexPid);

        token0Price = ICurveSwap(curveSwapAddress).calc_withdraw_one_coin(
            _token0,
            _curveCoinId
        );
    }

    function _borrow(
        uint256 _pid,
        uint256 _supportPid,
        uint256 _borrowBlocks,
        uint256 _token0
    ) internal returns (LendingParams memory) {
        PoolInfo storage pool = poolInfo[_pid];

        pool.borrowIndex++;

        bytes32 lendingId = generateId(
            msg.sender,
            _pid,
            pool.borrowIndex + block.number
        );

        LendingParams memory lendingParams = getLendingInfo(
            _token0,
            pool.convexPid,
            pool.curveCoinIds[_supportPid],
            pool.supportPids[_supportPid],
            pool.lendingThreshold,
            pool.liquidateThreshold,
            _borrowBlocks
        );

        IERC20(lendingParams.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _token0
        );

        IERC20(lendingParams.lpToken).safeApprove(convexBooster, 0);
        IERC20(lendingParams.lpToken).safeApprove(convexBooster, _token0);

        ISupplyBooster(supplyBooster).borrow(
            pool.supportPids[_supportPid],
            lendingId,
            msg.sender,
            lendingParams.lendingAmount,
            lendingParams.borrowInterest,
            _borrowBlocks
        );

        IConvexBooster(convexBooster).depositFor(
            pool.convexPid,
            _token0,
            msg.sender
        );

        BorrowInfo storage borrowInfo = borrowInfos[
            generateId(address(0), _pid, pool.supportPids[_supportPid])
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.add(
            lendingParams.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.add(
            lendingParams.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            generateId(msg.sender, _pid, pool.supportPids[_supportPid])
        ];

        statistic.totalCollateral = statistic.totalCollateral.add(_token0);
        statistic.totalBorrow = statistic.totalBorrow.add(
            lendingParams.lendingAmount
        );

        userLendings[msg.sender].push(
            UserLending({
                lendingId: lendingId,
                token0: _token0,
                token0Price: lendingParams.token0Price,
                lendingAmount: lendingParams.lendingAmount,
                borrowAmount: lendingParams.borrowAmount,
                borrowInterest: lendingParams.borrowInterest,
                supportPid: pool.supportPids[_supportPid],
                curveCoinId: pool.curveCoinIds[_supportPid],
                borrowNumbers: _borrowBlocks
            })
        );

        lendings[lendingId] = LendingInfo({
            user: msg.sender,
            pid: _pid,
            borrowIndex: pool.borrowIndex,
            userLendingIndex: userLendings[msg.sender].length - 1,
            startedBlock: block.number,
            utilizationRate: lendingParams.utilizationRate,
            supplyRatePerBlock: lendingParams.supplyRatePerBlock,
            state: UserLendingState.LENDING
        });

        poolLending[_pid][pool.borrowIndex] = lendingId;

        ILendingSponsor(lendingSponsor).addSponsor{value: msg.value}(
            lendingId,
            msg.sender
        );

        emit LendingBase(
            lendingId,
            _pid,
            pool.supportPids[_supportPid],
            pool.curveCoinIds[_supportPid],
            _borrowBlocks
        );

        emit Borrow(
            lendingId,
            msg.sender,
            _pid,
            _token0,
            lendingParams.token0Price,
            lendingParams.lendingAmount,
            _borrowBlocks
        );
    }

    function _repayBorrow(
        bytes32 _lendingId,
        uint256 _amount,
        bool _freezeTokens
    ) internal nonReentrant {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "!invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingIndex
        ];
        address underlyToken = ISupplyBooster(supplyBooster)
            .getLendingUnderlyToken(userLending.lendingId);
        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            block.number <=
                lendingInfo.startedBlock.add(userLending.borrowNumbers),
            "Expired"
        );

        if (underlyToken == ZERO_ADDRESS) {
            require(
                msg.value == _amount && _amount == userLending.lendingAmount,
                "!_amount"
            );

            ISupplyBooster(supplyBooster).repayBorrow{
                value: userLending.lendingAmount
            }(
                userLending.lendingId,
                lendingInfo.user,
                userLending.borrowInterest
            );
        } else {
            require(
                msg.value == 0 && _amount == userLending.lendingAmount,
                "!_amount"
            );

            IERC20(underlyToken).safeTransferFrom(
                msg.sender,
                supplyBooster,
                userLending.lendingAmount
            );

            ISupplyBooster(supplyBooster).repayBorrow(
                userLending.lendingId,
                lendingInfo.user,
                userLending.lendingAmount,
                userLending.borrowInterest
            );
        }

        IConvexBooster(convexBooster).withdrawFor(
            pool.convexPid,
            userLending.token0,
            lendingInfo.user,
            _freezeTokens
        );

        BorrowInfo storage borrowInfo = borrowInfos[
            generateId(address(0), lendingInfo.pid, userLending.supportPid)
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            generateId(
                lendingInfo.user,
                lendingInfo.pid,
                userLending.supportPid
            )
        ];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );
        statistic.recentRepayAt = block.timestamp;

        ILendingSponsor(lendingSponsor).payFee(
            userLending.lendingId,
            payable(lendingInfo.user)
        );

        lendingInfo.state = UserLendingState.EXPIRED;

        emit RepayBorrow(
            userLending.lendingId,
            lendingInfo.user,
            lendingInfo.state
        );
    }

    function repayBorrow(bytes32 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, false);
    }

    function repayBorrowERC20(bytes32 _lendingId, uint256 _amount) public {
        _repayBorrow(_lendingId, _amount, false);
    }

    function repayBorrowAndFreezeTokens(bytes32 _lendingId) public payable {
        _repayBorrow(_lendingId, msg.value, true);
    }

    function repayBorrowERC20AndFreezeTokens(
        bytes32 _lendingId,
        uint256 _amount
    ) public {
        _repayBorrow(_lendingId, _amount, true);
    }

    /**
    @notice Used to liquidate asset
    @dev If repayment is overdue, it is used to liquidate asset. If valued LP is not enough, can use msg.value or _extraErc20Amount force liquidation
    @param _lendingId Lending ID
    @param _extraErc20Amount If liquidate erc-20 asset, fill in extra amount. If native asset, send msg.value
     */
    function liquidate(bytes32 _lendingId, uint256 _extraErc20Amount)
        public
        payable
        nonReentrant
    {
        uint256 gasStart = gasleft();
        LendingInfo storage lendingInfo = lendings[_lendingId];

        require(lendingInfo.startedBlock > 0, "!invalid lendingId");

        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingIndex
        ];

        require(
            lendingInfo.state == UserLendingState.LENDING,
            "!UserLendingState"
        );

        require(
            lendingInfo.startedBlock.add(userLending.borrowNumbers).sub(
                liquidateThresholdBlockNumbers
            ) < block.number,
            "!borrowNumbers"
        );

        PoolInfo storage pool = poolInfo[lendingInfo.pid];

        lendingInfo.state = UserLendingState.LIQUIDATED;

        BorrowInfo storage borrowInfo = borrowInfos[
            generateId(address(0), lendingInfo.pid, userLending.supportPid)
        ];

        borrowInfo.borrowAmount = borrowInfo.borrowAmount.sub(
            userLending.token0Price
        );
        borrowInfo.supplyAmount = borrowInfo.supplyAmount.sub(
            userLending.lendingAmount
        );

        Statistic storage statistic = myStatistics[
            generateId(
                lendingInfo.user,
                lendingInfo.pid,
                userLending.supportPid
            )
        ];

        statistic.totalCollateral = statistic.totalCollateral.sub(
            userLending.token0
        );
        statistic.totalBorrow = statistic.totalBorrow.sub(
            userLending.lendingAmount
        );

        (address underlyToken, uint256 liquidateAmount) = IConvexBooster(
            convexBooster
        ).liquidate(
                pool.convexPid,
                userLending.curveCoinId,
                lendingInfo.user,
                userLending.token0
            );

        if (underlyToken == ZERO_ADDRESS) {
            liquidateAmount = liquidateAmount.add(msg.value);

            ISupplyBooster(supplyBooster).liquidate{value: liquidateAmount}(
                userLending.lendingId,
                userLending.borrowInterest
            );
        } else {
            IERC20(underlyToken).safeTransfer(supplyBooster, liquidateAmount);

            if (_extraErc20Amount > 0) {
                // Failure without authorization
                IERC20(underlyToken).safeTransferFrom(
                    msg.sender,
                    supplyBooster,
                    _extraErc20Amount
                );
            }

            ISupplyBooster(supplyBooster).liquidate(
                userLending.lendingId,
                userLending.borrowInterest
            );
        }

        ILendingSponsor(lendingSponsor).payFee(
            userLending.lendingId,
            msg.sender
        );

        uint256 gasSpent = (21000 + gasStart - gasleft()).mul(tx.gasprice);

        emit Liquidate(
            userLending.lendingId,
            lendingInfo.user,
            liquidateAmount,
            gasSpent,
            lendingInfo.state
        );
    }

    function setLiquidateThresholdBlockNumbers(uint256 _v)
        public
        onlyGovernance
    {
        require(
            _v >= MIN_LIQUIDATE_BLOCK_NUMBERS &&
                _v <= MAX_LIQUIDATE_BLOCK_NUMBERS,
            "!_v"
        );

        liquidateThresholdBlockNumbers = _v;
    }

    function setBorrowBlock(uint256 _number, bool _state)
        public
        onlyGovernance
    {
        require(
            _number.sub(liquidateThresholdBlockNumbers) >
                liquidateThresholdBlockNumbers,
            "!_number"
        );

        borrowBlocks[_number] = _state;

        emit SetBorrowBlock(_number, borrowBlocks[_number]);
    }

    function setLendingThreshold(uint256 _pid, uint256 _v)
        public
        onlyGovernance
    {
        require(
            _v >= MIN_LENDING_THRESHOLD && _v <= MAX_LENDING_THRESHOLD,
            "!_v"
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.lendingThreshold = _v;
    }

    function setLiquidateThreshold(uint256 _pid, uint256 _v)
        public
        onlyGovernance
    {
        require(
            _v >= MIN_LIQUIDATE_THRESHOLD && _v <= MAX_LIQUIDATE_THRESHOLD,
            "!_v"
        );

        PoolInfo storage pool = poolInfo[_pid];

        pool.liquidateThreshold = _v;
    }

    receive() external payable {}

    /* 
    @param _convexBoosterPid convexBooster contract
    @param _supplyBoosterPids supply contract
    @param _curveCoinIds curve coin id of curve COINS
     */
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) public onlyGovernance {
        require(
            _lendingThreshold >= MIN_LENDING_THRESHOLD &&
                _lendingThreshold <= MAX_LENDING_THRESHOLD,
            "!_lendingThreshold"
        );
        require(
            _liquidateThreshold >= MIN_LIQUIDATE_THRESHOLD &&
                _liquidateThreshold <= MAX_LIQUIDATE_THRESHOLD,
            "!_liquidateThreshold"
        );
        require(
            _supplyBoosterPids.length == _curveCoinIds.length,
            "!_supportPids && _curveCoinIds"
        );

        poolInfo.push(
            PoolInfo({
                convexPid: _convexBoosterPid,
                supportPids: _supplyBoosterPids,
                curveCoinIds: _curveCoinIds,
                lendingThreshold: _lendingThreshold,
                liquidateThreshold: _liquidateThreshold,
                borrowIndex: 0
            })
        );
    }

    /* function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    } */

    function generateId(
        address x,
        uint256 y,
        uint256 z
    ) public pure returns (bytes32) {
        /* return toBytes16(uint256(keccak256(abi.encodePacked(x, y, z)))); */
        return keccak256(abi.encodePacked(x, y, z));
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function cursor(
        uint256 _pid,
        uint256 _offset,
        uint256 _size
    ) public view returns (bytes32[] memory, uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 size = _offset.add(_size) > pool.borrowIndex
            ? pool.borrowIndex.sub(_offset)
            : _size;

        bytes32[] memory userLendingIds = new bytes32[](size);

        for (uint256 i = 0; i < size; i++) {
            bytes32 userLendingId = poolLending[_pid][_offset.add(i)];

            userLendingIds[i] = userLendingId;
        }

        return (userLendingIds, pool.borrowIndex);
    }

    function calculateRepayAmount(bytes32 _lendingId)
        public
        view
        returns (uint256)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];
        UserLending storage userLending = userLendings[lendingInfo.user][
            lendingInfo.userLendingIndex
        ];

        if (lendingInfo.state == UserLendingState.LIQUIDATED) return 0;

        return userLending.lendingAmount;
    }

    function getPoolSupportPids(uint256 _pid)
        public
        view
        returns (uint256[] memory)
    {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.supportPids;
    }

    function getCurveCoinId(uint256 _pid, uint256 _supportPid)
        public
        view
        returns (int128)
    {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.curveCoinIds[_supportPid];
    }

    function getUserLendingState(bytes32 _lendingId)
        public
        view
        returns (UserLendingState)
    {
        LendingInfo storage lendingInfo = lendings[_lendingId];

        return lendingInfo.state;
    }

    function getLendingInfo(
        uint256 _token0,
        uint256 _convexPid,
        int128 _curveCoinId,
        uint256 _supplyPid,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold,
        uint256 _borrowBlocks
    ) public view returns (LendingParams memory) {
        (address lpToken, uint256 token0Price) = _getCurveInfo(
            _convexPid,
            _curveCoinId,
            _token0
        );

        uint256 utilizationRate = ISupplyBooster(supplyBooster)
            .getUtilizationRate(_supplyPid);
        uint256 supplyRatePerBlock = ISupplyBooster(supplyBooster)
            .getBorrowRatePerBlock(_supplyPid);
        uint256 supplyRate = getSupplyRate(supplyRatePerBlock, _borrowBlocks);
        uint256 lendflareTotalRate;

        if (utilizationRate > 0) {
            lendflareTotalRate = getLendingRate(
                supplyRate,
                getAmplificationFactor(utilizationRate)
            );
        } else {
            lendflareTotalRate = supplyRate.sub(SUPPLY_RATE_DENOMINATOR);
        }

        uint256 lendingAmount = token0Price.mul(SUPPLY_RATE_DENOMINATOR);

        lendingAmount = lendingAmount.mul(
            THRESHOLD_DENOMINATOR.sub(_lendingThreshold).sub(
                _liquidateThreshold
            )
        );

        lendingAmount = lendingAmount.div(THRESHOLD_DENOMINATOR);

        uint256 repayBorrowAmount = lendingAmount.div(SUPPLY_RATE_DENOMINATOR);
        uint256 borrowAmount = lendingAmount.div(
            SUPPLY_RATE_DENOMINATOR.add(lendflareTotalRate)
        );

        uint256 borrowInterest = repayBorrowAmount.sub(borrowAmount);

        return
            LendingParams({
                lendingAmount: repayBorrowAmount,
                borrowAmount: borrowAmount,
                borrowInterest: borrowInterest,
                lendingRate: lendflareTotalRate,
                utilizationRate: utilizationRate,
                supplyRatePerBlock: supplyRatePerBlock,
                lpToken: lpToken,
                token0Price: token0Price
            });
    }

    function getUserLendingsLength(address _user)
        public
        view
        returns (uint256)
    {
        return userLendings[_user].length;
    }

    function getSupplyRate(uint256 _supplyBlockRate, uint256 n)
        public
        pure
        returns (
            uint256 total // _supplyBlockRate and the result are scaled to 1e18
        )
    {
        uint256 term = 1e18; // term0 = xn, term1 = n(n-1)/2! * x^2, term2 = term1 * (n - 2) / (i + 1) * x
        uint256 result = 1e18; // partial sum of terms
        uint256 MAX_TERMS = 10; // up to MAX_TERMS are calculated, the error is negligible

        for (uint256 i = 0; i < MAX_TERMS && i < n; ++i) {
            term = term.mul(n - i).div(i + 1).mul(_supplyBlockRate).div(1e18);

            total = total.add(term);
        }

        total = total.add(result);
    }

    function getAmplificationFactor(uint256 _utilizationRate)
        public
        pure
        returns (uint256)
    {
        if (_utilizationRate <= 0.9 * 1e18) {
            return uint256(10).mul(_utilizationRate).div(9).add(1e18);
        }

        return uint256(20).mul(_utilizationRate).sub(16 * 1e18);
    }

    // lendflare total rate
    function getLendingRate(uint256 _supplyRate, uint256 _amplificationFactor)
        public
        pure
        returns (uint256)
    {
        return _supplyRate.sub(1e18).mul(_amplificationFactor).div(1e18);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

interface IConvexBooster {
    function liquidate(
        uint256 _convexPid,
        int128 _curveCoinId,
        address _user,
        uint256 _amount
    ) external returns (address, uint256);

    function depositFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user
    ) external returns (bool);

    function withdrawFor(
        uint256 _convexPid,
        uint256 _amount,
        address _user,
        bool _freezeTokens
    ) external returns (bool);

    function poolInfo(uint256 _convexPid)
        external
        view
        returns (
            uint256 originConvexPid,
            address curveSwapAddress,
            address lpToken,
            address originCrvRewards,
            address originStash,
            address virtualBalance,
            address rewardCrvPool,
            address rewardCvxPool,
            bool shutdown
        );

    function addConvexPool(uint256 _originConvexPid) external;
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./supply/SupplyTreasuryFundForCompound.sol";
import "./convex/IConvexBooster.sol";
import "./supply/ISupplyBooster.sol";

/* 
This contract will be executed after the lending contracts is created and will become invalid in the future.
 */

interface ILendingMarket {
    function addMarketPool(
        uint256 _convexBoosterPid,
        uint256[] calldata _supplyBoosterPids,
        int128[] calldata _curveCoinIds,
        uint256 _lendingThreshold,
        uint256 _liquidateThreshold
    ) external;
}

contract GenerateLendingPools {
    address public convexBooster;
    address public lendingMarket;

    address public supplyBooster;
    address public supplyRewardFactory;

    bool public completed;
    address public deployer;

    struct ConvexPool {
        address target;
        uint256 pid;
    }

    struct LendingMarketMapping {
        uint256 convexBoosterPid;
        uint256[] supplyBoosterPids;
        int128[] curveCoinIds;
    }

    address[] public supplyPools;
    address[] public compoundPools;
    ConvexPool[] public convexPools;
    LendingMarketMapping[] public lendingMarketMappings;

    constructor(address _deployer) public {
        deployer = _deployer;
    }

    function setLendingContract(
        address _supplyBooster,
        address _convexBooster,
        address _lendingMarket,
        address _supplyRewardFactory
    ) public {
        require(
            deployer == msg.sender,
            "GenerateLendingPools: !authorized auth"
        );

        supplyBooster = _supplyBooster;
        convexBooster = _convexBooster;
        lendingMarket = _lendingMarket;
        supplyRewardFactory = _supplyRewardFactory;
    }

    function createMapping(
        uint256 _convexBoosterPid,
        uint256 _param1,
        uint256 _param2,
        int128 _param3,
        int128 _param4
    ) internal pure returns (LendingMarketMapping memory lendingMarketMapping) {
        uint256[] memory supplyBoosterPids = new uint256[](2);
        int128[] memory curveCoinIds = new int128[](2);

        supplyBoosterPids[0] = _param1;
        supplyBoosterPids[1] = _param2;

        curveCoinIds[0] = _param3;
        curveCoinIds[1] = _param4;

        lendingMarketMapping.convexBoosterPid = _convexBoosterPid;
        lendingMarketMapping.supplyBoosterPids = supplyBoosterPids;
        lendingMarketMapping.curveCoinIds = curveCoinIds;
    }

    function createMapping(
        uint256 _convexBoosterPid,
        uint256 _param1,
        int128 _param2
    ) internal pure returns (LendingMarketMapping memory lendingMarketMapping) {
        uint256[] memory supplyBoosterPids = new uint256[](1);
        int128[] memory curveCoinIds = new int128[](1);

        supplyBoosterPids[0] = _param1;
        curveCoinIds[0] = _param2;

        lendingMarketMapping.convexBoosterPid = _convexBoosterPid;
        lendingMarketMapping.supplyBoosterPids = supplyBoosterPids;
        lendingMarketMapping.curveCoinIds = curveCoinIds;
    }

    function generateSupplyPools() internal {
        address compoundComptroller = 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;

        (address USDC,address cUSDC) = (0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, 0x39AA39c021dfbaE8faC545936693aC917d5E7563);
        (address DAI,address cDAI) = (0x6B175474E89094C44Da98b954EedeAC495271d0F, 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
        (address TUSD,address cTUSD) = (0x0000000000085d4780B73119b644AE5ecd22b376, 0x12392F67bdf24faE0AF363c24aC620a2f67DAd86);
        (address WBTC,address cWBTC) = (0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, 0xC11b1268C1A384e55C48c2391d8d480264A3A7F4);
        (address Ether,address cEther) = (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5);


        supplyPools.push(USDC);
        supplyPools.push(DAI);
        supplyPools.push(TUSD);
        supplyPools.push(WBTC);
        supplyPools.push(Ether);

        compoundPools.push(cUSDC);
        compoundPools.push(cDAI);
        compoundPools.push(cTUSD);
        compoundPools.push(cWBTC);
        compoundPools.push(cEther);

        for (uint256 i = 0; i < supplyPools.length; i++) {
            SupplyTreasuryFundForCompound supplyTreasuryFund = new SupplyTreasuryFundForCompound(
                    supplyBooster,
                    compoundPools[i],
                    compoundComptroller,
                    supplyRewardFactory
                );

            ISupplyBooster(supplyBooster).addSupplyPool(
                supplyPools[i],
                address(supplyTreasuryFund)
            );
        }
    }

    function generateConvexPools() internal {
        // USDC,DAI , supplyBoosterPids, curveCoinIds  =  [cUSDC, cDAI], [USDC, DAI]
        convexPools.push( ConvexPool(0xC25a3A3b969415c80451098fa907EC722572917F, 4) ); // DAI USDC USDT sUSD               [1, 0] [0, 1] sUSD
        convexPools.push( ConvexPool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B, 40) ); // MIM DAI USDC USDT               [1, 0] [1, 2] mim
        convexPools.push( ConvexPool(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490, 9) ); // DAI USDC USDT                    [1, 0] [0, 1] 3Pool
        convexPools.push( ConvexPool(0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B, 32) ); // FRAX DAI USDC USDT              [1, 0] [1, 2] frax
        convexPools.push( ConvexPool(0x1AEf73d49Dedc4b1778d0706583995958Dc862e6, 14) ); // mUSD + 3Crv                     [1, 0] [1, 2] musd
        convexPools.push( ConvexPool(0x94e131324b6054c0D789b190b2dAC504e4361b53, 21) ); // UST + 3Crv                      [1, 0] [1, 2] ust
        convexPools.push( ConvexPool(0xEd279fDD11cA84bEef15AF5D39BB4d4bEE23F0cA, 33) ); // LUSD + 3Crv                     [1, 0] [1, 2] lusd
        convexPools.push( ConvexPool(0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c, 36) ); // alUSD + 3Crv                    [1, 0] [1, 2] alusd
        convexPools.push( ConvexPool(0xD2967f45c4f384DEEa880F807Be904762a3DeA07, 10) ); // GUSD + 3Crv                     [1, 0] [1, 2] gusd
        convexPools.push( ConvexPool(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522, 13) ); // USDN + 3Crv                     [1, 0] [1, 2] usdn
        convexPools.push( ConvexPool(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522, 12) ); // USDK + 3Crv                     [1, 0] [1, 2] usdk
        convexPools.push( ConvexPool(0x4807862AA8b2bF68830e4C8dc86D0e9A998e085a, 34) ); // BUSD + 3Crv                     [1, 0] [1, 2] busdv2
        convexPools.push( ConvexPool(0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858, 11) ); // HUSD + 3Crv                     [1, 0] [1, 2] husd
        convexPools.push( ConvexPool(0xC2Ee6b0334C261ED60C72f6054450b61B8f18E35, 15) ); // RSV + 3Crv                      [1, 0] [1, 2] rsv
        convexPools.push( ConvexPool(0x3a664Ab939FD8482048609f652f9a0B0677337B9, 17) ); // DUSD + 3Crv                     [1, 0] [1, 2] dusd
        convexPools.push( ConvexPool(0x7Eb40E450b9655f4B3cC4259BCC731c63ff55ae6, 28) ); // USDP + 3Crv                     [1, 0] [1, 2] usdp

        // TUSD
        convexPools.push( ConvexPool(0xEcd5e75AFb02eFa118AF914515D6521aaBd189F1, 31) ); // TUSD + 3Crv                     [2] [0] tusd

        // WBTC
        convexPools.push( ConvexPool(0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3, 7) ); // renBTC + wBTC + sBTC            [3] [1] sbtc
        convexPools.push( ConvexPool(0x2fE94ea3d5d4a175184081439753DE15AeF9d614, 20) ); // oBTC + renBTC + wBTC + sBTC     [3] [2] obtc
        convexPools.push( ConvexPool(0x49849C98ae39Fff122806C06791Fa73784FB3675, 6) ); // renBTC + wBTC                   [3] [1] ren
        convexPools.push( ConvexPool(0xb19059ebb43466C323583928285a49f558E572Fd, 8) ); // HBTC + wBTC                     [3] [1] hbtc
        convexPools.push( ConvexPool(0x410e3E86ef427e30B9235497143881f717d93c2A, 19) ); // BBTC + renBTC + wBTC + sBTC     [3] [2] bbtc
        convexPools.push( ConvexPool(0x64eda51d3Ad40D56b9dFc5554E06F94e1Dd786Fd, 16) ); // tBTC + renBTC + wBTC + sBTC     [3] [2] tbtc
        convexPools.push( ConvexPool(0xDE5331AC4B3630f94853Ff322B66407e0D6331E8, 18) ); // pBTC + renBTC + wBTC + sBTC     [3] [2] pbtc

        // ETH
        convexPools.push( ConvexPool(0xA3D87FffcE63B53E0d54fAa1cc983B7eB0b74A9c, 23) ); // ETH + sETH                      [4] [0] seth
        convexPools.push( ConvexPool(0x06325440D014e39736583c165C2963BA99fAf14E, 25) ); // ETH + stETH                     [4] [0] steth
        convexPools.push( ConvexPool(0xaA17A236F2bAdc98DDc0Cf999AbB47D47Fc0A6Cf, 27) ); // ETH + ankrETH                   [4] [0] ankreth
        convexPools.push( ConvexPool(0x53a901d48795C58f485cBB38df08FA96a24669D5, 35) ); // ETH + rETH                      [4] [0] reth

        for (uint256 i = 0; i < convexPools.length; i++) {
            IConvexBooster(convexBooster).addConvexPool(convexPools[i].pid);
        }
    }

    function generateMappingPools() internal {
        lendingMarketMappings.push(createMapping(0, 1, 0, 0, 1)); // [1, 0] [0, 1]
        lendingMarketMappings.push(createMapping(1, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(2, 1, 0, 0, 1)); // [1, 0] [0, 1]
        lendingMarketMappings.push(createMapping(3, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(4, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(5, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(6, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(7, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(8, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(9, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(10, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(11, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(12, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(13, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(14, 1, 0, 1, 2)); // [1, 0] [1, 2]
        lendingMarketMappings.push(createMapping(15, 1, 0, 1, 2)); // [1, 0] [1, 2]

        lendingMarketMappings.push(createMapping(16, 2, 0)); // [2] [0]

        lendingMarketMappings.push(createMapping(17, 3, 1)); // [3] [1]
        lendingMarketMappings.push(createMapping(18, 3, 2)); // [3] [2]
        lendingMarketMappings.push(createMapping(19, 3, 1)); // [3] [1]
        lendingMarketMappings.push(createMapping(20, 3, 1)); // [3] [1]
        lendingMarketMappings.push(createMapping(21, 3, 2)); // [3] [2]
        lendingMarketMappings.push(createMapping(22, 3, 2)); // [3] [2]
        lendingMarketMappings.push(createMapping(23, 3, 2)); // [3] [2]

        lendingMarketMappings.push(createMapping(24, 4, 0)); // [4] [0]
        lendingMarketMappings.push(createMapping(25, 4, 0)); // [4] [0]
        lendingMarketMappings.push(createMapping(26, 4, 0)); // [4] [0]
        lendingMarketMappings.push(createMapping(27, 4, 0)); // [4] [0]

        for (uint256 i = 0; i < lendingMarketMappings.length; i++) {
            ILendingMarket(lendingMarket).addMarketPool(
                lendingMarketMappings[i].convexBoosterPid,
                lendingMarketMappings[i].supplyBoosterPids,
                lendingMarketMappings[i].curveCoinIds,
                100,
                50
            );
        }
    }

    function run() public {
        require(deployer == msg.sender, "GenerateLendingPools: !authorized auth");
        require(!completed, "GenerateLendingPools: !completed");

        require(supplyBooster != address(0),"!supplyBooster");
        require(convexBooster != address(0),"!convexBooster");
        require(lendingMarket != address(0),"!lendingMarket");
        require(supplyRewardFactory != address(0),"!supplyRewardFactory");

        generateSupplyPools();
        generateConvexPools();
        generateMappingPools();

        completed = true;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../common/IBaseReward.sol";

interface ICompoundComptroller {
    /*** Assets You Are In ***/
    function enterMarkets(address[] calldata cTokens)
        external
        returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function getAssetsIn(address account)
        external
        view
        returns (address[] memory);

    function checkMembership(address account, address cToken)
        external
        view
        returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function getCompAddress() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function accountAssets(address user)
        external
        view
        returns (address[] memory);

    function markets(address _cToken)
        external
        view
        returns (bool isListed, uint256 collateralFactorMantissa);
}

interface ICompound {
    function borrow(uint256 borrowAmount) external returns (uint256);

    function isCToken(address) external view returns (bool);

    function comptroller() external view returns (ICompoundComptroller);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function accrualBlockNumber() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function borrowBalanceStored(address user) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function decimals() external view returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function interestRateModel() external view returns (address);
}

interface ICompoundCEther is ICompound {
    function repayBorrow() external payable;

    function mint() external payable;
}

interface ICompoundCErc20 is ICompound {
    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function underlying() external returns (address); // like usdc usdt
}

interface ISupplyRewardFactory {
    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address);
}

contract SupplyTreasuryFundForCompound is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardCompPool;
    address public supplyRewardFactory;
    address public virtualBalance;
    address public compAddress;
    address public compoundComptroller;
    address public underlyToken;
    address public lpToken;
    address public owner;
    uint256 public totalUnderlyToken;
    uint256 public frozenUnderlyToken;
    bool public isErc20;
    bool private initialized;

    modifier onlyInitialized() {
        require(initialized, "!initialized");
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "SupplyTreasuryFundForCompound: !authorized"
        );
        _;
    }

    constructor(
        address _owner,
        address _lpToken,
        address _compoundComptroller,
        address _supplyRewardFactory
    ) public {
        owner = _owner;
        compoundComptroller = _compoundComptroller;
        lpToken = _lpToken;
        supplyRewardFactory = _supplyRewardFactory;
    }

    // call by Owner (SupplyBooster)
    function initialize(
        address _virtualBalance,
        address _underlyToken,
        bool _isErc20
    ) public onlyOwner {
        require(!initialized, "initialized");

        compAddress = ICompoundComptroller(compoundComptroller).getCompAddress();

        underlyToken = _underlyToken;

        virtualBalance = _virtualBalance;
        isErc20 = _isErc20;

        rewardCompPool = ISupplyRewardFactory(supplyRewardFactory).createReward(
                compAddress,
                virtualBalance,
                address(this)
            );

        initialized = true;
    }

    function _mintEther(uint256 _amount) internal {
        ICompoundCEther(lpToken).mint{value: _amount}();
    }

    function _mintErc20(uint256 _amount) internal {
        ICompoundCErc20(lpToken).mint(_amount);
    }

    receive() external payable {}

    function migrate(address _newTreasuryFund, bool _setReward)
        external
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        uint256 cTokens = IERC20(lpToken).balanceOf(address(this));

        uint256 redeemState = ICompound(lpToken).redeem(cTokens);

        require(
            redeemState == 0,
            "SupplyTreasuryFundForCompound: !redeemState"
        );

        uint256 bal;

        if (isErc20) {
            bal = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(owner, bal);
        } else {
            bal = address(this).balance;

            if (bal > 0) {
                payable(owner).sendValue(bal);
            }
        }

        if (_setReward) {
            IBaseReward(rewardCompPool).addOwner(_newTreasuryFund);
            IBaseReward(rewardCompPool).removeOwner(address(this));
        }

        return bal;
    }

    function _depositFor(address _for, uint256 _amount) internal {
        totalUnderlyToken = totalUnderlyToken.add(_amount);

        if (isErc20) {
            IERC20(underlyToken).safeApprove(lpToken, 0);
            IERC20(underlyToken).safeApprove(lpToken, _amount);

            _mintErc20(_amount);
        } else {
            _mintEther(_amount);
        }

        if (_for != address(0)) {
            IBaseReward(rewardCompPool).stake(_for);
        }
    }

    function depositFor(address _for)
        public
        payable
        onlyInitialized
        onlyOwner
        nonReentrant
    {
        _depositFor(_for, msg.value);
    }

    function depositFor(address _for, uint256 _amount)
        public
        onlyInitialized
        onlyOwner
        nonReentrant
    {
        _depositFor(_for, _amount);
    }

    function withdrawFor(address _to, uint256 _amount)
        public
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        IBaseReward(rewardCompPool).withdraw(_to);

        require(
            totalUnderlyToken >= _amount,
            "SupplyTreasuryFundForCompound: !insufficient balance"
        );

        totalUnderlyToken = totalUnderlyToken.sub(_amount);

        uint256 redeemState = ICompound(lpToken).redeemUnderlying(_amount);

        require(
            redeemState == 0,
            "SupplyTreasuryFundForCompound: !redeemState"
        );

        uint256 bal;

        if (isErc20) {
            bal = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(_to, bal);
        } else {
            bal = address(this).balance;

            if (bal > 0) {
                payable(_to).sendValue(bal);
            }
        }

        return bal;
    }

    function borrow(
        address _to,
        uint256 _lendingAmount,
        uint256 _lendingInterest
    ) public onlyInitialized nonReentrant onlyOwner returns (uint256) {
        totalUnderlyToken = totalUnderlyToken.sub(_lendingAmount);
        frozenUnderlyToken = frozenUnderlyToken.add(_lendingAmount);

        uint256 redeemState = ICompound(lpToken).redeemUnderlying(
            _lendingAmount
        );

        require(
            redeemState == 0,
            "SupplyTreasuryFundForCompound: !redeemState"
        );

        if (isErc20) {
            IERC20(underlyToken).safeTransfer(
                _to,
                _lendingAmount.sub(_lendingInterest)
            );

            if (_lendingInterest > 0) {
                IERC20(underlyToken).safeTransfer(owner, _lendingInterest);
            }
        } else {
            payable(_to).sendValue(_lendingAmount.sub(_lendingInterest));
            if (_lendingInterest > 0) {
                payable(owner).sendValue(_lendingInterest);
            }
        }

        return _lendingInterest;
    }

    function repayBorrow()
        public
        payable
        onlyInitialized
        nonReentrant
        onlyOwner
    {
        _mintEther(msg.value);

        totalUnderlyToken = totalUnderlyToken.add(msg.value);
        frozenUnderlyToken = frozenUnderlyToken.sub(msg.value);
    }

    function repayBorrow(uint256 _lendingAmount)
        public
        onlyInitialized
        nonReentrant
        onlyOwner
    {
        IERC20(underlyToken).safeApprove(lpToken, 0);
        IERC20(underlyToken).safeApprove(lpToken, _lendingAmount);

        _mintErc20(_lendingAmount);

        totalUnderlyToken = totalUnderlyToken.add(_lendingAmount);
        frozenUnderlyToken = frozenUnderlyToken.sub(_lendingAmount);
    }

    function getBalance() public view returns (uint256) {
        uint256 exchangeRateStored = ICompound(lpToken).exchangeRateStored();
        uint256 cTokens = IERC20(lpToken).balanceOf(address(this));

        return exchangeRateStored.mul(cTokens).div(1e18);
    }

    function claim()
        public
        onlyInitialized
        onlyOwner
        nonReentrant
        returns (uint256)
    {
        ICompoundComptroller(compoundComptroller).claimComp(address(this));

        uint256 balanceOfComp = IERC20(compAddress).balanceOf(address(this));

        if (balanceOfComp > 0) {
            IERC20(compAddress).safeTransfer(rewardCompPool, balanceOfComp);

            IBaseReward(rewardCompPool).notifyRewardAmount(balanceOfComp);
        }

        uint256 bal;
        uint256 cTokens = IERC20(lpToken).balanceOf(address(this));

        // If Uses withdraws all the money, the remaining ctoken is profit.
        if (totalUnderlyToken == 0 && frozenUnderlyToken == 0) {
            if (cTokens > 0) {
                uint256 redeemState = ICompound(lpToken).redeem(cTokens);

                require(
                    redeemState == 0,
                    "SupplyTreasuryFundForCompound: !redeemState"
                );

                if (isErc20) {
                    bal = IERC20(underlyToken).balanceOf(address(this));

                    IERC20(underlyToken).safeTransfer(owner, bal);
                } else {
                    bal = address(this).balance;

                    if (bal > 0) {
                        payable(owner).sendValue(bal);
                    }
                }

                return bal;
            }
        }

        uint256 exchangeRateStored = ICompound(lpToken).exchangeRateCurrent();

        // ctoken price
        uint256 cTokenPrice = cTokens.mul(exchangeRateStored).div(1e18);

        if (cTokenPrice > totalUnderlyToken.add(frozenUnderlyToken)) {
            uint256 interestCToken = cTokenPrice
                .sub(totalUnderlyToken.add(frozenUnderlyToken))
                .mul(1e18)
                .div(exchangeRateStored);

            uint256 redeemState = ICompound(lpToken).redeem(interestCToken);

            require(
                redeemState == 0,
                "SupplyTreasuryFundForCompound: !redeemState"
            );

            if (isErc20) {
                bal = IERC20(underlyToken).balanceOf(address(this));

                IERC20(underlyToken).safeTransfer(owner, bal);
            } else {
                bal = address(this).balance;

                if (bal > 0) {
                    payable(owner).sendValue(bal);
                }
            }
        }

        return bal;
    }

    function getReward(address _for) public onlyOwner nonReentrant {
        if (IBaseReward(rewardCompPool).earned(_for) > 0) {
            IBaseReward(rewardCompPool).getReward(_for);
        }
    }

    function getBorrowRatePerBlock() public view returns (uint256) {
        return ICompound(lpToken).borrowRatePerBlock();
    }

    /* function getCollateralFactorMantissa() public view returns (uint256) {
        ICompoundComptroller comptroller = ICompound(lpToken).comptroller();
        (bool isListed, uint256 collateralFactorMantissa) = comptroller.markets(
            lpToken
        );

        return isListed ? collateralFactorMantissa : 800000000000000000;
    } */
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../common/IVirtualBalanceWrapper.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ILendFlareToken {
    function futureEpochTimeWrite() external returns (uint256);

    function rate() external view returns (uint256);
}

interface IMinter {
    function minted(address addr, address self) external view returns (uint256);
}

interface ILendFlareGaugeModel {
    function getGaugeWeightShare(address addr) external view returns (uint256);
}

contract LendFlareGauge is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 constant TOKENLESS_PRODUCTION = 40;
    uint256 constant BOOST_WARMUP = 2 weeks;
    uint256 constant WEEK = 1 weeks;

    address public virtualBalance;
    uint256 public working_supply;
    uint256 public period;
    uint256 public inflation_rate;
    uint256 public future_epoch_time;

    address public lendFlareVotingEscrow;
    address public lendFlareToken;
    address public lendFlareTokenMinter;
    address public lendFlareGaugeModel;

    mapping(uint256 => uint256) public period_timestamp;
    mapping(uint256 => uint256) public integrate_inv_supply;

    mapping(address => uint256) public integrate_inv_supply_of;
    mapping(address => uint256) public integrate_checkpoint_of;
    mapping(address => uint256) public totalAccrued;
    mapping(address => uint256) public rewardLiquidityLimits;

    event UpdateLiquidityLimit(
        address user,
        uint256 original_balance,
        uint256 original_supply,
        uint256 working_balance,
        uint256 working_supply
    );

    constructor(
        address _virtualBalance,
        address _lendFlareToken,
        address _lendFlareVotingEscrow,
        address _lendFlareGaugeModel,
        address _lendFlareTokenMinter
    ) public {
        virtualBalance = _virtualBalance;
        lendFlareVotingEscrow = _lendFlareVotingEscrow;
        lendFlareToken = _lendFlareToken;
        lendFlareTokenMinter = _lendFlareTokenMinter;
        lendFlareGaugeModel = _lendFlareGaugeModel;
    }

    function _updateLiquidityLimit(
        address addr,
        uint256 l,
        uint256 L
    ) internal {
        uint256 voting_balance = IERC20(lendFlareVotingEscrow).balanceOf(addr);
        uint256 voting_total = IERC20(lendFlareVotingEscrow).totalSupply();
        uint256 lim = (l * TOKENLESS_PRODUCTION) / 100;

        if (
            voting_total > 0 &&
            block.timestamp > period_timestamp[0] + BOOST_WARMUP
        ) {
            lim +=
                (((L * voting_balance) / voting_total) *
                    (100 - TOKENLESS_PRODUCTION)) /
                100;
        }

        lim = min(l, lim);

        uint256 old_bal = rewardLiquidityLimits[addr];

        rewardLiquidityLimits[addr] = lim;

        uint256 _working_supply = working_supply + lim - old_bal;
        working_supply = _working_supply;

        emit UpdateLiquidityLimit(addr, l, L, lim, _working_supply);
    }

    function _checkpoint(address addr) internal {
        uint256 _period_time = period_timestamp[period];
        uint256 _integrate_inv_supply = integrate_inv_supply[period];
        uint256 rate = inflation_rate;
        uint256 new_rate = rate;
        uint256 prev_future_epoch = future_epoch_time;

        if (prev_future_epoch >= _period_time) {
            future_epoch_time = ILendFlareToken(lendFlareToken)
                .futureEpochTimeWrite();
            new_rate = ILendFlareToken(lendFlareToken).rate();

            require(new_rate > 0, "!new_rate");

            inflation_rate = new_rate;
        }

        uint256 _working_balance = rewardLiquidityLimits[addr];
        uint256 _working_supply = working_supply;

        if (block.timestamp > _period_time) {
            uint256 prev_week_time = _period_time;
            uint256 week_time = min(
                ((_period_time + WEEK) / WEEK) * WEEK,
                block.timestamp
            );

            for (uint256 i = 0; i < 500; i++) {
                uint256 dt = week_time - prev_week_time;
                uint256 w = ILendFlareGaugeModel(lendFlareGaugeModel)
                    .getGaugeWeightShare(address(this));

                if (_working_supply > 0) {
                    if (
                        prev_future_epoch >= prev_week_time &&
                        prev_future_epoch < week_time
                    ) {
                        _integrate_inv_supply +=
                            (rate * w * (prev_future_epoch - prev_week_time)) /
                            _working_supply;
                        rate = new_rate;
                        _integrate_inv_supply +=
                            (rate * w * (week_time - prev_future_epoch)) /
                            _working_supply;
                    } else {
                        _integrate_inv_supply +=
                            (rate * w * dt) /
                            _working_supply;
                    }

                    if (week_time == block.timestamp) break;

                    prev_week_time = week_time;
                    week_time = min(week_time + WEEK, block.timestamp);
                }
            }
        }

        period += 1;
        period_timestamp[period] = block.timestamp;
        integrate_inv_supply[period] = _integrate_inv_supply;

        totalAccrued[addr] +=
            (_working_balance *
                (_integrate_inv_supply - integrate_inv_supply_of[addr])) /
            10**18;
        integrate_inv_supply_of[addr] = _integrate_inv_supply;
        integrate_checkpoint_of[addr] = block.timestamp;
    }

    function updateReward(address addr) public nonReentrant returns (bool) {
        _checkpoint(addr);
        _updateLiquidityLimit(
            addr,
            IVirtualBalanceWrapper(virtualBalance).balanceOf(addr),
            IVirtualBalanceWrapper(virtualBalance).totalSupply()
        );

        return true;
    }

    function claimableTokens(address addr)
        public
        nonReentrant
        returns (uint256)
    {
        _checkpoint(addr);

        return
            totalAccrued[addr] -
            IMinter(lendFlareTokenMinter).minted(addr, address(this));
    }

    function lastCheckpointTimestamp() public view returns (uint256) {
        return period_timestamp[period];
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract SupplyPoolGaugeFactory {
    address public owner;

    event CreateGauge(address gauge);

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "SupplyPoolGaugeFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createGauge(
        address _virtualBalance,
        address _lendflareToken,
        address _lendflareVotingEscrow,
        address _lendflareGaugeModel,
        address _lendflareTokenMinter
    ) public returns (address) {
        require(
            msg.sender == owner,
            "SupplyPoolGaugeFactory: !authorized createGauge"
        );

        LendFlareGauge gauge = new LendFlareGauge(
            _virtualBalance,
            _lendflareToken,
            _lendflareVotingEscrow,
            _lendflareGaugeModel,
            _lendflareTokenMinter
        );

        emit CreateGauge(address(gauge));

        return address(gauge);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface ILendFlareToken is IERC20 {
    function setLiquidityFinish() external;
}

contract LiquidityTransformer is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    ILendFlareToken public lendflareToken;
    address public uniswapPair;

    IUniswapV2Router02 public constant uniswapRouter =
        IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address payable teamAddress;

    uint256 public constant FEE_DENOMINATOR = 10;
    uint256 public constant liquifyTokens = 909090909 * 1e18;
    uint256 public investmentTime;
    uint256 public minInvest;
    uint256 public launchTime;

    struct Globals {
        uint256 totalUsers;
        uint256 totalBuys;
        uint256 transferredUsers;
        uint256 totalWeiContributed;
        bool liquidity;
        uint256 endTimeAt;
    }

    Globals public globals;

    mapping(address => uint256) public investorBalances;
    mapping(address => uint256[2]) investorHistory;

    event UniSwapResult(
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity,
        uint256 endTimeAt
    );

    modifier afterUniswapTransfer() {
        require(globals.liquidity == true, "Forward liquidity first");
        _;
    }

    constructor(
        address _lendflareToken,
        address payable _teamAddress,
        uint256 _launchTime
    ) public {
        require(_launchTime > block.timestamp, "!_launchTime");
        launchTime = _launchTime;
        lendflareToken = ILendFlareToken(_lendflareToken);
        teamAddress = _teamAddress;

        minInvest = 0.1 ether;
        investmentTime = 7 days;

        
    }

    function createPair() external {
        require(address(uniswapPair) == address(0), "!uniswapPair");

        uniswapPair = address(
            IUniswapV2Factory(factory()).createPair(
                WETH(),
                address(lendflareToken)
            )
        );
    }

    receive() external payable {
        require(
            msg.sender == address(uniswapRouter) || msg.sender == teamAddress,
            "Direct deposits disabled"
        );
    }

    function reserve() external payable {
        _reserve(msg.sender, msg.value);
    }

    function reserveWithToken(address _tokenAddress, uint256 _tokenAmount)
        external
    {
        IERC20 token = IERC20(_tokenAddress);

        token.safeTransferFrom(msg.sender, address(this), _tokenAmount);

        token.approve(address(uniswapRouter), _tokenAmount);

        address[] memory _path = preparePath(_tokenAddress);

        uint256[] memory amounts = uniswapRouter.swapExactTokensForETH(
            _tokenAmount,
            minInvest,
            _path,
            address(this),
            block.timestamp
        );

        _reserve(msg.sender, amounts[1]);
    }

    function _reserve(address _senderAddress, uint256 _senderValue) internal {
        require(block.timestamp >= launchTime, "Not started");
        require(
            block.timestamp <= launchTime.add(investmentTime),
            "IDO has ended"
        );
        require(globals.liquidity == false, "!globals.liquidity");
        require(_senderValue >= minInvest, "Investment below minimum");

        if (investorBalances[_senderAddress] == 0) {
            globals.totalUsers++;
        }

        investorBalances[_senderAddress] = investorBalances[_senderAddress].add(
            _senderValue
        );

        globals.totalWeiContributed = globals.totalWeiContributed.add(
            _senderValue
        );
        globals.totalBuys++;
    }

    function forwardLiquidity() external nonReentrant {
        require(msg.sender == tx.origin, "!EOA");
        require(globals.liquidity == false, "!globals.liquidity");
        require(
            block.timestamp > launchTime.add(investmentTime),
            "Not over yet"
        );

        uint256 _etherFee = globals.totalWeiContributed.div(FEE_DENOMINATOR);
        uint256 _balance = globals.totalWeiContributed.sub(_etherFee);

        teamAddress.sendValue(_etherFee);

        uint256 half = liquifyTokens.div(2);
        uint256 _lendflareTokenFee = half.div(FEE_DENOMINATOR);

        IERC20(lendflareToken).safeTransfer(teamAddress, _lendflareTokenFee);

        lendflareToken.approve(
            address(uniswapRouter),
            half.sub(_lendflareTokenFee)
        );

        (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        ) = uniswapRouter.addLiquidityETH{value: _balance}(
                address(lendflareToken),
                half.sub(_lendflareTokenFee),
                0,
                0,
                address(0x0),
                block.timestamp
            );

        globals.liquidity = true;
        globals.endTimeAt = block.timestamp;

        lendflareToken.setLiquidityFinish();

        emit UniSwapResult(
            amountToken,
            amountETH,
            liquidity,
            globals.endTimeAt
        );
    }

    function getMyTokens() external afterUniswapTransfer nonReentrant {
        require(globals.liquidity, "!globals.liquidity");
        require(investorBalances[msg.sender] > 0, "!balance");

        uint256 myTokens = checkMyTokens(msg.sender);

        investorHistory[msg.sender][0] = investorBalances[msg.sender];
        investorHistory[msg.sender][1] = myTokens;
        investorBalances[msg.sender] = 0;

        IERC20(lendflareToken).safeTransfer(msg.sender, myTokens);

        globals.transferredUsers++;

        if (globals.transferredUsers == globals.totalUsers) {
            uint256 surplusBalance = IERC20(lendflareToken).balanceOf(
                address(this)
            );

            if (surplusBalance > 0) {
                IERC20(lendflareToken).safeTransfer(
                    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                    surplusBalance
                );
            }
        }
    }

    /* view functions */
    function WETH() public pure returns (address) {
        return IUniswapV2Router02(uniswapRouter).WETH();
    }

    function checkMyTokens(address _sender) public view returns (uint256) {
        if (
            globals.totalWeiContributed == 0 || investorBalances[_sender] == 0
        ) {
            return 0;
        }

        uint256 half = liquifyTokens.div(2);
        uint256 otherHalf = liquifyTokens.sub(half);
        uint256 percent = investorBalances[_sender].mul(100e18).div(
            globals.totalWeiContributed
        );
        uint256 myTokens = otherHalf.mul(percent).div(100e18);

        return myTokens;
    }

    function factory() public pure returns (address) {
        return IUniswapV2Router02(uniswapRouter).factory();
    }

    function getInvestorHistory(address _sender)
        public
        view
        returns (uint256[2] memory)
    {
        return investorHistory[_sender];
    }

    function preparePath(address _tokenAddress)
        internal
        pure
        returns (address[] memory _path)
    {
        _path = new address[](2);
        _path[0] = _tokenAddress;
        _path[1] = WETH();
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LendingSponsor is ReentrancyGuard {
    using Address for address payable;
    using SafeMath for uint256;

    enum LendingInfoState {
        NONE,
        CLOSED
    }

    struct LendingInfo {
        address user;
        uint256 amount;
        LendingInfoState state;
    }

    address public lendingMarket;
    uint256 public totalSupply;
    address public owner;

    mapping(bytes32 => LendingInfo) public lendingInfos;

    event AddSponsor(bytes32 sponsor, uint256 amount);
    event PayFee(bytes32 sponsor, address user, uint256 sponsorAmount);

    modifier onlyLendingMarket() {
        require(
            lendingMarket == msg.sender,
            "LendingSponsor: caller is not the lendingMarket"
        );

        _;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "LendingSponsor: caller is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setLendingMarket(address _v) external onlyOwner {
        require(_v != address(0), "!_v");

        lendingMarket = _v;

        owner = address(0);
    }

    function payFee(bytes32 _lendingId, address payable _user)
        public
        onlyLendingMarket
        nonReentrant
    {
        LendingInfo storage lendingInfo = lendingInfos[_lendingId];

        if (lendingInfo.state == LendingInfoState.NONE) {
            lendingInfo.state = LendingInfoState.CLOSED;

            _user.sendValue(lendingInfo.amount);

            totalSupply = totalSupply.sub(lendingInfo.amount);

            emit PayFee(_lendingId, _user, lendingInfo.amount);
        }
    }

    function addSponsor(bytes32 _lendingId, address _user)
        public
        payable
        onlyLendingMarket
        nonReentrant
    {
        lendingInfos[_lendingId] = LendingInfo({
            user: _user,
            amount: msg.value,
            state: LendingInfoState.NONE
        });

        totalSupply = totalSupply.add(msg.value);

        emit AddSponsor(_lendingId, msg.value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

contract LendFlareProxy is TransparentUpgradeableProxy {
    constructor(
        address logic,
        address admin,
        bytes memory data
    ) public TransparentUpgradeableProxy(logic, admin, data) {}
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract Timelock {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 14 days;
    uint256 public constant MINIMUM_DELAY = 1 days;
    uint256 public constant MAXIMUM_DELAY = 30 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    constructor(address admin_, uint256 delay_) public {
        admin = admin_;

        _setDelay(delay_);
    }

    function _setDelay(uint256 delay_) internal {
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::_setDelay: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::_setDelay: Delay must not exceed maximum delay."
        );

        delay = delay_;

        emit NewDelay(delay);
    }

    function setDelay(uint256 delay_) public {
        require(
            msg.sender == address(this),
            "Timelock::setDelay: Call must come from Timelock."
        );

        _setDelay(delay_);
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin,
            "Timelock::acceptAdmin: Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public {
        require(
            msg.sender == address(this),
            "Timelock::setPendingAdmin: Call must come from Timelock."
        );
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public returns (bytes32) {
        require(
            msg.sender == admin,
            "Timelock::queueTransaction: Call must come from admin."
        );
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public {
        require(
            msg.sender == admin,
            "Timelock::cancelTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) public payable returns (bytes memory) {
        require(
            msg.sender == admin,
            "Timelock::executeTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, value, signature, data, eta)
        );
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta.add(GRACE_PERIOD),
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = target.call{value: value}(
            callData
        );
        require(success, _getRevertMsg(returnData));
        // require(
        //     success,
        //     "Timelock::executeTransaction: Transaction execution reverted."
        // );

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface ILiquidityGauge {
    function updateReward(address _for) external;

    function totalAccrued(address _for) external view returns (uint256);
}

interface ILendFlareToken {
    function mint(address _for, uint256 amount) external;
}

contract LendFlareTokenMinter is ReentrancyGuard {
    using SafeMath for uint256;

    address public token;
    address public supplyPoolExtraRewardFactory;
    uint256 public launchTime;

    mapping(address => mapping(address => uint256)) public minted; // user -> gauge -> value

    event Minted(address user, address gauge, uint256 amount);

    constructor(
        address _token,
        address _supplyPoolExtraRewardFactory,
        uint256 _launchTime
    ) public {
        require(_launchTime > block.timestamp, "!_launchTime");
        launchTime = _launchTime;
        token = _token;
        supplyPoolExtraRewardFactory = _supplyPoolExtraRewardFactory;
    }

    function _mintFor(address gauge_addr, address _for) internal {
        if (block.timestamp >= launchTime) {
            ILiquidityGauge(gauge_addr).updateReward(_for);

            uint256 total_mint = ILiquidityGauge(gauge_addr).totalAccrued(_for);
            uint256 to_mint = total_mint.sub(minted[_for][gauge_addr]);

            if (to_mint > 0) {
                ILendFlareToken(token).mint(_for, to_mint);
                minted[_for][gauge_addr] = total_mint;

                emit Minted(_for, gauge_addr, total_mint);
            }
        }
    }

    function mintFor(address gauge_addr, address _for) public nonReentrant {
        require(
            msg.sender == supplyPoolExtraRewardFactory,
            "LendFlareTokenMinter: !authorized mintFor"
        );

        _mintFor(gauge_addr, _for);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LendFlareToken is Initializable, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public constant YEAR = 1 days * 365;
    uint256 public constant INITIAL_RATE = (274815283 * 10**18) / YEAR; // leading to 43% premine
    uint256 public constant RATE_REDUCTION_TIME = YEAR;
    uint256 public constant RATE_REDUCTION_COEFFICIENT = 1189207115002721024; // 2 ** (1/4) * 1e18
    uint256 public constant RATE_DENOMINATOR = 10**18;

    uint256 public startEpochTime;
    uint256 public startEpochSupply;
    uint256 public miningEpoch;
    uint256 public rate;
    uint256 public version;

    address public multiSigUser;
    address public owner;
    address public minter;
    address public liquidityTransformer;

    bool public liquidity;

    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event SetMinter(address minter);
    event SetOwner(address owner);
    event SetLiquidityTransformer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    function initialize(address _owner, address _multiSigUser)
        public
        initializer
    {
        _name = "LendFlare DAO Token";
        _symbol = "LFT";
        _decimals = 18;
        version = 1;

        owner = _owner;
        multiSigUser = _multiSigUser;

        startEpochTime = block.timestamp - RATE_REDUCTION_TIME;

        miningEpoch = 0;
        rate = 0;
        startEpochSupply = 0;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "LendFlareToken: caller is not the owner");
        _;
    }

    modifier onlyLiquidityTransformer() {
        require(
            liquidityTransformer == msg.sender,
            "LendFlareToken: caller is not the liquidityTransformer"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    function setLiquidityTransformer(address _v) public onlyOwner {
        require(_v != address(0), "!_v");
        require(liquidityTransformer == address(0), "!liquidityTransformer");

        liquidityTransformer = _v;

        uint256 supply = 909090909 * 10**18;

        _balances[liquidityTransformer] = supply;
        _totalSupply = _totalSupply.add(supply);

        startEpochSupply = startEpochSupply.add(supply);

        emit SetLiquidityTransformer(address(0), multiSigUser, supply);
    }

    function setLiquidityFinish() external onlyLiquidityTransformer {
        require(!liquidity, "!liquidity");

        uint256 official_team = 90909090 * 10**18;
        uint256 merkle_airdrop = 30303030 * 10**18;
        uint256 early_liquidity_reward = 151515151 * 10**18;
        uint256 community = 121212121 * 10**18;

        uint256 supply = official_team
            .add(merkle_airdrop)
            .add(early_liquidity_reward)
            .add(community);

        _balances[multiSigUser] = supply;
        _totalSupply = _totalSupply.add(supply);

        startEpochSupply = startEpochSupply.add(supply);

        liquidity = true;

        emit Transfer(address(0), multiSigUser, official_team);
        emit Transfer(address(0), multiSigUser, merkle_airdrop);
        emit Transfer(address(0), multiSigUser, early_liquidity_reward);
        emit Transfer(address(0), multiSigUser, community);
    }

    function _updateMiningParameters() internal {
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += RATE_REDUCTION_TIME;
        miningEpoch++;

        if (_rate == 0) {
            _rate = INITIAL_RATE;
        } else {
            _startEpochSupply += _rate * RATE_REDUCTION_TIME;
            startEpochSupply = _startEpochSupply;
            _rate = (_rate * RATE_DENOMINATOR) / RATE_REDUCTION_COEFFICIENT;
        }

        rate = _rate;

        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }

    function updateMiningParameters() external {
        require(
            block.timestamp >= startEpochTime + RATE_REDUCTION_TIME,
            "too soon!"
        );

        _updateMiningParameters();
    }

    function startEpochTimeWrite() external returns (uint256) {
        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();

            return startEpochTime;
        }

        return startEpochTime;
    }

    function futureEpochTimeWrite() external returns (uint256) {
        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();

            return startEpochTime + RATE_REDUCTION_TIME;
        }

        return startEpochTime + RATE_REDUCTION_TIME;
    }

    function availableSupply() public view returns (uint256) {
        return startEpochSupply + (block.timestamp - startEpochTime) * rate;
    }

    function mintableInTimeframe(uint256 start, uint256 end)
        external
        view
        returns (uint256)
    {
        require(start >= startEpochTime, "!start");
        require(start <= end, "start > end");

        uint256 to_mint = 0;
        uint256 current_epoch_time = startEpochTime;
        uint256 current_rate = rate;

        if (end > current_epoch_time + RATE_REDUCTION_TIME) {
            current_epoch_time += RATE_REDUCTION_TIME;
            current_rate =
                (current_rate * RATE_DENOMINATOR) /
                RATE_REDUCTION_COEFFICIENT;
        }

        require(
            end <= current_epoch_time + RATE_REDUCTION_TIME,
            "too far in future"
        );

        // It will not work in 1000 years.
        for (uint256 i = 0; i < 999; i++) {
            if (end >= current_epoch_time) {
                uint256 current_end = end;

                if (current_end > current_epoch_time + RATE_REDUCTION_TIME) {
                    current_end = current_epoch_time + RATE_REDUCTION_TIME;
                }

                uint256 current_start = start;

                if (current_start >= current_epoch_time + RATE_REDUCTION_TIME) {
                    break;
                } else if (current_start < current_epoch_time) {
                    current_start = current_epoch_time;
                }

                to_mint += current_rate * (current_end - current_start);

                if (start >= current_epoch_time) break;

                current_epoch_time -= RATE_REDUCTION_TIME;
                current_rate =
                    (current_rate * RATE_REDUCTION_COEFFICIENT) /
                    RATE_DENOMINATOR;

                require(
                    current_rate <= INITIAL_RATE,
                    "this should never happen"
                );
            }
        }

        return to_mint;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;

        emit SetMinter(_minter);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address user, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[user][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public returns (bool) {
        require(msg.sender == minter, "!minter");
        require(liquidity, "!liquidity");
        require(account != address(0), "mint to the zero address");

        if (block.timestamp >= startEpochTime + RATE_REDUCTION_TIME) {
            _updateMiningParameters();
        }

        _totalSupply = _totalSupply.add(amount);

        require(
            _totalSupply <= availableSupply(),
            "exceeds allowable mint amount"
        );

        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(
            amount,
            "burn amount exceeds balance"
        );

        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(msg.sender, address(0), amount);
    }

    function _approve(
        address user,
        address spender,
        uint256 amount
    ) internal virtual {
        require(user != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[user][spender] = amount;
        emit Approval(user, spender, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract LendFlareGaugeModel {
    using SafeMath for uint256;

    struct GaugeModel {
        address gauge;
        uint256 weight;
        bool shutdown;
    }

    address[] public gauges;
    address public owner;
    address public supplyExtraReward;

    mapping(address => GaugeModel) public gaugeWeights;

    event AddGaguge(address indexed gauge, uint256 weight);
    event ToggleGauge(address indexed gauge, bool enabled);
    event UpdateGaugeWeight(address indexed gauge, uint256 weight);
    event SetOwner(address owner);

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "LendFlareGaugeModel: caller is not the owner"
        );
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    constructor() public {
        owner = msg.sender;
    }

    function setSupplyExtraReward(address _v) public onlyOwner {
        require(_v != address(0), "!_v");

        supplyExtraReward = _v;
    }

    // default = 100000000000000000000 weight(%) = 100000000000000000000 * 1e18/ total * 100
    function addGauge(address _gauge, uint256 _weight) public {
        require(
            msg.sender == supplyExtraReward,
            "LendFlareGaugeModel: !authorized addGauge"
        );

        gauges.push(_gauge);

        gaugeWeights[_gauge] = GaugeModel({
            gauge: _gauge,
            weight: _weight,
            shutdown: false
        });
    }

    function updateGaugeWeight(address _gauge, uint256 _newWeight)
        public
        onlyOwner
    {
        require(_gauge != address(0), "LendFlareGaugeModel:: !_gauge");
        require(
            gaugeWeights[_gauge].gauge == _gauge,
            "LendFlareGaugeModel: !found"
        );

        gaugeWeights[_gauge].weight = _newWeight;

        emit UpdateGaugeWeight(_gauge, gaugeWeights[_gauge].weight);
    }

    function toggleGauge(address _gauge, bool _state) public {
        require(
            msg.sender == supplyExtraReward,
            "LendFlareGaugeModel: !authorized toggleGauge"
        );

        gaugeWeights[_gauge].shutdown = _state;

        emit ToggleGauge(_gauge, _state);
    }

    function getGaugeWeightShare(address _gauge) public view returns (uint256) {
        uint256 totalWeight;

        for (uint256 i = 0; i < gauges.length; i++) {
            if (!gaugeWeights[gauges[i]].shutdown) {
                totalWeight = totalWeight.add(gaugeWeights[gauges[i]].weight);
            }
        }

        return gaugeWeights[_gauge].weight.mul(1e18).div(totalWeight);
    }

    function gaugesLength() public view returns (uint256) {
        return gauges.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";

contract VirtualBalanceWrapper {
    using SafeMath for uint256;

    address public owner;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _owner) public {
        owner = _owner;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _for) public view returns (uint256) {
        return _balances[_for];
    }

    function stakeFor(address _for, uint256 _amount) public returns (bool) {
        require(
            msg.sender == owner,
            "VirtualBalanceWrapper: !authorized stakeFor"
        );
        require(_amount > 0, "VirtualBalanceWrapper: !_amount");

        _totalSupply = _totalSupply.add(_amount);
        _balances[_for] = _balances[_for].add(_amount);

        return true;
    }

    function withdrawFor(address _for, uint256 _amount) public returns (bool) {
        require(
            msg.sender == owner,
            "VirtualBalanceWrapper: !authorized withdrawFor"
        );
        require(_amount > 0, "VirtualBalanceWrapper: !_amount");

        _totalSupply = _totalSupply.sub(_amount);
        _balances[_for] = _balances[_for].sub(_amount);

        return true;
    }
}

contract VirtualBalanceWrapperFactory {
    event NewOwner(address indexed sender, address operator);
    event RemoveOwner(address indexed sender, address operator);

    mapping(address => bool) private owners;

    modifier onlyOwners() {
        require(isOwner(msg.sender), "vbw: caller is not an owner onlyOwners");
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
    }

    function addOwner(address _newOwner) public onlyOwners {
        require(!isOwner(_newOwner), "vbw: address is already owner addOwner");

        owners[_newOwner] = true;

        emit NewOwner(msg.sender, _newOwner);
    }

    function addOwners(address[] calldata _newOwners) external onlyOwners {
        for (uint256 i = 0; i < _newOwners.length; i++) {
            addOwner(_newOwners[i]);
        }
    }

    function removeOwner(address _owner) external onlyOwners {
        require(isOwner(_owner), "vbw: address is not owner removeOwner");

        owners[_owner] = false;

        emit RemoveOwner(msg.sender, _owner);
    }

    function isOwner(address _owner) public view returns (bool) {
        return owners[_owner];
    }

    function createWrapper(address _owner) public onlyOwners returns (address) {
        return address(new VirtualBalanceWrapper(_owner));
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LendFlareTokenLocker is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;
    address public token;
    uint256 public start_time;
    uint256 public end_time;

    mapping(address => uint256) public initial_locked;
    mapping(address => uint256) public total_claimed;
    mapping(address => uint256) public disabled_at;

    uint256 public initial_locked_supply;
    uint256 public unallocated_supply;

    event Fund(address indexed recipient, uint256 amount);
    event Claim(address indexed recipient, uint256 amount);
    event ToggleDisable(address recipient, bool disabled);
    event SetOwner(address owner);

    constructor(
        address _owner,
        address _token,
        uint256 _start_time,
        uint256 _end_time
    ) public {
        require(
            _start_time >= block.timestamp,
            "_start_time >= block.timestamp"
        );
        require(_end_time > _start_time, "_end_time > _start_time");

        owner = _owner;
        token = _token;
        start_time = _start_time;
        end_time = _end_time;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "LendFlareTokenLocker: !authorized setOwner"
        );

        owner = _owner;

        emit SetOwner(_owner);
    }

    function addTokens(uint256 _amount) public {
        require(
            msg.sender == owner,
            "LendFlareTokenLocker: !authorized addTokens"
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
        unallocated_supply += _amount;
    }

    function fund(address[] memory _recipients, uint256[] memory _amounts)
        public
    {
        require(msg.sender == owner, "LendFlareTokenLocker: !authorized fund");
        require(
            _recipients.length == _amounts.length,
            "_recipients != _amounts"
        );

        uint256 _total_amount;

        for (uint256 i = 0; i < _amounts.length; i++) {
            uint256 amount = _amounts[i];
            address recipient = _recipients[i];

            if (recipient == address(0)) {
                break;
            }

            _total_amount += amount;

            initial_locked[recipient] += amount;
            emit Fund(recipient, amount);
        }

        initial_locked_supply += _total_amount;
        unallocated_supply -= _total_amount;
    }

    function toggleDisable(address _recipient) public {
        require(
            msg.sender == owner,
            "LendFlareTokenLocker: !authorized toggleDisable"
        );

        bool is_enabled = disabled_at[_recipient] == 0;

        if (is_enabled) {
            disabled_at[_recipient] = block.timestamp;
        } else {
            disabled_at[_recipient] = 0;
        }

        emit ToggleDisable(_recipient, is_enabled);
    }

    function claim() public nonReentrant {
        address recipient = msg.sender;
        uint256 t = disabled_at[recipient];

        if (t == 0) {
            t = block.timestamp;
        }

        uint256 claimable = _totalVestedOf(recipient, t) -
            total_claimed[recipient];

        total_claimed[recipient] += claimable;

        IERC20(token).safeTransfer(recipient, claimable);

        emit Claim(recipient, claimable);
    }

    function _totalVestedOf(address _recipient, uint256 _time)
        internal
        view
        returns (uint256)
    {
        if (_time == 0) _time = block.timestamp;

        uint256 locked = initial_locked[_recipient];

        if (_time < start_time) {
            return 0;
        }

        return
            min(
                (locked * (_time - start_time)) / (end_time - start_time),
                locked
            );
    }

    function vestedSupply() public view returns (uint256) {
        uint256 locked = initial_locked_supply;

        if (block.timestamp < start_time) {
            return 0;
        }

        return
            min(
                (locked * (block.timestamp - start_time)) /
                    (end_time - start_time),
                locked
            );
    }

    function lockedSupply() public view returns (uint256) {
        return initial_locked_supply - vestedSupply();
    }

    function availableOf(address _recipient) public view returns (uint256) {
        uint256 t = disabled_at[_recipient];

        if (t == 0) {
            t = block.timestamp;
        }

        return _totalVestedOf(_recipient, t) - total_claimed[_recipient];
    }

    function lockedOf(address _recipient) public view returns (uint256) {
        return
            initial_locked[_recipient] -
            _totalVestedOf(_recipient, block.timestamp);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract LendFlareTokenLockerFactory {
    uint256 public totalLockers;
    mapping(uint256 => address) public lockers;

    address public owner;

    event CreateLocker(
        uint256 indexed uniqueId,
        address indexed locker,
        string description
    );

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "LendFlareTokenLockerFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createLocker(
        uint256 _uniqueId,
        address _token,
        uint256 _start_time,
        uint256 _end_time,
        address _owner,
        string calldata description
    ) external returns (address) {
        require(
            msg.sender == owner,
            "LendFlareTokenLockerFactory: !authorized createLocker"
        );
        require(lockers[_uniqueId] == address(0), "!_uniqueId");

        LendFlareTokenLocker locker = new LendFlareTokenLocker(
            _owner,
            _token,
            _start_time,
            _end_time
        );

        lockers[_uniqueId] = address(locker);

        totalLockers++;

        emit CreateLocker(_uniqueId, address(locker), description);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./convex/ConvexInterfaces.sol";
import "./common/IVirtualBalanceWrapper.sol";

contract ConvexBooster is Initializable, ReentrancyGuard, IConvexBooster {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // https://curve.readthedocs.io/registry-address-provider.html
    ICurveAddressProvider public curveAddressProvider =
        ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

    address public constant ZERO_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address public convexRewardFactory;
    address public virtualBalanceWrapperFactory;
    address public originConvexBooster;
    address public rewardCrvToken;
    address public rewardCvxToken;
    uint256 public version;

    address public lendingMarket;
    address public owner;
    address public governance;

    struct PoolInfo {
        uint256 originConvexPid;
        address curveSwapAddress; /* like 3pool https://github.com/curvefi/curve-js/blob/master/src/constants/abis/abis-ethereum.ts */
        address lpToken;
        address originCrvRewards;
        address originStash;
        address virtualBalance;
        address rewardCrvPool;
        address rewardCvxPool;
        bool shutdown;
    }

    PoolInfo[] public override poolInfo;

    mapping(uint256 => mapping(address => uint256)) public frozenTokens; // pid => (user => amount)

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateExtraRewards(uint256 pid, uint256 index, address extraReward);
    event Initialized(address indexed thisAddress);
    event ToggleShutdownPool(uint256 pid, bool shutdown);
    event SetOwner(address owner);
    event SetGovernance(address governance);

    modifier onlyOwner() {
        require(owner == msg.sender, "ConvexBooster: caller is not the owner");
        _;
    }

    modifier onlyGovernance() {
        require(
            governance == msg.sender,
            "ConvexBooster: caller is not the governance"
        );
        _;
    }

    modifier onlyLendingMarket() {
        require(
            lendingMarket == msg.sender,
            "ConvexBooster: caller is not the lendingMarket"
        );

        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    /* 
    The default governance user is GenerateLendingPools contract.
    It will be set to DAO in the future 
    */
    function setGovernance(address _governance) public onlyOwner {
        governance = _governance;

        emit SetGovernance(_governance);
    }

    function setLendingMarket(address _v) public onlyOwner {
        require(_v != address(0), "!_v");

        lendingMarket = _v;
    }

    function initialize(
        address _owner,
        address _originConvexBooster,
        address _convexRewardFactory,
        address _virtualBalanceWrapperFactory,
        address _rewardCrvToken,
        address _rewardCvxToken
    ) public initializer {
        owner = _owner;
        governance = _owner;
        convexRewardFactory = _convexRewardFactory;
        originConvexBooster = _originConvexBooster;
        virtualBalanceWrapperFactory = _virtualBalanceWrapperFactory;
        rewardCrvToken = _rewardCrvToken;
        rewardCvxToken = _rewardCvxToken;
        version = 1;

        emit Initialized(address(this));
    }

    

    function addConvexPool(uint256 _originConvexPid)
        public
        override
        onlyGovernance
    {
        (
            address lpToken,
            ,
            ,
            address originCrvRewards,
            address originStash,
            bool shutdown
        ) = IOriginConvexBooster(originConvexBooster).poolInfo(
                _originConvexPid
            );

        require(!shutdown, "!shutdown");
        require(lpToken != address(0), "!lpToken");

        ICurveRegistry registry = ICurveRegistry(
            ICurveAddressProvider(curveAddressProvider).get_registry()
        );

        address curveSwapAddress = registry.get_pool_from_lp_token(lpToken);

        address virtualBalance = IVirtualBalanceWrapperFactory(
            virtualBalanceWrapperFactory
        ).createWrapper(address(this));

        address rewardCrvPool = IConvexRewardFactory(convexRewardFactory)
            .createReward(rewardCrvToken, virtualBalance, address(this));

        address rewardCvxPool = IConvexRewardFactory(convexRewardFactory)
            .createReward(rewardCvxToken, virtualBalance, address(this));

        uint256 extraRewardsLength = IOriginConvexRewardPool(originCrvRewards)
            .extraRewardsLength();

        if (extraRewardsLength > 0) {
            for (uint256 i = 0; i < extraRewardsLength; i++) {
                address extraRewardToken = IOriginConvexRewardPool(
                    originCrvRewards
                ).extraRewards(i);

                address extraRewardPool = IConvexRewardFactory(
                    convexRewardFactory
                ).createReward(
                        IOriginConvexRewardPool(extraRewardToken).rewardToken(),
                        virtualBalance,
                        address(this)
                    );

                IConvexRewardPool(rewardCrvPool).addExtraReward(
                    extraRewardPool
                );
            }
        }

        poolInfo.push(
            PoolInfo({
                originConvexPid: _originConvexPid,
                curveSwapAddress: curveSwapAddress,
                lpToken: lpToken,
                originCrvRewards: originCrvRewards,
                originStash: originStash,
                virtualBalance: virtualBalance,
                rewardCrvPool: rewardCrvPool,
                rewardCvxPool: rewardCvxPool,
                shutdown: false
            })
        );
    }

    function updateExtraRewards(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        (
            ,
            ,
            ,
            address originCrvRewards,
            ,
            bool shutdown
        ) = IOriginConvexBooster(originConvexBooster).poolInfo(
                pool.originConvexPid
            );

        require(!shutdown, "!shutdown");

        uint256 originExtraRewardsLength = IOriginConvexRewardPool(
            originCrvRewards
        ).extraRewardsLength();

        uint256 currentExtraRewardsLength = IConvexRewardPool(
            pool.rewardCrvPool
        ).extraRewardsLength();

        for (
            uint256 i = currentExtraRewardsLength;
            i < originExtraRewardsLength;
            i++
        ) {
            address extraRewardToken = IOriginConvexRewardPool(originCrvRewards)
                .extraRewards(i);

            address extraRewardPool = IConvexRewardFactory(convexRewardFactory)
                .createReward(
                    IOriginConvexRewardPool(extraRewardToken).rewardToken(),
                    pool.virtualBalance,
                    address(this)
                );

            IConvexRewardPool(pool.rewardCrvPool).addExtraReward(
                extraRewardPool
            );

            emit UpdateExtraRewards(_pid, i, extraRewardPool);
        }
    }

    function toggleShutdownPool(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        pool.shutdown = !pool.shutdown;

        emit ToggleShutdownPool(_pid, pool.shutdown);
    }

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) public override onlyLendingMarket nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        IERC20(pool.lpToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        // (
        //     address lpToken,
        //     address token,
        //     address gauge,
        //     address crvRewards,
        //     address stash,
        //     bool shutdown
        // ) = IOriginConvexBooster(convexBooster).poolInfo(pool.convexPid);
        (, , , , , bool shutdown) = IOriginConvexBooster(originConvexBooster)
            .poolInfo(pool.originConvexPid);

        require(!shutdown, "!convex shutdown");
        require(!pool.shutdown, "!shutdown");

        IERC20(pool.lpToken).safeApprove(originConvexBooster, 0);
        IERC20(pool.lpToken).safeApprove(originConvexBooster, _amount);

        IOriginConvexBooster(originConvexBooster).deposit(
            pool.originConvexPid,
            _amount,
            true
        );

        IConvexRewardPool(pool.rewardCrvPool).stake(_user);
        IConvexRewardPool(pool.rewardCvxPool).stake(_user);

        IVirtualBalanceWrapper(pool.virtualBalance).stakeFor(_user, _amount);

        emit Deposited(_user, _pid, _amount);

        return true;
    }

    function withdrawMyTokens(uint256 _pid, uint256 _amount)
        public
        nonReentrant
    {
        require(_amount > 0, "!_amount");

        PoolInfo storage pool = poolInfo[_pid];

        frozenTokens[_pid][msg.sender] = frozenTokens[_pid][msg.sender].sub(
            _amount
        );

        IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(
            _amount,
            true
        );

        IERC20(pool.lpToken).safeTransfer(msg.sender, _amount);
    }

    function withdrawFor(
        uint256 _pid,
        uint256 _amount,
        address _user,
        bool _frozenTokens
    ) public override onlyLendingMarket nonReentrant returns (bool) {
        PoolInfo storage pool = poolInfo[_pid];

        if (_frozenTokens) {
            frozenTokens[_pid][_user] = frozenTokens[_pid][_user].add(_amount);
        } else {
            IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(
                _amount,
                true
            );

            IERC20(pool.lpToken).safeTransfer(_user, _amount);
        }

        if (IConvexRewardPool(pool.rewardCrvPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardCrvPool).getReward(_user);
        }

        if (IConvexRewardPool(pool.rewardCvxPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardCvxPool).getReward(_user);
        }

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(_user, _amount);

        IConvexRewardPool(pool.rewardCrvPool).withdraw(_user);
        IConvexRewardPool(pool.rewardCvxPool).withdraw(_user);

        emit Withdrawn(_user, _pid, _amount);

        return true;
    }

    function liquidate(
        uint256 _pid,
        int128 _coinId,
        address _user,
        uint256 _amount
    )
        external
        override
        onlyLendingMarket
        nonReentrant
        returns (address, uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];

        IOriginConvexRewardPool(pool.originCrvRewards).withdrawAndUnwrap(
            _amount,
            true
        );

        IVirtualBalanceWrapper(pool.virtualBalance).withdrawFor(_user, _amount);

        if (IConvexRewardPool(pool.rewardCrvPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardCrvPool).getReward(_user);
        }

        if (IConvexRewardPool(pool.rewardCvxPool).earned(_user) > 0) {
            IConvexRewardPool(pool.rewardCvxPool).getReward(_user);
        }

        IConvexRewardPool(pool.rewardCrvPool).withdraw(_user);
        IConvexRewardPool(pool.rewardCvxPool).withdraw(_user);

        IERC20(pool.lpToken).safeApprove(pool.curveSwapAddress, 0);
        IERC20(pool.lpToken).safeApprove(pool.curveSwapAddress, _amount);

        address underlyToken = ICurveSwap(pool.curveSwapAddress).coins(
            uint256(_coinId)
        );

        ICurveSwap(pool.curveSwapAddress).remove_liquidity_one_coin(
            _amount,
            _coinId,
            0
        );

        if (underlyToken == ZERO_ADDRESS) {
            uint256 totalAmount = address(this).balance;

            msg.sender.sendValue(totalAmount);

            return (ZERO_ADDRESS, totalAmount);
        } else {
            uint256 totalAmount = IERC20(underlyToken).balanceOf(address(this));

            IERC20(underlyToken).safeTransfer(msg.sender, totalAmount);

            return (underlyToken, totalAmount);
        }
    }

    function getRewards(uint256 _pid) public nonReentrant {
        PoolInfo memory pool = poolInfo[_pid];

        if (IConvexRewardPool(pool.rewardCrvPool).earned(msg.sender) > 0) {
            IConvexRewardPool(pool.rewardCrvPool).getReward(msg.sender);
        }

        if (IConvexRewardPool(pool.rewardCvxPool).earned(msg.sender) > 0) {
            IConvexRewardPool(pool.rewardCvxPool).getReward(msg.sender);
        }
    }

    function claimRewardToken(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        IOriginConvexRewardPool(pool.originCrvRewards).getReward(
            address(this),
            true
        );

        address rewardUnderlyToken = IOriginConvexRewardPool(
            pool.originCrvRewards
        ).rewardToken();
        uint256 crvBalance = IERC20(rewardUnderlyToken).balanceOf(
            address(this)
        );

        if (crvBalance > 0) {
            IERC20(rewardUnderlyToken).safeTransfer(
                pool.rewardCrvPool,
                crvBalance
            );

            IConvexRewardPool(pool.rewardCrvPool).notifyRewardAmount(
                crvBalance
            );
        }

        uint256 extraRewardsLength = IConvexRewardPool(pool.rewardCrvPool)
            .extraRewardsLength();

        for (uint256 i = 0; i < extraRewardsLength; i++) {
            address currentExtraReward = IConvexRewardPool(pool.rewardCrvPool)
                .extraRewards(i);
            address originExtraRewardToken = IOriginConvexRewardPool(
                pool.originCrvRewards
            ).extraRewards(i);
            address extraRewardUnderlyToken = IOriginConvexVirtualBalanceRewardPool(
                    originExtraRewardToken
                ).rewardToken();
            IOriginConvexVirtualBalanceRewardPool(originExtraRewardToken)
                .getReward(address(this));
            uint256 extraBalance = IERC20(extraRewardUnderlyToken).balanceOf(
                address(this)
            );
            if (extraBalance > 0) {
                IERC20(extraRewardUnderlyToken).safeTransfer(
                    currentExtraReward,
                    extraBalance
                );
                IConvexRewardPool(currentExtraReward).notifyRewardAmount(
                    extraBalance
                );
            }
        }

        /* cvx */
        uint256 cvxBal = IERC20(rewardCvxToken).balanceOf(address(this));

        if (cvxBal > 0) {
            IERC20(rewardCvxToken).safeTransfer(pool.rewardCvxPool, cvxBal);

            IConvexRewardPool(pool.rewardCvxPool).notifyRewardAmount(cvxBal);
        }
    }

    function claimAllRewardToken() public {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            claimRewardToken(i);
        }
    }

    receive() external payable {}

    /* view functions */
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "./IConvexBooster.sol";

interface IOriginConvexBooster {
    function deposit( uint256 _pid, uint256 _amount, bool _stake ) external returns (bool);
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);
    function claimStashToken(address _token, address _rewardAddress, address _lfRewardAddress, uint256 _rewards) external;
    function poolInfo(uint256) external view returns(address,address,address,address,address, bool);
    function isShutdown() external view returns(bool);
    function minter() external view returns(address);
    function earmarkRewards(uint256) external returns(bool);
}

interface IOriginConvexRewardPool {
    function getReward() external returns(bool);
    function getReward(address _account, bool _claimExtras) external returns(bool);
    function withdrawAllAndUnwrap(bool claim) external;
    function withdrawAndUnwrap(uint256 amount, bool claim) external returns(bool);
    function withdrawAll(bool claim) external;
    function withdraw(uint256 amount, bool claim) external returns(bool);
    function stakeFor(address _for, uint256 _amount) external returns(bool);
    function stakeAll() external returns(bool);
    function stake(uint256 _amount) external returns(bool);
    function earned(address account) external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function rewardToken() external returns(address);
    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
}

interface IOriginConvexVirtualBalanceRewardPool {
    function getReward(address _account) external;
    function getReward() external;
    function rewardToken() external returns(address);
}

interface IConvexRewardPool {
    function earned(address account) external view returns (uint256);
    function stake(address _for) external;
    function withdraw(address _for) external;
    function getReward(address _for) external;
    function notifyRewardAmount(uint256 reward) external;

    function extraRewards(uint256 _idx) external view returns (address);
    function extraRewardsLength() external view returns (uint256);
    function addExtraReward(address _reward) external returns(bool);
}

interface IConvexRewardFactory {
    function createReward(address _reward, address _virtualBalance, address _operator) external returns (address);
}

interface ICurveSwap {
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
    /* function remove_liquidity(uint256 _token_amount, uint256[] memory min_amounts) external; */
    function coins(uint256 _coinId) external view returns(address);
    function balances(uint256 _coinId) external view returns(uint256);
}

interface ICurveAddressProvider{
    function get_registry() external view returns(address);
    function get_address(uint256 _id) external view returns(address);
}

interface ICurveRegistry{
    function gauge_controller() external view returns(address);
    function get_lp_token(address) external view returns(address);
    function get_pool_from_lp_token(address) external view returns(address);
    function get_gauges(address) external view returns(address[10] memory,uint128[10] memory);
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ConvexInterfaces.sol";
import "../common/IVirtualBalanceWrapper.sol";

contract ConvexRewardPool is ReentrancyGuard, IConvexRewardPool {
    using Address for address payable;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public rewardToken;
    uint256 public constant duration = 7 days;

    address public owner;
    address public virtualBalance;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    address[] public override extraRewards;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user);
    event Withdrawn(address indexed user);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    constructor(
        address _reward,
        address _virtualBalance,
        address _owner
    ) public {
        rewardToken = _reward;
        virtualBalance = _virtualBalance;
        owner = _owner;
    }

    function totalSupply() public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).totalSupply();
    }

    function balanceOf(address _for) public view returns (uint256) {
        return IVirtualBalanceWrapper(virtualBalance).balanceOf(_for);
    }

    function extraRewardsLength() external view override returns (uint256) {
        return extraRewards.length;
    }

    function addExtraReward(address _reward) external override returns (bool) {
        require(
            msg.sender == owner,
            "ConvexRewardPool: !authorized addExtraReward"
        );
        require(_reward != address(0), "!reward setting");

        extraRewards.push(_reward);
        return true;
    }

    function clearExtraRewards() external {
        require(
            msg.sender == owner,
            "ConvexRewardPool: !authorized clearExtraRewards"
        );

        delete extraRewards;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address _for) public view override returns (uint256) {
        uint256 total = balanceOf(_for)
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[_for]))
            .div(1e18)
            .add(rewards[_for]);

        for (uint256 i = 0; i < extraRewards.length; i++) {
            total = total.add(IConvexRewardPool(extraRewards[i]).earned(_for));
        }

        return total;
    }

    function stake(address _for)
        public
        override
        nonReentrant
        updateReward(_for)
    {
        require(msg.sender == owner, "ConvexRewardPool: !authorized stake");

        emit Staked(_for);
    }

    function withdraw(address _for)
        public
        override
        nonReentrant
        updateReward(_for)
    {
        require(msg.sender == owner, "ConvexRewardPool: !authorized withdraw");

        emit Withdrawn(_for);
    }

    function getReward(address _for)
        public
        override
        nonReentrant
        updateReward(_for)
    {
        uint256 reward = earned(_for);

        if (reward > 0) {
            rewards[_for] = 0;

            if (rewardToken != address(0)) {
                IERC20(rewardToken).safeTransfer(_for, reward);
            } else {
                require(
                    address(this).balance >= reward,
                    "!address(this).balance"
                );

                payable(_for).sendValue(reward);
            }

            emit RewardPaid(_for, reward);
        }

        for (uint256 i = 0; i < extraRewards.length; i++) {
            IConvexRewardPool(extraRewards[i]).getReward(_for);
        }
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        updateReward(address(0))
    {
        require(
            msg.sender == owner,
            "ConvexRewardPool: !authorized notifyRewardAmount"
        );
        // overflow fix according to https://sips.synthetix.io/sips/sip-77
        require(
            reward < uint256(-1) / 1e18,
            "the notified reward cannot invoke multiplication overflow"
        );

        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    receive() external payable {}
}

contract ConvexRewardFactory {
    address public owner;

    event CreateReward(IConvexRewardPool rewardPool, address rewardToken);

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _owner) external {
        require(
            msg.sender == owner,
            "ConvexRewardFactory: !authorized setOwner"
        );

        owner = _owner;
    }

    function createReward(
        address _rewardToken,
        address _virtualBalance,
        address _owner
    ) external returns (address) {
        require(
            msg.sender == owner,
            "ConvexRewardFactory: !authorized createReward"
        );

        IConvexRewardPool rewardPool = IConvexRewardPool(
            address(new ConvexRewardPool(_rewardToken, _virtualBalance, _owner))
        );

        emit CreateReward(rewardPool, _rewardToken);

        return address(rewardPool);
    }
}

// SPDX-License-Identifier: UNLICENSED
/* 

  _                          _   _____   _                       
 | |       ___   _ __     __| | |  ___| | |   __ _   _ __    ___ 
 | |      / _ \ | '_ \   / _` | | |_    | |  / _` | | '__|  / _ \
 | |___  |  __/ | | | | | (_| | |  _|   | | | (_| | | |    |  __/
 |_____|  \___| |_| |_|  \__,_| |_|     |_|  \__,_| |_|     \___|
                                                                 
LendFlare.finance
*/

pragma solidity =0.6.12;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    struct Layer {
        address token;
        uint96 startTime;
        uint96 endTime;
        mapping(uint256 => uint256) claimed;
    }

    mapping(bytes32 => Layer) public layers;

    address public owner;

    event Claimed(address account, address token, uint256 amount);
    event SetOwner(address owner);

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;

        emit SetOwner(_owner);
    }

    constructor() public {
        owner = msg.sender;
    }

    function newlayer(
        bytes32 merkleRoot,
        address token,
        uint96 startTime,
        uint96 endTime
    ) external onlyOwner {
        require(
            layers[merkleRoot].token == address(0),
            "merkleRoot already register"
        );
        require(merkleRoot != bytes32(0), "empty root");
        require(token != address(0), "empty token");
        require(startTime < endTime, "wrong dates");

        Layer storage _layer = layers[merkleRoot];
        _layer.token = token;
        _layer.startTime = startTime;
        _layer.endTime = endTime;
    }

    function isClaimed(bytes32 merkleRoot, uint256 index)
        public
        view
        returns (bool)
    {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = layers[merkleRoot].claimed[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);

        return claimedWord & mask == mask;
    }

    function _setClaimed(bytes32 merkleRoot, uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        layers[merkleRoot].claimed[claimedWordIndex] =
            layers[merkleRoot].claimed[claimedWordIndex] |
            (1 << claimedBitIndex);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProofs
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(index, account, amount));
        bytes32 merkleRoot = processProof(merkleProofs, leaf);

        require(layers[merkleRoot].token != address(0), "empty token");
        require(
            layers[merkleRoot].startTime < block.timestamp &&
                layers[merkleRoot].endTime >= block.timestamp,
            "out of time"
        );

        require(!isClaimed(merkleRoot, index), "already claimed");

        _setClaimed(merkleRoot, index);

        IERC20(layers[merkleRoot].token).safeTransfer(account, amount);

        emit Claimed(account, address(layers[merkleRoot].token), amount);
    }

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }
        }

        return computedHash;
    }
}