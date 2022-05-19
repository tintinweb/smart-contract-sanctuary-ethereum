/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external payable returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract HPThtlc {

  //address _account;
  //address _token;

  IERC20 public token;  

  constructor() { 
    //token.approve(_recipient, _amount);
    //_spender (address) , _value (uint256
    //token.createTokens(_amount);
    //token.transferFrom(_recipient, _to, _amount);
  }

  function setup (address _account, address _token) public returns (uint256) { //) public returns (uint256) { //
    //_account = address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    //_token = address(0x0D8775F648430679A709E98d2b0Cb6250d2887EF); // BAT mainnet

    token = IERC20(_token);

    return token.balanceOf(_account);
    //token.approve(con, rec,  1);
  }

  /* deposit eth for swap */
  // 0xdAC17F958D2ee523a2206206994597C13D831ec7 - usdt
  // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 - weth
  // 0x0D8775F648430679A709E98d2b0Cb6250d2887EF - BAT
  /*
  function depositEth(address _recipient, address _token, uint _amount) payable external returns (bool success) { //, address _to, 
    require(_recipient != address(0), "Require: Address");

    token = IERC20(_token);
    token.approve(_recipient, _amount);
    //_spender (address) , _value (uint256
    //token.createTokens(_amount);
    //token.transferFrom(_recipient, _to, _amount);

    return true;
  }
  */
    
}