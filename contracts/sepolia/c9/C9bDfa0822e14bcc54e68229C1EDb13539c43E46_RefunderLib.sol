// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Campaign } from "../../Campaign.sol";
import { Reward } from "../../Reward.sol";

library RefunderLib {
  function refund (
    address _i_crf,
    Campaign.refunder_pckg storage _refP, 
    mapping (uint256 => address) storage _rewards, 
    mapping (address => uint256) storage _aggrDons, 
    mapping (address => uint256[]) storage _entDons, 
    address _donator
    ) external {
    if(msg.sender != _i_crf){revert();}
    if(_refP.c_state == Campaign.C_State.Expired){revert();}
    if(_aggrDons[_donator] == 0 ){revert();}

    uint256 amountToRefund = _aggrDons[_donator];

    if(_refP.currentBalance < amountToRefund){revert();}
    _refP.currentBalance = _refP.currentBalance - amountToRefund;

    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert();}

    delete _aggrDons[_donator];

    if(_entDons[_donator].length > 0){    
      for(uint i=0; i<_entDons[_donator].length; i++){
        if(!(_rewards[_entDons[_donator][i]] != address(0))){
          Reward(_rewards[_entDons[_donator][i]]).removeDonator(_donator);
        }
      }
    }

    delete _entDons[_donator];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import { Reward } from "./Reward.sol";
import { RewardFactory } from "./factories/RewardFactory.sol";
import { RefunderLib } from "./libraries/campaign/RefunderLib.sol";

// errors
// error Cmp_NIS(); /**not in state */
// error Cmp_NotCrtr();
// error Cmp_DIC(); /**donator is creator */
// error Cmp_NoDns();
// error Cmp_RefF();
// error Cmp_UpkNN();
// error Cmp_NotRef();
// error Cmp_Bankrupt();

contract Campaign is KeeperCompatibleInterface, ReentrancyGuard{

  // enums
  enum C_State {
    Fundraising,
    Expired,
    Canceled
  }

  // c_state variables
  address immutable public i_crf;
  address payable immutable public i_creator;
  address immutable public i_rwdFactory;
  string public s_title;
  string public s_description;
  string public s_category;
  string public s_imageURI;
  string public s_campaignURI;
  string public s_tags;
  uint256 public goalAmount;
  uint256 public duration;
  uint256 public currentBalance;
  uint256 private immutable i_initTimeStamp;
  uint256 private constant i_maxDur = 5184000;
  uint256 public deadline;
  uint256 private rId;
  C_State public c_state = C_State.Fundraising; // default c_state

  struct CampaignObject {
    address i_creator;
    string s_title;
    string s_description;
    string s_category;
    string s_tags;
    uint256 goalAmount;
    uint256 duration;
    uint256 currentBalance;
    C_State currentC_State;
    string s_imageURI;
    string s_campaignURI;
    uint256 deadline;
  }

  struct refunder_pckg {
    uint256 currentBalance;
    C_State c_state;
  }

  // mapping (uint256 => reward) public rewards;
  mapping (uint256 => address) public rewards;
  mapping (address => uint256[]) public entDonations;
  mapping (address => uint256) public aggrDonations;

  uint256[] public rKeys;

  // events
  event FundingRecieved (
    address indexed contributor,
    uint256 amount,
    uint256 currentBalance
  );
  event CreatorPaid(address creator, address campaignAddress);
  event CampaignExpired(address campaignAddress);
  event CampaignCanceled();

  // modifiers
  modifier isCreator() {
    if(msg.sender != i_creator){revert();}
    _;
  }

  refunder_pckg _refP;

  constructor (
    address _crowdfunder,
    address _creator,
    address _rwdFactory,
    string memory _title,
    string memory _description,
    string memory _category,
    string memory _tags,
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI
  ) {
    i_rwdFactory = _rwdFactory;
    i_crf = _crowdfunder;
    i_creator = payable(_creator);
    s_title = _title;
    s_description = _description;
    s_category = _category;
    s_tags = _tags;
    goalAmount = _goalAmount;
    i_initTimeStamp = block.timestamp;
    duration = _duration > i_maxDur ? i_maxDur : _duration;
    deadline = i_initTimeStamp + duration;
    s_imageURI = _imageURI;
    currentBalance = 0;
  }


  function donate(address _donator, bool _rewardable) public payable nonReentrant{
    if(msg.sender != i_crf){revert();}
    if(c_state != C_State.Fundraising){revert();}
    if(_donator == i_creator){revert();}
    currentBalance = currentBalance + msg.value;
    if(_rewardable){
      if(rewards[msg.value] != address(0)){
        (bool success, ) = rewards[msg.value].call(abi.encodeWithSignature("addDonator(address)", _donator));
        if(!success){revert();}
        entDonations[_donator].push(msg.value);
      }else{revert();}
    }
    aggrDonations[_donator] = aggrDonations[_donator] + msg.value; 
    emit FundingRecieved(_donator, msg.value, currentBalance);
  }

  /**
    @dev this is the function chainlink keepers calls
    chekupkeep returns true to trigger the action after the interval has passed
   */
  function checkUpkeep(bytes memory /**checkData */) public view override
  returns (bool upkeepNeeded, bytes memory /**performData */) 
  {
    bool isOpen = c_state == C_State.Fundraising;
    bool timePassed = ((block.timestamp - i_initTimeStamp) > duration);
    upkeepNeeded = (timePassed && isOpen);
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /**performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){revert();}
    c_state = C_State.Expired;
    emit CampaignExpired(address(this));
  }

  function payout() external isCreator{
    if(c_state != C_State.Expired){revert();}
    uint256 totalRaised = currentBalance;
    currentBalance = 0;
    (bool success, ) = i_creator.call{value: totalRaised}("");
    if(success){
      emit CreatorPaid(i_creator, address(this));
    }
    else{revert();}
  }


  function refund(address _donator) external nonReentrant{
    _refP = refunder_pckg(currentBalance, c_state);
    RefunderLib.refund(i_crf, _refP, rewards, aggrDonations, entDonations, _donator);
  }

  function makeReward(RewardFactory.rwdInput memory _rwd) external isCreator {
    if(rewards[_rwd._price] != address(0)){revert();}
    rKeys.push(_rwd._price);
    address newReward = RewardFactory(i_rwdFactory).createReward(address(this), i_creator, _rwd);
    rewards[_rwd._price] = newReward;
  }

  function endCampaign() external isCreator {
    if(c_state == C_State.Expired){revert();}
    c_state = C_State.Canceled;
    emit CampaignCanceled();
  }

  // update functions
  function updateCampaignURI(string memory _campaignURI) external isCreator {
    s_campaignURI = _campaignURI;
  }

  function updateDur(uint256 _addedDur) external isCreator {
    duration = (((duration + _addedDur)) > i_maxDur) ? i_maxDur : (duration + _addedDur);
    deadline = i_initTimeStamp + duration;
  }

  // getter functions
  function getRewardKeys() external view returns(uint256[] memory){
    return rKeys;
  }
  
  function getReward(uint256 _priceID) external view returns(Reward.RewardObject memory) {
    Reward reward = Reward(rewards[_priceID]);
    return reward.getRewardDetails();
  }

  function getCampaignDetails() external view returns(CampaignObject memory) {
    return CampaignObject(
      i_creator,
      s_title, 
      s_description,
      s_category,
      s_tags,
      goalAmount,
      duration,
      currentBalance,
      c_state,
      s_imageURI,
      s_campaignURI,
      deadline
    );
  }
}

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