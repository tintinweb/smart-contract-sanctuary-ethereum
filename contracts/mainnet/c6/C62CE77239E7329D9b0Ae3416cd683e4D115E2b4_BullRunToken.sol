/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapV2Router02 {
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

contract BullRunToken {
    string public constant name = "Luffy";
    string public constant symbol = "LUFFY";
    uint256 public constant decimals = 18;
    uint256 public totalSupply = 1000000000000 * 10**decimals;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public owner;
    IUniswapV2Router02 public uniswapRouter;
    address public uniswapPair;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    constructor() {
        owner = 0x1Fc7857E493e7bC2f443F48CB69Cf57070546C6E;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    function setUniswapRouter(address router) external {
        require(address(uniswapRouter) == address(0), "Router already set");
        uniswapRouter = IUniswapV2Router02(router);
        uniswapPair = address(this);
    }

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount, uint256 deadline) external {
        require(address(uniswapRouter) != address(0), "Router not set");
        require(tokenAmount > 0, "Token amount must be greater than zero");
        require(ethAmount > 0, "ETH amount must be greater than zero");

        _approve(address(this), address(uniswapRouter), tokenAmount);
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            deadline
        );
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(balances[sender] >= amount, "ERC20: insufficient balance");

        balances[sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(address tokenOwner, address spender, uint256 amount) internal {
        require(tokenOwner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[tokenOwner][spender] = amount;

        emit Approval(tokenOwner, spender, amount);
    }
}