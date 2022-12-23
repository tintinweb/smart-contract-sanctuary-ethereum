/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Feeder { 
    address owner;
    address token;
    IERC20 tokenContract;
    uint256 private tokensAmount; 
    mapping(address => bool) private whiteList;
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    constructor(IERC20 _tokenAddress) {
        owner = msg.sender;
        tokenContract = _tokenAddress;
    }

    function getTokensAmount() public view returns(uint256){
        return tokensAmount;
    }

    function setTokensAmount(uint256 _amount) public onlyOwner() {
        tokensAmount = _amount;
    }

    function takeTokens() public {
        require(whiteList[msg.sender], "You are not whitelisted");
        require(tokenContract.balanceOf(address(this)) >= tokensAmount, "Not enough tokens");

        whiteList[msg.sender] = false;
        tokenContract.approve(address(this), tokensAmount);
        tokenContract.transferFrom(address(this), msg.sender, tokensAmount);

    }

    function addToWhilelist(address[] calldata _accounts) public onlyOwner() {
        for(uint256 i = 0; i < _accounts.length; i++) {
            whiteList[_accounts[i]] = true;
        }
    }

    function isAddyWhitelisted(address _addy) public view returns(bool) {
        return whiteList[_addy];
    }

    function withdraw() public onlyOwner {
        uint256 amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(owner, amount);
    }



}