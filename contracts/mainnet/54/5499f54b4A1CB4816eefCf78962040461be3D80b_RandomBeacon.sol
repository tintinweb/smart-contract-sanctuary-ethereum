// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "./api/IRandomBeacon.sol";
import "./libraries/Groups.sol";
import "./libraries/Relay.sol";
import "./libraries/Groups.sol";
import "./libraries/Callback.sol";
import "./Reimbursable.sol";
import "./Governable.sol";
import {BeaconInactivity as Inactivity} from "./libraries/BeaconInactivity.sol";
import {BeaconAuthorization as Authorization} from "./libraries/BeaconAuthorization.sol";
import {BeaconDkg as DKG} from "./libraries/BeaconDkg.sol";
import {BeaconDkgValidator as DKGValidator} from "./BeaconDkgValidator.sol";

import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "@threshold-network/solidity-contracts/contracts/staking/IApplication.sol";
import "@threshold-network/solidity-contracts/contracts/staking/IStaking.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title Keep Random Beacon
/// @notice Keep Random Beacon contract. It lets to request a new
///         relay entry and validates the new relay entry provided by the
///         network. This contract is in charge of all other Random Beacon
///         activities such as group lifecycle or slashing.
/// @dev Should be owned by the governance contract controlling Random Beacon
///      parameters.
contract RandomBeacon is IRandomBeacon, IApplication, Governable, Reimbursable {
    using SafeERC20 for IERC20;
    using Authorization for Authorization.Data;
    using DKG for DKG.Data;
    using Groups for Groups.Data;
    using Relay for Relay.Data;
    using Callback for Callback.Data;

    // Constant parameters

    /// @notice Seed value used for the genesis group selection.
    /// https://www.wolframalpha.com/input/?i=pi+to+78+digits
    uint256 internal constant genesisSeed =
        31415926535897932384626433832795028841971693993751058209749445923078164062862;

    // Governable parameters

    /// @notice Relay entry callback gas limit. This is the gas limit with which
    ///         callback function provided in the relay request transaction is
    ///         executed. The callback is executed with a new relay entry value
    ///         in the same transaction the relay entry is submitted.
    uint256 internal _callbackGasLimit;

    /// @notice The frequency of new group creation. Groups are created with
    ///         a fixed frequency of relay requests.
    uint256 internal _groupCreationFrequency;

    /// @notice Slashing amount for submitting a malicious DKG result. Every
    ///         DKG result submitted can be challenged for the time of
    ///         `dkg.ResultChallengePeriodLength`. If the DKG result submitted
    ///         is challenged and proven to be malicious, the operator who
    ///         submitted the malicious result is slashed for
    ///         `_maliciousDkgResultSlashingAmount`.
    uint96 internal _maliciousDkgResultSlashingAmount;

    /// @notice Slashing amount when an unauthorized signing has been proved,
    ///         which means the private key leaked and all the group members
    ///         should be punished.
    uint96 internal _unauthorizedSigningSlashingAmount;

    /// @notice Duration of the sortition pool rewards ban imposed on operators
    ///         who misbehaved during DKG by being inactive or disqualified and
    ///         for operators that were identified by the rest of group members
    ///         as inactive via `notifyOperatorInactivity`.
    uint256 internal _sortitionPoolRewardsBanDuration;

    /// @notice Percentage of the staking contract malicious behavior
    ///         notification reward which will be transferred to the notifier
    ///         reporting about relay entry timeout. Notifiers are rewarded
    ///         from a notifiers treasury pool. For example, if
    ///         notification reward is 1000 and the value of the multiplier is
    ///         5, the notifier will receive: 5% of 1000 = 50 per each
    ///         operator affected.
    uint256 internal _relayEntryTimeoutNotificationRewardMultiplier;

    /// @notice Percentage of the staking contract malicious behavior
    ///         notification reward which will be transferred to the notifier
    ///         reporting about unauthorized signing. Notifiers are rewarded
    ///         from a notifiers treasury pool. For example, if a
    ///         notification reward is 1000 and the value of the multiplier is
    ///         5, the notifier will receive: 5% of 1000 = 50 per each
    ///         operator affected.
    uint256 internal _unauthorizedSigningNotificationRewardMultiplier;

    /// @notice Percentage of the staking contract malicious behavior
    ///         notification reward which will be transferred to the notifier
    ///         reporting about a malicious DKG result. Notifiers are rewarded
    ///         from a notifiers treasury pool. For example, if
    ///         notification reward is 1000 and the value of the multiplier is
    ///         5, the notifier will receive: 5% of 1000 = 50 per each
    ///         operator affected.
    uint256 internal _dkgMaliciousResultNotificationRewardMultiplier;

    /// @notice Calculated gas cost for submitting a DKG result. This will
    ///         be refunded as part of the DKG approval process. It is in the
    ///         submitter's interest to not skip his priority turn on the approval,
    ///         otherwise the refund of the DKG submission will be refunded to
    ///         another group member that will call the DKG approve function.
    uint256 internal _dkgResultSubmissionGas;

    /// @notice Gas that is meant to balance the DKG result approval's overall
    ///         cost. Can be updated by the governance based on the current
    ///         market conditions.
    uint256 internal _dkgResultApprovalGasOffset;

    /// @notice Gas that is meant to balance the operator inactivity notification
    ///         cost. Can be updated by the governance based on the current
    ///         market conditions.
    uint256 internal _notifyOperatorInactivityGasOffset;

    /// @notice Gas that is meant to balance the relay entry submission cost.
    ///         Can be updated by the governance based on the current market
    ///         conditions.
    uint256 internal _relayEntrySubmissionGasOffset;

    // Other parameters

    /// @notice Stores current operator inactivity claim nonce for given group.
    ///         Each claim is made with an unique nonce which protects
    ///         against claim replay.
    mapping(uint64 => uint256) public inactivityClaimNonce; // groupId -> nonce

    /// @notice Authorized addresses that can request a relay entry.
    mapping(address => bool) public authorizedRequesters;

    // External dependencies

    SortitionPool public sortitionPool;
    IERC20 public tToken;
    IStaking public staking;

    // Libraries data storages

    Authorization.Data internal authorization;
    DKG.Data internal dkg;
    Groups.Data internal groups;
    Relay.Data internal relay;
    Callback.Data internal callback;

    // Events

    event AuthorizationParametersUpdated(
        uint96 minimumAuthorization,
        uint64 authorizationDecreaseDelay,
        uint64 authorizationDecreaseChangePeriod
    );

    event RelayEntryParametersUpdated(
        uint256 relayEntrySoftTimeout,
        uint256 relayEntryHardTimeout,
        uint256 callbackGasLimit
    );

    event GroupCreationParametersUpdated(
        uint256 groupCreationFrequency,
        uint256 groupLifetime,
        uint256 dkgResultChallengePeriodLength,
        uint256 dkgResultChallengeExtraGas,
        uint256 dkgResultSubmissionTimeout,
        uint256 dkgResultSubmitterPrecedencePeriodLength
    );

    event RewardParametersUpdated(
        uint256 sortitionPoolRewardsBanDuration,
        uint256 relayEntryTimeoutNotificationRewardMultiplier,
        uint256 unauthorizedSigningNotificationRewardMultiplier,
        uint256 dkgMaliciousResultNotificationRewardMultiplier
    );

    event SlashingParametersUpdated(
        uint256 relayEntrySubmissionFailureSlashingAmount,
        uint256 maliciousDkgResultSlashingAmount,
        uint256 unauthorizedSigningSlashingAmount
    );

    event GasParametersUpdated(
        uint256 dkgResultSubmissionGas,
        uint256 dkgResultApprovalGasOffset,
        uint256 notifyOperatorInactivityGasOffset,
        uint256 relayEntrySubmissionGasOffset
    );

    event RequesterAuthorizationUpdated(
        address indexed requester,
        bool isAuthorized
    );

    event DkgStarted(uint256 indexed seed);

    event DkgResultSubmitted(
        bytes32 indexed resultHash,
        uint256 indexed seed,
        DKG.Result result
    );

    event DkgTimedOut();

    event DkgResultApproved(
        bytes32 indexed resultHash,
        address indexed approver
    );

    event DkgResultChallenged(
        bytes32 indexed resultHash,
        address indexed challenger,
        string reason
    );

    event DkgMaliciousResultSlashed(
        bytes32 indexed resultHash,
        uint256 slashingAmount,
        address maliciousSubmitter
    );

    event DkgMaliciousResultSlashingFailed(
        bytes32 indexed resultHash,
        uint256 slashingAmount,
        address maliciousSubmitter
    );

    event DkgStateLocked();

    event DkgSeedTimedOut();

    event GroupRegistered(uint64 indexed groupId, bytes indexed groupPubKey);

    event RelayEntryRequested(
        uint256 indexed requestId,
        uint64 groupId,
        bytes previousEntry
    );

    event RelayEntrySubmitted(
        uint256 indexed requestId,
        address submitter,
        bytes entry
    );

    event RelayEntryTimedOut(
        uint256 indexed requestId,
        uint64 terminatedGroupId
    );

    event RelayEntryDelaySlashed(
        uint256 indexed requestId,
        uint256 slashingAmount,
        address[] groupMembers
    );

    event RelayEntryDelaySlashingFailed(
        uint256 indexed requestId,
        uint256 slashingAmount,
        address[] groupMembers
    );

    event RelayEntryTimeoutSlashed(
        uint256 indexed requestId,
        uint256 slashingAmount,
        address[] groupMembers
    );

    event RelayEntryTimeoutSlashingFailed(
        uint256 indexed requestId,
        uint256 slashingAmount,
        address[] groupMembers
    );

    event UnauthorizedSigningSlashed(
        uint64 indexed groupId,
        uint256 unauthorizedSigningSlashingAmount,
        address[] groupMembers
    );

    event UnauthorizedSigningSlashingFailed(
        uint64 indexed groupId,
        uint256 unauthorizedSigningSlashingAmount,
        address[] groupMembers
    );

    event CallbackFailed(uint256 entry, uint256 entrySubmittedBlock);

    event InactivityClaimed(
        uint64 indexed groupId,
        uint256 nonce,
        address notifier
    );

    event OperatorRegistered(
        address indexed stakingProvider,
        address indexed operator
    );

    event AuthorizationIncreased(
        address indexed stakingProvider,
        address indexed operator,
        uint96 fromAmount,
        uint96 toAmount
    );

    event AuthorizationDecreaseRequested(
        address indexed stakingProvider,
        address indexed operator,
        uint96 fromAmount,
        uint96 toAmount,
        uint64 decreasingAt
    );

    event AuthorizationDecreaseApproved(address indexed stakingProvider);

    event InvoluntaryAuthorizationDecreaseFailed(
        address indexed stakingProvider,
        address indexed operator,
        uint96 fromAmount,
        uint96 toAmount
    );

    event OperatorJoinedSortitionPool(
        address indexed stakingProvider,
        address indexed operator
    );

    event OperatorStatusUpdated(
        address indexed stakingProvider,
        address indexed operator
    );

    /// @dev Assigns initial values to parameters to make the beacon work
    ///      safely. These parameters are just proposed defaults and they might
    ///      be updated with `update*` functions after the contract deployment
    ///      and before transferring the ownership to the governance contract.
    constructor(
        SortitionPool _sortitionPool,
        IERC20 _tToken,
        IStaking _staking,
        DKGValidator _dkgValidator,
        ReimbursementPool _reimbursementPool
    ) {
        sortitionPool = _sortitionPool;
        tToken = _tToken;
        staking = _staking;
        reimbursementPool = _reimbursementPool;

        require(
            address(_sortitionPool) != address(0),
            "Zero-address reference"
        );
        require(address(_tToken) != address(0), "Zero-address reference");
        require(address(_staking) != address(0), "Zero-address reference");
        require(address(_dkgValidator) != address(0), "Zero-address reference");
        require(
            address(_reimbursementPool) != address(0),
            "Zero-address reference"
        );

        dkg.init(_sortitionPool, _dkgValidator);
        relay.initSeedEntry();

        _transferGovernance(msg.sender);

        //
        // All parameters set in the constructor are initial ones, used at the
        // moment contracts were deployed for the first time. Parameters are
        // governable and values assigned in the constructor do not need to
        // reflect the current ones.
        //

        // Minimum authorization is 40k T.
        //
        // Authorization decrease delay is 45 days.
        //
        // Authorization decrease change period is 45 days. It means pending
        // authorization decrease can be overwritten all the time.
        authorization.setParameters(40_000e18, 3_888_000, 3_888_000);

        // Malicious DKG result slashing amount is set initially to 1% of the
        // minimum authorization (400 T). This values needs to be increased
        // significantly once the system is fully launched.
        //
        // Unauthorized signing slashing amount is set initially to 1% of the
        // minimum authorization (400 T). This values needs to be increased
        // significantly once the system is fully launched.
        //
        // Slashing amount for not providing relay entry on time is set
        // initially to 1% of the minimum authorization (400 T). This values
        // needs to be increased significantly once the system is fully launched.
        //
        // Inactive operators are set as ineligible for rewards for 2 weeks.
        _maliciousDkgResultSlashingAmount = 400e18;
        _unauthorizedSigningSlashingAmount = 400e18;
        relay.setRelayEntrySubmissionFailureSlashingAmount(400e18);

        // Notifier of a malicious DKG result receives 100% of the notifier
        // reward from the staking contract.
        //
        // Notifier of unauthorized signing receives 100% of the notifier
        // reward from the staking contract.
        //
        // Notifier of relay entry timeout receives 100% of the notifier
        // reward from the staking contract.
        _dkgMaliciousResultNotificationRewardMultiplier = 100;
        _unauthorizedSigningNotificationRewardMultiplier = 100;
        _relayEntryTimeoutNotificationRewardMultiplier = 100;

        // Inactive operators are set as ineligible for rewards for 2 weeks.
        _sortitionPoolRewardsBanDuration = 2 weeks;

        // DKG result challenge period length is set to 48h, assuming
        // 15s block time.
        //
        // The extra gas required for DKG result challenge is 50k units.
        //
        // DKG result submission timeout, gives each member 20 blocks to submit
        // the result. Assuming 15s block time, it is ~8h to submit the result
        // in the pessimistic case.
        //
        // The original DKG result submitter has 20 blocks to approve it before
        // anyone else can do that.
        //
        // With these parameters, the happy path takes no more than 56 hours.
        // In practice, it should take about 48 hours (just the challenge time).
        dkg.setParameters(11_520, 50_000, 1_280, 20);

        // Relay entry soft timeout gives each of 64 members 20 blocks to submit
        // the result.
        //
        // Relay entry hard timeout is set to ~48h assuming 15s block time.
        relay.setTimeouts(1_280, 5_760);

        // Callback gas limit is set to 56k units of gas. As of April 2022, it
        // is enough to store new entry and block number on-chain.
        // If the cost of EVM opcodes change over time, these parameters will
        // have to be updated.
        _callbackGasLimit = 64_000;

        // Group lifetime is set to 45 days assuming 15s block time.
        //
        // New group is created every 2 relay requests.
        //
        // This way, even if ECDSA WalletRegistry is the only consumer of the
        // beacon initially, and relay request is executed every week, we should
        // have 2 active groups in the system all the time.
        groups.setGroupLifetime(259_200);
        _groupCreationFrequency = 2;

        // Gas parameters were adjusted based on Ethereum state in April 2022.
        // If the cost of EVM opcodes change over time, these parameters will
        // have to be updated.
        _dkgResultSubmissionGas = 237_650;
        _dkgResultApprovalGasOffset = 41_500;
        _notifyOperatorInactivityGasOffset = 54_500;
        _relayEntrySubmissionGasOffset = 11_250;
    }

    modifier onlyStakingContract() {
        require(
            msg.sender == address(staking),
            "Caller is not the staking contract"
        );
        _;
    }

    modifier onlyReimbursableAdmin() override {
        require(governance == msg.sender, "Caller is not the governance");
        _;
    }

    /// @notice Updates the values of authorization parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param _minimumAuthorization New minimum authorization amount
    /// @param _authorizationDecreaseDelay New authorization decrease delay in
    ///        seconds
    /// @param _authorizationDecreaseChangePeriod New authorization decrease
    ///        change period in seconds
    function updateAuthorizationParameters(
        uint96 _minimumAuthorization,
        uint64 _authorizationDecreaseDelay,
        uint64 _authorizationDecreaseChangePeriod
    ) external onlyGovernance {
        authorization.setParameters(
            _minimumAuthorization,
            _authorizationDecreaseDelay,
            _authorizationDecreaseChangePeriod
        );

        emit AuthorizationParametersUpdated(
            _minimumAuthorization,
            _authorizationDecreaseDelay,
            _authorizationDecreaseChangePeriod
        );
    }

    /// @notice Updates the values of relay entry parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param relayEntrySoftTimeout New relay entry submission soft timeout
    /// @param relayEntryHardTimeout New relay entry hard timeout
    /// @param callbackGasLimit New callback gas limit
    function updateRelayEntryParameters(
        uint256 relayEntrySoftTimeout,
        uint256 relayEntryHardTimeout,
        uint256 callbackGasLimit
    ) external onlyGovernance {
        _callbackGasLimit = callbackGasLimit;
        relay.setTimeouts(relayEntrySoftTimeout, relayEntryHardTimeout);

        emit RelayEntryParametersUpdated(
            relayEntrySoftTimeout,
            relayEntryHardTimeout,
            callbackGasLimit
        );
    }

    /// @notice Updates the values of group creation parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param groupCreationFrequency New group creation frequency
    /// @param groupLifetime New group lifetime in blocks
    /// @param dkgResultChallengePeriodLength New DKG result challenge period
    ///        length
    /// @param dkgResultChallengeExtraGas New DKG result challenge extra gas
    /// @param dkgResultSubmissionTimeout New DKG result submission timeout
    /// @param dkgSubmitterPrecedencePeriodLength New DKG result submitter
    ///        precedence period length
    function updateGroupCreationParameters(
        uint256 groupCreationFrequency,
        uint256 groupLifetime,
        uint256 dkgResultChallengePeriodLength,
        uint256 dkgResultChallengeExtraGas,
        uint256 dkgResultSubmissionTimeout,
        uint256 dkgSubmitterPrecedencePeriodLength
    ) external onlyGovernance {
        _groupCreationFrequency = groupCreationFrequency;
        groups.setGroupLifetime(groupLifetime);
        dkg.setParameters(
            dkgResultChallengePeriodLength,
            dkgResultChallengeExtraGas,
            dkgResultSubmissionTimeout,
            dkgSubmitterPrecedencePeriodLength
        );

        emit GroupCreationParametersUpdated(
            groupCreationFrequency,
            groupLifetime,
            dkgResultChallengePeriodLength,
            dkgResultChallengeExtraGas,
            dkgResultSubmissionTimeout,
            dkgSubmitterPrecedencePeriodLength
        );
    }

    /// @notice Updates the values of reward parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param sortitionPoolRewardsBanDuration New sortition pool rewards
    ///        ban duration in seconds.
    /// @param relayEntryTimeoutNotificationRewardMultiplier New value of the
    ///        relay entry timeout notification reward multiplier
    /// @param unauthorizedSigningNotificationRewardMultiplier New value of the
    ///        unauthorized signing notification reward multiplier
    /// @param dkgMaliciousResultNotificationRewardMultiplier New value of the
    ///        DKG malicious result notification reward multiplier
    function updateRewardParameters(
        uint256 sortitionPoolRewardsBanDuration,
        uint256 relayEntryTimeoutNotificationRewardMultiplier,
        uint256 unauthorizedSigningNotificationRewardMultiplier,
        uint256 dkgMaliciousResultNotificationRewardMultiplier
    ) external onlyGovernance {
        _sortitionPoolRewardsBanDuration = sortitionPoolRewardsBanDuration;
        _relayEntryTimeoutNotificationRewardMultiplier = relayEntryTimeoutNotificationRewardMultiplier;
        _unauthorizedSigningNotificationRewardMultiplier = unauthorizedSigningNotificationRewardMultiplier;
        _dkgMaliciousResultNotificationRewardMultiplier = dkgMaliciousResultNotificationRewardMultiplier;
        emit RewardParametersUpdated(
            sortitionPoolRewardsBanDuration,
            relayEntryTimeoutNotificationRewardMultiplier,
            unauthorizedSigningNotificationRewardMultiplier,
            dkgMaliciousResultNotificationRewardMultiplier
        );
    }

    /// @notice Updates the values of slashing parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param relayEntrySubmissionFailureSlashingAmount New relay entry
    ///        submission failure amount
    /// @param maliciousDkgResultSlashingAmount New malicious DKG result
    ///        slashing amount
    /// @param unauthorizedSigningSlashingAmount New unauthorized signing
    ///        slashing amount
    function updateSlashingParameters(
        uint96 relayEntrySubmissionFailureSlashingAmount,
        uint96 maliciousDkgResultSlashingAmount,
        uint96 unauthorizedSigningSlashingAmount
    ) external onlyGovernance {
        relay.setRelayEntrySubmissionFailureSlashingAmount(
            relayEntrySubmissionFailureSlashingAmount
        );
        _maliciousDkgResultSlashingAmount = maliciousDkgResultSlashingAmount;
        _unauthorizedSigningSlashingAmount = unauthorizedSigningSlashingAmount;
        emit SlashingParametersUpdated(
            relayEntrySubmissionFailureSlashingAmount,
            maliciousDkgResultSlashingAmount,
            unauthorizedSigningSlashingAmount
        );
    }

    /// @notice Updates the values of gas parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param dkgResultSubmissionGas New DKG result submission gas
    /// @param dkgResultApprovalGasOffset New DKG result approval gas offset
    /// @param notifyOperatorInactivityGasOffset New operator inactivity
    ///        notification gas offset
    /// @param relayEntrySubmissionGasOffset New relay entry submission gas
    ///        offset
    function updateGasParameters(
        uint256 dkgResultSubmissionGas,
        uint256 dkgResultApprovalGasOffset,
        uint256 notifyOperatorInactivityGasOffset,
        uint256 relayEntrySubmissionGasOffset
    ) external onlyGovernance {
        _dkgResultSubmissionGas = dkgResultSubmissionGas;
        _dkgResultApprovalGasOffset = dkgResultApprovalGasOffset;
        _notifyOperatorInactivityGasOffset = notifyOperatorInactivityGasOffset;
        _relayEntrySubmissionGasOffset = relayEntrySubmissionGasOffset;

        emit GasParametersUpdated(
            dkgResultSubmissionGas,
            dkgResultApprovalGasOffset,
            notifyOperatorInactivityGasOffset,
            relayEntrySubmissionGasOffset
        );
    }

    /// @notice Set authorization for requesters that can request a relay
    ///         entry.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract.
    /// @param requester Requester, can be a contract or EOA
    /// @param isAuthorized True or false
    function setRequesterAuthorization(address requester, bool isAuthorized)
        external
        onlyGovernance
    {
        authorizedRequesters[requester] = isAuthorized;

        emit RequesterAuthorizationUpdated(requester, isAuthorized);
    }

    /// @notice Withdraws application rewards for the given staking provider.
    ///         Rewards are withdrawn to the staking provider's beneficiary
    ///         address set in the staking contract. Reverts if staking provider
    ///         has not registered the operator address.
    /// @dev Emits `RewardsWithdrawn` event.
    function withdrawRewards(address stakingProvider) external {
        address operator = stakingProviderToOperator(stakingProvider);
        require(operator != address(0), "Unknown operator");
        (, address beneficiary, ) = staking.rolesOf(stakingProvider);
        uint96 amount = sortitionPool.withdrawRewards(operator, beneficiary);
        // slither-disable-next-line reentrancy-events
        emit RewardsWithdrawn(stakingProvider, amount);
    }

    /// @notice Withdraws rewards belonging to operators marked as ineligible
    ///         for sortition pool rewards.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      random beacon governance contract.
    /// @param recipient Recipient of withdrawn rewards.
    function withdrawIneligibleRewards(address recipient)
        external
        onlyGovernance
    {
        sortitionPool.withdrawIneligible(recipient);
    }

    /// @notice Used by staking provider to set operator address that will
    ///         operate a node. The given staking provider can set operator
    ///         address only one time. The operator address can not be changed
    ///         and must be unique. Reverts if the operator is already set for
    ///         the staking provider or if the operator address is already in
    ///         use. Reverts if there is a pending authorization decrease for
    ///         the staking provider.
    function registerOperator(address operator) external {
        authorization.registerOperator(operator);
    }

    /// @notice Lets the operator join the sortition pool. The operator address
    ///         must be known - before calling this function, it has to be
    ///         appointed by the staking provider by calling `registerOperator`.
    ///         Also, the operator must have the minimum authorization required
    ///         by the beacon. Function reverts if there is no minimum stake
    ///         authorized or if the operator is not known. If there was an
    ///         authorization decrease requested, it is activated by starting
    ///         the authorization decrease delay.
    function joinSortitionPool() external {
        authorization.joinSortitionPool(staking, sortitionPool);
    }

    /// @notice Updates status of the operator in the sortition pool. If there
    ///         was an authorization decrease requested, it is activated by
    ///         starting the authorization decrease delay.
    ///         Function reverts if the operator is not known.
    function updateOperatorStatus(address operator) external {
        authorization.updateOperatorStatus(staking, sortitionPool, operator);
    }

    /// @notice Used by T staking contract to inform the beacon that the
    ///         authorized stake amount for the given staking provider increased.
    ///
    ///         Reverts if the authorization amount is below the minimum.
    ///
    ///         The function is not updating the sortition pool. Sortition pool
    ///         state needs to be updated by the operator with a call to
    ///         `joinSortitionPool` or `updateOperatorStatus`.
    ///
    /// @dev Can only be called by T staking contract.
    function authorizationIncreased(
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external onlyStakingContract {
        authorization.authorizationIncreased(
            stakingProvider,
            fromAmount,
            toAmount
        );
    }

    /// @notice Used by T staking contract to inform the beacon that the
    ///         authorization decrease for the given staking provider has been
    ///         requested.
    ///
    ///         Reverts if the amount after deauthorization would be non-zero
    ///         and lower than the minimum authorization.
    ///
    ///         Reverts if another authorization decrease request is pending for
    ///         the staking provider and not enough time passed since the
    ///         original request (see `authorizationDecreaseChangePeriod`).
    ///
    ///         If the operator is not known (`registerOperator` was not called)
    ///         it lets to `approveAuthorizationDecrease` immediately. If the
    ///         operator is known (`registerOperator` was called), the operator
    ///         needs to update state of the sortition pool with a call to
    ///         `joinSortitionPool` or `updateOperatorStatus`. After the
    ///         sortition pool state is in sync, authorization decrease delay
    ///         starts.
    ///
    ///         After authorization decrease delay passes, authorization
    ///         decrease request needs to be approved with a call to
    ///         `approveAuthorizationDecrease` function.
    ///
    ///         If there is a pending authorization decrease request, it is
    ///         overwritten, but only if enough time passed since the original
    ///         request. Otherwise, the function reverts.
    ///
    /// @dev Can only be called by T staking contract.
    function authorizationDecreaseRequested(
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external onlyStakingContract {
        authorization.authorizationDecreaseRequested(
            stakingProvider,
            fromAmount,
            toAmount
        );
    }

    /// @notice Approves the previously registered authorization decrease
    ///         request. Reverts if authorization decrease delay has not passed
    ///         yet or if the authorization decrease was not requested for the
    ///         given staking provider.
    function approveAuthorizationDecrease(address stakingProvider) external {
        authorization.approveAuthorizationDecrease(staking, stakingProvider);
    }

    /// @notice Used by T staking contract to inform the beacon the
    ///         authorization has been decreased for the given staking provider
    ///         involuntarily, as a result of slashing.
    ///
    ///         If the operator is not known (`registerOperator` was not called)
    ///         the function does nothing. The operator was never in a sortition
    ///         pool so there is nothing to update.
    ///
    ///         If the operator is known, sortition pool is unlocked, and the
    ///         operator is in the sortition pool, the sortition pool state is
    ///         updated. If the sortition pool is locked, update needs to be
    ///         postponed. Every other staker is incentivized to call
    ///         `updateOperatorStatus` for the problematic operator to increase
    ///         their own rewards in the pool.
    function involuntaryAuthorizationDecrease(
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external onlyStakingContract {
        authorization.involuntaryAuthorizationDecrease(
            staking,
            sortitionPool,
            stakingProvider,
            fromAmount,
            toAmount
        );
    }

    /// @notice Triggers group selection if there are no active groups.
    function genesis() external {
        require(groups.numberOfActiveGroups() == 0, "Not awaiting genesis");

        dkg.lockState();
        dkg.start(
            uint256(keccak256(abi.encodePacked(genesisSeed, block.number)))
        );
    }

    /// @notice Submits result of DKG protocol. It is on-chain part of phase 14 of
    ///         the protocol. The DKG result consists of result submitting member
    ///         index, calculated group public key, bytes array of misbehaved
    ///         members, concatenation of signatures from group members,
    ///         indices of members corresponding to each signature and
    ///         the list of group members.
    ///         When the result is verified successfully it gets registered and
    ///         waits for an approval. A result can be challenged to verify the
    ///         members list corresponds to the expected set of members determined
    ///         by the sortition pool.
    ///         A candidate group is registered based on the submitted DKG result
    ///         details.
    /// @dev The message to be signed by each member is keccak256 hash of the
    ///      chain ID, calculated group public key, misbehaved members as bytes
    ///      and DKG start block. The calculated hash should be prefixed with
    //       prefixed with
    ///      `\x19Ethereum signed message:\n` before signing, so the message to
    ///      sign is:
    ///      `\x19Ethereum signed message:\n${keccak256(chainID,groupPubKey,misbehaved,startBlock)}`
    /// @param dkgResult DKG result.
    function submitDkgResult(DKG.Result calldata dkgResult) external {
        groups.validatePublicKey(dkgResult.groupPubKey);
        dkg.submitResult(dkgResult);
    }

    /// @notice Notifies about DKG timeout.
    function notifyDkgTimeout() external refundable(msg.sender) {
        dkg.notifyTimeout();
    }

    /// @notice Approves DKG result. Can be called when the challenge period for
    ///         the submitted result is finished. Considers the submitted result
    ///         as valid, bans misbehaved group members from the sortition pool
    ///         rewards, and completes the group creation by activating the
    ///         candidate group. For the first `submitterPrecedencePeriodLength`
    ///         blocks after the end of the challenge period can be called only
    ///         by the DKG result submitter. After that time, can be called by
    ///         anyone.
    /// @param dkgResult Result to approve. Must match the submitted result
    ///        stored during `submitDkgResult`.
    function approveDkgResult(DKG.Result calldata dkgResult) external {
        uint256 gasStart = gasleft();

        uint32[] memory misbehavedMembers = dkg.approveResult(dkgResult);

        if (misbehavedMembers.length > 0) {
            sortitionPool.setRewardIneligibility(
                misbehavedMembers,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + _sortitionPoolRewardsBanDuration
            );
        }

        groups.addGroup(dkgResult.groupPubKey, dkgResult.membersHash);
        dkg.complete();

        // Refund msg.sender's ETH for DKG result submission and result approval
        reimbursementPool.refund(
            _dkgResultSubmissionGas +
                (gasStart - gasleft()) +
                _dkgResultApprovalGasOffset,
            msg.sender
        );
    }

    /// @notice Challenges DKG result. If the submitted result is proved to be
    ///         invalid it reverts the DKG back to the result submission phase.
    ///         It removes a candidate group that was previously registered with
    ///         the DKG result submission.
    /// @param dkgResult Result to challenge. Must match the submitted result
    ///        stored during `submitDkgResult`.
    /// @dev Due to EIP-150 1/64 of the gas is not forwarded to the call, and
    ///      will be kept to execute the remaining operations in the function
    ///      after the call inside the try-catch. To eliminate a class of
    ///      attacks related to the gas limit manipulation, this function
    ///      requires an extra amount of gas to be left at the end of the
    ///      execution.
    function challengeDkgResult(DKG.Result calldata dkgResult) external {
        (bytes32 maliciousResultHash, uint32 maliciousSubmitter) = dkg
            .challengeResult(dkgResult);

        uint96 slashingAmount = _maliciousDkgResultSlashingAmount;
        address maliciousSubmitterAddresses = sortitionPool.getIDOperator(
            maliciousSubmitter
        );

        address[] memory stakingProviderWrapper = new address[](1);
        stakingProviderWrapper[0] = operatorToStakingProvider(
            maliciousSubmitterAddresses
        );
        try
            staking.seize(
                slashingAmount,
                _dkgMaliciousResultNotificationRewardMultiplier,
                msg.sender,
                stakingProviderWrapper
            )
        {
            // slither-disable-next-line reentrancy-events
            emit DkgMaliciousResultSlashed(
                maliciousResultHash,
                slashingAmount,
                maliciousSubmitterAddresses
            );
        } catch {
            // Should never happen but we want to ensure a non-critical path
            // failure from an external contract does not stop the challenge
            // to complete.
            emit DkgMaliciousResultSlashingFailed(
                maliciousResultHash,
                slashingAmount,
                maliciousSubmitterAddresses
            );
        }

        // Due to EIP-150, 1/64 of the gas is not forwarded to the call, and
        // will be kept to execute the remaining operations in the function
        // after the call inside the try-catch.
        //
        // To ensure there is no way for the caller to manipulate gas limit in
        // such a way that the call inside try-catch fails with out-of-gas and
        // the rest of the function is executed with the remaining 1/64 of gas,
        // we require an extra gas amount to be left at the end of the call to
        // `challengeDkgResult`.
        dkg.requireChallengeExtraGas();
    }

    /// @notice Check current group creation state.
    function getGroupCreationState() external view returns (DKG.State) {
        return dkg.currentState();
    }

    /// @notice Checks if DKG timed out. The DKG timeout period includes time required
    ///         for off-chain protocol execution and time for the result publication
    ///         for all group members. After this time result cannot be submitted
    ///         and DKG can be notified about the timeout.
    /// @return True if DKG timed out, false otherwise.
    function hasDkgTimedOut() external view returns (bool) {
        return dkg.hasDkgTimedOut();
    }

    function getGroupsRegistry() external view returns (bytes32[] memory) {
        return groups.groupsRegistry;
    }

    function getGroup(uint64 groupId)
        external
        view
        returns (Groups.Group memory)
    {
        return groups.getGroup(groupId);
    }

    function getGroup(bytes memory groupPubKey)
        external
        view
        returns (Groups.Group memory)
    {
        return groups.getGroup(groupPubKey);
    }

    /// @notice Creates a request to generate a new relay entry, which will
    ///         include a random number (by signing the previous entry's
    ///         random number). Requester must be previously authorized by the
    ///         governance.
    /// @param callbackContract Beacon consumer callback contract.
    function requestRelayEntry(IRandomBeaconConsumer callbackContract)
        external
    {
        require(
            authorizedRequesters[msg.sender],
            "Requester must be authorized"
        );

        uint64 groupId = groups.selectGroup(
            uint256(keccak256(AltBn128.g1Marshal(relay.previousEntry)))
        );

        relay.requestEntry(groupId);

        callback.setCallbackContract(callbackContract);

        // If the current request should trigger group creation we need to lock
        // DKG state (lock sortition pool) to prevent operators from changing
        // its state before relay entry is known. That entry will be used as a
        // group selection seed.
        if (
            relay.requestCount % _groupCreationFrequency == 0 &&
            dkg.currentState() == DKG.State.IDLE
        ) {
            dkg.lockState();
        }
    }

    /// @notice Creates a new relay entry. Gas-optimized version that can be
    ///         called only before the soft timeout. This should be the majority
    ///         of cases.
    /// @param entry Group BLS signature over the previous entry.
    function submitRelayEntry(bytes calldata entry) external {
        uint256 gasStart = gasleft();

        Groups.Group storage group = groups.getGroup(
            relay.currentRequestGroupID
        );

        relay.submitEntryBeforeSoftTimeout(entry, group.groupPubKey);

        // If DKG is awaiting a seed, that means the we should start the actual
        // group creation process.
        if (dkg.currentState() == DKG.State.AWAITING_SEED) {
            dkg.start(uint256(keccak256(entry)));
        }

        callback.executeCallback(uint256(keccak256(entry)), _callbackGasLimit);

        reimbursementPool.refund(
            (gasStart - gasleft()) + _relayEntrySubmissionGasOffset,
            msg.sender
        );
    }

    /// @notice Creates a new relay entry.
    /// @param entry Group BLS signature over the previous entry.
    /// @param groupMembers Identifiers of group members.
    function submitRelayEntry(
        bytes calldata entry,
        uint32[] calldata groupMembers
    ) external {
        uint256 gasStart = gasleft();
        uint256 currentRequestId = relay.currentRequestID;

        Groups.Group storage group = groups.getGroup(
            relay.currentRequestGroupID
        );

        require(
            group.membersHash == keccak256(abi.encode(groupMembers)),
            "Invalid group members"
        );

        uint96 slashingAmount = relay.submitEntry(entry, group.groupPubKey);

        if (slashingAmount > 0) {
            address[] memory groupMembersAddresses = sortitionPool
                .getIDOperators(groupMembers);

            address[] memory stakingProvidersAddresses = new address[](
                groupMembersAddresses.length
            );
            for (uint256 i = 0; i < groupMembersAddresses.length; i++) {
                stakingProvidersAddresses[i] = operatorToStakingProvider(
                    groupMembersAddresses[i]
                );
            }

            try staking.slash(slashingAmount, stakingProvidersAddresses) {
                // slither-disable-next-line reentrancy-events
                emit RelayEntryDelaySlashed(
                    currentRequestId,
                    slashingAmount,
                    groupMembersAddresses
                );
            } catch {
                // Should never happen but we want to ensure a non-critical path
                // failure from an external contract does not stop group members
                // from submitting a valid relay entry.
                emit RelayEntryDelaySlashingFailed(
                    currentRequestId,
                    slashingAmount,
                    groupMembersAddresses
                );
            }
        }

        // If DKG is awaiting a seed, that means the we should start the actual
        // group creation process.
        if (dkg.currentState() == DKG.State.AWAITING_SEED) {
            dkg.start(uint256(keccak256(entry)));
        }

        callback.executeCallback(uint256(keccak256(entry)), _callbackGasLimit);
        reimbursementPool.refund(
            (gasStart - gasleft()) + _relayEntrySubmissionGasOffset,
            msg.sender
        );
    }

    /// @notice Reports a relay entry timeout.
    /// @param groupMembers Identifiers of group members.
    function reportRelayEntryTimeout(uint32[] calldata groupMembers) external {
        uint64 groupId = relay.currentRequestGroupID;
        Groups.Group storage group = groups.getGroup(groupId);

        require(
            group.membersHash == keccak256(abi.encode(groupMembers)),
            "Invalid group members"
        );

        uint96 slashingAmount = relay.relayEntrySubmissionFailureSlashingAmount;
        address[] memory groupMembersAddresses = sortitionPool.getIDOperators(
            groupMembers
        );

        address[] memory stakingProvidersAddresses = new address[](
            groupMembersAddresses.length
        );
        for (uint256 i = 0; i < groupMembersAddresses.length; i++) {
            stakingProvidersAddresses[i] = operatorToStakingProvider(
                groupMembersAddresses[i]
            );
        }

        try
            staking.seize(
                slashingAmount,
                _relayEntryTimeoutNotificationRewardMultiplier,
                msg.sender,
                stakingProvidersAddresses
            )
        {
            // slither-disable-next-line reentrancy-events
            emit RelayEntryTimeoutSlashed(
                relay.currentRequestID,
                slashingAmount,
                groupMembersAddresses
            );
        } catch {
            // Should never happen but we want to ensure a non-critical path
            // failure from an external contract does not stop the challenge
            // to complete.
            emit RelayEntryTimeoutSlashingFailed(
                relay.currentRequestID,
                slashingAmount,
                groupMembersAddresses
            );
        }

        groups.terminateGroup(groupId);
        groups.expireOldGroups();

        if (groups.numberOfActiveGroups() > 0) {
            groupId = groups.selectGroup(
                uint256(keccak256(AltBn128.g1Marshal(relay.previousEntry)))
            );
            relay.retryOnEntryTimeout(groupId);
        } else {
            relay.cleanupOnEntryTimeout();

            // If DKG is awaiting a seed, we should notify about its timeout to
            // avoid blocking the future group creation.
            if (dkg.currentState() == DKG.State.AWAITING_SEED) {
                dkg.notifySeedTimedOut();
            }
        }
    }

    /// @notice Reports unauthorized groups signing. Must provide a valid signature
    ///         of the sender's address as a message. Successful signature
    ///         verification means the private key has been leaked and all group
    ///         members should be punished by slashing their tokens. Group has
    ///         to be active or expired. Unauthorized signing cannot be reported
    ///         for a terminated group. In case of reporting unauthorized
    ///         signing for a terminated group, or when the signature is invalid,
    ///         function reverts.
    /// @param signedMsgSender Signature of the sender's address as a message.
    /// @param groupId Group that is being reported for leaking a private key.
    /// @param groupMembers Identifiers of group members.
    function reportUnauthorizedSigning(
        bytes memory signedMsgSender,
        uint64 groupId,
        uint32[] calldata groupMembers
    ) external {
        Groups.Group memory group = groups.getGroup(groupId);

        require(
            group.membersHash == keccak256(abi.encode(groupMembers)),
            "Invalid group members"
        );

        require(!group.terminated, "Group cannot be terminated");

        require(
            BLS.verifyBytes(
                group.groupPubKey,
                abi.encodePacked(msg.sender),
                signedMsgSender
            ),
            "Invalid signature"
        );

        groups.terminateGroup(groupId);

        address[] memory groupMembersAddresses = sortitionPool.getIDOperators(
            groupMembers
        );

        address[] memory stakingProvidersAddresses = new address[](
            groupMembersAddresses.length
        );
        for (uint256 i = 0; i < groupMembersAddresses.length; i++) {
            stakingProvidersAddresses[i] = operatorToStakingProvider(
                groupMembersAddresses[i]
            );
        }

        try
            staking.seize(
                _unauthorizedSigningSlashingAmount,
                _unauthorizedSigningNotificationRewardMultiplier,
                msg.sender,
                stakingProvidersAddresses
            )
        {
            // slither-disable-next-line reentrancy-events
            emit UnauthorizedSigningSlashed(
                groupId,
                _unauthorizedSigningSlashingAmount,
                groupMembersAddresses
            );
        } catch {
            // Should never happen but we want to ensure a non-critical path
            // failure from an external contract does not stop the challenge
            // to complete.
            emit UnauthorizedSigningSlashingFailed(
                groupId,
                _unauthorizedSigningSlashingAmount,
                groupMembersAddresses
            );
        }
    }

    /// @notice Notifies about operators who are inactive. Using this function,
    ///         a majority of the group can decide about punishing specific
    ///         group members who constantly fail doing their job. If the provided
    ///         claim is proved to be valid and signed by sufficient number
    ///         of group members, operators of members deemed as inactive are
    ///         banned for sortition pool rewards for duration specified by
    ///         `_sortitionPoolRewardsBanDuration` parameter. The sender of
    ///         the claim must be one of the claim signers. This function can be
    ///         called only for active and non-terminated groups.
    /// @param claim Operator inactivity claim.
    /// @param nonce Current inactivity claim nonce for the given group. Must
    ///        be the same as the stored one.
    /// @param groupMembers Identifiers of group members.
    function notifyOperatorInactivity(
        Inactivity.Claim calldata claim,
        uint256 nonce,
        uint32[] calldata groupMembers
    ) external {
        uint256 gasStart = gasleft();
        uint64 groupId = claim.groupId;

        require(nonce == inactivityClaimNonce[groupId], "Invalid nonce");

        require(groups.isGroupActive(groupId), "Group is not active");

        Groups.Group storage group = groups.getGroup(groupId);

        require(
            group.membersHash == keccak256(abi.encode(groupMembers)),
            "Invalid group members"
        );

        uint32[] memory ineligibleOperators = Inactivity.verifyClaim(
            sortitionPool,
            claim,
            group.groupPubKey,
            nonce,
            groupMembers
        );

        inactivityClaimNonce[groupId]++;

        emit InactivityClaimed(groupId, nonce, msg.sender);

        sortitionPool.setRewardIneligibility(
            ineligibleOperators,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp + _sortitionPoolRewardsBanDuration
        );

        reimbursementPool.refund(
            (gasStart - gasleft()) + _notifyOperatorInactivityGasOffset,
            msg.sender
        );
    }

    /// @notice The minimum authorization amount required so that operator can
    ///         participate in the random beacon. This amount is required to
    ///         execute slashing for providing a malicious DKG result or when
    ///         a relay entry times out.
    function minimumAuthorization() external view returns (uint96) {
        return authorization.parameters.minimumAuthorization;
    }

    /// @return Flag indicating whether a relay entry request is currently
    ///         in progress.
    function isRelayRequestInProgress() external view returns (bool) {
        return relay.isRequestInProgress();
    }

    /// @notice Returns the current value of the staking provider's eligible
    ///         stake. Eligible stake is defined as the currently authorized
    ///         stake minus the pending authorization decrease. Eligible stake
    ///         is what is used for operator's weight in the sortition pool.
    ///         If the authorized stake minus the pending authorization decrease
    ///         is below the minimum authorization, eligible stake is 0.
    function eligibleStake(address stakingProvider)
        external
        view
        returns (uint96)
    {
        return authorization.eligibleStake(staking, stakingProvider);
    }

    /// @notice Returns the amount of rewards available for withdrawal for the
    ///         given staking provider. Reverts if staking provider has not
    ///         registered the operator address.
    function availableRewards(address stakingProvider)
        external
        view
        returns (uint96)
    {
        address operator = stakingProviderToOperator(stakingProvider);
        require(operator != address(0), "Unknown operator");
        return sortitionPool.getAvailableRewards(operator);
    }

    /// @notice Returns the amount of stake that is pending authorization
    ///         decrease for the given staking provider. If no authorization
    ///         decrease has been requested, returns zero.
    function pendingAuthorizationDecrease(address stakingProvider)
        external
        view
        returns (uint96)
    {
        return authorization.pendingAuthorizationDecrease(stakingProvider);
    }

    /// @notice Returns the remaining time in seconds that needs to pass before
    ///         the requested authorization decrease can be approved.
    ///         If the sortition pool state was not updated yet by the operator
    ///         after requesting the authorization decrease, returns
    ///         `type(uint64).max`.
    function remainingAuthorizationDecreaseDelay(address stakingProvider)
        external
        view
        returns (uint64)
    {
        return
            authorization.remainingAuthorizationDecreaseDelay(stakingProvider);
    }

    /// @notice Returns operator registered for the given staking provider.
    function stakingProviderToOperator(address stakingProvider)
        public
        view
        returns (address)
    {
        return authorization.stakingProviderToOperator[stakingProvider];
    }

    /// @notice Returns staking provider of the given operator.
    function operatorToStakingProvider(address operator)
        public
        view
        returns (address)
    {
        return authorization.operatorToStakingProvider[operator];
    }

    /// @notice Checks if the operator's authorized stake is in sync with
    ///         operator's weight in the sortition pool.
    ///         If the operator is not in the sortition pool and their
    ///         authorized stake is non-zero, function returns false.
    function isOperatorUpToDate(address operator) external view returns (bool) {
        return
            authorization.isOperatorUpToDate(staking, sortitionPool, operator);
    }

    /// @notice Returns true if the given operator is in the sortition pool.
    ///         Otherwise, returns false.
    function isOperatorInPool(address operator) external view returns (bool) {
        return sortitionPool.isOperatorInPool(operator);
    }

    /// @notice Selects a new group of operators. Can only be called when DKG
    ///         is in progress and the pool is locked.
    ///         At least one operator has to be registered in the pool,
    ///         otherwise the function fails reverting the transaction.
    /// @return IDs of selected group members.
    function selectGroup() external view returns (uint32[] memory) {
        return sortitionPool.selectGroup(DKG.groupSize, bytes32(dkg.seed));
    }

    /// @notice Returns authorization-related parameters of the beacon.
    /// @dev The minimum authorization is also returned by `minimumAuthorization()`
    ///      function, as a requirement of `IApplication` interface.
    /// @return minimumAuthorization The minimum authorization amount required
    ///         so that operator can participate in the random beacon. This
    ///         amount is required to execute slashing for providing a malicious
    ///         DKG result or when a relay entry times out.
    /// @return authorizationDecreaseDelay Delay in seconds that needs to pass
    ///         between the time authorization decrease is requested and the
    ///         time that request gets approved. Protects against free-riders
    ///         earning rewards and not being active in the network.
    /// @return authorizationDecreaseChangePeriod Authorization decrease change
    ///        period in seconds. It is the time, before authorization decrease
    ///        delay end, during which the pending authorization decrease
    ///        request can be overwritten.
    ///        If set to 0, pending authorization decrease request can not be
    ///        overwritten until the entire `authorizationDecreaseDelay` ends.
    ///        If set to value equal `authorizationDecreaseDelay`, request can
    ///        always be overwritten.
    function authorizationParameters()
        external
        view
        returns (
            uint96 minimumAuthorization,
            uint64 authorizationDecreaseDelay,
            uint64 authorizationDecreaseChangePeriod
        )
    {
        return (
            authorization.parameters.minimumAuthorization,
            authorization.parameters.authorizationDecreaseDelay,
            authorization.parameters.authorizationDecreaseChangePeriod
        );
    }

    /// @notice Returns relay-entry-related parameters of the beacon.
    /// @return relayEntrySoftTimeout Soft timeout in blocks for a group to
    ///         submit the relay entry. If the soft timeout is reached for
    ///         submitting the relay entry, the slashing starts.
    /// @return relayEntryHardTimeout Hard timeout in blocks for a group to
    ///         submit the relay entry. After the soft timeout passes without
    ///         relay entry submitted, all group members start getting slashed.
    ///         The slashing amount increases linearly until the group submits
    ///         the relay entry or until `relayEntryHardTimeout` is reached.
    ///         When the hard timeout is reached, each group member will get
    ///         slashed for `_relayEntrySubmissionFailureSlashingAmount`.
    /// @return callbackGasLimit Relay entry callback gas limit. This is the gas
    ///         limit with which callback function provided in the relay request
    ///         transaction is executed. The callback is executed with a new
    ///         relay entry value in the same transaction the relay entry is
    ///         submitted.
    function relayEntryParameters()
        external
        view
        returns (
            uint256 relayEntrySoftTimeout,
            uint256 relayEntryHardTimeout,
            uint256 callbackGasLimit
        )
    {
        return (
            relay.relayEntrySoftTimeout,
            relay.relayEntryHardTimeout,
            _callbackGasLimit
        );
    }

    /// @notice Returns group-creation-related parameters of the beacon.
    /// @return groupCreationFrequency The frequency of a new group creation.
    ///         Groups are created with a fixed frequency of relay requests.
    /// @return groupLifetime Group lifetime in blocks. When a group reached its
    ///         lifetime, it is no longer selected for new relay requests but
    ///         may still be responsible for submitting relay entry if relay
    ///         request assigned to that group is still pending.
    /// @return dkgResultChallengePeriodLength The number of blocks for which
    ///         a DKG result can be challenged. Anyone can challenge DKG result
    ///         for a certain number of blocks before the result is fully
    ///         accepted and the group registered in the pool of active groups.
    ///         If the challenge gets accepted, all operators who signed the
    ///         malicious result get slashed for and the notifier gets rewarded.
    /// @return dkgResultChallengeExtraGas The extra gas required to be left at
    ///         the end of the challenge DKG result transaction.
    /// @return dkgResultSubmissionTimeout Timeout in blocks for a group to
    ///         submit the DKG result. All members are eligible to submit the
    ///         DKG result. If `dkgResultSubmissionTimeout` passes without the
    ///         DKG result submitted, DKG is considered as timed out and no DKG
    ///         result for this group creation can be submitted anymore.
    /// @return dkgSubmitterPrecedencePeriodLength Time during the DKG result
    ///         approval stage when the submitter of the DKG result takes the
    ///         precedence to approve the DKG result. After this time passes
    ///         anyone can approve the DKG result.
    function groupCreationParameters()
        external
        view
        returns (
            uint256 groupCreationFrequency,
            uint256 groupLifetime,
            uint256 dkgResultChallengePeriodLength,
            uint256 dkgResultChallengeExtraGas,
            uint256 dkgResultSubmissionTimeout,
            uint256 dkgSubmitterPrecedencePeriodLength
        )
    {
        return (
            _groupCreationFrequency,
            groups.groupLifetime,
            dkg.parameters.resultChallengePeriodLength,
            dkg.parameters.resultChallengeExtraGas,
            dkg.parameters.resultSubmissionTimeout,
            dkg.parameters.submitterPrecedencePeriodLength
        );
    }

    /// @notice Returns reward-related parameters of the beacon.
    /// @return sortitionPoolRewardsBanDuration Duration of the sortition pool
    ///         rewards ban imposed on operators who misbehaved during DKG by
    ///         being inactive or disqualified and for operators that were
    ///         identified by the rest of group members as inactive via
    ///         `notifyOperatorInactivity`.
    /// @return relayEntryTimeoutNotificationRewardMultiplier Percentage of the
    ///         staking contract malicious behavior notification reward which
    ///         will be transferred to the notifier reporting about relay entry
    ///         timeout. Notifiers are rewarded from a notifiers treasury pool.
    ///         For example, if notification reward is 1000 and the value of the
    ///         multiplier is 5, the notifier will receive: 5% of 1000 = 50 per
    ///         each operator affected.
    /// @return unauthorizedSigningNotificationRewardMultiplier Percentage of the
    ///         staking contract malicious behavior notification reward which
    ///         will be transferred to the notifier reporting about unauthorized
    ///         signing. Notifiers are rewarded from a notifiers treasury pool.
    ///         For example, if a notification reward is 1000 and the value of
    ///         the multiplier is 5, the notifier will receive: 5% of 1000 = 50
    ///         per each operator affected.
    /// @return dkgMaliciousResultNotificationRewardMultiplier Percentage of the
    ///         staking contract malicious behavior notification reward which
    ///         will be transferred to the notifier reporting about a malicious
    ///         DKG result. Notifiers are rewarded from a notifiers treasury
    ///         pool. For example, if notification reward is 1000 and the value
    ///         of the multiplier is 5, the notifier will receive:
    ///         5% of 1000 = 50 per each operator affected.
    function rewardParameters()
        external
        view
        returns (
            uint256 sortitionPoolRewardsBanDuration,
            uint256 relayEntryTimeoutNotificationRewardMultiplier,
            uint256 unauthorizedSigningNotificationRewardMultiplier,
            uint256 dkgMaliciousResultNotificationRewardMultiplier
        )
    {
        return (
            _sortitionPoolRewardsBanDuration,
            _relayEntryTimeoutNotificationRewardMultiplier,
            _unauthorizedSigningNotificationRewardMultiplier,
            _dkgMaliciousResultNotificationRewardMultiplier
        );
    }

    /// @notice Returns slashing-related parameters of the beacon.
    /// @return relayEntrySubmissionFailureSlashingAmount Slashing amount for
    ///         not submitting relay entry. When relay entry hard timeout is
    ///         reached without the relay entry submitted, each group member
    ///         gets slashed for `relayEntrySubmissionFailureSlashingAmount`.
    ///         If the relay entry gets submitted after the soft timeout, but
    ///         before the hard timeout, each group member gets slashed
    ///         proportionally to `relayEntrySubmissionFailureSlashingAmount`
    ///         and the time passed since the soft deadline.
    /// @return maliciousDkgResultSlashingAmount Slashing amount for submitting
    ///         a malicious DKG result. Every DKG result submitted can be
    ///         challenged for the time of `dkg.ResultChallengePeriodLength`.
    ///         If the DKG result submitted is challenged and proven to be
    ///         malicious, the operator who submitted the malicious result is
    ///         slashed for `maliciousDkgResultSlashingAmount`.
    /// @return unauthorizedSigningSlashingAmount Slashing amount when an
    ///         unauthorized signing has been proved, which means the private
    ///         key leaked and all the group members should be punished.
    function slashingParameters()
        external
        view
        returns (
            uint96 relayEntrySubmissionFailureSlashingAmount,
            uint96 maliciousDkgResultSlashingAmount,
            uint96 unauthorizedSigningSlashingAmount
        )
    {
        return (
            relay.relayEntrySubmissionFailureSlashingAmount,
            _maliciousDkgResultSlashingAmount,
            _unauthorizedSigningSlashingAmount
        );
    }

    /// @notice Returns gas-related parameters of the beacon.
    /// @return dkgResultSubmissionGas Calculated gas cost for submitting a DKG
    ///         result. This will be refunded as part of the DKG approval
    ///         process.
    /// @return dkgResultApprovalGasOffset Gas that is meant to balance the DKG
    ///         result approval's overall cost.
    /// @return notifyOperatorInactivityGasOffset Gas that is meant to balance
    ///         the operator inactivity notification cost.
    /// @return relayEntrySubmissionGasOffset Gas that is meant to balance the
    ///         relay entry submission cost.
    function gasParameters()
        external
        view
        returns (
            uint256 dkgResultSubmissionGas,
            uint256 dkgResultApprovalGasOffset,
            uint256 notifyOperatorInactivityGasOffset,
            uint256 relayEntrySubmissionGasOffset
        )
    {
        return (
            _dkgResultSubmissionGas,
            _dkgResultApprovalGasOffset,
            _notifyOperatorInactivityGasOffset,
            _relayEntrySubmissionGasOffset
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "./IRandomBeaconConsumer.sol";

/// @title Random Beacon interface
interface IRandomBeacon {
    /// @notice Creates a request to generate a new relay entry. Requires a
    ///         request fee denominated in T token.
    /// @param callbackContract Beacon consumer callback contract.
    function requestRelayEntry(IRandomBeaconConsumer callbackContract) external;
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

/// @notice This library is used as a registry of created groups.
/// @dev This library should be used along with DKG library that ensures linear
///      groups creation (only one group creation happens at a time). A candidate
///      group has to be popped or activated before adding a new candidate group.
library Groups {
    struct Group {
        bytes groupPubKey;
        uint256 registrationBlockNumber;
        // Keccak256 hash of group members identifiers array. Group members do not
        // include operators selected by the sortition pool that misbehaved during DKG.
        // See how `misbehavedMembersIndices` are used in `hashGroupMembers` function.
        bytes32 membersHash;
        // When selected group does not create a relay entry on-time it should
        // be marked as terminated.
        bool terminated;
    }

    struct Data {
        // Mapping of keccak256 hashes of group public keys to groups details.
        mapping(bytes32 => Group) groupsData;
        // Holds keccak256 hashes of group public keys in the order of registration.
        bytes32[] groupsRegistry;
        // Group ids that were active but failed creating a relay entry. When an
        // active-terminated group qualifies to become 'expired', then it will
        // be removed from this array.
        uint64[] activeTerminatedGroups;
        // Points to the first active group, it is also the expired groups counter.
        uint64 expiredGroupOffset;
        // Group lifetime in blocks. When a group reached its lifetime, it
        // is no longer selected for new relay requests but may still be
        // responsible for submitting relay entry if relay request assigned
        // to that group is still pending.
        uint256 groupLifetime;
    }

    event GroupRegistered(uint64 indexed groupId, bytes indexed groupPubKey);

    /// @notice Performs preliminary validation of a new group public key.
    ///         The group public key must be unique and have 128 bytes in length.
    ///         If the validation fails, the function reverts. This function
    ///         must be called first for a public key of a group added with
    ///         `addGroup` function.
    /// @param groupPubKey Candidate group public key
    function validatePublicKey(Data storage self, bytes calldata groupPubKey)
        internal
        view
    {
        require(groupPubKey.length == 128, "Invalid length of the public key");

        bytes32 groupPubKeyHash = keccak256(groupPubKey);

        require(
            self.groupsData[groupPubKeyHash].registrationBlockNumber == 0,
            "Group with this public key was already registered"
        );
    }

    /// @notice Adds a new candidate group. The group is stored with group public
    ///         key and group members, but is not yet activated.
    /// @dev The group members list is stored with all misbehaved members filtered out.
    ///      The code calling this function should ensure that the number of
    ///      candidate (not activated) groups is never more than one.
    /// @param groupPubKey Generated candidate group public key
    /// @param membersHash Keccak256 hash of members that actively took part in DKG.
    function addGroup(
        Data storage self,
        bytes calldata groupPubKey,
        bytes32 membersHash
    ) internal {
        bytes32 groupPubKeyHash = keccak256(groupPubKey);

        // We use group from storage that is assumed to be a struct set to the
        // default values. We need to remember to overwrite fields in case a
        // candidate group was already registered before and popped.
        Group storage group = self.groupsData[groupPubKeyHash];
        group.groupPubKey = groupPubKey;
        group.membersHash = membersHash;
        group.registrationBlockNumber = block.number;

        self.groupsRegistry.push(groupPubKeyHash);

        emit GroupRegistered(
            uint64(self.groupsRegistry.length - 1),
            groupPubKey
        );
    }

    /// @notice Goes through groups starting from the oldest one that is still
    ///         active and checks if it hasn't expired. If so, updates the information
    ///         about expired groups so that all expired groups are marked as such.
    function expireOldGroups(Data storage self) internal {
        // Move expiredGroupOffset as long as there are some groups that should
        // be marked as expired. It is possible that expired group offset will
        // move out of the groups array by one position. It means that all groups
        // are expired (it points to the first active group) and that place in
        // groups array - currently empty - will be possibly filled later by
        // a new group.
        while (
            self.expiredGroupOffset < self.groupsRegistry.length &&
            groupLifetimeOf(
                self,
                self.groupsRegistry[self.expiredGroupOffset]
            ) <
            block.number
        ) {
            self.expiredGroupOffset++;
        }

        // Go through all activeTerminatedGroups and if some of the terminated
        // groups are expired, remove them from activeTerminatedGroups collection
        // and rearrange the array to preserve the original order.
        // This is needed because we evaluate the shift of selected group index
        // based on how many non-expired groups have been terminated. Hence it is
        // important that a number of terminated groups matches the length of
        // activeTerminatedGroups[].
        uint256 i = 0;
        while (i < self.activeTerminatedGroups.length) {
            if (self.expiredGroupOffset > self.activeTerminatedGroups[i]) {
                // When 'i'th group qualifies for expiration, we need to remove
                // it from the activeTerminatedGroups array manually by rearranging
                // the order starting from 'i'th group.
                for (
                    uint256 j = i;
                    j < self.activeTerminatedGroups.length - 1;
                    j++
                ) {
                    self.activeTerminatedGroups[j] = self
                        .activeTerminatedGroups[j + 1];
                }
                // Resizing the array length by 1. The last element was copied
                // over in the loop above to an index "second to last". This is
                // why we can safely remove it from here.
                self.activeTerminatedGroups.pop();
            } else {
                i++;
            }
        }
    }

    /// @notice Terminates group with the provided index. Reverts if the group
    ///         is already terminated.
    /// @param  groupId Index in the groupRegistry array.
    function terminateGroup(Data storage self, uint64 groupId) internal {
        require(
            !isGroupTerminated(self, groupId),
            "Group has been already terminated"
        );
        self.groupsData[self.groupsRegistry[groupId]].terminated = true;
        // Expanding array for a new terminated group that is added below during
        // sortition in ascending order.
        self.activeTerminatedGroups.push();

        // Sorting activeTerminatedGroups by groupId in ascending order so a
        // non-terminated group is properly selected.
        uint256 i;
        for (
            i = self.activeTerminatedGroups.length - 1;
            i > 0 && self.activeTerminatedGroups[i - 1] > groupId;
            i--
        ) {
            self.activeTerminatedGroups[i] = self.activeTerminatedGroups[i - 1];
        }
        self.activeTerminatedGroups[i] = groupId;
    }

    /// @notice Returns an index of a randomly selected active group. Terminated
    ///         and expired groups are not considered as active.
    ///         Before new group is selected, information about expired groups
    ///         is updated. At least one active group needs to be present for this
    ///         function to succeed.
    /// @param seed Random number used as a group selection seed.
    function selectGroup(Data storage self, uint256 seed)
        internal
        returns (uint64)
    {
        expireOldGroups(self);

        require(numberOfActiveGroups(self) > 0, "No active groups");

        uint64 selectedGroup = uint64(seed % numberOfActiveGroups(self));
        uint64 result = shiftByTerminatedGroups(
            self,
            shiftByExpiredGroups(self, selectedGroup)
        );
        return result;
    }

    /// @notice Setter for group lifetime.
    /// @param lifetime Lifetime of a group in blocks.
    function setGroupLifetime(Data storage self, uint256 lifetime) internal {
        self.groupLifetime = lifetime;
    }

    /// @notice Checks if group with the given index is terminated.
    function isGroupTerminated(Data storage self, uint64 groupId)
        internal
        view
        returns (bool)
    {
        return self.groupsData[self.groupsRegistry[groupId]].terminated;
    }

    /// @notice Gets the cutoff time until which the given group is considered
    ///         to be active assuming it hasn't been terminated before.
    function groupLifetimeOf(Data storage self, bytes32 groupPubKeyHash)
        internal
        view
        returns (uint256)
    {
        return
            self.groupsData[groupPubKeyHash].registrationBlockNumber +
            self.groupLifetime;
    }

    /// @notice Checks if group with the given index is active and non-terminated.
    function isGroupActive(Data storage self, uint64 groupId)
        internal
        view
        returns (bool)
    {
        return
            groupLifetimeOf(self, self.groupsRegistry[groupId]) >=
            block.number &&
            !isGroupTerminated(self, groupId);
    }

    function getGroup(Data storage self, uint64 groupId)
        internal
        view
        returns (Group storage)
    {
        return self.groupsData[self.groupsRegistry[groupId]];
    }

    function getGroup(Data storage self, bytes memory groupPubKey)
        internal
        view
        returns (Group storage)
    {
        return self.groupsData[keccak256(groupPubKey)];
    }

    /// @notice Gets the number of active groups. Expired and terminated
    ///         groups are not counted as active.
    function numberOfActiveGroups(Data storage self)
        internal
        view
        returns (uint64)
    {
        if (self.groupsRegistry.length == 0) {
            return 0;
        }

        uint256 activeGroups = self.groupsRegistry.length -
            self.expiredGroupOffset -
            self.activeTerminatedGroups.length;

        return uint64(activeGroups);
    }

    /// @notice Evaluates the shift of a selected group index based on the number
    ///         of expired groups.
    function shiftByExpiredGroups(Data storage self, uint64 selectedIndex)
        internal
        view
        returns (uint64)
    {
        return self.expiredGroupOffset + selectedIndex;
    }

    /// @notice Evaluates the shift of a selected group index based on the number
    ///         of non-expired but terminated groups.
    function shiftByTerminatedGroups(Data storage self, uint64 selectedIndex)
        internal
        view
        returns (uint64)
    {
        uint64 shiftedIndex = selectedIndex;
        for (uint64 i = 0; i < self.activeTerminatedGroups.length; i++) {
            if (self.activeTerminatedGroups[i] <= shiftedIndex) {
                shiftedIndex++;
            }
        }

        return shiftedIndex;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./AltBn128.sol";
import "./BLS.sol";
import "./Groups.sol";

library Relay {
    using SafeERC20 for IERC20;

    struct Data {
        // Total count of all requests.
        uint64 requestCount;
        // Data of current request.
        // Request identifier.
        uint64 currentRequestID;
        // Identifier of group responsible for signing.
        uint64 currentRequestGroupID;
        // Request start block.
        uint64 currentRequestStartBlock;
        // Previous entry value.
        AltBn128.G1Point previousEntry;
        // Time in blocks during which a result is expected to be submitted.
        uint32 relayEntrySoftTimeout;
        // Hard timeout in blocks for a group to submit the relay entry.
        uint32 relayEntryHardTimeout;
        // Slashing amount for not submitting relay entry
        uint96 relayEntrySubmissionFailureSlashingAmount;
    }

    /// @notice Seed used as the first relay entry value.
    /// It's a G1 point G * PI =
    /// G * 31415926535897932384626433832795028841971693993751058209749445923078164062862
    /// Where G is the generator of G1 abstract cyclic group.
    bytes public constant relaySeed =
        hex"15c30f4b6cf6dbbcbdcc10fe22f54c8170aea44e198139b776d512d8f027319a1b9e8bfaf1383978231ce98e42bafc8129f473fc993cf60ce327f7d223460663";

    event RelayEntryRequested(
        uint256 indexed requestId,
        uint64 groupId,
        bytes previousEntry
    );

    event RelayEntrySubmitted(
        uint256 indexed requestId,
        address submitter,
        bytes entry
    );

    event RelayEntryTimedOut(
        uint256 indexed requestId,
        uint64 terminatedGroupId
    );

    /// @notice Initializes the very first `previousEntry` with an initial
    ///         `relaySeed` value. Can be performed only once.
    function initSeedEntry(Data storage self) internal {
        require(
            self.previousEntry.x == 0 && self.previousEntry.y == 0,
            "Seed entry already initialized"
        );
        self.previousEntry = AltBn128.g1Unmarshal(relaySeed);
    }

    /// @notice Creates a request to generate a new relay entry, which will
    ///         include a random number (by signing the previous entry's
    ///         random number).
    /// @param groupId Identifier of the group chosen to handle the request.
    function requestEntry(Data storage self, uint64 groupId) internal {
        require(
            !isRequestInProgress(self),
            "Another relay request in progress"
        );

        uint64 currentRequestId = ++self.requestCount;

        self.currentRequestID = currentRequestId;
        self.currentRequestGroupID = groupId;
        self.currentRequestStartBlock = uint64(block.number);

        emit RelayEntryRequested(
            currentRequestId,
            groupId,
            AltBn128.g1Marshal(self.previousEntry)
        );
    }

    /// @notice Creates a new relay entry. Gas-optimized version that can be
    ///         called only before the soft timeout. This should be the majority
    ///         of cases.
    /// @param entry Group BLS signature over the previous entry.
    /// @param groupPubKey Public key of the group which signed the relay entry.
    function submitEntryBeforeSoftTimeout(
        Data storage self,
        bytes calldata entry,
        bytes storage groupPubKey
    ) internal {
        require(
            block.number < softTimeoutBlock(self),
            "Relay entry soft timeout passed"
        );
        _submitEntry(self, entry, groupPubKey);
    }

    /// @notice Creates a new relay entry. Can be called at any time.
    ///         In case the soft timeout has not been exceeded, it is more
    ///         gas-efficient to call the second variation of `submitEntry`.
    /// @param entry Group BLS signature over the previous entry.
    /// @param groupPubKey Public key of the group which signed the relay entry.
    /// @return slashingAmount Amount by which group members should be slashed
    ///         in case the relay entry was submitted after the soft timeout.
    ///         The value is zero if entry was submitted on time.
    function submitEntry(
        Data storage self,
        bytes calldata entry,
        bytes storage groupPubKey
    ) internal returns (uint96) {
        // If the soft timeout has been exceeded apply stake slashing for
        // all group members. Otherwise, no slashing.
        uint96 slashingAmount = calculateSlashingAmount(self);

        _submitEntry(self, entry, groupPubKey);

        return slashingAmount;
    }

    function _submitEntry(
        Data storage self,
        bytes calldata entry,
        bytes storage groupPubKey
    ) internal {
        require(isRequestInProgress(self), "No relay request in progress");
        require(!hasRequestTimedOut(self), "Relay request timed out");

        require(
            BLS._verify(
                AltBn128.g2Unmarshal(groupPubKey),
                self.previousEntry,
                AltBn128.g1Unmarshal(entry)
            ),
            "Invalid entry"
        );

        emit RelayEntrySubmitted(self.currentRequestID, msg.sender, entry);

        self.previousEntry = AltBn128.g1Unmarshal(entry);
        self.currentRequestID = 0;
        self.currentRequestGroupID = 0;
        self.currentRequestStartBlock = 0;
    }

    /// @notice Calculates the slashing amount for all group members.
    /// @dev Must be used when a soft timeout was hit.
    /// @return Amount by which group members should be slashed
    ///         in case the relay entry was submitted after the soft timeout.
    function calculateSlashingAmount(Data storage self)
        internal
        view
        returns (uint96)
    {
        uint256 softTimeout = softTimeoutBlock(self);

        if (block.number > softTimeout) {
            uint256 submissionDelay = block.number - softTimeout;
            // The slashing amount is a result of a calculated portion of the submission
            // delay blocks. The max delay can be set up to relayEntryHardTimeout, which
            // in consequence sets the max slashing amount.
            if (submissionDelay > self.relayEntryHardTimeout) {
                submissionDelay = self.relayEntryHardTimeout;
            }

            return
                uint96(
                    (submissionDelay *
                        self.relayEntrySubmissionFailureSlashingAmount) /
                        self.relayEntryHardTimeout
                );
        }

        return 0;
    }

    /// @notice Updates relay-related parameters
    /// @param _relayEntrySoftTimeout New relay entry soft timeout value.
    ///        It is the time in blocks during which a result is expected to be
    ///        submitted so that the group is not slashed.
    /// @param _relayEntryHardTimeout New relay entry hard timeout value.
    ///        It is the time in blocks for a group to submit the relay entry
    ///        before slashing for the full slashing amount happens.
    function setTimeouts(
        Data storage self,
        uint256 _relayEntrySoftTimeout,
        uint256 _relayEntryHardTimeout
    ) internal {
        require(!isRequestInProgress(self), "Relay request in progress");

        self.relayEntrySoftTimeout = uint32(_relayEntrySoftTimeout);
        self.relayEntryHardTimeout = uint32(_relayEntryHardTimeout);
    }

    /// @notice Set relayEntrySubmissionFailureSlashingAmount parameter.
    /// @param newRelayEntrySubmissionFailureSlashingAmount New value of
    ///        the parameter.
    function setRelayEntrySubmissionFailureSlashingAmount(
        Data storage self,
        uint96 newRelayEntrySubmissionFailureSlashingAmount
    ) internal {
        require(!isRequestInProgress(self), "Relay request in progress");

        self
            .relayEntrySubmissionFailureSlashingAmount = newRelayEntrySubmissionFailureSlashingAmount;
    }

    /// @notice Retries the current relay request in case a relay entry
    ///         timeout was reported.
    /// @param newGroupId ID of the group chosen to retry the current request.
    function retryOnEntryTimeout(Data storage self, uint64 newGroupId)
        internal
    {
        require(hasRequestTimedOut(self), "Relay request did not time out");

        uint64 currentRequestId = self.currentRequestID;
        uint64 previousGroupId = self.currentRequestGroupID;

        emit RelayEntryTimedOut(currentRequestId, previousGroupId);

        self.currentRequestGroupID = newGroupId;
        self.currentRequestStartBlock = uint64(block.number);

        emit RelayEntryRequested(
            currentRequestId,
            newGroupId,
            AltBn128.g1Marshal(self.previousEntry)
        );
    }

    /// @notice Cleans up the current relay request in case a relay entry
    ///         timeout was reported.
    function cleanupOnEntryTimeout(Data storage self) internal {
        require(hasRequestTimedOut(self), "Relay request did not time out");

        emit RelayEntryTimedOut(
            self.currentRequestID,
            self.currentRequestGroupID
        );

        self.currentRequestID = 0;
        self.currentRequestGroupID = 0;
        self.currentRequestStartBlock = 0;
    }

    /// @notice Returns whether a relay entry request is currently in progress.
    /// @return True if there is a request in progress. False otherwise.
    function isRequestInProgress(Data storage self)
        internal
        view
        returns (bool)
    {
        return self.currentRequestID != 0;
    }

    /// @notice Returns whether the current relay request has timed out.
    /// @return True if the request timed out. False otherwise.
    function hasRequestTimedOut(Data storage self)
        internal
        view
        returns (bool)
    {
        uint256 _relayEntryTimeout = self.relayEntrySoftTimeout +
            self.relayEntryHardTimeout;

        return
            isRequestInProgress(self) &&
            block.number > self.currentRequestStartBlock + _relayEntryTimeout;
    }

    /// @notice Calculates soft timeout block for the pending relay request.
    /// @return The soft timeout block
    function softTimeoutBlock(Data storage self)
        internal
        view
        returns (uint256)
    {
        return self.currentRequestStartBlock + self.relayEntrySoftTimeout;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

import "../api/IRandomBeaconConsumer.sol";

/// @title Callback library
/// @dev Library for handling calls to random beacon consumer.
library Callback {
    struct Data {
        IRandomBeaconConsumer callbackContract;
    }

    event CallbackFailed(uint256 entry, uint256 entrySubmittedBlock);

    /// @notice Sets callback contract.
    /// @param callbackContract Callback contract.
    function setCallbackContract(
        Data storage self,
        IRandomBeaconConsumer callbackContract
    ) internal {
        self.callbackContract = callbackContract;
    }

    /// @notice Executes consumer specified callback for the relay entry request.
    /// @param entry The generated random number.
    /// @param callbackGasLimit Callback gas limit.
    function executeCallback(
        Data storage self,
        uint256 entry,
        uint256 callbackGasLimit
    ) internal {
        if (address(self.callbackContract) != address(0)) {
            try
                self.callbackContract.__beaconCallback{gas: callbackGasLimit}(
                    entry,
                    block.number
                )
            {} catch {
                // slither-disable-next-line reentrancy-events
                emit CallbackFailed(entry, block.number);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "./ReimbursementPool.sol";

abstract contract Reimbursable {
    // The variable should be initialized by the implementing contract.
    // slither-disable-next-line uninitialized-state
    ReimbursementPool public reimbursementPool;

    // Reserved storage space in case we need to add more variables,
    // since there are upgradeable contracts that inherit from this one.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    // slither-disable-next-line unused-state
    uint256[49] private __gap;

    event ReimbursementPoolUpdated(address newReimbursementPool);

    modifier refundable(address receiver) {
        uint256 gasStart = gasleft();
        _;
        reimbursementPool.refund(gasStart - gasleft(), receiver);
    }

    modifier onlyReimbursableAdmin() virtual {
        _;
    }

    function updateReimbursementPool(ReimbursementPool _reimbursementPool)
        external
        onlyReimbursableAdmin
    {
        emit ReimbursementPoolUpdated(address(_reimbursementPool));

        reimbursementPool = _reimbursementPool;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

/// @notice Governable contract.
/// @dev A constructor is not defined, which makes the contract compatible with
///      upgradable proxies. This requires calling explicitly `_transferGovernance`
///      function in a child contract.
abstract contract Governable {
    // Governance of the contract
    // The variable should be initialized by the implementing contract.
    // slither-disable-next-line uninitialized-state
    address public governance;

    // Reserved storage space in case we need to add more variables,
    // since there are upgradeable contracts that inherit from this one.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    // slither-disable-next-line unused-state
    uint256[49] private __gap;

    event GovernanceTransferred(address oldGovernance, address newGovernance);

    modifier onlyGovernance() virtual {
        require(governance == msg.sender, "Caller is not the governance");
        _;
    }

    /// @notice Transfers governance of the contract to `newGovernance`.
    function transferGovernance(address newGovernance)
        external
        virtual
        onlyGovernance
    {
        require(
            newGovernance != address(0),
            "New governance is the zero address"
        );
        _transferGovernance(newGovernance);
    }

    function _transferGovernance(address newGovernance) internal virtual {
        address oldGovernance = governance;
        governance = newGovernance;
        emit GovernanceTransferred(oldGovernance, newGovernance);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "./BytesLib.sol";
import "./Groups.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";

library BeaconInactivity {
    using BytesLib for bytes;
    using ECDSA for bytes32;

    struct Claim {
        // ID of the group raising the inactivity claim.
        uint64 groupId;
        // Indices of members accused of being inactive. Indices must be in
        // range [1, groupMembers.length], unique, and sorted in ascending order.
        uint256[] inactiveMembersIndices;
        // Concatenation of signatures from members supporting the claim.
        // The message to be signed by each member is keccak256 hash of the
        // concatenation of the chain ID, inactivity claim nonce for the given
        // group, group public key, and inactive members indices. The calculated
        // hash should be prefixed with `\x19Ethereum signed message:\n` before
        // signing, so the message to sign is:
        // `\x19Ethereum signed message:\n${keccak256(
        //    chainID | nonce | groupPubKey | inactiveMembersIndices
        // )}`
        bytes signatures;
        // Indices of members corresponding to each signature. Indices must be
        // in range [1, groupMembers.length], unique, and sorted in ascending
        // order.
        uint256[] signingMembersIndices;
    }

    /// @notice The minimum number of group members needed to interact according
    ///         to the protocol to produce a valid inactivity claim.
    uint256 public constant groupThreshold = 33;

    /// @notice Size in bytes of a single signature produced by member
    ///         supporting the inactivity claim.
    uint256 public constant signatureByteSize = 65;

    /// @notice Verifies the inactivity claim according to the rules defined in
    ///         `Claim` struct documentation. Reverts if verification fails.
    /// @dev Group members hash is validated upstream in
    ///      RandomBeacon.notifyOperatorInactivity()
    /// @param sortitionPool Sortition pool reference
    /// @param claim Inactivity claim
    /// @param groupPubKey Public key of the group raising the claim
    /// @param nonce Current nonce for group used in the claim
    /// @param groupMembers Identifiers of group members
    /// @return inactiveMembers Identifiers of members who are inactive
    function verifyClaim(
        SortitionPool sortitionPool,
        Claim calldata claim,
        bytes memory groupPubKey,
        uint256 nonce,
        uint32[] calldata groupMembers
    ) external view returns (uint32[] memory inactiveMembers) {
        // Validate inactive members indices. Maximum indices count is equal to
        // the group size and is not limited deliberately to leave a theoretical
        // possibility to accuse more members than `groupSize - groupThreshold`.
        validateMembersIndices(
            claim.inactiveMembersIndices,
            groupMembers.length
        );

        // Validate signatures array is properly formed and number of
        // signatures and signers is correct.
        uint256 signaturesCount = claim.signatures.length / signatureByteSize;
        require(claim.signatures.length != 0, "No signatures provided");
        require(
            claim.signatures.length % signatureByteSize == 0,
            "Malformed signatures array"
        );
        require(
            signaturesCount == claim.signingMembersIndices.length,
            "Unexpected signatures count"
        );
        require(signaturesCount >= groupThreshold, "Too few signatures");
        require(signaturesCount <= groupMembers.length, "Too many signatures");

        // Validate signing members indices. Note that `signingMembersIndices`
        // were already partially validated during `signatures` parameter
        // validation.
        validateMembersIndices(
            claim.signingMembersIndices,
            groupMembers.length
        );

        // Usage of group public key and not group ID is important because it
        // provides uniqueness of signed messages and prevent against reusing
        // them in future in case some other application has a group with the
        // same ID and subset of members.
        bytes32 signedMessageHash = keccak256(
            abi.encode(
                block.chainid,
                nonce,
                groupPubKey,
                claim.inactiveMembersIndices
            )
        ).toEthSignedMessageHash();

        address[] memory groupMembersAddresses = sortitionPool.getIDOperators(
            groupMembers
        );

        // Verify each signature.
        bytes memory checkedSignature;
        bool senderSignatureExists = false;
        for (uint256 i = 0; i < signaturesCount; i++) {
            uint256 memberIndex = claim.signingMembersIndices[i];
            checkedSignature = claim.signatures.slice(
                signatureByteSize * i,
                signatureByteSize
            );
            address recoveredAddress = signedMessageHash.recover(
                checkedSignature
            );

            require(
                groupMembersAddresses[memberIndex - 1] == recoveredAddress,
                "Invalid signature"
            );

            if (!senderSignatureExists && msg.sender == recoveredAddress) {
                senderSignatureExists = true;
            }
        }

        require(senderSignatureExists, "Sender must be claim signer");

        inactiveMembers = new uint32[](claim.inactiveMembersIndices.length);
        for (uint256 i = 0; i < claim.inactiveMembersIndices.length; i++) {
            uint256 memberIndex = claim.inactiveMembersIndices[i];
            inactiveMembers[i] = groupMembers[memberIndex - 1];
        }

        return inactiveMembers;
    }

    /// @notice Validates members indices array. Array is considered valid
    ///         if its size and each single index are in [1, groupSize] range,
    ///         indexes are unique, and sorted in an ascending order.
    ///         Reverts if validation fails.
    /// @param indices Array to validate
    /// @param groupSize Group size used as reference
    function validateMembersIndices(
        uint256[] calldata indices,
        uint256 groupSize
    ) internal pure {
        require(
            indices.length > 0 && indices.length <= groupSize,
            "Corrupted members indices"
        );

        // Check if first and last indices are in range [1, groupSize].
        // This check combined with the loop below makes sure every single
        // index is in the correct range.
        require(
            indices[0] > 0 && indices[indices.length - 1] <= groupSize,
            "Corrupted members indices"
        );

        for (uint256 i = 0; i < indices.length - 1; i++) {
            // Check whether given index is smaller than the next one. This
            // way we are sure indexes are ordered in the ascending order
            // and there are no duplicates.
            require(indices[i] < indices[i + 1], "Corrupted members indices");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

// Initial version copied from Keep Network ECDSA Wallets:
// https://github.com/keep-network/keep-core/blob/5286ebc8ff99b2aa6569f9dd97fd6995f25b4630/solidity/ecdsa/contracts/libraries/EcdsaAuthorization.sol
//
// With the following differences:
// - functions' visibility was changed to public/external to deploy it as a linked
//   library.
// - documentation was updated to be more generic.

pragma solidity 0.8.17;

import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "@threshold-network/solidity-contracts/contracts/staking/IStaking.sol";

/// @notice Library managing the state of stake authorizations for the operator
///         contract and the presence of operators in the sortition
///         pool based on the stake authorized for them.
library BeaconAuthorization {
    struct Parameters {
        // The minimum authorization required by the beacon so that
        // operator can join the sortition pool and do the work.
        uint96 minimumAuthorization;
        // Authorization decrease delay in seconds between the time
        // authorization decrease is requested and the time the authorization
        // decrease can be approved. It is always the same value, no matter if
        // authorization decrease amount is small, significant, or if it is
        // a decrease to zero.
        uint64 authorizationDecreaseDelay;
        // The time period before the authorization decrease delay end,
        // during which the authorization decrease request can be overwritten.
        //
        // When the request is overwritten, the authorization decrease delay is
        // reset.
        //
        // For example, if `authorizationDecraseChangePeriod` is set to 4
        // days, `authorizationDecreaseDelay` is set to 14 days, and someone
        // requested authorization decrease, it means they can not
        // request another decrease for the first 10 days. After 10 days pass,
        // they can request again and overwrite the previous authorization
        // decrease request. The delay time will reset for them and they
        // will have to wait another 10 days to alter it and 14 days to
        // approve it.
        //
        // This value protects against malicious operators who manipulate
        // their weight by overwriting authorization decrease request, and
        // lowering or increasing their eligible stake this way.
        //
        // If set to a value equal to `authorizationDecreaseDelay, it means
        // that authorization decrease request can be always overwritten.
        // If set to zero, it means authorization decrease request can not be
        // overwritten until the delay end, and one needs to wait for the entire
        // authorization decrease delay to approve their decrease and request
        // for another one or to overwrite the pending one.
        //
        //   (1) authorization decrease requested timestamp
        //   (2) from this moment authorization decrease request can be
        //       overwritten
        //   (3) from this moment authorization decrease request can be
        //       approved, assuming it was NOT overwritten in (2)
        //
        //  (1)                            (2)                        (3)
        // --x------------------------------x--------------------------x---->
        //   |                               \________________________/
        //   |                             authorizationDecreaseChangePeriod
        //    \______________________________________________________/
        //                   authorizationDecreaseDelay
        //
        uint64 authorizationDecreaseChangePeriod;
    }

    struct AuthorizationDecrease {
        uint96 decreasingBy; // amount
        uint64 decreasingAt; // timestamp
    }

    struct Data {
        Parameters parameters;
        mapping(address => address) stakingProviderToOperator;
        mapping(address => address) operatorToStakingProvider;
        mapping(address => AuthorizationDecrease) pendingDecreases;
    }

    event OperatorRegistered(
        address indexed stakingProvider,
        address indexed operator
    );

    event AuthorizationIncreased(
        address indexed stakingProvider,
        address indexed operator,
        uint96 fromAmount,
        uint96 toAmount
    );

    event AuthorizationDecreaseRequested(
        address indexed stakingProvider,
        address indexed operator,
        uint96 fromAmount,
        uint96 toAmount,
        uint64 decreasingAt
    );

    event AuthorizationDecreaseApproved(address indexed stakingProvider);

    event InvoluntaryAuthorizationDecreaseFailed(
        address indexed stakingProvider,
        address indexed operator,
        uint96 fromAmount,
        uint96 toAmount
    );

    event OperatorJoinedSortitionPool(
        address indexed stakingProvider,
        address indexed operator
    );

    event OperatorStatusUpdated(
        address indexed stakingProvider,
        address indexed operator
    );

    /// @notice Updates authorization-related parameters.
    /// @param _minimumAuthorization New value of the minimum authorization for
    ///        the beacon. Without at least the minimum authorization, staking
    ///        provider is not eligible to join and operate in the network.
    /// @param _authorizationDecreaseDelay New value of the authorization
    ///        decrease delay. It is the time in seconds that needs to pass
    ///        between the time authorization decrease is requested and the time
    ///        the authorization decrease can be approved, no matter the
    ///        authorization decrease amount.
    /// @param _authorizationDecreaseChangePeriod New value of the authorization
    ///        decrease change period. It is the time in seconds, before
    ///        authorization decrease delay end, during which the pending
    ///        authorization decrease request can be overwritten.
    ///        If set to 0, pending authorization decrease request can not be
    ///        overwritten until the entire `authorizationDecreaseDelay` ends.
    ///        If set to value equal `authorizationDecreaseDelay`, request can
    ///        always be overwritten.
    function setParameters(
        Data storage self,
        uint96 _minimumAuthorization,
        uint64 _authorizationDecreaseDelay,
        uint64 _authorizationDecreaseChangePeriod
    ) external {
        self.parameters.minimumAuthorization = _minimumAuthorization;
        self
            .parameters
            .authorizationDecreaseDelay = _authorizationDecreaseDelay;
        self
            .parameters
            .authorizationDecreaseChangePeriod = _authorizationDecreaseChangePeriod;
    }

    /// @notice Used by staking provider to set operator address that will
    ///         operate a node. The given staking provider can set operator
    ///         address only one time. The operator address can not be changed
    ///         and must be unique. Reverts if the operator is already set for
    ///         the staking provider or if the operator address is already in
    ///         use. Reverts if there is a pending authorization decrease for
    ///         the staking provider.
    function registerOperator(Data storage self, address operator) public {
        address stakingProvider = msg.sender;

        require(operator != address(0), "Operator can not be zero address");
        require(
            self.stakingProviderToOperator[stakingProvider] == address(0),
            "Operator already set for the staking provider"
        );
        require(
            self.operatorToStakingProvider[operator] == address(0),
            "Operator address already in use"
        );

        // Authorization request for a staking provider who has not yet
        // registered their operator can be approved immediately.
        // We need to make sure that the approval happens before operator
        // is registered to do not let the operator join the sortition pool
        // with an unresolved authorization decrease request that can be
        // approved at any point.
        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];
        require(
            decrease.decreasingAt == 0,
            "There is a pending authorization decrease request"
        );

        emit OperatorRegistered(stakingProvider, operator);

        self.stakingProviderToOperator[stakingProvider] = operator;
        self.operatorToStakingProvider[operator] = stakingProvider;
    }

    /// @notice Used by T staking contract to inform the beacon that the
    ///         authorized stake amount for the given staking provider increased.
    ///
    ///         Reverts if the authorization amount is below the minimum.
    ///
    ///         The function is not updating the sortition pool. Sortition pool
    ///         state needs to be updated by the operator with a call to
    ///         `joinSortitionPool` or `updateOperatorStatus`.
    ///
    /// @dev Should only be callable by T staking contract.
    function authorizationIncreased(
        Data storage self,
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external {
        require(
            toAmount >= self.parameters.minimumAuthorization,
            "Authorization below the minimum"
        );

        // Note that this function does not require the operator address to be
        // set for the given staking provider. This allows the stake owner
        // who is also an authorizer to increase the authorization before the
        // staking provider sets the operator. This allows delegating stake
        // and increasing authorization immediately one after another without
        // having to wait for the staking provider to do their part.

        address operator = self.stakingProviderToOperator[stakingProvider];
        emit AuthorizationIncreased(
            stakingProvider,
            operator,
            fromAmount,
            toAmount
        );
    }

    /// @notice Used by T staking contract to inform the beacon that the
    ///         authorization decrease for the given staking provider has been
    ///         requested.
    ///
    ///         Reverts if the amount after deauthorization would be non-zero
    ///         and lower than the minimum authorization.
    ///
    ///         Reverts if another authorization decrease request is pending for
    ///         the staking provider and not enough time passed since the
    ///         original request (see `authorizationDecreaseChangePeriod`).
    ///
    ///         If the operator is not known (`registerOperator` was not called)
    ///         it lets to `approveAuthorizationDecrease` immediately. If the
    ///         operator is known (`registerOperator` was called), the operator
    ///         needs to update state of the sortition pool with a call to
    ///         `joinSortitionPool` or `updateOperatorStatus`. After the
    ///         sortition pool state is in sync, authorization decrease delay
    ///         starts.
    ///
    ///         After authorization decrease delay passes, authorization
    ///         decrease request needs to be approved with a call to
    ///         `approveAuthorizationDecrease` function.
    ///
    ///         If there is a pending authorization decrease request, it is
    ///         overwritten, but only if enough time passed since the original
    ///         request. Otherwise, the function reverts.
    ///
    /// @dev Should only be callable by T staking contract.
    function authorizationDecreaseRequested(
        Data storage self,
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) public {
        require(
            toAmount == 0 || toAmount >= self.parameters.minimumAuthorization,
            "Authorization amount should be 0 or above the minimum"
        );

        address operator = self.stakingProviderToOperator[stakingProvider];

        uint64 decreasingAt;

        if (operator == address(0)) {
            // Operator is not known. It means `registerOperator` was not
            // called yet, and there is no chance the operator could
            // call `joinSortitionPool`. We can let to approve authorization
            // decrease immediately because that operator was never in the
            // sortition pool.

            // solhint-disable-next-line not-rely-on-time
            decreasingAt = uint64(block.timestamp);
        } else {
            // Operator is known. It means that this operator is or was in
            // the sortition pool. Before authorization decrease delay starts,
            // the operator needs to update the state of the sortition pool
            // with a call to `joinSortitionPool` or `updateOperatorStatus`.
            // For now, we set `decreasingAt` as "never decreasing" and let
            // it be updated by `joinSortitionPool` or `updateOperatorStatus`
            // once we know the sortition pool is in sync.
            decreasingAt = type(uint64).max;
        }

        uint96 decreasingBy = fromAmount - toAmount;

        AuthorizationDecrease storage decreaseRequest = self.pendingDecreases[
            stakingProvider
        ];

        uint64 pendingDecreaseAt = decreaseRequest.decreasingAt;
        if (pendingDecreaseAt != 0 && pendingDecreaseAt != type(uint64).max) {
            // If there is already a pending authorization decrease request for
            // this staking provider and that request has been activated
            // (sortition pool was updated), require enough time to pass before
            // it can be overwritten.
            require(
                // solhint-disable-next-line not-rely-on-time
                block.timestamp >=
                    pendingDecreaseAt -
                        self.parameters.authorizationDecreaseChangePeriod,
                "Not enough time passed since the original request"
            );
        }

        decreaseRequest.decreasingBy = decreasingBy;
        decreaseRequest.decreasingAt = decreasingAt;

        emit AuthorizationDecreaseRequested(
            stakingProvider,
            operator,
            fromAmount,
            toAmount,
            decreasingAt
        );
    }

    /// @notice Approves the previously registered authorization decrease
    ///         request. Reverts if authorization decrease delay have not passed
    ///         yet or if the authorization decrease was not requested for the
    ///         given staking provider.
    function approveAuthorizationDecrease(
        Data storage self,
        IStaking tokenStaking,
        address stakingProvider
    ) public {
        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];
        require(
            decrease.decreasingAt > 0,
            "Authorization decrease not requested"
        );
        require(
            decrease.decreasingAt != type(uint64).max,
            "Authorization decrease request not activated"
        );
        require(
            // solhint-disable-next-line not-rely-on-time
            block.timestamp >= decrease.decreasingAt,
            "Authorization decrease delay not passed"
        );

        emit AuthorizationDecreaseApproved(stakingProvider);

        // slither-disable-next-line unused-return
        tokenStaking.approveAuthorizationDecrease(stakingProvider);
        delete self.pendingDecreases[stakingProvider];
    }

    /// @notice Used by T staking contract to inform the beacon the
    ///         authorization has been decreased for the given staking provider
    ///         involuntarily, as a result of slashing.
    ///
    ///         If the operator is not known (`registerOperator` was not called)
    ///         the function does nothing. The operator was never in a sortition
    ///         pool so there is nothing to update.
    ///
    ///         If the operator is known, sortition pool is unlocked, and the
    ///         operator is in the sortition pool, the sortition pool state is
    ///         updated. If the sortition pool is locked, update needs to be
    ///         postponed. Every other staker is incentivized to call
    ///         `updateOperatorStatus` for the problematic operator to increase
    ///         their own rewards in the pool.
    ///
    /// @dev Should only be callable by T staking contract.
    function involuntaryAuthorizationDecrease(
        Data storage self,
        IStaking tokenStaking,
        SortitionPool sortitionPool,
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external {
        address operator = self.stakingProviderToOperator[stakingProvider];

        if (operator == address(0)) {
            // Operator is not known. It means `registerOperator` was not
            // called yet, and there is no chance the operator could
            // call `joinSortitionPool`. We can just ignore this update because
            // operator was never in the sortition pool.
            return;
        } else {
            // Operator is known. It means that this operator is or was in the
            // sortition pool and the sortition pool may need to be updated.
            //
            // If the sortition pool is not locked and the operator is in the
            // sortition pool, we are updating it.
            //
            // To keep stakes synchronized between applications when staking
            // providers are slashed, without the risk of running out of gas,
            // the staking contract queues up slashings and let users process
            // the transactions. When an application slashes one or more staking
            // providers, it adds them to the slashing queue on the staking
            // contract. A queue entry contains the staking provider’s address
            // and the amount they are due to be slashed.
            //
            // When there is at least one staking provider in the slashing
            // queue, any account can submit a transaction processing one or
            // more staking providers' slashings, and collecting a reward for
            // doing so. A queued slashing is processed by updating the staking
            // provider’s stake to the post-slashing amount, updating authorized
            // amount for each affected application, and notifying all affected
            // applications that the staking provider’s authorized stake has
            // been reduced due to slashing.
            //
            // The entire idea is that the process transaction is expensive
            // because each application needs to be updated, so the reward for
            // the processor is hefty and comes from the slashed tokens.
            // Practically, it means that if the sortition pool is unlocked, and
            // can be updated, it should be updated because we already paid
            // someone for updating it.
            //
            // If the sortition pool is locked, update needs to wait. Other
            // sortition pool members are incentivized to call
            // `updateOperatorStatus` for the problematic operator because they
            // will increase their rewards this way.
            if (sortitionPool.isOperatorInPool(operator)) {
                if (sortitionPool.isLocked()) {
                    emit InvoluntaryAuthorizationDecreaseFailed(
                        stakingProvider,
                        operator,
                        fromAmount,
                        toAmount
                    );
                } else {
                    updateOperatorStatus(
                        self,
                        tokenStaking,
                        sortitionPool,
                        operator
                    );
                }
            }
        }
    }

    /// @notice Lets the operator join the sortition pool. The operator address
    ///         must be known - before calling this function, it has to be
    ///         appointed by the staking provider by calling `registerOperator`.
    ///         Also, the operator must have the minimum authorization required
    ///         by the beacon. Function reverts if there is no minimum stake
    ///         authorized or if the operator is not known. If there was an
    ///         authorization decrease requested, it is activated by starting
    ///         the authorization decrease delay.
    function joinSortitionPool(
        Data storage self,
        IStaking tokenStaking,
        SortitionPool sortitionPool
    ) public {
        address operator = msg.sender;

        address stakingProvider = self.operatorToStakingProvider[operator];
        require(stakingProvider != address(0), "Unknown operator");

        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];

        uint96 _eligibleStake = eligibleStake(
            self,
            tokenStaking,
            stakingProvider,
            decrease.decreasingBy
        );

        require(_eligibleStake != 0, "Authorization below the minimum");

        emit OperatorJoinedSortitionPool(stakingProvider, operator);

        sortitionPool.insertOperator(operator, _eligibleStake);

        // If there is a pending authorization decrease request, activate it.
        // At this point, the sortition pool state is up to date so the
        // authorization decrease delay can start counting.
        if (decrease.decreasingAt == type(uint64).max) {
            decrease.decreasingAt =
                // solhint-disable-next-line not-rely-on-time
                uint64(block.timestamp) +
                self.parameters.authorizationDecreaseDelay;
        }
    }

    /// @notice Updates status of the operator in the sortition pool. If there
    ///         was an authorization decrease requested, it is activated by
    ///         starting the authorization decrease delay.
    ///         Function reverts if the operator is not known.
    function updateOperatorStatus(
        Data storage self,
        IStaking tokenStaking,
        SortitionPool sortitionPool,
        address operator
    ) public {
        address stakingProvider = self.operatorToStakingProvider[operator];
        require(stakingProvider != address(0), "Unknown operator");

        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];

        emit OperatorStatusUpdated(stakingProvider, operator);

        if (sortitionPool.isOperatorInPool(operator)) {
            uint96 _eligibleStake = eligibleStake(
                self,
                tokenStaking,
                stakingProvider,
                decrease.decreasingBy
            );

            sortitionPool.updateOperatorStatus(operator, _eligibleStake);
        }

        // If there is a pending authorization decrease request, activate it.
        // At this point, the sortition pool state is up to date so the
        // authorization decrease delay can start counting.
        if (decrease.decreasingAt == type(uint64).max) {
            decrease.decreasingAt =
                // solhint-disable-next-line not-rely-on-time
                uint64(block.timestamp) +
                self.parameters.authorizationDecreaseDelay;
        }
    }

    /// @notice Checks if the operator's authorized stake is in sync with
    ///         operator's weight in the sortition pool.
    ///         If the operator is not in the sortition pool and their
    ///         authorized stake is non-zero, function returns false.
    function isOperatorUpToDate(
        Data storage self,
        IStaking tokenStaking,
        SortitionPool sortitionPool,
        address operator
    ) external view returns (bool) {
        address stakingProvider = self.operatorToStakingProvider[operator];
        require(stakingProvider != address(0), "Unknown operator");

        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];

        uint96 _eligibleStake = eligibleStake(
            self,
            tokenStaking,
            stakingProvider,
            decrease.decreasingBy
        );

        if (!sortitionPool.isOperatorInPool(operator)) {
            return _eligibleStake == 0;
        } else {
            return sortitionPool.isOperatorUpToDate(operator, _eligibleStake);
        }
    }

    /// @notice Returns the current value of the staking provider's eligible
    ///         stake. Eligible stake is defined as the currently authorized
    ///         stake minus the pending authorization decrease. Eligible stake
    ///         is what is used for operator's weight in the pool. If the
    ///         authorized stake minus the pending authorization decrease is
    ///         below the minimum authorization, eligible stake is 0.
    /// @dev This function can be exposed to the public in contrast to the
    ///      second variant accepting `decreasingBy` as a parameter.
    function eligibleStake(
        Data storage self,
        IStaking tokenStaking,
        address stakingProvider
    ) external view returns (uint96) {
        return
            eligibleStake(
                self,
                tokenStaking,
                stakingProvider,
                pendingAuthorizationDecrease(self, stakingProvider)
            );
    }

    /// @notice Returns the current value of the staking provider's eligible
    ///         stake. Eligible stake is defined as the currently authorized
    ///         stake minus the pending authorization decrease. Eligible stake
    ///         is what is used for operator's weight in the pool. If the
    ///         authorized stake minus the pending authorization decrease is
    ///         below the minimum authorization, eligible stake is 0.
    /// @dev This function is not intended to be exposes to the public.
    ///      `decreasingBy` must be fetched from `pendingDecreases` mapping and
    ///      it is passed as a parameter to optimize gas usage of functions that
    ///      call `eligibleStake` and need to use `AuthorizationDecrease`
    ///      fetched from `pendingDecreases` for some additional logic.
    function eligibleStake(
        Data storage self,
        IStaking tokenStaking,
        address stakingProvider,
        uint96 decreasingBy
    ) public view returns (uint96) {
        uint96 authorizedStake = tokenStaking.authorizedStake(
            stakingProvider,
            address(this)
        );

        uint96 _eligibleStake = authorizedStake > decreasingBy
            ? authorizedStake - decreasingBy
            : 0;

        if (_eligibleStake < self.parameters.minimumAuthorization) {
            return 0;
        } else {
            return _eligibleStake;
        }
    }

    /// @notice Returns the amount of stake that is pending authorization
    ///         decrease for the given staking provider. If no authorization
    ///         decrease has been requested, returns zero.
    function pendingAuthorizationDecrease(
        Data storage self,
        address stakingProvider
    ) public view returns (uint96) {
        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];

        return decrease.decreasingBy;
    }

    /// @notice Returns the remaining time in seconds that needs to pass before
    ///         the requested authorization decrease can be approved.
    ///         If the sortition pool state was not updated yet by the operator
    ///         after requesting the authorization decrease, returns
    ///         `type(uint64).max`.
    function remainingAuthorizationDecreaseDelay(
        Data storage self,
        address stakingProvider
    ) external view returns (uint64) {
        AuthorizationDecrease storage decrease = self.pendingDecreases[
            stakingProvider
        ];

        if (decrease.decreasingAt == type(uint64).max) {
            return type(uint64).max;
        }

        // solhint-disable-next-line not-rely-on-time
        uint64 _now = uint64(block.timestamp);
        return _now > decrease.decreasingAt ? 0 : decrease.decreasingAt - _now;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "./BytesLib.sol";
import {BeaconDkgValidator as DKGValidator} from "../BeaconDkgValidator.sol";

library BeaconDkg {
    using BytesLib for bytes;
    using ECDSA for bytes32;

    struct Parameters {
        // Time in blocks during which a submitted result can be challenged.
        uint256 resultChallengePeriodLength;
        // Extra gas required to be left at the end of the challenge DKG result
        // transaction.
        uint256 resultChallengeExtraGas;
        // Time in blocks during which a result is expected to be submitted.
        uint256 resultSubmissionTimeout;
        // Time in blocks during which only the result submitter is allowed to
        // approve it. Once this period ends and the submitter have not approved
        // the result, anyone can do it.
        uint256 submitterPrecedencePeriodLength;
    }

    struct Data {
        // Address of the Sortition Pool contract.
        SortitionPool sortitionPool;
        // Address of the DKGValidator contract.
        DKGValidator dkgValidator;
        // DKG parameters. The parameters should persist between DKG executions.
        // They should be updated with dedicated set functions only when DKG is not
        // in progress.
        Parameters parameters;
        // Time in blocks at which DKG started.
        uint256 startBlock;
        // Seed used to start DKG.
        uint256 seed;
        // Time in blocks that should be added to result submission period calculation.
        // It is used in case of a challenge to adjust DKG timeout calculation.
        uint256 resultSubmissionStartBlockOffset;
        // Hash of submitted DKG result.
        bytes32 submittedResultHash;
        // Block number from the moment of the DKG result submission.
        uint256 submittedResultBlock;
    }

    /// @notice DKG result.
    struct Result {
        // Claimed submitter candidate group member index.
        // Must be in range [1, groupSize].
        uint256 submitterMemberIndex;
        // Generated candidate group public key
        bytes groupPubKey;
        // Array of misbehaved members indices (disqualified or inactive).
        // Indices must be in range [1, groupSize], unique, and sorted in ascending
        // order.
        uint8[] misbehavedMembersIndices;
        // Concatenation of signatures from members supporting the result.
        // The message to be signed by each member is keccak256 hash of the
        // calculated group public key, misbehaved members indices and DKG
        // start block. The calculated hash should be prefixed with prefixed with
        // `\x19Ethereum signed message:\n` before signing, so the message to
        // sign is:
        // `\x19Ethereum signed message:\n${keccak256(
        //    groupPubKey, misbehavedMembersIndices, dkgStartBlock
        // )}`
        bytes signatures;
        // Indices of members corresponding to each signature. Indices must be
        // be in range [1, groupSize], unique, and sorted in ascending order.
        uint256[] signingMembersIndices;
        // Identifiers of candidate group members as outputted by the group
        // selection protocol.
        uint32[] members;
        // Keccak256 hash of group members identifiers that actively took part
        // in DKG (excluding IA/DQ members).
        bytes32 membersHash;
    }

    /// @notice States for phases of group creation. The states doesn't include
    ///         timeouts which should be tracked and notified individually.
    enum State {
        // Group creation is not in progress. It is a state set after group creation
        // completion either by timeout or by a result approval.
        IDLE,
        // Group creation is awaiting the seed and sortition pool is locked.
        AWAITING_SEED,
        // Off-chain DKG protocol execution is in progress. A result is being calculated
        // by the clients in this state. It's not yet possible to submit the result.
        KEY_GENERATION,
        // After off-chain DKG protocol execution the contract awaits result submission.
        // This is a state to which group creation returns in case of a result
        // challenge notification.
        AWAITING_RESULT,
        // DKG result was submitted and awaits an approval or a challenge. If a result
        // gets challenge the state returns to `AWAITING_RESULT`. If a result gets
        // approval the state changes to `IDLE`.
        CHALLENGE
    }

    /// @dev Size of a group in the threshold relay.
    uint256 public constant groupSize = 64;

    /// @notice Time in blocks after which DKG result is complete and ready to be
    //          published by clients.
    uint256 public constant offchainDkgTime = 5 * (1 + 5) + 2 * (1 + 10) + 20;

    event DkgStarted(uint256 indexed seed);

    // To recreate the members that actively took part in dkg, the selected members
    // array should be filtered out from misbehavedMembersIndices.
    event DkgResultSubmitted(
        bytes32 indexed resultHash,
        uint256 indexed seed,
        Result result
    );

    event DkgTimedOut();

    event DkgResultApproved(
        bytes32 indexed resultHash,
        address indexed approver
    );

    event DkgResultChallenged(
        bytes32 indexed resultHash,
        address indexed challenger,
        string reason
    );

    event DkgStateLocked();

    event DkgSeedTimedOut();

    /// @notice Initializes SortitionPool and DKGValidator addresses.
    ///        Can be performed only once.
    /// @param _sortitionPool Sortition Pool reference
    /// @param _dkgValidator DKGValidator reference
    function init(
        Data storage self,
        SortitionPool _sortitionPool,
        DKGValidator _dkgValidator
    ) internal {
        require(
            address(self.sortitionPool) == address(0),
            "Sortition Pool address already set"
        );

        require(
            address(self.dkgValidator) == address(0),
            "DKG Validator address already set"
        );

        self.sortitionPool = _sortitionPool;
        self.dkgValidator = _dkgValidator;
    }

    /// @notice Determines the current state of group creation. It doesn't take
    ///         timeouts into consideration. The timeouts should be tracked and
    ///         notified separately.
    function currentState(Data storage self)
        internal
        view
        returns (State state)
    {
        state = State.IDLE;

        if (self.sortitionPool.isLocked()) {
            state = State.AWAITING_SEED;

            if (self.startBlock > 0) {
                state = State.KEY_GENERATION;

                if (block.number > self.startBlock + offchainDkgTime) {
                    state = State.AWAITING_RESULT;

                    if (self.submittedResultBlock > 0) {
                        state = State.CHALLENGE;
                    }
                }
            }
        }
    }

    /// @notice Locks the sortition pool and starts awaiting for the
    ///         group creation seed.
    function lockState(Data storage self) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        emit DkgStateLocked();

        self.sortitionPool.lock();
    }

    function start(Data storage self, uint256 seed) internal {
        require(
            currentState(self) == State.AWAITING_SEED,
            "Current state is not AWAITING_SEED"
        );

        emit DkgStarted(seed);

        self.startBlock = block.number;
        self.seed = seed;
    }

    /// @notice Allows to submit a DKG result. The submitted result does not go
    ///         through a validation and before it gets accepted, it needs to
    ///         wait through the challenge period during which everyone has
    ///         a chance to challenge the result as invalid one. Submitter of
    ///         the result needs to be in the sortition pool and if the result
    ///         gets challenged, the submitter will get slashed.
    function submitResult(Data storage self, Result calldata result) external {
        require(
            currentState(self) == State.AWAITING_RESULT,
            "Current state is not AWAITING_RESULT"
        );
        require(!hasDkgTimedOut(self), "DKG timeout already passed");

        SortitionPool sortitionPool = self.sortitionPool;

        // Submitter must be an operator in the sortition pool.
        // Declared submitter's member index in the DKG result needs to match
        // the address calling this function.
        require(
            sortitionPool.isOperatorInPool(msg.sender),
            "Submitter not in the sortition pool"
        );
        require(
            sortitionPool.getIDOperator(
                result.members[result.submitterMemberIndex - 1]
            ) == msg.sender,
            "Unexpected submitter index"
        );

        self.submittedResultHash = keccak256(abi.encode(result));
        self.submittedResultBlock = block.number;

        emit DkgResultSubmitted(self.submittedResultHash, self.seed, result);
    }

    /// @notice Checks if DKG timed out. The DKG timeout period includes time required
    ///         for off-chain protocol execution and time for the result publication.
    ///         After this time a result cannot be submitted and DKG can be notified
    ///         about the timeout. DKG period is adjusted by result submission
    ///         offset that include blocks that were mined while invalid result
    ///         has been registered until it got challenged.
    /// @return True if DKG timed out, false otherwise.
    function hasDkgTimedOut(Data storage self) internal view returns (bool) {
        return
            currentState(self) == State.AWAITING_RESULT &&
            block.number >
            (self.startBlock +
                offchainDkgTime +
                self.resultSubmissionStartBlockOffset +
                self.parameters.resultSubmissionTimeout);
    }

    /// @notice Notifies about DKG timeout.
    function notifyTimeout(Data storage self) internal {
        require(hasDkgTimedOut(self), "DKG has not timed out");

        emit DkgTimedOut();

        complete(self);
    }

    /// @notice Notifies about the seed was not delivered and restores the
    ///         initial DKG state (IDLE).
    function notifySeedTimedOut(Data storage self) internal {
        require(
            currentState(self) == State.AWAITING_SEED,
            "Current state is not AWAITING_SEED"
        );

        emit DkgSeedTimedOut();

        complete(self);
    }

    /// @notice Approves DKG result. Can be called when the challenge period for
    ///         the submitted result is finished. Considers the submitted result
    ///         as valid. For the first `submitterPrecedencePeriodLength`
    ///         blocks after the end of the challenge period can be called only
    ///         by the DKG result submitter. After that time, can be called by
    ///         anyone.
    /// @dev Can be called after a challenge period for the submitted result.
    /// @param result Result to approve. Must match the submitted result stored
    ///        during `submitResult`.
    /// @return misbehavedMembers Identifiers of members who misbehaved during DKG.
    function approveResult(Data storage self, Result calldata result)
        external
        returns (uint32[] memory misbehavedMembers)
    {
        require(
            currentState(self) == State.CHALLENGE,
            "Current state is not CHALLENGE"
        );

        uint256 challengePeriodEnd = self.submittedResultBlock +
            self.parameters.resultChallengePeriodLength;

        require(
            block.number > challengePeriodEnd,
            "Challenge period has not passed yet"
        );

        require(
            keccak256(abi.encode(result)) == self.submittedResultHash,
            "Result under approval is different than the submitted one"
        );

        // Extract submitter member address. Submitter member index is in
        // range [1, groupSize] so we need to -1 when fetching identifier from members
        // array.
        address submitterMember = self.sortitionPool.getIDOperator(
            result.members[result.submitterMemberIndex - 1]
        );

        require(
            msg.sender == submitterMember ||
                block.number >
                challengePeriodEnd +
                    self.parameters.submitterPrecedencePeriodLength,
            "Only the DKG result submitter can approve the result at this moment"
        );

        // Extract misbehaved members identifiers. Misbehaved members indices
        // are in range [1, groupSize], so we need to -1 when fetching identifiers from
        // members array.
        misbehavedMembers = new uint32[](
            result.misbehavedMembersIndices.length
        );
        for (uint256 i = 0; i < result.misbehavedMembersIndices.length; i++) {
            misbehavedMembers[i] = result.members[
                result.misbehavedMembersIndices[i] - 1
            ];
        }

        emit DkgResultApproved(self.submittedResultHash, msg.sender);

        return misbehavedMembers;
    }

    /// @notice Challenges DKG result. If the submitted result is proved to be
    ///         invalid it reverts the DKG back to the result submission phase.
    /// @dev Can be called during a challenge period for the submitted result.
    /// @param result Result to challenge. Must match the submitted result
    ///        stored during `submitResult`.
    /// @return maliciousResultHash Hash of the malicious result.
    /// @return maliciousSubmitter Identifier of the malicious submitter.
    function challengeResult(Data storage self, Result calldata result)
        external
        returns (bytes32 maliciousResultHash, uint32 maliciousSubmitter)
    {
        require(
            currentState(self) == State.CHALLENGE,
            "Current state is not CHALLENGE"
        );

        require(
            block.number <=
                self.submittedResultBlock +
                    self.parameters.resultChallengePeriodLength,
            "Challenge period has already passed"
        );

        require(
            keccak256(abi.encode(result)) == self.submittedResultHash,
            "Result under challenge is different than the submitted one"
        );

        // https://github.com/crytic/slither/issues/982
        // slither-disable-next-line unused-return
        try
            self.dkgValidator.validate(result, self.seed, self.startBlock)
        returns (
            // slither-disable-next-line uninitialized-local,variable-scope
            bool isValid,
            // slither-disable-next-line uninitialized-local,variable-scope
            string memory errorMsg
        ) {
            if (isValid) {
                revert("unjustified challenge");
            }

            emit DkgResultChallenged(
                self.submittedResultHash,
                msg.sender,
                errorMsg
            );
        } catch {
            // if the validation reverted we consider the DKG result as invalid
            emit DkgResultChallenged(
                self.submittedResultHash,
                msg.sender,
                "validation reverted"
            );
        }

        // Consider result hash as malicious.
        maliciousResultHash = self.submittedResultHash;
        maliciousSubmitter = result.members[result.submitterMemberIndex - 1];

        // Adjust DKG result submission block start, so submission stage starts
        // from the beginning.
        self.resultSubmissionStartBlockOffset =
            block.number -
            self.startBlock -
            offchainDkgTime;

        submittedResultCleanup(self);

        return (maliciousResultHash, maliciousSubmitter);
    }

    /// @notice Due to EIP150, 1/64 of the gas is not forwarded to the call, and
    ///         will be kept to execute the remaining operations in the function
    ///         after the call inside the try-catch.
    ///
    ///         To ensure there is no way for the caller to manipulate gas limit
    ///         in such a way that the call inside try-catch fails with out-of-gas
    ///         and the rest of the function is executed with the remaining
    ///         1/64 of gas, we require an extra gas amount to be left at the
    ///         end of the call to the function challenging DKG result and
    ///         wrapping the call to BeaconDkgValidator and TokenStaking
    ///         contracts inside a try-catch.
    function requireChallengeExtraGas(Data storage self) internal view {
        require(
            gasleft() >= self.parameters.resultChallengeExtraGas,
            "Not enough extra gas left"
        );
    }

    /// @notice Updates DKG-related parameters
    /// @param _resultChallengePeriodLength New value of the result challenge
    ///        period length. It is the number of blocks for which a DKG result
    ///        can be challenged.
    /// @param _resultChallengeExtraGas New value of the result challenge extra
    ///        gas. It is the extra gas required to be left at the end of the
    ///        challenge DKG result transaction.
    /// @param _resultSubmissionTimeout New value of the result submission
    ///        timeout in seconds. It is a timeout for a group to provide a DKG
    ///        result.
    /// @param _submitterPrecedencePeriodLength New value of the submitter
    ///        precedence period length in blocks. It is the time during which
    ///        only the original DKG result submitter can approve it.
    function setParameters(
        Data storage self,
        uint256 _resultChallengePeriodLength,
        uint256 _resultChallengeExtraGas,
        uint256 _resultSubmissionTimeout,
        uint256 _submitterPrecedencePeriodLength
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            _resultChallengePeriodLength > 0,
            "Result challenge period length should be greater than zero"
        );
        require(
            _resultSubmissionTimeout > 0,
            "Result submission timeout should be greater than zero"
        );
        require(
            _submitterPrecedencePeriodLength < _resultSubmissionTimeout,
            "Submitter precedence period length should be less than the result submission timeout"
        );

        self
            .parameters
            .resultChallengePeriodLength = _resultChallengePeriodLength;
        self.parameters.resultChallengeExtraGas = _resultChallengeExtraGas;
        self.parameters.resultSubmissionTimeout = _resultSubmissionTimeout;
        self
            .parameters
            .submitterPrecedencePeriodLength = _submitterPrecedencePeriodLength;
    }

    /// @notice Completes DKG by cleaning up state.
    /// @dev Should be called after DKG times out or a result is approved.
    function complete(Data storage self) internal {
        delete self.startBlock;
        delete self.seed;
        delete self.resultSubmissionStartBlockOffset;
        submittedResultCleanup(self);
        self.sortitionPool.unlock();
    }

    /// @notice Cleans up submitted result state either after DKG completion
    ///         (as part of `complete` method) or after justified challenge.
    function submittedResultCleanup(Data storage self) private {
        delete self.submittedResultHash;
        delete self.submittedResultBlock;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "./libraries/BytesLib.sol";
import {BeaconDkg as DKG} from "./libraries/BeaconDkg.sol";

/// @title DKG result validator
/// @notice DKGValidator allows performing a full validation of DKG result,
///         including checking the format of fields in the result, declared
///         selected group members, and signatures of operators supporting the
///         result. The operator submitting the result should perform the
///         validation using a free contract call before submitting the result
///         to ensure their result is valid and can not be challenged. All other
///         network operators should perform validation of the submitted result
///         using a free contract call and challenge the result if the
///         validation fails.
contract BeaconDkgValidator {
    using BytesLib for bytes;
    using ECDSA for bytes32;

    /// @dev Size of a group in the threshold relay.
    uint256 public constant groupSize = 64;

    /// @dev The minimum number of group members needed to interact according to
    ///      the protocol to produce a relay entry. The adversary can not learn
    ///      anything about the key as long as it does not break into
    ///      groupThreshold+1 of members.
    uint256 public constant groupThreshold = 33;

    /// @dev The minimum number of active and properly behaving group members
    ///      during the DKG needed to accept the result. This number is higher
    ///      than `groupThreshold` to keep a safety margin for members becoming
    ///      inactive after DKG so that the group can still produce a relay
    ///      entry.
    uint256 public constant activeThreshold = 58; // 90% of groupSize

    /// @dev Size in bytes of a single signature produced by operator supporting
    ///      DKG result.
    uint256 public constant signatureByteSize = 65;

    SortitionPool public immutable sortitionPool;

    constructor(SortitionPool _sortitionPool) {
        require(
            address(_sortitionPool) != address(0),
            "Zero-address reference"
        );

        sortitionPool = _sortitionPool;
    }

    /// @notice Performs a full validation of DKG result, including checking the
    ///         format of fields in the result, declared selected group members,
    ///         and signatures of operators supporting the result.
    /// @param seed seed used to start the DKG and select group members
    /// @param startBlock DKG start block
    /// @return isValid true if the result is valid, false otherwise
    /// @return errorMsg validation error message; empty for a valid result
    function validate(
        DKG.Result calldata result,
        uint256 seed,
        uint256 startBlock
    ) external view returns (bool isValid, string memory errorMsg) {
        (bool hasValidFields, string memory error) = validateFields(result);
        if (!hasValidFields) {
            return (false, error);
        }

        if (!validateSignatures(result, startBlock)) {
            return (false, "Invalid signatures");
        }

        if (!validateGroupMembers(result, seed)) {
            return (false, "Invalid group members");
        }

        // At this point all group members and mishbehaved members were verified
        if (!validateMembersHash(result)) {
            return (false, "Invalid members hash");
        }

        return (true, "");
    }

    /// @notice Performs a static validation of DKG result fields: lengths,
    ///         ranges, and order of arrays.
    /// @return isValid true if the result is valid, false otherwise
    /// @return errorMsg validation error message; empty for a valid result
    function validateFields(DKG.Result calldata result)
        public
        pure
        returns (bool isValid, string memory errorMsg)
    {
        // Group public key needs to be 128 bytes long.
        if (result.groupPubKey.length != 128) {
            return (false, "Malformed group public key");
        }

        // The number of misbehaved members can not exceed the threshold.
        // Misbehaved member indices needs to be unique, between [1, groupSize],
        // and sorted in ascending order.
        uint8[] calldata misbehavedMembersIndices = result
            .misbehavedMembersIndices;
        if (groupSize - misbehavedMembersIndices.length < activeThreshold) {
            return (false, "Too many members misbehaving during DKG");
        }
        if (misbehavedMembersIndices.length > 1) {
            if (
                misbehavedMembersIndices[0] < 1 ||
                misbehavedMembersIndices[misbehavedMembersIndices.length - 1] >
                groupSize
            ) {
                return (false, "Corrupted misbehaved members indices");
            }
            for (uint256 i = 1; i < misbehavedMembersIndices.length; i++) {
                if (
                    misbehavedMembersIndices[i - 1] >=
                    misbehavedMembersIndices[i]
                ) {
                    return (false, "Corrupted misbehaved members indices");
                }
            }
        }

        // Each signature needs to have a correct length and signatures need to
        // be provided.
        uint256 signaturesCount = result.signatures.length / signatureByteSize;
        if (result.signatures.length == 0) {
            return (false, "No signatures provided");
        }
        if (result.signatures.length % signatureByteSize != 0) {
            return (false, "Malformed signatures array");
        }

        // We expect the same amount of signatures as the number of declared
        // group member indices that signed the result.
        uint256[] calldata signingMembersIndices = result.signingMembersIndices;
        if (signaturesCount != signingMembersIndices.length) {
            return (false, "Unexpected signatures count");
        }
        if (signaturesCount < groupThreshold) {
            return (false, "Too few signatures");
        }
        if (signaturesCount > groupSize) {
            return (false, "Too many signatures");
        }

        // Signing member indices needs to be unique, between [1,groupSize],
        // and sorted in ascending order.
        if (
            signingMembersIndices[0] < 1 ||
            signingMembersIndices[signingMembersIndices.length - 1] > groupSize
        ) {
            return (false, "Corrupted signing member indices");
        }
        for (uint256 i = 1; i < signingMembersIndices.length; i++) {
            if (signingMembersIndices[i - 1] >= signingMembersIndices[i]) {
                return (false, "Corrupted signing member indices");
            }
        }

        return (true, "");
    }

    /// @notice Performs validation of group members as declared in DKG
    ///         result against group members selected by the sortition pool.
    /// @param seed seed used to start the DKG and select group members
    /// @return true if group members matches; false otherwise
    function validateGroupMembers(DKG.Result calldata result, uint256 seed)
        public
        view
        returns (bool)
    {
        uint32[] calldata resultMembers = result.members;
        uint32[] memory actualGroupMembers = sortitionPool.selectGroup(
            groupSize,
            bytes32(seed)
        );
        if (resultMembers.length != actualGroupMembers.length) {
            return false;
        }
        for (uint256 i = 0; i < resultMembers.length; i++) {
            if (resultMembers[i] != actualGroupMembers[i]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Performs validation of signatures supplied in DKG result.
    ///         Note that this function does not check if addresses which
    ///         supplied signatures supporting the result are the ones selected
    ///         to the group by sortition pool. This function should be used
    ///         together with `validateGroupMembers`.
    /// @param startBlock DKG start block
    /// @return true if group members matches; false otherwise
    function validateSignatures(DKG.Result calldata result, uint256 startBlock)
        public
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encode(
                block.chainid,
                result.groupPubKey,
                result.misbehavedMembersIndices,
                startBlock
            )
        ).toEthSignedMessageHash();

        uint256[] calldata signingMembersIndices = result.signingMembersIndices;
        uint32[] memory signingMemberIds = new uint32[](
            signingMembersIndices.length
        );
        for (uint256 i = 0; i < signingMembersIndices.length; i++) {
            signingMemberIds[i] = result.members[signingMembersIndices[i] - 1];
        }

        address[] memory signingMemberAddresses = sortitionPool.getIDOperators(
            signingMemberIds
        );

        bytes memory current; // Current signature to be checked.

        uint256 signaturesCount = result.signatures.length / signatureByteSize;
        for (uint256 i = 0; i < signaturesCount; i++) {
            current = result.signatures.slice(
                signatureByteSize * i,
                signatureByteSize
            );
            address recoveredAddress = hash.recover(current);

            if (signingMemberAddresses[i] != recoveredAddress) {
                return false;
            }
        }

        return true;
    }

    /// @notice Performs validation of hashed group members that actively took
    ///         part in DKG.
    /// @param result DKG result
    /// @return true if result's group members hash matches with the one that is
    ///         challenged.
    function validateMembersHash(DKG.Result calldata result)
        public
        pure
        returns (bool)
    {
        if (result.misbehavedMembersIndices.length > 0) {
            // members that generated a group signing key
            uint32[] memory groupMembers = new uint32[](
                result.members.length - result.misbehavedMembersIndices.length
            );
            uint256 k = 0; // misbehaved members counter
            uint256 j = 0; // group members counter
            for (uint256 i = 0; i < result.members.length; i++) {
                // misbehaved member indices start from 1, so we need to -1 on misbehaved
                if (i != result.misbehavedMembersIndices[k] - 1) {
                    groupMembers[j] = result.members[i];
                    j++;
                } else if (k < result.misbehavedMembersIndices.length - 1) {
                    k++;
                }
            }

            return keccak256(abi.encode(groupMembers)) == result.membersHash;
        }

        return keccak256(abi.encode(result.members)) == result.membersHash;
    }
}

pragma solidity 0.8.17;

import "@thesis/solidity-contracts/contracts/token/IERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RNG.sol";
import "./SortitionTree.sol";
import "./Rewards.sol";
import "./Chaosnet.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
contract SortitionPool is
  SortitionTree,
  Rewards,
  Ownable,
  Chaosnet,
  IReceiveApproval
{
  using Branch for uint256;
  using Leaf for uint256;
  using Position for uint256;

  IERC20WithPermit public immutable rewardToken;

  uint256 public immutable poolWeightDivisor;

  bool public isLocked;

  event IneligibleForRewards(uint32[] ids, uint256 until);

  event RewardEligibilityRestored(address indexed operator, uint32 indexed id);

  /// @notice Reverts if called while pool is locked.
  modifier onlyUnlocked() {
    require(!isLocked, "Sortition pool locked");
    _;
  }

  /// @notice Reverts if called while pool is unlocked.
  modifier onlyLocked() {
    require(isLocked, "Sortition pool unlocked");
    _;
  }

  constructor(IERC20WithPermit _rewardToken, uint256 _poolWeightDivisor) {
    rewardToken = _rewardToken;
    poolWeightDivisor = _poolWeightDivisor;
  }

  function receiveApproval(
    address sender,
    uint256 amount,
    address token,
    bytes calldata
  ) external override {
    require(token == address(rewardToken), "Unsupported token");
    rewardToken.transferFrom(sender, address(this), amount);
    Rewards.addRewards(uint96(amount), uint32(root.sumWeight()));
  }

  /// @notice Withdraws all available rewards for the given operator to the
  ///         given beneficiary.
  /// @dev Can be called only be the owner. Does not validate if the provided
  ///      beneficiary is associated with the provided operator - this needs to
  ///      be done by the owner calling this function.
  /// @return The amount of rewards withdrawn in this call.
  function withdrawRewards(address operator, address beneficiary)
    public
    onlyOwner
    returns (uint96)
  {
    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(getPoolWeight(operator)));
    uint96 earned = Rewards.withdrawOperatorRewards(id);
    rewardToken.transfer(beneficiary, uint256(earned));
    return earned;
  }

  /// @notice Withdraws rewards not allocated to operators marked as ineligible
  ///         to the given recipient address.
  /// @dev Can be called only by the owner.
  function withdrawIneligible(address recipient) public onlyOwner {
    uint96 earned = Rewards.withdrawIneligibleRewards();
    rewardToken.transfer(recipient, uint256(earned));
  }

  /// @notice Locks the sortition pool. In locked state, members cannot be
  ///         inserted and removed from the pool. Members statuses cannot
  ///         be updated as well.
  /// @dev Can be called only by the contract owner.
  function lock() public onlyOwner {
    isLocked = true;
  }

  /// @notice Unlocks the sortition pool. Removes all restrictions set by
  ///         the `lock` method.
  /// @dev Can be called only by the contract owner.
  function unlock() public onlyOwner {
    isLocked = false;
  }

  /// @notice Inserts an operator to the pool. Reverts if the operator is
  /// already present. Reverts if the operator is not eligible because of their
  /// authorized stake. Reverts if the chaosnet is active and the operator is
  /// not a beta operator.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the inserted operator.
  /// @param authorizedStake Inserted operator's authorized stake for the application.
  function insertOperator(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);
    require(weight > 0, "Operator not eligible");

    if (isChaosnetActive) {
      require(isBetaOperator[operator], "Not beta operator for chaosnet");
    }

    _insertOperator(operator, weight);
    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(weight));
  }

  /// @notice Update the operator's weight if present and eligible,
  /// or remove from the pool if present and ineligible.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the updated operator.
  /// @param authorizedStake Operator's authorized stake for the application.
  function updateOperatorStatus(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);

    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(weight));

    if (weight == 0) {
      _removeOperator(operator);
    } else {
      updateOperator(operator, weight);
    }
  }

  /// @notice Set the given operators as ineligible for rewards.
  ///         The operators can restore their eligibility at the given time.
  function setRewardIneligibility(uint32[] calldata operators, uint256 until)
    public
    onlyOwner
  {
    Rewards.setIneligible(operators, until);
    emit IneligibleForRewards(operators, until);
  }

  /// @notice Restores reward eligibility for the operator.
  function restoreRewardEligibility(address operator) public {
    uint32 id = getOperatorID(operator);
    Rewards.restoreEligibility(id);
    emit RewardEligibilityRestored(operator, id);
  }

  /// @notice Returns whether the operator is eligible for rewards or not.
  function isEligibleForRewards(address operator) public view returns (bool) {
    uint32 id = getOperatorID(operator);
    return Rewards.isEligibleForRewards(id);
  }

  /// @notice Returns the time the operator's reward eligibility can be restored.
  function rewardsEligibilityRestorableAt(address operator)
    public
    view
    returns (uint256)
  {
    uint32 id = getOperatorID(operator);
    return Rewards.rewardsEligibilityRestorableAt(id);
  }

  /// @notice Returns whether the operator is able to restore their eligibility
  ///         for rewards right away.
  function canRestoreRewardEligibility(address operator)
    public
    view
    returns (bool)
  {
    uint32 id = getOperatorID(operator);
    return Rewards.canRestoreRewardEligibility(id);
  }

  /// @notice Returns the amount of rewards withdrawable for the given operator.
  function getAvailableRewards(address operator) public view returns (uint96) {
    uint32 id = getOperatorID(operator);
    return availableRewards(id);
  }

  /// @notice Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Return whether the operator's weight in the pool
  /// matches their eligible weight.
  function isOperatorUpToDate(address operator, uint256 authorizedStake)
    public
    view
    returns (bool)
  {
    return getWeight(authorizedStake) == getPoolWeight(operator);
  }

  /// @notice Return the weight of the operator in the pool,
  /// which may or may not be out of date.
  function getPoolWeight(address operator) public view returns (uint256) {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    if (flaggedPosition == 0) {
      return 0;
    } else {
      uint256 leafPosition = flaggedPosition.unsetFlag();
      uint256 leafWeight = getLeafWeight(leafPosition);
      return leafWeight;
    }
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed. At least one operator has to be
  /// registered in the pool, otherwise the function fails reverting the
  /// transaction.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @return selected Members of the selected group
  function selectGroup(uint256 groupSize, bytes32 seed)
    public
    view
    onlyLocked
    returns (uint32[] memory)
  {
    uint256 _root = root;

    bytes32 rngState = seed;
    uint256 rngRange = _root.sumWeight();
    require(rngRange > 0, "Not enough operators in pool");
    uint256 currentIndex;

    uint256 bits = RNG.bitsRequired(rngRange);

    uint32[] memory selected = new uint32[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
      (currentIndex, rngState) = RNG.getIndex(rngRange, rngState, bits);

      uint256 leafPosition = pickWeightedLeaf(currentIndex, _root);

      uint256 leaf = leaves[leafPosition];
      selected[i] = leaf.id();
    }
    return selected;
  }

  function getWeight(uint256 authorization) internal view returns (uint256) {
    return authorization / poolWeightDivisor;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity ^0.8.9;

/// @title  Application interface for Threshold Network applications
/// @notice Generic interface for an application. Application is an external
///         smart contract or a set of smart contracts utilizing functionalities
///         offered by Threshold Network. Applications authorized for the given
///         staking provider are eligible to slash the stake delegated to that
///         staking provider.
interface IApplication {
    /// @dev Event emitted by `withdrawRewards` function.
    event RewardsWithdrawn(address indexed stakingProvider, uint96 amount);

    /// @notice Withdraws application rewards for the given staking provider.
    ///         Rewards are withdrawn to the staking provider's beneficiary
    ///         address set in the staking contract.
    /// @dev Emits `RewardsWithdrawn` event.
    function withdrawRewards(address stakingProvider) external;

    /// @notice Used by T staking contract to inform the application that the
    ///         authorized amount for the given staking provider increased.
    ///         The application may do any necessary housekeeping. The
    ///         application must revert the transaction in case the
    ///         authorization is below the minimum required.
    function authorizationIncreased(
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external;

    /// @notice Used by T staking contract to inform the application that the
    ///         authorization decrease for the given staking provider has been
    ///         requested. The application should mark the authorization as
    ///         pending decrease and respond to the staking contract with
    ///         `approveAuthorizationDecrease` at its discretion. It may
    ///         happen right away but it also may happen several months later.
    ///         If there is already a pending authorization decrease request
    ///         for the application, and the application does not agree for
    ///         overwriting it, the function should revert.
    function authorizationDecreaseRequested(
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external;

    /// @notice Used by T staking contract to inform the application the
    ///         authorization has been decreased for the given staking provider
    ///         involuntarily, as a result of slashing. Lets the application to
    ///         do any housekeeping neccessary. Called with 250k gas limit and
    ///         does not revert the transaction if
    ///         `involuntaryAuthorizationDecrease` call failed.
    function involuntaryAuthorizationDecrease(
        address stakingProvider,
        uint96 fromAmount,
        uint96 toAmount
    ) external;

    /// @notice Returns the amount of application rewards available for
    ///         withdrawal for the given staking provider.
    function availableRewards(address stakingProvider)
        external
        view
        returns (uint96);

    /// @notice The minimum authorization amount required for the staking
    ///         provider so that they can participate in the application.
    function minimumAuthorization() external view returns (uint96);
}

// SPDX-License-Identifier: GPL-3.0-or-later

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity ^0.8.9;

/// @title Interface of Threshold Network staking contract
/// @notice The staking contract enables T owners to have their wallets offline
///         and their stake managed by staking providers on their behalf.
///         The staking contract does not define operator role. The operator
///         responsible for running off-chain client software is appointed by
///         the staking provider in the particular application utilizing the
///         staking contract. All off-chain client software should be able
///         to run without exposing operator's or staking provider’s private
///         key and should not require any owner’s keys at all. The stake
///         delegation optimizes the network throughput without compromising the
///         security of the owners’ stake.
interface IStaking {
    enum StakeType {
        NU,
        KEEP,
        T
    }

    //
    //
    // Delegating a stake
    //
    //

    /// @notice Creates a delegation with `msg.sender` owner with the given
    ///         staking provider, beneficiary, and authorizer. Transfers the
    ///         given amount of T to the staking contract.
    /// @dev The owner of the delegation needs to have the amount approved to
    ///      transfer to the staking contract.
    function stake(
        address stakingProvider,
        address payable beneficiary,
        address authorizer,
        uint96 amount
    ) external;

    /// @notice Copies delegation from the legacy KEEP staking contract to T
    ///         staking contract. No tokens are transferred. Caches the active
    ///         stake amount from KEEP staking contract. Can be called by
    ///         anyone.
    /// @dev The staking provider in T staking contract is the legacy KEEP
    ///      staking contract operator.
    function stakeKeep(address stakingProvider) external;

    /// @notice Copies delegation from the legacy NU staking contract to T
    ///         staking contract, additionally appointing staking provider,
    ///         beneficiary and authorizer roles. Caches the amount staked in NU
    ///         staking contract. Can be called only by the original delegation
    ///         owner.
    function stakeNu(
        address stakingProvider,
        address payable beneficiary,
        address authorizer
    ) external;

    /// @notice Refresh Keep stake owner. Can be called only by the old owner
    ///         or their staking provider.
    /// @dev The staking provider in T staking contract is the legacy KEEP
    ///      staking contract operator.
    function refreshKeepStakeOwner(address stakingProvider) external;

    /// @notice Allows the Governance to set the minimum required stake amount.
    ///         This amount is required to protect against griefing the staking
    ///         contract and individual applications are allowed to require
    ///         higher minimum stakes if necessary.
    function setMinimumStakeAmount(uint96 amount) external;

    //
    //
    // Authorizing an application
    //
    //

    /// @notice Allows the Governance to approve the particular application
    ///         before individual stake authorizers are able to authorize it.
    function approveApplication(address application) external;

    /// @notice Increases the authorization of the given staking provider for
    ///         the given application by the given amount. Can only be called by
    ///         the authorizer for that staking provider.
    /// @dev Calls `authorizationIncreased(address stakingProvider, uint256 amount)`
    ///      on the given application to notify the application about
    ///      authorization change. See `IApplication`.
    function increaseAuthorization(
        address stakingProvider,
        address application,
        uint96 amount
    ) external;

    /// @notice Requests decrease of the authorization for the given staking
    ///         provider on the given application by the provided amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given staking provider’s authorizer. Overwrites pending
    ///         authorization decrease for the given staking provider and
    ///         application if the application agrees for that. If the
    ///         application does not agree for overwriting, the function
    ///         reverts.
    /// @dev Calls `authorizationDecreaseRequested(address stakingProvider, uint256 amount)`
    ///      on the given application. See `IApplication`.
    function requestAuthorizationDecrease(
        address stakingProvider,
        address application,
        uint96 amount
    ) external;

    /// @notice Requests decrease of all authorizations for the given staking
    ///         provider on all applications by all authorized amount.
    ///         It may not change the authorized amount immediatelly. When
    ///         it happens depends on the application. Can only be called by the
    ///         given staking provider’s authorizer. Overwrites pending
    ///         authorization decrease for the given staking provider and
    ///         application.
    /// @dev Calls `authorizationDecreaseRequested(address stakingProvider, uint256 amount)`
    ///      for each authorized application. See `IApplication`.
    function requestAuthorizationDecrease(address stakingProvider) external;

    /// @notice Called by the application at its discretion to approve the
    ///         previously requested authorization decrease request. Can only be
    ///         called by the application that was previously requested to
    ///         decrease the authorization for that staking provider.
    ///         Returns resulting authorized amount for the application.
    function approveAuthorizationDecrease(address stakingProvider)
        external
        returns (uint96);

    /// @notice Decreases the authorization for the given `stakingProvider` on
    ///         the given disabled `application`, for all authorized amount.
    ///         Can be called by anyone.
    function forceDecreaseAuthorization(
        address stakingProvider,
        address application
    ) external;

    /// @notice Pauses the given application’s eligibility to slash stakes.
    ///         Besides that stakers can't change authorization to the application.
    ///         Can be called only by the Panic Button of the particular
    ///         application. The paused application can not slash stakes until
    ///         it is approved again by the Governance using `approveApplication`
    ///         function. Should be used only in case of an emergency.
    function pauseApplication(address application) external;

    /// @notice Disables the given application. The disabled application can't
    ///         slash stakers. Also stakers can't increase authorization to that
    ///         application but can decrease without waiting by calling
    ///         `requestAuthorizationDecrease` at any moment. Can be called only
    ///         by the governance. The disabled application can't be approved
    ///         again. Should be used only in case of an emergency.
    function disableApplication(address application) external;

    /// @notice Sets the Panic Button role for the given application to the
    ///         provided address. Can only be called by the Governance. If the
    ///         Panic Button for the given application should be disabled, the
    ///         role address should be set to 0x0 address.
    function setPanicButton(address application, address panicButton) external;

    /// @notice Sets the maximum number of applications one staking provider can
    ///         have authorized. Used to protect against DoSing slashing queue.
    ///         Can only be called by the Governance.
    function setAuthorizationCeiling(uint256 ceiling) external;

    //
    //
    // Stake top-up
    //
    //

    /// @notice Increases the amount of the stake for the given staking provider.
    /// @dev The sender of this transaction needs to have the amount approved to
    ///      transfer to the staking contract.
    function topUp(address stakingProvider, uint96 amount) external;

    /// @notice Propagates information about stake top-up from the legacy KEEP
    ///         staking contract to T staking contract. Can be called only by
    ///         the owner or the staking provider.
    function topUpKeep(address stakingProvider) external;

    /// @notice Propagates information about stake top-up from the legacy NU
    ///         staking contract to T staking contract. Can be called only by
    ///         the owner or the staking provider.
    function topUpNu(address stakingProvider) external;

    //
    //
    // Undelegating a stake (unstaking)
    //
    //

    /// @notice Reduces the liquid T stake amount by the provided amount and
    ///         withdraws T to the owner. Reverts if there is at least one
    ///         authorization higher than the sum of the legacy stake and
    ///         remaining liquid T stake or if the unstake amount is higher than
    ///         the liquid T stake amount. Can be called only by the delegation
    ///         owner or the staking provider.
    function unstakeT(address stakingProvider, uint96 amount) external;

    /// @notice Sets the legacy KEEP staking contract active stake amount cached
    ///         in T staking contract to 0. Reverts if the amount of liquid T
    ///         staked in T staking contract is lower than the highest
    ///         application authorization. This function allows to unstake from
    ///         KEEP staking contract and still being able to operate in T
    ///         network and earning rewards based on the liquid T staked. Can be
    ///         called only by the delegation owner or the staking provider.
    function unstakeKeep(address stakingProvider) external;

    /// @notice Reduces cached legacy NU stake amount by the provided amount.
    ///         Reverts if there is at least one authorization higher than the
    ///         sum of remaining legacy NU stake and liquid T stake for that
    ///         staking provider or if the untaked amount is higher than the
    ///         cached legacy stake amount. If succeeded, the legacy NU stake
    ///         can be partially or fully undelegated on the legacy staking
    ///         contract. This function allows to unstake from NU staking
    ///         contract and still being able to operate in T network and
    ///         earning rewards based on the liquid T staked. Can be called only
    ///         by the delegation owner or the staking provider.
    function unstakeNu(address stakingProvider, uint96 amount) external;

    /// @notice Sets cached legacy stake amount to 0, sets the liquid T stake
    ///         amount to 0 and withdraws all liquid T from the stake to the
    ///         owner. Reverts if there is at least one non-zero authorization.
    ///         Can be called only by the delegation owner or the staking
    ///         provider.
    function unstakeAll(address stakingProvider) external;

    //
    //
    // Keeping information in sync
    //
    //

    /// @notice Notifies about the discrepancy between legacy KEEP active stake
    ///         and the amount cached in T staking contract. Slashes the staking
    ///         provider in case the amount cached is higher than the actual
    ///         active stake amount in KEEP staking contract. Needs to update
    ///         authorizations of all affected applications and execute an
    ///         involuntary allocation decrease on all affected applications.
    ///         Can be called by anyone, notifier receives a reward.
    function notifyKeepStakeDiscrepancy(address stakingProvider) external;

    /// @notice Notifies about the discrepancy between legacy NU active stake
    ///         and the amount cached in T staking contract. Slashes the
    ///         staking provider in case the amount cached is higher than the
    ///         actual active stake amount in NU staking contract. Needs to
    ///         update authorizations of all affected applications and execute
    ///         an involuntary allocation decrease on all affected applications.
    ///         Can be called by anyone, notifier receives a reward.
    function notifyNuStakeDiscrepancy(address stakingProvider) external;

    /// @notice Sets the penalty amount for stake discrepancy and reward
    ///         multiplier for reporting it. The penalty is seized from the
    ///         delegated stake, and 5% of the penalty, scaled by the
    ///         multiplier, is given to the notifier. The rest of the tokens are
    ///         burned. Can only be called by the Governance. See `seize` function.
    function setStakeDiscrepancyPenalty(
        uint96 penalty,
        uint256 rewardMultiplier
    ) external;

    /// @notice Sets reward in T tokens for notification of misbehaviour
    ///         of one staking provider. Can only be called by the governance.
    function setNotificationReward(uint96 reward) external;

    /// @notice Transfer some amount of T tokens as reward for notifications
    ///         of misbehaviour
    function pushNotificationReward(uint96 reward) external;

    /// @notice Withdraw some amount of T tokens from notifiers treasury.
    ///         Can only be called by the governance.
    function withdrawNotificationReward(address recipient, uint96 amount)
        external;

    /// @notice Adds staking providers to the slashing queue along with the
    ///         amount that should be slashed from each one of them. Can only be
    ///         called by application authorized for all staking providers in
    ///         the array.
    function slash(uint96 amount, address[] memory stakingProviders) external;

    /// @notice Adds staking providers to the slashing queue along with the
    ///         amount. The notifier will receive reward per each staking
    ///         provider from notifiers treasury. Can only be called by
    ///         application authorized for all staking providers in the array.
    function seize(
        uint96 amount,
        uint256 rewardMultipier,
        address notifier,
        address[] memory stakingProviders
    ) external;

    /// @notice Takes the given number of queued slashing operations and
    ///         processes them. Receives 5% of the slashed amount.
    ///         Executes `involuntaryAllocationDecrease` function on each
    ///         affected application.
    function processSlashing(uint256 count) external;

    //
    //
    // Auxiliary functions
    //
    //

    /// @notice Returns the authorized stake amount of the staking provider for
    ///         the application.
    function authorizedStake(address stakingProvider, address application)
        external
        view
        returns (uint96);

    /// @notice Returns staked amount of T, Keep and Nu for the specified
    ///         staking provider.
    /// @dev    All values are in T denomination
    function stakes(address stakingProvider)
        external
        view
        returns (
            uint96 tStake,
            uint96 keepInTStake,
            uint96 nuInTStake
        );

    /// @notice Returns start staking timestamp.
    /// @dev    This value is set at most once.
    function getStartStakingTimestamp(address stakingProvider)
        external
        view
        returns (uint256);

    /// @notice Returns staked amount of NU for the specified staking provider.
    function stakedNu(address stakingProvider) external view returns (uint256);

    /// @notice Gets the stake owner, the beneficiary and the authorizer
    ///         for the specified staking provider address.
    /// @return owner Stake owner address.
    /// @return beneficiary Beneficiary address.
    /// @return authorizer Authorizer address.
    function rolesOf(address stakingProvider)
        external
        view
        returns (
            address owner,
            address payable beneficiary,
            address authorizer
        );

    /// @notice Returns length of application array
    function getApplicationsLength() external view returns (uint256);

    /// @notice Returns length of slashing queue
    function getSlashingQueueLength() external view returns (uint256);

    /// @notice Returns minimum possible stake for T, KEEP or NU in T
    ///         denomination.
    /// @dev For example, suppose the given staking provider has 10 T, 20 T
    ///      worth of KEEP, and 30 T worth of NU all staked, and the maximum
    ///      application authorization is 40 T, then `getMinStaked` for
    ///      that staking provider returns:
    ///          * 0 T if KEEP stake type specified i.e.
    ///            min = 40 T max - (10 T + 30 T worth of NU) = 0 T
    ///          * 10 T if NU stake type specified i.e.
    ///            min = 40 T max - (10 T + 20 T worth of KEEP) = 10 T
    ///          * 0 T if T stake type specified i.e.
    ///            min = 40 T max - (20 T worth of KEEP + 30 T worth of NU) < 0 T
    ///      In other words, the minimum stake amount for the specified
    ///      stake type is the minimum amount of stake of the given type
    ///      needed to satisfy the maximum application authorization given the
    ///      staked amounts of the other stake types for that staking provider.
    function getMinStaked(address stakingProvider, StakeType stakeTypes)
        external
        view
        returns (uint96);

    /// @notice Returns available amount to authorize for the specified application
    function getAvailableToAuthorize(
        address stakingProvider,
        address application
    ) external view returns (uint96);
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

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

interface IRandomBeaconConsumer {
    /// @notice Receives relay entry produced by Keep Random Beacon. This function
    /// should be called only by Keep Random Beacon.
    ///
    /// @param relayEntry Relay entry (random number) produced by Keep Random
    ///                   Beacon.
    /// @param blockNumber Block number at which the relay entry was submitted
    ///                    to the chain.
    function __beaconCallback(uint256 relayEntry, uint256 blockNumber) external;
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

import "./ModUtils.sol";

/// @title Operations on alt_bn128
/// @dev Implementations of common elliptic curve operations on Ethereum's
///      (poorly named) alt_bn128 curve. Whenever possible, use post-Byzantium
///      pre-compiled contracts to offset gas costs. Note that these
///      pre-compiles might not be available on all (eg private) chains.
library AltBn128 {
    using ModUtils for uint256;

    // G1Point implements a point in G1 group.
    struct G1Point {
        uint256 x;
        uint256 y;
    }

    // gfP2 implements a field of size p² as a quadratic extension of the base
    // field.
    struct gfP2 {
        uint256 x;
        uint256 y;
    }

    // G2Point implements a point in G2 group.
    struct G2Point {
        gfP2 x;
        gfP2 y;
    }

    // p is a prime over which we form a basic field
    // Taken from go-ethereum/crypto/bn256/cloudflare/constants.go
    uint256 internal constant p =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    /// @dev Gets generator of G1 group.
    ///      Taken from go-ethereum/crypto/bn256/cloudflare/curve.go
    uint256 internal constant g1x = 1;
    uint256 internal constant g1y = 2;

    /// @dev Gets generator of G2 group.
    ///      Taken from go-ethereum/crypto/bn256/cloudflare/twist.go
    uint256 internal constant g2xx =
        11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 internal constant g2xy =
        10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 internal constant g2yx =
        4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 internal constant g2yy =
        8495653923123431417604973247489272438418190587263600148770280649306958101930;

    /// @dev Gets twist curve B constant.
    ///      Taken from go-ethereum/crypto/bn256/cloudflare/twist.go
    uint256 internal constant twistBx =
        266929791119991161246907387137283842545076965332900288569378510910307636690;
    uint256 internal constant twistBy =
        19485874751759354771024239261021720505790618469301721065564631296452457478373;

    /// @dev Gets root of the point where x and y are equal.
    uint256 internal constant hexRootX =
        21573744529824266246521972077326577680729363968861965890554801909984373949499;
    uint256 internal constant hexRootY =
        16854739155576650954933913186877292401521110422362946064090026408937773542853;

    /// @dev g1YFromX computes a Y value for a G1 point based on an X value.
    ///      This computation is simply evaluating the curve equation for Y on a
    ///      given X, and allows a point on the curve to be represented by just
    ///      an X value + a sign bit.
    function g1YFromX(uint256 x) internal view returns (uint256) {
        return ((x.modExp(3, p) + 3) % p).modSqrt(p);
    }

    /// @dev Hash a byte array message, m, and map it deterministically to a
    ///      point on G1. Note that this approach was chosen for its simplicity
    ///      and lower gas cost on the EVM, rather than good distribution of
    ///      points on G1.
    function g1HashToPoint(bytes memory m)
        internal
        view
        returns (G1Point memory)
    {
        unchecked {
            bytes32 h = sha256(m);
            uint256 x = uint256(h) % p;
            uint256 y;

            while (true) {
                y = g1YFromX(x);
                if (y > 0) {
                    return G1Point(x, y);
                }
                x += 1;
            }
        }
    }

    /// @dev Decompress a point on G1 from a single uint256.
    function g1Decompress(bytes32 m) internal view returns (G1Point memory) {
        unchecked {
            bytes32 mX = bytes32(0);
            bytes1 leadX = m[0] & 0x7f;
            // slither-disable-next-line incorrect-shift
            uint256 mask = 0xff << (31 * 8);
            mX = (m & ~bytes32(mask)) | (leadX >> 0);

            uint256 x = uint256(mX);
            uint256 y = g1YFromX(x);

            if (parity(y) != (m[0] & 0x80) >> 7) {
                y = p - y;
            }

            require(
                isG1PointOnCurve(G1Point(x, y)),
                "Malformed bn256.G1 point."
            );

            return G1Point(x, y);
        }
    }

    /// @dev Wraps the point addition pre-compile introduced in Byzantium.
    ///      Returns the sum of two points on G1. Revert if the provided points
    ///      are not on the curve.
    function g1Add(G1Point memory a, G1Point memory b)
        internal
        view
        returns (G1Point memory c)
    {
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(a))
            mstore(add(arg, 0x20), mload(add(a, 0x20)))
            mstore(add(arg, 0x40), mload(b))
            mstore(add(arg, 0x60), mload(add(b, 0x20)))
            // 0x60 is the ECADD precompile address
            if iszero(staticcall(not(0), 0x06, arg, 0x80, c, 0x40)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Returns true if G1 point is on the curve.
    function isG1PointOnCurve(G1Point memory point)
        internal
        view
        returns (bool)
    {
        return point.y.modExp(2, p) == (point.x.modExp(3, p) + 3) % p;
    }

    /// @dev Wraps the scalar point multiplication pre-compile introduced in
    ///      Byzantium. The result of a point from G1 multiplied by a scalar
    ///      should match the point added to itself the same number of times.
    ///      Revert if the provided point isn't on the curve.
    function scalarMultiply(G1Point memory p_1, uint256 scalar)
        internal
        view
        returns (G1Point memory p_2)
    {
        assembly {
            let arg := mload(0x40)
            mstore(arg, mload(p_1))
            mstore(add(arg, 0x20), mload(add(p_1, 0x20)))
            mstore(add(arg, 0x40), scalar)
            // 0x07 is the ECMUL precompile address
            if iszero(staticcall(not(0), 0x07, arg, 0x60, p_2, 0x40)) {
                revert(0, 0)
            }
        }
    }

    /// @dev Wraps the pairing check pre-compile introduced in Byzantium.
    ///      Returns the result of a pairing check of 2 pairs
    ///      (G1 p1, G2 p2) (G1 p3, G2 p4)
    function pairing(
        G1Point memory p1,
        G2Point memory p2,
        G1Point memory p3,
        G2Point memory p4
    ) internal view returns (bool result) {
        uint256 _c;
        assembly {
            let c := mload(0x40)
            let arg := add(c, 0x20)

            mstore(arg, mload(p1))
            mstore(add(arg, 0x20), mload(add(p1, 0x20)))

            let p2x := mload(p2)
            mstore(add(arg, 0x40), mload(p2x))
            mstore(add(arg, 0x60), mload(add(p2x, 0x20)))

            let p2y := mload(add(p2, 0x20))
            mstore(add(arg, 0x80), mload(p2y))
            mstore(add(arg, 0xa0), mload(add(p2y, 0x20)))

            mstore(add(arg, 0xc0), mload(p3))
            mstore(add(arg, 0xe0), mload(add(p3, 0x20)))

            let p4x := mload(p4)
            mstore(add(arg, 0x100), mload(p4x))
            mstore(add(arg, 0x120), mload(add(p4x, 0x20)))

            let p4y := mload(add(p4, 0x20))
            mstore(add(arg, 0x140), mload(p4y))
            mstore(add(arg, 0x160), mload(add(p4y, 0x20)))

            // call(gasLimit, to, value, inputOffset, inputSize, outputOffset, outputSize)
            if iszero(staticcall(not(0), 0x08, arg, 0x180, c, 0x20)) {
                revert(0, 0)
            }
            _c := mload(c)
        }
        return _c != 0;
    }

    function getP() internal pure returns (uint256) {
        return p;
    }

    function g1() internal pure returns (G1Point memory) {
        return G1Point(g1x, g1y);
    }

    function g2() internal pure returns (G2Point memory) {
        return G2Point(gfP2(g2xx, g2xy), gfP2(g2yx, g2yy));
    }

    /// @dev g2YFromX computes a Y value for a G2 point based on an X value.
    ///      This computation is simply evaluating the curve equation for Y on a
    ///      given X, and allows a point on the curve to be represented by just
    ///      an X value + a sign bit.
    function g2YFromX(gfP2 memory _x) internal pure returns (gfP2 memory y) {
        (uint256 xx, uint256 xy) = _gfP2CubeAddTwistB(_x.x, _x.y);

        // Using formula y = x ^ (p^2 + 15) / 32 from
        // https://github.com/ethereum/beacon_chain/blob/master/beacon_chain/utils/bls.py
        // (p^2 + 15) / 32 results into a big 512bit value, so breaking it to two uint256 as (a * a + b)
        uint256 a = 3869331240733915743250440106392954448556483137451914450067252501901456824595;
        uint256 b = 146360017852723390495514512480590656176144969185739259173561346299185050597;

        (uint256 xbx, uint256 xby) = _gfP2Pow(xx, xy, b);
        (uint256 yax, uint256 yay) = _gfP2Pow(xx, xy, a);
        (uint256 ya2x, uint256 ya2y) = _gfP2Pow(yax, yay, a);
        (y.x, y.y) = _gfP2Multiply(ya2x, ya2y, xbx, xby);

        // Multiply y by hexRoot constant to find correct y.
        while (!_g2X2y(xx, xy, y.x, y.y)) {
            (y.x, y.y) = _gfP2Multiply(y.x, y.y, hexRootX, hexRootY);
        }
    }

    /// @dev Compress a point on G1 to a single uint256 for serialization.
    function g1Compress(G1Point memory point) internal pure returns (bytes32) {
        bytes32 m = bytes32(point.x);

        bytes1 leadM = m[0] | (parity(point.y) << 7);
        // slither-disable-next-line incorrect-shift
        uint256 mask = 0xff << (31 * 8);
        m = (m & ~bytes32(mask)) | (leadM >> 0);

        return m;
    }

    /// @dev Compress a point on G2 to a pair of uint256 for serialization.
    function g2Compress(G2Point memory point)
        internal
        pure
        returns (bytes memory)
    {
        bytes32 m = bytes32(point.x.x);

        bytes1 leadM = m[0] | (parity(point.y.x) << 7);
        // slither-disable-next-line incorrect-shift
        uint256 mask = 0xff << (31 * 8);
        m = (m & ~bytes32(mask)) | (leadM >> 0);

        return abi.encodePacked(m, bytes32(point.x.y));
    }

    /// @dev Unmarshals a point on G1 from bytes in an uncompressed form.
    function g1Unmarshal(bytes memory m)
        internal
        pure
        returns (G1Point memory)
    {
        require(m.length == 64, "Invalid G1 bytes length");

        bytes32 x;
        bytes32 y;

        assembly {
            x := mload(add(m, 0x20))
            y := mload(add(m, 0x40))
        }

        return G1Point(uint256(x), uint256(y));
    }

    /// @dev Marshals a point on G1 to bytes form.
    function g1Marshal(G1Point memory point)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory m = new bytes(64);
        bytes32 x = bytes32(point.x);
        bytes32 y = bytes32(point.y);

        assembly {
            mstore(add(m, 32), x)
            mstore(add(m, 64), y)
        }

        return m;
    }

    /// @dev Unmarshals a point on G2 from bytes in an uncompressed form.
    function g2Unmarshal(bytes memory m)
        internal
        pure
        returns (G2Point memory)
    {
        require(m.length == 128, "Invalid G2 bytes length");

        uint256 xx;
        uint256 xy;
        uint256 yx;
        uint256 yy;

        assembly {
            xx := mload(add(m, 0x20))
            xy := mload(add(m, 0x40))
            yx := mload(add(m, 0x60))
            yy := mload(add(m, 0x80))
        }

        return G2Point(gfP2(xx, xy), gfP2(yx, yy));
    }

    /// @dev Decompress a point on G2 from a pair of uint256.
    function g2Decompress(bytes memory m)
        internal
        pure
        returns (G2Point memory)
    {
        require(m.length == 64, "Invalid G2 compressed bytes length");

        bytes32 x1;
        bytes32 x2;
        uint256 temp;

        // Extract two bytes32 from bytes array
        assembly {
            temp := add(m, 32)
            x1 := mload(temp)
            temp := add(m, 64)
            x2 := mload(temp)
        }

        bytes32 mX = bytes32(0);
        bytes1 leadX = x1[0] & 0x7f;
        // slither-disable-next-line incorrect-shift
        uint256 mask = 0xff << (31 * 8);
        mX = (x1 & ~bytes32(mask)) | (leadX >> 0);

        gfP2 memory x = gfP2(uint256(mX), uint256(x2));
        gfP2 memory y = g2YFromX(x);

        if (parity(y.x) != (m[0] & 0x80) >> 7) {
            y.x = p - y.x;
            y.y = p - y.y;
        }

        return G2Point(x, y);
    }

    /// @dev Returns the sum of two gfP2 field elements.
    function gfP2Add(gfP2 memory a, gfP2 memory b)
        internal
        pure
        returns (gfP2 memory)
    {
        return gfP2(addmod(a.x, b.x, p), addmod(a.y, b.y, p));
    }

    /// @dev Returns multiplication of two gfP2 field elements.
    function gfP2Multiply(gfP2 memory a, gfP2 memory b)
        internal
        pure
        returns (gfP2 memory)
    {
        return
            gfP2(
                addmod(mulmod(a.x, b.y, p), mulmod(b.x, a.y, p), p),
                addmod(mulmod(a.y, b.y, p), p - mulmod(a.x, b.x, p), p)
            );
    }

    /// @dev Returns gfP2 element to the power of the provided exponent.
    function gfP2Pow(gfP2 memory _a, uint256 _exp)
        internal
        pure
        returns (gfP2 memory result)
    {
        (uint256 x, uint256 y) = _gfP2Pow(_a.x, _a.y, _exp);
        return gfP2(x, y);
    }

    function gfP2Square(gfP2 memory a) internal pure returns (gfP2 memory) {
        return gfP2Multiply(a, a);
    }

    function gfP2Cube(gfP2 memory a) internal pure returns (gfP2 memory) {
        return gfP2Multiply(a, gfP2Square(a));
    }

    function gfP2CubeAddTwistB(gfP2 memory a)
        internal
        pure
        returns (gfP2 memory)
    {
        (uint256 x, uint256 y) = _gfP2CubeAddTwistB(a.x, a.y);
        return gfP2(x, y);
    }

    /// @dev Returns true if G2 point's y^2 equals x.
    function g2X2y(gfP2 memory x, gfP2 memory y) internal pure returns (bool) {
        gfP2 memory y2;
        y2 = gfP2Square(y);

        return (y2.x == x.x && y2.y == x.y);
    }

    /// @dev Returns true if G2 point is on the curve.
    function isG2PointOnCurve(G2Point memory point)
        internal
        pure
        returns (bool)
    {
        (uint256 y2x, uint256 y2y) = _gfP2Square(point.y.x, point.y.y);
        (uint256 x3x, uint256 x3y) = _gfP2CubeAddTwistB(point.x.x, point.x.y);

        return (y2x == x3x && y2y == x3y);
    }

    function twistB() private pure returns (gfP2 memory) {
        return gfP2(twistBx, twistBy);
    }

    function hexRoot() private pure returns (gfP2 memory) {
        return gfP2(hexRootX, hexRootY);
    }

    /// @dev Calculates whether the provided number is even or odd.
    /// @return 0x01 if y is an even number and 0x00 if it's odd.
    function parity(uint256 value) private pure returns (bytes1) {
        return bytes32(value)[31] & 0x01;
    }

    function _gfP2Add(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) private pure returns (uint256 x, uint256 y) {
        x = addmod(ax, bx, p);
        y = addmod(ay, by, p);
    }

    function _gfP2Multiply(
        uint256 ax,
        uint256 ay,
        uint256 bx,
        uint256 by
    ) private pure returns (uint256 x, uint256 y) {
        x = addmod(mulmod(ax, by, p), mulmod(bx, ay, p), p);
        y = addmod(mulmod(ay, by, p), p - mulmod(ax, bx, p), p);
    }

    function _gfP2CubeAddTwistB(uint256 ax, uint256 ay)
        private
        pure
        returns (uint256 x, uint256 y)
    {
        (uint256 a3x, uint256 a3y) = _gfP2Cube(ax, ay);
        return _gfP2Add(a3x, a3y, twistBx, twistBy);
    }

    function _gfP2Pow(
        uint256 _ax,
        uint256 _ay,
        uint256 _exp
    ) private pure returns (uint256 x, uint256 y) {
        uint256 exp = _exp;
        x = 0;
        y = 1;
        uint256 ax = _ax;
        uint256 ay = _ay;

        // Reduce exp dividing by 2 gradually to 0 while computing final
        // result only when exp is an odd number.
        while (exp > 0) {
            if (parity(exp) == 0x01) {
                (x, y) = _gfP2Multiply(x, y, ax, ay);
            }

            unchecked {
                exp = exp / 2;
            }
            (ax, ay) = _gfP2Multiply(ax, ay, ax, ay);
        }
    }

    function _gfP2Square(uint256 _ax, uint256 _ay)
        private
        pure
        returns (uint256 x, uint256 y)
    {
        return _gfP2Multiply(_ax, _ay, _ax, _ay);
    }

    function _gfP2Cube(uint256 _ax, uint256 _ay)
        private
        pure
        returns (uint256 x, uint256 y)
    {
        (uint256 _bx, uint256 _by) = _gfP2Square(_ax, _ay);
        return _gfP2Multiply(_ax, _ay, _bx, _by);
    }

    function _g2X2y(
        uint256 xx,
        uint256 xy,
        uint256 yx,
        uint256 yy
    ) private pure returns (bool) {
        (uint256 y2x, uint256 y2y) = _gfP2Square(yx, yy);

        return (y2x == xx && y2y == xy);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

import "./AltBn128.sol";

/// @title BLS signatures verification
/// @dev Library for verification of 2-pairing-check BLS signatures, including
///      basic, aggregated, or reconstructed threshold BLS signatures, generated
///      using the AltBn128 curve.
library BLS {
    /// @dev Creates a signature over message using the provided secret key.
    function sign(bytes memory message, uint256 secretKey)
        external
        view
        returns (bytes memory)
    {
        AltBn128.G1Point memory p_1 = AltBn128.g1HashToPoint(message);
        AltBn128.G1Point memory p_2 = AltBn128.scalarMultiply(p_1, secretKey);

        return AltBn128.g1Marshal(p_2);
    }

    /// @dev Wraps the functionality of BLS.verify, but hashes a message to
    ///      a point on G1 and marshal to bytes first to allow raw bytes
    ///      verification.
    function verifyBytes(
        bytes memory publicKey,
        bytes memory message,
        bytes memory signature
    ) external view returns (bool) {
        AltBn128.G1Point memory point = AltBn128.g1HashToPoint(message);
        bytes memory messageAsPoint = AltBn128.g1Marshal(point);

        return verify(publicKey, messageAsPoint, signature);
    }

    /// @dev Verify performs the pairing operation to check if the signature
    ///      is correct for the provided message and the corresponding public
    ///      key. Public key must be a valid point on G2 curve in an
    ///      uncompressed format. Message must be a valid point on G1 curve in
    ///      an uncompressed format. Signature must be a valid point on G1
    ///      curve in an uncompressed format.
    function verify(
        bytes memory publicKey,
        bytes memory message,
        bytes memory signature
    ) public view returns (bool) {
        AltBn128.G1Point memory _signature = AltBn128.g1Unmarshal(signature);

        return
            _verify(
                AltBn128.g2Unmarshal(publicKey),
                AltBn128.g1Unmarshal(message),
                _signature
            );
    }

    function _verify(
        AltBn128.G2Point memory publicKey,
        AltBn128.G1Point memory message,
        AltBn128.G1Point memory signature
    ) public view returns (bool) {
        return
            AltBn128.pairing(
                AltBn128.G1Point(signature.x, AltBn128.getP() - signature.y),
                AltBn128.g2(),
                message,
                publicKey
            );
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

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

library ModUtils {
    /// @dev Wraps the modular exponent pre-compile introduced in Byzantium.
    ///      Returns base^exponent mod p.
    function modExp(
        uint256 base,
        uint256 exponent,
        uint256 p
    ) internal view returns (uint256 o) {
        assembly {
            // Args for the precompile: [<length_of_BASE> <length_of_EXPONENT>
            // <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>]
            let output := mload(0x40)
            let args := add(output, 0x20)
            mstore(args, 0x20)
            mstore(add(args, 0x20), 0x20)
            mstore(add(args, 0x40), 0x20)
            mstore(add(args, 0x60), base)
            mstore(add(args, 0x80), exponent)
            mstore(add(args, 0xa0), p)

            // 0x05 is the modular exponent contract address
            if iszero(staticcall(not(0), 0x05, args, 0xc0, output, 0x20)) {
                revert(0, 0)
            }
            o := mload(output)
        }
    }

    /// @dev Calculates and returns the square root of a mod p if such a square
    ///      root exists. The modulus p must be an odd prime. If a square root
    ///      does not exist, function returns 0.
    function modSqrt(uint256 a, uint256 p) internal view returns (uint256) {
        unchecked {
            if (legendre(a, p) != 1) {
                return 0;
            }

            if (a == 0) {
                return 0;
            }

            if (p % 4 == 3) {
                return modExp(a, (p + 1) / 4, p);
            }

            uint256 s = p - 1;
            uint256 e = 0;

            while (s % 2 == 0) {
                s = s / 2;
                e = e + 1;
            }

            // Note the smaller int- finding n with Legendre symbol or -1
            // should be quick
            uint256 n = 2;
            while (legendre(n, p) != -1) {
                n = n + 1;
            }

            uint256 x = modExp(a, (s + 1) / 2, p);
            uint256 b = modExp(a, s, p);
            uint256 g = modExp(n, s, p);
            uint256 r = e;
            uint256 gs = 0;
            uint256 m = 0;
            uint256 t = b;

            while (true) {
                t = b;
                m = 0;

                for (m = 0; m < r; m++) {
                    if (t == 1) {
                        break;
                    }
                    t = modExp(t, 2, p);
                }

                if (m == 0) {
                    return x;
                }

                gs = modExp(g, uint256(2)**(r - m - 1), p);
                g = (gs * gs) % p;
                x = (x * gs) % p;
                b = (b * g) % p;
                r = m;
            }
        }
    }

    /// @dev Calculates the Legendre symbol of the given a mod p.
    /// @return Returns 1 if a is a quadratic residue mod p, -1 if it is
    ///         a non-quadratic residue, and 0 if a is 0.
    function legendre(uint256 a, uint256 p) internal view returns (int256) {
        unchecked {
            uint256 raised = modExp(a, (p - 1) / uint256(2), p);

            if (raised == 0 || raised == 1) {
                return int256(raised);
            } else if (raised == p - 1) {
                return -1;
            }

            require(false, "Failed to calculate legendre.");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ReimbursementPool is Ownable, ReentrancyGuard {
    /// @notice Authorized contracts that can interact with the reimbursment pool.
    ///         Authorization can be granted and removed by the owner.
    mapping(address => bool) public isAuthorized;

    /// @notice Static gas includes:
    ///         - cost of the refund function
    ///         - base transaction cost
    uint256 public staticGas;

    /// @notice Max gas price used to reimburse a transaction submitter. Protects
    ///         against malicious operator-miners.
    uint256 public maxGasPrice;

    event StaticGasUpdated(uint256 newStaticGas);

    event MaxGasPriceUpdated(uint256 newMaxGasPrice);

    event SendingEtherFailed(uint256 refundAmount, address receiver);

    event AuthorizedContract(address thirdPartyContract);

    event UnauthorizedContract(address thirdPartyContract);

    event FundsWithdrawn(uint256 withdrawnAmount, address receiver);

    constructor(uint256 _staticGas, uint256 _maxGasPrice) {
        staticGas = _staticGas;
        maxGasPrice = _maxGasPrice;
    }

    /// @notice Receive ETH
    receive() external payable {}

    /// @notice Refunds ETH to a spender for executing specific transactions.
    /// @dev Ignoring the result of sending ETH to a receiver is made on purpose.
    ///      For EOA receiving ETH should always work. If a receiver is a smart
    ///      contract, then we do not want to fail a transaction, because in some
    ///      cases the refund is done at the very end of multiple calls where all
    ///      the previous calls were already paid off. It is a receiver's smart
    ///      contract resposibility to make sure it can receive ETH.
    /// @dev Only authorized contracts are allowed calling this function.
    /// @param gasSpent Gas spent on a transaction that needs to be reimbursed.
    /// @param receiver Address where the reimbursment is sent.
    function refund(uint256 gasSpent, address receiver) external nonReentrant {
        require(
            isAuthorized[msg.sender],
            "Contract is not authorized for a refund"
        );
        require(receiver != address(0), "Receiver's address cannot be zero");

        uint256 gasPrice = tx.gasprice < maxGasPrice
            ? tx.gasprice
            : maxGasPrice;

        uint256 refundAmount = (gasSpent + staticGas) * gasPrice;

        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,unchecked-lowlevel
        (bool sent, ) = receiver.call{value: refundAmount}("");
        /* solhint-enable avoid-low-level-calls */
        if (!sent) {
            // slither-disable-next-line reentrancy-events
            emit SendingEtherFailed(refundAmount, receiver);
        }
    }

    /// @notice Authorize a contract that can interact with this reimbursment pool.
    ///         Can be authorized by the owner only.
    /// @param _contract Authorized contract.
    function authorize(address _contract) external onlyOwner {
        isAuthorized[_contract] = true;

        emit AuthorizedContract(_contract);
    }

    /// @notice Unauthorize a contract that was previously authorized to interact
    ///         with this reimbursment pool. Can be unauthorized by the
    ///         owner only.
    /// @param _contract Authorized contract.
    function unauthorize(address _contract) external onlyOwner {
        delete isAuthorized[_contract];

        emit UnauthorizedContract(_contract);
    }

    /// @notice Setting a static gas cost for executing a transaction. Can be set
    ///         by the owner only.
    /// @param _staticGas Static gas cost.
    function setStaticGas(uint256 _staticGas) external onlyOwner {
        staticGas = _staticGas;

        emit StaticGasUpdated(_staticGas);
    }

    /// @notice Setting a max gas price for transactions. Can be set by the
    ///         owner only.
    /// @param _maxGasPrice Max gas price used to reimburse tx submitters.
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;

        emit MaxGasPriceUpdated(_maxGasPrice);
    }

    /// @notice Withdraws all ETH from this pool which are sent to a given
    ///         address. Can be set by the owner only.
    /// @param receiver An address where ETH is sent.
    function withdrawAll(address receiver) external onlyOwner {
        withdraw(address(this).balance, receiver);
    }

    /// @notice Withdraws ETH amount from this pool which are sent to a given
    ///         address. Can be set by the owner only.
    /// @param amount Amount to withdraw from the pool.
    /// @param receiver An address where ETH is sent.
    function withdraw(uint256 amount, address receiver) public onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );
        require(receiver != address(0), "Receiver's address cannot be zero");

        emit FundsWithdrawn(amount, receiver);

        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,arbitrary-send
        (bool sent, ) = receiver.call{value: amount}("");
        /* solhint-enable avoid-low-level-calls */
        require(sent, "Failed to send Ether");
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

/*
Version pulled from keep-core v1:
https://github.com/keep-network/keep-core/blob/f297202db00c027978ad8e7103a356503de5773c/solidity-v1/contracts/utils/BytesLib.sol

To compile it with solidity 0.8 `_preBytes_slot` was replaced with `_preBytes.slot`.
*/

/*
https://github.com/GNSPS/solidity-bytes-utils/
This is free and unencumbered software released into the public domain.
Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.
In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
For more information, please refer to <https://unlicense.org>
*/

/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory res) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        uint256 _totalLen = _start + 20;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Address conversion out of bounds."
        );
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(
            _bytes.length >= (_start + 1),
            "Uint8 conversion out of bounds."
        );
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        uint256 _totalLen = _start + 32;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Uint conversion out of bounds."
        );
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function toBytes32(bytes memory _source)
        internal
        pure
        returns (bytes32 result)
    {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes32 result) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
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

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IApproveAndCall.sol";

/// @title  IERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
interface IERC20WithPermit is IERC20, IERC20Metadata, IApproveAndCall {
    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Destroys `amount` tokens from the caller.
    function burn(uint256 amount) external;

    /// @notice Destroys `amount` of tokens from `account`, deducting the amount
    ///         from caller's allowance.
    function burnFrom(address account, uint256 amount) external;

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    function nonce(address owner) external view returns (uint256);

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    /* solhint-disable-next-line func-name-mixedcase */
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by contracts supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IReceiveApproval {
    /// @notice Receives approval to spend tokens. Called as a result of
    ///         `approveAndCall` call on the token.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external;
}

pragma solidity 0.8.17;

import "./Leaf.sol";
import "./Constants.sol";

library RNG {
  /// @notice Get an index in the range `[0 .. range-1]`
  /// and the new state of the RNG,
  /// using the provided `state` of the RNG.
  ///
  /// @param range The upper bound of the index, exclusive.
  ///
  /// @param state The previous state of the RNG.
  /// The initial state needs to be obtained
  /// from a trusted randomness oracle (the random beacon),
  /// or from a chain of earlier calls to `RNG.getIndex()`
  /// on an originally trusted seed.
  ///
  /// @dev Calculates the number of bits required for the desired range,
  /// takes the least significant bits of `state`
  /// and checks if the obtained index is within the desired range.
  /// The original state is hashed with `keccak256` to get a new state.
  /// If the index is outside the range,
  /// the function retries until it gets a suitable index.
  ///
  /// @return index A random integer between `0` and `range - 1`, inclusive.
  ///
  /// @return newState The new state of the RNG.
  /// When `getIndex()` is called one or more times,
  /// care must be taken to always use the output `state`
  /// of the most recent call as the input `state` of a subsequent call.
  /// At the end of a transaction calling `RNG.getIndex()`,
  /// the previous stored state must be overwritten with the latest output.
  function getIndex(
    uint256 range,
    bytes32 state,
    uint256 bits
  ) internal view returns (uint256, bytes32) {
    bool found = false;
    uint256 index = 0;
    bytes32 newState = state;
    while (!found) {
      index = truncate(bits, uint256(newState));
      newState = keccak256(abi.encodePacked(newState, address(this)));
      if (index < range) {
        found = true;
      }
    }
    return (index, newState);
  }

  /// @notice Calculate how many bits are required
  /// for an index in the range `[0 .. range-1]`.
  ///
  /// @param range The upper bound of the desired range, exclusive.
  ///
  /// @return uint The smallest number of bits
  /// that can contain the number `range-1`.
  function bitsRequired(uint256 range) internal pure returns (uint256) {
    unchecked {
      if (range == 1) {
        return 0;
      }

      uint256 bits = Constants.WEIGHT_WIDTH - 1;

      // Left shift by `bits`,
      // so we have a 1 in the (bits + 1)th least significant bit
      // and 0 in other bits.
      // If this number is equal or greater than `range`,
      // the range [0, range-1] fits in `bits` bits.
      //
      // Because we loop from high bits to low bits,
      // we find the highest number of bits that doesn't fit the range,
      // and return that number + 1.
      while (1 << bits >= range) {
        bits--;
      }

      return bits + 1;
    }
  }

  /// @notice Truncate `input` to the `bits` least significant bits.
  function truncate(uint256 bits, uint256 input)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      return input & ((1 << bits) - 1);
    }
  }
}

pragma solidity 0.8.17;

import "./Branch.sol";
import "./Position.sol";
import "./Leaf.sol";
import "./Constants.sol";

contract SortitionTree {
  using Branch for uint256;
  using Position for uint256;
  using Leaf for uint256;

  // implicit tree
  // root 8
  // level2 64
  // level3 512
  // level4 4k
  // level5 32k
  // level6 256k
  // level7 2M
  uint256 internal root;

  // A 2-index mapping from layer => (index (0-index) => branch). For example,
  // to access the 6th branch in the 2nd layer (right below the root node; the
  // first branch layer), call branches[2][5]. Mappings are used in place of
  // arrays for efficiency. The root is the first layer, the branches occupy
  // layers 2 through 7, and layer 8 is for the leaves. Following this
  // convention, the first index in `branches` is `2`, and the last index is
  // `7`.
  mapping(uint256 => mapping(uint256 => uint256)) internal branches;

  // A 0-index mapping from index => leaf, acting as an array. For example, to
  // access the 42nd leaf, call leaves[41].
  mapping(uint256 => uint256) internal leaves;

  // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
  // of all operators present in the pool
  mapping(address => uint256) internal flaggedLeafPosition;

  // the leaf after the rightmost occupied leaf of each stack
  uint256 internal rightmostLeaf;

  // the empty leaves in each stack
  // between 0 and the rightmost occupied leaf
  uint256[] internal emptyLeaves;

  // Each operator has an uint32 ID number
  // which is allocated when they first join the pool
  // and remains unchanged even if they leave and rejoin the pool.
  mapping(address => uint32) internal operatorID;

  // The idAddress array records the address corresponding to each ID number.
  // The ID number 0 is initialized with a zero address and is not used.
  address[] internal idAddress;

  constructor() {
    root = 0;
    rightmostLeaf = 0;
    idAddress.push();
  }

  /// @notice Return the ID number of the given operator address. An ID number
  /// of 0 means the operator has not been allocated an ID number yet.
  /// @param operator Address of the operator.
  /// @return the ID number of the given operator address
  function getOperatorID(address operator) public view returns (uint32) {
    return operatorID[operator];
  }

  /// @notice Get the operator address corresponding to the given ID number. A
  /// zero address means the ID number has not been allocated yet.
  /// @param id ID of the operator
  /// @return the address of the operator
  function getIDOperator(uint32 id) public view returns (address) {
    return idAddress.length > id ? idAddress[id] : address(0);
  }

  /// @notice Gets the operator addresses corresponding to the given ID
  /// numbers. A zero address means the ID number has not been allocated yet.
  /// This function works just like getIDOperator except that it allows to fetch
  /// operator addresses for multiple IDs in one call.
  /// @param ids the array of the operator ids
  /// @return an array of the associated operator addresses
  function getIDOperators(uint32[] calldata ids)
    public
    view
    returns (address[] memory)
  {
    uint256 idCount = idAddress.length;

    address[] memory operators = new address[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      uint32 id = ids[i];
      operators[i] = idCount > id ? idAddress[id] : address(0);
    }
    return operators;
  }

  /// @notice Checks if operator is already registered in the pool.
  /// @param operator the address of the operator
  /// @return whether or not the operator is already registered in the pool
  function isOperatorRegistered(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Sum the number of operators in each trunk.
  /// @return the number of operators in the pool
  function operatorsInPool() public view returns (uint256) {
    // Get the number of leaves that might be occupied;
    // if `rightmostLeaf` equals `firstLeaf()` the tree must be empty,
    // otherwise the difference between these numbers
    // gives the number of leaves that may be occupied.
    uint256 nPossiblyUsedLeaves = rightmostLeaf;
    // Get the number of empty leaves
    // not accounted for by the `rightmostLeaf`
    uint256 nEmptyLeaves = emptyLeaves.length;

    return (nPossiblyUsedLeaves - nEmptyLeaves);
  }

  /// @notice Convenience method to return the total weight of the pool
  /// @return the total weight of the pool
  function totalWeight() public view returns (uint256) {
    return root.sumWeight();
  }

  /// @notice Give the operator a new ID number.
  /// Does not check if the operator already has an ID number.
  /// @param operator the address of the operator
  /// @return a new ID for that operator
  function allocateOperatorID(address operator) internal returns (uint256) {
    uint256 id = idAddress.length;

    require(id <= type(uint32).max, "Pool capacity exceeded");

    operatorID[operator] = uint32(id);
    idAddress.push(operator);
    return id;
  }

  /// @notice Inserts an operator into the sortition pool
  /// @param operator the address of an operator to insert
  /// @param weight how much weight that operator has in the pool
  function _insertOperator(address operator, uint256 weight) internal {
    require(
      !isOperatorRegistered(operator),
      "Operator is already registered in the pool"
    );

    // Fetch the operator's ID, and if they don't have one, allocate them one.
    uint256 id = getOperatorID(operator);
    if (id == 0) {
      id = allocateOperatorID(operator);
    }

    // Determine which leaf to insert them into
    uint256 position = getEmptyLeafPosition();
    // Record the block the operator was inserted in
    uint256 theLeaf = Leaf.make(operator, block.number, id);

    // Update the leaf, and propagate the weight changes all the way up to the
    // root.
    root = setLeaf(position, theLeaf, weight, root);

    // Without position flags,
    // the position 0x000000 would be treated as empty
    flaggedLeafPosition[operator] = position.setFlag();
  }

  /// @notice Remove an operator (and their weight) from the pool.
  /// @param operator the address of the operator to remove
  function _removeOperator(address operator) internal {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    require(flaggedPosition != 0, "Operator is not registered in the pool");
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();

    // Update the leaf, and propagate the weight changes all the way up to the
    // root.
    root = removeLeaf(unflaggedPosition, root);
    removeLeafPositionRecord(operator);
  }

  /// @notice Update an operator's weight in the pool.
  /// @param operator the address of the operator to update
  /// @param weight the new weight
  function updateOperator(address operator, uint256 weight) internal {
    require(
      isOperatorRegistered(operator),
      "Operator is not registered in the pool"
    );

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = updateLeaf(unflaggedPosition, weight, root);
  }

  /// @notice Helper method to remove a leaf position record for an operator.
  /// @param operator the address of the operator to remove the record for
  function removeLeafPositionRecord(address operator) internal {
    flaggedLeafPosition[operator] = 0;
  }

  /// @notice Removes the data and weight from a particular leaf.
  /// @param position the leaf index to remove
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function removeLeaf(uint256 position, uint256 _root)
    internal
    returns (uint256)
  {
    uint256 rightmostSubOne = rightmostLeaf - 1;
    bool isRightmost = position == rightmostSubOne;

    // Clears out the data in the leaf node, and then propagates the weight
    // changes all the way up to the root.
    uint256 newRoot = setLeaf(position, 0, 0, _root);

    // Infer if need to fall back on emptyLeaves yet
    if (isRightmost) {
      rightmostLeaf = rightmostSubOne;
    } else {
      emptyLeaves.push(position);
    }
    return newRoot;
  }

  /// @notice Updates the tree to give a particular leaf a new weight.
  /// @param position the index of the leaf to update
  /// @param weight the new weight
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function updateLeaf(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    if (getLeafWeight(position) != weight) {
      return updateTree(position, weight, _root);
    } else {
      return _root;
    }
  }

  /// @notice Places a leaf into a particular position, with a given weight and
  /// propagates that change.
  /// @param position the index to place the leaf in
  /// @param theLeaf the new leaf to place in the position
  /// @param leafWeight the weight of the leaf
  /// @param _root the root containing the new leaf
  /// @return the updated root node
  function setLeaf(
    uint256 position,
    uint256 theLeaf,
    uint256 leafWeight,
    uint256 _root
  ) internal returns (uint256) {
    // set leaf
    leaves[position] = theLeaf;

    return (updateTree(position, leafWeight, _root));
  }

  /// @notice Propagates a weight change at a position through the tree,
  /// eventually returning the updated root.
  /// @param position the index of leaf to update
  /// @param weight the new weight of the leaf
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function updateTree(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    uint256 childSlot;
    uint256 treeNode;
    uint256 newNode;
    uint256 nodeWeight = weight;

    uint256 parent = position;
    // set levels 7 to 2
    for (uint256 level = Constants.LEVELS; level >= 2; level--) {
      childSlot = parent.slot();
      parent = parent.parent();
      treeNode = branches[level][parent];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      branches[level][parent] = newNode;
      nodeWeight = newNode.sumWeight();
    }

    // set level Root
    childSlot = parent.slot();
    return _root.setSlot(childSlot, nodeWeight);
  }

  /// @notice Retrieves the next available empty leaf position. Tries to fill
  /// left to right first, ignoring leaf removals, and then fills
  /// most-recent-removals first.
  /// @return the position of the empty leaf
  function getEmptyLeafPosition() internal returns (uint256) {
    uint256 rLeaf = rightmostLeaf;
    bool spaceOnRight = (rLeaf + 1) < Constants.POOL_CAPACITY;
    if (spaceOnRight) {
      rightmostLeaf = rLeaf + 1;
      return rLeaf;
    } else {
      uint256 emptyLeafCount = emptyLeaves.length;
      require(emptyLeafCount > 0, "Pool is full");
      uint256 emptyLeaf = emptyLeaves[emptyLeafCount - 1];
      emptyLeaves.pop();
      return emptyLeaf;
    }
  }

  /// @notice Gets the flagged leaf position for an operator.
  /// @param operator the address of the operator
  /// @return the leaf position of that operator
  function getFlaggedLeafPosition(address operator)
    internal
    view
    returns (uint256)
  {
    return flaggedLeafPosition[operator];
  }

  /// @notice Gets the weight of a leaf at a particular position.
  /// @param position the index of the leaf
  /// @return the weight of the leaf at that position
  function getLeafWeight(uint256 position) internal view returns (uint256) {
    uint256 slot = position.slot();
    uint256 parent = position.parent();

    // A leaf's weight information is stored a 32-bit slot in the branch layer
    // directly above the leaf layer. To access it, we calculate that slot and
    // parent position, and always know the hard-coded layer index.
    uint256 node = branches[Constants.LEVELS][parent];
    return node.getSlot(slot);
  }

  /// @notice Picks a leaf given a random index.
  /// @param index a number in `[0, _root.totalWeight())` used to decide
  /// between leaves
  /// @param _root the root of the tree
  function pickWeightedLeaf(uint256 index, uint256 _root)
    internal
    view
    returns (uint256 leafPosition)
  {
    uint256 currentIndex = index;
    uint256 currentNode = _root;
    uint256 currentPosition = 0;
    uint256 currentSlot;

    require(index < currentNode.sumWeight(), "Index exceeds weight");

    // get root slot
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

    // get slots from levels 2 to 7
    for (uint256 level = 2; level <= Constants.LEVELS; level++) {
      currentPosition = currentPosition.child(currentSlot);
      currentNode = branches[level][currentPosition];
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
    }

    // get leaf position
    leafPosition = currentPosition.child(currentSlot);
  }
}

pragma solidity 0.8.17;

/// @title Rewards
/// @notice Rewards are allocated proportionally to operators
/// present in the pool at payout based on their weight in the pool.
///
/// To facilitate this, we use a global accumulator value
/// to track the total rewards one unit of weight would've earned
/// since the creation of the pool.
///
/// Whenever a reward is paid, the accumulator is increased
/// by the size of the reward divided by the total weight
/// of all eligible operators in the pool.
///
/// Each operator has an individual accumulator value,
/// set to equal the global accumulator when the operator joins the pool.
/// This accumulator reflects the amount of rewards
/// that have already been accounted for with that operator.
///
/// Whenever an operator's weight in the pool changes,
/// we can update the amount of rewards the operator has earned
/// by subtracting the operator's accumulator from the global accumulator.
/// This gives us the amount of rewards one unit of weight has earned
/// since the last time the operator's rewards have been updated.
/// Then we multiply that by the operator's previous (pre-change) weight
/// to determine how much rewards in total the operator has earned,
/// and add this to the operator's earned rewards.
/// Finally, we set the operator's accumulator to the global accumulator value.
contract Rewards {
  struct OperatorRewards {
    // The state of the global accumulator
    // when the operator's rewards were last updated
    uint96 accumulated;
    // The amount of rewards collected by the operator after the latest update.
    // The amount the operator could withdraw may equal `available`
    // or it may be greater, if more rewards have been paid in since then.
    // To evaulate the most recent amount including rewards potentially paid
    // since the last update, use `availableRewards` function.
    uint96 available;
    // If nonzero, the operator is ineligible for rewards
    // and may only re-enable rewards after the specified timestamp.
    // XXX: unsigned 32-bit integer unix seconds, will break around 2106
    uint32 ineligibleUntil;
    // Locally cached weight of the operator,
    // used to reduce the cost of setting operators ineligible.
    uint32 weight;
  }

  // The global accumulator of how much rewards
  // a hypothetical operator of weight 1 would have earned
  // since the creation of the pool.
  uint96 internal globalRewardAccumulator;
  // If the amount of reward tokens paid in
  // does not divide cleanly by pool weight,
  // the difference is recorded as rounding dust
  // and added to the next reward.
  uint96 internal rewardRoundingDust;

  // The amount of rewards that would've been earned by ineligible operators
  // had they not been ineligible.
  uint96 public ineligibleEarnedRewards;

  // Ineligibility times are calculated from this offset,
  // set at contract creation.
  uint256 internal immutable ineligibleOffsetStart;

  mapping(uint32 => OperatorRewards) internal operatorRewards;

  constructor() {
    // solhint-disable-next-line not-rely-on-time
    ineligibleOffsetStart = block.timestamp;
  }

  /// @notice Return whether the operator is eligible for rewards or not.
  function isEligibleForRewards(uint32 operator) internal view returns (bool) {
    return operatorRewards[operator].ineligibleUntil == 0;
  }

  /// @notice Return the time the operator's reward eligibility can be restored.
  function rewardsEligibilityRestorableAt(uint32 operator)
    internal
    view
    returns (uint256)
  {
    uint32 until = operatorRewards[operator].ineligibleUntil;
    require(until != 0, "Operator already eligible");
    return (uint256(until) + ineligibleOffsetStart);
  }

  /// @notice Return whether the operator is able to restore their eligibility
  ///         for rewards right away.
  function canRestoreRewardEligibility(uint32 operator)
    internal
    view
    returns (bool)
  {
    // solhint-disable-next-line not-rely-on-time
    return rewardsEligibilityRestorableAt(operator) <= block.timestamp;
  }

  /// @notice Internal function for updating the global state of rewards.
  function addRewards(uint96 rewardAmount, uint32 currentPoolWeight) internal {
    require(currentPoolWeight > 0, "No recipients in pool");

    uint96 totalAmount = rewardAmount + rewardRoundingDust;
    uint96 perWeightReward = totalAmount / currentPoolWeight;
    uint96 newRoundingDust = totalAmount % currentPoolWeight;

    globalRewardAccumulator += perWeightReward;
    rewardRoundingDust = newRoundingDust;
  }

  /// @notice Internal function for updating the operator's reward state.
  function updateOperatorRewards(uint32 operator, uint32 newWeight) internal {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, update their earned rewards
      o.available += accruedRewards;
    } else {
      // If ineligible, put the rewards into the ineligible pot
      ineligibleEarnedRewards += accruedRewards;
    }
    // In any case, update their accumulator and weight
    o.accumulated = acc;
    o.weight = newWeight;
    operatorRewards[operator] = o;
  }

  /// @notice Set the amount of withdrawable tokens to zero
  /// and return the previous withdrawable amount.
  /// @dev Does not update the withdrawable amount,
  /// but should usually be accompanied by an update.
  function withdrawOperatorRewards(uint32 operator)
    internal
    returns (uint96 withdrawable)
  {
    OperatorRewards storage o = operatorRewards[operator];
    withdrawable = o.available;
    o.available = 0;
  }

  /// @notice Set the amount of ineligible-earned tokens to zero
  /// and return the previous amount.
  function withdrawIneligibleRewards() internal returns (uint96 withdrawable) {
    withdrawable = ineligibleEarnedRewards;
    ineligibleEarnedRewards = 0;
  }

  /// @notice Set the given operators as ineligible for rewards.
  /// The operators can restore their eligibility at the given time.
  function setIneligible(uint32[] memory operators, uint256 until) internal {
    OperatorRewards memory o = OperatorRewards(0, 0, 0, 0);
    uint96 globalAcc = globalRewardAccumulator;
    uint96 accrued = 0;
    // Record ineligibility as seconds after contract creation
    uint32 _until = uint32(until - ineligibleOffsetStart);

    for (uint256 i = 0; i < operators.length; i++) {
      uint32 operator = operators[i];
      OperatorRewards storage r = operatorRewards[operator];
      o.available = r.available;
      o.accumulated = r.accumulated;
      o.ineligibleUntil = r.ineligibleUntil;
      o.weight = r.weight;

      if (o.ineligibleUntil != 0) {
        // If operator is already ineligible,
        // don't earn rewards or shorten its ineligibility
        if (o.ineligibleUntil < _until) {
          o.ineligibleUntil = _until;
        }
      } else {
        // The operator becomes ineligible -> earn rewards
        o.ineligibleUntil = _until;
        accrued = (globalAcc - o.accumulated) * uint96(o.weight);
        o.available += accrued;
      }
      o.accumulated = globalAcc;

      r.available = o.available;
      r.accumulated = o.accumulated;
      r.ineligibleUntil = o.ineligibleUntil;
      r.weight = o.weight;
    }
  }

  /// @notice Restore the given operator's eligibility for rewards.
  function restoreEligibility(uint32 operator) internal {
    // solhint-disable-next-line not-rely-on-time
    require(canRestoreRewardEligibility(operator), "Operator still ineligible");
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
    ineligibleEarnedRewards += accruedRewards;
    o.accumulated = acc;
    o.ineligibleUntil = 0;
    operatorRewards[operator] = o;
  }

  /// @notice Returns the amount of rewards currently available for withdrawal
  ///         for the given operator.
  function availableRewards(uint32 operator) internal view returns (uint96) {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, calculate newly accrued rewards and add
      // them to the available ones, calculated during the last update.
      uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
      return o.available + accruedRewards;
    } else {
      // If ineligible, return only the rewards calculated during the last
      // update.
      return o.available;
    }
  }
}

pragma solidity 0.8.17;

/// @title Chaosnet
/// @notice This is a beta staker program for stakers willing to go the extra
/// mile with monitoring, share their logs with the dev team, and allow to more
/// carefully monitor the bootstrapping network. As the network matures, the
/// beta program will be ended.
contract Chaosnet {
  /// @notice Indicates if the chaosnet is active. The chaosnet is active
  /// after the contract deployment and can be ended with a call to
  /// `deactivateChaosnet()`. Once deactivated chaosnet can not be activated
  /// again.
  bool public isChaosnetActive;

  /// @notice Indicates if the given operator is a beta operator for chaosnet.
  mapping(address => bool) public isBetaOperator;

  /// @notice Address controlling chaosnet status and beta operator addresses.
  address public chaosnetOwner;

  event BetaOperatorsAdded(address[] operators);

  event ChaosnetOwnerRoleTransferred(
    address oldChaosnetOwner,
    address newChaosnetOwner
  );

  event ChaosnetDeactivated();

  constructor() {
    _transferChaosnetOwner(msg.sender);
    isChaosnetActive = true;
  }

  modifier onlyChaosnetOwner() {
    require(msg.sender == chaosnetOwner, "Not the chaosnet owner");
    _;
  }

  modifier onlyOnChaosnet() {
    require(isChaosnetActive, "Chaosnet is not active");
    _;
  }

  /// @notice Adds beta operator to chaosnet. Can be called only by the
  /// chaosnet owner when the chaosnet is active. Once the operator is added
  /// as a beta operator, it can not be removed.
  function addBetaOperators(address[] calldata operators)
    public
    onlyOnChaosnet
    onlyChaosnetOwner
  {
    for (uint256 i = 0; i < operators.length; i++) {
      isBetaOperator[operators[i]] = true;
    }

    emit BetaOperatorsAdded(operators);
  }

  /// @notice Deactivates the chaosnet. Can be called only by the chaosnet
  /// owner. Once deactivated chaosnet can not be activated again.
  function deactivateChaosnet() public onlyOnChaosnet onlyChaosnetOwner {
    isChaosnetActive = false;
    emit ChaosnetDeactivated();
  }

  /// @notice Transfers the chaosnet owner role to another non-zero address.
  function transferChaosnetOwnerRole(address newChaosnetOwner)
    public
    onlyChaosnetOwner
  {
    require(
      newChaosnetOwner != address(0),
      "New chaosnet owner must not be zero address"
    );
    _transferChaosnetOwner(newChaosnetOwner);
  }

  function _transferChaosnetOwner(address newChaosnetOwner) internal {
    address oldChaosnetOwner = chaosnetOwner;
    chaosnetOwner = newChaosnetOwner;
    emit ChaosnetOwnerRoleTransferred(oldChaosnetOwner, newChaosnetOwner);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by tokens supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IApproveAndCall {
    /// @notice Executes `receiveApproval` function on spender as specified in
    ///         `IReceiveApproval` interface. Approves spender to withdraw from
    ///         the caller multiple times, up to the `amount`. If this
    ///         function is called again, it overwrites the current allowance
    ///         with `amount`. Reverts if the approval reverted or if
    ///         `receiveApproval` call on the spender reverted.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external returns (bool);
}

pragma solidity 0.8.17;

import "./Constants.sol";

library Leaf {
  function make(
    address _operator,
    uint256 _creationBlock,
    uint256 _id
  ) internal pure returns (uint256) {
    assert(_creationBlock <= type(uint64).max);
    assert(_id <= type(uint32).max);
    // Converting a bytesX type into a larger type
    // adds zero bytes on the right.
    uint256 op = uint256(bytes32(bytes20(_operator)));
    // Bitwise AND the id to erase
    // all but the 32 least significant bits
    uint256 uid = _id & Constants.ID_MAX;
    // Erase all but the 64 least significant bits,
    // then shift left by 32 bits to make room for the id
    uint256 cb = (_creationBlock & Constants.BLOCKHEIGHT_MAX) <<
      Constants.ID_WIDTH;
    // Bitwise OR them all together to get
    // [address operator || uint64 creationBlock || uint32 id]
    return (op | cb | uid);
  }

  function operator(uint256 leaf) internal pure returns (address) {
    // Converting a bytesX type into a smaller type
    // truncates it on the right.
    return address(bytes20(bytes32(leaf)));
  }

  /// @notice Return the block number the leaf was created in.
  function creationBlock(uint256 leaf) internal pure returns (uint256) {
    return ((leaf >> Constants.ID_WIDTH) & Constants.BLOCKHEIGHT_MAX);
  }

  function id(uint256 leaf) internal pure returns (uint32) {
    // Id is stored in the 32 least significant bits.
    // Bitwise AND ensures that we only get the contents of those bits.
    return uint32(leaf & Constants.ID_MAX);
  }
}

pragma solidity 0.8.17;

library Constants {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  uint256 constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant LAST_SLOT = SLOT_COUNT - 1;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;
  uint256 constant POOL_CAPACITY = SLOT_COUNT**LEVELS;

  uint256 constant ID_WIDTH = SLOT_WIDTH;
  uint256 constant ID_MAX = SLOT_MAX;

  uint256 constant BLOCKHEIGHT_WIDTH = 96 - ID_WIDTH;
  uint256 constant BLOCKHEIGHT_MAX = (2**BLOCKHEIGHT_WIDTH) - 1;

  uint256 constant SLOT_POINTER_MAX = (2**SLOT_BITS) - 1;
  uint256 constant LEAF_FLAG = 1 << 255;

  uint256 constant WEIGHT_WIDTH = 256 / SLOT_COUNT;
  ////////////////////////////////////////////////////////////////////////////
}

pragma solidity 0.8.17;

import "./Constants.sol";

/// @notice The implicit 8-ary trees of the sortition pool
/// rely on packing 8 "slots" of 32-bit values into each uint256.
/// The Branch library permits efficient calculations on these slots.
library Branch {
  /// @notice Calculate the right shift required
  /// to make the 32 least significant bits of an uint256
  /// be the bits of the `position`th slot
  /// when treating the uint256 as a uint32[8].
  ///
  /// @dev Not used for efficiency reasons,
  /// but left to illustrate the meaning of a common pattern.
  /// I wish solidity had macros, even C macros.
  function slotShift(uint256 position) internal pure returns (uint256) {
    unchecked {
      return position * Constants.SLOT_WIDTH;
    }
  }

  /// @notice Return the `position`th slot of the `node`,
  /// treating `node` as a uint32[32].
  function getSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Doing a bitwise AND with `SLOT_MAX`
      // clears all but the 32 least significant bits.
      // Because of the right shift by `slotShift(position)` bits,
      // those 32 bits contain the 32 bits in the `position`th slot of `node`.
      return (node >> shiftBits) & Constants.SLOT_MAX;
    }
  }

  /// @notice Return `node` with the `position`th slot set to zero.
  function clearSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Shifting `SLOT_MAX` left by `slotShift(position)` bits
      // gives us a number where all bits of the `position`th slot are set,
      // and all other bits are unset.
      //
      // Using a bitwise NOT on this number,
      // we get a uint256 where all bits are set
      // except for those of the `position`th slot.
      //
      // Bitwise ANDing the original `node` with this number
      // sets the bits of `position`th slot to zero,
      // leaving all other bits unchanged.
      return node & ~(Constants.SLOT_MAX << shiftBits);
    }
  }

  /// @notice Return `node` with the `position`th slot set to `weight`.
  ///
  /// @param weight The weight of of the node.
  /// Safely truncated to a 32-bit number,
  /// but this should never be called with an overflowing weight regardless.
  function setSlot(
    uint256 node,
    uint256 position,
    uint256 weight
  ) internal pure returns (uint256) {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Clear the `position`th slot like in `clearSlot()`.
      uint256 clearedNode = node & ~(Constants.SLOT_MAX << shiftBits);
      // Bitwise AND `weight` with `SLOT_MAX`
      // to clear all but the 32 least significant bits.
      //
      // Shift this left by `slotShift(position)` bits
      // to obtain a uint256 with all bits unset
      // except in the `position`th slot
      // which contains the 32-bit value of `weight`.
      uint256 shiftedWeight = (weight & Constants.SLOT_MAX) << shiftBits;
      // When we bitwise OR these together,
      // all other slots except the `position`th one come from the left argument,
      // and the `position`th gets filled with `weight` from the right argument.
      return clearedNode | shiftedWeight;
    }
  }

  /// @notice Calculate the summed weight of all slots in the `node`.
  function sumWeight(uint256 node) internal pure returns (uint256 sum) {
    unchecked {
      sum = node & Constants.SLOT_MAX;
      // Iterate through each slot
      // by shifting `node` right in increments of 32 bits,
      // and adding the 32 least significant bits to the `sum`.
      uint256 newNode = node >> Constants.SLOT_WIDTH;
      while (newNode > 0) {
        sum += (newNode & Constants.SLOT_MAX);
        newNode = newNode >> Constants.SLOT_WIDTH;
      }
      return sum;
    }
  }

  /// @notice Pick a slot in `node` that corresponds to `index`.
  /// Treats the node like an array of virtual stakers,
  /// the number of virtual stakers in each slot corresponding to its weight,
  /// and picks which slot contains the `index`th virtual staker.
  ///
  /// @dev Requires that `index` be lower than `sumWeight(node)`.
  /// However, this is not enforced for performance reasons.
  /// If `index` exceeds the permitted range,
  /// `pickWeightedSlot()` returns the rightmost slot
  /// and an excessively high `newIndex`.
  ///
  /// @return slot The slot of `node` containing the `index`th virtual staker.
  ///
  /// @return newIndex The index of the `index`th virtual staker of `node`
  /// within the returned slot.
  function pickWeightedSlot(uint256 node, uint256 index)
    internal
    pure
    returns (uint256 slot, uint256 newIndex)
  {
    unchecked {
      newIndex = index;
      uint256 newNode = node;
      uint256 currentSlotWeight = newNode & Constants.SLOT_MAX;
      while (newIndex >= currentSlotWeight) {
        newIndex -= currentSlotWeight;
        slot++;
        newNode = newNode >> Constants.SLOT_WIDTH;
        currentSlotWeight = newNode & Constants.SLOT_MAX;
      }
      return (slot, newIndex);
    }
  }
}

pragma solidity 0.8.17;

import "./Constants.sol";

library Position {
  // Return the last 3 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint256 a) internal pure returns (uint256) {
    return a & Constants.SLOT_POINTER_MAX;
  }

  // Return the parent of a position number
  function parent(uint256 a) internal pure returns (uint256) {
    return a >> Constants.SLOT_BITS;
  }

  // Return the location of the child of a at the given slot
  function child(uint256 a, uint256 s) internal pure returns (uint256) {
    return (a << Constants.SLOT_BITS) | (s & Constants.SLOT_POINTER_MAX); // slot(s)
  }

  // Return the uint p as a flagged position uint:
  // the least significant 21 bits contain the position
  // and the 22nd bit is set as a flag
  // to distinguish the position 0x000000 from an empty field.
  function setFlag(uint256 p) internal pure returns (uint256) {
    return p | Constants.LEAF_FLAG;
  }

  // Turn a flagged position into an unflagged position
  // by removing the flag at the 22nd least significant bit.
  //
  // We shouldn't _actually_ need this
  // as all position-manipulating code should ignore non-position bits anyway
  // but it's cheap to call so might as well do it.
  function unsetFlag(uint256 p) internal pure returns (uint256) {
    return p & (~Constants.LEAF_FLAG);
  }
}