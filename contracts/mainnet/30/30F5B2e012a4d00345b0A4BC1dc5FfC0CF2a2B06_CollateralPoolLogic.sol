// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/IUserData.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./HelpersLogic.sol";
import "./ValidationLogic.sol";
import "./CollateralLogic.sol";
import "./ReserveLogic.sol";
import "../storage/LedgerStorage.sol";

library CollateralPoolLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 2;

    event DepositedCollateral(address user, address asset, address reinvestment, uint256 amount);
    event WithdrawnCollateral(address user, address asset, address reinvestment, uint256 amount);
    event EmergencyWithdrawnCollateral(address asset, address reinvestment, uint256 supply);
    event ReinvestedCollateralSupply(address asset, address reinvestment, uint256 supply);

    function executeDepositCollateral(
        address user,
        address asset,
        address reinvestment,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        uint256 currCollateralSupply = localCollateral.getCollateralSupply();
        uint256 currUserCollateralBalance = IUserData(protocolConfig.userData).getUserCollateralInternal(
            user, pid, currCollateralSupply, assetConfig.decimals
        );

        ValidationLogic.validateDepositCollateral(localCollateral, userLastTradeBlock, amount, currUserCollateralBalance);

        IUserData(protocolConfig.userData).depositCollateral(user, pid, amount, assetConfig.decimals, currCollateralSupply);

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        if (reinvestment != address(0)) {
            HelpersLogic.approveMax(asset, reinvestment, amount);

            IReinvestment(reinvestment).checkpoint(user, currUserCollateralBalance);
            IReinvestment(reinvestment).invest(amount);
        } else {
            collateral.liquidSupply += amount;
        }

        emit DepositedCollateral(user, asset, reinvestment, amount);
    }

    struct ExecuteWithdrawVars {
        DataTypes.CollateralData collateralCache;
        uint256 currCollateralSupply;
        uint256 currUserCollateralBalance;
        uint256 maxAmountToWithdraw;
        uint256 feeAmount;
    }

    function executeWithdrawCollateral(
        address user,
        address asset,
        address reinvestment,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        ExecuteWithdrawVars memory vars;

        vars.currCollateralSupply = localCollateral.getCollateralSupply();
        vars.currUserCollateralBalance = IUserData(protocolConfig.userData).getUserCollateralInternal(
            user, pid, vars.currCollateralSupply, assetConfig.decimals
        );

        vars.maxAmountToWithdraw = IUserData(protocolConfig.userData).getUserCollateral(user, asset, reinvestment, true);

        // only allow certain amount to withdraw
        if (amount > vars.maxAmountToWithdraw) {
            amount = vars.maxAmountToWithdraw;
        }

        ValidationLogic.validateWithdrawCollateral(
            localCollateral,
            userLastTradeBlock,
            amount,
            vars.maxAmountToWithdraw,
            vars.currCollateralSupply
        );

        IUserData(protocolConfig.userData).withdrawCollateral(
            user,
            pid,
            amount,
            vars.currCollateralSupply,
            assetConfig.decimals
        );

        if (reinvestment != address(0)) {
            IReinvestment(reinvestment).checkpoint(user, vars.currUserCollateralBalance);
            IReinvestment(reinvestment).divest(amount);
        } else {
            collateral.liquidSupply -= amount;
        }

        if (localCollateral.configuration.depositFeeMantissaGwei > 0) {
            vars.feeAmount = amount.wadMul(
                uint256(localCollateral.configuration.depositFeeMantissaGwei).unitToWad(9)
            );

            IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, vars.feeAmount);
        }

        IERC20Upgradeable(asset).safeTransfer(user, amount - vars.feeAmount);

        emit WithdrawnCollateral(user, asset, reinvestment, amount - vars.feeAmount);
    }

    function executeEmergencyWithdrawCollateral(uint256 pid) external {
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        uint256 priorBalance = IERC20Upgradeable(collateral.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(collateral.reinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(collateral.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        collateral.liquidSupply += withdrawn;

        emit EmergencyWithdrawnCollateral(collateral.asset, collateral.reinvestment, withdrawn);
    }

    function executeReinvestCollateralSupply(uint256 pid) external {
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        IERC20Upgradeable(collateral.asset).safeApprove(collateral.reinvestment, collateral.liquidSupply);
        IReinvestment(collateral.reinvestment).invest(collateral.liquidSupply);

        emit ReinvestedCollateralSupply(collateral.asset, collateral.reinvestment, collateral.liquidSupply);

        collateral.liquidSupply = 0;
    }

    function claimReinvestmentRewards(
        address user,
        address asset,
        address reinvestment
    ) external {
        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;

        require(localCollateral.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_INACTIVE);
        require(reinvestment != address(0), Errors.INVALID_POOL_REINVESTMENT);

        uint256 currBalance = IUserData(LedgerStorage.getProtocolConfig().userData).getUserCollateral(user, asset, reinvestment, false);

        IReinvestment(reinvestment).claim(user, currBalance);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IReinvestmentProxy {
    function owner() external view returns (address);

    function logic() external view returns (address);

    function setLogic() external view returns (address);

    function supportedInterfaceId() external view returns (bytes4);
}

interface IReinvestmentLogic {

    event UpdatedTreasury(address oldAddress, address newAddress);
    event UpdatedFeeMantissa(uint256 oldFee, uint256 newFee);

    struct Reward {
        address asset;
        uint256 claimable;
    }

    function setTreasury(address treasury_) external;

    function setFeeMantissa(uint256 feeMantissa_) external;

    function asset() external view returns (address);

    function treasury() external view returns (address);

    function ledger() external view returns (address);

    function feeMantissa() external view returns (uint256);

    function receipt() external view returns (address);

    function platform() external view returns (address);

    function rewardOf(address, uint256) external view returns (Reward[] memory);

    function rewardLength() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim(address, uint256) external;

    function checkpoint(address, uint256) external;

    function invest(uint256) external;

    function divest(uint256) external;

    function emergencyWithdraw() external returns (uint256);

    function sweep(address) external;
}

interface IReinvestment is IReinvestmentProxy, IReinvestmentLogic {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface IUserData {
    function depositReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function depositCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 currReserveSupply,
        uint256 decimals
    ) external;

    function changePosition(
        address user,
        uint256 pid,
        int256 incomingPosition,
        uint256 borrowIndex,
        uint256 decimals
    ) external;

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfiguration memory);

    function getUserReserve(address user, address asset, bool claimable) external view returns (uint256);

    function getUserCollateral(address user, address asset, address reinvestment, bool claimable) external view returns (uint256);

    function getUserCollateralInternal(address user, uint256 pid, uint256 currPoolSupply, uint256 decimals) external view returns (uint256);

    function getUserPosition(address user, address asset) external view returns (int256);

    function getUserPositionInternal(address user, uint256 pid, uint256 borrowIndex, uint256 decimals) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

library UserConfiguration {

    function setUsingReserve(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingReserve
    ) internal {
        self.reserve = (self.reserve & ~(1 << bitIndex)) | (uint256(usingReserve ? 1 : 0) << bitIndex);
    }

    function setUsingCollateral(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingCollateral
    ) internal {
        self.collateral = (self.collateral & ~(1 << bitIndex)) | (uint256(usingCollateral ? 1 : 0) << bitIndex);
    }

    function setUsingPosition(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingPosition
    ) internal {
        self.position = (self.position & ~(1 << bitIndex)) | (uint256(usingPosition ? 1 : 0) << bitIndex);
    }

    function isUsingReserve(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.reserve >> bitIndex) & 1 != 0;
    }

    function isUsingCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.collateral >> bitIndex) & 1 != 0;
    }

    function isUsingPosition(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.position >> bitIndex) & 1 != 0;
    }

    function hasReserve(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.reserve >> offSetIndex) > 0;
    }

    function hasCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.collateral >> offSetIndex) > 0;
    }

    function hasPosition(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.position >> offSetIndex) > 0;
    }

    function isEmpty(DataTypes.UserConfiguration memory self) internal pure returns (bool) {
        return self.reserve == 0 && self.collateral == 0 && self.position == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/ISwapAdapter.sol";
import "../interfaces/IPriceOracleGetter.sol";
import "../interfaces/IReinvestment.sol";
import "../interfaces/IBonusPool.sol";
import "../interfaces/IUserData.sol";

/// @dev This help resolves cyclic dependencies
library DataTypes {

    uint256 public constant VERSION = 1;

    address public constant LIQUIDATION_WALLET = 0x0000000000000000000000000000000000000001;

    enum AssetState {Disabled, Active, Withdrawing}

    enum PositionType {Long, Short}

    enum AssetMode {Disabled, OnlyReserve, OnlyLong, ReserveAndLong}

    enum AssetKind {SingleStable, SingleVolatile, LP}

    struct AssetStorage {
        uint256 assetsCount;
        mapping(uint256 => address) assetsList;
        mapping(address => DataTypes.AssetConfig) assetConfigs;
    }

    struct ReserveStorage {
        uint256 reservesCount;
        mapping(address => uint256) reservesList;
        mapping(uint256 => DataTypes.ReserveData) reserves;
    }

    struct CollateralStorage {
        uint256 collateralsCount;
        mapping(address => mapping(address => uint256)) collateralsList;
        mapping(uint256 => DataTypes.CollateralData) collaterals;
    }

    struct ProtocolConfig {
        address treasury;
        address configuratorAddress;
        address userData;
        uint256 leverageFactor;
        uint256 tradeFeeMantissa;
        uint256 liquidationRatioMantissa;
        uint256 swapBufferLimitPercentage;
    }

    struct MappingStorage {
        mapping(address => bool) whitelistedCallers;
        mapping(address => uint256) userLastTradeBlock;
        mapping(address => uint256) liquidatedCollaterals;
    }

    // Shared property of reserve, collateral and portfolio
    struct AssetConfig {
        uint256 assetId;
        uint8 decimals;
        AssetKind kind;
        ISwapAdapter swapAdapter;
        IPriceOracleGetter oracle;
    }

    struct ReserveConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 protocolRateMantissaGwei;
        uint32 utilizationBaseRateMantissaGwei;
        uint32 kinkMantissaGwei;
        uint32 multiplierAnnualGwei;
        uint32 jumpMultiplierAnnualGwei;
        // --- 208 bits used ---
        AssetState state;
        AssetMode mode;
    }

    struct ReserveDataExtension {
        address reinvestment;
        address longReinvestment;
        address bonusPool;
    }

    struct ReserveData {
        ReserveConfiguration configuration;
        ReserveDataExtension ext;
        address asset;
        uint256 poolId;
        uint256 liquidSupply;
        // scaled utilized supply on reserve, changes whenever a deposit, withdraw, borrow and repay is executed
        uint256 scaledUtilizedSupplyRay;
        uint256 longSupply;
        uint256 reserveIndexRay;
        uint256 utilizationPercentageRay;
        uint256 protocolIndexRay;
        uint256 lastUpdatedTimestamp;
    }

    struct ReserveDataCache {
        address asset;
        address reinvestment;
        address longReinvestment;
        uint256 currReserveIndexRay;
        uint256 currProtocolIndexRay;
        uint256 currBorrowIndexRay;
    }

    struct CollateralConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 ltvGwei;
        uint128 minBalance;
        // --- 192 bits used ---
        AssetState state;
    }

    struct CollateralData {
        CollateralConfiguration configuration;
        address asset;
        address reinvestment;
        uint256 poolId;
        uint256 liquidSupply;
        uint256 totalShareSupplyRay;
    }

    struct UserConfiguration {
        uint256 reserve;
        uint256 collateral;
        uint256 position;
    }

    struct UserData {
        UserConfiguration configuration;
        mapping(uint256 => uint256) reserveShares; // in ray
        mapping(uint256 => uint256) collateralShares; // in ray
        mapping(uint256 => int256) positions; // in ray
    }

    struct InitReserveData {
        address reinvestment;
        address bonusPool;
        address longReinvestment;
        uint32 depositFeeMantissa;
        uint32 protocolRateMantissaRay;
        uint32 utilizationBaseRateMantissaRay;
        uint32 kinkMantissaRay;
        uint32 multiplierAnnualRay;
        uint32 jumpMultiplierAnnualRay;
        AssetState state;
        AssetMode mode;
    }


    struct ValidateTradeParams {
        address user;
        uint256 amountToTrade;
        uint256 currShortReserveAvailableSupply;
        uint256 maxAmountToTrade;
        uint256 userLastTradeBlock;
    }

    struct UserLiquidity {
        uint256 totalCollateralUsdPreLtv;
        uint256 totalCollateralUsdPostLtv;
        uint256 totalLongUsd;
        uint256 totalShortUsd;
        int256 pnlUsd;
        int256 totalLeverageUsd;
        int256 availableLeverageUsd;
        bool isLiquidatable;
    }

    struct UserLiquidityCachedData {
        int256 currShortingPosition;
        int256 currLongingPosition;
        uint256 shortingPrice;
        uint256 shortingPriceDecimals;
        uint256 longingPrice;
        uint256 longingPriceDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/
library MathUtils {
    uint256 public constant VERSION = 1;

    uint256 internal constant WAD_UNIT = 18;
    uint256 internal constant RAY_UNIT = 27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;
    uint256 public constant HALF_WAD = WAD / 2;
    uint256 public constant HALF_RAY = RAY / 2;


    /**
     * @notice Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_WAD) / b, "MathUtils: overflow");

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @notice Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, "MathUtils: overflow");

        return (a * WAD + halfB) / b;
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_RAY) / b, "MathUtils: overflow");

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, "MathUtils: overflow");

        return (a * RAY + halfB) / b;
    }

    /**
     * @notice Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, "MathUtils: overflow");

        return result / WAD_RAY_RATIO;
    }

    /**
     * @notice Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, "MathUtils: overflow");
        return result;
    }

    /**
     * @notice Converts unit to wad
     * @param self Value
     * @param unit Value's unit
     * @return value converted in wad
     **/
    function unitToWad(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD_UNIT) return self;

        if (unit < WAD_UNIT) {
            return self * 10**(WAD_UNIT - unit);
        } else {
            return self / 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * 10**(RAY_UNIT -unit);
        } else {
            return self / 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * int256(10**(RAY_UNIT -unit));
        } else {
            return self / int256(10**(unit - RAY_UNIT));
        }
    }

    /**
     * @notice Converts wad to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function wadToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD) return self;

        if (unit < WAD_UNIT) {
            return self / 10**(WAD_UNIT - unit);
        } else {
            return self * 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / 10**(RAY_UNIT - unit);
        } else {
            return self * 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / int256(10**(RAY_UNIT - unit));
        } else {
            return self * int256(10**(unit - RAY_UNIT));
        }
    }

    function abs(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(a * (-1));
        } else {
            return uint256(a);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library HelpersLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function approveMax(address asset, address spender, uint256 minAmount) internal {
        uint256 currAllowance = IERC20Upgradeable(asset).allowance(address(this), spender);

        if (currAllowance < minAmount) {
            IERC20Upgradeable(asset).safeApprove(spender, 0);
            IERC20Upgradeable(asset).safeApprove(spender, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "../helpers/Errors.sol";

library ValidationLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant VERSION = 1;

    /**
     * @notice Validate a Deposit to Reserve
     * @param reserve reserve
     * @param amount amount
     **/
    function validateDepositReserve(
        DataTypes.ReserveData memory reserve,
        uint256 amount
    ) internal pure {
        require(
            reserve.configuration.mode == DataTypes.AssetMode.OnlyReserve ||
            reserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong,
            "reserve mode disabled"
        );
        require(reserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
    }

    /**
     * @notice Validate a Withdraw from Reserve
     * @param reserve reserve
     * @param amount amount
     **/
    function validateWithdrawReserve(
        DataTypes.ReserveData memory reserve,
        uint256 currReserveSupply,
        uint256 amount
    ) internal pure {
        require(
            reserve.configuration.mode == DataTypes.AssetMode.OnlyReserve ||
            reserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong,
            "reserve mode disabled"
        );
        require(reserve.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currReserveSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
    }

    /**
     * @notice Validate a Deposit to Collateral
     * @param collateral collateral
     * @param userLastTradeBlock userLastTradeBlock
     * @param amount amount
     * @param userCollateral userCollateral
     **/
    function validateDepositCollateral(
        DataTypes.CollateralData memory collateral,
        uint256 userLastTradeBlock,
        uint256 amount,
        uint256 userCollateral
    ) internal view {
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(collateral.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(
            (userCollateral + amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
    }

    /**
     * @notice Validate a Withdraw from Collateral
     * @param collateral collateral
     * @param userLastTradeBlock userLastTradeBlock
     * @param amount amount
     * @param userCollateral userCollateral
     **/
    function validateWithdrawCollateral(
        DataTypes.CollateralData memory collateral,
        uint256 userLastTradeBlock,
        uint256 amount,
        uint256 userCollateral,
        uint256 currCollateralSupply
    ) internal view {
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(collateral.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currCollateralSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
        require(
            (userCollateral - amount) == 0 || (userCollateral - amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
    }

    /**
     * @notice Validate Short Repayment
     * @param userLastTradeBlock userLastTradeBlock
     * @param user user
     * @param asset asset
     * @param amount amount
     **/
    function validateRepayShort(
        int256 currNormalizedPosition,
        uint256 userLastTradeBlock,
        address user,
        address asset,
        uint256 amount,
        DataTypes.AssetState state,
        DataTypes.AssetMode mode
    ) internal view {
        require(
            state == DataTypes.AssetState.Active &&
            (mode == DataTypes.AssetMode.OnlyReserve ||
            mode == DataTypes.AssetMode.ReserveAndLong),
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(currNormalizedPosition < 0, Errors.INVALID_POSITION_TYPE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        /*
        TODO: is allowance checked can be omitted?
        it will still revert during transfer if amount is not enough
        */
        require(
            IERC20Upgradeable(asset).allowance(user, address(this)) >= amount,
            "need to approve first"
        );
    }

    /**
     * @notice Validate a Withdraw Long
     * @param userPosition User position
     * @param userLastTradeBlock userLastTradeBlock
     **/
    function validateWithdrawLong(
        int256 userPosition,
        uint256 userLastTradeBlock,
        uint256 amount,
        DataTypes.AssetState state,
        DataTypes.AssetMode mode
    ) internal view {
        require(
            state == DataTypes.AssetState.Active &&
            (mode == DataTypes.AssetMode.OnlyLong ||
            mode == DataTypes.AssetMode.ReserveAndLong),
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(userPosition > 0, Errors.NOT_ENOUGH_LONG_BALANCE);
        require(amount > 0, Errors.INVALID_AMOUNT_INPUT);
    }

    /**
     * @notice Validate a Trade
     * @param shortReserve Shorting reserve
     * @param longReserve Longing reserve
     * @param shortingAssetPosition User shorting asset position
     * @param params ValidateTradeParams object
     **/
    function validateTrade(
        DataTypes.ReserveData memory shortReserve,
        DataTypes.ReserveData memory longReserve,
        int256 shortingAssetPosition,
        DataTypes.ValidateTradeParams memory params
    ) internal view {
        require(shortReserve.asset != longReserve.asset, Errors.CANNOT_TRADE_SAME_ASSET);
        // is pool active
        require(
            shortReserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong ||
            shortReserve.configuration.mode == DataTypes.AssetMode.OnlyReserve,
            "asset cannot short"
        );
        require(
            longReserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong ||
            longReserve.configuration.mode == DataTypes.AssetMode.OnlyLong,
            "asset cannot long"
        );
        require(shortReserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(longReserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);

        // user constraint
        require(params.userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(params.amountToTrade != 0, Errors.INVALID_ZERO_AMOUNT);

        // max short amount
        require(params.amountToTrade <= params.maxAmountToTrade, Errors.NOT_ENOUGH_USER_LEVERAGE);

        uint256 amountToBorrow;

        if (shortingAssetPosition < 0) {
            // Already negative on short side, so the entire trading amount will be borrowed
            amountToBorrow = params.amountToTrade;
        } else {
            // Not negative on short side: there may be something to sell before borrowing
            if (uint256(shortingAssetPosition) < params.amountToTrade) {
                amountToBorrow = params.amountToTrade - uint256(shortingAssetPosition);
            }
            // else, curr position is long and has enough to fill the trade
        }


        // check available reserve
        if (amountToBorrow > 0) {
            require(amountToBorrow <= params.currShortReserveAvailableSupply, Errors.NOT_ENOUGH_POOL_BALANCE);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../math/MathUtils.sol";
import "../../types/DataTypes.sol";

library CollateralLogic {
    using MathUtils for uint256;

    function getCollateralSupply(
        DataTypes.CollateralData memory collateral
    ) internal view returns (uint256){
        return collateral.reinvestment == address(0)
        ? collateral.liquidSupply
        : IReinvestment(collateral.reinvestment).totalSupply();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/IUserData.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "../math/InterestUtils.sol";
import "./ValidationLogic.sol";
import "../storage/LedgerStorage.sol";

library ReserveLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    /**
     * @dev The reserve supplies
     */
    function getReserveSupplies(
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 unit = LedgerStorage.getAssetStorage().assetConfigs[reserve.asset].decimals;
        uint256 currAvailableSupply;

        if (reserve.ext.reinvestment == address(0)) {
            currAvailableSupply += reserve.liquidSupply;
        } else {
            currAvailableSupply += IReinvestment(reserve.ext.reinvestment).totalSupply();
        }

        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        uint256 currLockedReserveSupplyRay = reserve.scaledUtilizedSupplyRay.rayMul(nextReserveIndexRay);

        uint256 currProtocolUtilizedSupplyRay = reserve.scaledUtilizedSupplyRay.rayMul(nextProtocolIndexRay);

        uint256 currReserveSupply = currAvailableSupply + currLockedReserveSupplyRay.rayToUnit(unit);

        uint256 currUtilizedSupplyRay = currLockedReserveSupplyRay + currProtocolUtilizedSupplyRay;

        uint256 currTotalSupplyRay = currAvailableSupply.unitToRay(unit) + currUtilizedSupplyRay;

        return (
        currAvailableSupply,
        currReserveSupply,
        currProtocolUtilizedSupplyRay.rayToUnit(unit),
        currTotalSupplyRay.rayToUnit(unit),
        currUtilizedSupplyRay.rayToUnit(unit)
        );
    }

    /**
     * Get normalized debt
     * @return the normalized debt. expressed in ray
     **/
    function getReserveIndexes(
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256, uint256) {
        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        return (
        nextReserveIndexRay,
        nextProtocolIndexRay,
        nextProtocolIndexRay + nextReserveIndexRay
        );
    }

    function updateIndex(
        DataTypes.ReserveData storage reserve
    ) internal {
        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        reserve.reserveIndexRay = nextReserveIndexRay;
        reserve.protocolIndexRay = nextProtocolIndexRay;

        reserve.lastUpdatedTimestamp = block.timestamp;
    }

    function postUpdateReserveData(DataTypes.ReserveData storage reserve) internal {
        uint256 decimals = LedgerStorage.getAssetStorage().assetConfigs[reserve.asset].decimals;

        (,,,uint256 currTotalSupply, uint256 currUtilizedSupply) = getReserveSupplies(reserve);

        reserve.utilizationPercentageRay = currTotalSupply > 0 ? currUtilizedSupply.unitToRay(decimals).rayDiv(
            currTotalSupply.unitToRay(decimals)
        ) : 0;
    }

    function calculateIndexes(
        DataTypes.ReserveData memory reserve,
        uint256 blockTimestamp
    ) private pure returns (uint256, uint256) {
        if (reserve.utilizationPercentageRay == 0) {
            return (
            reserve.reserveIndexRay,
            reserve.protocolIndexRay
            );
        }

        uint256 currBorrowIndexRay = reserve.reserveIndexRay + reserve.protocolIndexRay;

        uint256 interestRateRay = getInterestRate(
            reserve.utilizationPercentageRay,
            uint256(reserve.configuration.protocolRateMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.utilizationBaseRateMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.kinkMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.multiplierAnnualGwei).unitToRay(9),
            uint256(reserve.configuration.jumpMultiplierAnnualGwei).unitToRay(9)
        );

        if (interestRateRay == 0) {
            return (
            reserve.reserveIndexRay,
            reserve.protocolIndexRay
            );
        }

        uint256 cumulatedInterestIndexRay = InterestUtils.getCompoundedInterest(
            interestRateRay, reserve.lastUpdatedTimestamp, blockTimestamp
        );

        uint256 growthIndexRay = currBorrowIndexRay.rayMul(cumulatedInterestIndexRay) - currBorrowIndexRay;

        uint256 protocolInterestRatioRay = uint256(reserve.configuration.protocolRateMantissaGwei).unitToRay(9).rayDiv(interestRateRay);

        uint256 nextProtocolIndexRay = reserve.protocolIndexRay + growthIndexRay.rayMul(protocolInterestRatioRay);

        uint256 nextReserveIndexRay = reserve.reserveIndexRay + growthIndexRay.rayMul(MathUtils.RAY - protocolInterestRatioRay);

        return (nextReserveIndexRay, nextProtocolIndexRay);
    }

    /**
    * @notice Get the interest rate: `rate + utilizationBaseRate + protocolRate`
    * @param utilizationPercentageRay scaledTotalSupplyRay
    * @param protocolRateMantissaRay protocolRateMantissaRay
    * @param utilizationBaseRateMantissaRay utilizationBaseRateMantissaRay
    * @param kinkMantissaRay kinkMantissaRay
    * @param multiplierAnnualRay multiplierAnnualRay
    * @param jumpMultiplierAnnualRay jumpMultiplierAnnualRay
    **/
    function getInterestRate(
        uint256 utilizationPercentageRay,
        uint256 protocolRateMantissaRay,
        uint256 utilizationBaseRateMantissaRay,
        uint256 kinkMantissaRay,
        uint256 multiplierAnnualRay,
        uint256 jumpMultiplierAnnualRay
    ) private pure returns (uint256) {
        uint256 rateRay;

        if (utilizationPercentageRay <= kinkMantissaRay) {
            rateRay = utilizationPercentageRay.rayMul(multiplierAnnualRay);
        } else {
            uint256 normalRateRay = kinkMantissaRay.rayMul(multiplierAnnualRay);
            uint256 excessUtilRay = utilizationPercentageRay - kinkMantissaRay;
            rateRay = excessUtilRay.rayMul(jumpMultiplierAnnualRay) + normalRateRay;
        }

        return rateRay + utilizationBaseRateMantissaRay + protocolRateMantissaRay;
    }

    function cache(
        DataTypes.ReserveData storage reserve
    ) internal view returns (
        DataTypes.ReserveDataCache memory
    ) {
        DataTypes.ReserveDataCache memory reserveCache;

        reserveCache.asset = reserve.asset;
        reserveCache.reinvestment = reserve.ext.reinvestment;
        reserveCache.longReinvestment = reserve.ext.longReinvestment;

        // if the action involves mint/burn of debt, the cache needs to be updated
        reserveCache.currReserveIndexRay = reserve.reserveIndexRay;
        reserveCache.currProtocolIndexRay = reserve.protocolIndexRay;
        reserveCache.currBorrowIndexRay = reserveCache.currReserveIndexRay + reserveCache.currProtocolIndexRay;

        return reserveCache;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../types/DataTypes.sol";

library LedgerStorage {
    bytes32 constant ASSET_STORAGE_HASH = keccak256("asset_storage");
    bytes32 constant RESERVE_STORAGE_HASH = keccak256("reserve_storage");
    bytes32 constant COLLATERAL_STORAGE_HASH = keccak256("collateral_storage");
    bytes32 constant PROTOCOL_CONFIG_HASH = keccak256("protocol_config");
    bytes32 constant MAPPING_STORAGE_HASH = keccak256("mapping_storage");

    function getAssetStorage() internal pure returns (DataTypes.AssetStorage storage assetStorage) {
        bytes32 hash = ASSET_STORAGE_HASH;
        assembly {assetStorage.slot := hash}
    }

    function getReserveStorage() internal pure returns (DataTypes.ReserveStorage storage rs) {
        bytes32 hash = RESERVE_STORAGE_HASH;
        assembly {rs.slot := hash}
    }

    function getCollateralStorage() internal pure returns (DataTypes.CollateralStorage storage cs) {
        bytes32 hash = COLLATERAL_STORAGE_HASH;
        assembly {cs.slot := hash}
    }

    function getProtocolConfig() internal pure returns (DataTypes.ProtocolConfig storage pc) {
        bytes32 hash = PROTOCOL_CONFIG_HASH;
        assembly {pc.slot := hash}
    }

    function getMappingStorage() internal pure returns (DataTypes.MappingStorage storage ms) {
        bytes32 hash = MAPPING_STORAGE_HASH;
        assembly {ms.slot := hash}
    }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISwapAdapter {
    function swap(
        address selling,
        address buying,
        uint256 amount,
        bytes memory data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBonusPool {
    function updatePoolUser(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Errors {
    string public constant LEDGER_INITIALIZED = 'LEDGER_INITIALIZED';
    string public constant CALLER_NOT_OPERATOR = 'CALLER_NOT_OPERATOR';
    string public constant CALLER_NOT_LIQUIDATE_EXECUTOR = 'CALLER_NOT_LIQUIDATE_EXECUTOR';
    string public constant CALLER_NOT_CONFIGURATOR = 'CALLER_NOT_CONFIGURATOR';
    string public constant CALLER_NOT_WHITELISTED = 'CALLER_NOT_WHITELISTED';
    string public constant CALLER_NOT_LEDGER = 'ONLY_LEDGER';
    string public constant INVALID_LEVERAGE_FACTOR = 'INVALID_LEVERAGE_FACTOR';
    string public constant INVALID_LIQUIDATION_RATIO = 'INVALID_LIQUIDATION_RATIO';
    string public constant INVALID_TRADE_FEE = 'INVALID_TRADE_FEE';
    string public constant INVALID_ZERO_ADDRESS = 'INVALID_ZERO_ADDRESS';
    string public constant INVALID_ASSET_CONFIGURATION = 'INVALID_ASSET_CONFIGURATION';
    string public constant ASSET_INACTIVE = 'ASSET_INACTIVE';
    string public constant ASSET_ACTIVE = 'ASSET_ACTIVE';
    string public constant POOL_INACTIVE = 'POOL_INACTIVE';
    string public constant POOL_ACTIVE = 'POOL_ACTIVE';
    string public constant POOL_EXIST = 'POOL_EXIST';
    string public constant INVALID_POOL_REINVESTMENT = 'INVALID_POOL_REINVESTMENT';
    string public constant ASSET_INITIALIZED = 'ASSET_INITIALIZED';
    string public constant ASSET_NOT_INITIALIZED = 'ASSET_NOT_INITIALIZED';
    string public constant POOL_INITIALIZED = 'POOL_INITIALIZED';
    string public constant POOL_NOT_INITIALIZED = 'POOL_NOT_INITIALIZED';
    string public constant INVALID_ZERO_AMOUNT = 'INVALID_ZERO_AMOUNT';
    string public constant CANNOT_SWEEP_REGISTERED_ASSET = 'CANNOT_SWEEP_REGISTERED_ASSET';
    string public constant INVALID_ACTION_ID = 'INVALID_ACTION_ID';
    string public constant INVALID_POSITION_TYPE = 'INVALID_POSITION_TYPE';
    string public constant INVALID_AMOUNT_INPUT = 'INVALID_AMOUNT_INPUT';
    string public constant INVALID_ASSET_INPUT = 'INVALID_ASSET_INPUT';
    string public constant INVALID_SWAP_BUFFER_LIMIT = 'INVALID_SWAP_BUFFER_LIMIT';
    string public constant NOT_ENOUGH_BALANCE = 'NOT_ENOUGH_BALANCE';
    string public constant NOT_ENOUGH_LONG_BALANCE = 'NOT_ENOUGH_LONG_BALANCE';
    string public constant NOT_ENOUGH_POOL_BALANCE = 'NOT_ENOUGH_POOL_BALANCE';
    string public constant NOT_ENOUGH_USER_LEVERAGE = 'NOT_ENOUGH_USER_LEVERAGE';
    string public constant MISSING_UNDERLYING_ASSET = 'MISSING_UNDERLYING_ASSET';
    string public constant NEGATIVE_PNL = 'NEGATIVE_PNL';
    string public constant NEGATIVE_AVAILABLE_LEVERAGE = 'NEGATIVE_AVAILABLE_LEVERAGE';
    string public constant BAD_TRADE = 'BAD_TRADE';
    string public constant USER_TRADE_BLOCK = 'USER_TRADE_BLOCK';
    string public constant ERROR_EMERGENCY_WITHDRAW = 'ERROR_EMERGENCY_WITHDRAW';
    string public constant ERROR_UNWRAP_LP = 'ERROR_UNWRAP_LP';
    string public constant CANNOT_TRADE_SAME_ASSET = 'CANNOT_TRADE_SAME_ASSET';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MathUtils.sol";

library InterestUtils {
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
   * @notice Function to calculate the interest using a compounded interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
    function getCompoundedInterest(
        uint256 rate,
        uint256 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        uint256 exp = currentTimestamp - lastUpdateTimestamp;

        if (exp == 0) {
            return MathUtils.RAY;
        }

        uint256 expMinusOne = exp - 1;

        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

        uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
        uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

        uint256 secondTerm = exp * expMinusOne * basePowerTwo / 2;
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree / 6;

        return MathUtils.RAY + (ratePerSecond * exp) + secondTerm + thirdTerm;
    }
}