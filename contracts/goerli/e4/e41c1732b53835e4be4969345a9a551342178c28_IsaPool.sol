/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// File: v2-goerli/Context.sol
// SPDX-License-Identifier: GPL-3.0


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

// File: v2-goerli/Ownable.sol


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

// File: v2-goerli/Callable.sol


pragma solidity >=0.7.0 <=0.9.0;


contract Callable is Ownable {
  mapping(address => bool) public allowedCallers;

  function newAllowedCaller(address allowed) public onlyOwner {
    allowedCallers[allowed] = true;
  }

  function isAllowedCaller(address caller) public view returns (bool) {
    return allowedCallers[caller];
  }

  modifier mustBeAllowedCaller() {
    require(allowedCallers[msg.sender], "Not allowed caller");
    _;
  }
}

// File: v2-goerli/SacTokenInterface.sol


pragma solidity >=0.7.0 <=0.9.0;

interface SacTokenInterface {
  function balanceOf(address tokenOwner) external view returns (uint256);

  function allowance(address owner, address delegate) external view returns (uint256);

  function approveWith(address delegate, uint256 numTokens) external returns (uint256);

  function transferWith(address tokenOwner, uint256 numTokens) external returns (bool);

  function transferFrom(
    address owner,
    address to,
    uint256 numTokens
  ) external returns (bool);
}

// File: v2-goerli/PoolPassiveInterface.sol


pragma solidity >=0.7.0 <=0.9.0;

interface PoolPassiveInterface {
  /*
   * @dev Allow a user approve tokens from pool to your account
   */
  function approveWith(address delegate, uint256 _numTokens) external returns (bool);

  /*
   * @dev Allow a user transfer tokens to pool
   */
  function transferWith(address tokenOwner, uint256 tokens) external returns (bool);

  /*
   * @dev Allow a user withdraw (transfer) your tokens approved to your account
   */
  function withDraw() external returns (bool);

  /*
   * @dev Allow a user know how much tokens his has approved from pool
   */
  function allowance() external view returns (uint256);

  /*
   * @dev Allow a user know how much tokens this pool has available
   */
  function balance() external view returns (uint256);

  /*
   * @dev Allow a user know how much tokens this pool has available
   */
  function balanceOf(address tokenOwner) external view returns (uint256);
}

// File: v2-goerli/IsaPool.sol


pragma solidity >=0.7.0 <=0.9.0;





/**
 * @author Sintrop
 * @title IsaPool
 * @dev IsaPool is a contract to manage user votes
 */
contract IsaPool is PoolPassiveInterface, Ownable, Callable {
  SacTokenInterface internal sacToken;

  constructor(address sacTokenAddress) {
    sacToken = SacTokenInterface(sacTokenAddress);
  }

  /**
   * @dev Show how much tokens the developer can withdraw from DeveloperPool address
   * @return uint256
   * TODO Check external code call - EXTCALL
   */
  function allowance() public view override returns (uint256) {
    return sacToken.allowance(address(this), msg.sender);
  }

  /**
   * @dev Allow a user know how much SAC Tokens has
   * @param tokenOwner The address of the token owner
   * @return uint256
   */
  function balanceOf(address tokenOwner) public view override returns (uint256) {
    return sacToken.balanceOf(tokenOwner);
  }

  /**
   * @dev Allow a user know how much SAC Tokens this pool has
   */
  function balance() public view override returns (uint256) {
    return balanceOf(address(this));
  }

  /**
   * @dev Allow a user approve some tokens from pool to he
   * @param _numTokens How much tokens the user want transfer
   * @return bool
   */
  function approveWith(address delegate, uint256 _numTokens)
    public
    override
    mustBeAllowedCaller
    returns (bool)
  {
    sacToken.approveWith(delegate, _numTokens);
    return true;
  }

  function withDraw() public pure override returns (bool) {
    return true;
  }

  /**
   * @dev Allow a user transfer some tokens to this contract pool
   * @param tokenOwner The address of the token owner
   * @param numTokens How much tokens the user want transfer
   * @return bool
   */
  function transferWith(address tokenOwner, uint256 numTokens) public override returns (bool) {
    sacToken.transferWith(tokenOwner, numTokens);
    return true;
  }
}