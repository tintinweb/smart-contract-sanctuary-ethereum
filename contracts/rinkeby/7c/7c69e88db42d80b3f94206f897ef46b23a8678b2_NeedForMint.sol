/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract NeedForMint {
    address payable public owner;

    uint256 public subscriptionMonthlyPrice = 0.15 ether;
    uint256 public subscriptionMonthlyPriceDiscounted = 0.09 ether;

    struct User {
        uint subscriptionExpires;
        // 1 - regular, 2 - priceoff, 3 - lifetime, 42 - admin
        uint role;
        bool inited;
    }

    mapping(address => User) private users;

    constructor() {
        owner = payable(msg.sender);
        users[msg.sender] = User(0, 42, true);
    }

    modifier onlyAdmin() {
        require(users[msg.sender].role == 42, "You are not in admin list");
        _;
    }

    function setSubscriptionPrice(uint256 _newSubscriptionPrice) external onlyAdmin {
        subscriptionMonthlyPrice = _newSubscriptionPrice;
    }

    function setSubscriptionDiscountPrice(uint256 _newSubscriptionPrice) external onlyAdmin {
        subscriptionMonthlyPriceDiscounted = _newSubscriptionPrice;
    }

    function modifyUser(address _address, uint8 _role) external onlyAdmin {
        User memory user = User(block.timestamp, _role, true);
        users[_address] = user;
    }

    function setSubscription(address _address, uint256 _timestamp) external onlyAdmin {
        users[_address].subscriptionExpires = _timestamp;
    }

    function getSubscriptionStatus() external view returns (bool) {
        return _getSubscriptionStatus(msg.sender);
    }

    function getUserSubscriptionStatus(address _address) external view returns (bool) {
        return _getSubscriptionStatus(_address);
    }

    function getUserSubscriptionExpires(address _address) external view returns (uint256) {
        User memory user = users[_address];
        return user.subscriptionExpires;
    }

    function _getSubscriptionStatus(address _address) private view returns (bool) {
        uint256 timeNow = block.timestamp;
        User memory user = users[_address];
        if (user.role == 3) return true;
        if (user.role == 42) return true;

        uint256 userSubscriptionExpires = users[_address].subscriptionExpires;
        bool isUserSubscribed = userSubscriptionExpires >= timeNow;
        return isUserSubscribed;
    }

    function getUserRole(address _address) external view returns (uint256) {
        User memory user = users[_address];
        return user.role;
    }


    function subscriptionRenewal() public payable {
        if (users[msg.sender].inited == false) {
            users[msg.sender] = User(1, 1, true);
        }

        if (users[msg.sender].role == 2) {
            require(msg.value == subscriptionMonthlyPriceDiscounted, "You should send exact amount of ETH");
        }
        if (users[msg.sender].role == 1) {
            require(msg.value == subscriptionMonthlyPrice, "You should send exact amount of ETH");
        }

        uint256 currentUserExpiresTimestamp = users[msg.sender].subscriptionExpires;
        uint256 timeNow = block.timestamp;
        if (timeNow > currentUserExpiresTimestamp) {
            users[msg.sender].subscriptionExpires = timeNow + 30 days;
        } else {
            users[msg.sender].subscriptionExpires = currentUserExpiresTimestamp + 30 days;
        }
    }

    function withdrawAll(uint256 _amount) public payable onlyAdmin {
        require(_amount <= address(this).balance, "Insufficient funds");
        owner.transfer(_amount);
    }
}