/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
      assembly { size := extcodesize(account) }
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
      (bool success, ) = recipient.call{ value: amount }("");
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
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
      require(address(this).balance >= value, "Address: insufficient balance for call");
      require(isContract(target), "Address: call to non-contract");
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
  function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
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
  function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
      require(isContract(target), "Address: delegate call to non-contract");
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, bytes memory returndata) = target.delegatecall(data);
      return _verifyCallResult(success, returndata, errorMessage);
  }
  function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 {
 function totalSupply() external view returns (uint256);
 function balanceOf(address account) external view returns (uint256);
 function transfer(address recipient, uint256 amount) external returns (bool);
 function allowance(address owner, address spender) external view returns (uint256);
 function approve(address spender, uint256 amount) external returns (bool);
 function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 event Transfer(address indexed from, address indexed to, uint256 value);
 event Approval(address indexed owner, address indexed spender, uint256 value);
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
  function safeTransfer(IERC20 token, address to, uint256 value) internal {
      _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }
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
      // solhint-disable-next-line max-line-length
      require((value == 0) || (token.allowance(address(this), spender) == 0),
          "SafeERC20: approve from non-zero to non-zero allowance"
      );
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }
  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
      uint256 newAllowance = token.allowance(address(this), spender) + value;
      _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }
  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
      if (returndata.length > 0) { // Return data is optional
          // solhint-disable-next-line max-line-length
          require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
      }
  }
}

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

// File: contracts/EdenSwapRoll.sol

// EdenSwapRoll helps your migrate your existing Uniswap LP tokens to EdenSwapSwap LP ones
contract EdenSwapRoll {

    using SafeERC20 for IERC20;

    IUniswapV2Router02 public immutable oldRouter;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    constructor(address _oldRouter, address _router) {
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        uniswapV2Router = _uniswapV2Router;

        IUniswapV2Router02 _uniswapV2Routerold = IUniswapV2Router02(_oldRouter);
        oldRouter = _uniswapV2Routerold;

    }
    
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    // msg.sender should have approved 'liquidity' amount of LP token of 'tokenA' and 'tokenB'
    function migrate(
        address tokenA,
        address tokenB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 liquidity,
        uint256 deadline
    ) public {
        require(deadline >= block.timestamp, 'EdenSwap: EXPIRED');

        uniswapV2Pair = IUniswapV2Factory(oldRouter.factory())
            .getPair(tokenA, tokenB);


        (uint256 amountA, uint256 amountB) = removeLiquidityfromOldRouter(tokenA, tokenB, amountAMin, amountBMin, liquidity);
    
        // Add liquidity to the new router
        (uint256 pooledAmountA, uint256 pooledAmountB, uint256 liquidityAdded) = addLiquidityToNewRouter(tokenA, tokenB, amountA, amountB, amountAMin, amountBMin);
    
        // Send remaining tokens to msg.sender
        if (amountA > pooledAmountA) {
            IERC20(tokenA).safeTransfer(msg.sender, amountA - pooledAmountA);
        }
        if (amountB > pooledAmountB) {
            IERC20(tokenB).safeTransfer(msg.sender, amountB - pooledAmountB);
        }
    }

    function removeLiquidityfromOldRouter(address tokenA, address tokenB, uint256 amountAmin, uint256 amountBmin, uint256 liquidity) internal virtual returns(uint256 amountA, uint256 amountB){
 
        // transferfrom sender to contract address
        IUniswapV2Pair(uniswapV2Pair).transferFrom(msg.sender, address(this), liquidity);
        // approve router address
        IUniswapV2Pair(uniswapV2Pair).approve(address(oldRouter), liquidity);

        // remove the liquidity
        (uint256 pooledAmountA, uint256 pooledAmountB) = oldRouter.removeLiquidity(
            tokenA, //0x7deE6E7E0466E7E96d26d78Cc1c6BafFa0eFC16A,
            tokenB, //0x1db7B0287742cd82f7B94cEE2AB882301f54684a,
            liquidity,
            amountAmin, // slippage is unavoidable
            amountBmin, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        return (pooledAmountA, pooledAmountB);

    }
    
    function addLiquidityToNewRouter(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 amountAmin, uint256 amountBmin) internal returns (uint256 pooledAmountA, uint256 pooledAmountB, uint256 liquidityAddedAmount){
       
        // transfer to contract address
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        // approve token transfer to cover all possible scenarios
        IERC20(tokenA).approve(address(uniswapV2Router), amountA);
        IERC20(tokenB).approve(address(uniswapV2Router), amountB);

        // add the liquidity
        (uint256 pooledA, uint256 pooledB, uint256 liquidityAdded) = uniswapV2Router.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            amountAmin, // slippage is unavoidable
            amountBmin, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );

        return (pooledA, pooledB, liquidityAdded);
    }
    
}