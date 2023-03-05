/**
 *Submitted for verification at Etherscan.io on 2023-03-05
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

contract MyFaucet{

    address _tokenContract;
    uint256 _amountAllowed;
    uint256 _timeLimit=86400;

    mapping(address=>uint256) public _lastDewTime;

    //部署时填入你的ERC20代币地址。
    constructor(address tokenContract){
        _tokenContract = tokenContract; 
    }

    function dew() public{
    IERC20 token = IERC20(_tokenContract); // 创建IERC20合约对象
    require(token.balanceOf(address(this)) >= _amountAllowed, "Faucet Empty!"); // 水龙头空了
    uint256  currentTime=block.timestamp;
    require(currentTime - _lastDewTime[msg.sender] > _timeLimit,"only 1 time in 24hours");//24h只能取一次。
    token.transfer(msg.sender, _amountAllowed); // 发送token
    _lastDewTime[msg.sender]=currentTime;
    }
}