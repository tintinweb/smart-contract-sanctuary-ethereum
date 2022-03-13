//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UniswapAdapter {
    // interfaces
    using SafeERC20 for IERC20;

    // EVENTS

    /**
     * Emitted when swap was completed
     * @param to - address of receiver of tokens
     * @param addressArray - array of addresses of pairs
     * @param amountsArray -  array of amounts of tokens
     */
    event Swapped(
        address indexed to,
        address[] addressArray,
        uint256[] amountsArray
    );

    /**
     * Emitted when pair was created
     * @param pair -  address of pair
     * @param tokenOne -  address of first token
     * @param tokenTwo -  address of second token
     */
    event PairCreated(
        address indexed pair,
        address tokenOne,
        address tokenTwo
    );

    /**
     * Emitted when liquidity was added.
     * @param to - address
     * @param amountOne - amount of tokenOne added to pool
     * @param amountTwo - amount of tokenTwo added to pool
     * @param amountLiquidity - amount of liquidity tokens to receive
     */
    event LiquidityProvided(
        address indexed to,
        uint256 amountOne,
        uint256 amountTwo,
        uint256 indexed amountLiquidity
    );
    /**
     * This even emiited when liquidity removed.
     * @param to - address
     * @param amountOne - amount of tokenOne to receive
     * @param amountTwo - amount of tokenTwo to receive
     * @param amountLiquidity amount of liquidity tokens that was send.
     */
    event LiquidityRemoved(
        address indexed to,
        uint256 amountOne,
        uint256 amountTwo,
        uint256 indexed amountLiquidity
    );

    // Uniswap factory address
    address public factoryAddress;

    // Uniswap router address
    address public routerAddress;

    /**
     * Constructor
     * @param _factoryAddress - Uniswap factory address
     * @param _routerAddress - Uniswap router address
     */
    constructor(address _factoryAddress, address _routerAddress) {
        factoryAddress = _factoryAddress;
        routerAddress = _routerAddress;
    }

    /**
     * Function that creates new tokens pair
     * @param tokenOne - address of first token
     * @param tokenTwo - address of second token
     * @return pairAddress - address of pair
     */
    function createPair(address tokenOne, address tokenTwo)
    external
    returns (address)
    {
        address pairAddress = IUniswapV2Factory(factoryAddress).createPair(tokenOne, tokenTwo);
        emit PairCreated(pairAddress, tokenOne, tokenTwo);
        return pairAddress;
    }

    /**
     * View function that returns address of tokens pair
     * @param tokenOne - address of first token
     * @param tokenTwo - address of second token
     * @return pairAddress - address of pair
     */
    function getTokensPair(address tokenOne, address tokenTwo)
    external
    view
    returns (address)
    {
        return IUniswapV2Factory(factoryAddress).getPair(tokenOne, tokenTwo);
    }

    /**
     * View function that returns count of all pairs
     * @return count - count of all pairs
     */
    function allPairsLength() external view returns (uint256) {
        return IUniswapV2Factory(factoryAddress).allPairsLength();
    }

    /**
     * Function that adds some tokens in liquidity pool
     * @param tokenOne - address of first token
     * @param tokenTwo - address of second token
     * @param amountOne - amount of tokenOne that you want to add to pool
     * @param amountTwo - amount of tokenTwo that you want to add to pool
     * @param amountMinOne - minimum amount of tokenOne that you want to add to pool
     * @param amountMinTwo - minimum amount of tokenTwo that you want to add to pool
     * @param to - address that gets liquidity tokens of pair
     * @param timeLimit - the time until which this call remains relevant
     * @return _amountOne - amount of tokenOne that was added to pool
     * @return _amountTwo - amount of tokenTwo that was added to pool
     * @return _liquidityAmount - amount of liquidity tokens that was send at "to" address
     */
    function provideLiquidity(
        address tokenOne,
        address tokenTwo,
        uint256 amountOne,
        uint256 amountTwo,
        uint256 amountMinOne,
        uint256 amountMinTwo,
        address to,
        uint256 timeLimit
    )
    external
    returns (
        uint256 _amountOne,
        uint256 _amountTwo,
        uint256 _liquidityAmount
    )
    {
        IERC20(tokenOne).safeTransferFrom(
            msg.sender,
            address(this),
            amountOne
        );
        IERC20(tokenTwo).safeTransferFrom(
            msg.sender,
            address(this),
            amountTwo
        );

        IERC20(tokenOne).approve(address(routerAddress), amountOne);
        IERC20(tokenTwo).approve(address(routerAddress), amountTwo);

        (_amountOne, _amountTwo, _liquidityAmount) = IUniswapV2Router02(routerAddress).addLiquidity(
            tokenOne,
            tokenTwo,
            amountOne,
            amountTwo,
            amountMinOne,
            amountMinTwo,
            to,
            timeLimit
        );

        if (amountOne > _amountOne) {
            IERC20(tokenOne).safeTransfer(msg.sender, amountOne - _amountOne);
        }
        if (amountTwo > _amountTwo) {
            IERC20(tokenTwo).safeTransfer(msg.sender, amountTwo - _amountTwo);
        }

        emit LiquidityProvided(to, _amountOne, _amountTwo, _liquidityAmount);
    }

    /**
     * Function that removes some tokens from liquidity pool
     * @param tokenOne - address of first token
     * @param tokenTwo - address of second token
     * @param liquidityAmount - amount of liquidity token that you want to send
     * @param amountMinOne - minimum amount of tokenOne that you want to get from pool
     * @param amountMinTwo - minimum amount of tokenTwo that you want to get from pool
     * @param to - address at which we will get tokens from pair
     * @param timeLimit - the time until which this call remains relevant
     * @return _amountOne - amount of tokenOne that "to" address gets
     * @return _amountTwo - amount of tokenTwo that "to" address gets
     */
    function removeLiquidity(
        address tokenOne,
        address tokenTwo,
        uint256 liquidityAmount,
        uint256 amountMinOne,
        uint256 amountMinTwo,
        address to,
        uint256 timeLimit
    ) external returns (uint256 _amountOne, uint256 _amountTwo) {
        address pair = (
            IUniswapV2Factory(factoryAddress).getPair(tokenOne, tokenTwo)
        );
        IERC20(pair).safeTransferFrom(
            msg.sender,
            address(this),
            liquidityAmount
        );

        IERC20(pair).approve(address(routerAddress), liquidityAmount);
        (_amountOne, _amountTwo) = IUniswapV2Router02(routerAddress).removeLiquidity(
            tokenOne,
            tokenTwo,
            liquidityAmount,
            amountMinOne,
            amountMinTwo,
            to,
            timeLimit
        );
        emit LiquidityRemoved(to, _amountOne, _amountTwo, liquidityAmount);
    }

    /**
     * Function that swaps amount of tokenOne for some amount of tokenTwo
     * @param amountOne - amount of tokenOne that you want to swap
     * @param amountTwo - amount of tokenTwo that you want to add send out
     * @param addressesPath -  array of addresses of pairs
     * @param to - address which will gets tokens out by swap
     * @param timeLimit - the time until which this call remains relevant
     * @return _amounts array of amounts of tokens
     */
    function swapExactTokensForTokens(
        uint256 amountOne,
        uint256 amountTwo,
        address[] calldata addressesPath,
        address to,
        uint256 timeLimit
    ) external returns (uint256[] memory _amounts) {
        IERC20(addressesPath[0]).safeTransferFrom(msg.sender, address(this), amountOne);
        IERC20(addressesPath[0]).approve(address(routerAddress), amountOne);

        _amounts = IUniswapV2Router02(routerAddress).swapExactTokensForTokens(
            amountOne,
            amountTwo,
            addressesPath,
            to,
            timeLimit
        );
        emit Swapped(to, addressesPath, _amounts);
    }

    /**
     * Function that swaps amount of tokenOne for some amount of tokenTwo
     * @param amountOut - amount of tokenTwo that you want to get
     * @param amountInMax - max amount of tokenOne that you want to send in
     * @param addressesPath -  array of addresses of pairs
     * @param to - address which will gets tokens out by swap
     * @param timeLimit - the time until which this call remains relevant
     * @return _amounts array of amounts of tokens
     */
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata addressesPath,
        address to,
        uint256 timeLimit
    ) external returns (uint256[] memory _amounts) {
        IERC20(addressesPath[0]).safeTransferFrom(
            msg.sender,
            address(this),
            amountInMax
        );
        IERC20(addressesPath[0]).approve(address(routerAddress), amountInMax);
        _amounts = IUniswapV2Router02(routerAddress).swapTokensForExactTokens(
            amountOut,
            amountInMax,
            addressesPath,
            to,
            timeLimit
        );
        IERC20(addressesPath[0]).safeTransfer(msg.sender, amountInMax - _amounts[0]);
        emit Swapped(to, addressesPath, _amounts);
    }

    /**
     * Returns the maximum output amount of the asset
     * @param amountIn - amount of tokens that we swapping in
     * @param addressesPath -  array of addresses of pairs
     * @return array of amounts of tokens
     */
    function getAmountsOut(uint256 amountIn, address[] calldata addressesPath)
    external
    view
    returns (uint256[] memory)
    {
        return IUniswapV2Router02(routerAddress).getAmountsOut(amountIn, addressesPath);
    }

    /**
     * Returns a required input amount of the asset
     * @param amountOut amount of tokens that we want to receive
     * @param addressesPath -  array of addresses of pairs
     * @return array of amounts of tokens
     */
    function getAmountsIn(uint256 amountOut, address[] calldata addressesPath)
    external
    view
    returns (uint256[] memory)
    {
        return IUniswapV2Router02(routerAddress).getAmountsIn(amountOut, addressesPath);
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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