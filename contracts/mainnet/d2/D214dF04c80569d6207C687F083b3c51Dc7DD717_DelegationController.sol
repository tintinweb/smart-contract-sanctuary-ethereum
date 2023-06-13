// SPDX-License-Identifier: AGPL-3.0-only

/*
    DelegationController.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev
    @author Vadim Yavorsky

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

import "@skalenetwork/skale-manager-interfaces/delegation/IDelegationController.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/IDelegationPeriodManager.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/IPunisher.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/ITokenState.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/IValidatorService.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/ILocker.sol";
import "@skalenetwork/skale-manager-interfaces/delegation/ITimeHelpers.sol";
import "@skalenetwork/skale-manager-interfaces/IBountyV2.sol";
import "@skalenetwork/skale-manager-interfaces/INodes.sol";
import "@skalenetwork/skale-manager-interfaces/IConstantsHolder.sol";

import "../Permissions.sol";
import "../utils/FractionUtils.sol";
import "../utils/MathUtils.sol";
import "./PartialDifferences.sol";

/**
 * @title Delegation Controller
 * @dev This contract performs all delegation functions including delegation
 * requests, and undelegation, etc.
 *
 * Delegators and validators may both perform delegations. Validators who perform
 * delegations to themselves are effectively self-delegating or self-bonding.
 *
 * IMPORTANT: Undelegation may be requested at any time, but undelegation is only
 * performed at the completion of the current delegation period.
 *
 * Delegated tokens may be in one of several states:
 *
 * - PROPOSED: token holder proposes tokens to delegate to a validator.
 * - ACCEPTED: token delegations are accepted by a validator and are locked-by-delegation.
 * - CANCELED: token holder cancels delegation proposal. Only allowed before the proposal is accepted by the validator.
 * - REJECTED: token proposal expires at the UTC start of the next month.
 * - DELEGATED: accepted delegations are delegated at the UTC start of the month.
 * - UNDELEGATION_REQUESTED: token holder requests delegations to undelegate from the validator.
 * - COMPLETED: undelegation request is completed at the end of the delegation period.
 */
contract DelegationController is Permissions, ILocker, IDelegationController {
    using MathUtils for uint;
    using PartialDifferences for PartialDifferences.Sequence;
    using PartialDifferences for PartialDifferences.Value;
    using FractionUtils for FractionUtils.Fraction;

    struct SlashingLogEvent {
        FractionUtils.Fraction reducingCoefficient;
        uint nextMonth;
    }

    struct SlashingLog {
        //      month => slashing event
        mapping (uint => SlashingLogEvent) slashes;
        uint firstMonth;
        uint lastMonth;
    }

    struct DelegationExtras {
        uint lastSlashingMonthBeforeDelegation;
    }

    struct SlashingEvent {
        FractionUtils.Fraction reducingCoefficient;
        uint validatorId;
        uint month;
    }

    struct SlashingSignal {
        address holder;
        uint penalty;
    }

    struct LockedInPending {
        uint amount;
        uint month;
    }

    struct FirstDelegationMonth {
        // month
        uint value;
        //validatorId => month
        mapping (uint => uint) byValidator;
    }

    struct ValidatorsStatistics {
        // number of validators
        uint number;
        //validatorId => amount of delegations
        mapping (uint => uint) delegated;
    }

    uint public constant UNDELEGATION_PROHIBITION_WINDOW_SECONDS = 3 * 24 * 60 * 60;

    /// @dev delegations will never be deleted to index in this array may be used like delegation id
    Delegation[] public delegations;

    // validatorId => delegationId[]
    mapping (uint => uint[]) public delegationsByValidator;

    //        holder => delegationId[]
    mapping (address => uint[]) public delegationsByHolder;

    // delegationId => extras
    mapping(uint => DelegationExtras) private _delegationExtras;

    // validatorId => sequence
    mapping (uint => PartialDifferences.Value) private _delegatedToValidator;
    // validatorId => sequence
    mapping (uint => PartialDifferences.Sequence) private _effectiveDelegatedToValidator;

    // validatorId => slashing log
    mapping (uint => SlashingLog) private _slashesOfValidator;

    //        holder => sequence
    mapping (address => PartialDifferences.Value) private _delegatedByHolder;
    //        holder =>   validatorId => sequence
    mapping (address => mapping (uint => PartialDifferences.Value)) private _delegatedByHolderToValidator;
    //        holder =>   validatorId => sequence
    mapping (address => mapping (uint => PartialDifferences.Sequence)) private _effectiveDelegatedByHolderToValidator;

    SlashingEvent[] private _slashes;
    //        holder => index in _slashes;
    mapping (address => uint) private _firstUnprocessedSlashByHolder;

    //        holder =>   validatorId => month
    mapping (address => FirstDelegationMonth) private _firstDelegationMonth;

    //        holder => locked in pending
    mapping (address => LockedInPending) private _lockedInPendingDelegations;

    mapping (address => ValidatorsStatistics) private _numberOfValidatorsPerDelegator;

    /**
     * @dev Modifier to make a function callable only if delegation exists.
     */
    modifier checkDelegationExists(uint delegationId) {
        require(delegationId < delegations.length, "Delegation does not exist");
        _;
    }

    /**
     * @dev Update and return a validator's delegations.
     */
    function getAndUpdateDelegatedToValidatorNow(uint validatorId) external override returns (uint) {
        return _getAndUpdateDelegatedToValidator(validatorId, _getCurrentMonth());
    }

    /**
     * @dev Update and return the amount delegated.
     */
    function getAndUpdateDelegatedAmount(address holder) external override returns (uint) {
        return _getAndUpdateDelegatedByHolder(holder);
    }

    /**
     * @dev Update and return the effective amount delegated (minus slash) for
     * the given month.
     */
    function getAndUpdateEffectiveDelegatedByHolderToValidator(address holder, uint validatorId, uint month)
        external
        override
        allow("Distributor")
        returns (uint effectiveDelegated)
    {
        SlashingSignal[] memory slashingSignals = _processAllSlashesWithoutSignals(holder);
        effectiveDelegated = _effectiveDelegatedByHolderToValidator[holder][validatorId]
            .getAndUpdateValueInSequence(month);
        _sendSlashingSignals(slashingSignals);
    }

    /**
     * @dev Allows a token holder to create a delegation proposal of an `amount`
     * and `delegationPeriod` to a `validatorId`. Delegation must be accepted
     * by the validator before the UTC start of the month, otherwise the
     * delegation will be rejected.
     *
     * The token holder may add additional information in each proposal.
     *
     * Emits a {DelegationProposed} event.
     *
     * Requirements:
     *
     * - Holder must have sufficient delegatable tokens.
     * - Delegation must be above the validator's minimum delegation amount.
     * - Delegation period must be allowed.
     * - Validator must be authorized if trusted list is enabled.
     * - Validator must be accepting new delegation requests.
     */
    function delegate(
        uint validatorId,
        uint amount,
        uint delegationPeriod,
        string calldata info
    )
        external
        override
    {
        require(
            _getDelegationPeriodManager().isDelegationPeriodAllowed(delegationPeriod),
            "This delegation period is not allowed");
        _getValidatorService().checkValidatorCanReceiveDelegation(validatorId, amount);
        _checkIfDelegationIsAllowed(msg.sender, validatorId);

        SlashingSignal[] memory slashingSignals = _processAllSlashesWithoutSignals(msg.sender);

        uint delegationId = _addDelegation(
            msg.sender,
            validatorId,
            amount,
            delegationPeriod,
            info);

        // check that there is enough money
        uint holderBalance = IERC777(contractManager.getSkaleToken()).balanceOf(msg.sender);
        uint forbiddenForDelegation = ILocker(contractManager.getTokenState())
            .getAndUpdateForbiddenForDelegationAmount(msg.sender);
        require(holderBalance >= forbiddenForDelegation, "Token holder does not have enough tokens to delegate");

        emit DelegationProposed(delegationId);

        _sendSlashingSignals(slashingSignals);
    }

    /**
     * @dev See {ILocker-getAndUpdateLockedAmount}.
     */
    function getAndUpdateLockedAmount(address wallet) external override returns (uint) {
        return _getAndUpdateLockedAmount(wallet);
    }

    /**
     * @dev See {ILocker-getAndUpdateForbiddenForDelegationAmount}.
     */
    function getAndUpdateForbiddenForDelegationAmount(address wallet) external override returns (uint) {
        return _getAndUpdateLockedAmount(wallet);
    }

    /**
     * @dev Allows token holder to cancel a delegation proposal.
     *
     * Emits a {DelegationRequestCanceledByUser} event.
     *
     * Requirements:
     *
     * - `msg.sender` must be the token holder of the delegation proposal.
     * - Delegation state must be PROPOSED.
     */
    function cancelPendingDelegation(uint delegationId) external override checkDelegationExists(delegationId) {
        require(msg.sender == delegations[delegationId].holder, "Only token holders can cancel delegation request");
        require(getState(delegationId) == State.PROPOSED, "Token holders are only able to cancel PROPOSED delegations");

        delegations[delegationId].finished = _getCurrentMonth();
        _subtractFromLockedInPendingDelegations(delegations[delegationId].holder, delegations[delegationId].amount);

        emit DelegationRequestCanceledByUser(delegationId);
    }

    /**
     * @dev Allows a validator to accept a proposed delegation.
     * Successful acceptance of delegations transition the tokens from a
     * PROPOSED state to ACCEPTED, and tokens are locked for the remainder of the
     * delegation period.
     *
     * Emits a {DelegationAccepted} event.
     *
     * Requirements:
     *
     * - Validator must be recipient of proposal.
     * - Delegation state must be PROPOSED.
     */
    function acceptPendingDelegation(uint delegationId) external override checkDelegationExists(delegationId) {
        require(
            _getValidatorService().checkValidatorAddressToId(msg.sender, delegations[delegationId].validatorId),
            "No permissions to accept request");
        _accept(delegationId);
    }

    /**
     * @dev Allows delegator to undelegate a specific delegation.
     *
     * Emits UndelegationRequested event.
     *
     * Requirements:
     *
     * - `msg.sender` must be the delegator or the validator.
     * - Delegation state must be DELEGATED.
     */
    function requestUndelegation(uint delegationId) external override checkDelegationExists(delegationId) {
        require(getState(delegationId) == State.DELEGATED, "Cannot request undelegation");
        IValidatorService validatorService = _getValidatorService();
        require(
            delegations[delegationId].holder == msg.sender ||
            (validatorService.validatorAddressExists(msg.sender) &&
            delegations[delegationId].validatorId == validatorService.getValidatorId(msg.sender)),
            "Permission denied to request undelegation");
        _removeValidatorFromValidatorsPerDelegators(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId);
        processAllSlashes(msg.sender);
        delegations[delegationId].finished = _calculateDelegationEndMonth(delegationId);

        require(
            block.timestamp + UNDELEGATION_PROHIBITION_WINDOW_SECONDS
                < _getTimeHelpers().monthToTimestamp(delegations[delegationId].finished),
            "Undelegation requests must be sent 3 days before the end of delegation period"
        );

        _subtractFromAllStatistics(delegationId);

        emit UndelegationRequested(delegationId);
    }

    /**
     * @dev Allows Punisher contract to slash an `amount` of stake from
     * a validator. This slashes an amount of delegations of the validator,
     * which reduces the amount that the validator has staked. This consequence
     * may force the SKALE Manager to reduce the number of nodes a validator is
     * operating so the validator can meet the Minimum Staking Requirement.
     *
     * Emits a {SlashingEvent}.
     *
     * See {Punisher}.
     */
    function confiscate(uint validatorId, uint amount) external override allow("Punisher") {
        uint currentMonth = _getCurrentMonth();
        FractionUtils.Fraction memory coefficient =
            _delegatedToValidator[validatorId].reduceValue(amount, currentMonth);

        uint initialEffectiveDelegated =
            _effectiveDelegatedToValidator[validatorId].getAndUpdateValueInSequence(currentMonth);
        uint[] memory initialSubtractions = new uint[](0);
        if (currentMonth < _effectiveDelegatedToValidator[validatorId].lastChangedMonth) {
            initialSubtractions = new uint[](
                _effectiveDelegatedToValidator[validatorId].lastChangedMonth - currentMonth
            );
            for (uint i = 0; i < initialSubtractions.length; ++i) {
                initialSubtractions[i] = _effectiveDelegatedToValidator[validatorId]
                    .subtractDiff[currentMonth + i + 1];
            }
        }

        _effectiveDelegatedToValidator[validatorId].reduceSequence(coefficient, currentMonth);
        _putToSlashingLog(_slashesOfValidator[validatorId], coefficient, currentMonth);
        _slashes.push(SlashingEvent({reducingCoefficient: coefficient, validatorId: validatorId, month: currentMonth}));

        IBountyV2 bounty = _getBounty();
        bounty.handleDelegationRemoving(
            initialEffectiveDelegated -
                _effectiveDelegatedToValidator[validatorId].getAndUpdateValueInSequence(currentMonth),
            currentMonth
        );
        for (uint i = 0; i < initialSubtractions.length; ++i) {
            bounty.handleDelegationAdd(
                initialSubtractions[i] -
                    _effectiveDelegatedToValidator[validatorId].subtractDiff[currentMonth + i + 1],
                currentMonth + i + 1
            );
        }
        emit Confiscated(validatorId, amount);
    }

    /**
     * @dev Allows Distributor contract to return and update the effective
     * amount delegated (minus slash) to a validator for a given month.
     */
    function getAndUpdateEffectiveDelegatedToValidator(uint validatorId, uint month)
        external
        override
        allowTwo("Bounty", "Distributor")
        returns (uint)
    {
        return _effectiveDelegatedToValidator[validatorId].getAndUpdateValueInSequence(month);
    }

    /**
     * @dev Return and update the amount delegated to a validator for the
     * current month.
     */
    function getAndUpdateDelegatedByHolderToValidatorNow(address holder, uint validatorId)
        external
        override
        returns (uint)
    {
        return _getAndUpdateDelegatedByHolderToValidator(holder, validatorId, _getCurrentMonth());
    }

    function getEffectiveDelegatedValuesByValidator(uint validatorId) external view override returns (uint[] memory) {
        return _effectiveDelegatedToValidator[validatorId].getValuesInSequence();
    }

    function getEffectiveDelegatedToValidator(uint validatorId, uint month) external view override returns (uint) {
        return _effectiveDelegatedToValidator[validatorId].getValueInSequence(month);
    }

    function getDelegatedToValidator(uint validatorId, uint month) external view override returns (uint) {
        return _delegatedToValidator[validatorId].getValue(month);
    }

    /**
     * @dev Return Delegation struct.
     */
    function getDelegation(uint delegationId)
        external
        view
        override
        checkDelegationExists(delegationId)
        returns (Delegation memory)
    {
        return delegations[delegationId];
    }

    /**
     * @dev Returns the first delegation month.
     */
    function getFirstDelegationMonth(address holder, uint validatorId) external view override returns(uint) {
        return _firstDelegationMonth[holder].byValidator[validatorId];
    }

    /**
     * @dev Returns a validator's total number of delegations.
     */
    function getDelegationsByValidatorLength(uint validatorId) external view override returns (uint) {
        return delegationsByValidator[validatorId].length;
    }

    /**
     * @dev Returns a holder's total number of delegations.
     */
    function getDelegationsByHolderLength(address holder) external view override returns (uint) {
        return delegationsByHolder[holder].length;
    }

    function initialize(address contractsAddress) public override initializer {
        Permissions.initialize(contractsAddress);
    }

    /**
     * @dev Process slashes up to the given limit.
     */
    function processSlashes(address holder, uint limit) public override {
        _sendSlashingSignals(_processSlashesWithoutSignals(holder, limit));
        emit SlashesProcessed(holder, limit);
    }

    /**
     * @dev Process all slashes.
     */
    function processAllSlashes(address holder) public override {
        processSlashes(holder, 0);
    }

    /**
     * @dev Returns the token state of a given delegation.
     */
    function getState(uint delegationId)
        public
        view
        override
        checkDelegationExists(delegationId)
        returns (State state)
    {
        if (delegations[delegationId].started == 0) {
            if (delegations[delegationId].finished == 0) {
                if (_getCurrentMonth() == _getTimeHelpers().timestampToMonth(delegations[delegationId].created)) {
                    return State.PROPOSED;
                } else {
                    return State.REJECTED;
                }
            } else {
                return State.CANCELED;
            }
        } else {
            if (_getCurrentMonth() < delegations[delegationId].started) {
                return State.ACCEPTED;
            } else {
                if (delegations[delegationId].finished == 0) {
                    return State.DELEGATED;
                } else {
                    if (_getCurrentMonth() < delegations[delegationId].finished) {
                        return State.UNDELEGATION_REQUESTED;
                    } else {
                        return State.COMPLETED;
                    }
                }
            }
        }
    }

    /**
     * @dev Returns the amount of tokens in PENDING delegation state.
     */
    function getLockedInPendingDelegations(address holder) public view override returns (uint) {
        uint currentMonth = _getCurrentMonth();
        if (_lockedInPendingDelegations[holder].month < currentMonth) {
            return 0;
        } else {
            return _lockedInPendingDelegations[holder].amount;
        }
    }

    /**
     * @dev Checks whether there are any unprocessed slashes.
     */
    function hasUnprocessedSlashes(address holder) public view override returns (bool) {
        return _everDelegated(holder) && _firstUnprocessedSlashByHolder[holder] < _slashes.length;
    }

    // private

    /**
     * @dev Allows Nodes contract to get and update the amount delegated
     * to validator for a given month.
     */
    function _getAndUpdateDelegatedToValidator(uint validatorId, uint month)
        private returns (uint)
    {
        return _delegatedToValidator[validatorId].getAndUpdateValue(month);
    }

    /**
     * @dev Adds a new delegation proposal.
     */
    function _addDelegation(
        address holder,
        uint validatorId,
        uint amount,
        uint delegationPeriod,
        string memory info
    )
        private
        returns (uint delegationId)
    {
        delegationId = delegations.length;
        delegations.push(Delegation(
            holder,
            validatorId,
            amount,
            delegationPeriod,
            block.timestamp,
            0,
            0,
            info
        ));
        delegationsByValidator[validatorId].push(delegationId);
        delegationsByHolder[holder].push(delegationId);
        _addToLockedInPendingDelegations(delegations[delegationId].holder, delegations[delegationId].amount);
    }

    function _addToDelegatedToValidator(uint validatorId, uint amount, uint month) private {
        _delegatedToValidator[validatorId].addToValue(amount, month);
    }

    function _addToEffectiveDelegatedToValidator(uint validatorId, uint effectiveAmount, uint month) private {
        _effectiveDelegatedToValidator[validatorId].addToSequence(effectiveAmount, month);
    }

    function _addToDelegatedByHolder(address holder, uint amount, uint month) private {
        _delegatedByHolder[holder].addToValue(amount, month);
    }

    function _addToDelegatedByHolderToValidator(
        address holder, uint validatorId, uint amount, uint month) private
    {
        _delegatedByHolderToValidator[holder][validatorId].addToValue(amount, month);
    }

    function _addValidatorToValidatorsPerDelegators(address holder, uint validatorId) private {
        if (_numberOfValidatorsPerDelegator[holder].delegated[validatorId] == 0) {
            _numberOfValidatorsPerDelegator[holder].number += 1;
        }
        _numberOfValidatorsPerDelegator[holder].delegated[validatorId] += 1;
    }

    function _removeFromDelegatedByHolder(address holder, uint amount, uint month) private {
        _delegatedByHolder[holder].subtractFromValue(amount, month);
    }

    function _removeFromDelegatedByHolderToValidator(
        address holder, uint validatorId, uint amount, uint month) private
    {
        _delegatedByHolderToValidator[holder][validatorId].subtractFromValue(amount, month);
    }

    function _removeValidatorFromValidatorsPerDelegators(address holder, uint validatorId) private {
        if (_numberOfValidatorsPerDelegator[holder].delegated[validatorId] == 1) {
            _numberOfValidatorsPerDelegator[holder].number -= 1;
        }
        _numberOfValidatorsPerDelegator[holder].delegated[validatorId] -= 1;
    }

    function _addToEffectiveDelegatedByHolderToValidator(
        address holder,
        uint validatorId,
        uint effectiveAmount,
        uint month)
        private
    {
        _effectiveDelegatedByHolderToValidator[holder][validatorId].addToSequence(effectiveAmount, month);
    }

    function _removeFromEffectiveDelegatedByHolderToValidator(
        address holder,
        uint validatorId,
        uint effectiveAmount,
        uint month)
        private
    {
        _effectiveDelegatedByHolderToValidator[holder][validatorId].subtractFromSequence(effectiveAmount, month);
    }

    function _getAndUpdateDelegatedByHolder(address holder) private returns (uint) {
        uint currentMonth = _getCurrentMonth();
        processAllSlashes(holder);
        return _delegatedByHolder[holder].getAndUpdateValue(currentMonth);
    }

    function _getAndUpdateDelegatedByHolderToValidator(
        address holder,
        uint validatorId,
        uint month)
        private returns (uint)
    {
        return _delegatedByHolderToValidator[holder][validatorId].getAndUpdateValue(month);
    }

    function _addToLockedInPendingDelegations(address holder, uint amount) private {
        uint currentMonth = _getCurrentMonth();
        if (_lockedInPendingDelegations[holder].month < currentMonth) {
            _lockedInPendingDelegations[holder].amount = amount;
            _lockedInPendingDelegations[holder].month = currentMonth;
        } else {
            assert(_lockedInPendingDelegations[holder].month == currentMonth);
            _lockedInPendingDelegations[holder].amount = _lockedInPendingDelegations[holder].amount + amount;
        }
    }

    function _subtractFromLockedInPendingDelegations(address holder, uint amount) private {
        uint currentMonth = _getCurrentMonth();
        assert(_lockedInPendingDelegations[holder].month == currentMonth);
        _lockedInPendingDelegations[holder].amount = _lockedInPendingDelegations[holder].amount - amount;
    }

    /**
     * @dev See {ILocker-getAndUpdateLockedAmount}.
     */
    function _getAndUpdateLockedAmount(address wallet) private returns (uint) {
        return _getAndUpdateDelegatedByHolder(wallet) + getLockedInPendingDelegations(wallet);
    }

    function _updateFirstDelegationMonth(address holder, uint validatorId, uint month) private {
        if (_firstDelegationMonth[holder].value == 0) {
            _firstDelegationMonth[holder].value = month;
            _firstUnprocessedSlashByHolder[holder] = _slashes.length;
        }
        if (_firstDelegationMonth[holder].byValidator[validatorId] == 0) {
            _firstDelegationMonth[holder].byValidator[validatorId] = month;
        }
    }

    function _removeFromDelegatedToValidator(uint validatorId, uint amount, uint month) private {
        _delegatedToValidator[validatorId].subtractFromValue(amount, month);
    }

    function _removeFromEffectiveDelegatedToValidator(uint validatorId, uint effectiveAmount, uint month) private {
        _effectiveDelegatedToValidator[validatorId].subtractFromSequence(effectiveAmount, month);
    }

    function _putToSlashingLog(
        SlashingLog storage log,
        FractionUtils.Fraction memory coefficient,
        uint month)
        private
    {
        if (log.firstMonth == 0) {
            log.firstMonth = month;
            log.lastMonth = month;
            log.slashes[month].reducingCoefficient = coefficient;
            log.slashes[month].nextMonth = 0;
        } else {
            require(log.lastMonth <= month, "Cannot put slashing event in the past");
            if (log.lastMonth == month) {
                log.slashes[month].reducingCoefficient =
                    log.slashes[month].reducingCoefficient.multiplyFraction(coefficient);
            } else {
                log.slashes[month].reducingCoefficient = coefficient;
                log.slashes[month].nextMonth = 0;
                log.slashes[log.lastMonth].nextMonth = month;
                log.lastMonth = month;
            }
        }
    }

    function _processSlashesWithoutSignals(address holder, uint limit)
        private returns (SlashingSignal[] memory slashingSignals)
    {
        if (hasUnprocessedSlashes(holder)) {
            uint index = _firstUnprocessedSlashByHolder[holder];
            uint end = _slashes.length;
            if (limit > 0 && (index + limit) < end) {
                end = index + limit;
            }
            slashingSignals = new SlashingSignal[](end - index);
            uint begin = index;
            for (; index < end; ++index) {
                uint validatorId = _slashes[index].validatorId;
                uint month = _slashes[index].month;
                uint oldValue = _getAndUpdateDelegatedByHolderToValidator(holder, validatorId, month);
                if (oldValue.muchGreater(0)) {
                    _delegatedByHolderToValidator[holder][validatorId].reduceValueByCoefficientAndUpdateSum(
                        _delegatedByHolder[holder],
                        _slashes[index].reducingCoefficient,
                        month);
                    _effectiveDelegatedByHolderToValidator[holder][validatorId].reduceSequence(
                        _slashes[index].reducingCoefficient,
                        month);
                    slashingSignals[index - begin].holder = holder;
                    slashingSignals[index - begin].penalty
                        = oldValue.boundedSub(_getAndUpdateDelegatedByHolderToValidator(holder, validatorId, month));
                }
            }
            _firstUnprocessedSlashByHolder[holder] = end;
        }
    }

    function _processAllSlashesWithoutSignals(address holder)
        private returns (SlashingSignal[] memory slashingSignals)
    {
        return _processSlashesWithoutSignals(holder, 0);
    }

    function _sendSlashingSignals(SlashingSignal[] memory slashingSignals) private {
        IPunisher punisher = IPunisher(contractManager.getPunisher());
        address previousHolder = address(0);
        uint accumulatedPenalty = 0;
        for (uint i = 0; i < slashingSignals.length; ++i) {
            if (slashingSignals[i].holder != previousHolder) {
                if (accumulatedPenalty > 0) {
                    punisher.handleSlash(previousHolder, accumulatedPenalty);
                }
                previousHolder = slashingSignals[i].holder;
                accumulatedPenalty = slashingSignals[i].penalty;
            } else {
                accumulatedPenalty = accumulatedPenalty + slashingSignals[i].penalty;
            }
        }
        if (accumulatedPenalty > 0) {
            punisher.handleSlash(previousHolder, accumulatedPenalty);
        }
    }

    function _addToAllStatistics(uint delegationId) private {
        uint currentMonth = _getCurrentMonth();
        delegations[delegationId].started = currentMonth + 1;
        if (_slashesOfValidator[delegations[delegationId].validatorId].lastMonth > 0) {
            _delegationExtras[delegationId].lastSlashingMonthBeforeDelegation =
                _slashesOfValidator[delegations[delegationId].validatorId].lastMonth;
        }

        _addToDelegatedToValidator(
            delegations[delegationId].validatorId,
            delegations[delegationId].amount,
            currentMonth + 1);
        _addToDelegatedByHolder(
            delegations[delegationId].holder,
            delegations[delegationId].amount,
            currentMonth + 1);
        _addToDelegatedByHolderToValidator(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId,
            delegations[delegationId].amount,
            currentMonth + 1);
        _updateFirstDelegationMonth(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId,
            currentMonth + 1);
        uint effectiveAmount = delegations[delegationId].amount *
            _getDelegationPeriodManager().stakeMultipliers(delegations[delegationId].delegationPeriod);
        _addToEffectiveDelegatedToValidator(
            delegations[delegationId].validatorId,
            effectiveAmount,
            currentMonth + 1);
        _addToEffectiveDelegatedByHolderToValidator(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId,
            effectiveAmount,
            currentMonth + 1);
        _addValidatorToValidatorsPerDelegators(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId
        );
    }

    function _subtractFromAllStatistics(uint delegationId) private {
        uint amountAfterSlashing = _calculateDelegationAmountAfterSlashing(delegationId);
        _removeFromDelegatedToValidator(
            delegations[delegationId].validatorId,
            amountAfterSlashing,
            delegations[delegationId].finished);
        _removeFromDelegatedByHolder(
            delegations[delegationId].holder,
            amountAfterSlashing,
            delegations[delegationId].finished);
        _removeFromDelegatedByHolderToValidator(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId,
            amountAfterSlashing,
            delegations[delegationId].finished);
        uint effectiveAmount = amountAfterSlashing *
                _getDelegationPeriodManager().stakeMultipliers(delegations[delegationId].delegationPeriod);
        _removeFromEffectiveDelegatedToValidator(
            delegations[delegationId].validatorId,
            effectiveAmount,
            delegations[delegationId].finished);
        _removeFromEffectiveDelegatedByHolderToValidator(
            delegations[delegationId].holder,
            delegations[delegationId].validatorId,
            effectiveAmount,
            delegations[delegationId].finished);
        _getBounty().handleDelegationRemoving(
            effectiveAmount,
            delegations[delegationId].finished);
    }

    function _accept(uint delegationId) private {
        _checkIfDelegationIsAllowed(delegations[delegationId].holder, delegations[delegationId].validatorId);

        State currentState = getState(delegationId);
        if (currentState != State.PROPOSED) {
            if (currentState == State.ACCEPTED ||
                currentState == State.DELEGATED ||
                currentState == State.UNDELEGATION_REQUESTED ||
                currentState == State.COMPLETED)
            {
                revert("The delegation has been already accepted");
            } else if (currentState == State.CANCELED) {
                revert("The delegation has been cancelled by token holder");
            } else if (currentState == State.REJECTED) {
                revert("The delegation request is outdated");
            }
        }
        require(currentState == State.PROPOSED, "Cannot set delegation state to accepted");

        SlashingSignal[] memory slashingSignals = _processAllSlashesWithoutSignals(delegations[delegationId].holder);

        _addToAllStatistics(delegationId);

        uint amount = delegations[delegationId].amount;

        uint effectiveAmount = amount *
            _getDelegationPeriodManager().stakeMultipliers(delegations[delegationId].delegationPeriod);
        _getBounty().handleDelegationAdd(
            effectiveAmount,
            delegations[delegationId].started
        );

        _sendSlashingSignals(slashingSignals);
        emit DelegationAccepted(delegationId);
    }

    function _getCurrentMonth() private view returns (uint) {
        return _getTimeHelpers().getCurrentMonth();
    }

    /**
     * @dev Checks whether the holder has performed a delegation.
     */
    function _everDelegated(address holder) private view returns (bool) {
        return _firstDelegationMonth[holder].value > 0;
    }

    /**
     * @dev Returns the month when a delegation ends.
     */
    function _calculateDelegationEndMonth(uint delegationId) private view returns (uint) {
        uint currentMonth = _getCurrentMonth();
        uint started = delegations[delegationId].started;

        if (currentMonth < started) {
            return started + delegations[delegationId].delegationPeriod;
        } else {
            uint completedPeriods = (currentMonth - started) / delegations[delegationId].delegationPeriod;
            return started + (completedPeriods + 1) * delegations[delegationId].delegationPeriod;
        }
    }

    /**
     * @dev Returns the delegated amount after a slashing event.
     */
    function _calculateDelegationAmountAfterSlashing(uint delegationId) private view returns (uint) {
        uint startMonth = _delegationExtras[delegationId].lastSlashingMonthBeforeDelegation;
        uint validatorId = delegations[delegationId].validatorId;
        uint amount = delegations[delegationId].amount;
        if (startMonth == 0) {
            startMonth = _slashesOfValidator[validatorId].firstMonth;
            if (startMonth == 0) {
                return amount;
            }
        }
        for (uint i = startMonth;
            i > 0 && i < delegations[delegationId].finished;
            i = _slashesOfValidator[validatorId].slashes[i].nextMonth) {
            if (i >= delegations[delegationId].started) {
                amount = amount
                    * _slashesOfValidator[validatorId].slashes[i].reducingCoefficient.numerator
                    / _slashesOfValidator[validatorId].slashes[i].reducingCoefficient.denominator;
            }
        }
        return amount;
    }

    /**
     * @dev Checks whether delegation to a validator is allowed.
     *
     * Requirements:
     *
     * - Delegator must not have reached the validator limit.
     * - Delegation must be made in or after the first delegation month.
     */
    function _checkIfDelegationIsAllowed(address holder, uint validatorId) private view {
        require(
            _numberOfValidatorsPerDelegator[holder].delegated[validatorId] > 0 ||
                _numberOfValidatorsPerDelegator[holder].number < _getConstantsHolder().limitValidatorsPerDelegator(),
            "Limit of validators is reached"
        );
    }

    function _getDelegationPeriodManager() private view returns (IDelegationPeriodManager) {
        return IDelegationPeriodManager(contractManager.getDelegationPeriodManager());
    }

    function _getBounty() private view returns (IBountyV2) {
        return IBountyV2(contractManager.getBounty());
    }

    function _getValidatorService() private view returns (IValidatorService) {
        return IValidatorService(contractManager.getValidatorService());
    }

    function _getTimeHelpers() private view returns (ITimeHelpers) {
        return ITimeHelpers(contractManager.getTimeHelpers());
    }

    function _getConstantsHolder() private view returns (IConstantsHolder) {
        return IConstantsHolder(contractManager.getConstantsHolder());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IDelegationController.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IDelegationController {
    enum State {
        PROPOSED,
        ACCEPTED,
        CANCELED,
        REJECTED,
        DELEGATED,
        UNDELEGATION_REQUESTED,
        COMPLETED
    }

    struct Delegation {
        address holder; // address of token owner
        uint validatorId;
        uint amount;
        uint delegationPeriod;
        uint created; // time of delegation creation
        uint started; // month when a delegation becomes active
        uint finished; // first month after a delegation ends
        string info;
    }

    /**
     * @dev Emitted when validator was confiscated.
     */
    event Confiscated(
        uint indexed validatorId,
        uint amount
    );

    /**
     * @dev Emitted when validator was confiscated.
     */
    event SlashesProcessed(
        address indexed holder,
        uint limit
    );

    /**
     * @dev Emitted when a delegation is proposed to a validator.
     */
    event DelegationProposed(
        uint delegationId
    );

    /**
     * @dev Emitted when a delegation is accepted by a validator.
     */
    event DelegationAccepted(
        uint delegationId
    );

    /**
     * @dev Emitted when a delegation is cancelled by the delegator.
     */
    event DelegationRequestCanceledByUser(
        uint delegationId
    );

    /**
     * @dev Emitted when a delegation is requested to undelegate.
     */
    event UndelegationRequested(
        uint delegationId
    );
    
    function getAndUpdateDelegatedToValidatorNow(uint validatorId) external returns (uint);
    function getAndUpdateDelegatedAmount(address holder) external returns (uint);
    function getAndUpdateEffectiveDelegatedByHolderToValidator(address holder, uint validatorId, uint month)
        external
        returns (uint effectiveDelegated);
    function delegate(
        uint validatorId,
        uint amount,
        uint delegationPeriod,
        string calldata info
    )
        external;
    function cancelPendingDelegation(uint delegationId) external;
    function acceptPendingDelegation(uint delegationId) external;
    function requestUndelegation(uint delegationId) external;
    function confiscate(uint validatorId, uint amount) external;
    function getAndUpdateEffectiveDelegatedToValidator(uint validatorId, uint month) external returns (uint);
    function getAndUpdateDelegatedByHolderToValidatorNow(address holder, uint validatorId) external returns (uint);
    function processSlashes(address holder, uint limit) external;
    function processAllSlashes(address holder) external;
    function getEffectiveDelegatedValuesByValidator(uint validatorId) external view returns (uint[] memory);
    function getEffectiveDelegatedToValidator(uint validatorId, uint month) external view returns (uint);
    function getDelegatedToValidator(uint validatorId, uint month) external view returns (uint);
    function getDelegation(uint delegationId) external view returns (Delegation memory);
    function getFirstDelegationMonth(address holder, uint validatorId) external view returns(uint);
    function getDelegationsByValidatorLength(uint validatorId) external view returns (uint);
    function getDelegationsByHolderLength(address holder) external view returns (uint);
    function getState(uint delegationId) external view returns (State state);
    function getLockedInPendingDelegations(address holder) external view returns (uint);
    function hasUnprocessedSlashes(address holder) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IDelegationPeriodManager.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IDelegationPeriodManager {
    /**
     * @dev Emitted when a new delegation period is specified.
     */
    event DelegationPeriodWasSet(
        uint length,
        uint stakeMultiplier
    );
    
    function setDelegationPeriod(uint monthsCount, uint stakeMultiplier) external;
    function stakeMultipliers(uint monthsCount) external view returns (uint);
    function isDelegationPeriodAllowed(uint monthsCount) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IPunisher.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IPunisher {
    /**
     * @dev Emitted upon slashing condition.
     */
    event Slash(
        uint validatorId,
        uint amount
    );

    /**
     * @dev Emitted upon forgive condition.
     */
    event Forgive(
        address wallet,
        uint amount
    );
    
    function slash(uint validatorId, uint amount) external;
    function forgive(address holder, uint amount) external;
    function handleSlash(address holder, uint amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ITokenState.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ITokenState {
    /**
     * @dev Emitted when a contract is added to the locker.
     */
    event LockerWasAdded(
        string locker
    );

    /**
     * @dev Emitted when a contract is removed from the locker.
     */
    event LockerWasRemoved(
        string locker
    );
    
    function removeLocker(string calldata locker) external;
    function addLocker(string memory locker) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IValidatorService.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IValidatorService {
    struct Validator {
        string name;
        address validatorAddress;
        address requestedAddress;
        string description;
        uint feeRate;
        uint registrationTime;
        uint minimumDelegationAmount;
        bool acceptNewRequests;
    }
    
    /**
     * @dev Emitted when a validator registers.
     */
    event ValidatorRegistered(
        uint validatorId
    );

    /**
     * @dev Emitted when a validator address changes.
     */
    event ValidatorAddressChanged(
        uint validatorId,
        address newAddress
    );

    /**
     * @dev Emitted when a validator is enabled.
     */
    event ValidatorWasEnabled(
        uint validatorId
    );

    /**
     * @dev Emitted when a validator is disabled.
     */
    event ValidatorWasDisabled(
        uint validatorId
    );

    /**
     * @dev Emitted when a node address is linked to a validator.
     */
    event NodeAddressWasAdded(
        uint validatorId,
        address nodeAddress
    );

    /**
     * @dev Emitted when a node address is unlinked from a validator.
     */
    event NodeAddressWasRemoved(
        uint validatorId,
        address nodeAddress
    );

    /**
     * @dev Emitted when whitelist disabled.
     */
    event WhitelistDisabled(bool status);

    /**
     * @dev Emitted when validator requested new address.
     */
    event RequestNewAddress(uint indexed validatorId, address previousAddress, address newAddress);

    /**
     * @dev Emitted when validator set new minimum delegation amount.
     */
    event SetMinimumDelegationAmount(uint indexed validatorId, uint previousMDA, uint newMDA);

    /**
     * @dev Emitted when validator set new name.
     */
    event SetValidatorName(uint indexed validatorId, string previousName, string newName);

    /**
     * @dev Emitted when validator set new description.
     */
    event SetValidatorDescription(uint indexed validatorId, string previousDescription, string newDescription);

    /**
     * @dev Emitted when validator start or stop accepting new delegation requests.
     */
    event AcceptingNewRequests(uint indexed validatorId, bool status);
    
    function registerValidator(
        string calldata name,
        string calldata description,
        uint feeRate,
        uint minimumDelegationAmount
    )
        external
        returns (uint validatorId);
    function enableValidator(uint validatorId) external;
    function disableValidator(uint validatorId) external;
    function disableWhitelist() external;
    function requestForNewAddress(address newValidatorAddress) external;
    function confirmNewAddress(uint validatorId) external;
    function linkNodeAddress(address nodeAddress, bytes calldata sig) external;
    function unlinkNodeAddress(address nodeAddress) external;
    function setValidatorMDA(uint minimumDelegationAmount) external;
    function setValidatorName(string calldata newName) external;
    function setValidatorDescription(string calldata newDescription) external;
    function startAcceptingNewRequests() external;
    function stopAcceptingNewRequests() external;
    function removeNodeAddress(uint validatorId, address nodeAddress) external;
    function getAndUpdateBondAmount(uint validatorId) external returns (uint);
    function getMyNodesAddresses() external view returns (address[] memory);
    function getTrustedValidators() external view returns (uint[] memory);
    function checkValidatorAddressToId(address validatorAddress, uint validatorId)
        external
        view
        returns (bool);
    function getValidatorIdByNodeAddress(address nodeAddress) external view returns (uint validatorId);
    function checkValidatorCanReceiveDelegation(uint validatorId, uint amount) external view;
    function getNodeAddresses(uint validatorId) external view returns (address[] memory);
    function validatorExists(uint validatorId) external view returns (bool);
    function validatorAddressExists(address validatorAddress) external view returns (bool);
    function checkIfValidatorAddressExists(address validatorAddress) external view;
    function getValidator(uint validatorId) external view returns (Validator memory);
    function getValidatorId(address validatorAddress) external view returns (uint);
    function isAcceptingNewRequests(uint validatorId) external view returns (bool);
    function isAuthorizedValidator(uint validatorId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ILocker.sol - SKALE Manager
    Copyright (C) 2019-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

/**
 * @dev Interface of the Locker functions.
 */
interface ILocker {
    /**
     * @dev Returns and updates the total amount of locked tokens of a given 
     * `holder`.
     */
    function getAndUpdateLockedAmount(address wallet) external returns (uint);

    /**
     * @dev Returns and updates the total non-transferrable and un-delegatable
     * amount of a given `holder`.
     */
    function getAndUpdateForbiddenForDelegationAmount(address wallet) external returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    ITimeHelpers.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface ITimeHelpers {
    function calculateProofOfUseLockEndTime(uint month, uint lockUpPeriodDays) external view returns (uint timestamp);
    function getCurrentMonth() external view returns (uint);
    function timestampToYear(uint timestamp) external view returns (uint);
    function timestampToMonth(uint timestamp) external view returns (uint);
    function monthToTimestamp(uint month) external view returns (uint timestamp);
    function addDays(uint fromTimestamp, uint n) external pure returns (uint);
    function addMonths(uint fromTimestamp, uint n) external pure returns (uint);
    function addYears(uint fromTimestamp, uint n) external pure returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IBountyV2.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IBountyV2 {

    /**
     * @dev Emitted when bounty reduction is turned on or turned off.
     */
    event BountyReduction(bool status);
    /**
     * @dev Emitted when a node creation window was changed.
     */
    event NodeCreationWindowWasChanged(
        uint oldValue,
        uint newValue
    );

    function calculateBounty(uint nodeIndex) external returns (uint);
    function enableBountyReduction() external;
    function disableBountyReduction() external;
    function setNodeCreationWindowSeconds(uint window) external;
    function handleDelegationAdd(uint amount, uint month) external;
    function handleDelegationRemoving(uint amount, uint month) external;
    function estimateBounty(uint nodeIndex) external view returns (uint);
    function getNextRewardTimestamp(uint nodeIndex) external view returns (uint);
    function getEffectiveDelegatedSum() external view returns (uint[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    INodes.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

import "./utils/IRandom.sol";

interface INodes {
    // All Nodes states
    enum NodeStatus {Active, Leaving, Left, In_Maintenance}

    struct Node {
        string name;
        bytes4 ip;
        bytes4 publicIP;
        uint16 port;
        bytes32[2] publicKey;
        uint startBlock;
        uint lastRewardDate;
        uint finishTime;
        NodeStatus status;
        uint validatorId;
    }

    // struct to note which Nodes and which number of Nodes owned by user
    struct CreatedNodes {
        mapping (uint => bool) isNodeExist;
        uint numberOfNodes;
    }

    struct SpaceManaging {
        uint8 freeSpace;
        uint indexInSpaceMap;
    }

    struct NodeCreationParams {
        string name;
        bytes4 ip;
        bytes4 publicIp;
        uint16 port;
        bytes32[2] publicKey;
        uint16 nonce;
        string domainName;
    }
    
    /**
     * @dev Emitted when a node is created.
     */
    event NodeCreated(
        uint nodeIndex,
        address owner,
        string name,
        bytes4 ip,
        bytes4 publicIP,
        uint16 port,
        uint16 nonce,
        string domainName
    );

    /**
     * @dev Emitted when a node completes a network exit.
     */
    event ExitCompleted(
        uint nodeIndex
    );

    /**
     * @dev Emitted when a node begins to exit from the network.
     */
    event ExitInitialized(
        uint nodeIndex,
        uint startLeavingPeriod
    );

    /**
     * @dev Emitted when a node set to in compliant or compliant.
     */
    event IncompliantNode(
        uint indexed nodeIndex,
        bool status
    );

    /**
     * @dev Emitted when a node set to in maintenance or from in maintenance.
     */
    event MaintenanceNode(
        uint indexed nodeIndex,
        bool status
    );

    /**
     * @dev Emitted when a node status changed.
     */
    event IPChanged(
        uint indexed nodeIndex,
        bytes4 previousIP,
        bytes4 newIP
    );
    
    function removeSpaceFromNode(uint nodeIndex, uint8 space) external returns (bool);
    function addSpaceToNode(uint nodeIndex, uint8 space) external;
    function changeNodeLastRewardDate(uint nodeIndex) external;
    function changeNodeFinishTime(uint nodeIndex, uint time) external;
    function createNode(address from, NodeCreationParams calldata params) external;
    function initExit(uint nodeIndex) external;
    function completeExit(uint nodeIndex) external returns (bool);
    function deleteNodeForValidator(uint validatorId, uint nodeIndex) external;
    function checkPossibilityCreatingNode(address nodeAddress) external;
    function checkPossibilityToMaintainNode(uint validatorId, uint nodeIndex) external returns (bool);
    function setNodeInMaintenance(uint nodeIndex) external;
    function removeNodeFromInMaintenance(uint nodeIndex) external;
    function setNodeIncompliant(uint nodeIndex) external;
    function setNodeCompliant(uint nodeIndex) external;
    function setDomainName(uint nodeIndex, string memory domainName) external;
    function makeNodeVisible(uint nodeIndex) external;
    function makeNodeInvisible(uint nodeIndex) external;
    function changeIP(uint nodeIndex, bytes4 newIP, bytes4 newPublicIP) external;
    function numberOfActiveNodes() external view returns (uint);
    function incompliant(uint nodeIndex) external view returns (bool);
    function getRandomNodeWithFreeSpace(
        uint8 freeSpace,
        IRandom.RandomGenerator memory randomGenerator
    )
        external
        view
        returns (uint);
    function isTimeForReward(uint nodeIndex) external view returns (bool);
    function getNodeIP(uint nodeIndex) external view returns (bytes4);
    function getNodeDomainName(uint nodeIndex) external view returns (string memory);
    function getNodePort(uint nodeIndex) external view returns (uint16);
    function getNodePublicKey(uint nodeIndex) external view returns (bytes32[2] memory);
    function getNodeAddress(uint nodeIndex) external view returns (address);
    function getNodeFinishTime(uint nodeIndex) external view returns (uint);
    function isNodeLeft(uint nodeIndex) external view returns (bool);
    function isNodeInMaintenance(uint nodeIndex) external view returns (bool);
    function getNodeLastRewardDate(uint nodeIndex) external view returns (uint);
    function getNodeNextRewardDate(uint nodeIndex) external view returns (uint);
    function getNumberOfNodes() external view returns (uint);
    function getNumberOnlineNodes() external view returns (uint);
    function getActiveNodeIds() external view returns (uint[] memory activeNodeIds);
    function getNodeStatus(uint nodeIndex) external view returns (NodeStatus);
    function getValidatorNodeIndexes(uint validatorId) external view returns (uint[] memory);
    function countNodesWithFreeSpace(uint8 freeSpace) external view returns (uint count);
    function getValidatorId(uint nodeIndex) external view returns (uint);
    function isNodeExist(address from, uint nodeIndex) external view returns (bool);
    function isNodeActive(uint nodeIndex) external view returns (bool);
    function isNodeLeaving(uint nodeIndex) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IConstantsHolder.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IConstantsHolder {

    /**
     * @dev Emitted when constants updated.
     */
    event ConstantUpdated(
        bytes32 indexed constantHash,
        uint previousValue,
        uint newValue
    );

    function setPeriods(uint32 newRewardPeriod, uint32 newDeltaPeriod) external;
    function setCheckTime(uint newCheckTime) external;
    function setLatency(uint32 newAllowableLatency) external;
    function setMSR(uint newMSR) external;
    function setLaunchTimestamp(uint timestamp) external;
    function setRotationDelay(uint newDelay) external;
    function setProofOfUseLockUpPeriod(uint periodDays) external;
    function setProofOfUseDelegationPercentage(uint percentage) external;
    function setLimitValidatorsPerDelegator(uint newLimit) external;
    function setSchainCreationTimeStamp(uint timestamp) external;
    function setMinimalSchainLifetime(uint lifetime) external;
    function setComplaintTimeLimit(uint timeLimit) external;
    function setMinNodeBalance(uint newMinNodeBalance) external;
    function reinitialize() external;
    function msr() external view returns (uint);
    function launchTimestamp() external view returns (uint);
    function rotationDelay() external view returns (uint);
    function limitValidatorsPerDelegator() external view returns (uint);
    function schainCreationTimeStamp() external view returns (uint);
    function minimalSchainLifetime() external view returns (uint);
    function complaintTimeLimit() external view returns (uint);
    function minNodeBalance() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    Permissions.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "@skalenetwork/skale-manager-interfaces/IContractManager.sol";
import "@skalenetwork/skale-manager-interfaces/IPermissions.sol";

import "./thirdparty/openzeppelin/AccessControlUpgradeableLegacy.sol";


/**
 * @title Permissions
 * @dev Contract is connected module for Upgradeable approach, knows ContractManager
 */
contract Permissions is AccessControlUpgradeableLegacy, IPermissions {
    using AddressUpgradeable for address;

    IContractManager public contractManager;

    /**
     * @dev Modifier to make a function callable only when caller is the Owner.
     *
     * Requirements:
     *
     * - The caller must be the owner.
     */
    modifier onlyOwner() {
        require(_isOwner(), "Caller is not the owner");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is an Admin.
     *
     * Requirements:
     *
     * - The caller must be an admin.
     */
    modifier onlyAdmin() {
        require(_isAdmin(msg.sender), "Caller is not an admin");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is the Owner
     * or `contractName` contract.
     *
     * Requirements:
     *
     * - The caller must be the owner or `contractName`.
     */
    modifier allow(string memory contractName) {
        require(
            contractManager.getContract(contractName) == msg.sender || _isOwner(),
            "Message sender is invalid");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is the Owner
     * or `contractName1` or `contractName2` contract.
     *
     * Requirements:
     *
     * - The caller must be the owner, `contractName1`, or `contractName2`.
     */
    modifier allowTwo(string memory contractName1, string memory contractName2) {
        require(
            contractManager.getContract(contractName1) == msg.sender ||
            contractManager.getContract(contractName2) == msg.sender ||
            _isOwner(),
            "Message sender is invalid");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when caller is the Owner
     * or `contractName1`, `contractName2`, or `contractName3` contract.
     *
     * Requirements:
     *
     * - The caller must be the owner, `contractName1`, `contractName2`, or
     * `contractName3`.
     */
    modifier allowThree(string memory contractName1, string memory contractName2, string memory contractName3) {
        require(
            contractManager.getContract(contractName1) == msg.sender ||
            contractManager.getContract(contractName2) == msg.sender ||
            contractManager.getContract(contractName3) == msg.sender ||
            _isOwner(),
            "Message sender is invalid");
        _;
    }

    function initialize(address contractManagerAddress) public virtual override initializer {
        AccessControlUpgradeableLegacy.__AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setContractManager(contractManagerAddress);
    }

    function _isOwner() internal view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _isAdmin(address account) internal view returns (bool) {
        address skaleManagerAddress = contractManager.contracts(keccak256(abi.encodePacked("SkaleManager")));
        if (skaleManagerAddress != address(0)) {
            AccessControlUpgradeableLegacy skaleManager = AccessControlUpgradeableLegacy(skaleManagerAddress);
            return skaleManager.hasRole(keccak256("ADMIN_ROLE"), account) || _isOwner();
        } else {
            return _isOwner();
        }
    }

    function _setContractManager(address contractManagerAddress) private {
        require(contractManagerAddress != address(0), "ContractManager address is not set");
        require(contractManagerAddress.isContract(), "Address is not contract");
        contractManager = IContractManager(contractManagerAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    FractionUtils.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;


library FractionUtils {

    struct Fraction {
        uint numerator;
        uint denominator;
    }

    function createFraction(uint numerator, uint denominator) internal pure returns (Fraction memory) {
        require(denominator > 0, "Division by zero");
        Fraction memory fraction = Fraction({numerator: numerator, denominator: denominator});
        reduceFraction(fraction);
        return fraction;
    }

    function createFraction(uint value) internal pure returns (Fraction memory) {
        return createFraction(value, 1);
    }

    function reduceFraction(Fraction memory fraction) internal pure {
        uint _gcd = gcd(fraction.numerator, fraction.denominator);
        fraction.numerator = fraction.numerator / _gcd;
        fraction.denominator = fraction.denominator / _gcd;
    }

    // numerator - is limited by 7*10^27, we could multiply it numerator * numerator - it would less than 2^256-1
    function multiplyFraction(Fraction memory a, Fraction memory b) internal pure returns (Fraction memory) {
        return createFraction(a.numerator * b.numerator, a.denominator * b.denominator);
    }

    function gcd(uint a, uint b) internal pure returns (uint) {
        uint _a = a;
        uint _b = b;
        if (_b > _a) {
            (_a, _b) = swap(_a, _b);
        }
        while (_b > 0) {
            _a = _a % _b;
            (_a, _b) = swap (_a, _b);
        }
        return _a;
    }

    function swap(uint a, uint b) internal pure returns (uint, uint) {
        return (b, a);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    MathUtils.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;


library MathUtils {

    uint constant private _EPS = 1e6;

    event UnderflowError(
        uint a,
        uint b
    );

    function boundedSub(uint256 a, uint256 b) internal returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            emit UnderflowError(a, b);
            return 0;
        }
    }

    function boundedSubWithoutEvent(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a >= b) {
            return a - b;
        } else {
            return 0;
        }
    }

    function muchGreater(uint256 a, uint256 b) internal pure returns (bool) {
        assert(type(uint).max - _EPS > b);
        return a > b + _EPS;
    }

    function approximatelyEqual(uint256 a, uint256 b) internal pure returns (bool) {
        if (a > b) {
            return a - b < _EPS;
        } else {
            return b - a < _EPS;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    PartialDifferences.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.8.17;

import "../utils/MathUtils.sol";
import "../utils/FractionUtils.sol";

/**
 * @title Partial Differences Library
 * @dev This library contains functions to manage Partial Differences data
 * structure. Partial Differences is an array of value differences over time.
 *
 * For example: assuming an array [3, 6, 3, 1, 2], partial differences can
 * represent this array as [_, 3, -3, -2, 1].
 *
 * This data structure allows adding values on an open interval with O(1)
 * complexity.
 *
 * For example: add +5 to [3, 6, 3, 1, 2] starting from the second element (3),
 * instead of performing [3, 6, 3+5, 1+5, 2+5] partial differences allows
 * performing [_, 3, -3+5, -2, 1]. The original array can be restored by
 * adding values from partial differences.
 */
library PartialDifferences {
    using MathUtils for uint;

    struct Sequence {
             // month => diff
        mapping (uint => uint) addDiff;
             // month => diff
        mapping (uint => uint) subtractDiff;
             // month => value
        mapping (uint => uint) value;

        uint firstUnprocessedMonth;
        uint lastChangedMonth;
    }

    struct Value {
             // month => diff
        mapping (uint => uint) addDiff;
             // month => diff
        mapping (uint => uint) subtractDiff;

        uint value;
        uint firstUnprocessedMonth;
        uint lastChangedMonth;
    }

    // functions for sequence

    function addToSequence(Sequence storage sequence, uint diff, uint month) internal {
        require(sequence.firstUnprocessedMonth <= month, "Cannot add to the past");
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
        }
        sequence.addDiff[month] = sequence.addDiff[month] + diff;
        if (sequence.lastChangedMonth != month) {
            sequence.lastChangedMonth = month;
        }
    }

    function subtractFromSequence(Sequence storage sequence, uint diff, uint month) internal {
        require(sequence.firstUnprocessedMonth <= month, "Cannot subtract from the past");
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
        }
        sequence.subtractDiff[month] = sequence.subtractDiff[month] + diff;
        if (sequence.lastChangedMonth != month) {
            sequence.lastChangedMonth = month;
        }
    }

    function getAndUpdateValueInSequence(Sequence storage sequence, uint month) internal returns (uint) {
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            for (uint i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                uint nextValue = (sequence.value[i - 1] + sequence.addDiff[i]).boundedSub(sequence.subtractDiff[i]);
                if (sequence.value[i] != nextValue) {
                    sequence.value[i] = nextValue;
                }
                if (sequence.addDiff[i] > 0) {
                    delete sequence.addDiff[i];
                }
                if (sequence.subtractDiff[i] > 0) {
                    delete sequence.subtractDiff[i];
                }
            }
            sequence.firstUnprocessedMonth = month + 1;
        }

        return sequence.value[month];
    }

    function reduceSequence(
        Sequence storage sequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint month) internal
    {
        require(month + 1 >= sequence.firstUnprocessedMonth, "Cannot reduce value in the past");
        require(
            reducingCoefficient.numerator <= reducingCoefficient.denominator,
            "Increasing of values is not implemented");
        if (sequence.firstUnprocessedMonth == 0) {
            return;
        }
        uint value = getAndUpdateValueInSequence(sequence, month);
        if (value.approximatelyEqual(0)) {
            return;
        }

        sequence.value[month] = sequence.value[month]
            * reducingCoefficient.numerator
            / reducingCoefficient.denominator;

        for (uint i = month + 1; i <= sequence.lastChangedMonth; ++i) {
            sequence.subtractDiff[i] = sequence.subtractDiff[i]
                * reducingCoefficient.numerator
                / reducingCoefficient.denominator;
        }
    }

    // functions for value

    function addToValue(Value storage sequence, uint diff, uint month) internal {
        require(sequence.firstUnprocessedMonth <= month, "Cannot add to the past");
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
            sequence.lastChangedMonth = month;
        }
        if (month > sequence.lastChangedMonth) {
            sequence.lastChangedMonth = month;
        }

        if (month >= sequence.firstUnprocessedMonth) {
            sequence.addDiff[month] = sequence.addDiff[month] + diff;
        } else {
            sequence.value = sequence.value + diff;
        }
    }

    function subtractFromValue(Value storage sequence, uint diff, uint month) internal {
        require(sequence.firstUnprocessedMonth <= month + 1, "Cannot subtract from the past");
        if (sequence.firstUnprocessedMonth == 0) {
            sequence.firstUnprocessedMonth = month;
            sequence.lastChangedMonth = month;
        }
        if (month > sequence.lastChangedMonth) {
            sequence.lastChangedMonth = month;
        }

        if (month >= sequence.firstUnprocessedMonth) {
            sequence.subtractDiff[month] = sequence.subtractDiff[month] + diff;
        } else {
            sequence.value = sequence.value.boundedSub(diff);
        }
    }

    function getAndUpdateValue(Value storage sequence, uint month) internal returns (uint) {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot calculate value in the past");
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            uint value = sequence.value;
            for (uint i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                value = (value + sequence.addDiff[i]).boundedSub(sequence.subtractDiff[i]);
                if (sequence.addDiff[i] > 0) {
                    delete sequence.addDiff[i];
                }
                if (sequence.subtractDiff[i] > 0) {
                    delete sequence.subtractDiff[i];
                }
            }
            if (sequence.value != value) {
                sequence.value = value;
            }
            sequence.firstUnprocessedMonth = month + 1;
        }

        return sequence.value;
    }

    function reduceValue(
        Value storage sequence,
        uint amount,
        uint month)
        internal returns (FractionUtils.Fraction memory)
    {
        require(month + 1 >= sequence.firstUnprocessedMonth, "Cannot reduce value in the past");
        if (sequence.firstUnprocessedMonth == 0) {
            return FractionUtils.createFraction(0);
        }
        uint value = getAndUpdateValue(sequence, month);
        if (value.approximatelyEqual(0)) {
            return FractionUtils.createFraction(0);
        }

        uint _amount = amount;
        if (value < amount) {
            _amount = value;
        }

        FractionUtils.Fraction memory reducingCoefficient =
            FractionUtils.createFraction(value.boundedSub(_amount), value);
        reduceValueByCoefficient(sequence, reducingCoefficient, month);
        return reducingCoefficient;
    }

    function reduceValueByCoefficient(
        Value storage sequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint month)
        internal
    {
        reduceValueByCoefficientAndUpdateSumIfNeeded(
            sequence,
            sequence,
            reducingCoefficient,
            month,
            false);
    }

    function reduceValueByCoefficientAndUpdateSum(
        Value storage sequence,
        Value storage sumSequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint month) internal
    {
        reduceValueByCoefficientAndUpdateSumIfNeeded(
            sequence,
            sumSequence,
            reducingCoefficient,
            month,
            true);
    }

    function reduceValueByCoefficientAndUpdateSumIfNeeded(
        Value storage sequence,
        Value storage sumSequence,
        FractionUtils.Fraction memory reducingCoefficient,
        uint month,
        bool hasSumSequence) internal
    {
        require(month + 1 >= sequence.firstUnprocessedMonth, "Cannot reduce value in the past");
        if (hasSumSequence) {
            require(month + 1 >= sumSequence.firstUnprocessedMonth, "Cannot reduce value in the past");
        }
        require(
            reducingCoefficient.numerator <= reducingCoefficient.denominator,
            "Increasing of values is not implemented");
        if (sequence.firstUnprocessedMonth == 0) {
            return;
        }
        uint value = getAndUpdateValue(sequence, month);
        if (value.approximatelyEqual(0)) {
            return;
        }

        uint newValue = sequence.value * reducingCoefficient.numerator / reducingCoefficient.denominator;
        if (hasSumSequence) {
            subtractFromValue(sumSequence, sequence.value.boundedSub(newValue), month);
        }
        sequence.value = newValue;

        for (uint i = month + 1; i <= sequence.lastChangedMonth; ++i) {
            uint newDiff = sequence.subtractDiff[i]
                * reducingCoefficient.numerator
                / reducingCoefficient.denominator;
            if (hasSumSequence) {
                sumSequence.subtractDiff[i] = sumSequence.subtractDiff[i]
                    .boundedSub(sequence.subtractDiff[i].boundedSub(newDiff));
            }
            sequence.subtractDiff[i] = newDiff;
        }
    }

    function getValueInSequence(Sequence storage sequence, uint month) internal view returns (uint) {
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            uint value = sequence.value[sequence.firstUnprocessedMonth - 1];
            for (uint i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                value = value + sequence.addDiff[i] - sequence.subtractDiff[i];
            }
            return value;
        } else {
            return sequence.value[month];
        }
    }

    function getValuesInSequence(Sequence storage sequence) internal view returns (uint[] memory values) {
        if (sequence.firstUnprocessedMonth == 0) {
            return values;
        }
        uint begin = sequence.firstUnprocessedMonth - 1;
        uint end = sequence.lastChangedMonth + 1;
        if (end <= begin) {
            end = begin + 1;
        }
        values = new uint[](end - begin);
        values[0] = sequence.value[sequence.firstUnprocessedMonth - 1];
        for (uint i = 0; i + 1 < values.length; ++i) {
            uint month = sequence.firstUnprocessedMonth + i;
            values[i + 1] = values[i] + sequence.addDiff[month] - sequence.subtractDiff[month];
        }
    }

    function getValue(Value storage sequence, uint month) internal view returns (uint) {
        require(
            month + 1 >= sequence.firstUnprocessedMonth,
            "Cannot calculate value in the past");
        if (sequence.firstUnprocessedMonth == 0) {
            return 0;
        }

        if (sequence.firstUnprocessedMonth <= month) {
            uint value = sequence.value;
            for (uint i = sequence.firstUnprocessedMonth; i <= month; ++i) {
                value = value + sequence.addDiff[i] - sequence.subtractDiff[i];
            }
            return value;
        } else {
            return sequence.value;
        }
    }

    function getValues(Value storage sequence) internal view returns (uint[] memory values) {
        if (sequence.firstUnprocessedMonth == 0) {
            return values;
        }
        uint begin = sequence.firstUnprocessedMonth - 1;
        uint end = sequence.lastChangedMonth + 1;
        if (end <= begin) {
            end = begin + 1;
        }
        values = new uint[](end - begin);
        values[0] = sequence.value;
        for (uint i = 0; i + 1 < values.length; ++i) {
            uint month = sequence.firstUnprocessedMonth + i;
            values[i + 1] = values[i] + sequence.addDiff[month] - sequence.subtractDiff[month];
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IRandom.sol - SKALE Manager Interfaces
    Copyright (C) 2022-Present SKALE Labs
    @author Dmytro Stebaiev

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;


interface IRandom {
    struct RandomGenerator {
        uint seed;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IContractManager.sol - SKALE Manager Interfaces
    Copyright (C) 2021-Present SKALE Labs
    @author Dmytro Stebaeiv

    SKALE Manager Interfaces is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager Interfaces is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager Interfaces.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IContractManager {
    /**
     * @dev Emitted when contract is upgraded.
     */
    event ContractUpgraded(string contractsName, address contractsAddress);

    function initialize() external;
    function setContractsAddress(string calldata contractsName, address newContractsAddress) external;
    function contracts(bytes32 nameHash) external view returns (address);
    function getDelegationPeriodManager() external view returns (address);
    function getBounty() external view returns (address);
    function getValidatorService() external view returns (address);
    function getTimeHelpers() external view returns (address);
    function getConstantsHolder() external view returns (address);
    function getSkaleToken() external view returns (address);
    function getTokenState() external view returns (address);
    function getPunisher() external view returns (address);
    function getContract(string calldata name) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IPermissions.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IPermissions {
    function initialize(address contractManagerAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@skalenetwork/skale-manager-interfaces/thirdparty/openzeppelin/IAccessControlUpgradeableLegacy.sol";
import "./InitializableWithGap.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 */
abstract contract AccessControlUpgradeableLegacy is InitializableWithGap, ContextUpgradeable, IAccessControlUpgradeableLegacy {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {


    }

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

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
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

// SPDX-License-Identifier: AGPL-3.0-only

/*
    IAccessControlUpgradeableLegacy.sol - SKALE Manager
    Copyright (C) 2018-Present SKALE Labs
    @author Artem Payvin

    SKALE Manager is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Manager is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Manager.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.6.10 <0.9.0;

interface IAccessControlUpgradeableLegacy {
    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
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
    
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract InitializableWithGap is Initializable {
    uint256[50] private ______gap;
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