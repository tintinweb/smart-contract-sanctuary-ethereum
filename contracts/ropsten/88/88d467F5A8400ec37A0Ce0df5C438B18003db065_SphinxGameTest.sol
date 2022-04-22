// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

 
// Riddle game. User submits 3 riddles, first person to get them all right wins.
// All verification is done on chain
// Keeps track of number of entries [total and per user]
// Closes 3 days/72hrs after deployment [see timestamp logic]
// Full balance will be withdrawn and 69% sent to the winner
contract SphinxGameTest is Ownable {

  string private solution1;
  string private solution2;
  string private solution3;
  uint private price = 10000000000000000;
  bool private gameClosed = false;
  uint public numEntries = 0;
  uint private timestamp;
  address public winner;

  event Win(string message);
  event Loss(string message);

  mapping(address => uint) public participants;

  //deploy with solutions, set 3 day time limit [16 hours for testing]
  constructor(string memory _solution1, string memory _solution2, string memory _solution3) {
      solution1 = _solution1;
      solution2 = _solution2;
      solution3 = _solution3;
      timestamp = block.timestamp + 60000;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  //Accept 3 guesses + compare to solutions
  function entry(string memory answer1, string memory answer2, string memory answer3) external payable callerIsUser
  {
    require (block.timestamp < timestamp, 
        "the game has closed"
    );

    require(
        gameClosed == false,
        "the game has closed"
    );

    require(
        msg.value >= price,
        "entry cost too low"
    );

    bytes32 answer1Hash = sha256(abi.encodePacked((answer1)));
    bytes32 answer2Hash = sha256(abi.encodePacked((answer2)));
    bytes32 answer3Hash = sha256(abi.encodePacked((answer3)));


    if (compareStrings(answer1Hash, solution1) && compareStrings(answer2Hash, solution2) && compareStrings(answer3Hash, solution3)) {
        gameClosed = true;
        numEntries++;
        participants[msg.sender] = participants[msg.sender] + 1;
        winner = msg.sender;
        emit Win("Win");
    }
    else {
        numEntries++;
        participants[msg.sender] = participants[msg.sender] + 1;
        emit Loss("Loss");
    }
  }

  //String comparison 
  function compareStrings (bytes32 a, string memory b) public pure returns (bool) {
      return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
  }

  //To calculate number of entries + pool size
  function getNumEntries() public view returns (uint) {
      return numEntries;
  }

  //To display close time/date on frontend
  function getTimestamp() public view returns (uint) {
      return timestamp;
  }

  //Withdraw entire balance
  function withdrawAll() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  //For testing
  function manualGameOpen() external onlyOwner {
    gameClosed = false;
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