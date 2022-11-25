// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "../../interfaces/IFeeDistributorFront.sol";
import "../../interfaces/ISanToken.sol";
import "../../interfaces/IStableMasterFront.sol";
import "../../interfaces/IVeANGLE.sol";

import "../../BaseRouter.sol";

// ============================= STRUCTS AND ENUMS =============================

/// @notice References to the contracts associated to a collateral for a stablecoin
struct Pairs {
    IPoolManager poolManager;
    IPerpetualManagerFrontWithClaim perpetualManager;
    ISanToken sanToken;
    ILiquidityGauge gauge;
}

/// @title AngleRouterMainnet
/// @author Angle Core Team
/// @notice Router contract built specifially for Angle use cases on Ethereum
/// @dev Interfaces were designed for both advanced users which know the addresses of the protocol's contract,
/// but most of the time users which only know addresses of the stablecoins and collateral types of the protocol
/// can perform the actions they want without needing to understand what's happening under the hood
contract AngleRouterMainnet is BaseRouter {
    using SafeERC20 for IERC20;

    // =================================== ERRORS ==================================

    error InvalidParams();

    // ================================== MAPPINGS =================================

    /// @notice Maps an agToken to its counterpart `StableMaster`
    mapping(IERC20 => IStableMasterFront) public mapStableMasters;
    /// @notice Maps a `StableMaster` to a mapping of collateral token to its counterpart `PoolManager`
    mapping(IStableMasterFront => mapping(IERC20 => Pairs)) public mapPoolManagers;

    uint256[48] private __gapMainnet;

    function initialize(
        address _core,
        address _uniswapRouter,
        address _oneInch,
        IERC20 angleAddress,
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges,
        bool[] calldata justLiquidityGauges
    ) external {
        initializeRouter(_core, _uniswapRouter, _oneInch);
        angleAddress.safeIncreaseAllowance(address(_getVeANGLE()), type(uint256).max);
        // agEUR and StableMaster for agEUR
        mapStableMasters[IERC20(0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8)] = IStableMasterFront(
            0x5adDc89785D75C86aB939E9e15bfBBb7Fc086A87
        );
        _addPairs(stablecoins, poolManagers, liquidityGauges, justLiquidityGauges);
    }

    // =========================== ROUTER FUNCTIONALITIES ==========================

    /// @inheritdoc BaseRouter
    function _chainSpecificAction(ActionType action, bytes calldata data) internal override {
        if (action == ActionType.claimRewardsWithPerps) {
            (
                address user,
                address[] memory claimLiquidityGauges,
                uint256[] memory claimPerpetualIDs,
                bool addressProcessed,
                address[] memory stablecoins,
                address[] memory collateralsOrPerpetualManagers
            ) = abi.decode(data, (address, address[], uint256[], bool, address[], address[]));
            _claimRewardsWithPerps(
                user,
                claimLiquidityGauges,
                claimPerpetualIDs,
                addressProcessed,
                stablecoins,
                collateralsOrPerpetualManagers
            );
        } else if (action == ActionType.claimWeeklyInterest) {
            (address user, address feeDistributor, bool letInContract) = abi.decode(data, (address, address, bool));
            _claimWeeklyInterest(user, IFeeDistributorFront(feeDistributor), letInContract);
        } else if (action == ActionType.veANGLEDeposit) {
            (address user, uint256 amount) = abi.decode(data, (address, uint256));
            _depositOnLocker(user, amount);
        } else if (action == ActionType.deposit) {
            (
                address user,
                uint256 amount,
                bool addressProcessed,
                address stablecoinOrStableMaster,
                address collateral,
                address poolManager
            ) = abi.decode(data, (address, uint256, bool, address, address, address));
            _deposit(user, amount, addressProcessed, stablecoinOrStableMaster, collateral, IPoolManager(poolManager));
        } else if (action == ActionType.withdraw) {
            (
                uint256 amount,
                bool addressProcessed,
                address stablecoinOrStableMaster,
                address collateralOrPoolManager,
                address sanToken
            ) = abi.decode(data, (uint256, bool, address, address, address));
            if (amount == type(uint256).max) amount = IERC20(sanToken).balanceOf(address(this));
            _withdraw(amount, addressProcessed, stablecoinOrStableMaster, collateralOrPoolManager);
        } else if (action == ActionType.mint) {
            (
                address user,
                uint256 amount,
                uint256 minStableAmount,
                bool addressProcessed,
                address stablecoinOrStableMaster,
                address collateral,
                address poolManager
            ) = abi.decode(data, (address, uint256, uint256, bool, address, address, address));
            _mint(
                user,
                amount,
                minStableAmount,
                addressProcessed,
                stablecoinOrStableMaster,
                collateral,
                IPoolManager(poolManager)
            );
        } else if (action == ActionType.openPerpetual) {
            (
                address user,
                uint256 amount,
                uint256 amountCommitted,
                uint256 extremeRateOracle,
                uint256 minNetMargin,
                bool addressProcessed,
                address stablecoinOrPerpetualManager,
                address collateral
            ) = abi.decode(data, (address, uint256, uint256, uint256, uint256, bool, address, address));
            _openPerpetual(
                user,
                amount,
                amountCommitted,
                extremeRateOracle,
                minNetMargin,
                addressProcessed,
                stablecoinOrPerpetualManager,
                collateral
            );
        } else if (action == ActionType.addToPerpetual) {
            (
                uint256 amount,
                uint256 perpetualID,
                bool addressProcessed,
                address stablecoinOrPerpetualManager,
                address collateral
            ) = abi.decode(data, (uint256, uint256, bool, address, address));
            _addToPerpetual(amount, perpetualID, addressProcessed, stablecoinOrPerpetualManager, collateral);
        }
    }

    /// @inheritdoc BaseRouter
    function _getNativeWrapper() internal pure override returns (IWETH9) {
        return IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /// @notice Claims rewards for multiple gauges and perpetuals at once
    /// @param gaugeUser Address for which to fetch the rewards from the gauges
    /// @param liquidityGauges Gauges to claim on
    /// @param perpetualIDs Perpetual IDs to claim rewards for
    /// @param addressProcessed Whether `PerpetualManager` list is already accessible in `collateralsOrPerpetualManagers` or if
    ///  it should be retrieved from `stablecoins` and `collateralsOrPerpetualManagers`
    /// @param stablecoins Stablecoin contracts linked to the perpetualsIDs. Array of zero addresses if `addressProcessed` is true
    /// @param collateralsOrPerpetualManagers Collateral contracts linked to the perpetualsIDs or `perpetualManager` contracts if
    /// `addressProcessed` is true
    function _claimRewardsWithPerps(
        address gaugeUser,
        address[] memory liquidityGauges,
        uint256[] memory perpetualIDs,
        bool addressProcessed,
        address[] memory stablecoins,
        address[] memory collateralsOrPerpetualManagers
    ) internal {
        uint256 perpetualIDsLength = perpetualIDs.length;
        if (
            perpetualIDsLength != 0 &&
            (stablecoins.length != perpetualIDsLength || collateralsOrPerpetualManagers.length != perpetualIDsLength)
        ) revert IncompatibleLengths();

        uint256 liquidityGaugesLength = liquidityGauges.length;
        for (uint256 i; i < liquidityGaugesLength; ++i) {
            ILiquidityGauge(liquidityGauges[i]).claim_rewards(gaugeUser);
        }

        for (uint256 i; i < perpetualIDsLength; ++i) {
            IPerpetualManagerFrontWithClaim perpManager;
            if (addressProcessed) perpManager = IPerpetualManagerFrontWithClaim(collateralsOrPerpetualManagers[i]);
            else {
                (, Pairs memory pairs) = _getInternalContracts(
                    IERC20(stablecoins[i]),
                    IERC20(collateralsOrPerpetualManagers[i])
                );
                perpManager = pairs.perpetualManager;
            }
            perpManager.getReward(perpetualIDs[i]);
        }
    }

    /// @notice Deposits ANGLE on an existing locker
    /// @param user Address to deposit for
    /// @param amount Amount to deposit
    function _depositOnLocker(address user, uint256 amount) internal {
        _getVeANGLE().deposit_for(user, amount);
    }

    /// @notice Claims weekly interest distribution and if wanted transfers it to the contract for future use
    /// @param user Address to claim for
    /// @param _feeDistributor Address of the fee distributor to claim to
    /// @dev If `letInContract` (and hence if funds are transferred to the router), you should approve the `angleRouter` to
    /// transfer the token claimed from the `feeDistributor`
    function _claimWeeklyInterest(
        address user,
        IFeeDistributorFront _feeDistributor,
        bool letInContract
    ) internal {
        uint256 amount = _feeDistributor.claim(user);
        if (letInContract) {
            // Fetching info from the `FeeDistributor` to process correctly the withdrawal
            IERC20 token = IERC20(_feeDistributor.token());
            token.safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    /// @notice Mints stablecoins using the Core module of the protocol
    /// @param user Address to send the stablecoins to
    /// @param amount Amount of collateral to use for the mint
    /// @param minStableAmount Minimum stablecoin minted for the tx not to revert
    /// @param addressProcessed Whether `msg.sender` provided the contracts address or the tokens one
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Collateral to mint from: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the mint
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    function _mint(
        address user,
        uint256 amount,
        uint256 minStableAmount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal {
        IStableMasterFront stableMaster;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(IERC20(stablecoinOrStableMaster), IERC20(collateral));
            poolManager = pairs.poolManager;
        }
        stableMaster.mint(amount, user, poolManager, minStableAmount);
    }

    /// @notice Deposits collateral in the Core Module of the protocol
    /// @param user Address where to send the resulting sanTokens, if this address is the router address then it means
    /// that the intention is to stake the sanTokens obtained in a subsequent `gaugeDeposit` action
    /// @param amount Amount of collateral to deposit
    /// @param addressProcessed Whether `msg.sender` provided the contracts addresses or the tokens ones
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateral Token to deposit: it can be null if `addressProcessed` is true but in the corresponding
    /// action, the `mixer` needs to get a correct address to compute the amount of tokens to use for the deposit
    /// @param poolManager PoolManager associated to the `collateral` (null if `addressProcessed` is not true)
    function _deposit(
        address user,
        uint256 amount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateral,
        IPoolManager poolManager
    ) internal {
        IStableMasterFront stableMaster;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(IERC20(stablecoinOrStableMaster), IERC20(collateral));
            poolManager = pairs.poolManager;
        }
        stableMaster.deposit(amount, user, poolManager);
    }

    /// @notice Withdraws sanTokens from the protocol
    /// @param amount Amount of sanTokens to withdraw
    /// @param addressProcessed Whether `msg.sender` provided the contracts addresses or the tokens ones
    /// @param stablecoinOrStableMaster Token associated to a `StableMaster` (if `addressProcessed` is false)
    /// or directly the `StableMaster` contract if `addressProcessed`
    /// @param collateralOrPoolManager Collateral to withdraw (if `addressProcessed` is false) or directly
    /// the `PoolManager` contract if `addressProcessed`
    function _withdraw(
        uint256 amount,
        bool addressProcessed,
        address stablecoinOrStableMaster,
        address collateralOrPoolManager
    ) internal {
        IStableMasterFront stableMaster;
        IPoolManager poolManager;
        if (addressProcessed) {
            stableMaster = IStableMasterFront(stablecoinOrStableMaster);
            poolManager = IPoolManager(collateralOrPoolManager);
        } else {
            Pairs memory pairs;
            (stableMaster, pairs) = _getInternalContracts(
                IERC20(stablecoinOrStableMaster),
                IERC20(collateralOrPoolManager)
            );
            poolManager = pairs.poolManager;
        }
        stableMaster.withdraw(amount, address(this), address(this), poolManager);
    }

    /// @notice Opens a perpetual within the Core Module
    /// @param owner Address to mint perpetual for
    /// @param margin Margin to open the perpetual with
    /// @param amountCommitted Commit amount in the perpetual
    /// @param maxOracleRate Maximum oracle rate required to have a leverage position opened
    /// @param minNetMargin Minimum net margin required to have a leverage position opened
    /// @param addressProcessed Whether msg.sender provided the contracts addresses or the tokens ones
    /// @param stablecoinOrPerpetualManager Token associated to the `StableMaster` (iif `addressProcessed` is false)
    /// or address of the desired `PerpetualManager` (if `addressProcessed` is true)
    /// @param collateral Collateral to mint from (it can be null if `addressProcessed` is true): it can be null if
    /// `addressProcessed` is true but in the corresponding action, the `mixer` needs to get a correct address to compute
    /// the amount of tokens to use for the deposit
    function _openPerpetual(
        address owner,
        uint256 margin,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) internal returns (uint256 perpetualID) {
        if (!addressProcessed) {
            (, Pairs memory pairs) = _getInternalContracts(IERC20(stablecoinOrPerpetualManager), IERC20(collateral));
            stablecoinOrPerpetualManager = address(pairs.perpetualManager);
        }
        return
            IPerpetualManagerFrontWithClaim(stablecoinOrPerpetualManager).openPerpetual(
                owner,
                margin,
                amountCommitted,
                maxOracleRate,
                minNetMargin
            );
    }

    /// @notice Adds collateral to a perpetual
    /// @param margin Amount of collateral to add
    /// @param perpetualID Perpetual to add collateral to
    /// @param addressProcessed Whether msg.sender provided the contracts addresses or the tokens ones
    /// @param stablecoinOrPerpetualManager Token associated to the `StableMaster` (iif `addressProcessed` is false)
    /// or address of the desired `PerpetualManager` (if `addressProcessed` is true)
    /// @param collateral Collateral to mint from (it can be null if `addressProcessed` is true): it can be null
    /// if `addressProcessed` is true but in the corresponding action, the `mixer` needs to get a correct address
    /// to compute the amount of tokens to use for the deposit
    function _addToPerpetual(
        uint256 margin,
        uint256 perpetualID,
        bool addressProcessed,
        address stablecoinOrPerpetualManager,
        address collateral
    ) internal {
        if (!addressProcessed) {
            (, Pairs memory pairs) = _getInternalContracts(IERC20(stablecoinOrPerpetualManager), IERC20(collateral));
            stablecoinOrPerpetualManager = address(pairs.perpetualManager);
        }
        IPerpetualManagerFrontWithClaim(stablecoinOrPerpetualManager).addToPerpetual(perpetualID, margin);
    }

    // ============================ GOVERNANCE UTILITIES ===========================

    /// @notice Adds a new `StableMaster`
    /// @param stablecoin Address of the new stablecoin
    /// @param stableMaster Address of the new `StableMaster`
    function addStableMaster(IERC20 stablecoin, IStableMasterFront stableMaster) external onlyGovernorOrGuardian {
        if (
            address(stablecoin) == address(0) ||
            address(mapStableMasters[stablecoin]) != address(0) ||
            stableMaster.agToken() != address(stablecoin)
        ) revert InvalidParams();
        mapStableMasters[stablecoin] = stableMaster;
    }

    /// @notice Adds new collateral types to specific stablecoins
    /// @param stablecoins Addresses of the stablecoins associated to the `StableMaster` of interest
    /// @param poolManagers Addresses of the `PoolManager` contracts associated to the pair (stablecoin,collateral)
    /// @param liquidityGauges Addresses of liquidity gauges contract associated to sanToken
    /// @param justLiquidityGauges Whether just the liquidity gauge addresses should be added
    function addPairs(
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges,
        bool[] calldata justLiquidityGauges
    ) external onlyGovernorOrGuardian {
        _addPairs(stablecoins, poolManagers, liquidityGauges, justLiquidityGauges);
    }

    // ========================= INTERNAL UTILITY FUNCTIONS ========================

    /// @notice Gets Angle contracts associated to a pair (stablecoin, collateral)
    /// @param stablecoin Token associated to a `StableMaster`
    /// @param collateral Collateral to mint/deposit/open perpetual or add collateral from
    /// @dev This function is used to check that the parameters passed by people calling some of the main
    /// router functions are correct
    function _getInternalContracts(IERC20 stablecoin, IERC20 collateral)
        internal
        view
        returns (IStableMasterFront stableMaster, Pairs memory pairs)
    {
        stableMaster = mapStableMasters[stablecoin];
        pairs = mapPoolManagers[stableMaster][collateral];
        if (address(stableMaster) == address(0) || address(pairs.poolManager) == address(0)) revert ZeroAddress();
        return (stableMaster, pairs);
    }

    /// @notice Internal version of the `addPairs` function
    function _addPairs(
        IERC20[] calldata stablecoins,
        IPoolManager[] calldata poolManagers,
        ILiquidityGauge[] calldata liquidityGauges,
        bool[] calldata justLiquidityGauges
    ) internal {
        uint256 stablecoinsLength = stablecoins.length;
        if (
            poolManagers.length != stablecoinsLength ||
            liquidityGauges.length != stablecoinsLength ||
            justLiquidityGauges.length != stablecoinsLength
        ) revert IncompatibleLengths();
        for (uint256 i; i < stablecoinsLength; ++i) {
            IStableMasterFront stableMaster = mapStableMasters[stablecoins[i]];
            _addPair(stableMaster, poolManagers[i], liquidityGauges[i], justLiquidityGauges[i]);
        }
    }

    /// @notice Adds new collateral type to specific stablecoin
    /// @param stableMaster Address of the `StableMaster` associated to the stablecoin of interest
    /// @param poolManager Address of the `PoolManager` contract associated to the pair (stablecoin,collateral)
    /// @param liquidityGauge Address of the liquidity gauge contract associated to sanToken
    /// @param justLiquidityGauge Whether we should just update the liquidity gauge address
    function _addPair(
        IStableMasterFront stableMaster,
        IPoolManager poolManager,
        ILiquidityGauge liquidityGauge,
        bool justLiquidityGauge
    ) internal {
        // Fetching the associated `sanToken` and `perpetualManager` from the contract
        (
            IERC20 collateral,
            ISanToken sanToken,
            IPerpetualManagerFrontWithClaim perpetualManager,
            ,
            ,
            ,
            ,
            ,

        ) = stableMaster.collateralMap(poolManager);
        // Reverting if the poolManager is not a valid `poolManager`
        if (address(collateral) == address(0)) revert InvalidParams();
        Pairs storage _pairs = mapPoolManagers[stableMaster][collateral];
        if (justLiquidityGauge) {
            // Cannot specify a liquidity gauge if the associated poolManager does not exist
            if (address(_pairs.poolManager) == address(0)) revert ZeroAddress();
            ILiquidityGauge gauge = _pairs.gauge;
            if (address(gauge) != address(0)) {
                _changeAllowance(IERC20(address(sanToken)), address(gauge), 0);
            }
        } else {
            // Checking if the pair has not already been initialized: if yes we need to make the function revert
            // otherwise we could end up with still approved `PoolManager` and `PerpetualManager` contracts
            if (address(_pairs.poolManager) != address(0)) revert InvalidParams();
            _pairs.poolManager = poolManager;
            _pairs.perpetualManager = IPerpetualManagerFrontWithClaim(address(perpetualManager));
            _pairs.sanToken = sanToken;
            _changeAllowance(collateral, address(stableMaster), type(uint256).max);
            _changeAllowance(collateral, address(perpetualManager), type(uint256).max);
        }
        _pairs.gauge = liquidityGauge;
        if (address(liquidityGauge) != address(0)) {
            if (address(sanToken) != liquidityGauge.staking_token()) revert InvalidParams();
            _changeAllowance(IERC20(address(sanToken)), address(liquidityGauge), type(uint256).max);
        }
    }

    /// @notice Returns the veANGLE address
    function _getVeANGLE() internal view virtual returns (IVeANGLE) {
        return IVeANGLE(0x0C462Dbb9EC8cD1630f1728B2CFD2769d09f0dd5);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title IFeeDistributorFront
/// @author Interface for public use of the `FeeDistributor` contract
/// @dev This interface is used for user related function
interface IFeeDistributorFront {
    function token() external returns (address);

    function claim(address _addr) external returns (uint256);

    function claim(address[20] memory _addr) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ISanToken is IERC20Upgradeable {}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "./IPoolManager.sol";
import "./ISanToken.sol";
import "./IPerpetualManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Struct to handle all the parameters to manage the fees
// related to a given collateral pool (associated to the stablecoin)
struct MintBurnData {
    // Values of the thresholds to compute the minting fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeMint;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeMint;
    // Values of the thresholds to compute the burning fees
    // depending on HA hedge (scaled by `BASE_PARAMS`)
    uint64[] xFeeBurn;
    // Values of the fees at thresholds (scaled by `BASE_PARAMS`)
    uint64[] yFeeBurn;
    // Max proportion of collateral from users that can be covered by HAs
    // It is exactly the same as the parameter of the same name in `PerpetualManager`, whenever one is updated
    // the other changes accordingly
    uint64 targetHAHedge;
    // Minting fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusMint;
    // Burning fees correction set by the `FeeManager` contract: they are going to be multiplied
    // to the value of the fees computed using the hedge curve
    // Scaled by `BASE_PARAMS`
    uint64 bonusMalusBurn;
    // Parameter used to limit the number of stablecoins that can be issued using the concerned collateral
    uint256 capOnStableMinted;
}

// Struct to handle all the variables and parameters to handle SLPs in the protocol
// including the fraction of interests they receive or the fees to be distributed to
// them
struct SLPData {
    // Last timestamp at which the `sanRate` has been updated for SLPs
    uint256 lastBlockUpdated;
    // Fees accumulated from previous blocks and to be distributed to SLPs
    uint256 lockedInterests;
    // Max interests used to update the `sanRate` in a single block
    // Should be in collateral token base
    uint256 maxInterestsDistributed;
    // Amount of fees left aside for SLPs and that will be distributed
    // when the protocol is collateralized back again
    uint256 feesAside;
    // Part of the fees normally going to SLPs that is left aside
    // before the protocol is collateralized back again (depends on collateral ratio)
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippageFee;
    // Portion of the fees from users minting and burning
    // that goes to SLPs (the rest goes to surplus)
    uint64 feesForSLPs;
    // Slippage factor that's applied to SLPs exiting (depends on collateral ratio)
    // If `slippage = BASE_PARAMS`, SLPs can get nothing, if `slippage = 0` they get their full claim
    // Updated by keepers and scaled by `BASE_PARAMS`
    uint64 slippage;
    // Portion of the interests from lending
    // that goes to SLPs (the rest goes to surplus)
    uint64 interestsForSLPs;
}

/// @title IStableMasterFront
/// @author Angle Core Team
/// @dev Front interface, meaning only user-facing functions
interface IStableMasterFront {
    function collateralMap(IPoolManager poolManager)
        external
        view
        returns (
            IERC20 token,
            ISanToken sanToken,
            IPerpetualManagerFrontWithClaim perpetualManager,
            address oracle,
            uint256 stocksUsers,
            uint256 sanRate,
            uint256 collatBase,
            SLPData memory slpData,
            MintBurnData memory feeData
        );

    function updateStocksUsers(uint256 amount, address poolManager) external;

    function mint(
        uint256 amount,
        address user,
        IPoolManager poolManager,
        uint256 minStableAmount
    ) external;

    function burn(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager,
        uint256 minCollatAmount
    ) external;

    function deposit(
        uint256 amount,
        address user,
        IPoolManager poolManager
    ) external;

    function withdraw(
        uint256 amount,
        address burner,
        address dest,
        IPoolManager poolManager
    ) external;

    function agToken() external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IVeANGLE
/// @author Angle Core Team
/// @notice Interface for the `VeANGLE` contract
interface IVeANGLE {
    // solhint-disable-next-line func-name-mixedcase
    function deposit_for(address addr, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

import "./interfaces/external/uniswap/IUniswapRouter.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/ICoreBorrow.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/ISavingsRateIlliquid.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IVaultManager.sol";

// ============================== STRUCTS AND ENUM =============================

/// @notice Action types
enum ActionType {
    transfer,
    wrapNative,
    unwrapNative,
    sweep,
    sweepNative,
    uniswapV3,
    oneInch,
    claimRewards,
    gaugeDeposit,
    borrower,
    swapper,
    mintSavingsRate,
    depositSavingsRate,
    redeemSavingsRate,
    withdrawSavingsRate,
    prepareRedeemSavingsRate,
    claimRedeemSavingsRate,
    swapIn,
    swapOut,
    claimWeeklyInterest,
    withdraw,
    mint,
    deposit,
    openPerpetual,
    addToPerpetual,
    veANGLEDeposit,
    claimRewardsWithPerps
}

/// @notice Data needed to get permits
struct PermitType {
    address token;
    address owner;
    uint256 value;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @notice Data to grant permit to the router for a vault
struct PermitVaultManagerType {
    address vaultManager;
    address owner;
    bool approved;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @title BaseRouter
/// @author Angle Core Team
/// @notice Base contract that Angle router contracts on different chains should override
/// @dev Router contracts are designed to facilitate the composition of actions on the different modules of the protocol
abstract contract BaseRouter is Initializable {
    using SafeERC20 for IERC20;

    /// @notice How many actions can be performed on a given `VaultManager` contract
    uint256 private constant _MAX_BORROW_ACTIONS = 10;

    // ================================= REFERENCES ================================

    /// @notice Core address handling access control
    ICoreBorrow public core;
    /// @notice Address of the router used for swaps
    IUniswapV3Router public uniswapV3Router;
    /// @notice Address of 1Inch router used for swaps
    address public oneInch;

    uint256[47] private __gap;

    // ============================== EVENTS / ERRORS ==============================

    error IncompatibleLengths();
    error InvalidReturnMessage();
    error NotApprovedOrOwner();
    error NotGovernor();
    error NotGovernorOrGuardian();
    error TooSmallAmountOut();
    error TransferFailed();
    error ZeroAddress();

    /// @notice Deploys the router contract on a chain
    function initializeRouter(
        address _core,
        address _uniswapRouter,
        address _oneInch
    ) public initializer {
        if (_core == address(0)) revert ZeroAddress();
        core = ICoreBorrow(_core);
        uniswapV3Router = IUniswapV3Router(_uniswapRouter);
        oneInch = _oneInch;
    }

    constructor() initializer {}

    // =========================== ROUTER FUNCTIONALITIES ==========================

    /// @notice Allows composable calls to different functions within the protocol
    /// @param paramsPermit Array of params `PermitType` used to do a 1 tx to approve the router on each token (can be done once by
    /// setting high approved amounts) which supports the `permit` standard. Users willing to interact with the contract
    /// with tokens that do not support permit should approve the contract for these tokens prior to interacting with it
    /// @param actions List of actions to be performed by the router (in order of execution)
    /// @param data Array of encoded data for each of the actions performed in this mixer. This is where the bytes-encoded parameters
    /// for a given action are stored
    /// @dev With this function, users can specify paths to swap tokens to the desired token of their choice. Yet the protocol
    /// does not verify the payload given and cannot check that the swap performed by users actually gives the desired
    /// out token: in this case funds may be made accessible to anyone on this contract if the concerned users
    /// do not perform a sweep action on these tokens
    function mixer(
        PermitType[] memory paramsPermit,
        ActionType[] calldata actions,
        bytes[] calldata data
    ) public payable virtual {
        // If all tokens have already been approved, there's no need for this step
        uint256 permitsLength = paramsPermit.length;
        for (uint256 i; i < permitsLength; ++i) {
            IERC20Permit(paramsPermit[i].token).permit(
                paramsPermit[i].owner,
                address(this),
                paramsPermit[i].value,
                paramsPermit[i].deadline,
                paramsPermit[i].v,
                paramsPermit[i].r,
                paramsPermit[i].s
            );
        }
        // Performing actions one after the others
        uint256 actionsLength = actions.length;
        for (uint256 i; i < actionsLength; ++i) {
            if (actions[i] == ActionType.transfer) {
                (address inToken, address receiver, uint256 amount) = abi.decode(data[i], (address, address, uint256));
                if (amount == type(uint256).max) amount = IERC20(inToken).balanceOf(msg.sender);
                IERC20(inToken).safeTransferFrom(msg.sender, receiver, amount);
            } else if (actions[i] == ActionType.wrapNative) {
                _wrapNative();
            } else if (actions[i] == ActionType.unwrapNative) {
                (uint256 minAmountOut, address to) = abi.decode(data[i], (uint256, address));
                _unwrapNative(minAmountOut, to);
            } else if (actions[i] == ActionType.sweep) {
                (address tokenOut, uint256 minAmountOut, address to) = abi.decode(data[i], (address, uint256, address));
                _sweep(tokenOut, minAmountOut, to);
            } else if (actions[i] == ActionType.sweepNative) {
                uint256 routerBalance = address(this).balance;
                if (routerBalance != 0) _safeTransferNative(msg.sender, routerBalance);
            } else if (actions[i] == ActionType.uniswapV3) {
                (address inToken, uint256 amount, uint256 minAmountOut, bytes memory path) = abi.decode(
                    data[i],
                    (address, uint256, uint256, bytes)
                );
                _swapOnUniswapV3(IERC20(inToken), amount, minAmountOut, path);
            } else if (actions[i] == ActionType.oneInch) {
                (address inToken, uint256 minAmountOut, bytes memory payload) = abi.decode(
                    data[i],
                    (address, uint256, bytes)
                );
                _swapOn1Inch(IERC20(inToken), minAmountOut, payload);
            } else if (actions[i] == ActionType.claimRewards) {
                (address user, address[] memory claimLiquidityGauges) = abi.decode(data[i], (address, address[]));
                _claimRewards(user, claimLiquidityGauges);
            } else if (actions[i] == ActionType.gaugeDeposit) {
                (address user, uint256 amount, address gauge, bool shouldClaimRewards) = abi.decode(
                    data[i],
                    (address, uint256, address, bool)
                );
                _gaugeDeposit(user, amount, ILiquidityGauge(gauge), shouldClaimRewards);
            } else if (actions[i] == ActionType.borrower) {
                (
                    address collateral,
                    address vaultManager,
                    address to,
                    address who,
                    ActionBorrowType[] memory actionsBorrow,
                    bytes[] memory dataBorrow,
                    bytes memory repayData
                ) = abi.decode(data[i], (address, address, address, address, ActionBorrowType[], bytes[], bytes));
                _parseVaultIDs(actionsBorrow, dataBorrow, vaultManager);
                _changeAllowance(IERC20(collateral), address(vaultManager), type(uint256).max);
                _angleBorrower(vaultManager, actionsBorrow, dataBorrow, to, who, repayData);
                _changeAllowance(IERC20(collateral), address(vaultManager), 0);
            } else if (actions[i] == ActionType.swapper) {
                (
                    ISwapper swapperContract,
                    IERC20 inToken,
                    IERC20 outToken,
                    address outTokenRecipient,
                    uint256 outTokenOwed,
                    uint256 inTokenObtained,
                    bytes memory payload
                ) = abi.decode(data[i], (ISwapper, IERC20, IERC20, address, uint256, uint256, bytes));
                _swapper(swapperContract, inToken, outToken, outTokenRecipient, outTokenOwed, inTokenObtained, payload);
            } else if (actions[i] == ActionType.mintSavingsRate) {
                (IERC20 token, IERC4626 savingsRate, uint256 shares, address to, uint256 maxAmountIn) = abi.decode(
                    data[i],
                    (IERC20, IERC4626, uint256, address, uint256)
                );
                _changeAllowance(token, address(savingsRate), maxAmountIn);
                _mintSavingsRate(savingsRate, shares, to, maxAmountIn);
                _changeAllowance(token, address(savingsRate), 0);
            } else if (actions[i] == ActionType.depositSavingsRate) {
                (IERC20 token, IERC4626 savingsRate, uint256 amount, address to, uint256 minSharesOut) = abi.decode(
                    data[i],
                    (IERC20, IERC4626, uint256, address, uint256)
                );
                _changeAllowance(token, address(savingsRate), amount);
                _depositSavingsRate(savingsRate, amount, to, minSharesOut);
            } else if (actions[i] == ActionType.redeemSavingsRate) {
                (IERC4626 savingsRate, uint256 shares, address to, uint256 minAmountOut) = abi.decode(
                    data[i],
                    (IERC4626, uint256, address, uint256)
                );
                _redeemSavingsRate(savingsRate, shares, to, minAmountOut);
            } else if (actions[i] == ActionType.withdrawSavingsRate) {
                (IERC4626 savingsRate, uint256 amount, address to, uint256 maxSharesOut) = abi.decode(
                    data[i],
                    (IERC4626, uint256, address, uint256)
                );
                _withdrawSavingsRate(savingsRate, amount, to, maxSharesOut);
            } else if (actions[i] == ActionType.prepareRedeemSavingsRate) {
                (ISavingsRateIlliquid savingsRate, uint256 amount, address to, uint256 minAmountOut) = abi.decode(
                    data[i],
                    (ISavingsRateIlliquid, uint256, address, uint256)
                );
                _prepareRedeemSavingsRate(savingsRate, amount, to, minAmountOut);
            } else if (actions[i] == ActionType.claimRedeemSavingsRate) {
                (ISavingsRateIlliquid savingsRate, address receiver, address[] memory strategiesToClaim) = abi.decode(
                    data[i],
                    (ISavingsRateIlliquid, address, address[])
                );
                _claimRedeemSavingsRate(savingsRate, receiver, strategiesToClaim);
            } else {
                _chainSpecificAction(actions[i], data[i]);
            }
        }
    }

    /// @notice Wrapper built on top of the base `mixer` function to grant approval to a `VaultManager` contract before performing
    /// actions and then revoking this approval after these actions
    /// @param paramsPermitVaultManager Parameters to sign permit to give allowance to the router for a `VaultManager` contract
    /// @dev In `paramsPermitVaultManager`, the signatures for granting approvals must be given first before the signatures
    /// to revoke approvals
    /// @dev The router contract has been built to be safe to keep approvals as you cannot take an action on a vault you are not
    /// approved for, but people wary about their approvals may want to grant it before immediately revoking it, although this
    /// is just an option
    function mixerVaultManagerPermit(
        PermitVaultManagerType[] memory paramsPermitVaultManager,
        PermitType[] memory paramsPermit,
        ActionType[] calldata actions,
        bytes[] calldata data
    ) external payable virtual {
        uint256 permitVaultManagerLength = paramsPermitVaultManager.length;
        for (uint256 i; i < permitVaultManagerLength; ++i) {
            if (paramsPermitVaultManager[i].approved) {
                IVaultManagerFunctions(paramsPermitVaultManager[i].vaultManager).permit(
                    paramsPermitVaultManager[i].owner,
                    address(this),
                    true,
                    paramsPermitVaultManager[i].deadline,
                    paramsPermitVaultManager[i].v,
                    paramsPermitVaultManager[i].r,
                    paramsPermitVaultManager[i].s
                );
            } else break;
        }
        mixer(paramsPermit, actions, data);
        // Storing the index at which starting the iteration for revoking approvals in a variable would make the stack
        // too deep
        for (uint256 i; i < permitVaultManagerLength; ++i) {
            if (!paramsPermitVaultManager[i].approved) {
                IVaultManagerFunctions(paramsPermitVaultManager[i].vaultManager).permit(
                    paramsPermitVaultManager[i].owner,
                    address(this),
                    false,
                    paramsPermitVaultManager[i].deadline,
                    paramsPermitVaultManager[i].v,
                    paramsPermitVaultManager[i].r,
                    paramsPermitVaultManager[i].s
                );
            }
        }
    }

    receive() external payable {}

    // ===================== INTERNAL ACTION-RELATED FUNCTIONS =====================

    /// @notice Wraps the native token of a chain to its wrapped version
    /// @dev It can be used for ETH to wETH or MATIC to wMATIC
    /// @dev The amount to wrap is to be specified in the `msg.value`
    function _wrapNative() internal virtual returns (uint256) {
        _getNativeWrapper().deposit{ value: msg.value }();
        return msg.value;
    }

    /// @notice Unwraps the wrapped version of a token to the native chain token
    /// @dev It can be used for wETH to ETH or wMATIC to MATIC
    function _unwrapNative(uint256 minAmountOut, address to) internal virtual returns (uint256 amount) {
        amount = _getNativeWrapper().balanceOf(address(this));
        _slippageCheck(amount, minAmountOut);
        if (amount != 0) {
            _getNativeWrapper().withdraw(amount);
            _safeTransferNative(to, amount);
        }
        return amount;
    }

    /// @notice Internal version of the `claimRewards` function
    /// @dev If the caller wants to send the rewards to another account than `gaugeUser`, it first needs to
    /// call `set_rewards_receiver(otherAccount)` on each `liquidityGauge`
    function _claimRewards(address gaugeUser, address[] memory liquidityGauges) internal virtual {
        uint256 gaugesLength = liquidityGauges.length;
        for (uint256 i; i < gaugesLength; ++i) {
            ILiquidityGauge(liquidityGauges[i]).claim_rewards(gaugeUser);
        }
    }

    /// @notice Allows to compose actions on a `VaultManager` (Angle Protocol Borrowing module)
    /// @param vaultManager Address of the vault to perform actions on
    /// @param actionsBorrow Actions type to perform on the vaultManager
    /// @param dataBorrow Data needed for each actions
    /// @param to Address to send the funds to
    /// @param who Swapper address to handle repayments
    /// @param repayData Bytes to use at the discretion of the `msg.sender`
    function _angleBorrower(
        address vaultManager,
        ActionBorrowType[] memory actionsBorrow,
        bytes[] memory dataBorrow,
        address to,
        address who,
        bytes memory repayData
    ) internal virtual returns (PaymentData memory paymentData) {
        return IVaultManagerFunctions(vaultManager).angle(actionsBorrow, dataBorrow, msg.sender, to, who, repayData);
    }

    /// @notice Allows to deposit tokens into a gauge
    /// @param user Address on behalf of which deposits should be made in the gauge
    /// @param amount Amount to stake
    /// @param gauge Liquidity gauge to stake in
    /// @param shouldClaimRewards Whether to claim or not previously accumulated rewards
    /// @dev You should be cautious on who will receive the rewards (if `shouldClaimRewards` is true)
    /// @dev The function will revert if the gauge has not already been approved by the contract
    function _gaugeDeposit(
        address user,
        uint256 amount,
        ILiquidityGauge gauge,
        bool shouldClaimRewards
    ) internal virtual {
        gauge.deposit(amount, user, shouldClaimRewards);
    }

    /// @notice Sweeps tokens from the router contract
    /// @param tokenOut Token to sweep
    /// @param minAmountOut Minimum amount of tokens to recover
    /// @param to Address to which tokens should be sent
    function _sweep(
        address tokenOut,
        uint256 minAmountOut,
        address to
    ) internal virtual {
        uint256 balanceToken = IERC20(tokenOut).balanceOf(address(this));
        _slippageCheck(balanceToken, minAmountOut);
        if (balanceToken != 0) {
            IERC20(tokenOut).safeTransfer(to, balanceToken);
        }
    }

    /// @notice Uses an external swapper
    /// @param swapper Contracts implementing the logic of the swap
    /// @param inToken Token used to do the swap
    /// @param outToken Token wanted
    /// @param outTokenRecipient Address who should have at the end of the swap at least `outTokenOwed`
    /// @param outTokenOwed Minimal amount for the `outTokenRecipient`
    /// @param inTokenObtained Amount of `inToken` used for the swap
    /// @param data Additional info for the specific swapper
    function _swapper(
        ISwapper swapper,
        IERC20 inToken,
        IERC20 outToken,
        address outTokenRecipient,
        uint256 outTokenOwed,
        uint256 inTokenObtained,
        bytes memory data
    ) internal {
        swapper.swap(inToken, outToken, outTokenRecipient, outTokenOwed, inTokenObtained, data);
    }

    /// @notice Allows to swap between tokens via UniswapV3 (if there is a path)
    /// @param inToken Token used as entrance of the swap
    /// @param amount Amount of in token to swap
    /// @param minAmountOut Minimum amount of outToken accepted for the swap to happen
    /// @param path Bytes representing the path to swap your input token to the accepted collateral
    function _swapOnUniswapV3(
        IERC20 inToken,
        uint256 amount,
        uint256 minAmountOut,
        bytes memory path
    ) internal returns (uint256 amountOut) {
        // Approve transfer to the `uniswapV3Router`
        // Since this router is supposed to be a trusted contract, we can leave the allowance to the token
        address uniRouter = address(uniswapV3Router);
        uint256 currentAllowance = IERC20(inToken).allowance(address(this), uniRouter);
        if (currentAllowance < amount)
            IERC20(inToken).safeIncreaseAllowance(uniRouter, type(uint256).max - currentAllowance);
        amountOut = IUniswapV3Router(uniRouter).exactInput(
            ExactInputParams(path, address(this), block.timestamp, amount, minAmountOut)
        );
    }

    /// @notice Swaps an inToken to another token via 1Inch Router
    /// @param payload Bytes needed for 1Inch router to process the swap
    /// @dev The `payload` given is expected to be obtained from 1Inch API
    function _swapOn1Inch(
        IERC20 inToken,
        uint256 minAmountOut,
        bytes memory payload
    ) internal returns (uint256 amountOut) {
        // Approve transfer to the `oneInch` address
        // Since this router is supposed to be a trusted contract, we can leave the allowance to the token
        address oneInchRouter = oneInch;
        _changeAllowance(IERC20(inToken), oneInchRouter, type(uint256).max);
        //solhint-disable-next-line
        (bool success, bytes memory result) = oneInchRouter.call(payload);
        if (!success) _revertBytes(result);

        amountOut = abi.decode(result, (uint256));
        _slippageCheck(amountOut, minAmountOut);
    }

    /// @notice Mints `shares` from an ERC4626 `SavingsRate` contract
    /// @param savingsRate ERC4626 `SavingsRate` to mint shares from
    /// @param shares Amount of shares to mint from `savingsRate`
    /// @param to Address to which shares should be sent
    /// @param maxAmountIn Max amount of assets used to mint
    /// @return amountIn Amount of assets used to mint by `to`
    function _mintSavingsRate(
        IERC4626 savingsRate,
        uint256 shares,
        address to,
        uint256 maxAmountIn
    ) internal returns (uint256 amountIn) {
        // This check is useless as the contract needs to approve an amount and it will revert
        // anyway if more than `maxAmountIn` is used
        // We let it just in case we call this function outside of the mixer
        _slippageCheck(maxAmountIn, (amountIn = savingsRate.mint(shares, to)));
    }

    /// @notice Deposits `amount` to an ERC4626 `SavingsRate` contract
    /// @param savingsRate The ERC4626 `SavingsRate` to deposit assets to
    /// @param amount Amount of assets to deposit
    /// @param to Address to which shares should be sent
    /// @param minSharesOut Minimum amount of `SavingsRate` shares that `to` should received
    /// @return sharesOut Amount of shares received by `to`
    function _depositSavingsRate(
        IERC4626 savingsRate,
        uint256 amount,
        address to,
        uint256 minSharesOut
    ) internal returns (uint256 sharesOut) {
        _slippageCheck(sharesOut = savingsRate.deposit(amount, to), minSharesOut);
    }

    /// @notice Withdraws `amount` from an ERC4626 `SavingsRate` contract
    /// @param savingsRate ERC4626 `SavingsRate` to withdraw assets from
    /// @param amount Amount of assets to withdraw
    /// @param to Destination of assets
    /// @param maxSharesOut Maximum amount of shares that should be burnt in the operation
    /// @return sharesOut Amount of shares burnt
    function _withdrawSavingsRate(
        IERC4626 savingsRate,
        uint256 amount,
        address to,
        uint256 maxSharesOut
    ) internal returns (uint256 sharesOut) {
        _slippageCheck(maxSharesOut, sharesOut = savingsRate.withdraw(amount, to, msg.sender));
    }

    /// @notice Redeems `shares` from an ERC4626 `SavingsRate` contract
    /// @param savingsRate ERC4626 `SavingsRate` to redeem shares from
    /// @param shares Amount of shares to redeem
    /// @param to Destination of assets
    /// @param minAmountOut Minimum amount of assets that `to` should receive in the redemption process
    /// @return amountOut Amount of assets received by `to`
    function _redeemSavingsRate(
        IERC4626 savingsRate,
        uint256 shares,
        address to,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        _slippageCheck(amountOut = savingsRate.redeem(shares, to, msg.sender), minAmountOut);
    }

    /// @notice Processes the redemption of `shares` shares from an ERC4626 `SavingsRate` contract with
    /// potentially illiquid strategies
    /// @param savingsRate ERC4626 `SavingsRate` to redeem shares from
    /// @param shares Amount of shares to redeem
    /// @param to Destination of assets
    /// @param minAmountOut Minimum amount of assets that `to` should receive in the transaction
    /// @return amountOut Amount of assets received by `to`
    /// @dev Note that when calling this function the user does not have the guarantee that all shares
    /// will be immediately processed and some shares may be leftover to claim
    /// @dev If `to` is the router address, if there are leftover funds that cannot be immediately claimed in the
    /// transaction then they will be lost, meaning that anyone will be able to claim them
    function _prepareRedeemSavingsRate(
        ISavingsRateIlliquid savingsRate,
        uint256 shares,
        address to,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        _slippageCheck(amountOut = savingsRate.prepareRedeem(shares, to, msg.sender), minAmountOut);
    }

    /// @notice Claims assets from previously shares previously sent by `receiver` to the
    /// `ssavingsRate` contract
    /// @return amountOut Amount of assets obtained during the claim
    function _claimRedeemSavingsRate(
        ISavingsRateIlliquid savingsRate,
        address receiver,
        address[] memory strategiesToClaim
    ) internal returns (uint256 amountOut) {
        return savingsRate.claimRedeem(receiver, strategiesToClaim);
    }

    /// @notice Allows to perform some specific actions for a chain
    function _chainSpecificAction(ActionType action, bytes calldata data) internal virtual {}

    // ======================= VIRTUAL FUNCTIONS TO OVERRIDE =======================

    /// @notice Gets the official wrapper of the native token on a chain (like wETH on Ethereum)
    function _getNativeWrapper() internal pure virtual returns (IWETH9);

    // ============================ GOVERNANCE FUNCTION ============================

    /// @notice Checks whether the `msg.sender` has the governor role or the guardian role
    modifier onlyGovernorOrGuardian() {
        if (!core.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Sets a new `core` contract
    function setCore(ICoreBorrow _core) external {
        if (!core.isGovernor(msg.sender) || !_core.isGovernor(msg.sender)) revert NotGovernor();
        core = ICoreBorrow(_core);
    }

    /// @notice Changes allowances for different tokens
    /// @param tokens Addresses of the tokens to allow
    /// @param spenders Addresses to allow transfer
    /// @param amounts Amounts to allow
    function changeAllowance(
        IERC20[] calldata tokens,
        address[] calldata spenders,
        uint256[] calldata amounts
    ) external onlyGovernorOrGuardian {
        uint256 tokensLength = tokens.length;
        if (tokensLength != spenders.length || tokensLength != amounts.length) revert IncompatibleLengths();
        for (uint256 i; i < tokensLength; ++i) {
            _changeAllowance(tokens[i], spenders[i], amounts[i]);
        }
    }

    /// @notice Sets a new router variable
    function setRouter(address router, uint8 who) external onlyGovernorOrGuardian {
        if (router == address(0)) revert ZeroAddress();
        if (who == 0) uniswapV3Router = IUniswapV3Router(router);
        else oneInch = router;
    }

    // ========================= INTERNAL UTILITY FUNCTIONS ========================

    /// @notice Changes allowance of this contract for a given token
    /// @param token Address of the token to change allowance
    /// @param spender Address to change the allowance of
    /// @param amount Amount allowed
    function _changeAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(spender, amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(spender, currentAllowance - amount);
        }
    }

    /// @notice Transfer amount of the native token to the `to` address
    /// @dev Forked from Solmate: https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol
    function _safeTransferNative(address to, uint256 amount) internal {
        bool success;
        //solhint-disable-next-line
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!success) revert TransferFailed();
    }

    /// @notice Parses the actions submitted to the router contract to interact with a `VaultManager` and makes sure that
    /// the calling address is well approved for all the vaults with which it is interacting
    /// @dev If such check was not made, we could end up in a situation where an address has given an approval for all its
    /// vaults to the router contract, and another address takes advantage of this to instruct actions on these other vaults
    /// to the router: it is hence super important for the router to pay attention to the fact that the addresses interacting
    /// with a vault are approved for this vault
    function _parseVaultIDs(
        ActionBorrowType[] memory actionsBorrow,
        bytes[] memory dataBorrow,
        address vaultManager
    ) internal view {
        uint256 actionsBorrowLength = actionsBorrow.length;
        if (actionsBorrowLength >= _MAX_BORROW_ACTIONS) revert IncompatibleLengths();
        // The amount of vaults to check cannot be bigger than the maximum amount of tokens
        // supported
        uint256[_MAX_BORROW_ACTIONS] memory vaultIDsToCheckOwnershipOf;
        bool createVaultAction;
        uint256 lastVaultID;
        uint256 vaultIDLength;
        for (uint256 i; i < actionsBorrowLength; ++i) {
            uint256 vaultID;
            // If there is a `createVault` action, the router should not worry about looking at
            // next vaultIDs given equal to 0
            if (actionsBorrow[i] == ActionBorrowType.createVault) {
                createVaultAction = true;
                continue;
                // There are then different ways depending on the action to find the `vaultID`
            } else if (
                actionsBorrow[i] == ActionBorrowType.removeCollateral || actionsBorrow[i] == ActionBorrowType.borrow
            ) {
                (vaultID, ) = abi.decode(dataBorrow[i], (uint256, uint256));
            } else if (actionsBorrow[i] == ActionBorrowType.closeVault) {
                vaultID = abi.decode(dataBorrow[i], (uint256));
            } else if (actionsBorrow[i] == ActionBorrowType.getDebtIn) {
                (vaultID, , , ) = abi.decode(dataBorrow[i], (uint256, address, uint256, uint256));
            } else continue;
            // If we need to add a null `vaultID`, we look at the `vaultIDCount` in the `VaultManager`
            // if there has not been any specific action
            if (vaultID == 0) {
                if (createVaultAction) {
                    continue;
                } else {
                    // If we haven't stored the last `vaultID`, we need to fetch it
                    if (lastVaultID == 0) {
                        lastVaultID = IVaultManagerStorage(vaultManager).vaultIDCount();
                    }
                    vaultID = lastVaultID;
                }
            }

            // Check if this `vaultID` has already been verified
            for (uint256 j; j < vaultIDLength; ++j) {
                if (vaultIDsToCheckOwnershipOf[j] == vaultID) {
                    // If yes, we continue to the next iteration
                    continue;
                }
            }
            // Verify this new vaultID and add it to the list
            if (!IVaultManagerFunctions(vaultManager).isApprovedOrOwner(msg.sender, vaultID)) {
                revert NotApprovedOrOwner();
            }
            vaultIDsToCheckOwnershipOf[vaultIDLength] = vaultID;
            vaultIDLength += 1;
        }
    }

    /// @notice Checks whether the amount obtained during a swap is not too small
    function _slippageCheck(uint256 amount, uint256 thresholdAmount) internal pure {
        if (amount < thresholdAmount) revert TooSmallAmountOut();
    }

    /// @notice Internal function used for error handling
    function _revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length != 0) {
            //solhint-disable-next-line
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }
        revert InvalidReturnMessage();
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IPoolManager {
    function token() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title Interface of the contract managing perpetuals with claim function
/// @author Angle Core Team
/// @dev Front interface with rewards function, meaning only user-facing functions
interface IPerpetualManagerFrontWithClaim {
    function getReward(uint256 perpetualID) external;

    function addToPerpetual(uint256 perpetualID, uint256 amount) external;

    function openPerpetual(
        address owner,
        uint256 amountBrought,
        uint256 amountCommitted,
        uint256 maxOracleRate,
        uint256 minNetMargin
    ) external returns (uint256 perpetualID);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
}

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router {
    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

/// @title Router for price estimation functionality
/// @notice Functions for getting the price of one token with respect to another using Uniswap V2
/// @dev This interface is only used for non critical elements of the protocol
interface IUniswapV2Router {
    /// @notice Given an input asset amount, returns the maximum output amount of the
    /// other asset (accounting for fees) given reserves.
    /// @param path Addresses of the pools used to get prices
    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 swapAmount,
        uint256 minExpected,
        address[] calldata path,
        address receiver,
        uint256 swapDeadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title ICoreBorrow
/// @author Angle Core Team
/// @notice Interface for the `CoreBorrow` contract

interface ICoreBorrow {
    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface ILiquidityGauge {
    // solhint-disable-next-line
    function staking_token() external returns (address stakingToken);

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    function deposit(
        uint256 _value,
        address _addr,
        // solhint-disable-next-line
        bool _claim_rewards
    ) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr) external;

    // solhint-disable-next-line
    function claim_rewards(address _addr, address _receiver) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title ISavingsRateIlliquid
/// @author Angle Core Team
/// @notice Interface for Angle's `SavingsRateIlliquid` contracts
interface ISavingsRateIlliquid {
    function claimRedeem(address receiver, address[] memory strategiesToClaim) external returns (uint256 totalOwed);

    function prepareRedeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

/// @title ISwapper
/// @author Angle Core Team
/// @notice Interface for a generic swapper, that supports swaps of higher complexity than aggregators
interface ISwapper {
    function swap(
        IERC20 inToken,
        IERC20 outToken,
        address outTokenRecipient,
        uint256 outTokenOwed,
        uint256 inTokenObtained,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITreasury.sol";

// ========================= Key Structs and Enums =============================

/// @notice Data to track during a series of action the amount to give or receive in stablecoins and collateral
/// to the caller or associated addresses
struct PaymentData {
    // Stablecoin amount the contract should give
    uint256 stablecoinAmountToGive;
    // Stablecoin amount owed to the contract
    uint256 stablecoinAmountToReceive;
    // Collateral amount the contract should give
    uint256 collateralAmountToGive;
    // Collateral amount owed to the contract
    uint256 collateralAmountToReceive;
}

/// @notice Data stored to track someone's loan (or equivalently called position)
struct Vault {
    // Amount of collateral deposited in the vault
    uint256 collateralAmount;
    // Normalized value of the debt (that is to say of the stablecoins borrowed)
    uint256 normalizedDebt;
}

/// @notice Actions possible when composing calls to the different entry functions proposed
enum ActionBorrowType {
    createVault,
    closeVault,
    addCollateral,
    removeCollateral,
    repayDebt,
    borrow,
    getDebtIn,
    permit
}

// ========================= Interfaces =============================

/// @title IVaultManagerFunctions
/// @author Angle Core Team
/// @notice Interface for the `VaultManager` contract
/// @dev This interface only contains functions of the contract which are called by other contracts
/// of this module (without getters)
interface IVaultManagerFunctions {
    /// @notice Allows composability between calls to the different entry points of this module. Any user calling
    /// this function can perform any of the allowed actions in the order of their choice
    /// @param actions Set of actions to perform
    /// @param datas Data to be decoded for each action: it can include like the `vaultID` or the
    /// @param from Address from which stablecoins will be taken if one action includes burning stablecoins. This address
    /// should either be the `msg.sender` or be approved by the latter
    /// @param to Address to which stablecoins and/or collateral will be sent in case of
    /// @return paymentData Struct containing the final transfers executed
    /// @dev This function is optimized to reduce gas cost due to payment from or to the user and that expensive calls
    /// or computations (like `oracleValue`) are done only once
    function angle(
        ActionBorrowType[] memory actions,
        bytes[] memory datas,
        address from,
        address to
    ) external payable returns (PaymentData memory paymentData);

    /// @notice Allows composability between calls to the different entry points of this module. Any user calling
    /// this function can perform any of the allowed actions in the order of their choice
    /// @param actions Set of actions to perform
    /// @param datas Data to be decoded for each action: it can include like the `vaultID` or the
    /// @param from Address from which stablecoins will be taken if one action includes burning stablecoins. This address
    /// should either be the `msg.sender` or be approved by the latter
    /// @param to Address to which stablecoins and/or collateral will be sent in case of
    /// @param who Address of the contract to handle in case of repayment of stablecoins from received collateral
    /// @param repayData Data to pass to the repayment contract in case of
    /// @return paymentData Struct containing the final transfers executed
    /// @dev This function is optimized to reduce gas cost due to payment from or to the user and that expensive calls
    /// or computations (like `oracleValue`) are done only once
    function angle(
        ActionBorrowType[] memory actions,
        bytes[] memory datas,
        address from,
        address to,
        address who,
        bytes memory repayData
    ) external payable returns (PaymentData memory paymentData);

    /// @notice Checks whether a given address is approved for a vault or owns this vault
    /// @param spender Address for which vault ownership should be checked
    /// @param vaultID ID of the vault to check
    /// @return Whether the `spender` address owns or is approved for `vaultID`
    function isApprovedOrOwner(address spender, uint256 vaultID) external view returns (bool);

    /// @notice Allows an address to give or revoke approval for all its vaults to another address
    /// @param owner Address signing the permit and giving (or revoking) its approval for all the controlled vaults
    /// @param spender Address to give approval to
    /// @param approved Whether to give or revoke the approval
    /// @param deadline Deadline parameter for the signature to be valid
    /// @dev The `v`, `r`, and `s` parameters are used as signature data
    function permit(
        address owner,
        address spender,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

/// @title IVaultManagerStorage
/// @author Angle Core Team
/// @notice Interface for the `VaultManager` contract
/// @dev This interface contains getters of the contract's public variables used by other contracts
/// of this module
interface IVaultManagerStorage {
    /// @notice Reference to the `treasury` contract handling this `VaultManager`
    function treasury() external view returns (ITreasury);

    /// @notice Reference to the collateral handled by this `VaultManager`
    function collateral() external view returns (IERC20);

    /// @notice ID of the last vault created. The `vaultIDCount` variables serves as a counter to generate a unique
    /// `vaultID` for each vault: it is like `tokenID` in basic ERC721 contracts
    function vaultIDCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

/// @title ITreasury
/// @author Angle Core Team
/// @notice Interface for the `Treasury` contract
/// @dev This interface only contains functions of the `Treasury` which are called by other contracts
/// of this module
interface ITreasury {
    /// @notice Checks whether a given address has well been initialized in this contract
    /// as a `VaultManager``
    /// @param _vaultManager Address to check
    /// @return Whether the address has been initialized or not
    function isVaultManager(address _vaultManager) external view returns (bool);
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