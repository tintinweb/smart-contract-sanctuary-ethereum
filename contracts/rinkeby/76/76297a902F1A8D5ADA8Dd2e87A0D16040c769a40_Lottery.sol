// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IRandomSeedGen.sol";

contract Lottery is Ownable {
  /**
   * @dev The current round number
   */
  uint256 public activeRound;

  /**
   * @dev The number of winners you can put as maximum
   */
  uint256 public MAX_NUMBER_OF_WINNERS = 10;

  /**
   * @dev The address of contract which chainlink VRF gets integrated into. used for generating random number
   */
  address public seedGenerator;

  /**
   * @dev Used to store the mapping for round, index and players
   * round => index => address
   */
  mapping(uint256 => mapping(uint256 => address)) public players;

  /**
   * @dev Used to store the mapping for round, address and status
   * round => address => status
   */
  mapping(uint256 => mapping(address => bool)) public statusOfPlayers;

  /**
   * @dev Used to store the mapping between round and the number of players
   */
  mapping(uint256 => uint256) public numberOfPlayers;

  /**
   * @dev Used to store the winners in the current round
   */
  mapping(uint256 => address[]) public winners;

  /**
   * @dev Emitted when new players are added in the active round
   * @param round - The round number
   * @param players - The array of player you're adding
   * @param startIndex - The start index to put for the first element
   *  which is equal to the length of players already added
   */
  event PlayersAdded(
    uint256 indexed round,
    address[] players,
    uint256 startIndex
  );

  /**
   * @dev Emitted when the current round is reset
   * @param round - The round number
   */
  event RoundReset(uint256 indexed round);

  /**
   * @dev Emitted when updating the seed generator
   */
  event SeedUpdated(address indexed oldSeed, address newSeed);

  /**
   * @dev Emitted when the winners are chosen
   * @param round - The round number
   * @param winners - The chosen winners
   */
  event WinnersChosen(uint256 indexed round, address[] winners);

  constructor() {}

  ///============= Owner Functions =============///

  /**
   * @dev Adds players to lottery list to choose the winner
   * @param _players - The array of address you're adding
   */
  function addPlayers(address[] calldata _players) external onlyOwner {
    uint256 startIndex = numberOfPlayers[activeRound];

    for (uint256 idx = 0; idx < _players.length; idx++) {
      require(!statusOfPlayers[activeRound][_players[idx]], "already added");
      players[activeRound][idx + startIndex] = _players[idx];
      statusOfPlayers[activeRound][_players[idx]] = true;
    }

    numberOfPlayers[activeRound] = startIndex + _players.length;

    emit PlayersAdded(activeRound, _players, startIndex);
  }

  /**
   * @dev Resets the current round. It also resets startIndex 0.
   */
  function resetRound() external onlyOwner {
    for (uint256 idx = 0; idx < numberOfPlayers[activeRound]; idx++) {
      statusOfPlayers[activeRound][players[activeRound][idx]] = false;
      players[activeRound][idx] = address(0);
    }
    numberOfPlayers[activeRound] = 0;
    delete winners[activeRound];

    emit RoundReset(activeRound);
  }

  /**
   * @dev Sets the seed generator
   * @param _seedGenerator - The address of random number generator
   */
  function setSeedGenerator(address _seedGenerator) external onlyOwner {
    emit SeedUpdated(seedGenerator, _seedGenerator);
    seedGenerator = _seedGenerator;
  }

  /**
   * @dev Generate `numberOfWinners` numbers out of a given players in the active round
   * @param numberOfWinners - The number of winners
   */
  function chooseWinners(uint256 numberOfWinners) external onlyOwner {
    uint256 totalNumberOfPlayers = numberOfPlayers[activeRound];

    require(totalNumberOfPlayers > 0, "no active players");
    require(
      numberOfWinners <= MAX_NUMBER_OF_WINNERS &&
      numberOfWinners < totalNumberOfPlayers,
      "invalid params"
    );
    require(numberOfWinners > 0, "!zero value");
    require(seedGenerator != address(0), "seed generator not set");

    address[] memory _players = new address[](totalNumberOfPlayers);
    for (uint256 idx = 0; idx < _players.length; idx++) {
      _players[idx] = players[activeRound][idx];
    }

    uint256 baseRandomNum = IRandomSeedGen(seedGenerator).random();
    address[] memory _winners = new address[](numberOfWinners);

    for (uint256 wId = 0; wId < numberOfWinners; wId++) {
      uint256 randomNum = uint256(
        keccak256(abi.encode(baseRandomNum, wId, activeRound))
      );
      uint256 selectedIdx = randomNum % (totalNumberOfPlayers - wId);
      address temp = _players[wId];
      _players[wId] = _players[wId + selectedIdx];
      _players[wId + selectedIdx] = temp;

      _winners[wId] = _players[wId];
    }

    winners[activeRound] = _winners;

    // The current round just ended! We need to move up to the next round
    activeRound++;

    // Request a new randomness
    IRandomSeedGen(seedGenerator).getRandomNumber();

    emit WinnersChosen(activeRound, _winners);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomSeedGen {
  function random() external view returns (uint256);

  function getRandomNumber() external returns (bytes32);
}