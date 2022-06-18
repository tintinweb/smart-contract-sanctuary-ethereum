// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ICopraGlobal} from "./ICopraGlobal.sol";

contract CopraGlobal is ICopraGlobal {
  uint256 private globalWithdrawalFee;
  uint256 private globalOriginatorFee;
  uint256 private globalGovernanceFee;
  uint256 private maxLoanDelayDays;
  uint256 private maxLateDays;
  bool private isProtocolActivated;

  address private multiSig;

  mapping(address => bool) public whitelistedUsers;

  error NotMultisig();

  modifier onlyMultisig() {
    if (msg.sender != multiSig) {
      revert NotMultisig();
    }
    _;
  }

  constructor(
    uint256 _globalWithdrawalFee,
    uint256 _globalOriginatorFee,
    uint256 _globalGovernanceFee,
    uint256 _maxLoanDelayDays,
    uint256 _maxLateDays,
    address _multiSig
  ) {
    globalWithdrawalFee = _globalWithdrawalFee;
    globalOriginatorFee = _globalOriginatorFee;
    globalGovernanceFee = _globalGovernanceFee;
    maxLoanDelayDays = _maxLoanDelayDays;
    maxLateDays = _maxLateDays;
    multiSig = _multiSig;
    isProtocolActivated = true;
  }

  function setMaxLoanDelayDays(uint256 _newMaxLoanLateDelayDays) external onlyMultisig {
    maxLoanDelayDays = _newMaxLoanLateDelayDays;
  }

  function setTreasuryAddress(address _treasury) external override onlyMultisig {
    multiSig = _treasury;
  }

  function setWithdrawalFee(uint256 _withdrawalFee) external override onlyMultisig {
    globalWithdrawalFee = _withdrawalFee;
  }

  function setOriginatorFee(uint256 _originatorFee) external override onlyMultisig {
    globalOriginatorFee = _originatorFee;
  }

  function setGovernanceFee(uint256 _governanceFee) external override onlyMultisig {
    globalGovernanceFee = _governanceFee;
  }

  function setIsProtocolActive(bool _isProtocolActive) external override onlyMultisig {
    isProtocolActivated = _isProtocolActive;
  }

  function setMaxLateDays(uint256 _maxLateDays) external override onlyMultisig {
    maxLateDays = _maxLateDays;
  }

  function toggleWhitelistedUser(address _user) external override onlyMultisig {
    whitelistedUsers[_user] = !whitelistedUsers[_user];
  }

  function getMaxLoanDelayDays() external view override returns (uint256) {
    return maxLoanDelayDays;
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

  function isWhitelistedUser(address _user) external view override returns (bool) {
    return whitelistedUsers[_user];
  }

  function isProtocolActive() external view override returns (bool) {
    return isProtocolActivated;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ICopraGlobal {
  function setMaxLoanDelayDays(uint256 _newMaxLoanLateDelayDays) external;

  function setIsProtocolActive(bool _isProtocolActive) external;

  function setMaxLateDays(uint256 _maxLateDays) external;

  function setWithdrawalFee(uint256 _withdrawalFee) external;

  function setOriginatorFee(uint256 _originatorFee) external;

  function setGovernanceFee(uint256 _governanceFee) external;

  function setTreasuryAddress(address _treasury) external;

  function toggleWhitelistedUser(address _user) external;

  function getMaxLoanDelayDays() external view returns (uint256);

  function getFees()
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function isProtocolActive() external view returns (bool);

  function getTreasuryAddress() external view returns (address);

  function getMaxLateDays() external view returns (uint256);

  function isWhitelistedUser(address _user) external view returns (bool);
}