// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "../../concentrator/clever/interfaces/ICLeverAMO.sol";

import "../libraries/LibConcentratorHarvester.sol";

contract CLeverAMOHarvesterFacet {
  /// @notice Harvest pending rewards from CLeverAMO contract.
  /// @param _amo The address of CLeverAMO contract.
  /// @param _minBaseOut The minimum of base token should harvested.
  function harvestCLeverAMO(address _amo, uint256 _minBaseOut) external {
    LibConcentratorHarvester.enforceHasPermission();

    ICLeverAMO(_amo).harvest(msg.sender, _minBaseOut);
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

interface ICLeverAMO {
  /// @notice Emitted when someone deposit base token to the contract.
  /// @param owner The owner of the base token.
  /// @param recipient The recipient of the locked base token.
  /// @param amount The amount of base token deposited.
  /// @param unlockAt The timestamp in second when the pool share is unlocked.
  event Deposit(address indexed owner, address indexed recipient, uint256 amount, uint256 unlockAt);

  /// @notice Emitted when someone unlock base token to pool share.
  /// @param owner The owner of the locked base token.
  /// @param amount The amount of base token unlocked.
  /// @param share The amount of pool share received.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Unlock(address indexed owner, uint256 amount, uint256 share, uint256 ratio);

  /// @notice Emitted when someone withdraw pool share.
  /// @param owner The owner of the pool share.
  /// @param recipient The recipient of the withdrawn debt token and lp token.
  /// @param shares The amount of pool share to withdraw.
  /// @param debtAmount The current amount of debt token received.
  /// @param lpAmount The current amount of lp token received.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Withdraw(
    address indexed owner,
    address indexed recipient,
    uint256 shares,
    uint256 debtAmount,
    uint256 lpAmount,
    uint256 ratio
  );

  /// @notice Emitted when someone call harvest.
  /// @param caller The address of the caller.
  /// @param baseAmount The amount of base token harvested.
  /// @param platformFee The amount of platform fee.
  /// @param bounty The amount of base token as harvest bounty.
  /// @param debtAmount The current amount of debt token harvested.
  /// @param lpAmount The current amount of lp token harvested.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Harvest(
    address indexed caller,
    uint256 baseAmount,
    uint256 platformFee,
    uint256 bounty,
    uint256 debtAmount,
    uint256 lpAmount,
    uint256 ratio
  );

  /// @notice Emitted when someone checkpoint AMO state.
  /// @param baseAmount The amount of base token used to convert.
  /// @param debtAmount The current amount of debt token converted.
  /// @param lpAmount The current amount of lp token converted.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  event Checkpoint(uint256 baseAmount, uint256 debtAmount, uint256 lpAmount, uint256 ratio);

  /// @notice Emitted when someone donate base token to the contract.
  /// @param caller The address of the caller.
  /// @param amount The amount of base token donated.
  event Donate(address indexed caller, uint256 amount);

  /// @notice Emitted when someone call rebalance.
  /// @param ratio The current ratio between lp token and debt token in the contract.
  /// @param startPoolRatio The ratio between debt token and base token in curve pool before rebalance.
  /// @param targetPoolRatio The ratio between debt token and base token in curve pool after rebalance.
  event Rebalance(uint256 ratio, uint256 startPoolRatio, uint256 targetPoolRatio);

  /// @notice The address of base token.
  function baseToken() external view returns (address);

  /// @notice The address of debt token.
  function debtToken() external view returns (address);

  /// @notice The address of Curve base/debt pool.
  function curvePool() external view returns (address);

  /// @notice The address of Curve base/debt lp token.
  function curveLpToken() external view returns (address);

  /// @notice The address of furnace contract for debt token.
  function furnace() external view returns (address);

  /// @notice The total amount of debt token in contract.
  function totalDebtToken() external view returns (uint256);

  /// @notice The total amount of curve lp token in contract.
  function totalCurveLpToken() external view returns (uint256);

  /// @notice The current ratio between curve lp token and debt token, with precision 1e18.
  function ratio() external view returns (uint256);

  /// @notice Deposit base token to the contract.
  /// @dev Use `_amount` when caller wants to deposit all his base token.
  /// @param _amount The amount of base token to deposit.
  /// @param _recipient The address recipient who will receive the base token.
  function deposit(uint256 _amount, address _recipient) external;

  /// @notice Unlock pool share from the contract.
  /// @param _minShareOut The minimum amount of shares should receive.
  /// @return shares The amount of shares received.
  function unlock(uint256 _minShareOut) external returns (uint256 shares);

  /// @notice Burn shares and withdraw to debt token and lp token according to current ratio.
  /// @dev Use `_shares` when caller wants to withdraw all his shares.
  /// @param _shares The amount of pool shares to burn.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _minLpOut The minimum of lp token should receive.
  /// @param _minDebtOut The minimum of debt token should receive.
  /// @return lpTokenOut The amount of lp token received.
  /// @return debtTokenOut The amount of debt token received.
  function withdraw(
    uint256 _shares,
    address _recipient,
    uint256 _minLpOut,
    uint256 _minDebtOut
  ) external returns (uint256 lpTokenOut, uint256 debtTokenOut);

  /// @notice Burn shares and withdraw to base token.
  /// @dev Use `_shares` when caller wants to withdraw all his shares.
  /// @param _shares The amount of pool shares to burn.
  /// @param _recipient The address of recipient who will receive the token.
  /// @param _minBaseOut The minimum of base token should receive.
  /// @return baseTokenOut The amount of base token received.
  function withdrawToBase(
    uint256 _shares,
    address _recipient,
    uint256 _minBaseOut
  ) external returns (uint256 baseTokenOut);

  /// @notice Someone donate base token to the contract.
  /// @param _amount The amount of base token to donate.
  function donate(uint256 _amount) external;

  /// @notice rebalance the curve pool based on tokens in curve pool.
  /// @param _withdrawAmount The amount of debt token or lp token to withdraw.
  /// @param _minOut The minimum output token to control slippage.
  /// @param _targetRangeLeft The left end point of the target range, multiplied by 1e18.
  /// @param _targetRangeRight The right end point of the target range, multiplied by 1e18.
  function rebalance(
    uint256 _withdrawAmount,
    uint256 _minOut,
    uint256 _targetRangeLeft,
    uint256 _targetRangeRight
  ) external;

  /// @notice harvest the pending rewards and reinvest to the pool.
  /// @param _recipient The address of recipient who will receive the harvest bounty.
  /// @param _minBaseOut The minimum of base token should harvested.
  /// @return baseTokenOut The amount of base token harvested.
  function harvest(address _recipient, uint256 _minBaseOut) external returns (uint256 baseTokenOut);

  /// @notice External call to checkpoint AMO state.
  function checkpoint() external;
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