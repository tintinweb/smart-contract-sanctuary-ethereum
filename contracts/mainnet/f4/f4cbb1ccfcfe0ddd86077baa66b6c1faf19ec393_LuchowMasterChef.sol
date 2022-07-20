/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

    constructor() public {
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
    constructor() public {
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
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
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
        return functionCall(target, data, 'Address: low-level call failed');
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// Controller with ReTk in the contracts.
contract ReTkController is Ownable, ReentrancyGuard {
    // The ReTk TOKEN!
    IBEP20 public reTk;
    // The operator can only transfer reward tokens in the contract
    mapping(address=>bool) public operator;
    // Event
    event OperatorTokenRecovery(address tokenRecovered, uint256 amount);
    event SetOperator(address _operator, bool _value);

    modifier onlyOperator() {
        require(operator[_msgSender()], "operator: caller is not the operator");
        _;
    }

    constructor(IBEP20 _reTk) public {
        reTk = _reTk;
        operator[_msgSender()] = true;

        emit SetOperator(_msgSender(), true);
    }

    // Safe ReTk transfer function, just in case if rounding error causes pool to not have enough ReTks.
    function safeReTkTransfer(address _to, uint256 _amount) public onlyOperator nonReentrant returns (uint256) {
        uint256 reTkBal = reTk.balanceOf(address(this));
        if (_amount > reTkBal) { _amount = reTkBal; }
        if (_amount > 0) { reTk.transfer(_to, _amount); }
        return _amount;
    }

    function setOperator(address _operator, bool _value) external onlyOwner {
        operator[_operator] = _value;
        emit SetOperator(_operator, _value);
    }

    /**
     * @notice It allows the operator to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by operator.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IBEP20(_tokenAddress).transfer(msg.sender, _tokenAmount);
        emit OperatorTokenRecovery(_tokenAddress, _tokenAmount);
    }
}

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}

/**
 * LuchowMasterChef is the master of Reward Token(MLOKY) = ReTk(reTk)
 * 
 * Note that it's ownable and the owner wields tremendous power.
 *
 * Have fun reading it. Hopefully it's bug-free. God bless.
 */
contract LuchowMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lastDepositedAt; // Last Deposited time
        //
        // We do some fancy math here. Basically, any point in time, the amount of ReTks
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accReTkPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accReTkPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 lpSupply; // Pool lp supply
        uint256 allocPoint; // How many allocation points assigned to this pool. ReTks to distribute per block.
        uint256 lastRewardBlock; // Last block number that ReTks distribution occurs.
        uint256 accReTkPerShare; // Accumulated ReTks per share, times 1e21 (1e30 - ReTk's decimals). See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 withdrawFeeBP; // Withdraw fee in basis points
        uint256 lockPeriod; // Withdraw lock period in seconds
    }

    // The Reword Token!
    IBEP20 public reTk;
    // The reward token controller contract
    ReTkController public reTkController;
    // Deposit Fee address
    address public feeAddress;
    // Reword Tokens created per block.
    uint256 public reTkPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Mative Token mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Bonus muliplier for early ReTk makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 120 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 120 days;
    // Max deposit fee: 10%
    uint16 public constant MAXIMUM_DEPOSIT_FEE = 1000;
    // Max withdraw fee: 10%
    uint16 public constant MAXIMUM_WITHDRAW_FEE = 1000;
    // Maximum emission rate
    uint256 public constant MAXIMUM_EMISSON_RATE = 10000;

    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 oldValue, uint256 newValue);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event FeeAddressUpdated(address indexed oldFeeAddress, address indexed newFeeAddress);
    event StartBlockUpdated(uint256 oldBlock, uint256 newBlock);

    constructor(
        IBEP20 _reTk,
        ReTkController _reTkController,
        address _feeAddress,
        uint256 _startBlock,
        uint256 _reTkPerBlock
    ) public {
        reTk = _reTk;
        reTkController = _reTkController;
        startBlock = _startBlock;
        uint256 rewardTokenDecimals = reTk.decimals();
        require(
            _reTkPerBlock <= MAXIMUM_EMISSON_RATE.mul(10**rewardTokenDecimals),
            "Emission rate exceeds limit"
        );
        reTkPerBlock = _reTkPerBlock;

        require(_feeAddress != address(0), "Invalid fee address");
        feeAddress = _feeAddress;
        emit FeeAddressUpdated(address(0), _feeAddress);

        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _reTk,
            lpSupply: 0,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accReTkPerShare: 0,
            depositFeeBP: 0,
            harvestInterval: 0,
            withdrawFeeBP: 0,
            lockPeriod: 0
        }));

        totalAllocPoint = 1000;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint, 
        IBEP20 _lpToken, 
        uint16 _depositFeeBP, 
        uint16 _withdrawFeeBP,
        uint256 _harvestInterval, 
        uint256 _lockPeriod,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "add: invalid deposit fee basis points");
        require(_withdrawFeeBP <= MAXIMUM_WITHDRAW_FEE, "add: invalid withdraw fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) { massUpdatePools(); }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            lpSupply: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accReTkPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval: _harvestInterval,
            withdrawFeeBP: _withdrawFeeBP,
            lockPeriod: _lockPeriod
        }));
    }

    // Update the given pool's ReTk allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid, 
        uint256 _allocPoint, 
        uint16 _depositFeeBP, 
        uint16 _withdrawFeeBP,
        uint256 _harvestInterval, 
        uint256 _lockPeriod,
        bool _withUpdate
    ) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid deposit fee basis points");
        require(_withdrawFeeBP <= MAXIMUM_WITHDRAW_FEE, "set: invalid withdraw fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) { massUpdatePools(); }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].lockPeriod = _lockPeriod;
    }

    // Return reward multiplier over the given _from block to _to block.
    function getMultiplier(uint256 _fromBlock, uint256 _toBlock) public pure returns (uint256) {
        return _toBlock.sub(_fromBlock).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending ReTks on frontend.
    function pendingReTk(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accReTkPerShare = pool.accReTkPerShare;
        uint256 lpSupply = pool.lpSupply;
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 reTkReward = multiplier.mul(reTkPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accReTkPerShare = accReTkPerShare.add(reTkReward.mul(1e21).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accReTkPerShare).div(1e21).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest ReTks.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // View function to see if user can withdraw
    function canWithdraw(uint256 _pid, address _user) public view returns (bool) {
        uint256 lastDepositedAt = userInfo[_pid][_user].lastDepositedAt;
        uint256 lockPeriod = poolInfo[_pid].lockPeriod;
        return block.timestamp >= lastDepositedAt.add(lockPeriod);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) { return; }
        uint256 lpSupply = pool.lpSupply;
        if (lpSupply == 0 || pool.allocPoint == 0) { pool.lastRewardBlock = block.number; return; }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 reTkReward = multiplier.mul(reTkPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        pool.accReTkPerShare = pool.accReTkPerShare.add(reTkReward.mul(1e21).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for ReTk allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        payOrLockupPendingReTk(_pid);

        if (_amount > 0) {
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);

            uint256 depositFee = 0;
            if (pool.depositFeeBP > 0) {
                depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                if (depositFee > 0) {
                    pool.lpToken.safeTransfer(feeAddress, depositFee);
                }
            }
            user.amount = user.amount.add(_amount).sub(depositFee);
            user.lastDepositedAt = block.timestamp;
            pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
        }
        user.rewardDebt = user.amount.mul(pool.accReTkPerShare).div(1e21);
        emit Deposited(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "Non zero amount");
        require(user.amount >= _amount, "withdraw: not good(user balance not enough)");
        require(pool.lpSupply >= _amount, "withdraw: not good(pool balance not enough)");

        updatePool(_pid);
        payOrLockupPendingReTk(_pid);

        user.amount = user.amount.sub(_amount);
        pool.lpSupply = pool.lpSupply.sub(_amount);

        if (!canWithdraw(_pid, msg.sender)) {
            uint256 withdrawFee = _amount.mul(pool.withdrawFeeBP).div(10000);
            if (withdrawFee > 0) {
                pool.lpToken.safeTransfer(feeAddress, withdrawFee);
                _amount = _amount.sub(withdrawFee);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accReTkPerShare).div(1e21);
        emit Withdrawn(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        pool.lpSupply = pool.lpSupply.sub(amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdrawn(msg.sender, _pid, amount);
    }

    // Pay or lockup pending ReTks.
    function payOrLockupPendingReTk(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }
        uint256 pending = user.amount.mul(pool.accReTkPerShare).div(1e21).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);
                // send rewards
                uint256 transferredAmount = safeReTkTransfer(msg.sender, totalRewards);
                // reset lockup
                uint256 diff = totalRewards.sub(transferredAmount);
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp).add(diff);
                user.rewardLockedUp = diff;
                if (transferredAmount > 0) {
                    user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
                }
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe ReTk transfer function, just in case if rounding error causes pool to not have enough ReTks.
    function safeReTkTransfer(address _to, uint256 _amount) internal returns (uint256) {
        return reTkController.safeReTkTransfer(_to, _amount);
    }

    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        require(feeAddress != _feeAddress, "setFeeAddress: Already Set");
        emit FeeAddressUpdated(feeAddress, _feeAddress);
        feeAddress = _feeAddress;
    }

    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        require(block.number < startBlock, "Farm already started");
        require(block.number < _startBlock, "Invalid start block");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = _startBlock;
        }
        emit StartBlockUpdated(startBlock, _startBlock);
        startBlock = _startBlock;
    }

    function updateEmissionRate(uint256 _reTkPerBlock) external onlyOwner {
        uint256 rewardTokenDecimals = reTk.decimals();
        require(
            _reTkPerBlock <= MAXIMUM_EMISSON_RATE.mul(10**rewardTokenDecimals),
            "updateEmissionRate: exceeds emission limit"
        );
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, reTkPerBlock, _reTkPerBlock);
        reTkPerBlock = _reTkPerBlock;
    }
}