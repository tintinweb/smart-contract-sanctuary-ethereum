pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {Unauthorized, IllegalState, IllegalArgument} from "./base/Errors.sol";

import "./base/Multicall.sol";
import "./base/Mutex.sol";

import "./interfaces/IAlchemistV2.sol";
import "./interfaces/IERC20Minimal.sol";
import "./interfaces/IERC20TokenReceiver.sol";
import "./interfaces/ITokenAdapter.sol";
import "./interfaces/IAlchemicToken.sol";
import "./interfaces/IWhitelist.sol";

import "./libraries/SafeCast.sol";
import "./libraries/Sets.sol";
import "./libraries/TokenUtils.sol";
import "./libraries/Limiters.sol";

/// @title  AlchemistV2
/// @author Alchemix Finance
contract AlchemistV2 is IAlchemistV2, Initializable, Multicall, Mutex {
    using Limiters for Limiters.LinearGrowthLimiter;
    using Sets for Sets.AddressSet;

    /// @notice A user account.
    struct Account {
        // A signed value which represents the current amount of debt or credit that the account has accrued.
        // Positive values indicate debt, negative values indicate credit.
        int256 debt;
        // The share balances for each yield token.
        mapping(address => uint256) balances;
        // The last values recorded for accrued weights for each yield token.
        mapping(address => uint256) lastAccruedWeights;
        // The set of yield tokens that the account has deposited into the system.
        Sets.AddressSet depositedTokens;
        // The allowances for mints.
        mapping(address => uint256) mintAllowances;
        // The allowances for withdrawals.
        mapping(address => mapping(address => uint256)) withdrawAllowances;
    }

    /// @notice The number of basis points there are to represent exactly 100%.
    uint256 public constant BPS = 10000;

    /// @notice The scalar used for conversion of integral numbers to fixed point numbers. Fixed point numbers in this
    ///         implementation have 18 decimals of resolution, meaning that 1 is represented as 1e18, 0.5 is
    ///         represented as 5e17, and 2 is represented as 2e18.
    uint256 public constant FIXED_POINT_SCALAR = 1e18;

    /// @inheritdoc IAlchemistV2Immutables
    string public constant override version = "2.2.6";

    /// @inheritdoc IAlchemistV2Immutables
    address public override debtToken;

    /// @inheritdoc IAlchemistV2State
    address public override admin;

    /// @inheritdoc IAlchemistV2State
    address public override pendingAdmin;

    /// @inheritdoc IAlchemistV2State
    mapping(address => bool) public override sentinels;

    /// @inheritdoc IAlchemistV2State
    mapping(address => bool) public override keepers;

    /// @inheritdoc IAlchemistV2State
    address public override transmuter;

    /// @inheritdoc IAlchemistV2State
    uint256 public override minimumCollateralization;

    /// @inheritdoc IAlchemistV2State
    uint256 public override protocolFee;

    /// @inheritdoc IAlchemistV2State
    address public override protocolFeeReceiver;

    /// @inheritdoc IAlchemistV2State
    address public override whitelist;

    /// @dev A linear growth function that limits the amount of debt-token minted.
    Limiters.LinearGrowthLimiter private _mintingLimiter;

    // @dev The repay limiters for each underlying token.
    mapping(address => Limiters.LinearGrowthLimiter) private _repayLimiters;

    // @dev The liquidation limiters for each underlying token.
    mapping(address => Limiters.LinearGrowthLimiter) private _liquidationLimiters;

    /// @dev Accounts mapped by the address that owns them.
    mapping(address => Account) private _accounts;

    /// @dev Underlying token parameters mapped by token address.
    mapping(address => UnderlyingTokenParams) private _underlyingTokens;

    /// @dev Yield token parameters mapped by token address.
    mapping(address => YieldTokenParams) private _yieldTokens;

    /// @dev An iterable set of the underlying tokens that are supported by the system.
    Sets.AddressSet private _supportedUnderlyingTokens;

    /// @dev An iterable set of the yield tokens that are supported by the system.
    Sets.AddressSet private _supportedYieldTokens;

    constructor() initializer {}

    /// @inheritdoc IAlchemistV2State
    function getYieldTokensPerShare(address yieldToken) external view override returns (uint256) {
        return _convertSharesToYieldTokens(yieldToken, 10**_yieldTokens[yieldToken].decimals);
    }

    /// @inheritdoc IAlchemistV2State
    function getUnderlyingTokensPerShare(address yieldToken) external view override returns (uint256) {
        return _convertSharesToUnderlyingTokens(yieldToken, 10**_yieldTokens[yieldToken].decimals);
    }

    /// @inheritdoc IAlchemistV2State
    function getSupportedUnderlyingTokens() external view override returns (address[] memory) {
        return _supportedUnderlyingTokens.values;
    }

    /// @inheritdoc IAlchemistV2State
    function getSupportedYieldTokens() external view override returns (address[] memory) {
        return _supportedYieldTokens.values;
    }

    /// @inheritdoc IAlchemistV2State
    function isSupportedUnderlyingToken(address underlyingToken) external view override returns (bool) {
        return _supportedUnderlyingTokens.contains(underlyingToken);
    }

    /// @inheritdoc IAlchemistV2State
    function isSupportedYieldToken(address yieldToken) external view override returns (bool) {
        return _supportedYieldTokens.contains(yieldToken);
    }

    /// @inheritdoc IAlchemistV2State
    function accounts(address owner)
        external view override
        returns (
            int256 debt,
            address[] memory depositedTokens
        )
    {
        Account storage account = _accounts[owner];

        return (
            _calculateUnrealizedDebt(owner),
            account.depositedTokens.values
        );
    }

    /// @inheritdoc IAlchemistV2State
    function positions(address owner, address yieldToken)
        external view override
        returns (
            uint256 shares,
            uint256 lastAccruedWeight
        )
    {
        Account storage account = _accounts[owner];
        return (account.balances[yieldToken], account.lastAccruedWeights[yieldToken]);
    }

    /// @inheritdoc IAlchemistV2State
    function mintAllowance(address owner, address spender)
        external view override
        returns (uint256)
    {
        Account storage account = _accounts[owner];
        return account.mintAllowances[spender];
    }

    /// @inheritdoc IAlchemistV2State
    function withdrawAllowance(address owner, address spender, address yieldToken)
        external view override
        returns (uint256)
    {
        Account storage account = _accounts[owner];
        return account.withdrawAllowances[spender][yieldToken];
    }

    /// @inheritdoc IAlchemistV2State
    function getUnderlyingTokenParameters(address underlyingToken)
        external view override
        returns (UnderlyingTokenParams memory)
    {
        return _underlyingTokens[underlyingToken];
    }

    /// @inheritdoc IAlchemistV2State
    function getYieldTokenParameters(address yieldToken)
        external view override
        returns (YieldTokenParams memory)
    {
        return _yieldTokens[yieldToken];
    }

    /// @inheritdoc IAlchemistV2State
    function getMintLimitInfo()
        external view override
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        )
    {
        return (
            _mintingLimiter.get(),
            _mintingLimiter.rate,
            _mintingLimiter.maximum
        );
    }

    /// @inheritdoc IAlchemistV2State
    function getRepayLimitInfo(address underlyingToken)
        external view override
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        )
    {
        Limiters.LinearGrowthLimiter storage limiter = _repayLimiters[underlyingToken];
        return (
            limiter.get(),
            limiter.rate,
            limiter.maximum
        );
    }

    /// @inheritdoc IAlchemistV2State
    function getLiquidationLimitInfo(address underlyingToken)
        external view override
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        )
    {
        Limiters.LinearGrowthLimiter storage limiter = _liquidationLimiters[underlyingToken];
        return (
            limiter.get(),
            limiter.rate,
            limiter.maximum
        );
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function initialize(InitializationParams memory params) external initializer {
        _checkArgument(params.protocolFee <= BPS);

        debtToken                = params.debtToken;
        admin                    = params.admin;
        transmuter               = params.transmuter;
        minimumCollateralization = params.minimumCollateralization;
        protocolFee              = params.protocolFee;
        protocolFeeReceiver      = params.protocolFeeReceiver;
        whitelist                = params.whitelist;

        _mintingLimiter = Limiters.createLinearGrowthLimiter(
            params.mintingLimitMaximum,
            params.mintingLimitBlocks,
            params.mintingLimitMinimum
        );

        emit AdminUpdated(admin);
        emit TransmuterUpdated(transmuter);
        emit MinimumCollateralizationUpdated(minimumCollateralization);
        emit ProtocolFeeUpdated(protocolFee);
        emit ProtocolFeeReceiverUpdated(protocolFeeReceiver);
        emit MintingLimitUpdated(params.mintingLimitMaximum, params.mintingLimitBlocks);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setPendingAdmin(address value) external override {
        _onlyAdmin();
        pendingAdmin = value;
        emit PendingAdminUpdated(value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function acceptAdmin() external override {
        _checkState(pendingAdmin != address(0));

        if (msg.sender != pendingAdmin) {
            revert Unauthorized();
        }

        admin = pendingAdmin;
        pendingAdmin = address(0);

        emit AdminUpdated(admin);
        emit PendingAdminUpdated(address(0));
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setSentinel(address sentinel, bool flag) external override {
        _onlyAdmin();
        sentinels[sentinel] = flag;
        emit SentinelSet(sentinel, flag);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setKeeper(address keeper, bool flag) external override {
        _onlyAdmin();
        keepers[keeper] = flag;
        emit KeeperSet(keeper, flag);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function addUnderlyingToken(address underlyingToken, UnderlyingTokenConfig calldata config) external override lock {
        _onlyAdmin();
        _checkState(!_supportedUnderlyingTokens.contains(underlyingToken));

        uint8 tokenDecimals = TokenUtils.expectDecimals(underlyingToken);
        uint8 debtTokenDecimals = TokenUtils.expectDecimals(debtToken);

        _checkArgument(tokenDecimals <= debtTokenDecimals);

        _underlyingTokens[underlyingToken] = UnderlyingTokenParams({
            decimals:         tokenDecimals,
            conversionFactor: 10**(debtTokenDecimals - tokenDecimals),
            enabled:          false
        });

        _repayLimiters[underlyingToken] = Limiters.createLinearGrowthLimiter(
            config.repayLimitMaximum,
            config.repayLimitBlocks,
            config.repayLimitMinimum
        );

        _liquidationLimiters[underlyingToken] = Limiters.createLinearGrowthLimiter(
            config.liquidationLimitMaximum,
            config.liquidationLimitBlocks,
            config.liquidationLimitMinimum
        );

        _supportedUnderlyingTokens.add(underlyingToken);

        emit AddUnderlyingToken(underlyingToken);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function addYieldToken(address yieldToken, YieldTokenConfig calldata config) external override lock {
        _onlyAdmin();
        _checkArgument(config.maximumLoss <= BPS);
        _checkArgument(config.creditUnlockBlocks > 0);

        _checkState(!_supportedYieldTokens.contains(yieldToken));

        ITokenAdapter adapter = ITokenAdapter(config.adapter);

        _checkState(yieldToken == adapter.token());
        _checkSupportedUnderlyingToken(adapter.underlyingToken());

        _yieldTokens[yieldToken] = YieldTokenParams({
            decimals:              TokenUtils.expectDecimals(yieldToken),
            underlyingToken:       adapter.underlyingToken(),
            adapter:               config.adapter,
            maximumLoss:           config.maximumLoss,
            maximumExpectedValue:  config.maximumExpectedValue,
            creditUnlockRate:      FIXED_POINT_SCALAR / config.creditUnlockBlocks,
            activeBalance:         0,
            harvestableBalance:    0,
            totalShares:           0,
            expectedValue:         0,
            accruedWeight:         0,
            pendingCredit:         0,
            distributedCredit:     0,
            lastDistributionBlock: 0,
            enabled:               false
        });

        _supportedYieldTokens.add(yieldToken);

        TokenUtils.safeApprove(yieldToken, config.adapter, type(uint256).max);
        TokenUtils.safeApprove(adapter.underlyingToken(), config.adapter, type(uint256).max);

        emit AddYieldToken(yieldToken);
        emit TokenAdapterUpdated(yieldToken, config.adapter);
        emit MaximumLossUpdated(yieldToken, config.maximumLoss);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setUnderlyingTokenEnabled(address underlyingToken, bool enabled) external override {
        _onlySentinelOrAdmin();
        _checkSupportedUnderlyingToken(underlyingToken);
        _underlyingTokens[underlyingToken].enabled = enabled;
        emit UnderlyingTokenEnabled(underlyingToken, enabled);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setYieldTokenEnabled(address yieldToken, bool enabled) external override {
        _onlySentinelOrAdmin();
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].enabled = enabled;
        emit YieldTokenEnabled(yieldToken, enabled);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function configureRepayLimit(address underlyingToken, uint256 maximum, uint256 blocks) external override {
        _onlyAdmin();
        _checkSupportedUnderlyingToken(underlyingToken);
        _repayLimiters[underlyingToken].update();
        _repayLimiters[underlyingToken].configure(maximum, blocks);
        emit RepayLimitUpdated(underlyingToken, maximum, blocks);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function configureLiquidationLimit(address underlyingToken, uint256 maximum, uint256 blocks) external override {
        _onlyAdmin();
        _checkSupportedUnderlyingToken(underlyingToken);
        _liquidationLimiters[underlyingToken].update();
        _liquidationLimiters[underlyingToken].configure(maximum, blocks);
        emit LiquidationLimitUpdated(underlyingToken, maximum, blocks);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setTransmuter(address value) external override {
        _onlyAdmin();
        _checkArgument(value != address(0));
        transmuter = value;
        emit TransmuterUpdated(value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setMinimumCollateralization(uint256 value) external override {
        _onlyAdmin();
        minimumCollateralization = value;
        emit MinimumCollateralizationUpdated(value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setProtocolFee(uint256 value) external override {
        _onlyAdmin();
        _checkArgument(value <= BPS);
        protocolFee = value;
        emit ProtocolFeeUpdated(value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setProtocolFeeReceiver(address value) external override {
        _onlyAdmin();
        _checkArgument(value != address(0));
        protocolFeeReceiver = value;
        emit ProtocolFeeReceiverUpdated(value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function configureMintingLimit(uint256 maximum, uint256 rate) external override {
        _onlyAdmin();
        _mintingLimiter.update();
        _mintingLimiter.configure(maximum, rate);
        emit MintingLimitUpdated(maximum, rate);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function configureCreditUnlockRate(address yieldToken, uint256 blocks) external override {
        _onlyAdmin();
        _checkArgument(blocks > 0);
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].creditUnlockRate = FIXED_POINT_SCALAR / blocks;
        emit CreditUnlockRateUpdated(yieldToken, blocks);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setTokenAdapter(address yieldToken, address adapter) external override {
        _onlyAdmin();
        _checkState(yieldToken == ITokenAdapter(adapter).token());
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].adapter = adapter;
        TokenUtils.safeApprove(yieldToken, adapter, type(uint256).max);
        TokenUtils.safeApprove(ITokenAdapter(adapter).underlyingToken(), adapter, type(uint256).max);
        emit TokenAdapterUpdated(yieldToken, adapter);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setMaximumExpectedValue(address yieldToken, uint256 value) external override {
        _onlyAdmin();
        _checkSupportedYieldToken(yieldToken);
        _yieldTokens[yieldToken].maximumExpectedValue = value;
        emit MaximumExpectedValueUpdated(yieldToken, value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function setMaximumLoss(address yieldToken, uint256 value) external override {
        _onlyAdmin();
        _checkArgument(value <= BPS);
        _checkSupportedYieldToken(yieldToken);

        _yieldTokens[yieldToken].maximumLoss = value;

        emit MaximumLossUpdated(yieldToken, value);
    }

    /// @inheritdoc IAlchemistV2AdminActions
    function snap(address yieldToken) external override lock {
        _onlyAdmin();
        _checkSupportedYieldToken(yieldToken);

        uint256 expectedValue = _convertYieldTokensToUnderlying(yieldToken, _yieldTokens[yieldToken].activeBalance);

        _yieldTokens[yieldToken].expectedValue = expectedValue;

        emit Snap(yieldToken, expectedValue);
    }

    /// @inheritdoc IAlchemistV2Actions
    function approveMint(address spender, uint256 amount) external override {
        _onlyWhitelisted();
        _approveMint(msg.sender, spender, amount);
    }

    /// @inheritdoc IAlchemistV2Actions
    function approveWithdraw(address spender, address yieldToken, uint256 shares) external override {
        _onlyWhitelisted();
        _checkSupportedYieldToken(yieldToken);
        _approveWithdraw(msg.sender, spender, yieldToken, shares);
    }

    /// @inheritdoc IAlchemistV2Actions
    function poke(address owner) external override lock {
        _onlyWhitelisted();
        _preemptivelyHarvestDeposited(owner);
        _distributeUnlockedCreditDeposited(owner);
        _poke(owner);
    }

    /// @inheritdoc IAlchemistV2Actions
    function deposit(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external override lock returns (uint256) {
        _onlyWhitelisted();
        _checkArgument(recipient != address(0));
        _checkSupportedYieldToken(yieldToken);

        // Deposit the yield tokens to the recipient.
        uint256 shares = _deposit(yieldToken, amount, recipient);

        // Transfer tokens from the message sender now that the internal storage updates have been committed.
        TokenUtils.safeTransferFrom(yieldToken, msg.sender, address(this), amount);

        return shares;
    }

    /// @inheritdoc IAlchemistV2Actions
    function depositUnderlying(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external override lock returns (uint256) {
        _onlyWhitelisted();
        _checkArgument(recipient != address(0));
        _checkSupportedYieldToken(yieldToken);

        // Before depositing, the underlying tokens must be wrapped into yield tokens.
        uint256 amountYieldTokens = _wrap(yieldToken, amount, minimumAmountOut);

        // Deposit the yield-tokens to the recipient.
        return _deposit(yieldToken, amountYieldTokens, recipient);
    }

    /// @inheritdoc IAlchemistV2Actions
    function withdraw(
        address yieldToken,
        uint256 shares,
        address recipient
    ) external override lock returns (uint256) {
        _onlyWhitelisted();
        _checkArgument(recipient != address(0));
        _checkSupportedYieldToken(yieldToken);

        // Withdraw the shares from the system.
        uint256 amountYieldTokens = _withdraw(yieldToken, msg.sender, shares, recipient);

        // Transfer the yield tokens to the recipient.
        TokenUtils.safeTransfer(yieldToken, recipient, amountYieldTokens);

        return amountYieldTokens;
    }

    /// @inheritdoc IAlchemistV2Actions
    function withdrawFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient
    ) external override lock returns (uint256) {
        _onlyWhitelisted();
        _checkArgument(recipient != address(0));
        _checkSupportedYieldToken(yieldToken);

        // Preemptively try and decrease the withdrawal allowance. This will save gas when the allowance is not
        // sufficient for the withdrawal.
        _decreaseWithdrawAllowance(owner, msg.sender, yieldToken, shares);

        // Withdraw the shares from the system.
        uint256 amountYieldTokens = _withdraw(yieldToken, owner, shares, recipient);

        // Transfer the yield tokens to the recipient.
        TokenUtils.safeTransfer(yieldToken, recipient, amountYieldTokens);

        return amountYieldTokens;
    }

    /// @inheritdoc IAlchemistV2Actions
    function withdrawUnderlying(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external override lock returns (uint256) {
        _onlyWhitelisted();

        _checkArgument(recipient != address(0));

        _checkSupportedYieldToken(yieldToken);

        _checkLoss(yieldToken);

        uint256 amountYieldTokens = _withdraw(yieldToken, msg.sender, shares, recipient);

        return _unwrap(yieldToken, amountYieldTokens, recipient, minimumAmountOut);
    }

    /// @inheritdoc IAlchemistV2Actions
    function withdrawUnderlyingFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external override lock returns (uint256) {
        _onlyWhitelisted();

        _checkArgument(recipient != address(0));

        _checkSupportedYieldToken(yieldToken);

        _checkLoss(yieldToken);

        _decreaseWithdrawAllowance(owner, msg.sender, yieldToken, shares);

        uint256 amountYieldTokens = _withdraw(yieldToken, owner, shares, recipient);

        return _unwrap(yieldToken, amountYieldTokens, recipient, minimumAmountOut);
    }

    /// @inheritdoc IAlchemistV2Actions
    function mint(uint256 amount, address recipient) external override lock {
        _onlyWhitelisted();
        _checkArgument(amount > 0);
        _checkArgument(recipient != address(0));

        // Mint tokens from the message sender's account to the recipient.
        _mint(msg.sender, amount, recipient);
    }

    /// @inheritdoc IAlchemistV2Actions
    function mintFrom(
        address owner,
        uint256 amount,
        address recipient
    ) external override lock {
        _onlyWhitelisted();
        _checkArgument(amount > 0);
        _checkArgument(recipient != address(0));

        // Preemptively try and decrease the minting allowance. This will save gas when the allowance is not sufficient
        // for the mint.
        _decreaseMintAllowance(owner, msg.sender, amount);

        // Mint tokens from the owner's account to the recipient.
        _mint(owner, amount, recipient);
    }

    /// @inheritdoc IAlchemistV2Actions
    function burn(uint256 amount, address recipient) external override lock returns (uint256) {
        _onlyWhitelisted();

        _checkArgument(amount > 0);
        _checkArgument(recipient != address(0));

        // Distribute unlocked credit to depositors.
        _distributeUnlockedCreditDeposited(recipient);

        // Update the recipient's account, decrease the debt of the recipient by the number of tokens burned.
        _poke(recipient);

        // Check that the debt is greater than zero.
        //
        // It is possible that the number of debt which is repayable is equal to or less than zero after realizing the
        // credit that was earned since the last update. We do not want to perform a noop so we need to check that the
        // amount of debt to repay is greater than zero.
        int256 debt;
        _checkState((debt = _accounts[recipient].debt) > 0);

        // Limit how much debt can be repaid up to the current amount of debt that the account has. This prevents
        // situations where the user may be trying to repay their entire debt, but it decreases since they send the
        // transaction and causes a revert because burning can never decrease the debt below zero.
        //
        // Casts here are safe because it is asserted that debt is greater than zero.
        uint256 credit = amount > uint256(debt) ? uint256(debt) : amount;

        // Update the recipient's debt.
        _updateDebt(recipient, -SafeCast.toInt256(credit));

        // Burn the tokens from the message sender.
        TokenUtils.safeBurnFrom(debtToken, msg.sender, credit);

        emit Burn(msg.sender, credit, recipient);

        return credit;
    }

    /// @inheritdoc IAlchemistV2Actions
    function repay(address underlyingToken, uint256 amount, address recipient) external override lock returns (uint256) {
        _onlyWhitelisted();

        _checkArgument(amount > 0);
        _checkArgument(recipient != address(0));

        _checkSupportedUnderlyingToken(underlyingToken);
        _checkUnderlyingTokenEnabled(underlyingToken);

        // Distribute unlocked credit to depositors.
        _distributeUnlockedCreditDeposited(recipient);

        // Update the recipient's account and decrease the amount of debt incurred.
        _poke(recipient);

        // Check that the debt is greater than zero.
        //
        // It is possible that the amount of debt which is repayable is equal to or less than zero after realizing the
        // credit that was earned since the last update. We do not want to perform a noop so we need to check that the
        // amount of debt to repay is greater than zero.
        int256 debt;
        _checkState((debt = _accounts[recipient].debt) > 0);

        // Determine the maximum amount of underlying tokens that can be repaid.
        //
        // It is implied that this value is greater than zero because `debt` is greater than zero so a noop is not possible
        // beyond this point. Casting the debt to an unsigned integer is also safe because `debt` is greater than zero.
        uint256 maximumAmount = _normalizeDebtTokensToUnderlying(underlyingToken, uint256(debt));

        // Limit the number of underlying tokens to repay up to the maximum allowed.
        uint256 actualAmount = amount > maximumAmount ? maximumAmount : amount;

        Limiters.LinearGrowthLimiter storage limiter = _repayLimiters[underlyingToken];

        // Check to make sure that the underlying token repay limit has not been breached.
        uint256 currentRepayLimit = limiter.get();
        if (actualAmount > currentRepayLimit) {
          revert RepayLimitExceeded(underlyingToken, actualAmount, currentRepayLimit);
        }

        uint256 credit = _normalizeUnderlyingTokensToDebt(underlyingToken, actualAmount);

        // Update the recipient's debt.
        _updateDebt(recipient, -SafeCast.toInt256(credit));

        // Decrease the amount of the underlying token which is globally available to be repaid.
        limiter.decrease(actualAmount);

        // Transfer the repaid tokens to the transmuter.
        TokenUtils.safeTransferFrom(underlyingToken, msg.sender, transmuter, actualAmount);

        // Inform the transmuter that it has received tokens.
        IERC20TokenReceiver(transmuter).onERC20Received(underlyingToken, actualAmount);

        emit Repay(msg.sender, underlyingToken, actualAmount, recipient);

        return actualAmount;
    }

    /// @inheritdoc IAlchemistV2Actions
    function liquidate(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external override lock returns (uint256) {
        _onlyWhitelisted();

        _checkArgument(shares > 0);

        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        address underlyingToken = yieldTokenParams.underlyingToken;

        _checkSupportedYieldToken(yieldToken);
        _checkYieldTokenEnabled(yieldToken);
        _checkUnderlyingTokenEnabled(underlyingToken);
        _checkLoss(yieldToken);

        // Calculate the unrealized debt.
        //
        // It is possible that the number of debt which is repayable is equal to or less than zero after realizing the
        // credit that was earned since the last update. We do not want to perform a noop so we need to check that the
        // amount of debt to repay is greater than zero.
        int256 unrealizedDebt;
        _checkState((unrealizedDebt = _calculateUnrealizedDebt(msg.sender)) > 0);

        // Determine the maximum amount of shares that can be liquidated from the unrealized debt.
        //
        // It is implied that this value is greater than zero because `debt` is greater than zero. Casting the debt to an
        // unsigned integer is also safe for this reason.
        uint256 maximumShares = _convertUnderlyingTokensToShares(
          yieldToken,
          _normalizeDebtTokensToUnderlying(underlyingToken, uint256(unrealizedDebt))
        );

        // Limit the number of shares to liquidate up to the maximum allowed.
        uint256 actualShares = shares > maximumShares ? maximumShares : shares;

        // Unwrap the yield tokens that the shares are worth.
        uint256 amountYieldTokens      = _convertSharesToYieldTokens(yieldToken, actualShares);
        uint256 amountUnderlyingTokens = _unwrap(yieldToken, amountYieldTokens, address(this), minimumAmountOut);

        // Again, perform another noop check. It is possible that the amount of underlying tokens that were received by
        // unwrapping the yield tokens was zero because the amount of yield tokens to unwrap was too small.
        _checkState(amountUnderlyingTokens > 0);

        Limiters.LinearGrowthLimiter storage limiter = _liquidationLimiters[underlyingToken];

        // Check to make sure that the underlying token liquidation limit has not been breached.
        uint256 liquidationLimit = limiter.get();
        if (amountUnderlyingTokens > liquidationLimit) {
          revert LiquidationLimitExceeded(underlyingToken, amountUnderlyingTokens, liquidationLimit);
        }

        // Buffers any harvestable yield tokens. This will properly synchronize the balance which is held by users
        // and the balance which is held by the system. This is required for `_sync` to function correctly.
        _preemptivelyHarvest(yieldToken);

        // Distribute unlocked credit to depositors.
        _distributeUnlockedCreditDeposited(msg.sender);

        uint256 credit = _normalizeUnderlyingTokensToDebt(underlyingToken, amountUnderlyingTokens);

        // Update the message sender's account, proactively burn shares, decrease the amount of debt incurred, and then
        // decrease the value of the token that the system is expected to hold.
        _poke(msg.sender, yieldToken);
        _burnShares(msg.sender, yieldToken, actualShares);
        _updateDebt(msg.sender, -SafeCast.toInt256(credit));
        _sync(yieldToken, amountYieldTokens, _usub);

        // Decrease the amount of the underlying token which is globally available to be liquidated.
        limiter.decrease(amountUnderlyingTokens);

        // Transfer the liquidated tokens to the transmuter.
        TokenUtils.safeTransfer(underlyingToken, transmuter, amountUnderlyingTokens);

        // Inform the transmuter that it has received tokens.
        IERC20TokenReceiver(transmuter).onERC20Received(underlyingToken, amountUnderlyingTokens);

        emit Liquidate(msg.sender, yieldToken, underlyingToken, actualShares);

        return actualShares;
    }

    /// @inheritdoc IAlchemistV2Actions
    function donate(address yieldToken, uint256 amount) external override lock {
        _onlyWhitelisted();
        _checkArgument(amount != 0);

        // Distribute any unlocked credit so that the accrued weight is up to date.
        _distributeUnlockedCredit(yieldToken);

        // Update the message sender's account. This will assure that any credit that was earned is not overridden.
        _poke(msg.sender);

        uint256 shares = _yieldTokens[yieldToken].totalShares - _accounts[msg.sender].balances[yieldToken];

        _yieldTokens[yieldToken].accruedWeight += amount * FIXED_POINT_SCALAR / shares;
        _accounts[msg.sender].lastAccruedWeights[yieldToken] = _yieldTokens[yieldToken].accruedWeight;

        TokenUtils.safeBurnFrom(debtToken, msg.sender, amount);

        emit Donate(msg.sender, yieldToken, amount);
    }

    /// @inheritdoc IAlchemistV2Actions
    function harvest(address yieldToken, uint256 minimumAmountOut) external override lock {
        _onlyKeeper();
        _checkSupportedYieldToken(yieldToken);

        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        // Buffer any harvestable yield tokens. This will properly synchronize the balance which is held by users
        // and the balance which is held by the system to be harvested during this call.
        _preemptivelyHarvest(yieldToken);

        // Load and proactively clear the amount of harvestable tokens so that future calls do not rely on stale data.
        // Because we cannot call an external unwrap until the amount of harvestable tokens has been calculated,
        // clearing this data immediately prevents any potential reentrancy attacks which would use stale harvest
        // buffer values.
        uint256 harvestableAmount = yieldTokenParams.harvestableBalance;
        yieldTokenParams.harvestableBalance = 0;

        // Check that the harvest will not be a no-op.
        _checkState(harvestableAmount != 0);

        address underlyingToken = yieldTokenParams.underlyingToken;
        uint256 amountUnderlyingTokens = _unwrap(yieldToken, harvestableAmount, address(this), minimumAmountOut);

        // Calculate how much of the unwrapped underlying tokens will be allocated for fees and distributed to users.
        uint256 feeAmount = amountUnderlyingTokens * protocolFee / BPS;
        uint256 distributeAmount = amountUnderlyingTokens - feeAmount;

        uint256 credit = _normalizeUnderlyingTokensToDebt(underlyingToken, distributeAmount);

        // Distribute credit to all of the users who hold shares of the yield token.
        _distributeCredit(yieldToken, credit);

        // Transfer the tokens to the fee receiver and transmuter.
        TokenUtils.safeTransfer(underlyingToken, protocolFeeReceiver, feeAmount);
        TokenUtils.safeTransfer(underlyingToken, transmuter, distributeAmount);

        // Inform the transmuter that it has received tokens.
        IERC20TokenReceiver(transmuter).onERC20Received(underlyingToken, distributeAmount);

        emit Harvest(yieldToken, minimumAmountOut, amountUnderlyingTokens);
    }

    /// @dev Checks that the `msg.sender` is the administrator.
    ///
    /// @dev `msg.sender` must be the administrator or this call will revert with an {Unauthorized} error.
    function _onlyAdmin() internal view {
        if (msg.sender != admin) {
            revert Unauthorized();
        }
    }

    /// @dev Checks that the `msg.sender` is the administrator or a sentinel.
    ///
    /// @dev `msg.sender` must be either the administrator or a sentinel or this call will revert with an
    ///      {Unauthorized} error.
    function _onlySentinelOrAdmin() internal view {
        // Check if the message sender is the administrator.
        if (msg.sender == admin) {
            return;
        }

        // Check if the message sender is a sentinel. After this check we can revert since we know that it is neither
        // the administrator or a sentinel.
        if (!sentinels[msg.sender]) {
            revert Unauthorized();
        }
    }

    /// @dev Checks that the `msg.sender` is a keeper.
    ///
    /// @dev `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    function _onlyKeeper() internal view {
        if (!keepers[msg.sender]) {
            revert Unauthorized();
        }
    }

    /// @dev Preemptively harvests all of the yield tokens that have been deposited into an account.
    ///
    /// @param owner The address which owns the account.
    function _preemptivelyHarvestDeposited(address owner) internal {
        Sets.AddressSet storage depositedTokens = _accounts[owner].depositedTokens;
        for (uint256 i = 0; i < depositedTokens.values.length; i++) {
            _preemptivelyHarvest(depositedTokens.values[i]);
        }
    }

    /// @dev Preemptively harvests `yieldToken`.
    ///
    /// @dev This will earmark yield tokens to be harvested at a future time when the current value of the token is
    ///      greater than the expected value. The purpose of this function is to synchronize the balance of the yield
    ///      token which is held by users versus tokens which will be seized by the protocol.
    ///
    /// @param yieldToken The address of the yield token to preemptively harvest.
    function _preemptivelyHarvest(address yieldToken) internal {
        uint256 activeBalance = _yieldTokens[yieldToken].activeBalance;
        if (activeBalance == 0) {
            return;
        }

        uint256 currentValue = _convertYieldTokensToUnderlying(yieldToken, activeBalance);
        uint256 expectedValue = _yieldTokens[yieldToken].expectedValue;
        if (currentValue <= expectedValue) {
            return;
        }

        uint256 harvestable = _convertUnderlyingTokensToYield(yieldToken, currentValue - expectedValue);
        if (harvestable == 0) {
            return;
        }
        _yieldTokens[yieldToken].activeBalance -= harvestable;
        _yieldTokens[yieldToken].harvestableBalance += harvestable;
    }

    /// @dev Checks if a yield token is enabled.
    ///
    /// @param yieldToken The address of the yield token.
    function _checkYieldTokenEnabled(address yieldToken) internal view {
        if (!_yieldTokens[yieldToken].enabled) {
          revert TokenDisabled(yieldToken);
        }
    }

    /// @dev Checks if an underlying token is enabled.
    ///
    /// @param underlyingToken The address of the underlying token.
    function _checkUnderlyingTokenEnabled(address underlyingToken) internal view {
        if (!_underlyingTokens[underlyingToken].enabled) {
          revert TokenDisabled(underlyingToken);
        }
    }

    /// @dev Checks if an address is a supported yield token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address to check.
    function _checkSupportedYieldToken(address yieldToken) internal view {
        if (!_supportedYieldTokens.contains(yieldToken)) {
            revert UnsupportedToken(yieldToken);
        }
    }

    /// @dev Checks if an address is a supported underlying token.
    ///
    /// If the address is not a supported yield token, this function will revert using a {UnsupportedToken} error.
    ///
    /// @param underlyingToken The address to check.
    function _checkSupportedUnderlyingToken(address underlyingToken) internal view {
        if (!_supportedUnderlyingTokens.contains(underlyingToken)) {
            revert UnsupportedToken(underlyingToken);
        }
    }

    /// @dev Checks if `amount` of debt tokens can be minted.
    ///
    /// @dev `amount` must be less than the current minting limit or this call will revert with a
    ///      {MintingLimitExceeded} error.
    ///
    /// @param amount The amount to check.
    function _checkMintingLimit(uint256 amount) internal view {
        uint256 limit = _mintingLimiter.get();
        if (amount > limit) {
            revert MintingLimitExceeded(amount, limit);
        }
    }

    /// @dev Checks if the current loss of `yieldToken` has exceeded its maximum acceptable loss.
    ///
    /// @dev The loss that `yieldToken` has incurred must be less than its maximum accepted value or this call will
    ///      revert with a {LossExceeded} error.
    ///
    /// @param yieldToken The address of the yield token.
    function _checkLoss(address yieldToken) internal view {
        uint256 loss = _loss(yieldToken);
        uint256 maximumLoss = _yieldTokens[yieldToken].maximumLoss;
        if (loss > maximumLoss) {
            revert LossExceeded(yieldToken, loss, maximumLoss);
        }
    }

    /// @dev Deposits `amount` yield tokens into the account of `recipient`.
    ///
    /// @dev Emits a {Deposit} event.
    ///
    /// @param yieldToken The address of the yield token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The recipient of the yield tokens.
    ///
    /// @return The number of shares minted to `recipient`.
    function _deposit(
        address yieldToken,
        uint256 amount,
        address recipient
    ) internal returns (uint256) {
        _checkArgument(amount > 0);

        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        address underlyingToken = yieldTokenParams.underlyingToken;

        // Check that the yield token and it's underlying token are enabled. Disabling the yield token and or the
        // underlying token prevents the system from holding more of the disabled yield token or underlying token.
        _checkYieldTokenEnabled(yieldToken);
        _checkUnderlyingTokenEnabled(underlyingToken);

        // Check to assure that the token has not experienced a sudden unexpected loss. This prevents users from being
        // able to deposit funds and then have them siphoned if the price recovers.
        _checkLoss(yieldToken);

        // Buffers any harvestable yield tokens. This will properly synchronize the balance which is held by users
        // and the balance which is held by the system to eventually be harvested.
        _preemptivelyHarvest(yieldToken);

        // Distribute unlocked credit to depositors.
        _distributeUnlockedCreditDeposited(recipient);

        // Update the recipient's account, proactively issue shares for the deposited tokens to the recipient, and then
        // increase the value of the token that the system is expected to hold.
        _poke(recipient, yieldToken);
        uint256 shares = _issueSharesForAmount(recipient, yieldToken, amount);
        _sync(yieldToken, amount, _uadd);

        // Check that the maximum expected value has not been breached.
        uint256 maximumExpectedValue = yieldTokenParams.maximumExpectedValue;
        if (yieldTokenParams.expectedValue > maximumExpectedValue) {
          revert ExpectedValueExceeded(yieldToken, amount, maximumExpectedValue);
        }

        emit Deposit(msg.sender, yieldToken, amount, recipient);

        return shares;
    }

    /// @dev Withdraw `yieldToken` from the account owned by `owner` by burning shares and receiving yield tokens of
    ///      equivalent value.
    ///
    /// @dev Emits a {Withdraw} event.
    ///
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param owner      The address of the account owner to withdraw from.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The recipient of the withdrawn shares. This parameter is only used for logging.
    ///
    /// @return The amount of yield tokens that the burned shares were exchanged for.
    function _withdraw(
        address yieldToken,
        address owner,
        uint256 shares,
        address recipient
    ) internal returns (uint256) {
        // Buffers any harvestable yield tokens that the owner of the account has deposited. This will properly
        // synchronize the balance of all the tokens held by the owner so that the validation check properly
        // computes the total value of the tokens held by the owner.
        _preemptivelyHarvestDeposited(owner);

        // Distribute unlocked credit for all of the tokens that the user has deposited into the system. This updates
        // the accrued weights so that the debt is properly calculated before the account is validated.
        _distributeUnlockedCreditDeposited(owner);

        uint256 amountYieldTokens = _convertSharesToYieldTokens(yieldToken, shares);

        // Update the owner's account, burn shares from the owner's account, and then decrease the value of the token
        // that the system is expected to hold.
        _poke(owner);
        _burnShares(owner, yieldToken, shares);
        _sync(yieldToken, amountYieldTokens, _usub);

        // Valid the owner's account to assure that the collateralization invariant is still held.
        _validate(owner);

        emit Withdraw(owner, yieldToken, shares, recipient);

        return amountYieldTokens;
    }

    /// @dev Mints debt tokens to `recipient` using the account owned by `owner`.
    ///
    /// @dev Emits a {Mint} event.
    ///
    /// @param owner     The owner of the account to mint from.
    /// @param amount    The amount to mint.
    /// @param recipient The recipient of the minted debt tokens.
    function _mint(address owner, uint256 amount, address recipient) internal {
        // Check that the system will allow for the specified amount to be minted.
        _checkMintingLimit(amount);

        // Preemptively harvest all tokens that the user has deposited into the system. This allows the debt to be
        // properly calculated before the account is validated.
        _preemptivelyHarvestDeposited(owner);

        // Distribute unlocked credit for all of the tokens that the user has deposited into the system. This updates
        // the accrued weights so that the debt is properly calculated before the account is validated.
        _distributeUnlockedCreditDeposited(owner);

        // Update the owner's account, increase their debt by the amount of tokens to mint, and then finally validate
        // their account to assure that the collateralization invariant is still held.
        _poke(owner);
        _updateDebt(owner, SafeCast.toInt256(amount));
        _validate(owner);

        // Decrease the global amount of mintable debt tokens.
        _mintingLimiter.decrease(amount);

        // Mint the debt tokens to the recipient.
        TokenUtils.safeMint(debtToken, recipient, amount);

        emit Mint(owner, amount, recipient);
    }

    /// @dev Synchronizes the active balance and expected value of `yieldToken`.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount to add or subtract from the debt.
    /// @param operation  The mathematical operation to perform for the update. Either one of {_uadd} or {_usub}.
    function _sync(
        address yieldToken,
        uint256 amount,
        function(uint256, uint256) internal pure returns (uint256) operation
    ) internal {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];

        uint256 amountUnderlyingTokens = _convertYieldTokensToUnderlying(yieldToken, amount);
        uint256 updatedActiveBalance   = operation(yieldTokenParams.activeBalance, amount);
        uint256 updatedExpectedValue   = operation(yieldTokenParams.expectedValue, amountUnderlyingTokens);

        _yieldTokens[yieldToken].activeBalance = updatedActiveBalance;
        _yieldTokens[yieldToken].expectedValue = updatedExpectedValue;
    }

    /// @dev Gets the amount of loss that `yieldToken` has incurred measured in basis points. When the expected
    ///      underlying value is less than the actual value, this will return zero.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return The loss in basis points.
    function _loss(address yieldToken) internal view returns (uint256) {
        YieldTokenParams memory yieldTokenParams = _yieldTokens[yieldToken];

        uint256 amountUnderlyingTokens = _convertYieldTokensToUnderlying(yieldToken, yieldTokenParams.activeBalance);
        uint256 expectedUnderlyingValue = yieldTokenParams.expectedValue;

        return expectedUnderlyingValue > amountUnderlyingTokens
            ? ((expectedUnderlyingValue - amountUnderlyingTokens) * BPS) / expectedUnderlyingValue
            : 0;
    }

    /// @dev Distributes `amount` credit to all depositors of `yieldToken`.
    ///
    /// @param yieldToken The address of the yield token to distribute credit for.
    /// @param amount     The amount of credit to distribute in debt tokens.
    function _distributeCredit(address yieldToken, uint256 amount) internal {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 pendingCredit     = yieldTokenParams.pendingCredit;
        uint256 distributedCredit = yieldTokenParams.distributedCredit;
        uint256 unlockedCredit    = _calculateUnlockedCredit(yieldToken);
        uint256 lockedCredit      = pendingCredit - (distributedCredit + unlockedCredit);

        // Distribute any unlocked credit before overriding it.
        if (unlockedCredit > 0) {
            yieldTokenParams.accruedWeight += unlockedCredit * FIXED_POINT_SCALAR / yieldTokenParams.totalShares;
        }

        yieldTokenParams.pendingCredit         = amount + lockedCredit;
        yieldTokenParams.distributedCredit     = 0;
        yieldTokenParams.lastDistributionBlock = block.number;
    }

    /// @dev Distributes unlocked credit for all of the yield tokens that have been deposited into the account owned
    ///      by `owner`.
    ///
    /// @param owner The address of the account owner.
    function _distributeUnlockedCreditDeposited(address owner) internal {
        Sets.AddressSet storage depositedTokens = _accounts[owner].depositedTokens;
        for (uint256 i = 0; i < depositedTokens.values.length; i++) {
            _distributeUnlockedCredit(depositedTokens.values[i]);
        }
    }

    /// @dev Distributes unlocked credit of `yieldToken` to all depositors.
    ///
    /// @param yieldToken The address of the yield token to distribute unlocked credit for.
    function _distributeUnlockedCredit(address yieldToken) internal {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 unlockedCredit = _calculateUnlockedCredit(yieldToken);
        if (unlockedCredit == 0) {
            return;
        }

        yieldTokenParams.accruedWeight     += unlockedCredit * FIXED_POINT_SCALAR / yieldTokenParams.totalShares;
        yieldTokenParams.distributedCredit += unlockedCredit;
    }

    /// @dev Wraps `amount` of an underlying token into its `yieldToken`.
    ///
    /// @param yieldToken       The address of the yield token to wrap the underlying tokens into.
    /// @param amount           The amount of the underlying token to wrap.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be received from the operation.
    ///
    /// @return The amount of yield tokens that resulted from the operation.
    function _wrap(
        address yieldToken,
        uint256 amount,
        uint256 minimumAmountOut
    ) internal returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        ITokenAdapter adapter = ITokenAdapter(yieldTokenParams.adapter);
        address underlyingToken = yieldTokenParams.underlyingToken;

        TokenUtils.safeTransferFrom(underlyingToken, msg.sender, address(this), amount);
        uint256 wrappedShares = adapter.wrap(amount, address(this));
        if (wrappedShares < minimumAmountOut) {
            revert SlippageExceeded(wrappedShares, minimumAmountOut);
        }

        return wrappedShares;
    }

    /// @dev Unwraps `amount` of `yieldToken` into its underlying token.
    ///
    /// @param yieldToken       The address of the yield token to unwrap.
    /// @param amount           The amount of the underlying token to wrap.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be received from the
    ///                         operation.
    ///
    /// @return The amount of underlying tokens that resulted from the operation.
    function _unwrap(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) internal returns (uint256) {
        ITokenAdapter adapter = ITokenAdapter(_yieldTokens[yieldToken].adapter);
        uint256 amountUnwrapped = adapter.unwrap(amount, recipient);
        if (amountUnwrapped < minimumAmountOut) {
            revert SlippageExceeded(amountUnwrapped, minimumAmountOut);
        }
        return amountUnwrapped;
    }

    /// @dev Synchronizes the state for all of the tokens deposited in the account owned by `owner`.
    ///
    /// @param owner The address of the account owner.
    function _poke(address owner) internal {
        Sets.AddressSet storage depositedTokens = _accounts[owner].depositedTokens;
        for (uint256 i = 0; i < depositedTokens.values.length; i++) {
            _poke(owner, depositedTokens.values[i]);
        }
    }

    /// @dev Synchronizes the state of `yieldToken` for the account owned by `owner`.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token to synchronize the state for.
    function _poke(address owner, address yieldToken) internal {
        Account storage account = _accounts[owner];

        uint256 currentAccruedWeight = _yieldTokens[yieldToken].accruedWeight;
        uint256 lastAccruedWeight    = account.lastAccruedWeights[yieldToken];

        if (currentAccruedWeight == lastAccruedWeight) {
            return;
        }

        uint256 balance          = account.balances[yieldToken];
        uint256 unrealizedCredit = (currentAccruedWeight - lastAccruedWeight) * balance / FIXED_POINT_SCALAR;

        account.debt                           -= SafeCast.toInt256(unrealizedCredit);
        account.lastAccruedWeights[yieldToken]  = currentAccruedWeight;
    }

    /// @dev Increases the debt by `amount` for the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount to increase the debt by.
    function _updateDebt(address owner, int256 amount) internal {
        Account storage account = _accounts[owner];
        account.debt += amount;
    }

    /// @dev Set the mint allowance for `spender` to `amount` for the account owned by `owner`.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address of the spender.
    /// @param amount  The amount of debt tokens to set the mint allowance to.
    function _approveMint(address owner, address spender, uint256 amount) internal {
        Account storage account = _accounts[owner];
        account.mintAllowances[spender] = amount;
        emit ApproveMint(owner, spender, amount);
    }

    /// @dev Decrease the mint allowance for `spender` by `amount` for the account owned by `owner`.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address of the spender.
    /// @param amount  The amount of debt tokens to decrease the mint allowance by.
    function _decreaseMintAllowance(address owner, address spender, uint256 amount) internal {
        Account storage account = _accounts[owner];
        account.mintAllowances[spender] -= amount;
    }

    /// @dev Set the withdraw allowance of `yieldToken` for `spender` to `shares` for the account owned by `owner`.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address of the spender.
    /// @param yieldToken The address of the yield token to set the withdraw allowance for.
    /// @param shares     The amount of shares to set the withdraw allowance to.
    function _approveWithdraw(address owner, address spender, address yieldToken, uint256 shares) internal {
        Account storage account = _accounts[owner];
        account.withdrawAllowances[spender][yieldToken] = shares;
        emit ApproveWithdraw(owner, spender, yieldToken, shares);
    }

    /// @dev Decrease the withdraw allowance of `yieldToken` for `spender` by `amount` for the account owned by `owner`.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address of the spender.
    /// @param yieldToken The address of the yield token to decrease the withdraw allowance for.
    /// @param amount     The amount of shares to decrease the withdraw allowance by.
    function _decreaseWithdrawAllowance(address owner, address spender, address yieldToken, uint256 amount) internal {
        Account storage account = _accounts[owner];
        account.withdrawAllowances[spender][yieldToken] -= amount;
    }

    /// @dev Checks that the account owned by `owner` is properly collateralized.
    ///
    /// @dev If the account is undercollateralized then this will revert with an {Undercollateralized} error.
    ///
    /// @param owner The address of the account owner.
    function _validate(address owner) internal view {
        int256 debt = _accounts[owner].debt;
        if (debt <= 0) {
            return;
        }

        uint256 collateralization = _totalValue(owner) * FIXED_POINT_SCALAR / uint256(debt);

        if (collateralization < minimumCollateralization) {
            revert Undercollateralized();
        }
    }

    /// @dev Gets the total value of the deposit collateral measured in debt tokens of the account owned by `owner`.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The total value.
    function _totalValue(address owner) internal view returns (uint256) {
        uint256 totalValue = 0;

        Sets.AddressSet storage depositedTokens = _accounts[owner].depositedTokens;
        for (uint256 i = 0; i < depositedTokens.values.length; i++) {
            address yieldToken             = depositedTokens.values[i];
            address underlyingToken        = _yieldTokens[yieldToken].underlyingToken;
            uint256 shares                 = _accounts[owner].balances[yieldToken];
            uint256 amountUnderlyingTokens = _convertSharesToUnderlyingTokens(yieldToken, shares);

            totalValue += _normalizeUnderlyingTokensToDebt(underlyingToken, amountUnderlyingTokens);
        }

        return totalValue;
    }

    /// @dev Issues shares of `yieldToken` for `amount` of its underlying token to `recipient`.
    ///
    /// IMPORTANT: `amount` must never be 0.
    ///
    /// @param recipient  The address of the recipient.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of the underlying token.
    ///
    /// @return The amount of shares issued to `recipient`.
    function _issueSharesForAmount(
        address recipient,
        address yieldToken,
        uint256 amount
    ) internal returns (uint256) {
        uint256 shares = _convertYieldTokensToShares(yieldToken, amount);

        if (_accounts[recipient].balances[yieldToken] == 0) {
          _accounts[recipient].depositedTokens.add(yieldToken);
        }

        _accounts[recipient].balances[yieldToken] += shares;
        _yieldTokens[yieldToken].totalShares += shares;

        return shares;
    }

    /// @dev Burns `share` shares of `yieldToken` from the account owned by `owner`.
    ///
    /// @param owner      The address of the owner.
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares to burn.
    function _burnShares(address owner, address yieldToken, uint256 shares) internal {
        Account storage account = _accounts[owner];

        account.balances[yieldToken] -= shares;
        _yieldTokens[yieldToken].totalShares -= shares;

        if (account.balances[yieldToken] == 0) {
            account.depositedTokens.remove(yieldToken);
        }
    }

    /// @dev Gets the amount of debt that the account owned by `owner` will have after an update occurs.
    ///
    /// @param owner The address of the account owner.
    ///
    /// @return The amount of debt that the account owned by `owner` will have after an update.
    function _calculateUnrealizedDebt(address owner) internal view returns (int256) {
        int256 debt = _accounts[owner].debt;

        Sets.AddressSet storage depositedTokens = _accounts[owner].depositedTokens;
        for (uint256 i = 0; i < depositedTokens.values.length; i++) {
            address yieldToken = depositedTokens.values[i];

            uint256 currentAccruedWeight = _yieldTokens[yieldToken].accruedWeight;
            uint256 lastAccruedWeight    = _accounts[owner].lastAccruedWeights[yieldToken];
            uint256 unlockedCredit       = _calculateUnlockedCredit(yieldToken);

            currentAccruedWeight += unlockedCredit > 0
                ? unlockedCredit * FIXED_POINT_SCALAR / _yieldTokens[yieldToken].totalShares
                : 0;

            if (currentAccruedWeight == lastAccruedWeight) {
                continue;
            }

            uint256 balance = _accounts[owner].balances[yieldToken];
            uint256 unrealizedCredit = ((currentAccruedWeight - lastAccruedWeight) * balance) / FIXED_POINT_SCALAR;

            debt -= SafeCast.toInt256(unrealizedCredit);
        }

        return debt;
    }

    /// @dev Gets the virtual active balance of `yieldToken`.
    ///
    /// @dev The virtual active balance is the active balance minus any harvestable tokens which have yet to be realized.
    ///
    /// @param yieldToken The address of the yield token to get the virtual active balance of.
    ///
    /// @return The virtual active balance.
    function _calculateUnrealizedActiveBalance(address yieldToken) internal view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 activeBalance = yieldTokenParams.activeBalance;
        if (activeBalance == 0) {
          return activeBalance;
        }

        uint256 currentValue = _convertYieldTokensToUnderlying(yieldToken, activeBalance);
        uint256 expectedValue = yieldTokenParams.expectedValue;
        if (currentValue <= expectedValue) {
          return activeBalance;
        }

        uint256 harvestable = _convertUnderlyingTokensToYield(yieldToken, currentValue - expectedValue);
        if (harvestable == 0) {
          return activeBalance;
        }

        return activeBalance - harvestable;
    }

    /// @dev Calculates the amount of unlocked credit for `yieldToken` that is available for distribution.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return The amount of unlocked credit available.
    function _calculateUnlockedCredit(address yieldToken) internal view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];

        uint256 pendingCredit = yieldTokenParams.pendingCredit;
        if (pendingCredit == 0) {
            return 0;
        }

        uint256 creditUnlockRate      = yieldTokenParams.creditUnlockRate;
        uint256 distributedCredit     = yieldTokenParams.distributedCredit;
        uint256 lastDistributionBlock = yieldTokenParams.lastDistributionBlock;

        uint256 percentUnlocked = (block.number - lastDistributionBlock) * creditUnlockRate;

        return percentUnlocked < FIXED_POINT_SCALAR
            ? (pendingCredit * percentUnlocked / FIXED_POINT_SCALAR) - distributedCredit
            : pendingCredit - distributedCredit;
    }

    /// @dev Gets the amount of shares that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The number of shares.
    function _convertYieldTokensToShares(address yieldToken, uint256 amount) internal view returns (uint256) {
        if (_yieldTokens[yieldToken].totalShares == 0) {
            return amount;
        }
        return amount * _yieldTokens[yieldToken].totalShares / _calculateUnrealizedActiveBalance(yieldToken);
    }

    /// @dev Gets the amount of yield tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return The amount of yield tokens.
    function _convertSharesToYieldTokens(address yieldToken, uint256 shares) internal view returns (uint256) {
        uint256 totalShares = _yieldTokens[yieldToken].totalShares;
        if (totalShares == 0) {
          return shares;
        }
        return (shares * _calculateUnrealizedActiveBalance(yieldToken)) / totalShares;
    }

    /// @dev Gets the amount of underlying tokens that `shares` shares of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param shares     The amount of shares.
    ///
    /// @return The amount of underlying tokens.
    function _convertSharesToUnderlyingTokens(address yieldToken, uint256 shares) internal view returns (uint256) {
        uint256 amountYieldTokens = _convertSharesToYieldTokens(yieldToken, shares);
        return _convertYieldTokensToUnderlying(yieldToken, amountYieldTokens);
    }

    /// @dev Gets the amount of an underlying token that `amount` of `yieldToken` is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of yield tokens.
    ///
    /// @return The amount of underlying tokens.
    function _convertYieldTokensToUnderlying(address yieldToken, uint256 amount) internal view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        ITokenAdapter adapter = ITokenAdapter(yieldTokenParams.adapter);
        return amount * adapter.price() / 10**yieldTokenParams.decimals;
    }

    /// @dev Gets the amount of `yieldToken` that `amount` of its underlying token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of underlying tokens.
    ///
    /// @return The amount of yield tokens.
    function _convertUnderlyingTokensToYield(address yieldToken, uint256 amount) internal view returns (uint256) {
        YieldTokenParams storage yieldTokenParams = _yieldTokens[yieldToken];
        ITokenAdapter adapter = ITokenAdapter(yieldTokenParams.adapter);
        return amount * 10**yieldTokenParams.decimals / adapter.price();
    }

    /// @dev Gets the amount of shares of `yieldToken` that `amount` of its underlying token is exchangeable for.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of underlying tokens.
    ///
    /// @return The amount of shares.
    function _convertUnderlyingTokensToShares(address yieldToken, uint256 amount) internal view returns (uint256) {
        uint256 amountYieldTokens = _convertUnderlyingTokensToYield(yieldToken, amount);
        return _convertYieldTokensToShares(yieldToken, amountYieldTokens);
    }

    /// @dev Normalize `amount` of `underlyingToken` to a value which is comparable to units of the debt token.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of the debt token.
    ///
    /// @return The normalized amount.
    function _normalizeUnderlyingTokensToDebt(address underlyingToken, uint256 amount) internal view returns (uint256) {
        return amount * _underlyingTokens[underlyingToken].conversionFactor;
    }

    /// @dev Normalize `amount` of the debt token to a value which is comparable to units of `underlyingToken`.
    ///
    /// @dev This operation will result in truncation of some of the least significant digits of `amount`. This
    ///      truncation amount will be the least significant N digits where N is the difference in decimals between
    ///      the debt token and the underlying token.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of the debt token.
    ///
    /// @return The normalized amount.
    function _normalizeDebtTokensToUnderlying(address underlyingToken, uint256 amount) internal view returns (uint256) {
        return amount / _underlyingTokens[underlyingToken].conversionFactor;
    }

    /// @dev Checks the whitelist for msg.sender.
    ///
    /// Reverts if msg.sender is not in the whitelist.
    function _onlyWhitelisted() internal view {
        // Check if the message sender is an EOA. In the future, this potentially may break. It is important that functions
        // which rely on the whitelist not be explicitly vulnerable in the situation where this no longer holds true.
        if (tx.origin == msg.sender) {
          return;
        }

        // Only check the whitelist for calls from contracts.
        if (!IWhitelist(whitelist).isWhitelisted(msg.sender)) {
          revert Unauthorized();
        }
    }

    /// @dev Checks an expression and reverts with an {IllegalArgument} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    function _checkArgument(bool expression) internal pure {
        if (!expression) {
            revert IllegalArgument();
        }
    }

    /// @dev Checks an expression and reverts with an {IllegalState} error if the expression is {false}.
    ///
    /// @param expression The expression to check.
    function _checkState(bool expression) internal pure {
        if (!expression) {
            revert IllegalState();
        }
    }

    /// @dev Adds two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z The result.
    function _uadd(uint256 x, uint256 y) internal pure returns (uint256 z) { z = x + y; }

    /// @dev Subtracts two unsigned 256 bit integers together and returns the result.
    ///
    /// @dev This operation is checked and will fail if the result overflows.
    ///
    /// @param x The first operand.
    /// @param y The second operand.
    ///
    /// @return z the result.
    function _usub(uint256 x, uint256 y) internal pure returns (uint256 z) { z = x - y; }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

pragma solidity ^0.8.11;

/// @notice An error used to indicate that an action could not be completed because either the `msg.sender` or
///         `msg.origin` is not authorized.
error Unauthorized();

/// @notice An error used to indicate that an action could not be completed because the contract either already existed
///         or entered an illegal condition which is not recoverable from.
error IllegalState();

/// @notice An error used to indicate that an action could not be completed because of an illegal argument was passed
///         to the function.
error IllegalArgument();

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

import "../interfaces/IMulticall.sol";

/// @title  Multicall
/// @author Uniswap Labs
///
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) external payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                revert MulticallFailed(data[i], result);
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.11;

/// @title  Mutex
/// @author Alchemix Finance
///
/// @notice Provides a mutual exclusion lock for implementing contracts.
abstract contract Mutex {
    /// @notice An error which is thrown when a lock is attempted to be claimed before it has been freed.
    error LockAlreadyClaimed();

    /// @notice The lock state. Non-zero values indicate the lock has been claimed.
    uint256 private _lockState;

    /// @dev A modifier which acquires the mutex.
    modifier lock() {
        _claimLock();

        _;

        _freeLock();
    }

    /// @dev Gets if the mutex is locked.
    ///
    /// @return if the mutex is locked.
    function _isLocked() internal returns (bool) {
        return _lockState == 1;
    }

    /// @dev Claims the lock. If the lock is already claimed, then this will revert.
    function _claimLock() internal {
        // Check that the lock has not been claimed yet.
        if (_lockState != 0) {
            revert LockAlreadyClaimed();
        }

        // Claim the lock.
        _lockState = 1;
    }

    /// @dev Frees the lock.
    function _freeLock() internal {
        _lockState = 0;
    }
}

pragma solidity >=0.5.0;

import "./alchemist/IAlchemistV2Actions.sol";
import "./alchemist/IAlchemistV2AdminActions.sol";
import "./alchemist/IAlchemistV2Errors.sol";
import "./alchemist/IAlchemistV2Immutables.sol";
import "./alchemist/IAlchemistV2Events.sol";
import "./alchemist/IAlchemistV2State.sol";

/// @title  IAlchemistV2
/// @author Alchemix Finance
interface IAlchemistV2 is
    IAlchemistV2Actions,
    IAlchemistV2AdminActions,
    IAlchemistV2Errors,
    IAlchemistV2Immutables,
    IAlchemistV2Events,
    IAlchemistV2State
{ }

pragma solidity >=0.5.0;

/// @title  IERC20Minimal
/// @author Alchemix Finance
interface IERC20Minimal {
    /// @notice An event which is emitted when tokens are transferred between two parties.
    ///
    /// @param owner     The owner of the tokens from which the tokens were transferred.
    /// @param recipient The recipient of the tokens to which the tokens were transferred.
    /// @param amount    The amount of tokens which were transferred.
    event Transfer(address indexed owner, address indexed recipient, uint256 amount);

    /// @notice An event which is emitted when an approval is made.
    ///
    /// @param owner   The address which made the approval.
    /// @param spender The address which is allowed to transfer tokens on behalf of `owner`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Gets the current total supply of tokens.
    ///
    /// @return The total supply.
    function totalSupply() external view returns (uint256);

    /// @notice Gets the balance of tokens that an account holds.
    ///
    /// @param account The account address.
    ///
    /// @return The balance of the account.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Gets the allowance that an owner has allotted for a spender.
    ///
    /// @param owner   The owner address.
    /// @param spender The spender address.
    ///
    /// @return The number of tokens that `spender` is allowed to transfer on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Transfers `amount` tokens from `msg.sender` to `recipient`.
    ///
    /// @notice Emits a {Transfer} event.
    ///
    /// @param recipient The address which will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Approves `spender` to transfer `amount` tokens on behalf of `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    ///
    /// @param spender The address which is allowed to transfer tokens on behalf of `msg.sender`.
    /// @param amount  The amount of tokens that `spender` is allowed to transfer.
    ///
    /// @return If the approval was successful.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `owner` to `recipient` using an approval that `owner` gave to `msg.sender`.
    ///
    /// @notice Emits a {Approval} event.
    /// @notice Emits a {Transfer} event.
    ///
    /// @param owner     The address to transfer tokens from.
    /// @param recipient The address that will receive the tokens.
    /// @param amount    The amount of tokens to transfer.
    ///
    /// @return If the transfer was successful.
    function transferFrom(address owner, address recipient, uint256 amount) external returns (bool);
}

pragma solidity >=0.5.0;

/// @title  IERC20TokenReceiver
/// @author Alchemix Finance
interface IERC20TokenReceiver {
    /// @notice Informs implementors of this interface that an ERC20 token has been transferred.
    ///
    /// @param token The token that was transferred.
    /// @param value The amount of the token that was transferred.
    function onERC20Received(address token, uint256 value) external;
}

pragma solidity >=0.5.0;

/// @title  ITokenAdapter
/// @author Alchemix Finance
interface ITokenAdapter {
    /// @notice Gets the current version.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Gets the address of the yield token that this adapter supports.
    ///
    /// @return The address of the yield token.
    function token() external view returns (address);

    /// @notice Gets the address of the underlying token that the yield token wraps.
    ///
    /// @return The address of the underlying token.
    function underlyingToken() external view returns (address);

    /// @notice Gets the number of underlying tokens that a single whole yield token is redeemable for.
    ///
    /// @return The price.
    function price() external view returns (uint256);

    /// @notice Wraps `amount` underlying tokens into the yield token.
    ///
    /// @param amount           The amount of the underlying token to wrap.
    /// @param recipient        The address which will receive the yield tokens.
    ///
    /// @return amountYieldTokens The amount of yield tokens minted to `recipient`.
    function wrap(uint256 amount, address recipient)
        external
        returns (uint256 amountYieldTokens);

    /// @notice Unwraps `amount` yield tokens into the underlying token.
    ///
    /// @param amount           The amount of yield-tokens to redeem.
    /// @param recipient        The recipient of the resulting underlying-tokens.
    ///
    /// @return amountUnderlyingTokens The amount of underlying tokens unwrapped to `recipient`.
    function unwrap(uint256 amount, address recipient)
        external
        returns (uint256 amountUnderlyingTokens);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.0;

import "./IERC20Burnable.sol";
import "./IERC20Minimal.sol";
import "./IERC20Mintable.sol";

/// @title  IAlchemicToken
/// @author Alchemix Finance
interface IAlchemicToken is IERC20Minimal, IERC20Burnable, IERC20Mintable {
  /// @notice Gets the total amount of minted tokens for an account.
  ///
  /// @param account The address of the account.
  ///
  /// @return The total minted.
  function hasMinted(address account) external view returns (uint256);

  /// @notice Lowers the number of tokens which the `msg.sender` has minted.
  ///
  /// This reverts if the `msg.sender` is not whitelisted.
  ///
  /// @param amount The amount to lower the minted amount by.
  function lowerHasMinted(uint256 amount) external;
}

pragma solidity ^0.8.11;

import "../base/Errors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/Sets.sol";

/// @title  Whitelist
/// @author Alchemix Finance
interface IWhitelist {
  /// @dev Emitted when a contract is added to the whitelist.
  ///
  /// @param account The account that was added to the whitelist.
  event AccountAdded(address account);

  /// @dev Emitted when a contract is removed from the whitelist.
  ///
  /// @param account The account that was removed from the whitelist.
  event AccountRemoved(address account);

  /// @dev Emitted when the whitelist is deactivated.
  event WhitelistDisabled();

  /// @dev Returns the list of addresses that are whitelisted for the given contract address.
  ///
  /// @return addresses The addresses that are whitelisted to interact with the given contract.
  function getAddresses() external view returns (address[] memory addresses);

  /// @dev Returns the disabled status of a given whitelist.
  ///
  /// @return disabled A flag denoting if the given whitelist is disabled.
  function disabled() external view returns (bool);

  /// @dev Adds an contract to the whitelist.
  ///
  /// @param caller The address to add to the whitelist.
  function add(address caller) external;

  /// @dev Adds a contract to the whitelist.
  ///
  /// @param caller The address to remove from the whitelist.
  function remove(address caller) external;

  /// @dev Disables the whitelist of the target whitelisted contract.
  ///
  /// This can only occur once. Once the whitelist is disabled, then it cannot be reenabled.
  function disable() external;

  /// @dev Checks that the `msg.sender` is whitelisted when it is not an EOA.
  ///
  /// @param account The account to check.
  ///
  /// @return whitelisted A flag denoting if the given account is whitelisted.
  function isWhitelisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IllegalArgument} from "../base/Errors.sol";

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
  /// @notice Cast a uint256 to a int256, revert on overflow
  /// @param y The uint256 to be casted
  /// @return z The casted integer, now type int256
  function toInt256(uint256 y) internal pure returns (int256 z) {
    if (y >= 2**255) {
      revert IllegalArgument();
    }
    z = int256(y);
  }

  /// @notice Cast a int256 to a uint256, revert on underflow
  /// @param y The int256 to be casted
  /// @return z The casted integer, now type uint256
  function toUint256(int256 y) internal pure returns (uint256 z) {
    if (y < 0) {
      revert IllegalArgument();
    }
    z = uint256(y);
  }
}

pragma solidity ^0.8.11;

/// @title  Sets
/// @author Alchemix Finance
library Sets {
    using Sets for AddressSet;

    /// @notice A data structure holding an array of values with an index mapping for O(1) lookup.
    struct AddressSet {
        address[] values;
        mapping(address => uint256) indexes;
    }

    /// @dev Add a value to a Set
    ///
    /// @param self  The Set.
    /// @param value The value to add.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value is already contained in the Set)
    function add(AddressSet storage self, address value) internal returns (bool) {
        if (self.contains(value)) {
            return false;
        }
        self.values.push(value);
        self.indexes[value] = self.values.length;
        return true;
    }

    /// @dev Remove a value from a Set
    ///
    /// @param self  The Set.
    /// @param value The value to remove.
    ///
    /// @return Whether the operation was successful (unsuccessful if the value was not contained in the Set)
    function remove(AddressSet storage self, address value) internal returns (bool) {
        uint256 index = self.indexes[value];
        if (index == 0) {
            return false;
        }

        // Normalize the index since we know that the element is in the set.
        index--;

        uint256 lastIndex = self.values.length - 1;

        if (index != lastIndex) {
            address lastValue = self.values[lastIndex];
            self.values[index] = lastValue;
            self.indexes[lastValue] = index + 1;
        }

        self.values.pop();

        delete self.indexes[value];

        return true;
    }

    /// @dev Returns true if the value exists in the Set
    ///
    /// @param self  The Set.
    /// @param value The value to check.
    ///
    /// @return True if the value is contained in the Set, False if it is not.
    function contains(AddressSet storage self, address value) internal view returns (bool) {
        return self.indexes[value] != 0;
    }
}

pragma solidity ^0.8.11;

import "../interfaces/IERC20Burnable.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IERC20Mintable.sol";

/// @title  TokenUtils
/// @author Alchemix Finance
library TokenUtils {
    /// @notice An error used to indicate that a call to an ERC20 contract failed.
    ///
    /// @param target  The target address.
    /// @param success If the call to the token was a success.
    /// @param data    The resulting data from the call. This is error data when the call was not a success. Otherwise,
    ///                this is malformed data when the call was a success.
    error ERC20CallFailed(address target, bool success, bytes data);

    /// @dev A safe function to get the decimals of an ERC20 token.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token The target token.
    ///
    /// @return The amount of decimals of the token.
    function expectDecimals(address token) internal view returns (uint8) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Metadata.decimals.selector)
        );

        if (!success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint8));
    }

    /// @dev Gets the balance of tokens held by an account.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the query fails or returns an unexpected value.
    ///
    /// @param token   The token to check the balance of.
    /// @param account The address of the token holder.
    ///
    /// @return The balance of the tokens held by an account.
    function safeBalanceOf(address token, address account) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, account)
        );

        if (!success || data.length < 32) {
            revert ERC20CallFailed(token, success, data);
        }

        return abi.decode(data, (uint256));
    }

    /// @dev Transfers tokens to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer failed or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransfer(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transfer.selector, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Approves tokens for the smart contract.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the approval fails or returns an unexpected value.
    ///
    /// @param token   The token to approve.
    /// @param spender The contract to spend the tokens.
    /// @param value   The amount of tokens to approve.
    function safeApprove(address token, address spender, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.approve.selector, spender, value)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Transfer tokens from one address to another address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the transfer fails or returns an unexpected value.
    ///
    /// @param token     The token to transfer.
    /// @param owner     The address of the owner.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to transfer.
    function safeTransferFrom(address token, address owner, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Minimal.transferFrom.selector, owner, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Mints tokens to an address.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the mint fails or returns an unexpected value.
    ///
    /// @param token     The token to mint.
    /// @param recipient The address of the recipient.
    /// @param amount    The amount of tokens to mint.
    function safeMint(address token, address recipient, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Mintable.mint.selector, recipient, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Burns tokens.
    ///
    /// Reverts with a `CallFailed` error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param amount The amount of tokens to burn.
    function safeBurn(address token, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burn.selector, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }

    /// @dev Burns tokens from its total supply.
    ///
    /// @dev Reverts with a {CallFailed} error if execution of the burn fails or returns an unexpected value.
    ///
    /// @param token  The token to burn.
    /// @param owner  The owner of the tokens.
    /// @param amount The amount of tokens to burn.
    function safeBurnFrom(address token, address owner, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20Burnable.burnFrom.selector, owner, amount)
        );

        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) {
            revert ERC20CallFailed(token, success, data);
        }
    }
}

pragma solidity ^0.8.11;

import {IllegalArgument} from "../base/Errors.sol";

/// @title  Functions
/// @author Alchemix Finance
library Limiters {
    using Limiters for LinearGrowthLimiter;

    /// @dev A maximum cooldown to avoid malicious governance bricking the contract.
    /// @dev 1 day @ 12 sec / block
    uint256 constant public MAX_COOLDOWN_BLOCKS = 7200;

    /// @dev The scalar used to convert integral types to fixed point numbers.
    uint256 constant public FIXED_POINT_SCALAR = 1e18;

    /// @dev The configuration and state of a linear growth function (LGF).
    struct LinearGrowthLimiter {
        uint256 maximum;        /// The maximum limit of the function.
        uint256 rate;           /// The rate at which the function increases back to its maximum.
        uint256 lastValue;      /// The most recently saved value of the function.
        uint256 lastBlock;      /// The block that `lastValue` was recorded.
        uint256 minLimit;       /// A minimum limit to avoid malicious governance bricking the contract
    }

    /// @dev Instantiates a new linear growth function.
    ///
    /// @param maximum The maximum value for the LGF.
    /// @param blocks  The number of blocks that determins the rate of the LGF.
    ///
    /// @return The LGF struct.
    function createLinearGrowthLimiter(uint256 maximum, uint256 blocks, uint256 _minLimit) internal view returns (LinearGrowthLimiter memory) {
        if (blocks > MAX_COOLDOWN_BLOCKS) {
            revert IllegalArgument();
        }

        if (maximum < _minLimit) {
            revert IllegalArgument();
        }

        return LinearGrowthLimiter({
            maximum: maximum,
            rate: maximum * FIXED_POINT_SCALAR / blocks,
            lastValue: maximum,
            lastBlock: block.number,
            minLimit: _minLimit
        });
    }

    /// @dev Configure an LGF.
    ///
    /// @param self    The LGF to configure.
    /// @param maximum The maximum value of the LFG.
    /// @param blocks  The number of recovery blocks of the LGF.
    function configure(LinearGrowthLimiter storage self, uint256 maximum, uint256 blocks) internal {
        if (blocks > MAX_COOLDOWN_BLOCKS) {
            revert IllegalArgument();
        }

        if (maximum < self.minLimit) {
            revert IllegalArgument();
        }

        if (self.lastValue > maximum) {
            self.lastValue = maximum;
        }

        self.maximum = maximum;
        self.rate = maximum * FIXED_POINT_SCALAR / blocks;
    }

    /// @dev Updates the state of an LGF by updating `lastValue` and `lastBlock`.
    ///
    /// @param self the LGF to update.
    function update(LinearGrowthLimiter storage self) internal {
        self.lastValue = self.get();
        self.lastBlock = block.number;
    }

    /// @dev Decrease the value of the linear growth limiter.
    ///
    /// @param self   The linear growth limiter.
    /// @param amount The amount to decrease `lastValue`.
    function decrease(LinearGrowthLimiter storage self, uint256 amount) internal {
        uint256 value = self.get();
        self.lastValue = value - amount;
        self.lastBlock = block.number;
    }

    /// @dev Get the current value of the linear growth limiter.
    ///
    /// @return The current value.
    function get(LinearGrowthLimiter storage self) internal view returns (uint256) {
        uint256 elapsed = block.number - self.lastBlock;
        if (elapsed == 0) {
            return self.lastValue;
        }
        uint256 delta = elapsed * self.rate / FIXED_POINT_SCALAR;
        uint256 value = self.lastValue + delta;
        return value > self.maximum ? self.maximum : value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title  Multicall interface
/// @author Uniswap Labs
///
/// @notice Enables calling multiple methods in a single call to the contract.
/// @dev    The use of `msg.value` should be heavily scrutinized for implementors of this interfaces.
interface IMulticall {
    /// @notice An error used to indicate that an individual call in a multicall failed.
    ///
    /// @param data   The call data.
    /// @param result The result of the call.
    error MulticallFailed(bytes data, bytes result);

    /// @notice Call multiple functions in the implementing contract.
    ///
    /// @param data The encoded function data for each of the calls to make to this contract.
    ///
    /// @return results The results from each of the calls passed in via data.
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Actions
/// @author Alchemix Finance
///
/// @notice Specifies user actions.
interface IAlchemistV2Actions {
    /// @notice Approve `spender` to mint `amount` debt tokens.
    ///
    /// **_NOTE:_** This function is WHITELISTED.
    ///
    /// @param spender The address that will be approved to mint.
    /// @param amount  The amount of tokens that `spender` will be allowed to mint.
    function approveMint(address spender, uint256 amount) external;

    /// @notice Approve `spender` to withdraw `amount` shares of `yieldToken`.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @param spender    The address that will be approved to withdraw.
    /// @param yieldToken The address of the yield token that `spender` will be allowed to withdraw.
    /// @param shares     The amount of shares that `spender` will be allowed to withdraw.
    function approveWithdraw(
        address spender,
        address yieldToken,
        uint256 shares
    ) external;

    /// @notice Synchronizes the state of the account owned by `owner`.
    ///
    /// @param owner The owner of the account to synchronize.
    function poke(address owner) external;

    /// @notice Deposit a yield token into a user's account.
    ///
    /// @notice An approval must be set for `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **_NOTE:_** When depositing, the `AlchemistV2` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **yieldToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amount = 50000;
    /// @notice IERC20(ydai).approve(alchemistAddress, amount);
    /// @notice AlchemistV2(alchemistAddress).deposit(ydai, amount, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The yield-token to deposit.
    /// @param amount     The amount of yield tokens to deposit.
    /// @param recipient  The owner of the account that will receive the resulting shares.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function deposit(
        address yieldToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 sharesIssued);

    /// @notice Deposit an underlying token into the account of `recipient` as `yieldToken`.
    ///
    /// @notice An approval must be set for the underlying token of `yieldToken` which is greater than `amount`.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or the call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Deposit} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** When depositing, the `AlchemistV2` contract must have **allowance()** to spend funds on behalf of **msg.sender** for at least **amount** of the **underlyingToken** being deposited.  This can be done via the standard `ERC20.approve()` method.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amount = 50000;
    /// @notice AlchemistV2(alchemistAddress).depositUnderlying(ydai, amount, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to wrap the underlying tokens into.
    /// @param amount           The amount of the underlying token to deposit.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of yield tokens that are expected to be deposited to `recipient`.
    ///
    /// @return sharesIssued The number of shares issued to `recipient`.
    function depositUnderlying(
        address yieldToken,
        uint256 amount,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesIssued);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares. The number of yield tokens withdrawn to `recipient` will depend on the value of shares for that yield token at the time of the call.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getYieldTokensPerShare(ydai);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdraw(ydai, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdraw(
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw yield tokens to `recipient` by burning `share` shares from the account of `owner`
    ///
    /// @notice `owner` must have an withdrawal allowance which is greater than `amount` for this call to succeed.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getYieldTokensPerShare(ydai);
    /// @notice uint256 amtYieldTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdrawFrom(msg.sender, ydai, amtYieldTokens / pps, msg.sender);
    /// @notice ```
    ///
    /// @param owner      The address of the account owner to withdraw from.
    /// @param yieldToken The address of the yield token to withdraw.
    /// @param shares     The number of shares to burn.
    /// @param recipient  The address of the recipient.
    ///
    /// @return amountWithdrawn The number of yield tokens that were withdrawn to `recipient`.
    function withdrawFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw underlying tokens to `recipient` by burning `share` shares and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `withdrawFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getUnderlyingTokensPerShare(ydai);
    /// @notice uint256 amountUnderlyingTokens = 5000;
    /// @notice AlchemistV2(alchemistAddress).withdrawUnderlying(ydai, amountUnderlyingTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of underlying tokens that were withdrawn to `recipient`.
    function withdrawUnderlying(
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Withdraw underlying tokens to `recipient` by burning `share` shares from the account of `owner` and unwrapping the yield tokens that the shares were redeemed for.
    ///
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    ///
    /// @notice Emits a {Withdraw} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `withdrawFrom()` must have **withdrawAllowance()** to withdraw funds on behalf of **owner** for at least the amount of `yieldTokens` that **shares** will be converted to.  This can be done via the `approveWithdraw()` or `permitWithdraw()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 pps = AlchemistV2(alchemistAddress).getUnderlyingTokensPerShare(ydai);
    /// @notice uint256 amtUnderlyingTokens = 5000 * 10**ydai.decimals();
    /// @notice AlchemistV2(alchemistAddress).withdrawUnderlying(msg.sender, ydai, amtUnderlyingTokens / pps, msg.sender, 1);
    /// @notice ```
    ///
    /// @param owner            The address of the account owner to withdraw from.
    /// @param yieldToken       The address of the yield token to withdraw.
    /// @param shares           The number of shares to burn.
    /// @param recipient        The address of the recipient.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    ///
    /// @return amountWithdrawn The number of underlying tokens that were withdrawn to `recipient`.
    function withdrawUnderlyingFrom(
        address owner,
        address yieldToken,
        uint256 shares,
        address recipient,
        uint256 minimumAmountOut
    ) external returns (uint256 amountWithdrawn);

    /// @notice Mint `amount` debt tokens.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Mint} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice AlchemistV2(alchemistAddress).mint(amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to mint.
    /// @param recipient The address of the recipient.
    function mint(uint256 amount, address recipient) external;

    /// @notice Mint `amount` debt tokens from the account owned by `owner` to `recipient`.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    ///
    /// @notice Emits a {Mint} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    /// @notice **_NOTE:_** The caller of `mintFrom()` must have **mintAllowance()** to mint debt from the `Account` controlled by **owner** for at least the amount of **yieldTokens** that **shares** will be converted to.  This can be done via the `approveMint()` or `permitMint()` methods.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtDebt = 5000;
    /// @notice AlchemistV2(alchemistAddress).mintFrom(msg.sender, amtDebt, msg.sender);
    /// @notice ```
    ///
    /// @param owner     The address of the owner of the account to mint from.
    /// @param amount    The amount of tokens to mint.
    /// @param recipient The address of the recipient.
    function mintFrom(
        address owner,
        uint256 amount,
        address recipient
    ) external;

    /// @notice Burn `amount` debt tokens to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must have non-zero debt or this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Burn} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice uint256 amtBurn = 5000;
    /// @notice AlchemistV2(alchemistAddress).burn(amtBurn, msg.sender);
    /// @notice ```
    ///
    /// @param amount    The amount of tokens to burn.
    /// @param recipient The address of the recipient.
    ///
    /// @return amountBurned The amount of tokens that were burned.
    function burn(uint256 amount, address recipient) external returns (uint256 amountBurned);

    /// @notice Repay `amount` debt using `underlyingToken` to credit the account owned by `recipient`.
    ///
    /// @notice `amount` will be limited up to the amount of debt that `recipient` currently holds.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `recipient` must be non-zero or this call will revert with an {IllegalArgument} error.
    /// @notice `underlyingToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `amount` must be less than or equal to the current available repay limit or this call will revert with a {ReplayLimitExceeded} error.
    ///
    /// @notice Emits a {Repay} event.
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address dai = 0x6b175474e89094c44da98b954eedeac495271d0f;
    /// @notice uint256 amtRepay = 5000;
    /// @notice AlchemistV2(alchemistAddress).repay(dai, amtRepay, msg.sender);
    /// @notice ```
    ///
    /// @param underlyingToken The address of the underlying token to repay.
    /// @param amount          The amount of the underlying token to repay.
    /// @param recipient       The address of the recipient which will receive credit.
    ///
    /// @return amountRepaid The amount of tokens that were repaid.
    function repay(
        address underlyingToken,
        uint256 amount,
        address recipient
    ) external returns (uint256 amountRepaid);

    /// @notice
    ///
    /// @notice `shares` will be limited up to an equal amount of debt that `recipient` currently holds.
    ///
    /// @notice `shares` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice `yieldToken` must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice `yieldToken` underlying token must be enabled or this call will revert with a {TokenDisabled} error.
    /// @notice The loss in expected value of `yieldToken` must be less than the maximum permitted by the system or this call will revert with a {LossExceeded} error.
    /// @notice `amount` must be less than or equal to the current available liquidation limit or this call will revert with a {LiquidationLimitExceeded} error.
    ///
    /// @notice Emits a {Liquidate} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amtSharesLiquidate = 5000 * 10**ydai.decimals();
    /// @notice AlchemistV2(alchemistAddress).liquidate(ydai, amtSharesLiquidate, 1);
    /// @notice ```
    ///
    /// @param yieldToken       The address of the yield token to liquidate.
    /// @param shares           The number of shares to burn for credit.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be liquidated.
    ///
    /// @return sharesLiquidated The amount of shares that were liquidated.
    function liquidate(
        address yieldToken,
        uint256 shares,
        uint256 minimumAmountOut
    ) external returns (uint256 sharesLiquidated);

    /// @notice Burns `amount` debt tokens to credit accounts which have deposited `yieldToken`.
    ///
    /// @notice `amount` must be greater than zero or this call will revert with a {IllegalArgument} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {Donate} event.
    ///
    /// @notice **_NOTE:_** This function is WHITELISTED.
    ///
    /// @notice **Example:**
    /// @notice ```
    /// @notice address ydai = 0xdA816459F1AB5631232FE5e97a05BBBb94970c95;
    /// @notice uint256 amtSharesLiquidate = 5000;
    /// @notice AlchemistV2(alchemistAddress).liquidate(dai, amtSharesLiquidate, 1);
    /// @notice ```
    ///
    /// @param yieldToken The address of the yield token to credit accounts for.
    /// @param amount     The amount of debt tokens to burn.
    function donate(address yieldToken, uint256 amount) external;

    /// @notice Harvests outstanding yield that a yield token has accumulated and distributes it as credit to holders.
    ///
    /// @notice `msg.sender` must be a keeper or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The amount being harvested must be greater than zero or else this call will revert with an {IllegalState} error.
    ///
    /// @notice Emits a {Harvest} event.
    ///
    /// @param yieldToken       The address of the yield token to harvest.
    /// @param minimumAmountOut The minimum amount of underlying tokens that are expected to be withdrawn to `recipient`.
    function harvest(address yieldToken, uint256 minimumAmountOut) external;
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2AdminActions
/// @author Alchemix Finance
///
/// @notice Specifies admin and or sentinel actions.
interface IAlchemistV2AdminActions {
    /// @notice Contract initialization parameters.
    struct InitializationParams {
        // The initial admin account.
        address admin;
        // The ERC20 token used to represent debt.
        address debtToken;
        // The initial transmuter or transmuter buffer.
        address transmuter;
        // The minimum collateralization ratio that an account must maintain.
        uint256 minimumCollateralization;
        // The percentage fee taken from each harvest measured in units of basis points.
        uint256 protocolFee;
        // The address that receives protocol fees.
        address protocolFeeReceiver;
        // A limit used to prevent administrators from making minting functionality inoperable.
        uint256 mintingLimitMinimum;
        // The maximum number of tokens that can be minted per period of time.
        uint256 mintingLimitMaximum;
        // The number of blocks that it takes for the minting limit to be refreshed.
        uint256 mintingLimitBlocks;
        // The address of the whitelist.
        address whitelist;
    }

    /// @notice Configuration parameters for an underlying token.
    struct UnderlyingTokenConfig {
        // A limit used to prevent administrators from making repayment functionality inoperable.
        uint256 repayLimitMinimum;
        // The maximum number of underlying tokens that can be repaid per period of time.
        uint256 repayLimitMaximum;
        // The number of blocks that it takes for the repayment limit to be refreshed.
        uint256 repayLimitBlocks;
        // A limit used to prevent administrators from making liquidation functionality inoperable.
        uint256 liquidationLimitMinimum;
        // The maximum number of underlying tokens that can be liquidated per period of time.
        uint256 liquidationLimitMaximum;
        // The number of blocks that it takes for the liquidation limit to be refreshed.
        uint256 liquidationLimitBlocks;
    }

    /// @notice Configuration parameters of a yield token.
    struct YieldTokenConfig {
        // The adapter used by the system to interop with the token.
        address adapter;
        // The maximum percent loss in expected value that can occur before certain actions are disabled measured in
        // units of basis points.
        uint256 maximumLoss;
        // The maximum value that can be held by the system before certain actions are disabled measured in the
        // underlying token.
        uint256 maximumExpectedValue;
        // The number of blocks that credit will be distributed over to depositors.
        uint256 creditUnlockBlocks;
    }

    /// @notice Initialize the contract.
    ///
    /// @notice `params.protocolFee` must be in range or this call will with an {IllegalArgument} error.
    /// @notice The minting growth limiter parameters must be valid or this will revert with an {IllegalArgument} error. For more information, see the {Limiters} library.
    ///
    /// @notice Emits an {AdminUpdated} event.
    /// @notice Emits a {TransmuterUpdated} event.
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    /// @notice Emits a {ProtocolFeeUpdated} event.
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    /// @notice Emits a {MintingLimitUpdated} event.
    ///
    /// @param params The contract initialization parameters.
    function initialize(InitializationParams memory params) external;

    /// @notice Sets the pending administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {PendingAdminUpdated} event.
    ///
    /// @dev This is the first step in the two-step process of setting a new administrator. After this function is called, the pending administrator will then need to call {acceptAdmin} to complete the process.
    ///
    /// @param value the address to set the pending admin to.
    function setPendingAdmin(address value) external;

    /// @notice Allows for `msg.sender` to accepts the role of administrator.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice The current pending administrator must be non-zero or this call will revert with an {IllegalState} error.
    ///
    /// @dev This is the second step in the two-step process of setting a new administrator. After this function is successfully called, this pending administrator will be reset and the new administrator will be set.
    ///
    /// @notice Emits a {AdminUpdated} event.
    /// @notice Emits a {PendingAdminUpdated} event.
    function acceptAdmin() external;

    /// @notice Sets an address as a sentinel.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param sentinel The address to set or unset as a sentinel.
    /// @param flag     A flag indicating of the address should be set or unset as a sentinel.
    function setSentinel(address sentinel, bool flag) external;

    /// @notice Sets an address as a keeper.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param keeper The address to set or unset as a keeper.
    /// @param flag   A flag indicating of the address should be set or unset as a keeper.
    function setKeeper(address keeper, bool flag) external;

    /// @notice Adds an underlying token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @param underlyingToken The address of the underlying token to add.
    /// @param config          The initial underlying token configuration.
    function addUnderlyingToken(
        address underlyingToken,
        UnderlyingTokenConfig calldata config
    ) external;

    /// @notice Adds a yield token to the system.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {AddYieldToken} event.
    /// @notice Emits a {TokenAdapterUpdated} event.
    /// @notice Emits a {MaximumLossUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to add.
    /// @param config     The initial yield token configuration.
    function addYieldToken(address yieldToken, YieldTokenConfig calldata config)
        external;

    /// @notice Sets an underlying token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits an {UnderlyingTokenEnabled} event.
    ///
    /// @param underlyingToken The address of the underlying token to enable or disable.
    /// @param enabled         If the underlying token should be enabled or disabled.
    function setUnderlyingTokenEnabled(address underlyingToken, bool enabled)
        external;

    /// @notice Sets a yield token as either enabled or disabled.
    ///
    /// @notice `msg.sender` must be either the admin or a sentinel or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {YieldTokenEnabled} event.
    ///
    /// @param yieldToken The address of the yield token to enable or disable.
    /// @param enabled    If the underlying token should be enabled or disabled.
    function setYieldTokenEnabled(address yieldToken, bool enabled) external;

    /// @notice Configures the the repay limit of `underlyingToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {ReplayLimitUpdated} event.
    ///
    /// @param underlyingToken The address of the underlying token to configure the repay limit of.
    /// @param maximum         The maximum repay limit.
    /// @param blocks          The number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    function configureRepayLimit(
        address underlyingToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Configure the liquidation limiter of `underlyingToken`.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `underlyingToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @notice Emits a {LiquidationLimitUpdated} event.
    ///
    /// @param underlyingToken The address of the underlying token to configure the liquidation limit of.
    /// @param maximum         The maximum liquidation limit.
    /// @param blocks          The number of blocks it will take for the maximum liquidation limit to be replenished when it is completely exhausted.
    function configureLiquidationLimit(
        address underlyingToken,
        uint256 maximum,
        uint256 blocks
    ) external;

    /// @notice Set the address of the transmuter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {TransmuterUpdated} event.
    ///
    /// @param value The address of the transmuter.
    function setTransmuter(address value) external;

    /// @notice Set the minimum collateralization ratio.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MinimumCollateralizationUpdated} event.
    ///
    /// @param value The new minimum collateralization ratio.
    function setMinimumCollateralization(uint256 value) external;

    /// @notice Sets the fee that the protocol will take from harvests.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be in range or this call will with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeUpdated} event.
    ///
    /// @param value The value to set the protocol fee to measured in basis points.
    function setProtocolFee(uint256 value) external;

    /// @notice Sets the address which will receive protocol fees.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `value` must be non-zero or this call will revert with an {IllegalArgument} error.
    ///
    /// @notice Emits a {ProtocolFeeReceiverUpdated} event.
    ///
    /// @param value The address to set the protocol fee receiver to.
    function setProtocolFeeReceiver(address value) external;

    /// @notice Configures the minting limiter.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    ///
    /// @notice Emits a {MintingLimitUpdated} event.
    ///
    /// @param maximum The maximum minting limit.
    /// @param blocks  The number of blocks it will take for the maximum minting limit to be replenished when it is completely exhausted.
    function configureMintingLimit(uint256 maximum, uint256 blocks) external;

    /// @notice Sets the rate at which credit will be completely available to depositors after it is harvested.
    ///
    /// @notice Emits a {CreditUnlockRateUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the credit unlock rate for.
    /// @param blocks     The number of blocks that it will take before the credit will be unlocked.
    function configureCreditUnlockRate(address yieldToken, uint256 blocks) external;

    /// @notice Sets the token adapter of a yield token.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    /// @notice The token that `adapter` supports must be `yieldToken` or this call will revert with a {IllegalState} error.
    ///
    /// @notice Emits a {TokenAdapterUpdated} event.
    ///
    /// @param yieldToken The address of the yield token to set the adapter for.
    /// @param adapter    The address to set the token adapter to.
    function setTokenAdapter(address yieldToken, address adapter) external;

    /// @notice Sets the maximum expected value of a yield token that the system can hold.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @param yieldToken The address of the yield token to set the maximum expected value for.
    /// @param value      The maximum expected value of the yield token denoted measured in its underlying token.
    function setMaximumExpectedValue(address yieldToken, uint256 value)
        external;

    /// @notice Sets the maximum loss that a yield bearing token will permit before restricting certain actions.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev There are two types of loss of value for yield bearing assets: temporary or permanent. The system will automatically restrict actions which are sensitive to both forms of loss when detected. For example, deposits must be restricted when an excessive loss is encountered to prevent users from having their collateral harvested from them. While the user would receive credit, which then could be exchanged for value equal to the collateral that was harvested from them, it is seen as a negative user experience because the value of their collateral should have been higher than what was originally recorded when they made their deposit.
    ///
    /// @param yieldToken The address of the yield bearing token to set the maximum loss for.
    /// @param value      The value to set the maximum loss to. This is in units of basis points.
    function setMaximumLoss(address yieldToken, uint256 value) external;

    /// @notice Snap the expected value `yieldToken` to the current value.
    ///
    /// @notice `msg.sender` must be the admin or this call will revert with an {Unauthorized} error.
    /// @notice `yieldToken` must be registered or this call will revert with a {UnsupportedToken} error.
    ///
    /// @dev This function should only be used in the event of a loss in the target yield-token. For example, say a third-party protocol experiences a fifty percent loss. The expected value (amount of underlying tokens) of the yield tokens being held by the system would be two times the real value that those yield tokens could be redeemed for. This function gives governance a way to realize those losses so that users can continue using the token as normal.
    ///
    /// @param yieldToken The address of the yield token to snap.
    function snap(address yieldToken) external;
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Errors
/// @author Alchemix Finance
///
/// @notice Specifies errors.
interface IAlchemistV2Errors {
    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that the system did not recognize.
    ///
    /// @param token The address of the token.
    error UnsupportedToken(address token);

    /// @notice An error which is used to indicate that an operation failed because it tried to operate on a token that has been disabled.
    ///
    /// @param token The address of the token.
    error TokenDisabled(address token);

    /// @notice An error which is used to indicate that an operation failed because an account became undercollateralized.
    error Undercollateralized();

    /// @notice An error which is used to indicate that an operation failed because the expected value of a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param expectedValue        The expected value measured in units of the underlying token.
    /// @param maximumExpectedValue The maximum expected value permitted measured in units of the underlying token.
    error ExpectedValueExceeded(address yieldToken, uint256 expectedValue, uint256 maximumExpectedValue);

    /// @notice An error which is used to indicate that an operation failed because the loss that a yield token in the system exceeds the maximum value permitted.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param loss        The amount of loss measured in basis points.
    /// @param maximumLoss The maximum amount of loss permitted measured in basis points.
    error LossExceeded(address yieldToken, uint256 loss, uint256 maximumLoss);

    /// @notice An error which is used to indicate that a minting operation failed because the minting limit has been exceeded.
    ///
    /// @param amount    The amount of debt tokens that were requested to be minted.
    /// @param available The amount of debt tokens which are available to mint.
    error MintingLimitExceeded(uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the repay limit for an underlying token has been exceeded.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of underlying tokens that were requested to be repaid.
    /// @param available       The amount of underlying tokens that are available to be repaid.
    error RepayLimitExceeded(address underlyingToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that an repay operation failed because the liquidation limit for an underlying token has been exceeded.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param amount          The amount of underlying tokens that were requested to be liquidated.
    /// @param available       The amount of underlying tokens that are available to be liquidated.
    error LiquidationLimitExceeded(address underlyingToken, uint256 amount, uint256 available);

    /// @notice An error which is used to indicate that the slippage of a wrap or unwrap operation was exceeded.
    ///
    /// @param amount           The amount of underlying or yield tokens returned by the operation.
    /// @param minimumAmountOut The minimum amount of the underlying or yield token that was expected when performing
    ///                         the operation.
    error SlippageExceeded(uint256 amount, uint256 minimumAmountOut);
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Immutables
/// @author Alchemix Finance
interface IAlchemistV2Immutables {
    /// @notice Returns the version of the alchemist.
    ///
    /// @return The version.
    function version() external view returns (string memory);

    /// @notice Returns the address of the debt token used by the system.
    ///
    /// @return The address of the debt token.
    function debtToken() external view returns (address);
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2Events
/// @author Alchemix Finance
interface IAlchemistV2Events {
    /// @notice Emitted when the pending admin is updated.
    ///
    /// @param pendingAdmin The address of the pending admin.
    event PendingAdminUpdated(address pendingAdmin);

    /// @notice Emitted when the administrator is updated.
    ///
    /// @param admin The address of the administrator.
    event AdminUpdated(address admin);

    /// @notice Emitted when an address is set or unset as a sentinel.
    ///
    /// @param sentinel The address of the sentinel.
    /// @param flag     A flag indicating if `sentinel` was set or unset as a sentinel.
    event SentinelSet(address sentinel, bool flag);

    /// @notice Emitted when an address is set or unset as a keeper.
    ///
    /// @param sentinel The address of the keeper.
    /// @param flag     A flag indicating if `keeper` was set or unset as a sentinel.
    event KeeperSet(address sentinel, bool flag);

    /// @notice Emitted when an underlying token is added.
    ///
    /// @param underlyingToken The address of the underlying token that was added.
    event AddUnderlyingToken(address indexed underlyingToken);

    /// @notice Emitted when a yield token is added.
    ///
    /// @param yieldToken The address of the yield token that was added.
    event AddYieldToken(address indexed yieldToken);

    /// @notice Emitted when an underlying token is enabled or disabled.
    ///
    /// @param underlyingToken The address of the underlying token that was enabled or disabled.
    /// @param enabled         A flag indicating if the underlying token was enabled or disabled.
    event UnderlyingTokenEnabled(address indexed underlyingToken, bool enabled);

    /// @notice Emitted when an yield token is enabled or disabled.
    ///
    /// @param yieldToken The address of the yield token that was enabled or disabled.
    /// @param enabled    A flag indicating if the yield token was enabled or disabled.
    event YieldTokenEnabled(address indexed yieldToken, bool enabled);

    /// @notice Emitted when the repay limit of an underlying token is updated.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param maximum         The updated maximum repay limit.
    /// @param blocks          The updated number of blocks it will take for the maximum repayment limit to be replenished when it is completely exhausted.
    event RepayLimitUpdated(address indexed underlyingToken, uint256 maximum, uint256 blocks);

    /// @notice Emitted when the liquidation limit of an underlying token is updated.
    ///
    /// @param underlyingToken The address of the underlying token.
    /// @param maximum         The updated maximum liquidation limit.
    /// @param blocks          The updated number of blocks it will take for the maximum liquidation limit to be replenished when it is completely exhausted.
    event LiquidationLimitUpdated(address indexed underlyingToken, uint256 maximum, uint256 blocks);

    /// @notice Emitted when the transmuter is updated.
    ///
    /// @param transmuter The updated address of the transmuter.
    event TransmuterUpdated(address transmuter);

    /// @notice Emitted when the minimum collateralization is updated.
    ///
    /// @param minimumCollateralization The updated minimum collateralization.
    event MinimumCollateralizationUpdated(uint256 minimumCollateralization);

    /// @notice Emitted when the protocol fee is updated.
    ///
    /// @param protocolFee The updated protocol fee.
    event ProtocolFeeUpdated(uint256 protocolFee);
    
    /// @notice Emitted when the protocol fee receiver is updated.
    ///
    /// @param protocolFeeReceiver The updated address of the protocol fee receiver.
    event ProtocolFeeReceiverUpdated(address protocolFeeReceiver);

    /// @notice Emitted when the minting limit is updated.
    ///
    /// @param maximum The updated maximum minting limit.
    /// @param blocks  The updated number of blocks it will take for the maximum minting limit to be replenished when it is completely exhausted.
    event MintingLimitUpdated(uint256 maximum, uint256 blocks);

    /// @notice Emitted when the credit unlock rate is updated.
    ///
    /// @param yieldToken The address of the yield token.
    /// @param blocks     The number of blocks that distributed credit will unlock over.
    event CreditUnlockRateUpdated(address yieldToken, uint256 blocks);

    /// @notice Emitted when the adapter of a yield token is updated.
    ///
    /// @param yieldToken   The address of the yield token.
    /// @param tokenAdapter The updated address of the token adapter.
    event TokenAdapterUpdated(address yieldToken, address tokenAdapter);

    /// @notice Emitted when the maximum expected value of a yield token is updated.
    ///
    /// @param yieldToken           The address of the yield token.
    /// @param maximumExpectedValue The updated maximum expected value.
    event MaximumExpectedValueUpdated(address indexed yieldToken, uint256 maximumExpectedValue);

    /// @notice Emitted when the maximum loss of a yield token is updated.
    ///
    /// @param yieldToken  The address of the yield token.
    /// @param maximumLoss The updated maximum loss.
    event MaximumLossUpdated(address indexed yieldToken, uint256 maximumLoss);

    /// @notice Emitted when the expected value of a yield token is snapped to its current value.
    ///
    /// @param yieldToken    The address of the yield token.
    /// @param expectedValue The updated expected value measured in the yield token's underlying token.
    event Snap(address indexed yieldToken, uint256 expectedValue);

    /// @notice Emitted when `owner` grants `spender` the ability to mint debt tokens on its behalf.
    ///
    /// @param owner   The address of the account owner.
    /// @param spender The address which is being permitted to mint tokens on the behalf of `owner`.
    /// @param amount  The amount of debt tokens that `spender` is allowed to mint.
    event ApproveMint(address indexed owner, address indexed spender, uint256 amount);

    /// @notice Emitted when `owner` grants `spender` the ability to withdraw `yieldToken` from its account.
    ///
    /// @param owner      The address of the account owner.
    /// @param spender    The address which is being permitted to mint tokens on the behalf of `owner`.
    /// @param yieldToken The address of the yield token that `spender` is allowed to withdraw.
    /// @param amount     The amount of shares of `yieldToken` that `spender` is allowed to withdraw.
    event ApproveWithdraw(address indexed owner, address indexed spender, address indexed yieldToken, uint256 amount);

    /// @notice Emitted when a user deposits `amount of `yieldToken` to `recipient`.
    ///
    /// @notice This event does not imply that `sender` directly deposited yield tokens. It is possible that the
    ///         underlying tokens were wrapped.
    ///
    /// @param sender       The address of the user which deposited funds.
    /// @param yieldToken   The address of the yield token that was deposited.
    /// @param amount       The amount of yield tokens that were deposited.
    /// @param recipient    The address that received the deposited funds.
    event Deposit(address indexed sender, address indexed yieldToken, uint256 amount, address recipient);

    /// @notice Emitted when `shares` shares of `yieldToken` are burned to withdraw `yieldToken` from the account owned
    ///         by `owner` to `recipient`.
    ///
    /// @notice This event does not imply that `recipient` received yield tokens. It is possible that the yield tokens
    ///         were unwrapped.
    ///
    /// @param owner      The address of the account owner.
    /// @param yieldToken The address of the yield token that was withdrawn.
    /// @param shares     The amount of shares that were burned.
    /// @param recipient  The address that received the withdrawn funds.
    event Withdraw(address indexed owner, address indexed yieldToken, uint256 shares, address recipient);

    /// @notice Emitted when `amount` debt tokens are minted to `recipient` using the account owned by `owner`.
    ///
    /// @param owner     The address of the account owner.
    /// @param amount    The amount of tokens that were minted.
    /// @param recipient The recipient of the minted tokens.
    event Mint(address indexed owner, uint256 amount, address recipient);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to `recipient`.
    ///
    /// @param sender    The address which is burning tokens.
    /// @param amount    The amount of tokens that were burned.
    /// @param recipient The address that received credit for the burned tokens.
    event Burn(address indexed sender, uint256 amount, address recipient);

    /// @notice Emitted when `amount` of `underlyingToken` are repaid to grant credit to `recipient`.
    ///
    /// @param sender          The address which is repaying tokens.
    /// @param underlyingToken The address of the underlying token that was used to repay debt.
    /// @param amount          The amount of the underlying token that was used to repay debt.
    /// @param recipient       The address that received credit for the repaid tokens.
    event Repay(address indexed sender, address indexed underlyingToken, uint256 amount, address recipient);

    /// @notice Emitted when `sender` liquidates `share` shares of `yieldToken`.
    ///
    /// @param owner           The address of the account owner liquidating shares.
    /// @param yieldToken      The address of the yield token.
    /// @param underlyingToken The address of the underlying token.
    /// @param shares          The amount of the shares of `yieldToken` that were liquidated.
    event Liquidate(address indexed owner, address indexed yieldToken, address indexed underlyingToken, uint256 shares);

    /// @notice Emitted when `sender` burns `amount` debt tokens to grant credit to users who have deposited `yieldToken`.
    ///
    /// @param sender     The address which burned debt tokens.
    /// @param yieldToken The address of the yield token.
    /// @param amount     The amount of debt tokens which were burned.
    event Donate(address indexed sender, address indexed yieldToken, uint256 amount);

    /// @notice Emitted when `yieldToken` is harvested.
    ///
    /// @param yieldToken     The address of the yield token that was harvested.
    /// @param minimumAmountOut    The maximum amount of loss that is acceptable when unwrapping the underlying tokens into yield tokens, measured in basis points.
    /// @param totalHarvested The total amount of underlying tokens harvested.
    event Harvest(address indexed yieldToken, uint256 minimumAmountOut, uint256 totalHarvested);
}

pragma solidity >=0.5.0;

/// @title  IAlchemistV2State
/// @author Alchemix Finance
interface IAlchemistV2State {
    /// @notice Defines underlying token parameters.
    struct UnderlyingTokenParams {
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // A coefficient used to normalize the token to a value comparable to the debt token. For example, if the
        // underlying token is 8 decimals and the debt token is 18 decimals then the conversion factor will be
        // 10^10. One unit of the underlying token will be comparably equal to one unit of the debt token.
        uint256 conversionFactor;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Defines yield token parameters.
    struct YieldTokenParams {
        // The number of decimals the token has. This value is cached once upon registering the token so it is important
        // that the decimals of the token are immutable or the system will begin to have computation errors.
        uint8 decimals;
        // The associated underlying token that can be redeemed for the yield-token.
        address underlyingToken;
        // The adapter used by the system to wrap, unwrap, and lookup the conversion rate of this token into its
        // underlying token.
        address adapter;
        // The maximum percentage loss that is acceptable before disabling certain actions.
        uint256 maximumLoss;
        // The maximum value of yield tokens that the system can hold, measured in units of the underlying token.
        uint256 maximumExpectedValue;
        // The percent of credit that will be unlocked per block. The representation of this value is a 18  decimal
        // fixed point integer.
        uint256 creditUnlockRate;
        // The current balance of yield tokens which are held by users.
        uint256 activeBalance;
        // The current balance of yield tokens which are earmarked to be harvested by the system at a later time.
        uint256 harvestableBalance;
        // The total number of shares that have been minted for this token.
        uint256 totalShares;
        // The expected value of the tokens measured in underlying tokens. This value controls how much of the token
        // can be harvested. When users deposit yield tokens, it increases the expected value by how much the tokens
        // are exchangeable for in the underlying token. When users withdraw yield tokens, it decreases the expected
        // value by how much the tokens are exchangeable for in the underlying token.
        uint256 expectedValue;
        // The current amount of credit which is will be distributed over time to depositors.
        uint256 pendingCredit;
        // The amount of the pending credit that has been distributed.
        uint256 distributedCredit;
        // The block number which the last credit distribution occurred.
        uint256 lastDistributionBlock;
        // The total accrued weight. This is used to calculate how much credit a user has been granted over time. The
        // representation of this value is a 18 decimal fixed point integer.
        uint256 accruedWeight;
        // A flag to indicate if the token is enabled.
        bool enabled;
    }

    /// @notice Gets the address of the admin.
    ///
    /// @return admin The admin address.
    function admin() external view returns (address admin);

    /// @notice Gets the address of the pending administrator.
    ///
    /// @return pendingAdmin The pending administrator address.
    function pendingAdmin() external view returns (address pendingAdmin);

    /// @notice Gets if an address is a sentinel.
    ///
    /// @param sentinel The address to check.
    ///
    /// @return isSentinel If the address is a sentinel.
    function sentinels(address sentinel) external view returns (bool isSentinel);

    /// @notice Gets if an address is a keeper.
    ///
    /// @param keeper The address to check.
    ///
    /// @return isKeeper If the address is a keeper
    function keepers(address keeper) external view returns (bool isKeeper);

    /// @notice Gets the address of the transmuter.
    ///
    /// @return transmuter The transmuter address.
    function transmuter() external view returns (address transmuter);

    /// @notice Gets the minimum collateralization.
    ///
    /// @notice Collateralization is determined by taking the total value of collateral that a user has deposited into their account and dividing it their debt.
    ///
    /// @dev The value returned is a 18 decimal fixed point integer.
    ///
    /// @return minimumCollateralization The minimum collateralization.
    function minimumCollateralization() external view returns (uint256 minimumCollateralization);

    /// @notice Gets the protocol fee.
    ///
    /// @return protocolFee The protocol fee.
    function protocolFee() external view returns (uint256 protocolFee);

    /// @notice Gets the protocol fee receiver.
    ///
    /// @return protocolFeeReceiver The protocol fee receiver.
    function protocolFeeReceiver() external view returns (address protocolFeeReceiver);

    /// @notice Gets the address of the whitelist contract.
    ///
    /// @return whitelist The address of the whitelist contract.
    function whitelist() external view returns (address whitelist);
    
    /// @notice Gets the conversion rate of underlying tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of underlying tokens per share.
    function getUnderlyingTokensPerShare(address yieldToken) external view returns (uint256 rate);

    /// @notice Gets the conversion rate of yield tokens per share.
    ///
    /// @param yieldToken The address of the yield token to get the conversion rate for.
    ///
    /// @return rate The rate of yield tokens per share.
    function getYieldTokensPerShare(address yieldToken) external view returns (uint256 rate);

    /// @notice Gets the supported underlying tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported underlying tokens.
    function getSupportedUnderlyingTokens() external view returns (address[] memory tokens);

    /// @notice Gets the supported yield tokens.
    ///
    /// @dev The order of the entries returned by this function is not guaranteed to be consistent between calls.
    ///
    /// @return tokens The supported yield tokens.
    function getSupportedYieldTokens() external view returns (address[] memory tokens);

    /// @notice Gets if an underlying token is supported.
    ///
    /// @param underlyingToken The address of the underlying token to check.
    ///
    /// @return isSupported If the underlying token is supported.
    function isSupportedUnderlyingToken(address underlyingToken) external view returns (bool isSupported);

    /// @notice Gets if a yield token is supported.
    ///
    /// @param yieldToken The address of the yield token to check.
    ///
    /// @return isSupported If the yield token is supported.
    function isSupportedYieldToken(address yieldToken) external view returns (bool isSupported);

    /// @notice Gets information about the account owned by `owner`.
    ///
    /// @param owner The address that owns the account.
    ///
    /// @return debt            The unrealized amount of debt that the account had incurred.
    /// @return depositedTokens The yield tokens that the owner has deposited.
    function accounts(address owner) external view returns (int256 debt, address[] memory depositedTokens);

    /// @notice Gets information about a yield token position for the account owned by `owner`.
    ///
    /// @param owner      The address that owns the account.
    /// @param yieldToken The address of the yield token to get the position of.
    ///
    /// @return shares            The amount of shares of that `owner` owns of the yield token.
    /// @return lastAccruedWeight The last recorded accrued weight of the yield token.
    function positions(address owner, address yieldToken)
        external view
        returns (
            uint256 shares,
            uint256 lastAccruedWeight
        );

    /// @notice Gets the amount of debt tokens `spender` is allowed to mint on behalf of `owner`.
    ///
    /// @param owner   The owner of the account.
    /// @param spender The address which is allowed to mint on behalf of `owner`.
    ///
    /// @return allowance The amount of debt tokens that `spender` can mint on behalf of `owner`.
    function mintAllowance(address owner, address spender) external view returns (uint256 allowance);

    /// @notice Gets the amount of shares of `yieldToken` that `spender` is allowed to withdraw on behalf of `owner`.
    ///
    /// @param owner      The owner of the account.
    /// @param spender    The address which is allowed to withdraw on behalf of `owner`.
    /// @param yieldToken The address of the yield token.
    ///
    /// @return allowance The amount of shares that `spender` can withdraw on behalf of `owner`.
    function withdrawAllowance(address owner, address spender, address yieldToken) external view returns (uint256 allowance);

    /// @notice Gets the parameters of an underlying token.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return params The underlying token parameters.
    function getUnderlyingTokenParameters(address underlyingToken)
        external view
        returns (UnderlyingTokenParams memory params);

    /// @notice Get the parameters and state of a yield-token.
    ///
    /// @param yieldToken The address of the yield token.
    ///
    /// @return params The yield token parameters.
    function getYieldTokenParameters(address yieldToken)
        external view
        returns (YieldTokenParams memory params);

    /// @notice Gets current limit, maximum, and rate of the minting limiter.
    ///
    /// @return currentLimit The current amount of debt tokens that can be minted.
    /// @return rate         The maximum possible amount of tokens that can be liquidated at a time.
    /// @return maximum      The highest possible maximum amount of debt tokens that can be minted at a time.
    function getMintLimitInfo()
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );

    /// @notice Gets current limit, maximum, and rate of a repay limiter for `underlyingToken`.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return currentLimit The current amount of underlying tokens that can be repaid.
    /// @return rate         The rate at which the the current limit increases back to its maximum in tokens per block.
    /// @return maximum      The maximum possible amount of tokens that can be repaid at a time.
    function getRepayLimitInfo(address underlyingToken)
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );

    /// @notice Gets current limit, maximum, and rate of the liquidation limiter for `underlyingToken`.
    ///
    /// @param underlyingToken The address of the underlying token.
    ///
    /// @return currentLimit The current amount of underlying tokens that can be liquidated.
    /// @return rate         The rate at which the function increases back to its maximum limit (tokens / block).
    /// @return maximum      The highest possible maximum amount of debt tokens that can be liquidated at a time.
    function getLiquidationLimitInfo(address underlyingToken)
        external view
        returns (
            uint256 currentLimit,
            uint256 rate,
            uint256 maximum
        );
}

pragma solidity >=0.5.0;

import "./IERC20Minimal.sol";

/// @title  IERC20Burnable
/// @author Alchemix Finance
interface IERC20Burnable is IERC20Minimal {
    /// @notice Burns `amount` tokens from the balance of `msg.sender`.
    ///
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burn(uint256 amount) external returns (bool);

    /// @notice Burns `amount` tokens from `owner`'s balance.
    ///
    /// @param owner  The address to burn tokens from.
    /// @param amount The amount of tokens to burn.
    ///
    /// @return If burning the tokens was successful.
    function burnFrom(address owner, uint256 amount) external returns (bool);
}

pragma solidity >=0.5.0;

import "./IERC20Minimal.sol";

/// @title  IERC20Mintable
/// @author Alchemix Finance
interface IERC20Mintable is IERC20Minimal {
    /// @notice Mints `amount` tokens to `recipient`.
    ///
    /// @param recipient The address which will receive the minted tokens.
    /// @param amount    The amount of tokens to mint.
    ///
    /// @return If minting the tokens was successful.
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

pragma solidity >=0.5.0;

/// @title  IERC20Metadata
/// @author Alchemix Finance
interface IERC20Metadata {
    /// @notice Gets the name of the token.
    ///
    /// @return The name.
    function name() external view returns (string memory);

    /// @notice Gets the symbol of the token.
    ///
    /// @return The symbol.
    function symbol() external view returns (string memory);

    /// @notice Gets the number of decimals that the token has.
    ///
    /// @return The number of decimals.
    function decimals() external view returns (uint8);
}