// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from './Ownable.sol';
import {IBoredGhostsAlpha} from './interfaces/IBoredGhostsAlpha.sol';
import {IMasterOfGhosts} from './interfaces/IMasterOfGhosts.sol';

/**
 * @dev Proxy contract (classic not transparent) to control an Ownable IBoredGhostsAlpha contract.
 * Necessary as the IBoredGhostsAlpha will be under a transparent proxy, and we want the same
 * account being proxy admin and owner there.
 * Not adapted to generic batched CALL in order to make interaction easier, without encoding
 */
contract MasterOfGhosts is Ownable, IMasterOfGhosts {
  IBoredGhostsAlpha public immutable BORED_GHOSTS_ALPHA;

  constructor(IBoredGhostsAlpha boredGhostsAlpha) {
    BORED_GHOSTS_ALPHA = boredGhostsAlpha;
  }

  function configureCollection(address[] calldata collections) external onlyOwner {
    BORED_GHOSTS_ALPHA.configureCollection(collections);
  }

  function mint(address[] calldata recipients) external onlyOwner {
    for (uint256 i = 0; i < recipients.length; i++) {
      BORED_GHOSTS_ALPHA.mint(recipients[i]);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Context} from '../../lib/solidity-utils/src/contracts/transparent-proxy/Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _transferOwnership(msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    _owner = newOwner;
    emit OwnershipTransferred(_owner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoredGhostsAlpha {
  struct CollectionConfig {
    uint8 outfitsCount;
    uint240 woreMap;
  }

  struct Outfit {
    address location;
    uint8 id;
    //string name; //TODO: maybe return it back
  }
  event NewSeasonArrived(address outfitLocation, uint256 count);
  event OutfitBorrowed(uint256 tokenId, address outfitLocation, uint64 outfitId);
  event OutfitReturned(uint256 tokenId, address outfitLocation, uint64 outfitId);

  function count() external view returns (uint256);

  function collectionConfigs(address collection) external view returns (CollectionConfig memory);

  function boringOutfits(uint256 tokenId) external view returns (Outfit memory);

  function configureCollection(address[] calldata collections) external;

  function mint(address to) external;

  function wear(uint256 tokenId, Outfit calldata attributes) external;

  function casualOutfit() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBoredGhostsAlpha} from './IBoredGhostsAlpha.sol';

/**
 * @dev Proxy contract (classic not transparent) to control an Ownable IBoredGhostsAlpha contract.
 * Necessary as the IBoredGhostsAlpha will be under a transparent proxy, and we want the same
 * account being proxy admin and owner there.
 * Not adapted to generic batched CALL in order to make interaction easier, without encoding
 */
interface IMasterOfGhosts {
  function BORED_GHOSTS_ALPHA() external view returns (IBoredGhostsAlpha);

  function configureCollection(address[] calldata collections) external;

  function mint(address[] calldata recipients) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}