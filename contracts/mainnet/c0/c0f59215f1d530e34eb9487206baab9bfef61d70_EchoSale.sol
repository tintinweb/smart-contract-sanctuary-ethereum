// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEchoSale.sol";
import "./IIncarnateEcho.sol";

contract EchoSale is Ownable, IEchoSale {
  uint256 public mintCount;
  uint256 mintMaximum = 10_000;

  mapping(address => bool) public earlyAccess;

  address private _echo;

  uint earlyMintStart;
  uint earlyMintEnd;
  uint256 earlyMintPrice;

  uint mintStart;
  uint mintEnd;
  uint256 mintPrice;

  function earlyMint(uint256 quantity) payable public {
    require(earlyMintStart > 0, 'Early mint is not enabled');
    require(earlyMintPrice > 0, 'Early mint is not enabled');
    require(_echo != address(0), 'Early mint is not enabled');

    require(earlyMintStart <= block.timestamp, 'Early mint has not started yet');
    require(block.timestamp <= earlyMintEnd, 'Early mint has ended');
    require(hasEarlyAccess(), 'You need to have early access to use early mint');

    uint256 remaining = getRemaining(block.timestamp);
    require(quantity > 0, 'Quantity needs to be at least one');
    require(remaining > 0, 'Sold out');
    require(quantity <= 10, 'The maximum quantity is 10');
    require(quantity <= remaining, 'Not enough tokens available');
    require(msg.value >= earlyMintPrice * quantity, 'The message value is not enough');

    IIncarnateEcho(_echo).mint(msg.sender, quantity);
    payable(owner()).transfer(msg.value);

    delete earlyAccess[msg.sender];
    mintCount += quantity;
    
    emit Remaining(mintMaximum - mintCount);
  }

  function hasEarlyAccess() view public returns (bool hasAccess) {
    return earlyAccess[msg.sender] == true;
  }

  function getEarlyAccessInformation() view public returns (bool hasAccess, uint start, uint end, uint256 price) {
    require(earlyMintStart > 0, 'Early mint is not enabled');
    require(earlyMintPrice > 0, 'Early mint is not enabled');
    require(_echo != address(0), 'Early mint is not enabled');

    return (hasEarlyAccess(), earlyMintStart, earlyMintEnd, earlyMintPrice);
  }

  function addEarlyAccess(address address1, address address2, address address3, address address4, address address5) onlyOwner public {
    if (address1 != address(0)) {
      earlyAccess[address1] = true;
    }
    if (address2 != address(0)) {
      earlyAccess[address2] = true;
    }
    if (address3 != address(0)) {
      earlyAccess[address3] = true;
    }
    if (address4 != address(0)) {
      earlyAccess[address4] = true;
    }
    if (address5 != address(0)) {
      earlyAccess[address5] = true;
    }
  }

  function removeEarlyAccess(address address1, address address2, address address3, address address4, address address5) onlyOwner public {
    if (address1 != address(0)) {
      delete earlyAccess[address1];
    }
    if (address2 != address(0)) {
      delete earlyAccess[address2];
    }
    if (address3 != address(0)) {
      delete earlyAccess[address3];
    }
    if (address4 != address(0)) {
      delete earlyAccess[address4];
    }
    if (address5 != address(0)) {
      delete earlyAccess[address5];
    }
  }

  function enableEarlyMint(uint start, uint end, uint256 price) onlyOwner public {
    earlyMintStart = start;
    earlyMintEnd = end;
    earlyMintPrice = price;
  }

  function mint(uint256 quantity) payable public {
    uint256 remaining = getRemaining(block.timestamp);

    require(mintStart <= block.timestamp, 'Mint has not started yet');
    require(block.timestamp <= mintEnd, 'Mint has ended');
    require(quantity > 0, 'Quantity needs to be at least one');
    require(remaining > 0, 'Sold out');
    require(quantity <= 10, 'The maximum quantity is 10');
    require(quantity <= remaining, 'Not enough tokens available');
    require(msg.value >= mintPrice * quantity, 'The message value is not enough');

    IIncarnateEcho(_echo).mint(msg.sender, quantity);
    payable(owner()).transfer(msg.value);
    mintCount += quantity;

    emit Remaining(mintMaximum - mintCount);
  }

  function mintFor(address to, uint256 quantity) public onlyOwner {
    uint256 remaining = getRemaining(block.timestamp);

    require(quantity > 0, 'Quantity needs to be at least one');
    require(quantity <= remaining, 'Not enough tokens available');

    IIncarnateEcho(_echo).mint(to, quantity);
    mintCount += quantity;

    emit Remaining(mintMaximum - mintCount);
  }

  function getRemaining(uint time) view private returns (uint256 remaining) {
    if (mintCount < mintMaximum) {
      remaining = mintMaximum - mintCount;
    } else {
      remaining = 0;
    }

    if (mintEnd < time) {
      remaining = 0;
    }
    return remaining;
  }

  function getMintInformation(uint time) view public returns (uint start, uint end, uint256 price, uint256 remaining) {
    require(_echo != address(0), 'Mint is not enabled');
    require(mintStart > 0, 'Mint is not enabled');
    require(mintPrice > 0, 'Mint is not enabled');

    if (time < block.timestamp) {
      time = block.timestamp;
    }

    return (mintStart, mintEnd, mintPrice, getRemaining(time));
  }

  function enableMint(uint start, uint end, uint256 price) onlyOwner public {
    mintStart = start;
    mintEnd = end;
    mintPrice = price;
  }

  function setEcho(address echo) onlyOwner public {
    _echo = echo;
  }

  function Echo() view public returns (address) {
    return _echo;
  }

  function setMintMaximum(uint256 max) onlyOwner public {
    mintMaximum = max;
  }

  function MintMaximum() view public returns (uint256) {
    return mintMaximum;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IIncarnateEcho {
    function mint(address to, uint256 quantity) external;
    function burn(uint256 tokenId) external;
    function addMinter(address minter) external;
    function removeMinter(address minter) external;
    function getTokenBaseUri() view external returns (string memory);
    function setTokenBaseUri(string memory tokenBaseUri) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

interface IEchoSale {
  event Remaining(uint256 remaining);

  function setEcho(address echo) external;
  function setMintMaximum(uint256 max) external;
  
  function earlyMint(uint256 quantity) payable external;
  function addEarlyAccess(address address1, address address2, address address3, address address4, address address5) external;
  function removeEarlyAccess(address address1, address address2, address address3, address address4, address address5) external;
  function enableEarlyMint(uint start, uint end, uint256 price) external;

  function mint(uint256 quantity) payable external;
  function enableMint(uint start, uint end, uint256 price) external;

  function mintFor(address to, uint256 quantity) external;

  function hasEarlyAccess() view external returns (bool hasAccess);
  function getEarlyAccessInformation() view external returns (bool hasAccess, uint start, uint end, uint256 price);
  function getMintInformation(uint time) view external returns (uint start, uint end, uint256 price, uint256 remaining);

  function Echo() view external returns (address);
  function MintMaximum() view external returns (uint256);
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