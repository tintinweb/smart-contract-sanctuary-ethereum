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

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function mint(address to, uint256 quantity) external;

  function max() external view returns (uint256);

  function totalSupply() external view returns (uint256);
}

contract MinterWhitelist is Ownable {
  IERC721 public erc721;
  mapping(address => uint256) public whitelistA;
  mapping(address => bool) public whitelistB;

  uint256 public whitelistSize;
  uint256 public mintedA;
  uint256 public mintedB;
  uint256 public mintQuantityB;

  bool public publicMint;
  bool public wlMint;

  constructor(IERC721 _erc721) public {
    erc721 = _erc721;
    mintQuantityB = 1;
  }

  function viewAllocationB() public view returns (uint256) {
    return erc721.max() - erc721.totalSupply() - whitelistSize;
  }

  function mint() public {
    require(wlMint, "mint not started");
    require(
      whitelistA[msg.sender] > 0 || whitelistB[msg.sender],
      "Address not whitelisted"
    );
    if (whitelistA[msg.sender] > 0) {
      erc721.mint(msg.sender, whitelistA[msg.sender]);
      mintedA = mintedA + whitelistA[msg.sender];
      whitelistSize = whitelistSize - whitelistA[msg.sender];
      whitelistA[msg.sender] = 0;
      return;
    }
    require(mintedB < viewAllocationB(), "Only reserved mints left");
    uint256 quantity = mintQuantityB;
    if (viewAllocationB() - mintedB < mintQuantityB) {
      quantity = viewAllocationB() - mintedB;
    }
    erc721.mint(msg.sender, quantity);
    whitelistB[msg.sender] = false;
    mintedB = mintedB + quantity;
  }

  function setERC721(IERC721 _erc721) public onlyOwner {
    erc721 = _erc721;
  }

  function setMintQuantityB(uint256 _quantity) public onlyOwner {
    mintQuantityB = _quantity;
  }

  function setWLMint(bool _isTrue) public onlyOwner {
    wlMint = _isTrue;
  }

  function setWhitelistA(
    address[] memory _whitelist,
    uint256[] memory _quantities
  ) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistSize =
        whitelistSize +
        _quantities[i] -
        whitelistA[_whitelist[i]];
      whitelistA[_whitelist[i]] = _quantities[i];
    }
  }

  function revokeWhitelistA(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistSize = whitelistSize - whitelistA[_whitelist[i]];
      whitelistA[_whitelist[i]] = 0;
    }
  }

  function setWhitelistB(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistB[_whitelist[i]] = true;
    }
  }

  function revokeWhitelistB(address[] memory _whitelist) public onlyOwner {
    for (uint256 i = 0; i < _whitelist.length; i++) {
      whitelistB[_whitelist[i]] = false;
    }
  }
}