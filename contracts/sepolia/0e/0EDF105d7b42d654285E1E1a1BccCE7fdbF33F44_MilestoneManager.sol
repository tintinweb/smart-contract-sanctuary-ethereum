// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

// External Libraries
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";

// Internal Dependencies
import {Module, ContextUpgradeable} from "src/modules/base/Module.sol";
import {
    IPaymentClient,
    PaymentClient,
    IPaymentProcessor
} from "src/modules/mixins/PaymentClient.sol";

// Internal Interfaces
import {IMilestoneManager} from "src/modules/IMilestoneManager.sol";
import {IProposal} from "src/proposal/IProposal.sol";

// Internal Libraries
import {LinkedIdList} from "src/common/LinkedIdList.sol";

/**
 * @title MilestoneManager
 *
 * @dev Module to manage milestones for a proposal.
 *
 *      A milestone can exists in 4 different states:
 *        - added
 *              The milestone got added to the contract.
 *        - active
 *              When a milestone is started, it initias payment orders to pay
 *              the proposal's contributors.
 *              A milestone is active, until either its duration is over or it's
 *              marked as completed.
 *        - submitted
 *              A proposal contributor marks a milestone as submitted by
 *              submitting non-empty data that can be interpreted and evaluated
 *              by off-chain systems.
 *        - completed
 *              After a milestone was submitted, it can be marked as completed.
 *              This marks the end of the milestone.
 *
 * @author byterocket
 */
contract MilestoneManager is IMilestoneManager, Module, PaymentClient {
    using SafeERC20 for IERC20;
    using LinkedIdList for LinkedIdList.List;

    //--------------------------------------------------------------------------
    // Modifiers

    modifier onlyContributorOf(uint milestoneId) {
        if (!isContributor(milestoneId, _msgSender())) {
            revert Module__MilestoneManager__OnlyCallableByContributor();
        }
        _;
    }

    modifier validDuration(uint duration) {
        if (duration == 0) {
            revert Module__MilestoneManager__InvalidDuration();
        }
        _;
    }

    /// @dev this does not check if id is SENTINEL. This has to be checked seperately via validId()
    modifier validIntermediateMilestonePosition(
        uint id,
        uint idToPositionAfter
    ) {
        if (
            _milestoneRegistry[id].startTimestamp != 0 //Milestone hasnt started
                || (
                    _milestoneRegistry[_milestoneList.getNextId(idToPositionAfter)]
                        .startTimestamp != 0
                ) //If the following milestone already started you cant move or add a new milestone here, because it could never be started//@todo has to be put into other modifier
        ) {
            revert Module__MilestoneManager__InvalidIntermediatePosition();
        }
        _;
    }

    modifier validSubmissionData(bytes calldata submissionData) {
        if (submissionData.length == 0) {
            revert Module__MilestoneManage__InvalidSubmissionData();
        }
        _;
    }

    modifier validId(uint milestoneId) {
        if (!isExistingMilestoneId(milestoneId)) {
            revert Module__MilestoneManager__InvalidMilestoneId();
        }
        _;
    }

    modifier validContributors(Contributor[] calldata contribs) {
        uint contribLength = contribs.length;
        uint salaryPctSum;

        // Fail if contributors list is empty.
        if (contribLength == 0 || contribLength > MAXIMUM_CONTRIBUTORS) {
            revert Module__MilestoneManager__InvalidContributorAmount();
        }

        for (uint i; i < contribLength; ++i) {
            address contributorAddr = contribs[i].addr;
            uint contributorSalary = contribs[i].salary;

            // check the address is valid
            if (
                contributorAddr == address(0)
                    || contributorAddr == address(this)
                    || contributorAddr == address(proposal())
            ) {
                revert Module__MilestoneManager__InvalidContributorAddress();
            }

            // check the address is unique
            for (uint j = i + 1; j < contribLength; ++j) {
                if (contribs[j].addr == contributorAddr) {
                    revert Module__MilestoneManager__DuplicateContributorAddress(
                    );
                }
            }

            // check the salary (as budget percentage) is valid
            if (contributorSalary == 0 || contributorSalary > SALARY_PRECISION)
            {
                revert Module__MilestoneManager__InvalidContributorSalary();
            }

            salaryPctSum += contributorSalary;
        }

        //check salary percentages add up to total
        if (salaryPctSum != SALARY_PRECISION) {
            revert Module__MilestoneManager__InvalidSalarySum();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Constants

    /// @dev Marks the beginning of the list.
    /// @dev Unrealistic to have that many milestones.
    uint internal constant _SENTINEL = type(uint).max;

    /// @dev Marks the last element of the list.
    /// @dev Always links back to the _SENTINEL.
    uint internal _last;

    /// @dev Marks the maximum amount of contributors per milestone.
    /// @dev Setting a reasonable limit prevents running into 'out of gas' issues with the generated payment order array
    uint internal constant MAXIMUM_CONTRIBUTORS = 50;

    //--------------------------------------------------------------------------
    // Storage

    /// @dev Value for what the next id will be.
    uint private _nextId;

    /// @dev Registry mapping milestone ids to Milestone structs.
    mapping(uint => Milestone) private _milestoneRegistry;

    /// @dev List of milestone id's.
    LinkedIdList.List _milestoneList;

    /// @dev The current active milestone's id.
    /// @dev Uses _SENTINEL to indicate no current active milestone.
    uint private _activeMilestone;

    /// @dev The current minimum time gap between the updating and staring of a milestone
    /// @dev The default value will be 3 days. Can be updated by authorized addresses.
    uint private _milestoneUpdateTimelock;

    /// @dev Marks the precision we will use for the salary percentages. Represents what counts as "100%".
    /// @dev Value is 100_000_000 since it allows for 1$ precision in a 1.000.000$ budget.
    uint internal SALARY_PRECISION;

    /// @dev Defines what part of the Budget gets taken as fee at the start of a Milestone.
    /// @dev defined as a value relative to the SALARY_PRECISION
    uint internal FEE_PCT;

    /// @dev Treasury address to send the fees to.
    address private FEE_TREASURY;

    //--------------------------------------------------------------------------
    // Initialization

    /// @inheritdoc Module
    function init(
        IProposal proposal_,
        Metadata memory metadata,
        bytes memory configdata
    ) external override(Module) initializer {
        __Module_init(proposal_, metadata);

        // Set up empty list of milestones.
        _milestoneList.init();

        // Set _activeMilestone to sentinel as otherwise the 0th milestone would
        // be interpreted as active.
        _activeMilestone = _SENTINEL;
        _milestoneUpdateTimelock = 3 days;

        (SALARY_PRECISION, FEE_PCT, FEE_TREASURY) =
            abi.decode(configdata, (uint, uint, address));

        if (FEE_PCT >= SALARY_PRECISION) {
            revert Module__MilestoneManager__FeeOverHundredPercent();
        }
    }

    //--------------------------------------------------------------------------
    // Public View Functions

    /// @inheritdoc IMilestoneManager
    function getMilestoneInformation(uint id)
        public
        view
        validId(id)
        returns (Milestone memory)
    {
        return _milestoneRegistry[id];
    }

    /// @inheritdoc IMilestoneManager
    function listMilestoneIds() public view returns (uint[] memory) {
        return _milestoneList.listIds();
    }

    /// @inheritdoc IMilestoneManager
    function getActiveMilestoneId() external view returns (uint milestoneId) {
        if (!hasActiveMilestone()) {
            revert Module__MilestoneManager__NoActiveMilestone();
        }

        return _activeMilestone;
    }

    /// @inheritdoc IMilestoneManager
    function hasActiveMilestone() public view returns (bool) {
        if (!isExistingMilestoneId(_activeMilestone)) {
            return false;
        }

        Milestone memory m = _milestoneRegistry[_activeMilestone];

        // Milestone active if not completed and already started but duration
        // not yet over.
        uint startTimestamp = m.startTimestamp;
        return !m.completed && startTimestamp != 0
            && startTimestamp + m.duration >= block.timestamp;
    }

    /// @inheritdoc IMilestoneManager
    function isNextMilestoneActivatable() public view returns (bool) {
        // Return false if next milestone does not exist.
        uint next = _milestoneList.getNextId(_activeMilestone);
        if (!isExistingMilestoneId(next)) {
            return false;
        }

        if (
            block.timestamp - _milestoneRegistry[next].lastUpdatedTimestamp
                < _milestoneUpdateTimelock
        ) {
            return false;
        }

        // Return false if Milestone has already been started
        if (_milestoneRegistry[next].startTimestamp != 0) {
            return false;
        }

        // Return true if current active milestone does not exist.
        if (!isExistingMilestoneId(_activeMilestone)) {
            return true;
        }

        Milestone memory m = _milestoneRegistry[_activeMilestone];

        // Milestone is activatable if current milestone started and its
        // duration exceeded.
        return m.startTimestamp + m.duration < block.timestamp;
    }

    /// @inheritdoc IMilestoneManager
    function isExistingMilestoneId(uint id) public view returns (bool) {
        return _milestoneList.isExistingId(id);
    }

    /// @inheritdoc IMilestoneManager
    function getPreviousMilestoneId(uint id)
        external
        view
        validId(id)
        returns (uint prevId)
    {
        uint[] memory milestoneIds = listMilestoneIds();

        uint len = milestoneIds.length;
        for (uint i; i < len; ++i) {
            if (milestoneIds[i] == id) {
                return i != 0 ? milestoneIds[i - 1] : _SENTINEL;
            }
        }
    }

    /// @inheritdoc IMilestoneManager
    function isContributor(uint milestoneId, address who)
        public
        view
        returns (bool)
    {
        Contributor[] memory contribs =
            getMilestoneInformation(milestoneId).contributors;

        uint len = contribs.length;
        for (uint i; i < len; ++i) {
            if (contribs[i].addr == who) {
                return true;
            }
        }
        return false;
    }

    /// @inheritdoc IMilestoneManager
    function getSalaryPrecision() public view returns (uint) {
        return SALARY_PRECISION;
    }

    function getFeePct() public view returns (uint) {
        return FEE_PCT;
    }

    /// @inheritdoc IMilestoneManager
    function getMaximumContributors() public pure returns (uint) {
        return MAXIMUM_CONTRIBUTORS;
    }

    function getMilestoneUpdateTimelock() public view returns (uint) {
        return _milestoneUpdateTimelock;
    }

    //--------------------------------------------------------------------------
    // Milestone API Functions

    /// @inheritdoc IMilestoneManager
    function addMilestone(
        uint duration,
        uint budget,
        Contributor[] calldata contributors,
        bytes calldata details
    ) external onlyAuthorizedOrManager returns (uint) {
        _validateMilestoneDetails(duration, budget, contributors, details);

        return _addMilestone(duration, budget, contributors, details);
    }

    /// @inheritdoc IMilestoneManager
    function stopMilestone(uint prevId, uint id)
        external
        onlyAuthorizedOrManager
        validId(id)
    {
        Milestone storage m = _milestoneRegistry[id];

        // Only stoppable if milestone currently active.
        // revert if not started yet or finished already
        if (
            m.startTimestamp == 0
                || block.timestamp > m.startTimestamp + m.duration
        ) {
            revert Module__MilestoneManager__MilestoneNotActive();
        }

        //Move ActiveId To Previous Id
        _activeMilestone = prevId;

        //Remove Id from list
        _milestoneList.removeId(prevId, id);

        // stop all currently running payments
        __Module_proposal.paymentProcessor().cancelRunningPayments(
            IPaymentClient(address(this))
        );

        emit MilestoneStopped(id);
    }

    /// @inheritdoc IMilestoneManager
    function removeMilestone(uint prevId, uint id)
        external
        onlyAuthorizedOrManager
        validId(id)
    {
        Milestone storage m = _milestoneRegistry[id];

        // Not removeable if milestone started already.
        // Note that this also ensures completed milestones are non-removable.
        if (m.startTimestamp != 0) {
            revert Module__MilestoneManager__MilestoneNotRemovable();
        }

        // Remove milestone instance from registry.
        delete _milestoneRegistry[id];

        //Remove Id from list
        _milestoneList.removeId(prevId, id);

        emit MilestoneRemoved(id);
    }

    /// @inheritdoc IMilestoneManager
    function startNextMilestone() external onlyAuthorizedOrManager {
        if (!isNextMilestoneActivatable()) {
            revert Module__MilestoneManager__MilestoneNotActivateable();
        }

        // Get next milestone's id and update _activeMilestone.
        uint next = _milestoneList.getNextId(_activeMilestone);
        _activeMilestone = next;

        // Receive pointer to next milestone instance.
        Milestone storage m = _milestoneRegistry[next];

        // Mark milestone as started, i.e. set its startTimestamp.
        m.startTimestamp = block.timestamp;

        IMilestoneManager.Contributor[] memory contribCache = m.contributors;

        if (m.budget != 0) {
            //substract the fee from the budget and send it to treasury
            uint feePayout = ((m.budget / SALARY_PRECISION) * FEE_PCT);

            m.budget -= feePayout;

            _ensureTokenBalance(feePayout);
            proposal().token().safeTransfer(FEE_TREASURY, feePayout);

            // Create payment order for each contributor of the new  milestone.
            uint len = contribCache.length;
            if (contribCache.length == 1) {
                // Calculate the payout amount.
                uint contributorPayout =
                    (m.budget / SALARY_PRECISION) * contribCache[0].salary;

                // Note that the payout SHOULD be fulfilled before the end of the milestone's duration.
                _addPaymentOrder(
                    contribCache[0].addr,
                    contributorPayout,
                    block.timestamp + m.duration
                );
            }
            if (contribCache.length > 1) {
                // memory arrays used as parameters to _addPaymentOrders
                address[] memory recipients = new address[](len);
                uint[] memory amounts = new uint[](len);
                uint[] memory dueTos = new uint[](len);
                for (uint i; i < len; ++i) {
                    // Calculate the contributor payout and add it to contributorPayouts array
                    uint contributorPayout =
                        (m.budget / SALARY_PRECISION) * contribCache[i].salary;
                    amounts[i] = contributorPayout;

                    // Save contributor addresses and dueTos
                    recipients[i] = contribCache[i].addr;
                    dueTos[i] = block.timestamp + m.duration;
                }

                _addPaymentOrders(recipients, amounts, dueTos);
            }
        }

        __Module_proposal.paymentProcessor().processPayments(
            IPaymentClient(address(this))
        );

        emit MilestoneStarted(_last);
    }

    /// @inheritdoc IMilestoneManager
    function updateMilestone(
        uint id,
        uint duration,
        uint budget,
        Contributor[] calldata contributors,
        bytes calldata details
    ) external onlyAuthorizedOrManager validId(id) {
        _validateMilestoneDetails(duration, budget, contributors, details);

        Milestone storage m = _milestoneRegistry[id];

        // Not updateable if milestone started already.
        if (m.startTimestamp != 0) {
            revert Module__MilestoneManager__MilestoneNotUpdateable();
        }

        bool changed;

        if (m.duration != duration) {
            m.duration = duration;
            changed = true;
        }

        if (m.budget != budget) {
            m.budget = budget;
            changed = true;
        }

        if (
            keccak256(abi.encodePacked(m.details))
                != keccak256(abi.encodePacked(details))
        ) {
            m.details = details;
            changed = true;
        }

        if (hashContributors(m.contributors) != hashContributors(contributors))
        {
            delete m.contributors;
            uint len = contributors.length;
            for (uint i; i < len; ++i) {
                m.contributors.push(contributors[i]);
            }
            changed = true;
        }

        if (changed) {
            m.lastUpdatedTimestamp = block.timestamp;
            emit MilestoneUpdated(id, duration, budget, contributors, details);
        }
    }

    /// @inheritdoc IMilestoneManager
    function moveMilestoneInList(uint id, uint prevId, uint idToPositionAfter)
        external
        onlyAuthorizedOrManager
        validIntermediateMilestonePosition(id, idToPositionAfter)
    {
        _milestoneList.moveIdInList(id, prevId, idToPositionAfter);
    }

    /// @inheritdoc IMilestoneManager
    function submitMilestone(uint milestoneId, bytes calldata submissionData)
        external
        onlyContributorOf(milestoneId)
        validId(milestoneId)
        validSubmissionData(submissionData)
    {
        Milestone storage m = _milestoneRegistry[milestoneId];

        // Not submitable if milestone not started yet or already completed.
        if (m.startTimestamp == 0 || m.completed) {
            revert Module__MilestoneManager__MilestoneNotSubmitable();
        }

        if (m.submissionData.length == 0) {
            m.submissionData = submissionData;
            emit MilestoneSubmitted(milestoneId, submissionData);
        }
    }

    /// @inheritdoc IMilestoneManager
    function completeMilestone(uint milestoneId)
        external
        onlyAuthorizedOrManager
        validId(milestoneId)
    {
        Milestone storage m = _milestoneRegistry[milestoneId];

        // Not confirmable if milestone not submitted yet.
        if (m.submissionData.length == 0) {
            revert Module__MilestoneManager__MilestoneNotCompleteable();
        }

        if (!m.completed) {
            m.completed = true;
            emit MilestoneCompleted(milestoneId);
        }
    }

    /// @inheritdoc IMilestoneManager
    function declineMilestone(uint milestoneId)
        external
        onlyAuthorizedOrManager
        validId(milestoneId)
    {
        Milestone storage m = _milestoneRegistry[milestoneId];

        // Not declineable if milestone not submitted yet or already completed.
        if (m.submissionData.length == 0 || m.completed) {
            revert Module__MilestoneManager__MilestoneNotDeclineable();
        }

        // Declining a milestone removes the submitionData and therefore marks it as not submitted again.
        m.submissionData = "";
        emit MilestoneDeclined(milestoneId);
    }

    function changeTreasuryAddress(address to) external {
        if (_msgSender() != FEE_TREASURY) {
            revert Module__MilestoneManager__OnlyCallableByTreasury();
        }
        FEE_TREASURY = to;
    }

    //--------------------------------------------------------------------------
    // Internal Function Implementations

    /// @notice Adds a milestone instance to the list of current milestones
    /// @dev sub-function created to circumvent stackTooDeep errors, assumes parameters have been validated before
    /// @param duration The duration of the milestone.
    /// @param budget The budget for the milestone.
    /// @param contributors The contributor information for the milestone
    /// @param details The milestone's details.
    /// @return _id The newly added milestone's id.
    function _addMilestone(
        uint duration,
        uint budget,
        Contributor[] calldata contributors,
        bytes calldata details
    ) internal returns (uint _id) {
        // Note ids start at 1.
        uint milestoneId = ++_nextId;

        // Add milestone's id to the list.
        _milestoneList.addId(milestoneId);

        // Add milestone instance to registry.
        _milestoneRegistry[milestoneId].duration = duration;
        _milestoneRegistry[milestoneId].budget = budget;

        uint len = contributors.length;
        for (uint i; i < len; ++i) {
            _milestoneRegistry[milestoneId].contributors.push(contributors[i]);
        }

        _milestoneRegistry[milestoneId].details = details;
        _milestoneRegistry[milestoneId].lastUpdatedTimestamp = block.timestamp;

        emit MilestoneAdded(
            milestoneId, duration, budget, contributors, details
        );

        return milestoneId;
    }

    //--------------------------------------------------------------------------
    // Internal Helper Functions

    /// @notice Internal validation function for all milestone details
    /// @dev Only used as a vehicle for all modifiers, the function itself just returns true
    /// @dev Reverts if an argument invalid.
    /// @param duration The duration of the milestone.
    /// @param budget The budget for the milestone.
    /// @param contributors The contributor information for the milestone
    /// @param details The milestone's details.
    function _validateMilestoneDetails(
        uint duration,
        uint budget,
        Contributor[] calldata contributors,
        bytes calldata details
    ) internal view validDuration(duration) validContributors(contributors) {}

    /// @notice Creates a hash of a given set of ontributors for easy comparison
    /// @param contributors The set of contributors to hash.
    /// @return The hashed contributor information.
    function hashContributors(Contributor[] memory contributors)
        internal
        pure
        returns (bytes32)
    {
        uint len = contributors.length;

        address[] memory addrCache = new address[](len);
        uint[] memory salaryCache = new uint[](len);
        bytes32[] memory dataCache = new bytes32[](len);

        for (uint i; i < len; ++i) {
            addrCache[i] = contributors[i].addr;
            salaryCache[i] = contributors[i].salary;
            dataCache[i] = contributors[i].data;
        }

        return keccak256(abi.encodePacked(addrCache, salaryCache, dataCache));
    }

    function updateMilestoneUpdateTimelock(uint _newTimelock)
        external
        onlyAuthorized
    {
        _milestoneUpdateTimelock = _newTimelock;
        emit MilestoneUpdateTimelockUpdated(_milestoneUpdateTimelock);
    }

    //--------------------------------------------------------------------------
    // {PaymentClient} Function Implementations

    function _ensureTokenBalance(uint amount)
        internal
        override(PaymentClient)
    {
        uint balance = __Module_proposal.token().balanceOf(address(this));

        if (balance < amount) {
            // Trigger callback from proposal to transfer tokens
            // to address(this).
            bool ok;
            (ok, /*returnData*/ ) = __Module_proposal.executeTxFromModule(
                address(__Module_proposal.token()),
                abi.encodeWithSignature(
                    "transfer(address,uint256)", address(this), amount - balance
                )
            );

            if (!ok) {
                revert Module__PaymentClient__TokenTransferFailed();
            }
        }
    }

    function _ensureTokenAllowance(IPaymentProcessor spender, uint amount)
        internal
        override(PaymentClient)
    {
        IERC20 token = __Module_proposal.token();
        uint allowance = token.allowance(address(this), address(spender));

        if (allowance < amount) {
            token.safeIncreaseAllowance(address(spender), amount - allowance);
        }
    }

    function _isAuthorizedPaymentProcessor(IPaymentProcessor who)
        internal
        view
        override(PaymentClient)
        returns (bool)
    {
        return __Module_proposal.paymentProcessor() == who;
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Dependencies
import {
    PausableUpgradeable,
    ContextUpgradeable
} from "@oz-up/security/PausableUpgradeable.sol";

// Internal Libraries
import {LibMetadata} from "src/modules/lib/LibMetadata.sol";

// Internal Interfaces
import {IModule, IProposal} from "src/modules/base/IModule.sol";
import {IAuthorizer} from "src/modules/IAuthorizer.sol";

/**
 * @title Module
 *
 * @dev The base contract for modules.
 *
 *      This contract provides a framework for triggering and receiving proposal
 *      callbacks (via `call`) and a modifier to authenticate
 *      callers via the module's proposal.
 *
 *      Each module is identified via a unique identifier based on its major
 *      version, title, and url given in the metadata.
 *
 *      Using proxy contracts, e.g. beacons, enables globally updating module
 *      instances when its minor version changes, but supports differentiating
 *      otherwise equal modules with different major versions.
 *
 * @author byterocket
 */
abstract contract Module is IModule, PausableUpgradeable {
    //--------------------------------------------------------------------------
    // Storage
    //
    // Variables are prefixed with `__Module_`.

    /// @dev The module's proposal instance.
    ///
    /// @custom:invariant Not mutated after initialization.
    IProposal internal __Module_proposal;

    /// @dev The module's metadata.
    ///
    /// @custom:invariant Not mutated after initialization.
    Metadata internal __Module_metadata;

    //--------------------------------------------------------------------------
    // Modifiers
    //
    // Note that the modifiers declared here are available in dowstream
    // contracts too. To not make unnecessary modifiers available, this contract
    // inlines argument validations not needed in downstream contracts.

    /// @notice Modifier to guarantee function is only callable by addresses
    ///         authorized via Proposal.
    modifier onlyAuthorized() {
        IAuthorizer authorizer = __Module_proposal.authorizer();
        if (!authorizer.isAuthorized(_msgSender())) {
            revert Module__CallerNotAuthorized();
        }
        _;
    }

    /// @notice Modifier to guarantee function is only callable by either
    ///         addresses authorized via Proposal or the Proposal's manager.
    modifier onlyAuthorizedOrManager() {
        IAuthorizer authorizer = __Module_proposal.authorizer();
        if (
            !authorizer.isAuthorized(_msgSender())
                && __Module_proposal.manager() != _msgSender()
        ) {
            revert Module__CallerNotAuthorized();
        }
        _;
    }

    /// @notice Modifier to guarantee function is only callable by the proposal.
    /// @dev onlyProposal functions MUST only access the module's storage, i.e.
    ///      `__Module_` variables.
    /// @dev Note to use function prefix `__Module_`.
    modifier onlyProposal() {
        if (_msgSender() != address(__Module_proposal)) {
            revert Module__OnlyCallableByProposal();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Initialization

    constructor() {
        _disableInitializers();
    }

    /// @inheritdoc IModule
    function init(
        IProposal proposal_,
        Metadata memory metadata,
        bytes memory /*configdata*/
    ) external virtual initializer {
        __Module_init(proposal_, metadata);
    }

    /// @dev The initialization function MUST be called by the upstream
    ///      contract in their overriden `init()` function.
    /// @param proposal_ The module's proposal.
    function __Module_init(IProposal proposal_, Metadata memory metadata)
        internal
        onlyInitializing
    {
        __Pausable_init();

        // Write proposal to storage.
        if (address(proposal_) == address(0)) {
            revert Module__InvalidProposalAddress();
        }
        __Module_proposal = proposal_;

        // Write metadata to storage.
        if (!LibMetadata.isValid(metadata)) {
            revert Module__InvalidMetadata();
        }
        __Module_metadata = metadata;
    }

    //--------------------------------------------------------------------------
    // onlyAuthorized Functions
    //
    // API functions for authenticated users.

    /// @inheritdoc IModule
    function pause() external override(IModule) onlyAuthorizedOrManager {
        _pause();
    }

    /// @inheritdoc IModule
    function unpause() external override(IModule) onlyAuthorizedOrManager {
        _unpause();
    }

    //--------------------------------------------------------------------------
    // Public View Functions

    /// @inheritdoc IModule
    function identifier() public view returns (bytes32) {
        return LibMetadata.identifier(__Module_metadata);
    }

    /// @inheritdoc IModule
    function version() public view returns (uint, uint) {
        return (__Module_metadata.majorVersion, __Module_metadata.minorVersion);
    }

    /// @inheritdoc IModule
    function url() public view returns (string memory) {
        return __Module_metadata.url;
    }

    /// @inheritdoc IModule
    function title() public view returns (string memory) {
        return __Module_metadata.title;
    }

    /// @inheritdoc IModule
    function proposal() public view returns (IProposal) {
        return __Module_proposal;
    }

    //--------------------------------------------------------------------------
    // Internal Functions

    /// @dev Internal function to trigger a callback from the proposal.
    /// @param data The call data for the proposal to call.
    /// @return Whether the callback succeeded.
    /// @return The return data of the callback.
    function _triggerProposalCallback(bytes memory data)
        internal
        returns (bool, bytes memory)
    {
        bool ok;
        bytes memory returnData;
        (ok, returnData) =
            __Module_proposal.executeTxFromModule(address(this), data);

        // Note that there is no check whether the proposal callback succeeded.
        // This responsibility is delegated to the caller, i.e. downstream
        // module implementation.
        // However, the {IModule} interface defines a generic error type for
        // failed proposal callbacks that can be used to prevent different
        // custom error types in each implementation.
        return (ok, returnData);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Dependencies
import {ContextUpgradeable} from "@oz-up/utils/ContextUpgradeable.sol";

// Internal Dependencies
import {
    IPaymentClient,
    IPaymentProcessor
} from "src/modules/mixins/IPaymentClient.sol";

/**
 * @title PaymentClient
 *
 * @dev The PaymentClient mixin enables modules to create payment orders that
 *      are processable by a proposal's {IPaymentProcessor} module.
 *
 * @author byterocket
 */
abstract contract PaymentClient is IPaymentClient, ContextUpgradeable {
    //--------------------------------------------------------------------------
    // Modifiers

    modifier validRecipient(address recipient) {
        _ensureValidRecipient(recipient);
        _;
    }

    modifier validAmount(uint amount) {
        _ensureValidAmount(amount);
        _;
    }

    modifier validDueTo(uint dueTo) {
        _ensureValidDueTo(dueTo);
        _;
    }

    //--------------------------------------------------------------------------
    // State

    /// @dev The list of oustanding orders.
    /// @dev Emptied whenever orders are collected.
    PaymentOrder[] internal _orders;

    /// @dev The current cumulative amount of tokens outstanding.
    uint internal _outstandingTokenAmount;

    //--------------------------------------------------------------------------
    // Internal Functions Implemented in Downstream Contract

    /// @dev Ensures `amount` of payment tokens exist in address(this).
    /// @dev MUST be overriden by downstream contract.
    function _ensureTokenBalance(uint amount) internal virtual;

    /// @dev Ensures `amount` of token allowance for payment processor(s).
    /// @dev MUST be overriden by downstream contract.
    function _ensureTokenAllowance(IPaymentProcessor spender, uint amount)
        internal
        virtual;

    /// @dev Returns whether address `who` is an authorized payment processor.
    /// @dev MUST be overriden by downstream contract.
    function _isAuthorizedPaymentProcessor(IPaymentProcessor who)
        internal
        view
        virtual
        returns (bool);

    //--------------------------------------------------------------------------
    // Internal Mutating Functions

    /// @dev Adds a new {PaymentOrder} to the list of outstanding orders.
    /// @param recipient The recipient of the payment.
    /// @param amount The amount to be paid out.
    /// @param dueTo Timestamp at which the payment SHOULD be fulfilled.
    function _addPaymentOrder(address recipient, uint amount, uint dueTo)
        internal
        virtual
        validRecipient(recipient)
        validAmount(amount)
        validDueTo(dueTo)
    {
        // Add order's token amount to current outstanding amount.
        _outstandingTokenAmount += amount;

        // Add new order to list of oustanding orders.
        _orders.push(PaymentOrder(recipient, amount, block.timestamp, dueTo));

        // Ensure our token balance is sufficient.
        // Note that function is implemented in downstream contract.
        _ensureTokenBalance(_outstandingTokenAmount);

        emit PaymentOrderAdded(recipient, amount);
    }

    /// @dev Adds a set of new {PaymentOrder}s to the list of outstanding
    ///      orders.
    /// @param recipients The list of recipients of the payments.
    /// @param amounts The amounts to be paid out.
    /// @param dueTos Timestamps at which the payments SHOULD be fulfilled.
    function _addPaymentOrders(
        address[] memory recipients,
        uint[] memory amounts,
        uint[] memory dueTos
    ) internal virtual {
        uint orderAmount = recipients.length;

        // Revert if arrays' length mismatch.
        if (orderAmount != amounts.length || orderAmount != dueTos.length) {
            revert Module__PaymentClient__ArrayLengthMismatch();
        }

        uint totalTokenAmount;
        for (uint i; i < orderAmount; ++i) {
            _ensureValidRecipient(recipients[i]);
            _ensureValidAmount(amounts[i]);
            _ensureValidDueTo(dueTos[i]);

            // Add order's amount to total amount of new orders.
            totalTokenAmount += amounts[i];

            // Add new order to list of oustanding orders.
            _orders.push(
                PaymentOrder(
                    recipients[i], amounts[i], block.timestamp, dueTos[i]
                )
            );

            emit PaymentOrderAdded(recipients[i], amounts[i]);
        }

        // Add total orders' amount to current outstanding amount.
        _outstandingTokenAmount += totalTokenAmount;

        // Ensure our token balance is sufficient.
        // Note that functions is implemented in downstream contract.
        _ensureTokenBalance(_outstandingTokenAmount);
    }

    /// @dev Adds a set of new identical {PaymentOrder}s to the list of
    ///      outstanding orders.
    /// @param recipients The list of recipients of the payments.
    /// @param amount The amount to be paid out in each order.
    /// @param dueTo Timestamp at which the payments SHOULD be fulfilled.
    function _addIdenticalPaymentOrders(
        address[] memory recipients,
        uint amount,
        uint dueTo
    ) internal virtual validAmount(amount) validDueTo(dueTo) {
        uint orderAmount = recipients.length;

        for (uint i; i < orderAmount; ++i) {
            _ensureValidRecipient(recipients[i]);

            // Add new order to list of oustanding orders.
            _orders.push(
                PaymentOrder(recipients[i], amount, block.timestamp, dueTo)
            );

            emit PaymentOrderAdded(recipients[i], amount);
        }

        // Add total orders' amount to current outstanding amount.
        _outstandingTokenAmount += amount * orderAmount;

        // Ensure our token balance is sufficient.
        // Note that functions is implemented in downstream contract.
        _ensureTokenBalance(_outstandingTokenAmount);
    }

    //--------------------------------------------------------------------------
    // IPaymentClient Functions

    /// @inheritdoc IPaymentClient
    function collectPaymentOrders()
        external
        virtual
        returns (PaymentOrder[] memory, uint)
    {
        // Ensure caller is authorized to act as payment processor.
        // Note that function is implemented in downstream contract.
        if (!_isAuthorizedPaymentProcessor(IPaymentProcessor(_msgSender()))) {
            revert Module__PaymentClient__CallerNotAuthorized();
        }

        // Ensure payment processor is able to fetch the tokens from
        // address(this).
        // Note that function is implemented in downstream contract.
        _ensureTokenAllowance(
            IPaymentProcessor(_msgSender()), _outstandingTokenAmount
        );

        // Create a copy of all orders to return.
        uint ordersLength = _orders.length;
        PaymentOrder[] memory copy = new PaymentOrder[](ordersLength);
        for (uint i; i < ordersLength; ++i) {
            copy[i] = _orders[i];
        }

        // Delete all outstanding orders.
        delete _orders;

        // Cache outstanding token amount.
        uint outstandingTokenAmountCache = _outstandingTokenAmount;

        // Set outstanding token amount to zero.
        _outstandingTokenAmount = 0;

        //Ensure that the Client will have sufficient funds.
        // Note that function is implemented in downstream contract.
        // Note that while we also control when adding a payment order, more complex payment systems with f.ex. deferred payments may not guarantee that having enough balance available when adding the order means it'll have enough balance when the order is processed.
        _ensureTokenBalance(outstandingTokenAmountCache);

        // Return copy of orders and orders' total token amount to payment
        // processor.
        return (copy, outstandingTokenAmountCache);
    }

    /// @inheritdoc IPaymentClient
    function paymentOrders()
        external
        view
        virtual
        returns (PaymentOrder[] memory)
    {
        return _orders;
    }

    /// @inheritdoc IPaymentClient
    function outstandingTokenAmount() external view virtual returns (uint) {
        return _outstandingTokenAmount;
    }

    //--------------------------------------------------------------------------
    // Private Functions

    function _ensureValidRecipient(address recipient) private view {
        if (recipient == address(0) || recipient == address(this)) {
            revert Module__PaymentClient__InvalidRecipient();
        }
    }

    function _ensureValidAmount(uint amount) private pure {
        if (amount == 0) {
            revert Module__PaymentClient__InvalidAmount();
        }
    }

    function _ensureValidDueTo(uint dueTo) private view {
        if (dueTo < block.timestamp) {
            revert Module__PaymentClient__InvalidDueTo();
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IPaymentClient} from "src/modules/mixins/IPaymentClient.sol";

interface IMilestoneManager is IPaymentClient {
    //--------------------------------------------------------------------------
    // Types

    struct Milestone {
        /// @dev The duration of the milestone.
        ///      MUST not be zero.
        uint duration;
        /// @dev The budget for the milestone.
        ///      That is the number of tokens payed to contributors when the
        ///      milestone starts.
        ///      CAN be zero.
        uint budget;
        /// @dev The contributors for the Milestone
        ///      MUST not be empty
        ///      All contributors.salary MUST add up to 100_000_000 (100%)
        Contributor[] contributors;
        /// @dev Arbitrary data to store milestone details if necessary.
        ///      CAN be empty.
        bytes details;
        /// @dev The timestamp the milestone started.
        uint startTimestamp;
        /// @dev Represents the data that is accompanied when a milestone is submitted.
        ///      A Milestone is interpreted as being submitted when the
        ///      submissionData bytes array is not empty.
        ///      Note that only accounts holding the {CONTRIBUTOR_ROLE()} can
        ///      set submittedData and therefore submit milestones.
        bytes submissionData;
        /// @dev Whether the milestone is completed.
        ///      A milestone is completed if it got confirmed and started more
        ///      than duration seconds ago.
        bool completed;
        /// @dev The milestone's last updated timestamp
        ///      To start a new milestone, it should not have been updated in the last 5 days
        uint lastUpdatedTimestamp;
    }

    struct Contributor {
        /// @dev The contributor's address.
        ///      MUST not be empty.
        address addr;
        /// @dev The contributor's salary, as a percentage of the Milestone's total budget.
        ///      MUST not be empty.
        ///      MUST be a number between 1 and SALARY_PRECISION.
        /// @dev Default value for SALARY_PRECISION is 100_000_000 This allows precision of up to 1$ in a 1.000.000$ budget.
        uint salary;
        /// @dev Additional data for the contributor.
        ///      CAN be empty.
        bytes32 data;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by contributor.
    error Module__MilestoneManager__OnlyCallableByContributor();

    /// @notice Given duration invalid.
    error Module__MilestoneManager__InvalidDuration();

    // @audit-info If needed, add error for invalid budget here.
    /// @notice Given budget invalid.
    //error Module__MilestoneManager__InvalidBudget();

    /// @notice Given details invalid.
    error Module__MilestoneManager__InvalidDetails();

    /// @notice Given position invalid.
    error Module__MilestoneManager__InvalidPosition();

    /// @notice Given id is not a valid Intermediate Position in list.
    error Module__MilestoneManager__InvalidIntermediatePosition();

    /// @notice Given milestone id invalid.
    error Module__MilestoneManager__InvalidMilestoneId();

    /// @dev The given submissionData is invalid
    error Module__MilestoneManage__InvalidSubmissionData();

    /// @notice Given milestone not updateable.
    error Module__MilestoneManager__MilestoneNotUpdateable();

    /// @notice Given milestone not removable.
    error Module__MilestoneManager__MilestoneNotRemovable();

    // @notice Given milestone not active.
    error Module__MilestoneManager__MilestoneNotActive();

    /// @notice Given milestone not submitable.
    error Module__MilestoneManager__MilestoneNotSubmitable();

    /// @notice Given milestone not completed.
    error Module__MilestoneManager__MilestoneNotCompleteable();

    /// @notice Given milestone not declineable.
    error Module__MilestoneManager__MilestoneNotDeclineable();

    /// @notice Given milestone not activateable.
    error Module__MilestoneManager__MilestoneNotActivateable();

    /// @notice The supplied milestones are not consecutive
    error Module__MilestoneManager__MilestonesNotConsecutive();

    /// @notice No active milestone currently existing.
    error Module__MilestoneManager__NoActiveMilestone();

    /// @notice Milestone has either too many or no contributors at all.
    error Module__MilestoneManager__InvalidContributorAmount();

    /// @notice Given contributor address invalid.
    error Module__MilestoneManager__InvalidContributorAddress();

    /// @notice Contributor address is already on list.
    error Module__MilestoneManager__DuplicateContributorAddress();

    /// @notice Given contributor salary invalid.
    error Module__MilestoneManager__InvalidContributorSalary();

    /// @notice Given contributor salary invalid.
    error Module__MilestoneManager__InvalidSalarySum();

    /// @notice The fee exceeds 100%
    error Module__MilestoneManager__FeeOverHundredPercent();

    /// @notice The function can only be called by the treasury
    error Module__MilestoneManager__OnlyCallableByTreasury();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when a new milestone added.
    event MilestoneAdded(
        uint indexed id,
        uint duration,
        uint budget,
        Contributor[] contributors,
        bytes details
    );

    /// @notice Event emitted when a milestone got updated.
    event MilestoneUpdated(
        uint indexed id,
        uint duration,
        uint budget,
        Contributor[] contributors,
        bytes details
    );

    /// @notice Event emitted when a milestone is stopped.
    // @param id id of the milestone that is stopped.
    event MilestoneStopped(uint indexed id);

    /// @notice Event emitted when a milestone is removed.
    event MilestoneRemoved(uint indexed id);

    /// @notice Event emitted when a milestone is started.
    event MilestoneStarted(uint indexed id);

    /// @notice Event emitted when a milestone is submitted.
    event MilestoneSubmitted(uint indexed id, bytes submissionData);

    /// @notice Event emitted when a milestone is completed.
    event MilestoneCompleted(uint indexed id);

    /// @notice Event emitted when a milestone declined.
    event MilestoneDeclined(uint indexed id);

    /// @notice Event emitted when a milestone updation timelock is updated.
    event MilestoneUpdateTimelockUpdated(uint indexed newTimelock);

    //--------------------------------------------------------------------------
    // Functions

    //----------------------------------
    // Milestone View Functions

    /// @notice Returns the milestone instance with id `id`.
    /// @dev Returns empty milestone in case id `id` is invalid.
    /// @param id The id of the milstone to return.
    /// @return Milestone with id `id`.
    function getMilestoneInformation(uint id)
        external
        view
        returns (Milestone memory);

    /// @notice Returns total list of milestone ids.
    /// @dev List is in ascending order.
    /// @return List of milestone ids.
    function listMilestoneIds() external view returns (uint[] memory);

    /// @notice Fetches the id of the previous milestone in the list
    /// @dev Reverts if id invalid
    /// @dev This should ideally be only used in a frontend context
    ///      because iterating through the list and finding the previous element
    ///      causes an O(n) runtime of the given list and should ideally be outsourced off-chain.
    /// @param id the id of which the previous element in the list should be found.
    /// @return prevId The id of the previous milestone.
    function getPreviousMilestoneId(uint id)
        external
        view
        returns (uint prevId);

    /// @notice Returns the current active milestone's id.
    /// @dev Reverts in case there is no active milestone.
    /// @return Current active milestone id.
    function getActiveMilestoneId() external view returns (uint);

    /// @notice Returns whether there exists a current active milestone.
    /// @return True if current active milestone exists, false otherwise.
    function hasActiveMilestone() external view returns (bool);

    /// @notice Returns whether the next milestone is activatable.
    /// @return True if next milestone activatable, false otherwise.
    function isNextMilestoneActivatable() external view returns (bool);

    /// @notice Returns whether milestone with id `id` exists.
    /// @return True if milestone with id `id` exists, false otherwise.
    function isExistingMilestoneId(uint id) external view returns (bool);

    /// @notice Returns whether an address is a contributor in one specific milestone.
    /// @return True if the address is a contributor, false otherwise.
    function isContributor(uint id, address who) external view returns (bool);

    /// @notice Returns the precision of the salary percentages. Should be read as "100 + digits after comma", representing 100%
    /// @return The salary precision
    function getSalaryPrecision() external view returns (uint);

    /// @notice Returns what part of the Budget gets taken as fee at the start of a Milestone.
    /// @return The fee, relative to the SALARY_PRECISION
    function getFeePct() external view returns (uint);

    /// @notice Returns the maximum number of allowed contributors
    /// @return The maximum contributors
    function getMaximumContributors() external pure returns (uint);

    //----------------------------------
    // Milestone Mutating Functions

    /// @notice Adds a new milestone.
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if an argument invalid.
    /// @param duration The duration of the milestone.
    /// @param budget The budget for the milestone.
    /// @param contributors The contributor information for the milestone
    /// @param details The milestone's details.
    /// @return The newly added milestone's id.
    function addMilestone(
        uint duration,
        uint budget,
        Contributor[] calldata contributors,
        bytes calldata details
    ) external returns (uint);

    /// @notice Stops a milestone.
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if id invalid, milestone not currently active or milestone ids
    ///      not consecutive in list.
    /// @param prevId The previous milestone's id in the milestone list.
    /// @param id The milestone's id to remove.
    function stopMilestone(uint prevId, uint id) external;

    /// @notice Removes a milestone.
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if id invalid, milestone already completed or milestone ids
    ///      not consecutive in list.
    /// @param prevId The previous milestone's id in the milestone list.
    /// @param id The milestone's id to remove.
    function removeMilestone(uint prevId, uint id) external;

    /// @notice Starts the next milestones.
    /// @dev Creates the payment orders to pay contributors.
    /// @dev Reverts if next milestone not activatable or proposal's contributor
    ///      list empty.
    /// @dev Only callable by authorized addresses.
    function startNextMilestone() external;

    /// @notice Updates a milestone's informations.
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if an argument invalid or milestone already started.
    /// @param id The milestone's id.
    /// @param duration The duration of the milestone.
    /// @param budget The budget for the milestone.
    /// @param contributors The contributor information for the milestone
    /// @param details The milestone's details.
    function updateMilestone(
        uint id,
        uint duration,
        uint budget,
        Contributor[] calldata contributors,
        bytes calldata details
    ) external;

    /// @notice Moves a Milestone in the milestone list
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if milestone that should be moved already started.
    /// @dev Reverts if the position following the idToPositionAfter milestone already started.
    /// @dev Reverts if milestone that should be moved equals the milestone that should be positioned after.
    /// @dev Reverts if milestone that should be positioned after equals the milestone that comes previous to the one that should be moved
    /// @param id The id of the milestone that should be moved.
    /// @param prevId The previous milestone's id in the milestone list (in relation to the milestone that should be moved).
    /// @param idToPositionAfter The id of the milestone, that the selected milestone should be positioned after.
    function moveMilestoneInList(uint id, uint prevId, uint idToPositionAfter)
        external;

    /// @notice Submits a milestone.
    /// @dev Only callable by addresses holding the contributor role.
    /// @dev Reverts if id invalid, milestone not yet started, or milestone
    ///      already completed.
    /// @dev Relay function that routes the function call via the proposal.
    /// @param id The milestone's id.
    function submitMilestone(uint id, bytes calldata submissionData) external;

    /// @notice Completes a milestone.
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if id invalid or milestone not yet submitted.
    /// @param id The milestone's id.
    function completeMilestone(uint id) external;

    /// @notice Declines a submitted milestone.
    /// @dev Only callable by authorized addresses.
    /// @dev Reverts if id invalid, milestone not yet submitted, or milestone
    ///      already completed.
    /// @param id The milestone's id.
    function declineMilestone(uint id) external;

    /// @notice Updates the `_milestoneUpdateTimelock` value
    /// @dev Only callable by authorized addresses.
    /// @dev The `_milestoneUpdateTimelock` is the allowed time gap between updating a milestone and starting it
    /// @param _newTimelock The new intended value for `_milestoneUpdateTimelock`
    function updateMilestoneUpdateTimelock(uint _newTimelock) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// External Interfaces
import {IERC20} from "@oz/token/ERC20/IERC20.sol";

// Internal Interfaces
import {IModuleManager} from "src/proposal/base/IModuleManager.sol";
import {IFundingManager} from "src/proposal/base/IFundingManager.sol";
import {IAuthorizer} from "src/modules/IAuthorizer.sol";
import {IPaymentProcessor} from "src/modules/IPaymentProcessor.sol";

interface IProposal is IModuleManager, IFundingManager {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized caller.
    error Proposal__CallerNotAuthorized();

    /// @notice Execution of transaction failed.
    error Proposal__ExecuteTxFailed();

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Initialization function.
    function init(
        uint proposalId,
        address owner,
        IERC20 token,
        address[] calldata modules,
        IAuthorizer authorizer,
        IPaymentProcessor paymentProcessor
    ) external;

    /// @notice Executes a call on target `target` with call data `data`.
    /// @dev Only callable by authorized caller.
    /// @param target The address to call.
    /// @param data The call data.
    /// @return The return data of the call.
    function executeTx(address target, bytes memory data)
        external
        returns (bytes memory);

    /// @notice Returns the proposal's id.
    /// @dev Unique id set by the {ProposalFactory} during initialization.
    function proposalId() external view returns (uint);

    /// @notice The {IAuthorizer} implementation used to authorize addresses.
    function authorizer() external view returns (IAuthorizer);

    /// @notice The {IPaymentProcessor} implementation used to process module
    ///         payments.
    function paymentProcessor() external view returns (IPaymentProcessor);

    /// @notice The proposal's {IERC20} token accepted for fundings and used
    ///         for payments.
    function token() external view returns (IERC20);

    /// @notice The proposal's non-rebasing receipt token.
    function receiptToken() external view returns (IERC20);

    /// @notice The version of the proposal instance.
    function version() external pure returns (string memory);

    function owner() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

/*
Assumptions
-Continous Usage of List
-List is initiated with init ->once<-
-used ids are unique 
*/

library LinkedIdList {
    struct List {
        /// @dev Size of the list
        uint size;
        /// @dev Marks the last element of the list.
        /// @dev Always links back to the _SENTINEL.
        uint last;
        /// @dev List of Ids
        mapping(uint => uint) list;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Given id invalid.
    error Library__LinkedIdList__InvalidId();

    /// @notice Given new id invalid.
    error Library__LinkedIdList__InvalidNewId();

    /// @notice Given position in list is invalid.
    error Library__LinkedIdList__InvalidPosition();

    /// @notice Given ids are not consecutive.
    error Library__LinkedIdList__IdNotConsecutive();

    /// @notice Given ids are not consecutive.
    error Library__LinkedIdList__InvalidIntermediatePosition();

    //--------------------------------------------------------------------------
    // Modifier

    modifier validNewId(List storage self, uint id) {
        if (isExistingId(self, id) || id == 0) {
            revert Library__LinkedIdList__InvalidNewId();
        }
        _;
    }

    modifier validId(List storage self, uint id) {
        if (!isExistingId(self, id)) {
            revert Library__LinkedIdList__InvalidId();
        }
        _;
    }

    modifier validPosition(List storage self, uint id) {
        if (self.list[id] == 0) {
            revert Library__LinkedIdList__InvalidPosition();
        }
        _;
    }

    modifier onlyConsecutiveIds(List storage self, uint prevId, uint id) {
        if (self.list[prevId] != id) {
            revert Library__LinkedIdList__IdNotConsecutive();
        }
        _;
    }

    /// @dev prevId is checked by consecutiveId to be valid
    modifier validMoveParameter(
        List storage self,
        uint id,
        uint prevId,
        uint idToPositionAfter
    ) {
        //Check that id is existing
        if (!isExistingId(self, id)) {
            revert Library__LinkedIdList__InvalidId();
        }
        //Check that idToPositionAfter is in the list
        if (self.list[idToPositionAfter] == 0) {
            revert Library__LinkedIdList__InvalidPosition();
        }
        //Check if it is a valid intermediate position
        if (
            (id == idToPositionAfter) //Make sure it doesnt move after itself
                || (idToPositionAfter == prevId) //Make sure it doesnt move before itself
        ) {
            revert Library__LinkedIdList__InvalidIntermediatePosition();
        }

        //Check for Consecutive Id
        if (self.list[prevId] != id) {
            revert Library__LinkedIdList__IdNotConsecutive();
        }
        _;
    }

    //--------------------------------------------------------------------------
    // Constants

    /// @dev Marks the beginning of the list.
    /// @dev Unrealistic to have that many ids.
    uint internal constant _SENTINEL = type(uint).max;

    //--------------------------------------------------------------------------
    // Init Function

    /// @dev should never be called more than once
    function init(List storage self) internal {
        //set Sentinel to link back to itself to initiate List
        self.list[_SENTINEL] = _SENTINEL;
        self.last = _SENTINEL;
    }

    //--------------------------------------------------------------------------
    // View Functions

    function length(List storage self) internal view returns (uint) {
        return self.size;
    }

    /// @dev Returns the last id in
    function lastId(List storage self) internal view returns (uint) {
        return self.last;
    }

    /// @notice lists the ids contained in the linked list
    /// @dev Returns an array
    /// @param self : the linked List from where the ids should be listed
    /// @return array of ids that are contained in the list
    function listIds(List storage self) internal view returns (uint[] memory) {
        uint[] memory result = new uint256[](self.size);

        // Populate result array.
        uint index;
        uint elem = self.list[_SENTINEL];
        while (elem != _SENTINEL) {
            result[index] = elem;
            elem = self.list[elem];
            index++;
        }

        return result;
    }

    function isExistingId(List storage self, uint id)
        internal
        view
        returns (bool)
    {
        //Return true if id is in list and not Sentinel
        return self.list[id] != 0 && id != _SENTINEL;
    }

    ///@dev id and prevId can be _SENTINEL
    function getPreviousId(List storage self, uint id)
        internal
        view
        validPosition(self, id)
        returns (uint prevId)
    {
        if (id == _SENTINEL) {
            return self.last;
        }
        uint[] memory Ids = listIds(self);

        uint len = Ids.length;
        for (uint i; i < len; ++i) {
            if (Ids[i] == id) {
                return i != 0 ? Ids[i - 1] : _SENTINEL;
            }
        }
    }

    ///@dev id and nextId can be _SENTINEL
    function getNextId(List storage self, uint id)
        internal
        view
        validPosition(self, id)
        returns (uint nextId)
    {
        return self.list[id];
    }

    //--------------------------------------------------------------------------
    // Mutating Functions

    // add To list at last position
    function addId(List storage self, uint id) internal validNewId(self, id) {
        self.list[self.last] = id;
        self.list[id] = _SENTINEL;
        self.last = id;
        self.size++;
    }

    function removeId(List storage self, uint prevId, uint id)
        internal
        validId(self, id)
        onlyConsecutiveIds(self, prevId, id)
    {
        // Remove id from list and decrease size.
        self.list[prevId] = self.list[id];
        delete self.list[id];
        self.size--;

        // In case last element was removed, update _last to its previous
        // element.
        if (id == self.last) {
            self.last = prevId;
        }
    }

    function moveIdInList(
        List storage self,
        uint id,
        uint prevId,
        uint idToPositionAfter
    ) internal validMoveParameter(self, id, prevId, idToPositionAfter) {
        //Remove current id from list
        uint nextIdInLine = self.list[id];
        self.list[prevId] = nextIdInLine;

        //Re-Add id in list:

        //Get the Id that should come after the milestone with idToPositionAfter
        nextIdInLine = self.list[idToPositionAfter];

        // Add id inbetween the targeted id (idToPositionAfter) and the originally following id (nextIdInLine)
        self.list[idToPositionAfter] = id;
        self.list[id] = nextIdInLine;

        //If _last doesnt point towards Sentinel
        if (self.list[self.last] != _SENTINEL) {
            //either id moved to last position
            if (self.list[id] == _SENTINEL) {
                self.last = id;
            }
            //or id moved away from last position
            else {
                self.last = prevId;
            }
        }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IModule} from "src/modules/base/IModule.sol";

/**
 * @title Metadata Library
 *
 * @dev Provides common functions for {IModule}'s Metadata type.
 *
 * @author byterocket
 */
library LibMetadata {
    /// @dev Returns the identifier for given metadata.
    /// @param metadata The metadata.
    /// @return The metadata's identifier.
    function identifier(IModule.Metadata memory metadata)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                metadata.majorVersion, metadata.url, metadata.title
            )
        );
    }

    /// @dev Returns whether the given metadata is valid.
    /// @param metadata The metadata.
    /// @return True if metadata valid, false otherwise.
    function isValid(IModule.Metadata memory metadata)
        internal
        pure
        returns (bool)
    {
        // Invalid if url empty.
        if (bytes(metadata.url).length == 0) {
            return false;
        }

        // Invalid if title empty.
        if (bytes(metadata.title).length == 0) {
            return false;
        }

        // Invalid if version is v0.0.
        if (metadata.majorVersion == 0 && metadata.minorVersion == 0) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Interfaces
import {IProposal} from "src/proposal/IProposal.sol";

interface IModule {
    struct Metadata {
        uint majorVersion;
        uint minorVersion;
        string url;
        string title;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized caller.
    error Module__CallerNotAuthorized();

    /// @notice Function is only callable by the proposal.
    error Module__OnlyCallableByProposal();

    /// @notice Given proposal address invalid.
    error Module__InvalidProposalAddress();

    /// @notice Given metadata invalid.
    error Module__InvalidMetadata();

    /// @notice Proposal callback triggered failed.
    /// @param funcSig The signature of the function called.
    error Module_ProposalCallbackFailed(string funcSig);

    //--------------------------------------------------------------------------
    // Functions

    /// @notice The module's initializer function.
    /// @dev CAN be overriden by downstream contract.
    /// @dev MUST call `__Module_init()`.
    /// @param proposal The module's proposal instance.
    /// @param metadata The module's metadata.
    /// @param configdata Variable config data for specific module
    ///                   implementations.
    function init(
        IProposal proposal,
        Metadata memory metadata,
        bytes memory configdata
    ) external;

    /// @notice Returns the module's identifier.
    /// @dev The identifier is defined as the keccak256 hash of the module's
    ///      abi packed encoded major version, url and title.
    /// @return The module's identifier.
    function identifier() external view returns (bytes32);

    /// @notice Returns the module's version.
    /// @return The module's major version.
    /// @return The module's minor version.
    function version() external view returns (uint, uint);

    /// @notice Returns the module's URL.
    /// @return The module's URL.
    function url() external view returns (string memory);

    /// @notice Returns the module's title.
    /// @return The module's title.
    function title() external view returns (string memory);

    /// @notice Returns the module's {IProposal} proposal instance.
    /// @return The module's proposal.
    function proposal() external view returns (IProposal);

    /// @notice Pauses the module.
    /// @dev Only callable by authorized addresses.
    function pause() external;

    /// @notice Unpauses the module.
    /// @dev Only callable by authorized addresses.
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

interface IAuthorizer {
    function isAuthorized(address who) external view returns (bool);
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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

// Internal Interfaces
import {IPaymentProcessor} from "src/modules/IPaymentProcessor.sol";

interface IPaymentClient {
    struct PaymentOrder {
        /// @dev The recipient of the payment.
        address recipient;
        /// @dev The amount of tokens to pay.
        uint amount;
        /// @dev Timestamp at which the order got created.
        uint createdAt;
        /// @dev Timestamp at which the payment SHOULD be fulfilled.
        uint dueTo;
    }

    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Module__PaymentClient__CallerNotAuthorized();

    /// @notice ERC20 token transfer failed.
    error Module__PaymentClient__TokenTransferFailed();

    /// @notice Given recipient invalid.
    error Module__PaymentClient__InvalidRecipient();

    /// @notice Given amount invalid.
    error Module__PaymentClient__InvalidAmount();

    /// @notice Given dueTo invalid.
    error Module__PaymentClient__InvalidDueTo();

    /// @notice Given arrays' length mismatch.
    error Module__PaymentClient__ArrayLengthMismatch();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Added a payment order.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    event PaymentOrderAdded(address indexed recipient, uint amount);

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Returns the list of outstanding payment orders.
    function paymentOrders() external view returns (PaymentOrder[] memory);

    /// @notice Returns the total outstanding token payment amount.
    function outstandingTokenAmount() external view returns (uint);

    /// @notice Collects outstanding payment orders.
    /// @dev Marks the orders as completed for the client.
    ///      The responsibility to fulfill the orders are now in the caller's
    ///      hand!
    /// @return list of payment orders
    /// @return total amount of token to pay
    function collectPaymentOrders()
        external
        returns (PaymentOrder[] memory, uint);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

interface IModuleManager {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Proposal__ModuleManager__CallerNotAuthorized();

    /// @notice Function is only callable by modules.
    error Proposal__ModuleManager__OnlyCallableByModule();

    /// @notice Given module address invalid.
    error Proposal__ModuleManager__InvalidModuleAddress();

    /// @notice Given address is a module.
    error Proposal__ModuleManager__IsModule();

    /// @notice Given address is not a module.
    error Proposal__ModuleManager__IsNotModule();

    /// @notice The supplied modules are not consecutive.
    error Proposal__ModuleManager__ModulesNotConsecutive();

    /// @notice The Manager has reached the maximum amount of modules.
    error Proposal__ModuleManager__ModuleAmountOverLimits();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when module added.
    /// @param module The module's address.
    event ModuleAdded(address indexed module);

    /// @notice Event emitted when module removed.
    /// @param module The module's address.
    event ModuleRemoved(address indexed module);

    /// @notice Event emitted when account `account` is granted role `role` for
    ///         module `module`.
    /// @param module The module's address.
    /// @param role The access control role.
    /// @param account The account the role was granted to.
    event ModuleRoleGranted(
        address indexed module, bytes32 indexed role, address indexed account
    );

    /// @notice Event emitted when account `account` is revoked role `role` for
    ///         module `module`.
    /// @param module The module's address.
    /// @param role The access control role.
    /// @param account The account the role was revoked for.
    event ModuleRoleRevoked(
        address indexed module, bytes32 indexed role, address indexed account
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Executes a call to `to` with call data `data` either via call
    /// @dev Only callable by enabled modules.
    /// @param to The address to call.
    /// @param data The call data.
    /// @return Whether the call succeeded.
    /// @return The return data of the call.
    function executeTxFromModule(address to, bytes memory data)
        external
        returns (bool, bytes memory);

    /// @notice Adds address `module` as module.
    /// @dev Only callable by authorized address.
    /// @dev Fails if address invalid or address already added as module.
    /// @param module The module address to add.
    function addModule(address module) external;

    /// @notice Removes address `module` as module.
    /// @dev Only callable by authorized address.
    /// @dev Fails if address not added as module.
    /// @param module The module address to remove.
    function removeModule(address module) external;

    /// @notice Returns whether the address `module` is added as module.
    /// @param module The module to check.
    /// @return True if module added, false otherwise.
    function isModule(address module) external returns (bool);

    /// @notice Returns the list of all modules.
    /// @return List of all modules.
    function listModules() external view returns (address[] memory);

    /// @notice Returns the number of modules.
    function modulesSize() external view returns (uint8);

    /// @notice Grants role `role` to account `account` in caller's access
    ///         control context.
    /// @dev Only callable by enabled module.
    /// @param role The access control role.
    /// @param account The account to grant given role.
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes role `role` from account `account` in caller's access
    ///         control context.
    /// @dev Only callable by enabled module.
    /// @param role The access control role.
    /// @param account The account to revoke role for.
    function revokeRole(bytes32 role, address account) external;

    /// @notice Renounces the caller's role `role` in module's `module` access
    ///         control context.
    /// @param module The module in which's access control context the role
    ///               should be renounced.
    /// @param role The access control role.
    function renounceRole(address module, bytes32 role) external;

    /// @notice Returns whether the account `account` holds the role `role` in
    ///         the module's `module` access control context.
    /// @param module The module in which's access control context the role
    ///               is checked.
    /// @param role The access control role.
    /// @param account The account to check role for.
    /// @return True if account has role in module's access control context,
    ///         false otherwise.
    function hasRole(address module, bytes32 role, address account)
        external
        returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IRebasingERC20} from "src/proposal/token/IRebasingERC20.sol";

interface IFundingManager is IRebasingERC20 {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice Function is only callable by authorized address.
    error Proposal__FundingManager__CannotSelfDeposit();

    /// @notice There is a cap on deposits.
    error Proposal__FundingManager__DepositCapReached();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Event emitted when a deposit takes place.
    /// @param from The address depositing tokens.
    /// @param to The address that will receive the receipt tokens.
    /// @param amount The amount of tokens deposited.
    event Deposit(
        address indexed from, address indexed to, uint indexed amount
    );

    /// @notice Event emitted when a withdrawal takes place.
    /// @param from The address supplying the receipt tokens.
    /// @param to The address that will receive the underlying tokens.
    /// @param amount The amount of underlying tokens withdrawn.
    event Withdrawal(
        address indexed from, address indexed to, uint indexed amount
    );

    //--------------------------------------------------------------------------
    // Functions

    function deposit(uint amount) external;
    function depositFor(address to, uint amount) external;

    function withdraw(uint amount) external;
    function withdrawTo(address to, uint amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {IPaymentClient} from "src/modules/mixins/IPaymentClient.sol";

interface IPaymentProcessor {
    //--------------------------------------------------------------------------
    // Errors

    /// @notice invalid caller
    error Module__PaymentManager__OnlyCallableByModule();

    /// @notice a client can only execute on its own orders
    error Module__PaymentManager__CannotCallOnOtherClientsOrders();

    //--------------------------------------------------------------------------
    // Events

    /// @notice Emitted when a payment gets processed for execution.
    /// @param paymentClient The payment client that originated the order.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    /// @param createdAt Timestamp at which the order was created.
    /// @param dueTo Timestamp at which the full amount should be payed out/claimable.
    event PaymentOrderProcessed(
        address indexed paymentClient,
        address indexed recipient,
        uint amount,
        uint createdAt,
        uint dueTo
    );

    /// @notice Emitted when an amount of ERC20 tokens gets sent out of the contract.
    /// @param recipient The address that will receive the payment.
    /// @param amount The amount of tokens the payment consists of.
    event TokensReleased(
        address indexed recipient, address indexed token, uint amount
    );

    //--------------------------------------------------------------------------
    // Functions

    /// @notice Processes all payments from an {IPaymentClient} instance.
    /// @dev It's up to the the implementation to keep up with what has been
    ///      paid out or not.
    /// @param client The {IPaymentClient} instance to process its to payments.
    function processPayments(IPaymentClient client) external;

    /// @notice Cancels all unfinished payments from an {IPaymentClient} instance.
    /// @dev It's up to the the implementation to keep up with what has been
    ///      paid out or not.
    /// @param client The {IPaymentClient} instance to process its to payments.
    function cancelRunningPayments(IPaymentClient client) external;

    /// @notice Returns the IERC20 token the payment processor can process.
    function token() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import "./IERC20Metadata.sol";

/**
 * @title Rebasing ERC20 Interface
 *
 * @dev Interface definition for Rebasing ERC20 tokens which have an "elastic"
 *      external balance and "fixed" internal balance.
 *      Each user's external balance is represented as a product of a "scalar"
 *      and the user's internal balance.
 *
 *      In regular time intervals the rebase operation updates the scalar,
 *      which increases or decreases all user balances proportionally.
 *
 *      The standard ERC20 methods are denomintaed in the elastic balance.
 *
 * @author Buttonwood Foundation
 */
interface IRebasingERC20 is IERC20Metadata {
    /// @notice Returns the fixed balance of the specified address.
    /// @param who The address to query.
    function scaledBalanceOf(address who) external view returns (uint);

    /// @notice Returns the total fixed supply.
    function scaledTotalSupply() external view returns (uint);

    /// @notice Transfer all of the sender's balance to a specified address.
    /// @param to The address to transfer to.
    /// @return True on success, false otherwise.
    function transferAll(address to) external returns (bool);

    /// @notice Transfer all balance tokens from one address to another.
    /// @param from The address to send tokens from.
    /// @param to The address to transfer to.
    function transferAllFrom(address from, address to)
        external
        returns (bool);

    /// @notice Triggers the next rebase, if applicable.
    function rebase() external;

    /// @notice Event emitted when the balance scalar is updated.
    /// @param epoch The number of rebases since inception.
    /// @param newScalar The new scalar.
    event Rebase(uint indexed epoch, uint newScalar);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
pragma solidity ^0.8.13;

import "./IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 *
 * @author OpenZeppelin
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 *
 * @author OpenZeppelin
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint amount)
        external
        returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}