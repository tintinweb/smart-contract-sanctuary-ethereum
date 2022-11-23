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
import "../interfaces/IAgora.sol";
import "../interfaces/IDaoCore.sol";

/**
 * @notice contract interacting with the Core to add or remove Entry
 * to the DAO.
 * CAUTION: this contract must always have the possibility to add and remove Slots
 * in the DAO, otherwise the DAO can be blocked
 */

contract Managing is ProposerAdapter {
    struct EntryProposal {
        bytes4 slot;
        bool isExtension;
        address contractAddr;
    }

    mapping(bytes28 => EntryProposal) private _proposals;

    constructor(address core) Adapter(core, Slot.MANAGING) {}

    /* //////////////////////////
            PUBLIC FUNCTIONS
    ////////////////////////// */
    /**
     * @notice allow member to propose a new entry to the DAO
     * Propositions need an approval from the admin
     */
    function proposeEntry(
        bytes4 entrySlot,
        bool isExt,
        address contractAddr,
        bytes4 voteParamId,
        uint32 minStartTime
    ) external onlyMember {
        // checking the proposed contract is done in Agora

        // construct the proposal
        EntryProposal memory entryProposal_ = EntryProposal(entrySlot, isExt, contractAddr);
        bytes28 proposalId = bytes28(keccak256(abi.encode(entryProposal_)));

        // store proposal data and check adapter state
        _newProposal();
        _proposals[proposalId] = entryProposal_;

        // send to Agora
        IAgora(_slotAddress(Slot.AGORA)).submitProposal(
            entrySlot,
            proposalId,
            false,
            voteParamId,
            minStartTime,
            msg.sender
        );
    }

    /**
     * @notice change a slot entry without vote, useful for
     * quick add of Slot
     *
     * NOTE consider disable this function when the DAO reach a certain
     * size to let only member decide as admin can abuse of it. But can
     * be useful in ermergency situation
     *
     * NOTE a commitment logic can be implemented to let another admin check
     * the new contract
     */
    function manageSlotEntry(bytes4 entrySlot, address contractAddr) external onlyAdmin {
        IDaoCore(_core).changeSlotEntry(entrySlot, contractAddr);
    }

    /* //////////////////////////
        INTERNAL FUNCTIONS
    ////////////////////////// */
    function _executeProposal(bytes32 proposalId) internal override {
        EntryProposal memory entryProposal_ = _proposals[_readProposalId(proposalId)];
        IDaoCore(_core).changeSlotEntry(entryProposal_.slot, entryProposal_.contractAddr);
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