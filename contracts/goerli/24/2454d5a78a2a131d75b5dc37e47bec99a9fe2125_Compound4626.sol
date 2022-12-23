// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import 'src/interfaces/IERC4626.sol';
import 'src/libs/LibCompound.sol';
import 'src/tokens/ERC20.sol';

contract Compound4626 is ERC20, IERC4626 {
    ICERC20 immutable cToken;

    constructor(
        address c,
        string memory n,
        string memory s,
        uint8 d
    ) ERC20(n, s, d) {
        cToken = ICERC20(c);
        IERC20(cToken.underlying()).approve(c, type(uint256).max);
    }

    function asset() external view returns (IERC20 assetTokenAddress) {
        return (cToken.underlying());
    }

    function totalAssets() external view returns (uint256 totalManagedAssets) {
        return (cToken.getCash());
    }

    function convertToShares(uint256 _assets)
        public
        view
        returns (uint256 shares)
    {
        return (_assets / LibCompound.viewExchangeRate(cToken));
    }

    function convertToAssets(uint256 _shares)
        external
        view
        returns (uint256 assets)
    {
        return (_shares * LibCompound.viewExchangeRate(cToken));
    }

    function maxDeposit(address _receiver)
        external
        view
        returns (uint256 maxAssets)
    {
        return (IERC20(cToken.underlying()).balanceOf(_receiver));
    }

    function previewDeposit(uint256 _assets)
        external
        view
        returns (uint256 shares)
    {
        return (_assets / LibCompound.viewExchangeRate(cToken));
    }

    function deposit(uint256 _assets, address _receiver)
        external
        returns (uint256 shares)
    {
        uint256 amount = _assets / LibCompound.viewExchangeRate(cToken);
        IERC20(cToken.underlying()).transferFrom(
            msg.sender,
            address(this),
            _assets
        );
        cToken.mint(_assets);
        _mint(_receiver, amount);
        return (amount);
    }

    function maxMint(address _receiver)
        external
        view
        returns (uint256 maxShares)
    {
        return (IERC20(cToken.underlying()).balanceOf(_receiver) /
            LibCompound.viewExchangeRate(cToken));
    }

    function previewMint(uint256 _shares)
        external
        view
        returns (uint256 assets)
    {
        return (_shares * LibCompound.viewExchangeRate(cToken));
    }

    function mint(uint256 _shares, address _receiver)
        external
        returns (uint256 assets)
    {
        uint256 amount = _shares * LibCompound.viewExchangeRate(cToken);
        IERC20(cToken.underlying()).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        cToken.mint(amount);
        _mint(_receiver, _shares);
        return (amount);
    }

    function maxWithdraw(address _owner)
        external
        view
        returns (uint256 maxAssets)
    {
        return (balanceOf(_owner) * LibCompound.viewExchangeRate(cToken));
    }

    function previewWithdraw(uint256 _assets)
        external
        view
        returns (uint256 shares)
    {
        return (_assets / LibCompound.viewExchangeRate(cToken));
    }

    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 shares) {
        uint256 amount = _assets / LibCompound.viewExchangeRate(cToken);
        _burn(_owner, amount);
        cToken.redeemUnderlying(_assets);
        IERC20(cToken.underlying()).transfer(_receiver, _assets);
        return (amount);
    }

    function maxRedeem(address _owner)
        external
        view
        returns (uint256 maxShares)
    {
        return (balanceOf(_owner));
    }

    function previewRedeem(uint256 _shares)
        external
        view
        returns (uint256 assets)
    {
        return (_shares * LibCompound.viewExchangeRate(cToken));
    }

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assets) {
        uint256 amount = _shares * LibCompound.viewExchangeRate(cToken);
        _burn(_owner, _shares);
        cToken.redeem(_shares);
        IERC20(cToken.underlying()).transfer(_receiver, amount);
        return (amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import 'src/interfaces/IERC20.sol';

import 'src/libs/InterestRateModel.sol';

interface ICERC20 is IERC20 {
    function mint(uint256) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function underlying() external view returns (IERC20);

    function totalBorrows() external view returns (uint256);

    function totalFuseFees() external view returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function totalReserves() external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function totalAdminFees() external view returns (uint256);

    function fuseFeeMantissa() external view returns (uint256);

    function adminFeeMantissa() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function interestRateModel() external view returns (InterestRateModel);

    function initialExchangeRateMantissa() external view returns (uint256);

    function repayBorrowBehalf(address, uint256) external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function getCash() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

}

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

import 'src/interfaces/IERC20.sol';

/**
 * @title EIP 4626 specification
 * @notice Interface of EIP 4626 Interface
 * as defined in https://eips.ethereum.org/EIPS/eip-4626
 */
interface IERC4626 is IERC20 {
    /**
     * @notice Event indicating that `caller` exchanged `assets` for `shares`, and transferred those `shares` to `owner`
     * @dev Emitted when tokens are deposited into the vault via {mint} and {deposit} methods
     */
    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Event indicating that `caller` exchanged `shares`, owned by `owner`, for `assets`, and transferred those
     * `assets` to `receiver`
     * @dev Emitted when shares are withdrawn from the vault via {redeem} or {withdraw} methods
     */
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @notice Returns the address of the underlying token used by the Vault
     * @return assetTokenAddress The address of the underlying ERC20 Token
     * @dev MUST be an ERC-20 token contract
     *
     * MUST not revert
     */
    function asset() external view returns (IERC20 assetTokenAddress);

    /**
     * @notice Returns the total amount of the underlying asset managed by the Vault
     * @return totalManagedAssets Amount of the underlying asset
     * @dev Should include any compounding that occurs from yield.
     *
     * Should be inclusive of any fees that are charged against assets in the vault.
     *
     * Must not revert
     *
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     *
     * @notice Returns the amount of shares that, in an ideal scenario, the vault would exchange for the amount of assets
     * provided
     *
     * @param _assets Amount of assets to convert
     * @return shares Amount of shares that would be exchanged for the provided amount of assets
     *
     * @dev MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *
     * MUST NOT show any variations depending on the caller.
     *
     * MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     *
     * MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
     *
     * MUST round down towards 0.
     *
     * This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and from.
     */
    function convertToShares(uint256 _assets)
        external
        view
        returns (uint256 shares);

    /**
     *
     * @notice Returns the amount of assets that the vault would exchange for the amount of shares provided
     *
     * @param _shares Amount of vault shares to convert
     * @return assets Amount of assets that would be exchanged for the provided amount of shares
     *
     * @dev MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *
     * MUST NOT show any variations depending on the caller.
     *
     * MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     *
     * MUST NOT revert unless due to integer overflow caused by an unreasonably large input.
     *
     * MUST round down towards 0.
     *
     * This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and from.
     */
    function convertToAssets(uint256 _shares)
        external
        view
        returns (uint256 assets);

    /**
     *
     * @notice Returns the maximum amount of the underlying asset that can be deposited into the vault for the `receiver`
     * through a {deposit} call
     *
     * @param _receiver Address whose maximum deposit is being queries
     * @return maxAssets
     *
     * @dev MUST return the maximum amount of assets {deposit} would allow to be deposited for receiver and not cause a
     * revert, which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if
     *necessary). This assumes that the user has infinite assets, i.e. MUST NOT rely on {balanceOf} of asset.
     *
     * MUST factor in both global and user-specific limits, like if deposits are entirely disabled (even temporarily)
     * it MUST return 0.
     *
     * MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     *
     * MUST NOT revert.
     */
    function maxDeposit(address _receiver)
        external
        view
        returns (uint256 maxAssets);

    /**
     * @notice Simulate the effects of a user's deposit at the current block, given current on-chain conditions
     * @param _assets Amount of assets
     * @return shares Amount of shares
     * @dev MUST return as close to and no more than the exact amount of Vault shares that would be minted in a {deposit}
     * call in the same transaction. I.e. deposit should return the same or more shares as {previewDeposit} if called in
     * the same transaction. (I.e. {previewDeposit} should underestimate or round-down)
     *
     * MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     * deposit would be accepted, regardless if the user has enough tokens approved, etc.
     *
     * MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause deposit to revert.
     *
     * Note that any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage
     * in share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 _assets)
        external
        view
        returns (uint256 shares);

    /**
     * @notice Mints `shares` Vault shares to `receiver` by depositing exactly `amount` of underlying tokens
     * @param _assets Amount of assets
     * @param _receiver Address to deposit underlying tokens into
     * @dev Must emit the {Deposit} event
     *
     * MUST support ERC-20 {approve} / {transferFrom} on asset as a deposit flow. MAY support an additional flow in
     * which the underlying tokens are owned by the Vault contract before the {deposit} execution, and are accounted for
     * during {deposit}.
     *
     * MUST revert if all of `assets` cannot be deposited (due to deposit limit being reached, slippage, the user not
     * approving enough underlying tokens to the Vault contract, etc).
     *
     * Note that most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 _assets, address _receiver)
        external
        returns (uint256 shares);

    /**
     * @notice Returns the maximum amount of shares that can be minted from the vault for the `receiver``, via a `mint`
     * call
     * @param _receiver Address to deposit minted shares into
     * @return maxShares The maximum amount of shares
     * @dev MUST return the maximum amount of shares mint would allow to be deposited to receiver and not cause a revert,
     * which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if necessary).
     * This assumes that the user has infinite assets, i.e. MUST NOT rely on balanceOf of asset.
     *
     * MUST factor in both global and user-specific limits, like if mints are entirely disabled (even temporarily) it
     *
     * MUST return 0.
     *
     * MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     *
     * MUST NOT revert.
     */
    function maxMint(address _receiver)
        external
        view
        returns (uint256 maxShares);

    /**
     * @notice Simulate the effects of a user's mint at the current block, given current on-chain conditions
     * @param _shares Amount of shares to mint
     * @return assets Amount of assets required to mint `mint` amount of shares
     * @dev MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     * in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the same
     * transaction. (I.e. {previewMint} should overestimate or round-up)
     *
     * MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     * would be accepted, regardless if the user has enough tokens approved, etc.
     *
     * MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause mint to revert.
     *
     * Note that any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 _shares)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Mints exactly `shares` vault shares to `receiver` by depositing `amount` of underlying tokens
     * @param _shares Amount of shares to mint
     * @param _receiver Address to deposit minted shares into
     * @return assets Amount of assets transferred to vault
     * @dev Must emit the {Deposit} event
     *
     * MUST support ERC-20 {approve} / {transferFrom} on asset as a mint flow. MAY support an additional flow in
     *  which the underlying tokens are owned by the Vault contract before the mint execution, and are accounted for
     * during mint.
     *
     * MUST revert if all of `shares` cannot be minted (due to deposit limit being reached, slippage, the user not
     * approving enough underlying tokens to the Vault contract, etc).
     *
     * Note that most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 _shares, address _receiver)
        external
        returns (uint256 assets);

    /**
     * @notice Returns the maximum amount of the underlying asset that can be withdrawn from the `owner` balance in the
     * vault, through a `withdraw` call.
     * @param _owner Address of the owner whose max withdrawal amount is being queries
     * @return maxAssets Maximum amount of underlying asset that can be withdrawn
     * @dev MUST return the maximum amount of assets that could be transferred from `owner` through {withdraw} and not
     * cause a revert, which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if
     * necessary).
     *
     * MUST factor in both global and user-specific limits, like if withdrawals are entirely disabled
     * (even temporarily)  it MUST return 0.
     *
     * MUST NOT revert.
     */
    function maxWithdraw(address _owner)
        external
        view
        returns (uint256 maxAssets);

    /**
     * @notice Simulate the effects of a user's withdrawal at the current block, given current on-chain conditions.
     * @param _assets Amount of assets
     * @return shares Amount of shares
     * @dev MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a
     * {withdraw} call in the same transaction. I.e. {withdraw} should return the same or fewer shares as
     * {previewWithdraw} if called in the same transaction. (I.e. {previewWithdraw should overestimate or round-up})
     *
     * MUST NOT account for withdrawal limits like those returned from {maxWithdraw} and should always act as though
     * the withdrawal would be accepted, regardless if the user has enough shares, etc.
     *
     * MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause {withdraw} to revert.
     *
     * Note that any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 _assets)
        external
        view
        returns (uint256 shares);

    /**
     * @notice Burns `shares` from `owner` and sends exactly `assets` of underlying tokens to `receiver`
     * @param _assets Amount of underling assets to withdraw
     * @return shares Amount of shares that will be burned
     * @dev Must emit the {Withdraw} event
     *
     * MUST support a withdraw flow where the shares are burned from `owner` directly where `owner` is `msg.sender`
     * or `msg.sender` has ERC-20 approval over the shares of `owner`. MAY support an additional flow in which the shares
     * are transferred to the Vault contract before the withdraw execution, and are accounted for during withdraw.
     *
     * MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     * not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     *  Those methods should be performed separately.
     */
    function withdraw(
        uint256 _assets,
        address _receiver,
        address _owner
    ) external returns (uint256 shares);

    /**
     * @notice Returns the maximum amount of vault shares that can be redeemed from the `owner` balance in the vault, via
     * a `redeem` call.
     * @param _owner Address of the owner whose shares are being queries
     * @return maxShares Maximum amount of shares that can be redeemed
     * @dev MUST return the maximum amount of shares that could be transferred from `owner` through `redeem` and not cause
     * a revert, which MUST NOT be higher than the actual maximum that would be accepted (it should underestimate if
     * necessary).
     *
     * MUST factor in both global and user-specific limits, like if redemption is entirely disabled
     * (even temporarily) it MUST return 0.
     *
     * MUST NOT revert
     */
    function maxRedeem(address _owner)
        external
        view
        returns (uint256 maxShares);

    /**
     * @notice Simulate the effects of a user's redemption at the current block, given current on-chain conditions
     * @param _shares Amount of shares that are being simulated to be redeemed
     * @return assets Amount of underlying assets that can be redeemed
     * @dev MUST return as close to and no more than the exact amount of `assets `that would be withdrawn in a {redeem}
     * call in the same transaction. I.e. {redeem} should return the same or more assets as {previewRedeem} if called in
     * the same transaction. I.e. {previewRedeem} should underestimate/round-down
     *
     * MUST NOT account for redemption limits like those returned from {maxRedeem} and should always act as though
     * the redemption would be accepted, regardless if the user has enough shares, etc.
     *
     * MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     *
     * MUST NOT revert due to vault specific user/global limits. MAY revert due to other conditions that would also
     * cause {redeem} to revert.
     *
     * Note that any unfavorable discrepancy between {convertToAssets} and {previewRedeem} SHOULD be considered
     * slippage in share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 _shares)
        external
        view
        returns (uint256 assets);

    /**
     * @notice Burns exactly `shares` from `owner` and sends `assets` of underlying tokens to `receiver`
     * @param _shares Amount of shares to burn
     * @param _receiver Address to deposit redeemed underlying tokens to
     * @return assets Amount of underlying tokens redeemed
     * @dev Must emit the {Withdraw} event
     * MUST support a {redeem} flow where the shares are burned from owner directly where `owner` is `msg.sender` or
     *
     * `msg.sender` has ERC-20 approval over the shares of `owner`. MAY support an additional flow in which the shares
     * are transferred to the Vault contract before the {redeem} execution, and are accounted for during {redeem}.
     *
     * MUST revert if all of {shares} cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     * not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface InterestRateModel {
    function getBorrowRate(
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >0.8.0;

import {FixedPointMathLib} from 'src/utils/FixedPointMathLib.sol';

import {ICERC20} from 'src/interfaces/ICERC20.sol';

/// @notice Get up to date cToken data without mutating state.
/// @author Transmissions11 (https://github.com/transmissions11/libcompound)
library LibCompound {
    using FixedPointMathLib for uint256;

    function viewUnderlyingBalanceOf(ICERC20 cToken, address user)
        internal
        view
        returns (uint256)
    {
        return cToken.balanceOf(user).mulWadDown(viewExchangeRate(cToken));
    }

    function viewExchangeRate(ICERC20 cToken) internal view returns (uint256) {
        uint256 accrualBlockNumberPrior = cToken.accrualBlockNumber();

        if (accrualBlockNumberPrior == block.number)
            return cToken.exchangeRateStored();

        uint256 totalCash = cToken.underlying().balanceOf(address(cToken));
        uint256 borrowsPrior = cToken.totalBorrows();
        uint256 reservesPrior = cToken.totalReserves();

        uint256 borrowRateMantissa = cToken.interestRateModel().getBorrowRate(
            totalCash,
            borrowsPrior,
            reservesPrior
        );

        require(borrowRateMantissa <= 0.0005e16, 'RATE_TOO_HIGH'); // Same as borrowRateMaxMantissa in CTokenInterfaces.sol

        uint256 interestAccumulated = (borrowRateMantissa *
            (block.number - accrualBlockNumberPrior)).mulWadDown(borrowsPrior);

        uint256 totalReserves = cToken.reserveFactorMantissa().mulWadDown(
            interestAccumulated
        ) + reservesPrior;
        uint256 totalBorrows = interestAccumulated + borrowsPrior;
        uint256 totalSupply = cToken.totalSupply();

        return
            totalSupply == 0
                ? cToken.initialExchangeRateMantissa()
                : (totalCash + totalBorrows - totalReserves).divWadDown(
                    totalSupply
                );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import 'src/interfaces/IERC20.sol';

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * NOTES: This is an adaptation of the Open Zeppelin ERC20, with changes made per audit
 * requests, and to fit overall Swivel Style. We use it specifically as the base for
 * the Erc2612 hence the `Perc` (Permissioned erc20) naming.
 *
 * Dangling underscores are generally not allowed within swivel style but the 
 * internal, abstracted implementation methods inherted from the O.Z contract are maintained here.
 * Hence, when you see a dangling underscore prefix, you know it is *only* allowed for
 * one of these method calls. It is not allowed for any other purpose. These are:
     _approve
     _transfer
     _mint
     _burn
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is IERC20 {
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    uint8 public decimals;
    uint256 public override totalSupply;
    string public name; // NOTE: cannot make strings immutable
    string public symbol; // NOTE: see above

    /**
     * @dev Sets the values for {name} and {symbol}.
     * @param n Name of the token
     * @param s Symbol of the token
     * @param d Decimals of the token
     */
    constructor(
        string memory n,
        string memory s,
        uint8 d
    ) {
        name = n;
        symbol = s;
        decimals = d;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     * @param a Adress to fetch balance of
     */
    function balanceOf(address a)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balances[a];
    }

    /**
     * @dev See {IERC20-transfer}.
     * @param r The recipient
     * @param a The amount transferred
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address r, uint256 a)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, r, a);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     * @param o The owner
     * @param s The spender
     */
    function allowance(address o, address s)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return allowances[o][s];
    }

    /**
     * @dev See {IERC20-approve}.
     * @param s The spender
     * @param a The amount to approve
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address s, uint256 a)
        public
        virtual
        override
        returns (bool)
    {
        _approve(msg.sender, s, a);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * @param s The sender
     * @param r The recipient
     * @param a The amount to transfer
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address s,
        address r,
        uint256 a
    ) public virtual override returns (bool) {
        _transfer(s, r, a);

        uint256 currentAllowance = allowances[s][msg.sender];
        require(
            currentAllowance >= a,
            'erc20 transfer amount exceeds allowance'
        );
        _approve(s, msg.sender, currentAllowance - a);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * @param s The spender
     * @param a The amount increased
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
    function increaseAllowance(address s, uint256 a)
        public
        virtual
        returns (bool)
    {
        _approve(msg.sender, s, allowances[msg.sender][s] + a);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * @param s The spender
     * @param a The amount subtracted
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
    function decreaseAllowance(address s, uint256 a)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowances[msg.sender][s];
        require(currentAllowance >= a, 'erc20 decreased allowance below zero');
        _approve(msg.sender, s, currentAllowance - a);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     * @param s The sender
     * @param r The recipient
     * @param a The amount to transfer
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address s,
        address r,
        uint256 a
    ) internal virtual {
        require(s != address(0), 'erc20 transfer from the zero address');
        require(r != address(0), 'erc20 transfer to the zero address');

        uint256 senderBalance = balances[s];
        require(senderBalance >= a, 'erc20 transfer amount exceeds balance');
        balances[s] = senderBalance - a;
        balances[r] += a;

        emit Transfer(s, r, a);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * @param r The recipient
     * @param a The amount to mint
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     */
    function _mint(address r, uint256 a) internal virtual {
        require(r != address(0), 'erc20 mint to the zero address');

        totalSupply += a;
        balances[r] += a;
        emit Transfer(address(0), r, a);
    }

    /**
     * @dev Destroys `amount` tokens from `owner`, reducing the
     * total supply.
     * @param o The owner of the amount being burned
     * @param a The amount to burn
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `owner` must have at least `amount` tokens.
     */
    function _burn(address o, uint256 a) internal virtual {
        require(o != address(0), 'erc20 burn from the zero address');

        uint256 accountBalance = balances[o];
        require(accountBalance >= a, 'erc20 burn amount exceeds balance');
        balances[o] = accountBalance - a;
        totalSupply -= a;

        emit Transfer(o, address(0), a);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * @param o The owner
     * @param s The spender
     * @param a The amount
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
        address o,
        address s,
        uint256 a
    ) internal virtual {
        require(o != address(0), 'erc20 approve from the zero address');
        require(s != address(0), 'erc20 approve to the zero address');

        allowances[o][s] = a;
        emit Approval(o, s, a);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

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

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}