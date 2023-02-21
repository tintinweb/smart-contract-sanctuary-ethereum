/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] memory path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

contract AutoBuyer {
    address private constant WETH_ADDRESS = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // WETH address on Ethereum mainnet
    address public owner; // contract owner address
    address public tokenToBuy; // token address to buy
    bool public autoBuyEnabled; // flag to enable/disable auto buy
    uint256 public minEthAmount; // minimum ETH amount required to trigger auto buy
    uint256 public minTokenAmount; // minimum token amount to be bought on auto buy
    IUniswapV2Router public uniswapRouter; // Uniswap router address
    IUniswapV2Factory public uniswapFactory; // Uniswap factory address
    mapping(address => bool) public whitelistedTokens; // mapping of whitelisted token addresses

    event LogAutoBuyEnabled(bool enabled);
    event LogTokenToBuyUpdated(address tokenAddress);
    event LogMinEthAmountUpdated(uint256 amount);
    event LogMinTokenAmountUpdated(uint256 amount);
    event LogTokenWhitelisted(address tokenAddress, bool whitelisted);
    event LogTokensReceived(address sender, uint256 amount);

    constructor(address _uniswapRouter, address _uniswapFactory, uint256 _minEthAmount, uint256 _minTokenAmount) {
        owner = msg.sender;
        uniswapRouter = IUniswapV2Router(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        minEthAmount = _minEthAmount;
        minTokenAmount = _minTokenAmount;
        autoBuyEnabled = true;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function setTokenToBuy(address _tokenToBuy) external onlyOwner {
        require(_tokenToBuy != address(0), "Token address cannot be zero.");
        tokenToBuy = _tokenToBuy;
        emit LogTokenToBuyUpdated(_tokenToBuy);
    }

    function setMinEthAmount(uint256 _minEthAmount) external onlyOwner {
        require(_minEthAmount > 0, "Minimum ETH amount should be greater than zero.");
        minEthAmount = _minEthAmount;
        emit LogMinEthAmountUpdated(_minEthAmount);
    }

    function setMinTokenAmount(uint256 _minTokenAmount) external onlyOwner {
        require(_minTokenAmount > 0, "Minimum token amount should be greater than zero.");
        minTokenAmount = _minTokenAmount;
        emit LogMinTokenAmountUpdated(_minTokenAmount);
    }

}