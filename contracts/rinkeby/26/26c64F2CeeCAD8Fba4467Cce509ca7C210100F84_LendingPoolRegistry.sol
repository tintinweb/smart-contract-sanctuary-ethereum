// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./ILendingPoolRegistry.sol";
import "./ILendingPoolInitializer.sol";
import "../lendingPool/ILendingPool.sol";
import "../library/DSMath.sol";

contract LendingPoolRegistry is ILendingPoolRegistry {
  using Counters for Counters.Counter;
  using DSMath for uint256;

  Counters.Counter private numWhitelistedPools;

  mapping(address => bool) public lendingPoolExists;
  mapping(address => bool) public whitelist;
  mapping(address => uint256) public poolIds;
  address[] public pools;
  address public timelockControllerAddress;
  address public lendingPoolInitializer;

  event LendingPoolWhitelisted(address _lpAddress, address _jCopAddress, address _sCopAddress);
  event LendingPoolClosed(address _lpAddress);
  event LendingPoolProposed(
    address _lpAddress,
    uint256 _endTimeInEpochS,
    bool _isTryingToWhitelist,
    uint256 _proposalId,
    address _proposalAddress
  );

  modifier onlyTimelockController() {
    require(msg.sender == timelockControllerAddress, "Only the timelock controller contract may execute this action");
    _;
  }

  modifier isValidPool(address _lpAddress) {
    require(lendingPoolExists[_lpAddress], "Invalid Lending Pool address");
    _;
  }

  constructor(address _timelockControllerAddress) {
    timelockControllerAddress = _timelockControllerAddress;
  }

  function setLendingPoolInitializer(address _lendingPoolInitializer) external {
    require(lendingPoolInitializer == address(0), "Initializer already set");
    lendingPoolInitializer = _lendingPoolInitializer;
  }

  function whitelistPool(
    address _lpAddress,
    string calldata _jCopName,
    string calldata _jCopSymbol,
    string calldata _sCopName,
    string calldata _sCopSymbol
  ) external override isValidPool(_lpAddress) onlyTimelockController {
    require(!whitelist[_lpAddress], "LP already whitelisted");
    require(lendingPoolInitializer != address(0), "initializer not set");
    whitelist[_lpAddress] = true;
    numWhitelistedPools.increment();
    (address jCopAddress, address sCopAddress) = (ILendingPoolInitializer(lendingPoolInitializer)).initPool(
      _lpAddress,
      _jCopName,
      _jCopSymbol,
      _sCopName,
      _sCopSymbol
    );
    emit LendingPoolWhitelisted(_lpAddress, jCopAddress, sCopAddress);
  }

  function closePool(address _lpAddress) external override isValidPool(_lpAddress) onlyTimelockController {
    whitelist[_lpAddress] = false;
    emit LendingPoolClosed(_lpAddress);
  }

  function openPool(address _lpAddress) external override isValidPool(_lpAddress) onlyTimelockController {
    whitelist[_lpAddress] = true;
    emit LendingPoolClosed(_lpAddress);
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

interface ILendingPoolRegistry {
  function whitelistPool(
    address _lpAddress,
    string calldata _jCopName,
    string calldata _jCopSymbol,
    string calldata _sCopName,
    string calldata _sCopSymbol
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
pragma solidity ^0.8.4;

interface ILendingPoolInitializer {
  function initPool(
    address _lpAddress,
    string memory jCopName,
    string memory jCopSymbol,
    string memory sCopName,
    string memory sCopSymbol
  ) external returns (address, address);
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