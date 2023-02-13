/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract DistributeETH {
    address payable public AthosWallet;
    address payable public DanielWallet;

    function setAthosWallet(address payable newWallet) public {
        AthosWallet = newWallet;
    }

    function setDanielWallet(address payable newWallet) public {
        DanielWallet = newWallet;
    }

    function receiveERC20Tokens(address _tokenAddress, uint _amount) public {
        ERC20 token = ERC20(_tokenAddress);

        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        uint AthosAmount = _amount * 15 / 100;
        uint DanielAmount = _amount * 15 / 100;

        require(token.transfer(AthosWallet, AthosAmount), "Failed to send funds to Athos Wallet");
        require(token.transfer(DanielWallet, DanielAmount), "Failed to send funds to Daniel Wallet ");
    }

    function approveTokenTransfer(address _tokenAddress, uint _amount) public {
        ERC20 token = ERC20(_tokenAddress);

        require(token.approve(address(this), _amount), "Approval failed");
    }

    fallback() external payable {
        uint amountReceived = msg.value;
        uint AthosAmount = amountReceived * 15 / 100;
        uint DanielAmount = amountReceived * 15 / 100;

        require(AthosWallet.send(AthosAmount), "Failed to send funds to wallet 1");
        require(DanielWallet.send(DanielAmount), "Failed to send funds to wallet 2");
    }
}