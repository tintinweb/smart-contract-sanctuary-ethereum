// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity ^0.8.4;

interface ICopraGlobal {
  struct Expenses {
    uint256 listLoan;
    uint256 proposePool;
  }

  function getFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getExpenses() external returns (Expenses memory);

  function getTreasuryAddress() external returns (address);

  function getMaxLateDays() external view returns (uint256);

  function setMaxLateDays(uint256 _maxLateDays) external;

  function setWithdrawalFee(uint256 _withdrawalFee) external;

  function setOriginatorFee(uint256 _originatorFee) external;

  function setGovernanceFee(uint256 _governanceFee) external;

  function setTreasuryAddress(address _treasury) external;

  function setProposePoolExpense(uint256 _proposePoolExpense) external;

  function setListLoanExpense(uint256 _listLoanExpense) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./types.sol";
import "../../loans/ILoanNFT.sol";
import "../../ICopraGlobal.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../library/DSMath.sol";

library LoanTransactionLogic {
  using DSMath for uint256;

  function update(uint256 _loanID, address _loanNFTAddress) public {
    ILoanNFT loanNFT = ILoanNFT(_loanNFTAddress);
    loanNFT.updateLoanValue(_loanID);
  }

  function disburse(
    LendingPoolStateData memory _self,
    uint256 _loanID,
    address _loanNFTAddress
  ) public returns (uint256) {
    ILoanNFT loanNFT = ILoanNFT(_loanNFTAddress);
    Loan memory loan = loanNFT.getLoan(_loanID);
    address borrower = loan.borrower;
    require(_canLoanBeDisbursed(loan), "LoanTransactionLogic: Loan cannot be disbursed");

    if (IERC20(_self.baseTokenAddress).balanceOf(address(this)) < loan.principal) {
      loanNFT.setStatus(_loanID, LoanStatus.FAILED_TO_DISBURSE);
      return 0;
    } else {
      IERC20 baseToken = IERC20(_self.baseTokenAddress);
      baseToken.transfer(borrower, loan.principal);
      loanNFT.disburse(_loanID);
      return loan.principal;
    }
  }

  function payLoan(
    LendingPoolStateData memory _self,
    uint256 _loanID,
    uint256 _amountPaid,
    address _copraGlobal,
    address _loanNFTAddress,
    address _originator
  )
    public
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    Loan memory loan = ILoanNFT(_loanNFTAddress).getLoan(_loanID);
    require(loan.status == LoanStatus.DISBURSED, "LoanTransactionLogic: loan not in disbursed state");
    // Prevent user from overpaying
    _amountPaid = _amountPaid > loan.balances.balance ? loan.balances.balance : _amountPaid;
    (uint256 amountToPool, uint256 amountToOriginator, uint256 amountToTreasury) = (ILoanNFT(_loanNFTAddress))
      .updateAmountPaid(_loanID, _amountPaid);

    // Transfer full repayment to pool first
    (IERC20(_self.baseTokenAddress)).transferFrom(loan.borrower, address(this), _amountPaid);

    // Transfer fees from pool to treasury and originator
    _payFees(amountToTreasury, amountToOriginator, _self.baseTokenAddress, _copraGlobal, _originator);

    return (amountToPool, amountToTreasury, amountToOriginator);
  }

  function _canLoanBeDisbursed(Loan memory _loan) private view returns (bool) {
    return block.timestamp >= _loan.disbursementDate && _loan.actualTimeDisbursed == 0;
  }

  function _payFees(
    uint256 _amountToTreasury,
    uint256 _amountToOriginator,
    address _baseTokenAddress,
    address _copraGlobal,
    address _originator
  ) internal {
    if (_amountToTreasury > 0) {
      ICopraGlobal copraGlobalContract = ICopraGlobal(_copraGlobal);
      address treasuryAddress = copraGlobalContract.getTreasuryAddress();
      (IERC20(_baseTokenAddress)).transfer(treasuryAddress, _amountToTreasury);
    }

    if (_amountToOriginator > 0) {
      (IERC20(_baseTokenAddress)).transfer(_originator, _amountToOriginator);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct LendingPoolConstraints {
  uint256 minReservePercentage;
  uint256 maxReservePercentage;
  uint256 minPoolJuniorTranchePercentage;
  uint256 maxPoolSize;
}

struct LendingPoolStateData {
  uint256 dailySeniorYield;
  uint256 seniorObligation;
  uint256 juniorValue;
  uint256 seniorValue;
  uint256 sCopTokenPrice;
  uint256 jCopTokenPrice;
  uint256 lastTimeSeniorObligationUpdated;
  bool isPoolActive;
  address baseTokenAddress;
  address jCopTokenAddress;
  address sCopTokenAddress;
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