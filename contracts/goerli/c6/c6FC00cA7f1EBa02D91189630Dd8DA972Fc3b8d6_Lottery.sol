// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
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
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFV2WrapperInterface {
  /**
   * @return the request ID of the most recent VRF V2 request made by this wrapper. This should only
   * be relied option within the same transaction that the request was made.
   */
  function lastRequestId() external view returns (uint256);

  /**
   * @notice Calculates the price of a VRF request with the given callbackGasLimit at the current
   * @notice block.
   *
   * @dev This function relies on the transaction gas price which is not automatically set during
   * @dev simulation. To estimate the price at a specific gas price, use the estimatePrice function.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   */
  function calculateRequestPrice(uint32 _callbackGasLimit) external view returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(uint32 _callbackGasLimit, uint256 _requestGasPriceWei) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/VRFV2WrapperInterface.sol";

/** *******************************************************************************
 * @notice Interface for contracts using VRF randomness through the VRF V2 wrapper
 * ********************************************************************************
 * @dev PURPOSE
 *
 * @dev Create VRF V2 requests without the need for subscription management. Rather than creating
 * @dev and funding a VRF V2 subscription, a user can use this wrapper to create one off requests,
 * @dev paying up front rather than at fulfillment.
 *
 * @dev Since the price is determined using the gas price of the request transaction rather than
 * @dev the fulfillment transaction, the wrapper charges an additional premium on callback gas
 * @dev usage, in addition to some extra overhead costs associated with the VRFV2Wrapper contract.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFV2WrapperConsumerBase. The consumer must be funded
 * @dev with enough LINK to make the request, otherwise requests will revert. To request randomness,
 * @dev call the 'requestRandomness' function with the desired VRF parameters. This function handles
 * @dev paying for the request based on the current pricing.
 *
 * @dev Consumers must implement the fullfillRandomWords function, which will be called during
 * @dev fulfillment with the randomness result.
 */
abstract contract VRFV2WrapperConsumerBase {
  LinkTokenInterface internal immutable LINK;
  VRFV2WrapperInterface internal immutable VRF_V2_WRAPPER;

  /**
   * @param _link is the address of LinkToken
   * @param _vrfV2Wrapper is the address of the VRFV2Wrapper contract
   */
  constructor(address _link, address _vrfV2Wrapper) {
    LINK = LinkTokenInterface(_link);
    VRF_V2_WRAPPER = VRFV2WrapperInterface(_vrfV2Wrapper);
  }

  /**
   * @dev Requests randomness from the VRF V2 wrapper.
   *
   * @param _callbackGasLimit is the gas limit that should be used when calling the consumer's
   *        fulfillRandomWords function.
   * @param _requestConfirmations is the number of confirmations to wait before fulfilling the
   *        request. A higher number of confirmations increases security by reducing the likelihood
   *        that a chain re-org changes a published randomness outcome.
   * @param _numWords is the number of random words to request.
   *
   * @return requestId is the VRF V2 request ID of the newly created randomness request.
   */
  function requestRandomness(
    uint32 _callbackGasLimit,
    uint16 _requestConfirmations,
    uint32 _numWords
  ) internal returns (uint256 requestId) {
    LINK.transferAndCall(
      address(VRF_V2_WRAPPER),
      VRF_V2_WRAPPER.calculateRequestPrice(_callbackGasLimit),
      abi.encode(_callbackGasLimit, _requestConfirmations, _numWords)
    );
    return VRF_V2_WRAPPER.lastRequestId();
  }

  /**
   * @notice fulfillRandomWords handles the VRF V2 wrapper response. The consuming contract must
   * @notice implement it.
   *
   * @param _requestId is the VRF V2 request ID.
   * @param _randomWords is the randomness result.
   */
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual;

  function rawFulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) external {
    require(msg.sender == address(VRF_V2_WRAPPER), "only VRF V2 wrapper can fulfill");
    fulfillRandomWords(_requestId, _randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
//enter lottery
//pick a random winner at an interval-automated
//use chainlink to get randomnesss

//errors
error Lottery__NotEnoughEthEntered();
error Lottery__TransferFailed();
error Lottery__NotOpen();
error Lottery__UpkeepNotNeeded(uint256 currentBalance, uint256 playerCount, uint256 lotteryState);
//THE CONTRACT

/**
 * @title A lottery contract
 * @author Martin Ndung'u
 * @notice This contract is for creating a decentralized lottery smart contract
 * @dev it utilizes the chainlink keepers and also chainlink get randomness.
 */
contract Lottery is VRFV2WrapperConsumerBase, AutomationCompatible {

    /* type declaration */
       enum lotteryState{
        OPEN, CALCULATING
    }

    uint32 internal callbackGasLimit=100000;
    uint32 internal numWords=2;
    uint16 public requestConfirmations =3;
    address linkAddress=0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address wrapperAddress=	0x708701a1DfF4f478de54383E49a627eD4852C816;

    // state variables
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    //lottery variables
    address private s_recentWinner;
    lotteryState private s_lotteryState;
    uint256 private s_lastTimestamp;
    uint256 private s_currentTimestamp;
    uint256 private immutable i_interval;
        //events
    event LotteryEntered(address indexed player);
    event FulfilledRequest(uint random, uint256 requestId);
    event WinnerPicked(address winner);
    event RequestFulfilled(
        uint256 requestId,
        uint256[] randomWords,
        uint256 payment);
    event RequestSent(
        uint256 requestId,
         uint32 numWords);
   

    struct RequestStatus{
        uint256 paid;
        bool fulfilled;
        uint256[] randomWords;
    }
    mapping(uint256 => RequestStatus)
    public s_requests;

    uint256 [] public requestIds;
    uint256 public lastRequestId;
    //functions

    //constructor
    constructor(uint256 entranceFee, uint256 interval) VRFV2WrapperConsumerBase(linkAddress, wrapperAddress){
        s_lastTimestamp=block.timestamp;
        i_interval=interval;
        s_lotteryState= lotteryState.OPEN;
        i_entranceFee = entranceFee;
    }

    function enterLottery() public payable {
        if(s_lotteryState != lotteryState.OPEN){
            revert Lottery__NotOpen();
        }
        if (msg.value < i_entranceFee) revert Lottery__NotEnoughEthEntered();
        s_players.push(payable(msg.sender)); //cast in payable because the s_players array is a payable array
        emit LotteryEntered(msg.sender);
    }
    //get random number
    function requestRandomWords() external returns(uint256 requestId){
      requestId= requestRandomness(
        callbackGasLimit,
        requestConfirmations,
        numWords
      );
      s_requests[requestId]=RequestStatus({
        paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
        randomWords: new uint256[](0),
        fulfilled: false
      });
      requestIds.push(requestId);
      lastRequestId=requestId;
      emit RequestSent(requestId, numWords);
      return requestId;
    }
    /**
     * @dev This the function that the chainlink keeper automation nodes call.
     * check upkeep returns a boolean which triggers the perform upkeep
     */
    //check upkeep
    function checkUpkeep(bytes memory /*checkData*/) public view override returns(bool upkeepNeeded, bytes memory /*performData*/){
        bool isOpen= lotteryState.OPEN == s_lotteryState;
        bool timePassed =((block.timestamp - s_lastTimestamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance= (address(this).balance > 0);
        upkeepNeeded=(timePassed && isOpen && hasBalance && hasPlayers);
    }

    //perform upKeep
  
    function performUpkeep(
         bytes calldata /*perfomData*/) 
         external override {
        (bool upKeepNeeded,)=checkUpkeep("");
        if(!upKeepNeeded){
            revert Lottery__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_lotteryState));
        } 

        s_lotteryState=lotteryState.CALCULATING;
        
    }
    function fulfillRandomWords(
        uint256 requestId, 
        uint256[] memory randomWords) 
    internal 
    override{
        require(s_requests[requestId].paid > 0, "request not found");
        s_requests[requestId].fulfilled=true;
        s_requests[requestId].randomWords= randomWords;

        emit RequestFulfilled(
            requestId,
            randomWords,
            s_requests[requestId].paid);

        uint256 indexOfWinner = randomWords[0] % s_players.length; 
        address payable recentWinner=s_players[indexOfWinner];
        s_recentWinner=recentWinner;
        (bool success,)=recentWinner.call{value: address(this).balance}("");
        if(!success) revert Lottery__TransferFailed();
        emit WinnerPicked(recentWinner);
        s_players= new address payable[](0);
        s_lotteryState=lotteryState.OPEN;
        s_lastTimestamp=block.timestamp;
    }
    //withdraw link
    function withdrawLink() public {
        LinkTokenInterface link= LinkTokenInterface(linkAddress);
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),"unable to transfer"
        );
    }

    //getters view/pure functions
    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }
    function getPlayers(uint256 index) public view returns(address){
        return s_players[index];
    }
    function getRecentWinner()public view returns(address){
        return s_recentWinner;
    }
    function getLotteryState() public view returns(lotteryState){
        return s_lotteryState;
    }
    // function getNumberOfWords() public view returns(RequestStatus){
    //     return RequestStatus.randomWords.length;
    // }
    function getPlayerCount() public view returns(uint256){
        return s_players.length;
    }
    function getLastTimestamp() public view returns (uint256){
        return s_lastTimestamp;
    }
    function getInterval()public view returns(uint256){
        return i_interval;
    }
}