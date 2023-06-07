// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {Ownable2Step} from '../dependencies/openzeppelin/Ownable2Step.sol';
import {AggregatorV2V3Interface} from '../dependencies/chainlink/AggregatorV2V3Interface.sol';
import {IHOPE} from '../interfaces/IHOPE.sol';
import {IHOPEPriceFeed} from '../interfaces/IHOPEPriceFeed.sol';

contract HOPEPriceFeed is Ownable2Step, IHOPEPriceFeed {
  uint256 private constant K_FACTOR = 1e20;
  uint256 private constant PRICE_SCALE = 1e8;
  uint256 public immutable K; // 1080180484347501
  address public immutable ETH_ADDRESS; // 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
  address public immutable BTC_ADDRESS; // 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB
  address public immutable HOPE_ADDRESS; // 0xc353Bf07405304AeaB75F4C2Fac7E88D6A68f98e

  struct TokenConfig {
    AggregatorV2V3Interface priceFeed;
    uint256 factor;
    bool isExist;
  }
  address[] private reserveTokens;
  mapping(address => TokenConfig) private reserveTokenConfigs;

  event ReserveUpdate(address[] tokens, address[] priceFeed, uint256[] factors);

  constructor(address _ethMaskAddress, address _btcMaskAddress, address _hopeAddress, uint256 _k) {
    ETH_ADDRESS = _ethMaskAddress;
    BTC_ADDRESS = _btcMaskAddress;
    HOPE_ADDRESS = _hopeAddress;
    K = _k;
  }

  function setReserveTokens(
    address[] memory tokens,
    address[] memory priceFeeds,
    uint256[] memory factors
  ) external onlyOwner {
    require(tokens.length == priceFeeds.length, 'HOPEPriceFeeds: Invalid input');
    require(tokens.length == factors.length, 'HOPEPriceFeeds: Invalid input');

    for (uint256 i = 0; i < tokens.length; i++) {
      if (!reserveTokenConfigs[tokens[i]].isExist) {
        reserveTokens.push(tokens[i]);
      }
      reserveTokenConfigs[tokens[i]] = TokenConfig(AggregatorV2V3Interface(priceFeeds[i]), factors[i], true);
    }

    emit ReserveUpdate(tokens, priceFeeds, factors);
  }

  function latestAnswer() external view override returns (uint256) {
    uint256 hopeSupply = getHOPETotalSupply();
    uint256 reserveTotalValue;
    uint256 hopePrice;

    unchecked {
      for (uint256 i = 0; i < reserveTokens.length; i++) {
        TokenConfig memory config = reserveTokenConfigs[reserveTokens[i]];
        uint256 reserveInToken = _calculateReserveAmount(hopeSupply, config);
        uint256 reserveValueInToken = _calculateReserveValue(reserveInToken, config);
        reserveTotalValue += reserveValueInToken;
      }

      hopePrice = reserveTotalValue / hopeSupply;
    }

    if (hopePrice >= PRICE_SCALE) return PRICE_SCALE;
    return hopePrice;
  }

  function _calculateReserveAmount(uint256 hopeSupply, TokenConfig memory config) internal view returns (uint256) {
    unchecked {
      uint256 reserveAmount = (hopeSupply * K * config.factor) / K_FACTOR;
      return reserveAmount;
    }
  }

  function _calculateReserveValue(uint256 reserveAmount, TokenConfig memory config) internal view returns (uint256) {
    uint256 reservePrice = uint256(config.priceFeed.latestAnswer());
    uint256 reserveDecimals = uint256(config.priceFeed.decimals());
    unchecked {
      uint256 reserveValue = (reserveAmount * reservePrice * PRICE_SCALE) / (10 ** reserveDecimals);
      return reserveValue;
    }
  }

  function getReservePrice(address token) external view returns (uint256) {
    TokenConfig memory config = reserveTokenConfigs[token];
    return uint256(config.priceFeed.latestAnswer());
  }

  function getHOPETotalSupply() public view returns (uint256) {
    return IHOPE(HOPE_ADDRESS).totalSupply();
  }

  function getReserveTokens() external view returns (address[] memory) {
    return reserveTokens;
  }

  function getReserveTokenConfig(address token) external view returns (address, uint256, bool) {
    TokenConfig memory config = reserveTokenConfigs[token];
    return (address(config.priceFeed), config.factor, config.isExist);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.17;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IHOPE {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IHOPEPriceFeed {
    function latestAnswer() external view returns (uint256);
}