// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import { BaseStrategy, IBaseStrategy } from "./BaseStrategy.sol";
import { BaseQuorumPercent } from "./BaseQuorumPercent.sol";
import { BaseVotingBasisPercent } from "./BaseVotingBasisPercent.sol";

 /**
  * An [Azorius](./Azorius.md) [BaseStrategy](./BaseStrategy.md) implementation that 
  * enables linear (i.e. 1 to 1) token voting. Each token delegated to a given address 
  * in an `ERC20Votes` token equals 1 vote for a Proposal.
  */
contract LinearERC20Voting is BaseStrategy, BaseQuorumPercent, BaseVotingBasisPercent {

    /**
     * The voting options for a Proposal.
     */
    enum VoteType {
        NO,     // disapproves of executing the Proposal
        YES,    // approves of executing the Proposal
        ABSTAIN // neither YES nor NO, i.e. voting "present"
    }

    /**
     * Defines the current state of votes on a particular Proposal.
     */
    struct ProposalVotes {
        uint32 votingStartBlock; // block that voting starts at
        uint32 votingEndBlock; // block that voting ends
        uint256 noVotes; // current number of NO votes for the Proposal
        uint256 yesVotes; // current number of YES votes for the Proposal
        uint256 abstainVotes; // current number of ABSTAIN votes for the Proposal
        mapping(address => bool) hasVoted; // whether a given address has voted yet or not
    }

    IVotes public governanceToken;

    /** Number of blocks a new Proposal can be voted on. */
    uint32 public votingPeriod;

    /** Voting weight required to be able to submit Proposals. */
    uint256 public requiredProposerWeight;

    /** `proposalId` to `ProposalVotes`, the voting state of a Proposal. */
    mapping(uint256 => ProposalVotes) internal proposalVotes;

    event VotingPeriodUpdated(uint32 votingPeriod);
    event RequiredProposerWeightUpdated(uint256 requiredProposerWeight);
    event ProposalInitialized(uint32 proposalId, uint32 votingEndBlock);
    event Voted(address voter, uint32 proposalId, uint8 voteType, uint256 weight);

    error InvalidProposal();
    error VotingEnded();
    error AlreadyVoted();
    error InvalidVote();
    error InvalidTokenAddress();

    /**
     * Sets up the contract with its initial parameters.
     *
     * @param initializeParams encoded initialization parameters: `address _owner`,
     * `ERC20Votes _governanceToken`, `address _azoriusModule`, `uint256 _votingPeriod`,
     * `uint256 _quorumNumerator`, `uint256 _basisNumerator`
     */
    function setUp(bytes memory initializeParams) public override initializer {
        (
            address _owner,
            IVotes _governanceToken,
            address _azoriusModule,
            uint32 _votingPeriod,
            uint256 _requiredProposerWeight,
            uint256 _quorumNumerator,
            uint256 _basisNumerator
        ) = abi.decode(
                initializeParams,
                (address, IVotes, address, uint32, uint256, uint256, uint256)
            );
        if (address(_governanceToken) == address(0))
            revert InvalidTokenAddress();

        governanceToken = _governanceToken;
        __Ownable_init();
        transferOwnership(_owner);
        _setAzorius(_azoriusModule);
        _updateQuorumNumerator(_quorumNumerator);
        _updateBasisNumerator(_basisNumerator);
        _updateVotingPeriod(_votingPeriod);
        _updateRequiredProposerWeight(_requiredProposerWeight);

        emit StrategySetUp(_azoriusModule, _owner);
    }

    /**
     * Updates the voting time period for new Proposals.
     *
     * @param _votingPeriod voting time period (in blocks)
     */
    function updateVotingPeriod(uint32 _votingPeriod) external onlyOwner {
        _updateVotingPeriod(_votingPeriod);
    }

    /**
     * Updates the voting weight required to submit new Proposals.
     *
     * @param _requiredProposerWeight required token voting weight
     */
    function updateRequiredProposerWeight(uint256 _requiredProposerWeight) external onlyOwner {
        _updateRequiredProposerWeight(_requiredProposerWeight);
    }

    /**
     * Casts votes for a Proposal, equal to the caller's token delegation.
     *
     * @param _proposalId id of the Proposal to vote on
     * @param _voteType Proposal support as defined in VoteType (NO, YES, ABSTAIN)
     */
    function vote(uint32 _proposalId, uint8 _voteType) external {
        _vote(
            _proposalId,
            msg.sender,
            _voteType,
            getVotingWeight(msg.sender, _proposalId)
        );
    }

    /**
     * Returns the current state of the specified Proposal.
     *
     * @param _proposalId id of the Proposal
     * @return noVotes current count of "NO" votes
     * @return yesVotes current count of "YES" votes
     * @return abstainVotes current count of "ABSTAIN" votes
     * @return startBlock block number voting starts
     * @return endBlock block number voting ends
     */
    function getProposalVotes(uint32 _proposalId) external view
        returns (
            uint256 noVotes,
            uint256 yesVotes,
            uint256 abstainVotes,
            uint32 startBlock,
            uint32 endBlock,
            uint256 votingSupply
        )
    {
        noVotes = proposalVotes[_proposalId].noVotes;
        yesVotes = proposalVotes[_proposalId].yesVotes;
        abstainVotes = proposalVotes[_proposalId].abstainVotes;
        startBlock = proposalVotes[_proposalId].votingStartBlock;
        endBlock = proposalVotes[_proposalId].votingEndBlock;
        votingSupply = getProposalVotingSupply(_proposalId);
    }

    /** @inheritdoc BaseStrategy*/
    function initializeProposal(bytes memory _data) public virtual override onlyAzorius {
        uint32 proposalId = abi.decode(_data, (uint32));
        uint32 _votingEndBlock = uint32(block.number) + votingPeriod;

        proposalVotes[proposalId].votingEndBlock = _votingEndBlock;
        proposalVotes[proposalId].votingStartBlock = uint32(block.number);

        emit ProposalInitialized(proposalId, _votingEndBlock);
    }
    
    /**
     * Returns whether an address has voted on the specified Proposal.
     *
     * @param _proposalId id of the Proposal to check
     * @param _address address to check
     * @return bool true if the address has voted on the Proposal, otherwise false
     */
    function hasVoted(uint32 _proposalId, address _address) public view returns (bool) {
        return proposalVotes[_proposalId].hasVoted[_address];
    }

    /** @inheritdoc BaseStrategy*/
    function isPassed(uint32 _proposalId) public view override returns (bool) {
        return (
            block.number > proposalVotes[_proposalId].votingEndBlock && // voting period has ended
            meetsQuorum(getProposalVotingSupply(_proposalId), proposalVotes[_proposalId].yesVotes, proposalVotes[_proposalId].abstainVotes) && // yes + abstain votes meets the quorum
            meetsBasis(proposalVotes[_proposalId].yesVotes, proposalVotes[_proposalId].noVotes) // yes votes meets the basis
        );
    }

    /**
     * Returns a snapshot of total voting supply for a given Proposal.  Because token supplies can change,
     * it is necessary to calculate quorum from the supply available at the time of the Proposal's creation,
     * not when it is being voted on passes / fails.
     *
     * @param _proposalId id of the Proposal
     * @return uint256 voting supply snapshot for the given _proposalId
     */
    function getProposalVotingSupply(uint32 _proposalId) public view virtual returns (uint256) {
        return governanceToken.getPastTotalSupply(proposalVotes[_proposalId].votingStartBlock);
    }

    /**
     * Calculates the voting weight an address has for a specific Proposal.
     *
     * @param _voter address of the voter
     * @param _proposalId id of the Proposal
     * @return uint256 the address' voting weight
     */
    function getVotingWeight(address _voter, uint32 _proposalId) public view returns (uint256) {
        return
            governanceToken.getPastVotes(
                _voter,
                proposalVotes[_proposalId].votingStartBlock
            );
    }

    /** @inheritdoc BaseStrategy*/
    function isProposer(address _address) public view override returns (bool) {
        return governanceToken.getPastVotes(
            _address,
            block.number - 1
        ) >= requiredProposerWeight;
    }

    /** @inheritdoc BaseStrategy*/
    function votingEndBlock(uint32 _proposalId) public view override returns (uint32) {
      return proposalVotes[_proposalId].votingEndBlock;
    }

    /** Internal implementation of `updateVotingPeriod`. */
    function _updateVotingPeriod(uint32 _votingPeriod) internal {
        votingPeriod = _votingPeriod;
        emit VotingPeriodUpdated(_votingPeriod);
    }

    /** Internal implementation of `updateRequiredProposerWeight`. */
    function _updateRequiredProposerWeight(uint256 _requiredProposerWeight) internal {
        requiredProposerWeight = _requiredProposerWeight;
        emit RequiredProposerWeightUpdated(_requiredProposerWeight);
    }

    /**
     * Internal function for casting a vote on a Proposal.
     *
     * @param _proposalId id of the Proposal
     * @param _voter address casting the vote
     * @param _voteType vote support, as defined in VoteType
     * @param _weight amount of voting weight cast, typically the
     *          total number of tokens delegated
     */
    function _vote(uint32 _proposalId, address _voter, uint8 _voteType, uint256 _weight) internal {
        if (proposalVotes[_proposalId].votingEndBlock == 0)
            revert InvalidProposal();
        if (block.number > proposalVotes[_proposalId].votingEndBlock)
            revert VotingEnded();
        if (proposalVotes[_proposalId].hasVoted[_voter]) revert AlreadyVoted();

        proposalVotes[_proposalId].hasVoted[_voter] = true;

        if (_voteType == uint8(VoteType.NO)) {
            proposalVotes[_proposalId].noVotes += _weight;
        } else if (_voteType == uint8(VoteType.YES)) {
            proposalVotes[_proposalId].yesVotes += _weight;
        } else if (_voteType == uint8(VoteType.ABSTAIN)) {
            proposalVotes[_proposalId].abstainVotes += _weight;
        } else {
            revert InvalidVote();
        }

        emit Voted(_voter, _proposalId, _voteType, _weight);
    }

    /** @inheritdoc BaseQuorumPercent*/
    function quorumVotes(uint32 _proposalId) public view override returns (uint256) {
        return quorumNumerator * getProposalVotingSupply(_proposalId) / QUORUM_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { IAzorius } from "./interfaces/IAzorius.sol";
import { IBaseStrategy } from "./interfaces/IBaseStrategy.sol";
import { FactoryFriendly } from "@gnosis.pm/zodiac/contracts/factory/FactoryFriendly.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * The base abstract contract for all voting strategies in Azorius.
 */
abstract contract BaseStrategy is OwnableUpgradeable, FactoryFriendly, IBaseStrategy {

    event AzoriusSet(address indexed azoriusModule);
    event StrategySetUp(address indexed azoriusModule, address indexed owner);

    error OnlyAzorius();

    IAzorius public azoriusModule;

    /**
     * Ensures that only the [Azorius](./Azorius.md) contract that pertains to this 
     * [BaseStrategy](./BaseStrategy.md) can call functions on it.
     */
    modifier onlyAzorius() {
        if (msg.sender != address(azoriusModule)) revert OnlyAzorius();
        _;
    }

    constructor() {
      _disableInitializers();
    }

    /** @inheritdoc IBaseStrategy*/
    function setAzorius(address _azoriusModule) external onlyOwner {
        azoriusModule = IAzorius(_azoriusModule);
        emit AzoriusSet(_azoriusModule);
    }

    /** @inheritdoc IBaseStrategy*/
    function initializeProposal(bytes memory _data) external virtual;

    /** @inheritdoc IBaseStrategy*/
    function isPassed(uint32 _proposalId) external view virtual returns (bool);

    /** @inheritdoc IBaseStrategy*/
    function isProposer(address _address) external view virtual returns (bool);

    /** @inheritdoc IBaseStrategy*/
    function votingEndBlock(uint32 _proposalId) external view virtual returns (uint32);

    /**
     * Sets the address of the [Azorius](Azorius.md) module contract.
     *
     * @param _azoriusModule address of the Azorius module
     */
    function _setAzorius(address _azoriusModule) internal {
        azoriusModule = IAzorius(_azoriusModule);
        emit AzoriusSet(_azoriusModule);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * An Azorius extension contract that enables percent based quorums.
 * Intended to be implemented by [BaseStrategy](./BaseStrategy.md) implementations.
 */
abstract contract BaseQuorumPercent is OwnableUpgradeable {
    
    /** The numerator to use when calculating quorum (adjustable). */
    uint256 public quorumNumerator;

    /** The denominator to use when calculating quorum (1,000,000). */
    uint256 public constant QUORUM_DENOMINATOR = 1_000_000;

    /** Ensures the numerator cannot be larger than the denominator. */
    error InvalidQuorumNumerator();

    event QuorumNumeratorUpdated(uint256 quorumNumerator);

    /** 
     * Updates the quorum required for future Proposals.
     *
     * @param _quorumNumerator numerator to use when calculating quorum (over 1,000,000)
     */
    function updateQuorumNumerator(uint256 _quorumNumerator) public virtual onlyOwner {
        _updateQuorumNumerator(_quorumNumerator);
    }

    /** Internal implementation of `updateQuorumNumerator`. */
    function _updateQuorumNumerator(uint256 _quorumNumerator) internal virtual {
        if (_quorumNumerator > QUORUM_DENOMINATOR)
            revert InvalidQuorumNumerator();

        quorumNumerator = _quorumNumerator;

        emit QuorumNumeratorUpdated(_quorumNumerator);
    }

    /**
     * Calculates whether a vote meets quorum. This is calculated based on yes votes + abstain
     * votes.
     *
     * @param _totalSupply the total supply of tokens
     * @param _yesVotes number of votes in favor
     * @param _abstainVotes number of votes abstaining
     * @return bool whether the total number of yes votes + abstain meets the quorum
     */
    function meetsQuorum(uint256 _totalSupply, uint256 _yesVotes, uint256 _abstainVotes) public view returns (bool) {
        return _yesVotes + _abstainVotes >= (_totalSupply * quorumNumerator) / QUORUM_DENOMINATOR;
    }

    /**
     * Calculates the total number of votes required for a proposal to meet quorum.
     * 
     * @param _proposalId The ID of the proposal to get quorum votes for
     * @return uint256 The quantity of votes required to meet quorum
     */
    function quorumVotes(uint32 _proposalId) public view virtual returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * An Azorius extension contract that enables percent based voting basis calculations.
 *
 * Intended to be implemented by BaseStrategy implementations, this allows for voting strategies
 * to dictate any basis strategy for passing a Proposal between >50% (simple majority) to 100%.
 *
 * See https://en.wikipedia.org/wiki/Voting#Voting_basis.
 * See https://en.wikipedia.org/wiki/Supermajority.
 */
abstract contract BaseVotingBasisPercent is OwnableUpgradeable {
    
    /** The numerator to use when calculating basis (adjustable). */
    uint256 public basisNumerator;

    /** The denominator to use when calculating basis (1,000,000). */
    uint256 public constant BASIS_DENOMINATOR = 1_000_000;

    error InvalidBasisNumerator();

    event BasisNumeratorUpdated(uint256 basisNumerator);

    /**
     * Updates the `basisNumerator` for future Proposals.
     *
     * @param _basisNumerator numerator to use
     */
    function updateBasisNumerator(uint256 _basisNumerator) public virtual onlyOwner {
        _updateBasisNumerator(_basisNumerator);
    }

    /** Internal implementation of `updateBasisNumerator`. */
    function _updateBasisNumerator(uint256 _basisNumerator) internal virtual {
        if (_basisNumerator > BASIS_DENOMINATOR || _basisNumerator < BASIS_DENOMINATOR / 2)
            revert InvalidBasisNumerator();

        basisNumerator = _basisNumerator;

        emit BasisNumeratorUpdated(_basisNumerator);
    }

    /**
     * Calculates whether a vote meets its basis.
     *
     * @param _yesVotes number of votes in favor
     * @param _noVotes number of votes against
     * @return bool whether the yes votes meets the set basis
     */
    function meetsBasis(uint256 _yesVotes, uint256 _noVotes) public view returns (bool) {
        return _yesVotes > (_yesVotes + _noVotes) * basisNumerator / BASIS_DENOMINATOR;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

import { Enum } from "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

/**
 * The base interface for the Azorius governance Safe module.
 * Azorius conforms to the Zodiac pattern for Safe modules: https://github.com/gnosis/zodiac
 *
 * Azorius manages the state of Proposals submitted to a DAO, along with the associated strategies
 * ([BaseStrategy](../BaseStrategy.md)) for voting that are enabled on the DAO.
 *
 * Any given DAO can support multiple voting BaseStrategies, and these strategies are intended to be
 * as customizable as possible.
 *
 * Proposals begin in the `ACTIVE` state and will ultimately end in either
 * the `EXECUTED`, `EXPIRED`, or `FAILED` state.
 *
 * `ACTIVE` - a new proposal begins in this state, and stays in this state
 *          for the duration of its voting period.
 *
 * `TIMELOCKED` - A proposal that passes enters the `TIMELOCKED` state, during which
 *          it cannot yet be executed.  This is to allow time for token holders
 *          to potentially exit their position, as well as parent DAOs time to
 *          initiate a freeze, if they choose to do so. A proposal stays timelocked
 *          for the duration of its `timelockPeriod`.
 *
 * `EXECUTABLE` - Following the `TIMELOCKED` state, a passed proposal becomes `EXECUTABLE`,
 *          and can then finally be executed on chain by anyone.
 *
 * `EXECUTED` - the final state for a passed proposal.  The proposal has been executed
 *          on the blockchain.
 *
 * `EXPIRED` - a passed proposal which is not executed before its `executionPeriod` has
 *          elapsed will be `EXPIRED`, and can no longer be executed.
 *
 * `FAILED` - a failed proposal (as defined by its [BaseStrategy](../BaseStrategy.md) 
 *          `isPassed` function). For a basic strategy, this would mean it received more 
 *          NO votes than YES or did not achieve quorum. 
 */
interface IAzorius {

    /** Represents a transaction to perform on the blockchain. */
    struct Transaction {
        address to; // destination address of the transaction
        uint256 value; // amount of ETH to transfer with the transaction
        bytes data; // encoded function call data of the transaction
        Enum.Operation operation; // Operation type, Call or DelegateCall
    }

    /** Holds details pertaining to a single proposal. */
    struct Proposal {
        uint32 executionCounter; // count of transactions that have been executed within the proposal
        uint32 timelockPeriod; // time (in blocks) this proposal will be timelocked for if it passes
        uint32 executionPeriod; // time (in blocks) this proposal has to be executed after timelock ends before it is expired
        address strategy; // BaseStrategy contract this proposal was created on
        bytes32[] txHashes; // hashes of the transactions that are being proposed
    }

    /** The list of states in which a Proposal can be in at any given time. */
    enum ProposalState {
        ACTIVE,
        TIMELOCKED,
        EXECUTABLE,
        EXECUTED,
        EXPIRED,
        FAILED
    }

    /**
     * Enables a [BaseStrategy](../BaseStrategy.md) implementation for newly created Proposals.
     *
     * Multiple strategies can be enabled, and new Proposals will be able to be
     * created using any of the currently enabled strategies.
     *
     * @param _strategy contract address of the BaseStrategy to be enabled
     */
    function enableStrategy(address _strategy) external;

    /**
     * Disables a previously enabled [BaseStrategy](../BaseStrategy.md) implementation for new proposals.
     * This has no effect on existing Proposals, either `ACTIVE` or completed.
     *
     * @param _prevStrategy BaseStrategy address that pointed in the linked list to the strategy to be removed
     * @param _strategy address of the BaseStrategy to be removed
     */
    function disableStrategy(address _prevStrategy, address _strategy) external;

    /**
     * Updates the `timelockPeriod` for newly created Proposals.
     * This has no effect on existing Proposals, either `ACTIVE` or completed.
     *
     * @param _timelockPeriod timelockPeriod (in blocks) to be used for new Proposals
     */
    function updateTimelockPeriod(uint32 _timelockPeriod) external;

    /**
     * Updates the execution period for future Proposals.
     *
     * @param _executionPeriod new execution period (in blocks)
     */
    function updateExecutionPeriod(uint32 _executionPeriod) external;

    /**
     * Submits a new Proposal, using one of the enabled [BaseStrategies](../BaseStrategy.md).
     * New Proposals begin immediately in the `ACTIVE` state.
     *
     * @param _strategy address of the BaseStrategy implementation which the Proposal will use
     * @param _data arbitrary data passed to the BaseStrategy implementation. This may not be used by all strategies, 
     * but is included in case future strategy contracts have a need for it
     * @param _transactions array of transactions to propose
     * @param _metadata additional data such as a title/description to submit with the proposal
     */
    function submitProposal(
        address _strategy,
        bytes memory _data,
        Transaction[] calldata _transactions,
        string calldata _metadata
    ) external;

    /**
     * Executes all transactions within a Proposal.
     * This will only be able to be called if the Proposal passed.
     *
     * @param _proposalId identifier of the Proposal
     * @param _targets target contracts for each transaction
     * @param _values ETH values to be sent with each transaction
     * @param _data transaction data to be executed
     * @param _operations Calls or Delegatecalls
     */
    function executeProposal(
        uint32 _proposalId,
        address[] memory _targets,
        uint256[] memory _values,
        bytes[] memory _data,
        Enum.Operation[] memory _operations
    ) external;

    /**
     * Returns whether a [BaseStrategy](../BaseStrategy.md) implementation is enabled.
     *
     * @param _strategy contract address of the BaseStrategy to check
     * @return bool True if the strategy is enabled, otherwise False
     */
    function isStrategyEnabled(address _strategy) external view returns (bool);

    /**
     * Returns an array of enabled [BaseStrategy](../BaseStrategy.md) contract addresses.
     * Because the list of BaseStrategies is technically unbounded, this
     * requires the address of the first strategy you would like, along
     * with the total count of strategies to return, rather than
     * returning the whole list at once.
     *
     * @param _startAddress contract address of the BaseStrategy to start with
     * @param _count maximum number of BaseStrategies that should be returned
     * @return _strategies array of BaseStrategies
     * @return _next next BaseStrategy contract address in the linked list
     */
    function getStrategies(
        address _startAddress,
        uint256 _count
    ) external view returns (address[] memory _strategies, address _next);

    /**
     * Gets the state of a Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @return ProposalState uint256 ProposalState enum value representing the
     *         current state of the proposal
     */
    function proposalState(uint32 _proposalId) external view returns (ProposalState);

    /**
     * Generates the data for the module transaction hash (required for signing).
     *
     * @param _to target address of the transaction
     * @param _value ETH value to send with the transaction
     * @param _data encoded function call data of the transaction
     * @param _operation Enum.Operation to use for the transaction
     * @param _nonce Safe nonce of the transaction
     * @return bytes hashed transaction data
     */
    function generateTxHashData(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation,
        uint256 _nonce
    ) external view returns (bytes memory);

    /**
     * Returns the `keccak256` hash of the specified transaction.
     *
     * @param _to target address of the transaction
     * @param _value ETH value to send with the transaction
     * @param _data encoded function call data of the transaction
     * @param _operation Enum.Operation to use for the transaction
     * @return bytes32 transaction hash
     */
    function getTxHash(
        address _to,
        uint256 _value,
        bytes memory _data,
        Enum.Operation _operation
    ) external view returns (bytes32);

    /**
     * Returns the hash of a transaction in a Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @param _txIndex index of the transaction within the Proposal
     * @return bytes32 hash of the specified transaction
     */
    function getProposalTxHash(uint32 _proposalId, uint32 _txIndex) external view returns (bytes32);

    /**
     * Returns the transaction hashes associated with a given `proposalId`.
     *
     * @param _proposalId identifier of the Proposal to get transaction hashes for
     * @return bytes32[] array of transaction hashes
     */
    function getProposalTxHashes(uint32 _proposalId) external view returns (bytes32[] memory);

    /**
     * Returns details about the specified Proposal.
     *
     * @param _proposalId identifier of the Proposal
     * @return _strategy address of the BaseStrategy contract the Proposal is on
     * @return _txHashes hashes of the transactions the Proposal contains
     * @return _timelockPeriod time (in blocks) the Proposal is timelocked for
     * @return _executionPeriod time (in blocks) the Proposal must be executed within, after timelock ends
     * @return _executionCounter counter of how many of the Proposals transactions have been executed
     */
    function getProposal(uint32 _proposalId) external view
        returns (
            address _strategy,
            bytes32[] memory _txHashes,
            uint32 _timelockPeriod,
            uint32 _executionPeriod,
            uint32 _executionCounter
        );
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity =0.8.19;

/**
 * The specification for a voting strategy in Azorius.
 *
 * Each IBaseStrategy implementation need only implement the given functions here,
 * which allows for highly composable but simple or complex voting strategies.
 *
 * It should be noted that while many voting strategies make use of parameters such as
 * voting period or quorum, that is a detail of the individual strategy itself, and not
 * a requirement for the Azorius protocol.
 */
interface IBaseStrategy {

    /**
     * Sets the address of the [Azorius](../Azorius.md) contract this 
     * [BaseStrategy](../BaseStrategy.md) is being used on.
     *
     * @param _azoriusModule address of the Azorius Safe module
     */
    function setAzorius(address _azoriusModule) external;

    /**
     * Called by the [Azorius](../Azorius.md) module. This notifies this 
     * [BaseStrategy](../BaseStrategy.md) that a new Proposal has been created.
     *
     * @param _data arbitrary data to pass to this BaseStrategy
     */
    function initializeProposal(bytes memory _data) external;

    /**
     * Returns whether a Proposal has been passed.
     *
     * @param _proposalId proposalId to check
     * @return bool true if the proposal has passed, otherwise false
     */
    function isPassed(uint32 _proposalId) external view returns (bool);

    /**
     * Returns whether the specified address can submit a Proposal with
     * this [BaseStrategy](../BaseStrategy.md).
     *
     * This allows a BaseStrategy to place any limits it would like on
     * who can create new Proposals, such as requiring a minimum token
     * delegation.
     *
     * @param _address address to check
     * @return bool true if the address can submit a Proposal, otherwise false
     */
    function isProposer(address _address) external view returns (bool);

    /**
     * Returns the block number voting ends on a given Proposal.
     *
     * @param _proposalId proposalId to check
     * @return uint32 block number when voting ends on the Proposal
     */
    function votingEndBlock(uint32 _proposalId) external view returns (uint32);
}

// SPDX-License-Identifier: LGPL-3.0-only

/// @title Zodiac FactoryFriendly - A contract that allows other contracts to be initializable and pass bytes as arguments to define contract state
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract FactoryFriendly is OwnableUpgradeable {
    function setUp(bytes memory initializeParams) public virtual;
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}