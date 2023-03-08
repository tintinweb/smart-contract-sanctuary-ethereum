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
pragma solidity ^0.8.0;

/**
 * @notice config of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member blockCountPerTurn number of blocks each oracle has during their turn to
 * perform upkeep before it will be the next keeper's turn to submit
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct Config {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint24 blockCountPerTurn;
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member numUpkeeps total number of upkeeps on the registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint256 numUpkeeps;
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData
  ) external returns (uint256 id);

  function performUpkeep(uint256 id, bytes calldata performData) external returns (bool success);

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(uint256 id)
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getKeeperInfo(address query)
    external
    view
    returns (
      address payee,
      bool active,
      uint96 balance
    );

  function getState()
    external
    view
    returns (
      State memory,
      Config memory,
      address[] memory
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    view
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      int256 gasWei,
      int256 linkEth
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(uint256 upkeepId, address from)
    external
    returns (
      bytes memory performData,
      uint256 maxLinkPayment,
      uint256 gasLimit,
      uint256 adjustedGasWei,
      uint256 linkEth
    );
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

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
import "./UpkeepIDConsumer.sol";

// errors
error Campaign__NotInC_State();
error Campaign__NotCreator(address _address);
error Campaign__DonatorIsCreator(address _address);
error Campaign__PayoutFailed();
error Campaign__NoDonationsHere(address _donatorAddress);
error Campaign__RefundFailed();
error Campaign__UpkeepNotNeeded();
error Campaign__AlreadyExpired(address _campaignAddress);
error Campaign__NotRefundable(address _campaignAddress);
error Campaign__CampaignBankrupt(address _campaignAddress);


contract Campaign is KeeperCompatibleInterface{
  using SafeMath for uint256;

  // enums
  enum C_State {
    Fundraising,
    Expired,
    Canceled
  }

  // c_state variables
  address payable immutable public i_creator;
  string public s_title;
  string public s_description;
  string public s_category;
  string public s_imageURI;
  string public s_campaignURI;
  string[] public s_tags;
  uint256 public goalAmount;
  uint256 public duration;
  uint256 public currentBalance;
  uint256 private immutable i_lastTimeStamp;
  uint256 private immutable i_maxTimeStamp;
  uint256 public deadline;
  C_State public c_state = C_State.Fundraising; // default c_state
  address private immutable i_linkTokenAddress;
  address private immutable i_upkeepCreatorAddress;
  uint256 private rId;

  struct CampaignObject {
    address i_creator;
    string s_title;
    string s_description;
    string s_category;
    string[] s_tags;
    uint256 goalAmount;
    uint256 duration;
    uint256 currentBalance;
    C_State currentC_State;
    string s_imageURI;
    string s_campaignURI;
    uint256 deadline;
  }

  struct phyReward {
    uint256 price;
    string title;
    string description;
    string[] perks;
    uint256 delDate;
    uint256 quantity;
    string[] shipsTo;
  }

  struct digReward {
    uint256 price;
    string title;
    string description;
    string[] perks;
    uint256 delDate;
    uint256 quantity;
    bool infinite;
  }

  mapping (uint256 => phyReward) public phyRewards;
  mapping (uint256 => digReward) public digRewards;
  mapping (address => uint256[]) public donations;


  // events
  event FundingRecieved (
    address indexed contributor,
    uint256 amount,
    uint256 currentBalance
  );
  event CreatorPaid(address creator, address campaignAddress);
  event CampaignSuccessful(address campaignAddress);
  event CampaignExpired(address campaignAddress);
  event CampaignCanceled();


  // modifiers
  modifier isCreator() {
    if(msg.sender != i_creator){revert Campaign__NotCreator(msg.sender);}
    _;
  }


  constructor (
    address _creator,
    string memory _title,
    string memory _description,
    string memory _category,
    string[] memory _tags,
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI,
    string memory _campaignURI,
    address _linkTokenAddress,
    address _upkeepCreatorAddress
  ) {
    i_creator = payable(_creator);
    s_title = _title;
    s_description = _description;
    s_category = _category;
    s_tags = _tags;
    goalAmount = _goalAmount;
    i_lastTimeStamp = block.timestamp;
    i_maxTimeStamp = i_lastTimeStamp + 5184000; // 60days
    if(_duration > (i_maxTimeStamp.sub(i_lastTimeStamp))){
      duration = i_maxTimeStamp.sub(i_lastTimeStamp);
    }else{
      duration = _duration;
    }
    deadline = i_lastTimeStamp + duration;
    s_imageURI = _imageURI;
    s_campaignURI = _campaignURI;
    currentBalance = 0;
    i_linkTokenAddress = _linkTokenAddress;
    i_upkeepCreatorAddress = _upkeepCreatorAddress;
  }

  function timeBox() public isCreator {
    UpkeepIDConsumer newUpkeepCreator = UpkeepIDConsumer(i_upkeepCreatorAddress);
    LinkTokenInterface token = LinkTokenInterface(i_linkTokenAddress);
    if(token.balanceOf(i_upkeepCreatorAddress) <= 0){revert("no funds");}
    rId = newUpkeepCreator.registerAndPredictID(s_title, "0x", address(this), 500000, i_creator, "0x", 10000000000000000000, 0);
  }

  function donate() external payable {
    if(c_state != C_State.Fundraising){revert Campaign__NotInC_State();}
    if (msg.sender == i_creator){revert Campaign__DonatorIsCreator(msg.sender);}
    donations[msg.sender].push(msg.value);
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
    bool isOpen = c_state == C_State.Fundraising;
    bool timePassed = ((block.timestamp - i_lastTimeStamp) > duration);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (timePassed && isOpen && hasBalance) ;
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /**performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){revert Campaign__UpkeepNotNeeded();}
    c_state = C_State.Expired;
    emit CampaignExpired(address(this));
    if(currentBalance >= goalAmount){
      emit CampaignSuccessful(address(this));
    }
  }

  function payout() public isCreator {
    if(c_state != C_State.Expired){revert Campaign__NotInC_State();}
    uint256 totalRaised = currentBalance;
    currentBalance = 0;
    (bool success, ) = i_creator.call{value: totalRaised}("");
    if(success){
      emit CreatorPaid(i_creator, address(this));
    }
    else{revert Campaign__PayoutFailed();}
  }

  function refund(address _donator) public {
    if(c_state == C_State.Expired){revert Campaign__AlreadyExpired(address(this));}
    if(donations[_donator].length == 0 ){revert Campaign__NoDonationsHere(_donator);}
    uint256 amountToRefund = calcFunderDonations(donations[_donator]);
    delete(donations[_donator]);
    if(currentBalance < amountToRefund){revert Campaign__CampaignBankrupt(address(this));}
    currentBalance = currentBalance.sub(amountToRefund);
    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert Campaign__RefundFailed();}
  }

  function calcFunderDonations(uint256[] memory _funderArr) private pure returns(uint256 result){
    for (uint256 i = 0; i < _funderArr.length; i++) {
      result += _funderArr[i];
    }
    return result;
  }

  function makeDigitalReward (
    uint256 _price, string memory _title, 
    string memory _description, 
    string[] memory _perks,
    uint256 _quantity,
    bool _infinite
    ) public isCreator {
    digRewards[_price] = digReward(_price, _title, _description, _perks, deadline, _quantity, _infinite);
  }

  function makePhysicalReward( 
    uint256 _price, string memory _title, 
    string memory _description, string[] memory _perks, 
    uint256 _deadline, uint256 _quantity, string[] memory _shipsTo
    ) public isCreator {
    phyRewards[_price] = phyReward(_price, _title, _description, _perks, _deadline, _quantity, _shipsTo);
  }

  function deleteReward(uint256 _priceID) public isCreator {
    if(phyRewards[_priceID].price > 0){delete(phyRewards[_priceID]);}
    if(digRewards[_priceID].price > 0){delete(digRewards[_priceID]);}
  }

  function endCampaign() public isCreator {
    if(c_state == C_State.Expired){revert Campaign__AlreadyExpired(address(this));}
    c_state = C_State.Canceled;
    emit CampaignCanceled();
  }

  // update functions
  function updateGoalAmount(uint256 _newGoalAmount) public isCreator {
    goalAmount = _newGoalAmount;
  }

  function updateDuration(uint256 _additionalTime) public isCreator {
    if((_additionalTime + duration) > (i_maxTimeStamp.sub(i_lastTimeStamp))){
      duration = i_maxTimeStamp.sub(i_lastTimeStamp); // 60days
    }
    else{
      duration += _additionalTime;
    }
  }

  function updateCampaignURI(string memory _campaignURI) public isCreator {
    s_campaignURI = _campaignURI;
  }

  // getter functions
  function getDonations(address _donator) public view returns(uint256[] memory) {
    return donations[_donator];
  }

  function getCampaignDetails() public view returns(CampaignObject memory) {
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
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Campaign.sol";

// errors
error CrowdFunder__NotCreator(address _caller, address _campaignAddress);
error CrowdFunder__CampaignStillActive(address _campaignAddress);
error CrowdFunder__DonationFailed(address _campaignAddress);
error CrowdFunder__RefundFailed(address _campaignAddress);
error CrowdFunder__CampaignNotRefundable(address _campaignAddress);

contract CrowdFunder {
  using SafeMath for uint256;

  event UserAdded(
    address indexed _address,
    string _username,
    string _twitter,
    string _email,
    string _location,
    string _bio
  );

  event CampaignAdded(
    address indexed _campaignAddress,
    address indexed _creator,
    string _category,
    string[] _tags
  );

  event CampaignFunded(
    address indexed _funder,
    address indexed _campaignAddress
  );

  event CampaignShrunk(
    address indexed _withdrawer,
    address indexed _campaignAddress
  );

  event CampaignRemoved(
    address indexed _campaignAddress
  );

  event UserHomeAddrAdded(
    address _userAddress,
    string _homeAddr
  );

  uint256 public campaignCounter;
  mapping (address => Campaign) private campaigns;


  modifier isCreator(address _campaignAddress) {
    if(campaigns[_campaignAddress].i_creator() != msg.sender){
      revert CrowdFunder__NotCreator(msg.sender, _campaignAddress);
    }
    _;
  }

  function addUser(
    address _address, string memory _username, 
    string memory _twitter, string memory _email, 
    string memory _location, string memory _bio
    ) public {
    emit UserAdded(_address, _username, _twitter, _email, _location, _bio);
  }

  function addCampaign (
    string memory _title, 
    string memory _description,
    string memory _category,
    string[] memory _tags, 
    uint256 _goalAmount,
    uint256 _duration,
    string memory _imageURI,
    string memory _campaignURI,
    address _linkTokenAddress,
    address _upkeepCreatorAddress
    ) external {
    Campaign newCampaign = new Campaign(
      payable(msg.sender), _title, 
      _description, _category, 
      _tags, _goalAmount, 
      _duration, _imageURI, _campaignURI, 
      _linkTokenAddress, _upkeepCreatorAddress
    );
    campaigns[address(newCampaign)] = newCampaign;
    campaignCounter+=1;
    emit CampaignAdded(address(newCampaign), msg.sender, _category, _tags);
  }

  function donateToCampaign (address _campaignAddress) public payable {
    (bool success, ) = _campaignAddress.delegatecall(abi.encodeWithSignature("donate()"));
    if(success){
      emit CampaignFunded(msg.sender, _campaignAddress);
    }else{
      revert CrowdFunder__DonationFailed(_campaignAddress);
    }
  }

  function refundFromCampaign(address _campaignAddress, address _donator) public {
    (bool success,) = _campaignAddress.delegatecall(abi.encodeWithSignature("refund(address)", _donator));
    if(success){
      emit CampaignShrunk(msg.sender, _campaignAddress);
    }else{
      revert CrowdFunder__RefundFailed(_campaignAddress);
    }
  }

  function removeCampaign (address _campaignAddress) public isCreator(_campaignAddress) {
    if(uint(campaigns[_campaignAddress].c_state()) == 0){revert CrowdFunder__CampaignStillActive(_campaignAddress);}
    delete(campaigns[_campaignAddress]);
    campaignCounter-=1;
    emit CampaignRemoved(_campaignAddress);
  }

  function addUserHomeAddr (address _userAddress, string memory _homeAddr) public {
    emit UserHomeAddrAdded(_userAddress, _homeAddr);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {AutomationRegistryInterface, State, Config} from "@chainlink/contracts/src/v0.8/interfaces/AutomationRegistryInterface1_2.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

interface KeeperRegistrarInterface {
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source,
    address sender
  ) external;
}

contract UpkeepIDConsumer {
  LinkTokenInterface public immutable i_link;
  address public immutable registrar;
  AutomationRegistryInterface public immutable i_registry;
  bytes4 registerSig = KeeperRegistrarInterface.register.selector;

  constructor(
    address _link,
    address _registrar,
    address _registry
  ) {
    i_link = LinkTokenInterface(_link);
    registrar = _registrar;
    i_registry = AutomationRegistryInterface(_registry);
  }

  function registerAndPredictID(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source
  ) public returns(uint){
    (State memory state, Config memory _c, address[] memory _k) = i_registry.getState();
    uint256 oldNonce = state.nonce;
    bytes memory payload = abi.encode(
      name,
      encryptedEmail,
      upkeepContract,
      gasLimit,
      adminAddress,
      checkData,
      amount,
      source,
      address(this)
    );

    i_link.transferAndCall(
      registrar,
      amount,
      bytes.concat(registerSig, payload)
    );
    (state, _c, _k) = i_registry.getState();
    uint256 newNonce = state.nonce;
    if (newNonce == oldNonce + 1) {
      uint256 upkeepID = uint256(
        keccak256(
          abi.encodePacked(
            blockhash(block.number - 1),
            address(i_registry),
            uint32(oldNonce)
          )
        )
      );
      // DEV - Use the upkeepID however you see fit
      return upkeepID;
    } else {
      revert("auto-approve disabled");
    }
  }
}