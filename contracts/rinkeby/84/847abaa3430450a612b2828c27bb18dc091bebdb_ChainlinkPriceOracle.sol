// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../../common/BaseNonUpgradeable.sol";
import "../../common/libraries/Math.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/external/IChainlinkDataFeed.sol";

contract ChainlinkPriceOracle is IPriceOracle, BaseNonUpgradeable {
  address public immutable usdc;
  address public immutable weth;

  // base token => token a => feed
  mapping(address => mapping(address => address)) public feeds;

  constructor(
    address registry,
    address _usdc,
    address _weth,
    address[] memory tokenAs,
    address[] memory tokenBs,
    address[] memory dataFeeds
  ) BaseNonUpgradeable(registry) {
    require(tokenAs.length == tokenBs.length && tokenAs.length == dataFeeds.length);
    usdc = _usdc;
    weth = _weth;

    for (uint256 i; i < tokenAs.length; i++) {
      address a = tokenAs[i];
      address b = tokenBs[i];
      address dataFeed = dataFeeds[i];
      feeds[b][a] = dataFeed;
    }
  }

  /**
   * @notice Fetch the price of a, denominated in b
   * @return price Returns the price of a, denominated in b, with 18 decimal places
   */
  function getPrice(address a, address b) external view override returns (uint256) {
    address feed = _getFeed(a, b);

    if (feed != address(0)) {
      return _getPrice(feed);
    }

    uint256 price = _getDerivedPrice(a, b, usdc);
    if (price != 0) {
      return price;
    }

    price = _getDerivedPrice(a, b, weth);
    if (price != 0) {
      return price;
    }

    return 0;
  }

  /**
   * @notice Derive the price of a, denominated in b using multiple data feeds
   * @dev Chainlink Data Feeds can be used in combination to derive denominated
   *  price pairs in other currencies. For example, if you needed a AVAX / ETH price,
   *  you could take the AVAX / USD feed and the ETH / USD feed to derive AVAX / ETH.
   * @param a Address of token A
   * @param b Address of token B
   * @param altB Address of an alternative token B
   * @return price Returns the derived price of a, denominated in b, with 18 decimal places
   */
  function _getDerivedPrice(
    address a,
    address b,
    address altB
  ) internal view returns (uint256) {
    // Example: a = AVAX, b = ETH, altB = USDC

    // E.g. AVAX / USD feed
    address aToAltBFeed = _getFeed(a, altB);
    if (aToAltBFeed != address(0)) {
      // E.g. USD / ETH feed
      address altBToBFeed = _getFeed(altB, b);
      if (altBToBFeed != address(0)) {
        // E.g. Price of AVAX in USD
        uint256 priceInAltB = _getPrice(aToAltBFeed);
        // E.g. Price of USD in ETH
        uint256 altBToB = _getPrice(altBToBFeed);
        return Math.scaledMul(priceInAltB, altBToB, 18);
      }
      // E.g. ETH / USD feed
      address bToAltBFeed = _getFeed(b, altB);
      if (bToAltBFeed != address(0)) {
        // E.g. Price of AXAX in USD
        uint256 priceInAltB = _getPrice(aToAltBFeed);
        // E.g. Price of ETH in USD
        uint256 bToAltB = _getInvertedPrice(bToAltBFeed);
        return Math.scaledMul(priceInAltB, bToAltB, 18);
      }
    }

    return 0;
  }

  function _getFeed(address a, address b) internal view returns (address) {
    return feeds[b][a];
  }

  function _getPrice(address feed) internal view returns (uint256) {
    return Math.scale(uint256(IChainlinkDataFeed(feed).latestAnswer()), _getDecimals(feed), 18);
  }

  function _getInvertedPrice(address feed) internal view returns (uint256) {
    return Math.scaledDiv(1e18, _getPrice(feed), 18);
  }

  function _getDecimals(address feed) internal view returns (uint8) {
    return IChainlinkDataFeed(feed).decimals();
  }

  //==============================================================
  // Admin Actions
  //==============================================================
  function updateFeed(
    address a,
    address b,
    address feed
  ) external onlyAdmin {
    feeds[b][a] = feed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "../modules/shared-services/interfaces/IContractRegistry.sol";
import "../modules/shared-services/interfaces/IACL.sol";
import "./libraries/ErrorCodes.sol";

/**
 * @title The base contract for non-upgradeable, admin-aware contracts
 */
abstract contract BaseNonUpgradeable {
  IContractRegistry public immutable registry;

  constructor(address _registry) {
    registry = IContractRegistry(_registry);
  }

  modifier onlyOwner() {
    if (!IACL(registry.getACL()).isOwner(msg.sender)) {
      revert ErrorCodes.OnlyOwner();
    }
    _;
  }

  modifier onlyAdmin() {
    if (!IACL(registry.getACL()).isAdmin(msg.sender)) {
      revert ErrorCodes.OnlyAdmin();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library Math {
  /**
   * @notice Multiply two numbers with the same decimal places
   * @param x The first number to multiply
   * @param y The second number to multiply
   * @param d The number of decimals places for both numbers
   * @return z The result scaled to `d` decimal places
   */
  function scaledMul(
    uint256 x,
    uint256 y,
    uint8 d
  ) internal pure returns (uint256 z) {
    return scaledMul(x, y, d, d);
  }

  /**
   * @notice Multiply two numbers and scale the result to the number of decimals of the first number
   * @param x The first number to multiply
   * @param y The second number to multiply
   * @param xd The number of decimals of the first number. The result will be denominated to these decimal places
   * @param yd The number of decimals of the second number
   * @return z The result scaled to `xd` decimal places
   */
  function scaledMul(
    uint256 x,
    uint256 y,
    uint8 xd,
    uint8 yd
  ) internal pure returns (uint256 z) {
    return scaledMul(x, y, xd, yd, xd);
  }

  /**
   * @notice Multiply two numbers and scale the result to a specified number of decimals
   * @param x The first number to multiply
   * @param y The second number to multiply
   * @param xd The number of decimals of the first number
   * @param yd The number of decimals of the second number
   * @param d The number of decimals that the result should be denominated in
   * @return z The result scaled to `d` decimal places
   */
  function scaledMul(
    uint256 x,
    uint256 y,
    uint8 xd,
    uint8 yd,
    uint8 d
  ) internal pure returns (uint256 z) {
    return (x * y * mantissa(d)) / (mantissa(xd) * mantissa(yd));
  }

  /**
   * @notice Divide two numbers with the same decimal places
   * @param x The numerator
   * @param y The denominator
   * @param d The number of decimals places for both numbers
   * @return z The result scaled to `d` decimal places
   */
  function scaledDiv(
    uint256 x,
    uint256 y,
    uint8 d
  ) internal pure returns (uint256 z) {
    return scaledDiv(x, y, d, d);
  }

  /**
   * @notice Divide two numbers and scale the result to the number of decimals of the first number
   * @param x The numerator
   * @param y The denominator
   * @param xd The number of decimals of the numerator. The result will be denominated to these decimal places
   * @param yd The number of decimals of the denominator
   * @return z The result scaled to `xd` decimal places
   */
  function scaledDiv(
    uint256 x,
    uint256 y,
    uint8 xd,
    uint8 yd
  ) internal pure returns (uint256 z) {
    return scaledDiv(x, y, xd, yd, xd);
  }

  /**
   * @notice Divide two numbers and scale the result to a specified number of decimals
   * @param x The numerator
   * @param y The denominator
   * @param xd The number of decimals of the numerator
   * @param yd The number of decimals of the denominator
   * @param d The number of decimals that the result should be denominated in
   * @return z The result scaled to `d` decimal places
   */
  function scaledDiv(
    uint256 x,
    uint256 y,
    uint8 xd,
    uint8 yd,
    uint8 d
  ) internal pure returns (uint256 z) {
    return (x * mantissa(d) * mantissa(yd)) / (y * mantissa(xd));
  }

  /**
   * @notice Scale the number to a new decimal denomination
   * @param x The number
   * @param xd The number of decimals for the original number
   * @param d The number of decimals that the result should be denominated in
   */
  function scale(
    uint256 x,
    uint8 xd,
    uint8 d
  ) internal pure returns (uint256) {
    return (x * mantissa(d)) / mantissa(xd);
  }

  function mantissa(uint8 decimals) internal pure returns (uint256) {
    return uint256(10**decimals);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title Interface for a NIL Price Oracle
 */
interface IPriceOracle {
  /**
   * @notice Returns the price of token A, denominated in token B
   * @param a Address of token A
   * @param b Address of token B
   * @return price The price of token A, denominated in token B. Returns zero if we do not have price data for this pair.
   */
  function getPrice(address a, address b) external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title Minimal interface for a Chainlink Data Feed contract
 * @notice https://docs.chain.link/docs/using-chainlink-reference-contracts/
 */
interface IChainlinkDataFeed {
  function decimals() external view returns (uint8);

  function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title The interface for the NIL Contract Registry
 * @notice Main registry that stores contract addresses for the entire protocol
 *  @dev Owned by NIL Governance
 */
interface IContractRegistry {
  /**
   * @notice Emitted when a new address is set
   * @param id The contract id
   * @param oldAddress The old contract address
   * @param newAddress The new contract address
   */
  event AddressSet(bytes32 id, address oldAddress, address newAddress);

  /**
   * @notice The contract id for the Access Control contract
   */
  function ACL() external view returns (bytes32);

  /**
   * @notice Returns the address of the ACL contract
   * @return The address of the ACL contract
   */
  function getACL() external view returns (address);

  /**
   * @notice Updates the address of the Access Control contract
   * @param newACL The address of the new Access Control contract
   **/
  function setACL(address newACL) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @title The interface for NIL's Access Control functionality
 * @notice The main registry of system roles and permissions across the entire protocol
 * @dev Owned by NIL Governance
 */
interface IACL {
  /**
   * @notice Returns the identifier of the Admin role
   * @return The id of the Admin role
   */
  function ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns the identifier of the EmergencyAdmin role
   * @return The id of the EmergencyAdmin role
   */
  function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

  /**
   * @notice Returns true if the address is an admin, false otherwise
   * @param admin The address to check
   * @return True if the given address is an admin, false otherwise
   */
  function isAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new admin
   * @param admin The address of the new admin
   */
  function addAdmin(address admin) external;

  /**
   * @notice Removes an admin
   * @param admin The address of the admin to remove
   */
  function removeAdmin(address admin) external;

  /**
   * @notice Returns true if the address is an emergency admin, false otherwise
   * @param admin The address to check
   * @return True if the given address is an emergency admin, false otherwise
   */
  function isEmergencyAdmin(address admin) external view returns (bool);

  /**
   * @notice Adds a new emergency admin
   * @param emergencyAdmin The address of the new emergency admin
   */
  function addEmergencyAdmin(address emergencyAdmin) external;

  /**
   * @notice Removes an emergency admin
   * @param emergencyAdmin The address of the emergency admin to remove
   */
  function removeEmergencyAdmin(address emergencyAdmin) external;

  /**
   * @notice Returns true if the address is the protocol owner, false otherwise
   * @param owner The address to check
   * @return True if the given address is the protocol owner, false otherwise
   */
  function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

library ErrorCodes {
  /* ========== ACCESS CONTROL ========== */
  /// @notice Only the protocol owner may perform this action
  error OnlyOwner();

  /// @notice Only a protocol admin may perform this action
  error OnlyAdmin();

  /* ========== INVALID PARAMETERS ========== */
  /// @notice Cannot use the zero address
  error ZeroAddress();

  /// @notice The DEFAULT_ADMIN_ROLE cannot be set using `grantRole()`
  /// @dev Use `transferOwnership()` instead
  error CannotGrantRoleDefaultAdmin();
}