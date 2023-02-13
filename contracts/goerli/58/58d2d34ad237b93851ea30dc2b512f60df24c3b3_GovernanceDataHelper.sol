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

pragma solidity ^0.8.0;

import '../CrossChainUtils.sol';

/// @dev interface needed by the portals on the receiving side to be able to receive bridged messages
interface IBaseReceiverPortal {
  /**
   * @dev method called by CrossChainManager when a message has been confirmed
   * @param originSender address of the sender of the bridged message
   * @param originChainId id of the chain where the message originated
   * @param message bytes bridged containing the desired information
   */
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainForwarder {
  /**
   * @dev object storing the connected pair of bridge adapters, on current and destination chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current network
   */
  struct ChainIdBridgeConfig {
    address destinationBridgeAdapter;
    address currentChainBridgeAdapter;
  }

  /**
   * @dev object with the necessary information to remove bridge adapters
   * @param bridgeAdapter address of the bridge adapter to remove
   * @param chainIds array of chain ids where the bridge adapter connects
   */
  struct BridgeAdapterToDisable {
    address bridgeAdapter;
    CrossChainUtils.Chains[] chainIds;
  }

  /**
   * @dev object storing the pair bridgeAdapter (current deployed chain) destination chain bridge adapter configuration
   * @param currentChainBridgeAdapter address of the bridge adapter deployed on current chain
   * @param destinationBridgeAdapter address of the bridge adapter on the destination chain
   * @param dstChainId id of the destination chain using our own nomenclature
   */
  struct BridgeAdapterConfigInput {
    address currentChainBridgeAdapter;
    address destinationBridgeAdapter;
    CrossChainUtils.Chains destinationChainId;
  }

  /**
   * @dev emitted when a bridge adapter failed to send a message
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   * @param returndata bytes with error information
   */
  event AdapterFailed(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message,
    bytes returndata
  );

  /**
   * @dev emitted when a message is successfully forwarded through a bridge adapter
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter that failed (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param destinationChainId id of destination chain
   * @param message bytes intended to be bridged
   */
  event MessageForwarded(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address indexed destinationBridgeAdapter,
    bytes message
  );

  /**
   * @dev emitted when a bridge adapter has been added to the allowed list
   * @param destinationChainId id of the destination chain in our notation
   * @param bridgeAdapter address of the bridge adapter added (deployed on current network)
   * @param destinationBridgeAdapter address of the connected bridge adapter on destination chain
   * @param allowed boolean indicating if the bridge adapter is allowed or disallowed
   */
  event BridgeAdapterUpdated(
    CrossChainUtils.Chains indexed destinationChainId,
    address indexed bridgeAdapter,
    address destinationBridgeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when a sender has been updated
   * @param sender address of the updated sender
   * @param isApproved boolean that indicates if the sender has been approved or removed
   */
  event SenderUpdated(address indexed sender, bool indexed isApproved);

  /// @dev method to get the current sent message nonce
  function currentNonce() external view returns (uint256);

  /**
   * @dev method to check if a message has been previously forwarded.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param message bytes that need to be bridged
   */
  function isMessageForwarded(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    bytes memory message
  ) external view returns (bool);

  /**
   * @dev method called to initiate message forwarding to other networks.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function forwardMessage(
    CrossChainUtils.Chains destinationChainId,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @dev method called to re forward a previously sent message.
   * @param destinationChainId id of the destination chain where the message needs to be bridged
   * @param origin address where the message originates from
   * @param destination address where the message is intended for
   * @param gasLimit gas cost on receiving side of the message
   * @param message bytes that need to be bridged
   */
  function retryMessage(
    CrossChainUtils.Chains destinationChainId,
    address origin,
    address destination,
    uint256 gasLimit,
    bytes memory message
  ) external;

  /**
   * @dev method to enable bridge adapters
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function enableBridgeAdapters(
    BridgeAdapterConfigInput[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to disable bridge adapters
   * @param bridgeAdapters array of bridge adapter addresses to disable
   */
  function disableBridgeAdapters(
    BridgeAdapterToDisable[] memory bridgeAdapters
  ) external;

  /**
   * @dev method to remove sender addresses
   * @param senders list of addresses to remove
   */
  function removeSenders(address[] memory senders) external;

  /**
   * @dev method to approve new sender addresses
   * @param senders list of addresses to approve
   */
  function approveSenders(address[] memory senders) external;

  /**
   * @dev method to get all the bridge adapters of a chain
   * @param chainId id of the chain we want to get the adateprs from
   * @return an array of chain configurations where the bridge adapter can communicate
   */
  function getBridgeAdaptersByChain(
    CrossChainUtils.Chains chainId
  ) external view returns (ChainIdBridgeConfig[] memory);

  /**
   * @dev method to get if a sender is approved
   * @param sender address that we want to check if approved
   */
  function isSenderApproved(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICrossChainForwarder.sol';
import './ICrossChainReceiver.sol';

interface ICrossChainManager is ICrossChainForwarder, ICrossChainReceiver {
  /**
   * @dev method called to initialize the proxy
   * @param owner address of the owner of the cross chain manager
   * @param guardian address of the guardian of the cross chain manager
   * @param clEmergencyOracle address of the chainlink emergency oracle
   * @param initialRequiredConfirmations number of confirmations the messages need to be accepted as valid
   * @param receiverBridgeAdaptersToAllow array of addresses of the bridge adapters that can receive messages
   * @param forwarderBridgeAdaptersToEnable array specifying for every bridgeAdapter, the destinations it can have
   * @param sendersToApprove array of addresses to allow as forwarders
   */
  function initialize(
    address owner,
    address guardian,
    address clEmergencyOracle,
    uint256 initialRequiredConfirmations,
    address[] memory receiverBridgeAdaptersToAllow,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    address[] memory sendersToApprove
  ) external;

  /**
   * @dev method called to rescue tokens sent erroneously to the contract. Only callable by owner
   * @param erc20Token address of the token to rescue
   * @param to address to send the tokens
   * @param amount of tokens to rescue
   */
  function emergencyTokenTransfer(
    address erc20Token,
    address to,
    uint256 amount
  ) external;

  /**
   * @dev method called to rescue ether sent erroneously to the contract. Only callable by owner
   * @param to address to send the eth
   * @param amount of eth to rescue
   */
  function emergencyEtherTransfer(address to, uint256 amount) external;

  /**
  * @dev method to check if there is a new emergency state, indicated by chainlink emergency oracle.
         This method is callable by anyone as a new emergency will be determined by the oracle, and this way
         it will be easier / faster to enter into emergency.
  */
  function solveEmergency(
    uint256 newConfirmations,
    uint120 newValidityTimestamp,
    address[] memory receiverBridgeAdaptersToAllow,
    address[] memory receiverBridgeAdaptersToDisallow,
    address[] memory sendersToApprove,
    address[] memory sendersToRemove,
    BridgeAdapterConfigInput[] memory forwarderBridgeAdaptersToEnable,
    BridgeAdapterToDisable[] memory forwarderBridgeAdaptersToDisable
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {CrossChainUtils} from '../CrossChainUtils.sol';

interface ICrossChainReceiver {
  /**
   * @dev object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   */
  struct InternalBridgedMessageStateWithoutAdapters {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
  }
  /**
   * @dev object that stores the internal information of the message
   * @param confirmations number of times that this message has been bridged
   * @param bridgedByAdapterNonce stores the nonce of when the message has been bridged by a determined bridge adapter
   * @param delivered boolean indicating if the bridged message has been delivered to the destination
   * @param bridgedByAdapter list of bridge adapters that have bridged the message
   */
  struct InternalBridgedMessage {
    uint120 confirmations;
    uint120 firstBridgedAt;
    bool delivered;
    mapping(address => bool) bridgedByAdapter;
  }

  /**
   * @dev emitted when a message has reached the necessary number of confirmations
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated
   * @param message bytes confirmed
   */
  event MessageConfirmed(
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message
  );

  /**
   * @dev emitted when a message has been received successfully
   * @param internalId message id assigned on the manager, used for internal purposes: hash(to, from, message)
   * @param bridgeAdapter address of the bridge adapter who received the message (deployed on current network)
   * @param msgDestination address of consumer of the message
   * @param msgOrigin address where the message originated (CrossChainManager on origin chain)
   * @param message bytes bridged
   * @param confirmations number of current confirmations for this message
   */
  event MessageReceived(
    bytes32 internalId,
    address indexed bridgeAdapter,
    address indexed msgDestination,
    address indexed msgOrigin,
    bytes message,
    uint256 confirmations
  );

  /**
   * @dev emitted when a bridge adapter gets disallowed
   * @param brigeAdapter address of the disallowed bridge adapter
   * @param allowed boolean indicating if the bridge adapter has been allowed or disallowed
   */
  event ReceiverBridgeAdaptersUpdated(
    address indexed brigeAdapter,
    bool indexed allowed
  );

  /**
   * @dev emitted when number of confirmations needed to validate a message changes
   * @param newConfirmations number of new confirmations needed for a message to be valid
   */
  event ConfirmationsUpdated(uint256 newConfirmations);

  /**
   * @dev emitted when a new timestamp for invalidations gets set
   * @param invalidTimestamp timestamp to invalidate previous messages
   */
  event NewInvalidation(uint256 invalidTimestamp);

  /// @dev method to get the needed confirmations for a message to be accepted as valid
  function requiredConfirmations() external view returns (uint256);

  /// @dev method to get the timestamp from where the messages will be valid
  function validityTimestamp() external view returns (uint120);

  /**
   * @dev method to get if a bridge adapter is allowed
   * @param bridgeAdapter address of the brige adapter to check
   * @return boolean indicating if brige adapter is allowed
   */
  function isReceiverBridgeAdapterAllowed(address bridgeAdapter)
    external
    view
    returns (bool);

  /**
   * @dev  method to get the internal message information
   * @param internalId hash(originChain + payload) identifying the message internally
   * @return number of confirmations of internal message identified by internalId and the updated timestamp
   */
  function getInternalMessageState(bytes32 internalId)
    external
    view
    returns (InternalBridgedMessageStateWithoutAdapters memory);

  /**
   * @dev method to get if message has been received by bridge adapter
   * @param internalId id of the message as stored internally
   * @param bridgeAdapter address of the bridge adapter to check if it has bridged the message
   * return array of addresses
   */
  function isInternalMessageReceivedByAdapter(
    bytes32 internalId,
    address bridgeAdapter
  ) external view returns (bool);

  /**
   * @dev method to set a new timestamp from where the messages will be valid.
   * @param newValidityTimestamp timestamp where all the previous unconfirmed messages must be invalidated.
   */
  function updateMessagesValidityTimestamp(uint120 newValidityTimestamp)
    external;

  /**
   * @dev method to update the number of confirmations necessary for the messages to be accepted as valid
   * @param newConfirmations new number of needed confirmations
   */
  function updateConfirmations(uint256 newConfirmations) external;

  /**
   * @dev method that registers a received message, updates the confirmations, and sets it as valid if number
   of confirmations has been reached.
   * @param payload bytes of the payload, containing the information to operate with it
   */
  function receiveCrossChainMessage(
    bytes memory payload,
    CrossChainUtils.Chains originChainId
  ) external;

  /**
   * @dev method to add bridge adapters to the allowed list
   * @param bridgeAdapters array of new bridge adapter configurations
   */
  function allowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;

  /**
   * @dev method to remove bridge adapters from the allowed list
   * @param bridgeAdapters array of bridge adapter addresses to remove from the allow list
   */
  function disallowReceiverBridgeAdapters(address[] memory bridgeAdapters)
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ICrossChainManager} from 'ghost-crosschain-infra/contracts/interfaces/ICrossChainManager.sol';
import {IGovernanceCore} from '../interfaces/IGovernanceCore.sol';
import {IVotingPortal, CrossChainUtils, IBaseReceiverPortal} from '../interfaces/IVotingPortal.sol';

/**
 * @title SameChainMessageRegistry
 * @author BGD Labs
 * @dev Contract with the knowledge on how to initialize and get votes, from a vote that happened on a different or same chain.
 */
contract VotingPortal is IVotingPortal {
  address public immutable CROSS_CHAIN_MANAGER;
  address public immutable GOVERNANCE;
  address public immutable VOTING_MACHINE;
  uint256 public immutable GAS_LIMIT;
  CrossChainUtils.Chains public immutable VOTING_MACHINE_CHAIN_ID;

  /**
   * @param crossChainManager address of current network message manager (cross chain manager or same chain manager)
   */
  constructor(
    address crossChainManager,
    address governance,
    address votingMachine,
    uint256 gasLimit,
    CrossChainUtils.Chains votingMachineChainId
  ) {
    CROSS_CHAIN_MANAGER = crossChainManager;
    GOVERNANCE = governance;
    VOTING_MACHINE = votingMachine;
    GAS_LIMIT = gasLimit;
    VOTING_MACHINE_CHAIN_ID = votingMachineChainId;
  }

  /// @inheritdoc IBaseReceiverPortal
  /// @dev pushes the voting result and queues the proposal identified by proposalId
  function receiveCrossChainMessage(
    address originSender,
    CrossChainUtils.Chains originChainId,
    bytes memory message
  ) external {
    require(
      msg.sender == CROSS_CHAIN_MANAGER &&
        originSender == VOTING_MACHINE &&
        originChainId == VOTING_MACHINE_CHAIN_ID,
      'WRONG_MESSAGE_ORIGIN'
    );

    (uint256 proposalId, uint128 forVotes, uint128 againstVotes) = abi.decode(
      message,
      (uint256, uint128, uint128)
    );

    IGovernanceCore(GOVERNANCE).queueProposal(
      proposalId,
      forVotes,
      againstVotes
    );
  }

  /// @inheritdoc IVotingPortal
  function forwardStartVotingMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external {
    bytes memory message = abi.encode(proposalId, blockHash, votingDuration);
    _sendMessage(msg.sender, MessageType.Proposal, message);
  }

  /// @inheritdoc IVotingPortal
  function forwardVoteMessage(
    uint256 proposalId,
    address voter,
    bool support,
    address[] memory votingTokens
  ) external {
    bytes memory message = abi.encode(proposalId, voter, support, votingTokens);
    _sendMessage(msg.sender, MessageType.Vote, message);
  }

  function _sendMessage(
    address caller,
    MessageType messageType,
    bytes memory message
  ) internal {
    require(caller == GOVERNANCE, 'CALLER_NOT_GOVERNANCE');
    bytes memory messageWithType = abi.encode(messageType, message);

    ICrossChainManager(CROSS_CHAIN_MANAGER).forwardMessage(
      VOTING_MACHINE_CHAIN_ID,
      VOTING_MACHINE,
      GAS_LIMIT,
      messageWithType
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainMandateUtils} from 'aave-crosschain-mandates/contracts/CrossChainMandateUtils.sol';
import {IGovernanceDataHelper} from './interfaces/IGovernanceDataHelper.sol';
import {IGovernanceCore} from '../../interfaces/IGovernanceCore.sol';
import {VotingPortal} from '../VotingPortal.sol';

contract GovernanceDataHelper is IGovernanceDataHelper {
  function getProposalsData(
    IGovernanceCore govCore,
    uint256 from, // if from is 0 then uses the latest id
    uint256 to, // if to is 0 then will be ignored
    uint256 pageSize
  ) external view returns (Proposal[] memory) {
    if (from == 0) {
      from = govCore.getProposalsCount();
      if (from == 0) {
        return new Proposal[](0);
      }
    } else {
      from += 1;
    }
    require(from >= to, 'from >= to');
    uint256 tempTo = from > pageSize ? from - pageSize : 0;
    if (tempTo > to) {
      to = tempTo;
    }
    pageSize = from - to;
    Proposal[] memory proposals = new Proposal[](pageSize);
    IGovernanceCore.Proposal memory proposalData;

    for (uint256 i = 0; i < pageSize; i++) {
      proposalData = govCore.getProposal(from - i - 1);
      VotingPortal votingPortal = VotingPortal(proposalData.votingPortal);
      proposals[i] = Proposal({
        id: from - i - 1,
        votingChainId: votingPortal.VOTING_MACHINE_CHAIN_ID(),
        proposalData: proposalData
      });
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
    uint256 cooldownPeriod = govCore.COOLDOWN_PERIOD();
    uint256 expirationTime = govCore.PROPOSAL_EXPIRATION_TIME();

    return
      Constants({
        votingConfigs: votingConfigs,
        precisionDivider: precisionDivider,
        cooldownPeriod: cooldownPeriod,
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
    CrossChainUtils.Chains votingChainId;
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
    uint256 from,
    uint256 to,
    uint256 pageSize
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
   * @notice emitted when a vote is successfully sent to voting chain
   * @param proposalId id of the proposal the vote is for
   * @param voter address that wants to vote on a proposal
   * @param support indicates if vote is in favor or against the proposal
   * @param votingTokens list of token addresses to use for the vote
   */
  event VoteForwarded(
    uint256 indexed proposalId,
    address indexed voter,
    bool indexed support,
    address[] votingTokens
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
  function addVotingPortals(address[] calldata votingPortals) external;

  /**
   * @dev method to disapprove voting machines, as to not make them usable any more.
   * @param votingPortals list of addresses of the voting machines that are no longer valid
   */
  function removeVotingPortals(address[] calldata votingPortals) external;

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
   * @dev method to get the the voting tokens cap
   * @return cap for the voting tokens
   */
  function VOTING_TOKENS_CAP() external view returns (uint256);

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

  /**
   * @dev method that enables smart contracts that are on governance chain to vote on
             l2 voting machine
   * @param proposalId id of the proposal to vote of
   * @param support boolean indicating if the vote is in favor or against the proposal
   * @param votingTokens list of token addresses the voter wants to vote with
   */
  function voteViaBridge(
    uint256 proposalId,
    bool support,
    address[] memory votingTokens
  ) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrossChainUtils} from 'ghost-crosschain-infra/contracts/CrossChainUtils.sol';
import {IBaseReceiverPortal} from 'ghost-crosschain-infra/contracts/interfaces/IBaseReceiverPortal.sol';

interface IVotingPortal is IBaseReceiverPortal {
  enum MessageType {
    Null, // leave empty
    Proposal, // indicates that the message is to bridge a proposal configuration
    Vote // indicates that the message is to bridge a vote
  }

  /// @dev get the chain id where the voting machine which is connected to, is deployed
  function VOTING_MACHINE_CHAIN_ID()
    external
    view
    returns (CrossChainUtils.Chains);

  /// @dev gets the address of the voting machine on the destination network
  function VOTING_MACHINE() external view returns (address);

  /// @dev gets the address of the connected governance
  function GOVERNANCE() external view returns (address);

  /// @dev gets the address of the current network message manager (cross chain manager or same chain manager)
  function CROSS_CHAIN_MANAGER() external view returns (address);

  /// @dev gas limit to be used on receiving side of bridging voting configurations
  function GAS_LIMIT() external view returns (uint256);

  /**
   * @notice method to bridge the vote configuration to voting chain, so a vote can be started.
   * @param proposalId id of the proposal bridged to start the vote on
   * @param blockHash hash of the block on L1 when the proposal was activated for voting
   * @param votingDuration duration in seconds of the vote
   **/
  function forwardStartVotingMessage(
    uint256 proposalId,
    bytes32 blockHash,
    uint24 votingDuration
  ) external;

  /**
   * @notice method to bridge a vote to the voting chain
   * @param proposalId id of the proposal bridged to start the vote on
   * @param voter address that wants to emit the vote
   * @param support indicates if vote is in favor or against the proposal
   * @param votingTokens list of token addresses that the voter will use for voting
   **/
  function forwardVoteMessage(
    uint256 proposalId,
    address voter,
    bool support,
    address[] memory votingTokens
  ) external;
}