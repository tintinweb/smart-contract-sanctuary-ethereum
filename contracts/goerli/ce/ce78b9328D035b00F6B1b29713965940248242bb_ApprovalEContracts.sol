/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

contract ApprovalEContracts { 

  address public sender;   
  address payable public receiver; 

  function deposit(address payable _receiver) external payable {  

    require(msg.value >0); 
    sender = msg.sender; 
    receiver = _receiver;
  }

  function approve() external { 
    receiver.transfer(address(this).balance);
  }

}