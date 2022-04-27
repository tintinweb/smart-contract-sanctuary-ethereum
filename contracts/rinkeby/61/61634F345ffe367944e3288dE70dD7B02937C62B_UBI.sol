//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

contract UBI {
    event EnableSubscriptions(bool enable);
    event DisableSubscriptions(bool enable);
    
    event Subscribe(address addr);
    event Unsubscribe(address addr);
    
    address[] private subscribers;
    mapping(address => uint) private subscribersIndexed;
    mapping(address => uint) private subscribersClaim;
    uint index;

    address private owner;
    address private cron;

    // check if subs/claims are enabled
    bool private subEnable;
    
    // track the passed time
    uint private timePassed;

    uint private balance;

    constructor(address _cron) {
        subEnable = false;
        
        index = 0;
        balance = address(this).balance;
        owner = msg.sender;
        cron = _cron;

        timePassed = 0 minutes;
    }

    function donate() public payable returns (string memory) {
        require(msg.value > 0);
        balance += msg.value;
        return string(abi.encodePacked("Thank you for your donation, ", msg.sender));

    }

    function enableSubscriptionsToChains() public onlyOwner {
        emit EnableSubscriptions(true);
    }

    function disableSubscriptionsToChains() public onlyOwner {
        emit DisableSubscriptions(false);
    }

    function enableSubscription() public onlyCron {
        // require(address(this).balance > 0, "Not enough balance to distribute.");
        require(!subEnable, "Subscriptions already enabled.");

        subEnable = true;
    }

    function disableSubscription() public onlyCron {
        require(subEnable, "Subscriptions are not enabled.");
        require(timePassed >= 10 minutes, "Not enough time has passed");

        timePassed = 0 minutes;
        subEnable = false;
        
    }

    // It executes every x amount of time since subscriptions have been enabled.
    function checkIncomes() public onlyCron returns (uint) {
        require(subEnable, "Subscriptions are not enabled.");
        uint share = balance / (subscribers.length);
        for(uint i = 0; i < subscribers.length; i++){
            subscribersClaim[subscribers[i]] += share;
            balance -= share;
        }

        // Cron is legit no need for checking block time trust me bro
        timePassed += 2 minutes;
        // console.log("Calculated income: %s", share);
        return balance;
    }


    // Will do later some sort of struct/array to enable claimings by each individual subscription.
    // At the moment will leave it to just globally letting subscribers claim tokens.
    function claimTokens() public {
        require(exists(msg.sender) != 0, "Address not subscribed in the first place.");
        require(!subEnable, "Subscriptions are not disabled.");
        (bool success, ) = msg.sender.call{value: subscribersClaim[msg.sender]}("");
        require(success, "Error claiming token.");
        // console.log("Subscribers claim: %s", subscribersClaim[msg.sender]);
        subscribersClaim[msg.sender] = 0;
    }

    function subscribe() public {
        require(subEnable, "Subscriptions are not enabled.");
        require(exists(msg.sender) == 0, "Address already subscribed.");
        emit Subscribe(msg.sender);
    }

    function unsubscribe() public {
        require(subEnable, "Subscriptions are not enabled.");
        require(exists(msg.sender) != 0, "Address not subscribed in the first place.");
        emit Unsubscribe(msg.sender);
    }
    
    function getSubscription(address addr) public onlyCron {
        subscribers.push(addr);
        subscribersIndexed[addr] = index + 1;
    }

    
    function stopSubscription(address addr) public onlyCron{
        uint _index = exists(addr);
        require(_index != 0, "Address not subscribed in the first place.");

        subscribers[_index - 1] = subscribers[subscribers.length - 1];
        subscribers.pop();

        subscribersIndexed[msg.sender] = 0;

    }

    function exists(address item) private view returns (uint) {
        return subscribersIndexed[item];
    }

    function isSubscribed() public view returns (bool){
        if(exists(msg.sender) != 0){
            return true;
        }

        return false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyCron() {
        require(msg.sender == cron);
        _;
    }
}