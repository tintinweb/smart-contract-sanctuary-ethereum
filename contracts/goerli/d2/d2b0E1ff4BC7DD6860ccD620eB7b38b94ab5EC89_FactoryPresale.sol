/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


// 
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

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// 
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// 
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// 
interface IUniswapV2Factory {
    /*
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    */

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    /*
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    */
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
    /*
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    */
}

// 
interface IUniswapV2Router02 {
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
    /*
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
    */
}

// 
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// 
// import "hardhat/console.sol";
//import "hardhat/console.sol";
contract SaleTimeManagement is Ownable {
    uint128 private _startTime;
    uint128 private _endTime;

    event StartTimeChanged(uint256 oldStartTime, uint256 newStartTime);
    event EndTimeChanged(uint256 oldEndTime, uint256 newEndTime);

    function startTime() public view returns (uint128) {
        return _startTime;
    }

    function endTime() public view returns (uint128) {
        return _endTime;
    }

    modifier onlyWhenEnded() {
        require(block.timestamp >= _endTime, "sale has not ended");
        _;
    }

    modifier onlyWhenActive() {
        require(
            block.timestamp >= _startTime && block.timestamp <= _endTime,
            "sale is not active"
        );
        _;
    }

    modifier onlyBeforeStart() {
        require(
            block.timestamp < _startTime || _startTime == 0,
            "sale has already started"
        );
        _;
    }

    /**
     * @dev Sets the start time of the sale.
     * @param startTime_ The start time of the sale (unix seconds timestamp ).
     */
    function setStartTime(
        uint128 startTime_
    ) external onlyOwner onlyBeforeStart {
        _setStartTime(startTime_);
    }

    function _setStartTime(uint128 startTime_) internal {
        require(startTime_ > block.timestamp, "start time in the past");
        uint256 oldStart = _startTime;
        // keep the sale period the same
        if (_endTime > _startTime) {
            _setEndTime(startTime_ + _endTime - _startTime);
        } else {
            _setEndTime(startTime_ + 1 days);
        }
        _startTime = startTime_;

        emit StartTimeChanged(oldStart, _startTime);
    }

    function setEndTime(uint128 endTime_) external onlyOwner onlyBeforeStart {
        _setEndTime(endTime_);
    }

    function _setEndTime(uint128 endTime_) internal {
        require(endTime_ > _startTime, "endtime < starttime");

        emit EndTimeChanged(_endTime, endTime_);

        _endTime = endTime_;
    }
}

// 
interface IUniswapV2Pair is IERC20 {
    /*
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    */

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    /*
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
    */
}

// 
interface IERC20EXTRA {
    /*
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);
    */
    function decimals() external pure returns (uint8);
    /*
    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint value
    ) external returns (bool);
    */
}

// 
//import "hardhat/console.sol";
contract Whitelist is Ownable {
    event Whitelisted(address indexed user, bool isWhitelisted);

    mapping(address => bool) private _whitelist;

    bool private _whitelistEnabled;

    function enableWhitelist() external onlyOwner {
        _whitelistEnabled = true;
    }

    function disableWhitelist() external onlyOwner {
        _whitelistEnabled = false;
    }

    function isWhitelistEnabled() public view returns (bool) {
        return _whitelistEnabled;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    function addWhitelist(address account) public onlyOwner {
        _whitelist[account] = true;
        emit Whitelisted(account, true);
    }

    function removeWhitelist(address account) public onlyOwner {
        _whitelist[account] = false;
        emit Whitelisted(account, false);
    }

    modifier onlyWhitelisted() {
        if (_whitelistEnabled) {
            require(isWhitelisted(msg.sender), "!whitelisted");
        }
        _;
    }

    function addManyWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            addWhitelist(accounts[i]);
        }
    }

    function removeManyWhitelist(address[] memory accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            removeWhitelist(accounts[i]);
        }
    }
}

// 
uint256 constant MAX_UINT256 = type(uint256).max;

// 51 %
uint256 constant MAX_LP = 100;

// 49 %
// 10%
uint256 constant MIN_LP = 10;

uint256 constant MIN_SOFT_CAP = 10;

// 
//import "hardhat/console.sol";
struct UserInfo {
    uint248 boughtAmount; // using uint248 so this struct will be packed into 64 bytes 8bytes for the bool and 56 bytes for the 2 * uint248
    uint248 spentAmount;
    bool claimed;
}

// This is the exact same contract as Presale.sol but without revert error messages to reduce it's size
contract FactoryPresale is SaleTimeManagement, Whitelist {
    using SafeERC20 for IERC20;
    using SafeERC20 for IUniswapV2Pair;
    using Address for address;

    IERC20 public immutable saleToken;
    IERC20 public immutable raisedToken;
    uint256 public immutable saleTokenDecimals;
    IUniswapV2Router02 public immutable router;

    IUniswapV2Pair public immutable pair;

    uint256 public salePrice;
    uint256 public offredAmount;
    uint256 public soldAmount;

    uint256 public minBuy; // in raised token
    uint256 public maxBuy; // in raised token

    bool public immutable isWETH;

    mapping(address => UserInfo) public usersInfo;

    uint256 public lpPercentage;
    uint256 public lPReserved;
    uint256 public listingPrice;
    uint256 public lpLockPeriodInMinutes;
    bool public lpCreated;
    bool public lpClaimed;

    uint256 public softCap;

    bool public isInitialized;

    bool public allowContracts;

    function setAllowContracts(bool _allowContracts) external onlyOwner {
        _setAllowContracts(_allowContracts);
    }

    function _setAllowContracts(bool _allowContracts) internal {
        if (_allowContracts != allowContracts)
            emit AllowContractChanged(_allowContracts);
        allowContracts = _allowContracts;
    }

    event Buy(address indexed user, uint256 spentAmount, uint256 boughtAmount);
    event Claim(address indexed user, uint256 amount);

    event SalePriceChanged(uint256 oldSalePrice, uint256 newSalePrice);
    event MinBuyChanged(uint256 oldMinBuy, uint256 newMinBuy);
    event MaxBuyChanged(uint256 oldMaxBay, uint256 newMaxBuy);
    event OfferedAmountChanged(uint256 oldAmount, uint256 newOfferedAmount);
    event AllowContractChanged(bool value);

    constructor(
        IERC20 saleToken_,
        IERC20 paymentToken_,
        IUniswapV2Router02 router_,
        address owner_
    ) {
        saleToken = saleToken_;
        raisedToken = paymentToken_;
        router = router_;

        address _pair = IUniswapV2Factory(router.factory()).getPair(
            address(paymentToken_),
            address(saleToken_)
        );
        if (_pair == address(0)) {
            _pair = IUniswapV2Factory(router.factory()).createPair(
                address(paymentToken_),
                address(saleToken_)
            );
        }
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pair)
            .getReserves();
        require(reserve0 == 0 && reserve1 == 0);

        pair = IUniswapV2Pair(_pair);
        // the factory is the one deploying this contract
        // give ownership to the deployer not the factory
        _transferOwnership(owner_);

        isWETH = address(paymentToken_) == router.WETH();

        saleTokenDecimals = 10 ** IERC20EXTRA(address(saleToken_)).decimals();
    }

    modifier onlySuccessful() {
        require(((softCap * saleTokenDecimals) / salePrice) <= soldAmount);
        _;
    }

    modifier onlyNotSuccessful() {
        require(((softCap * saleTokenDecimals) / salePrice) > soldAmount);
        _;
    }

    modifier onlyAfterLpCreated() {
        if (!lpCreated) _createLP();
        _;
    }

    function buy(
        uint256 amount_
    ) external payable onlyWhenActive onlyWhitelisted {
        if (!allowContracts) {
            require(!address(msg.sender).isContract());
        }
        if (!isWETH) {
            require(msg.value == 0);
            raisedToken.safeTransferFrom(msg.sender, address(this), amount_);
        }
        uint256 inAmount = isWETH ? msg.value : amount_;
        require(inAmount >= minBuy);

        usersInfo[msg.sender].spentAmount += uint248(inAmount);
        require(usersInfo[msg.sender].spentAmount <= maxBuy);

        uint256 outAmount = (inAmount * saleTokenDecimals) / salePrice;

        require(outAmount <= (offredAmount - soldAmount));
        usersInfo[msg.sender].boughtAmount += uint248(outAmount);

        soldAmount += outAmount;
    }

    function claim() external onlyWhenEnded onlySuccessful onlyAfterLpCreated {
        require(!usersInfo[msg.sender].claimed);
        usersInfo[msg.sender].claimed = true;
        saleToken.safeTransfer(msg.sender, usersInfo[msg.sender].boughtAmount);
    }

    function claimRefund() external onlyNotSuccessful onlyWhenEnded {
        require(!usersInfo[msg.sender].claimed);
        // avoids reentrancy
        usersInfo[msg.sender].claimed = true;
        if (isWETH) {
            payable(msg.sender).transfer(usersInfo[msg.sender].spentAmount);
        } else {
            raisedToken.safeTransfer(
                msg.sender,
                usersInfo[msg.sender].spentAmount
            );
        }
    }

    function _createLP() internal {
        lpCreated = true;
        uint256 amount = (soldAmount * lpPercentage * salePrice) /
            (100 * saleTokenDecimals);
        uint256 amountinSaleToken = (amount * saleTokenDecimals) / listingPrice;

        // send the left tokens from lp reserves to the owner
        saleToken.safeTransfer(owner(), lPReserved - amountinSaleToken);

        if (!isWETH) {
            raisedToken.safeApprove(address(router), amount);
            saleToken.safeApprove(address(router), amountinSaleToken);
            router.addLiquidity(
                address(raisedToken),
                address(saleToken),
                amount,
                amountinSaleToken,
                0,
                0,
                address(this),
                type(uint256).max
            );
        } else {
            saleToken.safeApprove(address(router), amountinSaleToken);
            router.addLiquidityETH{value: amount}(
                address(saleToken),
                amountinSaleToken,
                0,
                0,
                address(this),
                type(uint256).max
            );
        }
    }

    // claim non sold and lp reserves that was not used
    function clainNonSoldUnsucessfull()
        external
        onlyOwner
        onlyWhenEnded
        onlyNotSuccessful
    {
        saleToken.safeTransfer(msg.sender, lPReserved + offredAmount);
    }

    function widthrawUnsoldAfterSuccessful()
        external
        onlyOwner
        onlyWhenEnded
        onlySuccessful
        onlyAfterLpCreated
    {
        saleToken.safeTransfer(msg.sender, offredAmount - soldAmount);
    }

    function widthrawRaisedToken()
        external
        onlyOwner
        onlyWhenEnded
        onlySuccessful
        onlyAfterLpCreated
    {
        if (!isWETH) {
            raisedToken.safeTransfer(
                msg.sender,
                raisedToken.balanceOf(address(this))
            );
        } else {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    function widthrawLp() external onlyOwner onlyWhenEnded onlyAfterLpCreated {
        require(
            lpLockPeriodInMinutes == 0 ||
                block.timestamp > endTime() + lpLockPeriodInMinutes * 1 minutes
        );
        lpClaimed = true;
        pair.safeTransfer(msg.sender, pair.balanceOf(address(this)));
    }

    function setMinBuy(uint256 minBuy_) external onlyOwner onlyBeforeStart {
        _setMinBuy(minBuy_);
    }

    function setMaxBuy(uint256 maxBuy_) external onlyOwner onlyBeforeStart {
        _setMaxBuy(maxBuy_);
    }

    function initializeSale(
        uint128 startTime_,
        uint128 endTime_,
        uint256 salePrice_,
        uint256 _offredAmount,
        uint256 minBuy_,
        uint256 maxBuy_,
        uint256 lpPercentage_,
        uint256 listingPrice_,
        uint256 lpLockPeriodInMinutes_,
        uint256 softCap_,
        bool allowContracts_
    ) external onlyOwner onlyBeforeStart {
        _setStartTime(startTime_);
        _setEndTime(endTime_);

        _setSalePrice(salePrice_);

        require(_offredAmount > 0);
        _depositSaleToken(_offredAmount);

        _setMinBuy(minBuy_);
        _setMaxBuy(maxBuy_);

        require(listingPrice_ > 0);
        // listing price should not be lower than 90% of the sale price
        require(listingPrice_ >= ((salePrice_ * 9) / 10));
        listingPrice = listingPrice_;
        _setLPPercentage(lpPercentage_);

        _setlPLockPeriodInMinutes(lpLockPeriodInMinutes_);

        uint256 toBeRAised = (_offredAmount * salePrice_) / saleTokenDecimals;
        require(softCap_ <= toBeRAised);
        require(softCap_ >= (toBeRAised * MIN_SOFT_CAP) / 100);
        softCap = softCap_;

        _setAllowContracts(allowContracts_);

        isInitialized = true;
    }

    function _setSalePrice(uint256 salePrice_) internal {
        require(salePrice_ > 0);
        emit SalePriceChanged(salePrice, salePrice_);
        salePrice = salePrice_;
    }

    function _depositSaleToken(uint256 amount_) internal {
        saleToken.safeTransferFrom(msg.sender, address(this), amount_);
        emit OfferedAmountChanged(offredAmount, offredAmount + amount_);
        offredAmount = offredAmount + amount_;
    }

    function _setMaxBuy(uint256 maxBuy_) internal {
        require(maxBuy_ > 0);
        emit MaxBuyChanged(maxBuy, maxBuy_);
        maxBuy = maxBuy_;
    }

    function _setMinBuy(uint256 minBuy_) internal {
        emit MinBuyChanged(minBuy, minBuy_);
        minBuy = minBuy_;
    }

    function _setlPLockPeriodInMinutes(
        uint256 _lpLockPeriodInMinutes
    ) internal {
        lpLockPeriodInMinutes = _lpLockPeriodInMinutes;
    }

    function _setLPPercentage(uint256 _lpPercentage) internal {
        require(_lpPercentage <= MAX_LP);
        require(_lpPercentage >= MIN_LP);

        lpPercentage = _lpPercentage;
        uint256 _lPReserved = ((offredAmount * lpPercentage * salePrice) /
            (100 * listingPrice));

        saleToken.safeTransferFrom(msg.sender, address(this), _lPReserved);
        lPReserved = _lPReserved;
    }
}

// 
contract FinanomyFactory {
    address[] public presales;
    uint256 public presalesCount;

    uint256 public fee = 0.5 ether;

    address public feeAddress;

    constructor() {
        feeAddress = msg.sender;
    }

    modifier onlyFeeAddress() {
        require(msg.sender == feeAddress);
        _;
    }

    event PresaleCreated(
        address indexed presale,
        address indexed token,
        address indexed owner
    );

    function setFee(uint256 _fee) external onlyFeeAddress {
        fee = _fee;
    }

    function setFeeAddress(address _feeAddress) external onlyFeeAddress {
        feeAddress = _feeAddress;
    }

    function createPresale(
        IERC20 saleToken_,
        IERC20 paymentToken_,
        IUniswapV2Router02 router_
    ) public payable {
        require(msg.value >= fee);
        FactoryPresale presale = new FactoryPresale(
            saleToken_,
            paymentToken_,
            router_,
            msg.sender
        );
        presales.push(address(presale));
        presalesCount++;

        emit PresaleCreated(address(presale), address(saleToken_), msg.sender);
    }

    function collectFee() external onlyFeeAddress {
        payable(msg.sender).transfer(address(this).balance);
    }
}