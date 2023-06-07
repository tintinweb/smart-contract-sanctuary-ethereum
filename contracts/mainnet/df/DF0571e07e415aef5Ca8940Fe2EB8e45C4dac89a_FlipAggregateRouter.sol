// SPDX-License-Identifier: MIT
//Twitter: https://twitter.com/FLIP_Tools

pragma solidity ^0.8.0;

import "./IUniswapV2Router02.sol";
import "./ISwapRouter.sol";
import "./IERC20.sol";
import "./IWETH.sol";

contract FlipAggregateRouter {
    error VersionNotSupported();

    address public zeroAdd;
    address public deadAdd = 0x000000000000000000000000000000000000dEaD;
    address public deployer;
    string public twitter = "https://twitter.com/FLIP_Tools";
    string public telegram;
    string public discord;

    mapping(uint256 => IUniswapV2Router02) public v2Routers;// 0 - Uniswap | 1 - Sushiswap
    mapping(uint256 => ISwapRouter) public v3Routers;// 0 - Uniswap | 2 - Camelot
    IWETH public weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    modifier activeDex(uint version, uint256 dexID) {
        address routerAdd;
        if (version == 2) {
            routerAdd = address(v2Routers[dexID]);
        } else if (version == 3) {
            routerAdd = address(v3Routers[dexID]);
        }
        require(routerAdd != zeroAdd,"Dex not active.");
        require(routerAdd != deadAdd,"Dex is blocked");
        _;
    }

    modifier onlyDep() {
        require(msg.sender == deployer,"Only Deployer");
        _;
    }

    constructor () {
        deployer = msg.sender;
        v2Routers[0] = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        v2Routers[1] = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
        v3Routers[0] = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        v3Routers[2] = ISwapRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    }

    receive() external payable {}

    function checkDexActive(uint version, uint256 dexID) external view returns (bool) {
        address routerAdd;
        if (version == 2) {
            routerAdd = address(v2Routers[dexID]);
        } else if (version == 3) {
            routerAdd = address(v3Routers[dexID]);
        }
        if (routerAdd != zeroAdd && routerAdd != deadAdd) {
            return true;
        } else {
            return false;
        }
    }

    function getRouter(uint version, uint256 dexID) external view returns (address) {
        if (version == 2) {
            return address(v2Routers[dexID]);
        } else if (version == 3) {
            return address(v3Routers[dexID]);
        } else {
            revert VersionNotSupported();
        }
    }

    function addRouter(uint version, uint256 dexID, address routerAdd) external onlyDep {
        if (version == 2) {
            require(address(v2Routers[dexID]) == address(0),"Dex already initiated.");
            v2Routers[dexID] = IUniswapV2Router02(routerAdd);
        } else if (version == 3) {
            require(address(v3Routers[dexID]) == address(0),"Dex already initiated.");
            v3Routers[dexID] = ISwapRouter(routerAdd);
        } else {
            revert VersionNotSupported();
        }
    }

    function blockRouter(uint version, uint256 dexID) external onlyDep activeDex(version, dexID) {
        if (version == 2) {
            v2Routers[dexID] = IUniswapV2Router02(deadAdd);
        } else if (version == 3) {
            v3Routers[dexID] = ISwapRouter(deadAdd);
        }
    }

    function setSocials(string memory _twitter, string memory _telegram, string memory _discord) external onlyDep {
        if (bytes(_twitter).length > 0) {
            twitter = _twitter;
        }
        if (bytes(_telegram).length > 0) {
            telegram = _telegram;
        }
        if (bytes(_discord).length > 0) {
            discord = _discord;
        }
    }

    function swapV2ETH(address token, uint256 amount, uint256 dexID, bool isSell) external payable activeDex(2, dexID) returns(uint[] memory amountsOut) {
        IUniswapV2Router02 router = v2Routers[dexID];
        address[] memory path = new address[](2);
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            path[0] = token;
            path[1] = address(weth);
            amountsOut = router.swapExactTokensForETH(
                amount,
                0,
                path,
                msg.sender,
                block.timestamp
            );
        } else {
            require(msg.value == amount,"Incorrect ETH");
            path[0] = address(weth);
            path[1] = token;
            amountsOut = router.swapExactETHForTokens{value: amount}(
                0,
                path,
                msg.sender,
                block.timestamp
            );
        }
    }

    function swapV2WETH(address token, uint256 amount, uint256 dexID, bool isSell) external activeDex(2, dexID) returns (uint[] memory amountsOut) {
        IUniswapV2Router02 router = v2Routers[dexID];
        address[] memory path = new address[](2);
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            path[0] = token;
            path[1] = address(weth);
        } else {
            weth.transferFrom(msg.sender, address(this), amount);
            weth.approve(address(router), amount);
            path[0] = address(weth);
            path[1] = token;
        }
        amountsOut = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function swapV3WETH(address token, uint256 amount, uint256 dexID, uint24 poolFee, bool isSell) external activeDex(3, dexID) returns (uint256 amountOut) {
        ISwapRouter router = v3Routers[dexID];
        ISwapRouter.ExactInputSingleParams memory params;
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(weth),
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        } else {
            weth.transferFrom(msg.sender, address(this), amount);
            weth.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: token,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        }
        amountOut = router.exactInputSingle(params);
    }

    function swapV3ETH(address token, uint256 amount, uint256 dexID, uint24 poolFee, bool isSell) external payable activeDex(3, dexID) returns (uint256 amountOut) {
        ISwapRouter router = v3Routers[dexID];
        ISwapRouter.ExactInputSingleParams memory params;
        if (isSell) {
            IERC20 Itoken = IERC20(token);
            Itoken.transferFrom(msg.sender, address(this), amount);
            Itoken.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: address(weth),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle(params);
            weth.withdraw(amountOut);
            payable(msg.sender).transfer(amountOut);
        } else {
            require(msg.value == amount,"Incorrect ETH sent");
            weth.deposit{value: amount}();
            weth.approve(address(router), amount);
            params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: token,
                fee: poolFee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
            amountOut = router.exactInputSingle(params);
        }
    }

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}