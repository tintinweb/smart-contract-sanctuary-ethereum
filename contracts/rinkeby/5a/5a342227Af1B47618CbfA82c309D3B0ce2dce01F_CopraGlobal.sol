// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ICopraGlobal, Expenses} from "./ICopraGlobal.sol";

contract CopraGlobal is ICopraGlobal {
  uint256 private globalWithdrawalFee;
  uint256 private globalOriginatorFee;
  uint256 private globalGovernanceFee;
  uint256 private proposePoolExpense;
  uint256 private maxLateDays;
  bool private isProtocolActivated;
  Expenses private expenses;

  address private multiSig;
  address private timelockController;

  mapping(address => bool) public whitelistedUsers;

  modifier onlyTimelockController() {
    require(msg.sender == timelockController, "not timelock controller");
    _;
  }

  modifier onlyMultisig() {
    require(msg.sender == multiSig, "not multisig");
    _;
  }

  constructor(
    uint256 _globalWithdrawalFee,
    uint256 _globalOriginatorFee,
    uint256 _globalGovernanceFee,
    uint256 _maxLateDays,
    uint256 _proposePoolExpense,
    uint256 _listLoanExpense,
    address _multiSig,
    address _timelockController
  ) {
    globalWithdrawalFee = _globalWithdrawalFee;
    globalOriginatorFee = _globalOriginatorFee;
    globalGovernanceFee = _globalGovernanceFee;
    maxLateDays = _maxLateDays;
    expenses = Expenses({proposePool: _proposePoolExpense, listLoan: _listLoanExpense});
    multiSig = _multiSig;
    isProtocolActivated = true;
    timelockController = _timelockController;
  }

  function setTreasuryAddress(address _treasury) external override {
    require(msg.sender == multiSig, "not treasury");
    multiSig = _treasury;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external override onlyTimelockController {
    globalWithdrawalFee = _withdrawalFee;
  }

  function setOriginatorFee(uint256 _originatorFee) external override onlyTimelockController {
    globalOriginatorFee = _originatorFee;
  }

  function setGovernanceFee(uint256 _governanceFee) external override onlyTimelockController {
    globalGovernanceFee = _governanceFee;
  }

  function setListLoanExpense(uint256 _listLoanExpense) external override onlyTimelockController {
    expenses.listLoan = _listLoanExpense;
  }

  function setProposePoolExpense(uint256 _proposePoolExpense) external override onlyTimelockController {
    expenses.proposePool = _proposePoolExpense;
  }

  function setIsProtocolActive(bool _isProtocolActive) external override onlyMultisig {
    isProtocolActivated = _isProtocolActive;
  }

  function setMaxLateDays(uint256 _maxLateDays) external override onlyTimelockController {
    maxLateDays = _maxLateDays;
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
    return multiSig;
  }

  function getMaxLateDays() external view override returns (uint256) {
    return maxLateDays;
  }

  function getExpenses() external view override returns (Expenses memory) {
    return expenses;
  }

  function isWhitelistedUser(address _user) external view override returns (bool) {
    return whitelistedUsers[_user];
  }

  function toggleWhitelistedUser(address _user) external override {
    require(msg.sender == multiSig, "not multisig");
    whitelistedUsers[_user] = !whitelistedUsers[_user];
  }

  function isProtocolActive() external view override returns (bool) {
    return isProtocolActivated;
  }

  function getTimelockController() external view override returns (address) {
    return timelockController;
  }
}

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