pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface SI {
    function mint(address to) external returns (uint);
    function getTokenLimit() external view returns (uint256);
    function checkPool() external view returns (uint);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}

contract SolidsSimpleMinter is Ownable{
  address public ERC721;
  address public artist;
  uint public price;
  uint public maxMint;

  constructor(address _erc721Address, address _artist, uint _amountInWei, uint _maxMint) {
        ERC721 = _erc721Address;
        artist = _artist;
        price = _amountInWei;
        maxMint = _maxMint;
    }

  function setAddresses (address _erc721Address, address _artist) external onlyOwner {
    ERC721 = _erc721Address;
    artist = _artist;
  }

  function setPrice (uint _amountInWei) external onlyOwner {
    price = _amountInWei;
  }

  function setMaxMint (uint _maxMint) external onlyOwner {
    uint alreadyMinted = SI(ERC721).totalSupply();
    require (_maxMint >= alreadyMinted, "Cannot set limit below already minted");
    maxMint = _maxMint;
  }

  function artistMint (uint _qty) external onlyOwner {
    SI solids = SI(ERC721);
    for (uint i = 0; i < _qty; i++) {
      solids.mint(msg.sender);
    }
  }

  function mint (uint _qty) external payable {
    require(msg.value == price*_qty, "Payment amount insufficient");
    
    SI solids = SI(ERC721);
    uint totalSupply = solids.totalSupply();
    
    require(totalSupply < maxMint, "Minted out");
    uint availableToMint = maxMint - totalSupply;
    require (_qty <= availableToMint, "Not enough available to mint");

    (bool sent, ) = artist.call{value: msg.value}("");
    require(sent, "Failed to send Ether");

    for (uint i = 0; i < _qty; i++) {
      solids.mint(msg.sender);
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