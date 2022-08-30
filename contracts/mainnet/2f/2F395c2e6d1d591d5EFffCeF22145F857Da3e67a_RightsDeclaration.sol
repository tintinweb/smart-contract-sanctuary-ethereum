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
pragma solidity ^0.8.1;

/**
 * @dev Required interface of an ISCC Hub compliant contract.
 */
interface IISCCHub {
  function announce(string calldata iscc, string calldata url, string calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

/**
 * @dev Required interface of an ISCC Registrar compliant contract.
 */
interface IISCCRegistrar {
   function declare(string calldata iscc, string calldata url, string calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IISCCHub.sol";
import "./IISCCRegistrar.sol";

contract MintangibleRegistrar is IISCCRegistrar, Ownable {

   address private _hub;
   mapping(address => bool) _allowed;

   constructor(address hub_) {
      _hub = hub_;
   }

   function hub() public view returns (address) {
      return _hub;
   }

   function setHub(address hub_) public onlyOwner {
      _hub = hub_;
   }

   function addAllowed(address addr) public onlyOwner {
      _allowed[addr] = true;
   }

   function isAllowed(address addr) internal view returns (bool) {
      return _allowed[addr];
   }

   function removeAllowed(address addr) public onlyOwner {
      _allowed[addr] = false;
   }

   function declare(string calldata iscc, string calldata url, string calldata message) external override  {
      require(isAllowed(msg.sender) == true, "MintangibleRegistrar: Caller is not allowed to make declarations");
      IISCCHub(_hub).announce(iscc, url, message);
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../iscc/MintangibleRegistrar.sol";
import "../rights/RightsProtocol.sol";

contract RightsDeclaration is Ownable {

  // Address of ISCC Registrar Smart Contract
  address private _isccAddr;

  // Address of Rights Protocol Smart contract
  address private _rightsProtocolAddr;

  // List of addresses that can make declarations using this contract
  mapping(address => bool) _allowed;

  constructor(address isccAddr_, address rightsProtocolAddr_) {
    _isccAddr = isccAddr_;
    _rightsProtocolAddr = rightsProtocolAddr_;
  }
  
  function isccAddr() public view returns (address) {
    return _isccAddr;
  }

  function setIsccAddr(address isccAddr_) public onlyOwner {
    _isccAddr = isccAddr_;
  }

  function rightsProtocolAddr() public view returns (address) {
    return _rightsProtocolAddr;
  }

  function setRightsProtocolAddr(address rightsProtocolAddr_) public onlyOwner {
    _rightsProtocolAddr = rightsProtocolAddr_;
  }

  function addAllowed(address addr) public onlyOwner {
    _allowed[addr] = true;
   }

  function isAllowed(address addr) internal view returns (bool) {
    return _allowed[addr];
  }

  function removeAllowed(address addr) public onlyOwner {
    _allowed[addr] = false;
  }

  function declare(
    address contractAddr, 
    uint256 tokenID, 
    string calldata rightsURI, 
    string calldata isccCode, 
    string calldata isccURI, 
    string calldata isccMessage)
    public returns (uint256) 
  {
    require(isAllowed(msg.sender) == true, "RightsDeclaration: Caller is not allowed to make declarations");
    MintangibleRegistrar(_isccAddr).declare(isccCode, isccURI, isccMessage);
    uint rightsID = RightsProtocol(_rightsProtocolAddr).declare(contractAddr, tokenID, rightsURI, false);
    return rightsID;
  }
 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RightsProtocol is Ownable {

  /**
   * @dev Emitted when rights are declared for the token `tokenID` of contract `contractAddr`
   */
  event RightsDeclared(address indexed contractAddr, uint256 indexed tokenID, uint256 rightsID, string indexed rightsURI, address declarer);

  /** 
   * @dev Emitted when Rights Authority for tokens in the contract `contractAddr` is transferred from the old Rights Authority (`oldAuthority`) 
   * to a new Rights Authority (`newAuthority`)
   */
  event ContractAuthorityTransferred(address indexed oldAuthority, address indexed newAuthority, address indexed contractAddr);

  /**
   * @dev Emitted when declarations for the contract `contractAddr` are frozen
   */
  event ContractDeclarationsFrozen(address indexed contractAddr, address indexed declarer);
   
  /** 
   * @dev Emitted when Rights Authority (`rightsAuthority`) approves an Operator (`operator`) to declare rights for tokens of the contract 
   * `contractAddr` 
   */
  event ContractOperatorApproved(address indexed rightsAuthority, address indexed operator, address indexed contractAddr);

  /** 
   * @dev Emitted when Rights Authority (`rightsAuthority`) revokes the Operator (`operator`) to declare rights for tokens of the contract 
   * `contractAddr` 
   */
  event ContractOperatorRevoked(address indexed rightsAuthority, address indexed operator, address indexed contractAddr);

  /** 
   * @dev Emitted when Rights Authority for the token `tokenID` of contract `contractAddr` is transferred from the old Rights Authority 
   * (`oldAuthority`) to a new Rights Authority (`newAuthority`) 
   */
  event TokenAuthorityTransferred(address oldAuthority, address indexed newAuthority, address indexed contractAddr, uint256 indexed tokenID);

  /**
   * @dev Emitted when declarations for the token `tokenID` of contract `contractAddr` are frozen
   */
  event TokenDeclarationsFrozen(address indexed contractAddr, uint256 indexed tokenID, address indexed declarer);

  /**
   * @dev Emitted when Rights Authority (`rightsAuthority`) approves an Operator (`operator`) to declare rights for the token `tokenID` of 
   * contract `contractAddr`
   */
  event TokenOperatorApproved(address rightsAuthority, address indexed operator, address indexed contractAddr, uint256 indexed tokenID);

  /**
   * @dev Emitted when Rights Authority (`rightsAuthority`) revokes the Operator (`operator`) to declare rights for the token `tokenID` of 
   * contract `contractAddr`
   */
  event TokenOperatorRevoked(address rightsAuthority, address indexed operator, address indexed contractAddr, uint256 indexed tokenID);

  // Rights Status information
  struct RightsStatus { 
    address authority;
    address operator;
    uint256 authorityDate;
    uint256 frozenDate;
  }

  using Counters for Counters.Counter;
  Counters.Counter private _id;

  bool private _useAllowlist;

  // List of addresses that can make declarations using this contract
  mapping(address => bool) _allowlist;

  // Maps Rights ID to Rights URI
  mapping(uint256 => string) private _rights;

  // Maps NFT (Smart Contract address / Token ID) to the list of Rights IDs
  mapping(address => mapping(uint256 => uint256[])) private _ids;

  // Maps NFT Smart Contract address to Rights Status information (contract-level)
  mapping(address => RightsStatus) private _contractStatus;

  // Maps NFT (Smart Contract address / Token ID) to Rights Status information (token-level)
  mapping(address => mapping(uint256 => RightsStatus)) private _tokenStatus;

  constructor() {
    _useAllowlist = true; 
  }

  /*
   * Disable allowlist 
   */
  function disableAllowlist() public onlyOwner {
    _useAllowlist = false;
  }

  /*
   * Returns a boolean indicating if allowlist is enabled
   */
  function useAllowlist() public view returns (bool) {
    return _useAllowlist;
  }

  /*
   * Throws error if caller is not in the allowed list
   */
  modifier onlyAllowed() {
    if (_useAllowlist) {
      require(_allowlist[msg.sender] == true || _allowlist[tx.origin] == true, "RightsProtocol: caller is not allowed");
    }
    _;
  }
  
  /*
   * Add address to the allowed list
   */
  function addAllowed(address addr) public onlyOwner {
    _allowlist[addr] = true;
  }

  /*
   * Remove address from the allowed list
   */
  function removeAllowed(address addr) public onlyOwner {
    _allowlist[addr] = false;
  }

  /*
   * Declare Rights for a NFT
   */
  function declare(address contractAddr, uint256 tokenID, string calldata rightsURI_, bool freeze) public onlyAllowed returns (uint256) {
    require(contractAddr != address(0), "RightsProtocol: NFT Smart Contract address can not be empty");
    require(tokenID > 0, "RightsProtocol: Token ID can not be empty");
    require(bytes(rightsURI_).length > 0, "RightsProtocol: Rights URI can not be empty");

    // Check if declarations are frozen for the token
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Rights declarations frozen for the contract or for the token");

    // Check if the user is approved to attach declarations
    require(_canManageToken(contractAddr, tokenID), "RightsProtocol: Caller is not Rights Authority or approved Operator for the token");

    // Increment Rights ID
    _id.increment();
    uint256 rightsID = _id.current();

    // Store Rights data
    _rights[rightsID] = rightsURI_;
    _ids[contractAddr][tokenID].push(rightsID);

    // Handle freezing
    if (freeze) {
      _tokenStatus[contractAddr][tokenID].frozenDate = block.timestamp;
      emit TokenDeclarationsFrozen(contractAddr, tokenID, tx.origin);
    }

    // Emit event
    emit RightsDeclared(contractAddr, tokenID, rightsID, rightsURI_, tx.origin); 

    return rightsID;
  }

  /*
   * Returns a list of Rights IDs associated with the token
   */
  function ids(address contractAddr, uint256 tokenID) public view returns (uint256[] memory) {
    return _ids[contractAddr][tokenID];
  }

  /*
   * Returns the Rights URI associated with the Rights ID
   */
  function rightsURI(uint256 rightsID) public view returns (string memory) {
    require(rightsID <= _id.current(), "RightsProtocol: Query for nonexistent Rights ID");
    return _rights[rightsID];
  }

  /*
   * Returns a list of Rights URI associated with the token
   */
  function rightsURIs(address contractAddr, uint256 tokenID) public view returns (string[] memory) {
    uint256[] memory rightsIDs = ids(contractAddr, tokenID);
    string[] memory uris = new string[](rightsIDs.length);
    for (uint i = 0; i < rightsIDs.length; i++) {
      string memory rightsURI_ = rightsURI(rightsIDs[i]);
      uris[i]= rightsURI_;
    }
    return uris;
  }

  /*
   * Freeze declarations for a contract
   */
  function freezeContract(address contractAddr) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Rights declarations are already frozen for the contract");
    require(_canManageContract(contractAddr) == true, "RightsProtocol: Caller is not Rights Authority or approved Operator for the contract");

    RightsStatus storage contractStatus = _contractStatus[contractAddr];
    contractStatus.frozenDate = block.timestamp;

    emit ContractDeclarationsFrozen(contractAddr, tx.origin);
  }

  /*
   * Freeze declarations for a token
   */
  function freezeToken(address contractAddr, uint256 tokenID) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Rights declarations are already frozen for the token");
    require(_canManageToken(contractAddr, tokenID) == true, "RightsProtocol: Caller is not Rights Authority or approved Operator for the token");

    RightsStatus storage tokenStatus = _tokenStatus[contractAddr][tokenID];
    tokenStatus.frozenDate = block.timestamp;

    emit TokenDeclarationsFrozen(contractAddr, tokenID, tx.origin);
  }

  /* 
   * Check if contract declarations are frozen
   */
  function isContractFrozen(address contractAddr) public view returns (bool) {
    return _contractStatus[contractAddr].frozenDate > 0;
  }

  /*
   * Check if token declarations are frozen:
   * 1. The token declarations were frozen
   * 2. The contract declarations were frozen and the token-level authority was NOT set before
   */
  function isTokenFrozen(address contractAddr, uint256 tokenID) public view returns (bool) {
    RightsStatus storage tokenStatus = _tokenStatus[contractAddr][tokenID];
    if (tokenStatus.frozenDate > 0) {
      return true;
    }

    // Check if token-level authority was set before the freezing
    RightsStatus storage contractStatus = _contractStatus[contractAddr];
    if (contractStatus.frozenDate > 0) {
      if (tokenStatus.authorityDate > 0 && tokenStatus.authorityDate < contractStatus.frozenDate) {
        return false;
      } else {
        return true;
      }
    } 

    return false;
  }

  /*
   * Approve contract-level operator
   * This function should be called directly by the contract-level authority
   */
  function approveContractOperator(address contractAddr, address operator) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Operator can not be approved if declarations are frozen for the contract");
    require(_isContractAuthority(contractAddr, false) == true, "RightsProtocol: Caller is not contract-level Rights Authority");
        
    _contractStatus[contractAddr].operator = operator;
    emit ContractOperatorApproved(msg.sender, operator, contractAddr);
  }

  /*
   * Revoke contract-level operator
   * This function should be called directly by the contract-level authority
   */
  function revokeContractOperator(address contractAddr) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Operator can not be revoked if declarations are frozen for the contract");
    require(_isContractAuthority(contractAddr, false) == true, "RightsProtocol: Caller is not contract-level Rights Authority");

    address operator = _contractStatus[contractAddr].operator;
    _contractStatus[contractAddr].operator = address(0);
    emit ContractOperatorRevoked(msg.sender, operator, contractAddr);
  }

  /*
   * Approve token-level operator
   * This function should be called directly by the token-level authority
   */
  function approveTokenOperator(address contractAddr, uint256 tokenID, address operator) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Operator can not be approved if declarations are frozen for the token");
    require(_isTokenAuthority(contractAddr, tokenID, false) == true , "RightsProtocol: Caller is not (token-level and contract-level) Rights Authority");

    _tokenStatus[contractAddr][tokenID].operator = operator; 
    emit TokenOperatorApproved(msg.sender, operator, contractAddr, tokenID);
  }

  /*
   * Revoke token-level operator
   * This function should be called directly by the token-level authority
   */
  function revokeTokenOperator(address contractAddr, uint256 tokenID) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Operator can not be revoked if declarations are frozen for the token");
    require(_isTokenAuthority(contractAddr, tokenID, false) == true , "RightsProtocol: Caller is not (token-level and contract-level) Rights Authority");

    address operator = _tokenStatus[contractAddr][tokenID].operator;
    _tokenStatus[contractAddr][tokenID].operator = address(0); 
    emit TokenOperatorRevoked(msg.sender, operator, contractAddr, tokenID);
  }

  /*
   * Transfer contract-level Rights Authority
   */
  function transferContractAuthority(address contractAddr, address newAuthority) public onlyAllowed {
    require(isContractFrozen(contractAddr) == false, "RightsProtocol: Rights Authority can not be transferred if contract declarations are frozen");
    require(_isContractAuthority(contractAddr, false) == true, "RightsProtocol: Caller is not contract-level Rights Authority");

    RightsStatus storage contractStatus = _contractStatus[contractAddr];
    contractStatus.authority = newAuthority;
    contractStatus.authorityDate = block.timestamp;

    emit ContractAuthorityTransferred(msg.sender, newAuthority, contractAddr);
  }

  /*
   * Transfer token-level Rights Authority
   */
  function transferTokenAuthority(address contractAddr, uint256 tokenID, address newAuthority) public onlyAllowed {
    require(isTokenFrozen(contractAddr, tokenID) == false, "RightsProtocol: Rights Authority can not be transferred if token declarations are frozen");
    require(_isTokenAuthority(contractAddr, tokenID, false) == true, "RightsProtocol: Caller is not (token-level and contract-level) Rights Authority");
    
    RightsStatus storage tokenStatus = _tokenStatus[contractAddr][tokenID];
    tokenStatus.authority = newAuthority;
    tokenStatus.authorityDate = block.timestamp;

    emit TokenAuthorityTransferred(msg.sender, newAuthority, contractAddr, tokenID);
  }

  /*
   * Check if user of caller is approved to make contract declarations
   */
  function _canManageContract(address contractAddr) internal view returns (bool) {
    return _isContractAuthority(contractAddr, true) || _isContractOperator(contractAddr);
  }

  /*
   * Check if user or caller is approved to make token declarations
   */
  function _canManageToken(address contractAddr, uint256 tokenID) internal view returns (bool) {
    return _isTokenAuthority(contractAddr, tokenID, true) || _isTokenOperator(contractAddr, tokenID);
  }
  
  /*
   * Check if user or caller is a contract-level Rights Authority
   */
  function _isContractAuthority(address contractAddr, bool origin) internal view returns (bool) {
    // Use transaction origin or direct caller?
    address caller;
    if (origin) {
      caller = tx.origin;
    } else {
      caller = msg.sender;
    }

    // The contract authority was explicitly set, check if it's the caller
    address contractAuthority = _contractStatus[contractAddr].authority;
    if (contractAuthority != address(0)) {
      return contractAuthority == caller;
    }

    // The contract itself is the direct caller
    if (msg.sender == contractAddr) {
      return true;
    }

    // The owner of the contract is the caller
    address contractOwner = Ownable(contractAddr).owner();
    return contractOwner == caller;
  }

  /*
   * Check if transaction origin or message sender is a token-level Rights Authority
   */
  function _isTokenAuthority(address contractAddr, uint256 tokenID, bool origin) internal view returns (bool) {
    address caller;
    if (origin) {
      caller = tx.origin;
    } else {
      caller = msg.sender;
    }
    
    // The token authority was explicitly set, check if it's the caller
    address tokenAuthority = _tokenStatus[contractAddr][tokenID].authority;
    if (tokenAuthority != address(0)) {
      return tokenAuthority == caller;
    }

    // The contract authority was explicitly set, check if it's the caller
    address contractAuthority = _contractStatus[contractAddr].authority;
    if (contractAuthority != address(0)) {
      return contractAuthority == caller;
    }

    // The contract itself is the direct caller
    if (msg.sender == contractAddr) {
      return true;
    }

    // The owner of the contract is the caller
    address contractOwner = Ownable(contractAddr).owner();
    return contractOwner == caller;
  }

  /*
   * Check if caller (transaction origin) is contract Operator
   */
  function _isContractOperator(address contractAddr) internal view returns (bool) {
    address contractOperator = _contractStatus[contractAddr].operator;
    return contractOperator == tx.origin;
  } 

  /*
   * Check if caller (transaction origin) is token Operator
   */
  function _isTokenOperator(address contractAddr, uint256 tokenID) internal view returns (bool) {
    address tokenOperator = _tokenStatus[contractAddr][tokenID].operator;
    if (tokenOperator != address(0)) {
      return tokenOperator == tx.origin;
    }

    address contractOperator = _contractStatus[contractAddr].operator;
    if (contractOperator != address(0)) {
      return contractOperator == tx.origin;
    }

    return false;
  }
}