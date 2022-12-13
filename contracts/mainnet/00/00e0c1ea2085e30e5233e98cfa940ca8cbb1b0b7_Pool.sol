// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { ERC20 }       from "../modules/erc20/contracts/ERC20.sol";
import { ERC20Helper } from "../modules/erc20-helper/src/ERC20Helper.sol";

import { IPoolManagerLike } from "./interfaces/Interfaces.sol";
import { IERC20, IPool }    from "./interfaces/IPool.sol";

/*

    ██████╗  ██████╗  ██████╗ ██╗
    ██╔══██╗██╔═══██╗██╔═══██╗██║
    ██████╔╝██║   ██║██║   ██║██║
    ██╔═══╝ ██║   ██║██║   ██║██║
    ██║     ╚██████╔╝╚██████╔╝███████╗
    ╚═╝      ╚═════╝  ╚═════╝ ╚══════╝

*/

contract Pool is IPool, ERC20 {

    uint256 public immutable override BOOTSTRAP_MINT;

    address public override asset;    // Underlying ERC-20 asset handled by the ERC-4626 contract.
    address public override manager;  // Address of the contract that manages administrative functionality.

    uint256 private _locked = 1;  // Used when checking for reentrancy.

    constructor(
        address manager_,
        address asset_,
        address destination_,
        uint256 bootstrapMint_,
        uint256 initialSupply_,
        string memory name_,
        string memory symbol_
    )
        ERC20(name_, symbol_, ERC20(asset_).decimals())
    {
        require((manager = manager_) != address(0), "P:C:ZERO_MANAGER");
        require((asset   = asset_)   != address(0), "P:C:ZERO_ASSET");

        if (initialSupply_ != 0) {
            _mint(destination_, initialSupply_);
        }

        BOOTSTRAP_MINT = bootstrapMint_;

        require(ERC20Helper.approve(asset_, manager_, type(uint256).max), "P:C:FAILED_APPROVE");
    }

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    modifier checkCall(bytes32 functionId_) {
        ( bool success_, string memory errorMessage_ ) = IPoolManagerLike(manager).canCall(functionId_, msg.sender, msg.data[4:]);

        require(success_, errorMessage_);

        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "P:LOCKED");

        _locked = 2;

        _;

        _locked = 1;
    }

    /******************************************************************************************************************************/
    /*** LP Functions                                                                                                           ***/
    /******************************************************************************************************************************/

    function deposit(uint256 assets_, address receiver_) external override nonReentrant checkCall("P:deposit") returns (uint256 shares_) {
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function depositWithPermit(
        uint256 assets_,
        address receiver_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external override nonReentrant checkCall("P:depositWithPermit") returns (uint256 shares_)
    {
        ERC20(asset).permit(msg.sender, address(this), assets_, deadline_, v_, r_, s_);
        _mint(shares_ = previewDeposit(assets_), assets_, receiver_, msg.sender);
    }

    function mint(uint256 shares_, address receiver_) external override nonReentrant checkCall("P:mint") returns (uint256 assets_) {
        _mint(shares_, assets_ = previewMint(shares_), receiver_, msg.sender);
    }

    function mintWithPermit(
        uint256 shares_,
        address receiver_,
        uint256 maxAssets_,
        uint256 deadline_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    )
        external override nonReentrant checkCall("P:mintWithPermit") returns (uint256 assets_)
    {
        require((assets_ = previewMint(shares_)) <= maxAssets_, "P:MWP:INSUFFICIENT_PERMIT");

        ERC20(asset).permit(msg.sender, address(this), maxAssets_, deadline_, v_, r_, s_);
        _mint(shares_, assets_, receiver_, msg.sender);
    }

    function redeem(uint256 shares_, address receiver_, address owner_) external override nonReentrant checkCall("P:redeem") returns (uint256 assets_) {
        uint256 redeemableShares_;
        ( redeemableShares_, assets_ ) = IPoolManagerLike(manager).processRedeem(shares_, owner_, msg.sender);
        _burn(redeemableShares_, assets_, receiver_, owner_, msg.sender);
    }

    function withdraw(uint256 assets_, address receiver_, address owner_) external override nonReentrant checkCall("P:withdraw") returns (uint256 shares_) {
        ( shares_, assets_ ) = IPoolManagerLike(manager).processWithdraw(assets_, owner_, msg.sender);
        _burn(shares_, assets_, receiver_, owner_, msg.sender);
    }

    /******************************************************************************************************************************/
    /*** ERC-20 Overridden Functions                                                                                            ***/
    /******************************************************************************************************************************/

    function transfer(
        address recipient_,
        uint256 amount_
    )
        public override(IERC20, ERC20) checkCall("P:transfer") returns (bool success_)
    {
        success_ = super.transfer(recipient_, amount_);
    }

    function transferFrom(
        address owner_,
        address recipient_,
        uint256 amount_
    )
        public override(IERC20, ERC20) checkCall("P:transferFrom") returns (bool success_)
    {
        success_ = super.transferFrom(owner_, recipient_, amount_);
    }

    /******************************************************************************************************************************/
    /*** Withdrawal Request Functions                                                                                           ***/
    /******************************************************************************************************************************/

    function removeShares(uint256 shares_, address owner_) external override nonReentrant checkCall("P:removeShares") returns (uint256 sharesReturned_) {
        if (msg.sender != owner_) _decreaseAllowance(owner_, msg.sender, shares_);

        emit SharesRemoved(
            owner_,
            sharesReturned_ = IPoolManagerLike(manager).removeShares(shares_, owner_)
        );
    }

    function requestRedeem(uint256 shares_, address owner_) external override nonReentrant checkCall("P:requestRedeem") returns (uint256 escrowedShares_) {
        emit RedemptionRequested(
            owner_,
            shares_,
            escrowedShares_ = _requestRedeem(shares_, owner_)
        );
    }

    function requestWithdraw(uint256 assets_, address owner_) external override nonReentrant checkCall("P:requestWithdraw") returns (uint256 escrowedShares_) {
        emit WithdrawRequested(
            owner_,
            assets_,
            escrowedShares_ = _requestWithdraw(assets_, owner_)
        );
    }

    /******************************************************************************************************************************/
    /*** Internal Functions                                                                                                     ***/
    /******************************************************************************************************************************/

    function _burn(uint256 shares_, uint256 assets_, address receiver_, address owner_, address caller_) internal {
        require(receiver_ != address(0), "P:B:ZERO_RECEIVER");

        if (shares_ == 0) return;

        if (caller_ != owner_) {
            _decreaseAllowance(owner_, caller_, shares_);
        }

        _burn(owner_, shares_);

        emit Withdraw(caller_, receiver_, owner_, assets_, shares_);

        require(ERC20Helper.transfer(asset, receiver_, assets_), "P:B:TRANSFER");
    }

    function _divRoundUp(uint256 numerator_, uint256 divisor_) internal pure returns (uint256 result_) {
        result_ = (numerator_ + divisor_ - 1) / divisor_;
    }

    function _mint(uint256 shares_, uint256 assets_, address receiver_, address caller_) internal {
        require(receiver_ != address(0), "P:M:ZERO_RECEIVER");
        require(shares_   != uint256(0), "P:M:ZERO_SHARES");
        require(assets_   != uint256(0), "P:M:ZERO_ASSETS");

        if (totalSupply == 0 && BOOTSTRAP_MINT != 0) {
            _mint(address(0), BOOTSTRAP_MINT);

            emit BootstrapMintPerformed(caller_, receiver_, assets_, shares_, BOOTSTRAP_MINT);

            shares_ -= BOOTSTRAP_MINT;
        }

        _mint(receiver_, shares_);

        emit Deposit(caller_, receiver_, assets_, shares_);

        require(ERC20Helper.transferFrom(asset, caller_, address(this), assets_), "P:M:TRANSFER_FROM");
    }

    function _requestRedeem(uint256 shares_, address owner_) internal returns (uint256 escrowShares_) {
        address destination_;

        ( escrowShares_, destination_ ) = IPoolManagerLike(manager).getEscrowParams(owner_, shares_);

        if (msg.sender != owner_) {
            _decreaseAllowance(owner_, msg.sender, escrowShares_);
        }

        if (escrowShares_ != 0 && destination_ != address(0)) {
            _transfer(owner_, destination_, escrowShares_);
        }

        IPoolManagerLike(manager).requestRedeem(escrowShares_, owner_, msg.sender);
    }

    function _requestWithdraw(uint256 assets_, address owner_) internal returns (uint256 escrowShares_) {
        address destination_;

        ( escrowShares_, destination_ ) = IPoolManagerLike(manager).getEscrowParams(owner_, convertToExitShares(assets_));

        if (msg.sender != owner_) {
            _decreaseAllowance(owner_, msg.sender, escrowShares_);
        }

        if (escrowShares_ != 0 && destination_ != address(0)) {
            _transfer(owner_, destination_, escrowShares_);
        }

        IPoolManagerLike(manager).requestWithdraw(escrowShares_, assets_, owner_, msg.sender);
    }

    /******************************************************************************************************************************/
    /*** External View Functions                                                                                                ***/
    /******************************************************************************************************************************/

    function balanceOfAssets(address account_) external view override returns (uint256 balanceOfAssets_) {
        balanceOfAssets_ = convertToAssets(balanceOf[account_]);
    }

    function maxDeposit(address receiver_) external view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolManagerLike(manager).maxDeposit(receiver_);
    }

    function maxMint(address receiver_) external view override returns (uint256 maxShares_) {
        maxShares_ = IPoolManagerLike(manager).maxMint(receiver_);
    }

    function maxRedeem(address owner_) external view override returns (uint256 maxShares_) {
        maxShares_ = IPoolManagerLike(manager).maxRedeem(owner_);
    }

    function maxWithdraw(address owner_) external view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolManagerLike(manager).maxWithdraw(owner_);
    }

    function previewRedeem(uint256 shares_) external view override returns (uint256 assets_) {
        assets_ = IPoolManagerLike(manager).previewRedeem(msg.sender, shares_);
    }

    function previewWithdraw(uint256 assets_) external view override returns (uint256 shares_) {
        shares_ = IPoolManagerLike(manager).previewWithdraw(msg.sender, assets_);
    }

    /******************************************************************************************************************************/
    /*** Public View Functions                                                                                                  ***/
    /******************************************************************************************************************************/

    function convertToAssets(uint256 shares_) public view override returns (uint256 assets_) {
        uint256 totalSupply_ = totalSupply;

        assets_ = totalSupply_ == 0 ? shares_ : (shares_ * totalAssets()) / totalSupply_;
    }

    function convertToExitAssets(uint256 shares_) public view override returns (uint256 assets_) {
        uint256 totalSupply_ = totalSupply;

        assets_ = totalSupply_ == 0 ? shares_ : shares_ * (totalAssets() - unrealizedLosses()) / totalSupply_;
    }

    function convertToShares(uint256 assets_) public view override returns (uint256 shares_) {
        uint256 totalSupply_ = totalSupply;

        shares_ = totalSupply_ == 0 ? assets_ : (assets_ * totalSupply_) / totalAssets();
    }

    function convertToExitShares(uint256 amount_) public view override returns (uint256 shares_) {
        shares_ = _divRoundUp(amount_ * totalSupply, totalAssets() - unrealizedLosses());
    }

    function previewDeposit(uint256 assets_) public view override returns (uint256 shares_) {
        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round DOWN if it’s calculating the amount of shares to issue to a user, given an amount of assets provided.
        shares_ = convertToShares(assets_);
    }

    function previewMint(uint256 shares_) public view override returns (uint256 assets_) {
        uint256 totalSupply_ = totalSupply;

        // As per https://eips.ethereum.org/EIPS/eip-4626#security-considerations,
        // it should round UP if it’s calculating the amount of assets a user must provide, to be issued a given amount of shares.
        assets_ = totalSupply_ == 0 ? shares_ : _divRoundUp(shares_ * totalAssets(), totalSupply_);
    }

    function totalAssets() public view override returns (uint256 totalAssets_) {
        totalAssets_ = IPoolManagerLike(manager).totalAssets();
    }

    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        unrealizedLosses_ = IPoolManagerLike(manager).unrealizedLosses();
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 } from "../../modules/erc20/contracts/interfaces/IERC20.sol";

/// @title A standard for tokenized Vaults with a single underlying ERC-20 token.
interface IERC4626 is IERC20 {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                  ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   `caller_` has exchanged `assets_` for `shares_` and transferred them to `owner_`.
     *         MUST be emitted when assets are deposited via the `deposit` or `mint` methods.
     *  @param caller_ The caller of the function that emitted the `Deposit` event.
     *  @param owner_  The owner of the shares.
     *  @param assets_ The amount of assets deposited.
     *  @param shares_ The amount of shares minted.
     */
    event Deposit(address indexed caller_, address indexed owner_, uint256 assets_, uint256 shares_);

    /**
     *  @dev   `caller_` has exchanged `shares_`, owned by `owner_`, for `assets_`, and transferred them to `receiver_`.
     *         MUST be emitted when assets are withdrawn via the `withdraw` or `redeem` methods.
     *  @param caller_   The caller of the function that emitted the `Withdraw` event.
     *  @param receiver_ The receiver of the assets.
     *  @param owner_    The owner of the shares.
     *  @param assets_   The amount of assets withdrawn.
     *  @param shares_   The amount of shares burned.
     */
    event Withdraw(address indexed caller_, address indexed receiver_, address indexed owner_, uint256 assets_, uint256 shares_);

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    The address of the underlying asset used by the Vault.
     *          MUST be a contract that implements the ERC-20 standard.
     *          MUST NOT revert.
     *  @return asset_ The address of the underlying asset.
     */
    function asset() external view returns (address asset_);

    /******************************************************************************************************************************/
    /*** State Changing Functions                                                                                               ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of the assets cannot be deposited (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  assets_   The amount of assets to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The amount of shares minted.
     */
    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    /**
     *  @dev    Mints `shares_` to `receiver_` by depositing `assets_` into the Vault.
     *          MUST emit the {Deposit} event.
     *          MUST revert if all of shares cannot be minted (due to insufficient approval, deposit limits, slippage, etc).
     *  @param  shares_   The amount of shares to mint.
     *  @param  receiver_ The receiver of the shares.
     *  @return assets_   The amount of assets deposited.
     */
    function mint(uint256 shares_, address receiver_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the shares cannot be redeemed (due to insufficient shares, withdrawal limits, slippage, etc).
     *  @param  shares_   The amount of shares to redeem.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the shares.
     *  @return assets_   The amount of assets sent to the receiver.
     */
    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

    /**
     *  @dev    Burns `shares_` from `owner_` and sends `assets_` to `receiver_`.
     *          MUST emit the {Withdraw} event.
     *          MUST revert if all of the assets cannot be withdrawn (due to insufficient assets, withdrawal limits, slippage, etc).
     *  @param  assets_   The amount of assets to withdraw.
     *  @param  receiver_ The receiver of the assets.
     *  @param  owner_    The owner of the assets.
     *  @return shares_   The amount of shares burned from the owner.
     */
    function withdraw(uint256 assets_, address receiver_, address owner_) external returns (uint256 shares_);

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    The amount of `assets_` the `shares_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to convert.
     *  @return assets_ The amount of equivalent assets.
     */
    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    The amount of `shares_` the `assets_` are currently equivalent to.
     *          MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     *          MUST NOT reflect slippage or other on-chain conditions when performing the actual exchange.
     *          MUST NOT show any variations depending on the caller.
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to convert.
     *  @return shares_ The amount of equivalent shares.
     */
    function convertToShares(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be deposited on behalf of the `receiver_` through a `deposit` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the assets.
     *  @return assets_   The maximum amount of assets that can be deposited.
     */
    function maxDeposit(address receiver_) external view returns (uint256 assets_);

    /**
     *  @dev    Maximum amount of `shares_` that can be minted on behalf of the `receiver_` through a `mint` call.
     *          MUST return a limited value if the receiver is subject to any limits, or the maximum value otherwise.
     *          MUST NOT revert.
     *  @param  receiver_ The receiver of the shares.
     *  @return shares_   The maximum amount of shares that can be minted.
     */
    function maxMint(address receiver_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `shares_` that can be redeemed from the `owner_` through a `redeem` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned shares otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the shares.
     *  @return shares_ The maximum amount of shares that can be redeemed.
     */
    function maxRedeem(address owner_) external view returns (uint256 shares_);

    /**
     *  @dev    Maximum amount of `assets_` that can be withdrawn from the `owner_` through a `withdraw` call.
     *          MUST return a limited value if the owner is subject to any limits, or the total amount of owned assets otherwise.
     *          MUST NOT revert.
     *  @param  owner_  The owner of the assets.
     *  @return assets_ The maximum amount of assets that can be withdrawn.
     */
    function maxWithdraw(address owner_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of shares that would be minted in a `deposit` call in the same transaction.
     *          MUST NOT account for deposit limits like those returned from `maxDeposit` and should always act as though the deposit would be accepted.
     *  @param  assets_ The amount of assets to deposit.
     *  @return shares_ The amount of shares that would be minted.
     */
    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of assets that would be deposited in a `mint` call in the same transaction.
     *          MUST NOT account for mint limits like those returned from `maxMint` and should always act as though the minting would be accepted.
     *  @param  shares_ The amount of shares to mint.
     *  @return assets_ The amount of assets that would be deposited.
     */
    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of assets that would be withdrawn in a `redeem` call in the same transaction.
     *          MUST NOT account for redemption limits like those returned from `maxRedeem` and should always act as though the redemption would be accepted.
     *  @param  shares_ The amount of shares to redeem.
     *  @return assets_ The amount of assets that would be withdrawn.
     */
    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of shares that would be burned in a `withdraw` call in the same transaction.
     *          MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should always act as though the withdrawal would be accepted.
     *  @param  assets_ The amount of assets to withdraw.
     *  @return shares_ The amount of shares that would be redeemed.
     */
    function previewWithdraw(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Total amount of the underlying asset that is managed by the Vault.
     *          SHOULD include compounding that occurs from any yields.
     *          MUST NOT revert.
     *  @return totalAssets_ The total amount of assets the Vault manages.
     */
    function totalAssets() external view returns (uint256 totalAssets_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { IERC20 } from "../../modules/erc20/contracts/interfaces/IERC20.sol";

import { IERC4626 } from "./IERC4626.sol";

interface IPool is IERC20, IERC4626 {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Initial shares amount was minted to the zero address to prevent the first depositor frontrunning exploit.
     *  @param caller_              The caller of the function that emitted the `BootstrapMintPerformed` event.
     *  @param receiver_            The user that was minted the shares.
     *  @param assets_              The amount of assets deposited.
     *  @param shares_              The amount of shares that would have been minted to the user if it was not the first deposit.
     *  @param bootStrapMintAmount_ The amount of shares that was minted to the zero address to protect the first depositor.
     */
    event BootstrapMintPerformed(address indexed caller_, address indexed receiver_, uint256 assets_, uint256 shares_, uint256 bootStrapMintAmount_);

    /**
     *  @dev   `newOwner_` has accepted the transferral of RDT ownership from `previousOwner_`.
     *  @param previousOwner_ The previous RDT owner.
     *  @param newOwner_      The new RDT owner.
     */
    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);

    /**
     *  @dev   `owner_` has set the new pending owner of RDT to `pendingOwner_`.
     *  @param owner_        The current RDT owner.
     *  @param pendingOwner_ The new pending RDT owner.
     */
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);

    /**
     *  @dev   A new redemption request has been made.
     *  @param owner_          The owner of shares.
     *  @param shares_         The amount of shares requested to redeem.
     *  @param escrowedShares_ The amount of shares actually escrowed for this withdrawal request.
     */
    event RedemptionRequested(address indexed owner_, uint256 shares_, uint256 escrowedShares_);

    /**
     *  @dev   Shares have been removed.
     *  @param owner_  The owner of shares.
     *  @param shares_ The amount of shares requested to be removed.
     */
    event SharesRemoved(address indexed owner_, uint256 shares_);

    /**
     *  @dev   A new withdrawal request has been made.
     *  @param owner_          The owner of shares.
     *  @param assets_         The amount of assets requested to withdraw.
     *  @param escrowedShares_ The amount of shares actually escrowed for this withdrawal request.
     */
    event WithdrawRequested(address indexed owner_, uint256 assets_, uint256 escrowedShares_);

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    The amount of shares that will be burned during the first deposit/mint.
     *  @return bootstrapMint_ The amount of shares to be burned.
     */
    function BOOTSTRAP_MINT() external view returns (uint256 bootstrapMint_);

    /**
     *  @dev    The address of the account that is allowed to update the vesting schedule.
     *  @return manager_ The address of the pool manager.
     */
    function manager() external view returns (address manager_);

    /******************************************************************************************************************************/
    /*** LP Functions                                                                                                           ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Does a ERC4626 `deposit` with a ERC-2612 `permit`.
     *  @param  assets_   The amount of `asset` to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @param  deadline_ The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_        ECDSA signature v component.
     *  @param  r_        ECDSA signature r component.
     *  @param  s_        ECDSA signature s component.
     *  @return shares_   The amount of shares minted.
     */
    function depositWithPermit(uint256 assets_, address receiver_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 shares_);

    /**
     *  @dev    Does a ERC4626 `mint` with a ERC-2612 `permit`.
     *  @param  shares_    The amount of `shares` to mint.
     *  @param  receiver_  The receiver of the shares.
     *  @param  maxAssets_ The maximum amount of assets that can be taken, as per the permit.
     *  @param  deadline_  The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_         ECDSA signature v component.
     *  @param  r_         ECDSA signature r component.
     *  @param  s_         ECDSA signature s component.
     *  @return assets_    The amount of shares deposited.
     */
    function mintWithPermit(uint256 shares_, address receiver_, uint256 maxAssets_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) external returns (uint256 assets_);

    /******************************************************************************************************************************/
    /*** Withdrawal Request Functions                                                                                           ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Removes shares from the withdrawal mechanism, can only be called after the beginning of the withdrawal window has passed.
     *  @param  shares_         The amount of shares to redeem.
     *  @param  owner_          The owner of the shares.
     *  @return sharesReturned_ The amount of shares withdrawn.
     */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /**
     *  @dev    Requests a withdrawal of assets from the pool.
     *  @param  assets_       The amount of assets to withdraw.
     *  @param  owner_        The owner of the shares.
     *  @return escrowShares_ The amount of shares sent to escrow.
     */
    function requestWithdraw(uint256 assets_, address owner_) external returns (uint256 escrowShares_);

    /**
     *  @dev    Requests a redemption of shares from the pool.
     *  @param  shares_       The amount of shares to redeem.
     *  @param  owner_        The owner of the shares.
     *  @return escrowShares_ The amount of shares sent to escrow.
     */
    function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowShares_);

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Returns the amount of underlying assets owned by the specified account.
     *  @param  account_ Address of the account.
     *  @return assets_  Amount of assets owned.
     */
    function balanceOfAssets(address account_) external view returns (uint256 assets_);

    /**
     *  @dev    Returns the amount of exit assets for the input amount.
     *  @param  shares_ The amount of shares to convert to assets.
     *  @return assets_ Amount of assets able to be exited.
     */
    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Returns the amount of exit shares for the input amount.
     *  @param  assets_ The amount of assets to convert to shares.
     *  @return shares_ Amount of shares able to be exited.
     */
    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IERC20Like {

    function balanceOf(address account_) external view returns (uint256 balance_);

    function decimals() external view returns (uint8 decimals_);

    function totalSupply() external view returns (uint256 totalSupply_);

}

interface ILoanManagerLike {

    function acceptNewTerms(
        address loan_,
        address refinancer_,
        uint256 deadline_,
        bytes[] calldata calls_
    ) external;

    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    function claim(address loan_, bool hasSufficientCover_) external;

    function finishCollateralLiquidation(address loan_) external returns (uint256 remainingLosses_, uint256 serviceFee_);

    function fund(address loan_) external;

    function removeLoanImpairment(address loan_, bool isGovernor_) external;

    function setAllowedSlippage(address collateralAsset_, uint256 allowedSlippage_) external;

    function setMinRatio(address collateralAsset_, uint256 minRatio_) external;

    function impairLoan(address loan_, bool isGovernor_) external;

    function triggerDefault(address loan_, address liquidatorFactory_) external returns (bool liquidationComplete_, uint256 remainingLosses_, uint256 platformFees_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

}

interface ILoanManagerInitializerLike {

    function encodeArguments(address pool_) external pure returns (bytes memory calldata_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_);

}

interface ILiquidatorLike {

    function collateralRemaining() external view returns (uint256 collateralRemaining_);

    function liquidatePortion(uint256 swapAmount_, uint256 maxReturnAmount_, bytes calldata data_) external;

    function pullFunds(address token_, address destination_, uint256 amount_) external;

    function setCollateralRemaining(uint256 collateralAmount_) external;

}

interface IMapleGlobalsLike {

    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    function getLatestPrice(address asset_) external view returns (uint256 price_);

    function governor() external view returns (address governor_);

    function isBorrower(address account_) external view returns (bool isBorrower_);

    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);

    function isPoolDelegate(address account_) external view returns (bool isPoolDelegate_);

    function isPoolDeployer(address poolDeployer_) external view returns (bool isPoolDeployer_);

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    function migrationAdmin() external view returns (address migrationAdmin_);

    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    function mapleTreasury() external view returns (address mapleTreasury_);

    function ownedPoolManager(address poolDelegate_) external view returns (address poolManager_);

    function protocolPaused() external view returns (bool protocolPaused_);

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

}

interface IMapleLoanLike {

    function acceptLender() external;

    function acceptNewTerms(address refinancer_, uint256 deadline_, bytes[] calldata calls_) external returns (bytes32 refinanceCommitment_);

    function batchClaimFunds(uint256[] memory amounts_, address[] memory destinations_) external;

    function borrower() external view returns (address borrower_);

    function claimFunds(uint256 amount_, address destination_) external;

    function collateral() external view returns (uint256 collateral);

    function collateralAsset() external view returns(address asset_);

    function feeManager() external view returns (address feeManager_);

    function fundsAsset() external view returns (address asset_);

    function fundLoan(address lender_) external returns (uint256 fundsLent_);

    function getClosingPaymentBreakdown() external view returns (
        uint256 principal_,
        uint256 interest_,
        uint256 delegateServiceFee_,
        uint256 platformServiceFee_
    );

    function getNextPaymentDetailedBreakdown() external view returns (
        uint256 principal_,
        uint256[3] memory interest_,
        uint256[2] memory fees_
    );

    function getNextPaymentBreakdown() external view returns (
        uint256 principal_,
        uint256 interest_,
        uint256 fees_
    );

    function getUnaccountedAmount(address asset_) external view returns (uint256 unaccountedAmount_);

    function gracePeriod() external view returns (uint256 gracePeriod_);

    function interestRate() external view returns (uint256 interestRate_);

    function isImpaired() external view returns (bool isImpaired_);

    function lateFeeRate() external view returns (uint256 lateFeeRate_);

    function lender() external view returns (address lender_);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function originalNextPaymentDueDate() external view returns (uint256 originalNextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function paymentsRemaining() external view returns (uint256 paymentsRemaining_);

    function principal() external view returns (uint256 principal_);

    function principalRequested() external view returns (uint256 principalRequested_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function removeLoanImpairment() external;

    function repossess(address destination_) external returns (uint256 collateralRepossessed_, uint256 fundsRepossessed_);

    function setPendingLender(address pendingLender_) external;

    function skim(address token_, address destination_) external returns (uint256 skimmed_);

    function impairLoan() external;

    function unimpairedPaymentDueDate() external view returns (uint256 unimpairedPaymentDueDate_);

}

interface IMapleLoanV3Like {

    function acceptLender() external;

    function getNextPaymentBreakdown() external view returns (uint256 principal_, uint256 interest_, uint256, uint256);

    function nextPaymentDueDate() external view returns (uint256 nextPaymentDueDate_);

    function paymentInterval() external view returns (uint256 paymentInterval_);

    function principal() external view returns (uint256 principal_);

    function refinanceInterest() external view returns (uint256 refinanceInterest_);

    function setPendingLender(address pendingLender_) external;

}

interface IMapleProxyFactoryLike {

    function mapleGlobals() external view returns (address mapleGlobals_);

}

interface ILoanFactoryLike {

    function isLoan(address loan_) external view returns (bool isLoan_);

}

interface IPoolDelegateCoverLike {

    function moveFunds(uint256 amount_, address recipient_) external;

}

interface IPoolLike is IERC20Like {

    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    function asset() external view returns (address asset_);

    function convertToAssets(uint256 shares_) external view returns (uint256 assets_);

    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function deposit(uint256 assets_, address receiver_) external returns (uint256 shares_);

    function manager() external view returns (address manager_);

    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    function processExit(uint256 shares_, uint256 assets_, address receiver_, address owner_) external;

    function redeem(uint256 shares_, address receiver_, address owner_) external returns (uint256 assets_);

}

interface IPoolManagerLike {

    function addLoanManager(address loanManager_) external;

    function canCall(bytes32 functionId_, address caller_, bytes memory data_) external view returns (bool canCall_, string memory errorMessage_);

    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    function claim(address loan_) external;

    function delegateManagementFeeRate() external view returns (uint256 delegateManagementFeeRate_);

    function fund(uint256 principalAmount_, address loan_, address loanManager_) external;

    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address escrow_);

    function globals() external view returns (address globals_);

    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    function loanManager() external view returns (address loanManager_);

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    function processRedeem(uint256 shares_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function processWithdraw(uint256 assets_, address owner_, address sender_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function poolDelegate() external view returns (address poolDelegate_);

    function poolDelegateCover() external view returns (address poolDelegateCover_);

    function removeLoanManager(address loanManager_) external;

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    function requestRedeem(uint256 shares_, address owner_, address sender_) external;

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    function setWithdrawalManager(address withdrawalManager_) external;

    function totalAssets() external view returns (uint256 totalAssets_);

    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);

    function withdrawalManager() external view returns (address withdrawalManager_);

}

interface IWithdrawalManagerInitializerLike {

    function encodeArguments(address pool_, uint256 cycleDuration_, uint256 windowDuration_) external pure returns (bytes memory calldata_);

    function decodeArguments(bytes calldata calldata_) external pure returns (address pool_, uint256 cycleDuration_, uint256 windowDuration_);

}

interface IWithdrawalManagerLike {

    function addShares(uint256 shares_, address owner_) external;

    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);

    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);

    function lockedShares(address owner_) external view returns (uint256 lockedShares_);

    function previewRedeem(address owner_, uint256 shares) external view returns (uint256 redeemableShares, uint256 resultingAssets_);

    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 redeemableAssets_, uint256 resultingShares_);

    function processExit(uint256 shares_, address account_) external returns (uint256 redeemableShares_, uint256 resultingAssets_);

    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

import { IERC20 } from "./interfaces/IERC20.sol";

/*
    ███████╗██████╗  ██████╗    ██████╗  ██████╗
    ██╔════╝██╔══██╗██╔════╝    ╚════██╗██╔═████╗
    █████╗  ██████╔╝██║          █████╔╝██║██╔██║
    ██╔══╝  ██╔══██╗██║         ██╔═══╝ ████╔╝██║
    ███████╗██║  ██║╚██████╗    ███████╗╚██████╔╝
    ╚══════╝╚═╝  ╚═╝ ╚═════╝    ╚══════╝ ╚═════╝
*/

/**
 *  @title Modern ERC-20 implementation.
 *  @dev   Acknowledgements to Solmate, OpenZeppelin, and DSS for inspiring this code.
 */
contract ERC20 is IERC20 {

    /**************/
    /*** ERC-20 ***/
    /**************/

    string public override name;
    string public override symbol;

    uint8 public immutable override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;

    mapping(address => mapping(address => uint256)) public override allowance;

    /****************/
    /*** ERC-2612 ***/
    /****************/

    // PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    mapping(address => uint256) public override nonces;

    /**
     *  @param name_     The name of the token.
     *  @param symbol_   The symbol of the token.
     *  @param decimals_ The decimal precision used by the token.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name     = name_;
        symbol   = symbol_;
        decimals = decimals_;
    }

    /**************************/
    /*** External Functions ***/
    /**************************/

    function approve(address spender_, uint256 amount_) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedAmount_) public virtual override returns (bool success_) {
        _decreaseAllowance(msg.sender, spender_, subtractedAmount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedAmount_) public virtual override returns (bool success_) {
        _approve(msg.sender, spender_, allowance[msg.sender][spender_] + addedAmount_);
        return true;
    }

    function permit(address owner_, address spender_, uint256 amount_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_) public virtual override {
        require(deadline_ >= block.timestamp, "ERC20:P:EXPIRED");

        // Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}.
        require(
            uint256(s_) <= uint256(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) &&
            (v_ == 27 || v_ == 28),
            "ERC20:P:MALLEABLE"
        );

        // Nonce realistically cannot overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner_, spender_, amount_, nonces[owner_]++, deadline_))
                )
            );

            address recoveredAddress = ecrecover(digest, v_, r_, s_);

            require(recoveredAddress == owner_ && owner_ != address(0), "ERC20:P:INVALID_SIGNATURE");
        }

        _approve(owner_, spender_, amount_);
    }

    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool success_) {
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address owner_, address recipient_, uint256 amount_) public virtual override returns (bool success_) {
        _decreaseAllowance(owner_, msg.sender, amount_);
        _transfer(owner_, recipient_, amount_);
        return true;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function DOMAIN_SEPARATOR() public view override returns (bytes32 domainSeparator_) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        emit Approval(owner_, spender_, allowance[owner_][spender_] = amount_);
    }

    function _burn(address owner_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot underflow because a user's balance will never be larger than the total supply.
        unchecked { totalSupply -= amount_; }

        emit Transfer(owner_, address(0), amount_);
    }

    function _decreaseAllowance(address owner_, address spender_, uint256 subtractedAmount_) internal {
        uint256 spenderAllowance = allowance[owner_][spender_];  // Cache to memory.

        if (spenderAllowance != type(uint256).max) {
            _approve(owner_, spender_, spenderAllowance - subtractedAmount_);
        }
    }

    function _mint(address recipient_, uint256 amount_) internal {
        totalSupply += amount_;

        // Cannot overflow because totalSupply would first overflow in the statement above.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(address(0), recipient_, amount_);
    }

    function _transfer(address owner_, address recipient_, uint256 amount_) internal {
        balanceOf[owner_] -= amount_;

        // Cannot overflow because minting prevents overflow of totalSupply, and sum of user balances == totalSupply.
        unchecked { balanceOf[recipient_] += amount_; }

        emit Transfer(owner_, recipient_, amount_);
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.7;

/// @title Interface of the ERC20 standard as defined in the EIP, including EIP-2612 permit functionality.
interface IERC20 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Emitted when one account has set the allowance of another account over their tokens.
     *  @param owner_   Account that tokens are approved from.
     *  @param spender_ Account that tokens are approved for.
     *  @param amount_  Amount of tokens that have been approved.
     */
    event Approval(address indexed owner_, address indexed spender_, uint256 amount_);

    /**
     *  @dev   Emitted when tokens have moved from one account to another.
     *  @param owner_     Account that tokens have moved from.
     *  @param recipient_ Account that tokens have moved to.
     *  @param amount_    Amount of tokens that have been transferred.
     */
    event Transfer(address indexed owner_, address indexed recipient_, uint256 amount_);

    /**************************/
    /*** External Functions ***/
    /**************************/

    /**
     *  @dev    Function that allows one account to set the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_ Account that tokens are approved for.
     *  @param  amount_  Amount of tokens that have been approved.
     *  @return success_ Boolean indicating whether the operation succeeded.
     */
    function approve(address spender_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to decrease the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_          Account that tokens are approved for.
     *  @param  subtractedAmount_ Amount to decrease approval by.
     *  @return success_          Boolean indicating whether the operation succeeded.
     */
    function decreaseAllowance(address spender_, uint256 subtractedAmount_) external returns (bool success_);

    /**
     *  @dev    Function that allows one account to increase the allowance of another account over their tokens.
     *          Emits an {Approval} event.
     *  @param  spender_     Account that tokens are approved for.
     *  @param  addedAmount_ Amount to increase approval by.
     *  @return success_     Boolean indicating whether the operation succeeded.
     */
    function increaseAllowance(address spender_, uint256 addedAmount_) external returns (bool success_);

    /**
     *  @dev   Approve by signature.
     *  @param owner_    Owner address that signed the permit.
     *  @param spender_  Spender of the permit.
     *  @param amount_   Permit approval spend limit.
     *  @param deadline_ Deadline after which the permit is invalid.
     *  @param v_        ECDSA signature v component.
     *  @param r_        ECDSA signature r component.
     *  @param s_        ECDSA signature s component.
     */
    function permit(address owner_, address spender_, uint amount_, uint deadline_, uint8 v_, bytes32 r_, bytes32 s_) external;

    /**
     *  @dev    Moves an amount of tokens from `msg.sender` to a specified account.
     *          Emits a {Transfer} event.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transfer(address recipient_, uint256 amount_) external returns (bool success_);

    /**
     *  @dev    Moves a pre-approved amount of tokens from a sender to a specified account.
     *          Emits a {Transfer} event.
     *          Emits an {Approval} event.
     *  @param  owner_     Account that tokens are moving from.
     *  @param  recipient_ Account that receives tokens.
     *  @param  amount_    Amount of tokens that are transferred.
     *  @return success_   Boolean indicating whether the operation succeeded.
     */
    function transferFrom(address owner_, address recipient_, uint256 amount_) external returns (bool success_);

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the allowance that one account has given another over their tokens.
     *  @param  owner_     Account that tokens are approved from.
     *  @param  spender_   Account that tokens are approved for.
     *  @return allowance_ Allowance that one account has given another over their tokens.
     */
    function allowance(address owner_, address spender_) external view returns (uint256 allowance_);

    /**
     *  @dev    Returns the amount of tokens owned by a given account.
     *  @param  account_ Account that owns the tokens.
     *  @return balance_ Amount of tokens owned by a given account.
     */
    function balanceOf(address account_) external view returns (uint256 balance_);

    /**
     *  @dev    Returns the decimal precision used by the token.
     *  @return decimals_ The decimal precision used by the token.
     */
    function decimals() external view returns (uint8 decimals_);

    /**
     *  @dev    Returns the signature domain separator.
     *  @return domainSeparator_ The signature domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32 domainSeparator_);

    /**
     *  @dev    Returns the name of the token.
     *  @return name_ The name of the token.
     */
    function name() external view returns (string memory name_);

    /**
      *  @dev    Returns the nonce for the given owner.
      *  @param  owner_  The address of the owner account.
      *  @return nonce_ The nonce for the given owner.
     */
    function nonces(address owner_) external view returns (uint256 nonce_);

    /**
     *  @dev    Returns the permit type hash.
     *  @return permitTypehash_ The permit type hash.
     */
    function PERMIT_TYPEHASH() external view returns (bytes32 permitTypehash_);

    /**
     *  @dev    Returns the symbol of the token.
     *  @return symbol_ The symbol of the token.
     */
    function symbol() external view returns (string memory symbol_);

    /**
     *  @dev    Returns the total amount of tokens in existence.
     *  @return totalSupply_ The total amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256 totalSupply_);

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