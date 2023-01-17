/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract UsdtCollector  {
    address payable recipient;
    address targetToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    IERC20 token;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    constructor(address payable _addr) {
        recipient = _addr;
        token = IERC20(targetToken);
    }
  
    receive() payable external {
        recipient.transfer(msg.value);
        emit Transfer(msg.sender, address(this), msg.value);
    }
    
    function withdraw() public {
        uint256 erc20balance = token.balanceOf(address(this));
        token.transfer(recipient, erc20balance);
    }    
}