/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.5.10;



// Part: IERC20

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

// Part: TokenInterface

contract TokenInterface{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

// File: Staker.sol

contract Staker{
  address[] public token;
  address public lp;
  mapping (address => uint256) public balance; 
  mapping (address => uint256) public last_block; 
  mapping (address => uint256) public reward; 

  constructor(address _lp, address _t0, address _t1) public{
    lp = _lp;
    token.push(_t0);
    token.push(_t1);
  }

  function _check_point(address addr) internal{
    if (last_block[addr] == 0) {last_block[addr] = block.number;}
    reward[addr] += (block.number - last_block[addr]) * balance[addr];
  }

  function add_token(address _t) public{
    token.push(_t);
  }

  function stake(uint256 amount) public returns(bool){
    IERC20(lp).transferFrom(msg.sender, address(this), amount);
    _check_point(msg.sender);
    balance[msg.sender] += amount;
    return true;
  }

  function withdraw(uint256 amount, bool claim) public returns(bool){
    require(amount <= balance[msg.sender], "Staker: not enough balance");
    _check_point(msg.sender);
    balance[msg.sender] -= amount;
    IERC20(lp).transfer(msg.sender, amount);
    if (claim){
      getReward();
    }
    return true;
  }

  function getReward() public returns(bool){
    _check_point(msg.sender);
    for (uint i = 0; i < token.length; i++){
      TokenInterface(token[i]).generateTokens(msg.sender, reward[msg.sender]/10000);
    }
    reward[msg.sender] = 0;
    return true;
  }
}