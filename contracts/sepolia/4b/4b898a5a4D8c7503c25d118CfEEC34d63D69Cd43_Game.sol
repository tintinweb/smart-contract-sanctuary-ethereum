// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
* @author AlexPiquard
* @notice Game smart contract for currency exchange rate evolution prediction.
*/
contract Game is Ownable {
    // @dev Percent of balance for owner of the contract
    uint256 public constant PERCENT_FOR_OWNER = 5;

    struct Bet {
        string currency;
        bool bet;
        uint256 amount;
        uint256 when;
    }

    struct Currency {
        AggregatorV3Interface dataFeed;
        uint80 lastRoundID;
        uint80 currentRoundID;
        int lastPrice;
        int currentPrice;
        uint256 updatedAt;
    }

    // @dev Iterable list of currency keys.
    string[] private currencyKeys;
    // @dev Associated currencies for each key.
    mapping(string => Currency) private currencies;
    // @dev List of users of this round.
    address[] private users;
    // @dev Associated bet for each user in this round.
    mapping(address => Bet) private bets;

    constructor() Ownable() {}

    function addCurrencyFeed(string memory currencyKey, AggregatorV3Interface dataFeed) public onlyOwner {
        (
            uint80 roundID,
            int answer,
            /*uint256 startedAt*/,
            uint256 updatedAt,
            /*uint80 answeredInRound*/
        ) = (dataFeed).latestRoundData();

        // @dev If the round is not complete yet, updatedAt is 0
        require(updatedAt > 0, "Round not complete");

        currencies[currencyKey] = Currency(dataFeed, 0, roundID, 0, answer, updatedAt);
        currencyKeys.push(currencyKey);
    }

    function clearCurrencies() public onlyOwner {
        for (uint256 i = 0; i < currencyKeys.length; ++i) {
            delete currencies[currencyKeys[i]];
        }
        delete currencyKeys;
    }

    function updateLatestCurrencyData(string memory currencyKey) private {
        Currency memory currency = currencies[currencyKey];
        (
            uint80 roundID,
            int answer,
            /*uint256 startedAt*/,
            uint256 updatedAt,
            /*uint80 answeredInRound*/
        ) = (currency.dataFeed).latestRoundData();

        // @dev If the round is not complete yet, updatedAt is 0
        require(updatedAt > 0, "Round not complete");

        currency.lastRoundID = currency.currentRoundID;
        currency.lastPrice = currency.currentPrice;
        currency.currentRoundID = roundID;
        currency.currentPrice = answer;
        currency.updatedAt = updatedAt;

        currencies[currencyKey] = currency;
    }

    function betIncrease(string memory currency) public payable {
        bet(msg.value, true, currency);
    }

    function betDecrease(string memory currency) public payable {
        bet(msg.value, false, currency);
    }

    function getBetAmount() public view returns (uint256) {
        return bets[msg.sender].amount;
    }

    function getBetCurrency() public view returns (string memory) {
        return bets[msg.sender].currency;
    }

    function getBet() public view returns (bool) {
        return bets[msg.sender].bet;
    }

    function getSupportedCurrencies() public view returns (string[] memory) {
        return currencyKeys;
    }

    function bet(uint256 amount, bool state, string memory currency) private {
        require(amount > 0, "cant bet for free");
        require(address(currencies[currency].dataFeed) != address(0), "unsupported currency");

        Bet memory b = bets[msg.sender];
        if (b.amount == 0) {
            b = Bet(currency, state, amount, block.timestamp);
            bets[msg.sender] = b;
        } else {
            require(b.bet == state, "cant change bet");
            require(keccak256(bytes(b.currency)) == keccak256(bytes(currency)), "cant change currency");
            b.amount += amount;
            b.when = block.timestamp;
            bets[msg.sender] = b;
        }
        users.push(msg.sender);
    }

    // @notice Everyone can generate result, at his own cost.
    function result() public {
        // @dev Update data for all currencies.
        for (uint256 i = 0; i < currencyKeys.length; ++i) {
            updateLatestCurrencyData(currencyKeys[i]);
        }

        // @dev Get winners and sum bet amount.
        address[] memory winners = new address[](users.length);
        uint256 winnersBalance;

        for (uint256 i = 0; i < users.length; ++i) {
            Bet memory b = bets[users[i]];
            Currency memory currency = currencies[b.currency];

            // @dev If round is still the same for this currency, we do nothing.
            if (currency.lastRoundID == currency.currentRoundID) continue;

            // @dev If bet was done after price update, we do nothing.
            if (b.when > currency.updatedAt) continue;

            // @dev Check if he's wrong.
            if (b.bet != bool(currency.currentPrice > currency.lastPrice)) continue;

            winners[i] = users[i];
            winnersBalance += b.amount;
        }

        // @dev Get balance and subtract contract percent.
        uint256 balance = address(this).balance;
        uint256 ownerGain = (balance * PERCENT_FOR_OWNER) / 100;

        if (balance > ownerGain)
            balance -= ownerGain;

        // @dev Give money to winners.
        for (uint256 i = 0; i < winners.length; ++i) {
            if (winners[i] == address(0)) continue;

            // @dev Check if gain is too low.
            uint256 gain = (bets[winners[i]].amount*balance)/winnersBalance;
            if (gain == 0) continue;

            // @dev Give percent of balance to user, related to bet amount.
            payable(address(winners[i])).transfer(gain);
        }

        // @dev The rest goes to owner.
        payable(address(owner())).transfer(address(this).balance);

        reset();
    }

    // @dev Reset game at end of round, after result.
    function reset() private {
        for (uint256 i = 0; i < users.length; ++i) {
            delete bets[users[i]];
        }
        delete users;
    }
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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