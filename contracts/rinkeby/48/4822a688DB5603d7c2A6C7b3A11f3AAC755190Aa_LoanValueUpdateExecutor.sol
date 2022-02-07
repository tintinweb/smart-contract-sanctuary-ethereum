// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../../loans/ILoanNFT.sol";

abstract contract LoanUpdateExecutor {
  event LoanFailedToUpdate(uint256 _loanID);

  function execute(address _loanNFTAddress, uint256[] calldata _loanIDs) external {
    for (uint256 i = 0; i < _loanIDs.length; i++) {
      uint256 loanID = _loanIDs[i];
      address lpAddress = (ILoanNFT(_loanNFTAddress)).getLoanOwner(loanID);
      if (!_processLoan(loanID, lpAddress)) {
        emit LoanFailedToUpdate(loanID);
      }
    }
  }

  function _processLoan(uint256 _loanID, address _lpAddress) internal virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./LoanUpdateExecutor.sol";
import "../../../lendingPool/ILendingPool.sol";

contract LoanValueUpdateExecutor is LoanUpdateExecutor {
  function _processLoan(uint256 _loanID, address _lpAddress) internal override returns (bool) {
    try (ILendingPool(_lpAddress)).updateLoan(_loanID) {
      return true;
    } catch {
      return false;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LoanBalances {
  uint256 outstanding;
  uint256 fee;
  uint256 late;
  uint256 pool;
  uint256 balance;
  uint256 netValue;
  uint256 lastUpdatedAt;
}

enum LoanStatus {
  REGISTERED,
  DISBURSED,
  CLOSED,
  DEFAULTED,
  FAILED_TO_DISBURSE
}

struct Loan {
  uint256 repaymentDate;
  uint256 principal;
  uint256 amountRepaid;
  uint256 lateFee;
  uint256 disbursementDate;
  uint256 actualTimeDisbursed;
  uint256 dailyRate;
  address borrower;
  LoanBalances balances;
  LoanStatus status;
}

interface ILoanNFT {
  function mintNewLoan(bytes calldata _loan) external returns (uint256);

  function updateMultipleLoanValues(uint256[] calldata _loanIDs) external;

  function updateLoanValue(uint256 _loanID) external;

  function getTotalLoanValue(address _loanOwner) external view returns (uint256);

  function getLoan(uint256 _loanId) external view returns (Loan memory);

  function updateAmountPaid(uint256 _loanId, uint256 _loanRepayment)
    external
    returns (
      uint256 _amountToPool,
      uint256 _amountToOriginator,
      uint256 _amountToGovernance
    );

  function disburse(uint256 _loanID) external;

  function setStatus(uint256 _loanID, LoanStatus _newStatus) external;

  function getNumLoans() external view returns (uint256);

  function getLoanOwner(uint256 _loanID) external view returns (address);
}