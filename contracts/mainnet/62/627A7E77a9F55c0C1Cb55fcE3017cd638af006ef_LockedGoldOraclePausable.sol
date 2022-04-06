//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface ICacheGold {
    function totalCirculation() external view returns (uint256);
}

interface IChainLink {
  function latestAnswer() external view returns (int256 answer);
}

/**
* @title LockedGoldOraclePausable
* @dev Read from an external contract - Chainlink Proof Of Reserves and return the information to the CACHE Token Contract
* @dev The read checks if the contract is not paused and 
* @dev the oracle value is always greater than the present circulation. In case either condition fails a ZERO value is returned
* @dev The owner is a multisig deployed by CACHE
*/
contract LockedGoldOraclePausable is Ownable, Pausable {
  
  uint8 public constant DECIMALS = 8;
  // 10^8 shortcut
  uint256 private constant TOKEN = 10 ** uint256(DECIMALS);
  // Cap on total number of tokens that can ever be produced
  uint256 public constant SUPPLY_CAP = 8133525786 * TOKEN;

  address private _cacheContract;
  address private _chainLinkContract;
  event ContractSet(address indexed, string);

  /**
  * @dev Set the CACHE token contract address
  */
  function setCacheContract(address __cacheContract) external onlyOwner {
    _cacheContract = __cacheContract;
    emit ContractSet(__cacheContract, "CACHE");
  }

  /**
  * @dev Set the Chainlink Proof Of Reserves contract address
  */
  function setChainlinkContract(address __chainLinkContract) external onlyOwner {
    _chainLinkContract = __chainLinkContract;
    emit ContractSet(__chainLinkContract, "CHAINLINK");
  }

  /**
  @dev Add pause role for owner, this is implemented as an emergency measure to pause Mint of new tokens.
  */
  function pause() external onlyOwner {
      _pause();
  }

  function unpause() external onlyOwner {
      _unpause();
  }

  /**
  * @dev Requires the Proof of Reserves amount emitted to be lower than token circulation amount emitted by CACHE Token Contract. 
  * @dev Requires that the locked Gold is less than or equal to the total supply cap of the CACHE GOLD Contract. 
  * @dev Requires that the contract is not paused. 
  * @dev CACHE Token Contract Mint return 0/revert message when this function fails above requirements.   
  */
  function lockedGold() external view whenNotPaused() returns(uint256) {
    uint _lockedGold = uint(IChainLink(_chainLinkContract).latestAnswer());
    require(_lockedGold >= ICacheGold(_cacheContract).totalCirculation(), "Insufficent grams locked");
    require(_lockedGold <= SUPPLY_CAP, "Exceeds Supply Cap");
    return _lockedGold;
  }

  function cacheContract() external view returns(address) {
    return _cacheContract;
  }
  
  function chainlinkContract() external view returns(address) {
    return _chainLinkContract;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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