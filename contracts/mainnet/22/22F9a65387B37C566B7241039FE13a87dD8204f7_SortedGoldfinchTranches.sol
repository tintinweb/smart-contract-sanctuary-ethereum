/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

// File: alloyx-smart-contracts-v2/contracts/alloyx/interfaces/ISortedGoldfinchTranches.sol


pragma solidity ^0.8.7;

/**
 * @title SortedGoldfinchTranches Interface
 * @notice A editable sorted list of tranch pool addresses according to score
 * @author AlloyX
 */
interface ISortedGoldfinchTranches {
  /**
   * @notice A method to get the top k tranch pools
   * @param k the top k tranch pools
   */
  function getTop(uint256 k) external view returns (address[] memory);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: alloyx-smart-contracts-v2/contracts/alloyx/SortedGoldfinchTranches.sol


pragma solidity ^0.8.7;



/**
 * @title SortedGoldfinchTranches
 * @notice A editable sorted list of tranch pool addresses according to score
 * @author AlloyX
 */
contract SortedGoldfinchTranches is ISortedGoldfinchTranches, Ownable {
  mapping(address => uint256) public scores;
  mapping(address => address) _nextTranches;
  uint256 public listSize;
  address constant GUARD = address(1);

  constructor() public {
    _nextTranches[GUARD] = GUARD;
  }

  /**
   * @notice A method to add a tranch with a score
   * @param tranch the address of the tranch pool address
   * @param score the score of the tranch pool address
   */
  function addTranch(address tranch, uint256 score) public onlyOwner {
    require(_nextTranches[tranch] == address(0));
    address index = _findIndex(score);
    scores[tranch] = score;
    _nextTranches[tranch] = _nextTranches[index];
    _nextTranches[index] = tranch;
    listSize++;
  }

  /**
   * @notice A method to increase the score of a tranch pool
   * @param tranch the address of the tranch pool address
   * @param score the score of the tranch pool address to increase by
   */
  function increaseScore(address tranch, uint256 score) external onlyOwner {
    updateScore(tranch, scores[tranch] + score);
  }

  /**
   * @notice A method to reduce the score of a tranch pool
   * @param tranch the address of the tranch pool address
   * @param score the score of the tranch pool address to reduce by
   */
  function reduceScore(address tranch, uint256 score) external onlyOwner {
    updateScore(tranch, scores[tranch] - score);
  }

  /**
   * @notice A method to update the score of a tranch pool
   * @param tranch the address of the tranch pool address
   * @param newScore the score of the tranch pool address to update to
   */
  function updateScore(address tranch, uint256 newScore) public onlyOwner {
    require(_nextTranches[tranch] != address(0));
    address prevTranch = _findPrevTranch(tranch);
    address nextTranch = _nextTranches[tranch];
    if (_verifyIndex(prevTranch, newScore, nextTranch)) {
      scores[tranch] = newScore;
    } else {
      removeTranch(tranch);
      addTranch(tranch, newScore);
    }
  }

  /**
   * @notice A method to remove the tranch pool address
   * @param tranch the address of the tranch pool address
   */
  function removeTranch(address tranch) public onlyOwner {
    require(_nextTranches[tranch] != address(0));
    address prevTranch = _findPrevTranch(tranch);
    _nextTranches[prevTranch] = _nextTranches[tranch];
    _nextTranches[tranch] = address(0);
    scores[tranch] = 0;
    listSize--;
  }

  /**
   * @notice A method to get the top k tranch pools
   * @param k the top k tranch pools
   */
  function getTop(uint256 k) external view override returns (address[] memory) {
    require(k <= listSize);
    address[] memory tranchLists = new address[](k);
    address currentAddress = _nextTranches[GUARD];
    for (uint256 i = 0; i < k; ++i) {
      tranchLists[i] = currentAddress;
      currentAddress = _nextTranches[currentAddress];
    }
    return tranchLists;
  }

  /**
   * @notice A method to verify the next tranch is valid
   * @param prevTranch the previous tranch pool address
   * @param newValue the new score
   * @param nextTranch the next tranch pool address
   */
  function _verifyIndex(
    address prevTranch,
    uint256 newValue,
    address nextTranch
  ) internal view returns (bool) {
    return
      (prevTranch == GUARD || scores[prevTranch] >= newValue) &&
      (nextTranch == GUARD || newValue > scores[nextTranch]);
  }

  /**
   * @notice A method to find the index of the newly added score
   * @param newValue the new score
   */
  function _findIndex(uint256 newValue) internal view returns (address) {
    address candidateAddress = GUARD;
    while (true) {
      if (_verifyIndex(candidateAddress, newValue, _nextTranches[candidateAddress]))
        return candidateAddress;
      candidateAddress = _nextTranches[candidateAddress];
    }
    return address(0);
  }

  /**
   * @notice A method to tell if the previous tranch is ahead of current tranch
   * @param tranch the current tranch pool
   * @param prevTranch the previous tranch pool
   */
  function _isPrevTranch(address tranch, address prevTranch) internal view returns (bool) {
    return _nextTranches[prevTranch] == tranch;
  }

  /**
   * @notice A method to find the previous tranch pool
   * @param tranch the current tranch pool
   */
  function _findPrevTranch(address tranch) internal view returns (address) {
    address currentAddress = GUARD;
    while (_nextTranches[currentAddress] != GUARD) {
      if (_isPrevTranch(tranch, currentAddress)) return currentAddress;
      currentAddress = _nextTranches[currentAddress];
    }
    return address(0);
  }
}