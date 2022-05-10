// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRandomizer.sol";


contract Randomizer is IRandomizer, Ownable {
  uint256 private _currentRound;
  uint256 private _delay;
  bool private _nextRoundRequired;
  uint256 private _roundMinDuration;
  mapping(uint256 => Round) private _rounds;

  function canFinishRound() external view override(IRandomizer) returns (bool) {
    if (_currentRound == 0) return true;
    Round memory round_ = _rounds[_currentRound];
    return _canFinishRound(round_);
  }

  function currentRound() external view override(IRandomizer) returns (uint256) {
    return _currentRound;
  }

  function delay() external view override(IRandomizer) returns (uint256) {
    return _delay;
  }

  function nextRound() external view override(IRandomizer) returns (uint256) {
    return _currentRound + 1;
  }

  function nextRoundRequired() external view override(IRandomizer) returns (bool) {
    return _nextRoundRequired;
  }

  function roundMinDuration() external view override(IRandomizer) returns (uint256) {
    return _roundMinDuration;
  }

  function canFinishRound(uint256 roundNumber_) external view override(IRandomizer) returns (bool) {
    Round memory round_ = _rounds[roundNumber_];
    return _canFinishRound(round_);
  }

  function isRandomReady(uint256 roundNumber_) external view override(IRandomizer) returns (bool) {
    return _rounds[roundNumber_].status == Status.RELEASED;
  }

  function random(uint256 roundNumber_) external view override(IRandomizer) returns (uint256) {
    return _rounds[roundNumber_].random;
  }

  function round(uint256 roundNumber_) external view override(IRandomizer) returns (Round memory) {
    require(roundNumber_ <= _currentRound, "Randomizer: invalid round");
    return _rounds[roundNumber_];
  }

  constructor(uint256 delay_, uint256 roundMinDuration_) Ownable() {
    _updateDelay(delay_);
    _updateRoundMinDuration(roundMinDuration_);
  }

  function releaseRandom(uint256 roundNumber_) public returns (uint256) {
    require(roundNumber_ <= _currentRound, "Randomizer: invalid round");
    Round storage round_ = _rounds[roundNumber_];
    if (round_.random != 0) return round_.random;
    require(round_.status == Status.FINISHED, "Randomizer: round not finished");
    require(round_.blockHash != bytes32(0), "Randomizer: blockHash not provided");
    uint256 random_ = uint256(keccak256(abi.encodePacked(round_.seed, round_.blockHash)));
    round_.random = random_;
    round_.status = Status.RELEASED;
    emit RandomReleased(roundNumber_, random_, msg.sender);
    return random_;
  }

  function requireNextRound() external override(IRandomizer) returns (bool) {
    _nextRoundRequired = true;
    emit RoundRequired(_currentRound + 1);
    return true;
  }

  function switchRound(string memory seed_, bytes32 hashSeed_) external onlyOwner returns (bool) {
    if (_currentRound > 0) _finishRound(_currentRound, seed_);
    _startRound(hashSeed_);
    return true;
  }

  function startRound(bytes32 hashSeed_) external onlyOwner returns (bool) {
    _startRound(hashSeed_);
    return true;
  }

  function finishRound(uint256 roundNumber_, string memory seed_) public returns (bool) {
    _finishRound(roundNumber_, seed_);
    return true;
  }

  function saveBlockHash(uint256 roundNumber_) public returns (bytes32 blockHash) {
    require(roundNumber_ <= _currentRound, "Randomizer: invalid round");
    Round storage round_ = _rounds[roundNumber_];
    if (_canSaveBlockHash(round_)) _saveBlockHash(roundNumber_, round_);
    else return round_.blockHash;
  }

  function restartRound(uint256 roundNumber_, bytes32 hashSeed_) external returns (bool) {
    require(roundNumber_ < _currentRound, "Randomizer: invalid round");
    Round storage round_ = _rounds[roundNumber_];
    require(round_.status != Status.RELEASED, "Randomizer: round already released");
    _setRound(roundNumber_, hashSeed_);
    emit RoundRestarted(roundNumber_, hashSeed_, block.number, msg.sender);
    return true;
  }

  function updateDelay(uint256 delay_) external onlyOwner returns (bool) {
    _updateDelay(delay_);
    return true;
  }

  function updateRoundMinDuration(uint256 roundMinDuration_) external onlyOwner returns (bool) {
    _updateRoundMinDuration(roundMinDuration_);
    return true;
  }

  function _canFinishRound(Round memory round_) private view returns (bool) {
    return round_.endsAt <= block.number && round_.status < Status.FINISHED;
  }

  function _canSaveBlockHash(Round memory round_) private view returns (bool) {
    return round_.blockNumber + _delay < block.number
      && round_.blockNumber > block.number - 256
      && round_.blockHash == bytes32(0);
  }

  function _finishRound(uint256 roundNumber_, string memory seed_) private {
    require(roundNumber_ > 0 && roundNumber_ <= _currentRound, "Randomizer: invalid round");
    Round storage round_ = _rounds[roundNumber_];
    require(round_.status == Status.ACTIVE, "Randomizer: round not active");
    require(_canFinishRound(round_), "Randomizer: too early for round finishing");
    require(round_.hashSeed != bytes32(0), "Randomizer: hashSeed not provided");
    require(keccak256(abi.encodePacked(seed_)) == round_.hashSeed, "Randomizer: invalid seed");
    round_.seed = seed_;
    round_.status = Status.FINISHED;
    emit RoundFinished(roundNumber_, seed_, msg.sender);
    if (_canSaveBlockHash(round_)) _saveBlockHash(roundNumber_, round_);
    if (round_.blockHash != bytes32(0)) releaseRandom(roundNumber_);
  }

  function _saveBlockHash(uint256 roundNumber_, Round storage round_) private returns (bytes32 blockHash) {
    blockHash = blockhash(round_.blockNumber);
    round_.blockHash = blockHash;
    emit BlockHashSaved(roundNumber_, blockHash, msg.sender);
  }

  function _startRound(bytes32 hashSeed_) private {
    require(_nextRoundRequired, "Randomizer: round not required");
    _currentRound += 1;
    Round storage round_ = _rounds[_currentRound];
    require(round_.hashSeed == bytes32(0), "Randomizer: hashSeed already provided");
    _setRound(_currentRound, hashSeed_);
    _nextRoundRequired = false;
    emit RoundStarted(_currentRound, hashSeed_, round_.blockNumber, msg.sender);
  }

  function _setRound(uint256 roundNumber_, bytes32 hashSeed_) private {
    uint256 blockNumber = block.number;
    require(hashSeed_ != bytes32(0), "Randomizer: hashSeed is zero bytes");
    Round storage round_ = _rounds[roundNumber_];
    round_.startAt = blockNumber;
    round_.endsAt = blockNumber + _roundMinDuration;
    round_.hashSeed = hashSeed_;
    round_.blockNumber = blockNumber;
    round_.status = Status.ACTIVE;
  }

  function _updateDelay(uint256 delay_) private {
    _delay = delay_;
    emit DelayUpdated(delay_);
  }

  function _updateRoundMinDuration(uint256 roundMinDuration_) private {
    require(roundMinDuration_ > 0, "Randomizer: roundMinDuration is zero");
    _roundMinDuration = roundMinDuration_;
    emit RoundMinDurationUpdated(roundMinDuration_);
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


interface IRandomizer {
  enum Status {
    NOT_ACTIVE,
    ACTIVE,
    FINISHED,
    RELEASED
  }

  struct Round {
    uint256 startAt;
    uint256 endsAt;
    bytes32 hashSeed;
    string seed;
    uint256 blockNumber;
    bytes32 blockHash;
    uint256 random;
    Status status;
  }

  function canFinishRound() external view returns (bool);
  function currentRound() external view returns (uint256);
  function delay() external view returns (uint256);
  function nextRound() external view returns (uint256);
  function nextRoundRequired() external view returns (bool);
  function roundMinDuration() external view returns (uint256);
  function canFinishRound(uint256 roundNumber_) external view returns (bool);
  function isRandomReady(uint256 roundNumber_) external view returns (bool);
  function random(uint256 roundNumber_) external view returns (uint256);
  function round(uint256 roundNumber_) external view returns (Round memory);

  function requireNextRound() external returns (bool);

  event BlockHashSaved(uint256 round_, bytes32 blockHash_, address indexed caller);
  event DelayUpdated(uint256 delay_);
  event RandomReleased(
    uint256 round_,
    uint256 random_,
    address indexed caller
  );
  event RoundMinDurationUpdated(uint256 roundMinDuration_);
  event RoundFinished(uint256 round_, string seed_, address indexed caller);
  event RoundRequired(uint256 round_);
  event RoundRestarted(uint256 indexed round_, bytes32 hashSeed_, uint256 blockNumber_, address indexed caller);
  event RoundStarted(uint256 round_, bytes32 hashSeed_, uint256 blockNumber_, address indexed caller);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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