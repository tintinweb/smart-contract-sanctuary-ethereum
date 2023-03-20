// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract NostradamusLS is Ownable {
    uint256 public betAmount;
    uint256 public total;
    uint256 public minRoll;
    uint256 public maxRoll;
    uint256 public nextBetId;

    mapping(uint256 => Bet) public bets;
    mapping(address => uint256) public pay;

    struct Bet {
        address player;
        uint256 amount;
        string salt;
        uint256 playerRoll;
        uint256 playRoll;
        bool settled;
        bool won;
        uint256 timestamp;
    }

    event BetPlaced(
        uint256 indexed betId,
        address indexed player,
        uint256 amount,
        uint256 playerRoll,
        string salt
    );
    event BetSettled(uint256 indexed betId, uint256 playRoll, bool won);

    constructor() {
        betAmount = 0.01 ether;
        hash = 0xadcbdf1fce290c09ecb84b430d4d15f2d2abaebe15b368e41736b5e07895a29b;
        minRoll = 1;
        maxRoll = 100;
        nextBetId = 0;
    }

    function placeBet(
        uint lev,
        string memory salt
    ) external payable returns (uint256) {
        require(msg.value >= betAmount, "Incorrect bet amount");
        //require(msg.value * lev <= address(this).balance / 100,"Incorrect bet amount");
        uint256 playerRoll = lev;
        uint256 betId = nextBetId++;
        bets[betId] = Bet({
            player: msg.sender,
            amount: msg.value,
            playerRoll: playerRoll,
            salt: salt,
            playRoll: 0,
            settled: false,
            won: false,
            timestamp: block.timestamp
        });
        total += msg.value;
        emit BetPlaced(betId, msg.sender, msg.value, playerRoll, salt);
        return betId;
    }

    uint256 public a;
    bytes32 public hash;

    function submitRoll(bytes32 playRoll) external onlyOwner {
        Bet storage bet = bets[a++];

        require(!bet.settled, "Bet already settled");
        require(
            keccak256(abi.encodePacked(playRoll)) == hash,
            "Bet already settled"
        );
        bet.playRoll = randomRoll(playRoll, bet.salt);
        bet.settled = true;
        hash = playRoll;
        if (maxRoll / bet.playerRoll > bet.playRoll) {
            bet.won = true;
            uint256 amount = bet.amount * bet.playerRoll;
            pay[bet.player] += amount;
            total += bet.amount * bet.playerRoll - bet.amount;
            bet.amount = 0;
        } else {
            total -= bet.amount;
        }

        emit BetSettled(a, bet.playRoll, bet.won);
    }

    function defaultRoll(uint play) external onlyOwner {
        Bet storage bet = bets[play];
        require(
            bet.timestamp + 1 days < block.timestamp,
            "Bet already settled"
        );
        uint256 amount = bet.amount * bet.playerRoll;
        bet.amount = 0;
        payable(bet.player).transfer(amount);
        emit BetSettled(a, bet.playRoll, bet.won);
    }

    function withdraw() external {
        uint amount = pay[msg.sender];
        total -= pay[msg.sender];
        pay[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function randomRoll(
        bytes32 roll,
        string memory salt
    ) public view returns (uint256) {
        uint256 randomness = uint256(
            keccak256(abi.encodePacked(roll, a, salt))
        );
        return (randomness % (maxRoll - minRoll + 1)) + minRoll;
    }

    function setBetAmount(uint256 newBetAmount) external onlyOwner {
        betAmount = newBetAmount;
    }

    function withdrawHouse(uint256 amount) external onlyOwner{
        require(amount + total <= address(this).balance, "Not enough balance");
        payable(msg.sender).transfer(amount);
    }
}