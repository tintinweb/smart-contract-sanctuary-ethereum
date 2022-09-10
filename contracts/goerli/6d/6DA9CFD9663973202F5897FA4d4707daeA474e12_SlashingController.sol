// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-protocol/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.15;

import "./FortaStakingParameters.sol";
import "../utils/StateMachines.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SlashingController is BaseComponentUpgradeable, StateMachineController, SubjectTypeValidator {
    using Counters for Counters.Counter;
    using StateMachines for StateMachines.Machine;

    StateMachines.State public constant UNDEFINED = StateMachines.State._00;
    StateMachines.State public constant CREATED = StateMachines.State._01;
    StateMachines.State public constant REJECTED = StateMachines.State._02;
    StateMachines.State public constant DISMISSED = StateMachines.State._03;
    StateMachines.State public constant IN_REVIEW = StateMachines.State._04;
    StateMachines.State public constant REVIEWED = StateMachines.State._05;
    StateMachines.State public constant EXECUTED = StateMachines.State._06;
    StateMachines.State public constant REVERTED = StateMachines.State._07;

    enum PenaltyMode {
        UNDEFINED,
        MIN_STAKE,
        CURRENT_STAKE
    }

    struct SlashPenalty {
        uint256 percentSlashed;
        PenaltyMode mode;
    }

    struct Deposit {
        address proposer;
        uint256 amount;
    }

    struct Proposal {
        uint256 subjectId;
        address proposer;
        bytes32 penaltyId;
        uint8 subjectType;
    }

    Counters.Counter private _proposalIds;
    mapping(uint256 => Proposal) public proposals; // proposalId --> Proposal
    mapping(uint256 => uint256) public deposits; // proposalId --> tokenAmount
    mapping(bytes32 => SlashPenalty) public penalties; // penaltyId --> SlashPenalty
    ISlashingExecutor public slashingExecutor;
    FortaStakingParameters public stakingParameters;
    uint256 public depositAmount;
    uint256 public slashPercentToProposer;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IERC20 public immutable depositToken;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    StateMachines.Machine private immutable _transitionTable;

    //solhint-disable-next-line const-name-snakecase
    string public constant version = "0.1.0";
    uint256 public constant MAX_EVIDENCE_LENGTH = 5;
    uint256 public constant MAX_CHAR_LENGTH = 200;
    uint256 private constant HUNDRED_PERCENT = 100;

    event SlashProposalUpdated(
        address indexed updater,
        uint256 indexed proposalId,
        StateMachines.State indexed stateId,
        address proposer,
        uint256 subjectId,
        uint8 subjectType,
        bytes32 penaltyId
    );
    event EvidenceSubmitted(uint256 proposalId, StateMachines.State stateId, string[] evidence);
    event SlashingExecutorChanged(address indexed slashingExecutor);
    event StakingParametersManagerChanged(address indexed stakingParametersManager);
    event DepositAmountChanged(uint256 amount);
    event SlashPercentToProposerChanged(uint256 amount);
    event DepositSubmitted(uint256 indexed proposalId, address indexed proposer, uint256 amount);
    event DepositReturned(uint256 indexed proposalId, address indexed proposer, uint256 amount);
    event DepositSlashed(uint256 indexed proposalId, address indexed proposer, uint256 amount);
    event SlashPenaltyAdded(bytes32 indexed penaltyId, uint256 percentSlashed, PenaltyMode mode);
    event SlashPenaltyRemoved(bytes32 indexed penaltyId, uint256 percentSlashed, PenaltyMode mode);

    error WrongSlashPenaltyId(bytes32 penaltyId);
    error NonRegisteredSubject(uint8 subjectType, uint256 subjectId);
    error WrongPercentValue(uint256 value);

    modifier onlyValidSlashPenaltyId(bytes32 penaltyId) {
        if (penalties[penaltyId].mode == PenaltyMode.UNDEFINED) revert WrongSlashPenaltyId(penaltyId);
        _;
    }

    modifier onlyValidPercent(uint256 percent) {
        if (percent > HUNDRED_PERCENT) revert WrongPercentValue(percent);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _forwarder, address _depositToken) initializer ForwardedContext(_forwarder) {
        if (_depositToken == address(0)) revert ZeroAddress("_depositToken");
        depositToken = IERC20(_depositToken);
        _transitionTable = StateMachines
            .EMPTY_MACHINE
            .addEdgeTransition(UNDEFINED, CREATED)
            .addEdgeTransition(CREATED, DISMISSED)
            .addEdgeTransition(CREATED, REJECTED)
            .addEdgeTransition(CREATED, IN_REVIEW)
            .addEdgeTransition(IN_REVIEW, REVIEWED)
            .addEdgeTransition(IN_REVIEW, REVERTED)
            .addEdgeTransition(REVIEWED, EXECUTED)
            .addEdgeTransition(REVIEWED, REVERTED);
    }

    /**
     * @notice Initializer method, access point to initialize inheritance tree.
     * @param __manager address of AccessManager.
     * @param __router address of Router.
     */
    function initialize(
        address __manager,
        address __router,
        ISlashingExecutor __executor,
        FortaStakingParameters __stakingParameters,
        uint256 __depositAmount,
        uint256 __slashPercentToProposer,
        bytes32[] calldata __slashPenaltyIds,
        SlashPenalty[] calldata __slashPenalties
    ) public initializer {
        __AccessManaged_init(__manager);
        __Routed_init(__router);
        __UUPSUpgradeable_init();

        _setSlashingExecutor(__executor);
        _setStakingParametersManager(__stakingParameters);
        _setDepositAmount(__depositAmount);
        _setSlashPercentToProposer(__slashPercentToProposer);
        _setSlashPenalties(__slashPenaltyIds, __slashPenalties);
    }

    // Proposal LifeCycle
    /**
     * @notice Creates a slash proposal pointing to a slashable subject. To do so, the proposer must provide a FORT deposit and present evidence.
     * @param _subjectType type of the subject.
     * @param _subjectId ERC721 registry id of the stake subject.
     * @param _penaltyId if of the SlashPenalty to inflict upon the subject if the proposal goes through.
     * @param _evidence IPFS hashes of the evidence files, proof of the subject being slash worthy.
     * @return proposalId the proposal identifier.
     */
    function proposeSlash(
        uint8 _subjectType,
        uint256 _subjectId,
        bytes32 _penaltyId,
        string[] calldata _evidence
    ) external onlyValidSlashPenaltyId(_penaltyId) onlyValidSubjectType(_subjectType) returns (uint256 proposalId) {
        if (!stakingParameters.isRegistered(_subjectType, _subjectId)) revert NonRegisteredSubject(_subjectType, _subjectId);
        if (stakingParameters.totalStakeFor(_subjectType, _subjectId) == 0) revert ZeroAmount("subject stake");
        Proposal memory slashProposal = Proposal(_subjectId, _msgSender(), _penaltyId, _subjectType);
        SafeERC20.safeTransferFrom(depositToken, _msgSender(), address(this), depositAmount);
        _proposalIds.increment();
        proposalId = _proposalIds.current();
        deposits[proposalId] = depositAmount;
        proposals[proposalId] = slashProposal;
        emit DepositSubmitted(proposalId, _msgSender(), depositAmount);
        _transition(proposalId, CREATED);
        emit SlashProposalUpdated(_msgSender(), proposalId, CREATED, slashProposal.proposer, slashProposal.subjectId, slashProposal.subjectType, slashProposal.penaltyId);
        _submitEvidence(proposalId, CREATED, _evidence);
        slashingExecutor.freeze(_subjectType, _subjectId, true);
        return proposalId;
    }

    /**
     * @notice Arbiter dismisses a slash proposal (the proposal is legitimate, but after investigation, it is not a slashable offense)
     * The deposit is returned to the proposer, and the stake of the subject is unfrozen
     * @param _proposalId the proposal identifier.
     * @param _evidence IPFS hashes of the evidence files, proof of the subject not being slashable.
     */
    function dismissSlashProposal(uint256 _proposalId, string[] calldata _evidence) external onlyRole(SLASHING_ARBITER_ROLE) {
        _transition(_proposalId, DISMISSED);
        _submitEvidence(_proposalId, DISMISSED, _evidence);
        _returnDeposit(_proposalId);
        slashingExecutor.freeze(proposals[_proposalId].subjectType, proposals[_proposalId].subjectId, false);
    }

    /**
     * @notice Arbiter rejects a slash proposal, slashing the deposit of the proposer (the proposal is deemed as spam, malicious, or similar)
     * and unfreezing the subject's stake.
     * @param _proposalId the proposal identifier.
     * @param _evidence IPFS hashes of the evidence files, justification for slashing the proposer's deposit.
     */
    function rejectSlashProposal(uint256 _proposalId, string[] calldata _evidence) external onlyRole(SLASHING_ARBITER_ROLE) {
        _transition(_proposalId, REJECTED);
        _submitEvidence(_proposalId, REJECTED, _evidence);
        _slashDeposit(_proposalId);
        slashingExecutor.freeze(proposals[_proposalId].subjectType, proposals[_proposalId].subjectId, false);
    }

    /**
     * @notice Arbiter recognizes the report as valid and procceeds to investigate. The deposit is returned to proposer, stake remains frozen.
     * @param _proposalId the proposal identifier.
     */
    function markAsInReviewSlashProposal(uint256 _proposalId) external onlyRole(SLASHING_ARBITER_ROLE) {
        _transition(_proposalId, IN_REVIEW);
        if (deposits[_proposalId] == 0) revert ZeroAmount("deposit on _proposalId");
        _returnDeposit(_proposalId);
    }

    /**
     * @notice After investigation, arbiter updates the proposal's incorrect assumptions. This can only be done if the proposal is IN_REVIEW, and
     * presenting evidence for the changes.
     * Changing the subject and subjectType will unfreeze the previous target and freeze the new.
     * Changing the penalty will affect slashing amounts.
     * @param _proposalId the proposal identifier.
     * @param _subjectType type of the subject.
     * @param _subjectId ERC721 registry id of the stake subject.
     * @param _penaltyId if of the SlashPenalty to inflict upon the subject if the proposal goes through.
     * @param _evidence IPFS hashes of the evidence files, proof of need for proposal changes.
     */
    function reviewSlashProposalParameters(
        uint256 _proposalId,
        uint8 _subjectType,
        uint256 _subjectId,
        bytes32 _penaltyId,
        string[] calldata _evidence
    ) external onlyRole(SLASHING_ARBITER_ROLE) onlyInState(_proposalId, IN_REVIEW) onlyValidSlashPenaltyId(_penaltyId) onlyValidSubjectType(_subjectType) {
        // No need to check for proposal existence, onlyInState will revert if _proposalId is in undefined state
        if (!stakingParameters.isRegistered(_subjectType, _subjectId)) revert NonRegisteredSubject(_subjectType, _subjectId);

        _submitEvidence(_proposalId, IN_REVIEW, _evidence);
        if (_subjectType != proposals[_proposalId].subjectType || _subjectId != proposals[_proposalId].subjectId) {
            slashingExecutor.freeze(proposals[_proposalId].subjectType, proposals[_proposalId].subjectId, false);
            slashingExecutor.freeze(_subjectType, _subjectId, true);
        }
        Proposal memory slashProposal = Proposal(_subjectId, proposals[_proposalId].proposer, _penaltyId, _subjectType);
        proposals[_proposalId] = slashProposal;
        emit SlashProposalUpdated(_msgSender(), _proposalId, IN_REVIEW, slashProposal.proposer, slashProposal.subjectId, slashProposal.subjectType, slashProposal.penaltyId);
    }

    /**
     * @notice Arbiter marks the proposal as reviewed, so the slasher can execute or revert.
     * @param _proposalId the proposal identifier.
     */
    function markAsReviewedSlashProposal(uint256 _proposalId) external onlyRole(SLASHING_ARBITER_ROLE) {
        _transition(_proposalId, REVIEWED);
    }

    /**
     * @notice The slashing proposal should not be executed. Stake is unfrozen.
     * If the proposal is IN_REVIEW, this can be executed by the SLASHING_ARBITER_ROLE.
     * If the proposal is REVIEWED, this can be executed by the SLASHER_ROLE.
     * @param _proposalId the proposal identifier.
     * @param _evidence IPFS hashes of the evidence files, proof of the slash being not valid.
     */
    function revertSlashProposal(uint256 _proposalId, string[] calldata _evidence) external {
        _authorizeRevertSlashProposal(_proposalId);
        _transition(_proposalId, REVERTED);
        _submitEvidence(_proposalId, REVERTED, _evidence);
        slashingExecutor.freeze(proposals[_proposalId].subjectType, proposals[_proposalId].subjectId, false);
    }

    /**
     * @notice The slashing proposal is executed. Subject's stake is slashed and unfrozen.
     * The proposer gets a % of the slashed stake as defined by slashPercentToProposer.
     * Only executable by SLASHER_ROLE
     * @param _proposalId the proposal identifier.
     */
    function executeSlashProposal(uint256 _proposalId) external onlyRole(SLASHER_ROLE) {
        _transition(_proposalId, EXECUTED);
        Proposal memory proposal = proposals[_proposalId];
        slashingExecutor.slash(proposal.subjectType, proposal.subjectId, getSlashedStakeValue(_proposalId), proposal.proposer, slashPercentToProposer);
        slashingExecutor.freeze(proposal.subjectType, proposal.subjectId, false);
    }

    // Penalty calculation (ISlashingController)

    /**
     * @notice gets the stake amount to be slashed.
     * The amount depends on the StakePenalty.
     * In all cases, the amount will be the minimum of the max slashable stake for the subject and:
     * MIN_STAKE: a % of the subject's MIN_STAKE
     * CURRENT_STAKE: a % of the subject's active + inactive stake.
     */
    function getSlashedStakeValue(uint256 _proposalId) public view returns (uint256) {
        Proposal memory proposal = proposals[_proposalId];
        SlashPenalty memory penalty = penalties[proposal.penaltyId];
        uint256 totalStake = stakingParameters.totalStakeFor(proposal.subjectType, proposal.subjectId);
        uint256 max = Math.mulDiv(totalStake, stakingParameters.maxSlashableStakePercent(), HUNDRED_PERCENT);
        if (penalty.mode == PenaltyMode.UNDEFINED) {
            return 0;
        } else if (penalty.mode == PenaltyMode.MIN_STAKE) {
            return Math.min(max, Math.mulDiv(stakingParameters.minStakeFor(proposal.subjectType, proposal.subjectId), penalty.percentSlashed, HUNDRED_PERCENT));
        } else if (penalty.mode == PenaltyMode.CURRENT_STAKE) {
            return Math.min(max, Math.mulDiv(totalStake, penalty.percentSlashed, HUNDRED_PERCENT));
        }
        return 0;
    }

    // Gets the subjectType and subjectId for a proposalId
    function getSubject(uint256 _proposalId) external view returns (uint8 subjectType, uint256 subject) {
        return (proposals[_proposalId].subjectType, proposals[_proposalId].subjectId);
    }

    // Gets the proposer of a proposalId
    function getProposer(uint256 _proposalId) external view returns (address) {
        return proposals[_proposalId].proposer;
    }

    // Admin methods
    function setSlashingExecutor(ISlashingExecutor _executor) external onlyRole(STAKING_ADMIN_ROLE) {
        _setSlashingExecutor(_executor);
    }

    function setStakingParametersManager(FortaStakingParameters _stakingParameters) external onlyRole(STAKING_ADMIN_ROLE) {
        _setStakingParametersManager(_stakingParameters);
    }

    function setDepositAmount(uint256 _amount) external onlyRole(STAKING_ADMIN_ROLE) {
        _setDepositAmount(_amount);
    }

    function setSlashPercentToProposer(uint256 _amount) external onlyRole(STAKING_ADMIN_ROLE) {
        _setSlashPercentToProposer(_amount);
    }

    function setSlashPenalties(bytes32[] calldata _slashReasons, SlashPenalty[] calldata _slashPenalties) external onlyRole(STAKING_ADMIN_ROLE) {
        _setSlashPenalties(_slashReasons, _slashPenalties);
    }

    // Private validations

    function _authorizeRevertSlashProposal(uint256 _proposalId) private view {
        bytes32 requiredRole = currentState(_proposalId) == IN_REVIEW ? SLASHING_ARBITER_ROLE : SLASHER_ROLE;
        if (!hasRole(requiredRole, _msgSender())) {
            revert MissingRole(requiredRole, _msgSender());
        }
        // If it's in another state, _transition() will revert
    }

    // Private param setting

    function _setSlashingExecutor(ISlashingExecutor _executor) private {
        if (address(_executor) == address(0)) revert ZeroAddress("_executor");
        slashingExecutor = _executor;
        emit SlashingExecutorChanged(address(_executor));
    }

    function _setStakingParametersManager(FortaStakingParameters _stakingParameters) private {
        if (address(_stakingParameters) == address(0)) revert ZeroAddress("_stakingParameters");
        stakingParameters = _stakingParameters;
        emit StakingParametersManagerChanged(address(_stakingParameters));
    }

    function _setDepositAmount(uint256 _amount) private {
        if (_amount == 0) revert ZeroAmount("_amount");
        depositAmount = _amount;
        emit DepositAmountChanged(depositAmount);
    }

    function _setSlashPercentToProposer(uint256 _amount) private onlyValidPercent(_amount) {
        slashPercentToProposer = _amount;
        emit SlashPercentToProposerChanged(_amount);
    }

    function _setSlashPenalties(bytes32[] calldata _slashReasons, SlashPenalty[] calldata _slashPenalties) private {
        uint256 length = _slashReasons.length;
        if (length != _slashPenalties.length) revert DifferentLengthArray("_slashReasons", "_slashPenalties");
        for (uint256 i = 0; i < length; i++) {
            if (penalties[_slashReasons[i]].mode != PenaltyMode.UNDEFINED) {
                emit SlashPenaltyRemoved(_slashReasons[i], penalties[_slashReasons[i]].percentSlashed, penalties[_slashReasons[i]].mode);
            }
            penalties[_slashReasons[i]] = _slashPenalties[i];
            emit SlashPenaltyAdded(_slashReasons[i], _slashPenalties[i].percentSlashed, _slashPenalties[i].mode);
        }
    }

    // Evidence handling
    function _submitEvidence(
        uint256 _proposalId,
        StateMachines.State _stateId,
        string[] calldata _evidence
    ) private {
        uint256 evidenceLength = _evidence.length;
        if (evidenceLength == 0) revert ZeroAmount("evidence length");
        if (evidenceLength > MAX_EVIDENCE_LENGTH) revert ArrayTooBig(evidenceLength, MAX_EVIDENCE_LENGTH);
        for (uint256 i = 0; i < evidenceLength; i++) {
            if (bytes(_evidence[i]).length > MAX_CHAR_LENGTH) revert StringTooLarge(bytes(_evidence[i]).length, MAX_CHAR_LENGTH);
        }
        emit EvidenceSubmitted(_proposalId, _stateId, _evidence);
    }

    // Private deposit handling
    function _returnDeposit(uint256 _proposalId) private {
        uint256 amount = deposits[_proposalId];
        delete deposits[_proposalId];
        SafeERC20.safeTransfer(depositToken, proposals[_proposalId].proposer, amount);
        emit DepositReturned(_proposalId, proposals[_proposalId].proposer, amount);
    }

    function _slashDeposit(uint256 _proposalId) private {
        uint256 amount = deposits[_proposalId];
        delete deposits[_proposalId];
        SafeERC20.safeTransfer(depositToken, slashingExecutor.treasury(), amount);
        emit DepositSlashed(_proposalId, proposals[_proposalId].proposer, amount);
    }

    function transitionTable() public view virtual override returns (StateMachines.Machine) {
        return _transitionTable;
    }
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "./FortaStaking.sol";

contract FortaStakingParameters is BaseComponentUpgradeable, SubjectTypeValidator, IStakeController {
    FortaStaking private _fortaStaking;
    // stake subject parameters for each subject
    mapping(uint8 => IStakeSubject) private _stakeSubjectHandlers;

    event FortaStakingChanged(address staking);

    string public constant version = "0.1.1";
    uint256 public constant maxSlashableStakePercent = 90;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address forwarder) initializer ForwardedContext(forwarder) {}

    /**
     * @notice Initializer method, access point to initialize inheritance tree.
     * @param __manager address of AccessManager.
     * @param __router address of Router.
     * @param __fortaStaking address of FortaStaking.
     */
    function initialize(
        address __manager,
        address __router,
        address __fortaStaking
    ) public initializer {
        __AccessManaged_init(__manager);
        __Routed_init(__router);
        __UUPSUpgradeable_init();
        _setFortaStaking(__fortaStaking);
    }

    /// Setter for FortaStaking implementation address.
    function setFortaStaking(address newFortaStaking) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setFortaStaking(newFortaStaking);
    }

    function _setFortaStaking(address newFortaStaking) internal {
        if (newFortaStaking == address(0)) revert ZeroAddress("newFortaStaking");
        _fortaStaking = FortaStaking(newFortaStaking);
        emit FortaStakingChanged(address(_fortaStaking));
    }

    /**
     * Sets stake subject handler stake for subject type.
     */
    function setStakeSubjectHandler(uint8 subjectType, IStakeSubject subjectHandler) external onlyRole(DEFAULT_ADMIN_ROLE) onlyValidSubjectType(subjectType) {
        if (address(subjectHandler) == address(0)) revert ZeroAddress("subjectHandler");
        emit StakeSubjectHandlerChanged(address(subjectHandler), address(_stakeSubjectHandlers[subjectType]));
        _stakeSubjectHandlers[subjectType] = subjectHandler;
    }

    /// Get max stake for that `subjectType` and `subject`. If not set, will return 0.
    function maxStakeFor(uint8 subjectType, uint256 subject) external view returns (uint256) {
        return _stakeSubjectHandlers[subjectType].getStakeThreshold(subject).max;
    }

    /// Get min stake for that `subjectType` and `subject`. If not set, will return 0.
    function minStakeFor(uint8 subjectType, uint256 subject) external view returns (uint256) {
        return _stakeSubjectHandlers[subjectType].getStakeThreshold(subject).min;
    }

    /// Get if staking is activated for that `subjectType` and `subject`. If not set, will return false.
    function isStakeActivatedFor(uint8 subjectType, uint256 subject) external view returns (bool) {
        return _stakeSubjectHandlers[subjectType].getStakeThreshold(subject).activated;
    }

    /// Gets active stake (amount of staked tokens) on `subject` id for `subjectType`
    function activeStakeFor(uint8 subjectType, uint256 subject) external view returns (uint256) {
        return _fortaStaking.activeStakeFor(subjectType, subject);
    }

    /// Gets active and inactive stake (amount of staked tokens) on `subject` id for `subjectType`
    function totalStakeFor(uint8 subjectType, uint256 subject) external view override returns (uint256) {
        return _fortaStaking.activeStakeFor(subjectType, subject) + _fortaStaking.inactiveStakeFor(subjectType, subject);
    }

    /// Checks if subject, subjectType is registered
    function isRegistered(uint8 subjectType, uint256 subject) external view returns (bool) {
        return _stakeSubjectHandlers[subjectType].isRegistered(subject);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * Library to handle Finite State Machines and codify their transitions in a uint256.
 * NOTE: the number of states is limited to 16.
 * Rewritten by Hadrien Croubois, https://github.com/Amxx
 */
library StateMachines {
    type Machine is uint256;
    
    Machine internal constant EMPTY_MACHINE = Machine.wrap(0);
    
    enum State {
        _00, _01, _02, _03, 
        _04, _05, _06, _07, 
        _08, _09, _10, _11, 
        _12, _13, _14, _15
    }

    function statesToEdge(State fromState, State toState) internal pure returns (uint256) {
        return 1 << (uint8(toState) * 16 + uint8(fromState));
    }

    function isTransitionValid(Machine self, State fromState, State toState) internal pure returns (bool) {
        return Machine.unwrap(self) & statesToEdge(fromState, toState) != 0;
    }

    function addEdgeTransition(Machine self, State fromState, State toState) internal pure returns (Machine newMachine) {
        return Machine.wrap(Machine.unwrap(self) | statesToEdge(fromState, toState));
    }

    function removeEdgeTransition(Machine self, State fromState, State toState) internal pure returns (Machine newMachine) {
        return Machine.wrap(Machine.unwrap(self) & ~statesToEdge(fromState, toState));
    }
}

/**
 * Contract that allows for the creation and management of finite state machines.
 * The state machines will transition following a commonly defined state set.
 * What each state and state transition means, as well as the business logic of defining a valid transition
 * are left to the inheriting contract.
 */
abstract contract StateMachineController {
    using StateMachines for StateMachines.Machine;

    event StateTransition(uint256 indexed machineId, StateMachines.State indexed fromState, StateMachines.State indexed toState);
    error InvalidState(StateMachines.State state);
    error InvalidStateTransition(StateMachines.State fromState, StateMachines.State toState);

    mapping(uint256 => StateMachines.State) private _machines;

    modifier onlyInState(uint256 _machineId, StateMachines.State _state) {
        if (_state != _machines[_machineId]) revert InvalidState(_state);
        _;
    }

    function transitionTable() virtual public view returns(StateMachines.Machine);
    
    function _transition(uint256 _machineId, StateMachines.State _newState) internal {
        if (!transitionTable().isTransitionValid(_machines[_machineId], _newState)) revert InvalidStateTransition(_machines[_machineId], _newState);
        emit StateTransition(_machineId, _machines[_machineId], _newState);
        _machines[_machineId] = _newState;
    }

    /**
     * Checks the current state of a machine.
     * @param _machineId the identifier of a machine.
     * @return current state identifier.
     */
    function currentState(uint256 _machineId) public view returns (StateMachines.State) {
        return _machines[_machineId];
    }
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/draft-IERC2612.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/Timers.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";

import "./FortaStakingUtils.sol";
import "./SubjectTypes.sol";
import "./IStakeController.sol";
import "./ISlashingExecutor.sol";
import "../BaseComponentUpgradeable.sol";
import "../../tools/Distributions.sol";

interface IRewardReceiver {
    function onRewardReceived(
        uint8 subjectType,
        uint256 subject,
        uint256 amount
    ) external;
}

/**
 * @dev This is a generic staking contract for the Forta platform. It allows any account to deposit ERC20 tokens to
 * delegate their "power" by staking on behalf of a particular subject. The subject can be scanner, or any other actor
 * in the Forta ecosystem, who need to lock assets in order to contribute to the system.
 *
 * Stakers take risks with their funds, as bad action from a subject can lead to slashing of the funds. In the
 * meantime, stakers are elligible for rewards. Rewards distributed to a particular subject's stakers are distributed
 * following to each staker's share in the subject.
 *
 * Stakers can withdraw their funds, following a withdrawal delay. During the withdrawal delay, funds are no longer
 * counting toward the active stake of a subject, but are still slashable.
 *
 * The SLASHER_ROLE should be given to a future smart contract that will be in charge of resolving disputes.
 *
 * Stakers receive ERC1155 shares in exchange for their stake, making the active stake transferable. When a withdrawal
 * is initiated, similarly the ERC1155 tokens representing the (transferable) active shares are burned in exchange for
 * non-transferable ERC1155 tokens representing the inactive shares.
 *
 * ERC1155 shares representing active stake are transferable, and can be used in an AMM. Their value is however subject
 * to quick devaluation in case of slashing event for the corresponding subject. Thus, trading of such shares should be
 * be done very carefully.
 *
 * WARNING: To stake from another smart contract (smart contract wallets included), it must be fully ERC1155 compatible,
 * implementing ERC1155Receiver. If not, minting of active and inactive shares will fail.
 * Do not deposit on the constructor if you don't implement ERC1155Receiver. During the construction, the minting will
 * succeed but you will not be able to withdraw or mint new shares from the contract. If this happens, transfer your
 * shares to an EOA or fully ERC1155 compatible contract.
 */
contract FortaStaking is BaseComponentUpgradeable, ERC1155SupplyUpgradeable, SubjectTypeValidator, ISlashingExecutor {
    using Distributions for Distributions.Balances;
    using Distributions for Distributions.SignedBalances;
    using Timers for Timers.Timestamp;
    using ERC165Checker for address;

    // NOTE: do not set as immutable. Previous versions were deployed, and setting as immutable would
    // generate an incopatible storage layout for new versions, risking storage layout collisions.
    IERC20 public stakedToken;

    // subject => active stake
    Distributions.Balances private _activeStake;
    // subject => inactive stake
    Distributions.Balances private _inactiveStake;

    // subject => staker => inactive stake timer
    mapping(uint256 => mapping(address => Timers.Timestamp)) private _lockingDelay;

    // subject => reward
    Distributions.Balances private _rewards;
    // subject => staker => released reward
    mapping(uint256 => Distributions.SignedBalances) private _released;

    // frozen tokens
    mapping(uint256 => bool) private _frozen;

    // withdrawal delay
    uint64 private _withdrawalDelay;

    // treasury for slashing
    address private _treasury;

    uint256 private constant HUNDRED_PERCENT = 100;


    IStakeController private _stakingParameters;
    uint256 public constant MIN_WITHDRAWAL_DELAY = 1 days;
    uint256 public constant MAX_WITHDRAWAL_DELAY = 90 days;


    event StakeDeposited(uint8 indexed subjectType, uint256 indexed subject, address indexed account, uint256 amount);
    event WithdrawalInitiated(uint8 indexed subjectType, uint256 indexed subject, address indexed account, uint64 deadline);
    event WithdrawalExecuted(uint8 indexed subjectType, uint256 indexed subject, address indexed account);
    event Froze(uint8 indexed subjectType, uint256 indexed subject, address indexed by, bool isFrozen);
    event Slashed(uint8 indexed subjectType, uint256 indexed subject, address indexed by, uint256 value);
    event SlashedShareSent(uint8 indexed subjectType, uint256 indexed subject, address indexed by, uint256 value);
    event Rewarded(uint8 indexed subjectType, uint256 indexed subject, address indexed from, uint256 value);
    event Released(uint8 indexed subjectType, uint256 indexed subject, address indexed to, uint256 value);
    event DelaySet(uint256 newWithdrawalDelay);
    event TreasurySet(address newTreasury);
    event StakeParamsManagerSet(address indexed newManager);
    event MaxStakeReached(uint8 indexed subjectType, uint256 indexed subject);
    event TokensSwept(address indexed token, address to, uint256 amount);

    error WithdrawalNotReady();
    error SlashingOver90Percent();
    error WithdrawalSharesNotTransferible();
    error FrozenSubject();
    error NoActiveShares();
    error NoInactiveShares();
    error StakeInactiveOrSubjectNotFound();

    string public constant version = "0.1.1";

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _forwarder) initializer ForwardedContext(_forwarder) {
        
    }

    /**
     * @notice Initializer method, access point to initialize inheritance tree.
     * @param __manager address of AccessManager.
     * @param __router address of Router.
     * @param __withdrawalDelay cooldown period between withdrawal init and withdrawal (in seconds).
     * @param __treasury address where the slashed tokens go to.
     */
    function initialize(
        address __manager,
        address __router,
        uint64 __withdrawalDelay,
        address __treasury,
        address __stakedToken
    ) public initializer {
        if (__treasury == address(0)) revert ZeroAddress("__treasury");
        if (__stakedToken == address(0)) revert ZeroAddress("__stakedToken");
        __AccessManaged_init(__manager);
        __Routed_init(__router);
        __UUPSUpgradeable_init();
        __ERC1155_init("");
        __ERC1155Supply_init();
        _withdrawalDelay = __withdrawalDelay;
        _treasury = __treasury;
        stakedToken = IERC20(__stakedToken);
        emit DelaySet(__withdrawalDelay);
        emit TreasurySet(__treasury);
    }

    /// Returns treasury address (slashed tokens destination)
    function treasury() public view returns (address) {
        return _treasury;
    }

    /**
     * @notice Get stake of a subject (not marked for withdrawal).
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return amount of stakedToken actively staked on subject+subjectType.
     */
    function activeStakeFor(uint8 subjectType, uint256 subject) public view returns (uint256) {
        return _activeStake.balanceOf(FortaStakingUtils.subjectToActive(subjectType, subject));
    }

    /**
     * @notice Get total active stake of all subjects (not marked for withdrawal).
     * @return amount of stakedToken actively staked on all subject+subjectTypes.
     */
    function totalActiveStake() public view returns (uint256) {
        return _activeStake.totalSupply();
    }

    /**
     * @notice Get inactive stake of a subject (marked for withdrawal).
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return amount of stakedToken still staked on subject+subjectType but marked for withdrawal.
     */
    function inactiveStakeFor(uint8 subjectType, uint256 subject) external view returns (uint256) {
        return _inactiveStake.balanceOf(FortaStakingUtils.subjectToInactive(subjectType, subject));
    }

    /**
     * @notice Get total inactive stake of all subjects (marked for withdrawal).
     * @return amount of stakedToken still staked on all subject+subjectTypes but marked for withdrawal.
     */
    function totalInactiveStake() public view returns (uint256) {
        return _inactiveStake.totalSupply();
    }

    /**
     * @notice Get (active) shares of an account on a subject, corresponding to a fraction of the subject stake.
     * @dev This is equivalent to getting the ERC1155 balanceOf for keccak256(abi.encodePacked(subjectType, subject)),
     * shifted 9 bits, with the 9th bit set and uint8(subjectType) masked in
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param account holder of the ERC1155 staking shares.
     * @return amount of ERC1155 shares account is in possession in representing stake on subject+subjectType.
     */
    function sharesOf(
        uint8 subjectType,
        uint256 subject,
        address account
    ) public view returns (uint256) {
        return balanceOf(account, FortaStakingUtils.subjectToActive(subjectType, subject));
    }

    /**
     * @notice Get the total (active) shares on a subject.
     * @dev This is equivalent to getting the ERC1155 totalSupply for keccak256(abi.encodePacked(subjectType, subject)),
     * shifted 9 bits, with the 9th bit set and uint8(subjectType) masked in
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return total ERC1155 shares representing stake on subject+subjectType.
     */
    function totalShares(uint8 subjectType, uint256 subject) external view returns (uint256) {
        return totalSupply(FortaStakingUtils.subjectToActive(subjectType, subject));
    }

    /**
     * @notice Get inactive shares of an account on a subject, corresponding to a fraction of the subject inactive stake.
     * @dev This is equivalent to getting the ERC1155 balanceOf for keccak256(abi.encodePacked(subjectType, subject)),
     * shifted 9 bits, with the 9th bit unset and uint8(subjectType) masked in.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param account holder of the ERC1155 staking shares.
     * @return amount of ERC1155 shares account is in possession in representing inactive stake on subject+subjectType, marked for withdrawal.
     */
    function inactiveSharesOf(
        uint8 subjectType,
        uint256 subject,
        address account
    ) external view returns (uint256) {
        return balanceOf(account, FortaStakingUtils.subjectToInactive(subjectType, subject));
    }

    /**
     * @notice Get the total inactive shares on a subject.
     * @dev This is equivalent to getting the ERC1155 totalSupply for keccak256(abi.encodePacked(subjectType, subject)),
     * shifted 9 bits, with the 9th bit unset and uint8(subjectType) masked in
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return total ERC1155 shares representing inactive stake on subject+subjectType, marked for withdrawal.
     */
    function totalInactiveShares(uint8 subjectType, uint256 subject) external view returns (uint256) {
        return totalSupply(FortaStakingUtils.subjectToInactive(subjectType, subject));
    }

    /**
     * @notice Checks if a subject frozen (stake of frozen subject cannot be withdrawn).
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return true if subject is frozen, false otherwise
     */
    function isFrozen(uint8 subjectType, uint256 subject) public view returns (bool) {
        return _frozen[FortaStakingUtils.subjectToActive(subjectType, subject)];
    }

    /**
     * @notice Deposit `stakeValue` tokens for a given `subject`, and mint the corresponding active ERC1155 shares.
     * will return tokens staked over maximum for the subject.
     * If stakeValue would drive the stake over the maximum, only stakeValue - excess is transferred, but transaction will
     * not fail.
     * Reverts if max stake for subjectType not set, or subject not found
     * @dev NOTE: Subject type is necessary because we can't infer subject ID uniqueness between scanners, agents, etc
     * Emits a ERC1155.TransferSingle event and StakeDeposited (to allow accounting per subject type)
     * Emits MaxStakeReached(subjectType, activeSharesId)
     * WARNING: To stake from another smart contract (smart contract wallets included), it must be fully ERC1155 compatible,
     * implementing ERC1155Receiver. If not, minting of active and inactive shares will fail.
     * Do not deposit on the constructor if you don't implement ERC1155Receiver. During the construction, the minting will
     * succeed but you will not be able to withdraw or mint new shares from the contract. If this happens, transfer your
     * shares to an EOA or fully ERC1155 compatible contract.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param stakeValue amount of staked token.
     * @return amount of ERC1155 active shares minted.
     */
    function deposit(
        uint8 subjectType,
        uint256 subject,
        uint256 stakeValue
    ) public onlyValidSubjectType(subjectType) returns (uint256) {
        if (address(_stakingParameters) == address(0)) revert ZeroAddress("_stakingParameters");
        if (!_stakingParameters.isStakeActivatedFor(subjectType, subject)) revert StakeInactiveOrSubjectNotFound();
        address staker = _msgSender();
        uint256 activeSharesId = FortaStakingUtils.subjectToActive(subjectType, subject);
        bool reachedMax;
        (stakeValue, reachedMax) = _getInboundStake(subjectType, subject, stakeValue);
        if (reachedMax) {
            emit MaxStakeReached(subjectType, subject);
        }
        uint256 sharesValue = stakeToActiveShares(activeSharesId, stakeValue);
        SafeERC20.safeTransferFrom(stakedToken, staker, address(this), stakeValue);

        _activeStake.mint(activeSharesId, stakeValue);
        _mint(staker, activeSharesId, sharesValue, new bytes(0));
        emit StakeDeposited(subjectType, subject, staker, stakeValue);
        // NOTE: hooks will be reintroduced (with more info) when first use case is implemented. For now they are removed
        // to reduce attack surface.
        // _emitHook(abi.encodeWithSignature("hook_afterStakeChanged(uint8, uint256)", subjectType, subject));
        return sharesValue;
    }

    /**
     * Calculates how much of the incoming stake fits for subject.
     * @param subjectType valid subect type
     * @param subject the id of the subject
     * @param stakeValue stake sent by staker
     * @return stakeValue - excess
     * @return true if reached max
     */
    function _getInboundStake(
        uint8 subjectType,
        uint256 subject,
        uint256 stakeValue
    ) private view returns (uint256, bool) {
        uint256 max = _stakingParameters.maxStakeFor(subjectType, subject);
        if (activeStakeFor(subjectType, subject) >= max) {
            return (0, true);
        } else {
            uint256 stakeLeft = max - activeStakeFor(subjectType, subject);
            return (
                Math.min(
                    stakeValue, // what the user wants to stake
                    stakeLeft // what is actually left
                ),
                activeStakeFor(subjectType, subject) + stakeValue >= max
            );
        }
    }

    /** @notice Starts the withdrawal process for an amount of shares. Burns active shares and mints inactive
     * shares (non transferrable). Stake will be available for withdraw() after _withdrawalDelay. If the
     * subject has not been slashed, the shares will correspond 1:1 with stake.
     * @dev Emits a WithdrawalInitiated event.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param sharesValue amount of shares token.
     * @return amount of time until withdrawal is valid.
     */
    function initiateWithdrawal(
        uint8 subjectType,
        uint256 subject,
        uint256 sharesValue
    ) public onlyValidSubjectType(subjectType) returns (uint64) {
        address staker = _msgSender();
        uint256 activeSharesId = FortaStakingUtils.subjectToActive(subjectType, subject);
        if (balanceOf(staker, activeSharesId) == 0) revert NoActiveShares();
        uint64 deadline = SafeCast.toUint64(block.timestamp) + _withdrawalDelay;

        _lockingDelay[activeSharesId][staker].setDeadline(deadline);

        uint256 activeShares = Math.min(sharesValue, balanceOf(staker, activeSharesId));
        uint256 stakeValue = activeSharesToStake(activeSharesId, activeShares);
        uint256 inactiveShares = stakeToInactiveShares(FortaStakingUtils.activeToInactive(activeSharesId), stakeValue);

        _activeStake.burn(activeSharesId, stakeValue);
        _inactiveStake.mint(FortaStakingUtils.activeToInactive(activeSharesId), stakeValue);
        _burn(staker, activeSharesId, activeShares);
        _mint(staker, FortaStakingUtils.activeToInactive(activeSharesId), inactiveShares, new bytes(0));

        emit WithdrawalInitiated(subjectType, subject, staker, deadline);
        // NOTE: hooks will be reintroduced (with more info) when first use case is implemented. For now they are removed
        // to reduce attack surface.
        // _emitHook(abi.encodeWithSignature("hook_afterStakeChanged(uint8, uint256)", subjectType, subject));
        return deadline;
    }

    /**
     * @notice Burn `sharesValue` inactive shares for a given `subject`, and withdraw the corresponding tokens
     * (if the subject type has not been frozen, and the withdrawal delay time has passed).
     * @dev shares must have been marked for withdrawal before by initiateWithdrawal().
     * Emits events WithdrawalExecuted and ERC1155.TransferSingle.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return amount of withdrawn staked tokens.
     */
    function withdraw(uint8 subjectType, uint256 subject) public onlyValidSubjectType(subjectType) returns (uint256) {
        address staker = _msgSender();
        uint256 inactiveSharesId = FortaStakingUtils.subjectToInactive(subjectType, subject);
        if (balanceOf(staker, inactiveSharesId) == 0) revert NoInactiveShares();
        if (_frozen[FortaStakingUtils.inactiveToActive(inactiveSharesId)]) revert FrozenSubject();

        Timers.Timestamp storage timer = _lockingDelay[FortaStakingUtils.inactiveToActive(inactiveSharesId)][staker];
        if (!timer.isExpired()) revert WithdrawalNotReady();
        timer.reset();
        emit WithdrawalExecuted(subjectType, subject, staker);

        uint256 inactiveShares = balanceOf(staker, inactiveSharesId);
        uint256 stakeValue = inactiveSharesToStake(inactiveSharesId, inactiveShares);

        _inactiveStake.burn(inactiveSharesId, stakeValue);
        _burn(staker, inactiveSharesId, inactiveShares);
        SafeERC20.safeTransfer(stakedToken, staker, stakeValue);
        // NOTE: hooks will be reintroduced (with more info) when first use case is implemented. For now they are removed
        // to reduce attack surface.
        // _emitHook(abi.encodeWithSignature("hook_afterStakeChanged(uint8, uint256)", subjectType, subject));

        return stakeValue;
    }

    /**
     * @notice Slash a fraction of a subject stake, and transfer it to the treasury. Restricted to the `SLASHER_ROLE`.
     * @dev This will alter the relationship between shares and stake, reducing shares value for a subject.
     * Emits a Slashed event.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param stakeValue amount of staked token to be slashed.
     * @param proposer address of the slash proposer. Must be nonzero address if proposerPercent > 0
     * @param proposerPercent percentage of stakeValue sent to the proposer. From 0 to FortaStakingParameters.maxSlashableStakePercent()
     * @return stakeValue
     */
    function slash(
        uint8 subjectType,
        uint256 subject,
        uint256 stakeValue,
        address proposer,
        uint256 proposerPercent
    ) public override onlyRole(SLASHER_ROLE) returns (uint256) {
        uint256 activeSharesId = FortaStakingUtils.subjectToActive(subjectType, subject);
        uint256 activeStake = _activeStake.balanceOf(activeSharesId);
        uint256 inactiveStake = _inactiveStake.balanceOf(FortaStakingUtils.activeToInactive(activeSharesId));

        // We set the slash limit at 90% of the stake, so new depositors on slashed pools (with now 0 stake) won't mint
        // an amounts of shares so big that they might cause overflows.
        // New shares = pool shares * new staked amount / pool stake
        // See deposit and stakeToActiveShares methods.
        uint256 maxSlashableStake = Math.mulDiv(activeStake + inactiveStake, _stakingParameters.maxSlashableStakePercent(), HUNDRED_PERCENT);
        if (stakeValue > maxSlashableStake) revert SlashingOver90Percent();

        uint256 slashFromActive = Math.mulDiv(activeStake, stakeValue, activeStake + inactiveStake);
        uint256 slashFromInactive = stakeValue - slashFromActive;
        stakeValue = slashFromActive + slashFromInactive;

        _activeStake.burn(activeSharesId, slashFromActive);
        _inactiveStake.burn(FortaStakingUtils.activeToInactive(activeSharesId), slashFromInactive);

        if (proposerPercent > 0) {
            if (proposer == address(0)) revert ZeroAddress("proposer");
            uint256 proposerShare = Math.mulDiv(stakeValue, proposerPercent, HUNDRED_PERCENT);
            SafeERC20.safeTransfer(stakedToken, proposer, proposerShare);
            emit SlashedShareSent(subjectType, subject, proposer, proposerShare);
            SafeERC20.safeTransfer(stakedToken, _treasury, stakeValue - proposerShare);
        } else {
            SafeERC20.safeTransfer(stakedToken, _treasury, stakeValue);
        }
        emit Slashed(subjectType, subject, _msgSender(), stakeValue);

        return stakeValue;
    }

    /**
     * @notice Freeze/unfreeze withdrawal of a subject stake. This will be used when something suspicious happens
     * with a subject but there is not a strong case yet for slashing.
     * Restricted to the `SLASHER_ROLE`.
     * @dev Emits a Freeze event.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param frozen true to freeze, false to unfreeze.
     */
    function freeze(
        uint8 subjectType,
        uint256 subject,
        bool frozen
    ) public override onlyRole(SLASHER_ROLE) onlyValidSubjectType(subjectType) {
        _frozen[FortaStakingUtils.subjectToActive(subjectType, subject)] = frozen;
        emit Froze(subjectType, subject, _msgSender(), frozen);
    }

    /**
     * @notice Deposit reward value for a given `subject`. The corresponding tokens will be shared amongst the shareholders
     * of this subject.
     * @dev Emits a Reward event.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param value amount of reward tokens.
     */
    function reward(
        uint8 subjectType,
        uint256 subject,
        uint256 value
    ) public onlyValidSubjectType(subjectType) {
        SafeERC20.safeTransferFrom(stakedToken, _msgSender(), address(this), value);
        _rewards.mint(FortaStakingUtils.subjectToActive(subjectType, subject), value);
        emit Rewarded(subjectType, subject, _msgSender(), value);
    }

    /**
     * @notice Sweep all token that might be mistakenly sent to the contract. This covers both unrelated tokens and staked
     * tokens that would be sent through a direct transfer. Restricted to SWEEPER_ROLE.
     * If tokens are the same as staked tokens, only the extra tokens (no stake or rewards) will be transferred.
     * @dev WARNING: thoroughly review the token to b
     * @param token address of the token to be swept.
     * @param recipient destination address of the swept tokens
     * @return amount of tokens swept. For unrelated tokens is FortaStaking's balance, for stakedToken its
     * the balance over the active stake + inactive stake + rewards
     */
    function sweep(IERC20 token, address recipient) public onlyRole(SWEEPER_ROLE) returns (uint256) {
        uint256 amount = token.balanceOf(address(this));

        if (token == stakedToken) {
            amount -= totalActiveStake();
            amount -= totalInactiveStake();
            amount -= _rewards.totalSupply();
        }

        SafeERC20.safeTransfer(token, recipient, amount);
        emit TokensSwept(address(token), recipient, amount);
        return amount;
    }

    /**
     * @notice Release reward owed by given `account` for its current or past share for a given `subject`.
     * @dev If staking from a contract, said contract may optionally implement ERC165 for IRewardReceiver.
     * Emits a Release event.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @param account that staked on the subject.
     * @return available reward transferred.
     */
    function releaseReward(
        uint8 subjectType,
        uint256 subject,
        address account
    ) public onlyValidSubjectType(subjectType) returns (uint256) {
        uint256 activeSharesId = FortaStakingUtils.subjectToActive(subjectType, subject);
        uint256 value = _availableReward(activeSharesId, account);
        _rewards.burn(activeSharesId, value);
        _released[activeSharesId].mint(account, SafeCast.toInt256(value));

        SafeERC20.safeTransfer(stakedToken, account, value);

        emit Released(subjectType, subject, account, value);

        if (Address.isContract(account) && account.supportsInterface(type(IRewardReceiver).interfaceId)) {
            IRewardReceiver(account).onRewardReceived(subjectType, subject, value);
        }

        return value;
    }

    /**
     * @notice Amount of reward tokens owed by given `account` for its current or past share for a given `subject`.
     * @param activeSharesId ERC1155 id representing the active shares of a subject / subjectType pair.
     * @param account address of the staker
     * @return rewards available for staker on that subject.
     */
    function _availableReward(uint256 activeSharesId, address account) internal view returns (uint256) {
        return
            SafeCast.toUint256(
                SafeCast.toInt256(_historicalRewardFraction(activeSharesId, balanceOf(account, activeSharesId), Math.Rounding.Down)) - _released[activeSharesId].balanceOf(account)
            );
    }

    /**
     * @dev Amount of reward tokens owed by given `account` for its current or past share for a given `subject`.
     * @param subjectType type of staking subject (see SubjectTypes.sol)
     * @param subject ID of subject
     * @param account address of the staker
     * @return rewards available for staker on that subject.
     */
    function availableReward(
        uint8 subjectType,
        uint256 subject,
        address account
    ) external view returns (uint256) {
        uint256 activeSharesId = FortaStakingUtils.subjectToActive(subjectType, subject);
        return _availableReward(activeSharesId, account);
    }

    /**
     * @dev Relay a ERC2612 permit signature to the staked token. This cal be bundled with a {deposit} or a {reward}
     * operation using Multicall.
     * @param value amount of token allowance for deposit/reward
     * @param deadline for the meta-tx to be relayed.
     * @param v part of signature
     * @param r part of signature
     * @param s part of signature
     */
    function relayPermit(
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        IERC2612(address(stakedToken)).permit(_msgSender(), address(this), value, deadline, v, r, s);
    }

    // Internal helpers
    function _totalHistoricalReward(uint256 activeSharesId) internal view returns (uint256) {
        return SafeCast.toUint256(SafeCast.toInt256(_rewards.balanceOf(activeSharesId)) + _released[activeSharesId].totalSupply());
    }

    function _historicalRewardFraction(
        uint256 activeSharesId,
        uint256 amount,
        Math.Rounding rounding
    ) internal view returns (uint256) {
        uint256 supply = totalSupply(activeSharesId);
        return amount > 0 && supply > 0 ? Math.mulDiv(_totalHistoricalReward(activeSharesId), amount, supply, rounding) : 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // Order is important here, we must do the virtual release, which uses totalSupply(activeSharesId) in
        // _historicalRewardFraction, BEFORE the super call updates the totalSupply()
        for (uint256 i = 0; i < ids.length; i++) {
            if (FortaStakingUtils.isActive(ids[i])) {
                // Mint, burn, or transfer of subject shares would by default affect the distribution of the
                // currently available reward for the subject. We create a "virtual release" that should preserve
                // reward distribution as it was prior to the transfer.
                int256 virtualRelease = SafeCast.toInt256(_historicalRewardFraction(ids[i], amounts[i], Math.Rounding.Up));

                if (from == address(0)) {
                    _released[ids[i]].mint(to, virtualRelease);
                } else if (to == address(0)) {
                    _released[ids[i]].burn(from, virtualRelease);
                } else {
                    _released[ids[i]].transfer(from, to, virtualRelease);
                }
            } else {
                if (!(from == address(0) || to == address(0))) revert WithdrawalSharesNotTransferible();
            }
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Conversions

    /**
     * @notice Convert active token stake amount to active shares amount
     * @param activeSharesId ERC1155 active shares id
     * @param amount active stake amount
     * @return ERC1155 active shares amount
     */
    function stakeToActiveShares(uint256 activeSharesId, uint256 amount) public view returns (uint256) {
        uint256 activeStake = _activeStake.balanceOf(activeSharesId);
        return activeStake == 0 ? amount : Math.mulDiv(totalSupply(activeSharesId), amount, activeStake);
    }

    /**
     * @notice Convert inactive token stake amount to inactive shares amount
     * @param inactiveSharesId ERC1155 inactive shares id
     * @param amount inactive stake amount
     * @return ERC1155 inactive shares amount
     */
    function stakeToInactiveShares(uint256 inactiveSharesId, uint256 amount) public view returns (uint256) {
        uint256 inactiveStake = _inactiveStake.balanceOf(inactiveSharesId);
        return inactiveStake == 0 ? amount : Math.mulDiv(totalSupply(inactiveSharesId), amount, inactiveStake);
    }

    /**
     * @notice Convert active shares amount to active stake amount.
     * @param activeSharesId ERC1155 active shares id
     * @param amount ERC1155 active shares amount
     * @return active stake amount
     */
    function activeSharesToStake(uint256 activeSharesId, uint256 amount) public view returns (uint256) {
        uint256 activeSupply = totalSupply(activeSharesId);
        return activeSupply == 0 ? 0 : Math.mulDiv(_activeStake.balanceOf(activeSharesId), amount, activeSupply);
    }

    /**
     * @notice Convert inactive shares amount to inactive stake amount.
     * @param inactiveSharesId ERC1155 inactive shares id
     * @param amount ERC1155 inactive shares amount
     * @return inactive stake amount
     */
    function inactiveSharesToStake(uint256 inactiveSharesId, uint256 amount) public view returns (uint256) {
        uint256 inactiveSupply = totalSupply(inactiveSharesId);
        return inactiveSupply == 0 ? 0 : Math.mulDiv(_inactiveStake.balanceOf(inactiveSharesId), amount, inactiveSupply);
    }

    // Admin: change withdrawal delay

    /**
     * @notice Sets withdrawal delay. Restricted to DEFAULT_ADMIN_ROLE
     * @param newDelay in seconds.
     */
    function setDelay(uint64 newDelay) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newDelay < MIN_WITHDRAWAL_DELAY) revert AmountTooSmall(newDelay, MIN_WITHDRAWAL_DELAY);
        if (newDelay > MAX_WITHDRAWAL_DELAY) revert AmountTooLarge(newDelay, MAX_WITHDRAWAL_DELAY);
        _withdrawalDelay = newDelay;
        emit DelaySet(newDelay);
    }

    /**
     * @notice Sets destination of slashed tokens. Restricted to DEFAULT_ADMIN_ROLE
     * @param newTreasury address.
     */
    function setTreasury(address newTreasury) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newTreasury == address(0)) revert ZeroAddress("newTreasury");
        _treasury = newTreasury;
        emit TreasurySet(newTreasury);
    }

    // Admin: change staking parameters manager
    function setStakingParametersManager(IStakeController newStakingParameters) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (address(newStakingParameters) == address(0)) revert ZeroAddress("newStakingParameters");
        emit StakeParamsManagerSet(address(newStakingParameters));
        _stakingParameters = newStakingParameters;
    }

    // Overrides

    /**
     * @notice Sets URI of the ERC1155 tokens. Restricted to DEFAULT_ADMIN_ROLE
     * @param newUri root of the hosted metadata.
     */
    function setURI(string memory newUri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setURI(newUri);
    }

    /**
     * @notice Helper to get either msg msg.sender if not a meta transaction, signer of forwarder metatx if it is.
     * @inheritdoc ForwardedContext
     */
    function _msgSender() internal view virtual override(ContextUpgradeable, BaseComponentUpgradeable) returns (address sender) {
        return super._msgSender();
    }

    /**
     * @notice Helper to get msg.data if not a meta transaction, forwarder data in metatx if it is.
     * @inheritdoc ForwardedContext
     */
    function _msgData() internal view virtual override(ContextUpgradeable, BaseComponentUpgradeable) returns (bytes calldata) {
        return super._msgData();
    }

    uint256[40] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/draft-IERC2612.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/draft-IERC20Permit.sol";

interface IERC2612 is IERC20Permit {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

library FortaStakingUtils {
    /**
     * @dev Encode "active" and subjectType in subject by hashing them together, shifting left 9 bits,
     * setting bit 9 (to mark as active) and masking subjectType in
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return ERC1155 token id representing active shares.
     */
    function subjectToActive(uint8 subjectType, uint256 subject) internal pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(subjectType, subject))) << 9 | uint16(256)) | uint256(subjectType);
    }

    /**
     * @dev Encode "inactive" and subjectType in subject by hashing them together, shifting left 9 bits,
     * letting bit 9 unset (to mark as inactive) and masking subjectType in.
     * @param subjectType agents, scanner or future types of stake subject. See SubjectTypes.sol
     * @param subject id identifying subject (external to FortaStaking).
     * @return ERC1155 token id representing inactive shares.
     */
    function subjectToInactive(uint8 subjectType, uint256 subject) internal pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(subjectType, subject))) << 9) | uint256(subjectType);
    }

    /**
     * @dev Unsets bit 9 of an activeSharesId to mark as inactive
     * @param activeSharesId ERC1155 token id representing active shares.
     * @return ERC1155 token id representing inactive shares.
     */
    function activeToInactive(uint256 activeSharesId) internal pure returns (uint256) {
        return activeSharesId & (~uint256(1 << 8));
    }

    /**
     * @dev Sets bit 9 of an inactiveSharesId to mark as inactive
     * @param inactiveSharesId ERC1155 token id representing inactive shares.
     * @return ERC1155 token id representing active shares.
     */
    function inactiveToActive(uint256 inactiveSharesId) internal pure returns (uint256) {
        return inactiveSharesId | (1 << 8);
    }

    /**
     * @dev Checks if shares id is active
     * @param sharesId ERC1155 token id representing shares.
     * @return true if active shares, false if inactive
     */
    function isActive(uint256 sharesId) internal pure returns(bool) {
        return sharesId & (1 << 8) == 256;
    }

    /**
     * @dev Extracts subject type encoded in shares id
     * @param sharesId ERC1155 token id representing shares.
     * @return subject type (see SubjectTypes.sol)
     */
    function subjectTypeOfShares(uint256 sharesId) internal pure returns(uint8) {
        return uint8(sharesId);
    }
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

uint8 constant SCANNER_SUBJECT = 0;
uint8 constant AGENT_SUBJECT = 1;

contract SubjectTypeValidator {

    error InvalidSubjectType(uint8 subjectType);

    /**
     * @dev check if `subjectType` belongs to the defined SUBJECT_TYPES
     * @param subjectType is not an enum because some contracts using subjectTypes are not
     * upgradeable (StakingEscrow)
     */
    modifier onlyValidSubjectType(uint8 subjectType) {
        if (
            subjectType != SCANNER_SUBJECT &&
            subjectType != AGENT_SUBJECT
        ) revert InvalidSubjectType(subjectType);
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "./IStakeSubject.sol";

interface IStakeController {
    event StakeSubjectHandlerChanged(address newHandler, address oldHandler);
    function setStakeSubjectHandler(uint8 subjectType, IStakeSubject subjectHandler) external;
    function activeStakeFor(uint8 subjectType, uint256 subject) external view returns(uint256);
    function maxStakeFor(uint8 subjectType, uint256 subject) external view returns(uint256);
    function minStakeFor(uint8 subjectType, uint256 subject) external view returns(uint256);
    function totalStakeFor(uint8 subjectType, uint256 subject) external view returns(uint256);
    function maxSlashableStakePercent() external view returns(uint256);
    function isStakeActivatedFor(uint8 subjectType, uint256 subject) external view returns(bool);
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-protocol/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

interface ISlashingExecutor {
    function freeze(
        uint8 subjectType,
        uint256 subject,
        bool frozen
    ) external;

    function slash(
        uint8 subjectType,
        uint256 subject,
        uint256 stakeValue,
        address proposer,
        uint256 proposerPercent
    ) external returns (uint256);

    function treasury() external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Roles.sol";
import "./utils/AccessManaged.sol";
import "./utils/IVersioned.sol";
import "./utils/ForwardedContext.sol";
import "./utils/Routed.sol";
import "../tools/ENSReverseRegistration.sol";

/**
 * @dev The Forta platform is composed of "component" smart contracts that are upgradeable, share a common access
 * control scheme and can send use routed hooks to signal one another. They also support the multicall pattern.
 *
 * This contract contains the base of Forta components. Contract  inheriting this will have to call
 * - __AccessManaged_init(address manager)
 * - __Routed_init(address router)
 * in their initialization process.
 */
abstract contract BaseComponentUpgradeable is
    ForwardedContext,
    AccessManagedUpgradeable,
    RoutedUpgradeable,
    Multicall,
    UUPSUpgradeable,
    IVersioned
{
    
    // Access control for the upgrade process
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyRole(UPGRADER_ROLE) {
    }

    // Allow the upgrader to set ENS reverse registration
    function setName(address ensRegistry, string calldata ensName) public onlyRole(ENS_MANAGER_ROLE) {
        ENSReverseRegistration.setName(ensRegistry, ensName);
    }

    /**
     * @notice Helper to get either msg msg.sender if not a meta transaction, signer of forwarder metatx if it is.
     * @inheritdoc ForwardedContext
     */
    function _msgSender() internal view virtual override(ContextUpgradeable, ForwardedContext) returns (address sender) {
        return super._msgSender();
    }

    /**
     * @notice Helper to get msg.data if not a meta transaction, forwarder data in metatx if it is.
     * @inheritdoc ForwardedContext
     */
    function _msgData() internal view virtual override(ContextUpgradeable, ForwardedContext) returns (bytes calldata) {
        return super._msgData();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "../errors/GeneralErrors.sol";

library Distributions {
    struct Balances {
        mapping(uint256 => uint256) _balances;
        uint256 _totalSupply;
    }


    function balanceOf(Balances storage self, uint256 subjectId) internal view returns (uint256) {
        return self._balances[subjectId];
    }

    function totalSupply(Balances storage self) internal view returns (uint256) {
        return self._totalSupply;
    }

    function mint(Balances storage self, uint256 subjectId, uint256 amount) internal {
        self._balances[subjectId] += amount;
        self._totalSupply += amount;
    }

    function burn(Balances storage self, uint256 subjectId, uint256 amount) internal {
        self._balances[subjectId] -= amount;
        self._totalSupply -= amount;
    }

    function transfer(Balances storage self, uint256 from, uint256 to, uint256 amount) internal {
        self._balances[from] -= amount;
        self._balances[to] += amount;
    }

    struct SignedBalances {
        mapping(address => int256) _balances;
        int256 _totalSupply;
    }

    function balanceOf(SignedBalances storage self, address account) internal view returns (int256) {
        return self._balances[account];
    }

    function totalSupply(SignedBalances storage self) internal view returns (int256) {
        return self._totalSupply;
    }

    function mint(SignedBalances storage self, address account, int256 amount) internal {
        if (account == address(0)) revert ZeroAddress("mint");
        self._balances[account] += amount;
        self._totalSupply += amount;
    }

    function burn(SignedBalances storage self, address account, int256 amount) internal {
        if(account == address(0)) revert ZeroAddress("burn");
        self._balances[account] -= amount;
        self._totalSupply -= amount;
    }

    function transfer(SignedBalances storage self, address from, address to, int256 amount) internal {
        if (from == address(0)) revert ZeroAddress("from");
        if (to == address(0)) revert ZeroAddress("to");
        self._balances[from] -= amount;
        self._balances[to] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

interface IStakeSubject {
    struct StakeThreshold {
        uint256 min;
        uint256 max;
        bool activated;
    }
    function getStakeThreshold(uint256 subject) external view returns (StakeThreshold memory);
    function isStakedOverMin(uint256 subject) external view returns (bool);
    function isRegistered(uint256 subjectId) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
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
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
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
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
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
        _upgradeToAndCallUUPS(newImplementation, data, true);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

// These are the roles used in the components of the Forta system, except
// Forta token itself, that needs to define it's own roles for consistency across chains

bytes32 constant DEFAULT_ADMIN_ROLE = bytes32(0);

// Routing
bytes32 constant ROUTER_ADMIN_ROLE  = keccak256("ROUTER_ADMIN_ROLE");
// Base component
bytes32 constant ENS_MANAGER_ROLE   = keccak256("ENS_MANAGER_ROLE");
bytes32 constant UPGRADER_ROLE      = keccak256("UPGRADER_ROLE");
// Registries
bytes32 constant AGENT_ADMIN_ROLE   = keccak256("AGENT_ADMIN_ROLE");
bytes32 constant SCANNER_ADMIN_ROLE = keccak256("SCANNER_ADMIN_ROLE");
bytes32 constant DISPATCHER_ROLE    = keccak256("DISPATCHER_ROLE");
// Staking
bytes32 constant SLASHER_ROLE       = keccak256("SLASHER_ROLE");
bytes32 constant SWEEPER_ROLE       = keccak256("SWEEPER_ROLE");
bytes32 constant REWARDS_ADMIN_ROLE      = keccak256("REWARDS_ADMIN_ROLE");
bytes32 constant SLASHING_ARBITER_ROLE      = keccak256("SLASHING_ARBITER_ROLE");
bytes32 constant STAKING_ADMIN_ROLE      = keccak256("STAKING_ADMIN_ROLE");

// Scanner Node Version
bytes32 constant SCANNER_VERSION_ROLE = keccak256("SCANNER_VERSION_ROLE");
bytes32 constant SCANNER_BETA_VERSION_ROLE = keccak256("SCANNER_BETA_VERSION_ROLE");

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "../Roles.sol";
import "../../errors/GeneralErrors.sol";

abstract contract AccessManagedUpgradeable is ContextUpgradeable {

    using ERC165CheckerUpgradeable for address;

    IAccessControl private _accessControl;

    event AccessManagerUpdated(address indexed newAddressManager);
    error MissingRole(bytes32 role, address account);

    /**
     * @notice Checks if _msgSender() has `role`, reverts if not.
     * @param role the role to be tested, defined in Roles.sol and set in AccessManager instance.
     */
    modifier onlyRole(bytes32 role) {
        if (!hasRole(role, _msgSender())) {
            revert MissingRole(role, _msgSender());
        }
        _;
    }

    /**
     * @notice Initializer method, access point to initialize inheritance tree.
     * @param manager address of AccessManager.
     */
    function __AccessManaged_init(address manager) internal initializer {
        if (!manager.supportsInterface(type(IAccessControl).interfaceId)) revert UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(manager);
        emit AccessManagerUpdated(manager);
    }

    /**
     * @notice Checks if `account has `role` assigned.
     * @param role the role to be tested, defined in Roles.sol and set in AccessManager instance.
     * @param account the address to be tested for the role.
     * @return return true if account has role, false otherwise.
     */
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return _accessControl.hasRole(role, account);
    }

    /**
     * @notice Sets AccessManager instance. Restricted to DEFAULT_ADMIN_ROLE
     * @param newManager address of the new instance of AccessManager.
     */
    function setAccessManager(address newManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (!newManager.supportsInterface(type(IAccessControl).interfaceId)) revert UnsupportedInterface("IAccessControl");
        _accessControl = IAccessControl(newManager);
        emit AccessManagerUpdated(newManager);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

interface IVersioned {
    function version() external returns(string memory v);
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract ForwardedContext is ContextUpgradeable {

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    uint256 private constant ADDRESS_SIZE_BYTES = 20;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        // WARNING: do not set this address to other than a deployed Forwarder instance.
        // Forwarder is critical infrastructure with priviledged address, it is safe for the limited
        // functionality of the Forwarder contract, any other EOA or contract could be a security issue.
        _trustedForwarder = trustedForwarder;
    }

    /// Checks if `forwarder` address provided is the trustedForwarder set in the constructor.
    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * @notice Gets sender of the transaction of signer if meta transaction.
     * @dev If the tx is sent by the trusted forwarded, we assume it is a meta transaction and 
     * the signer address is encoded in the last 20 bytes of msg.data.
     * @return sender address of sender of the transaction of signer if meta transaction.
     */
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            return address(bytes20(msg.data[msg.data.length - ADDRESS_SIZE_BYTES: msg.data.length]));
        } else {
            return super._msgSender();
        }
    }

    /**
     * @notice Gets msg.data of the transaction or meta-tx.
     * @dev If the tx is sent by the trusted forwarded, we assume it is a meta transaction and 
     * msg.data must have the signer address (encoded in the last 20 bytes of msg.data) removed.
     * @return msg.data of the transaction of msg.data - signer address if meta transaction.
     */
    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - ADDRESS_SIZE_BYTES];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import "./AccessManaged.sol";
import "../router/IRouter.sol";
import "../../errors/GeneralErrors.sol";

abstract contract RoutedUpgradeable is AccessManagedUpgradeable {
    IRouter private _router;

    event RouterUpdated(address indexed router);

    /**
     * @notice Initializer method, access point to initialize inheritance tree.
     * @param router address of Routed.
     */
    function __Routed_init(address router) internal initializer {
        if (router == address(0)) revert ZeroAddress("router");
        _router = IRouter(router);
        emit RouterUpdated(router);
    }

    /**
     * @dev Routed contracts can use this method to notify the subscribed observers registered
     * in Router routing table. Hooks may revert on failure or not, as set when calling
     * Router.setRoutingTable(bytes4 sig, address target, bool enable, bool revertsOnFail)
     * @param data keccak256 of the method signature and param values the listener contracts.
     * will execute.
     */
    function _emitHook(bytes memory data) internal {
        if (address(_router) != address(0)) {
            try _router.hookHandler(data) {}
            catch {}
        }
    }

    /// Sets new Router instance. Restricted to DEFAULT_ADMIN_ROLE.
    function setRouter(address newRouter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newRouter == address(0)) revert ZeroAddress("newRouter");
        _router = IRouter(newRouter);
        emit RouterUpdated(newRouter);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

import { ENS } from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";

interface IReverseRegistrar {
    function ADDR_REVERSE_NODE() external view returns (bytes32);
    function ens() external view returns (ENS);
    function defaultResolver() external view returns (address);
    function claim(address) external returns (bytes32);
    function claimWithResolver(address, address) external returns (bytes32);
    function setName(string calldata) external returns (bytes32);
    function node(address) external pure returns (bytes32);
}

library ENSReverseRegistration {
    // namehash('addr.reverse')
    bytes32 internal constant ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    function setName(address ensregistry, string calldata ensname) internal {
        IReverseRegistrar(ENS(ensregistry).owner(ADDR_REVERSE_NODE)).setName(ensname);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
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
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
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
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
library StorageSlotUpgradeable {
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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

error ZeroAddress(string name);
error ZeroAmount(string name);
error EmptyArray(string name);
error EmptyString(string name);
error UnorderedArray(string name);
error DifferentLengthArray(string array1, string array2);
error ArrayTooBig(uint256 length, uint256 max);
error StringTooLarge(uint256 length, uint256 max);
error AmountTooLarge(uint256 amount, uint256 max);
error AmountTooSmall(uint256 amount, uint256 min);

error UnsupportedInterface(string name);

error SenderNotOwner(address sender, uint256 ownedId);
error DoesNotHaveAccess(address sender, string access);

// Permission here refers to XXXRegistry.sol Permission enums
error DoesNotHavePermission(address sender, uint8 permission, uint256 id);

// SPDX-License-Identifier: UNLICENSED
// See Forta Network License: https://github.com/forta-network/forta-contracts/blob/master/LICENSE.md

pragma solidity ^0.8.4;

interface IRouter {
    function hookHandler(bytes calldata) external;
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}