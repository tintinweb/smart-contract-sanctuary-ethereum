// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../concentrator/interfaces/IAladdinCompounder.sol";
import "../../concentrator/interfaces/IConcentratorGeneralVault.sol";

import "../libraries/LibConcentratorHarvester.sol";

// solhint-disable not-rely-on-time

contract ConcentratorHarvesterFacet {
  /// @notice Return the minimum amount CTR should be locked.
  function minLockCTR() external view returns (uint256) {
    return LibConcentratorHarvester.harvesterStorage().minLockCTR;
  }

  /// @notice Return the minimum number of seconds that veCTR should be locked.
  function minLockDuration() external view returns (uint256) {
    return LibConcentratorHarvester.harvesterStorage().minLockDuration;
  }

  /// @notice Return whether the account is whitelisted.
  /// @param _account The address of account to query.
  function isWhitelist(address _account) external view returns (bool) {
    LibConcentratorHarvester.HarvesterStorage storage hs = LibConcentratorHarvester.harvesterStorage();
    return hs.whitelist[_account];
  }

  /// @notice Return whether the account is blacklisted.
  /// @param _account The address of account to query.
  function isBlacklist(address _account) external view returns (bool) {
    LibConcentratorHarvester.HarvesterStorage storage hs = LibConcentratorHarvester.harvesterStorage();
    return hs.blacklist[_account];
  }

  /// @notice Return whether the account can do harvest.
  /// @param _account The address of account to query.
  function hasPermission(address _account) external view returns (bool) {
    ICurveVoteEscrow.LockedBalance memory _locked = ICurveVoteEscrow(LibConcentratorHarvester.veCTR).locked(_account);
    LibConcentratorHarvester.HarvesterStorage storage hs = LibConcentratorHarvester.harvesterStorage();

    // check whether is blacklisted
    if (hs.blacklist[_account]) return false;

    // check whether is whitelisted
    if (hs.whitelist[_account] || hs.minLockCTR == 0) return true;

    // check veCTR locking
    return uint128(_locked.amount) >= hs.minLockCTR && _locked.end >= hs.minLockDuration + block.timestamp;
  }

  /// @notice Harvest pending rewards from concentrator vault.
  /// @param _vault The address of concentrator vault contract.
  /// @param _pid The pool id to harvest.
  /// @param _minOut The minimum amount of rewards should get.
  function harvestConcentratorVault(
    address _vault,
    uint256 _pid,
    uint256 _minOut
  ) external {
    LibConcentratorHarvester.enforceHasPermission();

    IConcentratorGeneralVault(_vault).harvest(_pid, msg.sender, _minOut);
  }

  /// @notice Harvest pending rewards from AladdinCompounder contract.
  /// @param _compounder The address of AladdinCompounder contract.
  /// @param _minAssets The minimum amount of underlying assets should be harvested.
  function harvestConcentratorCompounder(address _compounder, uint256 _minAssets) external {
    LibConcentratorHarvester.enforceHasPermission();

    IAladdinCompounder(_compounder).harvest(msg.sender, _minAssets);
  }

  /// @notice Update the harvester permission parameters.
  /// @param _minLockCTR The minimum amount CTR should be locked.
  /// @param _minLockDuration The minimum number of seconds that veCTR should be locked.
  function updatePermission(uint128 _minLockCTR, uint128 _minLockDuration) external {
    LibConcentratorHarvester.enforceIsContractOwner();
    LibConcentratorHarvester.updatePermission(_minLockCTR, _minLockDuration);
  }

  /// @notice Update the whitelist status of account.
  /// @param _account The address to update.
  /// @param _status The status to update.
  function updateWhitelist(address _account, bool _status) external {
    LibConcentratorHarvester.enforceIsContractOwner();
    LibConcentratorHarvester.updateWhitelist(_account, _status);
  }

  /// @notice Update the blacklist status of account.
  /// @param _account The address to update.
  /// @param _status The status to update.
  function updateBlacklist(address _account, bool _status) external {
    LibConcentratorHarvester.enforceIsContractOwner();
    LibConcentratorHarvester.updateBlacklist(_account, _status);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "../../interfaces/ICurveVoteEscrow.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

library LibConcentratorHarvester {
  /*************
   * Constants *
   *************/

  /// @dev The storage slot for default diamond storage.
  bytes32 private constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  /// @dev The storage slot for harvester storage.
  bytes32 private constant HARVESTER_STORAGE_POSITION = keccak256("diamond.harvester.concentrator.storage");

  /// @dev The address of veCTR contract.
  address internal constant veCTR = 0xe4C09928d834cd58D233CD77B5af3545484B4968;

  /***********
   * Structs *
   ***********/

  struct FacetAddressAndSelectorPosition {
    address facetAddress;
    uint16 selectorPosition;
  }

  struct DiamondStorage {
    // function selector => facet address and selector position in selectors array
    mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
    bytes4[] selectors;
    mapping(bytes4 => bool) supportedInterfaces;
    // owner of the contract
    address contractOwner;
  }

  struct HarvesterStorage {
    uint128 minLockCTR;
    uint128 minLockDuration;
    mapping(address => bool) whitelist;
    mapping(address => bool) blacklist;
  }

  /**********************
   * Internal Functions *
   **********************/

  function diamondStorage() private pure returns (DiamondStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function harvesterStorage() internal pure returns (HarvesterStorage storage hs) {
    bytes32 position = HARVESTER_STORAGE_POSITION;
    assembly {
      hs.slot := position
    }
  }

  function updatePermission(uint128 _minLockCTR, uint128 _minLockDuration) internal {
    HarvesterStorage storage hs = harvesterStorage();

    hs.minLockCTR = _minLockCTR;
    hs.minLockDuration = _minLockDuration;
  }

  function updateWhitelist(address _account, bool _status) internal {
    HarvesterStorage storage hs = harvesterStorage();

    hs.whitelist[_account] = _status;
  }

  function updateBlacklist(address _account, bool _status) internal {
    HarvesterStorage storage hs = harvesterStorage();

    hs.blacklist[_account] = _status;
  }

  function enforceIsContractOwner() internal view {
    require(msg.sender == diamondStorage().contractOwner, "only owner");
  }

  function enforceHasPermission() internal view {
    ICurveVoteEscrow.LockedBalance memory _locked = ICurveVoteEscrow(veCTR).locked(msg.sender);
    HarvesterStorage storage hs = harvesterStorage();

    // check whether is blacklisted
    require(!hs.blacklist[msg.sender], "account blacklisted");

    // check whether is whitelisted
    if (hs.whitelist[msg.sender] || hs.minLockCTR == 0) return;

    // check veCTR locking
    require(uint128(_locked.amount) >= hs.minLockCTR, "insufficient lock amount");
    require(_locked.end >= hs.minLockDuration + block.timestamp, "insufficient lock duration");
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IConcentratorGeneralVault {
  /// @notice Emitted when someone change allowance.
  /// @param pid The pool id.
  /// @param owner The address of the owner.
  /// @param spender The address of the spender.
  /// @param value The new value of allowance.
  event Approval(uint256 indexed pid, address indexed owner, address indexed spender, uint256 value);

  /// @notice Emitted when someone deposits asset into this contract.
  /// @param pid The pool id.
  /// @param sender The address who sends underlying asset.
  /// @param recipient The address who will receive the pool shares.
  /// @param assetsIn The amount of asset deposited.
  /// @param sharesOut The amounf of pool shares received.
  event Deposit(
    uint256 indexed pid,
    address indexed sender,
    address indexed recipient,
    uint256 assetsIn,
    uint256 sharesOut
  );

  /// @notice Emitted when someone withdraws asset from this contract.
  /// @param pid The pool id.
  /// @param sender The address who call the function.
  /// @param owner The address who owns the assets.
  /// @param recipient The address who will receive the assets.
  /// @param assetsOut The amount of asset withdrawn.
  /// @param sharesIn The amounf of pool shares to withdraw.
  event Withdraw(
    uint256 indexed pid,
    address indexed sender,
    address indexed owner,
    address recipient,
    uint256 sharesIn,
    uint256 assetsOut
  );

  /// @notice Emitted when someone claim rewards from this contract.
  /// @param pid The pool id.
  /// @param sender The address who call the function.
  /// @param recipient The address who will receive the rewards;
  /// @param rewards The amount of reward received.
  event Claim(uint256 indexed pid, address indexed sender, address indexed recipient, uint256 rewards);

  /// @notice Emitted when someone harvests rewards.
  /// @param pid The pool id.
  /// @param caller The address who call the function.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param rewards The total amount of rewards harvested.
  /// @param platformFee The amount of harvested assets as platform fee.
  /// @param harvestBounty The amount of harvested assets as harvest bounty.
  event Harvest(
    uint256 indexed pid,
    address indexed caller,
    address indexed recipient,
    uint256 rewards,
    uint256 platformFee,
    uint256 harvestBounty
  );

  /// @notice The address of reward token.
  function rewardToken() external view returns (address);

  /// @notice Return the amount of pending rewards for specific pool.
  /// @param pid The pool id.
  /// @param account The address of user.
  function pendingReward(uint256 pid, address account) external view returns (uint256);

  /// @notice Return the amount of pending AladdinCRV rewards for all pool.
  /// @param account The address of user.
  function pendingRewardAll(address account) external view returns (uint256);

  /// @notice Return the user share for specific user.
  /// @param pid The pool id to query.
  /// @param account The address of user.
  function getUserShare(uint256 pid, address account) external view returns (uint256);

  /// @notice Return the address of underlying token.
  /// @param pid The pool id to query.
  function underlying(uint256 pid) external view returns (address);

  /// @notice Return the total underlying token deposited.
  /// @param pid The pool id to query.
  function getTotalUnderlying(uint256 pid) external view returns (uint256);

  /// @notice Return the total pool share deposited.
  /// @param pid The pool id to query.
  function getTotalShare(uint256 pid) external view returns (uint256);

  /// @notice Returns the remaining number of shares that `spender` will be allowed to spend on behalf of `owner`.
  /// @param pid The pool id to query.
  /// @param owner The address of the owner.
  /// @param spender The address of the spender.
  function allowance(
    uint256 pid,
    address owner,
    address spender
  ) external view returns (uint256);

  /// @notice Sets `amount` as the allowance of `spender` over the caller's share.
  /// @param pid The pool id to query.
  /// @param spender The address of the spender.
  /// @param amount The amount of allowance.
  function approve(
    uint256 pid,
    address spender,
    uint256 amount
  ) external;

  /// @notice Deposit some token to specific pool for someone.
  /// @param pid The pool id.
  /// @param recipient The address of recipient who will recieve the token.
  /// @param assets The amount of token to deposit. -1 means deposit all.
  /// @return share The amount of share after deposit.
  function deposit(
    uint256 pid,
    address recipient,
    uint256 assets
  ) external returns (uint256 share);

  /// @notice Withdraw some token from specific pool and zap to token.
  /// @param pid The pool id.
  /// @param shares The share of token want to withdraw. -1 means withdraw all.
  /// @param recipient The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return assets The amount of token sent to recipient.
  function withdraw(
    uint256 pid,
    uint256 shares,
    address recipient,
    address owner
  ) external returns (uint256 assets);

  /// @notice claim pending rewards from specific pool.
  /// @param pid The pool id.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claim(
    uint256 pid,
    address recipient,
    uint256 minOut,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice claim pending rewards from multiple pools.
  /// @param pids The list of pool id to claim.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claimMulti(
    uint256[] memory pids,
    address recipient,
    uint256 minOut,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice claim pending rewards from all pools.
  /// @param recipient The address of account who will receive the rewards.
  /// @param minOut The minimum amount of pending reward to receive.
  /// @param claimAsToken The address of token to claim as. Use address(0) if claim as ETH
  /// @return claimed The amount of reward sent to the recipient.
  function claimAll(
    uint256 minOut,
    address recipient,
    address claimAsToken
  ) external returns (uint256 claimed);

  /// @notice Harvest the pending reward and convert to aCRV.
  /// @param pid The pool id.
  /// @param recipient The address of account to receive harvest bounty.
  /// @param minOut The minimum amount of cvxCRV should get.
  /// @return harvested The amount of cvxCRV harvested after zapping all other tokens to it.
  function harvest(
    uint256 pid,
    address recipient,
    uint256 minOut
  ) external returns (uint256 harvested);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/// @title IAladdinCompounder
/// @notice The interface for AladdinCompounder like aCRV, aFXS, and is also EIP4646 compatible.
interface IAladdinCompounder {
  /// @notice Emitted when someone deposits asset into this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param sender The address who sends underlying asset.
  /// @param owner The address who will receive the pool shares.
  /// @param assets The amount of asset deposited.
  /// @param shares The amounf of pool shares received.
  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

  /// @notice Emitted when someone withdraws asset from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param sender The address who call the function.
  /// @param receiver The address who will receive the assets.
  /// @param owner The address who owns the assets.
  /// @param assets The amount of asset withdrawn.
  /// @param shares The amounf of pool shares to withdraw.
  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  /// @notice Emitted when someone harvests rewards.
  /// @param caller The address who call the function.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param assets The total amount of underlying asset harvested.
  /// @param platformFee The amount of harvested assets as platform fee.
  /// @param harvestBounty The amount of harvested assets as harvest bounty.
  event Harvest(
    address indexed caller,
    address indexed recipient,
    uint256 assets,
    uint256 platformFee,
    uint256 harvestBounty
  );

  /// @notice Return the address of underlying assert.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  function asset() external view returns (address assetTokenAddress);

  /// @notice Return the total amount of underlying assert mananged by the contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  function totalAssets() external view returns (uint256 totalManagedAssets);

  /// @notice Return the amount of pool shares given the amount of asset.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of asset to convert.
  function convertToShares(uint256 assets) external view returns (uint256 shares);

  /// @notice Return the amount of asset given the amount of pool share.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of pool shares to convert.
  function convertToAssets(uint256 shares) external view returns (uint256 assets);

  /// @notice Return the maximum amount of asset that the user can deposit.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param receiver The address of user to receive the pool share.
  function maxDeposit(address receiver) external view returns (uint256 maxAssets);

  /// @notice Return the amount of pool shares will receive, if perform a deposit.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of asset to deposit.
  function previewDeposit(uint256 assets) external view returns (uint256 shares);

  /// @notice Deposit assets into this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of asset to deposit.
  /// @param receiver The address of account who will receive the pool share.
  /// @return shares The amount of pool shares received.
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);

  /// @notice Return the maximum amount of pool shares that the user can mint.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param receiver The address of user to receive the pool share.
  function maxMint(address receiver) external view returns (uint256 maxShares);

  /// @notice Return the amount of assets needed, if perform a mint.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to mint.
  function previewMint(uint256 shares) external view returns (uint256 assets);

  /// @notice Mint pool shares from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to mint.
  /// @param receiver The address of account who will receive the pool share.
  /// @return assets The amount of assets deposited to the contract.
  function mint(uint256 shares, address receiver) external returns (uint256 assets);

  /// @notice Return the maximum amount of assets that the user can withdraw.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param owner The address of user to withdraw from.
  function maxWithdraw(address owner) external view returns (uint256 maxAssets);

  /// @notice Return the amount of shares needed, if perform a withdraw.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of assets to withdraw.
  function previewWithdraw(uint256 assets) external view returns (uint256 shares);

  /// @notice Withdraw assets from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param assets The amount of assets to withdraw.
  /// @param receiver The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return shares The amount of pool shares burned.
  function withdraw(
    uint256 assets,
    address receiver,
    address owner
  ) external returns (uint256 shares);

  /// @notice Return the maximum amount of pool shares that the user can redeem.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param owner The address of user to redeem from.
  function maxRedeem(address owner) external view returns (uint256 maxShares);

  /// @notice Return the amount of assets to be received, if perform a redeem.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to redeem.
  function previewRedeem(uint256 shares) external view returns (uint256 assets);

  /// @notice Redeem assets from this contract.
  /// @dev See https://eips.ethereum.org/EIPS/eip-4626
  /// @param shares The amount of pool shares to burn.
  /// @param receiver The address of account who will receive the assets.
  /// @param owner The address of user to withdraw from.
  /// @return assets The amount of assets withdrawn.
  function redeem(
    uint256 shares,
    address receiver,
    address owner
  ) external returns (uint256 assets);

  /// @notice Harvest rewards and convert to underlying asset.
  /// @param recipient The address of account to recieve the harvest bounty.
  /// @param minAssets The minimum amount of underlying asset harvested.
  /// @return assets The total amount of underlying asset harvested.
  function harvest(address recipient, uint256 minAssets) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

interface ICurveVoteEscrow {
  struct LockedBalance {
    int128 amount;
    uint256 end;
  }

  /// @notice Deposit `_value` tokens for `msg.sender` and lock until `_unlock_time`
  /// @param _value Amount to deposit
  /// @param _unlock_time Epoch time when tokens unlock, rounded down to whole weeks
  function create_lock(uint256 _value, uint256 _unlock_time) external;

  /// @notice Deposit `_value` additional tokens for `msg.sender` without modifying the unlock time
  /// @param _value Amount of tokens to deposit and add to the lock
  function increase_amount(uint256 _value) external;

  /// @notice Extend the unlock time for `msg.sender` to `_unlock_time`
  /// @param _unlock_time New epoch time for unlocking
  function increase_unlock_time(uint256 _unlock_time) external;

  /// @notice Withdraw all tokens for `msg.sender`
  /// @dev Only possible if the lock has expired
  function withdraw() external;

  /// @notice Get timestamp when `_addr`'s lock finishes
  /// @param _addr User wallet
  /// @return Epoch time of the lock end
  function locked__end(address _addr) external view returns (uint256);

  function locked(address _addr) external view returns (LockedBalance memory);
}