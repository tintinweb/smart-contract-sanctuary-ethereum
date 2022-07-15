// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IAddressRegistry} from "./IAddressRegistry.sol";

abstract contract AddressResolver {
  IAddressRegistry public addressRegistry;

  constructor(address _registry) {
    addressRegistry = IAddressRegistry(_registry);
  }

  function _resolve(string memory _contractName) internal view returns (address) {
    return addressRegistry.get(_contractName);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAddressRegistry {
  function register(string calldata _name, address _address) external;

  function updateController(address _newController) external;

  function get(string calldata _name) external view returns (address);

  function getController() external view returns (address);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ILPTokenDeployer {
  function deploy(
    string calldata _name,
    string calldata _symbol,
    address _lpAddress
  ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./libraries/types.sol";

enum Tranche {
  JUNIOR,
  SENIOR
}

struct LoanRegistrationParams {
  uint256 loanTenorSeconds;
  uint256 gracePeriodSeconds;
  uint256 principal;
  uint256 lateFee;
  uint256 disbursementDate;
  uint256 dailyRate;
  address borrowerAddress;
  string purpose;
  string description;
}

struct PoolUpdateParams {
  uint256[] updatedLoanIDs;
  Loan[] loansToUpdate;
  uint256 totalActiveLoanValue;
  uint256 numLoansUpdated;
  uint256 updatedSeniorObligation;
  bool isLastUpdate;
}

enum LoanStatus {
  REGISTERED,
  DISBURSED,
  ACTIVE,
  CLOSED,
  DEFAULTED,
  FAILED_TO_DISBURSE
}

struct Loan {
  uint256 globalLoanID;
  uint256 loanTenorSeconds;
  uint256 gracePeriodSeconds;
  uint256 principal;
  uint256 amountRepaid;
  uint256 lateFee;
  uint256 disbursementDate;
  uint256 actualTimeDisbursed;
  uint256 dailyRate;
  uint256 timeActivated;
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

interface ILendingPoolRegistry {
  function whitelistPool(
    address _lpAddress,
    string memory _jCopName,
    string memory _jCopSymbol,
    string memory _sCopName,
    string memory _sCopSymbol
  ) external;

  function closePool(address _lpAddress) external;

  function openPool(address _lpAddress) external;

  function registerPool(address _lpAddress) external;

  function isWhitelisted(address _lpAddress) external view returns (bool);

  function getNumWhitelistedPools() external view returns (uint256);

  function getPools() external view returns (address[] memory);

  function isRegisteredPool(address _lpAddress) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ILendingPoolRegistry} from "./ILendingPoolRegistry.sol";
import {ILendingPool} from "../lendingPool/ILendingPool.sol";
import {AddressResolver} from "../AddressResolver.sol";
import {ILPTokenDeployer} from "../deployers/ILPTokenDeployer.sol";
import {ICopraGlobal} from "../ICopraGlobal.sol";

contract LendingPoolRegistry is ILendingPoolRegistry, AddressResolver {
  using Counters for Counters.Counter;

  string private constant COPRA_GLOBAL = "CopraGlobal";
  Counters.Counter private numWhitelistedPools;

  mapping(address => bool) public lendingPoolExists;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public poolIds;
  address[] public pools;

  event LendingPoolWhitelisted(address _lpAddress, address _jCopAddress, address _sCopAddress);
  event LendingPoolClosed(address _lpAddress);

  error NotMultisig();
  error NonExistentPool();
  error WhitelistedPool();

  modifier onlyMultisig() {
    ICopraGlobal copGlobal = ICopraGlobal(_resolve(COPRA_GLOBAL));
    if (msg.sender != copGlobal.getTreasuryAddress()) {
      revert NotMultisig();
    }
    _;
  }

  modifier isValidPool(address _lpAddress) {
    if (!lendingPoolExists[_lpAddress]) {
      revert NonExistentPool();
    }
    _;
  }

  constructor(address _addressRegistry) AddressResolver(_addressRegistry) {}

  function whitelistPool(
    address _lpAddress,
    string memory _jCopName,
    string memory _jCopSymbol,
    string memory _sCopName,
    string memory _sCopSymbol
  ) external override isValidPool(_lpAddress) onlyMultisig {
    if (whitelist[_lpAddress]) {
      revert WhitelistedPool();
    }
    whitelist[_lpAddress] = true;
    numWhitelistedPools.increment();
    ILPTokenDeployer lpTokenDeployer = ILPTokenDeployer(_resolve("LPTokenDeployer"));
    address jCopTokenAddress = lpTokenDeployer.deploy(_jCopName, _jCopSymbol, _lpAddress);
    address sCopTokenAddress = lpTokenDeployer.deploy(_sCopName, _sCopSymbol, _lpAddress);
    (ILendingPool(_lpAddress)).init(jCopTokenAddress, sCopTokenAddress);
    emit LendingPoolWhitelisted(_lpAddress, jCopTokenAddress, sCopTokenAddress);
  }

  function closePool(address _lpAddress) external override isValidPool(_lpAddress) onlyMultisig {
    whitelist[_lpAddress] = false;
    emit LendingPoolClosed(_lpAddress);
  }

  function openPool(address _lpAddress) external override isValidPool(_lpAddress) onlyMultisig {
    whitelist[_lpAddress] = true;
  }

  function registerPool(address _lpAddress) external override {
    lendingPoolExists[_lpAddress] = true;
    poolIds[_lpAddress] = pools.length;
    pools.push(_lpAddress);
  }

  function isWhitelisted(address _lpAddress) external view override returns (bool) {
    return whitelist[_lpAddress];
  }

  function getNumWhitelistedPools() external view override returns (uint256) {
    return numWhitelistedPools.current();
  }

  function getPools() external view override returns (address[] memory) {
    return pools;
  }

  function isRegisteredPool(address _lpAddress) external view override returns (bool) {
    return lendingPoolExists[_lpAddress];
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
  uint256 totalNonActiveLoanValue;
  uint256 totalActiveLoanValue;
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