// SPDX-License-Identifier: BSD-3-Clause

/// @title Federation Delegate

import "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NounsTokenLike, NounsDAOStorageV1} from "./external/nouns/governance/NounsDAOInterfaces.sol";
import "./federation.sol";

pragma solidity ^0.8.16;

contract DelegateFixedQuorum is DelegateEvents {
    /// @notice The name of this contract
    string public constant name = "federation fixed quorum";

    /// @notice the address of the vetoer
    address public vetoer;    

    /// @notice the address of the controlling DAO logic contract
    NounsDAOStorageV1 public ownerDAO;

    /// @notice the address of the token that governs the owner DAO
    NounsTokenLike public nounishToken;

    /// @notice The total number of delegate actions proposed
    uint256 public proposalCount;

    /// @notice the window in blocks that a proposal which has met quorum can be executed
    uint256 public execWindow;

    /// @notice the default quorum for all proposals
    uint256 public quorum;

    /// @notice The official record of all delegate actions ever proposed
    mapping(uint256 => DelegateAction) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /**
     * @param nounishToken_ The address of the Nounish tokens that govern the owner DAO
     * @param ownerDAO_ The address of the external Nounish DAO
     * @param execWindow_ The window in blocks that a proposal which has met quorum can be executed
     * @param quorum_ Fixed quorum for proposal
     */
    constructor(address _vetoer, address nounishToken_, NounsDAOStorageV1 ownerDAO_, uint256 execWindow_, uint256 quorum_) {
        require(
            address(ownerDAO_) != address(0),
            "invalid owner dao address"
        );

        require(
            nounishToken_ != address(0),
            "invalid nounish NFT address"
        );

        nounishToken = NounsTokenLike(nounishToken_);
        ownerDAO = ownerDAO_;
        execWindow = execWindow_;
        vetoer = _vetoer;
        quorum = quorum_;
    }

    function _externalProposal(NounsDAOStorageV1 eDAO, uint256 ePropID) public view returns (uint256) {
        (,,,,,, uint256 ePropEndBlock,,,,,,) = eDAO.proposals(
            ePropID
        );

        return ePropEndBlock;
    }

    function _alreadyProposed(address eDAO, uint256 ePropID) public view returns (bool) {
        for (uint i=1; i <= proposalCount; i++){
            if (proposals[i].eDAO == eDAO && proposals[i].eID == ePropID) {
                return true;
            }
        }

        return false;
    }

    /**
     * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
     * @param eDAO Target address of the external DAO executor
     * @param ePropID The ID of the proposal on the external DAO
     * @return Proposal id of internal delegate action
     */
    function propose(NounsDAOStorageV1 eDAO, uint256 ePropID) public returns (uint256) {
        require(
            nounishToken.getPriorVotes(msg.sender, block.number - 1) > 0,
            "representation required to start a vote"
        );

        require(
            address(eDAO) != address(0),
            "external DAO address is not valid"
        );

        require (
            !_alreadyProposed(address(eDAO), ePropID),
            "proposal already proposed"
        );

        // this delegate must have representation before voting can be started
        try eDAO.nouns().getPriorVotes(address(this), block.number - 1) returns (uint96 votes) {
            require(votes > 0, "delegate does not have external DAO representation");   
        } catch(bytes memory) {
            revert("checking delegate representation on external DAO failed");
        }        

        // check when external proposal ends
        uint256 ePropEndBlock;
        try this._externalProposal(eDAO, ePropID) returns (uint256 endBlock) {
            ePropEndBlock = endBlock;
        } catch(bytes memory) {
            revert(
                string.concat("invalid external proposal id: ", 
                    Strings.toString(ePropID), 
                    " for external DAO: ", 
                    Strings.toHexString(address(eDAO))
                )
            );
        }

        require(ePropEndBlock > block.number, "external proposal has already ended or does not exist");

        proposalCount++;
        DelegateAction storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.eID = ePropID;
        newProposal.eDAO = address(eDAO);
        newProposal.proposer = msg.sender;
        newProposal.quorumVotes = quorum;

        /// @notice immediately open proposal for voting
        newProposal.startBlock = block.number;
        newProposal.endBlock = ePropEndBlock;
        newProposal.forVotes = 0;
        newProposal.againstVotes = 0;
        newProposal.abstainVotes = 0;
        newProposal.executed = false;
        newProposal.vetoed = false;

        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            newProposal.eDAO,
            newProposal.eID,
            newProposal.startBlock,
            newProposal.endBlock,
            newProposal.quorumVotes
        );

        return newProposal.id;
    }

    /**
     * @notice Executes a proposal if it has met quorum
     * @param proposalId The id of the proposal to execute
     * @dev This function ensures that the proposal has reached quorum through a result check
     */
    function execute(uint256 proposalId) external {
        require(
            state(proposalId) == ProposalState.Active,
            "proposal can only be executed if it is active"
        );

        ProposalResult r = result(proposalId);
        require(
            r != ProposalResult.Undecided,
            "proposal result cannot be undecided"
        );

        DelegateAction storage proposal = proposals[proposalId];
        proposal.executed = true;

        require(
            block.number >= proposal.endBlock-execWindow,
            "proposal can only be executed if it is within the execution window"
        );

        // untrusted external calls, don't modify any state after this point
        // support values 0=against, 1=for, 2=abstain
        INounsDAOGovernance eDAO = INounsDAOGovernance(proposal.eDAO);
        if (r == ProposalResult.For) {
            eDAO.castVote(proposal.eID, 1);
        } else if (r == ProposalResult.Against) {
            eDAO.castVote(proposal.eID, 0);
        } else if (r == ProposalResult.Abstain) {
            eDAO.castVote(proposal.eID, 2);
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Vetoes a proposal only if sender is the vetoer and the proposal has not been executed.
     * @param proposalId The id of the proposal to veto
     */
    function veto(uint256 proposalId) external {
        require(vetoer != address(0), "veto power burned");
        
        require(msg.sender == vetoer, "caller not vetoer");
        
        require(
            state(proposalId) != ProposalState.Executed,
            "cannot veto executed proposal"
        );

        DelegateAction storage proposal = proposals[proposalId];
        proposal.vetoed = true;

        emit ProposalVetoed(proposalId);
    }    

    /**
     * @notice Cast a vote for a proposal with an optional reason
     * @param proposalId The id of the proposal to vote on
     * @param support The support value for the vote. 0=against, 1=for, 2=abstain
     */
    function castVote(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) external {
        require(
            state(proposalId) == ProposalState.Active,
            "voting is closed"
        );

        require(support <= 2, "invalid vote type");

        DelegateAction storage proposal = proposals[proposalId];

        uint96 votes = nounishToken.getPriorVotes(msg.sender, proposal.startBlock);
        require(votes > 0, "caller does not have votes");

        Receipt storage receipt = proposal.receipts[msg.sender];

        require(
            receipt.hasVoted == false,
            "already voted"
        );

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes + votes;
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes + votes;
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes + votes;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(
            msg.sender,
            proposalId,
            support,
            votes,
            reason
        );
    }

    /**
     * @notice Gets the receipt for a voter on a given proposal
     * @param proposalId the id of proposal
     * @param voter The address of the voter
     * @return The voting receipt
     */
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
     * @notice Gets the state of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal state
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId, "proposal not found");

        DelegateAction storage proposal = proposals[proposalId];

        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.number > proposal.endBlock) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Active;
        }
    }

    /**
     * @notice Gets the result of a proposal
     * @param proposalId The id of the proposal
     * @return Proposal result
     */
    function result(uint256 proposalId) public view returns (ProposalResult) {
        require(proposalCount >= proposalId, "invalid proposal id");

        DelegateAction storage proposal = proposals[proposalId];

        uint256 totalVotes = proposal.forVotes + proposal.againstVotes + proposal.abstainVotes ;
        if (totalVotes < proposal.quorumVotes) {
            return ProposalResult.Undecided;
        }

        if ((proposal.abstainVotes > proposal.forVotes) && (proposal.abstainVotes > proposal.againstVotes)) {
            return ProposalResult.Abstain;
        }

        if (proposal.againstVotes > proposal.forVotes) {
            return ProposalResult.Against;
        }

        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalResult.For;
        }

        return ProposalResult.Undecided;
    }

    /**
     * @notice Changes proposal exec window
     * @dev function for updating the exec window of a proposal
     */
    function _setExecWindow(uint newExecWindow) public {
        require(msg.sender == address(ownerDAO), "only owner can change exec window");

        emit NewExecWindow(execWindow, newExecWindow);

        execWindow = newExecWindow;
    }

    /**
     * @notice Burns veto priviledges
     * @dev Vetoer function destroying veto power forever
     */
    function _burnVetoPower() public {
        require(msg.sender == vetoer, "vetoer only");
        _setVetoer(address(0));
    }

    /**
     * @notice Changes vetoer address
     * @dev Vetoer function for updating vetoer address
     */
    function _setVetoer(address newVetoer) public {
        require(msg.sender == vetoer, "vetoer only");

        emit NewVetoer(vetoer, newVetoer);

        vetoer = newVetoer;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// NounsDAOEvents, NounsDAOProxyStorage, NounsDAOStorageV1 adds support for changes made by Nouns DAO to GovernorBravo.sol
// See NounsDAOLogicV1.sol for more details.

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
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );

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
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    /// @notice Emitted when proposal threshold basis points is set
    event ProposalThresholdBPSSet(
        uint256 oldProposalThresholdBPS,
        uint256 newProposalThresholdBPS
    );

    /// @notice Emitted when quorum votes basis points is set
    event QuorumVotesBPSSet(
        uint256 oldQuorumVotesBPS,
        uint256 newQuorumVotesBPS
    );

    /// @notice Emitted when pendingAdmin is changed
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /// @notice Emitted when pendingAdmin is accepted, which means admin is updated
    event NewAdmin(address oldAdmin, address newAdmin);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);
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
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint96);

    function totalSupply() external view returns (uint96);
}

// SPDX-License-Identifier: BSD-3-Clause

/// @title Federation

// Federation is an on-chain delegated voter which enables communities
// in the Nouns ecosystem to participate in governance with one another

// Built by wiz ⌐◨-◨ ☆ﾟ. * ･ ｡ﾟ

pragma solidity ^0.8.16;

import {NounsDAOStorageV1} from "./external/nouns/governance/NounsDAOInterfaces.sol";

/// @notice All possible states that a proposal may be in
enum ProposalState {
    Active,
    Expired,
    Executed,
    Vetoed
}

/// @notice All possible results for a proposal
enum ProposalResult {
    For,
    Against,
    Abstain,
    Undecided
}

/// @notice A delegate action is a proposal for how the Federation delegate should
/// vote on an external proposal.
struct DelegateAction {
    /// @notice Unique id for looking up a proposal
    uint256 id;
    /// @notice Creator of the proposal
    address proposer;
    /// @notice Implementation of external DAO proposal reference is for
    address eDAO;
    /// @notice Id of the external proposal reference in the external DAO
    uint256 eID;
    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed at the time of proposal creation. *DIFFERS from GovernerBravo
    uint256 quorumVotes;
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

contract DelegateEvents {
    event ProposalCreated(
        uint256 id,
        address proposer,
        address indexed eDAO,
        uint256 indexed ePropID,
        uint256 startBlock,
        uint256 endBlock,
        uint256 quorumVotes
    );

    /// @notice An event emitted when a vote has been cast on a proposal
    /// @param voter The address which casted a vote
    /// @param proposalId The proposal id which was voted on
    /// @param support Support value for the vote. 0=against, 1=for, 2=abstain
    /// @param votes Number of votes which were cast by the voter
    /// @param reason The reason given for the vote by the voter
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 votes,
        string reason
    );

    /// @notice An event emitted when a proposal has been executed in the NounsDAOExecutor
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been vetoed by vetoAddress
    event ProposalVetoed(uint256 id);

    /// @notice Emitted when vetoer is changed
    event NewVetoer(address oldVetoer, address newVetoer);

    /// @notice Emitted when exec window is changed
    event NewExecWindow(uint256 oldExecWindow, uint256 newExecWindow);
}

interface INounsDAOGovernance {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);

    function castVote(uint256 proposalId, uint8 support) external;

    function queue(uint256 proposalId) external;

    function execute(uint256 proposalId) external;

    function state(uint256 proposalId) external view returns (NounsDAOStorageV1.ProposalState);

    function quorumVotes() external view returns (uint256);
    
    function proposalThreshold() external view returns (uint256);
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