pragma solidity ^0.5.0;


import "./ERC20.sol";

contract Shop {
    address private owner;
    IERC20 private token;
    mapping(string => Subscription) private subscriptions;

    struct Subscription {
        address owner;
        uint timestamp;
        uint tokens;
    }

    constructor(address _owner, address _token) public {
        owner = _owner;
        token = IERC20(_token);
    }

    event SubscriptionPaid(string _subscriptionId, uint _timestampFrom, address _ownerAddress, uint _tokens);

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner can exec this function!");
        _;
    }

    modifier isValidSubscription(string memory _subscriptionId){
        require(bytes(_subscriptionId).length > 0, "incorrect subscription id!");
        require(bytes(_subscriptionId).length < 10, "incorrect subscription id!");
        require(subscriptions[_subscriptionId].owner == address(0), "subscription already exists!");
        _;
    }

    modifier enoughTokensOnBalance(uint _tokens){
        require(_tokens > 0, "you must pay for subscription!");
        require(token.balanceOf(msg.sender) >= _tokens, "insufficient funds!");
        _;
    }

    modifier enoughAllowance(uint _tokens){
        require(_tokens > 0, "you must pay for subscription!");
        require(token.allowance(msg.sender, address(this)) >= _tokens, "insufficient allowance!");
        _;
    }

    function withdrawAll(address _to) public onlyOwner  returns (bool){
        return token.transfer(_to, token.balanceOf(address(this)));
    }

    function createSubscription(string memory _subscriptionId, uint _tokens) public isValidSubscription(_subscriptionId) enoughTokensOnBalance(_tokens) enoughAllowance(_tokens) {
        bool success = token.transferFrom(msg.sender, address(this), _tokens);
        require(success, "tokens transfer failed!");

        subscriptions[_subscriptionId] = Subscription(
            msg.sender, block.timestamp, _tokens
        );

        emit SubscriptionPaid(_subscriptionId, block.timestamp, msg.sender, _tokens);
    }

    function getSubscriptionOwnerAddress(string memory _subscriptionId) public view returns (address){
        return subscriptions[_subscriptionId].owner;
    }

    function getSubscriptionDateFrom(string memory _subscriptionId) public view returns (uint){
        return subscriptions[_subscriptionId].timestamp;
    }

    function getSubscriptionTokensPaid(string memory _subscriptionId) public view returns (uint){
        return subscriptions[_subscriptionId].tokens;
    }
}