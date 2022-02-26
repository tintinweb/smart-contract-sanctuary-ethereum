//SPDX-License-Identifier: MIT
// Fork by Maker Median.sol https://github.com/makerdao/median/blob/master/src/median.sol
pragma solidity ^0.8.0;

import "../interface/IMedian.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MedianSpacex is Ownable {
  uint128        val;
  uint32  public age;
  bytes32 public wat = "GSPACEX";
  uint256 public bar = 3;

  struct FeedData {
    uint256 value;
    uint256 age;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  // Authorized oracles, set by an auth
  mapping (address => uint256) public oracle;

  // Whitelisted contracts, set by an auth
  mapping (address => uint256) public bud;

  // Mapping for at most 256 oracles
  mapping (uint8 => address) public slot;

  modifier toll { require(bud[msg.sender] == 1, "Address not permitted to read"); _;}

  event LogMedianPrice(uint256 val, uint256 age);

  function read() external view toll returns (uint256) {
    (uint256 price, bool valid) = peek();
    require(valid, "Invalid price to read");

    return price;
  }

  function peek() public view toll returns (uint256, bool) {
    return (val, val > 0);
  }

  function recover(uint256 val_, uint256 age_, uint8 v, bytes32 r, bytes32 s) virtual public view returns (address) {
    return ecrecover(
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(val_, age_, wat)))),
      v, r, s
    );
  }

  function poke(
    FeedData[] memory data
  ) external {
    require(data.length == bar, "Invalid number of answers of Oracles");

    uint256 bloom = 0;
    uint256 last = 0;
    uint256 zzz = age;

    for (uint i = 0; i < data.length; i++) {
      uint8 sl;
      // Validate the values were signed by an authorized oracle
      address signer = recover(data[i].value, data[i].age, data[i].v, data[i].r, data[i].s);
      // Check that signer is an oracle
      require(oracle[signer] == 1, "Not authorized oracle signer");
      // Price feed age greater than last medianizer age
      require(data[i].age > zzz, "Signer oracle message expired");
      // Check for ordered values
      require(data[i].value >= last, "Message is not in the order");
      last = data[i].value;
      // Bloom filter for signer uniqueness
      assembly {
        sl := shr(152, signer)
      }
      require((bloom >> sl) % 2 == 0, "Signer oracle already sended");
      bloom += uint256(2) ** sl;
    }

    val = uint128(data[data.length >> 1].value);
    age = uint32(block.timestamp);
    emit LogMedianPrice(val, age);
  }

  function lift(address account) external onlyOwner {
    require(account != address(0), "Invalid account");
    uint8 s;
    assembly {
      s := shr(152, account)
    }
    require(slot[s] == address(0), "Signer already exists");
    oracle[account] = 1;
    slot[s] = account;
  }

  function drop(address account) external onlyOwner {
    uint8 s;
    oracle[account] = 0;
    assembly {
      s := shr(152, account)
    }
    slot[s] = address(0);
  }

  function setBar(uint256 bar_) external onlyOwner {
    require(bar_ > 0, "Needs to be a positive value");
    require(bar_ % 2 != 0, "Need be a odd number");
    bar = bar_;
  }

  function kiss(address account) public onlyOwner {
    require(account != address(0), "It's not a signer valid");
    bud[account] = 1;
  }

  function diss(address account) public onlyOwner {
    bud[account] = 0;
  }

  function kiss(address[] calldata accounts) public onlyOwner {
    for(uint i = 0; i < accounts.length; i++) {
      require(accounts[i] != address(0), "It's not a signer valid");
      bud[accounts[i]] = 1;
    }
  }

  function diss(address[] calldata accounts) public onlyOwner {
    for(uint i = 0; i < accounts.length; i++) {
      bud[accounts[i]] = 0;
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMedian {
  function peek() external view returns (uint256, bool);
  function read() external view returns (uint256);
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