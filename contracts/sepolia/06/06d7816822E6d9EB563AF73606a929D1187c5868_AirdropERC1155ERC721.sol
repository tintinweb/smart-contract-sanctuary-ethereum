// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { MinterAccessControl } from "./MinterAccessControl.sol";
import { IAirdropERC1155ERC721 } from "./IAirdropERC1155ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AirdropERC1155ERC721 is IAirdropERC1155ERC721, Ownable, MinterAccessControl, ReentrancyGuard {

  mapping(address => uint256) public lastTokenMinted;

  function mintERC721(
    address nft,
    bytes4 mintSig,
    address who,
    uint256[] calldata tokenIds
  ) external override onlyMinter {
    require(nft != address(0), "nft address can't be zero");
    for (uint256 i = 0; i < tokenIds.length; ++i) {
      bytes memory data = abi.encodeWithSelector(mintSig, who, tokenIds[i]);
      (bool success, ) = nft.call(data);
      require(success, "nft mint failed");
    }
  }

  function mintERC721WithoutAssignTokenIds(
    address nft,
    bytes4 mintSig,
    address who,
    uint256 amount
  ) external override onlyMinter nonReentrant {
    require(nft != address(0), "nft address can't be zero");
    uint256 startingTokenId = lastTokenMinted[nft];
    uint256 tokenMinted;
    uint256 i;
    while (tokenMinted < amount) {
      bytes memory data = abi.encodeWithSelector(mintSig, who, startingTokenId + i);
      (bool success, ) = nft.call(data);
      if (success) {
        ++tokenMinted;
      }
      ++i;
    }
    lastTokenMinted[nft] = startingTokenId + i;
  }

  function mintERC1155(
    address nft,
    bytes4 mintSig,
    address who,
    uint256 tokenId,
    uint256 amount
  ) external override onlyMinter {
    require(nft != address(0), "nft address can't be zero");
    bytes memory data = abi.encodeWithSelector(mintSig, who, tokenId, amount, "");
    (bool success, ) = nft.call(data);
    require(success, "nft mint failed");
  }

  function batchMintERC721WithoutAssignTokenIds(
    address nft,
    bytes4 mintSig,
    address[] memory who,
    uint256 amount
  ) external override onlyMinter nonReentrant {
    require(nft != address(0), "nft address can't be zero");
    uint256 startingTokenId = lastTokenMinted[nft];
    uint256 tokenMinted;
    uint256 totalShouldMint = amount * who.length;
    uint256 whoIndex;
    uint256 i;

    while (tokenMinted < totalShouldMint) {
      address mintFor = who[whoIndex];
      bytes memory data = abi.encodeWithSelector(mintSig, mintFor, startingTokenId + i);
      (bool success, ) = nft.call(data);
      if (success) {
        ++tokenMinted;
        if (tokenMinted % amount == 0) ++whoIndex;
      }
      ++i;
    }
    lastTokenMinted[nft] = startingTokenId + i;
  }

  function batchMintERC1155(
    address nft,
    bytes4 mintSig,
    address[] memory who,    
    uint256 tokenId,
    uint256 amount
  ) external override onlyMinter {
    require(nft != address(0), "nft address can't be zero");
    for (uint256 i = 0; i < who.length; ++i) {
      bytes memory data = abi.encodeWithSelector(mintSig, who[i], tokenId, amount, "");
      (bool success, ) = nft.call(data);
      require(success, "nft mint failed");
    }
  }

  function batchMintERC1155(
    address nft,
    bytes4 mintSig,
    address[] memory who,    
    uint256[] memory tokenIds,
    uint256 amount
  ) external override onlyMinter {
    require(nft != address(0), "nft address can't be zero");
    for (uint256 i = 0; i < who.length; ++i) {
      bytes memory data = abi.encodeWithSelector(mintSig, who[i], tokenIds[i], amount, "");
      (bool success, ) = nft.call(data);
      require(success, "nft mint failed");
    }
  }

  function grantMinterRole(address addr_) external virtual onlyOwner {
    super._grantMinterRole(addr_);
  }

  function revokeMinterRole(address addr_) external virtual onlyOwner {
    super._revokeMinterRole(addr_);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

interface IAirdropERC1155ERC721 {
  // mint
  function mintERC721(address nft, bytes4 selector, address who, uint256[] calldata tokenIds) external;
  function mintERC721WithoutAssignTokenIds(address nft, bytes4 selector, address who, uint256 amount) external;
  function mintERC1155(address nft, bytes4 selector, address who, uint256 tokenId, uint256 amount) external;

  // batchMint
  function batchMintERC721WithoutAssignTokenIds(address nft, bytes4 selector, address[] memory who, uint256 amount) external;
  function batchMintERC1155(address nft, bytes4 selector, address[] memory who, uint256[] memory tokenId, uint256 amount) external;
  function batchMintERC1155(address nft, bytes4 selector, address[] memory who, uint256 tokenId, uint256 amount) external;
}

interface IGrantMinterRole {
  function grantMinterRole(address addr_) external;
  function minters(address addr_) external view returns (bool);
}

interface IERC721 {
  function balanceOf(address owner) external view returns (uint256 balance);
  function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC1155 {
  function balanceOf(address account, uint256 id) external view returns (uint256);
  function balanceOfBatch(
    address[] calldata accounts,
    uint256[] calldata ids
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract MinterAccessControl {

  /// @dev a list of minter role, and only minter can mint nft
  mapping(address => bool) public minters;

  /**
    * @dev Fired in grantMinterRole()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param account an address which is granted minter role
    */
  event MinterRoleGranted(address indexed sender, address indexed account);

  /**
    * @dev Fired in revokeMinterRole()
    *
    * @param sender an address which performed an operation, usually contract owner
    * @param account an address which is revoked minter role
    */
  event MinterRoleRevoked(address indexed sender, address indexed account);

  /**
    * @notice Service function to grant minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is granted minter role
    */
  function _grantMinterRole(address addr_) internal virtual {
    require(addr_ != address(0), "invalid address");
    minters[addr_] = true;
    emit MinterRoleGranted(msg.sender, addr_);
  }

  /**
    * @notice Service function to revoke minter role
    *
    * @dev this function can only be called by owner
    *
    * @param addr_ an address which is revorked minter role
    */
  function _revokeMinterRole(address addr_) internal virtual {
    require(addr_ != address(0), "invalid address");
    minters[addr_] = false;
    emit MinterRoleRevoked(msg.sender, addr_);
  }

  /**
    * @dev Modifier that checks that an account has a minter role.
    *
    */
  modifier onlyMinter() {
      require(minters[msg.sender] == true, "permission denied");
      _;
  }

}