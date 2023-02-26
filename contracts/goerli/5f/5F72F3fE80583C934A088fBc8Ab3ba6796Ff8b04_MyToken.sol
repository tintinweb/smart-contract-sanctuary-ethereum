/**
 *Submitted for verification at Etherscan.io on 2023-02-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract MyToken {
    string public name = "MYT";
    string public symbol = "OK";
    uint256 public totalSupply = 10000;
    uint256 public liquidityPoolCreationTime;
    address public owner;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(balances[sender] >= amount, "Not enough balance");
        require(allowances[sender][msg.sender] >= amount, "Not enough allowance");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function buy() public payable {
        require(msg.value > 0, "Amount must be greater than 0");
        uint256 amount = msg.value;
        balances[msg.sender] += amount;
        balances[address(this)] -= amount;
        emit Transfer(address(this), msg.sender, amount);
    }

    function sell(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Not enough balance");
        require(block.timestamp < liquidityPoolCreationTime, "Sell time must be lower than liquidity pool creation time");
        balances[msg.sender] -= amount;
        balances[address(this)] += amount;
        payable(msg.sender).transfer(amount);
        emit Transfer(msg.sender, address(this), amount);
    }

    function createLiquidityPool() public onlyOwner {
        require(liquidityPoolCreationTime == 0, "Liquidity pool already created");
        liquidityPoolCreationTime = block.timestamp;
        uint256 liquidityAmount = totalSupply / 2; // half of total supply
        uint256 ethAmount = address(this).balance; // all ETH balance of the contract
        IUniswapV2Router uniswapRouter = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
          
            // approve token transfer to router
    approve(address(uniswapRouter), liquidityAmount);

    // add liquidity to pool
    (uint amountToken, uint amountETH, uint liquidity) = uniswapRouter.addLiquidityETH{value: ethAmount}(
        address(this),
        liquidityAmount,
        liquidityAmount,
        ethAmount,
        address(this),
        block.timestamp + 3600
    );

    // transfer remaining tokens to owner
    balances[owner] += totalSupply - liquidityAmount;
    balances[address(this)] -= totalSupply - liquidityAmount;
    emit Transfer(address(this), owner, totalSupply - liquidityAmount);

    // transfer LP tokens to owner
    balances[owner] += liquidity;
    balances[address(this)] -= liquidity;
    emit Transfer(address(this), owner, liquidity);
}

function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
}

receive() external payable {
    buy();
}
}