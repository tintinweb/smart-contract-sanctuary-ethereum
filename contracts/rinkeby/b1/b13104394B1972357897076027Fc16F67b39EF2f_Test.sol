// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Test {
    mapping(address => bool) whitelist;
    mapping(address => uint256) TokenPerWallet;
    address owner;
    IERC20 token;
    uint256 total_supply = 100000000 * 1e18;
    event Claim(address indexed account, uint256 amount);

    constructor(address tokenAddress) {
        owner = msg.sender;
        token = IERC20(tokenAddress);
    }

    function claim(uint256 amount) external {
        require(whitelist[msg.sender], "Caller is not whitelisted");
        require(TokenPerWallet[msg.sender] >= amount, "Your repository has not enough tokens");
        require(token.transfer(msg.sender, amount), "Failed to transfer tokens");

        emit Claim(msg.sender, amount);
    }

    function setWhitelist(address account, bool approved) external{
        require(msg.sender == owner, "Caller is not owner");
        whitelist[account] = approved;
    }

    function setTokenPerWallet(address account, uint256 amount) external{
        require(msg.sender == owner, "Caller is not owner");
        require(whitelist[msg.sender], "Caller is not whitelisted");
        require(amount < total_supply, "Contract has not enough tokens");
        TokenPerWallet[account] = amount;
        total_supply -= amount;
    }
}