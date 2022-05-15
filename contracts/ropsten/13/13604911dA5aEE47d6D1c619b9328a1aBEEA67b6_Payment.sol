// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "PaymentInterface.sol";
import "AggregatorV3Interface.sol";

contract Payment is PaymentInterface {
  address contractOwner;  
  // ADMIN
  address[] adminAddresses;
  mapping(address => Admin) addressToAdmin;
  // CHANNEL
  string[] channelTelegramIds;
  mapping(string => Channel) telegramIdToChannel;
  // PLAN
  uint nextPlanId;
  mapping(uint => Plan) idToPlan;
  // SUBSCRIPTION
  uint nextSubscriptionId;
  mapping(uint => Subscription) idToSubscription;
  // SUBSCRIBER
  address[] subscriberAddresses;
  mapping(address => Subscriber) addressToSubscriber;

  constructor() {
      contractOwner = msg.sender;
   }


//   function getAdminFullInfo() public view returns(AdminFullInfo) {
//     require(adminExists(msg.sender), 'No such admin');
//     AdminFullInfo adminInfo = AdminFullInfo()
//   }

  function getMyChannels() public view returns(Channel[] memory) {
    require(adminExists(msg.sender), 'No such admin');
    Channel[] memory channels = new Channel[](channelTelegramIds.length);
    uint channelCount = 0;
    for (uint i=0; i<channelTelegramIds.length; i++) {
        string memory channelTelegramId = channelTelegramIds[i];
        if (telegramIdToChannel[channelTelegramId].adminAddress == msg.sender) {
            channels[channelCount++] = telegramIdToChannel[channelTelegramId];
        }
    }
    return channels;
  }

  function addChannel(string memory adminTelegramId, string memory channelTelegramId) external {
      require(!channelExists(channelTelegramId), 'Channel already exists');
      addAdminIfNeeded(adminTelegramId);
      channelTelegramIds.push(channelTelegramId);
      telegramIdToChannel[channelTelegramId] = Channel(channelTelegramId, msg.sender);
  }

  function addAdminIfNeeded(string memory adminTelegramId) internal {
      if (!adminExists(msg.sender)) {
          adminAddresses.push(msg.sender);
          addressToAdmin[msg.sender] = Admin(msg.sender, adminTelegramId, 0);
      }
  }

  function getChannelPlans(string memory telegramId) public view returns(Plan[] memory) {
      require(channelExists(telegramId), 'No such channel');
      Plan[] memory plans = new Plan[](nextPlanId - 1);
      uint planCount = 0;
      for (uint i=0; i<nextPlanId; i++) {
        if (equalStrings(idToPlan[i].channelTelegramId, telegramId)) {
            plans[planCount++] = idToPlan[i];
        }
      }
      return plans;
  }

  function createPlan(
      uint amount, 
      uint frequencyInDays, 
      string memory telegramId
    ) external {
    require(amount > 0, 'amount needs to be > 0');
    require(frequencyInDays > 0, 'Frequency needs to be > 1 day');
    require(channelExists(telegramId), 'Create channel first');
    require(telegramIdToChannel[telegramId].adminAddress == msg.sender, 'You are not adming of this channel');

    idToPlan[nextPlanId] = Plan(nextPlanId, telegramId, amount, frequencyInDays * 60 * 60 * 24);

    nextPlanId++;
  }

  function getPlanSubscriptions(
      uint planId
  ) public view returns(Subscription[] memory) {
      require(planExists(planId), 'No such plan');
      require(msg.sender == getChannelAdminAddress(idToPlan[planId].channelTelegramId) || msg.sender == contractOwner, 'Only channel owner and contract owner are allowed to see channel subscriptions');
      Subscription[] memory subs = new Subscription[](nextSubscriptionId);
      uint subCount = 0;
      for (uint i=1; i<nextSubscriptionId-1; i++) {
          if (idToSubscription[i].planId == planId) {
              subs[subCount++] = idToSubscription[i];
          }
      }
      return subs;
  }

  function getChannelSubscriptions(
    string memory telegramChannelId
  ) external view returns(Subscription[] memory) {
      require(msg.sender == getChannelAdminAddress(telegramChannelId) || msg.sender == contractOwner, 'Only channel owner and contract owner are allowed to see channel subscriptions');
      Plan[] memory plans = getChannelPlans(telegramChannelId);
      Subscription[] memory subs = new Subscription[](nextSubscriptionId); 
      uint subCount = 0;
      for (uint i=0; i<plans.length; i++) {
          Subscription[] memory planSubs = getPlanSubscriptions(plans[i].id);
          for (uint j=0; j<planSubs.length; j++) {
              subs[subCount++] = planSubs[j];
          }
      }
      return subs;
  }

  function getMySubscriptions() external view returns(SubscriptionFullInfo[] memory) {
    require(subscriberExists(msg.sender), 'No such subscriber');
    return getSubscriberSubscriptions(addressToSubscriber[msg.sender].subscriberTelegramId);
  }

  // channels => plans => subscriptions
  function getSubscriberSubscriptions(
    string memory telegramSubscriberId
  ) public view returns(SubscriptionFullInfo[] memory) {
      require(msg.sender == contractOwner, 'Only channel owner is allowed to call this method');
      Subscriber memory subscriber = getSubscriberByTelegramId(telegramSubscriberId);
      SubscriptionFullInfo[] memory subs = new SubscriptionFullInfo[](nextSubscriptionId);
      uint subCount = 0;
      // loop throught all subscriptions and find needed one
      for (uint i=0; i<nextSubscriptionId; i++) {
          if (idToSubscription[i].subscriberAddress == subscriber.subscriberAddress) {
              Subscription memory subscription = idToSubscription[i];
              Plan memory plan = idToPlan[subscription.planId];
              Channel memory channel = telegramIdToChannel[plan.channelTelegramId];
              subs[subCount++] = SubscriptionFullInfo(
                  channel,
                  plan,
                  subscription,
                  subscriber
                );
          }
      }
      return subs;
  }

  function getAllDebtors() external view returns(Subscription[] memory) {
      
  }

  function getMyDebtors() external view returns(Subscription[] memory) {
      // can by admin

      // find all admin channels
      // foreach channel find debtors
  }

  function getChannelDebtors() internal view returns(SubscriberSubscriptionTuple[] memory) {

  }

//   function subscribe(uint planId) external {
//     IERC20 token = IERC20(plans[planId].token);
//     Plan storage plan = plans[planId];
//     require(plan.merchant != address(0), 'this plan does not exist');

//     token.transferFrom(msg.sender, plan.merchant, plan.amount);  
//     emit PaymentSent(
//       msg.sender, 
//       plan.merchant, 
//       plan.amount, 
//       planId, 
//       block.timestamp
//     );

//     subscriptions[msg.sender][planId] = Subscription(
//       msg.sender, 
//       block.timestamp, 
//       block.timestamp + plan.frequency
//     );
//     emit SubscriptionCreated(msg.sender, planId, block.timestamp);
//   }

//   function cancel(uint planId) external {
//     Subscription storage subscription = subscriptions[msg.sender][planId];
//     require(
//       subscription.subscriber != address(0), 
//       'this subscription does not exist'
//     );
//     delete subscriptions[msg.sender][planId]; 
//     emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
//   }

//   function pay(address subscriber, uint planId) external {
//     Subscription storage subscription = subscriptions[subscriber][planId];
//     Plan storage plan = plans[planId];
//     IERC20 token = IERC20(plan.token);
//     require(
//       subscription.subscriber != address(0), 
//       'this subscription does not exist'
//     );
//     require(
//       block.timestamp > subscription.nextPayment,
//       'not due yet'
//     );

//     token.transferFrom(subscriber, plan.merchant, plan.amount);  
//     emit PaymentSent(
//       subscriber,
//       plan.merchant, 
//       plan.amount, 
//       planId, 
//       block.timestamp
//     );
//     subscription.nextPayment = subscription.nextPayment + plan.frequency;
//   }
    function getSubscriberByTelegramId(string memory subscriberTelegramId) internal view returns(Subscriber memory) {
        
    }

    function getChannelByPlanId(uint planId) internal view returns(Channel memory) {
        require(planExists(planId), 'No such plan');
        return telegramIdToChannel[idToPlan[planId].channelTelegramId];
    }

    function getChannelAdminAddress(string memory telegramChannelId) internal view returns(address) {
        require(channelExists(telegramChannelId), 'No such channel');
        return telegramIdToChannel[telegramChannelId].adminAddress;
    }

    function adminExists(address adminAddress) internal view returns(bool) {
        return bytes(addressToAdmin[adminAddress].telegramId).length != 0;
    }

    function channelExists(string memory telegramId) internal view returns(bool) {
        return bytes(telegramIdToChannel[telegramId].telegramId).length != 0;
    }

    function planExists(uint id) internal view returns(bool) {
        return bytes(idToPlan[id].channelTelegramId).length != 0;
    }

    function subscriptionExists(uint id) internal view returns(bool) {
        return idToSubscription[id].subscriberAddress != address(0);
    }

    function subscriberExists(address subscriberAddress) internal view returns(bool) {
        return bytes(addressToSubscriber[subscriberAddress].subscriberTelegramId).length != 0;
    }

    function equalStrings(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface PaymentInterface {
  // STORING STRUCTS
  struct Admin {
    address admingAddress;
    string telegramId;
    uint256 amountFunded;
  }
  struct Channel {
    string telegramId;
    address adminAddress;
  }
  struct Plan {
    uint id;
    string channelTelegramId;
    uint amount;
    uint frequency;
  }
  struct Subscription {
    uint id;
    uint planId;
    address subscriberAddress;
    uint start;
    uint nextPayment;
  }
  struct Subscriber {
    address subscriberAddress;
    string subscriberTelegramId;
  }
  struct SubscriberSubscriptionTuple {
    Subscriber subscriber;
    Subscription subscription;
  }
  struct SubscriptionFullInfo {
      Channel channel;
      Plan plan;
      Subscription subscription;
      Subscriber subscriber;
  }
  function getMyChannels() external view returns(Channel[] memory);
  function addChannel(string memory adminTelegramId, string memory channelTelegramId) external;
  function getChannelPlans(string memory telegramId) external view returns(Plan[] memory);
  function createPlan(
      uint amount, 
      uint frequencyInDays, 
      string memory telegramId
    ) external;
  function getPlanSubscriptions(
      uint planId
  ) external view returns(Subscription[] memory);
  function getChannelSubscriptions(
    string memory telegramChannelId
  ) external view returns(Subscription[] memory);
  function getMySubscriptions() external view returns(SubscriptionFullInfo[] memory);
  function getSubscriberSubscriptions(
    string memory telegramSubscriberId
  ) external view returns(SubscriptionFullInfo[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}