// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./external/council/libraries/History.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/ARCDVestingVaultStorage.sol";
import "./libraries/HashedStorageReentrancyBlock.sol";

import "./interfaces/IARCDVestingVault.sol";
import "./BaseVotingVault.sol";

import {
    AVV_InvalidSchedule,
    AVV_InvalidCliffAmount,
    AVV_InsufficientBalance,
    AVV_HasGrant,
    AVV_NoGrantSet,
    AVV_CliffNotReached,
    AVV_AlreadyDelegated,
    AVV_InvalidAmount,
    AVV_ZeroAddress
} from "./errors/Governance.sol";

/**
 * @title ARCDVestingVault
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is a vesting vault for the Arcade token. It allows for the creation of grants
 * which can be vested over time. The vault has a manager who can add and remove grants.
 * The vault also has a timelock which can change the manager.
 *
 * When a grant is created by a manager, the manager specifies the delegatee. This is the address
 * that will receive the voting power of the grant. The delegatee can be updated by the grant
 * recipient at any time. When a grant is created, there are three time parameters:
 *      created - The block number the grant starts at. If not specified, the current block is used.
 *      cliff - The block number the cliff ends at. No tokens are unlocked until this block is reached.
 *              The cliffAmount parameter is the amount of tokens that will be unlocked at the cliff.
 *      expiration - The block number the grant ends at. All tokens are unlocked at this block.
 *
 * @dev There is no emergency withdrawal, any funds not sent via deposit() are unrecoverable
 *      by this version of the VestingVault. When grants are added the contracts will not transfer
 *      in tokens on each add but rather check for solvency via state variables.
 */
contract ARCDVestingVault is IARCDVestingVault, HashedStorageReentrancyBlock, BaseVotingVault {
    using History for History.HistoricalBalances;
    using ARCDVestingVaultStorage for ARCDVestingVaultStorage.Grant;
    using Storage for Storage.Address;
    using Storage for Storage.Uint256;

    // ========================================= CONSTRUCTOR ============================================

    /**
     * @notice Deploys a new vesting vault, setting relevant immutable variables
     *         and granting management power to a defined address.
     *
     * @param _token              The ERC20 token to grant.
     * @param _stale              Stale block used for voting power calculations
     * @param manager_            The address of the manager.
     * @param timelock_           The address of the timelock.
     */
    constructor(IERC20 _token, uint256 _stale, address manager_, address timelock_) BaseVotingVault(_token, _stale) {
        if (manager_ == address(0)) revert AVV_ZeroAddress();
        if (timelock_ == address(0)) revert AVV_ZeroAddress();

        Storage.set(Storage.addressPtr("manager"), manager_);
        Storage.set(Storage.addressPtr("timelock"), timelock_);
        Storage.set(Storage.uint256Ptr("entered"), 1);
    }

    // ==================================== MANAGER FUNCTIONALITY =======================================

    /**
     * @notice Adds a new grant. The manager sets who the voting power will be delegated to initially.
     *         This potentially avoids the need for a delegation transaction by the grant recipient.
     *
     * @param who                        The Grant recipient.
     * @param amount                     The total grant value.
     * @param cliffAmount                The amount of tokens that will be unlocked at the cliff.
     * @param startTime                  Optionally set a start time in the future. If set to zero
     *                                   then the start time will be made the block tx is in.
     * @param expiration                 Timestamp when the grant ends (all tokens count as unlocked).
     * @param cliff                      Timestamp when the cliff ends. No tokens are unlocked until
     *                                   this timestamp is reached.
     * @param delegatee                  The address to delegate the voting power to
     */
    function addGrantAndDelegate(
        address who,
        uint128 amount,
        uint128 cliffAmount,
        uint128 startTime,
        uint128 expiration,
        uint128 cliff,
        address delegatee
    ) external onlyManager {
        // if no custom start time is needed we use this block.
        if (startTime == 0) {
            startTime = uint128(block.number);
        }
        // grant schedule check
        if (cliff >= expiration || startTime >= expiration || cliff < startTime) revert AVV_InvalidSchedule();

        // cliff check
        if (cliffAmount >= amount) revert AVV_InvalidCliffAmount();

        Storage.Uint256 storage unassigned = _unassigned();
        if (unassigned.data < amount) revert AVV_InsufficientBalance(unassigned.data);

        // load the grant
        ARCDVestingVaultStorage.Grant storage grant = _grants()[who];

        // if this address already has a grant, a different address must be provided
        // topping up or editing active grants is not supported.
        if (grant.allocation != 0) revert AVV_HasGrant();

        // load the delegate. Defaults to the grant owner
        delegatee = delegatee == address(0) ? who : delegatee;

        // calculate the voting power. Assumes all voting power is initially locked.
        uint128 newVotingPower = amount;

        // set the new grant
        _grants()[who] = ARCDVestingVaultStorage.Grant(
            amount,
            cliffAmount,
            0,
            startTime,
            expiration,
            cliff,
            newVotingPower,
            delegatee
        );

        // update the amount of unassigned tokens
        unassigned.data -= amount;

        // update the delegatee's voting power
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);
        votingPower.push(grant.delegatee, delegateeVotes + newVotingPower);

        emit VoteChange(grant.delegatee, who, int256(uint256(newVotingPower)));
    }

    /**
     * @notice Removes a grant. Any available vested tokens will be sent to the grant recipient.
     *         Any remaining unvested tokens will be sent to the vesting manager.
     *
     * @param who             The grant owner.
     */
    function revokeGrant(address who) external virtual onlyManager {
        // load the grant
        ARCDVestingVaultStorage.Grant storage grant = _grants()[who];

        // if the grant has already been removed or no grant available, revert
        if (grant.allocation == 0) revert AVV_NoGrantSet();

        // get the amount of withdrawable tokens
        uint256 withdrawable = _getWithdrawableAmount(grant);
        grant.withdrawn += uint128(withdrawable);
        token.transfer(who, withdrawable);

        // transfer the remaining tokens to the vesting manager
        uint256 remaining = grant.allocation - grant.withdrawn;
        grant.withdrawn += uint128(remaining);
        token.transfer(_manager().data, remaining);

        // update the delegatee's voting power
        _syncVotingPower(who, grant);

        // Emit the vote change event
        emit VoteChange(grant.delegatee, who, -1 * int256(uint256(grant.latestVotingPower)));

        // delete the grant
        delete _grants()[who];
    }

    /**
     * @notice Manager-only token deposit function.  Deposited tokens are added to `_unassigned`
     *         and can be used to create grants.
     *
     * @dev This is the only way to deposit tokens into the contract. Any tokens sent via other
     *      means are not recoverable by this contract.
     *
     * @param amount           The amount of tokens to deposit.
     */
    function deposit(uint256 amount) external onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        // update unassigned value
        unassigned.data += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice Manager-only token withdrawal function. The manager can only withdraw tokens that
     *         are not being used by a grant.
     *
     * @param amount           The amount to withdraw.
     * @param recipient        The address to withdraw to.
     */
    function withdraw(uint256 amount, address recipient) external override onlyManager {
        Storage.Uint256 storage unassigned = _unassigned();
        if (unassigned.data < amount) revert AVV_InsufficientBalance(unassigned.data);
        // update unassigned value
        unassigned.data -= amount;

        token.transfer(recipient, amount);
    }

    // ========================================= USER OPERATIONS ========================================

    /**
     * @notice Grant owners use to claim any withdrawable value from a grant. Voting power
     *         is recalculated factoring in the amount withdrawn.
     *
     * @param amount                 The amount to withdraw.
     */
    function claim(uint256 amount) external override nonReentrant {
        if (amount == 0) revert AVV_InvalidAmount();

        // load the grant
        ARCDVestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        if (grant.allocation == 0) revert AVV_NoGrantSet();
        if (grant.cliff > block.number) revert AVV_CliffNotReached(grant.cliff);

        // get the withdrawable amount
        uint256 withdrawable = _getWithdrawableAmount(grant);
        if (amount > withdrawable) revert AVV_InsufficientBalance(withdrawable);

        // update the grant's withdrawn amount
        if (amount == withdrawable) {
            grant.withdrawn += uint128(withdrawable);
        } else {
            grant.withdrawn += uint128(amount);
            withdrawable = amount;
        }

        // update the user's voting power
        _syncVotingPower(msg.sender, grant);

        // transfer the available amount
        token.transfer(msg.sender, withdrawable);
    }

    /**
     * @notice Updates the caller's voting power delegatee.
     *
     * @param to              The address to delegate to.
     */
    function delegate(address to) external {
        ARCDVestingVaultStorage.Grant storage grant = _grants()[msg.sender];
        if (to == grant.delegatee) revert AVV_AlreadyDelegated();

        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 oldDelegateeVotes = votingPower.loadTop(grant.delegatee);
        uint256 newVotingPower = _currentVotingPower(grant);

        // Remove old delegatee's voting power and emit event
        votingPower.push(grant.delegatee, oldDelegateeVotes - grant.latestVotingPower);
        emit VoteChange(grant.delegatee, msg.sender, -1 * int256(uint256(grant.latestVotingPower)));

        // Note - It is important that this is loaded here and not before the previous state change because if
        // to == grant.delegatee and re-delegation was allowed we could be working with out of date state.
        uint256 newDelegateeVotes = votingPower.loadTop(to);

        // add voting power to the target delegatee and emit event
        votingPower.push(to, newDelegateeVotes + newVotingPower);

        // update grant info
        grant.latestVotingPower = uint128(newVotingPower);
        grant.delegatee = to;

        emit VoteChange(to, msg.sender, int256(newVotingPower));
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns the claimable amount for a given grant.
     *
     * @param who                    Address to query.
     *
     * @return Token amount that can be claimed.
     */
    function claimable(address who) external view returns (uint256) {
        return _getWithdrawableAmount(_grants()[who]);
    }

    /**
     * @notice Getter function for the grants mapping.
     *
     * @param who            The owner of the grant to query
     *
     * @return               The user's grant object.
     */
    function getGrant(address who) external view returns (ARCDVestingVaultStorage.Grant memory) {
        return _grants()[who];
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice Calculates and returns how many tokens a grant owner can withdraw.
     *
     * @param grant                    The memory location of the loaded grant.
     *
     * @return amount                  Number of tokens the grant owner can withdraw.
     */
    function _getWithdrawableAmount(ARCDVestingVaultStorage.Grant memory grant) internal view returns (uint256) {
        // if before cliff or created date, no tokens have unlocked
        if (block.number < grant.cliff) {
            return 0;
        }
        // if after expiration, return the full allocation minus what has already been withdrawn
        if (block.number >= grant.expiration) {
            return (grant.allocation - grant.withdrawn);
        }
        // if after cliff, return vested amount minus what has already been withdrawn
        if (block.number >= grant.cliff) {
            uint256 postCliffAmount = grant.allocation - grant.cliffAmount;
            uint256 blocksElapsedSinceCliff = block.number - grant.cliff;
            uint256 totalBlocksPostCliff = grant.expiration - grant.cliff;
            uint256 unlocked = grant.cliffAmount + (postCliffAmount * blocksElapsedSinceCliff) / totalBlocksPostCliff;

            return unlocked - grant.withdrawn;
        } else {
            return 0;
        }
    }

    /**
     * @notice Helper that returns the current voting power of a grant.
     *
     * @param grant                     The grant to check for voting power.
     *
     * @return votingPower              The current voting power of the grant.
     */
    function _currentVotingPower(ARCDVestingVaultStorage.Grant memory grant) internal pure returns (uint256) {
        return (grant.allocation - grant.withdrawn);
    }

    /**
     * @notice Helper to update a delegatee's voting power.
     *
     * @param who                       The address who's voting power we need to sync.
     * @param grant                     The storage pointer to the grant of that user.
     */
    function _syncVotingPower(address who, ARCDVestingVaultStorage.Grant storage grant) internal {
        History.HistoricalBalances memory votingPower = _votingPower();

        uint256 delegateeVotes = votingPower.loadTop(grant.delegatee);

        uint256 newVotingPower = _currentVotingPower(grant);
        // get the change in voting power. Negative if the voting power is reduced
        int256 change = int256(newVotingPower) - int256(uint256(grant.latestVotingPower));
        // voting power can only go down since only called when tokens are claimed or grant revoked
        if (change < 0) {
            // if the change is negative, we multiply by -1 to avoid underflow when casting
            votingPower.push(grant.delegatee, delegateeVotes - uint256(change * -1));
            emit VoteChange(grant.delegatee, who, change);

            grant.latestVotingPower = uint128(newVotingPower);
        }
    }

    /**
     * @notice A single function endpoint for loading grant storage. Returns a
     *         storage mapping which can be used to look up grant data.
     *
     * @dev Only one Grant is allowed per address. Grants SHOULD NOT
     *      be modified.
     *
     * @return grants                   Pointer to the grant storage mapping.
     */
    function _grants() internal pure returns (mapping(address => ARCDVestingVaultStorage.Grant) storage) {
        // This call returns a storage mapping with a unique non overwrite-able storage location
        // which can be persisted through upgrades, even if they change storage layout
        return (ARCDVestingVaultStorage.mappingAddressToGrantPtr("grants"));
    }

    /**
     * @notice A function to access the storage of the unassigned token value.
     *         The unassigned tokens are not part of any grant and can be used for a future
     *         grant or withdrawn by the manager.
     *
     * @return unassigned               Pointer to the unassigned token value.
     */
    function _unassigned() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("unassigned");
    }
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

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./external/council/libraries/History.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/HashedStorageReentrancyBlock.sol";

import "./interfaces/IBaseVotingVault.sol";

import { BVV_NotManager, BVV_NotTimelock, BVV_ZeroAddress } from "./errors/Governance.sol";

/**
 * @title BaseVotingVault
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is a base voting vault contract for use with Arcade voting vaults.
 * It includes basic voting vault functions like querying vote power, setting
 * the timelock and manager addresses, and getting the contracts token balance.
 */
abstract contract BaseVotingVault is HashedStorageReentrancyBlock, IBaseVotingVault {
    // ======================================== STATE ==================================================

    // Bring libraries into scope
    using History for History.HistoricalBalances;

    // ============================================ STATE ===============================================

    /// @notice The token used for voting in this vault.
    IERC20 public immutable token;

    /// @notice Number of blocks after which history can be pruned.
    uint256 public immutable staleBlockLag;

    // ============================================ EVENTS ==============================================

    // Event to track delegation data
    event VoteChange(address indexed from, address indexed to, int256 amount);

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Deploys a base voting vault, setting immutable values for the token
     *         and staleBlockLag.
     *
     * @param _token                     The external erc20 token contract.
     * @param _staleBlockLag             The number of blocks before which the delegation history is forgotten.
     */
    constructor(IERC20 _token, uint256 _staleBlockLag) {
        if (address(_token) == address(0)) revert BVV_ZeroAddress();

        token = _token;
        staleBlockLag = _staleBlockLag;
    }

    // ==================================== TIMELOCK FUNCTIONALITY ======================================

    /**
     * @notice Timelock-only timelock update function.
     * @dev Allows the timelock to update the timelock address.
     *
     * @param timelock_                  The new timelock.
     */
    function setTimelock(address timelock_) external onlyTimelock {
        Storage.set(Storage.addressPtr("timelock"), timelock_);
    }

    /**
     * @notice Timelock-only manager update function.
     * @dev Allows the timelock to update the manager address.
     *
     * @param manager_                   The new manager address.
     */
    function setManager(address manager_) external onlyTimelock {
        Storage.set(Storage.addressPtr("manager"), manager_);
    }

    // ======================================= VIEW FUNCTIONS ===========================================

    /**
     * @notice Loads the voting power of a user.
     *
     * @param user                       The address we want to load the voting power of.
     * @param blockNumber                Block number to query the user's voting power at.
     *
     * @return votes                     The number of votes.
     */
    function queryVotePower(address user, uint256 blockNumber, bytes calldata) external override returns (uint256) {
        // Get our reference to historical data
        History.HistoricalBalances memory votingPower = _votingPower();

        // Find the historical data and clear everything more than 'staleBlockLag' into the past
        return votingPower.findAndClear(user, blockNumber, block.number - staleBlockLag);
    }

    /**
     * @notice Loads the voting power of a user without changing state.
     *
     * @param user                       The address we want to load the voting power of.
     * @param blockNumber                Block number to query the user's voting power at.
     *
     * @return votes                     The number of votes.
     */
    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256) {
        // Get our reference to historical data
        History.HistoricalBalances memory votingPower = _votingPower();

        // Find the historical datum
        return votingPower.find(user, blockNumber);
    }

    /**
     * @notice A function to access the storage of the timelock address.
     * @dev The timelock can access all functions with the onlyTimelock modifier.
     *
     * @return timelock                  The timelock address.
     */
    function timelock() public pure returns (address) {
        return _timelock().data;
    }

    /**
     * @notice A function to access the storage of the manager address.
     *
     * @dev The manager can access all functions with the onlyManager modifier.
     *
     * @return manager                   The manager address.
     */
    function manager() public pure returns (address) {
        return _manager().data;
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice A function to access the storage of the token value
     *
     * @return balance                    A struct containing the balance uint.
     */
    function _balance() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("balance");
    }

    /**
     * @notice A function to access the storage of the timelock address.
     *
     * @dev The timelock can access all functions with the onlyTimelock modifier.
     *
     * @return timelock                   A struct containing the timelock address.
     */
    function _timelock() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("timelock");
    }

    /**
     * @notice A function to access the storage of the manager address.
     *
     * @dev The manager can access all functions with the onlyManager modifier.
     *
     * @return manager                    A struct containing the manager address.
     */
    function _manager() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("manager");
    }

    /**
     * @notice Returns the historical voting power tracker.
     *
     * @return votingPower              Historical voting power tracker.
     */
    function _votingPower() internal pure returns (History.HistoricalBalances memory) {
        // This call returns a storage mapping with a unique non overwrite-able storage location.
        return (History.load("votingPower"));
    }

    /**
     * @notice Modifier to check that the caller is the manager.
     */
    modifier onlyManager() {
        if (msg.sender != manager()) revert BVV_NotManager();

        _;
    }

    /**
     * @notice Modifier to check that the caller is the timelock.
     */
    modifier onlyTimelock() {
        if (msg.sender != timelock()) revert BVV_NotTimelock();

        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title GovernanceErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the Arcade governance vault contracts. All errors
 * are prefixed by the contract that throws them (e.g., "NBV_" for NFTBoostVault).
 * Errors located in one place to make it possible to holistically look at all
 * governance failure cases.
 */

// ======================================== NFT BOOST VAULT ==========================================
/// @notice All errors prefixed with NBV_, to separate from other contracts in governance.

/**
 * @notice Ensure caller ERC1155 token ownership for NFTBoostVault operations.
 *
 */
error NBV_DoesNotOwn();

/**
 * @notice Ensure caller has not already registered.
 */
error NBV_HasRegistration();

/**
 * @notice Caller has not already registered.
 */
error NBV_NoRegistration();

/**
 * @notice Ensure delegatee is not already registered as the delegate in user's Registration.
 */
error NBV_AlreadyDelegated();

/**
 * @notice Contract balance has to be bigger than amount being withdrawn.
 */
error NBV_InsufficientBalance();

/**
 * @notice Withdrawable tokens less than withdraw request amount.
 *
 * @param withdrawable              The returned withdrawable amount from
 *                                  a user's registration.
 */
error NBV_InsufficientWithdrawableBalance(uint256 withdrawable);

/**
 * @notice Multiplier limit exceeded.
 */
error NBV_MultiplierLimit();

/**
 * @notice No multiplier has been set for token.
 */
error NBV_NoMultiplierSet();

/**
 * @notice The provided token address and token id are invalid.
 *
 * @param tokenAddress              The token address provided.
 * @param tokenId                   The token id provided.
 */
error NBV_InvalidNft(address tokenAddress, uint256 tokenId);

/**
 * @notice User is calling withdraw() with zero amount.
 */
error NBV_ZeroAmount();

/**
 * @notice Cannot pass zero address as an address parameter.
 */
error NBV_ZeroAddress();

/**
 * @notice Provided addresses array holds more than 50 addresses.
 */
error NBV_ArrayTooManyElements();

/** @notice NFT Boost Voting Vault has already been unlocked.
 */
error NBV_AlreadyUnlocked();

/**
 * @notice ERC20 withdrawals from NFT Boost Voting Vault are frozen.
 */
error NBV_Locked();

/**
 * @notice Airdrop contract is not the caller.
 */
error NBV_NotAirdrop();

// =================================== FROZEN LOCKING VAULT =====================================
/// @notice All errors prefixed with FLV_, to separate from other contracts in governance.

/**
 * @notice Withdraws from vault are frozen.
 */
error FLV_WithdrawsFrozen();

// ==================================== VESTING VOTING VAULT ======================================
/// @notice All errors prefixed with AVV_, to separate from other contracts in governance.

/**
 * @notice Block number parameters used to create a grant are invalid. Check that the start time is
 *         before the cliff, and the cliff is before the expiration.
 */
error AVV_InvalidSchedule();

/**
 * @notice Cliff amount should be less than the grant amount.
 */
error AVV_InvalidCliffAmount();

/**
 * @notice Insufficient balance to carry out the transaction.
 *
 * @param amountAvailable           The amount available in the vault.
 */
error AVV_InsufficientBalance(uint256 amountAvailable);

/**
 * @notice Grant has already been created for specified user.
 */
error AVV_HasGrant();

/**
 * @notice Grant has not been created for the specified user.
 */
error AVV_NoGrantSet();

/**
 * @notice Tokens cannot be claimed before the cliff.
 *
 * @param cliffBlock                The block number when grant claims begin.
 */
error AVV_CliffNotReached(uint256 cliffBlock);

/**
 * @notice Tokens cannot be re-delegated to the same address.
 */
error AVV_AlreadyDelegated();

/**
 * @notice Cannot withdraw zero tokens.
 */
error AVV_InvalidAmount();

/**
 * @notice Cannot pass zero address as an address parameter.
 */
error AVV_ZeroAddress();

// ==================================== IMMUTABLE VESTING VAULT ======================================

/**
 * @notice Grants cannot be revoked from the immutable vesting vault.
 */
error IVV_ImmutableGrants();

// ====================================== BASE VOTING VAULT ======================================

/**
 * @notice Caller is not the manager.
 */
error BVV_NotManager();

/**
 * @notice Caller is not the timelock.
 */
error BVV_NotTimelock();

/**
 * @notice Cannot pass zero address as an address parameter.
 */
error BVV_ZeroAddress();

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./Storage.sol";

// This library is an assembly optimized storage library which is designed
// to track timestamp history in a struct which uses hash derived pointers.
// WARNING - Developers using it should not access the underlying storage
// directly since we break some assumptions of high level solidity. Please
// note this library also increases the risk profile of memory manipulation
// please be cautious in your usage of uninitialized memory structs and other
// anti patterns.
library History {
    // The storage layout of the historical array looks like this
    // [(128 bit min index)(128 bit length)] [0][0] ... [(64 bit block num)(192 bit data)] .... [(64 bit block num)(192 bit data)]
    // We give the option to the invoker of the search function the ability to clear
    // stale storage. To find data we binary search for the block number we need
    // This library expects the blocknumber indexed data to be pushed in ascending block number
    // order and if data is pushed with the same blocknumber it only retains the most recent.
    // This ensures each blocknumber is unique and contains the most recent data at the end
    // of whatever block it indexes [as long as that block is not the current one].

    // A struct which wraps a memory pointer to a string and the pointer to storage
    // derived from that name string by the storage library
    // WARNING - For security purposes never directly construct this object always use load
    struct HistoricalBalances {
        string name;
        // Note - We use bytes32 to reduce how easy this is to manipulate in high level sol
        bytes32 cachedPointer;
    }

    /// @notice The method by which inheriting contracts init the HistoricalBalances struct
    /// @param name The name of the variable. Note - these are globals, any invocations of this
    ///             with the same name work on the same storage.
    /// @return The memory pointer to the wrapper of the storage pointer
    function load(string memory name)
        internal
        pure
        returns (HistoricalBalances memory)
    {
        mapping(address => uint256[]) storage storageData =
            Storage.mappingAddressToUnit256ArrayPtr(name);
        bytes32 pointer;
        assembly {
            pointer := storageData.slot
        }
        return HistoricalBalances(name, pointer);
    }

    /// @notice An unsafe method of attaching the cached ptr in a historical balance memory objects
    /// @param pointer cached pointer to storage
    /// @return storageData A storage array mapping pointer
    /// @dev PLEASE DO NOT USE THIS METHOD WITHOUT SERIOUS REVIEW. IF AN EXTERNAL ACTOR CAN CALL THIS WITH
    //       ARBITRARY DATA THEY MAY BE ABLE TO OVERWRITE ANY STORAGE IN THE CONTRACT.
    function _getMapping(bytes32 pointer)
        private
        pure
        returns (mapping(address => uint256[]) storage storageData)
    {
        assembly {
            storageData.slot := pointer
        }
    }

    /// @notice This function adds a block stamp indexed piece of data to a historical data array
    ///         To prevent duplicate entries if the top of the array has the same blocknumber
    ///         the value is updated instead
    /// @param wrapper The wrapper which hold the reference to the historical data storage pointer
    /// @param who The address which indexes the array we need to push to
    /// @param data The data to append, should be at most 192 bits and will revert if not
    function push(
        HistoricalBalances memory wrapper,
        address who,
        uint256 data
    ) internal {
        // Check preconditions
        // OoB = Out of Bounds, short for contract bytecode size reduction
        require(data <= type(uint192).max, "OoB");
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // We load the block number and then shift it to be in the top 64 bits
        uint256 blockNumber = block.number << 192;
        // We combine it with the data, because of our require this will have a clean
        // top 64 bits
        uint256 packedData = blockNumber | data;
        // Load the array length
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // On the first push we don't try to load
        uint256 loadedBlockNumber = 0;
        if (length != 0) {
            (loadedBlockNumber, ) = _loadAndUnpack(storageData, length - 1);
        }
        // The index we push to, note - we use this pattern to not branch the assembly
        uint256 index = length;
        // If the caller is changing data in the same block we change the entry for this block
        // instead of adding a new one. This ensures each block numb is unique in the array.
        if (loadedBlockNumber == block.number) {
            index = length - 1;
        }
        // We use assembly to write our data to the index
        assembly {
            // Stores packed data in the equivalent of storageData[length]
            sstore(
                add(
                    // The start of the data slots
                    add(storageData.slot, 1),
                    // index where we store
                    index
                ),
                packedData
            )
        }
        // Reset the boundaries if they changed
        if (loadedBlockNumber != block.number) {
            _setBounds(storageData, minIndex, length + 1);
        }
    }

    /// @notice Loads the most recent timestamp of delegation power
    /// @param wrapper The memory struct which we want to search for historical data
    /// @param who The user who's balance we want to load
    /// @return the top slot of the array
    function loadTop(HistoricalBalances memory wrapper, address who)
        internal
        view
        returns (uint256)
    {
        // Load the storage pointer
        uint256[] storage userData = _getMapping(wrapper.cachedPointer)[who];
        // Load the length
        (, uint256 length) = _loadBounds(userData);
        // If it's zero no data has ever been pushed so we return zero
        if (length == 0) {
            return 0;
        }
        // Load the current top
        (, uint256 storedData) = _loadAndUnpack(userData, length - 1);
        // and return it
        return (storedData);
    }

    /// @notice Finds the data stored with the highest block number which is less than or equal to a provided
    ///         blocknumber.
    /// @param wrapper The memory struct which we want to search for historical data
    /// @param who The address which indexes the array to be searched
    /// @param blocknumber The blocknumber we want to load the historical data of
    /// @return The loaded unpacked data at this point in time.
    function find(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber
    ) internal view returns (uint256) {
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // Pre load the bounds
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // Search for the blocknumber
        (, uint256 loadedData) =
            _find(storageData, blocknumber, 0, minIndex, length);
        // In this function we don't have to change the stored length data
        return (loadedData);
    }

    /// @notice Finds the data stored with the highest blocknumber which is less than or equal to a provided block number
    ///         Opportunistically clears any data older than staleBlock which is possible to clear.
    /// @param wrapper The memory struct which points to the storage we want to search
    /// @param who The address which indexes the historical data we want to search
    /// @param blocknumber The blocknumber we want to load the historical state of
    /// @param staleBlock A block number which we can [but are not obligated to] delete history older than
    /// @return The found data
    function findAndClear(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber,
        uint256 staleBlock
    ) internal returns (uint256) {
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // Pre load the bounds
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // Search for the blocknumber
        (uint256 staleIndex, uint256 loadedData) =
            _find(storageData, blocknumber, staleBlock, minIndex, length);
        // We clear any data in the stale region
        // Note - Since find returns 0 if no stale data is found and we use > instead of >=
        //        this won't trigger if no stale data is found. Plus it won't trigger on minIndex == staleIndex
        //        == maxIndex and clear the whole array.
        if (staleIndex > minIndex) {
            // Delete the outdated stored info
            _clear(minIndex, staleIndex, storageData);
            // Reset the array info with stale index as the new minIndex
            _setBounds(storageData, staleIndex, length);
        }
        return (loadedData);
    }

    /// @notice Searches for the data stored at the largest blocknumber index less than a provided parameter.
    ///         Allows specification of a expiration stamp and returns the greatest examined index which is
    ///         found to be older than that stamp.
    /// @param data The stored data
    /// @param blocknumber the blocknumber we want to load the historical data for.
    /// @param staleBlock The oldest block that we care about the data stored for, all previous data can be deleted
    /// @param startingMinIndex The smallest filled index in the array
    /// @param length the length of the array
    /// @return Returns the largest stale data index seen or 0 for no seen stale data and the stored data
    function _find(
        uint256[] storage data,
        uint256 blocknumber,
        uint256 staleBlock,
        uint256 startingMinIndex,
        uint256 length
    ) private view returns (uint256, uint256) {
        // We explicitly revert on the reading of memory which is uninitialized
        require(length != 0, "uninitialized");
        // Do some correctness checks
        require(staleBlock <= blocknumber);
        require(startingMinIndex < length);
        // Load the bounds of our binary search
        uint256 maxIndex = length - 1;
        uint256 minIndex = startingMinIndex;
        uint256 staleIndex = 0;

        // We run a binary search on the block number fields in the array between
        // the minIndex and maxIndex. If we find indexes with blocknumber < staleBlock
        // we set staleIndex to them and return that data for an optional clearing step
        // in the calling function.
        while (minIndex != maxIndex) {
            // We use the ceil instead of the floor because this guarantees that
            // we pick the highest blocknumber less than or equal the requested one
            uint256 mid = (minIndex + maxIndex + 1) / 2;
            // Load and unpack the data in the midpoint index
            (uint256 pastBlock, uint256 loadedData) = _loadAndUnpack(data, mid);

            //  If we've found the exact block we are looking for
            if (pastBlock == blocknumber) {
                // Then we just return the data
                return (staleIndex, loadedData);

                // Otherwise if the loaded block is smaller than the block number
            } else if (pastBlock < blocknumber) {
                // Then we first check if this is possibly a stale block
                if (pastBlock < staleBlock) {
                    // If it is we mark it for clearing
                    staleIndex = mid;
                }
                // We then repeat the search logic on the indices greater than the midpoint
                minIndex = mid;

                // In this case the pastBlock > blocknumber
            } else {
                // We then repeat the search on the indices below the midpoint
                maxIndex = mid - 1;
            }
        }

        // We load at the final index of the search
        (uint256 _pastBlock, uint256 _loadedData) =
            _loadAndUnpack(data, minIndex);
        // This will only be hit if a user has misconfigured the stale index and then
        // tried to load father into the past than has been preserved
        require(_pastBlock <= blocknumber, "Search Failure");
        return (staleIndex, _loadedData);
    }

    /// @notice Clears storage between two bounds in array
    /// @param oldMin The first index to set to zero
    /// @param newMin The new minimum filled index, ie clears to index < newMin
    /// @param data The storage array pointer
    function _clear(
        uint256 oldMin,
        uint256 newMin,
        uint256[] storage data
    ) private {
        // Correctness checks on this call
        require(oldMin <= newMin);
        // This function is private and trusted and should be only called by functions which ensure
        // that oldMin < newMin < length
        assembly {
            // The layout of arrays in solidity is [length][data]....[data] so this pointer is the
            // slot to write to data
            let dataLocation := add(data.slot, 1)
            // Loop through each index which is below new min and clear the storage
            // Note - Uses strict min so if given an input like oldMin = 5 newMin = 5 will be a no op
            for {
                let i := oldMin
            } lt(i, newMin) {
                i := add(i, 1)
            } {
                // store at the starting data pointer + i 256 bits of zero
                sstore(add(dataLocation, i), 0)
            }
        }
    }

    /// @notice Loads and unpacks the block number index and stored data from a data array
    /// @param data the storage array
    /// @param i the index to load and unpack
    /// @return (block number, stored data)
    function _loadAndUnpack(uint256[] storage data, uint256 i)
        private
        view
        returns (uint256, uint256)
    {
        // This function is trusted and should only be called after checking data lengths
        // we use assembly for the sload to avoid reloading length.
        uint256 loaded;
        assembly {
            loaded := sload(add(add(data.slot, 1), i))
        }
        // Unpack the packed 64 bit block number and 192 bit data field
        return (
            loaded >> 192, // block number of the data
            loaded &
                0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff // the data
        );
    }

    /// @notice This function sets our non standard bounds data field where a normal array
    ///         would have length
    /// @param data the pointer to the storage array
    /// @param minIndex The minimum non stale index
    /// @param length The length of the storage array
    function _setBounds(
        uint256[] storage data,
        uint256 minIndex,
        uint256 length
    ) private {
        // Correctness check
        require(minIndex < length);

        assembly {
            // Ensure data cleanliness
            let clearedLength := and(
                length,
                0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff
            )
            // We move the min index into the top 128 bits by shifting it left by 128 bits
            let minInd := shl(128, minIndex)
            // We pack the data using binary or
            let packed := or(minInd, clearedLength)
            // We store in the packed data in the length field of this storage array
            sstore(data.slot, packed)
        }
    }

    /// @notice This function loads and unpacks our packed min index and length for our custom storage array
    /// @param data The pointer to the storage location
    /// @return minInd the first filled index in the array
    /// @return length the length of the array
    function _loadBounds(uint256[] storage data)
        private
        view
        returns (uint256 minInd, uint256 length)
    {
        // Use assembly to manually load the length storage field
        uint256 packedData;
        assembly {
            packedData := sload(data.slot)
        }
        // We use a shift right to clear out the low order bits of the data field
        minInd = packedData >> 128;
        // We use a binary and to extract only the bottom 128 bits
        length =
            packedData &
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

// This library allows for secure storage pointers across proxy implementations
// It will return storage pointers based on a hashed name and type string.
library Storage {
    // This library follows a pattern which if solidity had higher level
    // type or macro support would condense quite a bit.

    // Each basic type which does not support storage locations is encoded as
    // a struct of the same name capitalized and has functions 'load' and 'set'
    // which load the data and set the data respectively.

    // All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    // which will return a storage version of the type with slot which is the hash of
    // the variable name and type string. This pointer allows easy state management between
    // upgrades and overrides the default solidity storage slot system.

    /// @dev The address type container
    struct Address {
        address data;
    }

    /// @notice A function which turns a variable name for a storage address into a storage
    ///         pointer for its container.
    /// @param name the variable name
    /// @return data the storage pointer
    function addressPtr(string memory name)
        internal
        pure
        returns (Address storage data)
    {
        bytes32 typehash = keccak256("address");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice A function to load an address from the container struct
    /// @param input the storage pointer for the container
    /// @return the loaded address
    function load(Address storage input) internal view returns (address) {
        return input.data;
    }

    /// @notice A function to set the internal field of an address container
    /// @param input the storage pointer to the container
    /// @param to the address to set the container to
    function set(Address storage input, address to) internal {
        input.data = to;
    }

    /// @dev The uint256 type container
    struct Uint256 {
        uint256 data;
    }

    /// @notice A function which turns a variable name for a storage uint256 into a storage
    ///         pointer for its container.
    /// @param name the variable name
    /// @return data the storage pointer
    function uint256Ptr(string memory name)
        internal
        pure
        returns (Uint256 storage data)
    {
        bytes32 typehash = keccak256("uint256");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice A function to load an uint256 from the container struct
    /// @param input the storage pointer for the container
    /// @return the loaded uint256
    function load(Uint256 storage input) internal view returns (uint256) {
        return input.data;
    }

    /// @notice A function to set the internal field of a unit256 container
    /// @param input the storage pointer to the container
    /// @param to the address to set the container to
    function set(Uint256 storage input, uint256 to) internal {
        input.data = to;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToUnit256Ptr(string memory name)
        internal
        pure
        returns (mapping(address => uint256) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => uint256)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToUnit256ArrayPtr(string memory name)
        internal
        pure
        returns (mapping(address => uint256[]) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => uint256[])");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice Allows external users to calculate the slot given by this lib
    /// @param typeString the string which encodes the type
    /// @param name the variable name
    /// @return the slot assigned by this lib
    function getPtr(string memory typeString, string memory name)
        external
        pure
        returns (uint256)
    {
        bytes32 typehash = keccak256(abi.encodePacked(typeString));
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        return (uint256)(offset);
    }

    // A struct which represents 1 packed storage location with a compressed
    // address and uint96 pair
    struct AddressUint {
        address who;
        uint96 amount;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToPackedAddressUint(string memory name)
        internal
        pure
        returns (mapping(address => AddressUint) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => AddressUint)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../libraries/ARCDVestingVaultStorage.sol";

interface IARCDVestingVault {
    /**
     * @notice Public functions
     */
    function getGrant(address _who) external view returns (ARCDVestingVaultStorage.Grant memory);

    function claimable(address _who) external view returns (uint256);

    function claim(uint256 _amount) external;

    function delegate(address _to) external;

    /**
     * @notice Only Manager functions
     */
    function addGrantAndDelegate(
        address _who,
        uint128 _amount,
        uint128 _cliffAmount,
        uint128 _startTime,
        uint128 _expiration,
        uint128 _cliff,
        address _delegatee
    ) external;

    function revokeGrant(address _who) external;

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount, address _recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBaseVotingVault {
    function queryVotePower(address user, uint256 blockNumber, bytes calldata extraData) external returns (uint256);

    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256);

    function setTimelock(address timelock_) external;

    function setManager(address manager_) external;

    function timelock() external pure returns (address);

    function manager() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title ARCDVestingVaultStorage
 * @author Non-Fungible Technologies, Inc.
 *
 * Contract based on Council's `Storage.sol` with modified scope to match the VestingVault
 * requirements. This library allows for secure storage pointers across proxy implementations.
 * It will return storage pointers based on a hashed name and type string.
 */
library ARCDVestingVaultStorage {
    // ========================================== DATA TYPES ============================================

    // This library follows a pattern which if solidity had higher level
    // type or macro support would condense quite a bit.

    // Each basic type which does not support storage locations is encoded as
    // a struct of the same name capitalized and has functions 'load' and 'set'
    // which load the data and set the data respectively.

    // All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    // which will return a storage version of the type with slot which is the hash of
    // the variable name and type string. This pointer allows easy state management between
    // upgrades and overrides the default solidity storage slot system.

    /// @notice A struct which represents 1 packed storage location (Grant)
    struct Grant {
        uint128 allocation;
        uint128 cliffAmount;
        uint128 withdrawn;
        uint128 created;
        uint128 expiration;
        uint128 cliff;
        uint128 latestVotingPower;
        address delegatee;
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice Returns the storage pointer for a named mapping of address to uint256[].
     *
     * @param name            The variable name for the pointer
     */
    function mappingAddressToGrantPtr(
        string memory name
    ) internal pure returns (mapping(address => Grant) storage data) {
        bytes32 typehash = keccak256("mapping(address => Grant)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../external/council/libraries/History.sol";
import "../external/council/libraries/Storage.sol";

/**
 * @title HashedStorageReentrancyBlock
 * @author Non-Fungible Technologies, Inc.
 *
 * Helper contract to prevent reentrancy attacks using hashed storage. This contract is used
 * to protect against reentrancy attacks in the Arcade voting vault contracts.
 */
abstract contract HashedStorageReentrancyBlock {
    // =========================================== HELPERS ==============================================

    /**
     * @dev Returns the storage pointer to the entered state variable.
     *
     * @return Storage              pointer to the entered state variable.
     */
    function _entered() internal pure returns (Storage.Uint256 memory) {
        return Storage.uint256Ptr("entered");
    }

    // ========================================= MODIFIERS =============================================

    /**
     * @dev Re-entrancy guard modifier using hashed storage.
     */
    modifier nonReentrant() {
        Storage.Uint256 memory entered = _entered();
        // Check the state variable before the call is entered
        require(entered.data == 1, "REENTRANCY");

        // Store that the function has been entered
        entered.data = 2;

        // Run the function code
        _;

        // Clear the state
        entered.data = 1;
    }
}