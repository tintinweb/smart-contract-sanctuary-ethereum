/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT

// Dependency file: @openzeppelin/contracts/utils/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// import "@openzeppelin/contracts/utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol

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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol

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


// Dependency file: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/math/SafeMath.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/ethereum/interfaces/IPoolFactory.sol

interface IPoolFactory {
    function updateTVL(uint256 tvl) external;

    function flushReward(address user, uint256 amount) external;

    function getTotalTVLWeight() external view returns (uint256 lockedPoolTvlWeight, uint256 unlockedPoolTvlWeight);

    function getPoolShare(address pool) external view returns (uint256 amount);
}


// Dependency file: contracts/ethereum/interfaces/IERC20Mintable.sol

/**
 * @notice Interface for minting any ERC20 token
 */
interface IERC20Mintable {
    function mint(address _to, uint256 _amount) external returns (uint256);
}


// Dependency file: contracts/ethereum/Errors.sol

library Errors {
    string public constant ONLY_WHEN_DEPOSITED = '1';
    string public constant ONLY_DEPOSITOR = '2';
    string public constant VESTED_TIME_NOT_REACHED = '3';
    string public constant ONLY_AFTER_END_BLOCK = '4';
    string public constant ONLY_BEFORE_STAKING_ENDS = '5';
    string public constant ONLY_FACTORY_CAN_CALL = '6';
    string public constant DEFENCE = '7';
    string public constant ONLY_WHEN_WITHDRAWN = '8';
    string public constant SHOULD_BE_NON_ZERO = '9';
    string public constant SHOULD_BE_MORE_THAN_CLAIMED = 'A';
    string public constant ONLY_POOLS_CAN_CALL = 'B';
    string public constant LOCK_IN_BLOCK_LESS_THAN_MIN = 'C';
    string public constant EXCEEDS_MAX_ITERATION = 'D';
    string public constant ONLY_DEPOSIT_OR_WITHDRAWN = 'E';
}


// Dependency file: contracts/ethereum/StakingPool.sol

// import 'contracts/ethereum/interfaces/IPoolFactory.sol';

// import 'contracts/ethereum/interfaces/IERC20Mintable.sol';
// import 'contracts/ethereum/Errors.sol';

contract StakingPool is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    enum DepositState {
        NOT_CREATED,
        DEPOSITED,
        WITHDRAWN,
        REWARD_CLAIMED
    }

    struct Deposit {
        uint256 amount;
        uint256 startBlock;
        uint256 unlockBlock;
        address user;
        DepositState depositState;
        uint256 vestedRewardUnlockBlock;
        uint256 vestedRewards;
    }

    /**
     * @notice Total number of blocks in one year
     */
    uint256 public constant totalBlocksPerYear = 2400000; // use 2.4 million for mainnet deployment, use a smaller number for testing

    /**
     * @notice Address of factory
     */
    address public immutable factory;

    /**
     * @notice minimum number of blocks to be locked
     */
    uint256 public immutable lockinBlocks;

    /**
     * @notice Block at which starting starts
     */
    uint256 public immutable startBlock;

    /**
     * @notice Block at which dapp ends
     */
    uint256 public immutable endBlock;

    /**
     * @notice block at which staking ends
     */
    uint256 public immutable stakingEndBlock;

    /**
     * @notice address of staking token
     */
    address public immutable stakingToken;

    /**
     * @notice deposit counter
     */
    uint256 public depositCounter;

    /**
     * @notice total value locked
     */
    uint256 public tvl;

    /**
     * @notice deposits
     */
    mapping(uint256 => Deposit) public deposits;

    /**
     * @notice event when deposit is emitted
     */
    event Deposited(uint256 indexed depositNumber, address indexed depositor, uint256 amount, uint256 unlockBlock);

    /**
     * @notice event when deposit is withdrawn
     */
    event Withdraw(uint256 indexed depositNumber);

    /**
     * @notice event when vested reward is withdrawn
     */
    event WithdrawVestedReward(uint256 indexed depositNumber);

    /**
     * @notice event when token are withdrawn on emergency
     */
    event EmegencyWithdrawToken(uint256 indexed depositNumber);

    /**
     * @notice max number of deposits that can be operated in the single call
     */
    uint256 public constant MAX_LOOP_ITERATIONS = 20;

    /**
     * @param _stakingToken Address of the staking token
     * @param _lockinBlocks Minimum number of blocks the deposit should be staked
     * @param _operator Address of the staking operator
     */
    constructor(
        address _stakingToken,
        uint256 _lockinBlocks,
        address _operator
    ) Ownable() {
        require(_lockinBlocks < totalBlocksPerYear, Errors.LOCK_IN_BLOCK_LESS_THAN_MIN);
        factory = msg.sender;

        lockinBlocks = _lockinBlocks;
        startBlock = block.number;
        endBlock = block.number.add(totalBlocksPerYear);
        stakingEndBlock = block.number.add(totalBlocksPerYear.sub(_lockinBlocks));

        stakingToken = _stakingToken;

        Ownable.transferOwnership(_operator);
    }

    /**
     * @notice Deposit to Staking Contract, The token must be approved before this function is called
     * @param amount Amount of tokens to be staked
     */
    function deposit(uint256 amount) external beforeStakingEnds defence {
        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), amount);
        depositCounter++;
        uint256 unlockBlock = block.number.add(lockinBlocks);
        deposits[depositCounter] = Deposit(amount, block.number, unlockBlock, msg.sender, DepositState.DEPOSITED, 0, 0);

        tvl = tvl.add(amount);
        IPoolFactory(factory).updateTVL(tvl);

        emit Deposited(depositCounter, msg.sender, amount, unlockBlock);
    }

    /**
     * @notice Withdraw Multiple Deposits
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawNinjaMultiple(uint256[] calldata depositNumbers) public defence {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            withdrawNinja(depositNumbers[index]);
        }
    }

    /**
     * @notice Withdraw ninja
     * @param depositNumber Deposit Number
     */
    function withdrawNinja(uint256 depositNumber) public onlyWhenDeposited(depositNumber) onlyDepositor(depositNumber) defence {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.number > _deposit.unlockBlock, Errors.ONLY_AFTER_END_BLOCK);

        uint256 blockNumber = block.number;

        if (blockNumber > endBlock) {
            blockNumber = endBlock;
        }
        _deposit.depositState = DepositState.WITHDRAWN;
        _deposit.vestedRewardUnlockBlock = blockNumber.add(totalBlocksPerYear);

        uint256 numberOfBlocksStaked = _deposit.unlockBlock.sub(_deposit.startBlock);

        uint256 vestedReward = getVestedRewards(_deposit.amount, numberOfBlocksStaked);
        _deposit.vestedRewards = vestedReward;

        IERC20(stakingToken).safeTransfer(_deposit.user, _deposit.amount);
        tvl = tvl.sub(_deposit.amount);
        IPoolFactory(factory).updateTVL(tvl);

        emit Withdraw(depositNumber);
    }

    /**
     * @notice Returns the number of Vested ninja token for a given deposit
     * @param depositNumber Deposit Number
     */
    function getNinjaVestedAmount(uint256 depositNumber) public view returns (uint256) {
        Deposit storage _deposit = deposits[depositNumber];
        if (_deposit.depositState != DepositState.WITHDRAWN) {
            return 0;
        }

        uint256 numberOfBlocksStaked = _deposit.unlockBlock.sub(_deposit.startBlock);
        return getVestedRewards(_deposit.amount, numberOfBlocksStaked);
    }

    /**
     * @notice Withdraw Multiple Vested Rewards
     * @param depositNumbers Deposit Numbers to withdraw
     */
    function withdrawVestedNinjaMultiple(uint256[] calldata depositNumbers) public defence {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            withdrawVestedNinja(depositNumbers[index]);
        }
    }

    /**
     * @notice Withdraw Vested Reward
     * @param depositNumber Deposit Number to withdraw
     */
    function withdrawVestedNinja(uint256 depositNumber) public onlyWhenWithdrawn(depositNumber) onlyDepositor(depositNumber) defence {
        Deposit storage _deposit = deposits[depositNumber];
        require(block.number > _deposit.vestedRewardUnlockBlock, Errors.VESTED_TIME_NOT_REACHED);
        _deposit.depositState = DepositState.REWARD_CLAIMED;
        IPoolFactory(factory).flushReward(msg.sender, _deposit.vestedRewards);
        emit WithdrawVestedReward(depositNumber);
    }

    /**
     * @notice Returns the number of Vested Rewards for given number of blocks and amount
     * @param amount Amount of staked token
     * @param numberOfBlocksStaked Number of blocks staked
     */
    function getVestedRewards(uint256 amount, uint256 numberOfBlocksStaked) internal view returns (uint256) {
        uint256 totalPoolShare = IPoolFactory(factory).getPoolShare(address(this));
        return totalPoolShare.mul(amount).mul(numberOfBlocksStaked).div(totalBlocksPerYear).div(tvl);
    }

    /**
     * @notice Withdraw Multiple Vested Rewards
     * @param depositNumbers Deposit Numbers to emergency withdraw
     */
    function emergencyWithdrawMultiple(uint256[] calldata depositNumbers) public {
        require(depositNumbers.length <= MAX_LOOP_ITERATIONS, Errors.EXCEEDS_MAX_ITERATION);
        for (uint256 index = 0; index < depositNumbers.length; index++) {
            emergencyWithdraw(depositNumbers[index]);
        }
    }

    /**
     * @notice Remove the staking token from contract. No Rewards will released in this case
     * @param depositNumber deposit number
     */
    function emergencyWithdraw(uint256 depositNumber)
        public
        onlyWhenDepositorOrWithdraw(depositNumber)
        onlyDepositor(depositNumber)
        defence
    {
        Deposit memory _deposit = deposits[depositNumber];
        IERC20(stakingToken).safeTransfer(_deposit.user, _deposit.amount);
        tvl = tvl.sub(_deposit.amount);
        IPoolFactory(factory).updateTVL(tvl);
        delete deposits[depositNumber];
        emit EmegencyWithdrawToken(depositNumber);
    }

    /**
     * @notice Modifier to prevent staking after the staking period ends
     */
    modifier beforeStakingEnds() {
        require(block.number < stakingEndBlock, Errors.ONLY_BEFORE_STAKING_ENDS);
        _;
    }

    /**
     * @notice Modifier that allows only factory contract to call
     */
    modifier onlyFactory() {
        require(msg.sender == factory, Errors.ONLY_FACTORY_CAN_CALL);
        _;
    }

    /**
     * @notice Modifier to prevent contract interaction
     */
    modifier defence() {
        require((msg.sender == tx.origin), Errors.DEFENCE);
        _;
    }

    /**
     * @notice Modifier to check if the deposit state is DEPOSITED
     */
    modifier onlyWhenDeposited(uint256 depositNumber) {
        require(deposits[depositNumber].depositState == DepositState.DEPOSITED, Errors.ONLY_WHEN_DEPOSITED);
        _;
    }

    /**
     * @notice Modifier to check if the deposit state is WITHDRAWN
     */
    modifier onlyWhenWithdrawn(uint256 depositNumber) {
        require(deposits[depositNumber].depositState == DepositState.WITHDRAWN, Errors.ONLY_WHEN_WITHDRAWN);
        _;
    }

    /**
     * @notice Modifier to check if the eposit state is DEPOSITED or WITHDRAWN
     */
    modifier onlyWhenDepositorOrWithdraw(uint256 depositNumber) {
        Deposit memory _deposit = deposits[depositNumber];
        require(
            _deposit.depositState == DepositState.WITHDRAWN || _deposit.depositState == DepositState.DEPOSITED,
            Errors.ONLY_DEPOSIT_OR_WITHDRAWN
        );
        _;
    }

    /**
     * @notice Modifier to ensure only depositor calls
     */
    modifier onlyDepositor(uint256 depositNumber) {
        require(deposits[depositNumber].user == msg.sender, Errors.ONLY_DEPOSITOR);
        _;
    }
}


// Root file: contracts/ethereum/StakingPoolFactory.sol

pragma solidity 0.7.0;

// import '/Users/akshay/Code/UFO/ninja/node_modules/@openzeppelin/contracts/access/Ownable.sol';
// import '/Users/akshay/Code/UFO/ninja/node_modules/@openzeppelin/contracts/math/SafeMath.sol';
// import '/Users/akshay/Code/UFO/ninja/node_modules/@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

// import 'contracts/ethereum/StakingPool.sol';
// import 'contracts/ethereum/interfaces/IPoolFactory.sol';

contract PoolFactory is Ownable, IPoolFactory {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    struct Pool {
        uint256 tvl;
        uint8 weight;
        bool isPool;
        bool ninjaPool;
    }

    /**
     * @notice Weight is scaled by 10
     */
    uint8 public immutable SCALING_FACTOR = 100;

    /**
     * @notice event when pool is created
     * @param poolNumber Index of the pool
     * @param pool address of the pool
     */
    event CreatePool(uint256 indexed poolNumber, address indexed pool);

    /**
     * @notice event when tvl is updated
     * @param pool address of the pool
     */
    event UpdatePoolTVL(address indexed pool, uint256 tvl);

    /**
     * @notice pool params
     */
    mapping(address => Pool) public pools;

    /**
     * @notice pool number to pool address
     */
    mapping(uint256 => address) public poolNumberToPoolAddress;

    /**
     * @notice total number of pools
     */
    uint256 public totalPools;

    /**
     * @notice total ninja token rewards allocation for locked pools
     */
    uint256 public ninjaRewardsForNinjaPools;

    /**
     * @notice total ninja token rewards allocation for unlocked pools
     */
    uint256 public ninjaRewardsForLpPools;

    /**
     * @notice total ninja token claimed from the ninja pools
     */
    uint256 public claimedNinjaRewardsForNinjaPools;

    /**
     * @notice total ninja token rewards claimed from the lp pools
     */
    uint256 public claimedNinjaRewardsForLpPools;

    /**
     * @notice address of the reward token
     */
    address public immutable rewardToken;

    /**
     * @notice Constructor
     * @param _admin Address of the admin
     * @param _ninjaRewardsForNinjaPoolsPools Ninja Rewards to be distributed for the locked pools
     * @param _ninjaRewardsForLpPoolsPools Ninja Rewards to be distributed for the unlocked pools
     * @param _rewardToken Address of the reward token
     * @param _ninjaToken Address of the ninja token
     * @param _lpToken Address of the lp token
     */
    constructor(
        address _admin,
        uint256 _ninjaRewardsForNinjaPoolsPools,
        uint256 _ninjaRewardsForLpPoolsPools,
        address _rewardToken,
        address _ninjaToken,
        address _lpToken
    ) {
        Ownable.transferOwnership(_admin);
        ninjaRewardsForNinjaPools = _ninjaRewardsForNinjaPoolsPools;
        ninjaRewardsForLpPools = _ninjaRewardsForLpPoolsPools;

        rewardToken = _rewardToken;
        totalPools = 8;

        // for ease even pools are ninja pool, odd pools are lp pools

        // unlocked pools
        _createPool(0, _ninjaToken, 1, _admin, 100); // ninja token pool, flexi pool
        _createPool(1, _lpToken, 1, _admin, 100); // lp token pool, flexi pool

        // locked pools
        _createPool(2, _ninjaToken, 196300, _admin, 105); // ninja token pool, 1 month lock in pool
        _createPool(3, _lpToken, 196300, _admin, 105); // lp token pool, 1 month lock in pool

        _createPool(4, _ninjaToken, 589000, _admin, 115); // ninja token pool, 3 month lock in pool
        _createPool(5, _lpToken, 589000, _admin, 115); // lp token pool, 3 month lock in pool

        _createPool(6, _ninjaToken, 1179000, _admin, 150); //ninja token pool, 6 month lock in pool
        _createPool(7, _lpToken, 1179000, _admin, 150); // lp token pool, 6 month lock in pool
    }

    /**
     * @notice internal function called in the constructor
     * @param poolNumber Index number of the pool
     * @param _stakingToken Address of the token to be staked
     * @param lockinBlocks Number of blocks the deposit is locked
     * @param _poolWeight Reward weight of the pool. Higher weight, higher rewards
     */
    function _createPool(
        uint256 poolNumber,
        address _stakingToken,
        uint256 lockinBlocks,
        address _admin,
        uint8 _poolWeight
    ) internal {
        require(_poolWeight != 0, Errors.SHOULD_BE_NON_ZERO);
        require(lockinBlocks != 0, Errors.SHOULD_BE_NON_ZERO);

        // address _stakingToken,
        // address _maticBridge,
        // uint256 _lockinBlocks

        StakingPool _pool = new StakingPool(_stakingToken, lockinBlocks, _admin); // change to actual addresses
        pools[address(_pool)] = Pool(0, _poolWeight, true, poolNumber % 2 == 0);
        poolNumberToPoolAddress[poolNumber] = address(_pool);
        emit CreatePool(poolNumber, address(_pool));
    }

    /**
     * @notice Update the TVL. Only a pool can call
     * @param tvl New TVL of the pool
     */
    function updateTVL(uint256 tvl) external override onlyPool {
        pools[msg.sender].tvl = tvl;
        emit UpdatePoolTVL(msg.sender, tvl);
    }

    /**
     * @notice Send ninja token rewards user. Only a pool can call
     * @param user Address of the user to send reward to
     * @param amount Amount of tokens to send
     */
    function flushReward(address user, uint256 amount) external override onlyPool {
        if (pools[msg.sender].ninjaPool) {
            claimedNinjaRewardsForNinjaPools = claimedNinjaRewardsForNinjaPools.add(amount);
        } else {
            claimedNinjaRewardsForLpPools = claimedNinjaRewardsForLpPools.add(amount);
        }
        IERC20(rewardToken).safeTransfer(user, amount);
    }

    /**
     * @notice Get Total Weight of TVL locked in all contracts
     */
    function getTotalTVLWeight() public view override returns (uint256 ninjaPoolWeight, uint256 lpPoolWeight) {
        ninjaPoolWeight = _getPoolWeight(0).add(_getPoolWeight(2)).add(_getPoolWeight(4)).add(_getPoolWeight(6));
        lpPoolWeight = _getPoolWeight(1).add(_getPoolWeight(3)).add(_getPoolWeight(5)).add(_getPoolWeight(7));
    }

    /**
     * @notice Internal function to calculate the weight of pool
     */
    function _getPoolWeight(uint256 poolNumber) internal view returns (uint256) {
        Pool storage pool = pools[poolNumberToPoolAddress[poolNumber]];
        return pool.tvl.mul(pool.weight).div(SCALING_FACTOR);
    }

    /**
     * @notice Calculate the number of ninja reward tokens a pool is entitiled to at given point in time.
     * @param pool Address of the pool
     */
    function getPoolShare(address pool) public view override returns (uint256 amount) {
        Pool storage _pool = pools[pool];
        if (!_pool.isPool) {
            return 0;
        }
        (uint256 ninjaPoolWeight, uint256 lpPoolWeight) = getTotalTVLWeight();

        uint256 totalTvlWeight = _pool.ninjaPool ? ninjaPoolWeight : lpPoolWeight;
        if (totalTvlWeight == 0) {
            // to avoid division overflow when tvl is 0
            return 0;
        }
        uint256 totalReward = _pool.ninjaPool ? ninjaRewardsForNinjaPools : ninjaRewardsForLpPools;

        uint256 claimedRewards = _pool.ninjaPool ? claimedNinjaRewardsForNinjaPools : claimedNinjaRewardsForLpPools;
        amount = (totalReward.sub(claimedRewards)).mul(_pool.tvl.mul(_pool.weight).div(SCALING_FACTOR)).div(totalTvlWeight);
    }

    /**
     * @notice Fetch Pool APR. Will return 0 if address is not a valid pool (or) the tvl in pool is zero
     * @param pool Address of the pool to fetch APR
     */
    function getPoolApr(address pool) public view returns (uint256) {
        uint256 share = getPoolShare(pool);
        Pool storage _pool = pools[pool];
        if (_pool.tvl == 0) {
            return 0;
        }
        return share.mul(10**18).div(_pool.tvl);
    }

    /**
     * @notice Change ninja Rewards to be distributed for ninja pools
     * @param amount New Amount
     */
    function changeNinjaRewardsForNinjaPools(uint256 amount) external onlyOwner {
        require(amount > ninjaRewardsForNinjaPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        ninjaRewardsForNinjaPools = amount;
    }

    /**
     * @notice Change ninja Rewards to be distributed for LP pools
     * @param amount New Amount
     */
    function changeNinjaRewardsForLpPools(uint256 amount) external onlyOwner {
        require(amount > claimedNinjaRewardsForLpPools, Errors.SHOULD_BE_MORE_THAN_CLAIMED);
        claimedNinjaRewardsForLpPools = amount;
    }

    /**
     * @notice Withdraw ninja tokens available in case of any emergency
     * @param recipient Address to receive the emergency deposit
     */
    function emergencyWithdrawRewardBalance(address recipient) external onlyOwner {
        uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        IERC20(rewardToken).transfer(recipient, rewardBalance);
    }

    /**
     * @notice ensures that sender is a registered pool
     */
    modifier onlyPool() {
        require(pools[msg.sender].isPool, Errors.ONLY_POOLS_CAN_CALL);
        _;
    }
}