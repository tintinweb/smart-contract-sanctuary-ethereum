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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IMasterPool {
    struct AuctionInfo {
        uint256 auctionAmount;
        uint256 stakeDuration;
        bool claimed;
    }

    struct StakingPool {
        address staker;
        uint256 stakeAmount;
        uint256 stakeDuration;
        uint256 stakeTimestamp;
        bool claimed;
    }

    struct PendingRewards {
        uint256 claimableRewards;
        uint256 stakableRewards;
        uint256 dividendsRewards;
    }

    struct UserInfo {
        uint256 dividendsRewards;
        uint256 totalBidAmount;
        mapping(uint256 => uint256) bidAmountPerAuction;
        mapping(uint256 => uint256) stakeDuration;
        uint256 totalStakedAmount;
    }

    struct StakingHistory {
        uint256 stakingId;
        uint256 stakeAmount;
        uint256 leftDuration;
        uint256 totalDuration;
        bool finished;
    }

    struct AuctionHistory {
        uint256 auctionId;
        uint256 tokenXPool;
        uint256 totalBUSDDividens;
        uint256 totalBidAmount;
        uint256 bidAmount;
        uint256 stakeDuration;
        uint256 participantsCnt;
        uint256 auctionPrice;
        bool claimed;
        bool finished;
    }

    event Auction(address indexed user, uint256 amount, uint256 stakeDuration);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITokenX is IERC20 {
    function mint(
        address account_,
        uint256 amount_
    ) external;

    function burn(uint256 amount_) external;

    function leftDays() external view returns (uint256);

    function launchedAt() external view returns (uint256);
    
    function supplyAmount(uint256 auctionId) external pure returns (uint256);

    function getLiquidAmount() external view returns (uint256);

    function getLiquidAmount(address user_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ITokenX.sol";
import "./interfaces/IMasterPool.sol";
import "./interfaces/IUniswapV2Router02.sol";

contract MasterPool is IMasterPool, Ownable {
    using SafeERC20 for IERC20;

    ITokenX private tokenX;
    IERC20 private BUSD;
    bool private isLock;
    uint256 private stakingId;
    address private devWallet;

    IUniswapV2Router02 public router;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 constant AUCTION_PERIOD = 100;
    uint256 constant STAKE_MIN_PERIOD = 100;

    uint256 constant PERCENT_FOR_AUCTION = 97;  // 97%
    uint256 constant PERCENT_FOR_BUYBAK = 1;    // 1%
    uint256 constant PERCENT_FOR_DEV = 1;       // 1%
    uint256 constant PERCENT_FOR_LIQUIDITY = 1; // 1%

    mapping(uint256 => StakingPool) private stakingPools;
    mapping(uint256 => uint256) private totalAuctioned;
    mapping(address => uint256) private lastAuctionIds;
    mapping(uint256 => uint256) private totalAuctionStaked;
    mapping(address => uint256) private lastClaimDividensIds;
    mapping(address => PendingRewards) private pendingRewards;
    mapping(uint256 => mapping(address => AuctionInfo)) private auctionInfos;
    mapping(uint256 => address[]) private auctionStakers;
    mapping(address => UserInfo) private userInfos;

    uint256 private totalStakedAmount;

    modifier lock() {
        require (isLock == false, "locked");
        isLock = true;
        _;
        isLock = false;
    }

    constructor (
        address routerAddress_,
        address devWallet_,
        address pairTokenAddress_
    ) {
        BUSD = IERC20(pairTokenAddress_);
        isLock = false;
        router = IUniswapV2Router02(routerAddress_);
        devWallet = devWallet_;
    }

    /// @notice Set tokenX address
    /// @dev Onlyowner can call this function.
    /// @dev After call this function, ownership will go to DEAD wallet to burn owner key.
    /// @param tokenAddress_ The address of tokenX.
    function setTokenAddress(address tokenAddress_) external onlyOwner {
        tokenX = ITokenX(tokenAddress_);
        _transferOwnership(DEAD);
    }

    /// @notice Users attend to acution with BUSD token.
    /// @dev Explain to a developer any extra details
    /// @param auctionAmount_ The amount of BUSD to attend to auction.
    /// @param stakeDuration_ The duration for stake.
    function auction(
        uint256 auctionAmount_,
        uint256 stakeDuration_
    ) external lock {
        address sender = msg.sender;
        uint256 auctionId = tokenX.leftDays();
        AuctionInfo storage auctionInfo = auctionInfos[auctionId][sender];
        require (sender != address(0), "zero address");
        require (auctionId < AUCTION_PERIOD, "auction finished");
        require (auctionInfo.auctionAmount == 0, "already acutioned");
        require (stakeDuration_ <= 1000 && stakeDuration_ % STAKE_MIN_PERIOD == 0, "invalid stake duration");

        BUSD.safeTransferFrom(sender, address(this), auctionAmount_);
        
        auctionInfo.auctionAmount = auctionAmount_;
        auctionInfo.stakeDuration = stakeDuration_;
        lastAuctionIds[sender] = auctionId;
        auctionStakers[auctionId].push(sender);
        totalAuctioned[auctionId] += auctionAmount_;
        userInfos[sender].totalBidAmount += auctionAmount_;
        userInfos[sender].bidAmountPerAuction[auctionId] += auctionAmount_;
        userInfos[sender].stakeDuration[auctionId] = stakeDuration_;

        _actionForTokenX(auctionAmount_);

        emit Auction(sender, auctionAmount_, stakeDuration_);
    }

    /// @notice Claim rewards from auction.
    /// @dev Reverts tx if no rewards for a user.
    function claimAuctionRewards(
        uint256 auctionId_
    ) external {
        address sender = msg.sender;
        require (sender != address(0), "invalid user");
        uint256 curAuctionId = tokenX.leftDays();
        require (auctionId_ < curAuctionId, "auction is not finished");

        AuctionInfo memory auctionInfo = auctionInfos[auctionId_][sender];
        uint256 totalAuctionedAmount = totalAuctioned[auctionId_];
        uint256 auctionedAmount = auctionInfo.auctionAmount;
        uint256 supplyAmount = tokenX.supplyAmount(auctionId_);
        uint256 rewards = totalAuctionedAmount == 0 ? 0 : supplyAmount * auctionedAmount / totalAuctionedAmount;

        require (rewards > 0, "no rewards");

        if (auctionInfo.stakeDuration > 0) {
            _stake(sender, rewards, auctionInfo.stakeDuration);
        } else {
            tokenX.mint(sender, rewards);    
        }        
    }

    function getAuctionReward(
        uint256 auctionId_
    ) public view returns (uint256) {
        address sender = msg.sender;
        // require (sender != address(0), "invalid user");
        uint256 curAuctionId = tokenX.leftDays();
        // require (auctionId_ < curAuctionId, "auction is not finished");
        if (auctionId_ >= curAuctionId) return 0;
        
        AuctionInfo memory auctionInfo = auctionInfos[auctionId_][sender];
        uint256 totalAuctionedAmount = totalAuctioned[auctionId_];
        uint256 auctionedAmount = auctionInfo.auctionAmount;
        uint256 supplyAmount = tokenX.supplyAmount(auctionId_);
        uint256 rewards = totalAuctionedAmount == 0 ? 0 : supplyAmount * auctionedAmount / totalAuctionedAmount;
        return rewards;
    }

    /// @notice Get claimable dividends BUSD amount.
    /// @param account_ The addres of a user.
    /// @return Return claimable dividends BUSD amount.
    function claimableDividendsRewards(
        address account_
    ) public view returns (uint256) {
        require (account_ != address(0), "zero address");
        
        uint256 auctionId = tokenX.leftDays();
        uint256 lastAuctionId = lastAuctionIds[account_];
        uint256 lastDividensClaimId = lastClaimDividensIds[account_];
        if (
            auctionId == 0 ||
            lastAuctionId == 0 ||
            lastAuctionId == lastDividensClaimId
        ) {
            return 0;
        }
        
        uint256 rewards = 0;
        lastAuctionId = auctionId == lastAuctionId ? lastAuctionId - 1 : lastAuctionId;

        for (uint256 id = lastDividensClaimId; id <= lastAuctionId; id ++) {
            rewards += _getClaimableDividendsBUSD(account_, id);
        }

        return rewards;
    }

    function claimDividendsRewards() external {
        address sender = msg.sender;
        require (sender != address(0), "zero address");

        uint256 rewards = claimableDividendsRewards(sender);
        require (rewards > 0, "no rewards");

        userInfos[sender].dividendsRewards += rewards;
        lastClaimDividensIds[sender] = lastAuctionIds[sender];

        BUSD.safeTransfer(sender, rewards);
    }

    /// @notice Stake tokenX to staking pool.
    /// @param amount_ The amount of tokenX for staking.
    /// @param duration_ The duration of timestamp for staking.
    function stake(
        uint256 amount_,
        uint256 duration_
    ) external {
        address sender = msg.sender;
        require (sender != address(0), "zero address");
        require (
            duration_ % STAKE_MIN_PERIOD == 0 && 
            duration_ / STAKE_MIN_PERIOD >= 1, 
            "invalid duration"
        );
        require (amount_ > 0, "invalid amount");
        _stake(sender, amount_, duration_);

        IERC20(address(tokenX)).safeTransferFrom(sender, address(this), amount_);
    }

    /// @notice Let users to get origin amount of tokenX and rewards from staking pool.
    /// @param stakingId_ The ID of staking pool.
    function unstake(
        uint256 stakingId_
    ) external {
        StakingPool memory pool = stakingPools[stakingId_];
        address sender = msg.sender;
        require (sender != address(0), "zero address");
        require (pool.staker != address(0), "no such pool");
        
        uint256 unlockTime = pool.stakeDuration * 1 days + pool.stakeTimestamp;
        require (unlockTime <= block.timestamp, "in staking duration");

        _unstake(sender, stakingId_);
    }

    function getUserStakingState(
        address user_
    ) external view returns (
        uint256 userBalance,
        uint256 stakedAmount,
        uint256 totalAmount,
        StakingHistory[] memory stakingHistory
    ) {
        require (user_ != address(0), "zero address");
        userBalance = tokenX.balanceOf(user_);
        stakedAmount = userInfos[user_].totalStakedAmount;
        totalAmount = userBalance + stakedAmount;

        if (totalAmount == 0) {
            stakingHistory = new StakingHistory[](0);
        } else {
            StakingHistory[] memory history = new StakingHistory[](stakingId);
            uint256 index = 0;
            for (uint256 i = 0; i < stakingId; i ++) {
                if (stakingPools[i].staker == user_ && stakingPools[i].claimed == false) {
                    StakingPool memory stakingPool = stakingPools[i];
                    uint256 leftDuration = (block.timestamp - stakingPool.stakeTimestamp);
                    leftDuration = leftDuration / 1 days >= stakingPool.stakeDuration ? stakingPool.stakeDuration : leftDuration / 1 days;
                    history[index ++] = StakingHistory({
                        stakingId: i,
                        stakeAmount: stakingPool.stakeAmount,
                        leftDuration: leftDuration,
                        totalDuration: stakingPool.stakeDuration,
                        finished: leftDuration == stakingPool.stakeDuration
                    });
                }
            }

            stakingHistory = new StakingHistory[](index);
            for (uint256 i = 0; i < index; i ++) {
                stakingHistory[i] = history[i];
            }
        }
    }

    function getAuctionRewardsState(
        address user_
    ) external view returns (
        uint256 claimableAmount,
        uint256 claimedAmount,
        uint256 supplyAmount,
        uint256 stakedAmount,
        uint256 liquidAmount,
        uint256 userLiquid
    ) {
        require (user_ != address(0), "zero address");
        // global state
        supplyAmount = tokenX.totalSupply();
        stakedAmount = totalStakedAmount;
        liquidAmount = tokenX.getLiquidAmount();

        // personal state. 
        claimableAmount = claimableDividendsRewards(user_);
        claimedAmount = userInfos[user_].dividendsRewards;
        userLiquid = tokenX.getLiquidAmount(user_);
    }

    function getGlobalAuctionState() external view returns (
        uint256 auctionDay,
        uint256 remainAuctionDay,
        uint256 todayTokenXPool,
        uint256 todayBUSDPool,
        uint256 todayParticipants,
        uint256 curAuctionPrice,
        uint256 totalBUSDDividens
    ) {
        uint256 auctionId = tokenX.leftDays();

        if (auctionId > 99) {
            auctionDay = 100;
            remainAuctionDay = 0;
            todayTokenXPool = 0;
            todayBUSDPool = 0;
            todayParticipants = 0;
            curAuctionPrice = 0;
            totalBUSDDividens = 0;
        } else {
            auctionDay = auctionId + 1;
            remainAuctionDay = 100 - auctionDay;
            todayTokenXPool = tokenX.supplyAmount(auctionId);
            todayBUSDPool = totalAuctioned[auctionId];
            todayParticipants = auctionStakers[auctionId].length;
            curAuctionPrice = todayTokenXPool == 0 ? 0 : todayBUSDPool * 1e18 / todayTokenXPool;
            totalBUSDDividens = auctionId == 0 ? 0 : totalAuctioned[auctionId - 1] * PERCENT_FOR_AUCTION / 100;
        }
    }

    function getUserAuctionState(address user_) external view returns (
        uint256 myAuctionBidToday,
        uint256 myTotalAuctionBid,
        uint256 myBUSDDividens,
        AuctionHistory[] memory auctionHistory
    ) {
        require (user_ != address(0), "zero user address");
        address account = user_;

        uint256 auctionId = tokenX.leftDays();
        myTotalAuctionBid = userInfos[account].totalBidAmount;
        myAuctionBidToday = auctionId > 99 ? 0 : userInfos[account].bidAmountPerAuction[auctionId];    

        auctionId = auctionId > 99 ? 100 : auctionId;
        for (uint256 i = 0; i < auctionId; i ++) {
            myBUSDDividens += _getClaimableDividendsBUSD(account, i);
        }

        auctionHistory = new AuctionHistory[](auctionId == 100 ? 100 : auctionId);
        for (uint256 i = 0; i < auctionId; i ++) {
            uint256 totalAmount = totalAuctioned[i];
            uint256 tokenXPool = tokenX.supplyAmount(i);
            uint256 auctionPrice = tokenXPool == 0 ? 0 : totalAmount * 1e18 / tokenXPool;
            auctionHistory[i] = AuctionHistory({
                auctionId: i,
                tokenXPool: tokenXPool,
                totalBUSDDividens: i == 0 ? 0 : totalAuctioned[i - 1] * PERCENT_FOR_AUCTION / 100,
                totalBidAmount: totalAmount,
                bidAmount: userInfos[account].bidAmountPerAuction[i],
                stakeDuration: userInfos[account].stakeDuration[i],
                participantsCnt: auctionStakers[i].length,
                auctionPrice: auctionPrice,
                claimed: auctionInfos[i][account].claimed,
                finished: (i < auctionId)
            });
        }
    }

    /// @notice Stake amount to staking pool.
    /// @param account_ The address of staker.
    /// @param amount_ Staking amount.
    /// @param duration_ Staking duration.
    function _stake(
        address account_,
        uint256 amount_,
        uint256 duration_
    ) internal {
        stakingPools[stakingId ++] = StakingPool({
            staker: account_,
            stakeAmount: amount_,
            stakeDuration: duration_,
            stakeTimestamp: block.timestamp,
            claimed: false
        });

        userInfos[account_].totalStakedAmount += amount_;
        totalStakedAmount += amount_;
    }

    /// @notice Unstake staking pool.
    /// @param account_ The address of a user.
    /// @param stakingId_ The staking pool ID.
    function _unstake(
        address account_,
        uint256 stakingId_
    ) internal {
        StakingPool storage pool = stakingPools[stakingId_];
        uint256 rewards = (pool.stakeDuration / STAKE_MIN_PERIOD) * pool.stakeAmount;
        tokenX.mint(account_, rewards);
        userInfos[account_].totalStakedAmount -= pool.stakeAmount;
        totalStakedAmount -= pool.stakeAmount;
        pool.claimed = true;
        IERC20(address(tokenX)).safeTransfer(account_, pool.stakeAmount);
        
        delete stakingPools[stakingId_];
    }

    /// @notice Get BUSD amount can be claim.
    /// @param account_ The address of a user.
    /// @param auctionId_ The Id of a auction.
    /// @return Return BUSD amount can be claim.
    function _getClaimableDividendsBUSD(
        address account_,
        uint256 auctionId_
    ) internal view returns (uint256) {
        if (auctionId_ == 0 || auctionId_ > 99) {
            return 0;
        }
        uint256 totalAmount = totalAuctioned[auctionId_ - 1];
        if (totalAmount == 0) {
            return 0;
        }

        if (userInfos[account_].bidAmountPerAuction[auctionId_] == 0) {
            return 0;
        }

        uint256 stakerLength = auctionStakers[auctionId_].length;
        if (stakerLength == 0) {
            return 0;
        }

        uint256 amountForAuction = totalAmount * PERCENT_FOR_AUCTION / 100;
        (uint256 stakableRewards, ) = _calcRewards(account_, auctionId_);
        uint256 total = _getTotalAuctionStakedAmount(auctionId_);

        return total == 0 ? 0 : amountForAuction * stakableRewards / total;
    }

    /// @notice Calculate stakable rewards and claimable rewards by auctionId.
    /// @param account_ The address of a user.
    /// @param auctionId_ The ID of auction.
    /// @return Return stakable rewards and claimable rewards.
    function _calcRewards(
        address account_,
        uint256 auctionId_
    ) internal view returns (uint256, uint256) {
        AuctionInfo memory auctionInfo = auctionInfos[auctionId_][account_];
        uint256 totalAuctionedAmount = totalAuctioned[auctionId_];
        uint256 auctionedAmount = auctionInfo.auctionAmount;
        uint256 supplyAmount = tokenX.supplyAmount(auctionId_);
        uint256 rewards = totalAuctionedAmount == 0 ? 0 : supplyAmount * auctionedAmount / totalAuctionedAmount;
        uint256 stakableRewards = 0;
        uint256 claimableRewards = 0;

        if (auctionInfo.stakeDuration > 0) {
            stakableRewards += rewards;
        } else {
            claimableRewards += rewards;
        }

        return (stakableRewards, claimableRewards);
    }

    /// @notice Get total staked amount.
    /// @param auctionId_ The ID of a auction.
    /// @return Return total staked amount.
    function _getTotalAuctionStakedAmount(
        uint256 auctionId_
    ) internal view returns (uint256) {
        uint256 stakerCnt = auctionStakers[auctionId_].length;
        uint256 total = 0;
        for (uint256 i = 0; i < stakerCnt; i ++) {
            address staker = auctionStakers[auctionId_][i];
            (uint256 rewards, ) = _calcRewards(staker, auctionId_);
            total += rewards;
        }

        return total;
    }

    /// @notice Divide BUSD amount for tokenX.
    /// @dev 10% for dev, 5% for buyback, and 5% for liquidity.
    /// @param auctionAmount_ The amount of BUSD attended to daily auction.
    function _actionForTokenX(
        uint256 auctionAmount_
    ) internal {
        _addliquidity(auctionAmount_);
        _buyBack(auctionAmount_);
        uint256 amountForDev = auctionAmount_ * PERCENT_FOR_DEV / 100;
        if (amountForDev > 0) {
            BUSD.safeTransfer(devWallet, amountForDev);
        }
    }

    /// @notice Add liquidity to keep price of tokenX.
    /// @dev Using 5% of BUSD attended to auction, add liquidity to keept price of tokenX.
    /// @param auctionAmount_ The amount of BUSD attented to daily auction
    function _addliquidity(
        uint256 auctionAmount_
    ) internal {
        uint256 amountForLiquidity = auctionAmount_ * PERCENT_FOR_LIQUIDITY / 100;
        address[] memory path = new address[](2);
        path[0] = address(BUSD);
        path[1] = address(tokenX);
        uint256[] memory amounts = router.getAmountsOut(
            amountForLiquidity, 
            path
        );

        uint256 tokenXAmount = amounts[1];
        require (tokenXAmount > 0, "no liquidity pool");
        tokenX.mint(address(this), tokenXAmount);

        BUSD.approve(address(router), amountForLiquidity);
        tokenX.approve(address(router), tokenXAmount);
        router.addLiquidity(
            address(BUSD), 
            address(tokenX), 
            amountForLiquidity, 
            tokenXAmount, 
            0, 
            0, 
            address(this), 
            block.timestamp
        );
    }

    function _buyBack(
        uint256 auctionAmount_
    ) internal {
        uint256 amountForBuyBack = auctionAmount_ * PERCENT_FOR_LIQUIDITY / 100;
        if (amountForBuyBack == 0) {
            return;
        }
        uint256 beforeBal = tokenX.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = address(BUSD);
        path[1] = address(tokenX);
        BUSD.approve(address(router), amountForBuyBack);
        
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountForBuyBack, 
            0, 
            path, 
            address(this), 
            block.timestamp
        );
        uint256 afterBal = tokenX.balanceOf(address(this));
        uint256 boughtBal = afterBal - beforeBal;
        if (boughtBal > 0) {
            tokenX.burn(boughtBal);
        }
    }
}