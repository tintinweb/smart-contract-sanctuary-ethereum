// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/Ownable.sol";

contract ArbitrageBot is Ownable {

    constructor() {
    }

    address[] path;
    uint256 public MinPercentage = 20;
    uint256 public Percentage_Divider = 1000;

    function changeMinPercentage(uint256 Percentage) public onlyOwner {
        MinPercentage = Percentage;
    }

    function CalculatePercentage(uint256 amount) internal view returns (uint256) {
        uint256 MinToken = amount +
            ((MinPercentage * amount) / Percentage_Divider);
            return MinToken;
    }

    function CrossExchangeArbitrage(
        address router0,
        address router1,
        address token0,
        address token1,
        uint256 amount
    ) public payable onlyOwner {
        address WETH = IUniswapV2Router01(router0).WETH();

        if (token0 == WETH) {
            require(msg.value > 0, "insufficient funds for the transaction");
            swapETHtoToken(router0, token1, msg.value);

            IERC20(token1).approve(
                router1,
                IERC20(token1).balanceOf(address(this))
            );
            swapTokenToEth(
                router1,
                token1,
                IERC20(token1).balanceOf(address(this))
            );
        } else if (token1 == WETH) {
            require(amount > 0, "insufficient funds for the transaction");
            IERC20(token0).approve(
                router0,
                IERC20(token0).balanceOf(address(this))
            );
            swapTokenToEth(router0, token0, amount);

            swapETHtoToken(router1, token0, address(this).balance);
        } else {
            require(amount > 0, "insufficient funds for the transaction");
            IERC20(token0).approve(
                router0,
                IERC20(token0).balanceOf(address(this))
            );
            swap(router0, token0, token1, amount);
            IERC20(token1).approve(
                router1,
                IERC20(token1).balanceOf(address(this))
            );
            swap(
                router1,
                token1,
                token0,
                IERC20(token1).balanceOf(address(this))
            );
        }
    }

    function Trianglestrategy1(
        address router,
        address token0,
        address token1,
        address token2,
        uint256 amount
    ) public payable onlyOwner {
        address WETH = IUniswapV2Router01(router).WETH();
        if (token0 == WETH) {
            require(msg.value > 0, "insufficient funds for the transaction");
            swapETHtoToken(router, token1, msg.value);
            IERC20(token1).approve(
                router,
                IERC20(token1).balanceOf(address(this))
            );
            swap(
                router,
                token1,
                token2,
                IERC20(token1).balanceOf(address(this))
            );

            IERC20(token2).approve(
                router,
                IERC20(token2).balanceOf(address(this))
            );
            swapTokenToEth(
                router,
                token2,
                IERC20(token2).balanceOf(address(this))
            );
        } else if (token1 == WETH) {
            require(amount > 0, "insufficient funds for the transaction");
            swapTokenToEth(router, token0, amount);
            swapETHtoToken(router, token1, address(this).balance);
            IERC20(token1).approve(
                router,
                IERC20(token1).balanceOf(address(this))
            );
            swap(
                router,
                token1,
                token0,
                IERC20(token1).balanceOf(address(this))
            );
        } else if (token2 == WETH) {
            require(amount > 0, "insufficient funds for the transaction");
            swap(router, token0, token1, amount);
            IERC20(token1).approve(
                router,
                IERC20(token1).balanceOf(address(this))
            );
            swapTokenToEth(
                router,
                token1,
                IERC20(token1).balanceOf(address(this))
            );
            swapETHtoToken(router, token0, address(this).balance);
        } else {
            require(amount > 0, "insufficient funds for the transaction");
            swap(router, token0, token1, amount);
            IERC20(token1).approve(
                router,
                IERC20(token1).balanceOf(address(this))
            );
            swap(
                router,
                token1,
                token2,
                IERC20(token1).balanceOf(address(this))
            );
            IERC20(token2).approve(
                router,
                IERC20(token2).balanceOf(address(this))
            );
            swap(
                router,
                token2,
                token0,
                IERC20(token2).balanceOf(address(this))
            );
        }
    }

    function swap(
        address router,
        address tokenA,
        address tokenB,
        uint256 amount
    ) internal {
        path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        IUniswapV2Router01(router).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 300 seconds
        );
    }

    function swapETHtoToken(
        address router,
        address token,
        uint256 amount
    ) internal {
        path = new address[](2);
        path[0] = IUniswapV2Router01(router).WETH();
        path[1] = token;

        IUniswapV2Router01(router).swapExactETHForTokens{value: amount}(
            0,
            path,
            address(this),
            block.timestamp + 300 seconds
        );
    }

    function swapTokenToEth(
        address router,
        address token,
        uint256 amount
    ) internal {
        path = new address[](2);
        path[0] = token;
        path[1] = IUniswapV2Router01(router).WETH();

        IUniswapV2Router01(router).swapExactTokensForETH(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 300 seconds
        );
    }
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

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

abstract contract Ownable is Context {
    address public _owner;

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
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);
  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}