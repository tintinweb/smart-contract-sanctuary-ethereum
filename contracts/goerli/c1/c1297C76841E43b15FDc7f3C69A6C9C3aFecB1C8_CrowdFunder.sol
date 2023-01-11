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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

// errors
error Campaign__NotInState();
error Campaign__NotCreator(address _address);
error Campaign__DonatorIsCreator(address _address);
error Campaign__PayoutFailed();
error Campaign__NoDonationsHere(address _donatorAddress);
error Campaign__RefundFailed();
error Campaign__UpkeepNotNeeded();
error Campaign__NotWithrawable(address _campaignAddress);
error Campaign__AlreadyExpired(address _campaignAddress);
error Campaign__NotRefundable(address _campaignAddress);
error Campaign__CampaignBankrupt(address _campaignAddress);


contract Campaign is KeeperCompatibleInterface {
  using SafeMath for uint256;

  // enums
  enum State {
    Successful,
    Fundraising,
    Expired
  }

  enum CreatorType {
    Sole,
    Team
  }


  // state variables
  address payable public creator;
  CreatorType public creatorType;
  string public creatorName;
  string public title;
  string public description;
  string[] public tags;
  uint256 public goalAmount;
  uint256 public duration;
  uint256 public currentBalance;
  uint256 private s_lastTimeStamp;
  State public state = State.Fundraising; // default state
  mapping (address => uint256) public donations;
  bool public nowPayable;
  bool public nowRefunding;


  struct CampaignObject {
    address creator;
    CreatorType creatorType;
    string creatorName;
    string title;
    string description;
    string[] tags;
    uint256 goalAmount;
    uint256 duration;
    uint256 currentBalance;
    State currentState;
  }


  // events
  event FundingRecieved (
    address indexed contributor,
    uint256 amount,
    uint256 currentBalance
  );
  event CreatorPaid(address creator, address campaignAddress);
  event CampaignSuccessful(address campaignAddress);
  event CampaignExpired(address campaignAddress);


  // modifiers
  modifier inState(State _state) {
    if (state != _state){revert Campaign__NotInState();}
    _;
  }

  modifier isCreator() {
    if(msg.sender != creator){revert Campaign__NotCreator(msg.sender);}
    _;
  }

  constructor (
    address _creator,
    uint64 _creatorType,
    string memory _creatorName,
    string memory _title,
    string memory _description,
    string[] memory _tags,
    uint256 _goalAmount,
    uint256 _duration
  ) {
    creator = payable(_creator);
    creatorType = CreatorType(_creatorType);
    creatorName = _creatorName;
    title = _title;
    description = _description;
    tags = _tags;
    goalAmount = _goalAmount;
    duration = _duration;
    s_lastTimeStamp = block.timestamp;
    currentBalance = 0;
    nowPayable = false;
    nowRefunding = false;
  }

  function donate() external inState(State.Fundraising) payable {
    if (msg.sender == creator){revert Campaign__DonatorIsCreator(msg.sender);}
    donations[msg.sender] = donations[msg.sender].add(msg.value);
    currentBalance = currentBalance.add(msg.value);
    emit FundingRecieved(msg.sender, msg.value, currentBalance);
  }

  /**
    @dev this is the function chainlink keepers calls
    chekupkeep returns true to trigger the action after the interval has passed
   */
  function checkUpkeep(bytes memory /**checkData */) public view override
  returns (bool upkeepNeeded, bytes memory /**performData */) 
  {
    bool goalReached = currentBalance >= goalAmount;
    bool isOpen = state == State.Fundraising;
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > duration);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (goalReached || timePassed && isOpen && hasBalance) ;
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /**performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){revert Campaign__UpkeepNotNeeded();}

    // allow creator withdraw funds
    nowPayable = true;
    nowRefunding = true;

    if((block.timestamp - s_lastTimeStamp) > duration){
      state = State.Expired; 
      emit CampaignExpired(address(this));
    }
    else if(currentBalance >= goalAmount){
      state = State.Successful;
      emit CampaignSuccessful(address(this));
    }
  }

  function payout() public isCreator {
    if(!nowPayable){revert Campaign__NotWithrawable(address(this));}
    uint256 totalRaised = currentBalance;
    currentBalance = 0;
    (bool success, ) = creator.call{value: totalRaised}("");
    if(success){
      nowRefunding = false;
      emit CreatorPaid(creator, address(this));
    }
    else{revert Campaign__PayoutFailed();}
  }

  function refund(address _donator) public {
    if(!nowRefunding){revert Campaign__NotRefundable(address(this));}
    if(donations[_donator] <= 0){revert Campaign__NoDonationsHere(msg.sender);}
    uint256 amountToRefund = donations[_donator];
    donations[_donator] = 0;
    if(currentBalance < amountToRefund){revert Campaign__CampaignBankrupt(address(this));}
    currentBalance = currentBalance.sub(amountToRefund);
    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert Campaign__RefundFailed();} // TODO: test if it returns the money to mapping
  }

  function endCampaign() public isCreator {
    if(state == State.Expired){revert Campaign__AlreadyExpired(address(this));}
    state = State.Expired;
    if(currentBalance > 0){nowPayable = true;}
    emit CampaignExpired(address(this));
  }

  function allowRefunds() public isCreator {
    if(currentBalance <= 0){revert Campaign__CampaignBankrupt(address(this));}
    else{nowRefunding = true;}
  }

  // update functions
  function updateDuration(uint256 _addedTime) public isCreator {
    duration = duration.add(_addedTime);
  }

  function updateTitle(string memory _newTitle) public isCreator {
    title = _newTitle;
  }

  function updateDescription(string memory _newDescription) public isCreator {
    description = _newDescription;
  }
  
  // getter functions
  function getBalance() public view returns(uint256) {
    return currentBalance;
  }

  function getCampaignState() public view returns(State) {
    return state;
  }

  function getDonations(address _donator) public view returns(uint256) {
    return donations[_donator];
  }

  function getCampaignDetails() public view returns(CampaignObject memory) {
    return CampaignObject(
      creator,
      creatorType,
      creatorName,
      title,
      description,
      tags,
      goalAmount,
      duration,
      currentBalance,
      state
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
error CrowdFunder__NoSuchCampaign(address _campaignAddress);
error CrowdFunder__NotCreator(address _caller, address _campaignAddress);
error CrowdFunder__CampaignStillActive(address _campaignAddress);

contract CrowdFunder {
  using SafeMath for uint256;

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    uint256 _creatorType,
    string _creatorName,
    string _title,
    string _description,
    string[] _tags,
    uint256 _goalAmount,
    uint256 _duration
  );

  event CampaignCanceled(
    address indexed _campaignAddress
  );


  mapping (address => Campaign) campaigns;
  mapping (address => address) campaignCreators;
  mapping (address => bool) campaignAddresses;

  modifier isCreator(address _campaignAddress) {
    if(msg.sender != campaignCreators[_campaignAddress]){
      revert CrowdFunder__NotCreator(msg.sender, _campaignAddress);
    }
    _;
  }

  function addCampaign (
    uint64 _creatorType,
    string memory _creatorName,
    string memory _title, 
    string memory _description,
    string[] memory _tags, 
    uint256 _goalAmount,
    uint256 _duration
    ) external {
    // uint256 raiseUntil = block.timestamp.add(duration.mul(1 days));
    Campaign newCampaign = new Campaign(payable(msg.sender), _creatorType, _creatorName, _title, _description, _tags, _goalAmount, _duration);
    campaigns[address(newCampaign)] = newCampaign;
    campaignAddresses[address(newCampaign)] = true;
    campaignCreators[address(newCampaign)] = msg.sender;
    emit CampaignAdded(address(newCampaign), msg.sender, _creatorType, _creatorName, _title, _description, _tags, _goalAmount, _duration);
  }

  function cancelCampaign (address _campaignAddress) public isCreator(_campaignAddress) {
    if(uint(campaigns[_campaignAddress].getCampaignState()) == 1){revert CrowdFunder__CampaignStillActive(_campaignAddress);}
    delete(campaigns[_campaignAddress]);
    delete(campaignAddresses[_campaignAddress]);
    // emit CampaignCanceled(_campaignAddress, campaigns[_campaignAddress].creator(), campaigns[_campaignAddress].goalAmount());
    emit CampaignCanceled(_campaignAddress);
  }

  function getCampaign(address _campaignAddress) external view returns (Campaign.CampaignObject memory) {
    if(!campaignAddresses[_campaignAddress]){revert CrowdFunder__NoSuchCampaign(_campaignAddress);}
    return campaigns[_campaignAddress].getCampaignDetails();
  }
}