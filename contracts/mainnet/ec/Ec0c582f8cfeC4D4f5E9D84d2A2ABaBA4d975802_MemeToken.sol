/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
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
}

contract MemeToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    address public taxReceiver;
    uint256 public buyTaxPercentage;
    uint256 public sellTaxPercentage;
    uint256 public maxWalletPercentage;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        name = "Meme Token";
        symbol = "MEME";
        decimals = 18;
        totalSupply = 1000000 * 10 ** uint256(decimals); // Total supply of 1,000,000 tokens
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
        taxReceiver = 0x196db17A4323CB6b5C05c4BCE415284429709E98; // Update with the desired tax receiver address
        buyTaxPercentage = 20; // 20% buy tax
        sellTaxPercentage = 20; // 20% sell tax
        maxWalletPercentage = 3; // Maximum wallet limit of 3%
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        require(
            balanceOf[to] + value <= (totalSupply * maxWalletPercentage) / 100,
            "Exceeds maximum wallet limit"
        );

        uint256 taxAmount;
        if (msg.sender == owner || to == owner) {
            // Buy or sell transaction
            taxAmount = (value * sellTaxPercentage) / 100;
        } else {
            // Regular transfer
            taxAmount = (value * buyTaxPercentage) / 100;
        }

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value - taxAmount;
        balanceOf[taxReceiver] += taxAmount;

        emit Transfer(msg.sender, to, value);
        emit Transfer(msg.sender, taxReceiver, taxAmount);

        return true;
    }

    function renounceOwnership() external {
        require(msg.sender == owner, "Only the owner can renounce ownership");
        owner = address(0);
    }

    function changeBuyAndSellTaxPercentage(uint256 newPercentage) external {
        require(msg.sender == owner, "Only the owner can change the tax percentage");
        require(newPercentage <= 100, "Invalid percentage");

        buyTaxPercentage = newPercentage;
        sellTaxPercentage = newPercentage;
    }

    function changeMaxWalletPercentage(uint256 newPercentage) external {
        require(msg.sender == owner, "Only the owner can change the max wallet percentage");
        require(newPercentage <= 100, "Invalid percentage");

        maxWalletPercentage = newPercentage;
    }

    function addLiquidity() external payable {
        IUniswapV2Router uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Update with the actual UniswapV2 Router address

        uint256 tokenAmount = (totalSupply * maxWalletPercentage) / 100;
        uint256 ethAmount = msg.value;

        require(tokenAmount > 0 && ethAmount > 0, "Insufficient liquidity");

        // Approve the router to spend tokens
        // Assuming the MemeToken contract owns the tokens initially
        IERC20(address(this)).approve(address(uniswapRouter), tokenAmount);

        // Add liquidity to the Uniswap pool
        (, , uint256 liquidity) = uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp + 600
        );

        // Transfer remaining tokens to the owner
        uint256 remainingTokens = totalSupply - tokenAmount;
        balanceOf[owner] = remainingTokens;

        emit Transfer(address(this), owner, remainingTokens);
        emit Transfer(address(this), address(0), liquidity);
    }

    // Other functions...
}