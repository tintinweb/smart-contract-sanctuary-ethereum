// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RightsRegistry {

  using Counters for Counters.Counter;
  Counters.Counter private _id;

  /**
   * @dev Emitted when rights are declared for the token `tokenID` of contract `contractAddr`
   */
  event RightsDeclared(address indexed contractAddr, uint256 indexed tokenID, uint256 indexed rightsID, string rightsURI, address declarer);

  /**
   * @dev Emitted when `owner` enables `approved` to declare rights for the token `tokenId` of contract `contractAddr`
   */
  event DeclarationApproval(address indexed owner, address indexed approved, address contractAddr, uint256 indexed tokenID);

  /** 
   * @dev Emitted when `owner` enables `approved` to declare rights for `tokenID` token 
   */
  event DeclarationApprovalForAll(address indexed owner, address indexed approved, address indexed contractAddr);

  // key = Rights ID => value = Rights URI
  mapping(uint256 => string) private _rights;

  /*
   * Stores a list of Rights IDs associated with a specific NFT
   * key = NFT contract address
   * value = mapping (key = Token ID => value = list of Rights IDs)
   */ 
  mapping(address => mapping(uint256 => uint256[])) private _ids;

  mapping(address => address) private _contractApprovals;

  mapping(address => mapping(uint256 => address)) private _tokenApprovals;

  /*
   * Declare Rights for a NFT
   */
  function declare(address contractAddr, uint256 tokenID, string calldata rightsURI_) public returns (uint256) {
    require(contractAddr != address(0), "RightsRegistry: NFT Contract address can not be empty");
    require(tokenID > 0, "RightsRegistry: Token ID can not be empty");
    require(bytes(rightsURI_).length > 0, "RightsRegistry: Rights URI can not be empty");
    require(_isApproved(contractAddr, tokenID), "RightsRegistry: User is not the owner of the NFT contract and has no approval to declare rights");

    // Increment Rights ID
    _id.increment();
    uint256 rightsID = _id.current();

    // Store Rights data
    _rights[rightsID] = rightsURI_;
    _ids[contractAddr][tokenID].push(rightsID);

    // Emit event
    emit RightsDeclared(contractAddr, tokenID, rightsID, rightsURI_, tx.origin);

    return rightsID;
  }

  /*
   * Returns the Rights URI associated with the Rights ID
   */
  function uri(uint256 rightsID) public view returns (string memory) {
    require(rightsID <= _id.current(), "RightsRegistry: Query for nonexistent Rights");
    return _rights[rightsID];
  }

  /*
   * Returns a list of Rights IDs associated with a NFT
   */
  function ids(address contractAddr, uint256 tokenID) public view returns (uint256[] memory) {
    return _ids[contractAddr][tokenID];
  }

  /*
   * Approve the operator to declare righs for the token
   */
  function approve(address contractAddr, uint256 tokenID, address operator) public {
    require(Ownable(contractAddr).owner() == tx.origin || contractAddr == msg.sender, "RightsRegistry: Only the owner of the NFT contract can approve operators to declare Rights");
    _tokenApprovals[contractAddr][tokenID] = operator; 
    emit DeclarationApproval(msg.sender, operator, contractAddr, tokenID);
  }

  /*
   * Approve the operator to declare rights for all the tokens in the contract
   */
  function approveAll(address contractAddr, address operator) public {
    require(Ownable(contractAddr).owner() == tx.origin || contractAddr == msg.sender, "RightsRegistry: Only the owner of the NFT contract can approve operators to declare Rights");
    _contractApprovals[contractAddr] = operator;
    emit DeclarationApprovalForAll(msg.sender, operator, contractAddr);
  }

  function _isApproved(address contractAddr, uint256 tokenID) internal view virtual returns (bool) {
    if (_tokenApprovals[contractAddr][tokenID] == tx.origin) {
      return true;
    }
    if (_contractApprovals[contractAddr] == tx.origin) {
      return true;
    }
    if (Ownable(contractAddr).owner() == tx.origin) {
      return true;
    }
    return false;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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