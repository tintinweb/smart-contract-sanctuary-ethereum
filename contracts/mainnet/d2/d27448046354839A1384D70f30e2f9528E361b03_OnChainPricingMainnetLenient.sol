// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.10;


import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";


import "IUniswapRouterV2.sol";
import "ICurveRouter.sol";

import {OnChainPricingMainnet} from "OnChainPricingMainnet.sol";



/// @title OnChainPricing
/// @author Alex the Entreprenerd @ BadgerDAO
/// @dev Mainnet Version of Price Quoter, hardcoded for more efficiency
/// @notice To spin a variant, just change the constants and use the Component Functions at the end of the file
/// @notice Instead of upgrading in the future, just point to a new implementation
/// @notice This version has 5% extra slippage to allow further flexibility
///     if the manager abuses the check you should consider reverting back to a more rigorous pricer
contract OnChainPricingMainnetLenient is OnChainPricingMainnet {

    // === SLIPPAGE === //
    // Can change slippage within rational limits
    address public constant TECH_OPS = 0x86cbD0ce0c087b482782c181dA8d191De18C8275;
    
    uint256 private constant MAX_BPS = 10_000;

    uint256 private constant MAX_SLIPPAGE = 500; // 5%

    uint256 public slippage = 200; // 2% Initially

    constructor(
        address _uniV3Simulator, 
        address _balancerV2Simulator
    ) OnChainPricingMainnet(_uniV3Simulator, _balancerV2Simulator){
        // Silence is golden
    }

    function setSlippage(uint256 newSlippage) external {
        require(msg.sender == TECH_OPS, "Only TechOps");
        require(newSlippage < MAX_SLIPPAGE);
        slippage = newSlippage;
    }

    // === PRICING === //

    /// @dev View function for testing the routing of the strategy
    function findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) external view override returns (Quote memory q) {
        q = _findOptimalSwap(tokenIn, tokenOut, amountIn);
        q.amountOut = q.amountOut * (MAX_BPS - slippage) / MAX_BPS;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapRouterV2 {
    function factory() external view returns (address);

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
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
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface ICurveRouter {
  function get_best_rate(
    address from, address to, uint256 _amount) external view returns (address, uint256);
  
  function exchange_with_best_rate(
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected
  ) external returns (uint256);
  
  function exchange_with_best_rate(
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external returns (uint256);
  
  function exchange(
    address _pool,
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.10;


import {IERC20} from "IERC20.sol";
import {IERC20Metadata} from "IERC20Metadata.sol";
import {SafeERC20} from "SafeERC20.sol";
import {Address} from "Address.sol";

import "IUniswapRouterV2.sol";
import "IV3Pool.sol";
import "IV2Pool.sol";
import "IV3Quoter.sol";
import "IBalancerV2Vault.sol";
import "IBalancerV2WeightedPool.sol";
import "IBalancerV2StablePool.sol";
import "ICurveRouter.sol";
import "ICurvePool.sol";
import "IV3Simulator.sol";
import "IBalancerV2Simulator.sol";

enum SwapType { 
    CURVE, //0
    UNIV2, //1
    SUSHI, //2
    UNIV3, //3
    UNIV3WITHWETH, //4 
    BALANCER, //5
    BALANCERWITHWETH //6 
}

/// @title OnChainPricing
/// @author Alex the Entreprenerd for BadgerDAO
/// @author Camotelli @rayeaster
/// @dev Mainnet Version of Price Quoter, hardcoded for more efficiency
/// @notice To spin a variant, just change the constants and use the Component Functions at the end of the file
/// @notice Instead of upgrading in the future, just point to a new implementation
/// @notice TOC
/// UNIV2
/// UNIV3
/// BALANCER
/// CURVE
/// UTILS
/// 
contract OnChainPricingMainnet {
    using Address for address;
    
    // Assumption #1 Most tokens liquid pair is WETH (WETH is tokenized ETH for that chain)
    // e.g on Fantom, WETH would be wFTM
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// == Uni V2 Like Routers || These revert on non-existent pair == //
    // UniV2
    address public constant UNIV2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Spookyswap
    bytes public constant UNIV2_POOL_INITCODE = hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f";
    address public constant UNIV2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // Sushi
    address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    bytes public constant SUSHI_POOL_INITCODE = hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303";
    address public constant SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    // Curve / Doesn't revert on failure
    address public constant CURVE_ROUTER = 0x8e764bE4288B842791989DB5b8ec067279829809; // Curve quote and swaps
		
    // UniV3 impl credit to https://github.com/1inch/spot-price-aggregator/blob/master/contracts/oracles/UniswapV3Oracle.sol
    address public constant UNIV3_QUOTER = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    bytes32 public constant UNIV3_POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    address public constant UNIV3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

    // BalancerV2 Vault
    address public constant BALANCERV2_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    bytes32 public constant BALANCERV2_NONEXIST_POOLID = "BALANCER-V2-NON-EXIST-POOLID";
    // selected Balancer V2 pools for given pairs on Ethereum with liquidity > $5M: https://dev.balancer.fi/references/subgraphs#examples
    bytes32 public constant BALANCERV2_WSTETH_WETH_POOLID = 0x32296969ef14eb0c6d29669c550d4a0449130230000200000000000000000080;
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    bytes32 public constant BALANCERV2_WBTC_WETH_POOLID = 0xa6f548df93de924d73be7d25dc02554c6bd66db500020000000000000000000e;
    address public constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    bytes32 public constant BALANCERV2_USDC_WETH_POOLID = 0x96646936b91d6b9d7d0c47c496afbf3d6ec7b6f8000200000000000000000019;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 public constant BALANCERV2_BAL_WETH_POOLID = 0x5c6ee304399dbdb9c8ef030ab642b10820db8f56000200000000000000000014;
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    bytes32 public constant BALANCERV2_FEI_WETH_POOLID = 0x90291319f1d4ea3ad4db0dd8fe9e12baf749e84500020000000000000000013c;
    address public constant FEI = 0x956F47F50A910163D8BF957Cf5846D573E7f87CA;
    bytes32 public constant BALANCERV2_BADGER_WBTC_POOLID = 0xb460daa847c45f1c4a41cb05bfb3b51c92e41b36000200000000000000000194;
    address public constant BADGER = 0x3472A5A71965499acd81997a54BBA8D852C6E53d;
    bytes32 public constant BALANCERV2_GNO_WETH_POOLID = 0xf4c0dd9b82da36c07605df83c8a416f11724d88b000200000000000000000026;
    address public constant GNO = 0x6810e776880C02933D47DB1b9fc05908e5386b96;
    bytes32 public constant BALANCERV2_CREAM_WETH_POOLID = 0x85370d9e3bb111391cc89f6de344e801760461830002000000000000000001ef;
    address public constant CREAM = 0x2ba592F78dB6436527729929AAf6c908497cB200;	
    bytes32 public constant BALANCERV2_LDO_WETH_POOLID = 0xbf96189eee9357a95c7719f4f5047f76bde804e5000200000000000000000087;
    address public constant LDO = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;	
    bytes32 public constant BALANCERV2_SRM_WETH_POOLID = 0x231e687c9961d3a27e6e266ac5c433ce4f8253e4000200000000000000000023;
    address public constant SRM = 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF;	
    bytes32 public constant BALANCERV2_rETH_WETH_POOLID = 0x1e19cf2d73a72ef1332c882f20534b6519be0276000200000000000000000112;
    address public constant rETH = 0xae78736Cd615f374D3085123A210448E74Fc6393;	
    bytes32 public constant BALANCERV2_AKITA_WETH_POOLID = 0xc065798f227b49c150bcdc6cdc43149a12c4d75700020000000000000000010b;
    address public constant AKITA = 0x3301Ee63Fb29F863f2333Bd4466acb46CD8323E6;	
    bytes32 public constant BALANCERV2_OHM_DAI_WETH_POOLID = 0xc45d42f801105e861e86658648e3678ad7aa70f900010000000000000000011e;
    address public constant OHM = 0x64aa3364F17a4D01c6f1751Fd97C2BD3D7e7f1D5;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    bytes32 public constant BALANCERV2_COW_WETH_POOLID = 0xde8c195aa41c11a0c4787372defbbddaa31306d2000200000000000000000181;
    bytes32 public constant BALANCERV2_COW_GNO_POOLID = 0x92762b42a06dcdddc5b7362cfb01e631c4d44b40000200000000000000000182;
    address public constant COW = 0xDEf1CA1fb7FBcDC777520aa7f396b4E015F497aB;
    bytes32 public constant BALANCERV2_AURA_WETH_POOLID = 0xc29562b045d80fd77c69bec09541f5c16fe20d9d000200000000000000000251;
    address public constant AURA = 0xC0c293ce456fF0ED870ADd98a0828Dd4d2903DBF;
    bytes32 public constant BALANCERV2_AURABAL_BALWETH_POOLID = 0x3dd0843a028c86e0b760b1a76929d1c5ef93a2dd000200000000000000000249;
    
    address public constant GRAVIAURA = 0xBA485b556399123261a5F9c95d413B4f93107407;
    address public constant DIGG = 0x798D1bE841a82a273720CE31c822C61a67a601C3;
    bytes32 public constant BALANCERV2_AURABAL_GRAVIAURA_WETH_POOLID = 0x0578292cb20a443ba1cde459c985ce14ca2bdee5000100000000000000000269;
    bytes32 public constant BALANCER_V2_WBTC_DIGG_GRAVIAURA_POOLID = 0x8eb6c82c3081bbbd45dcac5afa631aac53478b7c000100000000000000000270;

    // NOTE: Not used due to possible migration： https://forum.balancer.fi/t/vulnerability-disclosure/3179
    bytes32 public constant BALANCERV2_DAI_USDC_USDT_POOLID = 0x06df3b2bbb68adc8b0e302443692037ed9f91b42000000000000000000000063;

    address public constant AURABAL = 0x616e8BfA43F920657B3497DBf40D6b1A02D4608d;
    address public constant BALWETHBPT = 0x5c6Ee304399DBdB9C8Ef030aB642B10820DB8F56;
    uint256 public constant CURVE_FEE_SCALE = 100000;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    /// @dev helper library to simulate Uniswap V3 swap
    address public immutable uniV3Simulator;
    /// @dev helper library to simulate Balancer V2 swap
    address public immutable balancerV2Simulator;


    /// UniV3, replaces an array
    /// @notice We keep above constructor, because this is a gas optimization
    ///     Saves storing fee ids in storage, saving 2.1k+ per call
    uint256 constant univ3_fees_length = 4;
    function univ3_fees(uint256 i) internal pure returns (uint24) {
        if(i == 0){
            return uint24(100);
        } else if (i == 1) {
            return uint24(500);
        } else if (i == 2) {
            return uint24(3000);
        } 
        // else if (i == 3) {
        return uint24(10000);
    }

    constructor(address _uniV3Simulator, address _balancerV2Simulator){
        uniV3Simulator = _uniV3Simulator;
        balancerV2Simulator = _balancerV2Simulator;
    }

    struct Quote {
        SwapType name;
        uint256 amountOut;
        bytes32[] pools; // specific pools involved in the optimal swap path
        uint256[] poolFees; // specific pool fees involved in the optimal swap path, typically in Uniswap V3
    }

    /// @dev Given tokenIn, out and amountIn, returns true if a quote will be non-zero
    /// @notice Doesn't guarantee optimality, just non-zero
    function isPairSupported(address tokenIn, address tokenOut, uint256 amountIn) external view returns (bool) {
        // Sorted by "assumed" reverse worst case
        // Go for higher gas cost checks assuming they are offering best precision / good price

        // If There's a Bal Pool, since we have to hardcode, then the price is probably non-zero
        bytes32 poolId = getBalancerV2Pool(tokenIn, tokenOut);
        if (poolId != BALANCERV2_NONEXIST_POOLID){
            return true;
        }

        // If no pool this is fairly cheap, else highly likely there's a price
        if(checkUniV3PoolsExistence(tokenIn, tokenOut)) {
            return true;
        }

        // Highly likely to have any random token here
        if(getUniPrice(UNIV2_ROUTER, tokenIn, tokenOut, amountIn) > 0) {
            return true;
        }

        // Otherwise it's probably on Sushi
        if(getUniPrice(SUSHI_ROUTER, tokenIn, tokenOut, amountIn) > 0) {
            return true;
        }

        // Curve at this time has great execution prices but low selection
        (, uint256 curveQuote) = getCurvePrice(CURVE_ROUTER, tokenIn, tokenOut, amountIn);
        if (curveQuote > 0){
            return true;
        }

        return false;
    }

    /// @dev External function, virtual so you can override, see Lenient Version
    /// @param tokenIn - The token you want to sell
    /// @param tokenOut - The token you want to buy
    /// @param amountIn - The amount of token you want to sell
    function findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) external view virtual returns (Quote memory) {
        return _findOptimalSwap(tokenIn, tokenOut, amountIn);
    }

    /// @dev View function for testing the routing of the strategy
    /// See {findOptimalSwap}
    function _findOptimalSwap(address tokenIn, address tokenOut, uint256 amountIn) internal view returns (Quote memory) {
        bool wethInvolved = (tokenIn == WETH || tokenOut == WETH);
        uint256 length = wethInvolved? 5 : 7; // Add length you need

        Quote[] memory quotes = new Quote[](length);
        bytes32[] memory dummyPools;
        uint256[] memory dummyPoolFees;

        (address curvePool, uint256 curveQuote) = getCurvePrice(CURVE_ROUTER, tokenIn, tokenOut, amountIn);
        if (curveQuote > 0){		   
            (bytes32[] memory curvePools, uint256[] memory curvePoolFees) = _getCurveFees(curvePool);
            quotes[0] = Quote(SwapType.CURVE, curveQuote, curvePools, curvePoolFees);		
        } else {
            quotes[0] = Quote(SwapType.CURVE, curveQuote, dummyPools, dummyPoolFees);         			
        }

        quotes[1] = Quote(SwapType.UNIV2, getUniPrice(UNIV2_ROUTER, tokenIn, tokenOut, amountIn), dummyPools, dummyPoolFees);

        quotes[2] = Quote(SwapType.SUSHI, getUniPrice(SUSHI_ROUTER, tokenIn, tokenOut, amountIn), dummyPools, dummyPoolFees);

        quotes[3] = Quote(SwapType.UNIV3, getUniV3Price(tokenIn, amountIn, tokenOut), dummyPools, dummyPoolFees);

        quotes[4] = Quote(SwapType.BALANCER, getBalancerPriceAnalytically(tokenIn, amountIn, tokenOut), dummyPools, dummyPoolFees);

        if(!wethInvolved){
            quotes[5] = Quote(SwapType.UNIV3WITHWETH, (_useSinglePoolInUniV3(tokenIn, tokenOut) > 0 ? 0 : getUniV3PriceWithConnector(tokenIn, amountIn, tokenOut, WETH)), dummyPools, dummyPoolFees);	

            quotes[6] = Quote(SwapType.BALANCERWITHWETH, getBalancerPriceWithConnectorAnalytically(tokenIn, amountIn, tokenOut, WETH), dummyPools, dummyPoolFees);		
        }

        // Because this is a generalized contract, it is best to just loop,
        // Ideally we have a hierarchy for each chain to save some extra gas, but I think it's ok
        // O(n) complexity and each check is like 9 gas
        Quote memory bestQuote = quotes[0];
        unchecked {
            for(uint256 x = 1; x < length; ++x) {
                if(quotes[x].amountOut > bestQuote.amountOut) {
                    bestQuote = quotes[x];
                }
            }
        }


        return bestQuote;
    }    

    /// === Component Functions === /// 
    /// Why bother?
    /// Because each chain is slightly different but most use similar tech / forks
    /// May as well use the separate functoions so each OnChain Pricing on different chains will be slightly different
    /// But ultimately will work in the same way

    /// === UNIV2 === ///

    /// @dev Given the address of the UniV2Like Router, the input amount, and the path, returns the quote for it
    function getUniPrice(address router, address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256) {
	
        // check pool existence first before quote against it
        bool _univ2 = (router == UNIV2_ROUTER);
        
        (address _pool, address _token0, ) = pairForUniV2((_univ2? UNIV2_FACTORY : SUSHI_FACTORY), tokenIn, tokenOut, (_univ2? UNIV2_POOL_INITCODE : SUSHI_POOL_INITCODE));
        if (!_pool.isContract()){
            return 0;
        }
		
        bool _zeroForOne = (_token0 == tokenIn);
        (uint256 _t0Balance, uint256 _t1Balance, ) = IUniswapV2Pool(_pool).getReserves();
        // Use dummy magic number as a quick-easy substitute for liquidity (to avoid one SLOAD) since we have pool reserve check in it
        bool _basicCheck = _checkPoolLiquidityAndBalances(1, (_zeroForOne? _t0Balance : _t1Balance), amountIn);
        return _basicCheck? getUniV2AmountOutAnalytically(amountIn, (_zeroForOne? _t0Balance : _t1Balance), (_zeroForOne? _t1Balance : _t0Balance)) : 0;
    }
	
    /// @dev reference https://etherscan.io/address/0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F#code#L122
    function getUniV2AmountOutAnalytically(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
	
    function pairForUniV2(address factory, address tokenA, address tokenB, bytes memory _initCode) public pure returns (address, address, address) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);		
        address pair = getAddressFromBytes32Lsb(keccak256(abi.encodePacked(
                hex"ff",
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                _initCode // init code hash
        )));
        return (pair, token0, token1);
    }
	
    /// === UNIV3 === ///
	
    /// @dev explore Uniswap V3 pools to check if there is a chance to resolve the swap with in-range liquidity (i.e., without crossing ticks)
    /// @dev check helper UniV3SwapSimulator for more
    /// @return maximum output (with current in-range liquidity & spot price) and according pool fee
    function sortUniV3Pools(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256, uint24){
        uint256 _maxQuote;
        uint24 _maxQuoteFee;
		
        {
            // Heuristic: If we already know high TVL Pools, use those
            uint24 _bestFee = _useSinglePoolInUniV3(tokenIn, tokenOut);
            (address token0, address token1, bool token0Price) = _ifUniV3Token0Price(tokenIn, tokenOut);
			
            {
                if (_bestFee > 0) {
                    (,uint256 _bestOutAmt) = _checkSimulationInUniV3(token0, token1, amountIn, _bestFee, token0Price);
                    return (_bestOutAmt, _bestFee);
                }
            }
			
            (uint256 _maxQAmt, uint24 _maxQFee) = _simLoopAllUniV3Pools(token0, token1, amountIn, token0Price); 
            _maxQuote = _maxQAmt;
            _maxQuoteFee = _maxQFee;
        }
		
        return (_maxQuote, _maxQuoteFee);
    }	
	
    /// @dev loop over all possible Uniswap V3 pools to find a proper quote
    function _simLoopAllUniV3Pools(address token0, address token1, uint256 amountIn, bool token0Price) internal view returns (uint256, uint24) {		
        uint256 _maxQuote;
        uint24 _maxQuoteFee;
        uint256 feeTypes = univ3_fees_length;		
	
        for (uint256 i = 0; i < feeTypes;){
            uint24 _fee = univ3_fees(i);
                
            {			 
                // TODO: Partial rewrite to perform initial comparison against all simulations based on "liquidity in range"
                // If liq is in range, then lowest fee auto-wins
                // Else go down fee range with liq in range 
                // NOTE: A tick is like a ratio, so technically X ticks can offset a fee
                // Meaning we prob don't need full quote in majority of cases, but can compare number of ticks
                // per pool per fee and pre-rank based on that
                (, uint256 _outAmt) = _checkSimulationInUniV3(token0, token1, amountIn, _fee, token0Price);
                if (_outAmt > _maxQuote){
                    _maxQuote = _outAmt;
                    _maxQuoteFee = _fee;
                }
                unchecked { ++i; }	
            }
        }
		
        return (_maxQuote, _maxQuoteFee);		
    }
	
    /// @dev tell if there exists some Uniswap V3 pool for given token pair
    function checkUniV3PoolsExistence(address tokenIn, address tokenOut) public view returns (bool){
        uint256 feeTypes = univ3_fees_length;	
        (address token0, address token1, ) = _ifUniV3Token0Price(tokenIn, tokenOut);
        bool _exist;
        {    
          for (uint256 i = 0; i < feeTypes;){
             address _pool = _getUniV3PoolAddress(token0, token1, univ3_fees(i));
             if (_pool.isContract()) {
                 _exist = true;
                 break;
             }
             unchecked { ++i; }	
          }				 
        }	
        return _exist;		
    }
	
    /// @dev Uniswap V3 pool in-range liquidity check
    /// @return true if cross-ticks full simulation required for the swap otherwise false (in-range liquidity would satisfy the swap)
    function checkUniV3InRangeLiquidity(address token0, address token1, uint256 amountIn, uint24 _fee, bool token0Price, address _pool) public view returns (bool, uint256){
        {    
             if (!_pool.isContract()) {
                 return (false, 0);
             }
			 
             bool _basicCheck = _checkPoolLiquidityAndBalances(IUniswapV3Pool(_pool).liquidity(), IERC20(token0Price? token0 : token1).balanceOf(_pool), amountIn);
             if (!_basicCheck) {
                 return (false, 0);
             }
			 
             UniV3SortPoolQuery memory _sortQuery = UniV3SortPoolQuery(_pool, token0, token1, _fee, amountIn, token0Price);
             return IUniswapV3Simulator(uniV3Simulator).checkInRangeLiquidity(_sortQuery);
        }
    }
	
    /// @dev internal function to avoid stack too deep for 1) check in-range liquidity in Uniswap V3 pool 2) full cross-ticks simulation in Uniswap V3
    function _checkSimulationInUniV3(address token0, address token1, uint256 amountIn, uint24 _fee, bool token0Price) internal view returns (bool, uint256) {
        bool _crossTick;
        uint256 _outAmt;
        
        address _pool = _getUniV3PoolAddress(token0, token1, _fee);		
        {
             // in-range swap check: find out whether the swap within current liquidity would move the price across next tick
             (bool _outOfInRange, uint256 _outputAmount) = checkUniV3InRangeLiquidity(token0, token1, amountIn, _fee, token0Price, _pool);
             _crossTick = _outOfInRange;
             _outAmt = _outputAmount;
        }
        {
             // unfortunately we need to do a full simulation to cross ticks
             if (_crossTick){
                 _outAmt = simulateUniV3Swap(token0, amountIn, token1, _fee, token0Price, _pool);
             } 
        }
        return (_crossTick, _outAmt);
    }
	
    /// @dev internal function for a basic sanity check pool existence and balances
    /// @return true if basic check pass otherwise false
    function _checkPoolLiquidityAndBalances(uint256 _liq, uint256 _reserveIn, uint256 amountIn) internal pure returns (bool) {
	    
        {
             // heuristic check0: ensure the pool initiated with valid liquidity in place
             if (_liq == 0) {
                 return false;
             }
        }
		
        {
            // TODO: In a later check, we check slot0 liquidity
            // Is there any change that slot0 gives us more information about the liquidity in range,
            // Such that optimistically it would immediately allow us to determine a winning pool?
            // Prob winning pool would be: Lowest Fee, with Liquidity covered within the tick
		
             // heuristic check1: ensure the pool tokenIn reserve makes sense in terms of [amountIn], i.e., the pool is liquid compared to swap amount
             // say if the pool got 100 tokenA, and you tried to swap another 100 tokenA into it for the other token, 
             // by the math of AMM, this will drastically imbalance the pool, so the quote won't be good for sure
             return _reserveIn > amountIn;
        }		
    }
	
    /// @dev simulate Uniswap V3 swap using its tick-based math for given parameters
    /// @dev check helper UniV3SwapSimulator for more
    function simulateUniV3Swap(address token0, uint256 amountIn, address token1, uint24 _fee, bool token0Price, address _pool) public view returns (uint256) {
        return IUniswapV3Simulator(uniV3Simulator).simulateUniV3Swap(_pool, token0, token1, token0Price, _fee, amountIn);
    }	
	
    /// @dev Given the address of the input token & amount & the output token
    /// @return the quote for it
    function getUniV3Price(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256) {		
        (uint256 _maxInRangeQuote, ) = sortUniV3Pools(tokenIn, amountIn, tokenOut);		
        return _maxInRangeQuote;
    }
	
    /// @dev Given the address of the input token & amount & the output token & connector token in between (input token ---> connector token ---> output token)
    /// @return the quote for it
    function getUniV3PriceWithConnector(address tokenIn, uint256 amountIn, address tokenOut, address connectorToken) public view returns (uint256) {
        // Skip if there is a mainstrem direct swap or connector pools not exist
        if (!checkUniV3PoolsExistence(tokenIn, connectorToken) || !checkUniV3PoolsExistence(connectorToken, tokenOut)){
            return 0;
        }
		
        uint256 connectorAmount = getUniV3Price(tokenIn, amountIn, connectorToken);	
        if (connectorAmount > 0){	
            return getUniV3Price(connectorToken, connectorAmount, tokenOut);
        } else{
            return 0;
        }
    }
	
    /// @dev return token0 & token1 and if token0 equals tokenIn
    function _ifUniV3Token0Price(address tokenIn, address tokenOut) internal pure returns (address, address, bool){
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        return (token0, token1, token0 == tokenIn);
    }
	
    /// @dev query with the address of the token0 & token1 & the fee tier
    /// @return the uniswap v3 pool address
    function _getUniV3PoolAddress(address token0, address token1, uint24 fee) internal pure returns (address) {
        bytes32 addr = keccak256(abi.encodePacked(hex"ff", UNIV3_FACTORY, keccak256(abi.encode(token0, token1, fee)), UNIV3_POOL_INIT_CODE_HASH));
        return address(uint160(uint256(addr)));
    }
	
    /// @dev selected token pair which will try a chosen Uniswap V3 pool ONLY among all possible fees
    /// @dev picked from most traded pool (Volume 7D) in https://info.uniswap.org/#/pools
    /// @dev mainly 5 most-popular tokens WETH-WBTC-USDC-USDT-DAI (Volume 24H) https://info.uniswap.org/#/tokens
    /// @return 0 if all possible fees should be checked otherwise the ONLY pool fee we should go for
    function _useSinglePoolInUniV3(address tokenIn, address tokenOut) internal pure returns(uint24) {
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        if (token1 == WETH && (token0 == USDC || token0 == WBTC || token0 == DAI)) {
            return 500;
        } else if (token0 == WETH && token1 == USDT) {
            return 500;
        } else if (token1 == USDC && token0 == DAI) {
            return 100;
        } else if (token0 == USDC && token1 == USDT) {
            return 100;
        } else if (token1 == USDC && token0 == WBTC) {
            return 3000;
        } else {
            return 0;
        }
    }	

    /// === BALANCER === ///
	
    /// @dev Given the input/output token, returns the quote for input amount from Balancer V2 using its underlying math
    function getBalancerPriceAnalytically(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256) { 
        bytes32 poolId = getBalancerV2Pool(tokenIn, tokenOut);
        if (poolId == BALANCERV2_NONEXIST_POOLID){
            return 0;
        }
        return getBalancerQuoteWithinPoolAnalytcially(poolId, tokenIn, amountIn, tokenOut);
    }
	
    function getBalancerQuoteWithinPoolAnalytcially(bytes32 poolId, address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256) {			
        uint256 _quote;		
        address _pool = getAddressFromBytes32Msb(poolId);
        
        {
            (address[] memory tokens, uint256[] memory balances, ) = IBalancerV2Vault(BALANCERV2_VAULT).getPoolTokens(poolId);
			
            uint256 _inTokenIdx = _findTokenInBalancePool(tokenIn, tokens);
            require(_inTokenIdx < tokens.length, "!inBAL");
            uint256 _outTokenIdx = _findTokenInBalancePool(tokenOut, tokens);
            require(_outTokenIdx < tokens.length, "!outBAL");
			 
            if(balances[_inTokenIdx] <= amountIn) return 0;
		
            /// Balancer math for spot price of tokenIn -> tokenOut: weighted value(number * price) relation should be kept
            try IBalancerV2StablePool(_pool).getAmplificationParameter() returns (uint256 currentAmp, bool, uint256) {
                // stable pool math
                {
                   ExactInStableQueryParam memory _stableQuery = ExactInStableQueryParam(tokens, balances, currentAmp, _inTokenIdx, _outTokenIdx, amountIn, IBalancerV2StablePool(_pool).getSwapFeePercentage());

                    try IBalancerV2Simulator(balancerV2Simulator).calcOutGivenInForStable(_stableQuery) returns (uint256 balQuote) {
                        _quote = balQuote;
                    } catch  {
                        _quote = 0;
                    }    

                }
            } catch {
                // weighted pool math
                {
                   uint256[] memory _weights = IBalancerV2WeightedPool(_pool).getNormalizedWeights();
                   require(_weights.length == tokens.length, "!lenBAL");
                   ExactInQueryParam memory _query = ExactInQueryParam(tokenIn, tokenOut, balances[_inTokenIdx], _weights[_inTokenIdx], balances[_outTokenIdx], _weights[_outTokenIdx], amountIn, IBalancerV2WeightedPool(_pool).getSwapFeePercentage());

                    try IBalancerV2Simulator(balancerV2Simulator).calcOutGivenIn(_query) returns (uint256 balQuote) {
                        _quote = balQuote;
                    } catch {
                        _quote = 0;
                    }
                }
            }
        }
		
        return _quote;
    }
	
    function _findTokenInBalancePool(address _token, address[] memory _tokens) internal pure returns (uint256){	    
        uint256 _len = _tokens.length;
        for (uint256 i = 0; i < _len; ){
            if (_tokens[i] == _token){
                return i;
            }
            unchecked{ ++i; }
        } 
        return type(uint256).max;
    }
	
    /// @dev Given the input/output/connector token, returns the quote for input amount from Balancer V2 using its underlying math
    function getBalancerPriceWithConnectorAnalytically(address tokenIn, uint256 amountIn, address tokenOut, address connectorToken) public view returns (uint256) { 
        if (getBalancerV2Pool(tokenIn, connectorToken) == BALANCERV2_NONEXIST_POOLID || getBalancerV2Pool(connectorToken, tokenOut) == BALANCERV2_NONEXIST_POOLID){
            return 0;
        }
		
        uint256 _in2ConnectorAmt = getBalancerPriceAnalytically(tokenIn, amountIn, connectorToken);
        if (_in2ConnectorAmt <= 0){
            return 0;
        }
        return getBalancerPriceAnalytically(connectorToken, _in2ConnectorAmt, tokenOut);    
    }
	
    /// @return selected BalancerV2 pool given the tokenIn and tokenOut 
    function getBalancerV2Pool(address tokenIn, address tokenOut) public pure returns(bytes32){
        (address token0, address token1) = tokenIn < tokenOut ? (tokenIn, tokenOut) : (tokenOut, tokenIn);
        if (token0 == CREAM && token1 == WETH){
            return BALANCERV2_CREAM_WETH_POOLID;
        } else if (token0 == GNO && token1 == WETH){
            return BALANCERV2_GNO_WETH_POOLID;
        } else if (token0 == WBTC && token1 == BADGER){
            return BALANCERV2_BADGER_WBTC_POOLID;
        } else if (token0 == FEI && token1 == WETH){
            return BALANCERV2_FEI_WETH_POOLID;
        } else if (token0 == BAL && token1 == WETH){
            return BALANCERV2_BAL_WETH_POOLID;
        } else if (token0 == USDC && token1 == WETH){
            return BALANCERV2_USDC_WETH_POOLID;
        } else if (token0 == WBTC && token1 == WETH){
            return BALANCERV2_WBTC_WETH_POOLID;
        } else if (token0 == WSTETH && token1 == WETH){
            return BALANCERV2_WSTETH_WETH_POOLID;
        } else if (token0 == LDO && token1 == WETH){
            return BALANCERV2_LDO_WETH_POOLID;
        } else if (token0 == SRM && token1 == WETH){
            return BALANCERV2_SRM_WETH_POOLID;
        } else if (token0 == rETH && token1 == WETH){
            return BALANCERV2_rETH_WETH_POOLID;
        } else if (token0 == AKITA && token1 == WETH){
            return BALANCERV2_AKITA_WETH_POOLID;
        } else if ((token0 == OHM && token1 == WETH) || (token0 == OHM && token1 == DAI)){
            return BALANCERV2_OHM_DAI_WETH_POOLID;
        } else if (token0 == GNO && token1 == COW){
            return BALANCERV2_COW_GNO_POOLID;
        } else if (token0 == WETH && token1 == COW){
            return BALANCERV2_COW_WETH_POOLID;
        } else if (token0 == WETH && token1 == AURA){
            return BALANCERV2_AURA_WETH_POOLID;
        } else if (token0 == BALWETHBPT && token1 == AURABAL){
            return BALANCERV2_AURABAL_BALWETH_POOLID;
        } else if (token0 == AURABAL && token1 == WETH){
            return BALANCERV2_AURABAL_GRAVIAURA_WETH_POOLID;
        } else if (token0 == GRAVIAURA && token1 == WETH){
            return BALANCERV2_AURABAL_GRAVIAURA_WETH_POOLID;
        } else if (token0 == WBTC && token1 == DIGG){
            return BALANCER_V2_WBTC_DIGG_GRAVIAURA_POOLID;
        } else if (token0 == DIGG && token1 == GRAVIAURA){
            return BALANCER_V2_WBTC_DIGG_GRAVIAURA_POOLID;
        
        } else{
            return BALANCERV2_NONEXIST_POOLID;
        }		
    }

    /// === CURVE === ///

    /// @dev Given the address of the CurveLike Router, the input amount, and the path, returns the quote for it
    function getCurvePrice(address router, address tokenIn, address tokenOut, uint256 amountIn) public view returns (address, uint256) {
        (address pool, uint256 curveQuote) = ICurveRouter(router).get_best_rate(tokenIn, tokenOut, amountIn);

        return (pool, curveQuote);
    }
	
    /// @return assembled curve pools and fees in required Quote struct for given pool
    // TODO: Decide if we need fees, as it costs more gas to compute
    function _getCurveFees(address _pool) internal view returns (bytes32[] memory, uint256[] memory){	
        bytes32[] memory curvePools = new bytes32[](1);
        curvePools[0] = convertToBytes32(_pool);
        uint256[] memory curvePoolFees = new uint256[](1);
        curvePoolFees[0] = ICurvePool(_pool).fee() * CURVE_FEE_SCALE / 1e10;//https://curve.readthedocs.io/factory-pools.html?highlight=fee#StableSwap.fee
        return (curvePools, curvePoolFees);
    }

    /// === UTILS === ///

    /// @dev Given a address input, return the bytes32 representation
    // TODO: Figure out if abi.encode is better -> Benchmark on GasLab
    function convertToBytes32(address _input) public pure returns (bytes32){
        return bytes32(uint256(uint160(_input)) << 96);
    }
	
    /// @dev Take for example the _input "0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC"
    /// @return the result of "0x111122223333444455556666777788889999aAaa"
    function getAddressFromBytes32Msb(bytes32 _input) public pure returns (address){
        return address(uint160(bytes20(_input)));
    }
	
    /// @dev Take for example the _input "0x111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFFCCCC"
    /// @return the result of "0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc"
    function getAddressFromBytes32Lsb(bytes32 _input) public pure returns (address){
        return address(uint160(uint256(_input)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

interface IUniswapV3Pool {
    function slot0() external view returns (uint160 sqrtPriceX96, int24, uint16, uint16, uint16, uint8, bool);
    function liquidity() external view returns (uint128);
    function tickBitmap(int16 wordPosition) external view returns (uint256);
    function tickSpacing() external view returns (int24);
    function fee() external view returns (uint24);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function ticks(int24 tick) external view returns (uint128 liquidityGross, int128 liquidityNet, uint256 feeGrowthOutside0X128, uint256 feeGrowthOutside1X128, int56 tickCumulativeOutside, uint160 secondsPerLiquidityOutsideX128, uint32 secondsOutside, bool initialized);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

interface IUniswapV2Pool {
    function getReserves() external view returns (uint256 reserve0, uint256 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IV3Quoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

enum SwapKind { GIVEN_IN, GIVEN_OUT }

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
}

enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

interface IBalancerV2Vault {
    function batchSwap(SwapKind kind, BatchSwapStep[] calldata swaps, address[] calldata assets, FundManagement calldata funds, int256[] calldata limits, uint256 deadline) external returns (int256[] memory assetDeltas);
    function queryBatchSwap(SwapKind kind, BatchSwapStep[] calldata swaps, address[] calldata assets, FundManagement calldata funds) external returns (int256[] memory assetDeltas);
    function swap(SingleSwap calldata singleSwap, FundManagement calldata funds, uint256 limit, uint256 deadline) external returns (uint256 amountCalculatedInOut);
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
    function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IBalancerV2WeightedPool {
    function getNormalizedWeights() external view returns (uint256[] memory);
    function getSwapFeePercentage() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IBalancerV2StablePool {
    function getAmplificationParameter() external view returns (uint256 value, bool isUpdating, uint256 precision);
    function getSwapFeePercentage() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;


interface ICurvePool {
  function coins(uint256 n) external view returns (address);
  function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
  function exchange(int128 i, int128 j, uint256 _dx, uint256 _min_dy) external returns (uint256);
  function get_virtual_price() external view returns (uint256);
  function get_balances() external view returns (uint256[] memory);
  function fee() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

// Uniswap V3 simulation query
struct TickNextWithWordQuery{
    address pool;
    int24 tick;
    int24 tickSpacing;
    bool lte;
}
	
struct UniV3SortPoolQuery{
    address _pool;
    address _token0;
    address _token1;
    uint24 _fee;
    uint256 amountIn;
    bool zeroForOne;
}

interface IUniswapV3Simulator {
    function simulateUniV3Swap(address _pool, address _token0, address _token1, bool _zeroForOne, uint24 _fee, uint256 _amountIn) external view returns (uint256);
    function checkInRangeLiquidity(UniV3SortPoolQuery memory _sortQuery) external view returns (bool, uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

struct ExactInQueryParam{
    address tokenIn;
    address tokenOut;
    uint256 balanceIn;
    uint256 weightIn;
    uint256 balanceOut;
    uint256 weightOut;
    uint256 amountIn;
    uint256 swapFeePercentage;
}

struct ExactInStableQueryParam{
    address[] tokens;
    uint256[] balances;
    uint256 currentAmp;
    uint256 tokenIndexIn;
    uint256 tokenIndexOut;
    uint256 amountIn;
    uint256 swapFeePercentage;
}

interface IBalancerV2Simulator {
    function calcOutGivenIn(ExactInQueryParam memory _query) external view returns (uint256);
    function calcOutGivenInForStable(ExactInStableQueryParam memory _query) external view returns (uint256);
}