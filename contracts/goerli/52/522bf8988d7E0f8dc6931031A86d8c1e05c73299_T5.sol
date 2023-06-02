/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: EtherFork_flattened.sol




// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol


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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol


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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol


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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


pragma solidity >=0.6.2;


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
    require(success, errorMessage);
    return returndata;
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
    return Address.functionStaticCall(target, data, errorMessage);
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
    return Address.functionDelegateCall(target, data, errorMessage);
}

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResult1(
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
        // The code below is unreachable. No need to return anything after a revert.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}



/*
Yo fam, We created this token to give you a shot at financial freedom, 
but let's keep it real, there are risks in this game. 
Crypto is a wild ride, but here to help you up your hustle, volatility can be crazy, 
build community, stay strong and don't get lazy. 
Protect your gains and remember that family is more important than anything you can do here.  
Do your due diligence and chase that paper responsibly, Embrace the risks, 
but don't lose sight of the opportunities. 
Best of luck to you.

Here's a list of Libraries imported above:







input addresses: 

devWallet: 0xcd04505F750112911360779A499adc608E01f30b
deadWallet: 0x000000000000000000000000000000000000dEaD

partnershipTokenAddress BNB Testnet: 0x5e4467517AAc8F89DD3547e7B8FAfB723e270Fd0
V2Router on BNB Testnet: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1

PartnershipTokenAddress on ETH Testnet: 0x96c0ca1a8E9d5903D9d748533A737079308C70A6
V2Router on ETH Testnet: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D


*/

// File: EtherFork.sol

pragma solidity ^0.8.18;

contract T5 is ERC20, Ownable {
    using Address for address;
    using SafeERC20 for IERC20;

    uint256 private constant MAX_TAX_PERCENTAGE = 10; // 10% represented as percentage
    uint256 private constant MAX_WALLET_LIMIT_PERCENTAGE = 2; // 2% represented as percentage
    uint256 private constant PARTNERSHIP_TOKEN_HOLD_THRESHOLD = 5; // 5% represented as percentage
    
    uint256 private _lastTokenValueUpdateTime = 0;
    uint256 private constant TOKEN_VALUE_UPDATE_INTERVAL = 24 hours;
    uint256 private _tokenValueOfETH = 0;

    uint256 private _totalBurnedTokens;
    uint256 private _burnedTokensLast24Hours;
    uint256 private _burnStartTime;

    uint256 private _gasFee;
    uint256 private _triggerPercent = 10;

    struct TaxRates {
        uint256 devTaxPercentage;
        uint256 partnershipBuyBackAndBurnTaxPercentage;
        uint256 tokenBurnTaxPercentage;
    }

    struct Addresses {
        address devWallet;
        address deadWallet;
        address partnershipTokenAddress;
    }

    TaxRates private _buyTaxRates;
    TaxRates private _sellTaxRates;
    Addresses private _addresses;

    mapping(address => bool) private _whitelist; // Whitelist of addresses excluded from fees
    mapping(address => uint256) private _balances;
    

    mapping(address => bool) private _isExcludedFromMaxWalletLimit; // Addresses excluded from max wallet limit
    uint256 private _maxWalletLimit; // Maximum wallet limit

    address private _owner;
    address private _partnershipTokenAddress;

    IUniswapV2Router02 private _uniswapV2Router; // Uniswap router instance
    address private _uniswapV2Pair; // Uniswap pair address

    // Tax fee balances
    uint256 private _devTaxBalance;
    uint256 private _partnershipBuyBackAndBurnTaxBalance;
    uint256 private _tokenBurnTaxBalance;
    uint256 private _burnTaxBalance;

    bool private _tradingEnabled; // Flag to indicate if trading is enabled

    string private _website;
    string private _twitter;
    string private _telegram;
    string private _basedDevMessage;

    modifier tradingEnabled() {
        require(_tradingEnabled, "Trading is not enabled");
        _;
    }

    event TokensRemoved(address indexed tokenAddress, address indexed recipient, uint256 amount);
    event PreCheckError(address sender, address recipient, uint256 amount);
    event InsufficientGasError(address recipient, uint256 balance, uint256 gasFee);
    event TaxTransferError(uint256 requiredTax, uint256 currentBalance);
    event TransferError(address sender, address recipient, uint256 amount);
    event InsufficientBalanceError(address account, uint256 balance, uint256 requiredAmount);


   constructor(
    uint256 buyDevTaxPercentage,
    uint256 buyPartnershipBuyBackAndBurnTaxPercentage,
    uint256 buyTokenBurnTaxPercentage,

    uint256 sellDevTaxPercentage,
    uint256 sellPartnershipBuyBackAndBurnTaxPercentage,
    uint256 sellTokenBurnTaxPercentage,

    address devWallet,
    address deadWallet,
    address partnershipTokenAddress
) ERC20("Token Five", "T5") {
    require(buyDevTaxPercentage <= MAX_TAX_PERCENTAGE, "Buy dev tax percentage exceeds maximum");
    require(buyPartnershipBuyBackAndBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Buy partnership buyback and burn tax percentage exceeds maximum");
    require(buyTokenBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Buy token burn tax percentage exceeds maximum");
    
    require(sellDevTaxPercentage <= MAX_TAX_PERCENTAGE, "Sell dev tax percentage exceeds maximum");
    require(sellPartnershipBuyBackAndBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Sell partnership buyback and burn tax percentage exceeds maximum");
    require(sellTokenBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Sell token burn tax percentage exceeds maximum");
    
    require(devWallet != address(0), "Invalid dev wallet address");
    require(deadWallet != address(0), "Invalid dead wallet address");
    require(partnershipTokenAddress != address(0), "Invalid partnership token address");

    _buyTaxRates.devTaxPercentage = buyDevTaxPercentage;
    _buyTaxRates.partnershipBuyBackAndBurnTaxPercentage = buyPartnershipBuyBackAndBurnTaxPercentage;
    _buyTaxRates.tokenBurnTaxPercentage = buyTokenBurnTaxPercentage;

    _sellTaxRates.devTaxPercentage = sellDevTaxPercentage;
    _sellTaxRates.partnershipBuyBackAndBurnTaxPercentage = sellPartnershipBuyBackAndBurnTaxPercentage;
    _sellTaxRates.tokenBurnTaxPercentage = sellTokenBurnTaxPercentage;

    _addresses.devWallet = devWallet;
    _addresses.deadWallet = deadWallet;
    _addresses.partnershipTokenAddress = partnershipTokenAddress;



        uint256 totalSupply = 100000000000 * 10**decimals();
        _mint(msg.sender, totalSupply);

        _owner = msg.sender;

        // Exclude owner and contract from fees
        _whitelist[msg.sender] = true;
        _whitelist[address(this)] = true;

        // Create an instance of the Uniswap V2 Router
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        // Set the Uniswap V2 Pair address
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // Exclude Router from fees and max wallet limit
        _whitelist[address(_uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[address(_uniswapV2Router)] = true;

    }

    function setTradingEnabled(bool enabled) external onlyOwner {
        require(!_tradingEnabled, "Trading is already enabled");
        _tradingEnabled = enabled;
    }

    function setBasedDev(string calldata message) external onlyOwner {
        _basedDevMessage = message;
    }

    function BasedDev() public view returns (string memory) {
        return _basedDevMessage;
    }

    function setDYOR(string calldata website, string calldata twitter, string calldata telegram) external onlyOwner {
        _website = website;
        _twitter = twitter;
        _telegram = telegram;
    }

    function DYOR() public view returns (string memory website, string memory twitter, string memory telegram) {
        return (_website, _twitter, _telegram);
    }

    function setBuyTaxRates(
        uint256 devTaxPercentage,
        uint256 partnershipBuyBackAndBurnTaxPercentage,
        uint256 tokenBurnTaxPercentage
        ) external onlyOwner {
        require(devTaxPercentage <= MAX_TAX_PERCENTAGE, "Buy dev tax percentage exceeds maximum");
        require(partnershipBuyBackAndBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Buy partnership buyback and burn tax percentage exceeds maximum");
        require(tokenBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Buy token burn tax percentage exceeds maximum");

        _buyTaxRates.devTaxPercentage = devTaxPercentage;
        _buyTaxRates.partnershipBuyBackAndBurnTaxPercentage = partnershipBuyBackAndBurnTaxPercentage;
        _buyTaxRates.tokenBurnTaxPercentage = tokenBurnTaxPercentage;
    }

    function setSellTaxRates(
        uint256 devTaxPercentage,
        uint256 partnershipBuyBackAndBurnTaxPercentage,
        uint256 tokenBurnTaxPercentage
    ) external onlyOwner {
        require(devTaxPercentage <= MAX_TAX_PERCENTAGE, "Sell dev tax percentage exceeds maximum");
        require(partnershipBuyBackAndBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Sell partnership buyback and burn tax percentage exceeds maximum");
        require(tokenBurnTaxPercentage <= MAX_TAX_PERCENTAGE, "Sell token burn tax percentage exceeds maximum");

        _sellTaxRates.devTaxPercentage = devTaxPercentage;
        _sellTaxRates.partnershipBuyBackAndBurnTaxPercentage = partnershipBuyBackAndBurnTaxPercentage;
        _sellTaxRates.tokenBurnTaxPercentage = tokenBurnTaxPercentage;
    }

    function setAddresses(
        address devWallet,
        address deadWallet,
        address partnershipTokenAddress
    ) external onlyOwner {
        require(devWallet != address(0), "Invalid dev wallet address");
        require(deadWallet != address(0), "Invalid dead wallet address");
        require(partnershipTokenAddress != address(0), "Invalid partnership token address");

        _addresses.devWallet = devWallet;
        _addresses.deadWallet = deadWallet;
        _addresses.partnershipTokenAddress = partnershipTokenAddress;
    }

        function getBuyTaxRates() public view returns (string memory, string memory, uint256, string memory, uint256, string memory, uint256) {
            return ("Buy Tax Rates", "Dev Tax", _buyTaxRates.devTaxPercentage, "Partnership Buyback and Burn Tax", _buyTaxRates.partnershipBuyBackAndBurnTaxPercentage, "Token Burn Tax", _buyTaxRates.tokenBurnTaxPercentage);
        }

        function getSellTaxRates() public view returns (string memory, string memory, uint256, string memory, uint256, string memory, uint256) {
            return ("Sell Tax Rates", "Dev Tax", _sellTaxRates.devTaxPercentage, "Partnership Buyback and Burn Tax", _sellTaxRates.partnershipBuyBackAndBurnTaxPercentage, "Token Burn Tax", _sellTaxRates.tokenBurnTaxPercentage);
        }


        function getAddresses() public view returns (string memory, string memory, address, string memory, address, string memory, address) {
            return ("Addresses", "Dev Wallet", _addresses.devWallet, "Dead Wallet", _addresses.deadWallet, "Partnership Token Address", _addresses.partnershipTokenAddress);
        }

        
        function getBurnedTokens() public view returns (uint256 totalBurned, uint256 burnedLast24Hours) {
            return (_totalBurnedTokens, _burnedTokensLast24Hours);
    
        }

        function getLiquidityPair() external view returns (address) {
            return _uniswapV2Pair;
        }


        function removeTokens(address tokenAddress, uint256 amount) external onlyOwner {
            require(tokenAddress != address(0), "Invalid token address");

            IERC20 token = IERC20(tokenAddress);

            // Check token balance
            uint256 contractTokenBalance = token.balanceOf(address(this));
            require(contractTokenBalance >= amount, "Insufficient token balance");

            // Transfer tokens to the contract owner
            bool success = token.transfer(msg.sender, amount);
            require(success, "Token transfer failed");

            emit TokensRemoved(tokenAddress, msg.sender, amount);
        }


    // Exclude from fees and maxWallet limits
    function whitelistExchange(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
            _isExcludedFromMaxWalletLimit[addresses[i]] = true;
        }
    }

    //Excludes from fees
    function addAddressesToWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            _whitelist[addresses[i]] = false;
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    // Function to get the gas fee
function getGasFee() public view returns (uint256) {
    return _gasFee;
}


function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external payable {
    require(balanceOf(msg.sender) >= tokenAmount, "Not enough tokens in caller's account for liquidity provision");

    transferFrom(msg.sender, address(this), tokenAmount);
    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    uint256 tokenDecimalAdjustment = 10**decimals(); // Adjust according to the number of decimal places in your token
    uint256 ethDecimalAdjustment = 10**18; // Assuming ETH has 18 decimal places

    _uniswapV2Router.addLiquidityETH{value: ethAmount * ethDecimalAdjustment}(
        address(this),
        tokenAmount * tokenDecimalAdjustment,
        0,
        0,
        msg.sender,
        block.timestamp
    );
}

function removeLiquidity(uint256 liquidityAmount) external {
    _approve(address(this), address(_uniswapV2Router), liquidityAmount);

    (uint256 tokenAmount, uint256 ethAmount) = _uniswapV2Router.removeLiquidityETH(
        address(this),
        liquidityAmount,
        0,
        0,
        address(this),
        block.timestamp
    );

    uint256 tokenDecimalAdjustment = 10**decimals(); // Adjust according to the number of decimal places in your token
    uint256 ethDecimalAdjustment = 10**18; // Assuming ETH has 18 decimal places

    transfer(msg.sender, tokenAmount / tokenDecimalAdjustment);
    (bool success,) = msg.sender.call{value: ethAmount / ethDecimalAdjustment}("");
    require(success, "ETH transfer failed");
}



    

    function _isWithinMaxWalletLimit(address recipient, uint256 amount) private view returns (bool) {
    if (
        recipient != address(0) &&
        recipient != address(this) &&
        recipient != _owner &&
        recipient != _addresses.devWallet &&
        recipient != _addresses.deadWallet &&
        recipient != address(_uniswapV2Router) && // Exclude the Uniswap V2 router
        !_isExcludedFromMaxWalletLimit[recipient]
    ) {
        uint256 recipientBalance = balanceOf(recipient);
        uint256 maxWalletLimit = (totalSupply() * 2) / 100;
        if (recipientBalance + amount > maxWalletLimit) {
            return false;
        }
    }

    return true;
}


    function percentChange(uint256 newPercent) public onlyOwner {
    require(newPercent <= 100, "Percent cannot be more than 100");
    _triggerPercent = newPercent;
}

    function _preCheck(address sender, address recipient, uint256 amount) private {
    if (sender == address(0) || recipient == address(0) || amount <= 0 || (!_whitelist[sender] && !_whitelist[recipient] && !_isWithinMaxWalletLimit(recipient, amount))) {
        emit PreCheckError(sender, recipient, amount);
    }
    require(sender != address(0), "Invalid sender");
    require(recipient != address(0), "Invalid recipient");
    require(amount > 0, "Invalid amount");
    if (!_whitelist[sender] && !_whitelist[recipient]) {
        require(_isWithinMaxWalletLimit(recipient, amount), "Exceeds max wallet limit");
    }
}

function _calculateAndApplyTaxes(address sender, address recipient, uint256 amount) private returns (uint256) {
    uint256 devTaxAmount = 0;
    uint256 partnershipBuyBackAndBurnTaxAmount = 0;
    uint256 burnTaxAmount = 0;

    if (!_whitelist[sender] && !_whitelist[recipient]) {
        TaxRates memory taxRates;
        bool isSell;

        if (recipient == address(_uniswapV2Router) || recipient == _uniswapV2Pair) {
            // Sell transaction
            taxRates = _sellTaxRates;
            isSell = true;
        } else {
            // Buy transaction
            taxRates = _buyTaxRates;
            isSell = false;
        }

        devTaxAmount = (amount * taxRates.devTaxPercentage) / (MAX_TAX_PERCENTAGE * 100);
        partnershipBuyBackAndBurnTaxAmount = (amount * taxRates.partnershipBuyBackAndBurnTaxPercentage) / (MAX_TAX_PERCENTAGE * 100);
        burnTaxAmount = (amount * taxRates.tokenBurnTaxPercentage) / (MAX_TAX_PERCENTAGE * 100);
    }
    
    uint256 transferAmount = amount - (devTaxAmount + partnershipBuyBackAndBurnTaxAmount + burnTaxAmount);

    _devTaxBalance += devTaxAmount;
    _partnershipBuyBackAndBurnTaxBalance += partnershipBuyBackAndBurnTaxAmount;
    _burnTaxBalance += burnTaxAmount;

    return transferAmount;
}

function _deductGasFees(address recipient, bool isSell) private {
    if (isSell) {
        uint256 gasFee = getGasFee();
        if (_balances[recipient] < gasFee || gasFee > _balances[recipient] * 75 / 1000) {
            emit InsufficientGasError(recipient, _balances[recipient], gasFee);
        }
        require(_balances[recipient] >= gasFee && gasFee <= _balances[recipient] * 75 / 1000, "Insufficient balance or gas fee too high");
        _balances[recipient] -= gasFee;
        _balances[address(this)] += gasFee;
    }
}

function _transferTaxes(address sender) private {
    uint256 totalTax = _devTaxBalance + _partnershipBuyBackAndBurnTaxBalance + _burnTaxBalance;
    if (totalTax > _balances[sender]) {
        emit TaxTransferError(totalTax, _balances[sender]);
    }
    require(_balances[sender] >= totalTax, "Insufficient balance to transfer tax");
    super._transfer(sender, address(this), totalTax);
}

function _checkAndConvertTaxes() private {
    uint256 totalTaxBalance = _devTaxBalance + _partnershipBuyBackAndBurnTaxBalance + _burnTaxBalance;

    // Total Tax Fee Check
    if (totalTaxBalance >= (tokenValueOfETH() * _triggerPercent / 100)) {
        _convertAndSend();
    }
}

function _transfer(address sender, address recipient, uint256 amount) internal virtual override {
    _preCheck(sender, recipient, amount);
    uint256 transferAmount = _calculateAndApplyTaxes(sender, recipient, amount);
    _deductGasFees(recipient, (recipient == address(_uniswapV2Router) || recipient == _uniswapV2Pair));
    _transferTaxes(sender);
    _checkAndConvertTaxes();
    super._transfer(sender, recipient, transferAmount);
}

    function burn(uint256 amount) external {
        _transfer(msg.sender, _addresses.deadWallet, amount * 1e18);
    }


    function _burnTokens(address token, uint256 amount) private {
    _transfer(address(this), _addresses.deadWallet, amount);
    emit Transfer(address(this), _addresses.deadWallet, amount);

    // Update the total burned tokens
    _totalBurnedTokens += amount;

    // Check if the 24-hour period has elapsed since the last burn
    if (block.timestamp >= _burnStartTime + 1 days) {
        _burnedTokensLast24Hours = amount;
        _burnStartTime = block.timestamp;
    } else {
        _burnedTokensLast24Hours += amount;
    }

    // If the token is EtherFork itself, update the token value of ETH
    if (token == address(this)) {
        tokenValueOfETH();
    }
}


    function _convertAndSend() private {
    // Convert devTax to ETH and send to dev wallet
    _swapTokensForETH(_devTaxBalance, _addresses.devWallet);
    _devTaxBalance = 0;

    // Convert partnershipBuyBackAndBurnTax to ETH, use it to buy partnership tokens, and send them to deadWallet
    _swapTokensForETH(_partnershipBuyBackAndBurnTaxBalance, address(this));
    _partnershipBuyBackAndBurnTaxBalance = 0;
    _swapETHForPartnershipTokens(address(this).balance);
    _transfer(address(this), _addresses.deadWallet, balanceOf(_addresses.partnershipTokenAddress));

    // Burn burnTax by sending it to the deadWallet
    _burnTokens(address(this), _burnTaxBalance);
    _burnTaxBalance = 0;

    }

    function manualConvert() external onlyOwner {
    // Perform the swap even if the gas fees are high
    _swapTokensForETHOverride(_devTaxBalance, _addresses.devWallet);
    _devTaxBalance = 0;

    // Convert partnershipBuyBackAndBurnTax to ETH, use it to buy partnership tokens, and send them to deadWallet
    _swapTokensForETHOverride(_partnershipBuyBackAndBurnTaxBalance, address(this));
    _partnershipBuyBackAndBurnTaxBalance = 0;
    _swapETHForPartnershipTokens(address(this).balance);
    _transfer(address(this), _addresses.deadWallet, balanceOf(_addresses.partnershipTokenAddress));

    // Burn burnTax by sending it to the deadWallet
    _burnTokens(address(this), _burnTaxBalance);
    _burnTaxBalance = 0;
}

function _swapTokensForETHOverride(uint256 tokenAmount, address to) private {
    // Generate the Uniswap pair path of token -> WETH.
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _uniswapV2Router.WETH();

    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    // Perform the token to ETH swap
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // Accept any amount of ETH.
        path,
        address(this),
        block.timestamp
    );

    // Transfer the received ETH to the specified address
    (bool success, ) = to.call{value: address(this).balance}("");
    require(success, "ETH transfer failed");

    // Check if there are any remaining tokens and transfer them to the specified address
    uint256 remainingTokenBalance = balanceOf(address(this));
    if (remainingTokenBalance > 0) {
        _transfer(address(this), to, remainingTokenBalance);
    }
}


    function _swapTokensForETH(uint256 tokenAmount, address /* to */) private returns (uint256) {
    uint256 gasStart = gasleft();  // Get gas remaining before the swap

    // Generate the Uniswap pair path of token -> WETH.
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _uniswapV2Router.WETH();

    _approve(address(this), address(_uniswapV2Router), tokenAmount);

    // Perform the token to ETH swap
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        tokenAmount,
        0, // Accept any amount of ETH.
        path,
        address(this),
        block.timestamp
    );

    uint256 gasEnd = gasleft();    // Get gas remaining after the swap
    uint256 gasFee = gasStart - gasEnd;  // Calculate the gas fee

    _gasFee = gasFee; // Assign the gas fee to the storage variable

    return gasFee;
}


    function _swapETHForPartnershipTokens(uint256 ethAmount) private {
    // Define the path for the swap as ETH -> Partnership token.
    address[] memory path = new address[](2);
    path[0] = _uniswapV2Router.WETH();
    path[1] = _partnershipTokenAddress;

    // Calculate the amount to hold on the contract
    uint256 amountToHold = (ethAmount * 2) / 100;

    // Hold the amount on the contract
    (bool success, ) = address(this).call{value: amountToHold}("");
    require(success, "ETH hold failed");

    // Calculate the remaining amount to swap
    uint256 remainingAmount = ethAmount - amountToHold;

    // Perform the swap
    _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: remainingAmount}(
        0, // Accept any amount of tokens.
        path,
        address(this),
        block.timestamp
    );
}


    function _updateTokenValueOfETH() private {
        require(block.timestamp >= _lastTokenValueUpdateTime + TOKEN_VALUE_UPDATE_INTERVAL, "Token value update interval has not elapsed");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        uint256[] memory amounts = _uniswapV2Router.getAmountsOut(1e18, path); // Get the value of 1 token in ETH
        _tokenValueOfETH = amounts[1];

        _lastTokenValueUpdateTime = block.timestamp;
    }

    function tokenValueOfETH() public returns (uint256) {
        if (block.timestamp >= _lastTokenValueUpdateTime + TOKEN_VALUE_UPDATE_INTERVAL) {
            _updateTokenValueOfETH();
        }
        return _tokenValueOfETH;
    }

    // Fallback function to receive Ether
    receive() external payable {}

    // Function to receive ERC20 tokens
    function receiveToken(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    // Function to transfer ERC20 tokens from the contract
    function transferToken(address token, address recipient, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(recipient, amount);
    }

    // Get the path for swapping ETH to partnership tokens
    function _getETHToPartnershipTokenPath() private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = _addresses.partnershipTokenAddress;
        return path;
    }


}