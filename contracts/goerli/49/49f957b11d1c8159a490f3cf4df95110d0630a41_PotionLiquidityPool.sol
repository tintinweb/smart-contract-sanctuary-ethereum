/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.4;

import { ICurveManager } from "./interfaces/ICurveManager.sol";
import { ICriteriaManager } from "./interfaces/ICriteriaManager.sol";
import { ControllerInterface } from "./packages/opynInterface/OpynControllerInterface.sol";
import { OtokenInterface } from "./packages/opynInterface/OtokenInterface.sol";
import { OtokenFactoryInterface } from "./packages/opynInterface/OtokenFactoryInterface.sol";
import { Actions } from "./packages/opynInterface/ActionsInterface.sol";
import { AddressBookInterface } from "./packages/opynInterface/AddressBookInterface.sol";
import { WhitelistInterface } from "./packages/opynInterface/WhitelistInterface.sol";
import { OracleInterface } from "./packages/opynInterface/OracleInterface.sol";
import { FixedPointInt256 as FPI } from "./packages/opynInterface/FixedPointInt256.sol";
import { OpynActionsLibrary as ActionsLib } from "./OpynActionsLibrary.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IERC20MetadataUpgradeable as ERC20Interface } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { PRBMathSD59x18 } from "./packages/PRBMathSD59x18.sol";

/**
 * @title PotionLiquidityPool
 * @notice It allows LPs to deposit, withdraw and configure Pools Of Capital. Buyer can buy OTokens.
 */
contract PotionLiquidityPool is PausableUpgradeable, OwnableUpgradeable {
    // This contract performs significant fixed point arithmetic, and uses TWO DIFFERENT maths libraries for that:
    // 1. Whenever we do a calculation that involves an exchange rate (e.g. the ETH price denominated in USDC) we use the same
    //    library as Opyn. This is so that we can more easily compare our code and results to Opyn's, and perhaps replace our
    //    code with theirs if/when they extend their public interfaces.
    // 2. For our more complex premium calculation logic, we make use of the more powerful PRBMathSD59x18 library. This handles
    //    exponentials and logarithms for us. We also use it for util calculations, because utilisations are used as input in
    //    premium calculations.
    using FPI for FPI.FixedPointInt;
    using PRBMathSD59x18 for int256;
    using SafeERC20 for IERC20;

    /// @dev Strike prices from an otoken contract are expressed with 8 decimals
    uint256 internal constant STRIKE_PRICE_DECIMALS = 8;
    /// @dev Oracle prices are always expressed with 8 decimals
    uint256 internal constant ORACLE_PRICE_DECIMALS = 8;
    /// @dev The otoken (ERC20) that tracks option ownership uses 8 decimals for token quantities
    uint256 internal constant OTOKEN_QTY_DECIMALS = 8;

    /// @dev Seconds per day required for calculating option duration in days
    uint256 internal constant SECONDS_IN_A_DAY = 86400;

    /// @dev Max int size for max tvl validation
    uint256 internal constant MAX_INT = 2**256 - 1;

    /**
     * @notice Initialize this implementation contract
     * @dev Function initializer for the upgradeable proxy.
     * @param _opynAddressBook The address of the OpynAddressBook contract.
     * @param _poolCollateralToken The address of the collateral used in this contract.
     * @param _curveManager The address of the CurveManager contract.
     * @param _criteriaManager The address of the CriteriaManager contract.
     */
    function initialize(
        address _opynAddressBook,
        address _poolCollateralToken,
        address _curveManager,
        address _criteriaManager
    ) external initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        sumOfAllUnlockedBalances = 0;
        sumOfAllLockedBalances = 0;
        maxTotalValueLocked = MAX_INT;
        // We interact with multiple Opyn contracts, but each time we do so we go through the
        // Opyn addressbook contrac to identify the address we want to interact with. This means we are
        // robust to the opyn system being upgraded, provided the addressbook remains constant.
        opynAddressBook = AddressBookInterface(_opynAddressBook);

        // One exception: Opyn's addressbook deploys an upgradable proxy in front of its Controller contract, and upgades
        // that proxy to change the controller. As such we save the proxy address here, and avoid the need
        // to go through the addressbook to get to the controller. This saves some gas.
        opynController = ControllerInterface(opynAddressBook.getController());
        vaultCount = opynController.getAccountVaultCounter(address(this));
        poolCollateralToken = IERC20(_poolCollateralToken);
        crv = ICurveManager(_curveManager);
        crit = ICriteriaManager(_criteriaManager);
    }

    ///////////////////////////////////////////////////////////////////////////
    //  Events
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Emits when an LP deposits (initially unlocked) funds into Potion.
    event Deposited(address indexed lp, uint256 indexed poolId, uint256 amount);

    /// @notice Emits when an LP withdraws unlocked funds from Potion.
    event Withdrawn(address indexed lp, uint256 indexed poolId, uint256 amount);

    /// @notice Emits when an LP associates a set of crtieria with a pool of their capital.
    event CriteriaSetSelected(address indexed lp, uint256 indexed poolId, bytes32 criteriaSetHash);

    /// @notice Emits when an LP associates a pricing curve with a pool of their capital.
    event CurveSelected(address indexed lp, uint256 indexed poolId, bytes32 curveHash);

    /// @notice Emits once per purchase, with details of the buyer and the aggregate figures involved.
    event OptionsBought(
        address indexed buyer,
        address indexed otoken,
        uint256 numberOfOtokens,
        uint256 totalPremiumPaid
    );

    /// @notice Emits for every LP involved in collateralizing a purchase, with details of the LP and the figures involved in their part of the purchase.
    event OptionsSold(
        address indexed lp,
        uint256 indexed poolId,
        address indexed otoken,
        bytes32 curveHash,
        uint256 numberOfOtokens,
        uint256 liquidityCollateralized,
        uint256 premiumReceived
    );

    /// @notice Emits when all collateral for a given otoken (which must have reached expiry) is reclaimed from the Opyn contracts, into this Potion contract.
    event OptionSettled(address indexed otoken, uint256 collateralReturned);

    /// @notice Emits every time that some collateral (preciously reclaimed from the Opyn conracts into this Potion contract) is redistributed to one of the collateralising LPs.
    event OptionSettlementDistributed(
        address indexed otoken,
        address indexed lp,
        uint256 indexed poolId,
        uint256 collateralReturned
    );

    ///////////////////////////////////////////////////////////////////////////
    //  Structs and vars
    ///////////////////////////////////////////////////////////////////////////

    /// @dev A VaultInfo contains the data about a single Opyn Vault.
    struct VaultInfo {
        uint256 vaultId; // the vault's ID in Opyn's contracts. Valid vaultIDs start at 1, so this can be used as an existence check in a map
        uint256 totalContributions; // The total contributed to the vault by Potion LPs, denominated in collateral tokens
        bool settled; // Whether the vault has been settled. That is, whether the unused collateral has, after otoken expiry, been reclaimed from the Opyn contracts into this contract
        uint256 settledAmount; // The amount of unused collateral that was reclaimed from the Opyn contracts upon settlement
        mapping(address => mapping(uint256 => uint256)) contributionsByLp; // The vault contributions, denominated in collateral tokens, indexed by LP and then by the LP's poolId
    }

    /// @dev The keys required to identify a given pool of capital in the lpPools map.
    struct PoolIdentifier {
        address lp;
        uint256 poolId;
    }

    /// @dev The data associated with a given pool of capital, belonging to one LP
    struct PoolOfCapital {
        uint256 total; // The total (locked or unlocked) of capital in the pool, denominated in collateral tokens
        uint256 locked; // The locked capital in the pool, denominated in collateral tokens
        bytes32 curveHash; // Identifies the curve to use when pricing the premiums charged for any otokens sold (& collateralizated) by this pool
        bytes32 criteriaSetHash; // Identifies the set of otokens that this pool is willing to sell (& collateralize)
    }

    /// @dev The counterparty data associated with a given (tranche of an) otoken purchase. For gas efficiency reasons, the buyer must pass in details of the curve and criteria, and these are verified as a match (rather than calculated) on-chain
    struct CounterpartyDetails {
        address lp; // The LP to buy from
        uint256 poolId; // The pool (belonging to LP) that will colalteralize the otoken
        ICurveManager.Curve curve; // The curve used to calculate the otoken premium
        ICriteriaManager.Criteria criteria; // The criteria associated with this curve, which matches the otoken
        uint256 orderSizeInOtokens; // The number of otokens to buy from this particular counterparty
    }

    /// @dev Used only internally, in memory, to track aggregate values across an order involving multiple LPs. This reduces the number of local variables and thereby avoids a "stack too deep" error at compile time.
    struct AggregateOrderData {
        uint256 premium;
        uint256 collateral;
        uint256 orderSize;
    }

    /// @dev Used only internally, in memory, to track parameters involved in calculating collateral requirements. This reduces the number of local variables and thereby avoids a "stack too deep" error at compile time.
    struct CollateralCalculationParams {
        bool collateralMatchesStrike; // true iff the collateral asset and the strike asset are the same (this simplifies the calculation)
        FPI.FixedPointInt strikePrice; // The strike asset price returned by the oracle, in the FixedPointInt representation of decimal numbers
        FPI.FixedPointInt collateralPrice; // The collateral asset price returned by the oracle, in the FixedPointInt representation of decimal numbers
        FPI.FixedPointInt otokenStrikeHumanReadable; // The strike price denominated in strike tokens, in human readable notation (e.g. if strike = 300USDC, this is "300.0" not "300000000"
        uint256 collateralTokenDecimals; // The number of decimals used by the collateral token (may differ from the strike token)
    }

    ///////////////////////////////////////////////////////////////////////////
    //  Contract state
    ///////////////////////////////////////////////////////////////////////////

    /// @dev The maximum value (denominated in collateral tokens) that can be custodied by this contract, or by Opyn on behalf of this contract
    // (i.e. including locked and unlocked balances across all pools of capital).
    uint256 public maxTotalValueLocked;

    /// @dev The number of Opyn vaults that this contract has ever opened
    uint256 public vaultCount;

    /// @dev One Potion vault per token, indexed by otoken address. We know that this map only contains entries for whitelisted (or previously whitelisted) otokens, because we check before creating entries.
    mapping(address => VaultInfo) internal vaults;

    /// @dev Data about pools of capital, indexed first by LP address and then by an (arbitrary) numeric poolId
    mapping(address => mapping(uint256 => PoolOfCapital)) public lpPools;

    /// @dev The aggregate amount of capital currently unlocked in this contract by LPs. Denominated in collateral tokens. This is used for some safety checks, and could theoretically be removed at a later date to reduce gas costs.
    uint256 public sumOfAllUnlockedBalances;

    /// @dev The aggregate amount of capital currently deposited locked in this contract by LPs. Denominated in collateral tokens. This is used for some safety checks, and could theoretically be removed at a later date to reduce gas costs.
    uint256 public sumOfAllLockedBalances;

    // All Opyn contracts are trusted => we assume there is no malicious code within Opyn contracts.
    /// @dev If we want to interact with the Opyn Controller, we already know the address of its transparent proxy. This contract is trusted.
    ControllerInterface public opynController;
    /// @dev If we want to interact with any other Opyn contract, we look up its address in the addressbook. All Opyn contracts are trusted.
    AddressBookInterface public opynAddressBook;

    /// @dev The curve manager is used to manage curves, and curve hashes, and the calculation of prices based on curves.
    ICurveManager public crv;

    /// @dev The criteria manager is used to manage criteria, and sets of criteria, and hashes thereof
    ICriteriaManager public crit;

    /// @dev Currently we support only a single token as collateral. The easiest route to supporting multiple types of collateral may be multiple instances of the PotionLiquidityPool contract. The collateral token is chosen carefully and is therefore probably to be trusted, but we nevertheless attempt to interact with it at the _end_ of each transaction to reduce the scope for re-entrancy attacks!
    IERC20 public poolCollateralToken;

    ///////////////////////////////////////////////////////////////////////////
    //  Admin (owner) functions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Set the total max value locked per user in a Pool of Capital.
     * @param _newMax The new total max value locked.
     */
    function setMaxTotalValueLocked(uint256 _newMax) external onlyOwner whenNotPaused {
        maxTotalValueLocked = _newMax;
    }

    /**
     * @notice Allows the admin to pause the whole system
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @notice Allows the admin to unpause the whole system
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Update the contract used to manage curves, and curve hashes, and the calculation of prices based on curves
     * @dev To ensure continued operation for all users, any new CurveManager must be pre-populated with the same data as the existing CurveManager (for reasons of gas efficiency, we do not use an upgradable proxy mechanism)
     * @dev The `CurveManager` can be changed while paused, in case this is required to address security issues
     * @param _new The new address of the CurveManager
     */
    function setCurveManager(ICurveManager _new) external onlyOwner {
        crv = _new;
    }

    /**
     * @notice Update the contract used to manage criteria, and sets of criteria, and hashes thereof
     * @dev Note To ensure continued operation for all users, any new CriteriaManager must be pre-populated with the same data as the existing CriteriaManager (for reasons of gas efficiency, we do not use an upgradable proxy mechanism)
     * @dev The `CriteriaManager` can be changed while paused, in case this is required to address security issues
     * @param _new The new address of the CriteriaManager
     */
    function setCriteriaManager(ICriteriaManager _new) external onlyOwner {
        crit = _new;
    }

    ///////////////////////////////////////////////////////////////////////////
    //  Getters & view functions
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Get the ID of the existing Opyn vault that Potion uses to collateralize a given OToken.
     * @param _otoken The identifier (token contract address) of the OToken. Not checked for validity in this view function.
     * @return The unique ID of the vault, > 0. If no vault exists, the returned value will be 0
     */
    function getVaultId(OtokenInterface _otoken) public view returns (uint256) {
        return vaults[address(_otoken)].vaultId;
    }

    /**
     * @notice Query the locked capital in a specified pool of capital
     * @dev _poolId is generated in the client side.
     * @param _lp The address of the liquidity provider.
     * @param _poolId An (LP-specific) pool identifier.
     * @return The amount of capital locked in the pool, denominated in collateral tokens.
     */
    function lpLockedAmount(address _lp, uint256 _poolId) external view returns (uint256) {
        return lpPools[_lp][_poolId].locked;
    }

    /**
     * @notice Query the total capital (locked + unlocked) in a specified pool of capital.
     * @param _lp The address of the liquidity provider.
     * @param _poolId An (LP-specific) pool identifier.
     * @return The amount of capital in the pool, denominated in collateral tokens.
     */
    function lpTotalAmount(address _lp, uint256 _poolId) external view returns (uint256) {
        return lpPools[_lp][_poolId].total;
    }

    /**
     * @notice The amount of capital required to collateralize a given quantitiy of a given OToken.
     * @param _otoken The identifier (token contract address) of the OToken to be collateralized. Not checked for validity in this view function.
     * @param _otokenQty The number of OTokens we wish to collateralize.
     * @return The amount of collateral required, denominated in collateral tokens.
     */
    function collateralNeededForPuts(OtokenInterface _otoken, uint256 _otokenQty) external view returns (uint256) {
        CollateralCalculationParams memory collateralCalcParams;
        (address collateralAsset, , address strikeAsset, uint256 strikePrice, , ) = _otoken.getOtokenDetails();
        (
            collateralCalcParams.collateralMatchesStrike,
            collateralCalcParams.strikePrice,
            collateralCalcParams.collateralPrice
        ) = _getLivePrices(strikeAsset, collateralAsset);
        collateralCalcParams.otokenStrikeHumanReadable = FPI.fromScaledUint(strikePrice, OTOKEN_QTY_DECIMALS);
        collateralCalcParams.collateralTokenDecimals = ERC20Interface(collateralAsset).decimals();
        return _collateralNeededForPuts(_otokenQty, collateralCalcParams);
    }

    /**
     * @notice Calculate the premiums for a particular OToken from the provided sellers.
     * @param _otoken The `OToken` for which we calculate the premium charged for a purchase. This is not checked for validity in this view function, nor is it checked for compatibility with sellers.
     * @param _sellers The details of the counterparties and counterparty pricing, for which we calculate the premiums. These are assumed (not checked) to be compatibile with the `Otoken`.
     * @return totalPremiumInCollateralTokens The total premium in collateral tokens.
     * @return perLpPremiumsInCollateralTokens The premiums per LP in collateral tokens, ordered in the same way as the `_sellers` param.
     */
    function premiums(OtokenInterface _otoken, CounterpartyDetails[] memory _sellers)
        external
        view
        returns (uint256 totalPremiumInCollateralTokens, uint256[] memory perLpPremiumsInCollateralTokens)
    {
        perLpPremiumsInCollateralTokens = new uint256[](_sellers.length);

        (address collateralAsset, , address strikeAsset, uint256 strikePrice, , ) = _otoken.getOtokenDetails();
        CollateralCalculationParams memory collateralCalcParams;
        (
            collateralCalcParams.collateralMatchesStrike,
            collateralCalcParams.strikePrice,
            collateralCalcParams.collateralPrice
        ) = _getLivePrices(strikeAsset, collateralAsset);
        collateralCalcParams.otokenStrikeHumanReadable = FPI.fromScaledUint(strikePrice, OTOKEN_QTY_DECIMALS);
        collateralCalcParams.collateralTokenDecimals = ERC20Interface(collateralAsset).decimals();

        // This loop is unbounded. If it runs outof gas that's because the buyer is trying to buy from too many different pools
        // It is the responsibility of the router to not route buyers to too many pools in a singel transaction
        for (uint256 i = 0; i < _sellers.length; i++) {
            CounterpartyDetails memory seller = _sellers[i];
            uint256 collateralRequired = _collateralNeededForPuts(seller.orderSizeInOtokens, collateralCalcParams);
            uint256 premium = _premiumForLp(seller.lp, seller.poolId, seller.curve, collateralRequired);
            perLpPremiumsInCollateralTokens[i] = premium;
            totalPremiumInCollateralTokens = totalPremiumInCollateralTokens + premium;
        }
        return (totalPremiumInCollateralTokens, perLpPremiumsInCollateralTokens);
    }

    /**
     * @notice Calculates the utilization before and after locking new collateral amount.
     * @param _lp The address of the liquidity provider.
     * @param _poolId An (LP-specific) pool identifier.
     * @param _collateralToLock The amount of collateral to lock.
     * @return utilBeforeAs59x18 Utilization before locking the collateral specified.
     * @return utilAfterAs59x18 Utilization after locking the collateral specified.
     * @return lockedAmountBefore The total collateral locked before locking the collateral specified.
     * @return lockedAmountAfter The total collateral locked after locking the collateral specified.
     */
    function util(
        address _lp,
        uint256 _poolId,
        uint256 _collateralToLock
    )
        public
        view
        returns (
            int256 utilBeforeAs59x18,
            int256 utilAfterAs59x18,
            uint256 lockedAmountBefore,
            uint256 lockedAmountAfter
        )
    {
        PoolOfCapital storage bal = lpPools[_lp][_poolId];
        lockedAmountBefore = bal.locked;
        lockedAmountAfter = bal.locked + _collateralToLock;
        require(lockedAmountAfter <= bal.total, "util calc: >100% locked");
        require(bal.total > 0, "util calc: 0 balance");

        // Note that the use of fromUint here implies a max total balance in any pool of ~5.8e+58 wei.
        // This is 5.8e+40 human units if the collateral token uses 18 decimals
        utilBeforeAs59x18 = PRBMathSD59x18.fromUint(lockedAmountBefore).div(PRBMathSD59x18.fromUint(bal.total));
        utilAfterAs59x18 = PRBMathSD59x18.fromUint(lockedAmountAfter).div(PRBMathSD59x18.fromUint(bal.total));

        return (utilBeforeAs59x18, utilAfterAs59x18, lockedAmountBefore, lockedAmountAfter);
    }

    /**
     * @notice The specified OToken's strike price as a percentage of the current market spot price.
     * @dev In-The-Money put options will return a value > 100; Out-Of-The-Money put options will return a value <= 100.
     * @param _otoken The identifier (token contract address) of the OToken to get the strike price. Not checked for validity in this view function.
     * @return The strike price as a percentage of the current price, rounded up to an integer percentage.
     *         E.g. if current price is $100, then a strike price of $94.01 returns a strikePercent of 95,
     *         and a strike price of $102.99 returns a strikePercent of 103.
     */
    function percentStrike(OtokenInterface _otoken) public view returns (uint256) {
        // strikePrice() returns a value that assumes 8 digits (i.e. human readable value * 10^8), regardless of the decimals used by any other token
        (, address underlyingAsset, address strikeAsset, uint256 strikePrice, , ) = _otoken.getOtokenDetails();
        uint256 strikePriceInStrikeTokensTimes10e8 = strikePrice;

        // Get the spot prices of the underlying and strike assets
        (, FPI.FixedPointInt memory underlyingPrice, FPI.FixedPointInt memory strikeTokenPrice) = _getLivePrices(
            underlyingAsset,
            strikeAsset
        );
        assert(underlyingPrice.value > 0);
        assert(strikeTokenPrice.value > 0);
        FPI.FixedPointInt memory spotPriceInStrikeTokensAsDecimal = underlyingPrice.div(strikeTokenPrice);
        uint256 spotPriceInStrikeTokensTimes10e8 = spotPriceInStrikeTokensAsDecimal.toScaledUint(
            ORACLE_PRICE_DECIMALS,
            false
        );

        // To get the strike as a percentage of the spot price, we want to use the same units for both the
        // numerator and the denominator when calculating:
        //    (strikeTokenPrice * 100) / spotPrice
        //
        // Here we add (denominator -1) to the numerator before dividing, to ensure that we round up
        return
            ((strikePriceInStrikeTokensTimes10e8 * 100) + spotPriceInStrikeTokensTimes10e8 - 1) /
            spotPriceInStrikeTokensTimes10e8;
    }

    /**
     * @notice It calculates the number of days (including all partial days) until the specified Otoken expires.
     * @dev reverts if the otoken already expired
     * @param _otoken The identifier (address) of the Otoken. Not checked for validity in this view function.
     * @return The number of days remaining until OToken expiry, rounded up if necessary to make to an integer number of days.
     */
    function durationInDays(OtokenInterface _otoken) public view returns (uint256) {
        uint256 expiry = _otoken.expiryTimestamp();
        require(expiry > block.timestamp, "Otoken has expired");
        uint256 duration = expiry - block.timestamp;
        // To round up the answer, we add SECONDS_IN_A_DAY-1 before we divide
        return (duration + SECONDS_IN_A_DAY - 1) / SECONDS_IN_A_DAY;
    }

    ///////////////////////////////////////////////////////////////////////////
    //  Public interface
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Create an Opyn vault, which Potion will use to collateralize a given OToken.
     * @dev `_otoken` is implicitly checked for validity when we call `_getOrCreateVaultInfo`.
     * @param _otoken The identifier (token contract address) of the OToken.
     * @return The unique ID of the vault, > 0.
     */
    function createNewVaultId(OtokenInterface _otoken) external whenNotPaused returns (uint256) {
        require(getVaultId(_otoken) == 0, "Vault already exists");
        return _getOrCreateVaultInfo(_otoken).vaultId;
    }

    /**
     * @notice Deposit collateral tokens from the sender into the specified pool belonging to the caller.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _amount The amount of collateral tokens to deposit.
     */
    function deposit(uint256 _poolId, uint256 _amount) public whenNotPaused {
        if (_amount > 0) {
            _credit(msg.sender, _poolId, _amount);
            poolCollateralToken.safeTransferFrom(msg.sender, address(this), _amount);
            assert(poolCollateralToken.balanceOf(address(this)) >= sumOfAllUnlockedBalances);
            emit Deposited(msg.sender, _poolId, _amount);
        }
    }

    /**
     * @notice Deposit collateral tokens from the sender into the specified pool belonging to the caller and configures the Curve and CriteriaSet.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _amount The amount of collateral tokens to deposit.
     * @param _curveHash The hash of the new Curve to be set in the specified pool.
     * @param _criteriaSetHash The hash of the new CriteriaSet to be set in the specified pool.
     */
    function depositAndConfigurePool(
        uint256 _poolId,
        uint256 _amount,
        bytes32 _curveHash,
        bytes32 _criteriaSetHash
    ) external whenNotPaused {
        setCurve(_poolId, _curveHash);
        setCurveCriteria(_poolId, _criteriaSetHash);

        // We deposit last as this involves an external call, albeit to a trusted collateral token
        deposit(_poolId, _amount);
    }

    /**
     * @notice Set the "set of criteria" associated with a given pool of capital. These criteria will be used to determine which otokens this pool of capital is prepared to collateralize. If any Criteria in the set is a match, then the otoken can potentially be colalteralized by this pool of capital, subject to the premium being paid and sufficient liquidity being available.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _criteriaSetHash The hash of the immutable CriteriaSet to be associated with this PoolOfCapital.
     */
    function setCurveCriteria(uint256 _poolId, bytes32 _criteriaSetHash) public whenNotPaused {
        // Allow setting criteriaSet = 0x000... to indicate that this capital is not available for use
        require(_criteriaSetHash == bytes32(0) || crit.isCriteriaSetHash(_criteriaSetHash), "No such criteriaSet");
        if (lpPools[msg.sender][_poolId].criteriaSetHash != _criteriaSetHash) {
            lpPools[msg.sender][_poolId].criteriaSetHash = _criteriaSetHash;
            emit CriteriaSetSelected(msg.sender, _poolId, _criteriaSetHash);
        }
    }

    /**
     * @notice Set the curve associated with a given pool of capital. The curve will be used to price the premiums charged for any otokens that this pool of capital is prepared to collateralize.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _curveHash The hash of the immutable Curve to be associated with this PoolOfCapital.
     */
    function setCurve(uint256 _poolId, bytes32 _curveHash) public whenNotPaused {
        require(crv.isKnownCurveHash(_curveHash), "No such curve");
        if (lpPools[msg.sender][_poolId].curveHash != _curveHash) {
            lpPools[msg.sender][_poolId].curveHash = _curveHash;
            emit CurveSelected(msg.sender, _poolId, _curveHash);
        }
    }

    /**
     * @notice Withdraw unlocked collateral tokens from the specified pool belonging to the caller, and send them to the caller's address.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _amount The amount of collateral tokens to withdraw.
     */
    function withdraw(uint256 _poolId, uint256 _amount) external whenNotPaused {
        if (_amount > 0) {
            _debit(msg.sender, _poolId, _amount);
            poolCollateralToken.safeTransfer(msg.sender, _amount);
            assert(poolCollateralToken.balanceOf(address(this)) >= sumOfAllUnlockedBalances);
            emit Withdrawn(msg.sender, _poolId, _amount);
        }
    }

    /**
     * @notice Creates a new otoken, and then buy it from the specified list of sellers.
     * @param _underlyingAsset A property of the otoken that is to be created.
     * @param _strikeAsset A property of the otoken that is to be created.
     * @param _collateralAsset A property of the otoken that is to be created.
     * @param _strikePrice A property of the otoken that is to be created.
     * @param _expiry A property of the otoken that is to be created.
     * @param _isPut A property of the otoken that is to be created.
     * @param _sellers The LPs to buy the new otokens from. These LPs will charge a premium to collateralize the otoken.
     * @param _maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
     * @return premium The total premium paid.
     */
    function createAndBuyOtokens(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut,
        CounterpartyDetails[] memory _sellers,
        uint256 _maxPremium
    ) external whenNotPaused returns (uint256 premium) {
        require(_collateralAsset == address(poolCollateralToken), "Potion: wrong collateral token");
        OtokenFactoryInterface otokenFactory = OtokenFactoryInterface(opynAddressBook.getOtokenFactory());
        address otoken = otokenFactory.createOtoken(
            _underlyingAsset,
            _strikeAsset,
            _collateralAsset,
            _strikePrice,
            _expiry,
            _isPut
        );
        return buyOtokens(OtokenInterface(otoken), _sellers, _maxPremium);
    }

    /**
     * @notice Buy a OTokens from the specified list of sellers.
     * @dev `_otoken` is implicitly checked for validity when we call `_getOrCreateVaultInfo`.
     * @param _otoken The identifier (address) of the OTokens being bought.
     * @param _sellers The LPs to buy the new OTokens from. These LPs will charge a premium to collateralize the otoken.
     * @param _maxPremium The maximum premium that the buyer is willing to pay, denominated in collateral tokens (wei) and aggregated across all sellers
     * @return premium The aggregated premium paid.
     */
    function buyOtokens(
        OtokenInterface _otoken,
        CounterpartyDetails[] memory _sellers,
        uint256 _maxPremium
    ) public whenNotPaused returns (uint256 premium) {
        AggregateOrderData memory runningTotals;
        VaultInfo storage vault = _getOrCreateVaultInfo(_otoken);

        // We have some info about the otoken that we read for every seller. Get it once and cache it.
        ICriteriaManager.OtokenProperties memory otokenCache;
        address collateralAsset;
        uint256 otokenStrikePrice;
        (
            collateralAsset,
            otokenCache.underlyingAsset,
            otokenCache.strikeAsset,
            otokenStrikePrice,
            ,
            otokenCache.isPut
        ) = _otoken.getOtokenDetails();
        IERC20 collateralToken = IERC20(collateralAsset);

        // For now, only puts are supported and only with one collateral token
        require(collateralToken == poolCollateralToken, "Potion: wrong collateral token");
        require(otokenCache.isPut, "Potion: otoken not a put");

        // Getting the durationInDays implicitly asserts that the otoken has not yet expired
        otokenCache.percentStrikeValue = percentStrike(_otoken);
        otokenCache.wholeDaysRemaining = durationInDays(_otoken);

        // We need the price ratio, strike price, and the decimals used by the collateral token, but we
        // can get these once rather than once-per-seller
        CollateralCalculationParams memory collateralCalcParams;
        (
            collateralCalcParams.collateralMatchesStrike,
            collateralCalcParams.strikePrice,
            collateralCalcParams.collateralPrice
        ) = _getLivePrices(otokenCache.strikeAsset, collateralAsset);
        collateralCalcParams.otokenStrikeHumanReadable = FPI.fromScaledUint(otokenStrikePrice, OTOKEN_QTY_DECIMALS);
        collateralCalcParams.collateralTokenDecimals = ERC20Interface(collateralAsset).decimals();

        // Iterate through sellers, doing checks and optimistically updating with assumption that transaction will succeed
        // This loop is unbounded. If it runs outof gas that's because the buyer is trying to buy from too many different pools
        // It is the responsibility of the router to not route buyers to too many pools in a singel transaction
        require(_sellers.length > 0, "Can't buy from no sellers");

        for (uint256 i = 0; i < _sellers.length; i++) {
            CounterpartyDetails memory seller = _sellers[i];
            bytes32 curveHash = crv.hashCurve(seller.curve);
            require(seller.orderSizeInOtokens > 0, "Order tranche is zero");
            require(crv.isKnownCurveHash(curveHash), "No such curve");
            require(curveHash == lpPools[seller.lp][seller.poolId].curveHash, "Invalid curve");
            require(
                crit.isInCriteriaSet(
                    lpPools[seller.lp][seller.poolId].criteriaSetHash,
                    crit.hashCriteria(seller.criteria)
                ),
                "Invalid criteria hash"
            );

            // Check that the token matches the LP's criteria
            require(seller.criteria.underlyingAsset == otokenCache.underlyingAsset, "wrong underlying token");
            require(seller.criteria.strikeAsset == otokenCache.strikeAsset, "wrong strike token");
            require(seller.criteria.isPut == otokenCache.isPut, "call options not supported");
            require(seller.criteria.maxStrikePercent >= otokenCache.percentStrikeValue, "invalid strike%");
            require(seller.criteria.maxDurationInDays >= otokenCache.wholeDaysRemaining, "invalid duration");

            (uint256 latestPremium, uint256 latestCollateral) = _initiatePurchaseAndUpdateFundsForOneLP(
                seller,
                collateralCalcParams
            );
            runningTotals.premium = runningTotals.premium + latestPremium;
            runningTotals.orderSize = runningTotals.orderSize + seller.orderSizeInOtokens;
            runningTotals.collateral = runningTotals.collateral + latestCollateral;
            vault.contributionsByLp[seller.lp][seller.poolId] =
                vault.contributionsByLp[seller.lp][seller.poolId] +
                latestCollateral;
            emit OptionsSold(
                seller.lp,
                seller.poolId,
                address(_otoken),
                curveHash,
                seller.orderSizeInOtokens,
                latestCollateral,
                latestPremium
            );
        }

        require(runningTotals.premium <= _maxPremium, "Premium higher than max");
        collateralToken.safeIncreaseAllowance(opynAddressBook.getMarginPool(), runningTotals.collateral);

        // Calling into Opyn implicitly checks that the otoken is valid (e.g. not a dummy token, and not expired)
        vault.totalContributions = vault.totalContributions + runningTotals.collateral;
        Actions.ActionArgs[] memory opynActions = ActionsLib._actionArgsToDepositCollateralAndMintOtokens(
            vault.vaultId,
            _otoken,
            address(collateralToken),
            runningTotals.collateral,
            runningTotals.orderSize
        );
        opynController.operate(opynActions);

        // Transfer colateral at the end, just in case collateral token is malicious (but if it is we are probably screwed for other reasons!)
        collateralToken.safeTransferFrom(msg.sender, address(this), runningTotals.premium);
        assert(poolCollateralToken.balanceOf(address(this)) >= sumOfAllUnlockedBalances);
        emit OptionsBought(msg.sender, address(_otoken), runningTotals.orderSize, runningTotals.premium);
        return runningTotals.premium;
    }

    /**
     * @notice Retrieve unused collateral from Opyn into this contract. Does not redistribute it to our (unbounded number of) LPs
     * @dev `_otoken` is implicitly checked for validity when we call `_getVaultInfo`.
     * Redistribution can be done by calling redistributeSettlement(addresses).
     * @param _otoken The identifier (address) of the expired OToken for which unused collateral should be retrieved.
     */
    function settleAfterExpiry(OtokenInterface _otoken) public whenNotPaused {
        VaultInfo storage v = _getVaultInfo(_otoken);
        require(!v.settled, "Vault already settled");

        // Success or revert
        v.settled = true;

        require(opynController.isSettlementAllowed(address(_otoken)), "Otoken cannot (yet) settle");

        // Get the settled amount of collateral
        v.settledAmount = opynController.getProceed(address(this), v.vaultId);

        if (v.settledAmount > 0) {
            Actions.ActionArgs[] memory openVaultActions = new Actions.ActionArgs[](1);
            openVaultActions[0] = ActionsLib._getSettleVaultAction(address(this), v.vaultId, address(this));
            opynController.operate(openVaultActions);

            emit OptionSettled(address(_otoken), v.settledAmount);
        }
    }

    /**
     * @notice Calculates the outstading settlement from the PoolIdentifier in OTokens.
     * @dev Redistribution can be done by calling redistributeSettlement(addresses).
     * @dev `_otoken` is implicitly checked for validity when we call `_getVaultInfo`.
     * @param _otoken The identifier (address) of the expired OToken for which unused collateral should be retrieved.
     * @param _pool The pool information which the outstanding settlement is calculated.
     * @return collateralDueBack The amount of collateral that can be removed from a vault.
     */
    function outstandingSettlement(OtokenInterface _otoken, PoolIdentifier calldata _pool)
        public
        view
        returns (uint256 collateralDueBack)
    {
        VaultInfo storage v = _getVaultInfo(_otoken);
        uint256 contribution = v.contributionsByLp[_pool.lp][_pool.poolId];
        if (v.totalContributions == 0 || contribution == 0) {
            return 0;
        }

        if (isSettled(_otoken)) {
            return (v.settledAmount * contribution) / v.totalContributions;
        } else {
            uint256 settledAmount = opynController.getProceed(address(this), v.vaultId);
            // Round down, so that we never over-pay
            return (settledAmount * contribution) / v.totalContributions;
        }
    }

    /**
     * @notice Check whether a give OToken has been settled.
     * @dev Settled OTokens may not have had funds redistributed to all (or any) contributing LPs.
     * @dev `_otoken` is implicitly checked for validity when we call `_getVaultInfo`.
     * @param _otoken the (settled or unsettled) OToken.
     * @return True if it is settled, otherwise false
     */
    function isSettled(OtokenInterface _otoken) public view returns (bool) {
        VaultInfo storage v = _getVaultInfo(_otoken);
        return v.settled;
    }

    /**
     * @notice Redistribute already-retrieved collateral amongst the specified pools. This function must be called after settleAfterExpiry.
     * @dev If the full list of PoolIdentifiers owed funds is too long, a partial list can be provided and additional calls to redistributeSettlement() can be made.
     * @dev `_otoken` is implicitly checked for validity when we call `_getVaultInfo`.
     * @param _otoken The identifier (address) of the settled otoken for which retrieved collateral should be redistributed.
     * @param _pools The pools of capital to which the collateral should be redistributed. These pools must be (a subset of) the pools that provided collateral for the specified otoken.
     */
    function redistributeSettlement(OtokenInterface _otoken, PoolIdentifier[] calldata _pools) public whenNotPaused {
        VaultInfo storage v = _getVaultInfo(_otoken);
        require(v.settled, "Vault not yet settled");

        // This loop is unbounded. If it runs out of gas that's because the caller is trying to redistribute
        // funds to too many LPs in one transaction. In that case, the caller can retry with smaller lists
        // (perhaps spreading the long list of LPs across more than one transaction).
        for (uint256 i = 0; i < _pools.length; i++) {
            PoolIdentifier calldata p = _pools[i];
            if (v.contributionsByLp[p.lp][p.poolId] == 0) {
                continue;
            }

            // Round down, so that we never over-pay
            uint256 amountToCredit = (v.settledAmount * v.contributionsByLp[p.lp][p.poolId]) / v.totalContributions;
            _burnLocked(p.lp, p.poolId, v.contributionsByLp[p.lp][p.poolId] - amountToCredit);
            _unlock(p.lp, p.poolId, amountToCredit);
            v.contributionsByLp[p.lp][p.poolId] = 0;
            emit OptionSettlementDistributed(address(_otoken), p.lp, p.poolId, amountToCredit);
        }

        // Check we've not allocated more than we had to give
        assert(poolCollateralToken.balanceOf(address(this)) >= sumOfAllUnlockedBalances);
    }

    /**
     * @notice Retrieve unused collateral from Opyn, and redistribute it to the specified LPs.
     * @dev If the full list of PoolIdentifiers owed funds is too long, a partial list can be provided and additional calls to redistributeSettlement() can be made.
     * @dev `_otoken` is implicitly checked for validity when we call `settleAfterExpiry`.
     * @param _otoken The identifier (address) of the expired otoken for which unused collateral should be retrieved.
     * @param _pools The pools of capital to which the collateral should be redistributed. These pools must be (a subset of) the pools that provided collateral for the specified otoken.
     */
    function settleAndRedistributeSettlement(OtokenInterface _otoken, PoolIdentifier[] calldata _pools)
        external
        whenNotPaused
    {
        settleAfterExpiry(_otoken);
        redistributeSettlement(_otoken, _pools);
    }

    /**
     * @notice Deposit and create a curve and criteria set if they don't exist.
     * @dev This function also sets the curve and criteria set in the specified pool.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _amount The amount of collateral tokens to deposit.
     * @param _curve The Curve to add and set in the pool.
     * @param _criterias A sorted array of Criteria, ordered by Criteria hash.
     */
    function depositAndCreateCurveAndCriteria(
        uint256 _poolId,
        uint256 _amount,
        ICurveManager.Curve memory _curve,
        ICriteriaManager.Criteria[] memory _criterias
    ) external whenNotPaused {
        addAndSetCurve(_poolId, _curve);
        addAndSetCriterias(_poolId, _criterias);

        // We deposit last as this involves an external call, albeit to a trusted collateral token
        deposit(_poolId, _amount);
    }

    /**
     * @notice Add and set a curve.
     * @dev If the curve already exists, it won't be added
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _curve The Curve to add and set in the pool.
     */
    function addAndSetCurve(uint256 _poolId, ICurveManager.Curve memory _curve) public whenNotPaused {
        bytes32 curveHash = crv.addCurve(_curve);
        setCurve(_poolId, curveHash);
    }

    /**
     * @notice Add criteria, criteria set and set the criteria set in the specified pool.
     * @dev If the criteria and criteria set already exists, it won't be added.
     * @param _poolId The identifier for a PoolOfCapital belonging to the caller. Could be an existing pool or a new one.
     * @param _criterias A sorted array of Criteria, ordered by Criteria hash.
     */
    function addAndSetCriterias(uint256 _poolId, ICriteriaManager.Criteria[] memory _criterias) public whenNotPaused {
        uint256 criteriasLength = _criterias.length;
        bytes32[] memory criteriaHashes = new bytes32[](criteriasLength);
        for (uint256 i = 0; i < criteriasLength; i++) {
            criteriaHashes[i] = crit.addCriteria(_criterias[i]);
        }
        bytes32 criteriaSetHash = crit.addCriteriaSet(criteriaHashes);
        setCurveCriteria(_poolId, criteriaSetHash);
    }

    ///////////////////////////////////////////////////////////////////////////
    //  Internals
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Debits unlocked collateral tokens from the specified PoolOfCapital
     * @dev _PoolId is generated on the client side.
     * @param _lp The Address of the Liquidity provider.
     * @param _poolId An (LP-specific) pool identifier..
     * @param _amount The amount to credit to the corresponding PoolOfCapital.
     */
    function _debit(
        address _lp,
        uint256 _poolId,
        uint256 _amount
    ) internal {
        PoolOfCapital storage lpb = lpPools[_lp][_poolId];
        lpb.total = lpb.total - _amount;
        sumOfAllUnlockedBalances = sumOfAllUnlockedBalances - _amount;
        require(lpb.total >= lpb.locked, "_debit: locked > total");
    }

    /**
     * @notice Credits unlocked collateral tokens to the specified PoolOfCapital
     * @dev _PoolId is generated on the client side.
     * @param _lp The Address of the Liquidity provider.
     * @param _poolId An (LP-specific) pool identifier..
     * @param _amount The amount to credit to the corresponding PoolOfCapital.
     */

    function _credit(
        address _lp,
        uint256 _poolId,
        uint256 _amount
    ) internal {
        PoolOfCapital storage lpb = lpPools[_lp][_poolId];
        lpb.total = lpb.total + _amount;
        sumOfAllUnlockedBalances = sumOfAllUnlockedBalances + _amount;
        require(sumOfAllUnlockedBalances + sumOfAllLockedBalances <= maxTotalValueLocked, "Max TVL exceeded");
    }

    /**
     * @notice Burns collateral tokens from the specified PoolOfCapital
     * @dev _PoolId is generated on the client side.
     * @param _lp The Address of the Liquidity provider.
     * @param _poolId An (LP-specific) pool identifier.
     * @param _amount The amount of collateral tokens to burn from the specified PoolOfCapital.
     */
    function _burnLocked(
        address _lp,
        uint256 _poolId,
        uint256 _amount
    ) internal {
        PoolOfCapital storage lpb = lpPools[_lp][_poolId];
        lpb.total = lpb.total - _amount;
        lpb.locked = lpb.locked - _amount;
        sumOfAllLockedBalances = sumOfAllLockedBalances - _amount;
        // No need to update sumOfAllUnlockedBalances
    }

    /**
     * @notice Unlocks collateral tokens within the specified PoolOfCapital
     * @dev _PoolId is generated on the client side.
     * @param _lp The Address of the Liquidity provider.
     * @param _poolId An (LP-specific) pool identifier.
     * @param _amount The amount to unlock from the specified PoolOfCapital.
     */
    function _unlock(
        address _lp,
        uint256 _poolId,
        uint256 _amount
    ) internal {
        PoolOfCapital storage lpb = lpPools[_lp][_poolId];
        lpb.locked = lpb.locked - _amount;
        sumOfAllUnlockedBalances = sumOfAllUnlockedBalances + _amount;
        sumOfAllLockedBalances = sumOfAllLockedBalances - _amount;
        require(lpb.total >= lpb.locked, "_unlock: locked > total");
        assert(poolCollateralToken.balanceOf(address(this)) >= sumOfAllUnlockedBalances);
    }

    /**
     * @dev Get the VaultInfo for the Opyn vault that Potion uses to collateralize a given otoken
     * @param _otoken The identifier (token contract address) of the otoken. The otoken must have a vault, or the function will throw. Note that only whitelisted (or previously-whitelisted) otokens can have a vault.
     * @return The VaultInfo struct for the now-guaranteed-to-be-valid (i.e. is whitelisted or was previously whitelisted) otoken.
     */
    function _getVaultInfo(OtokenInterface _otoken) internal view returns (VaultInfo storage) {
        require(vaults[address(_otoken)].vaultId > 0, "No such vault");
        return vaults[address(_otoken)];
    }

    /**
     * @notice Get the VaultInfo for the Opyn vault that Potion uses to collateralize a given otoken.
     * @dev A vault will be created only if the otoken is whitelisted and a vault does not already exist.
     * @param _otoken The identifier (token contract address) of a whitelisted otoken.
     * @return The VaultInfo struct for the now-guaranteed-to-be-valid (i.e. is whitelisted or was previously whitelisted) otoken.
     */
    function _getOrCreateVaultInfo(OtokenInterface _otoken) internal returns (VaultInfo storage) {
        if (vaults[address(_otoken)].vaultId == 0) {
            // 0 is not used as a vault ID, so this vault does not exist yet.
            // The otoken is valid (whitelisted) and has no vault, so create a vault
            vaultCount += 1;
            Actions.ActionArgs[] memory openVaultActions = new Actions.ActionArgs[](1);
            openVaultActions[0] = ActionsLib._getOpenVaultAction(address(this), vaultCount);

            // Update our map and create the vault
            vaults[address(_otoken)].vaultId = vaultCount;
            opynController.operate(openVaultActions);

            // If the otoken is not whitelisted it's not a real otoken and we revert.
            // We could have checked this earlier, but doing it last sidesteps reantrancy issues.
            WhitelistInterface whitelist = WhitelistInterface(opynAddressBook.getWhitelist());
            require(whitelist.isWhitelistedOtoken(address(_otoken)), "Invalid otoken");
        }

        return vaults[address(_otoken)];
    }

    /**
     * @notice Increments the locked and total collateral for the LP, on the assumption that the quote will be
     * exercized.
     * @dev Does NOT check that the supplied otoken is valid, or allowed by the LP. Does NOT check that the supplied curve is allowed by the LP.
     * @dev It must only be called by internal functions that ensure the order is subsequntly fulfilled.
     * @param _seller The seller details(LP).
     * @param _collateralCalcParams Struct used to pass other inputs required for collateral calculation
     */
    function _initiatePurchaseAndUpdateFundsForOneLP(
        CounterpartyDetails memory _seller,
        CollateralCalculationParams memory _collateralCalcParams
    ) internal returns (uint256 premium, uint256 collateralAmount) {
        // Take the premium from the buyer; it's paid in the collateral token
        PoolOfCapital storage lpBal = lpPools[_seller.lp][_seller.poolId];

        // Return the collateral amount
        collateralAmount = _collateralNeededForPuts(_seller.orderSizeInOtokens, _collateralCalcParams);
        premium = _premiumForLp(_seller.lp, _seller.poolId, _seller.curve, collateralAmount);
        lpBal.total = lpBal.total + premium;
        lpBal.locked = lpBal.locked + collateralAmount;
        sumOfAllUnlockedBalances = sumOfAllUnlockedBalances + premium - collateralAmount;
        sumOfAllLockedBalances = sumOfAllLockedBalances + collateralAmount;
        require(lpBal.locked <= lpBal.total, "insufficient collateral");
        return (premium, collateralAmount);
    }

    /**
     * @notice The amount of capital required to collateralize a given quantitiy of a given `OToken`.
     * @dev don't introduce rounding errors. this must match the value returned by Opyn's logic, or else options will be insufcciently collateralised
     * @param _otokenQty The number of OTokens we wish to collateralize.
     * @param _collateralCalcParams Struct used to pass other inputs required for collateral calculation
     * @return The amount of collateral required, denominated in collateral tokens.
     */
    function _collateralNeededForPuts(uint256 _otokenQty, CollateralCalculationParams memory _collateralCalcParams)
        internal
        pure
        returns (uint256)
    {
        // Takes the non-expired, non-spread, selling a put case code from _getMarginRequired
        // Otoken quantities always use 8 decimals
        FPI.FixedPointInt memory shortOtokensHumanReadable = FPI.fromScaledUint(_otokenQty, OTOKEN_QTY_DECIMALS);
        FPI.FixedPointInt memory collateralNeededHumanStrikeTokens = shortOtokensHumanReadable.mul(
            _collateralCalcParams.otokenStrikeHumanReadable
        );
        // convert amount to be denominated in collateral

        FPI.FixedPointInt memory collateralRequired;
        if (_collateralCalcParams.collateralMatchesStrike) {
            // No exchange rate conversion required
            collateralRequired = collateralNeededHumanStrikeTokens;
        } else {
            assert(_collateralCalcParams.collateralPrice.value > 0);
            collateralRequired = _convertAmountOnLivePrice(
                collateralNeededHumanStrikeTokens,
                _collateralCalcParams.strikePrice,
                _collateralCalcParams.collateralPrice
            );
        }

        return collateralRequired.toScaledUint(_collateralCalcParams.collateralTokenDecimals, false);
    }

    /**
     * @notice Calculates the Premium for the supplied counterparty details.
     * @dev Does NOT check that the supplied curve is allowed. Premium calculations involve some orunding and loss of accuracy due
     * to the complex math at play. We expect the calculated premium to be within 0.1% of the correct value (i.e. the value we would
     * get in, say, python with no loss of precision) in all but a few pathological cases (e.g. util below 0.1% and multiple curve
     * parameters very near zero)
     * @param _lp The Address of the Liquidity provider.
     * @param _poolId An (LP-specific) pool identifier.
     * @param _curve The curve used to calculate the premium.
     * @param _collateralToLock The amount of collateral to lock.
     * @return premiumInCollateralTokens
     */
    function _premiumForLp(
        address _lp,
        uint256 _poolId,
        ICurveManager.Curve memory _curve,
        uint256 _collateralToLock
    ) internal view returns (uint256 premiumInCollateralTokens) {
        (
            int256 utilBeforeAs59x18,
            int256 utilAfterAs59x18,
            uint256 lockedAmountBefore,
            uint256 lockedAmountAfter
        ) = util(_lp, _poolId, _collateralToLock);

        // Make sure we're not buying too large an amount, nor an amount so small that we can't calc a premium
        require(utilAfterAs59x18 > utilBeforeAs59x18, "Order tranche too small");
        require(utilAfterAs59x18 <= _curve.max_util_59x18, "Max util exceeded");

        // The result of hyperbolicCurve tells us the premium we should have received in aggregate at any utilisation, as a percentage
        // of the aggregate locked collateral.
        // When calling hyperbolicCurve we pass in a utilisation as a fixed-point decimal (1.0 = 100% utilisation) and get back the
        // a % as a fixed point decimal (1.0 = premium should be 100% of the locked collateral).
        // To get the premium for our new order, we:
        //   1. Calculate the premium we should have received, in aggregate, BEFORE this order
        //   2. Calculate the premium we should have received, in aggregate, AFTER this order (for any non-trivial order, utilisation and
        //      collateral locked will both increase)
        //   3. Charge the buyer difference.
        uint256 premiumBefore = crv
            .hyperbolicCurve(_curve, utilBeforeAs59x18)
            .mul(PRBMathSD59x18.fromUint(lockedAmountBefore))
            .toUint();
        uint256 premiumAfter = crv
            .hyperbolicCurve(_curve, utilAfterAs59x18)
            .mul(PRBMathSD59x18.fromUint(lockedAmountAfter))
            .toUint();
        return premiumAfter - premiumBefore;
    }

    /**
     * @notice Return the spot prices of assets A and B, unless A and B are the same asset
     * @param _assetA Asset A address
     * @param _assetB Asset B address
     * @return identicalAssets whether the passed assets were identical; if so, prices of 0 are returned
     * @return scaledPriceA of asset A (not set if identicalAssets=true)
     * @return scaledPriceB of asset B (not set if identicalAssets=true)
     */
    function _getLivePrices(address _assetA, address _assetB)
        internal
        view
        returns (
            bool identicalAssets,
            FPI.FixedPointInt memory scaledPriceA,
            FPI.FixedPointInt memory scaledPriceB
        )
    {
        if (_assetA == _assetB) {
            // N.B. this may be the most common case for puts
            return (true, FPI.fromUnscaledInt(0), FPI.fromUnscaledInt(0));
        }

        OracleInterface oracle = OracleInterface(AddressBookInterface(opynAddressBook).getOracle());

        // Oracle prices are always scaled by 8 decimals
        uint256 priceA = oracle.getPrice(_assetA);
        uint256 priceB = oracle.getPrice(_assetB);

        return (
            false,
            FPI.fromScaledUint(priceA, ORACLE_PRICE_DECIMALS),
            FPI.fromScaledUint(priceB, ORACLE_PRICE_DECIMALS)
        );
    }

    /**
     * @notice Convert an amount in asset A to equivalent amount of asset B, based on a live price.
     * @dev Function includes the amount and applies .mul() first to increase the accuracy.
     * @param _amount Amount in asset A.
     * @param _priceA The price of asset A, as returned by Opyn's oracle (decimals = 8), in the FixedPointInt representation of decimal numbers
     * @param _priceB The price of asset B, as returned by Opyn's oracle (decimals = 8), in the FixedPointInt representation of decimal numbers
     */
    function _convertAmountOnLivePrice(
        FPI.FixedPointInt memory _amount,
        FPI.FixedPointInt memory _priceA,
        FPI.FixedPointInt memory _priceB
    ) internal pure returns (FPI.FixedPointInt memory) {
        // amount A * price A in USD = amount B * price B in USD
        // amount B = amount A * price A / price B
        assert(_priceB.value > 0);
        return _amount.mul(_priceA).div(_priceB);
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.4;

/**
 * @title ICurveManager
 * @notice Keeps a registry of all Curves that are known to the Potion protocol
 */
interface ICurveManager {
    ///////////////////////////////////////////////////////////////////////////
    //  Events
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Emits when new curves are registered.
    /// @dev Curves are immutable once added, so expect at most one log per curveHash.
    event CurveAdded(bytes32 indexed curveHash, Curve curveParams);

    ///////////////////////////////////////////////////////////////////////////
    //  Structs and vars
    ///////////////////////////////////////////////////////////////////////////

    /// @notice A Curve defines a function of the form:
    ///
    ///  f(x) =  a * x * cosh(b*x^c) + d
    ///
    /// @dev All Curve parameters are signed 59x18-bit fixed point numbers, i.e. the numerator part of a number
    /// that has a fixed denominator of 2^64.
    struct Curve {
        int256 a_59x18;
        int256 b_59x18;
        int256 c_59x18;
        int256 d_59x18;
        int256 max_util_59x18;
    }

    /**
     * @notice Add the specified Curve to the registry of Curves that are known to our contract
     * @param _curve The Curve to register
     * @return hash The keccak256 of the Curve
     */
    function addCurve(Curve calldata _curve) external returns (bytes32 hash);

    /**
     * @notice Get the hash of given Curve
     * @param _curve The Curve to be hashed.
     * @return The keccak256 hash of the Curve
     */
    function hashCurve(Curve memory _curve) external pure returns (bytes32);

    /**
     * @notice Check whether the specified hash is the hash of a Curve that is known to our contract
     * @param _hash The hash to look for
     * @return valid True if the hash is that of a known Curve; false if it is not
     */
    function isKnownCurveHash(bytes32 _hash) external view returns (bool valid);

    /**
     * @notice Calculates hyperbolic cosine of an input x, using the formula:
     *
     *            e^x + e^(-x)
     * cosh(x) =  ------------
     *                 2
     *
     * @dev The input and output are signed 59x18-bit fixed point number.
     * @param _input59x18 Signed 59x18-bit fixed point number
     * @return output59x18 Result of computing the hyperbolic cosine of an input x
     */
    function cosh(int256 _input59x18) external pure returns (int256 output59x18);

    /**
     * @notice Evaluates the function defined by curve c at point x, example:
     *
     *    a * x * cosh(b*x^c) + d
     *
     * @dev x is typically utilisation as a fraction (1 = 100%).
     * @dev All inputs are signed 59x18-bit fixed point numbers, i.e. the numerator part of a number
     * that has a fixed denominator of 2^64
     * @dev The output is a signed 59x18-bit fixed point number.
     * @param _curve The Curve values to be used by the function expression mentioned above.
     * @param _x_59x18 The point at which the function expression mentioned above will be calculated.
     * @return output59x18 Result of the function expression mentioned above evaluated at point x.
     */
    function hyperbolicCurve(Curve memory _curve, int256 _x_59x18) external pure returns (int256 output59x18);
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.4;

import { OtokenInterface } from "../packages/opynInterface/OtokenInterface.sol";

/**
 * @title ICriteriaManager
 * @notice Keeps a registry of all Criteria and CriteriaSet instances that are know to the Potion protocol.
 */
interface ICriteriaManager {
    ///////////////////////////////////////////////////////////////////////////
    //  Events
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Emits when new criteria are registered.
    /// @dev Criteria are immutable once added, so expect at most one log per criteriaHash.
    event CriteriaAdded(bytes32 indexed criteriaHash, Criteria criteria);

    /// @notice Emits when a new set of criteria is registered.
    /// @dev Criteria sets are immutable once added, so expect at most one log per criteriaSetHash.
    event CriteriaSetAdded(bytes32 indexed criteriaSetHash, bytes32[] criteriaSet);

    ///////////////////////////////////////////////////////////////////////////
    //  Structs and vars
    ///////////////////////////////////////////////////////////////////////////

    /// @dev A Criteria is considered a match for an OToken if the assets match, and the isPut flag matches, and maxStrikePercent is greater than or equal to the option's strike as a percentage of the current spot price, and maxDurationInDays is greater than or equal to the number of days (whole days or part days) until the OToken expires.
    struct Criteria {
        address underlyingAsset;
        address strikeAsset;
        bool isPut;
        uint256 maxStrikePercent;
        uint256 maxDurationInDays; // Must be > 0 for valid criteria. Doubles as existence flag.
    }

    /// @dev Otoken properties to be checked against Criteria.
    struct OtokenProperties {
        uint256 percentStrikeValue; /// The strike price as a percentage of the current price, rounded up to an integer percentage. E.g. if current price is $100, then a strike price of $94.01 implies a strikePercent of 95, and a strike price of $102.99 implies a strikePercent of 103.
        uint256 wholeDaysRemaining; /// The number of days remaining until OToken expiry, rounded up if necessary to make to an integer number of days.
        address underlyingAsset;
        address strikeAsset;
        bool isPut;
    }

    /// @dev a (non-enumerable) set of Criteria. An OToken is considered a match with a CriteriaSet if one or more of the Criteria within the set is a Match for the option.
    struct CriteriaSet {
        bool exists;
        mapping(bytes32 => bool) hashes;
    }

    ///////////////////////////////////////////////////////////////////////////
    //  Public interfaces
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Add the specified set of Criteria to the registry of CriteriaSets that are known to our contract.
     * @param _hashes A sorted list of bytes32 values, each being the hash of a known Criteria. No duplicates, so this can be considered a set.
     * @return criteriaSetHash The identifier for this criteria set.
     */
    function addCriteriaSet(bytes32[] memory _hashes) external returns (bytes32 criteriaSetHash);

    /**
     * @notice Check whether the specified hash is the hash of a CriteriaSet that is known to our contract.
     * @param _criteriaSetHash The hash to look for.
     * @return valid True if the hash is that of a known CriteriaSet; false if it is not.
     */
    function isCriteriaSetHash(bytes32 _criteriaSetHash) external view returns (bool valid);

    /**
     * @notice Add the specified Criteria to the registry of Criteria that are known to our contract.
     * @param _criteria The Criteria to register.
     * @return hash The keccak256 of the Criteria.
     */
    function addCriteria(Criteria memory _criteria) external returns (bytes32 hash);

    /**
     * @notice Get the hash of given Criteria
     * @param _criteria The Criteria to be hashed.
     * @return The keccak256 hash of the Criteria.
     */
    function hashCriteria(Criteria memory _criteria) external pure returns (bytes32);

    /**
     * @notice Get the hash of an ordered list of hash values.
     * @param _hashes The list of bytes32 values to be hashed. This list must be sorted according to solidity's ordering, and must not contain any duplicate values.
     * @return The keccak256 hash of the set of hashes.
     */
    function hashOfSortedHashes(bytes32[] memory _hashes) external pure returns (bytes32);

    /**
     * @notice Check whether the specified Criteria hash exists within the specified CriteriaSet.
     * @dev Clients should be responsible of passing correct parameters(_criteriaSetHash and _criteriaHash), otherwise we revert.
     * @param _criteriaSetHash The criteria list to be checked.
     * @param _criteriaHash The criteria we are looking for on that list.
     * @return isInSet true if the criteria exists in the criteriaSet; false if it does not.
     */
    function isInCriteriaSet(bytes32 _criteriaSetHash, bytes32 _criteriaHash) external view returns (bool isInSet);

    /**
     * @notice Check that a given token matches some specific Criteria.
     * @param _criteria The criteria to be checked against
     * @param _otokenCache The otoken to check
     */
    function requireOtokenMeetsCriteria(Criteria memory _criteria, OtokenProperties memory _otokenCache) external pure;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

import { Actions } from "./ActionsInterface.sol";
import { MarginVaultInterface } from "./MarginVaultInterface.sol";

/**
 * @title Public Controller interface
 * @notice For use by consumers and end users. Excludes permissioned (e.g. owner-only) functions
 */
interface ControllerInterface {
    function addressbook() external view returns (address);

    function whitelist() external view returns (address);

    function oracle() external view returns (address);

    function calculator() external view returns (address);

    function pool() external view returns (address);

    function partialPauser() external view returns (address);

    function fullPauser() external view returns (address);

    function systemPartiallyPaused() external view returns (bool);

    function systemFullyPaused() external view returns (bool);

    function callRestricted() external view returns (bool);

    /**
     * @notice send asset amount to margin pool
     * @dev use donate() instead of direct transfer() to store the balance in assetBalance
     * @param _asset asset address
     * @param _amount amount to donate to pool
     */
    function donate(address _asset, uint256 _amount) external;

    /**
     * @notice allows a user to give or revoke privileges to an operator which can act on their behalf on their vaults
     * @dev can only be updated by the vault owner
     * @param _operator operator that the sender wants to give privileges to or revoke them from
     * @param _isOperator new boolean value that expresses if the sender is giving or revoking privileges for _operator
     */
    function setOperator(address _operator, bool _isOperator) external;

    /**
     * @notice execute a number of actions on specific vaults
     * @dev can only be called when the system is not fully paused
     * @param _actions array of actions arguments
     */
    function operate(Actions.ActionArgs[] memory _actions) external;

    /**
     * @notice sync vault latest update timestamp
     * @dev anyone can update the latest time the vault was touched by calling this function
     * vaultLatestUpdate will sync if the vault is well collateralized
     * @param _owner vault owner address
     * @param _vaultId vault id
     */
    function sync(address _owner, uint256 _vaultId) external;

    /**
     * @notice check if a specific address is an operator for an owner account
     * @param _owner account owner address
     * @param _operator account operator address
     * @return True if the _operator is an approved operator for the _owner account
     */
    function isOperator(address _owner, address _operator) external view returns (bool);

    /**
     * @notice returns the current controller configuration
     * @return whitelist, the address of the whitelist module
     * @return oracle, the address of the oracle module
     * @return calculator, the address of the calculator module
     * @return pool, the address of the pool module
     */
    function getConfiguration()
        external
        view
        returns (
            address,
            address,
            address,
            address
        );

    /**
     * @notice return a vault's proceeds pre or post expiry, the amount of collateral that can be removed from a vault
     * @param _owner account owner of the vault
     * @param _vaultId vaultId to return balances for
     * @return amount of collateral that can be taken out
     */
    function getProceed(address _owner, uint256 _vaultId) external view returns (uint256);

    /**
     * @notice check if a vault is liquidatable in a specific round id
     * @param _owner vault owner address
     * @param _vaultId vault id to check
     * @param _roundId chainlink round id to check vault status at
     * @return isUnderCollat, true if vault is undercollateralized, the price of 1 repaid otoken and the otoken collateral dust amount
     */
    function isLiquidatable(
        address _owner,
        uint256 _vaultId,
        uint256 _roundId
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    /**
     * @notice get an oToken's payout/cash value after expiry, in the collateral asset
     * @param _otoken oToken address
     * @param _amount amount of the oToken to calculate the payout for, always represented in 1e8
     * @return amount of collateral to pay out
     */
    function getPayout(address _otoken, uint256 _amount) external view returns (uint256);

    /**
     * @dev return if an expired oToken is ready to be settled, only true when price for underlying,
     * strike and collateral assets at this specific expiry is available in our Oracle module
     * @param _otoken oToken
     */
    function isSettlementAllowed(address _otoken) external view returns (bool);

    /**
     * @dev return if underlying, strike, collateral are all allowed to be settled
     * @param _underlying oToken underlying asset
     * @param _strike oToken strike asset
     * @param _collateral oToken collateral asset
     * @param _expiry otoken expiry timestamp
     * @return True if the oToken has expired AND all oracle prices at the expiry timestamp have been finalized, False if not
     */
    function canSettleAssets(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);

    /**
     * @notice get the number of vaults for a specified account owner
     * @param _accountOwner account owner address
     * @return number of vaults
     */
    function getAccountVaultCounter(address _accountOwner) external view returns (uint256);

    /**
     * @notice check if an oToken has expired
     * @param _otoken oToken address
     * @return True if the otoken has expired, False if not
     */
    function hasExpired(address _otoken) external view returns (bool);

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner
     */
    function getVault(address _owner, uint256 _vaultId) external view returns (MarginVaultInterface.Vault memory);

    /**
     * @notice return a specific vault
     * @param _owner account owner
     * @param _vaultId vault id of vault to return
     * @return Vault struct that corresponds to the _vaultId of _owner, vault type and the latest timestamp when the vault was updated
     */
    function getVaultWithDetails(address _owner, uint256 _vaultId)
        external
        view
        returns (
            MarginVaultInterface.Vault memory,
            uint256,
            uint256
        );
}

// SPDX-License-Identifier: Apache-2.0
// Adapted from public domain Opyn code
pragma solidity 0.8.4;

interface OtokenInterface {
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

// SPDX-License-Identifier: Apache-2.0
// Adapted from public domain Opyn code
pragma solidity 0.8.4;

/**
 * @title OtokenFactoryInterface
 * @notice Interface used to interact with Opyn's OTokens.
 */
interface OtokenFactoryInterface {
    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

/**
 * @title Actions
 * @author Opyn & Potion Teams
 * @notice A library that provides a ActionArgs struct, sub types of Action structs, and functions to parse ActionArgs into specific Actions.
 */
library Actions {
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
}

// SPDX-License-Identifier: Apache-2.0
// Adapted from public domain Opyn code
pragma solidity 0.8.4;

interface AddressBookInterface {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    /* Setters */

    function setOtokenImpl(address _otokenImpl) external;

    function setOtokenFactory(address _factory) external;

    function setOracle(address _oracle) external;

    function setWhitelist(address _whitelist) external;

    function setController(address _controller) external;

    function setMarginPool(address _marginPool) external;

    function setMarginCalculator(address _calculator) external;

    function setLiquidationManager(address _liquidationManager) external;

    function setAddress(bytes32 _id, address _newImpl) external;
}

// SPDX-License-Identifier: Apache-2.0
// Adapted from public domain Opyn code
pragma solidity 0.8.4;

interface WhitelistInterface {
    /* View functions */

    function addressBook() external view returns (address);

    function isWhitelistedProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external view returns (bool);

    function isWhitelistedCollateral(address _collateral) external view returns (bool);

    function isWhitelistedOtoken(address _otoken) external view returns (bool);

    function isWhitelistedCallee(address _callee) external view returns (bool);

    /* Admin / factory only functions */
    function whitelistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function blacklistProduct(
        address _underlying,
        address _strike,
        address _collateral,
        bool _isPut
    ) external;

    function whitelistCollateral(address _collateral) external;

    function blacklistCollateral(address _collateral) external;

    function whitelistOtoken(address _otoken) external;

    function blacklistOtoken(address _otoken) external;

    function whitelistCallee(address _callee) external;

    function blacklistCallee(address _callee) external;
}

// SPDX-License-Identifier: Apache-2.0
// Adapted from public domain Opyn code
pragma solidity 0.8.4;

interface OracleInterface {
    function isLockingPeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function isDisputePeriodOver(address _asset, uint256 _expiryTimestamp) external view returns (bool);

    function getExpiryPrice(address _asset, uint256 _expiryTimestamp) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(address _pricer) external view returns (uint256);

    function getPricerDisputePeriod(address _pricer) external view returns (uint256);

    function getChainlinkRoundData(address _asset, uint80 _roundId) external view returns (uint256, uint256);

    // Non-view function

    function setAssetPricer(address _asset, address _pricer) external;

    function setLockingPeriod(address _pricer, uint256 _lockingPeriod) external;

    function setDisputePeriod(address _pricer, uint256 _disputePeriod) external;

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function disputeExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;

    function setDisputer(address _disputer) external;
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/SignedSafeMathUpgradeable.sol";
import { SignedConverter } from "./SignedConverter.sol";

/**
 * @title FixedPointInt256
 * @author Opyn Team
 * @notice FixedPoint library
 */
library FixedPointInt256 {
    using SignedSafeMathUpgradeable for int256;
    using SignedConverter for int256;
    using SafeMathUpgradeable for uint256;
    using SignedConverter for uint256;

    int256 private constant SCALING_FACTOR = 1e27;
    uint256 private constant BASE_DECIMALS = 27;

    struct FixedPointInt {
        int256 value;
    }

    /**
     * @notice constructs an `FixedPointInt` from an unscaled int, e.g., `b=5` gets stored internally as `5**27`.
     * @param a int to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledInt(int256 a) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.mul(SCALING_FACTOR));
    }

    /**
     * @notice constructs an FixedPointInt from an scaled uint with {_decimals} decimals
     * Examples:
     * (1)  USDC    decimals = 6
     *      Input:  5 * 1e6 USDC  =>    Output: 5 * 1e27 (FixedPoint 8.0 USDC)
     * (2)  cUSDC   decimals = 8
     *      Input:  5 * 1e6 cUSDC =>    Output: 5 * 1e25 (FixedPoint 0.08 cUSDC)
     * @param _a uint256 to convert into a FixedPoint.
     * @param _decimals  original decimals _a has
     * @return the converted FixedPoint, with 27 decimals.
     */
    function fromScaledUint(uint256 _a, uint256 _decimals) internal pure returns (FixedPointInt memory) {
        FixedPointInt memory fixedPoint;

        if (_decimals == BASE_DECIMALS) {
            fixedPoint = FixedPointInt(_a.uintToInt());
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals.sub(BASE_DECIMALS);
            fixedPoint = FixedPointInt((_a.div(10**exp)).uintToInt());
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            fixedPoint = FixedPointInt((_a.mul(10**exp)).uintToInt());
        }

        return fixedPoint;
    }

    /**
     * @notice convert a FixedPointInt number to an uint256 with a specific number of decimals
     * @param _a FixedPointInt to convert
     * @param _decimals number of decimals that the uint256 should be scaled to
     * @param _roundDown True to round down the result, False to round up
     * @return the converted uint256
     */
    function toScaledUint(
        FixedPointInt memory _a,
        uint256 _decimals,
        bool _roundDown
    ) internal pure returns (uint256) {
        uint256 scaledUint;

        if (_decimals == BASE_DECIMALS) {
            scaledUint = _a.value.intToUint();
        } else if (_decimals > BASE_DECIMALS) {
            uint256 exp = _decimals - BASE_DECIMALS;
            scaledUint = (_a.value).intToUint().mul(10**exp);
        } else {
            uint256 exp = BASE_DECIMALS - _decimals;
            uint256 tailing;
            if (!_roundDown) {
                uint256 remainer = (_a.value).intToUint().mod(10**exp);
                if (remainer > 0) tailing = 1;
            }
            scaledUint = (_a.value).intToUint().div(10**exp).add(tailing);
        }

        return scaledUint;
    }

    /**
     * @notice add two signed integers, a + b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return sum of the two signed integers
     */
    function add(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.add(b.value));
    }

    /**
     * @notice subtract two signed integers, a-b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return difference of two signed integers
     */
    function sub(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt(a.value.sub(b.value));
    }

    /**
     * @notice multiply two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return mul of two signed integers
     */
    function mul(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(b.value)) / SCALING_FACTOR);
    }

    /**
     * @notice divide two signed integers, a by b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return div of two signed integers
     */
    function div(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return FixedPointInt((a.value.mul(SCALING_FACTOR)) / b.value);
    }

    /**
     * @notice minimum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return min of two signed integers
     */
    function min(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value < b.value ? a : b;
    }

    /**
     * @notice maximum between two signed integers, a and b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return max of two signed integers
     */
    function max(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (FixedPointInt memory) {
        return a.value > b.value ? a : b;
    }

    /**
     * @notice is a is equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if equal, False if not
     */
    function isEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value == b.value;
    }

    /**
     * @notice is a greater than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a > b, False if not
     */
    function isGreaterThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value > b.value;
    }

    /**
     * @notice is a greater than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a >= b, False if not
     */
    function isGreaterThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value >= b.value;
    }

    /**
     * @notice is a is less than b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a < b, False if not
     */
    function isLessThan(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value < b.value;
    }

    /**
     * @notice is a less than or equal to b
     * @param a FixedPointInt
     * @param b FixedPointInt
     * @return True if a <= b, False if not
     */
    function isLessThanOrEqual(FixedPointInt memory a, FixedPointInt memory b) internal pure returns (bool) {
        return a.value <= b.value;
    }
}

/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity 0.8.4;
import { OtokenInterface } from "./packages/opynInterface/OtokenInterface.sol";
import { Actions } from "./packages/opynInterface/ActionsInterface.sol";

library OpynActionsLibrary {
    function _getOpenVaultAction(address _owner, uint256 _vaultId) internal pure returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.OpenVault,
                owner: _owner,
                vaultId: _vaultId,
                secondAddress: address(0),
                asset: address(0),
                amount: 0,
                index: 0,
                data: ""
            });
    }

    function _getSettleVaultAction(
        address _owner,
        uint256 _vaultId,
        address to
    ) internal pure returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.SettleVault,
                owner: _owner,
                vaultId: _vaultId,
                secondAddress: to,
                asset: address(0),
                amount: 0,
                index: 0,
                data: ""
            });
    }

    function _getDepositCollateralAction(
        address _owner,
        uint256 _vaultId,
        address _otoken,
        address _from,
        uint256 _amount
    ) internal pure returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.DepositCollateral,
                owner: _owner,
                vaultId: _vaultId,
                secondAddress: _from,
                asset: _otoken,
                amount: _amount,
                index: 0,
                data: ""
            });
    }

    function _getMintShortOptionAction(
        address _owner,
        uint256 _vaultId,
        address _otoken,
        address _to,
        uint256 _amount
    ) internal pure returns (Actions.ActionArgs memory) {
        return
            Actions.ActionArgs({
                actionType: Actions.ActionType.MintShortOption,
                owner: _owner,
                vaultId: _vaultId,
                secondAddress: _to,
                asset: _otoken,
                amount: _amount,
                index: 0,
                data: ""
            });
    }

    function _actionArgsToDepositCollateralAndMintOtokens(
        uint256 _vaultId,
        OtokenInterface _otoken,
        address _collateralToken,
        uint256 _collateralAmount,
        uint256 _orderSizeInOtokens
    ) internal view returns (Actions.ActionArgs[] memory opynActions) {
        // Deposit collateral and mint options straight to the buyer
        opynActions = new Actions.ActionArgs[](2);
        opynActions[0] = _getDepositCollateralAction(
            address(this),
            _vaultId,
            address(_collateralToken),
            address(this),
            _collateralAmount
        );
        opynActions[1] = _getMintShortOptionAction(
            address(this),
            _vaultId,
            address(_otoken),
            msg.sender,
            _orderSizeInOtokens
        );

        return opynActions;
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: WTFPL
pragma solidity 0.8.4;

import "./PRBMathCommon.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math. It works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            require(x > MIN_SD59x18);
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        require(x <= MAX_WHOLE_SD59x18);
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMathCommon.mulDiv".
    /// - None of the inputs can be type(int256).min.
    /// - y cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMathCommon.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > type(int256).min);
        require(y > type(int256).min);

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 resultUnsigned = PRBMathCommon.mulDiv(ax, uint256(SCALE), ay);
        require(resultUnsigned <= uint256(type(int256).max));

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(resultUnsigned) : int256(resultUnsigned);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 88.722839111672999628.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 128e18.
        require(x < 88722839111672999628);

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 128e18 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2**59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2**128 doesn't fit within the 128.128-bit fixed-point representation.
            require(x < 128e18);

            unchecked {
                // Convert x to the 128.128-bit fixed-point format.
                uint256 x128x128 = (uint256(x) << 128) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 128e18.
                result = int256(PRBMathCommon.exp2(x128x128));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimised for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        require(x >= MIN_WHOLE_SD59x18);
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            require(x >= MIN_SD59x18 / SCALE && x <= MAX_SD59x18 / SCALE);
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            require(xy / x == y);

            // The product cannot be negative.
            require(xy >= 0);

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMathCommon.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding towards zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
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
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
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
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        require(x > 0);

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
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
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 332192809488736234;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        require(x > 0);
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMathCommon.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// alawys 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMathCommon.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > MIN_SD59x18);
        require(y > MIN_SD59x18);

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 resultUnsigned = PRBMathCommon.mulDivFixedPoint(ax, ay);
            require(resultUnsigned <= uint256(MAX_SD59x18));

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(resultUnsigned) : int256(resultUnsigned);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMathCommon.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMathCommon.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 absX = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 absResult = y & 1 > 0 ? absX : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            absX = PRBMathCommon.mulDivFixedPoint(absX, absX);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                absResult = PRBMathCommon.mulDivFixedPoint(absResult, absX);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        require(absResult <= uint256(MAX_SD59x18));

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(absResult) : int256(absResult);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// Caveats:
    /// - The maximum fixed-point number permitted is 57896044618658097711785492504343953926634.992332820282019729.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        require(x >= 0);
        require(x < 57896044618658097711785492504343953926634992332820282019729);
        unchecked {
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMathCommon.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // POTION FUNCTIONS
    //
    // The code ABOVE is unchanged from V1.1.0 of the PRB-math library at https://github.com/hifi-finance/prb-math
    // (npm module `prb-math`). It is copied under the terms of its WTFPL license.
    //
    // The code BELOW is not part of that original library and has been added by Potion.
    //
    ///////////////////////////////////////////////////////////////////////////
    uint256 internal constant MAX_UINT_CONVERTIBLE_TO_SD59x18 = uint256(MAX_SD59x18) / uint256(SCALE);

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Created for convenience to allow creation of signed decimals from unsiged ints.
    /// Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (int256 result) {
        require(x <= MAX_UINT_CONVERTIBLE_TO_SD59x18);
        return fromInt(int256(x));
    }

    /// @notice Adds two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal fixed-point number.
    /// @dev Created for convenience, to allow use of the `x.add(y)` notation. Solidity V0.8's overflow checks are sufficient to ensure safety.
    /// @param x An addend as a signed 59.18-decimal fixed-point number.
    /// @param y An addend as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function add(int256 x, int256 y) internal pure returns (int256 result) {
        result = x + y;
    }

    //
    /// @notice Subtracts one signed 59.18-decimal fixed-point number from another signed 59.18-decimal fixed-point number, returning a new signed 59.18-decimal fixed-point number.
    /// @dev Created for convenience, to allow the `x.sub(y)` notation. Solidity V0.8's overflow checks are sufficient to ensure safety.
    /// @param x The minuend as a signed 59.18-decimal fixed-point number.
    /// @param y The subtrahend as a signed 59.18-decimal fixed-point number.
    /// @return result The difference as a signed 59.18-decimal fixed-point number.
    function sub(int256 x, int256 y) internal pure returns (int256 result) {
        result = x - y;
    }

    /// @notice Converts a non-negative, signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed, non-negative 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(int256 x) internal pure returns (uint256 result) {
        require(x >= 0);
        unchecked {
            result = uint256(x / SCALE);
        }
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

/**
 * @title MarginVaultInterface
 * @author Opyn & Potion Team
 * @notice A library that provides the Controller with a Vault struct and the functions that manipulate vaults.
 * Vaults describe discrete position combinations of long options, short options, and collateral assets that a user can have.
 */
library MarginVaultInterface {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral in order to write oTokens against (i.e. in spreads)
        address[] longOtokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address in shortOtokens
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address in longOtokens
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMathUpgradeable {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.4;

/**
 * @title SignedConverter
 * @author Opyn Team
 * @notice A library to convert an unsigned integer to signed integer or signed integer to unsigned integer.
 */
library SignedConverter {
    /**
     * @notice convert an unsigned integer to a signed integer
     * @param a uint to convert into a signed integer
     * @return converted signed integer
     */
    function uintToInt(uint256 a) internal pure returns (int256) {
        require(a < 2**255, "FixedPointInt256: out of int range");

        return int256(a);
    }

    /**
     * @notice convert a signed integer to an unsigned integer
     * @param a int to convert into an unsigned integer
     * @return converted unsigned integer
     */
    function intToUint(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(-a);
        } else {
            return uint256(a);
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

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
// representation. When it does not, it is annonated in the function's NatSpec documentation.
library PRBMathCommon {
    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661508869554232690281;

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Uses 128.128-bit fixed-point numbers, which is the most efficient way.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 128.128-bit fixed-point number.
    /// @return result The result as an unsigned 60x18 decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 128.128-bit fixed-point format.
            result = 0x80000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^127 and all magic factors are less than 2^129.
            if (x & 0x80000000000000000000000000000000 > 0)
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x40000000000000000000000000000000 > 0)
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDED) >> 128;
            if (x & 0x20000000000000000000000000000000 > 0)
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A7920) >> 128;
            if (x & 0x10000000000000000000000000000000 > 0)
                result = (result * 0x10B5586CF9890F6298B92B71842A98364) >> 128;
            if (x & 0x8000000000000000000000000000000 > 0)
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FE) >> 128;
            if (x & 0x4000000000000000000000000000000 > 0)
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE9) >> 128;
            if (x & 0x2000000000000000000000000000000 > 0)
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA40) >> 128;
            if (x & 0x1000000000000000000000000000000 > 0)
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9544) >> 128;
            if (x & 0x800000000000000000000000000000 > 0)
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679C) >> 128;
            if (x & 0x400000000000000000000000000000 > 0)
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A011) >> 128;
            if (x & 0x200000000000000000000000000000 > 0)
                result = (result * 0x100162F3904051FA128BCA9C55C31E5E0) >> 128;
            if (x & 0x100000000000000000000000000000 > 0)
                result = (result * 0x1000B175EFFDC76BA38E31671CA939726) >> 128;
            if (x & 0x80000000000000000000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3E) >> 128;
            if (x & 0x40000000000000000000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B4) >> 128;
            if (x & 0x20000000000000000000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292027) >> 128;
            if (x & 0x10000000000000000000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FD) >> 128;
            if (x & 0x8000000000000000000000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAC) >> 128;
            if (x & 0x4000000000000000000000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7CA) >> 128;
            if (x & 0x2000000000000000000000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x1000000000000000000000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x800000000000000000000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1629) >> 128;
            if (x & 0x400000000000000000000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2C) >> 128;
            if (x & 0x200000000000000000000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A6) >> 128;
            if (x & 0x100000000000000000000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFF) >> 128;
            if (x & 0x80000000000000000000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2F0) >> 128;
            if (x & 0x40000000000000000000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737B) >> 128;
            if (x & 0x20000000000000000000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F07) >> 128;
            if (x & 0x10000000000000000000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44FA) >> 128;
            if (x & 0x8000000000000000000000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC824) >> 128;
            if (x & 0x4000000000000000000000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE51) >> 128;
            if (x & 0x2000000000000000000000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFD0) >> 128;
            if (x & 0x1000000000000000000000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x800000000000000000000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AE) >> 128;
            if (x & 0x400000000000000000000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CD) >> 128;
            if (x & 0x200000000000000000000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x100000000000000000000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AF) >> 128;
            if (x & 0x80000000000000000000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCF) >> 128;
            if (x & 0x40000000000000000000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0E) >> 128;
            if (x & 0x20000000000000000000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x10000000000000000000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94D) >> 128;
            if (x & 0x8000000000000000000000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33E) >> 128;
            if (x & 0x4000000000000000000000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26946) >> 128;
            if (x & 0x2000000000000000000000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388D) >> 128;
            if (x & 0x1000000000000000000000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D41) >> 128;
            if (x & 0x800000000000000000000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDF) >> 128;
            if (x & 0x400000000000000000000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77F) >> 128;
            if (x & 0x200000000000000000000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C3) >> 128;
            if (x & 0x100000000000000000000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E3) >> 128;
            if (x & 0x80000000000000000000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F2) >> 128;
            if (x & 0x40000000000000000000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA39) >> 128;
            if (x & 0x20000000000000000000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x10000000000000000000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x8000000000000000000 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x4000000000000000000 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x2000000000000000000 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D92) >> 128;
            if (x & 0x1000000000000000000 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x800000000000000000 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE545) >> 128;
            if (x & 0x400000000000000000 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x200000000000000000 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x100000000000000000 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x80000000000000000 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6E) >> 128;
            if (x & 0x40000000000000000 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B3) >> 128;
            if (x & 0x20000000000000000 > 0) result = (result * 0x1000000000000000162E42FEFA39EF359) >> 128;
            if (x & 0x10000000000000000 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AC) >> 128;

            // We do two things at the same time below:
            //
            //     1. Multiply the result by 2^n + 1, where 2^n is the integer part and 1 is an extra bit to account
            //        for the fact that we initially set the result to 0.5 We implement this by subtracting from 127
            //        instead of 128.
            //     2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because result * SCALE * 2^ip / 2^127 = result * SCALE / 2^(127 - ip), where ip is the integer
            // part and SCALE / 2^128 is what converts the result to our unsigned fixed-point format.
            result *= SCALE;
            result >>= (127 - (x >> 128));
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
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2**256 and mod 2**256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256. Also prevents denominator == 0.
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number
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

                // Flip lpotdod such that it is 2**256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2**256. Now that denominator is an odd number, it has an inverse modulo 2**256 such
            // that denominator * inv = 1 mod 2**256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2**8
            inverse *= 2 - denominator * inverse; // inverse mod 2**16
            inverse *= 2 - denominator * inverse; // inverse mod 2**32
            inverse *= 2 - denominator * inverse; // inverse mod 2**64
            inverse *= 2 - denominator * inverse; // inverse mod 2**128
            inverse *= 2 - denominator * inverse; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2**256. Since the precoditions guarantee that the outcome is
            // less than 2**256, this is the final result. We don't need to compute the high bits of the result and prod1
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
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMathCommon.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two queations:
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

        require(SCALE > prod1);

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
        require(x > type(int256).min);
        require(y > type(int256).min);
        require(denominator > type(int256).min);

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
        uint256 resultUnsigned = mulDiv(ax, ay, ad);
        require(resultUnsigned <= uint256(type(int256).max));

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
        result = sx ^ sy ^ sd == 0 ? -int256(resultUnsigned) : int256(resultUnsigned);
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

        // Set the initial guess to the closest power of two that is higher than x.
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