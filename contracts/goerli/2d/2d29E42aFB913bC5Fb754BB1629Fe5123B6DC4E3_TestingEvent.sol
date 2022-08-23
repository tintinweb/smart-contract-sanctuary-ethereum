/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestingEvent{
  
     uint public count;

     event LimitOrderPlaced(address user,address inputToken,uint256 inputTokenAmount,address outputToken,uint256 minimumOutputToken,uint8 orderType);

    function emitEvent(address inputToken,uint256 amount,address outputToken,uint256 amount1,uint8 orderType) external{
        count++;
        emit LimitOrderPlaced(msg.sender,inputToken,amount,outputToken,amount1,orderType);
    }
}