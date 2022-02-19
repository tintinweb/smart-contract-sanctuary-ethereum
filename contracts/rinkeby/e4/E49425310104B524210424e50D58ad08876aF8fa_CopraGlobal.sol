// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ICopraGlobal.sol";
import "./library/PercentLib.sol";

contract CopraGlobal is ICopraGlobal {
  using PercentLib for uint256;

  uint256 public globalWithdrawalFee;
  uint256 public globalOriginatorFee;
  uint256 public globalGovernanceFee;
  uint256 public proposePoolExpense;
  uint256 public maxLateDays;
  Expenses public expenses;

  address public treasuryAddress;
  address public timelockController;

  constructor(
    uint256 _globalWithdrawalFee,
    uint256 _globalOriginatorFee,
    uint256 _globalGovernanceFee,
    uint256 _maxLateDays,
    uint256 _proposePoolExpense,
    uint256 _listLoanExpense,
    address _treasuryAddress,
    address _timelockController
  ) {
    globalWithdrawalFee = _globalWithdrawalFee.toPercent();
    globalOriginatorFee = _globalOriginatorFee.toPercent();
    globalGovernanceFee = _globalGovernanceFee.toPercent();
    maxLateDays = _maxLateDays;
    expenses = Expenses({proposePool: _proposePoolExpense, listLoan: _listLoanExpense});
    treasuryAddress = _treasuryAddress;
    timelockController = _timelockController;
  }

  function getFees()
    external
    view
    override
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (globalWithdrawalFee, globalOriginatorFee, globalGovernanceFee);
  }

  function getTreasuryAddress() external view override returns (address) {
    return treasuryAddress;
  }

  function getMaxLateDays() external view override returns (uint256) {
    return maxLateDays;
  }

  function getExpenses() external view override returns (Expenses memory) {
    return expenses;
  }

  function setTreasuryAddress(address _treasury) external override {
    require(msg.sender == treasuryAddress, "not treasury");
    treasuryAddress = _treasury;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external override {
    _onlyTimelockController();
    globalWithdrawalFee = _withdrawalFee.toPercent();
  }

  function setOriginatorFee(uint256 _originatorFee) external override {
    _onlyTimelockController();
    globalOriginatorFee = _originatorFee.toPercent();
  }

  function setGovernanceFee(uint256 _governanceFee) external override {
    _onlyTimelockController();
    globalGovernanceFee = _governanceFee.toPercent();
  }

  function setListLoanExpense(uint256 _listLoanExpense) external override {
    _onlyTimelockController();
    expenses.listLoan = _listLoanExpense;
  }

  function setProposePoolExpense(uint256 _proposePoolExpense) external override {
    _onlyTimelockController();
    expenses.proposePool = _proposePoolExpense;
  }

  function setMaxLateDays(uint256 _maxLateDays) external override {
    _onlyTimelockController();
    maxLateDays = _maxLateDays;
  }

  function _onlyTimelockController() internal view {
    require(msg.sender == timelockController, "CopraGlobal: Not timelock controller");
  }
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

import "./DSMath.sol";

library PercentLib {
  using DSMath for uint256;

  function toPercent(uint256 _num) internal pure returns (uint256) {
    return _num.wdiv(uint256(100).toWAD());
  }
}