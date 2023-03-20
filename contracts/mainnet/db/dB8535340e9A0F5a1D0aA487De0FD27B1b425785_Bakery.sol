/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/*
Cookie Farming Adventure is a decentralized farm running on the Ethereum blockchain,
with lots of features that let you earn and win tokens.

What we are trying to do is to create a game that is reminiscent of the old incremental games,
by including P2E features to mix these two worlds!

Telegram: https://t.me/CookieFarmingAdventure
Twitter: https://twitter.com/CookieFarmAdv
Website: https://cookiefarmingadventure.com/
Whitepaper: https://docs.cookiefarmingadventure.com/cookie-farming-adventure/
*/

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

interface IUniswapV2Router {
  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function factory() external view returns (address);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountsIn(uint256 amountOut, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IToken {
  function burn(address account, uint256 amount) external returns (bool);

  function mint(address account, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function uniswapV2Router() external view returns (address);
}

contract Bakery is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint256 public constant PRECISION = 10**18;
  uint256 public constant BASE_COOKIE_PER_SECOND = 1 * PRECISION;
  uint256 public constant INITIAL_UPGRADE_COST_FLAT = 400_000 * PRECISION;
  uint256 public constant INITIAL_UPGRADE_COST_MULTIPLIER = 600_000 * PRECISION;
  uint256 public constant TOKEN_PER_COOKIE = 1; // 1:1

  uint256 public registerFeePercent = 10;
  uint256 public sellFeePercent = 20;
  uint256 public referralFeePercent = 10;
  uint256 public bakeryListingFeePercent = 10;
  uint256 public bakeryListingIndex = 1;
  uint256 public tokenAmountToRegister = 1_000_000 * 10**18; // 18 decimals token

  address private topCookieFeeder = address(0);
  uint256 private topCookieFeederNbCookiesEaten = 0;
  address private topReferral = address(0);

  address private treasury;

  IToken public token;

  BakeryStats public stats;

  enum UpgradeType {
    Flat,
    Multiplier
  }

  struct BakeryStats {
    uint256 totalCookiesBought;
    uint256 totalCookiesCooked;
    uint256 totalCookiesSpent;
    uint256 totalCookiesSold;
    uint256 totalCookiesEaten;
  }

  struct BakeryLockPlan {
    uint32 duration;
    uint8 percentBonus;
  }

  struct Player {
    uint256 cookieBalance;
    uint8 cookieBonusMultiplier;
    uint256 cookieBonusFlat;
    uint8 cookieBonusLockPercent;
    uint256 totalCookiesCooked;
    uint256 totalCookiesSpent;
    uint256 totalCookiesEaten;
    uint32 lastUpdateTimestamp;
    uint32 bakeryLockedUntilTimestamp;
    uint8 nbFlatUpgrades;
    uint8 nbMultiplierUpgrades;
    address referral;
    uint32 referredCount;
    uint256 totalReferralEarnings;
  }

  struct BakeryListing {
    address seller;
    uint256 price;
  }

  mapping(address => Player) public players;
  mapping(address => uint256) public playerBakeryListingId;
  mapping(uint256 => BakeryListing) public bakeryListings;

  BakeryLockPlan[] public bakeryLockPlans;

  modifier onlyRegisteredPlayer() {
    require(isPlayerRegistered(msg.sender), "You need a Bakery");
    _;
  }

  modifier bakeryNotLocked() {
    require(isBakeryUnlocked(msg.sender), "Bakery is locked");
    _;
  }

  event PlayerRegistered(address indexed player, address indexed referral);
  event PlayerUpdated(address indexed player, uint256 cookieBalance);
  event CookieBought(address indexed player, uint256 cookieAmount);
  event CookieSold(address indexed player, uint256 cookieAmount);
  event ReferralPayment(
    address indexed from,
    address indexed referral,
    uint256 cookieAmount
  );
  event UpgradeBought(
    address indexed player,
    UpgradeType upgradeType,
    uint256 upgradeQty,
    uint256 totalCost
  );
  event CookiesEaten(
    address indexed player,
    uint256 nbCookies,
    uint256 totalCookiesEaten,
    bool isTopCookieFeeder
  );
  event BakeryLocked(address indexed player, uint32 untilTimestamp);
  event BakeryListingCreated(uint256 id, address indexed seller, uint256 price);
  event BakeryListingRemoved(uint256 id, address indexed seller);
  event BakeryListingBought(
    uint256 id,
    address indexed seller,
    address indexed buyer,
    uint256 price
  );

  constructor(address _token, address _treasury) {
    require(BASE_COOKIE_PER_SECOND != 0, "BASE_COOKIE_PER_SECOND must be > 0");
    require(
      INITIAL_UPGRADE_COST_FLAT != 0,
      "INITIAL_UPGRADE_COST_FLAT must be > 0"
    );
    require(
      INITIAL_UPGRADE_COST_MULTIPLIER != 0,
      "INITIAL_UPGRADE_COST_MULTIPLIER must be > 0"
    );
    require(TOKEN_PER_COOKIE != 0, "TOKEN_PER_COOKIE must be > 0");

    treasury = _treasury;

    token = IToken(_token);

    bakeryLockPlans.push(BakeryLockPlan({duration: 1 days, percentBonus: 20}));
    bakeryLockPlans.push(BakeryLockPlan({duration: 3 days, percentBonus: 50}));
    bakeryLockPlans.push(BakeryLockPlan({duration: 7 days, percentBonus: 120}));
  }

  function registerPlayer(address referral) public nonReentrant {
    require(!isPlayerRegistered(msg.sender), "You already own a Bakery");
    require(
      token.balanceOf(msg.sender) >= tokenAmountToRegister,
      "You don't have enough tokens to register"
    );
    require(referral != msg.sender, "You can't refer yourself");
    require(
      referral == address(0) || isPlayerRegistered(referral),
      "Referral is not registered"
    );

    if (referral != address(0)) {
      players[referral].referredCount++;
      if (
        players[referral].referredCount > players[topReferral].referredCount
      ) {
        topReferral = referral;
      }
    }

    players[msg.sender] = Player({
      cookieBalance: 0,
      cookieBonusMultiplier: 0,
      cookieBonusFlat: 0,
      cookieBonusLockPercent: 0,
      lastUpdateTimestamp: uint32(block.timestamp),
      totalCookiesCooked: 0,
      totalCookiesSpent: 0,
      totalCookiesEaten: 0,
      nbFlatUpgrades: 0,
      nbMultiplierUpgrades: 0,
      bakeryLockedUntilTimestamp: 0,
      referral: referral,
      referredCount: 0,
      totalReferralEarnings: 0
    });

    uint256 registerFee = (tokenAmountToRegister * registerFeePercent) / 100;

    emit PlayerRegistered(msg.sender, referral);
    bool success = token.burn(msg.sender, tokenAmountToRegister);
    require(success, "Token burn failed");

    if (registerFee > 0) {
      success = token.mint(address(this), registerFee);
      require(success, "Token mint failed");
      swapTokensForETH(registerFee);
    }
  }

  function buyCookies(uint256 amount) public onlyRegisteredPlayer nonReentrant {
    require(amount != 0, "You must buy at least 1 cookie");

    uint256 cost = amount * TOKEN_PER_COOKIE;

    require(
      token.balanceOf(msg.sender) >= cost,
      "You don't have enough tokens to buy cookies"
    );

    // Update player info before buying cookies to make sure cookieBalance is up to date
    updatePlayerInfo();
    Player storage p = players[msg.sender];

    p.cookieBalance += amount;
    stats.totalCookiesBought += amount;
    emit CookieBought(msg.sender, amount);
    bool success = token.burn(msg.sender, cost);
    require(success, "Token burn failed");
  }

  function sellCookies(uint256 amount)
    public
    onlyRegisteredPlayer
    bakeryNotLocked
    nonReentrant
  {
    require(amount != 0, "You must sell at least 1 cookie");

    // Update player info before selling cookies to make sure cookieBalance is up to date
    updatePlayerInfo();

    Player storage p = players[msg.sender];

    require(p.cookieBalance >= amount, "You don't have enough cookies to sell");
    p.cookieBalance -= amount;

    uint256 cookiesForReferral = (amount * referralFeePercent) / 100;
    uint256 cookiesTaxed = (amount * sellFeePercent) / 100;
    uint256 cookiesToSell = amount - cookiesForReferral - cookiesTaxed;

    if (p.referral != address(0)) {
      players[p.referral].cookieBalance += cookiesForReferral;
      players[p.referral].totalReferralEarnings += cookiesForReferral;
      emit ReferralPayment(msg.sender, p.referral, cookiesForReferral);
    }

    emit CookieSold(msg.sender, amount);
    stats.totalCookiesSold += amount;
    bool success = token.mint(msg.sender, cookiesToSell * TOKEN_PER_COOKIE);
    require(success, "Token mint failed");

    if (cookiesTaxed > 0) {
      // Mint tokens for treasury and swap them for ETH
      // We mint half the amount of tokens for the treasury and half burned
      uint256 tokensToMintForTreasury = (cookiesTaxed * TOKEN_PER_COOKIE) / 2;
      success = token.mint(address(this), tokensToMintForTreasury);
      require(success, "Token mint failed");
      swapTokensForETH(tokensToMintForTreasury);
    }
  }

  function eatCookies(uint256 amount)
    external
    onlyRegisteredPlayer
    nonReentrant
  {
    require(amount != 0, "You must eat at least 1 cookie");

    // Update player info before eating cookies to make sure cookieBalance is up to date
    updatePlayerInfo();

    require(
      getPlayerCookiesAvailable(msg.sender) >= amount,
      "Not enough cookies to eat"
    );

    Player storage p = players[msg.sender];

    p.cookieBalance -= amount;
    p.totalCookiesEaten += amount;
    stats.totalCookiesEaten += amount;

    if (p.totalCookiesEaten > topCookieFeederNbCookiesEaten) {
      topCookieFeeder = msg.sender;
      topCookieFeederNbCookiesEaten = p.totalCookiesEaten;
    }
    emit CookiesEaten(
      msg.sender,
      amount,
      p.totalCookiesEaten,
      msg.sender == topCookieFeeder
    );
  }

  function updatePlayerInfo() public {
    require(isPlayerRegistered(msg.sender), "You need a Bakery");

    Player storage p = players[msg.sender];

    if (p.lastUpdateTimestamp >= block.timestamp) {
      return;
    }

    uint256 cookiesCookedUntilLockEnd = 0;
    uint256 cookiesCooked = getPlayerCookiesCookedSinceTimestamp(
      msg.sender,
      p.lastUpdateTimestamp
    );

    if (isBakeryUnlocked(msg.sender) && p.bakeryLockedUntilTimestamp != 0) {
      // it was locked , so we need to compute the cookies earned until the lock end
      cookiesCookedUntilLockEnd = getPlayerCookiesCookedInSeconds(
        msg.sender,
        p.bakeryLockedUntilTimestamp - p.lastUpdateTimestamp
      );

      // reset the lock bonus because lock is over
      p.cookieBonusLockPercent = 0;

      // We also need to compute the cookies earned since the lock end
      cookiesCooked = getPlayerCookiesCookedSinceTimestamp(
        msg.sender,
        p.bakeryLockedUntilTimestamp
      );
    }

    cookiesCooked += cookiesCookedUntilLockEnd;

    p.cookieBalance += cookiesCooked;
    p.lastUpdateTimestamp = uint32(block.timestamp);
    p.totalCookiesCooked += cookiesCooked;
    stats.totalCookiesCooked += cookiesCooked;
  }

  function isPlayerBakeryForSale(address player) public view returns (bool) {
    return playerBakeryListingId[player] != 0;
  }

  function createBakeryListing(uint256 tokenPrice)
    external
    onlyRegisteredPlayer
    nonReentrant
  {
    require(!isPlayerBakeryForSale(msg.sender), "Bakery already for sale");
    require(tokenPrice != 0, "Price must be > 0");

    uint256 id = bakeryListingIndex;
    bakeryListings[id] = BakeryListing({seller: msg.sender, price: tokenPrice});
    playerBakeryListingId[msg.sender] = id;
    bakeryListingIndex++;

    emit BakeryListingCreated(id, msg.sender, tokenPrice);
  }

  function removeBakeryListing(uint256 listingId)
    external
    onlyRegisteredPlayer
    nonReentrant
  {
    require(bakeryListingExists(listingId), "Listing does not exist");
    require(
      bakeryListings[listingId].seller == msg.sender,
      "Only seller can remove listing"
    );

    delete bakeryListings[listingId];
    delete playerBakeryListingId[msg.sender];

    emit BakeryListingRemoved(listingId, msg.sender);
  }

  function buyBakeryListing(uint256 listingId) external nonReentrant {
    require(
      !isPlayerRegistered(msg.sender),
      "A registered player cannot buy a bakery"
    );
    require(bakeryListingExists(listingId), "Listing does not exist");

    BakeryListing memory listing = bakeryListings[listingId];
    require(
      token.balanceOf(msg.sender) >= listing.price,
      "Not enough tokens to buy the bakery"
    );

    // Remove the listing
    delete bakeryListings[listingId];
    delete playerBakeryListingId[listing.seller];

    // Process the bakery transfer
    players[msg.sender] = players[listing.seller];
    delete players[listing.seller];

    // If the previous owner was the top cookie eater, we need to update it
    if (topCookieFeeder == listing.seller) {
      topCookieFeeder = msg.sender;
    }

    // Payment
    uint256 tokensForTreasury = (listing.price * bakeryListingFeePercent) / 100;
    uint256 tokensForSeller = listing.price - tokensForTreasury;

    // Transfer tokens to seller
    IERC20(address(token)).safeTransferFrom(
      msg.sender,
      listing.seller,
      tokensForSeller
    );

    // Transfer tokens to contract
    IERC20(address(token)).safeTransferFrom(
      msg.sender,
      address(this),
      tokensForTreasury
    );

    // Swap tokens for ETH and send to treasury
    swapTokensForETH(tokensForTreasury);

    emit BakeryListingBought(
      listingId,
      listing.seller,
      msg.sender,
      listing.price
    );
  }

  function swapTokensForETH(uint256 amount) internal {
    IUniswapV2Router router = IUniswapV2Router(token.uniswapV2Router());

    address[] memory path = new address[](2);
    path[0] = address(token);
    path[1] = router.WETH();

    // Swap tokens for ETH and send to treasury
    bool success = IERC20(address(token)).approve(address(router), amount);
    require(success, "Failed to approve token transfer");
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      amount,
      0,
      path,
      treasury,
      block.timestamp + 300
    );
  }

  function bakeryListingExists(uint256 listingId) public view returns (bool) {
    return bakeryListings[listingId].seller != address(0);
  }

  function getBakeryListing(uint256 listingId)
    external
    view
    returns (BakeryListing memory)
  {
    return bakeryListings[listingId];
  }

  function isPlayerRegistered(address player) public view returns (bool) {
    return players[player].lastUpdateTimestamp != 0;
  }

  function getPlayerCookiesAvailable(address player)
    public
    view
    returns (uint256)
  {
    Player memory p = players[player];

    uint256 cookiesCookedUntilLockEnd = 0;
    uint256 cookiesCooked = getPlayerCookiesCookedSinceTimestamp(
      player,
      p.lastUpdateTimestamp
    );

    if (isBakeryUnlocked(player) && p.bakeryLockedUntilTimestamp != 0) {
      // it was locked , so we need to compute the cookies earned until the lock end
      cookiesCookedUntilLockEnd = getPlayerCookiesCookedInSeconds(
        player,
        p.bakeryLockedUntilTimestamp - p.lastUpdateTimestamp
      );

      // reset the lock bonus because lock is over
      p.cookieBonusLockPercent = 0;

      // We also need to compute the cookies earned since the lock end
      cookiesCooked =
        getCookiesPerSecond(p.cookieBonusFlat, p.cookieBonusMultiplier, 0) *
        (block.timestamp - p.bakeryLockedUntilTimestamp);
    }

    return p.cookieBalance + cookiesCooked + cookiesCookedUntilLockEnd;
  }

  function getPlayerCookiesCookedSinceTimestamp(
    address player,
    uint256 timestamp
  ) public view returns (uint256) {
    require(timestamp <= block.timestamp, "Timestamp must be in the past");

    uint256 secondsSinceLastUpdate = block.timestamp - timestamp;
    uint256 cps = getPlayerCookiesCookedInSeconds(
      player,
      secondsSinceLastUpdate
    );
    return cps;
  }

  function getPlayerCookiesCookedInSeconds(
    address player,
    uint256 secondsToEarn
  ) public view returns (uint256) {
    uint256 cps = getPlayerCookiesPerSecond(player);
    return (cps * secondsToEarn);
  }

  function getPlayerCookiesPerSecond(address player)
    public
    view
    returns (uint256)
  {
    if (!isPlayerRegistered(player)) {
      return 0;
    }

    Player memory p = players[player];

    uint256 cps = getCookiesPerSecond(
      p.cookieBonusFlat,
      p.cookieBonusMultiplier,
      p.cookieBonusLockPercent
    );

    return cps;
  }

  function getCookiesPerSecond(
    uint256 cookieBonusFlat,
    uint8 cookieBonusMultiplier,
    uint256 cookieBonusLockPercent
  ) public pure returns (uint256) {
    uint256 cpsWithoutLockBonus = ((PRECISION * 6) / 10) +
      ((PRECISION + (cookieBonusMultiplier * PRECISION * 12) / 10) *
        (PRECISION + (cookieBonusFlat * PRECISION * 8) / 10) *
        (cookieBonusFlat + cookieBonusMultiplier + 1)) /
      (10 * PRECISION);

    uint256 cpsWithLockBonus = (cpsWithoutLockBonus *
      (100 + cookieBonusLockPercent)) / 100;

    return cpsWithLockBonus;
  }

  function lockTheBakery(uint256 planIndex)
    external
    onlyRegisteredPlayer
    nonReentrant
  {
    BakeryLockPlan memory plan = getBakeryLockPlan(planIndex);

    updatePlayerInfo();
    Player storage p = players[msg.sender];

    require(isBakeryUnlocked(msg.sender), "Bakery is already rented");

    p.bakeryLockedUntilTimestamp = uint32(block.timestamp) + plan.duration;
    p.cookieBonusLockPercent = plan.percentBonus;
    emit BakeryLocked(msg.sender, p.bakeryLockedUntilTimestamp);
  }

  function buyUpgrade(UpgradeType upgradeType, uint8 upgradeQty)
    external
    onlyRegisteredPlayer
    nonReentrant
  {
    require(upgradeQty != 0, "Upgrade quantity must be > 0");
    // Update player info before buying the upgrade to make sure cookieBalance is up to date
    updatePlayerInfo();

    uint256 upgradeCost = getPlayerUpgradeCost(
      msg.sender,
      upgradeType,
      upgradeQty
    );

    require(
      getPlayerCookiesAvailable(msg.sender) >= upgradeCost,
      "Not enough cookies to buy this upgrade"
    );

    Player storage p = players[msg.sender];

    p.cookieBalance -= upgradeCost;
    p.totalCookiesSpent += upgradeCost;
    stats.totalCookiesSpent += upgradeCost;

    uint256 nbUpgrades = 0;

    if (upgradeType == UpgradeType.Flat) {
      p.cookieBonusFlat += upgradeQty;
      p.nbFlatUpgrades += upgradeQty;
      nbUpgrades = p.nbFlatUpgrades;
    } else if (upgradeType == UpgradeType.Multiplier) {
      p.cookieBonusMultiplier += upgradeQty;
      p.nbMultiplierUpgrades += upgradeQty;
      nbUpgrades = p.nbMultiplierUpgrades;
    } else {
      revert("Invalid upgrade type");
    }

    emit UpgradeBought(msg.sender, upgradeType, upgradeQty, upgradeCost);
  }

  function getUpgradeCost(uint256 initialUpgradeCost, uint256 nbUpgrades)
    public
    pure
    returns (uint256)
  {
    return initialUpgradeCost * (nbUpgrades + 1);
  }

  function setSellFeePercent(uint256 newSellFeePercent) external onlyOwner {
    require(newSellFeePercent <= 30, "Sell fee percent must be <= 30");
    sellFeePercent = newSellFeePercent;
  }

  function setReferralFeePercent(uint256 newReferralFeePercent)
    external
    onlyOwner
  {
    require(newReferralFeePercent <= 30, "Referral fee percent must be <= 30");
    referralFeePercent = newReferralFeePercent;
  }

  function setRegisterFeePercent(uint256 newRegisterFeePercent)
    external
    onlyOwner
  {
    require(newRegisterFeePercent <= 30, "Register fee percent must be <= 30");
    registerFeePercent = newRegisterFeePercent;
  }

  function setBakeryListingFeePercent(uint256 newBakeryListingFeePercent)
    external
    onlyOwner
  {
    require(
      newBakeryListingFeePercent <= 30,
      "Bakery listing fee percent must be <= 30"
    );
    bakeryListingFeePercent = newBakeryListingFeePercent;
  }

  function setTokenAmountToRegister(uint256 newTokenAmountToRegister)
    external
    onlyOwner
  {
    tokenAmountToRegister = newTokenAmountToRegister;
  }

  function setTreasury(address newTreasury) external onlyOwner {
    treasury = newTreasury;
  }

  function getPlayerInfo(address player) public view returns (Player memory) {
    return players[player];
  }

  function getPlayerUpgradeCost(
    address player,
    UpgradeType upgradeType,
    uint8 upgradeQty
  ) public view returns (uint256) {
    Player memory p = players[player];

    uint256 cost = 0;

    if (upgradeType == UpgradeType.Flat) {
      for (uint8 i = 0; i < upgradeQty; i++) {
        cost += getUpgradeCost(INITIAL_UPGRADE_COST_FLAT, p.nbFlatUpgrades + i);
      }
    } else if (upgradeType == UpgradeType.Multiplier) {
      for (uint8 i = 0; i < upgradeQty; i++) {
        cost += getUpgradeCost(
          INITIAL_UPGRADE_COST_MULTIPLIER,
          p.nbMultiplierUpgrades + i
        );
      }
    } else {
      revert("Invalid upgrade type. Must be Flat or Multiplier");
    }

    assert(cost != 0);
    return cost;
  }

  function getTopCookieFeeder() external view returns (address) {
    return topCookieFeeder;
  }

  function getTopCookieFeederNbCookiesEaten() external view returns (uint256) {
    return topCookieFeederNbCookiesEaten;
  }

  function getBakeryLockPlanLength() public view returns (uint256) {
    return bakeryLockPlans.length;
  }

  function getBakeryLockPlan(uint256 planIndex)
    public
    view
    returns (BakeryLockPlan memory)
  {
    require(
      planIndex < getBakeryLockPlanLength(),
      "Bakery lock plan index out of bounds"
    );
    return bakeryLockPlans[planIndex];
  }

  function getBakeryLockPlans()
    external
    view
    returns (BakeryLockPlan[] memory)
  {
    return bakeryLockPlans;
  }

  function getTopReferral() public view returns (address) {
    return topReferral;
  }

  function getTopReferralReferredCount() public view returns (uint256) {
    return players[topReferral].referredCount;
  }

  function getTopReferralTotalReferralEarnings() public view returns (uint256) {
    return players[topReferral].totalReferralEarnings;
  }

  function isBakeryUnlocked(address player) public view returns (bool) {
    return
      players[player].bakeryLockedUntilTimestamp <= block.timestamp ||
      players[player].bakeryLockedUntilTimestamp == 0;
  }

  function withdrawETH() external onlyOwner {
    (bool success, ) = payable(owner()).call{value: address(this).balance}("");
    require(success, "Withdraw ETH failed");
  }

  function withdrawERC20(address _token) external onlyOwner {
    IERC20 t = IERC20(_token);
    bool success = t.transfer(owner(), t.balanceOf(address(this)));
    require(success, "Withdraw ERC20 failed");
  }

  //TODO: Remove this function
  function getBlockTimestamp() public view returns (uint256) {
    return block.timestamp;
  }
}