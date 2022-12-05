// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';

library CrossChainMandateUtils {
  enum AccessControl {
    Level_null, // to not use 0
    Level_1, // LEVEL_1 - short executor before, listing assets, changes of assets params, updates of the protocol etc
    Level_2 // LEVEL_2 - long executor before, mandate provider updates
  }
  // should fit into uint256 imo
  struct Payload {
    // our own id for the chain, rationality is optimize the space, because chainId by the standard can be uint256,
    //TODO: the limit of enum is 256, should we care about it, or we will never reach this point?
    CrossChainUtils.Chains chain;
    AccessControl accessLevel;
    address mandateProvider; // address which holds the logic to execute after success proposal voting
    uint40 payloadId; // number of the payload placed to mandateProvider, max is: ~10¹²
    uint40 __RESERVED; // reserved for some future needs
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library CrossChainUtils {
  enum Chains {
    Null_network, // to not use 0
    EthMainnet,
    Polygon,
    Avalanche,
    Harmony,
    Arbitrum,
    Fantom,
    Optimism,
    Goerli,
    AvalancheFuji,
    OptimismGoerli,
    PolygonMumbai,
    ArbitrumGoerli,
    FantomTestnet,
    HarmonyTestnet
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {IGovernanceDataHelper} from './interfaces/IGovernanceDataHelper.sol';
import {IGovernanceCore} from '../../interfaces/IGovernanceCore.sol';

contract GovernanceDataHelper is IGovernanceDataHelper {
  function getProposalsData(
    IGovernanceCore govCore,
    uint256[] calldata proposalIds
  ) external view returns (Proposal[] memory) {
    Proposal[] memory proposals = new Proposal[](proposalIds.length);
    IGovernanceCore.Proposal memory proposalData;

    for (uint256 i = 0; i < proposalIds.length; i++) {
      proposalData = govCore.getProposal(proposalIds[i]);
      proposals[i] = Proposal({id: proposalIds[i], proposalData: proposalData});
    }

    return proposals;
  }

  function getConstants(
    IGovernanceCore govCore,
    CrossChainMandateUtils.AccessControl[] calldata accessLevels
  ) external view returns (Constants memory) {
    VotingConfig[] memory votingConfigs = new VotingConfig[](
      accessLevels.length
    );
    IGovernanceCore.VotingConfig memory votingConfig;

    for (uint256 i = 0; i < accessLevels.length; i++) {
      votingConfig = govCore.getVotingConfig(accessLevels[i]);
      votingConfigs[i] = VotingConfig({
        accessLevel: accessLevels[i],
        config: votingConfig
      });
    }

    uint256 precisionDivider = govCore.PRECISION_DIVIDER();
    uint256 coolDownPeriod = govCore.COOLDOWN_PERIOD();
    uint256 expirationTime = govCore.PROPOSAL_EXPIRATION_TIME();

    return
      Constants({
        votingConfigs: votingConfigs,
        precisionDivider: precisionDivider,
        cooldownPeriod: coolDownPeriod,
        expirationTime: expirationTime
      });
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IGovernanceCore} from '../../../interfaces/IGovernanceCore.sol';

interface IGovernanceDataHelper {
  struct Proposal {
    uint256 id;
    IGovernanceCore.Proposal proposalData;
  }

  struct VotingConfig {
    CrossChainMandateUtils.AccessControl accessLevel;
    IGovernanceCore.VotingConfig config;
  }

  struct Constants {
    VotingConfig[] votingConfigs;
    uint256 precisionDivider;
    uint256 cooldownPeriod;
    uint256 expirationTime;
  }

  function getProposalsData(
    IGovernanceCore govCore,
    uint256[] calldata proposalIds
  ) external view returns (Proposal[] memory);

  function getConstants(
    IGovernanceCore govCore,
    CrossChainMandateUtils.AccessControl[] calldata accessLevels
  ) external view returns (Constants memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IL1VotingStrategy} from './IL1VotingStrategy.sol';

interface IGovernanceCore {
  // TODO: think about what we expect in config, maybe we want in receive normal units with 18 decimals, and reduce decimals inside
  // from another side uint56 is ~10^16, which means that nobody will be able even to pass 10^18
  /**
   * @dev Object storing the vote configuration for a specific access level
   * @param isActive boolean indicating if this configuration should be used
   * @param coolDownBeforeVotingStart number of seconds indicating how much time should pass before proposal will be moved to vote
   * @param votingDuration number of seconds indicating the duration of a vote
   * @param quorum minimum number of votes needed for a proposal to pass.
            FOR VOTES + AGAINST VOTES > QUORUM
            we consider that this param in case of AAVE don't need decimal places
   * @param differential number of for votes that need to be bigger than against votes to pass a proposal.
            FOR VOTES - AGAINST VOTES > DIFFERENTIAL
            we consider that this param in case of AAVE don't need decimal places
   * @param minPropositionPower the minimum needed power to create a proposal.
            we consider that this param in case of AAVE don't need decimal places
   */
  struct VotingConfig {
    bool isActive;
    uint24 coolDownBeforeVotingStart;
    uint24 votingDuration;
    uint56 quorum;
    uint56 differential;
    uint56 minPropositionPower;
  }

  /**
   * @dev object storing the input parameters of a voting configuration
   * @param accessLevel number of access level needed to execute a proposal in this settings
   * @param isActive boolean indicating if this configuration should be used
   * @param votingDuration number of seconds indicating the duration of a vote
   * @param quorum minimum number of votes needed for a proposal to pass.
            FOR VOTES + AGAINST VOTES > QUORUM
            in normal units with 18 decimals
   * @param differential number of for votes that need to be bigger than against votes to pass a proposal.
            FOR VOTES - AGAINST VOTES > DIFFERENTIAL
            in normal units with 18 decimals
   * @param minPropositionPower the minimum needed power to create a proposal.
            in normal units with 18 decimals
   */
  struct SetVotingConfigInput {
    CrossChainMandateUtils.AccessControl accessLevel;
    bool isActive;
    uint24 coolDownBeforeVotingStart;
    uint24 votingDuration;
    uint256 quorum;
    uint256 differential;
    uint256 minPropositionPower;
  }

  /**
   * @dev enum storing the different states of a proposal
   */
  enum State {
    Null, // proposal does not exists
    Created, // created, waiting for a cooldown to initiate the balances snapshot
    Active, // balances snapshot set, voting in progress
    Queued, // voting results submitted, but proposal is under grace period when guardian can cancel it
    Executed, // results sent to the execution chain(s)
    Failed, // voting was not successful
    Cancelled, // got cancelled by guardian, or because proposition power of creator dropped below allowed minimum
    Expired
  }

  /**
   * @dev object storing all the information of a proposal including the different states in time that can have
   * @param votingDuration number of seconds indicating the duration of a vote. max is: 16'777'216 (ie 194.18 days)
   * @param creationTime timestamp in seconds of when the proposal was created. max is: 1.099511628×10¹² (ie 34'865 years)
   * @param snapshotBlockHash blockHash of when the proposal was created, as to be able to get the correct balances on this specific block
   * @param accessLevel minimum level needed to be able to execute this proposal
   * @param state current state of the proposal
   * @param creator address of the creator of the proposal
   * @param payloads list of objects containing the payload information necessary for execution
   * @param queuingTime timestamp in seconds of when the proposal was queued
   * @param cancelTimestamp timestamp in seconds of when the proposal was canceled
   * @param votingPortal address of the votingPortal used to communicate with the voting chain
   * @param ipfsHash ipfs has containing the proposal metadata information
   * @param forVotes number of votes in favor of the proposal
   * @param againstVotes number of votes against the proposal
   * @param hashBlockNumber block number used to take the block hash from. Proposal creation block number - 1
   */
  struct Proposal {
    uint24 votingDuration;
    uint40 creationTime;
    uint40 votingActivationTime;
    bytes32 snapshotBlockHash;
    CrossChainMandateUtils.AccessControl accessLevel; // should be needed only on "execution chain", should fit into uint256 imo
    State state;
    uint40 queuingTime;
    uint40 cancelTimestamp;
    bytes32 ipfsHash;
    uint128 forVotes;
    uint128 againstVotes;
    address votingPortal;
    address creator;
    uint256 hashBlockNumber;
    CrossChainMandateUtils.Payload[] payloads; // should be needed only on "execution chain", should fit into uint256 imo
  }

  /**
   * @dev emitted when votingStrategy got updated
   * @param newVotingStrategy address of the new votingStrategy
   **/
  event VotingStrategyUpdated(address indexed newVotingStrategy);

  /**
   * @dev emitted when one of the _votingConfigs got updated
   * @param accessLevel minimum level needed to be able to execute this proposal
   * @param isActive is this voting configuration active or not
   * @param votingDuration duration of the voting period in seconds
   * @param quorum min amount of votes needed to pass a proposal
   * @param differential minimal difference between you and no votes for proposal to pass
   * @param minPropositionPower minimal proposition power of a user to be able to create proposal
   **/
  event VotingConfigUpdated(
    CrossChainMandateUtils.AccessControl indexed accessLevel,
    bool indexed isActive,
    uint24 votingDuration,
    uint24 coolDownBeforeVotingStart,
    uint256 quorum,
    uint256 differential,
    uint256 minPropositionPower
  );

  /**
   * @dev
   * @param proposalId id of the proposal
   * @param creator address of the creator of the proposal
   * @param accessLevel minimum level needed to be able to execute this proposal
   * @param votingDuration duration of the voting period in seconds
   * @param ipfsHash ipfs has containing the proposal metadata information
   */
  event ProposalCreated(
    uint256 indexed proposalId,
    address indexed creator,
    CrossChainMandateUtils.AccessControl indexed accessLevel,
    uint24 votingDuration,
    bytes32 ipfsHash
  );
  /**
   * @dev
   * @param proposalId id of the proposal
   * @param snapshotBlockHash blockHash of when the proposal was created, as to be able to get the correct balances on this specific block
   * @param snapshotBlockNumber number of the block when the proposal was created
   */
  event VotingActivated(
    uint256 indexed proposalId,
    bytes32 snapshotBlockHash,
    uint256 snapshotBlockNumber
  );

  /**
   * @dev emitted when proposal change state to Queued
   * @param proposalId id of the proposal
   * @param votesFor votes for proposal
   * @param votesAgainst votes against proposal
   **/
  event ProposalQueued(
    uint256 indexed proposalId,
    uint128 votesFor,
    uint128 votesAgainst
  );

  /**
   * @dev emitted when proposal change state to Executed
   * @param proposalId id of the proposal
   **/
  event ProposalExecuted(uint256 indexed proposalId);

  /**
   * @dev emitted when proposal change state to Canceled
   * @param proposalId id of the proposal
   **/
  event ProposalCanceled(uint256 indexed proposalId);

  /**
   * @dev emitted when proposal change state to Failed
   * @param proposalId id of the proposal
   * @param votesFor votes for proposal
   * @param votesAgainst votes against proposal
   **/
  event ProposalFailed(
    uint256 indexed proposalId,
    uint128 votesFor,
    uint128 votesAgainst
  );

  /**
   * @dev emitted when a voting machine gets updated
   * @param votingPortal address of the voting portal updated
   * @param approved boolean indicating if a voting portal has been added or removed
   */
  event VotingPortalUpdated(
    address indexed votingPortal,
    bool indexed approved
  );

  /**
   * @dev emitted when a payload is successfully sent to the execution chain
   * @param proposalId id of the proposal containing the payload sent for execution
   * @param payloadId id of the payload sent for execution
   * @param mandateProvider address of the mandate provider on the execution chain
   * @param chainId id of the execution chain
   * @param payloadNumberOnProposal number of payload sent for execution, from the number of payloads contained in proposal
   * @param numberOfPayloadsOnProposal number of payloads that are in the proposal
   */
  event PayloadSent(
    uint256 indexed proposalId,
    uint40 payloadId,
    address indexed mandateProvider,
    CrossChainUtils.Chains indexed chainId,
    uint256 payloadNumberOnProposal,
    uint256 numberOfPayloadsOnProposal
  );

  /**
   * @dev method to initialize governance v3
   * @param owner address of the new owner of governance
   * @param guardian address of the new guardian of governance
   * @param votingStrategy address of the governance chain voting strategy with the logic of weighted powers
   * @param votingConfigs objects containing the information of different voting configurations depending on access level
   * @param votingPortals objects containing the information of different voting machines depending on chain id
   */
  function initialize(
    address owner,
    address guardian,
    IL1VotingStrategy votingStrategy,
    SetVotingConfigInput[] calldata votingConfigs,
    address[] calldata votingPortals
  ) external;

  /**
   * @dev method to approve new voting machines
   * @param votingPortals array of voting portal addresses to approve
   */
  function addVotingPortals(address[] memory votingPortals) external;

  /**
   * @dev method to disapprove voting machines, as to not make them usable any more.
   * @param votingPortals list of addresses of the voting machines that are no longer valid
   */
  function removeVotingPortals(address[] memory votingPortals) external;

  /**
   * @dev creates a proposal, with configuration specified in VotingConfig corresponding to the accessLevel
   * @param payloads which user propose to vote for
   * @param accessLevel which maximum access level this proposal requires
   * @param votingPortal address of the contract which will bootstrap voting, and provide results in the end
   * @param ipfsHash ipfs hash of a document with proposal description
   * @return created proposal ID
   **/
  function createProposal(
    CrossChainMandateUtils.Payload[] calldata payloads,
    CrossChainMandateUtils.AccessControl accessLevel,
    address votingPortal,
    bytes32 ipfsHash
  ) external returns (uint256);

  /**
   * @dev executes a proposal, can be called by anyone if proposal in Queued state
   * @dev and passed more then COOLDOWN_PERIOD seconds after proposal entered this state
   * @param proposalId id of the proposal
   **/
  function executeProposal(uint256 proposalId) external;

  /**
   * @dev cancels a proposal, can be initiated by guardian,
   * @dev or if proposition power of proposal creator will go below minPropositionPower specified in VotingConfig
   * @param proposalId id of the proposal
   **/
  function cancelProposal(uint256 proposalId) external;

  /**
   * @dev method to set a new votingStrategy contract
   * @param newVotingStrategy address of the new contract containing the voting a voting strategy
   */

  function setVotingStrategy(IL1VotingStrategy newVotingStrategy) external;

  /**
   * @dev method to set the voting configuration for a determined access level
   * @param votingConfigs object containing configuration for an access level
   */
  function setVotingConfigs(SetVotingConfigInput[] calldata votingConfigs)
    external;

  /**
   * @dev method to get the voting configuration from an access level
   * @param accessLevel level for which to get the configuration of a vote
   */
  function getVotingConfig(CrossChainMandateUtils.AccessControl accessLevel)
    external
    view
    returns (VotingConfig memory);

  /// @dev gets the address of the current network message manager (cross chain manager or same chain manager)
  function CROSS_CHAIN_MANAGER() external view returns (address);

  /**
   * @dev method to get the cool down period between queuing and execution
   * @return time in seconds
   */
  function COOLDOWN_PERIOD() external view returns (uint256);

  /**
   * @dev method to get the precision divider used to remove unneeded decimals
   * @return decimals of 1 ether (18)
   */
  function PRECISION_DIVIDER() external view returns (uint256);

  /**
   * @dev method to get the expiration time from creation from which the proposal will be invalid
   * @return time in seconds
   */
  function PROPOSAL_EXPIRATION_TIME() external view returns (uint256);

  /**
   * @dev method to get the name of the contract
   * @return name string
   */
  function NAME() external view returns (string memory);

  /**
   * @dev method to get the proposal identified by passed id
   * @param proposalId id of the proposal to get the information of
   * @return proposal object containing all the information
   */
  function getProposal(uint256 proposalId)
    external
    view
    returns (Proposal memory);

  /**
   * @dev address of the current voting strategy to use on the governance
   * @return address of the voting strategy
   */
  function getVotingStrategy() external view returns (IL1VotingStrategy);

  /**
   * @dev proposals counter.
   * @return the current number proposals created
   */
  function getProposalsCount() external view returns (uint256);

  /**
   * @dev method to get a voting machine for chain id
   * @param votingPortal address of the voting portal to check if approved
   */
  function isVotingPortalApproved(address votingPortal)
    external
    view
    returns (bool);

  /**
   * @dev method to queue a proposal for execution
   * @param proposalId the id of the proposal to queue
   * @param forVotes number of votes in favor of the proposal
   * @param againstVotes number of votes against of the proposal
   */
  function queueProposal(
    uint256 proposalId,
    uint128 forVotes,
    uint128 againstVotes
  ) external;

  /**
   * @dev method to send proposal to votingMachine
   * @param proposalId id of the proposal to start the voting on
   */
  function activateVoting(uint256 proposalId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IL1VotingStrategy {
  /**
   * @dev method to get the full weighted voting power of an user
   * @param user address where we want to get the power from
   */
  function getFullVotingPower(address user) external view returns (uint256);

  /**
   * @dev method to get the full weighted proposal power of an user
   * @param user address where we want to get the power from
   */
  function getFullPropositionPower(address user)
    external
    view
    returns (uint256);
}