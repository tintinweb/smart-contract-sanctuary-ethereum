/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.0;
contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}


// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^ 0.8.0;

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
  function _msgSender() internal view virtual returns(address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns(bytes calldata) {
    return msg.data;
  }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^ 0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * onlyOwner, which can be applied to your functions to restrict their use to
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
  function owner() public view virtual returns(address) {
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
   * onlyOwner functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (newOwner).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (newOwner).
   * Internal function without access restriction.
   */
  function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
    _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
  }
}

interface IMintplexOpenEditionPlus {
  function initialize(
    address _owner,
    address[] memory _payables,
    uint256[] memory _payouts,
    string memory tokenName,
    string memory tokenSymbol,
    string[2] memory uris,
    uint256[2] memory _collectionSettings,
    uint256[2] memory _settings
  ) external;
}

pragma solidity ^ 0.8.1;

contract MintplexOpenEditionPlusFactory is Ownable, CloneFactory {
  address public libraryAddress;
  event MintplexOpenEditionPlusCreated(address newMintplexContract);

  constructor(address _master) { 
    libraryAddress = _master;
  }

  function setLibraryAddress(address _libraryAddress) public onlyOwner {
    libraryAddress = _libraryAddress;
  }

  function create(
    address _owner,
    address[] memory _payables,
    uint256[] memory _payouts,
    string memory tokenName,
    string memory tokenSymbol,
    string[2] memory uris, // [basetokenURI, collectionURI]
    uint256[2] memory _collectionSettings, // [maxMintsPerTxn, softCap]
    uint256[2] memory _settings // [mintPrice, maxWalletMints]
  ) public returns(address) {
    address clone = CloneFactory.createClone(libraryAddress);
    IMintplexOpenEditionPlus(clone).initialize(
      _owner,
      _payables,
      _payouts,
      tokenName,
      tokenSymbol,
      uris,
      _collectionSettings,
      _settings
    );
    emit MintplexOpenEditionPlusCreated(clone);
    return clone;
  }
}