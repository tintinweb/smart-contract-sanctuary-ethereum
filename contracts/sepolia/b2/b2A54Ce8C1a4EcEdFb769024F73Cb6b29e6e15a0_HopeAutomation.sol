// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Ownable2Step} from '../dependencies/openzeppelin/Ownable2Step.sol';
import {AutomationCompatibleInterface} from '../dependencies/chainlink/AutomationCompatibleInterface.sol';
import {IHOPEPriceFeed} from '../interfaces/IHOPEPriceFeed.sol';
import {IHopeAggregator} from '../interfaces/IHopeAggregator.sol';

contract HopeAutomation is Ownable2Step, AutomationCompatibleInterface {
  uint256 internal constant THRESHOLD_FACTOR = 1e4;

  address public priceFeed;
  address public aggregator;

  uint256 public heartbeat;
  uint256 public deviationThreshold;

  uint256 public lastPrice;
  uint256 public lastTimestamp;

  event HeartbeatUpdated(uint256 newHeartbeat);
  event DeviationThresholdUpdated(uint256 newDeviationThreshold);
  event HOPEPriceFeedUpdated(address newPriceFeed);
  event AggregatorUpdated(address newAggregator);
  event PriceUpdated(uint256 price, uint256 timestamp);

  constructor(address _priceFeed, address _aggregator, uint256 _heartbeat, uint256 _deviationThreshold) {
    _setHOPEPriceFeed(_priceFeed);
    _setAggregator(_aggregator);
    _setHeartbeat(_heartbeat);
    _setDeviationThreshold(_deviationThreshold);
  }

  function setHeartbeat(uint256 _heartbeat) external onlyOwner {
    _setHeartbeat(_heartbeat);
  }

  function setDeviationThreshold(uint256 _deviationThreshold) external onlyOwner {
    _setDeviationThreshold(_deviationThreshold);
  }

  function setHOPEPriceFeed(address _priceFeed) external onlyOwner {
    _setHOPEPriceFeed(_priceFeed);
  }

  function setAggregator(address _aggregator) external onlyOwner {
    _setAggregator(_aggregator);
  }

  function _setHeartbeat(uint256 _heartbeat) internal {
    heartbeat = _heartbeat;
    emit HeartbeatUpdated(_heartbeat);
  }

  function _setDeviationThreshold(uint256 _deviationThreshold) internal {
    deviationThreshold = _deviationThreshold;
    emit DeviationThresholdUpdated(_deviationThreshold);
  }

  function _setHOPEPriceFeed(address _priceFeed) internal {
    priceFeed = _priceFeed;
    emit HOPEPriceFeedUpdated(_priceFeed);
  }

  function _setAggregator(address _aggregator) internal {
    aggregator = _aggregator;
    emit AggregatorUpdated(_aggregator);
  }

  function checkUpkeep(
    bytes calldata /*checkData*/
  ) external view override returns (bool upkeepNeeded, bytes memory /*performData*/) {
    (, upkeepNeeded) = _checkUpKeep();
  }

  function performUpkeep(bytes memory /*performData*/) external override {
    (uint256 price, bool upkeepNeeded) = _checkUpKeep();
    require(upkeepNeeded, 'HopeAutomation: upkeep not needed');
    lastPrice = price;
    lastTimestamp = block.timestamp;
    IHopeAggregator(aggregator).transmit(price);

    emit PriceUpdated(price, block.timestamp);
  }

  function _checkUpKeep() internal view returns (uint256 price, bool upkeepNeeded) {
    price = _getPrice();
    upkeepNeeded = price > 0;
    bool thresholdMet;
    unchecked {
      upkeepNeeded = upkeepNeeded && block.timestamp - lastTimestamp >= heartbeat;
      if (price >= lastPrice) {
        thresholdMet = price - lastPrice >= (deviationThreshold * lastPrice) / THRESHOLD_FACTOR;
      } else {
        thresholdMet = lastPrice - price >= (deviationThreshold * lastPrice) / THRESHOLD_FACTOR;
      }
      upkeepNeeded = upkeepNeeded || thresholdMet;
    }
  }

  function _getPrice() internal view returns (uint256 price) {
    price = IHOPEPriceFeed(priceFeed).latestAnswer();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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

interface IHOPEPriceFeed {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

interface IHopeAggregator {
    function transmit(uint256 _answer) external;
}