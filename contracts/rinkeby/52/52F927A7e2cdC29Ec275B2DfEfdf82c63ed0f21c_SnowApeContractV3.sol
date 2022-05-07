// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * This updated contract implements a 'betting pool' which is facilitated by the contract owner.
 * The contract owner no longer has permission to withdraw directly from the smart contract; rather,
 * they only have the ability to control how the betting pool is distributed.
 *
 * Additions/changes: bettingPoolBalance, getBettingPoolBalance, initializeOnePlayerGame, determineOutputOfOnePlayerGame
 */
contract SnowApeContractV3 is Ownable {
    uint16[] public LEAGUE_NONCES;

    uint256[] public LEAGUE_FEES = [
        10000000000000000, // monkey league
        100000000000000000, // gorilla league
        1000000000000000000 // kong league
    ];

    uint8 public LATE_FEE_DIVISOR = 5; // (100 / LATE_FEE_DIVISOR) = the late fee percentage added per-day

    address private payoutAddress;

    mapping(uint16 => mapping(uint16 => uint32)) public LEAGUE_PLAYER_COUNTS;
    mapping(uint16 => mapping(uint16 => uint256)) public LEAGUE_TOTAL_FEES;
    mapping(uint16 => mapping(uint16 => mapping(address => uint16))) public portfolioCounts;
    mapping(uint16 => uint256) public lastLeagueStartDates;

    constructor(uint16[] memory nonces) {
        LEAGUE_NONCES = nonces;
    }

    /**
     * Gets the current seconds since 1970 in east coast time
     * @return seconds
     */
    function getEastCoastSeconds() private view returns (uint256) {
        return block.timestamp - 14400;
    }

    /**
     * Calculates the fee based on the number of days that have occured since the league was started
     * @param leagueId the league on which to calculate the fee
     * @return fee
     */
    function getFee(uint16 leagueId) public view returns (uint256) {
        uint256 day = getEastCoastSeconds() / 86400;
        uint256 leagueFee = LEAGUE_FEES[leagueId];
        uint256 leagueStartDay = lastLeagueStartDates[leagueId];

        if ((leagueStartDay == 0) || day <= (leagueStartDay + 2)) {
            // first league or still the weekend, do not charge a late fee
            return leagueFee;
        }

        uint256 daysSinceStartMultiplier = day - 2 - leagueStartDay;
        uint256 lateFee = (leagueFee / LATE_FEE_DIVISOR) *
            daysSinceStartMultiplier;
        return leagueFee + lateFee;
    }

    /**
        Returns current nonce for a league
        * @return nonce
     */
    function getNonce(uint16 leagueId) public view returns (uint16) {
        return LEAGUE_NONCES[leagueId];
    }

    /**
        Returns current nonces for all leagues
        * @return nonce
     */
    function getNonces() public view returns (uint16[] memory) {
        return LEAGUE_NONCES;
    }

    /**
     * @dev Gets the balance of the smart contract.
     * @return currentBalance
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev Gets the balance of an address.
     * @return currentBalance
     */
    function balanceOf(address adr) public view returns (uint256) {
        return address(adr).balance;
    }

    /**
     * @dev Gets the number of portfolios an address is entitled to.
     * @param player the address of the player
     * @param leagueId the id of the league
     * @return portfolioSize
     */
    function getPortfolioSize(address player, uint16 leagueId)
        public
        view
        returns (uint16, uint16)
    {
        uint16 leagueNonce = LEAGUE_NONCES[leagueId];
        return (portfolioCounts[leagueId][leagueNonce][player], leagueNonce);
    }

    /**
     * Sets payout address of contract
     * @param adr the address to send funds to on payouts
     */
    function setPayoutAddress(address adr) public onlyOwner {
        payoutAddress = adr;
    }

    /**
     * @dev Joins a league.
     * @param leagueId the leagueId (for determining bet size)
     */
    function joinLeague(uint16 leagueId) public payable {
        require(
            msg.value >= getFee(leagueId),
            "Insufficient payment to play game."
        );
        uint16 leagueNonce = LEAGUE_NONCES[leagueId];

        portfolioCounts[leagueId][leagueNonce][msg.sender]++;
        LEAGUE_PLAYER_COUNTS[leagueId][leagueNonce]++;
        LEAGUE_TOTAL_FEES[leagueId][leagueNonce] += msg.value;
    }

    /**
     * @dev Pays the winner of a league. The winner recievs the league's player count * base league fee,
     * while the owner recieves the total late fees charged.
     * @param players the address of the players who won
     * @param leagueId the leagueId (for determining bet size)
     */
    function payWinners(address[] calldata players, uint16 leagueId)
        public
        onlyOwner
    {
        uint16 leagueNonce = LEAGUE_NONCES[leagueId];
        uint32 leaguePlayerCount = LEAGUE_PLAYER_COUNTS[leagueId][leagueNonce];
        uint256 payout = leaguePlayerCount * LEAGUE_FEES[leagueId];
        uint256 payoutPerWinner = payout / players.length;
        uint256 roundingExtra = payout - (payoutPerWinner * players.length);

        for (uint8 i = 0; i < players.length; i++) {
            require(
                portfolioCounts[leagueId][leagueNonce][players[i]] > 0,
                "Not a valid player"
            );
            address payable gameFeeBeneficiary = payable(players[i]);
            (bool sent, ) = gameFeeBeneficiary.call{value: payoutPerWinner}("");

            assert(sent);
        }

        uint256 totalFeesCollected = LEAGUE_TOTAL_FEES[leagueId][leagueNonce];
        uint256 ownerPayout = (totalFeesCollected - payout) + roundingExtra;

        if (ownerPayout != 0) {
            address payable owner = (payoutAddress == address(0))
                ? payable(owner())
                : payable(payoutAddress);
            (bool success, ) = owner.call{value: ownerPayout}("");

            assert(success);
        }

        LEAGUE_NONCES[leagueId]++;
        lastLeagueStartDates[leagueId] = getEastCoastSeconds() / 86400;
    }

    /**
     * @dev Pays no winner, but collects late fees and moves the whole pot into next week's league.
     * @param leagueId the leagueId (for determining bet size)
     */
    function callNoWinner(uint16 leagueId) public onlyOwner {
        uint16 leagueNonce = LEAGUE_NONCES[leagueId];
        uint32 leaguePlayerCount = LEAGUE_PLAYER_COUNTS[leagueId][leagueNonce];
        uint256 payout = leaguePlayerCount * LEAGUE_FEES[leagueId];

        uint256 totalFeesCollected = LEAGUE_TOTAL_FEES[leagueId][leagueNonce];
        uint256 ownerPayout = (totalFeesCollected - payout);

        if (ownerPayout != 0) {
            address payable owner = (payoutAddress == address(0))
                ? payable(owner())
                : payable(payoutAddress);
            (bool success, ) = owner.call{value: ownerPayout}("");

            assert(success);
        }

        LEAGUE_NONCES[leagueId]++;
        lastLeagueStartDates[leagueId] = getEastCoastSeconds() / 86400;

        uint16 newLeagueNonce = LEAGUE_NONCES[leagueId];

        LEAGUE_PLAYER_COUNTS[leagueId][newLeagueNonce] = leaguePlayerCount;
        LEAGUE_TOTAL_FEES[leagueId][newLeagueNonce] = payout;
    }

    function addLeague(uint256 leagueFee) public onlyOwner returns (uint256) {
        LEAGUE_FEES.push(leagueFee);
        LEAGUE_NONCES.push(0);

        return LEAGUE_FEES.length - 1;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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