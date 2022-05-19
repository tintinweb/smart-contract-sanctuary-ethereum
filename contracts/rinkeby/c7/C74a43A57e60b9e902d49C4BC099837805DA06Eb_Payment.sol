// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "PaymentInterface.sol";
import "IERC20.sol";

contract Payment is PaymentInterface {
    address owner;  
    IERC20 token;
    // USER
    address[] userAddresses;
    mapping(address => User) addressToUser;
    // CHANNEL
    string[] channelTelegramIds;
    mapping(string => Channel) telegramIdToChannel;
    // PLAN
    uint nextPlanId;
    mapping(uint => Plan) idToPlan;
    // SUBSCRIPTION
    uint nextSubscriptionId;
    mapping(uint => Subscription) idToSubscription;

    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    function getMyTelegramId() external view returns(string memory) {
        require(userExists(msg.sender), 'Register with your telegramId first');
        return addressToUser[msg.sender].userTelegramId;
    }

    function addUser(string memory userTelegramId) external {
        require(!userExists(msg.sender), 'You can register only one telegramId');
        require(!accountVerified(userTelegramId), 'This account is already verified');
        
        User memory user = getUserByTelegramId(userTelegramId);

        // we already know that this account is not verified yet
        if (user.userAddress != address(0) && user.userAddress != msg.sender) {
            replaceUser(user.userAddress, msg.sender, userTelegramId);
        } else {
            userAddresses.push(msg.sender);
            addressToUser[msg.sender] = User(msg.sender, userTelegramId, false);
        }
    }

    function replaceUser(address oldAddress, address newAddress, string memory userTelegramId) internal {
        for (uint i=0; i<userAddresses.length; i++) {
            if (userAddresses[i] == oldAddress) {
                userAddresses[i] = newAddress;
            }
        }
        delete addressToUser[oldAddress];
        addressToUser[newAddress] = User(newAddress, userTelegramId, false);
    }

    function verifyUser(string memory userTelegramId) external {
        require(msg.sender == owner, 'Only contract owner can verify users');
        require(getUserByTelegramId(userTelegramId).userAddress != address(0), 'No such account');
        require(!accountVerified(userTelegramId), 'This account is already verified');
        
        User storage user = addressToUser[getUserByTelegramId(userTelegramId).userAddress];
        user.isVerified = true;
    }

    function getMyChannels() public view returns(Channel[] memory) {
        require(userVerified(msg.sender), 'Only for verified users');
        require(userExists(msg.sender), 'No such user');
        Channel[] memory channels = new Channel[](channelTelegramIds.length);
        uint channelCount = 0;
        for (uint i=0; i<channelTelegramIds.length; i++) {
            string memory channelTelegramId = channelTelegramIds[i];
            if (telegramIdToChannel[channelTelegramId].adminAddress == msg.sender) {
                channels[channelCount++] = telegramIdToChannel[channelTelegramId];
            }
        }
        // copy array to delete null entries 
        Channel[] memory result = new Channel[](channelCount);
        for (uint i=0; i<channelCount; i++) {
            result[i] = channels[i];
        }
        return result;
    }

    function getMyUserAccount() public view returns(User memory) {
        require(userExists(msg.sender), 'No such user');
        return addressToUser[msg.sender];
    }

    //   function getMyPlans() public view returns(Plan[] memory) {
    //       require(adminExists(msg.sender), 'No such admin');
    //       Channel[] memory channels = new Channel[](channelTelegramIds.length);
    //       uint channelCount = 0;
    //       for (uint i=0; i<channelTelegramIds.length; i++) {
    //         string memory channelTelegramId = channelTelegramIds[i];
    //         if (telegramIdToChannel[channelTelegramId].adminAddress == msg.sender) {
    //             channels[channelCount++] = telegramIdToChannel[channelTelegramId];
    //         }
    //     }
    //     return channels;
    //   }

    function addChannel(string memory adminTelegramId, string memory channelTelegramId) external {
        require(msg.sender == owner, 'This method is allowed only for contract owner');
        require(!channelExists(channelTelegramId), 'Channel already exists');
        User memory admin = getUserByTelegramId(adminTelegramId);
        require(admin.userAddress != address(0), 'No such user');
        channelTelegramIds.push(channelTelegramId);
        telegramIdToChannel[channelTelegramId] = Channel(channelTelegramId, admin.userAddress);
    }

    function getChannelPlans(string memory telegramId) public view returns(Plan[] memory) {
        require(channelExists(telegramId), 'No such channel');
        Plan[] memory plans = new Plan[](nextPlanId);
        uint planCount = 0;
        for (uint i=0; i<nextPlanId; i++) {
            if (equalStrings(idToPlan[i].channelTelegramId, telegramId)) {
                plans[planCount++] = idToPlan[i];
            }
        }
        // copy array to delete null entries 
        Plan[] memory result = new Plan[](planCount);
        for (uint i=0; i<planCount; i++) {
            result[i] = plans[i];
        }
        return result;
    }

    function createPlan(
        uint amount, 
        uint frequencyInDays, 
        string memory telegramId
        ) external {
        require(userVerified(msg.sender), 'Only for verified users');
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
        require(msg.sender == getChannelAdminAddress(idToPlan[planId].channelTelegramId) || msg.sender == owner, 'Only channel admin and contract owner are allowed to see channel subscriptions');
        Subscription[] memory subs = new Subscription[](nextSubscriptionId);
        uint subCount = 0;
        for (uint i=0; i<nextSubscriptionId; i++) {
            if (idToSubscription[i].planId == planId) {
                subs[subCount++] = idToSubscription[i];
            }
        }
        // copy array to delete null entries 
        Subscription[] memory result = new Subscription[](subCount);
        for (uint i=0; i<subCount; i++) {
            result[i] = subs[i];
        }
        return result;
    }

    function getChannelSubscriptions(
        string memory channelTelegramId
    ) external view returns(Subscription[] memory) {
        require(msg.sender == getChannelAdminAddress(channelTelegramId) || msg.sender == owner, 'Only channel owner and contract owner are allowed to see channel subscriptions');
        Plan[] memory plans = getChannelPlans(channelTelegramId);
        Subscription[] memory subs = new Subscription[](nextSubscriptionId); 
        uint subCount = 0;
        for (uint i=0; i<plans.length; i++) {
            Subscription[] memory planSubs = getPlanSubscriptions(plans[i].id);
            for (uint j=0; j<planSubs.length; j++) {
                subs[subCount++] = planSubs[j];
            }
        }
        // copy array to delete null entries 
        Subscription[] memory result = new Subscription[](subCount);
        for (uint i=0; i<subCount; i++) {
            result[i] = subs[i];
        }
        return result;
    }

    function getMySubscriptions() external view returns(SubscriptionFullInfo[] memory) {
        require(userVerified(msg.sender), 'Only for verified users');
        require(userExists(msg.sender), 'No such user');
        return getSubscriberSubscriptions(addressToUser[msg.sender].userTelegramId);
    }

    function getSubscriberSubscriptions(
        string memory telegramSubscriberId
    ) public view returns(SubscriptionFullInfo[] memory) {
        require(msg.sender == owner || msg.sender == getUserByTelegramId(telegramSubscriberId).userAddress, 'Only channel owner and subscriber are allowed to call this method');
        User memory subscriber = getUserByTelegramId(telegramSubscriberId);
        SubscriptionFullInfo[] memory subs = new SubscriptionFullInfo[](nextSubscriptionId);
        uint subCount = 0;
        // loop throught all subscriptions and find needed one
        for (uint i=0; i<nextSubscriptionId; i++) {
            if (idToSubscription[i].subscriberAddress == subscriber.userAddress) {
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

        // copy array to delete null entries 
        SubscriptionFullInfo[] memory result = new SubscriptionFullInfo[](subCount);
        for (uint i=0; i<subCount; i++) {
            result[i] = subs[i];
        }
        return result;
    }

    function getAllDebtors() external view returns(UserSubscription[] memory) {
        UserSubscription[] memory debtors = new UserSubscription[](nextSubscriptionId);
        uint debtCount = 0;
        for (uint i=0; i<nextSubscriptionId; i++) {
            Subscription memory sub = idToSubscription[i];
            if (block.timestamp > sub.nextPayment) {
                debtors[debtCount++] = UserSubscription(getSubscriptionSubscriber(sub), sub);
            }
        }
        // copy array to delete null entries 
        UserSubscription[] memory result = new UserSubscription[](debtCount);
        for (uint i=0; i<debtCount; i++) {
            result[i] = debtors[i];
        }
        return result;
    }

    function getMyDebtors() external view returns(UserSubscription[] memory) {
        require(userVerified(msg.sender), 'Only for verified users');
        require(userExists(msg.sender), 'No such user');
        Channel[] memory channels = getMyChannels();
        UserSubscription[] memory debtors = new UserSubscription[](nextSubscriptionId);
        uint debtCount = 0;
        for (uint i=0; i<channels.length; i++) {
            Channel memory channel = channels[i];
            Plan[] memory plans = getChannelPlans(channel.telegramId);
            for (uint j=0; j<plans.length; j++) {
                Plan memory plan = plans[j];
                Subscription[] memory subs = getPlanSubscriptions(plan.id);
                for (uint k=0; k<subs.length; k++) {
                    Subscription memory sub = subs[k];
                    if (block.timestamp > sub.nextPayment) {
                        debtors[debtCount++] = UserSubscription(getSubscriptionSubscriber(sub), sub);
                    }
                }
            }
        }
        // copy array to delete null entries 
        UserSubscription[] memory result = new UserSubscription[](debtCount);
        for (uint i=0; i<debtCount; i++) {
            result[i] = debtors[i];
        }
        return result;
    }

    function subscribe(
        string memory channelTelegramId,
        uint planId
    ) external {
        require(userExists(msg.sender), 'No such user');
        require(channelExists(channelTelegramId), 'No such channel');
        require(planExists(planId), 'No such plan');
        require(equalStrings(idToPlan[planId].channelTelegramId, channelTelegramId), 'This plan does not belong to provided channel');
        require(!userSubscribed(channelTelegramId), 'You are already subscribed to this channel');
        require(getChannelAdminAddress(channelTelegramId) != msg.sender, 'You can not subscribe to your own channel');

        Plan storage plan = idToPlan[planId];
        User storage admin = addressToUser[getChannelAdminAddress(channelTelegramId)];

        token.transferFrom(msg.sender, admin.userAddress, plan.amount);  
        // emit PaymentSent(
        //   msg.sender, 
        //   plan.merchant, 
        //   plan.amount, 
        //   planId, 
        //   block.timestamp
        // );

        idToSubscription[nextSubscriptionId] = Subscription(
            nextSubscriptionId, 
            planId, msg.sender, 
            block.timestamp, 
            block.timestamp + plan.frequency
        );
        nextSubscriptionId++;

        // emit SubscriptionCreated(msg.sender, planId, block.timestamp);
    }

    function cancel(uint subscriptionId) external {
        require(subscriptionExists(subscriptionId), 'No such subscription');
        require(msg.sender == idToSubscription[subscriptionId].subscriberAddress || msg.sender == owner, 'You are not allowed to call this method');
        delete idToSubscription[subscriptionId];
        // emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
    }

    function pay(uint subscriptionId) external {
        require(subscriptionExists(subscriptionId), 'No such subscription');
        Subscription storage sub = idToSubscription[subscriptionId];
        Plan storage plan = idToPlan[sub.planId];
        require(
        block.timestamp > sub.nextPayment,
        'Not due yet'
        );

        Channel storage channel = getChannelByPlanId(plan.id);
        User storage admin = addressToUser[getChannelAdminAddress(channel.telegramId)];

        token.transferFrom(sub.subscriberAddress, admin.userAddress, plan.amount);  
        // emit PaymentSent(
        //   subscriber,
        //   plan.merchant, 
        //   plan.amount, 
        //   planId, 
        //   block.timestamp
        // );
        sub.nextPayment = sub.nextPayment + plan.frequency;
    }

    function getUserByTelegramId(string memory userTelegramId) internal view returns(User memory) {
        for (uint i=0; i<userAddresses.length; i++) {
            if (equalStrings(addressToUser[userAddresses[i]].userTelegramId, userTelegramId)) {
                return addressToUser[userAddresses[i]];
            }
            // returns nothing if not found
        }
    }

    function userSubscribed(string memory channelTelegramId) internal view returns(bool) {
        address userAddress = msg.sender;
        require(userExists(userAddress), 'No such user');

        for (uint i=0; i<nextSubscriptionId; i++) {
            if (equalStrings(idToPlan[idToSubscription[i].planId].channelTelegramId, channelTelegramId) && idToSubscription[i].subscriberAddress == userAddress) {
                return true;
            }
        }
        return false;
    }

    function getChannelByPlanId(uint planId) internal view returns(Channel storage) {
        require(planExists(planId), 'No such plan');
        return telegramIdToChannel[idToPlan[planId].channelTelegramId];
    }

    function getChannelAdminAddress(string memory channelTelegramId) internal view returns(address) {
        require(channelExists(channelTelegramId), 'No such channel');
        return telegramIdToChannel[channelTelegramId].adminAddress;
    }

    function userExists(address userAddress) internal view returns(bool) {
        return bytes(addressToUser[userAddress].userTelegramId).length != 0;
    }

    function userVerified(address userAddress) internal view returns(bool) {
        return addressToUser[userAddress].isVerified;
    }

    function accountVerified(string memory userTelegramId) internal view returns(bool) {
        return getUserByTelegramId(userTelegramId).isVerified;
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

    function getSubscriptionSubscriber(Subscription memory sub) internal view returns(User memory) {
        return addressToUser[sub.subscriberAddress];
    }

    function equalStrings(string memory a, string memory b) internal pure returns(bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface PaymentInterface {
  // STORING STRUCTS
  struct User {
    address userAddress;
    string userTelegramId;
    bool isVerified;
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
  struct UserSubscription {
    User subscriber;
    Subscription subscription;
  }
  struct SubscriptionFullInfo {
      Channel channel;
      Plan plan;
      Subscription subscription;
      User subscriber;
  }
  struct Debtor {
    string channelTelegramId;
    Plan plan;
    Subscription subscription;
    User subscriber;
  }

  function getMyTelegramId() external view returns(string memory);
  function addUser(string memory userTelegramId) external;
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
  function getAllDebtors() external view returns(UserSubscription[] memory);
  function getMyDebtors() external view returns(UserSubscription[] memory);
  function subscribe(
      string memory channelTelegramId,
      uint planId
  ) external;
  function cancel(uint subscriptionId) external;
  function pay(uint subscriptionId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}