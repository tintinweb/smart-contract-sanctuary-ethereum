// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/openzeppelin/security/ReentrancyGuard.sol";
import "./storage/PoolStorage.sol";
import "./lib/WadRayMath.sol";
import "./utils/Pauseable.sol";

error CollateralDoesNotExist();
error SyntheticDoesNotExist();
error SenderIsNotDebtToken();
error PoolRegistryIsNull();
error DebtTokenAlreadyExists();
error SenderIsNotDepositToken();
error DepositTokenAlreadyExists();
error AmountIsZero();
error CanNotLiquidateOwnPosition();
error PositionIsHealthy();
error AmountGreaterThanMaxLiquidable();
error RemainingDebtIsLowerThanTheFloor();
error AmountIsTooHight();
error DebtTokenDoesNotExist();
error DepositTokenDoesNotExist();
error SwapFeatureIsInactive();
error AmountInIsInvalid();
error AddressIsNull();
error SyntheticIsNull();
error SyntheticIsInUse();
error UnderlyingAssetInUse();
error RewardDistributorAlreadyExists();
error RewardDistributorDoesNotExist();
error TotalSupplyIsNotZero();
error NewValueIsSameAsCurrent();
error FeeIsGreaterThanTheMax();
error MaxLiquidableTooHigh();

/**
 * @title Pool contract
 */
contract Pool is ReentrancyGuard, Pauseable, PoolStorageV1 {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    using MappedEnumerableSet for MappedEnumerableSet.AddressSet;

    string public constant VERSION = "1.0.0";
    uint256 internal constant MAX_FEE_VALUE = 0.25e18; // 25%

    /// @notice Emitted when protocol liquidation fee is updated
    event DebtFloorUpdated(uint256 oldDebtFloorInUsd, uint256 newDebtFloorInUsd);

    /// @notice Emitted when debt token is enabled
    event DebtTokenAdded(IDebtToken indexed debtToken);

    /// @notice Emitted when debt token is disabled
    event DebtTokenRemoved(IDebtToken indexed debtToken);

    /// @notice Emitted when deposit fee is updated
    event DepositFeeUpdated(uint256 oldDepositFee, uint256 newDepositFee);

    /// @notice Emitted when deposit token is enabled
    event DepositTokenAdded(address indexed depositToken);

    /// @notice Emitted when deposit token is disabled
    event DepositTokenRemoved(IDepositToken indexed depositToken);

    /// @notice Emitted when issue fee is updated
    event IssueFeeUpdated(uint256 oldIssueFee, uint256 newIssueFee);

    /// @notice Emitted when liquidator incentive is updated
    event LiquidatorIncentiveUpdated(uint256 oldLiquidatorIncentive, uint256 newLiquidatorIncentive);

    /// @notice Emitted when maxLiquidable (liquidation cap) is updated
    event MaxLiquidableUpdated(uint256 oldMaxLiquidable, uint256 newMaxLiquidable);

    /// @notice Emitted when a position is liquidated
    event PositionLiquidated(
        address indexed liquidator,
        address indexed account,
        ISyntheticToken indexed syntheticToken,
        uint256 amountRepaid,
        uint256 depositSeized,
        uint256 fee
    );

    /// @notice Emitted when protocol liquidation fee is updated
    event ProtocolLiquidationFeeUpdated(uint256 oldProtocolLiquidationFee, uint256 newProtocolLiquidationFee);

    /// @notice Emitted when repay fee is updated
    event RepayFeeUpdated(uint256 oldRepayFee, uint256 newRepayFee);

    /// @notice Emitted when rewards distributor contract is added
    event RewardsDistributorAdded(IRewardsDistributor indexed _distributor);

    /// @notice Emitted when rewards distributor contract is removed
    event RewardsDistributorRemoved(IRewardsDistributor _distributor);

    /// @notice Emitted when swap fee is updated
    event SwapFeeUpdated(uint256 oldSwapFee, uint256 newSwapFee);

    /// @notice Emitted when the swap active flag is updated
    event SwapActiveUpdated(bool newActive);

    /// @notice Emitted when synthetic token is swapped
    event SyntheticTokenSwapped(
        address indexed account,
        ISyntheticToken indexed syntheticTokenIn,
        ISyntheticToken indexed syntheticTokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 fee
    );

    /// @notice Emitted when treasury contract is updated
    event TreasuryUpdated(ITreasury indexed oldTreasury, ITreasury indexed newTreasury);

    /// @notice Emitted when withdraw fee is updated
    event WithdrawFeeUpdated(uint256 oldWithdrawFee, uint256 newWithdrawFee);

    /**
     * @dev Throws if deposit token doesn't exist
     */
    modifier onlyIfDepositTokenExists(IDepositToken depositToken_) {
        if (!doesDepositTokenExist(depositToken_)) revert CollateralDoesNotExist();
        _;
    }

    /**
     * @dev Throws if synthetic token doesn't exist
     */
    modifier onlyIfSyntheticTokenExists(ISyntheticToken syntheticToken_) {
        if (!doesSyntheticTokenExist(syntheticToken_)) revert SyntheticDoesNotExist();
        _;
    }

    /**
     * @dev Throws if `msg.sender` isn't a debt token
     */
    modifier onlyIfMsgSenderIsDebtToken() {
        if (!doesDebtTokenExist(IDebtToken(msg.sender))) revert SenderIsNotDebtToken();
        _;
    }

    function initialize(IPoolRegistry poolRegistry_) public initializer {
        if (address(poolRegistry_) == address(0)) revert PoolRegistryIsNull();
        __ReentrancyGuard_init();
        __Pauseable_init();

        poolRegistry = poolRegistry_;
        isSwapActive = true;

        repayFee = 3e15; // 0.3%
        liquidationFees = LiquidationFees({
            liquidatorIncentive: 1e17, // 10%
            protocolFee: 8e16 // 8%
        });
        maxLiquidable = 0.5e18; // 50%
        swapFee = 6e15; // 0.6%
    }

    /**
     * @notice Add a debt token to the per-account list
     * @dev This function is called from `DebtToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDebtTokensOfAccount(address account_) external onlyIfMsgSenderIsDebtToken {
        if (!debtTokensOfAccount.add(account_, msg.sender)) revert DebtTokenAlreadyExists();
    }

    /**
     * @notice Add a deposit token to the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes from `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function addToDepositTokensOfAccount(address account_) external {
        if (!depositTokens.contains(msg.sender)) revert SenderIsNotDepositToken();
        if (!depositTokensOfAccount.add(account_, msg.sender)) revert DepositTokenAlreadyExists();
    }

    /**
     * @notice Get account's debt by querying latest prices from oracles
     * @param account_ The account to check
     * @return _debtInUsd The debt value in USD
     */
    function debtOf(address account_) public view override returns (uint256 _debtInUsd) {
        IMasterOracle _masterOracle = masterOracle();
        uint256 _length = debtTokensOfAccount.length(account_);
        for (uint256 i; i < _length; ++i) {
            IDebtToken _debtToken = IDebtToken(debtTokensOfAccount.at(account_, i));
            _debtInUsd += _masterOracle.quoteTokenToUsd(
                address(_debtToken.syntheticToken()),
                _debtToken.balanceOf(account_)
            );
        }
    }

    /**
     * @notice Returns whether the debt position from an account is healthy
     * @param account_ The account to check
     * @return _isHealthy Whether the account's position is healthy
     * @return _depositInUsd The total collateral deposited in USD
     * @return _debtInUsd The total debt in USD
     * @return _issuableLimitInUsd The max amount of debt (is USD) that can be created (considering collateral factors)
     * @return _issuableInUsd The amount of debt (is USD) that is free (i.e. can be used to issue synthetic tokens)
     */
    function debtPositionOf(address account_)
        public
        view
        override
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        )
    {
        _debtInUsd = debtOf(account_);
        (_depositInUsd, _issuableLimitInUsd) = depositOf(account_);
        _isHealthy = _debtInUsd <= _issuableLimitInUsd;
        _issuableInUsd = _debtInUsd < _issuableLimitInUsd ? _issuableLimitInUsd - _debtInUsd : 0;
    }

    /**
     * @notice Get account's total collateral deposited by querying latest prices from oracles
     * @param account_ The account to check
     * @return _depositInUsd The total deposit value in USD among all collaterals
     * @return _issuableLimitInUsd The max value in USD that can be used to issue synthetic tokens
     */
    function depositOf(address account_)
        public
        view
        override
        returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd)
    {
        IMasterOracle _masterOracle = masterOracle();
        uint256 _length = depositTokensOfAccount.length(account_);
        for (uint256 i; i < _length; ++i) {
            IDepositToken _depositToken = IDepositToken(depositTokensOfAccount.at(account_, i));
            uint256 _amountInUsd = _masterOracle.quoteTokenToUsd(
                address(_depositToken.underlying()),
                _depositToken.balanceOf(account_)
            );
            _depositInUsd += _amountInUsd;
            _issuableLimitInUsd += _amountInUsd.wadMul(_depositToken.collateralFactor());
        }
    }

    /**
     * @inheritdoc Pauseable
     */
    function everythingStopped() public view override(IPauseable, Pauseable) returns (bool) {
        return super.everythingStopped() || poolRegistry.everythingStopped();
    }

    /**
     * @notice Returns fee collector address
     */
    function feeCollector() external view override returns (address) {
        return poolRegistry.feeCollector();
    }

    /**
     * @notice Get all debt tokens
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDebtTokens() external view override returns (address[] memory) {
        return debtTokens.values();
    }

    /**
     * @notice Get all debt tokens
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDebtTokensOfAccount(address account_) external view override returns (address[] memory) {
        return debtTokensOfAccount.values(account_);
    }

    /**
     * @notice Get all deposit tokens
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDepositTokens() external view override returns (address[] memory) {
        return depositTokens.values();
    }

    /**
     * @notice Get deposit tokens of an account
     * @dev WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees.
     */
    function getDepositTokensOfAccount(address account_) external view override returns (address[] memory) {
        return depositTokensOfAccount.values(account_);
    }

    /**
     * @notice Get all rewards distributors
     */
    function getRewardsDistributors() external view override returns (IRewardsDistributor[] memory) {
        return rewardsDistributors;
    }

    /**
     * @notice Check if token is part of the debt offerings
     * @param debtToken_ Asset to check
     * @return true if exist
     */
    function doesDebtTokenExist(IDebtToken debtToken_) public view override returns (bool) {
        return debtTokens.contains(address(debtToken_));
    }

    /**
     * @notice Check if collateral is supported
     * @param depositToken_ Asset to check
     * @return true if exist
     */
    function doesDepositTokenExist(IDepositToken depositToken_) public view override returns (bool) {
        return depositTokens.contains(address(depositToken_));
    }

    /**
     * @notice Check if token is part of the synthetic offerings
     * @param syntheticToken_ Asset to check
     * @return true if exist
     */
    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) public view override returns (bool) {
        return address(debtTokenOf[syntheticToken_]) != address(0);
    }

    /**
     * @notice Quote synth  `_amountToRepay` in order to seize `totalToSeized_`
     * @param syntheticToken_ Synth for repayment
     * @param totalToSeize_ Collateral total amount to size
     * @param depositToken_ Collateral's deposit token
     * @return _amountToRepay Synth amount to burn
     * @return _toLiquidator Seized amount to the liquidator
     * @return _fee The fee amount to collect
     */
    function quoteLiquidateIn(
        ISyntheticToken syntheticToken_,
        uint256 totalToSeize_,
        IDepositToken depositToken_
    )
        public
        view
        override
        returns (
            uint256 _amountToRepay,
            uint256 _toLiquidator,
            uint256 _fee
        )
    {
        LiquidationFees memory _fees = liquidationFees;
        uint256 _totalFees = _fees.protocolFee + _fees.liquidatorIncentive;
        uint256 _repayAmountInCollateral = totalToSeize_;

        if (_totalFees > 0) {
            _repayAmountInCollateral = _repayAmountInCollateral.wadDiv(1e18 + _totalFees);
        }

        _amountToRepay = masterOracle().quote(
            address(depositToken_.underlying()),
            address(syntheticToken_),
            _repayAmountInCollateral
        );

        if (_fees.protocolFee > 0) {
            _fee = _repayAmountInCollateral.wadMul(_fees.protocolFee);
        }

        if (_fees.liquidatorIncentive > 0) {
            _toLiquidator = _repayAmountInCollateral.wadMul(1e18 + _fees.liquidatorIncentive);
        }
    }

    /**
     * @notice Quote max allowed synth to repay
     * @dev I.e. Considers the min amount between collateral's balance and `maxLiquidable` param
     * @param syntheticToken_ Synth for repayment
     * @param account_ The account to liquidate
     * @param depositToken_ Collateral's deposit token
     * @return _maxAmountToRepay Synth amount to burn
     */
    function quoteLiquidateMax(
        ISyntheticToken syntheticToken_,
        address account_,
        IDepositToken depositToken_
    ) external view override returns (uint256 _maxAmountToRepay) {
        (bool _isHealthy, , , , ) = debtPositionOf(account_);
        if (_isHealthy) {
            return 0;
        }

        (uint256 _amountToRepay, , ) = quoteLiquidateIn(
            syntheticToken_,
            depositToken_.balanceOf(account_),
            depositToken_
        );

        _maxAmountToRepay = debtTokenOf[syntheticToken_].balanceOf(account_).wadMul(maxLiquidable);

        if (_amountToRepay < _maxAmountToRepay) {
            _maxAmountToRepay = _amountToRepay;
        }
    }

    /**
     * @notice Quote collateral  `totalToSeized_` by repaying `amountToRepay_`
     * @param syntheticToken_ Synth for repayment
     * @param amountToRepay_ Synth amount to burn
     * @param depositToken_ Collateral's deposit token
     * @return _totalToSeize Collateral total amount to size
     * @return _toLiquidator Seized amount to the liquidator
     * @return _fee The fee amount to collect
     */
    function quoteLiquidateOut(
        ISyntheticToken syntheticToken_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        public
        view
        override
        returns (
            uint256 _totalToSeize,
            uint256 _toLiquidator,
            uint256 _fee
        )
    {
        _toLiquidator = masterOracle().quote(
            address(syntheticToken_),
            address(depositToken_.underlying()),
            amountToRepay_
        );

        LiquidationFees memory _fees = liquidationFees;

        if (_fees.protocolFee > 0) {
            _fee = _toLiquidator.wadMul(_fees.protocolFee);
        }
        if (_fees.liquidatorIncentive > 0) {
            _toLiquidator += _toLiquidator.wadMul(_fees.liquidatorIncentive);
        }

        _totalToSeize = _fee + _toLiquidator;
    }

    /**
     * @notice Quote `_amountIn` to get `amountOut_`
     * @param syntheticTokenIn_ Synth in
     * @param syntheticTokenOut_ Synth out
     * @param amountOut_ Amount out
     * @return _amountIn Amount in
     * @return _fee Fee to charge in `syntheticTokenOut_`
     */
    function quoteSwapIn(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountOut_
    ) external view override returns (uint256 _amountIn, uint256 _fee) {
        uint256 _swapFee = swapFee;
        if (_swapFee > 0) {
            amountOut_ = amountOut_.wadDiv(1e18 - _swapFee);
            _fee = amountOut_.wadMul(_swapFee);
        }

        _amountIn = poolRegistry.masterOracle().quote(
            address(syntheticTokenOut_),
            address(syntheticTokenIn_),
            amountOut_
        );
    }

    /**
     * @notice Quote `amountOut_` get from `amountIn_`
     * @param syntheticTokenIn_ Synth in
     * @param syntheticTokenOut_ Synth out
     * @param amountIn_ Amount in
     * @return _amountOut Amount out
     * @return _fee Fee to charge in `syntheticTokenOut_`
     */
    function quoteSwapOut(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) public view override returns (uint256 _amountOut, uint256 _fee) {
        _amountOut = poolRegistry.masterOracle().quote(
            address(syntheticTokenIn_),
            address(syntheticTokenOut_),
            amountIn_
        );

        uint256 _swapFee = swapFee;
        if (_swapFee > 0) {
            _fee = _amountOut.wadMul(_swapFee);
            _amountOut -= _fee;
        }
    }

    /**
     * @notice Burn synthetic token, unlock deposit token and send liquidator incentive
     * @param syntheticToken_ The msAsset to use for repayment
     * @param account_ The account with an unhealthy position
     * @param amountToRepay_ The amount to repay in synthetic token
     * @param depositToken_ The collateral to seize from
     * @return _totalSeized Total deposit amount seized from the liquidated account
     * @return _toLiquidator Share of `_totalSeized` sent to the liquidator
     * @return _fee Share of `_totalSeized` collected as fee
     */
    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfDepositTokenExists(depositToken_)
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        )
    {
        if (amountToRepay_ == 0) revert AmountIsZero();
        if (msg.sender == account_) revert CanNotLiquidateOwnPosition();

        IDebtToken _debtToken = debtTokenOf[syntheticToken_];
        _debtToken.accrueInterest();

        (bool _isHealthy, , , , ) = debtPositionOf(account_);

        if (_isHealthy) {
            revert PositionIsHealthy();
        }

        uint256 _debtTokenBalance = _debtToken.balanceOf(account_);

        if (amountToRepay_.wadDiv(_debtTokenBalance) > maxLiquidable) {
            revert AmountGreaterThanMaxLiquidable();
        }

        IMasterOracle _masterOracle = masterOracle();

        if (debtFloorInUsd > 0) {
            uint256 _newDebtInUsd = _masterOracle.quoteTokenToUsd(
                address(syntheticToken_),
                _debtTokenBalance - amountToRepay_
            );
            if (_newDebtInUsd > 0 && _newDebtInUsd < debtFloorInUsd) {
                revert RemainingDebtIsLowerThanTheFloor();
            }
        }

        (_totalSeized, _toLiquidator, _fee) = quoteLiquidateOut(syntheticToken_, amountToRepay_, depositToken_);

        if (_totalSeized > depositToken_.balanceOf(account_)) {
            revert AmountIsTooHight();
        }

        syntheticToken_.burn(msg.sender, amountToRepay_);
        _debtToken.burn(account_, amountToRepay_);
        depositToken_.seize(account_, msg.sender, _toLiquidator);

        if (_fee > 0) {
            depositToken_.seize(account_, poolRegistry.feeCollector(), _fee);
        }

        emit PositionLiquidated(msg.sender, account_, syntheticToken_, amountToRepay_, _totalSeized, _fee);
    }

    /**
     * @notice Get MasterOracle contract
     */
    function masterOracle() public view override returns (IMasterOracle) {
        return poolRegistry.masterOracle();
    }

    /**
     * @inheritdoc Pauseable
     */
    function paused() public view override(IPauseable, Pauseable) returns (bool) {
        return super.paused() || poolRegistry.paused();
    }

    /**
     * @notice Remove a debt token from the per-account list
     * @dev This function is called from `DebtToken` when user's balance changes to `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function removeFromDebtTokensOfAccount(address account_) external onlyIfMsgSenderIsDebtToken {
        if (!debtTokensOfAccount.remove(account_, msg.sender)) revert DebtTokenDoesNotExist();
    }

    /**
     * @notice Remove a deposit token from the per-account list
     * @dev This function is called from `DepositToken` when user's balance changes to `0`
     * @dev The caller should ensure to not pass `address(0)` as `_account`
     * @param account_ The account address
     */
    function removeFromDepositTokensOfAccount(address account_) external {
        if (!depositTokens.contains(msg.sender)) revert SenderIsNotDepositToken();
        if (!depositTokensOfAccount.remove(account_, msg.sender)) revert DepositTokenDoesNotExist();
    }

    /**
     * @notice Swap synthetic tokens
     * @param syntheticTokenIn_ Synthetic token to sell
     * @param syntheticTokenOut_ Synthetic token to buy
     * @param amountIn_ Amount to swap
     */
    function swap(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    )
        external
        override
        whenNotShutdown
        nonReentrant
        onlyIfSyntheticTokenExists(syntheticTokenIn_)
        onlyIfSyntheticTokenExists(syntheticTokenOut_)
        returns (uint256 _amountOut, uint256 _fee)
    {
        if (!isSwapActive) revert SwapFeatureIsInactive();
        if (amountIn_ == 0 || amountIn_ > syntheticTokenIn_.balanceOf(msg.sender)) revert AmountInIsInvalid();

        syntheticTokenIn_.burn(msg.sender, amountIn_);

        (_amountOut, _fee) = quoteSwapOut(syntheticTokenIn_, syntheticTokenOut_, amountIn_);

        if (_fee > 0) {
            syntheticTokenOut_.mint(poolRegistry.feeCollector(), _fee);
        }

        syntheticTokenOut_.mint(msg.sender, _amountOut);

        emit SyntheticTokenSwapped(msg.sender, syntheticTokenIn_, syntheticTokenOut_, amountIn_, _amountOut, _fee);
    }

    /**
     * @notice Add debt token to offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function addDebtToken(IDebtToken debtToken_) external override onlyGovernor {
        if (address(debtToken_) == address(0)) revert AddressIsNull();
        ISyntheticToken _syntheticToken = debtToken_.syntheticToken();
        if (address(_syntheticToken) == address(0)) revert SyntheticIsNull();
        if (address(debtTokenOf[_syntheticToken]) != address(0)) revert SyntheticIsInUse();

        if (!debtTokens.add(address(debtToken_))) revert DebtTokenAlreadyExists();

        debtTokenOf[_syntheticToken] = debtToken_;

        emit DebtTokenAdded(debtToken_);
    }

    /**
     * @notice Add deposit token (i.e. collateral) to Synth
     */
    function addDepositToken(address depositToken_) external override onlyGovernor {
        if (depositToken_ == address(0)) revert AddressIsNull();
        IERC20 _underlying = IDepositToken(depositToken_).underlying();
        if (address(depositTokenOf[_underlying]) != address(0)) revert UnderlyingAssetInUse();

        if (!depositTokens.add(depositToken_)) revert DepositTokenAlreadyExists();

        depositTokenOf[_underlying] = IDepositToken(depositToken_);

        emit DepositTokenAdded(depositToken_);
    }

    /**
     * @notice Add a RewardsDistributor contract
     */
    function addRewardsDistributor(IRewardsDistributor distributor_) external override onlyGovernor {
        if (address(distributor_) == address(0)) revert AddressIsNull();

        uint256 _length = rewardsDistributors.length;
        for (uint256 i; i < _length; ++i) {
            if (distributor_ == rewardsDistributors[i]) {
                revert RewardDistributorAlreadyExists();
            }
        }

        rewardsDistributors.push(distributor_);
        emit RewardsDistributorAdded(distributor_);
    }

    /**
     * @notice Remove debt token from offerings
     * @dev Must keep `debtTokenOf` mapping updated
     */
    function removeDebtToken(IDebtToken debtToken_) external override onlyGovernor {
        if (debtToken_.totalSupply() > 0) revert TotalSupplyIsNotZero();
        if (!debtTokens.remove(address(debtToken_))) revert DebtTokenDoesNotExist();

        delete debtTokenOf[debtToken_.syntheticToken()];

        emit DebtTokenRemoved(debtToken_);
    }

    /**
     * @notice Remove deposit token (i.e. collateral) from Synth
     */
    function removeDepositToken(IDepositToken depositToken_) external override onlyGovernor {
        if (depositToken_.totalSupply() > 0) revert TotalSupplyIsNotZero();

        if (!depositTokens.remove(address(depositToken_))) revert DepositTokenDoesNotExist();
        delete depositTokenOf[depositToken_.underlying()];

        emit DepositTokenRemoved(depositToken_);
    }

    /**
     * @notice Remove a RewardsDistributor contract
     */
    function removeRewardsDistributor(IRewardsDistributor distributor_) external override onlyGovernor {
        if (address(distributor_) == address(0)) revert AddressIsNull();

        uint256 _length = rewardsDistributors.length;
        uint256 _index = _length;
        for (uint256 i; i < _length; ++i) {
            if (rewardsDistributors[i] == distributor_) {
                _index = i;
                break;
            }
        }
        if (_index == _length) revert RewardDistributorDoesNotExist();
        if (_index != _length - 1) {
            rewardsDistributors[_index] = rewardsDistributors[_length - 1];
        }
        rewardsDistributors.pop();

        emit RewardsDistributorRemoved(distributor_);
    }

    /**
     * @notice Turn swap on/off
     */
    function toggleIsSwapActive() external override onlyGovernor {
        bool _newIsSwapActive = !isSwapActive;
        emit SwapActiveUpdated(_newIsSwapActive);
        isSwapActive = _newIsSwapActive;
    }

    /**
     * @notice Update debt floor
     */
    function updateDebtFloor(uint256 newDebtFloorInUsd_) external override onlyGovernor {
        uint256 _currentDebtFloorInUsd = debtFloorInUsd;
        if (newDebtFloorInUsd_ == _currentDebtFloorInUsd) revert NewValueIsSameAsCurrent();
        emit DebtFloorUpdated(_currentDebtFloorInUsd, newDebtFloorInUsd_);
        debtFloorInUsd = newDebtFloorInUsd_;
    }

    /**
     * @notice Update deposit fee
     */
    function updateDepositFee(uint256 newDepositFee_) external override onlyGovernor {
        if (newDepositFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentDepositFee = depositFee;
        if (newDepositFee_ == _currentDepositFee) revert NewValueIsSameAsCurrent();
        emit DepositFeeUpdated(_currentDepositFee, newDepositFee_);
        depositFee = newDepositFee_;
    }

    /**
     * @notice Update issue fee
     */
    function updateIssueFee(uint256 newIssueFee_) external override onlyGovernor {
        if (newIssueFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentIssueFee = issueFee;
        if (newIssueFee_ == _currentIssueFee) revert NewValueIsSameAsCurrent();
        emit IssueFeeUpdated(_currentIssueFee, newIssueFee_);
        issueFee = newIssueFee_;
    }

    /**
     * @notice Update liquidator incentive
     */
    function updateLiquidatorIncentive(uint128 newLiquidatorIncentive_) external override onlyGovernor {
        if (newLiquidatorIncentive_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentLiquidatorIncentive = liquidationFees.liquidatorIncentive;
        if (newLiquidatorIncentive_ == _currentLiquidatorIncentive) revert NewValueIsSameAsCurrent();
        emit LiquidatorIncentiveUpdated(_currentLiquidatorIncentive, newLiquidatorIncentive_);
        liquidationFees.liquidatorIncentive = newLiquidatorIncentive_;
    }

    /**
     * @notice Update maxLiquidable (liquidation cap)
     */
    function updateMaxLiquidable(uint256 newMaxLiquidable_) external override onlyGovernor {
        if (newMaxLiquidable_ > 1e18) revert MaxLiquidableTooHigh();
        uint256 _currentMaxLiquidable = maxLiquidable;
        if (newMaxLiquidable_ == _currentMaxLiquidable) revert NewValueIsSameAsCurrent();
        emit MaxLiquidableUpdated(_currentMaxLiquidable, newMaxLiquidable_);
        maxLiquidable = newMaxLiquidable_;
    }

    /**
     * @notice Update protocol liquidation fee
     */
    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external override onlyGovernor {
        if (newProtocolLiquidationFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentProtocolLiquidationFee = liquidationFees.protocolFee;
        if (newProtocolLiquidationFee_ == _currentProtocolLiquidationFee) revert NewValueIsSameAsCurrent();
        emit ProtocolLiquidationFeeUpdated(_currentProtocolLiquidationFee, newProtocolLiquidationFee_);
        liquidationFees.protocolFee = newProtocolLiquidationFee_;
    }

    /**
     * @notice Update repay fee
     */
    function updateRepayFee(uint256 newRepayFee_) external override onlyGovernor {
        if (newRepayFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentRepayFee = repayFee;
        if (newRepayFee_ == _currentRepayFee) revert NewValueIsSameAsCurrent();
        emit RepayFeeUpdated(_currentRepayFee, newRepayFee_);
        repayFee = newRepayFee_;
    }

    /**
     * @notice Update treasury contract - will migrate funds to the new contract
     */
    function updateTreasury(ITreasury newTreasury_) external override onlyGovernor {
        if (address(newTreasury_) == address(0)) revert AddressIsNull();
        ITreasury _currentTreasury = treasury;
        if (newTreasury_ == _currentTreasury) revert NewValueIsSameAsCurrent();

        if (address(_currentTreasury) != address(0)) {
            _currentTreasury.migrateTo(address(newTreasury_));
        }

        emit TreasuryUpdated(_currentTreasury, newTreasury_);
        treasury = newTreasury_;
    }

    /**
     * @notice Update swap fee
     */
    function updateSwapFee(uint256 newSwapFee_) external override onlyGovernor {
        if (newSwapFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentSwapFee = swapFee;
        if (newSwapFee_ == _currentSwapFee) revert NewValueIsSameAsCurrent();
        emit SwapFeeUpdated(_currentSwapFee, newSwapFee_);
        swapFee = newSwapFee_;
    }

    /**
     * @notice Update withdraw fee
     */
    function updateWithdrawFee(uint256 newWithdrawFee_) external override onlyGovernor {
        if (newWithdrawFee_ > MAX_FEE_VALUE) revert FeeIsGreaterThanTheMax();
        uint256 _currentWithdrawFee = withdrawFee;
        if (newWithdrawFee_ == _currentWithdrawFee) revert NewValueIsSameAsCurrent();
        emit WithdrawFeeUpdated(_currentWithdrawFee, newWithdrawFee_);
        withdrawFee = newWithdrawFee_;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/proxy/utils/Initializable.sol";
import "../utils/TokenHolder.sol";
import "../interfaces/IGovernable.sol";

error SenderIsNotGovernor();
error ProposedGovernorIsNull();
error SenderIsNotTheProposedGovernor();

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, TokenHolder, Initializable {
    /**
     * @notice The governor
     * @dev By default the contract deployer is the initial governor
     */
    address public governor;

    /**
     * @notice The proposed governor
     * @dev It will be empty (address(0)) if there isn't a proposed governor
     */
    address public proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    constructor() {
        governor = msg.sender;
        emit UpdatedGovernor(address(0), msg.sender);
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal initializer {
        governor = msg.sender;
        emit UpdatedGovernor(address(0), msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        if (governor != msg.sender) revert SenderIsNotGovernor();
        _;
    }

    /// @inheritdoc TokenHolder
    function _requireCanSweep() internal view override onlyGovernor {}

    /**
     * @notice Transfers governorship of the contract to a new account (`proposedGovernor`).
     * @dev Can only be called by the current owner.
     * @param proposedGovernor_ The new proposed governor
     */
    function transferGovernorship(address proposedGovernor_) external onlyGovernor {
        if (proposedGovernor_ == address(0)) revert ProposedGovernorIsNull();
        proposedGovernor = proposedGovernor_;
    }

    /**
     * @notice Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        address _proposedGovernor = proposedGovernor;
        if (msg.sender != _proposedGovernor) revert SenderIsNotTheProposedGovernor();
        emit UpdatedGovernor(governor, _proposedGovernor);
        governor = _proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuard is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
 */
library EnumerableSet {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISyntheticToken.sol";

interface IDebtToken is IERC20Metadata {
    function lastTimestampAccrued() external view returns (uint256);

    function isActive() external view returns (bool);

    function syntheticToken() external view returns (ISyntheticToken);

    function accrueInterest() external;

    function debtIndex() external returns (uint256 debtIndex_);

    function burn(address from_, uint256 amount_) external;

    function issue(uint256 amount_, address to_) external returns (uint256 _issued, uint256 _fee);

    function repay(address onBehalfOf_, uint256 amount_) external returns (uint256 _repaid, uint256 _fee);

    function repayAll(address onBehalfOf_) external returns (uint256 _repaid, uint256 _fee);

    function quoteIssueIn(uint256 amountToIssue_) external view returns (uint256 _amount, uint256 _fee);

    function quoteIssueOut(uint256 amount_) external view returns (uint256 _amountToIssue, uint256 _fee);

    function quoteRepayIn(uint256 amountToRepay_) external view returns (uint256 _amount, uint256 _fee);

    function quoteRepayOut(uint256 amount_) external view returns (uint256 _amountToRepay, uint256 _fee);

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;

    function updateInterestRate(uint256 newInterestRate_) external;

    function maxTotalSupply() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function interestRatePerSecond() external view returns (uint256);

    function toggleIsActive() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

interface IDepositToken is IERC20Metadata {
    function underlying() external view returns (IERC20);

    function collateralFactor() external view returns (uint256);

    function unlockedBalanceOf(address account_) external view returns (uint256);

    function lockedBalanceOf(address account_) external view returns (uint256);

    function deposit(uint256 amount_, address onBehalfOf_) external returns (uint256 _deposited, uint256 _fee);

    function quoteDepositIn(uint256 amountToDeposit_) external view returns (uint256 _amount, uint256 _fee);

    function quoteDepositOut(uint256 amount_) external view returns (uint256 _amountToDeposit, uint256 _fee);

    function quoteWithdrawIn(uint256 amountToWithdraw_) external view returns (uint256 _amount, uint256 _fee);

    function quoteWithdrawOut(uint256 amount_) external view returns (uint256 _amountToWithdraw, uint256 _fee);

    function withdraw(uint256 amount_, address to_) external returns (uint256 _withdrawn, uint256 _fee);

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateCollateralFactor(uint128 newCollateralFactor_) external;

    function isActive() external view returns (bool);

    function toggleIsActive() external;

    function maxTotalSupply() external view returns (uint256);

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPauseable {
    function paused() external view returns (bool);

    function everythingStopped() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IDepositToken.sol";
import "./IDebtToken.sol";
import "./ITreasury.sol";
import "./IRewardsDistributor.sol";
import "./IPoolRegistry.sol";

/**
 * @notice Pool interface
 */
interface IPool is IPauseable, IGovernable {
    function debtFloorInUsd() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function issueFee() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function repayFee() external view returns (uint256);

    function swapFee() external view returns (uint256);

    function liquidationFees() external view returns (uint128 liquidatorIncentive, uint128 protocolFee);

    function feeCollector() external view returns (address);

    function maxLiquidable() external view returns (uint256);

    function doesSyntheticTokenExist(ISyntheticToken syntheticToken_) external view returns (bool);

    function doesDebtTokenExist(IDebtToken debtToken_) external view returns (bool);

    function doesDepositTokenExist(IDepositToken depositToken_) external view returns (bool);

    function depositTokenOf(IERC20 underlying_) external view returns (IDepositToken);

    function debtTokenOf(ISyntheticToken syntheticToken_) external view returns (IDebtToken);

    function getDepositTokens() external view returns (address[] memory);

    function getDebtTokens() external view returns (address[] memory);

    function getRewardsDistributors() external view returns (IRewardsDistributor[] memory);

    function debtOf(address account_) external view returns (uint256 _debtInUsd);

    function depositOf(address account_) external view returns (uint256 _depositInUsd, uint256 _issuableLimitInUsd);

    function debtPositionOf(address account_)
        external
        view
        returns (
            bool _isHealthy,
            uint256 _depositInUsd,
            uint256 _debtInUsd,
            uint256 _issuableLimitInUsd,
            uint256 _issuableInUsd
        );

    function addDebtToken(IDebtToken debtToken_) external;

    function removeDebtToken(IDebtToken debtToken_) external;

    function addDepositToken(address depositToken_) external;

    function removeDepositToken(IDepositToken depositToken_) external;

    function liquidate(
        ISyntheticToken syntheticToken_,
        address account_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteLiquidateIn(
        ISyntheticToken syntheticToken_,
        uint256 totalToSeized_,
        IDepositToken depositToken_
    )
        external
        view
        returns (
            uint256 _amountToRepay,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteLiquidateMax(
        ISyntheticToken syntheticToken_,
        address account_,
        IDepositToken depositToken_
    ) external view returns (uint256 _maxAmountToRepay);

    function quoteLiquidateOut(
        ISyntheticToken syntheticToken_,
        uint256 amountToRepay_,
        IDepositToken depositToken_
    )
        external
        view
        returns (
            uint256 _totalSeized,
            uint256 _toLiquidator,
            uint256 _fee
        );

    function quoteSwapIn(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountOut_
    ) external view returns (uint256 _amountIn, uint256 _fee);

    function quoteSwapOut(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external view returns (uint256 _amountOut, uint256 _fee);

    function swap(
        ISyntheticToken syntheticTokenIn_,
        ISyntheticToken syntheticTokenOut_,
        uint256 amountIn_
    ) external returns (uint256 _amountOut, uint256 _fee);

    function updateSwapFee(uint256 newSwapFee_) external;

    function updateDebtFloor(uint256 newDebtFloorInUsd_) external;

    function updateDepositFee(uint256 newDepositFee_) external;

    function updateIssueFee(uint256 newIssueFee_) external;

    function updateWithdrawFee(uint256 newWithdrawFee_) external;

    function updateRepayFee(uint256 newRepayFee_) external;

    function updateLiquidatorIncentive(uint128 newLiquidatorIncentive_) external;

    function updateProtocolLiquidationFee(uint128 newProtocolLiquidationFee_) external;

    function updateMaxLiquidable(uint256 newMaxLiquidable_) external;

    function updateTreasury(ITreasury newTreasury_) external;

    function treasury() external view returns (ITreasury);

    function masterOracle() external view returns (IMasterOracle);

    function poolRegistry() external view returns (IPoolRegistry);

    function addToDepositTokensOfAccount(address account_) external;

    function removeFromDepositTokensOfAccount(address account_) external;

    function addToDebtTokensOfAccount(address account_) external;

    function removeFromDebtTokensOfAccount(address account_) external;

    function getDepositTokensOfAccount(address account_) external view returns (address[] memory);

    function getDebtTokensOfAccount(address account_) external view returns (address[] memory);

    function addRewardsDistributor(IRewardsDistributor distributor_) external;

    function removeRewardsDistributor(IRewardsDistributor distributor_) external;

    function toggleIsSwapActive() external;

    function isSwapActive() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./external/IMasterOracle.sol";
import "./IPauseable.sol";
import "./IGovernable.sol";
import "./ISyntheticToken.sol";

interface IPoolRegistry is IPauseable, IGovernable {
    function isPoolRegistered(address pool_) external view returns (bool);

    function feeCollector() external view returns (address);

    function nativeTokenGateway() external view returns (address);

    function getPools() external view returns (address[] memory);

    function registerPool(address pool_) external;

    function unregisterPool(address pool_) external;

    function masterOracle() external view returns (IMasterOracle);

    function updateMasterOracle(IMasterOracle newOracle_) external;

    function updateFeeCollector(address newFeeCollector_) external;

    function updateNativeTokenGateway(address newGateway_) external;

    function idOfPool(address pool_) external view returns (uint256);

    function nextPoolId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/IERC20.sol";

/**
 * @notice Reward Distributor interface
 */
interface IRewardsDistributor {
    function rewardToken() external view returns (IERC20);

    function tokenSpeeds(IERC20 token_) external view returns (uint256);

    function tokensAccruedOf(address account_) external view returns (uint256);

    function updateBeforeMintOrBurn(IERC20 token_, address account_) external;

    function updateBeforeTransfer(
        IERC20 token_,
        address from_,
        address to_
    ) external;

    function claimable(address account_) external view returns (uint256 _claimable);

    function claimable(address account_, IERC20 token_) external view returns (uint256 _claimable);

    function claimRewards(address account_) external;

    function claimRewards(address account_, IERC20[] memory tokens_) external;

    function claimRewards(address[] memory accounts_, IERC20[] memory tokens_) external;

    function updateTokenSpeed(IERC20 token_, uint256 newSpeed_) external;

    function updateTokenSpeeds(IERC20[] calldata tokens_, uint256[] calldata speeds_) external;

    function tokens(uint256) external view returns (IERC20);

    function tokenStates(IERC20) external view returns (uint224 index, uint32 timestamp);

    function accountIndexOf(IERC20, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IDebtToken.sol";
import "./IPoolRegistry.sol";

interface ISyntheticToken is IERC20Metadata {
    function isActive() external view returns (bool);

    function mint(address to_, uint256 amount_) external;

    function burn(address from_, uint256 amount) external;

    function poolRegistry() external returns (IPoolRegistry);

    function toggleIsActive() external;

    function seize(
        address from_,
        address to_,
        uint256 amount_
    ) external;

    function updateMaxTotalSupply(uint256 newMaxTotalSupply_) external;

    function maxTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITreasury {
    function pull(address to_, uint256 amount_) external;

    function migrateTo(address newTreasury_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterOracle {
    function quoteTokenToUsd(address _asset, uint256 _amount) external view returns (uint256 _amountInUsd);

    function quoteUsdToToken(address _asset, uint256 _amountInUsd) external view returns (uint256 _amount);

    function quote(
        address _assetIn,
        address _assetOut,
        uint256 _amountIn
    ) external view returns (uint256 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev EnumerableSet fork to support `address => address[]` mapping
 * @dev Forked from OZ 4.3.2
 */
library MappedEnumerableSet {
    struct Set {
        // Storage of set values
        address[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(address => uint256) _indexes;
    }

    struct AddressSet {
        mapping(address => Set) _ofAddress;
    }

    function _add(
        AddressSet storage set,
        address _key,
        address value
    ) private returns (bool) {
        if (!_contains(set, _key, value)) {
            set._ofAddress[_key]._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._ofAddress[_key]._indexes[value] = set._ofAddress[_key]._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(
        AddressSet storage set,
        address _key,
        address value
    ) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._ofAddress[_key]._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._ofAddress[_key]._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                address lastvalue = set._ofAddress[_key]._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._ofAddress[_key]._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._ofAddress[_key]._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._ofAddress[_key]._values.pop();

            // Delete the index for the deleted slot
            delete set._ofAddress[_key]._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(
        AddressSet storage set,
        address _key,
        address value
    ) private view returns (bool) {
        return set._ofAddress[_key]._indexes[value] != 0;
    }

    function _length(AddressSet storage set, address _key) private view returns (uint256) {
        return set._ofAddress[_key]._values.length;
    }

    function _at(
        AddressSet storage set,
        address _key,
        uint256 index
    ) private view returns (address) {
        return set._ofAddress[_key]._values[index];
    }

    function _values(AddressSet storage set, address _key) private view returns (address[] memory) {
        return set._ofAddress[_key]._values;
    }

    function add(
        AddressSet storage set,
        address key,
        address value
    ) internal returns (bool) {
        return _add(set, key, value);
    }

    function remove(
        AddressSet storage set,
        address key,
        address value
    ) internal returns (bool) {
        return _remove(set, key, value);
    }

    function contains(
        AddressSet storage set,
        address key,
        address value
    ) internal view returns (bool) {
        return _contains(set, key, value);
    }

    function length(AddressSet storage set, address key) internal view returns (uint256) {
        return _length(set, key);
    }

    function at(
        AddressSet storage set,
        address key,
        uint256 index
    ) internal view returns (address) {
        return _at(set, key, index);
    }

    function values(AddressSet storage set, address key) internal view returns (address[] memory) {
        address[] memory store = _values(set, key);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title Math library
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 * @dev Based on https://github.com/dapphub/ds-math/blob/master/src/math.sol
 */
library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD + b / 2) / b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/utils/structs/EnumerableSet.sol";
import "../lib/MappedEnumerableSet.sol";
import "../interfaces/IPool.sol";

abstract contract PoolStorageV1 is IPool {
    struct LiquidationFees {
        uint128 liquidatorIncentive;
        uint128 protocolFee;
    }

    /**
     * @notice The debt floor (in USD) for each synthetic token
     * This parameters is used to keep incentive for liquidators (i.e. cover gas and provide enough profit)
     */
    uint256 public override debtFloorInUsd;

    /**
     * @notice The fee charged when depositing collateral
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override depositFee;

    /**
     * @notice The fee charged when minting a synthetic token
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override issueFee;

    /**
     * @notice The fee charged when withdrawing collateral
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override withdrawFee;

    /**
     * @notice The fee charged when repaying debt
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override repayFee;

    /**
     * @notice The fee charged when swapping synthetic tokens
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override swapFee;

    /**
     * @notice The fees charged when liquidating a position
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    LiquidationFees public override liquidationFees;

    /**
     * @notice The max percent of the debt allowed to liquidate
     * @dev Use 18 decimals (e.g. 1e16 = 1%)
     */
    uint256 public override maxLiquidable;

    /**
     * @notice PoolRegistry
     */
    IPoolRegistry public override poolRegistry;

    /**
     * @notice Swap feature on/off flag
     */
    bool public override isSwapActive;

    /**
     * @notice Treasury contract
     */
    ITreasury public override treasury;

    /**
     * @notice Represents collateral's deposits
     */
    EnumerableSet.AddressSet internal depositTokens;

    /**
     * @notice Get the deposit token's address from given underlying asset
     */
    mapping(IERC20 => IDepositToken) public override depositTokenOf;

    /**
     * @notice Available debt tokens
     */
    EnumerableSet.AddressSet internal debtTokens;

    /**
     * @notice Per-account deposit tokens (i.e. tokens that user has balance > 0)
     */
    MappedEnumerableSet.AddressSet internal depositTokensOfAccount;

    /**
     * @notice Per-account debt tokens (i.e. tokens that user has balance > 0)
     */
    MappedEnumerableSet.AddressSet internal debtTokensOfAccount;

    /**
     * @notice RewardsDistributor contracts
     */
    IRewardsDistributor[] internal rewardsDistributors;

    /**
     * @notice Get the debt token's address from given synthetic asset
     */
    mapping(ISyntheticToken => IDebtToken) public override debtTokenOf;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interfaces/IPauseable.sol";
import "../access/Governable.sol";

error IsPaused();
error IsShutdown();
error IsNotPaused();
error IsNotShutdown();

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 */
abstract contract Pauseable is IPauseable, Governable {
    /// @notice Emitted when contract is turned on
    event Open(address indexed caller);

    /// @notice Emitted when contract is paused
    event Paused(address indexed caller);

    /// @notice Emitted when contract is shuted down
    event Shutdown(address indexed caller);

    /// @notice Emitted when contract is unpaused
    event Unpaused(address indexed caller);

    bool private _paused;
    bool private _everythingStopped;

    /**
     * @dev Throws if contract is paused
     */
    modifier whenNotPaused() {
        if (paused()) revert IsPaused();
        _;
    }

    /**
     * @dev Throws if contract is shutdown
     */
    modifier whenNotShutdown() {
        if (everythingStopped()) revert IsShutdown();
        _;
    }

    /**
     * @dev Throws if contract is not paused
     */
    modifier whenPaused() {
        if (!paused()) revert IsNotPaused();
        _;
    }

    /**
     * @dev Throws if contract is not shutdown
     */
    modifier whenShutdown() {
        if (!everythingStopped()) revert IsNotShutdown();
        _;
    }

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Pauseable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Pauseable_init() internal initializer {
        __Governable_init();
    }

    /**
     * @notice Return `true` if contract is shutdown
     */
    function everythingStopped() public view virtual returns (bool) {
        return _everythingStopped;
    }

    /**
     * @notice Return `true` if contract is paused
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Open contract operations, if contract is in shutdown state
     */
    function open() external virtual whenShutdown onlyGovernor {
        _everythingStopped = false;
        emit Open(msg.sender);
    }

    /**
     * @dev Suspend deposit feature, if contract is not paused.
     */
    function pause() external virtual whenNotPaused onlyGovernor {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Suspend all features (issue, repay, deposit, withdraw, liquidate and swap), if not already shutdown.
     */
    function shutdown() external virtual whenNotShutdown onlyGovernor {
        _everythingStopped = true;
        _paused = true;
        emit Shutdown(msg.sender);
    }

    /**
     * @dev Unpause contract operations, allow only if contract is paused and not shutdown.
     */
    function unpause() external virtual whenPaused whenNotShutdown onlyGovernor {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/token/ERC20/utils/SafeERC20.sol";

error FallbackIsNotAllowed();
error ReceiveIsNotAllowed();

/**
 * @title Utils contract that handles tokens sent to it
 */
abstract contract TokenHolder {
    using SafeERC20 for IERC20;

    /**
     * @dev Revert fallback calls
     */
    fallback() external payable {
        revert FallbackIsNotAllowed();
    }

    /**
     * @dev Revert when receiving by default
     */
    receive() external payable virtual {
        revert ReceiveIsNotAllowed();
    }

    /**
     * @notice ERC20 recovery in case of stuck tokens due direct transfers to the contract address.
     * @param token_ The token to transfer
     * @param to_ The recipient of the transfer
     * @param amount_ The amount to send
     */
    function sweep(
        IERC20 token_,
        address to_,
        uint256 amount_
    ) external {
        _requireCanSweep();

        if (address(token_) == address(0)) {
            Address.sendValue(payable(to_), amount_);
        } else {
            token_.safeTransfer(to_, amount_);
        }
    }

    /**
     * @notice Function that reverts if the caller isn't allowed to sweep tokens
     * @dev Usually requires the owner or governor as the caller
     */
    function _requireCanSweep() internal view virtual;
}