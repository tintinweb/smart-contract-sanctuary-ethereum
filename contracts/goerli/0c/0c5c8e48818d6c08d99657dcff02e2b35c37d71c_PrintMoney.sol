/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

interface IUniswapV2 {
    function WETH() external view returns (address);

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

    function factory() external view returns (address);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsIn(uint256 amountOut, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

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

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

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

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to,
        uint256 deadline
    ) external;

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    receive() external payable;
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

contract PrintMoney {
    address owner;
    IWETH private constant WETH = IWETH(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);
    
    event OwnerChanged(address old_owner, address new_owner);

    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function setOwner(address _newOwner) onlyOwner external {
        require(_newOwner != address(0) && owner != _newOwner, "Owners same/zero");
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }
    
    function approveToken(address token, address factory) onlyOwner external {
        IERC20 erc20 = IERC20(token);
        erc20.approve(factory, uint(-1)); // usdt six decimal would fail!
    }
    
    // assuming tokenIn always WETH
    function printMoney(
        address factory,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline,
        uint256 miner_share
    ) external {
        tokenIn;
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        require(amountIn <= _wethBalanceBefore, "Insufficient Balance");
        IUniswapV2 uni = IUniswapV2(payable(factory));
        uni.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceBefore < _wethBalanceAfter, "No profit");
        uint256 profit = _wethBalanceAfter - _wethBalanceBefore;
        uint256 _ethBalance = address(this).balance;
        uint256 miner_take = profit * miner_share / 100;
        if (_ethBalance < miner_take) {
            WETH.withdraw(miner_take - _ethBalance);
        }
        block.coinbase.transfer(miner_take);
    }

    function printMoneyWithFee(
        address factory,
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint256 deadline,
        uint256 miner_share
    ) external {
        tokenIn;
        uint256 _wethBalanceBefore = WETH.balanceOf(address(this));
        require(amountIn <= _wethBalanceBefore, "Insufficient Balance");
        IUniswapV2 uni = IUniswapV2(payable(factory));
        uni.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, amountOutMin, path, address(this), deadline);
        uint256 _wethBalanceAfter = WETH.balanceOf(address(this));
        require(_wethBalanceBefore < _wethBalanceAfter, "No profit");
        uint256 profit = _wethBalanceAfter - _wethBalanceBefore;
        uint256 _ethBalance = address(this).balance;
        uint256 miner_take = profit * miner_share / 100;
        if (_ethBalance < miner_take) {
            WETH.withdraw(miner_take - _ethBalance);
        }
        block.coinbase.transfer(miner_take);
    }

    receive() external payable {}

    function depositETHForWETH() external payable {
        WETH.deposit{value: msg.value}();
    }
    function withdraw(address to) onlyOwner external payable {
        payable(to).transfer(address(this).balance);
    }

    function withdrawToken(address token, address to) onlyOwner external {
        IERC20 erc20 = IERC20(token);
        uint bal = erc20.balanceOf(address(this));
        erc20.transfer(to, bal);
    }
}