// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "v2-periphery/interfaces/IUniswapV2Router01.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TPSwapManager {
    address private _router;
    address private _treasury;
    address private _stable;
    uint private _feePercentage;

    constructor(
        address router,
        address treasury,
        address stable
    ) {
        _router = router;
        _treasury = treasury;
        _stable = stable;
        _feePercentage = 100;
    }

    function getFeeExactTokensForTokens(uint amountIn, address[] calldata path) external view returns (uint fee) {
        if (path[0] == _stable) {
            fee = _calculateFeeIn(amountIn);
        } else if (path[path.length - 1] == _stable) {
            uint[] memory amounts = IUniswapV2Router01(_router).getAmountsOut(amountIn, path);
            fee = _calculateFeeOut(amounts[amounts.length - 1]);
        }
    }

    function getFeeTokensForExactTokens(uint amountOut, address[] calldata path) external view returns (uint fee) {
        if (path[0] == _stable) {
            uint[] memory swapAmounts = IUniswapV2Router01(_router).getAmountsIn(amountOut, path);
            fee = _calculateFeeIn(swapAmounts[0]);
        } else if (path[path.length - 1] == _stable) {
            fee = _calculateFeeOut(amountOut);
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path[0] == _stable || path[path.length - 1] == _stable, "");
        _preSwap(path[0], msg.sender, amountIn); //TBD: use _msgSender?

        if (path[0] == _stable) {
            uint fee = _calculateFeeIn(amountIn);
            // amountIn is exact-swap-amount so fee goes to treasury directly
            require(IERC20(path[0]).transferFrom(msg.sender, _treasury, fee), "");
        }

        amounts = _swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);

        if (path[path.length - 1] == _stable) {
            uint fee = _calculateFeeOut(amounts[amounts.length - 1]);
            // amounts[amounts.length - 1] is exact-swap-amount so fee goes to treasury directly
            require(IERC20(path[path.length - 1]).transfer(_treasury, fee), "");
        }

        _postSwap(path, msg.sender);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path[0] == _stable || path[path.length - 1] == _stable, "");
        _preSwap(path[0], msg.sender, amountInMax); //TBD: use _msgSender?

        if (path[0] == _stable) {
            uint[] memory swapAmounts = IUniswapV2Router01(_router).getAmountsIn(amountOut, path);
            uint fee = _calculateFeeIn(swapAmounts[0]);
            // swapAmounts[0] is exact-swap-amount so fee goes to treasury directly
            require(IERC20(path[0]).transferFrom(msg.sender, _treasury, fee), "");
        }

        amounts = _swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);

        if (path[path.length - 1] == _stable) {
            uint fee = _calculateFeeOut(amounts[amounts.length - 1]);
            // stableAmount is exact-swap-amount so fee goes to treasury directly
            require(IERC20(path[path.length - 1]).transfer(_treasury, fee), "");
        }

        _postSwap(path, msg.sender);
    }

    function _preSwap(
        address tokenIn,
        address account,
        uint amountIn
    ) internal {
        _chargeToken(tokenIn, account, amountIn);
        _approveToken(tokenIn, _router, amountIn);
    }

    function _postSwap(address[] calldata path, address to) internal {
        _emptyTokens(path, to);
        _approveToken(path[0], _router, 0);
    }

    // **** SWAP ****
    // TBD: check we dont want ETH-swaps
    function _swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) internal returns (uint[] memory amounts) {
        return IUniswapV2Router01(_router).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    function _swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) internal returns (uint[] memory amounts) {
        return IUniswapV2Router01(_router).swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline);
    }

    function _emptyTokens(address[] calldata path, address to) internal {
        for (uint i; i < path.length; i++) {
            IERC20 token = IERC20(path[i]);
            uint balance = token.balanceOf(address(this));
            if (balance > 0) IERC20(path[i]).transfer(to, balance);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint amount
    ) internal {
        IERC20(token).approve(spender, amount);
    }

    function _chargeToken(
        address token,
        address from,
        uint amount
    ) internal {
        require(IERC20(token).transferFrom(from, address(this), amount), "");
    }

    function _calculateFeeIn(uint amount) internal view returns (uint fee) {
        fee = (amount * _feePercentage) / 10000;
    }

    function _calculateFeeOut(uint amount) internal view returns (uint fee) {
        fee = (_feePercentage * amount) / (10000 + _feePercentage);
    }
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