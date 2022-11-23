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
import "../interfaces/IAdapter.sol";
import "../interfaces/IDaoCore.sol";
import "../helpers/Constants.sol";

/**
 * @notice abstract contract for Adapters, add guard modifier
 * to restrict access for only DAO members or contracts
 */
abstract contract Adapter is SlotEntry, IAdapter, Constants {
    constructor(address core, bytes4 slot) SlotEntry(core, slot, false) {}

    /* //////////////////////////
            MODIFIER
    ////////////////////////// */
    modifier onlyCore() {
        require(msg.sender == _core, "Adapter: not the core");
        _;
    }

    modifier onlyExtension(bytes4 slot) {
        IDaoCore core = IDaoCore(_core);
        require(
            core.isSlotExtension(slot) && core.getSlotContractAddr(slot) == msg.sender,
            "Adapter: wrong extension"
        );
        _;
    }

    /// NOTE consider using `hasRole(bytes4)` for future role in the DAO => AccessControl.sol
    modifier onlyMember() {
        require(IDaoCore(_core).hasRole(msg.sender, ROLE_MEMBER), "Adapter: not a member");
        _;
    }

    modifier onlyProposer() {
        require(IDaoCore(_core).hasRole(msg.sender, ROLE_PROPOSER), "Adapter: not a proposer");
        _;
    }

    modifier onlyAdmin() {
        require(IDaoCore(_core).hasRole(msg.sender, ROLE_ADMIN), "Adapter: not an admin");
        _;
    }

    /* //////////////////////////
            FUNCTIONS
    ////////////////////////// */
    /**
     * @notice delete storage and destruct the contract,
     * calls can still happen and ethers sended there are lost
     * for ever.
     *
     * @dev only callable when the contract is unplugged from DaoCore
     *
     * NOTE this operation is quite useless as the contract as not state
     */
    function eraseAdapter() public virtual override onlyExtension(Slot.AGORA) {
        require(
            IDaoCore(_core).getSlotContractAddr(slotId) != address(this),
            "Adapter: unplug from DaoCore"
        );
        selfdestruct(payable(_core));
    }

    /**
     * @notice internal getter
     * @return actual contract address associated with `slot`, return
     * address(0) if there is no contract address
     */
    function _slotAddress(bytes4 slot) internal view returns (address) {
        return IDaoCore(_core).getSlotContractAddr(slot);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../helpers/ProposalState.sol";
import "../interfaces/IProposerAdapter.sol";
import "../interfaces/IAgora.sol";
import "./Adapter.sol";

/**
 * @notice Extensions of abstract contract Adapters which implement
 * a proposal submission to Agora.
 *
 * @dev Allow contract to manage proposals counters, check vote result and
 * risk mitigation
 */
abstract contract ProposerAdapter is Adapter, IProposerAdapter {
    using ProposalState for ProposalState.State;

    ProposalState.State private _state;

    modifier paused() {
        require(!_state.paused(), "Adapter: paused");
        _;
    }

    /**
     * @notice called to finalize and archive a proposal
     * {_executeProposal} if accepted, this latter
     * function must be overrided in adapter implementation
     * with the logic of the adapter
     *
     * NOTE This function shouldn't be overrided (virtual), but maybe
     * it would be an option
     */
    function finalizeProposal(bytes32 proposalId) external onlyMember {
        (IAgora.VoteResult result, IAgora agora) = _checkProposalResult(proposalId);

        if (result == IAgora.VoteResult.ACCEPTED) {
            _executeProposal(proposalId);
        }

        _archiveProposal();
        agora.finalizeProposal(proposalId, msg.sender, result);
    }

    /**
     * @notice delete the archive after one year, Agora
     * store and do check before calling this function
     */
    function deleteArchive(bytes32) external virtual onlyExtension(Slot.AGORA) {
        // implement logic here
        _state.decrementArchive();
    }

    /**
     * @notice allow an admin to pause and unpause the adapter
     * @dev inverse the current pause state
     */
    function pauseToggleAdapter() external onlyAdmin {
        _state.pauseToggle();
    }

    /**
     * @notice desactivate the adapter
     * @dev CAUTION this function is not reversible,
     * only triggerable when there is no ongoing proposal
     */
    function desactive() external onlyAdmin {
        require(_state.currentOngoing() == 0, "Proposer: still ongoing proposals");
        _state.desactivate();
    }

    /**
     * @notice extend the {Adapter} method to check if
     * there is current archive in the contract
     *
     * NOTE should be called automatically when last archive is deleted
     */
    function eraseAdapter() public override {
        require(_state.desactived() && _state.currentArchive() == 0, "Proposer: cannot erase");
        super.eraseAdapter(); // is onlyExt check work?
    }

    /**
     * @notice getter for current numbers of ongoing proposal
     */
    function ongoingProposals() external view returns (uint256) {
        return _state.currentOngoing();
    }

    /**
     * @notice getter for current numbers of archived proposal
     */
    function archivedProposals() external view returns (uint256) {
        return _state.currentArchive();
    }

    function isPaused() external view returns (bool) {
        return _state.paused();
    }

    function isDesactived() external view returns (bool) {
        return _state.desactived();
    }

    /* //////////////////////////
        INTERNAL FUNCTIONS
    ////////////////////////// */
    /**
     * @notice decrement ongoing proposal and increment
     * archived proposal counter
     *
     * NOTE should be used when {Adapter::finalizeProposal}
     */
    function _archiveProposal() internal paused {
        _state.decrementOngoing();
        _state.incrementArchive();
    }

    /**
     * @notice called after a proposal is submitted to Agora.
     * @dev will increase the proposal counter, check if the
     * adapter has not been paused and check also if the
     * adapter has not been desactived
     */
    function _newProposal() internal paused {
        require(!_state.desactived(), "Proposer: adapter desactived");
        _state.incrementOngoing();
    }

    /**
     * @notice allow the proposal to check the vote result on
     * Agora, this function is only used (so far) when the adapter
     * needs to finalize a proposal
     *
     * @dev the function returns the {VoteResult} enum and the
     * {IAgora} interface to facilitate the result transmission to Agora
     *
     * NOTE This function could be transformed into a modifier which act
     * before and after the function {Adapter::finalizeProposal} as this
     * latter must call {Agora::finalizeProposal} then.
     */
    function _checkProposalResult(bytes32 proposalId)
        internal
        view
        returns (IAgora.VoteResult accepted, IAgora agora)
    {
        agora = IAgora(_slotAddress(Slot.AGORA));
        require(
            agora.getProposalStatus(proposalId) == IAgora.ProposalStatus.TO_FINALIZE,
            "Agora: proposal cannot be finalized"
        );

        accepted = agora.getVoteResult(proposalId);
    }

    /**
     * @notice this function is used as a hook to execute the
     * adapter logic when a proposal has been accepted.
     * @dev triggered by {finalizeProposal}
     */
    function _executeProposal(bytes32 proposalId) internal virtual {}

    function _readProposalId(bytes32 proposalId) internal pure returns (bytes28) {
        return bytes28(proposalId << 32);
    }
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

import "../abstracts/ProposerAdapter.sol";
import "../interfaces/IBank.sol";
import "../interfaces/IAgora.sol";

contract Voting is ProposerAdapter {
    enum ProposalType {
        CONSULTATION,
        VOTE_PARAMS
    }

    struct Consultation {
        string title;
        string description;
        address initiater;
    }

    struct ProposedVoteParam {
        bytes4 voteParamId;
        IAgora.Consensus consensus;
        uint32 votingPeriod;
        uint32 gracePeriod;
        uint32 threshold;
        uint32 adminValidationPeriod;
    }

    struct VotingProposal {
        ProposalType proposalType;
        Consultation consultation;
        ProposedVoteParam voteParam;
    }

    mapping(bytes28 => VotingProposal) private _votingProposals;

    constructor(address core) Adapter(core, Slot.VOTING) {}

    /* //////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////// */
    function submitVote(
        bytes32 proposalId,
        uint256 value,
        uint96 deposit,
        uint32 lockPeriod,
        uint96 advancedDeposit
    ) external onlyMember {
        // get vote Weight
        uint96 voteWeight = IBank(_slotAddress(Slot.BANK)).newCommitment(
            msg.sender,
            proposalId,
            deposit,
            lockPeriod,
            advancedDeposit
        );

        // submit vote
        IAgora(_slotAddress(Slot.AGORA)).submitVote(
            proposalId,
            msg.sender,
            uint128(voteWeight),
            value
        );
    }

    function proposeNewVoteParams(
        string calldata name,
        IAgora.Consensus consensus,
        uint32 votingPeriod,
        uint32 gracePeriod,
        uint32 threshold,
        uint32 minStartTime,
        uint32 adminValidationPeriod
    ) external onlyMember {
        bytes4 voteParamId = bytes4(keccak256(bytes(name)));
        IAgora agora = IAgora(_slotAddress(Slot.AGORA));
        require(
            agora.getVoteParams(voteParamId).votingPeriod == 0,
            "Voting: cannot replace vote params"
        );

        // proposal construction
        ProposedVoteParam memory voteParam_ = ProposedVoteParam(
            voteParamId,
            consensus,
            votingPeriod,
            gracePeriod,
            threshold,
            adminValidationPeriod
        );
        Consultation memory emptyConsultation;
        VotingProposal memory proposal_ = VotingProposal(
            ProposalType.VOTE_PARAMS,
            emptyConsultation,
            voteParam_
        );
        bytes28 proposalId = bytes28(keccak256(abi.encode(proposal_)));

        _newProposal();
        _votingProposals[proposalId] = proposal_;

        agora.submitProposal(slotId, proposalId, false, VOTE_STANDARD, minStartTime, msg.sender);
    }

    function proposeConsultation(
        string calldata title,
        string calldata description,
        uint32 minStartTime
    ) external onlyMember {
        Consultation memory consultation_ = Consultation(title, description, msg.sender);
        ProposedVoteParam memory emptyVoteParam;

        VotingProposal memory proposal_ = VotingProposal(
            ProposalType.CONSULTATION,
            consultation_,
            emptyVoteParam
        );
        bytes28 proposalId = bytes28(keccak256(abi.encode(proposal_)));

        _newProposal();
        _votingProposals[proposalId] = proposal_;

        IAgora(_slotAddress(Slot.AGORA)).submitProposal(
            slotId,
            proposalId,
            true,
            VOTE_STANDARD,
            minStartTime,
            msg.sender
        );
    }

    function withdrawAmount(uint128 amount) external onlyMember {
        IBank(_slotAddress(Slot.BANK)).withdrawAmount(msg.sender, amount);
    }

    function advanceDeposit(uint128 amount) external onlyMember {
        IBank(_slotAddress(Slot.BANK)).advancedDeposit(msg.sender, amount);
    }

    function requestDeleteArchive(bytes32 proposalId) external onlyMember {
        IAgora(_slotAddress(Slot.AGORA)).deleteArchive(proposalId, msg.sender);
    }

    function addNewVoteParams(
        string memory name,
        IAgora.Consensus consensus,
        uint32 votingPeriod,
        uint32 gracePeriod,
        uint32 threshold,
        uint32 adminValidationPeriod
    ) external onlyAdmin {
        bytes4 voteParamId = bytes4(keccak256(bytes(name)));

        IAgora(_slotAddress(Slot.AGORA)).changeVoteParams(
            voteParamId,
            consensus,
            votingPeriod,
            gracePeriod,
            threshold,
            adminValidationPeriod
        );
    }

    function removeVoteParams(bytes4 voteParamId) external onlyAdmin {
        IAgora(_slotAddress(Slot.AGORA)).changeVoteParams(
            voteParamId,
            IAgora.Consensus.NO_VOTE,
            0,
            0,
            0,
            0
        );
    }

    function validateProposal(bytes32 proposalId) external onlyAdmin {
        //
    }

    /* //////////////////////////
                GETTERS
    ////////////////////////// */

    function getConsultation(bytes28 proposalId)
        external
        view
        returns (Consultation memory consultation)
    {
        consultation = _votingProposals[proposalId].consultation;
        require(consultation.initiater != address(0), "Voting: no consultation");
    }

    function getProposedVoteParam(bytes28 proposalId)
        external
        view
        returns (ProposedVoteParam memory _voteParam)
    {
        _voteParam = _votingProposals[proposalId].voteParam;
        require(_voteParam.voteParamId != Slot.EMPTY, "Voting: no vote params");
    }

    /* //////////////////////////
        INTERNAL FUNCTIONS
    ////////////////////////// */
    function _changeVoteParam(VotingProposal memory votingProposal) internal {
        ProposedVoteParam memory _proposedVoteParam = votingProposal.voteParam;
        IAgora(_slotAddress(Slot.AGORA)).changeVoteParams(
            _proposedVoteParam.voteParamId,
            _proposedVoteParam.consensus,
            _proposedVoteParam.votingPeriod,
            _proposedVoteParam.gracePeriod,
            _proposedVoteParam.threshold,
            _proposedVoteParam.adminValidationPeriod
        );
    }

    function _executeProposal(bytes32 proposalId) internal override {
        VotingProposal memory votingProposal = _votingProposals[_readProposalId(proposalId)];
        if (ProposalType.VOTE_PARAMS == votingProposal.proposalType) {
            _changeVoteParam(votingProposal);
        }
        // TODO error should be handled here and other type of action function of type

        // => do nothing if consultation is accepted or add flag in struct Consultation
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
 * @notice Library which mix up Counters.sol and Pausable.sol from
 * OpenZeppelin.
 *
 * @dev it define and provide utils to manage the state of an adapter
 */

library ProposalState {
    error DecrementOverflow();

    /**
     * @notice overflow is not checked, as the maximum number is
     * 4_294_967_295, only underflow is checked
     */
    struct State {
        bool isPaused;
        bool isDesactived;
        uint32 ongoingProposal;
        uint32 archivedProposal;
    }

    /* //////////////////////////
                FLAGS
    ////////////////////////// */
    function desactived(State storage state) internal view returns (bool) {
        return state.isDesactived;
    }

    function paused(State storage state) internal view returns (bool) {
        return state.isPaused;
    }

    function pauseToggle(State storage state) internal {
        state.isPaused = state.isPaused ? false : true;
    }

    function desactivate(State storage state) internal {
        state.isDesactived = true;
    }

    /* //////////////////////////
            COUNTERS
    ////////////////////////// */

    function currentOngoing(State storage state) internal view returns (uint256) {
        return state.ongoingProposal;
    }

    function currentArchive(State storage state) internal view returns (uint256) {
        return state.archivedProposal;
    }

    function incrementOngoing(State storage state) internal {
        unchecked {
            ++state.ongoingProposal;
        }
    }

    function decrementOngoing(State storage state) internal {
        uint256 value = state.ongoingProposal;
        if (value == 0) revert DecrementOverflow();
        unchecked {
            --state.ongoingProposal;
        }
    }

    function incrementArchive(State storage state) internal {
        unchecked {
            ++state.archivedProposal;
        }
    }

    function decrementArchive(State storage state) internal {
        uint256 value = state.archivedProposal;
        if (value == 0) revert DecrementOverflow();
        unchecked {
            --state.archivedProposal;
        }
    }
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

interface IAdapter {
    function eraseAdapter() external;
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

interface IBank {
    event NewCommitment(
        bytes32 indexed proposalId,
        address indexed account,
        uint256 indexed lockPeriod,
        uint256 lockedAmount
    );
    event Deposit(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);

    event VaultCreated(bytes4 indexed vaultId);

    event VaultTransfer(
        bytes4 indexed vaultId,
        address indexed tokenAddr,
        address from,
        address to,
        uint128 amount
    );

    event VaultAmountCommitted(
        bytes4 indexed vaultId,
        address indexed tokenAddr,
        address indexed destinationAddr,
        uint128 amount
    );

    struct Account {
        uint128 availableBalance;
        uint96 lockedBalance; // until 100_000 proposals
        uint32 nextRetrieval;
    }

    /**
     * @notice Max amount locked per proposal is 50_000
     * With a x50 multiplier the voteWeight is at 2.5**24
     * Which is less than 2**96 (uint96)
     * lockPeriod and retrievalDate can be stored in uint32
     * the retrieval date would overflow if it is set to 82 years
     */
    struct Commitment {
        uint96 lockedAmount;
        uint96 voteWeight;
        uint32 lockPeriod;
        uint32 retrievalDate;
    }

    struct Balance {
        uint128 availableBalance;
        uint128 commitedBalance;
    }

    function newCommitment(
        address user,
        bytes32 proposalId,
        uint96 lockedAmount,
        uint32 lockPeriod,
        uint96 advanceDeposit
    ) external returns (uint96 voteWeight);

    function advancedDeposit(address user, uint128 amount) external;

    function withdrawAmount(address user, uint128 amount) external;

    function vaultCommit(
        bytes4 vaultId,
        address tokenAddr,
        address destinationAddr,
        uint128 amount
    ) external;

    function vaultDeposit(
        bytes4 vaultId,
        address tokenAddr,
        address tokenOwner,
        uint128 amount
    ) external;

    function vaultTransfer(
        bytes4 vaultId,
        address tokenAddr,
        address destinationAddr,
        uint128 amount
    ) external returns (bool);

    function createVault(bytes4 vaultId, address[] memory tokenList) external;

    function terraBioToken() external returns (address);
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