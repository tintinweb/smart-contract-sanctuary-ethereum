// SPDX-License-Identifier: GPL v3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CasinoGame.sol";

/* Bet types:
    - 0 = Red, Black, Even, Odd, Low, High (Pays even)
    - 1 = Column, Dozen (Pays 2:1)
    - 2 = Line (Pays 5:1)
    - 3 = Corner (Pays 8:1)
    - 4 = Street (Pays 11:1)
    - 5 = Split (Pays 17:1)
    - 6 = Single (Pays 35:1)
*/
struct RoulettePlayer {
    uint8 betType;
    uint256 bet;
    uint8[] betNums;
}

contract Roulette is Ownable, CasinoGame {
    // State variables
    mapping (address => RoulettePlayer) private rGames;
    uint256 private nonce = 0;

    // Events (to be emitted)
    event NewRound(address player, uint256 initialBet);
    event PlayerSpinComplete(address player, uint8 spinNum);
    event RoundResult(address player, uint256 payout);

    // Constructor for initial state values, including calling parent constructor
    constructor(uint256 _minBet, uint256 _maxBet) CasinoGame(_minBet, _maxBet) {}
    
    // Handles the initial start of a roulette round. First pays the initial bet
    //  to the contract, then sets the state of the round in progress to true.
    //  Finishes by calling the spin() function to begin the game.
    function playRound(uint256 _betAmount, uint8 _betType, uint8[] memory _betNums) external {
        // Only start the round if player is not in the middle of a game or an existing round.
        // Check that the paid bet is large enough.
        require(roundInProgress[msg.sender] == false, "Already playing game.");
        require(_betAmount >= minimumBet, "Bet is too small.");
        require(_betAmount <= maximumBet, "Bet is too large.");

        // Place the user's initial bet using a CasinoGame parent function
        payContract(msg.sender, _betAmount);

        //  Initialize new game round
        setRoundInProgress(msg.sender, true);

        // Let front end know a new round has begun
        emit NewRound(msg.sender, _betAmount);

        // Handle initial spin
        spin(msg.sender, _betAmount, _betType, _betNums);
    }

    // Handles creating a new RoulettePlayer to store player attributes.
    //  Selects a random number for the game, emits an event to notify listeners, then ends the game.
    function spin(address _playerAddress, uint256 _bet, uint8 _betType, uint8[] memory _betNums) private {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");
        RoulettePlayer storage player = rGames[_playerAddress];

        player.bet = _bet;
        player.betType = _betType;
        player.betNums = _betNums;

        // Select random number on roulette board
        uint8 rnd = uint8(rand(38));
        if(rnd == 37)
            rnd = 0;

        emit PlayerSpinComplete(_playerAddress, rnd); 
        endRound(_playerAddress, rnd);       
    }

    // Handles the end of a roulette round. It pays winnings, sets the roundInProgress
    // attribute to false. Then, it resets the RoulettePlayer attributes.
    function endRound(address _playerAddress, uint8 spinNum) private {
        require(roundInProgress[_playerAddress] == true, "Not playing round.");

        RoulettePlayer storage player = rGames[_playerAddress];
        uint256 totalPayout = 0;
        bool won = numInArray(spinNum, player.betNums);

        if(won) {
            // Begin by paying back initial bet
            totalPayout += player.bet;
            if(player.betType == 0)
                totalPayout += player.bet; // Pays even
            else if(player.betType == 1)
                totalPayout += player.bet * 2; // Pays 2:1
            else if(player.betType == 2)
                totalPayout += player.bet * 5; // Pays 5:1
            else if(player.betType == 3)
                totalPayout += player.bet * 8; // Pays 8:1
            else if(player.betType == 4)
                totalPayout += player.bet * 11; // Pays 11:1
            else if(player.betType == 5)
                totalPayout += player.bet * 17; // Pays 17;1
            else if(player.betType == 6)
                totalPayout += player.bet * 35; // Pays 35:1
            
            rewardUser(_playerAddress, totalPayout);
        }

        emit RoundResult(_playerAddress, totalPayout);

        setRoundInProgress(_playerAddress, false);
        resetRGame(_playerAddress);
    }

    // Resets a RoulettePlayer and all the internal attributes.
    // Currently not sure if we need to delete the arrays in the structs
    //  before deleting rGames[_playerAddress] to avoid memory leaks?
    function resetRGame(address _playerAddress) private {
        RoulettePlayer storage player = rGames[_playerAddress];
        // Reset attribute
        delete player.betNums;
        // Delete game entry in mapping
        delete rGames[_playerAddress];
    }

    // Returns true if the provided num is in the provided arr, otherwise false.
    function numInArray(uint8 num, uint8[] memory arr) private pure returns(bool) {
        for(uint i = 0; i < arr.length; i++) {
            if(arr[i] == num)
                return true;
        }
        return false;
    }

    // Generates a random number, 0 to _upper (non-inclusive), to be used for card selection.
    // Not truly random, but good enough for the needs of this project.
    // A mainnet application should use something like Chainlink VRF for this task instead.
    function rand(uint256 _upper) public returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number + nonce
        )));

        nonce++;

        return (seed - ((seed / _upper) * _upper));
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

// SPDX-License-Identifier: GPL v3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface CasinoInterface {
    function payWinnings(address _to, uint256 _amount) external;
    function transferFrom(address _from, uint256 _amount) external;
}

interface ChipInterface {
    function balanceOf(address account) external view returns (uint256);
    function casinoTransferFrom(address _from, address _to, uint256 _value) external;
}

/* The CasinoGame contract defines top-level state variables
*  and functions that all casino games must have. More game-specific
*  variables and functions will be defined in subclasses that inherit it.
*/
abstract contract CasinoGame is Ownable {

    // State variables
    CasinoInterface private casinoContract;
    ChipInterface private chipContract;
    uint256 internal minimumBet;
    uint256 internal maximumBet;
    mapping (address => bool) internal roundInProgress;
    
    // Events (to be emitted)
    event ContractPaid(address player, uint256 amount);
    event RewardPaid(address player, uint256 amount);

    // Constructor for initial state values
    constructor(uint256 _minBet, uint256 _maxBet) {
        minimumBet = _minBet;
        maximumBet = _maxBet;
    }

    // Sets the address of the Casino contract.
    function setCasinoContractAddress(address _address) external onlyOwner {
        casinoContract = CasinoInterface(_address);
    }

    // Sets the address of the Chip contract.
    function setChipContractAddress(address _address) external onlyOwner {
        chipContract = ChipInterface(_address);
    }


    // Sets the minimum bet required for all casino games.
    function setMinimumBet(uint256 _bet) external onlyOwner {
        require(_bet >= 0, "Bet is too low.");
        minimumBet = _bet;
    }
    
    // Sets the maximum bet allowed for all casino games.
    function setMaximumBet(uint256 _bet) external onlyOwner {
        require(_bet >= 0, "Bet is too high.");
        maximumBet = _bet;
    }

     // Sets the value of roundInProgress to true or false for a player.
    function setRoundInProgress(address _address, bool _isPlaying) internal {
        roundInProgress[_address] = _isPlaying;
    }

    // Getters
    function getCasinoContractAddress() public view returns (address) {return address(casinoContract);}
    function getChipContractAddress() public view returns (address) {return address(chipContract);}
    function getMinimumBet() public view returns (uint256) {return minimumBet;}
    function getMaximumBet() public view returns (uint256) {return maximumBet;}
    function getRoundInProgress(address _address) public view returns (bool) {return roundInProgress[_address];}

    // Rewards the user for the specified amount if they have won
    // anything from a casino game. Uses the Casino contract's payWinnings
    // function to achieve this.
    function rewardUser(address _user, uint256 _amount) internal {
        require(_amount >= 0, "Not enough to withdraw.");
        casinoContract.payWinnings(_user, _amount);
        emit RewardPaid(_user, _amount);
    }

    // Allows a user to place a bet by paying the contract the specified amount.
    function payContract(address _address, uint256 _amount) internal {
        require(chipContract.balanceOf(_address) >= _amount, "Not enough tokens.");
        casinoContract.transferFrom(_address, _amount);
        emit ContractPaid(_address, _amount);
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