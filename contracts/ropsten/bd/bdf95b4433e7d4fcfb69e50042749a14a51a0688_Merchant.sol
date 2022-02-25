/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


library MerchantLibrary {

    // Predict swap amount in / out of router
    function predictAmount(
        address _payingToken,
        address _receiveToken,
        IUniswapV2Router02 _swapRouter,
        uint256 knownAmount,
        address[] memory path,
        bool getInAmount
    ) public view returns (uint256) {
        if (address(_swapRouter) == address(0)) {
            return 0;
        }
        if (_payingToken == _receiveToken) {
            return knownAmount;
        }

        // swap path should be valid one
        bool isPathValid = path.length >= 2 &&
            path[0] == _payingToken &&
            path[path.length - 1] == _receiveToken;

        if (!isPathValid) {
            if (
                _payingToken == _swapRouter.WETH() ||
                _receiveToken == _swapRouter.WETH()
            ) {
                path = new address[](2);
                path[0] = _payingToken;
                path[1] = _receiveToken;
            } else {
                path = new address[](3);
                path[0] = _payingToken;
                path[1] = _swapRouter.WETH();
                path[2] = _receiveToken;
            }
        }

        if (getInAmount) {
            try _swapRouter.getAmountsIn(knownAmount, path) returns (
                uint256[] memory amounts
            ) {
                return amounts[0];
            } catch (
                bytes memory /* lowLevelData */
            ) {
                return 0;
            }
        } else {
            try _swapRouter.getAmountsOut(knownAmount, path) returns (
                uint256[] memory amounts
            ) {
                return amounts[amounts.length - 1];
            } catch (
                bytes memory /* lowLevelData */
            ) {
                return 0;
            }
        }
    }

    function predictBestOutAmount(
        address _payingToken,
        address _receiveToken,
        uint256 _amountIn,
        address[] memory _swapRouters,
        address[] memory path
    ) public view returns (uint256 bestAmount, uint256 bestRouterIndex) {
        for (uint256 i = 0; i < _swapRouters.length; i++) {
            IUniswapV2Router02 swapRouter = IUniswapV2Router02(_swapRouters[i]);
            uint256 amount = predictAmount(
                _payingToken,
                _receiveToken,
                swapRouter,
                _amountIn,
                path,
                true
            );
            if (bestAmount < amount) {
                bestAmount = amount;
                bestRouterIndex = i;
            }
        }
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
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
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


interface IAffiliatePool {
    /**
     * deposit affiliate fee
     * _account: affiliator wallet address
     * _amount: deposit amount
     */
    function deposit(address _account, uint256 _amount) external returns (bool);

    /**
     * withdraw affiliate fee
     * withdraw sender's affiliate fee to sender address
     * _amount: withdraw amount. withdraw all amount if _amount is 0
     */
    function withdraw(uint256 _amount) external returns (bool);

    /**
     * get affiliate fee balance
     * _account: affiliator wallet address
     */
    function balanceOf(address _account) external view returns (uint256);


    /**
     * initialize contract (only owner)
     * _tokenAddress: token contract address of affiliate fee
     */
    function initialize(address _tokenAddress) external;

    /**
     * transfer ownership (only owner)
     * _account: wallet address of new owner
     */
    function transferOwnership(address _account) external;

    /**
     * recover wrong tokens (only owner)
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external;

    /**
     * @dev called by the owner to pause, triggers stopped state
     * deposit, withdraw method is suspended
     */
    function pause() external;

    /**
     * @dev called by the owner to unpause, untriggers stopped state
     * deposit, withdraw method is enabled
     */
    function unpause() external;
}

interface IStakingPool {
    function balanceOf(address _account) external view returns (uint256);

    function getShare(address _account) external view returns (uint256);
}

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


abstract contract MerchantSharedProperty is Ownable {
    enum FeeMethod {
        SIMPLE,
        LIQU,
        AFLIQU
    }

    enum SharedProperty {
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
        MAIN_SWAP_ROUTER,
        SWAP_ROUTERS
    }
    mapping(SharedProperty => bool) private propSelfUpdates; // Property is updated in the contract itself

    mapping(address => bool) private payTokenBlcklist; // List of tokens can not be used for paying
    mapping(address => bool) private recTokenWhitelist; // list of tokens can be used for receiving

    // Merchant factory contract address
    address public MERCHANT_FACTORY;

    uint16 private feeMaxPercent; // FEE_MAX default 0.5%
    uint16 private feeMinPercent; // FEE_MIN default 0.1%

    uint16 private donationFee; // Donation fee default 0.15%
    uint16 public constant MAX_TRANSACTION_FEE = 1000; // Max transacton fee 10%
    uint16 private transactionFee; // Transaction fee multiplied by 100, default 0.5%

    uint256 private web3BalanceForFreeTx; // If any wallet has 1000 Web3 tokens, it will be exempted from the transaction fee
    uint256 private minAmountToProcessFee; // When there is 1 BNB staked, fee will be processed

    address payable private marketingWallet; // Marketing address
    address payable private donationWallet; // Donation wallet

    IAffiliatePool private affiliatePool;
    IStakingPool private stakingPool;
    IERC20 private web3Token;

    IUniswapV2Router02 private mainSwapRouter; // Main swap router
    address[] private swapRouters; // Available swap routers

    FeeMethod public feeProcessingMethod = FeeMethod.SIMPLE; // How to process fee
    address public merchantWallet; // Merchant wallet
    address public affiliatorWallet;

    event TransactionFeeUpdated(uint16 previousFee, uint16 newFee);
    event DonationFeeUpdated(uint256 previousFee, uint256 newFee);
    event FeeMaxPercentUpdated(uint256 previousFee, uint256 newFee);
    event FeeMinPercentUpdated(uint256 previousFee, uint256 newFee);
    event Web3BalanceForFreeTxUpdated(
        uint256 previousBalance,
        uint256 newBalance
    );
    event MinAmountToProcessFeeUpdated(uint256 oldAmount, uint256 newAmount);
    event MarketingWalletUpdated(
        address payable oldWallet,
        address payable newWallet
    );
    event DonationWalletUpdated(
        address payable oldWallet,
        address payable newWallet
    );
    event MerchantWalletUpdated(address oldWallet, address newWallet);
    event AffiliatorWalletUpdatd(address oldWallet, address newWallet);
    event FeeProcessingMethodUpdated(FeeMethod oldMethod, FeeMethod newMethod);
    event Web3TokenUpdated(address oldToken, address newToken);
    event AffiliatePoolUpdated(IAffiliatePool oldPool, IAffiliatePool newPool);
    event StakingPoolUpdated(IStakingPool oldPool, IStakingPool newPool);
    event MainSwapRouterUpdated(address indexed oldRouter, address indexed newRouter);
    event SwapRouterAdded(address indexed newRouter);

    function viewFeeMaxPercent() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.FEE_MAX_PERCENT]
        ) {
            return feeMaxPercent;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewFeeMaxPercent();
    }

    function viewFeeMinPercent() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.FEE_MIN_PERCENT]
        ) {
            return feeMinPercent;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewFeeMinPercent();
    }

    function viewDonationFee() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.DONATION_FEE]
        ) {
            return donationFee;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewDonationFee();
    }

    function viewTransactionFee() public view virtual returns (uint16) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.TRANSACTION_FEE]
        ) {
            return transactionFee;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewTransactionFee();
    }

    function viewWeb3BalanceForFreeTx() public view virtual returns (uint256) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.WEB3_BALANCE_FOR_FREE_TX]
        ) {
            return web3BalanceForFreeTx;
        }
        return
            MerchantSharedProperty(MERCHANT_FACTORY).viewWeb3BalanceForFreeTx();
    }

    function viewMinAmountToProcessFee() public view virtual returns (uint256) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.MIN_AMOUNT_TO_PROCESS_FEE]
        ) {
            return minAmountToProcessFee;
        }
        return
            MerchantSharedProperty(MERCHANT_FACTORY)
                .viewMinAmountToProcessFee();
    }

    function viewMarketingWallet()
        public
        view
        virtual
        returns (address payable)
    {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.MARKETING_WALLET]
        ) {
            return marketingWallet;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewMarketingWallet();
    }

    function viewDonationWallet()
        public
        view
        virtual
        returns (address payable)
    {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.DONATION_WALLET]
        ) {
            return donationWallet;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewDonationWallet();
    }

    function viewWeb3Token() public view virtual returns (IERC20) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.WEB3_TOKEN]
        ) {
            return web3Token;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewWeb3Token();
    }

    function viewAffiliatePool() public view virtual returns (IAffiliatePool) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.AFFILIATE_POOL]
        ) {
            return affiliatePool;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewAffiliatePool();
    }

    function viewStakingPool() public view virtual returns (IStakingPool) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.STAKING_POOL]
        ) {
            return stakingPool;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewStakingPool();
    }

    function viewMainSwapRouter() public view virtual returns (IUniswapV2Router02) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.MAIN_SWAP_ROUTER]
        ) {
            return mainSwapRouter;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewMainSwapRouter();
    }

    function viewSwapRouters() public view virtual returns (address[] memory) {
        if (
            MERCHANT_FACTORY == address(0) ||
            propSelfUpdates[SharedProperty.SWAP_ROUTERS]
        ) {
            return swapRouters;
        }
        return MerchantSharedProperty(MERCHANT_FACTORY).viewSwapRouters();
    }

    function isBlacklistedFromPayToken(address _token)
        public
        view
        returns (bool)
    {
        return payTokenBlcklist[_token];
    }

    function isWhitelistedForRecToken(address _token)
        public
        view
        returns (bool)
    {
        return recTokenWhitelist[_token];
    }

    /**
     * @dev Update fee max percentage
     * Only callable by owner
     */
    function updateFeeMaxPercent(uint16 _maxPercent) public onlyOwner {
        require(
            _maxPercent <= 10000 && _maxPercent >= feeMinPercent,
            "Invalid value"
        );

        emit FeeMaxPercentUpdated(feeMaxPercent, _maxPercent);
        feeMaxPercent = _maxPercent;
        propSelfUpdates[SharedProperty.FEE_MAX_PERCENT] = true;
    }

    /**
     * @dev Update fee min percentage
     * Only callable by owner
     */
    function updateFeeMinPercent(uint16 _minPercent) public onlyOwner {
        require(
            _minPercent <= 10000 && _minPercent <= feeMaxPercent,
            "Invalid value"
        );

        emit FeeMinPercentUpdated(feeMinPercent, _minPercent);
        feeMinPercent = _minPercent;
        propSelfUpdates[SharedProperty.FEE_MIN_PERCENT] = true;
    }

    /**
     * @dev Update donation fee
     * Only callable by owner
     */
    function updateDonationFee(uint16 _fee) public onlyOwner {
        require(_fee <= 10000, "Invalid fee");

        emit DonationFeeUpdated(donationFee, _fee);
        donationFee = _fee;
        propSelfUpdates[SharedProperty.DONATION_FEE] = true;
    }

    /**
     * @dev Update the transaction fee
     * Can only be called by the owner
     */
    function updateTransactionFee(uint16 _fee) public onlyOwner {
        require(_fee <= MAX_TRANSACTION_FEE, "Invalid fee");
        emit TransactionFeeUpdated(transactionFee, _fee);
        transactionFee = _fee;
        propSelfUpdates[SharedProperty.TRANSACTION_FEE] = true;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateWeb3BalanceForFreeTx(uint256 _web3Balance) public onlyOwner {
        require(_web3Balance > 0, "Invalid value");
        emit Web3BalanceForFreeTxUpdated(web3BalanceForFreeTx, _web3Balance);
        web3BalanceForFreeTx = _web3Balance;
        propSelfUpdates[SharedProperty.WEB3_BALANCE_FOR_FREE_TX] = true;
    }

    /**
     * @dev Update the web3 balance for free transaction
     * Can only be called by the owner
     */
    function updateMinAmountToProcessFee(uint256 _minAmount) public onlyOwner {
        require(_minAmount > 0, "Invalid value");
        emit MinAmountToProcessFeeUpdated(minAmountToProcessFee, _minAmount);
        minAmountToProcessFee = _minAmount;
        propSelfUpdates[SharedProperty.MIN_AMOUNT_TO_PROCESS_FEE] = true;
    }

    /**
     * @dev Update the marketing wallet address
     * Can only be called by the owner.
     */
    function updateMarketingWallet(address payable _marketingWallet)
        public
        onlyOwner
    {
        require(_marketingWallet != address(0), "Invalid address");
        emit MarketingWalletUpdated(marketingWallet, _marketingWallet);
        marketingWallet = _marketingWallet;
        propSelfUpdates[SharedProperty.MARKETING_WALLET] = true;
    }

    /**
     * @dev Update the donation wallet address
     * Can only be called by the owner.
     */
    function updateDonationWallet(address payable _donationWallet)
        public
        onlyOwner
    {
        require(_donationWallet != address(0), "Invalid address");
        emit DonationWalletUpdated(donationWallet, _donationWallet);
        donationWallet = _donationWallet;
        propSelfUpdates[SharedProperty.DONATION_WALLET] = true;
    }

    /**
     * @dev Update web3 token address
     * Callable only by owner
     */
    function updateWeb3TokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token");

        emit Web3TokenUpdated(address(web3Token), _tokenAddress);
        web3Token = IERC20(_tokenAddress);
        propSelfUpdates[SharedProperty.WEB3_TOKEN] = true;
    }

    function updateaffiliatePool(IAffiliatePool _affiliatePool)
        public
        onlyOwner
    {
        require(address(_affiliatePool) != address(0), "Invalid pool");
        emit AffiliatePoolUpdated(affiliatePool, _affiliatePool);
        affiliatePool = _affiliatePool;
        propSelfUpdates[SharedProperty.AFFILIATE_POOL] = true;
    }

    function updateStakingPool(IStakingPool _stakingPool) public onlyOwner {
        require(address(_stakingPool) != address(0), "Invalid pool");
        emit StakingPoolUpdated(stakingPool, _stakingPool);
        stakingPool = _stakingPool;
        propSelfUpdates[SharedProperty.STAKING_POOL] = true;
    }

    /**
     * @dev Update the main swap router.
     * Can only be called by the owner.
     */
    function updateMainSwapRouter(address _router) public onlyOwner {
        require(_router != address(0), "Invalid router");
        emit MainSwapRouterUpdated(address(mainSwapRouter), _router);
        mainSwapRouter = IUniswapV2Router02(_router);
        propSelfUpdates[SharedProperty.MAIN_SWAP_ROUTER] = true;
    }

    /**
     * @dev Update the swap router.
     * Can only be called by the owner.
     */
    function addSwapRouter(address _router) public onlyOwner {
        require(_router != address(0), "Invalid router");
        emit SwapRouterAdded(_router);
        swapRouters.push(_router);
        propSelfUpdates[SharedProperty.SWAP_ROUTERS] = true;
    }

    /**
     * @dev Update the merchant wallet address
     * Can only be called by the owner.
     */
    function updateMerchantWallet(address _merchantWallet) public onlyOwner {
        require(_merchantWallet != address(0), "Invalid address");
        emit MerchantWalletUpdated(merchantWallet, _merchantWallet);
        merchantWallet = _merchantWallet;
    }

    /**
     * @dev Update affiliator wallet address
     * Only callable by owner
     */
    function updateAffiliatorWalletAddress(address _walletAddress)
        public
        onlyOwner
    {
        require(_walletAddress != address(0), "Invalid address");
        emit AffiliatorWalletUpdatd(affiliatorWallet, _walletAddress);
        affiliatorWallet = _walletAddress;
    }

    /**
     * @dev Update fee processing method
     * Only callable by owner
     */
    function updateFeeProcessingMethod(FeeMethod _method) public onlyOwner {
        if (_method == FeeMethod.AFLIQU) {
            require(
                address(web3Token) != address(0) &&
                    address(affiliatePool) != address(0) &&
                    affiliatorWallet != address(0),
                "Invalid condition1"
            );
        }
        if (_method == FeeMethod.LIQU) {
            require(address(web3Token) != address(0), "Invalid condition2");
        }

        emit FeeProcessingMethodUpdated(feeProcessingMethod, _method);
        feeProcessingMethod = _method;
    }

    /**
     * @dev Exclude a token from paying blacklist
     * Only callable by owner
     */
    function excludeFromPayTokenBlacklist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        payTokenBlcklist[_token] = false;
    }

    /**
     * @dev Include a token in paying blacklist
     * Only callable by owner
     */
    function includeInPayTokenBlacklist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        payTokenBlcklist[_token] = true;
    }

    /**
     * @dev Exclude a token from receiving whitelist
     * Only callable by owner
     */
    function excludeFromRecTokenWhitelist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        recTokenWhitelist[_token] = false;
    }

    /**
     * @dev Include a token in receiving whitelist
     * Only callable by owner
     */
    function includeInRecTokenWhitelist(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token");
        recTokenWhitelist[_token] = true;
    }
}


contract Merchant is Pausable, MerchantSharedProperty, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TransctionInfo {
        bytes16 txId;
        address userAddress;
        address payingToken;
        uint256 amount;
        uint256 timeStamp;
    }

    // Whether it is initialized
    bool public isInitialized;
    address public receiveToken;

    uint256 public donationFeeCollected;

    uint256 public totalTxCount;
    mapping(address => uint256) public userTxCount;
    mapping(bytes16 => TransctionInfo) private txDetails;
    mapping(address => bytes16[]) private userTxDetails;

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);
    event NewTransaction(
        bytes16 txId,
        address userAddress,
        address payingToken,
        uint256 amount,
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
        address _merchantFactory,
        address _merchantWallet,
        address _receiveToken,
        address _merchantOwner
    ) external onlyOwner {
        require(!isInitialized, "Already initialized");
        require(_merchantFactory != address(0), "Invalid factory");
        require(
            _merchantWallet != address(0),
            "Invalid merchant wallet address"
        );
        require(_merchantOwner != address(0), "Invalid merchant owner");
        require(
            MerchantSharedProperty(_merchantFactory).isWhitelistedForRecToken(
                _receiveToken
            ),
            "Not whitelisted token"
        );
        IERC20(_receiveToken).balanceOf(address(this)); // Function just confirming

        MERCHANT_FACTORY = _merchantFactory;
        merchantWallet = _merchantWallet;
        receiveToken = _receiveToken;
        emit MerchantWalletUpdated(
            payable(address(0)),
            payable(merchantWallet)
        );

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_merchantOwner);
    }

    /**
     * @dev Handle fee
     * @param donationFeeAmount: donation fee is processed separately, so pass this amount
     */
    function handleFee(uint256 donationFeeAmount) internal {
        donationFeeCollected = donationFeeCollected.add(donationFeeAmount);
        uint256 etherBalance = address(this).balance;
        // Fee will be processed only when it is more than specific amount
        if (etherBalance < viewMinAmountToProcessFee()) {
            return;
        }

        if (donationFeeCollected > 0) {
            if (etherBalance >= donationFeeCollected) {
                viewDonationWallet().transfer(donationFeeCollected);
                etherBalance = etherBalance.sub(donationFeeCollected);
                donationFeeCollected = 0;
            } else {
                viewDonationWallet().transfer(etherBalance);
                etherBalance = 0;
                donationFeeCollected = donationFeeCollected.sub(etherBalance);
            }
        }

        if (etherBalance == 0) {
            return;
        }

        address payable marketingWallet = viewMarketingWallet();
        if (feeProcessingMethod == FeeMethod.SIMPLE) {
            marketingWallet.transfer(etherBalance);
        } else if (feeProcessingMethod == FeeMethod.LIQU) {
            // 50% of staked fee is added to WEB3-BNB liquidity and sent to the marketing address
            uint256 liquidifyBalance = etherBalance.div(2);

            uint256 half = liquidifyBalance.div(2);
            uint256 otherHalf = liquidifyBalance.sub(half);

            // Swap ether to web3
            (uint256 swappedWeb3Balance, bool success) = swapEtherToWeb3(
                half,
                address(this)
            );
            if (!success) {
                emit SwapEtherToWeb3TokenFailed(half);
                return;
            }

            // Add liquidity
            success = addLiquidity(
                swappedWeb3Balance,
                otherHalf,
                marketingWallet
            );
            if (!success) {
                emit AddLiquidityFailed(
                    swappedWeb3Balance,
                    otherHalf,
                    marketingWallet
                );
                // Do not return this time
            }

            // 50% of staked fee is swapped to WEB3 tokens to be sent to the marketing address
            uint256 directSwapBalance = address(this).balance;
            // Swap bnb to web3
            (, success) = swapEtherToWeb3(directSwapBalance, marketingWallet);
            if (!success) {
                emit SwapEtherToWeb3TokenFailed(directSwapBalance);
            }
        } else if (feeProcessingMethod == FeeMethod.AFLIQU) {
            IERC20 web3Token = viewWeb3Token();
            IAffiliatePool affiliatePool = viewAffiliatePool();

            // 55% of staked fee is swapped to WEB3 token
            uint256 buyupBalance = etherBalance.mul(55).div(100);
            (, bool success) = swapEtherToWeb3(buyupBalance, address(this));
            if (!success) {
                emit SwapEtherToWeb3TokenFailed(buyupBalance);
                return;
            }

            uint256 web3AmountToStake = web3Token
                .balanceOf(address(this))
                .mul(10)
                .div(55);

            // When fee processing method is AFLIQU, affiliatePool & affiliatorWallet addresses are not zero
            web3Token.approve(address(affiliatePool), web3AmountToStake);
            // 5% amount of WEB3 token is deposited to affiliate pool for merchant and affiliator
            uint256 eachStakeAmount = web3AmountToStake.div(2);
            if (eachStakeAmount > 0) {
                affiliatePool.deposit(merchantWallet, eachStakeAmount);
                affiliatePool.deposit(affiliatorWallet, eachStakeAmount);
            }

            // WEB3 + BNB to liquidity
            uint256 liqifyBalance = web3Token.balanceOf(address(this));
            // Add liquidity
            success = addLiquidity(
                liqifyBalance,
                address(this).balance,
                marketingWallet
            );
            if (!success) {
                emit AddLiquidityFailed(
                    liqifyBalance,
                    address(this).balance,
                    marketingWallet
                );
                return;
            }
        }
    }

    /**
     * @dev Swap tokens for eth
     * This function is called when fee processing mode is LIQU or AFLIQU which means web3 token is always set
     */
    function swapEtherToWeb3(uint256 etherAmount, address to)
        private
        returns (uint256 web3Amount, bool success)
    {
        IUniswapV2Router02 swapRouter = viewMainSwapRouter();
        IERC20 web3Token = viewWeb3Token();

        // generate the saunaSwap pair path of bnb -> web3
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(web3Token);

        // make the swap
        uint256 balanceBefore = web3Token.balanceOf(to);
        try
            swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
                value: etherAmount
            }(
                0, // accept any amount of WEB3
                path,
                to,
                block.timestamp.add(300)
            )
        {
            web3Amount = web3Token.balanceOf(to).sub(balanceBefore);
            success = true;
        } catch (
            bytes memory /* lowLevelData */
        ) {
            success = false;
            web3Amount = 0;
        }
    }

    /**
     * @dev Add liquidity
     * This function is called when fee processing mode is LIQU or AFLIQU which means web3 token is always set
     */
    function addLiquidity(
        uint256 web3Amount,
        uint256 etherAmount,
        address to
    ) private returns (bool success) {
        IUniswapV2Router02 swapRouter = viewMainSwapRouter();
        IERC20 web3Token = viewWeb3Token();

        // approve token transfer to cover all possible scenarios
        web3Token.safeApprove(address(swapRouter), web3Amount);

        // add the liquidity
        try
            swapRouter.addLiquidityETH{value: etherAmount}(
                address(web3Token),
                web3Amount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                to,
                block.timestamp.add(300)
            )
        {
            success = true;
        } catch (
            bytes memory /* lowLevelData */
        ) {
            success = false;
        }
    }

    /**
     * @dev Get in-amount to get out-amount of receive token
     * @return in-amount of token
     */
    function getAmountIn(
        address _payingToken,
        uint256 _amountOut,
        address[] memory _path
    ) external view returns (uint256) {
        // Blacklisted token can not be used as paying token
        if (
            MERCHANT_FACTORY != address(0) &&
            MerchantSharedProperty(MERCHANT_FACTORY).isBlacklistedFromPayToken(
                _payingToken
            )
        ) {
            return 0;
        }
        return
            MerchantLibrary.predictAmount(
                _payingToken,
                receiveToken,
                viewMainSwapRouter(),
                _amountOut,
                _path,
                true
            );
    }

    /**
     * @dev Get out-amount from the in-amount of token
     * @return out-amount of receive token
     */
    function getAmountOut(
        address _payingToken,
        uint256 _amountIn,
        address[] memory _path
    ) external view returns (uint256) {
        // Blacklisted token can not be used as paying token
        if (
            MERCHANT_FACTORY != address(0) &&
            MerchantSharedProperty(MERCHANT_FACTORY).isBlacklistedFromPayToken(
                _payingToken
            )
        ) {
            return 0;
        }

        return
            MerchantLibrary.predictAmount(
                _payingToken,
                receiveToken,
                viewMainSwapRouter(),
                _amountIn,
                _path,
                false
            );
    }

    /**
     * @dev Swap token to receive token and transfer to the merchant wallet
     * @param path: swap path from _payingTokenAddress to receive token
     */
    function doMerchantDeposit(
        address _payingToken,
        uint256 _amountIn,
        address[] memory path
    ) private {
        IUniswapV2Router02 swapRouter = viewMainSwapRouter();

        if (_payingToken == receiveToken) {
            IERC20(receiveToken).safeTransfer(merchantWallet, _amountIn);
        } else {
            // swap path should be valid one
            if (
                !(path.length >= 2 &&
                    path[0] == _payingToken &&
                    path[path.length - 1] == receiveToken)
            ) {
                // generate the saunaSwap pair path when valid path is not provided
                if (
                    _payingToken == swapRouter.WETH() ||
                    receiveToken == swapRouter.WETH()
                ) {
                    // generate the saunaSwap pair path
                    path = new address[](2);
                    path[0] = _payingToken;
                    path[1] = receiveToken;
                } else if (_payingToken != swapRouter.WETH()) {
                    path = new address[](3);
                    path[0] = _payingToken;
                    path[1] = swapRouter.WETH();
                    path[2] = receiveToken;
                }
            }

            // Choose router which returns max amount
            address[] memory availableSwapRouters = viewSwapRouters();
            // Assume that WETH is same in all routers
            (uint256 bestAmount, uint256 bestRouterIndex) = MerchantLibrary
                .predictBestOutAmount(
                    _payingToken,
                    receiveToken,
                    _amountIn,
                    availableSwapRouters,
                    path
                );

            if (bestAmount > 0) {
                IUniswapV2Router02 router = IUniswapV2Router02(
                    availableSwapRouters[bestRouterIndex]
                );

                // Approve token before transfer
                IERC20(_payingToken).approve(address(router), _amountIn);

                // make the swap
                router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    _amountIn,
                    0, // accept any amount of receive token
                    path,
                    merchantWallet,
                    block.timestamp.add(300)
                );
            }
        }
    }

    function getTxFeeAmount(uint256 _amountIn) private view returns (uint256) {
        IERC20 web3Token = viewWeb3Token();
        uint256 web3BalanceForFreeTx = viewWeb3BalanceForFreeTx();
        IStakingPool stakingPool = viewStakingPool();
        uint256 feeMaxPercent = viewFeeMaxPercent();

        // If user wallet has enough web3 token, fee amount is 0
        if (
            address(web3Token) != address(0) &&
            web3Token.balanceOf(_msgSender()) >= web3BalanceForFreeTx
        ) {
            return 0;
        }
        // If user did stake enough amount in staking contract, fee amount is 0
        if (
            address(stakingPool) != address(0) &&
            stakingPool.balanceOf(_msgSender()) >= web3BalanceForFreeTx
        ) {
            return 0;
        }
        // If staking contract is set to the merchant, determine fee amount from the staking amount
        if (address(stakingPool) != address(0)) {
            return
                _amountIn
                    .mul(
                        uint256(feeMaxPercent).sub(
                            stakingPool.getShare(_msgSender()).mul(
                                uint256(feeMaxPercent).sub(viewFeeMinPercent())
                            )
                        )
                    )
                    .div(10000);
        }
        // Default fee amount
        return _amountIn.mul(uint256(viewTransactionFee())).div(10000);
    }

    /**
     * @dev Get fee amount from the in-amount of token
     * @param feePath: swap path from _payingTokenAddress to WETH
     * @return totalFee: in Ether
     * @return donationFee: in Ether
     */
    function getFeeAmount(
        address _payingTokenAddress,
        uint256 _amountIn,
        address[] memory feePath
    ) public view returns (uint256, uint256) {
        // Blacklisted token can not be used as paying token
        if (
            MERCHANT_FACTORY != address(0) &&
            MerchantSharedProperty(MERCHANT_FACTORY).isBlacklistedFromPayToken(
                _payingTokenAddress
            )
        ) {
            return (0, 0);
        }

        IUniswapV2Router02 swapRouter = viewMainSwapRouter();

        uint256 feeAmount = getTxFeeAmount(_amountIn);
        // There is donation fee set always
        uint256 donationFeeAmount = _amountIn.mul(viewDonationFee()).div(10000);
        feeAmount = feeAmount.add(donationFeeAmount);

        if (feeAmount == 0) {
            return (0, 0);
        }

        if (_payingTokenAddress == swapRouter.WETH()) {
            return (feeAmount, donationFeeAmount);
        }

        if (
            !(feePath.length >= 2 &&
                feePath[0] == _payingTokenAddress &&
                feePath[feePath.length - 1] == swapRouter.WETH())
        ) {
            feePath = new address[](2);
            feePath[0] = _payingTokenAddress;
            feePath[1] = swapRouter.WETH();
        }

        uint256[] memory amounts = swapRouter.getAmountsOut(feeAmount, feePath);
        return (
            amounts[feePath.length - 1],
            amounts[feePath.length - 1].mul(donationFeeAmount).div(feeAmount)
        );
    }

    /**
     * @dev Submit transaction
     * @param feePath: swap path from _payingTokenAddress to WETH
     * @param path: swap path from _payingTokenAddress to receive token
     * @return txNumber Transaction number
     */
    function submitTransaction(
        address _payingTokenAddress,
        uint256 _amountIn,
        address[] memory path,
        address[] memory feePath
    ) external payable whenNotPaused nonReentrant returns (bytes16 txNumber) {
        require(_amountIn > 0, "_amountIn > 0");
        // Blacklisted token can not be used as paying token
        if (MERCHANT_FACTORY != address(0)) {
            require(
                !MerchantSharedProperty(MERCHANT_FACTORY)
                    .isBlacklistedFromPayToken(_payingTokenAddress),
                "blacklisted"
            );
        }

        IERC20 payingToken = IERC20(_payingTokenAddress);
        uint256 balanceBefore = payingToken.balanceOf(address(this));
        payingToken.safeTransferFrom(_msgSender(), address(this), _amountIn);
        _amountIn = payingToken.balanceOf(address(this)).sub(balanceBefore);

        (uint256 feeAmount, uint256 donationFeeAmount) = getFeeAmount(
            _payingTokenAddress,
            _amountIn,
            feePath
        );
        require(msg.value >= feeAmount, "Insufficient fee");

        // Swap token to receive token and transfer to the merchant wallet
        doMerchantDeposit(_payingTokenAddress, _amountIn, path);

        // Handle fee
        handleFee(donationFeeAmount);

        txNumber = generateTxID(_msgSender());
        txDetails[txNumber].txId = txNumber;
        txDetails[txNumber].userAddress = _msgSender();
        txDetails[txNumber].payingToken = _payingTokenAddress;
        txDetails[txNumber].amount = _amountIn;
        txDetails[txNumber].timeStamp = block.timestamp;

        userTxDetails[_msgSender()].push(txNumber);

        totalTxCount = totalTxCount.add(1);
        userTxCount[_msgSender()] = userTxCount[_msgSender()].add(1);

        emit NewTransaction(
            txNumber,
            _msgSender(),
            _payingTokenAddress,
            _amountIn,
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

    function generateTxID(address _userAddress)
        internal
        view
        returns (bytes16 stakeID)
    {
        return generateID(_userAddress, userTxCount[_userAddress], 0x01);
    }

    function getTxDetailById(bytes16 _txNumber)
        public
        view
        returns (TransctionInfo memory)
    {
        return txDetails[_txNumber];
    }

    function transactionPagination(
        address _userAddress,
        uint256 _offset,
        uint256 _length
    ) external view returns (bytes16[] memory _txIds) {
        uint256 start = _offset > 0 && userTxCount[_userAddress] > _offset
            ? userTxCount[_userAddress] - _offset
            : userTxCount[_userAddress];

        uint256 finish = _length > 0 && start > _length ? start - _length : 0;

        _txIds = new bytes16[](start - finish);
        uint256 i;
        for (uint256 _txIndex = start; _txIndex > finish; _txIndex--) {
            bytes16 _txID = generateID(_userAddress, _txIndex - 1, 0x01);
            _txIds[i] = _txID;
            i++;
        }
    }

    function getUserTxCount(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userTxCount[_userAddress];
    }

    function getUserAllTxDetails(address _userAddress)
        public
        view
        returns (uint256, bytes16[] memory)
    {
        return (userTxCount[_userAddress], userTxDetails[_userAddress]);
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
        require(
            _tokenAddress != address(viewWeb3Token()),
            "Cannot be $WEB3 token"
        );

        IERC20(_tokenAddress).safeTransfer(_msgSender(), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }
}