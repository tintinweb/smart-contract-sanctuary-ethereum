// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.0;

import "./ERC20.sol";

contract PaymentContract {
    address private _owner;
    IERC20 private _token;
    mapping(string => Subscription) private _subscriptions;

    struct Subscription {
        address owner;
        uint64 timestamp;
        uint192 tokens;
        address tokenAddress;
    }

    constructor(address owner, address token) public nonZeroAddress(owner) nonZeroAddress(token) {
        _owner = owner;
        _token = IERC20(token);
    }

    event SubscriptionPaid(string indexed subscriptionId, uint64 timestampFrom, address indexed ownerAddress, uint192 tokens, address tokenAddress);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TokenChanged(address indexed previousToken, address indexed newToken);

    event Withdraw(address indexed byOwner, address indexed toAddress, uint256 amount);

    modifier nonZeroAddress(address account) {
        require(account != address(0), "new owner can't be with the zero address");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == _owner, "only owner can exec this function");
        _;
    }

    modifier isValidSubscription(string memory subscriptionId){
        require(bytes(subscriptionId).length > 0, "incorrect subscription id");
        require(bytes(subscriptionId).length < 13, "incorrect subscription id");
        require(_subscriptions[subscriptionId].owner == address(0), "subscription already exists");
        _;
    }

    function changeToken(address newToken) external onlyOwner {
        require(newToken != address(_token), "already in use");
        require(newToken != address(0), "invalid address");

        address oldToken = address(_token);
        _token = IERC20(newToken);

        emit TokenChanged(oldToken, newToken);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner can't be the zero address");
        address oldOwner = _owner;
        _owner = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function withdrawAll(address to) public onlyOwner returns (bool){
        uint256 amount = _token.balanceOf(address(this));
        bool success = _token.transfer(to, amount);
        require(success, "withdraw transfer failed");

        emit Withdraw(_owner, to, amount);

        return success;
    }

    function createSubscription(string memory subscriptionId, uint192 tokens) public isValidSubscription(subscriptionId) {
        address tokenAddress = address(_token);

        _subscriptions[subscriptionId] = Subscription(
            msg.sender, uint64(block.timestamp), tokens, tokenAddress
        );

        bool success = _token.transferFrom(msg.sender, address(this), tokens);
        require(success, "tokens transfer failed");

        emit SubscriptionPaid(subscriptionId, uint64(block.timestamp), msg.sender, tokens, tokenAddress);
    }

    function getSubscription(string memory subscriptionId) public view returns (address, uint64, uint192, address){
        return (_subscriptions[subscriptionId].owner, _subscriptions[subscriptionId].timestamp, _subscriptions[subscriptionId].tokens, address(_token));
    }

    function owner() public view returns (address){
        return _owner;
    }

    function token() public view returns (address){
        return address(_token);
    }
}