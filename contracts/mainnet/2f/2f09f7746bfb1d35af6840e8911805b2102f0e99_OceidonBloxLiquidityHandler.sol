/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
	function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

contract OceidonBloxLiquidityHandler is Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public constant USDCAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant OBLOX = 0x9319820aD5447180D0CBb76c1C06c870562aEf93;
    address public constant uniswapV2_OBLOXUSDCPair = 0xB1636Da7243bED31B988d68026C3289Df258d252;
    bool private inProgress;

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
    }

    function addLiquidityFee(bool isAll, uint256 amountForLiquidity) public onlyOwner {
        require(!inProgress, "Add liquidity is in progress");
        if(isAll) {
            amountForLiquidity = IERC20(OBLOX).balanceOf(address(this));
        } else {
            require(amountForLiquidity <= IERC20(OBLOX).balanceOf(address(this)), "Not enough tokens in the contract");
        }

        inProgress = true;
        
        IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2_OBLOXUSDCPair);
        (uint256 res0, uint256 res1, ) = pair.getReserves();

        uint256 tokenReserve;
        if(OBLOX == pair.token0()) {
            tokenReserve = res0;
        } else {
            tokenReserve = res1;
        }
        uint256 originalAmount = IERC20(USDCAddress).balanceOf(address(this));
        uint256 amountToSwap = calculateSwapInAmount(tokenReserve, amountForLiquidity);
        //if no reserve or a new pair is created
        if (amountToSwap <= 0) amountToSwap = amountForLiquidity / 2;
        uint256 amountLeft = amountForLiquidity - amountToSwap;
        swapTokensForUSDC(amountToSwap, address(this));
        uint256 initialBalance = IERC20(USDCAddress).balanceOf(address(this)) - originalAmount;
        addLiquidity(amountLeft, initialBalance);
        
        inProgress = false;
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
            ) - (reserveIn * 1997)) / 1994;
    }

    function swapTokensForUSDC(uint256 tokenAmount, address receiver) private {
        address[] memory path = new address[](2);
        path[0] = OBLOX;
        path[1] = USDCAddress;
		
        IERC20(OBLOX).approve(address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            receiver,
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 usdcAmount) private {
        IERC20(OBLOX).approve(address(uniswapV2Router), tokenAmount);
        IERC20(USDCAddress).approve(address(uniswapV2Router), usdcAmount);
        uniswapV2Router.addLiquidity(
            OBLOX,
            USDCAddress,
            tokenAmount,
            usdcAmount, 
            0,
            0,
            address(this),
            block.timestamp
        );
    }
}