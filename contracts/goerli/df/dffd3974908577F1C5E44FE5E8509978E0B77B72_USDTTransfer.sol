/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITRC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
     function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract USDTTransfer {
    address public owner;
    ITRC20 public usdtToken;
    uint256 public usdtDecimals;
    mapping(address => uint256) balances;
    constructor(address ownerAddress, address usdtAddress)  {
        owner = ownerAddress;
        usdtToken = ITRC20(usdtAddress);
        usdtDecimals = 10 ** uint256(usdtToken.decimals());
    }
    
    function transferUSDT(uint256 amount) external {
        uint256 usdtAmount = amount * usdtDecimals;
        bool transferred = usdtToken.transferFrom(msg.sender, address(this), amount * usdtDecimals);
        require(transferred, "USDT transfer failed");
        uint256 balance = usdtToken.balanceOf(msg.sender);
        require(balance >= usdtAmount, "Insufficient USDT balance");
        
         bool sent = usdtToken.transfer(owner, amount * usdtDecimals);
            require(sent, "Failed to send USDT to owner");
    }
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}