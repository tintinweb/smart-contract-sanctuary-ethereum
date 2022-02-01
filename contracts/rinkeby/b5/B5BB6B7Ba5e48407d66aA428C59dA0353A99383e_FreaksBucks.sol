// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "sol-temple/src/tokens/ERC20.sol";

/// @title Freaks Bucks
contract FreaksBucks is Ownable, ERC20("Freaks Bucks", "FBX", 18, "1") {
  /// @notice Authorized callers mapping.
  mapping(address => bool) public auth;

  /// @notice Require the sender to be the owner or authorized.
  modifier onlyAuth() {
    require(auth[msg.sender], "Sender is not authorized");
    _;
  }

  /// @notice Set `addresses` authorization to `authorized`.
  function setAuth(address[] calldata addresses, bool authorized) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) auth[addresses[i]] = authorized;
  }

  /// @notice Mint new tokens to `to` with amount of `value`.
  function mint(address to, uint256 value) external onlyAuth {
    super._mint(to, value);
  }

  /// @notice Burn tokens from `from` with amount of `value`.
  function burn(address from, uint256 value) external onlyAuth {
    super._burn(from, value);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC20
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice A complete ERC20 implementation including EIP-2612 permit feature.
 * Inspired by Solmate's ERC20, aiming at efficiency.
 */
abstract contract ERC20 {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice See {ERC20-Transfer}.
  event Transfer(address indexed from, address indexed to, uint256 value);
  /// @notice See {ERC20-Approval}.
  event Approval(address indexed owner, address indexed spender, uint256 value);

  /// @notice See {ERC20-name}.
  string public name;
  /// @notice See {ERC20-symbol}.
  string public symbol;
  /// @notice See {ERC20-decimals}.
  uint8 public immutable decimals;

  /// @notice Used to hash the Domain Separator.
  string public version;

  /// @notice See {ERC20-totalSupply}.
  uint256 public totalSupply;
  /// @notice See {ERC20-balanceOf}.
  mapping(address => uint256) public balanceOf;
  /// @notice See {ERC20-allowance}.
  mapping(address => mapping(address => uint256)) public allowance;

  /// @notice See {ERC2612-nonces}.
  mapping(address => uint256) public nonces;

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  constructor(
    string memory name_,
    string memory symbol_,
    uint8 decimals_,
    string memory version_
  ) {
    name = name_;
    symbol = symbol_;
    decimals = decimals_;
    version = version_;
  }

  /// @notice See {ERC20-transfer}.
  function transfer(address to_, uint256 value_) public returns (bool) {
    _transfer(msg.sender, to_, value_);
    return true;
  }

  /// @notice See {ERC20-transferFrom}.
  function transferFrom(
    address from_,
    address to_,
    uint256 value_
  ) public returns (bool) {
    uint256 allowed = allowance[from_][msg.sender];
    require(allowed >= value_, "ERC20: allowance exceeds transfer value");
    if (allowed != type(uint256).max) allowance[from_][msg.sender] -= value_;

    _transfer(from_, to_, value_);
    return true;
  }

  /// @notice See {ERC20-approve}.
  function approve(address spender_, uint256 value_) public returns (bool) {
    _approve(msg.sender, spender_, value_);
    return true;
  }

  /// @notice See {ERC2612-DOMAIN_SEPARATOR}.
  function DOMAIN_SEPARATOR() public view returns (bytes32) {
    return _hashEIP712Domain(name, version, block.chainid, address(this));
  }

  /// @notice See {ERC2612-permit}.
  function permit(
    address owner_,
    address spender_,
    uint256 value_,
    uint256 deadline_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) public {
    require(deadline_ >= block.timestamp, "ERC20: expired permit deadline");

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 digest = _hashEIP712Message(
      DOMAIN_SEPARATOR(),
      keccak256(
        abi.encode(
          0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9,
          owner_,
          spender_,
          value_,
          nonces[owner_]++,
          deadline_
        )
      )
    );
    address signer = ecrecover(digest, v_, r_, s_);
    require(signer != address(0) && signer == owner_, "ERC20: invalid signature");

    _approve(owner_, spender_, value_);
  }

  /*             _                               _    */
  /*   _        ( )_                            (_ )  */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |  */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'_` ) | |  */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |  */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___) */

  /// @notice Internal transfer helper. Throws if `value_` exceeds `from_` balance.
  function _transfer(
    address from_,
    address to_,
    uint256 value_
  ) internal {
    require(balanceOf[from_] >= value_, "ERC20: insufficient balance");
    _beforeTokenTransfer(from_, to_, value_);

    balanceOf[from_] -= value_;
    unchecked {
      balanceOf[to_] += value_;
    }

    emit Transfer(from_, to_, value_);
    _afterTokenTransfer(from_, to_, value_);
  }

  /// @notice Internal approve helper.
  function _approve(
    address owner_,
    address spender_,
    uint256 value_
  ) internal {
    allowance[owner_][spender_] = value_;
    emit Approval(owner_, spender_, value_);
  }

  /// @notice Internal minting logic.
  function _mint(address to_, uint256 value_) internal {
    _beforeTokenTransfer(address(0), to_, value_);

    totalSupply += value_;
    unchecked {
      balanceOf[to_] += value_;
    }

    emit Transfer(address(0), to_, value_);
    _afterTokenTransfer(address(0), to_, value_);
  }

  /// @notice Internal burning logic.
  function _burn(address from_, uint256 value_) internal {
    _beforeTokenTransfer(from_, address(0), value_);

    balanceOf[from_] -= value_;
    unchecked {
      totalSupply -= value_;
    }

    emit Transfer(from_, address(0), value_);
    _afterTokenTransfer(from_, address(0), value_);
  }

  /**
   * @notice EIP721 domain hashing helper.
   * @dev Modified from https://github.com/0xProject/0x-monorepo/blob/development/contracts/utils/contracts/src/LibEIP712.sol
   */
  function _hashEIP712Domain(
    string memory name_,
    string memory version_,
    uint256 chainId_,
    address verifyingContract_
  ) internal pure returns (bytes32) {
    bytes32 result;
    assembly {
      // Calculate hashes of dynamic data
      let nameHash := keccak256(add(name_, 32), mload(name_))
      let versionHash := keccak256(add(version_, 32), mload(version_))

      // Load free memory pointer
      let memPtr := mload(64)

      // Store params in memory
      mstore(memPtr, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
      mstore(add(memPtr, 32), nameHash)
      mstore(add(memPtr, 64), versionHash)
      mstore(add(memPtr, 96), chainId_)
      mstore(add(memPtr, 128), verifyingContract_)

      // Compute hash
      result := keccak256(memPtr, 160)
    }
    return result;
  }

  /**
   * @notice EIP721 typed message hashing helper.
   * @dev Modified from https://github.com/0xProject/0x-monorepo/blob/development/contracts/utils/contracts/src/LibEIP712.sol
   */
  function _hashEIP712Message(bytes32 domainSeparator_, bytes32 hash_) internal pure returns (bytes32) {
    bytes32 result;
    assembly {
      // Load free memory pointer
      let memPtr := mload(64)

      mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000) // EIP191 header
      mstore(add(memPtr, 2), domainSeparator_) // EIP712 domain hash
      mstore(add(memPtr, 34), hash_) // Hash of struct

      // Compute hash
      result := keccak256(memPtr, 66)
    }
    return result;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 value
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 value
  ) internal virtual {}
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