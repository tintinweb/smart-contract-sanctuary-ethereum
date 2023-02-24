/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface ERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DistributeTokens {
    address payable public AthosWallet;
    address payable public DanielWallet;
    address public tokenAddress;
    uint public tokenDecimals;

    function setAthosWallet(address payable newWallet) public {
        AthosWallet = newWallet;
    }

    function setDanielWallet(address payable newWallet) public {
        DanielWallet = newWallet;
    }

   function ReceiveERC20tokens(address _sender, ERC20 _tokenAddress, uint256 _amount) public {

    require(_tokenAddress.allowance(_sender, address(this)) >= _amount, "Token allowance not sufficient");
    require(_tokenAddress.balanceOf(_sender) >= _amount, "Insufficient token balance");


    uint256 amountWithDecimals = _amount * (10 ** _tokenAddress.decimals());
    uint256 AthosAmount = amountWithDecimals * 15 / 100;
    uint256 DanielAmount = amountWithDecimals * 15 / 100;
    uint256 remainingAmount = amountWithDecimals - AthosAmount - DanielAmount;

    require(_tokenAddress.transferFrom(_sender, address(this), amountWithDecimals), "Transfer failed");
    require(_tokenAddress.transfer(AthosWallet, AthosAmount), "Failed to send funds to Athos Wallet");
    require(_tokenAddress.transfer(DanielWallet, DanielAmount), "Failed to send funds to Daniel Wallet");
    require(_tokenAddress.transfer(_sender, remainingAmount), "Failed to return remaining tokens to the sender");
}


  fallback() external payable {
    uint amountReceived = msg.value;
    uint AthosAmount = amountReceived * 15 / 100;
    uint DanielAmount = amountReceived * 15 / 100;

    require(AthosWallet.send(AthosAmount), "Failed to send funds to wallet 1");
    require(DanielWallet.send(DanielAmount), "Failed to send funds to wallet 2");
}
}