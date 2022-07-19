// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "v2-core/interfaces/IUniswapV2Pair.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";
import "v2-periphery/interfaces/IUniswapV2Router01.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract TPLiquidityManager {
    address private _router;

    constructor(address router) {
        _router = router;
    }

    function createPair(
        address vault,
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB,
        uint deadline
    ) external returns (address pair) {
        // check pair doesnt exist
        address factory = IUniswapV2Router01(_router).factory();
        require(IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0), "");
        // charges amounts from vault and approves
        _preAddLiquidity(vault, tokenA, tokenB, amountA, amountB);
        // addLiquidity using router
        uint liquidity = _addLiquidity(tokenA, tokenB, amountA, amountB, amountA, amountB, address(this), deadline);
        // disapproves and transfer liquidity to vault
        return _postAddLiquidity(tokenA, tokenB, vault, liquidity);
    }

    function addLiquidity(
        address vault,
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        uint deadline
    ) external {
        // check pair exists
        address factory = IUniswapV2Router01(_router).factory();
        require(IUniswapV2Factory(factory).getPair(tokenA, tokenB) != address(0), "");
        // charges amounts from vault and approves
        _preAddLiquidity(vault, tokenA, tokenB, amountADesired, amountBDesired);
        // addLiquidity using router
        uint liquidity = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );
        // disapproves and transfer liquidity to vault
        _postAddLiquidity(tokenA, tokenB, vault, liquidity);
    }

    function removeLiquidity(
        address vault,
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        uint deadline
    ) external {
        // charges lp token from vault and approves
        _preRemoveLiquidity(vault, tokenA, tokenB, liquidity);
        // removeLiquidity using router
        (uint amountA, uint amountB) = _removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            address(this),
            deadline
        );
        // dissapproves and transfer amounts to vault
        _postRemoveLiquidity(vault, tokenA, tokenB, amountA, amountB);
    }

    function _preAddLiquidity(
        address vault,
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) internal {
        // charges amounts from vault
        require(IERC20(tokenA).transferFrom(vault, address(this), amountA), "");
        require(IERC20(tokenB).transferFrom(vault, address(this), amountB), "");
        // approve tokens
        _approveToken(tokenA, _router, amountA);
        _approveToken(tokenB, _router, amountB);
    }

    function _postAddLiquidity(
        address tokenA,
        address tokenB,
        address vault,
        uint liquidity
    ) internal returns (address) {
        // disapprove tokens
        _approveToken(tokenA, _router, 0);
        _approveToken(tokenB, _router, 0);
        // transfer liquidity to vault
        address pair = _getPair(tokenA, tokenB);
        require(IUniswapV2Pair(pair).transfer(vault, liquidity), "");
        return pair;
    }

    function _preRemoveLiquidity(
        address vault,
        address tokenA,
        address tokenB,
        uint liquidity
    ) internal {
        address pair = _getPair(tokenA, tokenB);
        // charge lp token from vault
        IERC20(pair).transferFrom(vault, address(this), liquidity);
        // approve lp token
        IERC20(pair).approve(_router, liquidity);
    }

    function _postRemoveLiquidity(
        address vault,
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) internal {
        address pair = _getPair(tokenA, tokenB);
        // disapprove lp token
        _approveToken(pair, _router, 0);
        // transfer amounts to vault
        require(IUniswapV2Pair(tokenA).transfer(vault, amountA), "");
        require(IUniswapV2Pair(tokenB).transfer(vault, amountB), "");
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal returns (uint liquidity) {
        (, , liquidity) = IUniswapV2Router01(_router).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) internal returns (uint amountA, uint amountB) {
        (amountA, amountB) = IUniswapV2Router01(_router).removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    function _matchBalance(address token, uint amount) internal view returns (bool) {
        return IERC20(token).balanceOf(address(this)) == amount;
    }

    function _approveToken(
        address token,
        address spender,
        uint amount
    ) internal {
        IERC20(token).approve(spender, amount);
    }

    function _getPair(address tokenA, address tokenB) internal view returns (address) {
        address factory = IUniswapV2Router01(_router).factory();
        return IUniswapV2Factory(factory).getPair(tokenA, tokenB);
    }
}

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