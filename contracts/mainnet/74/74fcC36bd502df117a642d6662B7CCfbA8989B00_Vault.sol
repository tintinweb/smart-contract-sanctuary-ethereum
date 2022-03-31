// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./vault/VaultRestricted.sol";

/**
 * @notice Implementation of the {IVault} interface.
 *
 * @dev
 * All vault instances are meant to be deployed via the Controller
 * as a proxy and will not be recognizable by the Spool if they are
 * not done so.
 *
 * The vault contract is capable of supporting a single currency underlying
 * asset and deposit to multiple strategies at once, including dual-collateral
 * ones.
 *
 * The vault also supports the additional distribution of extra reward tokens as
 * an incentivization mechanism proportionate to each user's deposit amount within
 * the vhe vault.
 *
 * Vault implementation consists of following contracts:
 * 1. VaultImmutable: reads vault specific immutable variable from vault proxy contract
 * 2. VaultBase: holds vault state variables and provides some of the common vault functions
 * 3. RewardDrip: distributes vault incentivized rewards to users participating in the vault
 * 4. VaultIndexActions: implements functions to synchronize the vault with central Spool contract
 * 5. VaultRestricted: exposes functions restricted for other Spool specific contracts
 * 6. Vault: exposes unrestricted functons to interact with the core vault functionality (deposit/withdraw/claim)
 */
contract Vault is VaultRestricted {
    using SafeERC20 for IERC20;
    using Bitwise for uint256;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets the initial immutable values of the contract.
     *
     * @dev
     * All values have been sanitized by the controller contract, meaning
     * that no additional checks need to be applied here.
     *
     * @param _spool the spool implemenation
     * @param _controller the controller implemenation
     * @param _fastWithdraw fast withdraw implementation
     * @param _feeHandler fee handler implementation
     * @param _spoolOwner spool owner contract
     */
    constructor(
        ISpool _spool,
        IController _controller,
        IFastWithdraw _fastWithdraw,
        IFeeHandler _feeHandler,
        ISpoolOwner _spoolOwner
    )
        VaultBase(
            _spool,
            _controller,
            _fastWithdraw,
            _feeHandler
        )
        SpoolOwnable(_spoolOwner)
    {}

    /* ========== DEPOSIT ========== */

    /**
     * @notice Allows a user to perform a particular deposit to the vault.
     *
     * @dev
     * Emits a {Deposit} event indicating the amount newly deposited for index.
     *
     * Perform redeem if possible:
     * - Vault: Index has been completed (sync deposits/withdrawals)
     * - User: Claim deposit shares or withdrawn amount
     * 
     * Requirements:
     *
     * - the provided strategies must be valid
     * - the caller must have pre-approved the contract for the token amount deposited
     * - the caller cannot deposit zero value
     * - the system should not be paused
     *
     * @param vaultStrategies strategies of this vault (verified internally)
     * @param amount amount to deposit
     * @param transferFromVault if the transfer should occur from the funds transfer(controller) address
     */
    function deposit(address[] memory vaultStrategies, uint128 amount, bool transferFromVault)
        external
        verifyStrategies(vaultStrategies)
        hasStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        redeemUserModifier
        updateRewards
    {
        require(amount > 0, "NDP");

        // get next possible index to deposit
        uint24 activeGlobalIndex = _getActiveGlobalIndex();

        // Mark user deposited amount for active index
        vaultIndexAction[activeGlobalIndex].depositAmount += amount;
        userIndexAction[msg.sender][activeGlobalIndex].depositAmount += amount;

        // Mark vault strategies to deposit at index
        _distributeInStrats(vaultStrategies, amount, activeGlobalIndex);

        // mark that vault and user have interacted at this global index
        _updateInteractedIndex(activeGlobalIndex);
        _updateUserInteractedIndex(activeGlobalIndex);

        // transfer user deposit to Spool
        _transferDepositToSpool(amount, transferFromVault);

        // store user deposit amount
        _addInstantDeposit(amount);

        emit Deposit(msg.sender, activeGlobalIndex, amount);
    }

    /**
     * @notice Distributes a deposit to the various strategies based on the allocations of the vault.
     */
    function _distributeInStrats(
        address[] memory vaultStrategies,
        uint128 amount,
        uint256 activeGlobalIndex
    ) private {
        uint128 amountLeft = amount;
        uint256 lastElement = vaultStrategies.length - 1;
        uint256 _proportions = proportions;

        for (uint256 i; i < lastElement; i++) {
            uint128 proportionateAmount = _getStrategyDepositAmount(_proportions, i, amount);
            if (proportionateAmount > 0) {
                spool.deposit(vaultStrategies[i], proportionateAmount, activeGlobalIndex);
                amountLeft -= proportionateAmount;
            }
        }

        if (amountLeft > 0) {
            spool.deposit(vaultStrategies[lastElement], amountLeft, activeGlobalIndex);
        }
    }

    /* ========== WITHDRAW ========== */

    /**
     * @notice Allows a user to withdraw their deposited funds from the vault at next possible index.
     * The withdrawal is queued for when do hard work for index is completed.
     * 
     * @dev
     * Perform redeem if possible:
     * - Vault: Index has been completed (sync deposits/withdrawals)
     * - User: Claim deposit shares or withdrawn amount
     *
     * Emits a {Withdrawal} event indicating the shares burned, index of the withdraw and the amount of funds withdrawn.
     *
     * Requirements:
     *
     * - vault must not be reallocating
     * - the provided strategies must be valid
     * - the caller must have a non-zero amount of shares to withdraw
     * - the caller must have enough shares to withdraw the specified share amount
     * - the system should not be paused
     *
     * @param vaultStrategies strategies of this vault (verified internally)
     * @param sharesToWithdraw shares amount to withdraw
     * @param withdrawAll if all shares should be removed
     */
    function withdraw(
        address[] memory vaultStrategies,
        uint128 sharesToWithdraw,
        bool withdrawAll
    )
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        noReallocation
        redeemUserModifier
        updateRewards
    {
        sharesToWithdraw = _withdrawShares(sharesToWithdraw, withdrawAll);
        
        // get next possible index to withdraw
        uint24 activeGlobalIndex = _getActiveGlobalIndex();

        // mark user withdrawn shares amount for active index
        userIndexAction[msg.sender][activeGlobalIndex].withdrawShares += sharesToWithdraw;
        vaultIndexAction[activeGlobalIndex].withdrawShares += sharesToWithdraw;

        // mark strategies in the spool contract to be withdrawn at next possible index
        _withdrawFromStrats(vaultStrategies, sharesToWithdraw, activeGlobalIndex);

        // mark that vault and user interacted at this global index
        _updateInteractedIndex(activeGlobalIndex);
        _updateUserInteractedIndex(activeGlobalIndex);

        emit Withdraw(msg.sender, activeGlobalIndex, sharesToWithdraw);
    }

    /* ========== FAST WITHDRAW ========== */

    /**
     * @notice Allows a user to withdraw their deposited funds right away.
     *
     * @dev
     * @dev
     * User can execute the withdrawal of his shares from the vault at any time without
     * waiting for the DHW to process it. This is done independently of other events (e.g. DHW)
     * and the gas cost is paid entirely by the user.
     * Shares belonging to the user and are sent back to the FastWithdraw contract
     * where an actual withdrawal can be peformed, where user recieves the underlying tokens
     * right away.
     *
     * Requirements:
     *
     * - vault must not be reallocating
     * - the spool system must not be mid reallocation
     *   (started DHW and not finished, at index the reallocation was initiated)
     * - the provided strategies must be valid
     * - the sistem must not be in the middle of the reallocation
     * - the system should not be paused
     *
     * @param vaultStrategies strategies of this vault
     * @param sharesToWithdraw shares amount to withdraw
     * @param withdrawAll if all shares should be removed
     * @param fastWithdrawParams extra parameters to perform fast withdraw
     */
    function withdrawFast(
        address[] memory vaultStrategies,
        uint128 sharesToWithdraw,
        bool withdrawAll,
        FastWithdrawParams memory fastWithdrawParams
    )
        external
        noMidReallocation
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        noReallocation
        redeemUserModifier
        updateRewards
    {
        sharesToWithdraw = _withdrawShares(sharesToWithdraw, withdrawAll);

        uint256 vaultShareProportion = _getVaultShareProportion(sharesToWithdraw);
        totalShares -= sharesToWithdraw;

        uint128[] memory strategyRemovedShares = spool.removeShares(vaultStrategies, vaultShareProportion);

        uint256 proportionateDeposit = _getUserProportionateDeposit(sharesToWithdraw);

        // transfer removed shares to fast withdraw contract
        fastWithdraw.transferShares(
            vaultStrategies,
            strategyRemovedShares,
            proportionateDeposit,
            msg.sender,
            fastWithdrawParams
        );

        emit WithdrawFast(msg.sender, sharesToWithdraw);
    }

    /**
     * @dev Updates storage values according to shares withdrawn.
     *      If `withdrawAll` is true, all shares are removed from the users
     * @param sharesToWithdraw Amount of shares to withdraw
     * @param withdrawAll Withdraw all user shares
     */
    function _withdrawShares(uint128 sharesToWithdraw, bool withdrawAll) private returns(uint128) {
        User storage user = users[msg.sender];
        uint128 userShares = user.shares;

        uint128 userActiveInstantDeposit = user.instantDeposit;

        // Substract the not processed instant deposit
        // This way we don't consider the deposit that was not yet processed by the DHW
        // when calculating amount of it withdrawn
        LastIndexInteracted memory userIndexInteracted = userLastInteractions[msg.sender];
        if (userIndexInteracted.index1 > 0) {
            userActiveInstantDeposit -= userIndexAction[msg.sender][userIndexInteracted.index1].depositAmount;
            // also check if user second index has pending actions
            if (userIndexInteracted.index2 > 0) {
                userActiveInstantDeposit -= userIndexAction[msg.sender][userIndexInteracted.index2].depositAmount;
            }
        }
        
        // check if withdraw all flag was set or user requested
        // withdraw of all shares in `sharesToWithdraw`
        if (withdrawAll || userShares == sharesToWithdraw) {
            sharesToWithdraw = userShares;
            // set user shares to 0
            user.shares = 0;

            // substract all the users instant deposit processed till now
            // substract the same amount from vault total instand deposit value
            totalInstantDeposit -= userActiveInstantDeposit;
            user.instantDeposit -= userActiveInstantDeposit;
        } else {
            require(
                userShares >= sharesToWithdraw &&
                sharesToWithdraw > 0, 
                "WSH"
            );

            // if we didnt withdraw all calculate the proportion of
            // the instant deposit to substract it from the user and vault amounts
            uint128 instantDepositWithdrawn = _getProportion128(userActiveInstantDeposit, sharesToWithdraw, userShares);

            totalInstantDeposit -= instantDepositWithdrawn;
            user.instantDeposit -= instantDepositWithdrawn;

            // susrtact withdrawn shares from the user
            // NOTE: vault shares will be substracted when the at the redeem
            // for the current active index is processed. This way we substract it
            // only once for all the users.
            user.shares = userShares - sharesToWithdraw;
        }
        
        return sharesToWithdraw;
    }

    /**
     * @notice Calculates user proportionate deposit when withdrawing and updated user deposit storage
     * @dev Checks user index action to see if user already has some withdrawn shares
     *      pending to be processed.
     *      Called when performing the fast withdraw
     *
     * @param sharesToWithdraw shares amount to withdraw
     *
     * @return User deposit amount proportionate to the amount of shares being withdrawn
     */
    function _getUserProportionateDeposit(uint128 sharesToWithdraw) private returns(uint256) {
        User storage user = users[msg.sender];
        LastIndexInteracted memory userIndexInteracted = userLastInteractions[msg.sender];

        uint128 proportionateDeposit;
        uint128 sharesAtWithdrawal = user.shares + sharesToWithdraw;

        if (userIndexInteracted.index1 > 0) {
            sharesAtWithdrawal += userIndexAction[msg.sender][userIndexInteracted.index1].withdrawShares;

            if (userIndexInteracted.index2 > 0) {
                sharesAtWithdrawal += userIndexAction[msg.sender][userIndexInteracted.index2].withdrawShares;
            }
        }

        if (sharesAtWithdrawal > sharesToWithdraw) {
            uint128 userTotalDeposit = user.activeDeposit;
            proportionateDeposit = _getProportion128(userTotalDeposit, sharesToWithdraw, sharesAtWithdrawal);
            user.activeDeposit = userTotalDeposit - proportionateDeposit;
        } else {
            proportionateDeposit = user.activeDeposit;
            user.activeDeposit = 0;
        }

        return proportionateDeposit;
    }

    function _withdrawFromStrats(address[] memory vaultStrategies, uint128 totalSharesToWithdraw, uint256 activeGlobalIndex) private {
        uint256 vaultShareProportion = _getVaultShareProportion(totalSharesToWithdraw);
        for (uint256 i; i < vaultStrategies.length; i++) {
            spool.withdraw(vaultStrategies[i], vaultShareProportion, activeGlobalIndex);
        }
    }

    /* ========== CLAIM ========== */

    /**
     * @notice Allows a user to claim their debt from the vault after withdrawn shares were processed.
     *
     * @dev
     * Fee is taken from the profit
     * Perform redeem on user demand
     *
     * Emits a {DebtClaim} event indicating the debt the user claimed.
     *
     * Requirements:
     *
     * - if `doRedeemVault` is true, the provided strategies must be valid
     * - the caller must have a non-zero debt owed
     * - the system should not be paused (if doRedeemVault)
     *
     * @param doRedeemVault flag, to execute redeem for the vault (synchronize deposit/withdrawals with the system)
     * @param vaultStrategies vault stratigies
     * @param doRedeemUser flag, to execute redeem for the caller
     *
     * @return claimAmount amount of underlying asset, claimed by the caller
     */
    function claim(
        bool doRedeemVault,
        address[] memory vaultStrategies,
        bool doRedeemUser
    ) external returns (uint128 claimAmount) {
        User storage user = users[msg.sender];

        if (doRedeemVault) {
            _verifyStrategies(vaultStrategies);
            _redeemVaultStrategies(vaultStrategies);
        }

        if (doRedeemUser) {
            _redeemUser();
        }

        claimAmount = user.owed;
        require(claimAmount > 0, "CA0");

        user.owed = 0;

        // Calculate profit and take fees
        uint128 userWithdrawnDeposits = user.withdrawnDeposits;
        if (claimAmount > userWithdrawnDeposits) {
            user.withdrawnDeposits = 0;
            uint128 profit = claimAmount - userWithdrawnDeposits;

            uint128 feesPaid = _payFeesAndTransfer(profit);

            // Substract fees paid from claim amount
            claimAmount -= feesPaid;
        } else {
            user.withdrawnDeposits = userWithdrawnDeposits - claimAmount;
        }

        _underlying().safeTransfer(msg.sender, claimAmount);

        emit Claimed(msg.sender, claimAmount);
    }

    /* ========== REDEEM ========== */

    /**
     * @notice Redeem vault and user deposit and withdrawals
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault stratigies
     */
    function redeemVaultAndUser(address[] memory vaultStrategies)
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        redeemUserModifier
    {}

    /**
     * @notice Redeem vault and user and return the user state
     * @dev This function should be called as static and act as view
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault stratigies
     *
     * @return user state after reedeem
     */
    function getUpdatedUser(address[] memory vaultStrategies)
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        redeemUserModifier
        returns(uint256, uint256, uint256, uint256, uint256)
    {
        User memory user = users[msg.sender];

        uint256 totalUnderlying = 0;
        for (uint256 i; i < vaultStrategies.length; i++) {
            totalUnderlying += spool.getUnderlying(vaultStrategies[i]);
        }

        uint256 userTotalUnderlying;
        if (totalShares > 0 && user.shares > 0) {
            userTotalUnderlying = (totalUnderlying * user.shares) / totalShares;
        }

        return (
            user.shares,
            user.activeDeposit, // amount of user deposited underlying token
            user.owed, // underlying token claimable amount
            user.withdrawnDeposits, // underlying token withdrawn amount
            userTotalUnderlying
        );
    }

    /**
     * @notice Redeem vault strategy deposits and withdrawals after do hard work.
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault strategies
     */
    function redeemVaultStrategies(address[] memory vaultStrategies)
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
    {}

    /**
     * @notice Redeem vault strategy deposits and withdrawals after do hard work.
     *
     * Requirements:
     *
     * - the provided strategies must be valid
     *
     * @param vaultStrategies vault strategies
     * @return totalUnderlying total vault underlying
     * @return totalShares underlying and shares after redeem
     */
    function getUpdatedVault(address[] memory vaultStrategies)
        external
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        returns(uint256, uint256)
    {
        uint256 totalUnderlying = 0;
        for (uint256 i; i < vaultStrategies.length; i++) {
            totalUnderlying += spool.getUnderlying(vaultStrategies[i]);
        }
        return (totalUnderlying, totalShares);
    }

    /**
     * @notice Redeem user deposits and withdrawals
     *
     * @dev Can only redeem user up to last index vault has redeemed
     */
    function redeemUser()
        external
    {
        _redeemUser();
    }

    /* ========== STRATEGY REMOVED ========== */

    /**
     * @notice Notify a vault a strategy was removed from the Spool system
     * @dev
     * This can be called by anyone after a strategy has been removed from the system.
     * After the removal of the strategy that the vault contains, all actions
     * calling central Spool contract will revert. This function must be called,
     * to remove the strategy from the vault and update the strategy hash according
     * to the new strategy array.
     *
     * Requirements:
     *
     * - The Spool system must finish reallocation if it's in progress
     * - the provided strategies must be valid
     * - The strategy must belong to this vault
     * - The strategy must be removed from the system
     *
     * @param vaultStrategies Array of current vault strategies (including the removed one)
     * @param i Index of the removed strategy in the `vaultStrategies`
     */
    function notifyStrategyRemoved(
        address[] memory vaultStrategies,
        uint256 i
    )
        external
        reallocationFinished
        verifyStrategies(vaultStrategies)
        hasStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
    {
        require(
            i < vaultStrategies.length &&
            !controller.validStrategy(vaultStrategies[i]),
            "BSTR"
        );

        uint256 lastElement = vaultStrategies.length - 1;

        address[] memory newStrategies = new address[](lastElement);

        if (lastElement > 0) {
            for (uint256 j; j < lastElement; j++) {
                newStrategies[j] = vaultStrategies[j];
            }

            if (i < lastElement) {
                newStrategies[i] = vaultStrategies[lastElement];
            }

            uint256 _proportions = proportions;
            uint256 proportionsLeft = FULL_PERCENT - _proportions.get14BitUintByIndex(i);
            if (lastElement > 1 && proportionsLeft > 0) {
                if (i == lastElement) {
                    _proportions = _proportions.reset14BitUintByIndex(i);
                } else {
                    uint256 lastProportion = _proportions.get14BitUintByIndex(lastElement);
                    _proportions = _proportions.reset14BitUintByIndex(i);
                    _proportions = _proportions.set14BitUintByIndex(i, lastProportion);
                }

                uint256 newProportions = _proportions;

                uint256 lastNewElement = lastElement - 1;
                uint256 newProportionsLeft = FULL_PERCENT;
                for (uint256 j; j < lastNewElement; j++) {
                    uint256 propJ = _proportions.get14BitUintByIndex(j);
                    propJ = (propJ * FULL_PERCENT) / proportionsLeft;
                    newProportions = newProportions.set14BitUintByIndex(j, propJ);
                    newProportionsLeft -= propJ;
                }

                newProportions = newProportions.set14BitUintByIndex(lastNewElement, newProportionsLeft);

                proportions = newProportions;
            } else {
                proportions = FULL_PERCENT;
            }
        } else {
            proportions = 0;
        }

        _updateStrategiesHash(newStrategies);
        emit StrategyRemoved(i, vaultStrategies[i]);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Throws if given array of strategies is empty
     */
    function _hasStrategies(address[] memory vaultStrategies) private pure {
        require(vaultStrategies.length > 0, "NST");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if given array of strategies is empty
     */
    modifier hasStrategies(address[] memory vaultStrategies) {
        _hasStrategies(vaultStrategies);
        _;
    }

    /**
     * @notice Revert if reallocation is not finished for this vault
     */
    modifier reallocationFinished() {
        require(
            !_isVaultReallocating() ||
            reallocationIndex <= spool.getCompletedGlobalIndex(),
            "RNF"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 128 bits");
        return uint192(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IController {
    /* ========== FUNCTIONS ========== */

    function strategies(uint256 i) external view returns (address);

    function validStrategy(address strategy) external view returns (bool);

    function validVault(address vault) external view returns (bool);

    function getStrategiesCount() external view returns(uint8);

    function supportedUnderlying(IERC20 underlying)
        external
        view
        returns (bool);

    function getAllStrategies() external view returns (address[] memory);

    function verifyStrategies(address[] calldata _strategies) external view;

    function transferToSpool(
        address transferFrom,
        uint256 amount
    ) external;

    function checkPaused() external view;

    /* ========== EVENTS ========== */

    event EmergencyWithdrawStrategy(address indexed strategy);
    event EmergencyRecipientUpdated(address indexed recipient);
    event EmergencyWithdrawerUpdated(address indexed withdrawer, bool set);
    event PauserUpdated(address indexed user, bool set);
    event UnpauserUpdated(address indexed user, bool set);
    event VaultCreated(address indexed vault, address underlying, address[] strategies, uint256[] proportions,
        uint16 vaultFee, address riskProvider, int8 riskTolerance);
    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);
    event VaultInvalid(address vault);
    event DisableStrategy(address strategy);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./ISwapData.sol";

struct FastWithdrawParams {
    bool doExecuteWithdraw;
    uint256[][] slippages;
    SwapData[][] swapData;
}

interface IFastWithdraw {
    function transferShares(
        address[] calldata vaultStrategies,
        uint128[] calldata sharesWithdrawn,
        uint256 proportionateDeposit,
        address user,
        FastWithdrawParams calldata fastWithdrawParams
    ) external;

        /* ========== EVENTS ========== */

    event StrategyWithdrawn(address indexed user, address indexed vault, address indexed strategy);
    event UserSharesSaved(address indexed user, address indexed vault);
    event FastWithdrawExecuted(address indexed user, address indexed vault, uint256 totalWithdrawn);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IFeeHandler {
    function payFees(
        IERC20 underlying,
        uint256 profit,
        address riskProvider,
        address vaultOwner,
        uint16 vaultFee
    ) external returns (uint256 feesPaid);

    function setRiskProviderFee(address riskProvider, uint16 fee) external;

    /* ========== EVENTS ========== */

    event FeesPaid(address indexed vault, uint profit, uint ecosystemCollected, uint treasuryCollected, uint riskProviderColected, uint vaultFeeCollected);
    event RiskProviderFeeUpdated(address indexed riskProvider, uint indexed fee);
    event EcosystemFeeUpdated(uint indexed fee);
    event TreasuryFeeUpdated(uint indexed fee);
    event EcosystemCollectorUpdated(address indexed collector);
    event TreasuryCollectorUpdated(address indexed collector);
    event FeeCollected(address indexed collector, IERC20 indexed underlying, uint amount);
    event EcosystemFeeCollected(IERC20 indexed underlying, uint amount);
    event TreasuryFeeCollected(IERC20 indexed underlying, uint amount);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./spool/ISpoolExternal.sol";
import "./spool/ISpoolReallocation.sol";
import "./spool/ISpoolDoHardWork.sol";
import "./spool/ISpoolStrategy.sol";
import "./spool/ISpoolBase.sol";

/// @notice Utility Interface for central Spool implementation
interface ISpool is ISpoolExternal, ISpoolReallocation, ISpoolDoHardWork, ISpoolStrategy, ISpoolBase {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

/**
 * @notice Strict holding information how to swap the asset
 * @member slippage minumum output amount
 * @member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolBase {
    /* ========== FUNCTIONS ========== */

    function getCompletedGlobalIndex() external view returns(uint24);

    function getActiveGlobalIndex() external view returns(uint24);

    function isMidReallocation() external view returns (bool);

    /* ========== EVENTS ========== */

    event ReallocationTableUpdated(
        uint24 indexed index,
        bytes32 reallocationTableHash
    );

    event ReallocationTableUpdatedWithTable(
        uint24 indexed index,
        bytes32 reallocationTableHash,
        uint256[][] reallocationTable
    );
    
    event DoHardWorkCompleted(uint24 indexed index);

    event SetAllocationProvider(address actor, bool isAllocationProvider);
    event SetIsDoHardWorker(address actor, bool isDoHardWorker);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolDoHardWork {
    /* ========== EVENTS ========== */

    event DoHardWorkStrategyCompleted(address indexed strat, uint256 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../ISwapData.sol";

interface ISpoolExternal {
    /* ========== FUNCTIONS ========== */

    function deposit(address strategy, uint128 amount, uint256 index) external;

    function withdraw(address strategy, uint256 vaultProportion, uint256 index) external;

    function fastWithdrawStrat(address strat, address underlying, uint256 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external returns(uint128);

    function redeem(address strat, uint256 index) external returns (uint128, uint128);

    function redeemUnderlying(uint128 amount) external;

    function redeemReallocation(address[] calldata vaultStrategies, uint256 depositProportions, uint256 index) external;

    function removeShares(address[] calldata vaultStrategies, uint256 vaultProportion) external returns(uint128[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolReallocation {
    event StartReallocation(uint24 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolStrategy {
    /* ========== FUNCTIONS ========== */

    function getUnderlying(address strat) external returns (uint128);
    
    function getVaultTotalUnderlyingAtIndex(address strat, uint256 index) external view returns(uint128);

    function addStrategy(address strat) external;

    function disableStrategy(address strategy, bool skipDisable) external;

    function runDisableStrategy(address strategy) external;

    function emergencyWithdraw(
        address strat,
        address withdrawRecipient,
        uint256[] calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRewardDrip {
    /* ========== STRUCTS ========== */

    // The reward configuration struct, containing all the necessary data of a typical Synthetix StakingReward contract
    struct RewardConfiguration {
        uint32 rewardsDuration;
        uint32 periodFinish;
        uint192 rewardRate; // rewards per second multiplied by accuracy
        uint32 lastUpdateTime;
        uint224 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    /* ========== FUNCTIONS ========== */

    function getActiveRewards(address account) external;
    function tokenBlacklist(IERC20 token) view external returns(bool);

    /* ========== EVENTS ========== */
    
    event RewardPaid(IERC20 token, address indexed user, uint256 reward);
    event RewardAdded(IERC20 indexed token, uint256 amount, uint256 duration);
    event RewardExtended(IERC20 indexed token, uint256 amount, uint256 leftover, uint256 duration, uint32 periodFinish);
    event RewardRemoved(IERC20 indexed token);
    event PeriodFinishUpdated(IERC20 indexed token, uint32 periodFinish);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./IVaultDetails.sol";

interface IVaultBase {
    /* ========== FUNCTIONS ========== */

    function initialize(VaultInitializable calldata vaultInitializable) external;

    /* ========== STRUCTS ========== */

    struct User {
        uint128 instantDeposit; // used for calculating rewards
        uint128 activeDeposit; // users deposit after deposit process and claim
        uint128 owed; // users owed underlying amount after withdraw has been processed and claimed
        uint128 withdrawnDeposits; // users withdrawn deposit, used to calculate performance fees
        uint128 shares; // users shares after deposit process and claim
    }

    /* ========== EVENTS ========== */

    event Claimed(address indexed member, uint256 claimAmount);
    event Deposit(address indexed member, uint256 indexed index, uint256 amount);
    event Withdraw(address indexed member, uint256 indexed index, uint256 shares);
    event WithdrawFast(address indexed member, uint256 shares);
    event StrategyRemoved(uint256 i, address strategy);
    event TransferVaultOwner(address owner);
    event LowerVaultFee(uint16 fee);
    event UpdateName(string name);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

struct VaultDetails {
    address underlying;
    address[] strategies;
    uint256[] proportions;
    address creator;
    uint16 vaultFee;
    address riskProvider;
    int8 riskTolerance;
    string name;
}

struct VaultInitializable {
    string name;
    address owner;
    uint16 fee;
    address[] strategies;
    uint256[] proportions;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

struct VaultImmutables {
    IERC20 underlying;
    address riskProvider;
    int8 riskTolerance;
}

interface IVaultImmutable {
    /* ========== FUNCTIONS ========== */

    function underlying() external view returns (IERC20);

    function riskProvider() external view returns (address);

    function riskTolerance() external view returns (int8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultIndexActions {

    /* ========== STRUCTS ========== */

    struct IndexAction {
        uint128 depositAmount;
        uint128 withdrawShares;
    }

    struct LastIndexInteracted {
        uint128 index1;
        uint128 index2;
    }

    struct Redeem {
        uint128 depositShares;
        uint128 withdrawnAmount;
    }

    /* ========== EVENTS ========== */

    event VaultRedeem(uint indexed globalIndex);
    event UserRedeem(address indexed member, uint indexed globalIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultRestricted {
    /* ========== FUNCTIONS ========== */
    
    function reallocate(
        address[] calldata vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) external returns (uint256[] memory, uint256);

    function payFees(uint256 profit) external returns (uint256 feesPaid);

    /* ========== EVENTS ========== */

    event Reallocate(uint24 indexed index, uint256 newProportions);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

library Bitwise {
    function get8BitUintByIndex(uint256 bitwiseData, uint256 i) internal pure returns(uint256) {
        return (bitwiseData >> (8 * i)) & type(uint8).max;
    }

    // 14 bits is used for strategy proportions in a vault as FULL_PERCENT is 10_000
    function get14BitUintByIndex(uint256 bitwiseData, uint256 i) internal pure returns(uint256) {
        return (bitwiseData >> (14 * i)) & (16_383); // 16.383 is 2^14 - 1
    }

    function set14BitUintByIndex(uint256 bitwiseData, uint256 i, uint256 num14bit) internal pure returns(uint256) {
        return bitwiseData + (num14bit << (14 * i));
    }

    function reset14BitUintByIndex(uint256 bitwiseData, uint256 i) internal pure returns(uint256) {
        return bitwiseData & (~(16_383 << (14 * i)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @notice Library to provide utils for hashing and hash compatison of Spool related data
 */
library Hash {
    function hashReallocationTable(uint256[][] memory reallocationTable) internal pure returns(bytes32) {
        return keccak256(abi.encode(reallocationTable));
    }

    function hashStrategies(address[] memory strategies) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(strategies));
    }

    function sameStrategies(address[] memory strategies1, address[] memory strategies2) internal pure returns(bool) {
        return hashStrategies(strategies1) == hashStrategies(strategies2);
    }

    function sameStrategies(address[] memory strategies, bytes32 strategiesHash) internal pure returns(bool) {
        return hashStrategies(strategies) == strategiesHash;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../external/@openzeppelin/utils/SafeCast.sol";


/**
 * @notice A collection of custom math ustils used throughout the system
 */
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function getProportion128(uint256 mul1, uint256 mul2, uint256 div) internal pure returns (uint128) {
        return SafeCast.toUint128(((mul1 * mul2) / div));
    }

    function getProportion128Unchecked(uint256 mul1, uint256 mul2, uint256 div) internal pure returns (uint128) {
        unchecked {
            return uint128((mul1 * mul2) / div);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

/// @title Common Spool contracts constants
abstract contract BaseConstants {
    /// @dev 2 digits precision
    uint256 internal constant FULL_PERCENT = 100_00;

    /// @dev Accuracy when doing shares arithmetics
    uint256 internal constant ACCURACY = 10**30;
}

/// @title Contains USDC token related values
abstract contract USDC {
    /// @notice USDC token contract address
    IERC20 internal constant USDC_ADDRESS = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/ISpoolOwner.sol";

/// @title Logic to help check whether the caller is the Spool owner
abstract contract SpoolOwnable {
    /// @notice Contract that checks if address is Spool owner
    ISpoolOwner internal immutable spoolOwner;

    /**
     * @notice Sets correct initial values
     * @param _spoolOwner Spool owner contract address
     */
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    /**
     * @notice Checks if caller is Spool owner
     * @return True if caller is Spool owner, false otherwise
     */
    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }


    /// @notice Checks and throws if caller is not Spool owner
    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    /// @notice Checks and throws if caller is not Spool owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../interfaces/IController.sol";

/// @title Facilitates checking if the system is paused or not
abstract contract SpoolPausable {
    /* ========== STATE VARIABLES ========== */

    /// @notice The controller contract that is consulted for a strategy's and vault's validity
    IController public immutable controller;

    /**
     * @notice Sets initial values
     * @param _controller Controller contract address
     */
    constructor(IController _controller) {
        require(
            address(_controller) != address(0),
            "SpoolPausable::constructor: Controller contract address cannot be 0"
        );

        controller = _controller;
    }

    /* ========== MODIFIERS ========== */

    /// @notice Throws if system is paused
    modifier systemNotPaused() {
        controller.checkPaused();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IRewardDrip.sol";
import "./VaultBase.sol";

import "../external/@openzeppelin/utils/SafeCast.sol";
import "../external/@openzeppelin/security/ReentrancyGuard.sol";
import "../libraries/Math.sol";

/**
 * @notice Implementation of the {IRewardDrip} interface.
 *
 * @dev
 * An adaptation of the Synthetix StakingRewards contract to support multiple tokens:
 *
 * https://github.com/Synthetixio/synthetix/blob/develop/contracts/StakingRewards.sol
 *
 * Instead of storing the values of the StakingRewards contract at the contract level,
 * they are stored in a struct that is mapped to depending on the reward token instead.
 */
abstract contract RewardDrip is IRewardDrip, ReentrancyGuard, VaultBase {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    /// @notice Multiplier used when dealing reward calculations
    uint256 constant private REWARD_ACCURACY = 1e18;

    /* ========== STATE VARIABLES ========== */

    /// @notice All reward tokens supported by the contract
    mapping(uint256 => IERC20) public rewardTokens;

    /// @notice Vault reward token incentive configuration
    mapping(IERC20 => RewardConfiguration) public rewardConfiguration;

    /// @notice Blacklisted force-removed tokens
    mapping(IERC20 => bool) public override tokenBlacklist;

    /* ========== VIEWS ========== */

    function lastTimeRewardApplicable(IERC20 token)
        public
        view
        returns (uint32)
    {
        return uint32(Math.min(block.timestamp, rewardConfiguration[token].periodFinish));
    }

    function rewardPerToken(IERC20 token) public view returns (uint224) {
        RewardConfiguration storage config = rewardConfiguration[token];

        if (totalInstantDeposit == 0)
            return config.rewardPerTokenStored;
            
        uint256 timeDelta = lastTimeRewardApplicable(token) - config.lastUpdateTime;

        if (timeDelta == 0)
            return config.rewardPerTokenStored;

        return
            SafeCast.toUint224(
                config.rewardPerTokenStored + 
                    ((timeDelta
                        * config.rewardRate)
                        / totalInstantDeposit)
            );
    }

    function earned(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        RewardConfiguration storage config = rewardConfiguration[token];

        uint256 userShares = users[account].instantDeposit;

        if (userShares == 0)
            return config.rewards[account];
        
        uint256 userRewardPerTokenPaid = config.userRewardPerTokenPaid[account];

        return
            ((userShares * 
                (rewardPerToken(token) - userRewardPerTokenPaid))
                / REWARD_ACCURACY)
                + config.rewards[account];
    }

    function getRewardForDuration(IERC20 token)
        external
        view
        returns (uint256)
    {
        RewardConfiguration storage config = rewardConfiguration[token];
        return uint256(config.rewardRate) * config.rewardsDuration;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function getRewards(IERC20[] memory tokens) external nonReentrant {
        for (uint256 i; i < tokens.length; i++) {
            _getReward(tokens[i], msg.sender);
        }
    }

    function getActiveRewards(address account) external override onlyController nonReentrant {
        uint256 _rewardTokensCount = rewardTokensCount;
        for (uint256 i; i < _rewardTokensCount; i++) {
            _getReward(rewardTokens[i], account);
        }
    }

    function _getReward(IERC20 token, address account)
        internal
        updateReward(token, account)
    {
        RewardConfiguration storage config = rewardConfiguration[token];

        require(
            config.rewardsDuration != 0,
            "BTK"
        );

        uint256 reward = config.rewards[account];
        if (reward > 0) {
            config.rewards[account] = 0;
            token.safeTransfer(account, reward);
            emit RewardPaid(token, account, reward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Allows a new token to be added to the reward system
     *
     * @dev
     * Emits an {TokenAdded} event indicating the newly added reward token
     * and configuration
     *
     * Requirements:
     *
     * - the caller must be the reward distributor
     * - the reward duration must be non-zero
     * - the token must not have already been added
     *
     */
    function addToken(
        IERC20 token,
        uint32 rewardsDuration,
        uint256 reward
    ) external onlyVaultOwnerOrSpoolOwner exceptUnderlying(token) {
        RewardConfiguration storage config = rewardConfiguration[token];

        require(!tokenBlacklist[token], "TOBL");
        require(
            rewardsDuration != 0 &&
            config.lastUpdateTime == 0,
            "BCFG"
        );
        require(
            rewardTokensCount <= 5,
            "TMAX"
        );

        rewardTokens[rewardTokensCount] = token;
        rewardTokensCount++;

        config.rewardsDuration = rewardsDuration;

        if (reward > 0) {
            _notifyRewardAmount(token, reward);
        }
    }

    function notifyRewardAmount(IERC20 token, uint256 reward, uint32 rewardsDuration)
    external
    onlyVaultOwnerOrSpoolOwner
    {
        rewardConfiguration[token].rewardsDuration = rewardsDuration;
        _notifyRewardAmount(token, reward);
    }

    function _notifyRewardAmount(IERC20 token, uint256 reward)
        private
        updateReward(token, address(0))
    {
        RewardConfiguration storage config = rewardConfiguration[token];

        require(
            config.rewardPerTokenStored + (reward * REWARD_ACCURACY) <= type(uint192).max,
            "RTB"
        );

        token.safeTransferFrom(msg.sender, address(this), reward);
        uint32 newPeriodFinish = uint32(block.timestamp) + config.rewardsDuration;

        if (block.timestamp >= config.periodFinish) {
            config.rewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY) / config.rewardsDuration);
            emit RewardAdded(token, reward, config.rewardsDuration);
        } else {
            // If extending or adding additional rewards,
            // cannot set new finish time to be less than previously configured
            require(config.periodFinish <= newPeriodFinish, "PFS");
            uint256 remaining = config.periodFinish - block.timestamp;
            uint256 leftover = remaining * config.rewardRate;
            uint192 newRewardRate = SafeCast.toUint192((reward * REWARD_ACCURACY + leftover) / config.rewardsDuration);
        
            require(
                newRewardRate >= config.rewardRate,
                "LRR"
            );

            config.rewardRate = newRewardRate;
            emit RewardExtended(token, reward, leftover, config.rewardsDuration, newPeriodFinish);
        }

        config.lastUpdateTime = uint32(block.timestamp);
        config.periodFinish = newPeriodFinish;
    }

    // End rewards emission earlier
    function updatePeriodFinish(IERC20 token, uint32 timestamp)
        external
        onlyOwner
        updateReward(token, address(0))
    {
        if (rewardConfiguration[token].lastUpdateTime > timestamp) {
            rewardConfiguration[token].periodFinish = rewardConfiguration[token].lastUpdateTime;
        } else {
            rewardConfiguration[token].periodFinish = timestamp;
        }

        emit PeriodFinishUpdated(token, rewardConfiguration[token].periodFinish);
    }

    /**
     * @notice Claim reward tokens
     * @dev
     * This is meant to be an emergency function to claim reward tokens.
     * Users that have not claimed yet will not be able to claim as
     * the rewards will be removed.
     *
     * Requirements:
     *
     * - the caller must be Spool DAO
     * - cannot claim vault underlying token
     * - cannot only execute if the reward finished
     *
     * @param token Token address to remove
     * @param amount Amount of tokens to claim
     */
    function claimFinishedRewards(IERC20 token, uint256 amount) external onlyOwner exceptUnderlying(token) onlyFinished(token) {
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Force remove reward from vault rewards configuration.
     * @dev This is meant to be an emergency function if a reward token breaks.
     *
     * Requirements:
     *
     * - the caller must be Spool DAO
     *
     * @param token Token address to remove
     */
    function forceRemoveReward(IERC20 token) external onlyOwner {
        tokenBlacklist[token] = true;
        _removeReward(token);

        delete rewardConfiguration[token];
    }

    /**
     * @notice Remove reward from vault rewards configuration.
     * @dev
     * Used to sanitize vault and save on gas, after the reward has ended.
     * Users will be able to claim rewards 
     *
     * Requirements:
     *
     * - the caller must be the spool owner or Spool DAO
     * - cannot claim vault underlying token
     * - cannot only execute if the reward finished
     *
     * @param token Token address to remove
     */
    function removeReward(IERC20 token) 
        external
        onlyVaultOwnerOrSpoolOwner
        onlyFinished(token)
        updateReward(token, address(0))
    {
        _removeReward(token);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Syncs rewards across all tokens of the system
     *
     * This function is meant to be invoked every time the instant deposit
     * of a user changes.
     */
    function _updateRewards(address account) private {
        uint256 _rewardTokensCount = rewardTokensCount;
        
        for (uint256 i; i < _rewardTokensCount; i++)
            _updateReward(rewardTokens[i], account);
    }

    function _updateReward(IERC20 token, address account) private {
        RewardConfiguration storage config = rewardConfiguration[token];
        config.rewardPerTokenStored = rewardPerToken(token);
        config.lastUpdateTime = lastTimeRewardApplicable(token);
        if (account != address(0)) {
            config.rewards[account] = earned(token, account);
            config.userRewardPerTokenPaid[account] = config
                .rewardPerTokenStored;
        }
    }

    function _removeReward(IERC20 token) private {
        uint256 _rewardTokensCount = rewardTokensCount;
        for (uint256 i; i < _rewardTokensCount; i++) {
            if (rewardTokens[i] == token) {
                rewardTokens[i] = rewardTokens[_rewardTokensCount - 1];

                delete rewardTokens[_rewardTokensCount - 1];
                rewardTokensCount--;
                emit RewardRemoved(token);

                break;
            }
        }
    }

    function _exceptUnderlying(IERC20 token) private view {
        require(
            token != _underlying(),
            "NUT"
        );
    }

    function _onlyFinished(IERC20 token) private view {
        require(
            block.timestamp > rewardConfiguration[token].periodFinish,
            "RNF"
        );
    }

    /**
    * @notice Ensures that the caller is the controller
     */
    function _onlyController() private view {
        require(
            msg.sender == address(controller),
            "OCTRL"
        );
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(IERC20 token, address account) {
        _updateReward(token, account);
        _;
    }

    modifier updateRewards() {
        _updateRewards(msg.sender);
        _;
    }

    modifier exceptUnderlying(IERC20 token) {
        _exceptUnderlying(token);
        _;
    }

    modifier onlyFinished(IERC20 token) {
        _onlyFinished(token);
        _;
    }

    /**
     * @notice Throws if called by anyone else other than the controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// libraries
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../external/@openzeppelin/utils/SafeCast.sol";
import "../libraries/Bitwise.sol";
import "../libraries/Hash.sol";

// extends
import "../interfaces/vault/IVaultBase.sol";
import "./VaultImmutable.sol";
import "../shared/SpoolOwnable.sol";
import "../shared/Constants.sol";

// other imports
import "../interfaces/vault/IVaultDetails.sol";
import "../interfaces/ISpool.sol";
import "../interfaces/IController.sol";
import "../interfaces/IFastWithdraw.sol";
import "../interfaces/IFeeHandler.sol";
import "../shared/SpoolPausable.sol";

/**
 * @notice Implementation of the {IVaultBase} interface.
 *
 * @dev
 * Vault base holds vault state variables and provides some of the common vault functions.
 */
abstract contract VaultBase is IVaultBase, VaultImmutable, SpoolOwnable, SpoolPausable, BaseConstants {
    using Bitwise for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice The central Spool contract
    ISpool internal immutable spool;

    /// @notice The fast withdraw contract
    IFastWithdraw internal immutable fastWithdraw;

    /// @notice The fee handler contract
    IFeeHandler internal immutable feeHandler;

    /// @notice Boolean signaling if the contract was initialized yet
    bool private _initialized;

    /// @notice The owner of the vault, also the vault fee recipient
    address public vaultOwner;

    /// @notice Vault owner fee
    uint16 public vaultFee;

    /// @notice The name of the vault
    string public name;

    /// @notice The total shares of a vault
    uint128 public totalShares;

    /// @notice Total instant deposit, used to calculate vault reward incentives
    uint128 public totalInstantDeposit;

    /// @notice The proportions of each strategy when depositing
    /// @dev Proportions are 14bits each, and the add up to FULL_PERCENT (10.000)
    uint256 public proportions;

    /// @notice Proportions to deposit after reallocation withdraw amount is claimed
    uint256 internal depositProportions;
    
    /// @notice Hash of the strategies list
    bytes32 public strategiesHash;

    /// @notice Number of vault incentivized tokens
    uint8 public rewardTokensCount;
    
    /// @notice Data if vault and at what index vault is reallocating
    uint24 public reallocationIndex;

    /// @notice User vault state values
    mapping(address => User) public users;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets the initial immutable values of the contract common for all vaults.
     *
     * @dev
     * All values have been sanitized by the controller contract, meaning
     * that no additional checks need to be applied here.
     *
     * @param _spool the spool implemenation
     * @param _controller the controller implementation
     * @param _fastWithdraw fast withdraw implementation
     * @param _feeHandler fee handler implementation
     */
    constructor(
        ISpool _spool,
        IController _controller,
        IFastWithdraw _fastWithdraw,
        IFeeHandler _feeHandler
    )
    SpoolPausable(_controller)
    {
        require(address(_spool) != address(0), "VaultBase::constructor: Spool address cannot be 0");
        require(address(_fastWithdraw) != address(0), "VaultBase::constructor: FastWithdraw address cannot be 0");
        require(address(_feeHandler) != address(0), "VaultBase::constructor: Fee Handler address cannot be 0");

        spool = _spool;
        fastWithdraw = _fastWithdraw;
        feeHandler = _feeHandler;
    }

    /* ========== INITIALIZE ========== */

    /**
     * @notice Initializes state of the vault at proxy creation.
     * @dev Called only once by vault factory after deploying a vault proxy.
     *      All values have been sanitized by the controller contract, meaning
     *      that no additional checks need to be applied here.
     *
     * @param vaultInitializable initial vault specific variables
     */
    function initialize(
        VaultInitializable memory vaultInitializable
    ) external override initializer {
        vaultOwner = vaultInitializable.owner;
        vaultFee = vaultInitializable.fee;
        name = vaultInitializable.name;

        proportions = _mapProportionsArrayToBits(vaultInitializable.proportions);
        _updateStrategiesHash(vaultInitializable.strategies);
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Calculate and return proportion of passed parameters of 128 bit size
     * @dev Calculates the value using in 256 bit space, later casts back to 128 bit
     * Requirements:
     * 
     * - the result can't be bigger than maximum 128 bits value
     *
     * @param mul1 first multiplication value
     * @param mul2 second multiplication value
     * @param div result division value
     *
     * @return 128 bit proportion result
     */
    function _getProportion128(uint128 mul1, uint128 mul2, uint128 div) internal pure returns (uint128) {
        return SafeCast.toUint128((uint256(mul1) * mul2) / div);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Transfer vault owner to another address.
     *
     * @param _vaultOwner new vault owner address
     *
     * Requirements:
     *
     * - the caller can only be the vault owner or Spool DAO
     */
    function transferVaultOwner(address _vaultOwner) external onlyVaultOwnerOrSpoolOwner {
        vaultOwner = _vaultOwner;
        emit TransferVaultOwner(_vaultOwner);
    }

    /**
     * @notice Set lower vault fee.
     *
     * @param _vaultFee new vault fee
     *
     * Requirements:
     *
     * - the caller can only be the vault owner
     * - new vault fee must be lower than before
     */
    function lowerVaultFee(uint16 _vaultFee) external {
        require(
            msg.sender == vaultOwner &&
            _vaultFee < vaultFee,
            "FEE"
        );

        vaultFee = _vaultFee;
        emit LowerVaultFee(_vaultFee);
    }

    /**
     * @notice Update the name of the vault.
     *
     * @param _name new vault name
     *
     * Requirements:
     *
     * - the caller can only be the Spool DAO
     */
    function updateName(string memory _name) external onlyOwner {
        name = _name;
        emit UpdateName(_name);
    }

    // =========== DEPOSIT HELPERS ============ //

    /**
     * @notice Update instant deposit user and vault amounts
     *
     * @param amount deposited amount
     */
    function _addInstantDeposit(uint128 amount) internal {
        users[msg.sender].instantDeposit += amount;
        totalInstantDeposit += amount;
    }

    /**
     * @notice Get strategy deposit amount for the strategy
     * @param _proportions Vault strategy proportions (14bit each)
     * @param i index to get the proportion
     * @param amount Total deposit amount
     * @return strategyDepositAmount 
     */
    function _getStrategyDepositAmount(
        uint256 _proportions,
        uint256 i,
        uint256 amount
    ) internal pure returns (uint128) {
        return SafeCast.toUint128((_proportions.get14BitUintByIndex(i) * amount) / FULL_PERCENT);
    }

    /**
     * @notice Transfers deposited underlying asset amount from user to spool contract.
     * @dev Transfer happens from the vault or controller, defined by the user
     *
     * @param amount deposited amount
     * @param fromVault flag indicating wether the transfer is intiafed from the vault or controller
     */
    function _transferDepositToSpool(uint128 amount, bool fromVault) internal {
        if (fromVault) {
            _underlying().safeTransferFrom(msg.sender, address(spool), amount);
        } else {
            controller.transferToSpool(msg.sender, amount);
        }
    }

    /* ========== WITHDRAW HELPERS ========== */

    /**
     * @notice Calculates proportions of shares relative to the total shares
     * @dev Value has accuracy of `ACCURACY` which is 10^30
     *
     * @param sharesToWithdraw amount of shares
     *
     * @return total vault shares proportion
     */
    function _getVaultShareProportion(uint128 sharesToWithdraw) internal view returns(uint256) {
        return (ACCURACY * sharesToWithdraw) / totalShares;
    }

    // =========== PERFORMANCE FEES ============ //

    /**
     * @notice Pay fees to fee handler contract and transfer fee amount.
     * 
     * @param profit Total profit made by the users
     * @return feeSize Fee amount calculated from profit
     */
    function _payFeesAndTransfer(uint256 profit) internal returns (uint128 feeSize) {
        feeSize = SafeCast.toUint128(_payFees(profit));

        _underlying().safeTransfer(address(feeHandler), feeSize);
    }

    /**
     * @notice  Call fee handler contract to pay fees, without transfering assets
     * @dev Fee handler updates the fee storage slots and returns 
     *
     * @param profit Total profit made by the users
     * @return Fee amount calculated from profit
     */
    function _payFees(uint256 profit) internal returns (uint256) {
        return feeHandler.payFees(
            _underlying(),
            profit,
            _riskProvider(),
            vaultOwner,
            vaultFee
        );
    }

    // =========== STRATEGIIES ============ //

    /**
     * @notice Map vault strategy proportions array in one uint256 word.
     *
     * @dev Proportions sum up to `FULL_PERCENT` (10_000).
     *      There is maximum of 18 elements, and each takes maximum of 14bits.
     *
     * @param _proportions Vault strategy proportions array
     * @return Mapped propportion 256 bit word format
     */
    function _mapProportionsArrayToBits(uint256[] memory _proportions) internal pure returns (uint256) {
        uint256 proportions14bit;
        for (uint256 i = 0; i < _proportions.length; i++) {
            proportions14bit = proportions14bit.set14BitUintByIndex(i, _proportions[i]);
        }

        return proportions14bit;
    }

    /**
     * @dev Store vault strategy addresses array hash in `strategiesHash` storage
     * @param vaultStrategies Array of strategy addresses
     */
    function _updateStrategiesHash(address[] memory vaultStrategies) internal {
        strategiesHash = Hash.hashStrategies(vaultStrategies);
    }

    /**
     * @dev verify vault strategy addresses array against storage `strategiesHash`
     * @param vaultStrategies Array of strategies to verify
     */
    function _verifyStrategies(address[] memory vaultStrategies) internal view {
        require(Hash.sameStrategies(vaultStrategies, strategiesHash), "VSH");
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Verify the caller is The vault owner or Spool DAO
     *
     * @dev
     * Only callable from onlyVaultOwnerOrSpoolOwner modifier.
     *
     * Requirements:
     *
     * - msg.sender is the vault owner or Spool DAO
     */
    function _onlyVaultOwnerOrSpoolOwner() private view {
        require(
            msg.sender == vaultOwner || isSpoolOwner(),
            "OOD"
        );
    }

    /**
     * @notice Verify the caller is the spool contact
     *
     * @dev
     * Only callable from onlySpool modifier.
     *
     * Requirements:
     *
     * - msg.sender is central spool contract
     */
    function _onlySpool() private view {
        require(address(spool) == msg.sender, "OSP");
    }

    /**
     * @notice Verify caller is the spool contact
     *
     * @dev
     * Only callable from onlyFastWithdraw modifier.
     *
     * Requirements:
     *
     * - caller is fast withdraw contract
     */
    function _onlyFastWithdraw() private view {
        require(address(fastWithdraw) == msg.sender, "OFW");
    }

    /**
     * @notice Dissallow action if Spool reallocation already started
     */
    function _noMidReallocation() private view {
        require(!spool.isMidReallocation(), "NMR");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Ensures caller is vault owner or spool owner.
     */
    modifier onlyVaultOwnerOrSpoolOwner() {
        _onlyVaultOwnerOrSpoolOwner();
        _;
    }

    /**
     * @notice Ensures caller is central spool contract
     */
    modifier onlySpool() {
        _onlySpool();
        _;
    }

    /**
     * @notice Ensures caller is fast withdraw contract
     */
    modifier onlyFastWithdraw() {
        _onlyFastWithdraw();
        _;
    }

    /**
     * @notice Verifies given array of strategy addresses
     */
    modifier verifyStrategies(address[] memory vaultStrategies) {
        _verifyStrategies(vaultStrategies);
        _;
    }

    /**
     * @notice Ensures the system is not mid reallocation
     */
    modifier noMidReallocation() {
        _noMidReallocation();
        _;
    }

    /**
     * @notice Ensures the vault has not been initialized before
     */
    modifier initializer() {
        require(!_initialized, "AINT");
        _;
        _initialized = true;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IVaultImmutable.sol";

/**
 * @notice This contracts calls vault proxy that stores following
 *      properties as immutables. 
 */
abstract contract VaultImmutable {
    /* ========== FUNCTIONS ========== */

    /**
     * @dev Returns the underlying vault token from proxy address
     * @return Underlying token contract
     */
    function _underlying() internal view returns (IERC20) {
        return IVaultImmutable(address(this)).underlying();
    }

    /**
     * @dev Returns vaults risk provider from proxy address
     * @return Risk provider contract
     */
    function _riskProvider() internal view returns (address) {
        return IVaultImmutable(address(this)).riskProvider();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IVaultIndexActions.sol";
import "./RewardDrip.sol";

/**
 * @notice VaultIndexActions extends VaultBase and holds the logic to process index related data and actions.
 *
 * @dev
 * Index functions are executed when state changes are performed, to synchronize to vault with central Spool contract.
 * 
 * Index actions include:
 * - Redeem vault: claiming vault shares and withdrawn amount when DHW is complete
 * - Redeem user: claiming user deposit shares and/or withdrawn amount after vault claim has been processed
 */
abstract contract VaultIndexActions is IVaultIndexActions, RewardDrip {
    using SafeERC20 for IERC20;
    using Bitwise for uint256;

    /* ========== CONSTANTS ========== */

    /// @notice minimum shares size to avoid loss of share due to computation precision
    uint128 private constant MIN_SHARES = 10**8;

    /* ========== STATE VARIABLES ========== */

    /// @notice Holds up to 2 global indexes vault last interacted at and havent been redeemed yet
    /// @dev Second index can only be the next index of the first one
    /// Second index is used if the do-hard-work is executed in 2 transactions and actions are executed in between
    LastIndexInteracted public lastIndexInteracted;

    /// @notice Maps all vault actions to the corresponding global index
    mapping(uint256 => IndexAction) public vaultIndexAction;
    
    /// @notice Maps user actions to the corresponding global index
    mapping(address => mapping(uint256 => IndexAction)) public userIndexAction;

    /// @notice Holds up to 2 global indexes users last interacted with, and havent been redeemed yet
    mapping(address => LastIndexInteracted) public userLastInteractions;

    /// @notice Global index to deposit and withdraw vault redeem
    mapping(uint256 => Redeem) public redeems;

    // =========== VIEW FUNCTIONS ============ //

    /**
     * @notice Checks and sets the "is reallocating" flag for given index
     * @param index Index to check
     * @return isReallocating True if vault is reallocating at this `index`
     */
    function _isVaultReallocatingAtIndex(uint256 index) internal view returns (bool isReallocating) {
        if (index == reallocationIndex) {
            isReallocating = true;
        }
    }

    /**
     * @notice Check if the vault is set to reallocate
     * @dev True if in the current index or the next one
     * @return isReallocating True if vault is set to reallocate
     */
    function _isVaultReallocating() internal view returns (bool isReallocating) {
        if (reallocationIndex > 0) {
            isReallocating = true;
        }
    }

    // =========== VAULT REDEEM ============ //

    /**
     * @notice Redeem vault strategies after do hard work (DHW) has been completed
     * 
     * @dev
     * This is only possible if all vault strategy DHWs have been executed, otherwise it's reverted.
     * If the system is paused, function will revert - impacts vault functions deposit, withdraw, fastWithdraw,
     * claim, reallocate.
     * @param vaultStrategies strategies of this vault (verified internally)
     */
    function _redeemVaultStrategies(address[] memory vaultStrategies) internal systemNotPaused {
        LastIndexInteracted memory _lastIndexInteracted = lastIndexInteracted;
        if (_lastIndexInteracted.index1 > 0) {
            uint256 globalIndex1 = _lastIndexInteracted.index1;
            uint256 completedGlobalIndex = spool.getCompletedGlobalIndex();
            if (globalIndex1 <= completedGlobalIndex) {
                // redeem interacted index 1
                _redeemStrategiesIndex(globalIndex1, vaultStrategies);
                _lastIndexInteracted.index1 = 0;

                if (_lastIndexInteracted.index2 > 0) {
                    uint256 globalIndex2 = _lastIndexInteracted.index2;
                    if (globalIndex2 <= completedGlobalIndex) {
                        // redeem interacted index 2
                        _redeemStrategiesIndex(globalIndex2, vaultStrategies);
                    } else {
                        _lastIndexInteracted.index1 = _lastIndexInteracted.index2;
                    }
                    
                    _lastIndexInteracted.index2 = 0;
                }

                lastIndexInteracted = _lastIndexInteracted;
            }
        }
    }

    /**
     * @notice Redeem strategies for at index
     * @dev Causes additional gas for first interaction after DHW index has been completed
     * @param globalIndex Global index
     * @param vaultStrategies Array of vault strategy addresses
     */
    function _redeemStrategiesIndex(uint256 globalIndex, address[] memory vaultStrategies) private {
        uint128 _totalShares = totalShares;
        uint128 totalReceived = 0;
        uint128 totalWithdrawn = 0;
        uint128 totalUnderlyingAtIndex = 0;
        
        // if vault was reallocating at index claim reallocation deposit
        bool isReallocating = _isVaultReallocatingAtIndex(globalIndex);
        if (isReallocating) {
            spool.redeemReallocation(vaultStrategies, depositProportions, globalIndex);
            // Reset reallocation index to 0
            reallocationIndex = 0;
        }

        // go over strategies and redeem deposited shares and withdrawn amount
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            address strat = vaultStrategies[i];
            (uint128 receivedTokens, uint128 withdrawnTokens) = spool.redeem(strat, globalIndex);
            totalReceived += receivedTokens;
            totalWithdrawn += withdrawnTokens;
            
            totalUnderlyingAtIndex += spool.getVaultTotalUnderlyingAtIndex(strat, globalIndex);
        }

        // redeem underlying withdrawn token for all strategies at once
        if (totalWithdrawn > 0) {
            spool.redeemUnderlying(totalWithdrawn);
        }

        // substract withdrawn shares
        _totalShares -= vaultIndexAction[globalIndex].withdrawShares;

        // calculate new deposit shares
        uint128 newShares = 0;
        if (_totalShares == 0 || totalUnderlyingAtIndex == 0) {
            // Enforce minimum shares size to avoid loss of share due to computation precision
            newShares = (0 < totalReceived && totalReceived < MIN_SHARES) ? MIN_SHARES : totalReceived;
        } else {
            newShares = _getProportion128(totalReceived, _totalShares, totalUnderlyingAtIndex);
        }

        // add new deposit shares
        totalShares = _totalShares + newShares;

        redeems[globalIndex] = Redeem(newShares, totalWithdrawn);

        emit VaultRedeem(globalIndex);
    }

    // =========== USER REDEEM ============ //

    /**
     * @notice Redeem user deposit shares and withdrawn amount
     *
     * @dev
     * Check if vault has already claimed shares for itself
     */
    function _redeemUser() internal {
        LastIndexInteracted memory _lastIndexInteracted = lastIndexInteracted;
        LastIndexInteracted memory userIndexInteracted = userLastInteractions[msg.sender];

        // check if strategy for index has already been redeemed
        if (userIndexInteracted.index1 > 0 && 
            (_lastIndexInteracted.index1 == 0 || userIndexInteracted.index1 < _lastIndexInteracted.index1)) {
            // redeem interacted index 1
            _redeemUserAction(userIndexInteracted.index1, true);
            userIndexInteracted.index1 = 0;

            if (userIndexInteracted.index2 > 0) {
                if (_lastIndexInteracted.index2 == 0 || userIndexInteracted.index2 < _lastIndexInteracted.index1) {
                    // redeem interacted index 2
                    _redeemUserAction(userIndexInteracted.index2, false);
                } else {
                    userIndexInteracted.index1 = userIndexInteracted.index2;
                }
                
                userIndexInteracted.index2 = 0;
            }

            userLastInteractions[msg.sender] = userIndexInteracted;
        }
    }

    /**
     * @notice Redeem user action for the `index`
     * @param index index aw which user performed the action
     * @param isFirstIndex Is this the first user index
     */
    function _redeemUserAction(uint256 index, bool isFirstIndex) private {
        User storage user = users[msg.sender];
        IndexAction storage userIndex = userIndexAction[msg.sender][index];

        // redeem user withdrawn amount at index
        uint128 userWithdrawalShares = userIndex.withdrawShares;
        if (userWithdrawalShares > 0) {
            // calculate user withdrawn amount

            uint128 userWithdrawnAmount = _getProportion128(redeems[index].withdrawnAmount, userWithdrawalShares, vaultIndexAction[index].withdrawShares);

            user.owed += userWithdrawnAmount;

            // calculate proportionate deposit to pay for performance fees on claim
            uint128 proportionateDeposit;
            uint128 sharesAtWithdrawal = user.shares + userWithdrawalShares;
            if (isFirstIndex) {
                // if user has 2 withdraws pending sum shares from the pending one as well
                sharesAtWithdrawal += userIndexAction[msg.sender][index + 1].withdrawShares;
            }

            // check if withdrawal of all user shares was performes (all shares at the index of the action)
            if (sharesAtWithdrawal > userWithdrawalShares) {
                uint128 userTotalDeposit = user.activeDeposit;
                
                proportionateDeposit = _getProportion128(userTotalDeposit, userWithdrawalShares, sharesAtWithdrawal);
                user.activeDeposit = userTotalDeposit - proportionateDeposit;
            } else {
                proportionateDeposit = user.activeDeposit;
                user.activeDeposit = 0;
            }

            user.withdrawnDeposits += proportionateDeposit;

            // set user withdraw shares for index to 0
            userIndex.withdrawShares = 0;
        }

        // redeem user deposit shares at index
        uint128 userDepositAmount = userIndex.depositAmount;
        if (userDepositAmount > 0) {
            // calculate new user deposit shares
            uint128 newUserShares = _getProportion128(userDepositAmount, redeems[index].depositShares, vaultIndexAction[index].depositAmount);

            user.shares += newUserShares;
            user.activeDeposit += userDepositAmount;

            // set user deposit amount for index to 0
            userIndex.depositAmount = 0;
        }
        
        emit UserRedeem(msg.sender, index);
    }

    // =========== INDEX FUNCTIONS ============ //

    /**
     * @dev Saves vault last interacted global index
     * @param globalIndex Global index
     */
    function _updateInteractedIndex(uint24 globalIndex) internal {
        _updateLastIndexInteracted(lastIndexInteracted, globalIndex);
    }

    /**
     * @dev Saves last user interacted global index
     * @param globalIndex Global index
     */
    function _updateUserInteractedIndex(uint24 globalIndex) internal {
        _updateLastIndexInteracted(userLastInteractions[msg.sender], globalIndex);
    }

    /**
     * @dev Update last index with which the system interacted
     * @param lit Last interacted idex of a user or a vault
     * @param globalIndex Global index
     */
    function _updateLastIndexInteracted(LastIndexInteracted storage lit, uint24 globalIndex) private {
        if (lit.index1 > 0) {
            if (lit.index1 < globalIndex) {
                lit.index2 = globalIndex;
            }
        } else {
            lit.index1 = globalIndex;
        }

    }

    /**
     * @dev Gets current active global index from spool
     */
    function _getActiveGlobalIndex() internal view returns(uint24) {
        return spool.getActiveGlobalIndex();
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Ensures the vault is not currently reallocating
     */
    function _noReallocation() private view {
        require(!_isVaultReallocating(), "NRED");
    }

    /* ========== MODIFIERS ========== */

    /**
    * @dev Redeem given array of vault strategies
     */
    modifier redeemVaultStrategiesModifier(address[] memory vaultStrategies) {
        _redeemVaultStrategies(vaultStrategies);
        _;
    }

    /**
    * @dev Redeem user
     */
    modifier redeemUserModifier() {
        _redeemUser();
        _;
    }

    /**
     * @dev Ensures the vault is not currently reallocating
     */
    modifier noReallocation() {
        _noReallocation();
        _;
    }  
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/vault/IVaultRestricted.sol";
import "./VaultIndexActions.sol";

/**
 * @notice Implementation of the {IVaultRestricted} interface.
 *
 * @dev
 * VaultRestricted extends VaultIndexActions and exposes functions restricted for Spool specific contracts.
 * 
 * Index functions are executed when state changes are performed, to synchronize to vault with central Spool contract
 * 
 * Functions:
 * - payFees, called by fast withdraw, when user decides to fast withdraw its shares
 * - reallocate, called by spool, sets new strategy allocation values and calculates what
 *   strategies to withdraw from and deposit to, to achieve the desired allocation
 */
abstract contract VaultRestricted is IVaultRestricted, VaultIndexActions {
    using Bitwise for uint256;

    // =========== FAST WITHDRAW FEES ============ //

    /**
     * @notice  Notifies fee handler of user realized profits to calculate and store the fee.
     * @dev
     * Called by fast withdraw contract.
     * Fee handler updates the fee storage slots and returns calculated fee value
     * Fast withdraw transfers the calculated fee to the fee handler after.
     *
     * Requirements:
     *
     * - Caller must be the fast withdraw contract
     *
     * @param profit Total profit made by the user
     * @return Fee amount calculated from the profit
     */
    function payFees(uint256 profit) external override onlyFastWithdraw returns (uint256) {
        return _payFees(profit);
    }

    /* ========== SPOOL REALLOCATE ========== */

    /**
     * @notice Update vault strategy proportions and reallocate funds according to the new proportions.
     *
     * @dev 
     * Requirements:
     * 
     * - the caller must be the Spool contract
     * - reallocation must not be in progress
     * - new vault proportions must add up to `FULL_PERCENT`
     *
     * @param vaultStrategies Vault strategy addresses
     * @param newVaultProportions New vault proportions
     * @param finishedIndex Completed global index
     * @param activeIndex current active global index, that we're setting reallocate for
     *
     * @return withdrawProportionsArray array of shares to be withdrawn from each vault strategy, and be later deposited back to other vault strategies
     * @return newDepositProportions proportions to be deposited to strategies from all withdrawn funds (written in a uint word, 14bits each) values add up to `FULL_PERCENT`
     *
     */
    function reallocate(
        address[] memory vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) 
        external 
        override
        onlySpool
        verifyStrategies(vaultStrategies)
        redeemVaultStrategiesModifier(vaultStrategies)
        noReallocation
        returns(uint256[] memory withdrawProportionsArray, uint256 newDepositProportions)
    {
        (withdrawProportionsArray, newDepositProportions) = _adjustAllocation(vaultStrategies, newVaultProportions, finishedIndex);

        proportions = newVaultProportions;

        reallocationIndex = activeIndex;
        _updateInteractedIndex(activeIndex);
        emit Reallocate(reallocationIndex, newVaultProportions);
    }

    /**
     * @notice Set new vault strategy allocation and calculate how the funds should be spread
     * 
     * @dev
     * Requirements:
     *
     * - new proportions must add up to 100% (`FULL_PERCENT`)
     * - vault must withdraw from at least one strategy
     * - vault must deposit to at least one strategy
     * - vault total underlying must be more than zero
     *
     * @param vaultStrategies Vault strategy addresses
     * @param newVaultProportions New vault proportions
     * @param finishedIndex Completed global index
     *
     * @return withdrawProportionsArray array of shares to be withdrawn from each vault strategy, and be later deposited back to other vault strategies
     * @return newDepositProportions proportions to be deposited to strategies from all withdrawn funds (written in a uint word, 14bits each) values add up to `FULL_PERCENT`
     */
    function _adjustAllocation(
        address[] memory vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex
    )
        private returns(uint256[] memory, uint256)
    {
        uint256[] memory depositProportionsArray = new uint256[](vaultStrategies.length);
        uint256[] memory withdrawProportionsArray = new uint256[](vaultStrategies.length);

        (uint256[] memory stratUnderlyings, uint256 vaultTotalUnderlying) = _getStratsAndVaultUnderlying(vaultStrategies, finishedIndex);

        require(vaultTotalUnderlying > 0, "NUL");

        uint256 totalProportion;
        uint256 totalDepositProportion;
        uint256 lastDepositIndex;

        {
            // flags to check if reallocation will withdraw and reposit
            bool didWithdraw = false;
            bool willDeposit = false;
            for (uint256 i; i < vaultStrategies.length; i++) {
                uint256 newStratProportion = Bitwise.get14BitUintByIndex(newVaultProportions, i);
                totalProportion += newStratProportion;

                uint256 stratProportion;
                if (stratUnderlyings[i] > 0) {
                    stratProportion = (stratUnderlyings[i] * FULL_PERCENT) / vaultTotalUnderlying;
                }

                // if current proportion is more than new - withdraw
                if (stratProportion > newStratProportion) {
                    uint256 withdrawalProportion = stratProportion - newStratProportion;
                    if (withdrawalProportion < 10) // NOTE: skip if diff is less than 0.1%
                        continue;

                    uint256 withdrawalShareProportion = (withdrawalProportion * ACCURACY) / stratProportion;
                    withdrawProportionsArray[i] = withdrawalShareProportion;

                    didWithdraw = true;
                } else if (stratProportion < newStratProportion) {
                    // if less - prepare for deposit
                    uint256 depositProportion = newStratProportion - stratProportion;
                    if (depositProportion < 10) // NOTE: skip if diff is less than 0.1%
                        continue;

                    depositProportionsArray[i] = depositProportion;
                    totalDepositProportion += depositProportion;
                    lastDepositIndex = i;

                    willDeposit = true;
                }
            }

            // check if sum of new propotions equals to full percent
            require(
                totalProportion == FULL_PERCENT,
                "BPP"
            );

            // Check if withdraw happened and if deposit will, otherwise revert
            require(didWithdraw && willDeposit, "NRD");
        }

        // normalize deposit proportions to FULL_PERCENT
        uint256 newDepositProportions;
        uint256 totalDepositProp;
        for (uint256 i; i <= lastDepositIndex; i++) {
            if (depositProportionsArray[i] > 0) {
                uint256 proportion = (depositProportionsArray[i] * FULL_PERCENT) / totalDepositProportion;

                newDepositProportions = newDepositProportions.set14BitUintByIndex(i, proportion);
                
                totalDepositProp += proportion;
            }
        }
        
        newDepositProportions = newDepositProportions.set14BitUintByIndex(lastDepositIndex, FULL_PERCENT - totalDepositProp);

        // store reallocation deposit proportions
        depositProportions = newDepositProportions;

        return (withdrawProportionsArray, newDepositProportions);
    }

    /**
     * @notice Get strategies and vault underlying
     * @param vaultStrategies Array of vault strategy addresses
     * @param index Get the underlying amounts at index
     */
    function _getStratsAndVaultUnderlying(address[] memory vaultStrategies, uint256 index)
        private
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory stratUnderlyings = new uint256[](vaultStrategies.length);

        uint256 vaultTotalUnderlying;
        for (uint256 i; i < vaultStrategies.length; i++) {
            uint256 stratUnderlying = spool.getVaultTotalUnderlyingAtIndex(vaultStrategies[i], index);

            stratUnderlyings[i] = stratUnderlying;
            vaultTotalUnderlying += stratUnderlying;
        }

        return (stratUnderlyings, vaultTotalUnderlying);
    }
}