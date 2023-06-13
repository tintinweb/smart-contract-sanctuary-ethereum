// SPDX-License-Identifier: GPL-3.0

import { GovernancePool } from "src/module/governance-pool/GovernancePool.sol";
import { Motivator } from "src/incentives/Motivator.sol";
import {
  ModuleConfig,
  SLOT_INDEX_TOKEN_BALANCE,
  SLOT_INDEX_DELEGATE
} from "src/module/governance-pool/ModuleConfig.sol";
import { Wallet } from "src/wallet/Wallet.sol";
import { Validator } from "src/module/governance-pool/FactValidator.sol";
import { IReliquary } from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import { IDelegationRegistry } from "delegate-cash/IDelegationRegistry.sol";
import { IBatchProver } from "relic-sdk/packages/contracts/interfaces/IBatchProver.sol";
import { Fact, FactSignature } from "relic-sdk/packages/contracts/lib/Facts.sol";
import { Storage } from "relic-sdk/packages/contracts/lib/Storage.sol";
import { FactSigs } from "relic-sdk/packages/contracts/lib/FactSigs.sol";
import { PausableUpgradeable } from "openzeppelin-upgradeable/security/PausableUpgradeable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { NounsDAOStorageV2 } from "nouns-contracts/governance/NounsDAOInterfaces.sol";

pragma solidity ^0.8.19;

/// Wrapper for NounsDAOStorageV2 functionality
interface NounsGovernanceV2 {
  function castRefundableVoteWithReason(uint256, uint8, string calldata) external;
  function proposals(uint256) external view returns (NounsDAOStorageV2.ProposalCondensed memory);
  function state(uint256) external view returns (uint256);
}

/// Wrapper for Nouns token governance functionality
interface NounsToken {
  function getPriorVotes(address, uint256) external view returns (uint96);
}

// This module auctions off the collective voting power delegated to the highest
// bidder. Delegators can withdraw proceeds in proportion to their share of the
// pool for each prop once a vote has been cast and the voting period ends.
contract NounsPool is PausableUpgradeable, Motivator, GovernancePool, ModuleConfig {
  /// The name of this contract
  string public constant name = "Federation Nouns Governance Pool v0.1";

  /// The maximum uint256 value. Necessary to track this for overflow reasons
  /// fee switch as bps
  uint256 internal constant MAX_INT = type(uint256).max;

  /// The active bid on each proposal
  mapping(uint256 => Bid) internal bids;

  /// The delegators that have withdrawn proceeds from a bid
  mapping(uint256 => mapping(address => bool)) internal withdrawals;

  /// Do not leave implementation uninitialized
  constructor() {
    _disableInitializers();
  }

  /// Module initialization; Can only be called once
  function init(bytes calldata _data) external payable initializer {
    __Ownable_init();
    __Pausable_init();

    _cfg = _validateConfig(abi.decode(_data, (Config)));

    balanceSlotIdx = SLOT_INDEX_TOKEN_BALANCE;
    delegateSlotIdx = SLOT_INDEX_DELEGATE;

    if (msg.sender != _cfg.base) {
      _transferOwnership(_cfg.base);
    }
  }

  /// Submit a bid for a proposal vote
  function bid(uint256 _pId, uint256 _support) external payable {
    if (_support > 2) {
      revert BidInvalidSupport();
    }

    if (msg.value < _cfg.reservePrice) {
      revert BidReserveNotMet();
    }

    // we calc fee shares using bps; we need to ensure that
    // the bid amount can never overflow any of our math calcs
    if (msg.value >= MAX_INT / 10000) {
      revert BidMaxBidExceeded();
    }

    // only allow bidding on a prop if voting is active
    if (!_active(_pId)) {
      revert BidProposalNotActive();
    }

    Bid storage b = bids[_pId];
    if (b.executed) {
      revert BidVoteAlreadyCast();
    }

    address lastBidder = b.bidder;
    uint256 lastAmount = b.amount;
    if (msg.value < this.minBidAmount(_pId)) {
      revert BidTooLow();
    }

    // prevent a new auction from starting if the module is paused
    if (paused() && lastAmount == 0) {
      revert BidModulePaused();
    }

    // if we are in the cast window and have a winning bid, the auction has ended and the
    // vote can be cast. auctions are not extended so that we can always guarantee a vote
    // is cast before the external proposal voting period ends
    if (block.number + _cfg.castWindow > b.endBlock) {
      if (lastAmount >= _cfg.reservePrice) {
        revert BidAuctionEnded();
      }
    }

    b.amount = msg.value;
    b.bidder = msg.sender;
    b.support = _support;
    b.bidBlock = block.number;
    b.remainingAmount = b.amount;

    NounsDAOStorageV2.ProposalCondensed memory eProp =
      NounsGovernanceV2(_cfg.externalDAO).proposals(_pId);
    b.creationBlock = eProp.creationBlock;
    b.startBlock = eProp.startBlock;
    b.endBlock = eProp.endBlock;

    // request base lock so that this module cannot be disabled while a bid is active
    // requestLock works on a rolling basis so this module will always be allowed
    // to cast votes if it has an active bid
    Wallet(_cfg.base).requestLock((b.endBlock + 1) - block.number);

    // refund any previous bid on this prop
    if (lastBidder != address(0)) {
      SafeTransferLib.forceSafeTransferETH(lastBidder, lastAmount);
    }

    emit BidPlaced(_cfg.externalDAO, _pId, _support, b.amount, msg.sender);
  }

  /// Refunds a bid if a proposal is canceled, vetoed, or votes could not be cast
  function claimRefund(uint256 _pId) external {
    Bid storage b = bids[_pId];

    if (msg.sender != b.bidder) {
      revert ClaimOnlyBidder();
    }

    if (b.refunded) {
      revert ClaimAlreadyRefunded();
    }

    if (_refundable(_pId, b.executed)) {
      b.refunded = true;
      SafeTransferLib.forceSafeTransferETH(b.bidder, b.remainingAmount);
      emit RefundClaimed(_cfg.externalDAO, _pId, b.remainingAmount, msg.sender);
      return;
    }

    revert ClaimNotRefundable();
  }

  /// Casts a vote on an external proposal. A tip is awarded to the caller
  function castVote(uint256 _pId) external {
    Bid storage b = bids[_pId];
    if (b.amount == 0) {
      revert CastVoteBidDoesNotExist();
    }

    if (block.number + _cfg.castWindow < b.endBlock) {
      revert CastVoteNotInWindow();
    }

    // no atomic bid / casts
    if (block.number < b.bidBlock + _cfg.castWaitBlocks) {
      revert CastVoteMustWait();
    }

    if (b.executed) {
      revert CastVoteAlreadyCast();
    }

    b.executed = true;
    b.remainingVotes =
      NounsToken(_cfg.externalToken).getPriorVotes(_cfg.base, _voteSnapshotBlock(b, _pId));

    if (b.remainingVotes == 0) {
      revert CastVoteNoDelegations();
    }

    // cast vwr through base wallet, Nouns refunds gas
    bytes4 s = NounsGovernanceV2.castRefundableVoteWithReason.selector;
    bytes memory callData = abi.encodeWithSelector(s, _pId, uint8(b.support), _cfg.reason);
    Wallet(_cfg.base).execute(_cfg.externalDAO, 0, callData);

    // base tx refund covers validation checks performed in this fn before
    // votes were cast
    uint256 startGas = gasleft();
    emit VoteCast(_cfg.externalDAO, _pId, b.support, b.amount, b.bidder);

    // protocol fee switch
    uint256 fee;
    if (_cfg.feeBPS > 0) {
      fee = _bpsToUint(_cfg.feeBPS, b.amount);
      b.remainingAmount -= fee;
    }

    // deduct gas refund and tip from bid proceeds to incentivize casting of a vote
    // cap refund + tip by the bid amount so that we can never refund more than the
    // highest bid - any fees applied
    uint256 refund =
      _gasRefundWithTipAndCap(startGas, b.remainingAmount, _cfg.maxBaseFeeRefund, _cfg.tip);

    b.remainingAmount -= refund;

    if (fee > 0) {
      SafeTransferLib.forceSafeTransferETH(_cfg.feeRecipient, fee);
      emit ProtocolFeeApplied(_cfg.feeRecipient, fee);
    }

    SafeTransferLib.forceSafeTransferETH(tx.origin, refund);
    emit GasRefundWithTip(tx.origin, refund, _cfg.tip);
  }

  /// Withdraw proceeds from a proposal in proportion to voting weight delegated
  function withdraw(
    address _tokenOwner,
    address _prover,
    uint256[] calldata _pIds,
    uint256[] calldata _fee,
    bytes[] calldata _proofBatches
  ) external payable returns (uint256) {
    // verify prover version is a valid relic contract
    IReliquary reliq = IReliquary(_cfg.reliquary);
    IReliquary.ProverInfo memory p = reliq.provers(_prover);
    reliq.checkProver(p);
    if (_cfg.maxProverVersion != 0) {
      if (p.version > _cfg.maxProverVersion) {
        revert WithdrawMaxProverVersion();
      }
    }

    // to withdraw, sender must have permission set in the delegate cash registry
    // or they must be the owner of the Nouns delegated to the base wallet
    if (msg.sender != _tokenOwner) {
      IDelegationRegistry dr = IDelegationRegistry(_cfg.dcash);
      bool isDelegate = dr.checkDelegateForContract(msg.sender, _tokenOwner, address(this));
      if (!isDelegate) {
        revert WithdrawDelegateOrOwnerOnly();
      }
    }

    // calc the slot for the balance and delegate of the token owner to ensure that
    // proofs cannot be spoofed
    bytes32 balanceSlot = Storage.mapElemSlot(balanceSlotIdx, _addressToBytes32(_tokenOwner));

    bytes32 delegateSlot = Storage.mapElemSlot(delegateSlotIdx, _addressToBytes32(_tokenOwner));

    // how many props to loop over
    uint256 len = _pIds.length;

    // keep track of total amount to withdraw
    uint256 withdrawAmount;

    for (uint256 i = 0; i < len;) {
      Bid storage b = bids[_pIds[i]];
      if (b.amount == 0) {
        revert WithdrawBidNotOffered();
      }

      if (_refundable(_pIds[i], b.executed)) {
        revert WithdrawBidRefunded();
      }

      if (!b.executed) {
        revert WithdrawVoteNotCast();
      }

      if (withdrawals[_pIds[i]][_tokenOwner]) {
        revert WithdrawAlreadyClaimed();
      }

      // only allow withdrawals after the voting period has ended
      if (_active(_pIds[i])) {
        revert WithdrawPropIsActive();
      }

      // prevent multiple withdrawals from the same user on this prop
      withdrawals[_pIds[i]][_tokenOwner] = true;

      // validate that proofs are correctly formatted (for the correct slot, block, and token address)
      Fact[] memory facts =
        IBatchProver(_prover).proveBatch{ value: _fee[i] }(_proofBatches[i], false);

      Validator v = Validator(_cfg.factValidator);
      if (!v.validate(facts[0], balanceSlot, _voteSnapshotBlock(b, _pIds[i]), _cfg.externalToken)) {
        revert WithdrawInvalidProof("balanceOf");
      }

      if (!v.validate(facts[1], delegateSlot, _voteSnapshotBlock(b, _pIds[i]), _cfg.externalToken))
      {
        revert WithdrawInvalidProof("delegate");
      }

      bytes memory slotBalanceData = facts[0].data;
      uint256 nounsBalanceVal = Storage.parseUint256(slotBalanceData);
      if (nounsBalanceVal == 0) {
        revert WithdrawNoBalanceAtPropStart();
      }

      // ensure that the owner had delegated their Nouns to the base wallet when voting
      // started on this proposal
      bytes memory slotDelegateData = facts[1].data;
      address nounsDelegateVal = Storage.parseAddress(slotDelegateData);
      if (nounsDelegateVal != _cfg.base) {
        revert WithdrawNoTokensDelegated();
      }

      uint256 ownerShare = (nounsBalanceVal * b.remainingAmount) / b.remainingVotes;
      withdrawAmount += ownerShare;

      b.remainingVotes -= nounsBalanceVal;
      b.remainingAmount -= withdrawAmount;

      unchecked {
        ++i;
      }
    }

    if (withdrawAmount > 0) {
      SafeTransferLib.forceSafeTransferETH(_tokenOwner, withdrawAmount);
      emit Withdraw(_cfg.externalDAO, _tokenOwner, _pIds, withdrawAmount);
    }

    return withdrawAmount;
  }

  /// Locks the contract to prevent bidding on new proposals
  function pause() external onlyOwner {
    _pause();
  }

  /// Unlocks the contract to allow bidding
  function unpause() external onlyOwner {
    _unpause();
  }

  /// Returns the latest bid for the given proposal
  function getBid(uint256 _pId) external view returns (Bid memory) {
    return bids[_pId];
  }

  /// Returns whether an account has made a withdrawal for a proposal
  function withdrawn(uint256 _pId, address _account) external view returns (bool) {
    return withdrawals[_pId][_account];
  }

  /// Returns the next minimum bid amount for a proposal
  function minBidAmount(uint256 _pid) external view returns (uint256) {
    Bid memory b = bids[_pid];
    if (b.amount == 0) {
      return _cfg.reservePrice;
    }

    return b.amount + ((b.amount * _cfg.minBidIncrementPercentage) / 100);
  }

  /// Helper that calculates percent of number using bps
  function _bpsToUint(uint256 bps, uint256 number) internal pure returns (uint256) {
    require(number < MAX_INT / 10000);
    require(bps <= 10000);

    return (number * bps) / 10000;
  }

  /// Helper that converts type address to bytes32
  function _addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  /// Helper that determines if a bid is eligible for a refund
  /// Canceled or vetoed proposals are always refundable.
  function _refundable(uint256 _pId, bool _voteCast) internal view returns (bool) {
    uint256 state = NounsGovernanceV2(_cfg.externalDAO).state(_pId);

    // canceled
    if (state == 2) {
      return true;
    }

    // vetoed
    if (state == 8) {
      return true;
    }

    // pending, active, or updatable states should never be refundable since
    // voting is either in progress or has not started
    // 0 == Pending, 1 == Active, 10 == Updatable
    if (state == 0 || state == 1 || state == 10) {
      return false;
    }

    // if votes were not cast against the proposal, it is refundable
    return !_voteCast;
  }

  /// Helper that determines whether to use startBlock or creationBlock for voting
  /// on proposals. This ensures that the module is compatible with future
  /// expected Nouns governance updates
  function _voteSnapshotBlock(Bid memory _b, uint256 _pId) internal view returns (uint256) {
    // default to using creation block
    if (_cfg.useStartBlockFromPropId == 0) {
      return _b.creationBlock;
    }

    if (_pId >= _cfg.useStartBlockFromPropId) {
      return _b.startBlock;
    }

    return _b.creationBlock;
  }

  /// Helper that determines if a proposal voting period is active
  function _active(uint256 _pId) internal view returns (bool) {
    return NounsGovernanceV2(_cfg.externalDAO).state(_pId) == 1;
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause

/// @title Nouns DAO Logic interfaces and events

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// NounsDAOInterfaces.sol is a modified version of Compound Lab's GovernorBravoInterfaces.sol:
// https://github.com/compound-finance/compound-protocol/blob/b9b14038612d846b83f8a009a82c38974ff2dcfe/contracts/Governance/GovernorBravoInterfaces.sol
//
// GovernorBravoInterfaces.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
// With modifications by Nounders DAO.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause
//
// MODIFICATIONS
// NounsDAOEvents, NounsDAOProxyStorage, NounsDAOStorageV1 add support for changes made by Nouns DAO to GovernorBravo.sol
// See NounsDAOLogicV1.sol for more details.
// NounsDAOStorageV1Adjusted and NounsDAOStorageV2 add support for a dynamic vote quorum.
// See NounsDAOLogicV2.sol for more details.

pragma solidity ^0.8.6;

contract NounsDAOEvents {
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice An event emitted when a new proposal is created, which includes additional information
    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 votes, string reason);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the NounsDAOExecutor
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the NounsDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice An event emitted when the voting delay is set
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);

    /// @notice An event emitted when the voting period is set
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);

    /// @notice Emitted when implementation is changed
    event NewImplementation(address oldImplementation, address newImplementation);

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(uint256 oldProposalThresholdBPS, uint256 newProposalThresholdBPS);

    /// @notice Emitted when quorum votes basis points is set
    event QuorumVotesBPSSet(uint256 oldQuorumVotesBPS, uint256 newQuorumVotesBPS);

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);
}

contract NounsDAOEventsV2 is NounsDAOEvents {
    /// @notice Emitted when minQuorumVotesBPS is set
    event MinQuorumVotesBPSSet(uint16 oldMinQuorumVotesBPS, uint16 newMinQuorumVotesBPS);

    /// @notice Emitted when maxQuorumVotesBPS is set
    event MaxQuorumVotesBPSSet(uint16 oldMaxQuorumVotesBPS, uint16 newMaxQuorumVotesBPS);

    /// @notice Emitted when quorumCoefficient is set
    event QuorumCoefficientSet(uint32 oldQuorumCoefficient, uint32 newQuorumCoefficient);

    /// @notice Emitted when a voter cast a vote requesting a gas refund.
    event RefundableVote(address indexed voter, uint256 refundAmount, bool refundSent);

    /// @notice Emitted when admin withdraws the DAO's balance.
    event Withdraw(uint256 amount, bool sent);

    /// @notice Emitted when pendingVetoer is changed
    event NewPendingVetoer(address oldPendingVetoer, address newPendingVetoer);
}

contract NounsDAOProxyStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice Active brains of Governor
    address public implementation;
}

/**
 * @title Storage for Governor Bravo Delegate
 * @notice For future upgrades, do not change NounsDAOStorageV1. Create a new
 * contract which implements NounsDAOStorageV1 and following the naming convention
 * NounsDAOStorageVX.
 */
contract NounsDAOStorageV1 is NounsDAOProxyStorage {
    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
    uint256 public quorumVotesBPS;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The address of the Nouns DAO Executor NounsDAOExecutor
    INounsDAOExecutor public timelock;

    /// @notice The address of the Nouns tokens
    NounsTokenLike public nouns;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }
}

/**
 * @title Extra fields added to the `Proposal` struct from NounsDAOStorageV1
 * @notice The following fields were added to the `Proposal` struct:
 * - `Proposal.totalSupply`
 * - `Proposal.creationBlock`
 */
contract NounsDAOStorageV1Adjusted is NounsDAOProxyStorage {
    /// @notice Vetoer who has the ability to veto any proposal
    address public vetoer;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
    uint256 public proposalThresholdBPS;

    /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
    uint256 public quorumVotesBPS;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The address of the Nouns DAO Executor NounsDAOExecutor
    INounsDAOExecutor public timelock;

    /// @notice The address of the Nouns tokens
    NounsTokenLike public nouns;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) internal _proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;
        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        /// @notice The ordered list of function signatures to be called
        string[] signatures;
        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
        /// @notice The total supply at the time of proposal creation
        uint256 totalSupply;
        /// @notice The block at which this proposal was created
        uint256 creationBlock;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;
        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;
        /// @notice The number of votes the voter had, which were cast
        uint96 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }
}

/**
 * @title Storage for Governor Bravo Delegate
 * @notice For future upgrades, do not change NounsDAOStorageV2. Create a new
 * contract which implements NounsDAOStorageV2 and following the naming convention
 * NounsDAOStorageVX.
 */
contract NounsDAOStorageV2 is NounsDAOStorageV1Adjusted {
    DynamicQuorumParamsCheckpoint[] public quorumParamsCheckpoints;

    /// @notice Pending new vetoer
    address public pendingVetoer;

    struct DynamicQuorumParams {
        /// @notice The minimum basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed.
        uint16 minQuorumVotesBPS;
        /// @notice The maximum basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed.
        uint16 maxQuorumVotesBPS;
        /// @notice The dynamic quorum coefficient
        /// @dev Assumed to be fixed point integer with 6 decimals, i.e 0.2 is represented as 0.2 * 1e6 = 200000
        uint32 quorumCoefficient;
    }

    /// @notice A checkpoint for storing dynamic quorum params from a given block
    struct DynamicQuorumParamsCheckpoint {
        /// @notice The block at which the new values were set
        uint32 fromBlock;
        /// @notice The parameter values of this checkpoint
        DynamicQuorumParams params;
    }

    struct ProposalCondensed {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Creator of the proposal
        address proposer;
        /// @notice The number of votes needed to create a proposal at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 proposalThreshold;
        /// @notice The minimum number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
        uint256 quorumVotes;
        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;
        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;
        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been vetoed
        bool vetoed;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        /// @notice The total supply at the time of proposal creation
        uint256 totalSupply;
        /// @notice The block at which this proposal was created
        uint256 creationBlock;
    }
}

interface INounsDAOExecutor {
    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);
}

interface NounsTokenLike {
    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

/// SPDX-License-Identifier: MIT
/// (c) Theori, Inc. 2022
/// All rights reserved

import "../lib/Facts.sol";

pragma solidity >=0.8.0;

/**
 * @title IBatchProver
 * @author Theori, Inc.
 * @notice IBatchProver is a standard interface implemented by some Relic provers.
 *         Supports proving multiple facts ephemerally or proving and storing
 *         them in the Reliquary.
 */
interface IBatchProver {
    /**
     * @notice prove multiple facts ephemerally
     * @param proof the encoded proof, depends on the prover implementation
     * @param store whether to store the facts in the reliquary
     * @return facts the proven facts' information
     */
    function proveBatch(bytes calldata proof, bool store)
        external
        payable
        returns (Fact[] memory facts);
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "../lib/Facts.sol";

/**
 * @title Holder of Relics and Artifacts
 * @author Theori, Inc.
 * @notice The Reliquary is the heart of Relic. All issuers of Relics and Artifacts
 *         must be added to the Reliquary. Queries about Relics and Artifacts should
 *         be made to the Reliquary.
 */
interface IReliquary is IAccessControl {
    /**
     * @notice Issued when a new prover is accepted into the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that will always be associated with the prover
     */
    event NewProver(address prover, uint64 version);

    /**
     * @notice Issued when a new prover is placed under consideration for acceptance
     *         into the Reliquary
     * @param prover the address of the prover contract
     * @param version the proposed identifier to always be associated with the prover
     * @param timestamp the earliest this prover can be brought into the Reliquary
     */
    event PendingProverAdded(address prover, uint64 version, uint64 timestamp);

    /**
     * @notice Issued when an existing prover is banished from the Reliquary
     * @param prover the address of the prover contract
     * @param version the identifier that can never be used again
     * @dev revoked provers may not issue new Relics or Artifacts. The meaning of
     *      any previously introduced Relics or Artifacts is implementation dependent.
     */
    event ProverRevoked(address prover, uint64 version);

    struct ProverInfo {
        uint64 version;
        FeeInfo feeInfo;
        bool revoked;
    }

    enum FeeFlags {
        FeeNone,
        FeeNative,
        FeeCredits,
        FeeExternalDelegate,
        FeeExternalToken
    }

    struct FeeInfo {
        uint8 flags;
        uint16 feeCredits;
        // feeWei = feeWeiMantissa * pow(10, feeWeiExponent)
        uint8 feeWeiMantissa;
        uint8 feeWeiExponent;
        uint32 feeExternalId;
    }

    function ADD_PROVER_ROLE() external view returns (bytes32);

    function CREDITS_ROLE() external view returns (bytes32);

    function DELAY() external view returns (uint64);

    function GOVERNANCE_ROLE() external view returns (bytes32);

    function SUBSCRIPTION_ROLE() external view returns (bytes32);

    /**
     * @notice activates a pending prover once the delay has passed. Callable by anyone.
     * @param prover the address of the pending prover
     */
    function activateProver(address prover) external;

    /**
     * @notice Add credits to an account. Requires the CREDITS_ROLE.
     * @param user The account to which more credits should be granted
     * @param amount The number of credits to be added
     */
    function addCredits(address user, uint192 amount) external;

    /**
     * @notice Add/propose a new prover to prove facts. Requires the ADD_PROVER_ROLE.
     * @param prover the address of the prover in question
     * @param version the unique version string to associate with this prover
     * @dev Provers and proposed provers must have unique version IDs
     * @dev After the Reliquary is initialized, a review period of 64k blocks
     *      must conclude before a prover may be added. The request must then
     *      be re-submitted to take effect. Before initialization is complete,
     *      the review period is skipped.
     * @dev Emits PendingProverAdded when a prover is proposed for inclusion
     */
    function addProver(address prover, uint64 version) external;

    /**
     * @notice Add/update a subscription. Requires the SUBSCRIPTION_ROLE.
     * @param user The subscriber account to modify
     * @param ts The new block timestamp at which the subscription expires
     */
    function addSubscriber(address user, uint64 ts) external;

    /**
     * @notice Asserts that a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function assertValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable;

    /**
     * @notice Asserts that a particular block had a particular hash. Callable only from provers.
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @dev Reverts if the given block was not proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function assertValidBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view;

    /**
     * @notice Require that an appropriate fee is paid for proving a fact
     * @param sender The account wanting to prove a fact
     * @dev The fee is derived from the prover which calls this  function
     * @dev Reverts if the fee is not sufficient
     * @dev Only to be called by a prover
     */
    function checkProveFactFee(address sender) external payable;

    /**
     * @notice Helper function to query the status of a prover
     * @param prover the ProverInfo associated with the prover in question
     * @dev reverts if the prover is invalid or revoked
     */
    function checkProver(ProverInfo memory prover) external pure;

    /**
     * @notice Check how many credits a given account possesses
     * @param user The account in question
     * @return The number of credits
     */
    function credits(address user) external view returns (uint192);

    /**
     * @notice Verify if a particular block had a particular hash. Only callable by address(0),
               for debug
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugValidBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice Query for associated information for a fact. Only callable by address(0), for debug
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by off-chain tools only (reverts otherwise)
     */
    function debugVerifyFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    function factFees(uint8) external view returns (FeeInfo memory);

    function feeAccounts(address)
        external
        view
        returns (uint64 subscriberUntilTime, uint192 credits);

    function feeExternals(uint256) external view returns (address);

    /**
     * @notice Query for associated information for a fact. Only callable from provers.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function getFact(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Determine the appropriate ETH fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getProveFactNativeFee(address prover) external view returns (uint256);

    /**
     * @notice Determine the appropriate token fee to prove a fact
     * @param prover The prover of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getProveFactTokenFee(address prover) external view returns (uint256);

    /**
     * @notice Determine the appropriate ETH fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in ETH
     */
    function getVerifyFactNativeFee(FactSignature factSig) external view returns (uint256);

    /**
     * @notice Determine the appropriate token fee to query a fact
     * @param factSig The signature of the desired fact
     * @return the fee in wei
     * @dev Reverts if the fee is not to be paid in external tokens
     */
    function getVerifyFactTokenFee(FactSignature factSig) external view returns (uint256);

    function initialized() external view returns (bool);

    /**
     * @notice Check if an account has an active subscription
     * @param user The account in question
     * @return True if the account is active, otherwise false
     */
    function isSubscriber(address user) external view returns (bool);

    function pendingProvers(address) external view returns (uint64 timestamp, uint64 version);

    function provers(address)
        external
        view
        returns (ProverInfo memory);

    /**
     * @notice Remove credits from an account. Requires the CREDITS_ROLE.
     * @param user The account from which credits should be removed
     * @param amount The number of credits to be removed
     */
    function removeCredits(address user, uint192 amount) external;

    /**
     * @notice Remove a subscription. Requires the SUBSCRIPTION_ROLE.
     * @param user The subscriber account to modify
     */
    function removeSubscriber(address user) external;

    /**
     * @notice Deletes the fact from the Reliquary. Only callable from provers.
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being deleted
     * @dev May only be called by non-revoked provers
     */
    function resetFact(address account, FactSignature factSig) external;

    /**
     * @notice Stop accepting proofs from this prover. Requires the GOVERNANCE_ROLE.
     * @param prover The prover to banish from the reliquary
     * @dev Emits ProverRevoked
     * @dev Note: existing facts proved by the prover may still stand
     */
    function revokeProver(address prover) external;

    function setCredits(address user, uint192 amount) external;

    /**
     * @notice Adds the given information to the Reliquary. Only callable from provers.
     * @param account The account to which this information is bound (may be
     *        the null account for information bound to no specific address)
     * @param factSig The unique signature of the particular fact being proven
     * @param data Associated data to store with this item
     * @dev May only be called by non-revoked provers
     */
    function setFact(
        address account,
        FactSignature factSig,
        bytes memory data
    ) external;

    /**
     * @notice Sets the FeeInfo for a particular fee class. Requires the GOVERNANCE_ROLE.
     * @param cls The fee class
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setFactFee(
        uint8 cls,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    /**
     * @notice Initialize the Reliquary, enforcing the time lock for new provers. Requires the
               ADD_PROVER_ROLE.
     */
    function setInitialized() external;

    /**
     * @notice Sets the FeeInfo for a particular prover. Requires the GOVERNANCE_ROLE.
     * @param prover The prover in question
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setProverFee(
        address prover,
        FeeInfo memory feeInfo,
        address feeExternal
    ) external;

    /**
     * @notice Sets the FeeInfo for block verification. Requires the GOVERNANCE_ROLE.
     * @param feeInfo The FeeInfo to use for the class
     * @param feeExternal An external fee provider (token or delegate). If
     *        none is required, this should be set to 0.
     */
    function setValidBlockFee(FeeInfo memory feeInfo, address feeExternal) external;

    /**
     * @notice Verify if a particular block had a particular hash
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev A fee may be required based on the block in question
     */
    function validBlockHash(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external payable returns (bool);

    /**
     * @notice Verify if a particular block had a particular hash. Only callable from provers.
     * @param verifier The block history verifier to use for the query
     * @param hash The block hash in question
     * @param num The block number to query
     * @param proof Any witness information needed by the verifier
     * @return boolean indication of whether or not the given block was
     *         proven to have the given hash.
     * @dev This function is only for use by provers (reverts otherwise)
     */
    function validBlockHashFromProver(
        address verifier,
        bytes32 hash,
        uint256 num,
        bytes memory proof
    ) external view returns (bool);

    /**
     * @notice FeeInfo struct for block hash queries
     */
    function verifyBlockFeeInfo() external view returns (FeeInfo memory);

    /**
     * @notice Query for associated information for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev A fee may be required based on the factSig
     */
    function verifyFact(address account, FactSignature factSig)
        external
        payable
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Query for associated information for a fact which requires no query fee.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @return data any associated fact data
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactNoFee(address account, FactSignature factSig)
        external
        view
        returns (
            bool exists,
            uint64 version,
            bytes memory data
        );

    /**
     * @notice Query for the prover version for a fact
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev A fee may be required based on the factSig
     */
    function verifyFactVersion(address account, FactSignature factSig)
        external
        payable
        returns (bool exists, uint64 version);

    /**
     * @notice Query for the prover version for a fact which requires no query fee.
     * @param account The address to which the fact belongs
     * @param factSig The unique signature identifying the fact
     * @return exists whether or not a fact with the given signature
     *         is associated with the queried account
     * @return version the prover version id that proved this fact
     * @dev This function is for use by anyone
     * @dev This function reverts if the fact requires a fee to query
     */
    function verifyFactVersionNoFee(address account, FactSignature factSig)
        external
        view
        returns (bool exists, uint64 version);

    /**
     * @notice Reverse mapping of version information to the unique prover able
     *         to issue statements with that version
     */
    function versions(uint64) external view returns (address);

    /**
     * @notice Extract accumulated fees. Requires the GOVERNANCE_ROLE.
     * @param token The ERC20 token from which to extract fees. Or the 0 address for
     *        native ETH
     * @param dest The address to which fees should be transferred
     */
    function withdrawFees(address token, address dest) external;
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./Facts.sol";

/**
 * @title FactSigs
 * @author Theori, Inc.
 * @notice Helper functions for computing fact signatures
 */
library FactSigs {
    /**
     * @notice Produce the fact signature data for birth certificates
     */
    function birthCertificateFactSigData() internal pure returns (bytes memory) {
        return abi.encode("BirthCertificate");
    }

    /**
     * @notice Produce the fact signature for a birth certificate fact
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, birthCertificateFactSigData());
    }

    /**
     * @notice Produce the fact signature data for an account's storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSigData(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountStorage", blockNum, storageRoot);
    }

    /**
     * @notice Produce a fact signature for an accoun't storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSig(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (FactSignature)
    {
        return
            Facts.toFactSignature(Facts.NO_FEE, accountStorageFactSigData(blockNum, storageRoot));
    }

    /**
     * @notice Produce the fact signature data for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSigData(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("StorageSlot", slot, blockNum);
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, storageSlotFactSigData(slot, blockNum));
    }

    /**
     * @notice Produce the fact signature data for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSigData(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (bytes memory) {
        return abi.encode("Log", blockNum, txIdx, logIdx);
    }

    /**
     * @notice Produce a fact signature for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSig(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, logFactSigData(blockNum, txIdx, logIdx));
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("BlockHeader", blockNum);
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, blockHeaderSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an event fact
     * @param eventId The event in question
     */
    function eventFactSigData(uint64 eventId) internal pure returns (bytes memory) {
        return abi.encode("EventAttendance", "EventID", eventId);
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, eventFactSigData(eventId));
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

type FactSignature is bytes32;

struct Fact {
    address account;
    FactSignature sig;
    bytes data;
}

/**
 * @title Facts
 * @author Theori, Inc.
 * @notice Helper functions for fact classes (part of fact signature that determines fee).
 */
library Facts {
    uint8 internal constant NO_FEE = 0;

    /**
     * @notice construct a fact signature from a fact class and some unique data
     * @param cls the fact class (determines the fee)
     * @param data the unique data for the signature
     */
    function toFactSignature(uint8 cls, bytes memory data) internal pure returns (FactSignature) {
        return FactSignature.wrap(bytes32((uint256(keccak256(data)) << 8) | cls));
    }

    /**
     * @notice extracts the fact class from a fact signature
     * @param factSig the input fact signature
     */
    function toFactClass(FactSignature factSig) internal pure returns (uint8) {
        return uint8(uint256(FactSignature.unwrap(factSig)));
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title Storage
 * @author Theori, Inc.
 * @notice Helper functions for handling storage slot facts and computing storage slots
 */
library Storage {
    /**
     * @notice compute the slot for an element of a mapping
     * @param base the slot of the struct base
     * @param key the mapping key, padded to 32 bytes
     */
    function mapElemSlot(bytes32 base, bytes32 key) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(key, base));
    }

    /**
     * @notice compute the slot for an element of a static array
     * @param base the slot of the struct base
     * @param idx the index of the element
     * @param slotsPerElem the number of slots per element
     */
    function staticArrayElemSlot(
        bytes32 base,
        uint256 idx,
        uint256 slotsPerElem
    ) internal pure returns (bytes32) {
        return bytes32(uint256(base) + idx * slotsPerElem);
    }

    /**
     * @notice compute the slot for an element of a dynamic array
     * @param base the slot of the struct base
     * @param idx the index of the element
     * @param slotsPerElem the number of slots per element
     */
    function dynamicArrayElemSlot(
        bytes32 base,
        uint256 idx,
        uint256 slotsPerElem
    ) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(base))) + idx * slotsPerElem);
    }

    /**
     * @notice compute the slot for a struct field given the base slot and offset
     * @param base the slot of the struct base
     * @param offset the slot offset in the struct
     */
    function structFieldSlot(
        bytes32 base,
        uint256 offset
    ) internal pure returns (bytes32) {
        return bytes32(uint256(base) + offset);
    }

    function _parseUint256(bytes memory data) internal pure returns (uint256) {
        return uint256(bytes32(data)) >> (256 - 8 * data.length);
    }

    /**
     * @notice parse a uint256 from storage slot bytes
     * @param data the storage slot bytes
     * @return address the parsed address
     */
    function parseUint256(bytes memory data) internal pure returns (uint256) {
        require(data.length <= 32, 'data is not a uint256');
        return _parseUint256(data);
    }

    /**
     * @notice parse a uint64 from storage slot bytes
     * @param data the storage slot bytes
     */
    function parseUint64(bytes memory data) internal pure returns (uint64) {
        require(data.length <= 8, 'data is not a uint64');
        return uint64(_parseUint256(data));
    }

    /**
     * @notice parse an address from storage slot bytes
     * @param data the storage slot bytes
     */
    function parseAddress(bytes memory data) internal pure returns (address) {
        require(data.length <= 20, 'data is not an address');
        return address(uint160(_parseUint256(data)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Store the `from` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x60, amount) // Store the `amount` argument.

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, from) // Store the `from` argument.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x40, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x6a.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x3a, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x1a, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x3a.
            amount := mload(0x3a)
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0x095ea7b3000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, account) // Store the `account` argument.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x1c, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

pragma solidity ^0.8.19;

/// This is a base contract to aid in adding incentives to your protocol
abstract contract Motivator {
  /// Emitted when a caller receives a gas refund with tip
  event GasRefundWithTip(address indexed to, uint256 refund, uint256 tip);

  /// Base gas to refund
  uint256 public constant REFUND_BASE_GAS = 36000;

  /// Max priority fee used for refunds
  uint256 public constant MAX_REFUND_PRIORITY_FEE = 1 gwei;

  /// Max gas units that will be refunded
  uint256 public constant MAX_REFUND_GAS_USED = 200_000;

  /// Refunds gas spent on a transaction and includes a tip
  function _gasRefundWithTipAndCap(
    uint256 _startGas,
    uint256 _cap,
    uint256 _maxBaseFee,
    uint256 _tip
  ) internal view returns (uint256) {
    unchecked {
      uint256 balance = address(this).balance;
      if (balance == 0) {
        return 0;
      }

      uint256 basefee = min(block.basefee, _maxBaseFee);
      uint256 gasPrice = min(tx.gasprice, basefee + MAX_REFUND_PRIORITY_FEE);
      uint256 gasUsed = min(_startGas - gasleft() + REFUND_BASE_GAS, MAX_REFUND_GAS_USED);
      uint256 refundAmount = min((gasPrice * gasUsed) + _tip, balance);
      return min(_cap, refundAmount);
    }
  }

  /// Returns the min of two integers
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// Wraps Federation module functionality
interface Module {
  /// init is called when a new module is enabled from a base wallet
  function init(bytes calldata) external payable;
}

// SPDX-License-Identifier: GPL-3.0

import { Fact, FactSignature } from "relic-sdk/packages/contracts/lib/Facts.sol";
import { FactSigs } from "relic-sdk/packages/contracts/lib/FactSigs.sol";

pragma solidity ^0.8.19;

interface Validator {
  function validate(Fact memory fact, bytes32 expectedSlot, uint256 expectedBlock, address account)
    external
    pure
    returns (bool);
}

/// FactValidator abstracts proof validation functionality
contract FactValidator is Validator {
  function validate(Fact memory fact, bytes32 expectedSlot, uint256 expectedBlock, address account)
    external
    pure
    returns (bool)
  {
    FactSignature expectedSig = FactSigs.storageSlotFactSig(expectedSlot, expectedBlock);
    if (keccak256(abi.encodePacked(fact.sig)) != keccak256(abi.encodePacked(expectedSig))) {
      return false;
    }

    if (fact.account != account) {
      return false;
    }

    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import { Module } from "src/module/Module.sol";
import { ModuleConfig } from "src/module/governance-pool/ModuleConfig.sol";

/// GovernancePool Wraps governance pool module functionality
interface GovernancePool is Module {
  error InitExternalDAONotSet();
  error InitExternalTokenNotSet();
  error InitFeeRecipientNotSet();
  error InitCastWindowNotSet();
  error InitBaseWalletNotSet();

  error BidTooLow();
  error BidAuctionEnded();
  error BidInvalidSupport();
  error BidReserveNotMet();
  error BidProposalNotActive();
  error BidVoteAlreadyCast();
  error BidMaxBidExceeded();
  error BidModulePaused();

  error CastVoteBidDoesNotExist();
  error CastVoteNotInWindow();
  error CastVoteNoDelegations();
  error CastVoteMustWait();
  error CastVoteAlreadyCast();

  error ClaimOnlyBidder();
  error ClaimAlreadyRefunded();
  error ClaimNotRefundable();

  error WithdrawDelegateOrOwnerOnly();
  error WithdrawBidNotOffered();
  error WithdrawBidRefunded();
  error WithdrawVoteNotCast();
  error WithdrawPropIsActive();
  error WithdrawAlreadyClaimed();
  error WithdrawInvalidProof(string);
  error WithdrawNoBalanceAtPropStart();
  error WithdrawNoTokensDelegated();
  error WithdrawMaxProverVersion();

  /// Bid is the structure of an offer to cast a vote on a proposal
  struct Bid {
    /// The amount of ETH bid
    uint256 amount;
    /// The remaining amount of ETH left to be withdrawn
    uint256 remainingAmount;
    /// The remaining amount of votes left to withdraw proceeds from the pool
    uint256 remainingVotes;
    /// The block number the external proposal was created
    uint256 creationBlock;
    /// The block number the external proposal voting period started
    uint256 startBlock;
    /// The block number the external proposal voting period ends
    uint256 endBlock;
    /// the block number the bid was made
    uint256 bidBlock;
    /// The support value to cast if this bid wins
    uint256 support;
    /// The address of the bidder
    address bidder;
    /// Whether the vote was cast for this bid
    bool executed;
    /// Whether the bid was refunded
    bool refunded;
  }

  /// Emitted when a vote has been cast against an external proposal
  event VoteCast(
    address indexed dao, uint256 indexed propId, uint256 support, uint256 amount, address bidder
  );

  /// Emitted when a bid has been placed
  event BidPlaced(
    address indexed dao, uint256 indexed propId, uint256 support, uint256 amount, address bidder
  );

  /// Emitted when a refund has been claimed
  event RefundClaimed(
    address indexed dao, uint256 indexed propId, uint256 amount, address receiver
  );

  /// Emitted when proceeds have been withdrawn for a proposal
  event Withdraw(address indexed dao, address indexed receiver, uint256[] propId, uint256 amount);

  /// Emitted when a protocol fee has been applied when casting votes
  event ProtocolFeeApplied(address indexed recipient, uint256 amount);

  /// Bid on a proposal
  function bid(uint256, uint256) external payable;

  /// Cast a vote from the contract to external proposal
  function castVote(uint256) external;

  /// Claim a refund for a bid where the vote was not cast
  function claimRefund(uint256) external;

  /// Withdraw proceeds in proportion of delegation from a bid where the vote was cast
  /// A max of 5 props can be withdrawn from at once
  function withdraw(
    address _prover,
    address _delegator,
    uint256[] calldata _pId,
    uint256[] calldata _fee,
    bytes[] calldata _proof
  ) external payable returns (uint256);

  /// Get the bid for a proposal
  function getBid(uint256 _pId) external view returns (Bid memory);

  /// Returns whether an account has made a withdrawal for a proposal
  function withdrawn(uint256 _pId, address _account) external view returns (bool);

  /// Returns the next minimum bid amount for a proposal
  function minBidAmount(uint256 _pid) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

import { OwnableUpgradeable } from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";
import { IDelegationRegistry } from "delegate-cash/IDelegationRegistry.sol";
import { IBatchProver } from "relic-sdk/packages/contracts/interfaces/IBatchProver.sol";
import { IReliquary } from "relic-sdk/packages/contracts/interfaces/IReliquary.sol";
import { GovernancePool } from "src/module/governance-pool/GovernancePool.sol";
import { Wallet } from "src/wallet/Wallet.sol";

pragma solidity ^0.8.19;

// The storage slot index of the mapping containing Nouns token balance
bytes32 constant SLOT_INDEX_TOKEN_BALANCE = bytes32(uint256(4));

// The storage slot index of the mapping containing Nouns delegate addresses
bytes32 constant SLOT_INDEX_DELEGATE = bytes32(uint256(11));

abstract contract ModuleConfig is OwnableUpgradeable {
  /// Emitted when storage slots are updated
  event SlotsUpdated(bytes32 balanceSlot, bytes32 delegateSlot);

  /// Emitted when the config is updated
  event ConfigChanged();

  /// Returns if a lock is active for this module
  error ConfigModuleHasActiveLock();

  /// Config is the structure of cfg for a Governance Pool module
  struct Config {
    /// The base wallet address for this module
    address base;
    /// The address of the DAO we are casting votes against
    address externalDAO;
    /// The address of the token used for voting in the external DAO
    address externalToken;
    /// feeRecipient is the address that receives any configured protocol fee
    address feeRecipient;
    /// The minimum bid accepted to cast a vote
    uint256 reservePrice;
    /// castWaitBlocks prevents any votes from being cast until this time in blocks has passed
    uint256 castWaitBlocks;
    /// The minimum percent difference between the last bid placed for a
    /// proposal vote and the current one
    uint256 minBidIncrementPercentage;
    /// The window in blocks when a vote can be cast
    uint256 castWindow;
    /// The default tip configured for casting a vote
    uint256 tip;
    /// feeBPS as parts per 10_000, i.e. 10% = 1000
    uint256 feeBPS;
    /// The maximum amount of base fee that can be refunded when casting a vote
    uint256 maxBaseFeeRefund;
    /// max relic batch prover version; if 0 any prover version is accepted
    uint256 maxProverVersion;
    /// relic reliquary address
    address reliquary;
    /// delegate cash registry address
    address dcash;
    /// fact validator address
    address factValidator;
    /// in preparation for Nouns governance v2->v3 we need to know
    /// handle switching vote snapshots to a proposal's start block
    uint256 useStartBlockFromPropId;
    /// configurable vote reason
    string reason;
  }

  /// The storage slot index containing nouns token balance mappings
  bytes32 public balanceSlotIdx = SLOT_INDEX_TOKEN_BALANCE;

  /// The storage slot index containing nouns delegate mappings
  bytes32 public delegateSlotIdx = SLOT_INDEX_DELEGATE;

  /// The config of this module
  Config internal _cfg;

  modifier isNotLocked() {
    _isNotLocked();
    _;
  }

  /// Reverts if the module has an open lock
  function _isNotLocked() internal view virtual {
    if (Wallet(_cfg.base).hasActiveLock()) {
      revert ConfigModuleHasActiveLock();
    }
  }

  /// Management function to get this contracts config
  function getConfig() external view returns (Config memory) {
    return _cfg;
  }

  /// Management function to update the config post initialization
  function setConfig(Config memory _config) external onlyOwner isNotLocked {
    // fees cannot be updated after initialization
    _config.feeBPS = _cfg.feeBPS;
    _config.feeRecipient = _cfg.feeRecipient;

    _cfg = _validateConfig(_config);
    emit ConfigChanged();
  }

  function setTipAndRefund(uint256 _tip, uint256 _maxBaseFeeRefund) external onlyOwner isNotLocked {
    _cfg.tip = _tip;
    _cfg.maxBaseFeeRefund = _maxBaseFeeRefund;
    emit ConfigChanged();
  }

  /// Management function to set token storage slots for proof verification
  function setSlots(uint256 balanceSlot, uint256 delegateSlot) external onlyOwner isNotLocked {
    balanceSlotIdx = bytes32(balanceSlot);
    delegateSlotIdx = bytes32(delegateSlot);
    emit SlotsUpdated(balanceSlotIdx, delegateSlotIdx);
  }

  /// Management function to update dependency addresses
  function setAddresses(address _reliquary, address _delegateCash, address _factValidator)
    external
    onlyOwner
    isNotLocked
  {
    require(_reliquary != address(0), "invalid reliquary addr");
    require(_delegateCash != address(0), "invalid delegate cash registry addr");
    require(_factValidator != address(0), "invalid fact validator addr");

    _cfg.reliquary = _reliquary;
    _cfg.dcash = _delegateCash;
    _cfg.factValidator = _factValidator;
    emit ConfigChanged();
  }

  /// Management function to set a max required prover version
  /// Protects the pool in the event that relic is compromised
  function setMaxProverVersion(uint256 _version) external onlyOwner {
    _cfg.maxProverVersion = _version;
    emit ConfigChanged();
  }

  /// Management function to set the prop id for when we should start using
  /// proposal start blocks for voting snapshots
  function setUseStartBlockFromPropId(uint256 _pId) external onlyOwner {
    _cfg.useStartBlockFromPropId = _pId;
    emit ConfigChanged();
  }

  /// Management function to set vote reason
  function setReason(string calldata _reason) external onlyOwner {
    _cfg.reason = _reason;
    emit ConfigChanged();
  }

  /// Management function to reduce fees
  function setFeeBPS(uint256 _feeBPS) external onlyOwner {
    require(_feeBPS < _cfg.feeBPS, "fee cannot be increased");
    _cfg.feeBPS = _feeBPS;
    emit ConfigChanged();
  }

  /// Management function to update auction reserve price
  function setReservePrice(uint256 _reservePrice) external onlyOwner {
    require(_reservePrice > 0, "reserve cannot be 0");
    _cfg.reservePrice = _reservePrice;
    emit ConfigChanged();
  }

  /// Management function to update castWindow
  function setCastWindow(uint256 _castWindow) external onlyOwner {
    require(_castWindow > 0, "cast window 0");
    _cfg.castWindow = _castWindow;
    emit ConfigChanged();
  }

  /// Validates that the config is set properly and sets default values if necessary
  function _validateConfig(Config memory _config) internal pure returns (Config memory) {
    if (_config.castWindow == 0) {
      revert GovernancePool.InitCastWindowNotSet();
    }

    if (_config.externalDAO == address(0)) {
      revert GovernancePool.InitExternalDAONotSet();
    }

    if (_config.externalToken == address(0)) {
      revert GovernancePool.InitExternalTokenNotSet();
    }

    if (_config.feeBPS > 0 && _config.feeRecipient == address(0)) {
      revert GovernancePool.InitFeeRecipientNotSet();
    }

    if (_config.base == address(0)) {
      revert GovernancePool.InitBaseWalletNotSet();
    }

    // default reserve price
    if (_config.reservePrice == 0) {
      _config.reservePrice = 1 wei;
    }

    // default cast wait blocks 5 ~= 1 minute
    if (_config.castWaitBlocks == 0) {
      _config.castWaitBlocks = 5;
    }

    return _config;
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/// Wraps the functionality of a Federation base wallet
interface Wallet {
  error NotEnabled();
  error ModuleAlreadyInitialized();
  error TransactionReverted();
  error LockDurationRequestTooLong();
  error LockActive();

  event SetModule(address indexed module, bool enabled);

  event ExecuteTransaction(address indexed caller, address indexed target, uint256 value);

  event Received(uint256 indexed value, address indexed sender, bytes data);

  event RequestLock(address indexed module, uint256 duration);

  event ReleaseLock(address indexed module);

  event MaxLockDurationBlocksChanged(uint256 blocks);

  function initialize(address) external;

  function execute(address, uint256, bytes calldata) external returns (bytes memory);

  function setModule(address, bool) external;

  function moduleEnabled(address) external view returns (bool);

  function requestLock(uint256) external returns (uint256);

  function releaseLock() external;

  function hasActiveLock() external view returns (bool);

  function setMaxLockDurationBlocks(uint256 _blocks) external;

  function maxLockDurationBlocks() external view returns (uint256);
}