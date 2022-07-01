// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC4626, ERC20, SafeTransferLib } from "./base/ERC4626.sol";
import { Multicall } from "./base/Multicall.sol";
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { IAaveV2StablecoinCellar } from "./interfaces/IAaveV2StablecoinCellar.sol";
import { IAaveIncentivesController } from "./interfaces/IAaveIncentivesController.sol";
import { IStakedTokenV2 } from "./interfaces/IStakedTokenV2.sol";
import { ICurveSwaps } from "./interfaces/ICurveSwaps.sol";
import { ISushiSwapRouter } from "./interfaces/ISushiSwapRouter.sol";
import { IGravity } from "./interfaces/IGravity.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { Math } from "./utils/Math.sol";

import "./Errors.sol";

/**
 * @title Sommelier Aave V2 Stablecoin Cellar
 * @notice Dynamic ERC4626 that changes positions to always get the best yield for stablecoins on Aave.
 * @author Brian Le
 */
contract AaveV2StablecoinCellar is IAaveV2StablecoinCellar, ERC4626, Multicall, Ownable {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    // ======================================== POSITION STORAGE ========================================

    /**
     * @notice An interest-bearing derivative of the current asset returned by Aave for lending
     *         the current asset. Represents cellar's portion of assets earning yield in a lending
     *         position.
     */
    ERC20 public assetAToken;

    /**
     * @notice The decimals of precision used by the current position's asset.
     * @dev Since some stablecoins don't use the standard 18 decimals of precision (eg. USDC and USDT),
     *      we cache this to use for more efficient decimal conversions.
     */
    uint8 public assetDecimals;

    /**
     * @notice The total amount of assets held in the current position since the time of last accrual.
     * @dev Unlike `totalAssets`, this includes locked yield that hasn't been distributed.
     */
    uint256 public totalBalance;

    // ======================================== ACCRUAL CONFIG ========================================

    /**
     * @notice Period of time over which yield since the last accrual is linearly distributed to the cellar.
     * @dev Net gains are distributed gradually over a period to prevent frontrunning and sandwich attacks.
     *      Net losses are realized immediately otherwise users could time exits to sidestep losses.
     */
    uint32 public accrualPeriod = 7 days;

    /**
     * @notice Timestamp of when the last accrual occurred.
     */
    uint64 public lastAccrual;

    /**
     * @notice The amount of yield to be distributed to the cellar from the last accrual.
     */
    uint160 public maxLocked;

    /**
     * @notice The minimum level of total balance a strategy provider needs to achieve to receive
     *         performance fees for the next accrual.
     */
    uint256 public highWatermarkBalance;

    /**
     * @notice Set the accrual period over which yield is distributed.
     * @param newAccrualPeriod period of time in seconds of the new accrual period
     */
    function setAccrualPeriod(uint32 newAccrualPeriod) external onlyOwner {
        // Ensure that the change is not disrupting a currently ongoing distribution of accrued yield.
        if (totalLocked() > 0) revert STATE_AccrualOngoing();

        emit AccrualPeriodChanged(accrualPeriod, newAccrualPeriod);

        accrualPeriod = newAccrualPeriod;
    }

    // ========================================= FEES CONFIG =========================================

    /**
     *  @notice The percentage of yield accrued as performance fees.
     *  @dev This should be a value out of 1e18 (ie. 1e18 represents 100%, 0 represents 0%).
     */
    uint64 public constant platformFee = 0.0025e18; // 0.25%

    /**
     * @notice The percentage of total assets accrued as platform fees over a year.
     * @dev This should be a value out of 1e18 (ie. 1e18 represents 100%, 0 represents 0%).
     */
    uint64 public constant performanceFee = 0.1e18; // 10%

    /**
     * @notice Cosmos address of module that distributes fees, specified as a hex value.
     * @dev The Gravity contract expects a 32-byte value formatted in a specific way.
     */
    bytes32 public feesDistributor = hex"000000000000000000000000b813554b423266bbd4c16c32fa383394868c1f55";

    /**
     * @notice Set the address of the fee distributor on the Sommelier chain.
     * @dev IMPORTANT: Ensure that the address is formatted in the specific way that the Gravity contract
     *      expects it to be.
     * @param newFeesDistributor formatted address of the new fee distributor module
     */
    function setFeesDistributor(bytes32 newFeesDistributor) external onlyOwner {
        emit FeesDistributorChanged(feesDistributor, newFeesDistributor);

        feesDistributor = newFeesDistributor;
    }

    // ======================================== TRUST CONFIG ========================================

    /**
     * @notice Whether an asset position is trusted or not. Prevents cellar from rebalancing into an
     *         asset that has not been trusted by the users. Trusting / distrusting of an asset is done
     *         through governance.
     */
    mapping(ERC20 => bool) public isTrusted;

    /**
     * @notice Set the trust for a position.
     * @param position address of an asset position on Aave (eg. FRAX, UST, FEI).
     * @param trust whether to trust or distrust
     */
    function setTrust(ERC20 position, bool trust) external onlyOwner {
        isTrusted[position] = trust;

        // In the case that validators no longer trust the current position, pull all assets back
        // into the cellar.
        ERC20 currentPosition = asset;
        if (trust == false && position == currentPosition) _emptyPosition(currentPosition);

        emit TrustChanged(address(position), trust);
    }

    // ======================================== LIMITS CONFIG ========================================

    /**
     * @notice Maximum amount of assets that can be managed by the cellar. Denominated in the same decimals
     *         as the current asset.
     * @dev Set to `type(uint256).max` to have no limit.
     */
    uint256 public liquidityLimit;

    /**
     * @notice Maximum amount of assets per wallet. Denominated in the same decimals as the current asset.
     * @dev Set to `type(uint256).max` to have no limit.
     */
    uint256 public depositLimit;

    /**
     * @notice Set the maximum liquidity that cellar can manage. Uses the same decimals as the current asset.
     * @param newLimit amount of assets to set as the new limit
     */
    function setLiquidityLimit(uint256 newLimit) external onlyOwner {
        emit LiquidityLimitChanged(liquidityLimit, newLimit);

        liquidityLimit = newLimit;
    }

    /**
     * @notice Set the per-wallet deposit limit. Uses the same decimals as the current asset.
     * @param newLimit amount of assets to set as the new limit
     */
    function setDepositLimit(uint256 newLimit) external onlyOwner {
        emit DepositLimitChanged(depositLimit, newLimit);

        depositLimit = newLimit;
    }

    // ======================================== EMERGENCY LOGIC ========================================

    /**
     * @notice Whether or not the contract is shutdown in case of an emergency.
     */
    bool public isShutdown;

    /**
     * @notice Prevent a function from being called during a shutdown.
     */
    modifier whenNotShutdown() {
        if (isShutdown) revert STATE_ContractShutdown();

        _;
    }

    /**
     * @notice Shutdown the cellar. Used in an emergency or if the cellar has been deprecated.
     * @param emptyPosition whether to pull all assets back into the cellar from the current position
     */
    function initiateShutdown(bool emptyPosition) external whenNotShutdown onlyOwner {
        // Pull all assets from a position.
        if (emptyPosition) _emptyPosition(asset);

        isShutdown = true;

        emit ShutdownInitiated(emptyPosition);
    }

    /**
     * @notice Restart the cellar.
     */
    function liftShutdown() external onlyOwner {
        isShutdown = false;

        emit ShutdownLifted();
    }

    // ======================================== INITIALIZATION ========================================

    /**
     * @notice Curve Registry Exchange contract. Used for rebalancing positions.
     */
    ICurveSwaps public immutable curveRegistryExchange; // 0x81C46fECa27B31F3ADC2b91eE4be9717d1cd3DD7

    /**
     * @notice SushiSwap Router V2 contract. Used for reinvesting rewards back into the current position.
     */
    ISushiSwapRouter public immutable sushiswapRouter; // 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F

    /**
     * @notice Aave Lending Pool V2 contract. Used to deposit and withdraw from the current position.
     */
    ILendingPool public immutable lendingPool; // 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9

    /**
     * @notice Aave Incentives Controller V2 contract. Used to claim and unstake rewards to reinvest.
     */
    IAaveIncentivesController public immutable incentivesController; // 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5

    /**
     * @notice Cosmos Gravity Bridge contract. Used to transfer fees to `feeDistributor` on the Sommelier chain.
     */
    IGravity public immutable gravityBridge; // 0x69592e6f9d21989a043646fE8225da2600e5A0f7

    /**
     * @notice stkAAVE address. Used to swap rewards to the current asset to reinvest.
     */
    IStakedTokenV2 public immutable stkAAVE; // 0x4da27a545c0c5B758a6BA100e3a049001de870f5

    /**
     * @notice AAVE address. Used to swap rewards to the current asset to reinvest.
     */
    ERC20 public immutable AAVE; // 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9

    /**
     * @notice WETH address. Used to swap rewards to the current asset to reinvest.
     */
    ERC20 public immutable WETH; // 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2

    /**
     * @dev Owner will be set to the Gravity Bridge, which relays instructions from the Steward
     *      module to the cellars.
     *      https://github.com/PeggyJV/steward
     *      https://github.com/cosmos/gravity-bridge/blob/main/solidity/contracts/Gravity.sol
     * @param _asset current asset managed by the cellar
     * @param _approvedPositions list of approved positions to start with
     * @param _curveRegistryExchange Curve registry exchange
     * @param _sushiswapRouter Sushiswap V2 router address
     * @param _lendingPool Aave V2 lending pool address
     * @param _incentivesController _incentivesController
     * @param _gravityBridge Cosmos Gravity Bridge address
     * @param _stkAAVE stkAAVE address
     * @param _AAVE AAVE address
     * @param _WETH WETH address
     */
    constructor(
        ERC20 _asset,
        ERC20[] memory _approvedPositions,
        ICurveSwaps _curveRegistryExchange,
        ISushiSwapRouter _sushiswapRouter,
        ILendingPool _lendingPool,
        IAaveIncentivesController _incentivesController,
        IGravity _gravityBridge,
        IStakedTokenV2 _stkAAVE,
        ERC20 _AAVE,
        ERC20 _WETH
    ) ERC4626(_asset, "Sommelier Aave V2 Stablecoin Cellar LP Token", "aave2-CLR-S", 18) {
        // Initialize immutables.
        curveRegistryExchange = _curveRegistryExchange;
        sushiswapRouter = _sushiswapRouter;
        lendingPool = _lendingPool;
        incentivesController = _incentivesController;
        gravityBridge = _gravityBridge;
        stkAAVE = _stkAAVE;
        AAVE = _AAVE;
        WETH = _WETH;

        // Initialize asset.
        isTrusted[_asset] = true;
        uint8 _assetDecimals = _updatePosition(_asset);

        // Initialize limits.
        uint256 powOfAssetDecimals = 10**_assetDecimals;
        liquidityLimit = 5_000_000 * powOfAssetDecimals;
        depositLimit = type(uint256).max;

        // Initialize approved positions.
        for (uint256 i; i < _approvedPositions.length; i++) isTrusted[_approvedPositions[i]] = true;

        // Initialize starting timestamp for first accrual.
        lastAccrual = uint32(block.timestamp);

        // Transfer ownership to the Gravity Bridge.
        transferOwnership(address(_gravityBridge));
    }

    // ============================================ CORE LOGIC ============================================

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        // Check that the deposit is not restricted by a deposit limit or liquidity limit and
        // prevent deposits during a shutdown.
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) revert USR_DepositRestricted(assets, maxAssets);

        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        ERC20 cellarAsset = asset;
        uint256 assetsBeforeDeposit = cellarAsset.balanceOf(address(this));

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Check that the balance transferred is what was expected.
        uint256 assetsReceived = cellarAsset.balanceOf(address(this)) - assetsBeforeDeposit;
        if (assetsReceived != assets) revert STATE_AssetUsesFeeOnTransfer(address(cellarAsset));

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Check that the deposit is not restricted by a deposit limit or liquidity limit and
        // prevent deposits during a shutdown.
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) revert USR_DepositRestricted(assets, maxAssets);

        ERC20 cellarAsset = asset;
        uint256 assetsBeforeDeposit = cellarAsset.balanceOf(address(this));

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Check that the balance transferred is what was expected.
        uint256 assetsReceived = cellarAsset.balanceOf(address(this)) - assetsBeforeDeposit;
        if (assetsReceived != assets) revert STATE_AssetUsesFeeOnTransfer(address(cellarAsset));

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @dev Check if holding position has enough funds to cover the withdraw and only pull from the
     *      current lending position if needed.
     * @param assets amount of assets to withdraw
     */
    function beforeWithdraw(
        uint256 assets,
        uint256,
        address,
        address
    ) internal override {
        ERC20 currentPosition = asset;
        uint256 holdings = totalHoldings();

        // Only withdraw if not enough assets in the holding pool.
        if (assets > holdings) {
            uint256 withdrawnAssets = _withdrawFromPosition(currentPosition, assets - holdings);

            totalBalance -= withdrawnAssets;
            highWatermarkBalance -= withdrawnAssets;
        }
    }

    // ======================================= ACCOUNTING LOGIC =======================================

    /**
     * @notice The total amount of assets in the cellar.
     * @dev Excludes locked yield that hasn't been distributed.
     */
    function totalAssets() public view override returns (uint256) {
        return totalBalance + totalHoldings() - totalLocked();
    }

    /**
     * @notice The total amount of assets in holding position.
     */
    function totalHoldings() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
     * @notice The total amount of locked yield still being distributed.
     */
    function totalLocked() public view returns (uint256) {
        // Get the last accrual and accrual period.
        uint256 previousAccrual = lastAccrual;
        uint256 accrualInterval = accrualPeriod;

        // If the accrual period has passed, there is no locked yield.
        if (block.timestamp >= previousAccrual + accrualInterval) return 0;

        // Get the maximum amount we could return.
        uint256 maxLockedYield = maxLocked;

        // Get how much yield remains locked.
        return maxLockedYield - (maxLockedYield * (block.timestamp - previousAccrual)) / accrualInterval;
    }

    /**
     * @notice The amount of assets that the cellar would exchange for the amount of shares provided.
     * @param shares amount of shares to convert
     * @return assets the shares can be exchanged for
     */
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        uint256 totalShares = totalSupply;

        assets = totalShares == 0
            ? shares.changeDecimals(18, assetDecimals)
            : shares.mulDivDown(totalAssets(), totalShares);
    }

    /**
     * @notice The amount of shares that the cellar would exchange for the amount of assets provided.
     * @param assets amount of assets to convert
     * @return shares the assets can be exchanged for
     */
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        uint256 totalShares = totalSupply;

        shares = totalShares == 0
            ? assets.changeDecimals(assetDecimals, 18)
            : assets.mulDivDown(totalShares, totalAssets());
    }

    /**
     * @notice Simulate the effects of minting shares at the current block, given current on-chain conditions.
     * @param shares amount of shares to mint
     * @return assets that will be deposited
     */
    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        uint256 totalShares = totalSupply;

        assets = totalShares == 0
            ? shares.changeDecimals(18, assetDecimals)
            : shares.mulDivUp(totalAssets(), totalShares);
    }

    /**
     * @notice Simulate the effects of withdrawing assets at the current block, given current on-chain conditions.
     * @param assets amount of assets to withdraw
     * @return shares that will be redeemed
     */
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        uint256 totalShares = totalSupply;

        shares = totalShares == 0
            ? assets.changeDecimals(assetDecimals, 18)
            : assets.mulDivUp(totalShares, totalAssets());
    }

    // ========================================= LIMITS LOGIC =========================================

    /**
     * @notice Total amount of assets that can be deposited for a user.
     * @param receiver address of account that would receive the shares
     * @return assets maximum amount of assets that can be deposited
     */
    function maxDeposit(address receiver) public view override returns (uint256 assets) {
        if (isShutdown) return 0;

        uint256 asssetDepositLimit = depositLimit;
        uint256 asssetLiquidityLimit = liquidityLimit;
        if (asssetDepositLimit == type(uint256).max && asssetLiquidityLimit == type(uint256).max)
            return type(uint256).max;

        (uint256 leftUntilDepositLimit, uint256 leftUntilLiquidityLimit) = _getAssetsLeftUntilLimits(
            asssetDepositLimit,
            asssetLiquidityLimit,
            receiver
        );

        // Only return the more relevant of the two.
        assets = Math.min(leftUntilDepositLimit, leftUntilLiquidityLimit);
    }

    /**
     * @notice Total amount of shares that can be minted for a user.
     * @param receiver address of account that would receive the shares
     * @return shares maximum amount of shares that can be minted
     */
    function maxMint(address receiver) public view override returns (uint256 shares) {
        if (isShutdown) return 0;

        uint256 asssetDepositLimit = depositLimit;
        uint256 asssetLiquidityLimit = liquidityLimit;
        if (asssetDepositLimit == type(uint256).max && asssetLiquidityLimit == type(uint256).max)
            return type(uint256).max;

        (uint256 leftUntilDepositLimit, uint256 leftUntilLiquidityLimit) = _getAssetsLeftUntilLimits(
            asssetDepositLimit,
            asssetLiquidityLimit,
            receiver
        );

        // Only return the more relevant of the two.
        shares = convertToShares(Math.min(leftUntilDepositLimit, leftUntilLiquidityLimit));
    }

    function _getAssetsLeftUntilLimits(
        uint256 asssetDepositLimit,
        uint256 asssetLiquidityLimit,
        address receiver
    ) internal view returns (uint256 leftUntilDepositLimit, uint256 leftUntilLiquidityLimit) {
        uint256 totalAssetsIncludingUnrealizedGains = assetAToken.balanceOf(address(this)) + totalHoldings();

        // Convert receiver's shares to assets using total assets including locked yield.
        uint256 receiverShares = balanceOf[receiver];
        uint256 totalShares = totalSupply;
        uint256 maxWithdrawableByReceiver = totalShares == 0
            ? receiverShares
            : receiverShares.mulDivDown(totalAssetsIncludingUnrealizedGains, totalShares);

        // Get the maximum amount of assets that can be deposited until limits are reached.
        leftUntilDepositLimit = asssetDepositLimit.subMinZero(maxWithdrawableByReceiver);
        leftUntilLiquidityLimit = asssetLiquidityLimit.subMinZero(totalAssetsIncludingUnrealizedGains);
    }

    // ========================================== ACCRUAL LOGIC ==========================================

    /**
     * @notice Accrue yield, platform fees, and performance fees.
     * @dev Since this is the function responsible for distributing yield to shareholders and
     *      updating the cellar's balance, it is important to make sure it gets called regularly.
     */
    function accrue() public {
        uint256 totalLockedYield = totalLocked();

        // Without this check, malicious actors could do a slowdown attack on the distribution of
        // yield by continuously resetting the accrual period.
        if (msg.sender != owner() && totalLockedYield > 0) revert STATE_AccrualOngoing();

        // Compute and store current exchange rate between assets and shares for gas efficiency.
        uint256 oneAsset = 10**assetDecimals;
        uint256 exchangeRate = convertToShares(oneAsset);

        // Get balance since last accrual and updated balance for this accrual.
        uint256 balanceThisAccrual = assetAToken.balanceOf(address(this));

        // Calculate platform fees accrued.
        uint256 elapsedTime = block.timestamp - lastAccrual;
        uint256 platformFeeInAssets = (balanceThisAccrual * elapsedTime * platformFee) / 1e18 / 365 days;
        uint256 platformFees = platformFeeInAssets.mulDivDown(exchangeRate, oneAsset); // Convert to shares.

        // Calculate performance fees accrued.
        uint256 yield = balanceThisAccrual.subMinZero(highWatermarkBalance);
        uint256 performanceFeeInAssets = yield.mulWadDown(performanceFee);
        uint256 performanceFees = performanceFeeInAssets.mulDivDown(exchangeRate, oneAsset); // Convert to shares.

        // Mint accrued fees as shares.
        _mint(address(this), platformFees + performanceFees);

        // Do not count assets set aside for fees as yield. Allows fees to be immediately withdrawable.
        maxLocked = uint160(totalLockedYield + yield.subMinZero(platformFeeInAssets + performanceFeeInAssets));

        lastAccrual = uint32(block.timestamp);

        totalBalance = balanceThisAccrual;

        // Only update high watermark if balance greater than last high watermark.
        if (balanceThisAccrual > highWatermarkBalance) highWatermarkBalance = balanceThisAccrual;

        emit Accrual(platformFees, performanceFees, yield);
    }

    // ========================================= POSITION LOGIC =========================================

    /**
     * @notice Pushes assets into the current Aave lending position.
     * @param assets amount of assets to enter into the current position
     */
    function enterPosition(uint256 assets) public whenNotShutdown onlyOwner {
        ERC20 currentPosition = asset;

        totalBalance += assets;

        // Without this line, assets entered into Aave would be counted as gains during the next
        // accrual.
        highWatermarkBalance += assets;

        _depositIntoPosition(currentPosition, assets);

        emit EnterPosition(address(currentPosition), assets);
    }

    /**
     * @notice Pushes all assets in holding into the current Aave lending position.
     */
    function enterPosition() external {
        enterPosition(totalHoldings());
    }

    /**
     * @notice Pulls assets from the current Aave lending position.
     * @param assets amount of assets to exit from the current position
     */
    function exitPosition(uint256 assets) public whenNotShutdown onlyOwner {
        ERC20 currentPosition = asset;

        uint256 withdrawnAssets = _withdrawFromPosition(currentPosition, assets);

        totalBalance -= withdrawnAssets;

        // Without this line, assets exited from Aave would be counted as losses during the next
        // accrual.
        highWatermarkBalance -= withdrawnAssets;

        emit ExitPosition(address(currentPosition), assets);
    }

    /**
     * @notice Pulls all assets from the current Aave lending position.
     * @dev Strategy providers should not assume the position is empty after this call. If there is
     *      unrealized yield, that will still remain in the position. To completely empty the cellar,
     *      multicall accrue and this.
     */
    function exitPosition() external {
        exitPosition(totalBalance);
    }

    /**
     * @notice Rebalances current assets into a new position.
     * @param route array of [initial token, pool, token, pool, token, ...] that specifies the swap route on Curve.
     * @param swapParams multidimensional array of [i, j, swap type] where i and j are the correct
                         values for the n'th pool in `_route` and swap type should be 1 for a
                         stableswap `exchange`, 2 for stableswap `exchange_underlying`, 3 for a
                         cryptoswap `exchange`, 4 for a cryptoswap `exchange_underlying` and 5 for
                         Polygon factory metapools `exchange_underlying`
     * @param minAssetsOut minimum amount of assets received after swap
     */
    function rebalance(
        address[9] memory route,
        uint256[3][4] memory swapParams,
        uint256 minAssetsOut
    ) external whenNotShutdown onlyOwner {
        // Retrieve the last token in the route and store it as the new asset position.
        ERC20 newPosition;
        for (uint256 i; ; i += 2) {
            if (i == 8 || route[i + 1] == address(0)) {
                newPosition = ERC20(route[i]);
                break;
            }
        }

        // Ensure the asset position is trusted.
        if (!isTrusted[newPosition]) revert USR_UntrustedPosition(address(newPosition));

        ERC20 oldPosition = asset;

        // Doesn't make sense to rebalance into the same position.
        if (newPosition == oldPosition) revert USR_SamePosition(address(oldPosition));

        // Store this for later when updating total balance.
        uint256 totalAssetsInHolding = totalHoldings();
        uint256 totalBalanceIncludingHoldings = totalBalance + totalAssetsInHolding;

        // Pull any assets in the lending position back in to swap everything into the new position.
        uint256 assetsBeforeSwap = assetAToken.balanceOf(address(this)) > 0
            ? _withdrawFromPosition(oldPosition, type(uint256).max) + totalAssetsInHolding
            : totalAssetsInHolding;

        // Perform stablecoin swap using Curve.
        oldPosition.safeApprove(address(curveRegistryExchange), assetsBeforeSwap);
        uint256 assetsAfterSwap = curveRegistryExchange.exchange_multiple(
            route,
            swapParams,
            assetsBeforeSwap,
            minAssetsOut
        );

        uint8 oldPositionDecimals = assetDecimals;

        // Updates state for new position and check that Aave supports it.
        uint8 newPositionDecimals = _updatePosition(newPosition);

        // Deposit all newly swapped assets into Aave.
        _depositIntoPosition(newPosition, assetsAfterSwap);

        // Update maximum locked yield to scale accordingly to the decimals of the new asset.
        maxLocked = uint160(uint256(maxLocked).changeDecimals(oldPositionDecimals, newPositionDecimals));

        // Update the cellar's balance. If the unrealized gains before rebalancing exceed the losses
        // from the swap, then losses will be taken from the unrealized gains during next accrual
        // and this rebalance will not effect the exchange rate of shares to assets. Otherwise, the
        // losses from this rebalance will be realized and factored into the new balance.
        uint256 newTotalBalance = Math.min(
            totalBalanceIncludingHoldings.changeDecimals(oldPositionDecimals, newPositionDecimals),
            assetsAfterSwap
        );

        totalBalance = newTotalBalance;

        // Keep high watermark at level it should be at before rebalance because otherwise swap
        // losses from this rebalance would not be counted in the next accrual. Include holdings
        // into new high watermark balance as those have all been deposited into Aave now.
        highWatermarkBalance = (highWatermarkBalance + totalAssetsInHolding).changeDecimals(
            oldPositionDecimals,
            newPositionDecimals
        );

        emit Rebalance(address(oldPosition), address(newPosition), newTotalBalance);
    }

    // ======================================= REINVEST LOGIC =======================================

    /**
     * @notice Claim rewards from Aave and begin cooldown period to unstake them.
     * @return rewards amount of stkAAVE rewards claimed from Aave
     */
    function claimAndUnstake() external onlyOwner returns (uint256 rewards) {
        // Necessary to do as `claimRewards` accepts a dynamic array as first param.
        address[] memory aToken = new address[](1);
        aToken[0] = address(assetAToken);

        // Claim all stkAAVE rewards.
        rewards = incentivesController.claimRewards(aToken, type(uint256).max, address(this));

        // Begin the 10 day cooldown period for unstaking stkAAVE for AAVE.
        stkAAVE.cooldown();

        emit ClaimAndUnstake(rewards);
    }

    /**
     * @notice Reinvest rewards back into cellar's current position.
     * @dev Must be called within 2 day unstake period 10 days after `claimAndUnstake` was run.
     * @param minAssetsOut minimum amount of assets to receive after swapping AAVE to the current asset
     */
    function reinvest(uint256 minAssetsOut) external onlyOwner {
        // Redeems the cellar's stkAAVE rewards for AAVE.
        stkAAVE.redeem(address(this), type(uint256).max);

        // Get the amount of AAVE rewards going in to be swap for the current asset.
        uint256 rewardsIn = AAVE.balanceOf(address(this));

        ERC20 currentAsset = asset;

        // Specify the swap path from AAVE -> WETH -> current asset.
        address[] memory path = new address[](3);
        path[0] = address(AAVE);
        path[1] = address(WETH);
        path[2] = address(currentAsset);

        // Perform a multihop swap using Sushiswap.
        AAVE.safeApprove(address(sushiswapRouter), rewardsIn);
        uint256[] memory amounts = sushiswapRouter.swapExactTokensForTokens(
            rewardsIn,
            minAssetsOut,
            path,
            address(this),
            block.timestamp + 60
        );

        uint256 assetsOut = amounts[amounts.length - 1];

        // In the case of a shutdown, we just may want to redeem any leftover rewards for users to
        // claim but without entering them back into a position in case the position has been
        // exited. Also, for the purposes of performance fee calculation, we count reinvested
        // rewards as yield so do not update balance.
        if (!isShutdown) _depositIntoPosition(currentAsset, assetsOut);

        emit Reinvest(address(currentAsset), rewardsIn, assetsOut);
    }

    // ========================================= FEES LOGIC =========================================

    /**
     * @notice Transfer accrued fees to the Sommelier chain to distribute.
     * @dev Fees are accrued as shares and redeemed upon transfer.
     */
    function sendFees() external onlyOwner {
        // Redeem our fee shares for assets to send to the fee distributor module.
        uint256 totalFees = balanceOf[address(this)];
        uint256 assets = previewRedeem(totalFees);
        require(assets != 0, "ZERO_ASSETS");

        // Only withdraw assets from position if the holding position does not contain enough funds.
        // Pass in only the amount of assets withdrawn, the rest doesn't matter.
        beforeWithdraw(assets, 0, address(0), address(0));

        _burn(address(this), totalFees);

        // Transfer assets to a fee distributor on the Sommelier chain.
        ERC20 positionAsset = asset;
        positionAsset.safeApprove(address(gravityBridge), assets);
        gravityBridge.sendToCosmos(address(positionAsset), feesDistributor, assets);

        emit SendFees(totalFees, assets);
    }

    // ====================================== RECOVERY LOGIC ======================================

    /**
     * @notice Sweep tokens that are not suppose to be in the cellar.
     * @dev This may be used in case the wrong tokens are accidentally sent.
     * @param token address of token to transfer out of this cellar
     * @param to address to transfer sweeped tokens to
     */
    function sweep(ERC20 token, address to) external onlyOwner {
        // Prevent sweeping of assets managed by the cellar and shares minted to the cellar as fees.
        if (token == asset || token == assetAToken || token == this || address(token) == address(stkAAVE))
            revert USR_ProtectedAsset(address(token));

        // Transfer out tokens in this cellar that shouldn't be here.
        uint256 amount = token.balanceOf(address(this));
        token.safeTransfer(to, amount);

        emit Sweep(address(token), to, amount);
    }

    // ===================================== HELPER FUNCTIONS =====================================

    /**
     * @notice Deposits cellar holdings into an Aave lending position.
     * @param position the address of the asset position
     * @param assets the amount of assets to deposit
     */
    function _depositIntoPosition(ERC20 position, uint256 assets) internal {
        // Deposit assets into Aave position.
        position.safeApprove(address(lendingPool), assets);
        lendingPool.deposit(address(position), assets, address(this), 0);

        emit DepositIntoPosition(address(position), assets);
    }

    /**
     * @notice Withdraws assets from an Aave lending position.
     * @dev The assets withdrawn differs from the assets specified if withdrawing `type(uint256).max`.
     * @param position the address of the asset position
     * @param assets amount of assets to withdraw
     * @return withdrawnAssets amount of assets actually withdrawn
     */
    function _withdrawFromPosition(ERC20 position, uint256 assets) internal returns (uint256 withdrawnAssets) {
        // Withdraw assets from Aave position.
        withdrawnAssets = lendingPool.withdraw(address(position), assets, address(this));

        emit WithdrawFromPosition(address(position), withdrawnAssets);
    }

    /**
     * @notice Pull all assets from the current lending position on Aave back into holding.
     * @param position the address of the asset position to pull from
     */
    function _emptyPosition(ERC20 position) internal {
        uint256 totalPositionBalance = totalBalance;

        if (totalPositionBalance > 0) {
            accrue();

            _withdrawFromPosition(position, type(uint256).max);

            delete totalBalance;
            delete highWatermarkBalance;
        }
    }

    /**
     * @notice Update state variables related to the current position.
     * @dev Be aware that when updating to an asset that uses less decimals than the previous
     *      asset (eg. DAI -> USDC), `depositLimit` and `liquidityLimit` will lose some precision
     *      due to truncation.
     * @param newPosition address of the new asset being managed by the cellar
     */
    function _updatePosition(ERC20 newPosition) internal returns (uint8 newAssetDecimals) {
        // Retrieve the aToken that will represent the cellar's new position on Aave.
        (, , , , , , , address aTokenAddress, , , , ) = lendingPool.getReserveData(address(newPosition));

        // If the address is not null, it is supported by Aave.
        if (aTokenAddress == address(0)) revert USR_UnsupportedPosition(address(newPosition));

        // Update the decimals used by limits if necessary.
        uint8 oldAssetDecimals = assetDecimals;
        newAssetDecimals = newPosition.decimals();

        // Ensure the decimals of precision of the new position uses will not break the cellar.
        if (newAssetDecimals > 18) revert USR_TooManyDecimals(newAssetDecimals, 18);

        // Ignore if decimals are the same or if it is the first time initializing a position.
        if (oldAssetDecimals != 0 && oldAssetDecimals != newAssetDecimals) {
            uint256 asssetDepositLimit = depositLimit;
            uint256 asssetLiquidityLimit = liquidityLimit;
            if (asssetDepositLimit != type(uint256).max)
                depositLimit = asssetDepositLimit.changeDecimals(oldAssetDecimals, newAssetDecimals);

            if (asssetLiquidityLimit != type(uint256).max)
                liquidityLimit = asssetLiquidityLimit.changeDecimals(oldAssetDecimals, newAssetDecimals);
        }

        // Update state related to the current position.
        asset = newPosition;
        assetDecimals = newAssetDecimals;
        assetAToken = ERC20(aTokenAddress);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { Math } from "../utils/Math.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares, receiver, owner);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(assets, shares, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares, receiver, owner);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(assets, shares, receiver, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeDeposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual {}

    function afterDeposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual {}

    function beforeWithdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual {}

    function afterWithdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { IMulticall } from "../interfaces/IMulticall.sol";

/**
 * @title Multicall
 * @notice Enables calling multiple methods in a single call to the contract
 * From: https://github.com/Uniswap/v3-periphery/contracts/base/Multicall.sol
 */
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable-next-line reason-string
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { IAaveIncentivesController } from "../interfaces/IAaveIncentivesController.sol";
import { IStakedTokenV2 } from "../interfaces/IStakedTokenV2.sol";
import { ICurveSwaps } from "../interfaces/ICurveSwaps.sol";
import { ISushiSwapRouter } from "../interfaces/ISushiSwapRouter.sol";
import { ILendingPool } from "../interfaces/ILendingPool.sol";
import { IGravity } from "../interfaces/IGravity.sol";

/**
 * @title Interface for AaveV2StablecoinCellar
 */
interface IAaveV2StablecoinCellar {
    // ======================================== POSITION STORAGE ========================================

    function assetAToken() external view returns (ERC20);

    function assetDecimals() external view returns (uint8);

    function totalBalance() external view returns (uint256);

    // ========================================= ACCRUAL CONFIG =========================================

    /**
     * @notice Emitted when accrual period is changed.
     * @param oldPeriod time the period was changed from
     * @param newPeriod time the period was changed to
     */
    event AccrualPeriodChanged(uint32 oldPeriod, uint32 newPeriod);

    function accrualPeriod() external view returns (uint32);

    function lastAccrual() external view returns (uint64);

    function maxLocked() external view returns (uint160);

    function setAccrualPeriod(uint32 newAccrualPeriod) external;

    // =========================================== FEES CONFIG ===========================================

    /**
     * @notice Emitted when platform fees is changed.
     * @param oldPlatformFee value platform fee was changed from
     * @param newPlatformFee value platform fee was changed to
     */
    event PlatformFeeChanged(uint64 oldPlatformFee, uint64 newPlatformFee);

    /**
     * @notice Emitted when performance fees is changed.
     * @param oldPerformanceFee value performance fee was changed from
     * @param newPerformanceFee value performance fee was changed to
     */
    event PerformanceFeeChanged(uint64 oldPerformanceFee, uint64 newPerformanceFee);

    /**
     * @notice Emitted when fees distributor is changed.
     * @param oldFeesDistributor address of fee distributor was changed from
     * @param newFeesDistributor address of fee distributor was changed to
     */
    event FeesDistributorChanged(bytes32 oldFeesDistributor, bytes32 newFeesDistributor);

    function platformFee() external view returns (uint64);

    function performanceFee() external view returns (uint64);

    function feesDistributor() external view returns (bytes32);

    function setFeesDistributor(bytes32 newFeesDistributor) external;

    // ======================================== TRUST CONFIG ========================================

    /**
     * @notice Emitted when trust for a position is changed.
     * @param position address of the position that trust was changed for
     * @param trusted whether the position was trusted or untrusted
     */
    event TrustChanged(address indexed position, bool trusted);

    function isTrusted(ERC20) external view returns (bool);

    function setTrust(ERC20 position, bool trust) external;

    // ======================================== LIMITS CONFIG ========================================

    /**
     * @notice Emitted when the liquidity limit is changed.
     * @param oldLimit amount the limit was changed from
     * @param newLimit amount the limit was changed to
     */
    event LiquidityLimitChanged(uint256 oldLimit, uint256 newLimit);

    /**
     * @notice Emitted when the deposit limit is changed.
     * @param oldLimit amount the limit was changed from
     * @param newLimit amount the limit was changed to
     */
    event DepositLimitChanged(uint256 oldLimit, uint256 newLimit);

    function liquidityLimit() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function setLiquidityLimit(uint256 newLimit) external;

    function setDepositLimit(uint256 newLimit) external;

    // ======================================== EMERGENCY LOGIC ========================================

    /**
     * @notice Emitted when cellar is shutdown.
     * @param emptyPositions whether the current position(s) was exited
     */
    event ShutdownInitiated(bool emptyPositions);

    /**
     * @notice Emitted when shutdown is lifted.
     */
    event ShutdownLifted();

    function isShutdown() external view returns (bool);

    function initiateShutdown(bool emptyPosition) external;

    function liftShutdown() external;

    // ========================================== IMMUTABLES ==========================================

    function curveRegistryExchange() external view returns (ICurveSwaps);

    function sushiswapRouter() external view returns (ISushiSwapRouter);

    function lendingPool() external view returns (ILendingPool);

    function incentivesController() external view returns (IAaveIncentivesController);

    function gravityBridge() external view returns (IGravity);

    function stkAAVE() external view returns (IStakedTokenV2);

    function AAVE() external view returns (ERC20);

    function WETH() external view returns (ERC20);

    // ======================================= ACCOUNTING LOGIC =======================================

    function totalHoldings() external view returns (uint256);

    function totalLocked() external view returns (uint256);

    // ======================================== ACCRUAL LOGIC ========================================

    /**
     * @notice Emitted on accruals.
     * @param platformFees amount of shares minted as platform fees this accrual
     * @param performanceFees amount of shares minted as performance fees this accrual
     * @param yield amount of assets accrued as yield that will be distributed over this accrual period
     */
    event Accrual(uint256 platformFees, uint256 performanceFees, uint256 yield);

    /**
     * @notice Accrue yield, platform fees, and performance fees.
     * @dev Since this is the function responsible for distributing yield to shareholders and
     *      updating the cellar's balance, it is important to make sure it gets called regularly.
     */
    function accrue() external;

    // ========================================= POSITION LOGIC =========================================
    /**
     * @notice Emitted on deposit to Aave.
     * @param position the address of the position
     * @param assets the amount of assets to deposit
     */
    event DepositIntoPosition(address indexed position, uint256 assets);

    /**
     * @notice Emitted on withdraw from Aave.
     * @param position the address of the position
     * @param assets the amount of assets to withdraw
     */
    event WithdrawFromPosition(address indexed position, uint256 assets);

    /**
     * @notice Emitted upon entering assets into the current position on Aave.
     * @param position the address of the asset being pushed into the current position
     * @param assets amount of assets being pushed
     */
    event EnterPosition(address indexed position, uint256 assets);

    /**
     * @notice Emitted upon exiting assets from the current position on Aave.
     * @param position the address of the asset being pulled from the current position
     * @param assets amount of assets being pulled
     */
    event ExitPosition(address indexed position, uint256 assets);

    /**
     * @notice Emitted on rebalance of Aave poisition.
     * @param oldAsset the address of the asset for the old position
     * @param newAsset the address of the asset for the new position
     * @param assets the amount of the new assets cellar has after rebalancing
     */
    event Rebalance(address indexed oldAsset, address indexed newAsset, uint256 assets);

    function enterPosition() external;

    function enterPosition(uint256 assets) external;

    function exitPosition() external;

    function exitPosition(uint256 assets) external;

    function rebalance(
        address[9] memory route,
        uint256[3][4] memory swapParams,
        uint256 minAssetsOut
    ) external;

    // ========================================= REINVEST LOGIC =========================================

    /**
     * @notice Emitted upon claiming rewards and beginning cooldown period to unstake them.
     * @param rewards amount of rewards that were claimed
     */
    event ClaimAndUnstake(uint256 rewards);

    /**
     * @notice Emitted upon reinvesting rewards into the current position.
     * @param token the address of the asset rewards were swapped to
     * @param rewards amount of rewards swapped to be reinvested
     * @param assets amount of assets received from swapping rewards
     */
    event Reinvest(address indexed token, uint256 rewards, uint256 assets);

    function claimAndUnstake() external returns (uint256 rewards);

    function reinvest(uint256 minAssetsOut) external;

    // =========================================== FEES LOGIC ===========================================

    /**
     * @notice Emitted when platform fees are send to the Sommelier chain.
     * @param feesInSharesRedeemed amount of fees redeemed for assets to send
     * @param feesInAssetsSent amount of assets fees were redeemed for that were sent
     */
    event SendFees(uint256 feesInSharesRedeemed, uint256 feesInAssetsSent);

    function sendFees() external;

    // ========================================= RECOVERY LOGIC =========================================

    /**
     * @notice Emitted when tokens accidentally sent to cellar are recovered.
     * @param token the address of the token
     * @param to the address sweeped tokens were transferred to
     * @param amount amount transferred out
     */
    event Sweep(address indexed token, address indexed to, uint256 amount);

    function sweep(ERC20 token, address to) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

interface IAaveIncentivesController {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(address indexed user, address indexed to, address indexed claimer, uint256 amount);

    event ClaimerSet(address indexed user, address indexed claimer);

    /*
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /*
     * LEGACY **************************
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond) external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating
     * the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @param asset The asset to incentivize
     * @return the user index for the asset
     */
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function PRECISION() external view returns (uint8);

    /**
     * @dev Gets the distribution end timestamp of the emissions
     */
    function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.15;

interface IStakedTokenV2 {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function stakersCooldowns(address account) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

/**
 * @notice Partial interface for a Curve Registry Exchanges contract
 * @dev The registry exchange contract is used to find pools and query exchange rates for token swaps.
 *      It also provides a unified exchange API that can be useful for on-chain integrators.
 **/
interface ICurveSwaps {
    /**
     * @notice Perform up to four swaps in a single transaction
     * @dev Routing and swap params must be determined off-chain. This
     *      functionality is designed for gas efficiency over ease-of-use.
     * @param _route Array of [initial token, pool, token, pool, token, ...]
     *               The array is iterated until a pool address of 0x00, then the last
     *               given token is transferred to `_receiver` (address to transfer the final output token to)
     * @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
     *                     values for the n'th pool in `_route`. The swap type should be 1 for
     *                     a stableswap `exchange`, 2 for stableswap `exchange_underlying`, 3
     *                     for a cryptoswap `exchange`, 4 for a cryptoswap `exchange_underlying`
     *                     and 5 for Polygon factory metapools `exchange_underlying`
     * @param _expected The minimum amount received after the final swap.
     * @return Received amount of final output token
     **/
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected
    ) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

/**
 * @notice Partial interface for a SushiSwap Router contract
 **/
interface ISushiSwapRouter {
    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the `path`
     * @dev The first element of `path` is the input token, the last is the output token,
     *      and any intermediate elements represent intermediate pairs to trade through (if, for example, a direct pair does not exist).
     *      `msg.sender` should have already given the router an allowance of at least `amountIn` on the input token
     * @param amountIn The amount of input tokens to send
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert
     * @param path An array of token addresses. `path.length` must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity
     * @param to Recipient of the output tokens
     * @param deadline Unix timestamp after which the transaction will revert
     * @return amounts The input token amount and all subsequent output token amounts
     **/
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

interface IGravity {
    function sendToCosmos(
        address _tokenContract,
        bytes32 _destination,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

/**
 * @dev Partial interface for a Aave LendingPool contract,
 * which is the main point of interaction with an Aave protocol's market
 **/
interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (
            //stores the reserve configuration
            //bit 0-15: LTV
            //bit 16-31: Liq. threshold
            //bit 32-47: Liq. bonus
            //bit 48-55: Decimals
            //bit 56: Reserve is active
            //bit 57: reserve is frozen
            //bit 58: borrowing is enabled
            //bit 59: stable rate borrowing enabled
            //bit 60-63: reserved
            //bit 64-79: reserve factor
            uint256 configuration,
            //the liquidity index. Expressed in ray
            uint128 liquidityIndex,
            //variable borrow index. Expressed in ray
            uint128 variableBorrowIndex,
            //the current supply rate. Expressed in ray
            uint128 currentLiquidityRate,
            //the current variable borrow rate. Expressed in ray
            uint128 currentVariableBorrowRate,
            //the current stable borrow rate. Expressed in ray
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            //tokens addresses
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            //address of the interest rate strategy
            address interestRateStrategyAddress,
            //the id of the reserve. Represents the position in the list of the active reserves
            uint8 id
        );
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

library Math {
    /**
     * @notice Substract and return 0 instead if results are negative.
     */
    function subMinZero(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x - y : 0;
    }

    /**
     * @notice Used to change the decimals of precision used for an amount.
     */
    function changeDecimals(
        uint256 amount,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) {
            return amount;
        } else if (fromDecimals < toDecimals) {
            return amount * 10**(toDecimals - fromDecimals);
        } else {
            return amount / 10**(fromDecimals - toDecimals);
        }
    }

    // ===================================== OPENZEPPELIN'S MATH =====================================

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // ================================= SOLMATE's FIXEDPOINTMATHLIB =================================

    uint256 public constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

// ========================================== USER ERRORS ===========================================

/**
 * @dev These errors represent invalid user input to functions. Where appropriate, the invalid value
 *      is specified along with constraints. These errors can be resolved by callers updating their
 *      arguments.
 */

/**
 * @notice Attempted an action with zero assets.
 */
error USR_ZeroAssets();

/**
 * @notice Attempted an action with zero shares.
 */
error USR_ZeroShares();

/**
 * @notice Attempted deposit more than the max deposit.
 * @param assets the assets user attempted to deposit
 * @param maxDeposit the max assets that can be deposited
 */
error USR_DepositRestricted(uint256 assets, uint256 maxDeposit);

/**
 * @notice Attempted to transfer more active shares than the user has.
 * @param activeShares amount of shares user has
 * @param attemptedActiveShares amount of shares user tried to transfer
 */
error USR_NotEnoughActiveShares(uint256 activeShares, uint256 attemptedActiveShares);

/**
 * @notice Attempted swap into an asset that is not the current asset of the position.
 * @param assetOut address of the asset attempted to swap to
 * @param currentAsset address of the current asset of position
 */
error USR_InvalidSwap(address assetOut, address currentAsset);

/**
 * @notice Attempted to sweep an asset that is managed by the cellar.
 * @param token address of the token that can't be sweeped
 */
error USR_ProtectedAsset(address token);

/**
 * @notice Attempted rebalance into the same position.
 * @param position address of the position
 */
error USR_SamePosition(address position);

/**
 * @notice Attempted to update the position to one that is not supported by the platform.
 * @param unsupportedPosition address of the unsupported position
 */
error USR_UnsupportedPosition(address unsupportedPosition);

/**
 * @notice Attempted an operation on an untrusted position.
 * @param position address of the position
 */
error USR_UntrustedPosition(address position);

/**
 * @notice Attempted to update a position to an asset that uses an incompatible amount of decimals.
 * @param newDecimals decimals of precision that the new position uses
 * @param maxDecimals maximum decimals of precision for a position to be compatible with the cellar
 */
error USR_TooManyDecimals(uint8 newDecimals, uint8 maxDecimals);

/**
 * @notice User attempted to stake zero amout.
 */
error USR_ZeroDeposit();

/**
 * @notice User attempted to stake an amount smaller than the minimum deposit.
 *
 * @param amount                Amount user attmpted to stake.
 * @param minimumDeposit        The minimum deopsit amount accepted.
 */
error USR_MinimumDeposit(uint256 amount, uint256 minimumDeposit);

/**
 * @notice The specified deposit ID does not exist for the caller.
 *
 * @param depositId             The deposit ID provided for lookup.
 */
error USR_NoDeposit(uint256 depositId);

/**
 * @notice The user is attempting to cancel unbonding for a deposit which is not unbonding.
 *
 * @param depositId             The deposit ID the user attempted to cancel.
 */
error USR_NotUnbonding(uint256 depositId);

/**
 * @notice The user is attempting to unbond a deposit which has already been unbonded.
 *
 * @param depositId             The deposit ID the user attempted to unbond.
 */
error USR_AlreadyUnbonding(uint256 depositId);

/**
 * @notice The user is attempting to unstake a deposit which is still timelocked.
 *
 * @param depositId             The deposit ID the user attempted to unstake.
 */
error USR_StakeLocked(uint256 depositId);

/**
 * @notice The contract owner attempted to update rewards but the new reward rate would cause overflow.
 */
error USR_RewardTooLarge();

/**
 * @notice The reward distributor attempted to update rewards but 0 rewards per epoch.
 *         This can also happen if there is less than 1 wei of rewards per second of the
 *         epoch - due to integer division this will also lead to 0 rewards.
 */
error USR_ZeroRewardsPerEpoch();

/**
 * @notice The caller attempted to stake with a lock value that did not
 *         correspond to a valid staking time.
 *
 * @param lock                  The provided lock value.
 */
error USR_InvalidLockValue(uint256 lock);

/**
 * @notice The caller attempted an signed action with an invalid signature.
 * @param signatureLength length of the signature passed in
 * @param expectedSignatureLength expected length of the signature passed in
 */
error USR_InvalidSignature(uint256 signatureLength, uint256 expectedSignatureLength);

// ========================================== STATE ERRORS ===========================================

/**
 * @dev These errors represent actions that are being prevented due to current contract state.
 *      These errors do not relate to user input, and may or may not be resolved by other actions
 *      or the progression of time.
 */

/**
 * @notice Attempted an action when cellar is using an asset that has a fee on transfer.
 * @param assetWithFeeOnTransfer address of the asset with fee on transfer
 */
error STATE_AssetUsesFeeOnTransfer(address assetWithFeeOnTransfer);

/**
 * @notice Attempted action was prevented due to contract being shutdown.
 */
error STATE_ContractShutdown();

/**
 * @notice Attempted to shutdown the contract when it was already shutdown.
 */
error STATE_AlreadyShutdown();

/**
 * @notice The caller attempted to start a reward period, but the contract did not have enough tokens
 *         for the specified amount of rewards.
 *
 * @param rewardBalance         The amount of distributionToken held by the contract.
 * @param reward                The amount of rewards the caller attempted to distribute.
 */
error STATE_RewardsNotFunded(uint256 rewardBalance, uint256 reward);

/**
 * @notice Attempted an operation that is prohibited while yield is still being distributed from the last accrual.
 */
error STATE_AccrualOngoing();

/**
 * @notice The caller attempted to change the epoch length, but current reward epochs were active.
 */
error STATE_RewardsOngoing();

/**
 * @notice The caller attempted to change the next epoch duration, but there are rewards ready.
 */
error STATE_RewardsReady();

/**
 * @notice The caller attempted to deposit stake, but there are no remaining rewards to pay out.
 */
error STATE_NoRewardsLeft();

/**
 * @notice The caller attempted to perform an an emergency unstake, but the contract
 *         is not in emergency mode.
 */
error STATE_NoEmergencyUnstake();

/**
 * @notice The caller attempted to perform an an emergency unstake, but the contract
 *         is not in emergency mode, or the emergency mode does not allow claiming rewards.
 */
error STATE_NoEmergencyClaim();

/**
 * @notice The caller attempted to perform a state-mutating action (e.g. staking or unstaking)
 *         while the contract was paused.
 */
error STATE_ContractPaused();

/**
 * @notice The caller attempted to perform a state-mutating action (e.g. staking or unstaking)
 *         while the contract was killed (placed in emergency mode).
 * @dev    Emergency mode is irreversible.
 */
error STATE_ContractKilled();

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
// From: https://github.com/Uniswap/v3-periphery/contracts/interfaces/IMulticall.sol
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { ICellarStaking } from "./interfaces/ICellarStaking.sol";

import "./Errors.sol";

/**
 * @title Sommelier Staking
 * @author Kevin Kennis
 *
 * Staking for Sommelier Cellars.
 *
 * This contract is inspired by the Synthetix staking rewards contract, Ampleforth's
 * token geyser, and Treasure DAO's MAGIC mine. However, there are unique improvements
 * and new features, specifically unbonding, as inspired by LP bonding on Osmosis.
 * Unbonding allows the contract to guarantee deposits for a certain amount of time,
 * increasing predictability and stickiness of TVL for Cellars.
 *
 * *********************************** Funding Flow ***********************************
 *
 * 1) The contract owner calls 'notifyRewardAmount' to specify an initial schedule of rewards
 *    The contract should hold enough the distribution token to fund the
 *    specified reward schedule, where the length of the reward schedule is defined by
 *    epochDuration. This duration can also be changed by the owner, and any change will apply
 *    to future calls to 'notifyRewardAmount' (but will not affect active schedules).
 * 2) At a future time, the contract owner may call 'notifyRewardAmount' again to extend the
 *    staking program with new rewards. These new schedules may distribute more or less
 *    rewards than previous epochs. If a previous epoch is not finished, any leftover rewards
 *    get rolled into the new schedule, increasing the reward rate. Reward schedules always
 *    end exactly 'epochDuration' seconds from the most recent time 'notifyRewardAmount' has been
 *    called.
 *
 * ********************************* Staking Lifecycle ********************************
 *
 * 1) A user may deposit a certain amount of tokens to stake, and is required to lock
 *    those tokens for a specified amount of time. There are three locking options:
 *    one day, one week, or one month. Longer locking times receive larger 'boosts',
 *    that the deposit will receive a larger proportional amount of shares. A user
 *    may not unstake until they choose to unbond, and time defined by the lock has
 *    elapsed during unbonding.
 * 2) When a user wishes to withdraw, they must first "unbond" their stake, which starts
 *    a timer equivalent to the lock time. They still receive their rewards during this
 *    time, but forfeit any locktime boosts. A user may cancel the unbonding period at any
 *    time to regain their boosts, which will set the unbonding timer back to 0.
 * 2) Once the lock has elapsed, a user may unstake their deposit, either partially
 *    or in full. The user will continue to receive the same 'boosted' amount of rewards
 *    until they unstake. The user may unstake all of their deposits at once, as long
 *    as all of the lock times have elapsed. When unstaking, the user will also receive
 *    all eligible rewards for all deposited stakes, which accumulate linearly.
 * 3) At any time, a user may claim their available rewards for their deposits. Rewards
 *    accumulate linearly and can be claimed at any time, whether or not the lock has
 *    for a given deposit has expired. The user can claim rewards for a specific deposit,
 *    or may choose to collect all eligible rewards at once.
 *
 * ************************************ Accounting ************************************
 *
 * The contract uses an accounting mechanism based on the 'rewardPerToken' model,
 * originated by the Synthetix staking rewards contract. First, token deposits are accounted
 * for, with synthetic "boosted" amounts used for reward calculations. As time passes,
 * rewardPerToken continues to accumulate, whereas the value of 'rewardPerToken' will match
 * the reward due to a single token deposited before the first ever rewards were scheduled.
 *
 * At each accounting checkpoint, rewardPerToken will be recalculated, and every time an
 * existing stake is 'touched', this value is used to calculate earned rewards for that
 * stake. Each stake tracks a 'rewardPerTokenPaid' value, which represents the 'rewardPerToken'
 * value the last time the stake calculated "earned" rewards. Every recalculation pays the difference.
 * This ensures no earning is double-counted. When a new stake is deposited, its
 * initial 'rewardPerTokenPaid' is set to the current 'rewardPerToken' in the contract,
 * ensuring it will not receive any rewards emitted during the period before deposit.
 *
 * The following example applies to a given epoch of 100 seconds, with a reward rate
 * of 100 tokens per second:
 *
 * a) User 1 deposits a stake of 50 before the epoch begins
 * b) User 2 deposits a stake of 20 at second 20 of the epoch
 * c) User 3 deposits a stake of 100 at second 50 of the epoch
 *
 * In this case,
 *
 * a) At second 20, before User 2's deposit, rewardPerToken will be 40
 *     (2000 total tokens emitted over 20 seconds / 50 staked).
 * b) At second 50, before User 3's deposit, rewardPerToken will be 82.857
 *     (previous 40 + 3000 tokens emitted over 30 seconds / 70 staked == 42.857)
 * c) At second 100, when the period is over, rewardPerToken will be 112.267
 *     (previous 82.857 + 5000 tokens emitted over 50 seconds / 170 staked == 29.41)
 *
 *
 * Then, each user will receive rewards proportional to the their number of tokens. At second 100:
 * a) User 1 will receive 50 * 112.267 = 5613.35 rewards
 * b) User 2 will receive 20 * (112.267 - 40) = 1445.34
 *       (40 is deducted because it was the current rewardPerToken value on deposit)
 * c) User 3 will receive 100 * (112.267 - 82.857) = 2941
 *       (82.857 is deducted because it was the current rewardPerToken value on deposit)
 *
 * Depending on deposit times, this accumulation may take place over multiple
 * reward periods, and the total rewards earned is simply the sum of rewards earned for
 * each period. A user may also have multiple discrete deposits, which are all
 * accounted for separately due to timelocks and locking boosts. Therefore,
 * a user's total earned rewards are a function of their rewards across
 * the proportional tokens deposited, across different ranges of rewardPerToken.
 *
 * Reward accounting takes place before every operation which may change
 * accounting calculations (minting of new shares on staking, burning of
 * shares on unstaking, or claiming, which decrements eligible rewards).
 * This is gas-intensive but unavoidable, since retroactive accounting
 * based on previous proportionate shares would require a prohibitive
 * amount of storage of historical state. On every accounting run, there
 * are a number of safety checks to ensure that all reward tokens are
 * accounted for and that no accounting time periods have been missed.
 *
 */
contract CellarStaking is ICellarStaking, Ownable {
    using SafeTransferLib for ERC20;

    // ============================================ STATE ==============================================

    // ============== Constants ==============

    uint256 public constant ONE = 1e18;
    uint256 public constant ONE_DAY = 60 * 60 * 24;
    uint256 public constant ONE_WEEK = ONE_DAY * 7;
    uint256 public constant TWO_WEEKS = ONE_WEEK * 2;

    uint256 public immutable SHORT_BOOST;
    uint256 public immutable MEDIUM_BOOST;
    uint256 public immutable LONG_BOOST;

    uint256 public immutable SHORT_BOOST_TIME;
    uint256 public immutable MEDIUM_BOOST_TIME;
    uint256 public immutable LONG_BOOST_TIME;

    // ============ Global State =============

    ERC20 public immutable override stakingToken;
    ERC20 public immutable override distributionToken;
    uint256 public override currentEpochDuration;
    uint256 public override nextEpochDuration;
    uint256 public override rewardsReady;

    uint256 public override minimumDeposit;
    uint256 public override endTimestamp;
    uint256 public override totalDeposits;
    uint256 public override totalDepositsWithBoost;
    uint256 public override rewardRate;
    uint256 public override rewardPerTokenStored;

    uint256 private lastAccountingTimestamp = block.timestamp;

    /// @notice Emergency states in case of contract malfunction.
    bool public override paused;
    bool public override ended;
    bool public override claimable;

    // ============= User State ==============

    /// @notice user => all user's staking positions
    mapping(address => UserStake[]) public stakes;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @param _owner                The owner of the staking contract - will immediately receive ownership.
     * @param _stakingToken         The token users will deposit in order to stake.
     * @param _distributionToken    The token the staking contract will distribute as rewards.
     * @param _epochDuration        The length of a reward schedule.
     * @param shortBoost            The boost multiplier for the short unbonding time.
     * @param mediumBoost           The boost multiplier for the medium unbonding time.
     * @param longBoost             The boost multiplier for the long unbonding time.
     * @param shortBoostTime        The short unbonding time.
     * @param mediumBoostTime       The medium unbonding time.
     * @param longBoostTime         The long unbonding time.
     */
    constructor(
        address _owner,
        ERC20 _stakingToken,
        ERC20 _distributionToken,
        uint256 _epochDuration,
        uint256 shortBoost,
        uint256 mediumBoost,
        uint256 longBoost,
        uint256 shortBoostTime,
        uint256 mediumBoostTime,
        uint256 longBoostTime
    ) {
        stakingToken = _stakingToken;
        distributionToken = _distributionToken;
        nextEpochDuration = _epochDuration;

        SHORT_BOOST = shortBoost;
        MEDIUM_BOOST = mediumBoost;
        LONG_BOOST = longBoost;

        SHORT_BOOST_TIME = shortBoostTime;
        MEDIUM_BOOST_TIME = mediumBoostTime;
        LONG_BOOST_TIME = longBoostTime;

        transferOwnership(_owner);
    }

    // ======================================= STAKING OPERATIONS =======================================

    /**
     * @notice  Make a new deposit into the staking contract. Longer locks receive reward boosts.
     * @dev     Specified amount of stakingToken must be approved for withdrawal by the caller.
     * @dev     Valid lock values are 0 (one day), 1 (one week), and 2 (two weeks).
     *
     * @param amount                The amount of the stakingToken to stake.
     * @param lock                  The amount of time to lock stake for.
     */
    function stake(uint256 amount, Lock lock) external override whenNotPaused updateRewards {
        if (amount == 0) revert USR_ZeroDeposit();
        if (amount < minimumDeposit) revert USR_MinimumDeposit(amount, minimumDeposit);

        if (totalDeposits == 0 && rewardsReady > 0) {
            _startProgram(rewardsReady);
            rewardsReady = 0;

            // Need to run updateRewards again
            _updateRewards();
        } else if (block.timestamp > endTimestamp) {
            revert STATE_NoRewardsLeft();
        }

        // Do share accounting and populate user stake information
        (uint256 boost, ) = _getBoost(lock);
        uint256 amountWithBoost = amount + ((amount * boost) / ONE);

        stakes[msg.sender].push(
            UserStake({
                amount: uint112(amount),
                amountWithBoost: uint112(amountWithBoost),
                unbondTimestamp: 0,
                rewardPerTokenPaid: uint112(rewardPerTokenStored),
                rewards: 0,
                lock: lock
            })
        );

        // Update global state
        totalDeposits += amount;
        totalDepositsWithBoost += amountWithBoost;

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Stake(msg.sender, stakes[msg.sender].length - 1, amount);
    }

    /**
     * @notice  Unbond a specified amount from a certain deposited stake.
     * @dev     After the unbond time elapses, the deposit can be unstaked.
     *
     * @param depositId             The specified deposit to unstake from.
     *
     */
    function unbond(uint256 depositId) external override whenNotPaused updateRewards {
        _unbond(depositId);
    }

    /**
     * @notice  Unbond all user deposits.
     * @dev     Different deposits may have different timelocks.
     *
     */
    function unbondAll() external override whenNotPaused updateRewards {
        // Individually unbond each deposit
        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            UserStake storage s = userStakes[i];

            if (s.amount != 0 && s.unbondTimestamp == 0) {
                _unbond(i);
            }
        }
    }

    /**
     * @dev     Contains all logic for processing an unbond operation.
     *          For the given deposit, sets an unlock time, and
     *          reverts boosts to 0.
     *
     * @param depositId             The specified deposit to unbond from.
     */
    function _unbond(uint256 depositId) internal {
        // Fetch stake and make sure it is withdrawable
        UserStake storage s = stakes[msg.sender][depositId];

        uint256 depositAmount = s.amount;
        if (depositAmount == 0) revert USR_NoDeposit(depositId);
        if (s.unbondTimestamp > 0) revert USR_AlreadyUnbonding(depositId);

        _updateRewardForStake(msg.sender, depositId);

        // Remove any lock boosts
        uint256 depositAmountReduced = s.amountWithBoost - depositAmount;
        (, uint256 lockDuration) = _getBoost(s.lock);

        s.amountWithBoost = uint112(depositAmount);
        s.unbondTimestamp = uint32(block.timestamp + lockDuration);

        totalDepositsWithBoost -= uint112(depositAmountReduced);

        emit Unbond(msg.sender, depositId, depositAmount);
    }

    /**
     * @notice  Cancel an unbonding period for a stake that is currently unbonding.
     * @dev     Resets the unbonding timer and reinstates any lock boosts.
     *
     * @param depositId             The specified deposit to unstake from.
     *
     */
    function cancelUnbonding(uint256 depositId) external override whenNotPaused updateRewards {
        _cancelUnbonding(depositId);
    }

    /**
     * @notice  Cancel an unbonding period for all stakes.
     * @dev     Only cancels stakes that are unbonding.
     *
     */
    function cancelUnbondingAll() external override whenNotPaused updateRewards {
        // Individually unbond each deposit
        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            UserStake storage s = userStakes[i];

            if (s.amount != 0 && s.unbondTimestamp != 0) {
                _cancelUnbonding(i);
            }
        }
    }

    /**
     * @dev     Contains all logic for cancelling an unbond operation.
     *          For the given deposit, resets the unbonding timer, and
     *          reverts boosts to amount determined by lock.
     *
     * @param depositId             The specified deposit to unbond from.
     */
    function _cancelUnbonding(uint256 depositId) internal {
        // Fetch stake and make sure it is withdrawable
        UserStake storage s = stakes[msg.sender][depositId];

        uint256 depositAmount = s.amount;
        if (depositAmount == 0) revert USR_NoDeposit(depositId);
        if (s.unbondTimestamp == 0) revert USR_NotUnbonding(depositId);

        _updateRewardForStake(msg.sender, depositId);

        // Reinstate
        (uint256 boost, ) = _getBoost(s.lock);
        uint256 depositAmountIncreased = (s.amount * boost) / ONE;
        uint256 amountWithBoost = s.amount + depositAmountIncreased;

        s.amountWithBoost = uint112(amountWithBoost);
        s.unbondTimestamp = 0;

        totalDepositsWithBoost += depositAmountIncreased;

        emit CancelUnbond(msg.sender, depositId);
    }

    /**
     * @notice  Unstake a specific deposited stake.
     * @dev     The unbonding time for the specified deposit must have elapsed.
     * @dev     Unstaking automatically claims available rewards for the deposit.
     *
     * @param depositId             The specified deposit to unstake from.
     *
     * @return reward               The amount of accumulated rewards since the last reward claim.
     */
    function unstake(uint256 depositId) external override whenNotPaused updateRewards returns (uint256 reward) {
        return _unstake(depositId);
    }

    /**
     * @notice  Unstake all user deposits.
     * @dev     Only unstakes rewards that are unbonded.
     * @dev     Unstaking automatically claims all available rewards.
     *
     * @return rewards              The amount of accumulated rewards since the last reward claim.
     */
    function unstakeAll() external override whenNotPaused updateRewards returns (uint256[] memory) {
        // Individually unstake each deposit
        UserStake[] storage userStakes = stakes[msg.sender];
        uint256[] memory rewards = new uint256[](userStakes.length);

        for (uint256 i = 0; i < userStakes.length; i++) {
            UserStake storage s = userStakes[i];

            if (s.amount != 0 && s.unbondTimestamp != 0 && block.timestamp >= s.unbondTimestamp) {
                rewards[i] = _unstake(i);
            }
        }

        return rewards;
    }

    /**
     * @dev     Contains all logic for processing an unstake operation.
     *          For the given deposit, does share accounting and burns
     *          shares, returns staking tokens to the original owner,
     *          updates global deposit and share trackers, and claims
     *          rewards for the given deposit.
     *
     * @param depositId             The specified deposit to unstake from.
     */
    function _unstake(uint256 depositId) internal returns (uint256 reward) {
        // Fetch stake and make sure it is withdrawable
        UserStake storage s = stakes[msg.sender][depositId];

        uint256 depositAmount = s.amount;

        if (depositAmount == 0) revert USR_NoDeposit(depositId);
        if (s.unbondTimestamp == 0 || block.timestamp < s.unbondTimestamp) revert USR_StakeLocked(depositId);

        _updateRewardForStake(msg.sender, depositId);

        // Start unstaking
        reward = s.rewards;

        s.amount = 0;
        s.amountWithBoost = 0;
        s.rewards = 0;

        // Update global state
        // Boosted amount same as deposit amount, since we have unbonded
        totalDeposits -= depositAmount;
        totalDepositsWithBoost -= depositAmount;

        // Distribute stake
        stakingToken.safeTransfer(msg.sender, depositAmount);

        // Distribute reward
        distributionToken.safeTransfer(msg.sender, reward);

        emit Unstake(msg.sender, depositId, depositAmount, reward);
    }

    /**
     * @notice  Claim rewards for a given deposit.
     * @dev     Rewards accumulate linearly since deposit.
     *
     * @param depositId             The specified deposit for which to claim rewards.
     *
     * @return reward               The amount of accumulated rewards since the last reward claim.
     */
    function claim(uint256 depositId) external override whenNotPaused updateRewards returns (uint256 reward) {
        return _claim(depositId);
    }

    /**
     * @notice  Claim all available rewards.
     * @dev     Rewards accumulate linearly.
     *
     *
     * @return rewards               The amount of accumulated rewards since the last reward claim.
     *                               Each element of the array specified rewards for the corresponding
     *                               indexed deposit.
     */
    function claimAll() external override whenNotPaused updateRewards returns (uint256[] memory rewards) {
        // Individually claim for each stake
        UserStake[] storage userStakes = stakes[msg.sender];
        rewards = new uint256[](userStakes.length);

        for (uint256 i = 0; i < userStakes.length; i++) {
            rewards[i] = _claim(i);
        }
    }

    /**
     * @dev Contains all logic for processing a claim operation.
     *      Relies on previous reward accounting done before
     *      processing external functions. Updates the amount
     *      of rewards claimed so rewards cannot be claimed twice.
     *
     *
     * @param depositId             The specified deposit to claim rewards for.
     *
     * @return reward               The amount of accumulated rewards since the last reward claim.
     */
    function _claim(uint256 depositId) internal returns (uint256 reward) {
        // Fetch stake and make sure it is valid
        UserStake storage s = stakes[msg.sender][depositId];

        _updateRewardForStake(msg.sender, depositId);

        reward = s.rewards;

        // Distribute reward
        if (reward > 0) {
            s.rewards = 0;

            distributionToken.safeTransfer(msg.sender, reward);

            emit Claim(msg.sender, depositId, reward);
        }
    }

    /**
     * @notice  Unstake and return all staked tokens to the caller.
     * @dev     In emergency mode, staking time locks do not apply.
     */
    function emergencyUnstake() external override {
        if (!ended) revert STATE_NoEmergencyUnstake();

        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            if (claimable) _updateRewardForStake(msg.sender, i);

            UserStake storage s = userStakes[i];
            uint256 amount = s.amount;

            if (amount > 0) {
                // Update global state
                totalDeposits -= amount;
                totalDepositsWithBoost -= s.amountWithBoost;

                s.amount = 0;
                s.amountWithBoost = 0;

                stakingToken.transfer(msg.sender, amount);

                emit EmergencyUnstake(msg.sender, i, amount);
            }
        }
    }

    /**
     * @notice  Claim any accumulated rewards in emergency mode.
     * @dev     In emergency node, no additional reward accounting is done.
     *          Rewards do not accumulate after emergency mode begins,
     *          so any earned amount is only retroactive to when the contract
     *          was active.
     */
    function emergencyClaim() external override {
        if (!ended) revert STATE_NoEmergencyUnstake();
        if (!claimable) revert STATE_NoEmergencyClaim();

        uint256 reward;

        UserStake[] storage userStakes = stakes[msg.sender];
        for (uint256 i = 0; i < userStakes.length; i++) {
            _updateRewardForStake(msg.sender, i);

            UserStake storage s = userStakes[i];

            reward += s.rewards;
            s.rewards = 0;
        }

        if (reward > 0) {
            distributionToken.safeTransfer(msg.sender, reward);

            // No need for per-stake events like emergencyUnstake:
            // don't need to make sure positions were unwound
            emit EmergencyClaim(msg.sender, reward);
        }
    }

    // ======================================== ADMIN OPERATIONS ========================================

    /**
     * @notice Specify a new schedule for staking rewards. Contract must already hold enough tokens.
     * @dev    Can only be called by reward distributor. Owner must approve distributionToken for withdrawal.
     * @dev    epochDuration must divide reward evenly, otherwise any remainder will be lost.
     *
     * @param reward                The amount of rewards to distribute per second.
     */
    function notifyRewardAmount(uint256 reward) external override onlyOwner updateRewards {
        if (block.timestamp < endTimestamp) {
            uint256 remaining = endTimestamp - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            reward += leftover;
        }

        if (reward < nextEpochDuration) revert USR_ZeroRewardsPerEpoch();

        uint256 rewardBalance = distributionToken.balanceOf(address(this));
        uint256 pendingRewards = reward + rewardsReady;
        if (rewardBalance < pendingRewards) revert STATE_RewardsNotFunded(rewardBalance, pendingRewards);

        // prevent overflow when computing rewardPerToken
        uint256 proposedRewardRate = reward / nextEpochDuration;
        if (proposedRewardRate >= ((type(uint256).max / ONE) / nextEpochDuration)) {
            revert USR_RewardTooLarge();
        }

        if (totalDeposits == 0) {
            // No deposits yet, so keep rewards pending until first deposit
            // Incrementing in case it is called twice
            rewardsReady += reward;
        } else {
            // Ready to start
            _startProgram(reward);
        }

        lastAccountingTimestamp = block.timestamp;
    }

    /**
     * @notice Change the length of a reward epoch for future reward schedules.
     *
     * @param _epochDuration        The new duration for reward schedules.
     */
    function setRewardsDuration(uint256 _epochDuration) external override onlyOwner {
        if (rewardsReady > 0) revert STATE_RewardsReady();

        nextEpochDuration = _epochDuration;
        emit EpochDurationChange(nextEpochDuration);
    }

    /**
     * @notice Specify a minimum deposit for staking.
     * @dev    Can only be called by owner.
     *
     * @param _minimum              The minimum deposit for each new stake.
     */
    function setMinimumDeposit(uint256 _minimum) external override onlyOwner {
        minimumDeposit = _minimum;
    }

    /**
     * @notice Pause the contract. Pausing prevents staking, unstaking, claiming
     *         rewards, and scheduling new rewards. Should only be used
     *         in an emergency.
     *
     * @param _paused               Whether the contract should be paused.
     */
    function setPaused(bool _paused) external override onlyOwner {
        paused = _paused;
    }

    /**
     * @notice Stops the contract - this is irreversible. Should only be used
     *         in an emergency, for example an irreversible accounting bug
     *         or an exploit. Enables all depositors to withdraw their stake
     *         instantly. Also stops new rewards accounting.
     *
     * @param makeRewardsClaimable  Whether any previously accumulated rewards should be claimable.
     */
    function emergencyStop(bool makeRewardsClaimable) external override onlyOwner {
        if (ended) revert STATE_AlreadyShutdown();

        // Update state and put in irreversible emergency mode
        ended = true;
        claimable = makeRewardsClaimable;
        uint256 amountToReturn = distributionToken.balanceOf(address(this));

        if (makeRewardsClaimable) {
            // Update rewards one more time
            _updateRewards();

            // Return any remaining, since new calculation is stopped
            uint256 remaining = endTimestamp > block.timestamp ? (endTimestamp - block.timestamp) * rewardRate : 0;

            // Make sure any rewards except for remaining are kept for claims
            uint256 amountToKeep = rewardRate * currentEpochDuration - remaining;

            amountToReturn -= amountToKeep;
        }

        // Send distribution token back to owner
        distributionToken.transfer(msg.sender, amountToReturn);

        emit EmergencyStop(msg.sender, makeRewardsClaimable);
    }

    // ======================================= STATE INFORMATION =======================================

    /**
     * @notice Returns the latest time to account for in the reward program.
     *
     * @return timestamp           The latest time to calculate.
     */
    function latestRewardsTimestamp() public view override returns (uint256) {
        return block.timestamp < endTimestamp ? block.timestamp : endTimestamp;
    }

    /**
     * @notice Returns the amount of reward to distribute per currently-depostied token.
     *         Will update on changes to total deposit balance or reward rate.
     * @dev    Sets rewardPerTokenStored.
     *
     *
     * @return newRewardPerTokenStored  The new rewards to distribute per token.
     * @return latestTimestamp          The latest time to calculate.
     */
    function rewardPerToken() public view override returns (uint256 newRewardPerTokenStored, uint256 latestTimestamp) {
        latestTimestamp = latestRewardsTimestamp();

        if (totalDeposits == 0) return (rewardPerTokenStored, latestTimestamp);

        uint256 timeElapsed = latestTimestamp - lastAccountingTimestamp;
        uint256 rewardsForTime = timeElapsed * rewardRate;
        uint256 newRewardsPerToken = (rewardsForTime * ONE) / totalDepositsWithBoost;

        newRewardPerTokenStored = rewardPerTokenStored + newRewardsPerToken;
    }

    /**
     * @notice Gets all of a user's stakes.
     * @dev This is provided because Solidity converts public arrays into index getters,
     *      but we need a way to allow external contracts and users to access the whole array.

     * @param user                      The user whose stakes to get.
     *
     * @return stakes                   Array of all user's stakes
     */
    function getUserStakes(address user) public view override returns (UserStake[] memory) {
        return stakes[user];
    }

    // ============================================ HELPERS ============================================

    /**
     * @dev Modifier to apply reward updates before functions that change accounts.
     */
    modifier updateRewards() {
        _updateRewards();
        _;
    }

    /**
     * @dev Blocks calls if contract is paused or killed.
     */
    modifier whenNotPaused() {
        if (paused) revert STATE_ContractPaused();
        if (ended) revert STATE_ContractKilled();
        _;
    }

    /**
     * @dev Update reward accounting for the global state totals.
     */
    function _updateRewards() internal {
        (rewardPerTokenStored, lastAccountingTimestamp) = rewardPerToken();
    }

    /**
     * @dev On initial deposit, start the rewards program.
     *
     * @param reward                    The pending rewards to start distributing.
     */
    function _startProgram(uint256 reward) internal {
        // Assumptions
        // Total deposits are now (mod current tx), no ongoing program
        // Rewards are already funded (since checked in notifyRewardAmount)

        rewardRate = reward / nextEpochDuration;
        endTimestamp = block.timestamp + nextEpochDuration;
        currentEpochDuration = nextEpochDuration;

        emit Funding(reward, endTimestamp);
    }

    /**
     * @dev Update reward for a specific user stake.
     */
    function _updateRewardForStake(address user, uint256 depositId) internal {
        UserStake storage s = stakes[user][depositId];
        if (s.amount == 0) return;

        uint256 earned = _earned(s);
        s.rewards += uint112(earned);

        s.rewardPerTokenPaid = uint112(rewardPerTokenStored);
    }

    /**
     * @dev Return how many rewards a stake has earned and has claimable.
     */
    function _earned(UserStake memory s) internal view returns (uint256) {
        uint256 rewardPerTokenAcc = rewardPerTokenStored - s.rewardPerTokenPaid;
        uint256 newRewards = (s.amountWithBoost * rewardPerTokenAcc) / ONE;

        return newRewards;
    }

    /**
     * @dev Maps Lock enum values to corresponding lengths of time and reward boosts.
     */
    function _getBoost(Lock _lock) internal view returns (uint256 boost, uint256 timelock) {
        if (_lock == Lock.short) {
            return (SHORT_BOOST, SHORT_BOOST_TIME);
        } else if (_lock == Lock.medium) {
            return (MEDIUM_BOOST, MEDIUM_BOOST_TIME);
        } else if (_lock == Lock.long) {
            return (LONG_BOOST, LONG_BOOST_TIME);
        } else {
            revert USR_InvalidLockValue(uint256(_lock));
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

/**
 * @title Sommelier Staking Interface
 * @author Kevin Kennis
 *
 * @notice Full documentation in implementation contract.
 */
interface ICellarStaking {
    // ===================== Events =======================

    event Funding(uint256 rewardAmount, uint256 rewardEnd);
    event Stake(address indexed user, uint256 depositId, uint256 amount);
    event Unbond(address indexed user, uint256 depositId, uint256 amount);
    event CancelUnbond(address indexed user, uint256 depositId);
    event Unstake(address indexed user, uint256 depositId, uint256 amount, uint256 reward);
    event Claim(address indexed user, uint256 depositId, uint256 amount);
    event EmergencyStop(address owner, bool claimable);
    event EmergencyUnstake(address indexed user, uint256 depositId, uint256 amount);
    event EmergencyClaim(address indexed user, uint256 amount);
    event EpochDurationChange(uint256 duration);

    // ===================== Structs ======================

    enum Lock {
        short,
        medium,
        long
    }

    struct UserStake {
        uint112 amount;
        uint112 amountWithBoost;
        uint32 unbondTimestamp;
        uint112 rewardPerTokenPaid;
        uint112 rewards;
        Lock lock;
    }

    // ============== Public State Variables ==============

    function stakingToken() external returns (ERC20);

    function distributionToken() external returns (ERC20);

    function currentEpochDuration() external returns (uint256);

    function nextEpochDuration() external returns (uint256);

    function rewardsReady() external returns (uint256);

    function minimumDeposit() external returns (uint256);

    function endTimestamp() external returns (uint256);

    function totalDeposits() external returns (uint256);

    function totalDepositsWithBoost() external returns (uint256);

    function rewardRate() external returns (uint256);

    function rewardPerTokenStored() external returns (uint256);

    function paused() external returns (bool);

    function ended() external returns (bool);

    function claimable() external returns (bool);

    // ================ User Functions ================

    function stake(uint256 amount, Lock lock) external;

    function unbond(uint256 depositId) external;

    function unbondAll() external;

    function cancelUnbonding(uint256 depositId) external;

    function cancelUnbondingAll() external;

    function unstake(uint256 depositId) external returns (uint256 reward);

    function unstakeAll() external returns (uint256[] memory rewards);

    function claim(uint256 depositId) external returns (uint256 reward);

    function claimAll() external returns (uint256[] memory rewards);

    function emergencyUnstake() external;

    function emergencyClaim() external;

    // ================ Admin Functions ================

    function notifyRewardAmount(uint256 reward) external;

    function setRewardsDuration(uint256 _epochDuration) external;

    function setMinimumDeposit(uint256 _minimum) external;

    function setPaused(bool _paused) external;

    function emergencyStop(bool makeRewardsClaimable) external;

    // ================ View Functions ================

    function latestRewardsTimestamp() external view returns (uint256);

    function rewardPerToken() external view returns (uint256, uint256);

    function getUserStakes(address user) external view returns (UserStake[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { Math } from "src/utils/Math.sol";

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

contract MockSwapRouter {
    using Path for bytes;
    using Math for uint256;

    uint256 public constant EXCHANGE_RATE = 0.95e18;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256) {
        ERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        uint256 amountOut = params.amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(params.tokenIn).decimals();
        uint8 toDecimals = ERC20(params.tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= params.amountOutMinimum, "amountOutMin invariant failed");

        ERC20(params.tokenOut).transfer(params.recipient, amountOut);
        return amountOut;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams memory params) external payable returns (uint256) {
        (address tokenIn, address tokenOut, ) = params.path.decodeFirstPool();

        while (params.path.hasMultiplePools()) {
            params.path = params.path.skipToken();
            (, tokenOut, ) = params.path.decodeFirstPool();
        }

        ERC20(tokenIn).transferFrom(msg.sender, address(this), params.amountIn);

        uint256 amountOut = params.amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= params.amountOutMinimum, "amountOutMin invariant failed");

        ERC20(tokenOut).transfer(params.recipient, amountOut);
        return amountOut;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256
    ) external returns (uint256[] memory) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut = amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= amountOutMin, "amountOutMin invariant failed");

        ERC20(tokenOut).transfer(to, amountOut);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amountOut;

        return amounts;
    }

    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory,
        uint256 _amount,
        uint256 _expected
    ) external returns (uint256) {
        address tokenIn = _route[0];

        address tokenOut;
        for (uint256 i; ; i += 2) {
            if (i == 8 || _route[i + 1] == address(0)) {
                tokenOut = _route[i];
                break;
            }
        }

        ERC20(tokenIn).transferFrom(msg.sender, address(this), _amount);

        uint256 amountOut = _amount.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        amountOut = amountOut.changeDecimals(fromDecimals, toDecimals);

        require(amountOut >= _expected, "received less than expected");

        ERC20(tokenOut).transfer(msg.sender, amountOut);

        return amountOut;
    }

    function quote(uint256 amountIn, address[] calldata path) external view returns (uint256) {
        address tokenIn = path[0];
        address tokenOut = path[path.length - 1];

        uint256 amountOut = amountIn.mulWadDown(EXCHANGE_RATE);

        uint8 fromDecimals = ERC20(tokenIn).decimals();
        uint8 toDecimals = ERC20(tokenOut).decimals();
        return amountOut.changeDecimals(fromDecimals, toDecimals);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { MockERC20 } from "./MockERC20.sol";
import { Math } from "src/utils/Math.sol";

contract MockERC20WithTransferFee is MockERC20 {
    using Math for uint256;

    uint256 public constant transferFee = 0.01e18;

    constructor(string memory _symbol, uint8 _decimals) MockERC20(_symbol, _decimals) {}

    function transfer(address to, uint256 amount) public override returns (bool) {
        balanceOf[msg.sender] -= amount;

        amount -= amount.mulWadDown(transferFee);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        amount -= amount.mulWadDown(transferFee);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory _symbol, uint8 _decimals) ERC20(_symbol, _symbol, _decimals) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address to, uint256 amount) external {
        _burn(to, amount);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { MockERC20 } from "./MockERC20.sol";

contract MockStkAAVE is MockERC20 {
    MockERC20 public immutable AAVE; // AAVE
    uint256 public constant COOLDOWN_SECONDS = 864000; // 10 days
    uint256 public constant UNSTAKE_WINDOW = 172800; // 2 days
    mapping(address => uint256) public stakersCooldowns;

    constructor(MockERC20 _AAVE) MockERC20("stkAAVE", 18) {
        AAVE = _AAVE;
    }

    function cooldown() external {
        require(balanceOf[msg.sender] != 0, "INVALID_BALANCE_ON_COOLDOWN");
        stakersCooldowns[msg.sender] = block.timestamp;
    }

    function redeem(address to, uint256 amount) external {
        require(amount != 0, "INVALID_ZERO_AMOUNT");
        uint256 cooldownStartTimestamp = stakersCooldowns[msg.sender];
        require(block.timestamp > cooldownStartTimestamp + COOLDOWN_SECONDS, "INSUFFICIENT_COOLDOWN");
        require(
            block.timestamp - (cooldownStartTimestamp + COOLDOWN_SECONDS) <= UNSTAKE_WINDOW,
            "UNSTAKE_WINDOW_FINISHED"
        );

        uint256 balanceOfMessageSender = balanceOf[msg.sender];

        uint256 amountToRedeem = amount > balanceOfMessageSender ? balanceOfMessageSender : amount;

        // _updateCurrentUnclaimedRewards(msg.sender, balanceOfMessageSender, true);

        _burn(msg.sender, amountToRedeem);

        if (balanceOfMessageSender - amountToRedeem == 0) stakersCooldowns[msg.sender] = 0;

        AAVE.mint(to, amountToRedeem);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { MockStkAAVE } from "./MockStkAAVE.sol";

contract MockIncentivesController {
    MockStkAAVE public stkAAVE;
    mapping(address => uint256) public usersUnclaimedRewards;

    constructor(MockStkAAVE _stkAAVE) {
        stkAAVE = _stkAAVE;
    }

    /// @dev For testing purposes
    function addRewards(address account, uint256 amount) external {
        usersUnclaimedRewards[account] += amount;
    }

    function claimRewards(
        address[] calldata,
        uint256 amount,
        address to
    ) external returns (uint256) {
        uint256 claimable = usersUnclaimedRewards[to];

        if (amount > claimable) {
            amount = claimable;
        }

        usersUnclaimedRewards[to] -= amount;

        stkAAVE.mint(to, amount);

        return amount;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC4626 } from "src/base/ERC4626.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { MockERC20 } from "./MockERC20.sol";

contract MockERC4626 is ERC4626 {
    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC4626(_asset, _name, _symbol, _decimals) {}

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }

    function burn(address from, uint256 value) external {
        _burn(from, value);
    }

    function simulateGain(uint256 assets, address receiver) external returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        MockERC20(address(asset)).mint(address(this), assets);

        _mint(receiver, shares);
    }

    function simulateLoss(uint256 assets) external {
        MockERC20(address(asset)).burn(address(this), assets);
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { ERC4626 } from "src/base/ERC4626.sol";

interface ICellarRouter {
    // ======================================= ROUTER OPERATIONS =======================================

    function depositIntoCellarWithPermit(
        ERC4626 cellar,
        uint256 assets,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 shares);

    function depositAndSwapIntoCellar(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver
    ) external returns (uint256 shares);

    function depositAndSwapIntoCellarWithPermit(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 shares);

    function withdrawAndSwapFromCellar(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver
    ) external returns (uint256 shares);

    function withdrawAndSwapFromCellarWithPermit(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 shares);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";
import { ERC4626 } from "./base/ERC4626.sol";
import { Ownable } from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { ISwapRouter as IUniswapV3Router } from "./interfaces/ISwapRouter.sol";
import { IUniswapV2Router02 as IUniswapV2Router } from "./interfaces/IUniswapV2Router02.sol";
import { ICellarRouter } from "./interfaces/ICellarRouter.sol";
import { IGravity } from "./interfaces/IGravity.sol";

import "./Errors.sol";

contract CellarRouter is ICellarRouter, Ownable {
    using SafeTransferLib for ERC20;

    // ========================================== CONSTRUCTOR ==========================================
    /**
     * @notice Uniswap V3 swap router contract. Used for swapping if pool fees are specified.
     */
    IUniswapV3Router public immutable uniswapV3Router; // 0xE592427A0AEce92De3Edee1F18E0157C05861564

    /**
     * @notice Uniswap V2 swap router contract. Used for swapping if pool fees are not specified.
     */
    IUniswapV2Router public immutable uniswapV2Router; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    /**
     * @param _uniswapV3Router Uniswap V3 swap router address
     * @param _uniswapV2Router Uniswap V2 swap router address
     */
    constructor(
        IUniswapV3Router _uniswapV3Router,
        IUniswapV2Router _uniswapV2Router,
        address owner
    ) {
        uniswapV3Router = _uniswapV3Router;
        uniswapV2Router = _uniswapV2Router;

        // Transfer ownership to the Sommelier multisig.
        transferOwnership(address(owner));
    }

    // ======================================= DEPOSIT OPERATIONS =======================================

    /**
     * @notice Deposit assets into a cellar using permit.
     * @param cellar address of the cellar to deposit into
     * @param assets amount of assets to deposit
     * @param receiver address receiving the shares
     * @param deadline timestamp after which permit is invalid
     * @param signature a valid secp256k1 signature
     * @return shares amount of shares minted
     */
    function depositIntoCellarWithPermit(
        ERC4626 cellar,
        uint256 assets,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 shares) {
        // Retrieve the cellar's current asset.
        ERC20 asset = cellar.asset();

        // Approve the assets from the user to the router via permit.
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);
        asset.permit(msg.sender, address(this), assets, deadline, v, r, s);

        // Transfer assets from the user to the router.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Approve the cellar to spend assets.
        asset.safeApprove(address(cellar), assets);

        // Deposit assets into the cellar.
        shares = cellar.deposit(assets, receiver);
    }

    /**
     * @notice Deposit into a cellar by first performing a swap to the cellar's current asset if necessary.
     * @dev If using Uniswap V3 for swap, must specify the pool fee tier to use for each swap. For
     *      example, if there are "n" addresses in path, there should be "n-1" values specifying the
     *      fee tiers of each pool used for each swap. The current possible pool fee tiers for
     *      Uniswap V3 are 0.01% (100), 0.05% (500), 0.3% (3000), and 1% (10000). If using Uniswap
     *      V2, leave pool fees empty to use Uniswap V2 for swap.
     * @param cellar address of the cellar to deposit into
     * @param path array of [token1, token2, token3] that specifies the swap path on Sushiswap
     * @param poolFees amount out of 1e4 (eg. 10000 == 1%) that represents the fee tier to use for each swap
     * @param assets amount of assets to deposit
     * @param assetsOutMin minimum amount of assets received from swap
     * @param receiver address receiving the shares
     * @return shares amount of shares minted
     */
    function depositAndSwapIntoCellar(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver
    ) public returns (uint256 shares) {
        // Retrieve the asset being swapped and asset of cellar.
        ERC20 asset = cellar.asset();
        ERC20 assetIn = ERC20(path[0]);

        // Transfer assets from the user to the router.
        assetIn.safeTransferFrom(msg.sender, address(this), assets);

        // Check whether a swap is necessary. If not, skip swap and deposit into cellar directly.
        if (assetIn != asset) assets = _swap(path, poolFees, assets, assetsOutMin);

        // Approve the cellar to spend assets.
        asset.safeApprove(address(cellar), assets);

        // Deposit assets into the cellar.
        shares = cellar.deposit(assets, receiver);
    }

    /**
     * @notice Deposit into a cellar by first performing a swap to the cellar's current asset if necessary.
     * @dev If using Uniswap V3 for swap, must specify the pool fee tier to use for each swap. For
     *      example, if there are "n" addresses in path, there should be "n-1" values specifying the
     *      fee tiers of each pool used for each swap. The current possible pool fee tiers for
     *      Uniswap V3 are 0.01% (100), 0.05% (500), 0.3% (3000), and 1% (10000). If using Uniswap
     *      V2, leave pool fees empty to use Uniswap V2 for swap.
     * @param cellar address of the cellar to deposit into
     * @param path array of [token1, token2, token3] that specifies the swap path on Sushiswap
     * @param poolFees amount out of 1e4 (eg. 10000 == 1%) that represents the fee tier to use for each swap
     * @param assets amount of assets to deposit
     * @param assetsOutMin minimum amount of assets received from swap
     * @param receiver address receiving the shares
     * @param deadline timestamp after which permit is invalid
     * @param signature a valid secp256k1 signature
     * @return shares amount of shares minted
     */
    function depositAndSwapIntoCellarWithPermit(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 shares) {
        // Retrieve the asset being swapped.
        ERC20 assetIn = ERC20(path[0]);

        // Approve for router to burn user shares via permit.
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);
        assetIn.permit(msg.sender, address(this), assets, deadline, v, r, s);

        // Deposit assets into the cellar using a swap if necessary.
        shares = depositAndSwapIntoCellar(cellar, path, poolFees, assets, assetsOutMin, receiver);
    }

    // ======================================= WITHDRAW OPERATIONS =======================================

    /**
     * @notice Withdraws from a cellar and then performs a swap to another desired asset, if the
     *         withdrawn asset is not already.
     * @dev Permission is required from caller for router to burn shares. Please make sure that
     *      caller has approved the router to spend their shares.
     * @dev If using Uniswap V3 for swap, must specify the pool fee tier to use for each swap. For
     *      example, if there are "n" addresses in path, there should be "n-1" values specifying the
     *      fee tiers of each pool used for each swap. The current possible pool fee tiers for
     *      Uniswap V3 are 0.01% (100), 0.05% (500), 0.3% (3000), and 1% (10000). If using Uniswap
     *      V2, leave pool fees empty to use Uniswap V2 for swap.
     * @param cellar address of the cellar
     * @param path array of [token1, token2, token3] that specifies the swap path on swap
     * @param poolFees amount out of 1e4 (eg. 10000 == 1%) that represents the fee tier to use for each swap
     * @param assets amount of assets to withdraw
     * @param assetsOutMin minimum amount of assets received from swap
     * @param receiver address receiving the assets
     * @return shares amount of shares burned
     */
    function withdrawAndSwapFromCellar(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver
    ) public returns (uint256 shares) {
        ERC20 asset = cellar.asset();
        ERC20 assetOut = ERC20(path[path.length - 1]);

        // Withdraw assets from the cellar.
        shares = cellar.withdraw(assets, address(this), msg.sender);

        // Check whether a swap is necessary. If not, skip swap and transfer withdrawn assets to receiver.
        if (assetOut != asset) assets = _swap(path, poolFees, assets, assetsOutMin);

        // Transfer assets from the router to the receiver.
        assetOut.safeTransfer(receiver, assets);
    }

    /**
     * @notice Withdraws from a cellar and then performs a swap to another desired asset, if the
     *         withdrawn asset is not already, using permit.
     * @dev If using Uniswap V3 for swap, must specify the pool fee tier to use for each swap. For
     *      example, if there are "n" addresses in path, there should be "n-1" values specifying the
     *      fee tiers of each pool used for each swap. The current possible pool fee tiers for
     *      Uniswap V3 are 0.01% (100), 0.05% (500), 0.3% (3000), and 1% (10000). If using Uniswap
     *      V2, leave pool fees empty to use Uniswap V2 for swap.
     * @param cellar address of the cellar
     * @param path array of [token1, token2, token3] that specifies the swap path on swap
     * @param poolFees amount out of 1e4 (eg. 10000 == 1%) that represents the fee tier to use for each swap
     * @param assets amount of assets to withdraw
     * @param assetsOutMin minimum amount of assets received from swap
     * @param receiver address receiving the assets
     * @param deadline timestamp after which permit is invalid
     * @param signature a valid secp256k1 signature
     * @return shares amount of shares burned
     */
    function withdrawAndSwapFromCellarWithPermit(
        ERC4626 cellar,
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin,
        address receiver,
        uint256 deadline,
        bytes memory signature
    ) external returns (uint256 shares) {
        // Approve for router to burn user shares via permit.
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);
        cellar.permit(msg.sender, address(this), assets, deadline, v, r, s);

        // Withdraw assets from the cellar and swap to another asset if necessary.
        shares = withdrawAndSwapFromCellar(cellar, path, poolFees, assets, assetsOutMin, receiver);
    }

    // ========================================== RECOVERY LOGIC ==========================================

    /**
     * @notice Emitted when tokens accidentally sent to cellar router are recovered.
     * @param token the address of the token
     * @param to the address sweeped tokens were transferred to
     * @param amount amount transferred out
     */
    event Sweep(address indexed token, address indexed to, uint256 amount);

    function sweep(
        ERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        // Transfer out tokens from this cellar router contract that shouldn't be here.
        token.safeTransfer(to, amount);

        emit Sweep(address(token), to, amount);
    }

    // ========================================= HELPER FUNCTIONS =========================================

    /**
     * @notice Split a signature into its components.
     * @param signature a valid secp256k1 signature
     * @return v a component of the secp256k1 signature
     * @return r a component of the secp256k1 signature
     * @return s a component of the secp256k1 signature
     */
    function _splitSignature(bytes memory signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        if (signature.length != 65) revert USR_InvalidSignature(signature.length, 65);

        // Read each parameter directly from the signature's memory region.
        assembly {
            // Place first word on the stack at r.
            r := mload(add(signature, 32))

            // Place second word on the stack at s.
            s := mload(add(signature, 64))

            // Place final byte on the stack at v.
            v := byte(0, mload(add(signature, 96)))
        }
    }

    /**
     * @notice Perform a swap using Uniswap.
     * @dev If using Uniswap V3 for swap, must specify the pool fee tier to use for each swap. For
     *      example, if there are "n" addresses in path, there should be "n-1" values specifying the
     *      fee tiers of each pool used for each swap. The current possible pool fee tiers for
     *      Uniswap V3 are 0.01% (100), 0.05% (500), 0.3% (3000), and 1% (10000). If using Uniswap
     *      V2, leave pool fees empty to use Uniswap V2 for swap.
     * @param path array of [token1, token2, token3] that specifies the swap path on swap
     * @param poolFees amount out of 1e4 (eg. 10000 == 1%) that represents the fee tier to use for each swap
     * @param assets amount of assets to withdraw
     * @param assetsOutMin minimum amount of assets received from swap
     * @return assetsOut amount of assets received after swap
     */
    function _swap(
        address[] calldata path,
        uint24[] calldata poolFees,
        uint256 assets,
        uint256 assetsOutMin
    ) internal returns (uint256 assetsOut) {
        // Retrieve the asset being swapped.
        ERC20 assetIn = ERC20(path[0]);

        // Check whether to use Uniswap V2 or Uniswap V3 for swap.
        if (poolFees.length == 0) {
            // If no pool fees are specified, use Uniswap V2 for swap.

            // Approve assets to be swapped through the router.
            assetIn.safeApprove(address(uniswapV2Router), assets);

            // Execute the swap.
            uint256[] memory amountsOut = uniswapV2Router.swapExactTokensForTokens(
                assets,
                assetsOutMin,
                path,
                address(this),
                block.timestamp + 60
            );

            assetsOut = amountsOut[amountsOut.length - 1];
        } else {
            // If pool fees are specified, use Uniswap V3 for swap.

            // Approve assets to be swapped through the router.
            assetIn.safeApprove(address(uniswapV3Router), assets);

            // Encode swap parameters.
            bytes memory encodePackedPath = abi.encodePacked(address(assetIn));
            for (uint256 i = 1; i < path.length; i++)
                encodePackedPath = abi.encodePacked(encodePackedPath, poolFees[i - 1], path[i]);

            // Execute the swap.
            assetsOut = uniswapV3Router.exactInput(
                IUniswapV3Router.ExactInputParams({
                    path: encodePackedPath,
                    recipient: address(this),
                    deadline: block.timestamp + 60,
                    amountIn: assets,
                    amountOutMinimum: assetsOutMin
                })
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { MockLendingPool } from "./MockLendingPool.sol";
import { Math } from "src/utils/Math.sol";

library WadRayMath {
    uint256 public constant RAY = 1e27;
    uint256 public constant HALF_RAY = RAY / 2;

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "cannot divide by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, "math multiplication overflow");

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding down to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) return 0;

        require(a <= (type(uint256).max - HALF_RAY) / b, "math multiplication overflow");

        return (a * b + HALF_RAY) / RAY;
    }
}

contract MockAToken is ERC20 {
    address public underlyingAsset;
    MockLendingPool public lendingPool;

    constructor(
        address _lendingPool,
        address _underlyingAsset,
        string memory _symbol
    ) ERC20(_symbol, _symbol) {
        lendingPool = MockLendingPool(_lendingPool);
        underlyingAsset = _underlyingAsset;
    }

    function decimals() public view override returns (uint8) {
        return ERC20(underlyingAsset).decimals();
    }

    function mint(address user, uint256 amount) external {
        uint256 amountScaled = WadRayMath.rayDiv(amount, lendingPool.index());
        require(amountScaled != 0, "CT_INVALID_MINT_AMOUNT");
        _mint(user, amountScaled);
    }

    function burn(address user, uint256 amount) external {
        uint256 amountScaled = WadRayMath.rayDiv(amount, lendingPool.index());
        require(amountScaled != 0, "CT_INVALID_BURN_AMOUNT");
        _burn(user, amountScaled);
    }

    /**
     * @dev Mints aTokens to `user`
     * - Only callable by the LendingPool, as extra state updates there need to be managed
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool) {
        uint256 previousBalance = super.balanceOf(user);

        uint256 amountScaled = WadRayMath.rayDiv(amount, index);
        require(amountScaled != 0, "CT_INVALID_MINT_AMOUNT");
        _mint(user, amountScaled);

        return previousBalance == 0;
    }

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * - Only callable by the LendingPool, as extra state updates there need to be managed
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     */
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external {
        uint256 amountScaled = WadRayMath.rayDiv(amount, index);
        require(amountScaled != 0, "CT_INVALID_BURN_AMOUNT");
        _burn(user, amountScaled);

        ERC20(underlyingAsset).transfer(receiverOfUnderlying, amount);
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user) public view override returns (uint256) {
        return WadRayMath.rayMul(super.balanceOf(user), lendingPool.index());
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256) {
        return super.balanceOf(user);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { MockAToken } from "./MockAToken.sol";

contract MockLendingPool {
    mapping(address => address) public aTokens;
    uint256 public index = 1000000000000000000000000000;

    constructor() {}

    // for testing purposes; not in actual contract
    function setLiquidityIndex(uint256 _index) external {
        index = _index;
    }

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16
    ) external {
        ERC20(asset).transferFrom(onBehalfOf, aTokens[asset], amount);
        MockAToken(aTokens[asset]).mint(onBehalfOf, amount, index);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        if (amount == type(uint256).max) amount = MockAToken(aTokens[asset]).balanceOf(msg.sender);

        MockAToken(aTokens[asset]).burn(msg.sender, to, amount, index);

        return amount;
    }

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 configuration,
            uint128 liquidityIndex,
            uint128 variableBorrowIndex,
            uint128 currentLiquidityRate,
            uint128 currentVariableBorrowRate,
            uint128 currentStableBorrowRate,
            uint40 lastUpdateTimestamp,
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress,
            address interestRateStrategyAddress,
            uint8 id
        )
    {
        asset;
        configuration;
        liquidityIndex = uint128(index);
        variableBorrowIndex;
        currentLiquidityRate;
        currentVariableBorrowRate;
        currentStableBorrowRate;
        lastUpdateTimestamp;
        aTokenAddress = aTokens[asset];
        stableDebtTokenAddress;
        variableDebtTokenAddress;
        interestRateStrategyAddress;
        id;
    }

    function getReserveNormalizedIncome(address) external view returns (uint256) {
        return index;
    }

    function initReserve(address asset, address aTokenAddress) external {
        aTokens[asset] = aTokenAddress;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "lib/solmate/src/utils/SafeTransferLib.sol";

contract MockGravity {
    using SafeTransferLib for ERC20;
    error InvalidSendToCosmos();

    function sendToCosmos(
        address _tokenContract,
        bytes32,
        uint256 _amount
    ) external {
        // we snapshot our current balance of this token
        uint256 ourStartingBalance = ERC20(_tokenContract).balanceOf(address(this));

        // attempt to transfer the user specified amount
        ERC20(_tokenContract).safeTransferFrom(msg.sender, address(this), _amount);

        // check what this particular ERC20 implementation actually gave us, since it doesn't
        // have to be at all related to the _amount
        uint256 ourEndingBalance = ERC20(_tokenContract).balanceOf(address(this));

        // a very strange ERC20 may trigger this condition, if we didn't have this we would
        // underflow, so it's mostly just an error message printer
        if (ourEndingBalance <= ourStartingBalance) {
            revert InvalidSendToCosmos();
        }
    }

    receive() external payable {}
}