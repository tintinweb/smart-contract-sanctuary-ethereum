/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// File: contracts/libs/Context.sol

pragma solidity ^0.8.0;

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
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/libs/Ownable.sol

pragma solidity ^0.8.0;

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
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/libs/Pausable.sol

pragma solidity ^0.8.0;

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

// File: contracts/libs/SafeMath.sol

pragma solidity ^0.8.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
        return mod(a, b, "SafeMath: modulo by zero");
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
}

// File: contracts/libs/Address.sol

pragma solidity ^0.8.0;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

// File: contracts/libs/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/libs/SafeERC20.sol

pragma solidity ^0.8.0;



/**
 * @title SafeERC20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: BEP20 operation did not succeed"
            );
        }
    }
}

// File: contracts/libs/ReentrancyGuard.sol

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

    constructor () {
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

// File: contracts/libs/UniversalERC20.sol

pragma solidity ^0.8.0;


// File: contracts/UniversalERC20.sol

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS =
        IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS =
        IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            payable(address(uint160(to))).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(
                from == msg.sender && msg.value >= amount,
                "Wrong useage of ETH.universalTransferFrom()"
            );
            if (to != address(this)) {
                payable(address(uint160(to))).transfer(amount);
            }
            if (msg.value > amount) {
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalTransferFromSenderToThis(IERC20 token, uint256 amount)
        internal
    {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            if (msg.value > amount) {
                // Return remainder if exist
                payable(msg.sender).transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who)
        internal
        view
        returns (uint256)
    {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall{
            gas: 10000
        }(abi.encodeWithSignature("decimals()"));
        if (!success || data.length == 0) {
            (success, data) = address(token).staticcall{gas: 10000}(
                abi.encodeWithSignature("DECIMALS()")
            );
        }

        return (success && data.length > 0) ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) ||
            address(token) == address(ETH_ADDRESS));
    }
}

// File: contracts/interfaces/IMerchantProperty.sol

pragma solidity ^0.8.0;

interface IMerchantProperty {
    function viewFeeMaxPercent() external view returns (uint16);

    function viewFeeMinPercent() external view returns (uint16);

    function viewDonationFee() external view returns (uint16);

    function viewTransactionFee() external view returns (uint16);

    function viewWeb3BalanceForFreeTx() external view returns (uint256);

    function viewMinAmountToProcessFee() external view returns (uint256);

    function viewMarketingWallet() external view returns (address payable);

    function viewDonationWallet() external view returns (address payable);

    function viewWeb3Token() external view returns (address);

    function viewAffiliatePool() external view returns (address);

    function viewStakingPool() external view returns (address);

    function viewMainExchange() external view returns (address, uint256);

    function viewExchanges() external view returns (address[] memory, uint256[] memory);

    function viewReserved() external view returns (bytes memory);

    function isBlacklistedFromPayToken(address token_)
        external
        view
        returns (bool);

    function isWhitelistedForRecToken(address token_)
        external
        view
        returns (bool);

    function viewMerchantWallet() external view returns (address);

    function viewAffiliatorWallet() external view returns (address);

    function viewFeeProcessingMethod() external view returns (uint8);

    function viewReceiveToken() external view returns (address);

    function viewDonationFeeCollected() external view returns (uint256);

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 maxPercent_) external;

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 minPercent_) external;

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 fee_) external;

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 fee_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 web3Balance_) external;

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 minAmount_) external;

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable marketingWallet_) external;

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable donationWallet_) external;

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address tokenAddress_) external;

    function updateaffiliatePool(address affiliatePool_) external;

    function updateStakingPool(address stakingPool_) external;

    /**
     * @dev Update the main exchange address.
     * Can only be called by the owner.
     */
    function updateMainExchange(address exchange_, uint256 flag_) external;

    /**
     * @dev Add new exchange.
     * @param flag_: exchange type
     * Can only be called by the owner.
     */
    function addExchange(address exchange_, uint256 flag_) external;

    /**
     * @dev Remove the exchange.
     * Can only be called by the owner.
     */
    function removeExchange(uint256 index_) external;

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address token_) external;

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address token_) external;

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address token_) external;

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address token_) external;

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address merchantWallet_) external;

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWallet(address affiliatorWallet_) external;

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(uint8 method_) external;

    /**
     * @dev Update donationFeeCollected
     * Only callable by owner
     */
    function updateDonationFeeCollected(uint256 fee_) external;

    /**
     * @dev Update reserve param
     * Only callable by owner
     */
    function updateReserve(bytes memory reserve_) external;
}

// File: contracts/interfaces/ISlashController.sol

pragma solidity ^0.8.0;

interface ISlashController {
    /**
     * @dev Get shared property contract
     */
    function getSharedProperty() external view returns (address);

    /**
     * @dev Get slash core contract
     */
    function getSlashCore() external view returns (address);

    /**
     * @dev Get in-amount to get out-amount of receive token
     * @return in-amount of token
     */
    function getAmountIn(
        address payingToken_,
        uint256 amountOut_,
        address[] memory path_,
        bytes memory reserved_
    ) external view returns (uint256);

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_,
        bytes memory reserved_
    ) external view returns (uint256);

    /**
     * @dev Get fee amount from the out-amount of token
     * @param feePath_: swap path from _receive to ETH
     * @return totalFee: in Ether
     * @return donationFee: in Ether
     */
    function getFeeAmount(
        address account_,
        uint256 amountOut_,
        address[] memory feePath_,
        bytes memory reserved_
    ) external view returns (uint256, uint256);

    /**
     * @dev Submit transaction
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @param path_: swap path from _payingTokenAddress to receive token
     * @param amountIn_: user paid amount of input token
     * @param requiredAmountOut_: required amount of output token
     * @param paymentId_: payment id, this param will pass to merchant (if merchant received by contract)
     * @param optional_: optional data, this param will pass to merchant (if merchant received by contract)
     * @param reserved_: reserved parameter
     * @return refTokBal Redundant token amount that is refunded to the user
     * @return refFeeBal Redundant fee amount that is refunded to the user
     */
    function submitTransaction(
        address account_,
        address payingToken_,
        uint256 amountIn_,
        uint256 requiredAmountOut_,
        address[] memory path_,
        address[] memory feePath_,
        string memory paymentId_,
        string memory optional_,
        bytes memory reserved_
    )
        external
        payable
        returns (
            uint256, /** refTokBal */
            uint256 /** refFeeBal */
        );
}

// File: contracts/MerchantProperty.sol

pragma solidity ^0.8.0;



/**
 * @dev Merchant-specific property
 */
contract MerchantProperty is IMerchantProperty, Ownable {
    enum FeeMethod {
        SIMPLE,
        LIQU,
        AFLIQU
    }

    enum Property {
        FEE_MAX_PERCENT,
        FEE_MIN_PERCENT,
        DONATION_FEE,
        TRANSACTION_FEE,
        WEB3_BALANCE_FOR_FREE_TX,
        MIN_AMOUNT_TO_PROCESS_FEE,
        MARKETING_WALLET,
        DONATION_WALLET,
        WEB3_TOKEN,
        AFFILIATE_POOL,
        STAKING_POOL,
        MAIN_EXCHANGE,
        SWAP_EXCHANGES
    }
    mapping(Property => bool) private _specificProps; // Property is updated in the contract itself

    uint16 private _feeMaxPercent; // FEE_MAX default 0.5%
    uint16 private _feeMinPercent; // FEE_MIN default 0.1%

    uint16 private _donationFee; // Donation fee default 0.15%
    uint16 public constant MAX_TRANSACTION_FEE = 1000; // Max transacton fee 10%
    uint16 private _transactionFee; // Transaction fee multiplied by 100, default 0.5%

    uint256 private _web3BalanceForFreeTx; // If any wallet has 1000 Web3 tokens, it will be exempted from the transaction fee
    uint256 private _minAmountToProcessFee; // When there is 1 BNB staked, fee will be processed

    address payable private _marketingWallet; // Marketing address
    address payable private _donationWallet; // Donation wallet

    address private _affiliatePool;
    address private _stakingPool;
    address private _web3Token;

    address private _mainExchange; // Main exchange
    uint256 private _mainExchangeFlag; // Main exchange type
    address[] private _exchanges; // Available exchanges
    uint256[] private _exchangeFlags; // exchanges' types

    FeeMethod private _feeProcessingMethod = FeeMethod.SIMPLE; // How to process fee
    address private _merchantWallet; // Merchant wallet
    address private _affiliatorWallet; // Affiliator wallet

    address internal _receiveToken;
    uint256 private _donationFeeCollected;

    bytes internal _reserved;   // reserved param

    address internal _slashCore;
    IMerchantProperty internal _sharedProperty;
    ISlashController internal _slashController;

    function viewFeeMaxPercent() external view override returns (uint16) {
        return
            _specificProps[Property.FEE_MAX_PERCENT]
                ? _feeMaxPercent
                : _sharedProperty.viewFeeMaxPercent();
    }

    function viewFeeMinPercent() external view override returns (uint16) {
        return
            _specificProps[Property.FEE_MIN_PERCENT]
                ? _feeMinPercent
                : _sharedProperty.viewFeeMinPercent();
    }

    function viewDonationFee() external view override returns (uint16) {
        return
            _specificProps[Property.DONATION_FEE]
                ? _donationFee
                : _sharedProperty.viewDonationFee();
    }

    function viewTransactionFee() external view override returns (uint16) {
        return
            _specificProps[Property.TRANSACTION_FEE]
                ? _transactionFee
                : _sharedProperty.viewTransactionFee();
    }

    function viewWeb3BalanceForFreeTx()
        external
        view
        override
        returns (uint256)
    {
        return
            _specificProps[Property.WEB3_BALANCE_FOR_FREE_TX]
                ? _web3BalanceForFreeTx
                : _sharedProperty.viewWeb3BalanceForFreeTx();
    }

    function viewMinAmountToProcessFee()
        external
        view
        override
        returns (uint256)
    {
        return
            _specificProps[Property.MIN_AMOUNT_TO_PROCESS_FEE]
                ? _minAmountToProcessFee
                : _sharedProperty.viewMinAmountToProcessFee();
    }

    function viewMarketingWallet()
        external
        view
        override
        returns (address payable)
    {
        return
            _specificProps[Property.MARKETING_WALLET]
                ? _marketingWallet
                : _sharedProperty.viewMarketingWallet();
    }

    function viewDonationWallet()
        external
        view
        override
        returns (address payable)
    {
        return
            _specificProps[Property.DONATION_WALLET]
                ? _donationWallet
                : _sharedProperty.viewDonationWallet();
    }

    function viewWeb3Token() public view override returns (address) {
        return
            _specificProps[Property.WEB3_TOKEN]
                ? _web3Token
                : _sharedProperty.viewWeb3Token();
    }

    function viewAffiliatePool() public view override returns (address) {
        return
            _specificProps[Property.AFFILIATE_POOL]
                ? _affiliatePool
                : _sharedProperty.viewAffiliatePool();
    }

    function viewStakingPool() external view override returns (address) {
        return
            _specificProps[Property.STAKING_POOL]
                ? _stakingPool
                : _sharedProperty.viewStakingPool();
    }

    function viewMainExchange()
        external
        view
        override
        returns (address, uint256)
    {
        return
            _specificProps[Property.MAIN_EXCHANGE]
                ? (_mainExchange, _mainExchangeFlag)
                : _sharedProperty.viewMainExchange();
    }

    function viewExchanges()
        external
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        return
            _specificProps[Property.SWAP_EXCHANGES]
                ? (_exchanges, _exchangeFlags)
                : _sharedProperty.viewExchanges();
    }

    /**
     * @dev Pay token black list property is only available in shared property contract
     * Thats why it returns false here
     */
    function isBlacklistedFromPayToken(address token_)
        external
        view
        override
        returns (bool)
    {
        return _sharedProperty.isBlacklistedFromPayToken(token_);
    }

    /**
     * @dev Recv token whitelist property is only available in shared property contract
     * Thats why it returns false here
     */
    function isWhitelistedForRecToken(address token_)
        external
        view
        override
        returns (bool)
    {
        return _sharedProperty.isWhitelistedForRecToken(token_);
    }

    function viewMerchantWallet() external view override returns (address) {
        return _merchantWallet;
    }

    function viewAffiliatorWallet() external view override returns (address) {
        return _affiliatorWallet;
    }

    /**
     * @dev Fee processing method property is only available in merchant-specific contract
     * Thats why it returns 0 here
     */
    function viewFeeProcessingMethod() external view override returns (uint8) {
        return uint8(_feeProcessingMethod);
    }

    function viewReceiveToken() external view override returns (address) {
        return _receiveToken;
    }

    function viewDonationFeeCollected()
        external
        view
        override
        returns (uint256)
    {
        return _donationFeeCollected;
    }

    function viewSlashCore() external view returns (address) {
        return _slashCore;
    }

    function viewReserved() external view override returns (bytes memory) {
        return _reserved;
    }

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 maxPercent_)
        external
        override
        onlyOwner
    {
        require(
            maxPercent_ <= 10000 && maxPercent_ >= _feeMinPercent,
            "Invalid value"
        );

        _feeMaxPercent = maxPercent_;
        _specificProps[Property.FEE_MAX_PERCENT] = true;
    }

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 minPercent_)
        external
        override
        onlyOwner
    {
        require(
            minPercent_ <= 10000 && minPercent_ <= _feeMaxPercent,
            "Invalid value"
        );

        _feeMinPercent = minPercent_;
        _specificProps[Property.FEE_MIN_PERCENT] = true;
    }

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 fee_) external override onlyOwner {
        require(fee_ <= 10000, "Invalid fee");

        _donationFee = fee_;
        _specificProps[Property.DONATION_FEE] = true;
    }

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 fee_) external override onlyOwner {
        require(fee_ <= MAX_TRANSACTION_FEE, "Invalid fee");
        _transactionFee = fee_;
        _specificProps[Property.TRANSACTION_FEE] = true;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 web3Balance_)
        external
        override
        onlyOwner
    {
        require(web3Balance_ > 0, "Invalid value");
        _web3BalanceForFreeTx = web3Balance_;
        _specificProps[Property.WEB3_BALANCE_FOR_FREE_TX] = true;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 minAmount_)
        external
        override
        onlyOwner
    {
        require(minAmount_ > 0, "Invalid value");
        _minAmountToProcessFee = minAmount_;
        _specificProps[Property.MIN_AMOUNT_TO_PROCESS_FEE] = true;
    }

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable marketingWallet_)
        external
        override
        onlyOwner
    {
        require(marketingWallet_ != address(0), "Invalid address");
        _marketingWallet = marketingWallet_;
        _specificProps[Property.MARKETING_WALLET] = true;
    }

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable donationWallet_)
        external
        override
        onlyOwner
    {
        require(donationWallet_ != address(0), "Invalid address");
        _donationWallet = donationWallet_;
        _specificProps[Property.DONATION_WALLET] = true;
    }

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address tokenAddress_)
        external
        override
        onlyOwner
    {
        require(tokenAddress_ != address(0), "Invalid token");
        _web3Token = tokenAddress_;
        _specificProps[Property.WEB3_TOKEN] = true;
    }

    function updateaffiliatePool(address affiliatePool_)
        external
        override
        onlyOwner
    {
        require(affiliatePool_ != address(0), "Invalid pool");
        _affiliatePool = affiliatePool_;
        _specificProps[Property.AFFILIATE_POOL] = true;
    }

    function updateStakingPool(address stakingPool_)
        external
        override
        onlyOwner
    {
        require(stakingPool_ != address(0), "Invalid pool");
        _stakingPool = stakingPool_;
        _specificProps[Property.STAKING_POOL] = true;
    }

    /**
     * @dev Update the main exchange.
     * Can only be called by the owner.
     */
    function updateMainExchange(address exchange_, uint256 flag_)
        external
        override
        onlyOwner
    {
        require(
            exchange_ != address(0) && flag_ > 0,
            "Invalid exchange config"
        );
        _mainExchange = exchange_;
        _mainExchangeFlag = flag_;
        _specificProps[Property.MAIN_EXCHANGE] = true;
    }

    /**
     * @dev Add the exchange.
     * Can only be called by the owner.
     */
    function addExchange(address exchange_, uint256 flag_)
        external
        override
        onlyOwner
    {
        require(
            exchange_ != address(0) && flag_ > 0,
            "Invalid exchange config"
        );
        _exchanges.push(exchange_);
        _exchangeFlags.push(flag_);
        _specificProps[Property.SWAP_EXCHANGES] = true;
    }

    /**
     * @dev Remove the exchange from avilable exchanges.
     * Can only be called by the owner.
     */
    function removeExchange(uint256 index_) external override onlyOwner {
        require(index_ < _exchanges.length, "Invalid index");

        if (index_ != _exchanges.length - 1) {
            _exchanges[index_] = _exchanges[_exchanges.length - 1];
            _exchangeFlags[index_] = _exchangeFlags[_exchangeFlags.length - 1];
        }

        delete _exchanges[_exchanges.length - 1];
        delete _exchangeFlags[_exchangeFlags.length - 1];
        _exchanges.pop();
        _exchangeFlags.pop();
        if (_exchanges.length == 0) {
            _specificProps[Property.SWAP_EXCHANGES] = false;
        }
    }

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address token_)
        external
        override
        onlyOwner
    {}

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address token_)
        external
        override
        onlyOwner
    {}

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address token_)
        external
        override
        onlyOwner
    {}

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address token_)
        external
        override
        onlyOwner
    {}

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address merchantWallet_)
        public
        override
        onlyOwner
    {
        require(merchantWallet_ != address(0), "Invalid address");
        _merchantWallet = merchantWallet_;
    }

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWallet(address affiliatorWallet_)
        external
        override
        onlyOwner
    {
        require(affiliatorWallet_ != address(0), "Invalid address");
        _affiliatorWallet = affiliatorWallet_;
    }

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(uint8 method_)
        external
        override
        onlyOwner
    {
        address web3Token = viewWeb3Token();
        address affiliatePool = viewAffiliatePool();
        FeeMethod method = FeeMethod(method_);

        if (method == FeeMethod.AFLIQU) {
            require(
                web3Token != address(0) &&
                    affiliatePool != address(0) &&
                    _affiliatorWallet != address(0),
                "Invalid condition1"
            );
        }
        if (method == FeeMethod.LIQU) {
            require(web3Token != address(0), "Invalid condition2");
        }

        _feeProcessingMethod = method;
    }

    /**
     * @dev Update donation fee collected amount
     * Only callable by owner
     */
    function updateDonationFeeCollected(uint256 fee_)
        external
        override
        onlyOwner
    {
        _donationFeeCollected = fee_;
    }

    /**
     * @dev Update reserve param
     * Only callable by owner
     */
    function updateReserve(bytes memory reserved_)
        external
        override
        onlyOwner
    {
        _reserved = reserved_;
    }

    /**
     * @dev Disable self property
     * Only callable by owner
     * @param property_: property to be disabled
     */
    function disableSpecificProp(Property property_) external onlyOwner {
        _specificProps[property_] = false;
    }
}

// File: contracts/Merchant.sol



pragma solidity ^0.8.0;






contract Merchant is Pausable, MerchantProperty, ReentrancyGuard {
    using SafeMath for uint256;
    using UniversalERC20 for IERC20;

    struct TransctionInfo {
        bytes16 txId;
        address userAddress;
        address payingToken;
        address receiveToken;
        uint256 amountIn;
        uint256 amountOut;
        uint256 refTokBal; // Refunded token amount
        uint256 refFeeBal; // Refunded fee amount
        uint256 timeStamp;
    }

    bool private _initialized;

    uint256 public _totalTxCount;
    mapping(address => uint256) public _userTxCount;
    mapping(bytes16 => TransctionInfo) private _txDetails;
    mapping(address => bytes16[]) private _userTxDetails;

    event NewTransaction(
        bytes16 txId,
        address userAddress,
        address payingToken,
        address receiveToken,
        uint256 amountIn,
        uint256 amountOut,
        uint256 refTokBal,
        uint256 refFeeBal,
        uint256 timeStamp
    );
    event SwapEtherToWeb3TokenFailed(uint256 etherAmount);
    event AddLiquidityFailed(
        uint256 tokenAmount,
        uint256 etherAmount,
        address to
    );

    //to recieve ETH
    receive() external payable {}

    /**
     * @dev Initialize merchant contract
     * Only merchant factory callable
     */
    function initialize(
        address slashController_,
        address merchantWallet_,
        address receiveToken_,
        address merchantOwner_,
        bytes memory reserved_
    ) external onlyOwner {
        require(!_initialized, "Already initialized");
        require(merchantOwner_ != address(0), "Invalid merchant owner");

        updateMerchantWallet(merchantWallet_);
        updateSlashController(slashController_);

        IERC20(receiveToken_).universalBalanceOf(address(this)); // Function just confirming
        require(
            _sharedProperty.isWhitelistedForRecToken(receiveToken_),
            "Not whitelisted token"
        );

        _receiveToken = receiveToken_;
        _reserved = reserved_;
        _initialized = true;

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(merchantOwner_);
    }

    /**
     * @dev Update slash controller
     */
    function updateSlashController(address slashController_) public onlyOwner {
        require(slashController_ != address(0), "Invalid controller");
        _slashController = ISlashController(slashController_);
        _sharedProperty = IMerchantProperty(
            _slashController.getSharedProperty()
        );
        _slashCore = _slashController.getSlashCore();
    }

    /**
     * @dev Get out-amount from the in-amount of token
     * @param payingToken_: the address of paying token, zero address will be considered as native token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address payingToken_,
        uint256 amountIn_,
        address[] memory path_,
        bytes memory reserved_ /** reserved */
    ) external view returns (uint256) {
        return
            _slashController.getAmountOut(
                payingToken_,
                amountIn_,
                path_,
                reserved_
            );
    }

    /**
     * @dev Get in-amount to get out-amount of receive token
     * @param payingToken_: the address of paying token, zero address will be considered as native token
     * @return in-amount of token
     */
    function getAmountIn(
        address payingToken_,
        uint256 amountOut_,
        address[] memory path_,
        bytes memory reserved_ /** reserved */
    ) external view returns (uint256) {
        return
            _slashController.getAmountIn(
                payingToken_,
                amountOut_,
                path_,
                reserved_
            );
    }

    /**
     * @dev Get fee amount from the out-amount of token
     * @param feePath_: swap path from _receiveToken to ETH
     * @return totalFee: in Ether
     * @return donationFee: in Ether
     */
    function getFeeAmount(
        uint256 amountOut_,
        address[] memory feePath_,
        bytes memory reserved_ /** reserved */
    ) public view returns (uint256, uint256) {
        return
            _slashController.getFeeAmount(
                _msgSender(),
                amountOut_,
                feePath_,
                reserved_
            );
    }

    /**
     * @dev Submit transaction
     * @param payingToken_: the address of paying token, zero address will be considered as native token
     * @param feePath_: swap path from _payingTokenAddress to WETH
     * @param path_: swap path from _payingTokenAddress to receive token
     * @param amountIn_: paid input amount by user
     * @param requiredAmountOut_: required output amount by seller
     * @param paymentId_: payment id, this param will pass to merchant (if merchant received by contract)
     * @param optional_: optional data, this param will pass to merchant (if merchant received by contract)
     * @param reserved_: reserved parameter
     * @return txNumber Transaction number
     */
    function submitTransaction(
        address payingToken_,
        uint256 amountIn_,
        uint256 requiredAmountOut_,
        address[] memory path_,
        address[] memory feePath_,
        string memory paymentId_,
        string memory optional_,
        bytes memory reserved_ /** reserved */
    ) external payable whenNotPaused nonReentrant returns (bytes16 txNumber) {
        (uint256 refTokBal, uint256 refFeeBal) = _slashController
            .submitTransaction{value: msg.value}(
            _msgSender(),
            payingToken_,
            amountIn_,
            requiredAmountOut_,
            path_,
            feePath_,
            paymentId_,
            optional_,
            reserved_
        );

        // Generate tx id and then save all information related with tx
        txNumber = generateTxID(_msgSender());
        _txDetails[txNumber].txId = txNumber;
        _txDetails[txNumber].userAddress = _msgSender();
        _txDetails[txNumber].payingToken = payingToken_;
        _txDetails[txNumber].receiveToken = _receiveToken;
        _txDetails[txNumber].amountIn = amountIn_;
        _txDetails[txNumber].amountOut = requiredAmountOut_;
        _txDetails[txNumber].refTokBal = refTokBal;
        _txDetails[txNumber].refFeeBal = refFeeBal;
        _txDetails[txNumber].timeStamp = block.timestamp;

        _userTxDetails[_msgSender()].push(txNumber);

        _totalTxCount = _totalTxCount.add(1);
        _userTxCount[_msgSender()] = _userTxCount[_msgSender()].add(1);

        emit NewTransaction(
            txNumber,
            _msgSender(),
            payingToken_,
            _receiveToken,
            amountIn_,
            requiredAmountOut_,
            refTokBal,
            refFeeBal,
            block.timestamp.add(300)
        );

        return txNumber;
    }

    function toBytes16(uint256 x) internal pure returns (bytes16 b) {
        return bytes16(bytes32(x));
    }

    function generateID(
        address x,
        uint256 y,
        bytes1 z
    ) internal pure returns (bytes16 b) {
        b = toBytes16(uint256(keccak256(abi.encodePacked(x, y, z))));
    }

    function generateTxID(address userAddress_)
        internal
        view
        returns (bytes16 stakeID)
    {
        return generateID(userAddress_, _userTxCount[userAddress_], 0x01);
    }

    function getTxDetailById(bytes16 txNumber_)
        external
        view
        returns (TransctionInfo memory)
    {
        return _txDetails[txNumber_];
    }

    function transactionPagination(
        address userAddress_,
        uint256 offset_,
        uint256 length_
    ) external view returns (bytes16[] memory txIds) {
        uint256 start = offset_ > 0 && _userTxCount[userAddress_] > offset_
            ? _userTxCount[userAddress_] - offset_
            : _userTxCount[userAddress_];

        uint256 finish = length_ > 0 && start > length_ ? start - length_ : 0;

        txIds = new bytes16[](start - finish);
        uint256 i;
        for (uint256 txIndex = start; txIndex > finish; txIndex--) {
            bytes16 txID = generateID(userAddress_, txIndex - 1, 0x01);
            txIds[i] = txID;
            i++;
        }
    }

    function getUserTxCount(address userAddress_)
        external
        view
        returns (uint256)
    {
        return _userTxCount[userAddress_];
    }

    function getUserAllTxDetails(address userAddress_)
        external
        view
        returns (uint256, bytes16[] memory)
    {
        return (_userTxCount[userAddress_], _userTxDetails[userAddress_]);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        address web3Token = viewWeb3Token();
        require(_tokenAddress != web3Token, "Cannot be $WEB3 token");
        IERC20(_tokenAddress).universalTransfer(_msgSender(), _tokenAmount);
    }
}

// File: contracts/interfaces/ISlashAddressResolver.sol

pragma solidity ^0.8.0;

interface ISlashAddressResolver {
    function getDefaultController() external view returns (address);
    
    function getSlashController(address merchantContract_)
        external
        view
        returns (address);

    function resolveMerchantWithController(
        address merchantContract_,
        address slashController_
    ) external;

    function slashCommonOwner() external view returns (address);
}

// File: contracts/SlashFactory.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract SlashFactory is Ownable {
    ISlashAddressResolver public _slashAddressResolver;

    event NewMerchantDeployed(address merchantAddress_);
    event SlashAddressResolverUpdated(
        address oldResolver_,
        address newResolver_
    );

    constructor(address slashAddressResolver_) {
        require(
            slashAddressResolver_ != address(0),
            "SlashFactory: Invalid address resolver"
        );
        _slashAddressResolver = ISlashAddressResolver(slashAddressResolver_);
    }

    function updateAddressResolver(address slashAddressResolver_)
        external
        onlyOwner
    {
        require(
            slashAddressResolver_ != address(0),
            "SlashFactory: Invalid address resolver"
        );
        emit SlashAddressResolverUpdated(
            address(_slashAddressResolver),
            slashAddressResolver_
        );
        _slashAddressResolver = ISlashAddressResolver(slashAddressResolver_);
    }

    /**
     * @notice Deploy merchant payment contract
     */
    function deployMerchant(address merchantWallet_, address receiveToken_, bytes memory reserved_ /** reserved */)
        external
    {
        address defaultSlashController = _slashAddressResolver
            .getDefaultController();
        deployMerchantWithSpecificController(
            merchantWallet_,
            receiveToken_,
            defaultSlashController,
            reserved_
        );
    }

    /**
     * @notice Deploy merchant payment contract
     */
    function deployMerchantWithSpecificController(
        address merchantWallet_,
        address receiveToken_,
        address slashController_,
        bytes memory reserved_
    ) public {
        bytes memory bytecode = type(Merchant).creationCode;
        bytes32 salt = keccak256(
            abi.encodePacked(merchantWallet_, receiveToken_, block.timestamp)
        );
        address payable merchantAddress;

        assembly {
            merchantAddress := create2(
                0,
                add(bytecode, 32),
                mload(bytecode),
                salt
            )
        }

        Merchant(merchantAddress).initialize(
            slashController_,
            merchantWallet_,
            receiveToken_,
            _slashAddressResolver.slashCommonOwner(),
            reserved_
        );

        _slashAddressResolver.resolveMerchantWithController(
            merchantAddress,
            slashController_
        );

        emit NewMerchantDeployed(merchantAddress);
    }
}