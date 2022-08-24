/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TestingEvent{
  
     uint public count;

     event limitOrderPlaced(uint256 limitOrderId,address user,address inputToken,uint256 inputTokenAmount,address outputToken,uint256 minimumOutputToken,uint8 orderType);
        event limitOrderExecuted(uint256 limitOrderId);
        event limitOrderCancelled(uint256 limitOrderId);
    function emitEvent(address inputToken,uint256 amount,address outputToken,uint256 amount1,uint8 orderType) external{
        count++;
        emit limitOrderPlaced(count,msg.sender,inputToken,amount,outputToken,amount1,orderType);
    }

    function executeLimitOrder(uint256 limitOrderId)external{
        emit limitOrderExecuted(limitOrderId);
    }

      function cancelLimitOrder(uint256 limitOrderId)external{
        emit limitOrderCancelled(limitOrderId);
    }
}