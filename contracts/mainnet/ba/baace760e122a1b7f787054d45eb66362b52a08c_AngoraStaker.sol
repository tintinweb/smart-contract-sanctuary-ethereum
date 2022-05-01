/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
// File: AngoraStaker.sol


// File: anotest.sol



pragma solidity ^0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
     * @dev Returns the amount of decimals in the token
     */
    function decimals() external view returns (uint256);

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    /**
     * @dev Returns the floor of the division of two numbers
     *
     * This divides two numbers and rounds down
     */
    function floorDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        return a / b - (a % b == 0 ? 1 : 0);
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

// solhint-disable not-rely-on-time, avoid-low-level-calls
contract AngoraStaker is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public stakingToken; // Staking token

    uint256 private _totalSupply; // Total staked amount
    uint256 private _totalRewards;  // Total amount for rewards
    uint256 private _stakeRequired = 100e18; // Minimum stake amount

    // Set standard contract data in ContractData struct
    ContractData private _data = ContractData({
        isActive: 0,
        reentrant: 1,
        timeFinished: 0,
        baseMultiplier: 1e18
    });

    mapping (address => UserDeposit) private _deposits; // Track all user deposits
    mapping (address => uint256) private _userRewardPaid; // Track all user claims

    // Store global contract data in packed struct
    struct ContractData {
        uint8 isActive;
        uint8 reentrant;
        uint64 timeFinished;
        uint64 baseMultiplier;
    }

    // Store user deposit data in packed struct
    struct UserDeposit {
        uint8 lock; // 1 = 1 7 days; 2 = 30 days; 3 = 90 days
        uint64 timestamp;
        uint256 staked;
    }

    constructor(IERC20 ) {
        stakingToken = IERC20(0x60a5C1c2f75f61B1B8aDFD66B04dcE40d29fEecE);
    }

    // ===== MODIFIERS ===== //

    /**
     * @dev Reentrancy protection
     */
    modifier nonReentrant()
    {
        require(_data.reentrant == 1, "Reentrancy not allowed");
        _data.reentrant = 2;
        _;
        _data.reentrant = 1;
    }

    // ===== PAYABLE DEFAULTS ====== //

   

    // ===== VIEW FUNCTIONS ===== //

    /**
     * @dev Check total amount staked
     *
     * @return totalSupply the total amount staked
     */
    function totalSupply() external view returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @dev Check total rewards amount
     *
     * @notice this assumes that staking token is the same as reward token
     *
     * @return totalRewards the total balance of contract - amount staked
     */
    function totalRewards() external view returns (uint256)
    {
        return _totalRewards;
    }

    /**
     * @dev Check base multiplier of contract
     *
     * @notice Normalized to 1e18 = 100%. Contract currently uses a 1x, 2x, and 3x multiplier
     * based on how long the user locks their stake for (in UserDeposit struct).
     * Therefore max baseMultiplier would be <= 333e15 (33.3%).
     *
     * @return baseMultiplier 1e18 normalized percentage to start 
     */
    function baseMultiplier() external view returns (uint256)
    {
        return _data.baseMultiplier;
    }

    /**
     * @dev Checks amount staked for account.
     *
     * @param account the user account to look up.
     *
     * @return staked the total amount staked from account.
     */
    function balanceOf(address account) external view returns (uint256)
    {
        return _deposits[account].staked;
    }

    /**
     * @dev Checks all user deposit data for account.
     *
     * @param account the user account to look up.
     *
     * @return userDeposit the entire deposit data.
     */
    function getDeposit(address account) external view returns (UserDeposit memory)
    {
        return _deposits[account];
    }

    /**
     * @dev Checks if staking contract is active.
     *
     * @notice _isActive is stored as uint where 0 = false; 1 = true.
     *
     * @return isActive boolean true if 1; false if not.
     */
    function isActive() external view returns (bool)
    {
        return _data.isActive == 1;
    }

    /**
     * @dev Check current minimum stake amount
     *
     * @return minimum the min stake amount
     */
    function getMinimumStake() external view returns (uint256)
    {
        return _stakeRequired;
    }

    /**
     * @dev Checks when staking finished.
     *
     * @notice if 0, staking is still active.
     *
     * @return timeFinished the block timestamp of when staking completed.
     */
    function timeEnded() external view returns (uint256)
    {
        return _data.timeFinished;
    }

    /**
     * @dev Checks pending rewards currently accumulating for month.
     *
     * @notice These rewards are prorated for the current period (month).
     * Users cannot withdraw rewards until a full month has passed.
     * If a user makes an additional deposit mid-month, these pending rewards
     * will be added to their new staked amount, and lock time reset.
     *
     * @param account the user account to use for calculation.
     *
     * @return pending the pending reward for the current period.
     */
    function pendingReward(address account) public view returns (uint256)
    {
        // If staking rewards are finished, should always return 0
        if (_data.timeFinished > 0) {
            return 0;
        }

        // Get deposit record for account
        UserDeposit memory userDeposit = _deposits[account];

        if (userDeposit.staked == 0) {
            return 0;
        }

        // Calculate total time, week/months, and time delta between
        uint256 timePassed = block.timestamp - userDeposit.timestamp;
        uint256 daysPassed = timePassed > 0 ? Math.floorDiv(timePassed, 86400) : 0;
        uint256 interimTime = timePassed - (daysPassed * 86400);

        // Calculate pending rewards based on prorated time from the current period
        uint256 pending = userDeposit.staked * (_data.baseMultiplier * uint256(userDeposit.lock)) / 1e18 * interimTime / 2628000;
        return pending;
    }

    /**
     * @dev Checks current earned rewards for account.
     *
     * @notice These rewards are calculated by the number of full week/months
     * passed since deposit, based on the multiplier set by the user based on
     * lockup time (i.e. 1x for 7 days, 2x for 30 days, 3x for 90 days).
     * This function subtracts withdrawn rewards from the calculation so if
     * total rewards are 100 coins, but 50 are withdrawn,
     * it should return 50.
     *
     * @param account the user account to use for calculation.
     *
     * @return totalReward the total rewards the user has earned.
     */
    function earned(address account) public view returns (uint256)
    {
        // Get deposit record for account
        UserDeposit memory userDeposit = _deposits[account];
        
        // Get total rewards paid already
        uint256 rewardPaid = _userRewardPaid[account];

        // If a final timestamp is set, use that instead of current timestamp
        uint256 endTime = _data.timeFinished == 0 ? block.timestamp : _data.timeFinished;
        uint256 daysPassed = Math.floorDiv(endTime - userDeposit.timestamp, 86400);

        // If no days have passed, return 0
        if (daysPassed == 0) return 0;

        // Calculate total earned - amount already paid
        uint256 totalReward = userDeposit.staked * ((_data.baseMultiplier * userDeposit.lock) * daysPassed) / 1e18 - rewardPaid;
        
        return totalReward;
    }

    /**
     * @dev Check if user can withdraw their stake.
     *
     * @notice uses the user's lock chosen on deposit, multiplied
     * by the amount of seconds in a day.
     *
     * @param account the user account to check.
     *
     * @return canWithdraw boolean value determining if user can withdraw stake.
     */
    function withdrawable(address account) public view returns (bool)
    {
        UserDeposit memory userDeposit = _deposits[account];
        uint256 unlockTime = _getUnlockTime(userDeposit.timestamp, userDeposit.lock);
        
        if (block.timestamp < unlockTime) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @dev Check if current time past lock time.
     *
     * @param timestamp the user's initial lock time.
     * @param lock the lock multiplier chosen (1 = 7 days, 2 = 30 days, 3 = 90 days).
     *
     * @return unlockTime the timestamp after which a user can withdraw.
     */
    function _getUnlockTime(uint64 timestamp, uint8 lock) private pure returns (uint256)
    {
        if (lock == 1) {
            // Add one week
            return timestamp + (86400 * 7);
        } else if (lock == 2) {
            // Add one months
            return timestamp + (86400 * 30);            
        } else {
            // Add three months
            return timestamp + (86400 * 90);
        }
    }

    // ===== MUTATIVE FUNCTIONS ===== //

    /**
     * @dev Deposit and stake funds
     *
     * @param amount the amount of tokens to stake
     * @param lock the lock multiplier (1 = 7 days, 2 = 30 days, 3 = 90 days).
     *
     * @notice Users cannot change lock periods if adding additional stake
     */
    function deposit(uint256 amount, uint8 lock) external payable nonReentrant
    {
        // Check if staking is active
        require(_data.isActive != 0, "Staking inactive");
        require(lock > 0 && lock < 4, "Lock must be 1, 2, or 3");
        require(amount > 0, "Amount cannot be 0");

        // Get existing user deposit. All 0s if non-existent
        UserDeposit storage userDeposit = _deposits[msg.sender];

        require(userDeposit.staked + amount >= _stakeRequired, "Need to meet minimum stake");

        // Transfer token
        stakingToken.transferFrom(msg.sender, address(this), amount);

        // If user's current stake is greater than 0, we need to get
        // earned and pending rewards and add them to stake and total
        if (userDeposit.staked > 0) {
            uint256 earnedAmount = earned(msg.sender);
            uint256 pendingAmount = pendingReward(msg.sender);
            uint256 combinedAmount = earnedAmount + pendingAmount;

            // Update user's claimed amount
            _userRewardPaid[msg.sender] += combinedAmount;

            // Update total rewards by subtracting earned/pending amounts
            _totalRewards -= combinedAmount;

            // Update total supply and current stake
            _totalSupply += amount + combinedAmount;

            // Save new deposit data
            userDeposit.staked += amount + combinedAmount;
            userDeposit.timestamp = uint64(block.timestamp);

            if (lock > userDeposit.lock || block.timestamp > _getUnlockTime(userDeposit.timestamp, userDeposit.lock)) {
                userDeposit.lock = lock;
            }
        } else {
            // Create new deposit record for user with new lock time
            userDeposit.lock = lock;
            userDeposit.timestamp = uint64(block.timestamp);
            userDeposit.staked = amount;

            // Add new amount to total supply
            _totalSupply += amount;
        }

        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraws a user's stake.
     *
     * @param amount the amount to withdraw.
     *
     * @notice must be past unlock time.
     */
    function withdraw(uint256 amount) external payable nonReentrant
    {
        // Get user deposit info in storage
        UserDeposit storage userDeposit = _deposits[msg.sender];

        // Check if user can withdraw amount
        require(userDeposit.staked > 0, "User has no stake");
        require(withdrawable(msg.sender), "Lock still active");
        require(amount <= userDeposit.staked, "Withdraw amount too high");

        // Get earned rewards and paid rewards
        uint256 earnedRewards = earned(msg.sender);

        // Calculate amount to withdraw
        uint256 amountToWithdraw = amount + earnedRewards;

        // Check if user is withdrawing their total stake
        if (userDeposit.staked == amount) {
            // If withdrawing full amount we no longer care about paid rewards
            _userRewardPaid[msg.sender] = 0;
            // We only need to set staked to 0 because it is the only
            // value checked on future deposits
            userDeposit.staked = 0;
        } else {
            uint256 daysForStaking;
            if (userDeposit.lock == 1) {
                daysForStaking = 7;
            } else if (userDeposit.lock == 2) {
                daysForStaking = 30;
            } else if (userDeposit.lock == 3) {
                daysForStaking = 90;
            }
            // Remove amount from staked
            userDeposit.staked -= amount;
            // Start fresh
            _userRewardPaid[msg.sender] = 0;
            // Set new timestamp to 7, 30, or 90 days prior so users can still withdraw
            // from original stake time but rewards essentially restart
            userDeposit.timestamp = uint64(block.timestamp - (86400 * daysForStaking));
            _userRewardPaid[msg.sender] = earned(msg.sender);
        }

        // Update total staked amount and rewards amount
        _totalSupply -= amount;
        _totalRewards -= earnedRewards;

        // Transfer tokens to user
        stakingToken.safeTransfer(msg.sender, amountToWithdraw);

        emit Withdrawal(msg.sender, amount);
    }

    /**
     * @dev Emergency withdrawal in case rewards have been pulled
     *
     * @notice Only available after staking is closed and
     * all reward tokens have been withdrawn.
     */
    function emergencyWithdrawal() external payable
    {
        require(_data.isActive == 0, "Staking must be closed");
        require(_data.timeFinished > 0, "Staking must be closed");
        require(_totalRewards == 0, "Use normal withdraw");

        // Get user deposit info
        uint256 amountToWithdraw = _deposits[msg.sender].staked;
        require(amountToWithdraw > 0, "No stake to withdraw");

        // Reset all data
        _userRewardPaid[msg.sender] = 0;
        _deposits[msg.sender].staked = 0;

        // Update total staked amount
        _totalSupply -= amountToWithdraw;

        // Transfer tokens to user
        stakingToken.safeTransfer(msg.sender, amountToWithdraw);

        emit Withdrawal(msg.sender, amountToWithdraw);
    }

    /**
     * @dev Claims earned rewards.
     */
    function claimRewards() external payable nonReentrant
    {
        // Get user's earned rewards
        uint256 amountToWithdraw = earned(msg.sender);
        
        require(amountToWithdraw > 0, "No rewards to withdraw");
        require(amountToWithdraw <= _totalRewards, "Not enough rewards in contract");

        // Add amount to user's withdraw rewards
        _userRewardPaid[msg.sender] += amountToWithdraw;

        // Update total rewards
        _totalRewards -= amountToWithdraw;

        stakingToken.safeTransfer(msg.sender, amountToWithdraw);

        emit RewardsClaimed(amountToWithdraw);
    }

    /**
     * @dev Update minimum stake amount
     *
     * @param minimum the new minimum stake account
     */
    function updateMinimum(uint256 minimum) external payable onlyOwner
    {
        _stakeRequired = minimum;
        
        emit MinimumUpdated(minimum);
    }

  function updateMultiplier(uint64 multiplier) external payable onlyOwner
    {
        _data.baseMultiplier = multiplier;
        
        emit MultiplierUpdated(multiplier);
    }
    /**
     * @dev Funds rewards for contract
     *
     * @param amount the amount of tokens to fund
     */
    function fundStaking(uint256 amount) external payable onlyOwner
    {
        require(amount > 0, "Amount cannot be 0");

        _totalRewards += amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit StakingFunded(amount);
    }

    /**
     * @dev Withdraws rewards tokens
     *
     * @notice Requires rewards to be closed. This
     * function is intended to pull leftover tokens
     * once all users have claimed rewards.
     */
    function withdrawRewardTokens() external payable onlyOwner
    {
        require(_data.timeFinished > 0, "Staking must be complete");

        uint256 amountToWithdraw = _totalRewards;
        _totalRewards = 0;

        stakingToken.safeTransfer(owner(), amountToWithdraw);
    }

    /**
     * @dev Closes reward period
     *
     * @notice This is a one-way function. Once staking is closed, it
     * cannot be re-enabled. Use cautiously.
     */
    function closeRewards() external payable onlyOwner
    {
        require(_data.isActive == 1, "Contract already inactive");
        _data.isActive = 0;
        _data.timeFinished = uint64(block.timestamp);
        
        emit StakingEnded(block.timestamp);
    }

    /**
     * @dev Enables staking
     */
    function enableStaking() external payable onlyOwner
    {
        require(_data.isActive == 0, "Staking already active");
        _data.isActive = 1;

        emit StakingEnabled();
    }

    // ===== EVENTS ===== //

    event StakingFunded(uint256 amount);
    event StakingEnabled();
    event StakingEnded(uint256 timestamp);
    event RewardsClaimed(uint256 amount);
    event Deposited(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);
    event MinimumUpdated(uint256 newMinimum);
    event MultiplierUpdated(uint256 newMultiplier);
}