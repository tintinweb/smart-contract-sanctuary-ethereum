/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactionInfos the account sending and
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
 // CAUTION
 // This version of SafeMath should only be used with Solidity 0.8 or later,
 // because it relies on the compiler's built in overflow checks.
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */

    function burnFrom(address account, uint256 amount) external;
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
 *  @dev YouWant. Team
 */
 
contract DividendsContract is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 depositAmount; 
        uint256 mintAmount;
        DepositInfo[] depositInfo;
    }

   struct DepositInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 depositBlock;
        bool active;
    }

    struct PoolInfo {
        IERC20 lpToken; 
        uint256 tokenPerBlock;
        uint256 accTokenPerShare; 
        uint256 lastUpdateBlock;
        bool active;
    }

    IERC20 public rewardToken;
    uint256 public rewardTokenAccuracy;
    uint256 public lpTokenAccuracy;
    bool public emergencyWithdrawSwitch;
    bool public enableContract;

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public userTotalDepositAmount;
    mapping(uint256 => mapping(uint256 => uint256)) public currentAccTokenPerShare;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Claim(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user,uint256 indexed pid, uint256 amount);

    constructor(
        address _rewardTokenContract,
        uint8 _rewardTokenAccuracy
    ) {
        setRewardTokenContract(_rewardTokenContract);
        setRewardTokenAccuracy(_rewardTokenAccuracy);
        setLPTokenAccuracy(18);
    }

    modifier validatePoolByPid(uint256 _pid) {
        require (_pid < poolInfo.length , "Pool does not exist") ;
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(IERC20 _lpToken,uint256 _tokenPerBlock) public onlyOwner {
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            tokenPerBlock: _tokenPerBlock,
            accTokenPerShare: 0,
            lastUpdateBlock: block.number,
            active: true
        }));
    }

    function set(uint256 _pid, uint256 _tokenPerBlock) public validatePoolByPid(_pid) onlyOwner {
        updatePool(_pid);
        poolInfo[_pid].tokenPerBlock = _tokenPerBlock;
    }

    function setPoolActive(uint256 _pid,bool _active) public validatePoolByPid(_pid) onlyOwner {
        poolInfo[_pid].active = _active;
    }

    function getBlockInterval(uint256 _from, uint256 _to) internal pure returns (uint256) {
		return _to.sub(_from);
    }

    function pendingReward(uint256 _pid, address _user) public view validatePoolByPid(_pid) returns (uint256 totalPending) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastUpdateBlock && lpSupply != 0) {
            uint256 blockInterval = getBlockInterval(pool.lastUpdateBlock, block.number);
            uint256 tokenReward = blockInterval.mul(pool.tokenPerBlock);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        for (uint256 i = 0; i < user.depositInfo.length; i++) {
            if(user.depositInfo[i].active == true) {
                uint256 markAccTokenPerShare = currentAccTokenPerShare[_pid][user.depositInfo[i].depositBlock];
                uint256 pending = user.depositInfo[i].amount.mul((accTokenPerShare.sub(markAccTokenPerShare))).div(1e12).sub(user.depositInfo[i].rewardDebt);
                totalPending = totalPending.add(pending);
            }
        }
        return totalPending;
    }

    function myPendingReward(uint256 _pid, address _user) internal validatePoolByPid(_pid) returns (uint256 totalPending) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        for (uint256 i = 0; i < user.depositInfo.length; i++) {
            if(user.depositInfo[i].active == true) {
                uint256 pending = user.depositInfo[i].amount.mul((pool.accTokenPerShare.sub(currentAccTokenPerShare[_pid][user.depositInfo[i].depositBlock]))).div(1e12).sub(user.depositInfo[i].rewardDebt);
                user.depositInfo[i].rewardDebt = user.depositInfo[i].rewardDebt.add(pending);
                totalPending = totalPending.add(pending);
            }
        }
        return totalPending;
    }

    function getMyRewardDebt(uint256 _pid, address _user) external view validatePoolByPid(_pid) returns(uint256 totalRewardDebt) {
        UserInfo storage user = userInfo[_pid][_user];
        for (uint256 i = 0; i < user.depositInfo.length; i++) {
            if(user.depositInfo[i].active == true) {
                uint256 rewardDebt = user.depositInfo[i].rewardDebt;
                totalRewardDebt = totalRewardDebt.add(rewardDebt);
            }
        }
        return totalRewardDebt;
    }

    function updatePool(uint256 _pid) internal validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastUpdateBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastUpdateBlock = block.number;
            currentAccTokenPerShare[_pid][pool.lastUpdateBlock] = pool.accTokenPerShare;
            return;
        }
        uint256 blockInterval = getBlockInterval(pool.lastUpdateBlock, block.number);
        uint256 tokenReward = blockInterval.mul(pool.tokenPerBlock);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastUpdateBlock = block.number;
        currentAccTokenPerShare[_pid][pool.lastUpdateBlock] = pool.accTokenPerShare;
    }

    function deposit(uint256 _pid, uint256 _amount) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(enableContract == true,"deposit: The contract has not started");
        require(pool.active == true,"deposit: The pool is paused");
        require(_amount > 0,"deposit: input amount must be greater than 0");
        updatePool(_pid);
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.depositInfo.push(DepositInfo({
            amount: _amount,
            rewardDebt: 0,
            depositBlock: block.number,
            active: true
        }));
        user.depositAmount = user.depositAmount.add(_amount);
        userTotalDepositAmount[msg.sender] = userTotalDepositAmount[msg.sender].add(_amount);
        emit Deposit(msg.sender, _pid, _amount);
    }
        
    function claim(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(enableContract == true,"claim: The contract has not started");
        require(pool.active == true,"claim: The pool is paused");
        require(user.depositAmount > 0,"claim: you have not pledged");
        require(IERC20(rewardToken).balanceOf(address(this)) > 0,"claim: The reward token balance of this contract is zero"); 
        require(pendingReward(_pid,msg.sender) > 0,"claim: You have no reward tokens to claim");
        updatePool(_pid);
        uint256 deservedReward = myPendingReward(_pid, msg.sender);
        user.mintAmount = user.mintAmount.add(deservedReward);
        uint256 actualReward = deservedReward.div(lpTokenAccuracy.div(rewardTokenAccuracy));
        safeTokenTransfer(msg.sender, actualReward);
        emit Claim(msg.sender, _pid, deservedReward);
    }

    function withdraw(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(enableContract == true,"withdraw: The contract has not started");
        require(pool.active == true,"withdraw: The pool is paused");
        require(user.depositAmount > 0,"withdraw: you have not deposited");
        updatePool(_pid);
        if(pendingReward(_pid, msg.sender) > 0 && IERC20(rewardToken).balanceOf(address(this)) > 0){
            uint256 deservedReward = myPendingReward(_pid, msg.sender);
            user.mintAmount = user.mintAmount.add(deservedReward);
            uint256 actualReward = deservedReward.div(lpTokenAccuracy.div(rewardTokenAccuracy));
            safeTokenTransfer(msg.sender, actualReward);
            emit Claim(msg.sender, _pid, deservedReward);
        }
        pool.lpToken.safeTransfer(address(msg.sender), user.depositAmount);
        emit Withdraw(msg.sender, _pid, user.depositAmount);
        userTotalDepositAmount[msg.sender] = userTotalDepositAmount[msg.sender].sub(user.depositAmount);
        user.depositAmount = 0;
        deleteAllWithdrawTX(_pid);
    }

    function emergencyWithdraw(uint256 _pid) public validatePoolByPid(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(enableContract == true,"emergencyWithdraw: The contract has not started");
        require(emergencyWithdrawSwitch == true,"emergencyWithdraw: Management does not turn on the emergency withdrawal option");
        require(user.depositAmount > 0,"emergencyWithdraw: user amount must be greater than 0");
        pool.lpToken.safeTransfer(address(msg.sender), user.depositAmount);
        emit EmergencyWithdraw(msg.sender, _pid, user.depositAmount);
        userTotalDepositAmount[msg.sender] = userTotalDepositAmount[msg.sender].sub(user.depositAmount);
        user.depositAmount = 0;
        deleteAllWithdrawTX(_pid);
    }

    function deleteAllWithdrawTX(uint256 _pid) private validatePoolByPid(_pid) {
        for (uint256 i = 0; i < userInfo[_pid][msg.sender].depositInfo.length; i++) {
            if (userInfo[_pid][msg.sender].depositInfo[i].active == true) {
                userInfo[_pid][msg.sender].depositInfo[i].active = false;
            }
        }
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
        if (_amount > rewardTokenBalance) {
            IERC20(rewardToken).transfer(_to, rewardTokenBalance);
        } else {
            IERC20(rewardToken).transfer( _to, _amount);
        }
    }

    function retrieve() public onlyOwner {
        uint256 rewardTokenBalance = IERC20(rewardToken).balanceOf(address(this));
        safeTokenTransfer(msg.sender, rewardTokenBalance);
    }

    function getUserTotalDepositAmount(address addr) public view returns (uint256) {
        return userTotalDepositAmount[addr];
    }

    function getUserDepositAmountByPid(uint256 pid, address addr) public view validatePoolByPid(pid) returns (uint256) {
        return userInfo[pid][addr].depositAmount;
    }

    function setRewardTokenContract(address _token) public onlyOwner {
        rewardToken = IERC20(_token);
    }

    function setRewardTokenAccuracy(uint8 _newAccuracy) public onlyOwner {
        rewardTokenAccuracy = 10 ** _newAccuracy;
    }

    function setLPTokenAccuracy(uint8 _newAccuracy) public onlyOwner {
        lpTokenAccuracy = 10 ** _newAccuracy;
    }

    function setEnableContract(bool _value) public onlyOwner {
        enableContract = _value;
    }

    function setEmergencyWithdrawSwitch(bool _value) public onlyOwner {
        emergencyWithdrawSwitch = _value;
    }
}