// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../lendingPool/ILendingPool.sol";

contract LendingPoolSeniorObligationUpdateExecutor {
  event PoolFailedToUpdate(address indexed _poolAddress);

  function execute(address[] calldata poolAddresses) external {
    for (uint256 i = 0; i < poolAddresses.length; i++) {
      if (poolAddresses[i] != address(0)) {
        try (ILendingPool(poolAddresses[i])).updateSeniorObligation() {} catch {
          emit PoolFailedToUpdate(poolAddresses[i]);
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Tranche {
  JUNIOR,
  SENIOR
}

interface ILendingPool {
  function init(
    address _jCopToken,
    address _sCopToken,
    address _copraGlobal,
    address _copToken,
    address _loanNFT
  ) external;

  function registerLoan(bytes calldata _loan) external;

  function payLoan(uint256 _loanID, uint256 _amount) external;

  function disburseLoan(uint256 _loanID) external;

  function updateLoan(uint256 _loanID) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function getOriginator() external view returns (address);

  function updateSeniorObligation() external;

  function getLastUpdatedAt() external view returns (uint256);
}