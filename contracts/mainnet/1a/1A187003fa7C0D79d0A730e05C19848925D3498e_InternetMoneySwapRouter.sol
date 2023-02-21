// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

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
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity 0.8.17;

interface IWETH {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"guy","type":"address"},{"name":"wad","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"src","type":"address"},{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"wad","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"name":"dst","type":"address"},{"name":"wad","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"deposit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"name":"","type":"address"},{"name":"","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"stateMutability":"payable","type":"receive"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"guy","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"dst","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"src","type":"address"},{"indexed":false,"name":"wad","type":"uint256"}],"name":"Withdrawal","type":"event"}]
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./OracleReader.sol";
import "./interfaces/IWETH.sol";
import "./Migratable.sol";
import "./Utils.sol";

/**
 * @title contract for swapping tokens
 * @notice use this contract for only the most basic simulation
 * @dev function calls are currently implemented without side effects
 * @notice multicall was not included here because sender
 * is less relevant outside of a swap
 * which already allows for multiple swaps
 */
contract InternetMoneySwapRouter is Ownable, Migratable, Utils, OracleReader {
    using Address for address payable;
    using SafeERC20 for IERC20;
    /** a single dex entry */
    struct Dex {
        uint96 id;
        address router;
        bool disabled;
        string name;
    }
    Dex[] public dexInfo;

    error DexConflict(uint256 dexIndex);
    error NativeMissing(uint256 pathIndex);
    error FeeMissing(uint256 expected, uint256 provided, string message);
    error DestinationMissing();

    /**
     * returns all relevant dex info needed to render clients
     * @return _dexInfo the array of dexes as a DexInfo array
     * @return _wNative the wrapped native address
     * @return _destination destination of fees
     * @return _fee fee numerator as an int constant
     * @return _feeDenominator constant at 100_000
     */
    function allDexInfo() public view returns(
        Dex[] memory _dexInfo,
        address _wNative,
        address _destination,
        uint256 _fee,
        uint256 _feeDenominator
    ) {
        _dexInfo = dexInfo;
        _wNative = wNative;
        _destination = destination;
        _fee = fee;
        _feeDenominator = feeDenominator;
        _wNative = wNative;
    }

    /**
     * where the fees will end up
     * @notice this address cannot be updated after it is set during constructor
     * @notice the destination must be payable + have a receive function
     * that has gas consumption less than limit
     */
    address payable public immutable destination;
    /**
     * @notice map a router to a dex to check
     * if the router was already added, the addition should fail
     */
    mapping(address => uint256) public routerToDex;
    mapping(address => uint256) public feeNumerator;

    event AddDex(address indexed executor, uint256 indexed dexId);
    event UpdateDex(address indexed executor, uint256 indexed dexId);
    event UpdateTokenFee(address indexed token, uint256 indexed feeNumerator);

    /**
     * sets up the wallet swap contract
     * @param _destination where native currency will be sent
     * @param _wNative the address that is used to wrap and unwrap tokens
     * @notice wNative does not have to have the name wNative
     * it is just a placeholder for wrapped native currency
     * @notice the destination address must have a receive / fallback method
     * to receive native currency
     */
    constructor(
        address payable _destination,
        address payable _wNative,
        uint96 _fee
    ) OracleReader(_wNative, _destination == address(0) ? 0 : _fee) {
        destination = _destination;
    }

    receive() external payable {
        // the protocol thanks you for your donation
        if (destination == address(0)) {
            revert DestinationMissing();
        }
    }

    /**
     * @notice Add new Dex
     * @dev This also generate id of the Dex
     * @param _dexName Name of the Dex
     * @param _router address of the dex router
     */
    function addDex(
        string calldata _dexName,
        address _router
    ) external payable onlyOwner {
        uint256 id = dexInfo.length;
        dexInfo.push(Dex({
            name: _dexName,
            router: _router,
            id: uint96(id),
            disabled: false
        }));
        if (routerToDex[_router] != 0) {
            revert DexConflict(routerToDex[_router]);
        }
        routerToDex[_router] = dexInfo.length;
        emit AddDex(msg.sender, id);
    }

    /**
     * Updates dex info
     * @param id the id to update in dexInfo array
     * @param _name pass anything other than an empty string to update the name
     * @notice _factory is not used in these contracts
     * it is held for external services to utilize
     */
    function updateDex(
        uint256 id,
        string memory _name
    ) external payable onlyOwner {
        if (bytes(_name).length == 0) {
            return;
        }
        dexInfo[id].name = _name;
        emit UpdateDex(msg.sender, id);
    }

    /**
     * sets disabled flag on a dex
     * @param id the dex id to disable
     * @param disabled the boolean denoting whether to disable or enable
     */
    function disableDex(uint256 id, bool disabled) external payable onlyOwner {
        if (dexInfo[id].disabled == disabled) {
            return;
        }
        dexInfo[id].disabled = disabled;
        emit UpdateDex(msg.sender, id);
    }

    /**
     * adjust the tolerance of a particular token's fees
     * @param token the token to adjust the fee tolerance for
     * @param _feeNumerator the numerator to adjust the fee tolerance for (denominator 10_000)
     */
    function updateTokenFee(address token, uint256 _feeNumerator) external payable onlyOwner {
        if (feeNumerator[token] == _feeNumerator) {
            return;
        }
        feeNumerator[token] = _feeNumerator;
        emit UpdateTokenFee(token, _feeNumerator);
    }

    /**
     * distributes all fees, after withdrawing wrapped native balance
     * @notice if the amount is 0, all funds will be drained
     * @notice if an amount is provided, the method will only unwrap
     * the wNative token if it does not have enough native balance to cover the amount
     * @notice the balance will change in the middle of the function
     * if the appropriate conditions are met. however, we do not use that updated balance
     * because the whole amount may not have been asked for
     */
    function distributeAll(uint256 amount) external payable {
        (uint256 nativeBalance, uint256 wNativeBalance) = pendingDistributionSegmented();
        if ((amount == 0 || nativeBalance < amount) && wNativeBalance > 0) {
            IWETH(wNative).withdraw(wNativeBalance);
        }
        amount = clamp(amount, nativeBalance + wNativeBalance);
        if (amount == 0) {
            return;
        }
        destination.sendValue(amount);
    }
    /**
     * A public method to distribute fees
     * @param amount the amount of ether to distribute
     * @notice failure in receipt will cause this tx to fail as well
     */
    function distribute(uint256 amount) external payable {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            return;
        }
        destination.sendValue(clamp(amount, balance));
    }

    /**
     * returns the balance in wNative token and native token as two separate numbers
     */
    function pendingDistributionSegmented() public view returns(uint256, uint256) {
        return (address(this).balance, IWETH(wNative).balanceOf(address(this)));
    }

    /**
     * returns the balance of wNative token and native token,
     * treating them as an aggregate balance for ease
     */
    function pendingDistribution() public view returns(uint256) {
        (uint256 nativeBalance, uint256 wNativeBalance) = pendingDistributionSegmented();
        return nativeBalance + wNativeBalance;
    }

    /**
     * this method transfers funds from the sending address
     * and returns the delta of the balance of this contracat
     * @param sourceTokenId is the token id to transfer from the sender
     * @param amountIn is the amount that you desire to transfer from the sender
     * @return delta the amount that was actually transferred, using a `balanceOf` check
     */
    function collectFunds(address sourceTokenId, uint256 amountIn) internal returns(uint256) {
        address self = address(this);
        uint256 balanceBefore = IERC20(sourceTokenId).balanceOf(self);
        IERC20(sourceTokenId).safeTransferFrom(_msgSender(), self, amountIn);
        return IERC20(sourceTokenId).balanceOf(self) - balanceBefore;
    }

    /**
     * @notice Swap erc20 token, end with erc20 token
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     * @notice anyone using this method will be costing themselves more
     * than simply going through the router they wish to swap through
     * so anything that comes through really acts like a high yeilding voluntary donation box
     * @notice if wNative is passed in as the first or last step of the path
     * then fees will be calculated from that number available at that time
     * @notice fee is only paid via msg.value if and only if the
     * first and last of the path are not a wrapped token
     * @notice if first or last of the path is wNative
     * then msg.value is required to be zero
     */
    function swapTokenV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        address first = _path[0];
        address last = _path[_path.length - 1];
        address _wNative = wNative;
        uint256 nativeFee = 0;
        if (first == _wNative) {
            nativeFee = (_amountIn * fee) / feeDenominator;
            if (msg.value != 0) {
                revert FeeMissing(0, msg.value, "fees paid from input");
            }
        } else if (last != _wNative && fee > 0) {
            (address targetToken, uint256 minimum) = getFeeMinimum(
                IUniswapV2Router02(dexInfo[_dexId].router).factory(),
                _amountIn,
                _path
            );
            // introduce fee tolerance here
            uint256 numerator = feeNumerator[targetToken];
            numerator = numerator == 0 ? 9_000 : numerator;
            minimum = (minimum * numerator) / 10_000;
            if (minimum == 0) {
                revert FeeMissing(0, msg.value, "unable to compute fees");
            }
            if (msg.value < minimum) {
                revert FeeMissing(minimum, msg.value, "not enough fee value");
            }
        }
        // run transfer as normal
        uint256 actualAmountIn = collectFunds(first, _amountIn) - nativeFee;
        uint256 actualAmountOut = swapExactTokenForTokenV2(
            _dexId,
            _path,
            actualAmountIn,
            _minAmountOut,
            _deadline
        );
        uint256 actualAmountOutAfterFees = actualAmountOut;
        if (last == _wNative) {
            actualAmountOutAfterFees -= (actualAmountOut * fee) / feeDenominator;
            if (fee != 0 && msg.value != 0) {
                revert FeeMissing(0, msg.value, "fees paid from output");
            }
        }
        IERC20(last).safeTransfer(recipient, actualAmountOutAfterFees);
    }

    /**
     * @notice Swap native currency, end with erc20 token
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     * @notice this method does not require an approval step from the user
     */
    function swapNativeToV2(
        uint256 _dexId,
        address recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        uint256 minimal = (msg.value * fee) / feeDenominator;
        address payable _wNative = wNative;
        if (msg.value != _amountIn + minimal) {
            revert FeeMissing(_amountIn + minimal, msg.value, "amount + fees must = total");
        }
        if (_path[0] != _wNative) {
            revert NativeMissing(0);
        }
        // convert native to wNative
        IWETH(_wNative).deposit{value: _amountIn}();
        uint256 actualAmountOut = swapExactTokenForTokenV2(_dexId, _path, _amountIn, _minAmountOut, _deadline);
        IERC20(_path[_path.length - 1]).safeTransfer(recipient, actualAmountOut);
    }

    /**
     * @notice Swap ERC-20 Token, end with native currency
     * @param _dexId ID of the Dex
     * @param recipient address to receive funds
     * @param _path Token address array
     * @param _amountIn Input amount
     * @param _minAmountOut Output token amount
     * @param _deadline the time at which this transaction can no longer be run
     * @notice anything extra in msg.value is treated as a donation
     */
    function swapToNativeV2(
        uint256 _dexId,
        address payable recipient,
        address[] calldata _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _deadline
    ) external payable {
        address payable _wNative = wNative;
        if (_path[_path.length - 1] != _wNative) {
            revert NativeMissing(_path.length - 1);
        }
        uint256 actualAmountIn = collectFunds(_path[0], _amountIn);
        uint256 actualAmountOut = swapExactTokenForTokenV2(_dexId, _path, actualAmountIn, _minAmountOut, _deadline);
        uint256 minimal = (actualAmountOut * fee) / feeDenominator;
        uint256 actualAmountOutAfterFee = actualAmountOut - minimal;
        if (actualAmountOut > 0) {
            IWETH(_wNative).withdraw(actualAmountOut);
        }
        recipient.sendValue(actualAmountOutAfterFee);
    }

    function swapExactTokenForTokenV2(
        uint256 dexId,
        address[] calldata _path,
        uint256 _amountIn, // this value has been checked
        uint256 _minAmountOut, // this value will be met
        uint256 _deadline
    ) internal returns (uint256) {
        address router = dexInfo[dexId].router;
        address last = _path[_path.length - 1];
        // approve router to swap tokens
        IERC20(_path[0]).approve(router, _amountIn);
        // call to swap exact tokens
        uint256 balanceBefore = IERC20(last).balanceOf(address(this));
        IUniswapV2Router02(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amountIn,
            _minAmountOut,
            _path,
            address(this),
            _deadline
        );
        return IERC20(last).balanceOf(address(this)) - balanceBefore;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Migratable is Ownable {
    address[] public migrationAddresses;
    event UpdateMigrationAddresses(address indexed executor, address[] addresses);
    function setMigrationAddress(address[] calldata _migrationAddresses) external onlyOwner {
        migrationAddresses = _migrationAddresses;
        emit UpdateMigrationAddresses(_msgSender(), _migrationAddresses);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

abstract contract OracleReader {
    using Address for address;
    // fee = 0.729% Fee
    uint256 public constant feeDenominator = 100_000;
    uint256 public immutable fee;
    /**
     * the native address to deposit and withdraw from in the swap methods
     * @notice this address cannot be updated after it is set during constructor
     */
    address payable public immutable wNative;
    constructor(address payable _wNative, uint96 _fee) {
        wNative = _wNative;
        fee = _fee;
    }
    /**
     * checks the exchange factory pair for a pair with weth and its reserves
     * @param factory the factory to check for a pair and fee of the market
     * @param _amountIn the amount to simulate trading through the market
     * @param path the tokens being traded from and to
     */
    function getFeeMinimum(
        address factory,
        uint256 _amountIn,
        address[] calldata path
    ) public view returns(address, uint256) {
        for (uint256 i = 0; i < path.length; ++i) {
            address target = path[i];
            uint256 minimum = getSingleFeeMinimum(factory, _amountIn, target);
            if (minimum > 0) {
                return (target, minimum);
            }
            if (i != path.length - 1) {
                _amountIn = amountOutFrom(factory, target, path[i + 1], _amountIn);
            }
        }
        return (address(0), 0);
    }

    /**
     * get the amount out from reserves
     * does not take into account fees charged along the way
     * @param factory the factory to derive a pair against
     * @param tokenIn the token being pushed into the pair
     * @param tokenOut the token to be pulled out
     * @param amountIn the magnitude of the swap
     */
    function amountOutFrom(address factory, address tokenIn, address tokenOut, uint256 amountIn) public view returns(uint256) {
        address pair = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        bool inIs0 = IUniswapV2Pair(pair).token0() == tokenIn;
        (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(pair).getReserves();
        if (inIs0) {
            return (reserveB * amountIn) / reserveA;
        }
        return (reserveA * amountIn) / reserveB;
    }

    /**
     * gets the fee for a single token from the exchange factory pair
     * @param factory the factory to check for a pair
     * @param _amountIn the amount of tokens being moved through the market
     * @param source the token to check against wNative
     * @notice the number returned from this method does not check
     * the fee for the market so the calculation will be off by ~0.3% for most markets
     */
    function getSingleFeeMinimum(
        address factory,
        uint256 _amountIn,
        address source
    ) public view returns(uint256 minimum) {
        (uint256 tokenAmount, uint256 wethAmount) = checkPairForValidPrice(factory, source);
        if (wethAmount > 1 ether) {
            return (_amountIn * wethAmount * fee) / (feeDenominator * tokenAmount);
        }
    }

    /**
     * pull a token and weth reserve out of a provided token and factory to derive a market
     * @param factory the address of the factory to derive a pair from (token + wNative)
     * @param token the token to derive against a wNative token
     * @return tokenReserve the amount of token in reserve
     * @return wethReserve the amount of weth in reserve
     */
    function checkPairForValidPrice(address factory, address token) public view returns(uint256 tokenReserve, uint256 wethReserve) {
        IUniswapV2Factory uniFactory = IUniswapV2Factory(factory);
        address _wNative = wNative;
        address pair = uniFactory.getPair(token, _wNative);
        if (pair.isContract()) {
            (uint256 _reserveA, uint256 _reserveB, ) = IUniswapV2Pair(pair).getReserves();
            address token0 = IUniswapV2Pair(pair).token0();
            bool zeroIsWeth = token0 == _wNative;
            tokenReserve = zeroIsWeth ? _reserveB : _reserveA;
            wethReserve = zeroIsWeth ? _reserveA : _reserveB;
        }
        // weth is always returned as denominator
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract Utils {
    /** clamp the amount provided to a maximum, defaulting to provided maximum if 0 provided */
    function clamp(uint256 amount, uint256 max) pure public returns(uint256) {
        uint256 min = amount < max ? amount : max;
        return min == 0 ? max : min;
    }
}