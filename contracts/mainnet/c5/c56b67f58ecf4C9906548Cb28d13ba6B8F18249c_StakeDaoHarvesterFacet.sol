// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../../concentrator/interfaces/IAladdinCompounder.sol";
import "../../concentrator/stakedao/interfaces/IStakeDAOVault.sol";

import "../libraries/LibConcentratorHarvester.sol";

contract StakeDaoHarvesterFacet {
  /// @notice Harvest pending rewards from StakeDAOVault contract.
  /// @param _vault The address of StakeDAOVault contract.
  function harvestStakeDaoVault(address _vault) external {
    LibConcentratorHarvester.enforceHasPermission();

    IStakeDAOVault(_vault).harvest(msg.sender);
  }

  /// @notice Harvest pending rewards from StakeDAOVault and corresponding AladdinCompounder contract.
  /// @param _vault The address of StakeDAOVault contract.
  /// @param _compounder The address of AladdinCompounder contract.
  /// @param _minAssets The minimum amount of underlying assets should be harvested.
  function harvestStakeDaoVaultAndCompounder(
    address _vault,
    address _compounder,
    uint256 _minAssets
  ) external {
    LibConcentratorHarvester.enforceHasPermission();

    IStakeDAOVault(_vault).harvest(msg.sender);
    IAladdinCompounder(_compounder).harvest(msg.sender, _minAssets);
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

interface IStakeDAOVault {
  /// @notice Emitted when user deposit staking token to the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token deposited.
  event Deposit(address indexed _owner, address indexed _recipient, uint256 _amount);

  /// @notice Emitted when user withdraw staking token from the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the staking token.
  /// @param _amount The amount of staking token withdrawn.
  /// @param _fee The amount of withdraw fee.
  event Withdraw(address indexed _owner, address indexed _recipient, uint256 _amount, uint256 _fee);

  /// @notice Emitted when user claim pending rewards from the contract.
  /// @param _owner The address of the owner of the staking token.
  /// @param _recipient The address of the recipient of the pending rewards.
  /// @param _amounts The list of pending reward amounts.
  event Claim(address indexed _owner, address indexed _recipient, uint256[] _amounts);

  /// @notice Emitted when someone harvest pending rewards.
  /// @param _caller The address of the caller.
  /// @param _rewards The list of harvested rewards.
  /// @param _bounties The list of harvest bounty given to caller.
  /// @param _platformFees The list of platform fee taken.
  /// @param _boostFee The amount SDT for veSDT boost delegation fee.
  event Harvest(
    address indexed _caller,
    uint256[] _rewards,
    uint256[] _bounties,
    uint256[] _platformFees,
    uint256 _boostFee
  );

  /// @notice Return the amount of staking token staked in the contract.
  function totalSupply() external view returns (uint256);

  /// @notice Return the amount of staking token staked in the contract for some user.
  /// @param _user The address of user to query.
  function balanceOf(address _user) external view returns (uint256);

  /// @notice Deposit some staking token to the contract.
  /// @dev use `_amount=-1` to deposit all tokens.
  /// @param _amount The amount of staking token to deposit.
  /// @param _recipient The address of recipient who will receive the deposited staking token.
  function deposit(uint256 _amount, address _recipient) external;

  /// @notice Withdraw some staking token from the contract.
  /// @dev use `_amount=-1` to withdraw all tokens.
  /// @param _amount The amount of staking token to withdraw.
  /// @param _recipient The address of recipient who will receive the withdrawn staking token.
  function withdraw(uint256 _amount, address _recipient) external;

  /// @notice Claim all pending rewards from some user.
  /// @param _user The address of user to claim.
  /// @param _recipient The address of recipient who will receive the rewards.
  /// @return _amounts The list of amount of rewards claimed.
  function claim(address _user, address _recipient) external returns (uint256[] memory _amounts);

  /// @notice Harvest pending reward from the contract.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  function harvest(address _recipient) external;

  /// @notice Update the user information.
  /// @param _user The address of user to update.
  function checkpoint(address _user) external;
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