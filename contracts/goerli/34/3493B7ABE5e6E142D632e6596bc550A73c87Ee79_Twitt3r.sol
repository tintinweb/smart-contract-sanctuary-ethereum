// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// import "hardhat/console.sol"; // DEBUG

/**
 * @title Twitt3r
 * @author Max Petretta (maxpetretta.eth)
 * @notice A decentralized version of Twitter, build on the Ethereum blockchain
 * @dev Not audited!
 */
contract Twitt3r is Ownable, Pausable {
    uint8 public odds;
    uint256 public price;
    uint256 public jackpot;
    address public lastWinner;
    uint256 private seed;

    struct Tweet {
        address from;
        uint256 timestamp;
        string message;
        bool deleted;
        uint256 replyID;
        uint256 retweetID;
    }

    uint256 public id = 1; // Use id 0 for top-level tweets
    uint256[] public tweetIDs;
    mapping(uint256 => Tweet) public tweets; // Mapped struct with index, see: https://ethereum.stackexchange.com/a/13168
    mapping(address => uint256) public lastTweetedAt;

    /**
     * @notice Emitted when a new tweet is added to the contract
     * @param id The new tweet's ID
     * @param from The sender's address
     * @param timestamp The block timestamp of the new tweet
     * @param message The message from the tweet's sender
     * @param deleted Flag for marking the tweet as deleted
     * @param replyID The ID of the tweet being replied to, 0 for top-level tweets
     * @param retweetID The ID of the tweet being resent, 0 for top-level tweets
     */
    event NewTweet(
        uint256 indexed id,
        address indexed from,
        uint256 timestamp,
        string message,
        bool deleted,
        uint256 replyID,
        uint256 retweetID
    );

    /**
     * @notice Emitted when an existing tweet is modified by it's author
     * @param id The existing tweet's ID
     * @param from The sender's address
     * @param timestamp The block timestamp of the existing tweet
     * @param message The edited message from the tweet's sender
     * @param deleted Flag for marking the tweet as deleted
     * @param replyID The ID of the tweet being replied to, 0 for top-level tweets
     * @param retweetID The ID of the tweet being resent, 0 for top-level tweets
     */
    event EditTweet(
        uint256 indexed id,
        address indexed from,
        uint256 timestamp,
        string message,
        bool deleted,
        uint256 replyID,
        uint256 retweetID
    );

    /**
     * @notice Emitted when an existing tweet is deleted from the contract
     * @param id The existing tweet's ID
     * @param from The sender's address
     * @param timestamp The block timestamp of the new tweet
     * @param message The message from the tweet's sender
     * @param deleted Flag for marking the tweet as deleted
     * @param replyID The ID of the tweet being replied to, 0 for top-level tweets
     * @param retweetID The ID of the tweet being resent, 0 for top-level tweets
     */
    event DeleteTweet(
        uint256 indexed id,
        address indexed from,
        uint256 timestamp,
        string message,
        bool deleted,
        uint256 replyID,
        uint256 retweetID
    );

    /**
     * @notice Emitted when the contract owner clears all tweets from the contract
     * @param id The ID number of the last valid tweet
     */
    event ClearTweets(uint256 id);

    /**
     * @notice Emitted when a sender has won the contract lottery
     * @param winner The winner's wallet address
     * @param jackpot The value of the winner's jackpot
     */
    event WonLottery(address winner, uint256 jackpot);

    /// @notice Thrown when the sender is not authorized to perform an action
    error Unauthorized();

    /// @notice Thrown when the given tweet ID does not exist
    error InvalidID();

    /// @notice Thrown when the contract is sent the incorrect amount of ether
    error InvalidPrice();

    /// @notice Thrown when the sent message is over the allowed character length
    error InvalidMessage();

    /// @notice Thrown when the given tweet has been deleted
    error DeletedTweet();

    /// @notice Thrown when the sender is still on a tweet cooldown period
    error SenderCooldown();

    /// @notice Thrown when a contract withdrawal fails
    error WithdrawalFailed();

    /// @notice Thrown when the contract balance can not payout a jackpot win
    error InsufficientBalance();

    /**
     * @notice Deploys the Twitt3r contract with the given settings
     * @param _odds The percentage (0 - 100) chance of a jackpot payout
     * @param _price The price to send a tweet
     * @param _jackpot The value of the jackpot to pay out
     */
    constructor(
        uint8 _odds,
        uint256 _price,
        uint256 _jackpot
    ) payable {
        odds = _odds;
        price = _price;
        jackpot = _jackpot;
    }

    /// @notice Enable contract deposit to refill for jackpot payouts
    function deposit() public payable {}

    /// @notice In case of emergency, the owner can withdraw from the contract
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = owner().call{value: amount}("");
        if (!sent) revert WithdrawalFailed();
    }

    /**
     * @notice Send a message (tweet) to the contract
     * @param _message The sender's message to post
     * @param _replyID The ID of the tweet being replied to, 0 for top-level tweets
     * @param _retweetID The ID of the tweet being resent, 0 for top-level tweets
     */
    function newTweet(
        string memory _message,
        uint256 _replyID,
        uint256 _retweetID
    ) public payable whenNotPaused {
        if (msg.value < price) revert InvalidPrice();
        if (bytes(_message).length > 280) revert InvalidMessage();
        if (lastTweetedAt[msg.sender] + 1 minutes >= block.timestamp)
            revert SenderCooldown();

        // console.log("%s has tweeted!", msg.sender); // DEBUG
        lastTweetedAt[msg.sender] = block.timestamp;
        tweets[id] = Tweet(
            msg.sender,
            block.timestamp,
            _message,
            false,
            _replyID,
            _retweetID
        );
        tweetIDs.push(id);

        // Check if the sender has won the jackpot
        checkLottery(payable(msg.sender));

        // Alert subscribers to the new tweet transaction
        emit NewTweet(
            id,
            msg.sender,
            block.timestamp,
            _message,
            false,
            _replyID,
            _retweetID
        );
        id++;
    }

    /**
     * @notice Edit an existing tweet's message
     * @param _id The ID of the tweet being edited
     * @param _message The new replacement message for the specified tweet
     */
    function editTweet(uint256 _id, string memory _message)
        public
        whenNotPaused
    {
        if (tweets[_id].timestamp == 0) revert InvalidID();
        if (tweets[_id].deleted) revert DeletedTweet();
        if (tweets[_id].from != msg.sender) revert Unauthorized();
        if (bytes(_message).length > 280) revert InvalidMessage();

        tweets[_id].message = _message;
        emit EditTweet(
            _id,
            msg.sender,
            block.timestamp,
            tweets[_id].message,
            tweets[_id].deleted,
            tweets[_id].replyID,
            tweets[_id].retweetID
        );
    }

    /**
     * @notice Delete a tweet from the contract
     * @param _id The ID of the tweet to delete
     */
    function deleteTweet(uint256 _id) public whenNotPaused {
        if (tweets[_id].timestamp == 0) revert InvalidID();
        if (tweets[_id].deleted) revert DeletedTweet();
        if (tweets[_id].from != msg.sender) revert Unauthorized();

        tweets[_id].deleted = true;
        emit DeleteTweet(
            _id,
            msg.sender,
            block.timestamp,
            tweets[_id].message,
            tweets[_id].deleted,
            tweets[_id].replyID,
            tweets[_id].retweetID
        );
    }

    /// @notice In case of emergency, the owner can clear all tweets from the contract
    function clear() public onlyOwner {
        uint256 lastID = id;
        for (uint256 i = 0; i < tweetIDs.length; i++) {
            delete tweets[i];
        }
        delete tweetIDs;
        id = 1;

        emit ClearTweets(lastID);
    }

    /// @notice Allow the owner to pause tweeting functions
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice Allow the owner to unpause tweeting functions
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @notice Allow the owner to update the contract's settings
     * @param _odds The new percentage (0 - 100) chance of a jackpot payout
     * @param _price The new price to send a tweet
     * @param _jackpot The new value of the jackpot to pay out
     */
    function updateSettings(
        uint8 _odds,
        uint256 _price,
        uint256 _jackpot
    ) public onlyOwner {
        setOdds(_odds);
        setPrice(_price);
        setJackpot(_jackpot);
    }

    /**
     * @notice Check if the contract is paused
     * @return bool true if the contract is paused, false otherwise
     */
    function isPaused() public view returns (bool) {
        return paused();
    }

    /**
     * @notice Get the contract owner's address
     * @return address The contract owner
     */
    function getOwner() public view returns (address) {
        return owner();
    }

    /**
     * @notice Get the balance of the contract
     * @return uint256 The current address of the contract
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get the odds of winning the jackpot
     * @return uint8 The current odds of a jackpot payout
     */
    function getOdds() public view returns (uint8) {
        return odds;
    }

    /**
     * @notice Get the price of sending a new tweet
     * @return uint256 The current price of sending a tweet
     */
    function getPrice() public view returns (uint256) {
        return price;
    }

    /**
     * @notice Get the jackpot payout value
     * @return uint256 The current jackpot payout amount
     */
    function getJackpot() public view returns (uint256) {
        return jackpot;
    }

    /**
     * @notice Get the last winner's address
     * @return address The last winner's wallet address
     */
    function getLastWinner() public view returns (address) {
        return lastWinner;
    }

    /**
     * @notice Get all sent tweets from the contract
     * @return Tweet[] An array of all tweets stored on the contract
     */
    function getTweets() public view returns (Tweet[] memory) {
        Tweet[] memory allTweets = new Tweet[](tweetIDs.length);
        for (uint256 i = 0; i < tweetIDs.length; i++) {
            allTweets[i] = tweets[tweetIDs[i]];
        }
        return allTweets;
    }

    /**
     * @notice Get the total number of tweets sent
     * @return uint256 The current total number of tweets
     */
    function getTotalTweets() public view returns (uint256) {
        return tweetIDs.length;
    }

    /**
     * @notice Set the odds of winning a jackpot
     * @param _odds The new percent odds of winning
     */
    function setOdds(uint8 _odds) internal {
        odds = _odds;
    }

    /**
     * @notice Set the price of sending a tweet
     * @param _price The new price of sending a tweet
     */
    function setPrice(uint256 _price) internal {
        price = _price;
    }

    /**
     * @notice Set the jackpot payout amount
     * @param _jackpot The new value of winning a jackpot
     */
    function setJackpot(uint256 _jackpot) internal {
        jackpot = _jackpot;
    }

    /**
     * @notice Check whether the last sender won the lottery, based on the set odds
     * @dev Uses a simple RNG method based on block difficulty and timestamp, could be improved
     * @param _sender The most recent tweet sender
     */
    function checkLottery(address payable _sender) private {
        if (address(this).balance < jackpot) revert InsufficientBalance();

        uint256 randomNumber = (block.difficulty + block.timestamp + seed) %
            100;
        // console.log("Random # generated: %s", randomNumber); // DEBUG
        seed = randomNumber;

        if (randomNumber < odds) {
            // console.log("%s has won!", msg.sender); // DEBUG

            (bool sent, ) = _sender.call{value: jackpot}("");
            if (!sent) revert WithdrawalFailed();
            emit WonLottery(_sender, jackpot);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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