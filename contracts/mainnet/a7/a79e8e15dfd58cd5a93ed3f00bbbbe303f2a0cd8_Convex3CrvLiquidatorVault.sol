// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// External
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// libs
import { AbstractSlippage } from "../AbstractSlippage.sol";
import { AbstractVault, IERC20 } from "../../AbstractVault.sol";
import { Convex3CrvAbstractVault } from "./Convex3CrvAbstractVault.sol";
import { LiquidatorAbstractVault } from "../../liquidator/LiquidatorAbstractVault.sol";
import { LiquidatorStreamAbstractVault } from "../../liquidator/LiquidatorStreamAbstractVault.sol";
import { LiquidatorStreamFeeAbstractVault } from "../../liquidator/LiquidatorStreamFeeAbstractVault.sol";
import { VaultManagerRole } from "../../../shared/VaultManagerRole.sol";
import { InitializableToken } from "../../../tokens/InitializableToken.sol";
import { ICurve3Pool } from "../../../peripheral/Curve/ICurve3Pool.sol";
import { ICurveMetapool } from "../../../peripheral/Curve/ICurveMetapool.sol";
import { Curve3CrvMetapoolCalculatorLibrary } from "../../../peripheral/Curve/Curve3CrvMetapoolCalculatorLibrary.sol";

/**
 * @title   Convex Vault for #Pool (3Crv) based Curve Metapools that liquidates CRV and CVX rewards.
 * @notice  ERC-4626 vault that deposits Curve 3Pool LP tokens (3Crv) in a Curve Metapool, eg musd3Crv;
 * deposits the Metapool LP token in Convex; and stakes the Convex LP token, eg cvxmusd3Crv,
 * in Convex for CRV and CVX rewards. The Convex rewards are swapped for a Curve 3Pool token,
 * eg DAI, USDC or USDT, using the Liquidator module and donated back to the vault.
 * On donation back to the vault, the DAI, USDC or USDT is deposited into the underlying Curve Metapool;
 * the Curve Metapool LP token is deposited into the corresponding Convex pool and the Convex LP token staked.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-04-29
 */

contract Convex3CrvLiquidatorVault is
    Convex3CrvAbstractVault,
    LiquidatorStreamFeeAbstractVault,
    Initializable
{
    using SafeERC20 for IERC20;

    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// @notice Token that the liquidator sells CRV and CVX rewards for. This must be a 3Pool asset. ie DAI, USDC or USDT.
    address internal donateToken_;

    event DonateTokenUpdated(address token);

    /**
     * @param _nexus               Address of the Nexus contract that resolves protocol modules and roles..
     * @param _asset               Address of the vault's asset which is Curve's 3Pool LP token (3Crv).
     * @param _data                Initial data for `Convex3CrvAbstractVault` constructor of type `ConstructorData`.
     * @param _streamDuration      Number of seconds the increased asssets per share will be streamed after liquidated rewards are donated back.
     */
    constructor(
        address _nexus,
        address _asset,
        ConstructorData memory _data,
        uint256 _streamDuration
    )
        VaultManagerRole(_nexus)
        AbstractVault(_asset)
        Convex3CrvAbstractVault(_data)
        LiquidatorStreamAbstractVault(_streamDuration)
    {}

    /**
     * @param _name            Name of vault.
     * @param _symbol          Symbol of vault.
     * @param _vaultManager    Trusted account that can perform vault operations. eg rebalance.
     * @param _slippageData    Initial slippage limits.
     * @param _rewardTokens    Address of the reward tokens.
     * @param __donateToken    3Pool token (DAI, USDC or USDT) that CVX and CRV rewards are swapped to by the Liquidator.
     * @param _feeReceiver     Account that receives the performance fee as shares.
     * @param _donationFee     Donation fee scaled to `FEE_SCALE`.
     */
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _vaultManager,
        SlippageData memory _slippageData,
        address[] memory _rewardTokens,
        address __donateToken,
        address _feeReceiver,
        uint256 _donationFee
    ) external initializer {
        // Vault initialization
        VaultManagerRole._initialize(_vaultManager);
        AbstractSlippage._initialize(_slippageData);
        LiquidatorAbstractVault._initialize(_rewardTokens);
        Convex3CrvAbstractVault._initialize();
        LiquidatorStreamFeeAbstractVault._initialize(_feeReceiver, _donationFee);

        // Set the vault's decimals to the same as the metapool's LP token, eg musd3CRV
        uint8 decimals_ = InitializableToken(address(metapoolToken)).decimals();
        InitializableToken._initialize(_name, _symbol, decimals_);

        _setDonateToken(__donateToken);

        // Approve the Curve.fi 3Pool (3Crv) to transfer the 3Pool token
        IERC20(DAI).safeApprove(address(basePool), type(uint256).max);
        IERC20(USDC).safeApprove(address(basePool), type(uint256).max);
        IERC20(USDT).safeApprove(address(basePool), type(uint256).max);
    }

    /**
     * @notice The number of shares after any liquidated shares are burnt.
     * @return shares The vault's total number of shares.
     * @dev If shares are being burnt, the `totalSupply` will decrease in every block.
     * Uses the `LiquidatorStreamAbstractVault` implementation.
     */
    function totalSupply()
        public
        view
        virtual
        override(ERC20, IERC20, LiquidatorStreamAbstractVault)
        returns (uint256 shares)
    {
        shares = LiquidatorStreamAbstractVault.totalSupply();
    }

    /***************************************
                Liquidator Hooks
    ****************************************/

    /**
     * @return token Token that the liquidator needs to swap reward tokens to which must be either DAI, USDC or USDT.
     */
    function _donateToken(address) internal view override returns (address token) {
        token = donateToken_;
    }

    function _beforeCollectRewards() internal virtual override {
        // claim CRV and CVX from Convex
        // also claim any additional rewards if any.
        baseRewardPool.getReward(address(this), true);
    }

    /**
     * @dev Converts donated tokens (DAI, USDC or USDT) to vault assets (3Crv) and shares.
     * Transfers token from donor to vault.
     * Adds the token to the Curve 3Pool to receive the vault asset (3Crv) in exchange.
     * The resulting asset (3Crv) is added to the Curve Metapool.
     * The Curve Metapool LP token, eg mUSD3Crv, is added to the Convex pool and staked.
     */
    function _convertTokens(address token, uint256 amount)
        internal
        virtual
        override
        returns (uint256 shares_, uint256 assets_)
    {
        // Validate token is in 3Pool and scale all amounts up to 18 decimals
        uint256[3] memory basePoolAmounts;
        uint256 scaledUsdAmount;
        if (token == DAI) {
            scaledUsdAmount = amount;
            basePoolAmounts[0] = amount;
        } else if (token == USDC) {
            scaledUsdAmount = amount * 1e12;
            basePoolAmounts[1] = amount;
        } else if (token == USDT) {
            scaledUsdAmount = amount * 1e12;
            basePoolAmounts[2] = amount;
        } else {
            revert("token not in 3Pool");
        }

        // Transfer DAI, USDC or USDT from donor
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Deposit DAI, USDC or USDT and receive Curve.fi 3Pool LP tokens (3Crv).
        ICurve3Pool(basePool).add_liquidity(
            basePoolAmounts,
            0 // slippage protection will be done on the second deposit into the Metapool
        );

        // Slippage and flash loan protection
        // Convert DAI, USDC or USDT to Metapool LP tokens, eg musd3CRV.
        // This method uses the Metapool's virtual price which can not be manipulated with a flash loan.
        uint256 minMetapoolTokens = Curve3CrvMetapoolCalculatorLibrary.convertUsdToMetaLp(
            metapool,
            scaledUsdAmount
        );
        // Then reduce the metapol LP tokens amount by the slippage. eg 10 basis points = 0.1%
        minMetapoolTokens = (minMetapoolTokens * (BASIS_SCALE - depositSlippage)) / BASIS_SCALE;

        // Get vault's asset (3Crv) balance after adding token to Curve's 3Pool.
        assets_ = _asset.balanceOf(address(this));
        // Add asset (3Crv) to metapool with slippage protection.
        uint256 metapoolTokens = ICurveMetapool(metapool).add_liquidity([0, assets_], minMetapoolTokens);

        // Calculate share value of the new assets before depositing the metapool tokens to the Convex pool.
        shares_ = _getSharesFromMetapoolTokens(
            metapoolTokens,
            baseRewardPool.balanceOf(address(this)),
            totalSupply()
        );

        // Deposit Curve.fi Metapool LP token, eg musd3CRV, in Convex pool, eg cvxmusd3CRV, and stake.
        booster.deposit(convexPoolId, metapoolTokens, true);
    }

    /***************************************
     Vault overrides with streamRewards modifier
    ****************************************/

    // As two vaults (Convex3CrvAbstractVault and LiquidatorStreamFeeAbstractVault) are being inheriterd, Solidity needs to know which functions to override.

    /**
     * @notice Mint vault shares to receiver by transferring exact amount of underlying asset tokens (3Crv) from the caller.
     * @param assets The amount of underlying assets (3Crv) to be transferred to the vault.
     * @param receiver The account that the vault shares will be minted to.
     * @return shares The amount of vault shares that were minted.
     * @dev Burns any streamed shares from the last liquidation before depositing.
     */
    function deposit(uint256 assets, address receiver)
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    /**
     * @notice Mint exact amount of vault shares to the receiver by transferring enough underlying asset tokens (3Crv) from the caller.
     * @param shares The amount of vault shares to be minted.
     * @param receiver The account the vault shares will be minted to.
     * @return assets The amount of underlying assets (3Crv) that were transferred from the caller.
     * @dev Burns any streamed shares from the last liquidation before minting.
     */
    function mint(uint256 shares, address receiver)
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    /**
     * @notice Burns exact amount of vault shares from owner and transfers the underlying asset tokens (3Crv) to the receiver.
     * @param shares The amount of vault shares to be burnt.
     * @param receiver The account the underlying assets will be transferred to.
     * @param owner The account that owns the vault shares to be burnt.
     * @return assets The amount of underlying assets (3Crv) that were transferred to the receiver.
     * @dev Burns any streamed shares from the last liquidation before redeeming.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    )
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 assets)
    {
        assets = _redeem(shares, receiver, owner);
    }

    /**
     * @notice Burns enough vault shares from owner and transfers the exact amount of underlying asset tokens (3Crv) to the receiver.
     * @param assets The amount of underlying assets (3Crv) to be withdrawn from the vault.
     * @param receiver The account that the underlying assets will be transferred to.
     * @param owner Account that owns the vault shares to be burnt.
     * @return shares The amount of vault shares that were burnt.
     * @dev Burns any streamed shares from the last liquidation before withdrawing.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    )
        external
        virtual
        override(AbstractVault, LiquidatorStreamAbstractVault)
        whenNotPaused
        streamRewards
        returns (uint256 shares)
    {
        shares = _withdraw(assets, receiver, owner);
    }

    /***************************************
            Vault preview functions
    ****************************************/

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._previewDeposit(assets);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewMint(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._previewMint(shares);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._previewRedeem(shares);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._previewWithdraw(assets);
    }

    /***************************************
            Internal vault operations
    ****************************************/

    /// @dev use Convex3CrvAbstractVault implementation.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._deposit(assets, receiver);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._mint(shares, receiver);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual override(AbstractVault, Convex3CrvAbstractVault) returns (uint256 assets) {
        assets = Convex3CrvAbstractVault._redeem(shares, receiver, owner);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual override(AbstractVault, Convex3CrvAbstractVault) returns (uint256 shares) {
        shares = Convex3CrvAbstractVault._withdraw(assets, receiver, owner);
    }

    /***************************************
            Internal vault convertions
    ****************************************/

    /// @dev use Convex3CrvAbstractVault implementation.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 assets)
    {
        assets = Convex3CrvAbstractVault._convertToAssets(shares);
    }

    /// @dev use Convex3CrvAbstractVault implementation.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override(AbstractVault, Convex3CrvAbstractVault)
        returns (uint256 shares)
    {
        shares = Convex3CrvAbstractVault._convertToShares(assets);
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /// @dev Sets the token the rewards are swapped for and donated back to the vault.
    function _setDonateToken(address __donateToken) internal {
        require(
            __donateToken == DAI || __donateToken == USDC || __donateToken == USDT,
            "donate token not in 3Pool"
        );
        donateToken_ = __donateToken;

        emit DonateTokenUpdated(__donateToken);
    }

    /**
     * @notice  Vault manager or governor sets the token the rewards are swapped for and donated back to the vault.
     * @param __donateToken a token in the 3Pool (DAI, USDC or USDT).
     */
    function setDonateToken(address __donateToken) external onlyKeeperOrGovernor {
        _setDonateToken(__donateToken);
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

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { ILiquidatorVault } from "../../interfaces/ILiquidatorVault.sol";
import { VaultManagerRole } from "../../shared/VaultManagerRole.sol";

/**
 * @title   Vaults must implement this if they integrate to the Liquidator.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 *
 * Implementations must implement the `collectRewards` function.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - LiquidatorAbstractVault._initialize(_rewardTokens)
 */
abstract contract LiquidatorAbstractVault is ILiquidatorVault, VaultManagerRole {
    using SafeERC20 for IERC20;

    /// @notice Reward tokens collected by the vault.
    address[] public rewardToken;

    event RewardAdded(address indexed reward, uint256 position);

    /**
     * @param _rewardTokens Address of the reward tokens.
     */
    function _initialize(address[] memory _rewardTokens) internal virtual {
        _addRewards(_rewardTokens);
    }

    /**
     * Collects reward tokens from underlying platforms or vaults to this vault and
     * reports to the caller the amount of tokens now held by the vault.
     * This can be called by anyone but it used by the Liquidator to transfer the
     * rewards tokens from this vault to the liquidator.
     *
     * @param rewardTokens_ Array of reward tokens that were collected.
     * @param rewards The amount of reward tokens that were collected.
     * @param donateTokens The token the Liquidator swaps the reward tokens to.
     */
    function collectRewards()
        external
        virtual
        override
        returns (
            address[] memory rewardTokens_,
            uint256[] memory rewards,
            address[] memory donateTokens
        )
    {
        _beforeCollectRewards();

        uint256 rewardLen = rewardToken.length;
        rewardTokens_ = new address[](rewardLen);
        rewards = new uint256[](rewardLen);
        donateTokens = new address[](rewardLen);

        for (uint256 i = 0; i < rewardLen; ) {
            address rewardTokenMem = rewardToken[i];
            rewardTokens_[i] = rewardTokenMem;
            // Get reward token balance for this vault.
            rewards[i] = IERC20(rewardTokenMem).balanceOf(address(this));
            donateTokens[i] = _donateToken(rewardTokenMem);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Base implementation doesn't do anything.
     * This can be overridden to get rewards from underlying platforms or vaults.
     */
    function _beforeCollectRewards() internal virtual {
        // Do nothing
    }

    /**
     * @dev Tells the Liquidator what token to swap the reward tokens to.
     * For example, the vault asset.
     * @param reward Reward token that is being sold by the Liquidator.
     */
    function _donateToken(address reward) internal view virtual returns (address token);

    /**
     * @notice Adds new reward tokens to the vault so the liquidator module can transfer them from the vault.
     * Can only be called by the protocol governor.
     * @param _rewardTokens A list of reward token addresses.
     */
    function addRewards(address[] memory _rewardTokens) external virtual onlyGovernor {
        _addRewards(_rewardTokens);
    }

    function _addRewards(address[] memory _rewardTokens) internal virtual {
        address liquidator = _liquidatorV2();
        require(liquidator != address(0), "invalid Liquidator V2");

        uint256 rewardTokenLen = rewardToken.length;

        // For reward token
        uint256 len = _rewardTokens.length;
        for (uint256 i = 0; i < len; ) {
            address newReward = _rewardTokens[i];
            rewardToken.push(newReward);
            IERC20(newReward).safeApprove(liquidator, type(uint256).max);

            emit RewardAdded(newReward, rewardTokenLen + i);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns all reward tokens address added to the vault.
     */
    function rewardTokens() external view override returns (address[] memory) {
        return rewardToken;
    }

    /**
     * @notice Returns the token that rewards must be swapped to before donating back to the vault.
     * @param _rewardToken The address of the reward token collected by the vault.
     * @return token The address of the token that `_rewardToken` is to be swapped for.
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     */
    function donateToken(address _rewardToken) external view override returns (address token) {
        token = _donateToken(_rewardToken);
    }
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Libs
import { LiquidatorAbstractVault } from "./LiquidatorStreamAbstractVault.sol";
import { LiquidatorStreamAbstractVault, StreamData } from "./LiquidatorStreamAbstractVault.sol";
import { AbstractVault } from "../AbstractVault.sol";
import { FeeAdminAbstractVault } from "../fee/FeeAdminAbstractVault.sol";

/**
 * @notice   Abstract ERC-4626 vault that streams increases in the vault's assets per share
 * by minting and then burning shares over a period of time.
 * This vault charges a performance fee on the donated assets by senting a percentage of the streamed shares
 * to a fee receiver.
 *
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-08
 *
 * The following functions have to be implemented
 * - collectRewards()
 * - totalAssets()
 * - the token functions on `AbstractToken`.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 *   - LiquidatorStreamAbstractVault(_streamDuration)
 * - VaultManagerRole._initialize(_vaultManager)
 * - LiquidatorAbstractVault._initialize(_rewardTokens)
 * - LiquidatorStreamFeeAbstractVault._initialize(_feeReceiver, _donationFee)
 */
abstract contract LiquidatorStreamFeeAbstractVault is LiquidatorStreamAbstractVault {
    /// @notice Scale of the `donationFee`. 100% = 1000000, 1% = 10000, 0.01% = 100.
    uint256 public constant FEE_SCALE = 1e6;

    /// @notice Account that receives the donation fee as shares.
    address public feeReceiver;
    /// @notice Donation fee scaled to `FEE_SCALE`.
    uint32 public donationFee;

    event FeeReceiverUpdated(address indexed feeReceiver);
    event DonationFeeUpdated(uint32 donationFee);

    /**
     * @param _feeReceiver Account that receives the performance fee as shares.
     * @param _donationFee Donation fee scaled to `FEE_SCALE`.
     */
    function _initialize(address _feeReceiver, uint256 _donationFee) internal virtual {
        feeReceiver = _feeReceiver;
        donationFee = SafeCast.toUint32(_donationFee);
    }

    /**
     * @dev Collects a performance fee in the form of shares from the donated tokens.
     * @return streamShares_ The number of shares to be minted and then burnt over a period of time.
     * @return streamAssets_ The number of assets allocated to the streaming of shares.
     */
    function _beforeStreamShare(uint256 newShares, uint256 newAssets)
        internal
        virtual
        override
        returns (uint256 streamShares_, uint256 streamAssets_)
    {
        // Charge a fee
        uint256 feeShares = (newShares * donationFee) / FEE_SCALE;
        uint256 feeAssets = (newAssets * donationFee) / FEE_SCALE;
        streamShares_ = newShares - feeShares;
        streamAssets_ = newAssets - feeAssets;

        // Mint new shares to the fee receiver. These shares will not be burnt over time.
        _mint(feeReceiver, feeShares);

        emit Deposit(msg.sender, feeReceiver, feeAssets, feeShares);
    }

    /***************************************
                    Vault Admin
    ****************************************/

    /**
     * @notice  Called by the protocol `Governor` to set a new donation fee
     * @param _donationFee Donation fee scaled to 6 decimal places. 1% = 10000, 0.01% = 100
     */
    function setDonationFee(uint32 _donationFee) external onlyGovernor {
        require(_donationFee <= FEE_SCALE, "Invalid fee");

        donationFee = _donationFee;

        emit DonationFeeUpdated(_donationFee);
    }

    /**
     * @notice Called by the protocol `Governor` to set the fee receiver address.
     * @param _feeReceiver Address that will receive the fees.
     */
    function setFeeReceiver(address _feeReceiver) external onlyGovernor {
        feeReceiver = _feeReceiver;

        emit FeeReceiverUpdated(feeReceiver);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { AbstractVault, IERC20 } from "../AbstractVault.sol";
import { LiquidatorAbstractVault } from "./LiquidatorAbstractVault.sol";

struct StreamData {
    uint32 last;
    uint32 end;
    uint128 sharesPerSecond;
}

/**
 * @title   Abstract ERC-4626 vault that streams increases in the vault's assets per share by minting and then burning shares over a period of time.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-03
 *
 * Implementations must implement the `collectRewards` function.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - LiquidatorAbstractVault._initialize(_rewardTokens)
 */
abstract contract LiquidatorStreamAbstractVault is AbstractVault, LiquidatorAbstractVault {
    using SafeERC20 for IERC20;

    /// @notice Number of seconds the increased asssets per share will be streamed after tokens are donated.
    uint256 public immutable STREAM_DURATION;
    /// @notice The scale of the shares per second to be burnt which is 18 decimal places.
    uint256 public constant STREAM_PER_SECOND_SCALE = 1e18;

    /// @notice Stream data for the shares being burnt over time to slowing increase the vault's assetes per share.
    StreamData public shareStream;

    modifier streamRewards() {
        _streamRewards();
        _;
    }

    /**
     * @param _streamDuration  Number of seconds the increased asssets per share will be streamed after liquidated rewards are donated back.
     */
    constructor(uint256 _streamDuration) {
        STREAM_DURATION = _streamDuration;
    }

    /// @dev calculates the amount of vault shares that can be burnt to this point in time.
    function _secondsToBurn(StreamData memory stream) internal view returns (uint256 secondsToBurn_) {
        // If still burning vault shares
        if (block.timestamp < stream.end) {
            secondsToBurn_ = block.timestamp - stream.last;
        }
        // If still vault shares to burn since the stream ended.
        else if (stream.last < stream.end) {
            secondsToBurn_ = stream.end - stream.last;
        }
    }

    /// @dev Burns vault shares to this point of time.
    function _streamRewards() internal {
        StreamData memory stream = shareStream;

        if (stream.last < stream.end) {
            uint256 secondsToBurn = _secondsToBurn(stream);
            uint256 sharesToBurn = (secondsToBurn * stream.sharesPerSecond) /
                STREAM_PER_SECOND_SCALE;

            // Store the current timestamp which can be past the end.
            shareStream.last = SafeCast.toUint32(block.timestamp);

            // Burn the shares since the last time.
            _burn(address(this), sharesToBurn);

            emit Withdraw(msg.sender, address(0), address(this), 0, sharesToBurn);
        }
    }

    /**
     * @notice The number of shares after any liquidated shares are burnt.
     * @return shares The vault's total number of shares.
     * @dev If shares are being burnt, the `totalSupply` will decrease in every block.
     */
    function totalSupply() public view virtual override(ERC20, IERC20) returns (uint256 shares) {
        StreamData memory stream = shareStream;
        uint256 secondsToBurn = _secondsToBurn(stream);
        uint256 sharesToBurn = (secondsToBurn * stream.sharesPerSecond) / STREAM_PER_SECOND_SCALE;
        
        shares = ERC20.totalSupply() - sharesToBurn;
    }

    /**
     * @notice Converts donated tokens into vault assets, mints shares so the assets per share
     * does not increase initially, and then burns the new shares over a period of time
     * so the assets per share gradually increases.
     * @param token The address of the token being donated to the vault.
     @ @param amount The amount of tokens being donated to the vault.
     */
    function donate(address token, uint256 amount) external virtual override streamRewards {
        (uint256 newShares, uint256 newAssets) = _convertTokens(token, amount);

        StreamData memory stream = shareStream;
        uint256 remainingStreamShares = _streamedShares(stream);

        if (newShares > 0) {
            // Not all shares have to be streamed. Some may be used as a fee.
            (uint256 newStreamShares, uint256 streamAssets) = _beforeStreamShare(
                newShares,
                newAssets
            );

            uint256 sharesPerSecond = ((remainingStreamShares + newStreamShares) *
                STREAM_PER_SECOND_SCALE) / STREAM_DURATION;

            // Store updated stream data
            shareStream = StreamData(
                SafeCast.toUint32(block.timestamp),
                SafeCast.toUint32(block.timestamp + STREAM_DURATION),
                SafeCast.toUint128(sharesPerSecond)
            );

            // Mint new shares that will be burnt over time.
            _mint(address(this), newStreamShares);

            emit Deposit(msg.sender, address(this), streamAssets, newStreamShares);
        }
    }

    /**
     * @dev The base implementation assumes the donated token is the vault's asset token.
     * This can be overridden in implementing contracts.
     * Overriding implementations can also invest the assets into an underlying platform or vaults.
     */
    function _convertTokens(address token, uint256 amount)
        internal
        virtual
        returns (uint256 shares_, uint256 assets_)
    {
        require(token == address(_asset), "Donated token not asset");

        assets_ = amount;

        uint256 totalAssetsBefore = totalAssets();
        // if no assets in the vault yet then shares = assets
        // use the shares per asset when the existing streaming ends so remove the unstream shares from the total supply.
        shares_ = totalAssetsBefore == 0
            ? amount
            : (amount * (ERC20.totalSupply() - _streamedShares(shareStream))) / totalAssetsBefore;

        // Transfer assets from donor to vault.
        _asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev This implementation just returns the amount of new shares and assets. The can be overriden to take out a fee
     * or do something else with the shares.
     * @param newShares The total number of new shares to be minted in order to stream the increased in assets per share.
     * @param newAssets The total number of new assets being deposited.
     * @param streamShares The number of shares to be minted and then burnt over a period of time.
     * @param streamAssets The number of assets allocated to the streaming of shares.
     */
    function _beforeStreamShare(uint256 newShares, uint256 newAssets)
        internal
        virtual
        returns (uint256 streamShares, uint256 streamAssets)
    {
        streamShares = newShares;
        streamAssets = newAssets;
    }

    /**
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     */
    function _donateToken(address) internal view virtual override returns (address token) {
        token = address(_asset);
    }

    /// @return remainingShares The amount of liquidated shares still to be burnt.
    function _streamedShares(StreamData memory stream)
        internal
        pure
        returns (uint256 remainingShares)
    {
        if (stream.last < stream.end) {
            uint256 secondsSinceLast = stream.end - stream.last;

            remainingShares = (secondsSinceLast * stream.sharesPerSecond) / STREAM_PER_SECOND_SCALE;
        }
    }

    /***************************************
            Streamed Rewards Views
    ****************************************/

    /**
     * @return remaining Amount of liquidated shares still to be burnt.
     */
    function streamedShares() external view returns (uint256 remaining) {
        StreamData memory stream = shareStream;
        remaining = _streamedShares(stream);
    }

    /***************************************
        Add streamRewards modifier
    ****************************************/

    function deposit(uint256 assets, address receiver)
        external
        virtual
        override
        whenNotPaused
        streamRewards
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        external
        virtual
        override
        whenNotPaused
        streamRewards
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override whenNotPaused streamRewards returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override whenNotPaused streamRewards returns (uint256 shares) {
        shares = _withdraw(assets, receiver, owner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface ICurveMetapool {
    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] memory amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

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
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external
        returns (uint256[2] memory);

    function remove_liquidity_imbalance(uint256[2] memory amounts, uint256 max_burn_amount)
        external
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns (uint256);

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

    function base_pool() external view returns (address);

    function base_virtual_price() external view returns (uint256);

    function base_cache_updated() external view returns (uint256);

    function base_coins(uint256 arg0) external view returns (address);

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
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 token_supply
    );

    event RemoveLiquidityOne(
        address indexed provider,
        uint256[2] token_amount,
        uint256 coin_amount
    );

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
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
import { ICurveMetapool } from "./ICurveMetapool.sol";

/**
 * @title   Calculates Curve token amounts including fees for Curve.fi Metapools that are based on 3Pool (3Crv).
 * @notice  This has been configured to work for metapools with only two coins, 18 decimal places
 * and 3Pool (3Crv) as the base pool. That is, 3Crv is the second coin in index position 1 of the metapool.
 * This is an alternative to Curve's `calc_token_amount` which does not take into account fees.
 * This library takes into account pool fees.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-07-12
 * @dev     See Atul Agarwal's post "Understanding the Curve AMM, Part -1: StableSwap Invariant"
 *          for an explaination of the maths behind StableSwap. This includes an explation of the
 *          variables S, D, Ann used in getD and getY.
 *          https://atulagarwal.dev/posts/curveamm/stableswap/
 */
library Curve3CrvMetapoolCalculatorLibrary {
    /// @notice Curve's 3Pool used as a base pool by the Curve metapools.
    address public constant BASE_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    /// @notice Number of coins in the pool.
    uint256 public constant N_COINS = 2;
    uint256 public constant VIRTUAL_PRICE_SCALE = 1e18;
    /// @notice Scale of the Curve.fi metapool fee. 100% = 1e10, 0.04% = 4e6.
    uint256 public constant CURVE_FEE_SCALE = 1e10;
    /// @notice Time in seconds the 3Pool virtual price is cached in the Metapool = 10 minutes.
    uint256 public constant BASE_CACHE_EXPIRES = 10 * 60;
    /// @notice Scales up the mint tokens by 0.002 basis points.
    uint256 public constant MINT_ADJUST = 10000002;
    uint256 public constant MINT_ADJUST_SCALE = 10000000;

    /**
     * @notice Calculates the amount of metapool liquidity provider tokens, eg musd3Crv,
     * to mint for depositing a fixed amount of tokens, eg mUSD or 3Crv, to the metapool.
     * @param _metapool Curve metapool to deposit tokens. eg mUSD+3Crv
     * @param _metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param _tokenAmount The amount of coins, eg mUSD or 3Crv, to deposit to the metapool.
     * @param _coinIndex The index of the coin in the metapool. 0 = eg musd, 1 = base coin, eg 3Crv.
     * @return mintAmount_ The amount of metapool liquidity provider tokens, eg musd3Crv, to mint.
     * @return invariant_ The metapool invariant before the deposit. This is the USD value of the metapool.
     * @return totalSupply_ Total metapool liquidity provider tokens, eg musd3Crv, before the deposit.
     * @return baseVirtualPrice_ Virtual price of the base pool in USD and `VIRTUAL_PRICE_SCALE` decimals.
     */
    function calcDeposit(
        address _metapool,
        address _metapoolToken,
        uint256 _tokenAmount,
        uint256 _coinIndex
    )
        external
        view
        returns (
            uint256 mintAmount_,
            uint256 invariant_,
            uint256 totalSupply_,
            uint256 baseVirtualPrice_
        )
    {
        totalSupply_ = IERC20(_metapoolToken).totalSupply();
        // To save gas, only deal with a non empty pool.
        require(totalSupply_ > 0, "empty pool");

        baseVirtualPrice_ = _baseVirtualPrice(_metapool, true);

        // Using separate vairables rather than an array to save gas
        uint256 oldBalancesScaled0 = ICurveMetapool(_metapool).balances(0);
        uint256 oldBalancesScaled1 = ICurveMetapool(_metapool).balances(1);

        // The metapool's amplitude coefficient (A) multiplied by the number of coins in the pool.
        uint256 Ann = ICurveMetapool(_metapool).A() * N_COINS;

        // Calculate invariant before deposit
        invariant_ = _getD(
            [oldBalancesScaled0, (oldBalancesScaled1 * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE],
            Ann
        );

        // Using separate vairables rather than an array to save gas
        uint256 newBalancesScaled0 = _coinIndex == 0
            ? oldBalancesScaled0 + _tokenAmount
            : oldBalancesScaled0;
        uint256 newBalancesScaled1 = _coinIndex == 1
            ? oldBalancesScaled1 + _tokenAmount
            : oldBalancesScaled1;

        // Recalculate invariant after deposit
        uint256 invariantAfterDeposit = _getD(
            [newBalancesScaled0, (newBalancesScaled1 * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE],
            Ann
        );

        // We need to recalculate the invariant accounting for fees to calculate fair user's share
        // fee: uint256 = CurveBase(_base_pool).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
        uint256 fee = ICurveMetapool(_metapool).fee() / 2;
        uint256 differenceScaled;

        // Get the difference between the actual balance after deposit and the ideal balance if a propotional deposit.
        differenceScaled = _coinIndex == 0
            ? newBalancesScaled0 - ((oldBalancesScaled0 * invariantAfterDeposit) / invariant_)
            : ((oldBalancesScaled0 * invariantAfterDeposit) / invariant_) - oldBalancesScaled0;
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled0 -= (fee * differenceScaled) / CURVE_FEE_SCALE;

        // Get the difference between the actual balance after deposit and the ideal balance if a propotional deposit.
        differenceScaled = _coinIndex == 1
            ? newBalancesScaled1 - ((oldBalancesScaled1 * invariantAfterDeposit) / invariant_)
            : ((oldBalancesScaled1 * invariantAfterDeposit) / invariant_) - oldBalancesScaled1;
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled1 -= (fee * differenceScaled) / CURVE_FEE_SCALE;

        // Recalculate invariant after fees have been taken out
        uint256 invariantAfterFees = _getD(
            [newBalancesScaled0, (newBalancesScaled1 * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE],
            Ann
        );

        // Calculate how much metapool tokens to mint
        mintAmount_ = (totalSupply_ * (invariantAfterFees - invariant_)) / invariant_;
    }

    /**
     * @notice Calculates the amount of metapool liquidity provider tokens, eg musd3Crv,
     * to burn for withdrawing a fixed amount of tokens, eg mUSD or 3Crv, from the metapool.
     * @param _metapool Curve metapool to withdraw tokens. eg mUSD+3Crv
     * @param _metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param _tokenAmount The amount of coins, eg mUSD or 3Crv, to withdraw from the metapool.
     * @param _coinIndex The index of the coin in the metapool. 0 = eg musd, 1 = base coin, eg 3Crv.
     * @return burnAmount_ The amount of metapool liquidity provider tokens, eg musd3Crv, to burn.
     * @return invariant_ The metapool invariant before the withdraw. This is the USD value of the metapool.
     * @return totalSupply_ Total metapool liquidity provider tokens, eg musd3Crv, before the withdraw.
     */
    function calcWithdraw(
        address _metapool,
        address _metapoolToken,
        uint256 _tokenAmount,
        uint256 _coinIndex
    )
        external
        view
        returns (
            uint256 burnAmount_,
            uint256 invariant_,
            uint256 totalSupply_,
            uint256 baseVirtualPrice_
        )
    {
        totalSupply_ = IERC20(_metapoolToken).totalSupply();
        // To save gas, only deal with a non empty pool.
        require(totalSupply_ > 0, "empty pool");

        baseVirtualPrice_ = _baseVirtualPrice(_metapool, true);

        // Using separate vairables rather than an array to save gas
        uint256 oldBalancesScaled0 = ICurveMetapool(_metapool).balances(0);
        uint256 oldBalancesScaled1 = ICurveMetapool(_metapool).balances(1);

        // The metapool's amplitude coefficient (A) multiplied by the number of coins in the pool.
        uint256 Ann = ICurveMetapool(_metapool).A() * N_COINS;

        // Calculate invariant before deposit
        invariant_ = _getD(
            [oldBalancesScaled0, (oldBalancesScaled1 * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE],
            Ann
        );

        // Using separate vairables rather than an array to save gas
        uint256 newBalancesScaled0 = _coinIndex == 0
            ? oldBalancesScaled0 - _tokenAmount
            : oldBalancesScaled0;
        uint256 newBalancesScaled1 = _coinIndex == 1
            ? oldBalancesScaled1 - _tokenAmount
            : oldBalancesScaled1;

        // Recalculate invariant after deposit
        uint256 invariantAfterWithdraw = _getD(
            [newBalancesScaled0, (newBalancesScaled1 * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE],
            Ann
        );

        // We need to recalculate the invariant accounting for fees to calculate fair user's share
        // fee: uint256 = CurveBase(_base_pool).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
        uint256 fee = ICurveMetapool(_metapool).fee() / 2;
        uint256 differenceScaled;

        // Get the difference between the actual balance after deposit and the ideal balance if a propotional deposit.
        differenceScaled = _coinIndex == 0
            ? ((oldBalancesScaled0 * invariantAfterWithdraw) / invariant_) - newBalancesScaled0
            : oldBalancesScaled0 - ((oldBalancesScaled0 * invariantAfterWithdraw) / invariant_);
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled0 -= (fee * differenceScaled) / CURVE_FEE_SCALE;

        // Get the difference between the actual balance after deposit and the ideal balance if a propotional deposit.
        differenceScaled = _coinIndex == 1
            ? ((oldBalancesScaled1 * invariantAfterWithdraw) / invariant_) - newBalancesScaled1
            : oldBalancesScaled1 - ((oldBalancesScaled1 * invariantAfterWithdraw) / invariant_);
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled1 -= (fee * differenceScaled) / CURVE_FEE_SCALE;

        // Recalculate invariant after fees have been taken out
        uint256 invariantAfterFees = _getD(
            [newBalancesScaled0, (newBalancesScaled1 * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE],
            Ann
        );

        // Calculate how much metapool tokens to burn
        burnAmount_ = ((totalSupply_ * (invariant_ - invariantAfterFees)) / invariant_) + 1;
    }

    /**
     * @notice Calculates the amount of metapool coins, eg mUSD or 3Crv, to deposit into the metapool
     * to mint a fixed amount of metapool liquidity provider tokens, eg musd3Crv.
     * @param _metapool Curve metapool to mint lp tokens. eg mUSD+3Crv
     * @param _metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param _mintAmount The amount of metapool liquidity provider token, eg musd3Crv, to mint.
     * @param _coinIndex The index of the coin in the metapool. 0 = eg musd, 1 = base coin, eg 3Crv.
     * @return tokenAmount_ The amount of coins, eg mUSD or 3Crv, to deposit.
     * @return invariant_ The invariant before the mint. This is the USD value of the metapool.
     * @return totalSupply_ Total metapool liquidity provider tokens, eg musd3Crv, before the mint.
     */
    function calcMint(
        address _metapool,
        address _metapoolToken,
        uint256 _mintAmount,
        uint256 _coinIndex
    )
        external
        view
        returns (
            uint256 tokenAmount_,
            uint256 invariant_,
            uint256 totalSupply_,
            uint256 baseVirtualPrice_
        )
    {
        totalSupply_ = IERC20(_metapoolToken).totalSupply();
        // To save gas, only deal with a non empty pool.
        require(totalSupply_ > 0, "empty pool");

        baseVirtualPrice_ = _baseVirtualPrice(_metapool, true);

        // Using separate vairables rather than an array to save gas
        uint256 oldBalancesScaled0 = ICurveMetapool(_metapool).balances(0);
        uint256 oldBalancesScaled1 = (ICurveMetapool(_metapool).balances(1) * baseVirtualPrice_) /
            VIRTUAL_PRICE_SCALE;

        // The metapool's amplitude coefficient (A) multiplied by the number of coins in the pool.
        uint256 Ann = ICurveMetapool(_metapool).A() * N_COINS;

        // Calculate invariant before deposit
        invariant_ = _getD([oldBalancesScaled0, oldBalancesScaled1], Ann);

        // Desired invariant after mint
        uint256 invariantAfterMint = invariant_ + ((_mintAmount * invariant_) / totalSupply_);

        // Required coin balance to get to the new invariant after mint
        uint256 requiredBalanceScaled = _getY(
            [oldBalancesScaled0, oldBalancesScaled1],
            Ann,
            _coinIndex,
            invariantAfterMint
        );

        // Adjust balances for fees
        // fee: uint256 = CurveBase(_base_pool).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
        uint256 fee = ICurveMetapool(_metapool).fee() / 2;
        // Get the difference between the actual balance after deposit and the ideal balance if a propotional deposit.
        // The first assignment is the balance delta but can't use a diff variable due to stack too deep
        uint256 newBalancesScaled0 = _coinIndex == 0
            ? requiredBalanceScaled - ((oldBalancesScaled0 * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled0 * invariantAfterMint) / invariant_) - oldBalancesScaled0;
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled0 = oldBalancesScaled0 - ((newBalancesScaled0 * fee) / CURVE_FEE_SCALE);

        // Get the difference between the actual balance after deposit and the ideal balance if a propotional deposit.
        // The first assignment is the balance delta but can't use a diff variable due to stack too deep
        uint256 newBalancesScaled1 = _coinIndex == 1
            ? requiredBalanceScaled - ((oldBalancesScaled1 * invariantAfterMint) / invariant_)
            : ((oldBalancesScaled1 * invariantAfterMint) / invariant_) - oldBalancesScaled1;
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled1 = oldBalancesScaled1 - ((newBalancesScaled1 * fee) / CURVE_FEE_SCALE);

        // Calculate new coin balance to preserve the invariant
        requiredBalanceScaled = _getY(
            [newBalancesScaled0, newBalancesScaled1],
            Ann,
            _coinIndex,
            invariantAfterMint
        );

        // tokens required to deposit = new coin balance - current coin balance
        // Deposit more to account for rounding errors.
        // If the base pool lp token, eg 3Crv, then need to convert from USD back to 3Crv
        // using the base pool virtual price.
        tokenAmount_ = _coinIndex == 0
            ? requiredBalanceScaled - newBalancesScaled0
            : ((requiredBalanceScaled - newBalancesScaled1) * VIRTUAL_PRICE_SCALE) /
                baseVirtualPrice_;
        // Round up the amount
        tokenAmount_ = (tokenAmount_ * MINT_ADJUST) / MINT_ADJUST_SCALE;
    }

    /**
     * @notice Calculates the amount of metapool coins, eg mUSD or 3Crv, that will be received from the metapool
     * from burning a fixed amount of metapool liquidity provider tokens, eg musd3Crv.
     * @param _metapool Curve metapool to redeem lp tokens. eg mUSD+3Crv
     * @param _metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param _burnAmount The amount of metapool liquidity provider token, eg musd3Crv, to burn.
     * @param _coinIndex The index of the coin in the metapool. 0 = eg musd, 1 = base coin, eg 3Crv.
     * @return tokenAmount_ The amount of coins, eg mUSD or 3Crv, to deposit.
     * @return invariant_ The invariant before the redeem. This is the USD value of the metapool.
     * @return totalSupply_ Total metapool liquidity provider tokens, eg musd3Crv, before the redeem.
     */
    function calcRedeem(
        address _metapool,
        address _metapoolToken,
        uint256 _burnAmount,
        uint256 _coinIndex
    )
        external
        view
        returns (
            uint256 tokenAmount_,
            uint256 invariant_,
            uint256 totalSupply_
        )
    {
        totalSupply_ = IERC20(_metapoolToken).totalSupply();
        // To save gas, only deal with a non empty pool.
        require(totalSupply_ > 0, "empty pool");

        uint256 baseVirtualPrice = _baseVirtualPrice(_metapool, true);

        // Using separate vairables rather than an array to save gas
        uint256 oldBalancesScaled0 = ICurveMetapool(_metapool).balances(0);
        uint256 oldBalancesScaled1 = (ICurveMetapool(_metapool).balances(1) * baseVirtualPrice) /
            VIRTUAL_PRICE_SCALE;

        // The metapool's amplitude coefficient (A) multiplied by the number of coins in the pool.
        uint256 Ann = ICurveMetapool(_metapool).A() * N_COINS;

        // Calculate invariant before deposit
        invariant_ = _getD([oldBalancesScaled0, oldBalancesScaled1], Ann);

        // Desired invariant after redeem
        uint256 invariantAfterRedeem = invariant_ - ((_burnAmount * invariant_) / totalSupply_);

        // Required coin balance to get to the new invariant after redeem
        uint256 requiredBalanceScaled = _getY(
            [oldBalancesScaled0, oldBalancesScaled1],
            Ann,
            _coinIndex,
            invariantAfterRedeem
        );

        // Adjust balances for fees
        // fee: uint256 = CurveBase(_base_pool).fee() * BASE_N_COINS / (4 * (BASE_N_COINS - 1))
        uint256 fee = ICurveMetapool(_metapool).fee() / 2;
        // Get the difference between the actual balance after deposit and the ideal balance if a propotional redeem.
        // The first assignment is the balance delta but can't use a diff variable due to stack too deep
        uint256 newBalancesScaled0 = _coinIndex == 0
            ? ((oldBalancesScaled0 * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled0 - ((oldBalancesScaled0 * invariantAfterRedeem) / invariant_);
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled0 = oldBalancesScaled0 - ((newBalancesScaled0 * fee) / CURVE_FEE_SCALE);

        // Get the difference between the actual balance after deposit and the ideal balance if a propotional redeem.
        // The first assignment is the balance delta but can't use a diff variable due to stack too deep
        uint256 newBalancesScaled1 = _coinIndex == 1
            ? ((oldBalancesScaled1 * invariantAfterRedeem) / invariant_) - requiredBalanceScaled
            : oldBalancesScaled1 - ((oldBalancesScaled1 * invariantAfterRedeem) / invariant_);
        // new balance = old balance - (diff from ideal balance * fee)
        newBalancesScaled1 = oldBalancesScaled1 - ((newBalancesScaled1 * fee) / CURVE_FEE_SCALE);

        // Calculate new coin balance to preserve the invariant
        requiredBalanceScaled = _getY(
            [newBalancesScaled0, newBalancesScaled1],
            Ann,
            _coinIndex,
            invariantAfterRedeem
        );

        // tokens required to deposit = new coin balance - current coin balance
        // Deposit more to account for rounding errors.
        // If the base pool lp token, eg 3Crv, then need to convert from USD back to 3Crv
        // using the base pool virtual price.
        tokenAmount_ = _coinIndex == 0
            ? newBalancesScaled0 - requiredBalanceScaled - 1
            : ((newBalancesScaled1 - requiredBalanceScaled - 1) * VIRTUAL_PRICE_SCALE) /
                baseVirtualPrice;
    }

    /**
     * @notice Gets the USD price of the base pool liquidity provider token scaled to `VIRTUAL_PRICE_SCALE`. eg 3Crv/USD.
     * This is either going to be from
     * 1. The 10 minute cache in the metapool.
     * 2. The latest directly from the base pool.
     * Note the base pool virtual price is different to the metapool virtual price.
     * The base pool's virtual price is used to price 3Pool's 3Crv back to USD.
     * @param metapool Curve metapool to get the virtual price from.
     * @param cached true will try and get the base pool's virtual price from the metapool cache.
     */
    function getBaseVirtualPrice(address metapool, bool cached)
        external
        view
        returns (uint256 baseVirtualPrice_)
    {
        baseVirtualPrice_ = _baseVirtualPrice(metapool, cached);
    }

    /**
     * @notice Gets the USD price of the base pool liquidity provider token scaled to `VIRTUAL_PRICE_SCALE`. eg 3Crv/USD.
     * This is directly from the base pool and not the cached value in the Metapool.
     */
    function getBaseVirtualPrice() external view returns (uint256 baseVirtualPrice_) {
        baseVirtualPrice_ = ICurve3Pool(BASE_POOL).get_virtual_price();
    }

    /**
     * @dev Gets the base pool's virtual price. This is either going to be from
     * 1. The 10 minute cache in the metapool.
     * 2. The latest directly from the base pool.
     * Note the base pool virtual price is different to the metapool virtual price.
     * The base pool's virtual price is used to price 3Pool's 3Crv back to USD.
     * @param metapool Curve metapool to get the virtual price from.
     * @param cached true will try and get the base pool's virtual price from the metapool cache.
     */
    function _baseVirtualPrice(address metapool, bool cached)
        internal
        view
        returns (uint256 baseVirtualPrice_)
    {
        if (cached) {
            // Get the last time the metapool updated it's virtual price cache.
            uint256 baseCacheUpdated = ICurveMetapool(metapool).base_cache_updated();
            if (block.timestamp <= baseCacheUpdated + BASE_CACHE_EXPIRES) {
                // Get the base pool's virtual price cached in the metapool
                return ICurveMetapool(metapool).base_virtual_price();
            }
        }
        // If not cached or cache older than 10 minutes then get latest virtual price from the base pool.
        baseVirtualPrice_ = ICurve3Pool(BASE_POOL).get_virtual_price();
    }

    /**
     * @notice Gets the metapool and basepool virtual prices. These prices do not change with the balance of the coins in the pools.
     * This means the virtual prices can not be manipulated with flash loans or sandwich attacks.
     * @param metapool Curve metapool to get the virtual price from.
     * @param metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param cached true will try and get the base pool's virtual price from the metapool cache.
     * false will get the base pool's virtual price directly from the base pool.
     * @return metaVirtualPrice_ Metapool's liquidity provider token price in USD scaled to `VIRTUAL_PRICE_SCALE`. eg musd3Crv/USD
     * @return baseVirtualPrice_ Basepool's liquidity provider token price in USD scaled to `VIRTUAL_PRICE_SCALE`. eg 3Crv/USD
     */
    function getVirtualPrices(
        address metapool,
        address metapoolToken,
        bool cached
    ) external view returns (uint256 metaVirtualPrice_, uint256 baseVirtualPrice_) {
        baseVirtualPrice_ = _baseVirtualPrice(metapool, cached);

        // Calculate invariant before deposit
        uint256 invariant = _getD(
            [
                ICurveMetapool(metapool).balances(0),
                (ICurveMetapool(metapool).balances(1) * baseVirtualPrice_) / VIRTUAL_PRICE_SCALE
            ],
            ICurveMetapool(metapool).A() * N_COINS
        );

        // This will fail if the metapool is empty
        metaVirtualPrice_ = (invariant * VIRTUAL_PRICE_SCALE) / IERC20(metapoolToken).totalSupply();
    }

    /**
     * @notice Values USD amount as base pool LP tokens.
     * Base pool LP = USD amount * virtual price scale / base pool virutal price
     * @param usdAmount Amount of USD scaled to 18 decimal places to value.
     * @return baseLp_ Value in base pool liquidity provider tokens. eg 3Crv
     */
    function convertUsdToBaseLp(uint256 usdAmount) external view returns (uint256 baseLp_) {
        if (usdAmount > 0) {
            baseLp_ =
                (usdAmount * VIRTUAL_PRICE_SCALE) /
                ICurve3Pool(BASE_POOL).get_virtual_price();
        }
    }

    /**
     * @notice Values USD amount as metapool LP tokens.
     * Metapool LP = USD amount * virtual price scale / metapool virutal price
     * @param metapool Curve metapool to get the virtual price from.
     * @param usdAmount Amount of USD scaled to 18 decimal places to value.
     * @return metaLp_ Value in metapool liquidity provider tokens. eg musd3Crv
     */
    function convertUsdToMetaLp(address metapool, uint256 usdAmount)
        external
        view
        returns (uint256 metaLp_)
    {
        if (usdAmount > 0) {
            metaLp_ =
                (usdAmount * VIRTUAL_PRICE_SCALE) /
                ICurveMetapool(metapool).get_virtual_price();
        }
    }

    /**
     * @notice Values metapool liquidity provider (LP) tokens as base pool LP tokens.
     * Base pool LP = metapool LP tokens * metapool USD value * base pool virtual price scale /
     * (total metapool LP supply * base pool virutal price)
     * @param metapool Curve metapool to get the virtual price from.
     * @param metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param cached true will try and get the base pool's virtual price from the metapool cache.
     * @param metaLp Amount of metapool liquidity provider tokens to value.
     * @return baseLp_ Value in base pool liquidity provider tokens.
     */
    function convertToBaseLp(
        address metapool,
        address metapoolToken,
        uint256 metaLp,
        bool cached
    ) public view returns (uint256 baseLp_) {
        if (metaLp > 0) {
            // Get value of one base pool lp token in USD scaled to VIRTUAL_PRICE_SCALE. eg 3Crv/USD.
            // This will use Metapool's cached base virtual price.
            uint256 baseVirtualPrice = _baseVirtualPrice(metapool, cached);

            // Calculate metapool invariant which is value of the metapool in USD
            uint256 invariant = _getD(
                [
                    ICurveMetapool(metapool).balances(0),
                    (ICurveMetapool(metapool).balances(1) * baseVirtualPrice) / VIRTUAL_PRICE_SCALE
                ],
                ICurveMetapool(metapool).A() * N_COINS
            );

            uint256 metaVirtualPrice = (invariant * VIRTUAL_PRICE_SCALE) /
                IERC20(metapoolToken).totalSupply();

            // This will fail if the metapool is empty
            baseLp_ = (metaLp * metaVirtualPrice) / baseVirtualPrice;
        }
    }

    function convertToBaseLp(
        address metapool,
        address metapoolToken,
        uint256 metaLp
    ) external view returns (uint256 baseLp_) {
        baseLp_ = convertToBaseLp(metapool, metapoolToken, metaLp, false);
    }

    /**
     * @notice Values base pool liquidity provider (LP) tokens as metapool LP tokens.
     * Metapool LP = base pool LP tokens * base pool virutal price * total metapool LP supply /
     * (metapool USD value * base pool virtual price scale)
     * @param metapool Curve metapool to get the virtual price from.
     * @param metapoolToken Curve metapool liquidity provider token. eg musd3Crv/USD
     * @param baseLp Amount of base pool liquidity provider tokens to value.
     * @param cached true will try and get the base pool's virtual price from the metapool cache.
     * @return metaLp_ Value in metapool liquidity provider tokens.
     */
    function convertToMetaLp(
        address metapool,
        address metapoolToken,
        uint256 baseLp,
        bool cached
    ) public view returns (uint256 metaLp_) {
        if (baseLp > 0) {
            uint256 baseVirtualPrice = _baseVirtualPrice(metapool, cached);

            // Calculate invariant which is value of metapool in USD
            uint256 invariant = _getD(
                [
                    ICurveMetapool(metapool).balances(0),
                    (ICurveMetapool(metapool).balances(1) * baseVirtualPrice) / VIRTUAL_PRICE_SCALE
                ],
                ICurveMetapool(metapool).A() * N_COINS
            );

            uint256 metaVirtualPrice = (invariant * VIRTUAL_PRICE_SCALE) /
                IERC20(metapoolToken).totalSupply();

            metaLp_ = (baseLp * baseVirtualPrice) / metaVirtualPrice;
        }
    }

    function convertToMetaLp(
        address metapool,
        address metapoolToken,
        uint256 baseLp
    ) external view returns (uint256 metaLp_) {
        metaLp_ = convertToMetaLp(metapool, metapoolToken, baseLp, false);
    }

    /**
     * @notice Uses Newton’s Method to iteratively solve the StableSwap invariant (D).
     * @dev This is a port of Curve's Vyper implementation with some gas optimizations.
     * Curve's implementation is `get_D` in https://etherscan.io/address/0x8474ddbe98f5aa3179b3b3f5942d724afcdec9f6#code
     *
     * @param xp  The scaled balances of the coins in the pool.
     * @param Ann The amplitude coefficient multiplied by the number of coins in the pool (A * N_COINS).
     * @return D  The StableSwap invariant
     */
    function _getD(uint256[N_COINS] memory xp, uint256 Ann) internal pure returns (uint256 D) {
        uint256 S = xp[0] + xp[1];

        // Do these multiplications here rather than in each loop
        uint256 xp0 = xp[0] * N_COINS;
        uint256 xp1 = xp[1] * N_COINS;

        uint256 Dprev = 0;
        D = S;
        uint256 D_P;
        for (uint256 i = 0; i < 255; ) {
            // D_P: uint256 = D
            // for _x in xp:
            //     D_P = D_P * D / (_x * N_COINS)  # If division by 0, this will be borked: only withdrawal will work. And that is good
            D_P = ((((D * D) / xp0) * D) / xp1);

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
     * @notice Uses Newton’s Method to iteratively solve the required balance of a coin to maintain StableSwap invariant (D).
     * @dev This is a port of Curve's Vyper implementation with some gas optimizations.
     * Curve's implementation is `get_y_D` in https://etherscan.io/address/0x8474ddbe98f5aa3179b3b3f5942d724afcdec9f6#code
     *
     * @param xp  The scaled balances of the coins in the pool.
     * @param Ann The amplitude coefficient multiplied by the number of coins in the pool (A * N_COINS).
     * @param coinIndex The index of the coin in the metapool. 0 = eg musd, 1 = base coin, eg 3Crv.
     * @param D  The StableSwap invariant
     * @return y The required balance of coin at `coinIndex`.
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

// External
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Libs
import { AbstractSlippage } from "../AbstractSlippage.sol";
import { AbstractVault, IERC20 } from "../../AbstractVault.sol";
import { IConvexBooster } from "../../../peripheral/Convex/IConvexBooster.sol";
import { IConvexRewardsPool } from "../../../peripheral/Convex/IConvexRewardsPool.sol";
import { ICurveMetapool } from "../../../peripheral/Curve/ICurveMetapool.sol";
import { ICurve3Pool } from "../../../peripheral/Curve/ICurve3Pool.sol";
import { Curve3CrvMetapoolCalculatorLibrary } from "../../../peripheral/Curve/Curve3CrvMetapoolCalculatorLibrary.sol";

/**
 * @title   Abstract ERC-4626 vault with a Curve.fi 3pool (3Crv) asset invested in a Curve metapool,
 * deposited in a Convex pool and then staked.
 * @notice Curve.fi's 3pool DAI/USDC/USDT (3Crv) liquidity provider token is deposited in
 * a Curve.fi metapool to get a Curve.fi metapool LP token, eg musd3CRV,
 * which is deposited into a Convex Curve LP pool, eg cvxmusd3CRV, and finally the
 * Convex LP token is staked for rewards.
 *
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-06
 *
 * The constructor of implementing contracts need to call the following:
 * - VaultManagerRole(_nexus)
 * - AbstractSlippage(_slippageData)
 * - AbstractVault(_assetArg)
 * - Convex3CrvAbstractVault(_curveMetapool, _booster, _poolId)
 *
 * The `initialize` function of implementing contracts need to call the following:
 * - InitializableToken._initialize(_name, _symbol, decimals)
 * - VaultManagerRole._initialize(_vaultManager)
 * - Convex3CrvAbstractVault._initialize()
 */
abstract contract Convex3CrvAbstractVault is AbstractSlippage, AbstractVault {
    using SafeERC20 for IERC20;

    // Initial arguments to pass to constructor in a struct to avaoid stackTooDeep compilation error
    /// @param metapool           Curve.fi's metapool the asset, eg 3Crv, is deposited into. eg musd3CRV, MIM-3LP3CRV-f or usdp3CRV
    /// @param booster            Convex's Booster contract that contains the Curve.fi LP pools.
    /// @param convexPoolId       Convex's pool identifier. eg 14 for the musd3CRV pool.
    struct ConstructorData {
        address metapool;
        address booster;
        uint256 convexPoolId;
    }

    /// @notice 3CRV token scale
    uint256 public constant ASSET_SCALE = 1e18;
    uint256 public constant VIRTUAL_PRICE_SCALE = 1e18;

    /// @notice Curve.fi pool the 3Crv asset is deposited into. eg musd3CRV, MIM-3LP3CRV-f or usdp3CRV.
    address public immutable metapool;
    /// @notice Curve.fi Metapool liquidity provider token. eg Curve.fi MUSD/3Crv (musd3CRV)
    address public immutable metapoolToken;
    /// @notice Scale of the metapool liquidity provider token. eg 1e18 if 18 decimal places.
    uint256 public immutable metapoolTokenScale;
    /// @notice Curve's 3Pool used as a base pool by the Curve metapools.
    address public immutable basePool;

    /// @notice Convex's Booster contract that contains the Curve.fi LP pools.
    IConvexBooster public immutable booster;
    /// @notice Convex's pool identifier. eg 14 for the musd3CRV pool.
    uint256 public immutable convexPoolId;
    /// @notice Convex's base rewards contract for staking Convex's LP token. eg staking cvxmusd3CRV
    IConvexRewardsPool public immutable baseRewardPool;

    /// @param _data Contract immutable config of type `ConstructorData`.
    constructor(ConstructorData memory _data) {
        // Convex contracts
        booster = IConvexBooster(_data.booster);
        convexPoolId = _data.convexPoolId;
        (address metapoolTokenAddress, , , address baseRewardPoolAddress, , ) = IConvexBooster(
            _data.booster
        ).poolInfo(_data.convexPoolId);
        metapoolToken = metapoolTokenAddress;
        metapoolTokenScale = 10**IERC20Metadata(metapoolTokenAddress).decimals();
        baseRewardPool = IConvexRewardsPool(baseRewardPoolAddress);

        metapool = _data.metapool;
        basePool = Curve3CrvMetapoolCalculatorLibrary.BASE_POOL;
    }

    /// @dev Set Allowances for threeCrvToken and _asset
    function _initialize() internal virtual {
        _resetAllowances();

        // Check the base token in the Curve.fi metapool matches the vault asset.
        // Need to check here as the _asset is set in the AbstractVault constructor hence not
        // available in this abstract contract's constructor.
        require(ICurveMetapool(metapool).coins(1) == address(_asset), "Asset != Curve base coin");
    }

    /***************************************
                    Valuations
    ****************************************/

    /**
     * @notice Uses the Curve 3Pool and Metapool virtual prices to calculate the value of
     * the vault's assets (3Crv) from the staked Metapool LP tokens, eg musd3Crv, in the Convex pool.
     * This does not include slippage or fees.
     * @return totalManagedAssets Value of all the assets (3Crv) in the vault.
     */
    function totalAssets() public view override returns (uint256 totalManagedAssets) {
        uint256 totalMetapoolTokens = baseRewardPool.balanceOf(address(this));
        totalManagedAssets = Curve3CrvMetapoolCalculatorLibrary.convertToBaseLp(
            metapool,
            metapoolToken,
            totalMetapoolTokens
        );
    }

    /*///////////////////////////////////////////////////////////////
                        DEPOSIT/MINT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Overloaded standard ERC-4626 `deposit` method with custom slippage.
     * @param assets The amount of underlying assets to be transferred to the vault.
     * @param receiver The account that the vault shares will be minted to.
     * @param customDepositSlippage Deposit slippage in basis points i.e. 1% = 100.
     * @return shares The amount of vault shares that were minted.
     */
    function deposit(
        uint256 assets,
        address receiver,
        uint256 customDepositSlippage
    ) external virtual whenNotPaused returns (uint256 shares) {
        shares = _depositInternal(assets, receiver, customDepositSlippage);
    }

    /// @dev Override `AbstractVault._deposit`.
    function _deposit(uint256 assets, address receiver)
        internal
        virtual
        override
        returns (uint256 shares)
    {
        shares = _depositInternal(assets, receiver, depositSlippage);
    }

    /// @dev Vault assets (3Crv) -> Metapool LP tokens, eg musd3Crv -> vault shares
    function _depositInternal(
        uint256 _assets,
        address _receiver,
        uint256 _slippage
    ) internal virtual returns (uint256 shares) {
        // Transfer vault's asssets (3Crv) from the caller.
        _asset.safeTransferFrom(msg.sender, address(this), _assets);

        // Get this vault's balance of Metapool LP tokens, eg musd3Crv.
        // Used to calculate the proportion of shares that should be minted.
        uint256 totalMetapoolTokensBefore = baseRewardPool.balanceOf(address(this));

        // Calculate fair amount of metapool LP tokens, eg musd3Crv, using virtual prices for vault assets (3Crv)
        uint256 minMetapoolTokens = _getMetapoolTokensForAssets(_assets);
        // Calculate min amount of metapool LP tokens with max slippage
        // This is used for sandwich attack protection
        minMetapoolTokens = (minMetapoolTokens * (BASIS_SCALE - _slippage)) / BASIS_SCALE;

        // Deposit 3Crv into metapool and the stake into Convex vault
        uint256 metapoolTokensReceived = _depositAndStake(_assets, minMetapoolTokens);

        // Calculate the proportion of shares to mint based on the amount of Metapool LP tokens.
        shares = _getSharesFromMetapoolTokens(
            metapoolTokensReceived,
            totalMetapoolTokensBefore,
            totalSupply()
        );

        _mint(_receiver, shares);

        emit Deposit(msg.sender, _receiver, _assets, shares);
    }

    /// @dev Converts vault assets to shares in two steps
    /// Vault assets (3Crv) -> Metapool LP tokens, eg musd3Crv -> vault shares
    /// Override `AbstractVault._previewDeposit`.
    function _previewDeposit(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        if (assets > 0) {
            // Calculate Metapool LP tokens, eg musd3Crv, for vault assets (3Crv)
            (uint256 metapoolTokens, , , ) = Curve3CrvMetapoolCalculatorLibrary.calcDeposit(
                metapool,
                metapoolToken,
                assets,
                1
            );

            // Calculate the proportion of shares to mint based on the amount of metapool LP tokens, eg musd3Crv.
            shares = _getSharesFromMetapoolTokens(
                metapoolTokens,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );
        }
    }

    /// @dev Override `AbstractVault._mint`.
    /// Vault shares -> Metapool LP tokens, eg musd3Crv -> vault assets (3Crv)
    function _mint(uint256 shares, address receiver)
        internal
        virtual
        override
        returns (uint256 assets)
    {
        // Calculate Curve Metapool LP tokens, eg musd3CRV, needed to mint the required amount of shares
        uint256 requiredMetapoolTokens = _getMetapoolTokensFromShares(
            shares,
            baseRewardPool.balanceOf(address(this)),
            totalSupply()
        );

        // Calculate assets needed to deposit into the metapool for the for required metapool lp tokens.
        uint256 invariant;
        uint256 metapoolTotalSupply;
        uint256 baseVirtualPrice;
        (
            assets,
            invariant,
            metapoolTotalSupply,
            baseVirtualPrice
        ) = Curve3CrvMetapoolCalculatorLibrary.calcMint(
            metapool,
            metapoolToken,
            requiredMetapoolTokens,
            1
        );
        // Protect against sandwich and flash loan attacks where the balance of the metapool is manipulated.
        uint256 maxAssets = (requiredMetapoolTokens * invariant * VIRTUAL_PRICE_SCALE) /
            (metapoolTotalSupply * baseVirtualPrice);
        maxAssets = (maxAssets * (BASIS_SCALE + mintSlippage)) / BASIS_SCALE;
        require(assets <= maxAssets, "too much slippage");

        // Transfer vault's asssets (3Crv) from the caller.
        _asset.safeTransferFrom(msg.sender, address(this), assets);

        // Deposit 3Crv into metapool and the stake into Convex vault
        _depositAndStake(assets, requiredMetapoolTokens);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @dev Converts vault shares to assets in two steps
    /// Vault shares -> Metapool LP tokens, eg musd3Crv -> vault assets (3Crv)
    /// Override `AbstractVault._previewMint`.
    function _previewMint(uint256 shares) internal view virtual override returns (uint256 assets) {
        if (shares > 0) {
            uint256 metapoolTokens = _getMetapoolTokensFromShares(
                shares,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );
            (assets, , , ) = Curve3CrvMetapoolCalculatorLibrary.calcMint(
                metapool,
                metapoolToken,
                metapoolTokens,
                1
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                        WITHDRAW/REDEEM
    //////////////////////////////////////////////////////////////*/

    /// @dev Override `AbstractVault._withdraw`.
    /// Vault assets (3Crv) -> Metapool LP tokens, eg musd3Crv -> vault shares
    function _withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) internal virtual override returns (uint256 shares) {
        if (assets > 0) {
            (
                uint256 metapoolTokensRequired,
                uint256 invariant,
                uint256 metapoolTotalSupply,
                uint256 baseVirtualPrice
            ) = Curve3CrvMetapoolCalculatorLibrary.calcWithdraw(metapool, metapoolToken, assets, 1);

            // Calculate max metapool tokens using virtual prices
            // This protects against sandwich and flash loan attacks against the the Curve metapool.
            uint256 maxMetapoolTokens = (assets * baseVirtualPrice * metapoolTotalSupply) /
                (invariant * VIRTUAL_PRICE_SCALE);
            maxMetapoolTokens =
                (maxMetapoolTokens * (BASIS_SCALE + withdrawSlippage)) /
                BASIS_SCALE;
            require(metapoolTokensRequired <= maxMetapoolTokens, "too much slippage");

            shares = _getSharesFromMetapoolTokens(
                metapoolTokensRequired,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );

            // If caller is not the owner of the shares
            uint256 allowed = allowance(owner, msg.sender);
            if (msg.sender != owner && allowed != type(uint256).max) {
                require(shares <= allowed, "Amount exceeds allowance");
                _approve(owner, msg.sender, allowed - shares);
            }

            // Withdraw metapool lp tokens from Convex pool
            // don't claim rewards.
            baseRewardPool.withdrawAndUnwrap(metapoolTokensRequired, false);

            // Remove assets (3Crv) from the Curve metapool by burning the LP tokens, eg musd3Crv
            ICurveMetapool(metapool).remove_liquidity_imbalance(
                [0, assets],
                metapoolTokensRequired
            );

            _burn(owner, shares);

            _asset.safeTransfer(receiver, assets);

            emit Withdraw(msg.sender, receiver, owner, assets, shares);
        }
    }

    /// @dev Override `AbstractVault._previewWithdraw`.
    function _previewWithdraw(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        if (assets > 0) {
            (uint256 metapoolTokens, , , ) = Curve3CrvMetapoolCalculatorLibrary.calcWithdraw(
                metapool,
                metapoolToken,
                assets,
                1
            );

            shares = _getSharesFromMetapoolTokens(
                metapoolTokens,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );
        }
    }

    /**
     * @notice Overloaded standard ERC-4626 `redeem` method with custom slippage.
     * @param shares The amount of vault shares to be burnt.
     * @param receiver The account the underlying assets will be transferred to.
     * @param owner The account that owns the vault shares to be burnt.
     * @param customRedeemSlippage Redeem slippage in basis points i.e. 1% = 100.
     * @return assets The amount of underlying assets that were transferred to the receiver.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner,
        uint256 customRedeemSlippage
    ) external virtual whenNotPaused returns (uint256 assets) {
        assets = _redeemInternal(shares, receiver, owner, customRedeemSlippage);
    }

    /// @dev Override `AbstractVault._redeem`.
    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual override returns (uint256 assets) {
        assets = _redeemInternal(shares, receiver, owner, redeemSlippage);
    }

    /// @dev Vault shares -> Metapool LP tokens, eg musd3Crv -> vault assets (3Crv)
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

            // Calculate Curve Metapool LP tokens, eg musd3CRV, needed to mint the required amount of shares
            uint256 totalMetapoolTokens = baseRewardPool.balanceOf(address(this));
            uint256 requiredMetapoolTokens = _getMetapoolTokensFromShares(
                _shares,
                totalMetapoolTokens,
                totalSupply()
            );

            // Calculate fair amount of assets (3Crv) using virtual prices for metapool LP tokens, eg musd3Crv
            uint256 minAssets = _getAssetsForMetapoolTokens(requiredMetapoolTokens);
            // Calculate min amount of assets (3Crv) with max slippage.
            // This is used for sandwich attack protection.
            minAssets = (minAssets * (BASIS_SCALE - _slippage)) / BASIS_SCALE;

            // Withdraw metapool lp tokens from Convex pool
            // don't claim rewards.
            baseRewardPool.withdrawAndUnwrap(requiredMetapoolTokens, false);

            // Remove assets (3Crv) from the Curve metapool by burning the LP tokens, eg musd3Crv
            assets = ICurveMetapool(metapool).remove_liquidity_one_coin(
                requiredMetapoolTokens,
                1,
                minAssets
            );

            _burn(_owner, _shares);

            _asset.safeTransfer(_receiver, assets);

            emit Withdraw(msg.sender, _receiver, _owner, assets, _shares);
        }
    }

    /// @dev Override `AbstractVault._previewRedeem`.
    /// Vault shares -> Metapool LP tokens, eg musd3Crv -> vault assets (3Crv)
    function _previewRedeem(uint256 shares)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        if (shares > 0) {
            uint256 metapoolTokens = _getMetapoolTokensFromShares(
                shares,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );
            (assets, , ) = Curve3CrvMetapoolCalculatorLibrary.calcRedeem(
                metapool,
                metapoolToken,
                metapoolTokens,
                1
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            CONVERTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Override `AbstractVault._convertToAssets`.
    function _convertToAssets(uint256 shares)
        internal
        view
        virtual
        override
        returns (uint256 assets)
    {
        if (shares > 0) {
            uint256 metapoolTokens = _getMetapoolTokensFromShares(
                shares,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );
            assets = Curve3CrvMetapoolCalculatorLibrary.convertToBaseLp(
                metapool,
                metapoolToken,
                metapoolTokens
            );
        }
    }

    /// @dev Override `AbstractVault._convertToShares`.
    function _convertToShares(uint256 assets)
        internal
        view
        virtual
        override
        returns (uint256 shares)
    {
        if (assets > 0) {
            uint256 metapoolTokens = Curve3CrvMetapoolCalculatorLibrary.convertToMetaLp(
                metapool,
                metapoolToken,
                assets
            );
            shares = _getSharesFromMetapoolTokens(
                metapoolTokens,
                baseRewardPool.balanceOf(address(this)),
                totalSupply()
            );
        }
    }

    /***************************************
                    Utility
    ****************************************/

    /// @dev Add assets (3Crv) to the Curve metapool and
    /// deposit the received metapool lp tokens, eg musd3Crv, into a Convex pool.
    function _depositAndStake(uint256 _assets, uint256 _minMetapoolTokens)
        internal
        returns (uint256 metapoolTokens_)
    {
        // Deposit assets, eg 3Crv, into the Curve.fi Metapool pool.
        metapoolTokens_ = ICurveMetapool(metapool).add_liquidity([0, _assets], _minMetapoolTokens);

        // Deposit Curve.fi Metapool LP token, eg musd3CRV, in Convex pool, eg cvxmusd3CRV, and stake.
        booster.deposit(convexPoolId, metapoolTokens_, true);
    }

    /// @dev Utility function to convert Curve Metapool LP tokens, eg musd3Crv, to expected 3Pool LP tokens (3Crv).
    /// @param _metapoolTokens Amount of Curve Metapool LP tokens. eg musd3Crv
    /// @return expectedAssets Expected amount of 3Pool (3Crv) LP tokens.
    function _getAssetsForMetapoolTokens(uint256 _metapoolTokens)
        internal
        view
        returns (uint256 expectedAssets)
    {
        // 3Crv virtual price in USD. Non-manipulable
        uint256 threePoolVirtualPrice = ICurve3Pool(basePool).get_virtual_price();
        // Metapool virtual price in USD. eg musd3Crv/USD
        uint256 metapoolVirtualPrice = ICurveMetapool(metapool).get_virtual_price();

        // Amount of "asset" (3Crv) tokens corresponding to Curve Metapool LP tokens
        // = musd3Crv/USD price * musd3Crv amount * 3Crv scale / (3Crv/USD price * musd3Crv scale)
        expectedAssets =
            (metapoolVirtualPrice * _metapoolTokens * ASSET_SCALE) /
            (threePoolVirtualPrice * metapoolTokenScale);
    }

    /// @dev Utility function to convert 3Pool (3Crv) LP tokens to expected Curve Metapool LP tokens (musd3Crv).
    /// @param _assetsAmount Amount of 3Pool (3Crv) LP tokens.
    /// @return expectedMetapoolTokens Amount of Curve Metapool tokens (musd3Crv) expected from curve.
    function _getMetapoolTokensForAssets(uint256 _assetsAmount)
        internal
        view
        returns (uint256 expectedMetapoolTokens)
    {
        // 3Crv virtual price in USD. Non-manipulable
        uint256 threePoolVirtualPrice = ICurve3Pool(basePool).get_virtual_price();
        // Metapool virtual price in USD
        uint256 metapoolVirtualPrice = ICurveMetapool(metapool).get_virtual_price();

        // Amount of Curve Metapool LP tokens corresponding to assets (3Crv)
        expectedMetapoolTokens =
            (threePoolVirtualPrice * _assetsAmount * metapoolTokenScale) /
            (metapoolVirtualPrice * ASSET_SCALE);
    }

    function _getSharesFromMetapoolTokens(
        uint256 _metapoolTokens,
        uint256 _totalMetapoolTokens,
        uint256 _totalShares
    ) internal pure returns (uint256 shares) {
        if (_totalMetapoolTokens == 0) {
            shares = _metapoolTokens;
        } else {
            shares = (_metapoolTokens * _totalShares) / _totalMetapoolTokens;
        }
    }

    function _getMetapoolTokensFromShares(
        uint256 _shares,
        uint256 _totalMetapoolTokens,
        uint256 _totalShares
    ) internal pure returns (uint256 metapoolTokens) {
        if (_totalShares == 0) {
            metapoolTokens = _shares;
        } else {
            metapoolTokens = (_shares * _totalMetapoolTokens) / _totalShares;
        }
    }

    /***************************************
                    Emergency Functions
    ****************************************/

    /**
     * @notice Governor liquidates all the vault's assets and send to the governor.
     * Only to be used in an emergency. eg whitehat protection against a hack.
     * The governor is the Protocol DAO's multisig wallet so can not be executed by one person.
     * @param minAssets Minimum amount of asset tokens (3Crv) to receive from removing liquidity from the Curve Metapool.
     * This provides sandwich attack protection.
     */
    function liquidateVault(uint256 minAssets) external onlyGovernor {
        uint256 totalMetapoolTokens = baseRewardPool.balanceOf(address(this));

        baseRewardPool.withdrawAndUnwrap(totalMetapoolTokens, false);
        ICurveMetapool(metapool).remove_liquidity_one_coin(totalMetapoolTokens, 1, minAssets);

        _asset.safeTransfer(_governor(), _asset.balanceOf(address(this)));
    }

    /***************************************
                    Set Vault Parameters
    ****************************************/

    /// @notice Function to reset allowances in the case they get exhausted
    function resetAllowances() external onlyGovernor {
        _resetAllowances();
    }

    function _resetAllowances() internal {
        // Approve the Curve.fi metapool, eg musd3CRV, to transfer the asset 3Crv.
        _asset.safeApprove(address(metapool), 0);
        _asset.safeApprove(address(metapool), type(uint256).max);
        // Approve the Convex booster contract to transfer the Curve.fi metapool LP token. eg musd3CRV
        IERC20(metapoolToken).safeApprove(address(booster), 0);
        IERC20(metapoolToken).safeApprove(address(booster), type(uint256).max);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @title   Interface that the Liquidator uses to interact with vaults.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-05-11
 */
interface ILiquidatorVault {
    /**
     * @notice Used by the liquidator to collect rewards from the vault's underlying platforms
     * or vaults into the vault contract.
     * The liquidator will transfer the collected rewards from the vault to the liquidator separately
     * to the `collectRewards` call.
     *
     * @param rewardTokens Array of reward tokens that were collected.
     * @param rewards The amount of reward tokens that were collected.
     * @param purchaseTokens The token to purchase for each of the rewards.
     */
    function collectRewards()
        external
        returns (
            address[] memory rewardTokens,
            uint256[] memory rewards,
            address[] memory purchaseTokens
        );

    /**
     * @notice Adds assets to a vault which decides what to do with the extra tokens.
     * If the tokens are the vault's asset, the simplest is for the vault to just add
     * to the other assets without minting any shares.
     * This has the effect of increasing the vault's assets per share.
     * This can be a problem if there is a relatively large amount of assets being donated as it can be sandwich attacked.
     * The attacker can mint a large amount of shares before the donation and then redeem them afterwards taking most of the donated assets.
     * This can be avoided by streaming the increase of assets per share over time. For example,
     * minting new shares and then burning them over a period of time. eg one day.
     *
     * @param token The address of the tokens being donated.
     * @param amount The amount of tokens being donated.
     */
    function donate(address token, uint256 amount) external;

    /**
     * @notice Returns all reward token addresses added to the vault.
     */
    function rewardTokens() external view returns (address[] memory rewardTokens);

    /**
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     * @param rewardToken The address of the reward token.
     * @return token The address of the tokens being donated.
     */
    function donateToken(address rewardToken) external view returns (address token);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

interface IConvexRewardsPool {
    function balanceOf(address account) external view returns (uint256);

    function currentRewards() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function rewards(address) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

/**
 * @notice Generated from Convex's Booster contract on mainnet.
 * https://etherscan.io/address/0xF403C135812408BFbE8713b5A23a04b3D48AAE31
 *
 * mUSD Pool Id (pid) is 14
 * lptoken    : 0x1AEf73d49Dedc4b1778d0706583995958Dc862e6 : Curve LP Token          : Curve.fi MUSD/3Crv (musd3CRV)
 * token      : 0xd34d466233c5195193dF712936049729140DBBd7 : DepositToken            : Curve.fi MUSD/3Crv Convex Deposit (cvxmusd3CRV)
 * gauge      : 0x5f626c30EC1215f4EdCc9982265E8b1F411D1352 : Staking Liquidity Gauge : Curve.fi: MUSD Liquidity Gauge
 * crvRewards : 0xDBFa6187C79f4fE4Cda20609E75760C5AaE88e52 : BaseRewardPool          : Convex staking contract for cvxmusd3CRV for rewards
 * stash      : 0x2eEa402ff31c580630b8545A33EDc00881E6949c : ExtraRewardStashV1      : Convex staking contract for cvxmusd3CRV for extra rewards
 */
interface IConvexBooster {
    function claimRewards(uint256 _pid, address _gauge) external returns (bool);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function poolInfo(uint256 _pid)
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function rewardClaimed(
        uint256 _pid,
        address _address,
        uint256 _amount
    ) external returns (bool);

    function vote(
        uint256 _voteId,
        address _votingAddress,
        bool _support
    ) external returns (bool);

    function voteDelegate() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawTo(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external returns (bool);
}