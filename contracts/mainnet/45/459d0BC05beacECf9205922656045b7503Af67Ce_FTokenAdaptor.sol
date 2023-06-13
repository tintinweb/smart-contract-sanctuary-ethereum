// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { BaseAdaptor, ERC20, SafeTransferLib, Cellar, PriceRouter, Math } from "src/modules/adaptors/BaseAdaptor.sol";
import { IFToken } from "src/interfaces/external/Frax/IFToken.sol";

/**
 * @title FraxLend fToken Adaptor
 * @dev This adaptor is specifically for FraxLendPairV2 contracts.
 *      To interact with a different version, inherit from this adaptor
 *      and overrid the interface helper functions.
 * @notice Allows Cellars to lend FRAX to FraxLend pairs.
 * @author crispymangoes, 0xEinCodes
 */
contract FTokenAdaptor is BaseAdaptor {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    //==================== Adaptor Data Specification ====================
    // adaptorData = abi.encode(address fToken)
    // Where:
    // `fToken` is the fToken address position this adaptor is working with.
    //================= Configuration Data Specification =================
    // NA
    //====================================================================

    /**
     * @notice Attempted to interact with an fToken the Cellar is not using.
     */
    error FTokenAdaptor__FTokenPositionsMustBeTracked(address fToken);

    //============================================ Global Functions ===========================================
    /**
     * @dev Identifier unique to this adaptor for a shared registry.
     * Normally the identifier would just be the address of this contract, but this
     * Identifier is needed during Cellar Delegate Call Operations, so getting the address
     * of the adaptor is more difficult.
     */
    function identifier() public pure virtual override returns (bytes32) {
        return keccak256(abi.encode("FraxLend fToken Adaptor V 0.0"));
    }

    /**
     * @notice The FRAX contract on Ethereum Mainnet.
     */
    function FRAX() internal pure returns (ERC20) {
        return ERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    }

    /**
     * @notice Indicates whether or not we should worry about updating interest
     *         when interacting with FraxLend.
     * @dev True is the most accurate method, but will slightly add to gas costs.
     *      False is less accurate, but this error is mitigated by the frequency the
     *      FraxLend Pairs are interacted with.
     */
    function ACCOUNT_FOR_INTEREST() internal pure virtual returns (bool) {
        return true;
    }

    //============================================ Implement Base Functions ===========================================
    /**
     * @notice Cellar must approve fToken to spend its assets, then call deposit to lend its assets.
     * @param assets the amount of assets to lend on FraxLend
     * @param adaptorData adaptor data containing the abi encoded fToken
     * @dev configurationData is NOT used
     */
    function deposit(uint256 assets, bytes memory adaptorData, bytes memory) public override {
        // Deposit assets to Frax Lend.
        IFToken fToken = abi.decode(adaptorData, (IFToken));
        FRAX().safeApprove(address(fToken), assets);
        _deposit(fToken, assets, address(this));

        // Zero out approvals if necessary.
        _revokeExternalApproval(FRAX(), address(fToken));
    }

    /**
     * @notice Cellars must withdraw from FraxLend, then transfer assets to receiver.
     * @dev Important to verify that external receivers are allowed if receiver is not Cellar address.
     * @param assets the amount of assets to withdraw from FraxLend
     * @param receiver the address to send withdrawn assets to
     * @param adaptorData adaptor data containing the abi encoded fToken
     * @dev configurationData is NOT used
     */
    function withdraw(uint256 assets, address receiver, bytes memory adaptorData, bytes memory) public override {
        // Run external receiver check.
        _externalReceiverCheck(receiver);

        // Withdraw assets from Frax.
        IFToken fToken = abi.decode(adaptorData, (IFToken));
        _withdraw(fToken, assets, receiver, address(this));
    }

    /**
     * @notice Returns the amount of FRAX that can be withdrawn.
     * @dev Compares FRAX supplied to FRAX borrowed to check for liquidity.
     *      - If FRAX balance is greater than liquidity available, it returns the amount available.
     */
    function withdrawableFrom(
        bytes memory adaptorData,
        bytes memory
    ) public view override returns (uint256 withdrawableFrax) {
        IFToken fToken = abi.decode(adaptorData, (IFToken));
        (uint128 totalFraxSupplied, , uint128 totalFraxBorrowed, , ) = _getPairAccounting(fToken);
        if (totalFraxBorrowed >= totalFraxSupplied) return 0;
        uint256 liquidFrax = totalFraxSupplied - totalFraxBorrowed;
        uint256 fraxBalance = _toAssetAmount(fToken, _balanceOf(fToken, msg.sender), false, ACCOUNT_FOR_INTEREST());
        withdrawableFrax = fraxBalance > liquidFrax ? liquidFrax : fraxBalance;
    }

    /**
     * @notice Returns the cellar's balance of the FRAX position.
     */
    function balanceOf(bytes memory adaptorData) public view override returns (uint256) {
        IFToken fToken = abi.decode(adaptorData, (IFToken));
        return _toAssetAmount(fToken, _balanceOf(fToken, msg.sender), false, ACCOUNT_FOR_INTEREST());
    }

    /**
     * @notice Returns FRAX.
     */
    function assetOf(bytes memory) public pure override returns (ERC20) {
        return FRAX();
    }

    /**
     * @notice This adaptor returns collateral, and not debt.
     */
    function isDebt() public pure override returns (bool) {
        return false;
    }

    //============================================ Strategist Functions ===========================================
    /**
     * @notice Allows strategists to lend FRAX on FraxLend.
     * @dev Uses `_maxAvailable` helper function, see BaseAdaptor.sol
     * @param fToken the specified FraxLend Pair
     * @param amountToDeposit the amount of Frax to lend on FraxLend
     */
    function lendFrax(IFToken fToken, uint256 amountToDeposit) public {
        _validateFToken(fToken);
        amountToDeposit = _maxAvailable(FRAX(), amountToDeposit);
        FRAX().safeApprove(address(fToken), amountToDeposit);
        _deposit(fToken, amountToDeposit, address(this));

        // Zero out approvals if necessary.
        _revokeExternalApproval(FRAX(), address(fToken));
    }

    /**
     * @notice Allows strategists to redeem Frax shares from FraxLend.
     * @param fToken the specified FraxLend Pair
     * @param amountToRedeem the amount of Frax shares to redeem from FraxLend
     */
    function redeemFraxShare(IFToken fToken, uint256 amountToRedeem) public {
        _validateFToken(fToken);
        amountToRedeem = _maxAvailable(ERC20(address(fToken)), amountToRedeem);

        _redeem(fToken, amountToRedeem, address(this), address(this));
    }

    /**
     * @notice Allows strategists to withdraw FRAX from FraxLend.
     * @dev Used to withdraw an exact amount from Frax Lend.
     *      Use `redeemFraxShare` to withdraw all.
     * @param fToken the specified FraxLend Pair
     * @param amountToWithdraw the amount of FRAX to withdraw from FraxLend
     */
    function withdrawFrax(IFToken fToken, uint256 amountToWithdraw) public {
        _validateFToken(fToken);
        _withdraw(fToken, amountToWithdraw, address(this), address(this));
    }

    /**
     * @notice Allows a strategist to call `addInterest` on a Frax Pair they are using.
     * @dev A strategist might want to do this if a Frax Lend pair has not been interacted
     *      in a while, and the strategist does not plan on interacting with it during a
     *      rebalance.
     * @dev Calling this can increase the share price during the rebalance,
     *      so a strategist should consider moving some assets into reserves.
     */
    function callAddInterest(IFToken fToken) public {
        _validateFToken(fToken);
        _addInterest(fToken);
    }

    /**
     * @notice Validates that a given fToken is set up as a position in the Cellar.
     * @dev This function uses `address(this)` as the address of the Cellar.
     */
    function _validateFToken(IFToken fToken) internal view {
        bytes32 positionHash = keccak256(abi.encode(identifier(), false, abi.encode(address(fToken))));
        uint32 positionId = Cellar(address(this)).registry().getPositionHashToPositionId(positionHash);
        if (!Cellar(address(this)).isPositionUsed(positionId))
            revert FTokenAdaptor__FTokenPositionsMustBeTracked(address(fToken));
    }

    //============================================ Interface Helper Functions ===========================================

    //============================== Interface Details ==============================
    // The Frax Pair interface can slightly change between versions.
    // To account for this, FTokenAdaptors will use the below internal functions when
    // interacting with Frax Pairs, this way new pairs can be added by creating a
    // new contract that inherits from this one, and overrides any function it needs
    // so it conforms with the new Frax Pair interface.

    // Current versions in use for `FraxLendPair` include v1 and v2.

    // IMPORTANT: This `FTokenAdaptor.sol` is associated to the v2 version of `FraxLendPair`
    // whereas FTokenAdaptorV1 is actually associated to `FraxLendPairv1`.
    // The reasoning to name it like this was to set up the base FTokenAdaptor for the
    // most current version, v2. This is in anticipation that more FraxLendPairs will
    // be deployed following v2 in the near future. When later versions are deployed,
    // then the described inheritance pattern above will be used.
    //===============================================================================

    /**
     * @notice Deposit $FRAX into specified 'v2' FraxLendPair
     * @dev ftoken.deposit() calls into the respective version (v2 by default) of FraxLendPair
     * @param fToken The specified FraxLendPair
     * @param amount The amount of $FRAX Token to transfer to Pair
     * @param receiver The address to receive the Asset Shares (fTokens)
     */
    function _deposit(IFToken fToken, uint256 amount, address receiver) internal virtual {
        fToken.deposit(amount, receiver);
    }

    /**
     * @notice Withdraw $FRAX from specified 'v2' FraxLendPair
     * @dev ftoken.withdraw() calls into the respective version (v2 by default) of FraxLendPair
     * @param fToken The specified FraxLendPair
     * @param assets The amount to withdraw
     * @param receiver The address to which the Asset Tokens will be transferred
     * @param owner The owner of the Asset Shares (fTokens)
     */
    function _withdraw(IFToken fToken, uint256 assets, address receiver, address owner) internal virtual {
        fToken.withdraw(assets, receiver, owner);
    }

    /**
     * @notice Caller redeems Asset Shares for Asset Tokens $FRAX from specified 'v2' FraxLendPair
     * @dev ftoken.redeem() calls into the respective version (v2 by default) of FraxLendPair
     * @param fToken The specified FraxLendPair
     * @param shares The number of Asset Shares (fTokens) to burn for Asset Tokens
     * @param receiver The address to which the Asset Tokens will be transferred
     * @param owner The owner of the Asset Shares (fTokens)
     */
    function _redeem(IFToken fToken, uint256 shares, address receiver, address owner) internal virtual {
        fToken.redeem(shares, receiver, owner);
    }

    /**
     * @notice Converts a given number of shares to $FRAX amount from specified 'v2' FraxLendPair
     * @dev This is one of the adjusted functions from v1 to v2. ftoken.toAssetAmount() calls into the respective version (v2 by default) of FraxLendPair
     * @param fToken The specified FraxLendPair
     * @param shares Shares of asset (fToken)
     * @param roundUp Whether to round up after division
     * @param previewInterest Whether to preview interest accrual before calculation
     */
    function _toAssetAmount(
        IFToken fToken,
        uint256 shares,
        bool roundUp,
        bool previewInterest
    ) internal view virtual returns (uint256) {
        return fToken.toAssetAmount(shares, roundUp, previewInterest);
    }

    /**
     * @notice Converts a given asset amount to a number of asset shares (fTokens) from specified 'v2' FraxLendPair
     * @dev This is one of the adjusted functions from v1 to v2. ftoken.toAssetShares() calls into the respective version (v2 by default) of FraxLendPair
     * @param fToken The specified FraxLendPair
     * @param amount The amount of asset
     * @param roundUp Whether to round up after division
     * @param previewInterest Whether to preview interest accrual before calculation
     */
    function _toAssetShares(
        IFToken fToken,
        uint256 amount,
        bool roundUp,
        bool previewInterest
    ) internal view virtual returns (uint256) {
        return fToken.toAssetShares(amount, roundUp, previewInterest);
    }

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function _balanceOf(IFToken fToken, address user) internal view virtual returns (uint256) {
        return fToken.balanceOf(user);
    }

    /**
     * @notice gets all pair level accounting numbers from specified 'v2' FraxLendPair
     * @param fToken The specified FraxLendPair
     * @return totalAssetAmount Total assets deposited and interest accrued, total claims
     * @return totalAssetShares Total fTokens
     * @return totalBorrowAmount Total borrows
     * @return totalBorrowShares Total borrow shares
     * @return totalCollateral Total collateral
     */
    function _getPairAccounting(
        IFToken fToken
    )
        internal
        view
        virtual
        returns (
            uint128 totalAssetAmount,
            uint128 totalAssetShares,
            uint128 totalBorrowAmount,
            uint128 totalBorrowShares,
            uint256 totalCollateral
        )
    {
        (totalAssetAmount, totalAssetShares, totalBorrowAmount, totalBorrowShares, totalCollateral) = fToken
            .getPairAccounting();
    }

    /**
     * @notice Caller calls `addInterest` on specified 'v2' FraxLendPair
     * @dev ftoken.addInterest() calls into the respective version (v2 by default) of FraxLendPair
     * @param fToken The specified FraxLendPair
     */
    function _addInterest(IFToken fToken) internal virtual {
        fToken.addInterest(false);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { ERC20, SafeTransferLib, Math } from "src/base/ERC4626.sol";
import { Registry } from "src/Registry.sol";
import { Cellar } from "src/base/Cellar.sol";
import { SwapRouter } from "src/modules/swap-router/SwapRouter.sol";
import { PriceRouter } from "src/modules/price-router/PriceRouter.sol";

/**
 * @title Base Adaptor
 * @notice Base contract all adaptors must inherit from.
 * @dev Allows Cellars to interact with arbritrary DeFi assets and protocols.
 * @author crispymangoes
 */
abstract contract BaseAdaptor {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /**
     * @notice Attempted to specify an external receiver during a Cellar `callOnAdaptor` call.
     */
    error BaseAdaptor__ExternalReceiverBlocked();

    /**
     * @notice Attempted to deposit to a position where user deposits were not allowed.
     */
    error BaseAdaptor__UserDepositsNotAllowed();

    /**
     * @notice Attempted to withdraw from a position where user withdraws were not allowed.
     */
    error BaseAdaptor__UserWithdrawsNotAllowed();

    /**
     * @notice Attempted swap has bad slippage.
     */
    error BaseAdaptor__Slippage();

    /**
     * @notice Attempted swap used unsupported output asset.
     */
    error BaseAdaptor__PricingNotSupported(address asset);

    //============================================ Global Functions ===========================================
    /**
     * @dev Identifier unique to this adaptor for a shared registry.
     * Normally the identifier would just be the address of this contract, but this
     * Identifier is needed during Cellar Delegate Call Operations, so getting the address
     * of the adaptor is more difficult.
     */
    function identifier() public pure virtual returns (bytes32) {
        return keccak256(abi.encode("Base Adaptor V 0.0"));
    }

    function SWAP_ROUTER_REGISTRY_SLOT() internal pure returns (uint256) {
        return 1;
    }

    function PRICE_ROUTER_REGISTRY_SLOT() internal pure returns (uint256) {
        return 2;
    }

    /**
     * @notice Max possible slippage when making a swap router swap.
     */
    function slippage() public pure returns (uint32) {
        return 0.9e4;
    }

    //============================================ Implement Base Functions ===========================================
    //==================== Base Function Specification ====================
    // Base functions are functions designed to help the Cellar interact with
    // an adaptor position, strategists are not intended to use these functions.
    // Base functions MUST be implemented in adaptor contracts, even if that is just
    // adding a revert statement to make them uncallable by normal user operations.
    //
    // All view Base functions will be called used normal staticcall.
    // All mutative Base functions will be called using delegatecall.
    //=====================================================================
    /**
     * @notice Function Cellars call to deposit users funds into holding position.
     * @param assets the amount of assets to deposit
     * @param adaptorData data needed to deposit into a position
     * @param configurationData data settable when strategists add positions to their Cellar
     *                          Allows strategist to control how the adaptor interacts with the position
     */
    function deposit(uint256 assets, bytes memory adaptorData, bytes memory configurationData) public virtual;

    /**
     * @notice Function Cellars call to withdraw funds from positions to send to users.
     * @param receiver the address that should receive withdrawn funds
     * @param adaptorData data needed to withdraw from a position
     * @param configurationData data settable when strategists add positions to their Cellar
     *                          Allows strategist to control how the adaptor interacts with the position
     */
    function withdraw(
        uint256 assets,
        address receiver,
        bytes memory adaptorData,
        bytes memory configurationData
    ) public virtual;

    /**
     * @notice Function Cellars use to determine `assetOf` balance of an adaptor position.
     * @param adaptorData data needed to interact with the position
     * @return balance of the position in terms of `assetOf`
     */
    function balanceOf(bytes memory adaptorData) public view virtual returns (uint256);

    /**
     * @notice Functions Cellars use to determine the withdrawable balance from an adaptor position.
     * @dev Debt positions MUST return 0 for their `withdrawableFrom`
     * @notice accepts adaptorData and configurationData
     * @return withdrawable balance of the position in terms of `assetOf`
     */
    function withdrawableFrom(bytes memory, bytes memory) public view virtual returns (uint256);

    /**
     * @notice Function Cellars use to determine the underlying ERC20 asset of a position.
     * @param adaptorData data needed to withdraw from a position
     * @return the underlying ERC20 asset of a position
     */
    function assetOf(bytes memory adaptorData) public view virtual returns (ERC20);

    /**
     * @notice When positions are added to the Registry, this function can be used in order to figure out
     *         what assets this adaptor needs to price, and confirm pricing is properly setup.
     */
    function assetsUsed(bytes memory adaptorData) public view virtual returns (ERC20[] memory assets) {
        assets = new ERC20[](1);
        assets[0] = assetOf(adaptorData);
    }

    /**
     * @notice Functions Registry/Cellars use to determine if this adaptor reports debt values.
     * @dev returns true if this adaptor reports debt values.
     */
    function isDebt() public view virtual returns (bool);

    //============================================ Strategist Functions ===========================================
    //==================== Strategist Function Specification ====================
    // Strategist functions are only callable by strategists through the Cellars
    // `callOnAdaptor` function. A cellar will never call any of these functions,
    // when a normal user interacts with a cellar(depositing/withdrawing)
    //
    // All strategist functions will be called using delegatecall.
    // Strategist functions are intentionally "blind" to what positions the cellar
    // is currently holding. This allows strategists to enter temporary positions
    // while rebalancing.
    // To mitigate strategist from abusing this and moving funds in untracked
    // positions, the cellar will enforce a Total Value Locked check that
    // insures TVL has not deviated too much from `callOnAdaptor`.
    //===========================================================================

    //============================================ Helper Functions ===========================================
    /**
     * @notice Helper function that allows adaptor calls to use the max available of an ERC20 asset
     * by passing in type(uint256).max
     * @param token the ERC20 asset to work with
     * @param amount when `type(uint256).max` is used, this function returns `token`s `balanceOf`
     * otherwise this function returns amount.
     */
    function _maxAvailable(ERC20 token, uint256 amount) internal view virtual returns (uint256) {
        if (amount == type(uint256).max) return token.balanceOf(address(this));
        else return amount;
    }

    /**
     * @notice Helper function that checks if `spender` has any more approval for `asset`, and if so revokes it.
     */
    function _revokeExternalApproval(ERC20 asset, address spender) internal {
        if (asset.allowance(address(this), spender) > 0) asset.safeApprove(spender, 0);
    }

    /**
     * @notice Helper function that validates external receivers are allowed.
     */
    function _externalReceiverCheck(address receiver) internal view {
        if (receiver != address(this) && Cellar(address(this)).blockExternalReceiver())
            revert BaseAdaptor__ExternalReceiverBlocked();
    }

    /**
     * @notice Allows strategists to zero out an approval for a given `asset`.
     * @param asset the ERC20 asset to revoke `spender`s approval for
     * @param spender the address to revoke approval for
     */
    function revokeApproval(ERC20 asset, address spender) public {
        asset.safeApprove(spender, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFToken {
    // Frax Pair V1 interface.
    // Example Pair: https://etherscan.io/address/0xDbe88DBAc39263c47629ebbA02b3eF4cf0752A72#code
    function deposit(uint256 amount, address receiver) external;

    function redeem(uint256 shares, address receiver, address owner) external;

    function toAssetAmount(uint256 shares, bool roundUp) external view returns (uint256);

    function toAssetShares(uint256 amount, bool roundUp) external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function addInterest()
        external
        returns (uint256 _interestEarned, uint256 _feesAmount, uint256 _feesShare, uint64 _newRate);

    function getPairAccounting()
        external
        view
        returns (
            uint128 totalAssetAmount,
            uint128 totalAssetShares,
            uint128 totalBorrowAmount,
            uint128 totalBorrowShares,
            uint256 totalCollateral
        );

    function borrowAsset(uint256 borrowAmount, uint256 collateralAmount, address receiver) external;

    function repayAsset(uint256 shares, address borrower) external;

    // Changes for Frax Pair V2 interface.
    // Example Pair: https://etherscan.io/address/0x78bB3aEC3d855431bd9289fD98dA13F9ebB7ef15#code
    struct CurrentRateInfo {
        uint32 lastBlock;
        uint32 feeToProtocolRate; // Fee amount 1e5 precision
        uint64 lastTimestamp;
        uint64 ratePerSec;
        uint64 fullUtilizationRate;
    }

    struct VaultAccount {
        uint128 amount; // Total amount, analogous to market cap
        uint128 shares; // Total shares, analogous to shares outstanding
    }

    function toAssetAmount(uint256 shares, bool roundUp, bool previewInterest) external view returns (uint256);

    function toAssetShares(uint256 amount, bool roundUp, bool previewInterest) external view returns (uint256);

    function withdraw(uint256 assets, address receiver, address owner) external;

    function addInterest(
        bool returnAccounting
    )
        external
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            CurrentRateInfo memory _currentRateInfo,
            VaultAccount memory _totalAsset,
            VaultAccount memory _totalBorrow
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "src/base/ERC20.sol";
import { SafeTransferLib } from "src/base/SafeTransferLib.sol";
import { Math } from "src/utils/Math.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares, receiver, owner);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(assets, shares, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares, receiver, owner);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);

        afterWithdraw(assets, shares, receiver, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeDeposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual {}

    function afterDeposit(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal virtual {}

    function beforeWithdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual {}

    function afterWithdraw(
        uint256 assets,
        uint256 shares,
        address receiver,
        address owner
    ) internal virtual {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Cellar } from "src/base/Cellar.sol";
import { ERC20 } from "src/base/ERC20.sol";
import { BaseAdaptor } from "src/modules/adaptors/BaseAdaptor.sol";
import { PriceRouter } from "src/modules/price-router/PriceRouter.sol";

contract Registry is Ownable {
    // ============================================= ADDRESS CONFIG =============================================

    /**
     * @notice Emitted when the address of a contract is changed.
     * @param id value representing the unique ID tied to the changed contract
     * @param oldAddress address of the contract before the change
     * @param newAddress address of the contract after the contract
     */
    event AddressChanged(uint256 indexed id, address oldAddress, address newAddress);

    /**
     * @notice Attempted to set the address of a contract that is not registered.
     * @param id id of the contract that is not registered
     */
    error Registry__ContractNotRegistered(uint256 id);

    /**
     * @notice Emitted when depositor privilege changes.
     * @param depositor depositor address
     * @param state the new state of the depositor privilege
     */
    event DepositorOnBehalfChanged(address depositor, bool state);

    /**
     * @notice The unique ID that the next registered contract will have.
     */
    uint256 public nextId;

    /**
     * @notice Get the address associated with an id.
     */
    mapping(uint256 => address) public getAddress;

    /**
     * @notice In order for an address to make deposits on behalf of users they must be approved.
     */
    mapping(address => bool) public approvedForDepositOnBehalf;

    /**
     * @notice toggles a depositors  ability to deposit into cellars on behalf of users.
     */
    function setApprovedForDepositOnBehalf(address depositor, bool state) external onlyOwner {
        approvedForDepositOnBehalf[depositor] = state;
        emit DepositorOnBehalfChanged(depositor, state);
    }

    /**
     * @notice Set the address of the contract at a given id.
     */
    function setAddress(uint256 id, address newAddress) external {
        if (id > 0) {
            _checkOwner();
            if (id >= nextId) revert Registry__ContractNotRegistered(id);
        } else {
            if (msg.sender != getAddress[0]) revert Registry__OnlyCallableByZeroId();
        }

        emit AddressChanged(id, getAddress[id], newAddress);

        getAddress[id] = newAddress;
    }

    // ============================================= INITIALIZATION =============================================

    /**
     * @param gravityBridge address of GravityBridge contract
     * @param swapRouter address of SwapRouter contract
     * @param priceRouter address of PriceRouter contract
     */
    constructor(address gravityBridge, address swapRouter, address priceRouter) Ownable() {
        _register(gravityBridge);
        _register(swapRouter);
        _register(priceRouter);
    }

    // ============================================ REGISTER CONFIG ============================================

    /**
     * @notice Emitted when a new contract is registered.
     * @param id value representing the unique ID tied to the new contract
     * @param newContract address of the new contract
     */
    event Registered(uint256 indexed id, address indexed newContract);

    /**
     * @notice Register the address of a new contract.
     * @param newContract address of the new contract to register
     */
    function register(address newContract) external onlyOwner {
        _register(newContract);
    }

    function _register(address newContract) internal {
        getAddress[nextId] = newContract;

        emit Registered(nextId, newContract);

        nextId++;
    }

    // ============================================= ADDRESS 0 LOGIC =============================================
    /**
     * Address 0 is the address of the gravity bridge, and special abilities that the owner does not have.
     * - It can change what address is stored at address 0.
     * - It can change the owner of this contract.
     */

    /**
     * @notice Emitted when an ownership transition is started.
     */
    event OwnerTransitionStarted(address newOwner, uint256 startTime);

    /**
     * @notice Emitted when an ownership transition is cancelled.
     */
    event OwnerTransitionCancelled();

    /**
     * @notice Emitted when an ownership transition is completed.
     */
    event OwnerTransitionComplete(address newOwner);

    /**
     * @notice Attempted to call a function intended for Zero Id address.
     */
    error Registry__OnlyCallableByZeroId();

    /**
     * @notice Attempted to transition owner to the zero address.
     */
    error Registry__NewOwnerCanNotBeZero();

    /**
     * @notice Attempted to perform a restricted action while ownership transition is pending.
     */
    error Registry__TransitionPending();

    /**
     * @notice Attempted to cancel or complete a transition when one is not active.
     */
    error Registry__TransitionNotPending();

    /**
     * @notice Attempted to call `completeTransition` from an address that is not the pending owner.
     */
    error Registry__OnlyCallableByPendingOwner();

    /**
     * @notice The amount of time it takes for an ownership transition to work.
     */
    uint256 public constant TRANSITION_PERIOD = 7 days;

    /**
     * @notice The Pending Owner, that becomes the owner after the transition period, and they call `completeTransition`.
     */
    address public pendingOwner;

    /**
     * @notice The starting time stamp of the transition.
     */
    uint256 public transitionStart;

    /**
     * @notice Allows Zero Id address to set a new owner, after the transition period is up.
     */
    function transitionOwner(address newOwner) external {
        if (msg.sender != getAddress[0]) revert Registry__OnlyCallableByZeroId();
        if (pendingOwner != address(0)) revert Registry__TransitionPending();
        if (newOwner == address(0)) revert Registry__NewOwnerCanNotBeZero();

        pendingOwner = newOwner;
        transitionStart = block.timestamp;
    }

    /**
     * @notice Allows Zero Id address to cancel an ongoing owner transition.
     */
    function cancelTransition() external {
        if (msg.sender != getAddress[0]) revert Registry__OnlyCallableByZeroId();
        if (pendingOwner == address(0)) revert Registry__TransitionNotPending();

        pendingOwner = address(0);
        transitionStart = 0;
    }

    /**
     * @notice Allows pending owner to complete the ownership transition.
     */
    function completeTransition() external {
        if (pendingOwner == address(0)) revert Registry__TransitionNotPending();
        if (msg.sender != pendingOwner) revert Registry__OnlyCallableByPendingOwner();
        if (block.timestamp < transitionStart + TRANSITION_PERIOD) revert Registry__TransitionPending();

        _transferOwnership(pendingOwner);

        pendingOwner = address(0);
        transitionStart = 0;
    }

    /**
     * @notice Extends OZ Ownable `_checkOwner` function to block owner calls, if there is an ongoing transition.
     */
    function _checkOwner() internal view override {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        if (transitionStart != 0) revert Registry__TransitionPending();
    }

    // ============================================ PAUSE LOGIC ============================================

    /**
     * @notice Emitted when a target is paused.
     */
    event TargetPaused(address target);

    /**
     * @notice Emitted when a target is unpaused.
     */
    event TargetUnpaused(address target);

    /**
     * @notice Attempted to unpause a target that was not paused.
     */
    error Registry__TargetNotPaused(address target);

    /**
     * @notice Attempted to pause a target that was already paused.
     */
    error Registry__TargetAlreadyPaused(address target);

    /**
     * @notice Mapping stores whether or not a cellar is paused.
     */
    mapping(address => bool) public isCallerPaused;

    /**
     * @notice Allows multisig to pause multiple cellars in a single call.
     */
    function batchPause(address[] calldata targets) external onlyOwner {
        for (uint256 i; i < targets.length; ++i) _pauseTarget(targets[i]);
    }

    /**
     * @notice Allows multisig to unpause multiple cellars in a single call.
     */
    function batchUnpause(address[] calldata targets) external onlyOwner {
        for (uint256 i; i < targets.length; ++i) _unpauseTarget(targets[i]);
    }

    /**
     * @notice Helper function to pause some target.
     */
    function _pauseTarget(address target) internal {
        if (isCallerPaused[target]) revert Registry__TargetAlreadyPaused(target);
        isCallerPaused[target] = true;
        emit TargetPaused(target);
    }

    /**
     * @notice Helper function to unpause some target.
     */
    function _unpauseTarget(address target) internal {
        if (!isCallerPaused[target]) revert Registry__TargetNotPaused(target);
        isCallerPaused[target] = false;
        emit TargetUnpaused(target);
    }

    // ============================================ ADAPTOR LOGIC ============================================

    /**
     * @notice Attempted to trust an adaptor with non unique identifier.
     */
    error Registry__IdentifierNotUnique();

    /**
     * @notice Attempted to use an untrusted adaptor.
     */
    error Registry__AdaptorNotTrusted(address adaptor);

    /**
     * @notice Attempted to trust an already trusted adaptor.
     */
    error Registry__AdaptorAlreadyTrusted(address adaptor);

    /**
     * @notice Maps an adaptor address to bool indicating whether it has been set up in the registry.
     */
    mapping(address => bool) public isAdaptorTrusted;

    /**
     * @notice Maps an adaptors identfier to bool, to track if the identifier is unique wrt the registry.
     */
    mapping(bytes32 => bool) public isIdentifierUsed;

    /**
     * @notice Trust an adaptor to be used by cellars
     * @param adaptor address of the adaptor to trust
     */
    function trustAdaptor(address adaptor) external onlyOwner {
        if (isAdaptorTrusted[adaptor]) revert Registry__AdaptorAlreadyTrusted(adaptor);
        bytes32 identifier = BaseAdaptor(adaptor).identifier();
        if (isIdentifierUsed[identifier]) revert Registry__IdentifierNotUnique();
        isAdaptorTrusted[adaptor] = true;
        isIdentifierUsed[identifier] = true;
    }

    /**
     * @notice Allows registry to distrust adaptors.
     * @dev Doing so prevents Cellars from adding this adaptor to their catalogue.
     */
    function distrustAdaptor(address adaptor) external onlyOwner {
        if (!isAdaptorTrusted[adaptor]) revert Registry__AdaptorNotTrusted(adaptor);
        // Set trust to false.
        isAdaptorTrusted[adaptor] = false;

        // We are NOT resetting `isIdentifierUsed` because if this adaptor is distrusted, then something needs
        // to change about the new one being re-trusted.
    }

    /**
     * @notice Reverts if `adaptor` is not trusted by the registry.
     */
    function revertIfAdaptorIsNotTrusted(address adaptor) external view {
        if (!isAdaptorTrusted[adaptor]) revert Registry__AdaptorNotTrusted(adaptor);
    }

    // ============================================ POSITION LOGIC ============================================
    /**
     * @notice stores data related to Cellar positions.
     * @param adaptors address of the adaptor to use for this position
     * @param isDebt bool indicating whether this position takes on debt or not
     * @param adaptorData arbitrary data needed to correclty set up a position
     * @param configurationData arbitrary data settable by strategist to change cellar <-> adaptor interaction
     */
    struct PositionData {
        address adaptor;
        bool isDebt;
        bytes adaptorData;
        bytes configurationData;
    }

    /**
     * @notice Emitted when a new position is added to the registry.
     * @param id the positions id
     * @param adaptor address of the adaptor this position uses
     * @param isDebt bool indicating whether this position takes on debt or not
     * @param adaptorData arbitrary bytes used to configure this position
     */
    event PositionAdded(uint32 id, address adaptor, bool isDebt, bytes adaptorData);

    /**
     * @notice Attempted to trust a position not being used.
     * @param position address of the invalid position
     */
    error Registry__PositionPricingNotSetUp(address position);

    /**
     * @notice Attempted to add a position with bad input values.
     */
    error Registry__InvalidPositionInput();

    /**
     * @notice Attempted to add a position that does not exist.
     */
    error Registry__PositionDoesNotExist();

    /**
     * @notice Attempted to add a position that is not trusted.
     */
    error Registry__PositionIsNotTrusted(uint32 position);

    /**
     * @notice Addresses of the positions currently used by the cellar.
     */
    uint256 public constant PRICE_ROUTER_REGISTRY_SLOT = 2;

    /**
     * @notice Stores the number of positions that have been added to the registry.
     *         Starts at 101.
     */
    uint32 public positionCount = 100;

    /**
     * @notice Maps a position hash to a position Id.
     * @dev can be used by adaptors to verify that a certain position is open during Cellar `callOnAdaptor` calls.
     */
    mapping(bytes32 => uint32) public getPositionHashToPositionId;

    /**
     * @notice Maps a position id to its position data.
     * @dev used by Cellars when adding new positions.
     */
    mapping(uint32 => PositionData) public getPositionIdToPositionData;

    /**
     * @notice Maps a position to a bool indicating whether or not it is trusted.
     */
    mapping(uint32 => bool) public isPositionTrusted;

    /**
     * @notice Trust a position to be used by the cellar.
     * @param adaptor the adaptor address this position uses
     * @param adaptorData arbitrary bytes used to configure this position
     * @return positionId the position id of the newly added position
     */
    function trustPosition(address adaptor, bytes memory adaptorData) external onlyOwner returns (uint32 positionId) {
        bytes32 identifier = BaseAdaptor(adaptor).identifier();
        bool isDebt = BaseAdaptor(adaptor).isDebt();
        bytes32 positionHash = keccak256(abi.encode(identifier, isDebt, adaptorData));
        positionId = positionCount + 1; //Add one so that we do not use Id 0.

        // Check that...
        // `adaptor` is a non zero address
        // position has not been already set up
        if (adaptor == address(0) || getPositionHashToPositionId[positionHash] != 0)
            revert Registry__InvalidPositionInput();

        if (!isAdaptorTrusted[adaptor]) revert Registry__AdaptorNotTrusted(adaptor);

        // Set position data.
        getPositionIdToPositionData[positionId] = PositionData({
            adaptor: adaptor,
            isDebt: isDebt,
            adaptorData: adaptorData,
            configurationData: abi.encode(0)
        });

        // Globally trust the position.
        isPositionTrusted[positionId] = true;

        getPositionHashToPositionId[positionHash] = positionId;

        // Check that assets position uses are supported for pricing operations.
        ERC20[] memory assets = BaseAdaptor(adaptor).assetsUsed(adaptorData);
        PriceRouter priceRouter = PriceRouter(getAddress[PRICE_ROUTER_REGISTRY_SLOT]);
        for (uint256 i; i < assets.length; i++) {
            if (!priceRouter.isSupported(assets[i])) revert Registry__PositionPricingNotSetUp(address(assets[i]));
        }

        positionCount = positionId;

        emit PositionAdded(positionId, adaptor, isDebt, adaptorData);
    }

    /**
     * @notice Allows registry to distrust positions.
     * @dev Doing so prevents Cellars from adding this position to their catalogue,
     *      and adding the position to their tracked arrays.
     */
    function distrustPosition(uint32 positionId) external onlyOwner {
        if (!isPositionTrusted[positionId]) revert("Position not trusted");
        isPositionTrusted[positionId] = false;
    }

    /**
     * @notice Called by Cellars to add a new position to themselves.
     * @param positionId the id of the position the cellar wants to add
     * @return adaptor the address of the adaptor, isDebt bool indicating whether position is
     *         debt or not, and adaptorData needed to interact with position
     */
    function addPositionToCellar(
        uint32 positionId
    ) external view returns (address adaptor, bool isDebt, bytes memory adaptorData) {
        if (positionId > positionCount || positionId == 0) revert Registry__PositionDoesNotExist();

        revertIfPositionIsNotTrusted(positionId);

        PositionData memory positionData = getPositionIdToPositionData[positionId];
        return (positionData.adaptor, positionData.isDebt, positionData.adaptorData);
    }

    /**
     * @notice Reverts if `positionId` is not trusted by the registry.
     */
    function revertIfPositionIsNotTrusted(uint32 positionId) public view {
        if (!isPositionTrusted[positionId]) revert Registry__PositionIsNotTrusted(positionId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { ERC4626, SafeTransferLib, Math, ERC20 } from "./ERC4626.sol";
import { Registry } from "src/Registry.sol";
import { PriceRouter } from "src/modules/price-router/PriceRouter.sol";
import { IGravity } from "src/interfaces/external/IGravity.sol";
import { Uint32Array } from "src/utils/Uint32Array.sol";
import { BaseAdaptor } from "src/modules/adaptors/BaseAdaptor.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Owned } from "@solmate/auth/Owned.sol";

/**
 * @title Sommelier Cellar
 * @notice A composable ERC4626 that can use arbitrary DeFi assets/positions using adaptors.
 * @author crispymangoes
 */
contract Cellar is ERC4626, Owned, ERC721Holder {
    using Uint32Array for uint32[];
    using SafeTransferLib for ERC20;
    using Math for uint256;
    using Address for address;

    // ========================================= MULTICALL =========================================

    /**
     * @notice Allows caller to call multiple functions in a single TX.
     * @dev Does NOT return the function return values.
     */
    function multicall(bytes[] calldata data) external {
        for (uint256 i = 0; i < data.length; i++) address(this).functionDelegateCall(data[i]);
    }

    // ========================================= REENTRANCY GUARD =========================================

    /**
     * @notice `locked` is public, so that the state can be checked even during view function calls.
     */
    uint256 public locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }

    // ========================================= PRICE ROUTER CACHE =========================================

    /**
     * @notice Cached price router contract.
     * @dev This way cellar has to "opt in" to price router changes.
     */
    PriceRouter public priceRouter;

    /**
     * @notice Updates the cellar to use the lastest price router in the registry.
     * @param checkTotalAssets If true totalAssets is checked before and after updating the price router,
     *        and is verified to be withing a +- 5% envelope.
     *        If false totalAssets is only called after updating the price router.]
     * @param allowableRange The +- range the total assets may deviate between the old and new price router.
     *                       - 1_000 == 10%
     *                       - 500 == 5%
     * @dev `allowableRange` reverts from arithmetic underflow if it is greater than 10_000, this is
     *      desired behavior.
     */
    function cachePriceRouter(bool checkTotalAssets, uint16 allowableRange) external onlyOwner {
        uint256 minAssets;
        uint256 maxAssets;

        if (checkTotalAssets) {
            uint256 assetsBefore = totalAssets();
            minAssets = assetsBefore.mulDivDown(1e4 - allowableRange, 1e4);
            maxAssets = assetsBefore.mulDivDown(1e4 + allowableRange, 1e4);
        }

        priceRouter = PriceRouter(registry.getAddress(PRICE_ROUTER_REGISTRY_SLOT));
        uint256 assetsAfter = totalAssets();

        if (checkTotalAssets) {
            if (assetsAfter < minAssets || assetsAfter > maxAssets)
                revert Cellar__TotalAssetDeviatedOutsideRange(assetsAfter, minAssets, maxAssets);
        }
    }

    // ========================================= POSITIONS CONFIG =========================================

    /**
     * @notice Emitted when a position is added.
     * @param position id of position that was added
     * @param index index that position was added at
     */
    event PositionAdded(uint32 position, uint256 index);

    /**
     * @notice Emitted when a position is removed.
     * @param position id of position that was removed
     * @param index index that position was removed from
     */
    event PositionRemoved(uint32 position, uint256 index);

    /**
     * @notice Emitted when the positions at two indexes are swapped.
     * @param newPosition1 id of position (previously at index2) that replaced index1.
     * @param newPosition2 id of position (previously at index1) that replaced index2.
     * @param index1 index of first position involved in the swap
     * @param index2 index of second position involved in the swap.
     */
    event PositionSwapped(uint32 newPosition1, uint32 newPosition2, uint256 index1, uint256 index2);

    /**
     * @notice Emitted when Governance adds/removes a position to/from the cellars catalogue.
     */
    event PositionCatalogueAltered(uint32 positionId, bool inCatalogue);

    /**
     * @notice Emitted when Governance adds/removes an adaptor to/from the cellars catalogue.
     */
    event AdaptorCatalogueAltered(address adaptor, bool inCatalogue);

    /**
     * @notice Attempted to add a position that is already being used.
     * @param position id of the position
     */
    error Cellar__PositionAlreadyUsed(uint32 position);

    /**
     * @notice Attempted to make an unused position the holding position.
     * @param position id of the position
     */
    error Cellar__PositionNotUsed(uint32 position);

    /**
     * @notice Attempted to add a position that is not in the catalogue.
     * @param position id of the position
     */
    error Cellar__PositionNotInCatalogue(uint32 position);

    /**
     * @notice Attempted an action on a position that is required to be empty before the action can be performed.
     * @param position address of the non-empty position
     * @param sharesRemaining amount of shares remaining in the position
     */
    error Cellar__PositionNotEmpty(uint32 position, uint256 sharesRemaining);

    /**
     * @notice Attempted an operation with an asset that was different then the one expected.
     * @param asset address of the asset
     * @param expectedAsset address of the expected asset
     */
    error Cellar__AssetMismatch(address asset, address expectedAsset);

    /**
     * @notice Attempted to add a position when the position array is full.
     * @param maxPositions maximum number of positions that can be used
     */
    error Cellar__PositionArrayFull(uint256 maxPositions);

    /**
     * @notice Attempted to add a position, with mismatched debt.
     * @param position the posiiton id that was mismatched
     */
    error Cellar__DebtMismatch(uint32 position);

    /**
     * @notice Attempted to remove the Cellars holding position.
     */
    error Cellar__RemovingHoldingPosition();

    /**
     * @notice Attempted to add an invalid holding position.
     * @param positionId the id of the invalid position.
     */
    error Cellar__InvalidHoldingPosition(uint32 positionId);

    /**
     * @notice Array of uint32s made up of cellars credit positions Ids.
     */
    uint32[] public creditPositions;

    /**
     * @notice Array of uint32s made up of cellars debt positions Ids.
     */
    uint32[] public debtPositions;

    /**
     * @notice Tell whether a position is currently used.
     */
    mapping(uint256 => bool) public isPositionUsed;

    /**
     * @notice Get position data given position id.
     */
    mapping(uint32 => Registry.PositionData) public getPositionData;

    /**
     * @notice Get the ids of the credit positions currently used by the cellar.
     */
    function getCreditPositions() external view returns (uint32[] memory) {
        return creditPositions;
    }

    /**
     * @notice Get the ids of the debt positions currently used by the cellar.
     */
    function getDebtPositions() external view returns (uint32[] memory) {
        return debtPositions;
    }

    /**
     * @notice Maximum amount of positions a cellar can have in it's credit/debt arrays.
     */
    uint256 public constant MAX_POSITIONS = 16;

    /**
     * @notice Stores the index of the holding position in the creditPositions array.
     */
    uint32 public holdingPosition;

    /**
     * @notice Allows owner to change the holding position.
     */
    function setHoldingPosition(uint32 positionId) external onlyOwner {
        _setHoldingPosition(positionId);
    }

    function _setHoldingPosition(uint32 positionId) internal {
        if (!isPositionUsed[positionId]) revert Cellar__PositionNotUsed(positionId);
        if (_assetOf(positionId) != asset) revert Cellar__AssetMismatch(address(asset), address(_assetOf(positionId)));
        if (getPositionData[positionId].isDebt) revert Cellar__InvalidHoldingPosition(positionId);
        holdingPosition = positionId;
    }

    /**
     * @notice Positions the strategist is approved to use without any governance intervention.
     */
    mapping(uint32 => bool) public positionCatalogue;

    /**
     * @notice Adaptors the strategist is approved to use without any governance intervention.
     */
    mapping(address => bool) public adaptorCatalogue;

    /**
     * @notice Allows Governance to add positions to this cellar's catalogue.
     */
    function addPositionToCatalogue(uint32 positionId) external onlyOwner {
        _addPositionToCatalogue(positionId);
    }

    /**
     * @notice Helper function that checks the position is trusted.
     */
    function _addPositionToCatalogue(uint32 positionId) internal {
        // Make sure position is not paused and is trusted.
        registry.revertIfPositionIsNotTrusted(positionId);
        positionCatalogue[positionId] = true;
        emit PositionCatalogueAltered(positionId, true);
    }

    /**
     * @notice Allows Governance to remove positions from this cellar's catalogue.
     */
    function removePositionFromCatalogue(uint32 positionId) external onlyOwner {
        positionCatalogue[positionId] = false;
        emit PositionCatalogueAltered(positionId, false);
    }

    /**
     * @notice Allows Governance to add adaptors to this cellar's catalogue.
     */
    function addAdaptorToCatalogue(address adaptor) external onlyOwner {
        // Make sure adaptor is not paused and is trusted.
        registry.revertIfAdaptorIsNotTrusted(adaptor);
        adaptorCatalogue[adaptor] = true;
        emit AdaptorCatalogueAltered(adaptor, true);
    }

    /**
     * @notice Allows Governance to remove adaptors from this cellar's catalogue.
     */
    function removeAdaptorFromCatalogue(address adaptor) external onlyOwner {
        adaptorCatalogue[adaptor] = false;
        emit AdaptorCatalogueAltered(adaptor, false);
    }

    /**
     * @notice Insert a trusted position to the list of positions used by the cellar at a given index.
     * @param index index at which to insert the position
     * @param positionId id of position to add
     * @param configurationData data used to configure how the position behaves
     */
    function addPosition(
        uint32 index,
        uint32 positionId,
        bytes memory configurationData,
        bool inDebtArray
    ) external onlyOwner {
        _whenNotShutdown();
        _addPosition(index, positionId, configurationData, inDebtArray);
    }

    /**
     * @notice Internal function is used by `addPosition` and initialize function.
     */
    function _addPosition(uint32 index, uint32 positionId, bytes memory configurationData, bool inDebtArray) internal {
        // Check if position is already being used.
        if (isPositionUsed[positionId]) revert Cellar__PositionAlreadyUsed(positionId);

        // Check if position is in the position catalogue.
        if (!positionCatalogue[positionId]) revert Cellar__PositionNotInCatalogue(positionId);

        // Grab position data from registry.
        // Also checks if position is not trusted and reverts if so.
        (address adaptor, bool isDebt, bytes memory adaptorData) = registry.addPositionToCellar(positionId);

        if (isDebt != inDebtArray) revert Cellar__DebtMismatch(positionId);

        // Copy position data from registry to here.
        getPositionData[positionId] = Registry.PositionData({
            adaptor: adaptor,
            isDebt: isDebt,
            adaptorData: adaptorData,
            configurationData: configurationData
        });

        if (isDebt) {
            if (debtPositions.length >= MAX_POSITIONS) revert Cellar__PositionArrayFull(MAX_POSITIONS);
            // Add new position at a specified index.
            debtPositions.add(index, positionId);
        } else {
            if (creditPositions.length >= MAX_POSITIONS) revert Cellar__PositionArrayFull(MAX_POSITIONS);
            // Add new position at a specified index.
            creditPositions.add(index, positionId);
        }

        isPositionUsed[positionId] = true;

        emit PositionAdded(positionId, index);
    }

    /**
     * @notice Remove the position at a given index from the list of positions used by the cellar.
     * @dev Called by strategist.
     * @param index index at which to remove the position
     */
    function removePosition(uint32 index, bool inDebtArray) external onlyOwner {
        // Get position being removed.
        uint32 positionId = inDebtArray ? debtPositions[index] : creditPositions[index];
        // Only remove position if it is empty, and if it is not the holding position.
        uint256 positionBalance = _balanceOf(positionId);
        if (positionBalance > 0) revert Cellar__PositionNotEmpty(positionId, positionBalance);

        _removePosition(index, positionId, inDebtArray);
    }

    /**
     * @notice Allows Governance to force a cellar out of a position without making ANY external calls.
     */
    function forcePositionOut(uint32 index, uint32 positionId, bool inDebtArray) external onlyOwner {
        _removePosition(index, positionId, inDebtArray);
    }

    /**
     * @notice Internal helper function to remove positions from cellars tracked arrays.
     */
    function _removePosition(uint32 index, uint32 positionId, bool inDebtArray) internal {
        if (positionId == holdingPosition) revert Cellar__RemovingHoldingPosition();

        if (inDebtArray) {
            // Remove position at the given index.
            debtPositions.remove(index);
        } else {
            creditPositions.remove(index);
        }

        isPositionUsed[positionId] = false;
        delete getPositionData[positionId];

        emit PositionRemoved(positionId, index);
    }

    /**
     * @notice Swap the positions at two given indexes.
     * @param index1 index of first position to swap
     * @param index2 index of second position to swap
     * @param inDebtArray bool indicating to switch positions in the debt array, or the credit array.
     */
    function swapPositions(uint32 index1, uint32 index2, bool inDebtArray) external onlyOwner {
        // Get the new positions that will be at each index.
        uint32 newPosition1;
        uint32 newPosition2;

        if (inDebtArray) {
            newPosition1 = debtPositions[index2];
            newPosition2 = debtPositions[index1];
            // Swap positions.
            (debtPositions[index1], debtPositions[index2]) = (newPosition1, newPosition2);
        } else {
            newPosition1 = creditPositions[index2];
            newPosition2 = creditPositions[index1];
            // Swap positions.
            (creditPositions[index1], creditPositions[index2]) = (newPosition1, newPosition2);
        }

        emit PositionSwapped(newPosition1, newPosition2, index1, index2);
    }

    // =============================================== FEES CONFIG ===============================================

    /**
     * @notice Emitted when platform fees is changed.
     * @param oldPlatformFee value platform fee was changed from
     * @param newPlatformFee value platform fee was changed to
     */
    event PlatformFeeChanged(uint64 oldPlatformFee, uint64 newPlatformFee);

    /**
     * @notice Emitted when strategist platform fee cut is changed.
     * @param oldPlatformCut value strategist platform fee cut was changed from
     * @param newPlatformCut value strategist platform fee cut was changed to
     */
    event StrategistPlatformCutChanged(uint64 oldPlatformCut, uint64 newPlatformCut);

    /**
     * @notice Emitted when strategists payout address is changed.
     * @param oldPayoutAddress value strategists payout address was changed from
     * @param newPayoutAddress value strategists payout address was changed to
     */
    event StrategistPayoutAddressChanged(address oldPayoutAddress, address newPayoutAddress);

    /**
     * @notice Attempted to change strategist fee cut with invalid value.
     */
    error Cellar__InvalidFeeCut();

    /**
     * @notice Attempted to change platform fee with invalid value.
     */
    error Cellar__InvalidFee();

    /**
     * @notice Data related to fees.
     * @param strategistPlatformCut Determines how much platform fees go to strategist.
     *                              This should be a value out of 1e18 (ie. 1e18 represents 100%, 0 represents 0%).
     * @param platformFee The percentage of total assets accrued as platform fees over a year.
                          This should be a value out of 1e18 (ie. 1e18 represents 100%, 0 represents 0%).
     * @param strategistPayoutAddress Address to send the strategists fee shares.
     */
    struct FeeData {
        uint64 strategistPlatformCut;
        uint64 platformFee;
        uint64 lastAccrual;
        address strategistPayoutAddress;
    }

    /**
     * @notice Stores all fee data for cellar.
     */
    FeeData public feeData =
        FeeData({
            strategistPlatformCut: 0.75e18,
            platformFee: 0.01e18,
            lastAccrual: 0,
            strategistPayoutAddress: address(0)
        });

    /**
     * @notice Sets the max possible performance fee for this cellar.
     */
    uint64 public constant MAX_PLATFORM_FEE = 0.2e18;

    /**
     * @notice Sets the max possible fee cut for this cellar.
     */
    uint64 public constant MAX_FEE_CUT = 1e18;

    /**
     * @notice Sets the Strategists cut of platform fees
     * @param cut the platform cut for the strategist
     */
    function setStrategistPlatformCut(uint64 cut) external onlyOwner {
        if (cut > MAX_FEE_CUT) revert Cellar__InvalidFeeCut();
        emit StrategistPlatformCutChanged(feeData.strategistPlatformCut, cut);

        feeData.strategistPlatformCut = cut;
    }

    /**
     * @notice Sets the Strategists payout address
     * @param payout the new strategist payout address
     */
    function setStrategistPayoutAddress(address payout) external onlyOwner {
        emit StrategistPayoutAddressChanged(feeData.strategistPayoutAddress, payout);

        feeData.strategistPayoutAddress = payout;
    }

    // =========================================== EMERGENCY LOGIC ===========================================

    /**
     * @notice Emitted when cellar emergency state is changed.
     * @param isShutdown whether the cellar is shutdown
     */
    event ShutdownChanged(bool isShutdown);

    /**
     * @notice Attempted action was prevented due to contract being shutdown.
     */
    error Cellar__ContractShutdown();

    /**
     * @notice Attempted action was prevented due to contract not being shutdown.
     */
    error Cellar__ContractNotShutdown();

    /**
     * @notice Attempted to interact with the cellar when it is paused.
     */
    error Cellar__Paused();

    /**
     * @notice Whether or not the contract is shutdown in case of an emergency.
     */
    bool public isShutdown;

    /**
     * @notice Pauses all user entry/exits, and strategist rebalances.
     */
    bool public ignorePause;

    /**
     * @notice View function external contracts can use to see if the cellar is paused.
     */
    function isPaused() external view returns (bool) {
        if (!ignorePause) {
            return registry.isCallerPaused(address(this));
        }
        return false;
    }

    /**
     * @notice Pauses all user entry/exits, and strategist rebalances.
     */
    function _checkIfPaused() internal view {
        if (!ignorePause) {
            if (registry.isCallerPaused(address(this))) revert Cellar__Paused();
        }
    }

    /**
     * @notice Allows governance to choose whether or not to respect a pause.
     */
    function toggleIgnorePause(bool toggle) external onlyOwner {
        ignorePause = toggle;
    }

    /**
     * @notice Prevent a function from being called during a shutdown.
     */
    function _whenNotShutdown() internal view {
        if (isShutdown) revert Cellar__ContractShutdown();
    }

    /**
     * @notice Shutdown the cellar. Used in an emergency or if the cellar has been deprecated.
     * @dev In the case where
     */
    function initiateShutdown() external onlyOwner {
        _whenNotShutdown();
        isShutdown = true;

        emit ShutdownChanged(true);
    }

    /**
     * @notice Restart the cellar.
     */
    function liftShutdown() external onlyOwner {
        if (!isShutdown) revert Cellar__ContractNotShutdown();
        isShutdown = false;

        emit ShutdownChanged(false);
    }

    // =========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Id to get the gravity bridge from the registry.
     */
    uint256 public constant GRAVITY_BRIDGE_REGISTRY_SLOT = 0;

    /**
     * @notice Id to get the price router from the registry.
     */
    uint256 public constant PRICE_ROUTER_REGISTRY_SLOT = 2;

    /**
     * @notice Address of the platform's registry contract. Used to get the latest address of modules.
     */
    Registry public registry;

    /**
     * @dev Owner should be set to the Gravity Bridge, which relays instructions from the Steward
     *      module to the cellars.
     *      https://github.com/PeggyJV/steward
     *      https://github.com/cosmos/gravity-bridge/blob/main/solidity/contracts/Gravity.sol
     * @param _registry address of the platform's registry contract
     * @param _asset address of underlying token used for the for accounting, depositing, and withdrawing
     * @param _name name of this cellar's share token
     * @param _symbol symbol of this cellar's share token
     * @param params abi encode values.
     *               -  _creditPositions ids of the credit positions to initialize the cellar with
     *               -  _debtPositions ids of the credit positions to initialize the cellar with
     *               -  _creditConfigurationData configuration data for each position
     *               -  _debtConfigurationData configuration data for each position
     *               -  _holdingIndex the index in _creditPositions to use as the holding position.
     *               -  _strategistPayout the address to send the strategists fee shares.
     *               -  _assetRiskTolerance this cellars risk tolerance for assets it is exposed to
     *               -  _protocolRiskTolerance this cellars risk tolerance for protocols it will use
     */
    constructor(
        Registry _registry,
        ERC20 _asset,
        string memory _name,
        string memory _symbol,
        bytes memory params
    ) ERC4626(_asset, _name, _symbol, 18) Owned(_registry.getAddress(GRAVITY_BRIDGE_REGISTRY_SLOT)) {
        registry = _registry;
        priceRouter = PriceRouter(registry.getAddress(PRICE_ROUTER_REGISTRY_SLOT));

        {
            (
                uint32[] memory _creditPositions,
                uint32[] memory _debtPositions,
                bytes[] memory _creditConfigurationData,
                bytes[] memory _debtConfigurationData,
                uint32 _holdingPosition
            ) = abi.decode(params, (uint32[], uint32[], bytes[], bytes[], uint8));

            // Initialize positions.
            for (uint32 i; i < _creditPositions.length; ++i) {
                _addPositionToCatalogue(_creditPositions[i]);
                _addPosition(i, _creditPositions[i], _creditConfigurationData[i], false);
            }
            for (uint32 i; i < _debtPositions.length; ++i) {
                _addPositionToCatalogue(_debtPositions[i]);
                _addPosition(i, _debtPositions[i], _debtConfigurationData[i], true);
            }
            // This check allows us to deploy an implementation contract.
            /// @dev No cellars will be deployed with a zero length credit positions array.
            if (_creditPositions.length > 0) _setHoldingPosition(_holdingPosition);
        }

        // Initialize last accrual timestamp to time that cellar was created, otherwise the first
        // `accrue` will take platform fees from 1970 to the time it is called.
        feeData.lastAccrual = uint64(block.timestamp);

        (, , , , , address _strategistPayout, , ) = abi.decode(
            params,
            (uint32[], uint32[], bytes[], bytes[], uint8, address, uint128, uint128)
        );

        feeData.strategistPayoutAddress = _strategistPayout;
    }

    // =========================================== CORE LOGIC ===========================================

    /**
     * @notice Emitted when share locking period is changed.
     * @param oldPeriod the old locking period
     * @param newPeriod the new locking period
     */
    event ShareLockingPeriodChanged(uint256 oldPeriod, uint256 newPeriod);

    /**
     * @notice Attempted an action with zero shares.
     */
    error Cellar__ZeroShares();

    /**
     * @notice Attempted an action with zero assets.
     */
    error Cellar__ZeroAssets();

    /**
     * @notice Withdraw did not withdraw all assets.
     * @param assetsOwed the remaining assets owed that were not withdrawn.
     */
    error Cellar__IncompleteWithdraw(uint256 assetsOwed);

    /**
     * @notice Attempted to withdraw an illiquid position.
     * @param illiquidPosition the illiquid position.
     */
    error Cellar__IlliquidWithdraw(address illiquidPosition);

    /**
     * @notice Attempted to set `shareLockPeriod` to an invalid number.
     */
    error Cellar__InvalidShareLockPeriod();

    /**
     * @notice Attempted to burn shares when they are locked.
     * @param timeSharesAreUnlocked time when caller can transfer/redeem shares
     * @param currentBlock the current block number.
     */
    error Cellar__SharesAreLocked(uint256 timeSharesAreUnlocked, uint256 currentBlock);

    /**
     * @notice Attempted deposit on behalf of a user without being approved.
     */
    error Cellar__NotApprovedToDepositOnBehalf(address depositor);

    /**
     * @notice Shares must be locked for at least 5 minutes after minting.
     */
    uint256 public constant MINIMUM_SHARE_LOCK_PERIOD = 5 * 60;

    /**
     * @notice Shares can be locked for at most 2 days after minting.
     */
    uint256 public constant MAXIMUM_SHARE_LOCK_PERIOD = 2 days;

    /**
     * @notice After deposits users must wait `shareLockPeriod` time before being able to transfer or withdraw their shares.
     */
    uint256 public shareLockPeriod = MAXIMUM_SHARE_LOCK_PERIOD;

    /**
     * @notice mapping that stores every users last time stamp they minted shares.
     */
    mapping(address => uint256) public userShareLockStartTime;

    /**
     * @notice Allows share lock period to be updated.
     * @param newLock the new lock period
     */
    function setShareLockPeriod(uint256 newLock) external onlyOwner {
        if (newLock < MINIMUM_SHARE_LOCK_PERIOD || newLock > MAXIMUM_SHARE_LOCK_PERIOD)
            revert Cellar__InvalidShareLockPeriod();
        uint256 oldLockingPeriod = shareLockPeriod;
        shareLockPeriod = newLock;
        emit ShareLockingPeriodChanged(oldLockingPeriod, newLock);
    }

    /**
     * @notice helper function that checks enough time has passed to unlock shares.
     * @param owner the address of the user to check
     */
    function _checkIfSharesLocked(address owner) internal view {
        uint256 lockTime = userShareLockStartTime[owner];
        if (lockTime != 0) {
            uint256 timeSharesAreUnlocked = lockTime + shareLockPeriod;
            if (timeSharesAreUnlocked > block.timestamp)
                revert Cellar__SharesAreLocked(timeSharesAreUnlocked, block.timestamp);
        }
    }

    /**
     * @notice Override `transfer` to add share lock check.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        _checkIfSharesLocked(msg.sender);
        return super.transfer(to, amount);
    }

    /**
     * @notice Override `transferFrom` to add share lock check.
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        _checkIfSharesLocked(from);
        return super.transferFrom(from, to, amount);
    }

    /**
     * @notice Attempted deposit more than the max deposit.
     * @param assets the assets user attempted to deposit
     * @param maxDeposit the max assets that can be deposited
     */
    error Cellar__DepositRestricted(uint256 assets, uint256 maxDeposit);

    /**
     * @notice called at the beginning of deposit.
     * @param assets amount of assets deposited by user.
     * @param receiver address receiving the shares.
     */
    function beforeDeposit(uint256 assets, uint256, address receiver) internal view override {
        _whenNotShutdown();
        _checkIfPaused();
        if (msg.sender != receiver) {
            if (!registry.approvedForDepositOnBehalf(msg.sender))
                revert Cellar__NotApprovedToDepositOnBehalf(msg.sender);
        }
        uint256 maxAssets = maxDeposit(receiver);
        if (assets > maxAssets) revert Cellar__DepositRestricted(assets, maxAssets);
    }

    /**
     * @notice called at the end of deposit.
     * @param assets amount of assets deposited by user.
     */
    function afterDeposit(uint256 assets, uint256, address receiver) internal override {
        _depositTo(holdingPosition, assets);
        userShareLockStartTime[receiver] = block.timestamp;
    }

    /**
     * @notice called at the beginning of withdraw.
     */
    function beforeWithdraw(uint256, uint256, address, address owner) internal view override {
        _checkIfPaused();
        // Make sure users shares are not locked.
        _checkIfSharesLocked(owner);
    }

    function _enter(uint256 assets, uint256 shares, address receiver) internal {
        beforeDeposit(assets, shares, receiver);

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares, receiver);
    }

    /**
     * @notice Deposits assets into the cellar, and returns shares to receiver.
     * @param assets amount of assets deposited by user.
     * @param receiver address to receive the shares.
     * @return shares amount of shares given for deposit.
     */
    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256 shares) {
        // Use `_accounting` instead of totalAssets bc re-entrancy is already checked in this function.
        uint256 _totalAssets = _accounting(false);

        // Check for rounding error since we round down in previewDeposit.
        if ((shares = _convertToShares(assets, _totalAssets)) == 0) revert Cellar__ZeroShares();

        _enter(assets, shares, receiver);
    }

    /**
     * @notice Mints shares from the cellar, and returns shares to receiver.
     * @param shares amount of shares requested by user.
     * @param receiver address to receive the shares.
     * @return assets amount of assets deposited into the cellar.
     */
    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256 assets) {
        // Use `_accounting` instead of totalAssets bc re-entrancy is already checked in this function.
        uint256 _totalAssets = _accounting(false);

        // previewMint rounds up, but initial mint could return zero assets, so check for rounding error.
        if ((assets = _previewMint(shares, _totalAssets)) == 0) revert Cellar__ZeroAssets();

        _enter(assets, shares, receiver);
    }

    function _exit(uint256 assets, uint256 shares, address receiver, address owner) internal {
        beforeWithdraw(assets, shares, receiver, owner);

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        _withdrawInOrder(assets, receiver);

        /// @notice `afterWithdraw` is currently not used.
        // afterWithdraw(assets, shares, receiver, owner);
    }

    /**
     * @notice Withdraw assets from the cellar by redeeming shares.
     * @dev Unlike conventional ERC4626 contracts, this may not always return one asset to the receiver.
     *      Since there are no swaps involved in this function, the receiver may receive multiple
     *      assets. The value of all the assets returned will be equal to the amount defined by
     *      `assets` denominated in the `asset` of the cellar (eg. if `asset` is USDC and `assets`
     *      is 1000, then the receiver will receive $1000 worth of assets in either one or many
     *      tokens).
     * @param assets equivalent value of the assets withdrawn, denominated in the cellar's asset
     * @param receiver address that will receive withdrawn assets
     * @param owner address that owns the shares being redeemed
     * @return shares amount of shares redeemed
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 shares) {
        // Use `_accounting` instead of totalAssets bc re-entrancy is already checked in this function.
        uint256 _totalAssets = _accounting(false);

        // No need to check for rounding error, `previewWithdraw` rounds up.
        shares = _previewWithdraw(assets, _totalAssets);

        _exit(assets, shares, receiver, owner);
    }

    /**
     * @notice Redeem shares to withdraw assets from the cellar.
     * @dev Unlike conventional ERC4626 contracts, this may not always return one asset to the receiver.
     *      Since there are no swaps involved in this function, the receiver may receive multiple
     *      assets. The value of all the assets returned will be equal to the amount defined by
     *      `assets` denominated in the `asset` of the cellar (eg. if `asset` is USDC and `assets`
     *      is 1000, then the receiver will receive $1000 worth of assets in either one or many
     *      tokens).
     * @param shares amount of shares to redeem
     * @param receiver address that will receive withdrawn assets
     * @param owner address that owns the shares being redeemed
     * @return assets equivalent value of the assets withdrawn, denominated in the cellar's asset
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256 assets) {
        // Use `_accounting` instead of totalAssets bc re-entrancy is already checked in this function.
        uint256 _totalAssets = _accounting(false);

        // Check for rounding error since we round down in previewRedeem.
        if ((assets = _convertToAssets(shares, _totalAssets)) == 0) revert Cellar__ZeroAssets();

        _exit(assets, shares, receiver, owner);
    }

    /**
     * @notice Struct used in `_withdrawInOrder` in order to hold multiple pricing values in a single variable.
     * @dev Prevents stack too deep errors.
     */
    struct WithdrawPricing {
        uint256 priceBaseUSD;
        uint256 oneBase;
        uint256 priceQuoteUSD;
        uint256 oneQuote;
    }

    /**
     * @notice Multipler used to insure calculations use very high precision.
     */
    uint256 private constant PRECISION_MULTIPLIER = 1e18;

    /**
     * @dev Withdraw from positions in the order defined by `positions`.
     * @param assets the amount of assets to withdraw from cellar
     * @param receiver the address to sent withdrawn assets to
     * @dev Only loop through credit array because debt can not be withdraw by users.
     */
    function _withdrawInOrder(uint256 assets, address receiver) internal {
        // Save asset price in USD, and decimals to reduce external calls.
        WithdrawPricing memory pricingInfo;
        pricingInfo.priceQuoteUSD = priceRouter.getPriceInUSD(asset);
        pricingInfo.oneQuote = 10 ** asset.decimals();
        uint256 creditLength = creditPositions.length;
        for (uint256 i; i < creditLength; ++i) {
            uint32 position = creditPositions[i];
            uint256 withdrawableBalance = _withdrawableFrom(position);
            // Move on to next position if this one is empty.
            if (withdrawableBalance == 0) continue;
            ERC20 positionAsset = _assetOf(position);

            pricingInfo.priceBaseUSD = priceRouter.getPriceInUSD(positionAsset);
            pricingInfo.oneBase = 10 ** positionAsset.decimals();
            uint256 totalWithdrawableBalanceInAssets;
            {
                uint256 withdrawableBalanceInUSD = (PRECISION_MULTIPLIER * withdrawableBalance).mulDivDown(
                    pricingInfo.priceBaseUSD,
                    pricingInfo.oneBase
                );
                totalWithdrawableBalanceInAssets = withdrawableBalanceInUSD.mulDivDown(
                    pricingInfo.oneQuote,
                    pricingInfo.priceQuoteUSD
                );
                totalWithdrawableBalanceInAssets = totalWithdrawableBalanceInAssets / PRECISION_MULTIPLIER;
            }

            // We want to pull as much as we can from this position, but no more than needed.
            uint256 amount;

            if (totalWithdrawableBalanceInAssets > assets) {
                // Convert assets into position asset.
                uint256 assetsInUSD = (PRECISION_MULTIPLIER * assets).mulDivDown(
                    pricingInfo.priceQuoteUSD,
                    pricingInfo.oneQuote
                );
                amount = assetsInUSD.mulDivDown(pricingInfo.oneBase, pricingInfo.priceBaseUSD);
                amount = amount / PRECISION_MULTIPLIER;
                assets = 0;
            } else {
                amount = withdrawableBalance;
                assets = assets - totalWithdrawableBalanceInAssets;
            }

            // Withdraw from position.
            _withdrawFrom(position, amount, receiver);

            // Stop if no more assets to withdraw.
            if (assets == 0) break;
        }
        // If withdraw did not remove all assets owed, revert.
        if (assets > 0) revert Cellar__IncompleteWithdraw(assets);
    }

    // ========================================= ACCOUNTING LOGIC =========================================

    /**
     * @notice Internal accounting function that can report total assets, or total assets withdrawable.
     * @param reportWithdrawable if true, then the withdrawable total assets is reported,
     *                           if false, then the total assets is reported
     */
    function _accounting(bool reportWithdrawable) internal view returns (uint256 assets) {
        uint256 numOfCreditPositions = creditPositions.length;
        ERC20[] memory creditAssets = new ERC20[](numOfCreditPositions);
        uint256[] memory creditBalances = new uint256[](numOfCreditPositions);
        // If we just need the withdrawable, then query credit array value.
        if (reportWithdrawable) {
            for (uint256 i; i < numOfCreditPositions; ++i) {
                uint32 position = creditPositions[i];
                // If the withdrawable balance is zero there is no point to query the asset since a zero balance has zero value.
                if ((creditBalances[i] = _withdrawableFrom(position)) == 0) continue;
                creditAssets[i] = _assetOf(position);
            }
            assets = priceRouter.getValues(creditAssets, creditBalances, asset);
        } else {
            uint256 numOfDebtPositions = debtPositions.length;
            ERC20[] memory debtAssets = new ERC20[](numOfDebtPositions);
            uint256[] memory debtBalances = new uint256[](numOfDebtPositions);
            for (uint256 i; i < numOfCreditPositions; ++i) {
                uint32 position = creditPositions[i];
                // If the balance is zero there is no point to query the asset since a zero balance has zero value.
                if ((creditBalances[i] = _balanceOf(position)) == 0) continue;
                creditAssets[i] = _assetOf(position);
            }
            for (uint256 i; i < numOfDebtPositions; ++i) {
                uint32 position = debtPositions[i];
                // If the balance is zero there is no point to query the asset since a zero balance has zero value.
                if ((debtBalances[i] = _balanceOf(position)) == 0) continue;
                debtAssets[i] = _assetOf(position);
            }
            assets = priceRouter.getValuesDelta(creditAssets, creditBalances, debtAssets, debtBalances, asset);
        }
    }

    /**
     * @notice The total amount of assets in the cellar.
     * @dev EIP4626 states totalAssets needs to be inclusive of fees.
     * Since performance fees mint shares, total assets remains unchanged,
     * so this implementation is inclusive of fees even though it does not explicitly show it.
     * @dev EIP4626 states totalAssets must not revert, but it is possible for `totalAssets` to revert
     * so it does NOT conform to ERC4626 standards.
     * @dev Run a re-entrancy check because totalAssets can be wrong if re-entering from deposit/withdraws.
     */
    function totalAssets() public view override returns (uint256 assets) {
        _checkIfPaused();
        require(locked == 1, "REENTRANCY");
        assets = _accounting(false);
    }

    /**
     * @notice The total amount of withdrawable assets in the cellar.
     * @dev Run a re-entrancy check because totalAssetsWithdrawable can be wrong if re-entering from deposit/withdraws.
     */
    function totalAssetsWithdrawable() public view returns (uint256 assets) {
        _checkIfPaused();
        require(locked == 1, "REENTRANCY");
        assets = _accounting(true);
    }

    /**
     * @notice The amount of assets that the cellar would exchange for the amount of shares provided.
     * @param shares amount of shares to convert
     * @return assets the shares can be exchanged for
     */
    function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
        assets = _convertToAssets(shares, totalAssets());
    }

    /**
     * @notice The amount of shares that the cellar would exchange for the amount of assets provided.
     * @param assets amount of assets to convert
     * @return shares the assets can be exchanged for
     */
    function convertToShares(uint256 assets) public view override returns (uint256 shares) {
        shares = _convertToShares(assets, totalAssets());
    }

    /**
     * @notice Simulate the effects of minting shares at the current block, given current on-chain conditions.
     * @param shares amount of shares to mint
     * @return assets that will be deposited
     */
    function previewMint(uint256 shares) public view override returns (uint256 assets) {
        uint256 _totalAssets = totalAssets();
        assets = _previewMint(shares, _totalAssets);
    }

    /**
     * @notice Simulate the effects of withdrawing assets at the current block, given current on-chain conditions.
     * @param assets amount of assets to withdraw
     * @return shares that will be redeemed
     */
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        uint256 _totalAssets = totalAssets();
        shares = _previewWithdraw(assets, _totalAssets);
    }

    /**
     * @notice Simulate the effects of depositing assets at the current block, given current on-chain conditions.
     * @param assets amount of assets to deposit
     * @return shares that will be minted
     */
    function previewDeposit(uint256 assets) public view override returns (uint256 shares) {
        uint256 _totalAssets = totalAssets();
        shares = _convertToShares(assets, _totalAssets);
    }

    /**
     * @notice Simulate the effects of redeeming shares at the current block, given current on-chain conditions.
     * @param shares amount of shares to redeem
     * @return assets that will be returned
     */
    function previewRedeem(uint256 shares) public view override returns (uint256 assets) {
        uint256 _totalAssets = totalAssets();
        assets = _convertToAssets(shares, _totalAssets);
    }

    /**
     * @notice Finds the max amount of value an `owner` can remove from the cellar.
     * @param owner address of the user to find max value.
     * @param inShares if false, then returns value in terms of assets
     *                 if true then returns value in terms of shares
     */
    function _findMax(address owner, bool inShares) internal view returns (uint256 maxOut) {
        _checkIfPaused();
        // Check if owner shares are locked, return 0 if so.
        uint256 lockTime = userShareLockStartTime[owner];
        if (lockTime != 0) {
            uint256 timeSharesAreUnlocked = lockTime + shareLockPeriod;
            if (timeSharesAreUnlocked > block.timestamp) return 0;
        }
        // Get amount of assets to withdraw.
        uint256 _totalAssets = _accounting(false);
        uint256 assets = _convertToAssets(balanceOf[owner], _totalAssets);

        uint256 withdrawable = _accounting(true);
        maxOut = assets <= withdrawable ? assets : withdrawable;

        if (inShares) maxOut = _convertToShares(maxOut, _totalAssets);
        // else leave maxOut in terms of assets.
    }

    /**
     * @notice Returns the max amount withdrawable by a user inclusive of performance fees
     * @dev EIP4626 states maxWithdraw must not revert, but it is possible for `totalAssets` to revert
     * so it does NOT conform to ERC4626 standards.
     * @param owner address to check maxWithdraw of.
     * @return the max amount of assets withdrawable by `owner`.
     */
    function maxWithdraw(address owner) public view override returns (uint256) {
        require(locked == 1, "REENTRANCY");
        return _findMax(owner, false);
    }

    /**
     * @notice Returns the max amount shares redeemable by a user
     * @dev EIP4626 states maxRedeem must not revert, but it is possible for `totalAssets` to revert
     * so it does NOT conform to ERC4626 standards.
     * @param owner address to check maxRedeem of.
     * @return the max amount of shares redeemable by `owner`.
     */
    function maxRedeem(address owner) public view override returns (uint256) {
        require(locked == 1, "REENTRANCY");
        return _findMax(owner, true);
    }

    /**
     * @dev Used to more efficiently convert amount of shares to assets using a stored `totalAssets` value.
     */
    function _convertToAssets(uint256 shares, uint256 _totalAssets) internal view returns (uint256 assets) {
        uint256 totalShares = totalSupply;

        assets = totalShares == 0
            ? shares.changeDecimals(18, asset.decimals())
            : shares.mulDivDown(_totalAssets, totalShares);
    }

    /**
     * @dev Used to more efficiently convert amount of assets to shares using a stored `totalAssets` value.
     */
    function _convertToShares(uint256 assets, uint256 _totalAssets) internal view returns (uint256 shares) {
        uint256 totalShares = totalSupply;

        shares = totalShares == 0
            ? assets.changeDecimals(asset.decimals(), 18)
            : assets.mulDivDown(totalShares, _totalAssets);
    }

    /**
     * @dev Used to more efficiently simulate minting shares using a stored `totalAssets` value.
     */
    function _previewMint(uint256 shares, uint256 _totalAssets) internal view returns (uint256 assets) {
        uint256 totalShares = totalSupply;

        assets = totalShares == 0
            ? shares.changeDecimals(18, asset.decimals())
            : shares.mulDivUp(_totalAssets, totalShares);
    }

    /**
     * @dev Used to more efficiently simulate withdrawing assets using a stored `totalAssets` value.
     */
    function _previewWithdraw(uint256 assets, uint256 _totalAssets) internal view returns (uint256 shares) {
        uint256 totalShares = totalSupply;

        shares = totalShares == 0
            ? assets.changeDecimals(asset.decimals(), 18)
            : assets.mulDivUp(totalShares, _totalAssets);
    }

    // =========================================== ADAPTOR LOGIC ===========================================

    /**
     * @notice Emitted on when the rebalance deviation is changed.
     * @param oldDeviation the old rebalance deviation
     * @param newDeviation the new rebalance deviation
     */
    event RebalanceDeviationChanged(uint256 oldDeviation, uint256 newDeviation);

    /**
     * @notice totalAssets deviated outside the range set by `allowedRebalanceDeviation`.
     * @param assets the total assets in the cellar
     * @param min the minimum allowed assets
     * @param max the maximum allowed assets
     */
    error Cellar__TotalAssetDeviatedOutsideRange(uint256 assets, uint256 min, uint256 max);

    /**
     * @notice Total shares in a cellar changed when they should stay constant.
     * @param current the current amount of total shares
     * @param expected the expected amount of total shares
     */
    error Cellar__TotalSharesMustRemainConstant(uint256 current, uint256 expected);

    /**
     * @notice Total shares in a cellar changed when they should stay constant.
     * @param requested the requested rebalance  deviation
     * @param max the max rebalance deviation.
     */
    error Cellar__InvalidRebalanceDeviation(uint256 requested, uint256 max);

    /**
     * @notice Strategist attempted to use an adaptor that is either paused or is not trusted by governance.
     * @param adaptor the adaptor address that is paused or not trusted.
     */
    error Cellar__CallToAdaptorNotAllowed(address adaptor);

    /**
     * @notice Stores the max possible rebalance deviation for this cellar.
     */
    uint64 public constant MAX_REBALANCE_DEVIATION = 0.1e18;

    /**
     * @notice The percent the total assets of a cellar may deviate during a `callOnAdaptor`(rebalance) call.
     */
    uint256 public allowedRebalanceDeviation = 0.0003e18;

    /**
     * @notice Allows governance to change this cellars rebalance deviation.
     * @param newDeviation the new rebalance deviation value.
     */
    function setRebalanceDeviation(uint256 newDeviation) external onlyOwner {
        if (newDeviation > MAX_REBALANCE_DEVIATION)
            revert Cellar__InvalidRebalanceDeviation(newDeviation, MAX_REBALANCE_DEVIATION);

        uint256 oldDeviation = allowedRebalanceDeviation;
        allowedRebalanceDeviation = newDeviation;

        emit RebalanceDeviationChanged(oldDeviation, newDeviation);
    }

    // Set to true before any adaptor calls are made.
    /**
     * @notice This bool is used to stop strategists from abusing Base Adaptor functions(deposit/withdraw).
     */
    bool public blockExternalReceiver;

    /**
     * @notice Struct used to make calls to adaptors.
     * @param adaptor the address of the adaptor to make calls to
     * @param the abi encoded function calls to make to the `adaptor`
     */
    struct AdaptorCall {
        address adaptor;
        bytes[] callData;
    }

    event AdaptorCalled(address adaptor, bytes data);

    /**
     * @notice Allows strategists to manage their Cellar using arbitrary logic calls to adaptors.
     * @dev There are several safety checks in this function to prevent strategists from abusing it.
     *      - `blockExternalReceiver`
     *      - `totalAssets` must not change by much
     *      - `totalShares` must remain constant
     *      - adaptors must be set up to be used with this cellar
     * @dev Since `totalAssets` is allowed to deviate slightly, strategists could abuse this by sending
     *      multiple `callOnAdaptor` calls rapidly, to gradually change the share price.
     *      To mitigate this, rate limiting will be put in place on the Sommelier side.
     */
    function callOnAdaptor(AdaptorCall[] memory data) external onlyOwner nonReentrant {
        _whenNotShutdown();
        _checkIfPaused();
        blockExternalReceiver = true;

        // Record `totalAssets` and `totalShares` before making any external calls.
        uint256 minimumAllowedAssets;
        uint256 maximumAllowedAssets;
        uint256 totalShares;
        {
            uint256 assetsBeforeAdaptorCall = _accounting(false);
            minimumAllowedAssets = assetsBeforeAdaptorCall.mulDivUp((1e18 - allowedRebalanceDeviation), 1e18);
            maximumAllowedAssets = assetsBeforeAdaptorCall.mulDivUp((1e18 + allowedRebalanceDeviation), 1e18);
            totalShares = totalSupply;
        }

        // Run all adaptor calls.
        for (uint8 i = 0; i < data.length; ++i) {
            address adaptor = data[i].adaptor;
            // Revert if adaptor not in catalogue, or adaptor is paused.
            if (!adaptorCatalogue[adaptor]) revert Cellar__CallToAdaptorNotAllowed(adaptor);
            for (uint8 j = 0; j < data[i].callData.length; j++) {
                adaptor.functionDelegateCall(data[i].callData[j]);
                emit AdaptorCalled(adaptor, data[i].callData[j]);
            }
        }

        // After making every external call, check that the totalAssets haas not deviated significantly, and that totalShares is the same.
        uint256 assets = _accounting(false);
        if (assets < minimumAllowedAssets || assets > maximumAllowedAssets) {
            revert Cellar__TotalAssetDeviatedOutsideRange(assets, minimumAllowedAssets, maximumAllowedAssets);
        }
        if (totalShares != totalSupply) revert Cellar__TotalSharesMustRemainConstant(totalSupply, totalShares);

        blockExternalReceiver = false;
    }

    // ========================================= Aave Flash Loan Support =========================================

    /**
     * @notice External contract attempted to initiate a flash loan.
     */
    error Cellar__ExternalInitiator();

    /**
     * @notice executeOperation was not called by the Aave Pool.
     */
    error Cellar__CallerNotAavePool();

    /**
     * @notice The Aave V2 Pool contract on Ethereum Mainnet.
     */
    address public aavePool = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

    /**
     * @notice Allows strategist to utilize Aave flashloans while rebalancing the cellar.
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        if (initiator != address(this)) revert Cellar__ExternalInitiator();
        if (msg.sender != aavePool) revert Cellar__CallerNotAavePool();

        AdaptorCall[] memory data = abi.decode(params, (AdaptorCall[]));

        // Run all adaptor calls.
        for (uint8 i = 0; i < data.length; ++i) {
            address adaptor = data[i].adaptor;
            // Revert if adaptor not in catalogue, or adaptor is paused.
            if (!adaptorCatalogue[adaptor]) revert Cellar__CallToAdaptorNotAllowed(adaptor);
            for (uint8 j = 0; j < data[i].callData.length; j++) {
                adaptor.functionDelegateCall(data[i].callData[j]);
            }
        }

        // Approve pool to repay all debt.
        for (uint256 i = 0; i < amounts.length; ++i) {
            ERC20(assets[i]).safeApprove(aavePool, (amounts[i] + premiums[i]));
        }

        return true;
    }

    // ============================================ LIMITS LOGIC ============================================

    /**
     * @notice Total amount of assets that can be deposited for a user.
     * @return assets maximum amount of assets that can be deposited
     */
    function maxDeposit(address) public view override returns (uint256) {
        if (isShutdown) return 0;

        return type(uint256).max;
    }

    /**
     * @notice Total amount of shares that can be minted for a user.
     * @return shares maximum amount of shares that can be minted
     */
    function maxMint(address) public view override returns (uint256) {
        if (isShutdown) return 0;

        return type(uint256).max;
    }

    // ========================================== HELPER FUNCTIONS ==========================================

    /**
     * @dev Deposit into a position according to its position type and update related state.
     * @param position address to deposit funds into
     * @param assets the amount of assets to deposit into the position
     */
    function _depositTo(uint32 position, uint256 assets) internal {
        address adaptor = getPositionData[position].adaptor;
        adaptor.functionDelegateCall(
            abi.encodeWithSelector(
                BaseAdaptor.deposit.selector,
                assets,
                getPositionData[position].adaptorData,
                getPositionData[position].configurationData
            )
        );
    }

    /**
     * @dev Withdraw from a position according to its position type and update related state.
     * @param position address to withdraw funds from
     * @param assets the amount of assets to withdraw from the position
     * @param receiver the address to sent withdrawn assets to
     */
    function _withdrawFrom(uint32 position, uint256 assets, address receiver) internal {
        address adaptor = getPositionData[position].adaptor;
        adaptor.functionDelegateCall(
            abi.encodeWithSelector(
                BaseAdaptor.withdraw.selector,
                assets,
                receiver,
                getPositionData[position].adaptorData,
                getPositionData[position].configurationData
            )
        );
    }

    /**
     * @dev Get the withdrawable balance of a position according to its position type.
     * @param position position to get the withdrawable balance of
     */
    function _withdrawableFrom(uint32 position) internal view returns (uint256) {
        // Debt positions always return 0 for their withdrawable.
        if (getPositionData[position].isDebt) return 0;
        return
            BaseAdaptor(getPositionData[position].adaptor).withdrawableFrom(
                getPositionData[position].adaptorData,
                getPositionData[position].configurationData
            );
    }

    /**
     * @dev Get the balance of a position according to its position type.
     * @dev For ERC4626 position balances, this uses `previewRedeem` as opposed
     *      to `convertToAssets` so that balanceOf ERC4626 positions includes fees taken on withdraw.
     * @param position position to get the balance of
     */
    function _balanceOf(uint32 position) internal view returns (uint256) {
        address adaptor = getPositionData[position].adaptor;
        return BaseAdaptor(adaptor).balanceOf(getPositionData[position].adaptorData);
    }

    /**
     * @dev Get the asset of a position according to its position type.
     * @param position to get the asset of
     */
    function _assetOf(uint32 position) internal view returns (ERC20) {
        address adaptor = getPositionData[position].adaptor;
        return BaseAdaptor(adaptor).assetOf(getPositionData[position].adaptorData);
    }

    /**
     * @notice Get all the credit positions underlying assets.
     */
    function getPositionAssets() external view returns (ERC20[] memory assets) {
        assets = new ERC20[](creditPositions.length);
        for (uint256 i = 0; i < creditPositions.length; ++i) {
            assets[i] = _assetOf(creditPositions[i]);
        }
    }

    function viewPositionBalances()
        external
        view
        returns (ERC20[] memory assets, uint256[] memory balances, bool[] memory isDebt)
    {
        uint256 creditLen = creditPositions.length;
        uint256 debtLen = debtPositions.length;
        assets = new ERC20[](creditLen + debtLen);
        balances = new uint256[](creditLen + debtLen);
        isDebt = new bool[](creditLen + debtLen);
        for (uint256 i = 0; i < creditLen; ++i) {
            assets[i] = _assetOf(creditPositions[i]);
            balances[i] = _balanceOf(creditPositions[i]);
            isDebt[i] = false;
        }

        for (uint256 i = 0; i < debtLen; ++i) {
            assets[i + creditPositions.length] = _assetOf(debtPositions[i]);
            balances[i + creditPositions.length] = _balanceOf(debtPositions[i]);
            isDebt[i + creditPositions.length] = true;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { ERC20, SafeTransferLib } from "src/base/ERC4626.sol";
import { Multicall } from "src/base/Multicall.sol";
import { IUniswapV2Router02 as IUniswapV2Router } from "src/interfaces/external/IUniswapV2Router02.sol";
import { IUniswapV3Router } from "src/interfaces/external/IUniswapV3Router.sol";

/**
 * @title Sommelier Swap Router
 * @notice Provides a universal interface allowing Sommelier contracts to interact with multiple
 *         different exchanges to perform swaps.
 * @dev Perform multiple swaps using Multicall.
 * @author crispymangoes, Brian Le
 */
contract SwapRouter is Multicall {
    using SafeTransferLib for ERC20;

    /**
     * @param UNIV2 Uniswap V2
     * @param UNIV3 Uniswap V3
     */
    enum Exchange {
        UNIV2,
        UNIV3
    }

    /**
     * @notice Get the selector of the function to call in order to perform swap with a given exchange.
     */
    mapping(Exchange => bytes4) public getExchangeSelector;

    // ========================================== CONSTRUCTOR ==========================================

    /**
     * @notice Uniswap V2 swap router contract.
     */
    IUniswapV2Router public immutable uniswapV2Router; // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    /**
     * @notice Uniswap V3 swap router contract.
     */
    IUniswapV3Router public immutable uniswapV3Router; // 0xE592427A0AEce92De3Edee1F18E0157C05861564

    /**
     * @param _uniswapV2Router address of the Uniswap V2 swap router contract
     * @param _uniswapV3Router address of the Uniswap V3 swap router contract
     */
    constructor(IUniswapV2Router _uniswapV2Router, IUniswapV3Router _uniswapV3Router) {
        // Set up all exchanges.
        uniswapV2Router = _uniswapV2Router;
        uniswapV3Router = _uniswapV3Router;

        // Set up mapping between IDs and selectors.
        getExchangeSelector[Exchange.UNIV2] = SwapRouter(this).swapWithUniV2.selector;
        getExchangeSelector[Exchange.UNIV3] = SwapRouter(this).swapWithUniV3.selector;
    }

    // ======================================= SWAP OPERATIONS =======================================

    /**
     * @notice Attempted to perform a swap that reverted without a message.
     */
    error SwapRouter__SwapReverted();

    /**
     * @notice Attempted to perform a swap with mismatched assetIn and swap data.
     * @param actual the address encoded into the swap data
     * @param expected the address passed in with assetIn
     */
    error SwapRouter__AssetInMisMatch(address actual, address expected);

    /**
     * @notice Attempted to perform a swap with mismatched assetOut and swap data.
     * @param actual the address encoded into the swap data
     * @param expected the address passed in with assetIn
     */
    error SwapRouter__AssetOutMisMatch(address actual, address expected);

    /**
     * @notice Perform a swap using a supported exchange.
     * @param exchange value dictating which exchange to use to make the swap
     * @param swapData encoded data used for the swap
     * @param receiver address to send the received assets to
     * @return amountOut amount of assets received from the swap
     */
    function swap(
        Exchange exchange,
        bytes memory swapData,
        address receiver,
        ERC20 assetIn,
        ERC20 assetOut
    ) external returns (uint256 amountOut) {
        // Route swap call to appropriate function using selector.
        (bool success, bytes memory result) = address(this).delegatecall(
            abi.encodeWithSelector(getExchangeSelector[exchange], swapData, receiver, assetIn, assetOut)
        );

        if (!success) {
            // If there is return data, the call reverted with a reason or a custom error so we
            // bubble up the error message.
            if (result.length > 0) {
                assembly {
                    let returndata_size := mload(result)
                    revert(add(32, result), returndata_size)
                }
            } else {
                revert SwapRouter__SwapReverted();
            }
        }

        amountOut = abi.decode(result, (uint256));
    }

    /**
     * @notice Perform a swap using Uniswap V2.
     * @param swapData bytes variable storing the following swap information:
     *      address[] path: array of addresses dictating what swap path to follow
     *      uint256 amount: amount of the first asset in the path to swap
     *      uint256 amountOutMin: the minimum amount of the last asset in the path to receive
     * @param receiver address to send the received assets to
     * @return amountOut amount of assets received from the swap
     */
    function swapWithUniV2(
        bytes memory swapData,
        address receiver,
        ERC20 assetIn,
        ERC20 assetOut
    ) public returns (uint256 amountOut) {
        (address[] memory path, uint256 amount, uint256 amountOutMin) = abi.decode(
            swapData,
            (address[], uint256, uint256)
        );

        // Check that path matches assetIn and assetOut.
        if (assetIn != ERC20(path[0])) revert SwapRouter__AssetInMisMatch(path[0], address(assetIn));
        if (assetOut != ERC20(path[path.length - 1]))
            revert SwapRouter__AssetOutMisMatch(path[path.length - 1], address(assetOut));

        // Transfer assets to this contract to swap.
        assetIn.safeTransferFrom(msg.sender, address(this), amount);

        // Approve assets to be swapped through the router.
        assetIn.safeApprove(address(uniswapV2Router), amount);

        // Execute the swap.
        uint256[] memory amountsOut = uniswapV2Router.swapExactTokensForTokens(
            amount,
            amountOutMin,
            path,
            receiver,
            block.timestamp + 60
        );

        amountOut = amountsOut[amountsOut.length - 1];

        _checkApprovalIsZero(assetIn, address(uniswapV2Router));
    }

    /**
     * @notice Perform a swap using Uniswap V3.
     * @param swapData bytes variable storing the following swap information
     *      address[] path: array of addresses dictating what swap path to follow
     *      uint24[] poolFees: array of pool fees dictating what swap pools to use
     *      uint256 amount: amount of the first asset in the path to swap
     *      uint256 amountOutMin: the minimum amount of the last asset in the path to receive
     * @param receiver address to send the received assets to
     * @return amountOut amount of assets received from the swap
     */
    function swapWithUniV3(
        bytes memory swapData,
        address receiver,
        ERC20 assetIn,
        ERC20 assetOut
    ) public returns (uint256 amountOut) {
        (address[] memory path, uint24[] memory poolFees, uint256 amount, uint256 amountOutMin) = abi.decode(
            swapData,
            (address[], uint24[], uint256, uint256)
        );

        // Check that path matches assetIn and assetOut.
        if (assetIn != ERC20(path[0])) revert SwapRouter__AssetInMisMatch(path[0], address(assetIn));
        if (assetOut != ERC20(path[path.length - 1]))
            revert SwapRouter__AssetOutMisMatch(path[path.length - 1], address(assetOut));

        // Transfer assets to this contract to swap.
        assetIn.safeTransferFrom(msg.sender, address(this), amount);

        // Approve assets to be swapped through the router.
        assetIn.safeApprove(address(uniswapV3Router), amount);

        // Encode swap parameters.
        bytes memory encodePackedPath = abi.encodePacked(address(assetIn));
        for (uint256 i = 1; i < path.length; i++)
            encodePackedPath = abi.encodePacked(encodePackedPath, poolFees[i - 1], path[i]);

        // Execute the swap.
        amountOut = uniswapV3Router.exactInput(
            IUniswapV3Router.ExactInputParams({
                path: encodePackedPath,
                recipient: receiver,
                deadline: block.timestamp + 60,
                amountIn: amount,
                amountOutMinimum: amountOutMin
            })
        );

        _checkApprovalIsZero(assetIn, address(uniswapV3Router));
    }

    // ======================================= HELPER FUNCTIONS =======================================
    /**
     * @notice Emitted when a swap does not use all the assets swap router approved.
     */
    error SwapRouter__UnusedApproval();

    /**
     * @notice Helper function that reverts if the Swap Router has unused approval after a swap is made.
     */
    function _checkApprovalIsZero(ERC20 asset, address spender) internal view {
        if (asset.allowance(address(this), spender) != 0) revert SwapRouter__UnusedApproval();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { ERC20, SafeTransferLib } from "src/base/ERC4626.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IChainlinkAggregator } from "src/interfaces/external/IChainlinkAggregator.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Math } from "src/utils/Math.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Extension } from "src/modules/price-router/Extensions/Extension.sol";
import { Registry } from "src/Registry.sol";

import { UniswapV3Pool } from "src/interfaces/external/UniswapV3Pool.sol";
import { OracleLibrary } from "@uniswapV3P/libraries/OracleLibrary.sol";

/**
 * @title Sommelier Price Router
 * @notice Provides a universal interface allowing Sommelier contracts to retrieve secure pricing
 *         data from Chainlink.
 * @author crispymangoes
 */
contract PriceRouter is Ownable {
    using SafeTransferLib for ERC20;
    using SafeCast for int256;
    using Math for uint256;
    using Address for address;

    event AddAsset(address indexed asset);

    event IntentToEditAsset(
        address asset,
        AssetSettings _settings,
        bytes _storage,
        bytes32 editHash,
        uint256 assetEditableAt
    );

    event EditAssetCancelled(address asset, bytes32 editHash);

    event EditAssetComplete(address asset, bytes32 editHash);

    Registry public immutable registry;

    constructor(Registry _registry) {
        registry = _registry;
    }

    // =========================================== ASSETS CONFIG ===========================================
    /**
     * @notice Bare minimum settings all derivatives support.
     * @param derivative the derivative used to price the asset
     * @param source the address used to price the asset
     */
    struct AssetSettings {
        uint8 derivative;
        address source;
    }

    /**
     * @notice Mapping between an asset to price and its `AssetSettings`.
     */
    mapping(ERC20 => AssetSettings) public getAssetSettings;

    // ======================================= OWNERSHIP TRANSISITION =======================================

    /**
     * @notice Emitted when an ownership transition is started.
     */
    event OwnerTransitionStarted(address newOwner, uint256 startTime);

    /**
     * @notice Emitted when an ownership transition is cancelled.
     */
    event OwnerTransitionCancelled();

    /**
     * @notice Emitted when an ownership transition is completed.
     */
    event OwnerTransitionComplete(address newOwner);

    /**
     * @notice Attempted to call a function intended for Zero Id address.
     */
    error PriceRouter__OnlyCallableByZeroId();

    /**
     * @notice Attempted to transition owner to the zero address.
     */
    error PriceRouter__NewOwnerCanNotBeZero();

    /**
     * @notice Attempted to perform a restricted action while ownership transition is pending.
     */
    error PriceRouter__TransitionPending();

    /**
     * @notice Attempted to cancel or complete a transition when one is not active.
     */
    error PriceRouter__TransitionNotPending();

    /**
     * @notice Attempted to call `completeTransition` from an address that is not the pending owner.
     */
    error PriceRouter__OnlyCallableByPendingOwner();

    /**
     * @notice The amount of time it takes for an ownership transition to work.
     */
    uint256 public constant TRANSITION_PERIOD = 7 days;

    /**
     * @notice The Pending Owner, that becomes the owner after the transition period, and they call `completeTransition`.
     */
    address public pendingOwner;

    /**
     * @notice The starting time stamp of the transition.
     */
    uint256 public transitionStart;

    /**
     * @notice Allows Zero Id address to set a new owner, after the transition period is up.
     */
    function transitionOwner(address newOwner) external {
        if (msg.sender != registry.getAddress(0)) revert PriceRouter__OnlyCallableByZeroId();
        if (pendingOwner != address(0)) revert PriceRouter__TransitionPending();
        if (newOwner == address(0)) revert PriceRouter__NewOwnerCanNotBeZero();

        pendingOwner = newOwner;
        transitionStart = block.timestamp;
    }

    /**
     * @notice Allows Zero Id address to cancel an ongoing owner transition.
     */
    function cancelTransition() external {
        if (msg.sender != registry.getAddress(0)) revert PriceRouter__OnlyCallableByZeroId();
        if (pendingOwner == address(0)) revert PriceRouter__TransitionNotPending();

        pendingOwner = address(0);
        transitionStart = 0;
    }

    /**
     * @notice Allows pending owner to complete the ownership transition.
     */
    function completeTransition() external {
        if (pendingOwner == address(0)) revert PriceRouter__TransitionNotPending();
        if (msg.sender != pendingOwner) revert PriceRouter__OnlyCallableByPendingOwner();
        if (block.timestamp < transitionStart + TRANSITION_PERIOD) revert PriceRouter__TransitionPending();

        _transferOwnership(pendingOwner);

        pendingOwner = address(0);
        transitionStart = 0;
    }

    /**
     * @notice Extends OZ Ownable `_checkOwner` function to block owner calls, if there is an ongoing transition.
     */
    function _checkOwner() internal view override {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        if (transitionStart != 0) revert PriceRouter__TransitionPending();
    }

    // ======================================= ASSET OPERATIONS =======================================

    /**
     * @notice Attempted to set a minimum price below the Chainlink minimum price (with buffer).
     * @param minPrice minimum price attempted to set
     * @param bufferedMinPrice minimum price that can be set including buffer
     */
    error PriceRouter__InvalidMinPrice(uint256 minPrice, uint256 bufferedMinPrice);

    /**
     * @notice Attempted to set a maximum price above the Chainlink maximum price (with buffer).
     * @param maxPrice maximum price attempted to set
     * @param bufferedMaxPrice maximum price that can be set including buffer
     */
    error PriceRouter__InvalidMaxPrice(uint256 maxPrice, uint256 bufferedMaxPrice);

    /**
     * @notice Attempted to add an invalid asset.
     * @param asset address of the invalid asset
     */
    error PriceRouter__InvalidAsset(address asset);

    /**
     * @notice Attempted to add an asset that is already supported.
     */
    error PriceRouter__AssetAlreadyAdded(address asset);

    /**
     * @notice Attempted to edit an asset that is not supported.
     */
    error PriceRouter__AssetNotAdded(address asset);

    /**
     * @notice Attempted to edit an asset that is not editable.
     */
    error PriceRouter__AssetNotEditable(address asset);

    /**
     * @notice Attempted to cancel the editing of an asset that is not pending edit.
     */
    error PriceRouter__AssetNotPendingEdit(address asset);

    /**
     * @notice Attempted to add an asset, but actual answer was outside range of expectedAnswer.
     */
    error PriceRouter__BadAnswer(uint256 answer, uint256 expectedAnswer);

    /**
     * @notice Attempted to perform an operation using an unknown derivative.
     */
    error PriceRouter__UnknownDerivative(uint8 unknownDerivative);

    /**
     * @notice Attempted to add an asset with invalid min/max prices.
     * @param min price
     * @param max price
     */
    error PriceRouter__MinPriceGreaterThanMaxPrice(uint256 min, uint256 max);

    /**
     * @notice The allowed deviation between the expected answer vs the actual answer.
     */
    uint256 public constant EXPECTED_ANSWER_DEVIATION = 0.02e18;

    /**
     * @notice The amount of time that must pass between owner calling `startEditAsset`, and `completeEditAsset`.
     */
    uint64 public constant EDIT_ASSET_DELAY = 7 days;

    /**
     * @notice Stores the timestamp when an asset can be editted.
     */
    mapping(bytes32 => uint256) public assetEditableTimestamp;

    /**
     * @notice Allows owner to add assets to the price router.
     * @dev Performs a sanity check by comparing the price router computed price to
     * a user input `_expectedAnswer`.
     * @param _asset the asset to add to the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     * @param _expectedAnswer the expected answer for the asset from  `_getPriceInUSD`
     */
    function addAsset(
        ERC20 _asset,
        AssetSettings memory _settings,
        bytes memory _storage,
        uint256 _expectedAnswer
    ) external onlyOwner {
        // Check that asset is not already added.
        if (getAssetSettings[_asset].derivative > 0) revert PriceRouter__AssetAlreadyAdded(address(_asset));

        _updateAsset(_asset, _settings, _storage, _expectedAnswer);

        emit AddAsset(address(_asset));
    }

    /**
     * @notice Allows owner to start the edit asset process.
     * @dev Saves a hash of the inputs, and maps it to the timestamp when `_asset` is editable.
     * @param _asset the asset to edit in the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     */
    function startEditAsset(ERC20 _asset, AssetSettings memory _settings, bytes memory _storage) external onlyOwner {
        // Make sure the asset has been added.
        if (getAssetSettings[_asset].derivative == 0) revert PriceRouter__AssetNotAdded(address(_asset));
        bytes32 editHash = keccak256(abi.encode(_asset, _settings, _storage));

        uint256 assetEditableAt = block.timestamp + EDIT_ASSET_DELAY;
        assetEditableTimestamp[editHash] = assetEditableAt;

        emit IntentToEditAsset(address(_asset), _settings, _storage, editHash, assetEditableAt);
    }

    /**
     * @notice Once `EDIT_ASSET_DELAY` has passed, `_asset` is now editable using the
     *         same inputs given to `startEditAsset`.
     * @param _asset the asset to finish editing in the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     */
    function completeEditAsset(
        ERC20 _asset,
        AssetSettings memory _settings,
        bytes memory _storage,
        uint256 _expectedAnswer
    ) external onlyOwner {
        bytes32 editHash = keccak256(abi.encode(_asset, _settings, _storage));

        // Make sure asset can be edited.
        uint256 assetEditableAt = assetEditableTimestamp[editHash];
        if (assetEditableAt == 0 || block.timestamp < assetEditableAt)
            revert PriceRouter__AssetNotEditable(address(_asset));

        // Reset edit timestamp.
        assetEditableTimestamp[editHash] = 0;

        // Edit the asset.
        _updateAsset(_asset, _settings, _storage, _expectedAnswer);

        emit EditAssetComplete(address(_asset), editHash);
    }

    /**
     * @notice Cancel a pending edit for `_asset`.
     * @param _asset the asset to cancel editing of in the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     */
    function cancelEditAsset(ERC20 _asset, AssetSettings memory _settings, bytes memory _storage) external onlyOwner {
        bytes32 editHash = keccak256(abi.encode(_asset, _settings, _storage));

        // Make sure asset is pending edit.
        uint256 assetEditableAt = assetEditableTimestamp[editHash];
        if (assetEditableAt == 0) revert PriceRouter__AssetNotPendingEdit(address(_asset));

        assetEditableTimestamp[editHash] = 0;

        emit EditAssetCancelled(address(_asset), editHash);
    }

    /**
     * @notice Helper function to update an `_asset`s configuration.
     * @param _asset the asset to update in the pricing router
     * @param _settings the settings for `_asset`
     *        @dev The `derivative` value in settings MUST be non zero.
     * @param _storage arbitrary bytes data used to configure `_asset` pricing
     */
    function _updateAsset(
        ERC20 _asset,
        AssetSettings memory _settings,
        bytes memory _storage,
        uint256 _expectedAnswer
    ) internal {
        if (address(_asset) == address(0)) revert PriceRouter__InvalidAsset(address(_asset));

        // Zero is an invalid derivative.
        if (_settings.derivative == 0) revert PriceRouter__UnknownDerivative(_settings.derivative);

        // Call setup function for appropriate derivative.
        if (_settings.derivative == 1) {
            _setupPriceForChainlinkDerivative(_asset, _settings.source, _storage);
        } else if (_settings.derivative == 2) {
            _setupPriceForTwapDerivative(_asset, _settings.source, _storage);
        } else if (_settings.derivative == 3) {
            Extension(_settings.source).setupSource(_asset, _storage);
        } else revert PriceRouter__UnknownDerivative(_settings.derivative);

        // Check `_getPriceInUSD` against `_expectedAnswer`.
        uint256 minAnswer = _expectedAnswer.mulWadDown((1e18 - EXPECTED_ANSWER_DEVIATION));
        uint256 maxAnswer = _expectedAnswer.mulWadDown((1e18 + EXPECTED_ANSWER_DEVIATION));

        getAssetSettings[_asset] = _settings;
        uint256 answer = _getPriceInUSD(_asset, _settings);
        if (answer < minAnswer || answer > maxAnswer) revert PriceRouter__BadAnswer(answer, _expectedAnswer);
    }

    /**
     * @notice return bool indicating whether or not an asset has been set up.
     * @dev Since `addAsset` enforces the derivative is non zero, checking if the stored setting
     *      is nonzero is sufficient to see if the asset is set up.
     */
    function isSupported(ERC20 asset) external view returns (bool) {
        return getAssetSettings[asset].derivative > 0;
    }

    // ======================================= PRICING OPERATIONS =======================================

    /**
     * @notice Get `asset` price in USD.
     * @dev Returns price in USD with 8 decimals.
     */
    function getPriceInUSD(ERC20 asset) external view returns (uint256) {
        AssetSettings memory assetSettings = getAssetSettings[asset];
        return _getPriceInUSD(asset, assetSettings);
    }

    /**
     * @notice Get multiple `asset` prices in USD.
     * @dev Returns array of prices in USD with 8 decimals.
     */
    function getPricesInUSD(ERC20[] calldata assets) external view returns (uint256[] memory prices) {
        prices = new uint256[](assets.length);
        for (uint256 i; i < assets.length; ++i) {
            AssetSettings memory assetSettings = getAssetSettings[assets[i]];
            prices[i] = _getPriceInUSD(assets[i], assetSettings);
        }
    }

    /**
     * @notice Get the value of an asset in terms of another asset.
     * @param baseAsset address of the asset to get the price of in terms of the quote asset
     * @param amount amount of the base asset to price
     * @param quoteAsset address of the asset that the base asset is priced in terms of
     * @return value value of the amount of base assets specified in terms of the quote asset
     */
    function getValue(ERC20 baseAsset, uint256 amount, ERC20 quoteAsset) external view returns (uint256 value) {
        AssetSettings memory baseSettings = getAssetSettings[baseAsset];
        AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
        if (baseSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(baseAsset));
        if (quoteSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(quoteAsset));
        uint256 priceBaseUSD = _getPriceInUSD(baseAsset, baseSettings);
        uint256 priceQuoteUSD = _getPriceInUSD(quoteAsset, quoteSettings);
        value = _getValueInQuote(priceBaseUSD, priceQuoteUSD, baseAsset.decimals(), quoteAsset.decimals(), amount);
    }

    /**
     * @notice Helper function that compares `_getValues` between input 0 and input 1.
     */
    function getValuesDelta(
        ERC20[] calldata baseAssets0,
        uint256[] calldata amounts0,
        ERC20[] calldata baseAssets1,
        uint256[] calldata amounts1,
        ERC20 quoteAsset
    ) external view returns (uint256) {
        uint256 value0 = _getValues(baseAssets0, amounts0, quoteAsset);
        uint256 value1 = _getValues(baseAssets1, amounts1, quoteAsset);
        return value0 - value1;
    }

    /**
     * @notice Helper function that determines the value of assets using `_getValues`.
     */
    function getValues(
        ERC20[] calldata baseAssets,
        uint256[] calldata amounts,
        ERC20 quoteAsset
    ) external view returns (uint256) {
        return _getValues(baseAssets, amounts, quoteAsset);
    }

    /**
     * @notice Get the exchange rate between two assets.
     * @param baseAsset address of the asset to get the exchange rate of in terms of the quote asset
     * @param quoteAsset address of the asset that the base asset is exchanged for
     * @return exchangeRate rate of exchange between the base asset and the quote asset
     */
    function getExchangeRate(ERC20 baseAsset, ERC20 quoteAsset) public view returns (uint256 exchangeRate) {
        AssetSettings memory baseSettings = getAssetSettings[baseAsset];
        AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
        if (baseSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(baseAsset));
        if (quoteSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(quoteAsset));

        exchangeRate = _getExchangeRate(baseAsset, baseSettings, quoteAsset, quoteSettings, quoteAsset.decimals());
    }

    /**
     * @notice Get the exchange rates between multiple assets and another asset.
     * @param baseAssets addresses of the assets to get the exchange rates of in terms of the quote asset
     * @param quoteAsset address of the asset that the base assets are exchanged for
     * @return exchangeRates rate of exchange between the base assets and the quote asset
     */
    function getExchangeRates(
        ERC20[] memory baseAssets,
        ERC20 quoteAsset
    ) external view returns (uint256[] memory exchangeRates) {
        uint8 quoteAssetDecimals = quoteAsset.decimals();
        AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
        if (quoteSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(quoteAsset));

        uint256 numOfAssets = baseAssets.length;
        exchangeRates = new uint256[](numOfAssets);
        for (uint256 i; i < numOfAssets; i++) {
            AssetSettings memory baseSettings = getAssetSettings[baseAssets[i]];
            if (baseSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(baseAssets[i]));
            exchangeRates[i] = _getExchangeRate(
                baseAssets[i],
                baseSettings,
                quoteAsset,
                quoteSettings,
                quoteAssetDecimals
            );
        }
    }

    // =========================================== HELPER FUNCTIONS ===========================================
    ERC20 private constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /**
     * @notice Attempted to update the asset to one that is not supported by the platform.
     * @param asset address of the unsupported asset
     */
    error PriceRouter__UnsupportedAsset(address asset);

    /**
     * @notice Gets the exchange rate between a base and a quote asset
     * @param baseAsset the asset to convert into quoteAsset
     * @param quoteAsset the asset base asset is converted into
     * @return exchangeRate value of base asset in terms of quote asset
     */
    function _getExchangeRate(
        ERC20 baseAsset,
        AssetSettings memory baseSettings,
        ERC20 quoteAsset,
        AssetSettings memory quoteSettings,
        uint8 quoteAssetDecimals
    ) internal view returns (uint256) {
        uint256 basePrice = _getPriceInUSD(baseAsset, baseSettings);
        uint256 quotePrice = _getPriceInUSD(quoteAsset, quoteSettings);
        uint256 exchangeRate = basePrice.mulDivDown(10 ** quoteAssetDecimals, quotePrice);
        return exchangeRate;
    }

    /**
     * @notice Helper function to get an assets price in USD.
     * @dev Returns price in USD with 8 decimals.
     */
    function _getPriceInUSD(ERC20 asset, AssetSettings memory settings) internal view returns (uint256) {
        // Call get price function using appropriate derivative.
        uint256 price;
        if (settings.derivative == 1) {
            price = _getPriceForChainlinkDerivative(asset, settings.source);
        } else if (settings.derivative == 2) {
            price = _getPriceForTwapDerivative(asset, settings.source);
        } else if (settings.derivative == 3) {
            price = Extension(settings.source).getPriceInUSD(asset);
        } else revert PriceRouter__UnknownDerivative(settings.derivative);

        return price;
    }

    /**
     * @notice math function that preserves precision by multiplying the amountBase before dividing.
     * @param priceBaseUSD the base asset price in USD
     * @param priceQuoteUSD the quote asset price in USD
     * @param baseDecimals the base asset decimals
     * @param quoteDecimals the quote asset decimals
     * @param amountBase the amount of base asset
     */
    function _getValueInQuote(
        uint256 priceBaseUSD,
        uint256 priceQuoteUSD,
        uint8 baseDecimals,
        uint8 quoteDecimals,
        uint256 amountBase
    ) internal pure returns (uint256 valueInQuote) {
        // Get value in quote asset, but maintain as much precision as possible.
        // Cleaner equations below.
        // baseToUSD = amountBase * priceBaseUSD / 10**baseDecimals.
        // valueInQuote = baseToUSD * 10**quoteDecimals / priceQuoteUSD
        valueInQuote = amountBase.mulDivDown(
            (priceBaseUSD * 10 ** quoteDecimals),
            (10 ** baseDecimals * priceQuoteUSD)
        );
    }

    /**
     * @notice Attempted an operation with arrays of unequal lengths that were expected to be equal length.
     */
    error PriceRouter__LengthMismatch();

    /**
     * @notice Get the total value of multiple assets in terms of another asset.
     * @param baseAssets addresses of the assets to get the price of in terms of the quote asset
     * @param amounts amounts of each base asset to price
     * @param quoteAsset address of the assets that the base asset is priced in terms of
     * @return value total value of the amounts of each base assets specified in terms of the quote asset
     */
    function _getValues(
        ERC20[] calldata baseAssets,
        uint256[] calldata amounts,
        ERC20 quoteAsset
    ) internal view returns (uint256) {
        if (baseAssets.length != amounts.length) revert PriceRouter__LengthMismatch();
        uint256 quotePrice;
        {
            AssetSettings memory quoteSettings = getAssetSettings[quoteAsset];
            if (quoteSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(quoteAsset));
            quotePrice = _getPriceInUSD(quoteAsset, quoteSettings);
        }
        uint256 valueInQuote;
        uint8 quoteDecimals = quoteAsset.decimals();

        for (uint8 i = 0; i < baseAssets.length; i++) {
            // Skip zero amount values.
            if (amounts[i] == 0) continue;
            ERC20 baseAsset = baseAssets[i];
            if (baseAsset == quoteAsset) valueInQuote += amounts[i];
            else {
                uint256 basePrice;
                {
                    AssetSettings memory baseSettings = getAssetSettings[baseAsset];
                    if (baseSettings.derivative == 0) revert PriceRouter__UnsupportedAsset(address(baseAsset));
                    basePrice = _getPriceInUSD(baseAsset, baseSettings);
                }
                valueInQuote += _getValueInQuote(
                    basePrice,
                    quotePrice,
                    baseAsset.decimals(),
                    quoteDecimals,
                    amounts[i]
                );
            }
        }
        return valueInQuote;
    }

    // =========================================== CHAINLINK PRICE DERIVATIVE ===========================================\
    /**
     * @notice Stores data for Chainlink derivative assets.
     * @param max the max valid price of the asset
     * @param min the min valid price of the asset
     * @param heartbeat the max amount of time between price updates
     * @param inETH bool indicating whether the price feed is
     *        denominated in ETH(true) or USD(false)
     */
    struct ChainlinkDerivativeStorage {
        uint144 max;
        uint80 min;
        uint24 heartbeat;
        bool inETH;
    }

    /**
     * @notice Buffered min price exceedes 80 bits of data.
     */
    error PriceRouter__BufferedMinOverflow();

    /**
     * @notice Returns Chainlink Derivative Storage
     */
    mapping(ERC20 => ChainlinkDerivativeStorage) public getChainlinkDerivativeStorage;

    /**
     * @notice If zero is specified for a Chainlink asset heartbeat, this value is used instead.
     */
    uint24 public constant DEFAULT_HEART_BEAT = 1 days;

    /**
     * @notice Setup function for pricing Chainlink derivative assets.
     * @dev _source The address of the Chainlink Data feed.
     * @dev _storage A ChainlinkDerivativeStorage value defining valid prices.
     */
    function _setupPriceForChainlinkDerivative(ERC20 _asset, address _source, bytes memory _storage) internal {
        ChainlinkDerivativeStorage memory parameters = abi.decode(_storage, (ChainlinkDerivativeStorage));

        // Use Chainlink to get the min and max of the asset.
        IChainlinkAggregator aggregator = IChainlinkAggregator(IChainlinkAggregator(_source).aggregator());
        uint256 minFromChainklink = uint256(uint192(aggregator.minAnswer()));
        uint256 maxFromChainlink = uint256(uint192(aggregator.maxAnswer()));

        // Add a ~10% buffer to minimum and maximum price from Chainlink because Chainlink can stop updating
        // its price before/above the min/max price.
        uint256 bufferedMinPrice = (minFromChainklink * 1.1e18) / 1e18;
        uint256 bufferedMaxPrice = (maxFromChainlink * 0.9e18) / 1e18;

        if (parameters.min == 0) {
            // Revert if bufferedMinPrice overflows because uint80 is too small to hold the minimum price,
            // and lowering it to uint80 is not safe because the price feed can stop being updated before
            // it actually gets to that lower price.
            if (bufferedMinPrice > type(uint80).max) revert PriceRouter__BufferedMinOverflow();
            parameters.min = uint80(bufferedMinPrice);
        } else {
            if (parameters.min < bufferedMinPrice)
                revert PriceRouter__InvalidMinPrice(parameters.min, bufferedMinPrice);
        }

        if (parameters.max == 0) {
            //Do not revert even if bufferedMaxPrice is greater than uint144, because lowering it to uint144 max is more conservative.
            parameters.max = bufferedMaxPrice > type(uint144).max ? type(uint144).max : uint144(bufferedMaxPrice);
        } else {
            if (parameters.max > bufferedMaxPrice)
                revert PriceRouter__InvalidMaxPrice(parameters.max, bufferedMaxPrice);
        }

        if (parameters.min >= parameters.max)
            revert PriceRouter__MinPriceGreaterThanMaxPrice(parameters.min, parameters.max);

        parameters.heartbeat = parameters.heartbeat != 0 ? parameters.heartbeat : DEFAULT_HEART_BEAT;

        getChainlinkDerivativeStorage[_asset] = parameters;
    }

    /**
     * @notice Get the price of a Chainlink derivative in terms of USD.
     */
    function _getPriceForChainlinkDerivative(ERC20 _asset, address _source) internal view returns (uint256) {
        ChainlinkDerivativeStorage memory parameters = getChainlinkDerivativeStorage[_asset];
        IChainlinkAggregator aggregator = IChainlinkAggregator(_source);
        (, int256 _price, , uint256 _timestamp, ) = aggregator.latestRoundData();
        uint256 price = _price.toUint256();
        _checkPriceFeed(address(_asset), price, _timestamp, parameters.max, parameters.min, parameters.heartbeat);
        // If price is in ETH, then convert price into USD.
        if (parameters.inETH) {
            uint256 _ethToUsd = _getPriceInUSD(WETH, getAssetSettings[WETH]);
            price = price.mulWadDown(_ethToUsd);
        }
        return price;
    }

    /**
     * @notice Attempted an operation to price an asset that under its minimum valid price.
     * @param asset address of the asset that is under its minimum valid price
     * @param price price of the asset
     * @param minPrice minimum valid price of the asset
     */
    error PriceRouter__AssetBelowMinPrice(address asset, uint256 price, uint256 minPrice);

    /**
     * @notice Attempted an operation to price an asset that under its maximum valid price.
     * @param asset address of the asset that is under its maximum valid price
     * @param price price of the asset
     * @param maxPrice maximum valid price of the asset
     */
    error PriceRouter__AssetAboveMaxPrice(address asset, uint256 price, uint256 maxPrice);

    /**
     * @notice Attempted to fetch a price for an asset that has not been updated in too long.
     * @param asset address of the asset thats price is stale
     * @param timeSinceLastUpdate seconds since the last price update
     * @param heartbeat maximum allowed time between price updates
     */
    error PriceRouter__StalePrice(address asset, uint256 timeSinceLastUpdate, uint256 heartbeat);

    /**
     * @notice helper function to validate a price feed is safe to use.
     * @param asset ERC20 asset price feed data is for.
     * @param value the price value the price feed gave.
     * @param timestamp the last timestamp the price feed was updated.
     * @param max the upper price bound
     * @param min the lower price bound
     * @param heartbeat the max amount of time between price updates
     */
    function _checkPriceFeed(
        address asset,
        uint256 value,
        uint256 timestamp,
        uint144 max,
        uint88 min,
        uint24 heartbeat
    ) internal view {
        if (value < min) revert PriceRouter__AssetBelowMinPrice(address(asset), value, min);

        if (value > max) revert PriceRouter__AssetAboveMaxPrice(address(asset), value, max);

        uint256 timeSinceLastUpdate = block.timestamp - timestamp;
        if (timeSinceLastUpdate > heartbeat)
            revert PriceRouter__StalePrice(address(asset), timeSinceLastUpdate, heartbeat);
    }

    // =========================================== TWAP PRICE DERIVATIVE ===========================================

    /**
     * @notice Stores data for Twap derivative assets.
     * @param secondsAgo the twap duration
     * @param baseDecimals the base assets decimals
     * @param quoteDecimals the quote assets decimals
     * @param quoteToken the asset the twap quotes in
     */
    struct TwapDerivativeStorage {
        uint32 secondsAgo;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        ERC20 quoteToken;
    }

    /**
     * @notice Tried setting up a Twap for an asset where the underlying pools does not use the asset.
     */
    error PriceRouter__TwapAssetNotInPool();

    /**
     * @notice Provided secondsAgo does not meet minimum,
     */
    error PriceRouter__SecondsAgoDoesNotMeetMinimum();

    /**
     * @notice Returns Twap Derivative Storage
     */
    mapping(ERC20 => TwapDerivativeStorage) public getTwapDerivativeStorage;

    /**
     * @notice The smallest possible TWAP that can be used.
     */
    uint32 public constant MINIMUM_SECONDS_AGO = 900;

    /**
     * @notice Setup function for pricing Twap derivative assets.
     * @dev Make sure that TWAP assets have sufficient observations, and increase them if not before adding.
     * @dev _source The address of the Uniswap V3 pool.
     * @dev _storage A TwapDerivativeStorage value defining valid prices.
     */
    function _setupPriceForTwapDerivative(ERC20 _asset, address _source, bytes memory _storage) internal {
        TwapDerivativeStorage memory parameters = abi.decode(_storage, (TwapDerivativeStorage));

        // Verify seconds ago is reasonable.
        if (parameters.secondsAgo < MINIMUM_SECONDS_AGO) revert PriceRouter__SecondsAgoDoesNotMeetMinimum();

        UniswapV3Pool pool = UniswapV3Pool(_source);

        ERC20 token0 = ERC20(pool.token0());
        ERC20 token1 = ERC20(pool.token1());
        if (token0 == _asset) {
            parameters.baseDecimals = _asset.decimals();
            parameters.quoteDecimals = token1.decimals();
            parameters.quoteToken = token1;
        } else if (token1 == _asset) {
            parameters.baseDecimals = _asset.decimals();
            parameters.quoteDecimals = token0.decimals();
            parameters.quoteToken = token0;
        } else revert PriceRouter__TwapAssetNotInPool();

        getTwapDerivativeStorage[_asset] = parameters;
    }

    /**
     * @notice Get the price of a Twap derivative in terms of USD.
     */
    function _getPriceForTwapDerivative(ERC20 asset, address _source) internal view returns (uint256) {
        TwapDerivativeStorage memory parameters = getTwapDerivativeStorage[asset];
        (int24 arithmeticMeanTick, ) = OracleLibrary.consult(_source, parameters.secondsAgo);
        // Get the amount of quote token each base token is worth.
        uint256 quoteAmount = OracleLibrary.getQuoteAtTick(
            arithmeticMeanTick,
            uint128(10 ** parameters.baseDecimals),
            address(asset),
            address(parameters.quoteToken)
        );
        uint256 quotePrice = _getPriceInUSD(parameters.quoteToken, getAssetSettings[parameters.quoteToken]);
        return quoteAmount.mulDivDown(quotePrice, 10 ** parameters.quoteDecimals);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal INITIAL_CHAIN_ID;

    bytes32 internal INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

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

    /*//////////////////////////////////////////////////////////////
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

import { ERC20 } from "src/base/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

library Math {
    /**
     * @notice Substract with a floor of 0 for the result.
     */
    function subMinZero(uint256 x, uint256 y) internal pure returns (uint256) {
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
            return amount / 10**(fromDecimals - toDecimals);
        }
    }

    // ===================================== OPENZEPPELIN'S MATH =====================================

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity 0.8.16;

interface IGravity {
    function sendToCosmos(
        address _tokenContract,
        bytes32 _destination,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

/**
 * @notice A library to extend the uint32 array data type.
 */
library Uint32Array {
    // =========================================== ADDRESS STORAGE ===========================================

    /**
     * @notice Add an uint32 to the array at a given index.
     * @param array uint32 array to add the uint32 to
     * @param index index to add the uint32 at
     * @param value uint32 to add to the array
     */
    function add(
        uint32[] storage array,
        uint32 index,
        uint32 value
    ) internal {
        uint256 len = array.length;

        if (len > 0) {
            array.push(array[len - 1]);

            for (uint256 i = len - 1; i > index; i--) array[i] = array[i - 1];

            array[index] = value;
        } else {
            array.push(value);
        }
    }

    /**
     * @notice Remove a uint32 from the array at a given index.
     * @param array uint32 array to remove the uint32 from
     * @param index index to remove the uint32 at
     */
    function remove(uint32[] storage array, uint32 index) internal {
        uint256 len = array.length;

        require(index < len, "Index out of bounds");

        for (uint256 i = index; i < len - 1; i++) array[i] = array[i + 1];

        array.pop();
    }

    /**
     * @notice Check whether an array contains an uint32.
     * @param array uint32 array to check
     * @param value uint32 to check for
     */
    function contains(uint32[] storage array, uint32 value) internal view returns (bool) {
        for (uint256 i; i < array.length; i++) if (value == array[i]) return true;

        return false;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import { IMulticall } from "src/interfaces/IMulticall.sol";

/**
 * @title Multicall
 * @notice Enables calling multiple methods in a single call to the contract
 * From: https://github.com/Uniswap/v3-periphery/blob/1d69caf0d6c8cfeae9acd1f34ead30018d6e6400/contracts/base/Multicall.sol
 */
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable-next-line reason-string
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

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

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3Router is IUniswapV3SwapCallback {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

interface IChainlinkAggregator is AggregatorV2V3Interface {
    function maxAnswer() external view returns (int192);

    function minAnswer() external view returns (int192);

    function aggregator() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
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
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
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
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
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
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
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
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
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
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
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
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
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
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
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
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
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
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
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
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
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
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
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
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
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
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
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
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
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
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
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
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
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
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
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
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
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
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
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
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
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
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
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
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
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
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
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
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
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
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import { ERC20 } from "src/base/ERC4626.sol";
import { PriceRouter } from "src/modules/price-router/PriceRouter.sol";
import { Math } from "src/utils/Math.sol";

/**
 * @title Sommelier Price Router Extension abstract contract.
 * @notice Provides shared logic between Extensions.
 * @author crispymangoes
 */
abstract contract Extension {
    /**
     * @notice Attempted to call a function only callable by the price router.
     */
    error Extension__OnlyPriceRouter();

    /**
     * @notice Prevents non price router contracts from calling a function.
     */
    modifier onlyPriceRouter() {
        if (msg.sender != address(priceRouter)) revert Extension__OnlyPriceRouter();
        _;
    }

    /**
     * @notice The Sommelier PriceRouter contract.
     */
    PriceRouter public immutable priceRouter;

    constructor(PriceRouter _priceRouter) {
        priceRouter = _priceRouter;
    }

    /**
     * @notice Setup function is called when an asset is added/edited.
     */
    function setupSource(ERC20 asset, bytes memory sourceData) external virtual;

    /**
     * @notice Returns the price of an asset in USD.
     */
    function getPriceInUSD(ERC20 asset) external view virtual returns (uint256);
}

pragma solidity ^0.8.10;

interface UniswapV3Pool {
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );
    event Initialize(uint160 sqrtPriceX96, int24 tick);
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    function burn(int24 tickLower, int24 tickUpper, uint128 amount) external returns (uint256 amount0, uint256 amount1);

    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    function factory() external view returns (address);

    function fee() external view returns (uint24);

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);

    function flash(address recipient, uint256 amount0, uint256 amount1, bytes memory data) external;

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    function initialize(uint160 sqrtPriceX96) external;

    function liquidity() external view returns (uint128);

    function maxLiquidityPerTick() external view returns (uint128);

    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes memory data
    ) external returns (uint256 amount0, uint256 amount1);

    function observations(
        uint256
    )
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    function observe(
        uint32[] memory secondsAgos
    ) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    function positions(
        bytes32
    )
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function protocolFees() external view returns (uint128 token0, uint128 token1);

    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function snapshotCumulativesInside(
        int24 tickLower,
        int24 tickUpper
    ) external view returns (int56 tickCumulativeInside, uint160 secondsPerLiquidityInsideX128, uint32 secondsInside);

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes memory data
    ) external returns (int256 amount0, int256 amount1);

    function tickBitmap(int16) external view returns (uint256);

    function tickSpacing() external view returns (int24);

    function ticks(
        int24
    )
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.9.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';

/// @title Oracle library
/// @notice Provides functions to integrate with V3 pool oracle
library OracleLibrary {
    /// @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
    /// @param pool Address of the pool that we want to observe
    /// @param secondsAgo Number of seconds in the past from which to calculate the time-weighted means
    /// @return arithmeticMeanTick The arithmetic mean tick from (block.timestamp - secondsAgo) to block.timestamp
    /// @return harmonicMeanLiquidity The harmonic mean liquidity from (block.timestamp - secondsAgo) to block.timestamp
    function consult(address pool, uint32 secondsAgo)
        internal
        view
        returns (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity)
    {
        require(secondsAgo != 0, 'BP');

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = IUniswapV3Pool(pool)
            .observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        uint160 secondsPerLiquidityCumulativesDelta = secondsPerLiquidityCumulativeX128s[1] -
            secondsPerLiquidityCumulativeX128s[0];

        arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(secondsAgo)));
        // Always round to negative infinity
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(secondsAgo)) != 0)) arithmeticMeanTick--;

        // We are multiplying here instead of shifting to ensure that harmonicMeanLiquidity doesn't overflow uint128
        uint192 secondsAgoX160 = uint192(secondsAgo) * type(uint160).max;
        harmonicMeanLiquidity = uint128(secondsAgoX160 / (uint192(secondsPerLiquidityCumulativesDelta) << 32));
    }

    /// @notice Given a tick and a token amount, calculates the amount of token received in exchange
    /// @param tick Tick value used to calculate the quote
    /// @param baseAmount Amount of token to be converted
    /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
    /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
    /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
    function getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }

    /// @notice Given a pool, it returns the number of seconds ago of the oldest stored observation
    /// @param pool Address of Uniswap V3 pool that we want to observe
    /// @return secondsAgo The number of seconds ago of the oldest observation stored for the pool
    function getOldestObservationSecondsAgo(address pool) internal view returns (uint32 secondsAgo) {
        (, , uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();
        require(observationCardinality > 0, 'NI');

        (uint32 observationTimestamp, , , bool initialized) = IUniswapV3Pool(pool).observations(
            (observationIndex + 1) % observationCardinality
        );

        // The next index might not be initialized if the cardinality is in the process of increasing
        // In this case the oldest observation is always in index 0
        if (!initialized) {
            (observationTimestamp, , , ) = IUniswapV3Pool(pool).observations(0);
        }

        unchecked {
            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }

    /// @notice Given a pool, it returns the tick value as of the start of the current block
    /// @param pool Address of Uniswap V3 pool
    /// @return The tick that the pool was in at the start of the current block
    function getBlockStartingTickAndLiquidity(address pool) internal view returns (int24, uint128) {
        (, int24 tick, uint16 observationIndex, uint16 observationCardinality, , , ) = IUniswapV3Pool(pool).slot0();

        // 2 observations are needed to reliably calculate the block starting tick
        require(observationCardinality > 1, 'NEO');

        // If the latest observation occurred in the past, then no tick-changing trades have happened in this block
        // therefore the tick in `slot0` is the same as at the beginning of the current block.
        // We don't need to check if this observation is initialized - it is guaranteed to be.
        (
            uint32 observationTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,

        ) = IUniswapV3Pool(pool).observations(observationIndex);
        if (observationTimestamp != uint32(block.timestamp)) {
            return (tick, IUniswapV3Pool(pool).liquidity());
        }

        uint256 prevIndex = (uint256(observationIndex) + observationCardinality - 1) % observationCardinality;
        (
            uint32 prevObservationTimestamp,
            int56 prevTickCumulative,
            uint160 prevSecondsPerLiquidityCumulativeX128,
            bool prevInitialized
        ) = IUniswapV3Pool(pool).observations(prevIndex);

        require(prevInitialized, 'ONI');

        uint32 delta = observationTimestamp - prevObservationTimestamp;
        tick = int24((tickCumulative - int56(uint56(prevTickCumulative))) / int56(uint56(delta)));
        uint128 liquidity = uint128(
            (uint192(delta) * type(uint160).max) /
                (uint192(secondsPerLiquidityCumulativeX128 - prevSecondsPerLiquidityCumulativeX128) << 32)
        );
        return (tick, liquidity);
    }

    /// @notice Information for calculating a weighted arithmetic mean tick
    struct WeightedTickData {
        int24 tick;
        uint128 weight;
    }

    /// @notice Given an array of ticks and weights, calculates the weighted arithmetic mean tick
    /// @param weightedTickData An array of ticks and weights
    /// @return weightedArithmeticMeanTick The weighted arithmetic mean tick
    /// @dev Each entry of `weightedTickData` should represents ticks from pools with the same underlying pool tokens. If they do not,
    /// extreme care must be taken to ensure that ticks are comparable (including decimal differences).
    /// @dev Note that the weighted arithmetic mean tick corresponds to the weighted geometric mean price.
    function getWeightedArithmeticMeanTick(WeightedTickData[] memory weightedTickData)
        internal
        pure
        returns (int24 weightedArithmeticMeanTick)
    {
        // Accumulates the sum of products between each tick and its weight
        int256 numerator;

        // Accumulates the sum of the weights
        uint256 denominator;

        // Products fit in 152 bits, so it would take an array of length ~2**104 to overflow this logic
        for (uint256 i; i < weightedTickData.length; i++) {
            numerator += weightedTickData[i].tick * int256(uint256(weightedTickData[i].weight));
            denominator += weightedTickData[i].weight;
        }

        weightedArithmeticMeanTick = int24(numerator / int256(denominator));
        // Always round to negative infinity
        if (numerator < 0 && (numerator % int256(denominator) != 0)) weightedArithmeticMeanTick--;
    }

    /// @notice Returns the "synthetic" tick which represents the price of the first entry in `tokens` in terms of the last
    /// @dev Useful for calculating relative prices along routes.
    /// @dev There must be one tick for each pairwise set of tokens.
    /// @param tokens The token contract addresses
    /// @param ticks The ticks, representing the price of each token pair in `tokens`
    /// @return syntheticTick The synthetic tick, representing the relative price of the outermost tokens in `tokens`
    function getChainedPrice(address[] memory tokens, int24[] memory ticks)
        internal
        pure
        returns (int256 syntheticTick)
    {
        require(tokens.length - 1 == ticks.length, 'DL');
        for (uint256 i = 1; i <= ticks.length; i++) {
            // check the tokens for address sort order, then accumulate the
            // ticks into the running synthetic tick, ensuring that intermediate tokens "cancel out"
            tokens[i - 1] < tokens[i] ? syntheticTick += ticks[i - 1] : syntheticTick -= ticks[i - 1];
        }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
// From: https://github.com/Uniswap/v3-periphery/contracts/interfaces/IMulticall.sol
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
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

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}