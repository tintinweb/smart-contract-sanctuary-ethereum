// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./BaseTokenVault.sol";
import "./IFeeModel.sol";

contract TokenVault is BaseTokenVault {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== CLONE's MASTER CONTRACT ========== */
  TokenVault public immutable masterContract;

  /* ========== STATE VARIABLES: Migration Options ========== */
  IFeeModel public withdrawalFeeModel;
  IMigrator public reserveMigrator; // should be similar to the migrator (with treasury amd gov lp vault fee = 0)
  uint24 public feePool; // applicable only for token vault (gov lp vault doesn't have a feepool)
  address public treasury;
  uint256 public treasuryFeeRate;
  uint256 public campaignStartBlock;
  uint256 public campaignEndBlock;

  /* ========== EVENTS ========== */
  event Migrate(uint256 stakingTokenAmount, uint256 vaultETHAmount);
  event SetMigrationOption(
    IMigrator migrator,
    IMigrator reserveMigrator,
    uint256 campaignEndBlock,
    address feeModel,
    uint256 feePool,
    address treasury,
    uint256 treasuryFeeRate
  );
  event ReduceReserve(address to, uint256 reserveAmount, uint256 reducedETHAmount);
  event ClaimETH(address indexed user, uint256 ethAmount);

  /* ========== ERRORS ========== */
  error TokenVault_InvalidChainId();
  error TokenVault_InvalidTreasuryFeeRate();
  error TokenVault_InvalidCampaignEndBlock();

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
    isGovLpVault = false;
    isInitialized = true;
  }

  /* ========== ADMIN FUNCTIONS ========== */

  function setMigrationOption(
    IMigrator _migrator,
    IMigrator _reserveMigrator,
    uint256 _campaignEndBlock,
    address _withdrawalFeeModel,
    uint24 _feePool,
    address _treasury,
    uint256 _treasuryFeeRate
  ) external onlyMasterContractOwner {
    if (_treasuryFeeRate >= 1 ether) {
      revert TokenVault_InvalidTreasuryFeeRate();
    }
    if (block.number >= _campaignEndBlock) {
      revert TokenVault_InvalidCampaignEndBlock();
    }

    migrator = _migrator;
    reserveMigrator = _reserveMigrator;
    campaignEndBlock = _campaignEndBlock;
    withdrawalFeeModel = IFeeModel(_withdrawalFeeModel);
    feePool = _feePool;
    treasury = _treasury;
    treasuryFeeRate = _treasuryFeeRate;

    emit SetMigrationOption(
      _migrator,
      _reserveMigrator,
      _campaignEndBlock,
      _withdrawalFeeModel,
      _feePool,
      _treasury,
      _treasuryFeeRate
    );
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function migrate() external override nonReentrant whenNotMigrated {
    // If chain id = 1, revert
    // otherwise, only controller can call the migration
    if (block.chainid == 1) {
      revert TokenVault_InvalidChainId();
    } else {
      if (controller != msg.sender) {
        revert TokenVault_NotController();
      }
    }

    isMigrated = true;

    if (_totalSupply == 0) return;

    bytes memory data = abi.encode(address(stakingToken), feePool);

    stakingToken.safeTransfer(address(migrator), _totalSupply);
    migrator.execute(data);

    ethSupply = address(this).balance;

    emit Migrate(_totalSupply, ethSupply);
  }

  function reduceReserve() external nonReentrant {
    // If chain id = 1 and the caller is not an owner, revert
    // otherwise, only controller can call the migration
    if (block.chainid == 1) {
      if (msg.sender != getMasterContractOwner()) {
        revert TokenVault_NotOwner();
      }
    } else {
      if (msg.sender != controller) {
        revert TokenVault_NotController();
      }
    }

    if (reserve == 0) return;

    bytes memory data = abi.encode(address(stakingToken), feePool);

    uint256 ethBalanceBefore = address(this).balance;

    uint256 _reserve = reserve; // SLOAD
    reserve = 0;

    stakingToken.safeTransfer(address(reserveMigrator), _reserve);
    reserveMigrator.execute(data);

    uint256 reducedETHAmount = address(this).balance - ethBalanceBefore;

    if (reducedETHAmount > 0) {
      if (block.chainid == 1) {
        treasury.safeTransferETH(reducedETHAmount);
        emit ReduceReserve(treasury, _reserve, reducedETHAmount);
        return;
      }
      uint256 treasuryFee = treasuryFeeRate.mulWadDown(reducedETHAmount);
      uint256 executionFee = reducedETHAmount - treasuryFee;

      msg.sender.safeTransferETH(executionFee);
      treasury.safeTransferETH(treasuryFee);

      emit ReduceReserve(msg.sender, _reserve, executionFee);
      emit ReduceReserve(treasury, _reserve, treasuryFee);
    }
  }

  function claimETH() external whenMigrated {
    // claimGov first to reset the reward
    claimGov();
    uint256 claimable = _balances[msg.sender].mulDivDown(ethSupply, _totalSupply);

    if (claimable == 0) {
      return;
    }

    _balances[msg.sender] = 0;

    msg.sender.safeTransferETH(claimable);

    emit ClaimETH(msg.sender, claimable);
  }

  function notifyRewardAmount(uint256 _reward) external override onlyRewardsDistribution updateReward(address(0)) {
    if (block.timestamp >= periodFinish) {
      campaignStartBlock = block.number;
      rewardRate = _reward.div(rewardsDuration);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = _reward.add(leftover).div(rewardsDuration);
    }

    // Ensure the provided reward amount is not more than the balance in the contract.
    // This keeps the reward rate in the right range, preventing overflows due to
    // very high values of rewardRate in the earned and rewardsPerToken functions;
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    uint256 balance = IERC20(rewardsToken).balanceOf(address(this));
    if (rewardRate > balance.div(rewardsDuration)) revert TokenVault_ProvidedRewardTooHigh();

    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(rewardsDuration);
    emit RewardAdded(_reward);
  }

  function withdraw(uint256 _amount) public override nonReentrant whenNotMigrated updateReward(msg.sender) {
    if (_amount <= 0) revert TokenVault_CannotWithdrawZeroAmount();

    // actual withdrawal amount calculation with fee calculation
    uint256 feeRate = withdrawalFeeModel.getFeeRate(campaignStartBlock, block.number, campaignEndBlock);
    uint256 withdrawalFee = feeRate.mulWadDown(_amount);
    reserve += withdrawalFee;
    uint256 actualWithdrawalAmount = _amount - withdrawalFee;

    _totalSupply = _totalSupply.sub(_amount);
    _balances[msg.sender] = _balances[msg.sender].sub(_amount);

    stakingToken.safeTransfer(msg.sender, actualWithdrawalAmount);

    emit Withdrawn(msg.sender, actualWithdrawalAmount, withdrawalFee);
  }

  function getAmountOut() external returns (uint256) {
    if (address(migrator) == address(0) || _totalSupply == 0) {
      return 0;
    }
    bytes memory data = abi.encode(address(stakingToken), uint24(feePool), uint256(_totalSupply));
    return migrator.getAmountOut(data);
  }

  function getApproximatedExecutionRewards() external returns (uint256) {
    if (address(migrator) == address(0) || _totalSupply == 0) return 0;

    bytes memory data = abi.encode(address(stakingToken), uint24(feePool), uint256(_totalSupply));
    return migrator.getApproximatedExecutionRewards(data);
  }

  function getMasterContractOwner() public view override returns (address) {
    return masterContract.owner();
  }
}