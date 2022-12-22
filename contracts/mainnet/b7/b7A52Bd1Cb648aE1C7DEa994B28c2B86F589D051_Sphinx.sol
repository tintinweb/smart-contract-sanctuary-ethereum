// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

// User submits answers 3 riddles, first person to get them all right wins.
// The winners will share 69% of the pool according to the proportion they staked.
contract Sphinx is Ownable {

  bytes32 private solution;
  uint private minimum = 0.025 ether;
  uint private maximum = 1.0 ether;
  bool private gameClosed = false;
  uint public numEntries = 0;
  uint public timestamp;
  address public winner;

  event Fail(string message);
  event Receipt(string message);

  mapping(address => uint) public participants;

  //deploy with solutions, set 1 day time limit [16 hours for testing]
  constructor(bytes32 _solution) {
      solution = _solution;
      timestamp = block.timestamp + 87000;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  // Accept 3 guesses + compare to solutions
  function entry(string memory answer) external payable callerIsUser {

    require (
      block.timestamp < timestamp, 
      "the game has closed"
    );

    require(
      msg.value >= minimum,
      "entry cost too low"
    );

    require(
      msg.value <= maximum,
      "entry cost too high"
    );

    if (bytes(answer).length > 0) {
      numEntries++;
      emit Receipt("Confirmed");
    }else{
      emit Fail("Error");
    }
  }

  function reveal(
    string memory answerA, 
    string memory answerB, 
    string memory answerC, 
    string memory secretSalt) external view onlyOwner returns (bytes32) {
      string memory revealedSolution = string.concat(answerA, answerB, answerC,secretSalt);
      bytes32 testHash = sha256(abi.encodePacked((revealedSolution)));
      return testHash;
  }

  function getNumEntries() public view returns (uint) {
    return numEntries;
  }

  function getContractBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }

  // Withdraw entire balance
  function withdrawAll() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  // For testing
  function manualGameOpen() external onlyOwner {
    gameClosed = false;
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