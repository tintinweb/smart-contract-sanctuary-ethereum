/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/adapters/UniswapAdapter.sol
// SPDX-License-Identifier: MIT AND GPL-3.0-or-later
pragma solidity =0.8.11 >=0.8.0 <0.9.0 >=0.8.1 <0.9.0;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

////// lib/openzeppelin-contracts/contracts/utils/Address.sol
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

/* pragma solidity ^0.8.1; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

/* pragma solidity ^0.8.0; */

/* import "../IERC20.sol"; */
/* import "../../../utils/Address.sol"; */

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

////// src/interfaces/IUniswapAdapterCaller.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap Adapter Caller Interface
 * @author bayu (github.com/pyk)
 * @notice Contract that interact with Uniswap Adapter should implement this interface.
 */
interface IUniswapAdapterCaller {
    /**
     * @notice Function that will be executed by Uniswap Adapter to finish the flash swap.
     *         The caller will receive _amountOut of the specified tokenOut.
     * @param _wethAmount The amount of WETH that the caller need to send back to the Uniswap Adapter
     * @param _amountOut The amount of of tokenOut transfered to the caller.
     * @param _data Data passed by the caller.
     */
    function onFlashSwapWETHForExactTokens(uint256 _wethAmount, uint256 _amountOut, bytes calldata _data) external;
}

////// src/interfaces/IUniswapV2Pair.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V2 Pair Interface
 * @author bayu (github.com/pyk)
 */
interface IUniswapV2Pair {
    function token1() external view returns (address);
    function token0() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

////// src/interfaces/IUniswapV3Pool.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V3 Pool Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IUniswapV3Pool {
    /// @notice Docs: https://docs.uniswap.org/protocol/reference/core/UniswapV3Pool#swap
    function swap(address _recipient, bool _zeroForOne, int256 _amountSpecified, uint160 _sqrtPriceLimitX96, bytes memory _data) external returns (int256 amount0, int256 amount1);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
}

////// src/interfaces/IUniswapAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

/* import { IUniswapV2Pair } from "../interfaces/IUniswapV2Pair.sol"; */
/* import { IUniswapV3Pool } from "../interfaces/IUniswapV3Pool.sol"; */
/* import { IUniswapAdapterCaller } from "../interfaces/IUniswapAdapterCaller.sol"; */

/**
 * @title Uniswap Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Utility contract to interact with Uniswap V2 & V3
 */
interface IUniswapAdapter {
    /// ███ Types ██████████████████████████████████████████████████████████████

    /**
     * @notice The supported Uniswap version
     */
    enum UniswapVersion {
        UniswapV2,
        UniswapV3
    }

    /**
     * @notice Liquidity data for specified token
     * @param version The address of Rise Token
     * @param pair The Uniswap V2 pair address
     * @param pool The Uniswap V3 pool address
     * @param router The Uniswap router address
     */
    struct LiquidityData {
        UniswapVersion version;
        IUniswapV2Pair pair;
        IUniswapV3Pool pool;
        address router;
    }

    /**
     * @notice Parameters to do flash swap WETH->tokenOut
     * @param tokenOut The output token
     * @param caller The flash swap caller
     * @param liquidityData Liquidi
     * @param amountOut The amount of tokenOut that will be received by
     *        this contract
     * @param wethAmount The amount of WETH required to finish the flash swap
     */
    struct FlashSwapWETHForExactTokensParams {
        IERC20 tokenOut;
        IUniswapAdapterCaller caller;
        LiquidityData liquidityData;
        uint256 amountOut;
        uint256 wethAmount;
    }

    /// @notice Flash swap types
    enum FlashSwapType {
        FlashSwapWETHForExactTokens
    }


    /// ███ Events █████████████████████████████████████████████████████████████

    /**
     * @notice Event emitted when token is configured
     * @param liquidityData The liquidity data of the token
     */
    event TokenConfigured(LiquidityData liquidityData);

    /**
     * @notice Event emitted when flash swap succeeded
     * @param params The flash swap params
     */
    event FlashSwapped(FlashSwapWETHForExactTokensParams params);


    /// ███ Errors █████████████████████████████████████████████████████████████

    /// @notice Error is raised when owner use invalid uniswap version
    error InvalidUniswapVersion(uint8 version);

    /// @notice Error is raised when invalid amount
    error InvalidAmount(uint256 amount);

    /// @notice Error is raised when token is not configured
    error TokenNotConfigured(address token);

    /// @notice Error is raised when the callback is called by unkown pair/pool
    error CallerNotAuthorized();

    /// @notice Error is raised when the caller not repay the token
    error CallerNotRepay();

    /// @notice Error is raised when this contract receive invalid amount when flashswap
    error FlashSwapReceivedAmountInvalid(uint256 expected, uint256 got);


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /**
     * @notice Configure the token
     * @param _token The ERC20 token
     * @param _version The Uniswap version (2 or 3)
     * @param _pairOrPool The contract address of the TOKEN/ETH pair or pool
     * @param _router The Uniswap V2 or V3 router address
     */
    function configure(
        address _token,
        UniswapVersion _version,
        address _pairOrPool,
        address _router
    ) external;


    /// ███ Read-only functions ████████████████████████████████████████████████

    /**
     * @notice Returns true if token is configured
     * @param _token The token address
     */
    function isConfigured(address _token) external view returns (bool);

    /// ███ Adapters ███████████████████████████████████████████████████████████

    /**
     * @notice Borrow exact amount of tokenOut and repay it with WETH.
     *         The Uniswap Adapter will call msg.sender#onFlashSwapWETHForExactTokens.
     * @param _tokenOut The address of ERC20 that swapped
     * @param _amountOut The exact amount of tokenOut that will be received by the caller
     */
    function flashSwapWETHForExactTokens(
        address _tokenOut,
        uint256 _amountOut,
        bytes memory _data
    ) external;

    /**
     * @notice Swaps an exact amount of input tokenIn for as many WETH as possible
     * @param _tokenIn tokenIn address
     * @param _amountIn The amount of tokenIn
     * @param _amountOutMin The minimum amount of WETH to be received
     * @return _amountOut The WETH amount received
     */
    function swapExactTokensForWETH(
        address _tokenIn,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256 _amountOut);

    /**
     * @notice Swaps an exact amount of WETH for as few tokenIn as possible.
     * @param _tokenIn tokenIn address
     * @param _wethAmount The amount of tokenIn
     * @param _amountInMax The minimum amount of WETH to be received
     * @return _amountIn The WETH amount received
     */
    function swapTokensForExactWETH(
        address _tokenIn,
        uint256 _wethAmount,
        uint256 _amountInMax
    ) external returns (uint256 _amountIn);

    /**
     * @notice Swaps an exact amount of WETH for tokenOut
     * @param _tokenOut tokenOut address
     * @param _wethAmount The amount of WETH
     * @param _amountOutMin The minimum amount of WETH to be received
     * @return _amountOut The WETH amount received
     */
    function swapExactWETHForTokens(
        address _tokenOut,
        uint256 _wethAmount,
        uint256 _amountOutMin
    ) external returns (uint256 _amountOut);

}

////// src/interfaces/IUniswapV2Router02.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V2 Router Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

////// src/interfaces/IUniswapV3SwapRouter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/**
 * @title Uniswap V3 Swap Router Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */

interface IUniswapV3SwapRouter {
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
    function exactInputSingle(ExactInputSingleParams memory params) external returns (uint256 amountOut);
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
    function exactOutputSingle(ExactOutputSingleParams memory params) external returns (uint256 amountIn);
}

////// src/interfaces/IWETH9.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */

/**
 * @title WETH Interface
 * @author bayu <[email protected]> <https://github.com/pyk>
 */
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

////// src/adapters/UniswapAdapter.sol
/* pragma solidity 0.8.11; */
/* pragma experimental ABIEncoderV2; */

/* import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol"; */
/* import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol"; */
/* import { SafeERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol"; */

/* import { IUniswapAdapter } from "../interfaces/IUniswapAdapter.sol"; */
/* import { IUniswapV2Router02 } from "../interfaces/IUniswapV2Router02.sol"; */
/* import { IUniswapV2Pair } from "../interfaces/IUniswapV2Pair.sol"; */
/* import { IUniswapV3Pool } from "../interfaces/IUniswapV3Pool.sol"; */
/* import { IUniswapV3SwapRouter } from "../interfaces/IUniswapV3SwapRouter.sol"; */
/* import { IUniswapAdapterCaller } from "../interfaces/IUniswapAdapterCaller.sol"; */

/* import { IWETH9 } from "../interfaces/IWETH9.sol"; */

/**
 * @title Uniswap Adapter
 * @author bayu <[email protected]> <https://github.com/pyk>
 * @notice Utility contract to interact with Uniswap V2 & V3
 */
contract UniswapAdapter is IUniswapAdapter, Ownable {
    /// ███ Libraries ██████████████████████████████████████████████████████████

    using SafeERC20 for IERC20;
    using SafeERC20 for IWETH9;

    /// ███ Storages ███████████████████████████████████████████████████████████

    /// @notice WETH address
    IWETH9 public weth;

    /// @notice Mapping token to their liquidity metadata
    mapping(address => LiquidityData) public liquidities;

    /// @notice Whitelisted pair/pool that can call the callback
    mapping(address => bool) private isValidCallbackCaller;


    /// ███ Constuctors ████████████████████████████████████████████████████████

    constructor(address _weth) {
        weth = IWETH9(_weth);
    }


    /// ███ Owner actions ██████████████████████████████████████████████████████

    /// @inheritdoc IUniswapAdapter
    function configure(address _token, UniswapVersion _version, address _pairOrPool, address _router) external onlyOwner {
        isValidCallbackCaller[_pairOrPool] = true;
        liquidities[_token] = LiquidityData({
            version: _version,
            pool: IUniswapV3Pool(_pairOrPool),
            pair: IUniswapV2Pair(_pairOrPool),
            router: _router
        });
        emit TokenConfigured(liquidities[_token]);
    }


    /// ███ Internal functions █████████████████████████████████████████████████

    /// @notice Executed when flashSwapWETHForExactTokens is triggered
    function onFlashSwapWETHForExactTokens(FlashSwapWETHForExactTokensParams memory _params, bytes memory _data) internal {
        // Transfer the tokenOut to caller
        _params.tokenOut.safeTransfer(address(_params.caller), _params.amountOut);

        // Execute the callback
        uint256 prevBalance = weth.balanceOf(address(this));
        _params.caller.onFlashSwapWETHForExactTokens(_params.wethAmount, _params.amountOut, _data);
        uint256 balance = weth.balanceOf(address(this));

        // Check the balance
        if (balance < prevBalance + _params.wethAmount) revert CallerNotRepay();

        // Transfer the WETH to the Uniswap V2 pair or pool
        if (_params.liquidityData.version == UniswapVersion.UniswapV2) {
            weth.safeTransfer(address(_params.liquidityData.pair), _params.wethAmount);
        } else {
            weth.safeTransfer(address(_params.liquidityData.pool), _params.wethAmount);
        }

        emit FlashSwapped(_params);
    }


    /// ███ Callbacks ██████████████████████████████████████████████████████████

    function uniswapV2Call(address _sender, uint256 _amount0, uint256 _amount1, bytes memory _data) external {
        /// ███ Checks

        // Check caller
        if (!isValidCallbackCaller[msg.sender]) revert CallerNotAuthorized();
        if (_sender != address(this)) revert CallerNotAuthorized();

        /// ███ Interactions

        // Get the data
        (FlashSwapType flashSwapType, bytes memory data) = abi.decode(_data, (FlashSwapType, bytes));

        // Continue execute the function based on the flash swap type
        if (flashSwapType == FlashSwapType.FlashSwapWETHForExactTokens) {
            (FlashSwapWETHForExactTokensParams memory params, bytes memory callData) = abi.decode(data, (FlashSwapWETHForExactTokensParams,bytes));
            // Check the amount out
            uint256 amountOut = _amount0 == 0 ? _amount1 : _amount0;
            if (params.amountOut != amountOut) revert FlashSwapReceivedAmountInvalid(params.amountOut, amountOut);

            // Calculate the WETH amount
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(params.tokenOut);
            params.wethAmount = IUniswapV2Router02(params.liquidityData.router).getAmountsIn(params.amountOut, path)[0];

            onFlashSwapWETHForExactTokens(params, callData);
            return;
        }
    }

    function uniswapV3SwapCallback(int256 _amount0Delta, int256 _amount1Delta, bytes memory _data) external {
        /// ███ Checks

        // Check caller
        if (!isValidCallbackCaller[msg.sender]) revert CallerNotAuthorized();

        /// ███ Interactions

        // Get the data
        (FlashSwapType flashSwapType, bytes memory data) = abi.decode(_data, (FlashSwapType, bytes));

        // Continue execute the function based on the flash swap type
        if (flashSwapType == FlashSwapType.FlashSwapWETHForExactTokens) {
            (FlashSwapWETHForExactTokensParams memory params, bytes memory callData) = abi.decode(data, (FlashSwapWETHForExactTokensParams,bytes));

            // if amount negative then it must be the amountOut, otherwise it's weth amount
            uint256 amountOut = _amount0Delta < 0 ?  uint256(-1 * _amount0Delta) : uint256(-1 * _amount1Delta);
            params.wethAmount = _amount0Delta > 0 ? uint256(_amount0Delta) : uint256(_amount1Delta);

            // Check the amount out
            if (params.amountOut != amountOut) revert FlashSwapReceivedAmountInvalid(params.amountOut, amountOut);

            onFlashSwapWETHForExactTokens(params, callData);
            return;
        }
    }


    /// ███ Read-only functions ████████████████████████████████████████████████

    /// @inheritdoc IUniswapAdapter
    function isConfigured(address _token) public view returns (bool) {
        if (liquidities[_token].router == address(0)) return false;
        return true;
    }

    /// ███ Adapters ███████████████████████████████████████████████████████████

    /// @inheritdoc IUniswapAdapter
    function flashSwapWETHForExactTokens(address _tokenOut, uint256 _amountOut, bytes memory _data) external {
        /// ███ Checks
        if (_amountOut == 0) revert InvalidAmount(0);
        if (!isConfigured(_tokenOut)) revert TokenNotConfigured(_tokenOut);

        // Check the metadata
        LiquidityData memory metadata = liquidities[_tokenOut];

        /// ███ Interactions

        // Initialize the params
        FlashSwapWETHForExactTokensParams memory params = FlashSwapWETHForExactTokensParams({
            tokenOut: IERC20(_tokenOut),
            amountOut: _amountOut,
            caller: IUniswapAdapterCaller(msg.sender),
            liquidityData: metadata,
            wethAmount: 0 // Initialize as zero; It will be updated in the callback
        });
        bytes memory data = abi.encode(FlashSwapType.FlashSwapWETHForExactTokens, abi.encode(params, _data));

        // Flash swap Uniswap V2; The pair address will call uniswapV2Callback function
        if (metadata.version == UniswapVersion.UniswapV2) {
            // Get amountOut for token and weth
            uint256 amount0Out = _tokenOut == metadata.pair.token0() ? _amountOut : 0;
            uint256 amount1Out = _tokenOut == metadata.pair.token1() ? _amountOut : 0;

            // Do the flash swap
            metadata.pair.swap(amount0Out, amount1Out, address(this), data);
            return;
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // zeroForOne (true: token0 -> token1) (false: token1 -> token0)
            bool zeroForOne = _tokenOut == metadata.pool.token1() ? true : false;

            // amountSpecified (Exact input: positive) (Exact output: negative)
            int256 amountSpecified = -1 * int256(_amountOut);
            uint160 sqrtPriceLimitX96 = (zeroForOne ? 4295128740 : 1461446703485210103287273052203988822378723970341);

            // Perform swap
            metadata.pool.swap(address(this), zeroForOne, amountSpecified, sqrtPriceLimitX96, data);
            return;
        }
    }

    /// @inheritdoc IUniswapAdapter
    function swapExactTokensForWETH(address _tokenIn, uint256 _amountIn, uint256 _amountOutMin) external returns (uint256 _amountOut) {
        /// ███ Checks
        if (!isConfigured(_tokenIn)) revert TokenNotConfigured(_tokenIn);

        /// ███ Interactions
        LiquidityData memory metadata = liquidities[_tokenIn];
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        IERC20(_tokenIn).safeIncreaseAllowance(metadata.router, _amountIn);

        if (metadata.version == UniswapVersion.UniswapV2) {
            // Do the swap
            address[] memory path = new address[](2);
            path[0] = _tokenIn;
            path[1] = address(weth);
            _amountOut = IUniswapV2Router02(metadata.router).swapExactTokensForTokens(_amountIn, _amountOutMin, path, msg.sender, block.timestamp)[1];
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // Do the swap
            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: address(weth),
                fee: metadata.pool.fee(),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });
            _amountOut = IUniswapV3SwapRouter(metadata.router).exactInputSingle(params);
        }

        return _amountOut;
    }

    /// @inheritdoc IUniswapAdapter
    function swapTokensForExactWETH(address _tokenIn, uint256 _wethAmount, uint256 _amountInMax) external returns (uint256 _amountIn) {
        /// ███ Checks
        if (!isConfigured(_tokenIn)) revert TokenNotConfigured(_tokenIn);

        /// ███ Interactions
        LiquidityData memory metadata = liquidities[_tokenIn];
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountInMax);
        IERC20(_tokenIn).safeIncreaseAllowance(metadata.router, _amountInMax);

        if (metadata.version == UniswapVersion.UniswapV2) {
            // Do the swap
            address[] memory path = new address[](2);
            path[0] = _tokenIn;
            path[1] = address(weth);
            _amountIn = IUniswapV2Router02(metadata.router).swapTokensForExactTokens(_wethAmount, _amountInMax, path, msg.sender, block.timestamp)[1];
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // Do the swap
            IUniswapV3SwapRouter.ExactOutputSingleParams memory params = IUniswapV3SwapRouter.ExactOutputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: address(weth),
                fee: metadata.pool.fee(),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: _wethAmount,
                amountInMaximum: _amountInMax,
                sqrtPriceLimitX96: 0
            });
            _amountIn = IUniswapV3SwapRouter(metadata.router).exactOutputSingle(params);
        }

        if (_amountInMax > _amountIn) {
            // Transfer back excess token
            IERC20(_tokenIn).safeTransfer(msg.sender, _amountInMax - _amountIn);
        }
        return _amountIn;
    }

    /// @inheritdoc IUniswapAdapter
    function swapExactWETHForTokens(address _tokenOut, uint256 _wethAmount, uint256 _amountOutMin) external returns (uint256 _amountOut) {
        /// ███ Checks
        if (!isConfigured(_tokenOut)) revert TokenNotConfigured(_tokenOut);

        /// ███ Interactions
        LiquidityData memory metadata = liquidities[_tokenOut];
        IERC20(address(weth)).safeTransferFrom(msg.sender, address(this), _wethAmount);
        weth.safeIncreaseAllowance(metadata.router, _wethAmount);

        if (metadata.version == UniswapVersion.UniswapV2) {
            // Do the swap
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = _tokenOut;
            _amountOut = IUniswapV2Router02(metadata.router).swapExactTokensForTokens(_wethAmount, _amountOutMin, path, msg.sender, block.timestamp)[1];
        }

        if (metadata.version == UniswapVersion.UniswapV3) {
            // Do the swap
            IUniswapV3SwapRouter.ExactInputSingleParams memory params = IUniswapV3SwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: _tokenOut,
                fee: metadata.pool.fee(),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: _wethAmount,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });
            _amountOut = IUniswapV3SwapRouter(metadata.router).exactInputSingle(params);
        }

        return _amountOut;
    }
}