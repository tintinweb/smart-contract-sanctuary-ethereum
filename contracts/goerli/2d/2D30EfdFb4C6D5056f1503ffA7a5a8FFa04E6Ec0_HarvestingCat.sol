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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NoEtherSent();

interface ERCBase {
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  function getApproved(uint256 tokenId) external view returns (address);
}

interface ERC721Partial is ERCBase {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface ERC1155Partial is ERCBase {
  function transferFrom(address from, address to, uint256 tokenId) external;
}

contract HarvestingCat is ReentrancyGuard, Ownable {
  //contract variables
  uint256 public buybackFee;
  uint256 public amountToSend;
  address payable public VAULT;

  //ERC-165 identifier
  bytes4 _ERC721 = 0x80ac58cd;
  bytes4 _ERC1155 = 0xd9b67a26;

  //events
  event NftSold(address seller, address tokenContract, uint256 tokenId);
  event NftBoughtback(address seller, address tokenContract, uint256 tokenId);
  event WithdrewToken(address owner, address tokenContract, uint256 tokenId);

  function sell(address tokenContract, uint256 tokenId) public {
    require(address(this).balance > amountToSend, "Not enough ether in contract.");
    (bool sent, ) = payable(msg.sender).call{ value: amountToSend }("");
    require(sent, "Failed to send ether.");
    ERCBase token = ERCBase(tokenContract);
    require(token.getApproved(tokenId) == address(this), "You need to approve token transfer");
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).transferFrom(msg.sender, address(this), tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).transferFrom(msg.sender, address(this), tokenId);
    }
    emit NftSold(msg.sender, tokenContract, tokenId);
  }

  function buyback(address tokenContract , uint256 tokenId) public payable {
    if (msg.value == 0) {
      revert NoEtherSent();
    }
    require(msg.value >= buybackFee + 1, "You need to send at least 0.03 eth (buyback fee) + 1 wei (10^-18 eth)");
    require(msg.sender.balance > msg.value, "You do not have enough ether");
    (bool sent, ) = payable(address(this)).call{ value: msg.value }("");
    require(sent, "Failed to send ether.");
    ERCBase token = ERCBase(tokenContract);
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).transferFrom(address(this), msg.sender, tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).transferFrom(address(this), msg.sender, tokenId);
    }
    emit NftBoughtback(msg.sender, tokenContract, tokenId);
  }


  function withdrawToken(address tokenContract, uint256 tokenId) public onlyOwner {
    ERCBase token = ERCBase(tokenContract);
    if (token.supportsInterface(_ERC721)) {
      ERC721Partial(tokenContract).transferFrom(address(this), VAULT, tokenId);
    } else if (token.supportsInterface(_ERC1155)) {
      ERC1155Partial(tokenContract).transferFrom(address(this), VAULT, tokenId);
    }
    emit WithdrewToken(msg.sender, tokenContract, tokenId);
  }

  function setVaultAddress(address vault) public onlyOwner {
    VAULT = payable(vault);
  }

  function setAmountToSend(uint256 amount) public onlyOwner {
    amountToSend = amount;
  }

  function setBuybackFee(uint256 amount) public onlyOwner {
    buybackFee = amount;
  }

  receive() external payable {}
}