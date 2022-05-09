/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

pragma solidity >=0.8.2 < 0.9.0;
pragma abicoder v2;
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts/utils/math/SafeMath.sol
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)


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

// File: GabrielV2.sol

/// @title Archangel Reward Staking Pool V2 (GabrielV2)
/// @notice Stake tokens to Earn Rewards.
contract GabrielV2 is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /* ========== STATE VARIABLES ========== */

    address public devaddr;
    uint public devPercent;
    
    address public treasury;
    uint public tPercent;
    
    PoolInfo[] public poolInfo;
    mapping(uint => mapping(address => UserInfo)) public userInfo;

    /* ========== STRUCTS ========== */
    struct ConstructorArgs {
        uint devPercent;
        uint tPercent;
        address devaddr;
        address treasury;
    }
    
    struct ExtraArgs {
        IERC20 stakeToken;
        uint openTime;
        uint waitPeriod;
        uint lockDuration;
    }

    struct PoolInfo {
        bool canStake;
        bool canUnstake;
        IERC20 stakeToken;
        uint lockDuration;
        uint lockTime;
        uint NORT;
        uint openTime;
        uint staked;
        uint unlockTime;
        uint unstaked;        
        uint waitPeriod;
        address[] harvestList;
        address[] rewardTokens;
        address[] stakeList;
        uint[] rewardsInPool;
    }

    struct UserInfo {
        uint amount;
        bool harvested;
    }

    /* ========== EVENTS ========== */
    event Harvest(uint pid, address user, uint amount);
    event PercentsUpdated(uint dev, uint treasury);
    event ReflectionsClaimed(uint pid, address token, uint amount);
    event Stake(uint pid, address user, uint amount);
    event Unstake(uint pid, address user, uint amount);

    /* ========== CONSTRUCTOR ========== */
    constructor(
        ConstructorArgs memory constructorArgs,
        ExtraArgs memory extraArgs,
        uint _NORT,
        address[] memory _rewardTokens,
        uint[] memory _rewardsInPool
    ) {
        devPercent = constructorArgs.devPercent;
        tPercent = constructorArgs.tPercent;
        devaddr = constructorArgs.devaddr;
        treasury = constructorArgs.treasury;
        createPool(extraArgs, _NORT, _rewardTokens, _rewardsInPool);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _changeNORT(uint _pid, uint _NORT) internal {
        PoolInfo storage pool = poolInfo[_pid];
        address[] memory rewardTokens = new address[](_NORT);
        uint[] memory rewardsInPool = new uint[](_NORT);
        pool.NORT = _NORT;
        pool.rewardTokens = rewardTokens;
        pool.rewardsInPool = rewardsInPool;
    }

    function changeNORT(uint _pid, uint _NORT) external onlyOwner {
        _changeNORT(_pid, _NORT);
    }

    function changePercents(uint _devPercent, uint _tPercent) external onlyOwner {
        require(_devPercent.add(_tPercent) == 100, "must sum up to 100%");
        devPercent = _devPercent;
        tPercent = _tPercent;
        emit PercentsUpdated(_devPercent, _tPercent);
    }

    function changeRewardTokens(uint _pid, address[] memory _rewardTokens) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint NORT = pool.NORT;
        require(_rewardTokens.length == NORT, "CRT: array length mismatch");
        for (uint i = 0; i < NORT; i++) {
            pool.rewardTokens[i] = _rewardTokens[i];
        }
    }

    /// @notice function to claim reflections
    function claimReflection(uint _pid, address token, uint amount) external onlyOwner {
        uint onePercent = amount.div(100);
        uint devShare = devPercent.mul(onePercent);
        uint tShare = amount.sub(devShare);
        IERC20(token).safeTransfer(devaddr, devShare);
        IERC20(token).safeTransfer(treasury, tShare);
        emit ReflectionsClaimed(_pid, token, amount);
    }

    /**
     * @notice create a new pool
     * @param extraArgs ["stakeToken", openTime, waitPeriod, lockDuration]
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     * @param _rewardTokens an array containing the addresses of the different reward tokens
     * @param _rewardsInPool an array of token balances for each unique reward token in the pool.
     */
    function createPool(ExtraArgs memory extraArgs, uint _NORT, address[] memory _rewardTokens, uint[] memory _rewardsInPool) public onlyOwner {
        require(_rewardTokens.length == _NORT && _rewardTokens.length == _rewardsInPool.length, "CP: array length mismatch");
        address[] memory rewardTokens = new address[](_NORT);
        uint[] memory rewardsInPool = new uint[](_NORT);
        address[] memory emptyList;
        require(
            extraArgs.openTime > block.timestamp,
            "open time must be a future time"
        );
        uint _lockTime = extraArgs.openTime.add(extraArgs.waitPeriod);
        uint _unlockTime = _lockTime.add(extraArgs.lockDuration);
        
        poolInfo.push(
            PoolInfo({
                stakeToken: extraArgs.stakeToken,
                staked: 0,
                unstaked: 0,
                openTime: extraArgs.openTime,
                waitPeriod: extraArgs.waitPeriod,
                lockTime: _lockTime,
                lockDuration: extraArgs.lockDuration,
                unlockTime: _unlockTime,
                canStake: false,
                canUnstake: false,
                NORT: _NORT,
                rewardTokens: rewardTokens,
                rewardsInPool: rewardsInPool,
                stakeList: emptyList,
                harvestList: emptyList
            })
        );
        uint _pid = poolInfo.length - 1;
        PoolInfo storage pool = poolInfo[_pid];
        for (uint i = 0; i < _NORT; i++) {
            pool.rewardTokens[i] = _rewardTokens[i];
            pool.rewardsInPool[i] = _rewardsInPool[i];
        }
    }

    /// @notice Update dev address by the previous dev.
    function dev(address _devaddr) external {
        require(msg.sender == devaddr, "dev: caller is not the current dev");
        devaddr = _devaddr;
    }

    /// @notice Harvest your earnings
    /// @param _pid select the particular pool
    function harvest(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.timestamp > pool.unlockTime && pool.canUnstake == false) {
            pool.canUnstake = true;
        }
        require(pool.canUnstake == true, "pool is still locked");
        require(user.amount > 0 && user.harvested == false, "Harvest: forbid withdraw");
        pool.harvestList.push(msg.sender);
        update(_pid);
        uint NORT = pool.NORT;
        for (uint i = 0; i < NORT; i++) {
            uint reward = user.amount * pool.rewardsInPool[i];
            uint lpSupply = pool.staked;
            uint pending = reward.div(lpSupply);
            if (pending > 0) {
                IERC20(pool.rewardTokens[i]).safeTransfer(msg.sender, pending);
                pool.rewardsInPool[i] = pool.rewardsInPool[i].sub(pending);
                emit Harvest(_pid, msg.sender, pending);
            }
        }
        pool.staked = pool.staked.sub(user.amount);
        user.harvested = true;
    }

    function recoverERC20(address token, address recipient, uint amount) external onlyOwner {
        IERC20(token).safeTransfer(recipient, amount);
    }

    /**
     * @notice sets user.harvested to false for all users
     * @param _pid select the particular pool
     * @param harvestList an array containing addresses of users for that particular pool.
     */
    function reset(uint _pid, address[] memory harvestList) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint len = harvestList.length;
        uint len2 = pool.harvestList.length;
        uint staked;
        for (uint i; i < len; i++) {
            UserInfo storage user = userInfo[_pid][harvestList[i]];
            user.harvested = false;
            staked = staked.add(user.amount);
        }
        pool.staked = pool.staked.add(staked);

        address lastUser = harvestList[len-1];
        address lastHarvester = pool.harvestList[len2-1];
        if (lastHarvester == lastUser) {
            address[] memory emptyList;
            pool.harvestList = emptyList;
        }
    }

    /**
     * @notice reset all the values of a particular pool
     * @param _pid select the particular pool
     * @param extraArgs ["stakeToken", openTime, waitPeriod, lockDuration]
     * @param _NORT specify the number of diffrent tokens the pool will give out as reward
     * @param _rewardTokens an array containing the addresses of the different reward tokens
     * @param _rewardsInPool an array of token balances for each unique reward token in the pool.
     */
    function reuse(uint _pid, ExtraArgs memory extraArgs, uint _NORT, address[] memory _rewardTokens, uint[] memory _rewardsInPool) external onlyOwner {
        require(
            _rewardTokens.length == _NORT &&
            _rewardTokens.length == _rewardsInPool.length,
            "RP: array length mismatch"
        );
        PoolInfo storage pool = poolInfo[_pid];
        pool.stakeToken = extraArgs.stakeToken;
        pool.unstaked = 0;
        _setTimeValues( _pid, extraArgs.openTime, extraArgs.waitPeriod, extraArgs.lockDuration);
        _changeNORT(_pid, _NORT);
        for (uint i = 0; i < _NORT; i++) {
            pool.rewardTokens[i] = _rewardTokens[i];
            pool.rewardsInPool[i] = _rewardsInPool[i];
        }
        pool.stakeList = pool.harvestList;
    }

    /**
     * @notice Set or modify the token balances of a particular pool
     * @param _pid select the particular pool
     * @param rewards array of token balances for each reward token in the pool
     */
    function setPoolRewards(uint _pid, uint[] memory rewards) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        uint NORT = pool.NORT;
        require(rewards.length == NORT, "SPR: array length mismatch");
        for (uint i = 0; i < NORT; i++) {
            pool.rewardsInPool[i] = rewards[i];
        }
    }

    function _setTimeValues(
        uint _pid,
        uint _openTime,
        uint _waitPeriod,
        uint _lockDuration
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        require(
            _openTime > block.timestamp,
            "open time must be a future time"
        );
        pool.openTime = _openTime;
        pool.waitPeriod = _waitPeriod;
        pool.lockTime = _openTime.add(_waitPeriod);
        pool.lockDuration = _lockDuration;
        pool.unlockTime = pool.lockTime.add(_lockDuration);
    }

    function setTimeValues(
        uint _pid,
        uint _openTime,
        uint _waitPeriod,
        uint _lockDuration
    ) external onlyOwner {
        _setTimeValues(_pid, _openTime, _waitPeriod, _lockDuration);
    }

    /// @notice Update treasury address.
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice stake ERC20 tokens to earn rewards
     * @param _pid select the particular pool
     * @param _amount amount of tokens to be deposited by user
     */
    function stake(uint _pid, uint _amount) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (block.timestamp > pool.lockTime && pool.canStake == true) {
            pool.canStake = false;
        }
        if (
            block.timestamp > pool.openTime &&
            block.timestamp < pool.lockTime &&
            block.timestamp < pool.unlockTime &&
            pool.canStake == false
        ) {
            pool.canStake = true;
        }
        require(
            pool.canStake == true,
            "pool is not yet opened or is locked"
        );
        update(_pid);
        if (_amount == 0) {
            return;
        }
        pool.stakeToken.safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        pool.stakeList.push(msg.sender);
        user.amount = user.amount.add(_amount);
        pool.staked = pool.staked.add(_amount);
        emit Stake(_pid, msg.sender, _amount);
    }

    /// @notice Exit without caring about rewards. EMERGENCY ONLY.
    /// @param _pid select the particular pool
    function unstake(uint _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "unstake: withdraw bad");
        pool.stakeToken.safeTransfer(msg.sender, user.amount);
        pool.unstaked = pool.unstaked.add(user.amount);
        if (pool.staked >= user.amount) {
            pool.staked = pool.staked.sub(user.amount);
        }
        emit Unstake(_pid, msg.sender, user.amount);
        user.amount = 0;
    }

    function update(uint _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.openTime) {
            return;
        }
        if (
            block.timestamp > pool.openTime &&
            block.timestamp < pool.lockTime &&
            block.timestamp < pool.unlockTime
        ) {
            pool.canStake = true;
            pool.canUnstake = false;
        }
        if (
            block.timestamp > pool.lockTime &&
            block.timestamp < pool.unlockTime
        ) {
            pool.canStake = false;
            pool.canUnstake = false;
        }
        if (
            block.timestamp > pool.unlockTime &&
            pool.unlockTime > 0
        ) {
            pool.canStake = false;
            pool.canUnstake = true;
        }
    }

    /* ========== READ ONLY ========== */

    function harvesters(uint _pid) external view returns (address[] memory harvestList) {
        PoolInfo memory pool = poolInfo[_pid];
        harvestList = pool.harvestList;
    }

    function harvests(uint _pid) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.harvestList.length;
    }

    function poolLength() external view returns (uint) {
        return poolInfo.length;
    }

    function rewardInPool(uint _pid) external view returns (uint[] memory rewardsInPool) {
        PoolInfo memory pool = poolInfo[_pid];
        rewardsInPool = pool.rewardsInPool;
    }

    function stakers(uint _pid) external view returns (address[] memory stakeList) {
        PoolInfo memory pool = poolInfo[_pid];
        stakeList = pool.stakeList;
    }

    function stakes(uint _pid) external view returns (uint) {
        PoolInfo memory pool = poolInfo[_pid];
        return pool.stakeList.length;
    }

    function tokensInPool(uint _pid) external view returns (address[] memory rewardTokens) {
        PoolInfo memory pool = poolInfo[_pid];
        rewardTokens = pool.rewardTokens;
    }

    function unclaimedRewards(uint _pid, address _user)
        external
        view
        returns (uint[] memory unclaimedReward)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint NORT = pool.NORT;
        if (block.timestamp > pool.lockTime && block.timestamp < pool.unlockTime && pool.staked != 0) {
            uint[] memory array = new uint[](NORT);
            for (uint i = 0; i < NORT; i++) {
                uint blocks = block.timestamp.sub(pool.lockTime);
                uint reward = blocks * user.amount * pool.rewardsInPool[i];
                uint lpSupply = pool.staked * pool.lockDuration;
                uint pending = reward.div(lpSupply);
                array[i] = pending;
            }
            return array;
        } else if (block.timestamp > pool.unlockTime && user.harvested == false && pool.staked != 0) {
            uint[] memory array = new uint[](NORT);
            for (uint i = 0; i < NORT; i++) {                
                uint reward = user.amount * pool.rewardsInPool[i];
                uint lpSupply = pool.staked;
                uint pending = reward.div(lpSupply);
                array[i] = pending;
            }
            return array;
        } else {
            uint[] memory array = new uint[](NORT);
            for (uint i = 0; i < NORT; i++) {                
                array[i] = 0;
            }
            return array;
        }        
    }
}