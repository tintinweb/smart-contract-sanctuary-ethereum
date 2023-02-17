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

import "contracts/cash/external/openzeppelin/contracts/access/Ownable.sol";
import "contracts/cash/interfaces/IMulticall.sol";
import "./IOndoPriceOracleV2.sol";

/// @notice Helper interface for checking fTokens.
interface CTokenInterface {
  function isCToken() external returns (bool);
}

/**
 * @title FTokenOracleSafetyWrapper
 * @author Ondo Finance
 * @notice This contract is a safety wrapper to prevent errors in when
 *         inputting fToken underlying price into a price oracle.
 *         This contract enforces that the price doesn't change more than
 *         `priceDeltaTolerances[fToken]` in a single transaction.
 *
 * @dev Usage could be the following batched transactions:
 *      1. `ondoPriceOracle.transferOwnership(<this contract>)
 *      2. FTokenOracleSafetyWrapper(<this contract>).setPriceSafe(<new price>)
 *      3. FTokenOracleSafetyWrapper(<this contract>).relinquishOracleOwnershipToOwner()
 */
contract FTokenOracleSafetyWrapper is Ownable, IMulticall {
  // Price oracle being wrapped
  IOndoPriceOracleV2 public constant ondoPriceOracle =
    IOndoPriceOracleV2(0xBa9B10f90B0ef26711373A0D8B6e7741866a7ef2);

  // Helper constant for basis point calculations
  uint256 public constant BPS_DENOMINATOR = 10_000;

  // Storage for fToken -> last price delta tolerance in bps
  mapping(address => uint256) public priceDeltaTolerances;

  /**
   * @notice Event emitted when price delta tolerance is set
   *
   * @param oldTolerance Old price tolerance
   * @param newTolerance New price tolerance
   */
  event DeltaPriceToleranceSet(uint256 oldTolerance, uint256 newTolerance);

  /**
   * @notice Event emitted when price safety check passess
   *
   * @param fToken   fToken whose underlying price was set
   * @param oldPrice Old price
   * @param newPrice New price
   */
  event PriceSafetyCheckPassed(
    address fToken,
    uint256 oldPrice,
    uint256 newPrice
  );

  /**
   * @notice Sets the delta tolerance that constrains price changes
   *         within a single function call.
   *
   * @param fToken       fToken address, whose underlying asset we set the
   *                     delta tolerance for
   * @param toleranceBPS Delta tolerance in BPS
   */
  function setDeltaPriceTolerances(
    address fToken,
    uint256 toleranceBPS
  ) external onlyOwner {
    require(CTokenInterface(fToken).isCToken(), "Incompatible fToken");
    require(toleranceBPS <= BPS_DENOMINATOR, "tolerance can not exceed 100%");
    uint256 oldTolerance = priceDeltaTolerances[fToken];
    priceDeltaTolerances[fToken] = toleranceBPS;
    emit DeltaPriceToleranceSet(oldTolerance, toleranceBPS);
  }

  /**
   * @notice Set an fToken's underlying price within `ondoPriceOracle`'s
   *         after performing safety checks.
   * @param fToken           fToken whose underlying's price is being set
   * @param price            New price for `fToken`'s underlying asset
   * @param ignoreDeltaCheck Whether or not to bypass the check if the
   *                         fToken's underlying asset price is set to 0
   *
   * @dev For the very first price setting of a specific fToken's underlying
   *      asset `ignoreDeltaCheck` should be set to true as to not compare
   *      against an uninitialized price.
   */
  function setPriceSafe(
    address fToken,
    uint256 price,
    bool ignoreDeltaCheck
  ) external onlyOwner {
    require(priceDeltaTolerances[fToken] > 0, "Delta tolerance not set");
    uint256 lastPrice = ondoPriceOracle.getUnderlyingPrice(fToken);
    uint256 priceDelta = _abs(price, lastPrice);
    if (!(lastPrice == 0 && ignoreDeltaCheck)) {
      uint256 maxToleratedPriceDelta = (lastPrice *
        priceDeltaTolerances[fToken]) / BPS_DENOMINATOR;
      require(
        priceDelta <= maxToleratedPriceDelta,
        "Price exceeds delta tolerance"
      );
    }
    ondoPriceOracle.setPrice(fToken, price);
    emit PriceSafetyCheckPassed(fToken, lastPrice, price);
  }

  /// @notice Set `ondoPriceOracle`'s owner to the owner of this contract.
  function relinquishOracleOwnershipToOwner() external onlyOwner {
    Ownable(address(ondoPriceOracle)).transferOwnership(owner());
  }

  /// @notice gets the absolute value of the difference between a and b
  function _abs(uint256 a, uint256 b) private pure returns (uint256 diff) {
    if (a > b) {
      diff = a - b;
    } else {
      diff = b - a;
    }
  }

  /**
   * @notice Allows for arbitrary batched calls
   *
   * @dev All external calls made through this function will
   *      msg.sender == contract address
   *
   * @param exCallData Struct consisting of
   *       1) target - contract to call
   *       2) data - data to call target with
   *       3) value - eth value to call target with
   */
  function multiexcall(
    ExCallData[] calldata exCallData
  ) external payable override onlyOwner returns (bytes[] memory results) {
    results = new bytes[](exCallData.length);
    for (uint256 i = 0; i < exCallData.length; ++i) {
      (bool success, bytes memory ret) = address(exCallData[i].target).call{
        value: exCallData[i].value
      }(exCallData[i].data);
      require(success, "Call Failed");
      results[i] = ret;
    }
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

/**
 * @title IMulticall
 * @author Ondo Finance
 * @notice This interface dictates the required external functions for Ondo's
 *         multicall contract.
 */
interface IMulticall {
  /// @dev External call data structure
  struct ExCallData {
    // The contract we intend to call
    address target;
    // The encoded function data for the call
    bytes data;
    // The ether value to be sent in the call
    uint256 value;
  }

  /**
   * @notice Batches multiple function calls to different target contracts
   *         and returns the resulting data provided all calls were successful
   *
   * @dev The `msg.sender` is always the contract from which this function
   *      is being called
   *
   * @param exdata The ExCallData struct array containing the information
   *               regarding which contract to call, what data to call with,
   *               and what ether value to send along with the call
   *
   * @return results The resulting data returned from each call made
   */
  function multiexcall(
    ExCallData[] calldata exdata
  ) external payable returns (bytes[] memory results);
}

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