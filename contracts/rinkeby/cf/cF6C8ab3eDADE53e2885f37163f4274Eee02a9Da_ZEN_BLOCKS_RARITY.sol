// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: mhxalt.eth
/// @author: seesharp.eth

import "@openzeppelin/contracts/access/Ownable.sol";

interface DATA_BLOCKS {
  function maxSupply() external view returns (uint256);
  function mintZenBlockActiveTs() external view returns (uint256);
}

interface ZEN_BLOCKS {
  function totalSupply() external view returns (uint256);
}

contract ZEN_BLOCKS_RARITY is Ownable {
  uint256 public PROVENANCE_HASH = 0;
  uint256 public startingIndexBlock = 0;
  uint256 public startingIndex = 0;
  uint256[] public rarityWinners = new uint256[](6);

  address public zenBlocksContract;
  address public dataBlocksContract;

  constructor(address _zenBlocksContract, address _dataBlocksContract) {
    zenBlocksContract = _zenBlocksContract;
    dataBlocksContract = _dataBlocksContract;
  }

  function setProvenanceHash(uint256 _provenanceHash) public onlyOwner {
    require(PROVENANCE_HASH == 0, "Provenance Hash Already Set!");
    PROVENANCE_HASH = _provenanceHash;
  }

  function setStartingIndexBlock() public {
    require(startingIndexBlock == 0, "startingIndexBlock alredy set!");
    DATA_BLOCKS db = DATA_BLOCKS(dataBlocksContract);

    require(db.mintZenBlockActiveTs() == 0, "zen block minting hasn't ended");

    startingIndexBlock = block.number;
  }

  function setStartingIndex() public {
    require(startingIndexBlock != 0, "startingIndexBlock not set!");
    require(startingIndex == 0, "startingIndex already set!");

    DATA_BLOCKS db = DATA_BLOCKS(dataBlocksContract);
    ZEN_BLOCKS zb = ZEN_BLOCKS(zenBlocksContract);

    uint256 maxSupplyDB = db.maxSupply();

    uint256 usedHash = uint256(blockhash(startingIndexBlock));
    // Just a sanity case in the worst case if this function is called late (EVM only stores last 256 block hashes)
    if ((block.number - startingIndexBlock) > 255) {
      usedHash = uint256(blockhash(block.number - 1));
    }
    startingIndex = usedHash % maxSupplyDB;
    // Prevent default sequence
    if (startingIndex == 0) {
        startingIndex = startingIndex + 1;
    }

    uint256 supplyZB = zb.totalSupply();
    uint256 random_idx = 0;
    for (uint256 i = 0; i < 6; i++) {
      bool duplicate = true;
      while (duplicate) {
        duplicate = false;

        random_idx += 1;
        rarityWinners[i] = uint256(keccak256(abi.encodePacked(usedHash + random_idx))) % (supplyZB - i);
        for (uint256 j = 0; j < i; j++) {
          if (rarityWinners[i] == rarityWinners[j]) {
            duplicate = true;
            break;
          }
        }
      }
    }
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