// SPDX-License-Identifier: MIT
//.___________. __  .__   __. ____    ____      ___           _______..___________..______        ______
//|           ||  | |  \ |  | \   \  /   /     /   \         /       ||           ||   _  \      /  __  \
//`---|  |----`|  | |   \|  |  \   \/   /     /  ^  \       |   (----``---|  |----`|  |_)  |    |  |  |  |
//    |  |     |  | |  . `  |   \_    _/     /  /_\  \       \   \        |  |     |      /     |  |  |  |
//    |  |     |  | |  |\   |     |  |      /  _____  \  .----)   |       |  |     |  |\  \----.|  `--'  |
//    |__|     |__| |__| \__|     |__|     /__/     \__\ |_______/        |__|     | _| `._____| \______/

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EmissionRateManager is Ownable {

  struct EmissionRate {
    uint256 value; // # of $ASTRO minted per day
    uint256 timestamp; // Timestamp when this rate takes effect
  }

  uint256 public constant WAD = 1e17;

  // Mapping from token rarity to all rates in chronological order
  mapping(uint256 => EmissionRate[]) public emissionRates;

  constructor() {
    // Setting up initial emission rate

    // Rarity 0 - Token ranking from 1501 - 3000, 8 tokens per day
    emissionRates[0].push(EmissionRate(80 * WAD, block.timestamp));

    // Rarity 1 - Token ranking from 501 - 1500, 12 tokens per day
    emissionRates[1].push(EmissionRate(120 * WAD, block.timestamp));

    // Rarity 2 - Token ranking from 101 - 500, 15 tokens per day
    emissionRates[2].push(EmissionRate(150 * WAD, block.timestamp));

    // Rarity 3 - Token ranking from 11 - 100, 20 tokens per day
    emissionRates[3].push(EmissionRate(200 * WAD, block.timestamp));

    // Rarity 4  - Token ranking from 1 - 10, 100 tokens per day
    emissionRates[4].push(EmissionRate(1000 * WAD, block.timestamp));
  }

  function setEmissionRate(uint256[] calldata rarities, uint256[] calldata rates) external onlyOwner {
    require(rarities.length > 0 && rarities.length == rates.length, "Invalid parameters");

    unchecked {
      for (uint256 i = 0; i < rarities.length; i++) {
        emissionRates[rarities[i]].push(
          EmissionRate(rates[i] * WAD, block.timestamp)
        );
      }
    }
  }

  function currentEmissionRate(uint256 tokenRarity) public view returns (uint256 emissionRate) {
    uint256 numRates = emissionRates[tokenRarity].length;
    if (numRates > 0) {
      emissionRate = emissionRates[tokenRarity][numRates - 1].value;
    }
  }

  function amountToMint(uint256 tokenRarity, uint256 timestamp, uint256 interval) public view returns (uint256 amount, uint256 newTimestamp) {
    EmissionRate[] memory rates = emissionRates[tokenRarity];
    uint256 numRates = rates.length;
    require(numRates > 0, "No rates");

    uint256 numIntervals = (block.timestamp - timestamp) / interval;
    newTimestamp = timestamp + numIntervals * interval;

    if (numIntervals > 0) {
      uint256 end = timestamp;
      uint256 idx = 0;
      for (uint256 i = 0; i < numIntervals; i++) {
        end += interval;
        
        while (idx < numRates && rates[idx].timestamp < end) {
          idx++;
        }

        amount += rates[idx - 1].value;
      }
    }
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