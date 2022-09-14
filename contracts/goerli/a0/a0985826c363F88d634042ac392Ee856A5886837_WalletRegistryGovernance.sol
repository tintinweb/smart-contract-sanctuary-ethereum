// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

import "./WalletRegistry.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@keep-network/random-beacon/contracts/ReimbursementPool.sol";

import {IWalletOwner} from "./api/IWalletOwner.sol";
import {IRandomBeacon} from "@keep-network/random-beacon/contracts/api/IRandomBeacon.sol";

/// @title Wallet Registry Governance
/// @notice Owns the `WalletRegistry` contract and is responsible for updating
///         its governable parameters in respect to the governance delay.
contract WalletRegistryGovernance is Ownable {
    uint256 public newGovernanceDelay;
    uint256 public governanceDelayChangeInitiated;

    address public newWalletRegistryGovernance;
    uint256 public walletRegistryGovernanceTransferInitiated;

    address public newWalletOwner;
    uint256 public walletOwnerChangeInitiated;

    uint96 public newMinimumAuthorization;
    uint256 public minimumAuthorizationChangeInitiated;

    uint64 public newAuthorizationDecreaseDelay;
    uint256 public authorizationDecreaseDelayChangeInitiated;

    uint64 public newAuthorizationDecreaseChangePeriod;
    uint256 public authorizationDecreaseChangePeriodChangeInitiated;

    uint96 public newMaliciousDkgResultSlashingAmount;
    uint256 public maliciousDkgResultSlashingAmountChangeInitiated;

    uint256 public newMaliciousDkgResultNotificationRewardMultiplier;
    uint256
        public maliciousDkgResultNotificationRewardMultiplierChangeInitiated;

    uint256 public newSortitionPoolRewardsBanDuration;
    uint256 public sortitionPoolRewardsBanDurationChangeInitiated;

    uint256 public newDkgSeedTimeout;
    uint256 public dkgSeedTimeoutChangeInitiated;

    uint256 public newDkgResultChallengePeriodLength;
    uint256 public dkgResultChallengePeriodLengthChangeInitiated;

    uint256 public newDkgResultChallengeExtraGas;
    uint256 public dkgResultChallengeExtraGasChangeInitiated;

    uint256 public newDkgResultSubmissionTimeout;
    uint256 public dkgResultSubmissionTimeoutChangeInitiated;

    uint256 public newSubmitterPrecedencePeriodLength;
    uint256 public dkgSubmitterPrecedencePeriodLengthChangeInitiated;

    uint256 public newDkgResultSubmissionGas;
    uint256 public dkgResultSubmissionGasChangeInitiated;

    uint256 public newDkgResultApprovalGasOffset;
    uint256 public dkgResultApprovalGasOffsetChangeInitiated;

    uint256 public newNotifyOperatorInactivityGasOffset;
    uint256 public notifyOperatorInactivityGasOffsetChangeInitiated;

    uint256 public newNotifySeedTimeoutGasOffset;
    uint256 public notifySeedTimeoutGasOffsetChangeInitiated;

    uint256 public newNotifyDkgTimeoutNegativeGasOffset;
    uint256 public notifyDkgTimeoutNegativeGasOffsetChangeInitiated;

    address payable public newReimbursementPool;
    uint256 public reimbursementPoolChangeInitiated;

    WalletRegistry public immutable walletRegistry;

    uint256 public governanceDelay;

    event GovernanceDelayUpdateStarted(
        uint256 governanceDelay,
        uint256 timestamp
    );
    event GovernanceDelayUpdated(uint256 governanceDelay);

    event WalletRegistryGovernanceTransferStarted(
        address newWalletRegistryGovernance,
        uint256 timestamp
    );
    event WalletRegistryGovernanceTransferred(
        address newWalletRegistryGovernance
    );

    event WalletOwnerUpdateStarted(address walletOwner, uint256 timestamp);
    event WalletOwnerUpdated(address walletOwner);

    event MinimumAuthorizationUpdateStarted(
        uint96 minimumAuthorization,
        uint256 timestamp
    );
    event MinimumAuthorizationUpdated(uint96 minimumAuthorization);

    event AuthorizationDecreaseDelayUpdateStarted(
        uint64 authorizationDecreaseDelay,
        uint256 timestamp
    );
    event AuthorizationDecreaseDelayUpdated(uint64 authorizationDecreaseDelay);

    event AuthorizationDecreaseChangePeriodUpdateStarted(
        uint64 authorizationDecreaseChangePeriod,
        uint256 timestamp
    );

    event AuthorizationDecreaseChangePeriodUpdated(
        uint64 authorizationDecreaseChangePeriod
    );

    event MaliciousDkgResultSlashingAmountUpdateStarted(
        uint256 maliciousDkgResultSlashingAmount,
        uint256 timestamp
    );
    event MaliciousDkgResultSlashingAmountUpdated(
        uint256 maliciousDkgResultSlashingAmount
    );

    event MaliciousDkgResultNotificationRewardMultiplierUpdateStarted(
        uint256 maliciousDkgResultNotificationRewardMultiplier,
        uint256 timestamp
    );
    event MaliciousDkgResultNotificationRewardMultiplierUpdated(
        uint256 maliciousDkgResultNotificationRewardMultiplier
    );

    event SortitionPoolRewardsBanDurationUpdateStarted(
        uint256 sortitionPoolRewardsBanDuration,
        uint256 timestamp
    );
    event SortitionPoolRewardsBanDurationUpdated(
        uint256 sortitionPoolRewardsBanDuration
    );

    event DkgSeedTimeoutUpdateStarted(
        uint256 dkgSeedTimeout,
        uint256 timestamp
    );
    event DkgSeedTimeoutUpdated(uint256 dkgSeedTimeout);

    event DkgResultChallengePeriodLengthUpdateStarted(
        uint256 dkgResultChallengePeriodLength,
        uint256 timestamp
    );
    event DkgResultChallengePeriodLengthUpdated(
        uint256 dkgResultChallengePeriodLength
    );

    event DkgResultChallengeExtraGasUpdateStarted(
        uint256 dkgResultChallengeExtraGas,
        uint256 timestamp
    );
    event DkgResultChallengeExtraGasUpdated(uint256 dkgResultChallengeExtraGas);

    event DkgResultSubmissionTimeoutUpdateStarted(
        uint256 dkgResultSubmissionTimeout,
        uint256 timestamp
    );
    event DkgResultSubmissionTimeoutUpdated(uint256 dkgResultSubmissionTimeout);

    event DkgSubmitterPrecedencePeriodLengthUpdateStarted(
        uint256 submitterPrecedencePeriodLength,
        uint256 timestamp
    );
    event DkgSubmitterPrecedencePeriodLengthUpdated(
        uint256 submitterPrecedencePeriodLength
    );

    event DkgResultSubmissionGasUpdateStarted(
        uint256 dkgResultSubmissionGas,
        uint256 timestamp
    );
    event DkgResultSubmissionGasUpdated(uint256 dkgResultSubmissionGas);

    event DkgResultApprovalGasOffsetUpdateStarted(
        uint256 dkgResultApprovalGasOffset,
        uint256 timestamp
    );
    event DkgResultApprovalGasOffsetUpdated(uint256 dkgResultApprovalGasOffset);

    event NotifyOperatorInactivityGasOffsetUpdateStarted(
        uint256 notifyOperatorInactivityGasOffset,
        uint256 timestamp
    );
    event NotifyOperatorInactivityGasOffsetUpdated(
        uint256 notifyOperatorInactivityGasOffset
    );

    event NotifySeedTimeoutGasOffsetUpdateStarted(
        uint256 notifySeedTimeoutGasOffset,
        uint256 timestamp
    );
    event NotifySeedTimeoutGasOffsetUpdated(uint256 notifySeedTimeoutGasOffset);

    event NotifyDkgTimeoutNegativeGasOffsetUpdateStarted(
        uint256 notifyDkgTimeoutNegativeGasOffset,
        uint256 timestamp
    );
    event NotifyDkgTimeoutNegativeGasOffsetUpdated(
        uint256 notifyDkgTimeoutNegativeGasOffset
    );

    event ReimbursementPoolUpdateStarted(
        address reimbursementPool,
        uint256 timestamp
    );
    event ReimbursementPoolUpdated(address reimbursementPool);

    /// @notice Reverts if called before the governance delay elapses.
    /// @param changeInitiatedTimestamp Timestamp indicating the beginning
    ///        of the change.
    modifier onlyAfterGovernanceDelay(uint256 changeInitiatedTimestamp) {
        /* solhint-disable not-rely-on-time */
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            block.timestamp - changeInitiatedTimestamp >= governanceDelay,
            "Governance delay has not elapsed"
        );
        _;
        /* solhint-enable not-rely-on-time */
    }

    constructor(WalletRegistry _walletRegistry, uint256 _governanceDelay) {
        walletRegistry = _walletRegistry;
        governanceDelay = _governanceDelay;
    }

    /// @notice Upgrades the random beacon.
    /// @dev Can be called only by the contract owner.
    /// @param _newRandomBeacon New random beacon address
    function upgradeRandomBeacon(address _newRandomBeacon) external onlyOwner {
        require(
            _newRandomBeacon != address(0),
            "New random beacon address cannot be zero"
        );

        walletRegistry.upgradeRandomBeacon(IRandomBeacon(_newRandomBeacon));
    }

    /// @notice Initializes the Wallet Owner's address.
    /// @dev Can be called only by the contract owner. It can be called only if
    ///      walletOwner has not been set before. It doesn't enforce a governance
    ///      delay for the initial update. Any subsequent updates should be performed
    ///      with beginWalletOwnerUpdate/finalizeWalletOwnerUpdate with respect
    ///      of a governance delay.
    /// @param _walletOwner The Wallet Owner's address
    function initializeWalletOwner(address _walletOwner) external onlyOwner {
        require(
            address(walletRegistry.walletOwner()) == address(0),
            "Wallet Owner already initialized"
        );
        require(
            _walletOwner != address(0),
            "Wallet Owner address cannot be zero"
        );

        walletRegistry.updateWalletOwner(IWalletOwner(_walletOwner));
    }

    /// @notice Begins the governance delay update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newGovernanceDelay New governance delay
    function beginGovernanceDelayUpdate(uint256 _newGovernanceDelay)
        external
        onlyOwner
    {
        newGovernanceDelay = _newGovernanceDelay;
        /* solhint-disable not-rely-on-time */
        governanceDelayChangeInitiated = block.timestamp;
        emit GovernanceDelayUpdateStarted(_newGovernanceDelay, block.timestamp);
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the governance delay update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeGovernanceDelayUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(governanceDelayChangeInitiated)
    {
        emit GovernanceDelayUpdated(newGovernanceDelay);
        governanceDelay = newGovernanceDelay;
        governanceDelayChangeInitiated = 0;
        newGovernanceDelay = 0;
    }

    /// @notice Begins the wallet registry governance transfer process.
    /// @dev Can be called only by the contract owner.
    function beginWalletRegistryGovernanceTransfer(
        address _newWalletRegistryGovernance
    ) external onlyOwner {
        require(
            address(_newWalletRegistryGovernance) != address(0),
            "New wallet registry governance address cannot be zero"
        );
        newWalletRegistryGovernance = _newWalletRegistryGovernance;
        /* solhint-disable not-rely-on-time */
        walletRegistryGovernanceTransferInitiated = block.timestamp;
        emit WalletRegistryGovernanceTransferStarted(
            _newWalletRegistryGovernance,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet registry governance transfer process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeWalletRegistryGovernanceTransfer()
        external
        onlyOwner
        onlyAfterGovernanceDelay(walletRegistryGovernanceTransferInitiated)
    {
        emit WalletRegistryGovernanceTransferred(newWalletRegistryGovernance);
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.transferGovernance(newWalletRegistryGovernance);
        walletRegistryGovernanceTransferInitiated = 0;
        newWalletRegistryGovernance = address(0);
    }

    /// @notice Begins the wallet owner update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newWalletOwner New wallet owner address
    function beginWalletOwnerUpdate(address _newWalletOwner)
        external
        onlyOwner
    {
        require(
            address(_newWalletOwner) != address(0),
            "New wallet owner address cannot be zero"
        );
        /* solhint-disable not-rely-on-time */
        newWalletOwner = _newWalletOwner;
        walletOwnerChangeInitiated = block.timestamp;
        emit WalletOwnerUpdateStarted(_newWalletOwner, block.timestamp);
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet owner update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeWalletOwnerUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(walletOwnerChangeInitiated)
    {
        emit WalletOwnerUpdated(newWalletOwner);
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateWalletOwner(IWalletOwner(newWalletOwner));
        walletOwnerChangeInitiated = 0;
        newWalletOwner = address(0);
    }

    /// @notice Begins the minimum authorization amount update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newMinimumAuthorization New minimum authorization amount.
    function beginMinimumAuthorizationUpdate(uint96 _newMinimumAuthorization)
        external
        onlyOwner
    {
        /* solhint-disable not-rely-on-time */
        newMinimumAuthorization = _newMinimumAuthorization;
        minimumAuthorizationChangeInitiated = block.timestamp;
        emit MinimumAuthorizationUpdateStarted(
            _newMinimumAuthorization,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the minimum authorization amount update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeMinimumAuthorizationUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(minimumAuthorizationChangeInitiated)
    {
        emit MinimumAuthorizationUpdated(newMinimumAuthorization);
        (
            ,
            uint64 authorizationDecreaseDelay,
            uint64 authorizationDecreaseChangePeriod
        ) = walletRegistry.authorizationParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateAuthorizationParameters(
            newMinimumAuthorization,
            authorizationDecreaseDelay,
            authorizationDecreaseChangePeriod
        );
        minimumAuthorizationChangeInitiated = 0;
        newMinimumAuthorization = 0;
    }

    /// @notice Begins the authorization decrease delay update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newAuthorizationDecreaseDelay New authorization decrease delay
    function beginAuthorizationDecreaseDelayUpdate(
        uint64 _newAuthorizationDecreaseDelay
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newAuthorizationDecreaseDelay = _newAuthorizationDecreaseDelay;
        authorizationDecreaseDelayChangeInitiated = block.timestamp;
        emit AuthorizationDecreaseDelayUpdateStarted(
            _newAuthorizationDecreaseDelay,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the authorization decrease delay update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeAuthorizationDecreaseDelayUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(authorizationDecreaseDelayChangeInitiated)
    {
        emit AuthorizationDecreaseDelayUpdated(newAuthorizationDecreaseDelay);
        (
            uint96 minimumAuthorization,
            uint64 authorizationDecreaseChangePeriod,

        ) = walletRegistry.authorizationParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateAuthorizationParameters(
            minimumAuthorization,
            newAuthorizationDecreaseDelay,
            authorizationDecreaseChangePeriod
        );
        authorizationDecreaseDelayChangeInitiated = 0;
        newAuthorizationDecreaseDelay = 0;
    }

    /// @notice Begins the authorization decrease change period update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newAuthorizationDecreaseChangePeriod New authorization decrease change period
    function beginAuthorizationDecreaseChangePeriodUpdate(
        uint64 _newAuthorizationDecreaseChangePeriod
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newAuthorizationDecreaseChangePeriod = _newAuthorizationDecreaseChangePeriod;
        authorizationDecreaseChangePeriodChangeInitiated = block.timestamp;
        emit AuthorizationDecreaseChangePeriodUpdateStarted(
            _newAuthorizationDecreaseChangePeriod,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the authorization decrease change period update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeAuthorizationDecreaseChangePeriodUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            authorizationDecreaseChangePeriodChangeInitiated
        )
    {
        emit AuthorizationDecreaseChangePeriodUpdated(
            newAuthorizationDecreaseChangePeriod
        );
        (
            uint96 minimumAuthorization,
            uint64 authorizationDecreaseDelay,

        ) = walletRegistry.authorizationParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateAuthorizationParameters(
            minimumAuthorization,
            authorizationDecreaseDelay,
            newAuthorizationDecreaseChangePeriod
        );
        authorizationDecreaseChangePeriodChangeInitiated = 0;
        newAuthorizationDecreaseChangePeriod = 0;
    }

    /// @notice Begins the malicious DKG result slashing amount update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newMaliciousDkgResultSlashingAmount New malicious DKG result
    ///        slashing amount
    function beginMaliciousDkgResultSlashingAmountUpdate(
        uint96 _newMaliciousDkgResultSlashingAmount
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newMaliciousDkgResultSlashingAmount = _newMaliciousDkgResultSlashingAmount;
        maliciousDkgResultSlashingAmountChangeInitiated = block.timestamp;
        emit MaliciousDkgResultSlashingAmountUpdateStarted(
            _newMaliciousDkgResultSlashingAmount,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the malicious DKG result slashing amount update
    ///         process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeMaliciousDkgResultSlashingAmountUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            maliciousDkgResultSlashingAmountChangeInitiated
        )
    {
        emit MaliciousDkgResultSlashingAmountUpdated(
            newMaliciousDkgResultSlashingAmount
        );
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateSlashingParameters(
            newMaliciousDkgResultSlashingAmount
        );
        maliciousDkgResultSlashingAmountChangeInitiated = 0;
        newMaliciousDkgResultSlashingAmount = 0;
    }

    /// @notice Begins the DKG malicious result notification reward multiplier
    ///         update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newMaliciousDkgResultNotificationRewardMultiplier New DKG
    ///        malicious result notification reward multiplier.
    function beginMaliciousDkgResultNotificationRewardMultiplierUpdate(
        uint256 _newMaliciousDkgResultNotificationRewardMultiplier
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        require(
            _newMaliciousDkgResultNotificationRewardMultiplier <= 100,
            "Maximum value is 100"
        );

        newMaliciousDkgResultNotificationRewardMultiplier = _newMaliciousDkgResultNotificationRewardMultiplier;
        maliciousDkgResultNotificationRewardMultiplierChangeInitiated = block
            .timestamp;
        emit MaliciousDkgResultNotificationRewardMultiplierUpdateStarted(
            _newMaliciousDkgResultNotificationRewardMultiplier,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the DKG malicious result notification reward
    ///         multiplier update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeMaliciousDkgResultNotificationRewardMultiplierUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            maliciousDkgResultNotificationRewardMultiplierChangeInitiated
        )
    {
        emit MaliciousDkgResultNotificationRewardMultiplierUpdated(
            newMaliciousDkgResultNotificationRewardMultiplier
        );
        (, uint256 sortitionPoolRewardsBanDuration) = walletRegistry
            .rewardParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateRewardParameters(
            newMaliciousDkgResultNotificationRewardMultiplier,
            sortitionPoolRewardsBanDuration
        );
        maliciousDkgResultNotificationRewardMultiplierChangeInitiated = 0;
        newMaliciousDkgResultNotificationRewardMultiplier = 0;
    }

    /// @notice Begins the dkg result submission gas update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newDkgResultSubmissionGas New DKG result submission gas.
    function beginDkgResultSubmissionGasUpdate(
        uint256 _newDkgResultSubmissionGas
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newDkgResultSubmissionGas = _newDkgResultSubmissionGas;
        dkgResultSubmissionGasChangeInitiated = block.timestamp;
        emit DkgResultSubmissionGasUpdateStarted(
            _newDkgResultSubmissionGas,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the dkg result submission gas update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgResultSubmissionGasUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(dkgResultSubmissionGasChangeInitiated)
    {
        emit DkgResultSubmissionGasUpdated(newDkgResultSubmissionGas);
        (
            ,
            uint256 dkgResultApprovalGasOffset,
            uint256 notifyOperatorInactivityGasOffset,
            uint256 notifySeedTimeoutGasOffset,
            uint256 notifyDkgTimeoutNegativeGasOffset
        ) = walletRegistry.gasParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateGasParameters(
            newDkgResultSubmissionGas,
            dkgResultApprovalGasOffset,
            notifyOperatorInactivityGasOffset,
            notifySeedTimeoutGasOffset,
            notifyDkgTimeoutNegativeGasOffset
        );
        dkgResultSubmissionGasChangeInitiated = 0;
        newDkgResultSubmissionGas = 0;
    }

    /// @notice Begins the dkg approval gas offset update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newDkgResultApprovalGasOffset New DKG result approval gas.
    function beginDkgResultApprovalGasOffsetUpdate(
        uint256 _newDkgResultApprovalGasOffset
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newDkgResultApprovalGasOffset = _newDkgResultApprovalGasOffset;
        dkgResultApprovalGasOffsetChangeInitiated = block.timestamp;
        emit DkgResultApprovalGasOffsetUpdateStarted(
            _newDkgResultApprovalGasOffset,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the dkg result approval gas offset update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgResultApprovalGasOffsetUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(dkgResultApprovalGasOffsetChangeInitiated)
    {
        emit DkgResultApprovalGasOffsetUpdated(newDkgResultApprovalGasOffset);
        (
            uint256 dkgResultSubmissionGas,
            ,
            uint256 notifyOperatorInactivityGasOffset,
            uint256 notifySeedTimeoutGasOffset,
            uint256 notifyDkgTimeoutNegativeGasOffset
        ) = walletRegistry.gasParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateGasParameters(
            dkgResultSubmissionGas,
            newDkgResultApprovalGasOffset,
            notifyOperatorInactivityGasOffset,
            notifySeedTimeoutGasOffset,
            notifyDkgTimeoutNegativeGasOffset
        );
        dkgResultApprovalGasOffsetChangeInitiated = 0;
        newDkgResultApprovalGasOffset = 0;
    }

    /// @notice Begins the notify operator inactivity gas offset update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newNotifyOperatorInactivityGasOffset New operator inactivity
    ///        notification gas offset
    function beginNotifyOperatorInactivityGasOffsetUpdate(
        uint256 _newNotifyOperatorInactivityGasOffset
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newNotifyOperatorInactivityGasOffset = _newNotifyOperatorInactivityGasOffset;
        notifyOperatorInactivityGasOffsetChangeInitiated = block.timestamp;
        emit NotifyOperatorInactivityGasOffsetUpdateStarted(
            _newNotifyOperatorInactivityGasOffset,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the notify operator inactivity gas offset update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeNotifyOperatorInactivityGasOffsetUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            notifyOperatorInactivityGasOffsetChangeInitiated
        )
    {
        emit NotifyOperatorInactivityGasOffsetUpdated(
            newNotifyOperatorInactivityGasOffset
        );
        (
            uint256 dkgResultSubmissionGas,
            uint256 dkgResultApprovalGasOffset,
            ,
            uint256 notifySeedTimeoutGasOffset,
            uint256 notifyDkgTimeoutNegativeGasOffset
        ) = walletRegistry.gasParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateGasParameters(
            dkgResultSubmissionGas,
            dkgResultApprovalGasOffset,
            newNotifyOperatorInactivityGasOffset,
            notifySeedTimeoutGasOffset,
            notifyDkgTimeoutNegativeGasOffset
        );
        notifyOperatorInactivityGasOffsetChangeInitiated = 0;
        newNotifyOperatorInactivityGasOffset = 0;
    }

    /// @notice Begins the notify seed for DKG delivery timeout gas offset update
    ///         process.
    /// @dev Can be called only by the contract owner.
    /// @param _newNotifySeedTimeoutGasOffset New seed for DKG delivery timeout
    ///        notification gas offset
    function beginNotifySeedTimeoutGasOffsetUpdate(
        uint256 _newNotifySeedTimeoutGasOffset
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newNotifySeedTimeoutGasOffset = _newNotifySeedTimeoutGasOffset;
        notifySeedTimeoutGasOffsetChangeInitiated = block.timestamp;
        emit NotifySeedTimeoutGasOffsetUpdateStarted(
            _newNotifySeedTimeoutGasOffset,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the notify seed for DKG delivery timeout gas offset
    ///         update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeNotifySeedTimeoutGasOffsetUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(notifySeedTimeoutGasOffsetChangeInitiated)
    {
        emit NotifySeedTimeoutGasOffsetUpdated(newNotifySeedTimeoutGasOffset);
        (
            uint256 dkgResultSubmissionGas,
            uint256 dkgResultApprovalGasOffset,
            uint256 notifyOperatorInactivityGasOffset,
            ,
            uint256 notifyDkgTimeoutNegativeGasOffset
        ) = walletRegistry.gasParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateGasParameters(
            dkgResultSubmissionGas,
            dkgResultApprovalGasOffset,
            notifyOperatorInactivityGasOffset,
            newNotifySeedTimeoutGasOffset,
            notifyDkgTimeoutNegativeGasOffset
        );
        notifySeedTimeoutGasOffsetChangeInitiated = 0;
        newNotifySeedTimeoutGasOffset = 0;
    }

    /// @notice Begins the notify DKG timeout negative gas offset update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newNotifyDkgTimeoutNegativeGasOffset New DKG timeout negative gas
    ///        notification gas offset
    function beginNotifyDkgTimeoutNegativeGasOffsetUpdate(
        uint256 _newNotifyDkgTimeoutNegativeGasOffset
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newNotifyDkgTimeoutNegativeGasOffset = _newNotifyDkgTimeoutNegativeGasOffset;
        notifyDkgTimeoutNegativeGasOffsetChangeInitiated = block.timestamp;
        emit NotifyDkgTimeoutNegativeGasOffsetUpdateStarted(
            _newNotifyDkgTimeoutNegativeGasOffset,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the notify DKG timeout negative gas offset update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeNotifyDkgTimeoutNegativeGasOffsetUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            notifyDkgTimeoutNegativeGasOffsetChangeInitiated
        )
    {
        emit NotifyDkgTimeoutNegativeGasOffsetUpdated(
            newNotifyDkgTimeoutNegativeGasOffset
        );
        (
            uint256 dkgResultSubmissionGas,
            uint256 dkgResultApprovalGasOffset,
            uint256 notifyOperatorInactivityGasOffset,
            uint256 notifySeedTimeoutGasOffset,

        ) = walletRegistry.gasParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateGasParameters(
            dkgResultSubmissionGas,
            dkgResultApprovalGasOffset,
            notifyOperatorInactivityGasOffset,
            notifySeedTimeoutGasOffset,
            newNotifyDkgTimeoutNegativeGasOffset
        );
        notifyDkgTimeoutNegativeGasOffsetChangeInitiated = 0;
        newNotifyDkgTimeoutNegativeGasOffset = 0;
    }

    /// @notice Begins the reimbursement pool update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newReimbursementPool New reimbursement pool.
    function beginReimbursementPoolUpdate(address payable _newReimbursementPool)
        external
        onlyOwner
    {
        require(
            address(_newReimbursementPool) != address(0),
            "New reimbursement pool address cannot be zero"
        );
        /* solhint-disable not-rely-on-time */
        newReimbursementPool = _newReimbursementPool;
        reimbursementPoolChangeInitiated = block.timestamp;
        emit ReimbursementPoolUpdateStarted(
            _newReimbursementPool,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the reimbursement pool update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeReimbursementPoolUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(reimbursementPoolChangeInitiated)
    {
        emit ReimbursementPoolUpdated(newReimbursementPool);
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateReimbursementPool(
            ReimbursementPool(newReimbursementPool)
        );
        reimbursementPoolChangeInitiated = 0;
        newReimbursementPool = payable(address(0));
    }

    /// @notice Begins the sortition pool rewards ban duration update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newSortitionPoolRewardsBanDuration New sortition pool rewards
    ///        ban duration.
    function beginSortitionPoolRewardsBanDurationUpdate(
        uint256 _newSortitionPoolRewardsBanDuration
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newSortitionPoolRewardsBanDuration = _newSortitionPoolRewardsBanDuration;
        sortitionPoolRewardsBanDurationChangeInitiated = block.timestamp;
        emit SortitionPoolRewardsBanDurationUpdateStarted(
            _newSortitionPoolRewardsBanDuration,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the sortition pool rewards ban duration update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeSortitionPoolRewardsBanDurationUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(sortitionPoolRewardsBanDurationChangeInitiated)
    {
        emit SortitionPoolRewardsBanDurationUpdated(
            newSortitionPoolRewardsBanDuration
        );
        (
            uint256 maliciousDkgResultNotificationRewardMultiplier,

        ) = walletRegistry.rewardParameters();
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateRewardParameters(
            maliciousDkgResultNotificationRewardMultiplier,
            newSortitionPoolRewardsBanDuration
        );
        sortitionPoolRewardsBanDurationChangeInitiated = 0;
        newSortitionPoolRewardsBanDuration = 0;
    }

    /// @notice Begins the DKG seed timeout update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newDkgSeedTimeout New DKG seed timeout in blocks
    function beginDkgSeedTimeoutUpdate(uint256 _newDkgSeedTimeout)
        external
        onlyOwner
    {
        /* solhint-disable not-rely-on-time */
        require(_newDkgSeedTimeout > 0, "DKG seed timeout must be > 0");
        newDkgSeedTimeout = _newDkgSeedTimeout;
        dkgSeedTimeoutChangeInitiated = block.timestamp;
        emit DkgSeedTimeoutUpdateStarted(_newDkgSeedTimeout, block.timestamp);
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the DKG seed timeout update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgSeedTimeoutUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(dkgSeedTimeoutChangeInitiated)
    {
        emit DkgSeedTimeoutUpdated(newDkgSeedTimeout);
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateDkgParameters(
            newDkgSeedTimeout,
            walletRegistry.dkgParameters().resultChallengePeriodLength,
            walletRegistry.dkgParameters().resultChallengeExtraGas,
            walletRegistry.dkgParameters().resultSubmissionTimeout,
            walletRegistry.dkgParameters().submitterPrecedencePeriodLength
        );
        dkgSeedTimeoutChangeInitiated = 0;
        newDkgSeedTimeout = 0;
    }

    /// @notice Begins the DKG result challenge period length update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newDkgResultChallengePeriodLength New DKG result challenge
    ///        period length in blocks
    function beginDkgResultChallengePeriodLengthUpdate(
        uint256 _newDkgResultChallengePeriodLength
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        require(
            _newDkgResultChallengePeriodLength >= 10,
            "DKG result challenge period length must be >= 10"
        );
        newDkgResultChallengePeriodLength = _newDkgResultChallengePeriodLength;
        dkgResultChallengePeriodLengthChangeInitiated = block.timestamp;
        emit DkgResultChallengePeriodLengthUpdateStarted(
            _newDkgResultChallengePeriodLength,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the DKG result challenge period length update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgResultChallengePeriodLengthUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(dkgResultChallengePeriodLengthChangeInitiated)
    {
        emit DkgResultChallengePeriodLengthUpdated(
            newDkgResultChallengePeriodLength
        );
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateDkgParameters(
            walletRegistry.dkgParameters().seedTimeout,
            newDkgResultChallengePeriodLength,
            walletRegistry.dkgParameters().resultChallengeExtraGas,
            walletRegistry.dkgParameters().resultSubmissionTimeout,
            walletRegistry.dkgParameters().submitterPrecedencePeriodLength
        );
        dkgResultChallengePeriodLengthChangeInitiated = 0;
        newDkgResultChallengePeriodLength = 0;
    }

    /// @notice Begins the DKG result challenge extra gas update process.
    /// @dev Can be called only by the contract owner.
    /// @param _newDkgResultChallengeExtraGas New DKG result challenge extra gas
    function beginDkgResultChallengeExtraGasUpdate(
        uint256 _newDkgResultChallengeExtraGas
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        newDkgResultChallengeExtraGas = _newDkgResultChallengeExtraGas;
        dkgResultChallengeExtraGasChangeInitiated = block.timestamp;
        emit DkgResultChallengeExtraGasUpdateStarted(
            _newDkgResultChallengeExtraGas,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the DKG result challenge extra gas update process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgResultChallengeExtraGasUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(dkgResultChallengeExtraGasChangeInitiated)
    {
        emit DkgResultChallengeExtraGasUpdated(newDkgResultChallengeExtraGas);
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateDkgParameters(
            walletRegistry.dkgParameters().seedTimeout,
            walletRegistry.dkgParameters().resultChallengePeriodLength,
            newDkgResultChallengeExtraGas,
            walletRegistry.dkgParameters().resultSubmissionTimeout,
            walletRegistry.dkgParameters().submitterPrecedencePeriodLength
        );
        dkgResultChallengeExtraGasChangeInitiated = 0;
        newDkgResultChallengeExtraGas = 0;
    }

    /// @notice Begins the DKG result submission timeout update
    ///         process.
    /// @dev Can be called only by the contract owner.
    /// @param _newDkgResultSubmissionTimeout New DKG result submission timeout
    ///        in blocks
    function beginDkgResultSubmissionTimeoutUpdate(
        uint256 _newDkgResultSubmissionTimeout
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        require(
            _newDkgResultSubmissionTimeout > 0,
            "DKG result submission timeout must be > 0"
        );
        newDkgResultSubmissionTimeout = _newDkgResultSubmissionTimeout;
        dkgResultSubmissionTimeoutChangeInitiated = block.timestamp;
        emit DkgResultSubmissionTimeoutUpdateStarted(
            _newDkgResultSubmissionTimeout,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the DKG result submission timeout update
    ///         process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgResultSubmissionTimeoutUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(dkgResultSubmissionTimeoutChangeInitiated)
    {
        emit DkgResultSubmissionTimeoutUpdated(newDkgResultSubmissionTimeout);
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateDkgParameters(
            walletRegistry.dkgParameters().seedTimeout,
            walletRegistry.dkgParameters().resultChallengePeriodLength,
            walletRegistry.dkgParameters().resultChallengeExtraGas,
            newDkgResultSubmissionTimeout,
            walletRegistry.dkgParameters().submitterPrecedencePeriodLength
        );
        dkgResultSubmissionTimeoutChangeInitiated = 0;
        newDkgResultSubmissionTimeout = 0;
    }

    /// @notice Begins the DKG submitter precedence period length update
    ///         process.
    /// @dev Can be called only by the contract owner.
    /// @param _newSubmitterPrecedencePeriodLength New DKG submitter precedence
    ///        period length in blocks
    function beginDkgSubmitterPrecedencePeriodLengthUpdate(
        uint256 _newSubmitterPrecedencePeriodLength
    ) external onlyOwner {
        /* solhint-disable not-rely-on-time */
        require(
            _newSubmitterPrecedencePeriodLength > 0,
            "DKG submitter precedence period length must be > 0"
        );
        newSubmitterPrecedencePeriodLength = _newSubmitterPrecedencePeriodLength;
        dkgSubmitterPrecedencePeriodLengthChangeInitiated = block.timestamp;
        emit DkgSubmitterPrecedencePeriodLengthUpdateStarted(
            _newSubmitterPrecedencePeriodLength,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the DKG submitter precedence period length update
    ///         process.
    /// @dev Can be called only by the contract owner, after the governance
    ///      delay elapses.
    function finalizeDkgSubmitterPrecedencePeriodLengthUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(
            dkgSubmitterPrecedencePeriodLengthChangeInitiated
        )
    {
        emit DkgSubmitterPrecedencePeriodLengthUpdated(
            newSubmitterPrecedencePeriodLength
        );
        // slither-disable-next-line reentrancy-no-eth
        walletRegistry.updateDkgParameters(
            walletRegistry.dkgParameters().seedTimeout,
            walletRegistry.dkgParameters().resultChallengePeriodLength,
            walletRegistry.dkgParameters().resultChallengeExtraGas,
            walletRegistry.dkgParameters().resultSubmissionTimeout,
            newSubmitterPrecedencePeriodLength
        );
        dkgSubmitterPrecedencePeriodLengthChangeInitiated = 0;
        newSubmitterPrecedencePeriodLength = 0;
    }

    /// @notice Withdraws rewards belonging to operators marked as ineligible
    ///         for sortition pool rewards.
    /// @dev Can be called only by the contract owner.
    /// @param recipient Recipient of withdrawn rewards.
    function withdrawIneligibleRewards(address recipient) external onlyOwner {
        walletRegistry.withdrawIneligibleRewards(recipient);
    }

    /// @notice Get the time remaining until the governance delay can be updated.
    /// @return Remaining time in seconds.
    function getRemainingGovernanceDelayUpdateTime()
        external
        view
        returns (uint256)
    {
        return getRemainingChangeTime(governanceDelayChangeInitiated);
    }

    /// @notice Get the time remaining until the wallet registry governance can
    ///         be transferred.
    /// @return Remaining time in seconds.
    function getRemainingWalletRegistryGovernanceTransferDelayTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(walletRegistryGovernanceTransferInitiated);
    }

    /// @notice Get the time remaining until the minimum authorization amount
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingMimimumAuthorizationUpdateTime()
        external
        view
        returns (uint256)
    {
        return getRemainingChangeTime(minimumAuthorizationChangeInitiated);
    }

    /// @notice Get the time remaining until the authorization decrease delay
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingAuthorizationDecreaseDelayUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(authorizationDecreaseDelayChangeInitiated);
    }

    /// @notice Get the time remaining until the authorization decrease change
    ///         period can be updated.
    /// @return Remaining time in seconds.
    function getRemainingAuthorizationDecreaseChangePeriodUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                authorizationDecreaseChangePeriodChangeInitiated
            );
    }

    /// @notice Get the time remaining until the malicious DKG result
    ///         slashing amount can be updated.
    /// @return Remaining time in seconds.
    function getRemainingMaliciousDkgResultSlashingAmountUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                maliciousDkgResultSlashingAmountChangeInitiated
            );
    }

    /// @notice Get the time remaining until the DKG malicious result
    ///         notification reward multiplier duration can be updated.
    /// @return Remaining time in seconds.
    function getRemainingMaliciousDkgResultNotificationRewardMultiplierUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                maliciousDkgResultNotificationRewardMultiplierChangeInitiated
            );
    }

    /// @notice Get the time remaining until the sortition pool rewards ban
    ///         duration can be updated.
    /// @return Remaining time in seconds.
    function getRemainingSortitionPoolRewardsBanDurationUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                sortitionPoolRewardsBanDurationChangeInitiated
            );
    }

    /// @notice Get the time remaining until the DKG seed timeout can be updated.
    /// @return Remaining time in seconds.
    function getRemainingDkgSeedTimeoutUpdateTime()
        external
        view
        returns (uint256)
    {
        return getRemainingChangeTime(dkgSeedTimeoutChangeInitiated);
    }

    /// @notice Get the time remaining until the DKG result challenge period
    ///         length can be updated.
    /// @return Remaining time in seconds.
    function getRemainingDkgResultChallengePeriodLengthUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                dkgResultChallengePeriodLengthChangeInitiated
            );
    }

    function getRemainingDkgResultChallengeExtraGasUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(dkgResultChallengeExtraGasChangeInitiated);
    }

    /// @notice Get the time remaining until the DKG result submission timeout
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingDkgResultSubmissionTimeoutUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(dkgResultSubmissionTimeoutChangeInitiated);
    }

    /// @notice Get the time remaining until the wallet owner can be updated.
    /// @return Remaining time in seconds.
    function getRemainingWalletOwnerUpdateTime()
        external
        view
        returns (uint256)
    {
        return getRemainingChangeTime(walletOwnerChangeInitiated);
    }

    /// @notice Get the time remaining until the wallet owner can be updated.
    /// @return Remaining time in seconds.
    function getRemainingDkgSubmitterPrecedencePeriodLengthUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                dkgSubmitterPrecedencePeriodLengthChangeInitiated
            );
    }

    /// @notice Get the time remaining until the dkg result submission gas can
    ///         be updated.
    /// @return Remaining time in seconds.
    function getRemainingDkgResultSubmissionGasUpdateTime()
        external
        view
        returns (uint256)
    {
        return getRemainingChangeTime(dkgResultSubmissionGasChangeInitiated);
    }

    /// @notice Get the time remaining until the dkg result approval gas offset
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingDkgResultApprovalGasOffsetUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(dkgResultApprovalGasOffsetChangeInitiated);
    }

    /// @notice Get the time remaining until the operator inactivity gas offset
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingNotifyOperatorInactivityGasOffsetUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                notifyOperatorInactivityGasOffsetChangeInitiated
            );
    }

    /// @notice Get the time remaining until the seed for DKG delivery timeout
    /// gas offset can be updated.
    /// @return Remaining time in seconds.
    function getRemainingNotifySeedTimeoutGasOffsetUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(notifySeedTimeoutGasOffsetChangeInitiated);
    }

    /// @notice Get the time remaining until the DKG timeout negative gas offset
    ///         can be updated.
    /// @return Remaining time in seconds.
    function getRemainingNotifyDkgTimeoutNegativeGasOffsetUpdateTime()
        external
        view
        returns (uint256)
    {
        return
            getRemainingChangeTime(
                notifyDkgTimeoutNegativeGasOffsetChangeInitiated
            );
    }

    /// @notice Get the time remaining until reimbursement pool can be updated.
    /// @return Remaining time in seconds.
    function getRemainingReimbursementPoolUpdateTime()
        external
        view
        returns (uint256)
    {
        return getRemainingChangeTime(reimbursementPoolChangeInitiated);
    }

    /// @notice Gets the time remaining until the governable parameter update
    ///         can be committed.
    /// @param changeTimestamp Timestamp indicating the beginning of the change.
    /// @return Remaining time in seconds.
    function getRemainingChangeTime(uint256 changeTimestamp)
        internal
        view
        returns (uint256)
    {
        require(changeTimestamp > 0, "Change not initiated");
        /* solhint-disable-next-line not-rely-on-time */
        uint256 elapsed = block.timestamp - changeTimestamp;
        if (elapsed >= governanceDelay) {
            return 0;
        }

        return governanceDelay - elapsed;
    }
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

import "./api/IWalletRegistry.sol";
import "./api/IWalletOwner.sol";
import "./libraries/Wallets.sol";
import {EcdsaAuthorization as Authorization} from "./libraries/EcdsaAuthorization.sol";
import {EcdsaDkg as DKG} from "./libraries/EcdsaDkg.sol";
import {EcdsaInactivity as Inactivity} from "./libraries/EcdsaInactivity.sol";
import {EcdsaDkgValidator as DKGValidator} from "./EcdsaDkgValidator.sol";

import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "@keep-network/random-beacon/contracts/api/IRandomBeacon.sol";
import "@keep-network/random-beacon/contracts/api/IRandomBeaconConsumer.sol";
import "@keep-network/random-beacon/contracts/Reimbursable.sol";
import "@keep-network/random-beacon/contracts/ReimbursementPool.sol";
import "@keep-network/random-beacon/contracts/Governable.sol";

import "@threshold-network/solidity-contracts/contracts/staking/IApplication.sol";
import "@threshold-network/solidity-contracts/contracts/staking/IStaking.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract WalletRegistry is
    IWalletRegistry,
    IRandomBeaconConsumer,
    IApplication,
    Governable,
    Reimbursable,
    Initializable
{
    using Authorization for Authorization.Data;
    using DKG for DKG.Data;
    using Wallets for Wallets.Data;

    // Libraries data storages
    Authorization.Data internal authorization;
    DKG.Data internal dkg;
    Wallets.Data internal wallets;

    /// @notice Slashing amount for submitting a malicious DKG result. Every
    ///         DKG result submitted can be challenged for the time of
    ///         `dkg.resultChallengePeriodLength`. If the DKG result submitted
    ///         is challenged and proven to be malicious, the operator who
    ///         submitted the malicious result is slashed for
    ///         `_maliciousDkgResultSlashingAmount`.
    uint96 internal _maliciousDkgResultSlashingAmount;

    /// @notice Percentage of the staking contract malicious behavior
    ///         notification reward which will be transferred to the notifier
    ///         reporting about a malicious DKG result. Notifiers are rewarded
    ///         from a notifiers treasury pool. For example, if
    ///         notification reward is 1000 and the value of the multiplier is
    ///         5, the notifier will receive: 5% of 1000 = 50 per each
    ///         operator affected.
    uint256 internal _maliciousDkgResultNotificationRewardMultiplier;

    /// @notice Duration of the sortition pool rewards ban imposed on operators
    ///         who missed their turn for DKG result submission or who failed
    ///         a heartbeat.
    uint256 internal _sortitionPoolRewardsBanDuration;

    /// @notice Calculated max gas cost for submitting a DKG result. This will
    ///         be refunded as part of the DKG approval process. It is in the
    ///         submitter's interest to not skip his priority turn on the approval,
    ///         otherwise the refund of the DKG submission will be refunded to
    ///         another group member that will call the DKG approve function.
    uint256 internal _dkgResultSubmissionGas;

    /// @notice Gas that is meant to balance the DKG result approval's overall
    ///         cost. It can be updated by the governance based on the current
    ///         market conditions.
    uint256 internal _dkgResultApprovalGasOffset;

    /// @notice Gas that is meant to balance the notification of an operator
    ///         inactivity. It can be updated by the governance based on the
    ///         current market conditions.
    uint256 internal _notifyOperatorInactivityGasOffset;

    /// @notice Gas that is meant to balance the notification of a seed for DKG
    ///         delivery timeout. It can be updated by the governance based on the
    ///         current market conditions.
    uint256 internal _notifySeedTimeoutGasOffset;

    /// @notice Gas that is meant to balance the notification of a DKG protocol
    ///         execution timeout. It can be updated by the governance based on the
    ///         current market conditions.
    /// @dev The value is subtracted for the refundable gas calculation, as the
    ///      DKG timeout notification transaction recovers some gas when cleaning
    ///      up the storage.
    uint256 internal _notifyDkgTimeoutNegativeGasOffset;

    /// @notice Stores current operator inactivity claim nonce for the given
    ///         wallet signing group. Each claim is made with a unique nonce
    ///         which protects against claim replay.
    mapping(bytes32 => uint256) public inactivityClaimNonce; // walletID -> nonce

    // Address that is set as owner of all wallets. Only this address can request
    // new wallets creation and manage their state.
    IWalletOwner public walletOwner;

    // External dependencies

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    SortitionPool public immutable sortitionPool;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    IStaking public immutable staking;
    IRandomBeacon public randomBeacon;

    // Events
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

    event DkgStateLocked();

    event DkgSeedTimedOut();

    event WalletCreated(
        bytes32 indexed walletID,
        bytes32 indexed dkgResultHash
    );

    event WalletClosed(bytes32 indexed walletID);

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

    event AuthorizationParametersUpdated(
        uint96 minimumAuthorization,
        uint64 authorizationDecreaseDelay,
        uint64 authorizationDecreaseChangePeriod
    );

    event RewardParametersUpdated(
        uint256 maliciousDkgResultNotificationRewardMultiplier,
        uint256 sortitionPoolRewardsBanDuration
    );

    event SlashingParametersUpdated(uint256 maliciousDkgResultSlashingAmount);

    event DkgParametersUpdated(
        uint256 seedTimeout,
        uint256 resultChallengePeriodLength,
        uint256 resultChallengeExtraGas,
        uint256 resultSubmissionTimeout,
        uint256 resultSubmitterPrecedencePeriodLength
    );

    event GasParametersUpdated(
        uint256 dkgResultSubmissionGas,
        uint256 dkgResultApprovalGasOffset,
        uint256 notifyOperatorInactivityGasOffset,
        uint256 notifySeedTimeoutGasOffset,
        uint256 notifyDkgTimeoutNegativeGasOffset
    );

    event RandomBeaconUpgraded(address randomBeacon);

    event WalletOwnerUpdated(address walletOwner);

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

    event InactivityClaimed(
        bytes32 indexed walletID,
        uint256 nonce,
        address notifier
    );

    modifier onlyStakingContract() {
        require(
            msg.sender == address(staking),
            "Caller is not the staking contract"
        );
        _;
    }

    /// @notice Reverts if called not by the Wallet Owner.
    modifier onlyWalletOwner() {
        require(
            msg.sender == address(walletOwner),
            "Caller is not the Wallet Owner"
        );
        _;
    }

    modifier onlyReimbursableAdmin() override {
        require(governance == msg.sender, "Caller is not the governance");
        _;
    }

    /// @dev Used to initialize immutable variables only, use `initialize` function
    ///      for upgradable contract initialization on deployment.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(SortitionPool _sortitionPool, IStaking _staking) {
        sortitionPool = _sortitionPool;
        staking = _staking;

        _disableInitializers();
    }

    /// @dev Initializes upgradable contract on deployment.
    function initialize(
        DKGValidator _ecdsaDkgValidator,
        IRandomBeacon _randomBeacon,
        ReimbursementPool _reimbursementPool
    ) external initializer {
        randomBeacon = _randomBeacon;
        reimbursementPool = _reimbursementPool;

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
        authorization.setMinimumAuthorization(40_000e18);
        authorization.setAuthorizationDecreaseDelay(3_888_000);
        authorization.setAuthorizationDecreaseChangePeriod(3_888_000);

        // Malicious DKG result slashing amount is set initially to 1% of the
        // minimum authorization (400 T). This values needs to be increased
        // significantly once the system is fully launched.
        //
        // Notifier of a malicious DKG result receives 100% of the notifier
        // reward from the staking contract.
        //
        // Inactive operators are set as ineligible for rewards for 2 weeks.
        _maliciousDkgResultSlashingAmount = 400e18;
        _maliciousDkgResultNotificationRewardMultiplier = 100;
        _sortitionPoolRewardsBanDuration = 2 weeks;

        // DKG seed timeout is set to 48h assuming 15s block time. The same
        // value is used by the Random Beacon as a relay entry hard timeout.
        //
        // DKG result challenge period length is set to 48h as well, assuming
        // 15s block time.
        //
        // DKG result submission timeout, gives each member 20 blocks to submit
        // the result. Assuming 15s block time, it is ~8h to submit the result
        // in the pessimistic case.
        //
        // The original DKG result submitter has 20 blocks to approve it before
        // anyone else can do that.
        //
        // With these parameters, the happy path takes no more than 104 hours.
        // In practice, it should take about 48 hours (just the challenge time).
        dkg.init(sortitionPool, _ecdsaDkgValidator);
        dkg.setSeedTimeout(11_520);
        dkg.setResultChallengePeriodLength(11_520);
        dkg.setResultChallengeExtraGas(50_000);
        dkg.setResultSubmissionTimeout(100 * 20);
        dkg.setSubmitterPrecedencePeriodLength(20);

        // Gas parameters were adjusted based on Ethereum state in April 2022.
        // If the cost of EVM opcodes change over time, these parameters will
        // have to be updated.
        _dkgResultSubmissionGas = 290_000;
        _dkgResultApprovalGasOffset = 72_000;
        _notifyOperatorInactivityGasOffset = 93_000;
        _notifySeedTimeoutGasOffset = 7_250;
        _notifyDkgTimeoutNegativeGasOffset = 2_300;
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
    ///      wallet registry governance contract.
    /// @param recipient Recipient of withdrawn rewards.
    function withdrawIneligibleRewards(address recipient)
        external
        onlyGovernance
    {
        sortitionPool.withdrawIneligible(recipient);
    }

    /// @notice Used by staking provider to set operator address that will
    ///         operate ECDSA node. The given staking provider can set operator
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
    ///         by ECDSA. Function reverts if there is no minimum stake
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

    /// @notice Used by T staking contract to inform the application that the
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

    /// @notice Used by T staking contract to inform the application that the
    ///         authorization decrease for the given staking provider has been
    ///         requested.
    ///
    ///         Reverts if the amount after deauthorization would be non-zero
    ///         and lower than the minimum authorization.
    ///
    ///         If the operator is not known (`registerOperator` was not called)
    ///         it lets to `approveAuthorizationDecrease` immediatelly. If the
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
    ///         overwritten.
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

    /// @notice Used by T staking contract to inform the application the
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

    /// @notice Updates address of the Random Beacon.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param _randomBeacon Random Beacon address.
    function upgradeRandomBeacon(IRandomBeacon _randomBeacon)
        external
        onlyGovernance
    {
        randomBeacon = _randomBeacon;
        emit RandomBeaconUpgraded(address(_randomBeacon));
    }

    /// @notice Updates the wallet owner.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters. The wallet owner has to implement `IWalletOwner`
    ///      interface.
    /// @param _walletOwner New wallet owner address.
    function updateWalletOwner(IWalletOwner _walletOwner)
        external
        onlyGovernance
    {
        walletOwner = _walletOwner;
        emit WalletOwnerUpdated(address(_walletOwner));
    }

    /// @notice Updates the values of authorization parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param _minimumAuthorization New minimum authorization amount.
    /// @param _authorizationDecreaseDelay New authorization decrease delay in
    ///        seconds.
    /// @param _authorizationDecreaseChangePeriod New authorization decrease
    ///        change period in seconds.
    function updateAuthorizationParameters(
        uint96 _minimumAuthorization,
        uint64 _authorizationDecreaseDelay,
        uint64 _authorizationDecreaseChangePeriod
    ) external onlyGovernance {
        authorization.setMinimumAuthorization(_minimumAuthorization);
        authorization.setAuthorizationDecreaseDelay(
            _authorizationDecreaseDelay
        );
        authorization.setAuthorizationDecreaseChangePeriod(
            _authorizationDecreaseChangePeriod
        );

        emit AuthorizationParametersUpdated(
            _minimumAuthorization,
            _authorizationDecreaseDelay,
            _authorizationDecreaseChangePeriod
        );
    }

    /// @notice Updates the values of DKG parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param _seedTimeout New seed timeout.
    /// @param _resultChallengePeriodLength New DKG result challenge period
    ///        length.
    /// @param _resultChallengeExtraGas New extra gas value required to be left
    ///        at the end of the DKG result challenge transaction.
    /// @param _resultSubmissionTimeout New DKG result submission timeout.
    /// @param _submitterPrecedencePeriodLength New submitter precedence period
    ///        length.
    function updateDkgParameters(
        uint256 _seedTimeout,
        uint256 _resultChallengePeriodLength,
        uint256 _resultChallengeExtraGas,
        uint256 _resultSubmissionTimeout,
        uint256 _submitterPrecedencePeriodLength
    ) external onlyGovernance {
        dkg.setSeedTimeout(_seedTimeout);
        dkg.setResultChallengePeriodLength(_resultChallengePeriodLength);
        dkg.setResultChallengeExtraGas(_resultChallengeExtraGas);
        dkg.setResultSubmissionTimeout(_resultSubmissionTimeout);
        dkg.setSubmitterPrecedencePeriodLength(
            _submitterPrecedencePeriodLength
        );

        // slither-disable-next-line reentrancy-events
        emit DkgParametersUpdated(
            _seedTimeout,
            _resultChallengePeriodLength,
            _resultChallengeExtraGas,
            _resultSubmissionTimeout,
            _submitterPrecedencePeriodLength
        );
    }

    /// @notice Updates the values of reward parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param maliciousDkgResultNotificationRewardMultiplier New value of the
    ///        DKG malicious result notification reward multiplier.
    /// @param sortitionPoolRewardsBanDuration New sortition pool rewards
    ///        ban duration in seconds.
    function updateRewardParameters(
        uint256 maliciousDkgResultNotificationRewardMultiplier,
        uint256 sortitionPoolRewardsBanDuration
    ) external onlyGovernance {
        _maliciousDkgResultNotificationRewardMultiplier = maliciousDkgResultNotificationRewardMultiplier;
        _sortitionPoolRewardsBanDuration = sortitionPoolRewardsBanDuration;
        emit RewardParametersUpdated(
            maliciousDkgResultNotificationRewardMultiplier,
            sortitionPoolRewardsBanDuration
        );
    }

    /// @notice Updates the values of slashing parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param maliciousDkgResultSlashingAmount New malicious DKG result
    ///        slashing amount.
    function updateSlashingParameters(uint96 maliciousDkgResultSlashingAmount)
        external
        onlyGovernance
    {
        _maliciousDkgResultSlashingAmount = maliciousDkgResultSlashingAmount;
        emit SlashingParametersUpdated(maliciousDkgResultSlashingAmount);
    }

    /// @notice Updates the values of gas-related parameters.
    /// @dev Can be called only by the contract guvnor, which should be the
    ///      wallet registry governance contract. The caller is responsible for
    ///      validating parameters.
    /// @param dkgResultSubmissionGas New DKG result submission gas.
    /// @param dkgResultApprovalGasOffset New DKG result approval gas offset.
    /// @param notifyOperatorInactivityGasOffset New operator inactivity
    ///        notification gas offset.
    /// @param notifySeedTimeoutGasOffset New seed for DKG delivery timeout
    ///        notification gas offset.
    /// @param notifyDkgTimeoutNegativeGasOffset New DKG timeout notification gas
    ///        offset.
    function updateGasParameters(
        uint256 dkgResultSubmissionGas,
        uint256 dkgResultApprovalGasOffset,
        uint256 notifyOperatorInactivityGasOffset,
        uint256 notifySeedTimeoutGasOffset,
        uint256 notifyDkgTimeoutNegativeGasOffset
    ) external onlyGovernance {
        _dkgResultSubmissionGas = dkgResultSubmissionGas;
        _dkgResultApprovalGasOffset = dkgResultApprovalGasOffset;
        _notifyOperatorInactivityGasOffset = notifyOperatorInactivityGasOffset;
        _notifySeedTimeoutGasOffset = notifySeedTimeoutGasOffset;
        _notifyDkgTimeoutNegativeGasOffset = notifyDkgTimeoutNegativeGasOffset;

        emit GasParametersUpdated(
            dkgResultSubmissionGas,
            dkgResultApprovalGasOffset,
            notifyOperatorInactivityGasOffset,
            _notifySeedTimeoutGasOffset,
            _notifyDkgTimeoutNegativeGasOffset
        );
    }

    /// @notice Requests a new wallet creation.
    /// @dev Can be called only by the owner of wallets.
    ///      It locks the DKG and request a new relay entry. It expects
    ///      that the DKG process will be started once a new relay entry
    ///      gets generated.
    function requestNewWallet() external onlyWalletOwner {
        dkg.lockState();

        randomBeacon.requestRelayEntry(this);
    }

    /// @notice Closes an existing wallet. Reverts if wallet with the given ID
    ///         does not exist or if it has already been closed.
    /// @param walletID ID of the wallet.
    /// @dev Only a Wallet Owner can call this function.
    function closeWallet(bytes32 walletID) external onlyWalletOwner {
        wallets.deleteWallet(walletID);
        emit WalletClosed(walletID);
    }

    /// @notice A callback that is executed once a new relay entry gets
    ///         generated. It starts the DKG process.
    /// @dev Can be called only by the random beacon contract.
    /// @param relayEntry Relay entry.
    function __beaconCallback(uint256 relayEntry, uint256) external {
        require(
            msg.sender == address(randomBeacon),
            "Caller is not the Random Beacon"
        );

        dkg.start(relayEntry);
    }

    /// @notice Submits result of DKG protocol.
    ///         The DKG result consists of result submitting member index,
    ///         calculated group public key, bytes array of misbehaved members,
    ///         concatenation of signatures from group members, indices of members
    ///         corresponding to each signature and the list of group members.
    ///         The result is registered optimistically and waits for an approval.
    ///         The result can be challenged when it is believed to be incorrect.
    ///         The challenge verifies the registered result i.a. it checks if members
    ///         list corresponds to the expected set of members determined
    ///         by the sortition pool.
    /// @dev The message to be signed by each member is keccak256 hash of the
    ///      calculated group public key, misbehaved members indices and DKG
    ///      start block. The calculated hash should be prefixed with prefixed with
    ///      `\x19Ethereum signed message:\n` before signing, so the message to
    ///      sign is:
    ///      `\x19Ethereum signed message:\n${keccak256(groupPubKey,misbehavedIndices,startBlock)}`
    /// @param dkgResult DKG result.
    function submitDkgResult(DKG.Result calldata dkgResult) external {
        wallets.validatePublicKey(dkgResult.groupPubKey);
        dkg.submitResult(dkgResult);
    }

    /// @notice Approves DKG result. Can be called when the challenge period for
    ///         the submitted result is finished. Considers the submitted result
    ///         as valid, bans misbehaved group members from the sortition pool
    ///         rewards, and completes the group creation by activating the
    ///         candidate group. For the first `resultSubmissionTimeout` blocks
    ///         after the end of the challenge period can be called only by the
    ///         DKG result submitter. After that time, can be called by anyone.
    ///         A new wallet based on the DKG result details.
    /// @param dkgResult Result to approve. Must match the submitted result
    ///        stored during `submitDkgResult`.
    function approveDkgResult(DKG.Result calldata dkgResult) external {
        uint256 gasStart = gasleft();
        uint32[] memory misbehavedMembers = dkg.approveResult(dkgResult);

        (bytes32 walletID, bytes32 publicKeyX, bytes32 publicKeyY) = wallets
            .addWallet(dkgResult.membersHash, dkgResult.groupPubKey);

        emit WalletCreated(walletID, keccak256(abi.encode(dkgResult)));

        if (misbehavedMembers.length > 0) {
            sortitionPool.setRewardIneligibility(
                misbehavedMembers,
                // solhint-disable-next-line not-rely-on-time
                block.timestamp + _sortitionPoolRewardsBanDuration
            );
        }

        walletOwner.__ecdsaWalletCreatedCallback(
            walletID,
            publicKeyX,
            publicKeyY
        );

        dkg.complete();

        // Refund msg.sender's ETH for DKG result submission and result approval
        reimbursementPool.refund(
            _dkgResultSubmissionGas +
                (gasStart - gasleft()) +
                _dkgResultApprovalGasOffset,
            msg.sender
        );
    }

    /// @notice Notifies about seed for DKG delivery timeout. It is expected
    ///         that a seed is delivered by the Random Beacon as a relay entry in a
    ///         callback function.
    function notifySeedTimeout() external {
        uint256 gasStart = gasleft();

        dkg.notifySeedTimeout();

        reimbursementPool.refund(
            (gasStart - gasleft()) + _notifySeedTimeoutGasOffset,
            msg.sender
        );
    }

    /// @notice Notifies about DKG timeout.
    function notifyDkgTimeout() external {
        uint256 gasStart = gasleft();

        dkg.notifyDkgTimeout();

        // Note that the offset is subtracted as it is expected that the cleanup
        // performed on DKG timeout notification removes data from the storage
        // which is recovering gas for the transaction.
        reimbursementPool.refund(
            (gasStart - gasleft()) - _notifyDkgTimeoutNegativeGasOffset,
            msg.sender
        );
    }

    /// @notice Challenges DKG result. If the submitted result is proved to be
    ///         invalid it reverts the DKG back to the result submission phase.
    /// @param dkgResult Result to challenge. Must match the submitted result
    ///        stored during `submitDkgResult`.
    /// @dev Due to EIP-150 1/64 of the gas is not forwarded to the call, and
    ///      will be kept to execute the remaining operations in the function
    ///      after the call inside the try-catch. To eliminate a class of
    ///      attacks related to the gas limit manipulation, this function
    ///      requires an extra amount of gas to be left at the end of the
    ///      execution.
    function challengeDkgResult(DKG.Result calldata dkgResult) external {
        (
            bytes32 maliciousDkgResultHash,
            uint32 maliciousDkgResultSubmitterId
        ) = dkg.challengeResult(dkgResult);

        address maliciousDkgResultSubmitterAddress = sortitionPool
            .getIDOperator(maliciousDkgResultSubmitterId);

        address[] memory operatorWrapper = new address[](1);
        operatorWrapper[0] = operatorToStakingProvider(
            maliciousDkgResultSubmitterAddress
        );

        try
            staking.seize(
                _maliciousDkgResultSlashingAmount,
                _maliciousDkgResultNotificationRewardMultiplier,
                msg.sender,
                operatorWrapper
            )
        {
            // slither-disable-next-line reentrancy-events
            emit DkgMaliciousResultSlashed(
                maliciousDkgResultHash,
                _maliciousDkgResultSlashingAmount,
                maliciousDkgResultSubmitterAddress
            );
        } catch {
            // Should never happen but we want to ensure a non-critical path
            // failure from an external contract does not stop the challenge
            // to complete.
            emit DkgMaliciousResultSlashingFailed(
                maliciousDkgResultHash,
                _maliciousDkgResultSlashingAmount,
                maliciousDkgResultSubmitterAddress
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

    /// @notice Notifies about operators who are inactive. Using this function,
    ///         a majority of the wallet signing group can decide about
    ///         punishing specific group members who constantly fail doing their
    ///         job. If the provided claim is proved to be valid and signed by
    ///         sufficient number of group members, operators of members deemed
    ///         as inactive are banned from sortition pool rewards for the
    ///         duration specified by `sortitionPoolRewardsBanDuration` parameter.
    ///         The function allows to signal about single operators being
    ///         inactive as well as to signal wallet-wide heartbeat failures
    ///         that are propagated to the wallet owner who should begin the
    ///         procedure of moving responsibilities to another wallet given
    ///         that the wallet who failed the heartbeat may soon be not able to
    ///         function and provide new signatures.
    ///         The sender of the claim must be one of the claim signers. This
    ///         function can be called only for registered wallets
    /// @param claim Operator inactivity claim.
    /// @param nonce Current inactivity claim nonce for the given wallet signing
    ///              group. Must be the same as the stored one.
    /// @param groupMembers Identifiers of the wallet signing group members.
    function notifyOperatorInactivity(
        Inactivity.Claim calldata claim,
        uint256 nonce,
        uint32[] calldata groupMembers
    ) external {
        uint256 gasStart = gasleft();

        bytes32 walletID = claim.walletID;

        require(nonce == inactivityClaimNonce[walletID], "Invalid nonce");

        (bytes32 pubKeyX, bytes32 pubKeyY) = wallets
            .getWalletPublicKeyCoordinates(walletID);
        bytes32 memberIdsHash = wallets.getWalletMembersIdsHash(walletID);

        require(
            memberIdsHash == keccak256(abi.encode(groupMembers)),
            "Invalid group members"
        );

        uint32[] memory ineligibleOperators = Inactivity.verifyClaim(
            sortitionPool,
            claim,
            bytes.concat(pubKeyX, pubKeyY),
            nonce,
            groupMembers
        );

        inactivityClaimNonce[walletID]++;

        emit InactivityClaimed(walletID, nonce, msg.sender);

        sortitionPool.setRewardIneligibility(
            ineligibleOperators,
            // solhint-disable-next-line not-rely-on-time
            block.timestamp + _sortitionPoolRewardsBanDuration
        );

        if (claim.heartbeatFailed) {
            walletOwner.__ecdsaWalletHeartbeatFailedCallback(
                walletID,
                pubKeyX,
                pubKeyY
            );
        }

        reimbursementPool.refund(
            (gasStart - gasleft()) + _notifyOperatorInactivityGasOffset,
            msg.sender
        );
    }

    /// @notice Allows the wallet owner to add all signing group members of the
    ///         wallet with the given ID to the slashing queue of the staking .
    ///         contract. The notifier will receive reward per each group member
    ///         from the staking contract notifiers treasury. The reward is
    ///         scaled by the `rewardMultiplier` provided as a parameter.
    /// @param amount Amount of tokens to seize from each signing group member.
    /// @param rewardMultiplier Fraction of the staking contract notifiers
    ///        reward the notifier should receive; should be between [0, 100].
    /// @param notifier Address of the misbehavior notifier.
    /// @param walletID ID of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events.
    ///      - `rewardMultiplier` must be between [0, 100].
    ///      - This function does revert if staking contract call reverts.
    ///        The calling code needs to handle the potential revert.
    function seize(
        uint96 amount,
        uint256 rewardMultiplier,
        address notifier,
        bytes32 walletID,
        uint32[] calldata walletMembersIDs
    ) external onlyWalletOwner {
        bytes32 memberIdsHash = wallets.getWalletMembersIdsHash(walletID);
        require(
            memberIdsHash == keccak256(abi.encode(walletMembersIDs)),
            "Invalid wallet members identifiers"
        );

        address[] memory groupMembersAddresses = sortitionPool.getIDOperators(
            walletMembersIDs
        );
        address[] memory stakingProvidersAddresses = new address[](
            walletMembersIDs.length
        );
        for (uint256 i = 0; i < groupMembersAddresses.length; i++) {
            stakingProvidersAddresses[i] = operatorToStakingProvider(
                groupMembersAddresses[i]
            );
        }

        staking.seize(
            amount,
            rewardMultiplier,
            notifier,
            stakingProvidersAddresses
        );
    }

    /// @notice Checks if DKG result is valid for the current DKG.
    /// @param result DKG result.
    /// @return True if the result is valid. If the result is invalid it returns
    ///         false and an error message.
    function isDkgResultValid(DKG.Result calldata result)
        external
        view
        returns (bool, string memory)
    {
        return dkg.isResultValid(result);
    }

    /// @notice Check current wallet creation state.
    function getWalletCreationState() external view returns (DKG.State) {
        return dkg.currentState();
    }

    /// @notice Checks whether the given operator is a member of the given
    ///         wallet signing group.
    /// @param walletID ID of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @param operator Address of the checked operator.
    /// @param walletMemberIndex Position of the operator in the wallet signing
    ///        group members list.
    /// @return True - if the operator is a member of the given wallet signing
    ///         group. False - otherwise.
    /// @dev Requirements:
    ///      - The `operator` parameter must be an actual sortition pool operator.
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events.
    ///      - The `walletMemberIndex` must be in range [1, walletMembersIDs.length]
    function isWalletMember(
        bytes32 walletID,
        uint32[] calldata walletMembersIDs,
        address operator,
        uint256 walletMemberIndex
    ) external view returns (bool) {
        uint32 operatorID = sortitionPool.getOperatorID(operator);

        require(operatorID != 0, "Not a sortition pool operator");

        bytes32 memberIdsHash = wallets.getWalletMembersIdsHash(walletID);

        require(
            memberIdsHash == keccak256(abi.encode(walletMembersIDs)),
            "Invalid wallet members identifiers"
        );

        require(
            1 <= walletMemberIndex &&
                walletMemberIndex <= walletMembersIDs.length,
            "Wallet member index is out of range"
        );

        return walletMembersIDs[walletMemberIndex - 1] == operatorID;
    }

    /// @notice Checks if awaiting seed timed out.
    /// @return True if awaiting seed timed out, false otherwise.
    function hasSeedTimedOut() external view returns (bool) {
        return dkg.hasSeedTimedOut();
    }

    /// @notice Checks if DKG timed out. The DKG timeout period includes time required
    ///         for off-chain protocol execution and time for the result publication
    ///         for all group members. After this time result cannot be submitted
    ///         and DKG can be notified about the timeout.
    /// @return True if DKG timed out, false otherwise.
    function hasDkgTimedOut() external view returns (bool) {
        return dkg.hasDkgTimedOut();
    }

    function getWallet(bytes32 walletID)
        external
        view
        returns (Wallets.Wallet memory)
    {
        return wallets.registry[walletID];
    }

    /// @notice Gets public key of a wallet with a given wallet ID.
    ///         The public key is returned in an uncompressed format as a 64-byte
    ///         concatenation of X and Y coordinates.
    /// @param walletID ID of the wallet.
    /// @return Uncompressed public key of the wallet.
    function getWalletPublicKey(bytes32 walletID)
        external
        view
        returns (bytes memory)
    {
        return wallets.getWalletPublicKey(walletID);
    }

    /// @notice Checks if a wallet with the given ID is registered.
    /// @param walletID Wallet's ID.
    /// @return True if wallet is registered, false otherwise.
    function isWalletRegistered(bytes32 walletID) external view returns (bool) {
        return wallets.isWalletRegistered(walletID);
    }

    /// @notice The minimum authorization amount required so that operator can
    ///         participate in ECDSA Wallet operations.
    function minimumAuthorization() external view returns (uint96) {
        return authorization.parameters.minimumAuthorization;
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

    /// @notice Retrieves dkg parameters that were set in DKG library.
    function dkgParameters() external view returns (DKG.Parameters memory) {
        return dkg.parameters;
    }

    /// @notice Returns authorization-related parameters.
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
    ///         period in seconds. It is the time, before authorization decrease
    ///         delay end, during which the pending authorization decrease
    ///         request can be overwritten.
    ///         If set to 0, pending authorization decrease request can not be
    ///         overwritten until the entire `authorizationDecreaseDelay` ends.
    ///         If set to value equal `authorizationDecreaseDelay`, request can
    ///         always be overwritten.
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

    /// @notice Retrieves reward-related parameters.
    /// @return maliciousDkgResultNotificationRewardMultiplier Percentage of the
    ///         staking contract malicious behavior notification reward which
    ///         will be transferred to the notifier reporting about a malicious
    ///         DKG result. Notifiers are rewarded from a notifiers treasury
    ///         pool. For example, if notification reward is 1000 and the value
    ///         of the multiplier is 5, the notifier will receive:
    ///         5% of 1000 = 50 per each operator affected.
    /// @return sortitionPoolRewardsBanDuration Duration of the sortition pool
    ///         rewards ban imposed on operators who missed their turn for DKG
    ///         result submission or who failed a heartbeat.
    function rewardParameters()
        external
        view
        returns (
            uint256 maliciousDkgResultNotificationRewardMultiplier,
            uint256 sortitionPoolRewardsBanDuration
        )
    {
        return (
            _maliciousDkgResultNotificationRewardMultiplier,
            _sortitionPoolRewardsBanDuration
        );
    }

    /// @notice Retrieves slashing-related parameters.
    /// @return maliciousDkgResultSlashingAmount Slashing amount for submitting
    ///         a malicious DKG result. Every DKG result submitted can be
    ///         challenged for the time of `dkg.resultChallengePeriodLength`.
    ///         If the DKG result submitted is challenged and proven to be
    ///         malicious, the operator who submitted the malicious result is
    ///         slashed for `_maliciousDkgResultSlashingAmount`.
    function slashingParameters()
        external
        view
        returns (uint96 maliciousDkgResultSlashingAmount)
    {
        return _maliciousDkgResultSlashingAmount;
    }

    /// @notice Retrieves gas-related parameters.
    /// @return dkgResultSubmissionGas Calculated max gas cost for submitting
    ///         a DKG result. This will be refunded as part of the DKG approval
    ///         process. It is in the submitter's interest to not skip his
    ///         priority turn on the approval, otherwise the refund of the DKG
    ///         submission will be refunded to another group member that will
    ///         call the DKG approve function.
    /// @return dkgResultApprovalGasOffset Gas that is meant to balance the DKG
    ///         result approval's overall cost. It can be updated by the
    ///         governance based on the current market conditions.
    /// @return notifyOperatorInactivityGasOffset Gas that is meant to balance
    ///         the notification of an operator inactivity. It can be updated by
    ///         the governance based on the current market conditions.
    /// @return notifySeedTimeoutGasOffset Gas that is meant to balance the
    ///         notification of a seed for DKG delivery timeout. It can be updated
    ///         by the governance based on the current market conditions.
    /// @return notifyDkgTimeoutNegativeGasOffset Gas that is meant to balance
    ///         the notification of a DKG protocol execution timeout. It can be
    ///         updated by the governance based on the current market conditions.
    function gasParameters()
        external
        view
        returns (
            uint256 dkgResultSubmissionGas,
            uint256 dkgResultApprovalGasOffset,
            uint256 notifyOperatorInactivityGasOffset,
            uint256 notifySeedTimeoutGasOffset,
            uint256 notifyDkgTimeoutNegativeGasOffset
        )
    {
        return (
            _dkgResultSubmissionGas,
            _dkgResultApprovalGasOffset,
            _notifyOperatorInactivityGasOffset,
            _notifySeedTimeoutGasOffset,
            _notifyDkgTimeoutNegativeGasOffset
        );
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

pragma solidity ^0.8.9;

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

pragma solidity ^0.8.9;

interface IWalletOwner {
    /// @notice Callback function executed once a new wallet is created.
    /// @dev Should be callable only by the Wallet Registry.
    /// @param walletID Wallet's unique identifier.
    /// @param publicKeyY Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    function __ecdsaWalletCreatedCallback(
        bytes32 walletID,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external;

    /// @notice Callback function executed once a wallet heartbeat failure
    ///         is detected.
    /// @dev Should be callable only by the Wallet Registry.
    /// @param walletID Wallet's unique identifier.
    /// @param publicKeyY Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    function __ecdsaWalletHeartbeatFailedCallback(
        bytes32 walletID,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external;
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

import "./IRandomBeaconConsumer.sol";

/// @title Random Beacon interface
interface IRandomBeacon {
    /// @notice Creates a request to generate a new relay entry. Requires a
    ///         request fee denominated in T token.
    /// @param callbackContract Beacon consumer callback contract.
    function requestRelayEntry(IRandomBeaconConsumer callbackContract) external;
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

import "../libraries/EcdsaDkg.sol";

interface IWalletRegistry {
    /// @notice Requests a new wallet creation.
    /// @dev Only the Wallet Owner can call this function.
    function requestNewWallet() external;

    /// @notice Closes an existing wallet.
    /// @param walletID ID of the wallet.
    /// @dev Only the Wallet Owner can call this function.
    function closeWallet(bytes32 walletID) external;

    /// @notice Adds all signing group members of the wallet with the given ID
    ///         to the slashing queue of the staking contract. The notifier will
    ///         receive reward per each group member from the staking contract
    ///         notifiers treasury. The reward is scaled by the
    ///         `rewardMultiplier` provided as a parameter.
    /// @param amount Amount of tokens to seize from each signing group member
    /// @param rewardMultiplier Fraction of the staking contract notifiers
    ///        reward the notifier should receive; should be between [0, 100]
    /// @param notifier Address of the misbehavior notifier
    /// @param walletID ID of the wallet
    /// @param walletMembersIDs Identifiers of the wallet signing group members
    /// @dev Only the Wallet Owner can call this function.
    ///      Requirements:
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events.
    ///      - `rewardMultiplier` must be between [0, 100].
    ///      - This function does revert if staking contract call reverts.
    ///        The calling code needs to handle the potential revert.
    function seize(
        uint96 amount,
        uint256 rewardMultiplier,
        address notifier,
        bytes32 walletID,
        uint32[] calldata walletMembersIDs
    ) external;

    /// @notice Gets public key of a wallet with a given wallet ID.
    ///         The public key is returned in an uncompressed format as a 64-byte
    ///         concatenation of X and Y coordinates.
    /// @param walletID ID of the wallet.
    /// @return Uncompressed public key of the wallet.
    function getWalletPublicKey(bytes32 walletID)
        external
        view
        returns (bytes memory);

    /// @notice Check current wallet creation state.
    function getWalletCreationState() external view returns (EcdsaDkg.State);

    /// @notice Checks whether the given operator is a member of the given
    ///         wallet signing group.
    /// @param walletID ID of the wallet
    /// @param walletMembersIDs Identifiers of the wallet signing group members
    /// @param operator Address of the checked operator
    /// @param walletMemberIndex Position of the operator in the wallet signing
    ///        group members list
    /// @return True - if the operator is a member of the given wallet signing
    ///         group. False - otherwise.
    /// @dev Requirements:
    ///      - The `operator` parameter must be an actual sortition pool operator.
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events.
    ///      - The `walletMemberIndex` must be in range [1, walletMembersIDs.length]
    function isWalletMember(
        bytes32 walletID,
        uint32[] calldata walletMembersIDs,
        address operator,
        uint256 walletMemberIndex
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

library Wallets {
    struct Wallet {
        // Keccak256 hash of group members identifiers array. Group members do not
        // include operators selected by the sortition pool that misbehaved during DKG.
        bytes32 membersIdsHash;
        // Uncompressed ECDSA public key stored as X and Y coordinates (32 bytes each).
        bytes32 publicKeyX;
        bytes32 publicKeyY;
        // This struct doesn't contain `__gap` property as the structure is stored
        // in a mapping, mappings store values in different slots and they are
        // not contiguous with other values.
    }

    struct Data {
        // Mapping of keccak256 hashes of wallet public keys to wallet details.
        // Hash of public key is considered an unique wallet identifier.
        mapping(bytes32 => Wallet) registry;
        // Reserved storage space in case we need to add more variables.
        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        // slither-disable-next-line unused-state
        uint256[49] __gap;
    }

    /// @notice Performs preliminary validation of a new group public key.
    ///         The group public key must be unique and have 64 bytes in length.
    ///         If the validation fails, the function reverts. This function
    ///         must be called first for a public key of a wallet added with
    ///         `addWallet` function.
    /// @param publicKey Uncompressed public key of a new wallet.
    function validatePublicKey(Data storage self, bytes calldata publicKey)
        internal
        view
    {
        require(publicKey.length == 64, "Invalid length of the public key");

        bytes32 walletID = keccak256(publicKey);
        require(
            self.registry[walletID].publicKeyX == bytes32(0),
            "Wallet with the given public key already exists"
        );

        bytes32 publicKeyX = bytes32(publicKey[:32]);
        require(publicKeyX != bytes32(0), "Wallet public key must be non-zero");
    }

    /// @notice Registers a new wallet. This function does not validate
    ///         parameters. The code calling this function must call
    ///         `validatePublicKey` first.
    /// @dev Uses a public key hash as a unique identifier of a wallet.
    /// @param membersIdsHash Keccak256 hash of group members identifiers array
    /// @param publicKey Uncompressed public key
    /// @return walletID Wallet's ID
    /// @return publicKeyX Wallet's public key's X coordinate
    /// @return publicKeyY Wallet's public key's Y coordinate
    function addWallet(
        Data storage self,
        bytes32 membersIdsHash,
        bytes calldata publicKey
    )
        internal
        returns (
            bytes32 walletID,
            bytes32 publicKeyX,
            bytes32 publicKeyY
        )
    {
        walletID = keccak256(publicKey);

        publicKeyX = bytes32(publicKey[:32]);
        publicKeyY = bytes32(publicKey[32:]);

        self.registry[walletID].membersIdsHash = membersIdsHash;
        self.registry[walletID].publicKeyX = publicKeyX;
        self.registry[walletID].publicKeyY = publicKeyY;
    }

    /// @notice Deletes wallet with the given ID from the registry. Reverts
    ///         if wallet with the given ID has not been registered or if it
    ///         has already been closed.
    function deleteWallet(Data storage self, bytes32 walletID) internal {
        require(
            isWalletRegistered(self, walletID),
            "Wallet with the given ID has not been registered"
        );

        delete self.registry[walletID];
    }

    /// @notice Checks if a wallet with the given ID is registered.
    /// @param walletID Wallet's ID
    /// @return True if a wallet is registered, false otherwise
    function isWalletRegistered(Data storage self, bytes32 walletID)
        internal
        view
        returns (bool)
    {
        return self.registry[walletID].publicKeyX != bytes32(0);
    }

    /// @notice Returns Keccak256 hash of the wallet signing group members
    ///         identifiers array. Group members do not include operators
    ///         selected by the sortition pool that misbehaved during DKG.
    ///         Reverts if wallet with the given ID is not registered.
    /// @param walletID ID of the wallet
    /// @return Wallet signing group members hash
    function getWalletMembersIdsHash(Data storage self, bytes32 walletID)
        internal
        view
        returns (bytes32)
    {
        require(
            isWalletRegistered(self, walletID),
            "Wallet with the given ID has not been registered"
        );

        return self.registry[walletID].membersIdsHash;
    }

    /// @notice Gets public key of a wallet with the given wallet ID.
    ///         The public key is returned as X and Y coordinates.
    ///         Reverts if wallet with the given ID is not registered.
    /// @param walletID ID of the wallet
    /// @return x Public key X coordinate
    /// @return y Public key Y coordinate
    function getWalletPublicKeyCoordinates(Data storage self, bytes32 walletID)
        internal
        view
        returns (bytes32 x, bytes32 y)
    {
        require(
            isWalletRegistered(self, walletID),
            "Wallet with the given ID has not been registered"
        );

        Wallet storage wallet = self.registry[walletID];

        return (wallet.publicKeyX, wallet.publicKeyY);
    }

    /// @notice Gets public key of a wallet with the given wallet ID.
    ///         The public key is returned in an uncompressed format as a 64-byte
    ///         concatenation of X and Y coordinates.
    ///         Reverts if wallet with the given ID is not registered.
    /// @param walletID ID of the wallet
    /// @return Uncompressed public key of the wallet
    function getWalletPublicKey(Data storage self, bytes32 walletID)
        internal
        view
        returns (bytes memory)
    {
        (bytes32 x, bytes32 y) = getWalletPublicKeyCoordinates(self, walletID);
        return bytes.concat(x, y);
    }
}

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "@threshold-network/solidity-contracts/contracts/staking/IStaking.sol";

/// @notice Library managing the state of stake authorizations for ECDSA
///         operator contract and the presence of operators in the sortition
///         pool based on the stake authorized for them.
library EcdsaAuthorization {
    struct Parameters {
        // The minimum authorization required by ECDSA application so that
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
        // This struct doesn't contain `__gap` property as the structure is
        // stored inside `Data` struct, that already have a gap that can be used
        // on upgrade.
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
        // Reserved storage space in case we need to add more variables.
        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        // slither-disable-next-line unused-state
        uint256[46] __gap;
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

    /// @notice Sets the minimum authorization for ECDSA application. Without
    ///         at least the minimum authorization, staking provider is not
    ///         eligible to join and operate in the network.
    function setMinimumAuthorization(
        Data storage self,
        uint96 _minimumAuthorization
    ) internal {
        self.parameters.minimumAuthorization = _minimumAuthorization;
    }

    /// @notice Sets the authorization decrease delay. It is the time in seconds
    ///         that needs to pass between the time authorization decrease is
    ///         requested and the time the authorization decrease can be
    ///         approved, no matter the authorization decrease amount.
    function setAuthorizationDecreaseDelay(
        Data storage self,
        uint64 _authorizationDecreaseDelay
    ) internal {
        self
            .parameters
            .authorizationDecreaseDelay = _authorizationDecreaseDelay;
    }

    /// @notice Sets the authorization decrease change period. It is the time
    ///         period before the authorization decrease delay end,
    ///         during which the authorization decrease request can be
    ///         overwritten.
    function setAuthorizationDecreaseChangePeriod(
        Data storage self,
        uint64 _authorizationDecreaseChangePeriod
    ) internal {
        self
            .parameters
            .authorizationDecreaseChangePeriod = _authorizationDecreaseChangePeriod;
    }

    /// @notice Used by staking provider to set operator address that will
    ///         operate ECDSA node. The given staking provider can set operator
    ///         address only one time. The operator address can not be changed
    ///         and must be unique. Reverts if the operator is already set for
    ///         the staking provider or if the operator address is already in
    ///         use. Reverts if there is a pending authorization decrease for
    ///         the staking provider.
    function registerOperator(Data storage self, address operator) internal {
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

    /// @notice Used by T staking contract to inform the application that the
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
    ) internal {
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

    /// @notice Used by T staking contract to inform the application that the
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
    ) internal {
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
    ) internal {
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

    /// @notice Used by T staking contract to inform the application the
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
    ) internal {
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
    ///         by ECDSA. Function reverts if there is no minimum stake
    ///         authorized or if the operator is not known. If there was an
    ///         authorization decrease requested, it is activated by starting
    ///         the authorization decrease delay.
    function joinSortitionPool(
        Data storage self,
        IStaking tokenStaking,
        SortitionPool sortitionPool
    ) internal {
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
    ) internal {
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
    ) internal view returns (bool) {
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
    ) internal view returns (uint96) {
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
    ) internal view returns (uint96) {
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
    ) internal view returns (uint96) {
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
    ) internal view returns (uint64) {
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

// SPDX-License-Identifier: MIT
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

// Initial version copied from Keep Network Random Beacon:
// https://github.com/keep-network/keep-core/blob/5138c7628868dbeed3ae2164f76fccc6c1fbb9e8/solidity/random-beacon/contracts/libraries/DKG.sol
//
// With the following differences:
// - the group size was set to 100,
// - offchainDkgTimeout was removed,
// - submission eligibility verification is not performed on-chain,
// - submission eligibility delay was replaced with a submission timeout,
// - seed timeout notification requires seedTimeout period to pass.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "@keep-network/random-beacon/contracts/libraries/BytesLib.sol";
import "../EcdsaDkgValidator.sol";

library EcdsaDkg {
    using BytesLib for bytes;
    using ECDSAUpgradeable for bytes32;

    struct Parameters {
        // Time in blocks during which a seed is expected to be delivered.
        // DKG starts only after a seed is delivered. The time the contract
        // awaits for a seed is not included in the DKG timeout.
        uint256 seedTimeout;
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
        // This struct doesn't contain `__gap` property as the structure is
        // stored inside `Data` struct, that already have a gap that can be used
        // on upgrade.
    }

    struct Data {
        // Address of the Sortition Pool contract.
        SortitionPool sortitionPool;
        // Address of the EcdsaDkgValidator contract.
        EcdsaDkgValidator dkgValidator;
        // DKG parameters. The parameters should persist between DKG executions.
        // They should be updated with dedicated set functions only when DKG is not
        // in progress.
        Parameters parameters;
        // Time in block at which DKG state was locked.
        uint256 stateLockBlock;
        // Time in blocks at which DKG started.
        uint256 startBlock;
        // Seed used to start DKG.
        uint256 seed;
        // Time in blocks that should be added to result submission eligibility
        // delay calculation. It is used in case of a challenge to adjust
        // DKG timeout calculation.
        uint256 resultSubmissionStartBlockOffset;
        // Hash of submitted DKG result.
        bytes32 submittedResultHash;
        // Block number from the moment of the DKG result submission.
        uint256 submittedResultBlock;
        // Reserved storage space in case we need to add more variables.
        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        // slither-disable-next-line unused-state
        uint256[38] __gap;
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
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice States for phases of group creation. The states doesn't include
    ///         timeouts which should be tracked and notified individually.
    enum State {
        // Group creation is not in progress. It is a state set after group creation
        // completion either by timeout or by a result approval.
        IDLE,
        // Group creation is awaiting the seed and sortition pool is locked.
        AWAITING_SEED,
        // DKG protocol execution is in progress. A result is being calculated
        // by the clients in this state and the contract awaits a result submission.
        // This is a state to which group creation returns in case of a result
        // challenge notification.
        AWAITING_RESULT,
        // DKG result was submitted and awaits an approval or a challenge. If a result
        // gets challenge the state returns to `AWAITING_RESULT`. If a result gets
        // approval the state changes to `IDLE`.
        CHALLENGE
    }

    /// @dev Size of a group in ECDSA wallet.
    uint256 public constant groupSize = 100;

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

    /// @notice Initializes SortitionPool and EcdsaDkgValidator addresses.
    ///        Can be performed only once.
    /// @param _sortitionPool Sortition Pool reference
    /// @param _dkgValidator EcdsaDkgValidator reference
    function init(
        Data storage self,
        SortitionPool _sortitionPool,
        EcdsaDkgValidator _dkgValidator
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
                state = State.AWAITING_RESULT;

                if (self.submittedResultBlock > 0) {
                    state = State.CHALLENGE;
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

        self.stateLockBlock = block.number;
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
    function submitResult(Data storage self, Result calldata result) internal {
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

    /// @notice Checks if awaiting seed timed out.
    /// @return True if awaiting seed timed out, false otherwise.
    function hasSeedTimedOut(Data storage self) internal view returns (bool) {
        return
            currentState(self) == State.AWAITING_SEED &&
            block.number > (self.stateLockBlock + self.parameters.seedTimeout);
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
                self.resultSubmissionStartBlockOffset +
                self.parameters.resultSubmissionTimeout);
    }

    /// @notice Notifies about the seed was not delivered and restores the
    ///         initial DKG state (IDLE).
    function notifySeedTimeout(Data storage self) internal {
        require(hasSeedTimedOut(self), "Awaiting seed has not timed out");

        emit DkgSeedTimedOut();

        complete(self);
    }

    /// @notice Notifies about DKG timeout.
    function notifyDkgTimeout(Data storage self) internal {
        require(hasDkgTimedOut(self), "DKG has not timed out");

        emit DkgTimedOut();

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
        internal
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
        internal
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
        self.resultSubmissionStartBlockOffset = block.number - self.startBlock;

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
    ///         wrapping the call to EcdsaDkgValidator and TokenStaking
    ///         contracts inside a try-catch.
    function requireChallengeExtraGas(Data storage self) internal view {
        require(
            gasleft() >= self.parameters.resultChallengeExtraGas,
            "Not enough extra gas left"
        );
    }

    /// @notice Checks if DKG result is valid for the current DKG.
    /// @param result DKG result.
    /// @return True if the result is valid. If the result is invalid it returns
    ///         false and an error message.
    function isResultValid(Data storage self, Result calldata result)
        internal
        view
        returns (bool, string memory)
    {
        require(self.startBlock > 0, "DKG has not been started");

        return self.dkgValidator.validate(result, self.seed, self.startBlock);
    }

    /// @notice Set setSeedTimeout parameter.
    function setSeedTimeout(Data storage self, uint256 newSeedTimeout)
        internal
    {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(newSeedTimeout > 0, "New value should be greater than zero");

        self.parameters.seedTimeout = newSeedTimeout;
    }

    /// @notice Set resultChallengePeriodLength parameter.
    function setResultChallengePeriodLength(
        Data storage self,
        uint256 newResultChallengePeriodLength
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            newResultChallengePeriodLength > 0,
            "New value should be greater than zero"
        );

        self
            .parameters
            .resultChallengePeriodLength = newResultChallengePeriodLength;
    }

    /// @notice Set resultChallengeExtraGas parameter.
    function setResultChallengeExtraGas(
        Data storage self,
        uint256 newResultChallengeExtraGas
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        self.parameters.resultChallengeExtraGas = newResultChallengeExtraGas;
    }

    /// @notice Set resultSubmissionTimeout parameter.
    function setResultSubmissionTimeout(
        Data storage self,
        uint256 newResultSubmissionTimeout
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            newResultSubmissionTimeout > 0,
            "New value should be greater than zero"
        );

        self.parameters.resultSubmissionTimeout = newResultSubmissionTimeout;
    }

    /// @notice Set submitterPrecedencePeriodLength parameter.
    function setSubmitterPrecedencePeriodLength(
        Data storage self,
        uint256 newSubmitterPrecedencePeriodLength
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            newSubmitterPrecedencePeriodLength <
                self.parameters.resultSubmissionTimeout,
            "New value should be less than result submission period length"
        );

        self
            .parameters
            .submitterPrecedencePeriodLength = newSubmitterPrecedencePeriodLength;
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

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "@keep-network/random-beacon/contracts/libraries/BytesLib.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";

import "./Wallets.sol";

library EcdsaInactivity {
    using BytesLib for bytes;
    using ECDSAUpgradeable for bytes32;

    struct Claim {
        // ID of the wallet whose signing group is raising the inactivity claim.
        bytes32 walletID;
        // Indices of group members accused of being inactive. Indices must be in
        // range [1, groupMembers.length], unique, and sorted in ascending order.
        uint256[] inactiveMembersIndices;
        // Indicates if inactivity claim is a wallet-wide heartbeat failure.
        // If wallet failed a heartbeat, this is signalled to the wallet owner
        // who may decide to move responsibilities to another wallet
        // given that the wallet who failed the heartbeat is at risk of not
        // being able to sign messages soon.
        bool heartbeatFailed;
        // Concatenation of signatures from members supporting the claim.
        // The message to be signed by each member is keccak256 hash of the
        // concatenation of inactivity claim nonce for the given wallet, wallet
        // public key, inactive members indices, and boolean flag indicating
        // if this is a wallet-wide heartbeat failure. The calculated hash should
        // be prefixed with `\x19Ethereum signed message:\n` before signing, so
        // the message to sign is:
        // `\x19Ethereum signed message:\n${keccak256(
        //    nonce | walletPubKey | inactiveMembersIndices | heartbeatFailed
        // )}`
        bytes signatures;
        // Indices of members corresponding to each signature. Indices must be
        // in range [1, groupMembers.length], unique, and sorted in ascending
        // order.
        uint256[] signingMembersIndices;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice The minimum number of wallet signing group members needed to
    ///         interact according to the protocol to produce a valid inactivity
    ///         claim.
    uint256 public constant groupThreshold = 51;

    /// @notice Size in bytes of a single signature produced by member
    ///         supporting the inactivity claim.
    uint256 public constant signatureByteSize = 65;

    /// @notice Verifies the inactivity claim according to the rules defined in
    ///         `Claim` struct documentation. Reverts if verification fails.
    /// @dev Wallet signing group members hash is validated upstream in
    ///      `WalletRegistry.notifyOperatorInactivity()`
    /// @param sortitionPool Sortition pool reference
    /// @param claim Inactivity claim
    /// @param walletPubKey Public key of the wallet
    /// @param nonce Current inactivity nonce for wallet used in the claim
    /// @param groupMembers Identifiers of group members
    /// @return inactiveMembers Identifiers of members who are inactive
    function verifyClaim(
        SortitionPool sortitionPool,
        Claim calldata claim,
        bytes memory walletPubKey,
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

        bytes32 signedMessageHash = keccak256(
            abi.encodePacked(
                nonce,
                walletPubKey,
                claim.inactiveMembersIndices,
                claim.heartbeatFailed
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
    /// @param indices Array to validate.
    /// @param groupSize Group size used as reference.
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

// SPDX-License-Identifier: MIT
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

// Initial version copied from Keep Network Random Beacon:
// https://github.com/keep-network/keep-core/blob/5138c7628868dbeed3ae2164f76fccc6c1fbb9e8/solidity/random-beacon/contracts/DKGValidator.sol
//
// With the following differences:
// - group public key length,
// - group size and related thresholds,
// - documentation.

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@keep-network/random-beacon/contracts/libraries/BytesLib.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "./libraries/EcdsaDkg.sol";

/// @title DKG result validator
/// @notice EcdsaDkgValidator allows performing a full validation of DKG result,
///         including checking the format of fields in the result, declared
///         selected group members, and signatures of operators supporting the
///         result. The operator submitting the result should perform the
///         validation using a free contract call before submitting the result
///         to ensure their result is valid and can not be challenged. All other
///         network operators should perform validation of the submitted result
///         using a free contract call and challenge the result if the
///         validation fails.
contract EcdsaDkgValidator {
    using BytesLib for bytes;
    using ECDSA for bytes32;

    /// @dev Size of a group in DKG.
    uint256 public constant groupSize = 100;

    /// @dev The minimum number of group members needed to interact according to
    ///      the protocol to produce a signature. The adversary can not learn
    ///      anything about the key as long as it does not break into
    ///      groupThreshold+1 of members.
    uint256 public constant groupThreshold = 51;

    /// @dev The minimum number of active and properly behaving group members
    ///      during the DKG needed to accept the result. This number is higher
    ///      than `groupThreshold` to keep a safety margin for members becoming
    ///      inactive after DKG so that the group can still produce signature.
    uint256 public constant activeThreshold = 90; // 90% of groupSize

    /// @dev Size in bytes of a public key produced by group members during the
    /// the DKG. The length assumes uncompressed ECDSA public key.
    uint256 public constant publicKeyByteSize = 64;

    /// @dev Size in bytes of a single signature produced by operator supporting
    ///      DKG result.
    uint256 public constant signatureByteSize = 65;

    SortitionPool public immutable sortitionPool;

    constructor(SortitionPool _sortitionPool) {
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
        EcdsaDkg.Result calldata result,
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

        // At this point all group members and misbehaved members were verified
        if (!validateMembersHash(result)) {
            return (false, "Invalid members hash");
        }

        return (true, "");
    }

    /// @notice Performs a static validation of DKG result fields: lengths,
    ///         ranges, and order of arrays.
    /// @return isValid true if the result is valid, false otherwise
    /// @return errorMsg validation error message; empty for a valid result
    function validateFields(EcdsaDkg.Result calldata result)
        public
        pure
        returns (bool isValid, string memory errorMsg)
    {
        if (result.groupPubKey.length != publicKeyByteSize) {
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
    function validateGroupMembers(EcdsaDkg.Result calldata result, uint256 seed)
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
    function validateSignatures(
        EcdsaDkg.Result calldata result,
        uint256 startBlock
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(
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
    /// @return true if calculated result's group members hash matches with the
    /// one that is challenged.
    function validateMembersHash(EcdsaDkg.Result calldata result)
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

pragma solidity 0.8.9;

import "@thesis/solidity-contracts/contracts/token/IERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RNG.sol";
import "./SortitionTree.sol";
import "./Rewards.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
contract SortitionPool is SortitionTree, Rewards, Ownable, IReceiveApproval {
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
  /// already present.
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

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

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

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

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

// SPDX-License-Identifier: MIT
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

pragma solidity ^0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

    /// @notice Refresh Keep stake owner. Can be called only by the old owner.
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
    ///         application.
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
    ///         Can be called only by the owner or the staking provider.
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

pragma solidity ^0.8.9;

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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

pragma solidity 0.8.9;

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