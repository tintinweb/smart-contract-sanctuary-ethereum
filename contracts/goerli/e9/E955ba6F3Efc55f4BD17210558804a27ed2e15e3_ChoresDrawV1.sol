// SPDX-License-Identifier: MIT
/// @author: github.com/cliffoo
pragma solidity ^0.8.0;


import "./chainlink/ConfirmedOwner.sol";
import "./chainlink/VRFV2WrapperConsumerBase.sol";

// Based on: https://docs.chain.link/samples/VRF/VRFv2DirectFundingConsumer.sol
// LINK Faucet: https://faucets.chain.link

contract ChoresDrawV1 is VRFV2WrapperConsumerBase, ConfirmedOwner {
  /**
  ----------------------------------------
  Events
  ----------------------------------------
   */

  event RequestSent(uint256 requestId, uint32 numChores);
  event RequestFulfilled(uint256 requestId, uint256 drawIndex);

  /**
  ----------------------------------------
  Modifiers
  ----------------------------------------
   */

  modifier requestExists(uint256 _id) {
    require(requests[_id].linkPaid > 0, "Request not found");
    _;
  }
  modifier choreExists(uint256 _id) {
    require(_id < numChores, "Chore not found");
    _;
  }
  modifier memberExists(uint256 _id) {
    require(_id < numMembers, "Member not found");
    _;
  }
  modifier drawExists(uint256 _id) {
    require(_id < draws.length, "Draw not found");
    _;
  }
  modifier nonEmptyValue(string memory _value) {
    require((bytes(_value)).length > 0, "Empty value");
    _;
  }
  modifier memberNameDoesNotExist(string memory _value) {
    for (uint256 i = 0; i < numMembers; i++) {
      require(
        keccak256(abi.encodePacked(_value)) !=
          keccak256(abi.encodePacked(members[i].name)),
        "Name already exists"
      );
    }
    _;
  }
  modifier onlyOwnerOrMemberOwner(uint256 _memberId) {
    bool isOwner = msg.sender == owner();
    bool isMemberOwner = msg.sender == members[_memberId].owner;
    require(isOwner || isMemberOwner, "Not owner or member owner");
    _;
  }

  /**
  ----------------------------------------
  Structs and state variables
  ----------------------------------------
   */

  // VRF request
  struct Request {
    uint256 linkPaid;
    bool fulfilled;
    uint256 drawIndex;
  }
  uint256[] public requestIds;
  uint256 public lastRequestId;
  mapping(uint256 => Request) public requests; // Request id => Request status

  // VRF request params
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  // Hard-coded addresses for Goerli
  // - LINK
  address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
  // - VRF wrapper
  address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

  // Chore
  struct Chore {
    string label;
  }
  uint32 public numChores = 0;
  mapping(uint256 => Chore) public chores; // Chore id => Chore

  // Member
  struct Member {
    string name;
    address owner;
    mapping(uint256 => bool) chores; // Chore id => Participation in chore
  }
  uint256 public numMembers = 0;
  mapping(uint256 => Member) public members; // Member id => Member

  // Draw
  struct Draw {
    uint256 timestamp;
    uint256[] randomNumbers;
    uint256 numChores;
    uint256 numMembers;
    mapping(uint256 => Chore) chores;
    mapping(uint256 => Member) members;
  }
  uint256 public numDraws = 0;
  Draw[] public draws;

  // Draw interpretation
  // A given Draw can produce an array of n DrawInterpretation,
  // where n is the number of chores in Draw.
  struct DrawInterpretation {
    uint256 timestamp;
    uint256 randomNumber;
    string choreLabel;
    string selectedMember;
    string[] enlistedMembers;
    string[] delistedMembers;
  }

  /**
  ----------------------------------------
   */

  constructor()
    ConfirmedOwner(msg.sender)
    VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
  {}

  /**
  ----------------------------------------
  VRF and LINK functions
  ----------------------------------------
   */

  function withdrawLink() external onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(
      link.transfer(msg.sender, link.balanceOf(address(this))),
      "Unable to transfer"
    );
  }

  function requestDraw() external onlyOwner returns (uint256 requestId) {
    requestId = requestRandomness(
      callbackGasLimit,
      requestConfirmations,
      numChores
    );
    requests[requestId] = Request({
      linkPaid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
      fulfilled: false,
      drawIndex: 2**256 - 1
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numChores);
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
    internal
    override
    requestExists(_requestId)
  {
    // Update requests
    uint256 drawIndex = draws.length;
    requests[_requestId].fulfilled = true;
    requests[_requestId].drawIndex = drawIndex;

    // Update draws
    Draw storage draw = draws[drawIndex];
    // Copy members to draw
    for (uint256 i = 0; i < numMembers; i++) {
      draw.members[i].name = members[i].name;
      draw.members[i].owner = members[i].owner;
      for (uint256 j = 0; j < numChores; j++) {
        draw.members[i].chores[j] = members[i].chores[j];
      }
    }
    // Copy chores to draw
    for (uint256 i = 0; i < numChores; i++) {
      draw.chores[i].label = chores[i].label;
    }
    draw.numMembers = numMembers;
    draw.numChores = numChores;
    draw.randomNumbers = _randomWords;
    draw.timestamp = block.timestamp;

    numDraws++;
    emit RequestFulfilled(_requestId, drawIndex);
  }

  /**
  ----------------------------------------
  Interpretation function
  ----------------------------------------
   */

  function interpretDraw(uint256 _drawIndex)
    external
    view
    drawExists(_drawIndex)
    returns (DrawInterpretation[] memory interpretations)
  {
    // Unpack some draw data
    uint256[] memory drawRandomNumbers = draws[_drawIndex].randomNumbers;
    uint256 drawNumChores = draws[_drawIndex].numChores;
    uint256 drawNumMembers = draws[_drawIndex].numMembers;

    // For each chore
    for (uint256 i = 0; i < drawNumChores; i++) {
      DrawInterpretation memory interpretation = interpretations[i];
      uint256 choreRandomNumber = drawRandomNumbers[i];
      string[] memory enlistedMembers;
      string[] memory delistedMembers;
      uint256 enlistedCounter = 0;
      uint256 delistedCounter = 0;

      // For each member
      for (uint256 j = 0; j < drawNumMembers; j++) {
        string memory memberName = draws[_drawIndex].members[j].name;
        if (draws[_drawIndex].members[j].chores[i]) {
          enlistedMembers[enlistedCounter] = memberName;
          enlistedCounter++;
        } else {
          delistedMembers[delistedCounter] = memberName;
          delistedCounter++;
        }
      }

      interpretation.timestamp = draws[_drawIndex].timestamp;
      interpretation.randomNumber = choreRandomNumber;
      interpretation.choreLabel = draws[_drawIndex].chores[i].label;
      interpretation.selectedMember = enlistedMembers[
        choreRandomNumber % enlistedCounter
      ];
      interpretation.enlistedMembers = enlistedMembers;
      interpretation.delistedMembers = delistedMembers;
    }

    return interpretations;
  }

  /**
  ----------------------------------------
  Chore functions
  ----------------------------------------
   */

  function addChore(string memory _label)
    external
    onlyOwner
    returns (uint256 choreId)
  {
    choreId = numChores;
    chores[choreId] = Chore({label: _label});
    numChores++;
    return choreId;
  }

  function removeChore(uint256 _choreId)
    external
    choreExists(_choreId)
    onlyOwner
  {
    uint256 lastChoreId = numChores - 1;
    if (_choreId != lastChoreId) _copyLastChoreTo(_choreId);

    delete chores[lastChoreId];
    numChores--;

    for (uint256 i = 0; i < numMembers; i++) {
      members[i].chores[_choreId] = members[i].chores[lastChoreId];
      delete members[i].chores[lastChoreId];
    }
  }

  function _copyLastChoreTo(uint256 _choreId) private {
    Chore storage lastChore = chores[numChores - 1];
    Chore storage choreAtId = chores[_choreId];
    choreAtId.label = lastChore.label;
  }

  /**
  ----------------------------------------
  Member functions
  ----------------------------------------
   */
  function addMember(string memory _name) external returns (uint256 memberId) {
    return addMember(_name, address(0));
  }

  function addMember(string memory _name, address _memberOwner)
    public
    nonEmptyValue(_name)
    memberNameDoesNotExist(_name)
    onlyOwner
    returns (uint256 memberId)
  {
    memberId = numMembers;
    Member storage member = members[memberId];
    member.name = _name;
    member.owner = _memberOwner;
    numMembers++;
    return memberId;
  }

  function removeMember(uint256 _memberId)
    external
    memberExists(_memberId)
    onlyOwner
  {
    uint256 lastMemberId = numMembers - 1;
    if (_memberId != lastMemberId) _copyLastMemberTo(_memberId);

    delete members[lastMemberId];
    numMembers--;
  }

  function _copyLastMemberTo(uint256 _memberId) private {
    Member storage lastMember = members[numMembers - 1];
    Member storage memberAtId = members[_memberId];
    memberAtId.name = lastMember.name;
    memberAtId.owner = lastMember.owner;
    for (uint256 i = 0; i < numChores; i++) {
      memberAtId.chores[i] = lastMember.chores[i];
    }
  }

  function updateMemberOwner(uint256 _memberId, address _memberOwner)
    external
    memberExists(_memberId)
    onlyOwnerOrMemberOwner(_memberId)
  {
    members[_memberId].owner = _memberOwner;
  }

  function updateMemberName(uint256 _memberId, string memory _name)
    external
    memberExists(_memberId)
    onlyOwner
  {
    members[_memberId].name = _name;
  }

  /**
  ----------------------------------------
  Chore and member functions
  ----------------------------------------
   */

  function enlistMemberForChore(uint256 _memberId, uint256 _choreId)
    public
    choreExists(_choreId)
    memberExists(_memberId)
    onlyOwnerOrMemberOwner(_memberId)
  {
    members[_memberId].chores[_choreId] = true;
  }

  function delistMemberForChore(uint256 _memberId, uint256 _choreId)
    public
    choreExists(_choreId)
    memberExists(_memberId)
    onlyOwnerOrMemberOwner(_memberId)
  {
    members[_memberId].chores[_choreId] = false;
  }

  function enlistMemberForAllChores(uint256 _memberId)
    external
    memberExists(_memberId)
    onlyOwnerOrMemberOwner(_memberId)
  {
    for (uint256 i = 0; i < numChores; i++) enlistMemberForChore(_memberId, i);
  }

  function delistMemberForAllChores(uint256 _memberId)
    external
    memberExists(_memberId)
    onlyOwnerOrMemberOwner(_memberId)
  {
    for (uint256 i = 0; i < numChores; i++) delistMemberForChore(_memberId, i);
  }

  function enlistAllMembersForChore(uint256 _choreId)
    external
    choreExists(_choreId)
    onlyOwner
  {
    for (uint256 i = 0; i < numMembers; i++) enlistMemberForChore(i, _choreId);
  }

  function delistAllMembersForChore(uint256 _choreId)
    external
    choreExists(_choreId)
    onlyOwner
  {
    for (uint256 i = 0; i < numMembers; i++) delistMemberForChore(i, _choreId);
  }
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
  function calculateRequestPrice(uint32 _callbackGasLimit)
    external
    view
    returns (uint256);

  /**
   * @notice Estimates the price of a VRF request with a specific gas limit and gas price.
   *
   * @dev This is a convenience function that can be called in simulation to better understand
   * @dev pricing.
   *
   * @param _callbackGasLimit is the gas limit used to estimate the price.
   * @param _requestGasPriceWei is the gas price in wei used for the estimation.
   */
  function estimateRequestPrice(
    uint32 _callbackGasLimit,
    uint256 _requestGasPriceWei
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LinkTokenInterface.sol";
import "./VRFV2WrapperInterface.sol";

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
  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
    internal
    virtual;

  function rawFulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  ) external {
    require(
      msg.sender == address(VRF_V2_WRAPPER),
      "only VRF V2 wrapper can fulfill"
    );
    fulfillRandomWords(_requestId, _randomWords);
  }
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

interface LinkTokenInterface {
  function allowance(address owner, address spender)
    external
    view
    returns (uint256 remaining);

  function approve(address spender, uint256 value)
    external
    returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue)
    external
    returns (bool success);

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

import "./OwnableInterface.sol";

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

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner)
    ConfirmedOwnerWithProposal(newOwner, address(0))
  {}
}