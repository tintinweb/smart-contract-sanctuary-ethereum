/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract NeedForMint {
    address payable public owner;

    uint public subscriptionMonthlyPrice = 0.15 ether;
    uint public subscriptionMonthlyPriceDiscounted = 0.09 ether;

    struct User {
        uint subscriptionExpires;
        // 1 - regular, 2 - priceoff, 3 - lifetime, 4 - admin
        uint role;
    }

    mapping(address => User) private users;

    constructor() {
        owner = payable(msg.sender);
        users[msg.sender] = User(0, 42);
    }

    modifier onlyAdmin() {
        require(users[msg.sender].role == 42, "You are not in admin list");
        _;
    }

    event Renewal(address wallet, uint endtimestamp);

    function setSubscriptionPrice(uint _newSubscriptionPrice)
        external
        onlyAdmin
    {
        subscriptionMonthlyPrice = _newSubscriptionPrice;
    }

    function setSubscriptionDiscountPrice(uint _newSubscriptionPrice)
        external
        onlyAdmin
    {
        subscriptionMonthlyPriceDiscounted = _newSubscriptionPrice;
    }

    function modifyUser(address _address, uint _role) external onlyAdmin {
        User memory user = User(block.timestamp, _role);
        users[_address] = user;
    }

    function setSubscription(address _address, uint _timestamp)
        external
        onlyAdmin
    {
        users[_address].subscriptionExpires = _timestamp;
    }

    function getSubscriptionStatus() external view returns (bool) {
        return _getSubscriptionStatus(msg.sender);
    }

    function getUserSubscriptionStatus(address _address)
        external
        view
        returns (bool)
    {
        return _getSubscriptionStatus(_address);
    }

    function getUserSubscriptionExpires(address _address)
        external
        view
        returns (uint)
    {
        User memory user = users[_address];
        return user.subscriptionExpires;
    }

    function _getSubscriptionStatus(address _address)
        private
        view
        returns (bool)
    {
        uint timeNow = block.timestamp;
        User memory user = users[_address];
        if (user.role == 3) return true;
        if (user.role == 42) return true;

        uint userSubscriptionExpires = users[_address].subscriptionExpires;
        bool isUserSubscribed = userSubscriptionExpires >= timeNow;
        return isUserSubscribed;
    }

    function getUserRole(address _address) external view returns (uint) {
        User memory user = users[_address];
        return user.role;
    }

    function subscriptionRenewal() public payable {
        uint blockTimestamp = block.timestamp;
        uint month = 30 days;

        if (users[msg.sender].role == 2) {
            require(
                msg.value == subscriptionMonthlyPriceDiscounted,
                "You should send exact amount of ETH"
            );
        } else {
            require(
                msg.value == subscriptionMonthlyPrice,
                "You should send exact amount of ETH"
            );
        }

        if (users[msg.sender].role == 0) {
            users[msg.sender] = User(0, 1);
        }

        uint currentUserExpiresTimestamp = users[msg.sender]
            .subscriptionExpires;
        if (blockTimestamp > currentUserExpiresTimestamp) {
            users[msg.sender].subscriptionExpires = blockTimestamp + month;
        } else {
            users[msg.sender].subscriptionExpires =
                currentUserExpiresTimestamp +
                month;
        }
        emit Renewal(msg.sender, users[msg.sender].subscriptionExpires);
    }

    function withdrawAll(uint _amount) public payable onlyAdmin {
        require(_amount <= address(this).balance, "Insufficient funds");
        owner.transfer(_amount);
    }
}