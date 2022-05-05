//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract BettingPools is Ownable {
    enum GameStatus {PENDING, IN_PROGRESS, TEAM_HOME, TEAM_AWAY, DRAW}

    GameStatus currentStatus = GameStatus.PENDING;

    uint256 public minimumBet;

    mapping(address => uint256[3]) public playerMap;
    mapping(address => bool) public hasPlayerWithdrawn;

    uint256[3] pools;
    address[] playerAddresses;

    struct Player {
      uint256[3] bets;
    }

    constructor() {
        minimumBet = 0.001 ether;
    }

    //pools: 1 = Away, 0 = Draw, 2 = Home
    function bet(uint8 _pool) public payable {
      require(msg.value >= minimumBet,
        "Bet is less than minimum"
      );

      require(currentStatus == GameStatus.PENDING,
        "Game is no longer availible"
      );

      if(_pool == 1) {
        playerMap[msg.sender][1] = msg.value;
        pools[1] += msg.value;
      } else if (_pool == 2) {
        playerMap[msg.sender][2] = msg.value;
        pools[2] += msg.value;
      } else {
        playerMap[msg.sender][0] = msg.value;
        pools[0] += msg.value;
      }

      playerAddresses.push(msg.sender);
    }

    function getTotalBetsForPool() public view returns(uint256[3] memory) {
      return pools;
    }

    function getBetsForAddress(address _address) public view returns(uint256[3] memory) {
      return playerMap[_address];
    }

    function getWinnings() public view returns(uint256){
        require (!hasPlayerWithdrawn[msg.sender],
          "no withdraw availible"
        );

        require (currentStatus != GameStatus.PENDING || currentStatus != GameStatus.IN_PROGRESS,
          "game is not complete"
        );

        uint256[3] memory playerBet = playerMap[msg.sender];

        if (currentStatus == GameStatus.TEAM_HOME) {
          return playerBet[1] + ((playerBet[1] * (pools[0] + pools[2])) / pools[1]);
        } else if (currentStatus == GameStatus.TEAM_AWAY) {
          return playerBet[2] + ((playerBet[2]) * (pools[1] + pools[0])) / pools[2];
        } else if (currentStatus == GameStatus.DRAW) {
          return playerBet[0] + ((playerBet[0]) * (pools[1] + pools[2])) / pools[0] ;
        }

        return 0;
    }

    function withdrawWinings() public {
      require (!hasPlayerWithdrawn[msg.sender],
        "no withdraw availible"
      );

      address payable winner = payable(msg.sender);
      uint256 winnings = getWinnings();

      hasPlayerWithdrawn[msg.sender] = true;
      winner.transfer(winnings);
    }

    function updateGameStatus(uint8 _result) public onlyOwner {
      require(_result >= 0 && _result <= 4,
        "Invalid game status"
      );

      if (_result == 0) {
        currentStatus = GameStatus.PENDING;
      } else if (_result == 1) {
        currentStatus = GameStatus.IN_PROGRESS;
      } else if (_result == 2) {
        currentStatus = GameStatus.TEAM_HOME;
      } else if (_result == 3) {
        currentStatus = GameStatus.TEAM_AWAY;
      } else if (_result == 4) {
        currentStatus = GameStatus.DRAW;
      }
    }
}

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