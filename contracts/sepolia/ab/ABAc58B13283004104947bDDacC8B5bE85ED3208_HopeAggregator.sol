// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {Ownable2Step} from '../dependencies/openzeppelin/Ownable2Step.sol';
import {AggregatorV2V3Interface} from '../dependencies/chainlink/AggregatorV2V3Interface.sol';
import {IHopeAggregator} from '../interfaces/IHopeAggregator.sol';

contract HopeAggregator is Ownable2Step, IHopeAggregator, AggregatorV2V3Interface {
  uint256 public constant override version = 1;
  uint8 public immutable override decimals;
  string public override description; // 'HOPE/USD'
  address internal transmitter;
  uint80 internal roundId;

  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }
  mapping(uint80 /* aggregator round ID */ => Transmission) internal transmissions;

  event TransmitterUpdated(address newTransmitter);

  modifier isTransmitter() {
    require(msg.sender == transmitter, 'HopeAggregator: caller is not the transmitter');
    _;
  }

  constructor(uint8 _decimals, string memory _description, address _transmitter) {
    decimals = _decimals;
    description = _description;
    transmitter = _transmitter;
  }

  function updateTransmitter(address newTransmitter) external onlyOwner {
    transmitter = newTransmitter;
    emit TransmitterUpdated(newTransmitter);
  }

  function transmit(uint256 _answer) external override isTransmitter {
    roundId++;
    int192 currentPrice = int192(int256(_answer));
    transmissions[roundId] = Transmission(currentPrice, uint64(block.timestamp));
    emit AnswerUpdated(currentPrice, roundId, uint64(block.timestamp));
  }

  function latestAnswer() external view override returns (int256) {
    return transmissions[roundId].answer;
  }

  function latestTimestamp() external view override returns (uint256) {
    return transmissions[roundId].timestamp;
  }

  function latestRound() external view override returns (uint256) {
    return roundId;
  }

  function getAnswer(uint256 _roundId) external view override returns (int256) {
    return transmissions[uint80(_roundId)].answer;
  }

  function getTimestamp(uint256 _roundId) external view override returns (uint256) {
    return transmissions[uint80(_roundId)].timestamp;
  }

  function getRoundData(uint80 _roundId) external view override returns (uint80, int256, uint256, uint256, uint80) {
    Transmission memory transmission = transmissions[_roundId];
    return (_roundId, transmission.answer, transmission.timestamp, transmission.timestamp, _roundId);
  }

  function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
    Transmission memory transmission = transmissions[roundId];
    return (roundId, transmission.answer, transmission.timestamp, transmission.timestamp, roundId);
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

interface IHopeAggregator {
    function transmit(uint256 _answer) external;
}