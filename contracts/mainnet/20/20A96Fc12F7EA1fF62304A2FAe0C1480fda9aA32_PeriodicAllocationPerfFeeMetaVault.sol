// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

//Libs
import { PeriodicAllocationAbstractVault } from "../allocate/PeriodicAllocationAbstractVault.sol";
import { PerfFeeAbstractVault } from "../fee/PerfFeeAbstractVault.sol";
import { FeeAdminAbstractVault } from "../fee/FeeAdminAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";
import { InitializableToken } from "../../tokens/InitializableToken.sol";

/**
 * @notice  EIP-4626 vault that periodically invests 3CRV in the underlying vaults and charge performance fees
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-27
 */
contract PeriodicAllocationPerfFeeMetaVault is
    PeriodicAllocationAbstractVault,
    PerfFeeAbstractVault,
    Initializable
{
    /// @param _nexus Address of the Nexus contract that resolves protocol modules and roles.
    /// @param _asset Address of the vault's underlying asset which is one of DAI/USDC/USDT
    constructor(address _nexus, address _asset) AbstractVault(_asset) VaultManagerRole(_nexus) {}

    /// @notice have to override this function
    /// @dev dummy function
    function _initialize(address dummy)
        internal
        virtual
        override(FeeAdminAbstractVault, VaultManagerRole)
    {}

    /**
     * @param _name  Name of Vault token
     * @param _symbol Symbol of vault token
     * @param _vaultManager Trusted account that can perform vault operations. eg rebalance.
     * @param _performanceFee  Performance fee to be charged
     * @param _feeReceiver  Account that receives fees in the form of vault shares.
     * @param _underlyingVaults  The underlying vaults address to invest into.
     * @param _sourceParams Params related to sourcing of assets
     * @param _assetPerShareUpdateThreshold threshold amount of transfers to/from for assetPerShareUpdate
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _vaultManager,
        uint256 _performanceFee,
        address _feeReceiver,
        address[] memory _underlyingVaults,
        AssetSourcingParams memory _sourceParams,
        uint256 _assetPerShareUpdateThreshold
    ) external initializer {
        // Set the vault's decimals to the same as the reference asset.
        uint8 decimals_ = InitializableToken(address(_asset)).decimals();
        InitializableToken._initialize(_name, _symbol, decimals_);

        // Initialize contracts
        VaultManagerRole._initialize(_vaultManager);
        PerfFeeAbstractVault._initialize(_performanceFee);
        PeriodicAllocationAbstractVault._initialize(
            _underlyingVaults,
            _sourceParams,
            _assetPerShareUpdateThreshold
        );
        FeeAdminAbstractVault._initialize(_feeReceiver);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/MINT
    //////////////////////////////////////////////////////////////*/

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._deposit(assets, receiver);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._previewDeposit(assets);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._mint(shares, receiver);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewMint(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._previewMint(shares);
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._withdraw(assets, receiver, owner);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._previewWithdraw(assets);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        internal
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._redeem(shares, receiver, owner);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._previewRedeem(shares);
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 assets)
    {
        return PeriodicAllocationAbstractVault._convertToAssets(shares);
    }

    /// @dev use PeriodicAllocationAbstractVault implementation.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, PeriodicAllocationAbstractVault)
        returns (uint256 shares)
    {
        return PeriodicAllocationAbstractVault._convertToShares(assets);
    }

    /***************************************
                Vault Hooks
    ****************************************/

    function _afterDepositHook(
        uint256 assets,
        uint256,
        address,
        bool
    ) internal virtual override {
        // Assets are held in the vault after deposit and mint so this hook is not needed.
        // Assets are deposited using the `settle` function to the underlying
    }

    function _beforeWithdrawHook(
        uint256 assets,
        uint256,
        address,
        bool
    ) internal virtual override {
        // Assets are withdrawn from the underlying using the `sourceAssets` function if there are not enough assets in this vault.
    }

    /***************************************
                Internal Hooks
    ****************************************/

    /// @dev update assetPerShare after charging performance fees
    function _afterChargePerformanceFee() internal virtual override {
        _updateAssetPerShare();
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { SameAssetUnderlyingsAbstractVault } from "./SameAssetUnderlyingsAbstractVault.sol";
import { AssetPerShareAbstractVault } from "./AssetPerShareAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { IERC4626Vault } from "../../interfaces/IERC4626Vault.sol";

/**
 * @title   Abstract ERC-4626 vault that periodically invests in underlying ERC-4626 vaults of the same asset.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-27
 */
abstract contract PeriodicAllocationAbstractVault is
    SameAssetUnderlyingsAbstractVault,
    AssetPerShareAbstractVault
{
    // Structure to have settlement data
    struct Settlement {
        uint256 vaultIndex;
        uint256 assets;
    }

    struct AssetSourcingParams {
        /// @notice Shares threshold (basis points) below which assets are sourced from single vault.
        uint32 singleVaultSharesThreshold;
        /// @notice Index of underlying vault in `underlyingVaults` to source small withdrawls from.  Starts from index 0
        uint32 singleSourceVaultIndex;
    }

    /// @notice Basis points calculation scale. 100% = 10000, 1% = 100, 0.01% = 1
    uint256 public constant BASIS_SCALE = 1e4;

    /// @notice Params related to sourcing of assets.
    AssetSourcingParams public sourceParams;

    /// @notice Amount of assets that are transferred from/to the vault.
    uint256 public assetsTransferred;

    /// @notice Threshold amount of transfers to/from for `assetPerShareUpdate`.
    uint256 public assetPerShareUpdateThreshold;

    event SingleVaultSharesThresholdUpdated(uint256 singleVaultSharesThreshold);
    event SingleSourceVaultIndexUpdated(uint32 singleSourceVaultIndex);
    event AssetPerShareUpdateThresholdUpdated(uint256 assetPerShareUpdateThreshold);

    /**
     * @param _underlyingVaults  The underlying vaults address to invest into.
     * @param _sourceParams Params related to sourcing of assets.
     * @param _assetPerShareUpdateThreshold Threshold amount of transfers to/from for `assetPerShareUpdate`.
     */
    function _initialize(
        address[] memory _underlyingVaults,
        AssetSourcingParams memory _sourceParams,
        uint256 _assetPerShareUpdateThreshold
    ) internal virtual {
        require(
            _sourceParams.singleVaultSharesThreshold <= BASIS_SCALE,
            "Invalid shares threshold"
        );
        require(
            _sourceParams.singleSourceVaultIndex < _underlyingVaults.length,
            "Invalid source vault index"
        );

        SameAssetUnderlyingsAbstractVault._initialize(_underlyingVaults);
        AssetPerShareAbstractVault._initialize();

        sourceParams = _sourceParams;
        assetPerShareUpdateThreshold = _assetPerShareUpdateThreshold;
    }

    /**
     * @notice Invests the assets sitting in the vault from previous deposits and mints into the nominated underlying vaults.
     * @param settlements A list of asset amounts and underlying vault indices to deposit the assets sitting in the vault.
     * @dev Provide exact assets amount through settlement and this way remaining assets are left in vault.
     */
    function settle(Settlement[] calldata settlements) external virtual onlyVaultManager {
        Settlement memory settlement;

        for (uint256 i = 0; i < settlements.length; ) {
            settlement = settlements[i];

            if (settlement.assets > 0) {
                // Deposit assets in underlying vault
                resolveVaultIndex(settlement.vaultIndex).deposit(settlement.assets, address(this));
            }

            unchecked {
                ++i;
            }
        }

        // Update assetPerShare
        _updateAssetPerShare();
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_deposit` logic.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override
        returns (uint256 shares)
    {
        _checkAndUpdateAssetPerShare(assets);
        shares = _previewDeposit(assets);
        _transferAndMint(assets, shares, receiver, true);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 shares)
    {
        return AssetPerShareAbstractVault._previewDeposit(assets);
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_mint` logic.
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override
        returns (uint256 assets)
    {
        assets = _previewMint(shares);
        _checkAndUpdateAssetPerShare(assets);
        _transferAndMint(assets, shares, receiver, false);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewMint(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 assets)
    {
        return AssetPerShareAbstractVault._previewMint(shares);
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_withdraw` logic.
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual override returns (uint256 shares) {
        _checkAndUpdateAssetPerShare(assets);
        shares = _previewWithdraw(assets);

        uint256 availableAssets = _sourceAssets(assets, shares);
        require(availableAssets >= assets, "not enough assets");

        // Burn this vault's shares and transfer the assets to the receiver.
        _burnTransfer(assets, shares, receiver, owner, false);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 shares)
    {
        return AssetPerShareAbstractVault._previewWithdraw(assets);
    }

    /// @dev Calls `_checkAndUpdateAssetPerShare` before abstract `_redeem` logic.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual override returns (uint256 assets) {
        assets = _previewRedeem(shares);
        _checkAndUpdateAssetPerShare(assets);

        uint256 availableAssets = _sourceAssets(assets, shares);
        require(availableAssets >= assets, "not enough assets");

        _burnTransfer(assets, shares, receiver, owner, true);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, AssetPerShareAbstractVault)
        returns (uint256 assets)
    {
        return AssetPerShareAbstractVault._previewRedeem(shares);
    }

    /**
     * @notice Sources enough assets from underlying vaults for `redeem` or `withdraw`.
     * @param assets Amount of assets to source from underlying vaults.
     * @param shares Amount of this vault's shares to burn.
     * @return actualAssets Amount of assets sourced to this vault.
     * @dev Ensure there is enough assets in the vault to transfer
     * to the receiver for `withdraw` or `redeem`.
     */
    function _sourceAssets(uint256 assets, uint256 shares) internal returns (uint256 actualAssets) {
        // Get the amount of assets held in this vault.
        actualAssets = _asset.balanceOf(address(this));

        // If there is not enough assets held in this vault, the extra assets need to be sourced from the underlying vaults.
        if (assets > actualAssets) {
            // Bool to track whether sourcing from single vault is successs
            bool sourceFromSingleVaultComplete = false;

            // Calculate how many assets need to be withdrawn from the underlying
            uint256 requiredAssets = assets - actualAssets;

            // Fraction of this vault's shares to be burnt
            uint256 sharesRatio = (shares * BASIS_SCALE) / totalSupply();

            // Load the sourceParams from storage into memory
            AssetSourcingParams memory assetSourcingParams = sourceParams;

            /// Source assets from a single vault
            if (sharesRatio <= assetSourcingParams.singleVaultSharesThreshold) {
                IERC4626Vault underlyingVault = resolveVaultIndex(
                    assetSourcingParams.singleSourceVaultIndex
                );

                // Underlying vault has sufficient assets to cover the sourcing
                if (requiredAssets <= underlyingVault.maxWithdraw(address(this))) {
                    // Withdraw assets
                    underlyingVault.withdraw(requiredAssets, address(this), address(this));
                    sourceFromSingleVaultComplete = true;
                }
            }

            /// Withdraw from all if shareRedeemed are above threshold or sourcing fron single vault was not enough
            if (
                sharesRatio > assetSourcingParams.singleVaultSharesThreshold ||
                !sourceFromSingleVaultComplete
            ) {
                uint256 i;
                uint256 len = _activeUnderlyingVaults.length;
                uint256 totalUnderlyingAssets;

                uint256[] memory underlyingVaultAssets = new uint256[](len);

                // Compute max assets held by each underlying vault and total for the Meta Vault.
                for (i = 0; i < len; ) {
                    underlyingVaultAssets[i] = _activeUnderlyingVaults[i].maxWithdraw(
                        address(this)
                    );
                    // Increment total underlying assets
                    totalUnderlyingAssets += underlyingVaultAssets[i];

                    unchecked {
                        ++i;
                    }
                }

                if (totalUnderlyingAssets >= requiredAssets) {
                    // Amount of assets to be withdrawn from each underlying vault
                    uint256 underlyingAssetsToWithdraw;

                    // For each underlying vault
                    for (i = 0; i < len; ) {
                        if (underlyingVaultAssets[i] > 0) {
                            // source assets proportionally and round up
                            underlyingAssetsToWithdraw =
                                ((requiredAssets * underlyingVaultAssets[i]) /
                                    totalUnderlyingAssets) +
                                1;
                            // check round up is not more than max assets
                            underlyingAssetsToWithdraw = underlyingAssetsToWithdraw >
                                underlyingVaultAssets[i]
                                ? underlyingVaultAssets[i]
                                : underlyingAssetsToWithdraw;

                            // withdraw assets proportionally to this vault
                            _activeUnderlyingVaults[i].withdraw(
                                underlyingAssetsToWithdraw,
                                address(this),
                                address(this)
                            );
                        }
                        unchecked {
                            ++i;
                        }
                    }
                }
            }
            // Update vault actual assets
            actualAssets = _asset.balanceOf(address(this));
        }
    }

    /// @dev Checks whether assetPerShare needs to be updated and updates it.
    /// @param _assets Amount of assets requested for transfer to/from the vault.
    function _checkAndUpdateAssetPerShare(uint256 _assets) internal {
        // 0 threshold means update before each transfer
        if (assetPerShareUpdateThreshold == 0) {
            _updateAssetPerShare();
        } else {
            // if the transferred amount including this transfer is above threshold
            if (assetsTransferred + _assets >= assetPerShareUpdateThreshold) {
                _updateAssetPerShare();

                // reset assetsTransferred
                assetsTransferred = 0;
            } else {
                // increment assetsTransferred
                assetsTransferred += _assets;
            }
        }
    }

    /***************************************
                Vault Properties setters
    ****************************************/

    /// @notice `Governor` sets the threshold for large withdrawals that withdraw proportionally
    /// from all underlying vaults instead of just from a single configured vault.
    /// This means smaller `redeem` and `withdraw` txs pay a lot less gas.
    /// @param _singleVaultSharesThreshold Percentage of shares being redeemed in basis points. eg 20% = 2000, 5% = 500
    function setSingleVaultSharesThreshold(uint32 _singleVaultSharesThreshold)
        external
        onlyGovernor
    {
        require(_singleVaultSharesThreshold <= BASIS_SCALE, "Invalid shares threshold");
        sourceParams.singleVaultSharesThreshold = _singleVaultSharesThreshold;

        emit SingleVaultSharesThresholdUpdated(_singleVaultSharesThreshold);
    }

    /// @notice `Governor` sets the underlying vault that small withdrawals are redeemed from.
    /// @param _singleSourceVaultIndex the underlying vault's index position in `underlyingVaults`. This starts from index 0.
    function setSingleSourceVaultIndex(uint32 _singleSourceVaultIndex) external onlyGovernor {
        // Check the single source vault is active.
        resolveVaultIndex(_singleSourceVaultIndex);
        sourceParams.singleSourceVaultIndex = _singleSourceVaultIndex;

        emit SingleSourceVaultIndexUpdated(_singleSourceVaultIndex);
    }

    /// @notice Governor sets the threshold asset amount of cumulative transfers to/from the vault before the assets per share is updated.
    /// @param _assetPerShareUpdateThreshold cumulative asset transfers amount.
    function setAssetPerShareUpdateThreshold(uint256 _assetPerShareUpdateThreshold)
        external
        onlyGovernor
    {
        assetPerShareUpdateThreshold = _assetPerShareUpdateThreshold;

        emit AssetPerShareUpdateThresholdUpdated(_assetPerShareUpdateThreshold);
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override(AssetPerShareAbstractVault, AbstractVault)
        returns (uint256 assets)
    {
        return AssetPerShareAbstractVault._convertToAssets(shares);
    }

    /// @dev Uses AssetPerShareAbstractVault logic.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override(AssetPerShareAbstractVault, AbstractVault)
        returns (uint256 shares)
    {
        return AssetPerShareAbstractVault._convertToShares(assets);
    }

    /***************************************
                Internal Hooks
    ****************************************/

    /// @dev Updates assetPerShare after rebalance
    function _afterRebalance() internal virtual override {
        _updateAssetPerShare();
    }

    /// @dev Updates assetPerShare after an underlying vault is removed
    function _afterRemoveVault() internal virtual override {
        _updateAssetPerShare();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IERC4626Vault } from "../interfaces/IERC4626Vault.sol";
import { VaultManagerRole } from "../shared/VaultManagerRole.sol";
import { InitializableToken } from "../tokens/InitializableToken.sol";

/**
 * @title   Abstract ERC-4626 Vault.
 * @author  mStable
 * @notice  See the following for the full EIP-4626 specification https://eips.ethereum.org/EIPS/eip-4626.
 * Connects to the mStable Nexus to get modules and roles like the `Governor` and `Liquidator`.
 * Creates the `VaultManager` role.
 *
 * The `totalAssets`, `_beforeWithdrawHook` and `_afterDepositHook` functions need to be implemented.
 *
 * @dev     VERSION: 1.0
 *          DATE:    2022-02-10
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - AbstractVault(_assetArg)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 */
abstract contract AbstractVault is IERC4626Vault, InitializableToken, VaultManagerRole {
    using SafeERC20 for IERC20;

    /// @notice Address of the vault's underlying asset token.
    IERC20 internal immutable _asset;

    /**
     * @param _assetArg         Address of the vault's underlying asset.
     */
    constructor(address _assetArg) {
        require(_assetArg != address(0), "Asset is zero");
        _asset = IERC20(_assetArg);
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/MINT
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    function _deposit(uint256 assets, address receiver) internal virtual returns (uint256 shares) {
        shares = _previewDeposit(assets);

        _transferAndMint(assets, shares, receiver, true);
    }

    function previewDeposit(uint256 assets) external view override returns (uint256 shares) {
        shares = _previewDeposit(assets);
    }

    function _previewDeposit(uint256 assets) internal view virtual returns (uint256 shares) {
        shares = _convertToShares(assets);
    }

    function maxDeposit(address caller) external view override returns (uint256 maxAssets) {
        maxAssets = _maxDeposit(caller);
    }

    function _maxDeposit(address) internal view virtual returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = type(uint256).max;
    }

    function mint(uint256 shares, address receiver)
        external
        virtual
        override
        whenNotPaused
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    function _mint(uint256 shares, address receiver) internal virtual returns (uint256 assets) {
        assets = _previewMint(shares);
        _transferAndMint(assets, shares, receiver, false);
    }

    function previewMint(uint256 shares) external view override returns (uint256 assets) {
        assets = _previewMint(shares);
    }

    function _previewMint(uint256 shares) internal view virtual returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    function maxMint(address owner) external view override returns (uint256 maxShares) {
        maxShares = _maxMint(owner);
    }

    function _maxMint(address) internal view virtual returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }

        maxShares = type(uint256).max;
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL DEPSOIT/MINT
    //////////////////////////////////////////////////////////////*/

    function _transferAndMint(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        _afterDepositHook(assets, shares, receiver, fromDeposit);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 shares) {
        shares = _withdraw(assets, receiver, owner);
    }

    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual returns (uint256 shares) {
        shares = _previewWithdraw(assets);

        _burnTransfer(assets, shares, receiver, owner, false);
    }

    function previewWithdraw(uint256 assets) external view override returns (uint256 shares) {
        shares = _previewWithdraw(assets);
    }

    function _previewWithdraw(uint256 assets) internal view virtual returns (uint256 shares) {
        shares = _convertToShares(assets);
    }

    function maxWithdraw(address owner) external view override returns (uint256 maxAssets) {
        maxAssets = _maxWithdraw(owner);
    }

    function _maxWithdraw(address owner) internal view virtual returns (uint256 maxAssets) {
        if (paused()) {
            return 0;
        }

        maxAssets = _previewRedeem(balanceOf(owner));
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override whenNotPaused returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner);
    }

    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual returns (uint256 assets) {
        assets = _previewRedeem(shares);
        _burnTransfer(assets, shares, receiver, owner, true);
    }

    function previewRedeem(uint256 shares) external view override returns (uint256 assets) {
        assets = _previewRedeem(shares);
    }

    function _previewRedeem(uint256 shares) internal view virtual returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    function maxRedeem(address owner) external view override returns (uint256 maxShares) {
        maxShares = _maxRedeem(owner);
    }

    function _maxRedeem(address owner) internal view virtual returns (uint256 maxShares) {
        if (paused()) {
            return 0;
        }
        
        maxShares = balanceOf(owner);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    function _burnTransfer(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner,
        bool fromRedeem
    ) internal virtual {
        // If caller is not the owner of the shares
        uint256 allowed = allowance(owner, msg.sender);
        if (msg.sender != owner && allowed != type(uint256).max) {
            require(shares <= allowed, "Amount exceeds allowance");
            _approve(owner, msg.sender, allowed - shares);
        }
        _beforeWithdrawHook(assets, shares, owner, fromRedeem);

        _burn(owner, shares);

        _asset.safeTransfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*///////////////////////////////////////////////////////////////
                            EXTENRAL ASSETS
    //////////////////////////////////////////////////////////////*/

    function asset() external view virtual override returns (address assetTokenAddress) {
        assetTokenAddress = address(_asset);
    }

    /**
     * @notice It should include any compounding that occurs from yield. It must be inclusive of any fees that are charged against assets in the Vault. It must not revert.
     *
     * Returns the total amount of the underlying asset that is “managed” by vault.
     */
    function totalAssets() public view virtual override returns (uint256 totalManagedAssets);

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    function convertToAssets(uint256 shares)
        external
        view
        virtual
        override
        returns (uint256 assets)
    {
        assets = _convertToAssets(shares);
    }

    function _convertToAssets(uint256 shares) internal view virtual returns (uint256 assets) {
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            assets = shares; // 1:1 value of shares and assets
        } else {
            assets = (shares * totalAssets()) / totalShares;
        }
    }

    function convertToShares(uint256 assets)
        external
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares = _convertToShares(assets);
    }

    function _convertToShares(uint256 assets) internal view virtual returns (uint256 shares) {
        uint256 totalShares = totalSupply();

        if (totalShares == 0) {
            shares = assets; // 1:1 value of shares and assets
        } else {
            shares = (assets * totalShares) / totalAssets();
        }
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * Called be the `deposit` and `mint` functions after the assets have been transferred into the vault
     * but before shares are minted.
     * Typically, the hook implementation deposits the assets into the underlying vaults or platforms.
     *
     * @dev the shares returned from `totalSupply` and `balanceOf` have not yet been updated with the minted shares.
     * The assets returned from `totalAssets` and `assetsOf` are typically updated as part of the `_afterDepositHook` hook but it depends on the implementation.
     *
     * If an vault is implementing multiple vault capabilities, the `_afterDepositHook` function that updates the assets amounts should be executed last.
     *
     * @param assets the amount of underlying assets to be transferred to the vault.
     * @param shares the amount of vault shares to be minted.
     * @param receiver the account that is receiving the minted shares.
     */
    function _afterDepositHook(
        uint256 assets,
        uint256 shares,
        address receiver,
        bool fromDeposit
    ) internal virtual {}

    /**
     * Called be the `withdraw` and `redeem` functions before
     * the assets have been transferred from the vault to the receiver
     * and before the owner's shares are burnt.
     * Typically, the hook implementation withdraws the assets from the underlying vaults or platforms.
     *
     * @param assets the amount of underlying assets to be withdrawn from the vault.
     * @param shares the amount of vault shares to be burnt.
     * @param owner the account that owns the shares that are being burnt.
     */
    function _beforeWithdrawHook(
        uint256 assets,
        uint256 shares,
        address owner,
        bool fromRedeem
    ) internal virtual {}
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { FeeAdminAbstractVault } from "./FeeAdminAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";

/**
 * @notice   Abstract ERC-4626 vault that calculates a performance fee since the last time the performance fee was charged.
 * @author  mStable
 * @dev     VERSION: 1.1
 *          Created: 2022-05-27
 *          Updated: 2022-11-11
 *
 * The following functions have to be implemented
 * - chargePerformanceFee()
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - FeeAdminAbstractVault._initialize(_feeReceiver)
 * - PerfFeeAbstractVault._initialize(_performanceFee)
 */
abstract contract PerfFeeAbstractVault is FeeAdminAbstractVault {
    /// @notice Scale of the performance fee. 100% = 1000000, 1% = 10000, 0.01% = 100
    uint256 public constant FEE_SCALE = 1e6;
    /// @notice Scale of the assets per share used to calculate performance fees. 1e26 = 26 decimal places.
    uint256 public constant PERF_ASSETS_PER_SHARE_SCALE = 1e26;

    /// @notice Performance fee scaled to 6 decimal places. 1% = 10000, 0.01% = 100
    uint256 public performanceFee;

    /// @notice Assets per shares used to calculate performance fees scaled to 26 decimal places.
    uint256 public perfFeesAssetPerShare;

    event PerformanceFee(address indexed feeReceiver, uint256 feeShares, uint256 assetsPerShare);
    event PerformanceFeeUpdated(uint256 performanceFee);

    /// @param _performanceFee Performance fee scaled to 6 decimal places.
    function _initialize(uint256 _performanceFee) internal virtual {
        performanceFee = _performanceFee;
        perfFeesAssetPerShare = PERF_ASSETS_PER_SHARE_SCALE;
    }

    /**
     * @dev charges a performance fee since the last time a fee was charged.
     */
    function _chargePerformanceFee() internal {
        //Calculate current assets per share.
        uint256 totalShares = totalSupply();
        uint256 totalAssets = totalAssets();
        uint256 currentAssetsPerShare = totalShares > 0
            ? (totalAssets * PERF_ASSETS_PER_SHARE_SCALE) / totalShares
            : perfFeesAssetPerShare;

        // Only charge a performance fee if assets per share has increased.
        if (currentAssetsPerShare > perfFeesAssetPerShare) {
            // Calculate the amount of shares to mint as a fee.
            // performance fee *
            // total shares *
            // percentrage increase in assets per share
            uint256 feeShares = (performanceFee *
                totalShares *
                (currentAssetsPerShare - perfFeesAssetPerShare)) /
                (perfFeesAssetPerShare * FEE_SCALE);

            // Small gains with a small vault decimals can cause the feeShares to be zero
            // even though there was an increase in the assets per share.
            if (feeShares > 0) {
                _mint(feeReceiver, feeShares);

                // Calculate the new assets per share after fee shares have been minted.
                // The assets per share has reduced as there are now more shares.
                currentAssetsPerShare =  (totalAssets * PERF_ASSETS_PER_SHARE_SCALE) / (totalShares + feeShares);

                emit PerformanceFee(feeReceiver, feeShares, currentAssetsPerShare);
            }
        }

        // Store current assets per share which could be less than the old assets per share.
        perfFeesAssetPerShare = currentAssetsPerShare;

        // Hook for implementing contracts to do something after performance fees have been collected.
        // For example, claim assets from liquidated rewards which will lift the assets per share.
        // New shares will be issued at the now higher assets per share.

        _afterChargePerformanceFee();
    }

    /**
     * @notice Vault Manager charges a performance fee since the last time a fee was charged.
     * As an example, if the assets per share increased by 0.1% in the last week and the performance fee is 4%, the vault shares will be
     * increased by 0.1% * 4% = 0.004% as a fee. If there was 100,000 vault shares, 4 (100,000 * 0.004%) vault shares will be minted as a
     * performance fee. This dilutes the assets per shares of the existing vault shareholders by 0.004%.
     * No performance fee is charged if the assets per share drops.
     * @dev Called from a trusted account so gains and loses can not be gamed.
     */
    function chargePerformanceFee() external virtual onlyVaultManager {
        _chargePerformanceFee();
    }

    /***************************************
            Performance Fee Admin
    ****************************************/

    /**
     * @notice Sets a new performance fee after charging to now using the old performance fee.
     * @param _performanceFee Performance fee scaled to 6 decimal places. 1% = 10000, 0.01% = 100
     */
    function setPerformanceFee(uint256 _performanceFee) external onlyGovernor {
        require(_performanceFee <= FEE_SCALE, "Invalid fee");

        // Charges a performance fee using the old value.
        _chargePerformanceFee();

        // Store the new performance fee.
        performanceFee = _performanceFee;

        emit PerformanceFeeUpdated(_performanceFee);
    }

    /***************************************
            Invest/Divest Assets Hooks
    ****************************************/

    /**
     * @dev Optional hook to do something after performance fees have been collected.
     * For example, claim assets from liquidated rewards which will lift the assets per share.
     * New shares will be issued at the now higher assets per share, but redemptions will use
     * the lower assets per share stored when the performance fee was charged.
     */
    function _afterChargePerformanceFee() internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Libs
import { AbstractVault } from "../AbstractVault.sol";

/**
 * @title   Abstract ERC-4626 vault that collects fees.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-27
 *
 * The following functions have to be implemented
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - FeeAdminAbstractVault._initialize(_feeReceiver)
 */
abstract contract FeeAdminAbstractVault is AbstractVault {
    /// @notice Account that receives the performance fee as shares.
    address public feeReceiver;

    event FeeReceiverUpdated(address indexed feeReceiver);

    /**
     * @param _feeReceiver Account that receives the performance fee as shares.
     */
    function _initialize(address _feeReceiver) internal virtual override {
        feeReceiver = _feeReceiver;
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /**
     * @notice Called by the protocol Governor to set the fee receiver address.
     * @param _feeReceiver Address that will receive the fees.
     */
    function setFeeReceiver(address _feeReceiver) external onlyGovernor {
        feeReceiver = _feeReceiver;

        emit FeeReceiverUpdated(feeReceiver);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { SingleSlotMapper } from "../../shared/SingleSlotMapper.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { IERC4626Vault } from "../../interfaces/IERC4626Vault.sol";

/**
 * @title   Abstract ERC-4626 vault that invests in underlying ERC-4626 vaults of the same asset.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-03-28
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - LightAbstractVault(_assetArg)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 * - SameAssetUnderlyingsAbstractVault._initialize(_underlyingVaults)
 */
abstract contract SameAssetUnderlyingsAbstractVault is AbstractVault {
    using SafeERC20 for IERC20;
    using SingleSlotMapper for uint256;

    struct Swap {
        uint256 fromVaultIndex;
        uint256 toVaultIndex;
        uint256 shares;
        uint256 assets;
    }

    /// @dev List of active underlying vaults this vault invests into.
    IERC4626Vault[] internal _activeUnderlyingVaults;
    /// @dev bit map of external vault indexes to active underlying vault indexes.
    /// This bit map only uses one slot read.
    ///
    /// The first byte from the left is the total number of vaults that have been used.
    /// If a new vault is added, the total number of vaults will be it's vault index.
    ///
    /// There are 62, 4 bit numbers going from right to left that hold the index to the internal
    /// active underlying vaults. This is 62 * 4 = 248 bits.
    /// 248 bits plus the 1 byte (8 bits) for the number of vaults gives 256 bits in the slot.
    /// By default, all external vault indexes are mapped to 0xF (15) which is an invalid index.
    /// When a vault is removed, it's mapped active underlying vault index is set back to 0xF.
    /// This means there is a maximum of 15 active underlying vaults.
    /// There is also a limit of 62 vaults that can be used over the life of this vault.
    uint256 internal vaultIndexMap;

    event AddedVault(uint256 indexed vaultIndex, address indexed vault);
    event RemovedVault(uint256 indexed vaultIndex, address indexed vault);

    /**
     * @param _underlyingVaults  The underlying vaults address to invest into.
     */
    function _initialize(address[] memory _underlyingVaults) internal virtual {
        uint256 vaultsLen = _underlyingVaults.length;
        require(vaultsLen > 0, "No underlying vaults");

        // Initialised all 62 vault indexes to 0xF which is an invalid underlying vault index.
        // The last byte (8 bits) from the left is reserved for the number of vault indexes that have been issued
        /// which is initialized to 0 hence there is 62 and not 64 Fs.
        uint256 vaultIndexMapMem = SingleSlotMapper.initialize();

        // For each underlying vault
        for (uint256 i = 0; i < vaultsLen; ) {
            vaultIndexMapMem = _addVault(_underlyingVaults[i], vaultIndexMapMem);
            unchecked {
                ++i;
            }
        }
        // Store the vaultIndexMap in storage
        vaultIndexMap = vaultIndexMapMem;
    }

    /**
     * @notice Includes all the assets in this vault plus all the underlying vaults.
     * The amount of assets in each underlying vault is calculated using the vault's share of the
     * underlying vault's total assets. `totalAssets()` does not account for fees or slippage so
     * the actual asset value is likely to be less.
     *
     * @return  totalManagedAssets The total assets managed by this vault.
     */
    function totalAssets() public view virtual override returns (uint256 totalManagedAssets) {
        totalManagedAssets = _asset.balanceOf(address(this)) + _totalUnderlyingAssets();
    }

    /**
     * @notice Includes the assets in all underlying vaults. It does not include the assets in this vault.
     * @return  totalUnderlyingAssets The total assets held in underlying vaults
     */
    function _totalUnderlyingAssets() internal view returns (uint256 totalUnderlyingAssets) {
        // Get the assets held by this vault in each of in the active underlying vaults
        uint256 len = _activeUnderlyingVaults.length;

        for (uint256 i = 0; i < len; ) {
            totalUnderlyingAssets += _activeUnderlyingVaults[i].maxWithdraw(address(this));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns the active number of underlying vaults.
     * This excludes any vaults that have been removed.
     *
     * @return  activeVaults The number of active underlying vaults.
     */
    function activeUnderlyingVaults() external view virtual returns (uint256 activeVaults) {
        activeVaults = _activeUnderlyingVaults.length;
    }

    /**
     * @notice Returns the total number of underlying vaults, both active and inactive.
     * The next vault added will have a vault index of this value.
     *
     * @return  totalVaults The number of active and inactive underlying vaults.
     */
    function totalUnderlyingVaults() external view virtual returns (uint256 totalVaults) {
        totalVaults = vaultIndexMap.indexes();
    }

    /**
     * @notice Resolves a vault index to an active underlying vault address.
     * This only works for active vaults.
     * A `Inactive vault` error will be thrown if the vault index has not been used
     * or the underlying vault is now inactive.s
     *
     * @param   vaultIndex External vault index used to identify the underlying vault.
     * @return  vault Address of the underlying vault.
     */
    function resolveVaultIndex(uint256 vaultIndex)
        public
        view
        virtual
        returns (IERC4626Vault vault)
    {
        // resolve the external vault index to the internal underlying vaults
        uint256 activeUnderlyingVaultsIndex = vaultIndexMap.map(vaultIndex);
        require(activeUnderlyingVaultsIndex < 0xF, "Inactive vault");
        vault = _activeUnderlyingVaults[activeUnderlyingVaultsIndex];
    }

    /**
     * @notice `VaultManager` rebalances the assets in the underlying vaults.
     * This can be moving assets between underlying vaults, moving assets in underlying
     * vaults back to this vault, or moving assets in this vault to underlying vaults.
     */
    function rebalance(Swap[] calldata swaps) external virtual onlyVaultManager {
        // For each swap
        Swap memory swap;
        uint256 vaultIndexMapMem = vaultIndexMap;
        uint256 fromVaultIndex;
        uint256 toVaultIndex;
        for (uint256 i = 0; i < swaps.length; ) {
            swap = swaps[i];

            // Map the external vault index to the internal active underlying vaults.
            fromVaultIndex = vaultIndexMapMem.map(swap.fromVaultIndex);
            require(fromVaultIndex < 0xF, "Inactive from vault");
            toVaultIndex = vaultIndexMapMem.map(swap.toVaultIndex);
            require(toVaultIndex < 0xF, "Inactive to vault");

            if (swap.assets > 0) {
                // Withdraw assets from underlying vault
                _activeUnderlyingVaults[fromVaultIndex].withdraw(
                    swap.assets,
                    address(this),
                    address(this)
                );

                // Deposits withdrawn assets in underlying vault
                _activeUnderlyingVaults[toVaultIndex].deposit(swap.assets, address(this));
            }
            if (swap.shares > 0) {
                // Redeem shares from underlying vault
                uint256 redeemedAssets = _activeUnderlyingVaults[fromVaultIndex].redeem(
                    swap.shares,
                    address(this),
                    address(this)
                );

                // Deposits withdrawn assets in underlying vault
                _activeUnderlyingVaults[toVaultIndex].deposit(redeemedAssets, address(this));
            }

            unchecked {
                ++i;
            }
        }

        // Call _afterRebalance hook
        _afterRebalance();
    }

    /***************************************
                Vault Management
    ****************************************/

    /**
     * @notice  Adds a new underlying ERC-4626 compliant vault.
     * This Meta Vault approves the new underlying vault to transfer max assets.
     * There is a limit of 15 active underlying vaults. If more vaults are needed,
     * another active vaults will need to be removed first.
     * There is also a limit of 62 underlying vaults that can be used by this Meta Vault
     * over its lifetime. That's both active and inactive vaults.
     *
     * @param _underlyingVault Address of a ERC-4626 compliant vault.
     */
    function addVault(address _underlyingVault) external onlyGovernor {
        vaultIndexMap = _addVault(_underlyingVault, vaultIndexMap);
    }

    /**
     * @param _underlyingVault Address of the new underlying vault.
     * @param _vaultIndexMap   The map of external to internal vault indexes.
     * @return vaultIndexMap_  The updated map of vault indexes.
     */
    function _addVault(address _underlyingVault, uint256 _vaultIndexMap)
        internal
        virtual
        returns (uint256 vaultIndexMap_)
    {
        require(IERC4626Vault(_underlyingVault).asset() == address(_asset), "Invalid vault asset");

        // Store new underlying vault in the contract.
        _activeUnderlyingVaults.push(IERC4626Vault(_underlyingVault));

        // Map the external vault index to the index of the internal active underlying vaults.
        uint256 vaultIndex;
        (vaultIndexMap_, vaultIndex) = _vaultIndexMap.addValue(_activeUnderlyingVaults.length - 1);

        // Approve the underlying vaults to transfer assets from this Meta Vault.
        _asset.safeApprove(_underlyingVault, type(uint256).max);

        emit AddedVault(vaultIndex, _underlyingVault);
    }

    /**
     * @notice  Removes an underlying ERC-4626 compliant vault.
     * All underlying shares are redeemed with the assets transferred to this vault.
     *
     * @param vaultIndex Index of the underlying vault starting from 0.
     */
    function removeVault(uint256 vaultIndex) external onlyGovernor {
        uint256 newUnderlyingVaultsLen = _activeUnderlyingVaults.length - 1;
        require(vaultIndex <= newUnderlyingVaultsLen, "Invalid from vault index");

        // Resolve the external vault index to the index in the internal active underlying vaults.
        uint256 vaultIndexMapMem = vaultIndexMap;
        uint256 underlyingVaultIndex = vaultIndexMapMem.map(vaultIndex);
        require(underlyingVaultIndex < 0xF, "Inactive vault");

        // Withdraw all assets from the underlying vault being removed.
        uint256 underlyingShares = _activeUnderlyingVaults[underlyingVaultIndex].maxRedeem(
            address(this)
        );
        if (underlyingShares > 0) {
            _activeUnderlyingVaults[vaultIndex].redeem(
                underlyingShares,
                address(this),
                address(this)
            );
        }

        address underlyingVault = address(_activeUnderlyingVaults[underlyingVaultIndex]);

        // move all vaults to the left after the vault being removed
        for (uint256 i = underlyingVaultIndex; i < newUnderlyingVaultsLen; ) {
            _activeUnderlyingVaults[i] = _activeUnderlyingVaults[i + 1];
            unchecked {
                ++i;
            }
        }
        _activeUnderlyingVaults.pop(); // delete the last underlying vault

        // Remove the underlying vault from the vault index map.
        vaultIndexMap = vaultIndexMapMem.removeValue(underlyingVaultIndex);

        // Call _afterRemoveVault
        _afterRemoveVault();

        emit RemovedVault(vaultIndex, underlyingVault);
    }

    /***************************************
                Internal Hooks
    ****************************************/

    /**
     * @dev Optional hook to do something after rebalance.
     * For example, assetsPerShare update after rebalance by PeriodicAllocationAbstractVault
     */
    function _afterRebalance() internal virtual {}

    /**
     * @dev Optional hook to do something after an underlying vault is removed.
     * For example, assetsPerShare update after removal by PeriodicAllocationAbstractVault
     */
    function _afterRemoveVault() internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { AbstractVault } from "../AbstractVault.sol";

/**
 * @title   Abstract ERC-4626 vault that maintains an `assetPerShare` ratio for vault operations (deposit, mint, withdraw and redeem).
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-02-10
 *
 * The following functions have to be implemented
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - AssetPerShareAbstractVault._initialize()
 */
abstract contract AssetPerShareAbstractVault is AbstractVault {
    /// @notice Scale of the assets per share. 1e26 = 26 decimal places
    uint256 public constant ASSETS_PER_SHARE_SCALE = 1e26;

    /// @notice Assets per share scaled to 26 decimal places.
    uint256 public assetsPerShare;

    event AssetsPerShareUpdated(uint256 assetsPerShare, uint256 totalAssets);

    /// @dev initialize the starting assets per share.
    function _initialize() internal virtual {
        assetsPerShare = ASSETS_PER_SHARE_SCALE;

        emit AssetsPerShareUpdated(ASSETS_PER_SHARE_SCALE, 0);
    }

    /**
     * @dev Calculate the amount of shares to mint to the receiver.
     * Use the assets per share value from the last settlement
     */
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares = _convertToShares(assets);
    }

    /**
     * @dev Calculate the amount of assets to transfer from the caller.
     * Use the assets per share value from the last settlement
     */
    function _previewMint(uint256 shares) internal view virtual override returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    /**
     * @dev Calculate the amount of shares to burn from the owner.
     * Use the assets per share value from the last settlement
     */
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares = _convertToShares(assets);
    }

    /**
     * @dev Calculate the amount of assets to transfer to the receiver.
     * Use the assets per share value from the last settlement
     */
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        assets = _convertToAssets(shares);
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev uses the stored `assetsPerShare` to convert shares to assets.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        assets = (shares * assetsPerShare) / ASSETS_PER_SHARE_SCALE;
    }

    /// @dev uses the stored `assetsPerShare` to convert assets to shares.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        shares = (assets * ASSETS_PER_SHARE_SCALE) / assetsPerShare;
    }

    /// @dev Updates assetPerShare of this vault to be expanted by the child contract to charge perf fees every assetPerShare update.
    function _updateAssetPerShare() internal virtual {
        uint256 totalAssets;
        (assetsPerShare, totalAssets) = calculateAssetPerShare();

        emit AssetsPerShareUpdated(assetsPerShare, totalAssets);
    }

    /// @notice VaultManager can update the `assetPerShare`.
    /// @dev to be called by watcher
    function updateAssetPerShare() external onlyVaultManager {
        _updateAssetPerShare();
    }

    /// @notice calculates current assetsPerShare
    /// @return assetsPerShare_ current assetsPerShare
    /// @return totalAssets_ totalAssets of the vault
    function calculateAssetPerShare()
        public
        view
        returns (uint256 assetsPerShare_, uint256 totalAssets_)
    {
        uint256 totalShares = totalSupply();
        
        // Calculate current assets per share
        totalAssets_ = totalAssets();
        assetsPerShare_ = totalShares > 0
            ? (totalAssets_ * ASSETS_PER_SHARE_SCALE) / totalShares
            : assetsPerShare;
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
     * @dev Returns Governor address from the Nexus
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return nexus.governor();
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
     * @dev Return Liquidator V2 module address from the Nexus
     * @return  Address of the Liquidator V2 contract
     */
    function _liquidatorV2() internal view returns (address) {
        return nexus.getModule(KEY_LIQUIDATOR_V2);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title   A gas efficient library for mapping unique identifiers to indexes in an active array.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-09-16
 */
library SingleSlotMapper {
    /**
     * @dev Initialised all 62 vault indexes to 0xF which is an invalid value.
     * The last byte (8 bits) from the left is reserved for the number of indexes that have been issued
     * which is initialized to 0 hence there is 62 and not 64 Fs.
     */
    function initialize() internal pure returns (uint256 mapData_) {
        mapData_ = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    }

    /**
     * @dev            Resolves the value of an index.
     * @param mapData  32 bytes (256 bits) of mapper data.
     * The left most byte contains the number of indexes mapped.
     * There are 62 4 bit values (248 bits) from right to left.
     * @param index    Value identifier between 0 and 61.
     * @return value   4 bit value where 0xF (15) is invalid.
     */
    function map(uint256 mapData, uint256 index) internal pure returns (uint256 value) {
        require(index < 62, "Index out of bounds");

        // Bit shift right by 4 bits (1/2 byte) for each index. eg
        // index 0 is not bit shifted
        // index 1 is shifted by 1 * 4 = 4 bits
        // index 3 is shifted by 3 * 4 = 12 bits
        // index 61 is shifted by 61 * 4 = 244 bits
        // A 0xF bit mask is used to cast the 4 bit number to a 256 number.
        // That is, the first 252 bits from the left are all set to 0.
        value = (mapData >> (index * 4)) & 0xF;
    }

    /**
     * @dev              Adds a mapping of a new index to a value.
     * @param  _mapData  32 bytes (256 bits) of map data.
     * @param  value     A 4 bit number between 0 and 14. 0xF (15) is invalid.
     * @return mapData_  Updated 32 bytes (256 bits) mapper data.
     * @return index     Index assigned to identify the added value.
     */
    function addValue(uint256 _mapData, uint256 value)
        internal
        pure
        returns (uint256 mapData_, uint256 index)
    {
        // value by be 14 or less as 0xF (15) is reserved for invalid.
        require(value < 0xF, "value out of bounds");

        // Right shift by 31 bytes * 8 bits (248 bits) to get the left most byte
        index = _mapData >> 248;
        require(index < 62, "map full");

        // Add the new number of indexed values to the left most byte.
        mapData_ = (index + 1) << 248;

        // Shift left and then right shift by 1 byte to clear the left most byte which has the previously set vault count.
        // OR with the previous map that has the number of vaults already set.
        mapData_ |= _mapData & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        // mapData_ |= (_mapData << 8) >> 8;

        // Clear the 4 bits of the mapped vault to all 0s.
        // Shift left by 4 bits for each index.
        // Negate (~) so we have a mask of all 1s except for the 4 bits we want to update next.
        // For example
        // index 0  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0
        // index 1  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0F
        // index 3  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0FFF
        // index 61 0xFF0FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        mapData_ &= ~(0xF << (4 * index));

        // Add the 4 bit value to the indexed location.
        mapData_ |= value << (4 * index);
    }

    /**
     * @dev Removes a value from the mapped indexes and decrements all higher values
     * by one. Typically, this is used when the values are positions in an array and
     * one of the array items has been removed.
     */
    function removeValue(uint256 _mapData, uint256 removedValue)
        internal
        pure
        returns (uint256 mapData_)
    {
        require(removedValue < 0xF, "value out of bounds");

        mapData_ = _mapData;
        uint256 indexCount = _mapData >> 248;
        bool found = false;

        // For each index
        for (uint256 i = 0; i < indexCount; ) {
            uint256 offset = i * 4;

            // Read the mapped value
            uint256 value = (_mapData >> offset) & 0xF;
            if (value == removedValue) {
                mapData_ |= 0xF << offset;
                found = true;
            } else if (value < 0xF && value > removedValue) {
                // Clear the mapped underlying vault index
                mapData_ &= ~(0xF << offset);
                // Set the mapped underlying vault index to one less than the previous value
                mapData_ |= (value - 1) << offset;
            }

            unchecked {
                ++i;
            }
        }
        require(found == true, "value not found");
    }

    /**
     * @dev The total number of values that have been indexed including any removed values.
     * @param  _mapData  32 bytes (256 bits) of map data.
     * @return total     Number of values that have been indexed.
     */
    function indexes(uint256 _mapData) internal pure returns (uint256 total) {
        // Bit shift 31 bytes (31 * 8 = 248 bits) to the right.
        total = _mapData >> 248;
    }
}