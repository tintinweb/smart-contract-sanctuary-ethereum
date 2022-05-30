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

/// @title A standard for tokenized Vaults with a single underlying ERC-20 token.
interface IERC4626 is IERC20 {

    /**************/
    /*** Events ***/
    /**************/

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

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev    The address of the underlying asset used by the Vault.
     *          MUST be a contract that implements the ERC-20 standard.
     *          MUST NOT revert.
     *  @return asset_ The address of the underlying asset.
     */
    function asset() external view returns (address asset_);

    /********************************/
    /*** State Changing Functions ***/
    /********************************/

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

    /**********************/
    /*** View Functions ***/
    /**********************/

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
     *          MUST NOT revert.
     *  @param  assets_ The amount of assets to deposit.
     *  @return shares_ The amount of shares that would be minted.
     */
    function previewDeposit(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of assets that would be deposited in a `mint` call in the same transaction.
     *          MUST NOT account for mint limits like those returned from `maxMint` and should always act as though the minting would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to mint.
     *  @return assets_ The amount of assets that would be deposited.
     */
    function previewMint(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block, given current on-chain conditions.
     *          MUST return as close to and no more than the exact amount of assets that would be withdrawn in a `redeem` call in the same transaction.
     *          MUST NOT account for redemption limits like those returned from `maxRedeem` and should always act as though the redemption would be accepted.
     *          MUST NOT revert.
     *  @param  shares_ The amount of shares to redeem.
     *  @return assets_ The amount of assets that would be withdrawn.
     */
    function previewRedeem(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block, given current on-chain conditions.
     *          MUST return as close to and no fewer than the exact amount of shares that would be burned in a `withdraw` call in the same transaction.
     *          MUST NOT account for withdrawal limits like those returned from `maxWithdraw` and should always act as though the withdrawal would be accepted.
     *          MUST NOT revert.
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

/// @title A token that represents ownership of future revenues distributed linearly over time.
interface IRevenueDistributionToken is IERC20, IERC4626 {

    /**************/
    /*** Events ***/
    /**************/

    /**
     *  @dev   Issuance parameters have been updated after a `_mint` or `_burn`.
     *  @param freeAssets_   Resulting `freeAssets` (y-intercept) value after accounting update.
     *  @param issuanceRate_ The new issuance rate of `asset` until `vestingPeriodFinish_`.
     */
    event IssuanceParamsUpdated(uint256 freeAssets_, uint256 issuanceRate_);

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
     *  @dev   `owner_` has updated the RDT vesting schedule to end at `vestingPeriodFinish_`.
     *  @param owner_               The current RDT owner.
     *  @param vestingPeriodFinish_ When the unvested balance will finish vesting.
     */
    event VestingScheduleUpdated(address indexed owner_, uint256 vestingPeriodFinish_);

    /***********************/
    /*** State Variables ***/
    /***********************/

    /**
     *  @dev The total amount of the underlying asset that is currently unlocked and is not time-dependent.
     *       Analogous to the y-intercept in a linear function.
     */
    function freeAssets() external view returns (uint256 freeAssets_);

    /**
     *  @dev The rate of issuance of the vesting schedule that is currently active.
     *       Denominated as the amount of underlying assets vesting per second.
     */
    function issuanceRate() external view returns (uint256 issuanceRate_);

    /**
     *  @dev The timestamp of when the linear function was last recalculated.
     *       Analogous to t0 in a linear function.
     */
    function lastUpdated() external view returns (uint256 lastUpdated_);

    /**
     *  @dev The address of the account that is allowed to update the vesting schedule.
     */
    function owner() external view returns (address owner_);

    /**
     *  @dev The next owner, nominated by the current owner.
     */
    function pendingOwner() external view returns (address pendingOwner_);

    /**
     *  @dev The precision at which the issuance rate is measured.
     */
    function precision() external view returns (uint256 precision_);

    /**
     *  @dev The end of the current vesting schedule.
     */
    function vestingPeriodFinish() external view returns (uint256 vestingPeriodFinish_);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    /**
     *  @dev Sets the pending owner as the new owner.
     *       Can be called only by the pending owner, and only after their nomination by the current owner.
     */
    function acceptOwnership() external;

    /**
     *  @dev   Sets a new address as the pending owner.
     *  @param pendingOwner_ The address of the next potential owner.
     */
    function setPendingOwner(address pendingOwner_) external;

    /**
     *  @dev    Updates the current vesting formula based on the amount of total unvested funds in the contract and the new `vestingPeriod_`.
     *  @param  vestingPeriod_ The amount of time over which all currently unaccounted underlying assets will be vested over.
     *  @return issuanceRate_  The new issuance rate.
     *  @return freeAssets_    The new amount of underlying assets that are unlocked.
     */
    function updateVestingSchedule(uint256 vestingPeriod_) external returns (uint256 issuanceRate_, uint256 freeAssets_);

    /************************/
    /*** Staker Functions ***/
    /************************/

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

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @dev    Returns the amount of underlying assets owned by the specified account.
     *  @param  account_ Address of the account.
     *  @return assets_  Amount of assets owned.
     */
    function balanceOfAssets(address account_) external view returns (uint256 assets_);

}

interface IxMPL is IRevenueDistributionToken {

    /**************/
    /*** Events ***/
    /**************/

    /**
    *  @dev Notifies that a scheduled migration was cancelled.
    */
    event MigrationCancelled();

    /**
    *  @dev   Notifies that a scheduled migration was executed.
    *  @param fromAsset_ The address of the old asset.
    *  @param toAsset_   The address of new asset migrated to.
    *  @param amount_    The amount of tokens migrated.
    */
    event MigrationPerformed(address indexed fromAsset_, address indexed toAsset_, uint256 amount_);

    /**
    *  @dev   Notifies that migration was scheduled.
    *  @param fromAsset_     The current asset address.
    *  @param toAsset_       The address of the asset to be migrated to.
    *  @param migrator_      The address of the migrator contract.
    *  @param migrationTime_ The earliest time the migration is scheduled for.
    */
    event MigrationScheduled(address indexed fromAsset_, address indexed toAsset_, address indexed migrator_, uint256 migrationTime_);

    /********************************/
    /*** Administrative Functions ***/
    /********************************/

    /**
    *  @dev Cancel the scheduled migration
    */
    function cancelMigration() external;

    /**
    *  @dev Perform a migration of the asset.
    */
    function performMigration() external;

    /**
    *  @dev   Schedule a migration to be executed after a delay.
    *  @param migrator_ The address of the migrator contract.
    *  @param newAsset_ The address of the new asset token.
    */
    function scheduleMigration(address migrator_, address newAsset_) external;

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
    *  @dev    Get the minimum delay that a scheduled transaction needs in order to be executed.
    *  @return minimumMigrationDelay_ The delay in seconds.
    */
    function MINIMUM_MIGRATION_DELAY() external pure returns (uint256 minimumMigrationDelay_);

    /**
    *  @dev    Get the timestamp that a migration is scheduled for.
    *  @return scheduledMigrationTimestamp_ The timestamp of the migration.
    */
    function scheduledMigrationTimestamp() external view returns (uint256 scheduledMigrationTimestamp_);

    /**
    *  @dev    The address of the migrator contract to be used during the scheduled migration.
    *  @return scheduledMigrator_ The address of the migrator.
    */
    function scheduledMigrator() external view returns (address scheduledMigrator_);

    /**
    *  @dev    The address of the new asset token to be migrated to during the scheduled migration.
    *  @return scheduledNewAsset_ The address of the new asset token.
    */
    function scheduledNewAsset() external view returns (address scheduledNewAsset_);

}

// Invariant 1:  totalAssets <= underlying balance of contract (with rounding)
// Invariant 2:  ∑ balanceOfAssets == totalAssets (with rounding)
// Invariant 3:  totalSupply <= totalAssets
// Invariant 4:  convertToAssets(totalSupply) == totalAssets (with rounding)
// Invariant 5:  freeAssets <= totalAssets
// Invariant 6:  balanceOfAssets >= balanceOf
// Invariant 7:  freeAssets <= underlying balance
// Invariant 8:  issuanceRate == 0 (if post vesting)
// Invariant 9:  issuanceRate > 0 (if mid vesting)

contract xMPLHealthChecker {

    // Structs to avoid stack too deep compiler error.
    struct Invariants {
        bool invariant1;
        bool invariant2;
        bool invariant3;
        bool invariant4;
        bool invariant5;
        bool invariant6;
        bool invariant7;
        bool invariant8;
        bool invariant9;
    }

    struct State {
        uint256 blockNumber;
        uint256 blockTimestamp;
        uint256 freeAssets;
        uint256 invariant4Diff;
        uint256 issuanceRate;
        uint256 lastUpdated;
        uint256 mplBalanceOfXMPL;
        uint256 sumBalanceOfAssets;
        uint256 supplyConvertedToAssets;
        uint256 totalAssets;
        uint256 totalSupply;
        uint256 vestingPeriodFinish;

        // Values for the first failed staker (6th invariant).
        address staker;
        uint256 stakerBalanceOfAssets;
        uint256 stakerBalanceOf;
    }

    IERC20 MPL;
    IxMPL xMPL;

    constructor(address xMPL_) {
        xMPL = IxMPL(xMPL_);
        MPL  = IERC20(xMPL.asset());
    }

    /****************/
    /*** Checkers ***/
    /****************/

    function checkInvariants(address[] memory xMPLHolders_) external view returns (Invariants memory invariants_, State memory state_) {
        // Get all state.
        state_.totalAssets             = xMPL.totalAssets();
        state_.totalSupply             = xMPL.totalSupply();
        state_.supplyConvertedToAssets = xMPL.convertToAssets(state_.totalSupply);
        state_.freeAssets              = xMPL.freeAssets();
        state_.lastUpdated             = xMPL.lastUpdated();
        state_.vestingPeriodFinish     = xMPL.vestingPeriodFinish();
        state_.issuanceRate            = xMPL.issuanceRate();

        state_.mplBalanceOfXMPL = MPL.balanceOf(address(xMPL));

        state_.blockTimestamp = block.timestamp;
        state_.blockNumber    = block.number;

        // Invariants 1, 3-5, 7-9
        invariants_.invariant1 = _totalAssets_lte_assetBalance(state_.totalAssets, state_.mplBalanceOfXMPL);
        invariants_.invariant3 = _totalSupply_lte_totalAssets(state_.totalSupply, state_.totalAssets);
        invariants_.invariant5 = _freeAssets_lte_totalAssets(state_.freeAssets, state_.totalAssets);
        invariants_.invariant7 = _freeAssets_lte_assetBalance(state_.freeAssets, state_.mplBalanceOfXMPL);
        invariants_.invariant8 = _issuanceRate_eq_zero_ifPostVesting(state_.blockTimestamp, state_.lastUpdated, state_.vestingPeriodFinish, state_.issuanceRate);
        invariants_.invariant9 = _issuanceRate_gt_zero_ifMidVesting(state_.blockTimestamp, state_.vestingPeriodFinish, state_.issuanceRate);

        // Invariants 2, 4
        ( invariants_.invariant2, state_.sumBalanceOfAssets ) = _sumBalanceOfAssets_eq_totalAssets(xMPLHolders_, state_.totalAssets);
        ( invariants_.invariant4, state_.invariant4Diff )     = _totalSupply_times_exchangeRate_eq_totalAssets(state_.totalSupply, state_.totalAssets, state_.supplyConvertedToAssets);

        // Invariant 6
        ( invariants_.invariant6, state_.staker, state_.stakerBalanceOfAssets, state_.stakerBalanceOf ) = balanceOfAssets_gte_balanceOf(xMPLHolders_);
    }

    /*******************/
    /*** Invariant 1 ***/
    /*******************/

    function totalAssets_lte_assetBalance() external view returns (bool isMaintained_, uint256 totalAssets_, uint256 mplBalanceOfXMPL_) {
        totalAssets_      = xMPL.totalAssets();
        mplBalanceOfXMPL_ = MPL.balanceOf(address(xMPL));

        isMaintained_ = _totalAssets_lte_assetBalance(totalAssets_, mplBalanceOfXMPL_);
    }

    function _totalAssets_lte_assetBalance(uint256 totalAssets_, uint256 mplBalanceOfXMPL_) internal pure returns (bool isMaintained_) {
        isMaintained_ = totalAssets_ <= mplBalanceOfXMPL_;
    }

    /*******************/
    /*** Invariant 2 ***/
    /*******************/

    function sumBalanceOfAssets_eq_totalAssets(address[] memory stakers_) public view returns (bool isMaintained_, uint256 totalAssets_, uint256 sumBalanceOfAssets_) {
        // Fork mainnet at block N, and just check the state there. The state is frozen, so you won't get issues not being able to check state atomically.
        totalAssets_ = xMPL.totalAssets();

        ( isMaintained_, sumBalanceOfAssets_ ) = _sumBalanceOfAssets_eq_totalAssets(stakers_, totalAssets_);
    }

    function _sumBalanceOfAssets_eq_totalAssets(address[] memory stakers_, uint256 totalAssets_) internal view returns (bool isMaintained_, uint256 sumBalanceOfAssets_) {
        if (xMPL.totalSupply() > 0) {
            for (uint256 i; i < stakers_.length; ++i) {
                sumBalanceOfAssets_ += xMPL.balanceOfAssets(stakers_[i]);
            }
            isMaintained_ = _getDiff(sumBalanceOfAssets_, totalAssets_) <= stakers_.length;
        } else {
            isMaintained_ = true;
        }
    }

    /*******************/
    /*** Invariant 3 ***/
    /*******************/

    function totalSupply_lte_totalAssets() external view returns (bool isMaintained_, uint256 totalSupply_, uint256 totalAssets_) {
        totalSupply_ = xMPL.totalSupply();
        totalAssets_ = xMPL.totalAssets();

        isMaintained_ = _totalSupply_lte_totalAssets(totalSupply_, totalAssets_);
    }

    function _totalSupply_lte_totalAssets(uint256 totalSupply_, uint256 totalAssets_) internal pure returns (bool isMaintained_) {
        isMaintained_ = totalSupply_ <= totalAssets_;
    }

    /*******************/
    /*** Invariant 4 ***/
    /*******************/

    function totalSupply_times_exchangeRate_eq_totalAssets() external view returns (bool isMaintained_, uint256 totalSupply_, uint256 totalAssets_, uint256 supplyConvertedToAssets_, uint256 diff_) {
        totalSupply_             = xMPL.totalSupply();
        totalAssets_             = xMPL.totalAssets();
        supplyConvertedToAssets_ = xMPL.convertToAssets(totalSupply_);

        ( isMaintained_, diff_ ) = _totalSupply_times_exchangeRate_eq_totalAssets(totalSupply_, totalAssets_, supplyConvertedToAssets_);
    }

    function _totalSupply_times_exchangeRate_eq_totalAssets(uint256 totalSupply_, uint256 totalAssets_, uint256 supplyConvertedToAssets_) internal pure returns (bool isMaintained_, uint256 diff_) {
        if (totalSupply_ > 0) {
            diff_ = _getDiff(supplyConvertedToAssets_, totalAssets_);
            isMaintained_ = diff_ <= 1;
        }
        else {
            isMaintained_ = true;
        }
    }

    /*******************/
    /*** Invariant 5 ***/
    /*******************/

    function freeAssets_lte_totalAssets() external view returns (bool isMaintained_, uint256 freeAssets_, uint256 totalAssets_) {
        freeAssets_  = xMPL.freeAssets();
        totalAssets_ = xMPL.totalAssets();

        isMaintained_ = _freeAssets_lte_totalAssets(freeAssets_, totalAssets_);
    }

    function _freeAssets_lte_totalAssets(uint256 freeAssets_, uint256 totalAssets_) internal pure returns (bool isMaintained_) {
        isMaintained_ = freeAssets_ <= totalAssets_;
    }

    /*******************/
    /*** Invariant 6 ***/
    /*******************/

    function balanceOfAssets_gte_balanceOf(address[] memory stakers_) public view
        returns (
            bool    isMaintained_,
            address staker_,
            uint256 balanceOfAssets_,
            uint256 balanceOf_
        )
    {
        isMaintained_ = true;

        for (uint256 i = 0; i < stakers_.length; ++i) {
            staker_          = stakers_[i];
            balanceOfAssets_ = xMPL.balanceOfAssets(stakers_[i]);
            balanceOf_       = xMPL.balanceOf(stakers_[i]);

            if (balanceOfAssets_ < balanceOf_) {
                isMaintained_ = false;
                break;
            }
        }
    }

    function balanceOfAssets_gte_balanceOf(address staker_) public view returns (bool isMaintained_, uint256 balanceOfAssets_, uint256 balanceOf_) {
        balanceOfAssets_ = xMPL.balanceOfAssets(staker_);
        balanceOf_       = xMPL.balanceOf(staker_);

        isMaintained_ = balanceOfAssets_ >= balanceOf_;
    }

    /*******************/
    /*** Invariant 7 ***/
    /*******************/

    function freeAssets_lte_assetBalance() external view returns (bool isMaintained_, uint256 freeAssets_, uint256 mplBalanceOfXMPL_) {
        freeAssets_       = xMPL.freeAssets();
        mplBalanceOfXMPL_ = MPL.balanceOf(address(xMPL));

        isMaintained_ = _freeAssets_lte_assetBalance(freeAssets_, mplBalanceOfXMPL_);
    }

    function _freeAssets_lte_assetBalance(uint256 freeAssets_, uint256 mplBalanceOfXMPL_) internal pure returns (bool isMaintained_) {
        isMaintained_ = freeAssets_ <= mplBalanceOfXMPL_;
    }

    /*******************/
    /*** Invariant 8 ***/
    /*******************/

    function issuanceRate_eq_zero_ifPostVesting() external view
        returns (
            bool    isMaintained_,
            uint256 blockTimestamp_,
            uint256 lastUpdated_,
            uint256 vestingPeriodFinish_,
            uint256 issuanceRate_
        )
    {
        blockTimestamp_      = block.timestamp;
        lastUpdated_         = xMPL.lastUpdated();
        vestingPeriodFinish_ = xMPL.vestingPeriodFinish();
        issuanceRate_        = xMPL.issuanceRate();

        isMaintained_ = _issuanceRate_eq_zero_ifPostVesting(blockTimestamp_, lastUpdated_, vestingPeriodFinish_, issuanceRate_);
    }

    function _issuanceRate_eq_zero_ifPostVesting(
        uint256 blockTimestamp_,
        uint256 lastUpdated_,
        uint256 vestingPeriodFinish_,
        uint256 issuanceRate_
    ) internal pure returns (bool isMaintained_)
    {
        if (blockTimestamp_ > vestingPeriodFinish_ && lastUpdated_ > vestingPeriodFinish_) {
            isMaintained_ = issuanceRate_ == 0;
        } else {
            isMaintained_ = true;
        }
    }

    /*******************/
    /*** Invariant 9 ***/
    /*******************/

    function issuanceRate_gt_zero_ifMidVesting() external view
        returns (
            bool    isMaintained_,
            uint256 blockTimestamp_,
            uint256 vestingPeriodFinish_,
            uint256 issuanceRate_
        )
    {
        blockTimestamp_      = block.timestamp;
        vestingPeriodFinish_ = xMPL.vestingPeriodFinish();
        issuanceRate_        = xMPL.issuanceRate();

        isMaintained_ = _issuanceRate_gt_zero_ifMidVesting(blockTimestamp_, vestingPeriodFinish_, issuanceRate_);
    }

    function _issuanceRate_gt_zero_ifMidVesting(
        uint256 blockTimestamp_,
        uint256 vestingPeriodFinish_,
        uint256 issuanceRate_
    ) internal pure returns (bool isMaintained_)
    {
        if (blockTimestamp_ <= vestingPeriodFinish_) {
            isMaintained_ = issuanceRate_ > 0;
        } else {
            isMaintained_ = true;
        }
    }

    /***************/
    /*** Helpers ***/
    /***************/

    function _getDiff(uint256 x, uint256 y) internal pure returns (uint256 diff) {
        diff = x > y ? x - y : y - x;
    }

}