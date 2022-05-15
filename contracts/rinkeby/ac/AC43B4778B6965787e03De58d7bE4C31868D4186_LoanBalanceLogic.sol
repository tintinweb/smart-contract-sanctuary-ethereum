// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Expenses {
  uint256 listLoan;
  uint256 proposePool;
}

interface ICopraGlobal {
  function setIsProtocolActive(bool _isProtocolActive) external;

  function setMaxLateDays(uint256 _maxLateDays) external;

  function setWithdrawalFee(uint256 _withdrawalFee) external;

  function setOriginatorFee(uint256 _originatorFee) external;

  function setGovernanceFee(uint256 _governanceFee) external;

  function setTreasuryAddress(address _treasury) external;

  function setProposePoolExpense(uint256 _proposePoolExpense) external;

  function setListLoanExpense(uint256 _listLoanExpense) external;

  function toggleWhitelistedUser(address _user) external;

  function getFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function isProtocolActive() external view returns (bool);

  function getExpenses() external view returns (Expenses memory);

  function getTreasuryAddress() external view returns (address);

  function getMaxLateDays() external view returns (uint256);

  function isWhitelistedUser(address _user) external view returns (bool);

  function getTimelockController() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./libraries/types.sol";

enum Tranche {
  JUNIOR,
  SENIOR
}

struct LoanRegistrationParams {
  uint256 repaymentDate;
  uint256 principal;
  uint256 lateFee;
  uint256 timeDisbursed;
  uint256 dailyRate;
  address borrowerAddress;
  string purpose;
  string description;
}

struct PoolUpdateParams {
  uint256[] updatedLoanIDs;
  Loan[] loansToUpdate;
  uint256 totalLoanValue;
  uint256 numLoansUpdated;
  uint256 updatedSeniorObligation;
  bool isLastUpdate;
}

enum LoanStatus {
  REGISTERED,
  ACTIVE,
  DISBURSED,
  CLOSED,
  DEFAULTED,
  FAILED_TO_DISBURSE
}

struct Loan {
  uint256 globalLoanID;
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

interface ILendingPool {
  function init(address _jCopToken, address _sCopToken) external;

  function registerLoan(LoanRegistrationParams calldata _loanParams) external;

  function payLoan(uint256 _loanID, uint256 _amount) external;

  function disburseLoan(uint256 _loanID) external;

  function deposit(Tranche _tranche, uint256 _amount) external;

  function withdraw(Tranche _tranche, uint256 _amount) external;

  function update(PoolUpdateParams memory _updateParams) external;

  function transferLoan(uint256 _loanID) external;

  function activateLoan(uint256 _loanID) external;

  function getPoolUpdateParams(uint256 _numLoans) external view returns (PoolUpdateParams memory);

  function getData()
    external
    view
    returns (
      LendingPoolStateData memory,
      LendingPoolConstraints memory,
      address
    );

  function getLoan(uint256 _loanID) external view returns (Loan memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {LendingPoolStateData} from "./types.sol";
import {ILoanNFT} from "../../loans/ILoanNFT.sol";
import {ICopraGlobal} from "../../ICopraGlobal.sol";
import {DSMath} from "../../library/DSMath.sol";
import {Loan, LoanBalances, LoanStatus} from "../ILendingPool.sol";

library LoanBalanceLogic {
  using DSMath for uint256;

  function getUpdatedLoanValue(
    Loan[] storage _loans,
    uint256 _loanID,
    ICopraGlobal _copraGlobal
  ) public view returns (Loan memory) {
    return getUpdatedLoanBalances(_loans[_loanID], _copraGlobal);
  }

  function getUpdatedLoanBalances(Loan memory _loan, ICopraGlobal _copraGlobal) public view returns (Loan memory) {
    (, uint256 originatorFee, uint256 governanceFee) = _copraGlobal.getFees();

    // Update loan balances
    _loan.balances.outstanding = _loan.balances.outstanding.add(_loan.balances.outstanding.wmul(_loan.dailyRate));
    _loan.balances.fee = _loan.balances.fee.add(
      _loan.balances.outstanding.wmul(_loan.dailyRate).wmul(originatorFee.add(governanceFee))
    );
    if (block.timestamp >= _loan.repaymentDate) {
      _loan.balances.late = _loan.balances.late.add(_loan.balances.outstanding.wmul(_loan.lateFee));
    }
    _loan.balances.balance = _loan.balances.outstanding.add(_loan.balances.late);
    _loan.balances.netValue = calculateLoanValue(_loan, _copraGlobal);
    return _loan;
  }

  function calculateLoanValue(Loan memory _loan, ICopraGlobal _copraGlobal) public view returns (uint256) {
    uint256 loanBalance = _loan.balances.outstanding.add(_loan.balances.late);
    uint256 loanValue = loanBalance < _loan.balances.fee ? 0 : loanBalance.sub(_loan.balances.fee);
    uint256 loanLateDays = block.timestamp < _loan.repaymentDate
      ? 0
      : (((block.timestamp - _loan.repaymentDate) / 1 days) + 1).toWAD();

    uint256 maxLateDays = _copraGlobal.getMaxLateDays().toWAD();
    uint256 loanLateDaysRatio = loanLateDays.wdiv(maxLateDays);
    uint256 oneWAD = uint256(1).toWAD();
    uint256 multiplier = loanLateDaysRatio > oneWAD ? 0 : oneWAD.sub(loanLateDays.wdiv(maxLateDays));

    return loanValue.wmul(multiplier);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LendingPoolConstraints {
  uint256 minReservePercentage;
  uint256 maxReservePercentage;
  uint256 minUnderwritten;
  uint256 maxPoolSize;
}

struct LendingPoolStateData {
  uint256 dailySeniorYield;
  uint256 seniorObligation;
  uint256 juniorValue;
  uint256 seniorValue;
  uint256 sCopTokenPrice;
  uint256 jCopTokenPrice;
  uint256 lastUpdatedAt;
  uint256 totalLoanValue;
  uint256 lastUpdatedLoanIdx;
  bool isPoolActive;
  bool isUpdating;
  address baseTokenAddress;
  address jCopTokenAddress;
  address sCopTokenAddress;
}

struct LoanBalances {
  uint256 outstanding;
  uint256 fee;
  uint256 late;
  uint256 balance;
  uint256 netValue;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.4.13;

library DSMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x <= y ? x : y;
  }

  function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
    return x >= y ? x : y;
  }

  function imin(int256 x, int256 y) internal pure returns (int256 z) {
    return x <= y ? x : y;
  }

  function imax(int256 x, int256 y) internal pure returns (int256 z) {
    return x >= y ? x : y;
  }

  uint256 constant WAD = 10**18;
  uint256 constant RAY = 10**27;

  function toWAD(uint256 a) internal pure returns (uint256 b) {
    b = a * WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), WAD / 2) / WAD;
  }

  //rounds to zero if x*y < WAD / 2
  function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, y), RAY / 2) / RAY;
  }

  //rounds to zero if x*y < WAD / 2
  function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, WAD), y / 2) / y;
  }

  //rounds to zero if x*y < RAY / 2
  function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = add(mul(x, RAY), y / 2) / y;
  }

  // This famous algorithm is called "exponentiation by squaring"
  // and calculates x^n with x as fixed-point and n as regular unsigned.
  //
  // It's O(log n), instead of O(n) for naive repeated multiplication.
  //
  // These facts are why it works:
  //
  //  If n is even, then x^n = (x^2)^(n/2).
  //  If n is odd,  then x^n = x * x^(n-1),
  //   and applying the equation for even x gives
  //    x^n = x * (x^2)^((n-1) / 2).
  //
  //  Also, EVM division is flooring and
  //    floor[(n-1) / 2] = floor[n / 2].
  //
  function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
    z = n % 2 != 0 ? x : RAY;

    for (n /= 2; n != 0; n /= 2) {
      x = rmul(x, x);

      if (n % 2 != 0) {
        z = rmul(z, x);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct LoanMeta {
  address pool;
  uint256 loanID;
}

interface ILoanNFT {
  function mint(
    uint256 _loanID,
    string memory _purpose,
    string memory _description
  ) external returns (uint256);

  function getLoan(uint256 _loanId) external view returns (LoanMeta memory);

  function getNumLoans() external view returns (uint256);

  function getLoanOwner(uint256 _loanID) external view returns (address);
}