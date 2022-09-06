/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./common/BaseActionUpgradeable.sol";
import { PotionProtocolHelperUpgradeable } from "./common/PotionProtocolHelperUpgradeable.sol";
import { UniswapV3HelperUpgradeable } from "./common/UniswapV3HelperUpgradeable.sol";
import "../versioning/PotionBuyActionV0.sol";
import "../library/PercentageUtils.sol";
import "../library/OpynProtocolLib.sol";
import "../library/TimeUtils.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
    @title PotionBuyAction

    @author Roberto Cano <robercano>

    @notice Investment action that implements a protective put on the assets received. For this, it uses the Potion
    Protocol to buy the Put Options required to protect the assets. It protects the 100% of the received assets with
    the limitation that the paid premium cannot be greater than a configured maximum premium percentage value.

    @dev The Potion Buy action uses Uniswap V3 to swap between the investment asset and USDC, which is required in order
    to pay for the Potion Protocol premium. Because of this, the action defines a swap slippage value that is used to limit
    the amount of slippage that is allowed on the swap operation.

    @dev The action also allows to configure a slippage value for the premium when the potions are bought. This value is
    different from the maximum premium percentage. The former is used to account for slippage when the potions are bought,
    while the latter is used to limit how much percentage of the received investment can be used as premium. This last
    parameter can be used to shape the investing performance of the action


 */
contract PotionBuyAction is
    BaseActionUpgradeable,
    UniswapV3HelperUpgradeable,
    PotionProtocolHelperUpgradeable,
    PotionBuyActionV0
{
    using PercentageUtils for uint256;
    using SafeERC20 for IERC20;
    using OpynProtocolLib for IOpynController;

    /**
        @notice Structure with all initialization parameters for the Potion Buy action

        @param adminAddress The address of the admin of the Action
        @param strategistAddress The address of the strategist of the Action
        @param operatorAddress The address of the operator of the Action
        @param investmentAsset The address of the asset managed by this Action
        @param USDC The address of the USDC token
        @param uniswapV3SwapRouter The address of the Uniswap V3 swap router
        @param potionLiquidityPoolManager The address of the Potion Protocol liquidity manager contract
        @param opynAddressBook The address of the Opyn Address Book where other contract addresses can be found
        @param maxPremiumPercentage The maximum percentage of the received investment that can be used as premium
        @param premiumSlippage The slippage percentage allowed on the premium when buying potions
        @param swapSlippage The slippage percentage allowed on the swap operation
        @param maxSwapDurationSecs The maximum duration of the swap operation in seconds
        @param cycleDurationSecs The duration of the investment cycle in seconds
        @param strikePercentage The strike percentage on the price of the hedged asset, as a uint256
               with `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */
    struct PotionBuyInitParams {
        address adminAddress;
        address strategistAddress;
        address operatorAddress;
        address investmentAsset;
        address USDC;
        address uniswapV3SwapRouter;
        address potionLiquidityPoolManager;
        address opynAddressBook;
        uint256 maxPremiumPercentage;
        uint256 premiumSlippage;
        uint256 swapSlippage;
        uint256 maxSwapDurationSecs;
        uint256 cycleDurationSecs;
        uint256 strikePercentage;
    }

    /// INITIALIZERS

    /**
        @notice Takes care of the initialization of all the contracts hierarchy. Any changes
        to the hierarchy will require to review this function to make sure that no initializer
        is called twice, and most importantly, that all initializers are called here

        @param initParams Initialization parameters for the Potion Buy action

        @dev See { PotionBuyInitParams }

     */
    function initialize(PotionBuyInitParams calldata initParams) external initializer {
        // Prepare the list of tokens that are not allowed to be refunded. In particular the loaned
        // asset is not allowed to be refunded and also USDC because the action will hold some of it
        // at some times. This prevents the admin to accidentally refund those assets
        address[] memory cannotRefundTokens = new address[](2);
        cannotRefundTokens[0] = initParams.investmentAsset;
        cannotRefundTokens[1] = initParams.USDC;

        __BaseAction_init_chained(
            initParams.adminAddress,
            initParams.strategistAddress,
            initParams.operatorAddress,
            cannotRefundTokens
        );
        __UniswapV3Helper_init_unchained(initParams.uniswapV3SwapRouter);
        __PotionProtocolHelper_init_unchained(
            initParams.potionLiquidityPoolManager,
            initParams.opynAddressBook,
            initParams.USDC
        );

        _setMaxPremiumPercentage(initParams.maxPremiumPercentage);
        _setPremiumSlippage(initParams.premiumSlippage);
        _setSwapSlippage(initParams.swapSlippage);
        _setMaxSwapDuration(initParams.maxSwapDurationSecs);
        _setCycleDuration(initParams.cycleDurationSecs);
        _setStrikePercentage(initParams.strikePercentage);

        // Get the next time
        uint256 todayAt8UTC = TimeUtils.calculateTodayWithOffset(block.timestamp, TimeUtils.SECONDS_TO_0800_UTC);
        nextCycleStartTimestamp = todayAt8UTC > block.timestamp
            ? todayAt8UTC
            : todayAt8UTC + initParams.cycleDurationSecs;
    }

    /// STATE CHANGERS

    /**
        @inheritdoc IAction

        @dev The Potion Buy action takes the following steps to enter a position:
            - Transfer the investment amount to the Action contract
            - Calculate the premium needed for buying the potions, including slippage
            - Check if the premium needed is higher than the allowed maximum premium percentage. The
              premium to be paid cannot be greater than this percentage on the investment amount
            - Swap part of the investment asset to get the calculated needed premium in USDC
            - Buy the potions using the calculated premium and the new USDC balance in the Action
              contract

     */
    function enterPosition(address investmentAsset, uint256 amountToInvest)
        external
        onlyVault
        onlyUnlocked
        onlyAfterCycleStart
        nonReentrant
    {
        _updateNextCycleStart();
        _setLifecycleState(LifecycleState.Locked);

        // TODO: We could calculate the amount of USDC that will be needed to buy the potion and just
        // TODO: transfer enough asset needed to swap for that. However it is simpler to transfer everything for now

        // The caller is the operator, so we can trust doing this external call first
        IERC20(investmentAsset).safeTransferFrom(_msgSender(), address(this), amountToInvest);

        bool isValid;
        uint256 maxPremiumNeededInUSDC;

        (isValid, maxPremiumNeededInUSDC, lastStrikePriceInUSDC) = _calculatePotionParameters(
            investmentAsset,
            strikePercentage,
            nextCycleStartTimestamp,
            amountToInvest,
            premiumSlippage
        );
        require(isValid, "Cannot calculate the required premium");

        uint256 maxPremiumAllowedInAsset = amountToInvest.applyPercentage(maxPremiumPercentage);
        uint256 maxPremiumAllowedInUSDC = _calculateAssetValueInUSDC(investmentAsset, maxPremiumAllowedInAsset);

        require(maxPremiumNeededInUSDC <= maxPremiumAllowedInUSDC, "The premium needed is too high");

        _swapOutput(investmentAsset, address(getUSDC()), maxPremiumNeededInUSDC, swapSlippage, maxSwapDurationSecs);
        _buyPotions(investmentAsset, lastStrikePriceInUSDC, nextCycleStartTimestamp, amountToInvest, premiumSlippage);

        emit ActionPositionEntered(investmentAsset, amountToInvest);
    }

    /**
        @inheritdoc IAction
     */
    function exitPosition(address investmentAsset)
        external
        onlyVault
        onlyLocked
        onlyAfterCycleEnd
        nonReentrant
        returns (uint256 amountReturned)
    {
        require(
            _isPotionRedeemable(investmentAsset, lastStrikePriceInUSDC, nextCycleStartTimestamp),
            "The Potion is not redeemable yet"
        );

        IERC20 investmentAssetERC20 = IERC20(investmentAsset);
        IERC20 USDC = getUSDC();

        _redeemPotions(investmentAsset, lastStrikePriceInUSDC, nextCycleStartTimestamp);
        uint256 amountToConvertToAssset = USDC.balanceOf(address(this));

        _swapInput(address(USDC), investmentAsset, amountToConvertToAssset, swapSlippage, maxSwapDurationSecs);

        amountReturned = investmentAssetERC20.balanceOf(address(this));

        SafeERC20.safeTransfer(investmentAssetERC20, _msgSender(), amountReturned);

        _setLifecycleState(LifecycleState.Unlocked);

        emit ActionPositionExited(investmentAsset, amountReturned);
    }

    /**
        @inheritdoc IPotionBuyActionV0
     */
    function setMaxPremiumPercentage(uint256 maxPremiumPercentage_) external override onlyStrategist {
        _setMaxPremiumPercentage(maxPremiumPercentage_);
    }

    /**
        @inheritdoc IPotionBuyActionV0
     */
    function setPremiumSlippage(uint256 premiumSlippage_) external override onlyStrategist {
        _setPremiumSlippage(premiumSlippage_);
    }

    /**
        @inheritdoc IPotionBuyActionV0
     */
    function setSwapSlippage(uint256 swapSlippage_) external override onlyStrategist {
        _setSwapSlippage(swapSlippage_);
    }

    /**
        @inheritdoc IPotionBuyActionV0
     */
    function setMaxSwapDuration(uint256 durationSeconds) external override onlyStrategist {
        _setMaxSwapDuration(durationSeconds);
    }

    /**
        @inheritdoc IPotionBuyActionV0
     */
    function setCycleDuration(uint256 durationSeconds) external override onlyStrategist {
        _setCycleDuration(durationSeconds);
    }

    /**
        @inheritdoc IPotionBuyActionV0
     */
    function setStrikePercentage(uint256 strikePercentage_) external override onlyStrategist {
        _setStrikePercentage(strikePercentage_);
    }

    // GETTERS

    /**
        @inheritdoc IAction
     */
    function canPositionBeEntered(
        address /*investmentAsset*/
    ) public view returns (bool canEnter) {
        canEnter = _isNextCycleStarted() && getLifecycleState() == LifecycleState.Unlocked;
    }

    /**
        @inheritdoc IAction
     */
    function canPositionBeExited(address investmentAsset) public view returns (bool canExit) {
        canExit =
            _isNextCycleStarted() &&
            _isPotionRedeemable(investmentAsset, lastStrikePriceInUSDC, nextCycleStartTimestamp) &&
            getLifecycleState() == LifecycleState.Locked;
    }

    /**
        @inheritdoc IPotionBuyActionV0
    */
    function calculateCurrentPayout(address investmentAsset) external view returns (bool isFinal, uint256 payout) {
        return _calculateCurrentPayout(investmentAsset, lastStrikePriceInUSDC, nextCycleStartTimestamp);
    }

    /// INTERNAL FUNCTIONS

    /**
        @dev See { setMaxPremiumPercentage }
     */
    function _setMaxPremiumPercentage(uint256 maxPremiumPercentage_) internal {
        if (maxPremiumPercentage_ <= 0 || maxPremiumPercentage_ > PercentageUtils.PERCENTAGE_100) {
            revert MaxPremiumPercentageOutOfRange(maxPremiumPercentage_);
        }

        maxPremiumPercentage = maxPremiumPercentage_;

        emit MaxPremiumPercentageChanged(maxPremiumPercentage_);
    }

    /**
        @dev See { setPremiumSlippage }
    */
    function _setPremiumSlippage(uint256 premiumSlippage_) internal {
        if (premiumSlippage_ <= 0 || premiumSlippage_ > PercentageUtils.PERCENTAGE_100) {
            revert PremiumSlippageOutOfRange(premiumSlippage_);
        }

        premiumSlippage = premiumSlippage_;

        emit PremiumSlippageChanged(premiumSlippage_);
    }

    /**
        @dev See { setSwapSlippage }
     */
    function _setSwapSlippage(uint256 swapSlippage_) internal {
        if (swapSlippage_ <= 0 || swapSlippage_ >= PercentageUtils.PERCENTAGE_100) {
            revert SwapSlippageOutOfRange(swapSlippage_);
        }

        swapSlippage = swapSlippage_;

        emit SwapSlippageChanged(swapSlippage_);
    }

    /**
        @dev See { setMaxSwapDuration }
     */
    function _setMaxSwapDuration(uint256 durationSeconds) internal {
        maxSwapDurationSecs = durationSeconds;

        emit MaxSwapDurationChanged(durationSeconds);
    }

    /**
        @dev See { setCycleDuration }
     */
    function _setCycleDuration(uint256 durationSeconds) internal {
        if (durationSeconds < MIN_CYCLE_DURATION) {
            revert CycleDurationTooShort(durationSeconds, MIN_CYCLE_DURATION);
        }

        cycleDurationSecs = durationSeconds;

        emit CycleDurationChanged(durationSeconds);
    }

    /**
        @dev See { setStrikePercentage }
     */
    function _setStrikePercentage(uint256 strikePercentage_) internal {
        if (strikePercentage_ == 0) {
            revert StrikePercentageIsZero();
        }

        strikePercentage = strikePercentage_;

        emit StrikePercentageChanged(strikePercentage_);
    }

    /**
        @notice Checks if the next cycle has already started or not

        @return True if the next cycle has already started, false otherwise
     */

    function _isNextCycleStarted() internal view returns (bool) {
        return block.timestamp >= nextCycleStartTimestamp;
    }

    /**
        @notice Updates the start of the next investment cycle

        @dev It has a bit of a complex logic to account for skipped cycles. If one or more
        cycles have been skipped, then we need to bring the next cycle start close to the current
        timestamp. To do so we calculate the current cycle offset from the cycle start that is closest
        to now, but in the past. Then we substract this offset from now to get the start of the current
        cycle. We then calculate the next cycle start from the previous by adding the cycle duration
     */
    function _updateNextCycleStart() internal {
        uint256 currentCycleOffset = (block.timestamp - nextCycleStartTimestamp) % cycleDurationSecs;
        uint256 lastCycleExpectedStart = block.timestamp - currentCycleOffset;

        nextCycleStartTimestamp = lastCycleExpectedStart + cycleDurationSecs;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../../interfaces/IAction.sol";
import "../../common/EmergencyLockUpgradeable.sol";
import "../../common/LifecycleStatesUpgradeable.sol";
import "../../common/RefundsHelperUpgreadable.sol";
import "../../common/RolesManagerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
    @title BaseVaultUpgradeable

    @author Roberto Cano <robercano>
    
    @notice Base contract for the Vault contract. It serves as a commonplace to take care of
    the inheritance order and the storage order of the contracts, as this is very important
    to keep consistent in order to be able to upgrade the contracts. The order of the contracts
    is also important to not break the C3 lineralization of the inheritance hierarchy.

    @dev Some of the contracts in the base hierarchy contain storage gaps to account for upgrades
    needed in those contracts. Those gaps allow to add new storage variables without shifting
    variables down the inheritance chain down. The gap is not used here and instead the versioned
    interfaces approach is chosen because it is more explicit.

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract
 */

abstract contract BaseActionUpgradeable is
    IAction,
    RolesManagerUpgradeable, // Making explicit inheritance here, although it is not necessary
    EmergencyLockUpgradeable,
    LifecycleStatesUpgradeable,
    RefundsHelperUpgreadable,
    ReentrancyGuardUpgradeable
{
    // UPGRADEABLE INITIALIZER

    /**
        @notice Takes care of the initialization of all the contracts hierarchy. Any changes
        to the hierarchy will require to review this function to make sure that no initializer
        is called twice, and most importantly, that all initializers are called here
     */
    // solhint-disable-next-line func-name-mixedcase
    function __BaseAction_init_chained(
        address adminAddress,
        address strategistAddress,
        address operatorAddress,
        address[] memory cannotRefundTokens
    ) internal onlyInitializing {
        __RolesManager_init_unchained(adminAddress, strategistAddress, operatorAddress);
        __EmergencyLock_init_unchained();
        __LifecycleStates_init_unchained();
        __RefundsHelper_init_unchained(cannotRefundTokens, false);
        __ReentrancyGuard_init_unchained();
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { PotionProtocolOracleUpgradeable } from "./PotionProtocolOracleUpgradeable.sol";
import "../../library/PotionProtocolLib.sol";
import "../../library/PercentageUtils.sol";
import "../../library/OpynProtocolLib.sol";
import "../../library/PriceUtils.sol";
import { IPotionLiquidityPool } from "../../interfaces/IPotionLiquidityPool.sol";
import { IOpynAddressBook } from "../../interfaces/IOpynAddressBook.sol";
import { IOpynController } from "../../interfaces/IOpynController.sol";
import { IOpynFactory } from "../../interfaces/IOpynFactory.sol";
import { IOpynOracle } from "../../interfaces/IOpynOracle.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/**
    @title PotionProtocolHelperUpgradeable

    @notice Helper contract that handles the configuration to perform Uniswap V3 multi-hop swaps. It
    uses the `UniswapV3SwapLib` to perform the swaps.

    @dev It inherits from the RolesManagerUpgradeable contract to scope the the parameters setting
    functions for only the Keeper role.

    @dev It does not initialize the RolesManagerUpgradeable as that is a contract that is shared
    among several other contracts of the Action. The initialization will happen in the Action contract
 */
contract PotionProtocolHelperUpgradeable is PotionProtocolOracleUpgradeable {
    using PotionProtocolLib for IPotionLiquidityPool;
    using OpynProtocolLib for IOpynController;
    using PercentageUtils for uint256;

    /**
        @notice The address of the Potion Protocol liquidity pool manager
     */
    IPotionLiquidityPool private _potionLiquidityPoolManager;

    /**
        @notice The address of the Opyn address book

        @dev This is used to get the addresses of the other Opyn contracts
     */
    IOpynAddressBook private _opynAddressBook;

    /**
        @notice Maps the address of an asset with the address of the potion that will be used to hedge it

        @dev token address => potion address
     */
    mapping(address => address) private _assetToPotion;

    /**
        @notice Address of the USDC contract. Used to calculate the settled amounts for
        redeeming potions

        @dev Unfortunately the Potion Protocol does not return the settled amount when 
        calling redeemPotions, so it is needed to get the USDC balance before and after the call
        to be able to calculate the settled amount
     */
    IERC20 private _USDC;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice It does chain the initialization to the parent contract because both contracts
        are quite coupled and `UniswapV3OracleUpgradeable` MUST not be used anywhere else in
        the inheritance chain.

        @param potionLiquidityPoolManager The address of the Potion Protocol liquidity pool manager
        @param opynAddressBook The address of the Opyn Address Book where other contract addresses can be found
        @param USDC The address of the USDC contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __PotionProtocolHelper_init_unchained(
        address potionLiquidityPoolManager,
        address opynAddressBook,
        address USDC
    ) internal onlyInitializing {
        __PotionProtocolOracle_init_unchained();

        _potionLiquidityPoolManager = IPotionLiquidityPool(potionLiquidityPoolManager);

        _opynAddressBook = IOpynAddressBook(opynAddressBook);

        _USDC = IERC20(USDC);
    }

    /// INTERNALS

    /**
        @notice Calculates the premium required to buy potions and the strike price denominated in USDC
        for the indicated amount of assets, the intended strike percentage and the intended slippage

        @param hedgedAsset The address of the asset to be hedged, used to get the associated potion information
        @param strikePercentage The strike percentage of the asset price as a uint256 with 
               `PercentageUtils.PERCENTAGE_DECIMALS` decimals
        @param expirationTimestamp The timestamp when the potion expires
        @param amount The amount of assets to be hedged
        @param slippage The slippage percentage to be used to calculate the premium

        @return isValid Whether the maximum premium could be calculated or not
        @return maxPremiumInUSDC The maximum premium needed to buy the potions
     */
    function _calculatePotionParameters(
        address hedgedAsset,
        uint256 strikePercentage,
        uint256 expirationTimestamp,
        uint256 amount,
        uint256 slippage
    )
        internal
        view
        returns (
            bool isValid,
            uint256 maxPremiumInUSDC,
            uint256 strikePriceInUSDC
        )
    {
        strikePriceInUSDC = _calculateStrikePrice(hedgedAsset, strikePercentage);

        PotionBuyInfo memory buyInfo = getPotionBuyInfo(hedgedAsset, strikePriceInUSDC, expirationTimestamp);
        uint256 potionsAmount = PotionProtocolLib.getPotionsAmount(hedgedAsset, amount);

        if (buyInfo.targetPotionAddress == address(0) || potionsAmount != buyInfo.totalSizeInPotions) {
            return (false, type(uint256).max, type(uint256).max);
        }

        isValid = true;
        maxPremiumInUSDC = buyInfo.expectedPremiumInUSDC.addPercentage(slippage);
    }

    /**
        @notice Buys potions from the Potion Protocol to insure the specific amount of assets

        @param hedgedAsset The address of the asset to be hedged, used to get the associated potion information
        @param strikePriceInUSDC The strike price of the potion with 8 decimals
        @param expirationTimestamp The timestamp when the potion expires
        @param amount The amount of assets to be hedged
        @param slippage The slippage percentage to be used to calculate the premium

        @return actualPremium The actual premium used to buy the potions
        @return amountPotions The amount of potions bought

     */
    function _buyPotions(
        address hedgedAsset,
        uint256 strikePriceInUSDC,
        uint256 expirationTimestamp,
        uint256 amount,
        uint256 slippage
    ) internal returns (uint256 actualPremium, uint256 amountPotions) {
        PotionBuyInfo memory buyInfo = getPotionBuyInfo(hedgedAsset, strikePriceInUSDC, expirationTimestamp);
        uint256 potionsAmount = PotionProtocolLib.getPotionsAmount(hedgedAsset, amount);

        require(buyInfo.targetPotionAddress != address(0), "Potion buy info not found for the given asset");
        require(potionsAmount == buyInfo.totalSizeInPotions, "Insured amount greater than expected amount");

        actualPremium = _potionLiquidityPoolManager.buyPotion(
            IOpynFactory(_opynAddressBook.getOtokenFactory()),
            buyInfo,
            slippage,
            getUSDC()
        );

        amountPotions = buyInfo.totalSizeInPotions;
    }

    /**
        @notice Redeems the potions bought once the expiration timestamp is reached

        @param hedgedAsset The address of the asset to be hedged, used to get the associated potion information
        @param strikePriceInUSDC The strike price of the potion with 8 decimals
        @param expirationTimestamp The timestamp when the potion expires

        @return settledAmount The amount of USDC settled after the redemption
     */
    function _redeemPotions(
        address hedgedAsset,
        uint256 strikePriceInUSDC,
        uint256 expirationTimestamp
    ) internal returns (uint256 settledAmount) {
        PotionBuyInfo memory buyInfo = getPotionBuyInfo(hedgedAsset, strikePriceInUSDC, expirationTimestamp);
        IOpynController opynController = IOpynController(_opynAddressBook.getController());

        bool isPayoutFinal;
        (isPayoutFinal, settledAmount) = _calculateCurrentPayout(hedgedAsset, strikePriceInUSDC, expirationTimestamp);

        require(isPayoutFinal, "Potion cannot be redeemed yet");

        _potionLiquidityPoolManager.settlePotion(buyInfo);

        if (settledAmount > 0) {
            _potionLiquidityPoolManager.redeemPotion(opynController, buyInfo);
        }
    }

    /**
        @notice Checks if the potion for the given asset can be redeemed already

        @param hedgedAsset The address of the hedged asset related to the potion to be redeemed

        @return Whether the potion can be redeemed or not
     */
    function _isPotionRedeemable(
        address hedgedAsset,
        uint256 strikePriceInUSDC,
        uint256 expirationTimestamp
    ) internal view returns (bool) {
        PotionBuyInfo memory buyInfo = getPotionBuyInfo(hedgedAsset, strikePriceInUSDC, expirationTimestamp);
        IOpynController opynController = IOpynController(_opynAddressBook.getController());
        return opynController.isPotionRedeemable(buyInfo.targetPotionAddress);
    }

    /// GETTERS

    /**
        @notice Calculates the strike price of the potion given the hedged asset and the strike percentage

        @param hedgedAsset The address of the asset to be hedged, used to get the price from the Opyn Oracle
        @param strikePercentage The strike percentage of the asset price as a uint256 with 
               `PercentageUtils.PERCENTAGE_DECIMALS` decimals

        @return The strike price of the potion in USDC with 8 decimals

        @dev This function calls the Opyn Oracle to get the price of the asset, so its value might
             change if called in different blocks.
     */
    function _calculateStrikePrice(address hedgedAsset, uint256 strikePercentage) internal view returns (uint256) {
        IOpynOracle opynOracle = IOpynOracle(_opynAddressBook.getOracle());

        uint256 priceInUSDC = opynOracle.getPrice(hedgedAsset);

        return priceInUSDC.applyPercentage(strikePercentage);
    }

    /**
        @notice Returns the calculated payout for the current block, and whether that payout is final or not

        @param hedgedAsset The address of the asset to be hedged, used to get the associated potion information
        @param strikePriceInUSDC The strike price of the potion with 8 decimals
        @param expirationTimestamp The timestamp when the potion expires

        @return isFinal Whether the payout is final or not. If the payout is final it won't change anymore. If it
                is not final it means that the potion has not expired yet and the payout may change in the future.
    */
    function _calculateCurrentPayout(
        address hedgedAsset,
        uint256 strikePriceInUSDC,
        uint256 expirationTimestamp
    ) internal view returns (bool isFinal, uint256 payout) {
        PotionBuyInfo memory buyInfo = getPotionBuyInfo(hedgedAsset, strikePriceInUSDC, expirationTimestamp);
        IOpynController opynController = IOpynController(_opynAddressBook.getController());

        isFinal = _isPotionRedeemable(hedgedAsset, strikePriceInUSDC, expirationTimestamp);
        payout = PotionProtocolLib.getPayout(opynController, buyInfo.targetPotionAddress, buyInfo.totalSizeInPotions);
    }

    /// GETTERS

    /**
        @notice Retrieves the given asset price in USDC from the Opyn Oracle

        @param hedgedAsset The address of the asset to be hedged, used to get the price from the Opyn Oracle
        @param amount The amount of asset to be converted to USDC

        @return The amount of USDC equivalent to the given amount of assets, with 8 decimals

        @dev This function calls the Opyn Oracle to get the price of the asset, so its value might
             change if called in different blocks.
     */
    function _calculateAssetValueInUSDC(address hedgedAsset, uint256 amount) internal view returns (uint256) {
        IOpynOracle opynOracle = IOpynOracle(_opynAddressBook.getOracle());

        uint256 assetPriceInUSD = opynOracle.getPrice(address(hedgedAsset));
        uint256 USDCPriceInUSD = opynOracle.getPrice(address(_USDC));

        uint256 hedgedAssetDecimals = IERC20Metadata(hedgedAsset).decimals();
        uint256 USDCDecimals = IERC20Metadata(address(_USDC)).decimals();

        return PriceUtils.convertAmount(hedgedAssetDecimals, USDCDecimals, amount, assetPriceInUSD, USDCPriceInUSD);
    }

    /**
        @notice Returns the USDC address configured in the contract

        @return The address of the USDC contract
     */
    function getUSDC() public view returns (IERC20) {
        return _USDC;
    }

    /**
        @notice Returns the Potion Protocol liquidity manager address

        @return The address of the Potion Protocol liquidity manager
    */
    function getPotionLiquidityManager() external view returns (IPotionLiquidityPool) {
        return _potionLiquidityPoolManager;
    }

    /**
        @notice Returns the Opyn Address Book address

        @return The address of the Opyn Address Book
     */
    function getOpynAddressBook() external view returns (IOpynAddressBook) {
        return _opynAddressBook;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./UniswapV3OracleUpgradeable.sol";
import "../../library/UniswapV3SwapLib.sol";
import "../../library/PriceUtils.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/**
    @title UniswapV3HelperUpgradeable

    @notice Helper contract that handles the configuration to perform Uniswap V3 multi-hop swaps. It
    uses the `UniswapV3SwapLib` to perform the swaps.

    @dev It inherits from the RolesManagerUpgradeable contract to scope the the parameters setting
    functions for only the Keeper role.

    @dev It does not initialize the RolesManagerUpgradeable as that is a contract that is shared
    among several other contracts of the Action. The initialization will happen in the Action contract

 */
contract UniswapV3HelperUpgradeable is UniswapV3OracleUpgradeable {
    using UniswapV3SwapLib for ISwapRouter;

    /**
        @notice The address of the Uniswap V3 Router contract
     */
    ISwapRouter private _swapRouter;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice It does chain the initialization to the parent contract because both contracts
        are quite coupled and `UniswapV3OracleUpgradeable` MUST not be used anywhere else in
        the inheritance chain.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __UniswapV3Helper_init_unchained(address swapRouter) internal onlyInitializing {
        __UniswapV3Oracle_init_unchained();

        _swapRouter = ISwapRouter(swapRouter);
    }

    /// FUNCTIONS

    /**
        @notice Swaps the exact given amount of input asset for some amount of output asset

        @param inputToken The address of the input token to be swapped
        @param outputToken The address of the output token to be received
        @param amountIn The exact amount of input token to be swapped
        @param slippage How much slippage is allowed on the output amount to be received, as a
        percentage with `UniswapV3SwapLib.SLIPPAGE_DECIMALS` decimals
        @param maxDuration The maximum duration of the swap, in seconds, used to calculate
        the deadline from `now`

        @dev It uses the information provided by the `UniswapV3OracleUpgradeable` contract to
        determine the path to use for the swap and the expected price for the swap.

        @dev This contract assumes that the input token is already owned by the contract itself
     */
    function _swapInput(
        address inputToken,
        address outputToken,
        uint256 amountIn,
        uint256 slippage,
        uint256 maxDuration
    ) internal returns (uint256 actualAmountOut) {
        SwapInfo memory swapInfo = getSwapInfo(inputToken, outputToken);

        require(
            swapInfo.inputToken == inputToken && swapInfo.outputToken == outputToken,
            "Swap info not found for the given token pair"
        );

        // TODO: price rate has to be passed as the price of the input token and the price of the output token
        // TODO: so the rate can be calculated inside PriceUtis
        uint256 expectedAmountOut = PriceUtils.toOutputAmount(swapInfo.expectedPriceRate, amountIn);

        UniswapV3SwapLib.SwapInputParameters memory swapParameters = UniswapV3SwapLib.SwapInputParameters({
            inputToken: inputToken,
            exactAmountIn: amountIn,
            expectedAmountOut: expectedAmountOut,
            slippage: slippage,
            maxDuration: maxDuration,
            swapPath: swapInfo.swapPath
        });

        actualAmountOut = _swapRouter.swapInput(swapParameters);
    }

    /**
        @notice Swaps some amount of input asset to obtain an exact amount of output asset

        @param inputToken The address of the input token to be swapped
        @param outputToken The address of the output token to be received
        @param amountOut The exact amount of output token to be received
        @param slippage How much slippage is allowed on the input amount to be swapped, as a
        percentage with `UniswapV3SwapLib.SLIPPAGE_DECIMALS` decimals
        @param maxDuration The maximum duration of the swap, in seconds, used to calculate
        the deadline from `now`

        @dev It uses the information provided by the `UniswapV3OracleUpgradeable` contract to
        determine the path to use for the swap and the expected price for the swap.

        @dev This contract assumes that the input token is already owned by the contract itself
        */
    function _swapOutput(
        address inputToken,
        address outputToken,
        uint256 amountOut,
        uint256 slippage,
        uint256 maxDuration
    ) internal returns (uint256 actualAmountIn) {
        SwapInfo memory swapInfo = getSwapInfo(inputToken, outputToken);

        require(
            swapInfo.inputToken == inputToken && swapInfo.outputToken == outputToken,
            "Swap info not found for the given token pair"
        );

        uint256 expectedAmountIn = PriceUtils.toInputAmount(swapInfo.expectedPriceRate, amountOut);

        UniswapV3SwapLib.SwapOutputParameters memory swapParameters = UniswapV3SwapLib.SwapOutputParameters({
            inputToken: inputToken,
            exactAmountOut: amountOut,
            expectedAmountIn: expectedAmountIn,
            slippage: slippage,
            maxDuration: maxDuration,
            swapPath: swapInfo.swapPath
        });

        actualAmountIn = _swapRouter.swapOutput(swapParameters);
    }

    /**
        @notice Returns the current swap router address
     */
    function getSwapRouter() public view returns (ISwapRouter) {
        return _swapRouter;
    }

    /**
        @notice Returns the output amount that can be received from the given input amount,
        when swapping from the input token to the output token

        @param inputToken The address of the input token to be swapped
        @param outputToken The address of the output token to be received
        @param amountIn The exact amount of input token to be swapped
     */
    function getSwapOutputAmount(
        address inputToken,
        address outputToken,
        uint256 amountIn
    ) public view returns (uint256) {
        SwapInfo memory swapInfo = getSwapInfo(inputToken, outputToken);
        return PriceUtils.toOutputAmount(swapInfo.expectedPriceRate, amountIn);
    }

    /**
        @notice Returns the input amount needed to receive the exact given output amount,
        when swapping from the input token to the output token

        @param inputToken The address of the input token to be swapped
        @param outputToken The address of the output token to be received
        @param amountOut The exact amount of output token to be received
     */
    function getSwapInputAmount(
        address inputToken,
        address outputToken,
        uint256 amountOut
    ) public view returns (uint256) {
        SwapInfo memory swapInfo = getSwapInfo(inputToken, outputToken);
        return PriceUtils.toInputAmount(swapInfo.expectedPriceRate, amountOut);
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionBuyActionV0 } from "../interfaces/IPotionBuyActionV0.sol";

/**    
    @title PotionBuyActionV0
        
    @author Roberto Cano <robercano>

    @notice Storage and interface for the V0 of the Vault
 */
abstract contract PotionBuyActionV0 is IPotionBuyActionV0 {
    // STORAGE

    /**
        @notice The minimum duration of a cycle in seconds
     */
    uint256 public constant MIN_CYCLE_DURATION = 1 days;

    /**
        @notice The maximum percentage of the received loan that can be used as premium to buy potions

        @dev The percentage is stored in the form of a uint256 with `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */
    uint256 public maxPremiumPercentage;

    /**
        @notice The percentage of slippage that is allowed on the premium
        when the potions are bought

        @dev The percentage is stored in the form of a uint256 with `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */

    uint256 public premiumSlippage;

    /**
        @notice The percentage of slippage that is allowed on Uniswap when it the asset is swapped for USDC and back

        @dev The percentage is stored in the form of a uint256 with `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */

    uint256 public swapSlippage;

    /**
        @notice The maximum duration of a Uniswap swap operation, in seconds
     */
    uint256 public maxSwapDurationSecs;

    /**
        @notice Timestamp when the next investment cycle can start. The action cannot enter the position
        before this timestamp
     */
    uint256 public nextCycleStartTimestamp;

    /**
        @notice Duration of the investment cycle in seconds
     */
    uint256 public cycleDurationSecs;

    /**
        @notice Strike percentage for the hedged asset, as a uint256 with 
                `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */
    uint256 public strikePercentage;

    /**
        @notice The strike price calculated for the last cycle when entering
                the position. Kept in the storage for quick reference

        @dev The price with 8 decimals denominated in USDC
        @dev This the same as the strike price that Opyn uses in the Gamma protocol
             and it must follow the same format
     */
    uint256 public lastStrikePriceInUSDC;

    /// MODIFIERS

    /**
        @notice Checks if the current cycle start time has been reached
     */
    modifier onlyAfterCycleStart() {
        require(block.timestamp >= nextCycleStartTimestamp, "Next cycle has not started yet");
        _;
    }

    /**
        @notice Checks if the current cycle end time has been reached

        @dev The end of the current cycle is exactly the same as the start of the next
     */
    modifier onlyAfterCycleEnd() {
        require(block.timestamp >= nextCycleStartTimestamp, "Current cycle has not ended yet");
        _;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title PercentageUtils

    @author Roberto Cano <robercano>
    
    @notice Utility library to apply a slippage percentage to an input amount
 */
library PercentageUtils {
    /**
        @notice The number of decimals used for the slippage percentage
     */
    uint256 public constant PERCENTAGE_DECIMALS = 6;

    /**
        @notice The factor used to scale the slippage percentage when calculating the slippage
        on an amount
     */
    uint256 public constant PERCENTAGE_FACTOR = 10**PERCENTAGE_DECIMALS;

    /**
        @notice Percentage of 100% with the given `PERCENTAGE_DECIMALS`
     */
    uint256 public constant PERCENTAGE_100 = 100 * PERCENTAGE_FACTOR;

    /**
        @notice Adds the percentage to the given amount and returns the result
        
        @return The amount after the percentage is applied

        @dev It performs the following operation:
            (100.0 + percentage) * amount
     */
    function addPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return applyPercentage(amount, PERCENTAGE_100 + percentage);
    }

    /**
        @notice Substracts the percentage from the given amount and returns the result
        
        @return The amount after the percentage is applied

        @dev It performs the following operation:
            (100.0 - percentage) * amount
     */
    function substractPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        return applyPercentage(amount, PERCENTAGE_100 - percentage);
    }

    /**
        @notice Applies the given percentage to the given amount and returns the result

        @param amount The amount to apply the percentage to
        @param percentage The percentage to apply to the amount

        @return The amount after the percentage is applied
     */
    function applyPercentage(uint256 amount, uint256 percentage) internal pure returns (uint256) {
        // TODO: used Math.mulDiv when it is released
        return (amount * percentage) / PERCENTAGE_100;
    }

    /**
        @notice Checks if the given percentage is in range, this is, if it is between 0 and 100

        @param percentage The percentage to check

        @return True if the percentage is in range, false otherwise
     */
    function isPercentageInRange(uint256 percentage) internal pure returns (bool) {
        return percentage <= PERCENTAGE_100;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IOpynController } from "../interfaces/IOpynController.sol";
import { IOpynFactory } from "../interfaces/IOpynFactory.sol";

/**
    @title OpynProtocolLib

    @author Roberto Cano <robercano>

    @notice Helper library to query the Opyn protocol
 */
library OpynProtocolLib {
    /// FUNCTIONS

    /**
        @notice Returns whether the given potion can be redeemed already or not

        @dev Unfortunately the Potion Protocol does not have a function to check if a potion can be redeemed
        or not, and it relies on the Opyn Controller for doing this. Wrapping this up in a library to make it
        more accesible
     */
    function isPotionRedeemable(IOpynController opynController, address potion) internal view returns (bool) {
        return opynController.isSettlementAllowed(potion);
    }

    /**
        @notice get the address at which a new oToken with these parameters would be deployed
        
        @param underlyingAsset asset that the option references
        @param USDC Address of the USDC token
        @param strikePrice strike price with decimals = 18
        @param expiry expiration timestamp as a unix timestamp
        
        @return the address of target otoken.
     */
    function getExistingOtoken(
        IOpynFactory opynFactory,
        address underlyingAsset,
        address USDC,
        uint256 strikePrice,
        uint256 expiry
    ) internal view returns (address) {
        return opynFactory.getOtoken(underlyingAsset, USDC, USDC, strikePrice, expiry, true);
    }

    /**
        @notice get the address at which a new oToken with these parameters would be deployed
     
        @param underlyingAsset asset that the option references
        @param USDC Address of the USDC token
        @param strikePrice strike price with decimals = 18
        @param expiry expiration timestamp as a unix timestamp

     @return targetAddress the address this oToken would be deployed at
     */
    function getTargetOtoken(
        IOpynFactory opynFactory,
        address underlyingAsset,
        address USDC,
        uint256 strikePrice,
        uint256 expiry
    ) internal view returns (address) {
        return opynFactory.getTargetOtokenAddress(underlyingAsset, USDC, USDC, strikePrice, expiry, true);
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title TimeUtils

    @author Roberto Cano <robercano>
    
    @notice Utility library to do time calculations. Used to adjust a timestamp to the next
            timestamp that falls on 08:00 UTC.
 */
library TimeUtils {
    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant SECONDS_IN_HOUR = 3600;
    uint256 public constant SECONDS_TO_0800_UTC = 8 * SECONDS_IN_HOUR;

    /**
      @notice Given a timestamp it calculates the timestamp that falls on the same day but is offset by
              the given number of seconds from 00:00 UTC of that day
      
      @param timestamp The timestamp to adjust
      @param secondsFromMidnightUTC The number of seconds from midnight UTC for the same day represented by `timestamp`

      @return The timestamp that falls on the same day but is offset by the given number of seconds from 00:00 UTC of that day
   */
    function calculateTodayWithOffset(uint256 timestamp, uint256 secondsFromMidnightUTC)
        internal
        pure
        returns (uint256)
    {
        uint256 timestampAtMidnightUTC = timestamp - (timestamp % SECONDS_IN_DAY);
        return timestampAtMidnightUTC + secondsFromMidnightUTC;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**  
    @title IAction

    @author Roberto Cano <robercano>

    @notice Interface for the investment actions executed on each investment cycle

    @dev An IAction represents an investment action that can be executed by an external caller.
    This caller will typically be a Vault, but it could also be used in other strategies.

    @dev An Action receives a loan from its caller so it can perform a specific investment action.
    The asset and amount of the loan is indicated in the `enterPosition` call, and the Action can transfer
    up to the indicated amount from the caller for the specified asset, and use it in the investment.
    Once the action indicates that the investment cycle is over, by signaling it through the
    `canPositionBeExited` call, the  caller can call `exitPosition` to exit the position. Upon this call,
    the action will transfer to the caller what's remaining of the loan, and will also return this amount
    as the return value of the `exitPotision` call.

    @dev The Actions does not need to transfer all allowed assets to itself if it is not needed. It could,
    for example, transfer a small amount which is enough to cover the cost of the investment. However,
    when returning the remaining amount, it must take into account the whole amount for the loan. For
    example:
        - The Action enters a position with a loan of 100 units of asset A
        - The Action transfers 50 units of asset A to itself
        - The Action exits the position with 65 units of asset A
        - Because it was allowed to get 100 units of asset A, and it made a profit of 15,
          the returned amount in the `exitPosition` call is 115 units of asset A (100 + 15).
        - If instead of 65 it had made a loss of 30 units, the returned amount would be
          70 units of asset A (100 - 30)

    @dev The above logic helps the caller easily track the profit/loss for the last investment cycle

 */
interface IAction {
    /// EVENTS
    event ActionPositionEntered(address indexed investmentAsset, uint256 amountToInvest);
    event ActionPositionExited(address indexed investmentAsset, uint256 amountReturned);

    /// FUNCTIONS
    /**
        @notice Function called to enter the investment position

        @param investmentAsset The asset available to the action contract for the investment 
        @param amountToInvest The amount of the asset that the action contract is allowed to use in the investment

        @dev When called, the action should have been approved for the given amount
        of asset. The action will retrieve the required amount of asset from the caller
        and invest it according to its logic
     */
    function enterPosition(address investmentAsset, uint256 amountToInvest) external;

    /**
        @notice Function called to exit the investment position

        @param investmentAsset The asset reclaim from the investment position

        @return amountReturned The amount of asset that the action contract received from the caller
        plus the profit or minus the loss of the investment cycle

        @dev When called, the action must transfer all of its balance for `asset` to the caller,
        and then return the total amount of asset that it received from the caller, plus/minus
        the profit/loss of the investment cycle.

        @dev See { IAction } description for more information on `amountReturned`
     */
    function exitPosition(address investmentAsset) external returns (uint256 amountReturned);

    /**
        @notice It inficates if the position can be entered or not

        @param investmentAsset The asset for which position can be entered or not

        @return canEnter true if the position can be entered, false otherwise

        @dev The function checks if the position can be entered for the current block. If it returns
        true then it indicates that the position can be entered at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeEntered(address investmentAsset) external view returns (bool canEnter);

    /**
        @notice It indicates if the position can be exited or not

        @param investmentAsset The asset for which position can be exited or not

        @return canExit true if the position can be exited, false otherwise

        @dev The function checks if the position can be exited for the current block. If it returns
        true then it indicates that the position can be exited at any moment from the current block.
        This invariant only takes into account the current state of the action itself and not any external
        dependendencies that the action may have
     */
    function canPositionBeExited(address investmentAsset) external view returns (bool canExit);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IEmergencyLock } from "../interfaces/IEmergencyLock.sol";
import { RolesManagerUpgradeable } from "./RolesManagerUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice See { IEmergencyLock }

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables
 */

contract EmergencyLockUpgradeable is RolesManagerUpgradeable, PausableUpgradeable, IEmergencyLock {
    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Unchained initializer

        @dev This contract does not need to initialize anything for itself. This contract
        replaces the Pausable contract. The Pausable contracts MUST NOT be used anywhere
        else in the inheritance chain. Assuming this, we can safely initialize the Pausable
        contract here

        @dev The name of the init function is marked as `_unchained` because we assume that the
        Pausable contract is not used anywhere else, and thus the functionality is that of an
        unchained initialization

        @dev The RolesManager contract MUST BE initialized in the Vault/Action contract as it
        it shared among other helper contracts
     */
    // solhint-disable-next-line func-name-mixedcase
    function __EmergencyLock_init_unchained() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    // FUNCTIONS

    /**
        @inheritdoc IEmergencyLock

        @dev Only functions marked with the `whenPaused` modifier will be executed
        when the contract is paused

        @dev This function can only be called when the contract is Unpaused
     */
    function pause() external onlyAdmin {
        _pause();
    }

    /**
        @inheritdoc IEmergencyLock

        @dev Only functions marked with the `whenUnpaused` modifier will be executed
        when the contract is unpaused

        @dev This function can only be called when the contract is Paused
     */
    function unpause() external onlyAdmin {
        _unpause();
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../interfaces/ILifecycleStates.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
    @title LifecycleStatesUpgradeable

    @author Roberto Cano <robercano>
    
    @notice See { ILifecycleStates }

    @dev The contract is upgradeable and follows the OpenZeppelin pattern to implement the
    upgradeability of the contract. Only the unchained initializer is provided as all
    contracts in the inheritance will be initialized in the Vault and Action contract

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables. The LifecycleState enumeration
    can be safely extended without affecting the storage
 */

contract LifecycleStatesUpgradeable is Initializable, ILifecycleStates {
    /// STORAGE

    /**
         @notice The current state of the vault
     */
    LifecycleState private _state;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Initializes the current state to Unlocked

        @dev Can only be called if the contracts has NOT been initialized

        @dev The name of the init function is marked as `_unchained` because it does not
        initialize the RolesManagerUpgradeable contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __LifecycleStates_init_unchained() internal onlyInitializing {
        _state = LifecycleState.Unlocked;
    }

    /// MODIFIERS

    /**
        @notice Modifier to scope functions to only be accessible when the state is Unlocked
     */
    modifier onlyUnlocked() {
        require(_state == LifecycleState.Unlocked, "State is not Unlocked");
        _;
    }

    /**
        @notice Modifier to scope functions to only be accessible when the state is Committed
     */
    modifier onlyCommitted() {
        require(_state == LifecycleState.Committed, "State is not Commited");
        _;
    }

    /**
        @notice Modifier to scope functions to only be accessible when the state is Locked
     */
    modifier onlyLocked() {
        require(_state == LifecycleState.Locked, "State is not Locked");
        _;
    }

    /// FUNCTIONS

    /**
        @notice Function to set the new state of the vault
        @param newState The new state of the vault
     */
    function _setLifecycleState(LifecycleState newState) internal {
        LifecycleState prevState = _state;

        _state = newState;

        emit LifecycleStateChanged(prevState, newState);
    }

    /**
        @inheritdoc ILifecycleStates
     */
    function getLifecycleState() public view returns (LifecycleState) {
        return _state;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRefundsHelper } from "../interfaces/IRefundsHelper.sol";
import { RolesManagerUpgradeable } from "./RolesManagerUpgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { AddressUpgradeable as Address } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
    @title RefundsHelperUpgreadable

    @author Roberto Cano <robercano>
    
    @notice See { IRefundsHelper}

    @dev It inherits from the RolesManagerUpgradeable contract to scope the refund functions
    for only the Admin role.

    @dev It does not initialize the RolesManagerUpgradeable as that is a contract that is shared
    among several other contracts of the vault. The initialization will happen in the Vault and
    Action contract

    @dev No storage gaps have been added as the functionlity of this contract is considered to be
    final and there is no need to add more storage variables
 */

contract RefundsHelperUpgreadable is RolesManagerUpgradeable, IRefundsHelper {
    using Address for address payable;

    /// STORAGE

    /**
        @notice The list of tokens that cannot be refunded

        @dev The list is populated at construction time and cannot be changed. For this purpose it
        is private and there is no setter function for it
    */
    mapping(address => bool) private _cannotRefund;

    /**
        @notice Flag to indicate if ETH can be refunded or not

        @dev The flag is set at initialization time and cannot be changed afterwards. For this
        purpose it is private and there is no setter function for it
    */
    bool private _cannotRefundETH;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice Marks the given token addresses as `non-refundable`

        @param _cannotRefundToken The list of token addresses that cannot be refunded

        @dev Can only be called if the contracts has NOT been initialized

        @dev The name of the init function is marked as `_unchained` because it does not
        initialize the RolesManagerUpgradeable contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __RefundsHelper_init_unchained(address[] memory _cannotRefundToken, bool cannotRefundETH_)
        internal
        onlyInitializing
    {
        for (uint256 i = 0; i < _cannotRefundToken.length; i++) {
            _cannotRefund[_cannotRefundToken[i]] = true;
        }

        _cannotRefundETH = cannotRefundETH_;
    }

    /// FUNCTIONS

    /**
        @inheritdoc IRefundsHelper

        @dev This function can be only called by the admin and only if the token is not in the
        list of tokens that cannot be refunded.
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external onlyAdmin {
        require(!_cannotRefund[token], "Token cannot be refunded");
        require(recipient != address(0), "Recipient address cannot be the null address");

        SafeERC20.safeTransfer(IERC20(token), recipient, amount);
    }

    /**
        @inheritdoc IRefundsHelper

        @dev This function can be only called by the admin and only if ETH is allowed to be
        refunded
     */
    function refundETH(uint256 amount, address payable recipient) external onlyAdmin {
        require(!_cannotRefundETH, "ETH cannot be refunded");
        require(recipient != address(0), "Recipient address cannot be the null address");

        recipient.sendValue(amount);
    }

    /// GETTERS

    /**
        @inheritdoc IRefundsHelper
     */
    function canRefund(address token) public view returns (bool) {
        return !_cannotRefund[token];
    }

    /**
        @inheritdoc IRefundsHelper
     */
    function canRefundETH() public view returns (bool) {
        return !_cannotRefundETH;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IRolesManager } from "../interfaces/IRolesManager.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
    @title RolesManagerUpgradeable

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states


    @dev It provides a functionality similar to the AccessControl contract from OpenZeppelin. The decision
    to implement the roles manually was made to avoid exposiing a higher attack surface area coming from 
    the AccessControl contract, plus reducing the size of the deployment as well

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`

    @dev This contract is intended to be always initialized in an unchained way as it may be shared
    among different helper contracts that need to scope their functions to the Admin or Keeper role.
 */

contract RolesManagerUpgradeable is Initializable, ContextUpgradeable, IRolesManager {
    // STORAGE

    /**
        @notice The address of the admin role

        @dev The admin role is the only role that can change the other roles, including the Admin itself
     */
    address private _adminAddress;

    /**
        @notice The address of the strategist role

        @dev The strategist role is the one that can change the vault and action parameters related to the
        investment strategy. Things like slippage percentage, maximum premium, principal percentages, etc...
     */
    address private _strategistAddress;

    /**
        @notice The address of the operator role

        @dev The operator role is the one that can cycle the vault and the action through its different states
     */
    address private _operatorAddress;

    /**
        @notice The address of the vault

        @dev The vault address is used in the actions to only allow the vault to call enterPosition and exitPosition
     */
    address private _vaultAddress;

    /// MODIFIERS

    /**
      @notice Modifier to scope functions to only be accessible by the Admin
     */
    modifier onlyAdmin() {
        require(_msgSender() == _adminAddress, "Only the Admin can call this function");
        _;
    }

    /**
      @notice Modifier to scope functions to only be accessible by the Strategist
     */
    modifier onlyStrategist() {
        require(_msgSender() == _strategistAddress, "Only the Strategist can call this function");
        _;
    }

    /**
      @notice Modifier to scope functions to only be accessible by the Operator
     */
    modifier onlyOperator() {
        require(_msgSender() == _operatorAddress, "Only the Operator can call this function");
        _;
    }

    /**
      @notice Modifier to scope functions to only be accessible by the Vault
     */
    modifier onlyVault() {
        require(_msgSender() == _vaultAddress, "Only the Vault can call this function");
        _;
    }

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice This does not chain the initialization to the parent contract.
        Also this contract does not need to initialize anything itself.

        @dev The Vault role is not initialized here. Instead, the admin must call
             `changeVault` to set the vault role address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __RolesManager_init_unchained(
        address adminAddress,
        address strategistAddress,
        address operatorAddress
    ) internal onlyInitializing {
        __changeAdmin(adminAddress);
        __changeStrategist(strategistAddress);
        __changeOperator(operatorAddress);
    }

    /// FUNCTIONS

    /**
        @inheritdoc IRolesManager

        @dev Only the previous Admin can change the address to a new one
     */
    function changeAdmin(address newAdminAddress) external onlyAdmin {
        __changeAdmin(newAdminAddress);
    }

    /**
        @inheritdoc IRolesManager

        @dev Only the Admin can change the address to a new one
     */
    function changeStrategist(address newStrategistAddress) external onlyAdmin {
        __changeStrategist(newStrategistAddress);
    }

    /**
        @inheritdoc IRolesManager

        @dev Only the Admin can change the address to a new one
     */
    function changeOperator(address newOperatorAddress) external onlyAdmin {
        __changeOperator(newOperatorAddress);
    }

    /**
        @inheritdoc IRolesManager

        @dev Only the Admin can change the address to a new one
     */
    function changeVault(address newVaultAddress) external onlyAdmin {
        __changeVault(newVaultAddress);
    }

    /**
        @inheritdoc IRolesManager
     */
    function getAdmin() public view returns (address) {
        return _adminAddress;
    }

    /**
        @inheritdoc IRolesManager
     */
    function getStrategist() public view returns (address) {
        return _strategistAddress;
    }

    /**
        @inheritdoc IRolesManager
     */
    function getOperator() public view returns (address) {
        return _operatorAddress;
    }

    /**
        @inheritdoc IRolesManager
     */
    function getVault() public view returns (address) {
        return _vaultAddress;
    }

    /// INTERNALS

    /**
        @notice See { changeAdmin }
     */
    function __changeAdmin(address newAdminAddress) private {
        require(newAdminAddress != address(0), "New Admin address cannot be the null address");

        address prevAdminAddress = _adminAddress;

        _adminAddress = newAdminAddress;

        emit AdminChanged(prevAdminAddress, newAdminAddress);
    }

    /**
        @notice See { changeStrategist }
     */
    function __changeStrategist(address newStrategistAddress) private {
        require(newStrategistAddress != address(0), "New Strategist address cannot be the null address");

        address prevStrategistAddress = _strategistAddress;

        _strategistAddress = newStrategistAddress;

        emit StrategistChanged(prevStrategistAddress, newStrategistAddress);
    }

    /**
        @notice See { changeOperator }
     */
    function __changeOperator(address newOperatorAddress) private {
        require(newOperatorAddress != address(0), "New Operator address cannot be the null address");

        address prevOperatorAddress = _operatorAddress;

        _operatorAddress = newOperatorAddress;

        emit OperatorChanged(prevOperatorAddress, newOperatorAddress);
    }

    /**
        @notice See { changeVault }
     */
    function __changeVault(address newVaultAddress) private {
        require(newVaultAddress != address(0), "New Vault address cannot be the null address");

        address prevVaultAddress = _vaultAddress;

        _vaultAddress = newVaultAddress;

        emit VaultChanged(prevVaultAddress, newVaultAddress);
    }

    /**
       @dev This empty reserved space is put in place to allow future versions to add new
       variables without shifting down storage in the inheritance chain.
       See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     
       @dev The size of the gap plus the size of the storage variables defined
       above must equal 50 storage slots
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title EmergencyLock

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to pause all the functionality of the vault in case
    of an emergency
 */

interface IEmergencyLock {
    // FUNCTIONS

    /**
        @notice Pauses the contract
     */
    function pause() external;

    /**
        @notice Unpauses the contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRolesManager

    @author Roberto Cano <robercano>
    
    @notice The RolesManager contract is a helper contract that provides a three access roles: Admin,
    Strategist and Operator. The scope of the different roles is as follows:
      - Admin: The admin role is the only role that can change the other roles, including the Admin
      role itself. 
      - Strategist: The strategist role is the one that can change the vault and action parameters
      related to the investment strategy. Things like slippage percentage, maximum premium, principal
      percentages, etc...
      - Operator: The operator role is the one that can cycle the vault and the action through its
      different states

    @dev The Admin can always change the Strategist address, Operator address and also change the Admin address.
    The Strategist and Operator roles have no special access except the access given explcitiely by their
    respective modifiers `onlyStrategist` and `onlyOperator`.
 */

interface IRolesManager {
    /// EVENTS
    event AdminChanged(address indexed prevAdminAddress, address indexed newAdminAddress);
    event StrategistChanged(address indexed prevStrategistAddress, address indexed newStrategistAddress);
    event OperatorChanged(address indexed prevOperatorAddress, address indexed newOperatorAddress);
    event VaultChanged(address indexed prevVaultAddress, address indexed newVaultAddress);

    /// FUNCTIONS

    /**
        @notice Changes the existing Admin address to a new one

        @dev Only the previous Admin can change the address to a new one
     */
    function changeAdmin(address newAdminAddress) external;

    /**
        @notice Changes the existing Strategist address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeStrategist(address newStrategistAddress) external;

    /**
        @notice Changes the existing Operator address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeOperator(address newOperatorAddress) external;

    /**
        @notice Changes the existing Vault address to a new one

        @dev Only the Admin can change the address to a new one
     */
    function changeVault(address newVaultAddress) external;

    /**
        @notice Returns the current Admin address
     */
    function getAdmin() external view returns (address);

    /**
        @notice Returns the current Strategist address
     */
    function getStrategist() external view returns (address);

    /**
        @notice Returns the current Operator address
     */
    function getOperator() external view returns (address);

    /**
        @notice Returns the current Vault address
     */
    function getVault() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title ILifecycleStates

    @author Roberto Cano <robercano>
    
    @notice Handles the lifecycle of the hedging vault and provides the necessary modifiers
    to scope functions that must only work in certain states. It also provides a getter
    to query the current state and an internal setter to change the state
 */

interface ILifecycleStates {
    /// STATES

    /**
        @notice States defined for the vault. Although the exact meaning of each state is
        dependent on the HedgingVault contract, the following assumptions are made here:
            - Unlocked: the vault accepts immediate deposits and withdrawals and the specific
            configuration of the next investment strategy is not yet known.
            - Committed: the vault accepts immediate deposits and withdrawals but the specific
            configuration of the next investment strategy is already known
            - Locked: the vault is locked and cannot accept immediate deposits or withdrawals. All
            of the assets managed by the vault are locked in it. It could accept deferred deposits
            and withdrawals though
     */
    enum LifecycleState {
        Unlocked,
        Committed,
        Locked
    }

    /// EVENTS
    event LifecycleStateChanged(LifecycleState indexed prevState, LifecycleState indexed newState);

    /// FUNCTIONS

    /**
        @notice Function to get the current state of the vault
        @return The current state of the vault
     */
    function getLifecycleState() external view returns (LifecycleState);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IRefundsHelper

    @author Roberto Cano <robercano>
    
    @notice Helper contract that allows the Admin to refund tokens or ETH sent to the vault
    by mistake. At construction time it receives the list of tokens that cannot be refunded.
    Those tokens are typically the asset managed by the vault and any intermediary tokens
    that the vault may use to manage the asset.
 */
interface IRefundsHelper {
    /// FUNCTIONS

    /**
        @notice Refunds the given amount of tokens to the given address
        @param token address of the token to be refunded
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refund(
        address token,
        uint256 amount,
        address recipient
    ) external;

    /**
        @notice Refunds the given amount of ETH to the given address
        @param amount amount of tokens to be refunded
        @param recipient address to which the tokens will be refunded
     */
    function refundETH(uint256 amount, address payable recipient) external;

    /// GETTERS

    /**
        @notice Returns whether the given token is refundable or not

        @param token address of the token to be checked

        @return true if the token is refundable, false otherwise
     */
    function canRefund(address token) external view returns (bool);

    /**
        @notice Returns whether the ETH is refundable or not

        @return true if ETH is refundable, false otherwise
     */
    function canRefundETH() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../../interfaces/IPotionProtocolOracle.sol";
import "../../interfaces/IOtoken.sol";
import { PotionBuyInfo } from "../../interfaces/IPotionBuyInfo.sol";
import "../../common/RolesManagerUpgradeable.sol";

/**
    @title IPotionProtocolOracle

    @notice Oracle contract for the Potion Protocol potion buy. It takes care of holding the information
    about the counterparties that will be used to buy a particular potion (potion) with a maximum allowed
    premium

    @dev It is very basic and it just aims to abstract the idea of an Oracle into a separate contract
    but it is still very coupled with PotionProtocolHelperUpgradeable

    @dev It inherits from the RolesManagerUpgradeable contract to scope the parameters setting
    functions for only the Keeper role.

    @dev It does not initialize the RolesManagerUpgradeable as that is a contract that is shared
    among several other contracts of the Action. The initialization will happen in the Action contract

 */
contract PotionProtocolOracleUpgradeable is IPotionProtocolOracle, RolesManagerUpgradeable {
    /**
        @notice Information on the buy of an OToken 

        @dev potion => PotionBuyInfo
    */
    mapping(bytes32 => PotionBuyInfo) private _potionBuyInfo;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice This does not chain the initialization to the parent contract.
        Also this contract does not need to initialize anything itself.
     */
    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __PotionProtocolOracle_init_unchained() internal view onlyInitializing {
        // Empty on purpose
    }

    /// FUNCTIONS

    /**
        @inheritdoc IPotionProtocolOracle
     */
    function setPotionBuyInfo(PotionBuyInfo calldata info) external onlyOperator {
        bytes32 id = _getPotionId(info.underlyingAsset, info.strikePriceInUSDC, info.expirationTimestamp);
        _potionBuyInfo[id] = info;
    }

    /**
        @inheritdoc IPotionProtocolOracle
     */
    function getPotionBuyInfo(
        address underlyingAsset,
        uint256 strikePrice,
        uint256 expirationTimestamp
    ) public view returns (PotionBuyInfo memory) {
        bytes32 id = _getPotionId(underlyingAsset, strikePrice, expirationTimestamp);
        return _potionBuyInfo[id];
    }

    /**
        @notice Calculates the unique ID for a potion

        @param underlyingAsset The address of the underlying token of the potion
        @param strikePrice The strike price of the potion with 8 decimals
        @param expirationTimestamp The timestamp when the potion expires

        @return The unique ID for the potion
     */
    function _getPotionId(
        address underlyingAsset,
        uint256 strikePrice,
        uint256 expirationTimestamp
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(underlyingAsset, strikePrice, expirationTimestamp));
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "../interfaces/IPotionLiquidityPool.sol";
import { IOtoken } from "../interfaces/IOtoken.sol";
import { IOpynFactory } from "../interfaces/IOpynFactory.sol";
import { IOpynController } from "../interfaces/IOpynController.sol";
import { PotionBuyInfo } from "../interfaces/IPotionBuyInfo.sol";

import "./PercentageUtils.sol";
import "./PriceUtils.sol";
import "./OpynProtocolLib.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/**
    @title PotionProtocolLib

    @author Roberto Cano <robercano>

    @notice Helper library to buy potions from the Potion Protocol
 */

library PotionProtocolLib {
    using PercentageUtils for uint256;
    using OpynProtocolLib for IOpynFactory;

    /// CONSTANTS
    uint256 private constant OTOKEN_DECIMALS = 8;

    /// FUNCTIONS

    /**
        @notice Buys the specified amount of potions with the given parameters

        @param potionLiquidityPoolManager Address of the Potion Protocol liquidity manager
        @param buyInfo The information required to buy a specific potion with a specific maximum premium requirement
        @param slippage Slippage to apply to the premium to calculate the maximum premium allowed

        @return actualPremium The actual premium paid for the purchase of potions

        @dev Convenience function that calculates the slippage on the premium and calls the
        pool manager. Abstracted here in case it is needed to expand the logic in the future.
     */

    function buyPotion(
        IPotionLiquidityPool potionLiquidityPoolManager,
        IOpynFactory opynFactory,
        PotionBuyInfo memory buyInfo,
        uint256 slippage,
        IERC20 USDC
    ) internal returns (uint256 actualPremium) {
        uint256 maxPremium = buyInfo.expectedPremiumInUSDC.addPercentage(slippage);

        SafeERC20.safeApprove(USDC, address(potionLiquidityPoolManager), maxPremium);

        address oToken = opynFactory.getExistingOtoken(
            buyInfo.underlyingAsset,
            address(USDC),
            buyInfo.strikePriceInUSDC,
            buyInfo.expirationTimestamp
        );

        if (oToken == address(0)) {
            address targetOToken = opynFactory.getTargetOtoken(
                buyInfo.underlyingAsset,
                address(USDC),
                buyInfo.strikePriceInUSDC,
                buyInfo.expirationTimestamp
            );

            require(
                targetOToken == buyInfo.targetPotionAddress,
                "Otoken does not exist and target address does not match"
            );

            actualPremium = potionLiquidityPoolManager.createAndBuyOtokens(
                buyInfo.underlyingAsset,
                address(USDC),
                address(USDC),
                buyInfo.strikePriceInUSDC,
                buyInfo.expirationTimestamp,
                true,
                buyInfo.sellers,
                maxPremium
            );
        } else {
            require(oToken == buyInfo.targetPotionAddress, "Otoken does exist but target address does not match");

            actualPremium = potionLiquidityPoolManager.buyOtokens(IOtoken(oToken), buyInfo.sellers, maxPremium);
        }

        if (actualPremium < maxPremium) {
            SafeERC20.safeApprove(USDC, address(potionLiquidityPoolManager), 0);
        }
    }

    /**
        @notice Settles the specified potion after it has expired

        @param potionLiquidityPoolManager Address of the Potion Protocol liquidity manager
        @param buyInfo The information used to previously purchase the potions
     */
    function settlePotion(IPotionLiquidityPool potionLiquidityPoolManager, PotionBuyInfo memory buyInfo) internal {
        IOtoken potion = IOtoken(buyInfo.targetPotionAddress);
        potionLiquidityPoolManager.settleAfterExpiry(potion);
    }

    /**
        @notice Redeems the specified potion after it has expired

        @param potionLiquidityPoolManager Address of the Potion Protocol liquidity manager
        @param opynController Address of the Opyn controller to claim the payout
        @param buyInfo The information used to previously purchase the potions
        
        @dev The settlement will send back the proceeds of the expired potion to this contract

        @dev The settled amount is not available in the contract. Check the below TODO for more info
     */
    function redeemPotion(
        IPotionLiquidityPool potionLiquidityPoolManager,
        IOpynController opynController,
        PotionBuyInfo memory buyInfo
    ) internal {
        IOtoken potion = IOtoken(buyInfo.targetPotionAddress);

        uint256 potionVaultId = potionLiquidityPoolManager.getVaultId(potion);

        IOpynController.ActionArgs[] memory redeemArgs = _getRedeemPotionAction(
            address(this),
            address(potion),
            potionVaultId,
            buyInfo.totalSizeInPotions
        );

        opynController.operate(redeemArgs);
    }

    /**
        @notice Retrieves the payout amount for an expired potion

        @param opynController Address of the Opyn controller to retrieve the payout amount
        @param potion Potion (otoken) to retrieve the payout amount for
        @param amount The amount of potions to retrieve the payout amount for

        @return payout The amount of USDC that will be returned to the buyer
     */
    function getPayout(
        IOpynController opynController,
        address potion,
        uint256 amount
    ) internal view returns (uint256 payout) {
        payout = opynController.getPayout(potion, amount);
    }

    /**
        @notice Gets the amount of potions required to cover the specified amount of the hedged asset

        @param hedgedAsset The asset being hedged by the potions
        @param amount The amount of the hedged asset to be covered by the potions

        @return The amount of potions required to cover the specified amount of the hedged asset
     */
    function getPotionsAmount(address hedgedAsset, uint256 amount) internal view returns (uint256) {
        uint256 hedgedAssetDecimals = IERC20Metadata(hedgedAsset).decimals();

        // Convert with a 1:1 ratio, just adjust the decimals
        return PriceUtils.convertAmount(hedgedAssetDecimals, OTOKEN_DECIMALS, amount, 1, 1);
    }

    /**
        @notice Retrieves the redeem action arguments for an expired potion

        @param owner Address of the buyer of the potion
        @param potion Potion (otoken) to settle
        @param vaultId The vault id of the potion to redeem
        @param amount The amount of USDC that will be returned to the buyer

        @return The redeem action arguments
    */
    function _getRedeemPotionAction(
        address owner,
        address potion,
        uint256 vaultId,
        uint256 amount
    ) private pure returns (IOpynController.ActionArgs[] memory) {
        IOpynController.ActionArgs[] memory redeemArgs = new IOpynController.ActionArgs[](1);
        redeemArgs[0] = IOpynController.ActionArgs({
            actionType: IOpynController.ActionType.Redeem,
            owner: owner,
            secondAddress: owner,
            asset: potion,
            vaultId: vaultId,
            amount: amount,
            index: 0,
            data: ""
        });

        return redeemArgs;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "@prb/math/contracts/PRBMathUD60x18.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

/**
    @title PriceUtils

    @author Roberto Cano <robercano>
    
    @notice Utility library to convert an input amount into an output amount using
    the given priceNumerator as the conversion factor
 */
library PriceUtils {
    /**
    @notice Type for the swap priceNumerator configured by the Keeper

    @dev Internally it is represented by a PRBMathUD60x18 fixed point number
    */
    // TODO: OpenZeppelin contracts are throwing an error if we define a custom type here
    //type Price is uint256;

    using PRBMathUD60x18 for uint256;

    uint256 internal constant PRICE_RATE_DECIMALS = 8;

    /**
        @notice Given an amount of input asset it calculates how much amount of the output 
        asset will be received at the given priceNumerator rate

        @param priceRate The priceNumerator rate of as output/input in PRBMathUD60x18 format
        @param inputAmount The amount of input asset to convert, as a uint256

        @return The amount of output asset that will be received
     */
    function toOutputAmount(uint256 priceRate, uint256 inputAmount) internal pure returns (uint256) {
        return priceRate.mul(PRBMathUD60x18.fromUint(inputAmount)).toUint();
    }

    /**
        @notice Given a desired output amount it calculates how much input asset is needed
        at the current priceNumerator rate

        @param priceRate The priceNumerator rate of as input/output in PRBMathUD60x18 format
        @param outputAmount The desired amount of output asset, as a uint256

        @return The amount of input asset that will be received
     */
    function toInputAmount(uint256 priceRate, uint256 outputAmount) internal pure returns (uint256) {
        return PRBMathUD60x18.fromUint(outputAmount).div(priceRate).toUint();
    }

    /**
        @notice Converts an amount of input token to an amount of output token using the given price rate

        @param inputTokenDecimals The number of decimals of the input token
        @param outputTokenDecimals The number of decimals of the output token
        @param amount The amount of the input token to convert
        @param priceNumerator The numerator of the price rate
        @param priceDenominator The denominator of the price rate

        @return outputAmount The output amount denominated in the output token
     */
    function convertAmount(
        uint256 inputTokenDecimals,
        uint256 outputTokenDecimals,
        uint256 amount,
        uint256 priceNumerator,
        uint256 priceDenominator
    ) internal pure returns (uint256 outputAmount) {
        if (inputTokenDecimals == outputTokenDecimals) {
            outputAmount = (amount * priceNumerator) / priceDenominator;
        } else if (inputTokenDecimals > outputTokenDecimals) {
            uint256 exp = inputTokenDecimals - outputTokenDecimals;
            outputAmount = (amount * priceNumerator) / priceDenominator / (10**exp);
        } else {
            uint256 exp = outputTokenDecimals - inputTokenDecimals;
            outputAmount = (amount * priceNumerator * (10**exp)) / priceDenominator;
        }

        return outputAmount;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "./ICurveManager.sol";
import "./ICriteriaManager.sol";

import "./IOtoken.sol";

// TODO: Add a description of the interface
interface IPotionLiquidityPool {
    /*
        @notice The details of a given counterparty that will be used to buy a potion

        @custom:member lp The LP to buy from
        @custom:member poolId The pool (belonging to LP) that will colalteralize the otoken
        @custom:member curve The curve used to calculate the otoken premium
        @custom:member criteria The criteria associated with this curve, which matches the otoken
        @custom:member orderSizeInOtokens The number of otokens to buy from this particular counterparty
    */
    struct CounterpartyDetails {
        address lp;
        uint256 poolId;
        ICurveManager.Curve curve;
        ICriteriaManager.Criteria criteria;
        uint256 orderSizeInOtokens;
    }

    /**
        @notice The data associated with a given pool of capital, belonging to one LP

        @custom:member total The total (locked or unlocked) of capital in the pool, denominated in collateral tokens
        @custom:member locked The amount of locked capital in the pool, denominated in collateral tokens
        @custom:member curveHash Identifies the curve to use when pricing the premiums charged for any otokens
                                 sold (& collateralizated) by this pool
        @custom:member criteriaSetHash Identifies the set of otokens that this pool is willing to sell (& collateralize)
    */
    struct PoolOfCapital {
        uint256 total;
        uint256 locked;
        bytes32 curveHash;
        bytes32 criteriaSetHash;
    }

    /**
       @notice Buy a OTokens from the specified list of sellers.
       
       @param _otoken The identifier (address) of the OTokens being bought.
       @param _sellers The LPs to buy the new OTokens from. These LPs will charge a premium to collateralize the otoken.
       @param _maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
       
       @return premium The aggregated premium paid.
     */
    function buyOtokens(
        IOtoken _otoken,
        CounterpartyDetails[] memory _sellers,
        uint256 _maxPremium
    ) external returns (uint256 premium);

    /**
        @notice Creates a new otoken, and then buy it from the specified list of sellers.
     
        @param underlyingAsset A property of the otoken that is to be created.
        @param strikeAsset A property of the otoken that is to be created.
        @param collateralAsset A property of the otoken that is to be created.
        @param strikePrice A property of the otoken that is to be created.
        @param expiry A property of the otoken that is to be created.
        @param isPut A property of the otoken that is to be created.
        @param sellers The LPs to buy the new otokens from. These LPs will charge a premium to collateralize the otoken.
        @param maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
        
        @return premium The total premium paid.
     */
    function createAndBuyOtokens(
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut,
        CounterpartyDetails[] memory sellers,
        uint256 maxPremium
    ) external returns (uint256 premium);

    /**
       @notice Retrieve unused collateral from Opyn into this contract. Does not redistribute it to our (unbounded number of) LPs.
               Redistribution can be done by calling redistributeSettlement(addresses).

       @param _otoken The identifier (address) of the expired OToken for which unused collateral should be retrieved.
     */
    function settleAfterExpiry(IOtoken _otoken) external;

    /**
        @notice Get the ID of the existing Opyn vault that Potion uses to collateralize a given OToken.
        
        @param _otoken The identifier (token contract address) of the OToken. Not checked for validity in this view function.
        
        @return The unique ID of the vault, > 0. If no vault exists, the returned value will be 0
     */
    function getVaultId(IOtoken _otoken) external view returns (uint256);

    /**
        @dev Returns the data about the pools of capital, indexed first by LP
             address and then by an (arbitrary) numeric poolId

        @param lpAddress The address of the LP that owns the pool
        @param poolId The ID of the pool owned by the LP

        @return The data about the pool of capital
    */
    function lpPools(address lpAddress, uint256 poolId) external view returns (PoolOfCapital memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

/**
  @notice Opyn Address Book interface, used to retrieve the addresses of other Opyn contracts
 */
interface IOpynAddressBook {
    /* Getters */

    function getOtokenFactory() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
 * @title Public Controller interface
 * @notice For use by consumers and end users. Excludes permissioned (e.g. owner-only) functions
 */
interface IOpynController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    /**
        @notice return if an expired oToken is ready to be settled, only true when price for underlying,
        strike and collateral assets at this specific expiry is available in our Oracle module
        
        @param _otoken oToken

        @return true if the expired oToken is ready to be settled, false otherwise
     */
    function isSettlementAllowed(address _otoken) external view returns (bool);

    /**
        @notice get an oToken's payout/cash value after expiry, in the collateral asset

        @param _otoken oToken address
        @param _amount amount of the oToken to calculate the payout for, always represented in 1e8
        
        @return amount of collateral to pay out
     */
    function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

    /**
        @notice execute a number of actions on specific vaults
        @dev can only be called when the system is not fully paused
        @param _actions array of actions arguments
     */
    function operate(ActionArgs[] memory _actions) external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
 * @title IOpynFactory
 * @notice Interface used to interact with Opyn's OTokens.
 */
interface IOpynFactory {
    /**
     * @notice get the oToken address for an already created oToken, if no oToken has been created with these parameters, it will return address(0)
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return the address of target otoken.
     */
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    /**
     * @notice get the address at which a new oToken with these parameters would be deployed
     * @dev return the exact address that will be deployed at with _computeAddress
     * @param _underlyingAsset asset that the option references
     * @param _strikeAsset asset that the strike price is denominated in
     * @param _collateralAsset asset that is held as collateral against short/written options
     * @param _strikePrice strike price with decimals = 18
     * @param _expiry expiration timestamp as a unix timestamp
     * @param _isPut True if a put option, False if a call option
     * @return targetAddress the address this oToken would be deployed at
     */
    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

/**
    @notice Opyn Oracle interface, used to retrieve the prices of assets
 */
interface IOpynOracle {
    /**
        @notice get a live asset price from the asset's pricer contract
        @param _asset asset address
        @return price scaled by 1e8, denominated in USD
                e.g. 17568900000 => 175.689 USD
     */
    function getPrice(address _asset) external view returns (uint256);

    /**
        @notice set stable asset price
        @dev price should be scaled by 1e8
        @param _asset asset address
        @param _price price
    */
    function setStablePrice(address _asset, uint256 _price) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "./IPotionLiquidityPool.sol";
import { PotionBuyInfo } from "./IPotionBuyInfo.sol";

/**
    @title IPotionProtocolOracle

    @notice Oracle contract for the Potion Protocol potion buy. It takes care of holding the information
    about the counterparties that will be used to buy a particular potion (potion) with a maximum allowed
    premium

    @dev It is very basic and it just aims to abstract the idea of an Oracle into a separate contract
    but it is still very coupled with PotionProtocolHelperUpgradeable
 */
interface IPotionProtocolOracle {
    /// FUNCTIONS

    /**
        @notice Sets the potion buy information for a specific potion

        @param info The information required to buy a specific potion with a specific maximum premium requirement

        @dev Only the Operator can call this function
     */
    function setPotionBuyInfo(PotionBuyInfo calldata info) external;

    /**
        @notice Gets the potion buy information for a given OToken

        @param underlyingAsset The address of the underlying token of the potion
        @param strikePrice The strike price of the potion
        @param expirationTimestamp The timestamp when the potion expires

        @return The Potion Buy information for the given potion

        @dev See { PotionBuyInfo }

     */
    function getPotionBuyInfo(
        address underlyingAsset,
        uint256 strikePrice,
        uint256 expirationTimestamp
    ) external view returns (PotionBuyInfo memory);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

// TODO: Add a description of the interface
interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);

    function init(
        address _addressBook,
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external;

    function getOtokenDetails()
        external
        view
        returns (
            address,
            address,
            address,
            uint256,
            uint256,
            bool
        );

    function mintOtoken(address account, uint256 amount) external;

    function burnOtoken(address account, uint256 amount) external;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import { IPotionLiquidityPool } from "../interfaces/IPotionLiquidityPool.sol";

/**    
    @title IPotionBuyInfo
        
    @author Roberto Cano <robercano>

    @notice Structure for the PotionBuyInfo
 */

/**
        @notice The information required to buy a specific potion with a specific maximum premium requirement

        @custom:member targetPotionAddress The address of the potion (otoken) to buy
        @custom:member underlyingAsset The address of the underlying asset of the potion (otoken) to buy
        @custom:member strikePriceInUSDC The strike price of the potion (otoken) to buy, with 8 decimals
        @custom:member expirationTimestamp The expiration timestamp of the potion (otoken) to buy
        @custom:member sellers The list of liquidity providers that will be used to buy the potion
        @custom:member expectedPremiumInUSDC The expected premium to be paid for the given order size
                       and the given sellers, in USDC
        @custom:member totalSizeInPotions The total number of potions to buy using the given sellers list
     */
struct PotionBuyInfo {
    address targetPotionAddress;
    address underlyingAsset;
    uint256 strikePriceInUSDC;
    uint256 expirationTimestamp;
    IPotionLiquidityPool.CounterpartyDetails[] sellers;
    uint256 expectedPremiumInUSDC;
    uint256 totalSizeInPotions;
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
 * @title ICurveManager
 * @notice Keeps a registry of all Curves that are known to the Potion protocol
 */
interface ICurveManager {
    struct Curve {
        int256 a_59x18;
        int256 b_59x18;
        int256 c_59x18;
        int256 d_59x18;
        int256 max_util_59x18;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

// TODO: Add a description of the interface
interface ICriteriaManager {
    struct Criteria {
        address underlyingAsset;
        address strikeAsset;
        bool isPut;
        uint256 maxStrikePercent;
        uint256 maxDurationInDays; // Must be > 0 for valid criteria. Doubles as existence flag.
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

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
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

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

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "../../interfaces/IUniswapV3Oracle.sol";
import "../../common/RolesManagerUpgradeable.sol";
import "../../library/PriceUtils.sol";

/**
    @title UniswapV3OracleUpgradeable

    @notice Oracle contract for Uniswap V3 swaps. It takes care of holding information about the
    path to use for a specific swap, and the expected price for a that swap.

    @dev It is very basic and it just aims to abstract the idea of an Oracle into a separate contract
    but it is still very coupled with UniswapV3HelperUpgradeable.

    @dev It inherits from the RolesManagerUpgradeable contract to scope the parameters setting
    functions for only the Keeper role.

    @dev It does not initialize the RolesManagerUpgradeable as that is a contract that is shared
    among several other contracts of the Action. The initialization will happen in the Action contract

 */
contract UniswapV3OracleUpgradeable is IUniswapV3Oracle, RolesManagerUpgradeable {
    /**
        @notice Swap information for each pair of input and output tokens

        @dev inputToken => outputToken => SwapInfo

        @dev the swap direction is important so there is no need to store the
        reverse mapping of outputToken => inputToken
    */
    mapping(address => mapping(address => SwapInfo)) private _swapInfo;

    /// UPGRADEABLE INITIALIZERS

    /**
        @notice This does not chain the initialization to the parent contract.
        Also this contract does not need to initialize anything itself.
     */
    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __UniswapV3Oracle_init_unchained() internal view onlyInitializing {
        // Empty on purpose
    }

    /// FUNCTIONS

    /**
        @inheritdoc IUniswapV3Oracle
     */
    function setSwapInfo(SwapInfo calldata info) external onlyOperator {
        _swapInfo[info.inputToken][info.outputToken] = info;
    }

    /**
        @inheritdoc IUniswapV3Oracle

     */
    function getSwapInfo(address inputToken, address outputToken) public view returns (SwapInfo memory) {
        return _swapInfo[inputToken][outputToken];
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "./PercentageUtils.sol";

/**
    @title UniswapV3SwapLib

    @author Roberto Cano <robercano>

    @notice Helper library to perform Uniswap V3 multi-hop swaps
 */
library UniswapV3SwapLib {
    using PercentageUtils for uint256;

    /// STRUCTS

    /**
        @notice The parameters necessary for an input swap

        @custom:member inputToken The token in which `amountIn` is denominated
        @custom:member exactAmountIn The exact amount of `inputToken` that will be used for the swap
        @custom:member expectedAmountOut The expected amount of output tokens to be received without taking into account slippage
        @custom:member slippage The allowed slippage for the amount of output tokens, as a percentage with 6 decimal places
        @custom:member maxDuration The maximum duration of the swap in seconds, used to calculate the deadline from `now`
        @custom:member swapPath The abi-encoded path for the swap, coming from the Router helper
    */
    struct SwapInputParameters {
        address inputToken;
        uint256 exactAmountIn;
        uint256 expectedAmountOut;
        uint256 slippage;
        uint256 maxDuration;
        bytes swapPath;
    }

    /**
        @notice The parameters necessary for an output swap

        @custom:member inputToken The token in which `amountIn` is denominated
        @custom:member swapPath The abi-encoded path for the swap, coming from the Router helper
        @custom:member exactAmountOut The exact amount of the output token that will be obtained after the swap
        @custom:member expectedAmountIn The expected amount of input tokens to be used in the swap without taking into account slippage
        @custom:member slippage The allowed slippage for the amount of input tokens that will be used for the swap,
        as a percentage with 6 decimal places
        @custom:member maxDuration The maximum duration of the swap in seconds, used to calculate the deadline from `now`
    */
    struct SwapOutputParameters {
        address inputToken;
        uint256 exactAmountOut;
        uint256 expectedAmountIn;
        uint256 slippage;
        uint256 maxDuration;
        bytes swapPath;
    }

    /// CONSTANTS
    /**
        @notice Performs a multi-hop swap with an exact amount of input tokens and a variable amount
        of output tokens

        @param swapRouter The Uniswap V3 Router contract
        @param parameters The parameters necessary for the swap

        @dev The `swapPath` is a sequence of tokenAddress Fee tokenAddress, encoded in reverse order, which are the variables
        needed to compute each pool contract address in our sequence of swaps. The multihop swap router code will automatically
        find the correct pool with these variables, and execute the swap needed within each pool in our sequence. More
        information on [Multi-hop Swaps](https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps)
        

        @dev The slippage parameter is applied to the `expectedAmountOut` in order to account for slippage during the swap.
        In particular when swapping with `swapInput` the input amount of tokens is exact, and it is the output that can suffer from
        slippage. In such case the slippage is applied as the percentage that can be substracted from the ideal 100% that
         could be obtained at the output.

        @dev The `maxDuration` parameter is used to calculate the deadline from the current block timestamp
     */
    function swapInput(ISwapRouter swapRouter, SwapInputParameters memory parameters)
        internal
        returns (uint256 amountOut)
    {
        uint256 amountOutMinimum = parameters.expectedAmountOut.substractPercentage(parameters.slippage);

        TransferHelper.safeApprove(parameters.inputToken, address(swapRouter), parameters.exactAmountIn);

        ISwapRouter.ExactInputParams memory uniswapParams = ISwapRouter.ExactInputParams({
            path: parameters.swapPath,
            recipient: address(this),
            deadline: block.timestamp + parameters.maxDuration,
            amountIn: parameters.exactAmountIn,
            amountOutMinimum: amountOutMinimum
        });

        amountOut = swapRouter.exactInput(uniswapParams);
    }

    /**
        @notice Performs a multi-hop swap for an exact amount of output tokens and a variable amount
        of input tokens

        @param swapRouter The Uniswap V3 Router contract
        @param parameters The parameters necessary for the swap

        @dev The `swapPath` is a sequence of tokenAddress Fee tokenAddress, encoded in reverse order, which are the variables
        needed to compute each pool contract address in our sequence of swaps. The multihop swap router code will automatically
        find the correct pool with these variables, and execute the swap needed within each pool in our sequence. More
        information on [Multi-hop Swaps](https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps)

        @dev The slippage parameter is applied to the `expectedAmountIn` in order to account for slippage during the swap.
        In particular when swapping with `swapOutput` the output amount of tokens is exact, and it is the input that can
        suffer from slippage. In such case the slippage is applied as the percentage that can be added from the ideal 100% that
        could have been used for the input

        @dev The `maxDuration` parameter is used to calculate the deadline from the current block timestamp
     */
    function swapOutput(ISwapRouter swapRouter, SwapOutputParameters memory parameters)
        internal
        returns (uint256 amountIn)
    {
        uint256 amountInMaximum = parameters.expectedAmountIn.addPercentage(parameters.slippage);

        TransferHelper.safeApprove(parameters.inputToken, address(swapRouter), amountInMaximum);

        // The parameter path is encoded as (tokenOut, fee, tokenIn/tokenOut, fee, tokenIn)
        // The tokenIn/tokenOut field is the shared token between the two pools used in the multiple pool swap. In this case USDC is the "shared" token.
        // For an exactOutput swap, the first swap that occurs is the swap which returns the eventual desired token.
        // In this case, our desired output token is WETH9 so that swap happpens first, and is encoded in the path accordingly.
        ISwapRouter.ExactOutputParams memory params = ISwapRouter.ExactOutputParams({
            path: parameters.swapPath,
            recipient: address(this),
            deadline: block.timestamp + parameters.maxDuration,
            amountOut: parameters.exactAmountOut,
            amountInMaximum: amountInMaximum
        });

        // Executes the swap, returning the amountIn actually spent.
        amountIn = swapRouter.exactOutput(params);

        // If the input amount used was less than the expected maximum, approve the router for 0 tokens
        // to avoid allowing the router to transfer the remaining tokens
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(parameters.inputToken, address(swapRouter), 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**
    @title IUniswapV3Oracle

    @notice Oracle contract for Uniswap V3 swaps. It takes care of holding information about the
    path to use for a specific swap, and the expected price for a that swap.
 */
interface IUniswapV3Oracle {
    /**
        @notice The information required to perform a safe swap

        @custom:member inputToken The address of the input token in the swap
        @custom:member outputToken The address of the output token in the swap
        @custom:member expectedPriceRate The expected price of the swap as a fixed point SD59x18 number
        @custom:member swapPath The path to use for the swap as an ABI encoded array of bytes

        @dev See [Multi-hop Swaps](https://docs.uniswap.org/protocol/guides/swaps/multihop-swaps) for
        more information on the `swapPath` format
     */
    struct SwapInfo {
        address inputToken;
        address outputToken;
        uint256 expectedPriceRate;
        bytes swapPath;
    }

    /// FUNCTIONS

    /**
        @notice Sets the swap information for an input/output token pair. The information
        includes the swap path and the expected swap price

        @param info The swap information for the pair

        @dev Only the Keeper role can call this function

        @dev See { SwapInfo }
     */
    function setSwapInfo(SwapInfo calldata info) external;

    /**
        @notice Gets the swap information for the given input/output token pair

        @param inputToken The address of the input token in the swap
        @param outputToken The address of the output token in the swap

        @return The swap information for the pair

     */
    function getSwapInfo(address inputToken, address outputToken) external view returns (SwapInfo memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

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

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.14;

/**    
    @title IPotionBuyActionV0
        
    @author Roberto Cano <robercano>

    @notice Interface for the V0 of the Potion Buy Action
 */
interface IPotionBuyActionV0 {
    /// EVENTS
    event MaxPremiumPercentageChanged(uint256 maxPremiumPercentage);
    event PremiumSlippageChanged(uint256 premiumSlippage);
    event SwapSlippageChanged(uint256 swapSlippage);
    event MaxSwapDurationChanged(uint256 maxSwapDurationSecs);
    event CycleDurationChanged(uint256 cycleDurationSecs);
    event StrikePercentageChanged(uint256 strikePercentage);

    /// ERRORS
    error MaxPremiumPercentageOutOfRange(uint256 maxPremiumPercentage);
    error PremiumSlippageOutOfRange(uint256 premiumSlippage);
    error SwapSlippageOutOfRange(uint256 swapSlippage);
    error CycleDurationTooShort(uint256 cycleDurationSecs, uint256 minCycleDurationSecs);
    error StrikePercentageIsZero();

    /// SETTERS

    /**
        @notice Sets the new maximum percentage of the received loan that can be used as
        premium to buy potions

        @dev Reverts if the percentage is less than 0 or greater than 100
     */
    function setMaxPremiumPercentage(uint256 maxPremiumPercentage_) external;

    /**
        @notice Sets the new slippage allowed on the premium when the potions are bought

        @dev Reverts if the percentage is less than 0 or greater than 100
     */
    function setPremiumSlippage(uint256 premiumSlippage_) external;

    /**
        @notice Sets the new slippage allowed on Uniswap when the assets are swapped

        @dev Reverts if the percentage is less than 0 or greater than 100
     */
    function setSwapSlippage(uint256 swapSlippage_) external;

    /**
        @notice Sets the maximum duration in seconds for a Uniswap swap operation
     */
    function setMaxSwapDuration(uint256 durationSeconds) external;

    /**
        @notice Sets the investment cycle duration in seconds
     */
    function setCycleDuration(uint256 durationSeconds) external;

    /**
        @notice Sets strike percentage as a uint256 with `PercentageUtils.PERCENTAGE_DECIMALS` decimals
     */
    function setStrikePercentage(uint256 strikePercentage) external;

    /// GETTERS

    /**
        @notice Returns the calculated payout for the current block, and whether that payout is final or not

        @param investmentAsset The asset available to the action contract for the investment 
        
        @return isFinal Whether the payout is final or not. If the payout is final it won't change anymore. If it
                is not final it means that the potion has not expired yet and the payout may change in the future.
    */
    function calculateCurrentPayout(address investmentAsset) external view returns (bool isFinal, uint256 payout);
}