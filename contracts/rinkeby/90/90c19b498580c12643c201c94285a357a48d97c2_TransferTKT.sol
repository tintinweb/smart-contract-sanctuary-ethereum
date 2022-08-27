// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITestKLIMAToken {
    function balanceOf(address account) external view returns (uint256);
    function approveToken(address owner, address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


contract TransferTKT {
    ITestKLIMAToken token;
    address private owner;

    constructor() {
        token = ITestKLIMAToken(0xE0Ce4D012449a1DeD81d4d94d1407823a70Bd7D4);
        owner = msg.sender;
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getUserTokenBalance() public view returns(uint256){  
        return token.balanceOf(msg.sender);
    }

    function approveToken(uint256 _tokenAmount) public returns(bool) {
        token.approveToken(msg.sender, address(this), _tokenAmount);
        return true;
    }

    function getAllowance() public view returns(uint256) {
        return token.allowance(msg.sender, address(this));
    }

    function acceptPayment(uint256 _tokenAmount) public returns(bool) {
        require(_tokenAmount > getAllowance(), "Please approve tokens before transferring");
        token.transferFrom(msg.sender, address(this), _tokenAmount);
        return true;
    }
    
    function getContractTokenBalance() public OnlyOwner view returns(uint256) {
        return token.balanceOf(address(this));
    }
}