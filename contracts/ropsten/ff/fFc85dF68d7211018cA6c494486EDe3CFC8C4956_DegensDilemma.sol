pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


abstract contract DDNFTInterface {
  using Counters for Counters.Counter;
  Counters.Counter public tokenIdCount;

  function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract DegensDilemma is Ownable {
  bool gameActive = false;

  mapping(uint256 => uint256) private _opponents;
  mapping(uint256 => uint256) private _playerBalance; // player's balance in gwei

  DDNFTInterface DDNFTContract;

  function setDDNFTAddress(address _address) external onlyOwner {
    DDNFTContract = DDNFTInterface(_address);
  }

  function startGame() public onlyOwner {
    gameActive = true;

    uint256[] memory participants = new uint256[](DDNFTContract.tokenIdCount());

    _pairParticipants(participants);
  }

  function _pairParticipants(uint256[] memory _participants) internal {
    uint256[] memory activeParticipants = _getActiveParticipants(_participants);

    for (uint256 i = 0; i < activeParticipants.length; i++) {
      if (_opponents[i] == 0) {
        uint256 opponent = _findOpponent(i, _getUnpairedParticipants(activeParticipants, i));
        _opponents[i] = opponent;
        _opponents[opponent] = i;
      }
    }
  }

  function _getActiveParticipants(uint256[] memory _participants) internal view returns(uint256[] memory) {
    uint256[] memory activeParticipants;

    for (uint256 i = 0; i < _participants.length; i++) {
      if (DDNFTContract.ownerOf(i) != address(0)) {
        activeParticipants[i] = i;
      }
    }

    return activeParticipants;
  }

  function _getUnpairedParticipants(uint256[] memory _participants, uint256 startingIndex) internal view returns(uint256[] memory) {
    uint256[] memory unpairedParticipants;

    for (uint256 i = startingIndex; i < _participants.length; i++) {
      if (_opponents[i] == 0) {
        unpairedParticipants[i] = i;
      }
    }

    return unpairedParticipants;
  }

  function _findOpponent(uint256 _id, uint256[] memory _participants) internal view returns (uint256) {
    uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, _id, _participants.length)));
    return _participants[rand % _participants.length];
  }

  function getOpponent(uint256 _id) public view returns (uint256) {
    return _opponents[_id];
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