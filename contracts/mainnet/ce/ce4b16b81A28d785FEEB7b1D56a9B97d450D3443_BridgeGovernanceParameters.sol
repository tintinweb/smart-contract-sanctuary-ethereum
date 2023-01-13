// SPDX-License-Identifier: GPL-3.0-only

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

pragma solidity 0.8.17;

/// @title Bridge Governance library for storing updatable parameters.
library BridgeGovernanceParameters {
    struct TreasuryData {
        address newTreasury;
        uint256 treasuryChangeInitiated;
    }

    struct DepositData {
        uint64 newDepositDustThreshold;
        uint256 depositDustThresholdChangeInitiated;
        uint64 newDepositTreasuryFeeDivisor;
        uint256 depositTreasuryFeeDivisorChangeInitiated;
        uint64 newDepositTxMaxFee;
        uint256 depositTxMaxFeeChangeInitiated;
        uint32 newDepositRevealAheadPeriod;
        uint256 depositRevealAheadPeriodChangeInitiated;
    }

    struct RedemptionData {
        uint64 newRedemptionDustThreshold;
        uint256 redemptionDustThresholdChangeInitiated;
        uint64 newRedemptionTreasuryFeeDivisor;
        uint256 redemptionTreasuryFeeDivisorChangeInitiated;
        uint64 newRedemptionTxMaxFee;
        uint256 redemptionTxMaxFeeChangeInitiated;
        uint64 newRedemptionTxMaxTotalFee;
        uint256 redemptionTxMaxTotalFeeChangeInitiated;
        uint32 newRedemptionTimeout;
        uint256 redemptionTimeoutChangeInitiated;
        uint96 newRedemptionTimeoutSlashingAmount;
        uint256 redemptionTimeoutSlashingAmountChangeInitiated;
        uint32 newRedemptionTimeoutNotifierRewardMultiplier;
        uint256 redemptionTimeoutNotifierRewardMultiplierChangeInitiated;
    }

    struct MovingFundsData {
        uint64 newMovingFundsTxMaxTotalFee;
        uint256 movingFundsTxMaxTotalFeeChangeInitiated;
        uint64 newMovingFundsDustThreshold;
        uint256 movingFundsDustThresholdChangeInitiated;
        uint32 newMovingFundsTimeoutResetDelay;
        uint256 movingFundsTimeoutResetDelayChangeInitiated;
        uint32 newMovingFundsTimeout;
        uint256 movingFundsTimeoutChangeInitiated;
        uint96 newMovingFundsTimeoutSlashingAmount;
        uint256 movingFundsTimeoutSlashingAmountChangeInitiated;
        uint32 newMovingFundsTimeoutNotifierRewardMultiplier;
        uint256 movingFundsTimeoutNotifierRewardMultiplierChangeInitiated;
        uint16 newMovingFundsCommitmentGasOffset;
        uint256 movingFundsCommitmentGasOffsetChangeInitiated;
        uint64 newMovedFundsSweepTxMaxTotalFee;
        uint256 movedFundsSweepTxMaxTotalFeeChangeInitiated;
        uint32 newMovedFundsSweepTimeout;
        uint256 movedFundsSweepTimeoutChangeInitiated;
        uint96 newMovedFundsSweepTimeoutSlashingAmount;
        uint256 movedFundsSweepTimeoutSlashingAmountChangeInitiated;
        uint32 newMovedFundsSweepTimeoutNotifierRewardMultiplier;
        uint256 movedFundsSweepTimeoutNotifierRewardMultiplierChangeInitiated;
    }

    struct WalletData {
        uint32 newWalletCreationPeriod;
        uint256 walletCreationPeriodChangeInitiated;
        uint64 newWalletCreationMinBtcBalance;
        uint256 walletCreationMinBtcBalanceChangeInitiated;
        uint64 newWalletCreationMaxBtcBalance;
        uint256 walletCreationMaxBtcBalanceChangeInitiated;
        uint64 newWalletClosureMinBtcBalance;
        uint256 walletClosureMinBtcBalanceChangeInitiated;
        uint32 newWalletMaxAge;
        uint256 walletMaxAgeChangeInitiated;
        uint64 newWalletMaxBtcTransfer;
        uint256 walletMaxBtcTransferChangeInitiated;
        uint32 newWalletClosingPeriod;
        uint256 walletClosingPeriodChangeInitiated;
    }

    struct FraudData {
        uint96 newFraudChallengeDepositAmount;
        uint256 fraudChallengeDepositAmountChangeInitiated;
        uint32 newFraudChallengeDefeatTimeout;
        uint256 fraudChallengeDefeatTimeoutChangeInitiated;
        uint96 newFraudSlashingAmount;
        uint256 fraudSlashingAmountChangeInitiated;
        uint32 newFraudNotifierRewardMultiplier;
        uint256 fraudNotifierRewardMultiplierChangeInitiated;
    }

    event DepositDustThresholdUpdateStarted(
        uint64 newDepositDustThreshold,
        uint256 timestamp
    );
    event DepositDustThresholdUpdated(uint64 depositDustThreshold);

    event DepositTreasuryFeeDivisorUpdateStarted(
        uint64 depositTreasuryFeeDivisor,
        uint256 timestamp
    );
    event DepositTreasuryFeeDivisorUpdated(uint64 depositTreasuryFeeDivisor);

    event DepositTxMaxFeeUpdateStarted(
        uint64 newDepositTxMaxFee,
        uint256 timestamp
    );
    event DepositTxMaxFeeUpdated(uint64 depositTxMaxFee);

    event DepositRevealAheadPeriodUpdateStarted(
        uint32 newDepositRevealAheadPeriod,
        uint256 timestamp
    );
    event DepositRevealAheadPeriodUpdated(uint32 depositRevealAheadPeriod);

    event RedemptionDustThresholdUpdateStarted(
        uint64 newRedemptionDustThreshold,
        uint256 timestamp
    );
    event RedemptionDustThresholdUpdated(uint64 redemptionDustThreshold);

    event RedemptionTreasuryFeeDivisorUpdateStarted(
        uint64 newRedemptionTreasuryFeeDivisor,
        uint256 timestamp
    );
    event RedemptionTreasuryFeeDivisorUpdated(
        uint64 redemptionTreasuryFeeDivisor
    );

    event RedemptionTxMaxFeeUpdateStarted(
        uint64 newRedemptionTxMaxFee,
        uint256 timestamp
    );
    event RedemptionTxMaxFeeUpdated(uint64 redemptionTxMaxFee);

    event RedemptionTxMaxTotalFeeUpdateStarted(
        uint64 newRedemptionTxMaxTotalFee,
        uint256 timestamp
    );
    event RedemptionTxMaxTotalFeeUpdated(uint64 redemptionTxMaxTotalFee);

    event RedemptionTimeoutUpdateStarted(
        uint32 newRedemptionTimeout,
        uint256 timestamp
    );
    event RedemptionTimeoutUpdated(uint32 redemptionTimeout);

    event RedemptionTimeoutSlashingAmountUpdateStarted(
        uint96 newRedemptionTimeoutSlashingAmount,
        uint256 timestamp
    );
    event RedemptionTimeoutSlashingAmountUpdated(
        uint96 redemptionTimeoutSlashingAmount
    );

    event RedemptionTimeoutNotifierRewardMultiplierUpdateStarted(
        uint32 newRedemptionTimeoutNotifierRewardMultiplier,
        uint256 timestamp
    );
    event RedemptionTimeoutNotifierRewardMultiplierUpdated(
        uint32 redemptionTimeoutNotifierRewardMultiplier
    );

    event MovingFundsTxMaxTotalFeeUpdateStarted(
        uint64 newMovingFundsTxMaxTotalFee,
        uint256 timestamp
    );
    event MovingFundsTxMaxTotalFeeUpdated(uint64 movingFundsTxMaxTotalFee);

    event MovingFundsDustThresholdUpdateStarted(
        uint64 newMovingFundsDustThreshold,
        uint256 timestamp
    );
    event MovingFundsDustThresholdUpdated(uint64 movingFundsDustThreshold);

    event MovingFundsTimeoutResetDelayUpdateStarted(
        uint32 newMovingFundsTimeoutResetDelay,
        uint256 timestamp
    );
    event MovingFundsTimeoutResetDelayUpdated(
        uint32 movingFundsTimeoutResetDelay
    );

    event MovingFundsTimeoutUpdateStarted(
        uint32 newMovingFundsTimeout,
        uint256 timestamp
    );
    event MovingFundsTimeoutUpdated(uint32 movingFundsTimeout);

    event MovingFundsTimeoutSlashingAmountUpdateStarted(
        uint96 newMovingFundsTimeoutSlashingAmount,
        uint256 timestamp
    );
    event MovingFundsTimeoutSlashingAmountUpdated(
        uint96 movingFundsTimeoutSlashingAmount
    );

    event MovingFundsTimeoutNotifierRewardMultiplierUpdateStarted(
        uint32 newMovingFundsTimeoutNotifierRewardMultiplier,
        uint256 timestamp
    );
    event MovingFundsTimeoutNotifierRewardMultiplierUpdated(
        uint32 movingFundsTimeoutNotifierRewardMultiplier
    );

    event MovingFundsCommitmentGasOffsetUpdateStarted(
        uint16 newMovingFundsCommitmentGasOffset,
        uint256 timestamp
    );
    event MovingFundsCommitmentGasOffsetUpdated(
        uint16 movingFundsCommitmentGasOffset
    );

    event MovedFundsSweepTxMaxTotalFeeUpdateStarted(
        uint64 newMovedFundsSweepTxMaxTotalFee,
        uint256 timestamp
    );
    event MovedFundsSweepTxMaxTotalFeeUpdated(
        uint64 movedFundsSweepTxMaxTotalFee
    );

    event MovedFundsSweepTimeoutUpdateStarted(
        uint32 newMovedFundsSweepTimeout,
        uint256 timestamp
    );
    event MovedFundsSweepTimeoutUpdated(uint32 movedFundsSweepTimeout);

    event MovedFundsSweepTimeoutSlashingAmountUpdateStarted(
        uint96 newMovedFundsSweepTimeoutSlashingAmount,
        uint256 timestamp
    );
    event MovedFundsSweepTimeoutSlashingAmountUpdated(
        uint96 movedFundsSweepTimeoutSlashingAmount
    );

    event MovedFundsSweepTimeoutNotifierRewardMultiplierUpdateStarted(
        uint32 newMovedFundsSweepTimeoutNotifierRewardMultiplier,
        uint256 timestamp
    );
    event MovedFundsSweepTimeoutNotifierRewardMultiplierUpdated(
        uint32 movedFundsSweepTimeoutNotifierRewardMultiplier
    );

    event WalletCreationPeriodUpdateStarted(
        uint32 newWalletCreationPeriod,
        uint256 timestamp
    );
    event WalletCreationPeriodUpdated(uint32 walletCreationPeriod);

    event WalletCreationMinBtcBalanceUpdateStarted(
        uint64 newWalletCreationMinBtcBalance,
        uint256 timestamp
    );
    event WalletCreationMinBtcBalanceUpdated(
        uint64 walletCreationMinBtcBalance
    );

    event WalletCreationMaxBtcBalanceUpdateStarted(
        uint64 newWalletCreationMaxBtcBalance,
        uint256 timestamp
    );
    event WalletCreationMaxBtcBalanceUpdated(
        uint64 walletCreationMaxBtcBalance
    );

    event WalletClosureMinBtcBalanceUpdateStarted(
        uint64 newWalletClosureMinBtcBalance,
        uint256 timestamp
    );
    event WalletClosureMinBtcBalanceUpdated(uint64 walletClosureMinBtcBalance);

    event WalletMaxAgeUpdateStarted(uint32 newWalletMaxAge, uint256 timestamp);
    event WalletMaxAgeUpdated(uint32 walletMaxAge);

    event WalletMaxBtcTransferUpdateStarted(
        uint64 newWalletMaxBtcTransfer,
        uint256 timestamp
    );
    event WalletMaxBtcTransferUpdated(uint64 walletMaxBtcTransfer);

    event WalletClosingPeriodUpdateStarted(
        uint32 newWalletClosingPeriod,
        uint256 timestamp
    );
    event WalletClosingPeriodUpdated(uint32 walletClosingPeriod);

    event FraudChallengeDepositAmountUpdateStarted(
        uint96 newFraudChallengeDepositAmount,
        uint256 timestamp
    );
    event FraudChallengeDepositAmountUpdated(
        uint96 fraudChallengeDepositAmount
    );

    event FraudChallengeDefeatTimeoutUpdateStarted(
        uint32 newFraudChallengeDefeatTimeout,
        uint256 timestamp
    );
    event FraudChallengeDefeatTimeoutUpdated(
        uint32 fraudChallengeDefeatTimeout
    );

    event FraudSlashingAmountUpdateStarted(
        uint96 newFraudSlashingAmount,
        uint256 timestamp
    );
    event FraudSlashingAmountUpdated(uint96 fraudSlashingAmount);

    event FraudNotifierRewardMultiplierUpdateStarted(
        uint32 newFraudNotifierRewardMultiplier,
        uint256 timestamp
    );
    event FraudNotifierRewardMultiplierUpdated(
        uint32 fraudNotifierRewardMultiplier
    );

    event TreasuryUpdateStarted(address newTreasury, uint256 timestamp);
    event TreasuryUpdated(address treasury);

    /// @notice Reverts if called before the governance delay elapses.
    /// @param changeInitiatedTimestamp Timestamp indicating the beginning
    ///        of the change.
    modifier onlyAfterGovernanceDelay(
        uint256 changeInitiatedTimestamp,
        uint256 governanceDelay
    ) {
        /* solhint-disable not-rely-on-time */
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            block.timestamp - changeInitiatedTimestamp >= governanceDelay,
            "Governance delay has not elapsed"
        );
        _;
        /* solhint-enable not-rely-on-time */
    }

    // --- Deposit

    /// @notice Begins the deposit dust threshold amount update process.
    /// @param _newDepositDustThreshold New deposit dust threshold amount.
    function beginDepositDustThresholdUpdate(
        DepositData storage self,
        uint64 _newDepositDustThreshold
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newDepositDustThreshold = _newDepositDustThreshold;
        self.depositDustThresholdChangeInitiated = block.timestamp;
        emit DepositDustThresholdUpdateStarted(
            _newDepositDustThreshold,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the deposit dust threshold amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeDepositDustThresholdUpdate(
        DepositData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.depositDustThresholdChangeInitiated,
            governanceDelay
        )
    {
        emit DepositDustThresholdUpdated(self.newDepositDustThreshold);

        self.newDepositDustThreshold = 0;
        self.depositDustThresholdChangeInitiated = 0;
    }

    /// @notice Begins the deposit treasury fee divisor amount update process.
    /// @param _newDepositTreasuryFeeDivisor New deposit treasury fee divisor amount.
    function beginDepositTreasuryFeeDivisorUpdate(
        DepositData storage self,
        uint64 _newDepositTreasuryFeeDivisor
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newDepositTreasuryFeeDivisor = _newDepositTreasuryFeeDivisor;
        self.depositTreasuryFeeDivisorChangeInitiated = block.timestamp;
        emit DepositTreasuryFeeDivisorUpdateStarted(
            _newDepositTreasuryFeeDivisor,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the deposit treasury fee divisor amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeDepositTreasuryFeeDivisorUpdate(
        DepositData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.depositTreasuryFeeDivisorChangeInitiated,
            governanceDelay
        )
    {
        emit DepositTreasuryFeeDivisorUpdated(
            self.newDepositTreasuryFeeDivisor
        );

        self.newDepositTreasuryFeeDivisor = 0;
        self.depositTreasuryFeeDivisorChangeInitiated = 0;
    }

    /// @notice Begins the deposit tx max fee amount update process.
    /// @param _newDepositTxMaxFee New deposit tx max fee amount.
    function beginDepositTxMaxFeeUpdate(
        DepositData storage self,
        uint64 _newDepositTxMaxFee
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newDepositTxMaxFee = _newDepositTxMaxFee;
        self.depositTxMaxFeeChangeInitiated = block.timestamp;
        emit DepositTxMaxFeeUpdateStarted(_newDepositTxMaxFee, block.timestamp);
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the deposit tx max fee amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeDepositTxMaxFeeUpdate(
        DepositData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.depositTxMaxFeeChangeInitiated,
            governanceDelay
        )
    {
        emit DepositTxMaxFeeUpdated(self.newDepositTxMaxFee);

        self.newDepositTxMaxFee = 0;
        self.depositTxMaxFeeChangeInitiated = 0;
    }

    /// @notice Begins the deposit reveal ahead period update process.
    /// @param _newDepositRevealAheadPeriod New deposit reveal ahead period.
    function beginDepositRevealAheadPeriodUpdate(
        DepositData storage self,
        uint32 _newDepositRevealAheadPeriod
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newDepositRevealAheadPeriod = _newDepositRevealAheadPeriod;
        self.depositRevealAheadPeriodChangeInitiated = block.timestamp;
        emit DepositRevealAheadPeriodUpdateStarted(
            _newDepositRevealAheadPeriod,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the deposit reveal ahead period update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeDepositRevealAheadPeriodUpdate(
        DepositData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.depositRevealAheadPeriodChangeInitiated,
            governanceDelay
        )
    {
        emit DepositRevealAheadPeriodUpdated(self.newDepositRevealAheadPeriod);

        self.newDepositRevealAheadPeriod = 0;
        self.depositRevealAheadPeriodChangeInitiated = 0;
    }

    // --- Redemption

    /// @notice Begins the redemption dust threshold amount update process.
    /// @param _newRedemptionDustThreshold New redemption dust threshold amount.
    function beginRedemptionDustThresholdUpdate(
        RedemptionData storage self,
        uint64 _newRedemptionDustThreshold
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newRedemptionDustThreshold = _newRedemptionDustThreshold;
        self.redemptionDustThresholdChangeInitiated = block.timestamp;
        emit RedemptionDustThresholdUpdateStarted(
            _newRedemptionDustThreshold,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption dust threshold amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionDustThresholdUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionDustThresholdChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionDustThresholdUpdated(self.newRedemptionDustThreshold);

        self.newRedemptionDustThreshold = 0;
        self.redemptionDustThresholdChangeInitiated = 0;
    }

    /// @notice Begins the redemption treasury fee divisor amount update process.
    /// @param _newRedemptionTreasuryFeeDivisor New redemption treasury fee divisor
    ///         amount.
    function beginRedemptionTreasuryFeeDivisorUpdate(
        RedemptionData storage self,
        uint64 _newRedemptionTreasuryFeeDivisor
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newRedemptionTreasuryFeeDivisor = _newRedemptionTreasuryFeeDivisor;
        self.redemptionTreasuryFeeDivisorChangeInitiated = block.timestamp;
        emit RedemptionTreasuryFeeDivisorUpdateStarted(
            _newRedemptionTreasuryFeeDivisor,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption treasury fee divisor amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionTreasuryFeeDivisorUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionTreasuryFeeDivisorChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionTreasuryFeeDivisorUpdated(
            self.newRedemptionTreasuryFeeDivisor
        );

        self.newRedemptionTreasuryFeeDivisor = 0;
        self.redemptionTreasuryFeeDivisorChangeInitiated = 0;
    }

    /// @notice Begins the redemption tx max fee amount update process.
    /// @param _newRedemptionTxMaxFee New redemption tx max fee amount.
    function beginRedemptionTxMaxFeeUpdate(
        RedemptionData storage self,
        uint64 _newRedemptionTxMaxFee
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newRedemptionTxMaxFee = _newRedemptionTxMaxFee;
        self.redemptionTxMaxFeeChangeInitiated = block.timestamp;
        emit RedemptionTxMaxFeeUpdateStarted(
            _newRedemptionTxMaxFee,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption tx max fee amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionTxMaxFeeUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionTxMaxFeeChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionTxMaxFeeUpdated(self.newRedemptionTxMaxFee);

        self.newRedemptionTxMaxFee = 0;
        self.redemptionTxMaxFeeChangeInitiated = 0;
    }

    /// @notice Begins the redemption tx max total fee amount update process.
    /// @param _newRedemptionTxMaxTotalFee New redemption tx max total fee amount.
    function beginRedemptionTxMaxTotalFeeUpdate(
        RedemptionData storage self,
        uint64 _newRedemptionTxMaxTotalFee
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newRedemptionTxMaxTotalFee = _newRedemptionTxMaxTotalFee;
        self.redemptionTxMaxTotalFeeChangeInitiated = block.timestamp;
        emit RedemptionTxMaxTotalFeeUpdateStarted(
            _newRedemptionTxMaxTotalFee,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption tx max total fee amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionTxMaxTotalFeeUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionTxMaxTotalFeeChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionTxMaxTotalFeeUpdated(self.newRedemptionTxMaxTotalFee);

        self.newRedemptionTxMaxTotalFee = 0;
        self.redemptionTxMaxTotalFeeChangeInitiated = 0;
    }

    /// @notice Begins the redemption timeout amount update process.
    /// @param _newRedemptionTimeout New redemption timeout amount.
    function beginRedemptionTimeoutUpdate(
        RedemptionData storage self,
        uint32 _newRedemptionTimeout
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newRedemptionTimeout = _newRedemptionTimeout;
        self.redemptionTimeoutChangeInitiated = block.timestamp;
        emit RedemptionTimeoutUpdateStarted(
            _newRedemptionTimeout,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption timeout amount update
    ///         process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionTimeoutUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionTimeoutChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionTimeoutUpdated(self.newRedemptionTimeout);

        self.newRedemptionTimeout = 0;
        self.redemptionTimeoutChangeInitiated = 0;
    }

    /// @notice Begins the redemption timeout slashing amount update process.
    /// @param _newRedemptionTimeoutSlashingAmount New redemption timeout slashing
    ///         amount.
    function beginRedemptionTimeoutSlashingAmountUpdate(
        RedemptionData storage self,
        uint96 _newRedemptionTimeoutSlashingAmount
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newRedemptionTimeoutSlashingAmount = _newRedemptionTimeoutSlashingAmount;
        self.redemptionTimeoutSlashingAmountChangeInitiated = block.timestamp;
        emit RedemptionTimeoutSlashingAmountUpdateStarted(
            _newRedemptionTimeoutSlashingAmount,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption timeout slashing amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionTimeoutSlashingAmountUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionTimeoutSlashingAmountChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionTimeoutSlashingAmountUpdated(
            self.newRedemptionTimeoutSlashingAmount
        );

        self.newRedemptionTimeoutSlashingAmount = 0;
        self.redemptionTimeoutSlashingAmountChangeInitiated = 0;
    }

    /// @notice Begins the redemption timeout notifier reward multiplier amount
    ///         update process.
    /// @param _newRedemptionTimeoutNotifierRewardMultiplier New redemption
    ///         timeout notifier reward multiplier amount.
    function beginRedemptionTimeoutNotifierRewardMultiplierUpdate(
        RedemptionData storage self,
        uint32 _newRedemptionTimeoutNotifierRewardMultiplier
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newRedemptionTimeoutNotifierRewardMultiplier = _newRedemptionTimeoutNotifierRewardMultiplier;
        self.redemptionTimeoutNotifierRewardMultiplierChangeInitiated = block
            .timestamp;
        emit RedemptionTimeoutNotifierRewardMultiplierUpdateStarted(
            _newRedemptionTimeoutNotifierRewardMultiplier,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the redemption timeout notifier reward multiplier amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeRedemptionTimeoutNotifierRewardMultiplierUpdate(
        RedemptionData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.redemptionTimeoutNotifierRewardMultiplierChangeInitiated,
            governanceDelay
        )
    {
        emit RedemptionTimeoutNotifierRewardMultiplierUpdated(
            self.newRedemptionTimeoutNotifierRewardMultiplier
        );

        self.newRedemptionTimeoutNotifierRewardMultiplier = 0;
        self.redemptionTimeoutNotifierRewardMultiplierChangeInitiated = 0;
    }

    // --- Moving funds

    /// @notice Begins the moving funds tx max total fee amount update process.
    /// @param _newMovingFundsTxMaxTotalFee New moving funds tx max total fee amount.
    function beginMovingFundsTxMaxTotalFeeUpdate(
        MovingFundsData storage self,
        uint64 _newMovingFundsTxMaxTotalFee
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newMovingFundsTxMaxTotalFee = _newMovingFundsTxMaxTotalFee;
        self.movingFundsTxMaxTotalFeeChangeInitiated = block.timestamp;
        emit MovingFundsTxMaxTotalFeeUpdateStarted(
            _newMovingFundsTxMaxTotalFee,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds tx max total fee amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsTxMaxTotalFeeUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsTxMaxTotalFeeChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsTxMaxTotalFeeUpdated(self.newMovingFundsTxMaxTotalFee);

        self.newMovingFundsTxMaxTotalFee = 0;
        self.movingFundsTxMaxTotalFeeChangeInitiated = 0;
    }

    /// @notice Begins the moving funds dust threshold amount update process.
    /// @param _newMovingFundsDustThreshold New moving funds dust threshold amount.
    function beginMovingFundsDustThresholdUpdate(
        MovingFundsData storage self,
        uint64 _newMovingFundsDustThreshold
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newMovingFundsDustThreshold = _newMovingFundsDustThreshold;
        self.movingFundsDustThresholdChangeInitiated = block.timestamp;
        emit MovingFundsDustThresholdUpdateStarted(
            _newMovingFundsDustThreshold,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds dust threshold amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsDustThresholdUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsDustThresholdChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsDustThresholdUpdated(self.newMovingFundsDustThreshold);

        self.newMovingFundsDustThreshold = 0;
        self.movingFundsDustThresholdChangeInitiated = 0;
    }

    /// @notice Begins the moving funds timeout reset delay amount update process.
    /// @param _newMovingFundsTimeoutResetDelay New moving funds timeout reset
    ///         delay amount.
    function beginMovingFundsTimeoutResetDelayUpdate(
        MovingFundsData storage self,
        uint32 _newMovingFundsTimeoutResetDelay
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newMovingFundsTimeoutResetDelay = _newMovingFundsTimeoutResetDelay;
        self.movingFundsTimeoutResetDelayChangeInitiated = block.timestamp;
        emit MovingFundsTimeoutResetDelayUpdateStarted(
            _newMovingFundsTimeoutResetDelay,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds timeout reset delay amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsTimeoutResetDelayUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsTimeoutResetDelayChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsTimeoutResetDelayUpdated(
            self.newMovingFundsTimeoutResetDelay
        );

        self.newMovingFundsTimeoutResetDelay = 0;
        self.movingFundsTimeoutResetDelayChangeInitiated = 0;
    }

    /// @notice Begins the moving funds timeout amount update process.
    /// @param _newMovingFundsTimeout New moving funds timeout amount.
    function beginMovingFundsTimeoutUpdate(
        MovingFundsData storage self,
        uint32 _newMovingFundsTimeout
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newMovingFundsTimeout = _newMovingFundsTimeout;
        self.movingFundsTimeoutChangeInitiated = block.timestamp;
        emit MovingFundsTimeoutUpdateStarted(
            _newMovingFundsTimeout,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds timeout amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsTimeoutUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsTimeoutChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsTimeoutUpdated(self.newMovingFundsTimeout);

        self.newMovingFundsTimeout = 0;
        self.movingFundsTimeoutChangeInitiated = 0;
    }

    /// @notice Begins the moving funds timeout slashing amount update process.
    /// @param _newMovingFundsTimeoutSlashingAmount New moving funds timeout slashing amount.
    function beginMovingFundsTimeoutSlashingAmountUpdate(
        MovingFundsData storage self,
        uint96 _newMovingFundsTimeoutSlashingAmount
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newMovingFundsTimeoutSlashingAmount = _newMovingFundsTimeoutSlashingAmount;
        self.movingFundsTimeoutSlashingAmountChangeInitiated = block.timestamp;
        emit MovingFundsTimeoutSlashingAmountUpdateStarted(
            _newMovingFundsTimeoutSlashingAmount,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds timeout slashing amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsTimeoutSlashingAmountUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsTimeoutSlashingAmountChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsTimeoutSlashingAmountUpdated(
            self.newMovingFundsTimeoutSlashingAmount
        );

        self.newMovingFundsTimeoutSlashingAmount = 0;
        self.movingFundsTimeoutSlashingAmountChangeInitiated = 0;
    }

    /// @notice Begins the moving funds timeout notifier reward multiplier amount
    ///         update process.
    /// @param _newMovingFundsTimeoutNotifierRewardMultiplier New moving funds
    ///         timeout notifier reward multiplier amount.
    function beginMovingFundsTimeoutNotifierRewardMultiplierUpdate(
        MovingFundsData storage self,
        uint32 _newMovingFundsTimeoutNotifierRewardMultiplier
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newMovingFundsTimeoutNotifierRewardMultiplier = _newMovingFundsTimeoutNotifierRewardMultiplier;
        self.movingFundsTimeoutNotifierRewardMultiplierChangeInitiated = block
            .timestamp;
        emit MovingFundsTimeoutNotifierRewardMultiplierUpdateStarted(
            _newMovingFundsTimeoutNotifierRewardMultiplier,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds timeout notifier reward multiplier
    ///         amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsTimeoutNotifierRewardMultiplierUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsTimeoutNotifierRewardMultiplierChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsTimeoutNotifierRewardMultiplierUpdated(
            self.newMovingFundsTimeoutNotifierRewardMultiplier
        );

        self.newMovingFundsTimeoutNotifierRewardMultiplier = 0;
        self.movingFundsTimeoutNotifierRewardMultiplierChangeInitiated = 0;
    }

    /// @notice Begins the moving funds commitment gas offset update process.
    /// @param _newMovingFundsCommitmentGasOffset New moving funds commitment
    ///        gas offset.
    function beginMovingFundsCommitmentGasOffsetUpdate(
        MovingFundsData storage self,
        uint16 _newMovingFundsCommitmentGasOffset
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newMovingFundsCommitmentGasOffset = _newMovingFundsCommitmentGasOffset;
        self.movingFundsCommitmentGasOffsetChangeInitiated = block.timestamp;
        emit MovingFundsCommitmentGasOffsetUpdateStarted(
            _newMovingFundsCommitmentGasOffset,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moving funds commitment gas offset update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovingFundsCommitmentGasOffsetUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movingFundsCommitmentGasOffsetChangeInitiated,
            governanceDelay
        )
    {
        emit MovingFundsCommitmentGasOffsetUpdated(
            self.newMovingFundsCommitmentGasOffset
        );

        self.newMovingFundsCommitmentGasOffset = 0;
        self.movingFundsCommitmentGasOffsetChangeInitiated = 0;
    }

    /// @notice Begins the moved funds sweep tx max total fee amount update process.
    /// @param _newMovedFundsSweepTxMaxTotalFee New moved funds sweep tx max total
    ///         fee amount.
    function beginMovedFundsSweepTxMaxTotalFeeUpdate(
        MovingFundsData storage self,
        uint64 _newMovedFundsSweepTxMaxTotalFee
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newMovedFundsSweepTxMaxTotalFee = _newMovedFundsSweepTxMaxTotalFee;
        self.movedFundsSweepTxMaxTotalFeeChangeInitiated = block.timestamp;
        emit MovedFundsSweepTxMaxTotalFeeUpdateStarted(
            _newMovedFundsSweepTxMaxTotalFee,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moved funds sweep tx max total fee amount update
    ///         process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovedFundsSweepTxMaxTotalFeeUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movedFundsSweepTxMaxTotalFeeChangeInitiated,
            governanceDelay
        )
    {
        emit MovedFundsSweepTxMaxTotalFeeUpdated(
            self.newMovedFundsSweepTxMaxTotalFee
        );

        self.newMovedFundsSweepTxMaxTotalFee = 0;
        self.movedFundsSweepTxMaxTotalFeeChangeInitiated = 0;
    }

    /// @notice Begins the moved funds sweep timeout amount update process.
    /// @param _newMovedFundsSweepTimeout New moved funds sweep timeout amount.
    function beginMovedFundsSweepTimeoutUpdate(
        MovingFundsData storage self,
        uint32 _newMovedFundsSweepTimeout
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newMovedFundsSweepTimeout = _newMovedFundsSweepTimeout;
        self.movedFundsSweepTimeoutChangeInitiated = block.timestamp;
        emit MovedFundsSweepTimeoutUpdateStarted(
            _newMovedFundsSweepTimeout,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moved funds sweep timeout amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovedFundsSweepTimeoutUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movedFundsSweepTimeoutChangeInitiated,
            governanceDelay
        )
    {
        emit MovedFundsSweepTimeoutUpdated(self.newMovedFundsSweepTimeout);

        self.newMovedFundsSweepTimeout = 0;
        self.movedFundsSweepTimeoutChangeInitiated = 0;
    }

    /// @notice Begins the moved funds sweep timeout slashing amount update
    ///         process.
    /// @param _newMovedFundsSweepTimeoutSlashingAmount New moved funds sweep
    ///         timeout slashing amount.
    function beginMovedFundsSweepTimeoutSlashingAmountUpdate(
        MovingFundsData storage self,
        uint96 _newMovedFundsSweepTimeoutSlashingAmount
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newMovedFundsSweepTimeoutSlashingAmount = _newMovedFundsSweepTimeoutSlashingAmount;
        self.movedFundsSweepTimeoutSlashingAmountChangeInitiated = block
            .timestamp;
        emit MovedFundsSweepTimeoutSlashingAmountUpdateStarted(
            _newMovedFundsSweepTimeoutSlashingAmount,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moved funds sweep timeout slashing amount
    ///         update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovedFundsSweepTimeoutSlashingAmountUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movedFundsSweepTimeoutSlashingAmountChangeInitiated,
            governanceDelay
        )
    {
        emit MovedFundsSweepTimeoutSlashingAmountUpdated(
            self.newMovedFundsSweepTimeoutSlashingAmount
        );

        self.newMovedFundsSweepTimeoutSlashingAmount = 0;
        self.movedFundsSweepTimeoutSlashingAmountChangeInitiated = 0;
    }

    /// @notice Begins the moved funds sweep timeout notifier reward multiplier
    ///         amount update process.
    /// @param _newMovedFundsSweepTimeoutNotifierRewardMultiplier New moved funds
    ///         sweep timeout notifier reward multiplier amount.
    function beginMovedFundsSweepTimeoutNotifierRewardMultiplierUpdate(
        MovingFundsData storage self,
        uint32 _newMovedFundsSweepTimeoutNotifierRewardMultiplier
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newMovedFundsSweepTimeoutNotifierRewardMultiplier = _newMovedFundsSweepTimeoutNotifierRewardMultiplier;
        self
            .movedFundsSweepTimeoutNotifierRewardMultiplierChangeInitiated = block
            .timestamp;
        emit MovedFundsSweepTimeoutNotifierRewardMultiplierUpdateStarted(
            _newMovedFundsSweepTimeoutNotifierRewardMultiplier,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the moved funds sweep timeout notifier reward multiplier
    ///         amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeMovedFundsSweepTimeoutNotifierRewardMultiplierUpdate(
        MovingFundsData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.movedFundsSweepTimeoutNotifierRewardMultiplierChangeInitiated,
            governanceDelay
        )
    {
        emit MovedFundsSweepTimeoutNotifierRewardMultiplierUpdated(
            self.newMovedFundsSweepTimeoutNotifierRewardMultiplier
        );

        self.newMovedFundsSweepTimeoutNotifierRewardMultiplier = 0;
        self.movedFundsSweepTimeoutNotifierRewardMultiplierChangeInitiated = 0;
    }

    // --- Wallet params

    /// @notice Begins the wallet creation period amount update process.
    /// @param _newWalletCreationPeriod New wallet creation period amount.
    function beginWalletCreationPeriodUpdate(
        WalletData storage self,
        uint32 _newWalletCreationPeriod
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletCreationPeriod = _newWalletCreationPeriod;
        self.walletCreationPeriodChangeInitiated = block.timestamp;
        emit WalletCreationPeriodUpdateStarted(
            _newWalletCreationPeriod,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet creation period amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletCreationPeriodUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletCreationPeriodChangeInitiated,
            governanceDelay
        )
    {
        emit WalletCreationPeriodUpdated(self.newWalletCreationPeriod);

        self.newWalletCreationPeriod = 0;
        self.walletCreationPeriodChangeInitiated = 0;
    }

    /// @notice Begins the wallet creation min btc balance amount update process.
    /// @param _newWalletCreationMinBtcBalance New wallet creation min btc balance
    ///         amount.
    function beginWalletCreationMinBtcBalanceUpdate(
        WalletData storage self,
        uint64 _newWalletCreationMinBtcBalance
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletCreationMinBtcBalance = _newWalletCreationMinBtcBalance;
        self.walletCreationMinBtcBalanceChangeInitiated = block.timestamp;
        emit WalletCreationMinBtcBalanceUpdateStarted(
            _newWalletCreationMinBtcBalance,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet creation min btc balance amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletCreationMinBtcBalanceUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletCreationMinBtcBalanceChangeInitiated,
            governanceDelay
        )
    {
        emit WalletCreationMinBtcBalanceUpdated(
            self.newWalletCreationMinBtcBalance
        );

        self.newWalletCreationMinBtcBalance = 0;
        self.walletCreationMinBtcBalanceChangeInitiated = 0;
    }

    /// @notice Begins the wallet creation max btc balance amount update process.
    /// @param _newWalletCreationMaxBtcBalance New wallet creation max btc balance
    ///         amount.
    function beginWalletCreationMaxBtcBalanceUpdate(
        WalletData storage self,
        uint64 _newWalletCreationMaxBtcBalance
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletCreationMaxBtcBalance = _newWalletCreationMaxBtcBalance;
        self.walletCreationMaxBtcBalanceChangeInitiated = block.timestamp;
        emit WalletCreationMaxBtcBalanceUpdateStarted(
            _newWalletCreationMaxBtcBalance,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet creation max btc balance amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletCreationMaxBtcBalanceUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletCreationMaxBtcBalanceChangeInitiated,
            governanceDelay
        )
    {
        emit WalletCreationMaxBtcBalanceUpdated(
            self.newWalletCreationMaxBtcBalance
        );

        self.newWalletCreationMaxBtcBalance = 0;
        self.walletCreationMaxBtcBalanceChangeInitiated = 0;
    }

    /// @notice Begins the wallet closure min btc balance amount update process.
    /// @param _newWalletClosureMinBtcBalance New wallet closure min btc balance amount.
    function beginWalletClosureMinBtcBalanceUpdate(
        WalletData storage self,
        uint64 _newWalletClosureMinBtcBalance
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletClosureMinBtcBalance = _newWalletClosureMinBtcBalance;
        self.walletClosureMinBtcBalanceChangeInitiated = block.timestamp;
        emit WalletClosureMinBtcBalanceUpdateStarted(
            _newWalletClosureMinBtcBalance,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet closure min btc balance amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletClosureMinBtcBalanceUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletClosureMinBtcBalanceChangeInitiated,
            governanceDelay
        )
    {
        emit WalletClosureMinBtcBalanceUpdated(
            self.newWalletClosureMinBtcBalance
        );

        self.newWalletClosureMinBtcBalance = 0;
        self.walletClosureMinBtcBalanceChangeInitiated = 0;
    }

    /// @notice Begins the wallet max age amount update process.
    /// @param _newWalletMaxAge New wallet max age amount.
    function beginWalletMaxAgeUpdate(
        WalletData storage self,
        uint32 _newWalletMaxAge
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletMaxAge = _newWalletMaxAge;
        self.walletMaxAgeChangeInitiated = block.timestamp;
        emit WalletMaxAgeUpdateStarted(_newWalletMaxAge, block.timestamp);
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet max age amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletMaxAgeUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletMaxAgeChangeInitiated,
            governanceDelay
        )
    {
        emit WalletMaxAgeUpdated(self.newWalletMaxAge);

        self.newWalletMaxAge = 0;
        self.walletMaxAgeChangeInitiated = 0;
    }

    /// @notice Begins the wallet max btc transfer amount update process.
    /// @param _newWalletMaxBtcTransfer New wallet max btc transfer amount.
    function beginWalletMaxBtcTransferUpdate(
        WalletData storage self,
        uint64 _newWalletMaxBtcTransfer
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletMaxBtcTransfer = _newWalletMaxBtcTransfer;
        self.walletMaxBtcTransferChangeInitiated = block.timestamp;
        emit WalletMaxBtcTransferUpdateStarted(
            _newWalletMaxBtcTransfer,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet max btc transfer amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletMaxBtcTransferUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletMaxBtcTransferChangeInitiated,
            governanceDelay
        )
    {
        emit WalletMaxBtcTransferUpdated(self.newWalletMaxBtcTransfer);

        self.newWalletMaxBtcTransfer = 0;
        self.walletMaxBtcTransferChangeInitiated = 0;
    }

    /// @notice Begins the wallet closing period amount update process.
    /// @param _newWalletClosingPeriod New wallet closing period amount.
    function beginWalletClosingPeriodUpdate(
        WalletData storage self,
        uint32 _newWalletClosingPeriod
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newWalletClosingPeriod = _newWalletClosingPeriod;
        self.walletClosingPeriodChangeInitiated = block.timestamp;
        emit WalletClosingPeriodUpdateStarted(
            _newWalletClosingPeriod,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the wallet closing period amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeWalletClosingPeriodUpdate(
        WalletData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.walletClosingPeriodChangeInitiated,
            governanceDelay
        )
    {
        emit WalletClosingPeriodUpdated(self.newWalletClosingPeriod);

        self.newWalletClosingPeriod = 0;
        self.walletClosingPeriodChangeInitiated = 0;
    }

    // --- Fraud

    /// @notice Begins the fraud challenge deposit amount update process.
    /// @param _newFraudChallengeDepositAmount New fraud challenge deposit amount.
    function beginFraudChallengeDepositAmountUpdate(
        FraudData storage self,
        uint96 _newFraudChallengeDepositAmount
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newFraudChallengeDepositAmount = _newFraudChallengeDepositAmount;
        self.fraudChallengeDepositAmountChangeInitiated = block.timestamp;
        emit FraudChallengeDepositAmountUpdateStarted(
            _newFraudChallengeDepositAmount,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the fraud challenge deposit amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeFraudChallengeDepositAmountUpdate(
        FraudData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.fraudChallengeDepositAmountChangeInitiated,
            governanceDelay
        )
    {
        emit FraudChallengeDepositAmountUpdated(
            self.newFraudChallengeDepositAmount
        );

        self.newFraudChallengeDepositAmount = 0;
        self.fraudChallengeDepositAmountChangeInitiated = 0;
    }

    /// @notice Begins the fraud challenge defeat timeout amount update process.
    /// @param _newFraudChallengeDefeatTimeout New fraud challenge defeat timeout
    ///         amount.
    function beginFraudChallengeDefeatTimeoutUpdate(
        FraudData storage self,
        uint32 _newFraudChallengeDefeatTimeout
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newFraudChallengeDefeatTimeout = _newFraudChallengeDefeatTimeout;
        self.fraudChallengeDefeatTimeoutChangeInitiated = block.timestamp;
        emit FraudChallengeDefeatTimeoutUpdateStarted(
            _newFraudChallengeDefeatTimeout,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the fraud challenge defeat timeout amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeFraudChallengeDefeatTimeoutUpdate(
        FraudData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.fraudChallengeDefeatTimeoutChangeInitiated,
            governanceDelay
        )
    {
        emit FraudChallengeDefeatTimeoutUpdated(
            self.newFraudChallengeDefeatTimeout
        );

        self.newFraudChallengeDefeatTimeout = 0;
        self.fraudChallengeDefeatTimeoutChangeInitiated = 0;
    }

    /// @notice Begins the fraud slashing amount update process.
    /// @param _newFraudSlashingAmount New fraud slashing amount.
    function beginFraudSlashingAmountUpdate(
        FraudData storage self,
        uint96 _newFraudSlashingAmount
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newFraudSlashingAmount = _newFraudSlashingAmount;
        self.fraudSlashingAmountChangeInitiated = block.timestamp;
        emit FraudSlashingAmountUpdateStarted(
            _newFraudSlashingAmount,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the fraud slashing amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeFraudSlashingAmountUpdate(
        FraudData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.fraudSlashingAmountChangeInitiated,
            governanceDelay
        )
    {
        emit FraudSlashingAmountUpdated(self.newFraudSlashingAmount);

        self.newFraudSlashingAmount = 0;
        self.fraudSlashingAmountChangeInitiated = 0;
    }

    /// @notice Begins the fraud notifier reward multiplier amount update process.
    /// @param _newFraudNotifierRewardMultiplier New fraud notifier reward multiplier
    ///         amount.
    function beginFraudNotifierRewardMultiplierUpdate(
        FraudData storage self,
        uint32 _newFraudNotifierRewardMultiplier
    ) external {
        /* solhint-disable not-rely-on-time */
        self
            .newFraudNotifierRewardMultiplier = _newFraudNotifierRewardMultiplier;
        self.fraudNotifierRewardMultiplierChangeInitiated = block.timestamp;
        emit FraudNotifierRewardMultiplierUpdateStarted(
            _newFraudNotifierRewardMultiplier,
            block.timestamp
        );
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the fraud notifier reward multiplier amount update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeFraudNotifierRewardMultiplierUpdate(
        FraudData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(
            self.fraudNotifierRewardMultiplierChangeInitiated,
            governanceDelay
        )
    {
        emit FraudNotifierRewardMultiplierUpdated(
            self.newFraudNotifierRewardMultiplier
        );

        self.newFraudNotifierRewardMultiplier = 0;
        self.fraudNotifierRewardMultiplierChangeInitiated = 0;
    }

    /// @notice Begins the treasury address update process.
    /// @dev It does not perform any parameter validation.
    /// @param _newTreasury New treasury address.
    function beginTreasuryUpdate(
        TreasuryData storage self,
        address _newTreasury
    ) external {
        /* solhint-disable not-rely-on-time */
        self.newTreasury = _newTreasury;
        self.treasuryChangeInitiated = block.timestamp;
        emit TreasuryUpdateStarted(_newTreasury, block.timestamp);
        /* solhint-enable not-rely-on-time */
    }

    /// @notice Finalizes the treasury address update process.
    /// @dev Can be called after the governance delay elapses.
    function finalizeTreasuryUpdate(
        TreasuryData storage self,
        uint256 governanceDelay
    )
        external
        onlyAfterGovernanceDelay(self.treasuryChangeInitiated, governanceDelay)
    {
        emit TreasuryUpdated(self.newTreasury);

        self.newTreasury = address(0);
        self.treasuryChangeInitiated = 0;
    }
}