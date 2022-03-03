// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;

/******************************************************************************\
* Author: Evert Kors <[email protected]> (https://twitter.com/evert0x)
* Sherlock Protocol: https://sherlock.xyz
/******************************************************************************/

import './Manager.sol';
import '../interfaces/managers/ISherlockProtocolManager.sol';

/// @title Sherlock core interface for protocols
/// @author Evert Kors
// This is the contract that manages covered protocols

contract SherlockProtocolManager is ISherlockProtocolManager, Manager {
  using SafeERC20 for IERC20;

  // Represents the token that protocols pay with (currently USDC)
  IERC20 public immutable token;

  // This is the ceiling value that can be set for the threshold (based on USDC balance) at which a protocol can get removed
  uint256 public constant MIN_BALANCE_SANITY_CEILING = 30_000 * 10**6; // 30k usdc

  // A removed protocol is still able to make a claim for this amount of time after its removal
  uint256 public constant PROTOCOL_CLAIM_DEADLINE = 7 days;

  // This is the amount that cannot be withdrawn (measured in seconds of payment) if a protocol wants to remove active balance
  uint256 public constant MIN_SECONDS_LEFT = 7 days;

  // Convenient for percentage calculations
  uint256 internal constant HUNDRED_PERCENT = 10**18;

  // The minimum active "seconds of coverage left" a protocol must have before arbitragers can remove the protocol from coverage
  // This value is calculated from a protocol's active balance divided by the premium per second the protocol is paying
  uint256 public constant MIN_SECONDS_OF_COVERAGE = 12 hours;

  // This is an address that is controlled by a covered protocol (maybe its a multisig used by that protocol, etc.)
  mapping(bytes32 => address) internal protocolAgent_;

  // The percentage of premiums that is NOT sent to stakers (set aside for security experts, reinsurance partners, etc.)
  mapping(bytes32 => uint256) internal nonStakersPercentage;

  // The premium per second paid by each protocol is stored in this mapping
  mapping(bytes32 => uint256) internal premiums_;

  // Each protocol should keep an active balance (in USDC) which is drawn against to pay stakers, nonstakers, etc.
  // This "active balance" is really just an accounting concept, doesn't mean tokens have been transferred or not
  mapping(bytes32 => uint256) internal activeBalances;

  // The timestamp at which Sherlock last ran this internal accounting (on the active balance) for each protocol
  mapping(bytes32 => uint256) internal lastAccountedEachProtocol;

  // The amount that can be claimed by nonstakers for each protocol
  // We need this value so we can track how much payment is coming from each protocol
  mapping(bytes32 => uint256) internal nonStakersClaimableByProtocol;

  // The last time where the global accounting was run (to calc allPremiumsPerSecToStakers below)
  uint256 internal lastAccountedGlobal;

  // This is the total amount of premiums paid (per second) by all the covered protocols (added up)
  uint256 internal allPremiumsPerSecToStakers;

  // This is the amount that was claimable by stakers the last time the accounting was run
  // The claimable amount presumably changes every second so this value is marked "last" because it is usually out-of-date
  uint256 internal lastClaimablePremiumsForStakers;

  // The minimum active balance (measured in USDC) a protocol must keep before arbitragers can remove the protocol from coverage
  // This is one of two criteria a protocol must meet in order to avoid removal (the other is MIN_SECONDS_OF_COVERAGE)
  uint256 public override minActiveBalance;

  // Removed protocols can still make a claim up until this timestamp (will be 10 days or something)
  mapping(bytes32 => uint256) internal removedProtocolClaimDeadline;

  // Mapping to store the protocolAgents for removed protocols (useful for claims made by a removed protocol)
  mapping(bytes32 => address) internal removedProtocolAgent;

  // Current amount of coverage (i.e. 20M USDC) for a protocol
  mapping(bytes32 => uint256) internal currentCoverage;

  // Previous amount of coverage for a protocol
  // Previous is also tracked in case a protocol lowers their coverage amount but still needs to make a claim on the old, higher amount
  mapping(bytes32 => uint256) internal previousCoverage;

  // Setting the token to USDC
  constructor(IERC20 _token) {
    if (address(_token) == address(0)) revert ZeroArgument();
    token = _token;
  }

  // Modifier used to ensure a protocol exists (has been instantiated and not removed)
  modifier protocolExists(bytes32 _protocol) {
    _verifyProtocolExists(_protocol);
    _;
  }

  /// @notice View current protocolAgent of `_protocol`
  /// @param _protocol Protocol identifier
  /// @return Address able to submit claims
  function protocolAgent(bytes32 _protocol) external view override returns (address) {
    address agent = protocolAgent_[_protocol];
    if (agent != address(0)) return agent;

    // If a protocol has been removed but is still within the claim deadline, the protocolAgent is returned
    // Note: Old protocol agent will never be address(0)
    if (block.timestamp <= removedProtocolClaimDeadline[_protocol]) {
      return removedProtocolAgent[_protocol];
    }

    // If a protocol was never instantiated or was removed and the claim deadline has passed, this error is returned
    revert ProtocolNotExists(_protocol);
  }

  // Checks if the protocol exists, then returns the current premium per second being charged
  /// @notice View current premium of protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of premium `_protocol` pays per second
  function premium(bytes32 _protocol)
    external
    view
    override
    protocolExists(_protocol)
    returns (uint256)
  {
    return premiums_[_protocol];
  }

  // Checks to see if a protocol has a protocolAgent assigned to it (we use this to check if a protocol exists)
  // If a protocol has been removed, it will throw an error here no matter what (even if still within claim window)
  function _verifyProtocolExists(bytes32 _protocol) internal view returns (address _protocolAgent) {
    _protocolAgent = protocolAgent_[_protocol];
    if (_protocolAgent == address(0)) revert ProtocolNotExists(_protocol);
  }

  //
  // View methods
  //

  // Calcs the debt accrued by the protocol since it last had an accounting update
  // This is the amount that needs to be removed from a protocol's active balance
  function _calcIncrementalProtocolDebt(bytes32 _protocol) internal view returns (uint256) {
    return (block.timestamp - lastAccountedEachProtocol[_protocol]) * premiums_[_protocol];
  }

  /// @notice View the amount nonstakers can claim from this protocol
  /// @param _protocol Protocol identifier
  /// @return Amount of tokens claimable by nonstakers
  /// @dev this reads from a storage variable + (now-lastsettled) * premiums
  // Note: This function works even for removed protocols because of nonStakersClaimableByProtocol[_protocol]
  // When a protocol gets removed, nonStakersClaimableByProtocol[_protocol] is updated and then doesn't change since the protocol has been removed
  function nonStakersClaimable(bytes32 _protocol) external view override returns (uint256) {
    // Calcs the debt of a protocol since the last accounting update
    uint256 debt = _calcIncrementalProtocolDebt(_protocol);
    // Gets the active balance of the protocol
    uint256 balance = activeBalances[_protocol];
    // The debt should never be higher than the balance (only happens if the arbitrages fail)
    if (debt > balance) debt = balance;

    // Adds the incremental claimable amount owed to nonstakers to the total claimable amount
    return
      nonStakersClaimableByProtocol[_protocol] +
      (nonStakersPercentage[_protocol] * debt) /
      HUNDRED_PERCENT;
  }

  /// @notice View current amount of all premiums that are owed to stakers
  /// @return Premiums claimable
  /// @dev Will increase every block
  /// @dev base + (now - last_settled) * ps
  function claimablePremiums() public view override returns (uint256) {
    // Takes last balance and adds (number of seconds since last accounting update * total premiums per second)
    return
      lastClaimablePremiumsForStakers +
      (block.timestamp - lastAccountedGlobal) *
      allPremiumsPerSecToStakers;
  }

  /// @notice View seconds of coverage left for `_protocol` before it runs out of active balance
  /// @param _protocol Protocol identifier
  /// @return Seconds of coverage left
  function secondsOfCoverageLeft(bytes32 _protocol)
    external
    view
    override
    protocolExists(_protocol)
    returns (uint256)
  {
    return _secondsOfCoverageLeft(_protocol);
  }

  // Helper function to return seconds of coverage left for a protocol
  // Gets the current active balance of the protocol and divides by the premium per second for the protocol
  function _secondsOfCoverageLeft(bytes32 _protocol) internal view returns (uint256) {
    uint256 premium = premiums_[_protocol];
    if (premium == 0) return 0;
    return _activeBalance(_protocol) / premium;
  }

  /// @notice View current active balance of covered protocol
  /// @param _protocol Protocol identifier
  /// @return Active balance
  /// @dev Accrued debt is subtracted from the stored active balance
  function activeBalance(bytes32 _protocol)
    external
    view
    override
    protocolExists(_protocol)
    returns (uint256)
  {
    return _activeBalance(_protocol);
  }

  // Helper function to calc the active balance of a protocol at current time
  function _activeBalance(bytes32 _protocol) internal view returns (uint256) {
    uint256 debt = _calcIncrementalProtocolDebt(_protocol);
    uint256 balance = activeBalances[_protocol];
    // The debt should never be higher than the balance (only happens if the arbitrages fail)
    if (debt > balance) return 0;
    return balance - debt;
  }

  //
  // State methods
  //

  /// @notice Helps set the premium per second for an individual protocol
  /// @param _protocol Protocol identifier
  /// @param _premium New premium per second
  /// @return oldPremiumPerSecond and nonStakerPercentage are returned for gas savings in the calling function
  function _setSingleProtocolPremium(bytes32 _protocol, uint256 _premium)
    internal
    returns (uint256 oldPremiumPerSecond, uint256 nonStakerPercentage)
  {
    // _settleProtocolDebt() subtracts debt from the protocol's active balance and updates the % due to nonstakers
    // Also updates the last accounted timestamp for this protocol
    // nonStakerPercentage is carried over from _settleProtocolDebt() for gas savings
    // nonStakerPercentage represents the percentage that goes to nonstakers for this protocol
    nonStakerPercentage = _settleProtocolDebt(_protocol);
    // Stores the old premium before it gets updated
    oldPremiumPerSecond = premiums_[_protocol];

    if (oldPremiumPerSecond != _premium) {
      // Sets the protocol's premium per second to the new value
      premiums_[_protocol] = _premium;
      emit ProtocolPremiumChanged(_protocol, oldPremiumPerSecond, _premium);
    }
    // We check if the NEW premium causes the _secondsOfCoverageLeft for the protocol to be less than the threshold for arbing
    // We don't need to check the min balance requirement for arbs because that value doesn't change like secondsOfCoverageLeft changes
    // Effectively we just need to make sure we don't accidentally run a protocol's active balance down below the point
    // Where arbs would no longer be incentivized to remove the protocol
    // Because if a protocol is not removed by arbs before running out of active balance, this can cause problems
    if (_premium != 0 && _secondsOfCoverageLeft(_protocol) < MIN_SECONDS_OF_COVERAGE) {
      revert InsufficientBalance(_protocol);
    }
  }

  /// @notice Sets a single protocol's premium per second and also updates the global total of premiums per second
  /// @param _protocol Protocol identifier
  /// @param _premium New premium per second
  function _setSingleAndGlobalProtocolPremium(bytes32 _protocol, uint256 _premium) internal {
    // Sets the individual protocol's premium and returns oldPremiumPerSecond and nonStakerPercentage for gas savings
    (uint256 oldPremiumPerSecond, uint256 nonStakerPercentage) = _setSingleProtocolPremium(
      _protocol,
      _premium
    );
    // Settling the total amount of premiums owed to stakers before a new premium per second gets set
    _settleTotalDebt();
    // This calculates the new global premium per second that gets paid to stakers
    // We input the same nonStakerPercentage twice because we simply aren't updating that value in this function
    allPremiumsPerSecToStakers = _calcGlobalPremiumPerSecForStakers(
      oldPremiumPerSecond,
      _premium,
      nonStakerPercentage,
      nonStakerPercentage,
      allPremiumsPerSecToStakers
    );
  }

  // Internal function to set a new protocolAgent for a specific protocol
  // _oldAgent is only included as part of emitting an event
  function _setProtocolAgent(
    bytes32 _protocol,
    address _oldAgent,
    address _protocolAgent
  ) internal {
    protocolAgent_[_protocol] = _protocolAgent;
    emit ProtocolAgentTransfer(_protocol, _oldAgent, _protocolAgent);
  }

  // Subtracts the accrued debt from a protocol's active balance
  // Credits the amount that can be claimed by nonstakers for this protocol
  // Takes the protocol ID as a param and returns the nonStakerPercentage for gas savings
  // Most of this function is dealing with an edge case related to a protocol not being removed by arbs
  function _settleProtocolDebt(bytes32 _protocol) internal returns (uint256 _nonStakerPercentage) {
    // This calcs the accrued debt of the protocol since it was last updated
    uint256 debt = _calcIncrementalProtocolDebt(_protocol);
    // This pulls the percentage that is sent to nonstakers
    _nonStakerPercentage = nonStakersPercentage[_protocol];
    // In case the protocol has accrued debt, this code block will ensure the debt is settled properly
    if (debt != 0) {
      // Pulls the stored active balance of the protocol
      uint256 balance = activeBalances[_protocol];
      // This is the start of handling an edge case where arbitragers don't remove this protocol before debt becomes greater than active balance
      // Economically speaking, this point should never be reached as arbs will get rewarded for removing the protocol before this point
      // The arb would use forceRemoveByActiveBalance and forceRemoveBySecondsOfCoverage
      // However, if arbs don't come in, the premium for this protocol should be set to 0 asap otherwise accounting for stakers/nonstakers gets messed up
      if (debt > balance) {
        // This error amount represents the magnitude of the mistake
        uint256 error = debt - balance;
        // Gets the latest value of claimable premiums for stakers
        _settleTotalDebt();
        // @note to production, set premium first to zero before solving accounting issue.
        // otherwise the accounting error keeps increasing
        uint256 lastClaimablePremiumsForStakers_ = lastClaimablePremiumsForStakers;

        // Figures out the amount due to stakers by subtracting the nonstaker percentage from 100%
        uint256 claimablePremiumError = ((HUNDRED_PERCENT - _nonStakerPercentage) * error) /
          HUNDRED_PERCENT;

        // This insufficient tokens var is simply how we know (emitted as an event) how many tokens the protocol is short
        uint256 insufficientTokens;

        // The idea here is that lastClaimablePremiumsForStakers has gotten too big accidentally
        // We need to decrease the balance of lastClaimablePremiumsForStakers by the amount that was added in error
        // This first line can be true if claimPremiumsForStakers() has been called and
        // lastClaimablePremiumsForStakers would be 0 but a faulty protocol could cause claimablePremiumError to be >0 still
        if (claimablePremiumError > lastClaimablePremiumsForStakers_) {
          insufficientTokens = claimablePremiumError - lastClaimablePremiumsForStakers_;
          lastClaimablePremiumsForStakers = 0;
        } else {
          // If the error is not bigger than the claimable premiums, then we just decrease claimable premiums
          // By the amount that was added in error (error) and insufficientTokens = 0
          lastClaimablePremiumsForStakers =
            lastClaimablePremiumsForStakers_ -
            claimablePremiumError;
        }

        // If two events are thrown, the values need to be summed up for the actual state.
        // This means an error of this type will continue until it is handled
        emit AccountingError(_protocol, claimablePremiumError, insufficientTokens);
        // We set the debt equal to the balance, and in the next line we effectively set the protocol's active balance to 0 in this case
        debt = balance;
      }
      // Subtracts the accrued debt (since last update) from the protocol's active balance and updates active balance
      activeBalances[_protocol] = balance - debt;
      // Adds the requisite amount of the debt to the balance claimable by nonstakers for this protocol
      nonStakersClaimableByProtocol[_protocol] += (_nonStakerPercentage * debt) / HUNDRED_PERCENT;
    }
    // Updates the last accounted timestamp for this protocol
    lastAccountedEachProtocol[_protocol] = block.timestamp;
  }

  // Multiplies the total premium per second * number of seconds since the last global accounting update
  // And adds it to the total claimable amount for stakers
  function _settleTotalDebt() internal {
    lastClaimablePremiumsForStakers +=
      (block.timestamp - lastAccountedGlobal) *
      allPremiumsPerSecToStakers;
    lastAccountedGlobal = block.timestamp;
  }

  // Calculates the global premium per second for stakers
  // Takes a specific protocol's old and new values for premium per second and nonstaker percentage and the old global premium per second to stakers
  // Subtracts out the old values of a protocol's premium per second and nonstaker percentage and adds the new ones
  function _calcGlobalPremiumPerSecForStakers(
    uint256 _premiumOld,
    uint256 _premiumNew,
    uint256 _nonStakerPercentageOld,
    uint256 _nonStakerPercentageNew,
    uint256 _inMemAllPremiumsPerSecToStakers
  ) internal pure returns (uint256) {
    return
      _inMemAllPremiumsPerSecToStakers +
      ((HUNDRED_PERCENT - _nonStakerPercentageNew) * _premiumNew) /
      HUNDRED_PERCENT -
      ((HUNDRED_PERCENT - _nonStakerPercentageOld) * _premiumOld) /
      HUNDRED_PERCENT;
  }

  // Helper function to remove and clean up a protocol from Sherlock
  // Params are the protocol ID and the protocol agent to which funds should be sent and from which post-removal claims can be made
  function _forceRemoveProtocol(bytes32 _protocol, address _agent) internal {
    // Sets the individual protocol's premium to zero and updates the global premium variable for a zero premium at this protocol
    _setSingleAndGlobalProtocolPremium(_protocol, 0);

    // Grabs the protocol's active balance
    uint256 balance = activeBalances[_protocol];

    // If there's still some active balance, delete the entry and send the remaining balance to the protocol agent
    if (balance != 0) {
      delete activeBalances[_protocol];
      token.safeTransfer(_agent, balance);

      emit ProtocolBalanceWithdrawn(_protocol, balance);
    }

    // Sets the protocol agent to zero address (as part of clean up)
    _setProtocolAgent(_protocol, _agent, address(0));

    // Cleans up other mappings for this protocol
    delete nonStakersPercentage[_protocol];
    delete lastAccountedEachProtocol[_protocol];
    // `premiums_` mapping is not deleted here as it's already 0 because of the `_setSingleAndGlobalProtocolPremium` call above

    // Sets a deadline in the future until which this protocol agent can still make claims for this removed protocol
    removedProtocolClaimDeadline[_protocol] = block.timestamp + PROTOCOL_CLAIM_DEADLINE;

    // This mapping allows Sherlock to verify the protocol agent making a claim after the protocol has been removed
    // Remember, only the protocol agent can make claims on behalf of the protocol, so this must be checked
    removedProtocolAgent[_protocol] = _agent;

    emit ProtocolUpdated(_protocol, bytes32(0), uint256(0), uint256(0));
    emit ProtocolRemoved(_protocol);
  }

  /// @notice Sets the minimum active balance before an arb can remove a protocol
  /// @param _minActiveBalance Minimum balance needed (in USDC)
  /// @dev Only gov
  /// @dev This call should be subject to a timelock
  function setMinActiveBalance(uint256 _minActiveBalance) external override onlyOwner {
    // New value cannot be the same as current value
    if (minActiveBalance == _minActiveBalance) revert InvalidArgument();
    // Can't set a value that is too high to be reasonable
    if (_minActiveBalance >= MIN_BALANCE_SANITY_CEILING) revert InvalidConditions();

    emit MinBalance(minActiveBalance, _minActiveBalance);
    minActiveBalance = _minActiveBalance;
  }

  // This function allows the nonstakers role to claim tokens owed to them by a specific protocol
  /// @notice Choose an `_amount` of tokens that nonstakers (`_receiver` address) will receive from `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens
  /// @param _receiver Address to receive tokens
  /// @dev Only callable by nonstakers role
  function nonStakersClaim(
    bytes32 _protocol,
    uint256 _amount,
    address _receiver
  ) external override whenNotPaused {
    if (_protocol == bytes32(0)) revert ZeroArgument();
    if (_amount == uint256(0)) revert ZeroArgument();
    if (_receiver == address(0)) revert ZeroArgument();
    // Only the nonstakers role (multisig or contract) can pull the funds
    if (msg.sender != sherlockCore.nonStakersAddress()) revert Unauthorized();

    // Call can't be executed on protocol that is removed
    if (protocolAgent_[_protocol] != address(0)) {
      // Updates the amount that nonstakers can claim from this protocol
      _settleProtocolDebt(_protocol);
    }

    // Sets balance to the amount that is claimable by nonstakers for this specific protocol
    uint256 balance = nonStakersClaimableByProtocol[_protocol];
    // If the amount requested is more than what's owed to nonstakers, revert
    if (_amount > balance) revert InsufficientBalance(_protocol);

    // Sets the claimable amount to whatever is left over after this amount is pulled
    nonStakersClaimableByProtocol[_protocol] = balance - _amount;
    // Transfers the amount requested to the `_receiver` address
    token.safeTransfer(_receiver, _amount);
  }

  // Transfers funds owed to stakers from this contract to the Sherlock core contract (where we handle paying out stakers)
  /// @notice Transfer current claimable premiums (for stakers) to core Sherlock address
  /// @dev Callable by everyone
  /// @dev Funds will be transferred to Sherlock core contract
  function claimPremiumsForStakers() external override whenNotPaused {
    // Gets address of core Sherlock contract
    address sherlock = address(sherlockCore);
    // Revert if core Sherlock contract not initialized yet
    if (sherlock == address(0)) revert InvalidConditions();

    // claimablePremiums is different from _settleTotalDebt() because it does not change state
    // Retrieves current amount of all premiums that are owed to stakers
    uint256 amount = claimablePremiums();

    // Transfers all the premiums owed to stakers to the Sherlock core contract
    if (amount != 0) {
      // Global value of premiums owed to stakers is set to zero since we are transferring the entire amount out
      lastClaimablePremiumsForStakers = 0;
      lastAccountedGlobal = block.timestamp;
      token.safeTransfer(sherlock, amount);
    }
  }

  // Function is used in the SherlockClaimManager contract to decide if a proposed claim falls under either the current or previous coverage amounts
  /// @param _protocol Protocol identifier
  /// @return current and previous are the current and previous coverage amounts for this protocol
  // Note For this process to work, a protocol's coverage amount should not be set more than once in the span of claim delay period (7 days or something)
  function coverageAmounts(bytes32 _protocol)
    external
    view
    override
    returns (uint256 current, uint256 previous)
  {
    // Checks to see if the protocol has an active protocolAgent (protocol not removed)
    // OR checks to see if the removed protocol is still within the claim window
    // If so, gives the current and previous coverage, otherwise throws an error
    if (
      protocolAgent_[_protocol] != address(0) ||
      block.timestamp <= removedProtocolClaimDeadline[_protocol]
    ) {
      return (currentCoverage[_protocol], previousCoverage[_protocol]);
    }

    revert ProtocolNotExists(_protocol);
  }

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
  ) external override onlyOwner {
    if (_protocol == bytes32(0)) revert ZeroArgument();
    if (_protocolAgent == address(0)) revert ZeroArgument();
    // Checks to make sure the protocol doesn't exist already
    if (protocolAgent_[_protocol] != address(0)) revert InvalidConditions();

    // Updates the protocol agent and passes in the old agent which is 0 address in this case
    _setProtocolAgent(_protocol, address(0), _protocolAgent);

    // Delete mappings that are potentially non default values
    // From previous time protocol was added/removed
    delete removedProtocolClaimDeadline[_protocol];
    delete removedProtocolAgent[_protocol];
    delete currentCoverage[_protocol];
    delete previousCoverage[_protocol];

    emit ProtocolAdded(_protocol);

    // Most of the logic for actually adding a protocol in this function
    protocolUpdate(_protocol, _coverage, _nonStakers, _coverageAmount);
  }

  /// @notice Update info regarding a protocol
  /// @param _protocol Protocol identifier
  /// @param _coverage Hash referencing the active coverage agreement
  /// @param _nonStakers Percentage of premium payments to nonstakers, scaled by 10**18
  /// @param _coverageAmount Max amount claimable by this protocol
  /// @dev Only callable by governance
  /// @dev `_nonStakers` can be 0
  function protocolUpdate(
    bytes32 _protocol,
    bytes32 _coverage,
    uint256 _nonStakers,
    uint256 _coverageAmount
  ) public override onlyOwner {
    if (_coverage == bytes32(0)) revert ZeroArgument();
    if (_nonStakers > HUNDRED_PERCENT) revert InvalidArgument();
    if (_coverageAmount == uint256(0)) revert ZeroArgument();

    // Checks to make sure the protocol has been assigned a protocol agent
    _verifyProtocolExists(_protocol);

    // Subtracts the accrued debt from a protocol's active balance (if any)
    // Updates the amount that can be claimed by nonstakers
    _settleProtocolDebt(_protocol);

    // Updates the global claimable amount for stakers
    _settleTotalDebt();

    // Gets the premium per second for this protocol
    uint256 premium = premiums_[_protocol];

    // Updates allPremiumsPerSecToStakers (premium is not able to be updated in this function, but percentage to nonstakers can be)
    allPremiumsPerSecToStakers = _calcGlobalPremiumPerSecForStakers(
      premium,
      premium,
      nonStakersPercentage[_protocol],
      _nonStakers,
      allPremiumsPerSecToStakers
    );

    // Updates the stored value of percentage of premiums that go to nonstakers
    nonStakersPercentage[_protocol] = _nonStakers;

    // Updates previous coverage and current coverage amounts
    previousCoverage[_protocol] = currentCoverage[_protocol];
    currentCoverage[_protocol] = _coverageAmount;

    emit ProtocolUpdated(_protocol, _coverage, _nonStakers, _coverageAmount);
  }

  /// @notice Remove a protocol from coverage
  /// @param _protocol Protocol identifier
  /// @dev Before removing a protocol the premium must be 0
  /// @dev Removing a protocol basically stops the `_protocolAgent` from being active (can still submit claims until claim deadline though)
  /// @dev Pays off debt + sends remaining balance to protocol agent
  /// @dev This call should be subject to a timelock
  /// @dev Only callable by governance
  function protocolRemove(bytes32 _protocol) external override onlyOwner {
    // checks to make sure the protocol actually has a protocol agent
    address agent = _verifyProtocolExists(_protocol);

    // Removes a protocol from Sherlock and cleans up its data
    // Params are the protocol ID and the protocol agent to which remaining active balance should be sent and from which post-removal claims can be made
    _forceRemoveProtocol(_protocol, agent);
  }

  /// @notice Remove a protocol with insufficient active balance
  /// @param _protocol Protocol identifier
  // msg.sender receives whatever is left of the insufficient active balance, this should incentivize arbs to call this function
  /// @dev This call should be subject to a timelock
  function forceRemoveByActiveBalance(bytes32 _protocol) external override whenNotPaused {
    address agent = _verifyProtocolExists(_protocol);

    // Gets the latest value of the active balance at this protocol
    _settleProtocolDebt(_protocol);
    // Sets latest value of active balance to remainingBalance variable
    uint256 remainingBalance = activeBalances[_protocol];

    // This means the protocol still has adequate active balance and thus cannot be removed
    if (remainingBalance >= minActiveBalance) revert InvalidConditions();

    // Sets the protocol's active balance to 0
    delete activeBalances[_protocol];
    // Removes the protocol from coverage
    _forceRemoveProtocol(_protocol, agent);

    if (remainingBalance != 0) {
      // sends the remaining balance to msg.sender
      token.safeTransfer(msg.sender, remainingBalance);
    }
    emit ProtocolRemovedByArb(_protocol, msg.sender, remainingBalance);
  }

  /// @notice Calculate if arb is possible and what the reward would be
  /// @param _protocol Protocol identifier
  /// @return arbAmount Amount reward for arbing
  /// @return able Indicator if arb call is even possible
  /// @dev Doesn't subtract the current protocol debt from the active balance
  function _calcForceRemoveBySecondsOfCoverage(bytes32 _protocol)
    internal
    view
    returns (uint256 arbAmount, bool able)
  {
    uint256 secondsLeft = _secondsOfCoverageLeft(_protocol);

    // If arb is not possible return false
    if (secondsLeft >= MIN_SECONDS_OF_COVERAGE) return (0, false);

    // This percentage scales over time
    // Reaches 100% on 0 seconds of coverage left
    uint256 percentageScaled = HUNDRED_PERCENT -
      (secondsLeft * HUNDRED_PERCENT) /
      MIN_SECONDS_OF_COVERAGE;

    able = true;
    arbAmount = (activeBalances[_protocol] * percentageScaled) / HUNDRED_PERCENT;
  }

  /// @notice Removes a protocol with insufficent seconds of coverage left
  /// @param _protocol Protocol identifier
  // Seconds of coverage is defined by the active balance of the protocol divided by the protocol's premium per second
  function forceRemoveBySecondsOfCoverage(bytes32 _protocol) external override whenNotPaused {
    // NOTE: We use _secondsOfCoverageLeft() below and include this check instead of secondsOfCoverageLeft() for gas savings
    address agent = _verifyProtocolExists(_protocol);

    // NOTE: We don't give the arb the full remaining balance like we do in forceRemoveByActiveBalance()
    // This is because we know the exact balance the arb will get in forceRemoveByActiveBalance()
    // But when removing based on seconds of coverage left, the remainingBalance could still be quite large
    // So it's better to scale the arb reward over time. It's a little complex because the remainingBalance
    // Decreases over time also but reward will be highest at the midpoint of percentageScaled (50%)
    _settleProtocolDebt(_protocol);
    (uint256 arbAmount, bool able) = _calcForceRemoveBySecondsOfCoverage(_protocol);
    if (able == false) revert InvalidConditions();

    if (arbAmount != 0) {
      // subtracts the amount that will be paid to the arb from the active balance
      activeBalances[_protocol] -= arbAmount;
    }

    // Removes the protocol from coverage
    // This function also pays the active balance to the protocol agent, so it's good we do this after subtracting arb amount above
    _forceRemoveProtocol(_protocol, agent);

    // Done after removing protocol to mitigate reentrency pattern
    // (In case token allows callback)
    if (arbAmount != 0) {
      token.safeTransfer(msg.sender, arbAmount);
    }
    emit ProtocolRemovedByArb(_protocol, msg.sender, arbAmount);
  }

  /// @notice Set premium of `_protocol` to `_premium`
  /// @param _protocol Protocol identifier
  /// @param _premium Amount of premium `_protocol` pays per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremium(bytes32 _protocol, uint256 _premium) external override onlyOwner {
    // Checks to see if protocol has a protocol agent
    _verifyProtocolExists(_protocol);

    // Updates individual protocol's premium and allPremiumsPerSecToStakers
    _setSingleAndGlobalProtocolPremium(_protocol, _premium);
  }

  /// @notice Set premium of multiple protocols
  /// @param _protocol Array of protocol identifiers
  /// @param _premium Array of premium amounts protocols pay per second
  /// @dev The value 0 would mean inactive coverage
  /// @dev Only callable by governance
  function setProtocolPremiums(bytes32[] calldata _protocol, uint256[] calldata _premium)
    external
    override
    onlyOwner
  {
    // Checks to make sure there are an equal amount of entries in each array
    if (_protocol.length != _premium.length) revert UnequalArrayLength();
    if (_protocol.length == 0) revert InvalidArgument();

    // Updates the global claimable amount for stakers
    _settleTotalDebt();

    uint256 allPremiumsPerSecToStakers_ = allPremiumsPerSecToStakers;

    // Loops through the array of protocols and checks to make sure each has a protocol agent assigned
    for (uint256 i; i < _protocol.length; i++) {
      _verifyProtocolExists(_protocol[i]);

      // Sets the protocol premium for that specific protocol
      // Function returns the old premium and nonStakerPercentage for that specific protocol
      (uint256 oldPremiumPerSecond, uint256 nonStakerPercentage) = _setSingleProtocolPremium(
        _protocol[i],
        _premium[i]
      );

      // Calculates the new global premium which adds up all premiums paid by all protocols
      allPremiumsPerSecToStakers_ = _calcGlobalPremiumPerSecForStakers(
        oldPremiumPerSecond,
        _premium[i],
        nonStakerPercentage,
        nonStakerPercentage,
        allPremiumsPerSecToStakers_
      );
    }

    // After the loop has finished, sets allPremiumsPerSecToStakers to the final temp value
    allPremiumsPerSecToStakers = allPremiumsPerSecToStakers_;
  }

  // This is how protocols pay for coverage by increasing their active balance
  /// @notice Deposits `_amount` of token to the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to deposit
  /// @dev Approval should be made before calling
  function depositToActiveBalance(bytes32 _protocol, uint256 _amount)
    external
    override
    whenNotPaused
  {
    if (_amount == uint256(0)) revert ZeroArgument();
    _verifyProtocolExists(_protocol);

    // Transfers _amount to this contract
    token.safeTransferFrom(msg.sender, address(this), _amount);
    // Increases the active balance of the protocol by _amount
    activeBalances[_protocol] += _amount;

    emit ProtocolBalanceDeposited(_protocol, _amount);
  }

  // If a protocol has paid too much into the active balance (which is how a protocol pays the premium)
  // Then the protocol can remove some of the active balance (up until there is 7 days worth of balance left)
  /// @notice Withdraws `_amount` of token from the active balance of `_protocol`
  /// @param _protocol Protocol identifier
  /// @param _amount Amount of tokens to withdraw
  /// @dev Only protocol agent is able to withdraw
  /// @dev Balance can be withdrawn up until 7 days worth of active balance
  function withdrawActiveBalance(bytes32 _protocol, uint256 _amount)
    external
    override
    whenNotPaused
  {
    if (_amount == uint256(0)) revert ZeroArgument();
    // Only the protocol agent can call this function
    if (msg.sender != _verifyProtocolExists(_protocol)) revert Unauthorized();

    // Updates the active balance of the protocol
    _settleProtocolDebt(_protocol);

    // Sets currentBalance to the active balance of the protocol
    uint256 currentBalance = activeBalances[_protocol];
    // Reverts if trying to withdraw more than the active balance
    if (_amount > currentBalance) revert InsufficientBalance(_protocol);

    // Removes the _amount to be withdrawn from the active balance
    activeBalances[_protocol] = currentBalance - _amount;
    // Reverts if a protocol has less than 7 days worth of active balance left
    if (_secondsOfCoverageLeft(_protocol) < MIN_SECONDS_LEFT) revert InsufficientBalance(_protocol);

    // Transfers the amount to the msg.sender (protocol agent)
    token.safeTransfer(msg.sender, _amount);
    emit ProtocolBalanceWithdrawn(_protocol, _amount);
  }

  /// @notice Transfer protocol agent role
  /// @param _protocol Protocol identifier
  /// @param _protocolAgent Account able to submit a claim on behalf of the protocol
  /// @dev Only the active protocolAgent is able to transfer the role
  function transferProtocolAgent(bytes32 _protocol, address _protocolAgent)
    external
    override
    whenNotPaused
  {
    if (_protocolAgent == address(0)) revert ZeroArgument();
    // Can't set the new protocol agent to the caller address
    if (msg.sender == _protocolAgent) revert InvalidArgument();
    // Because the caller must be the current protocol agent
    if (msg.sender != _verifyProtocolExists(_protocol)) revert Unauthorized();

    // Sets the protocol agent to the new address
    _setProtocolAgent(_protocol, msg.sender, _protocolAgent);
  }

  /// @notice Function used to check if this is the current active protocol manager
  /// @return Boolean indicating it's active
  /// @dev If inactive the owner can pull all ERC20s and ETH
  /// @dev Will be checked by calling the sherlock contract
  function isActive() public view returns (bool) {
    return address(sherlockCore.sherlockProtocolManager()) == address(this);
  }

  // Only contract owner can call this
  // Sends all specified tokens in this contract to the receiver's address (as well as ETH)
  function sweep(address _receiver, IERC20[] memory _extraTokens) external onlyOwner {
    if (_receiver == address(0)) revert ZeroArgument();
    // This contract must NOT be the current assigned protocol manager contract
    if (isActive()) revert InvalidConditions();
    // Executes the sweep for ERC-20s specified in _extraTokens as well as for ETH
    _sweep(_receiver, _extraTokens);
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