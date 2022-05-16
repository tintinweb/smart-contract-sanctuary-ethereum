/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.7.0 <0.9.0;

contract Subscribe is Ownable {
    string public name;
    bool public isPaused = false;
    uint public refundPeriod = 7 days;
    uint public lastWithdrawIndex = 0;
    mapping(uint => uint) public plans;
    mapping(string => DiscountedConditions) public discounts;
    mapping(uint => uint[]) public subscribers_by_user_address;
    mapping(address => uint[]) public influencers;
    mapping(address => InfluencerWithdraws[]) public influencer_withdraws;
    mapping(address => string[]) public influencer_promos;
    mapping(uint => UserService) public user_service;
    string[] public discounts_list;
    SubscribedPlan[] public subscribers;

    struct UserService {
        address user;
        uint user_unique_id;
        uint256 expire_date;
    }

    struct SubscribedPlan {
        address user;
        uint user_unique_id;
        uint plan_price;
        uint plan;
        uint256 date;
        uint refund_price;
        bool refunded;
        uint256 refund_date;
        string discount_name;
        uint discount_percent;
        address influencer_address;
        uint influencer_percent;
        bool influencer_withdrawed;
        bool withdrawed;
    }

    struct DiscountedConditions {
        string name;
        uint percent;
        address influencer_address;
        uint influencer_percent;
        uint256 date;
        bool deleted;
        uint256 deleted_date;
        uint used_count;
        uint total_eth_sent;
    }

    struct InfluencerWithdraws {
        address influencer_address;
        address caller_address;
        uint amount;
        uint256 date;
    }
   
    event PlanCreated(
        uint plan,
        uint price
    );

    event PlanRemoved(
        uint plan
    );

    event DiscountCreated(
        string name,
        uint percent,
        address influencer_address,
        uint influencer_percent,
        uint256 date
    );

    event DiscountRemoved(
        string name
    );
    
    constructor() {
        name = "CryptoMarketDarts";
        planCreate(30, 13000000000000000);
        planCreate(180, 67000000000000000);
        planCreate(360, 117000000000000000);
    }

    function subscribeDeposit(uint _plan, string memory _discount_name, uint user_unique_id) public payable {
        require(!isPaused, "Subscribtions are paused at the moment");
        require(_plan > 0, "Plan does not exist.");
        require(plans[_plan] > 0, "Plan does not exist.");
        require(user_unique_id > 0, "_unique_subscribe_str can't be empty");
        
        uint sent_val = msg.value;
        uint price_to_be_paid = plans[_plan];

        uint __discount_percent = 0;
        address __discount_influencer_address = address(0);
        uint __discount_influencer_percent = 0;
        bool __discount_influencer_withdrawed = false;
        
        if(bytes(_discount_name).length > 0) {

            DiscountedConditions memory dc = discounts[_discount_name];
            require(bytes(dc.name).length > 0 && dc.percent > 0 && dc.percent <= 100 && !dc.deleted, "Discount does not exists");
            price_to_be_paid = plans[_plan] * (100 - dc.percent) / 100;
            __discount_percent = dc.percent;
            __discount_influencer_address = dc.influencer_address;
            __discount_influencer_percent = dc.influencer_percent;
            if(dc.influencer_address != address(0)) {

                influencers[dc.influencer_address].push(subscribers.length);
            }
            discounts[_discount_name].used_count = discounts[_discount_name].used_count + 1;
            discounts[_discount_name].total_eth_sent = discounts[_discount_name].total_eth_sent + plans[_plan];
        }
        require(sent_val >= price_to_be_paid, "Insufficient Ether amount for current plan.");

        SubscribedPlan memory subscribed_plan;
        subscribed_plan.user = msg.sender;
        subscribed_plan.user_unique_id = user_unique_id;
        subscribed_plan.plan_price = plans[_plan];
        subscribed_plan.plan = _plan;
        subscribed_plan.date = block.timestamp;
        subscribed_plan.refund_price = price_to_be_paid;
        subscribed_plan.refunded = false;
        subscribed_plan.refund_date = 0;
        subscribed_plan.discount_name = _discount_name;
        subscribed_plan.discount_percent = __discount_percent;
        subscribed_plan.influencer_address = __discount_influencer_address;
        subscribed_plan.influencer_percent = __discount_influencer_percent;
        subscribed_plan.influencer_withdrawed = __discount_influencer_withdrawed;
        subscribed_plan.withdrawed = false;

        subscribers_by_user_address[user_unique_id].push(subscribers.length);
        subscribers.push(subscribed_plan);

        uint256 plan_days = _plan * 24 * 60 * 60;
        if(user_service[user_unique_id].user == address(0)) {

            UserService memory _user_service;
            _user_service.user = msg.sender;
            _user_service.user_unique_id = user_unique_id;
            _user_service.expire_date = block.timestamp + plan_days;

            user_service[user_unique_id] = _user_service;
        } else {

            if(user_service[user_unique_id].expire_date > block.timestamp) {
            
                user_service[user_unique_id].expire_date = user_service[user_unique_id].expire_date + plan_days;
            } else {

                user_service[user_unique_id].expire_date = block.timestamp + plan_days;
            }
        }
    }

    function getInfluencerInvoicesInfo(address user) public view returns(uint, uint, uint) {

        if(msg.sender != owner()) {

            require(user == msg.sender, "You are not an Influencer");
        }
        uint influencerWithdrawableBalance = 0;
        uint influencerRefundableBalance = 0;
        for (uint i = 0; i < influencers[user].length; i++) {
            SubscribedPlan storage lBid = subscribers[influencers[user][i]];
            if(refundPeriod < block.timestamp - lBid.date && !lBid.refunded && !lBid.influencer_withdrawed) {

                influencerWithdrawableBalance = influencerWithdrawableBalance + lBid.influencer_percent * lBid.plan_price / 100;
                
            } else {

                if(!lBid.refunded && !lBid.influencer_withdrawed) {

                    influencerRefundableBalance = influencerRefundableBalance + lBid.refund_price;
                }
                
            }
        }
        return (influencers[user].length, influencerWithdrawableBalance, influencerRefundableBalance);
    }

    function getInfluencerInvoicesData(address user) public view returns(SubscribedPlan[] memory) {

        if(msg.sender != owner()) {

            require(user == msg.sender, "You are not an Influencer");
        }

        SubscribedPlan[] memory lBids = new SubscribedPlan[](influencers[user].length);
        for (uint i = 0; i < influencers[user].length; i++) {
            SubscribedPlan storage lBid = subscribers[influencers[user][i]];
            lBids[i] = lBid;
        }
        return lBids;
    }

    function getSubscribersCount() public view returns(uint count) {
        return subscribers.length;
    }

    function getPromosCount() public view returns(uint count) {
        return discounts_list.length;
    }

    function getUserSubscribesByAddress(uint user_unique_id) public view returns (SubscribedPlan[] memory){

        SubscribedPlan[] memory lBids = new SubscribedPlan[](subscribers_by_user_address[user_unique_id].length);
        for (uint i = 0; i < subscribers_by_user_address[user_unique_id].length; i++) {
            SubscribedPlan storage lBid = subscribers[subscribers_by_user_address[user_unique_id][i]];
            lBids[i] = lBid;
        }
        return lBids;
    }

    function getUserSubscribesCount(uint user_unique_id) public view returns(uint count) {
        return subscribers_by_user_address[user_unique_id].length;
    }

    function getInfluencerPromoCount(address user) public view returns(uint count) {

        return influencer_promos[user].length;
    }

    function getInfluencerPromos(address user) public view returns(DiscountedConditions[] memory) {
        if(msg.sender != owner()) {

            require(user == msg.sender, "You are not an Influencer");
        }
        
        DiscountedConditions[] memory promosArr = new DiscountedConditions[](influencer_promos[user].length);
        for(uint i = 0; i < influencer_promos[user].length; i++) {

            DiscountedConditions storage lBid = discounts[influencer_promos[user][i]];
            promosArr[i] = lBid;
            
        }

        return promosArr;
    }

    function getInfluencerWithdraws(address user) public view returns(InfluencerWithdraws[] memory) {
        if(msg.sender != owner()) {

            require(user == msg.sender, "You are not an Influencer");
        }
        
        InfluencerWithdraws[] memory withdrawsArr = new InfluencerWithdraws[](influencer_withdraws[user].length);
        for(uint i = 0; i < influencer_withdraws[user].length; i++) {

            InfluencerWithdraws storage lBid = influencer_withdraws[user][i];
            withdrawsArr[i] = lBid;
        }

        return withdrawsArr;
    }

    function refund(uint invoice_key, uint user_unique_id) public payable {

        require(msg.sender != address(0), "Address cannot be blank");
        require(getUserSubscribesCount(user_unique_id) > 0, "User has no outstanding balance");
        require(getUserSubscribesCount(user_unique_id) > invoice_key, "Wrong invoice_key parameter");
        SubscribedPlan storage lBid = subscribers[subscribers_by_user_address[user_unique_id][invoice_key]];
        require(lBid.user == msg.sender, "This Ethereum wallet is not eligible for refund");
        require(!lBid.refunded, "Current invoice has already been refunded");
        require(refundPeriod >= block.timestamp - lBid.date, "Refund period has expired");

        subscribers[subscribers_by_user_address[user_unique_id][invoice_key]].refunded = true;
        subscribers[subscribers_by_user_address[user_unique_id][invoice_key]].refund_date = block.timestamp;

        /////////////////////////////////////////////////////////////////

        uint256 plan_days = lBid.plan * 24 * 60 * 60;
        user_service[user_unique_id].expire_date = user_service[user_unique_id].expire_date - plan_days;
        ///////////////////////////////////////////////////////////////

        (bool success, ) = payable(msg.sender).call{
            value: lBid.refund_price
        }("");
        require(success, "Refund transfer problem. Please try again later.");
    }

    function updateInfluencerInvoicesInfo(address influencer_address) private returns(uint) {

        require(influencers[influencer_address].length > 0, "There are no subscriptions created using this promo code.");
        uint influencerWiithdrawableBalance = 0;
        for (uint i = 0; i < influencers[influencer_address].length; i++) {
            SubscribedPlan storage lBid = subscribers[influencers[influencer_address][i]];
            if(refundPeriod < block.timestamp - lBid.date && !lBid.refunded && !lBid.influencer_withdrawed) {

                influencerWiithdrawableBalance = influencerWiithdrawableBalance + lBid.influencer_percent * lBid.plan_price / 100;
                subscribers[influencers[influencer_address][i]].influencer_withdrawed = true;
            }
        }
        return influencerWiithdrawableBalance;
    }

    function withdrawByInfluencer() public payable {

        uint withdrawSumary = updateInfluencerInvoicesInfo(msg.sender);
        require(withdrawSumary > 0, "There are no funds to withdraw to this wallet");
        (bool successVal, ) = payable(msg.sender).call{
            value: withdrawSumary
        }("");
        require(successVal, "Withdrawal issues with Ethereum network. Please try again later.");

        InfluencerWithdraws memory _influencer_withdraws;
        _influencer_withdraws.influencer_address = msg.sender;
        _influencer_withdraws.caller_address = msg.sender;
        _influencer_withdraws.amount = withdrawSumary;
        _influencer_withdraws.date = block.timestamp;
        influencer_withdraws[msg.sender].push(_influencer_withdraws);
    }
    
    //only owner functions

    function getAllPromos() public view onlyOwner returns(DiscountedConditions[] memory) {
        
        DiscountedConditions[] memory discountsListArr = new DiscountedConditions[](discounts_list.length);
        for(uint i = 0; i < discounts_list.length; i++) {

            DiscountedConditions storage lBid = discounts[discounts_list[i]];
            discountsListArr[i] = lBid;
        }

        return discountsListArr;
    }

    function withdrawInfluencerByAdmin(address influencer_address) public payable onlyOwner {

        uint withdrawSumary = updateInfluencerInvoicesInfo(influencer_address);
        require(withdrawSumary > 0, "There are no funds to withdraw to this wallet");
        (bool successVal, ) = payable(influencer_address).call{
            value: withdrawSumary
        }("");
        require(successVal, "Withdrawal issues with Ethereum network. Please try again later.");

        InfluencerWithdraws memory _influencer_withdraws;
        _influencer_withdraws.influencer_address = influencer_address;
        _influencer_withdraws.caller_address = msg.sender;
        _influencer_withdraws.amount = withdrawSumary;
        _influencer_withdraws.date = block.timestamp;
        influencer_withdraws[influencer_address].push(_influencer_withdraws);
    }

    function setIsPaused(bool _state) public onlyOwner {
        isPaused = _state;
    }

    function setRefundPeriod(uint _refundPeriod) public onlyOwner {
        refundPeriod = _refundPeriod;
    }

    function setLastWithdrawIndex(uint _lastWithdrawIndex) public onlyOwner {
        lastWithdrawIndex = _lastWithdrawIndex;
    }    

    function refundableBalance() public view onlyOwner returns(uint) {

        uint refundSumary = 0;
        for(uint i = 0; i < subscribers.length; i++) {

            if(refundPeriod >= block.timestamp - subscribers[i].date && !subscribers[i].refunded) {

                refundSumary = refundSumary + subscribers[i].refund_price;
            }
        }

        return refundSumary;
    }

    //////////////////////plan create
    function planCreate(uint _plan, uint _price) public onlyOwner {
        // Require valid _plan
        require(_plan > 0 && _plan <= 1080, "Plan date must be more than 0");
        
        require(_price > 0, "Plan date must be more than 0");
        // Create the plan
        plans[_plan] = _price;
        // Trigger event
        emit PlanCreated(_plan, _price);
    }
    
    //////////////////////plan remove
    function planRemove(uint _plan) public onlyOwner {
        // Require valid address
        require(_plan > 0, "Plan must be more than 0");
        
        delete plans[_plan];
        emit PlanRemoved(_plan);
    }

    //////////////////////dicount create
    function discountCreate(string memory _name, uint _percent, address _influencer_address, uint _influencer_percent) public onlyOwner {
        // Require valid _plan
        require(_percent > 0 && _percent <= 100, "Discount percent must be between 1 and 100");
        
        require(bytes(_name).length > 0, "Discount name cannot be empty");
        require(bytes(discounts[_name].name).length == 0, "This discount name is not available");
        require(_influencer_percent <= 100 - _percent, "Influencer AND discount percentage cannot be more than 100%");
        // Create the discount
        if(_influencer_address != address(0)) {
            influencer_promos[_influencer_address].push(_name);
        }
        
        DiscountedConditions memory discounted_conditions;
        discounted_conditions.name = _name;
        discounted_conditions.percent = _percent;
        discounted_conditions.influencer_address = _influencer_address;
        discounted_conditions.influencer_percent = _influencer_percent;
        discounted_conditions.date = block.timestamp;
        discounted_conditions.deleted = false;
        discounted_conditions.deleted_date = 0;
        discounted_conditions.used_count = 0;
        discounted_conditions.total_eth_sent = 0;
        
        discounts[_name] = discounted_conditions;
        discounts_list.push(_name);
        // Trigger event
        emit DiscountCreated(_name, _percent, _influencer_address, _influencer_percent, discounted_conditions.date);
    }
    
    //////////////////////plan remove
    function discountRemove(string memory _name) public onlyOwner {

        require(bytes(_name).length > 0, "Discount name cannot be empty");
        discounts[_name].deleted = true;
        discounts[_name].deleted_date = block.timestamp;
        emit DiscountRemoved(_name);
    }

    function withdraw() public payable onlyOwner {

        bool successArr = false;
        uint withdrawSumary = 0;
        uint withdrawOneTransactionSumary = 0;
        
        for (uint i = lastWithdrawIndex; i < subscribers.length; i++) {
            withdrawOneTransactionSumary = 0;
            successArr = false;
            SubscribedPlan storage lBid = subscribers[i];
            if((refundPeriod < block.timestamp - lBid.date) && !lBid.refunded && !lBid.withdrawed) {

                withdrawOneTransactionSumary = lBid.plan_price - (lBid.influencer_percent + lBid.discount_percent) * lBid.plan_price / 100;
                if(withdrawOneTransactionSumary > 0) {

                    withdrawSumary = withdrawSumary + withdrawOneTransactionSumary;
                    subscribers[i].withdrawed = true;
                    lastWithdrawIndex = i;
                }
            }
        }

        

        require(withdrawSumary > 0, "Withdrawal amount must be more than 0");
        (bool success, ) = payable(msg.sender).call{
            value: withdrawSumary
        }("");
        require(success, "Withdrawal issue with Ethereum network. Please try again later.");
    }

    function withdrawableBalance() public view onlyOwner returns(uint) {

        bool successArr = false;
        uint withdrawSumary = 0;
        uint withdrawOneTransactionSumary = 0;
        
        for (uint i = 0; i < subscribers.length; i++) {
            withdrawOneTransactionSumary = 0;
            successArr = false;
            SubscribedPlan storage lBid = subscribers[i];
            if((refundPeriod < block.timestamp - lBid.date) && !lBid.refunded && !lBid.withdrawed) {

                withdrawOneTransactionSumary = lBid.plan_price - (lBid.influencer_percent + lBid.discount_percent) * lBid.plan_price / 100;
                if(withdrawOneTransactionSumary > 0) {

                    withdrawSumary = withdrawSumary + withdrawOneTransactionSumary;
                }
            }
        }

        return withdrawSumary;
    }
}