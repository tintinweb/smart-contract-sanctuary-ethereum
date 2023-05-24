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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";
import "./Nonce.sol";
import "../libs/Utils.sol";

contract BetChain is Ownable {
    string public constant NAME = "BetChain";
    string public constant VERSION = "0.1";

    uint8 public constant MULTIPLIER = 2;
    Nonce private nonces;

    bytes32[] private gameIds;
    mapping(bytes32 => Game) private games; // Map of games
    mapping(bytes32 => Bet) private bets; // Map of bets
    mapping(address => bytes32[]) private betsPerPlayer; // address -> [bid]

    modifier betOwner(bytes32 _bid) {
        require(bets[_bid].owner == msg.sender, "Not bet owner");
        _;
    }

    modifier betExists(bytes32 _bid) {
        require(bets[_bid].bid != 0, "Bet does not exist");
        _;
    }

    modifier notPaid(bytes32 _bid) {
        require(!bets[_bid].paid, "Already paid");
        _;
    }

    modifier winner(bytes32 _bid) {
        require(
            bets[_bid].prediction == games[bets[_bid].gid].result,
            "Not a winner"
        );
        _;
    }

    modifier gameExist(bytes32 _gid) {
        require(bytes(games[_gid].teamA).length > 0, "Game does not exist");
        _;
    }

    modifier validPrediction(Result _prediction) {
        require(
            _prediction == Result.A_WINS ||
                _prediction == Result.B_WINS ||
                _prediction == Result.DRAW,
            "Prediction must be a valid value"
        );
        _;
    }

    modifier betsOpen(bytes32 _gid) {
        require(games[_gid].result == Result.NEW, "Bets closed for this offer");
        _;
    }

    modifier validTeams(string memory teamA, string memory teamB) {
        require(bytes(teamA).length > 0, "Team A cannot be an empty string");
        require(bytes(teamB).length > 0, "Team B cannot be an empty string");
        _;
    }

    modifier resultNotSet(bytes32 _gid) {
        require(games[_gid].result == Result.NEW, "Result already set");
        _;
    }

    modifier validResult(Result result) {
        require(
            result == Result.A_WINS ||
                result == Result.B_WINS ||
                result == Result.DRAW ||
                result == Result.CANCELLED,
            "Prediction must be a valid value"
        );
        _;
    }

    event ClaimSuccess(address _address, uint _amount);
    event BetCreated(
        bytes32 _bid,
        bytes32 _gid,
        uint _amount,
        Result _prediction
    );
    event GameCreated(bytes32 _gid, string _teamA, string _teamB);

    constructor() payable {
        nonces = new Nonce();
    }

    function addBet(
        bytes32 gid,
        Result prediction
    )
        external
        payable
        gameExist(gid)
        validPrediction(prediction)
        betsOpen(gid)
        returns (bytes32 bid)
    {
        // require(msg.value >= 1 ether, "At least 1 eth needed to fund a game");

        uint nonce = nonces.getNonce();
        bytes32 newBid = Utils.generateTransactionHash(msg.sender, nonce + 1);
        Bet memory newBet = Bet(
            newBid,
            gid,
            msg.value,
            msg.sender,
            prediction,
            false
        );

        bets[newBid] = newBet;
        betsPerPlayer[msg.sender].push(newBid);

        nonces.incrementNonce();
        assert(
            newBid ==
                Utils.generateTransactionHash(msg.sender, nonces.getNonce())
        );
        emit BetCreated(newBid, gid, msg.value, prediction);

        return newBid;
    }

    function claimWinner(
        bytes32 bid
    ) external betExists(bid) betOwner(bid) notPaid(bid) winner(bid) {
        bets[bid].paid = true;
        uint amount = bets[bid].amount * MULTIPLIER;
        emit ClaimSuccess(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function addGame(
        string memory teamA,
        string memory teamB
    ) external onlyOwner validTeams(teamA, teamB) returns (bytes32 gid) {
        uint nonce = nonces.getNonce();
        bytes32 newGid = Utils.generateTransactionHash(msg.sender, nonce + 1);
        games[newGid] = Game(teamA, teamB, Result.NEW);
        gameIds.push(newGid);
        nonces.incrementNonce();
        assert(
            newGid ==
                Utils.generateTransactionHash(msg.sender, nonces.getNonce())
        );

        emit GameCreated(newGid, teamA, teamB);

        return newGid;
    }

    function addResultToGame(
        bytes32 gid,
        Result result
    ) external onlyOwner gameExist(gid) resultNotSet(gid) validResult(result) {
        games[gid].result = result;
    }

    function getJackpot() external view returns (uint) {
        return Utils.getBalance(address(this));
    }

    function getBet(bytes32 bid) external view returns (Bet memory) {
        return bets[bid];
    }

    function getBets() external view returns (bytes32[] memory) {
        return betsPerPlayer[msg.sender];
    }

    function getGame(bytes32 gid) external view returns (Game memory) {
        return games[gid];
    }

    function getGames() external view returns (bytes32[] memory) {
        return gameIds;
    }

    fallback() external {
        // console.log("FALLLLBACKKKKKKKKKKKKKKK");
        // console.log(string(msg.data));
    }

    receive() external payable {
        // console.log("RECEEEEEEEEEEIVE");
        // console.log(msg.sender);
        // console.log(msg.value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "@openzeppelin/contracts/utils/Context.sol";

contract Nonce is Context{
    mapping(address => uint) private nonce;

    function incrementNonce() external {
        nonce[_msgSender()] = ++nonce[_msgSender()];
    }

    function getNonce() external view returns (uint) {
        return nonce[_msgSender()];
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.19;

enum Result {
    NEW, // Initial value
    A_WINS, // A wins
    B_WINS, // B wins
    DRAW, // Draw: no winner, no loser
    CANCELLED // Game cancelled
}

struct Game {
    string teamA; // Team A //TODO use curated data
    string teamB; // Team B //TODO use curated data
    Result result; // Game result
}

struct Bet {
    bytes32 bid; // Bid id
    bytes32 gid; // Game id
    uint amount; // Bet amount
    address owner; // Bet owner
    Result prediction; // Bet prediction
    bool paid; // Indicates when a winner bet was paid
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

// import "hardhat/console.sol";

library Utils {
    function getBalance(address addr) external view returns (uint) {
        return addr.balance;
    }

    function generateTransactionHash(
        address sender,
        uint256 nonce
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(sender, nonce));
    }
}