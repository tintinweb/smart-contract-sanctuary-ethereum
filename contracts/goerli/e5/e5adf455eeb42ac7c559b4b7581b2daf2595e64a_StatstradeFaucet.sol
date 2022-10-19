/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
  function transfer(address to,uint value) external returns(bool);
  function balanceOf(address owner) external view returns(uint);
}

contract StatstradeFaucet {
  uint public g__SiteLimit;
  
  constructor(uint limit) {
    g__SiteLimit = limit;
  }
  
  event FaucetEvent(string event_type,string event_id,address sender,uint value);
  
  function request_balance_faucet(address erc20_address) external view returns(uint) {
    IERC20 erc20 = IERC20(erc20_address);
    return erc20.balanceOf(address(this));
  }
  
  function request_balance_caller(address erc20_address) external view returns(uint) {
    IERC20 erc20 = IERC20(erc20_address);
    return erc20.balanceOf(msg.sender);
  }
  
  function request_topup(uint amount,address erc20_address) external {
    IERC20 erc20 = IERC20(erc20_address);
    uint balance = erc20.balanceOf(msg.sender);
    require((balance + amount) < g__SiteLimit,"Already topped up");
    erc20.transfer(msg.sender,amount);
    emit FaucetEvent("topup","",msg.sender,amount);
  }
}