// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

// This contract contains the logic for handling claims
// The idea is that the first level of handling a claim is the Sherlock Protocol Claims Committee (SPCC)(a multisig)
// If a protocol agent doesn't like that result, they can escalate the claim to UMA's Optimistic Oracle (OO), who will be the final decision
// We also build in a multisig (controlled by UMA) to give the final approve to pay out after the OO approves a claim

import './Manager.sol';
import '../interfaces/managers/ISherlockClaimManager.sol';
import '../interfaces/managers/ISherlockProtocolManager.sol';
import '../interfaces/UMAprotocol/SkinnyOptimisticOracleInterface.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/// @dev expects 6 decimals input tokens
contract SherlockClaimManager is ISherlockClaimManager, ReentrancyGuard, Manager {
  using SafeERC20 for IERC20;

  /// @dev at time of writing, the escalation cost will be 22.2k
  /// assuming BOND = 9600 and UMA's final fee = 1500
  /// UMA's final fee can be changed in the future, which may result in lower or higher required staked amounts for escalating a claim.
  /// The actual amount is 2 * (BOND + UMA's final fee), because:
  /// 1. The first half is charged when calling UMA.requestAndProposePriceFor()
  /// 2. The second half is charged when calling UMA.disputePriceFor()
  /// UMA's fee can be found here: https://github.com/UMAprotocol/protocol/blob/master/packages/core/contracts/oracle/implementation/Store.sol#L131)
  uint256 internal constant BOND = 9_600 * 10**6;

  // The amount of time the protocol agent has to escalate a claim
  uint256 public constant ESCALATE_TIME = 4 weeks;

  // The UMA Halt Operator (UMAHO) is the multisig (controlled by UMA) who gives final approval to pay out a claim
  // After the OO has voted to pay out
  // This variable represents the amount of time during which UMAHO can block a claim that was approved by the OO
  // After this time period, the claim (which was approved by the OO) is inferred to be approved by UMAHO as well
  uint256 public constant UMAHO_TIME = 24 hours;

  // The amount of time the Sherlock Protocol Claims Committee (SPCC) gets to decide on a claim
  // If no action is taken by SPCC during this time, then the protocol agent can escalate the decision to the UMA OO
  uint256 public constant SPCC_TIME = 7 days;

  // A pre-defined amount of time for the proposed price ($0) to be disputed within the OO
  // Note This value is not important as we immediately dispute the proposed price
  // 7200 represents 2 hours
  uint256 internal constant LIVENESS = 7200;

  // This is how UMA will know that Sherlock is requesting a decision from the OO
  // This is "SHERLOCK_CLAIM" in hex value
  bytes32 public constant override UMA_IDENTIFIER =
    bytes32(0x534845524c4f434b5f434c41494d000000000000000000000000000000000000);

  uint256 public constant MAX_CALLBACKS = 4;

  // The Optimistic Oracle contract that we interact with
  SkinnyOptimisticOracleInterface public constant UMA =
    SkinnyOptimisticOracleInterface(0xeE3Afe347D5C74317041E2618C49534dAf887c24);

  // USDC
  IERC20 public constant TOKEN = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  // The address of the multisig controlled by UMA that can emergency halt a claim that was approved by the OO
  address public override umaHaltOperator;
  // The address of the multisig controlled by Sherlock advisors who make the first judgment on a claim
  address public immutable override sherlockProtocolClaimsCommittee;

  // Takes a protocol's internal ID as a key and whether or not the protocol has a claim active as the value
  // Note Each protocol can only have one claim active at a time (this prevents spam)
  mapping(bytes32 => bool) public protocolClaimActive;

  // A protocol's public claim ID is simply incremented by 1 from the last claim ID made by any protocol (1, 2, 3, etc.)
  // A protocol's internal ID is the keccak256() of a protocol's ancillary data field
  // A protocol's ancillary data field will contain info like the hash of the protocol's coverage agreement (each will be unique)
  // The public ID (1, 2, 3, etc.) is easy to track while the internal ID is used for interacting with UMA
  mapping(uint256 => bytes32) internal publicToInternalID;

  // Opposite of the last field, allows us to move between a protocol's public ID and internal ID
  mapping(bytes32 => uint256) internal internalToPublicID;

  // Protocol's internal ID is the key, active claim is the value
  // Claim object is initialized in startClaim() below
  // See ISherlockClaimManager.sol for Claim struct
  mapping(bytes32 => Claim) internal claims_;

  // The last claim ID we used for a claim (ID is incremented by 1 each time)
  uint256 internal lastClaimID;

  // A request object used in the UMA OO
  SkinnyOptimisticOracleInterface.Request private umaRequest;

  // An array of contracts that implement the callback provided in this contract
  ISherlockClaimManagerCallbackReceiver[] public claimCallbacks;

  // Used for callbacks on UMA functions
  // This modifier is used for a function being called by the OO contract, requires this contract as caller
  // Requires the OO contract to pass in the Sherlock identifier
  modifier onlyUMA(bytes32 identifier) {
    if (identifier != UMA_IDENTIFIER) revert InvalidArgument();
    if (msg.sender != address(UMA)) revert InvalidSender();
    _;
  }

  // Only the Sherlock Claims Committee multisig can call a function with this modifier
  modifier onlySPCC() {
    if (msg.sender != sherlockProtocolClaimsCommittee) revert InvalidSender();
    _;
  }

  // Only the UMA Halt Operator multisig can call a function with this modifier
  modifier onlyUMAHO() {
    if (msg.sender != umaHaltOperator) revert InvalidSender();
    _;
  }

  // We pass in the contract addresses (both will be multisigs) in the constructor
  constructor(address _umaho, address _spcc) {
    if (_umaho == address(0)) revert ZeroArgument();
    if (_spcc == address(0)) revert ZeroArgument();

    umaHaltOperator = _umaho;
    sherlockProtocolClaimsCommittee = _spcc;
  }

  // Checks to see if a claim can be escalated to the UMA OO
  // Claim must be either
  // 1) Denied by SPCC and within 4 weeks after denial
  // 2) Pending by SPCC but beyond the designated time window for SPCC to respond
  function _isEscalateState(State _oldState, uint256 updated) internal view returns (bool) {
    if (_oldState == State.SpccDenied && block.timestamp <= updated + ESCALATE_TIME) return true;

    uint256 spccDeadline = updated + SPCC_TIME;
    if (
      _oldState == State.SpccPending &&
      spccDeadline < block.timestamp &&
      block.timestamp <= spccDeadline + ESCALATE_TIME
    ) {
      return true;
    }
    return false;
  }

  // Checks to see if a claim can be paid out
  // Will be paid out if:
  // 1) SPCC approved it
  // 2) UMA OO approved it and there is no UMAHO anymore
  // 3) UMA OO approved it and the designated window for the UMAHO to block it has passed
  function _isPayoutState(State _oldState, uint256 updated) internal view returns (bool) {
    if (_oldState == State.SpccApproved) return true;

    // If there is no UMA Halt Operator, then it can be paid out on UmaApproved state
    if (umaHaltOperator == address(0)) {
      if (_oldState == State.UmaApproved) return true;
    } else {
      // If there IS a nonzero UMAHO address, must wait for UMAHO halt period to pass
      if (_oldState == State.UmaApproved && updated + UMAHO_TIME < block.timestamp) return true;
    }
    return false;
  }

  function _isCleanupState(State _oldState) internal pure returns (bool) {
    if (_oldState == State.SpccDenied) return true;
    if (_oldState == State.SpccPending) return true;
    return false;
  }

  // Deletes the data associated with a claim (after claim has reached its final state)
  // _claimIdentifier is the internal claim ID
  function _cleanUpClaim(bytes32 _claimIdentifier) internal {
    // Protocol no longer has an active claim associated with it
    delete protocolClaimActive[claims_[_claimIdentifier].protocol];
    // Claim object is deleted
    delete claims_[_claimIdentifier];

    uint256 publicID = internalToPublicID[_claimIdentifier];
    // Deletes the public and internal ID key mappings
    delete publicToInternalID[publicID];
    delete internalToPublicID[_claimIdentifier];
  }

  // Each claim has a state that represents what part of the claims process it is in
  // _claimIdentifier is the internal claim ID
  // _state represents the state to which a protocol's state field will be changed
  // See ISherlockClaimManager.sol for the State enum
  function _setState(bytes32 _claimIdentifier, State _state) internal returns (State _oldState) {
    // retrieves the Claim object
    Claim storage claim = claims_[_claimIdentifier];
    // retrieves the current state (which we preemptively set to the old state)
    _oldState = claim.state;

    emit ClaimStatusChanged(internalToPublicID[_claimIdentifier], _oldState, _state);

    // If the new state is NonExistent, then we clean up this claim (delete the claim effectively)
    // Else we update the state to the new state and record the last updated timestamp
    if (_state == State.NonExistent) {
      _cleanUpClaim(_claimIdentifier);
    } else {
      claims_[_claimIdentifier].state = _state;
      claims_[_claimIdentifier].updated = block.timestamp;
    }
  }

  // Allows us to remove the UMA Halt Operator multisig address if we decide we no longer need UMAHO's services
  /// @notice gov is able to renounce the role
  function renounceUmaHaltOperator() external override onlyOwner {
    if (umaHaltOperator == address(0)) revert InvalidConditions();

    delete umaHaltOperator;
    emit UMAHORenounced();
  }

  // Returns the Claim struct for a given claim ID (function takes public ID but converts to internal ID)
  function claim(uint256 _claimID) external view override returns (Claim memory claim_) {
    bytes32 id_ = publicToInternalID[_claimID];
    if (id_ == bytes32(0)) revert InvalidArgument();

    claim_ = claims_[id_];
    if (claim_.state == State.NonExistent) revert InvalidArgument();
  }

  // This function allows a new contract to be added that will implement PreCorePayoutCallback()
  // The intention of this callback is to allow other contracts to trigger payouts, etc. when Sherlock triggers one
  // This would be helpful for a reinsurer who should pay out when Sherlock pays out
  // Data is passed to the "reinsurer" so it can know if it should pay out and how much
  /// @dev only add trusted and gas verified callbacks.
  function addCallback(ISherlockClaimManagerCallbackReceiver _callback)
    external
    onlyOwner
    nonReentrant
  {
    if (address(_callback) == address(0)) revert ZeroArgument();
    // Checks to see if the max amount of callback contracts has been reached
    if (claimCallbacks.length == MAX_CALLBACKS) revert InvalidState();
    // Checks to see if this callback contract already exists
    for (uint256 i; i < claimCallbacks.length; i++) {
      if (claimCallbacks[i] == _callback) revert InvalidArgument();
    }

    claimCallbacks.push(_callback);
    emit CallbackAdded(_callback);
  }

  // This removes a contract from the claimCallbacks array
  function removeCallback(ISherlockClaimManagerCallbackReceiver _callback, uint256 _index)
    external
    onlyOwner
    nonReentrant
  {
    if (address(_callback) == address(0)) revert ZeroArgument();
    // If the index and the callback contract don't line up, revert
    if (claimCallbacks[_index] != _callback) revert InvalidArgument();

    // Move last index to index of _callback
    // Creates a copy of the last index value and pastes it over the _index value
    claimCallbacks[_index] = claimCallbacks[claimCallbacks.length - 1];
    // Remove last index (because it is now a duplicate)
    claimCallbacks.pop();
    emit CallbackRemoved(_callback);
  }

  /// @notice Cleanup claim if escalation is not pursued
  /// @param _protocol protocol ID
  /// @param _claimID public claim ID
  /// @dev Retrieves current protocol agent for cleanup
  /// @dev State is either SpccPending or SpccDenied
  function cleanUp(bytes32 _protocol, uint256 _claimID) external whenNotPaused {
    if (_protocol == bytes32(0)) revert ZeroArgument();
    if (_claimID == uint256(0)) revert ZeroArgument();

    // Gets the instance of the protocol manager contract
    ISherlockProtocolManager protocolManager = sherlockCore.sherlockProtocolManager();
    // Gets the protocol agent associated with the protocol ID passed in
    address agent = protocolManager.protocolAgent(_protocol);
    // Caller of this function must be the protocol agent address associated with the protocol ID passed in
    if (msg.sender != agent) revert InvalidSender();

    bytes32 claimIdentifier = publicToInternalID[_claimID];
    // If there is no active claim
    if (claimIdentifier == bytes32(0)) revert InvalidArgument();

    Claim storage claim = claims_[claimIdentifier];
    // verify if claim belongs to protocol agent
    if (claim.protocol != _protocol) revert InvalidArgument();

    State _oldState = _setState(claimIdentifier, State.Cleaned);
    if (_isCleanupState(_oldState) == false) revert InvalidState();
    if (_setState(claimIdentifier, State.NonExistent) != State.Cleaned) revert InvalidState();
  }

  /// @notice Initiate a claim for a specific protocol as the protocol agent
  /// @param _protocol protocol ID (different from the internal or public claim ID fields)
  /// @param _amount amount of USDC which is being claimed by the protocol
  /// @param _receiver address to receive the amount of USDC being claimed
  /// @param _timestamp timestamp at which the exploit first occurred
  /// @param ancillaryData other data associated with the claim, such as the coverage agreement
  /// @dev The protocol agent that starts a claim will be the protocol agent during the claims lifecycle
  /// @dev Even if the protocol agent role is tranferred during the lifecycle
  /// @dev This is done because a protocols coverage can end after an exploit, either wilfully or forcefully.
  /// @dev The protocol agent is still active for 7 days after coverage ends, so a claim can still be submitted.
  /// @dev Approved claims after the 7 day period will still be paid, where the amount will be sent to the recevier.
  function startClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    uint32 _timestamp,
    bytes memory ancillaryData
  ) external override nonReentrant whenNotPaused {
    if (_protocol == bytes32(0)) revert ZeroArgument();
    if (_amount == uint256(0)) revert ZeroArgument();
    if (_receiver == address(0)) revert ZeroArgument();
    if (_timestamp == uint32(0)) revert ZeroArgument();
    if (_timestamp >= block.timestamp) revert InvalidArgument();
    if (ancillaryData.length == 0) revert ZeroArgument();
    if (address(sherlockCore) == address(0)) revert InvalidConditions();
    // Protocol must not already have another claim active
    if (protocolClaimActive[_protocol]) revert ClaimActive();

    // Creates the internal ID for this claim
    bytes32 claimIdentifier = keccak256(ancillaryData);
    // State for this newly created claim must be equal to the default state (NonExistent)
    if (claims_[claimIdentifier].state != State.NonExistent) revert InvalidArgument();

    // Gets the instance of the protocol manager contract
    ISherlockProtocolManager protocolManager = sherlockCore.sherlockProtocolManager();
    // Gets the protocol agent associated with the protocol ID passed in
    address agent = protocolManager.protocolAgent(_protocol);
    // Caller of this function must be the protocol agent address associated with the protocol ID passed in
    if (msg.sender != agent) revert InvalidSender();

    // Gets the current and previous coverage amount for this protocol
    (uint256 current, uint256 previous) = protocolManager.coverageAmounts(_protocol);
    // The max amount a protocol can claim is the higher of the current and previous coverage amounts
    uint256 maxClaim = current > previous ? current : previous;
    // True if a protocol is claiming based on its previous coverage amount (only used in event emission)
    // Current coverage takes precedence over the previous one, which means the only case this is true
    // is when claimed amount is greater than current coverage.
    bool prevCoverage = _amount > current;
    // Requires the amount claimed is less than or equal to the higher of the current and previous coverage amounts
    if (_amount > maxClaim) revert InvalidArgument();

    // Increments the last claim ID by 1 to get the public claim ID
    // Note initial claimID will be 1
    uint256 claimID = ++lastClaimID;
    // Protocol now has an active claim
    protocolClaimActive[_protocol] = true;
    // Sets the mappings for public and internal claim IDs
    publicToInternalID[claimID] = claimIdentifier;
    internalToPublicID[claimIdentifier] = claimID;

    // Initializes a Claim object and adds it to claims_ mapping
    // Created and updated fields are set to current time
    // State is updated to SpccPending (waiting on SPCC decision now)
    claims_[claimIdentifier] = Claim(
      block.timestamp,
      block.timestamp,
      msg.sender,
      _protocol,
      _amount,
      _receiver,
      _timestamp,
      State.SpccPending,
      ancillaryData
    );

    emit ClaimCreated(claimID, _protocol, _amount, _receiver, prevCoverage);
    emit ClaimStatusChanged(claimID, State.NonExistent, State.SpccPending);
  }

  // Only SPCC can call this
  // SPCC approves the claim and it can now be paid out
  // Requires that the last state of the claim was SpccPending
  function spccApprove(uint256 _claimID) external override whenNotPaused onlySPCC nonReentrant {
    bytes32 claimIdentifier = publicToInternalID[_claimID];
    if (claimIdentifier == bytes32(0)) revert InvalidArgument();

    if (_setState(claimIdentifier, State.SpccApproved) != State.SpccPending) revert InvalidState();
  }

  // Only SPCC can call this
  // SPCC denies the claim and now the protocol agent can escalate to UMA OO if they desire
  function spccRefuse(uint256 _claimID) external override whenNotPaused onlySPCC nonReentrant {
    bytes32 claimIdentifier = publicToInternalID[_claimID];
    if (claimIdentifier == bytes32(0)) revert InvalidArgument();

    if (_setState(claimIdentifier, State.SpccDenied) != State.SpccPending) revert InvalidState();
  }

  // If SPCC denied (or didn't respond to) the claim, a protocol agent can now escalate it to UMA's OO
  /// @notice Callable by protocol agent
  /// @param _claimID Public claim ID
  /// @param _amount Bond amount sent by protocol agent
  /// @dev Use hardcoded USDC address
  /// @dev Use hardcoded bond amount
  /// @dev Use hardcoded liveness 7200 (2 hours)
  /// @dev Requires the caller to be the account that initially started the claim
  // Amount sent needs to be at least equal to the BOND amount required
  function escalate(uint256 _claimID, uint256 _amount)
    external
    override
    nonReentrant
    whenNotPaused
  {
    if (_amount < BOND) revert InvalidArgument();

    // Gets the internal ID of the claim
    bytes32 claimIdentifier = publicToInternalID[_claimID];
    if (claimIdentifier == bytes32(0)) revert InvalidArgument();

    // Retrieves the claim struct
    Claim storage claim = claims_[claimIdentifier];
    // Requires the caller to be the account that initially started the claim
    if (msg.sender != claim.initiator) revert InvalidSender();

    // Timestamp when claim was last updated
    uint256 updated = claim.updated;
    // Sets the state to UmaPriceProposed
    State _oldState = _setState(claimIdentifier, State.UmaPriceProposed);

    // Can this claim be updated (based on its current state)? If no, revert
    if (_isEscalateState(_oldState, updated) == false) revert InvalidState();

    // Transfers the bond amount from the protocol agent to this address
    TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
    // Approves the OO contract to spend the bond amount
    TOKEN.safeApprove(address(UMA), _amount);

    // Sherlock protocol proposes a claim amount of $0 to the UMA OO to begin with
    // This line https://github.com/UMAprotocol/protocol/blob/master/packages/core/contracts/oracle/implementation/SkinnyOptimisticOracle.sol#L585
    // Will result in disputeSuccess=true if the DVM resolved price != 0
    // Note: The resolved price needs to exactly match the claim amount
    // Otherwise the `umaApproved` in our settled callback will be false
    UMA.requestAndProposePriceFor(
      UMA_IDENTIFIER, // Sherlock ID so UMA knows the request came from Sherlock
      claim.timestamp, // Timestamp to identify the request
      claim.ancillaryData, // Ancillary data such as the coverage agreement
      TOKEN, // USDC
      0, // Reward is 0, Sherlock handles rewards on its own
      BOND, // Cost of making a request to the UMA OO (as decided by Sherlock)
      LIVENESS, // Proposal liveness
      address(sherlockCore), // If escalated claim fails, bond amount gets sent to sherlockCore
      0 // price
    );

    // If the state is not equal to ReadyToProposeUmaDispute, revert
    // Then set the new state to UmaDisputeProposed
    // Note State gets set to ReadyToProposeUmaDispute in the callback function from requestAndProposePriceFor()
    if (_setState(claimIdentifier, State.UmaDisputeProposed) != State.ReadyToProposeUmaDispute) {
      revert InvalidState();
    }

    // The protocol agent is now disputing Sherlock's proposed claim amount of $0
    UMA.disputePriceFor(
      UMA_IDENTIFIER, // Sherlock ID so UMA knows the request came from Sherlock
      claim.timestamp, // Timestamp to identify the request
      claim.ancillaryData, // Ancillary data such as the coverage agreement
      umaRequest, // Refers to the original request made by Sherlock in requestAndProposePriceFor()
      msg.sender, // Protocol agent, known as the disputer (the one who is disputing Sherlock's $0 proposed claim amount)
      address(this) // This contract's address is the requester (Sherlock made the original request and proposed $0 claim amount)
    );

    // State gets updated to UmaPending in the disputePriceFor() callback (priceDisputed())
    if (claim.state != State.UmaPending) revert InvalidState();

    // Deletes the original request made by Sherlock
    delete umaRequest;
    // Approves the OO to spend $0
    // This is just out of caution, don't want UMA to be approved for any amount of tokens they shouldn't be
    TOKEN.safeApprove(address(UMA), 0);
    // Checks for remaining balance in the contract
    uint256 remaining = TOKEN.balanceOf(address(this));
    // Sends remaining balance to the protocol agent
    // A protocol agent should be able to send the exact amount to avoid the extra gas from this function
    if (remaining != 0) TOKEN.safeTransfer(msg.sender, remaining);
  }

  // Checks to make sure a payout is valid, then calls the core Sherlock payout function
  /// @notice Execute claim, storage will be removed after
  /// @param _claimID Public ID of the claim
  /// @dev Needs to be SpccApproved or UmaApproved && >UMAHO_TIME
  /// @dev Funds will be pulled from core
  // We are ok with spending the extra time to wait for the UMAHO time to expire before paying out
  // We could have UMAHO multisig send a tx to confirm the payout (payout would happen sooner),
  // But doesn't seem worth it to save half a day or so
  function payoutClaim(uint256 _claimID) external override nonReentrant whenNotPaused {
    bytes32 claimIdentifier = publicToInternalID[_claimID];
    if (claimIdentifier == bytes32(0)) revert InvalidArgument();

    Claim storage claim = claims_[claimIdentifier];
    // Only the claim initiator can call this, and payout gets sent to receiver address
    if (msg.sender != claim.initiator) revert InvalidSender();

    bytes32 protocol = claim.protocol;
    // Address to receive the payout
    // Note We could make the receiver a param in this function, but we want it to be known asap
    // Can find and correct problems if the receiver is specified when the claim is initiated
    address receiver = claim.receiver;
    // Amount (in USDC) to be paid out
    uint256 amount = claim.amount;
    // Time when claim was last updated
    uint256 updated = claim.updated;

    // Sets new state to NonExistent as the claim is over once it is paid out
    State _oldState = _setState(claimIdentifier, State.NonExistent);
    // Checks to make sure this claim can be paid out
    if (_isPayoutState(_oldState, updated) == false) revert InvalidState();

    // Calls the PreCorePayoutCallback function on any contracts in claimCallbacks
    for (uint256 i; i < claimCallbacks.length; i++) {
      claimCallbacks[i].PreCorePayoutCallback(protocol, _claimID, amount);
    }

    emit ClaimPayout(_claimID, receiver, amount);

    // We could potentially transfer more than `amount` in case balance > amount
    // We are leaving this as is for simplicity's sake
    // We don't expect to have tokens in this contract unless a reinsurer is providing them for a payout
    // In which case they should provide the exact amount, and balance == amount is true
    uint256 balance = TOKEN.balanceOf(address(this));
    if (balance != 0) TOKEN.safeTransfer(receiver, balance);
    if (balance < amount) sherlockCore.payoutClaim(receiver, amount - balance);
  }

  /// @notice UMAHO is able to execute a halt if the state is UmaApproved and state was updated less than UMAHO_TIME ago
  // Once the UMAHO_TIME is up, UMAHO can still halt the claim, but only if the claim hasn't been paid out yet
  function executeHalt(uint256 _claimID) external override whenNotPaused onlyUMAHO nonReentrant {
    bytes32 claimIdentifier = publicToInternalID[_claimID];
    if (claimIdentifier == bytes32(0)) revert InvalidArgument();

    // Sets state of claim to nonexistent, reverts if the old state was anything but UmaApproved
    if (_setState(claimIdentifier, State.Halted) != State.UmaApproved) revert InvalidState();
    if (_setState(claimIdentifier, State.NonExistent) != State.Halted) revert InvalidState();

    emit ClaimHalted(_claimID);
  }

  //
  // UMA callbacks
  //

  // Once requestAndProposePriceFor() is executed in UMA's contracts, this function gets called
  // We change the claim's state from UmaPriceProposed to ReadyToProposeUmaDispute
  // Then, the next callback in the process, disputePriceFor(), gets called by the UMA's contract.
  // @note Does not have reentrancy protection because it is called by the OO contract which is non-reentrant.
  function priceProposed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external override whenNotPaused onlyUMA(identifier) {
    bytes32 claimIdentifier = keccak256(ancillaryData);

    Claim storage claim = claims_[claimIdentifier];
    if (claim.updated != block.timestamp) revert InvalidConditions();

    // Sets state to ReadyToProposeUmaDispute
    if (_setState(claimIdentifier, State.ReadyToProposeUmaDispute) != State.UmaPriceProposed) {
      revert InvalidState();
    }
    // Sets global umaRequest variable to the request coming from this price proposal
    umaRequest = request;
  }

  // Once disputePriceFor() is executed in UMA's contracts, this function gets called
  // We change the claim's state from UmaDisputeProposed to UmaPending
  // Then, the next callback in the process, priceSettled(), gets called by the UMA's contract.
  // @note Does not have reentrancy protection because it is called by the OO contract which is non-reentrant.
  function priceDisputed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external override whenNotPaused onlyUMA(identifier) {
    bytes32 claimIdentifier = keccak256(ancillaryData);

    Claim storage claim = claims_[claimIdentifier];
    if (claim.updated != block.timestamp) revert InvalidConditions();

    // Sets state to UmaPending
    if (_setState(claimIdentifier, State.UmaPending) != State.UmaDisputeProposed) {
      revert InvalidState();
    }
  }

  // Once priceSettled() is executed in UMA's contracts, this function gets called
  // UMA OO gives back a resolved price (either 0 or claim.amount) and
  // Claim's state is changed to either UmaApproved or UmaDenied
  // If UmaDenied, the claim is dead and state is immediately changed to NonExistent and cleaned up
  /// @dev still want to capture settled price in a paused state. Otherwise claim is stuck.
  function priceSettled(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external override onlyUMA(identifier) nonReentrant {
    bytes32 claimIdentifier = keccak256(ancillaryData);

    Claim storage claim = claims_[claimIdentifier];

    // Retrives the resolved price for this claim (either 0 if Sherlock wins, or the amount of the claim as proposed by the protocol agent)
    uint256 resolvedPrice = uint256(request.resolvedPrice);
    // UMA approved the claim if the resolved price is equal to the claim amount set by the protocol agent
    bool umaApproved = resolvedPrice == claim.amount;

    // If UMA approves the claim, set state to UmaApproved
    // If UMA denies, set state to UmaDenied, then to NonExistent (deletes the claim data)
    if (umaApproved) {
      if (_setState(claimIdentifier, State.UmaApproved) != State.UmaPending) revert InvalidState();
    } else {
      if (_setState(claimIdentifier, State.UmaDenied) != State.UmaPending) revert InvalidState();
      if (_setState(claimIdentifier, State.NonExistent) != State.UmaDenied) revert InvalidState();
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

import '../interfaces/managers/IManager.sol';

abstract contract Manager is IManager, Ownable, Pausable {
  using SafeERC20 for IERC20;

  address private constant DEPLOYER = 0x1C11bE636415973520DdDf1b03822b4e2930D94A;
  ISherlock internal sherlockCore;

  modifier onlySherlockCore() {
    if (msg.sender != address(sherlockCore)) revert InvalidSender();
    _;
  }

  /// @notice Set sherlock core address
  /// @param _sherlock Current core contract
  /// @dev Only deployer is able to set core address on all chains except Hardhat network
  /// @dev One time function, will revert once `sherlock` != address(0)
  /// @dev This contract will be deployed first, passed on as argument in core constuctor
  /// @dev emits `SherlockCoreSet`
  function setSherlockCoreAddress(ISherlock _sherlock) external override {
    if (address(_sherlock) == address(0)) revert ZeroArgument();
    // 31337 is of the Hardhat network blockchain
    if (block.chainid != 31337 && msg.sender != DEPLOYER) revert InvalidSender();

    if (address(sherlockCore) != address(0)) revert InvalidConditions();
    sherlockCore = _sherlock;

    emit SherlockCoreSet(_sherlock);
  }

  // Internal function to send tokens remaining in a contract to the receiver address
  function _sweep(address _receiver, IERC20[] memory _extraTokens) internal {
    // Loops through the extra tokens (ERC20) provided and sends all of them to the receiver address
    for (uint256 i; i < _extraTokens.length; i++) {
      IERC20 token = _extraTokens[i];
      token.safeTransfer(_receiver, token.balanceOf(address(this)));
    }
    // Sends any remaining ETH to the receiver address (as long as receiver address is payable)
    (bool success, ) = _receiver.call{ value: address(this).balance }('');
    if (success == false) revert InvalidConditions();
  }

  function pause() external onlySherlockCore {
    _pause();
  }

  function unpause() external onlySherlockCore {
    _unpause();
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './callbacks/ISherlockClaimManagerCallbackReceiver.sol';
import '../UMAprotocol/OptimisticRequester.sol';
import './IManager.sol';

interface ISherlockClaimManager is IManager, OptimisticRequester {
  // Doesn't allow a new claim to be submitted by a protocol agent if a claim is already active for that protocol
  error ClaimActive();

  // If the current state of a claim does not match the expected state, this error is thrown
  error InvalidState();

  event ClaimCreated(
    uint256 claimID,
    bytes32 indexed protocol,
    uint256 amount,
    address receiver,
    bool previousCoverageUsed
  );

  event CallbackAdded(ISherlockClaimManagerCallbackReceiver callback);

  event CallbackRemoved(ISherlockClaimManagerCallbackReceiver callback);

  event ClaimStatusChanged(uint256 indexed claimID, State previousState, State currentState);

  event ClaimPayout(uint256 claimID, address receiver, uint256 amount);

  event ClaimHalted(uint256 claimID);

  event UMAHORenounced();

  enum State {
    NonExistent, // Claim doesn't exist (this is the default state on creation)
    SpccPending, // Claim is created, SPCC is able to set state to valid
    SpccApproved, // Final state, claim is valid
    SpccDenied, // Claim denied by SPCC, claim can be escalated within 4 weeks
    UmaPriceProposed, // Price is proposed but not escalated
    ReadyToProposeUmaDispute, // Price is proposed, callback received, ready to submit dispute
    UmaDisputeProposed, // Escalation is done, waiting for confirmation
    UmaPending, // Claim is escalated, in case Spcc denied or didn't act within 7 days.
    UmaApproved, // Final state, claim is valid, claim can be enacted after 1 day, umaHaltOperator has 1 day to change to denied
    UmaDenied, // Final state, claim is invalid
    Halted, // UMAHO can halt claim if state is UmaApproved
    Cleaned // Claim is removed by protocol agent
  }

  struct Claim {
    uint256 created;
    uint256 updated;
    address initiator;
    bytes32 protocol;
    uint256 amount;
    address receiver;
    uint32 timestamp;
    State state;
    bytes ancillaryData;
  }

  // requestAndProposePriceFor() --> proposer = sherlockCore (address to receive BOND if UMA denies claim)
  // disputePriceFor() --> disputer = protocolAgent
  // priceSettled will be the the callback that contains the main data

  // Assume BOND = 9600, UMA's final fee = 1500.
  // Claim initiator (Sherlock) has to pay 22.2k to dispute a claim,
  // so we will execute a safeTransferFrom(claimInitiator, address(this), 22.2k).
  // We need to approve the contract 22.2k as it will be transferred from address(this).

  // The 22.2k consists of 2 * (BOND + final fee charged by UMA), as follows:
  // 1. On requestAndProposePriceFor(), the fee will be 10k: 9600 BOND + 1500 UMA's final fee;
  // 2. On disputePriceFor(), the fee will be the same 10k.
  // note that half of the BOND (4800) + UMA's final fee (1500) is "burnt" and sent to UMA

  // UMA's final fee can be changed in the future, which may result in lower or higher required staked amounts for escalating a claim.

  // On settle, either the protocolAgent (dispute success) or sherlockCore (dispute failure)
  // will receive 9600 + 4800 + 1500 = 15900. In addition, the protocolAgent will be entitled to
  // the claimAmount if the dispute is successful/

  // lastClaimID <-- starts with 0, so initial id = 1
  // have claim counter, easy to identify certain claims by their number
  // but use hash(callback.request.propose + callback.timestamp) as the internal UUID to handle the callbacks

  // So SPCC and UMAHO are hardcoded (UMAHO can be renounced)
  // In case these need to be updated, deploy different contract and upgrade it on the sherlock gov side.

  // On price proposed callback --> call disputePriceFor with callbackdata + sherlock.strategyManager() and address(this)

  /// @notice `SHERLOCK_CLAIM` in utf8
  function UMA_IDENTIFIER() external view returns (bytes32);

  function sherlockProtocolClaimsCommittee() external view returns (address);

  /// @notice operator is able to deny approved UMA claims
  function umaHaltOperator() external view returns (address);

  /// @notice gov is able to renounce the role
  function renounceUmaHaltOperator() external;

  function claim(uint256 _claimID) external view returns (Claim memory);

  /// @notice Initiate a claim for a specific protocol as the protocol agent
  /// @param _protocol protocol ID (different from the internal or public claim ID fields)
  /// @param _amount amount of USDC which is being claimed by the protocol
  /// @param _receiver address to receive the amount of USDC being claimed
  /// @param _timestamp timestamp at which the exploit first occurred
  /// @param ancillaryData other data associated with the claim, such as the coverage agreement
  /// @dev The protocol agent that starts a claim will be the protocol agent during the claims lifecycle
  /// @dev Even if the protocol agent role is tranferred during the lifecycle
  function startClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver,
    uint32 _timestamp,
    bytes memory ancillaryData
  ) external;

  function spccApprove(uint256 _claimID) external;

  function spccRefuse(uint256 _claimID) external;

  /// @notice Callable by protocol agent
  /// @param _claimID Public claim ID
  /// @param _amount Bond amount sent by protocol agent
  /// @dev Use hardcoded USDC address
  /// @dev Use hardcoded bond amount
  /// @dev Use hardcoded liveness 7200 (2 hours)
  /// @dev proposedPrice = _amount
  function escalate(uint256 _claimID, uint256 _amount) external;

  /// @notice Execute claim, storage will be removed after
  /// @param _claimID Public ID of the claim
  /// @dev Needs to be SpccApproved or UmaApproved && >UMAHO_TIME
  /// @dev Funds will be pulled from core
  function payoutClaim(uint256 _claimID) external;

  /// @notice UMAHO is able to execute a halt if the state is UmaApproved and state was updated less than UMAHO_TIME ago
  function executeHalt(uint256 _claimID) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './IManager.sol';

/// @title Sherlock core interface for protocols
/// @author Evert Kors
interface ISherlockProtocolManager is IManager {
  // msg.sender is not authorized to call this function
  error Unauthorized();

  // If a protocol was never instantiated or was removed and the claim deadline has passed, this error is returned
  error ProtocolNotExists(bytes32 protocol);

  // When comparing two arrays and the lengths are not equal (but are supposed to be equal)
  error UnequalArrayLength();

  // If there is not enough balance in the contract for the amount requested (after any requirements are met), this is returned
  error InsufficientBalance(bytes32 protocol);

  event MinBalance(uint256 previous, uint256 current);

  event AccountingError(bytes32 indexed protocol, uint256 amount, uint256 insufficientTokens);

  event ProtocolAdded(bytes32 indexed protocol);

  event ProtocolRemovedByArb(bytes32 indexed protocol, address arb, uint256 profit);

  event ProtocolRemoved(bytes32 indexed protocol);

  event ProtocolUpdated(
    bytes32 indexed protocol,
    bytes32 coverage,
    uint256 nonStakers,
    uint256 coverageAmount
  );

  event ProtocolAgentTransfer(bytes32 indexed protocol, address from, address to);

  event ProtocolBalanceDeposited(bytes32 indexed protocol, uint256 amount);

  event ProtocolBalanceWithdrawn(bytes32 indexed protocol, uint256 amount);

  event ProtocolPremiumChanged(bytes32 indexed protocol, uint256 oldPremium, uint256 newPremium);

  /// @notice View current amount of all premiums that are owed to stakers
  /// @return Premiums claimable
  /// @dev Will increase every block
  /// @dev base + (now - last_settled) * ps
  function claimablePremiums() external view returns (uint256);

  /// @notice Transfer current claimable premiums (for stakers) to core Sherlock address
  /// @dev Callable by everyone
  /// @dev Funds will be transferred to Sherlock core contract
  function claimPremiumsForStakers() external;

  /// @notice View current protocolAgent of `_protocol`
  /// @param _protocol Protocol identifier
  /// @return Address able to submit claims
  function protocolAgent(bytes32 _protocol) external view returns (address);

  /// @notice View current premium of protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of premium `_protocol` pays per second
  function premium(bytes32 _protocol) external view returns (uint256);

  /// @notice View current active balance of covered protocol
  /// @param _protocol Protocol identifier
  /// @return Active balance
  /// @dev Accrued debt is subtracted from the stored active balance
  function activeBalance(bytes32 _protocol) external view returns (uint256);

  /// @notice View seconds of coverage left for `_protocol` before it runs out of active balance
  /// @param _protocol Protocol identifier
  /// @return Seconds of coverage left
  function secondsOfCoverageLeft(bytes32 _protocol) external view returns (uint256);

  /// @notice Add a new protocol to Sherlock
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Address able to submit a claim on behalf of the protocol
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Adding a protocol allows the `_protocolAgent` to submit a claim
  /// @dev Coverage is not started yet as the protocol doesn't pay a premium at this point
  /// @dev `_nonStakers` is scaled by 10**18
  /// @dev Only callable by governance
  function protocolAdd(
    bytes32 _protocol,
    address _protocolAgent,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) external;

  /// @notice Update info regarding a protocol
  /// @param _protocol Protocol identifier
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Only callable by governance
  function protocolUpdate(
    bytes32 _protocol,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) external;

  /// @notice Remove a protocol from coverage
  /// @param _protocol Protocol identifier
  /// @dev Before removing a protocol the premium must be 0
  /// @dev Removing a protocol basically stops the `_protocolAgent` from being active (can still submit claims until claim deadline though)
  /// @dev Pays off debt + sends remaining balance to protocol agent
  /// @dev This call should be subject to a timelock
  /// @dev Only callable by governance
  function protocolRemove(bytes32 _protocol) external;

  /// @notice Remove a protocol with insufficient active balance
  /// @param _protocol Protocol identifier
  function forceRemoveByActiveBalance(bytes32 _protocol) external;

  /// @notice Removes a protocol with insufficent seconds of coverage left
  /// @param _protocol Protocol identifier
  function forceRemoveBySecondsOfCoverage(bytes32 _protocol) external;

  /// @notice View minimal balance needed before liquidation can start
  /// @return Minimal balance needed
  function minActiveBalance() external view returns (uint256);

  /// @notice Sets the minimum active balance before an arb can remove a protocol
  /// @param _minActiveBalance Minimum balance needed (in USDC)
  /// @dev Only gov
  function setMinActiveBalance(uint256 _minActiveBalance) external;

  /// @notice Set premium of `_protocol` to `_premium`
  /// @param _protocol Protocol identifier
  /// @param _premium Amount of premium `_protocol` pays per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremium(bytes32 _protocol, uint256 _premium) external;

  /// @notice Set premium of multiple protocols
  /// @param _protocol Array of protocol identifiers
  /// @param _premium Array of premium amounts protocols pay per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremiums(bytes32[] calldata _protocol, uint256[] calldata _premium) external;

  /// @notice Deposits `_amount` of token to the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to deposit
  /// @dev Approval should be made before calling
  function depositToActiveBalance(bytes32 _protocol, uint256 _amount) external;

  /// @notice Withdraws `_amount` of token from the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to withdraw
  /// @dev Only protocol agent is able to withdraw
  /// @dev Balance can be withdrawn up until 7 days worth of active balance
  function withdrawActiveBalance(bytes32 _protocol, uint256 _amount) external;

  /// @notice Transfer protocol agent role
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Account able to submit a claim on behalf of the protocol
  /// @dev Only the active protocolAgent is able to transfer the role
  function transferProtocolAgent(bytes32 _protocol, address _protocolAgent) external;

  /// @notice View the amount nonstakers can claim from this protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of tokens claimable by nonstakers
  /// @dev this reads from a storage variable + (now-lastsettled) * premiums
  function nonStakersClaimable(bytes32 _protocol) external view returns (uint256);

  /// @notice Choose an `_amount` of tokens that nonstakers (`_receiver` address) will receive from `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _receiver Address to receive tokens
  /// @dev Only callable by nonstakers role
  function nonStakersClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver
  ) external;

  /// @param _protocol Protocol identifier
  /// @return current and previous are the current and previous coverage amounts for this protocol
  function coverageAmounts(bytes32 _protocol)
    external
    view
    returns (uint256 current, uint256 previous);

  /// @notice Function used to check if this is the current active protocol manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './OptimisticOracleInterface.sol';

/**
 * @title Interface for the gas-cost-reduced version of the OptimisticOracle.
 * @notice Differences from normal OptimisticOracle:
 * - refundOnDispute: flag is removed, by default there are no refunds on disputes.
 * - customizing request parameters: In the OptimisticOracle, parameters like `bond` and `customLiveness` can be reset
 *   after a request is already made via `requestPrice`. In the SkinnyOptimisticOracle, these parameters can only be
 *   set in `requestPrice`, which has an expanded input set.
 * - settleAndGetPrice: Replaced by `settle`, which can only be called once per settleable request. The resolved price
 *   can be fetched via the `Settle` event or the return value of `settle`.
 * - general changes to interface: Functions that interact with existing requests all require the parameters of the
 *   request to modify to be passed as input. These parameters must match with the existing request parameters or the
 *   function will revert. This change reflects the internal refactor to store hashed request parameters instead of the
 *   full request struct.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract SkinnyOptimisticOracleInterface {
  event RequestPrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event ProposePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event DisputePrice(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  event Settle(
    address indexed requester,
    bytes32 indexed identifier,
    uint32 timestamp,
    bytes ancillaryData,
    Request request
  );
  // Struct representing a price request. Note that this differs from the OptimisticOracleInterface's Request struct
  // in that refundOnDispute is removed.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @return totalBond default bond + final fee that the proposer and disputer will be required to pay.
   */
  function requestPrice(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address proposer,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value where caller is the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * propose a price for.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Combines logic of requestPrice and proposePrice while taking advantage of gas savings from not having to
   * overwrite Request params that a normal requestPrice() => proposePrice() flow would entail. Note: The proposer
   * will receive any rewards that come from this proposal. However, any bonds are pulled from the caller.
   * @dev The caller is the requester, but the proposer can be customized.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @param bond custom proposal bond to set for request. If set to 0, defaults to the final fee.
   * @param customLiveness custom proposal liveness to set for request.
   * @param proposer address to set as the proposer.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function requestAndProposePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward,
    uint256 bond,
    uint256 customLiveness,
    address proposer,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePriceFor(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request,
    address disputer,
    address requester
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal where caller is the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * dispute.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters whose hash must match the request that the caller wants to
   * settle.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   * @return resolvedPrice the price that the request settled to.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (uint256 payout, int256 resolvedPrice);

  /**
   * @notice Computes the current state of a price request. See the State enum for more details.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters.
   * @return the State.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) external virtual returns (OptimisticOracleInterface.State);

  /**
   * @notice Checks if a given request has resolved, expired or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request price request parameters. The hash of these parameters must match with the request hash that is
   * associated with the price request unique ID {requester, identifier, timestamp, ancillaryData}, or this method
   * will revert.
   * @return boolean indicating true if price exists and false if not.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    Request memory request
  ) public virtual returns (bool);

  /**
   * @notice Generates stamped ancillary data in the format that it would be used in the case of a price dispute.
   * @param ancillaryData ancillary data of the price being requested.
   * @param requester sender of the initial price request.
   * @return the stamped ancillary bytes.
   */
  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    pure
    virtual
    returns (bytes memory);
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '../ISherlock.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IManager {
  // An address or other value passed in is equal to zero (and shouldn't be)
  error ZeroArgument();

  // Occurs when a value already holds the desired property, or is not whitelisted
  error InvalidArgument();

  // If a required condition for executing the function is not met, it reverts and throws this error
  error InvalidConditions();

  // Throws if the msg.sender is not the required address
  error InvalidSender();

  event SherlockCoreSet(ISherlock sherlock);

  /// @notice Set sherlock core address where premiums should be send too
  /// @param _sherlock Current core contract
  /// @dev Only deployer is able to set core address on all chains except Hardhat network
  /// @dev One time function, will revert once `sherlock` != address(0)
  /// @dev This contract will be deployed first, passed on as argument in core constuctor
  /// @dev ^ that's needed for tvl accounting, once core is deployed this function is called
  /// @dev emits `SherlockCoreSet`
  function setSherlockCoreAddress(ISherlock _sherlock) external;

  /// @notice Pause external functions in contract
  function pause() external;

  /// @notice Unpause external functions in contract
  function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './ISherlockStake.sol';
import './ISherlockGov.sol';
import './ISherlockPayout.sol';
import './ISherlockStrategy.sol';

interface ISherlock is ISherlockStake, ISherlockGov, ISherlockPayout, ISherlockStrategy, IERC721 {
  // msg.sender is not authorized to call this function
  error Unauthorized();

  // An address or other value passed in is equal to zero (and shouldn't be)
  error ZeroArgument();

  // Occurs when a value already holds the desired property, or is not whitelisted
  error InvalidArgument();

  // Required conditions are not true/met
  error InvalidConditions();

  // If the SHER tokens held in a contract are not the value they are supposed to be
  error InvalidSherAmount(uint256 expected, uint256 actual);

  // Checks the ERC-721 functions _exists() to see if an NFT ID actually exists and errors if not
  error NonExistent();

  event ArbRestaked(uint256 indexed tokenID, uint256 reward);

  event Restaked(uint256 indexed tokenID);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

/// @title Sherlock core interface for stakers
/// @author Evert Kors
interface ISherlockStake {
  /// @notice View the current lockup end timestamp of `_tokenID`
  /// @return Timestamp when NFT position unlocks
  function lockupEnd(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current SHER reward of `_tokenID`
  /// @return Amount of SHER rewarded to owner upon reaching the end of the lockup
  function sherRewards(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current token balance claimable upon reaching end of the lockup
  /// @return Amount of tokens assigned to owner when unstaking position
  function tokenBalanceOf(uint256 _tokenID) external view returns (uint256);

  /// @notice View the current TVL for all stakers
  /// @return Total amount of tokens staked
  /// @dev Adds principal + strategy + premiums
  /// @dev Will calculate the most up to date value for each piece
  function totalTokenBalanceStakers() external view returns (uint256);

  /// @notice Stakes `_amount` of tokens and locks up for `_period` seconds, `_receiver` will receive the NFT receipt
  /// @param _amount Amount of tokens to stake
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @param _receiver Address that will receive the NFT representing the position
  /// @return _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to this ID after `_period` ends
  /// @dev `_period` needs to be whitelisted
  function initialStake(
    uint256 _amount,
    uint256 _period,
    address _receiver
  ) external returns (uint256 _id, uint256 _sher);

  /// @notice Redeem NFT `_id` and receive `_amount` of tokens
  /// @param _id TokenID of the position
  /// @return _amount Amount of tokens (USDC) owed to NFT ID
  /// @dev Only the owner of `_id` will be able to redeem their position
  /// @dev The SHER rewards are sent to the NFT owner
  /// @dev Can only be called after lockup `_period` has ended
  function redeemNFT(uint256 _id) external returns (uint256 _amount);

  /// @notice Owner restakes position with ID: `_id` for `_period` seconds
  /// @param _id ID of the position
  /// @param _period Period of time, in seconds, to lockup your funds
  /// @return _sher Amount of SHER tokens to be released to owner address after `_period` ends
  /// @dev Only the owner of `_id` will be able to restake their position using this call
  /// @dev `_period` needs to be whitelisted
  /// @dev Can only be called after lockup `_period` has ended
  function ownerRestake(uint256 _id, uint256 _period) external returns (uint256 _sher);

  /// @notice Allows someone who doesn't own the position (an arbitrager) to restake the position for 26 weeks (ARB_RESTAKE_PERIOD)
  /// @param _id ID of the position
  /// @return _sher Amount of SHER tokens to be released to position owner on expiry of the 26 weeks lockup
  /// @return _arbReward Amount of tokens (USDC) sent to caller (the arbitrager) in return for calling the function
  /// @dev Can only be called after lockup `_period` is more than 2 weeks in the past (assuming ARB_RESTAKE_WAIT_TIME is 2 weeks)
  /// @dev Max 20% (ARB_RESTAKE_MAX_PERCENTAGE) of tokens associated with a position are used to incentivize arbs (x)
  /// @dev During a 2 week period the reward ratio will move from 0% to 100% (* x)
  function arbRestake(uint256 _id) external returns (uint256 _sher, uint256 _arbReward);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './managers/ISherDistributionManager.sol';
import './managers/ISherlockProtocolManager.sol';
import './managers/ISherlockClaimManager.sol';
import './managers/IStrategyManager.sol';

/// @title Sherlock core interface for governance
/// @author Evert Kors
interface ISherlockGov {
  event ClaimPayout(address receiver, uint256 amount);
  event YieldStrategyUpdateWithdrawAllError(bytes error);
  event YieldStrategyUpdated(IStrategyManager previous, IStrategyManager current);
  event ProtocolManagerUpdated(ISherlockProtocolManager previous, ISherlockProtocolManager current);
  event ClaimManagerUpdated(ISherlockClaimManager previous, ISherlockClaimManager current);
  event NonStakerAddressUpdated(address previous, address current);
  event SherDistributionManagerUpdated(
    ISherDistributionManager previous,
    ISherDistributionManager current
  );

  event StakingPeriodEnabled(uint256 period);

  event StakingPeriodDisabled(uint256 period);

  /// @notice Allows stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already enabled
  function enableStakingPeriod(uint256 _period) external;

  /// @notice Disallow stakers to stake for `_period` of time
  /// @param _period Period of time, in seconds,
  /// @dev should revert if already disabled
  function disableStakingPeriod(uint256 _period) external;

  /// @notice View if `_period` is a valid period
  /// @return Boolean indicating if period is valid
  function stakingPeriods(uint256 _period) external view returns (bool);

  /// @notice Update SHER distribution manager contract
  /// @param _sherDistributionManager New adddress of the manager
  function updateSherDistributionManager(ISherDistributionManager _sherDistributionManager)
    external;

  /// @notice Deletes the SHER distribution manager altogether (if Sherlock decides to no longer pay out SHER rewards)
  function removeSherDistributionManager() external;

  /// @notice Read SHER distribution manager
  /// @return Address of current SHER distribution manager
  function sherDistributionManager() external view returns (ISherDistributionManager);

  /// @notice Update address eligible for non staker rewards from protocol premiums
  /// @param _nonStakers Address eligible for non staker rewards
  function updateNonStakersAddress(address _nonStakers) external;

  /// @notice View current non stakers address
  /// @return Current non staker address
  /// @dev Is able to pull funds out of the contract
  function nonStakersAddress() external view returns (address);

  /// @notice View current address able to manage protocols
  /// @return Protocol manager implemenation
  function sherlockProtocolManager() external view returns (ISherlockProtocolManager);

  /// @notice Transfer protocol manager implementation address
  /// @param _protocolManager new implementation address
  function updateSherlockProtocolManager(ISherlockProtocolManager _protocolManager) external;

  /// @notice View current address able to pull payouts
  /// @return Address able to pull payouts
  function sherlockClaimManager() external view returns (ISherlockClaimManager);

  /// @notice Transfer claim manager role to different address
  /// @param _claimManager New address of claim manager
  function updateSherlockClaimManager(ISherlockClaimManager _claimManager) external;

  /// @notice Update yield strategy
  /// @param _yieldStrategy New address of the strategy
  /// @dev try a yieldStrategyWithdrawAll() on old, ignore failure
  function updateYieldStrategy(IStrategyManager _yieldStrategy) external;

  /// @notice Update yield strategy ignoring current state
  /// @param _yieldStrategy New address of the strategy
  /// @dev tries a yieldStrategyWithdrawAll() on old strategy, ignore failure
  function updateYieldStrategyForce(IStrategyManager _yieldStrategy) external;

  /// @notice Read current strategy
  /// @return Address of current strategy
  /// @dev can never be address(0)
  function yieldStrategy() external view returns (IStrategyManager);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

/// @title Sherlock interface for payout manager
/// @author Evert Kors
interface ISherlockPayout {
  /// @notice Initiate a payout of `_amount` to `_receiver`
  /// @param _receiver Receiver of payout
  /// @param _amount Amount to send
  /// @dev only payout manager should call this
  /// @dev should pull money out of strategy
  function payoutClaim(address _receiver, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './managers/IStrategyManager.sol';

/// @title Sherlock core interface for yield strategy
/// @author Evert Kors
interface ISherlockStrategy {
  /// @notice Deposit `_amount` into active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyDeposit(uint256 _amount) external;

  /// @notice Withdraw `_amount` from active strategy
  /// @param _amount Amount of tokens
  /// @dev gov only
  function yieldStrategyWithdraw(uint256 _amount) external;

  /// @notice Withdraw all funds from active strategy
  /// @dev gov only
  function yieldStrategyWithdrawAll() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IManager.sol';

interface ISherDistributionManager is IManager {
  // anyone can just send token to this contract to fund rewards

  event Initialized(uint256 maxRewardsEndTVL, uint256 zeroRewardsStartTVL, uint256 maxRewardRate);

  /// @notice Caller will receive `_sher` SHER tokens based on `_amount` and `_period`
  /// @param _amount Amount of tokens (in USDC) staked
  /// @param _period Period of time for stake, in seconds
  /// @param _id ID for this NFT position
  /// @param _receiver Address that will be linked to this position
  /// @return _sher Amount of SHER tokens sent to Sherlock core contract
  /// @dev Calling contract will depend on before + after balance diff and return value
  /// @dev INCLUDES stake in calculation, function expects the `_amount` to be deposited already
  /// @dev If tvl=50 and amount=50, this means it is calculating SHER rewards for the first 50 tokens going in
  function pullReward(
    uint256 _amount,
    uint256 _period,
    uint256 _id,
    address _receiver
  ) external returns (uint256 _sher);

  /// @notice Calculates how many `_sher` SHER tokens are owed to a stake position based on `_amount` and `_period`
  /// @param _tvl TVL to use for reward calculation (pre-stake TVL)
  /// @param _amount Amount of tokens (USDC) staked
  /// @param _period Stake period (in seconds)
  /// @return _sher Amount of SHER tokens owed to this stake position
  /// @dev EXCLUDES `_amount` of stake, this will be added on top of TVL (_tvl is excluding _amount)
  /// @dev If tvl=0 and amount=50, it would calculate for the first 50 tokens going in (different from pullReward())
  function calcReward(
    uint256 _tvl,
    uint256 _amount,
    uint256 _period
  ) external view returns (uint256 _sher);

  /// @notice Function used to check if this is the current active distribution manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './IManager.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStrategyManager is IManager {
  /// @return Returns the token type being deposited into a strategy
  function want() external view returns (IERC20);

  /// @notice Withdraws all USDC from the strategy back into the Sherlock core contract
  /// @dev Only callable by the Sherlock core contract
  /// @return The final amount withdrawn
  function withdrawAll() external returns (uint256);

  /// @notice Withdraws a specific amount of USDC from the strategy back into the Sherlock core contract
  /// @param _amount Amount of USDC to withdraw
  function withdraw(uint256 _amount) external;

  /// @notice Deposits all USDC held in this contract into the strategy
  function deposit() external;

  /// @return Returns the USDC balance in this contract
  function balanceOf() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

interface ISherlockClaimManagerCallbackReceiver {
  /// @notice Calls this function on approved contracts and passes args
  /// @param _protocol The protocol that is receiving the payout
  /// @param _claimID The claim ID that is receiving the payout
  /// @param _amount The amount of USDC being paid out for this claim
  function PreCorePayoutCallback(
    bytes32 _protocol,
    uint256 _claimID,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import './SkinnyOptimisticOracleInterface.sol';

/**
 * @title Optimistic Requester.
 * @notice Optional interface that requesters can implement to receive callbacks.
 * @dev This contract does _not_ work with ERC777 collateral currencies or any others that call into the receiver on
 * transfer(). Using an ERC777 token would allow a user to maliciously grief other participants (while also losing
 * money themselves).
 */
interface OptimisticRequester {
  /**
   * @notice Callback for proposals.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after proposal.
   */
  function priceProposed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;

  /**
   * @notice Callback for disputes.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after dispute.
   */
  function priceDisputed(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;

  /**
   * @notice Callback for settlement.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data of the price being requested.
   * @param request request params after settlement.
   */
  function priceSettled(
    bytes32 identifier,
    uint32 timestamp,
    bytes memory ancillaryData,
    SkinnyOptimisticOracleInterface.Request memory request
  ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Financial contract facing Oracle interface.
 * @dev Interface used by financial contracts to interact with the Oracle. Voters will use a different interface.
 */
abstract contract OptimisticOracleInterface {
  // Struct representing the state of a price request.
  enum State {
    Invalid, // Never requested.
    Requested, // Requested, no other actions taken.
    Proposed, // Proposed, but not expired or disputed yet.
    Expired, // Proposed, not disputed, past liveness.
    Disputed, // Disputed, but no DVM price returned yet.
    Resolved, // Disputed and DVM price is available.
    Settled // Final price has been set in the contract (can get here from Expired or Resolved).
  }

  // Struct representing a price request.
  struct Request {
    address proposer; // Address of the proposer.
    address disputer; // Address of the disputer.
    IERC20 currency; // ERC20 token used to pay rewards and fees.
    bool settled; // True if the request is settled.
    bool refundOnDispute; // True if the requester should be refunded their reward on dispute.
    int256 proposedPrice; // Price that the proposer submitted.
    int256 resolvedPrice; // Price resolved once the request is settled.
    uint256 expirationTime; // Time at which the request auto-settles without a dispute.
    uint256 reward; // Amount of the currency to pay to the proposer on settlement.
    uint256 finalFee; // Final fee to pay to the Store upon request to the DVM.
    uint256 bond; // Bond that the proposer and disputer must pay on top of the final fee.
    uint256 customLiveness; // Custom liveness value set by the requester.
  }

  // This value must be <= the Voting contract's `ancillaryBytesLimit` value otherwise it is possible
  // that a price can be requested to this contract successfully, but cannot be disputed because the DVM refuses
  // to accept a price request made with ancillary data length over a certain size.
  uint256 public constant ancillaryBytesLimit = 8192;

  /**
   * @notice Requests a new price.
   * @param identifier price identifier being requested.
   * @param timestamp timestamp of the price being requested.
   * @param ancillaryData ancillary data representing additional args being passed with the price request.
   * @param currency ERC20 token used for payment of rewards and fees. Must be approved for use with the DVM.
   * @param reward reward offered to a successful proposer. Will be pulled from the caller. Note: this can be 0,
   *               which could make sense if the contract requests and proposes the value in the same call or
   *               provides its own reward system.
   * @return totalBond default bond (final fee) + final fee that the proposer and disputer will be required to pay.
   * This can be changed with a subsequent call to setBond().
   */
  function requestPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    IERC20 currency,
    uint256 reward
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Set the proposal bond associated with a price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param bond custom bond amount to set.
   * @return totalBond new bond + final fee that the proposer and disputer will be required to pay. This can be
   * changed again with a subsequent call to setBond().
   */
  function setBond(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 bond
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Sets the request to refund the reward if the proposal is disputed. This can help to "hedge" the caller
   * in the event of a dispute-caused delay. Note: in the event of a dispute, the winner still receives the other's
   * bond, so there is still profit to be made even if the reward is refunded.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   */
  function setRefundOnDispute(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual;

  /**
   * @notice Sets a custom liveness value for the request. Liveness is the amount of time a proposal must wait before
   * being auto-resolved.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param customLiveness new custom liveness.
   */
  function setCustomLiveness(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    uint256 customLiveness
  ) external virtual;

  /**
   * @notice Proposes a price value on another address' behalf. Note: this address will receive any rewards that come
   * from this proposal. However, any bonds are pulled from the caller.
   * @param proposer address to set as the proposer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePriceFor(
    address proposer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Proposes a price value for an existing price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @param proposedPrice price being proposed.
   * @return totalBond the amount that's pulled from the proposer's wallet as a bond. The bond will be returned to
   * the proposer once settled if the proposal is correct.
   */
  function proposePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData,
    int256 proposedPrice
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price request with an active proposal on another address' behalf. Note: this address will
   * receive any rewards that come from this dispute. However, any bonds are pulled from the caller.
   * @param disputer address to set as the disputer.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the caller's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was value (the proposal was incorrect).
   */
  function disputePriceFor(
    address disputer,
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public virtual returns (uint256 totalBond);

  /**
   * @notice Disputes a price value for an existing price request with an active proposal.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return totalBond the amount that's pulled from the disputer's wallet as a bond. The bond will be returned to
   * the disputer once settled if the dispute was valid (the proposal was incorrect).
   */
  function disputePrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 totalBond);

  /**
   * @notice Retrieves a price that was previously requested by a caller. Reverts if the request is not settled
   * or settleable. Note: this method is not view so that this call may actually settle the price request if it
   * hasn't been settled.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return resolved price.
   */
  function settleAndGetPrice(
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (int256);

  /**
   * @notice Attempts to settle an outstanding price request. Will revert if it isn't settleable.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return payout the amount that the "winner" (proposer or disputer) receives on settlement. This amount includes
   * the returned bonds as well as additional rewards.
   */
  function settle(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) external virtual returns (uint256 payout);

  /**
   * @notice Gets the current data structure containing all information about a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the Request data structure.
   */
  function getRequest(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (Request memory);

  /**
   * @notice Returns the state of a price request.
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return the State enum value.
   */
  function getState(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (State);

  /**
   * @notice Checks if a given request has resolved or been settled (i.e the optimistic oracle has a price).
   * @param requester sender of the initial price request.
   * @param identifier price identifier to identify the existing request.
   * @param timestamp timestamp to identify the existing request.
   * @param ancillaryData ancillary data of the price being requested.
   * @return true if price has resolved or settled, false otherwise.
   */
  function hasPrice(
    address requester,
    bytes32 identifier,
    uint256 timestamp,
    bytes memory ancillaryData
  ) public view virtual returns (bool);

  function stampAncillaryData(bytes memory ancillaryData, address requester)
    public
    view
    virtual
    returns (bytes memory);
}