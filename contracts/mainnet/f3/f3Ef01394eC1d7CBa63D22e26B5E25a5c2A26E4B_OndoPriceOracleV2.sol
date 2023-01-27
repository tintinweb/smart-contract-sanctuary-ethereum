// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "contracts/cash/external/openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    _transferOwnership(_msgSender());
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

/// @notice Taken from contracts/lending/compound/PriceOracle.sol
interface PriceOracle {
  /**
   * @notice Get the underlying price of a fToken asset
   * @param fToken The fToken to get the underlying price of
   * @return The underlying asset price mantissa (scaled by 1e18).
   */
  function getUnderlyingPrice(address fToken) external view returns (uint);
}

interface IOndoPriceOracle is PriceOracle {
  function setPrice(address fToken, uint256 price) external;

  function setFTokenToCToken(address fToken, address cToken) external;

  function setOracle(address newOracle) external;

  /**
   * @dev Event for when a fToken to cToken association is set
   *
   * @param fToken    fToken address
   * @param oldCToken Old cToken association
   * @param newCToken New cToken association
   */
  event FTokenToCTokenSet(
    address indexed fToken,
    address oldCToken,
    address newCToken
  );

  /**
   * @dev Event for when a fToken's underlying asset's price is set
   *
   * @param fToken   fToken address
   * @param oldPrice Old underlying asset's price
   * @param newPrice New underlying asset's price
   */
  event UnderlyingPriceSet(
    address indexed fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  /**
   * @dev Event for when the cToken oracle is set
   *
   * @param oldOracle Old cToken oracle
   * @param newOracle New cToken oracle
   */
  event CTokenOracleSet(address oldOracle, address newOracle);
}

interface IOndoPriceOracleV2 is IOndoPriceOracle {
  /// @notice Enum denoting where the price of an fToken is coming from
  enum OracleType {
    UNINITIALIZED,
    MANUAL,
    COMPOUND,
    CHAINLINK
  }

  function setPriceCap(address fToken, uint256 value) external;

  function setFTokenToChainlinkOracle(
    address fToken,
    address newChainlinkOracle,
    uint256 maxChainlinkOracleTimeDelay
  ) external;

  function setFTokenToOracleType(
    address fToken,
    OracleType oracleType
  ) external;

  /**
   * @dev Event for when a price cap is set on an fToken's underlying assset
   *
   * @param fToken      fToken address
   * @param oldPriceCap Old price cap
   * @param newPriceCap New price cap
   */
  event PriceCapSet(
    address indexed fToken,
    uint256 oldPriceCap,
    uint256 newPriceCap
  );

  /**
   * @dev Event for when chainlink Oracle is set
   *
   * @param fToken                      fToken address
   * @param oldOracle                   The old chainlink oracle
   * @param newOracle                   The new chainlink oracle
   * @param maxChainlinkOracleTimeDelay The max time delay for the chainlink oracle
   */
  event ChainlinkOracleSet(
    address indexed fToken,
    address oldOracle,
    address newOracle,
    uint256 maxChainlinkOracleTimeDelay
  );

  /**
   * @dev Event for when a fToken to chainlink oracle association is set
   *
   * @param fToken     fToken address
   * @param oracleType New oracle association
   */
  event FTokenToOracleTypeSet(address indexed fToken, OracleType oracleType);
}

/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "./IOndoPriceOracleV2.sol";
import "contracts/cash/external/openzeppelin/contracts/access/Ownable.sol";
import "contracts/lending/chainlink/AggregatorV3Interface.sol";

/// @notice Interface for generalizing different cToken oracles
interface CTokenOracle {
  function getUnderlyingPrice(address cToken) external view returns (uint256);
}

/// @notice Helper interface for standardizing comnmon calls to
///         fTokens and cTokens
interface CTokenLike {
  function underlying() external view returns (address);
}

/// @notice Helper interface for interacting with underlying assets
///         that are ERC20 compliant
interface IERC20Like {
  function decimals() external view returns (uint8);
}

/**
 * @title OndoPriceOracleV2
 * @author Ondo Finance
 * @notice This contract acts as a custom price oracle for the Flux lending
 *         market protocol. It allows for the owner to set the underlying price
 *         directly in contract storage, to set an fToken-to-cToken
 *         association for price retrieval using Compound's oracle, and
 *         to set an association between an fToken and a Chainlink
 *         oracle for price retrieval. It also allows the owner to
 *         set a price ceiling (a.k.a "cap") on an fToken's underlying asset.
 */
contract OndoPriceOracleV2 is IOndoPriceOracleV2, Ownable {
  /// @notice Initially set to contracts/lending/compound/uniswap/UniswapAnchoredView.sol
  CTokenOracle public cTokenOracle =
    CTokenOracle(0x50ce56A3239671Ab62f185704Caedf626352741e);

  /// @notice fToken to Oracle Type association
  mapping(address => OracleType) public fTokenToOracleType;

  /// @notice Contract storage for fToken's underlying asset prices
  mapping(address => uint256) public fTokenToUnderlyingPrice;

  /// @notice fToken to cToken associations for piggy backing off
  ///         of Compound's Oracle
  mapping(address => address) public fTokenToCToken;

  struct ChainlinkOracleInfo {
    AggregatorV3Interface oracle;
    uint256 scaleFactor;
    uint256 maxChainlinkOracleTimeDelay;
  }

  /// @notice fToken to Chainlink oracle association
  mapping(address => ChainlinkOracleInfo) public fTokenToChainlinkOracle;

  /// @notice Price cap for the underlying asset of an fToken. Optional.
  mapping(address => uint256) public fTokenToUnderlyingPriceCap;

  /**
   * @notice Retrieve the price of the provided fToken
   *         contract's underlying asset
   *
   * @param fToken fToken contract address
   *
   * @dev This function attempts to retrieve the price based on the associated
   *      `OracleType`. This can mean retrieving from Compound's oracle, a
   *      Chainlink oracle, or even a price set manually within contract
   *      storage. It will cap the price if a price cap is set in
   *      `fTokenToUnderlyingPriceCap`.
   * @dev Only supports oracle prices denominated in USD
   */
  function getUnderlyingPrice(
    address fToken
  ) external view override returns (uint256) {
    uint256 price;

    // Get price of fToken depending on OracleType
    OracleType oracleType = fTokenToOracleType[fToken];
    if (oracleType == OracleType.MANUAL) {
      // Get price stored in contract storage
      price = fTokenToUnderlyingPrice[fToken];
    } else if (oracleType == OracleType.COMPOUND) {
      // Get associated cToken and call Compound oracle
      address cTokenAddress = fTokenToCToken[fToken];
      price = cTokenOracle.getUnderlyingPrice(cTokenAddress);
    } else if (oracleType == OracleType.CHAINLINK) {
      // Get price from Chainlink oracle
      price = getChainlinkOraclePrice(fToken);
    } else {
      revert("Oracle type not supported");
    }

    // If price cap is set, take the min.
    if (fTokenToUnderlyingPriceCap[fToken] > 0) {
      price = _min(price, fTokenToUnderlyingPriceCap[fToken]);
    }

    return price;
  }

  /*//////////////////////////////////////////////////////////////
                   Price Cap & Oracle Type Setter
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the price cap for the provided fToken's underlying asset
   *
   * @param fToken fToken contract address
   */
  function setPriceCap(
    address fToken,
    uint256 value
  ) external override onlyOwner {
    uint256 oldPriceCap = fTokenToUnderlyingPriceCap[fToken];
    fTokenToUnderlyingPriceCap[fToken] = value;
    emit PriceCapSet(fToken, oldPriceCap, value);
  }

  /**
   * @notice Sets the oracle type for the provided fToken
   *
   * @param fToken     fToken contract address
   * @param oracleType Oracle Type of fToken
   */
  function setFTokenToOracleType(
    address fToken,
    OracleType oracleType
  ) external override onlyOwner {
    fTokenToOracleType[fToken] = oracleType;
    emit FTokenToOracleTypeSet(fToken, oracleType);
  }

  /*//////////////////////////////////////////////////////////////
                            Manual Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the price of an fToken contract's underlying asset
   *
   * @param fToken fToken contract address
   * @param price  New price of underlying asset
   */
  function setPrice(address fToken, uint256 price) external override onlyOwner {
    require(
      fTokenToOracleType[fToken] == OracleType.MANUAL,
      "OracleType must be Manual"
    );
    uint256 oldPrice = fTokenToUnderlyingPrice[fToken];
    fTokenToUnderlyingPrice[fToken] = price;
    emit UnderlyingPriceSet(fToken, oldPrice, price);
  }

  /*//////////////////////////////////////////////////////////////
                          Compound Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Sets the external oracle address for Compound oracleType
   *
   * @param newOracle cToken oracle contract address
   */
  function setOracle(address newOracle) external override onlyOwner {
    address oldOracle = address(cTokenOracle);
    cTokenOracle = CTokenOracle(newOracle);
    emit CTokenOracleSet(oldOracle, newOracle);
  }

  /**
   * @notice Associates a custom fToken with an external cToken
   *
   * @param fToken fToken contract address
   * @param cToken cToken contract address
   */
  function setFTokenToCToken(
    address fToken,
    address cToken
  ) external override onlyOwner {
    address oldCToken = fTokenToCToken[fToken];
    _setFTokenToCToken(fToken, cToken);
    emit FTokenToCTokenSet(fToken, oldCToken, cToken);
  }

  /**
   * @notice Private implementation function for setting fToken
   *         to cToken implementation
   *
   * @param fToken fToken contract address
   * @param cToken cToken contract address
   */
  function _setFTokenToCToken(address fToken, address cToken) internal {
    require(
      fTokenToOracleType[fToken] == OracleType.COMPOUND,
      "OracleType must be Compound"
    );
    require(
      CTokenLike(fToken).underlying() == CTokenLike(cToken).underlying(),
      "cToken and fToken must have the same underlying asset"
    );
    fTokenToCToken[fToken] = cToken;
  }

  /*//////////////////////////////////////////////////////////////
                          Chainlink Oracle
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Associates a custom fToken with a Chainlink oracle
   *
   * @param fToken                      fToken contract address
   * @param newChainlinkOracle          Chainlink oracle address
   * @param maxChainlinkOracleTimeDelay Max time delay in seconds for chainlink oracle
   *
   */
  function setFTokenToChainlinkOracle(
    address fToken,
    address newChainlinkOracle,
    uint256 maxChainlinkOracleTimeDelay
  ) external override onlyOwner {
    address oldChainlinkOracle = address(
      fTokenToChainlinkOracle[fToken].oracle
    );
    _setFTokenToChainlinkOracle(
      fToken,
      newChainlinkOracle,
      maxChainlinkOracleTimeDelay
    );
    emit ChainlinkOracleSet(
      fToken,
      oldChainlinkOracle,
      newChainlinkOracle,
      maxChainlinkOracleTimeDelay
    );
  }

  /**
   * @notice Internal implementation function for setting fToken to
   *         chainlinkOracle implementation
   *
   * @param fToken                      fToken contract address
   * @param chainlinkOracle             Chainlink oracle address
   * @param maxChainlinkOracleTimeDelay Max time delay in seconds for chainlink oracle
   *
   */
  function _setFTokenToChainlinkOracle(
    address fToken,
    address chainlinkOracle,
    uint256 maxChainlinkOracleTimeDelay
  ) internal {
    require(
      fTokenToOracleType[fToken] == OracleType.CHAINLINK,
      "OracleType must be Chainlink"
    );
    address underlying = CTokenLike(fToken).underlying();
    fTokenToChainlinkOracle[fToken].scaleFactor = (10 **
      (36 -
        uint256(IERC20Like(underlying).decimals()) -
        uint256(AggregatorV3Interface(chainlinkOracle).decimals())));
    fTokenToChainlinkOracle[fToken].oracle = AggregatorV3Interface(
      chainlinkOracle
    );
    fTokenToChainlinkOracle[fToken]
      .maxChainlinkOracleTimeDelay = maxChainlinkOracleTimeDelay;
  }

  /**
   * @notice Retrieve price of fToken's underlying asset from a Chainlink
   *         oracle
   *
   * @param fToken fToken contract address
   *
   * @dev This function is public for observability purposes only.
   */
  function getChainlinkOraclePrice(
    address fToken
  ) public view returns (uint256) {
    require(
      fTokenToOracleType[fToken] == OracleType.CHAINLINK,
      "fToken is not configured for Chainlink oracle"
    );
    ChainlinkOracleInfo storage chainlinkInfo = fTokenToChainlinkOracle[fToken];
    (
      uint80 roundId,
      int answer,
      ,
      uint updatedAt,
      uint80 answeredInRound
    ) = chainlinkInfo.oracle.latestRoundData();
    require(
      (answeredInRound >= roundId) &&
        (updatedAt >=
          block.timestamp - chainlinkInfo.maxChainlinkOracleTimeDelay),
      "Chainlink oracle price is stale"
    );
    require(answer >= 0, "Price cannot be negative");
    // Scale to decimals needed in Comptroller (18 decimal underlying -> 18 decimals; 6 decimal underlying -> 30 decimals)
    // Scales by same conversion factor as in Compound Oracle
    return uint256(answer) * chainlinkInfo.scaleFactor;
  }

  /*//////////////////////////////////////////////////////////////
                                Utils
  //////////////////////////////////////////////////////////////*/

  function _min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}