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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface Ilevel {
    function completeLevel(address studentContract) external payable returns(uint8);
    }	

contract CTF is Ownable {

    // Array for frontend . frontend looks up array then multicals get score.
    address[] private addrArray;
    uint8[] private levelArray;

    // Todo - change to private
    // Todo - add password hash
    
    mapping(uint8 => address) public levels; // LevelNumber => LevelContractAddress - For level contract lookup
    mapping(address => mapping(uint8 => uint8)) public scores; // StudentWalletAddress => Level => Score
    mapping(address => string) public discordNames; // StudentWalletAddress => Name - For displaying name in React Dapp
    mapping(address => address) public solutions; // SolutionAdress => StudentAdress - Checks solutions is deployed by owner
    bool public canSubmit;
    address constant NULL = address(0);
    
    
   
   function setExamStatus(bool status) external onlyOwner {
        canSubmit = status;
   }

    function submitSolution(uint8 levelNumber, address solutionAddress) external {
        require(canSubmit == true, "Exam Not Open"); 
        require(levels[levelNumber] != NULL, "Invalid Level");
        require(bytes(discordNames[msg.sender]).length != 0, "No Registered DiscordName");
        require(solutions[solutionAddress] == NULL || solutions[solutionAddress] == msg.sender, "msg.sender not owner of solution");
        solutions[solutionAddress] = msg.sender;
        Ilevel _level = Ilevel(levels[levelNumber]); // get level address
        scores[msg.sender][levelNumber] = _level.completeLevel(solutionAddress); // submit solution to level address;
    }

    function getAddresses() public view returns (address[] memory) {
      return addrArray;
    }

    function getLevels() public view returns (uint8[] memory) {
      return levelArray;
    }

    function getScore(address addr, uint8 level) public view returns (address, string memory ,uint8, uint8) {
        uint8 score = scores[addr][level];
        string memory name = discordNames[addr];
        return (addr, name, level, score);
    }

    function setDiscordName(string calldata userName) external {
        discordNames[msg.sender] = userName;
        addrArray.push(msg.sender);
    }

    function addLevel(address levelAddress, uint8 levelNumber) external onlyOwner {
        require(levels[levelNumber] == NULL); // cannot be registered already
        levels[levelNumber] = levelAddress;
        levelArray.push(levelNumber);
    }

    function updateLevel(uint8 levelNumber, address levelAddress) external onlyOwner {
        require(levels[levelNumber] != NULL); 
        levels[levelNumber] = levelAddress;
    }
}