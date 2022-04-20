// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Payment {
    uint public nextPlanId;

    enum Target {
        Event,
        User,
        Artist
    }

    struct Plan {
        address merchant;
        // address token; 
        uint256 amount;
        uint256 frequency; // 28days 2419200 29days 2505600 30days 2592000 31days 2678400 1,3,5,7,8,10,12 -> 31 / 4,6,9,11 -> 30 / 2 -> 28,29
                        // 1 months	    2629743
                        // 3 months 	7889230
                        // 6 months 	15778460
                        // 1 year 		31556926
        Target target;
    }

    struct Subscription {
        address subscriber;
        uint256 start;
        uint256 nextPayment;
        bool isSubscribe;
    }

    mapping(uint256 => Plan) public plans;
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;

    event PlanCreated(address indexed merchant, uint256 indexed planId, uint256 date);
    event SubscriptionCreated(address indexed subscriber, uint256 indexed planId, uint256 date);
    event SubscriptionCancelled(address indexed subscriber, uint256 indexed planId, uint256 date);
    event PaymentSent(address indexed from, address to, uint256 amount, uint256 indexed planId, uint256 date);

    function createPlan(uint256 amount, uint256 frequency, Target target) 
        external 
    {
        // require(token != address(0), "address cannot be null address");
        require(amount > 0, "amount needs to be > 0");
        require(frequency > 0, "frequency needs to be > 0");
        plans[nextPlanId] = Plan(msg.sender, amount, frequency, target);
        emit PlanCreated(msg.sender, nextPlanId, block.timestamp);
        nextPlanId++;
    }

    function subscribe(uint256 planId)
         external 
         payable
    {
        // IERC20 token = IERC20(plans[planId].token);
        Plan storage plan = plans[planId];
        require(plan.merchant != address(0), "this plan does not exist");

        // token.transferFrom(msg.sender, plan.merchant, plan.amount);  
        payable(plan.merchant).transfer(plan.amount);
        emit PaymentSent(msg.sender, plan.merchant, plan.amount, planId, block.timestamp);

        subscriptions[msg.sender][planId] = Subscription(msg.sender, block.timestamp, block.timestamp + plan.frequency, true);
        emit SubscriptionCreated(msg.sender, planId, block.timestamp + plan.frequency);
    }

    function cancel(uint256 planId) 
        external 
    {
        Subscription storage subscription = subscriptions[msg.sender][planId];
        require(subscription.subscriber != address(0), "this subscription does not exist");
        subscription.isSubscribe = false;
        emit SubscriptionCancelled(msg.sender, planId, block.timestamp);
    }

    function pay(uint256 planId) 
        external 
        payable
    {
        Subscription storage subscription = subscriptions[msg.sender][planId];
        Plan storage plan = plans[planId];
        // IERC20 token ;
        require(subscription.subscriber != address(0), "this subscription does not exist");
        require(block.timestamp > subscription.nextPayment, "not due yet");
        // token.transferFrom(subscriber,plan.merchant, msg.value);
        payable(plan.merchant).transfer(msg.value);
        // token.transferFrom(subscriber, plan.merchant, plan.amount);  
        // payable(plan.merchant).transfer
        emit PaymentSent(msg.sender, plan.merchant, plan.amount, planId, block.timestamp + plan.frequency);
        subscription.nextPayment = subscription.nextPayment + plan.frequency;
    }

    struct userPlan {
        uint256 amount;
        uint256 frequency;
        Target target;
    }

    function getAllPlans()
        public
        view
        returns(userPlan[] memory)
    {
        uint256 planLengths = nextPlanId;

        userPlan[] memory userPlans = new userPlan[](planLengths);

        for(uint256 i = 0; i < planLengths; i++){
            uint256 amount = plans[i].amount;
            uint256 frequency = plans[i].frequency;
            Target target = plans[i].target;
            userPlans[i] = userPlan(amount, frequency, target);
        }
        
        return userPlans;
    }

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