/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

// File: contracts/Subscription.sol


pragma solidity ^0.8.4;
contract Subscription{
    address admin;
    struct Sub{
      bytes32 userId;
      bytes32 planId;
       address wallet;
       uint createAt;
    }
    event SubscriptionCreated(
        bytes32 userId,
        bytes32 planId,
        uint date
  );
   event SubscriptionUpdated(
        bytes32 planId,
        uint date
  );
    event SubscriptionCancelled(
        bytes32 userId,
        uint date
  );

    Sub[] public subscriptionsList;
     constructor(){
        admin = msg.sender;
    }
    
     function Subcribe(bytes32 _userId,bytes32 planId)external payable{
        require(msg.value >0,'not enough ether');
        payable(admin).transfer(msg.value);
         for (uint i = 0; i < subscriptionsList.length; i++) {
           if(subscriptionsList[i].userId == _userId) {
            return;}
         }
        subscriptionsList.push(Sub(_userId,planId,msg.sender,block.timestamp));
        emit SubscriptionCreated(_userId,planId,block.timestamp);
     }
     function changePlan(bytes32 userId,bytes32 planId)external payable{
            uint i = find(userId);
            require(msg.value > 0,'not enough ether');
            payable(admin).transfer(msg.value);
            subscriptionsList[i].planId = planId;
             emit SubscriptionUpdated(planId,block.timestamp);
     }
     function deleteSubscription(bytes32 userId) external {
            uint i = find(userId);
            delete subscriptionsList[i];
            emit SubscriptionCancelled( userId, block.timestamp );
     }

      function getSubscriptions() public view returns(Sub[] memory){
        return subscriptionsList;
     }

   function find(bytes32 id) view internal returns(uint) {
    for(uint i = 0; i < subscriptionsList.length; i++) {
      if(subscriptionsList[i].userId == id) {
        return i;
      }
    }
    revert('Subscription does not exist!');
  }

     
}