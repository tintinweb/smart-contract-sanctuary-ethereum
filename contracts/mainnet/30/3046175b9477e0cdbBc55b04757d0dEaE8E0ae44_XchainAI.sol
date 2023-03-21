/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

/*
 * Xchain AI (XAI)
 *
 * Revolutionizing AI Experience with Xchain
 *
 * Website: https://xchainai.com/
 * Twitter: https://twitter.com/Xchainaicom/
 * Telegram: https://t.me/xchainai/
 *
 * By Studio L, Legacy Capital Division
 * https://legacycapital.cc/
*/

// SPDX-License-Identifier: MIT

// File: StudioL/XChain_AI/interface/IPairV2.sol



pragma solidity ^0.8.0;

interface IPairV2 {
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
}
// File: StudioL/XChain_AI/interface/IOKCDexRouterV1.sol


pragma solidity ^0.8.0;

// FACTORY CA: 0x7b9f0a56ca7d20a44f603c03c6f45db95b31e539
interface IOKCDexRouterV1 {
    function factory() external pure returns (address);

    function WOKT() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityOKT(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountOKTMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountOKT, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityOKT(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountOKTMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountOKT);

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

    function removeLiquidityOKTWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountOKTMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountOKT);

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

    function swapExactOKTForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactOKT(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForOKT(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapOKTForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function removeLiquidityOKTSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountOKTMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOKT);

    function removeLiquidityOKTWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountOKTMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountOKT);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactOKTForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForOKTSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
// File: StudioL/XChain_AI/interface/ICANTODexRouterV1.sol


pragma solidity ^0.8.0;

// FACTORY CA: 0xE387067f12561e579C5f7d4294f51867E0c1cFba
interface ICANTODexRouterV1 {
    function factory() external pure returns (address);

    function wcanto() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityCANTO(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountCANTOMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountCANTO, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityCANTO(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountCANTOMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountCANTO);

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

    function removeLiquidityCANTOWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountCANTOMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountCANTO);

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

    function swapExactCANTOForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactCANTO(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForCANTO(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapCANTOForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

}
// File: StudioL/XChain_AI/interface/IAVAXTJDexRouterV1.sol


pragma solidity ^0.8.0;

// FACTORY CA: 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10
interface IAVAXTJDexRouterV1 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountAVAX, uint256 liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}
// File: StudioL/XChain_AI/interface/IDexRouterV2.sol


pragma solidity ^0.8.0;

interface IDexRouterV2 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: StudioL/XChain_AI/interface/IFactoryV2.sol


pragma solidity ^0.8.0;

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
}
// File: StudioL/XChain_AI/interface/IPoolV3.sol


pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IPoolV3 {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}
// File: StudioL/XChain_AI/interface/IDexRouterV3.sol


pragma solidity ^0.8.0;

interface IDexRouterV3 {
    function factory() external pure returns (address);

    function WETH9() external pure returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as ExactInputSingleParams in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint deadline;
        uint amountIn;
        uint amountOutMinimum;
    }

    /// @notice Swaps amountIn of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as ExactInputParams in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint amountOut);

    function swapExactTokensForTokens (
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable;

    function swapTokensForExactTokens (
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable;
}

// File: StudioL/XChain_AI/interface/IFactoryV3.sol


pragma solidity ^0.8.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IFactoryV3 {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}
// File: StudioL/XChain_AI/lib/TransferHelper.sol


// Customized by StudioL

pragma solidity >=0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
        return success;
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
        return success;
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
        return success;
    }

    function safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
        return success;
    }
}

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

// File: StudioL/XChain_AI/AutoLiqSnSW_MaxWlt_Pausable_01_01.sol

/*
 * Xchain AI (XCAI)
 *
 * Revolutionizing AI Experience with Xchain
 *
 * Website: https://xchainai.com/
 * Twitter: https://twitter.com/Xchainaicom/
 * Telegram: https://t.me/xchainai/
 *
 * By Studio L, Legacy Capital Division
 * https://legacycapital.cc/
*/


pragma solidity >=0.8.0 <0.9.0;












interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IAntiBot {
    function authorizeRequestAB(address _tokenAddr) external;
    function checkAuthorized(address tokenCA) external returns (bool);
    function setProtections(
        address pairCA,
        bool antiSnipe,
        bool antiBlock,
        uint8 snipeBlockAmt,
        uint32 snipeBlockTime
    ) payable external returns (bool);
    function getProtTokenLPPoolProtectionStatus(address poolCA) external view returns (bool antiSnipe_, bool antiBlock_);
    function setLaunch(
        address lpPairCA,
        address pairedCoinCA,
        address dexCA,
        bool V2orV3,
        uint256 tradingEnabledBlock,
        uint256 tradingEnabledTime
    ) external returns (bool);
    function sniperProtection(
        address poolCA,
        address from,
        address to,
        bool buy,
        bool sell
    ) external returns (bool sniperTest, bool protectionSwitch);
    function sdwchBotProtection(address poolCA, address from, address to, bool buy, bool sell) external returns (bool);
}

interface ILPLocker {
    function setContractSwapSettings(uint256 _swapAmount) external returns (bool);
    function setDevelopmentWallet(address _development) external returns (bool);
    function setMarketingWallet(address _marketing) external returns (bool);
    function swapTokensAddNativeLiquidity(
        bool V2orV3,
        address pairedCoinCA
    ) external returns (
        bool success_
    );
    function swapTokensNonNative(
        bool V2orV3,
        address pairedCoinCA
    ) external returns (
        bool success_
    );
}

contract XchainAI is IERC20, Context {

    uint16 constant DIVISOR = 10000;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

//Token Variables
    string constant private _name = "XchainAI";
    string constant private _symbol = "XAI";

    uint64 constant private startingSupply = 100_000_000_000; //100 Billion, underscores aid readability
    uint8 constant private _decimals = 18;

    uint256 constant private _tTotal = startingSupply * (10 ** _decimals);

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

//Router, LP Pair Variables
    address private dexRouterCA;
    address constant public dexRouterV2CA = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IDexRouterV2 constant public dexRouterV2 = IDexRouterV2(dexRouterV2CA);
    address constant public dexRouterV3CA = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    address private _poolCA;
    address constant public NATIVECOIN = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    mapping (address => LPool[]) private liqPoolList;
    //LP Pairs
    struct LPool {
        address poolCA;
        address pairedCoinCA;
        address dexCA;
        bool V2orV3;
        bool tradingEnabled;
        bool liqAdded;
        bool sniperProtection;
        bool sdBotProtection;
        uint8 snipeBlockAmt;
        uint32 snipeBlockTime;
        uint32 tradingEnabledBlock;
        uint32 tradingEnabledTime;
        uint32 tradingPauseTime;
        uint32 tradingPausedTimestamp;
    }
    mapping (address => bool) private isLiqPool;

    event NewLPCreated(address DexRouterCA, address LPCA, address PairedCoinCA);

    bool public launched = false;
    bool private contractSwapEnabled = false;
    uint256 private swapThreshold;
    uint256 private swapAmount;

    uint32 constant private maxTradePauseTime = 30 days;
    event TradeEnabled(address Setter, address PoolCA, uint256 EnabledBlock, uint256 EnabledTime);
    event TradePaused(address Setter, address PoolCA, uint256 PausedBlock, uint32 PauseTime, uint256 DisabledTimestamp);

//Fee Variables

    struct Taxes {
        uint16 buyTax;
        uint16 sellTax;
    }

    Taxes private _taxes = Taxes({
        buyTax: 1600,
        sellTax: 1600
        });

    struct Ratios {
        uint16 liquidity;
        uint16 dvelopmnt;
        uint16 marketing;
        uint16 totalTax;
    }

    Ratios private _ratiosBuy = Ratios({
        liquidity: 100,
        dvelopmnt: 400,
        marketing: 100,
        totalTax: 600
        });

    Ratios private _ratiosSell = Ratios({
        liquidity: 100,
        dvelopmnt: 400,
        marketing: 100,
        totalTax: 600
        });

    Ratios private _ratiosTransfer = Ratios({
        liquidity: 0,
        dvelopmnt: 0,
        marketing: 0,
        totalTax: 0
        });

    Ratios private _ratiosActive = Ratios({
        liquidity: 100,
        dvelopmnt: 400,
        marketing: 100,
        totalTax: 600
        });

    uint16 constant public maxBuyTaxes = 1900;
    uint16 constant public maxSellTaxes = 1900;
    uint16 constant public maxRoundtripFee = 3800;

    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;


    struct TaxWallets {
        address lpLocker;
        address development;
        address marketing;
    }

    TaxWallets private _taxWallets = TaxWallets({
        lpLocker: _owner,
        development: _owner,
        marketing: _owner
    });

    event TaxesUpdated(address Setter, uint16 BuyTax, uint16 SellTax, uint256 Timestamp);
    event BuyRatiosUpdated(address Setter, uint16 Liquidity, uint16 Development, uint16 Marketing, uint16 Total, uint256 Timestamp);
    event SellRatiosUpdated(address Setter, uint16 Liquidity, uint16 Development, uint16 Marketing, uint16 Total, uint256 Timestamp);

    event ETHWithdrawn(address Withdrawer, address Recipient, uint256 ETHamount);
    event StuckTokensWithdrawn(address Withdrawer, address Recipient, uint256 TokenAmount);

//Tx & Wallet Variables

    uint256 private _maxWalletSize = (_tTotal * 100) / DIVISOR; // 1%

    //Contract Swap
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool public inSwap;
    address[] private contractSwapPath = [ address(this), address(0) ];

    event MaxWalletUpdated(address Setter, uint256 indexed OldMaxWallet, uint256 indexed NewMaxWallet, uint256 Timestamp);

    event ContractSwapEnabledUpdated(bool Enabled);
    event ContractSwapSettingsUpdated(uint256 SwapThreshold, uint256 SwapAmount);
    event AutoLiquify(uint256 TokensSold, address CurrencyCoin, uint256 Timestamp);

//AntiBot

    IAntiBot private antiSnipe;
    address private antiBotCA;

    bool public initialized = false;
    bool public botProtection = false;

    event SniperProtectionTimeElapsed(address ProtectionSwitch, uint256 offBlock, uint256 offTime);

//Owner

    address private _owner;
    event OwnerSet(address Setter, address indexed OldOwner, address indexed NewOwner);

    // ============================================== Constructor ==============================================

    constructor (
        bool _V2orV3,
        bool _pairedIsNative,
        address _LPTargetCoinCA,
        address _lpLocker,
        address _development,
        address _marketing
    ) {
        _owner = _msgSender();

        _taxWallets.lpLocker = _lpLocker;
        _isExcludedFromFees[_lpLocker] = true;
        _isExcludedFromLimits[_lpLocker] = true;
        _liquidityHolders[_lpLocker] = true;
        _allowances[ address(this) ][_lpLocker] = type(uint256).max;
        _allowances[_lpLocker][ address(this) ] = type(uint256).max;
        _allowances[_lpLocker][dexRouterV2CA] = type(uint256).max;
        _allowances[dexRouterV2CA][_lpLocker] = type(uint256).max;
        _allowances[_lpLocker][dexRouterV3CA] = type(uint256).max;
        _allowances[dexRouterV3CA][_lpLocker] = type(uint256).max;

        _taxWallets.development = _development;
        _isExcludedFromFees[_development] = true;
        _isExcludedFromLimits[_development] = true;

        _taxWallets.marketing = _marketing;
        _isExcludedFromFees[_marketing] = true;
        _isExcludedFromLimits[_marketing] = true;

        setNewLiquidityPool(_V2orV3, _LPTargetCoinCA, _pairedIsNative);

        _isExcludedFromFees[_msgSender()] = true;
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromLimits[_msgSender()] = true;
        _isExcludedFromLimits[_owner] = true;
        _isExcludedFromLimits[address(this)] = true;
        _liquidityHolders[_msgSender()] = true;
        _liquidityHolders[_owner] = true;

        _tOwned[_msgSender()] = _tTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // ============================================== Modifiers ==============================================

    modifier onlyOwner() {
        require(_msgSender() == _owner);
        _;
    }

    modifier onlyLPLocker() {
        require(_msgSender() == _taxWallets.lpLocker ||
                _msgSender() == address(this)
               );
        _;
    }

//===============================================================================================================
//Override Functions

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) external view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][_msgSender()] != type(uint256).max) {
            require(_allowances[sender][ _msgSender() ] >= amount, "ERC20: transfer amount exceeds allowance");
            _approve(sender, _msgSender(), _allowances[sender][ _msgSender() ] - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

//===============================================================================================================
//Common Functions

    function rescueStuckAssets(bool ethOrToken, address tokenCA, uint256 amt, address receivable) external onlyOwner {
        require(amt <= contractBalanceInWei(ethOrToken, tokenCA));
        bool sent;
        if (ethOrToken){
            sent = TransferHelper.safeTransferETH(receivable, amt);
            require(sent, "StudioL: Tx failed");
            emit ETHWithdrawn(_msgSender(), receivable, amt);
        } else {
            sent = TransferHelper.safeTransfer(tokenCA, receivable, amt);
            require(sent, "StudioL: Tx failed");
            emit StuckTokensWithdrawn(_msgSender(), receivable, amt);
        }
    }

    function contractBalanceInWei(bool ethOrToken, address tokenCA) public view returns (uint256) {
        if (ethOrToken){
            return address(this).balance;
        } else {
            return IERC20(tokenCA).balanceOf(address(this));
        }
    }

    receive() payable external {}

    function multiSendTokens(address[] memory accounts, uint256[] memory amountsInWei) external onlyOwner {
        require(accounts.length == amountsInWei.length, "StudioL_Token: Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[ _msgSender() ] >= amountsInWei[i]);
            _transfer(_msgSender(), accounts[i], amountsInWei[i]);
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

//===============================================================================================================
//Dex Router and LPool Manager Functions

    function setNewLiquidityPool(bool _V2orV3, address _LPTargetCoinCA, bool _pairedIsNative) public onlyOwner {
        if(_pairedIsNative == false){
            require(_LPTargetCoinCA != address(0), "StudioL_Token: Must Provide LP Target Token Contract Address!");
        }
        _isExcludedFromFees[dexRouterV2CA] = true;
        _isExcludedFromLimits[dexRouterV2CA] = true;
        _liquidityHolders[dexRouterV2CA] = true;

        _allowances[ _msgSender() ][dexRouterV2CA] = type(uint256).max;
        _allowances[dexRouterV2CA][ _msgSender() ] = type(uint256).max;
        _allowances[_owner][dexRouterV2CA] = type(uint256).max;
        _allowances[dexRouterV2CA][_owner] = type(uint256).max;
        _allowances[ address(this) ][dexRouterV2CA] = type(uint256).max;
        _allowances[dexRouterV2CA][ address(this) ] = type(uint256).max;

        _isExcludedFromFees[dexRouterV3CA] = true;
        _isExcludedFromLimits[dexRouterV3CA] = true;
        _liquidityHolders[dexRouterV3CA] = true;

        _allowances[ _msgSender() ][dexRouterV3CA] = type(uint256).max;
        _allowances[dexRouterV3CA][ _msgSender() ] = type(uint256).max;
        _allowances[_owner][dexRouterV3CA] = type(uint256).max;
        _allowances[dexRouterV3CA][_owner] = type(uint256).max;
        _allowances[ address(this) ][dexRouterV3CA] = type(uint256).max;
        _allowances[dexRouterV3CA][ address(this) ] = type(uint256).max;

        address lpCA;

        if(_V2orV3) {
            if(_pairedIsNative) {
                _LPTargetCoinCA = NATIVECOIN;
            }
            lpCA = IFactoryV2( IDexRouterV2(dexRouterV2CA).factory() ).getPair( _LPTargetCoinCA, address(this) );
            require(lpCA == address(0) && !isLiqPool[lpCA], "StudioL_Token: Pair already exists!");
            lpCA = IFactoryV2( IDexRouterV2(dexRouterV2CA).factory() ).createPair( _LPTargetCoinCA, address(this) );
        } else {
            if(_pairedIsNative) {
                _LPTargetCoinCA = NATIVECOIN;
            }
            lpCA = IFactoryV3( IDexRouterV3(dexRouterV3CA).factory() ).getPool( _LPTargetCoinCA, address(this), 3000 );
            require(lpCA == address(0) && !isLiqPool[lpCA], "StudioL_Token: Pool already exists!");
            lpCA = IFactoryV3( IDexRouterV3(dexRouterV3CA).factory() ).createPool( _LPTargetCoinCA, address(this), 3000 );
        }

        if(_V2orV3) {
            dexRouterCA = dexRouterV2CA;
        } else {
            dexRouterCA = dexRouterV3CA;
        }
        liqPoolList[ address(this) ].push( LPool( lpCA, _LPTargetCoinCA, dexRouterCA, _V2orV3, false, false, false, false, 0, 0, 0, 0, 0, 0) );

        isLiqPool[lpCA] = true;

        _allowances[lpCA][ _msgSender() ] = type(uint256).max;
        _allowances[ _msgSender() ][lpCA] = type(uint256).max;
        _allowances[lpCA][dexRouterCA] = type(uint256).max;
        _allowances[dexRouterCA][lpCA] = type(uint256).max;

        IERC20(lpCA).approve(dexRouterCA, type(uint256).max);

        emit NewLPCreated(dexRouterCA, lpCA, _LPTargetCoinCA);
    }

    function searchLiqPool(address pool) private view returns (uint8) {
        LPool[] memory poolInfo = liqPoolList[ address(this) ];

        for(uint8 i = 0; i < poolInfo.length; i++) {
            if(poolInfo[i].poolCA == pool) {return i;}
        }
        return type(uint8).max;
    }

    function getAllLiqPoolsData() external view returns (LPool[] memory) {
        return liqPoolList[ address(this) ];
    }

    function getLiqPoolsCount() external view returns (uint256) {
        return liqPoolList[ address(this) ].length;
    }

    function verifyLiqPool(address _ca) external view returns (bool) {
        return isLiqPool[_ca];
    }

//===============================================================================================================
//Antisniper Functions

    function requestProtection(address _antiBotCA) external onlyOwner returns (bool) {
        require(_antiBotCA != address(this), "StudioL_Token: Can't be self.");
        require(_antiBotCA.code.length > 0, "StudioL_Token: Can't be non-contract.");
        bool requested = false;
        antiSnipe = IAntiBot(_antiBotCA);
        antiBotCA = _antiBotCA;
        try antiSnipe.authorizeRequestAB( address(this) ) {
            requested = true;
        } catch {
            revert();
        }
        require(requested, "StudioL_Token: failed to request protection.");

        return requested;
    }

    function setProtection(
        address poolCA,
        bool _antiSWBot,
        bool _antiSnipe,
        uint8 snipeBlockAmt,
        uint32 snipeBlockTimeInSecs
    ) payable external onlyOwner returns (bool) {
        LPool storage poolInfo = liqPoolList[ address(this) ][ searchLiqPool(poolCA) ];
        bool checked = false;
        if(!initialized) {
            initialized = antiSnipe.checkAuthorized( address(this) );
        }
        if(_antiSnipe || _antiSWBot) {
            bool antiSnipe_;
            bool antiSw_;
            (antiSnipe_, antiSw_) = antiSnipe.getProtTokenLPPoolProtectionStatus(poolCA);
            if(antiSnipe_ != _antiSnipe || antiSw_ != _antiSWBot) {
                require(initialized, "StudioL_Token: protection request not authorized yet.");

                checked = antiSnipe.setProtections{value: msg.value}(
                    poolCA,
                    _antiSnipe,
                    _antiSWBot,
                    snipeBlockAmt,
                    snipeBlockTimeInSecs
                );
                require(checked, "StudioL_Token: failed to set protection.");
            }
            botProtection = true;

            _isExcludedFromFees[antiBotCA] = true;
            _isExcludedFromLimits[antiBotCA] = true;
            _allowances[poolCA][antiBotCA] = type(uint256).max;
            _allowances[antiBotCA][poolCA] = type(uint256).max;
            _allowances[antiBotCA][dexRouterV2CA] = type(uint256).max;
            _allowances[antiBotCA][dexRouterV3CA] = type(uint256).max;
        } else {
            botProtection = false;
        }
        poolInfo.sniperProtection = _antiSnipe;
        poolInfo.sdBotProtection = _antiSWBot;
        poolInfo.snipeBlockAmt = snipeBlockAmt;
        poolInfo.snipeBlockTime = snipeBlockTimeInSecs;
    
        return checked;
    }

    function enableTrading(address poolCA) external onlyOwner {
        LPool storage poolInfo = liqPoolList[ address(this) ][ searchLiqPool(poolCA) ];
        if(poolInfo.tradingPauseTime != 0) {
            poolInfo.tradingEnabled = true;
            poolInfo.tradingPauseTime = 0;
        } else {
            require(poolInfo.liqAdded, "StudioL_Token: Liquidity must be added.");
            require(poolInfo.tradingEnabled != true, "StudioL_Token: trading already enabled.");

            if(poolInfo.sniperProtection || poolInfo.sdBotProtection) {
                bool checked = antiSnipe.setLaunch(
                    poolCA,
                    poolInfo.pairedCoinCA,
                    poolInfo.dexCA,
                    poolInfo.V2orV3,
                    block.number,
                    block.timestamp
                );
                require(checked, "StudioL_Token: set launch tx failed.");
            }

            launched = true;
            poolInfo.tradingEnabled = true;
            poolInfo.tradingEnabledBlock = uint32(block.number);
            poolInfo.tradingEnabledTime = uint32(block.timestamp);

            setContractSwapSettings(true, 10, 11);
            // swapThreshold = (_tTotal * 10) / 10000; //0.1%
            // swapAmount = (_tTotal * 11) / 10000; //0.11%
        }
        emit TradeEnabled(_msgSender(), poolCA, block.number, block.timestamp);
    }

    function pauseTradeByPool(address[] calldata poolCA, bool pauseAllPools, uint32 pauseTimeInSecs) external onlyOwner {
        require(pauseTimeInSecs <= maxTradePauseTime, "StudioL_Token: cannot pause longer than max trade pause time.");
        LPool[] storage poolInfo = liqPoolList[ address(this) ];
        if(pauseAllPools) {
            for(uint8 i = 0; i < poolInfo.length; i++) {
                require(block.timestamp > 1 days + poolInfo[i].tradingPausedTimestamp, "StudioL_Token: can't pause again until cooldown is over.");
                poolInfo[i].tradingEnabled = false;
                poolInfo[i].tradingPauseTime = pauseTimeInSecs;
                poolInfo[i].tradingPausedTimestamp = uint32(block.timestamp);
                emit TradePaused(_msgSender(), poolInfo[i].poolCA, block.number, pauseTimeInSecs, block.timestamp);
            }
        } else {
            for(uint8 i = 0; i < poolCA.length; i++) {
                uint8 index = searchLiqPool(poolCA[i]);
                require(block.timestamp > 1 days + poolInfo[index].tradingPausedTimestamp, "StudioL_Token: can't pause again until cooldown is over.");
                poolInfo[index].tradingEnabled = false;
                poolInfo[index].tradingPauseTime = pauseTimeInSecs;
                poolInfo[index].tradingPausedTimestamp = uint32(block.timestamp);
                emit TradePaused(_msgSender(), poolCA[i], block.number, pauseTimeInSecs, block.timestamp);
            }
        }
    }

    function getMaxTradePauseTimeInDays() external pure returns (uint32) {
        return maxTradePauseTime / 1 days;
    }

    function getRemainingPauseTimeInSecs(address poolCA) public view returns (uint256) {
        uint8 index = searchLiqPool(poolCA);
        if(liqPoolList[ address(this) ][index].tradingPauseTime + liqPoolList[ address(this) ][index].tradingPausedTimestamp > block.timestamp) {
            return liqPoolList[ address(this) ][index].tradingPauseTime + liqPoolList[ address(this) ][index].tradingPausedTimestamp - block.timestamp;
        } else {
            return 0;            
        }
    }

//===============================================================================================================
//Fee Settings

//Set Fees and its Ratios
    function setTaxes(
        uint16 _buyTax,
        uint16 _sellTax,
        uint16 _liquidityBuy,
        uint16 _developmentBuy,
        uint16 _marketingBuy,
        uint16 _liquiditySell,
        uint16 _developmentSell,
        uint16 _marketingSell
    ) external onlyLPLocker returns (bool) {

        _taxes.buyTax = _buyTax;
        _taxes.sellTax = _sellTax;

        emit TaxesUpdated(_msgSender(), _buyTax, _sellTax, block.timestamp);
        setBuyRatios(_liquidityBuy, _developmentBuy, _marketingBuy);
        setSellRatios(_liquiditySell, _developmentSell, _marketingSell);
        return true;
    }

    function setBuyRatios(uint16 _liquidity, uint16 _development, uint16 _marketing) private {
        {
        _ratiosBuy.liquidity = _liquidity;
        _ratiosBuy.dvelopmnt = _development;
        _ratiosBuy.marketing = _marketing;
        _ratiosBuy.totalTax = _ratiosBuy.liquidity + _ratiosBuy.dvelopmnt + _ratiosBuy.marketing;
        }
        emit BuyRatiosUpdated(_msgSender(), _ratiosBuy.liquidity, _ratiosBuy.dvelopmnt, _ratiosBuy.marketing, _ratiosBuy.totalTax, block.timestamp);
    }

    function setSellRatios(uint16 _liquidity, uint16 _development, uint16 _marketing) private {
        {
        _ratiosSell.liquidity = _liquidity;
        _ratiosSell.dvelopmnt = _development;
        _ratiosSell.marketing = _marketing;
        _ratiosSell.totalTax = _ratiosSell.liquidity + _ratiosSell.dvelopmnt + _ratiosSell.marketing;
        }
        emit SellRatiosUpdated(_msgSender(), _ratiosSell.liquidity, _ratiosSell.dvelopmnt, _ratiosSell.marketing, _ratiosSell.totalTax, block.timestamp);
    }

    function getTaxesAndRatios() external view returns (
        uint16 buyTax_,
        uint16 sellTax_,
        uint16 buyLiquidityRatio_,
        uint16 buyDevelopmentRatio_,
        uint16 buyMarketingRatio_,
        uint16 sellLiquidityRatio_,
        uint16 sellDevelopmentRatio_,
        uint16 sellMarketingRatio_
    ) {
        return (
            _taxes.buyTax,
            _taxes.sellTax,
            _ratiosBuy.liquidity,
            _ratiosBuy.dvelopmnt,
            _ratiosBuy.marketing,
            _ratiosSell.liquidity,
            _ratiosSell.dvelopmnt,
            _ratiosSell.marketing
        );
    }

//Contract Swap functions
    function setContractSwapSettings(bool _switch, uint8 swapThresholdBps, uint8 amountBps) public onlyOwner {
        contractSwapEnabled = _switch;
        swapThreshold = (_tTotal * swapThresholdBps) / 10000;
        swapAmount = (_tTotal * amountBps) / 10000;
        require(swapThreshold <= swapAmount, "StudioL_Token: Threshold cannot be above amount.");

        emit ContractSwapEnabledUpdated(_switch);
        emit ContractSwapSettingsUpdated(swapThreshold, swapAmount);

        bool success = ILPLocker(_taxWallets.lpLocker).setContractSwapSettings(swapAmount);
        require(success, "StudioL_Token: Update contract swap settings at LP Locker contract tx failed.");
    }

    function getContractSwapSettings() external view returns (bool contractSwapEnabled_, uint256 swapThreshold_, uint256 swapAmount_) {
        return (contractSwapEnabled, swapThreshold, swapAmount);
    }

//Fee wallet functions
    function setLPLocker(address _lpLocker) external onlyOwner {
        _taxWallets.lpLocker = _lpLocker;
        _isExcludedFromFees[_lpLocker] = true;
        _isExcludedFromLimits[_lpLocker] = true;
        _liquidityHolders[_lpLocker] = true;
        _allowances[ address(this) ][_lpLocker] = type(uint256).max;
        _allowances[_lpLocker][ address(this) ] = type(uint256).max;
        _allowances[_lpLocker][dexRouterV2CA] = type(uint256).max;
        _allowances[dexRouterV2CA][_lpLocker] = type(uint256).max;
        _allowances[_lpLocker][dexRouterV3CA] = type(uint256).max;
        _allowances[dexRouterV3CA][_lpLocker] = type(uint256).max;
    }

    function setDevelopmentWallet(address _development) external onlyOwner {
        _taxWallets.development = _development;
        _isExcludedFromFees[_development] = true;
        _isExcludedFromLimits[_development] = true;
        bool success = ILPLocker(_taxWallets.lpLocker).setDevelopmentWallet(_development);
        require(success, "StudioL_Token: Update Development Wallet at LP Locker contract tx failed.");
    }

    function setMarketingWallet(address _marketing) external onlyOwner {
        _taxWallets.marketing = _marketing;
        _isExcludedFromFees[_marketing] = true;
        _isExcludedFromLimits[_marketing] = true;
        bool success = ILPLocker(_taxWallets.lpLocker).setMarketingWallet(_marketing);
        require(success, "StudioL_Token: Update Marketing Wallet at LP Locker contract tx failed.");
    }

    function getFeeWallets() external view returns (address lpLocker_, address development_, address marketing_) {
        return (_taxWallets.lpLocker, _taxWallets.development, _taxWallets.marketing);
    }

//===============================================================================================================
//Tx & User Wallet Settings

    function setMaxWalletSize(uint16 bps) external onlyOwner {
        require(_maxWalletSize != 0, "StudioL_Token: Max Wallet cannot be set once it has been set to 0 to turn off.");
        require((_tTotal * bps) / DIVISOR >= (_tTotal / 100), "StudioL_Token: Max Wallet amt must be above 1% of total supply.");

        emit MaxWalletUpdated(_msgSender(), _maxWalletSize, _tTotal * bps / DIVISOR, block.timestamp);
        _maxWalletSize = _tTotal * bps / DIVISOR;
    }

    function getMaxWalletSize() external view returns (uint256) {
        return _maxWalletSize;
    }

    function setExcludedFromFees(address account, bool _switch) external onlyOwner {
        _isExcludedFromFees[account] = _switch;
    }

    function setExcludedFromLimits(address account, bool _switch) external onlyOwner {
        _isExcludedFromLimits[account] = _switch;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[from]
            && !_liquidityHolders[to]
            && !_isExcludedFromLimits[from]
            && !_isExcludedFromLimits[to]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

//======================================================================================
//Transfer Functions

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "StudioL_Token: Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;

        if (isLiqPool[from]) {
            buy = true;
            _poolCA = from;
            _ratiosActive = _ratiosBuy;
        } else if (isLiqPool[to]) {
            sell = true;
            _poolCA = to;
            _ratiosActive = _ratiosSell;
        } else {
            other = true;
            _ratiosActive = _ratiosTransfer;
        }
        uint8 index = searchLiqPool(_poolCA);
        LPool memory poolInfo = liqPoolList[ address(this) ][index];

        if( _hasLimits(from, to) ) {
            if(poolInfo.tradingPauseTime != 0) {
                if( getRemainingPauseTimeInSecs(poolInfo.poolCA) == 0 ) {
                    liqPoolList[ address(this) ][index].tradingEnabled = true;
                    liqPoolList[ address(this) ][index].tradingPauseTime = 0;
                }
            }
            require(liqPoolList[ address(this) ][index].tradingEnabled, "StudioL_Token: Trading not enabled!");
            bool checked;

            if(poolInfo.sniperProtection) {
                try antiSnipe.sniperProtection(poolInfo.poolCA, from, to, buy, sell)
                returns (bool tested, bool protection) {
                    checked = tested;
                    liqPoolList[ address(this) ][index].sniperProtection = protection;
                } catch {
                    revert();
                }
                if(!checked) {
                    if(buy) {
                        _allowances[to][antiBotCA] = type(uint256).max;
                    } else {
                        require(checked, "StudioL_AntiBot: Sniper Rejected");
                    }
                }
                if (!poolInfo.sniperProtection) {
                    emit SniperProtectionTimeElapsed(poolInfo.poolCA, block.number, block.timestamp);
                }
            }

            if(poolInfo.sdBotProtection) {
                try antiSnipe.sdwchBotProtection(poolInfo.poolCA, from, to, buy, sell)
                returns (bool tested) {
                    checked = tested;
                } catch {
                    revert();
                }
                if(!checked) {
                    if(buy) {
                        _allowances[to][antiBotCA] = type(uint256).max;
                    } else {
                        require(checked, "StudioL_AntiBot: Sandwich Bot Rejected");
                    }
                }
            }

            if(to != poolInfo.dexCA && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(_tOwned[to] + amount <= _maxWalletSize, "StudioL_Token: Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        if(contractSwapEnabled) {
            if(!inSwap) {
                if(!buy) {
                    if(_tOwned[_taxWallets.lpLocker] >= swapThreshold) {
                        contractSwap(poolInfo.V2orV3, poolInfo.pairedCoinCA);
                    }
                }
            }
        }

        // Check if this is the liquidity adding tx to startup.
        if(!poolInfo.liqAdded) {
            _checkLiquidityAdd(poolInfo.poolCA, from, to);
            if(!poolInfo.liqAdded && _hasLimits(from, to) && !other) {
                revert("StudioL_Token: Pre-liquidity transfer protection.");
            }
        }

        uint256 _transferAmount;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            _transferAmount = amount;
        } else {
            uint256 _feeAmount = amount * (_ratiosActive.liquidity + _ratiosActive.dvelopmnt + _ratiosActive.marketing) / DIVISOR;
            _transferAmount = amount - _feeAmount;
            _tOwned[from] -= _feeAmount;
            _tOwned[_taxWallets.lpLocker] += _feeAmount;
            emit Transfer(from, _taxWallets.lpLocker, _feeAmount);
        }

        _tOwned[from] -= _transferAmount;
        _tOwned[to] += _transferAmount;

        emit Transfer(from, to, _transferAmount);
    }

    function _checkLiquidityAdd(address poolAddr, address from, address to) internal {
        LPool storage poolInfo = liqPoolList[ address(this) ][ searchLiqPool(poolAddr) ];
        require(poolInfo.liqAdded == false, "StudioL_Token: Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == poolAddr) {
            _liquidityHolders[from] = true;
            poolInfo.liqAdded = true;
        }
    }

    function triggerContractSwap(bool poolIsV2orV3, address poolPairedCoinCA) external onlyOwner {
        contractSwap(poolIsV2orV3, poolPairedCoinCA);
    }

    function contractSwap(bool _V2orV3, address pairedCoinCA) private lockTheSwap {
        bool success;
        uint256 contractTokenBalance = _tOwned[_taxWallets.lpLocker];
        if(pairedCoinCA == NATIVECOIN) {
            success = ILPLocker(_taxWallets.lpLocker).swapTokensAddNativeLiquidity(_V2orV3, pairedCoinCA);
        } else {
            success = ILPLocker(_taxWallets.lpLocker).swapTokensNonNative(_V2orV3, pairedCoinCA);
        }
        emit AutoLiquify(contractTokenBalance, pairedCoinCA, block.timestamp);
        require(success, "StudioL_Token: AutoLiquidity tx failed");
    }

//===============================================================================================================
//Owner Settings

    function setOwner(address account) external onlyOwner {
        require(_owner != account, "StudioL_Token: Already set to the desired value");
        emit OwnerSet( _msgSender(), _owner, account);
        _owner = account;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

}