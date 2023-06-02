/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >="0.8.18";
// Intended use: exchange for services on gitarg decentralized platform and ada NFTs (release date June 2nd - June 15th 2023)

contract gitarg {
  struct SpendDown {
    //address account;
    address owner;
    address spender;
    uint256 amount;
  }
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // possibly change to array
  //address private initialMinter;
  //address private secodaryMinter;
  //address public publicMinter;

  //mapping(address => SpendDown[]) spendDownFunds;
  //mapping(address => SpendDown) spendDownFunds;
  SpendDown[] spendDownFunds;
  
  mapping(address => address[]) private coop;
  //mapping(address => uint256) private spendDown;

  address[] owners;
  mapping(address => uint256) private balances;
  mapping(address => bool) private locked;

  // These functions may not be allowed
  function lock() public returns (bool) {
    locked[msg.sender] = true;
    return locked[msg.sender];
  }
  function unlock() public returns (bool) {
    locked[msg.sender] = false;
    return locked[msg.sender];
  }

  // ICO ERC-20 standard functions

  //https://eips.ethereum.org/EIPS/eip-20#name
  // function definition can be changed to pure - not in standard
  function name() public view returns (string memory) {
    return "gitarg";  
  }
  //https://eips.ethereum.org/EIPS/eip-20#symbol
  // function definition can be changed to pure - not in standard
  function symbol() public view returns (string memory) {
    return "GIT";
  }
  //https://eips.ethereum.org/EIPS/eip-20#decimals
  // function definition can be changed to pure - not in standard
  function decimals() public view returns (uint8) {
    return 6;
  }
  //https://eips.ethereum.org/EIPS/eip-20#decimals
  // function definition can be changed to pure - not in standard
  function totalSupply() public view returns (uint256) {
    return 100100000;
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  function transfer(address _to, uint256 _value) public returns (bool success) {
    require(!locked[msg.sender]);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    address[] memory coopList = coop[_from]; 
    bool allow = false;
    for (uint i = 0; i < coopList.length; i++) {
      if(coopList[i] == _to) {
        allow = true;
        continue;
      }
    }
    require(allow);
    emit Transfer(_from, _to, _value);
    return allow;
  }
  function approve(address _spender, uint256 _value) public returns (bool success) {
    //TODO - check balance
    //TODO - collapse records by owner
    spendDownFunds.push(SpendDown(msg.sender, _spender, _value));
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    // REVIEW
    for (uint i = 0; i < spendDownFunds.length; i++) {
      if (spendDownFunds[i].spender == _spender && spendDownFunds[i].owner == _owner) {
        return spendDownFunds[i].amount;
      }
    }
  }
}