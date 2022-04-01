// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract NftContract {
  function mintToken(address to, uint256 tokenId) external virtual;

  function burnToken(uint256 tokenId) external virtual;

  function exists(uint256 tokenId) external view virtual returns (bool);

  function ownerOf(uint256 tokenId) public view virtual returns (address);

  function totalSupply() public view virtual returns (uint256);

  function MAX_SUPPLY() public view virtual returns (uint256);

  function LAND_WIDTH() public view virtual returns (uint8);

  function LAND_HEIGHT() public view virtual returns (uint8);

  function setWH(
    uint256 tokenId,
    uint8 width,
    uint8 height
  ) external virtual;

  function rectOrigin(uint256 tokenId) public view virtual returns (uint256);

  function setRectOrigin(uint256 tokenId, uint256 originTokenId)
    external
    virtual;
}

contract LandControllerV1 is Ownable {
  NftContract immutable nftContract;
  uint8 immutable LAND_WIDTH;
  uint8 immutable LAND_HEIGHT;
  uint256 immutable MAX_SUPPLY;
  address minter;

  event Mint(address to, uint256 tokenId, uint8 width, uint8 height);
  event BatchMint(address to, uint256[] tokenIdList, uint8 width, uint8 height);

  constructor(address _nftContractAddress) {
    nftContract = NftContract(_nftContractAddress);
    MAX_SUPPLY = nftContract.MAX_SUPPLY();
    LAND_WIDTH = nftContract.LAND_WIDTH();
    LAND_HEIGHT = nftContract.LAND_HEIGHT();
  }

  function setMinter(address newAddress) external onlyOwner {
    minter = newAddress;
  }

  function batchMint(
    address to,
    uint256[] calldata tokenIdList,
    uint8 width,
    uint8 height
  ) external onlyOwner {
    require(
      nftContract.totalSupply() + tokenIdList.length <= MAX_SUPPLY,
      "Out of space"
    );
    for (uint256 i = 0; i < tokenIdList.length; i++) {
      _mintSpace(to, tokenIdList[i], width, height);
    }
    emit BatchMint(to, tokenIdList, width, height);
  }

  function mint(
    address to,
    uint256 tokenId,
    uint8 width,
    uint8 height
  ) external {
    require(msg.sender == minter, "Not minter");
    require(nftContract.totalSupply() + 1 <= MAX_SUPPLY, "Out of space");
    _mintSpace(to, tokenId, width, height);
    emit Mint(to, tokenId, width, height);
  }

  // Internal functions
  function _mintSpace(
    address to,
    uint256 tokenId,
    uint8 width,
    uint8 height
  ) internal {
    require(tokenId > 0, "Incorrect token id");
    (uint256 x, uint256 y) = _getXY(tokenId);
    require(
      x + width <= LAND_WIDTH + 1 && y + height <= LAND_HEIGHT + 1,
      "Out of land boundary"
    );
    for (uint256 i = x; i < x + width; i++) {
      for (uint256 j = y; j < y + height; j++) {
        uint256 currentTokenId = _getTokenId(i, j);
        require(!nftContract.exists(currentTokenId), "Not available");
        require(nftContract.rectOrigin(currentTokenId) == 0, "Not available");
        if (currentTokenId != tokenId) {
          nftContract.setRectOrigin(currentTokenId, tokenId);
        }
      }
    }
    nftContract.setWH(tokenId, width, height);
    nftContract.mintToken(to, tokenId);
  }

  function _getTokenId(uint256 x, uint256 y) internal pure returns (uint256) {
    return
      ((y - 1) / 50) *
      10000 +
      ((x - 1) / 40) *
      2000 +
      ((y - 1) % 50) *
      40 +
      ((x - 1) % 40) +
      1;
  }

  function _getXY(uint256 tokenId)
    internal
    pure
    returns (uint256 x, uint256 y)
  {
    x = (((tokenId - 1) % 10000) / 2000) * 40 + ((tokenId - 1) % 40) + 1;
    y = ((tokenId - 1) / 10000) * 50 + ((tokenId - 1) % 2000) / 40 + 1;
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