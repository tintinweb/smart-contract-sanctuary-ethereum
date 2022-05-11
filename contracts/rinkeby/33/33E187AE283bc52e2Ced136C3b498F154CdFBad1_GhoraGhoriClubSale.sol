/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: GhoraGhoriClubSale.sol


pragma solidity ^0.8.7;



interface IERC1155 {
  function mintBatch(address _to, uint256 _amount, string[] calldata _uris) external;
  function mintFungible(address _to, uint256 _id, uint256 _amount) external;
  function burn(address _owner, uint256 _tokenId, uint256 _amount) external;
  function balanceOf(address _owner, uint256 _id) external view returns(uint256);
  function setURI(uint256 _id, string calldata _newURI) external;
}

/**
 *
 *      ╔═╗╦ ╦╔═╗╦═╗╔═╗  ╔═╗╦ ╦╔═╗╦═╗╦  ╔═╗╦  ╦ ╦╔╗
 *      ║ ╦╠═╣║ ║╠╦╝╠═╣  ║ ╦╠═╣║ ║╠╦╝║  ║  ║  ║ ║╠╩╗
 *      ╚═╝╩ ╩╚═╝╩╚═╩ ╩  ╚═╝╩ ╩╚═╝╩╚═╩  ╚═╝╩═╝╚═╝╚═╝
 *
 *  GHora Ghori Club - Created by SXTW//MΞTΛ & Ryuzaki01
 *
 */
 /// @custom:security-contact [email protected]
contract GhoraGhoriClubSale is Ownable, ReentrancyGuard {
  IERC1155 public nft;

  bool     public enableSale = false;
  uint256  public price = 0.003 ether;
  uint256  public limitPerOrder;

  address private tokenAddress;
  mapping(uint256 => uint8) private burnerList;

  event NFTUpgrade(address buyer, uint256 _id, uint256 _burnId, uint256 _burnAmount);

  struct Burner {
    uint256 tokenId;
    uint8 reqAmount;
  }

  constructor(
    address _tokenAddress,
    uint256 _limitPerOrder,
    bool _enableSale
  ) Ownable() ReentrancyGuard() {
    nft = IERC1155(_tokenAddress);
    tokenAddress = _tokenAddress;
    limitPerOrder = _limitPerOrder;
    enableSale = _enableSale;
  }

  function toggleSale() public onlyOwner {
    enableSale = !enableSale;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setTokenAddress(address _tokenAddress) public onlyOwner {
    nft = IERC1155(_tokenAddress);
    tokenAddress = _tokenAddress;
  }

  function setBurnerList(Burner[] calldata _burnerlist) public onlyOwner {
    for (uint256 i = 0; i < _burnerlist.length;) {
      burnerList[_burnerlist[i].tokenId] = _burnerlist[i].reqAmount;
      unchecked { i++; }
    }
  }

  function mergeNFT(uint256 _tokenId, uint256 _burnerTokenId, string memory _newURI) external nonReentrant senderIsUser {
    uint8 requiredAmount = burnerList[_burnerTokenId];
    require(requiredAmount > 0, "You are not allowed to merge this");

    require(bytes(_newURI).length > 0, "You have to set the new URI");
    require(nft.balanceOf(msg.sender, _burnerTokenId) >= requiredAmount, "You don't have enough NFT to merge");
    require(nft.balanceOf(msg.sender, _tokenId) == 1, "You are not the owner");

    nft.burn(msg.sender, _burnerTokenId, requiredAmount);
    nft.setURI(_tokenId, _newURI);
    emit NFTUpgrade(msg.sender, _tokenId, _burnerTokenId, requiredAmount);
  }

  function saleMint(uint256 _amount, string[] memory _uris) public payable nonReentrant mintRequirement(_amount) senderIsUser {
    require(price * _amount <= msg.value, "Ether value sent is not correct");

    nft.mintBatch(msg.sender, _amount, _uris);
  }

  function creatorMint(uint256 _amount, string[] memory _uris) public nonReentrant onlyOwner {
    nft.mintBatch(msg.sender, _amount, _uris);
  }

  function withdrawETH() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  modifier mintRequirement(uint256 _amount) {
    require(enableSale, "Sale is not active");
    require(_amount <= limitPerOrder, "Purchase would exceed limit per order");
    _;
  }

  modifier senderIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
}