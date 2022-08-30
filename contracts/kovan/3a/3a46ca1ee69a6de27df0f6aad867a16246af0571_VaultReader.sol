// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens a user has shorted (i.e. written) against this vault
        address[] shortOtokens;
        // addresses of oTokens a user has bought and deposited in this vault
        // user can be long oTokens without opening a vault (e.g. by buying on a DEX)
        // generally, long oTokens will be 'deposited' in vaults to act as collateral
        // in order to write oTokens against (i.e. in spreads)
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

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

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

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
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
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(address _otoken, uint256 _amount)
        external
        view
        returns (uint256);

    function operate(ActionArgs[] calldata _actions) external;

    function getAccountVaultCounter(address owner)
        external
        view
        returns (uint256);

    function oracle() external view returns (address);

    function getVault(address _owner, uint256 _vaultId)
        external
        view
        returns (GammaTypes.Vault memory);

    function getProceed(address _owner, uint256 _vaultId)
        external
        view
        returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);
}

interface IOracle {
    function setAssetPricer(address _asset, address _pricer) external;

    function updateAssetPricer(address _asset, address _pricer) external;

    function getPrice(address _asset) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.4;


import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IOtoken} from "../interfaces/GammaInterface.sol";
import {PolysynthThetaVaultWithSwap} from "../vaults/BaseVaultWithSwap/PolysynthThetaVaultWithSwap.sol";
import {PolysynthPool} from "../pools/BasePool/PolysynthPool.sol";
import {Pool} from "../libraries/Pool.sol";

contract VaultReader is Initializable, OwnableUpgradeable{
    struct TraderShare {
        address trader;
        uint256 share;
    }

    struct VaultShares {
        address vaultAddress;
        uint16 round;
        uint256 expiry;
        uint256 decimals;
        TraderShare[] shares;
    }

    struct VaultBorrow {
        address vault;
        uint256 borrowed;
    }

    struct PoolMeta {
        address pool;
        uint16 round;
        uint32 expiry;
        uint256 totalBorrowed;
        uint256 utilizationRate;
        uint256 availableLiquidity;
        uint256 dps;
        uint256 lps;
        VaultBorrow[] vaults;
    }

        function initialize() public initializer {
        __Ownable_init();
    }


    function getShares(address _vault,address[] memory _traders) public view returns(VaultShares memory){
        PolysynthThetaVaultWithSwap vault =PolysynthThetaVaultWithSwap(_vault);
        (uint16 round,,,,) = vault.vaultState();
        (,address currOp,) = vault.optionState();
        IOtoken oToken = IOtoken(currOp);

        TraderShare[] memory shares = new TraderShare[](_traders.length);
        for (uint256 i = 0; i < _traders.length; i++) {
            uint256 totalShare = vault.shares(_traders[i]);
            (uint16 wRound, uint128 ws) = vault.withdrawals(_traders[i]);
            if(round == wRound) {
                totalShare += ws;
            }
            shares[i] = TraderShare({trader: _traders[i], share: totalShare});
        }

        return VaultShares(
            {
            vaultAddress: _vault, 
            round: round,
            expiry:oToken.expiryTimestamp(),
            decimals:vault.decimals(),
            shares: shares
            });
    }

    function allPPS(address _vault) public view returns (uint256[] memory){
        PolysynthThetaVaultWithSwap vault =PolysynthThetaVaultWithSwap(_vault);
        (uint16 round,,,,) = vault.vaultState();

        uint256[] memory pps = new uint256[](round);
        pps[0] = 0;
        for (uint256 i = 1; i < round; i++) {
            pps[i] = vault.roundPricePerShare(i);
        }

        return pps;
    }

    function poolMeta(address _pool) public view returns (PoolMeta memory) {
        PolysynthPool pool = PolysynthPool(_pool);
        (uint16 round,,,,,,uint256 totalBorrowed,uint32 expiry,,) = pool.poolState();
        uint256 uR = pool.currentUtilizationRate();
        uint256 aL = pool.availableBorrowLimit();
        (uint256 dps, uint256 lps) = pool.pricePerShares(0);

        address[] memory vs = pool.getVaults();

        uint256 vLength = vs.length;
        VaultBorrow[] memory vaults = new VaultBorrow[](vLength);
        for (uint256 i = 0; i < vLength; i++) {
            uint256 vB = pool.getVaultBorrowed(vs[i]);
            vaults[i] = VaultBorrow({vault:vs[i],borrowed:vB});
        }

        return PoolMeta({
            pool: _pool,
            round: round,
            expiry: expiry,
            totalBorrowed: totalBorrowed,
            utilizationRate: uR,
            availableLiquidity: aL,
            dps: dps,
            lps:lps,
            vaults: vaults
        });
    }
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
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwap} from "../../interfaces/ISwap.sol";
import {
    PolysynthThetaVaultStorage
} from "../../storage/PolysynthThetaVaultStorage.sol";
import {Vault} from "../../libraries/Vault.sol";
import {
    VaultLifecycleWithSwap
} from "../../libraries/VaultLifecycleWithSwap.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {ILiquidityGauge} from "../../interfaces/ILiquidityGauge.sol";
import {PolysynthVault} from "./base/PolysynthVault.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in PolysynthThetaVaultStorage.
 * PolysynthThetaVault should not inherit from any other contract aside from PolysynthVault, PolysynthThetaVaultStorage
 */
contract PolysynthThetaVaultWithSwap is PolysynthVault, PolysynthThetaVaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public immutable OTOKEN_FACTORY;

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    /************************************************
     *  EVENTS
     ***********************************************/

    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address indexed manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address indexed manager
    );

    event NewOptionStrikeSelected(uint256 strikePrice, uint256 delta);

    event PremiumDiscountSet(
        uint256 premiumDiscount,
        uint256 newPremiumDiscount
    );

    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event NewOffer(
        uint256 swapId,
        address seller,
        address oToken,
        address biddingToken,
        uint256 minPrice,
        uint256 minBidSize,
        uint256 totalSize
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     * @param _premiumDiscount is the vault's discount applied to the premium
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _optionsPremiumPricer;
        address _strikeSelection;
        uint32 _premiumDiscount;
    }

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _oTokenFactory is the contract address for minting new opyn option types (strikes, asset, expiry)
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _swapContract is the contract address that facilitates bids settlement
     */
    constructor(
        address _weth,
        address _usdc,
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _swapContract
    ) PolysynthVault(_weth, _usdc, _gammaController, _marginPool, _swapContract) {
        require(_oTokenFactory != address(0), "!_oTokenFactory");
        OTOKEN_FACTORY = _oTokenFactory;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(
            _initParams._owner,
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _vaultParams
        );
        require(
            _initParams._optionsPremiumPricer != address(0),
            "!_optionsPremiumPricer"
        );
        require(
            _initParams._strikeSelection != address(0),
            "!_strikeSelection"
        );
        require(
            _initParams._premiumDiscount > 0 &&
                _initParams._premiumDiscount <
                100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "!_premiumDiscount"
        );

        optionsPremiumPricer = _initParams._optionsPremiumPricer;
        strikeSelection = _initParams._strikeSelection;
        premiumDiscount = _initParams._premiumDiscount;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new discount on premiums for options we are selling
     * @param newPremiumDiscount is the premium discount
     */
    function setPremiumDiscount(uint256 newPremiumDiscount)
        external
        onlyKeeper
    {
        require(
            newPremiumDiscount > 0 &&
                newPremiumDiscount <= 100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "Invalid discount"
        );

        emit PremiumDiscountSet(premiumDiscount, newPremiumDiscount);

        premiumDiscount = newPremiumDiscount;
    }

    /**
     * @notice Sets the new auction duration
     * @param newAuctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        require(
            newAuctionDuration >= MIN_AUCTION_DURATION,
            "Invalid auction duration"
        );

        emit AuctionDurationSet(auctionDuration, newAuctionDuration);

        auctionDuration = newAuctionDuration;
    }

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    function setStrikeSelection(address newStrikeSelection) external onlyOwner {
        require(newStrikeSelection != address(0), "!newStrikeSelection");
        strikeSelection = newStrikeSelection;
    }

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    function setOptionsPremiumPricer(address newOptionsPremiumPricer)
        external
        onlyOwner
    {
        require(
            newOptionsPremiumPricer != address(0),
            "!newOptionsPremiumPricer"
        );
        optionsPremiumPricer = newOptionsPremiumPricer;
    }

    /**
     * @notice Optionality to set strike price manually
     * Should be called after closeRound if we are setting current week's strike
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external onlyOwner {
        require(strikePrice > 0, "!strikePrice");
        overriddenStrikePrice = strikePrice;
        lastStrikeOverrideRound = vaultState.round;
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
        liquidityGauge = newLiquidityGauge;
    }

    /**
     * @notice Sets oToken Premium
     * @param minPrice is the new oToken Premium in the units of 10**18
     */
    function setMinPrice(uint256 minPrice) external onlyKeeper {
        require(minPrice > 0, "!minPrice");
        currentOtokenPremium = minPrice;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(amount));
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending).sub(amount)
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        transferAsset(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares.add(
            numShares
        );
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        );
    }

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external nonReentrant {
        address _liquidityGauge = liquidityGauge;
        require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
        require(numShares > 0);
        uint256 heldByAccount = balanceOf(msg.sender);
        if (heldByAccount < numShares) {
            _redeem(numShares.sub(heldByAccount), false);
        }
        _transfer(msg.sender, address(this), numShares);
        _approve(address(this), _liquidityGauge, numShares);
        ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    }

    /**
     * @notice Closes the existing short and calculate the shares to mint, new price per share &
      amount of funds to re-allocate as collateral for the new round
     * Since we are incrementing the round here, the options are sold in the beginning of a round
     * instead of at the end of the round. For example, at round 1, we don't sell any options. We
     * start selling options at the beginning of round 2.
     */
    function closeRound() external nonReentrant {
        address oldOption = optionState.currentOption;
        require(
            oldOption != address(0) || vaultState.round == 1,
            "Round closed"
        );
        _closeShort(optionState.currentOption);

        uint256 currQueuedWithdrawShares = currentQueuedWithdrawShares;
        (uint256 lockedBalance, uint256 queuedWithdrawAmount) =
            _closeRound(
                uint256(lastQueuedWithdrawAmount),
                currQueuedWithdrawShares
            );

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares).add(
                currQueuedWithdrawShares
            );
        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        ShareMath.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);

        uint256 nextOptionReady = block.timestamp.add(DELAY);
        require(
            nextOptionReady <= type(uint32).max,
            "Overflow nextOptionReady"
        );
        optionState.nextOptionReadyAt = uint32(nextOptionReady);
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort(address oldOption) private {
        uint256 lockedAmount = vaultState.lockedAmount;
        if (oldOption != address(0)) {
            vaultState.lastLockedAmount = uint104(lockedAmount);
        }
        vaultState.lockedAmount = 0;

        optionState.currentOption = address(0);

        if (oldOption != address(0)) {
            uint256 withdrawAmount =
                VaultLifecycleWithSwap.settleShort(GAMMA_CONTROLLER);
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
    }

    /**
     * @notice Sets the next option the vault will be shorting
     */
    function commitNextOption() external onlyKeeper nonReentrant {
        address currentOption = optionState.currentOption;
        require(
            currentOption == address(0) && vaultState.round != 1,
            "Round not closed"
        );

        VaultLifecycleWithSwap.CommitParams memory commitParams =
            VaultLifecycleWithSwap.CommitParams({
                OTOKEN_FACTORY: OTOKEN_FACTORY,
                USDC: USDC,
                currentOption: currentOption,
                delay: DELAY,
                lastStrikeOverrideRound: lastStrikeOverrideRound,
                overriddenStrikePrice: overriddenStrikePrice,
                strikeSelection: strikeSelection,
                optionsPremiumPricer: optionsPremiumPricer,
                premiumDiscount: premiumDiscount
            });

        (address otokenAddress, uint256 strikePrice, uint256 delta) =
            VaultLifecycleWithSwap.commitNextOption(
                commitParams,
                vaultParams,
                vaultState
            );

        emit NewOptionStrikeSelected(strikePrice, delta);

        optionState.nextOption = otokenAddress;
    }

    /**
     * @notice Rolls the vault's funds into a new short position and create a new offer.
     */
    function rollToNextOption() external onlyKeeper nonReentrant {
        address newOption = optionState.nextOption;
        require(newOption != address(0), "!nextOption");

        optionState.currentOption = newOption;
        optionState.nextOption = address(0);
        uint256 lockedBalance = vaultState.lockedAmount;

        emit OpenShort(newOption, lockedBalance, msg.sender);

        VaultLifecycleWithSwap.createShort(
            GAMMA_CONTROLLER,
            MARGIN_POOL,
            newOption,
            lockedBalance
        );

        _createOffer();
    }

    /**
     * @notice Create offer in the swap contract.
     */
    function createOffer() external onlyKeeper nonReentrant {
        _createOffer();
    }

    function _createOffer() private {
        address currentOtoken = optionState.currentOption;
        uint256 currOtokenPremium = currentOtokenPremium;

        optionAuctionID = VaultLifecycleWithSwap.createOffer(
            currentOtoken,
            currOtokenPremium,
            SWAP_CONTRACT,
            vaultParams
        );
    }

    /**
     * @notice Settle current offer
     */
    function settleOffer(ISwap.Bid[] calldata bids)
        external
        onlyKeeper
        nonReentrant
    {
        ISwap(SWAP_CONTRACT).settleOffer(optionAuctionID, bids);
    }

    /**
     * @notice Burn the remaining oTokens left over
     */
    function burnRemainingOTokens() external onlyKeeper nonReentrant {
        uint256 unlockedAssetAmount =
            VaultLifecycleWithSwap.burnOtokens(
                GAMMA_CONTROLLER,
                optionState.currentOption
            );

        vaultState.lockedAmount = uint104(
            uint256(vaultState.lockedAmount).sub(unlockedAssetAmount)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import "hardhat/console.sol";

import {Pool} from "../../libraries/Pool.sol";
import {MathUtils} from "../../utils/MathUtils.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../../interfaces/IWETH.sol";
import {ILiquidity} from "../../interfaces/ILiquidity.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ShareMathPool} from "../../libraries/ShareMathPool.sol";

import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract PolysynthPool is OwnableUpgradeable,ReentrancyGuardUpgradeable,ERC20Upgradeable,ILiquidity{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMathPool for Pool.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Pool.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the liquidity pricePerShare value of the pool is stored
    /// This is used to determine the number of shares to be returned
    /// to the provider with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundSupplyPricePerShare;

    /// @notice On every round's close, the debt pricePerShare value of the pool is stored
    /// This is used to determine the debt accrued by the trader
    /// with their borrowReceipt in respective vault
    mapping(uint256 => uint256) public roundDebtPricePerShare;

    /// @notice On every round's start, the utilization rate of the pool is stored
    /// This is used to determine the borrow rate of the round
    /// and also both pricePerShares
    uint256 public currentUtilizationRate;

    /// @notice On every round's start, the borrow rate of the pool is stored
    /// This is used to determine the pricePerShares
    uint256 public currentBorrowRate;

    uint256 private lastRepaidAmount;

    uint256 private lastPoolBalance;

    /// @notice Stores pending user withdrawals
    mapping(address => Pool.Withdrawal) public withdrawals;

    address[] public verifiedVaults;

    mapping(address => uint256) private totalVaultBorrow;

    /// @notice Pool's parameters like cap, decimals
    Pool.PoolParams public poolParams;

    /// @notice Pool's lifecycle state like round and locked amounts
    Pool.PoolState public poolState;

    /// @notice role in charge of weekly pool operations such as closeRound
    // no access to critical vault changes
    address public keeper;

    // Queued withdraw shares for the current round
    // uint256 public currentQueuedWithdrawShares;

    // Amount locked for scheduled withdrawals last week;
    // uint256 public lastQueuedWithdrawAmount;


    // Gap is left to avoid storage collisions. Though PolysynthPool is not upgradeable, we add this as a safety measure.
    uint256[30] private ____gap;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    uint32 public immutable POOL_EXPIRY_PERIOD;

    uint256 public U0_TARGET_UTILIZATION_RATE = (75 * MathUtils.ray())/10**2;

    uint256 public R0_BASE_BORROW_RATE = (2 * MathUtils.ray())/10**2;

    uint256 public R2_INTEREST_RATE_SLOPE_ABOVE_U0 = (75 * MathUtils.ray())/10**2;

    uint256 public R1_INTEREST_RATE_SLOPE_BELOW_U0 = (15 * MathUtils.ray())/10**2;

    uint256 internal constant PLACEHOLDER_UINT = 1;


    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event VaultAdded(address indexed vault);
    event VaultRemoved(address indexed vault);


    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/
    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract     
     */
    constructor(
        address _weth,
        uint32 _expiry
    ) {
        require(_weth != address(0), "!_weth");
        require(_expiry!=0, "!_expiry");

        WETH = _weth;
        POOL_EXPIRY_PERIOD = _expiry;
    }

    function initialize(
        address _owner,
        address _keeper,
        string memory _tokenName,
        string memory _tokenSymbol,
        Pool.PoolParams calldata _poolParams
    ) external initializer {

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        keeper = _keeper;
        
        poolParams = _poolParams;

        // uint256 assetBalance =
        //     IERC20(poolParams.asset).balanceOf(address(this));
        // ShareMath.assertUint104(assetBalance);
        // vaultState.lastLockedAmount = uint104(assetBalance);

        poolState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "!newKeeper");
        keeper = newKeeper;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMathPool.assertUint104(newCap);
        emit CapSet(poolParams.cap, newCap);
        poolParams.cap = uint104(newCap);
    }

    function addVault(address _vault) external onlyOwner {
        require(!isVaultAdded(_vault), "vault already added");
        verifiedVaults.push(_vault);

        emit VaultAdded(_vault);
    }

    function removeVault(address _vault) external onlyOwner {
        uint256 vaultLength = verifiedVaults.length;
        for (uint256 i = 0; i < vaultLength; i++) {
            if (verifiedVaults[i] == _vault) {
                verifiedVaults[i] = verifiedVaults[vaultLength - 1];
                verifiedVaults.pop();
                emit VaultRemoved(_vault);
                break;
            }
        }
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the asset is not WETH.
     */
    function depositETH() external payable nonReentrant {
        require(poolParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);
        
        // An approve() by the msg.sender is required beforehand
        IERC20(poolParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Pool.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];
        
        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound(), "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        isAmountWithdrawable(amount);
        
        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(amount));
        poolState.totalPending = uint128(
            uint256(poolState.totalPending).sub(amount)
        );

        emit InstantWithdraw(msg.sender, amount, currentRound());

        transferAsset(msg.sender, amount);
    }


    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        poolState.queuedWithdrawShares = poolState.queuedWithdrawShares + uint128(numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        _completeWithdraw();
        // lastQueuedWithdrawAmount = uint128(
        //     uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        // );
    }


    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "!amount");
        require(creditor != address(0));

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(poolParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /************************************************
     *  POOL OPERATIONS
     ***********************************************/

     function close() external nonReentrant onlyKeeper{
        require(block.timestamp>poolState.nextPoolReadyAt, "early close");        
        // 1. Update LPS,DPS of the pool

        uint256 newRoundDPS;
        uint256 newRoundLPS;

        if (currentRound()==1) {
            newRoundDPS = MathUtils.ray();
            newRoundLPS = MathUtils.ray();
        } else {            
            uint256 prevRoundDPS = roundDebtPricePerShare[currentRound()-1];
            newRoundDPS = prevRoundDPS.mul(MathUtils.calculateCompoundedInterest(
                currentBorrowRate,
                poolState.lastRateUpdateTime
                )).div(MathUtils.ray());            

            uint256 prevRoundLPS = roundSupplyPricePerShare[currentRound()-1];
            newRoundLPS = prevRoundLPS.mul(MathUtils.calculateLinearInterest(
                currentBorrowRate,
                currentUtilizationRate,
                poolState.lastRateUpdateTime
                )).div(MathUtils.ray());

            console.log("here - ", currentRound(), prevRoundDPS, newRoundDPS);
            console.log("here - lps", currentRound(), prevRoundLPS, newRoundLPS);
            console.log("currentBorrowRate", currentBorrowRate, currentUtilizationRate);
        }
        
        roundDebtPricePerShare[currentRound()] = newRoundDPS;
        roundSupplyPricePerShare[currentRound()] = newRoundLPS;
        
        poolState.round +=1;
        poolState.lastRateUpdateTime = uint32(block.timestamp);
        poolState.nextPoolReadyAt = uint32(block.timestamp.add(POOL_EXPIRY_PERIOD));

        // uint256 newQueuedWithdrawShares =
        //     uint256(poolState.queuedWithdrawShares).add(
        //         currQueuedWithdrawShares
        //     );
        // ShareMath.assertUint128(newQueuedWithdrawShares);
        // poolState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        // Mint new shares
        uint256 mintShares = uint256(poolState.totalPending).mul(MathUtils.ray()).div(newRoundLPS);

        poolState.totalPending = 0;

        _mint(address(this), mintShares);

        // Get withdraw amount for this round, and add it to total withdraw amount        
     }

    function rollover() external nonReentrant onlyKeeper{        
        //TODO: Check if round is closed        
        // Calculate borrow rate and store 
        console.log("totalDebtShares", poolState.totalDebtShares, totalSupply(), poolState.queuedWithdrawShares);
        currentUtilizationRate = uint256(poolState.totalDebtShares)
        .mul(roundDebtPricePerShare[poolState.round-1])
        .mul(MathUtils.ray())
        .div(totalSupply()-poolState.queuedWithdrawShares)
        .div(roundSupplyPricePerShare[poolState.round-1]);

        currentBorrowRate = currentUtilizationRate<U0_TARGET_UTILIZATION_RATE
            ?   R0_BASE_BORROW_RATE+currentUtilizationRate.mul(R1_INTEREST_RATE_SLOPE_BELOW_U0).div(U0_TARGET_UTILIZATION_RATE)
            :   R0_BASE_BORROW_RATE+R1_INTEREST_RATE_SLOPE_BELOW_U0+uint256(currentUtilizationRate-U0_TARGET_UTILIZATION_RATE).mul(R2_INTEREST_RATE_SLOPE_ABOVE_U0).div(MathUtils.ray()-U0_TARGET_UTILIZATION_RATE);

        
        uint256 repay;

        lastPoolBalance = IERC20(poolParams.asset).balanceOf(address(this));
    }

    function borrow(uint256 borrowAmount, uint256 repaidAmount, uint256 newDebtShares, uint256 repaidDebtShares) external override nonReentrant {
        require(isVaultAdded(msg.sender), "invalid vault");

        require(poolState.lockedByVault[msg.sender] == uint128(borrowAmount), "vault borrow amount mismatch");

        console.log(borrowAmount , repaidAmount,newDebtShares,repaidDebtShares);


        poolState.pendingBorrowAmount -= uint128(borrowAmount);
        poolState.totalBorrowAmount  += uint128(borrowAmount);
        poolState.totalBorrowAmount  -= uint128(repaidAmount);
        lastRepaidAmount += repaidAmount;

        poolState.totalDebtShares += uint128(newDebtShares);
        poolState.totalDebtShares -= uint128(repaidDebtShares);

        poolState.lockedByVault[msg.sender] = 0;
        totalVaultBorrow[msg.sender] += uint128(borrowAmount);
        totalVaultBorrow[msg.sender] -= uint128(repaidAmount);


        IERC20(poolParams.asset).transfer(msg.sender, borrowAmount);
    }

    /************************************************
     *  INTERNAL OPERATIONS
     ***********************************************/
    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {        
        //TODO: Check this condition
        // uint256 totalWithDepositedAmount = totalBalance().add(amount);

        // require(totalWithDepositedAmount <= poolParams.cap, "Exceed cap");
        // require(
        //     totalWithDepositedAmount >= poolParams.minimumSupply,
        //     "Insufficient balance"
        // );

        emit Deposit(creditor, amount, currentRound());

        Pool.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound(),
                roundSupplyPricePerShare[depositReceipt.round],
                poolParams.decimals
            );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound() == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMathPool.assertUint104(depositAmount);

        depositReceipts[creditor] = Pool.DepositReceipt({
            round: uint16(currentRound()),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(poolState.totalPending).add(amount);
        ShareMathPool.assertUint128(newTotalPending);

        poolState.totalPending = uint128(newTotalPending);
    }

/**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // Only able to withdraw shares, which have notional value
        //less than the current free amount in the pool
        areSharesWithdrawable(numShares);

        // This caches the `round` variable used in shareBalances        
        Pool.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound();

        emit InitiateWithdraw(msg.sender, numShares, currentRound());

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound());
        }

        ShareMathPool.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Pool.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < poolState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        poolState.queuedWithdrawShares = uint128(
            uint256(poolState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMathPool.sharesToAsset(
                withdrawalShares,
                roundSupplyPricePerShare[withdrawalRound],
                poolParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        require(withdrawAmount > 0, "!withdrawAmount");

        // if(withdrawalFee>0){
        //     uint256 fee = withdrawAmount.mul(withdrawalFee).div(100 * Pool.FEE_MULTIPLIER);
        //     withdrawAmount -= fee;
        // }

        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Pool.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`        

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound(),
                roundSupplyPricePerShare[depositReceipt.round],
                poolParams.decimals
            );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound()) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMathPool.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(numShares)
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    function lockAmount(uint256 _amount) external override {
        require(isVaultAdded(msg.sender), "invalid vault");
        
        poolState.pendingBorrowAmount += uint128(_amount);
        poolState.lockedByVault[msg.sender] += uint128(_amount);
    }


    function unlockAmount(uint256 _amount) external override {
        require(isVaultAdded(msg.sender), "invalid vault");

        poolState.pendingBorrowAmount -= uint128(_amount);
        poolState.lockedByVault[msg.sender] += uint128(_amount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        address asset = poolParams.asset;
        if (asset == WETH) {
            console.log("WETH", WETH, amount, recipient);
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    function isAmountWithdrawable(uint256 amount) internal view{
        require(amount<=_freePoolBalance(), "not enough balance for inst with");
    }

    function areSharesWithdrawable(uint256 _shares) internal view{
        uint256 freeBalanceForStdWith = _freePoolBalance()-poolState.totalPending;

        uint256 userReqBalance = _shares.mul(roundSupplyPricePerShare[currentRound()-1]).div(MathUtils.ray());

        require(freeBalanceForStdWith>userReqBalance,"not enough balance for std with");
    }

    function availableShares() public view returns (uint256) {
        uint256 freeBalanceForStdWith = _freePoolBalance()-poolState.totalPending;

        uint256 aShares = freeBalanceForStdWith.mul(MathUtils.ray()).div(roundSupplyPricePerShare[currentRound()-1]);

        return aShares;
    }

    /**
     * @notice The amount of asset a trader can borrow
     */
    function availableBorrowLimit() public override view returns (uint256) {
        return _freePoolBalance();
    }

    function _freePoolBalance() internal view returns (uint256){
        uint256 totalShares = totalSupply();

        // Get latest values for LPS/DPS
        (uint256 currentDPS, uint256 currentLPS) = pricePerShares(0);
        console.log("currentDPS", currentDPS, currentLPS);
        uint256 currentAvailableBorrowLimit = ((
            totalShares - 
            poolState.queuedWithdrawShares
            ).mul(currentLPS)).div(MathUtils.ray())
            -(uint256(poolState.totalDebtShares).mul(currentDPS)).div(MathUtils.ray())
            +poolState.totalPending
            -poolState.pendingBorrowAmount;

        console.log("currentAvailableBorrowLimit", currentAvailableBorrowLimit);
        return currentAvailableBorrowLimit;
    }

    function isVaultAdded(address _vault) internal view returns (bool) {
        uint256 vaultLength = verifiedVaults.length;
        for (uint256 i = 0; i < vaultLength; i++) {
            if (verifiedVaults[i] == _vault) return true;
        }

        return false;
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Pool.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                poolState.round,
                roundSupplyPricePerShare[depositReceipt.round],
                poolParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }


    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShares(uint16 round) public override view returns (uint256 dps, uint256 lps) {
        uint16 roundToGet;

        if (round==0) {
            roundToGet = poolState.round - 1;
        } else {
            roundToGet = round;
        }        

        uint256 prevRoundDPS = roundDebtPricePerShare[roundToGet];
        uint256 prevRoundLPS = roundSupplyPricePerShare[roundToGet];

        if (round == 1 || roundToGet == 0) return (MathUtils.ray(), MathUtils.ray());
        if (round !=0) return (prevRoundDPS, prevRoundLPS);

        uint256 currentDPS = prevRoundDPS.mul(MathUtils.calculateCompoundedInterest(
            currentBorrowRate,
            poolState.lastRateUpdateTime
            )).div(MathUtils.ray());
        
        uint256 currentLPS = prevRoundLPS.mul(MathUtils.calculateLinearInterest(
            currentBorrowRate,
            currentUtilizationRate,
            poolState.lastRateUpdateTime
            )).div(MathUtils.ray());

        return (currentDPS, currentLPS);
    }

    function currentRound() public override view returns (uint16) {
        return poolState.round;
    }

    // function utilizationRate() public view returns (uint256){
    //     return uint256(poolState.totalBorrowAmount)
    //                 .mul(decimals())
    //                 .div(totalBalance());
    // }

    /**
     * @notice Returns the pool's total balance, including the amounts locked into vaults
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        // After calling closeRound, current option is set to none
        // We also commit the lockedAmount but do not deposit into Opyn
        // which results in double counting of asset balance and lockedAmount
        //FIXME: When after closing the round of the pool, amount is locked but 
        // not transferred to vaults, so totalBalance should only return balance of pool
        return
            poolState.pendingBorrowAmount>0
                ? uint256(poolState.lockedAmount).add(
                    IERC20(poolParams.asset).balanceOf(address(this))
                )
                : IERC20(poolParams.asset).balanceOf(address(this));
    }

    function getVaults() public view returns(address[] memory){
        return verifiedVaults;
    }

    function getVaultBorrowed(address _vault) public view returns(uint256){
        return totalVaultBorrow[_vault];
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return poolParams.decimals;
    }

    function cap() external view returns (uint256) {
        return poolParams.cap;
    }

    function totalPending() external view returns (uint256) {
        return poolState.totalPending;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

library Pool{
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct PoolParams {        
        // Token decimals for pool shares
        uint8 decimals;
        // Asset used in the Pool
        address asset;        
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct PoolState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for borrowing
        uint104 lockedAmount;
        // Amount that was locked for borrowing in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint psPool tokens
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint128 queuedWithdrawShares;
        // Total amount to be borrowed by vaults in the next cycle
        uint128 pendingBorrowAmount;
        // Amounts locked by the vaults to borrow
        mapping(address=>uint128) lockedByVault;
        // Total amount currently borrowed by the vaults
        uint128 totalBorrowAmount;
        // The timestamp when the pool funds will be deployed
        uint32 nextPoolReadyAt;
        // Total Debt shares 
        uint128 totalDebtShares;
        // The timestamp when the interest was last calculated
        uint32 lastRateUpdateTime;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
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
library SafeMath {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity =0.8.4;

interface ISwap {
    struct Offer {
        // 32 byte slot 1, partial fill
        // Seller wallet address
        address seller;
        // 32 byte slot 2
        // Addess of oToken
        address oToken;
        // Price per oToken denominated in biddingToken
        uint96 minPrice;
        // 32 byte slot 3
        // ERC20 Token to bid for oToken
        address biddingToken;
        // Minimum oToken amount acceptable for a single bid
        uint96 minBidSize;
        // 32 byte slot 4
        // Total available oToken amount
        uint128 totalSize;
        // Remaining available oToken amount
        // This figure is updated after each successfull swap
        uint128 availableSize;
        // 32 byte slot 5
        // Amount of biddingToken received
        // This figure is updated after each successfull swap
        uint256 totalSales;
    }

    struct Bid {
        // ID assigned to offers
        uint256 swapId;
        // Number only used once for each wallet
        uint256 nonce;
        // Signer wallet address
        address signerWallet;
        // Amount of biddingToken offered by signer
        uint256 sellAmount;
        // Amount of oToken requested by signer
        uint256 buyAmount;
        // Referrer wallet address
        address referrer;
        // Signature recovery id
        uint8 v;
        // r portion of the ECSDA signature
        bytes32 r;
        // s portion of the ECSDA signature
        bytes32 s;
    }

    struct OfferDetails {
        // Seller wallet address
        address seller;
        // Addess of oToken
        address oToken;
        // Price per oToken denominated in biddingToken
        uint256 minPrice;
        // ERC20 Token to bid for oToken
        address biddingToken;
        // Minimum oToken amount acceptable for a single bid
        uint256 minBidSize;
    }

    event Swap(
        uint256 indexed swapId,
        uint256 nonce,
        address indexed signerWallet,
        uint256 signerAmount,
        uint256 sellerAmount,
        address referrer,
        uint256 feeAmount
    );

    event NewOffer(
        uint256 swapId,
        address seller,
        address oToken,
        address biddingToken,
        uint256 minPrice,
        uint256 minBidSize,
        uint256 totalSize
    );

    event SetFee(address referrer, uint256 fee);

    event SettleOffer(uint256 swapId);

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event Authorize(address indexed signer, address indexed signerWallet);

    event Revoke(address indexed signer, address indexed signerWallet);

    function createOffer(
        address oToken,
        address biddingToken,
        uint96 minPrice,
        uint96 minBidSize,
        uint128 totalSize
    ) external returns (uint256 swapId);

    function settleOffer(uint256 swapId, Bid[] calldata bids) external;

    function cancelNonce(uint256[] calldata nonces) external;

    function check(Bid calldata bid)
        external
        view
        returns (uint256, bytes32[] memory);

    function averagePriceForOffer(uint256 swapId)
        external
        view
        returns (uint256);

    function authorize(address sender) external;

    function revoke() external;

    function nonceUsed(address, uint256) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

abstract contract PolysynthThetaVaultStorageV1 {
    // Logic contract used to price options
    address public optionsPremiumPricer;
    // Logic contract used to select strike prices
    address public strikeSelection;
    // Premium discount on options we are selling (thousandths place: 000 - 999)
    uint256 public premiumDiscount;
    // Current oToken premium
    uint256 public currentOtokenPremium;
    // Last round id at which the strike was manually overridden
    uint16 public lastStrikeOverrideRound;
    // Price last overridden strike set to
    uint256 public overriddenStrikePrice;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionID;
}

abstract contract PolysynthThetaVaultStorageV2 {
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;
}

abstract contract PolysynthThetaVaultStorageV3 {
    // DEPRECATED: Auction will be denominated in USDC if true
    bool private _isUsdcAuction;
    // DEPRECATED: Path for swaps
    bytes private _swapPath;
}

abstract contract PolysynthThetaVaultStorageV4 {
    // LiquidityGauge contract for the vault
    address public liquidityGauge;
}

abstract contract PolysynthThetaVaultStorageV5 {
    // OptionsPurchaseQueue contract for selling options
    address public optionsPurchaseQueue;
}

abstract contract PolysynthThetaVaultStorageV6 {
    // Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of PolysynthThetaVaultStorage
// e.g. PolysynthThetaVaultStorage<versionNumber>, so finally it would look like
// contract PolysynthThetaVaultStorage is PolysynthThetaVaultStorageV1, PolysynthThetaVaultStorageV2
abstract contract PolysynthThetaVaultStorage is
    PolysynthThetaVaultStorageV1,
    PolysynthThetaVaultStorageV2,
    PolysynthThetaVaultStorageV3,
    PolysynthThetaVaultStorageV4,
    PolysynthThetaVaultStorageV5,
    PolysynthThetaVaultStorageV6
{

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library Vault {
    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    // Fees are 6-decimal places. For example: 20 * 10**6 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10**6;

    // Premium discount has 1-decimal place. For example: 80 * 10**1 = 80%. Which represents a 20% discount.
    uint256 internal constant PREMIUM_DISCOUNT_MULTIPLIER = 10;

    // Otokens have 8 decimal places.
    uint256 internal constant OTOKEN_DECIMALS = 8;

    // Percentage of funds allocated to options is 2 decimal places. 10 * 10**2 = 10%
    uint256 internal constant OPTION_ALLOCATION_MULTIPLIER = 10**2;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    struct VaultParams {
        // Option type the vault is selling
        bool isPut;
        // Token decimals for vault shares
        uint8 decimals;
        // Asset used in Theta / Delta Vault
        address asset;
        // Underlying asset of the options sold by vault
        address underlying;
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        address nextOption;
        // Option that the vault is currently shorting / longing
        address currentOption;
        // The timestamp when the `nextOption` can be used by the vault
        uint32 nextOptionReadyAt;
    }

    struct VaultState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint128 totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint128 queuedWithdrawShares;
    }

    struct DepositReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct Withdrawal {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares withdrawn
        uint128 shares;
    }

    struct AuctionSellOrder {
        // Amount of `asset` token offered in auction
        uint96 sellAmount;
        // Amount of oToken requested in auction
        uint96 buyAmount;
        // User Id of delta vault in latest gnosis auction
        uint64 userId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {IStrikeSelection} from "../interfaces/IRibbon.sol";
import {GnosisAuction} from "./GnosisAuction.sol";
import {
    IOtokenFactory,
    IOtoken,
    IController,
    GammaTypes
} from "../interfaces/GammaInterface.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {ISwap} from "../interfaces/ISwap.sol";
import {IOptionsPurchaseQueue} from "../interfaces/IOptionsPurchaseQueue.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";

library VaultLifecycleWithSwap {
    using SafeMath for uint256;
    using SupportsNonCompliantERC20 for IERC20;
    using SafeERC20 for IERC20;

    struct CommitParams {
        address OTOKEN_FACTORY;
        address USDC;
        address currentOption;
        uint256 delay;
        uint16 lastStrikeOverrideRound;
        uint256 overriddenStrikePrice;
        address strikeSelection;
        address optionsPremiumPricer;
        uint256 premiumDiscount;
    }

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param commitParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return otokenAddress is the address of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */
    function commitNextOption(
        CommitParams calldata commitParams,
        Vault.VaultParams storage vaultParams,
        Vault.VaultState storage vaultState
    )
        external
        returns (
            address otokenAddress,
            uint256 strikePrice,
            uint256 delta
        )
    {
        uint256 expiry = getNextExpiry(commitParams.currentOption);

        IStrikeSelection selection =
            IStrikeSelection(commitParams.strikeSelection);

        bool isPut = vaultParams.isPut;
        address underlying = vaultParams.underlying;
        address asset = vaultParams.asset;

        (strikePrice, delta) = commitParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (commitParams.overriddenStrikePrice, selection.delta())
            : selection.getStrikePrice(expiry, isPut);

        require(strikePrice != 0, "!strikePrice");

        // retrieve address if option already exists, or deploy it
        otokenAddress = getOrDeployOtoken(
            commitParams,
            vaultParams,
            underlying,
            asset,
            strikePrice,
            expiry,
            isPut
        );

        return (otokenAddress, strikePrice, delta);
    }

    /**
     * @notice Verify the otoken has the correct parameters to prevent vulnerability to opyn contract changes
     * @param otokenAddress is the address of the otoken
     * @param vaultParams is the struct with vault general data
     * @param collateralAsset is the address of the collateral asset
     * @param USDC is the address of usdc
     * @param delay is the delay between commitAndClose and rollToNextOption
     */
    function verifyOtoken(
        address otokenAddress,
        Vault.VaultParams storage vaultParams,
        address collateralAsset,
        address USDC,
        uint256 delay
    ) private view {
        require(otokenAddress != address(0), "!otokenAddress");

        IOtoken otoken = IOtoken(otokenAddress);
        require(otoken.isPut() == vaultParams.isPut, "Type mismatch");
        require(
            otoken.underlyingAsset() == vaultParams.underlying,
            "Wrong underlyingAsset"
        );
        require(
            otoken.collateralAsset() == collateralAsset,
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        require(otoken.strikeAsset() == USDC, "strikeAsset != USDC");

        uint256 readyAt = block.timestamp.add(delay);
        require(otoken.expiryTimestamp() >= readyAt, "Expiry before delay");
    }

    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the vault's total asset balance
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from last round
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     */
    struct CloseParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 currentQueuedWithdrawShares;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from RibbonVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function closeRound(
        Vault.VaultState storage vaultState,
        CloseParams calldata params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees =
            currentBalance.sub(params.lastQueuedWithdrawAmount);

        {
            (performanceFeeInAsset, , totalVaultFee) = getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                params.managementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance.sub(totalVaultFee);

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply.sub(lastQueuedWithdrawShares),
                currentBalance.sub(params.lastQueuedWithdrawAmount),
                pendingAmount,
                params.decimals
            );

            queuedWithdrawAmount = params.lastQueuedWithdrawAmount.add(
                ShareMath.sharesToAsset(
                    params.currentQueuedWithdrawShares,
                    newPricePerShare,
                    params.decimals
                )
            );

            // After closing the short, if the options expire in-the-money
            // vault pricePerShare would go down because vault's asset balance decreased.
            // This ensures that the newly-minted shares do not take on the loss.
            mintShares = ShareMath.assetToShares(
                pendingAmount,
                newPricePerShare,
                params.decimals
            );
        }

        return (
            currentBalance.sub(queuedWithdrawAmount), // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            mintShares,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
     * @param gammaController is the address of the opyn controller contract
     * @param marginPool is the address of the opyn margin contract which holds the collateral
     * @param oTokenAddress is the address of the otoken to mint
     * @param depositAmount is the amount of collateral to deposit
     * @return the otoken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address oTokenAddress,
        uint256 depositAmount
    ) external returns (uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID =
            (controller.getAccountVaultCounter(address(this))).add(1);

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IOtoken oToken = IOtoken(oTokenAddress);
        address collateralAsset = oToken.collateralAsset();

        uint256 collateralDecimals =
            uint256(IERC20Detailed(collateralAsset).decimals());
        uint256 mintAmount;

        if (oToken.isPut()) {
            // For minting puts, there will be instances where the full depositAmount will not be used for minting.
            // This is because of an issue with precision.
            //
            // For ETH put options, we are calculating the mintAmount (10**8 decimals) using
            // the depositAmount (10**18 decimals), which will result in truncation of decimals when scaling down.
            // As a result, there will be tiny amounts of dust left behind in the Opyn vault when minting put otokens.
            //
            // For simplicity's sake, we do not refund the dust back to the address(this) on minting otokens.
            // We retain the dust in the vault so the calling contract can withdraw the
            // actual locked amount + dust at settlement.
            //
            // To test this behavior, we can console.log
            // MarginCalculatorInterface(0x7A48d10f372b3D7c60f6c9770B91398e4ccfd3C7).getExcessCollateral(vault)
            // to see how much dust (or excess collateral) is left behind.
            mintAmount = depositAmount
                .mul(10**Vault.OTOKEN_DECIMALS)
                .mul(10**18) // we use 10**18 to give extra precision
                .div(oToken.strikePrice().mul(10**(10 + collateralDecimals)));
        } else {
            mintAmount = depositAmount;

            if (collateralDecimals > 8) {
                uint256 scaleBy = 10**(collateralDecimals.sub(8)); // oTokens have 8 decimals
                if (mintAmount > scaleBy) {
                    mintAmount = depositAmount.div(scaleBy); // scale down from 10**18 to 10**8
                }
            }
        }

        // double approve to fix non-compliant ERC20s
        IERC20 collateralToken = IERC20(collateralAsset);
        collateralToken.safeApproveNonCompliant(marginPool, depositAmount);

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](3);

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oTokenAddress, // option address
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        return mintAmount;
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the opyn controller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(address gammaController) external returns (uint256) {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        // The short position has been previously closed, or all the otokens have been burned.
        // So we return early.
        if (address(collateralToken) == address(0)) {
            return 0;
        }

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultID, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Exercises the ITM option using existing long otoken position. Currently this implementation is simple.
     * It calls the `Redeem` action to claim the payout.
     * @param gammaController is the address of the opyn controller contract
     * @param oldOption is the address of the old option
     * @param asset is the address of the vault's asset
     * @return amount of asset received by exercising the option
     */
    function settleLong(
        address gammaController,
        address oldOption,
        address asset
    ) external returns (uint256) {
        IController controller = IController(gammaController);

        uint256 oldOptionBalance = IERC20(oldOption).balanceOf(address(this));

        if (controller.getPayout(oldOption, oldOptionBalance) == 0) {
            return 0;
        }

        uint256 startAssetBalance = IERC20(asset).balanceOf(address(this));

        // If it is after expiry, we need to redeem the profits
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oldOption, // address of otoken
            0, // not used
            oldOptionBalance, // otoken balance
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endAssetBalance = IERC20(asset).balanceOf(address(this));

        return endAssetBalance.sub(startAssetBalance);
    }

    /**
     * @notice Burn the remaining oTokens left over from auction. Currently this implementation is simple.
     * It burns oTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the opyn controller contract
     * @param currentOption is the address of the current option
     * @return amount of collateral redeemed by burning otokens
     */
    function burnOtokens(address gammaController, address currentOption)
        external
        returns (uint256)
    {
        uint256 numOTokensToBurn =
            IERC20(currentOption).balanceOf(address(this));

        require(numOTokensToBurn > 0, "No oTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // Burning `amount` of oTokens from the ribbon vault,
        // then withdrawing the corresponding collateral amount from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](2);

        actions[0] = IController.ActionArgs(
            IController.ActionType.BurnShortOption,
            address(this), // owner
            address(this), // address to transfer from
            address(vault.shortOtokens[0]), // otoken address
            vaultID, // vaultId
            numOTokensToBurn, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            address(collateralToken), // withdrawn asset
            vaultID, // vaultId
            vault.collateralAmounts[0].mul(numOTokensToBurn).div(
                vault.shortAmounts[0]
            ), // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount
                ? currentBalance.sub(pendingAmount)
                : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? lockedBalanceSansPending
                    .sub(lastLockedAmount)
                    .mul(performanceFeePercent)
                    .div(100 * Vault.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? lockedBalanceSansPending.mul(managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            _vaultFee = _performanceFeeInAsset.add(_managementFeeInAsset);
        } else {
            _managementFeeInAsset = managementFeePercent > 0
                ? lastLockedAmount.mul(managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            _vaultFee = _managementFeeInAsset;
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param commitParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param underlying is the address of the underlying asset of the option
     * @param collateralAsset is the address of the collateral asset of the option
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @param isPut is whether the option is a put
     * @return the address of the option
     */
    function getOrDeployOtoken(
        CommitParams calldata commitParams,
        Vault.VaultParams storage vaultParams,
        address underlying,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) internal returns (address) {
        IOtokenFactory factory = IOtokenFactory(commitParams.OTOKEN_FACTORY);

        address otokenFromFactory =
            factory.getOtoken(
                underlying,
                commitParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        if (otokenFromFactory != address(0)) {
            return otokenFromFactory;
        }

        address otoken =
            factory.createOtoken(
                underlying,
                commitParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        verifyOtoken(
            otoken,
            vaultParams,
            collateralAsset,
            commitParams.USDC,
            commitParams.delay
        );

        return otoken;
    }

    function getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) external view returns (uint256) {
        return
            _getOTokenPremium(
                oTokenAddress,
                optionsPremiumPricer,
                premiumDiscount
            );
    }

    function _getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer =
            IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium =
            premiumPricer.getPremium(
                newOToken.strikePrice(),
                newOToken.expiryTimestamp(),
                newOToken.isPut()
            );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(
            100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER
        );

        require(
            optionPremium <= type(uint96).max,
            "optionPremium > type(uint96) max value!"
        );
        require(optionPremium > 0, "!optionPremium");

        return optionPremium;
    }

    /**
     * @notice Creates an offer in the Swap Contract
     * @param currentOtoken is the current otoken address
     * @param currOtokenPremium is premium for each otoken
     * @param swapContract the address of the swap contract
     * @param vaultParams is the struct with vault general data
     * @return optionAuctionID auction id of the newly created offer
     */
    function createOffer(
        address currentOtoken,
        uint256 currOtokenPremium,
        address swapContract,
        Vault.VaultParams storage vaultParams
    ) external returns (uint256 optionAuctionID) {
        require(
            currOtokenPremium <= type(uint96).max,
            "currentOtokenPremium > type(uint96) max value!"
        );
        require(currOtokenPremium > 0, "!currentOtokenPremium");

        uint256 oTokenBalance = IERC20(currentOtoken).balanceOf(address(this));
        require(
            oTokenBalance <= type(uint128).max,
            "oTokenBalance > type(uint128) max value!"
        );

        // Use safeIncrease instead of safeApproval because safeApproval is only used for initial
        // approval and cannot be called again. Using safeIncrease allow us to call _createOffer
        // even when we are approving the same oTokens we have used before. This might happen if
        // we accidentally burn the oTokens before settlement.
        uint256 allowance =
            IERC20(currentOtoken).allowance(address(this), swapContract);

        if (allowance < oTokenBalance) {
            IERC20(currentOtoken).safeIncreaseAllowance(
                swapContract,
                oTokenBalance.sub(allowance)
            );
        }

        uint256 decimals = vaultParams.decimals;

        // If total size is larger than 1, set minimum bid as 1
        // Otherwise, set minimum bid to one tenth the total size
        uint256 minBidSize =
            oTokenBalance > 10**decimals ? 10**decimals : oTokenBalance.div(10);

        require(
            minBidSize <= type(uint96).max,
            "minBidSize > type(uint96) max value!"
        );

        currOtokenPremium = decimals > 18
            ? currOtokenPremium.mul(10**(decimals.sub(18)))
            : currOtokenPremium.div(10**(uint256(18).sub(decimals)));

        optionAuctionID = ISwap(swapContract).createOffer(
            currentOtoken,
            vaultParams.asset,
            uint96(currOtokenPremium),
            uint96(minBidSize),
            uint128(oTokenBalance)
        );
    }

    /**
     * @notice Allocates the vault's minted options to the OptionsPurchaseQueue contract
     * @dev Skipped if the optionsPurchaseQueue doesn't exist
     * @param optionsPurchaseQueue is the OptionsPurchaseQueue contract
     * @param option is the minted option
     * @param optionsAmount is the amount of options minted
     * @param optionAllocation is the maximum % of options to allocate towards the purchase queue (will only allocate
     *  up to the amount that is on the queue)
     * @return allocatedOptions is the amount of options that ended up getting allocated to the OptionsPurchaseQueue
     */
    function allocateOptions(
        address optionsPurchaseQueue,
        address option,
        uint256 optionsAmount,
        uint256 optionAllocation
    ) external returns (uint256 allocatedOptions) {
        // Skip if optionsPurchaseQueue is address(0)
        if (optionsPurchaseQueue != address(0)) {
            allocatedOptions = optionsAmount.mul(optionAllocation).div(
                100 * Vault.OPTION_ALLOCATION_MULTIPLIER
            );
            allocatedOptions = IOptionsPurchaseQueue(optionsPurchaseQueue)
                .getOptionsAllocation(address(this), allocatedOptions);

            if (allocatedOptions != 0) {
                IERC20(option).approve(optionsPurchaseQueue, allocatedOptions);
                IOptionsPurchaseQueue(optionsPurchaseQueue).allocateOptions(
                    allocatedOptions
                );
            }
        }

        return allocatedOptions;
    }

    /**
     * @notice Sell the allocated options to the purchase queue post auction settlement
     * @dev Reverts if the auction hasn't settled yet
     * @param optionsPurchaseQueue is the OptionsPurchaseQueue contract
     * @param swapContract The address of the swap settlement contract
     * @return totalPremiums Total premiums earnt by the vault
     */
    function sellOptionsToQueue(
        address optionsPurchaseQueue,
        address swapContract,
        uint256 optionAuctionID
    ) external returns (uint256) {
        uint256 settlementPrice =
            getAuctionSettlementPrice(swapContract, optionAuctionID);
        require(settlementPrice != 0, "!settlementPrice");

        return
            IOptionsPurchaseQueue(optionsPurchaseQueue).sellToBuyers(
                settlementPrice
            );
    }

    /**
     * @notice Gets the settlement price of a settled auction
     * @param swapContract The address of the swap settlement contract
     * @param optionAuctionID is the offer ID
     * @return settlementPrice Auction settlement price
     */
    function getAuctionSettlementPrice(
        address swapContract,
        uint256 optionAuctionID
    ) public view returns (uint256) {
        return ISwap(swapContract).averagePriceForOffer(optionAuctionID);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        address feeRecipient,
        uint256 performanceFee,
        uint256 managementFee,
        string calldata tokenName,
        string calldata tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) external pure {
        require(owner != address(0), "!owner");
        require(keeper != address(0), "!keeper");
        require(feeRecipient != address(0), "!feeRecipient");
        require(
            performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "performanceFee >= 100%"
        );
        require(
            managementFee < 100 * Vault.FEE_MULTIPLIER,
            "managementFee >= 100%"
        );
        require(bytes(tokenName).length > 0, "!tokenName");
        require(bytes(tokenSymbol).length > 0, "!tokenSymbol");

        require(_vaultParams.asset != address(0), "!asset");
        require(_vaultParams.underlying != address(0), "!underlying");
        require(_vaultParams.minimumSupply > 0, "!minimumSupply");
        require(_vaultParams.cap > 0, "!cap");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param currentOption is the otoken address that the vault is currently writing
     */
    function getNextExpiry(address currentOption)
        internal
        view
        returns (uint256)
    {
        // uninitialized state
        if (currentOption == address(0)) {
            return getNextFriday(block.timestamp);
        }
        uint256 currentExpiry = IOtoken(currentOption).expiryTimestamp();

        // After options expiry if no options are written for >1 week
        // We need to give the ability continue writing options
        if (block.timestamp > currentExpiry + 7 days) {
            return getNextFriday(block.timestamp);
        }
        return getNextFriday(currentExpiry);
    }

    /**
     * @notice Gets the next options expiry timestamp
     * @param timestamp is the expiry timestamp of the current option
     * Reference: https://codereview.stackexchange.com/a/33532
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Vault} from "./Vault.sol";

library ShareMath {
    using SafeMath for uint256;

    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return assetAmount.mul(10**decimals).div(assetPerShare);
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return shares.mul(assetPerShare).div(10**decimals);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Vault.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound =
                assetToShares(depositReceipt.amount, assetPerShare, decimals);

            return
                uint256(depositReceipt.unredeemedShares).add(sharesFromRound);
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return
            totalSupply > 0
                ? singleShare.mul(totalBalance.sub(pendingAmount)).div(
                    totalSupply
                )
                : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ILiquidityGauge {
    function balanceOf(address) external view returns (uint256);

    function deposit(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Vault} from "../../../libraries/Vault.sol";
import {
    VaultLifecycleWithSwap
} from "../../../libraries/VaultLifecycleWithSwap.sol";
import {ShareMath} from "../../../libraries/ShareMath.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";

contract PolysynthVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public depositFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public withdrawalFee;

    // Gap is left to avoid storage collisions. Though PolysynthVault is not upgradeable, we add this as a safety measure.
    uint256[30] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to PolysynthThetaVaultStorage
    // or PolysynthDeltaVaultStorage instead. Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public immutable USDC;

    /// @notice Deprecated: 15 minute timelock between commitAndClose and rollToNexOption.
    uint256 public constant DELAY = 0;

    /// @notice 7 day period between each options sale.
    uint256 public constant PERIOD = 7 days;

    // Number of weeks per year = 52.142857 weeks * FEE_MULTIPLIER = 52142857
    // Dividing by weeks per year requires doing num.mul(FEE_MULTIPLIER).div(WEEKS_PER_YEAR)
    uint256 private constant WEEKS_PER_YEAR = 52142857;

    // GAMMA_CONTROLLER is the top-level contract in Gamma protocol
    // which allows users to perform multiple actions on their vaults
    // and positions https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/Controller.sol
    address public immutable GAMMA_CONTROLLER;

    // MARGIN_POOL is Gamma protocol's collateral pool.
    // Needed to approve collateral.safeTransferFrom for minting otokens.
    // https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/MarginPool.sol
    address public immutable MARGIN_POOL;

    // SWAP_CONTRACT is a contract for settling bids via signed messages
    // https://github.com/Polysynth-finance/Polysynth-v2/blob/master/contracts/utils/Swap.sol
    address public immutable SWAP_CONTRACT;

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event DepositFeeSet(uint256 depositFee, uint256 newDepositFee);

    event WithdrawalFeeSet(uint256 withdrawalFee, uint256 newwithdrawalFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _swapContract is the contract address that facilitates bids settlement
     */
    constructor(
        address _weth,
        address _usdc,
        address _gammaController,
        address _marginPool,
        address _swapContract
    ) {
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_swapContract != address(0), "!_swapContract");
        require(_gammaController != address(0), "!_gammaController");
        require(_marginPool != address(0), "!_marginPool");

        WETH = _weth;
        USDC = _usdc;
        GAMMA_CONTROLLER = _gammaController;
        MARGIN_POOL = _marginPool;
        SWAP_CONTRACT = _swapContract;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     */
    function baseInitialize(
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        VaultLifecycleWithSwap.verifyInitializerParams(
            _owner,
            _keeper,
            _feeRecipient,
            _performanceFee,
            _managementFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        keeper = _keeper;

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee.mul(Vault.FEE_MULTIPLIER).div(
            WEEKS_PER_YEAR
        );
        vaultParams = _vaultParams;

        uint256 assetBalance =
            IERC20(vaultParams.asset).balanceOf(address(this));
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "!newKeeper");
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        require(newFeeRecipient != feeRecipient, "Must be new feeRecipient");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(
            newManagementFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid management fee"
        );

        // We are dividing annualized management fee by num weeks in a year
        uint256 tmpManagementFee =
            newManagementFee.mul(Vault.FEE_MULTIPLIER).div(WEEKS_PER_YEAR);

        emit ManagementFeeSet(managementFee, newManagementFee);

        managementFee = tmpManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(
            newPerformanceFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid performance fee"
        );

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /**
     * @notice Sets the deposit fee for the vault
     * @param newDepositFee is the deposit fee (6 decimals). ex: 0.1 * 10 ** 6 = 0.1%
     */
    function setDepositFee(uint256 newDepositFee) external onlyOwner {
        require(
            newDepositFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid deposit fee"
        );

        emit DepositFeeSet(depositFee, newDepositFee);

        depositFee = newDepositFee;
    }

    /**
     * @notice Sets the withdrawal fee for the vault
     * @param newWithdrawalFee is the withdrawal fee (6 decimals). ex: 0.1 * 10 ** 6 = 0.1%
     */
    function setWithdrawalFee(uint256 newWithdrawalFee) external onlyOwner {
        require(
            newWithdrawalFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid withdrawal fee"
        );

        emit DepositFeeSet(withdrawalFee, newWithdrawalFee);

        withdrawalFee = newWithdrawalFee;
    }


    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the asset is not WETH.
     */
    function depositETH() external payable nonReentrant {
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);

        if (depositFee>0){
            uint256 fee = amount.mul(depositFee).div(100 * Vault.FEE_MULTIPLIER);
            amount += fee;
        }

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "!amount");
        require(creditor != address(0));

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance().add(amount);

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(amount);
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMath.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        require(withdrawAmount > 0, "!withdrawAmount");

        if(withdrawalFee>0){
            uint256 fee = withdrawAmount.mul(withdrawalFee).div(100 * Vault.FEE_MULTIPLIER);
            withdrawAmount -= fee;
        }

        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Vault.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(numShares)
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Helper function that helps to save gas for writing values into the roundPricePerShare map.
     *         Writing `1` into the map makes subsequent writes warm, reducing the gas from 20k to 5k.
     *         Having 1 initialized beforehand will not be an issue as long as we round down share calculations to 0.
     * @param numRounds is the number of rounds to initialize in the map
     */
    function initRounds(uint256 numRounds) external nonReentrant {
        require(numRounds > 0, "!numRounds");

        uint256 _round = vaultState.round;
        for (uint256 i = 0; i < numRounds; i++) {
            uint256 index = _round + i;
            require(roundPricePerShare[index] == 0, "Initialized"); // AVOID OVERWRITING ACTUAL VALUES
            roundPricePerShare[index] = ShareMath.PLACEHOLDER_UINT;
        }
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as minting new shares, getting vault fees, etc.
     * @param lastQueuedWithdrawAmount is old queued withdraw amount
     * @param currentQueuedWithdrawShares is the queued withdraw shares for the current round
     * @return lockedBalance is the new balance used to calculate next option purchase size or collateral size
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _closeRound(
        uint256 lastQueuedWithdrawAmount,
        uint256 currentQueuedWithdrawShares
    ) internal returns (uint256 lockedBalance, uint256 queuedWithdrawAmount) {
        address recipient = feeRecipient;
        uint256 mintShares;
        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;
        {
            uint256 newPricePerShare;
            (
                lockedBalance,
                queuedWithdrawAmount,
                newPricePerShare,
                mintShares,
                performanceFeeInAsset,
                totalVaultFee
            ) = VaultLifecycleWithSwap.closeRound(
                vaultState,
                VaultLifecycleWithSwap.CloseParams(
                    vaultParams.decimals,
                    IERC20(vaultParams.asset).balanceOf(address(this)),
                    totalSupply(),
                    lastQueuedWithdrawAmount,
                    performanceFee,
                    managementFee,
                    currentQueuedWithdrawShares
                )
            );

            // Finalize the pricePerShare at the end of the round
            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            emit CollectVaultFees(
                performanceFeeInAsset,
                totalVaultFee,
                currentRound,
                recipient
            );

            vaultState.totalPending = 0;
            vaultState.round = uint16(currentRound + 1);
        }

        _mint(address(this), mintShares);

        if (totalVaultFee > 0) {
            transferAsset(payable(recipient), totalVaultFee);
        }

        return (lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        if (asset == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                _decimals
            );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        // After calling closeRound, current option is set to none
        // We also commit the lockedAmount but do not deposit into Opyn
        // which results in double counting of asset balance and lockedAmount

        return
            optionState.currentOption != address(0)
                ? uint256(vaultState.lockedAmount).add(
                    IERC20(vaultParams.asset).balanceOf(address(this))
                )
                : IERC20(vaultParams.asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function nextOptionReadyAt() external view returns (uint256) {
        return optionState.nextOptionReadyAt;
    }

    function currentOption() external view returns (address) {
        return optionState.currentOption;
    }

    function nextOption() external view returns (address) {
        return optionState.nextOption;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity =0.8.4;
import {Vault} from "../libraries/Vault.sol";

interface IRibbonVault {
    function deposit(uint256 amount) external;

    function depositETH() external payable;

    function cap() external view returns (uint256);

    function depositFor(uint256 amount, address creditor) external;

    function vaultParams() external view returns (Vault.VaultParams memory);
}

interface IStrikeSelection {
    function getStrikePrice(uint256 expiryTimestamp, bool isPut)
        external
        view
        returns (uint256, uint256);

    function delta() external view returns (uint256);
}

interface IOptionsPremiumPricer {
    function getPremium(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getPremiumInStables(
        uint256 strikePrice,
        uint256 timeToExpiry,
        bool isPut
    ) external view returns (uint256);

    function getOptionDelta(
        uint256 spotPrice,
        uint256 strikePrice,
        uint256 volatility,
        uint256 expiryTimestamp
    ) external view returns (uint256 delta);

    function getUnderlyingPrice() external view returns (uint256);

    function priceOracle() external view returns (address);

    function volatilityOracle() external view returns (address);

    function optionId() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DSMath} from "../vendor/DSMath.sol";
import {IGnosisAuction} from "../interfaces/IGnosisAuction.sol";
import {IOtoken} from "../interfaces/GammaInterface.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";
import {Vault} from "./Vault.sol";
import {IRibbonThetaVault} from "../interfaces/IRibbonThetaVault.sol";

library GnosisAuction {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    event PlaceAuctionBid(
        uint256 auctionId,
        address indexed auctioningToken,
        uint256 sellAmount,
        uint256 buyAmount,
        address indexed bidder
    );

    struct AuctionDetails {
        address oTokenAddress;
        address gnosisEasyAuction;
        address asset;
        uint256 assetDecimals;
        uint256 oTokenPremium;
        uint256 duration;
    }

    struct BidDetails {
        address oTokenAddress;
        address gnosisEasyAuction;
        address asset;
        uint256 assetDecimals;
        uint256 auctionId;
        uint256 lockedBalance;
        uint256 optionAllocation;
        uint256 optionPremium;
        address bidder;
    }

    function startAuction(AuctionDetails calldata auctionDetails)
        internal
        returns (uint256 auctionID)
    {
        uint256 oTokenSellAmount =
            getOTokenSellAmount(auctionDetails.oTokenAddress);
        require(oTokenSellAmount > 0, "No otokens to sell");

        IERC20(auctionDetails.oTokenAddress).safeApprove(
            auctionDetails.gnosisEasyAuction,
            IERC20(auctionDetails.oTokenAddress).balanceOf(address(this))
        );

        // minBidAmount is total oTokens to sell * premium per oToken
        // shift decimals to correspond to decimals of USDC for puts
        // and underlying for calls
        uint256 minBidAmount =
            DSMath.wmul(
                oTokenSellAmount.mul(10**10),
                auctionDetails.oTokenPremium
            );

        minBidAmount = auctionDetails.assetDecimals > 18
            ? minBidAmount.mul(10**(auctionDetails.assetDecimals.sub(18)))
            : minBidAmount.div(
                10**(uint256(18).sub(auctionDetails.assetDecimals))
            );

        require(
            minBidAmount <= type(uint96).max,
            "optionPremium * oTokenSellAmount > type(uint96) max value!"
        );

        uint256 auctionEnd = block.timestamp.add(auctionDetails.duration);

        auctionID = IGnosisAuction(auctionDetails.gnosisEasyAuction)
            .initiateAuction(
            // address of oToken we minted and are selling
            auctionDetails.oTokenAddress,
            // address of asset we want in exchange for oTokens. Should match vault `asset`
            auctionDetails.asset,
            // orders can be cancelled at any time during the auction
            auctionEnd,
            // order will last for `duration`
            auctionEnd,
            // we are selling all of the otokens minus a fee taken by gnosis
            uint96(oTokenSellAmount),
            // the minimum we are willing to sell all the oTokens for. A discount is applied on black-scholes price
            uint96(minBidAmount),
            // the minimum bidding amount must be 1 * 10 ** -assetDecimals
            1,
            // the min funding threshold
            0,
            // no atomic closure
            false,
            // access manager contract
            address(0),
            // bytes for storing info like a whitelist for who can bid
            bytes("")
        );

        emit InitiateGnosisAuction(
            auctionDetails.oTokenAddress,
            auctionDetails.asset,
            auctionID,
            msg.sender
        );
    }

    function placeBid(BidDetails calldata bidDetails)
        internal
        returns (
            uint256 sellAmount,
            uint256 buyAmount,
            uint64 userId
        )
    {
        // calculate how much to allocate
        sellAmount = bidDetails
            .lockedBalance
            .mul(bidDetails.optionAllocation)
            .div(100 * Vault.OPTION_ALLOCATION_MULTIPLIER);

        // divide the `asset` sellAmount by the target premium per oToken to
        // get the number of oTokens to buy (8 decimals)
        buyAmount = sellAmount
            .mul(10**(bidDetails.assetDecimals.add(Vault.OTOKEN_DECIMALS)))
            .div(bidDetails.optionPremium)
            .div(10**bidDetails.assetDecimals);

        require(
            sellAmount <= type(uint96).max,
            "sellAmount > type(uint96) max value!"
        );
        require(
            buyAmount <= type(uint96).max,
            "buyAmount > type(uint96) max value!"
        );

        // approve that amount
        IERC20(bidDetails.asset).safeApprove(
            bidDetails.gnosisEasyAuction,
            sellAmount
        );

        uint96[] memory _minBuyAmounts = new uint96[](1);
        uint96[] memory _sellAmounts = new uint96[](1);
        bytes32[] memory _prevSellOrders = new bytes32[](1);
        _minBuyAmounts[0] = uint96(buyAmount);
        _sellAmounts[0] = uint96(sellAmount);
        _prevSellOrders[
            0
        ] = 0x0000000000000000000000000000000000000000000000000000000000000001;

        // place sell order with that amount
        userId = IGnosisAuction(bidDetails.gnosisEasyAuction).placeSellOrders(
            bidDetails.auctionId,
            _minBuyAmounts,
            _sellAmounts,
            _prevSellOrders,
            "0x"
        );

        emit PlaceAuctionBid(
            bidDetails.auctionId,
            bidDetails.oTokenAddress,
            sellAmount,
            buyAmount,
            bidDetails.bidder
        );

        return (sellAmount, buyAmount, userId);
    }

    function claimAuctionOtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) internal {
        bytes32 order =
            encodeOrder(
                auctionSellOrder.userId,
                auctionSellOrder.buyAmount,
                auctionSellOrder.sellAmount
            );
        bytes32[] memory orders = new bytes32[](1);
        orders[0] = order;
        IGnosisAuction(gnosisEasyAuction).claimFromParticipantOrder(
            IRibbonThetaVault(counterpartyThetaVault).optionAuctionID(),
            orders
        );
    }

    function getOTokenSellAmount(address oTokenAddress)
        internal
        view
        returns (uint256)
    {
        // We take our current oToken balance. That will be our sell amount
        // but otokens will be transferred to gnosis.
        uint256 oTokenSellAmount =
            IERC20(oTokenAddress).balanceOf(address(this));

        require(
            oTokenSellAmount <= type(uint96).max,
            "oTokenSellAmount > type(uint96) max value!"
        );

        return oTokenSellAmount;
    }

    function getOTokenPremiumInStables(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer =
            IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated USDC for both call and put options
        uint256 optionPremium =
            premiumPricer.getPremiumInStables(
                newOToken.strikePrice(),
                newOToken.expiryTimestamp(),
                newOToken.isPut()
            );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(
            100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER
        );

        require(
            optionPremium <= type(uint96).max,
            "optionPremium > type(uint96) max value!"
        );

        return optionPremium;
    }

    function encodeOrder(
        uint64 userId,
        uint96 buyAmount,
        uint96 sellAmount
    ) internal pure returns (bytes32) {
        return
            bytes32(
                (uint256(userId) << 192) +
                    (uint256(buyAmount) << 96) +
                    uint256(sellAmount)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Detailed is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string calldata);

    function name() external view returns (string calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOptionsPurchaseQueue {
    /**
     * @dev Contains purchase request info
     * @param optionsAmount Amount of options to purchase
     * @param premiums Total premiums the buyer is spending to purchase the options (optionsAmount * ceilingPrice)
     *  We need to track the premiums here since the ceilingPrice could change between the time the purchase was
     *  requested and when the options are sold
     * @param buyer The buyer requesting this purchase
     */
    struct Purchase {
        uint128 optionsAmount; // Slot 0
        uint128 premiums;
        address buyer; // Slot 1
    }

    function purchases(address, uint256)
        external
        view
        returns (
            uint128,
            uint128,
            address
        );

    function totalOptionsAmount(address) external view returns (uint256);

    function vaultAllocatedOptions(address) external view returns (uint256);

    function whitelistedBuyer(address) external view returns (bool);

    function minPurchaseAmount(address) external view returns (uint256);

    function ceilingPrice(address) external view returns (uint256);

    function getPurchases(address vault)
        external
        view
        returns (Purchase[] memory);

    function getPremiums(address vault, uint256 optionsAmount)
        external
        view
        returns (uint256);

    function getOptionsAllocation(address vault, uint256 allocatedOptions)
        external
        view
        returns (uint256);

    function requestPurchase(address vault, uint256 optionsAmount)
        external
        returns (uint256);

    function allocateOptions(uint256 allocatedOptions)
        external
        returns (uint256);

    function sellToBuyers(uint256 settlementPrice) external returns (uint256);

    function cancelAllPurchases(address vault) external;

    function addWhitelist(address buyer) external;

    function removeWhitelist(address buyer) external;

    function setCeilingPrice(address vault, uint256 price) external;

    function setMinPurchaseAmount(address vault, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * This library supports ERC20s that have quirks in their behavior.
 * One such ERC20 is USDT, which requires allowance to be 0 before calling approve.
 * We plan to update this library with ERC20s that display such idiosyncratic behavior.
 */
library SupportsNonCompliantERC20 {
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    function safeApproveNonCompliant(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        if (address(token) == USDT) {
            SafeERC20.safeApprove(token, spender, 0);
        }
        SafeERC20.safeApprove(token, spender, amount);
    }
}

// SPDX-License-Identifier: MIT

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity =0.8.4;

library DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library AuctionType {
    struct AuctionData {
        IERC20 auctioningToken;
        IERC20 biddingToken;
        uint256 orderCancellationEndDate;
        uint256 auctionEndDate;
        bytes32 initialAuctionOrder;
        uint256 minimumBiddingAmountPerOrder;
        uint256 interimSumBidAmount;
        bytes32 interimOrder;
        bytes32 clearingPriceOrder;
        uint96 volumeClearingPriceOrder;
        bool minFundingThresholdNotReached;
        bool isAtomicClosureAllowed;
        uint256 feeNumerator;
        uint256 minFundingThreshold;
    }
}

interface IGnosisAuction {
    function initiateAuction(
        address _auctioningToken,
        address _biddingToken,
        uint256 orderCancellationEndDate,
        uint256 auctionEndDate,
        uint96 _auctionedSellAmount,
        uint96 _minBuyAmount,
        uint256 minimumBiddingAmountPerOrder,
        uint256 minFundingThreshold,
        bool isAtomicClosureAllowed,
        address accessManagerContract,
        bytes memory accessManagerContractData
    ) external returns (uint256);

    function auctionCounter() external view returns (uint256);

    function auctionData(uint256 auctionId)
        external
        view
        returns (AuctionType.AuctionData memory);

    function auctionAccessManager(uint256 auctionId)
        external
        view
        returns (address);

    function auctionAccessData(uint256 auctionId)
        external
        view
        returns (bytes memory);

    function FEE_DENOMINATOR() external view returns (uint256);

    function feeNumerator() external view returns (uint256);

    function settleAuction(uint256 auctionId) external returns (bytes32);

    function placeSellOrders(
        uint256 auctionId,
        uint96[] memory _minBuyAmounts,
        uint96[] memory _sellAmounts,
        bytes32[] memory _prevSellOrders,
        bytes calldata allowListCallData
    ) external returns (uint64);

    function claimFromParticipantOrder(
        uint256 auctionId,
        bytes32[] memory orders
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {Vault} from "../libraries/Vault.sol";

interface IRibbonThetaVault {
    function currentOption() external view returns (address);

    function nextOption() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function optionAuctionID() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function roundPricePerShare(uint256) external view returns (uint256);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

import "hardhat/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import {WadRayMath} from './WadRayMath.sol';

library MathUtils {
  using SafeMath for uint256;
//   using WadRayMath for uint256;

  /// @dev Ignoring leap years
  uint256 internal constant SECONDS_PER_YEAR = 365 days;
  uint256 internal constant RAY = 1e27;


  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @dev Function to calculate the interest accumulated using a linear interest rate formula
   * @param bRate The borrow rate, in wad
   * @param uRate The utilization rate, in wad
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate linearly accumulated during the timeDelta, in wad
   **/

  function calculateLinearInterest(uint256 bRate, uint256 uRate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    //solium-disable-next-line
    uint256 timeDifference = block.timestamp.sub(uint256(lastUpdateTimestamp));

    console.log("calculateLinearInterest", timeDifference, bRate, uRate);
    console.log("lastUpdateTimestamp", lastUpdateTimestamp);

    return (bRate.mul(uRate).div(RAY).mul(timeDifference) / SECONDS_PER_YEAR).add(RAY);
  }

  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint40 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal view returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp.sub(uint256(lastUpdateTimestamp));

    if (exp == 0) {
      return RAY;
    }

    console.log("calculateCompoundedInterest", rate, lastUpdateTimestamp, currentTimestamp);
    console.log("exp", exp, SECONDS_PER_YEAR);
    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDS_PER_YEAR;
    console.log("ratePerSecond", ratePerSecond, ratePerSecond.mul(exp));

    uint256 basePowerTwo = ratePerSecond.mul(ratePerSecond).div(RAY);
    uint256 basePowerThree = basePowerTwo.mul(ratePerSecond).div(RAY);

    uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
    uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;
    console.log("secondTerm,thirdTerm", secondTerm,thirdTerm, basePowerTwo);
    console.log("basePowerThree", basePowerThree);

    console.log("nnnnnn - ",  uint256(RAY).add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm));

    return uint256(RAY).add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
  }

  /**
   * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
   * @param rate The interest rate (in ray)
   * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
   **/
  function calculateCompoundedInterest(uint256 rate, uint40 lastUpdateTimestamp)
    internal
    view
    returns (uint256)
  {
    return calculateCompoundedInterest(rate, lastUpdateTimestamp, block.timestamp);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

interface ILiquidity{
    function availableBorrowLimit() external view returns (uint256);
    function lockAmount(uint256 _amount) external;
    function unlockAmount(uint256 _amount) external;
    function pricePerShares(uint16 round)external view returns(uint256,uint256);
    function currentRound() external view returns(uint16);
    function borrow(uint256 borrowAmount, uint256 repaidAmount, uint256 newDebtShares, uint256 repaidDebtShares) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Pool} from "./Pool.sol";

library ShareMathPool {
    using SafeMath for uint256;

    uint256 internal constant PLACEHOLDER_UINT = 1;

    function assetToShares(
        uint256 assetAmount,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return assetAmount.mul(10**27).div(assetPerShare);
    }

    function sharesToAsset(
        uint256 shares,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256) {
        // If this throws, it means that vault's roundPricePerShare[currentRound] has not been set yet
        // which should never happen.
        // Has to be larger than 1 because `1` is used in `initRoundPricePerShares` to prevent cold writes.
        require(assetPerShare > PLACEHOLDER_UINT, "Invalid assetPerShare");

        return shares.mul(assetPerShare).div(10**27);
    }

    /**
     * @notice Returns the shares unredeemed by the user given their DepositReceipt
     * @param depositReceipt is the user's deposit receipt
     * @param currentRound is the `round` stored on the vault
     * @param assetPerShare is the price in asset per share
     * @param decimals is the number of decimals the asset/shares use
     * @return unredeemedShares is the user's virtual balance of shares that are owed
     */
    function getSharesFromReceipt(
        Pool.DepositReceipt memory depositReceipt,
        uint256 currentRound,
        uint256 assetPerShare,
        uint256 decimals
    ) internal pure returns (uint256 unredeemedShares) {
        if (depositReceipt.round > 0 && depositReceipt.round < currentRound) {
            uint256 sharesFromRound =
                assetToShares(depositReceipt.amount, assetPerShare, decimals);

            return
                uint256(depositReceipt.unredeemedShares).add(sharesFromRound);
        }
        return depositReceipt.unredeemedShares;
    }

    function pricePerShare(
        uint256 totalSupply,
        uint256 totalBalance,
        uint256 pendingAmount,
        uint256 decimals
    ) internal pure returns (uint256) {
        uint256 singleShare = 10**decimals;
        return
            totalSupply > 0
                ? singleShare.mul(totalBalance.sub(pendingAmount)).div(
                    totalSupply
                )
                : singleShare;
    }

    /************************************************
     *  HELPERS
     ***********************************************/

    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {DSMath} from "../../../vendor/DSMath.sol";
import {IYearnRegistry, IYearnVault} from "../../../interfaces/IYearn.sol";
import {Vault} from "../../../libraries/Vault.sol";
import {VaultLifecycle} from "../../../libraries/VaultLifecycle.sol";
import {VaultLifecycleYearn} from "../../../libraries/VaultLifecycleYearn.sol";
import {ShareMath} from "../../../libraries/ShareMath.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";

contract RibbonVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Yearn vault contract
    IYearnVault public collateralToken;

    // Gap is left to avoid storage collisions. Though RibbonVault is not upgradeable, we add this as a safety measure.
    uint256[30] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to RibbonThetaYearnVaultStorage
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public immutable USDC;

    /// @notice 15 minute timelock between commitAndClose and rollToNexOption.
    uint256 public constant DELAY = 0;

    /// @notice Withdrawal buffer for yearn vault
    uint256 public constant YEARN_WITHDRAWAL_BUFFER = 5; // 0.05%

    /// @notice Slippage incurred during withdrawal
    uint256 public constant YEARN_WITHDRAWAL_SLIPPAGE = 5; // 0.05%

    /// @notice 7 day period between each options sale.
    uint256 public constant PERIOD = 7 days;

    // Number of weeks per year = 52.142857 weeks * FEE_MULTIPLIER = 52142857
    // Dividing by weeks per year requires doing num.mul(FEE_MULTIPLIER).div(WEEKS_PER_YEAR)
    uint256 private constant WEEKS_PER_YEAR = 52142857;

    // GAMMA_CONTROLLER is the top-level contract in Gamma protocol
    // which allows users to perform multiple actions on their vaults
    // and positions https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/Controller.sol
    address public immutable GAMMA_CONTROLLER;

    // MARGIN_POOL is Gamma protocol's collateral pool.
    // Needed to approve collateral.safeTransferFrom for minting otokens.
    // https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/MarginPool.sol
    address public immutable MARGIN_POOL;

    // GNOSIS_EASY_AUCTION is Gnosis protocol's contract for initiating auctions and placing bids
    // https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
    address public immutable GNOSIS_EASY_AUCTION;

    // Yearn registry contract
    address public immutable YEARN_REGISTRY;

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _gnosisEasyAuction is the contract address that facilitates gnosis auctions
     * @param _yearnRegistry is the address of the yearn registry from token to vault token
     */
    constructor(
        address _weth,
        address _usdc,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction,
        address _yearnRegistry
    ) {
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_gnosisEasyAuction != address(0), "!_gnosisEasyAuction");
        require(_gammaController != address(0), "!_gammaController");
        require(_marginPool != address(0), "!_marginPool");
        require(_yearnRegistry != address(0), "!_yearnRegistry");

        WETH = _weth;
        USDC = _usdc;
        GAMMA_CONTROLLER = _gammaController;
        MARGIN_POOL = _marginPool;
        GNOSIS_EASY_AUCTION = _gnosisEasyAuction;
        YEARN_REGISTRY = _yearnRegistry;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     */
    function baseInitialize(
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        VaultLifecycle.verifyInitializerParams(
            _owner,
            _keeper,
            _feeRecipient,
            _performanceFee,
            _managementFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        keeper = _keeper;

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee.mul(Vault.FEE_MULTIPLIER).div(
            WEEKS_PER_YEAR
        );
        vaultParams = _vaultParams;

        _upgradeYearnVault();

        uint256 assetBalance = totalBalance();
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "!newKeeper");
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        require(newFeeRecipient != feeRecipient, "Must be new feeRecipient");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(
            newManagementFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid management fee"
        );

        // We are dividing annualized management fee by num weeks in a year
        uint256 tmpManagementFee =
            newManagementFee.mul(Vault.FEE_MULTIPLIER).div(WEEKS_PER_YEAR);

        emit ManagementFeeSet(managementFee, newManagementFee);

        managementFee = tmpManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(
            newPerformanceFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid performance fee"
        );
        emit PerformanceFeeSet(performanceFee, newPerformanceFee);
        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "!amount");
        require(creditor != address(0), "!creditor");

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `collateralToken` into the contract and mint vault shares.
     * @param amount is the amount of `collateralToken` to deposit
     */
    function depositYieldToken(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        uint256 amountInAsset =
            DSMath.wmul(
                amount,
                collateralToken.pricePerShare().mul(
                    VaultLifecycleYearn.decimalShift(address(collateralToken))
                )
            );

        _depositFor(amountInAsset, msg.sender);

        IERC20(address(collateralToken)).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance().add(amount);

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        uint256 depositAmount = amount;
        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(amount);
        ShareMath.assertUint128(newTotalPending);
        vaultState.totalPending = uint128(newTotalPending);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;
        emit InitiateWithdraw(msg.sender, numShares, currentRound);
        uint256 existingShares = uint256(withdrawal.shares);
        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }
        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMath.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        VaultLifecycleYearn.unwrapYieldToken(
            withdrawAmount,
            vaultParams.asset,
            address(collateralToken),
            YEARN_WITHDRAWAL_BUFFER,
            YEARN_WITHDRAWAL_SLIPPAGE
        );

        require(withdrawAmount > 0, "!withdrawAmount");

        VaultLifecycleYearn.transferAsset(
            WETH,
            vaultParams.asset,
            msg.sender,
            withdrawAmount
        );

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Vault.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);

        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(numShares)
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Helper function that helps to save gas for writing values into the roundPricePerShare map.
     *         Writing `1` into the map makes subsequent writes warm, reducing the gas from 20k to 5k.
     *         Having 1 initialized beforehand will not be an issue as long as we round down share calculations to 0.
     * @param numRounds is the number of rounds to initialize in the map
     */
    function initRounds(uint256 numRounds) external nonReentrant {
        require(numRounds > 0, "!numRounds");

        uint256 _round = vaultState.round;
        for (uint256 i = 0; i < numRounds; i++) {
            uint256 index = _round + i;
            require(roundPricePerShare[index] == 0, "Initialized"); // AVOID OVERWRITING ACTUAL VALUES
            roundPricePerShare[index] = ShareMath.PLACEHOLDER_UINT;
        }
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as setting next option, minting new shares, getting vault fees, etc.
     * @param lastQueuedWithdrawAmount is old queued withdraw amount
     * @param currentQueuedWithdrawShares is the queued withdraw shares for the current round
     * @return newOption is the new option address
     * @return queuedWithdrawAmount is the queued amount for withdrawal
     */
    function _rollToNextOption(
        uint256 lastQueuedWithdrawAmount,
        uint256 currentQueuedWithdrawShares
    ) internal returns (address, uint256) {
        require(block.timestamp >= optionState.nextOptionReadyAt, "!ready");

        address newOption = optionState.nextOption;
        require(newOption != address(0), "!nextOption");

        (
            uint256 lockedBalance,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        ) =
            VaultLifecycle.rollover(
                vaultState,
                VaultLifecycle.RolloverParams(
                    vaultParams.decimals,
                    totalBalance(),
                    totalSupply(),
                    lastQueuedWithdrawAmount,
                    performanceFee,
                    managementFee,
                    currentQueuedWithdrawShares
                )
            );

        optionState.currentOption = newOption;
        optionState.nextOption = address(0);

        // Finalize the pricePerShare at the end of the round
        uint256 currentRound = vaultState.round;
        roundPricePerShare[currentRound] = newPricePerShare;

        address recipient = feeRecipient;

        emit CollectVaultFees(
            performanceFeeInAsset,
            totalVaultFee,
            currentRound,
            recipient
        );

        vaultState.totalPending = 0;
        vaultState.round = uint16(currentRound + 1);
        ShareMath.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);

        _mint(address(this), mintShares);

        address collateral = address(collateralToken);

        // Wrap entire `asset` balance to `collateralToken` balance
        VaultLifecycleYearn.wrapToYieldToken(vaultParams.asset, collateral);

        if (totalVaultFee > 0) {
            VaultLifecycleYearn.withdrawYieldAndBaseToken(
                WETH,
                vaultParams.asset,
                collateral,
                recipient,
                totalVaultFee
            );
        }

        return (newOption, queuedWithdrawAmount);
    }

    /*
      Upgrades the vault to point to the latest yearn vault for the asset token
    */
    function upgradeYearnVault() external onlyOwner {
        // Unwrap old yvUSDC
        IYearnVault collateral = IYearnVault(collateralToken);
        collateral.withdraw(
            collateral.balanceOf(address(this)),
            address(this),
            YEARN_WITHDRAWAL_SLIPPAGE
        );

        _upgradeYearnVault();
    }

    function _upgradeYearnVault() internal {
        address collateralAddr =
            IYearnRegistry(YEARN_REGISTRY).latestVault(vaultParams.asset);
        require(collateralAddr != address(0), "!collateralToken");
        collateralToken = IYearnVault(collateralAddr);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                _decimals
            );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        return
            uint256(vaultState.lockedAmount)
                .add(IERC20(vaultParams.asset).balanceOf(address(this)))
                .add(
                DSMath.wmul(
                    collateralToken.balanceOf(address(this)),
                    collateralToken.pricePerShare().mul(
                        VaultLifecycleYearn.decimalShift(
                            address(collateralToken)
                        )
                    )
                )
            );
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function nextOptionReadyAt() external view returns (uint256) {
        return optionState.nextOptionReadyAt;
    }

    function currentOption() external view returns (address) {
        return optionState.currentOption;
    }

    function nextOption() external view returns (address) {
        return optionState.nextOption;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }

    /************************************************
     *  HELPERS
     ***********************************************/
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IYearnVault {
    function pricePerShare() external view returns (uint256);

    function deposit(uint256 _amount, address _recipient)
        external
        returns (uint256);

    function withdraw(
        uint256 _maxShares,
        address _recipient,
        uint256 _maxLoss
    ) external returns (uint256);

    function approve(address _recipient, uint256 _amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function decimals() external view returns (uint256);
}

interface IYearnRegistry {
    function latestVault(address token) external returns (address);
}

interface IYearnPricer {
    function setExpiryPriceInOracle(uint256 _expiryTimestamp) external;

    function getPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {IStrikeSelection} from "../interfaces/IRibbon.sol";
import {GnosisAuction} from "./GnosisAuction.sol";
import {
    IOtokenFactory,
    IOtoken,
    IController,
    GammaTypes
} from "../interfaces/GammaInterface.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {IGnosisAuction} from "../interfaces/IGnosisAuction.sol";
import {IOptionsPurchaseQueue} from "../interfaces/IOptionsPurchaseQueue.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";

library VaultLifecycle {
    using SafeMath for uint256;
    using SupportsNonCompliantERC20 for IERC20;

    struct CloseParams {
        address OTOKEN_FACTORY;
        address USDC;
        address currentOption;
        uint256 delay;
        uint16 lastStrikeOverrideRound;
        uint256 overriddenStrikePrice;
        address strikeSelection;
        address optionsPremiumPricer;
        uint256 premiumDiscount;
    }

    /// @notice Default maximum option allocation for the queue (50%)
    uint256 internal constant QUEUE_OPTION_ALLOCATION = 5000;

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return otokenAddress is the address of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */
    function commitAndClose(
        CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        Vault.VaultState storage vaultState
    )
        external
        returns (
            address otokenAddress,
            uint256 strikePrice,
            uint256 delta
        )
    {
        uint256 expiry = getNextExpiry(closeParams.currentOption);

        IStrikeSelection selection =
            IStrikeSelection(closeParams.strikeSelection);

        bool isPut = vaultParams.isPut;
        address underlying = vaultParams.underlying;
        address asset = vaultParams.asset;

        (strikePrice, delta) = closeParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (closeParams.overriddenStrikePrice, selection.delta())
            : selection.getStrikePrice(expiry, isPut);

        require(strikePrice != 0, "!strikePrice");

        // retrieve address if option already exists, or deploy it
        otokenAddress = getOrDeployOtoken(
            closeParams,
            vaultParams,
            underlying,
            asset,
            strikePrice,
            expiry,
            isPut
        );

        return (otokenAddress, strikePrice, delta);
    }

    /**
     * @notice Verify the otoken has the correct parameters to prevent vulnerability to opyn contract changes
     * @param otokenAddress is the address of the otoken
     * @param vaultParams is the struct with vault general data
     * @param collateralAsset is the address of the collateral asset
     * @param USDC is the address of usdc
     * @param delay is the delay between commitAndClose and rollToNextOption
     */
    function verifyOtoken(
        address otokenAddress,
        Vault.VaultParams storage vaultParams,
        address collateralAsset,
        address USDC,
        uint256 delay
    ) private view {
        require(otokenAddress != address(0), "!otokenAddress");

        IOtoken otoken = IOtoken(otokenAddress);
        require(otoken.isPut() == vaultParams.isPut, "Type mismatch");
        require(
            otoken.underlyingAsset() == vaultParams.underlying,
            "Wrong underlyingAsset"
        );
        require(
            otoken.collateralAsset() == collateralAsset,
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        require(otoken.strikeAsset() == USDC, "strikeAsset != USDC");

        uint256 readyAt = block.timestamp.add(delay);
        require(otoken.expiryTimestamp() >= readyAt, "Expiry before delay");
    }

    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the vaults total balance of the asset
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the total amount queued for withdrawals
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     * @param currentQueuedWithdrawShares is amount of queued withdrawals from the current round
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 currentQueuedWithdrawShares;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from RibbonVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function rollover(
        Vault.VaultState storage vaultState,
        RolloverParams calldata params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees =
            currentBalance.sub(params.lastQueuedWithdrawAmount);

        {
            (performanceFeeInAsset, , totalVaultFee) = VaultLifecycle
                .getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                params.managementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance.sub(totalVaultFee);

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply.sub(lastQueuedWithdrawShares),
                currentBalance.sub(params.lastQueuedWithdrawAmount),
                pendingAmount,
                params.decimals
            );

            queuedWithdrawAmount = params.lastQueuedWithdrawAmount.add(
                ShareMath.sharesToAsset(
                    params.currentQueuedWithdrawShares,
                    newPricePerShare,
                    params.decimals
                )
            );

            // After closing the short, if the options expire in-the-money
            // vault pricePerShare would go down because vault's asset balance decreased.
            // This ensures that the newly-minted shares do not take on the loss.
            mintShares = ShareMath.assetToShares(
                pendingAmount,
                newPricePerShare,
                params.decimals
            );
        }

        return (
            currentBalance.sub(queuedWithdrawAmount), // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            mintShares,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
     * @param gammaController is the address of the opyn controller contract
     * @param marginPool is the address of the opyn margin contract which holds the collateral
     * @param oTokenAddress is the address of the otoken to mint
     * @param depositAmount is the amount of collateral to deposit
     * @return the otoken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address oTokenAddress,
        uint256 depositAmount
    ) external returns (uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID =
            (controller.getAccountVaultCounter(address(this))).add(1);

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IOtoken oToken = IOtoken(oTokenAddress);
        address collateralAsset = oToken.collateralAsset();

        uint256 collateralDecimals =
            uint256(IERC20Detailed(collateralAsset).decimals());
        uint256 mintAmount;

        if (oToken.isPut()) {
            // For minting puts, there will be instances where the full depositAmount will not be used for minting.
            // This is because of an issue with precision.
            //
            // For ETH put options, we are calculating the mintAmount (10**8 decimals) using
            // the depositAmount (10**18 decimals), which will result in truncation of decimals when scaling down.
            // As a result, there will be tiny amounts of dust left behind in the Opyn vault when minting put otokens.
            //
            // For simplicity's sake, we do not refund the dust back to the address(this) on minting otokens.
            // We retain the dust in the vault so the calling contract can withdraw the
            // actual locked amount + dust at settlement.
            //
            // To test this behavior, we can console.log
            // MarginCalculatorInterface(0x7A48d10f372b3D7c60f6c9770B91398e4ccfd3C7).getExcessCollateral(vault)
            // to see how much dust (or excess collateral) is left behind.
            mintAmount = depositAmount
                .mul(10**Vault.OTOKEN_DECIMALS)
                .mul(10**18) // we use 10**18 to give extra precision
                .div(oToken.strikePrice().mul(10**(10 + collateralDecimals)));
        } else {
            mintAmount = depositAmount;

            if (collateralDecimals > 8) {
                uint256 scaleBy = 10**(collateralDecimals.sub(8)); // oTokens have 8 decimals
                if (mintAmount > scaleBy) {
                    mintAmount = depositAmount.div(scaleBy); // scale down from 10**18 to 10**8
                }
            }
        }

        // double approve to fix non-compliant ERC20s
        IERC20 collateralToken = IERC20(collateralAsset);
        collateralToken.safeApproveNonCompliant(marginPool, depositAmount);

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](3);

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oTokenAddress, // option address
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        return mintAmount;
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the opyn controller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(address gammaController) external returns (uint256) {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        // The short position has been previously closed, or all the otokens have been burned.
        // So we return early.
        if (address(collateralToken) == address(0)) {
            return 0;
        }

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultID, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Exercises the ITM option using existing long otoken position. Currently this implementation is simple.
     * It calls the `Redeem` action to claim the payout.
     * @param gammaController is the address of the opyn controller contract
     * @param oldOption is the address of the old option
     * @param asset is the address of the vault's asset
     * @return amount of asset received by exercising the option
     */
    function settleLong(
        address gammaController,
        address oldOption,
        address asset
    ) external returns (uint256) {
        IController controller = IController(gammaController);

        uint256 oldOptionBalance = IERC20(oldOption).balanceOf(address(this));

        if (controller.getPayout(oldOption, oldOptionBalance) == 0) {
            return 0;
        }

        uint256 startAssetBalance = IERC20(asset).balanceOf(address(this));

        // If it is after expiry, we need to redeem the profits
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oldOption, // address of otoken
            0, // not used
            oldOptionBalance, // otoken balance
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endAssetBalance = IERC20(asset).balanceOf(address(this));

        return endAssetBalance.sub(startAssetBalance);
    }

    /**
     * @notice Burn the remaining oTokens left over from auction. Currently this implementation is simple.
     * It burns oTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the opyn controller contract
     * @param currentOption is the address of the current option
     * @return amount of collateral redeemed by burning otokens
     */
    function burnOtokens(address gammaController, address currentOption)
        external
        returns (uint256)
    {
        uint256 numOTokensToBurn =
            IERC20(currentOption).balanceOf(address(this));

        require(numOTokensToBurn > 0, "No oTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // Burning `amount` of oTokens from the ribbon vault,
        // then withdrawing the corresponding collateral amount from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](2);

        actions[0] = IController.ActionArgs(
            IController.ActionType.BurnShortOption,
            address(this), // owner
            address(this), // address to transfer from
            address(vault.shortOtokens[0]), // otoken address
            vaultID, // vaultId
            numOTokensToBurn, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            address(collateralToken), // withdrawn asset
            vaultID, // vaultId
            vault.collateralAmounts[0].mul(numOTokensToBurn).div(
                vault.shortAmounts[0]
            ), // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        pure
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount
                ? currentBalance.sub(pendingAmount)
                : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? lockedBalanceSansPending
                    .sub(lastLockedAmount)
                    .mul(performanceFeePercent)
                    .div(100 * Vault.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? lockedBalanceSansPending.mul(managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            _vaultFee = _performanceFeeInAsset.add(_managementFeeInAsset);
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param underlying is the address of the underlying asset of the option
     * @param collateralAsset is the address of the collateral asset of the option
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @param isPut is whether the option is a put
     * @return the address of the option
     */
    function getOrDeployOtoken(
        CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        address underlying,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) internal returns (address) {
        IOtokenFactory factory = IOtokenFactory(closeParams.OTOKEN_FACTORY);

        address otokenFromFactory =
            factory.getOtoken(
                underlying,
                closeParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        if (otokenFromFactory != address(0)) {
            return otokenFromFactory;
        }

        address otoken =
            factory.createOtoken(
                underlying,
                closeParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        verifyOtoken(
            otoken,
            vaultParams,
            collateralAsset,
            closeParams.USDC,
            closeParams.delay
        );

        return otoken;
    }

    function getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) external view returns (uint256) {
        return
            _getOTokenPremium(
                oTokenAddress,
                optionsPremiumPricer,
                premiumDiscount
            );
    }

    function _getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer =
            IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium =
            premiumPricer.getPremium(
                newOToken.strikePrice(),
                newOToken.expiryTimestamp(),
                newOToken.isPut()
            );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(
            100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER
        );

        require(
            optionPremium <= type(uint96).max,
            "optionPremium > type(uint96) max value!"
        );
        require(optionPremium > 0, "!optionPremium");

        return optionPremium;
    }

    /**
     * @notice Starts the gnosis auction
     * @param auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(GnosisAuction.AuctionDetails calldata auctionDetails)
        external
        returns (uint256)
    {
        return GnosisAuction.startAuction(auctionDetails);
    }

    /**
     * @notice Settles the gnosis auction
     * @param gnosisEasyAuction is the contract address of Gnosis easy auction protocol
     * @param auctionID is the auction ID of the gnosis easy auction
     */
    function settleAuction(address gnosisEasyAuction, uint256 auctionID)
        internal
    {
        IGnosisAuction(gnosisEasyAuction).settleAuction(auctionID);
    }

    /**
     * @notice Places a bid in an auction
     * @param bidDetails is the struct with all the details of the
      bid including the auction's id and how much to bid
     */
    function placeBid(GnosisAuction.BidDetails calldata bidDetails)
        external
        returns (
            uint256 sellAmount,
            uint256 buyAmount,
            uint64 userId
        )
    {
        return GnosisAuction.placeBid(bidDetails);
    }

    /**
     * @notice Claims the oTokens belonging to the vault
     * @param auctionSellOrder is the sell order of the bid
     * @param gnosisEasyAuction is the address of the gnosis auction contract
     holding custody to the funds
     * @param counterpartyThetaVault is the address of the counterparty theta
     vault of this delta vault
     */
    function claimAuctionOtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) external {
        GnosisAuction.claimAuctionOtokens(
            auctionSellOrder,
            gnosisEasyAuction,
            counterpartyThetaVault
        );
    }

    /**
     * @notice Allocates the vault's minted options to the OptionsPurchaseQueue contract
     * @dev Skipped if the optionsPurchaseQueue doesn't exist
     * @param optionsPurchaseQueue is the OptionsPurchaseQueue contract
     * @param option is the minted option
     * @param optionsAmount is the amount of options minted
     * @param optionAllocation is the maximum % of options to allocate towards the purchase queue (will only allocate
     *  up to the amount that is on the queue)
     * @return allocatedOptions is the amount of options that ended up getting allocated to the OptionsPurchaseQueue
     */
    function allocateOptions(
        address optionsPurchaseQueue,
        address option,
        uint256 optionsAmount,
        uint256 optionAllocation
    ) external returns (uint256 allocatedOptions) {
        // Skip if optionsPurchaseQueue is address(0)
        if (optionsPurchaseQueue != address(0)) {
            allocatedOptions = optionsAmount.mul(optionAllocation).div(
                100 * Vault.OPTION_ALLOCATION_MULTIPLIER
            );
            allocatedOptions = IOptionsPurchaseQueue(optionsPurchaseQueue)
                .getOptionsAllocation(address(this), allocatedOptions);

            if (allocatedOptions != 0) {
                IERC20(option).approve(optionsPurchaseQueue, allocatedOptions);
                IOptionsPurchaseQueue(optionsPurchaseQueue).allocateOptions(
                    allocatedOptions
                );
            }
        }

        return allocatedOptions;
    }

    /**
     * @notice Sell the allocated options to the purchase queue post auction settlement
     * @dev Reverts if the auction hasn't settled yet
     * @param optionsPurchaseQueue is the OptionsPurchaseQueue contract
     * @param gnosisEasyAuction The address of the Gnosis Easy Auction contract
     * @return totalPremiums Total premiums earnt by the vault
     */
    function sellOptionsToQueue(
        address optionsPurchaseQueue,
        address gnosisEasyAuction,
        uint256 optionAuctionID
    ) external returns (uint256) {
        uint256 settlementPrice =
            getAuctionSettlementPrice(gnosisEasyAuction, optionAuctionID);
        require(settlementPrice != 0, "!settlementPrice");

        return
            IOptionsPurchaseQueue(optionsPurchaseQueue).sellToBuyers(
                settlementPrice
            );
    }

    /**
     * @notice Gets the settlement price of a settled auction
     * @param gnosisEasyAuction The address of the Gnosis Easy Auction contract
     * @return settlementPrice Auction settlement price
     */
    function getAuctionSettlementPrice(
        address gnosisEasyAuction,
        uint256 optionAuctionID
    ) public view returns (uint256) {
        bytes32 clearingPriceOrder =
            IGnosisAuction(gnosisEasyAuction)
                .auctionData(optionAuctionID)
                .clearingPriceOrder;

        if (clearingPriceOrder == bytes32(0)) {
            // Current auction hasn't settled yet
            return 0;
        } else {
            // We decode the clearingPriceOrder to find the auction settlement price
            // settlementPrice = clearingPriceOrder.sellAmount / clearingPriceOrder.buyAmount
            return
                (10**Vault.OTOKEN_DECIMALS)
                    .mul(
                    uint96(uint256(clearingPriceOrder)) // sellAmount
                )
                    .div(
                    uint96(uint256(clearingPriceOrder) >> 96) // buyAmount
                );
        }
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        address feeRecipient,
        uint256 performanceFee,
        uint256 managementFee,
        string calldata tokenName,
        string calldata tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) external pure {
        require(owner != address(0), "!owner");
        require(keeper != address(0), "!keeper");
        require(feeRecipient != address(0), "!feeRecipient");
        require(
            performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "performanceFee >= 100%"
        );
        require(
            managementFee < 100 * Vault.FEE_MULTIPLIER,
            "managementFee >= 100%"
        );
        require(bytes(tokenName).length > 0, "!tokenName");
        require(bytes(tokenSymbol).length > 0, "!tokenSymbol");

        require(_vaultParams.asset != address(0), "!asset");
        require(_vaultParams.underlying != address(0), "!underlying");
        require(_vaultParams.minimumSupply > 0, "!minimumSupply");
        require(_vaultParams.cap > 0, "!cap");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param currentOption is the otoken address that the vault is currently writing
     */
    function getNextExpiry(address currentOption)
        internal
        view
        returns (uint256)
    {
        // uninitialized state
        if (currentOption == address(0)) {
            return getNextFriday(block.timestamp);
        }
        uint256 currentExpiry = IOtoken(currentOption).expiryTimestamp();

        // After options expiry if no options are written for >1 week
        // We need to give the ability continue writing options
        if (block.timestamp > currentExpiry + 7 days) {
            return getNextFriday(block.timestamp);
        }
        return getNextFriday(currentExpiry);
    }

    /**
     * @notice Gets the next options expiry timestamp
     * @param timestamp is the expiry timestamp of the current option
     * Reference: https://codereview.stackexchange.com/a/33532
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DSMath} from "../vendor/DSMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VaultLifecycle} from "./VaultLifecycle.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {IYearnVault} from "../interfaces/IYearn.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IStrikeSelection} from "../interfaces/IRibbon.sol";
import {
    IOtokenFactory,
    IOtoken,
    IController,
    GammaTypes
} from "../interfaces/GammaInterface.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";

library VaultLifecycleYearn {
    using SafeMath for uint256;
    using SupportsNonCompliantERC20 for IERC20;
    using SafeERC20 for IERC20;

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @param collateralAsset is the address of the collateral asset
     * @return otokenAddress is the address of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */
    function commitAndClose(
        VaultLifecycle.CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        Vault.VaultState storage vaultState,
        address collateralAsset
    )
        external
        returns (
            address otokenAddress,
            uint256 strikePrice,
            uint256 delta
        )
    {
        uint256 expiry =
            VaultLifecycle.getNextExpiry(closeParams.currentOption);

        bool isPut = vaultParams.isPut;

        IStrikeSelection selection =
            IStrikeSelection(closeParams.strikeSelection);

        // calculate strike and delta
        (strikePrice, delta) = closeParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (closeParams.overriddenStrikePrice, selection.delta())
            : selection.getStrikePrice(expiry, isPut);

        require(strikePrice != 0, "!strikePrice");

        // retrieve address if option already exists, or deploy it
        otokenAddress = VaultLifecycle.getOrDeployOtoken(
            closeParams,
            vaultParams,
            vaultParams.underlying,
            collateralAsset,
            strikePrice,
            expiry,
            isPut
        );

        return (otokenAddress, strikePrice, delta);
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param currentShareSupply is the total supply of shares
     * @param currentBalance is the total balance of the vault
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     */
    function rollover(
        uint256 currentShareSupply,
        uint256 currentBalance,
        Vault.VaultParams calldata vaultParams,
        Vault.VaultState calldata vaultState
    )
        external
        pure
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares
        )
    {
        uint256 pendingAmount = uint256(vaultState.totalPending);
        uint256 _decimals = vaultParams.decimals;

        newPricePerShare = ShareMath.pricePerShare(
            currentShareSupply,
            currentBalance,
            pendingAmount,
            _decimals
        );

        // After closing the short, if the options expire in-the-money
        // vault pricePerShare would go down because vault's asset balance decreased.
        // This ensures that the newly-minted shares do not take on the loss.
        uint256 _mintShares =
            ShareMath.assetToShares(pendingAmount, newPricePerShare, _decimals);

        uint256 newSupply = currentShareSupply.add(_mintShares);

        uint256 queuedAmount =
            newSupply > 0
                ? ShareMath.sharesToAsset(
                    vaultState.queuedWithdrawShares,
                    newPricePerShare,
                    _decimals
                )
                : 0;

        return (
            currentBalance.sub(queuedAmount),
            queuedAmount,
            newPricePerShare,
            _mintShares
        );
    }

    /**
     * @notice Withdraws yvWETH + WETH (if necessary) from vault using vault shares
     * @param weth is the weth address
     * @param asset is the vault asset address
     * @param collateralToken is the address of the collateral token
     * @param recipient is the recipient
     * @param amount is the withdraw amount in `asset`
     * @return withdrawAmount is the withdraw amount in `collateralToken`
     */
    function withdrawYieldAndBaseToken(
        address weth,
        address asset,
        address collateralToken,
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        uint256 pricePerYearnShare =
            IYearnVault(collateralToken).pricePerShare();
        uint256 withdrawAmount =
            DSMath.wdiv(
                amount,
                pricePerYearnShare.mul(decimalShift(collateralToken))
            );
        uint256 yieldTokenBalance =
            withdrawYieldToken(collateralToken, recipient, withdrawAmount);

        // If there is not enough yvWETH in the vault, it withdraws as much as possible and
        // transfers the rest in `asset`
        if (withdrawAmount > yieldTokenBalance) {
            withdrawBaseToken(
                weth,
                asset,
                collateralToken,
                recipient,
                withdrawAmount,
                yieldTokenBalance,
                pricePerYearnShare
            );
        }

        return withdrawAmount;
    }

    /**
     * @notice Withdraws yvWETH from vault
     * @param collateralToken is the address of the collateral token
     * @param recipient is the recipient
     * @param withdrawAmount is the withdraw amount in terms of yearn tokens
     * @return yieldTokenBalance is the balance of the yield token
     */
    function withdrawYieldToken(
        address collateralToken,
        address recipient,
        uint256 withdrawAmount
    ) internal returns (uint256) {
        IERC20 collateral = IERC20(collateralToken);

        uint256 yieldTokenBalance = collateral.balanceOf(address(this));
        uint256 yieldTokensToWithdraw =
            DSMath.min(yieldTokenBalance, withdrawAmount);
        if (yieldTokensToWithdraw > 0) {
            collateral.safeTransfer(recipient, yieldTokensToWithdraw);
        }

        return yieldTokenBalance;
    }

    /**
     * @notice Withdraws `asset` from vault
     * @param weth is the weth address
     * @param asset is the vault asset address
     * @param collateralToken is the address of the collateral token
     * @param recipient is the recipient
     * @param withdrawAmount is the withdraw amount in terms of yearn tokens
     * @param yieldTokenBalance is the collateral token (yvWETH) balance of the vault
     * @param pricePerYearnShare is the yvWETH<->WETH price ratio
     */
    function withdrawBaseToken(
        address weth,
        address asset,
        address collateralToken,
        address recipient,
        uint256 withdrawAmount,
        uint256 yieldTokenBalance,
        uint256 pricePerYearnShare
    ) internal {
        uint256 underlyingTokensToWithdraw =
            DSMath.wmul(
                withdrawAmount.sub(yieldTokenBalance),
                pricePerYearnShare.mul(decimalShift(collateralToken))
            );
        transferAsset(
            weth,
            asset,
            payable(recipient),
            underlyingTokensToWithdraw
        );
    }

    /**
     * @notice Unwraps the necessary amount of the yield-bearing yearn token
     *         and transfers amount to vault
     * @param amount is the amount of `asset` to withdraw
     * @param asset is the vault asset address
     * @param collateralToken is the address of the collateral token
     * @param yearnWithdrawalBuffer is the buffer for withdrawals from yearn vault
     * @param yearnWithdrawalSlippage is the slippage for withdrawals from yearn vault
     */
    function unwrapYieldToken(
        uint256 amount,
        address asset,
        address collateralToken,
        uint256 yearnWithdrawalBuffer,
        uint256 yearnWithdrawalSlippage
    ) external {
        uint256 assetBalance = IERC20(asset).balanceOf(address(this));
        IYearnVault collateral = IYearnVault(collateralToken);

        uint256 amountToUnwrap =
            DSMath.wdiv(
                DSMath.max(assetBalance, amount).sub(assetBalance),
                collateral.pricePerShare().mul(decimalShift(collateralToken))
            );

        if (amountToUnwrap > 0) {
            amountToUnwrap = amountToUnwrap
                .add(amountToUnwrap.mul(yearnWithdrawalBuffer).div(10000))
                .sub(1);

            collateral.withdraw(
                amountToUnwrap,
                address(this),
                yearnWithdrawalSlippage
            );
        }
    }

    /**
     * @notice Wraps the necessary amount of the base token to the yield-bearing yearn token
     * @param asset is the vault asset address
     * @param collateralToken is the address of the collateral token
     */
     //TODO: Here instead of YEARN registry it should pe AAVE Pool
    function wrapToYieldToken(address asset, address collateralToken) external {
        uint256 amountToWrap = IERC20(asset).balanceOf(address(this));

        if (amountToWrap > 0) {
            IERC20(asset).safeApprove(collateralToken, amountToWrap);

            // there is a slight imprecision with regards to calculating back from yearn token -> underlying
            // that stems from miscoordination between ytoken .deposit() amount wrapped and pricePerShare
            // at that point in time.
            // ex: if I have 1 eth, deposit 1 eth into yearn vault and calculate value of yearn token balance
            // denominated in eth (via balance(yearn token) * pricePerShare) we will get 1 eth - 1 wei.
            IYearnVault(collateralToken).deposit(amountToWrap, address(this));
        }
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param weth is the weth address
     * @param asset is the vault asset address
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(
        address weth,
        address asset,
        address recipient,
        uint256 amount
    ) public {
        if (asset == weth) {
            IWETH(weth).withdraw(amount);
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "!success");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /**
     * @notice Returns the decimal shift between 18 decimals and asset tokens
     * @param collateralToken is the address of the collateral token
     */
    function decimalShift(address collateralToken)
        public
        view
        returns (uint256)
    {
        return
            10**(uint256(18).sub(IERC20Detailed(collateralToken).decimals()));
    }

    function getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        address collateralAsset
    ) external view returns (uint256) {
        return
            _getOTokenPremium(
                oTokenAddress,
                optionsPremiumPricer,
                premiumDiscount,
                collateralAsset
            );
    }

    function _getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        address collateralAsset
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer =
            IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium =
            premiumPricer.getPremium(
                newOToken.strikePrice(),
                newOToken.expiryTimestamp(),
                newOToken.isPut()
            );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(
            100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER
        );

        // get the black scholes premium of the option and adjust premium based on
        // collateral asset <-> asset exchange rate
        uint256 adjustedPremium =
            DSMath.wmul(
                optionPremium,
                IYearnVault(collateralAsset).pricePerShare().mul(
                    decimalShift(collateralAsset)
                )
            );

        require(
            adjustedPremium <= type(uint96).max,
            "adjustedPremium > type(uint96) max value!"
        );
        require(adjustedPremium > 0, "!adjustedPremium");

        return adjustedPremium;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.4;

// import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
// import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
  /**
   * @dev Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referralCode The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   * @param fee The amount paid in fees
   **/
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @dev Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlying asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param interestRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
   * @param referralCode The referral code used
   **/
//   event Borrow(
//     address indexed reserve,
//     address user,
//     address indexed onBehalfOf,
//     uint256 amount,
//     DataTypes.InterestRateMode interestRateMode,
//     uint256 borrowRate,
//     uint16 indexed referralCode
//   );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   * @param useATokens True if the repayment is done using aTokens, `false` if done with underlying asset directly
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount,
    bool useATokens
  );

  /**
   * @dev Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
//   event SwapBorrowRateMode(
//     address indexed reserve,
//     address indexed user,
//     DataTypes.InterestRateMode interestRateMode
//   );

  /**
   * @dev Emitted on borrow(), repay() and liquidationCall() when using isolated assets
   * @param asset The address of the underlying asset of the reserve
   * @param totalDebt The total isolation mode debt for the reserve
   */
  event IsolationModeTotalDebtUpdated(address indexed asset, uint256 totalDebt);

  /**
   * @dev Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param interestRateMode The flashloan mode: 0 for regular flashloan, 1 for Stable debt, 2 for Variable debt
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
//   event FlashLoan(
//     address indexed target,
//     address initiator,
//     address indexed asset,
//     uint256 amount,
//     DataTypes.InterestRateMode interestRateMode,
//     uint256 premium,
//     uint16 indexed referralCode
//   );

  /**
   * @dev Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
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
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens, burning the
   * equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens
   * @dev  Passing uint256.max as amount will clean up any residual aToken dust balance, if the user aToken
   * balance is not enough to cover the whole debt
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 interestRateMode
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or vice versa
   * @param asset The address of the underlying asset borrowed
   * @param interestRateMode The current interest rate mode of the position being swapped: 1 for Stable, 2 for Variable
   **/
  function swapBorrowRateMode(address asset, uint256 interestRateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too
   *        much has been borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param interestRateModes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata interestRateModes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
   * into consideration. For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
//   function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration)
//     external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
//   function getConfiguration(address asset)
//     external
//     view
//     returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
//   function getUserConfiguration(address user)
//     external
//     view
//     returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state and configuration data of the reserve
   **/
//   function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the underlying assets of all the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the underlying assets of the initialized reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
   * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
   * @return The address of the reserve associated with id
   **/
  function getReserveAddressById(uint16 id) external view returns (address);

  /**
   * @notice Returns the PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
//   function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to the protocol treasury
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
   * - A part is sent to aToken holders as extra, one time accumulated interest
   * - A part is collected by the protocol treasury
   * @dev The total premium is calculated on the total borrowed amount
   * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium, expressed in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
   */
  function updateFlashloanPremiums(
    uint128 flashLoanPremiumTotal,
    uint128 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
//   function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
//   function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Resets the isolation mode total debt of the given asset to zero
   * @dev It requires the given asset has zero debt ceiling
   * @param asset The address of the underlying asset to reset the isolationModeTotalDebt
   */
  function resetIsolationModeTotalDebt(address asset) external;

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow, expressed in bps
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol treasury
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol treasury
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint16);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Rescue and transfer tokens locked in this contract
   * @param token The address of the token
   * @param to The address of the recipient
   * @param amount The amount of token to transfer
   */
  function rescueTokens(
    address token,
    address to,
    uint256 amount
  ) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
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
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {DSMath} from "../../vendor/DSMath.sol";
import {GnosisAuction} from "../../libraries/GnosisAuction.sol";
import {Vault} from "../../libraries/Vault.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {VaultLifecycle} from "../../libraries/VaultLifecycle.sol";
import {VaultLifecycleYearn} from "../../libraries/VaultLifecycleYearn.sol";
import {ILiquidityGauge} from "../../interfaces/ILiquidityGauge.sol";
import {RibbonVault} from "./base/RibbonVault.sol";
import {
    RibbonThetaYearnVaultStorage
} from "../../storage/RibbonThetaYearnVaultStorage.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in RibbonThetaYearnVaultStorage.
 * RibbonThetaYearnVault should not inherit from any other contract aside from RibbonVault, RibbonThetaYearnVaultStorage
 */
contract RibbonThetaYearnVault is RibbonVault, RibbonThetaYearnVaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public immutable OTOKEN_FACTORY;

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    /************************************************
     *  EVENTS
     ***********************************************/

    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address indexed manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address indexed manager
    );

    event NewOptionStrikeSelected(uint256 strikePrice, uint256 delta);

    event PremiumDiscountSet(
        uint256 premiumDiscount,
        uint256 newPremiumDiscount
    );
    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _oTokenFactory is the contract address for minting new opyn option types (strikes, asset, expiry)
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _gnosisEasyAuction is the contract address that facilitates gnosis auctions
     * @param _yearnRegistry is the address of the yearn registry from token to vault token
     */
    constructor(
        address _weth,
        address _usdc,
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction,
        address _yearnRegistry
    )
        RibbonVault(
            _weth,
            _usdc,
            _gammaController,
            _marginPool,
            _gnosisEasyAuction,
            _yearnRegistry
        )
    {
        require(_oTokenFactory != address(0), "!_oTokenFactory");
        OTOKEN_FACTORY = _oTokenFactory;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _owner is the owner of the vault with critical permissions
     * @param _keeper is the keeper of the vault with medium permissions (weekly actions)
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     * @param _premiumDiscount is the vault's discount applied to the premium
     * @param _auctionDuration is the duration of the gnosis auction
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _optionsPremiumPricer,
        address _strikeSelection,
        uint32 _premiumDiscount,
        uint256 _auctionDuration,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(
            _owner,
            _keeper,
            _feeRecipient,
            _managementFee,
            _performanceFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );
        require(_optionsPremiumPricer != address(0), "!_optionsPremiumPricer");
        require(_strikeSelection != address(0), "!_strikeSelection");
        require(
            _premiumDiscount > 0 &&
                _premiumDiscount < 100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "!_premiumDiscount"
        );
        require(_auctionDuration >= MIN_AUCTION_DURATION, "!_auctionDuration");
        optionsPremiumPricer = _optionsPremiumPricer;
        strikeSelection = _strikeSelection;
        premiumDiscount = _premiumDiscount;
        auctionDuration = _auctionDuration;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new discount on premiums for options we are selling
     * @param newPremiumDiscount is the premium discount
     */
    function setPremiumDiscount(uint256 newPremiumDiscount)
        external
        onlyKeeper
    {
        require(
            newPremiumDiscount > 0 &&
                newPremiumDiscount <= 100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "Invalid discount"
        );

        emit PremiumDiscountSet(premiumDiscount, newPremiumDiscount);

        premiumDiscount = newPremiumDiscount;
    }

    /**
     * @notice Sets the new auction duration
     * @param newAuctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        require(
            newAuctionDuration >= MIN_AUCTION_DURATION,
            "Invalid auction duration"
        );
        emit AuctionDurationSet(auctionDuration, newAuctionDuration);

        auctionDuration = newAuctionDuration;
    }

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    function setStrikeSelection(address newStrikeSelection) external onlyOwner {
        require(newStrikeSelection != address(0), "!newStrikeSelection");
        strikeSelection = newStrikeSelection;
    }

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    function setOptionsPremiumPricer(address newOptionsPremiumPricer)
        external
        onlyOwner
    {
        require(
            newOptionsPremiumPricer != address(0),
            "!newOptionsPremiumPricer"
        );
        optionsPremiumPricer = newOptionsPremiumPricer;
    }

    /**
     * @notice Optionality to set strike price manually
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external onlyOwner {
        require(strikePrice > 0, "!strikePrice");
        overriddenStrikePrice = strikePrice;
        lastStrikeOverrideRound = vaultState.round;
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
        liquidityGauge = newLiquidityGauge;
    }

    /**
     * @notice Sets the new optionsPurchaseQueue contract for this vault
     * @param newOptionsPurchaseQueue is the address of the new optionsPurchaseQueue contract
     */
    function setOptionsPurchaseQueue(address newOptionsPurchaseQueue)
        external
        onlyOwner
    {
        optionsPurchaseQueue = newOptionsPurchaseQueue;
    }

    /**
     * @notice Sets oToken Premium
     * @param minPrice is the new oToken Premium in the units of 10**18
     */
    function setMinPrice(uint256 minPrice) external onlyKeeper {
        require(minPrice > 0, "!minPrice");
        currentOtokenPremium = minPrice;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;

        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(amount));
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending).sub(amount)
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        VaultLifecycleYearn.unwrapYieldToken(
            amount,
            vaultParams.asset,
            address(collateralToken),
            YEARN_WITHDRAWAL_BUFFER,
            YEARN_WITHDRAWAL_SLIPPAGE
        );
        VaultLifecycleYearn.transferAsset(
            WETH,
            vaultParams.asset,
            msg.sender,
            amount
        );
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares.add(
            numShares
        );
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        );
    }

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external nonReentrant {
        address _liquidityGauge = liquidityGauge;
        require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
        require(numShares > 0);
        uint256 heldByAccount = balanceOf(msg.sender);
        if (heldByAccount < numShares) {
            _redeem(numShares.sub(heldByAccount), false);
        }
        _transfer(msg.sender, address(this), numShares);
        _approve(address(this), _liquidityGauge, numShares);
        ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    }

    /**
     * @notice Sets the next option the vault will be shorting, and closes the existing short.
     *         This allows all the users to withdraw if the next option is malicious.
     */
    function commitAndClose() external nonReentrant {
        address oldOption = optionState.currentOption;

        VaultLifecycle.CloseParams memory closeParams =
            VaultLifecycle.CloseParams({
                OTOKEN_FACTORY: OTOKEN_FACTORY,
                USDC: USDC,
                currentOption: oldOption,
                delay: DELAY,
                lastStrikeOverrideRound: lastStrikeOverrideRound,
                overriddenStrikePrice: overriddenStrikePrice,
                strikeSelection: strikeSelection,
                optionsPremiumPricer: optionsPremiumPricer,
                premiumDiscount: premiumDiscount
            });

        (address otokenAddress, uint256 strikePrice, uint256 delta) =
            VaultLifecycleYearn.commitAndClose(
                closeParams,
                vaultParams,
                vaultState,
                address(collateralToken)
            );

        emit NewOptionStrikeSelected(strikePrice, delta);

        optionState.nextOption = otokenAddress;
        uint256 nextOptionReady = block.timestamp.add(DELAY);
        require(
            nextOptionReady <= type(uint32).max,
            "Overflow nextOptionReady"
        );
        optionState.nextOptionReadyAt = uint32(nextOptionReady);

        _closeShort(oldOption);
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort(address oldOption) private {
        uint256 lockedAmount = vaultState.lockedAmount;
        if (oldOption != address(0)) {
            vaultState.lastLockedAmount = uint104(lockedAmount);
        }
        vaultState.lockedAmount = 0;

        optionState.currentOption = address(0);

        if (oldOption != address(0)) {
            uint256 withdrawAmount =
                VaultLifecycle.settleShort(GAMMA_CONTROLLER);
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
    }

    /**
     * @notice Rolls the vault's funds into a new short position.
     */
    function rollToNextOption() external onlyKeeper nonReentrant {
        uint256 currQueuedWithdrawShares = currentQueuedWithdrawShares;

        (address newOption, uint256 queuedWithdrawAmount) =
            _rollToNextOption(
                lastQueuedWithdrawAmount,
                currQueuedWithdrawShares
            );

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares).add(
                currQueuedWithdrawShares
            );
        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        // Locked balance denominated in `collateralToken`
        // there is a slight imprecision with regards to calculating back from yearn token -> underlying
        // that stems from miscoordination between ytoken .deposit() amount wrapped and pricePerShare
        // at that point in time.
        // ex: if I have 1 eth, deposit 1 eth into yearn vault and calculate value of yearn token balance
        // denominated in eth (via balance(yearn token) * pricePerShare) we will get 1 eth - 1 wei.

        // We are subtracting `collateralAsset` balance by queuedWithdrawAmount denominated in `collateralAsset` plus
        // a buffer for withdrawals taking into account slippage from yearn vault

        uint256 lockedBalance =
            collateralToken.balanceOf(address(this)).sub(
                DSMath.wdiv(
                    queuedWithdrawAmount.add(
                        queuedWithdrawAmount.mul(YEARN_WITHDRAWAL_BUFFER).div(
                            10000
                        )
                    ),
                    collateralToken.pricePerShare().mul(
                        VaultLifecycleYearn.decimalShift(
                            address(collateralToken)
                        )
                    )
                )
            );

        emit OpenShort(newOption, lockedBalance, msg.sender);

        uint256 optionsMintAmount =
            VaultLifecycle.createShort(
                GAMMA_CONTROLLER,
                MARGIN_POOL,
                newOption,
                lockedBalance
            );

        VaultLifecycle.allocateOptions(
            optionsPurchaseQueue,
            newOption,
            optionsMintAmount,
            VaultLifecycle.QUEUE_OPTION_ALLOCATION
        );

        _startAuction();
    }

    /**
     * @notice Initiate the gnosis auction.
     */
    function startAuction() external onlyKeeper nonReentrant {
        _startAuction();
    }

    function _startAuction() private {
        GnosisAuction.AuctionDetails memory auctionDetails;

        address currentOtoken = optionState.currentOption;

        auctionDetails.oTokenAddress = currentOtoken;
        auctionDetails.gnosisEasyAuction = GNOSIS_EASY_AUCTION;
        auctionDetails.asset = vaultParams.asset;
        auctionDetails.assetDecimals = vaultParams.decimals;
        auctionDetails.oTokenPremium = currentOtokenPremium;
        auctionDetails.duration = auctionDuration;

        optionAuctionID = VaultLifecycle.startAuction(auctionDetails);
    }

    /**
     * @notice Sell the allocated options to the purchase queue post auction settlement
     */
    function sellOptionsToQueue() external onlyKeeper nonReentrant {
        VaultLifecycle.sellOptionsToQueue(
            optionsPurchaseQueue,
            GNOSIS_EASY_AUCTION,
            optionAuctionID
        );
    }

    /**
     * @notice Burn the remaining oTokens left over from gnosis auction.
     */
    function burnRemainingOTokens() external onlyKeeper nonReentrant {
        uint256 unlockedAssetAmount =
            VaultLifecycle.burnOtokens(
                GAMMA_CONTROLLER,
                optionState.currentOption
            );

        vaultState.lockedAmount = uint104(
            uint256(vaultState.lockedAmount).sub(unlockedAssetAmount)
        );

        // Wrap entire `asset` balance to `collateralToken` balance
        VaultLifecycleYearn.wrapToYieldToken(
            vaultParams.asset,
            address(collateralToken)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

abstract contract RibbonThetaYearnVaultStorageV1 {
    // Logic contract used to price options
    address public optionsPremiumPricer;
    // Logic contract used to select strike prices
    address public strikeSelection;
    // Premium discount on options we are selling (thousandths place: 000 - 999)
    uint256 public premiumDiscount;
    // Current oToken premium
    uint256 public currentOtokenPremium;
    // Last round id at which the strike was manually overridden
    uint16 public lastStrikeOverrideRound;
    // Price last overridden strike set to
    uint256 public overriddenStrikePrice;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionID;
}

abstract contract RibbonThetaYearnVaultStorageV2 {
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;
}

abstract contract RibbonThetaYearnVaultStorageV3 {
    // LiquidityGauge contract for the vault
    address public liquidityGauge;
}

abstract contract RibbonThetaYearnVaultStorageV4 {
    // OptionsPurchaseQueue contract for selling options
    address public optionsPurchaseQueue;
}

abstract contract RibbonThetaYearnVaultStorageV5 {
    // Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of RibbonThetaVaultStorage
// e.g. RibbonThetaVaultStorage<versionNumber>, so finally it would look like
// contract RibbonThetaVaultStorage is RibbonThetaVaultStorageV1, RibbonThetaVaultStorageV2
abstract contract RibbonThetaYearnVaultStorage is
    RibbonThetaYearnVaultStorageV1,
    RibbonThetaYearnVaultStorageV2,
    RibbonThetaYearnVaultStorageV3,
    RibbonThetaYearnVaultStorageV4,
    RibbonThetaYearnVaultStorageV5
{

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "hardhat/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {ISwap} from "../../interfaces/ISwap.sol";
import {
    PolysynthLeverageVaultStorage
} from "../../storage/PolysynthLeverageVaultStorage.sol";
import {Vault} from "../../libraries/Vault.sol";
import {LeverageVault} from "../../libraries/LeverageVault.sol";
import {
    VaultLifecycleWithSwapAndLeverage
} from "../../libraries/VaultLifecycleWithSwapAndLeverage.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {ILiquidityGauge} from "../../interfaces/ILiquidityGauge.sol";
import {ILiquidity} from "../../interfaces/ILiquidity.sol";
import {PolysynthVault} from "./base/PolysynthVault.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in PolysynthLeverageVaultStorage.
 * PolysynthLeverageVault should not inherit from any other contract aside from PolysynthVault, PolysynthLeverageVaultStorage
 */
contract PolysynthLeverageVaultWithSwap is PolysynthVault, PolysynthLeverageVaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public immutable OTOKEN_FACTORY;

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    /************************************************
     *  EVENTS
     ***********************************************/

    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address indexed manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address indexed manager
    );

    event NewOptionStrikeSelected(uint256 strikePrice, uint256 delta);

    event PremiumDiscountSet(
        uint256 premiumDiscount,
        uint256 newPremiumDiscount
    );

    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event NewOffer(
        uint256 swapId,
        address seller,
        address oToken,
        address biddingToken,
        uint256 minPrice,
        uint256 minBidSize,
        uint256 totalSize
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     * @param _premiumDiscount is the vault's discount applied to the premium
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _optionsPremiumPricer;
        address _strikeSelection;
        address _poolAddress;
        uint32 _premiumDiscount;
    }

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _oTokenFactory is the contract address for minting new opyn option types (strikes, asset, expiry)
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _swapContract is the contract address that facilitates bids settlement
     */
    constructor(
        address _weth,
        address _usdc,
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _swapContract        
    ) PolysynthVault(_weth, _usdc, _gammaController, _marginPool, _swapContract) {
        require(_oTokenFactory != address(0), "!_oTokenFactory");
        OTOKEN_FACTORY = _oTokenFactory;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(
            _initParams._owner,
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _initParams._poolAddress,
            _vaultParams
        );
        // require(
        //     _initParams._optionsPremiumPricer != address(0),
        //     "!_optionsPremiumPricer"
        // );
        // require(
        //     _initParams._strikeSelection != address(0),
        //     "!_strikeSelection"
        // );
        require(
            _initParams._premiumDiscount > 0 &&
                _initParams._premiumDiscount <
                100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "!_premiumDiscount"
        );

        optionsPremiumPricer = _initParams._optionsPremiumPricer;
        strikeSelection = _initParams._strikeSelection;
        premiumDiscount = _initParams._premiumDiscount;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new discount on premiums for options we are selling
     * @param newPremiumDiscount is the premium discount
     */
    // function setPremiumDiscount(uint256 newPremiumDiscount)
    //     external
    //     onlyKeeper
    // {
    //     require(
    //         newPremiumDiscount > 0 &&
    //             newPremiumDiscount <= 100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
    //         "Invalid discount"
    //     );

    //     emit PremiumDiscountSet(premiumDiscount, newPremiumDiscount);

    //     premiumDiscount = newPremiumDiscount;
    // }

    /**
     * @notice Sets the new auction duration
     * @param newAuctionDuration is the auction duration
     */
    // function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
    //     require(
    //         newAuctionDuration >= MIN_AUCTION_DURATION,
    //         "Invalid auction duration"
    //     );

    //     emit AuctionDurationSet(auctionDuration, newAuctionDuration);

    //     auctionDuration = newAuctionDuration;
    // }

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    // function setStrikeSelection(address newStrikeSelection) external onlyOwner {
    //     require(newStrikeSelection != address(0), "!newStrikeSelection");
    //     strikeSelection = newStrikeSelection;
    // }

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    // function setOptionsPremiumPricer(address newOptionsPremiumPricer)
    //     external
    //     onlyOwner
    // {
    //     require(
    //         newOptionsPremiumPricer != address(0),
    //         "!newOptionsPremiumPricer"
    //     );
    //     optionsPremiumPricer = newOptionsPremiumPricer;
    // }

    /**
     * @notice Optionality to set strike price manually
     * Should be called after closeRound if we are setting current week's strike
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external onlyOwner {
        require(strikePrice > 0, "!strikePrice");
        overriddenStrikePrice = strikePrice;
        lastStrikeOverrideRound = vaultState.round;
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    // function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
    //     liquidityGauge = newLiquidityGauge;
    // }

    /**
     * @notice Sets oToken Premium
     * @param minPrice is the new oToken Premium in the units of 10**18
     */
    function setMinPrice(uint256 minPrice) external onlyKeeper {
        require(minPrice > 0, "!minPrice");
        currentOtokenPremium = minPrice;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        _instantWithdraw(amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares.add(
            numShares
        );
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        );
    }

    function initiateRepay(uint256 numShares) external nonReentrant {
        uint256 repayShares = _initiateRepay(numShares);
        currentQueuedRepayShares = currentQueuedRepayShares.add(
            numShares
        );
        borrowState.queuedRepayDebtShares += uint128(repayShares);
    }

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    // function stake(uint256 numShares) external nonReentrant {
    //     address _liquidityGauge = liquidityGauge;
    //     require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
    //     require(numShares > 0);
    //     uint256 heldByAccount = balanceOf(msg.sender);
    //     if (heldByAccount < numShares) {
    //         _redeem(numShares.sub(heldByAccount), false);
    //     }
    //     _transfer(msg.sender, address(this), numShares);
    //     _approve(address(this), _liquidityGauge, numShares);
    //     ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    // }

    /**
     * @notice Closes the existing short and calculate the shares to mint, new price per share &
      amount of funds to re-allocate as collateral for the new round
     * Since we are incrementing the round here, the options are sold in the beginning of a round
     * instead of at the end of the round. For example, at round 1, we don't sell any options. We
     * start selling options at the beginning of round 2.
     */
    function closeRound() external nonReentrant {
        address oldOption = optionState.currentOption;
        require(
            oldOption != address(0) || vaultState.round == 1,
            "Round closed"
        );
        _closeShort(optionState.currentOption);

        uint256 currQueuedWithdrawShares = currentQueuedWithdrawShares;
        uint256 currQueuedRepayShares = currentQueuedRepayShares;
        (uint256 lockedBalance, uint256 queuedWithdrawAmount) =
            _closeRound(
                uint256(lastQueuedWithdrawAmount),
                currQueuedWithdrawShares,
                currQueuedRepayShares
            );

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares).add(
                currQueuedWithdrawShares
            );
        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;
        currentQueuedRepayShares = 0;

        ShareMath.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);

        uint256 nextOptionReady = block.timestamp.add(DELAY);
        require(
            nextOptionReady <= type(uint32).max,
            "Overflow nextOptionReady"
        );
        optionState.nextOptionReadyAt = uint32(nextOptionReady);
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort(address oldOption) private {
        uint256 lockedAmount = vaultState.lockedAmount;
        if (oldOption != address(0)) {
            vaultState.lastLockedAmount = uint104(lockedAmount);
        }
        vaultState.lockedAmount = 0;

        optionState.currentOption = address(0);

        if (oldOption != address(0)) {
            uint256 withdrawAmount =
                VaultLifecycleWithSwapAndLeverage.settleShort(GAMMA_CONTROLLER);
            console.log("withdrawAmount", withdrawAmount);
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
    }

    /**
     * @notice Sets the next option the vault will be shorting
     */
    function commitNextOption() external onlyKeeper nonReentrant {
        address currentOption = optionState.currentOption;
        require(
            currentOption == address(0) && vaultState.round != 1,
            "Round not closed"
        );

        VaultLifecycleWithSwapAndLeverage.CommitParams memory commitParams =
            VaultLifecycleWithSwapAndLeverage.CommitParams({
                OTOKEN_FACTORY: OTOKEN_FACTORY,
                USDC: USDC,
                currentOption: currentOption,
                delay: DELAY,
                lastStrikeOverrideRound: lastStrikeOverrideRound,
                overriddenStrikePrice: overriddenStrikePrice,
                strikeSelection: strikeSelection,
                optionsPremiumPricer: optionsPremiumPricer,
                premiumDiscount: premiumDiscount
            });

        (address otokenAddress, uint256 strikePrice, uint256 delta) =
            VaultLifecycleWithSwapAndLeverage.commitNextOption(
                commitParams,
                vaultParams,
                vaultState
            );

        emit NewOptionStrikeSelected(strikePrice, delta);

        optionState.nextOption = otokenAddress;
    }

    /**
     * @notice Rolls the vault's funds into a new short position and create a new offer.
     */
    function rollToNextOption() external onlyKeeper nonReentrant {
        address newOption = optionState.nextOption;
        require(newOption != address(0), "!nextOption");

        optionState.currentOption = newOption;
        optionState.nextOption = address(0);
        uint256 lockedBalance = vaultState.lockedAmount;

        emit OpenShort(newOption, lockedBalance, msg.sender);

        VaultLifecycleWithSwapAndLeverage.createShort(
            GAMMA_CONTROLLER,
            MARGIN_POOL,
            newOption,
            lockedBalance
        );

        _createOffer();
    }

    /**
     * @notice Create offer in the swap contract.
     */
    // function createOffer() external onlyKeeper nonReentrant {
    //     _createOffer();
    // }

    function _createOffer() private {
        address currentOtoken = optionState.currentOption;
        uint256 currOtokenPremium = currentOtokenPremium;

        optionAuctionID = VaultLifecycleWithSwapAndLeverage.createOffer(
            currentOtoken,
            currOtokenPremium,
            SWAP_CONTRACT,
            vaultParams
        );
    }

    /**
     * @notice Settle current offer
     */
    function settleOffer(ISwap.Bid[] calldata bids)
        external
        onlyKeeper
        nonReentrant
    {
        ISwap(SWAP_CONTRACT).settleOffer(optionAuctionID, bids);
    }

    /**
     * @notice Burn the remaining oTokens left over
     */
    // function burnRemainingOTokens() external onlyKeeper nonReentrant {
    //     uint256 unlockedAssetAmount =
    //         VaultLifecycleWithSwapAndLeverage.burnOtokens(
    //             GAMMA_CONTROLLER,
    //             optionState.currentOption
    //         );

    //     vaultState.lockedAmount = uint104(
    //         uint256(vaultState.lockedAmount).sub(unlockedAssetAmount)
    //     );
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

abstract contract PolysynthLeverageVaultStorageV1 {
    // Logic contract used to price options
    address public optionsPremiumPricer;
    // Logic contract used to select strike prices
    address public strikeSelection;
    // Premium discount on options we are selling (thousandths place: 000 - 999)
    uint256 public premiumDiscount;
    // Current oToken premium
    uint256 public currentOtokenPremium;
    // Last round id at which the strike was manually overridden
    uint16 public lastStrikeOverrideRound;
    // Price last overridden strike set to
    uint256 public overriddenStrikePrice;
    // Auction duration
    uint256 public auctionDuration;
    // Auction id of current option
    uint256 public optionAuctionID;
}

abstract contract PolysynthLeverageVaultStorageV2 {
    // Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;
}

abstract contract PolysynthLeverageVaultStorageV3 {
    // DEPRECATED: Auction will be denominated in USDC if true
    bool private _isUsdcAuction;
    // DEPRECATED: Path for swaps
    bytes private _swapPath;
}

abstract contract PolysynthLeverageVaultStorageV4 {
    // LiquidityGauge contract for the vault
    address public liquidityGauge;
}

abstract contract PolysynthLeverageVaultStorageV5 {
    // OptionsPurchaseQueue contract for selling options
    address public optionsPurchaseQueue;
}

abstract contract PolysynthLeverageVaultStorageV6 {
    // Queued withdraw shares for the current round
    uint256 public currentQueuedWithdrawShares;
}

abstract contract PolysynthLeverageVaultStorageV7 {
    // Queued repay shares for the current round
    uint256 public currentQueuedRepayShares;
    // Amount locked for scheduled repays last week;
    uint256 public lastQueuedRepayAmount;
}
// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of PolysynthLeverageVaultStorage
// e.g. PolysynthLeverageVaultStorage<versionNumber>, so finally it would look like
// contract PolysynthLeverageVaultStorage is PolysynthLeverageVaultStorageV1, PolysynthLeverageVaultStorageV2
abstract contract PolysynthLeverageVaultStorage is
    PolysynthLeverageVaultStorageV1,
    PolysynthLeverageVaultStorageV2,
    PolysynthLeverageVaultStorageV3,
    PolysynthLeverageVaultStorageV4,
    PolysynthLeverageVaultStorageV5,
    PolysynthLeverageVaultStorageV6,
    PolysynthLeverageVaultStorageV7
{

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.4;

library LeverageVault{
    struct BorrowReceipt {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;        
    }


    struct BorrowState {
        // 32 byte slot 1
        //  Current round number. `round` represents the number of `period`s elapsed.
        uint16 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint rTHETA tokens
        uint128 totalPending;
        // Total amount of queued repay shares from current round
        uint128 queuedRepayDebtShares;
        // Total amount of queued repay shares from current round
        uint128 queuedRepayVaultShares;
    }


    struct Repay {
        // Maximum of 65535 rounds. Assuming 1 round is 7 days, maximum is 1256 years.
        uint16 round;
        // Number of shares repaid
        uint128 shares;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "hardhat/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {IStrikeSelection} from "../interfaces/IRibbon.sol";
import {GnosisAuction} from "./GnosisAuction.sol";
import {
    IOtokenFactory,
    IOtoken,
    IController,
    GammaTypes
} from "../interfaces/GammaInterface.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {ISwap} from "../interfaces/ISwap.sol";
import {IOptionsPurchaseQueue} from "../interfaces/IOptionsPurchaseQueue.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";

library VaultLifecycleWithSwapAndLeverage {
    using SafeMath for uint256;
    using SupportsNonCompliantERC20 for IERC20;
    using SafeERC20 for IERC20;

    struct CommitParams {
        address OTOKEN_FACTORY;
        address USDC;
        address currentOption;
        uint256 delay;
        uint16 lastStrikeOverrideRound;
        uint256 overriddenStrikePrice;
        address strikeSelection;
        address optionsPremiumPricer;
        uint256 premiumDiscount;
    }

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param commitParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return otokenAddress is the address of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */
    function commitNextOption(
        CommitParams calldata commitParams,
        Vault.VaultParams storage vaultParams,
        Vault.VaultState storage vaultState
    )
        external
        returns (
            address otokenAddress,
            uint256 strikePrice,
            uint256 delta
        )
    {
        uint256 expiry = getNextExpiry(commitParams.currentOption);

        IStrikeSelection selection =
            IStrikeSelection(commitParams.strikeSelection);

        bool isPut = vaultParams.isPut;
        address underlying = vaultParams.underlying;
        address asset = vaultParams.asset;

        (strikePrice, delta) = commitParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (commitParams.overriddenStrikePrice, selection.delta())
            : selection.getStrikePrice(expiry, isPut);

        require(strikePrice != 0, "!strikePrice");

        // retrieve address if option already exists, or deploy it
        otokenAddress = getOrDeployOtoken(
            commitParams,
            vaultParams,
            underlying,
            asset,
            strikePrice,
            expiry,
            isPut
        );

        return (otokenAddress, strikePrice, delta);
    }

    /**
     * @notice Verify the otoken has the correct parameters to prevent vulnerability to opyn contract changes
     * @param otokenAddress is the address of the otoken
     * @param vaultParams is the struct with vault general data
     * @param collateralAsset is the address of the collateral asset
     * @param USDC is the address of usdc
     * @param delay is the delay between commitAndClose and rollToNextOption
     */
    function verifyOtoken(
        address otokenAddress,
        Vault.VaultParams storage vaultParams,
        address collateralAsset,
        address USDC,
        uint256 delay
    ) private view {
        require(otokenAddress != address(0), "!otokenAddress");

        IOtoken otoken = IOtoken(otokenAddress);
        require(otoken.isPut() == vaultParams.isPut, "Type mismatch");
        require(
            otoken.underlyingAsset() == vaultParams.underlying,
            "Wrong underlyingAsset"
        );
        require(
            otoken.collateralAsset() == collateralAsset,
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        require(otoken.strikeAsset() == USDC, "strikeAsset != USDC");

        uint256 readyAt = block.timestamp.add(delay);
        require(otoken.expiryTimestamp() >= readyAt, "Expiry before delay");
    }

    /**
     * @param decimals is the decimals of the asset
     * @param totalBalance is the vault's total asset balance
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from last round
     * @param performanceFee is the perf fee percent to charge on premiums
     * @param managementFee is the management fee percent to charge on the AUM
     */
    struct CloseParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 performanceFee;
        uint256 managementFee;
        uint256 currentQueuedWithdrawShares;
        uint256 currentQueuedRepayShares;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from RibbonVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return performanceFeeInAsset is the performance fee charged by vault
     * @return totalVaultFee is the total amount of fee charged by vault
     */
    function closeRound(
        Vault.VaultState storage vaultState,
        CloseParams calldata params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 performanceFeeInAsset,
            uint256 totalVaultFee
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        // Total amount of queued withdrawal shares from previous rounds (doesn't include the current round)
        uint256 lastQueuedWithdrawShares = vaultState.queuedWithdrawShares;

        // Deduct older queued withdraws so we don't charge fees on them
        uint256 balanceForVaultFees =
            currentBalance.sub(params.lastQueuedWithdrawAmount);

        {
            (performanceFeeInAsset, , totalVaultFee) = getVaultFees(
                balanceForVaultFees,
                vaultState.lastLockedAmount,
                vaultState.totalPending,
                params.performanceFee,
                params.managementFee
            );
        }

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance.sub(totalVaultFee);

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply.sub(lastQueuedWithdrawShares),
                currentBalance.sub(params.lastQueuedWithdrawAmount),
                pendingAmount,
                params.decimals
            );

            queuedWithdrawAmount = params.lastQueuedWithdrawAmount.add(
                ShareMath.sharesToAsset(
                    params.currentQueuedWithdrawShares,
                    newPricePerShare,
                    params.decimals
                )
            );

            // After closing the short, if the options expire in-the-money
            // vault pricePerShare would go down because vault's asset balance decreased.
            // This ensures that the newly-minted shares do not take on the loss.
            mintShares = ShareMath.assetToShares(
                pendingAmount,
                newPricePerShare,
                params.decimals
            );
        }

        return (
            currentBalance.sub(queuedWithdrawAmount), // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            mintShares,
            performanceFeeInAsset,
            totalVaultFee
        );
    }

    /**
     * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
     * @param gammaController is the address of the opyn controller contract
     * @param marginPool is the address of the opyn margin contract which holds the collateral
     * @param oTokenAddress is the address of the otoken to mint
     * @param depositAmount is the amount of collateral to deposit
     * @return the otoken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address oTokenAddress,
        uint256 depositAmount
    ) external returns (uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID =
            (controller.getAccountVaultCounter(address(this))).add(1);

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IOtoken oToken = IOtoken(oTokenAddress);
        address collateralAsset = oToken.collateralAsset();

        uint256 collateralDecimals =
            uint256(IERC20Detailed(collateralAsset).decimals());
        uint256 mintAmount;

        if (oToken.isPut()) {
            // For minting puts, there will be instances where the full depositAmount will not be used for minting.
            // This is because of an issue with precision.
            //
            // For ETH put options, we are calculating the mintAmount (10**8 decimals) using
            // the depositAmount (10**18 decimals), which will result in truncation of decimals when scaling down.
            // As a result, there will be tiny amounts of dust left behind in the Opyn vault when minting put otokens.
            //
            // For simplicity's sake, we do not refund the dust back to the address(this) on minting otokens.
            // We retain the dust in the vault so the calling contract can withdraw the
            // actual locked amount + dust at settlement.
            //
            // To test this behavior, we can console.log
            // MarginCalculatorInterface(0x7A48d10f372b3D7c60f6c9770B91398e4ccfd3C7).getExcessCollateral(vault)
            // to see how much dust (or excess collateral) is left behind.
            mintAmount = depositAmount
                .mul(10**Vault.OTOKEN_DECIMALS)
                .mul(10**18) // we use 10**18 to give extra precision
                .div(oToken.strikePrice().mul(10**(10 + collateralDecimals)));
        } else {
            mintAmount = depositAmount;

            if (collateralDecimals > 8) {
                uint256 scaleBy = 10**(collateralDecimals.sub(8)); // oTokens have 8 decimals
                if (mintAmount > scaleBy) {
                    mintAmount = depositAmount.div(scaleBy); // scale down from 10**18 to 10**8
                }
            }
        }

        // double approve to fix non-compliant ERC20s
        IERC20 collateralToken = IERC20(collateralAsset);
        collateralToken.safeApproveNonCompliant(marginPool, depositAmount);

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](3);

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oTokenAddress, // option address
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        return mintAmount;
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the opyn controller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(address gammaController) external returns (uint256) {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        // The short position has been previously closed, or all the otokens have been burned.
        // So we return early.
        if (address(collateralToken) == address(0)) {
            return 0;
        }

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultID, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Exercises the ITM option using existing long otoken position. Currently this implementation is simple.
     * It calls the `Redeem` action to claim the payout.
     * @param gammaController is the address of the opyn controller contract
     * @param oldOption is the address of the old option
     * @param asset is the address of the vault's asset
     * @return amount of asset received by exercising the option
     */
    function settleLong(
        address gammaController,
        address oldOption,
        address asset
    ) external returns (uint256) {
        IController controller = IController(gammaController);

        uint256 oldOptionBalance = IERC20(oldOption).balanceOf(address(this));

        if (controller.getPayout(oldOption, oldOptionBalance) == 0) {
            return 0;
        }

        uint256 startAssetBalance = IERC20(asset).balanceOf(address(this));

        // If it is after expiry, we need to redeem the profits
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oldOption, // address of otoken
            0, // not used
            oldOptionBalance, // otoken balance
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endAssetBalance = IERC20(asset).balanceOf(address(this));

        return endAssetBalance.sub(startAssetBalance);
    }

    /**
     * @notice Burn the remaining oTokens left over from auction. Currently this implementation is simple.
     * It burns oTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the opyn controller contract
     * @param currentOption is the address of the current option
     * @return amount of collateral redeemed by burning otokens
     */
    function burnOtokens(address gammaController, address currentOption)
        external
        returns (uint256)
    {
        uint256 numOTokensToBurn =
            IERC20(currentOption).balanceOf(address(this));

        require(numOTokensToBurn > 0, "No oTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // Burning `amount` of oTokens from the ribbon vault,
        // then withdrawing the corresponding collateral amount from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](2);

        actions[0] = IController.ActionArgs(
            IController.ActionType.BurnShortOption,
            address(this), // owner
            address(this), // address to transfer from
            address(vault.shortOtokens[0]), // otoken address
            vaultID, // vaultId
            numOTokensToBurn, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            address(collateralToken), // withdrawn asset
            vaultID, // vaultId
            vault.collateralAmounts[0].mul(numOTokensToBurn).div(
                vault.shortAmounts[0]
            ), // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Calculates the performance and management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param lastLockedAmount is the amount of funds locked from the previous round
     * @param pendingAmount is the pending deposit amount
     * @param performanceFeePercent is the performance fee pct.
     * @param managementFeePercent is the management fee pct.
     * @return performanceFeeInAsset is the performance fee
     * @return managementFeeInAsset is the management fee
     * @return vaultFee is the total fees
     */
    function getVaultFees(
        uint256 currentBalance,
        uint256 lastLockedAmount,
        uint256 pendingAmount,
        uint256 performanceFeePercent,
        uint256 managementFeePercent
    )
        internal
        view
        returns (
            uint256 performanceFeeInAsset,
            uint256 managementFeeInAsset,
            uint256 vaultFee
        )
    {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount
                ? currentBalance.sub(pendingAmount)
                : 0;

        uint256 _performanceFeeInAsset;
        uint256 _managementFeeInAsset;
        uint256 _vaultFee;

        // Take performance fee and management fee ONLY if difference between
        // last week and this week's vault deposits, taking into account pending
        // deposits and withdrawals, is positive. If it is negative, last week's
        // option expired ITM past breakeven, and the vault took a loss so we
        // do not collect performance fee for last week
        if (lockedBalanceSansPending > lastLockedAmount) {
            _performanceFeeInAsset = performanceFeePercent > 0
                ? lockedBalanceSansPending
                    .sub(lastLockedAmount)
                    .mul(performanceFeePercent)
                    .div(100 * Vault.FEE_MULTIPLIER)
                : 0;
            _managementFeeInAsset = managementFeePercent > 0
                ? lockedBalanceSansPending.mul(managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            _vaultFee = _performanceFeeInAsset.add(_managementFeeInAsset);
            console.log("_managementFeeInAsset", _managementFeeInAsset, lastLockedAmount, Vault.FEE_MULTIPLIER);
            console.log("lockedBalanceSansPending", lockedBalanceSansPending, _performanceFeeInAsset, managementFeePercent);
        } else {            
            _managementFeeInAsset = managementFeePercent > 0
                ? lastLockedAmount.mul(managementFeePercent).div(
                    100 * Vault.FEE_MULTIPLIER
                )
                : 0;

            console.log("_managementFeeInAsset", _managementFeeInAsset, lastLockedAmount, Vault.FEE_MULTIPLIER);
            _vaultFee = _managementFeeInAsset;
        }

        return (_performanceFeeInAsset, _managementFeeInAsset, _vaultFee);
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param commitParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param underlying is the address of the underlying asset of the option
     * @param collateralAsset is the address of the collateral asset of the option
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @param isPut is whether the option is a put
     * @return the address of the option
     */
    function getOrDeployOtoken(
        CommitParams calldata commitParams,
        Vault.VaultParams storage vaultParams,
        address underlying,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) internal returns (address) {
        IOtokenFactory factory = IOtokenFactory(commitParams.OTOKEN_FACTORY);

        address otokenFromFactory =
            factory.getOtoken(
                underlying,
                commitParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        if (otokenFromFactory != address(0)) {
            return otokenFromFactory;
        }

        address otoken =
            factory.createOtoken(
                underlying,
                commitParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        verifyOtoken(
            otoken,
            vaultParams,
            collateralAsset,
            commitParams.USDC,
            commitParams.delay
        );

        return otoken;
    }

    function getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) external view returns (uint256) {
        return
            _getOTokenPremium(
                oTokenAddress,
                optionsPremiumPricer,
                premiumDiscount
            );
    }

    function _getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer =
            IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium =
            premiumPricer.getPremium(
                newOToken.strikePrice(),
                newOToken.expiryTimestamp(),
                newOToken.isPut()
            );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(
            100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER
        );

        require(
            optionPremium <= type(uint96).max,
            "optionPremium > type(uint96) max value!"
        );
        require(optionPremium > 0, "!optionPremium");

        return optionPremium;
    }

    /**
     * @notice Creates an offer in the Swap Contract
     * @param currentOtoken is the current otoken address
     * @param currOtokenPremium is premium for each otoken
     * @param swapContract the address of the swap contract
     * @param vaultParams is the struct with vault general data
     * @return optionAuctionID auction id of the newly created offer
     */
    function createOffer(
        address currentOtoken,
        uint256 currOtokenPremium,
        address swapContract,
        Vault.VaultParams storage vaultParams
    ) external returns (uint256 optionAuctionID) {
        require(
            currOtokenPremium <= type(uint96).max,
            "currentOtokenPremium > type(uint96) max value!"
        );
        require(currOtokenPremium > 0, "!currentOtokenPremium");

        uint256 oTokenBalance = IERC20(currentOtoken).balanceOf(address(this));
        require(
            oTokenBalance <= type(uint128).max,
            "oTokenBalance > type(uint128) max value!"
        );

        // Use safeIncrease instead of safeApproval because safeApproval is only used for initial
        // approval and cannot be called again. Using safeIncrease allow us to call _createOffer
        // even when we are approving the same oTokens we have used before. This might happen if
        // we accidentally burn the oTokens before settlement.
        uint256 allowance =
            IERC20(currentOtoken).allowance(address(this), swapContract);

        if (allowance < oTokenBalance) {
            IERC20(currentOtoken).safeIncreaseAllowance(
                swapContract,
                oTokenBalance.sub(allowance)
            );
        }

        uint256 decimals = vaultParams.decimals;

        // If total size is larger than 1, set minimum bid as 1
        // Otherwise, set minimum bid to one tenth the total size
        uint256 minBidSize =
            oTokenBalance > 10**decimals ? 10**decimals : oTokenBalance.div(10);

        require(
            minBidSize <= type(uint96).max,
            "minBidSize > type(uint96) max value!"
        );

        currOtokenPremium = decimals > 18
            ? currOtokenPremium.mul(10**(decimals.sub(18)))
            : currOtokenPremium.div(10**(uint256(18).sub(decimals)));

        optionAuctionID = ISwap(swapContract).createOffer(
            currentOtoken,
            vaultParams.asset,
            uint96(currOtokenPremium),
            uint96(minBidSize),
            uint128(oTokenBalance)
        );
    }

    /**
     * @notice Allocates the vault's minted options to the OptionsPurchaseQueue contract
     * @dev Skipped if the optionsPurchaseQueue doesn't exist
     * @param optionsPurchaseQueue is the OptionsPurchaseQueue contract
     * @param option is the minted option
     * @param optionsAmount is the amount of options minted
     * @param optionAllocation is the maximum % of options to allocate towards the purchase queue (will only allocate
     *  up to the amount that is on the queue)
     * @return allocatedOptions is the amount of options that ended up getting allocated to the OptionsPurchaseQueue
     */
    function allocateOptions(
        address optionsPurchaseQueue,
        address option,
        uint256 optionsAmount,
        uint256 optionAllocation
    ) external returns (uint256 allocatedOptions) {
        // Skip if optionsPurchaseQueue is address(0)
        if (optionsPurchaseQueue != address(0)) {
            allocatedOptions = optionsAmount.mul(optionAllocation).div(
                100 * Vault.OPTION_ALLOCATION_MULTIPLIER
            );
            allocatedOptions = IOptionsPurchaseQueue(optionsPurchaseQueue)
                .getOptionsAllocation(address(this), allocatedOptions);

            if (allocatedOptions != 0) {
                IERC20(option).approve(optionsPurchaseQueue, allocatedOptions);
                IOptionsPurchaseQueue(optionsPurchaseQueue).allocateOptions(
                    allocatedOptions
                );
            }
        }

        return allocatedOptions;
    }

    /**
     * @notice Sell the allocated options to the purchase queue post auction settlement
     * @dev Reverts if the auction hasn't settled yet
     * @param optionsPurchaseQueue is the OptionsPurchaseQueue contract
     * @param swapContract The address of the swap settlement contract
     * @return totalPremiums Total premiums earnt by the vault
     */
    function sellOptionsToQueue(
        address optionsPurchaseQueue,
        address swapContract,
        uint256 optionAuctionID
    ) external returns (uint256) {
        uint256 settlementPrice =
            getAuctionSettlementPrice(swapContract, optionAuctionID);
        require(settlementPrice != 0, "!settlementPrice");

        return
            IOptionsPurchaseQueue(optionsPurchaseQueue).sellToBuyers(
                settlementPrice
            );
    }

    /**
     * @notice Gets the settlement price of a settled auction
     * @param swapContract The address of the swap settlement contract
     * @param optionAuctionID is the offer ID
     * @return settlementPrice Auction settlement price
     */
    function getAuctionSettlementPrice(
        address swapContract,
        uint256 optionAuctionID
    ) public view returns (uint256) {
        return ISwap(swapContract).averagePriceForOffer(optionAuctionID);
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param owner is the owner of the vault with critical permissions
     * @param feeRecipient is the address to recieve vault performance and management fees
     * @param performanceFee is the perfomance fee pct.
     * @param tokenName is the name of the token
     * @param tokenSymbol is the symbol of the token
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        address owner,
        address keeper,
        address feeRecipient,
        uint256 performanceFee,
        uint256 managementFee,
        string calldata tokenName,
        string calldata tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) external pure {
        require(owner != address(0), "!owner");
        require(keeper != address(0), "!keeper");
        require(feeRecipient != address(0), "!feeRecipient");
        require(
            performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "performanceFee >= 100%"
        );
        require(
            managementFee < 100 * Vault.FEE_MULTIPLIER,
            "managementFee >= 100%"
        );
        require(bytes(tokenName).length > 0, "!tokenName");
        require(bytes(tokenSymbol).length > 0, "!tokenSymbol");

        require(_vaultParams.asset != address(0), "!asset");
        require(_vaultParams.underlying != address(0), "!underlying");
        require(_vaultParams.minimumSupply > 0, "!minimumSupply");
        require(_vaultParams.cap > 0, "!cap");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Gets the next option expiry timestamp
     * @param currentOption is the otoken address that the vault is currently writing
     */
    function getNextExpiry(address currentOption)
        internal
        view
        returns (uint256)
    {
        // uninitialized state
        if (currentOption == address(0)) {
            return getNextFriday(block.timestamp);
        }
        uint256 currentExpiry = IOtoken(currentOption).expiryTimestamp();

        // After options expiry if no options are written for >1 week
        // We need to give the ability continue writing options
        if (block.timestamp > currentExpiry + 7 days) {
            return getNextFriday(block.timestamp);
        }
        return getNextFriday(currentExpiry);
    }

    /**
     * @notice Gets the next options expiry timestamp
     * @param timestamp is the expiry timestamp of the current option
     * Reference: https://codereview.stackexchange.com/a/33532
     * Examples:
     * getNextFriday(week 1 thursday) -> week 1 friday
     * getNextFriday(week 1 friday) -> week 2 friday
     * getNextFriday(week 1 saturday) -> week 2 friday
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        // dayOfWeek = 0 (sunday) - 6 (saturday)
        uint256 dayOfWeek = ((timestamp / 1 days) + 4) % 7;
        uint256 nextFriday = timestamp + ((7 + 5 - dayOfWeek) % 7) * 1 days;
        uint256 friday8am = nextFriday - (nextFriday % (24 hours)) + (8 hours);

        // If the passed timestamp is day=Friday hour>8am, we simply increment it by a week to next Friday
        if (timestamp >= friday8am) {
            friday8am += 7 days;
        }
        return friday8am;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "hardhat/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Vault} from "../../../libraries/Vault.sol";
import {AuxVault} from "../../../libraries/AuxVault.sol";
import {LeverageVault} from "../../../libraries/LeverageVault.sol";
import {
    VaultLifecycleWithSwapAndLeverage
} from "../../../libraries/VaultLifecycleWithSwapAndLeverage.sol";
import {ShareMath} from "../../../libraries/ShareMath.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";
import {ILiquidity} from "../../../interfaces/ILiquidity.sol";
import {MathUtils} from "../../../utils/MathUtils.sol";

contract PolysynthVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice Stores the user's pending borrow for the round
    mapping(address => LeverageVault.BorrowReceipt) public borrowReceipts;

    /// @notice Stores the user's debt shares
    mapping(address => uint256) public userDebtShares;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    // mapping(address => LeverageVault.Repay) public repays;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's lifecycle state like round and locked amounts
    LeverageVault.BorrowState public borrowState;

    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    // /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    // uint256 public depositFee;

    // /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    // uint256 public withdrawalFee;

    // Gap is left to avoid storage collisions. Though PolysynthVault is not upgradeable, we add this as a safety measure.
    uint256[30] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to PolysynthThetaVaultStorage
    // or PolysynthDeltaVaultStorage instead. Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public immutable USDC;

    /// @notice Deprecated: 15 minute timelock between commitAndClose and rollToNexOption.
    uint256 public constant DELAY = 0;

    /// @notice 7 day period between each options sale.
    // uint256 public constant PERIOD = 7 days;

    /// @notice Initial margin ratio on scale of 10**6
    uint256 public constant INITIAL_MARGIN_RATIO = 200000;

    // Number of weeks per year = 52.142857 weeks * FEE_MULTIPLIER = 52142857
    // Dividing by weeks per year requires doing num.mul(FEE_MULTIPLIER).div(WEEKS_PER_YEAR)
    uint256 private constant WEEKS_PER_YEAR = 52142857;

    // GAMMA_CONTROLLER is the top-level contract in Gamma protocol
    // which allows users to perform multiple actions on their vaults
    // and positions https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/Controller.sol
    address public immutable GAMMA_CONTROLLER;

    // MARGIN_POOL is Gamma protocol's collateral pool.
    // Needed to approve collateral.safeTransferFrom for minting otokens.
    // https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/MarginPool.sol
    address public immutable MARGIN_POOL;

    // SWAP_CONTRACT is a contract for settling bids via signed messages
    // https://github.com/Polysynth-finance/Polysynth-v2/blob/master/contracts/utils/Swap.sol
    address public immutable SWAP_CONTRACT;

    // LIQUIDITY_POOL is a contract from where vault gets leveraged amount    
    address public LIQUIDITY_POOL;

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint8 leverage, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event InitiateRepay(
        address indexed account,
        uint256 shares,
        uint256 scaledShares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event DepositFeeSet(uint256 depositFee, uint256 newDepositFee);

    event WithdrawalFeeSet(uint256 withdrawalFee, uint256 newwithdrawalFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );


    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _swapContract is the contract address that facilitates bids settlement
     */
    constructor(
        address _weth,
        address _usdc,
        address _gammaController,
        address _marginPool,
        address _swapContract        
    ) {
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_swapContract != address(0), "!_swapContract");
        require(_gammaController != address(0), "!_gammaController");
        require(_marginPool != address(0), "!_marginPool");

        WETH = _weth;
        USDC = _usdc;
        GAMMA_CONTROLLER = _gammaController;
        MARGIN_POOL = _marginPool;
        SWAP_CONTRACT = _swapContract;        
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     */
    function baseInitialize(
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        address _poolAddress,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        VaultLifecycleWithSwapAndLeverage.verifyInitializerParams(
            _owner,
            _keeper,
            _feeRecipient,
            _performanceFee,
            _managementFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        keeper = _keeper;
        LIQUIDITY_POOL = _poolAddress;

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee.mul(Vault.FEE_MULTIPLIER).div(
            WEEKS_PER_YEAR
        );
        vaultParams = _vaultParams;

        uint256 assetBalance =
            IERC20(vaultParams.asset).balanceOf(address(this));
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    // function setNewKeeper(address newKeeper) external onlyOwner {
    //     require(newKeeper != address(0), "!newKeeper");
    //     keeper = newKeeper;
    // }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    // function setFeeRecipient(address newFeeRecipient) external onlyOwner {
    //     require(newFeeRecipient != address(0), "!newFeeRecipient");
    //     require(newFeeRecipient != feeRecipient, "Must be new feeRecipient");
    //     feeRecipient = newFeeRecipient;
    // }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    // function setManagementFee(uint256 newManagementFee) external onlyOwner {
    //     require(
    //         newManagementFee < 100 * Vault.FEE_MULTIPLIER,
    //         "Invalid management fee"
    //     );

    //     // We are dividing annualized management fee by num weeks in a year
    //     uint256 tmpManagementFee =
    //         newManagementFee.mul(Vault.FEE_MULTIPLIER).div(WEEKS_PER_YEAR);

    //     emit ManagementFeeSet(managementFee, newManagementFee);

    //     managementFee = tmpManagementFee;
    // }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    // function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
    //     require(
    //         newPerformanceFee < 100 * Vault.FEE_MULTIPLIER,
    //         "Invalid performance fee"
    //     );

    //     emit PerformanceFeeSet(performanceFee, newPerformanceFee);

    //     performanceFee = newPerformanceFee;
    // }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /**
     * @notice Sets the deposit fee for the vault
     * @param newDepositFee is the deposit fee (6 decimals). ex: 0.1 * 10 ** 6 = 0.1%
     */
    // function setDepositFee(uint256 newDepositFee) external onlyOwner {
    //     require(
    //         newDepositFee < 100 * Vault.FEE_MULTIPLIER,
    //         "Invalid deposit fee"
    //     );

    //     emit DepositFeeSet(depositFee, newDepositFee);

    //     depositFee = newDepositFee;
    // }

    /**
     * @notice Sets the withdrawal fee for the vault
     * @param newWithdrawalFee is the withdrawal fee (6 decimals). ex: 0.1 * 10 ** 6 = 0.1%
     */
    // function setWithdrawalFee(uint256 newWithdrawalFee) external onlyOwner {
    //     require(
    //         newWithdrawalFee < 100 * Vault.FEE_MULTIPLIER,
    //         "Invalid withdrawal fee"
    //     );

    //     emit DepositFeeSet(withdrawalFee, newWithdrawalFee);

    //     withdrawalFee = newWithdrawalFee;
    // }


    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the asset is not WETH.
     */
    function depositETH(uint8 leverage) external payable nonReentrant {
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, leverage, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount, uint8 leverage) external nonReentrant {
        require(amount > 0, "!amount");

        // Create debt receipt
        _depositFor(amount, leverage, msg.sender);

        // if (depositFee>0){
        //     uint256 fee = amount.mul(depositFee).div(100 * Vault.FEE_MULTIPLIER);
        //     amount += fee;
        // }

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    // function depositFor(uint256 amount,uint8 leverage, address creditor)
    //     external
    //     nonReentrant
    // {
    //     require(amount > 0, "!amount");
    //     require(creditor != address(0));

    //     _depositFor(amount, leverage, creditor);

    //     // An approve() by the msg.sender is required beforehand
    //     IERC20(vaultParams.asset).safeTransferFrom(
    //         msg.sender,
    //         address(this),
    //         amount
    //     );
    // }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, uint8 leverage, address creditor) private {
        uint256 currentRound = vaultState.round;
        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];
        LeverageVault.BorrowReceipt memory borrowReceipt = borrowReceipts[creditor];

        (uint256 depositAmount, uint256 borrowAmount, uint256 unredeemedShares) = AuxVault.deposit(AuxVault.DepositParams(
            LIQUIDITY_POOL,
            amount,
            leverage,
            totalBalance(),
            uint16(currentRound),
            roundPricePerShare[depositReceipt.round],
            borrowReceipt.amount,
            depositReceipt
        ), vaultParams);

        // uint256 totalWithDepositedAmount = totalBalance().add(amount);

        // require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        // require(
        //     totalWithDepositedAmount >= vaultParams.minimumSupply,
        //     "Insufficient balance"
        // );


        // // Get available borrow limit from pool
        ILiquidity pool = ILiquidity(LIQUIDITY_POOL);
        // uint256 borrowLimit = pool.availableBorrowLimit();
        // require(borrowLimit>=amount.mul(leverage-1), "not enough to borrow");

        emit Deposit(creditor, amount, leverage, currentRound);

        // Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];
        // LeverageVault.BorrowReceipt memory borrowReceipt = borrowReceipts[creditor];

        // // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        // uint256 unredeemedShares =
        //     depositReceipt.getSharesFromReceipt(
        //         currentRound,
        //         roundPricePerShare[depositReceipt.round],
        //         vaultParams.decimals
        //     );

        // uint256 depositAmount = amount.mul(leverage);
        // uint256 borrowAmount = amount.mul(leverage-1);

        // // If we have a pending deposit in the current round, we add on to the pending deposit
        // if (currentRound == depositReceipt.round) {
        //     uint256 newAmount = uint256(depositReceipt.amount).add(depositAmount);
        //     depositAmount = newAmount;
        //     borrowAmount = uint256(borrowReceipt.amount).add(borrowAmount);
        // }

        // ShareMath.assertUint104(depositAmount);
        // ShareMath.assertUint104(borrowAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        borrowReceipts[creditor] = LeverageVault.BorrowReceipt({
            round: pool.currentRound(),
            amount: uint104(borrowAmount)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(depositAmount);
        ShareMath.assertUint128(newTotalPending);

        uint256 newTotalPendingBorrow = uint256(borrowState.totalPending).add(borrowAmount);
        ShareMath.assertUint128(newTotalPendingBorrow);

        vaultState.totalPending = uint128(newTotalPending);
        borrowState.totalPending = uint128(newTotalPendingBorrow);
        // Notify LP Pool of the total amount to lock for this vault
        pool.lockAmount(borrowAmount);
    }


    function _instantWithdraw(uint256 amount) internal {
        Vault.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];

        LeverageVault.BorrowReceipt storage borrowReceipt =
            borrowReceipts[msg.sender];

        uint256 currentLeverage;

        (depositReceipt.amount,vaultState.totalPending,borrowReceipt.amount,borrowState.totalPending, currentLeverage) = AuxVault.instantWithdraw(
            AuxVault.InstantWithdrawParams(
                amount,
                depositReceipt.amount,
                borrowReceipt.amount,
                depositReceipt.round,
                vaultState.round,
                vaultState.totalPending,
                borrowState.totalPending
            )
        );

        // uint256 currentRound = vaultState.round;
        // require(amount > 0, "!amount");
        // require(depositReceipt.round == currentRound, "Invalid round");

        // uint256 receiptAmount = depositReceipt.amount - borrowReceipt.amount;
        // uint256 currentLeverage = uint256(depositReceipt.amount).mul(10**2).div(receiptAmount);
        // require(receiptAmount >= amount, "Exceed amount");

        // // Subtraction underflow checks already ensure it is smaller than uint104
        // depositReceipt.amount = uint104(depositReceipt.amount - amount.mul(currentLeverage).div(10**2));
        // vaultState.totalPending = uint128(
        //     uint256(vaultState.totalPending).sub(amount.mul(currentLeverage).div(10**2))
        // );

        // borrowReceipt.amount = uint104(borrowReceipt.amount - amount.mul(currentLeverage-10**2).div(10**2));
        // borrowState.totalPending = uint128(
        //     uint256(borrowState.totalPending).sub(amount.mul(currentLeverage-10**2).div(10**2))
        // );

        ILiquidity pool = ILiquidity(LIQUIDITY_POOL);
        pool.unlockAmount(amount.mul(currentLeverage-10**2).div(10**2));

        emit InstantWithdraw(msg.sender, amount, vaultState.round);

        transferAsset(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }
        
        ShareMath.assertUint128(withdrawalShares);
        require(accountMarginRatio(msg.sender, withdrawalShares)>=INITIAL_MARGIN_RATIO, "low margin ratio");

        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    function _initiateRepay(uint256 numShares) internal returns (uint256){
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        // uint256 currentRound = vaultState.round;
        // LeverageVault.Repay storage repay = repays[msg.sender];        

        // ILiquidity pool = ILiquidity(LIQUIDITY_POOL);
        // (uint256 dps, ) = pool.pricePerShares(pool.currentRound()-1);

        uint256 scaledRepayShares = AuxVault.initiateRepay(
            AuxVault.InitiateRepayParams(
                LIQUIDITY_POOL,
                numShares,
                roundPricePerShare[vaultState.round-1],
                vaultParams.decimals,
                userDebtShares[msg.sender]
            )
        );

        // bool repayIsSameRound = repay.round == currentRound;

        emit InitiateRepay(msg.sender, numShares, scaledRepayShares, vaultState.round);

        // uint256 existingShares = uint256(repay.shares);   
        
        // uint256 repayShares;
        // if (repayIsSameRound) {
        //     repayShares = existingShares.add(numShares);
        // } else {
        //     // require(existingShares == 0, "Existing repay");
        //     repayShares = numShares;
        //     repays[msg.sender].round = uint16(currentRound);
        // }

        // ShareMath.assertUint128(repayShares);

        // require(accountMarginRatio(msg.sender, withdrawalShares)>=INITIAL_MARGIN_RATIO, "low margin ratio");
        
        // repays[msg.sender].shares = uint128(scaledRepayshares);
        userDebtShares[msg.sender] -= scaledRepayShares;

        _transfer(msg.sender, address(this), numShares);

        return scaledRepayShares;
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMath.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        require(withdrawAmount > 0, "!withdrawAmount");

        // if(withdrawalFee>0){
        //     uint256 fee = withdrawAmount.mul(withdrawalFee).div(100 * Vault.FEE_MULTIPLIER);
        //     withdrawAmount -= fee;
        // }

        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Vault.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];
        LeverageVault.BorrowReceipt memory borrowReceipt =
            borrowReceipts[msg.sender];
        uint256 currentRound = vaultState.round;

        (uint256 nShares, uint256 newDebtShares, uint256 unredeemedShares) = AuxVault.redeem(
            AuxVault.RedeemParams(
                LIQUIDITY_POOL,
                numShares,
                isMax,
                uint16(currentRound),
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals,
                depositReceipt,
                borrowReceipt
            )
        );
        if (nShares == 0) {
            return;
        }
        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        

        // uint256 unredeemedShares =
        //     depositReceipt.getSharesFromReceipt(
        //         currentRound,
        //         roundPricePerShare[depositReceipt.round],
        //         vaultParams.decimals
        //     );

        // ILiquidity pool = ILiquidity(LIQUIDITY_POOL);
        // (uint256 dps,) = pool.pricePerShares(borrowReceipt.round);
        // uint256 newDebtShares = uint256(borrowReceipt.amount).mul(MathUtils.ray()).div(dps);

        userDebtShares[msg.sender] += newDebtShares;

        // numShares = isMax ? unredeemedShares : numShares;
        // if (numShares == 0) {
        //     return;
        // }
        // require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
            borrowReceipts[msg.sender].amount = 0;
        }

        // ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(nShares)
        );

        emit Redeem(msg.sender, nShares, depositReceipt.round);

        _transfer(address(this), msg.sender, nShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Helper function that helps to save gas for writing values into the roundPricePerShare map.
     *         Writing `1` into the map makes subsequent writes warm, reducing the gas from 20k to 5k.
     *         Having 1 initialized beforehand will not be an issue as long as we round down share calculations to 0.
     * @param numRounds is the number of rounds to initialize in the map
     */
    // function initRounds(uint256 numRounds) external nonReentrant {
    //     require(numRounds > 0, "!numRounds");

    //     uint256 _round = vaultState.round;
    //     for (uint256 i = 0; i < numRounds; i++) {
    //         uint256 index = _round + i;
    //         require(roundPricePerShare[index] == 0, "Initialized"); // AVOID OVERWRITING ACTUAL VALUES
    //         roundPricePerShare[index] = ShareMath.PLACEHOLDER_UINT;
    //     }
    // }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as minting new shares, getting vault fees, etc.
     * @param lastQueuedWithdrawAmount is old queued withdraw amount
     * @param currentQueuedWithdrawShares is the queued withdraw shares for the current round
     * @return lockedBalance is the new balance used to calculate next option purchase size or collateral size
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _closeRound(
        uint256 lastQueuedWithdrawAmount,
        uint256 currentQueuedWithdrawShares,
        uint256 currentQueuedRepayShares
    ) internal returns (uint256 lockedBalance, uint256 queuedWithdrawAmount) {
        address recipient = feeRecipient;
        uint256 mintShares;
        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;

        {
            uint256 newPricePerShare;
            (
                lockedBalance,
                queuedWithdrawAmount,
                newPricePerShare,
                mintShares,
                performanceFeeInAsset,
                totalVaultFee
            ) = VaultLifecycleWithSwapAndLeverage.closeRound(
                vaultState,
                VaultLifecycleWithSwapAndLeverage.CloseParams(
                    vaultParams.decimals,
                    IERC20(vaultParams.asset).balanceOf(address(this)),
                    totalSupply(),
                    lastQueuedWithdrawAmount,
                    performanceFee,
                    managementFee,
                    currentQueuedWithdrawShares,
                    currentQueuedRepayShares
                )
            );

            // Finalize the pricePerShare at the end of the round
            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            emit CollectVaultFees(
                performanceFeeInAsset,
                totalVaultFee,
                currentRound,
                recipient
            );
        }

        {
            ILiquidity pool = ILiquidity(LIQUIDITY_POOL);
            
            (uint256 newDebtShares, uint256 amountToRepay) = AuxVault.debtCalculation(
                AuxVault.DebtCalcParams(
                    LIQUIDITY_POOL,
                    borrowState.totalPending,
                    roundPricePerShare[vaultState.round-1],
                    currentQueuedRepayShares,
                    vaultParams.decimals
                )
            );
            
            if (amountToRepay>0) {                 
                IERC20(vaultParams.asset).safeTransfer(LIQUIDITY_POOL, amountToRepay);
            }

            pool.borrow(uint256(borrowState.totalPending), amountToRepay, newDebtShares, borrowState.queuedRepayDebtShares);            
        }

        lockedBalance += borrowState.totalPending;
        vaultState.totalPending = 0;
        borrowState.totalPending = 0;
        vaultState.round = uint16(vaultState.round + 1);

        // Burn repay shares and transfer amount to LP Pool
        _burn(address(this), currentQueuedRepayShares);
        _mint(address(this), mintShares);
        
        if (totalVaultFee > 0) {
            transferAsset(payable(recipient), totalVaultFee);
        } 

        return (lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        if (asset == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                _decimals
            );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    function accountMarginRatio(address account, uint256 withdrawalShares) public view returns(uint256) {
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
        return AuxVault.accountMarginRatio(
            AuxVault.MarginRatioParams(
                LIQUIDITY_POOL,
                assetPerShare,
                debtShares(account),
                shares(account),
                withdrawalShares,
                vaultParams.decimals
            )
        );
        // Get DPS from pool
        // ILiquidity pool = ILiquidity(LIQUIDITY_POOL);
        // (uint256 dps, )= pool.pricePerShares(0);
        // uint256 marginRatio;
        // uint256 _decimals = vaultParams.decimals;        
        // uint256 assetPerShare =
        //     ShareMath.pricePerShare(
        //         totalSupply(),
        //         totalBalance(),
        //         vaultState.totalPending,
        //         _decimals
        //     );
        // uint256 currDebtShares = debtShares(account);
        
        // {
        //     uint256 currShares = shares(account);
        //     uint256 currentDebtValue = currDebtShares.mul(dps).div(MathUtils.ray());
        //     uint256 currentValue = currShares == 0 || withdrawalShares>currShares ? 0 : ShareMath.sharesToAsset(currShares.sub(withdrawalShares), assetPerShare, _decimals);            
        //     uint256 nume = currentValue == 0 || currentDebtValue>currentValue? 0 : currentValue.sub(currentDebtValue);
        //     marginRatio = nume == 0 ? 0 : nume.mul(10**6).div(currentValue);            
        // }

        // return marginRatio;
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }

    function debtShares(address account) public view returns(uint256) {
        LeverageVault.BorrowReceipt memory borrowReceipt = borrowReceipts[account];

        return AuxVault.debtShares(
            AuxVault.DebtSharesParams(
                LIQUIDITY_POOL,
                borrowReceipt.amount,
                borrowReceipt.round,
                userDebtShares[account]
            )
        );
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        // After calling closeRound, current option is set to none
        // We also commit the lockedAmount but do not deposit into Opyn
        // which results in double counting of asset balance and lockedAmount

        return
            optionState.currentOption != address(0)
                ? uint256(vaultState.lockedAmount).add(
                    IERC20(vaultParams.asset).balanceOf(address(this))
                )
                : IERC20(vaultParams.asset).balanceOf(address(this));
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    // function cap() external view returns (uint256) {
    //     return vaultParams.cap;
    // }

    // function nextOptionReadyAt() external view returns (uint256) {
    //     return optionState.nextOptionReadyAt;
    // }

    // function currentOption() external view returns (address) {
    //     return optionState.currentOption;
    // }

    // function nextOption() external view returns (address) {
    //     return optionState.nextOption;
    // }

    // function totalPending() external view returns (uint256) {
    //     return vaultState.totalPending;
    // }

    // function borrowPending() external view returns (uint256) {
    //     return borrowState.totalPending;
    // }

     function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal virtual override
    {
        require(_onlyVault(from, to), "Polysynth: invalid sender");

        super._beforeTokenTransfer(from, to, amount); 
    }

    function _onlyVault(address from, address to) private view returns (bool) {
        return from==address(this) || from==address(0) || to == address(this);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "hardhat/console.sol";

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ILiquidity} from "../interfaces/ILiquidity.sol";
import {ShareMath} from "./ShareMath.sol";
import {Vault} from "./Vault.sol";
import {LeverageVault} from "./LeverageVault.sol";

library AuxVault{
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    uint256 internal constant RAY = 1e27;

    struct MarginRatioParams {
        address LIQUIDITY_POOL;
        uint256 assetPerShare;
        uint256 currDebtShares;
        uint256 currVaultShares;
        uint256 withdrawalShares;
        uint256 decimals;
    }
    function accountMarginRatio(MarginRatioParams calldata mrp) public view returns(uint256) {        
        // Get DPS from pool
        ILiquidity pool = ILiquidity(mrp.LIQUIDITY_POOL);
        (uint256 dps, )= pool.pricePerShares(0);
        uint256 marginRatio;        
                
        uint256 currentDebtValue = mrp.currDebtShares.mul(dps).div(RAY);

        if (mrp.currVaultShares < mrp.withdrawalShares) return 0;

        uint256 currentValue = ShareMath.sharesToAsset(mrp.currVaultShares.sub(mrp.withdrawalShares), mrp.assetPerShare, mrp.decimals);            
        uint256 nume = currentValue == 0 || currentDebtValue>currentValue? 0 : currentValue.sub(currentDebtValue);
        marginRatio = nume == 0 ? 0 : nume.mul(10**6).div(currentValue);

        return marginRatio;
    }

    struct DebtSharesParams {
        address LIQUIDITY_POOL;
        uint104 borrowAmount;
        uint16 borrowRound;        
        uint256 currentDebtShares;
    }

    function debtShares(DebtSharesParams calldata dsp) public view returns(uint256){
        ILiquidity pool = ILiquidity(dsp.LIQUIDITY_POOL);
        (uint256 dps, )= pool.pricePerShares(0);

        if (pool.currentRound()>dsp.borrowRound){
            uint256 newDebtShares = uint256(dsp.borrowAmount).mul(RAY).div(dps);

            return newDebtShares.add(dsp.currentDebtShares);
        }

        return dsp.currentDebtShares;
    }

    struct DebtCalcParams {
        address LIQUIDITY_POOL;
        uint256 totalPending;
        uint256 assetPerShare;
        uint256 repayShares;
        uint256 decimals;
    }

    function debtCalculation(DebtCalcParams calldata dcp) public view returns(uint256, uint256) {
        ILiquidity pool = ILiquidity(dcp.LIQUIDITY_POOL);
        (uint256 dps, ) = pool.pricePerShares(pool.currentRound()-1);
        
        uint256 newDebtShares = uint256(dcp.totalPending).mul(RAY).div(dps);

        uint256 amountToRepay = dcp.assetPerShare== 0 ? 0: ShareMath.sharesToAsset(
            dcp.repayShares,
            dcp.assetPerShare,
            dcp.decimals);

        return (newDebtShares, amountToRepay);
    }

    struct DepositParams{
        address LIQUIDITY_POOL;
        uint256 amount;
        uint8 leverage;
        uint256 totalBalance;
        uint16 currentRound;
        uint256 assetPerShare;
        uint256 prevBorrowAmount;
        Vault.DepositReceipt dr;
    }

    function deposit(DepositParams calldata dp, Vault.VaultParams storage vaultParams) public view returns(uint256, uint256, uint256) {
        uint256 totalWithDepositedAmount = dp.totalBalance.add(dp.amount);
        console.log("--------------------- dep", totalWithDepositedAmount, vaultParams.cap);
        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        // require(
        //     totalWithDepositedAmount >= vaultParams.minimumSupply,
        //     "Insufficient balance"
        // );


        // Get available borrow limit from pool
        ILiquidity pool = ILiquidity(dp.LIQUIDITY_POOL);
        uint256 borrowLimit = pool.availableBorrowLimit();
        require(borrowLimit>=dp.amount.mul(dp.leverage-1), "not enough to borrow");

                // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            dp.dr.getSharesFromReceipt(
                dp.currentRound,
                dp.assetPerShare,
                vaultParams.decimals
            );

        uint256 depositAmount = dp.amount.mul(dp.leverage);
        uint256 borrowAmount = dp.amount.mul(dp.leverage-1);

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (dp.currentRound == dp.dr.round) {
            uint256 newAmount = uint256(dp.dr.amount).add(depositAmount);
            depositAmount = newAmount;
            borrowAmount = uint256(dp.prevBorrowAmount).add(borrowAmount);
        }

        ShareMath.assertUint104(depositAmount);
        ShareMath.assertUint104(borrowAmount);

        return (depositAmount, borrowAmount, unredeemedShares);
    }

    struct RedeemParams{
        address LIQUIDITY_POOL;
        uint256 shares;
        bool isMax;
        uint16 currentRound;
        uint256 assetPerShare;
        uint256 decimals;
        Vault.DepositReceipt dr;
        LeverageVault.BorrowReceipt br;
    }

    function redeem(RedeemParams calldata rd) public view returns(uint256,uint256, uint256){

        uint256 unredeemedShares =
            rd.dr.getSharesFromReceipt(
                rd.currentRound,
                rd.assetPerShare,
                rd.decimals
            );

        ILiquidity pool = ILiquidity(rd.LIQUIDITY_POOL);
        (uint256 dps,) = pool.pricePerShares(rd.br.round);
        uint256 newDebtShares = uint256(rd.br.amount).mul(RAY).div(dps);


        uint256 numShares = rd.isMax ? unredeemedShares : rd.shares;
        if (numShares == 0) {
            return (0, 0, 0);
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        ShareMath.assertUint128(numShares);

        return (numShares, newDebtShares, unredeemedShares);
    }

    struct InstantWithdrawParams {
        uint256 amount;
        uint256 dAmount;
        uint256 bAmount;
        uint256 dRound;
        uint256 currentRound;
        uint256 totalPending;
        uint256 bTotalPending;
    }

    function instantWithdraw(InstantWithdrawParams calldata iwp) public view returns (uint104,uint128, uint104, uint128, uint256){
        uint256 amount = iwp.amount;

        require(amount > 0, "!amount");
        require(iwp.dRound == iwp.currentRound, "Invalid round");

        uint256 receiptAmount = iwp.dAmount - iwp.bAmount;
        console.log("receiptAmount",receiptAmount, amount);
        require(receiptAmount >= amount, "Exceed amount");

        uint256 currentLeverage = uint256(iwp.dAmount).mul(10**2).div(receiptAmount);        

        // uint256 dAmount;
        // uint256 totalPending;
        // uint256 bAmount;
        // uint256 bTotalPending;        
        
        // Subtraction underflow checks already ensure it is smaller than uint104
        uint256 dAmount = uint104(iwp.dAmount - amount.mul(currentLeverage).div(10**2));
        uint256 totalPending = uint128(
            uint256(iwp.totalPending).sub(amount.mul(currentLeverage).div(10**2))
        );
                
        uint256 bAmount = uint104(iwp.bAmount - amount.mul(currentLeverage-10**2).div(10**2));
        uint256 bTotalPending = uint128(
            uint256(iwp.bTotalPending).sub(amount.mul(currentLeverage-10**2).div(10**2))
        );
        

        return (uint104(dAmount), uint128(totalPending), uint104(bAmount), uint128(bTotalPending), currentLeverage);
    }

    struct InitiateRepayParams {
        address LIQUIDITY_POOL;
        uint256 numShares;
        uint256 assetPerShare;
        uint256 decimals;
        uint256 userDebtShares;
    }

    function initiateRepay(InitiateRepayParams calldata irp) public view returns (uint256){
        ILiquidity pool = ILiquidity(irp.LIQUIDITY_POOL);
        (uint256 dps, ) = pool.pricePerShares(pool.currentRound()-1);

        uint256 scaledRepayShares = irp.numShares
                .mul(irp.assetPerShare)
                .div(10**irp.decimals)
                .mul(RAY)
                .div(dps);

        require(irp.userDebtShares>=scaledRepayShares, "not enough debt shares");

        return scaledRepayShares;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {GnosisAuction} from "../../libraries/GnosisAuction.sol";
import {
    PolysynthThetaVaultStorage
} from "../../storage/PolysynthThetaVaultStorage.sol";
import {Vault} from "../../libraries/Vault.sol";
import {VaultLifecycle} from "../../libraries/VaultLifecycle.sol";
import {ShareMath} from "../../libraries/ShareMath.sol";
import {ILiquidityGauge} from "../../interfaces/ILiquidityGauge.sol";
import {RibbonVault} from "./base/RibbonVault.sol";

/**
 * UPGRADEABILITY: Since we use the upgradeable proxy pattern, we must observe
 * the inheritance chain closely.
 * Any changes/appends in storage variable needs to happen in RibbonThetaVaultStorage.
 * RibbonThetaVault should not inherit from any other contract aside from RibbonVault, RibbonThetaVaultStorage
 */
contract RibbonThetaVault is RibbonVault, PolysynthThetaVaultStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice oTokenFactory is the factory contract used to spawn otokens. Used to lookup otokens.
    address public immutable OTOKEN_FACTORY;

    // The minimum duration for an option auction.
    uint256 private constant MIN_AUCTION_DURATION = 5 minutes;

    /************************************************
     *  EVENTS
     ***********************************************/

    event OpenShort(
        address indexed options,
        uint256 depositAmount,
        address indexed manager
    );

    event CloseShort(
        address indexed options,
        uint256 withdrawAmount,
        address indexed manager
    );

    event NewOptionStrikeSelected(uint256 strikePrice, uint256 delta);

    event PremiumDiscountSet(
        uint256 premiumDiscount,
        uint256 newPremiumDiscount
    );

    event AuctionDurationSet(
        uint256 auctionDuration,
        uint256 newAuctionDuration
    );

    event InstantWithdraw(
        address indexed account,
        uint256 amount,
        uint256 round
    );

    event InitiateGnosisAuction(
        address indexed auctioningToken,
        address indexed biddingToken,
        uint256 auctionCounter,
        address indexed manager
    );

    /************************************************
     *  STRUCTS
     ***********************************************/

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     * @param _premiumDiscount is the vault's discount applied to the premium
     * @param _auctionDuration is the duration of the gnosis auction
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _optionsPremiumPricer;
        address _strikeSelection;
        uint32 _premiumDiscount;
        uint256 _auctionDuration;
    }

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _oTokenFactory is the contract address for minting new opyn option types (strikes, asset, expiry)
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _gnosisEasyAuction is the contract address that facilitates gnosis auctions
     */
    constructor(
        address _weth,
        address _usdc,
        address _oTokenFactory,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction
    )
        RibbonVault(
            _weth,
            _usdc,
            _gammaController,
            _marginPool,
            _gnosisEasyAuction
        )
    {
        require(_oTokenFactory != address(0), "!_oTokenFactory");
        OTOKEN_FACTORY = _oTokenFactory;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     * @param _initParams is the struct with vault initialization parameters
     * @param _vaultParams is the struct with vault general data
     */
    function initialize(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams
    ) external initializer {
        baseInitialize(
            _initParams._owner,
            _initParams._keeper,
            _initParams._feeRecipient,
            _initParams._managementFee,
            _initParams._performanceFee,
            _initParams._tokenName,
            _initParams._tokenSymbol,
            _vaultParams
        );
        require(
            _initParams._optionsPremiumPricer != address(0),
            "!_optionsPremiumPricer"
        );
        require(
            _initParams._strikeSelection != address(0),
            "!_strikeSelection"
        );
        require(
            _initParams._premiumDiscount > 0 &&
                _initParams._premiumDiscount <
                100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "!_premiumDiscount"
        );
        require(
            _initParams._auctionDuration >= MIN_AUCTION_DURATION,
            "!_auctionDuration"
        );
        optionsPremiumPricer = _initParams._optionsPremiumPricer;
        strikeSelection = _initParams._strikeSelection;
        premiumDiscount = _initParams._premiumDiscount;
        auctionDuration = _initParams._auctionDuration;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new discount on premiums for options we are selling
     * @param newPremiumDiscount is the premium discount
     */
    function setPremiumDiscount(uint256 newPremiumDiscount)
        external
        onlyKeeper
    {
        require(
            newPremiumDiscount > 0 &&
                newPremiumDiscount <= 100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "Invalid discount"
        );

        emit PremiumDiscountSet(premiumDiscount, newPremiumDiscount);

        premiumDiscount = newPremiumDiscount;
    }

    /**
     * @notice Sets the new auction duration
     * @param newAuctionDuration is the auction duration
     */
    function setAuctionDuration(uint256 newAuctionDuration) external onlyOwner {
        require(
            newAuctionDuration >= MIN_AUCTION_DURATION,
            "Invalid auction duration"
        );

        emit AuctionDurationSet(auctionDuration, newAuctionDuration);

        auctionDuration = newAuctionDuration;
    }

    /**
     * @notice Sets the new strike selection contract
     * @param newStrikeSelection is the address of the new strike selection contract
     */
    function setStrikeSelection(address newStrikeSelection) external onlyOwner {
        require(newStrikeSelection != address(0), "!newStrikeSelection");
        strikeSelection = newStrikeSelection;
    }

    /**
     * @notice Sets the new options premium pricer contract
     * @param newOptionsPremiumPricer is the address of the new strike selection contract
     */
    function setOptionsPremiumPricer(address newOptionsPremiumPricer)
        external
        onlyOwner
    {
        require(
            newOptionsPremiumPricer != address(0),
            "!newOptionsPremiumPricer"
        );
        optionsPremiumPricer = newOptionsPremiumPricer;
    }

    /**
     * @notice Optionality to set strike price manually
     * @param strikePrice is the strike price of the new oTokens (decimals = 8)
     */
    function setStrikePrice(uint128 strikePrice) external onlyOwner {
        require(strikePrice > 0, "!strikePrice");
        overriddenStrikePrice = strikePrice;
        lastStrikeOverrideRound = vaultState.round;
    }

    /**
     * @notice Sets the new liquidityGauge contract for this vault
     * @param newLiquidityGauge is the address of the new liquidityGauge contract
     */
    function setLiquidityGauge(address newLiquidityGauge) external onlyOwner {
        liquidityGauge = newLiquidityGauge;
    }

    /**
     * @notice Sets the new optionsPurchaseQueue contract for this vault
     * @param newOptionsPurchaseQueue is the address of the new optionsPurchaseQueue contract
     */
    function setOptionsPurchaseQueue(address newOptionsPurchaseQueue)
        external
        onlyOwner
    {
        optionsPurchaseQueue = newOptionsPurchaseQueue;
    }

    /**
     * @notice Sets oToken Premium
     * @param minPrice is the new oToken Premium in the units of 10**18
     */
    function setMinPrice(uint256 minPrice) external onlyKeeper {
        require(minPrice > 0, "!minPrice");
        currentOtokenPremium = minPrice;
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Withdraws the assets on the vault using the outstanding `DepositReceipt.amount`
     * @param amount is the amount to withdraw
     */
    function withdrawInstantly(uint256 amount) external nonReentrant {
        Vault.DepositReceipt storage depositReceipt =
            depositReceipts[msg.sender];

        uint256 currentRound = vaultState.round;
        require(amount > 0, "!amount");
        require(depositReceipt.round == currentRound, "Invalid round");

        uint256 receiptAmount = depositReceipt.amount;
        require(receiptAmount >= amount, "Exceed amount");

        // Subtraction underflow checks already ensure it is smaller than uint104
        depositReceipt.amount = uint104(receiptAmount.sub(amount));
        vaultState.totalPending = uint128(
            uint256(vaultState.totalPending).sub(amount)
        );

        emit InstantWithdraw(msg.sender, amount, currentRound);

        transferAsset(msg.sender, amount);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function initiateWithdraw(uint256 numShares) external nonReentrant {
        _initiateWithdraw(numShares);
        currentQueuedWithdrawShares = currentQueuedWithdrawShares.add(
            numShares
        );
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     */
    function completeWithdraw() external nonReentrant {
        uint256 withdrawAmount = _completeWithdraw();
        lastQueuedWithdrawAmount = uint128(
            uint256(lastQueuedWithdrawAmount).sub(withdrawAmount)
        );
    }

    /**
     * @notice Stakes a users vault shares
     * @param numShares is the number of shares to stake
     */
    function stake(uint256 numShares) external nonReentrant {
        address _liquidityGauge = liquidityGauge;
        require(_liquidityGauge != address(0)); // Removed revert msgs due to contract size limit
        require(numShares > 0);
        uint256 heldByAccount = balanceOf(msg.sender);
        if (heldByAccount < numShares) {
            _redeem(numShares.sub(heldByAccount), false);
        }
        _transfer(msg.sender, address(this), numShares);
        _approve(address(this), _liquidityGauge, numShares);
        ILiquidityGauge(_liquidityGauge).deposit(numShares, msg.sender, false);
    }

    /**
     * @notice Sets the next option the vault will be shorting, and closes the existing short.
     *         This allows all the users to withdraw if the next option is malicious.
     */
    function commitAndClose() external nonReentrant {
        address oldOption = optionState.currentOption;

        VaultLifecycle.CloseParams memory closeParams =
            VaultLifecycle.CloseParams({
                OTOKEN_FACTORY: OTOKEN_FACTORY,
                USDC: USDC,
                currentOption: oldOption,
                delay: DELAY,
                lastStrikeOverrideRound: lastStrikeOverrideRound,
                overriddenStrikePrice: overriddenStrikePrice,
                strikeSelection: strikeSelection,
                optionsPremiumPricer: optionsPremiumPricer,
                premiumDiscount: premiumDiscount
            });

        (address otokenAddress, uint256 strikePrice, uint256 delta) =
            VaultLifecycle.commitAndClose(closeParams, vaultParams, vaultState);

        emit NewOptionStrikeSelected(strikePrice, delta);

        optionState.nextOption = otokenAddress;

        uint256 nextOptionReady = block.timestamp.add(DELAY);
        require(
            nextOptionReady <= type(uint32).max,
            "Overflow nextOptionReady"
        );
        optionState.nextOptionReadyAt = uint32(nextOptionReady);

        _closeShort(oldOption);
    }

    /**
     * @notice Closes the existing short position for the vault.
     */
    function _closeShort(address oldOption) private {
        uint256 lockedAmount = vaultState.lockedAmount;
        if (oldOption != address(0)) {
            vaultState.lastLockedAmount = uint104(lockedAmount);
        }
        vaultState.lockedAmount = 0;

        optionState.currentOption = address(0);

        if (oldOption != address(0)) {
            uint256 withdrawAmount =
                VaultLifecycle.settleShort(GAMMA_CONTROLLER);
            emit CloseShort(oldOption, withdrawAmount, msg.sender);
        }
    }

    /**
     * @notice Rolls the vault's funds into a new short position.
     */
    function rollToNextOption() external onlyKeeper nonReentrant {
        uint256 currQueuedWithdrawShares = currentQueuedWithdrawShares;

        (
            address newOption,
            uint256 lockedBalance,
            uint256 queuedWithdrawAmount
        ) =
            _rollToNextOption(
                lastQueuedWithdrawAmount,
                currQueuedWithdrawShares
            );

        lastQueuedWithdrawAmount = queuedWithdrawAmount;

        uint256 newQueuedWithdrawShares =
            uint256(vaultState.queuedWithdrawShares).add(
                currQueuedWithdrawShares
            );
        ShareMath.assertUint128(newQueuedWithdrawShares);
        vaultState.queuedWithdrawShares = uint128(newQueuedWithdrawShares);

        currentQueuedWithdrawShares = 0;

        ShareMath.assertUint104(lockedBalance);
        vaultState.lockedAmount = uint104(lockedBalance);

        emit OpenShort(newOption, lockedBalance, msg.sender);

        uint256 optionsMintAmount =
            VaultLifecycle.createShort(
                GAMMA_CONTROLLER,
                MARGIN_POOL,
                newOption,
                lockedBalance
            );

        VaultLifecycle.allocateOptions(
            optionsPurchaseQueue,
            newOption,
            optionsMintAmount,
            VaultLifecycle.QUEUE_OPTION_ALLOCATION
        );

        _startAuction();
    }

    /**
     * @notice Initiate the gnosis auction.
     */
    function startAuction() external onlyKeeper nonReentrant {
        _startAuction();
    }

    function _startAuction() private {
        GnosisAuction.AuctionDetails memory auctionDetails;

        address currentOtoken = optionState.currentOption;

        auctionDetails.oTokenAddress = currentOtoken;
        auctionDetails.gnosisEasyAuction = GNOSIS_EASY_AUCTION;
        auctionDetails.asset = vaultParams.asset;
        auctionDetails.assetDecimals = vaultParams.decimals;
        auctionDetails.oTokenPremium = currentOtokenPremium;
        auctionDetails.duration = auctionDuration;

        optionAuctionID = VaultLifecycle.startAuction(auctionDetails);
    }

    /**
     * @notice Sell the allocated options to the purchase queue post auction settlement
     */
    function sellOptionsToQueue() external onlyKeeper nonReentrant {
        VaultLifecycle.sellOptionsToQueue(
            optionsPurchaseQueue,
            GNOSIS_EASY_AUCTION,
            optionAuctionID
        );
    }

    /**
     * @notice Burn the remaining oTokens left over from gnosis auction.
     */
    function burnRemainingOTokens() external onlyKeeper nonReentrant {
        uint256 unlockedAssetAmount =
            VaultLifecycle.burnOtokens(
                GAMMA_CONTROLLER,
                optionState.currentOption
            );

        vaultState.lockedAmount = uint104(
            uint256(vaultState.lockedAmount).sub(unlockedAssetAmount)
        );
    }

    /**
     * @notice Recovery function that returns an ERC20 token to the recipient
     * @param token is the ERC20 token to recover from the vault
     * @param recipient is the recipient of the recovered tokens
     */
    function recoverTokens(address token, address recipient)
        external
        onlyOwner
    {
        require(token != vaultParams.asset, "Vault asset not recoverable");
        require(token != address(this), "Vault share not recoverable");
        require(recipient != address(this), "Recipient cannot be vault");

        IERC20(token).safeTransfer(
            recipient,
            IERC20(token).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    ReentrancyGuardUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import {Vault} from "../../../libraries/Vault.sol";
import {VaultLifecycle} from "../../../libraries/VaultLifecycle.sol";
import {ShareMath} from "../../../libraries/ShareMath.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";

contract RibbonVault is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using ShareMath for Vault.DepositReceipt;

    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public depositFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public withdrawalFee;

    // Gap is left to avoid storage collisions. Though RibbonVault is not upgradeable, we add this as a safety measure.
    uint256[30] private ____gap;

    // *IMPORTANT* NO NEW STORAGE VARIABLES SHOULD BE ADDED HERE
    // This is to prevent storage collisions. All storage variables should be appended to RibbonThetaVaultStorage
    // or RibbonDeltaVaultStorage instead. Read this documentation to learn more:
    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/

    /// @notice WETH9 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    address public immutable WETH;

    /// @notice USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    address public immutable USDC;

    /// @notice Deprecated: 15 minute timelock between commitAndClose and rollToNexOption.
    uint256 public constant DELAY = 0;

    /// @notice 7 day period between each options sale.
    uint256 public constant PERIOD = 7 days;

    // Number of weeks per year = 52.142857 weeks * FEE_MULTIPLIER = 52142857
    // Dividing by weeks per year requires doing num.mul(FEE_MULTIPLIER).div(WEEKS_PER_YEAR)
    uint256 private constant WEEKS_PER_YEAR = 52142857;

    // GAMMA_CONTROLLER is the top-level contract in Gamma protocol
    // which allows users to perform multiple actions on their vaults
    // and positions https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/Controller.sol
    address public immutable GAMMA_CONTROLLER;

    // MARGIN_POOL is Gamma protocol's collateral pool.
    // Needed to approve collateral.safeTransferFrom for minting otokens.
    // https://github.com/opynfinance/GammaProtocol/blob/master/contracts/core/MarginPool.sol
    address public immutable MARGIN_POOL;

    // GNOSIS_EASY_AUCTION is Gnosis protocol's contract for initiating auctions and placing bids
    // https://github.com/gnosis/ido-contracts/blob/main/contracts/EasyAuction.sol
    address public immutable GNOSIS_EASY_AUCTION;

    /************************************************
     *  EVENTS
     ***********************************************/

    event Deposit(address indexed account, uint256 amount, uint256 round);

    event InitiateWithdraw(
        address indexed account,
        uint256 shares,
        uint256 round
    );

    event Redeem(address indexed account, uint256 share, uint256 round);

    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);

    event PerformanceFeeSet(uint256 performanceFee, uint256 newPerformanceFee);

    event CapSet(uint256 oldCap, uint256 newCap);

    event Withdraw(address indexed account, uint256 amount, uint256 shares);

    event CollectVaultFees(
        uint256 performanceFee,
        uint256 vaultFee,
        uint256 round,
        address indexed feeRecipient
    );

    /************************************************
     *  CONSTRUCTOR & INITIALIZATION
     ***********************************************/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _weth is the Wrapped Ether contract
     * @param _usdc is the USDC contract
     * @param _gammaController is the contract address for opyn actions
     * @param _marginPool is the contract address for providing collateral to opyn
     * @param _gnosisEasyAuction is the contract address that facilitates gnosis auctions
     */
    constructor(
        address _weth,
        address _usdc,
        address _gammaController,
        address _marginPool,
        address _gnosisEasyAuction
    ) {
        require(_weth != address(0), "!_weth");
        require(_usdc != address(0), "!_usdc");
        require(_gnosisEasyAuction != address(0), "!_gnosisEasyAuction");
        require(_gammaController != address(0), "!_gammaController");
        require(_marginPool != address(0), "!_marginPool");

        WETH = _weth;
        USDC = _usdc;
        GAMMA_CONTROLLER = _gammaController;
        MARGIN_POOL = _marginPool;
        GNOSIS_EASY_AUCTION = _gnosisEasyAuction;
    }

    /**
     * @notice Initializes the OptionVault contract with storage variables.
     */
    function baseInitialize(
        address _owner,
        address _keeper,
        address _feeRecipient,
        uint256 _managementFee,
        uint256 _performanceFee,
        string memory _tokenName,
        string memory _tokenSymbol,
        Vault.VaultParams calldata _vaultParams
    ) internal initializer {
        VaultLifecycle.verifyInitializerParams(
            _owner,
            _keeper,
            _feeRecipient,
            _performanceFee,
            _managementFee,
            _tokenName,
            _tokenSymbol,
            _vaultParams
        );

        __ReentrancyGuard_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        __Ownable_init();
        transferOwnership(_owner);

        keeper = _keeper;

        feeRecipient = _feeRecipient;
        performanceFee = _performanceFee;
        managementFee = _managementFee.mul(Vault.FEE_MULTIPLIER).div(
            WEEKS_PER_YEAR
        );
        vaultParams = _vaultParams;

        uint256 assetBalance =
            IERC20(vaultParams.asset).balanceOf(address(this));
        ShareMath.assertUint104(assetBalance);
        vaultState.lastLockedAmount = uint104(assetBalance);

        vaultState.round = 1;
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }

    /************************************************
     *  SETTERS
     ***********************************************/

    /**
     * @notice Sets the new keeper
     * @param newKeeper is the address of the new keeper
     */
    function setNewKeeper(address newKeeper) external onlyOwner {
        require(newKeeper != address(0), "!newKeeper");
        keeper = newKeeper;
    }

    /**
     * @notice Sets the new fee recipient
     * @param newFeeRecipient is the address of the new fee recipient
     */
    function setFeeRecipient(address newFeeRecipient) external onlyOwner {
        require(newFeeRecipient != address(0), "!newFeeRecipient");
        require(newFeeRecipient != feeRecipient, "Must be new feeRecipient");
        feeRecipient = newFeeRecipient;
    }

    /**
     * @notice Sets the management fee for the vault
     * @param newManagementFee is the management fee (6 decimals). ex: 2 * 10 ** 6 = 2%
     */
    function setManagementFee(uint256 newManagementFee) external onlyOwner {
        require(
            newManagementFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid management fee"
        );

        // We are dividing annualized management fee by num weeks in a year
        uint256 tmpManagementFee =
            newManagementFee.mul(Vault.FEE_MULTIPLIER).div(WEEKS_PER_YEAR);

        emit ManagementFeeSet(managementFee, newManagementFee);

        managementFee = tmpManagementFee;
    }

    /**
     * @notice Sets the performance fee for the vault
     * @param newPerformanceFee is the performance fee (6 decimals). ex: 20 * 10 ** 6 = 20%
     */
    function setPerformanceFee(uint256 newPerformanceFee) external onlyOwner {
        require(
            newPerformanceFee < 100 * Vault.FEE_MULTIPLIER,
            "Invalid performance fee"
        );

        emit PerformanceFeeSet(performanceFee, newPerformanceFee);

        performanceFee = newPerformanceFee;
    }

    /**
     * @notice Sets a new cap for deposits
     * @param newCap is the new cap for deposits
     */
    function setCap(uint256 newCap) external onlyOwner {
        require(newCap > 0, "!newCap");
        ShareMath.assertUint104(newCap);
        emit CapSet(vaultParams.cap, newCap);
        vaultParams.cap = uint104(newCap);
    }

    /************************************************
     *  DEPOSIT & WITHDRAWALS
     ***********************************************/

    /**
     * @notice Deposits ETH into the contract and mint vault shares. Reverts if the asset is not WETH.
     */
    function depositETH() external payable nonReentrant {
        require(vaultParams.asset == WETH, "!WETH");
        require(msg.value > 0, "!value");

        _depositFor(msg.value, msg.sender);

        IWETH(WETH).deposit{value: msg.value}();
    }

    /**
     * @notice Deposits the `asset` from msg.sender.
     * @param amount is the amount of `asset` to deposit
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "!amount");

        _depositFor(amount, msg.sender);

        if (depositFee>0){
            uint256 fee = amount.mul(depositFee).div(100 * Vault.FEE_MULTIPLIER);
            amount += fee;
        }


        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Deposits the `asset` from msg.sender added to `creditor`'s deposit.
     * @notice Used for vault -> vault deposits on the user's behalf
     * @param amount is the amount of `asset` to deposit
     * @param creditor is the address that can claim/withdraw deposited amount
     */
    function depositFor(uint256 amount, address creditor)
        external
        nonReentrant
    {
        require(amount > 0, "!amount");
        require(creditor != address(0));

        _depositFor(amount, creditor);

        // An approve() by the msg.sender is required beforehand
        IERC20(vaultParams.asset).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
    }

    /**
     * @notice Mints the vault shares to the creditor
     * @param amount is the amount of `asset` deposited
     * @param creditor is the address to receieve the deposit
     */
    function _depositFor(uint256 amount, address creditor) private {
        uint256 currentRound = vaultState.round;
        uint256 totalWithDepositedAmount = totalBalance().add(amount);

        require(totalWithDepositedAmount <= vaultParams.cap, "Exceed cap");
        require(
            totalWithDepositedAmount >= vaultParams.minimumSupply,
            "Insufficient balance"
        );

        emit Deposit(creditor, amount, currentRound);

        Vault.DepositReceipt memory depositReceipt = depositReceipts[creditor];

        // If we have an unprocessed pending deposit from the previous rounds, we have to process it.
        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        uint256 depositAmount = amount;

        // If we have a pending deposit in the current round, we add on to the pending deposit
        if (currentRound == depositReceipt.round) {
            uint256 newAmount = uint256(depositReceipt.amount).add(amount);
            depositAmount = newAmount;
        }

        ShareMath.assertUint104(depositAmount);

        depositReceipts[creditor] = Vault.DepositReceipt({
            round: uint16(currentRound),
            amount: uint104(depositAmount),
            unredeemedShares: uint128(unredeemedShares)
        });

        uint256 newTotalPending = uint256(vaultState.totalPending).add(amount);
        ShareMath.assertUint128(newTotalPending);

        vaultState.totalPending = uint128(newTotalPending);
    }

    /**
     * @notice Initiates a withdrawal that can be processed once the round completes
     * @param numShares is the number of shares to withdraw
     */
    function _initiateWithdraw(uint256 numShares) internal {
        require(numShares > 0, "!numShares");

        // We do a max redeem before initiating a withdrawal
        // But we check if they must first have unredeemed shares
        if (
            depositReceipts[msg.sender].amount > 0 ||
            depositReceipts[msg.sender].unredeemedShares > 0
        ) {
            _redeem(0, true);
        }

        // This caches the `round` variable used in shareBalances
        uint256 currentRound = vaultState.round;
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        bool withdrawalIsSameRound = withdrawal.round == currentRound;

        emit InitiateWithdraw(msg.sender, numShares, currentRound);

        uint256 existingShares = uint256(withdrawal.shares);

        uint256 withdrawalShares;
        if (withdrawalIsSameRound) {
            withdrawalShares = existingShares.add(numShares);
        } else {
            require(existingShares == 0, "Existing withdraw");
            withdrawalShares = numShares;
            withdrawals[msg.sender].round = uint16(currentRound);
        }

        ShareMath.assertUint128(withdrawalShares);
        withdrawals[msg.sender].shares = uint128(withdrawalShares);

        _transfer(msg.sender, address(this), numShares);
    }

    /**
     * @notice Completes a scheduled withdrawal from a past round. Uses finalized pps for the round
     * @return withdrawAmount the current withdrawal amount
     */
    function _completeWithdraw() internal returns (uint256) {
        Vault.Withdrawal storage withdrawal = withdrawals[msg.sender];

        uint256 withdrawalShares = withdrawal.shares;
        uint256 withdrawalRound = withdrawal.round;

        // This checks if there is a withdrawal
        require(withdrawalShares > 0, "Not initiated");

        require(withdrawalRound < vaultState.round, "Round not closed");

        // We leave the round number as non-zero to save on gas for subsequent writes
        withdrawals[msg.sender].shares = 0;
        vaultState.queuedWithdrawShares = uint128(
            uint256(vaultState.queuedWithdrawShares).sub(withdrawalShares)
        );

        uint256 withdrawAmount =
            ShareMath.sharesToAsset(
                withdrawalShares,
                roundPricePerShare[withdrawalRound],
                vaultParams.decimals
            );

        emit Withdraw(msg.sender, withdrawAmount, withdrawalShares);

        _burn(address(this), withdrawalShares);

        require(withdrawAmount > 0, "!withdrawAmount");

        if(withdrawalFee>0){
            uint256 fee = withdrawAmount.mul(withdrawalFee).div(100 * Vault.FEE_MULTIPLIER);
            withdrawAmount -= fee;
        }


        transferAsset(msg.sender, withdrawAmount);

        return withdrawAmount;
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem
     */
    function redeem(uint256 numShares) external nonReentrant {
        require(numShares > 0, "!numShares");
        _redeem(numShares, false);
    }

    /**
     * @notice Redeems the entire unredeemedShares balance that is owed to the account
     */
    function maxRedeem() external nonReentrant {
        _redeem(0, true);
    }

    /**
     * @notice Redeems shares that are owed to the account
     * @param numShares is the number of shares to redeem, could be 0 when isMax=true
     * @param isMax is flag for when callers do a max redemption
     */
    function _redeem(uint256 numShares, bool isMax) internal {
        Vault.DepositReceipt memory depositReceipt =
            depositReceipts[msg.sender];

        // This handles the null case when depositReceipt.round = 0
        // Because we start with round = 1 at `initialize`
        uint256 currentRound = vaultState.round;

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                currentRound,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        numShares = isMax ? unredeemedShares : numShares;
        if (numShares == 0) {
            return;
        }
        require(numShares <= unredeemedShares, "Exceeds available");

        // If we have a depositReceipt on the same round, BUT we have some unredeemed shares
        // we debit from the unredeemedShares, but leave the amount field intact
        // If the round has past, with no new deposits, we just zero it out for new deposits.
        if (depositReceipt.round < currentRound) {
            depositReceipts[msg.sender].amount = 0;
        }

        ShareMath.assertUint128(numShares);
        depositReceipts[msg.sender].unredeemedShares = uint128(
            unredeemedShares.sub(numShares)
        );

        emit Redeem(msg.sender, numShares, depositReceipt.round);

        _transfer(address(this), msg.sender, numShares);
    }

    /************************************************
     *  VAULT OPERATIONS
     ***********************************************/

    /**
     * @notice Helper function that helps to save gas for writing values into the roundPricePerShare map.
     *         Writing `1` into the map makes subsequent writes warm, reducing the gas from 20k to 5k.
     *         Having 1 initialized beforehand will not be an issue as long as we round down share calculations to 0.
     * @param numRounds is the number of rounds to initialize in the map
     */
    function initRounds(uint256 numRounds) external nonReentrant {
        require(numRounds > 0, "!numRounds");

        uint256 _round = vaultState.round;
        for (uint256 i = 0; i < numRounds; i++) {
            uint256 index = _round + i;
            require(roundPricePerShare[index] == 0, "Initialized"); // AVOID OVERWRITING ACTUAL VALUES
            roundPricePerShare[index] = ShareMath.PLACEHOLDER_UINT;
        }
    }

    /**
     * @notice Helper function that performs most administrative tasks
     * such as setting next option, minting new shares, getting vault fees, etc.
     * @param lastQueuedWithdrawAmount is old queued withdraw amount
     * @param currentQueuedWithdrawShares is the queued withdraw shares for the current round
     * @return newOption is the new option address
     * @return lockedBalance is the new balance used to calculate next option purchase size or collateral size
     * @return queuedWithdrawAmount is the new queued withdraw amount for this round
     */
    function _rollToNextOption(
        uint256 lastQueuedWithdrawAmount,
        uint256 currentQueuedWithdrawShares
    )
        internal
        returns (
            address newOption,
            uint256 lockedBalance,
            uint256 queuedWithdrawAmount
        )
    {
        require(block.timestamp >= optionState.nextOptionReadyAt, "!ready");

        newOption = optionState.nextOption;
        require(newOption != address(0), "!nextOption");

        address recipient = feeRecipient;
        uint256 mintShares;
        uint256 performanceFeeInAsset;
        uint256 totalVaultFee;
        {
            uint256 newPricePerShare;
            (
                lockedBalance,
                queuedWithdrawAmount,
                newPricePerShare,
                mintShares,
                performanceFeeInAsset,
                totalVaultFee
            ) = VaultLifecycle.rollover(
                vaultState,
                VaultLifecycle.RolloverParams(
                    vaultParams.decimals,
                    IERC20(vaultParams.asset).balanceOf(address(this)),
                    totalSupply(),
                    lastQueuedWithdrawAmount,
                    performanceFee,
                    managementFee,
                    currentQueuedWithdrawShares
                )
            );

            optionState.currentOption = newOption;
            optionState.nextOption = address(0);

            // Finalize the pricePerShare at the end of the round
            uint256 currentRound = vaultState.round;
            roundPricePerShare[currentRound] = newPricePerShare;

            emit CollectVaultFees(
                performanceFeeInAsset,
                totalVaultFee,
                currentRound,
                recipient
            );

            vaultState.totalPending = 0;
            vaultState.round = uint16(currentRound + 1);
        }

        _mint(address(this), mintShares);

        if (totalVaultFee > 0) {
            transferAsset(payable(recipient), totalVaultFee);
        }

        return (newOption, lockedBalance, queuedWithdrawAmount);
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) internal {
        address asset = vaultParams.asset;
        if (asset == WETH) {
            IWETH(WETH).withdraw(amount);
            (bool success, ) = recipient.call{value: amount}("");
            require(success, "Transfer failed");
            return;
        }
        IERC20(asset).safeTransfer(recipient, amount);
    }

    /************************************************
     *  GETTERS
     ***********************************************/

    /**
     * @notice Returns the asset balance held on the vault for the account
     * @param account is the address to lookup balance for
     * @return the amount of `asset` custodied by the vault for the user
     */
    function accountVaultBalance(address account)
        external
        view
        returns (uint256)
    {
        uint256 _decimals = vaultParams.decimals;
        uint256 assetPerShare =
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                _decimals
            );
        return
            ShareMath.sharesToAsset(shares(account), assetPerShare, _decimals);
    }

    /**
     * @notice Getter for returning the account's share balance including unredeemed shares
     * @param account is the account to lookup share balance for
     * @return the share balance
     */
    function shares(address account) public view returns (uint256) {
        (uint256 heldByAccount, uint256 heldByVault) = shareBalances(account);
        return heldByAccount.add(heldByVault);
    }

    /**
     * @notice Getter for returning the account's share balance split between account and vault holdings
     * @param account is the account to lookup share balance for
     * @return heldByAccount is the shares held by account
     * @return heldByVault is the shares held on the vault (unredeemedShares)
     */
    function shareBalances(address account)
        public
        view
        returns (uint256 heldByAccount, uint256 heldByVault)
    {
        Vault.DepositReceipt memory depositReceipt = depositReceipts[account];

        if (depositReceipt.round < ShareMath.PLACEHOLDER_UINT) {
            return (balanceOf(account), 0);
        }

        uint256 unredeemedShares =
            depositReceipt.getSharesFromReceipt(
                vaultState.round,
                roundPricePerShare[depositReceipt.round],
                vaultParams.decimals
            );

        return (balanceOf(account), unredeemedShares);
    }

    /**
     * @notice The price of a unit of share denominated in the `asset`
     */
    function pricePerShare() external view returns (uint256) {
        return
            ShareMath.pricePerShare(
                totalSupply(),
                totalBalance(),
                vaultState.totalPending,
                vaultParams.decimals
            );
    }

    /**
     * @notice Returns the vault's total balance, including the amounts locked into a short position
     * @return total balance of the vault, including the amounts locked in third party protocols
     */
    function totalBalance() public view returns (uint256) {
        return
            uint256(vaultState.lockedAmount).add(
                IERC20(vaultParams.asset).balanceOf(address(this))
            );
    }

    /**
     * @notice Returns the token decimals
     */
    function decimals() public view override returns (uint8) {
        return vaultParams.decimals;
    }

    function cap() external view returns (uint256) {
        return vaultParams.cap;
    }

    function nextOptionReadyAt() external view returns (uint256) {
        return optionState.nextOptionReadyAt;
    }

    function currentOption() external view returns (address) {
        return optionState.currentOption;
    }

    function nextOption() external view returns (address) {
        return optionState.nextOption;
    }

    function totalPending() external view returns (uint256) {
        return vaultState.totalPending;
    }
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/airswap/airswap-protocols/blob/main/source/swap/contracts/Swap.sol

pragma solidity =0.8.4;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ISwap.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";

contract Swap is ISwap, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    bytes32 public constant BID_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Bid(",
                "uint256 swapId,",
                "uint256 nonce,",
                "address signerWallet,",
                "uint256 sellAmount,",
                "uint256 buyAmount,",
                "address referrer",
                ")"
            )
        );

    bytes32 public constant DOMAIN_NAME = keccak256("POLYSYNTH SWAP");
    bytes32 public constant DOMAIN_VERSION = keccak256("1");
    uint256 public immutable DOMAIN_CHAIN_ID;
    bytes32 public immutable DOMAIN_SEPARATOR;

    uint256 internal constant MAX_PERCENTAGE = 10000;
    uint256 internal constant MAX_FEE = 1000;
    uint256 internal constant MAX_ERROR_COUNT = 10;
    uint256 internal constant OTOKEN_DECIMALS = 8;

    uint256 public offersCounter = 0;

    mapping(uint256 => Offer) public swapOffers;

    mapping(address => uint256) public referralFees;

    mapping(address => address) public authorized;

    /**
     * @notice Double mapping of signers to nonce groups to nonce states
     * @dev The nonce group is computed as nonce / 256, so each group of 256 sequential nonces uses the same key
     * @dev The nonce states are encoded as 256 bits, for each nonce in the group 0 means available and 1 means used
     */
    mapping(address => mapping(uint256 => uint256)) internal _nonceGroups;

    /************************************************
     *  CONSTRUCTOR
     ***********************************************/

    constructor() {
        uint256 currentChainId = getChainId();
        DOMAIN_CHAIN_ID = currentChainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                DOMAIN_NAME,
                DOMAIN_VERSION,
                currentChainId,
                this
            )
        );
    }

    /************************************************
     *  SETTER
     ***********************************************/

    /**
     * @notice Sets the referral fee for a specific referrer
     * @param referrer is the address of the referrer
     * @param fee is the fee in percent in 2 decimals
     */
    function setFee(address referrer, uint256 fee) external onlyOwner {
        require(referrer != address(0), "Referrer cannot be the zero address");
        require(fee < MAX_FEE, "Fee exceeds maximum");

        referralFees[referrer] = fee;

        emit SetFee(referrer, fee);
    }

    /************************************************
     *  OFFER CREATION AND SETTLEMENT
     ***********************************************/

    /**
     * @notice Create a new offer available for swap
     * @param oToken token offered by seller
     * @param biddingToken token asked by seller
     * @param minPrice minimum price of oToken denominated in biddingToken
     * @param minBidSize minimum amount of oToken requested in a single bid
     * @param totalSize amount of oToken offered by seller
     */
    function createOffer(
        address oToken,
        address biddingToken,
        uint96 minPrice,
        uint96 minBidSize,
        uint128 totalSize
    ) external override returns (uint256 swapId) {
        require(oToken != address(0), "oToken cannot be the zero address");
        require(
            biddingToken != address(0),
            "BiddingToken cannot be the zero address"
        );
        require(minPrice > 0, "MinPrice must be larger than zero");
        require(minBidSize > 0, "MinBidSize must be larger than zero");
        require(minBidSize <= totalSize, "MinBidSize exceeds total size");

        offersCounter += 1;

        swapId = offersCounter;

        swapOffers[swapId].seller = msg.sender;
        swapOffers[swapId].oToken = oToken;
        swapOffers[swapId].biddingToken = biddingToken;
        swapOffers[swapId].minBidSize = minBidSize;
        swapOffers[swapId].minPrice = minPrice;
        swapOffers[swapId].totalSize = totalSize;
        swapOffers[swapId].availableSize = totalSize;
        // We warm the storage slot with 1 wei so we avoid a cold SSTORE
        swapOffers[swapId].totalSales = 1;

        emit NewOffer(
            swapId,
            msg.sender,
            oToken,
            biddingToken,
            minPrice,
            minBidSize,
            totalSize
        );
    }

    /**
     * @notice Settles the swap offering by iterating through the bids
     * @param swapId unique identifier of the swap offer
     * @param bids bids for swaps
     */
    function settleOffer(uint256 swapId, Bid[] calldata bids)
        external
        override
        nonReentrant
    {
        Offer storage offer = swapOffers[swapId];

        address seller = offer.seller;
        require(
            seller == msg.sender,
            "Only seller can settle or offer doesn't exist"
        );
        require(offer.availableSize > 0, "Offer fully settled");

        uint256 totalSales;
        OfferDetails memory offerDetails;
        offerDetails.seller = seller;
        offerDetails.oToken = offer.oToken;
        offerDetails.biddingToken = offer.biddingToken;
        offerDetails.minPrice = offer.minPrice;
        offerDetails.minBidSize = offer.minBidSize;

        for (uint256 i = 0; i < bids.length; i++) {
            require(
                swapId == bids[i].swapId,
                "Offer and bid swapId mismatched"
            );

            _swap(offerDetails, offer, bids[i]);
            totalSales += bids[i].sellAmount;
        }

        bool fullySettled = offer.availableSize == 0;

        // Deduct the initial 1 wei offset if offer is fully settled
        offer.totalSales += totalSales - (fullySettled ? 1 : 0);

        if (fullySettled) {
            offer.seller = address(0);
            offer.oToken = address(0);
            offer.biddingToken = address(0);
            offer.minBidSize = 0;
            offer.minPrice = 0;

            emit SettleOffer(swapId);
        }
    }

    /**
     * @notice Authorize a signer
     * @param signer address Wallet of the signer to authorize
     * @dev Emits an Authorize event
     */
    function authorize(address signer) external override {
        require(signer != address(0), "SIGNER_INVALID");
        authorized[msg.sender] = signer;
        emit Authorize(signer, msg.sender);
    }

    /**
     * @notice Revoke the signer
     * @dev Emits a Revoke event
     */
    function revoke() external override {
        address tmp = authorized[msg.sender];
        delete authorized[msg.sender];
        emit Revoke(tmp, msg.sender);
    }

    /**
     * @notice Cancel one or more nonces
     * @dev Cancelled nonces are marked as used
     * @dev Emits a Cancel event
     * @dev Out of gas may occur in arrays of length > 400
     * @param nonces uint256[] List of nonces to cancel
     */
    function cancelNonce(uint256[] calldata nonces) external override {
        for (uint256 i = 0; i < nonces.length; i++) {
            uint256 nonce = nonces[i];
            if (_markNonceAsUsed(msg.sender, nonce)) {
                emit Cancel(nonce, msg.sender);
            }
        }
    }

    /************************************************
     *  PUBLIC VIEW FUNCTIONS
     ***********************************************/

    /**
     * @notice Validates Swap bid for any potential errors
     * @param bid Bid struct containing bid details
     * @return tuple of error count and bytes32[] memory array of error messages
     */
    function check(Bid calldata bid)
        external
        view
        override
        returns (uint256, bytes32[] memory)
    {
        Offer memory offer = swapOffers[bid.swapId];
        require(offer.seller != address(0), "Offer does not exist");

        bytes32[] memory errors = new bytes32[](MAX_ERROR_COUNT);

        uint256 errCount;

        // Check signature
        address signatory = _getSignatory(bid);

        if (signatory == address(0)) {
            errors[errCount] = "SIGNATURE_INVALID";
            errCount++;
        }

        if (
            bid.signerWallet != signatory &&
            authorized[bid.signerWallet] != signatory
        ) {
            errors[errCount] = "UNAUTHORIZED";
            errCount++;
        }

        // Check nonce
        if (nonceUsed(signatory, bid.nonce)) {
            errors[errCount] = "NONCE_ALREADY_USED";
            errCount++;
        }

        // Check bid size
        if (bid.buyAmount < offer.minBidSize) {
            errors[errCount] = "BID_TOO_SMALL";
            errCount++;
        }
        if (bid.buyAmount > offer.availableSize) {
            errors[errCount] = "BID_EXCEED_AVAILABLE_SIZE";
            errCount++;
        }
        
        // Check bid price
        uint256 bidPrice =
            (bid.sellAmount * 10**OTOKEN_DECIMALS) / bid.buyAmount;
        if (bidPrice < offer.minPrice) {
            errors[errCount] = "PRICE_TOO_LOW";
            errCount++;
        }

        // Check signer allowance
        uint256 signerAllowance =
            IERC20(offer.biddingToken).allowance(
                bid.signerWallet,
                address(this)
            );
        if (signerAllowance < bid.sellAmount) {
            errors[errCount] = "SIGNER_ALLOWANCE_LOW";
            errCount++;
        }

        // Check signer balance
        uint256 signerBalance =
            IERC20(offer.biddingToken).balanceOf(bid.signerWallet);
        if (signerBalance < bid.sellAmount) {
            errors[errCount] = "SIGNER_BALANCE_LOW";
            errCount++;
        }

        // Check seller allowance
        uint256 sellerAllowance =
            IERC20(offer.oToken).allowance(offer.seller, address(this));
        if (sellerAllowance < bid.buyAmount) {
            errors[errCount] = "SELLER_ALLOWANCE_LOW";
            errCount++;
        }

        // Check seller balance
        uint256 sellerBalance = IERC20(offer.oToken).balanceOf(offer.seller);
        if (sellerBalance < bid.buyAmount) {
            errors[errCount] = "SELLER_BALANCE_LOW";
            errCount++;
        }

        return (errCount, errors);
    }

    /**
     * @notice Returns the average settlement price for a swap offer
     * @param swapId unique identifier of the swap offer
     */
    function averagePriceForOffer(uint256 swapId)
        external
        view
        override
        returns (uint256)
    {
        Offer storage offer = swapOffers[swapId];
        require(offer.totalSize != 0, "Offer does not exist");

        uint256 availableSize = offer.availableSize;

        // Deduct the initial 1 wei offset if offer is not fully settled
        uint256 adjustment = availableSize != 0 ? 1 : 0;

        return
            ((offer.totalSales - adjustment) * (10**8)) /
            (offer.totalSize - availableSize);
    }

    /**
     * @notice Returns true if the nonce has been used
     * @param signer address Address of the signer
     * @param nonce uint256 Nonce being checked
     */
    function nonceUsed(address signer, uint256 nonce)
        public
        view
        override
        returns (bool)
    {
        uint256 groupKey = nonce / 256;
        uint256 indexInGroup = nonce % 256;
        return (_nonceGroups[signer][groupKey] >> indexInGroup) & 1 == 1;
    }

    /************************************************
     *  INTERNAL FUNCTIONS
     ***********************************************/

    /**
     * @notice Swap Atomic ERC20 Swap
     * @param details Details of offering
     * @param offer Offer struct containing offer details
     * @param bid Bid struct containing bid details
     */
    function _swap(
        OfferDetails memory details,
        Offer storage offer,
        Bid calldata bid
    ) internal {
        require(DOMAIN_CHAIN_ID == getChainId(), "CHAIN_ID_CHANGED");

        address signatory = _getSignatory(bid); 

        if (bid.signerWallet != signatory) {
            require(authorized[bid.signerWallet] == signatory, "UNAUTHORIZED");
        }

        require(signatory != address(0), "SIGNATURE_INVALID");

        require(_markNonceAsUsed(signatory, bid.nonce), "NONCE_ALREADY_USED");
        require(
            bid.buyAmount <= offer.availableSize,
            "BID_EXCEED_AVAILABLE_SIZE"
        );
        require(bid.buyAmount >= details.minBidSize, "BID_TOO_SMALL");

        console.log("bid.sellAmount", bid.sellAmount, bid.buyAmount, offer.minPrice);
        // Ensure min. price is met
        uint256 bidPrice =
            (bid.sellAmount * 10**OTOKEN_DECIMALS) / bid.buyAmount;
        require(bidPrice >= details.minPrice, "PRICE_TOO_LOW");

        // don't have to do a uint128 check because we already check
        // that bid.buyAmount <= offer.availableSize
        offer.availableSize -= uint128(bid.buyAmount);

        // Transfer token from sender to signer
        IERC20(details.oToken).safeTransferFrom(
            details.seller,
            bid.signerWallet,
            bid.buyAmount
        );

        // Transfer to referrer if any
        uint256 feeAmount;
        if (bid.referrer != address(0)) {
            uint256 feePercent = referralFees[bid.referrer];

            if (feePercent > 0) {
                feeAmount = (bid.sellAmount * feePercent) / MAX_PERCENTAGE;

                IERC20(details.biddingToken).safeTransferFrom(
                    bid.signerWallet,
                    bid.referrer,
                    feeAmount
                );
            }
        }

        // Transfer token from signer to recipient
        IERC20(details.biddingToken).safeTransferFrom(
            bid.signerWallet,
            details.seller,
            bid.sellAmount - feeAmount
        );

        // Emit a Swap event
        emit Swap(
            bid.swapId,
            bid.nonce,
            bid.signerWallet,
            bid.sellAmount,
            bid.buyAmount,
            bid.referrer,
            feeAmount
        );
    }

    /**
     * @notice Marks a nonce as used for the given signer
     * @param signer address Address of the signer for which to mark the nonce as used
     * @param nonce uint256 Nonce to be marked as used
     * @return bool True if the nonce was not marked as used already
     */
    function _markNonceAsUsed(address signer, uint256 nonce)
        internal
        returns (bool)
    {
        uint256 groupKey = nonce / 256;
        uint256 indexInGroup = nonce % 256;
        uint256 group = _nonceGroups[signer][groupKey];

        // If it is already used, return false
        if ((group >> indexInGroup) & 1 == 1) {
            return false;
        }

        _nonceGroups[signer][groupKey] = group | (uint256(1) << indexInGroup);

        return true;
    }

    /**
     * @notice Recover the signatory from a signature
     * @param bid Bid struct containing bid details
     */
    function _getSignatory(Bid calldata bid) internal view returns (address) {
        return
            ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR,
                        keccak256(
                            abi.encode(
                                BID_TYPEHASH,
                                bid.swapId,
                                bid.nonce,
                                bid.signerWallet,
                                bid.sellAmount,
                                bid.buyAmount,
                                bid.referrer
                            )
                        )
                    )
                ),
                bid.v,
                bid.r,
                bid.s
            );
    }

    /**
     * @notice Returns the current chainId using the chainid opcode
     * @return id uint256 The chain id
     */
    function getChainId() internal view returns (uint256 id) {
        // no-inline-assembly
        assembly {
            id := chainid()
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {DSMath} from "../vendor/DSMath.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VaultLifecycle} from "./VaultLifecycle.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {ISTETH, IWSTETH} from "../interfaces/ISTETH.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ICRV} from "../interfaces/ICRV.sol";
import {IStrikeSelection} from "../interfaces/IRibbon.sol";
import {
    IOtokenFactory,
    IOtoken,
    IController,
    GammaTypes
} from "../interfaces/GammaInterface.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";

library VaultLifecycleSTETH {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @param collateralAsset is the address of the collateral asset
     * @return otokenAddress is the address of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */
    function commitAndClose(
        VaultLifecycle.CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        Vault.VaultState storage vaultState,
        address collateralAsset
    )
        external
        returns (
            address otokenAddress,
            uint256 strikePrice,
            uint256 delta
        )
    {
        uint256 expiry =
            VaultLifecycle.getNextExpiry(closeParams.currentOption);

        IStrikeSelection selection =
            IStrikeSelection(closeParams.strikeSelection);

        // calculate strike and delta
        (strikePrice, delta) = closeParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (closeParams.overriddenStrikePrice, selection.delta())
            : selection.getStrikePrice(expiry, false);

        require(strikePrice != 0, "!strikePrice");

        // retrieve address if option already exists, or deploy it
        otokenAddress = VaultLifecycle.getOrDeployOtoken(
            closeParams,
            vaultParams,
            vaultParams.underlying,
            collateralAsset,
            strikePrice,
            expiry,
            false
        );

        return (otokenAddress, strikePrice, delta);
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param currentShareSupply is the total supply of shares
     * @param currentBalance is the total balance of the vault
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     */
    function rollover(
        uint256 currentShareSupply,
        uint256 currentBalance,
        Vault.VaultParams calldata vaultParams,
        Vault.VaultState calldata vaultState
    )
        external
        pure
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares
        )
    {
        uint256 pendingAmount = uint256(vaultState.totalPending);
        uint256 _decimals = vaultParams.decimals;

        newPricePerShare = ShareMath.pricePerShare(
            currentShareSupply,
            currentBalance,
            pendingAmount,
            _decimals
        );

        // After closing the short, if the options expire in-the-money
        // vault pricePerShare would go down because vault's asset balance decreased.
        // This ensures that the newly-minted shares do not take on the loss.
        uint256 _mintShares =
            ShareMath.assetToShares(pendingAmount, newPricePerShare, _decimals);

        uint256 newSupply = currentShareSupply.add(_mintShares);
        uint256 queuedAmount =
            newSupply > 0
                ? ShareMath.sharesToAsset(
                    vaultState.queuedWithdrawShares,
                    newPricePerShare,
                    _decimals
                )
                : 0;

        return (
            currentBalance.sub(queuedAmount),
            queuedAmount,
            newPricePerShare,
            _mintShares
        );
    }

    /**
     * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
     * @param gammaController is the address of the opyn controller contract
     * @param marginPool is the address of the opyn margin contract which holds the collateral
     * @param oTokenAddress is the address of the otoken to mint
     * @param depositAmount is the amount of collateral to deposit
     * @return the otoken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address oTokenAddress,
        uint256 depositAmount
    ) external returns (uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID =
            (controller.getAccountVaultCounter(address(this))).add(1);

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IOtoken oToken = IOtoken(oTokenAddress);
        address collateralAsset = oToken.collateralAsset();

        uint256 collateralDecimals =
            uint256(IERC20Detailed(collateralAsset).decimals());
        uint256 mintAmount;

        mintAmount = depositAmount;
        if (collateralDecimals > 8) {
            uint256 scaleBy = 10**(collateralDecimals.sub(8)); // oTokens have 8 decimals
            if (mintAmount > scaleBy) {
                mintAmount = depositAmount.div(scaleBy); // scale down from 10**18 to 10**8
            }
        }

        IERC20 collateralToken = IERC20(collateralAsset);
        collateralToken.safeApprove(marginPool, depositAmount);

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](3);

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oTokenAddress, // option address
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        return mintAmount;
    }

    /**
     * @notice Withdraws stETH + WETH (if necessary) from vault using vault shares
     * @param collateralToken is the address of the collateral token
     * @param weth is the WETH address
     * @param recipient is the recipient
     * @param amount is the withdraw amount in `asset`
     * @return withdrawAmount is the withdraw amount in `collateralToken`
     */
    function withdrawYieldAndBaseToken(
        address collateralToken,
        address weth,
        address recipient,
        uint256 amount
    ) external returns (uint256) {
        IWSTETH collateral = IWSTETH(collateralToken);

        uint256 withdrawAmount = collateral.getWstETHByStETH(amount);

        uint256 yieldTokenBalance =
            withdrawYieldToken(collateralToken, recipient, withdrawAmount);

        // If there is not enough wstETH in the vault, it withdraws as much as possible and
        // transfers the rest in `asset`
        if (withdrawAmount > yieldTokenBalance) {
            withdrawBaseToken(
                collateralToken,
                weth,
                recipient,
                withdrawAmount,
                yieldTokenBalance
            );
        }

        return withdrawAmount;
    }

    /**
     * @notice Withdraws stETH from vault
     * @param collateralToken is the address of the collateral token
     * @param recipient is the recipient
     * @param withdrawAmount is the withdraw amount in terms of yearn tokens
     * @return yieldTokenBalance is the balance of the yield token
     */
    function withdrawYieldToken(
        address collateralToken,
        address recipient,
        uint256 withdrawAmount
    ) internal returns (uint256) {
        IERC20 collateral = IERC20(collateralToken);

        uint256 yieldTokenBalance = collateral.balanceOf(address(this));
        uint256 yieldTokensToWithdraw =
            DSMath.min(yieldTokenBalance, withdrawAmount);
        if (yieldTokensToWithdraw > 0) {
            collateral.safeTransfer(recipient, yieldTokensToWithdraw);
        }

        return yieldTokenBalance;
    }

    /**
     * @notice Withdraws `asset` from vault
     * @param collateralToken is the address of the collateral token
     * @param weth is the WETH address
     * @param recipient is the recipient
     * @param withdrawAmount is the withdraw amount in terms of yearn tokens
     * @param yieldTokenBalance is the collateral token (stETH) balance of the vault
     */
    function withdrawBaseToken(
        address collateralToken,
        address weth,
        address recipient,
        uint256 withdrawAmount,
        uint256 yieldTokenBalance
    ) internal {
        uint256 underlyingTokensToWithdraw =
            IWSTETH(collateralToken).getStETHByWstETH(
                withdrawAmount.sub(yieldTokenBalance)
            );

        IWETH(weth).deposit{value: underlyingTokensToWithdraw}();
        IERC20(weth).safeTransfer(recipient, underlyingTokensToWithdraw);
    }

    /**
     * @notice Unwraps the necessary amount of the wstETH token
     *         and transfers ETH amount to vault
     * @param amount is the amount of ETH to withdraw
     * @param wstEth is the address of wstETH
     * @param stethToken is the address of stETH
     * @param crvPool is the address of the steth <-> eth pool on curve
     * @param minETHOut is the minimum eth amount to receive from the swap
     * @return amountETHOut is the amount of eth unwrapped
     available for the withdrawal (may incur curve slippage)
     */
    function unwrapYieldToken(
        uint256 amount,
        address wstEth,
        address stethToken,
        address crvPool,
        uint256 minETHOut
    ) external returns (uint256) {
        require(
            amount >= minETHOut,
            "Amount withdrawn smaller than minETHOut from swap"
        );
        require(
            minETHOut.mul(10**18).div(amount) >= 0.95 ether,
            "Slippage on minETHOut too high"
        );

        uint256 ethBalance = address(this).balance;
        IERC20 steth = IERC20(stethToken);
        uint256 stethBalance = steth.balanceOf(address(this));

        // 3 different success scenarios
        // Scenario 1. We hold enough ETH to satisfy withdrawal. Send it out directly
        // Scenario 2. We hold enough wstETH to satisy withdrawal. Unwrap then swap
        // Scenario 3. We hold enough ETH + stETH to satisfy withdrawal. Do a swap

        // Scenario 1
        if (ethBalance >= amount) {
            return amount;
        }

        // Scenario 2
        stethBalance = unwrapWstethForWithdrawal(
            wstEth,
            steth,
            ethBalance,
            stethBalance,
            amount,
            minETHOut
        );

        // Scenario 3
        // Now that we satisfied the ETH + stETH sum, we swap the stETH amounts necessary
        // to facilitate a withdrawal

        // This won't underflow since we already asserted that ethBalance < amount before this
        uint256 stEthAmountToSwap =
            DSMath.min(amount.sub(ethBalance), stethBalance);

        uint256 ethAmountOutFromSwap =
            swapStEthToEth(steth, crvPool, stEthAmountToSwap);

        uint256 totalETHOut = ethBalance.add(ethAmountOutFromSwap);

        // Since minETHOut is derived from calling the Curve pool's getter,
        // it reverts in the worst case where the user needs to unwrap and sell
        // 100% of their ETH withdrawal amount
        require(
            totalETHOut >= minETHOut,
            "Output ETH amount smaller than minETHOut"
        );

        return totalETHOut;
    }

    /**
     * @notice Unwraps the required amount of wstETH to a target ETH amount
     * @param wstEthAddress is the address for wstETH
     * @param steth is the ERC20 of stETH
     * @param startStEthBalance is the starting stETH balance used to determine how much more to unwrap
     * @param ethAmount is the ETH amount needed for the contract
     * @param minETHOut is the ETH amount but adjusted for slippage
     * @return the new stETH balance
     */
    function unwrapWstethForWithdrawal(
        address wstEthAddress,
        IERC20 steth,
        uint256 ethBalance,
        uint256 startStEthBalance,
        uint256 ethAmount,
        uint256 minETHOut
    ) internal returns (uint256) {
        uint256 ethstEthSum = ethBalance.add(startStEthBalance);

        if (ethstEthSum < minETHOut) {
            uint256 stethNeededFromUnwrap = ethAmount.sub(ethstEthSum);
            IWSTETH wstEth = IWSTETH(wstEthAddress);
            uint256 wstAmountToUnwrap =
                wstEth.getWstETHByStETH(stethNeededFromUnwrap);

            wstEth.unwrap(wstAmountToUnwrap);

            uint256 newStEthBalance = steth.balanceOf(address(this));
            require(
                ethBalance.add(newStEthBalance) >= minETHOut,
                "Unwrapping wstETH did not return sufficient stETH"
            );
            return newStEthBalance;
        }
        return startStEthBalance;
    }

    /**
     * @notice Swaps from stEth to ETH on the Lido Curve pool
     * @param steth is the address for the Lido staked ether
     * @param crvPool is the Curve pool address to do the swap
     * @param stEthAmount is the stEth amount to be swapped to Ether
     * @return ethAmountOutFromSwap is the returned ETH amount from swap
     */
    function swapStEthToEth(
        IERC20 steth,
        address crvPool,
        uint256 stEthAmount
    ) internal returns (uint256) {
        steth.safeApprove(crvPool, stEthAmount);

        // CRV SWAP HERE from steth -> eth
        // 0 = ETH, 1 = STETH
        // We are setting 1, which is the smallest possible value for the _minAmountOut parameter
        // However it is fine because we check that the totalETHOut >= minETHOut at the end
        // which makes sandwich attacks not possible
        uint256 ethAmountOutFromSwap =
            ICRV(crvPool).exchange(1, 0, stEthAmount, 1);

        return ethAmountOutFromSwap;
    }

    /**
     * @notice Wraps the necessary amount of the base token to the yield-bearing yearn token
     * @param weth is the address of weth
     * @param collateralToken is the address of the collateral token
     */
    function wrapToYieldToken(
        address weth,
        address collateralToken,
        address steth
    ) external {
        // Unwrap all weth premiums transferred to contract
        IWETH wethToken = IWETH(weth);
        uint256 wethBalance = wethToken.balanceOf(address(this));

        if (wethBalance > 0) {
            wethToken.withdraw(wethBalance);
        }

        uint256 ethBalance = address(this).balance;

        IWSTETH collateral = IWSTETH(collateralToken);
        IERC20 stethToken = IERC20(steth);

        if (ethBalance > 0) {
            // Send eth to Lido, recieve steth
            ISTETH(steth).submit{value: ethBalance}(address(this));
        }

        // Get all steth in contract
        uint256 stethBalance = stethToken.balanceOf(address(this));

        if (stethBalance > 0) {
            // approve wrap
            stethToken.safeApprove(collateralToken, stethBalance.add(1));
            // Wrap to wstETH - need to add 1 to steth balance as it is innacurate
            collateral.wrap(stethBalance.add(1));
        }
    }

    /**
     * @notice Gets stETH for direct stETH withdrawals, converts wstETH/ETH to stETH if not enough stETH
     * @param steth is the address of steth
     * @param wstEth is the address of wsteth
     * @param amount is the amount to withdraw
     * @return amount of stETH to transfer to the user, this is to account for rounding errors when unwrapping wstETH
     */
    function withdrawStEth(
        address steth,
        address wstEth,
        uint256 amount
    ) external returns (uint256) {
        // 3 different scenarios for withdrawing stETH directly
        // Scenario 1. We hold enough stETH to satisfy withdrawal. Send it out directly
        // Scenario 2. We hold enough stETH + wstETH to satisy withdrawal. Unwrap wstETH then send it
        // Scenario 3. We hold enough stETH + wstETH + ETH satisfy withdrawal. Unwrap wstETH, wrap ETH then send it
        uint256 _amount = amount;
        uint256 stethBalance = IERC20(steth).balanceOf(address(this));
        if (stethBalance >= amount) {
            // Can send out the stETH directly
            return amount; // We return here if we have enough stETH to satisfy the withdrawal
        } else {
            // If amount > stethBalance, send out the entire stethBalance and check wstETH and ETH
            amount = amount.sub(stethBalance);
        }
        uint256 wstethBalance = IWSTETH(wstEth).balanceOf(address(this));
        uint256 totalShares = ISTETH(steth).getTotalShares();
        uint256 totalPooledEther = ISTETH(steth).getTotalPooledEther();
        stethBalance = wstethBalance.mul(totalPooledEther).div(totalShares);
        if (stethBalance >= amount) {
            wstethBalance = amount.mul(totalShares).div(totalPooledEther);
            // Avoids reverting if unwrap amount is 0
            if (wstethBalance > 0) {
                // Unwraps wstETH and sends out the received stETH directly
                IWSTETH(wstEth).unwrap(wstethBalance);
                // Accounts for rounding errors when unwrapping wstETH, this is safe because this function would've
                // returned already if the stETH balance was greater than our withdrawal amount
                return IERC20(steth).balanceOf(address(this)); // We return here if we have enough stETH + wstETH
            }
        } else if (stethBalance > 0) {
            stethBalance = IERC20(steth).balanceOf(address(this));
            IWSTETH(wstEth).unwrap(wstethBalance);
            // Accounts for rounding errors when unwrapping wstETH
            amount = amount.sub(
                IERC20(steth).balanceOf(address(this)).sub(stethBalance)
            );
        }
        // Wrap ETH to stETH if we don't have enough stETH + wstETH
        uint256 ethBalance = address(this).balance;
        if (amount > 0 && ethBalance >= amount) {
            ISTETH(steth).submit{value: amount}(address(this));
        } else if (ethBalance > 0) {
            ISTETH(steth).submit{value: ethBalance}(address(this));
        }
        stethBalance = IERC20(steth).balanceOf(address(this));
        // Accounts for rounding errors by a margin of 3 wei
        require(_amount.add(3) >= stethBalance, "Unwrapped too much stETH");
        require(_amount <= stethBalance.add(3), "Unwrapped insufficient stETH");
        return stethBalance; // We return here if we have enough stETH + wstETH + ETH
    }

    /**
     * @notice Helper function to make either an ETH transfer or ERC20 transfer
     * @param recipient is the receiving address
     * @param amount is the transfer amount
     */
    function transferAsset(address recipient, uint256 amount) public {
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "!success");
    }

    function getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        address collateralToken
    ) external view returns (uint256) {
        return
            _getOTokenPremium(
                oTokenAddress,
                optionsPremiumPricer,
                premiumDiscount,
                collateralToken
            );
    }

    function _getOTokenPremium(
        address oTokenAddress,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        address collateralToken
    ) internal view returns (uint256) {
        IOtoken newOToken = IOtoken(oTokenAddress);
        IOptionsPremiumPricer premiumPricer =
            IOptionsPremiumPricer(optionsPremiumPricer);

        // Apply black-scholes formula (from rvol library) to option given its features
        // and get price for 100 contracts denominated in the underlying asset for call option
        // and USDC for put option
        uint256 optionPremium =
            premiumPricer.getPremium(
                newOToken.strikePrice(),
                newOToken.expiryTimestamp(),
                newOToken.isPut()
            );

        // Apply a discount to incentivize arbitraguers
        optionPremium = optionPremium.mul(premiumDiscount).div(
            100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER
        );

        // get the black scholes premium of the option and adjust premium based on
        // steth <-> eth exchange rate
        uint256 adjustedPremium =
            DSMath.wmul(
                optionPremium,
                IWSTETH(collateralToken).stEthPerToken()
            );

        require(
            adjustedPremium <= type(uint96).max,
            "adjustedPremium > type(uint96) max value!"
        );
        require(adjustedPremium > 0, "!adjustedPremium");

        return adjustedPremium;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface IWSTETH {
    function getStETHByWstETH(uint256 _amount) external view returns (uint256);

    function getWstETHByStETH(uint256 _amount) external view returns (uint256);

    function stEthPerToken() external view returns (uint256);

    function tokensPerStEth() external view returns (uint256);

    function stETH() external view returns (address);

    function wrap(uint256 _amount) external returns (uint256);

    function unwrap(uint256 _amount) external returns (uint256);

    function approve(address _recipient, uint256 _amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

interface ISTETH {
    function getBufferedEther(uint256 _amount) external view returns (uint256);

    function getPooledEthByShares(uint256 _amount)
        external
        view
        returns (uint256);

    function getSharesByPooledEth(uint256 _amount)
        external
        view
        returns (uint256);

    function submit(address _referralAddress)
        external
        payable
        returns (uint256);

    function withdraw(uint256 _amount, bytes32 _pubkeyHash)
        external
        returns (uint256);

    function approve(address _recipient, uint256 _amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getTotalPooledEther() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

interface ICRV {
    function get_dy(
        int128 _indexIn,
        int128 _indexOut,
        uint256 _amountIn
    ) external view returns (uint256);

    // https://github.com/curvefi/curve-contract/blob/
    // b0bbf77f8f93c9c5f4e415bce9cd71f0cdee960e/contracts/pools/steth/StableSwapSTETH.vy#L431
    function exchange(
        int128 _indexIn,
        int128 _indexOut,
        uint256 _amountIn,
        uint256 _minAmountOut
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {
    IPriceOracle
} from "../interfaces/IPriceOracle.sol";
import {IOptionsPremiumPricer} from "../interfaces/IRibbon.sol";
import {
    IManualVolatilityOracle
} from "../interfaces/IManualVolatilityOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {Vault} from "../libraries/Vault.sol";

contract DeltaStrikeSelection is Ownable {
    using SafeMath for uint256;

    /**
     * Immutables
     */
    IOptionsPremiumPricer public immutable optionsPremiumPricer;

    IManualVolatilityOracle public immutable volatilityOracle;

    // delta for options strike price selection. 1 is 10000 (10**4)
    uint256 public delta;

    // step in absolute terms at which we will increment
    // (ex: 100 * 10 ** assetOracleDecimals means we will move at increments of 100 points)
    uint256 public step;

    // multiplier to shift asset prices
    uint256 private immutable assetOracleMultiplier;

    // Delta are in 4 decimal places. 1 * 10**4 = 1 delta.
    uint256 private constant DELTA_MULTIPLIER = 10**4;

    // ChainLink's USD Price oracles return results in 8 decimal places
    uint256 private constant ORACLE_PRICE_MULTIPLIER = 10**8;

    event DeltaSet(uint256 oldDelta, uint256 newDelta, address indexed owner);
    event StepSet(uint256 oldStep, uint256 newStep, address indexed owner);

    constructor(
        address _optionsPremiumPricer,
        uint256 _delta,
        uint256 _step
    ) {
        require(_optionsPremiumPricer != address(0), "!_optionsPremiumPricer");
        require(_delta > 0, "!_delta");
        require(_delta <= DELTA_MULTIPLIER, "newDelta cannot be more than 1");
        require(_step > 0, "!_step");

        optionsPremiumPricer = IOptionsPremiumPricer(_optionsPremiumPricer);
        volatilityOracle = IManualVolatilityOracle(
            IOptionsPremiumPricer(_optionsPremiumPricer).volatilityOracle()
        );
        // ex: delta = 7500 (.75)
        delta = _delta;
        uint256 _assetOracleMultiplier =
            10 **
                IPriceOracle(
                    IOptionsPremiumPricer(_optionsPremiumPricer).priceOracle()
                )
                    .decimals();

        step = _step;

        assetOracleMultiplier = _assetOracleMultiplier;
    }

    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */
    function getStrikePrice(uint256 expiryTimestamp, bool isPut)
        external
        view
        returns (uint256 newStrikePrice, uint256 newDelta)
    {
        // asset's annualized volatility
        uint256 annualizedVol =
            volatilityOracle.annualizedVol(optionsPremiumPricer.optionId()).mul(
                10**10
            );
        return _getStrikePrice(expiryTimestamp, isPut, annualizedVol);
    }

    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @param annualizedVol is IV of the asset at the specified delta
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */
    function getStrikePriceWithVol(
        uint256 expiryTimestamp,
        bool isPut,
        uint256 annualizedVol
    ) external view returns (uint256 newStrikePrice, uint256 newDelta) {
        return
            _getStrikePrice(expiryTimestamp, isPut, annualizedVol.mul(10**10));
    }

    /**
     * @notice Gets the strike price satisfying the delta value
     * given the expiry timestamp and whether option is call or put
     * @param expiryTimestamp is the unix timestamp of expiration
     * @param isPut is whether option is put or call
     * @return newStrikePrice is the strike price of the option (ex: for BTC might be 45000 * 10 ** 8)
     * @return newDelta is the delta of the option given its parameters
     */

    function _getStrikePrice(
        uint256 expiryTimestamp,
        bool isPut,
        uint256 annualizedVol
    ) internal view returns (uint256 newStrikePrice, uint256 newDelta) {
        require(
            expiryTimestamp > block.timestamp,
            "Expiry must be in the future!"
        );

        // asset price
        uint256 assetPrice = optionsPremiumPricer.getUnderlyingPrice();

        // For each asset prices with step of 'step' (down if put, up if call)
        //   if asset's getOptionDelta(currStrikePrice, spotPrice, annualizedVol, t) == (isPut ? 1 - delta:delta)
        //   with certain margin of error
        //        return strike price

        uint256 strike =
            isPut
                ? assetPrice.sub(assetPrice % step).sub(step)
                : assetPrice.add(step - (assetPrice % step)).add(step);
        uint256 targetDelta = isPut ? DELTA_MULTIPLIER.sub(delta) : delta;
        uint256 prevDelta = isPut ? 0 : DELTA_MULTIPLIER;

        while (true) {
            uint256 currDelta =
                optionsPremiumPricer.getOptionDelta(
                    assetPrice.mul(ORACLE_PRICE_MULTIPLIER).div(
                        assetOracleMultiplier
                    ),
                    strike,
                    annualizedVol,
                    expiryTimestamp
                );
            //  If the current delta is between the previous
            //  strike price delta and current strike price delta
            //  then we are done
            bool foundTargetStrikePrice =
                isPut
                    ? targetDelta >= prevDelta && targetDelta <= currDelta
                    : targetDelta <= prevDelta && targetDelta >= currDelta;

            if (foundTargetStrikePrice) {
                uint256 finalDelta =
                    _getBestDelta(prevDelta, currDelta, targetDelta, isPut);
                uint256 finalStrike =
                    _getBestStrike(finalDelta, prevDelta, strike, isPut);
                require(
                    isPut
                        ? finalStrike <= assetPrice
                        : finalStrike >= assetPrice,
                    "Invalid strike price"
                );
                // make decimals consistent with oToken strike price decimals (10 ** 8)
                return (
                    finalStrike.mul(ORACLE_PRICE_MULTIPLIER).div(
                        assetOracleMultiplier
                    ),
                    finalDelta
                );
            }

            strike = isPut ? strike.sub(step) : strike.add(step);

            prevDelta = currDelta;
        }
    }

    /**
     * @notice Rounds to best delta value
     * @param prevDelta is the delta of the previous strike price
     * @param currDelta is delta of the current strike price
     * @param targetDelta is the delta we are targeting
     * @param isPut is whether its a put
     * @return the best delta value
     */
    function _getBestDelta(
        uint256 prevDelta,
        uint256 currDelta,
        uint256 targetDelta,
        bool isPut
    ) private pure returns (uint256) {
        uint256 finalDelta;

        // for tie breaks (ex: 0.05 <= 0.1 <= 0.15) round to higher strike price
        // for calls and lower strike price for puts for deltas
        if (isPut) {
            uint256 upperBoundDiff = currDelta.sub(targetDelta);
            uint256 lowerBoundDiff = targetDelta.sub(prevDelta);
            finalDelta = lowerBoundDiff <= upperBoundDiff
                ? prevDelta
                : currDelta;
        } else {
            uint256 upperBoundDiff = prevDelta.sub(targetDelta);
            uint256 lowerBoundDiff = targetDelta.sub(currDelta);
            finalDelta = lowerBoundDiff <= upperBoundDiff
                ? currDelta
                : prevDelta;
        }

        return finalDelta;
    }

    /**
     * @notice Rounds to best delta value
     * @param finalDelta is the best delta value we found
     * @param prevDelta is delta of the previous strike price
     * @param strike is the strike of the previous iteration
     * @param isPut is whether its a put
     * @return the best strike
     */
    function _getBestStrike(
        uint256 finalDelta,
        uint256 prevDelta,
        uint256 strike,
        bool isPut
    ) private view returns (uint256) {
        if (finalDelta != prevDelta) {
            return strike;
        }
        return isPut ? strike.add(step) : strike.sub(step);
    }

    /**
     * @notice Sets new delta value
     * @param newDelta is the new delta value
     */
    function setDelta(uint256 newDelta) external onlyOwner {
        require(newDelta > 0, "!newDelta");
        require(newDelta <= DELTA_MULTIPLIER, "newDelta cannot be more than 1");
        uint256 oldDelta = delta;
        delta = newDelta;
        emit DeltaSet(oldDelta, newDelta, msg.sender);
    }

    /**
     * @notice Sets new step value
     * @param newStep is the new step value
     */
    function setStep(uint256 newStep) external onlyOwner {
        require(newStep > 0, "!newStep");
        uint256 oldStep = step;
        step = newStep;
        emit StepSet(oldStep, newStep, msg.sender);
    }
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface IPriceOracle {
    function decimals() external view returns (uint256 _decimals);

    function latestAnswer() external view returns (uint256 price);
}

//SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.4;

interface IManualVolatilityOracle {
    function vol(bytes32 optionId)
        external
        view
        returns (uint256 standardDeviation);

    function annualizedVol(bytes32 optionId)
        external
        view
        returns (uint256 annualStdev);

    function setAnnualizedVol(
        bytes32[] calldata optionIds,
        uint256[] calldata newAnnualizedVols
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Vault} from "../libraries/Vault.sol";
import {ShareMath} from "../libraries/ShareMath.sol";
import {ILiquidity} from "../interfaces/ILiquidity.sol";

contract AuxVaults is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ERC20Upgradeable
{

    /************************************************
     *  IMMUTABLES & CONSTANTS
     ***********************************************/


    
    /************************************************
     *  NON UPGRADEABLE STORAGE
     ***********************************************/
    
    ILiquidity public pool;

    address public keeper;

     uint256 INITIAL_MARGIN_RATIO;
    uint256 MAINTENANCE_MARGIN_RATIO;
    uint256 PARTIAL_LIQUIDATION_RATIO;
    
    /************************************************
     *  EVENTS
     ***********************************************/

    event Liquidate(
        address indexed liquidator,
        uint256 totalAdjustedShares,
        uint256 liquidationPenalty,
        uint256 penaltyToBot,
        uint256 badDebt
    );

    function initialize(
        address _owner,
        address _keeper,
        address _vault,
        address _pool
    ) external initializer {
        require(
            _vault != address(0),
            "!_optionsPremiumPricer"
        );
        
        __ReentrancyGuard_init();        
        __Ownable_init();
        
        transferOwnership(_owner);
        keeper = _keeper;
        pool = ILiquidity(_pool);
    }

    /**
     * @dev Throws if called by any account other than the keeper.
     */
    modifier onlyKeeper() {
        require(msg.sender == keeper, "!keeper");
        _;
    }


    /**
     * @notice Set InitMargin Ratio
     */
    function setInitMarginRatio(uint256 _ratio) external onlyOwner {
        require(_ratio > 0, "margin ratio can't be zero");
        INITIAL_MARGIN_RATIO = _ratio;
    }

    /**
     * @notice Set Maintanance MarginRatio
     */
    function setMaintananceMarginRatio(uint256 _ratio) external onlyOwner {
        require(_ratio > 0, "margin ratio can't be zero");
        MAINTENANCE_MARGIN_RATIO = _ratio;
    }

    /**
     * @notice Set Maintanance MarginRatio
     */
    function setPartialLiquidationRatio(uint256 _ratio) external onlyOwner {
        require(_ratio > 0, "invalid partial liquidation ratio");
        PARTIAL_LIQUIDATION_RATIO = _ratio;
    }


    // /**
    //  * @notice check Liquidate state for many user Position
    //  */
    // function isliquidatableMany(address[] users) external returns(address[]) {
    //     require(users.length < 101, "Address list is too long.");
    //     address[] userList;
    //     for (uint256 i = 0; i <= users.length; i++) {
    //        (bool isLiquidate, uint256 marginRatio, 
    //         uint256 newEquityShares ,uint256 newDebtShares) =  isLiquidatable(users[i]);
    //         if(isLiquidate){
    //             userList.push(users[i]);
    //         }
    //     }
    //     return userList;
    // }

    // /**
    //  * @notice Liquidate many user Position
    //  */
    // function liquidateMany(address[] users) external onlyKeeper nonReentrant {
    //     require(users.length < 51, "Address list is too long.");
    //     for (uint256 i = 0; i <= users.length; i++) {
    //         _liquidate(users[i]);
    //     }
    // }

    /**
     * @notice Liquidate user Position
     */
    // function _liquidate(address user) internal nonReentrant {
    //     require(user != address(0), "address required");

    //     (bool isLiquidate, uint256 marginRatio, 
    //         uint256 newEquityShares ,uint256 newDebtShares) =  isLiquidatable(user);

    //     //Check liquidation creiteria
    //     require(isLiquidate, "Margin ratio not meet criteria for liquidation");

    //     uint256 repayBalanceShares = (newDebtShares.mul(dps)).div(pps);

    //     uint256 reapyShares;
    //     uint256 penaltyShares;
    //     uint256 badDebt;

    //     if (marginRatio < INITIAL_MARGIN_RATIO >= MAINTENANCE_MARGIN_RATIO) {
    //         // Partial Liquidation
    //         reapyShares = (
    //             repayBalanceShares.mul(PARTIAL_LIQUIDATION_RATIO)
    //         ).div(10**18);
    //         penaltyShares = reapyShares.mul(25).div(1000);
    //     } else if (marginRatio < MAINTENANCE_MARGIN_RATIO) {
    //         // Full Liquidation
    //         reapyShares = repayBalanceShares;
    //         penaltyShares = reapyShares.mul(25).div(1000);
    //     }

    //     uint256 totalAdjustedShares = reapyShares + penaltyShares;
    //     uint256 liquidationPenalty = penaltyShares.mul(pps);
    //     uint256 penaltyToBot = liquidationPenalty.div(2);
    //     uint256 penaltyToInsuranceFund = penaltyToBot;

    //     if (marginRatio < 0) {
    //         userDebtShares[msg.sender] = 0;
    //         badDebt = totalAdjustedShares.mul(pps);
    //         _transfer(msg.sender, address(this), totalAdjustedShares);
    //         _burn(address(this), totalAdjustedShares);
    //     } else {
    //         initiateRepay(totalAdjustedShares);
    //     }

    //     ///TODO move to vault
    //     //Send penalty amount to liquidator bot
    //     IERC20(vaultParams.asset).safeTransfer(msg.sender, penaltyToBot);
    //     //Send penalty amount to insurance fund
    //     IERC20(vaultParams.asset).safeTransfer(
    //         INSURANCE_FUND,
    //         penaltyToInsuranceFund
    //     );

    //     emit Liquidate(
    //         msg.sender,
    //         totalAdjustedShares,
    //         liquidationPenalty,
    //         penaltyToBot,
    //         badDebt
    //     );
    // }

    //     /**
    //  * @notice isLiquidatable checks user Position
    //  */
    // function isLiquidatable(address user) public view returns (bool, uint256,uint256,uint256){
    //     require(user != address(0), "address required");
    //     // nUEx => Net User Equity = ((userVaultSahres - Vault Withdrawal Receipt -  Repay Receipt of trader) x Price Per share valut + Deposit Receipt)
    //     Vault.DepositReceipt memory depositReceipt = vault.depositReceipts[msg.sender];

    //     uint256 pps = vault.roundPricePerShare[vaultState.round - 1];
    //     uint256 newUserEquity = (vault.shares(user).mul(pps)).add(depositReceipt.amount);
    //     uint256 newUserEquityShares = ShareMath.sharesToAsset(newUserEquity, pps, _decimals);

    //     //nUDx => Net User Debt = ((User Debt Shares - Repay Receipt x Price Per share valut / Debt Per Share) x Debt Per Share + borrow receipt)
    //     LeverageVault.BorrowReceipt memory borrowReceipt = borrowReceipts[user];
    //     (uint256 dps, ) = pool.pricePerShares(pool.currentRound() - 1);
    //     uint256 userDebtShares = vault.userDebtShares[msg.sender];
    //     uint256 newuserDebt = ((userDebtShares.mul(pps).div(dps)).mul(dps)).add(borrowReceipt.amount);
    //     uint256 newuserDebtShares = ShareMath.sharesToAsset(newuserDebt, pps, _decimals);
    //     uint256 marginRatio = (newUserEquityShares)
    //         .sub(newuserDebtSharesShares)
    //         .mul(10**4)
    //         .div(newUserEquityShares);

    //     bool isLiquidatable = marginRatio > INITIAL_MARGIN_RATIO;
    //     return(isLiquidatable, marginRatio, newUserEquityShares, newUserDebtShares);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {Vault} from "../libraries/Vault.sol";

abstract contract RibbonTreasuryVaultStorageV1 {
    /// @notice Vault's parameters like cap, decimals
    Vault.VaultParams public vaultParams;

    /// @notice Vault's lifecycle state like round and locked amounts
    Vault.VaultState public vaultState;

    /// @notice Vault's state of the options sold and the timelocked option
    Vault.OptionState public optionState;

    /// @notice Stores the user's pending deposit for the round
    mapping(address => Vault.DepositReceipt) public depositReceipts;

    /// @notice On every round's close, the pricePerShare value of an rTHETA token is stored
    /// This is used to determine the number of shares to be returned
    /// to a user with their DepositReceipt.depositAmount
    mapping(uint256 => uint256) public roundPricePerShare;

    /// @notice Stores pending user withdrawals
    mapping(address => Vault.Withdrawal) public withdrawals;

    /// @notice Mapping of depositors in the vault
    mapping(address => bool) public depositorsMap;

    /// @notice Array of depositors in the vault
    address[] public depositorsArray;

    /// @notice Fee recipient for the performance and management fees
    address public feeRecipient;

    /// @notice role in charge of weekly vault operations such as rollToNextOption and burnRemainingOTokens
    // no access to critical vault changes
    address public keeper;

    /// @notice Logic contract used to price options
    address public optionsPremiumPricer;

    /// @notice Logic contract used to select strike prices
    address public strikeSelection;

    /// @notice Performance fee charged on premiums earned in rollToNextOption. Only charged when there is no loss.
    uint256 public performanceFee;

    /// @notice Management fee charged on entire AUM in rollToNextOption. Only charged when there is no loss.
    uint256 public managementFee;

    /// @notice Premium discount on options we are selling (thousandths place: 000 - 999)
    uint256 public premiumDiscount;

    /// @notice Current oToken premium
    uint256 public currentOtokenPremium;

    /// @notice Price last overridden strike set to
    uint256 public overriddenStrikePrice;

    /// @notice Auction duration
    uint256 public auctionDuration;

    /// @notice Auction id of current option
    uint256 public optionAuctionID;

    /// @notice Amount locked for scheduled withdrawals last week;
    uint256 public lastQueuedWithdrawAmount;

    /// @notice Period between each options sale.
    /// Available options 7 (weekly), 14 (biweekly), 30 (monthly), 90 (quarterly), 180 (biannually)
    uint256 public period;

    /// @notice Maximum number of depositors
    uint256 public maxDepositors;

    /// @notice Minimum amount to deposit
    uint256 public minDeposit;

    /// @notice Last round id at which the strike was manually overridden
    uint16 public lastStrikeOverrideRound;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of RibbonTreasuryVaultStorage
// e.g. RibbonTreasuryVaultStorage<versionNumber>, so finally it would look like
// contract RibbonTreasuryVaultStorage is RibbonTreasuryVaultStorageV1, RibbonTreasuryVaultStorageV2
abstract contract RibbonTreasuryVaultStorage is RibbonTreasuryVaultStorageV1 {

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;
import {IRibbonThetaVault} from "../interfaces/IRibbonThetaVault.sol";
import {Vault} from "../libraries/Vault.sol";

abstract contract RibbonDeltaVaultStorageV1 {
    // Ribbon counterparty theta vault
    IRibbonThetaVault public counterpartyThetaVault;
    // % of funds to be used for weekly option purchase
    uint256 public optionAllocation;
    // Delta vault equivalent of lockedAmount
    uint256 public balanceBeforePremium;
    // User Id of delta vault in latest gnosis auction
    Vault.AuctionSellOrder public auctionSellOrder;
}

abstract contract RibbonDeltaVaultStorageV2 {
    // Amount locked for scheduled withdrawals last week;
    uint128 public lastQueuedWithdrawAmount;
}

// We are following Compound's method of upgrading new contract implementations
// When we need to add new storage variables, we create a new version of RibbonDeltaVaultStorage
// e.g. RibbonDeltaVaultStorage<versionNumber>, so finally it would look like
// contract RibbonDeltaVaultStorage is RibbonDeltaVaultStorageV1, RibbonDeltaVaultStorageV2
abstract contract RibbonDeltaVaultStorage is
    RibbonDeltaVaultStorageV1,
    RibbonDeltaVaultStorageV2
{

}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Vault} from "./Vault.sol";
import {ShareMath} from "./ShareMath.sol";
import {IStrikeSelection} from "../interfaces/IRibbon.sol";
import {GnosisAuction} from "./GnosisAuction.sol";
import {DateTime} from "./DateTime.sol";
import {
    IOtokenFactory,
    IOtoken,
    IController,
    GammaTypes
} from "../interfaces/GammaInterface.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {IGnosisAuction} from "../interfaces/IGnosisAuction.sol";
import {SupportsNonCompliantERC20} from "./SupportsNonCompliantERC20.sol";

library VaultLifecycleTreasury {
    using SafeMath for uint256;
    using SupportsNonCompliantERC20 for IERC20;

    struct CloseParams {
        address OTOKEN_FACTORY;
        address USDC;
        address currentOption;
        uint256 delay;
        uint16 lastStrikeOverrideRound;
        uint256 overriddenStrikePrice;
        uint256 period;
    }

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _tokenName is the name of the token
     * @param _tokenSymbol is the symbol of the token
     * @param _optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param _strikeSelection is the address of the contract with strike selection logic
     * @param _premiumDiscount is the vault's discount applied to the premium
     * @param _auctionDuration is the duration of the gnosis auction
     * @param _period is the period between each option sales
     */
    struct InitParams {
        address _owner;
        address _keeper;
        address _feeRecipient;
        uint256 _managementFee;
        uint256 _performanceFee;
        string _tokenName;
        string _tokenSymbol;
        address _optionsPremiumPricer;
        address _strikeSelection;
        uint32 _premiumDiscount;
        uint256 _auctionDuration;
        uint256 _period;
        uint256 _maxDepositors;
        uint256 _minDeposit;
    }

    /**
     * @notice Sets the next option the vault will be shorting, and calculates its premium for the auction
     * @param strikeSelection is the address of the contract with strike selection logic
     * @param optionsPremiumPricer is the address of the contract with the
       black-scholes premium calculation logic
     * @param premiumDiscount is the vault's discount applied to the premium
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param vaultState is the struct with vault accounting state
     * @return otokenAddress is the address of the new option
     * @return premium is the premium of the new option
     * @return strikePrice is the strike price of the new option
     * @return delta is the delta of the new option
     */
    function commitAndClose(
        address strikeSelection,
        address optionsPremiumPricer,
        uint256 premiumDiscount,
        CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        Vault.VaultState storage vaultState
    )
        external
        returns (
            address otokenAddress,
            uint256 premium,
            uint256 strikePrice,
            uint256 delta
        )
    {
        uint256 expiry;

        // uninitialized state
        if (closeParams.currentOption == address(0)) {
            expiry = getNextExpiry(block.timestamp, closeParams.period);
        } else {
            expiry = getNextExpiry(
                IOtoken(closeParams.currentOption).expiryTimestamp(),
                closeParams.period
            );
        }

        IStrikeSelection selection = IStrikeSelection(strikeSelection);

        bool isPut = vaultParams.isPut;
        address underlying = vaultParams.underlying;
        address asset = vaultParams.asset;

        (strikePrice, delta) = closeParams.lastStrikeOverrideRound ==
            vaultState.round
            ? (closeParams.overriddenStrikePrice, 0)
            : selection.getStrikePrice(expiry, isPut);

        require(strikePrice != 0, "!strikePrice");

        // retrieve address if option already exists, or deploy it
        otokenAddress = getOrDeployOtoken(
            closeParams,
            vaultParams,
            underlying,
            asset,
            strikePrice,
            expiry,
            isPut
        );

        // get the black scholes premium of the option
        premium = GnosisAuction.getOTokenPremiumInStables(
            otokenAddress,
            optionsPremiumPricer,
            premiumDiscount
        );

        require(premium > 0, "!premium");

        return (otokenAddress, premium, strikePrice, delta);
    }

    /**
     * @notice Verify the otoken has the correct parameters to prevent vulnerability to opyn contract changes
     * @param otokenAddress is the address of the otoken
     * @param vaultParams is the struct with vault general data
     * @param collateralAsset is the address of the collateral asset
     * @param USDC is the address of usdc
     * @param delay is the delay between commitAndClose and rollToNextOption
     */
    function verifyOtoken(
        address otokenAddress,
        Vault.VaultParams storage vaultParams,
        address collateralAsset,
        address USDC,
        uint256 delay
    ) private view {
        require(otokenAddress != address(0), "!otokenAddress");

        IOtoken otoken = IOtoken(otokenAddress);
        require(otoken.isPut() == vaultParams.isPut, "Type mismatch");
        require(
            otoken.underlyingAsset() == vaultParams.underlying,
            "Wrong underlyingAsset"
        );
        require(
            otoken.collateralAsset() == collateralAsset,
            "Wrong collateralAsset"
        );

        // we just assume all options use USDC as the strike
        require(otoken.strikeAsset() == USDC, "strikeAsset != USDC");

        uint256 readyAt = block.timestamp.add(delay);
        require(otoken.expiryTimestamp() >= readyAt, "Expiry before delay");
    }

    /**
     * @param currentShareSupply is the supply of the shares invoked with totalSupply()
     * @param asset is the address of the vault's asset
     * @param decimals is the decimals of the asset
     * @param lastQueuedWithdrawAmount is the amount queued for withdrawals from last round
     * @param managementFee is the management fee percent to charge on the AUM
     */
    struct RolloverParams {
        uint256 decimals;
        uint256 totalBalance;
        uint256 currentShareSupply;
        uint256 lastQueuedWithdrawAmount;
        uint256 managementFee;
    }

    /**
     * @notice Calculate the shares to mint, new price per share, and
      amount of funds to re-allocate as collateral for the new round
     * @param vaultState is the storage variable vaultState passed from RibbonVault
     * @param params is the rollover parameters passed to compute the next state
     * @return newLockedAmount is the amount of funds to allocate for the new round
     * @return queuedWithdrawAmount is the amount of funds set aside for withdrawal
     * @return newPricePerShare is the price per share of the new round
     * @return mintShares is the amount of shares to mint from deposits
     * @return managementFeeInAsset is the amount of management fee charged by vault
     */
    function rollover(
        Vault.VaultState storage vaultState,
        RolloverParams calldata params
    )
        external
        view
        returns (
            uint256 newLockedAmount,
            uint256 queuedWithdrawAmount,
            uint256 newPricePerShare,
            uint256 mintShares,
            uint256 managementFeeInAsset
        )
    {
        uint256 currentBalance = params.totalBalance;
        uint256 pendingAmount = vaultState.totalPending;
        uint256 queuedWithdrawShares = vaultState.queuedWithdrawShares;

        uint256 balanceForVaultFees;
        {
            uint256 pricePerShareBeforeFee =
                ShareMath.pricePerShare(
                    params.currentShareSupply,
                    currentBalance,
                    pendingAmount,
                    params.decimals
                );

            uint256 queuedWithdrawBeforeFee =
                params.currentShareSupply > 0
                    ? ShareMath.sharesToAsset(
                        queuedWithdrawShares,
                        pricePerShareBeforeFee,
                        params.decimals
                    )
                    : 0;

            // Deduct the difference between the newly scheduled withdrawals
            // and the older withdrawals
            // so we can charge them fees before they leave
            uint256 withdrawAmountDiff =
                queuedWithdrawBeforeFee > params.lastQueuedWithdrawAmount
                    ? queuedWithdrawBeforeFee.sub(
                        params.lastQueuedWithdrawAmount
                    )
                    : 0;

            balanceForVaultFees = currentBalance
                .sub(queuedWithdrawBeforeFee)
                .add(withdrawAmountDiff);
        }

        managementFeeInAsset = getManagementFee(
            balanceForVaultFees,
            vaultState.totalPending,
            params.managementFee
        );

        // Take into account the fee
        // so we can calculate the newPricePerShare
        currentBalance = currentBalance.sub(managementFeeInAsset);

        {
            newPricePerShare = ShareMath.pricePerShare(
                params.currentShareSupply,
                currentBalance,
                pendingAmount,
                params.decimals
            );

            // After closing the short, if the options expire in-the-money
            // vault pricePerShare would go down because vault's asset balance decreased.
            // This ensures that the newly-minted shares do not take on the loss.
            mintShares = ShareMath.assetToShares(
                pendingAmount,
                newPricePerShare,
                params.decimals
            );

            uint256 newSupply = params.currentShareSupply.add(mintShares);

            queuedWithdrawAmount = newSupply > 0
                ? ShareMath.sharesToAsset(
                    queuedWithdrawShares,
                    newPricePerShare,
                    params.decimals
                )
                : 0;
        }

        return (
            currentBalance.sub(queuedWithdrawAmount), // new locked balance subtracts the queued withdrawals
            queuedWithdrawAmount,
            newPricePerShare,
            mintShares,
            managementFeeInAsset
        );
    }

    /**
     * @notice Creates the actual Opyn short position by depositing collateral and minting otokens
     * @param gammaController is the address of the opyn controller contract
     * @param marginPool is the address of the opyn margin contract which holds the collateral
     * @param oTokenAddress is the address of the otoken to mint
     * @param depositAmount is the amount of collateral to deposit
     * @return the otoken mint amount
     */
    function createShort(
        address gammaController,
        address marginPool,
        address oTokenAddress,
        uint256 depositAmount
    ) external returns (uint256) {
        IController controller = IController(gammaController);
        uint256 newVaultID =
            (controller.getAccountVaultCounter(address(this))).add(1);

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IOtoken oToken = IOtoken(oTokenAddress);
        address collateralAsset = oToken.collateralAsset();

        uint256 collateralDecimals =
            uint256(IERC20Detailed(collateralAsset).decimals());
        uint256 mintAmount;

        if (oToken.isPut()) {
            // For minting puts, there will be instances where the full depositAmount will not be used for minting.
            // This is because of an issue with precision.
            //
            // For ETH put options, we are calculating the mintAmount (10**8 decimals) using
            // the depositAmount (10**18 decimals), which will result in truncation of decimals when scaling down.
            // As a result, there will be tiny amounts of dust left behind in the Opyn vault when minting put otokens.
            //
            // For simplicity's sake, we do not refund the dust back to the address(this) on minting otokens.
            // We retain the dust in the vault so the calling contract can withdraw the
            // actual locked amount + dust at settlement.
            //
            // To test this behavior, we can console.log
            // MarginCalculatorInterface(0x7A48d10f372b3D7c60f6c9770B91398e4ccfd3C7).getExcessCollateral(vault)
            // to see how much dust (or excess collateral) is left behind.
            mintAmount = depositAmount
                .mul(10**Vault.OTOKEN_DECIMALS)
                .mul(10**18) // we use 10**18 to give extra precision
                .div(oToken.strikePrice().mul(10**(10 + collateralDecimals)));
        } else {
            mintAmount = depositAmount;

            if (collateralDecimals > 8) {
                uint256 scaleBy = 10**(collateralDecimals.sub(8)); // oTokens have 8 decimals
                if (mintAmount > scaleBy) {
                    mintAmount = depositAmount.div(scaleBy); // scale down from 10**18 to 10**8
                }
            }
        }

        // double approve to fix non-compliant ERC20s
        IERC20 collateralToken = IERC20(collateralAsset);
        collateralToken.safeApproveNonCompliant(marginPool, depositAmount);

        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](3);

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            newVaultID, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            newVaultID, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        actions[2] = IController.ActionArgs(
            IController.ActionType.MintShortOption,
            address(this), // owner
            address(this), // address to transfer to
            oTokenAddress, // option address
            newVaultID, // vaultId
            mintAmount, // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        return mintAmount;
    }

    /**
     * @notice Close the existing short otoken position. Currently this implementation is simple.
     * It closes the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time. Since calling `_closeShort` deletes vaults by
     calling SettleVault action, this assumption should hold.
     * @param gammaController is the address of the opyn controller contract
     * @return amount of collateral redeemed from the vault
     */
    function settleShort(address gammaController) external returns (uint256) {
        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        // An otoken's collateralAsset is the vault's `asset`
        // So in the context of performing Opyn short operations we call them collateralAsset
        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        // The short position has been previously closed, or all the otokens have been burned.
        // So we return early.
        if (address(collateralToken) == address(0)) {
            return 0;
        }

        // This is equivalent to doing IERC20(vault.asset).balanceOf(address(this))
        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // If it is after expiry, we need to settle the short position using the normal way
        // Delete the vault and withdraw all remaining collateral from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultID, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Exercises the ITM option using existing long otoken position. Currently this implementation is simple.
     * It calls the `Redeem` action to claim the payout.
     * @param gammaController is the address of the opyn controller contract
     * @param oldOption is the address of the old option
     * @param asset is the address of the vault's asset
     * @return amount of asset received by exercising the option
     */
    function settleLong(
        address gammaController,
        address oldOption,
        address asset
    ) external returns (uint256) {
        IController controller = IController(gammaController);

        uint256 oldOptionBalance = IERC20(oldOption).balanceOf(address(this));

        if (controller.getPayout(oldOption, oldOptionBalance) == 0) {
            return 0;
        }

        uint256 startAssetBalance = IERC20(asset).balanceOf(address(this));

        // If it is after expiry, we need to redeem the profits
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](1);

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oldOption, // address of otoken
            0, // not used
            oldOptionBalance, // otoken balance
            0, // not used
            "" // not used
        );

        controller.operate(actions);

        uint256 endAssetBalance = IERC20(asset).balanceOf(address(this));

        return endAssetBalance.sub(startAssetBalance);
    }

    /**
     * @notice Burn the remaining oTokens left over from auction. Currently this implementation is simple.
     * It burns oTokens from the most recent vault opened by the contract. This assumes that the contract will
     * only have a single vault open at any given time.
     * @param gammaController is the address of the opyn controller contract
     * @param currentOption is the address of the current option
     * @return amount of collateral redeemed by burning otokens
     */
    function burnOtokens(address gammaController, address currentOption)
        external
        returns (uint256)
    {
        uint256 numOTokensToBurn =
            IERC20(currentOption).balanceOf(address(this));

        require(numOTokensToBurn > 0, "No oTokens to burn");

        IController controller = IController(gammaController);

        // gets the currently active vault ID
        uint256 vaultID = controller.getAccountVaultCounter(address(this));

        GammaTypes.Vault memory vault =
            controller.getVault(address(this), vaultID);

        require(vault.shortOtokens.length > 0, "No short");

        IERC20 collateralToken = IERC20(vault.collateralAssets[0]);

        uint256 startCollateralBalance =
            collateralToken.balanceOf(address(this));

        // Burning `amount` of oTokens from the ribbon vault,
        // then withdrawing the corresponding collateral amount from the vault
        IController.ActionArgs[] memory actions =
            new IController.ActionArgs[](2);

        actions[0] = IController.ActionArgs(
            IController.ActionType.BurnShortOption,
            address(this), // owner
            address(this), // address to transfer from
            address(vault.shortOtokens[0]), // otoken address
            vaultID, // vaultId
            numOTokensToBurn, // amount
            0, //index
            "" //data
        );

        actions[1] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            address(collateralToken), // withdrawn asset
            vaultID, // vaultId
            vault.collateralAmounts[0].mul(numOTokensToBurn).div(
                vault.shortAmounts[0]
            ), // amount
            0, //index
            "" //data
        );

        controller.operate(actions);

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        return endCollateralBalance.sub(startCollateralBalance);
    }

    /**
     * @notice Calculates the management fee for this week's round
     * @param currentBalance is the balance of funds held on the vault after closing short
     * @param pendingAmount is the pending deposit amount
     * @param managementFeePercent is the management fee pct.
     * @return managementFeeInAsset is the management fee
     */
    function getManagementFee(
        uint256 currentBalance,
        uint256 pendingAmount,
        uint256 managementFeePercent
    ) internal pure returns (uint256 managementFeeInAsset) {
        // At the first round, currentBalance=0, pendingAmount>0
        // so we just do not charge anything on the first round
        uint256 lockedBalanceSansPending =
            currentBalance > pendingAmount
                ? currentBalance.sub(pendingAmount)
                : 0;

        uint256 _managementFeeInAsset;

        // Always charge management fee regardless of whether the vault is
        // making a profit from the previous options sale
        _managementFeeInAsset = managementFeePercent > 0
            ? lockedBalanceSansPending.mul(managementFeePercent).div(
                100 * Vault.FEE_MULTIPLIER
            )
            : 0;

        return _managementFeeInAsset;
    }

    /**
     * @notice Either retrieves the option token if it already exists, or deploy it
     * @param closeParams is the struct with details on previous option and strike selection details
     * @param vaultParams is the struct with vault general data
     * @param underlying is the address of the underlying asset of the option
     * @param collateralAsset is the address of the collateral asset of the option
     * @param strikePrice is the strike price of the option
     * @param expiry is the expiry timestamp of the option
     * @param isPut is whether the option is a put
     * @return the address of the option
     */
    function getOrDeployOtoken(
        CloseParams calldata closeParams,
        Vault.VaultParams storage vaultParams,
        address underlying,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    ) internal returns (address) {
        IOtokenFactory factory = IOtokenFactory(closeParams.OTOKEN_FACTORY);

        address otokenFromFactory =
            factory.getOtoken(
                underlying,
                closeParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        if (otokenFromFactory != address(0)) {
            return otokenFromFactory;
        }

        address otoken =
            factory.createOtoken(
                underlying,
                closeParams.USDC,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );

        verifyOtoken(
            otoken,
            vaultParams,
            collateralAsset,
            closeParams.USDC,
            closeParams.delay
        );

        return otoken;
    }

    /**
     * @notice Starts the gnosis auction
     * @param auctionDetails is the struct with all the custom parameters of the auction
     * @return the auction id of the newly created auction
     */
    function startAuction(GnosisAuction.AuctionDetails calldata auctionDetails)
        external
        returns (uint256)
    {
        return GnosisAuction.startAuction(auctionDetails);
    }

    /**
     * @notice Settles the gnosis auction
     * @param gnosisEasyAuction is the contract address of Gnosis easy auction protocol
     * @param auctionID is the auction ID of the gnosis easy auction
     */
    function settleAuction(address gnosisEasyAuction, uint256 auctionID)
        internal
    {
        IGnosisAuction(gnosisEasyAuction).settleAuction(auctionID);
    }

    /**
     * @notice Places a bid in an auction
     * @param bidDetails is the struct with all the details of the
      bid including the auction's id and how much to bid
     */
    function placeBid(GnosisAuction.BidDetails calldata bidDetails)
        external
        returns (
            uint256 sellAmount,
            uint256 buyAmount,
            uint64 userId
        )
    {
        return GnosisAuction.placeBid(bidDetails);
    }

    /**
     * @notice Claims the oTokens belonging to the vault
     * @param auctionSellOrder is the sell order of the bid
     * @param gnosisEasyAuction is the address of the gnosis auction contract
     holding custody to the funds
     * @param counterpartyThetaVault is the address of the counterparty theta
     vault of this delta vault
     */
    function claimAuctionOtokens(
        Vault.AuctionSellOrder calldata auctionSellOrder,
        address gnosisEasyAuction,
        address counterpartyThetaVault
    ) external {
        GnosisAuction.claimAuctionOtokens(
            auctionSellOrder,
            gnosisEasyAuction,
            counterpartyThetaVault
        );
    }

    /**
     * @notice Verify the constructor params satisfy requirements
     * @param _initParams is the initialization parameter including owner, keeper, etc.
     * @param _vaultParams is the struct with vault general data
     */
    function verifyInitializerParams(
        InitParams calldata _initParams,
        Vault.VaultParams calldata _vaultParams,
        uint256 _min_auction_duration
    ) external pure {
        require(_initParams._owner != address(0), "!_owner");
        require(_initParams._keeper != address(0), "!_keeper");
        require(_initParams._feeRecipient != address(0), "!_feeRecipient");
        require(
            _initParams._performanceFee < 100 * Vault.FEE_MULTIPLIER,
            "performanceFee >= 100%"
        );
        require(
            _initParams._managementFee < 100 * Vault.FEE_MULTIPLIER,
            "managementFee >= 100%"
        );
        require(bytes(_initParams._tokenName).length > 0, "!_tokenName");
        require(bytes(_initParams._tokenSymbol).length > 0, "!_tokenSymbol");
        require(
            (_initParams._period == 7) ||
                (_initParams._period == 14) ||
                (_initParams._period == 30) ||
                (_initParams._period == 90) ||
                (_initParams._period == 180),
            "!_period"
        );
        require(
            _initParams._optionsPremiumPricer != address(0),
            "!_optionsPremiumPricer"
        );
        require(
            _initParams._strikeSelection != address(0),
            "!_strikeSelection"
        );
        require(
            _initParams._premiumDiscount > 0 &&
                _initParams._premiumDiscount <
                100 * Vault.PREMIUM_DISCOUNT_MULTIPLIER,
            "!_premiumDiscount"
        );
        require(
            _initParams._auctionDuration >= _min_auction_duration,
            "!_auctionDuration"
        );
        require(_initParams._maxDepositors > 0, "!_maxDepositors");
        require(_initParams._minDeposit > 0, "!_minDeposit");

        require(_vaultParams.asset != address(0), "!asset");
        require(_vaultParams.underlying != address(0), "!underlying");
        require(_vaultParams.minimumSupply > 0, "!minimumSupply");
        require(_vaultParams.cap > 0, "!cap");
        require(
            _vaultParams.cap > _vaultParams.minimumSupply,
            "cap has to be higher than minimumSupply"
        );
    }

    /**
     * @notice Gets the next options expiry timestamp, this function should be called
     when there is sufficient guard to ensure valid period
     * @param timestamp is the expiry timestamp of the current option
     * @param period is no. of days in between option sales. Available periods are: 
     * 7(1w), 14(2w), 30(1m), 90(3m), 180(6m)
     */
    function getNextExpiry(uint256 timestamp, uint256 period)
        internal
        pure
        returns (uint256 nextExpiry)
    {
        if (period == 7) {
            nextExpiry = DateTime.getNextFriday(timestamp);
            nextExpiry = nextExpiry <= timestamp
                ? nextExpiry + 1 weeks
                : nextExpiry;
        } else if (period == 14) {
            nextExpiry = DateTime.getNextFriday(timestamp);
            nextExpiry = nextExpiry <= timestamp
                ? nextExpiry + 2 weeks
                : nextExpiry;
        } else if (period == 30) {
            nextExpiry = DateTime.getMonthLastFriday(timestamp);
            nextExpiry = nextExpiry <= timestamp
                ? DateTime.getMonthLastFriday(nextExpiry + 1 weeks)
                : nextExpiry;
        } else if (period == 90) {
            nextExpiry = DateTime.getQuarterLastFriday(timestamp);
            nextExpiry = nextExpiry <= timestamp
                ? DateTime.getQuarterLastFriday(nextExpiry + 1 weeks)
                : nextExpiry;
        } else if (period == 180) {
            nextExpiry = DateTime.getBiannualLastFriday(timestamp);
            nextExpiry = nextExpiry <= timestamp
                ? DateTime.getBiannualLastFriday(nextExpiry + 1 weeks)
                : nextExpiry;
        }

        nextExpiry = nextExpiry - (nextExpiry % (24 hours)) + (8 hours);
    }
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
// ----------------------------------------------------------------------------

pragma solidity =0.8.4;

library DateTime {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days =
            _day -
                32075 +
                (1461 * (_year + 4800 + (_month - 14) / 12)) /
                4 +
                (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
                12 -
                (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
                4 -
                OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function getDaysInMonth(uint256 timestamp)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        (uint256 year, uint256 month, ) =
            _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month)
        internal
        pure
        returns (uint256 daysInMonth)
    {
        if (
            month == 1 ||
            month == 3 ||
            month == 5 ||
            month == 7 ||
            month == 8 ||
            month == 10 ||
            month == 12
        ) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp)
        internal
        pure
        returns (uint256 dayOfWeek)
    {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    /**
     * @notice Gets the Friday of the same week
     * @param timestamp is the given date and time
     * @return the Friday of the same week in unix time
     */
    function getThisWeekFriday(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return timestamp + 5 days - getDayOfWeek(timestamp) * 1 days;
    }

    /**
     * @notice Gets the next friday after the given date and time
     * @param timestamp is the given date and time
     * @return the next friday after the given date and time
     */
    function getNextFriday(uint256 timestamp) internal pure returns (uint256) {
        uint256 friday = getThisWeekFriday(timestamp);
        return friday >= timestamp ? friday : friday + 1 weeks;
    }

    /**
     * @notice Gets the last day of the month
     * @param timestamp is the given date and time
     * @return the last day of the same month in unix time
     */
    function getLastDayOfMonth(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        return
            timestampFromDate(getYear(timestamp), getMonth(timestamp) + 1, 1) -
            1 days;
    }

    /**
     * @notice Gets the last Friday of the month
     * @param timestamp is the given date and time
     * @return the last Friday of the same month in unix time
     */
    function getMonthLastFriday(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        uint256 lastDay = getLastDayOfMonth(timestamp);
        uint256 friday = getThisWeekFriday(lastDay);

        return friday > lastDay ? friday - 1 weeks : friday;
    }

    /**
     * @notice Gets the last Friday of the quarter
     * @param timestamp is the given date and time
     * @return the last Friday of the quarter in unix time
     */
    function getQuarterLastFriday(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        uint256 month = getMonth(timestamp);
        uint256 quarterMonth =
            (month <= 3) ? 3 : (month <= 6) ? 6 : (month <= 9) ? 9 : 12;

        uint256 quarterDate =
            timestampFromDate(getYear(timestamp), quarterMonth, 1);

        return getMonthLastFriday(quarterDate);
    }

    /**
     * @notice Gets the last Friday of the half-year
     * @param timestamp is the given date and time
     * @return the last friday of the half-year
     */
    function getBiannualLastFriday(uint256 timestamp)
        internal
        pure
        returns (uint256)
    {
        uint256 month = getMonth(timestamp);
        uint256 biannualMonth = (month <= 6) ? 6 : 12;

        uint256 biannualDate =
            timestampFromDate(getYear(timestamp), biannualMonth, 1);

        return getMonthLastFriday(biannualDate);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISwapRouter} from "../interfaces/ISwapRouter.sol";
import {IUniswapV3Factory} from "../interfaces/IUniswapV3Factory.sol";
import "./Path.sol";

library UniswapRouter {
    using Path for bytes;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @notice Check if the path set for swap is valid
     * @param swapPath is the swap path e.g. encodePacked(tokenIn, poolFee, tokenOut)
     * @param validTokenIn is the contract address of the correct tokenIn
     * @param validTokenOut is the contract address of the correct tokenOut
     * @param uniswapFactory is the contract address of UniswapV3 factory
     * @return isValidPath is whether the path is valid
     */
    function checkPath(
        bytes memory swapPath,
        address validTokenIn,
        address validTokenOut,
        address uniswapFactory
    ) internal view returns (bool isValidPath) {
        // Function checks if the tokenIn and tokenOut in the swapPath
        // matches the validTokenIn and validTokenOut specified.
        address tokenIn;
        address tokenOut;
        address tempTokenIn;
        uint24 fee;
        IUniswapV3Factory factory = IUniswapV3Factory(uniswapFactory);

        // Return early if swapPath is below the bare minimum (43)
        require(swapPath.length >= 43, "Path too short");
        // Return early if swapPath is above the max (66)
        // At worst we have 2 hops e.g. USDC > WETH > asset
        require(swapPath.length <= 66, "Path too long");

        // Decode the first pool in path
        (tokenIn, tokenOut, fee) = swapPath.decodeFirstPool();

        // Check to factory if pool exists
        require(
            factory.getPool(tokenIn, tokenOut, fee) != address(0),
            "Pool does not exist"
        );

        // Check next pool if multiple pools
        while (swapPath.hasMultiplePools()) {
            // Remove the first pool from path
            swapPath = swapPath.skipToken();
            // Check the next pool and update tokenOut
            (tempTokenIn, tokenOut, fee) = swapPath.decodeFirstPool();

            require(
                factory.getPool(tokenIn, tokenOut, fee) != address(0),
                "Pool does not exist"
            );
        }

        return tokenIn == validTokenIn && tokenOut == validTokenOut;
    }

    /**
     * @notice Swaps assets by calling UniswapV3 router
     * @param recipient is the address of recipient of the tokenOut
     * @param tokenIn is the address of the token given to the router
     * @param amountIn is the amount of tokenIn given to the router
     * @param minAmountOut is the minimum acceptable amount of tokenOut received from swap
     * @param router is the contract address of UniswapV3 router
     * @param swapPath is the swap path e.g. encodePacked(tokenIn, poolFee, tokenOut)
     * @return amountOut is the amount of tokenOut received from the swap
     */
    function swap(
        address recipient,
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        address router,
        bytes calldata swapPath
    ) internal returns (uint256 amountOut) {
        // Approve router to spend tokenIn
        IERC20(tokenIn).safeApprove(router, amountIn);

        // Swap assets using UniswapV3 router
        ISwapRouter.ExactInputParams memory swapParams =
            ISwapRouter.ExactInputParams({
                recipient: recipient,
                path: swapPath,
                deadline: block.timestamp.add(10 minutes),
                amountIn: amountIn,
                amountOutMinimum: minAmountOut
            });

        amountOut = ISwapRouter(router).exactInput(swapParams);

        return amountOut;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.4;
pragma abicoder v2;

/// Source: https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/callback/IUniswapV3SwapCallback.sol

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

/// Source: https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/ISwapRouter.sol

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
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

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
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

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
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Source: https://github.com/Uniswap/v3-core/blob/main/contracts/interfaces/IUniswapV3Factory.sol
pragma solidity =0.8.4;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Source: https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/Path.sol
pragma solidity =0.8.4;

import "./BytesLib.sol";

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
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH =
        POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Returns the number of pools in the path
    /// @param path The encoded swap path
    /// @return The number of pools in the path
    function numPools(bytes memory path) internal pure returns (uint256) {
        // Ignore the first token address. From then on every fee and token offset indicates a pool.
        return ((path.length - ADDR_SIZE) / NEXT_OFFSET);
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
    function getFirstPool(bytes memory path)
        internal
        pure
        returns (bytes memory)
    {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: MIT
// Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity =0.8.4;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
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
                    let mc := add(
                        add(tempBytes, lengthmod),
                        mul(0x20, iszero(lengthmod))
                    )
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(
                            add(
                                add(_bytes, lengthmod),
                                mul(0x20, iszero(lengthmod))
                            ),
                            _start
                        )
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

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint24)
    {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title UpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract UpgradeabilityProxy is Proxy {
  /**
   * @dev Contract constructor.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, bytes memory _data) payable {
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
    _setImplementation(_logic);
    if(_data.length > 0) {
      (bool success,) = _logic.delegatecall(_data);
      require(success);
    }
  }

  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal override view returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(Address.isContract(newImplementation), "Cannot set a proxy implementation to a non-contract address");

    bytes32 slot = IMPLEMENTATION_SLOT;

    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Implemented entirely in `_fallback`.
   */
  fallback () payable external {
    _fallback();
  }

  /**
   * @dev Receive function.
   * Implemented entirely in `_fallback`.
   */
  receive () payable external {
    // _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal virtual view returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 { revert(0, returndatasize()) }
      default { return(0, returndatasize()) }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {
  }

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import "./UpgradeabilityProxy.sol";

/**
 * @title AdminUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract AdminUpgradeabilityProxy is UpgradeabilityProxy {
  /**
   * Contract constructor.
   * @param _logic address of the initial implementation.
   * @param admin_ Address of the proxy administrator.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  constructor(address _logic, address admin_, bytes memory _data) UpgradeabilityProxy(_logic, _data) payable {
    assert(ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
    _setAdmin(admin_);
  }

  /**
   * @dev Emitted when the administration has been transferred.
   * @param previousAdmin Address of the previous admin.
   * @param newAdmin Address of the new admin.
   */
  event AdminChanged(address previousAdmin, address newAdmin);

  /**
   * @dev Storage slot with the admin of the contract.
   * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
   * validated in the constructor.
   */

  bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

  /**
   * @dev Modifier to check whether the `msg.sender` is the admin.
   * If it is, it will run the function. Otherwise, it will delegate the call
   * to the implementation.
   */
  modifier ifAdmin() {
    if (msg.sender == _admin()) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @return adminAddress The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address adminAddress) {
    return _admin();
  }

  /**
   * @return implementationAddress The address of the implementation.
   */
  function implementation() external ifAdmin returns (address implementationAddress) {
    return _implementation();
  }

  /**
   * @dev Changes the admin of the proxy.
   * Only the current admin can call this function.
   * @param newAdmin Address to transfer proxy administration to.
   */
  function changeAdmin(address newAdmin) external ifAdmin {
    require(newAdmin != address(0), "Cannot change the admin of a proxy to the zero address");
    emit AdminChanged(_admin(), newAdmin);
    _setAdmin(newAdmin);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy.
   * Only the admin can call this function.
   * @param newImplementation Address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @dev Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * This is useful to initialize the proxied contract.
   * @param newImplementation Address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data) payable external ifAdmin {
    _upgradeTo(newImplementation);
    (bool success,) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @return adm The admin slot.
   */
  function _admin() internal view returns (address adm) {
    bytes32 slot = ADMIN_SLOT;
    assembly {
      adm := sload(slot)
    }
  }

  /**
   * @dev Sets the address of the proxy admin.
   * @param newAdmin Address of the new proxy admin.
   */
  function _setAdmin(address newAdmin) internal {
    bytes32 slot = ADMIN_SLOT;

    assembly {
      sstore(slot, newAdmin)
    }
  }

  /**
   * @dev Only fall back when the sender is not the admin.
   */
  function _willFallback() internal override virtual {
    require(msg.sender != _admin(), "Cannot call fallback function from the proxy admin");
    super._willFallback();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISAVAX is IERC20 {
    function getSharesByPooledAvax(uint256 avaxAmount)
        external
        view
        returns (uint256);

    function getPooledAvaxByShares(uint256 shareAmount)
        external
        view
        returns (uint256);

    function submit() external payable returns (uint256);
}