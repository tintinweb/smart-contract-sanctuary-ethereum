/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

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
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns(address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns(bytes calldata) {
        return msg.data;
    }
}


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * By default, the owner account will be the one that deploys the contract.
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
        require(owner() == _msgSender(), "Not an owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
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


interface IWeb3TalentsShow {
   function getTokenId(address owner) external view returns (uint256);
}


pragma solidity ^0.8.19;

error NotAnJury();
error TimeIsOver();
error InvalidMember();
error TokenAlreadyUsed();
error ContractIsPaused();

contract TalentsVoting is Ownable {
   uint256 private endTime;
   uint256 public constant MAX_JURY_VOTES = 3;

   address public winner;
   IWeb3TalentsShow private token;

   bool public isVoteEnd;
   bool public pause = true;

   address[] public jurys;
   address[] public members;

   mapping(uint256 => bool) public usedTokens;
   mapping(address => uint256) public votesPerMember;
   mapping(address => uint256) public avaliableJuryVotes;

   event NewWinner(address indexed winner, uint256 time);

   constructor(
      address[] memory _jurys,
      address[] memory _members,
      IWeb3TalentsShow _token) {

         jurys = _jurys;
         members = _members;
         token = _token;
   }

   //===============================================================
   //                        Modifiers
   //===============================================================

   modifier voteIsOpen() {
      if (pause != false) revert ContractIsPaused();

      if (endTime <= block.timestamp) revert TimeIsOver();
      _;
   }

   modifier isValidJury(address jury) {
      if (_checkJury(jury) == false) revert NotAnJury();
      _;
   }

   modifier isValidMember(address member) {
      if (_checkMember(member) == false) revert InvalidMember();
      _;
   }

   //===============================================================
   //                      Setter Functions
   //===============================================================

   function setPause() external onlyOwner {
      pause = !pause;
   }

   function setTimer(uint256 _hours) external onlyOwner {
      uint256 startTime = block.timestamp;
      endTime = startTime + (_hours * 1 hours);
   }

   //===============================================================
   //                  View Functions
   //===============================================================

   function getStatus() public view returns (bool, address) {
      return (isVoteEnd, winner);
   }

   //===============================================================
   //                  Voting functions
   //===============================================================

   function voteAsJury(address member)
      external
      voteIsOpen
      isValidJury(msg.sender)
      isValidMember(member)
   {
      address jury = _msgSender();

      if (avaliableJuryVotes[jury] < 3) {
         unchecked {
            votesPerMember[member] += 100;
            avaliableJuryVotes[member]++;
         }
      }

   }

   function voteAsUser(address member)
      external
      voteIsOpen
      isValidMember(member) {
      address voter = _msgSender();
      uint256 tokenId = token.getTokenId(voter);

      if (usedTokens[tokenId] == true) revert TokenAlreadyUsed();

      usedTokens[tokenId] = true;
      unchecked {
         votesPerMember[member]++;
      }
   }

   //===============================================================
   //                  Count Votes Function
   //===============================================================

   function countVotes() external onlyOwner {
      if (endTime <= block.timestamp) revert TimeIsOver();

      (uint256[] memory _votes) = _getAllVotes();
      uint256 lenVotes = _votes.length;
      uint256 maxNumber;
      uint256 maxIndex;

      for (uint256 i = 0; i < lenVotes; i = _uncheckedIncrement(i)) {
         if (_votes[i] > maxNumber) {
            maxNumber = _votes[i];
            maxIndex = i;
         }
      }

      isVoteEnd = true;
      winner = members[maxIndex];
      emit NewWinner(winner, block.timestamp);
   }

   //===============================================================
   //                  Internal Functions
   //===============================================================

   function _checkJury(address jury) internal view returns (bool) {

      if (jurys[0] != jury && jurys[1] != jury && jurys[2] != jury) {
         return false;
      }
      return true;
   }

   function _checkMember(address member) internal view returns (bool) {

      if (
         members[0] != member &&
         members[1] != member &&
         members[2] != member &&
         members[3] != member &&
         members[4] != member) {

            return false;
         }
      return true;
   }

   function _getAllVotes() internal view returns (uint256[] memory) {
      uint256[] memory _votes = new uint256[](5);
      uint256 len = _votes.length;

      for (uint256 i = 0; i < len; i = _uncheckedIncrement(i)) {
         _votes[i] = (votesPerMember[members[i]]);
      }

      return _votes;
   }

   function _uncheckedIncrement(uint256 i) internal pure returns (uint256) {
      unchecked {
         i++;
      }
      return i;
   }
}