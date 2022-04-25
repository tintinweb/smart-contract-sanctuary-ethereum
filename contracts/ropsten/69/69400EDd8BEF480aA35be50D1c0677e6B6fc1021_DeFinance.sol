/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

contract DeFinance {

  enum CustomerType {
    ADMIN, SELLER, BUYER
  }
  struct User {
    address user;
    string name;
    string email;
    CustomerType role;
  }
  struct Subscription {
    uint256 productId;
    string productName;
    uint256 price;
    uint256 assuredAmnt;
    uint256 createdTime;
    address seller;
    address buyer;
    uint256 expiry;
    bool claimed;
    bool claimSettled;
  }

  address public admin;
  uint POINT_TWO_ETHER = 200000000000000000;
  mapping(address => User) public userInfos;
  mapping(address => Subscription[]) userSubscriptionsMap;
  mapping(address => Subscription[]) sellerClaims;

  constructor() {
      admin = msg.sender;
      userInfos[admin] = User(admin, "Vivek", "[email protected]", CustomerType.ADMIN);
  }

  modifier onlySellerOrBuyer() {
    require(!(msg.sender == admin), 'Either Seller or Buyer can register in the portal');
    _;
  }

  modifier onlySeller() {
    require(getUserInfo().role == CustomerType.SELLER, 'Only Seller can approve claim request');
    _;
  }

  function signup(string memory name, string memory email, CustomerType role) public onlySellerOrBuyer {
    userInfos[msg.sender] = User({user: msg.sender,
                                  name: name,
                                  email: email,
                                  role: role
                                  }
                                );
  }

  function getUserInfo() public view returns(User memory) {
    return userInfos[msg.sender];
  }

  function isAlreadySubscribed(uint256 productId) public view onlySellerOrBuyer returns (bool) {
    return isSubscribed(msg.sender, productId);
  }

  function isSellerSubscribed(address seller, uint256 productId) public view onlySellerOrBuyer returns (bool) {
    return isSubscribed(seller, productId);
  }

  function isSubscribed(address seller, uint256 productId) private view returns (bool) {
    Subscription[] memory subscriptions = userSubscriptionsMap[seller];
    for (uint i = 0; i < subscriptions.length; i++) {
      if(subscriptions[i].productId == productId) {
        return true;
      }
    }
    return false;
  }

  function isBuyerClaimed(uint productIdIndex) public view returns (bool){
    return userSubscriptionsMap[msg.sender][productIdIndex].claimed;
  }

  function subscribe(uint256 productId, string memory productName, uint256 price, uint256 assuredAmnt, address seller, uint256 expiry) public payable {

    require(!isAlreadySubscribed(productId), "User has already subscribed to this product");
    if(!(msg.sender == seller)){
        require(isSellerSubscribed(seller, productId), "Seller has already subscribed to this product");
    }
    require(msg.value >= price, 'Please pay minimum of 1 ether to subscribe');
    require(expiry > 0, 'Minimum of 1 should be required for the expiry field');
    Subscription memory newUserSubscription = Subscription( productId,
                                                            productName,
                                                            price,
                                                            assuredAmnt,
                                                            block.timestamp,
                                                            seller,
                                                            msg.sender,
                                                            block.timestamp + 2592000 * expiry, //30 days * expiry
                                                            false,
                                                            false
                                                        );

    
      payable(admin).transfer(POINT_TWO_ETHER);
      payable(seller).transfer(msg.value - POINT_TWO_ETHER);
    userSubscriptionsMap[msg.sender].push(newUserSubscription);
  }

  function claimRequest(uint productId) public {
    require(getUserInfo().role == CustomerType.BUYER, 'Only buyer can claim their request');
    require(isSubscribed(msg.sender, productId), 'Please buy a subscription before claiming');
    Subscription[] memory userSubscriptions = userSubscriptionsMap[msg.sender];
    for (uint256 i = 0; i < userSubscriptions.length; i++){
      if(userSubscriptions[i].productId == productId){
        require(!isBuyerClaimed(i), "User has already claimed against this product");
        userSubscriptionsMap[msg.sender][i].claimed = true;
        sellerClaims[userSubscriptions[i].seller].push(userSubscriptionsMap[msg.sender][i]);
      }
    }
  }

  function getClaimProductResult(uint productId) public view returns (bool) {
    Subscription[] memory userSubscriptions = userSubscriptionsMap[msg.sender];
    for (uint256 i = 0; i < userSubscriptions.length; i++){
      if(userSubscriptions[i].productId == productId && userSubscriptions[i].claimed){
        return true;
      }
    }
    return false;
  }

  function settleClaim(address owner, uint256 productId) public onlySeller payable {
    require(getUserInfo().role == CustomerType.SELLER, 'Only Seller can approve claim request');
    Subscription[] memory claimedSubscriptions = sellerClaims[msg.sender];
    for (uint256 i = 0; i < claimedSubscriptions.length; i++){
      if(claimedSubscriptions[i].productId == productId && claimedSubscriptions[i].buyer == owner){
        require(!sellerClaims[msg.sender][i].claimSettled, "The claim is already settled");
        require(msg.value >= sellerClaims[msg.sender][i].assuredAmnt, 'Assured Amount has not met');
        sellerClaims[msg.sender][i].claimSettled = true;
        Subscription[] memory userSubscriptions = userSubscriptionsMap[claimedSubscriptions[i].buyer];
        for (uint256 j = 0; j < userSubscriptions.length; j++){
          if(userSubscriptions[j].productId == productId){
            userSubscriptionsMap[claimedSubscriptions[i].buyer][j].claimSettled = true;
            payable(owner).transfer(msg.value);
          }
        }
      }
    }
  }

  function getSettledClaimStatus(address owner, uint256 productId) public view returns (bool){
    Subscription[] memory claimedSubscriptions = sellerClaims[msg.sender];
    for (uint256 i = 0; i < claimedSubscriptions.length; i++){
      if(claimedSubscriptions[i].productId == productId && claimedSubscriptions[i].buyer == owner){
        return sellerClaims[msg.sender][i].claimSettled;
      }
    }
    return false;
  }

  function rejectClaim(address owner, uint256 productId) public onlySeller {
    Subscription[] memory claimedSubscriptions = sellerClaims[msg.sender];
    for (uint256 i = 0; i < claimedSubscriptions.length; i++){
      if(claimedSubscriptions[i].productId == productId && claimedSubscriptions[i].buyer == owner){
        require(!sellerClaims[msg.sender][i].claimSettled, "The claim is already settled");
        delete sellerClaims[msg.sender][i];
      }
    }
  }

  function hasSellerClaims(address owner, uint256 productId) public view returns (bool){
    Subscription[] memory claimedSubscriptions = sellerClaims[msg.sender];
    for (uint256 i = 0; i < claimedSubscriptions.length; i++){
      if(claimedSubscriptions[i].productId == productId && claimedSubscriptions[i].buyer == owner){
        return true;
      }
    }
    return false;
  }
}