/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

/*

Welcome to
██████╗ ██████╗ ██╗██████╗  ██████╗ ███████╗██╗  ██╗
██╔══██╗██╔══██╗██║██╔══██╗██╔════╝ ██╔════╝╚██╗██╔╝
██████╔╝██████╔╝██║██║  ██║██║  ███╗█████╗   ╚███╔╝ 
██╔══██╗██╔══██╗██║██║  ██║██║   ██║██╔══╝   ██╔██╗ 
██████╔╝██║  ██║██║██████╔╝╚██████╔╝███████╗██╔╝ ██╗
╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                    
Powerful and fastest Atomic Swap as a service provider
Powered by xFox.io

--------------
Go to dApp : https://www.bridgex.app/
DOcumentation : https://docs.bridgex.app/
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT
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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
    // function renounceOwnership() public virtual onlyOwner {
    //     emit OwnershipTransferred(_owner, address(0));
    //     _owner = address(0);
    // }

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
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
        (bool success, ) = recipient.call{value: amount}("");
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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
        // solhint-disable-next-line max-line-length
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance =
        token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract BridgeX is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    //Defining a Project
    struct Project {
        address tokenAddress;
        uint balance;
        bool active;
        address owner;
        uint max_amount;
        uint swapCommissionPercent;
        address swapCommissionReceiver;
        uint minOracleFee;
        bool ownerVerified;

        mapping(uint => Chain) chains; //ChainID => chainData
        mapping(bytes32 => Swap) swaps; //SwapID => swapData
    }

    struct Chain {
        address tokenAddress;
        bool active;
        uint swapCount;
        uint minOracleFee;
    }

    struct Swap {
        uint swapCount;
        uint chainID;
        address from;
        address to;
        uint amount;
        bool isCompleted;
    }

    mapping(bytes32 => Project) public projects; //UniquePRojectID => projectdata
    uint public totalProjects = 0; //Total number of projects
    uint public totalSwaps = 0; //Total number of swaps performed in this contract

    //Oracle address 
    address payable public oracleAddress;

    //SUDO Settings
    uint public PROJECT_CREATION_COST;
    address payable public SERVICE_PROVIDER_ADDRESS;

    //Events
    event SwapStart (
        bytes32 indexed projectId,
        bytes32 indexed swapId,
        uint swapCount,
        uint toChainID,
        address indexed fromAddr, 
        address toAddr, 
        uint amount
    );
    
    event SwapEnd (
        bytes32 indexed projectId,
        bytes32 indexed swapId,
        uint swapCount,
        uint fromChainID,
        address indexed fromAddr, 
        address toAddr,
        uint amount
    );
    
    event SwapCompleted(
        bytes32 indexed projectId,
        bytes32 indexed swapId
    );

    event newProjectCreated(
        bytes32 indexed projectId, 
        address indexed tokenAddress, 
        address indexed owner,
        uint initialSupply
    );

    event newProjectChainCreated(
        bytes32 indexed projectId, 
        uint chainId, 
        address tokenAddress
    );

    event commissionReceived(
        bytes32 indexed projectId, 
        bytes32 indexed swapId,
        uint amount
    );

    event projectStatusChanged(
        bytes32 indexed projectId, 
        bool newStatus
    );

    //Modifiers
    modifier onlyActiveChains(bytes32 projectId, uint chainID){
        require(chainID != _getChainID(), "BRIDGEX: Swap must be created to different chain ID");
        require(projects[projectId].chains[chainID].active == true, "BRIDGEX: Only active chains");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    modifier onlyTokenOwner(bytes32 projectId) {
        require(projects[projectId].owner == _msgSender(), "ERROR: caller is not the Token Owner");
        _;
    }

    modifier OnlyOracle() {
        require(oracleAddress == _msgSender(), "ERROR: caller is not the Oracle");
        _;
    }

    constructor(address payable _oracleAddress, address payable _serviceProvider, uint _projectCreationCost) {
        oracleAddress = _oracleAddress;
        SERVICE_PROVIDER_ADDRESS = _serviceProvider;
        PROJECT_CREATION_COST = _projectCreationCost;
    }

    //Initite swap operation by users
    function swapStart(bytes32 projectId, uint toChainID, address to, uint amount) public payable onlyActiveChains(projectId, toChainID) whenNotPaused notContract nonReentrant {
        require(projects[projectId].active == true, "BRIDGE: Bridge Pool is inactive");
        require(msg.value.mul(1 gwei) >= projects[projectId].minOracleFee.add(projects[projectId].chains[toChainID].minOracleFee), "BRIDGE: Insufficient Oracle Fee");
        require(amount <= projects[projectId].max_amount, "BRIDGEX: Amount must be within max range");
        require(to == msg.sender, "BRIDGEX: Swaps allowed between same address only");
        require(IERC20(projects[projectId].tokenAddress).allowance(msg.sender, address(this)) >= amount, "BRIDGEX: Not enough allowance");
        _depositToken(projectId, amount);

        //Prepare commission to token owners
        uint commission;
        if(projects[projectId].swapCommissionPercent > 0 && msg.sender != projects[projectId].swapCommissionReceiver){
            commission = calculateCommission(projectId, amount);
            amount = amount.sub(commission);
            _withdrawCommission(projectId, commission);
            emit commissionReceived(projectId, projectId, commission);
        }

        //Increment swap count in chain
        projects[projectId].chains[toChainID].swapCount = projects[projectId].chains[toChainID].swapCount.add(1);
        uint _swapCount = projects[projectId].chains[toChainID].swapCount;
        uint _chainID = _getChainID();
        Swap memory swap = Swap({
            swapCount: _swapCount,
            chainID: _chainID,
            from: msg.sender,
            to: to,
            amount: amount,
            isCompleted: false
        });

        bytes32 swapId = keccak256(abi.encode(projectId, _swapCount, _chainID, toChainID, msg.sender, to, amount));
        require(projects[projectId].swaps[swapId].swapCount == 0, "BRIDGEX: It's available just 1 swap with same: projectId, chainID, swapCount, from, to, amount");
        projects[projectId].swaps[swapId] = swap;

        //Send oracle fees to oracle address
        if(msg.value > 0) {
            if (!oracleAddress.send(msg.value)) {
                oracleAddress.transfer(msg.value);
            }
        }

        emit SwapStart(projectId, swapId, _swapCount, toChainID, msg.sender, to, amount);
    }

    //Intermediate swap operation by oracle
    function swapEnd(bytes32 projectId, bytes32 swapId, uint swapCount, uint fromChainID, address from, address to, uint amount) public OnlyOracle onlyActiveChains(projectId, fromChainID) whenNotPaused {
        require(amount > 0 && to != address(0), "BRIDGEX: Primary Swap condition fail!");
        require(amount <= projects[projectId].balance, "BRIDGEX: Not enough token balance in bridge contract");
        uint _chainID = _getChainID();

        bytes32 processedSwapId = keccak256(abi.encode(projectId, swapCount, fromChainID, _chainID, from, to, amount));
        require(processedSwapId == swapId, "BRIDGEX: Swap ID Arguments do not match");
        require(projects[projectId].swaps[processedSwapId].isCompleted == false, "BRIDGEX: Swap already completed!");
        
        Swap memory swap = Swap({
            swapCount: swapCount,
            chainID: fromChainID,
            from: from,
            to: to,
            amount: amount,
            isCompleted: true
        });
        projects[projectId].swaps[processedSwapId] = swap;
        totalSwaps = totalSwaps.add(1);

        _transferToken(projectId, to, amount);
        emit SwapEnd(projectId, processedSwapId, swapCount, fromChainID, from, to, amount);
    }

    function setSwapComplete(bytes32 projectId, bytes32 swapId) external OnlyOracle{
        require(projects[projectId].swaps[swapId].isCompleted == false, "BRIDGEX: Swap already completed!");
        require(projects[projectId].swaps[swapId].swapCount != 0, "BRIDGEX: Event ID not found");
        require(projects[projectId].swaps[swapId].chainID == _getChainID(), "BRIDGEX: Swap from another chain should be completed from swapEnd()");
        projects[projectId].swaps[swapId].isCompleted = true;
        totalSwaps = totalSwaps.add(1);
        emit SwapCompleted(projectId, swapId);
    }

    //Token owner functions
    function configureAddSupply(bytes32 projectId, uint _supplyTokens) external onlyTokenOwner(projectId) {
        //Deposit tokens to the bridge pool
        require(IERC20(projects[projectId].tokenAddress).allowance(msg.sender, address(this)) >= _supplyTokens, "BRIDGEX: Not enough allowance");
        IERC20(projects[projectId].tokenAddress).safeTransferFrom(msg.sender, address(this), _supplyTokens);
        projects[projectId].balance = projects[projectId].balance.add(_supplyTokens);
    }

    function configureRemoveSupply(bytes32 projectId, uint _pullOutTokens) external onlyTokenOwner(projectId) {
        require(projects[projectId].active == false, "BRIDGEX: Project status must be inactive.");
        require(_pullOutTokens <= projects[projectId].balance,  "BRIDGEX: Project not enough balance.");
        _transferToken(projectId, msg.sender, _pullOutTokens);
    }
    
    function configureProjectSettings(bytes32 projectId, uint _maxAmount, bool _enableCommission, uint _swapCommissionPercent, address _swapCommissionReceiver) external onlyTokenOwner(projectId) {
        require(_swapCommissionReceiver != address(0), "BRIDGEX: Receiver address cannot be null");
        require(_swapCommissionPercent < 10000, "BRIDGEX: Commission must be less than 10000");        
        require(projects[projectId].owner != address(0), "BRIDGEX: Project Not Found!");

        projects[projectId].max_amount = _maxAmount;
        if(_enableCommission) {
            projects[projectId].swapCommissionPercent = _swapCommissionPercent;
            projects[projectId].swapCommissionReceiver = _swapCommissionReceiver;
        } else {
            projects[projectId].swapCommissionPercent = 0;
            projects[projectId].swapCommissionReceiver = address(0);
        }
    }

    function configureProjectStatus(bytes32 projectId, bool _status) external onlyTokenOwner(projectId) {
        require(projects[projectId].owner != address(0), "BRIDGEX: Project Not Found!");
        projects[projectId].active = _status;
        emit projectStatusChanged(projectId, _status);
    }

    function configureTransferProjectOwner(bytes32 projectId, address _newOwner) external onlyTokenOwner(projectId) {
        require(projects[projectId].owner != address(0), "BRIDGEX: Project Not Found!");
        projects[projectId].owner = _newOwner;
    }

    //Super Admin Functions
    function sudoSetMultipleProjectsOracleFee(bytes32[] memory projectIds, uint[] memory chainIds, uint[] memory bridge_minOracleFee, uint[] memory chain_minOracleFee) external onlyOwner {
        for(uint i = 0; i < projectIds.length; i++) {
            if(projects[projectIds[i]].owner != address(0)) {
                projects[projectIds[i]].minOracleFee = bridge_minOracleFee[i];
            } else {
                continue;
            }

            //Set chain ID oracle fees for this project
            for(uint j = 0; j < chainIds.length; j++) {
                if(projects[projectIds[i]].chains[chainIds[j]].tokenAddress != address(0)) {
                    projects[projectIds[i]].chains[chainIds[j]].minOracleFee = chain_minOracleFee[j];
                }
            }
        }
    }

    function sudoSetMultipleProjectsStatus(bytes32[] memory projectIds, bool[] memory _status) external onlyOwner {
        for(uint i = 0; i < projectIds.length; i++) {
            if(projects[projectIds[i]].owner != address(0)) {
                projects[projectIds[i]].active = _status[i];
                emit projectStatusChanged(projectIds[i], _status[i]);
            }
        }
    }

    function sudoConfigureTokenOwner(bytes32 projectId, address _owner) external onlyOwner {
        projects[projectId].owner = _owner;
    }

    function sudoConfigureChain(bytes32 projectId, uint chainID, address token_address, bool status, uint minOracleFee) external onlyOwner {
        require(chainID != _getChainID(), "BRIDGEX: Can`t change chain to current Chain ID");
        require(projects[projectId].chains[chainID].tokenAddress != address(0), "BRIDGEX: Chain is not registered");
        projects[projectId].chains[chainID].tokenAddress = token_address;
        projects[projectId].chains[chainID].active = status;
        projects[projectId].chains[chainID].minOracleFee = minOracleFee;
    }

    function sudoVerifyProjectWithOwner(bytes32 projectId) external onlyOwner {
        projects[projectId].ownerVerified = true;
    }

    function sudoAdjustProjectBalance(bytes32 projectId, uint _correctedAmount) external onlyOwner {
        projects[projectId].balance = _correctedAmount;
    }

    function sudoDeleteProject(bytes32 projectId) external onlyOwner {
        delete projects[projectId]; 
        totalProjects--;
    }

    function sudoChangeProviderAddress(address payable _newAddress) external onlyOwner {
        SERVICE_PROVIDER_ADDRESS = _newAddress;
    }

    function changeCreationCost(uint _newCost) public OnlyOracle {
        PROJECT_CREATION_COST = _newCost;
    }

    //Creation Functions
    function createNewProject(bytes32 projectId, bool firstTimeChain, address[] calldata addressArray, uint[] calldata uintArray, uint _addSupply) external payable returns(bytes32) {
        
        require(msg.sender == owner() || msg.value.mul(1 gwei) >= PROJECT_CREATION_COST, "BRIDGEX: Insufficient amount sent to create project.");
        
        bytes32 newProjectId;
        if(firstTimeChain) {
            newProjectId = keccak256(abi.encode(addressArray[0], addressArray[1]));
        } else {
            newProjectId = projectId;
        }

        require(projects[newProjectId].tokenAddress == address(0), "BRIDGEX: Project already created!");
        
        Project storage project = projects[newProjectId];
        project.tokenAddress = addressArray[0];
        project.active = true;
        project.owner = addressArray[1];
        project.max_amount = uintArray[0];
        project.swapCommissionPercent = uintArray[1];
        project.swapCommissionReceiver = addressArray[2];
        project.minOracleFee = uintArray[2];

        totalProjects++;

        //Send creation cost to relay wallet
        if(msg.value > 0) {
            if (!SERVICE_PROVIDER_ADDRESS.send(msg.value)) {
                SERVICE_PROVIDER_ADDRESS.transfer(msg.value);
            }
        }
        
        //Deposit tokens to the bridge pool
        require(IERC20(projects[newProjectId].tokenAddress).allowance(msg.sender, address(this)) >= _addSupply, "BRIDGEX: Not enough allowance");
        
        IERC20(projects[newProjectId].tokenAddress).safeTransferFrom(msg.sender, address(this), _addSupply);
        projects[newProjectId].balance = projects[newProjectId].balance.add(_addSupply);

        //Emit event new project created
        emit newProjectCreated(newProjectId, addressArray[0], addressArray[1], _addSupply);

        return newProjectId;
    }

    //Token Owner Add New Chain
    function addNewChainToProject(bytes32 projectId, uint _chainID, address _tokenAddress, uint _minOracleFee) public onlyTokenOwner(projectId) returns(bool){
        require(_chainID != _getChainID(), "ORACLE: Can`t add current chain ID");
        require(projects[projectId].chains[_chainID].tokenAddress == address(0), "ORACLE: ChainID has already been registered");

        Chain memory chain = Chain({
            tokenAddress: _tokenAddress,
            active: true,
            swapCount: 0,
            minOracleFee: _minOracleFee
        });
        projects[projectId].chains[_chainID] = chain;

        emit newProjectChainCreated(projectId, _chainID, _tokenAddress);
        return true;
    }

    //Helper Functions
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpaused(msg.sender);
    }

    function _transferToken(bytes32 projectId, address to, uint amount) private {
        IERC20(projects[projectId].tokenAddress).safeTransfer(to, amount);
        projects[projectId].balance = projects[projectId].balance.sub(amount);
    }

    function _depositToken(bytes32 projectId, uint amount) private {
        IERC20(projects[projectId].tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        projects[projectId].balance = projects[projectId].balance.add(amount);
    }

    //Calculates Commission to be sent to token owner
    function calculateCommission(bytes32 projectId, uint amount) public view returns(uint fee){
        fee = projects[projectId].swapCommissionReceiver != address(0) ? amount.mul(projects[projectId].swapCommissionPercent).div(10000) : 0;
    }

    //Internal function to send commission
    function _withdrawCommission(bytes32 projectId, uint commission) internal{
        if(commission > 0 && projects[projectId].swapCommissionReceiver != address(0)){
            _transferToken(projectId, projects[projectId].swapCommissionReceiver, commission);
        }
    }

    function _getChainID() internal view returns (uint) {
        uint id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    //DAPP helper functions
    //Get token balance of a project
    function seeProjectTokenBalance(bytes32 projectId) public view returns(uint balanceOf){
        return projects[projectId].balance;
    }

    //Get Token balance by contract address
    function seeAnyTokenBalance(address tokenAddress) public view returns(uint balanceOf){
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    //Get swapData by Swapid
    function seeSwapData(bytes32 projectId, bytes32 swapId) public view returns(uint counter, uint chainID, address from, uint amount, bool isCompleted){
        return (
            projects[projectId].swaps[swapId].swapCount,
            projects[projectId].swaps[swapId].chainID,
            projects[projectId].swaps[swapId].from,
            projects[projectId].swaps[swapId].amount,
            projects[projectId].swaps[swapId].isCompleted
        );
    }

    //Get chainData by chainId
    function seeChainData(bytes32 projectId, uint chainId) public view returns(address tokenAddress, bool active, uint swapCount, uint minOracleFee){
        return (
            projects[projectId].chains[chainId].tokenAddress,
            projects[projectId].chains[chainId].active,
            projects[projectId].chains[chainId].swapCount,
            projects[projectId].chains[chainId].minOracleFee
        );
    }

    //Emergency Functions
    //Emergency Withdraw Tokens sent to contract
    function emergencyWithdrawTokens(address _tokenAddress, address _toAddress, uint256 _amount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(_toAddress, _amount);
    }

    //Emergency withdraw Primary Coin sent to contract
    function emergencyWithdrawAsset(address payable toAddress) external onlyOwner {
        if(!toAddress.send(address(this).balance)) {
            return toAddress.transfer(address(this).balance);
        }
    }
}