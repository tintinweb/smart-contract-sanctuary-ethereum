// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IHashes } from "./interfaces/IHashes.sol";
import { LibBytes } from "./lib/LibBytes.sol";
import { LibDeactivateAuthority } from "./lib/LibDeactivateAuthority.sol";
import { LibEIP712 } from "./lib/LibEIP712.sol";
import { LibSignature } from "./lib/LibSignature.sol";
import { LibVeto } from "./lib/LibVeto.sol";
import { LibVoteCast } from "./lib/LibVoteCast.sol";
import { MathHelpers } from "./lib/MathHelpers.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/MathHelpers.sol";

/**
 * @title HashesDAO
 * @author DEX Labs
 * @notice This contract handles governance for the HashesDAO and the
 *         Hashes ERC-721 token ecosystem.
 */
contract HashesDAO is Ownable {
    using SafeMath for uint256;
    using MathHelpers for uint256;
    using LibBytes for bytes;

    /// @notice name for this Governance apparatus
    string public constant name = "HashesDAO"; // solhint-disable-line const-name-snakecase

    /// @notice version for this Governance apparatus
    string public constant version = "1"; // solhint-disable-line const-name-snakecase

    // Hashes ERC721 token
    IHashes hashesToken;

    // A boolean reflecting whether or not the authority system is still active.
    bool public authoritiesActive;
    // The minimum number of votes required for any authority actions.
    uint256 public quorumAuthorities;
    // Authority status by address.
    mapping(address => bool) authorities;
    // Proposal struct by ID
    mapping(uint256 => Proposal) proposals;
    // Latest proposal IDs by proposer address
    mapping(address => uint128) latestProposalIds;
    // Whether transaction hash is currently queued
    mapping(bytes32 => bool) queuedTransactions;
    // Max number of operations/actions a proposal can have
    uint32 public immutable proposalMaxOperations;
    // Number of blocks after a proposal is made that voting begins
    // (e.g. 1 block)
    uint32 public immutable votingDelay;
    // Number of blocks voting will be held
    // (e.g. 17280 blocks ~ 3 days of blocks)
    uint32 public immutable votingPeriod;
    // Time window (s) a successful proposal must be executed,
    // otherwise will be expired, measured in seconds
    // (e.g. 1209600 seconds)
    uint32 public immutable gracePeriod;
    // Minimum number of for votes required, even if there's a
    // majority in favor
    // (e.g. 100 votes)
    uint32 public immutable quorumVotes;
    // Minimum Hashes token holdings required to create a proposal
    // (e.g. 2 votes)
    uint32 public immutable proposalThreshold;
    // Time (s) proposals must be queued before executing
    uint32 public immutable timelockDelay;
    // Total number of proposals
    uint128 proposalCount;

    struct Proposal {
        bool canceled;
        bool executed;
        address proposer;
        uint32 delay;
        uint128 id;
        uint256 eta;
        uint256 forVotes;
        uint256 againstVotes;
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        uint256[] values;
        uint256 startBlock;
        uint256 endBlock;
        mapping(address => Receipt) receipts;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @notice Emitted when a new proposal is created
    event ProposalCreated(
        uint128 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice Emitted when a vote has been cast on a proposal
    event VoteCast(address indexed voter, uint128 indexed proposalId, bool support, uint256 votes);

    /// @notice Emitted when the authority system is deactivated.
    event AuthoritiesDeactivated();

    /// @notice Emitted when a proposal has been canceled
    event ProposalCanceled(uint128 indexed id);

    /// @notice Emitted when a proposal has been executed
    event ProposalExecuted(uint128 indexed id);

    /// @notice Emitted when a proposal has been queued
    event ProposalQueued(uint128 indexed id, uint256 eta);

    /// @notice Emitted when a proposal has been vetoed
    event ProposalVetoed(uint128 indexed id, uint256 quorum);

    /// @notice Emitted when a proposal action has been canceled
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Emitted when a proposal action has been executed
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /// @notice Emitted when a proposal action has been queued
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        uint256 value,
        string signature,
        bytes data,
        uint256 eta
    );

    /**
     * @dev Makes functions only accessible when the authority system is still
     *      active.
     */
    modifier onlyAuthoritiesActive() {
        require(authoritiesActive, "HashesDAO: authorities must be active.");
        _;
    }

    /**
     * @notice Constructor for the HashesDAO. Initializes the state.
     * @param _hashesToken The hashes token address. This is the contract that
     *        will be called to check for governance membership.
     * @param _authorities A list of authorities that are able to veto
     *        governance proposals. Authorities can revoke their status, but
     *        new authorities can never be added.
     * @param _proposalMaxOperations Max number of operations/actions a
     *        proposal can have
     * @param _votingDelay Number of blocks after a proposal is made
     *        that voting begins.
     * @param _votingPeriod Number of blocks voting will be held.
     * @param _gracePeriod Period in which a successful proposal must be
     *        executed, otherwise will be expired.
     * @param _timelockDelay Time (s) in which a successful proposal
     *        must be in the queue before it can be executed.
     * @param _quorumVotes Minimum number of for votes required, even
     *        if there's a majority in favor.
     * @param _proposalThreshold Minimum Hashes token holdings required
     *        to create a proposal
     */
    constructor(
        IHashes _hashesToken,
        address[] memory _authorities,
        uint32 _proposalMaxOperations,
        uint32 _votingDelay,
        uint32 _votingPeriod,
        uint32 _gracePeriod,
        uint32 _timelockDelay,
        uint32 _quorumVotes,
        uint32 _proposalThreshold
    ) Ownable() {
        hashesToken = _hashesToken;

        // Set initial variable values
        authoritiesActive = true;
        quorumAuthorities = _authorities.length / 2 + 1;
        address lastAuthority;
        for (uint256 i = 0; i < _authorities.length; i++) {
            require(lastAuthority < _authorities[i], "HashesDAO: authority addresses should monotonically increase.");
            lastAuthority = _authorities[i];
            authorities[_authorities[i]] = true;
        }
        proposalMaxOperations = _proposalMaxOperations;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        gracePeriod = _gracePeriod;
        timelockDelay = _timelockDelay;
        quorumVotes = _quorumVotes;
        proposalThreshold = _proposalThreshold;
    }

    /* solhint-disable ordering */
    receive() external payable {}

    /**
     * @notice This function allows participants who have sufficient
     *         Hashes holdings to create new proposals up for vote. The
     *         proposals contain the ordered lists of on-chain
     *         executable calldata.
     * @param _targets Addresses of contracts involved.
     * @param _values Values to be passed along with the calls.
     * @param _signatures Function signatures.
     * @param _calldatas Calldata passed to the function.
     * @param _description Text description of proposal.
     */
    function propose(
        address[] memory _targets,
        uint256[] memory _values,
        string[] memory _signatures,
        bytes[] memory _calldatas,
        string memory _description
    ) external returns (uint128) {
        // Ensure proposer has sufficient token holdings to propose
        require(
            hashesToken.getPriorVotes(msg.sender, block.number.sub(1)) >= proposalThreshold,
            "HashesDAO: proposer votes below proposal threshold."
        );
        require(
            _targets.length == _values.length &&
                _targets.length == _signatures.length &&
                _targets.length == _calldatas.length,
            "HashesDAO: proposal function information parity mismatch."
        );
        require(_targets.length != 0, "HashesDAO: must provide actions.");
        require(_targets.length <= proposalMaxOperations, "HashesDAO: too many actions.");

        if (latestProposalIds[msg.sender] != 0) {
            // Ensure proposer doesn't already have one active/pending
            ProposalState proposersLatestProposalState = state(latestProposalIds[msg.sender]);
            require(
                proposersLatestProposalState != ProposalState.Active,
                "HashesDAO: one live proposal per proposer, found an already active proposal."
            );
            require(
                proposersLatestProposalState != ProposalState.Pending,
                "HashesDAO: one live proposal per proposer, found an already pending proposal."
            );
        }

        // Proposal voting starts votingDelay after proposal is made
        uint256 startBlock = block.number.add(votingDelay);

        // Increment count of proposals
        proposalCount++;

        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.proposer = msg.sender;
        newProposal.delay = timelockDelay;
        newProposal.targets = _targets;
        newProposal.values = _values;
        newProposal.signatures = _signatures;
        newProposal.calldatas = _calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = startBlock.add(votingPeriod);

        // Update proposer's latest proposal
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            _targets,
            _values,
            _signatures,
            _calldatas,
            startBlock,
            startBlock.add(votingPeriod),
            _description
        );
        return newProposal.id;
    }

    /**
     * @notice This function allows any participant to queue a
     *         successful proposal for execution. Proposals are deemed
     *         successful if there is a simple majority (and more for
     *         votes than the minimum quorum) at the end of voting.
     * @param _proposalId Proposal id.
     */
    function queue(uint128 _proposalId) external {
        // Ensure proposal has succeeded (i.e. the voting period has
        // ended and there is a simple majority in favor and also above
        // the quorum
        require(
            state(_proposalId) == ProposalState.Succeeded,
            "HashesDAO: proposal can only be queued if it is succeeded."
        );
        Proposal storage proposal = proposals[_proposalId];

        // Establish eta of execution, which is a number of seconds
        // after queuing at which point proposal can actually execute
        uint256 eta = block.timestamp.add(proposal.delay);
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            // Ensure proposal action is not already in the queue
            bytes32 txHash = keccak256(
                abi.encode(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta)
            );
            require(!queuedTransactions[txHash], "HashesDAO: proposal action already queued at eta.");
            queuedTransactions[txHash] = true;
            emit QueueTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        // Set proposal eta timestamp after which it can be executed
        proposal.eta = eta;
        emit ProposalQueued(_proposalId, eta);
    }

    /**
     * @notice This function allows any participant to execute a
     *         queued proposal. A proposal in the queue must be in the
     *         queue for the delay period it was proposed with prior to
     *         executing, allowing the community to position itself
     *         accordingly.
     * @param _proposalId Proposal id.
     */
    function execute(uint128 _proposalId) external payable {
        // Ensure proposal is queued
        require(
            state(_proposalId) == ProposalState.Queued,
            "HashesDAO: proposal can only be executed if it is queued."
        );
        Proposal storage proposal = proposals[_proposalId];
        // Ensure proposal has been in the queue long enough
        require(block.timestamp >= proposal.eta, "HashesDAO: proposal hasn't finished queue time length.");

        // Ensure proposal hasn't been in the queue for too long
        require(block.timestamp <= proposal.eta.add(gracePeriod), "HashesDAO: transaction is stale.");

        proposal.executed = true;

        // Loop through each of the actions in the proposal
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash = keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            require(queuedTransactions[txHash], "HashesDAO: transaction hasn't been queued.");

            queuedTransactions[txHash] = false;

            // Execute action
            bytes memory callData;
            require(bytes(proposal.signatures[i]).length != 0, "HashesDAO: Invalid function signature.");
            callData = abi.encodePacked(bytes4(keccak256(bytes(proposal.signatures[i]))), proposal.calldatas[i]);
            // solium-disable-next-line security/no-call-value
            (bool success, ) = proposal.targets[i].call{ value: proposal.values[i] }(callData);

            require(success, "HashesDAO: transaction execution reverted.");

            emit ExecuteTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(_proposalId);
    }

    /**
     * @notice This function allows any participant to cancel any non-
     *         executed proposal. It can be canceled if the proposer's
     *         token holdings has dipped below the proposal threshold
     *         at the time of cancellation.
     * @param _proposalId Proposal id.
     */
    function cancel(uint128 _proposalId) external {
        ProposalState proposalState = state(_proposalId);

        // Ensure proposal hasn't executed
        require(proposalState != ProposalState.Executed, "HashesDAO: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[_proposalId];

        // Ensure proposer's token holdings has dipped below the
        // proposer threshold, leaving their proposal subject to
        // cancellation
        require(
            hashesToken.getPriorVotes(proposal.proposer, block.number.sub(1)) < proposalThreshold,
            "HashesDAO: proposer above threshold."
        );

        proposal.canceled = true;

        // Loop through each of the proposal's actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash = keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            queuedTransactions[txHash] = false;
            emit CancelTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(_proposalId);
    }

    /**
     * @notice This function allows participants to cast either in
     *         favor or against a particular proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _deactivate Deactivate tokens (true) or don't (false).
     * @param _deactivateSignature The signature to use when deactivating tokens.
     */
    function castVote(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature
    ) external {
        return _castVote(msg.sender, _proposalId, _support, _deactivate, _deactivateSignature);
    }

    /**
     * @notice This function allows participants to cast votes with
     *         offline signatures in favor or against a particular
     *         proposal.
     * @param _proposalId Proposal id.
     * @param _support In favor (true) or against (false).
     * @param _deactivate Deactivate tokens (true) or don't (false).
     * @param _deactivateSignature The signature to use when deactivating tokens.
     * @param _signature Signature
     */
    function castVoteBySig(
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature,
        bytes memory _signature
    ) external {
        // EIP712 hashing logic
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 voteCastHash = LibVoteCast.getVoteCastHash(
            LibVoteCast.VoteCast({ proposalId: _proposalId, support: _support, deactivate: _deactivate }),
            eip712DomainHash
        );

        // Recover the signature and EIP712 hash
        address recovered = LibSignature.getSignerOfHash(voteCastHash, _signature);

        // Cast the vote and return the result
        return _castVote(recovered, _proposalId, _support, _deactivate, _deactivateSignature);
    }

    /**
     * @notice Allows the authorities to veto a proposal.
     * @param _proposalId The ID of the proposal to veto.
     * @param _signatures The signatures of the authorities.
     */
    function veto(uint128 _proposalId, bytes[] memory _signatures) external onlyAuthoritiesActive {
        ProposalState proposalState = state(_proposalId);

        // Ensure proposal hasn't executed
        require(proposalState != ProposalState.Executed, "HashesDAO: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[_proposalId];

        // Ensure that a sufficient amount of authorities have signed to veto
        // this proposal.
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 vetoHash = LibVeto.getVetoHash(LibVeto.Veto({ proposalId: _proposalId }), eip712DomainHash);
        _verifyAuthorityAction(vetoHash, _signatures);

        // Cancel the proposal.
        proposal.canceled = true;

        // Loop through each of the proposal's actions
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            bytes32 txHash = keccak256(
                abi.encode(
                    proposal.targets[i],
                    proposal.values[i],
                    proposal.signatures[i],
                    proposal.calldatas[i],
                    proposal.eta
                )
            );
            queuedTransactions[txHash] = false;
            emit CancelTransaction(
                txHash,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalVetoed(_proposalId, _signatures.length);
    }

    /**
     * @notice Allows a quorum of authorities to deactivate the authority
     *         system. This operation can only be performed once and will
     *         prevent all future actions undertaken by the authorities.
     * @param _signatures The authority signatures to use to deactivate.
     * @param _authorities A list of authorities to delete. This isn't
     *        security-critical, but it allows the state to be cleaned up.
     */
    function deactivateAuthorities(bytes[] memory _signatures, address[] memory _authorities)
        external
        onlyAuthoritiesActive
    {
        // Ensure that a sufficient amount of authorities have signed to
        // deactivate the authority system.
        bytes32 eip712DomainHash = LibEIP712.hashEIP712Domain(name, version, getChainId(), address(this));
        bytes32 deactivateHash = LibDeactivateAuthority.getDeactivateAuthorityHash(
            LibDeactivateAuthority.DeactivateAuthority({ support: true }),
            eip712DomainHash
        );
        _verifyAuthorityAction(deactivateHash, _signatures);

        // Deactivate the authority system.
        authoritiesActive = false;
        quorumAuthorities = 0;
        for (uint256 i = 0; i < _authorities.length; i++) {
            authorities[_authorities[i]] = false;
        }

        emit AuthoritiesDeactivated();
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the actions involved in a given proposal.
     * @param _proposalId Proposal id.
     * @return targets Addresses of contracts involved.
     * @return values Values to be passed along with the calls.
     * @return signatures Function signatures.
     * @return calldatas Calldata passed to the function.
     */
    function getActions(uint128 _proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[_proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice This function allows any participant to retrieve the authority
     *         status of an arbitrary address.
     * @param _authority The address to check.
     * @return The authority status of the address.
     */
    function getAuthorityStatus(address _authority) external view returns (bool) {
        return authorities[_authority];
    }

    /**
     * @notice This function allows any participant to retrieve
     *         the receipt for a given proposal and voter.
     * @param _proposalId Proposal id.
     * @param _voter Voter address.
     * @return Voter receipt.
     */
    function getReceipt(uint128 _proposalId, address _voter) external view returns (Receipt memory) {
        return proposals[_proposalId].receipts[_voter];
    }

    /**
     * @notice This function gets a proposal from an ID.
     * @param _proposalId Proposal id.
     * @return Proposal attributes.
     */
    function getProposal(uint128 _proposalId)
        external
        view
        returns (
            bool,
            bool,
            address,
            uint32,
            uint128,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.canceled,
            proposal.executed,
            proposal.proposer,
            proposal.delay,
            proposal.id,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.eta,
            proposal.startBlock,
            proposal.endBlock
        );
    }

    /**
     * @notice This function gets whether a proposal action transaction
     *         hash is queued or not.
     * @param _txHash Proposal action tx hash.
     * @return Is proposal action transaction hash queued or not.
     */
    function getIsQueuedTransaction(bytes32 _txHash) external view returns (bool) {
        return queuedTransactions[_txHash];
    }

    /**
     * @notice This function gets the proposal count.
     * @return Proposal count.
     */
    function getProposalCount() external view returns (uint128) {
        return proposalCount;
    }

    /**
     * @notice This function gets the latest proposal ID for a user.
     * @param _proposer Proposer's address.
     * @return Proposal ID.
     */
    function getLatestProposalId(address _proposer) external view returns (uint128) {
        return latestProposalIds[_proposer];
    }

    /**
     * @notice This function retrieves the status for any given
     *         proposal.
     * @param _proposalId Proposal id.
     * @return Status of proposal.
     */
    function state(uint128 _proposalId) public view returns (ProposalState) {
        require(proposalCount >= _proposalId && _proposalId > 0, "HashesDAO: invalid proposal id.");
        Proposal storage proposal = proposals[_proposalId];

        // Note the 3rd conditional where we can escape out of the vote
        // phase if the for or against votes exceeds the skip remaining
        // voting threshold
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(gracePeriod)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function _castVote(
        address _voter,
        uint128 _proposalId,
        bool _support,
        bool _deactivate,
        bytes memory _deactivateSignature
    ) internal {
        // Sanity check the input.
        require(!(_support && _deactivate), "HashesDAO: can't support and deactivate simultaneously.");

        require(state(_proposalId) == ProposalState.Active, "HashesDAO: voting is closed.");
        Proposal storage proposal = proposals[_proposalId];
        Receipt storage receipt = proposal.receipts[_voter];

        // Ensure voter has not already voted
        require(!receipt.hasVoted, "HashesDAO: voter already voted.");

        // Obtain the token holdings (voting power) for participant at
        // the time voting started. They may have gained or lost tokens
        // since then, doesn't matter.
        uint256 votes = hashesToken.getPriorVotes(_voter, proposal.startBlock);

        // Ensure voter has nonzero voting power
        require(votes > 0, "HashesDAO: voter has no voting power.");
        if (_support) {
            // Increment the for votes in favor
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            // Increment the against votes
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        // Set receipt attributes based on cast vote parameters
        receipt.hasVoted = true;
        receipt.support = _support;
        receipt.votes = votes;

        // If necessary, deactivate the voter's hashes tokens.
        if (_deactivate) {
            uint256 deactivationCount = hashesToken.deactivateTokens(_voter, _proposalId, _deactivateSignature);
            if (deactivationCount > 0) {
                // Transfer the voter the activation fee for each of the deactivated tokens.
                (bool sent, ) = _voter.call{ value: hashesToken.activationFee().mul(deactivationCount) }("");
                require(sent, "Hashes: couldn't re-pay the token owner after deactivating hashes.");
            }
        }

        emit VoteCast(_voter, _proposalId, _support, votes);
    }

    /**
     * @dev Verifies a submission from authorities. In particular, this
     *      validates signatures, authorization status, and quorum.
     * @param _hash The message hash to use during recovery.
     * @param _signatures The authority signatures to verify.
     */
    function _verifyAuthorityAction(bytes32 _hash, bytes[] memory _signatures) internal view {
        address lastAddress;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address recovered = LibSignature.getSignerOfHash(_hash, _signatures[i]);
            require(lastAddress < recovered, "HashesDAO: recovered addresses should monotonically increase.");
            require(authorities[recovered], "HashesDAO: recovered addresses should be authorities.");
            lastAddress = recovered;
        }
        require(_signatures.length >= quorumAuthorities / 2 + 1, "HashesDAO: veto quorum was not reached.");
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// solhint-disable max-line-length
/**
 * @notice A library for validating signatures.
 * @dev Much of this file was taken from the LibSignature implementation found at:
 *      https://github.com/0xProject/protocol/blob/development/contracts/zero-ex/contracts/src/features/libs/LibSignature.sol
 */
// solhint-enable max-line-length
library LibSignature {
    // Exclusive upper limit on ECDSA signatures 'R' values. The valid range is
    // given by fig (282) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
        uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);

    // Exclusive upper limit on ECDSA signatures 'S' values. The valid range is
    // given by fig (283) of the yellow paper.
    uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

    /**
     * @dev Retrieve the signer of a signature. Throws if the signature can't be
     *      validated.
     * @param _hash The hash that was signed.
     * @param _signature The signature.
     * @return The recovered signer address.
     */
    function getSignerOfHash(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        require(_signature.length == 65, "LibSignature: Signature length must be 65 bytes.");

        // Get the v, r, and s values from the signature.
        uint8 v = uint8(_signature[0]);
        bytes32 r;
        bytes32 s;
        assembly {
            r := mload(add(_signature, 0x21))
            s := mload(add(_signature, 0x41))
        }

        // Enforce the signature malleability restrictions.
        validateSignatureMalleabilityLimits(v, r, s);

        // Recover the signature without pre-hashing.
        address recovered = ecrecover(_hash, v, r, s);

        // `recovered` can be null if the signature values are out of range.
        require(recovered != address(0), "LibSignature: Bad signature data.");
        return recovered;
    }

    /**
     * @notice Validates the malleability limits of an ECDSA signature.
     *
     *         Context:
     *
     *         EIP-2 still allows signature malleability for ecrecover(). Remove
     *         this possibility and make the signature unique. Appendix F in the
     *         Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf),
     *         defines the valid range for r in (282): 0 < r < secp256k1n, the
     *         valid range for s in (283): 0 < s < secp256k1n ÷ 2 + 1, and for v
     *         in (284): v ∈ {27, 28}. Most signatures from current libraries
     *         generate a unique signature with an s-value in the lower half order.
     *
     *         If your library generates malleable signatures, such as s-values
     *         in the upper range, calculate a new s-value with
     *         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1
     *         and flip v from 27 to 28 or vice versa. If your library also
     *         generates signatures with 0/1 for v instead 27/28, add 27 to v to
     *         accept these malleable signatures as well.
     *
     * @param _v The v value of the signature.
     * @param _r The r value of the signature.
     * @param _s The s value of the signature.
     */
    function validateSignatureMalleabilityLimits(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure {
        // Ensure the r, s, and v are within malleability limits. Appendix F of
        // the Yellow Paper stipulates that all three values should be checked.
        require(uint256(_r) < ECDSA_SIGNATURE_R_LIMIT, "LibSignature: r parameter of signature is invalid.");
        require(uint256(_s) < ECDSA_SIGNATURE_S_LIMIT, "LibSignature: s parameter of signature is invalid.");
        require(_v == 27 || _v == 28, "LibSignature: v parameter of signature is invalid.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibDeactivateAuthority {
    struct DeactivateAuthority {
        bool support;
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_DEACTIVATE_AUTHORITY_HASH = keccak256(abi.encodePacked(
    //        "DeactivateAuthority(",
    //        "bool support",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_DEACTIVATE_AUTHORITY_SCHEMA_HASH =
        0x17dec47eaa269b80dfd59f06648e0096c5e96c83185c6a1be1c71cf853a79a40;

    /// @dev Calculates Keccak-256 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return deactivateHash Keccak-256 EIP712 hash of the deactivation.
    function getDeactivateAuthorityHash(DeactivateAuthority memory _deactivate, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 deactivateHash)
    {
        deactivateHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashDeactivateAuthority(_deactivate));
        return deactivateHash;
    }

    /// @dev Calculates EIP712 hash of the deactivation.
    /// @param _deactivate The deactivate structure.
    /// @return result EIP712 hash of the deactivate.
    function hashDeactivateAuthority(DeactivateAuthority memory _deactivate) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_DEACTIVATE_AUTHORITY_SCHEMA_HASH;

        assembly {
            // Assert deactivate offset (this is an internal error that should never be triggered)
            if lt(_deactivate, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_deactivate, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibVeto {
    struct Veto {
        uint128 proposalId; // Proposal ID
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_VETO_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "Veto(",
    //        "uint128 proposalId",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VETO_SCHEMA_HASH =
        0x634b7f2828b36c241805efe02eca7354b65d9dd7345300a9c3fca91c0b028ad7;

    /// @dev Calculates Keccak-256 hash of the veto.
    /// @param _veto The veto structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return vetoHash Keccak-256 EIP712 hash of the veto.
    function getVetoHash(Veto memory _veto, bytes32 _eip712DomainHash) internal pure returns (bytes32 vetoHash) {
        vetoHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashVeto(_veto));
        return vetoHash;
    }

    /// @dev Calculates EIP712 hash of the veto.
    /// @param _veto The veto structure.
    /// @return result EIP712 hash of the veto.
    function hashVeto(Veto memory _veto) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VETO_SCHEMA_HASH;

        assembly {
            // Assert veto offset (this is an internal error that should never be triggered)
            if lt(_veto, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_veto, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 64)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import { LibEIP712 } from "./LibEIP712.sol";

library LibVoteCast {
    struct VoteCast {
        uint128 proposalId; // Proposal ID
        bool support; // Support
        bool deactivate; // Deactivation preference
    }

    // Hash for the EIP712 Schema
    //    bytes32 constant internal EIP712_VOTE_CAST_SCHEMA_HASH = keccak256(abi.encodePacked(
    //        "VoteCast(",
    //        "uint128 proposalId,",
    //        "bool support,",
    //        "bool deactivate",
    //        ")"
    //    ));
    bytes32 internal constant EIP712_VOTE_CAST_SCHEMA_HASH =
        0xe2e736baec1b33e622ec76a499ffd32b809860cc499f4d543162d229e795be74;

    /// @dev Calculates Keccak-256 hash of the vote cast.
    /// @param _voteCast The vote cast structure.
    /// @param _eip712DomainHash The hash of the EIP712 domain.
    /// @return voteCastHash Keccak-256 EIP712 hash of the vote cast.
    function getVoteCastHash(VoteCast memory _voteCast, bytes32 _eip712DomainHash)
        internal
        pure
        returns (bytes32 voteCastHash)
    {
        voteCastHash = LibEIP712.hashEIP712Message(_eip712DomainHash, hashVoteCast(_voteCast));
        return voteCastHash;
    }

    /// @dev Calculates EIP712 hash of the vote cast.
    /// @param _voteCast The vote cast structure.
    /// @return result EIP712 hash of the vote cast.
    function hashVoteCast(VoteCast memory _voteCast) internal pure returns (bytes32 result) {
        // Assembly for more efficiently computing:
        bytes32 schemaHash = EIP712_VOTE_CAST_SCHEMA_HASH;

        assembly {
            // Assert vote cast offset (this is an internal error that should never be triggered)
            if lt(_voteCast, 32) {
                invalid()
            }

            // Calculate memory addresses that will be swapped out before hashing
            let pos1 := sub(_voteCast, 32)

            // Backup
            let temp1 := mload(pos1)

            // Hash in place
            mstore(pos1, schemaHash)
            result := keccak256(pos1, 128)

            // Restore
            mstore(pos1, temp1)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library MathHelpers {
    using SafeMath for uint256;

    function proportion256(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return uint256(a).mul(b).div(c);
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governanceCap() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/*

  Copyright 2019 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.6;

library LibEIP712 {
    // Hash of the EIP712 Domain Separator Schema
    // keccak256(abi.encodePacked(
    //     "EIP712Domain(",
    //     "string name,",
    //     "string version,",
    //     "uint256 chainId,",
    //     "address verifyingContract",
    //     ")"
    // ))
    bytes32 internal constant _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    /// @dev Calculates a EIP712 domain separator.
    /// @param name The EIP712 domain name.
    /// @param version The EIP712 domain version.
    /// @param verifyingContract The EIP712 verifying contract.
    /// @return result EIP712 domain separator.
    function hashEIP712Domain(
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32 result) {
        bytes32 schemaHash = _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH;

        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     _EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        //     keccak256(bytes(name)),
        //     keccak256(bytes(version)),
        //     chainId,
        //     uint256(verifyingContract)
        // ))

        assembly {
            // Calculate hashes of dynamic data
            let nameHash := keccak256(add(name, 32), mload(name))
            let versionHash := keccak256(add(version, 32), mload(version))

            // Load free memory pointer
            let memPtr := mload(64)

            // Store params in memory
            mstore(memPtr, schemaHash)
            mstore(add(memPtr, 32), nameHash)
            mstore(add(memPtr, 64), versionHash)
            mstore(add(memPtr, 96), chainId)
            mstore(add(memPtr, 128), verifyingContract)

            // Compute hash
            result := keccak256(memPtr, 160)
        }
        return result;
    }

    /// @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
    /// @param eip712DomainHash Hash of the domain domain separator data, computed
    ///                         with getDomainHash().
    /// @param hashStruct The EIP712 hash struct.
    /// @return result EIP712 hash applied to the given EIP712 Domain.
    function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct) internal pure returns (bytes32 result) {
        // Assembly for more efficient computing:
        // keccak256(abi.encodePacked(
        //     EIP191_HEADER,
        //     EIP712_DOMAIN_HASH,
        //     hashStruct
        // ));

        assembly {
            // Load free memory pointer
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
            mstore(add(memPtr, 2), eip712DomainHash) // EIP712 domain hash
            mstore(add(memPtr, 34), hashStruct) // Hash of struct

            // Compute hash
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
/*

  Copyright 2018 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.6;

library LibBytes {
    using LibBytes for bytes;

    /// @dev Gets the memory address for a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of byte array. This
    ///         points to the header of the byte array which contains
    ///         the length.
    function rawAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

    /// @dev Gets the memory address for the contents of a byte array.
    /// @param input Byte array to lookup.
    /// @return memoryAddress Memory address of the contents of the byte array.
    function contentAddress(bytes memory input) internal pure returns (uint256 memoryAddress) {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

    /// @dev Copies `length` bytes from memory location `source` to `dest`.
    /// @param dest memory address to copy bytes to.
    /// @param source memory address to copy bytes from.
    /// @param length number of bytes to copy.
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    ) internal pure {
        if (length < 32) {
            // Handle a partial word by reading destination and masking
            // off the bits we are interested in.
            // This correctly handles overlap, zero lengths and source == dest
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
            // Skip the O(length) loop when source == dest.
            if (source == dest) {
                return;
            }

            // For large copies we copy whole words at a time. The final
            // word is aligned to the end of the range (instead of after the
            // previous) to handle partial words. So a copy will look like this:
            //
            //  ####
            //      ####
            //          ####
            //            ####
            //
            // We handle overlap in the source and destination range by
            // changing the copying direction. This prevents us from
            // overwriting parts of source that we still need to copy.
            //
            // This correctly handles source == dest
            //
            if (source > dest) {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because it
                    // is easier to compare with in the loop, and these
                    // are also the addresses we need for copying the
                    // last bytes.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the last 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the last bytes in
                    // source already due to overlap.
                    let last := mload(sEnd)

                    // Copy whole words front to back
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {

                    } lt(source, sEnd) {

                    } {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                    // Write the last 32 bytes
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                    // We subtract 32 from `sEnd` and `dEnd` because those
                    // are the starting points when copying a word at the end.
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                    // Remember the first 32 bytes of source
                    // This needs to be done here and not after the loop
                    // because we may have overwritten the first bytes in
                    // source already due to overlap.
                    let first := mload(source)

                    // Copy whole words back to front
                    // We use a signed comparisson here to allow dEnd to become
                    // negative (happens when source and dest < 32). Valid
                    // addresses in local memory will never be larger than
                    // 2**255, so they can be safely re-interpreted as signed.
                    // Note: the first check is always true,
                    // this could have been a do-while loop.
                    // solhint-disable-next-line no-empty-blocks
                    for {

                    } slt(dest, dEnd) {

                    } {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                    // Write the first 32 bytes
                    mstore(dest, first)
                }
            }
        }
    }

    /// @dev Returns a slices from a byte array.
    /// @param b The byte array to take a slice from.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        require(from <= to, "FROM_LESS_THAN_TO_REQUIRED");
        require(to <= b.length, "TO_LESS_THAN_LENGTH_REQUIRED");

        // Create a new bytes structure and copy contents
        result = new bytes(to - from);
        memCopy(result.contentAddress(), b.contentAddress() + from, result.length);
        return result;
    }

    /// @dev Returns a slice from a byte array without preserving the input.
    /// @param b The byte array to take a slice from. Will be destroyed in the process.
    /// @param from The starting index for the slice (inclusive).
    /// @param to The final index for the slice (exclusive).
    /// @return result The slice containing bytes at indices [from, to)
    /// @dev When `from == 0`, the original array will match the slice. In other cases its state will be corrupted.
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    ) internal pure returns (bytes memory result) {
        require(from <= to, "FROM_LESS_THAN_TO_REQUIRED");
        require(to <= b.length, "TO_LESS_THAN_LENGTH_REQUIRED");

        // Create a new bytes structure around [from, to) in-place.
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

    /// @dev Pops the last byte off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The byte that was popped off.
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "GREATER_THAN_ZERO_LENGTH_REQUIRED");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Pops the last 20 bytes off of a byte array by modifying its length.
    /// @param b Byte array that will be modified.
    /// @return result The 20 byte address that was popped off.
    function popLast20Bytes(bytes memory b) internal pure returns (address result) {
        require(b.length >= 20, "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED");

        // Store last 20 bytes.
        result = readAddress(b, b.length - 20);

        assembly {
            // Subtract 20 from byte array length.
            let newLen := sub(mload(b), 20)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Tests equality of two byte arrays.
    /// @param lhs First byte array to compare.
    /// @param rhs Second byte array to compare.
    /// @return equal True if arrays are the same. False otherwise.
    function equals(bytes memory lhs, bytes memory rhs) internal pure returns (bool equal) {
        // Keccak gas cost is 30 + numWords * 6. This is a cheap way to compare.
        // We early exit on unequal lengths, but keccak would also correctly
        // handle this.
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /// @dev Writes an address into a specific position in a byte array.
    /// @param b Byte array to insert address into.
    /// @param index Index in byte array of address.
    /// @param input Address to put into byte array.
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    ) internal pure {
        require(
            b.length >= index + 20, // 20 is length of address
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Store address into array memory
        assembly {
            // The address occupies 20 bytes and mstore stores 32 bytes.
            // First fetch the 32-byte word where we'll be storing the address, then
            // apply a mask so we have only the bytes in the word that the address will not occupy.
            // Then combine these bytes with the address and store the 32 bytes back to memory with mstore.

            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 12-byte mask to obtain extra bytes occupying word of memory where we'll store the address
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

            // Make sure input address is clean.
            // (Solidity does not guarantee this)
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

            // Store the neighbors and address into memory
            mstore(add(b, index), xor(input, neighbors))
        }
    }

    /// @dev Reads a bytes32 value from a position in a byte array.
    /// @param b Byte array containing a bytes32 value.
    /// @param index Index in byte array of bytes32 value.
    /// @return result bytes32 value from byte array.
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Writes a bytes32 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes32 to put into byte array.
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    ) internal pure {
        require(b.length >= index + 32, "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            mstore(add(b, index), input)
        }
    }

    /// @dev Reads a uint256 value from a position in a byte array.
    /// @param b Byte array containing a uint256 value.
    /// @param index Index in byte array of uint256 value.
    /// @return result uint256 value from byte array.
    function readUint256(bytes memory b, uint256 index) internal pure returns (uint256 result) {
        result = uint256(readBytes32(b, index));
        return result;
    }

    /// @dev Writes a uint256 into a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input uint256 to put into byte array.
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    ) internal pure {
        writeBytes32(b, index, bytes32(input));
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "GREATER_OR_EQUAL_TO_4_LENGTH_REQUIRED");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Reads an unpadded bytes2 value from a position in a byte array.
    /// @param b Byte array containing a bytes2 value.
    /// @param index Index in byte array of bytes2 value.
    /// @return result bytes2 value from byte array.
    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "GREATER_OR_EQUAL_TO_2_LENGTH_REQUIRED");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes2 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    /// @dev Reads nested bytes from a specific position.
    /// @dev NOTE: the returned value overlaps with the input value.
    ///            Both should be treated as immutable.
    /// @param b Byte array containing nested bytes.
    /// @param index Index of nested bytes.
    /// @return result Nested bytes.
    function readBytesWithLength(bytes memory b, uint256 index) internal pure returns (bytes memory result) {
        // Read length of nested bytes
        uint256 nestedBytesLength = readUint256(b, index);
        index += 32;

        // Assert length of <b> is valid, given
        // length of nested bytes
        require(b.length >= index + nestedBytesLength, "GREATER_OR_EQUAL_TO_NESTED_BYTES_LENGTH_REQUIRED");

        // Return a pointer to the byte array as it exists inside `b`
        assembly {
            result := add(b, index)
        }
        return result;
    }

    /// @dev Inserts bytes at a specific position in a byte array.
    /// @param b Byte array to insert <input> into.
    /// @param index Index in byte array of <input>.
    /// @param input bytes to insert.
    function writeBytesWithLength(
        bytes memory b,
        uint256 index,
        bytes memory input
    ) internal pure {
        // Assert length of <b> is valid, given
        // length of input
        require(
            b.length >= index + 32 + input.length, // 32 bytes to store length
            "GREATER_OR_EQUAL_TO_NESTED_BYTES_LENGTH_REQUIRED"
        );

        // Copy <input> into <b>
        memCopy(
            b.contentAddress() + index,
            input.rawAddress(), // includes length of <input>
            input.length + 32 // +32 bytes to store <input> length
        );
    }

    /// @dev Performs a deep copy of a byte array onto another byte array of greater than or equal length.
    /// @param dest Byte array that will be overwritten with source bytes.
    /// @param source Byte array to copy onto dest bytes.
    function deepCopyBytes(bytes memory dest, bytes memory source) internal pure {
        uint256 sourceLen = source.length;
        // Dest length must be >= source length, or some bytes would not be copied.
        require(dest.length >= sourceLen, "GREATER_OR_EQUAL_TO_SOURCE_BYTES_LENGTH_REQUIRED");
        memCopy(dest.contentAddress(), source.contentAddress(), sourceLen);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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