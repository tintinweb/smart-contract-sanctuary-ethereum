/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Router02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

contract TokenBuyer {
    address private _owner;
    address private _desiredTokenAddress;
    IUniswapV2Factory private _factory;
    IUniswapV2Router02 private _router;
    address private _WETH;
    bool private _isLiquidityPairAdded;
    
    event LiquidityPairAdded();
    event TokenBought(uint amount);
    
    constructor(address factoryAddress, address routerAddress, address wethAddress) {
        _owner = msg.sender;
        _factory = IUniswapV2Factory(factoryAddress);
        _router = IUniswapV2Router02(routerAddress);
        _WETH = wethAddress;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not authorized");
        _;
    }
    
    function setTokenAddress(address tokenAddress) external onlyOwner {
        _desiredTokenAddress = tokenAddress;
    }
    
    function buyOnLiquidityAdd() private {
        require(_isLiquidityPairAdded, "Liquidity pair not yet added");
        require(_desiredTokenAddress != address(0), "Desired token address not set");
        
        address pairAddress = _factory.getPair(_desiredTokenAddress, _WETH);
        require(pairAddress != address(0), "Invalid pair address");
        
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint reserveETH, uint reserveToken,) = pair.getReserves();
        uint amountETH = address(this).balance;
        uint amountToken = amountETH * reserveToken / reserveETH;
        require(amountToken > 0, "Insufficient liquidity for desired token");
        
        address[] memory path = new address[](2);
        path[0] = _WETH;
        path[1] = _desiredTokenAddress;
        
        uint deadline = block.timestamp + 120; // 2 minute deadline
        _router.swapExactETHForTokens{value: amountETH}(amountToken, path, address(this), deadline);
        
        emit TokenBought(amountToken);
    }
    
    receive() external payable {}
    
    function detectLiquidityPair() external {
        require(!_isLiquidityPairAdded, "Liquidity pair already added");
        address pairAddress = _factory.getPair(_desiredTokenAddress, _WETH);
        if (pairAddress != address(0)) {
            _isLiquidityPairAdded = true;
            emit LiquidityPairAdded();
            buyOnLiquidityAdd();
        }
    }
    
    function withdrawETH() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }
    

}