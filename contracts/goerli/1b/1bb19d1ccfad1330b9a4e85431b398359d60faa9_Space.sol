// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "src/interfaces/ISpace.sol";
import "src/types.sol";
import "src/interfaces/IVotingStrategy.sol";
import "src/interfaces/IExecutionStrategy.sol";

/**
 * @author  SnapshotLabs
 * @title   Space Contract.
 * @notice  Logic and bookkeeping contract.
 */
contract Space is ISpace, Ownable {
    // Maximum duration a proposal can last.
    uint32 public maxVotingDuration;
    // Minimum duration a proposal can last.
    uint32 public minVotingDuration;
    // Next proposal nonce, increased by one everytime a new proposal is created.
    uint256 public nextProposalId;
    // Minimum voting power required by a user to create a new proposal (used to prevent proposal spamming).
    uint256 public proposalThreshold;
    // Total voting power that needs to participate to a vote for a vote to be considered valid.
    uint256 public quorum;
    // Delay between when the proposal is created and when the voting period starts for this proposal.
    uint32 public votingDelay;

    // Array of available voting strategies that users can use to determine their voting power.
    /// @dev This needs to be an array because a mapping would limit a space to only one use per
    ///      voting strategy contract.
    Strategy[] private votingStrategies;

    // Mapping of allowed execution strategies.
    mapping(address => bool) private executionStrategies;
    // Mapping of allowed authenticators.
    mapping(address => bool) private authenticators;
    // Mapping of all `Proposal`s of this space (past and present).
    mapping(uint256 => Proposal) private proposalRegistry;
    // Mapping used to know if a voter already voted on a specific proposal. Here to prevent double voting.
    mapping(uint256 => mapping(address => bool)) private voteRegistry;
    // Mapping used to check the current voting power in favor of a `Choice` for a specific proposal.
    mapping(uint256 => mapping(Choice => uint256)) private votePower;

    // ------------------------------------
    // |                                  |
    // |          CONSTRUCTOR             |
    // |                                  |
    // ------------------------------------

    constructor(
        address _controller,
        uint32 _votingDelay,
        uint32 _minVotingDuration,
        uint32 _maxVotingDuration,
        uint256 _proposalThreshold,
        uint256 _quorum,
        Strategy[] memory _votingStrategies,
        address[] memory _authenticators,
        address[] memory _executionStrategies
    ) {
        transferOwnership(_controller);
        _setMaxVotingDuration(_maxVotingDuration);
        _setMinVotingDuration(_minVotingDuration);
        _setProposalThreshold(_proposalThreshold);
        _setQuorum(_quorum);
        _setVotingDelay(_votingDelay);
        _addVotingStrategies(_votingStrategies);
        _addAuthenticators(_authenticators);
        _addExecutionStrategies(_executionStrategies);

        nextProposalId = 1;

        // No event events emitted here because the constructor is called by the factory,
        // which emits a space creation event.
    }

    // ------------------------------------
    // |                                  |
    // |            INTERNAL              |
    // |                                  |
    // ------------------------------------

    function _setMaxVotingDuration(uint32 _maxVotingDuration) internal {
        if (_maxVotingDuration < minVotingDuration) revert InvalidDuration(minVotingDuration, _maxVotingDuration);
        maxVotingDuration = _maxVotingDuration;
    }

    function _setMinVotingDuration(uint32 _minVotingDuration) internal {
        if (_minVotingDuration > maxVotingDuration) revert InvalidDuration(_minVotingDuration, maxVotingDuration);
        minVotingDuration = _minVotingDuration;
    }

    function _setProposalThreshold(uint256 _proposalThreshold) internal {
        proposalThreshold = _proposalThreshold;
    }

    function _setQuorum(uint256 _quorum) internal {
        quorum = _quorum;
    }

    function _setVotingDelay(uint32 _votingDelay) internal {
        votingDelay = _votingDelay;
    }

    /**
     * @notice  Internal function to add voting strategies.
     * @dev     `_votingStrategies` should not be set to `0`.
     * @param   _votingStrategies  Array of voting strategies to add.
     */
    function _addVotingStrategies(Strategy[] memory _votingStrategies) internal {
        if (_votingStrategies.length == 0) revert EmptyArray();

        for (uint256 i = 0; i < _votingStrategies.length; i++) {
            // A voting strategy set to 0 is used to indicate that the voting strategy is no longer active,
            // so we need to prevent the user from adding a null invalid strategy address.
            if (_votingStrategies[i].addy == address(0)) revert InvalidVotingStrategyAddress();
            votingStrategies.push(_votingStrategies[i]);
        }
    }

    /**
     * @notice  Internal function to remove voting strategies.
     * @dev     Does not shrink the array but simply sets the values to 0.
     * @param   _votingStrategyIndices  Indices of the strategies to remove.
     */
    function _removeVotingStrategies(uint8[] memory _votingStrategyIndices) internal {
        for (uint8 i = 0; i < _votingStrategyIndices.length; i++) {
            votingStrategies[_votingStrategyIndices[i]].addy = address(0);
            votingStrategies[_votingStrategyIndices[i]].params = new bytes(0);
        }

        // TODO: should we check that there are still voting strategies left after this?
    }

    /**
     * @notice  Internal function to add authenticators.
     * @param   _authenticators  Array of authenticators to add.
     */
    function _addAuthenticators(address[] memory _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = true;
        }
    }

    /**
     * @notice  Internal function to remove authenticators.
     * @param   _authenticators  Array of authenticators to remove.
     */
    function _removeAuthenticators(address[] memory _authenticators) internal {
        for (uint256 i = 0; i < _authenticators.length; i++) {
            authenticators[_authenticators[i]] = false;
        }
        // TODO: should we check that there are still authenticators left? same for other setters..
    }

    /**
     * @notice  Internal function to add exection strategies.
     * @param   _executionStrategies  Array of exectuion strategies to add.
     */
    function _addExecutionStrategies(address[] memory _executionStrategies) internal {
        for (uint256 i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = true;
        }
    }

    /**
     * @notice  Internal function to remove execution strategies.
     * @param   _executionStrategies  Array of execution strategies to remove.
     */
    function _removeExecutionStrategies(address[] memory _executionStrategies) internal {
        for (uint256 i = 0; i < _executionStrategies.length; i++) {
            executionStrategies[_executionStrategies[i]] = false;
        }
    }

    /**
     * @notice  Internal function to ensure `msg.sender` is in the list of allowed authenticators.
     */
    function _assertValidAuthenticator() internal view {
        if (authenticators[msg.sender] != true) revert AuthenticatorNotWhitelisted(msg.sender);
    }

    /**
     * @notice  Internal function to ensure `executionStrategy` is in the list of allowed execution strategies.
     * @param   executionStrategyAddress  The execution strategy to check.
     */
    function _assertValidExecutionStrategy(address executionStrategyAddress) internal view {
        if (executionStrategies[executionStrategyAddress] != true)
            revert ExecutionStrategyNotWhitelisted(executionStrategyAddress);
    }

    /**
     * @notice  Internal function that checks if `proposalId` exists or not.
     * @param   proposal  The proposal to check.
     */
    function _assertProposalExists(Proposal memory proposal) internal pure {
        // startTimestamp cannot be set to 0 when a proposal is created,
        // so if proposal.startTimestamp is 0 it means this proposal does not exist
        // and hence `proposalId` is invalid.
        if (proposal.startTimestamp == 0) revert InvalidProposal();
    }

    /**
     * @notice  Internal function to ensure there are no duplicates in an array of `UserVotingStrategy`.
     * @dev     No way to declare a mapping in memory so we need to use an array and go for O(n^2)...
     * @param   strats  Array to check for duplicates.
     */
    function _assertNoDuplicateIndices(IndexedStrategy[] memory strats) internal pure {
        if (strats.length > 0) {
            for (uint256 i = 0; i < strats.length - 1; i++) {
                for (uint256 j = i + 1; j < strats.length; j++) {
                    if (strats[i].index == strats[j].index) revert DuplicateFound(strats[i].index, strats[j].index);
                }
            }
        }
    }

    /**
     * @notice  Internal function that will loop over the used voting strategies and
                return the cumulative voting power of a user.
     * @dev     
     * @param   timestamp  Timestamp of the snapshot.
     * @param   userAddress  Address for which to compute the voting power.
     * @param   userVotingStrategies The desired voting strategies to check.
     * @return  uint256  The total voting power of a user (over those specified voting strategies).
     */
    function _getCumulativeVotingPower(
        uint32 timestamp,
        address userAddress,
        IndexedStrategy[] calldata userVotingStrategies
    ) internal returns (uint256) {
        // Ensure there are no duplicates to avoid an attack where people double count a voting strategy
        _assertNoDuplicateIndices(userVotingStrategies);

        uint256 totalVotingPower = 0;
        for (uint256 i = 0; i < userVotingStrategies.length; i++) {
            uint256 index = userVotingStrategies[i].index;
            Strategy memory votingStrategy = votingStrategies[index];
            // A strategyAddress set to 0 indicates that this address has already been removed and is
            // no longer a valid voting strategy. See `_removeVotingStrategies`.
            if (votingStrategy.addy == address(0)) revert InvalidVotingStrategyIndex(i);
            IVotingStrategy strategy = IVotingStrategy(votingStrategy.addy);

            // With solc 0.8, this will revert in case of overflow.
            totalVotingPower += strategy.getVotingPower(
                timestamp,
                userAddress,
                votingStrategy.params,
                userVotingStrategies[i].params
            );
        }

        return totalVotingPower;
    }

    /**
     * @notice  Returns some information regarding state of quorum and votes.
     * @param   _quorum  The quorum to reach.
     * @param   _proposalId  The proposal id.
     * @return  bool  Whether or not the quorum has been reached.
     * TODO: Is this function useful? Doesnt seem like a particularly useful abstraction.
     */
    function _quorumInfo(uint256 _quorum, uint256 _proposalId) internal view returns (bool, uint256, uint256, uint256) {
        uint256 votesFor = votePower[_proposalId][Choice.For];
        uint256 votesAgainst = votePower[_proposalId][Choice.Against];
        uint256 votesAbstain = votePower[_proposalId][Choice.Abstain];

        // With solc 0.8, this will revert if an overflow occurs.
        uint256 total = votesFor + votesAgainst + votesAbstain;

        bool quorumReached = total >= _quorum;

        return (quorumReached, votesFor, votesAgainst, votesAbstain);
    }

    // ------------------------------------
    // |                                  |
    // |             SETTERS              |
    // |                                  |
    // ------------------------------------

    function setController(address _controller) external override onlyOwner {
        transferOwnership(_controller);
        emit ControllerUpdated(_controller);
    }

    function setMaxVotingDuration(uint32 _maxVotingDuration) external override onlyOwner {
        _setMaxVotingDuration(_maxVotingDuration);
        emit MaxVotingDurationUpdated(_maxVotingDuration);
    }

    function setMinVotingDuration(uint32 _minVotingDuration) external override onlyOwner {
        _setMinVotingDuration(_minVotingDuration);
        emit MinVotingDurationUpdated(_minVotingDuration);
    }

    function setMetadataUri(string calldata _metadataUri) external override onlyOwner {
        emit MetadataUriUpdated(_metadataUri);
    }

    function setProposalThreshold(uint256 _proposalThreshold) external override onlyOwner {
        _setProposalThreshold(_proposalThreshold);
        emit ProposalThresholdUpdated(_proposalThreshold);
    }

    function setQuorum(uint256 _quorum) external override onlyOwner {
        _setQuorum(_quorum);
        emit QuorumUpdated(_quorum);
    }

    function setVotingDelay(uint32 _votingDelay) external override onlyOwner {
        _setVotingDelay(_votingDelay);
        emit VotingDelayUpdated(_votingDelay);
    }

    function addVotingStrategies(Strategy[] calldata _votingStrategies) external override onlyOwner {
        _addVotingStrategies(_votingStrategies);
        emit VotingStrategiesAdded(_votingStrategies);
    }

    function removeVotingStrategies(uint8[] calldata _votingStrategyIndices) external override onlyOwner {
        _removeVotingStrategies(_votingStrategyIndices);
        emit VotingStrategiesRemoved(_votingStrategyIndices);
    }

    function addAuthenticators(address[] calldata _authenticators) external override onlyOwner {
        _addAuthenticators(_authenticators);
        emit AuthenticatorsAdded(_authenticators);
    }

    function removeAuthenticators(address[] calldata _authenticators) external override onlyOwner {
        _removeAuthenticators(_authenticators);
        emit AuthenticatorsRemoved(_authenticators);
    }

    function addExecutionStrategies(address[] calldata _executionStrategies) external override onlyOwner {
        _addExecutionStrategies(_executionStrategies);
        emit ExecutionStrategiesAdded(_executionStrategies);
    }

    function removeExecutionStrategies(address[] calldata _executionStrategies) external override onlyOwner {
        _removeExecutionStrategies(_executionStrategies);
        emit ExecutionStrategiesRemoved(_executionStrategies);
    }

    // ------------------------------------
    // |                                  |
    // |             GETTERS              |
    // |                                  |
    // ------------------------------------

    function getController() external view override returns (address) {
        return owner();
    }

    function getProposal(uint256 proposalId) external view override returns (Proposal memory) {
        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        return (proposal);
    }

    function getProposalStatus(uint256 proposalId) external view override returns (ProposalStatus) {
        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        (bool quorumReached, , , ) = _quorumInfo(proposal.quorum, proposalId);

        if (proposal.finalizationStatus == FinalizationStatus.NotExecuted) {
            // Proposal has not been executed yet. Let's look at the current timestamp.
            uint256 current = block.timestamp;
            if (current < proposal.startTimestamp) {
                // Not started yet.
                return ProposalStatus.WaitingForVotingPeriodToStart;
            } else if (current > proposal.maxEndTimestamp) {
                // Voting period is over, this proposal is waiting to be finalized.
                return ProposalStatus.Finalizable;
            } else {
                // We are somewhere between `proposal.startTimestamp` and `proposal.maxEndTimestamp`.
                if (current > proposal.minEndTimestamp) {
                    // We've passed `proposal.minEndTimestamp`, check if quorum has been reached.
                    if (quorumReached) {
                        // Quorum has been reached, this proposal is finalizable.
                        return ProposalStatus.VotingPeriodFinalizable;
                    } else {
                        // Quorum has not been reached so this proposal is NOT finalizable yet.
                        return ProposalStatus.VotingPeriod;
                    }
                } else {
                    // `proposal.minEndTimestamp` not reached, so we're just in the regular Voting Period.
                    return ProposalStatus.VotingPeriod;
                }
            }
        } else {
            // Proposal has been executed. Since `FinalizationStatus` and `ProposalStatus` only differ by
            // one, we can safely cast it by substracting 1.
            return ProposalStatus(uint8(proposal.finalizationStatus) - 1);
        }
    }

    function hasVoted(uint256 proposalId, address voter) external view override returns (bool) {
        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        return voteRegistry[proposalId][voter];
    }

    // ------------------------------------
    // |                                  |
    // |             CORE                 |
    // |                                  |
    // ------------------------------------

    /**
     * @notice  Create a proposal.
     * @param   proposerAddress  The address of the proposal creator.
     * @param   metadataUri  The metadata URI for the proposal.
     * @param   executionStrategy  The execution contract and associated execution parameters to use for this proposal.
     * @param   userVotingStrategies  Strategies to use to compute the proposer voting power.
     */
    function propose(
        address proposerAddress,
        string calldata metadataUri,
        Strategy calldata executionStrategy,
        IndexedStrategy[] calldata userVotingStrategies
    ) external override {
        _assertValidAuthenticator();
        _assertValidExecutionStrategy(executionStrategy.addy);

        // Casting to `uint32` is fine because this gives us until year ~2106.
        uint32 snapshotTimestamp = uint32(block.timestamp);

        uint256 votingPower = _getCumulativeVotingPower(snapshotTimestamp, proposerAddress, userVotingStrategies);
        if (votingPower < proposalThreshold) revert ProposalThresholdNotReached(votingPower);

        uint32 startTimestamp = snapshotTimestamp + votingDelay;
        uint32 minEndTimestamp = startTimestamp + minVotingDuration;
        uint32 maxEndTimestamp = startTimestamp + maxVotingDuration;

        bytes32 executionHash = keccak256(executionStrategy.params);

        Proposal memory proposal = Proposal(
            quorum,
            snapshotTimestamp,
            startTimestamp,
            minEndTimestamp,
            maxEndTimestamp,
            executionHash,
            executionStrategy.addy,
            FinalizationStatus.NotExecuted
        );

        proposalRegistry[nextProposalId] = proposal;
        emit ProposalCreated(nextProposalId, proposerAddress, proposal, metadataUri, executionStrategy.params);

        nextProposalId++;
    }

    /**
     * @notice  Cast a vote
     * @param   voterAddress  Voter's address.
     * @param   proposalId  Proposal id.
     * @param   choice  Choice can be `For`, `Against` or `Abstain`.
     * @param   userVotingStrategies  Strategies to use to compute the voter's voting power.
     */
    function vote(
        address voterAddress,
        uint256 proposalId,
        Choice choice,
        IndexedStrategy[] calldata userVotingStrategies
    ) external override {
        _assertValidAuthenticator();

        Proposal memory proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        if (proposal.finalizationStatus != FinalizationStatus.NotExecuted) revert ProposalAlreadyExecuted();

        uint32 currentTimestamp = uint32(block.timestamp);

        if (currentTimestamp >= proposal.maxEndTimestamp) revert VotingPeriodHasEnded();
        if (currentTimestamp < proposal.startTimestamp) revert VotingPeriodHasNotStarted();

        // Ensure voter has not already voted.
        if (voteRegistry[proposalId][voterAddress] == true) revert UserHasAlreadyVoted();

        uint256 votingPower = _getCumulativeVotingPower(proposal.snapshotTimestamp, voterAddress, userVotingStrategies);

        if (votingPower == 0) revert UserHasNoVotingPower();

        uint256 previousVotingPower = votePower[proposalId][choice];
        // With solc 0.8, this will revert if an overflow occurs.
        uint256 newVotingPower = previousVotingPower + votingPower;

        votePower[proposalId][choice] = newVotingPower;
        voteRegistry[proposalId][voterAddress] = true;

        Vote memory userVote = Vote(choice, votingPower);
        emit VoteCreated(proposalId, voterAddress, userVote);
    }

    /**
     * @notice  Finalize a proposal.
     * @param   proposalId  The proposal to cancel
     * @param   executionParams  The execution parameters, as described in `propose()`.
     */
    function finalizeProposal(uint256 proposalId, bytes calldata executionParams) external override {
        // TODO: check if we should use `memory` here and only use `storage` in the end
        // of this function when we actually modify the proposal
        Proposal storage proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        if (proposal.finalizationStatus != FinalizationStatus.NotExecuted) revert ProposalAlreadyExecuted();

        uint32 currentTimestamp = uint32(block.timestamp);

        if (proposal.minEndTimestamp > currentTimestamp) revert MinVotingDurationHasNotElapsed();

        bytes32 recoveredHash = keccak256(executionParams);
        if (proposal.executionHash != recoveredHash) revert ExecutionHashMismatch();

        (bool quorumReached, uint256 votesFor, uint256 votesAgainst, ) = _quorumInfo(proposal.quorum, proposalId);

        ProposalOutcome proposalOutcome;
        if (quorumReached) {
            // Quorum has been reached, determine if proposal should be accepted or rejected.
            if (votesFor > votesAgainst) {
                proposalOutcome = ProposalOutcome.Accepted;
            } else {
                proposalOutcome = ProposalOutcome.Rejected;
            }
        } else {
            // Quorum not reached, check to see if the voting period is over.
            if (currentTimestamp < proposal.maxEndTimestamp) {
                // Voting period is not over yet; revert.
                revert QuorumNotReachedYet();
            } else {
                // Voting period has ended but quorum wasn't reached: set outcome to `REJECTED`.
                proposalOutcome = ProposalOutcome.Rejected;
            }
        }

        // Ensure the execution strategy is still valid.
        if (executionStrategies[proposal.executionStrategy] == false) {
            proposalOutcome = ProposalOutcome.Cancelled;
        }

        IExecutionStrategy(proposal.executionStrategy).execute(proposalOutcome, executionParams);

        // TODO: should we set votePower[proposalId][choice] to 0 to get some nice ETH refund?
        // `ProposalOutcome` and `FinalizatonStatus` are almost the same enum except from their first
        // variant, so by adding `1` we will get the corresponding `FinalizationStatus`.
        proposal.finalizationStatus = FinalizationStatus(uint8(proposalOutcome) + 1);

        emit ProposalFinalized(proposalId, proposalOutcome);
    }

    /**
     * @notice  Cancel a proposal. Only callable by the owner.
     * @param   proposalId  The proposal to cancel
     * @param   executionParams  The execution parameters, as described in `propose()`.
     */
    function cancelProposal(uint256 proposalId, bytes calldata executionParams) external override onlyOwner {
        Proposal storage proposal = proposalRegistry[proposalId];
        _assertProposalExists(proposal);

        if (proposal.finalizationStatus != FinalizationStatus.NotExecuted) revert ProposalAlreadyExecuted();

        bytes32 recoveredHash = keccak256(executionParams);
        if (proposal.executionHash != recoveredHash) revert ExecutionHashMismatch();

        ProposalOutcome proposalOutcome = ProposalOutcome.Cancelled;

        IExecutionStrategy(proposal.executionStrategy).execute(proposalOutcome, executionParams);

        proposal.finalizationStatus = FinalizationStatus.FinalizedAndCancelled;
        emit ProposalFinalized(proposalId, proposalOutcome);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../types.sol";

interface IExecutionStrategy {
    function execute(ProposalOutcome proposalOutcome, bytes memory executionParams) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./space/ISpaceState.sol";
import "./space/ISpaceActions.sol";
import "./space/ISpaceOwnerActions.sol";
import "./space/ISpaceEvents.sol";
import "./space/ISpaceErrors.sol";

interface ISpace is ISpaceState, ISpaceActions, ISpaceOwnerActions, ISpaceEvents, ISpaceErrors {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

/// @title The interface for voting strategies
interface IVotingStrategy {
    /// @notice Get the voting power of an address at a given timestamp
    /// @param timestamp The snapshot timestamp to get the voting power at
    /// If a particular voting strategy requires a  block number instead of a timestamp,
    /// the strategy should resolve the timestamp to a block number.
    /// @param voterAddress The address to get the voting power of
    /// @param params The global parameters that can configure the voting strategy for a particular space
    /// @param userParams The user parameters that can be used in the voting strategy computation
    /// @return votingPower The voting power of the address at the given timestamp
    /// If there is no voting power, return 0.
    function getVotingPower(
        uint32 timestamp,
        address voterAddress,
        bytes calldata params,
        bytes calldata userParams
    ) external returns (uint256 votingPower);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "src/types.sol";

interface ISpaceActions {
    function propose(
        address proposerAddress,
        string calldata metadataUri,
        Strategy calldata executionStrategy,
        IndexedStrategy[] calldata userVotingStrategies
    ) external;

    function vote(
        address voterAddress,
        uint256 proposalId,
        Choice choice,
        IndexedStrategy[] calldata userVotingStrategies
    ) external;

    function finalizeProposal(uint256 proposalId, bytes calldata executionParams) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface ISpaceErrors {
    // Min duration should be smaller than or equal to max duration
    error InvalidDuration(uint32 minVotingDuration, uint32 maxVotingDuration);
    // Array is empty
    error EmptyArray();

    // All voting strategies addresses must be != address(0).
    error InvalidVotingStrategyAddress();
    error InvalidVotingStrategyIndex(uint256 index);
    error InvalidProposal();

    error AuthenticatorNotWhitelisted(address auth);
    error ExecutionStrategyNotWhitelisted(address strategy);

    error ProposalThresholdNotReached(uint256 votingPower);

    error DuplicateFound(uint a, uint b);

    error ProposalAlreadyExecuted();
    error MinVotingDurationHasNotElapsed();
    error ExecutionHashMismatch();
    error QuorumNotReachedYet();

    error VotingPeriodHasEnded();
    error VotingPeriodHasNotStarted();
    error UserHasAlreadyVoted();

    error UserHasNoVotingPower();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "src/types.sol";

interface ISpaceEvents {
    event ProposalCreated(
        uint256 nextProposalId,
        address proposerAddress,
        Proposal proposal,
        string metadataUri,
        bytes executionParams
    );
    event VoteCreated(uint256 proposalId, address voterAddress, Vote vote);
    event ProposalFinalized(uint256 proposalId, ProposalOutcome outcome);

    event VotingStrategiesAdded(Strategy[] votingStrategies);
    event VotingStrategiesRemoved(uint8[] indices);
    event ExecutionStrategiesAdded(address[] executionStrategies);
    event ExecutionStrategiesRemoved(address[] executionStrategies);
    event AuthenticatorsAdded(address[] authenticators);
    event AuthenticatorsRemoved(address[] authenticators);
    event ControllerUpdated(address newController);
    event MaxVotingDurationUpdated(uint32 newMaxVotingDuration);
    event MinVotingDurationUpdated(uint32 newMinVotingDuration);
    event MetadataUriUpdated(string newMetadataUri);
    event ProposalThresholdUpdated(uint256 newProposalThreshold);
    event QuorumUpdated(uint256 newQuorum);
    event VotingDelayUpdated(uint256 newVotingDelay);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../types.sol";

interface ISpaceOwnerActions {
    function cancelProposal(uint256 proposalId, bytes calldata executionParams) external;

    function setController(address controller) external;

    function setQuorum(uint256 quorum) external;

    function setVotingDelay(uint32 delay) external;

    function setMinVotingDuration(uint32 duration) external;

    function setMaxVotingDuration(uint32 duration) external;

    function setProposalThreshold(uint256 threshold) external;

    function setMetadataUri(string calldata metadataUri) external;

    function addVotingStrategies(Strategy[] calldata _votingStrategies) external;

    function removeVotingStrategies(uint8[] calldata indicesToRemove) external;

    function addAuthenticators(address[] calldata _authenticators) external;

    function removeAuthenticators(address[] calldata _authenticators) external;

    function addExecutionStrategies(address[] calldata _executionStrategies) external;

    function removeExecutionStrategies(address[] calldata _executionStrategies) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "src/types.sol";

interface ISpaceState {
    function getController() external view returns (address);

    function maxVotingDuration() external view returns (uint32);

    function minVotingDuration() external view returns (uint32);

    function nextProposalId() external view returns (uint256);

    function proposalThreshold() external view returns (uint256);

    function quorum() external view returns (uint256);

    function votingDelay() external view returns (uint32);

    function getProposal(uint256 proposalId) external view returns (Proposal memory);

    function getProposalStatus(uint256 proposalId) external view returns (ProposalStatus);

    function hasVoted(uint256 proposalId, address voter) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

struct Proposal {
    // We store the quroum for each proposal so that if the quorum is changed mid proposal,
    // the proposal will still use the previous quorum *
    uint256 quorum;
    // notice: `uint32::max` corresponds to year ~2106.
    uint32 snapshotTimestamp;
    // * The same logic applies for why we store the 3 timestamps below (which could otherwise
    // be inferred from the votingDelay, minVotingDuration, and maxVotingDuration state variables)
    uint32 startTimestamp;
    uint32 minEndTimestamp;
    uint32 maxEndTimestamp;
    bytes32 executionHash;
    address executionStrategy;
    FinalizationStatus finalizationStatus;
}

// A struct that represents any kind of strategy (i.e a pair of `address` and `bytes`)
struct Strategy {
    address addy;
    bytes params;
}

// Similar to `Strategy` except it's an `index` (uint8) and not an `address`
struct IndexedStrategy {
    uint8 index;
    bytes params;
}

// Outcome of a proposal after being voted on.
enum ProposalOutcome {
    Accepted,
    Rejected,
    Cancelled
}

// Similar to `ProposalOutcome` except is starts with `NotExecuted`.
// notice: it is important it starts with `NotExecuted` because it correponds to
// `0` which is the default value in Solidity.
enum FinalizationStatus {
    NotExecuted,
    FinalizedAndAccepted,
    FinalizedAndRejected,
    FinalizedAndCancelled
}

// Status of a proposal. If executed, it will be its outcome; else it will be some
// information regarding its current status.
enum ProposalStatus {
    Accepted,
    Rejected,
    Cancelled,
    WaitingForVotingPeriodToStart,
    VotingPeriod,
    VotingPeriodFinalizable,
    Finalizable
}

enum Choice {
    Against,
    For,
    Abstain
}

struct Vote {
    Choice choice;
    uint256 votingPower;
}

struct MetaTransaction {
    address to;
    uint256 value;
    bytes data;
    Enum.Operation operation;
}