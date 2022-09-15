/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

contract NeedForMint {
    address payable public owner;
    uint public subscriptionMonthlyPrice = 0.15 ether;
    uint public subscriptionMonthlyPriceDiscounted = 0.09 ether;

    struct User {
        uint subscriptionExpires;
        // 1 - regular, 2 - priceoff, 3 - lifetime, 42 - admin
        uint role;
        uint ref;
    }
    mapping(address => User) private users;
    mapping(uint => address) private wallets;
    uint public walletsCount;

    constructor() {
        owner = payable(msg.sender);
        walletsCount = 0;
        _storeUser(msg.sender, 0, 42, 0);
    }

    event Renewal(address wallet, uint endtimestamp, uint r);

    modifier onlyAdmin() {
        require(users[msg.sender].role == 42, "You are not in admin list");
        _;
    }

    function _storeUser(address _address, uint _subscriptionExpires, uint _role, uint _ref) internal {
        wallets[walletsCount] = _address;
        users[_address] = User(_subscriptionExpires, _role, _ref);
        walletsCount++;
    }

    function getWallets() public view onlyAdmin returns (address[] memory) {
        address[] memory _wallets = new address[](walletsCount);
        for (uint i = 0; i < walletsCount; i++) {
            _wallets[i] = wallets[i];
        }
        return _wallets;
    }

    function setSubscriptionPrice(uint _newSubscriptionPrice) external onlyAdmin {
        subscriptionMonthlyPrice = _newSubscriptionPrice;
    }

    function setSubscriptionDiscountPrice(uint _newSubscriptionPrice) external onlyAdmin {
        subscriptionMonthlyPriceDiscounted = _newSubscriptionPrice;
    }

    function modifyUser(address _address, uint _subscriptionExpires, uint _role, uint _ref) external onlyAdmin {
        require(owner != _address, "There is no possibility to get rid of the owner");
        User memory user = users[_address];
        if (user.role == 0) {
            _storeUser(_address, _subscriptionExpires, _role, _ref);
        } else {
            users[_address].role = _role;
        }
    }

    function modifyRef(address _address, uint _ref) external onlyAdmin {
        User memory user = users[_address];
        require(user.role > 0, "User does not exist");
        users[_address].ref = _ref;
    }

    function setSubscription(address _address, uint _timestamp) external onlyAdmin {
        User memory user = users[_address];
        require(user.role > 0, "User does not exist");
        users[_address].subscriptionExpires = _timestamp;
    }

    function getSubscriptionStatus() external view returns (bool) {
        return _getSubscriptionStatus(msg.sender);
    }

    function getUserSubscriptionStatus(address _address) external view returns (bool) {
        return _getSubscriptionStatus(_address);
    }

    function getUserSubscriptionExpires(address _address) external view returns (uint) {
        User memory user = users[_address];
        return user.subscriptionExpires;
    }

    function _getSubscriptionStatus(address _address) private view returns (bool) {
        uint timeNow = block.timestamp;
        User memory user = users[_address];
        if (user.role == 3) return true;
        if (user.role == 42) return true;

        uint userSubscriptionExpires = user.subscriptionExpires;
        bool isUserSubscribed = userSubscriptionExpires >= timeNow;
        return isUserSubscribed;
    }

    function getUserRole(address _address) external view returns (uint) {
        User memory user = users[_address];
        return user.role;
    }

    function getUser(address _address) external view onlyAdmin returns (User memory) {
        User memory user = users[_address];
        return user;
    }

    function subscriptionRenewal(uint _ref) public payable {
        User memory user = users[msg.sender];
        if (user.role == 0) {
            _storeUser(msg.sender, 1, 1, _ref);
        }
        if (user.role == 1) {
            require(msg.value == subscriptionMonthlyPrice, "You should send exact amount of ETH");
        }
        if (user.role == 2) {
            require(msg.value == subscriptionMonthlyPriceDiscounted, "You should send exact amount of ETH");
        }

        uint currentUserExpiresTimestamp = user.subscriptionExpires;
        uint timeNow = block.timestamp;
        if (timeNow > currentUserExpiresTimestamp) {
            users[msg.sender].subscriptionExpires = timeNow + 30 days;
        } else {
            users[msg.sender].subscriptionExpires = currentUserExpiresTimestamp + 30 days;
        }
        emit Renewal(msg.sender, users[msg.sender].subscriptionExpires, users[msg.sender].ref);
    }

    function withdrawAll(uint _amount) public onlyAdmin {
        require(_amount <= address(this).balance, "Insufficient funds");
        owner.transfer(_amount);
    }
}