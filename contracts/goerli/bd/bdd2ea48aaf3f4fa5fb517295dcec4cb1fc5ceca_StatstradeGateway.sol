/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
  function transfer(address to,uint value) external returns(bool);
}

contract StatstradeGateway {
  event GatewayEvent(string event_type,string event_id,address sender,uint value);
  
  address public g__SiteAuthority;
  
  constructor() {
    g__SiteAuthority = msg.sender;
  }
  
  function link_account(string memory message) external {
    emit GatewayEvent("link_account",message,msg.sender,0);
  }
  
  function payment_native(string memory message) external payable {
    require(msg.value != 0,"Cannot be zero");
    payable(g__SiteAuthority).transfer(msg.value);
    emit GatewayEvent("payment_native",message,msg.sender,msg.value);
  }
  
  function payment_token(address token_address,uint amount,string memory message) external {
    require(amount != 0,"Cannot be zero.");
    IERC20 erc20 = IERC20(token_address);
    erc20.transfer(g__SiteAuthority,amount);
    emit GatewayEvent("payment_token",message,msg.sender,amount);
  }
}