// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import { ERC20 } from "@rari-capital/solmate/src/tokens/ERC20.sol";
import { SafeTransferLib } from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAaveIncentivesController } from "./interfaces/IAaveIncentivesController.sol";
import { IStakedTokenV2 } from "./interfaces/IStakedTokenV2.sol";
import { ICurveSwaps } from "./interfaces/ICurveSwaps.sol";
import { ISushiSwapRouter } from "./interfaces/ISushiSwapRouter.sol";
import { IGravity } from "./interfaces/IGravity.sol";
import { ILendingPool } from "./interfaces/ILendingPool.sol";
import { MathUtils } from "./utils/MathUtils.sol";

import "./Errors.sol";
import { IAaveV2StablecoinCellar } from "./interfaces/IAaveV2StablecoinCellar.sol";

/**
 * @title Sommelier Aave V2 Stablecoin Cellar
 * @notice Dynamic ERC4626 that changes positions to always get the best yield for stablecoins on Aave.
 * @author Brian Le
 */
contract AaveV2StablecoinCellar is IAaveV2StablecoinCellar, ERC20, Ownable {
    using SafeTransferLib for ERC20;
    using MathUtils for uint256;

    /**
     * @notice The asset that makes up the cellar's holding pool. Will change whenever the cellar
     *         rebalances into a new position.
     * @dev The cellar denotes its inactive assets in this token. While it waits in the holding pool
     *      to be entered into a position, it is used as exit liquidity from those redeeming their
     *      shares for capital efficiency.
     */
    ERC20 public asset;

    /**
     * @notice An interest-bearing derivative of the current asset returned by Aave for lending
     *         the current asset. Represents cellar's portion of active assets earning yield in a
     *         lending position.
     */
    ERC20 public assetAToken;

    /**
     * @notice The decimals of precision used by the current asset.
     * @dev Since stablecoins don't use the standard 18 decimals of precision (eg. USDC and USDT),
     *      we cache this to use for decimal conversions when performing calculations and storing data.
     */
    uint8 public assetDecimals;

    /**
     * @notice Mapping from a user's address to all their deposits and balances.
     * @dev Used to determining which of a user's shares are active (ie. entered into a position earning
     *      yield vs inactive (ie. waiting in the holding pool to be entered into a position and not
     *      earning yield).
     */
    mapping(address => UserDeposit[]) public userDeposits;

    /**
     * @notice Mapping from a user's address to the index of their first non-zero deposit in `userDeposits`.
     * @dev Saves gas when looping through all of a user's deposits.
     */
    mapping(address => uint256) public currentDepositIndex;

    /**
     * @notice Whether an asset position is trusted or not. Prevents cellar from rebalancing into an
     *         asset that has not been trusted by the users. Trusting / distrusting of an asset is done
     *         through governance.
     */
    mapping(address => bool) public isTrusted;

    /**
     * @notice Last time all inactive assets were entered into a strategy and made active. Used to
     *         determining which of a user's shares are active.
     */
    uint256 public lastTimeEnteredPosition;

    /**
     * @notice The value fees are divided by to get a percentage. Represents the maximum percent (100%).
     */
    uint256 public constant DENOMINATOR = 100_00;

    /**
     * @notice The percentage of platform fees taken off of active assets over a year.
     */
    uint256 public constant PLATFORM_FEE = 1_00; // 1%

    /**
     * @notice The percentage of performance fees taken off of cellar gains.
     */
    uint256 public constant PERFORMANCE_FEE = 10_00; // 10%

    /**
     * @notice Stores fee-related data.
     */
    IAaveV2StablecoinCellar.Fees public fees;

    /**
     * @notice Cosmos address of the fee distributor as a hex value.
     * @dev The Gravity contract expects a 32-byte value formatted in a specific way.
     */
    bytes32 public feesDistributor = hex"000000000000000000000000b813554b423266bbd4c16c32fa383394868c1f55";

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
     * @notice Whether or not the contract is shutdown in case of an emergency.
     */
    bool public isShutdown;

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
        address[] memory _approvedPositions,
        ICurveSwaps _curveRegistryExchange,
        ISushiSwapRouter _sushiswapRouter,
        ILendingPool _lendingPool,
        IAaveIncentivesController _incentivesController,
        IGravity _gravityBridge,
        IStakedTokenV2 _stkAAVE,
        ERC20 _AAVE,
        ERC20 _WETH
    ) ERC20("Sommelier Aave V2 Stablecoin Cellar LP Token", "aave2-CLR-S", 18) {
        // Initialize immutables.
        curveRegistryExchange =  _curveRegistryExchange;
        sushiswapRouter = _sushiswapRouter;
        lendingPool = _lendingPool;
        incentivesController = _incentivesController;
        gravityBridge = _gravityBridge;
        stkAAVE = _stkAAVE;
        AAVE = _AAVE;
        WETH = _WETH;

        // Initialize asset.
        isTrusted[address(_asset)] = true;
        _updatePosition(address(_asset));

        // Initialize limits.
        uint256 powOfAssetDecimals = 10**assetDecimals;
        liquidityLimit = 5_000_000 * powOfAssetDecimals;
        depositLimit = 50_000 * powOfAssetDecimals;

        // Initialize approved positions.
        for (uint256 i; i < _approvedPositions.length; i++) isTrusted[_approvedPositions[i]] = true;

        // Transfer ownership to the Gravity Bridge.
        transferOwnership(address(_gravityBridge));
    }

    // =============================== DEPOSIT/WITHDRAWAL OPERATIONS ===============================

    /**
     * @notice Deposits assets and mints the shares to receiver.
     * @param assets amount of assets to deposit
     * @param receiver address receiving the shares
     * @return shares amount of shares minted
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        // Depositing above balance will only deposit balance.
        uint256 depositableAssets = asset.balanceOf(msg.sender);
        if (assets > depositableAssets) assets = depositableAssets;

        (, shares) = _deposit(assets, 0, receiver);
    }

    /**
     * @notice Mints shares to receiver by depositing assets.
     * @param shares amount of shares to mint
     * @param receiver address receiving the shares
     * @return assets amount of assets deposited
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets) {
        // Depositing above balance will only deposit balance.
        uint256 mintableShares = previewDeposit(asset.balanceOf(msg.sender));
        if (shares > mintableShares) shares = mintableShares;

        (assets, ) = _deposit(0, shares, receiver);
    }


    function _deposit(uint256 assets, uint256 shares, address receiver) internal returns (uint256, uint256) {
        if (isShutdown) revert STATE_ContractShutdown();

        // Must calculate before assets are transferred in.
        shares > 0 ? assets = previewMint(shares) : shares = previewDeposit(assets);

        // Prevent event spamming and user deposit spamming.
        if (shares == 0) revert USR_ZeroShares();

        // Enforce global liquidity restrictions and deposit restrictions per wallet.
        if (assets > maxDeposit(receiver)) revert USR_DepositRestricted(assets, maxDeposit(receiver));

        // Transfers assets into the cellar.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        // Mint user tokens that represents their share of the cellar's assets.
        _mint(receiver, shares);

        // Store the user's deposit data. This will be used later on when the user wants to withdraw
        // their assets or transfer their shares.
        UserDeposit[] storage deposits = userDeposits[receiver];
        deposits.push(UserDeposit({
            // Always store asset amounts with 18 decimals of precision regardless of the asset's
            // decimals. This is so we can still use this data even after rebalancing to different
            // asset.
            assets: uint112(assets.changeDecimals(assetDecimals, decimals)),
            shares: uint112(shares),
            timeDeposited: uint32(block.timestamp)
        }));

        emit Deposit(
            msg.sender,
            receiver,
            address(asset),
            assets,
            shares
        );

        return (assets, shares);
    }

    /**
     * @notice Withdraws assets to receiver by redeeming shares from owner.
     * @param assets amount of assets being withdrawn
     * @param receiver address of account receiving the assets
     * @param owner address of the owner of the shares being redeemed
     * @return shares amount of shares redeemed
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares) {
        // Ensures proceeding calculations are done with a standard 18 decimals of precision. Will
        // change back to the using the asset's usual decimals of precision when transferring assets
        // after all calculations are done.
        assets = assets.changeDecimals(assetDecimals, decimals);

        // Withdrawing above balance will only withdraw balance.
        (, shares) = _withdraw(assets, receiver, owner);
    }

    /**
     * @notice Redeems shares from owner to withdraw assets to receiver.
     * @param shares amount of shares redeemed
     * @param receiver address of account receiving the assets
     * @param owner address of the owner of the shares being redeemed
     * @return assets amount of assets sent to receiver
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets) {
        // Withdrawing above balance will only withdraw balance.
        (assets, ) = _withdraw(_convertToAssets(shares), receiver, owner);
    }

    /**
     * @dev `assets` must be passed in with 18 decimals of precision. Must extend/truncate decimals of
     *       the amount passed in if necessary to ensure this is true.
     */
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal returns (uint256, uint256) {
        if (balanceOf[owner] == 0) revert USR_ZeroShares();
        if (assets == 0) revert USR_ZeroAssets();

        // Tracks amount of shares to redeem.
        uint256 shares;

        // Retrieve the user's deposits to begin looping through them, generally from oldest to
        // newest deposits. This may not be the case if shares have been transferred to the owner,
        // which will be added to the end of the owner's deposits regardless of time deposited.
        UserDeposit[] storage deposits = userDeposits[owner];

        // Tracks the amount of assets left to withdraw. Updated at the end of each loop.
        uint256 leftToWithdraw = assets;

        // Saves gas by avoiding calling `_convertToAssets` on active shares during each loop.
        uint256 exchangeRate = _convertToAssets(1e18);

        for (uint256 i = currentDepositIndex[owner]; i < deposits.length; i++) {
            UserDeposit storage d = deposits[i];

            // Whether or not deposited shares are active or inactive.
            bool isActive = d.timeDeposited < lastTimeEnteredPosition;

            // If shares are active, convert them to the amount of assets they're worth to get the
            // maximum amount of assets withdrawable from this deposit.
            uint256 dAssets = isActive ? uint256(d.shares).mulWadDown(exchangeRate) : d.assets;

            // Determine the amount of assets and shares to withdraw from this deposit.
            uint256 withdrawnAssets = MathUtils.min(leftToWithdraw, dAssets);
            uint256 withdrawnShares = uint256(d.shares).mulDivUp(withdrawnAssets, dAssets);

            // For active shares, deletes the deposit data we don't need anymore for a gas refund.
            if (isActive) {
                delete d.assets;
                delete d.timeDeposited;
            } else {
                // Substract the amount of assets taken for this withdraw.
                d.assets -= uint112(withdrawnAssets);
            }

            // Subtract shares withdrawn and add to total.
            d.shares -= uint112(withdrawnShares);
            shares += withdrawnShares;

            // Update the counter of assets left to withdraw.
            leftToWithdraw -= withdrawnAssets;

            // Break if this is the last deposit or there is nothing left to withdraw.
            if (i == deposits.length - 1 || leftToWithdraw == 0) {
                // Store the user's next non-zero deposit to save gas on future looping.
                currentDepositIndex[owner] = d.shares != 0 ? i : i+1;
                break;
            }
        }

        // Check to see if the caller is approved to spend shares.
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Redeem shares.
        _burn(owner, shares);

        // Determine the total amount of assets withdrawn.
        assets -= leftToWithdraw;

        // Convert assets decimals back for transfers.
        assets = assets.changeDecimals(decimals, assetDecimals);

        // Only withdraw from position if holding pool does not contain enough funds.
        _allocateAssets(assets);

        // Transfer assets to receiver from the cellar's holding pool.
        asset.safeTransfer(receiver, assets);

        emit Withdraw(receiver, owner, address(asset), assets, shares);

        // The amount of assets actually withdrawn may be less than assets attempted to withdraw
        // if attempted withdraw amount was less than the withdrawable balance.
        return (assets, shares);
    }

    // ================================== ACCOUNTING OPERATIONS ==================================

    /**
     * @dev The internal functions always use 18 decimals of precision while the public functions use
     *      as many decimals as the current asset (aka they don't change the decimals). This is
     *      because we want the user deposit data the cellar stores to be usable across different
     *      assets regardless of the decimals used. This means the cellar will always perform
     *      calculations and store data with a standard of 18 decimals of precision but will change
     *      the decimals back when transferring assets outside the contract or returning data
     *      through public view functions.
     */

    /**
     * @notice Total amount of active asset entered into the current position.
     * @dev The aTokens' value is pegged to the value of the corresponding asset at a 1:1 ratio. We
     *      can find the amount of assets active in a position simply by taking balance of aTokens
     *      cellar holds.
     */
    function activeAssets() public view returns (uint256) {
        return assetAToken.balanceOf(address(this));
    }

    /**
     * @dev Same as `activeAssets` but forcibly denoted with 18 decimals of precision.
     */
    function _activeAssets() internal view returns (uint256) {
        uint256 assets = assetAToken.balanceOf(address(this));
        return assets.changeDecimals(assetDecimals, decimals);
    }

    /**
     * @notice Total amount of inactive asset in holding.
     */
    function inactiveAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
     * @dev Same as `inactiveAssets` but forcibly denoted with 18 decimals of precision.
     */
    function _inactiveAssets() internal view returns (uint256) {
        uint256 assets = asset.balanceOf(address(this));
        return assets.changeDecimals(assetDecimals, decimals);
    }

    /**
     * @notice Total amount of the asset managed by the cellar.
     */
    function totalAssets() public view returns (uint256) {
        return activeAssets() + inactiveAssets();
    }

    /**
     * @dev Same as `totalAssets` but forcibly denoted with 18 decimals of precision.
     */
    function _totalAssets() internal view returns (uint256) {
        return _activeAssets() + _inactiveAssets();
    }

    /**
     * @notice The amount of shares that the cellar would exchange for the amount of assets provided
     *         ASSUMING they are active.
     * @param assets amount of assets to convert
     * @return shares the assets can be exchanged for
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        assets = assets.changeDecimals(assetDecimals, decimals);
        return _convertToShares(assets);
    }

    /**
     * @dev Same as `convertToShares` but forcibly denoted with 18 decimals of precision.
     */
    function _convertToShares(uint256 assets) internal view returns (uint256) {
        uint256 currentTotalAssets =  _totalAssets();
        uint256 currentTotalSupply = totalSupply;
        return currentTotalAssets == 0 || currentTotalSupply == 0 ?
            assets :
            assets.mulDivDown(currentTotalSupply, currentTotalAssets);
    }

    /**
     * @notice The amount of assets that the cellar would exchange for the amount of shares provided
     *         ASSUMING they are active.
     * @param shares amount of shares to convert
     * @return assets the shares can be exchanged for
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 assets = _convertToAssets(shares);
        return assets.changeDecimals(decimals, assetDecimals);
    }

    /**
     * @dev Same as `convertToAssets` but forcibly denoted with 18 decimals of precision.
     */
    function _convertToAssets(uint256 shares) internal view returns (uint256) {
        return totalSupply == 0 ? shares : shares.mulDivDown(_totalAssets(), totalSupply);
    }

    /**
    * @notice Simulate the effects of depositing assets at the current block, given current on-chain
    *         conditions.
     * @param assets amount of assets to deposit
     * @return shares that will be minted
     */
    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    /**
    * @notice Simulate the effects of minting shares at the current block, given current on-chain
    *         conditions.
     * @param shares amount of shares to mint
     * @return assets that will be deposited
     */
    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        uint256 assets = supply == 0 ? shares : shares.mulDivUp(_totalAssets(), supply);
        return assets.changeDecimals(decimals, assetDecimals);
    }

    /**
    * @notice Simulate the effects of withdrawing assets at the current block, given current
    *         on-chain conditions ASSUMING the shares being redeemed are all active.
     * @param assets amount of assets to withdraw
     * @return shares that will be redeemed
     */
    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    /**
    * @notice Simulate the effects of redeeming shares at the current block, given current on-chain
    *         conditions ASSUMING the shares being redeemed are all active.
     * @param shares amount of sharers to redeem
     * @return assets that can be withdrawn
     */
    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    // ======================================= STATE INFORMATION =====================================

    /**
     * @notice Retrieve information on a user's deposit balances.
     * @param user address of the user
     * @return userActiveShares amount of active shares the user has
     * @return userInactiveShares amount of inactive shares the user has
     * @return userActiveAssets amount of active assets the user has
     * @return userInactiveAssets amount of inactive assets the user has
     */
    function getUserBalances(address user) external view returns (
        uint256 userActiveShares,
        uint256 userInactiveShares,
        uint256 userActiveAssets,
        uint256 userInactiveAssets
    ) {
        // Retrieve the user's deposits to begin looping through them, generally from oldest to
        // newest deposits. This may not be the case though if shares have been transferred to the
        // user, which will be added to the end of the user's deposits regardless of time
        // deposited.
        UserDeposit[] storage deposits = userDeposits[user];

        // Saves gas by avoiding calling `_convertToAssets` on active shares during each loop.
        uint256 exchangeRate = _convertToAssets(1e18);

        for (uint256 i = currentDepositIndex[user]; i < deposits.length; i++) {
            UserDeposit storage d = deposits[i];

            // Determine whether or not deposit is active or inactive.
            if (d.timeDeposited < lastTimeEnteredPosition) {
                // Saves an extra SLOAD if active and cast type to uint256.
                uint256 dShares = d.shares;

                userActiveShares += dShares;
                userActiveAssets += dShares.mulWadDown(exchangeRate); // Convert active shares to assets.
            } else {
                userInactiveShares += d.shares;
                userInactiveAssets += d.assets;
            }
        }

        // Return assets in their original units.
        userActiveAssets = userActiveAssets.changeDecimals(decimals, assetDecimals);
        userInactiveAssets = userInactiveAssets.changeDecimals(decimals, assetDecimals);
    }

    /**
     * @notice Retrieve a list of all of a user's deposits.
     * @dev This is provided because Solidity converts public arrays into index getters,
     *      but we need a way to allow external contracts and users to access the whole array.
     * @param user address of the user
     * @return array of all the users deposits
     */
    function getUserDeposits(address user) external view returns (UserDeposit[] memory) {
        return userDeposits[user];
    }

    // =========================== DEPOSIT/WITHDRAWAL LIMIT OPERATIONS ===========================

    /**
     * @notice Total number of assets that can be deposited by owner into the cellar.
     * @param owner address of account that would receive the shares
     * @return maximum amount of assets that can be deposited
     */
    function maxDeposit(address owner) public view returns (uint256) {
        if (isShutdown) return 0;

        if (depositLimit == type(uint256).max && liquidityLimit == type(uint256).max)
            // Conversion to fixed point will overflow if the number being converted has more integer
            // digits that fit in the bits reserved for them in the fixed point representation. This
            // is the maximum assets that can be deposited without overflowing.
            return uint256(type(uint112).max) / 10**(decimals - assetDecimals);

        uint256 leftUntilDepositLimit = depositLimit.subMin0(maxWithdraw(owner));
        uint256 leftUntilLiquidityLimit = liquidityLimit.subMin0(totalAssets());

        // Only return the more relevant of the two.
        return MathUtils.min(leftUntilDepositLimit, leftUntilLiquidityLimit);
    }

    /**
     * @notice Total number of shares that can be minted for owner from the cellar.
     * @param owner address of account that would receive the shares
     * @return maximum amount of shares that can be minted
     */
    function maxMint(address owner) public view returns (uint256) {
        return convertToShares(maxDeposit(owner));
    }

    /**
     * @notice Total number of assets that can be withdrawn from the cellar.
     * @param owner address of account that would holds the shares
     * @return maximum amount of assets that can be withdrawn
     */
    function maxWithdraw(address owner) public view returns (uint256) {
        UserDeposit[] storage deposits = userDeposits[owner];

        // Track max assets that can be withdrawn.
        uint256 assets;

        // Saves gas by avoiding calling `_convertToAssets` on active shares during each loop.
        uint256 exchangeRate = _convertToAssets(1e18);

        for (uint256 i = currentDepositIndex[owner]; i < deposits.length; i++) {
            UserDeposit storage d = deposits[i];

            // Determine the amount of assets that can be withdrawn. Only redeem active shares for
            // assets, otherwise just withdrawn the original amount of assets that were deposited.
            assets += d.timeDeposited < lastTimeEnteredPosition ?
                uint256(d.shares).mulWadDown(exchangeRate) :
                d.assets;
        }

        // Converts back to decimals used by that asset.
        return assets.changeDecimals(decimals, assetDecimals);
    }

    /**
     * @notice Total number of shares that can be redeemed from the cellar.
     * @param owner address of account that would holds the shares
     * @return maximum amount of shares that can be redeemed
     */
    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }

    // ====================================== FEE OPERATIONS ======================================

    /**
     * @notice Take platform fees and performance fees off of cellar's active assets.
     */
    function accrueFees() external updateYield {
        // Platform fees taken each accrual = activeAssets * (elapsedTime * (feePercentage / SECS_PER_YEAR)).
        uint256 elapsedTime = block.timestamp - fees.lastTimeAccruedPlatformFees;
        uint256 platformFeeInAssets = (_activeAssets() * elapsedTime * PLATFORM_FEE) / DENOMINATOR / 365 days;
        uint256 platformFees = _convertToShares(platformFeeInAssets);

        // Update tracking of last time platform fees were accrued.
        fees.lastTimeAccruedPlatformFees = uint32(block.timestamp);

        // Mint the cellar accrued platform fees as shares.
        _mint(address(this), platformFees);

        // Performance fees taken each accrual = yield * feePercentage
        uint256 yield = fees.yield;
        uint256 performanceFeeInAssets = yield.mulDivDown(PERFORMANCE_FEE, DENOMINATOR);
        uint256 performanceFees = _convertToShares(performanceFeeInAssets);

        // Reset tracking of yield since last accrual.
        fees.yield = 0;

        // Mint the cellar accrued performance fees as shares.
        _mint(address(this), performanceFees);

        // Update fees that have been accrued.
        fees.accruedPlatformFees += uint112(platformFees);
        fees.accruedPerformanceFees += uint112(performanceFees);

        emit AccruedPlatformFees(platformFees);
        emit AccruedPerformanceFees(performanceFees);
    }

    /**
     * @notice Tracks yield the cellar has gained since the last time fees were accrued.
     * @dev Must be called every time a function is called that updates `activeAssets`.
     */
    modifier updateYield() {
        uint256 currentActiveAssets = _activeAssets();
        uint256 lastActiveAssets = fees.lastActiveAssets;

        if (currentActiveAssets > lastActiveAssets) {
            fees.yield += uint112(currentActiveAssets - lastActiveAssets);
        }

        _;

        // Update this for next performance fee accrual.
        fees.lastActiveAssets = uint112(_activeAssets());
    }

    /**
     * @notice Transfer accrued fees to the Sommelier Chain to distribute.
     */
    function transferFees() external onlyOwner {
        // Cellar fees are accrued in shares and redeemed upon transfer.
        uint256 totalFees = ERC20(this).balanceOf(address(this));
        uint256 feeInAssets = previewRedeem(totalFees);

        // Redeem our fee shares for assets to transfer to Cosmos.
        _burn(address(this), totalFees);

        // Only withdraw assets from position if the holding pool does not contain enough funds.
        // Otherwise, all assets will come from the holding pool.
        _allocateAssets(feeInAssets);

        // Transfer assets to a fee distributor on the Sommelier Chain.
        asset.safeApprove(address(gravityBridge), feeInAssets);
        gravityBridge.sendToCosmos(address(asset), feesDistributor, feeInAssets);

        emit TransferFees(fees.accruedPlatformFees, fees.accruedPerformanceFees);

        // Reset the tracker for fees accrued that are still waiting to be transferred.
        fees.accruedPlatformFees = 0;
        fees.accruedPerformanceFees = 0;
    }

    // =================================== GOVERNANCE OPERATIONS ===================================

    /**
     * @notice Trust or distrust an asset position on Aave (eg. FRAX, UST, FEI).
     */
    function setTrust(address position, bool trust) external onlyOwner {
        isTrusted[position] = trust;

        // In the case that governance no longer trust the current position, pull all assets back into
        // the cellar.
        if (trust == false && position == address(asset)) _withdrawFromAave(address(asset), type(uint256).max);
    }

    /**
     * @notice Stop or start the contract. Used in an emergency or if the cellar has been retired.
     */
    function setShutdown(bool shutdown, bool exitPosition) external onlyOwner {
        isShutdown = shutdown;

        // Withdraw everything from the current position on Aave if specified when shutting down.
        if (shutdown && exitPosition) _withdrawFromAave(address(asset), type(uint256).max);

        emit Shutdown(shutdown, exitPosition);
    }

    /**
     * @notice Update the address of the fee distributor on the Sommelier Chain. IMPORTANT: Ensure
     *         that the address is formatted in the specific way that the Gravity contract expects
     *         it to be.
     */
    function setFeesDistributor(bytes32 newFeesDistributor) external onlyOwner {
        // Store for emitted event.
        bytes32 oldFeesDistributor = feesDistributor;

        // Change the fees distributor address.
        feesDistributor = newFeesDistributor;

        emit FeesDistributorChanged(oldFeesDistributor, newFeesDistributor);
    }

    // ===================================== ADMIN OPERATIONS =====================================

    /**
     * @notice Enters into the current Aave stablecoin position.
     */
    function enterPosition() external onlyOwner {
        if (isShutdown) revert STATE_ContractShutdown();

        uint256 currentInactiveAssets = inactiveAssets();

        // Deposits all inactive assets into the current position.
        _depositToAave(address(asset), currentInactiveAssets);

        // Update the last time cellar entered position.
        lastTimeEnteredPosition = block.timestamp;

        emit EnterPosition(address(asset), currentInactiveAssets);
    }

    /**
     * @notice Rebalances current assets into a new asset position.
     * @param route array of [initial token, pool, token, pool, token, ...] that specifies the swap route
     * @param swapParams multidimensional array of [i, j, swap type] where i and j are the correct
                         values for the n'th pool in `_route` and swap type should be 1 for a
                         stableswap `exchange`, 2 for stableswap `exchange_underlying`, 3 for a
                         cryptoswap `exchange`, 4 for a cryptoswap `exchange_underlying` and 5 for
                         Polygon factory metapools `exchange_underlying`
     * @param minAssetsOut minimum amount of assets received from swap
     */
    function rebalance(
        address[9] memory route,
        uint256[3][4] memory swapParams,
        uint256 minAssetsOut
    ) external onlyOwner {
        if (isShutdown) revert STATE_ContractShutdown();

        // Retrieve the last token in the route and store it as the new asset.
        address newAsset;
        for (uint256 i; ; i += 2) {
            if (i == 8 || route[i+1] == address(0)) {
                newAsset = route[i];
                break;
            }
        }

        // Doesn't make sense to rebalance into the same asset.
        if (newAsset == address(asset)) revert USR_SameAsset(newAsset);

        // Pull all active assets entered into Aave back into the cellar so we can swap everything
        // into the new asset.
        _withdrawFromAave(address(asset), type(uint256).max);

        uint256 currentInactiveAssets = inactiveAssets();

        // Perform stablecoin swap using Curve.
        asset.safeApprove(address(curveRegistryExchange), currentInactiveAssets);
        uint256 amountOut = curveRegistryExchange.exchange_multiple(
            route,
            swapParams,
            currentInactiveAssets,
            minAssetsOut
        );

        // Store this later for the event we will emit.
        address oldAsset = address(asset);

        // Updates state for our new position and check to make sure Aave supports it before
        // rebalancing.
        _updatePosition(newAsset);

        // Deposit all newly swapped assets into Aave.
        _depositToAave(address(asset), amountOut);

        // Update the last time all inactive assets were entered into a position.
        lastTimeEnteredPosition = block.timestamp;

        emit Rebalance(oldAsset, newAsset, amountOut);
    }

    /**
     * @notice Reinvest rewards back into cellar's current position.
     * @dev Must be called within 2 day unstake period 10 days after `claimAndUnstake` was run.
     * @param minAssetsOut minimum amount of assets received after swapping AAVE to the current asset
     */
    function reinvest(uint256 minAssetsOut) external onlyOwner {
        // Redeems the cellar's stkAAVE rewards for AAVE.
        stkAAVE.redeem(address(this), type(uint256).max);

        uint256 amountIn = AAVE.balanceOf(address(this));

        // Specify the swap path from AAVE -> WETH -> current asset.
        address[] memory path = new address[](3);
        path[0] = address(AAVE);
        path[1] = address(WETH);
        path[2] = address(asset);

        // Perform a multihop swap using Sushiswap.
        AAVE.safeApprove(address(sushiswapRouter), amountIn);
        uint256[] memory amounts = sushiswapRouter.swapExactTokensForTokens(
            amountIn,
            minAssetsOut,
            path,
            address(this),
            block.timestamp + 60
        );

        uint256 amountOut = amounts[amounts.length - 1];

        // Count reinvested rewards as yield.
        fees.yield += uint112(amountOut.changeDecimals(assetDecimals, decimals));

        // In the case of a shutdown, we just may want to redeem any leftover rewards for users to
        // claim but without entering them back into a position in case the position has been exited.
        if (!isShutdown) _depositToAave(address(asset), amountOut);

        emit Reinvest(address(asset), amountIn, amountOut);
    }

    /**
     * @notice Claim rewards from Aave and begin cooldown period to unstake them.
     * @return claimed amount of rewards claimed from Aave
     */
    function claimAndUnstake() external onlyOwner returns (uint256 claimed) {
        // Necessary to do as `claimRewards` accepts a dynamic array as first param.
        address[] memory aToken = new address[](1);
        aToken[0] = address(assetAToken);

        // Claim all stkAAVE rewards.
        claimed = incentivesController.claimRewards(aToken, type(uint256).max, address(this));

        // Begin the cooldown period for unstaking stkAAVE to later redeem for AAVE.
        stkAAVE.cooldown();

        emit ClaimAndUnstake(claimed);
    }

    /**
     * @notice Sweep tokens sent here that are not managed by the cellar.
     * @dev This may be used in case the wrong tokens are accidentally sent to this contract.
     * @param token address of token to transfer out of this cellar
     * @param to address to transfer sweeped tokens to
     */
    function sweep(address token, address to) external onlyOwner {
        // Prevent sweeping of assets managed by the cellar and shares minted to the cellar as fees.
        if (token == address(asset) || token == address(assetAToken) || token == address(this))
            revert USR_ProtectedAsset(token);

        // Transfer out tokens in this cellar that shouldn't be here.
        uint256 amount = ERC20(token).balanceOf(address(this));
        ERC20(token).safeTransfer(to, amount);

        emit Sweep(token, to, amount);
    }

    /**
     * @notice Sets the maximum liquidity that cellar can manage. Careful to use the same decimals as the
     *         current asset.
     */
    function setLiquidityLimit(uint256 limit) external onlyOwner {
        // Store for emitted event.
        uint256 oldLimit = liquidityLimit;

        // Change the liquidity limit.
        liquidityLimit = limit;

        emit LiquidityLimitChanged(oldLimit, limit);
    }

    /**
     * @notice Sets the per-wallet deposit limit. Careful to use the same decimals as the current asset.
     */
    function setDepositLimit(uint256 limit) external onlyOwner {
        // Store for emitted event.
        uint256 oldLimit = depositLimit;

        // Change the deposit limit.
        depositLimit = limit;

        emit DepositLimitChanged(oldLimit, limit);
    }

    // ========================================== HELPERS ==========================================

    /**
     * @notice Update state variables related to the current position.
     * @dev Be aware that when updating to an asset that uses less decimals than the previous
     *      asset (eg. DAI -> USDC), `depositLimit` and `liquidityLimit` will lose some precision
     *      due to truncation.
     * @param newAsset address of the new asset being managed by the cellar
     */
    function _updatePosition(address newAsset) internal {
        // Retrieve the aToken that will represent the cellar's new position on Aave.
        (, , , , , , , address aTokenAddress, , , , ) = lendingPool.getReserveData(newAsset);

        // If the address is not null, it is supported by Aave.
        if (aTokenAddress == address(0)) revert USR_UnsupportedPosition(newAsset);

        // Update the decimals used by limits if necessary.
        uint8 oldAssetDecimals = assetDecimals;
        uint8 newAssetDecimals = ERC20(newAsset).decimals();

        // Ensure the decimals of precision the new position uses will not break the cellar.
        if (newAssetDecimals > decimals) revert USR_TooManyDecimals(newAssetDecimals, decimals);

        // Ignore if decimals are the same or if it is the first time initializing a position.
        if (oldAssetDecimals != 0 && oldAssetDecimals != newAssetDecimals) {
            if (depositLimit != type(uint256).max) {
                depositLimit = depositLimit.changeDecimals(oldAssetDecimals, newAssetDecimals);
            }

            if (liquidityLimit != type(uint256).max) {
                liquidityLimit = liquidityLimit.changeDecimals(oldAssetDecimals, newAssetDecimals);
            }
        }

        // Update state related to the current position.
        asset = ERC20(newAsset);
        assetDecimals = newAssetDecimals;
        assetAToken = ERC20(aTokenAddress);
    }

    /**
     * @notice Ensures there is enough assets in the contract available for a transfer.
     * @dev Only withdraws from the current position if necessary.
     * @param assets The amount of assets to allocate
     */
    function _allocateAssets(uint256 assets) internal {
        uint256 currentInactiveAssets = inactiveAssets();

        // Only withdraw if not enough assets in the holding pool.
        if (assets > currentInactiveAssets) _withdrawFromAave(address(asset), assets - currentInactiveAssets);
    }

    /**
     * @notice Deposits cellar holdings into an Aave lending pool.
     * @param position the address of the asset position
     * @param assets the amount of assets to deposit
     */
    function _depositToAave(address position, uint256 assets) internal updateYield {
        // Ensure the position has been trusted by governance.
        if (!isTrusted[position]) revert USR_UntrustedPosition(position);

        // Initialize starting point for first platform fee accrual to time when cellar first deposits
        // assets into a position on Aave.
        if (fees.lastTimeAccruedPlatformFees == 0) fees.lastTimeAccruedPlatformFees = uint32(block.timestamp);

        // Deposit assets into Aave position.
        ERC20(position).safeApprove(address(lendingPool), assets);
        lendingPool.deposit(position, assets, address(this), 0);

        emit DepositToAave(position, assets);
    }

    /**
     * @notice Withdraws assets from Aave.
     * @param position the address of the asset position
     * @param assets the amount of assets to withdraw
     */
    function _withdrawFromAave(address position, uint256 assets) internal updateYield {
        // Skip withdrawal instead of reverting if there are no active assets to withdraw. Reverting
        // could potentially prevent important function calls from executing, such as `shutdown`, in
        // the case where there were no active assets because Aave would throw an error.
        if (activeAssets() > 0) {
            // Withdraw assets from Aave position.
            uint256 withdrawnAmount = lendingPool.withdraw(position, assets, address(this));


            // `withdrawnAmount` may be less than `assets` if cellar tried withdrawing more than
            // it's balance on Aave.
            emit WithdrawFromAave(position, withdrawnAmount);
        }
    }

    // ================================= SHARE TRANSFER OPERATIONS =================================

    /**
     * @dev Modified versions of Solmate's ERC20 transfer and transferFrom functions to work with the
     *      cellar's active vs inactive shares model.
     */

    /**
     * @notice Transfers shares from one account to another.
     * @param from address that is sending shares
     * @param to address that is receiving shares
     * @param amount amount of shares to transfer
     * @param onlyActive whether to only transfer active shares
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bool onlyActive
    ) public returns (bool) {
        // If the sender is not the owner of the shares, check to see if the owner has approved them
        // to spend their shares.
        if (from != msg.sender) {
            uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        }

        // Will revert here if sender is trying to transfer more shares then they have, so no need
        // for an explicit check.
        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        // Retrieve the deposits from sender then begin looping through deposits, generally from
        // oldest to newest deposits. This may not be the case though if shares have been
        // transferred to the sender, as they will be added to the end of the sender's deposits
        // regardless of time deposited.
        UserDeposit[] storage depositsFrom = userDeposits[from];

        // Tracks the amount of shares left to transfer; updated at the end of each loop.
        uint256 leftToTransfer = amount;

        for (uint256 i = currentDepositIndex[from]; i < depositsFrom.length; i++) {
            UserDeposit storage dFrom = depositsFrom[i];

            // If we only want to transfer active shares, skips this deposit if it is inactive.
            bool isActive = dFrom.timeDeposited < lastTimeEnteredPosition;
            if (onlyActive && !isActive) continue;

            // Saves an extra SLOAD if active and cast type to uint256.
            uint256 dFromShares = dFrom.shares;

            // Determine the amount of assets and shares to transfer from this deposit.
            uint256 transferredShares = MathUtils.min(leftToTransfer, dFromShares);
            uint256 transferredAssets = uint256(dFrom.assets).mulDivUp(transferredShares, dFromShares);

            // For active shares, deletes the deposit data we don't need anymore for a gas refund.
            if (isActive) {
                delete dFrom.assets;
                delete dFrom.timeDeposited;
            } else {
                dFrom.assets -= uint112(transferredAssets);
            }

            // Taken shares from this deposit to transfer.
            dFrom.shares -= uint112(transferredShares);

            // Transfer new deposit to the end of receiver's list of deposits.
            userDeposits[to].push(UserDeposit({
                assets: isActive ? 0 : uint112(transferredAssets),
                shares: uint112(transferredShares),
                timeDeposited: isActive ? 0 : dFrom.timeDeposited
            }));

            // Update the counter of assets left to transfer.
            leftToTransfer -= transferredShares;

            // Break if not shares left to transfer.
            if (leftToTransfer == 0) {
                // Only store the index for the next non-zero deposit to save gas on looping if
                // inactive deposits weren't skipped.
                if (!onlyActive) currentDepositIndex[from] = dFrom.shares != 0 ? i : i+1;
                break;
            }
        }

        // Will only happen if exhausted through all deposits and did not enough active shares to
        // transfer.
        if (leftToTransfer != 0) revert USR_NotEnoughActiveShares(leftToTransfer, amount);

        emit Transfer(from, to, amount);

        return true;
    }

    /**
     * @dev For compatibility with ERC20 standard.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        // Defaults to allowing both active and inactive shares to be transferred.
        return transferFrom(from, to, amount, false);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        // Defaults to allowing both active and inactive shares to be transferred.
        return transferFrom(msg.sender, to, amount, false);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
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
pragma solidity 0.8.11;

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
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
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
pragma solidity 0.8.11;

interface IStakedTokenV2 {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function stakersCooldowns(address account) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

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
pragma solidity 0.8.11;

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
pragma solidity 0.8.11;

interface IGravity {
    function sendToCosmos(
        address _tokenContract,
        bytes32 _destination,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

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
pragma solidity 0.8.11;

library MathUtils {
    /**
     * @notice Substract and return 0 instead if results are negative.
     */
    function subMin0(uint256 x, uint256 y) internal pure returns (uint256) {
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
            return ceilDiv(amount, 10**(fromDecimals - toDecimals));
        }
    }

    // ===================================== OPENZEPPELIN'S MATH =====================================

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

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
pragma solidity 0.8.11;

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
 * @notice Attempted swap into an asset that is not the current asset of the cellar.
 * @param assetOut address of the asset attempted to swap to
 * @param currentAsset address of the current asset of cellar
 */
error USR_InvalidSwap(address assetOut, address currentAsset);

/**
 * @notice Attempted to sweep an asset that is managed by the cellar.
 * @param token address of the token that can't be sweeped
 */
error USR_ProtectedAsset(address token);

/**
 * @notice Attempted rebalance into the same asset.
 * @param asset address of the asset
 */
error USR_SameAsset(address asset);

/**
 * @notice Attempted to update the position to one that is not supported by the platform.
 * @param unsupportedPosition address of the unsupported position
 */
error USR_UnsupportedPosition(address unsupportedPosition);

/**
 * @notice Attempted rebalance into an untrusted position.
 * @param asset address of the asset
 */
error USR_UntrustedPosition(address asset);

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

// ========================================== STATE ERRORS ===========================================

/**
 * @dev These errors represent actions that are being prevented due to current contract state.
 *      These errors do not relate to user input, and may or may not be resolved by other actions
 *      or the progression of time.
 */

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
 * @notice The caller attempted to change the epoch length, but current reward epochs were active.
 */
error STATE_RewardsOngoing();

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

/// @title interface for AaveV2StablecoinCellar
interface IAaveV2StablecoinCellar {
    // ======================================= EVENTS =======================================

    /**
     * @notice Emitted when assets are deposited into cellar.
     * @param caller the address of the caller
     * @param token the address of token the cellar receives
     * @param owner the address of the owner of shares
     * @param assets the amount of assets being deposited
     * @param shares the amount of shares minted to owner
     */
    event Deposit(address indexed caller, address indexed owner, address indexed token, uint256 assets, uint256 shares);

    /**
     * @notice Emitted when assets are withdrawn from cellar.
     * @param receiver the address of the receiver of the withdrawn assets
     * @param owner the address of the owner of the shares
     * @param token the address of the token withdrawn
     * @param assets the amount of assets being withdrawn
     * @param shares the amount of shares burned from owner
     */
    event Withdraw(
        address indexed receiver,
        address indexed owner,
        address indexed token,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Emitted on deposit to Aave.
     * @param position the address of the position
     * @param assets the amount of assets to deposit
     */
    event DepositToAave(address indexed position, uint256 assets);

    /**
     * @notice Emitted on withdraw from Aave.
     * @param position the address of the position
     * @param assets the amount of assets to withdraw
     */
    event WithdrawFromAave(address indexed position, uint256 assets);

    /**
     * @notice Emitted upon entering cellar's inactive assets into the current position on Aave.
     * @param position the address of the asset being entered into the current position
     * @param assets amount of assets being entered
     */
    event EnterPosition(address indexed position, uint256 assets);

    /**
     * @notice Emitted upon claiming rewards and beginning cooldown period to unstake them.
     * @param rewardsClaimed amount of rewards that were claimed
     */
    event ClaimAndUnstake(uint256 rewardsClaimed);

    /**
     * @notice Emitted upon reinvesting rewards into the current position.
     * @param token the address of the asset rewards were swapped to
     * @param rewards amount of rewards swapped to be reinvested
     * @param assets amount of assets received from swapping rewards
     */
    event Reinvest(address indexed token, uint256 rewards, uint256 assets);

    /**
     * @notice Emitted on rebalance of Aave poisition.
     * @param oldAsset the address of the asset for the old position
     * @param newAsset the address of the asset for the new position
     * @param assets the amount of the new assets cellar has after rebalancing
     */
    event Rebalance(address indexed oldAsset, address indexed newAsset, uint256 assets);

    /**
     * @notice Emitted when platform fees accrued.
     * @param feesInShares amount of fees accrued in shares
     */
    event AccruedPlatformFees(uint256 feesInShares);

    /**
     * @notice Emitted when performance fees accrued.
     * @param feesInShares amount of fees accrued in shares
     */
    event AccruedPerformanceFees(uint256 feesInShares);

    /**
     * @notice Emitted when platform fees are transferred to Cosmos.
     * @param platformFees amount of platform fees transferred
     * @param performanceFees amount of performance fees transferred
     */
    event TransferFees(uint112 platformFees, uint112 performanceFees);

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

    /**
     * @notice Emitted when fees distributor is changed.
     * @param oldFeesDistributor address of fee distributor was changed from
     * @param newFeesDistributor address of fee distributor was changed to
     */
    event FeesDistributorChanged(bytes32 oldFeesDistributor, bytes32 newFeesDistributor);

    /**
     * @notice Emitted when tokens accidentally sent to cellar are recovered.
     * @param token the address of the token
     * @param to the address sweeped tokens were transferred to
     * @param amount amount transferred out
     */
    event Sweep(address indexed token, address indexed to, uint256 amount);

    /**
     * @notice Emitted when cellar is shutdown.
     * @param isShutdown whether the contract is shutdown
     * @param exitPosition whether to exit the current position
     */
    event Shutdown(bool isShutdown, bool exitPosition);

    // ======================================= STRUCTS =======================================

    /**
     * @notice Stores user deposit data.
     * @param assets amount of assets deposited
     * @param shares amount of shares that were minted for their deposit
     * @param timeDeposited timestamp of when the user deposited
     */
    struct UserDeposit {
        uint112 assets;
        uint112 shares;
        uint32 timeDeposited;
    }

    /**
     * @notice Stores fee-related data.
     */
    struct Fees {
        /**
         * @notice Amount of yield earned since last time performance fees were accrued.
         */
        uint112 yield;
        /**
         * @notice Amount of active assets in cellar since yield was last calculated.
         */
        uint112 lastActiveAssets;
        /**
         * @notice Timestamp of last time platform fees were accrued.
         */
        uint32 lastTimeAccruedPlatformFees;
        /**
         * @notice Amount of platform fees that have been accrued awaiting transfer.
         * @dev Fees are taken in shares and redeemed for assets at the time they are transferred from
         *      the cellar to Cosmos to be distributed.
         */
        uint112 accruedPlatformFees;
        /**
         * @notice Amount of performance fees that have been accrued awaiting transfer.
         * @dev Fees are taken in shares and redeemed for assets at the time they are transferred from
         *      the cellar to Cosmos to be distributed.
         */
        uint112 accruedPerformanceFees;
    }

    // ================================= DEPOSIT/WITHDRAWAL OPERATIONS =================================

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function mint(uint256 shares, address receiver) external returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    // ==================================== ACCOUNTING OPERATIONS ====================================

    function activeAssets() external view returns (uint256);

    function inactiveAssets() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    // ======================================= STATE INFORMATION =====================================

    function getUserBalances(address user)
        external
        view
        returns (
            uint256 userActiveShares,
            uint256 userInactiveShares,
            uint256 userActiveAssets,
            uint256 userInactiveAssets
        );

    function getUserDeposits(address user) external view returns (UserDeposit[] memory);

    // ============================ DEPOSIT/WITHDRAWAL LIMIT OPERATIONS ============================

    function maxDeposit(address owner) external view returns (uint256);

    function maxMint(address owner) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    // ======================================= FEE OPERATIONS =======================================

    function accrueFees() external;

    function transferFees() external;

    // ======================================= ADMIN OPERATIONS =======================================

    function enterPosition() external;

    function rebalance(
        address[9] memory route,
        uint256[3][4] memory swapParams,
        uint256 minAmountOut
    ) external;

    function reinvest(uint256 minAmountOut) external;

    function claimAndUnstake() external returns (uint256 claimed);

    function sweep(address token, address to) external;

    function setLiquidityLimit(uint256 limit) external;

    function setDepositLimit(uint256 limit) external;

    function setShutdown(bool shutdown, bool exitPosition) external;

    // ================================== SHARE TRANSFER OPERATIONS ==================================

    function transferFrom(
        address from,
        address to,
        uint256 amount,
        bool onlyActive
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