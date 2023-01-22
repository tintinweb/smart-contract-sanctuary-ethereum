// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./chainlink/ConfirmedOwner.sol";
import "./chainlink/VRFV2WrapperConsumerBase.sol";

// Modified from https://docs.chain.link/samples/VRF/VRFv2DirectFundingConsumer.sol
// LINK Faucet: https://faucets.chain.link

contract ChoresDraw is VRFV2WrapperConsumerBase, ConfirmedOwner {
  event RequestSent(uint256 requestId, uint32 numChores);
  event RequestFulfilled(
    uint256 requestId,
    uint256[] randomWords,
    uint256 payment
  );

  struct RequestStatus {
    uint256 paid; // Amount paid in LINK
    bool fulfilled; // Whether the request has been successfully fulfilled
    uint256[] randomWords;
  }
  mapping(uint256 => RequestStatus) public requests; // Request id => Request status

  uint256[] public requestIds;
  uint256 public lastRequestId;

  // VRF consumer request params
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  // Hard-coded addresses for Goerli
  // LINK
  address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
  // VRF wrapper
  address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816;

  struct Chore {
    string label;
  }
  uint32 numChores = 0;
  mapping(uint32 => Chore) public chores; // Chore id => Chore

  struct Member {
    string name;
    address addr;
    mapping(uint32 => bool) chores; // Chore id => Participation in chore
    bool active; // Exempt from all chore duties if true, false otherwise
  }
  uint32 numMembers = 0;
  mapping(uint32 => Member) public members; // Member id => Member

  struct Draw {
    mapping(uint32 => Member) members;
    uint256[] randomWords;
    uint256 timestamp;
  }
  Draw[] public draws;

  modifier choreExists(uint32 _id) {
    require(_id < numChores, "Chore does not exist");
    _;
  }

  modifier memberExists(uint32 _id) {
    require(_id < numMembers, "Member does not exist");
    _;
  }

  modifier onlyOwnerOrMember(uint32 _memberId) {
    require(
      msg.sender == owner() || msg.sender == members[_memberId].addr,
      "Not owner or member"
    );
    _;
  }

  constructor()
    ConfirmedOwner(msg.sender)
    VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
  {}

  function requestDraw() external onlyOwner returns (uint256 requestId) {
    requestId = requestRandomness(
      callbackGasLimit,
      requestConfirmations,
      numChores
    );
    requests[requestId] = RequestStatus({
      paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
      randomWords: new uint256[](0),
      fulfilled: false
    });
    requestIds.push(requestId);
    lastRequestId = requestId;
    emit RequestSent(requestId, numChores);
    return requestId;
  }

  function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords)
    internal
    override
  {
    require(requests[_requestId].paid > 0, "Request not found");
    requests[_requestId].fulfilled = true;
    requests[_requestId].randomWords = _randomWords;
    emit RequestFulfilled(_requestId, _randomWords, requests[_requestId].paid);

    Draw storage draw = draws[draws.length];
    for (uint32 i = 0; i < numMembers; i++) {
      Member storage member = draw.members[i];
      member = members[i];
    }
    draw.randomWords = _randomWords;
    draw.timestamp = block.timestamp;
  }

  function getRequestStatus(uint256 _requestId)
    external
    view
    returns (
      uint256 paid,
      bool fulfilled,
      uint256[] memory randomWords
    )
  {
    require(requests[_requestId].paid > 0, "request not found");
    RequestStatus memory request = requests[_requestId];
    return (request.paid, request.fulfilled, request.randomWords);
  }

  function withdrawLink() public onlyOwner {
    LinkTokenInterface link = LinkTokenInterface(linkAddress);
    require(
      link.transfer(msg.sender, link.balanceOf(address(this))),
      "Unable to transfer"
    );
  }

  function addChore(string memory _label, bool enlistAll)
    external
    onlyOwner
    returns (uint32 choreId)
  {
    choreId = numChores;
    chores[choreId] = Chore({label: _label});
    numChores += 1;

    if (enlistAll) enlistAllForChore(choreId);
    return choreId;
  }

  function removeChore(uint32 _choreId)
    external
    choreExists(_choreId)
    onlyOwner
  {
    delete chores[_choreId];
    numChores--;
    delistAllForChore(_choreId);

    // If removed chore was not last chore (chore with highest id)
    if (_choreId != numChores) {
      // Copy last chore to fill gap
      chores[_choreId] = chores[numChores];
      // Delete last chore
      delete chores[numChores];
      // Since the last chore was "moved", it has a new id
      // Member chores data needs updated
      for (uint32 i = 0; i < numMembers; i++) {
        members[i].chores[_choreId] = members[i].chores[numChores];
        members[i].chores[numChores] = false;
      }
    }
  }

  function enlistAllForChore(uint32 _choreId)
    public
    choreExists(_choreId)
    onlyOwner
  {
    for (uint32 i = 0; i < numMembers; i++) {
      enlistMemberForChore(_choreId, i);
    }
  }

  function delistAllForChore(uint32 _choreId)
    public
    choreExists(_choreId)
    onlyOwner
  {
    for (uint32 i = 0; i < numMembers; i++) {
      delistMemberForChore(_choreId, i);
    }
  }

  function enlistMemberForChore(uint32 _choreId, uint32 _memberId)
    public
    choreExists(_choreId)
    memberExists(_memberId)
    onlyOwner
  {
    members[_memberId].chores[_choreId] = true;
  }

  function delistMemberForChore(uint32 _choreId, uint32 _memberId)
    public
    choreExists(_choreId)
    memberExists(_memberId)
    onlyOwner
  {
    members[_memberId].chores[_choreId] = false;
  }

  function addMember(string memory _name)
    external
    onlyOwner
    returns (uint32 memberId)
  {
    return addMember(_name, address(0), true);
  }

  function addMember(string memory _name, address _addr)
    external
    onlyOwner
    returns (uint32 memberId)
  {
    return addMember(_name, _addr, true);
  }

  function addMember(string memory _name, bool _enlistAll)
    external
    onlyOwner
    returns (uint32 memberId)
  {
    return addMember(_name, address(0), _enlistAll);
  }

  function addMember(
    string memory _name,
    address _addr,
    bool _enlistAll
  ) public onlyOwner returns (uint32 memberId) {
    // Check for existing member with same name
    for (uint32 i = 0; i < numMembers; i++) {
      require(
        keccak256(bytes(members[i].name)) != keccak256(bytes(_name)),
        "Duplicate member name"
      );
    }

    memberId = numMembers;
    Member storage newMember = members[memberId];
    newMember.name = _name;
    newMember.addr = _addr;
    newMember.active = true;
    numMembers++;

    if (_enlistAll) {
      for (uint32 i = 0; i < numChores; i++) {
        newMember.chores[i] = true;
      }
    }
    return memberId;
  }

  function removeMember(uint32 _memberId)
    external
    memberExists(_memberId)
    onlyOwner
  {
    delete members[_memberId];
    numMembers--;

    // If removed member was not last member (member with highest id)
    if (_memberId != numMembers) {
      // Copy last member to fill gap
      Member storage gap = members[_memberId];
      gap = members[numMembers];
      // Delete last member
      delete members[numMembers];
    }
  }

  function updateMemberAddress(uint32 _memberId, address _addr)
    external
    memberExists(_memberId)
    onlyOwnerOrMember(_memberId)
  {
    members[_memberId].addr = _addr;
  }

  function updateMemberName(uint32 _memberId, string memory _name)
    external
    memberExists(_memberId)
    onlyOwner
  {
    members[_memberId].name = _name;
  }

  function updateMemberActiveStatus(uint32 _memberId, bool _status) private {
    members[_memberId].active = _status;
  }

  function activateMember(uint32 _memberId)
    external
    memberExists(_memberId)
    onlyOwnerOrMember(_memberId)
  {
    updateMemberActiveStatus(_memberId, true);
  }

  function deactivateMember(uint32 _memberId)
    external
    memberExists(_memberId)
    onlyOwnerOrMember(_memberId)
  {
    updateMemberActiveStatus(_memberId, false);
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