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
import "./UpkeepCreator.sol";

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


contract Campaign is KeeperCompatibleInterface{
  using SafeMath for uint256;

  // enums
  enum State {
    Fundraising,
    Expired
  }


  // state variables
  address payable public creator;
  string public title;
  string public description;
  string public category;
  string[] public tags;
  uint256 public goalAmount;
  uint256 public duration;
  string public campaignURI;
  uint256 public currentBalance;
  uint256 private s_lastTimeStamp;
  uint256 private maxTimeStamp;
  State public state = State.Fundraising; // default state
  mapping (address => uint256) public donations;
  bool public nowPayable;
  bool public nowRefundable;
  bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("createUpkeep(address,string,uint32)"));
  uint public minFund;
  address private registryAddress;
  address private linkTokenAddress;



  struct CampaignObject {
    address creator;
    string title;
    string description;
    string category;
    string[] tags;
    uint256 goalAmount;
    uint256 duration;
    uint256 currentBalance;
    State currentState;
    bool nowRefundable;
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
  modifier isCreator() {
    if(msg.sender != creator){revert Campaign__NotCreator(msg.sender);}
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
    string memory _campaignURI,
    address _registryAddress,
    address _linkTokenAddress
  ) {
    creator = payable(_creator);
    title = _title;
    description = _description;
    category = _category;
    tags = _tags;
    goalAmount = _goalAmount;
    s_lastTimeStamp = block.timestamp;
    maxTimeStamp = s_lastTimeStamp + 2592000; // 30days
    if(_duration > (maxTimeStamp.sub(s_lastTimeStamp))){
      duration = maxTimeStamp.sub(s_lastTimeStamp);
    }else{
      duration = _duration;
    }
    campaignURI = _campaignURI;
    currentBalance = 0;
    nowPayable = false;
    nowRefundable = true;
    registryAddress = _registryAddress;
    linkTokenAddress = _linkTokenAddress;
  }

  function timeBox() public {
    minFund = 8000000000000000000;
    uint32 minGas = 500000;
    bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, address(this), title, minGas);

    UpkeepCreator newUpkeepCreator = new UpkeepCreator(registryAddress, linkTokenAddress);
    ILinkToken ERC677Linker = ILinkToken(linkTokenAddress);
    if(ERC677Linker.balanceOf(creator) <= 0){revert Campaign__UpkeepNotNeeded();}
    ERC677Linker.approve(address(this), minFund);
    // ERC677Linker.transferFrom(creator, address(this), minFund);
    ERC677Linker.transferAndCall(address(newUpkeepCreator), minFund, data);
  }

  function donate() external payable {
    if(state != State.Fundraising){revert Campaign__AlreadyExpired(address(this));}
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
    bool isOpen = state == State.Fundraising;
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > duration);
    bool hasBalance = address(this).balance > 0;
    upkeepNeeded = (timePassed && isOpen && hasBalance) ;
    return (upkeepNeeded, "0x0");
  }

  function performUpkeep(bytes calldata /**performData */) external override {
    (bool upkeepNeeded, ) = checkUpkeep("");
    if(!upkeepNeeded){revert Campaign__UpkeepNotNeeded();}

    // allow creator withdraw funds
    nowPayable = true;
    nowRefundable = false;
    state = State.Expired;
    emit CampaignExpired(address(this));
    if(currentBalance >= goalAmount){
      emit CampaignSuccessful(address(this));
    }
  }

  function payout() public isCreator {
    if(!nowPayable){revert Campaign__NotWithrawable(address(this));}
    uint256 totalRaised = currentBalance;
    currentBalance = 0;
    (bool success, ) = creator.call{value: totalRaised}("");
    if(success){
      nowRefundable = false;
      emit CreatorPaid(creator, address(this));
    }
    else{revert Campaign__PayoutFailed();}
  }

  function refund(address _donator) public {
    if(state == State.Expired){revert Campaign__AlreadyExpired(address(this));}
    if(donations[_donator] <= 0){revert Campaign__NoDonationsHere(_donator);}
    uint256 amountToRefund = donations[_donator];
    donations[_donator] = 0;
    if(currentBalance < amountToRefund){revert Campaign__CampaignBankrupt(address(this));}
    currentBalance = currentBalance.sub(amountToRefund);
    (bool success, ) = payable(_donator).call{value: amountToRefund}("");
    if(!success){revert Campaign__RefundFailed();} // TODO: test if it returns value (the money) to mapping
  }

  function endCampaign() public isCreator {
    if(state == State.Expired){revert Campaign__AlreadyExpired(address(this));}
    state = State.Expired;
    nowRefundable = false;
    if(currentBalance > 0){nowPayable = true;}
    emit CampaignExpired(address(this));
  }

  // update functions
  // function updateTitle(string memory _newTitle) public isCreator {
  //   title = _newTitle;
  // }

  // function updateDescription(string memory _newDescription) public isCreator {
  //   description = _newDescription;
  // }

  // function updateCategory(string memory _newCategory) public isCreator {
  //   category = _newCategory;
  // }

  // function updateGoalAmount(uint256 _newGoalAmount) public isCreator {
  //   goalAmount = _newGoalAmount;
  // }

  // function updateDuration(uint256 _additionalTime) public isCreator {
  //   if(_additionalTime + duration > (maxTimeStamp.sub(s_lastTimeStamp))){
  //     duration = maxTimeStamp.sub(s_lastTimeStamp); // 30days
  //   }
  //   else{
  //     duration += _additionalTime;
  //   }
  // }

  function updateCampaignURI(string memory _campaignURI) public isCreator {
    campaignURI = _campaignURI;
  }
  
  // getter functions
  function getCreator() public view returns(address) {
    return creator;
  }

  function getBalance() public view returns(uint256) {
    return currentBalance;
  }

  function getNowRefundable() public view returns(bool) {
    return nowRefundable;
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
      title,
      description,
      category,
      tags,
      goalAmount,
      duration,
      currentBalance,
      state,
      nowRefundable
    );
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface ILinkToken {
  function transferAndCall(address receiver, uint amount, bytes calldata data) external returns (bool success);
  function balanceOf(address user) external view returns(uint);
  function approve(address spender, uint amount) external;
  function transfer(address _to, uint _amount) external;
  function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

interface KeepersRegistry {
  function getRegistrar() external view returns(address);
}

contract UpkeepCreator {

  address public REGISTRY_ADDRESS; //goerli testnet 
  address public ERC677_LINK_ADDRESS;

  constructor(address _registryAddress, address _linkTokenAddress){
    REGISTRY_ADDRESS = _registryAddress;
    ERC677_LINK_ADDRESS = _linkTokenAddress;
  }
  /*
  register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source
  )
  */
  bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("register(string,bytes,address,uint32,address,bytes,uint96,uint8)"));
  uint public minFundingAmount = 5000000000000000000; //5 LINK
  uint8 public SOURCE = 110;

  ILinkToken ERC677Link = ILinkToken(ERC677_LINK_ADDRESS);

  //Note: make sure to fund this contract with LINK before calling createUpkeep
  function createUpkeep(address contractAddressToAutomate, string memory upkeepName, uint32 gasLimit) external {
    address registarAddress = KeepersRegistry(REGISTRY_ADDRESS).getRegistrar();
    uint96 amount = uint96(minFundingAmount);
    bytes memory data = abi.encodeWithSelector(FUNC_SELECTOR, upkeepName, hex"", contractAddressToAutomate, gasLimit, msg.sender, hex"", amount, SOURCE);
    ERC677Link.transferAndCall(registarAddress, minFundingAmount, data);
  }
}