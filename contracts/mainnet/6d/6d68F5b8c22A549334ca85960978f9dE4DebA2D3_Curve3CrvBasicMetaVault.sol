// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { AbstractSlippage } from "../AbstractSlippage.sol";
import { LightAbstractVault } from "../../LightAbstractVault.sol";
import { Curve3CrvAbstractMetaVault } from "./Curve3CrvAbstractMetaVault.sol";
import { VaultManagerRole } from "../../../shared/VaultManagerRole.sol";
import { InitializableToken } from "../../../tokens/InitializableToken.sol";

/**
 * @title   Basic 3Pool ERC-4626 vault that takes in one underlying asset to deposit in 3Pool and put the 3Crv in underlying metaVault.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 */
contract Curve3CrvBasicMetaVault is Curve3CrvAbstractMetaVault, Initializable {
    /// @param _nexus         Address of the Nexus contract that resolves protocol modules and roles..
    /// @param _asset         Address of the vault's asset which is one of the 3Pool tokens DAI, USDC or USDT.
    /// @param _metaVault     Address of the vault's underlying meta vault that implements ERC-4626.
    constructor(
        address _nexus,
        address _asset,
        address _metaVault
    )
        LightAbstractVault(_asset)
        Curve3CrvAbstractMetaVault(_asset, _metaVault)
        VaultManagerRole(_nexus)
    {}

    /// @param _name          Name of vault.
    /// @param _symbol        Symbol of vault.
    /// @param _vaultManager  Trusted account that can perform vault operations. eg rebalance.
    /// @param _slippageData  Initial slippage limits.
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _vaultManager,
        SlippageData memory _slippageData
    ) external initializer {
        // Set the vault's decimals to the same as the Metapool LP token (3Crv).
        InitializableToken._initialize(_name, _symbol, 18);

        VaultManagerRole._initialize(_vaultManager);
        AbstractSlippage._initialize(_slippageData);
        Curve3CrvAbstractMetaVault._initialize();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC4626Vault } from "../interfaces/IERC4626Vault.sol";
import { VaultManagerRole } from "../shared/VaultManagerRole.sol";
import { InitializableToken } from "../tokens/InitializableToken.sol";

/**
 * @title   A minimal abstract implementation of a ERC-4626 vault.
 * @author  mStable
 * @notice  Only implements the asset and max functions.
 * See the following for the full EIP-4626 specification https://eips.ethereum.org/EIPS/eip-4626.
 * Connects to the mStable Nexus to get modules like the Governor and Keeper.
 * Creates the VaultManager role.
 * Is a ERC-20 token with token details (name, symbol and decimals).
 *
 * @dev     VERSION: 1.0
 *          DATE:    2022-08-16
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - LightAbstractVault(_assetArg)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 */
abstract contract LightAbstractVault is IERC4626Vault, InitializableToken, VaultManagerRole {
    /// @notice Address of the vault's underlying asset token.
    IERC20 internal immutable _asset;

    /**
     * @param _assetArg         Address of the vault's underlying asset.
     */
    constructor(address _assetArg) {
        require(_assetArg != address(0), "Asset is zero");
        _asset = IERC20(_assetArg);
    }

    /// @return assetTokenAddress The address of the underlying token used for the Vault uses for accounting, depositing, and withdrawing
    function asset() external view virtual override returns (address assetTokenAddress) {
        assetTokenAddress = address(_asset);
    }

    /**
     * @notice The maximum number of underlying assets that caller can deposit.
     * @param caller Account that the assets will be transferred from.
     * @return maxAssets The maximum amount of underlying assets the caller can deposit.
     */
    function maxDeposit(address caller) external view override returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = type(uint256).max;
    }

    /**
     * @notice The maximum number of vault shares that caller can mint.
     * @param caller Account that the underlying assets will be transferred from.
     * @return maxShares The maximum amount of vault shares the caller can mint.
     */
    function maxMint(address caller) external view override returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }

        maxShares = type(uint256).max;
    }

    /**
     * @notice The maximum number of shares an owner can redeem for underlying assets.
     * @param owner Account that owns the vault shares.
     * @return maxShares The maximum amount of shares the owner can redeem.
     */
    function maxRedeem(address owner) external view override returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }

        maxShares = balanceOf(owner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { InitializableTokenDetails } from "./InitializableTokenDetails.sol";

/**
 * @title  Basic token with name, symbol and decimals that is initializable.
 * @author mStable
 * @dev    Implementing contracts must call InitializableToken._initialize
 * in their initialize function.
 */
abstract contract InitializableToken is ERC20, InitializableTokenDetails {
    /// @dev The name and symbol set by the constructor is not used.
    /// The `_initialize` is used to set the name and symbol as the token can be proxied.
    constructor() ERC20("name", "symbol") {}

    /**
     * @notice Initialization function for implementing contract
     * @param _name Name of token.
     * @param _symbol Symbol of token.
     * @param _decimals Decimals places of token. eg 18
     */
    function _initialize(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) internal virtual override {
        InitializableTokenDetails._initialize(_name, _symbol, _decimals);
    }

    /// @return name_ The `name` of the token.
    function name() public view override(ERC20, InitializableTokenDetails) returns (string memory name_) {
        name_ = InitializableTokenDetails.name();
    }

    /// @return symbol_ The symbol of the token, usually a shorter version of the name.
    function symbol()
        public
        view
        override(ERC20, InitializableTokenDetails)
        returns (string memory symbol_)
    {
        symbol_ = InitializableTokenDetails.symbol();
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     */
    function decimals() public view override(ERC20, InitializableTokenDetails) returns (uint8 decimals_) {
        decimals_ = InitializableTokenDetails.decimals();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ImmutableModule } from "../shared/ImmutableModule.sol";

/**
 * @title  VaultManagerRole , adds pausable capabilities, `onlyGovernor` can pause.
 * @notice Integrates to the `Nexus` contract resolves protocol module and role addresses.
 * For exmaple, the `Nexus` maintains who the protocol `Governor` is as well module addreesses
 * like the `Liquidator`.
 *
 * `VaultManagerRole` adds the `VaultManager` role that is trusted to set min and max parameters to protect
 * against sandwich attacks. The `VaultManager` can rebalance underlying vaults but can not
 * change the configuration of a vault. Basically, the `VaultManager` has to work within
 * the constraints of a vault's configuration. The `Governor` is the only account
 * that can change a vault's configuration.
 *
 * `VaultManagerRole` also adds pause capabilities that allows the protocol `Governor`
 * to pause all vault operations in an emergency.
 *
 * @author mStable
 * @dev     VERSION: 1.0
 *          DATE:    2021-02-24
 */
abstract contract VaultManagerRole is Pausable, ImmutableModule {
    /// @notice Trusted account that can perform vault operations that require parameters to protect against sandwich attacks.
    // For example, setting min or max amounts when rebalancing the underlyings of a vault.
    address public vaultManager;

    event SetVaultManager(address _vaultManager);

    /**
     * @param _nexus  Address of the `Nexus` contract that resolves protocol modules and roles.
     */
    constructor(address _nexus) ImmutableModule(_nexus) {}

    /**
     * @param _vaultManager Trusted account that can perform vault operations. eg rebalance.
     */
    function _initialize(address _vaultManager) internal virtual {
        vaultManager = _vaultManager;
    }

    modifier onlyVaultManager() {
        require(isVaultManager(msg.sender), "Only vault manager can execute");
        _;
    }

    /**
     * Checks if the specified `account` has the `VaultManager` role or not.
     * @param account Address to check if the `VaultManager` or not.
     * @return result true if the `account` is the `VaultManager`. false if not.
     */
    function isVaultManager(address account) public view returns (bool result) {
        result = vaultManager == account;
    }

    /**
     * @notice Called by the `Governor` to change the address of the `VaultManager` role.
     * Emits a `SetVaultManager` event.
     * @param _vaultManager Address that will take the `VaultManager` role.
     */
    function setVaultManager(address _vaultManager) external onlyGovernor {
        require(_vaultManager != address(0), "zero vault manager");
        require(vaultManager != _vaultManager, "already vault manager");

        vaultManager = _vaultManager;

        emit SetVaultManager(_vaultManager);
    }

    /**
     * @notice Called by the `Governor` to pause the contract.
     * Emits a `Paused` event.
     */
    function pause() external onlyGovernor whenNotPaused {
        _pause();
    }

    /**
     * @notice Called by the `Governor` to unpause the contract.
     * Emits a `Unpaused` event.
     */
    function unpause() external onlyGovernor whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";

/**
 * @title   Manages vault slippage limits
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-08-16
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(nexus)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - VaultManagerRole._initialize(_vaultManager)
 * - AbstractSlippage._initialize(_slippageData)
 */
abstract contract AbstractSlippage is VaultManagerRole {
    // Initial slippage limits in basis points. i.e. 1% = 100
    struct SlippageData {
        uint256 redeem;
        uint256 deposit;
        uint256 withdraw;
        uint256 mint;
    }

    // Events for slippage change
    event RedeemSlippageChange(address indexed sender, uint256 slippage);
    event DepositSlippageChange(address indexed sender, uint256 slippage);
    event WithdrawSlippageChange(address indexed sender, uint256 slippage);
    event MintSlippageChange(address indexed sender, uint256 slippage);

    /// @notice Basis points calculation scale. 100% = 10000. 1% = 100
    uint256 public constant BASIS_SCALE = 1e4;

    /// @notice Redeem slippage in basis points i.e. 1% = 100
    uint256 public redeemSlippage;
    /// @notice Deposit slippage in basis points i.e. 1% = 100
    uint256 public depositSlippage;
    /// @notice Withdraw slippage in basis points i.e. 1% = 100
    uint256 public withdrawSlippage;
    /// @notice Mint slippage in basis points i.e. 1% = 100
    uint256 public mintSlippage;

    /// @param _slippageData Initial slippage limits of type `SlippageData`.
    function _initialize(SlippageData memory _slippageData) internal {
        _setRedeemSlippage(_slippageData.redeem);
        _setDepositSlippage(_slippageData.deposit);
        _setWithdrawSlippage(_slippageData.withdraw);
        _setMintSlippage(_slippageData.mint);
    }

    /***************************************
            Internal slippage functions
    ****************************************/

    /// @param _slippage Redeem slippage to apply as basis points i.e. 1% = 100
    function _setRedeemSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid redeem slippage");
        redeemSlippage = _slippage;

        emit RedeemSlippageChange(msg.sender, _slippage);
    }

    /// @param _slippage Deposit slippage to apply as basis points i.e. 1% = 100
    function _setDepositSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid deposit Slippage");
        depositSlippage = _slippage;

        emit DepositSlippageChange(msg.sender, _slippage);
    }

    /// @param _slippage Withdraw slippage to apply as basis points i.e. 1% = 100
    function _setWithdrawSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid withdraw Slippage");
        withdrawSlippage = _slippage;

        emit WithdrawSlippageChange(msg.sender, _slippage);
    }

    /// @param _slippage Mint slippage to apply as basis points i.e. 1% = 100
    function _setMintSlippage(uint256 _slippage) internal {
        require(_slippage <= BASIS_SCALE, "Invalid mint slippage");
        mintSlippage = _slippage;

        emit MintSlippageChange(msg.sender, _slippage);
    }

    /***************************************
            External slippage functions
    ****************************************/

    /// @notice Governor function to set redeem slippage.
    /// @param _slippage Redeem slippage to apply as basis points i.e. 1% = 100
    function setRedeemSlippage(uint256 _slippage) external onlyGovernor {
        _setRedeemSlippage(_slippage);
    }

    /// @notice Governor function to set deposit slippage.
    /// @param _slippage Deposit slippage to apply as basis points i.e. 1% = 100
    function setDepositSlippage(uint256 _slippage) external onlyGovernor {
        _setDepositSlippage(_slippage);
    }

    /// @notice Governor function to set withdraw slippage.
    /// @param _slippage Withdraw slippage to apply as basis points i.e. 1% = 100
    function setWithdrawSlippage(uint256 _slippage) external onlyGovernor {
        _setWithdrawSlippage(_slippage);
    }

    /// @notice Governor function to set mint slippage.
    /// @param _slippage Mint slippage to apply as basis points i.e. 1% = 100
    function setMintSlippage(uint256 _slippage) external onlyGovernor {
        _setMintSlippage(_slippage);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// External
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Libs
import { AbstractSlippage } from "../AbstractSlippage.sol";
import { ICurveAddressProvider } from "../../../peripheral/Curve/ICurveAddressProvider.sol";
import { ICurveRegistryContract } from "../../../peripheral/Curve/ICurveRegistryContract.sol";
import { ICurve3Pool } from "../../../peripheral/Curve/ICurve3Pool.sol";
import { LightAbstractVault, IERC20 } from "../../LightAbstractVault.sol";
import { IERC4626Vault } from "../../../interfaces/IERC4626Vault.sol";
import { Curve3PoolCalculatorLibrary } from "../../../peripheral/Curve/Curve3PoolCalculatorLibrary.sol";

/**
 * @title  Abstract ERC-4626 vault with one of DAI/USDC/USDT asset invested in 3Pool, and then deposited in Meta Vault.
 * @notice One of DAI/USDC/USDT token is deposited in 3Pool to get a 3Pool LP token,
 *  which is deposited into a 3Pool Gauge for rewards.
 *
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-02
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - AbstractSlippage(_slippageData)
 * - AbstractVault(_assetArg)
 * - Curve3CrvAbstractMetaVault(_asset, _metaVault)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 * - Curve3CrvAbstractMetaVault._initialize()
 */
abstract contract Curve3CrvAbstractMetaVault is AbstractSlippage, LightAbstractVault {
    using SafeERC20 for IERC20;

    /// @notice Scale of one asset. eg 1e18 if asset has 18 decimal places.
    uint256 public immutable assetScale;
    /// @notice Converts USD value with 18 decimals back down to asset/vault scale.
    /// For example, convert 18 decimal USD value back down to USDC which only has 6 decimal places.
    /// Will be 1 for DAI, 1e12 for USDC and USDT.
    uint256 public immutable assetFromUsdScale;

    /// @notice Scale of the Curve.fi 3Crv token. 1e18 = 18 decimal places
    uint256 public constant threeCrvTokenScale = 1e18;
    /// @notice Address of the underlying Meta Vault that implements ERC-4626.
    IERC4626Vault public immutable metaVault;

    /// @notice The index of underlying asset DAI, USDC or USDT in 3Pool. DAI = 0, USDC = 1 and USDT = 2
    uint256 public immutable assetPoolIndex;

    /// @param _asset     Address of the vault's asset which is one of the 3Pool tokens DAI, USDC or USDT.
    /// @param _metaVault Address of the vault's underlying meta vault that implements ERC-4626.
    constructor(address _asset, address _metaVault) {
        require(_metaVault != address(0), "Invalid Vault");
        metaVault = IERC4626Vault(_metaVault);

        // Set underlying asset scales
        uint256 _decimals = IERC20Metadata(_asset).decimals();
        assetScale = 10**_decimals;
        assetFromUsdScale = (10**(18 - _decimals));

        uint256 _assetPoolIndex = 4;
        if (ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).coins(0) == address(_asset))
            _assetPoolIndex = 0;
        else if (ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).coins(1) == address(_asset))
            _assetPoolIndex = 1;
        else if (ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).coins(2) == address(_asset))
            _assetPoolIndex = 2;
        require(_assetPoolIndex < 3, "Underlying asset not in 3Pool");
        assetPoolIndex = _assetPoolIndex;
    }

    /// @dev approve 3Pool and the Meta Vault to transfer assets and 3Crv from this vault.
    function _initialize() internal virtual {
        _resetAllowances();
    }

    /***************************************
                    Valuations
    ****************************************/

    /**
     * @notice Calculates the vault's total assets by extrapolating the asset tokens (DAI, USDC or USDT) received
     * from redeeming one Curve 3Pool LP token (3Crv) by the amount of 3Crv in the underlying Meta Vault.
     * This takes into account Curve 3Pool token balances but does not take into account any slippage.
     * Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (DAI, USDC or USDT)
     * @return totalManagedAssets Amount of assets managed by the vault.
     */
    function totalAssets() public view override returns (uint256 totalManagedAssets) {
        // Get the amount of underying meta vault shares held by this vault.
        uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
        if (totalMetaVaultShares > 0) {
            // Convert underlying meta vault shares to 3Crv
            // This uses the Metapool and 3Pool virtual prices
            uint256 threeCrvTokens = metaVault.convertToAssets(totalMetaVaultShares);

            // Convert 3Crv to vault assets (DAI, USDC or USDT)
            totalManagedAssets = _getAssetsForThreeCrvTokens(threeCrvTokens);
        }
    }

    /***************************************
                Deposit functions
    ****************************************/

    /**
     * @notice Overrides the standard ERC-4626 deposit with an allowed slippage in basis points.
     * Adds vault asset (DAI, USDC or USDT) into Curve 3Pool and
     * deposits the liquidity provider token (3Crv) into the underlying 3Crv based meta vault.
     * @dev Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
     * @param assets The amount of underlying assets to be transferred to the vault.
     * @param receiver The account that the vault shares will be minted to.
     * @param slippage Deposit slippage in basis points i.e. 1% = 100.
     * @return shares The amount of vault shares that were minted.
     */
    function deposit(
        uint256 assets,
        address receiver,
        uint256 slippage
    ) external virtual whenNotPaused returns (uint256 shares) {
        shares = _depositInternal(assets, receiver, slippage);
    }

    /**
     * @notice  Mint vault shares to receiver by transferring exact amount of underlying asset tokens from the caller.
     * Adds vault asset (DAI, USDC or USDT) into Curve 3Pool and deposits the liquidity provider token (3Crv)
     * into the underlying 3Crv based meta vault.
     * @dev Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
     * @param assets The amount of underlying assets to be transferred to the vault.
     * @param receiver The account that the vault shares will be minted to.
     * @return shares The amount of vault shares that were minted.
     */
    function deposit(uint256 assets, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = _depositInternal(assets, receiver, depositSlippage);
    }

    /// @dev Converts vault assets to shares in three steps:
    /// Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
    function _depositInternal(
        uint256 _assets,
        address _receiver,
        uint256 _slippage
    ) internal virtual returns (uint256 shares) {
        // Transfer this vault's asssets (DAI, USDC or USDT) from the caller
        _asset.safeTransferFrom(msg.sender, address(this), _assets);

        // Get this vault's balance of underlying Meta Vault shares before deposit.
        uint256 metaVaultSharesBefore = metaVault.balanceOf(address(this));

        // Calculate fair amount of 3Pool LP tokens (3Crv) using virtual prices for vault assets, eg DAI
        uint256 minThreeCrvTokens = _getThreeCrvTokensForAssets(_assets);
        // Calculate min amount of metapool LP tokens with max slippage
        // This is used for sandwich attack protection
        minThreeCrvTokens = (minThreeCrvTokens * (BASIS_SCALE - _slippage)) / BASIS_SCALE;

        // Deposit asset (DAI, USDC or USDT) into 3Pool and then deposit into underlying meta vault.
        uint256 metaVaultSharesReceived = _addAndDeposit(_assets, minThreeCrvTokens);

        // Calculate the proportion of shares to mint based on the amount of underlying meta vault shares.
        shares = _getSharesFromMetaVaultShares(
            metaVaultSharesReceived,
            metaVaultSharesBefore,
            totalSupply()
        );

        _mint(_receiver, shares);

        emit Deposit(msg.sender, _receiver, _assets, shares);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current transaction, given current on-chain conditions.
     * @param assets The amount of underlying assets to be transferred.
     * @return shares The amount of vault shares that will be minted.
     * @dev Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
     */
    function previewDeposit(uint256 assets)
        external
        view
        virtual
        override
        returns (uint256 shares)
    {
        if (assets > 0) {
            // Calculate Meta Vault assets (3Crv) for this vault's asset (DAI, USDC, USDT)
            (uint256 threeCrvTokens, , ) = Curve3PoolCalculatorLibrary.calcDeposit(
                assets,
                assetPoolIndex
            );

            // Calculate underlying meta vault shares received for Meta Vault assets (3Crv)
            uint256 metaVaultShares = metaVault.previewDeposit(threeCrvTokens);

            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
            // Calculate the proportion of shares to mint based on the amount of underlying meta vault shares.
            shares = _getSharesFromMetaVaultShares(
                metaVaultShares,
                totalMetaVaultShares,
                totalSupply()
            );
        }
    }

    /***************************************
                Mint functions
    ****************************************/

    /**
     * @notice Mint exact amount of vault shares to the receiver by transferring enough underlying asset tokens from the caller.
     * Adds vault asset (DAI, USDC or USDT) into Curve 3Pool and deposits the liquidity provider token (3Crv)
     * into the underlying 3Crv based meta vault.
     * @param shares The amount of vault shares to be minted.
     * @param receiver The account the vault shares will be minted to.
     * @return assets The amount of underlying assets that were transferred from the caller.
     * @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (eg DAI)
     */
    function mint(uint256 shares, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 assets)
    {
        // Get the total underlying Meta Vault shares held by this vault.
        uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
        // Convert this vault's required shares to required underlying meta vault shares.
        uint256 requiredMetaVaultShares = _getMetaVaultSharesFromShares(
            shares,
            totalMetaVaultShares,
            totalSupply()
        );

        // Calculate 3Crv needed to mint the required Meta Vault shares
        // There is no sandwich protection on underlying Meta Vault deposits as
        // the 3Crv is not converted to Curve Metapool LP tokens until a later settle process.
        uint256 requiredThreeCrvTokens = metaVault.previewMint(requiredMetaVaultShares);

        // Calculate assets (DAI, USDC or USDT) needed to mint the required amount of shares
        uint256 invariant;
        uint256 total3CrvSupply;
        (assets, invariant, total3CrvSupply) = Curve3PoolCalculatorLibrary.calcMint(
            requiredThreeCrvTokens,
            assetPoolIndex
        );

        // Protect against sandwich and flash loan attacks where the balance of the 3Pool can be manipulated.
        // Calculate fair USD amount to mint required 3Crv.
        // Unscaled 3Pool virtual price (3Crv/USD) = pool invariant (USD value) / total supply of LP token (3Crv).
        // USD amount = 3Crv amount * pool invariant (USD value) / total supply of LP token (3Crv)
        uint256 maxAssets = (requiredThreeCrvTokens * invariant) / total3CrvSupply;
        // Max USD = USD amount + (1 + mint slippage). So for 1% slippage, USD amount * 1.01
        // We will assume 1 DAI is close to 1 USD so max USD = max assets (DAI, USDC or USDT).
        maxAssets = (maxAssets * (BASIS_SCALE + mintSlippage)) / BASIS_SCALE;
        require(assets <= maxAssets, "too much slippage");

        // Transfer this vault's asssets (DAI, USDC or USDT) from the caller.
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        // Deposit asset (DAI, USDC or USDT) into 3Pool and then deposit into underlying meta vault.
        _addAndDeposit(assets, requiredThreeCrvTokens);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current transaction, given current on-chain conditions.
     * @param shares The amount of vault shares to be minted.
     * @return assets The amount of each underlying assest tokens that will be transferred from the caller.
     * @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (eg DAI)
     */
    function previewMint(uint256 shares) external view virtual override returns (uint256 assets) {
        if (shares > 0) {
            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
            // Convert this vault's required shares to required underlying meta vault shares.
            uint256 requiredMetaVaultShares = _getMetaVaultSharesFromShares(
                shares,
                totalMetaVaultShares,
                totalSupply()
            );

            // Calculate 3Crv needed to mint the required Meta Vault shares
            uint256 requiredThreeCrvTokens = metaVault.previewMint(requiredMetaVaultShares);

            // Calculate assets (DAI, USDC or USDT) needed to mint the required amount of shares
            (assets, , ) = Curve3PoolCalculatorLibrary.calcMint(
                requiredThreeCrvTokens,
                assetPoolIndex
            );
        }
    }

    /***************************************
                Withdraw functions
    ****************************************/

    /**
     * @notice Burns enough vault shares from owner and transfers the exact amount of each underlying asset tokens to the receiver.
     * Withdraws 3Crv from underlying meta vault and then removes stablecoin (DAI, USDC or USDT) from the Curve 3Pool.
     * @param assets The amount of each underlying asset tokens to be withdrawn from the vault.
     * @param receiver The account that each underlying asset will be transferred to.
     * @param owner Account that owns the vault shares to be burnt.
     * @return shares The amount of vault shares that were burnt.
     * @dev Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 shares) {
        if (assets > 0) {
            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultSharesBefore = metaVault.balanceOf(address(this));

            // Calculate 3Pool LP tokens (3Crv) required for this vault's asset (DAI, USDC or USDT).
            (
                uint256 requiredThreeCrvTokens,
                uint256 invariant,
                uint256 total3CrvSupply
            ) = Curve3PoolCalculatorLibrary.calcWithdraw(assets, assetPoolIndex);

            // Withdraw 3Crv from underlying meta vault.
            uint256 metaVaultShares = metaVault.withdraw(
                requiredThreeCrvTokens,
                address(this),
                address(this)
            );

            // Calculate the proportion of shares to burn based on the amount of underlying meta vault shares.
            shares = _getSharesFromMetaVaultShares(
                metaVaultShares,
                totalMetaVaultSharesBefore,
                totalSupply()
            );

            // If caller is not the owner of the shares
            uint256 allowed = allowance(owner, msg.sender);
            if (msg.sender != owner && allowed != type(uint256).max) {
                require(shares <= allowed, "Amount exceeds allowance");
                _approve(owner, msg.sender, allowed - shares);
            }

            // Block scoping to workaround stack too deep
            {
                // Protect against sandwich and flash loan attacks where the balance of the 3Pool can be manipulated.
                // Calculate fair USD amount to withdraw required 3Crv.
                // Unscaled 3Pool virtual price (3Crv/USD) = pool invariant (USD value) / total supply of LP token (3Crv).
                // USD amount = 3Crv amount * pool invariant (USD value) / total supply of LP token (3Crv)
                uint256 minAssets = (requiredThreeCrvTokens * invariant) / total3CrvSupply;
                // Max USD = USD amount + (1 - withdraw slippage). So for 1% slippage, USD amount * 0.99
                // We will assume 1 DAI is close to 1 USD so min USD = min assets (DAI, USDC or USDT).
                minAssets = (minAssets * (BASIS_SCALE - withdrawSlippage)) / BASIS_SCALE;
                // USD value is scaled to 18 decimals, it needs to be scaled to asset decimals.
                minAssets = minAssets / assetFromUsdScale;
                require(assets >= minAssets, "too much slippage");

                uint256[3] memory assetsArray;
                assetsArray[assetPoolIndex] = assets;
                // Burn 3Pool LP tokens (3Crv) and receive this vault's asset (DAI, USDC or USDT).
                ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).remove_liquidity_imbalance(
                    assetsArray,
                    requiredThreeCrvTokens
                );
            }

            // Burn the owner's vault shares
            _burn(owner, shares);

            // Transfer this vault's asssets (DAI, USDC or USDT) to the receiver.
            _asset.safeTransfer(receiver, assets);

            emit Withdraw(msg.sender, receiver, owner, assets, shares);
        }
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current transaction, given current on-chain conditions.
     * @param assets The amount of each underlying asset tokens to be withdrawn.
     * @return shares The amount of vault shares that will be burnt.
     * @dev Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
     */
    function previewWithdraw(uint256 assets)
        external
        view
        virtual
        override
        returns (uint256 shares)
    {
        if (assets > 0) {
            // Calculate 3Pool LP tokens (3Crv) for this vault's asset (DAI, USDC or USDT).
            (uint256 threeCrvTokens, , ) = Curve3PoolCalculatorLibrary.calcWithdraw(
                assets,
                assetPoolIndex
            );

            // Calculate underlying meta vault shares received for 3Pool LP tokens (3Crv)
            uint256 metaVaultShares = metaVault.previewWithdraw(threeCrvTokens);

            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
            // Calculate the proportion of shares to burn based on the amount of underlying meta vault shares.
            shares = _getSharesFromMetaVaultShares(
                metaVaultShares,
                totalMetaVaultShares,
                totalSupply()
            );
        }
    }

    /**
     * @notice The maximum number of underlying assets that owner can withdraw.
     * @param owner Account that owns the vault shares.
     * @return maxAssets The maximum amount of underlying assets the owner can withdraw.
     */
    function maxWithdraw(address owner) external view virtual override returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = _previewRedeem(balanceOf(owner));
    }

    /***************************************
                Redeem functions
    ****************************************/

    /**
     * @notice Standard EIP-4626 redeem.
     * Redeems 3Crv from underlying meta vault and then removes stablecoin from the Curve 3Pool.
     * @param shares The amount of vault shares to be burnt.
     * @param receiver The account the underlying assets will be transferred to.
     * @param owner The account that owns the vault shares to be burnt.
     * @return assets The amount of underlying assets that were transferred to the receiver.
     * @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (eg DAI)
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 assets) {
        assets = _redeemInternal(shares, receiver, owner, redeemSlippage);
    }

    /**
     * @notice Overloaded standard ERC-4626 `redeem` method with custom slippage.
     * This can be used in the event of the asset depegging from 1 USD.
     * @param shares The amount of vault shares to be burnt.
     * @param receiver The account the underlying assets will be transferred to.
     * @param owner The account that owns the vault shares to be burnt.
     * @param customRedeemSlippage Redeem slippage in basis points i.e. 1% = 100.
     * @return assets The amount of underlying assets that were transferred to the receiver.
     * @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (eg DAI)
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 customRedeemSlippage
    ) external virtual whenNotPaused returns (uint256 assets) {
        assets = _redeemInternal(shares, receiver, owner, customRedeemSlippage);
    }

    /// @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (eg DAI)
    function _redeemInternal(
        uint256 _shares,
        address _receiver,
        address _owner,
        uint256 _slippage
    ) internal virtual returns (uint256 assets) {
        if (_shares > 0) {
            uint256 allowed = allowance(_owner, msg.sender);
            if (msg.sender != _owner && allowed != type(uint256).max) {
                require(_shares <= allowed, "Amount exceeds allowance");
                _approve(_owner, msg.sender, allowed - _shares);
            }

            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
            // Convert this vault's shares to underlying meta vault shares.
            uint256 metaVaultShares = _getMetaVaultSharesFromShares(
                _shares,
                totalMetaVaultShares,
                totalSupply()
            );

            // Burn underlying meta vault shares and receive 3Pool LP tokens (3Crv).
            uint256 threeCrvTokens = metaVault.redeem(
                metaVaultShares,
                address(this),
                address(this)
            );

            // Protect against sandwich and flash loan attacks where the balance of the 3Pool can be manipulated.
            // Get virtual price of Curve 3Pool LP tokens (3Crv) in USD.
            uint256 virtualPrice = Curve3PoolCalculatorLibrary.getVirtualPrice();

            // Calculate fair USD amount for burning 3Crv.
            // 3Pool virtual price (3Crv/USD) = pool invariant (USD value) * virtual price scale / total supply of LP token (3Crv).
            // 3Crv amount = USD amount * 3Pool virtual price / virtial price scale
            // USD amount = 3Crv amount * virtial price scale / 3Pool virtual price
            uint256 minAssets = (threeCrvTokens * Curve3PoolCalculatorLibrary.VIRTUAL_PRICE_SCALE) /
                virtualPrice;
            // Min USD = USD amount + (1 - mint slippage). So for 1% slippage, USD amount * 0.99
            // We will assume 1 DAI is close to 1 USD so min USD = min assets (DAI, USDC or USDT).
            minAssets = (minAssets * (BASIS_SCALE - _slippage)) / BASIS_SCALE;
            // USD value is scaled to 18 decimals, it needs to be scaled to asset decimals.
            minAssets = minAssets / assetFromUsdScale;

            // Burn 3Pool LP tokens (3Crv) and receive this vault's asset (DAI, USDC or USDT).
            ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).remove_liquidity_one_coin(
                threeCrvTokens,
                int128(uint128(assetPoolIndex)),
                minAssets
            );

            _burn(_owner, _shares);

            // Need to get how many assets was withdrawn from the 3Pool as it will be more than
            // the assets amount passed into this function for redeem()
            assets = _asset.balanceOf(address(this));

            // Transfer this vault's asssets (DAI, USDC or USDT) to the receiver.
            _asset.safeTransfer(_receiver, assets);

            emit Withdraw(msg.sender, _receiver, _owner, assets, _shares);
        }
    }

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current transaction, given current on-chain conditions.
     * @param shares The amount of vault shares to be burnt.
     * @return assets The amount of each underlying assest tokens that will transferred to the receiver.
     * @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (eg DAI)
     */
    function previewRedeem(uint256 shares) external view virtual override returns (uint256 assets) {
        assets = _previewRedeem(shares);
    }

    function _previewRedeem(uint256 shares) internal view virtual returns (uint256 assets) {
        if (shares > 0) {
            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));

            // Convert this vault's shares to underlying meta vault shares.
            uint256 metaVaultShares = _getMetaVaultSharesFromShares(
                shares,
                totalMetaVaultShares,
                totalSupply()
            );

            // Convert underlying meta vault shares to 3Pool LP tokens (3Crv).
            uint256 threeCrvTokens = metaVault.previewRedeem(metaVaultShares);

            // Convert 3Pool LP tokens (3Crv) to assets (DAI, USDC or USDT).
            (assets, , ) = Curve3PoolCalculatorLibrary.calcRedeem(threeCrvTokens, assetPoolIndex);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
     * @param shares The amount of vault shares to be converted to the underlying assets.
     * @return assets The amount of underlying assets converted from the vault shares.
     * @dev Vault shares -> Meta Vault shares -> Meta Vault assets (3Crv) -> vault assets (DAI, USDC or USDT)
     */
    function convertToAssets(uint256 shares)
        external
        view
        virtual
        override
        returns (uint256 assets)
    {
        uint256 metaVaultShares;
        uint256 totalShares = totalSupply();
        if (totalShares == 0) {
            // start with 1:1 value of shares to underlying meta vault shares
            metaVaultShares = shares;
        } else {
            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
            // Convert this vault's shares to underlying meta vault shares.
            metaVaultShares = _getMetaVaultSharesFromShares(
                shares,
                totalMetaVaultShares,
                totalShares
            );
        }

        // Convert underlying meta vault shares to 3Crv
        // This uses the Metapool and 3Pool virtual prices
        uint256 threeCrvTokens = metaVault.convertToAssets(metaVaultShares);
        // Convert 3Crv to assets (DAI, USDC or USDT) by extrapolating redeeming 1 3Crv.
        assets = _getAssetsForThreeCrvTokens(threeCrvTokens);
    }

    /**
     * @notice The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.
     * @param assets The amount of underlying assets to be convert to vault shares.
     * @return shares The amount of vault shares converted from the underlying assets.
     * @dev Vault assets (DAI, USDC or USDT) -> Meta Vault assets (3Crv) -> Meta Vault shares -> this vault's shares
     */
    function convertToShares(uint256 assets)
        external
        view
        virtual
        override
        returns (uint256 shares)
    {
        // Calculate fair amount of 3Pool LP tokens (3Crv) using virtual prices for vault assets, eg DAI
        uint256 threeCrvTokens = _getThreeCrvTokensForAssets(assets);

        // Convert 3Crv to underlying meta vault shares.
        // This uses the Metapool and 3Pool virtual prices.
        uint256 metaVaultShares = metaVault.convertToShares(threeCrvTokens);

        uint256 totalShares = totalSupply();
        if (totalShares == 0) {
            // start with 1:1 value of shares to underlying meta vault shares
            shares = metaVaultShares;
        } else {
            // Get the total underlying Meta Vault shares held by this vault.
            uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));
            shares = _getSharesFromMetaVaultShares(
                metaVaultShares,
                totalMetaVaultShares,
                totalShares
            );
        }
    }

    /***************************************
                    Utility
    ****************************************/

    /// @dev Deposit asset (DAI, USDC or USDT) into 3Pool and then deposit 3Crv into underlying meta vault.
    function _addAndDeposit(uint256 _assets, uint256 _minThreeCrvTokens)
        internal
        returns (uint256 metaVaultShares_)
    {
        // Get asset array of underlying to be deposited in the pool
        uint256[3] memory assetsArray;
        assetsArray[assetPoolIndex] = _assets;

        // Add assets, eg DAI, to the 3Pool and receive 3Pool LP tokens (3Crv)
        ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).add_liquidity(
            assetsArray,
            _minThreeCrvTokens
        );

        // Deposit 3Crv into the underlying meta vault and receive meta vault shares.
        // This assumes there is no 3Crv sitting in this vault. If there is, the caller will get extra vault shares.
        // Meta Vault deposits do not need sandwich attack protection.
        metaVaultShares_ = metaVault.deposit(
            IERC20(Curve3PoolCalculatorLibrary.LP_TOKEN).balanceOf(address(this)),
            address(this)
        );
    }

    /// @dev Utility function to convert 3Crv tokens to expected asset tokens (DAI, USDC or USDT) from Curve's 3Pool.
    /// Extrapolates assets received for redeeming on 3Pool LP token (3Crv).
    /// @param _threeCrvTokens Amount of 3Crv tokens to burn.
    /// @return expectedAssets Amount of asset tokens expected from Curve 3Pool.
    function _getAssetsForThreeCrvTokens(uint256 _threeCrvTokens)
        internal
        view
        returns (uint256 expectedAssets)
    {
        if (_threeCrvTokens > 0) {
            // convert 1 3Crv to the vault assets (DAI, USDC or USDT) per 3Crv
            (uint256 assetsPer3Crv, , ) = Curve3PoolCalculatorLibrary.calcRedeem(
                threeCrvTokenScale,
                assetPoolIndex
            );
            // Convert 3Crv amount to assets (DAI, USDC or USDT)
            expectedAssets = (_threeCrvTokens * assetsPer3Crv) / threeCrvTokenScale;
        }
    }

    /// @dev Utility function to convert asset (DAI, USDC or USDT) amount to fair 3Crv token amount.
    /// @param _assetsAmount Amount of assets (DAI, USDC or USDT) to burn.
    /// @return expectedthreeCrvTokens Fair amount of 3Crv tokens expected from Curve 3Pool.
    function _getThreeCrvTokensForAssets(uint256 _assetsAmount)
        internal
        view
        returns (uint256 expectedthreeCrvTokens)
    {
        // Curve 3Pool lp token virtual price which is the price of one scaled 3Crv (USD/3Crv). Non-manipulable
        uint256 lpVirtualPrice = Curve3PoolCalculatorLibrary.getVirtualPrice();

        // Amount of 3Pool lp tokens (3Crv) corresponding to asset tokens (DAI, USDC or USDT)
        // Assume 1 DAI == 1 USD
        // 3Crv amount = DAI amount / 3Crv/USD virtual price
        expectedthreeCrvTokens =
            (Curve3PoolCalculatorLibrary.VIRTUAL_PRICE_SCALE * _assetsAmount * threeCrvTokenScale) /
            (lpVirtualPrice * assetScale);
    }

    /// @param _metaVaultShares Underlying vault shares from deposit or withdraw.
    /// @param _totalMetaVaultShares Total number of Underlying vault shares owned by this vault.
    /// @param _totalShares Total shares of this vault before deposit or withdraw.
    /// @return shares Vault shares for deposit or withdraw.
    function _getSharesFromMetaVaultShares(
        uint256 _metaVaultShares,
        uint256 _totalMetaVaultShares,
        uint256 _totalShares
    ) internal pure returns (uint256 shares) {
        if (_totalMetaVaultShares == 0) {
            shares = _metaVaultShares;
        } else {
            shares = (_metaVaultShares * _totalShares) / _totalMetaVaultShares;
        }
    }

    function _getMetaVaultSharesFromShares(
        uint256 _shares,
        uint256 _totalMetaVaultShares,
        uint256 _totalShares
    ) internal pure returns (uint256 metaVaultShares) {
        if (_totalShares == 0) {
            metaVaultShares = _shares;
        } else {
            metaVaultShares = (_shares * _totalMetaVaultShares) / _totalShares;
        }
    }

    /***************************************
                    Emergency Functions
    ****************************************/

    /**
     * @notice Governor liquidates all the vault's assets and send to the governor.
     * Only to be used in an emergency. eg whitehat protection against a hack.
     * @param minAssets Minimum amount of asset tokens to receive from removing liquidity from the Curve 3Pool.
     * This provides sandwich attack protection.
     */
    function liquidateVault(uint256 minAssets) external onlyGovernor {
        uint256 totalMetaVaultShares = metaVault.balanceOf(address(this));

        metaVault.redeem(totalMetaVaultShares, address(this), address(this));

        ICurve3Pool(Curve3PoolCalculatorLibrary.THREE_POOL).remove_liquidity_one_coin(
            IERC20(Curve3PoolCalculatorLibrary.LP_TOKEN).balanceOf(address(this)),
            int128(uint128(assetPoolIndex)),
            minAssets
        );

        _asset.safeTransfer(_governor(), _asset.balanceOf(address(this)));
    }

    /***************************************
                    Set Vault Parameters
    ****************************************/

    /// @notice Approves Curve's 3Pool contract to transfer assets (DAI, USDC or USDT) from this vault.
    /// Also approves the underlying Meta Vault to transfer 3Crv from this vault.
    function resetAllowances() external onlyGovernor {
        _resetAllowances();
    }

    /// @dev Approves Curve's 3Pool contract to transfer assets (DAI, USDC or USDT) from this vault.
    /// Also approves the underlying Meta Vault to transfer 3Crv from this vault.
    function _resetAllowances() internal {
        _asset.safeApprove(address(Curve3PoolCalculatorLibrary.THREE_POOL), type(uint256).max);
        IERC20(Curve3PoolCalculatorLibrary.LP_TOKEN).safeApprove(
            address(metaVault),
            type(uint256).max
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title   Tokenized Vault Standard (ERC-4626) Interface
 * @author  mStable
 * @notice  See the following for the full ERC-4626 specification https://eips.ethereum.org/EIPS/eip-4626.
 * @dev     VERSION: 1.0
 *          DATE:    2022-02-10
 */
interface IERC4626Vault is IERC20 {
    /// @notice The address of the underlying token used by the Vault for valuing, depositing, and withdrawing.
    function asset() external view returns (address assetTokenAddress);

    /// @notice Total amount of the underlying asset that is “managed” by vault.
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @notice The amount of shares that the Vault would exchange for the amount of assets provided, in an ideal scenario where all the conditions are met.
     * @param assets The amount of underlying assets to be convert to vault shares.
     * @return shares The amount of vault shares converted from the underlying assets.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice The amount of assets that the Vault would exchange for the amount of shares provided, in an ideal scenario where all the conditions are met.
     * @param shares The amount of vault shares to be converted to the underlying assets.
     * @return assets The amount of underlying assets converted from the vault shares.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice The maximum number of underlying assets that caller can deposit.
     * @param caller Account that the assets will be transferred from.
     * @return maxAssets The maximum amount of underlying assets the caller can deposit.
     */
    function maxDeposit(address caller) external view returns (uint256 maxAssets);

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current transaction, given current on-chain conditions.
     * @param assets The amount of underlying assets to be transferred.
     * @return shares The amount of vault shares that will be minted.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Mint vault shares to receiver by transferring exact amount of underlying asset tokens from the caller.
     * @param assets The amount of underlying assets to be transferred to the vault.
     * @param receiver The account that the vault shares will be minted to.
     * @return shares The amount of vault shares that were minted.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @notice The maximum number of vault shares that caller can mint.
     * @param caller Account that the underlying assets will be transferred from.
     * @return maxShares The maximum amount of vault shares the caller can mint.
     */
    function maxMint(address caller) external view returns (uint256 maxShares);

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their mint at the current transaction, given current on-chain conditions.
     * @param shares The amount of vault shares to be minted.
     * @return assets The amount of underlying assests that will be transferred from the caller.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Mint exact amount of vault shares to the receiver by transferring enough underlying asset tokens from the caller.
     * @param shares The amount of vault shares to be minted.
     * @param receiver The account the vault shares will be minted to.
     * @return assets The amount of underlying assets that were transferred from the caller.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @notice The maximum number of underlying assets that owner can withdraw.
     * @param owner Account that owns the vault shares.
     * @return maxAssets The maximum amount of underlying assets the owner can withdraw.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current transaction, given current on-chain conditions.
     * @param assets The amount of underlying assets to be withdrawn.
     * @return shares The amount of vault shares that will be burnt.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @notice Burns enough vault shares from owner and transfers the exact amount of underlying asset tokens to the receiver.
     * @param assets The amount of underlying assets to be withdrawn from the vault.
     * @param receiver The account that the underlying assets will be transferred to.
     * @param owner Account that owns the vault shares to be burnt.
     * @return shares The amount of vault shares that were burnt.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @notice The maximum number of shares an owner can redeem for underlying assets.
     * @param owner Account that owns the vault shares.
     * @return maxShares The maximum amount of shares the owner can redeem.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @notice Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current transaction, given current on-chain conditions.
     * @param shares The amount of vault shares to be burnt.
     * @return assets The amount of underlying assests that will transferred to the receiver.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @notice Burns exact amount of vault shares from owner and transfers the underlying asset tokens to the receiver.
     * @param shares The amount of vault shares to be burnt.
     * @param receiver The account the underlying assets will be transferred to.
     * @param owner The account that owns the vault shares to be burnt.
     * @return assets The amount of underlying assets that were transferred to the receiver.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /**
     * @dev Emitted when sender has exchanged assets for shares, and transferred those shares to receiver.
     *
     * Note It must be emitted when tokens are deposited into the Vault in ERC4626.mint or ERC4626.deposit methods.
     */
    event Deposit(address indexed sender, address indexed receiver, uint256 assets, uint256 shares);

    /**
     * @dev Emitted when owner has exchanged shares for assets, and transferred those assets to receiver.
     *
     * Note It must be emitted when shares are withdrawn from the Vault in ERC4626.redeem or ERC4626.withdraw methods.
     */
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ModuleKeys } from "./ModuleKeys.sol";
import { INexus } from "../interfaces/INexus.sol";

/**
 * @notice  Provides modifiers and internal functions to check modules and roles in the `Nexus` registry.
 * For example, the `onlyGovernor` modifier validates the caller is the `Governor` in the `Nexus`.
 * @author  mStable
 * @dev     Subscribes to module updates from a given publisher and reads from its registry.
 *          Contract is used for upgradable proxy contracts.
 */
abstract contract ImmutableModule is ModuleKeys {
    /// @notice `Nexus` contract that resolves protocol modules and roles.
    INexus public immutable nexus;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _nexus Address of the Nexus contract that resolves protocol modules and roles.
     */
    constructor(address _nexus) {
        require(_nexus != address(0), "Nexus address is zero");
        nexus = INexus(_nexus);
    }

    /// @dev Modifier to allow function calls only from the Governor.
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /// @dev Modifier to allow function calls only from the Governor or the Keeper EOA.
    modifier onlyKeeperOrGovernor() {
        _keeperOrGovernor();
        _;
    }

    function _keeperOrGovernor() internal view {
        require(msg.sender == _keeper() || msg.sender == _governor(), "Only keeper or governor");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
    }

    /**
     * @dev Returns Governance Module address from the Nexus
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return nexus.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Keeper address from the Nexus.
     *      This account is used for operational transactions that
     *      don't need multiple signatures.
     * @return  Address of the Keeper externally owned account.
     */
    function _keeper() internal view returns (address) {
        return nexus.getModule(KEY_KEEPER);
    }

    /**
     * @dev Return Liquidator module address from the Nexus
     * @return  Address of the Liquidator contract
     */
    function _liquidator() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR);
    }

    /**
     * @dev Return Liquidator V2 module address from the Nexus
     * @return  Address of the Liquidator V2 contract
     */
    function _liquidatorV2() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR_V2);
    }

    /**
     * @dev Return ProxyAdmin module address from the Nexus
     * @return Address of the ProxyAdmin contract
     */
    function _proxyAdmin() internal view returns (address) {
        return nexus.getModule(KEY_PROXY_ADMIN);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title  ModuleKeys
 * @author mStable
 * @notice Provides system wide access to the byte32 represntations of system modules
 *         This allows each system module to be able to reference and update one another in a
 *         friendly way
 * @dev    keccak256() values are hardcoded to avoid re-evaluation of the constants at runtime.
 */
contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("LiquidatorV2");
    bytes32 internal constant KEY_LIQUIDATOR_V2 =
        0x4609f0c2814c5fc06ab61e580b24d36b621602ec696fa6680495a87fc21afb80;
    // keccak256("Keeper");
    bytes32 internal constant KEY_KEEPER =
        0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title INexus
 * @dev Basic interface for interacting with the Nexus i.e. SystemKernel
 */
interface INexus {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title  Token name, symbol and decimals are initializable.
 * @author mStable
 * @dev Optional functions from the ERC20 standard.
 * Converted from openzeppelin/contracts/token/ERC20/ERC20Detailed.sol
 */
abstract contract InitializableTokenDetails {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     * @notice To avoid variable shadowing appended `Arg` after arguments name.
     */
    function _initialize(
        string memory nameArg,
        string memory symbolArg,
        uint8 decimalsArg
    ) internal virtual {
        _name = nameArg;
        _symbol = symbolArg;
        _decimals = decimalsArg;
    }

    /// @return name_ The `name` of the token.
    function name() public view virtual returns (string memory name_) {
        name_ = _name;
    }

    /// @return symbol_ The symbol of the token, usually a shorter version of the name.
    function symbol() public view virtual returns (string memory symbol_) {
        symbol_ = _symbol;
    }

    /**
     * @notice Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8 decimals_) {
        decimals_ = _decimals;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICurveRegistryContract {
    function find_pool_for_coins(address _from, address _to) external view returns (address);

    function find_pool_for_coins(
        address _from,
        address _to,
        uint256 i
    ) external view returns (address);

    function get_n_coins(address _pool) external view returns (uint256[2] memory);

    function get_coins(address _pool) external view returns (address[8] memory);

    function get_underlying_coins(address _pool) external view returns (address[8] memory);

    function get_decimals(address _pool) external view returns (uint256[8] memory);

    function get_underlying_decimals(address _pool) external view returns (uint256[8] memory);

    function get_rates(address _pool) external view returns (uint256[8] memory);

    function get_gauges(address _pool)
        external
        view
        returns (address[10] memory, int128[10] memory);

    function get_balances(address _pool) external view returns (uint256[8] memory);

    function get_underlying_balances(address _pool) external view returns (uint256[8] memory);

    function get_virtual_price_from_lp_token(address _token) external view returns (uint256);

    function get_A(address _pool) external view returns (uint256);

    function get_parameters(address _pool)
        external
        view
        returns (
            uint256 A,
            uint256 future_A,
            uint256 fee,
            uint256 admin_fee,
            uint256 future_fee,
            uint256 future_admin_fee,
            address future_owner,
            uint256 initial_A,
            uint256 initial_A_time,
            uint256 future_A_time
        );

    function get_fees(address _pool) external view returns (uint256[2] memory);

    function get_admin_balances(address _pool) external view returns (uint256[8] memory);

    function get_coin_indices(
        address _pool,
        address _from,
        address _to
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function estimate_gas_used(
        address _pool,
        address _from,
        address _to
    ) external view returns (uint256);

    function is_meta(address _pool) external view returns (bool);

    function get_pool_name(address _pool) external view returns (string memory);

    function get_coin_swap_count(address _coin) external view returns (uint256);

    function get_coin_swap_complement(address _coin, uint256 _index)
        external
        view
        returns (address);

    function get_pool_asset_type(address _pool) external view returns (uint256);

    function add_pool(
        address _pool,
        uint256 _n_coins,
        address _lp_token,
        bytes32 _rate_info,
        uint256 _decimals,
        uint256 _underlying_decimals,
        bool _has_initial_A,
        bool _is_v1,
        string memory _name
    ) external;

    function add_pool_without_underlying(
        address _pool,
        uint256 _n_coins,
        address _lp_token,
        bytes32 _rate_info,
        uint256 _decimals,
        uint256 _use_rates,
        bool _has_initial_A,
        bool _is_v1,
        string memory _name
    ) external;

    function add_metapool(
        address _pool,
        uint256 _n_coins,
        address _lp_token,
        uint256 _decimals,
        string memory _name
    ) external;

    function add_metapool(
        address _pool,
        uint256 _n_coins,
        address _lp_token,
        uint256 _decimals,
        string memory _name,
        address _base_pool
    ) external;

    function remove_pool(address _pool) external;

    function set_pool_gas_estimates(address[5] memory _addr, uint256[2][5] memory _amount) external;

    function set_coin_gas_estimates(address[10] memory _addr, uint256[10] memory _amount) external;

    function set_gas_estimate_contract(address _pool, address _estimator) external;

    function set_liquidity_gauges(address _pool, address[10] memory _liquidity_gauges) external;

    function set_pool_asset_type(address _pool, uint256 _asset_type) external;

    function batch_set_pool_asset_type(address[32] memory _pools, uint256[32] memory _asset_types)
        external;

    function address_provider() external view returns (address);

    function gauge_controller() external view returns (address);

    function pool_list(uint256 arg0) external view returns (address);

    function pool_count() external view returns (uint256);

    function coin_count() external view returns (uint256);

    function get_coin(uint256 arg0) external view returns (address);

    function get_pool_from_lp_token(address arg0) external view returns (address);

    function get_lp_token(address arg0) external view returns (address);

    function last_updated() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function max_id() external view returns (uint256);

    function get_address(uint256 _id) external view returns (address);

    function add_new_id(address _address, string memory _description) external returns (uint256);

    function set_address(uint256 _id, address _address) external returns (bool);

    function unset_address(uint256 _id) external returns (bool);

    function commit_transfer_ownership(address _new_admin) external returns (bool);

    function apply_transfer_ownership() external returns (bool);

    function revert_transfer_ownership() external returns (bool);

    function admin() external view returns (address);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_admin() external view returns (address);

    function get_id_info(uint256 arg0)
        external
        view
        returns (
            address addr,
            bool is_active,
            uint256 version,
            uint256 last_modified,
            string memory description
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ICurve3Pool {
    function A() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[3] memory amounts, bool deposit)
        external
        view
        returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory amounts, uint256 max_burn_amount)
        external;

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function commit_new_fee(uint256 new_fee, uint256 new_admin_fee) external;

    function apply_new_fee() external;

    function revert_new_parameters() external;

    function commit_transfer_ownership(address _owner) external;

    function apply_transfer_ownership() external;

    function revert_transfer_ownership() external;

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;

    function donate_admin_fees() external;

    function kill_me() external;

    function unkill_me() external;

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function owner() external view returns (address);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function admin_actions_deadline() external view returns (uint256);

    function transfer_ownership_deadline() external view returns (uint256);

    function future_fee() external view returns (uint256);

    function future_admin_fee() external view returns (uint256);

    function future_owner() external view returns (address);

    // Events
    event TokenExchange(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );

    event AddLiquidity(
        address indexed provider,
        uint256[3] token_amounts,
        uint256[3] fees,
        uint256 invariant,
        uint256 token_supply
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256[3] token_amounts,
        uint256[3] fees,
        uint256 token_supply
    );

    event RemoveLiquidityOne(
        address indexed provider,
        uint256[3] token_amount,
        uint256 coin_amount
    );

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[3] token_amounts,
        uint256[3] fees,
        uint256 invariant,
        uint256 token_supply
    );

    event CommitNewFee(uint256 indexed deadline, uint256 fee, uint256 admin_fee);

    event NewFee(uint256 fee, uint256 admin_fee);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ICurve3Pool } from "./ICurve3Pool.sol";

/**
 * @title   Calculates Curve token amounts including fees for the Curve.fi 3Pool.
 * @notice  This has been configured to work for Curve 3Pool which contains DAI, USDC and USDT.
 * This is an alternative to Curve's `calc_token_amount` which does not take into account fees.
 * This library takes into account pool fees.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-07-12
 * @dev     See Atul Agarwal's post "Understanding the Curve AMM, Part -1: StableSwap Invariant"
 *          for an explaination of the maths behind StableSwap. This includes an explation of the
 *          variables S, D, Ann used in _getD
 *          https://atulagarwal.dev/posts/curveamm/stableswap/
 */
library Curve3PoolCalculatorLibrary {
    /// @notice Number of coins in the pool.
    uint256 public constant N_COINS = 3;
    uint256 public constant VIRTUAL_PRICE_SCALE = 1e18;
    /// @notice Scale of the Curve.fi metapool fee. 100% = 1e10, 0.04% = 4e6.
    uint256 public constant CURVE_FEE_SCALE = 1e10;
    /// @notice Address of the Curve.fi 3Pool contract.
    address public constant THREE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    /// @notice Address of the Curve.fi 3Pool liquidity token (3Crv).
    address public constant LP_TOKEN = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    /// @notice Scales up the mint tokens by 0.002 basis points.
    uint256 public constant MINT_ADJUST = 10000002;
    uint256 public constant MINT_ADJUST_SCALE = 10000000;

    /**
     * @notice Calculates the amount of liquidity provider tokens (3Crv) to mint for depositing a fixed amount of pool tokens.
     * @param _tokenAmount The amount of coins, eg DAI, USDC or USDT, to deposit.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return mintAmount_ The amount of liquidity provider tokens (3Crv) to mint.
     * @return invariant_ The invariant before the deposit. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the deposit.
     */
    function calcDeposit(uint256 _tokenAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 mintAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        // To save gas, only deal with deposits when there are already coins in the 3Pool.
        require(totalSupply_ > 0, "empty THREE_POOL");

        // Get balance of each stablecoin in the 3Pool
        uint256[N_COINS] memory oldBalances = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1), // USDC
            ICurve3Pool(THREE_POOL).balances(2) // USDT
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory oldBalancesScaled = [
            oldBalances[0],
            oldBalances[1] * 1e12,
            oldBalances[2] * 1e12
        ];

        // Get 3Pool amplitude coefficient (A)
        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // USD value before deposit
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Add deposit to corresponding balance
        uint256[N_COINS] memory newBalances = [
            _coinIndex == 0 ? oldBalances[0] + _tokenAmount : oldBalances[0],
            _coinIndex == 1 ? oldBalances[1] + _tokenAmount : oldBalances[1],
            _coinIndex == 2 ? oldBalances[2] + _tokenAmount : oldBalances[2]
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory newBalancesScaled = [
            newBalances[0],
            newBalances[1] * 1e12,
            newBalances[2] * 1e12
        ];

        // Invariant after deposit
        uint256 invariantAfterDeposit = _getD(newBalancesScaled, Ann);

        // We need to recalculate the invariant accounting for fees
        // to calculate fair user's share
        // _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 idealBalanceScaled = (invariantAfterDeposit * oldBalances[0]) / invariant_;
        uint256 differenceScaled = idealBalanceScaled > newBalances[0]
            ? idealBalanceScaled - newBalances[0]
            : newBalances[0] - idealBalanceScaled;
        newBalancesScaled[0] = newBalances[0] - ((fee * differenceScaled) / CURVE_FEE_SCALE);

        // USDC at index 1
        idealBalanceScaled = (invariantAfterDeposit * oldBalances[1]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[1]
            ? idealBalanceScaled - newBalances[1]
            : newBalances[1] - idealBalanceScaled;
        // Scale up USDC from 6 to 18 decimals
        newBalancesScaled[1] = (newBalances[1] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // USDT at index 2
        idealBalanceScaled = (invariantAfterDeposit * oldBalances[2]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[2]
            ? idealBalanceScaled - newBalances[2]
            : newBalances[2] - idealBalanceScaled;
        // Scale up USDT from 6 to 18 decimals
        newBalancesScaled[2] = (newBalances[2] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // Calculate, how much pool tokens to mint
        // LP tokens to mint = total LP tokens * (USD value after - USD value before) / USD value before
        mintAmount_ = (totalSupply_ * (_getD(newBalancesScaled, Ann) - invariant_)) / invariant_;
    }

    /**
     * @notice Calculates the amount of liquidity provider tokens (3Crv) to burn for receiving a fixed amount of pool tokens.
     * @param _tokenAmount The amount of coins, eg DAI, USDC or USDT, required to receive.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return burnAmount_ The amount of liquidity provider tokens (3Crv) to burn.
     * @return invariant_ The invariant before the withdraw. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the withdraw.
     */
    function calcWithdraw(uint256 _tokenAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 burnAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        require(totalSupply_ > 0, "empty THREE_POOL");

        // Get balance of each stablecoin in the 3Pool
        uint256[N_COINS] memory oldBalances = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1), // USDC
            ICurve3Pool(THREE_POOL).balances(2) // USDT
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory oldBalancesScaled = [
            oldBalances[0],
            oldBalances[1] * 1e12,
            oldBalances[2] * 1e12
        ];

        // Get 3Pool amplitude coefficient (A)
        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // USD value before withdraw
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Remove withdraw from corresponding balance
        uint256[N_COINS] memory newBalances = [
            _coinIndex == 0 ? oldBalances[0] - _tokenAmount : oldBalances[0],
            _coinIndex == 1 ? oldBalances[1] - _tokenAmount : oldBalances[1],
            _coinIndex == 2 ? oldBalances[2] - _tokenAmount : oldBalances[2]
        ];
        // Scale USDC and USDT from 6 decimals up to 18 decimals
        uint256[N_COINS] memory newBalancesScaled = [
            newBalances[0],
            newBalances[1] * 1e12,
            newBalances[2] * 1e12
        ];

        // Invariant after withdraw
        uint256 invariantAfterWithdraw = _getD(newBalancesScaled, Ann);

        // We need to recalculate the invariant accounting for fees
        // to calculate fair user's share
        // _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 idealBalanceScaled = (invariantAfterWithdraw * oldBalances[0]) / invariant_;
        uint256 differenceScaled = idealBalanceScaled > newBalances[0]
            ? idealBalanceScaled - newBalances[0]
            : newBalances[0] - idealBalanceScaled;
        newBalancesScaled[0] = newBalances[0] - ((fee * differenceScaled) / CURVE_FEE_SCALE);

        // USDC at index 1
        idealBalanceScaled = (invariantAfterWithdraw * oldBalances[1]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[1]
            ? idealBalanceScaled - newBalances[1]
            : newBalances[1] - idealBalanceScaled;
        // Scale up USDC from 6 to 18 decimals
        newBalancesScaled[1] = (newBalances[1] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // USDT at index 2
        idealBalanceScaled = (invariantAfterWithdraw * oldBalances[2]) / invariant_;
        differenceScaled = idealBalanceScaled > newBalances[2]
            ? idealBalanceScaled - newBalances[2]
            : newBalances[2] - idealBalanceScaled;
        // Scale up USDT from 6 to 18 decimals
        newBalancesScaled[2] = (newBalances[2] - (fee * differenceScaled) / CURVE_FEE_SCALE) * 1e12;

        // Calculate, how much pool tokens to burn
        // LP tokens to burn = total LP tokens * (USD value before - USD value after) / USD value before
        burnAmount_ =
            ((totalSupply_ * (invariant_ - _getD(newBalancesScaled, Ann))) / invariant_) +
            1;
    }

    /**
     * @notice Calculates the amount of pool coins to deposit for minting a fixed amount of liquidity provider tokens (3Crv).
     * @param _mintAmount The amount of liquidity provider tokens (3Crv) to mint.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return tokenAmount_ The amount of coins, eg DAI, USDC or USDT, to deposit.
     * @return invariant_ The invariant before the mint. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the mint.
     */
    function calcMint(uint256 _mintAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 tokenAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        // To save gas, only deal with mints when there are already coins in the 3Pool.
        require(totalSupply_ > 0, "empty THREE_POOL");

        // Get 3Pool balances and scale to 18 decimal
        uint256[N_COINS] memory oldBalancesScaled = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1) * 1e12, // USDC
            ICurve3Pool(THREE_POOL).balances(2) * 1e12 // USDT
        ];

        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // Get invariant before mint
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Desired invariant after mint
        uint256 invariantAfterMint = invariant_ + ((_mintAmount * invariant_) / totalSupply_);

        // Required coin balance to get to the new invariant after mint
        uint256 requiredBalanceScaled = _getY(
            oldBalancesScaled,
            Ann,
            _coinIndex,
            invariantAfterMint
        );

        // Adjust balances for fees
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;
        uint256[N_COINS] memory newBalancesScaled;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 dx_expected = _coinIndex == 0
            ? requiredBalanceScaled - ((oldBalancesScaled[0] * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled[0] * invariantAfterMint) / invariant_) - oldBalancesScaled[0];
        // the -1 covers 18 decimal rounding issues
        newBalancesScaled[0] = oldBalancesScaled[0] - ((dx_expected * fee) / CURVE_FEE_SCALE) - 1;

        // USDC at index 1
        dx_expected = _coinIndex == 1
            ? requiredBalanceScaled - ((oldBalancesScaled[1] * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled[1] * invariantAfterMint) / invariant_) - oldBalancesScaled[1];
        // the -1e12 covers 6 decimal rounding issues
        newBalancesScaled[1] =
            oldBalancesScaled[1] -
            ((dx_expected * fee) / CURVE_FEE_SCALE) -
            1e12;

        // USDT at index 2
        dx_expected = _coinIndex == 2
            ? requiredBalanceScaled - ((oldBalancesScaled[2] * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled[2] * invariantAfterMint) / invariant_) - oldBalancesScaled[2];
        // the -1e12 covers 6 decimal rounding issues
        newBalancesScaled[2] =
            oldBalancesScaled[2] -
            ((dx_expected * fee) / CURVE_FEE_SCALE) -
            1e12;

        // tokens (DAI, USDC or USDT) to transfer from caller scaled to 18 decimals
        tokenAmount_ =
            _getY(newBalancesScaled, Ann, _coinIndex, invariantAfterMint) -
            newBalancesScaled[_coinIndex];
        // If DAI then already 18 decimals, else its USDC or USDT so need to scale down to only 6 decimals
        // Deposit more to account for rounding errors
        tokenAmount_ = _coinIndex == 0 ? tokenAmount_ : tokenAmount_ / 1e12;

        // Round up the amount
        tokenAmount_ = (tokenAmount_ * MINT_ADJUST) / MINT_ADJUST_SCALE;
    }

    /**
     * @notice Calculates the amount of pool coins to receive for redeeming a fixed amount of liquidity provider tokens (3Crv).
     * @param _burnAmount The amount of liquidity provider tokens (3Crv) to burn.
     * @param _coinIndex The index of the coin in the pool to withdraw. 0 = DAI, 1 = USDC, 2 = USDT.
     * @return tokenAmount_ The amount of coins, eg DAI, USDC or USDT, to receive from the redeem.
     * @return invariant_ The invariant before the redeem. This is the USD value of the 3Pool.
     * @return totalSupply_ Total liquidity provider tokens (3Crv) before the redeem.
     */
    function calcRedeem(uint256 _burnAmount, uint256 _coinIndex)
        external
        view
        returns (
            uint256 tokenAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(LP_TOKEN).totalSupply();
        require(totalSupply_ > 0, "empty THREE_POOL");

        uint256[N_COINS] memory oldBalancesScaled = [
            ICurve3Pool(THREE_POOL).balances(0), // DAI
            ICurve3Pool(THREE_POOL).balances(1) * 1e12, // USDC
            ICurve3Pool(THREE_POOL).balances(2) * 1e12 // USDT
        ];

        uint256 Ann = ICurve3Pool(THREE_POOL).A() * N_COINS;

        // Get invariant before redeem
        invariant_ = _getD(oldBalancesScaled, Ann);

        // Desired invariant after redeem
        uint256 invariantAfterRedeem = invariant_ - ((_burnAmount * invariant_) / totalSupply_);

        // Required coin balance to get to the new invariant after redeem
        uint256 requiredBalanceScaled = _getY(
            oldBalancesScaled,
            Ann,
            _coinIndex,
            invariantAfterRedeem
        );

        // Adjust balances for fees
        // _fee: uint256 = self.fee * N_COINS / (4 * (N_COINS - 1))
        uint256 fee = (ICurve3Pool(THREE_POOL).fee() * 3) / 8;
        uint256[N_COINS] memory newBalancesScaled;

        // The following is not in a for loop to save gas

        // DAI at index 0
        uint256 dx_expected = _coinIndex == 0
            ? ((oldBalancesScaled[0] * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled[0] - (oldBalancesScaled[0] * invariantAfterRedeem) / invariant_;
        newBalancesScaled[0] = oldBalancesScaled[0] - ((dx_expected * fee) / CURVE_FEE_SCALE);

        // USDC at index 1
        dx_expected = _coinIndex == 1
            ? ((oldBalancesScaled[1] * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled[1] - (oldBalancesScaled[1] * invariantAfterRedeem) / invariant_;
        newBalancesScaled[1] = oldBalancesScaled[1] - ((dx_expected * fee) / CURVE_FEE_SCALE);

        // USDT at index 2
        dx_expected = _coinIndex == 2
            ? ((oldBalancesScaled[2] * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled[2] - (oldBalancesScaled[2] * invariantAfterRedeem) / invariant_;
        newBalancesScaled[2] = oldBalancesScaled[2] - ((dx_expected * fee) / CURVE_FEE_SCALE);

        // tokens (DAI, USDC or USDT) to transfer to receiver scaled to 18 decimals
        uint256 tokenAmountScaled = newBalancesScaled[_coinIndex] -
            _getY(newBalancesScaled, Ann, _coinIndex, invariantAfterRedeem) -
            1; // Withdraw less to account for rounding errors

        // If DAI then already 18 decimals, else its USDC or USDT so need to scale down to only 6 decimals
        tokenAmount_ = _coinIndex == 0 ? tokenAmountScaled : tokenAmountScaled / 1e12;
    }

    /**
     * Get 3Pool's virtual price which is in USD. This is 3Pool's USD value (invariant)
     * divided by the number of LP tokens scaled to `VIRTUAL_PRICE_SCALE` which is 1e18.
     * @return virtualPrice_ 3Pool's virtual price in USD scaled to 18 decimal places.
     */
    function getVirtualPrice() external view returns (uint256 virtualPrice_) {
        // Calculate the USD value of the 3Pool which is the invariant
        uint256 invariant = _getD(
            [
                ICurve3Pool(THREE_POOL).balances(0),
                ICurve3Pool(THREE_POOL).balances(1) * 1e12,
                ICurve3Pool(THREE_POOL).balances(2) * 1e12
            ],
            ICurve3Pool(THREE_POOL).A() * N_COINS
        );

        // This will fail if the pool is empty.
        // virtual price of one 3Crv in USD scaled to 18 decimal places (3Crv/USD) = 3Pool USD value * 1e18 / total 3Crv
        virtualPrice_ = (invariant * VIRTUAL_PRICE_SCALE) / IERC20(LP_TOKEN).totalSupply();
    }

    /**
     * @notice Uses Newton’s Method to iteratively solve the StableSwap invariant (D).
     * @param xp  The scaled balances of the coins in the 3Pool.
     * @param Ann The amplitude coefficient multiplied by the number of coins in the pool (A * N_COINS).
     * @return D  The StableSwap invariant
     */
    function _getD(uint256[N_COINS] memory xp, uint256 Ann) internal pure returns (uint256 D) {
        uint256 S = xp[0] + xp[1] + xp[2];

        // Do these multiplications here rather than in each loop
        uint256 xp0 = xp[0] * N_COINS;
        uint256 xp1 = xp[1] * N_COINS;
        uint256 xp2 = xp[2] * N_COINS;

        uint256 Dprev = 0;
        D = S;
        uint256 D_P;
        for (uint256 i = 0; i < 255; ) {
            // D_P: uint256 = D
            // for _x in xp:
            //     D_P = D_P * D / (_x * N_COINS)  # If division by 0, this will be borked: only withdrawal will work. And that is good
            D_P = (((((D * D) / xp0) * D) / xp1) * D) / xp2;

            Dprev = D;
            D = ((Ann * S + D_P * N_COINS) * D) / ((Ann - 1) * D + (N_COINS + 1) * D_P);
            // Equality with the precision of 1
            if (D > Dprev) {
                if (D - Dprev <= 1) break;
            } else {
                if (Dprev - D <= 1) break;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Calculate x[i] if one reduces D from being calculated for xp to D
     *
       Done by solving quadratic equation iteratively using the Newton's method.
        x_1**2 + x1 * (sum' - (A*n**n - 1) * D / (A * n**n)) = D ** (n + 1) / (n ** (2 * n) * prod' * A)
        x_1**2 + b*x_1 = c

        x_1 = (x_1**2 + c) / (2*x_1 + b)
     */
    function _getY(
        uint256[N_COINS] memory xp,
        uint256 Ann,
        uint256 coinIndex,
        uint256 D
    ) internal pure returns (uint256 y) {
        uint256 c = D;
        uint256 S_ = 0;
        if (coinIndex != 0) {
            S_ += xp[0];
            c = (c * D) / (xp[0] * N_COINS);
        }
        if (coinIndex != 1) {
            S_ += xp[1];
            c = (c * D) / (xp[1] * N_COINS);
        }
        if (coinIndex != 2) {
            S_ += xp[2];
            c = (c * D) / (xp[2] * N_COINS);
        }

        c = (c * D) / (Ann * N_COINS);
        uint256 b = S_ + D / Ann;
        uint256 yPrev = 0;
        y = D;
        uint256 i = 0;
        for (; i < 255; ) {
            yPrev = y;
            y = (y * y + c) / (2 * y + b - D);

            // Equality with the precision of 1
            if (y > yPrev) {
                if (y - yPrev <= 1) break;
            } else {
                if (yPrev - y <= 1) break;
            }

            unchecked {
                ++i;
            }
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