// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./Clones.sol";
import "./Address.sol";
import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./ITokenVault.sol";

contract Controller is Ownable {
  using Address for address;
  using Clones for address;
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;

  /* ========== STATE VARIABLES ========== */
  address[] public tokenVaults;
  address public govLPVault;
  mapping(address => bool) public registeredVaults;

  /* ========== EVENTS ========== */
  event Migrate(address[] vaults);
  event SetVault(address vault, bool isGovLPVault);
  event NewVault(address instance);
  event TransferFee(address beneficiary, uint256 fee);
  event SetRegisterVault(address vault, bool isRegistered);

  /* ========== ERRORS ========== */
  error Controller_NoVaults();
  error Controller_NoGovLPVault();
  error Controller_NonRegisterVault();

  /* ========== VIEWS ========== */

  function getDeterministicVault(address implementation, address _rewardsToken)
    external
    view
    returns (address predicted)
  {
    bytes32 salt = keccak256(abi.encodePacked(_rewardsToken));
    return implementation.predictDeterministicAddress(salt);
  }

  /* ========== ADMIN FUNCTIONS ========== */

  function _whitelistVault(address _vault, bool _isGovLPVault) private {
    if (_isGovLPVault) {
      govLPVault = _vault;
    } else {
      tokenVaults.push(_vault);
    }

    registeredVaults[_vault] = true;

    emit SetVault(_vault, _isGovLPVault);
  }

  function whitelistLPVault(address _vault) external onlyOwner {
    if (!registeredVaults[_vault]) revert Controller_NonRegisterVault();

    _whitelistVault(_vault, true);
  }

  // @dev For Safety Reason
  function setRegisterVault(address _vault, bool _isRegistered) external onlyOwner {
    registeredVaults[_vault] = _isRegistered;

    emit SetRegisterVault(_vault, _isRegistered);
  }

  function _initVaultAndEmit(
    address _instance,
    address _rewardsDistribution,
    address _rewardsToken,
    address _stakingToken,
    address _controller
  ) private {
    ITokenVault(_instance).initialize(_rewardsDistribution, _rewardsToken, _stakingToken, _controller);

    emit NewVault(_instance);
  }

  function deployDeterministicVault(
    address _implementation,
    address _rewardsDistribution,
    address _rewardsToken,
    address _stakingToken
  ) external onlyOwner {
    bytes32 salt = keccak256(abi.encodePacked(_stakingToken));
    address clone = _implementation.cloneDeterministic(salt);

    _initVaultAndEmit(clone, _rewardsDistribution, _rewardsToken, _stakingToken, address(this));

    _whitelistVault(clone, IBaseTokenVault(clone).isGovLpVault());
  }

  function migrate() external {
    if (tokenVaults.length == 0) revert Controller_NoVaults();
    if (govLPVault == address(0)) revert Controller_NoGovLPVault();

    uint256 vaultLength = tokenVaults.length;
    address[] memory _vaults = new address[](vaultLength + 1);

    for (uint256 index = 0; index < vaultLength; index++) {
      address tokenVault = tokenVaults[index];
      _vaults[index] = tokenVault;

      if (!registeredVaults[tokenVault]) {
        continue;
      }

      ITokenVault(tokenVault).reduceReserve();
      ITokenVault(tokenVault).migrate();
    }

    _vaults[vaultLength] = govLPVault;
    ITokenVault(govLPVault).migrate();

    uint256 executionFee = address(this).balance;
    if (executionFee > 0) {
      msg.sender.safeTransferETH(executionFee);

      emit TransferFee(msg.sender, executionFee);
    }
    emit Migrate(_vaults);
  }

  function getTotalAmountOut() external returns (uint256) {
    if (tokenVaults.length == 0) revert Controller_NoVaults();
    uint256 vaultLength = tokenVaults.length;
    address[] memory _vaults = new address[](vaultLength);
    uint256 sum = 0;

    for (uint256 index = 0; index < vaultLength; index++) {
      _vaults[index] = tokenVaults[index];
      uint256 amount = ITokenVault(tokenVaults[index]).getAmountOut();
      sum += amount;
    }

    return sum;
  }

  function getApproximatedTotalExecutionRewards() external returns (uint256) {
    if (tokenVaults.length == 0) revert Controller_NoVaults();
    uint256 vaultLength = tokenVaults.length;
    address[] memory _vaults = new address[](vaultLength);
    uint256 sum = 0;

    for (uint256 index = 0; index < vaultLength; index++) {
      _vaults[index] = tokenVaults[index];
      uint256 amount = ITokenVault(tokenVaults[index]).getApproximatedExecutionRewards();
      sum += amount;
    }

    return sum;
  }

  /// @dev Fallback function to accept ETH.
  receive() external payable {}
}