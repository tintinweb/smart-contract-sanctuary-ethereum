/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory);
}

contract MuzzleToken {
    string public constant name = "Muzzle Token";
    string public constant symbol = "MUZZ";
    uint8 public constant decimals = 18;
    uint256 public constant totalSupply = 21_000_000 * 10 ** decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public numSentAddresses;
    
    uint256 public sellTax = 1; // 1%
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SetOwner(address indexed oldOwner, address indexed newOwner);
    event SetSellTax(uint256 oldSellTax, uint256 newSellTax);
    event SetBlacklist(address indexed account, bool value);
    event SetWhitelist(address indexed account, bool value);

    constructor() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Muzzle: caller is not the owner");
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Muzzle: cannot set owner to zero address");
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }

    function setSellTax(uint256 newSellTax) external onlyOwner {
        require(newSellTax <= 10, "Muzzle: sell tax cannot exceed 10%");
        emit SetSellTax(sellTax, newSellTax);
        sellTax = newSellTax;
    }

    function setBlacklist(address account, bool value) external onlyOwner {
        blacklist[account] = value;
        emit SetBlacklist(account, value);
    }

    function setWhitelist(address account, bool value) external onlyOwner {
        whitelist[account] = value;
        emit SetWhitelist(account, value);
    }

    

        function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
    require(numSentAddresses[msg.sender] < 2, "Muzzle: you have already sent tokens to 2 different addresses");
    require(to != address(this), "Muzzle: you cannot transfer tokens to the contract address");
    require(balanceOf[msg.sender] >= value, "Muzzle: insufficient balance");
    require(balanceOf[to] + value > balanceOf[to], "Muzzle: integer overflow");
    require(!blacklist[msg.sender], "Muzzle: sender is blacklisted");
    require(!blacklist[to], "Muzzle: recipient is blacklisted");
    require(whitelist[msg.sender] || whitelist[to], "Muzzle: sender or recipient must be whitelisted");
    require(allowance[msg.sender][address(this)] >= value, "Muzzle: insufficient allowance");

    balanceOf[msg.sender] -= value;
    balanceOf[to] += value;

    numSentAddresses[msg.sender]++;

    allowance[msg.sender][address(this)] -= value;

    emit Transfer(msg.sender, to, value);

    return true;
}




    function sell(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Muzzle: insufficient balance");
        require(!blacklist[msg.sender], "Muzzle: sender is blacklisted");

        uint256 sellAmount = (amount * sellTax) / 100;
        uint256 ethAmount = amount - sellAmount;

        balanceOf[msg.sender] -= amount;
        balanceOf[address(this)] += sellAmount;

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        allowance[msg.sender][address(this)] = ethAmount;
        
        uniswapRouter.swapExactTokensForETH(ethAmount, 0, path, msg.sender, block.timestamp + 1 hours);

        emit Transfer(msg.sender, address(this), sellAmount);
    }
}