// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import {RewardsManager} from "RewardsManager.sol";

contract BadgerTree is RewardsManager {
  // So Brownie compiles it tbh
  // Changes here invalidate the bytecode, breaking trust of the mix
  // DO NOT CHANGE THIS FILE
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


import {IERC20} from "IERC20.sol";
import {SafeERC20} from "SafeERC20.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";


/// @title RewardsManager
/// @author Alex the Entreprenerd @ BadgerDAO
/// @notice CREDIT
/// Most of the code is inspired by:
/// SNX / CVX RewardsPool
/// Aave Stake V2
/// Compound
/// Inverse.Finance Dividend Token
/// Pool Together V4
/// ABOUT THE ARCHITECTURE
/// Invariant for deposits
/// If you had X token at epoch N, you'll have X tokens at epoch N+1
/// Total supply may be different
/// However, we calculate your share by just multiplying the share * seconds in the vault
/// If you had X tokens a epoch N, and you had X tokens at epoch N+1
/// You'll get X * SECONDS_PER_EPOCH points in epoch N+1 if you redeem at N+2
/// If you have X tokens at epoch N and withdraw, you'll get TIME_IN_EPOCH * X points

/// MAIN ISSUE
/// You'd need to accrue every single user to make sure that everyone get's the fair share
/// Alternatively you'd need to calcualate each share on each block
/// The alternative would be to check the vault.totalSupply()
/// However note that will change (can change at any time in any magnitude)
/// and as such cannot be trusted as much

/// SOLUTION
/// That the invariant for deposits works also for totalSupply
/// If totalSupply was X tokens at epoch N, and nothing changes in epoch N+1
/// Then in epoch N+1 the totalSupply was the same as in epoch N
/// If that's the case
/// and we accrue on every account change
/// then all we gotta do is take totalSupply * lastAccrue amount and that should net us the totalPoints per epoch
/// Remaining, non accrued users, have to be accrued without increasing the totalPoints as they are already accounted for in the totalSupply * time

/// Invariant for points
/// If you know totalSupply and Balance, and you know last timebalanceChanged as well as lasTime The Vault was accrued
/// points = timeSinceLastUserAccrue * shares
/// totalPoints = timeSinceLastVaultAccrue * totalSupply

/// CONCLUSION
/// Given the points, knowing the rewards amounts to distribute, you know how to split them at the end of each epoch

contract RewardsManager is ReentrancyGuard {
    
    using SafeERC20 for IERC20;

    // NOTE: Must be `immutable`, remove `immutable` for coverage report
    // DEPLOY_TIME allows us to automatically compute epochs
    // Since it's immutable the math is very cheap
    uint256 public immutable DEPLOY_TIME; 
    
    // One epoch is one week
    // This allows to specify rewards on a per week basis, making it easier to interact with contract
    uint256 public constant SECONDS_PER_EPOCH = 604800; 
    
    /// Used to store the start and end time for a epoch
    struct Epoch {
        uint256 startTimestamp;
        uint256 endTimestamp;
    }

    // Last timestamp in which vault was accrued - lastAccruedTimestamp[epochId][vaultAddress]
    mapping(uint256 => mapping(address => uint256)) public lastAccruedTimestamp; 

    // Last timestamp at which we accrued user. Used to calculate rewards in epochs with vault interaction 
    // e.g. lastUserAccrueTimestamp[epochId][vaultAddress][userAddress]
    mapping(uint256 => mapping(address => mapping(address => uint256))) public lastUserAccrueTimestamp; 

    // Calculate points per each epoch 
    // e.g. shares[epochId][vaultAddress][userAddress]
    mapping(uint256 => mapping(address => mapping(address => uint256))) public shares; 

    // Sum of all deposits for a vault at an epoch
    // e.g. totalSupply[epochId][vaultAddress]
    mapping(uint256 => mapping(address => uint256)) public totalSupply; 

    // Calculate points per each epoch
    // e.g. points[epochId][vaultAddress][userAddress]
    // User share of token X is equal to tokensForEpoch * points[epochId][vaultId][userAddress] / totalPoints[epochId][vaultAddress]
    // You accrue one point per second for each second you are in the vault
    mapping(uint256 => mapping(address => mapping(address => uint256))) public points; 

    // Given point for epoch how many where withdrawn by user?
    // e.g. pointsWithdrawn[epochId][vaultAddress][userAddress][rewardToken]
    mapping(uint256 => mapping(address => mapping(address => mapping(address => uint256)))) public pointsWithdrawn; 
    
    // Sum of all points given for a vault at an epoch 
    // e.g. totalPoints[epochId][vaultAddress]
    mapping(uint256 => mapping(address => uint256)) public totalPoints; 

    // Amount of rewards for the given epoch and vault
    // rewards[epochId][vaultAddress][tokenAddress] = AMOUNT
    mapping(uint256 => mapping(address => mapping(address => uint256))) public rewards; 
    
    // EpochId for Transfer is implied by block.timestamp (and can be fetched there)
    event Transfer(address indexed vault, address indexed from, address indexed to, uint256 amount);

    // Emitted after adding a reward
    event AddReward(uint256 epochId, address indexed vault, address indexed token, uint256 amount, address indexed sender);

    // Claiming of rewards may be done in bulk, information will be incomplete, as such we `epochId` is not indexed 
    event ClaimReward(uint256 epochId, address indexed vault, address indexed token, uint256 amount, address indexed claimer);

    // Fired off when using bulk claim functions to save gas
    event BulkClaimReward(uint256 epochStart, uint256 epochEnd, address indexed vault, address indexed token, uint256 totalAmount, address indexed claimer);

    constructor() {
        DEPLOY_TIME = block.timestamp;
    }

    /// === EPOCH HANDLING ==== ///

    /// @dev Returns the current epoch
    /// @notice The first epoch is 1 as 0 is used as a null value flag in the contract
    /// @return uint256 - Current epoch
    function currentEpoch() public view returns (uint256) {
        unchecked {
            return (block.timestamp - DEPLOY_TIME) / SECONDS_PER_EPOCH + 1;
        }
    }

    /// @dev Returns the start and end times for the Epoch
    /// @param epochId - The epochId you want info of
    /// @return Epoch - Epoch struct with the start and end time of the epoch in matter
    function getEpochData(uint256 epochId) public view returns (Epoch memory) {
        unchecked {
            uint256 start = DEPLOY_TIME + SECONDS_PER_EPOCH * (epochId - 1);
            uint256 end = start + SECONDS_PER_EPOCH;
            return Epoch(start, end);
        }
    }

    /// === NOTIFY SYSTEM === ///

    /// @dev This is used by external contracts to notify a change in balances
    /// @notice The handling of changes requires accruing points until now
    /// @notice After that, just change the balances
    /// @notice This contract is effectively tracking the balances of all users, this is pretty expensive
    /// @param from - sender of amount. address(0) represents a deposit
    /// @param to - receiver of amount. address(0) represents a withdrawal
    /// @param amount - quantity sent
    function notifyTransfer(address from, address to, uint256 amount) external {
        require(from != to, "Cannot transfer to yourself");
        // NOTE: Anybody can call this because it's indexed by msg.sender
        // Vault is msg.sender, and msg.sender cost 1 less gas

        if (from == address(0)) {
            _handleDeposit(msg.sender, to, amount);
        } else if (to == address(0)) {
            _handleWithdrawal(msg.sender, from, amount);
        } else {
            _handleTransfer(msg.sender, from, to, amount);
        }

        emit Transfer(msg.sender, from, to, amount);
    }

    /// @dev handles a deposit for vault, to address of amount
    /// @param vault - address for which the balance is changing
    /// @param to - receiver of amount
    /// @param amount - quantity sent
    function _handleDeposit(address vault, address to, uint256 amount) internal {
        uint256 cachedCurrentEpoch = currentEpoch();
        accrueUser(cachedCurrentEpoch, vault, to);
        // We have to accrue vault as totalSupply is gonna change
        accrueVault(cachedCurrentEpoch, vault);

        unchecked {
            // Add deposit data for user
            shares[cachedCurrentEpoch][vault][to] += amount;
        }
        // And total shares for epoch // Remove unchecked per QSP-5
        totalSupply[cachedCurrentEpoch][vault] += amount;

    }

    /// @dev handles a withdraw for vault, from address of amount
    /// @param vault - address for which the balance is changing
    /// @param from - receiver of amount
    /// @param amount - quantity sent
    function _handleWithdrawal(address vault, address from, uint256 amount) internal {
        uint256 cachedCurrentEpoch = currentEpoch();
        accrueUser(cachedCurrentEpoch, vault, from);
        // We have to accrue vault as totalSupply is gonna change
        accrueVault(cachedCurrentEpoch, vault);

        // Delete last shares
        // Delete deposit data or user
        shares[cachedCurrentEpoch][vault][from] -= amount;
        // Reduce totalSupply
        totalSupply[cachedCurrentEpoch][vault] -= amount;

    }

    /// @dev handles a transfer for vault, from address to address of amount
    /// @param vault - address for which the balance is changing
    /// @param from - sender of amount
    /// @param to - receiver of amount
    /// @param amount - quantity sent
    function _handleTransfer(address vault, address from, address to, uint256 amount) internal {
        uint256 cachedCurrentEpoch = currentEpoch();
        // Accrue points for from, so they get rewards
        accrueUser(cachedCurrentEpoch, vault, from);
        // Accrue points for to, so they don't get too many rewards
        accrueUser(cachedCurrentEpoch, vault, to);

        unchecked {
            // Add deposit data for to
            shares[cachedCurrentEpoch][vault][to] += amount;
        }

         // Delete deposit data for from
        shares[cachedCurrentEpoch][vault][from] -= amount;

        // No change in total supply as this is a transfer
    }

    /// === VAULT ACCRUAL === ///

    /// @dev Given an epoch and vault, accrue it's totalPoints
    /// @notice You need to accrue a vault before you can claim it's rewards
    /// @notice You can accrue by calling this function to save gas if you haven't moved your funds in a while 
    ///     (or use the bulk function to claim)
    /// @param epochId - the Epoch to accrue, cannot be a future one
    /// @param vault - the vault to accrue
    function accrueVault(uint256 epochId, address vault) public {
        require(epochId <= currentEpoch(), "Cannot see the future");

        (uint256 supply, bool shouldUpdate) = _getTotalSupplyAtEpoch(epochId, vault);

        if(shouldUpdate) {
            // Because we didn't return early, to make it cheaper for future lookbacks, let's store the lastKnownBalance
            totalSupply[epochId][vault] = supply;
        }

        uint256 timeLeftToAccrue = _getVaultTimeLeftToAccrue(epochId, vault);

        // Prob expired, may as well return early
        if(timeLeftToAccrue == 0) {
            // We're done
            lastAccruedTimestamp[epochId][vault] = block.timestamp;
            return;
        }

        // Removed unchecked per QSP-5
        totalPoints[epochId][vault] += timeLeftToAccrue * supply;
        // Any time after end is irrelevant
        // Setting to the actual time when `accrueVault` was called may help with debugging though
        lastAccruedTimestamp[epochId][vault] = block.timestamp;
    }

    /// @dev see {_getVaultTimeLeftToAccrue}
    function getVaultTimeLeftToAccrue (uint256 epochId, address vault) external view returns (uint256) {
        require(epochId <= currentEpoch(), "Cannot see the future");
        return _getVaultTimeLeftToAccrue(epochId, vault);
    }

    /// @dev Given an epoch and a vault, return the time left to accrue
    /// @notice Will return between 0 and `SECONDS_PER_EPOCH` for any epoch <= currentEpoch()
    /// @notice Will return a nonsense value if you query for an epoch in the future 
    /// @param epochId - Which epoch to query for
    /// @param vault - Which vault to query for
    /// @return uint256 - Time left to accrue for a given vault within an epoch
    function _getVaultTimeLeftToAccrue(uint256 epochId, address vault) internal view returns (uint256) {
        uint256 lastAccrueTime = lastAccruedTimestamp[epochId][vault];
        Epoch memory epochData = getEpochData(epochId);
        
        if(lastAccrueTime >= epochData.endTimestamp) {
            return 0; // Already accrued
        }

        uint256 maxTime = _min(block.timestamp, epochData.endTimestamp);

        // return _min(end, now) - start;
        if(lastAccrueTime == 0) {
            unchecked {
                return maxTime - epochData.startTimestamp;
            }
        }

        // If timestamp is 0, we never accrued
        // If this underflow the accounting on the contract is broken, so it's prob best for it to underflow
        unchecked {
            return _min(maxTime - lastAccrueTime, SECONDS_PER_EPOCH);
        }
    }

    /// @dev see {_getTotalSupplyAtEpoch}
    function getTotalSupplyAtEpoch(uint256 epochId, address vault) external view returns (uint256, bool) {
        require(epochId <= currentEpoch(), "Cannot see the future");
        return _getTotalSupplyAtEpoch(epochId, vault);
    }

    /// @dev Given and epoch and a vault, returns the appropiate totalSupply for this vault and whether
    /// the totalSupply should be updated
    /// @notice we return whether to update because the function has to figure that out
    /// comparing the storage value after the return value is a waste of a SLOAD
    /// @param epochId - Which epoch to query for
    /// @param vault - Which vault to query for
    /// @return uint256 totalSupply at epochId
    /// @return bool shouldUpdate, should we update the totalSupply[epochId][vault] (as we had to look it up)
    function _getTotalSupplyAtEpoch(uint256 epochId, address vault) internal view returns (uint256, bool) {
        if(lastAccruedTimestamp[epochId][vault] != 0){
            // Already updated
            return (totalSupply[epochId][vault], false);
        }

        // Shortcut
        if(epochId == 1) {
            // If epoch is first one, and we don't have a totalSupply, then totalSupply is zero
            return (0, false);

            // This allows to do epochId - 1 below
        }

        uint256 lastAccrueEpoch = 0; // Not found

        // In this case we gotta loop until we find the last known totalSupply which was accrued
        for(uint256 i = epochId - 1; i > 0; ){
            // NOTE: We have to loop because while we know the length of an epoch 
            // we don't have a guarantee of when it starts

            if(lastAccruedTimestamp[i][vault] != 0) {
                lastAccrueEpoch = i;
                break; // Found it
            }

            unchecked {
                --i;
            }
        }

        // Balance Never changed if we get here, the totalSupply is actually 0
        if(lastAccrueEpoch == 0) {
            // No need to update if it's 0
            return (0, false);
        }


        // We found the last known balance given lastAccruedTimestamp
        // Can still be zero (all shares burned)
        uint256 lastKnownTotalSupply = totalSupply[lastAccrueEpoch][vault];

        if(lastKnownTotalSupply == 0){
            // Despite it all, it's zero, no point in overwriting
            return (0, false);
        }

        return (lastKnownTotalSupply, true);
    }

    /// === USER ACCRUAL === ///

    /// @dev Accrue points gained during this epoch
    /// @notice This is called for both receiving, sending, depositing and withdrawing, any time the user balance changes
    /// @notice To properly accrue for this epoch:
    /// @notice Figure out the time passed since last accrue (max is start of epoch)
    /// @notice Figure out their points (their current balance) (before we update)
    /// @notice Just multiply the points * the time, those are the points they've earned
    /// @param epochId - id of epoch that you want to accrue points for
    /// @param vault - address under which you want to accrue
    /// @param user - address you want to accrue
    function accrueUser(uint256 epochId, address vault, address user) public {
        require(epochId <= currentEpoch(), "only ended epochs");

        (uint256 currentBalance, bool shouldUpdate) = _getBalanceAtEpoch(epochId, vault, user);

        if(shouldUpdate) {
            shares[epochId][vault][user] = currentBalance;
        }

        // Optimization:  No balance, return early
        if(currentBalance == 0){
            // Update timestamp to avoid math being off
            lastUserAccrueTimestamp[epochId][vault][user] = block.timestamp;
            return;
        }

        uint256 timeLeftToAccrue = _getUserTimeLeftToAccrue(epochId, vault, user);

        // Optimization: time is 0, end early
        if(timeLeftToAccrue == 0){
            // No time can happen if accrue happened on same block or if we're accruing after the end of the epoch
            // As such we still update the timestamp for historical purposes
            // This is effectively 5k more gas to know the last accrue time even after it lost relevance
            lastUserAccrueTimestamp[epochId][vault][user] = block.timestamp;
            return;
        }

        unchecked {
            // Add Points and use + instead of +=
            points[epochId][vault][user] += timeLeftToAccrue * currentBalance;
        }

        // Set last time for updating the user
        lastUserAccrueTimestamp[epochId][vault][user] = block.timestamp;
    }


    /// @dev see `_getUserTimeLeftToAccrue`
    function getUserTimeLeftToAccrue(uint256 epochId, address vault, address user) public view returns (uint256) {    
        require(epochId <= currentEpoch(), "Cannot see the future");
        return _getUserTimeLeftToAccrue(epochId, vault, user);
    }

    /// @dev Figures out the last time the given user was accrued at the epoch for the vault
    /// @return uint256 - Last time the user was accrued for a given vault and epoch
    /// @notice Invariant -> Never changed means full duration
    /// @notice Will return between 0 and `SECONDS_PER_EPOCH` for any epochId <= currentEpoch()
    /// @notice Will return a nonsense value if you query for an epoch in the future 
    /// @param epochId - id of epoch for which you want to know the time left for point accrual
    /// @param vault - vault you want the info for
    /// @param user - address you want the info for
    function _getUserTimeLeftToAccrue(uint256 epochId, address vault, address user) internal view returns (uint256) {
        uint256 lastBalanceChangeTime = lastUserAccrueTimestamp[epochId][vault][user];
        Epoch memory epochData = getEpochData(epochId);

        // If for some reason we are trying to accrue a position already accrued after end of epoch, return 0
        if(lastBalanceChangeTime >= epochData.endTimestamp){
            return 0;
        }

        // Cap maxTime at epoch end
        uint256 maxTime = _min(block.timestamp, epochData.endTimestamp);

        // If timestamp is 0, we never accrued
        // return _min(end, now) - start;
        if(lastBalanceChangeTime == 0) {
            unchecked {
                return maxTime - epochData.startTimestamp;
            }
        }


        // If this underflow the accounting on the contract is broken, so it's prob best for it to underflow
        unchecked {
            return _min(maxTime - lastBalanceChangeTime, SECONDS_PER_EPOCH);
        }

        // Weird Options -> Accrue has happened after end of epoch -> Don't accrue anymore

        // Normal option 1  -> Accrue has happened in this epoch -> Accrue remaining time
        // Normal option 2 -> Accrue never happened this epoch -> Accrue all time from start of epoch
    }

    /// @dev See `_getBalanceAtEpoch`
    function getBalanceAtEpoch(uint256 epochId, address vault, address user) external view returns (uint256, bool) {
        require(epochId <= currentEpoch(), "Cannot see the future");
        return _getBalanceAtEpoch(epochId, vault, user);
    }
    

    /// @dev Figures out and returns the balance of a user for a vault at a specific epoch
    /// @return uint256 - balance
    /// @return bool - should update, whether the accrue function should update the balance for the inputted epochId
    /// @notice we return whether to update because the function has to figure that out
    /// comparing the storage value after the return value is a waste of a SLOAD
    /// @param epochId - id of epoch at which time you want to know the balance of
    /// @param vault - vault for which you are checking the balance of
    /// @param user - address you want the balance of
    function _getBalanceAtEpoch(uint256 epochId, address vault, address user) internal view returns (uint256, bool) {
        // Time Last Known Balance has changed
        if(lastUserAccrueTimestamp[epochId][vault][user] != 0 ) {
            return (shares[epochId][vault][user], false);
        }

        // Shortcut
        if(epochId == 1) {
            // If epoch is first one, and we don't have a balance, then balance is zero
            return (0, false);

            // This allows to do epochId - 1 below
        }

        uint256 lastBalanceChangeEpoch = 0; // We haven't found it

        // Pessimistic Case, we gotta fetch the balance from the lastKnown Balances (could be up to currentEpoch - totalEpochs away)
        // Because we have lastUserAccrueTimestamp, let's find the first non-zero value, that's the last known balance
        // Notice that the last known balance we're looking could be zero, hence we look for a non-zero change first
        for(uint256 i = epochId - 1; i > 0; ){
            // NOTE: We have to loop because while we know the length of an epoch 
            // we don't have a guarantee of when it starts

            if(lastUserAccrueTimestamp[i][vault][user] != 0) {
                lastBalanceChangeEpoch = i;
                break; // Found it
            }

            unchecked {
                --i;
            }
        }

        // Balance Never changed if we get here, it's their first deposit, return 0
        if(lastBalanceChangeEpoch == 0) {
            // We don't need to update the cachedBalance, the accrueTimestamp will be updated though
            return (0, false);
        }


        // We found the last known balance given lastUserAccrueTimestamp
        // Can still be zero
        uint256 lastKnownBalance = shares[lastBalanceChangeEpoch][vault][user];

        return (lastKnownBalance, true); // We should update the balance
    }

    /// === REWARD CLAIMING === ///

    /// @dev Allow to bulk claim rewards, each ith entry is used for a separate `claimReward`
    /// @notice We may delete this function as you could just build a periphery contract for this
    /// @param epochsToClaim - List of epochIds
    /// @param vaults - List of Vaults
    /// @param tokens - List of Tokens
    /// @param users - List of Users
    function claimRewards(uint256[] calldata epochsToClaim, address[] calldata vaults, address[] calldata tokens, address[] calldata users) external {
        uint256 usersLength = users.length;
        uint256 epochLength = epochsToClaim.length;
        uint256 vaultLength = vaults.length;
        uint256 tokensLength = tokens.length;

        require(usersLength == epochLength, "length mismatch");
        require(epochLength == vaultLength, "length mismatch");
        require(vaultLength == tokensLength, "length mismatch");

        // Given an epoch and a vault
        // I have to accrue until end
        // I then compare the point to total points
        // Then, given the list of tokens I execute the transfers
        // To avoid re-entrancy we always change state before sending
        // Also this function needs to have re-entancy checks as well
        for(uint256 i; i < epochLength; ) {
            claimReward(epochsToClaim[i], vaults[i], tokens[i], users[i]);

            unchecked {
                ++i;
            }
        }
    }
    
    /// @dev Claim one Token Reward for a specific epoch, vault and user
    /// @notice Reference version of the function, fully onChain, fully in storage
    ///     This function is as expensive as it gets
    /// @notice Anyone can claim on behalf of others
    /// @notice Gas savings is fine as public / external matters only when using mem vs calldata for arrays
    /// @param epochId - For EpochId deposit are you claiming
    /// @param vault - Which vault are you claiming
    /// @param token - Which token reward to claim
    /// @param user - Who to claim for
    function claimRewardReference(uint256 epochId, address vault, address token, address user) public {
        require(epochId < currentEpoch(), "only ended epochs");

        accrueUser(epochId, vault, user);
        accrueUser(epochId, vault, address(this)); // Accrue this contract points
        accrueVault(epochId, vault);

        // Now that they are accrue, just use the points to estimate reward and send
        uint256 userPoints = points[epochId][vault][user];
        uint256 pointsLeft = userPoints - pointsWithdrawn[epochId][vault][user][token];

        // Early return
        if(pointsLeft == 0){
            return;
        }

        // Get amounts to divide over
        uint256 vaultTotalPoints = totalPoints[epochId][vault];
        uint256 thisContractVaultPoints = points[epochId][vault][address(this)];

        
        // We got some stuff left // Use ratio to calculate what we got left
        uint256 totalAdditionalReward = rewards[epochId][vault][token];

        // NOTE: We don't check for zero reward, make sure to claim a token you can receive!

        // NOTE: Divison at end to minimize dust, on avg 2 Million Claims = 1 USDC of dust
        uint256 tokensForUser = totalAdditionalReward * pointsLeft / (vaultTotalPoints - thisContractVaultPoints);
        
        // Update points
        unchecked {
            // Cannot overflow per the math above
            pointsWithdrawn[epochId][vault][user][token] += pointsLeft;
        }

        emit ClaimReward(epochId, vault, token, tokensForUser, user);

        // Transfer the token
        IERC20(token).safeTransfer(user, tokensForUser);
    }

    /// @dev Claim Rewards, without accruing points, saves gas for one-off claims
    /// @param epochId - For EpochId deposit are you claiming
    /// @param vault - Which vault are you claiming
    /// @param token - Which token reward to claim
    /// @param user - Who to claim for
    function claimReward(uint256 epochId, address vault, address token, address user) public {
        require(epochId < currentEpoch(), "only ended epochs");

        (uint256 userBalanceAtEpochId, ) = _getBalanceAtEpoch(epochId, vault, user);

        // For all epochs from start to end, get user info
        UserInfo memory userInfo = _getUserNextEpochInfo(epochId, vault, user, userBalanceAtEpochId);

        // If userPoints are zero, go next fast
        if (userInfo.userEpochTotalPoints == 0) {
            return; // Nothing to claim
        }

        (uint256 vaultSupplyAtEpochId, ) = _getTotalSupplyAtEpoch(epochId, vault);
        (uint256 startingContractBalance, ) = _getBalanceAtEpoch(epochId, vault, address(this));

        VaultInfo memory vaultInfo = _getVaultNextEpochInfo(epochId, vault, vaultSupplyAtEpochId);
        UserInfo memory thisContractInfo = _getUserNextEpochInfo(epochId, vault, address(this), startingContractBalance);

        // To be able to use the same ratio for all tokens, we need the pointsWithdrawn to all be 0
        require(pointsWithdrawn[epochId][vault][user][token] == 0, "already claimed");

        // We got some stuff left // Use ratio to calculate what we got left
        uint256 totalAdditionalReward = rewards[epochId][vault][token];

        // Calculate tokens for user
        uint256 tokensForUser = totalAdditionalReward * userInfo.userEpochTotalPoints / (vaultInfo.vaultEpochTotalPoints - thisContractInfo.userEpochTotalPoints);
        
        // We checked it was zero, no need to add
        pointsWithdrawn[epochId][vault][user][token] = userInfo.userEpochTotalPoints;

        emit ClaimReward(epochId, vault, token, tokensForUser, user);

        IERC20(token).safeTransfer(user, tokensForUser);
    }

    /// @dev Claim Rewards, without accruing points, for non-emitting vaults, saves gas for one-off claims
    /// @param epochId - For EpochId deposit are you claiming
    /// @param vault - Which vault are you claiming
    /// @param token - Which token reward to claim
    /// @param user - Who to claim for
    function claimRewardNonEmitting(uint256 epochId, address vault, address token, address user) public {
        require(epochId < currentEpoch(), "only ended epochs");

        // Get balance for this epoch
        (uint256 userBalanceAtEpochId, ) = _getBalanceAtEpoch(epochId, vault, user);
        
        // Get user info for this epoch
        UserInfo memory userInfo = _getUserNextEpochInfo(epochId, vault, user, userBalanceAtEpochId);

        // If userPoints are zero, go next fast
        if (userInfo.userEpochTotalPoints == 0) {
            return; // Nothing to claim
        }

        (uint256 vaultSupplyAtEpochId, ) = _getTotalSupplyAtEpoch(epochId, vault);

        VaultInfo memory vaultInfo = _getVaultNextEpochInfo(epochId, vault, vaultSupplyAtEpochId);

        // To be able to use the same ratio for all tokens, we need the pointsWithdrawn to all be 0
        require(pointsWithdrawn[epochId][vault][user][token] == 0, "already claimed");

        // We got some stuff left // Use ratio to calculate what we got left
        uint256 totalAdditionalReward = rewards[epochId][vault][token];

        // Calculate tokens for user
        uint256 tokensForUser = totalAdditionalReward * userInfo.userEpochTotalPoints / vaultInfo.vaultEpochTotalPoints;
        
        // We checked it was zero, no need to add
        pointsWithdrawn[epochId][vault][user][token] = userInfo.userEpochTotalPoints;

        emit ClaimReward(epochId, vault, token, tokensForUser, user);

        IERC20(token).safeTransfer(user, tokensForUser);
    }

    /// @dev Bulk claim all rewards for one vault over epochEnd - epochStart epochs (inclusive)
    /// @notice You can't use this function if you've already withdrawn rewards for the epochs
    /// @notice This function is useful if you claim once every X epochs, and want to bulk claim
    /// @param epochStart - From which epoch (included) should you claim?
    /// @param epochEnd - What's the last epoch (included) you want to claim to?
    /// @param vault - Which vault are you claiming
    /// @param tokens - List of tokens to claim
    /// @param user - Who to claim for
    function claimBulkTokensOverMultipleEpochs(uint256 epochStart, uint256 epochEnd, address vault, address[] calldata tokens, address user) external {
        // Go over total tokens to award
        // Then do one bulk transfer of it
        // This is the function you want to use to claim after some time (month or 6 months)
        // This one is without gas refunds, 
        // if you are confident in the fact that you're claiming all the tokens for a vault
        // you may as well use the optimized version to save more gas
        require(epochStart <= epochEnd, "wrong math");
        uint256 tokensLength = tokens.length;
        require(epochEnd < currentEpoch(), "only ended epochs");
        _requireNoDuplicates(tokens);

        // We'll map out amounts to tokens for the bulk transfers
        uint256[] memory amounts = new uint256[](tokensLength);
        for(uint epochId = epochStart; epochId <= epochEnd; ) {
            // Accrue each vault and user for each epoch
            accrueUser(epochId, vault, user);

            // Now that they are accrued, just use the points to estimate reward and send
            uint256 userPoints = points[epochId][vault][user];
            
            // No need for more SLOADs if points are zero
            if(userPoints == 0){
                unchecked { ++epochId; }
                continue;
            }

            // Accrue this contract points
            accrueUser(epochId, vault, address(this)); 
            accrueVault(epochId, vault);

            uint256 vaultTotalPoints = totalPoints[epochId][vault];
            uint256 thisContractVaultPoints = points[epochId][vault][address(this)];

            // We multiply just to avoid rounding

            // Loop over the tokens and see the points here
            for(uint256 i; i < tokensLength; ){
                
                // To be able to use the same ratio for all tokens, we need the pointsWithdrawn to all be 0
                // To allow for this I could loop and check they are all zero, which would allow for further optimization
                require(pointsWithdrawn[epochId][vault][user][tokens[i]] == 0, "already claimed");

                // Use ratio to calculate tokens to send
                uint256 totalAdditionalReward = rewards[epochId][vault][tokens[i]];
                // Which means they claimed all points for that token
                // Can assign because we checked it's 0 above
                pointsWithdrawn[epochId][vault][user][tokens[i]] = userPoints;

                amounts[i] += totalAdditionalReward * userPoints / (vaultTotalPoints - thisContractVaultPoints);

                unchecked { ++i; }
            }

            unchecked { ++epochId; }
        }


        // Go ahead and transfer
        for(uint256 i; i < tokensLength; ){
            emit BulkClaimReward(epochStart, epochEnd, vault, tokens[i], amounts[i], user);


            IERC20(tokens[i]).safeTransfer(user, amounts[i]);

            unchecked { ++i; }
        }
    }

    /// === ADD REWARDS === ///

    /// @dev Given start and epochEnd, add an equal split of amount of token for the given vault
    /// @notice Use this to save gas and do a linear distribution over multiple epochs
    ///     E.g. for Liquidity Mining or to incentivize liquidity / rent it
    /// @notice Will not work with feeOnTransferTokens, use the addReward function for those
    /// @param epochStart - From which epoch (included) do you wanna add reward to
    /// @param epochEnd - What's the last epoch (included) you want to add rewards to
    /// @param vault - Which vault are you claiming
    /// @param token - Token you want to add as reward
    /// @param total - Total amount to send, must be divisible by `totalEpochs`
    ///     `total` / `totalEpochs` = amount for each epoch 
    function addBulkRewardsLinearly(uint256 epochStart, uint256 epochEnd, address vault, address token, uint256 total) external nonReentrant {
        require(epochStart >= currentEpoch(), "Cannot add to past");
        require(epochEnd >= epochStart, "Must add at least one epoch");
        require(vault != address(0), "youtu.be/F3L376eH09Q");
        uint256 totalEpochs;
        unchecked {
            totalEpochs = epochEnd - epochStart + 1;
        }
        // Amount needs to be equally divisible per epoch, for custom additions, use this and then add more single rewards
        require(total % totalEpochs == 0, "must divide evenly");
        uint256 perEpoch = total / totalEpochs;

        // Transfer Token in, must receive the exact total
        uint256 startBalance = IERC20(token).balanceOf(address(this));  
        IERC20(token).safeTransferFrom(msg.sender, address(this), total);
        uint256 endBalance = IERC20(token).balanceOf(address(this));

        require(endBalance - startBalance == total, "no feeOnTransfer");

        // Give each epoch an equal amount of reward
        for(uint256 epochId = epochStart; epochId <= epochEnd; ) {
            
            emit AddReward(epochId, vault, token, perEpoch, msg.sender);
            
            unchecked {
                rewards[epochId][vault][token] += perEpoch;
            }

            unchecked { 
                ++epochId;
            }
        }
    }

    /// @dev Given start and epochEnd, add the token amounts of rewards for the interval specified
    /// @notice Use this to save gas and do a custom distribution over multiple epochs
    ///     E.g. for Liquidity Mining where there's a curve (less rewards over time)
    /// @notice Will not work with feeOnTransferTokens, use the addReward function for those
    /// @param epochStart - From which epoch (included) do you wanna add reward to
    /// @param epochEnd - What's the last epoch (included) you want to add rewards to
    /// @param vault - Which vault are you claiming
    /// @param token - Token you want to add as reward
    /// @param amounts - Amounts, for each epoch to be added
    function addBulkRewards(uint256 epochStart, uint256 epochEnd, address vault, address token, uint256[] calldata amounts) external nonReentrant {
        require(epochStart >= currentEpoch(), "Cannot add to past");
        require(epochEnd >= epochStart, "Must add one epoch");
        require(vault != address(0), "youtu.be/F3L376eH09Q");
        uint256 totalEpochs;
        unchecked {
            totalEpochs = epochEnd - epochStart + 1;
        }
        require(totalEpochs == amounts.length, "length mismatch");

        // Calculate total for one-off transfer
        uint256 total;
        for(uint256 i; i < totalEpochs; ) {
            // NOTE: Cannot have unchecked as overflow can be used to add rewards for free - QSP-1
            total += amounts[i];
            ++i;
        }

        // Transfer Token in, must receive the exact total
        uint256 startBalance = IERC20(token).balanceOf(address(this));  
        IERC20(token).safeTransferFrom(msg.sender, address(this), total);
        uint256 endBalance = IERC20(token).balanceOf(address(this));

        require(endBalance - startBalance == total, "no feeOnTransfer");

        // Add specific amount for each epoch
        for(uint256 epochId = epochStart; epochId <= epochEnd; ) {

            uint256 currentAmount = amounts[epochId - epochStart];

            emit AddReward(epochId, vault, token, currentAmount, msg.sender);

            unchecked {
                rewards[epochId][vault][token] += currentAmount;
            }

            unchecked { 
                ++epochId;
            }
        }
    }

    /// @notice Add an additional reward for the current epoch
    /// @notice No particular rationale as to why we wouldn't allow to send rewards for older epochs or future epochs
    /// @notice The typical use case is for this contract to receive certain rewards that would be sent to the badgerTree
    /// @notice nonReentrant because tokens could inflate rewards, this would only apply to the specific token, see reports for more
    /// @param epochId - Epoch for which to add the reward
    /// @param vault - Which vault are you adding a reward to
    /// @param token - Which token are you adding as reward
    /// @param amount - How much of the token to add
    function addReward(uint256 epochId, address vault, address token, uint256 amount) external nonReentrant {
        require(epochId >= currentEpoch(), "Cannot add to past");
        require(vault != address(0), "youtu.be/F3L376eH09Q");

        // Check change in balance to support `feeOnTransfer` tokens as well
        uint256 startBalance = IERC20(token).balanceOf(address(this));  
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        uint256 endBalance = IERC20(token).balanceOf(address(this));

        // Allow underflow in case of malicious token
        uint256 diff = endBalance - startBalance;

        unchecked {
            rewards[epochId][vault][token] += diff;
        }

        emit AddReward(epochId, vault, token, diff, msg.sender);
    }

    /// === UTILS === ///

    /// @dev Checks that there's no duplicate addresses
    /// @param arr - List to check for dups
    function _requireNoDuplicates(address[] memory arr) internal pure {
        uint256 arrLength = arr.length;
        // only up to len - 1 (no j to check if i == len - 1)
        for(uint i; i < arrLength - 1; ) {
            for (uint j = i + 1; j < arrLength; ) {
                require(arr[i] != arr[j], "dup");

                unchecked { ++j; }
            }

            unchecked { ++i; }
        }
    }

    /// @dev Math utility to obtain the minimum out of two numbers
    /// @param a - not b
    /// @param b - not a
    /// @return uint256 - Minimum number out of two inputs
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    /// ==== GAS OPTIMIZED BULK CLAIMS === ////

    /// NOTE: Non storage writing functions
    /// With the goal of making view functions cheap
    /// And to make optimized claiming way cheaper
    /// Intuition: On optimized version we delete storage
    /// This means the values are not useful after we've used them
    /// So let's skip writing to storage all together, use memory and skip any SSTORE, saving 5k / 20k per epoch per claim


    /// NOTE: These functions are based on the assumption that epochs are ended
    /// They are meant to optimize claiming
    /// For this reason extreme attention needs to be put into verifying that the epochs used have ended
    /// If it's not massive gas we may just check that `epochId` < `currentEpoch` but for now we can just assume and then we'll test


    /// NOTE: While the functions are public, only the uses that are internal will make sense, for that reason
    /// DO NOT USE THESE FUNCTIONS FOR INTEGRATIONS, YOU WILL GET REKT
    /// These functions should be private, but I need to test them right now.


    /// === Optimized functions === ////
    /// Invariant -> Epoch has ended
    /// Invariant -> Never changed means full duration & Balance is previously known
    /// 2 options. 
        /// Never accrued -> Use SECONDS_PER_EPOCH and prevBalance
        /// We did accrue -> Read Storage


    /// @dev Get the balance and timeLeft so you can calculate points for a user
    /// @return balance - The balance of the user in this epoch
    /// @return timeLeftToAccrue - How much time in the epoch left to accrue (userPoints + balance * timeLeftToAccrue == totalPoints)
    /// @return userEpochTotalPoints - The totalPoints for a user, getting them from here will save gas
    /// @return pointsInStorage - The total amount of points in storage for a given user
    struct UserInfo {
        uint256 balance;
        uint256 timeLeftToAccrue;
        uint256 userEpochTotalPoints; 
        uint256 pointsInStorage;
    }

    /// @dev See `_getUserNextEpochInfo`
    function getUserNextEpochInfo(uint256 epochId, address vault, address user, uint256 prevEpochBalance) external view returns (UserInfo memory info) {
        require(epochId < currentEpoch(), "only ended epochs");
        return _getUserNextEpochInfo(epochId, vault, user, prevEpochBalance);
    }


    /// @dev Return the userEpochInfo for the given epochId, vault, user
    /// @notice Requires `prevEpochBalance` to allow optimized claims
    ///     If an accrual happened during `epochId` it will read data from storage (expensive)
    ///     If no accrual happened (optimistic case), it will use `prevEpochBalance` to compute the rest of the values
    /// @param epochId - epoch for which to get info
    /// @param vault - address that indexes the info
    /// @param user - address for which to get the info of
    /// @param prevEpochBalance - previous known balance, to save gas
    /// @return info - see {UserInfo}
    function _getUserNextEpochInfo(uint256 epochId, address vault, address user, uint256 prevEpochBalance) internal view returns (UserInfo memory info) {
        // Ideal scenario is no accrue, no balance change so that we can calculate all from memory without checking storage

        // Time left to Accrue //
        uint256 lastBalanceChangeTime = lastUserAccrueTimestamp[epochId][vault][user];
        if(lastBalanceChangeTime == 0) {
            info.timeLeftToAccrue = SECONDS_PER_EPOCH;
        } else {
            // NOTE: If we do else if we gotta load the struct into memory
            // because we optimize for the best case, I believe it's best not to use else if here
            // If you got math to prove otherwise please share: [email protected]

            // An accrual for the epoch has happened
            Epoch memory epochData = getEpochData(epochId);

            // Already accrued after epoch end
            if(lastBalanceChangeTime >= epochData.endTimestamp){
                // timeLeftToAccrue = 0; // No need to set
            } else {
                unchecked {
                    info.timeLeftToAccrue = _min(epochData.endTimestamp - lastBalanceChangeTime, SECONDS_PER_EPOCH);
                }
            }
        }

        // Balance //
        if(lastBalanceChangeTime == 0) {
            info.balance = prevEpochBalance;
        } else {
            info.balance = shares[epochId][vault][user];
        }

        // Points //

        // Never accrued means points in storage are 0
        if(lastBalanceChangeTime == 0) {
            // Just multiply from scratch
            unchecked {
                info.userEpochTotalPoints = info.balance * info.timeLeftToAccrue;
            }
        } else {
            // We have accrued, return the sum of points from storage and the points that are not accrued
            info.pointsInStorage = points[epochId][vault][user];
            unchecked {
                info.userEpochTotalPoints = info.pointsInStorage + info.balance * info.timeLeftToAccrue;
            }
        }
    }


    /// @dev Get the totalSupply and timeLeft so you can calculate points for a vault
    /// @return vaultTotalSupply - The totalSupply of the user in this epoch
    /// @return timeLeftToAccrue - How much time in the epoch left to accrue (vaultPoints + vaultTotalSupply * timeLeftToAccrue == totalPoints)
    /// @return vaultEpochTotalPoints - The totalPoints for a vault, getting them from here will save gas
    /// @return pointsInStorage - The total amount of points in storage for a given vault
    struct VaultInfo {
        uint256 vaultTotalSupply;
        uint256 timeLeftToAccrue;
        uint256 vaultEpochTotalPoints;
        uint256 pointsInStorage;
    }


    /// @dev See `_getVaultNextEpochInfo`
    function getVaultNextEpochInfo(uint256 epochId, address vault, uint256 prevEpochTotalSupply) external view returns (VaultInfo memory info) {
        require(epochId < currentEpoch(), "only ended epochs");
        return _getVaultNextEpochInfo(epochId, vault, prevEpochTotalSupply);
    }


    /// @dev Return the VaultInfo for the given epochId, vault
    /// @notice Requires `prevEpochTotalSupply` to allow optimized math in case of non-accrual
    ///     If an accrual happened during `epochId` it will read data from storage (expensive)
    ///     If no accrual happened (optimistic case), it will use `prevEpochTotalSupply` to compute the rest of the values
    /// @param epochId - epochId for which to get the info
    /// @param vault - address of which you want the info of
    /// @param prevEpochTotalSupply - previously known total supply, to save gas
    /// @return info - see {VaultInfo}
    function _getVaultNextEpochInfo(uint256 epochId, address vault, uint256 prevEpochTotalSupply) internal view returns (VaultInfo memory info) {
        
        // Time left to Accrue //
        uint256 lastAccrueTime = lastAccruedTimestamp[epochId][vault];
        if(lastAccrueTime == 0) {
            info.timeLeftToAccrue = SECONDS_PER_EPOCH;
        } else {
            // NOTE: If we do else if we gotta load the struct into memory
            // because we optimize for the best case, I believe it's best not to use else if here
            // If you got math to prove otherwise please share: [email protected]
            
            // An accrual for the epoch has happened
            Epoch memory epochData = getEpochData(epochId);

            // Already accrued after epoch end
            if(lastAccrueTime >= epochData.endTimestamp) {
                // timeLeftToAccrue = 0;
            } else {
                unchecked {
                    info.timeLeftToAccrue = _min(epochData.endTimestamp - lastAccrueTime, SECONDS_PER_EPOCH);
                }
            }
        }

        if(lastAccrueTime == 0) {
            info.vaultTotalSupply = prevEpochTotalSupply;
        } else {
            info.vaultTotalSupply = totalSupply[epochId][vault];
        }


        if(lastAccrueTime == 0) {
        // Just multiply from scratch || Cannot use unchecked to avoid overflow - QSP-5
            info.vaultEpochTotalPoints = info.vaultTotalSupply * info.timeLeftToAccrue;
            // pointsInStorage = 0;
        } else {
            // We have accrued, return the sum of points from storage and the points that are not accrued
            info.pointsInStorage = totalPoints[epochId][vault];
            // Cannot use unchecked to avoid overflow - QSP-5
            info.vaultEpochTotalPoints = info.pointsInStorage + info.vaultTotalSupply * info.timeLeftToAccrue;
        }
    }

    /// @dev Parameters to claim a bulk of tokens for a given vault through the `reap` and `tear` destructive methods
    /// @return epochStart - Start timestamp of the epoch in matter
    /// @return epochEnd - End timestamp of the epoch in matter
    /// @return vault - The address of the vault to claim rewards from
    /// @return tokens - An array of the reward tokens to be claimed 
    struct OptimizedClaimParams {
        uint256 epochStart;
        uint256 epochEnd;
        address vault;
        address[] tokens;
    }

    /// @dev Given the Claim Values, perform bulk claims over multiple epochs, minimizing SSTOREs to save gas
    /// @notice This is a DESTRUCTIVE claim, your onChain data will be deleted to make the claim cheaper
    /// @notice Use this function if the vault emits-itself, otherwise use `tear`
    /// @notice Benchmarked to cost about 1.5M gas for 1 year, 5 tokens claimed for 1 vault
    /// @notice Benchmarked to cost about 670k gas for 1 year, 1 token claimed for 1 vault
    /// @param params see {OptimizedClaimParams}
    function reap(OptimizedClaimParams calldata params) external {
        require(params.epochStart <= params.epochEnd, "wrong math");
        address user = msg.sender; // Pay the extra 3 gas to make code reusable, not sorry
        require(params.epochEnd < currentEpoch(), "only ended epochs");
        _requireNoDuplicates(params.tokens);

        // Instead of accruing user and vault, we just compute the values in the loop
        // We can use those value for reward distribution
        // We must update the storage that we don't delete to ensure that user can only claim once
        // This is equivalent to deleting the user storage

        (uint256 userBalanceAtEpochId, ) = _getBalanceAtEpoch(params.epochStart, params.vault, user);
        (uint256 vaultSupplyAtEpochId, ) = _getTotalSupplyAtEpoch(params.epochStart, params.vault);
        (uint256 startingContractBalance, ) = _getBalanceAtEpoch(params.epochStart, params.vault, address(this));

        uint256 tokensLength = params.tokens.length;
        // We'll map out amounts to tokens for the bulk transfers
        uint256[] memory amounts = new uint256[](tokensLength);
    
        for(uint epochId = params.epochStart; epochId <= params.epochEnd;) {

            // For all epochs from start to end, get user info
            UserInfo memory userInfo = _getUserNextEpochInfo(epochId, params.vault, user, userBalanceAtEpochId);
            VaultInfo memory vaultInfo = _getVaultNextEpochInfo(epochId, params.vault, vaultSupplyAtEpochId);
            UserInfo memory thisContractInfo = _getUserNextEpochInfo(epochId, params.vault, address(this), startingContractBalance);

            // If userPoints are zero, go next fast
            if (userInfo.userEpochTotalPoints == 0) {
                // NOTE: By definition user points being zero means storage points are also zero
                userBalanceAtEpochId = userInfo.balance;
                vaultSupplyAtEpochId = vaultInfo.vaultTotalSupply;
                startingContractBalance = thisContractInfo.balance;

                unchecked { ++epochId; }
                continue;
            }

            // Use the info to get userPoints and vaultPoints
            if (userInfo.pointsInStorage > 0) {
                // Delete them as they need to be set to 0 to avoid double claiming
                delete points[epochId][params.vault][user];
            }

        
            // Use points to calculate amount of rewards
            for(uint256 i; i < tokensLength; ){
                address token = params.tokens[i];

                // To be able to use the same ratio for all tokens, we need the pointsWithdrawn to all be 0
                require(pointsWithdrawn[epochId][params.vault][user][token] == 0, "already claimed");
                
                // Use ratio to calculate tokens to send
                uint256 totalAdditionalReward = rewards[epochId][params.vault][token];

                amounts[i] += totalAdditionalReward * userInfo.userEpochTotalPoints / (vaultInfo.vaultEpochTotalPoints - thisContractInfo.userEpochTotalPoints);

                unchecked { ++i; }
            }


            // End of iteration, assign new balances for next loop
            unchecked {
                userBalanceAtEpochId = userInfo.balance;
                vaultSupplyAtEpochId = vaultInfo.vaultTotalSupply;
                startingContractBalance = thisContractInfo.balance;
            }

            unchecked { ++epochId; }
        }

        // == Storage Changes == //
        // No risk of overflow but seems to save 26 gas
        unchecked {
            // Delete the points for that epoch so nothing more to claim
            // This may be zero and may have already been deleted
            delete points[params.epochEnd][params.vault][user];

            // Because we set the accrue timestamp to end of the epoch
            // Must set this so user can't claim and their balance here is non-zero / last known
            lastUserAccrueTimestamp[params.epochEnd][params.vault][user] = block.timestamp; 
            
            // And we delete the initial balance meaning they have no balance left
            delete shares[params.epochStart][params.vault][user];
            lastUserAccrueTimestamp[params.epochStart][params.vault][user] = block.timestamp;

            // Port over shares from last check || NOTE: Port over last to mitigate QSP-2
            shares[params.epochEnd][params.vault][user] = userBalanceAtEpochId; 
        }

        // Go ahead and transfer
        {

            for(uint256 i; i < tokensLength; ){
                emit BulkClaimReward(params.epochStart, params.epochEnd, params.vault, params.tokens[i], amounts[i], user);

                IERC20(params.tokens[i]).safeTransfer(user, amounts[i]);

                unchecked { ++i; }
            }
        }
    }

    /// @dev Given the Claim Values, perform bulk claims over multiple epochs, minimizing SSTOREs to save gas
    /// @notice This is a DESTRUCTIVE claim, your onChain data will be deleted to make the claim cheaper
    /// @notice This function assume that the tokens will not be self-emitting vaults, saving you gas
    ///     use `reap` if if you need to claim from a vault that emits itself
    /// @notice Benchmarked to cost about 1.3M gas for 1 year, 5 tokens claimed for 1 vault
    /// @notice Benchmarked to cost about 532k gas for 1 year, 1 token claimed for 1 vault
    /// @param params see {OptimizedClaimParams}
    function tear(OptimizedClaimParams calldata params) external {
        require(params.epochStart <= params.epochEnd, "wrong math");
        address user = msg.sender; // Pay the extra 3 gas to make code reusable, not sorry
        require(params.epochEnd < currentEpoch(), "only ended epochs");
        _requireNoDuplicates(params.tokens);

        // Instead of accruing user and vault, we just compute the values in the loop
        // We can use those value for reward distribution
        // We must update the storage that we don't delete to ensure that user can only claim once
        // This is equivalent to deleting the user storage

        (uint256 userBalanceAtEpochId, ) = _getBalanceAtEpoch(params.epochStart, params.vault, user);
        (uint256 vaultSupplyAtEpochId, ) = _getTotalSupplyAtEpoch(params.epochStart, params.vault);

        // Cache tokens length, resused in loop and at end for transfer || Saves almost 1k gas over a year of claims
        uint256 tokensLength = params.tokens.length;

        // We'll map out amounts to tokens for the bulk transfers
        uint256[] memory amounts = new uint256[](tokensLength);
    
        for(uint epochId = params.epochStart; epochId <= params.epochEnd;) {

            // For all epochs from start to end, get user info
            UserInfo memory userInfo = _getUserNextEpochInfo(epochId, params.vault, user, userBalanceAtEpochId);
            VaultInfo memory vaultInfo = _getVaultNextEpochInfo(epochId, params.vault, vaultSupplyAtEpochId);

            // If userPoints are zero, go next fast
            if (userInfo.userEpochTotalPoints == 0) {
                // NOTE: By definition user points being zero means storage points are also zero
                userBalanceAtEpochId = userInfo.balance;
                vaultSupplyAtEpochId = vaultInfo.vaultTotalSupply;

                unchecked { ++epochId; }
                continue;
            }

            // Use the info to get userPoints and vaultPoints
            if (userInfo.pointsInStorage > 0) {
                // Delete them as they need to be set to 0 to avoid double claiming
                delete points[epochId][params.vault][user]; 
            }

        
            // Use points to calculate amount of rewards
            for(uint256 i; i < tokensLength; ){
                address token = params.tokens[i];

                // To be able to use the same ratio for all tokens, we need the pointsWithdrawn to all be 0
                require(pointsWithdrawn[epochId][params.vault][user][token] == 0, "already claimed");

                // Use ratio to calculate tokens to send
                uint256 totalAdditionalReward = rewards[epochId][params.vault][token];

                
                unchecked { 
                    // vaultEpochTotalPoints can't be zero if userEpochTotalPoints is > zero
                    amounts[i] += totalAdditionalReward * userInfo.userEpochTotalPoints / vaultInfo.vaultEpochTotalPoints;
                    ++i; 
                }
            }


            // End of iteration, assign new balances for next loop
            unchecked {
                // Seems to save 26 gas
                userBalanceAtEpochId = userInfo.balance;
                vaultSupplyAtEpochId = vaultInfo.vaultTotalSupply;
            }

            unchecked { ++epochId; }
        }

        // == Storage Changes == //
        // No risk of overflow but seems to save 26 gas
        unchecked {

            // Delete the points for that epoch so nothing more to claim
            // This may be zero and may have already been deleted
            delete points[params.epochEnd][params.vault][user]; 

            // Because we set the accrue timestamp to end of the epoch
            // Must set this so user can't claim and their balance here is non-zero / last known
            lastUserAccrueTimestamp[params.epochEnd][params.vault][user] = block.timestamp; 
            
            // And we delete the initial balance meaning they have no balance left
            delete shares[params.epochStart][params.vault][user];
            lastUserAccrueTimestamp[params.epochStart][params.vault][user] = block.timestamp;

            // Port over shares from last check || NOTE: Port over last to mitigate QSP-2
            shares[params.epochEnd][params.vault][user] = userBalanceAtEpochId;
        }

        // Go ahead and transfer
        {

            for(uint256 i; i < tokensLength; ){
                emit BulkClaimReward(params.epochStart, params.epochEnd, params.vault, params.tokens[i], amounts[i], user);
                
                IERC20(params.tokens[i]).safeTransfer(user, amounts[i]);
                
                unchecked { ++i; }
            }
        }
    }

    
    /// ===== LENS ==== ////

    /// @dev Given OptimizedClaimParams return a list of amounts claimable in bulk, ordered by the tokens
    /// @param params see {OptimizedClaimParams}
    /// @param user Address to run the check for
    /// @return amounts - List of all amounts based on the params
    function getClaimableBulkRewards(OptimizedClaimParams calldata params, address user) external view returns (uint256[] memory amounts) {
        require(params.epochStart <= params.epochEnd, "wrong math");
        require(params.epochEnd < currentEpoch(), "only ended epochs");
        _requireNoDuplicates(params.tokens);

        // Get initial balances
        (uint256 userBalanceAtEpochId, ) = _getBalanceAtEpoch(params.epochStart, params.vault, user);
        (uint256 vaultSupplyAtEpochId, ) = _getTotalSupplyAtEpoch(params.epochStart, params.vault);
        (uint256 startingContractBalance, ) = _getBalanceAtEpoch(params.epochStart, params.vault, address(this));

        uint256 tokensLength = params.tokens.length;
        // We'll map out amounts to tokens for the bulk transfers
        amounts = new uint256[](tokensLength); 

        for(uint epochId = params.epochStart; epochId <= params.epochEnd;) {

            // For all epochs from start to end, get user info
            UserInfo memory userInfo = _getUserNextEpochInfo(epochId, params.vault, user, userBalanceAtEpochId);
            VaultInfo memory vaultInfo = _getVaultNextEpochInfo(epochId, params.vault, vaultSupplyAtEpochId);
            UserInfo memory thisContractInfo = _getUserNextEpochInfo(epochId, params.vault, address(this), startingContractBalance);

            // If userPoints are zero, go next fast
            if (userInfo.userEpochTotalPoints == 0) {
                // NOTE: By definition user points being zero means storage points are also zero
                userBalanceAtEpochId = userInfo.balance;
                vaultSupplyAtEpochId = vaultInfo.vaultTotalSupply;
                startingContractBalance = thisContractInfo.balance;

                unchecked { ++epochId; }
                continue;
            }

        
            // Use points to calculate amount of rewards
            for(uint256 i; i < tokensLength; ){
                address token = params.tokens[i];

                // To be able to use the same ratio for all tokens, we need the pointsWithdrawn to all be 0
                require(pointsWithdrawn[epochId][params.vault][user][token] == 0, "already claimed");

                // Use ratio to calculate tokens to send
                uint256 totalAdditionalReward = rewards[epochId][params.vault][token];
        
                amounts[i] += totalAdditionalReward * userInfo.userEpochTotalPoints / (vaultInfo.vaultEpochTotalPoints - thisContractInfo.userEpochTotalPoints);
                unchecked { ++i; }
            }


            // End of iteration, assign new balances for next loop
            unchecked {
                userBalanceAtEpochId = userInfo.balance;
                vaultSupplyAtEpochId = vaultInfo.vaultTotalSupply;
                startingContractBalance = thisContractInfo.balance;
            }

            unchecked { ++epochId; }
        }



        return amounts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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