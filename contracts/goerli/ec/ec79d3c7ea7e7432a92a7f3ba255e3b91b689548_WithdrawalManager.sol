// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { ERC20Helper }           from "../modules/erc20-helper/src/ERC20Helper.sol";
import { IMapleProxyFactory }    from "../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";
import { MapleProxiedInternals } from "../modules/maple-proxy-factory/contracts/MapleProxiedInternals.sol";

import { IERC20Like, IMapleGlobalsLike, IPoolLike, IPoolManagerLike } from "./interfaces/Interfaces.sol";

import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";

import { WithdrawalManagerStorage } from "./WithdrawalManagerStorage.sol";

/*

    ██╗    ██╗██╗████████╗██╗  ██╗██████╗ ██████╗  █████╗ ██╗    ██╗ █████╗ ██╗
    ██║    ██║██║╚══██╔══╝██║  ██║██╔══██╗██╔══██╗██╔══██╗██║    ██║██╔══██╗██║
    ██║ █╗ ██║██║   ██║   ███████║██║  ██║██████╔╝███████║██║ █╗ ██║███████║██║
    ██║███╗██║██║   ██║   ██╔══██║██║  ██║██╔══██╗██╔══██║██║███╗██║██╔══██║██║
    ╚███╔███╔╝██║   ██║   ██║  ██║██████╔╝██║  ██║██║  ██║╚███╔███╔╝██║  ██║███████╗
    ╚══╝╚══╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚══════╝


    ███╗   ███╗ █████╗ ███╗   ██╗ █████╗  ██████╗ ███████╗██████╗
    ████╗ ████║██╔══██╗████╗  ██║██╔══██╗██╔════╝ ██╔════╝██╔══██╗
    ██╔████╔██║███████║██╔██╗ ██║███████║██║  ███╗█████╗  ██████╔╝
    ██║╚██╔╝██║██╔══██║██║╚██╗██║██╔══██║██║   ██║██╔══╝  ██╔══██╗
    ██║ ╚═╝ ██║██║  ██║██║ ╚████║██║  ██║╚██████╔╝███████╗██║  ██║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝

    * `cycleDuration` is the time of a full withdrawal cycle.
    *
    * |--------|--------|
    *     C1       C2
    *
    * There is a withdrawal window at the beginning of each withdrawal cycle.
    *
    * |===-----|===-----|
    *  WW1      WW2
    *
    * Once a user locks their shares, they must wait at least one full cycle from the end of the cycle they locked their shares in.
    * Users are only able to withdraw during a withdrawal window, which starts at the beginning of each cycle.
    *
    * |===-.---|===-----|===-----|
    *      ^             ^
    *  shares locked    earliest withdrawal time
    *
    * When the pool delegate changes the configuration, it will take effect only on the start of the third cycle.
    * This way all users that have already locked their shares will not have their withdrawal time affected.
    *
    *     C1       C2       C3             C4
    * |===--.--|===-----|===-----|==========----------|
    *       ^                     ^
    * configuration change     new configuration kicks in
    *
    * Users that request a withdrawal during C1 will withdraw during WW3 using the old configuration.
    * Users that lock their shares during and after C2 will withdraw in windows that use the new configuration.

*/

contract WithdrawalManager is IWithdrawalManager, WithdrawalManagerStorage, MapleProxiedInternals {

    /******************************************************************************************************************************/
    /*** Proxy Functions                                                                                                        ***/
    /******************************************************************************************************************************/

    function migrate(address migrator_, bytes calldata arguments_) external override {
        require(msg.sender == _factory(),        "WM:M:NOT_FACTORY");
        require(_migrate(migrator_, arguments_), "WM:M:FAILED");
    }

    function setImplementation(address implementation_) external override {
        require(msg.sender == _factory(), "WM:SI:NOT_FACTORY");
        _setImplementation(implementation_);
    }

    function upgrade(uint256 version_, bytes calldata arguments_) external override {
        address poolDelegate_ = poolDelegate();

        require(msg.sender == poolDelegate_ || msg.sender == governor(), "WM:U:NOT_AUTHORIZED");

        IMapleGlobalsLike mapleGlobals_ = IMapleGlobalsLike(globals());

        if (msg.sender == poolDelegate_) {
            require(mapleGlobals_.isValidScheduledCall(msg.sender, address(this), "WM:UPGRADE", msg.data), "WM:U:INVALID_SCHED_CALL");

            mapleGlobals_.unscheduleCall(msg.sender, "WM:UPGRADE", msg.data);
        }

        IMapleProxyFactory(_factory()).upgradeInstance(version_, arguments_);
    }

    /******************************************************************************************************************************/
    /*** Administrative Functions                                                                                               ***/
    /******************************************************************************************************************************/

    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external override {
        CycleConfig memory config_ = getCurrentConfig();

        require(msg.sender == poolDelegate(),      "WM:SEC:NOT_AUTHORIZED");
        require(windowDuration_ != 0,              "WM:SEC:ZERO_WINDOW");
        require(windowDuration_ <= cycleDuration_, "WM:SEC:WINDOW_OOB");

        require(
            cycleDuration_  != config_.cycleDuration ||
            windowDuration_ != config_.windowDuration,
            "WM:SEC:IDENTICAL_CONFIG"
        );

        // The new config will take effect only after the current cycle and two additional ones elapse.
        // This is done in order to to prevent overlaps between the current and new withdrawal cycles.
        uint256 currentCycleId_   = getCurrentCycleId();
        uint256 initialCycleId_   = currentCycleId_ + 3;
        uint256 initialCycleTime_ = getWindowStart(currentCycleId_) + 3 * config_.cycleDuration;
        uint256 latestConfigId_   = latestConfigId;

        // If the new config takes effect on the same cycle as the latest config, overwrite it. Otherwise create a new config.
        if (initialCycleId_ != cycleConfigs[latestConfigId_].initialCycleId) {
            latestConfigId_ = ++latestConfigId;
        }

        cycleConfigs[latestConfigId_] = CycleConfig({
            initialCycleId:   _uint64(initialCycleId_),
            initialCycleTime: _uint64(initialCycleTime_),
            cycleDuration:    _uint64(cycleDuration_),
            windowDuration:   _uint64(windowDuration_)
        });

        emit ConfigurationUpdated({
            configId_:         latestConfigId_,
            initialCycleId_:   _uint64(initialCycleId_),
            initialCycleTime_: _uint64(initialCycleTime_),
            cycleDuration_:    _uint64(cycleDuration_),
            windowDuration_:   _uint64(windowDuration_)
        });
    }

    /******************************************************************************************************************************/
    /*** Exit Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    function addShares(uint256 shares_, address owner_) external override {
        require(msg.sender == poolManager, "WM:AS:NOT_POOL_MANAGER");

        uint256 exitCycleId_  = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        require(lockedShares_ == 0 || block.timestamp >= getWindowStart(exitCycleId_), "WM:AS:WITHDRAWAL_PENDING");

        // Remove all existing shares from the current cycle.
        totalCycleShares[exitCycleId_] -= lockedShares_;

        lockedShares_ += shares_;

        require(lockedShares_ != 0, "WM:AS:NO_OP");

        // Move all shares (including any new ones) to the new cycle.
        exitCycleId_ = getCurrentCycleId() + 2;
        totalCycleShares[exitCycleId_] += lockedShares_;

        exitCycleId[owner_]  = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        require(ERC20Helper.transferFrom(pool, msg.sender, address(this), shares_), "WM:AS:TRANSFER_FROM_FAIL");

        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    function removeShares(uint256 shares_, address owner_) external override returns (uint256 sharesReturned_) {
        require(msg.sender == poolManager, "WM:RS:NOT_POOL_MANAGER");

        uint256 exitCycleId_  = exitCycleId[owner_];
        uint256 lockedShares_ = lockedShares[owner_];

        require(block.timestamp >= getWindowStart(exitCycleId_), "WM:RS:WITHDRAWAL_PENDING");
        require(shares_ != 0 && shares_ <= lockedShares_,        "WM:RS:SHARES_OOB");

        // Remove shares from old the cycle.
        totalCycleShares[exitCycleId_] -= lockedShares_;

        // Calculate remaining shares and new cycle (if applicable).
        lockedShares_ -= shares_;
        exitCycleId_   = lockedShares_ != 0 ? getCurrentCycleId() + 2 : 0;

        // Add shares to new cycle (if applicable).
        if (lockedShares_ != 0) {
            totalCycleShares[exitCycleId_] += lockedShares_;
        }

        // Update the withdrawal request.
        exitCycleId[owner_]  = exitCycleId_;
        lockedShares[owner_] = lockedShares_;

        sharesReturned_ = shares_;

        require(ERC20Helper.transfer(pool, owner_, shares_), "WM:RS:TRANSFER_FAIL");

        _emitUpdate(owner_, lockedShares_, exitCycleId_);
    }

    function processExit(address account_, uint256 requestedShares_) external override returns (uint256 redeemableShares_, uint256 resultingAssets_) {
        require(msg.sender == poolManager, "WM:PE:NOT_PM");

        uint256 exitCycleId_  = exitCycleId[account_];
        uint256 lockedShares_ = lockedShares[account_];

        require(requestedShares_ == lockedShares_, "WM:PE:INVALID_SHARES");

        bool partialLiquidity_;

        ( redeemableShares_, resultingAssets_, partialLiquidity_ ) = _previewRedeem(account_, lockedShares_, exitCycleId_);

        // Transfer both returned shares and redeemable shares, burn only the redeemable shares in the pool.
        require(ERC20Helper.transfer(pool, account_, redeemableShares_), "WM:PE:TRANSFER_FAIL");

        // Reduce totalCurrentShares by the shares that were used in the old cycle.
        totalCycleShares[exitCycleId_] -= lockedShares_;

        // Reduce the locked shares by the total amount transferred back to the LP.
        lockedShares_ -= redeemableShares_;

        // If there are any remaining shares, move them to the next cycle.
        // In case of partial liquidity move shares only one cycle forward (instead of two).
        if (lockedShares_ != 0) {
            exitCycleId_ = getCurrentCycleId() + (partialLiquidity_ ? 1 : 2);
            totalCycleShares[exitCycleId_] += lockedShares_;
        } else {
            exitCycleId_ = 0;
        }

        // Update the locked shares and cycle for the account, setting to zero if no shares are remaining.
        lockedShares[account_] = lockedShares_;
        exitCycleId[account_]  = exitCycleId_;

        _emitProcess(account_, redeemableShares_, resultingAssets_);
        _emitUpdate(account_, lockedShares_, exitCycleId_);
    }

    /******************************************************************************************************************************/
    /*** External View Utility Functions                                                                                        ***/
    /******************************************************************************************************************************/

    function isInExitWindow(address owner_) external view override returns (bool isInExitWindow_) {
        uint256 exitCycleId_ = exitCycleId[owner_];

        if (exitCycleId_ == 0) return false; // No withdrawal request

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        isInExitWindow_ = block.timestamp >= windowStart_ && block.timestamp <  windowEnd_;
    }

    function lockedLiquidity() external view override returns (uint256 lockedLiquidity_) {
        uint256 currentCycleId_ = getCurrentCycleId();

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(currentCycleId_);

        if (block.timestamp >= windowStart_ && block.timestamp < windowEnd_) {
            IPoolManagerLike poolManager_ = IPoolManagerLike(poolManager);

            uint256 totalAssetsWithLosses_ = poolManager_.totalAssets() - poolManager_.unrealizedLosses();
            uint256 totalSupply_           = IPoolLike(pool).totalSupply();

            lockedLiquidity_ = totalCycleShares[currentCycleId_] * totalAssetsWithLosses_ / totalSupply_;
        }
    }

    function previewRedeem(address owner_, uint256 shares_) external view override returns (uint256 redeemableShares_, uint256 resultingAssets_) {
        uint256 exitCycleId_ = exitCycleId[owner_];

        require(shares_ == lockedShares[owner_], "WM:PR:INVALID_SHARES");

        ( redeemableShares_, resultingAssets_, ) = _previewRedeem(owner_, shares_, exitCycleId_);
    }

    /******************************************************************************************************************************/
    /*** Public View Utility Functions                                                                                          ***/
    /******************************************************************************************************************************/

    function getConfigAtId(uint256 cycleId_) public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        if (configId_ == 0) return cycleConfigs[configId_];

        while (cycleId_ < cycleConfigs[configId_].initialCycleId) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    function getCurrentConfig() public view override returns (CycleConfig memory config_) {
        uint256 configId_ = latestConfigId;

        while (block.timestamp < cycleConfigs[configId_].initialCycleTime) {
            --configId_;
        }

        config_ = cycleConfigs[configId_];
    }

    function getCurrentCycleId() public view override returns (uint256 cycleId_) {
        CycleConfig memory config_ = getCurrentConfig();

        cycleId_ = config_.initialCycleId + (block.timestamp - config_.initialCycleTime) / config_.cycleDuration;
    }

    function getRedeemableAmounts(uint256 lockedShares_, address owner_) public view override returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_) {
        IPoolManagerLike poolManager_ = IPoolManagerLike(poolManager);

        // Calculate how much liquidity is available, and how much is required to allow redemption of shares.
        uint256 availableLiquidity_      = IERC20Like(asset()).balanceOf(pool);
        uint256 totalAssetsWithLosses_   = poolManager_.totalAssets() - poolManager_.unrealizedLosses();
        uint256 totalSupply_             = IPoolLike(pool).totalSupply();
        uint256 totalRequestedLiquidity_ = totalCycleShares[exitCycleId[owner_]] * totalAssetsWithLosses_ / totalSupply_;

        partialLiquidity_ = availableLiquidity_ < totalRequestedLiquidity_;

        // Calculate maximum redeemable shares while maintaining a pro-rata distribution.
        redeemableShares_ =
            partialLiquidity_
                ? lockedShares_ * availableLiquidity_ / totalRequestedLiquidity_
                : lockedShares_;

        resultingAssets_ = totalAssetsWithLosses_ * redeemableShares_ / totalSupply_;
    }

    function getWindowStart(uint256 cycleId_) public view override returns (uint256 windowStart_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + (cycleId_ - config_.initialCycleId) * config_.cycleDuration;
    }

    function getWindowAtId(uint256 cycleId_) public view override returns (uint256 windowStart_, uint256 windowEnd_) {
        CycleConfig memory config_ = getConfigAtId(cycleId_);

        windowStart_ = config_.initialCycleTime + (cycleId_ - config_.initialCycleId) * config_.cycleDuration;
        windowEnd_   = windowStart_ + config_.windowDuration;
    }

    /******************************************************************************************************************************/
    /*** Internal View Utility Functions                                                                                        ***/
    /******************************************************************************************************************************/

    function _previewRedeem(
        address owner_,
        uint256 lockedShares_,
        uint256 exitCycleId_
    )
        internal view returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_)
    {
        require(lockedShares_ != 0, "WM:PR:NO_REQUEST");

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        require(block.timestamp >= windowStart_ && block.timestamp <  windowEnd_, "WM:PR:NOT_IN_WINDOW");

        ( redeemableShares_, resultingAssets_, partialLiquidity_ ) = getRedeemableAmounts(lockedShares_, owner_);
    }

    /******************************************************************************************************************************/
    /*** Address View Functions                                                                                                 ***/
    /******************************************************************************************************************************/

    function asset() public view override returns (address asset_) {
        asset_ = IPoolLike(pool).asset();
    }

    function factory() external view override returns (address factory_) {
        factory_ = _factory();
    }

    function globals() public view override returns (address globals_) {
        globals_ = IMapleProxyFactory(_factory()).mapleGlobals();
    }

    function governor() public view override returns (address governor_) {
        governor_ = IMapleGlobalsLike(globals()).governor();
    }

    function implementation() external view override returns (address implementation_) {
        implementation_ = _implementation();
    }

    function poolDelegate() public view override returns (address poolDelegate_) {
        poolDelegate_ = IPoolManagerLike(poolManager).poolDelegate();
    }

    function previewWithdraw(address owner_, uint256 assets_) external pure override returns (uint256 redeemableAssets_, uint256 resultingShares_) {
        owner_; assets_; redeemableAssets_; resultingShares_;  // Silence compiler warnings
        require(false, "WM:PW:NOT_ENABLED");
    }

    /******************************************************************************************************************************/
    /*** Helper Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    function _emitProcess(address account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_) internal {
        if (sharesToRedeem_ == 0) {
            return;
        }

        emit WithdrawalProcessed(account_, sharesToRedeem_, assetsToWithdraw_);
    }

    function _emitUpdate(address account_, uint256 lockedShares_, uint256 exitCycleId_) internal {
        if (lockedShares_ == 0) {
            emit WithdrawalCancelled(account_);
            return;
        }

        ( uint256 windowStart_, uint256 windowEnd_ ) = getWindowAtId(exitCycleId_);

        emit WithdrawalUpdated(account_, lockedShares_, _uint64(windowStart_), _uint64(windowEnd_));
    }

    function _uint64(uint256 input_) internal pure returns (uint64 output_) {
        require(input_ <= type(uint64).max, "WM:UINT64_CAST_OOB");
        output_ = uint64(input_);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IWithdrawalManagerEvents }  from "./interfaces/IWithdrawalManagerEvents.sol";
import { IWithdrawalManagerStorage } from "./interfaces/IWithdrawalManagerStorage.sol";

abstract contract WithdrawalManagerStorage is IWithdrawalManagerStorage, IWithdrawalManagerEvents {

    address public override pool;
    address public override poolManager;

    uint256 public override latestConfigId;

    mapping(address => uint256) public override exitCycleId;
    mapping(address => uint256) public override lockedShares;

    mapping(uint256 => uint256) public override totalCycleShares;

    mapping(uint256 => CycleConfig) public override cycleConfigs;

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import { IMapleProxied } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxied.sol";

import { IWithdrawalManagerStorage } from "./IWithdrawalManagerStorage.sol";

interface IWithdrawalManager is IMapleProxied, IWithdrawalManagerStorage {

    /******************************************************************************************************************************/
    /*** State Changing Functions                                                                                               ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Add shares to the withdrawal manager.
     *  @param shares_ Amount of shares to add.
     *  @param owner_  Address of the owner of shares.
     */
    function addShares(uint256 shares_, address owner_) external;

    /**
     *  @dev   Process the exit of an account.
     *  @param account_         Address of the account process exit from.
     *  @param requestedShares_ Amount of initially requested shares.
     */
    function processExit(address account_, uint256 requestedShares_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev   Remove shares to the withdrawal manager.
     *  @param shares_ Amount of shares to remove.
     *  @param owner_  Address of the owner of shares.
     */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /**
     *  @dev   Sets up a new exit configuration.
     *  @param cycleDuration_  The total duration, in seconds, of a withdrawal cycle.
     *  @param windowDuration_ The duration, in seconds, of the withdrawal window.
     */
    function setExitConfig(uint256 cycleDuration_, uint256 windowDuration_) external;

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Gets the asset address used in this withdrawal manager.
     *  @return asset_ Address of the asset.
     */
    function asset() external view returns (address asset_);

    /**
     *  @dev    Gets the configuration of a given cycle id.
     *  @param  cycleId_  The id of the cycle.
     *  @return config_ The configuration info corresponding to the cycle.
     */
    function getConfigAtId(uint256 cycleId_) external view returns (CycleConfig memory config_);

    /**
     *  @dev    Gets the configuration of the current cycle id.
     *  @return config_ The configuration info corresponding to the cycle.
     */
    function getCurrentConfig() external view returns (CycleConfig memory config_);

    /**
     *  @dev   Gets the id of the current cycle.
     *  @param cycleId_ The id of the current cycle.
     */
    function getCurrentCycleId() external view returns (uint256 cycleId_);

    /**
     *  @dev    Gets the shares and assets that are redeemable for a given user.
     *  @param  lockedShares_     The amount of shares that are locked.
     *  @param  owner_            The owner of the shares.
     *  @return redeemableShares_ The amount of shares that are redeemable based on current liquidity.
     *  @return resultingAssets_  The corresponding amount of assets that can be redeemed using the shares.
     *  @return partialLiquidity_ Boolean indicating if there is enough liquidity to facilitate a full redemption.
     */
    function getRedeemableAmounts(uint256 lockedShares_, address owner_) external view returns (uint256 redeemableShares_, uint256 resultingAssets_, bool partialLiquidity_);

    /**
     *  @dev    Gets the timestamp of the beginning of the withdrawal window for a given cycle.
     *  @param  cycleId_     The id of the current cycle.
     *  @return windowStart_ The timestamp of the beginning of the cycle, which is the same as the beginning of the withdrawal window.
     */
    function getWindowStart(uint256 cycleId_) external view returns (uint256 windowStart_);

    /**
     *  @dev    Gets the timestamps of the beginning and end of the withdrawal window for a given cycle.
     *  @param  cycleId_     The id of the current cycle.
     *  @return windowStart_ The timestamp of the beginning of the cycle, which is the same as the beginning of the withdrawal window.
     *  @return windowEnd_   The timestamp of the end of the withdrawal window.
     */
    function getWindowAtId(uint256 cycleId_) external view returns (uint256 windowStart_, uint256 windowEnd_);

    /**
     *  @dev    Gets the address of globals.
     *  @return globals_ The address of globals.
     */
    function globals() external view returns (address globals_);

    /**
     *  @dev    Gets the address of the governor.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
     *  @dev    Checks if an account is included in an exit window.
     *  @param  owner_          The address of the share owners to check.
     *  @return isInExitWindow_ A boolean indicating whether or not the account is in an exit window.
     */
    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    /**
     *  @dev    Gets the total amount of funds that need to be locked to fulfill exits.
     *  @return lockedLiquidity_ The amount of locked liquidity.
     */
    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    /**
     *  @dev    Gets the pool delegate address.
     *  @return poolDelegate_ Address of the pool delegate.
     */
    function poolDelegate() external view returns (address poolDelegate_);

    /**
     *  @dev    Gets the amount of shares that can be redeemed.
     *  @param  owner_            The address to check the redemption for.
     *  @param  shares_           The amount of requested shares to redeem.
     *  @return redeemableShares_ The amount of shares that can be redeemed.
     *  @return resultingAssets_  The amount of assets that will be returned for `redeemableShares`.
     */
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /**
     *  @dev    Gets the amount of shares that can be withdrawn.
     *  @param  owner_            The address to check the withdrawal for.
     *  @param  assets_           The amount of requested shares to withdraw.
     *  @return redeemableAssets_ The amount of assets that can be withdrawn.
     *  @return resultingShares_  The amount of shares that will be burned.
     */
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

interface IWithdrawalManagerEvents {

    /**
     *  @dev   Emitted when the withdrawal configuration is updated.
     *  @param configId_         The identifier of the configuration.
     *  @param initialCycleId_   The identifier of the withdrawal cycle when the configuration takes effect.
     *  @param initialCycleTime_ The timestamp of the beginning of the withdrawal cycle when the configuration takes effect.
     *  @param cycleDuration_    The new duration of the withdrawal cycle.
     *  @param windowDuration_   The new duration of the withdrawal window.
     */
    event ConfigurationUpdated(uint256 indexed configId_, uint64 initialCycleId_, uint64 initialCycleTime_, uint64 cycleDuration_, uint64 windowDuration_);

    /**
     *  @dev   Emitted when a withdrawal request is cancelled.
     *  @param account_ Address of the account whose withdrawal request has been cancelled.
     */
    event WithdrawalCancelled(address indexed account_);

    /**
     *  @dev   Emitted when a withdrawal request is processed.
     *  @param account_          Address of the account processing their withdrawal request.
     *  @param sharesToRedeem_   Amount of shares that the account will redeem.
     *  @param assetsToWithdraw_ Amount of assets that will be withdrawn from the pool.
     */
    event WithdrawalProcessed(address indexed account_, uint256 sharesToRedeem_, uint256 assetsToWithdraw_);

    /**
     *  @dev   Emitted when a withdrawal request is updated.
     *  @param account_      Address of the account whose request has been updated.
     *  @param lockedShares_ Total amount of shares the account has locked.
     *  @param windowStart_  Time when the withdrawal window for the withdrawal request will begin.
     *  @param windowEnd_    Time when the withdrawal window for the withdrawal request will end.
     */
    event WithdrawalUpdated(address indexed account_, uint256 lockedShares_, uint64 windowStart_, uint64 windowEnd_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

interface IWithdrawalManagerStorage {

    struct CycleConfig {
        uint64 initialCycleId;    // Identifier of the first withdrawal cycle using this configuration.
        uint64 initialCycleTime;  // Timestamp of the first withdrawal cycle using this configuration.
        uint64 cycleDuration;     // Duration of the withdrawal cycle.
        uint64 windowDuration;    // Duration of the withdrawal window.
    }

    /**
     *  @dev    Gets the configuration for a given config id.
     *  @param  configId_        The id of the configuration to use.
     *  @return initialCycleId   Identifier of the first withdrawal cycle using this configuration.
     *  @return initialCycleTime Timestamp of the first withdrawal cycle using this configuration.
     *  @return cycleDuration    Duration of the withdrawal cycle.
     *  @return windowDuration   Duration of the withdrawal window.
     */
    function cycleConfigs(uint256 configId_) external returns (uint64 initialCycleId, uint64 initialCycleTime, uint64 cycleDuration, uint64 windowDuration);

    /**
     *  @dev    Gets the id of the cycle that account can exit on.
     *  @param  account_ The address to check the exit for.
     *  @return cycleId_ The id of the cycle that account can exit on.
     */
    function exitCycleId(address account_) external view returns (uint256 cycleId_);

    /**
     *  @dev    Gets the most recent configuration id.
     *  @return configId_ The id of the mostrecent configuration.
     */
    function latestConfigId() external view returns (uint256 configId_);

    /**
     *  @dev    Gets the amount of locked shares for an account.
     *  @param  account_      The address to check the exit for.
     *  @return lockedShares_ The amount of shares locked.
     */
    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    /**
     *  @dev    Gets the address of the pool associated with this withdrawal manager.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

    /**
     *  @dev    Gets the address of the pool manager associated with this withdrawal manager.
     *  @return poolManager_ The address of the pool manager.
     */
    function poolManager() external view returns (address poolManager_);

    /**
     *  @dev    Gets the amount of shares for a cycle.
     *  @param  cycleId_          The id to cycle to check.
     *  @return totalCycleShares_ The amount of shares in the cycle.
     */
    function totalCycleShares(uint256 cycleId_) external view returns (uint256 totalCycleShares_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

interface IMapleGlobalsLike {

    function governor() external view returns (address governor_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

}

interface IPoolLike {

    function asset() external view returns (address asset_);

    function convertToShares(uint256 assets_) external view returns (uint256 shares_);

    function manager() external view returns (address manager_);

    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    function totalSupply() external view returns (uint256 totalSupply_);

    function transfer(address account_, uint256 amount_) external returns (bool success_);

}

interface IPoolManagerLike {

    function globals() external view returns (address globals_);

    function poolDelegate() external view returns (address poolDelegate_);

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20Like } from "./interfaces/IERC20Like.sol";

/**
 * @title Small Library to standardize erc20 token interactions.
 */
library ERC20Helper {

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function transfer(address token_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transfer.selector, to_, amount_));
    }

    function transferFrom(address token_, address from_, address to_, uint256 amount_) internal returns (bool success_) {
        return _call(token_, abi.encodeWithSelector(IERC20Like.transferFrom.selector, from_, to_, amount_));
    }

    function approve(address token_, address spender_, uint256 amount_) internal returns (bool success_) {
        // If setting approval to zero fails, return false.
        if (!_call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, uint256(0)))) return false;

        // If `amount_` is zero, return true as the previous step already did this.
        if (amount_ == uint256(0)) return true;

        // Return the result of setting the approval to `amount_`.
        return _call(token_, abi.encodeWithSelector(IERC20Like.approve.selector, spender_, amount_));
    }

    function _call(address token_, bytes memory data_) private returns (bool success_) {
        if (token_.code.length == uint256(0)) return false;

        bytes memory returnData;
        ( success_, returnData ) = token_.call(data_);

        return success_ && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as needed by ERC20Helper.
interface IERC20Like {

    function approve(address spender_, uint256 amount_) external returns (bool success_);

    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { ProxiedInternals } from "../modules/proxy-factory/contracts/ProxiedInternals.sol";

/// @title A Maple implementation that is to be proxied, will need MapleProxiedInternals.
abstract contract MapleProxiedInternals is ProxiedInternals { }

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IProxied } from "../../modules/proxy-factory/contracts/interfaces/IProxied.sol";

/// @title A Maple implementation that is to be proxied, must implement IMapleProxied.
interface IMapleProxied is IProxied {

    /**
     *  @dev   The instance was upgraded.
     *  @param toVersion_ The new version of the loan.
     *  @param arguments_ The upgrade arguments, if any.
     */
    event Upgraded(uint256 toVersion_, bytes arguments_);

    /**
     *  @dev   Upgrades a contract implementation to a specific version.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param toVersion_ The version to upgrade to.
     *  @param arguments_ Some encoded arguments to use for the upgrade.
     */
    function upgrade(uint256 toVersion_, bytes calldata arguments_) external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IDefaultImplementationBeacon } from "../../modules/proxy-factory/contracts/interfaces/IDefaultImplementationBeacon.sol";

/// @title A Maple factory for Proxy contracts that proxy MapleProxied implementations.
interface IMapleProxyFactory is IDefaultImplementationBeacon {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                  ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   A default version was set.
     *  @param version_ The default version.
     */
    event DefaultVersionSet(uint256 indexed version_);

    /**
     *  @dev   A version of an implementation, at some address, was registered, with an optional initializer.
     *  @param version_               The version registered.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    event ImplementationRegistered(uint256 indexed version_, address indexed implementationAddress_, address indexed initializer_);

    /**
     *  @dev   A proxy contract was deployed with some initialization arguments.
     *  @param version_                 The version of the implementation being proxied by the deployed proxy contract.
     *  @param instance_                The address of the proxy contract deployed.
     *  @param initializationArguments_ The arguments used to initialize the proxy contract, if any.
     */
    event InstanceDeployed(uint256 indexed version_, address indexed instance_, bytes initializationArguments_);

    /**
     *  @dev   A instance has upgraded by proxying to a new implementation, with some migration arguments.
     *  @param instance_           The address of the proxy contract.
     *  @param fromVersion_        The initial implementation version being proxied.
     *  @param toVersion_          The new implementation version being proxied.
     *  @param migrationArguments_ The arguments used to migrate, if any.
     */
    event InstanceUpgraded(address indexed instance_, uint256 indexed fromVersion_, uint256 indexed toVersion_, bytes migrationArguments_);

    /**
     *  @dev   The MapleGlobals was set.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    event MapleGlobalsSet(address indexed mapleGlobals_);

    /**
     *  @dev   An upgrade path was disabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    event UpgradePathDisabled(uint256 indexed fromVersion_, uint256 indexed toVersion_);

    /**
     *  @dev   An upgrade path was enabled, with an optional migrator contract.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    event UpgradePathEnabled(uint256 indexed fromVersion_, uint256 indexed toVersion_, address indexed migrator_);

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev The default version.
     */
    function defaultVersion() external view returns (uint256 defaultVersion_);

    /**
     *  @dev The address of the MapleGlobals contract.
     */
    function mapleGlobals() external view returns (address mapleGlobals_);

    /**
     *  @dev    Whether the upgrade is enabled for a path from a version to another version.
     *  @param  toVersion_   The initial version.
     *  @param  fromVersion_ The destination version.
     *  @return allowed_     Whether the upgrade is enabled.
     */
    function upgradeEnabledForPath(uint256 toVersion_, uint256 fromVersion_) external view returns (bool allowed_);

    /******************************************************************************************************************************/
    /*** State Changing Functions                                                                                               ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Deploys a new instance proxying the default implementation version, with some initialization arguments.
     *          Uses a nonce and `msg.sender` as a salt for the CREATE2 opcode during instantiation to produce deterministic addresses.
     *  @param  arguments_ The initialization arguments to use for the instance deployment, if any.
     *  @param  salt_      The salt to use in the contract creation process.
     *  @return instance_  The address of the deployed proxy contract.
     */
    function createInstance(bytes calldata arguments_, bytes32 salt_) external returns (address instance_);

    /**
     *  @dev   Enables upgrading from a version to a version of an implementation, with an optional migrator.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     *  @param migrator_    The address of the migrator, if any.
     */
    function enableUpgradePath(uint256 fromVersion_, uint256 toVersion_, address migrator_) external;

    /**
     *  @dev   Disables upgrading from a version to a version of a implementation.
     *         Only the Governor can call this function.
     *  @param fromVersion_ The starting version of the upgrade path.
     *  @param toVersion_   The destination version of the upgrade path.
     */
    function disableUpgradePath(uint256 fromVersion_, uint256 toVersion_) external;

    /**
     *  @dev   Registers the address of an implementation contract as a version, with an optional initializer.
     *         Only the Governor can call this function.
     *  @param version_               The version to register.
     *  @param implementationAddress_ The address of the implementation.
     *  @param initializer_           The address of the initializer, if any.
     */
    function registerImplementation(uint256 version_, address implementationAddress_, address initializer_) external;

    /**
     *  @dev   Sets the default version.
     *         Only the Governor can call this function.
     *  @param version_ The implementation version to set as the default.
     */
    function setDefaultVersion(uint256 version_) external;

    /**
     *  @dev   Sets the Maple Globals contract.
     *         Only the Governor can call this function.
     *  @param mapleGlobals_ The address of a Maple Globals contract.
     */
    function setGlobals(address mapleGlobals_) external;

    /**
     *  @dev   Upgrades the calling proxy contract's implementation, with some migration arguments.
     *  @param toVersion_ The implementation version to upgrade the proxy contract to.
     *  @param arguments_ The migration arguments, if any.
     */
    function upgradeInstance(uint256 toVersion_, bytes calldata arguments_) external;

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Returns the deterministic address of a potential proxy, given some arguments and salt.
     *  @param  arguments_       The initialization arguments to be used when deploying the proxy.
     *  @param  salt_            The salt to be used when deploying the proxy.
     *  @return instanceAddress_ The deterministic address of a potential proxy.
     */
    function getInstanceAddress(bytes calldata arguments_, bytes32 salt_) external view returns (address instanceAddress_);

    /**
     *  @dev    Returns the address of an implementation version.
     *  @param  version_        The implementation version.
     *  @return implementation_ The address of the implementation.
     */
    function implementationOf(uint256 version_) external view returns (address implementation_);

    /**
     *  @dev    Returns if a given address has been deployed by this factory/
     *  @param  instance_   The address to check.
     *  @return isInstance_ A boolean indication if the address has been deployed by this factory.
     */
    function isInstance(address instance_) external view returns (bool isInstance_);

    /**
     *  @dev    Returns the address of a migrator contract for a migration path (from version, to version).
     *          If oldVersion_ == newVersion_, the migrator is an initializer.
     *  @param  oldVersion_ The old version.
     *  @param  newVersion_ The new version.
     *  @return migrator_   The address of a migrator contract.
     */
    function migratorForPath(uint256 oldVersion_, uint256 newVersion_) external view returns (address migrator_);

    /**
     *  @dev    Returns the version of an implementation contract.
     *  @param  implementation_ The address of an implementation contract.
     *  @return version_        The version of the implementation contract.
     */
    function versionOf(address implementation_) external view returns (uint256 version_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { SlotManipulatable } from "./SlotManipulatable.sol";

/// @title An implementation that is to be proxied, will need ProxiedInternals.
abstract contract ProxiedInternals is SlotManipulatable {

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.factory') - 1`.
    bytes32 private constant FACTORY_SLOT = bytes32(0x7a45a402e4cb6e08ebc196f20f66d5d30e67285a2a8aa80503fa409e727a4af1);

    /// @dev Storage slot with the address of the current factory. `keccak256('eip1967.proxy.implementation') - 1`.
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc);

    /// @dev Delegatecalls to a migrator contract to manipulate storage during an initialization or migration.
    function _migrate(address migrator_, bytes calldata arguments_) internal virtual returns (bool success_) {
        uint256 size;

        assembly {
            size := extcodesize(migrator_)
        }

        if (size == uint256(0)) return false;

        ( success_, ) = migrator_.delegatecall(arguments_);
    }

    /// @dev Sets the factory address in storage.
    function _setFactory(address factory_) internal virtual returns (bool success_) {
        _setSlotValue(FACTORY_SLOT, bytes32(uint256(uint160(factory_))));
        return true;
    }

    /// @dev Sets the implementation address in storage.
    function _setImplementation(address implementation_) internal virtual returns (bool success_) {
        _setSlotValue(IMPLEMENTATION_SLOT, bytes32(uint256(uint160(implementation_))));
        return true;
    }

    /// @dev Returns the factory address.
    function _factory() internal view virtual returns (address factory_) {
        return address(uint160(uint256(_getSlotValue(FACTORY_SLOT))));
    }

    /// @dev Returns the implementation address.
    function _implementation() internal view virtual returns (address implementation_) {
        return address(uint160(uint256(_getSlotValue(IMPLEMENTATION_SLOT))));
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

abstract contract SlotManipulatable {

    function _getReferenceTypeSlot(bytes32 slot_, bytes32 key_) internal pure returns (bytes32 value_) {
        return keccak256(abi.encodePacked(key_, slot_));
    }

    function _getSlotValue(bytes32 slot_) internal view returns (bytes32 value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

    function _setSlotValue(bytes32 slot_, bytes32 value_) internal {
        assembly {
            sstore(slot_, value_)
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An beacon that provides a default implementation for proxies, must implement IDefaultImplementationBeacon.
interface IDefaultImplementationBeacon {

    /// @dev The address of an implementation for proxies.
    function defaultImplementation() external view returns (address defaultImplementation_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title An implementation that is to be proxied, must implement IProxied.
interface IProxied {

    /**
     *  @dev The address of the proxy factory.
     */
    function factory() external view returns (address factory_);

    /**
     *  @dev The address of the implementation contract being proxied.
     */
    function implementation() external view returns (address implementation_);

    /**
     *  @dev   Modifies the proxy's implementation address.
     *  @param newImplementation_ The address of an implementation contract.
     */
    function setImplementation(address newImplementation_) external;

    /**
     *  @dev   Modifies the proxy's storage by delegate-calling a migrator contract with some arguments.
     *         Access control logic critical since caller can force a selfdestruct via a malicious `migrator_` which is delegatecalled.
     *  @param migrator_  The address of a migrator contract.
     *  @param arguments_ Some encoded arguments to use for the migration.
     */
    function migrate(address migrator_, bytes calldata arguments_) external;

}