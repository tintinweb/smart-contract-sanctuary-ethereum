// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./BaseTokenVault.sol";

contract GovLPVault is BaseTokenVault {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CLONE's MASTER CONTRACT ========== */
  GovLPVault public immutable masterContract;

  /* ========== STATE VARIABLES ========== */
  uint256 public powaaSupply; // powaa token as a result of removing liquidity of POWAA-ETH LP

  /* ========== EVENTS ========== */
  event Migrate(uint256 stakingTokenAmount, uint256 returnETHAmount, uint256 returnPOWAAAmount);
  event SetMigrationOption(IMigrator migrator);
  event ClaimETHPOWAA(address indexed user, uint256 claimableETH, uint256 claimablePOWAA);

  /* ========== MASTER CONTRACT INITIALIZE ========== */
  constructor() {
    masterContract = this;
  }

  /* ========== CLONE INITIALIZE ========== */
  function initialize(
    address _rewardsDistribution,
    address _rewardsToken,
    address _stakingToken,
    address _controller
  ) external override {
    if (isInitialized) revert TokenVault_AlreadyInitialized();

    rewardsToken = _rewardsToken;
    stakingToken = IERC20(_stakingToken);
    rewardsDistribution = _rewardsDistribution;
    controller = _controller;
    rewardsDuration = 7 days; // default 7 days
    isGovLpVault = true;
    isInitialized = true;
  }

  /* ========== ADMIN FUNCTIONS ========== */

  function setMigrationOption(IMigrator _migrator) external onlyMasterContractOwner {
    migrator = _migrator;

    emit SetMigrationOption(_migrator);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function migrate() external override nonReentrant whenNotMigrated {
    // If chain id = 1 and the caller is not an owner, revert
    // otherwise, only controller can call the migration
    if (block.chainid == 1) {
      if (getMasterContractOwner() != msg.sender) {
        revert TokenVault_NotOwner();
      }
    } else {
      if (controller != msg.sender) {
        revert TokenVault_NotController();
      }
    }

    isMigrated = true;

    if (_totalSupply == 0) return;

    bytes memory data = abi.encode(address(stakingToken));
    uint256 powaaBalanceBefore = IERC20(rewardsToken).balanceOf(address(this));

    stakingToken.safeTransfer(address(migrator), _totalSupply);
    migrator.execute(data);

    ethSupply = address(this).balance;
    powaaSupply = IERC20(rewardsToken).balanceOf(address(this)) - powaaBalanceBefore;

    emit Migrate(_totalSupply, ethSupply, powaaSupply);
  }

  function claimETHPOWAA() external whenMigrated {
    // claimGov first to reset the reward
    claimGov();
    uint256 claimableETH = _balances[msg.sender].mulDivDown(ethSupply, _totalSupply);
    uint256 claimablePOWAA = _balances[msg.sender].mulDivDown(powaaSupply, _totalSupply);

    if (claimableETH == 0 && claimablePOWAA == 0) {
      return;
    }

    _balances[msg.sender] = 0;

    msg.sender.safeTransferETH(claimableETH);
    IERC20(rewardsToken).safeTransfer(msg.sender, claimablePOWAA);

    emit ClaimETHPOWAA(msg.sender, claimableETH, claimablePOWAA);
  }

  function getMasterContractOwner() public view override returns (address) {
    return masterContract.owner();
  }
}