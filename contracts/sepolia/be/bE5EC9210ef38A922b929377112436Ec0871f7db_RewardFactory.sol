// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Reward } from "../Reward.sol";

contract RewardFactory {
  struct rwdInput {
    uint256 _price;
    string  _title; 
    string  _description; 
    string  _rpic;
    string[]  _perks; 
    uint256 _deadline; 
    uint256 _quantity; 
    bool _infinite; 
    string[]  _shipsTo;
  }

  function createReward(address _cmpAddress, address _creator, rwdInput memory _rwd) public returns (address) {
    Reward rwd = new Reward(
      _cmpAddress, 
      _creator,
      _rwd._price,
      _rwd._title,
      _rwd._description,
      _rwd._rpic,
      _rwd._perks,
      _rwd._deadline,
      _rwd._quantity,
      _rwd._infinite,
      _rwd._shipsTo 
    );

    return address(rwd);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Reward {
  address public immutable i_campaignAddress;
  // address public immutable i_crf;
  address public immutable i_creator;

  uint256 public immutable i_price;
  string public title;
  string public description;
  string public rpic;
  string[] public perks;
  uint256 public delDate;
  uint256 public quantity;
  bool public infinite = true;
  string[] public shipsTo;
  address[] public donators;
  string public surveyLink;

  struct RewardObject {
    uint256 price;
    string title;
    string description;
    string rpic;
    string[] perks;
    uint256 delDate;
    uint256 quantity;
    bool infinite;
    string[] shipsTo;
    address[] donators;
    string surveyLink;
  }

  mapping (address => uint256) public true_donator;  
  mapping (address => string) public surveyResponses;

  constructor ( 
    address _campaignAddress, 
    address _creator,
    uint256 _price, 
    string memory _title, 
    string memory _description, 
    string memory _rpic,
    string[] memory _perks, 
    uint256 _deadline, 
    uint256 _quantity, 
    bool _infinite, 
    string[] memory _shipsTo
    ) {
    i_price = _price;
    i_campaignAddress = _campaignAddress;
    i_creator = _creator;

    title = _title;
    description = _description;
    rpic = _rpic;
    perks = _perks;
    delDate = _deadline;
    quantity = _quantity;
    infinite = _infinite;
    shipsTo = _shipsTo;
  }

  function updateSurveyLink(string memory _surveylink) external {
    if(msg.sender != i_creator){revert();}
    surveyLink = _surveylink;
  }

  function addDonator(address _donator) external {
    if(msg.sender != i_campaignAddress){revert();}
    if((true_donator[_donator] > 0)){revert();} // already has id ...has therefor donated for this reward before

    if(!infinite){
      if(quantity > 0){
        quantity = quantity - 1;
        uint256 currNo = donators.length; // get array length
        true_donator[_donator] = currNo + 1; 
        donators.push(_donator);
      }else{revert();} // rwd has finished no longer available
    }else{
      uint256 currNo = donators.length; // get array length
      true_donator[_donator] = currNo + 1; 
      donators.push(_donator);
    }
  }

  function getDonators() external view returns(address[] memory){
    return donators;
  }

  function removeDonator(address _donator) external {
    if(msg.sender != i_campaignAddress){revert();}
    if(!(true_donator[_donator] > 0)){revert();} // not a donator
    uint256 index = true_donator[_donator] - 1;
    delete donators[index];
    delete true_donator[_donator];
  }

  function respondToSurvey(string memory _response) external {
    if(!(true_donator[msg.sender] > 0)){revert();} // not a donator
    surveyResponses[msg.sender] = _response;
  }

  function getRewardDetails() external view returns(RewardObject memory){
    return RewardObject(
      i_price,
      title,
      description,
      rpic,
      perks,
      delDate,
      quantity,
      infinite,
      shipsTo,
      donators,
      surveyLink
    );
  }
}