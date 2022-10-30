/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

contract IERC20 {
  function approve(address spender, uint256 value) public virtual returns (bool) {}
  function transfer(address to, uint256 value) public virtual returns (bool) {}
  function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {}
  function name() public view virtual returns (string memory) {}
  function symbol() public view virtual returns (string memory) {}
  function decimals() public view virtual returns (uint256) {}
  function totalSupply() public view virtual returns (uint256) {}
  function balanceOf(address account) public view virtual returns (uint256) {}
  function allowance(address owner, address spender) public view virtual returns (uint256) {}
}

contract ERC948 {

  event NewSubscription(
    address Customer,
    address Payee,
    uint256 Allowance,
    address TokenAddress,
    string Name,
    string Description,
    uint256 LastExecutionDate,
    uint256 SubscriptionPeriod
  );
  event SubscriptionCancelled(
    address Customer,
    address Payee
  );
  event SubscriptionPaid(
    address Customer,
    address Payee,
    uint256 PaymentDate,
    uint256 PaymentAmount,
    uint256 NextPaymentDate
  );

  mapping(address => mapping(address => Subscription)) public subscriptions;


  mapping(address => SubscriptionReceipt[]) public receipts;

  struct Subscription {
    address Customer;
    address Payee;
    uint256 Allowance;
    address TokenAddress;
    string Name;
    string Description;
    uint256 LastExecutionDate;
    uint256 SubscriptionPeriod;
    bool IsActive;
    bool Exists;
  }

  enum role {
    CUSTOMER,
    PAYEE
  }

  struct SubscriptionReceipt {
    address Customer;
    address Payee;
    uint256 Allowance;
    address TokenAddress;
    string Name;
    string Description;
    uint256 CreationDate;
    role Role;
  }



  constructor() {
  }


  function getSubscription(address _customer, address _payee) public view returns(Subscription memory){
    return subscriptions[_customer][_payee];
  }

  function getSubscriptionReceipts(address _customer) public view returns(SubscriptionReceipt[] memory){
    return receipts[_customer];
  }

  function subscriptionTimeRemaining(address _customer, address _payee) public view returns(uint256){
    uint256 remaining = getSubscription(_customer, _payee).LastExecutionDate+getSubscription(_customer, _payee).SubscriptionPeriod;
    if(block.timestamp > remaining){
      return 0;
    }
    else {
      return remaining - block.timestamp;
    }
  }

  function createSubscription(
    address _payee,
    uint256 _subscriptionCost, 
    address _token, 
    string memory _name, 
    string memory _description, 
    uint256 _subscriptionPeriod ) public virtual {
    IERC20 tokenInterface;
    tokenInterface = IERC20(_token);

    require(getSubscription(msg.sender, _payee).IsActive != true, "0xSUB: Active subscription already exists.");
    require(_subscriptionCost <= tokenInterface.balanceOf(msg.sender), "0xSUB: Insufficient token balance.");
    require(_subscriptionPeriod > 0, "0xSUB: Subscription period must be greater than 0.");

    subscriptions[msg.sender][_payee] = Subscription(
      msg.sender,
      _payee,
      _subscriptionCost,
      _token,
      _name,
      _description,
      block.timestamp,
      _subscriptionPeriod,
      true,
      true
    );
    receipts[msg.sender].push(SubscriptionReceipt(
      msg.sender,
      _payee,
      _subscriptionCost,
      _token,
      _name,
      _description,
      block.timestamp,
      role.CUSTOMER
    ));
    receipts[_payee].push(SubscriptionReceipt(
      msg.sender,
      _payee,
      _subscriptionCost,
      _token,
      _name,
      _description,
      block.timestamp,
      role.PAYEE
    ));
    require((tokenInterface.allowance(msg.sender, address(this)) >= (_subscriptionCost * 2)) && (tokenInterface.allowance(msg.sender, address(this)) <= 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), "0xSUB: Allowance of (_subscriptionCost * 2) required.");
    require(tokenInterface.transferFrom(msg.sender, _payee, _subscriptionCost), "0xSUB: Initial subscription payment failed.");


    emit NewSubscription(msg.sender, _payee, _subscriptionCost, _token, _name, _description, block.timestamp, _subscriptionPeriod);
    emit SubscriptionPaid(msg.sender, _payee, block.timestamp, _subscriptionCost, block.timestamp+_subscriptionPeriod);
  }
  
  function cancelSubscription(
    address _customer,
    address _payee ) public virtual {
    require((getSubscription(_customer, _payee).Customer == msg.sender || getSubscription(_customer, _payee).Payee == msg.sender), "0xSUB: Only subscription parties can cancel a subscription.");
    require(getSubscription(_customer, _payee).IsActive == true, "0xSUB: Subscription already inactive.");

    subscriptions[_customer][_payee].IsActive = false;

    emit SubscriptionCancelled(_customer, _payee);
  }

  function executePayment(
    address _customer
  ) public virtual {
    require(getSubscription(_customer, msg.sender).Payee == msg.sender, "0xSUB: Only subscription payees may execute a subscription payment.");
    require(getSubscription(_customer, msg.sender).IsActive == true, "0xSUB: Subscription already inactive.");
    require(_subscriptionPaid(_customer, msg.sender) != true, "0xSUB: Subscription already paid for this period.");

    IERC20 tokenInterface;
    tokenInterface = IERC20(getSubscription(_customer, msg.sender).TokenAddress);

    subscriptions[_customer][msg.sender].LastExecutionDate = block.timestamp;
    require(tokenInterface.transferFrom(_customer, msg.sender, getSubscription(_customer, msg.sender).Allowance), "0xSUB: Subscription payment failed.");


    emit SubscriptionPaid(_customer, msg.sender, block.timestamp, getSubscription(_customer, msg.sender).Allowance, block.timestamp+getSubscription(_customer, msg.sender).SubscriptionPeriod);
  }


   function _subscriptionPaid(address _customer, address _payee) internal view returns(bool){
    uint256 remaining = getSubscription(_customer, _payee).LastExecutionDate+getSubscription(_customer, _payee).SubscriptionPeriod;
    if(block.timestamp > remaining){
      return false;
    }
    else {
      return true;
    }
  }

}