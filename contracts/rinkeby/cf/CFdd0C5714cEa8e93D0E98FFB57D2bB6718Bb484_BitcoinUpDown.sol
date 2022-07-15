// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "AggregatorV3Interface.sol";
import "Ownable.sol";

contract BitcoinUpDown is Ownable {
    address payable private house;
    address payable[] public players;
    address payable[] public winners;
    address payable[] public price_up;
    address payable[] public price_down;
    struct PlayersBet {
        uint256 bet;
    }
    mapping(address => PlayersBet) public players_bet;
    AggregatorV3Interface internal btcUsdPriceFeed;
    enum BETTING_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNERS
    }
    enum UP_DOWN {
        UP,
        DOWN
    }
    BETTING_STATE public betting_state;
    int256 public price_open;
    int256 public price_close;
    uint256 public prize_pool;
    uint256 public total_up;
    uint256 public total_down;
    uint256 public total_winners;
    uint256 public percent;
    uint256 public ts_start;

    constructor(address _priceFeedAddress) public {
        house = msg.sender;
        btcUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        betting_state = BETTING_STATE.CLOSED;
    }

    function getPrice() public view returns (int256) {
        (, int256 price, , , ) = btcUsdPriceFeed.latestRoundData();
        return price / (10**8);
    }

    function startBet() public onlyOwner {
        require(betting_state == BETTING_STATE.CLOSED, "Betting aleardy open");
        price_open = getPrice();
        ts_start = block.timestamp;
        betting_state = BETTING_STATE.OPEN;
    }

    function bet(UP_DOWN _up_down) public payable {
        require(betting_state == BETTING_STATE.OPEN, "Betting closed");
        require(msg.value >= 1, "Minimum bet = 1$");
        require(block.timestamp - ts_start <= 3600, "Max 1 hour after start");
        players.push(msg.sender);
        players_bet[msg.sender].bet = msg.value;
        if (_up_down == UP_DOWN.UP) {
            price_up.push(msg.sender);
            total_up += msg.value;
        } else if (_up_down == UP_DOWN.DOWN) {
            price_down.push(msg.sender);
            total_down += msg.value;
        }
        prize_pool += msg.value;
    }

    function endBet() public onlyOwner {
        require(betting_state == BETTING_STATE.OPEN, "Betting aleardy closed");
        //require(block.timestamp - ts_start >= 3600, "Min 1 hour after start");
        betting_state = BETTING_STATE.CLOSED;
    }

    function declareWinners() public onlyOwner {
        require(betting_state == BETTING_STATE.CLOSED, "Betting still open");
        //require(block.timestamp - ts_start >= 1 days, "Min 1 day after start");
        betting_state = BETTING_STATE.CALCULATING_WINNERS;
        price_close = getPrice();
        uint256 fee = (2 * prize_pool) / 100; // 2% fee
        house.transfer(fee);
        prize_pool -= fee;
        if (price_close >= price_open) {
            winners = price_up;
            total_winners = total_up;
        } else if (price_close < price_open) {
            winners = price_down;
            total_winners = total_down;
        } else {
            // price didn't change
        }
        for (uint256 i = 0; i < winners.length; i++) {
            // each winner get percentage of the prize depending of his bet players_bet[winners[i]].be
            percent = (players_bet[winners[i]].bet * 100) / total_winners;
            winners[i].transfer((percent * prize_pool) / 100);
        }
        // reset
        players = new address payable[](0);
        winners = new address payable[](0);
        price_up = new address payable[](0);
        price_down = new address payable[](0);
        prize_pool = 0;
        total_up = 0;
        total_down = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

pragma solidity >=0.6.0 <0.8.0;

import "Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}