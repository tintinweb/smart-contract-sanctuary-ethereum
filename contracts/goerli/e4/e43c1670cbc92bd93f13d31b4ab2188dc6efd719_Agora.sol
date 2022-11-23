// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "openzeppelin-contracts/utils/Counters.sol";

import "./SlotEntry.sol";
import "../interfaces/IDaoCore.sol";

/**
 * @notice abstract contract used for Extension and DaoCore,
 * add a guard which accept only call from Adapters
 */
abstract contract Extension is SlotEntry {
    modifier onlyAdapter(bytes4 slot_) {
        require(
            IDaoCore(_core).getSlotContractAddr(slot_) == msg.sender,
            "Cores: not the right adapter"
        );
        _;
    }

    constructor(address core, bytes4 slot) SlotEntry(core, slot, true) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../helpers/Slot.sol";
import "../interfaces/ISlotEntry.sol";

/**
 * @notice abstract contract shared by Adapter, Extensions and
 * DaoCore, contains informations related to slots.
 *
 * @dev states of this contract are called to perform some checks,
 * especially when a new adapter or extensions is plugged to the
 * DAO
 */
abstract contract SlotEntry is ISlotEntry {
    address internal immutable _core;
    bytes4 public immutable override slotId;
    bool public immutable override isExtension;

    constructor(
        address core,
        bytes4 slot,
        bool isExt
    ) {
        require(core != address(0), "SlotEntry: zero address");
        require(slot != Slot.EMPTY, "SlotEntry: empty slot");
        _core = core;
        slotId = slot;
        isExtension = isExt;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../abstracts/Extension.sol";
import "../helpers/Constants.sol";
import "../interfaces/IAgora.sol";
import "../interfaces/IProposerAdapter.sol";
import "../helpers/Constants.sol";

/**
 * @notice contract which store votes parameters, vote result,
 * proposals and their status
 */

contract Agora is Extension, IAgora, Constants {
    using Slot for bytes28;

    struct Archive {
        uint32 archivedAt;
        address dataAddr;
    }

    mapping(bytes32 => Proposal) private _proposals;
    mapping(bytes4 => VoteParam) private _voteParams;
    mapping(bytes32 => mapping(address => bool)) private _votes;
    mapping(bytes32 => Archive) private _archives;

    constructor(address core) Extension(core, Slot.AGORA) {
        _addVoteParam(VOTE_STANDARD, Consensus.TOKEN, 7 days, 3 days, 8000, 7 days);
    }

    /* //////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////// */
    function submitVote(
        bytes32 proposalId,
        address voter,
        uint128 voteWeight,
        uint256 value
    ) external onlyAdapter(Slot.VOTING) {
        _submitVote(proposalId, voter, voteWeight, value);
    }

    function submitProposal(
        bytes4 slot,
        bytes28 adapterProposalId,
        bool adminApproved,
        bytes4 voteParamId,
        uint32 minStartTime,
        address initiater
    ) external onlyAdapter(slot) {
        bytes32 proposalId = adapterProposalId.concatWithSlot(slot);
        Proposal memory proposal_ = _proposals[proposalId];
        require(!proposal_.active, "Agora: proposal already exist");

        require(_voteParams[voteParamId].votingPeriod > 0, "Agora: unknown vote params");

        uint32 timestamp = uint32(block.timestamp);

        if (minStartTime == 0) minStartTime = timestamp;
        require(minStartTime >= timestamp, "Agora: wrong starting time");

        proposal_.active = true;
        proposal_.adminApproved = adminApproved;
        proposal_.createdAt = timestamp;
        proposal_.minStartTime = minStartTime;
        proposal_.initiater = initiater;
        proposal_.voteParamId = voteParamId;

        _proposals[proposalId] = proposal_;
        ++_voteParams[voteParamId].utilisation;

        emit ProposalSubmitted(slot, initiater, voteParamId, proposalId);
    }

    /**
     * @notice function used to flag that a proposal hase been
     * procedeed. Proposal are still in the storage of the contract.
     * @dev can be called by any adapter, allowing to implement restriction
     * on it if needed.
     *
     * TODO add logic to delete proposal once the corresponding the
     * maximal locking period is reached (< 1 year)
     */
    function finalizeProposal(
        bytes32 proposalId,
        address finalizer,
        VoteResult voteResult
    ) external onlyAdapter(bytes4(proposalId)) {
        _proposals[proposalId].proceeded = true;
        _archives[proposalId] = Archive(uint32(block.timestamp), msg.sender);
        emit ProposalFinalized(proposalId, finalizer, voteResult);
    }

    /**
     * @notice delete archive (if more than one year of existance)
     * in Agora and then datas in the Adapter
     *
     * NOTE This function could be called by another adapter, like
     * an adapter related to reputation and rewards, the second argument
     * is for a future utilisation of the rewarding users for maintaining
     * the DAO. BTW this function could be in another extensions
     */
    function deleteArchive(bytes32 proposalId, address) external onlyAdapter(Slot.VOTING) {
        Archive memory archive_ = _archives[proposalId];
        require(archive_.archivedAt > 0, "Agora: not an archive");
        require(block.timestamp >= archive_.archivedAt + 365 days, "Agora: not archivable");
        IProposerAdapter(archive_.dataAddr).deleteArchive(proposalId);
        delete _archives[proposalId];

        // reward user here
    }

    function changeVoteParams(
        bytes4 voteParamId,
        Consensus consensus,
        uint32 votingPeriod,
        uint32 gracePeriod,
        uint32 threshold,
        uint32 adminValidationPeriod
    ) external onlyAdapter(Slot.VOTING) {
        if (consensus == Consensus.NO_VOTE) {
            _removeVoteParam(voteParamId);
        } else {
            _addVoteParam(
                voteParamId,
                consensus,
                votingPeriod,
                gracePeriod,
                threshold,
                adminValidationPeriod
            );
        }
    }

    function validateProposal(bytes32 proposalId) external onlyAdapter(Slot.VOTING) {
        require(
            _evaluateProposalStatus(proposalId) == ProposalStatus.VALIDATION,
            "Agora: no validation required"
        );
        Proposal memory proposal_ = _proposals[proposalId];
        _proposals[proposalId].adminApproved = true;

        // postpone the `minStartTime` to now if passed
        uint256 timestamp = block.timestamp;
        if (proposal_.minStartTime < timestamp) {
            proposal_.minStartTime = uint32(timestamp);
        }
    }

    function suspendProposal(bytes32 proposalId) external onlyAdapter(Slot.VOTING) {
        ProposalStatus status = _evaluateProposalStatus(proposalId);
        require(
            status == ProposalStatus.STANDBY ||
                status == ProposalStatus.VALIDATION ||
                status == ProposalStatus.ONGOING ||
                status == ProposalStatus.CLOSED,
            "Agora: cannot suspend the proposal"
        );

        if (status == ProposalStatus.ONGOING) {
            _proposals[proposalId].suspendedAt = uint32(block.timestamp);
        } else if (status == ProposalStatus.CLOSED) {
            // flag when the proposal is suspended
            _proposals[proposalId].suspendedAt = 1;
        }
        _proposals[proposalId].suspended = true;
    }

    function unsuspendProposal(bytes32 proposalId) external onlyAdapter(Slot.VOTING) {
        Proposal memory proposal_ = _proposals[proposalId];
        require(proposal_.suspended, "Agora: proposal not suspended");
        uint256 timestamp = block.timestamp;

        proposal_.adminApproved = true;
        proposal_.suspended = false;
        if (proposal_.suspendedAt == 0) {
            // only if suspended in STANDBY or VALIDATION
            proposal_.minStartTime = uint32(timestamp);
        } else if (proposal_.suspendedAt > 1) {
            // postpone voting period if suspended in ONGOING
            proposal_.shiftedTime += uint32(timestamp - proposal_.suspendedAt);
        }

        _proposals[proposalId] = proposal_;
    }

    /* //////////////////////////
                GETTERS
    ////////////////////////// */
    function getProposalStatus(bytes32 proposalId) external view returns (ProposalStatus) {
        return _evaluateProposalStatus(proposalId);
    }

    function getVoteResult(bytes32 proposalId) external view returns (VoteResult) {
        return _calculVoteResult(proposalId);
    }

    function getProposal(bytes32 proposalId) external view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function getVoteParams(bytes4 voteParamId) external view returns (VoteParam memory) {
        return _voteParams[voteParamId];
    }

    function getVotes(bytes32 proposalId, address voter) external view returns (bool) {
        return _votes[proposalId][voter];
    }

    /* //////////////////////////
        INTERNAL FUNCTIONS
    ////////////////////////// */
    function _addVoteParam(
        bytes4 voteParamId,
        Consensus consensus,
        uint32 votingPeriod,
        uint32 gracePeriod,
        uint32 threshold,
        uint32 adminValidationPeriod
    ) internal {
        VoteParam memory voteParam_ = _voteParams[voteParamId];
        require(voteParam_.consensus == Consensus.NO_VOTE, "Agora: cannot replace params");

        require(votingPeriod > 0, "Agora: below min period");
        require(threshold <= 10000, "Agora: wrong threshold or below min value");

        voteParam_.consensus = consensus;
        voteParam_.votingPeriod = votingPeriod;
        voteParam_.gracePeriod = gracePeriod;
        voteParam_.threshold = threshold;
        voteParam_.adminValidationPeriod = adminValidationPeriod;

        _voteParams[voteParamId] = voteParam_;

        emit VoteParamsChanged(voteParamId, true);
    }

    function _removeVoteParam(bytes4 voteParamId) internal {
        uint256 utilisation = _voteParams[voteParamId].utilisation;
        require(utilisation == 0, "Agora: parameters still used");

        delete _voteParams[voteParamId];
        emit VoteParamsChanged(voteParamId, false);
    }

    function _submitVote(
        bytes32 proposalId,
        address voter,
        uint128 voteWeight,
        uint256 value
    ) internal {
        require(
            _evaluateProposalStatus(proposalId) == ProposalStatus.ONGOING,
            "Agora: outside voting period"
        );

        require(!_votes[proposalId][voter], "Agora: proposal voted");
        _votes[proposalId][voter] = true;

        Proposal memory proposal_ = _proposals[proposalId];

        if (_voteParams[proposal_.voteParamId].consensus == Consensus.MEMBER) {
            voteWeight = 1;
        }

        require(value <= 2, "Agora: neither (y), (n), (nota)");
        ++proposal_.score.memberVoted;
        if (value == 0) {
            proposal_.score.nbYes += voteWeight;
        } else if (value == 1) {
            proposal_.score.nbNo += voteWeight;
        } else {
            proposal_.score.nbNota += voteWeight;
        }

        _proposals[proposalId] = proposal_;
        emit MemberVoted(proposalId, voter, value, voteWeight);
    }

    function _calculVoteResult(bytes32 proposalId) internal view returns (VoteResult) {
        Proposal memory proposal_ = _proposals[proposalId];
        Score memory score_ = proposal_.score;
        // how to integrate NOTA vote, should it be?
        uint256 totalVote = score_.nbYes + score_.nbNo;

        if (
            totalVote != 0 &&
            (score_.nbYes * 10000) / totalVote >= _voteParams[proposal_.voteParamId].threshold
        ) {
            return VoteResult.ACCEPTED;
        } else {
            return VoteResult.REJECTED;
        }
    }

    function _evaluateProposalStatus(bytes32 proposalId) internal view returns (ProposalStatus) {
        Proposal memory proposal_ = _proposals[proposalId];
        VoteParam memory voteParam_ = _voteParams[proposal_.voteParamId];
        uint256 timestamp = block.timestamp;

        // proposal exist?
        if (!proposal_.active) {
            return ProposalStatus.UNKNOWN;
        }

        // is suspended?
        if (proposal_.suspended) {
            return ProposalStatus.SUSPENDED;
        }

        // is approved by admin?
        if (!proposal_.adminApproved) {
            uint256 endOfValidationPeriod = proposal_.createdAt + voteParam_.adminValidationPeriod;
            if (timestamp < endOfValidationPeriod) {
                return ProposalStatus.VALIDATION;
            } else {
                // virtualy postpone the `minStartTime`
                if (proposal_.minStartTime < endOfValidationPeriod) {
                    proposal_.minStartTime = uint32(endOfValidationPeriod);
                }
            }
        }

        // has started?
        if (timestamp < proposal_.minStartTime) {
            return ProposalStatus.STANDBY;
        }

        // is in voting period?
        if (timestamp < proposal_.minStartTime + proposal_.shiftedTime + voteParam_.votingPeriod) {
            return ProposalStatus.ONGOING;
        }

        // is in grace period?
        if (
            timestamp <
            proposal_.minStartTime +
                proposal_.shiftedTime +
                voteParam_.votingPeriod +
                voteParam_.gracePeriod
        ) {
            return ProposalStatus.CLOSED;
        }

        // is finalized
        if (!proposal_.proceeded) {
            return ProposalStatus.TO_FINALIZE;
        } else {
            return ProposalStatus.ARCHIVED;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev Constants used in the DAO
 */
contract Constants {
    // CREDIT
    bytes4 internal constant CREDIT_VOTE = bytes4(keccak256("credit-vote"));

    // VAULTS
    bytes4 internal constant TREASURY = bytes4(keccak256("treasury"));

    // VOTE PARAMS
    bytes4 internal constant VOTE_STANDARD = bytes4(keccak256("vote-standard"));

    /**
     * @dev Collection of roles available for DAO users
     */
    bytes4 internal constant ROLE_MEMBER = bytes4(keccak256("role-member"));
    bytes4 internal constant ROLE_PROPOSER = bytes4(keccak256("role-proposer"));
    bytes4 internal constant ROLE_ADMIN = bytes4(keccak256("role-admin"));
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @dev DAO Slot access collection
 */
library Slot {
    // GENERAL
    bytes4 internal constant EMPTY = 0x00000000;
    bytes4 internal constant CORE = 0xFFFFFFFF;

    // ADAPTERS
    bytes4 internal constant MANAGING = bytes4(keccak256("managing"));
    bytes4 internal constant ONBOARDING = bytes4(keccak256("onboarding"));
    bytes4 internal constant VOTING = bytes4(keccak256("voting"));
    bytes4 internal constant FINANCING = bytes4(keccak256("financing"));

    // EXTENSIONS
    bytes4 internal constant BANK = bytes4(keccak256("bank"));
    bytes4 internal constant AGORA = bytes4(keccak256("agora"));

    function concatWithSlot(bytes28 id, bytes4 slot) internal pure returns (bytes32) {
        return bytes32(bytes.concat(slot, id));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IAgora {
    event VoteParamsChanged(bytes4 indexed voteParamId, bool indexed added); // add consensus?

    event ProposalSubmitted(
        bytes4 indexed slot,
        address indexed from,
        bytes4 indexed voteParam,
        bytes32 proposalId
    );

    event ProposalFinalized(
        bytes32 indexed proposalId,
        address indexed finalizer,
        VoteResult indexed result
    );

    event MemberVoted(
        bytes32 indexed proposalId,
        address indexed voter,
        uint256 indexed value,
        uint256 voteWeight
    );
    enum ProposalStatus {
        UNKNOWN,
        VALIDATION,
        STANDBY,
        ONGOING,
        CLOSED,
        SUSPENDED,
        TO_FINALIZE,
        ARCHIVED // until last lock period
    }

    enum Consensus {
        NO_VOTE,
        TOKEN, // take vote weigth
        MEMBER // 1 address = 1 vote
    }

    enum VoteResult {
        ACCEPTED,
        REJECTED
    }

    struct Score {
        uint128 nbYes;
        uint128 nbNo;
        uint128 nbNota; // none of the above
        // see: https://blog.tally.xyz/understanding-governor-bravo-69b06f1875da
        uint128 memberVoted;
    }

    struct VoteParam {
        Consensus consensus;
        uint32 votingPeriod;
        uint32 gracePeriod;
        uint32 threshold; // 0 to 10000
        uint32 adminValidationPeriod;
        uint256 utilisation; // to fit
    }

    struct Proposal {
        bool active;
        bool adminApproved;
        bool suspended;
        bool proceeded; // ended or executed
        uint32 createdAt;
        uint32 minStartTime;
        uint32 shiftedTime;
        uint32 suspendedAt;
        bytes4 voteParamId;
        address initiater;
        Score score;
    }

    function submitProposal(
        bytes4 slot,
        bytes28 proposalId,
        bool adminValidation,
        bytes4 voteParamId,
        uint32 startTime,
        address initiater
    ) external;

    function changeVoteParams(
        bytes4 voteParamId,
        Consensus consensus,
        uint32 votingPeriod,
        uint32 gracePeriod,
        uint32 threshold,
        uint32 adminValidationPeriod
    ) external;

    function submitVote(
        bytes32 proposalId,
        address voter,
        uint128 voteWeight,
        uint256 value
    ) external;

    function finalizeProposal(
        bytes32 proposalId,
        address finalizer,
        VoteResult voteResult
    ) external;

    function deleteArchive(bytes32 proposalId, address user) external;

    // GETTERS
    function getProposalStatus(bytes32 proposalId) external view returns (ProposalStatus);

    function getVoteResult(bytes32 proposalId) external view returns (VoteResult);

    function getProposal(bytes32 proposalId) external view returns (Proposal memory);

    function getVoteParams(bytes4 voteParamId) external view returns (VoteParam memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IDaoCore {
    event SlotEntryChanged(
        bytes4 indexed slot,
        bool indexed isExtension,
        address oldContractAddr,
        address newContractAddr
    );

    event MemberStatusChanged(
        address indexed member,
        bytes4 indexed roles,
        bool indexed actualValue
    );

    struct Entry {
        bytes4 slot;
        bool isExtension;
        address contractAddr;
    }

    function changeSlotEntry(bytes4 slot, address contractAddr) external;

    function addNewAdmin(address account) external;

    function changeMemberStatus(
        address account,
        bytes4 role,
        bool value
    ) external;

    function membersCount() external returns (uint256);

    function hasRole(address account, bytes4 role) external returns (bool);

    function getRolesList() external returns (bytes4[] memory);

    function isSlotActive(bytes4 slot) external view returns (bool);

    function isSlotExtension(bytes4 slot) external view returns (bool);

    function getSlotContractAddr(bytes4 slot) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProposerAdapter {
    function finalizeProposal(bytes32 proposalId) external;

    function deleteArchive(bytes32 proposalId) external;

    function pauseToggleAdapter() external;

    function desactive() external;

    function ongoingProposals() external view returns (uint256);

    function archivedProposals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ISlotEntry {
    function isExtension() external view returns (bool);

    function slotId() external view returns (bytes4);
}