// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

interface IERC20Extended is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPriceOracle {
    /// @notice Get Price Aggregator address
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    /// @return Chainlink aggregator for base/quote
    function priceAggregator(address _base, address _quote) external view returns (AggregatorV3Interface);

    /// @dev Set a new chainlink price aggregator
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    function setAggregator(address _base, address _quote, address _aggregator) external;

    /// @notice Get price of `_base` in `quote`
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    /// @return basePrice Base price in quote
    function getPrice(address _base, address _quote) external view returns (uint256 basePrice);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import { IERC20Extended } from "../interfaces/IERC20Extended.sol";
import { IPriceOracle } from "../interfaces/IPriceOracle.sol";

/// @title Price Oracle
/// @author Horizon DAO (Yuri Fernandes)
/// @notice Uses Chainlink Price Aggregators to retrieve base price in quote (base/quote)
/// @dev Aggregator registration conventions:
///		- For stablecoins 1:1 with USD, register base/USD tokens as base/stablecoin priceAggregator
///		- For ETH use zero address
contract PriceOracle is IPriceOracle, Ownable {
    /// @dev mapping (base => quote => priceAggregator)
    mapping(address => mapping(address => AggregatorV3Interface)) public priceAggregator;

    /// @dev Emitted when a new price aggregator is set
    event SetAggregator(address indexed _by, address indexed _base, address indexed _quote, address _aggregator);

    /// @dev Instantiate PriceOracle
    /// @param _owner Owner address
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /// @inheritdoc IPriceOracle
    function setAggregator(address _base, address _quote, address _aggregator) external override onlyOwner {
        priceAggregator[_base][_quote] = AggregatorV3Interface(_aggregator);
        emit SetAggregator(msg.sender, _base, _quote, _aggregator);
    }

    /// @inheritdoc IPriceOracle
    function getPrice(address _base, address _quote) external view override returns (uint256 basePrice) {
        basePrice = uint256(_getAnswer(_base, _quote));
        uint8 priceDecimals = _getPriceDecimals(_base, _quote);
        uint8 quoteDecimals = _getTokenDecimals(_quote);
        if (priceDecimals > quoteDecimals) {
            basePrice /= 10 ** (priceDecimals - quoteDecimals);
        } else if (priceDecimals < quoteDecimals) {
            basePrice *= 10 ** (priceDecimals - quoteDecimals);
        }
    }

    /// @dev Get answer (price) given `_base` and `_quote`
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    /// @return Base price in quote (int256)
    function _getAnswer(address _base, address _quote) internal view returns (int256) {
        AggregatorV3Interface priceAggregator_ = priceAggregator[_base][_quote];
        require(address(priceAggregator_) != address(0), "Price Aggregator not available");
        (uint256 roundId, int256 priceInBase, , uint256 updatedAt, uint256 answeredInRound) = priceAggregator_
            .latestRoundData();
        require(roundId == answeredInRound, "Invalid Answer");
        require(updatedAt > 0, "Round not complete");
        return priceInBase;
    }

    /// @dev Get price decimals
    /// @param _base Base currency address
    /// @param _quote Quote currency address
    /// @return Number of decimals in price response
    function _getPriceDecimals(address _base, address _quote) internal view returns (uint8) {
        return priceAggregator[_base][_quote].decimals();
    }

    /// @dev Get token decimals
    /// @param _token Token address
    /// @return Number of decimals in `_token`
    function _getTokenDecimals(address _token) internal view returns (uint8) {
        return IERC20Extended(_token).decimals();
    }
}