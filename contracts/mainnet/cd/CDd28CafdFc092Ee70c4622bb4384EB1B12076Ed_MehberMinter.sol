// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMehberCollection.sol";
import "./interfaces/IMehtaverse.sol";

contract MehberMinter is Ownable {
  IMehberCollection public MehberCollection;
  IMehtaverse public Mehtaverse;

  mapping(uint256 => bool) public tokenPublicMintEnabled;

  mapping(uint256 => mapping(address => bool)) public mintPassMinted;
  mapping(uint256 => uint256) public mintPassMints;

  constructor(address MehberAddress, address MehtaverseAddress) {
    MehberCollection = IMehberCollection(MehberAddress);
    Mehtaverse = IMehtaverse(MehtaverseAddress);
  }

  function updateMintPassAmount(uint256 tokenId, uint256 amount)
    public
    onlyOwner
  {
    mintPassMints[tokenId] = amount;
  }

  function toggleTokenPublicMint(uint256 tokenId) public onlyOwner {
    tokenPublicMintEnabled[tokenId] = !tokenPublicMintEnabled[tokenId];
  }

  function publicMint(uint256 tokenId) external {
    require(tokenPublicMintEnabled[tokenId], "PUBLIC_SALE_DISABLED");

    MehberCollection.mint(msg.sender, tokenId, 1);
  }

  function mintPassMint(uint256 tokenId) external {
    uint256 mehBalance = Mehtaverse.balanceOf(msg.sender);

    require(mehBalance > 0, "MUST_OWN_MEHS");
    require(mintPassMints[tokenId] > 0, "NO_MEHBER_MINTS");
    require(!mintPassMinted[tokenId][msg.sender], "MEHBER_ALREADY_MINTED");

    mintPassMinted[tokenId][msg.sender] = true;

    MehberCollection.mint(
      msg.sender,
      tokenId,
      mehBalance * mintPassMints[tokenId]
    );
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

interface IMehberCollection {
  /// @notice Mint a specified amount of a single token to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenId The token to mint
  /// @param amount The number of tokens to mint
  function mint(
    address to,
    uint256 tokenId,
    uint256 amount
  ) external;

  /// @notice Mint specified amounts of multiple tokens in one transaction to a single address
  /// @param to The recipient address for the newly minted tokens
  /// @param tokenIds An array of IDs for tokens to mint
  /// @param amounts As array of amounts of tokens to mint, corresponding to the tokenIds
  function mintBatch(
    address to,
    uint256[] calldata tokenIds,
    uint256[] calldata amounts
  ) external;

  /// @notice Mint specified amounts of a single token to multiple addresses
  /// @param recipients An array of addresses to received the newly minted tokens
  /// @param tokenId The token to mint
  /// @param amounts As array of the number of tokens to mint to each address
  function mintToMany(
    address[] calldata recipients,
    uint256 tokenId,
    uint256[] calldata amounts
  ) external;

  function totalSupply(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.8;

interface IMehtaverse {
  function balanceOf(address owner) external view returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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