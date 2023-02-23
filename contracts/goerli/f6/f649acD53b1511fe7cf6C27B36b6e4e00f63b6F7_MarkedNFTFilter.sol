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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IExternalFilter is IERC165 {
  /**
   * @notice Pools can nominate an external contract to approve whether NFT IDs are accepted.
   * This is typically used to implement some kind of dynamic block list, e.g. stolen NFTs.
   * @param collection NFT contract address
   * @param nftIds List of NFT IDs to check
   * @return allowed True if swap (pool buys) is allowed
   */
  function areNFTsAllowed(address collection, uint256[] calldata nftIds, bytes calldata context)
    external
    returns (bool allowed);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IExternalFilter} from "./IExternalFilter.sol";

contract MarkedNFTFilter is Ownable, ERC165, IExternalFilter {
  using BitMaps for BitMaps.BitMap;

  mapping(address => BitMaps.BitMap) private collections;
  mapping(address => uint256) private markedCount;
  mapping(address => bool) private enabled;

  /**
   * @notice Pools can nominate an external contract to approve whether NFT IDs are accepted.
   * This is typically used to implement some kind of dynamic block list, e.g. stolen NFTs.
   * @param collection NFT contract address
   * @param nftIds List of NFT IDs to check
   * @return allowed True if swap (pool buys) is allowed
   */
  function areNFTsAllowed(address collection, uint256[] calldata nftIds, bytes calldata /* context */) external view returns (bool allowed) {
    if (!enabled[collection]) {
      return true;
    }

    uint256 length = nftIds.length;

    // this is a blacklist, so if we did not index the collection, it's allowed
    for (uint256 i; i < length;) {
      if (collections[collection].get(nftIds[i])) {
        return false;
      }

      unchecked {
        ++i;
      }
    }

    return true;
  }

  /**
   * @notice Returns marked NFTs in the same positions as the input array
   * @param collection NFT contract address
   * @param nftIds List of NFT IDs to check
   * @return marked bool[] of marked NFTs
   */
  function getMarkedNFTs(address collection, uint256[] calldata nftIds) external view returns (bool[] memory marked) {
    uint256 length = nftIds.length;
    marked = new bool[](length);

    for (uint256 i; i < length;) {
      if (collections[collection].get(nftIds[i])) {
        marked[i] = true;
      }
      else {
        marked[i] = false;
      }

      unchecked {
        ++i;
      }
    }

    return marked;
  }

  function getMarkedCount(address collection) external view returns (uint256 count) {
    return markedCount[collection];
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override (ERC165, IERC165) returns (bool) {
    return interfaceId == type(IExternalFilter).interfaceId || super.supportsInterface(interfaceId);
  }

  function markIds(address collection, uint256[] calldata nftIds) public onlyOwner {
    uint256 length = nftIds.length;

    for (uint256 i; i < length;) {
      if (!collections[collection].get(nftIds[i])) {
        collections[collection].set(nftIds[i]);
        markedCount[collection]++;
      }

      unchecked {
        ++i;
      }
    }
  }

  function unmarkIds(address collection, uint256[] calldata nftIds) public onlyOwner {
    uint256 length = nftIds.length;

    for (uint256 i; i < length;) {
      if (collections[collection].get(nftIds[i])) {
        collections[collection].unset(nftIds[i]);
        markedCount[collection]--;
      }

      unchecked {
        ++i;
      }
    }
  }

  function isEnabled(address collection) external view returns (bool) {
    return enabled[collection];
  }

  function disableCollection(address collection) public onlyOwner {
    // we cannot free the BitMap, so just set this flag to false
    delete enabled[collection];
  }

  function enableCollection(address collection) public onlyOwner {
    enabled[collection] = true;
  }
}