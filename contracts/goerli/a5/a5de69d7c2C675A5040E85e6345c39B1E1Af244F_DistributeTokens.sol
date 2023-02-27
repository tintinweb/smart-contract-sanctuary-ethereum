/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IERC20 {
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
   

    function setAthosWallet(address payable newWallet) public {
        AthosWallet = newWallet;
    }

    function setDanielWallet(address payable newWallet) public {
        DanielWallet = newWallet;
    }

   function ReceiveIERC20tokens(address _sender, IERC20 _tokenAddress, uint256 _amount) public {

    require(_tokenAddress.allowance(_sender, address(this)) >= _amount, "Token allowance not sufficient");
    require(_tokenAddress.balanceOf(_sender) >= _amount, "Insufficient token balance");


    
    uint256 AthosAmount = _amount * 15 / 100;
    uint256 DanielAmount = _amount * 15 / 100;
    uint256 remainingAmount = _amount - AthosAmount - DanielAmount;

    
    require(_tokenAddress.transferFrom(_sender, AthosWallet, AthosAmount), "Failed to send funds to Athos Wallet");
    require(_tokenAddress.transferFrom(_sender, DanielWallet, DanielAmount), "Failed to send funds to Daniel Wallet");
    require(_tokenAddress.transferFrom(_sender, address(this), remainingAmount), "Failed to return remaining tokens to the sender");
}


  fallback() external payable {
    uint amountReceived = msg.value;
    uint AthosAmount = amountReceived * 15 / 100;
    uint DanielAmount = amountReceived * 15 / 100;

    require(AthosWallet.send(AthosAmount), "Failed to send funds to wallet 1");
    require(DanielWallet.send(DanielAmount), "Failed to send funds to wallet 2");
}
}