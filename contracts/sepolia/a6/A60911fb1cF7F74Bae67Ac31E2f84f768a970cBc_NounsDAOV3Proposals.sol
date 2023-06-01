// SPDX-License-Identifier: GPL-3.0

/// @title Library for NounsDAOLogicV3 contract containing the proposal lifecycle code

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

pragma solidity ^0.8.6;

import './NounsDAOInterfaces.sol';
import { NounsDAOV3DynamicQuorum } from './NounsDAOV3DynamicQuorum.sol';
import { NounsDAOV3Fork } from './fork/NounsDAOV3Fork.sol';
import { SignatureChecker } from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import { ECDSA } from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

library NounsDAOV3Proposals {
    using NounsDAOV3DynamicQuorum for NounsDAOStorageV3.StorageV3;
    using NounsDAOV3Fork for NounsDAOStorageV3.StorageV3;

    error CantCancelProposalAtFinalState();
    error ProposalInfoArityMismatch();
    error MustProvideActions();
    error TooManyActions();
    error ProposerAlreadyHasALiveProposal();
    error InvalidSignature();
    error SignatureExpired();
    error CanOnlyEditUpdatableProposals();
    error OnlyProposerCanEdit();
    error SignerCountMismtach();
    error ProposerCannotUpdateProposalWithSigners();
    error MustProvideSignatures();
    error SignatureIsCancelled();
    error CannotExecuteDuringForkingPeriod();
    error VetoerBurned();
    error VetoerOnly();
    error CantVetoExecutedProposal();

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

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
    /// @dev V3 adds `signers`, `updatePeriodEndBlock` compared to the V1/V2 event.
    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] signers,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 updatePeriodEndBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );

    /// @notice Emitted when a proposal is created to be executed on timelockV1
    event ProposalCreatedOnTimelockV1(uint256 id);

    /// @notice Emitted when a proposal is updated
    event ProposalUpdated(
        uint256 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string description,
        string updateMessage
    );

    /// @notice Emitted when a proposal's transactions are updated
    event ProposalTransactionsUpdated(
        uint256 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string updateMessage
    );

    /// @notice Emitted when a proposal's description is updated
    event ProposalDescriptionUpdated(
        uint256 indexed id,
        address indexed proposer,
        string description,
        string updateMessage
    );

    /// @notice An event emitted when a proposal has been queued in the NounsDAOExecutor
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a proposal has been executed in the NounsDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice Emitted when someone cancels a signature
    event SignatureCancelled(address indexed signer, bytes sig);

    // Created to solve stack-too-deep errors
    struct ProposalTxs {
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
    }

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    bytes32 public constant PROPOSAL_TYPEHASH =
        keccak256(
            'Proposal(address proposer,address[] targets,uint256[] values,string[] signatures,bytes[] calldatas,string description,uint256 expiry)'
        );

    bytes32 public constant UPDATE_PROPOSAL_TYPEHASH =
        keccak256(
            'UpdateProposal(uint256 proposalId,address proposer,address[] targets,uint256[] values,string[] signatures,bytes[] calldatas,string description,uint256 expiry)'
        );

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param txs Target addresses, eth values, function signatures and calldatas for proposal calls
     * @param description String description of the proposal
     * @return Proposal id of new proposal
     */
    function propose(
        NounsDAOStorageV3.StorageV3 storage ds,
        ProposalTxs memory txs,
        string memory description
    ) internal returns (uint256) {
        uint256 adjustedTotalSupply = ds.adjustedTotalSupply();
        uint256 proposalThreshold_ = checkPropThreshold(
            ds,
            ds.nouns.getPriorVotes(msg.sender, block.number - 1),
            adjustedTotalSupply
        );
        checkProposalTxs(txs);
        checkNoActiveProp(ds, msg.sender);

        uint256 proposalId = ds.proposalCount = ds.proposalCount + 1;
        NounsDAOStorageV3.Proposal storage newProposal = createNewProposal(
            ds,
            proposalId,
            proposalThreshold_,
            adjustedTotalSupply,
            txs
        );
        ds.latestProposalIds[msg.sender] = proposalId;

        emitNewPropEvents(newProposal, new address[](0), ds.minQuorumVotes(adjustedTotalSupply), txs, description);

        return proposalId;
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold.
     * This proposal would be executed via the timelockV1 contract. This is meant to be used in case timelockV1
     * is still holding funds or has special permissions to execute on certain contracts.
     * @param txs Target addresses, eth values, function signatures and calldatas for proposal calls
     * @param description String description of the proposal
     * @return uint256 Proposal id of new proposal
     */
    function proposeOnTimelockV1(
        NounsDAOStorageV3.StorageV3 storage ds,
        ProposalTxs memory txs,
        string memory description
    ) internal returns (uint256) {
        uint256 newProposalId = propose(ds, txs, description);

        NounsDAOStorageV3.Proposal storage newProposal = ds._proposals[newProposalId];
        newProposal.executeOnTimelockV1 = true;

        emit ProposalCreatedOnTimelockV1(newProposalId);

        return newProposalId;
    }

    /**
     * @notice Function used to propose a new proposal. Sender and signers must have delegates above the proposal threshold
     * @param proposerSignatures Array of signers who have signed the proposal and their signatures.
     * @dev The signatures follow EIP-712. See `PROPOSAL_TYPEHASH` in NounsDAOV3Proposals.sol
     * @param txs Target addresses, eth values, function signatures and calldatas for proposal calls
     * @param description String description of the proposal
     * @return uint256 Proposal id of new proposal
     */
    function proposeBySigs(
        NounsDAOStorageV3.StorageV3 storage ds,
        NounsDAOStorageV3.ProposerSignature[] memory proposerSignatures,
        ProposalTxs memory txs,
        string memory description
    ) external returns (uint256) {
        if (proposerSignatures.length == 0) revert MustProvideSignatures();
        checkProposalTxs(txs);
        uint256 proposalId = ds.proposalCount = ds.proposalCount + 1;

        (uint256 votes, address[] memory signers) = verifySignersCanBackThisProposalAndCountTheirVotes(
            ds,
            proposerSignatures,
            txs,
            description,
            proposalId
        );

        uint256 adjustedTotalSupply = ds.adjustedTotalSupply();
        uint256 propThreshold = checkPropThreshold(ds, votes, adjustedTotalSupply);
        NounsDAOStorageV3.Proposal storage newProposal = createNewProposal(
            ds,
            proposalId,
            propThreshold,
            adjustedTotalSupply,
            txs
        );
        newProposal.signers = signers;

        emitNewPropEvents(newProposal, signers, ds.minQuorumVotes(adjustedTotalSupply), txs, description);

        return proposalId;
    }

    /**
     * @notice Invalidates a signature that may be used for signing a proposal.
     * Once a signature is canceled, the sender can no longer use it again.
     * If the sender changes their mind and want to sign the proposal, they can change the expiry timestamp
     * in order to produce a new signature.
     * The signature will only be invalidated when used by the sender. If used by a different account, it will
     * not be invalidated.
     * @param sig The signature to cancel
     */
    function cancelSig(NounsDAOStorageV3.StorageV3 storage ds, bytes calldata sig) external {
        bytes32 sigHash = keccak256(sig);
        ds.cancelledSigs[msg.sender][sigHash] = true;

        emit SignatureCancelled(msg.sender, sig);
    }

    /**
     * @notice Update a proposal transactions and description.
     * Only the proposer can update it, and only during the updateable period.
     * @param proposalId Proposal's id
     * @param targets Updated target addresses for proposal calls
     * @param values Updated eth values for proposal calls
     * @param signatures Updated function signatures for proposal calls
     * @param calldatas Updated calldatas for proposal calls
     * @param description Updated description of the proposal
     * @param updateMessage Short message to explain the update
     */
    function updateProposal(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory updateMessage
    ) external {
        updateProposalTransactionsInternal(ds, proposalId, targets, values, signatures, calldatas);

        emit ProposalUpdated(
            proposalId,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            description,
            updateMessage
        );
    }

    /**
     * @notice Updates the proposal's transactions. Only the proposer can update it, and only during the updateable period.
     * @param proposalId Proposal's id
     * @param targets Updated target addresses for proposal calls
     * @param values Updated eth values for proposal calls
     * @param signatures Updated function signatures for proposal calls
     * @param calldatas Updated calldatas for proposal calls
     * @param updateMessage Short message to explain the update
     */
    function updateProposalTransactions(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory updateMessage
    ) external {
        updateProposalTransactionsInternal(ds, proposalId, targets, values, signatures, calldatas);

        emit ProposalTransactionsUpdated(proposalId, msg.sender, targets, values, signatures, calldatas, updateMessage);
    }

    function updateProposalTransactionsInternal(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) internal {
        checkProposalTxs(ProposalTxs(targets, values, signatures, calldatas));

        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        checkProposalUpdatable(ds, proposalId, proposal);

        proposal.targets = targets;
        proposal.values = values;
        proposal.signatures = signatures;
        proposal.calldatas = calldatas;
    }

    /**
     * @notice Updates the proposal's description. Only the proposer can update it, and only during the updateable period.
     * @param proposalId Proposal's id
     * @param description Updated description of the proposal
     * @param updateMessage Short message to explain the update
     */
    function updateProposalDescription(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        string calldata description,
        string calldata updateMessage
    ) external {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        checkProposalUpdatable(ds, proposalId, proposal);

        emit ProposalDescriptionUpdated(proposalId, msg.sender, description, updateMessage);
    }

    /**
     * @notice Update a proposal's transactions and description that was created with proposeBySigs.
     * Only the proposer can update it, during the updateable period.
     * Requires the original signers to sign the update.
     * @param proposalId Proposal's id
     * @param proposerSignatures Array of signers who have signed the proposal and their signatures.
     * @dev The signatures follow EIP-712. See `UPDATE_PROPOSAL_TYPEHASH` in NounsDAOV3Proposals.sol
     * @param txs Updated transactions for the proposal
     * @param description Updated description of the proposal
     * @param updateMessage Short message to explain the update
     */
    function updateProposalBySigs(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        NounsDAOStorageV3.ProposerSignature[] memory proposerSignatures,
        ProposalTxs memory txs,
        string memory description,
        string memory updateMessage
    ) external {
        checkProposalTxs(txs);
        // without this check it's possible to run through this function and update a proposal without signatures
        // this problem doesn't exist in the propose function because we check for prop threshold there
        if (proposerSignatures.length == 0) revert MustProvideSignatures();

        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        if (state(ds, proposalId) != NounsDAOStorageV3.ProposalState.Updatable) revert CanOnlyEditUpdatableProposals();
        if (msg.sender != proposal.proposer) revert OnlyProposerCanEdit();

        address[] memory signers = proposal.signers;
        if (proposerSignatures.length != signers.length) revert SignerCountMismtach();

        bytes memory proposalEncodeData = abi.encodePacked(
            proposalId,
            calcProposalEncodeData(msg.sender, txs, description)
        );

        for (uint256 i = 0; i < proposerSignatures.length; ++i) {
            verifyProposalSignature(ds, proposalEncodeData, proposerSignatures[i], UPDATE_PROPOSAL_TYPEHASH);

            // To avoid the gas cost of having to search signers in proposal.signers, we're assuming the sigs we get
            // use the same amount of signers and the same order.
            if (signers[i] != proposerSignatures[i].signer) revert OnlyProposerCanEdit();
        }

        proposal.targets = txs.targets;
        proposal.values = txs.values;
        proposal.signatures = txs.signatures;
        proposal.calldatas = txs.calldatas;

        emit ProposalUpdated(
            proposalId,
            msg.sender,
            txs.targets,
            txs.values,
            txs.signatures,
            txs.calldatas,
            description,
            updateMessage
        );
    }

    /**
     * @notice Queues a proposal of state succeeded
     * @param proposalId The id of the proposal to queue
     */
    function queue(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) external {
        require(
            state(ds, proposalId) == NounsDAOStorageV3.ProposalState.Succeeded,
            'NounsDAO::queue: proposal can only be queued if it is succeeded'
        );
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        INounsDAOExecutor timelock = getProposalTimelock(ds, proposal);
        uint256 eta = block.timestamp + timelock.delay();
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(
                timelock,
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(
        INounsDAOExecutor timelock,
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            'NounsDAO::queueOrRevertInternal: identical proposal action already queued at eta'
        );
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
     * @notice Executes a queued proposal if eta has passed
     * @param proposalId The id of the proposal to execute
     */
    function execute(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) external {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        INounsDAOExecutor timelock = getProposalTimelock(ds, proposal);
        executeInternal(ds, proposal, timelock);
    }

    /**
     * @notice Executes a queued proposal on timelockV1 if eta has passed
     * This is only required for proposal that were queued on timelockV1, but before the upgrade to DAO V3.
     * These proposals will not have the `executeOnTimelockV1` bool turned on.
     */
    function executeOnTimelockV1(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) external {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        executeInternal(ds, proposal, ds.timelockV1);
    }

    function executeInternal(
        NounsDAOStorageV3.StorageV3 storage ds,
        NounsDAOStorageV3.Proposal storage proposal,
        INounsDAOExecutor timelock
    ) internal {
        require(
            state(ds, proposal.id) == NounsDAOStorageV3.ProposalState.Queued,
            'NounsDAO::execute: proposal can only be executed if it is queued'
        );
        if (ds.isForkPeriodActive()) revert CannotExecuteDuringForkingPeriod();

        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposal.id);
    }

    function getProposalTimelock(NounsDAOStorageV3.StorageV3 storage ds, NounsDAOStorageV3.Proposal storage proposal)
        internal
        view
        returns (INounsDAOExecutor)
    {
        if (proposal.executeOnTimelockV1) {
            return ds.timelockV1;
        } else {
            return ds.timelock;
        }
    }

    /**
     * @notice Vetoes a proposal only if sender is the vetoer and the proposal has not been executed.
     * @param proposalId The id of the proposal to veto
     */
    function veto(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) external {
        if (ds.vetoer == address(0)) {
            revert VetoerBurned();
        }

        if (msg.sender != ds.vetoer) {
            revert VetoerOnly();
        }

        if (stateInternal(ds, proposalId) == NounsDAOStorageV3.ProposalState.Executed) {
            revert CantVetoExecutedProposal();
        }

        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];

        proposal.vetoed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            ds.timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalVetoed(proposalId);
    }

    /**
     * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
     * @param proposalId The id of the proposal to cancel
     */
    function cancel(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) external {
        NounsDAOStorageV3.ProposalState proposalState = state(ds, proposalId);
        if (
            proposalState == NounsDAOStorageV3.ProposalState.Canceled ||
            proposalState == NounsDAOStorageV3.ProposalState.Defeated ||
            proposalState == NounsDAOStorageV3.ProposalState.Expired ||
            proposalState == NounsDAOStorageV3.ProposalState.Executed ||
            proposalState == NounsDAOStorageV3.ProposalState.Vetoed
        ) {
            revert CantCancelProposalAtFinalState();
        }

        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        address proposer = proposal.proposer;
        NounsTokenLike nouns = ds.nouns;

        uint256 votes = nouns.getPriorVotes(proposer, block.number - 1);
        bool msgSenderIsProposer = proposer == msg.sender;
        address[] memory signers = proposal.signers;
        for (uint256 i = 0; i < signers.length; ++i) {
            msgSenderIsProposer = msgSenderIsProposer || msg.sender == signers[i];
            votes += nouns.getPriorVotes(signers[i], block.number - 1);
        }

        require(
            msgSenderIsProposer || votes <= proposal.proposalThreshold,
            'NounsDAO::cancel: proposer above threshold'
        );

        proposal.canceled = true;
        INounsDAOExecutor timelock = getProposalTimelock(ds, proposal);
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId);
    }

    /**
     * @notice Gets the state of a proposal
     * @param ds the DAO's state struct
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId)
        public
        view
        returns (NounsDAOStorageV3.ProposalState)
    {
        return stateInternal(ds, proposalId);
    }

    /**
     * @notice Gets the state of a proposal
     * @dev This internal function is used by other libraries to embed in compile time and save the runtime gas cost of a delegate call
     * @param ds the DAO's state struct
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function stateInternal(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId)
        internal
        view
        returns (NounsDAOStorageV3.ProposalState)
    {
        require(ds.proposalCount >= proposalId, 'NounsDAO::state: invalid proposal id');
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];

        if (proposal.vetoed) {
            return NounsDAOStorageV3.ProposalState.Vetoed;
        } else if (proposal.canceled) {
            return NounsDAOStorageV3.ProposalState.Canceled;
        } else if (block.number <= proposal.updatePeriodEndBlock) {
            return NounsDAOStorageV3.ProposalState.Updatable;
        } else if (block.number <= proposal.startBlock) {
            return NounsDAOStorageV3.ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return NounsDAOStorageV3.ProposalState.Active;
        } else if (block.number <= proposal.objectionPeriodEndBlock) {
            return NounsDAOStorageV3.ProposalState.ObjectionPeriod;
        } else if (isDefeated(ds, proposal)) {
            return NounsDAOStorageV3.ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return NounsDAOStorageV3.ProposalState.Succeeded;
        } else if (proposal.executed) {
            return NounsDAOStorageV3.ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + getProposalTimelock(ds, proposal).GRACE_PERIOD()) {
            return NounsDAOStorageV3.ProposalState.Expired;
        } else {
            return NounsDAOStorageV3.ProposalState.Queued;
        }
    }

    /**
     * @notice Gets actions of a proposal
     * @param proposalId the id of the proposal
     * @return targets
     * @return values
     * @return signatures
     * @return calldatas
     */
    function getActions(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId)
        internal
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        NounsDAOStorageV3.Proposal storage p = ds._proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        address voter
    ) internal view returns (NounsDAOStorageV3.Receipt memory) {
        return ds._proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Returns the proposal details given a proposal id.
     *     The `quorumVotes` member holds the *current* quorum, given the current votes.
     * @param proposalId the proposal id to get the data for
     * @return A `ProposalCondensed` struct with the proposal data
     */
    function proposals(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId)
        external
        view
        returns (NounsDAOStorageV2.ProposalCondensed memory)
    {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        return
            NounsDAOStorageV2.ProposalCondensed({
                id: proposal.id,
                proposer: proposal.proposer,
                proposalThreshold: proposal.proposalThreshold,
                quorumVotes: ds.quorumVotes(proposal.id),
                eta: proposal.eta,
                startBlock: proposal.startBlock,
                endBlock: proposal.endBlock,
                forVotes: proposal.forVotes,
                againstVotes: proposal.againstVotes,
                abstainVotes: proposal.abstainVotes,
                canceled: proposal.canceled,
                vetoed: proposal.vetoed,
                executed: proposal.executed,
                totalSupply: proposal.totalSupply,
                creationBlock: proposal.creationBlock
            });
    }

    /**
     * @notice Returns the proposal details given a proposal id.
     *     The `quorumVotes` member holds the *current* quorum, given the current votes.
     * @param proposalId the proposal id to get the data for
     * @return A `ProposalCondensed` struct with the proposal data
     */
    function proposalsV3(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId)
        external
        view
        returns (NounsDAOStorageV3.ProposalCondensed memory)
    {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        return
            NounsDAOStorageV3.ProposalCondensed({
                id: proposal.id,
                proposer: proposal.proposer,
                proposalThreshold: proposal.proposalThreshold,
                quorumVotes: ds.quorumVotes(proposal.id),
                eta: proposal.eta,
                startBlock: proposal.startBlock,
                endBlock: proposal.endBlock,
                forVotes: proposal.forVotes,
                againstVotes: proposal.againstVotes,
                abstainVotes: proposal.abstainVotes,
                canceled: proposal.canceled,
                vetoed: proposal.vetoed,
                executed: proposal.executed,
                totalSupply: proposal.totalSupply,
                creationBlock: proposal.creationBlock,
                signers: proposal.signers,
                updatePeriodEndBlock: proposal.updatePeriodEndBlock,
                objectionPeriodEndBlock: proposal.objectionPeriodEndBlock,
                executeOnTimelockV1: proposal.executeOnTimelockV1
            });
    }

    /**
     * @notice Current proposal threshold using Noun Total Supply
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function proposalThreshold(NounsDAOStorageV3.StorageV3 storage ds, uint256 adjustedTotalSupply)
        internal
        view
        returns (uint256)
    {
        return bps2Uint(ds.proposalThresholdBPS, adjustedTotalSupply);
    }

    function isDefeated(NounsDAOStorageV3.StorageV3 storage ds, NounsDAOStorageV3.Proposal storage proposal)
        internal
        view
        returns (bool)
    {
        uint256 forVotes = proposal.forVotes;
        return forVotes <= proposal.againstVotes || forVotes < ds.quorumVotes(proposal.id);
    }

    /**
     * @notice reverts if `proposer` is the proposer or signer of an active proposal.
     * This is a spam protection mechanism to limit the number of proposals each noun can back.
     */
    function checkNoActiveProp(NounsDAOStorageV3.StorageV3 storage ds, address proposer) internal view {
        uint256 latestProposalId = ds.latestProposalIds[proposer];
        if (latestProposalId != 0) {
            NounsDAOStorageV3.ProposalState proposersLatestProposalState = state(ds, latestProposalId);
            if (
                proposersLatestProposalState == NounsDAOStorageV3.ProposalState.ObjectionPeriod ||
                proposersLatestProposalState == NounsDAOStorageV3.ProposalState.Active ||
                proposersLatestProposalState == NounsDAOStorageV3.ProposalState.Pending ||
                proposersLatestProposalState == NounsDAOStorageV3.ProposalState.Updatable
            ) revert ProposerAlreadyHasALiveProposal();
        }
    }

    /**
     * @dev Extracted this function to fix the `Stack too deep` error `proposeBySigs` hit.
     */
    function verifySignersCanBackThisProposalAndCountTheirVotes(
        NounsDAOStorageV3.StorageV3 storage ds,
        NounsDAOStorageV3.ProposerSignature[] memory proposerSignatures,
        ProposalTxs memory txs,
        string memory description,
        uint256 proposalId
    ) internal returns (uint256 votes, address[] memory signers) {
        NounsTokenLike nouns = ds.nouns;
        bytes memory proposalEncodeData = calcProposalEncodeData(msg.sender, txs, description);

        signers = new address[](proposerSignatures.length);
        for (uint256 i = 0; i < proposerSignatures.length; ++i) {
            verifyProposalSignature(ds, proposalEncodeData, proposerSignatures[i], PROPOSAL_TYPEHASH);
            address signer = signers[i] = proposerSignatures[i].signer;

            checkNoActiveProp(ds, signer);
            ds.latestProposalIds[signer] = proposalId;
            votes += nouns.getPriorVotes(signer, block.number - 1);
        }

        checkNoActiveProp(ds, msg.sender);
        ds.latestProposalIds[msg.sender] = proposalId;
        votes += nouns.getPriorVotes(msg.sender, block.number - 1);
    }

    function calcProposalEncodeData(
        address proposer,
        ProposalTxs memory txs,
        string memory description
    ) internal pure returns (bytes memory) {
        bytes32[] memory signatureHashes = new bytes32[](txs.signatures.length);
        for (uint256 i = 0; i < txs.signatures.length; ++i) {
            signatureHashes[i] = keccak256(bytes(txs.signatures[i]));
        }

        bytes32[] memory calldatasHashes = new bytes32[](txs.calldatas.length);
        for (uint256 i = 0; i < txs.calldatas.length; ++i) {
            calldatasHashes[i] = keccak256(txs.calldatas[i]);
        }

        return
            abi.encode(
                proposer,
                keccak256(abi.encodePacked(txs.targets)),
                keccak256(abi.encodePacked(txs.values)),
                keccak256(abi.encodePacked(signatureHashes)),
                keccak256(abi.encodePacked(calldatasHashes)),
                keccak256(bytes(description))
            );
    }

    function checkProposalUpdatable(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        NounsDAOStorageV3.Proposal storage proposal
    ) internal view {
        if (state(ds, proposalId) != NounsDAOStorageV3.ProposalState.Updatable) revert CanOnlyEditUpdatableProposals();
        if (msg.sender != proposal.proposer) revert OnlyProposerCanEdit();
        if (proposal.signers.length > 0) revert ProposerCannotUpdateProposalWithSigners();
    }

    function createNewProposal(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 proposalId,
        uint256 proposalThreshold_,
        uint256 adjustedTotalSupply,
        ProposalTxs memory txs
    ) internal returns (NounsDAOStorageV3.Proposal storage newProposal) {
        uint64 updatePeriodEndBlock = uint64(block.number + ds.proposalUpdatablePeriodInBlocks);
        uint256 startBlock = updatePeriodEndBlock + ds.votingDelay;
        uint256 endBlock = startBlock + ds.votingPeriod;

        newProposal = ds._proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.proposalThreshold = proposalThreshold_;
        newProposal.targets = txs.targets;
        newProposal.values = txs.values;
        newProposal.signatures = txs.signatures;
        newProposal.calldatas = txs.calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        newProposal.totalSupply = adjustedTotalSupply;
        newProposal.creationBlock = uint64(block.number);
        newProposal.updatePeriodEndBlock = updatePeriodEndBlock;
    }

    function emitNewPropEvents(
        NounsDAOStorageV3.Proposal storage newProposal,
        address[] memory signers,
        uint256 minQuorumVotes,
        ProposalTxs memory txs,
        string memory description
    ) internal {
        /// @notice Maintains backwards compatibility with GovernorBravo events
        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            txs.targets,
            txs.values,
            txs.signatures,
            txs.calldatas,
            newProposal.startBlock,
            newProposal.endBlock,
            description
        );

        /// @notice V1: Updated event with `proposalThreshold` and `quorumVotes` `minQuorumVotes`
        /// @notice V2: `quorumVotes` changed to `minQuorumVotes`
        /// @notice V3: Added signers and updatePeriodEndBlock
        emit ProposalCreatedWithRequirements(
            newProposal.id,
            msg.sender,
            signers,
            txs.targets,
            txs.values,
            txs.signatures,
            txs.calldatas,
            newProposal.startBlock,
            newProposal.endBlock,
            newProposal.updatePeriodEndBlock,
            newProposal.proposalThreshold,
            minQuorumVotes,
            description
        );
    }

    function checkPropThreshold(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256 votes,
        uint256 adjustedTotalSupply
    ) internal view returns (uint256 propThreshold) {
        propThreshold = proposalThreshold(ds, adjustedTotalSupply);
        require(votes > propThreshold, 'NounsDAO::propose: proposer votes below proposal threshold');
    }

    function checkProposalTxs(ProposalTxs memory txs) internal pure {
        if (
            txs.targets.length != txs.values.length ||
            txs.targets.length != txs.signatures.length ||
            txs.targets.length != txs.calldatas.length
        ) revert ProposalInfoArityMismatch();
        if (txs.targets.length == 0) revert MustProvideActions();
        if (txs.targets.length > proposalMaxOperations) revert TooManyActions();
    }

    function verifyProposalSignature(
        NounsDAOStorageV3.StorageV3 storage ds,
        bytes memory proposalEncodeData,
        NounsDAOStorageV3.ProposerSignature memory proposerSignature,
        bytes32 typehash
    ) internal view {
        bytes32 sigHash = keccak256(proposerSignature.sig);
        if (ds.cancelledSigs[proposerSignature.signer][sigHash]) revert SignatureIsCancelled();

        bytes32 digest = sigDigest(typehash, proposalEncodeData, proposerSignature.expirationTimestamp, address(this));
        if (!SignatureChecker.isValidSignatureNow(proposerSignature.signer, digest, proposerSignature.sig))
            revert InvalidSignature();

        if (block.timestamp > proposerSignature.expirationTimestamp) revert SignatureExpired();
    }

    /**
     * @notice Generate the digest (hash) used to verify proposal signatures.
     * @param typehash the EIP 712 type hash of the signed message, e.g. `PROPOSAL_TYPEHASH` or `UPDATE_PROPOSAL_TYPEHASH`.
     * @param proposalEncodeData the abi encoded proposal data, identical to the output of `calcProposalEncodeData`.
     * @param expirationTimestamp the signature's expiration timestamp.
     * @param verifyingContract the contract verifying the signature, e.g. the DAO proxy by default.
     * @return bytes32 the signature's typed data hash.
     */
    function sigDigest(
        bytes32 typehash,
        bytes memory proposalEncodeData,
        uint256 expirationTimestamp,
        address verifyingContract
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encodePacked(typehash, proposalEncodeData, expirationTimestamp));

        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes('Nouns DAO')), block.chainid, verifyingContract)
        );

        return ECDSA.toTypedDataHash(domainSeparator, structHash);
    }

    function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
        return (number * bps) / 10000;
    }
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
// NounsDAOStorageV3
// See NounsDAOLogicV3.sol for more details.

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

contract NounsDAOEventsV3 is NounsDAOEventsV2 {
    /// @notice An event emitted when a new proposal is created, which includes additional information
    /// @dev V3 adds `signers`, `updatePeriodEndBlock` compared to the V1/V2 event.
    event ProposalCreatedWithRequirements(
        uint256 id,
        address proposer,
        address[] signers,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        uint256 updatePeriodEndBlock,
        uint256 proposalThreshold,
        uint256 quorumVotes,
        string description
    );

    /// @notice Emitted when a proposal is created to be executed on timelockV1
    event ProposalCreatedOnTimelockV1(uint256 id);

    /// @notice Emitted when a proposal is updated
    event ProposalUpdated(
        uint256 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string description,
        string updateMessage
    );

    /// @notice Emitted when a proposal's transactions are updated
    event ProposalTransactionsUpdated(
        uint256 indexed id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        string updateMessage
    );

    /// @notice Emitted when a proposal's description is updated
    event ProposalDescriptionUpdated(
        uint256 indexed id,
        address indexed proposer,
        string description,
        string updateMessage
    );

    /// @notice Emitted when a proposal is set to have an objection period
    event ProposalObjectionPeriodSet(uint256 indexed id, uint256 objectionPeriodEndBlock);

    /// @notice Emitted when someone cancels a signature
    event SignatureCancelled(address indexed signer, bytes sig);

    /// @notice An event emitted when the objection period duration is set
    event ObjectionPeriodDurationSet(
        uint32 oldObjectionPeriodDurationInBlocks,
        uint32 newObjectionPeriodDurationInBlocks
    );

    /// @notice An event emitted when the objection period last minute window is set
    event LastMinuteWindowSet(uint32 oldLastMinuteWindowInBlocks, uint32 newLastMinuteWindowInBlocks);

    /// @notice An event emitted when the proposal updatable period is set
    event ProposalUpdatablePeriodSet(
        uint32 oldProposalUpdatablePeriodInBlocks,
        uint32 newProposalUpdatablePeriodInBlocks
    );

    /// @notice Emitted when the proposal id at which vote snapshot block changes is set
    event VoteSnapshotBlockSwitchProposalIdSet(
        uint256 oldVoteSnapshotBlockSwitchProposalId,
        uint256 newVoteSnapshotBlockSwitchProposalId
    );

    /// @notice Emitted when the erc20 tokens to include in a fork are set
    event ERC20TokensToIncludeInForkSet(address[] oldErc20Tokens, address[] newErc20tokens);

    /// @notice Emitted when the fork DAO deployer is set
    event ForkDAODeployerSet(address oldForkDAODeployer, address newForkDAODeployer);

    /// @notice Emitted when the during of the forking period is set
    event ForkPeriodSet(uint256 oldForkPeriod, uint256 newForkPeriod);

    /// @notice Emitted when the threhsold for forking is set
    event ForkThresholdSet(uint256 oldForkThreshold, uint256 newForkThreshold);

    /// @notice Emitted when the main timelock, timelockV1 and admin are set
    event TimelocksAndAdminSet(address timelock, address timelockV1, address admin);

    /// @notice Emitted when someones adds nouns to the fork escrow
    event EscrowedToFork(
        uint32 indexed forkId,
        address indexed owner,
        uint256[] tokenIds,
        uint256[] proposalIds,
        string reason
    );

    /// @notice Emitted when the owner withdraws their nouns from the fork escrow
    event WithdrawFromForkEscrow(uint32 indexed forkId, address indexed owner, uint256[] tokenIds);

    /// @notice Emitted when the fork is executed and the forking period begins
    event ExecuteFork(
        uint32 indexed forkId,
        address forkTreasury,
        address forkToken,
        uint256 forkEndTimestamp,
        uint256 tokensInEscrow
    );

    /// @notice Emitted when someone joins a fork during the forking period
    event JoinFork(
        uint32 indexed forkId,
        address indexed owner,
        uint256[] tokenIds,
        uint256[] proposalIds,
        string reason
    );

    /// @notice Emitted when the DAO withdraws nouns from the fork escrow after a fork has been executed
    event DAOWithdrawNounsFromEscrow(uint256[] tokenIds, address to);
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

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function minter() external view returns (address);

    function mint() external returns (uint256);

    function setApprovalForAll(address operator, bool approved) external;
}

interface IForkDAODeployer {
    function deployForkDAO(uint256 forkingPeriodEndTimestamp, INounsDAOForkEscrow forkEscrowAddress)
        external
        returns (address treasury, address token);

    function tokenImpl() external view returns (address);

    function auctionImpl() external view returns (address);

    function governorImpl() external view returns (address);

    function treasuryImpl() external view returns (address);
}

interface INounsDAOExecutorV2 is INounsDAOExecutor {
    function sendETH(address newDAOTreasury, uint256 ethToSend) external returns (bool success);

    function sendERC20(
        address newDAOTreasury,
        address erc20Token,
        uint256 tokensToSend
    ) external returns (bool success);
}

interface INounsDAOForkEscrow {
    function markOwner(address owner, uint256[] calldata tokenIds) external;

    function returnTokensToOwner(address owner, uint256[] calldata tokenIds) external;

    function closeEscrow() external returns (uint32);

    function numTokensInEscrow() external view returns (uint256);

    function numTokensOwnedByDAO() external view returns (uint256);

    function withdrawTokens(uint256[] calldata tokenIds, address to) external;

    function forkId() external view returns (uint32);

    function nounsToken() external view returns (NounsTokenLike);

    function dao() external view returns (address);

    function ownerOfEscrowedToken(uint32 forkId_, uint256 tokenId) external view returns (address);
}

contract NounsDAOStorageV3 {
    StorageV3 ds;

    struct StorageV3 {
        // ================ PROXY ================ //
        /// @notice Administrator for this contract
        address admin;
        /// @notice Pending administrator for this contract
        address pendingAdmin;
        /// @notice Active brains of Governor
        address implementation;
        // ================ V1 ================ //
        /// @notice Vetoer who has the ability to veto any proposal
        address vetoer;
        /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
        uint256 votingDelay;
        /// @notice The duration of voting on a proposal, in blocks
        uint256 votingPeriod;
        /// @notice The basis point number of votes required in order for a voter to become a proposer. *DIFFERS from GovernerBravo
        uint256 proposalThresholdBPS;
        /// @notice The basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed. *DIFFERS from GovernerBravo
        uint256 quorumVotesBPS;
        /// @notice The total number of proposals
        uint256 proposalCount;
        /// @notice The address of the Nouns DAO Executor NounsDAOExecutor
        INounsDAOExecutorV2 timelock;
        /// @notice The address of the Nouns tokens
        NounsTokenLike nouns;
        /// @notice The official record of all proposals ever proposed
        mapping(uint256 => Proposal) _proposals;
        /// @notice The latest proposal for each proposer
        mapping(address => uint256) latestProposalIds;
        // ================ V2 ================ //
        DynamicQuorumParamsCheckpoint[] quorumParamsCheckpoints;
        /// @notice Pending new vetoer
        address pendingVetoer;
        // ================ V3 ================ //
        /// @notice user => sig => isCancelled: signatures that have been cancelled by the signer and are no longer valid
        mapping(address => mapping(bytes32 => bool)) cancelledSigs;
        /// @notice The number of blocks before voting ends during which the objection period can be initiated
        uint32 lastMinuteWindowInBlocks;
        /// @notice Length of the objection period in blocks
        uint32 objectionPeriodDurationInBlocks;
        /// @notice Length of proposal updatable period in block
        uint32 proposalUpdatablePeriodInBlocks;
        /// @notice address of the DAO's fork escrow contract
        INounsDAOForkEscrow forkEscrow;
        /// @notice address of the DAO's fork deployer contract
        IForkDAODeployer forkDAODeployer;
        /// @notice ERC20 tokens to include when sending funds to a deployed fork
        address[] erc20TokensToIncludeInFork;
        /// @notice The treasury contract of the last deployed fork
        address forkDAOTreasury;
        /// @notice The token contract of the last deployed fork
        address forkDAOToken;
        /// @notice Timestamp at which the last fork period ends
        uint256 forkEndTimestamp;
        /// @notice Fork period in seconds
        uint256 forkPeriod;
        /// @notice Threshold defined in basis points (10,000 = 100%) required for forking
        uint256 forkThresholdBPS;
        /// @notice Address of the original timelock
        INounsDAOExecutor timelockV1;
        /// @notice The proposal at which to start using `startBlock` instead of `creationBlock` for vote snapshots
        /// @dev Make sure this stays the last variable in this struct, so we can delete it in the next version
        /// @dev To be zeroed-out and removed in a V3.1 fix version once the switch takes place
        uint256 voteSnapshotBlockSwitchProposalId;
    }

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
        uint64 creationBlock;
        /// @notice The last block which allows updating a proposal's description and transactions
        uint64 updatePeriodEndBlock;
        /// @notice Starts at 0 and is set to the block at which the objection period ends when the objection period is initiated
        uint64 objectionPeriodEndBlock;
        /// @dev unused for now
        uint64 placeholder;
        /// @notice The signers of a proposal, when using proposeBySigs
        address[] signers;
        /// @notice When true, a proposal would be executed on timelockV1 instead of the current timelock
        bool executeOnTimelockV1;
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

    struct ProposerSignature {
        /// @notice Signature of a proposal
        bytes sig;
        /// @notice The address of the signer
        address signer;
        /// @notice The timestamp until which the signature is valid
        uint256 expirationTimestamp;
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
        /// @notice The signers of a proposal, when using proposeBySigs
        address[] signers;
        /// @notice The last block which allows updating a proposal's description and transactions
        uint256 updatePeriodEndBlock;
        /// @notice Starts at 0 and is set to the block at which the objection period ends when the objection period is initiated
        uint256 objectionPeriodEndBlock;
        /// @notice When true, a proposal would be executed on timelockV1 instead of the current timelock
        bool executeOnTimelockV1;
    }

    struct DynamicQuorumParams {
        /// @notice The minimum basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed.
        uint16 minQuorumVotesBPS;
        /// @notice The maximum basis point number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed.
        uint16 maxQuorumVotesBPS;
        /// @notice The dynamic quorum coefficient
        /// @dev Assumed to be fixed point integer with 6 decimals, i.e 0.2 is represented as 0.2 * 1e6 = 200000
        uint32 quorumCoefficient;
    }

    struct NounsDAOParams {
        uint256 votingPeriod;
        uint256 votingDelay;
        uint256 proposalThresholdBPS;
        uint32 lastMinuteWindowInBlocks;
        uint32 objectionPeriodDurationInBlocks;
        uint32 proposalUpdatablePeriodInBlocks;
    }

    /// @notice A checkpoint for storing dynamic quorum params from a given block
    struct DynamicQuorumParamsCheckpoint {
        /// @notice The block at which the new values were set
        uint32 fromBlock;
        /// @notice The parameter values of this checkpoint
        DynamicQuorumParams params;
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
        Vetoed,
        ObjectionPeriod,
        Updatable
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Library for NounsDAOLogicV3 contract containing functions related to quorum calculations

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

pragma solidity ^0.8.6;

import './NounsDAOInterfaces.sol';
import { NounsDAOV3Fork } from './fork/NounsDAOV3Fork.sol';

library NounsDAOV3DynamicQuorum {
    using NounsDAOV3Fork for NounsDAOStorageV3.StorageV3;

    error UnsafeUint16Cast();

    /**
     * @notice Quorum votes required for a specific proposal to succeed
     * Differs from `GovernerBravo` which uses fixed amount
     */
    function quorumVotes(NounsDAOStorageV3.StorageV3 storage ds, uint256 proposalId) internal view returns (uint256) {
        NounsDAOStorageV3.Proposal storage proposal = ds._proposals[proposalId];
        if (proposal.totalSupply == 0) {
            return proposal.quorumVotes;
        }

        return
            dynamicQuorumVotes(
                proposal.againstVotes,
                proposal.totalSupply,
                getDynamicQuorumParamsAt(ds, proposal.creationBlock)
            );
    }

    /**
     * @notice Calculates the required quorum of for-votes based on the amount of against-votes
     *     The more against-votes there are for a proposal, the higher the required quorum is.
     *     The quorum BPS is between `params.minQuorumVotesBPS` and params.maxQuorumVotesBPS.
     *     The additional quorum is calculated as:
     *       quorumCoefficient * againstVotesBPS
     * @dev Note the coefficient is a fixed point integer with 6 decimals
     * @param againstVotes Number of against-votes in the proposal
     * @param totalSupply The total supply of Nouns at the time of proposal creation
     * @param params Configurable parameters for calculating the quorum based on againstVotes. See `DynamicQuorumParams` definition for additional details.
     * @return quorumVotes The required quorum
     */
    function dynamicQuorumVotes(
        uint256 againstVotes,
        uint256 totalSupply,
        NounsDAOStorageV3.DynamicQuorumParams memory params
    ) public pure returns (uint256) {
        uint256 againstVotesBPS = (10000 * againstVotes) / totalSupply;
        uint256 quorumAdjustmentBPS = (params.quorumCoefficient * againstVotesBPS) / 1e6;
        uint256 adjustedQuorumBPS = params.minQuorumVotesBPS + quorumAdjustmentBPS;
        uint256 quorumBPS = min(params.maxQuorumVotesBPS, adjustedQuorumBPS);
        return bps2Uint(quorumBPS, totalSupply);
    }

    /**
     * @notice returns the dynamic quorum parameters values at a certain block number
     * @dev The checkpoints array must not be empty, and the block number must be higher than or equal to
     *     the block of the first checkpoint
     * @param blockNumber_ the block number to get the params at
     * @return The dynamic quorum parameters that were set at the given block number
     */
    function getDynamicQuorumParamsAt(NounsDAOStorageV3.StorageV3 storage ds, uint256 blockNumber_)
        internal
        view
        returns (NounsDAOStorageV3.DynamicQuorumParams memory)
    {
        uint32 blockNumber = safe32(blockNumber_, 'NounsDAO::getDynamicQuorumParamsAt: block number exceeds 32 bits');
        uint256 len = ds.quorumParamsCheckpoints.length;

        if (len == 0) {
            return
                NounsDAOStorageV3.DynamicQuorumParams({
                    minQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    maxQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    quorumCoefficient: 0
                });
        }

        if (ds.quorumParamsCheckpoints[len - 1].fromBlock <= blockNumber) {
            return ds.quorumParamsCheckpoints[len - 1].params;
        }

        if (ds.quorumParamsCheckpoints[0].fromBlock > blockNumber) {
            return
                NounsDAOStorageV3.DynamicQuorumParams({
                    minQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    maxQuorumVotesBPS: safe16(ds.quorumVotesBPS),
                    quorumCoefficient: 0
                });
        }

        uint256 lower = 0;
        uint256 upper = len - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2;
            NounsDAOStorageV3.DynamicQuorumParamsCheckpoint memory cp = ds.quorumParamsCheckpoints[center];
            if (cp.fromBlock == blockNumber) {
                return cp.params;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return ds.quorumParamsCheckpoints[lower].params;
    }

    /**
     * @notice Current min quorum votes using Noun total supply
     */
    function minQuorumVotes(NounsDAOStorageV3.StorageV3 storage ds, uint256 adjustedTotalSupply)
        internal
        view
        returns (uint256)
    {
        return bps2Uint(getDynamicQuorumParamsAt(ds, block.number).minQuorumVotesBPS, adjustedTotalSupply);
    }

    /**
     * @notice Current max quorum votes using Noun total supply
     */
    function maxQuorumVotes(NounsDAOStorageV3.StorageV3 storage ds, uint256 adjustedTotalSupply)
        internal
        view
        returns (uint256)
    {
        return bps2Uint(getDynamicQuorumParamsAt(ds, block.number).maxQuorumVotesBPS, adjustedTotalSupply);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n <= type(uint32).max, errorMessage);
        return uint32(n);
    }

    function safe16(uint256 n) internal pure returns (uint16) {
        if (n > type(uint16).max) {
            revert UnsafeUint16Cast();
        }
        return uint16(n);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function bps2Uint(uint256 bps, uint256 number) internal pure returns (uint256) {
        return (number * bps) / 10000;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Library for NounsDAOLogicV3 contract containing the dao fork logic

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

pragma solidity ^0.8.6;

import { NounsDAOStorageV3, INounsDAOForkEscrow, INounsDAOExecutorV2 } from '../NounsDAOInterfaces.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { NounsTokenFork } from './newdao/token/NounsTokenFork.sol';

library NounsDAOV3Fork {
    error ForkThresholdNotMet();
    error ForkPeriodNotActive();
    error ForkPeriodActive();
    error AdminOnly();
    error ETHTransferFailed();
    error ERC20TransferFailed();

    /// @notice Emitted when someones adds nouns to the fork escrow
    event EscrowedToFork(
        uint32 indexed forkId,
        address indexed owner,
        uint256[] tokenIds,
        uint256[] proposalIds,
        string reason
    );

    /// @notice Emitted when the owner withdraws their nouns from the fork escrow
    event WithdrawFromForkEscrow(uint32 indexed forkId, address indexed owner, uint256[] tokenIds);

    /// @notice Emitted when the fork is executed and the forking period begins
    event ExecuteFork(
        uint32 indexed forkId,
        address forkTreasury,
        address forkToken,
        uint256 forkEndTimestamp,
        uint256 tokensInEscrow
    );

    /// @notice Emitted when someone joins a fork during the forking period
    event JoinFork(
        uint32 indexed forkId,
        address indexed owner,
        uint256[] tokenIds,
        uint256[] proposalIds,
        string reason
    );

    /// @notice Emitted when the DAO withdraws nouns from the fork escrow after a fork has been executed
    event DAOWithdrawNounsFromEscrow(uint256[] tokenIds, address to);

    /**
     * @notice Escrow Nouns to contribute to the fork threshold
     * @dev Requires approving the tokenIds or the entire noun token to the DAO contract
     * @param tokenIds the tokenIds to escrow. They will be sent to the DAO once the fork threshold is reached and the escrow is closed.
     * @param proposalIds array of proposal ids which are the reason for wanting to fork. This will only be used to emit event.
     * @param reason the reason for want to fork. This will only be used to emit event.
     */
    function escrowToFork(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256[] calldata tokenIds,
        uint256[] calldata proposalIds,
        string calldata reason
    ) external {
        if (isForkPeriodActive(ds)) revert ForkPeriodActive();
        INounsDAOForkEscrow forkEscrow = ds.forkEscrow;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            ds.nouns.safeTransferFrom(msg.sender, address(forkEscrow), tokenIds[i]);
        }

        emit EscrowedToFork(forkEscrow.forkId(), msg.sender, tokenIds, proposalIds, reason);
    }

    /**
     * @notice Withdraw Nouns from the fork escrow. Only possible if the fork has not been executed.
     * Only allowed to withdraw tokens that the sender has escrowed.
     * @param tokenIds the tokenIds to withdraw
     */
    function withdrawFromForkEscrow(NounsDAOStorageV3.StorageV3 storage ds, uint256[] calldata tokenIds) external {
        if (isForkPeriodActive(ds)) revert ForkPeriodActive();

        INounsDAOForkEscrow forkEscrow = ds.forkEscrow;
        forkEscrow.returnTokensToOwner(msg.sender, tokenIds);

        emit WithdrawFromForkEscrow(forkEscrow.forkId(), msg.sender, tokenIds);
    }

    /**
     * @notice Execute the fork. Only possible if the fork threshold has been exceeded.
     * This will deploy a new DAO and send the prorated part of the treasury to the new DAO's treasury.
     * This will also close the active escrow and all nouns in the escrow will belong to the original DAO.
     * @return forkTreasury The address of the new DAO's treasury
     * @return forkToken The address of the new DAO's token
     */
    function executeFork(NounsDAOStorageV3.StorageV3 storage ds)
        external
        returns (address forkTreasury, address forkToken)
    {
        if (isForkPeriodActive(ds)) revert ForkPeriodActive();
        INounsDAOForkEscrow forkEscrow = ds.forkEscrow;

        uint256 tokensInEscrow = forkEscrow.numTokensInEscrow();
        if (tokensInEscrow <= forkThreshold(ds)) revert ForkThresholdNotMet();

        uint256 forkEndTimestamp = block.timestamp + ds.forkPeriod;

        (forkTreasury, forkToken) = ds.forkDAODeployer.deployForkDAO(forkEndTimestamp, forkEscrow);
        sendProRataTreasury(ds, forkTreasury, tokensInEscrow, adjustedTotalSupply(ds));
        uint32 forkId = forkEscrow.closeEscrow();

        ds.forkDAOTreasury = forkTreasury;
        ds.forkDAOToken = forkToken;
        ds.forkEndTimestamp = forkEndTimestamp;

        emit ExecuteFork(forkId, forkTreasury, forkToken, forkEndTimestamp, tokensInEscrow);
    }

    /**
     * @notice Joins a fork while a fork is active
     * Sends the tokens to the escrow contract.
     * Sends a prorated part of the treasury to the new fork DAO's treasury.
     * Mints new tokens in the new fork DAO with the same token ids.
     * @param tokenIds the tokenIds to send to the DAO in exchange for joining the fork
     */
    function joinFork(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256[] calldata tokenIds,
        uint256[] calldata proposalIds,
        string calldata reason
    ) external {
        if (!isForkPeriodActive(ds)) revert ForkPeriodNotActive();

        INounsDAOForkEscrow forkEscrow = ds.forkEscrow;
        sendProRataTreasury(ds, ds.forkDAOTreasury, tokenIds.length, adjustedTotalSupply(ds));

        for (uint256 i = 0; i < tokenIds.length; i++) {
            ds.nouns.transferFrom(msg.sender, address(forkEscrow), tokenIds[i]);
        }

        NounsTokenFork(ds.forkDAOToken).claimDuringForkPeriod(msg.sender, tokenIds);

        emit JoinFork(forkEscrow.forkId() - 1, msg.sender, tokenIds, proposalIds, reason);
    }

    /**
     * @notice Withdraws nouns from the fork escrow after the fork has been executed
     * @dev Only the DAO can call this function
     * @param tokenIds the tokenIds to withdraw
     * @param to the address to send the nouns to
     */
    function withdrawDAONounsFromEscrow(
        NounsDAOStorageV3.StorageV3 storage ds,
        uint256[] calldata tokenIds,
        address to
    ) external {
        if (msg.sender != ds.admin) {
            revert AdminOnly();
        }

        ds.forkEscrow.withdrawTokens(tokenIds, to);

        emit DAOWithdrawNounsFromEscrow(tokenIds, to);
    }

    /**
     * @notice Returns the required number of tokens to escrow to trigger a fork
     */
    function forkThreshold(NounsDAOStorageV3.StorageV3 storage ds) public view returns (uint256) {
        return (adjustedTotalSupply(ds) * ds.forkThresholdBPS) / 10_000;
    }

    /**
     * @notice Returns the number of tokens currently in escrow, contributing to the fork threshold
     */
    function numTokensInForkEscrow(NounsDAOStorageV3.StorageV3 storage ds) public view returns (uint256) {
        return ds.forkEscrow.numTokensInEscrow();
    }

    /**
     * @notice Returns the number of nouns in supply minus nouns owned by the DAO, i.e. held in the treasury or in an
     * escrow after it has closed.
     * This is used when calculating proposal threshold, quorum, fork threshold & treasury split.
     */
    function adjustedTotalSupply(NounsDAOStorageV3.StorageV3 storage ds) internal view returns (uint256) {
        return ds.nouns.totalSupply() - ds.nouns.balanceOf(address(ds.timelock)) - ds.forkEscrow.numTokensOwnedByDAO();
    }

    function isForkPeriodActive(NounsDAOStorageV3.StorageV3 storage ds) internal view returns (bool) {
        return ds.forkEndTimestamp > block.timestamp;
    }

    /**
     * @notice Sends part of the DAO's treasury to the `newDAOTreasury` address.
     * The amount sent is proportional to the `tokenCount` out of `totalSupply`.
     * Sends ETH and ERC20 tokens listed in `ds.erc20TokensToIncludeInFork`.
     */
    function sendProRataTreasury(
        NounsDAOStorageV3.StorageV3 storage ds,
        address newDAOTreasury,
        uint256 tokenCount,
        uint256 totalSupply
    ) internal {
        INounsDAOExecutorV2 timelock = ds.timelock;
        uint256 ethToSend = (address(timelock).balance * tokenCount) / totalSupply;

        bool ethSent = timelock.sendETH(newDAOTreasury, ethToSend);
        if (!ethSent) revert ETHTransferFailed();

        uint256 erc20Count = ds.erc20TokensToIncludeInFork.length;
        for (uint256 i = 0; i < erc20Count; ++i) {
            IERC20 erc20token = IERC20(ds.erc20TokensToIncludeInFork[i]);
            uint256 tokensToSend = (erc20token.balanceOf(address(timelock)) * tokenCount) / totalSupply;
            bool erc20Sent = timelock.sendERC20(newDAOTreasury, address(erc20token), tokensToSend);
            if (!erc20Sent) revert ERC20TransferFailed();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns ERC-721 token, adjusted for forks

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

pragma solidity ^0.8.6;

import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { ERC721CheckpointableUpgradeable } from './base/ERC721CheckpointableUpgradeable.sol';
import { INounsDescriptorMinimal } from '../../../../interfaces/INounsDescriptorMinimal.sol';
import { INounsSeeder } from '../../../../interfaces/INounsSeeder.sol';
import { INounsTokenFork } from './INounsTokenFork.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { UUPSUpgradeable } from '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';
import { INounsDAOForkEscrow } from '../../../NounsDAOInterfaces.sol';

contract NounsTokenFork is INounsTokenFork, OwnableUpgradeable, ERC721CheckpointableUpgradeable, UUPSUpgradeable {
    error OnlyOwner();
    error OnlyTokenOwnerCanClaim();
    error OnlyOriginalDAO();
    error NoundersCannotBeAddressZero();
    error OnlyDuringForkingPeriod();

    string public constant NAME = 'NounsTokenFork';

    /// @notice  An address who has permissions to mint Nouns
    address public minter;

    /// @notice The Nouns token URI descriptor
    INounsDescriptorMinimal public descriptor;

    /// @notice The Nouns token seeder
    INounsSeeder public seeder;

    /// @notice The escrow contract used to verify ownership of the original Nouns in the post-fork claiming process
    INounsDAOForkEscrow public escrow;

    /// @notice The fork ID, used when querying the escrow for token ownership
    uint32 public forkId;

    /// @notice How many tokens are still available to be claimed by Nouners who put their original Nouns in escrow
    uint256 public remainingTokensToClaim;

    /// @notice The forking period expiration timestamp, afterwhich new tokens cannot be claimed by the original DAO
    uint256 public forkingPeriodEndTimestamp;

    /// @notice Whether the minter can be updated
    bool public isMinterLocked;

    /// @notice Whether the descriptor can be updated
    bool public isDescriptorLocked;

    /// @notice Whether the seeder can be updated
    bool public isSeederLocked;

    /// @notice The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    /// @notice The internal noun ID tracker
    uint256 private _currentNounId;

    /// @notice IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmZi1n79FqWt2tTLwCqiy6nLM6xLGRsEPQ5JmReJQKNNzX';

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    function initialize(
        address _owner,
        address _minter,
        INounsDAOForkEscrow _escrow,
        uint32 _forkId,
        uint256 startNounId,
        uint256 tokensToClaim,
        uint256 _forkingPeriodEndTimestamp
    ) external initializer {
        __ERC721_init('Nouns', 'NOUN');
        _transferOwnership(_owner);
        minter = _minter;
        escrow = _escrow;
        forkId = _forkId;
        _currentNounId = startNounId;
        remainingTokensToClaim = tokensToClaim;
        forkingPeriodEndTimestamp = _forkingPeriodEndTimestamp;

        NounsTokenFork originalToken = NounsTokenFork(address(escrow.nounsToken()));
        descriptor = originalToken.descriptor();
        seeder = originalToken.seeder();
    }

    /**
     * @notice Claim new tokens if you escrowed original Nouns and forked into a new DAO governed by holders of this
     * token.
     * @dev Reverts if the sender is not the owner of the escrowed token.
     * @param tokenIds The token IDs to claim
     */
    function claimFromEscrow(uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 nounId = tokenIds[i];
            if (escrow.ownerOfEscrowedToken(forkId, nounId) != msg.sender) revert OnlyTokenOwnerCanClaim();

            _mintWithOriginalSeed(msg.sender, nounId);
        }

        remainingTokensToClaim -= tokenIds.length;
    }

    /**
     * @notice The original DAO can claim tokens during the forking period, on behalf of Nouners who choose to join
     * a new fork DAO. Does not allow the original DAO to claim once the forking period has ended.
     * @dev Assumes the original DAO is honest during the forking period.
     * @param to The recipient of the tokens
     * @param tokenIds The token IDs to claim
     */
    function claimDuringForkPeriod(address to, uint256[] calldata tokenIds) external {
        if (msg.sender != escrow.dao()) revert OnlyOriginalDAO();
        if (block.timestamp > forkingPeriodEndTimestamp) revert OnlyDuringForkingPeriod();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 nounId = tokenIds[i];
            _mintWithOriginalSeed(to, nounId);
        }
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Mint a Noun to the minter, along with a possible nounders reward
     * Noun. Nounders reward Nouns are minted every 10 Nouns, starting at 0,
     * until 183 nounder Nouns have been minted (5 years w/ 24 hour auctions).
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        return _mintTo(minter, _currentNounId++);
    }

    /**
     * @notice Burn a noun.
     */
    function burn(uint256 nounId) public override onlyMinter {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptorMinimal _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, descriptor);

        _mint(to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }

    /**
     * @notice Mint a new token using the original Nouns seed.
     */
    function _mintWithOriginalSeed(address to, uint256 nounId) internal {
        (uint48 background, uint48 body, uint48 accessory, uint48 head, uint48 glasses) = NounsTokenFork(
            address(escrow.nounsToken())
        ).seeds(nounId);
        INounsSeeder.Seed memory seed = INounsSeeder.Seed(background, body, accessory, head, glasses);

        seeds[nounId] = seed;
        _mint(to, nounId);

        emit NounCreated(nounId, seed);
    }

    /**
     * @dev Reverts when `msg.sender` is not the owner of this contract; in the case of Noun DAOs it should be the
     * DAO's treasury contract.
     */
    function _authorizeUpgrade(address) internal view override onlyOwner {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BSD-3-Clause

/// @title Vote checkpointing for an ERC-721 token

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
// ERC721CheckpointableUpgradeable.sol is a modified version of ERC721Checkpointable.sol in this repository.
// ERC721Checkpointable.sol uses and modifies part of Compound Lab's Comp.sol:
// https://github.com/compound-finance/compound-protocol/blob/ae4388e780a8d596d97619d9704a931a2752c2bc/contracts/Governance/Comp.sol
//
// Comp.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
// With modifications by Nounders DAO.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause
//
// ERC721CheckpointableUpgradeable.sol MODIFICATIONS:
// - Inherits from OpenZeppelin's ERC721EnumerableUpgradeable.sol, removing the original modification Nouns made to
//   ERC721.sol, where for each mint two Transfer events were emitted; this modified implementation sticks with the
//   OpenZeppelin standard.
// - More importantly, this inheritance change makes the token upgradable, which we deemed important in the context of
//   forks, in order to give new Nouns forks enough of a chance to modify their contracts to the new DAO's needs.
// - Fixes a critical bug in `delegateBySig`, where the previous version allowed delegating to address zero, which then
//   reverts whenever that owner tries to delegate anew or transfer their tokens. The fix is simply to revert on any
//   attempt to delegate to address zero.
//
// ERC721Checkpointable.sol MODIFICATIONS:
// Checkpointing logic from Comp.sol has been used with the following modifications:
// - `delegates` is renamed to `_delegates` and is set to private
// - `delegates` is a public function that uses the `_delegates` mapping look-up, but unlike
//   Comp.sol, returns the delegator's own address if there is no delegate.
//   This avoids the delegator needing to "delegate to self" with an additional transaction
// - `_transferTokens()` is renamed `_beforeTokenTransfer()` and adapted to hook into OpenZeppelin's ERC721 hooks.

pragma solidity ^0.8.6;

import { ERC721EnumerableUpgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';

abstract contract ERC721CheckpointableUpgradeable is ERC721EnumerableUpgradeable {
    /// @notice Defines decimals as per ERC-20 convention to make integrations with 3rd party governance platforms easier
    uint8 public constant decimals = 0;

    /// @notice A record of each accounts delegate
    mapping(address => address) private _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @notice The votes a delegator can delegate, which is the current balance of the delegator.
     * @dev Used when calling `_delegate()`
     */
    function votesToDelegate(address delegator) public view returns (uint96) {
        return safe96(balanceOf(delegator), 'ERC721Checkpointable::votesToDelegate: amount exceeds 96 bits');
    }

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /**
     * @notice Adapted from `_transferTokens()` in `Comp.sol` to update delegate votes.
     * @dev hooks into OpenZeppelin's `ERC721._transfer`
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        /// @notice Differs from `_transferTokens()` to use `delegates` override method to simulate auto-delegation
        _moveDelegates(delegates(from), delegates(to), 1);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        if (delegatee == address(0)) delegatee = msg.sender;
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(delegatee != address(0), 'ERC721Checkpointable::delegateBySig: delegatee cannot be zero address');
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'ERC721Checkpointable::delegateBySig: invalid signature');
        require(nonce == nonces[signatory]++, 'ERC721Checkpointable::delegateBySig: invalid nonce');
        require(block.timestamp <= expiry, 'ERC721Checkpointable::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, 'ERC721Checkpointable::getPriorVotes: not yet determined');

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        uint96 amount = votesToDelegate(delegator);

        _moveDelegates(currentDelegate, delegatee, amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'ERC721Checkpointable::_moveDelegates: amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'ERC721Checkpointable::_moveDelegates: amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            'ERC721Checkpointable::_writeCheckpoint: block number exceeds 32 bits'
        );

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

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

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

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

pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptorMinimal descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsTokenFork

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

pragma solidity ^0.8.6;

import { IERC721Upgradeable } from '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';
import { INounsDescriptorMinimal } from '../../../../interfaces/INounsDescriptorMinimal.sol';
import { INounsSeeder } from '../../../../interfaces/INounsSeeder.sol';

interface INounsTokenFork is IERC721Upgradeable {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event NoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(INounsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INounsSeeder seeder) external;

    function lockSeeder() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}