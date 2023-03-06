/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

// File: contracts/Constants.sol
// SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// File: contracts/IOperatorFilterRegistry.sol


pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// File: contracts/OperatorFilterer.sol


pragma solidity ^0.8.13;


/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// File: contracts/DefaultOperatorFilterer.sol


pragma solidity ^0.8.13;


/**s
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// File: contracts/Address.sol



pragma solidity ^0.8.13; 

library Address { 
    function isContract(address account) internal view returns (bool) { 
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    } 
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
 
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    } 
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
 
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    } 
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
 
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
 
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
 
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
 
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else { 
            if (returndata.length > 0) { 

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: contracts/Ownable.sol



pragma solidity ^0.8.13; 

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    constructor() {
        _transferOwnership(_msgSender());
    }
 
    function owner() public view virtual returns (address) {
        return _owner;
    } 
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/MerkleProof.sol


pragma solidity ^0.8.13; 

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }
   function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
// File: contracts/Strings.sol


pragma solidity ^0.8.13; 
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
 
    function toString(uint256 value) internal pure returns (string memory) { 
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
 
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
 
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: contracts/ERC721A.sol



pragma solidity ^0.8.13; 



interface IERC721Receiver { 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
 
interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
 
abstract contract ERC165 is IERC165 { 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
} 
interface IERC721 is IERC165 { 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId); 
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId); 
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved); 
    function balanceOf(address owner) external view returns (uint256 balance); 
    function ownerOf(uint256 tokenId) external view returns (address owner); 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external; 
    function approve(address to, uint256 tokenId) external;
 
    function getApproved(uint256 tokenId) external view returns (address operator); 
    function setApprovalForAll(address operator, bool _approved) external; 
    function isApprovedForAll(address owner, address operator) external view returns (bool); 
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
} 
interface IERC721Enumerable is IERC721 { 
    function totalSupply() external view returns (uint256); 
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId); 
    function tokenByIndex(uint256 index) external view returns (uint256);
}  
interface IERC721Metadata is IERC721 { 
    function name() external view returns (string memory); 
    function symbol() external view returns (string memory); 
    function tokenURI(uint256 tokenId) external view returns (string memory);
} 


contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 1;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize; 
  string private _name; 
  string private _symbol; 
  mapping(uint256 => TokenOwnership) private _ownerships; 
  mapping(address => AddressData) private _addressData; 
  mapping(uint256 => address) private _tokenApprovals; 
  mapping(address => mapping(address => bool)) private _operatorApprovals; 
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  } 
  function totalSupply() public view override returns (uint256) {
    return currentIndex-1;
  } 
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  } 
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  } 
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  } 
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  } 
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  } 
  function name() public view virtual override returns (string memory) {
    return _name;
  } 
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  } 
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(),_getUriExtension()))
        : "";
  } 
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  function _getUriExtension() internal view virtual returns (string memory) {
    return "";
  }
 
   function approve(address to, uint256 tokenId) public virtual  override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  } 

  
  function getApproved(uint256 tokenId) public view  override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  } 
  function setApprovalForAll(address operator, bool approved) public virtual  override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }
 
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }
 
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _transfer(from, to, tokenId);
  } 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  } 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual  override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  } 
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  } 
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address"); 
    require(!_exists(startTokenId), "ERC721A: token already minted");
    // require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  } 
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1); 
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp)); 
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  } 
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0; 
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    } 
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  } 
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  } 
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {} 
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}
// File: contracts/AngrySheepClubPresale.sol

/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.8.13; 






abstract contract ReentrancyGuard { 
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
   _status = _ENTERED;

        _;
        _status = _NOT_ENTERED;
    }
}



contract AngrySheepClub is DefaultOperatorFilterer, Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;
  
  uint256 public MAX_PER_Transaction = 5; // maximum amount that user can mint per transaction
  uint256 public  PRICE = 0.0001 ether; // change price to 0.0001
  uint256 public currentSupply = 0;
  uint256 private constant TotalCollectionSize_ = 15001; // total number of nfts
  uint256 private constant PresaleSize = 2000;
  uint256 private  SubPresaleAmount = 25; //number of nfts that can be minted
  uint256 private  MintLimit = 5; //number of nfts that can be minted in a presale by a person.
  
  mapping (address => uint256) public nftBalances;
  
  string private _baseTokenURI;


  bool private mintingStopped = false;
  
  bytes32 public merkleRoot = 0xaa9136a6ec80bd5d14f08b5f186e7ef2ae0c5b78d512e282f8b6234d19e54a51;

  constructor() ERC721A("AngrySheepClub: Platinum Series","ASC", PresaleSize, TotalCollectionSize_) {
    
   
    _baseTokenURI="https://amber-manual-nightingale-456.mypinata.cloud/ipfs/QmU2GxnSPFq2QuiRxtpBJ67K1gUUDbaaj69EK2pNZRAMde/";

  }

  // Functions Overriding ERC-721A transfer to enforce creator earnings.

   function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

 
 
  function sendBackup4kNFTS() external onlyOwner {
    _safeMint(address(0xc89f993c5eD6A35bF4acC7845bd825Ed007EDe3e), 4000); // function to send nft number 10k-15k to a wallet address

  }
  function sendBackup1kNFTS() external onlyOwner {
    _safeMint(address(0xc89f993c5eD6A35bF4acC7845bd825Ed007EDe3e), 1000); // function to send nft number 10k-15k to a wallet address

  }


  function stopMint() external onlyOwner {
    mintingStopped = true;
  }

  function startMint() external onlyOwner {
    mintingStopped = false;
  }

  function mint(uint256 quantity) external payable callerIsUser {
    require(quantity <= MAX_PER_Transaction,"can not mint this many NFTS in a single txn");
    require(nftBalances[msg.sender] + quantity <= MintLimit, "You have minted maximum allowed nfts in this presale.");
    require(msg.value >= PRICE * quantity, "Need to send more ETH to complete this txn.");
    require(totalSupply() + quantity <= TotalCollectionSize_, "reached max supply");
    require(!mintingStopped, "Minting is currently stopped");
      if(currentSupply + quantity < PresaleSize){
        if (currentSupply + quantity > SubPresaleAmount) {
          mintingStopped = true;
          require(false, "All NFTs in this Sub-Presale are sold out.");
        }
      } 
      else{
          mintingStopped = true;
          currentSupply = 0;
          MintLimit += 5;
            
      }
    _safeMint(msg.sender, quantity);
    currentSupply += quantity;
    nftBalances[msg.sender] += quantity;
  }


  function PresaleMint(uint256 quantity, bytes32[] calldata merkleproof) external payable callerIsUser {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify( merkleproof, merkleRoot, leaf),"This wallet is Not whitelisted"); 
    require(quantity <= MAX_PER_Transaction,"can not mint this many NFTS in a single txn");
    require(nftBalances[msg.sender] + quantity <= MintLimit, "You have minted maximum allowed nfts in this presale.");
    require(msg.value >= PRICE * quantity, "Need to send more ETH to complete this txn.");
    require(totalSupply() + quantity <= TotalCollectionSize_, "reached max supply");
    require(!mintingStopped, "Minting is currently stopped");
      if(currentSupply + quantity < PresaleSize){
        if (currentSupply + quantity > SubPresaleAmount) {
          mintingStopped = true;
          require(false, "All NFTs in this Sub-Presale are sold out.");
        }
      } 
      else{
          mintingStopped = true;
          MintLimit += 5;
            
      }
    _safeMint(msg.sender, quantity);
    currentSupply += quantity;
    nftBalances[msg.sender] += quantity;
  }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
        : "";
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
  
  function setMerkleRoot(bytes32 m) public onlyOwner{
    merkleRoot = m;
  }

  function getMerkleRoot() public view returns(bytes32){
    return merkleRoot;
  }

  function setSubPresaleAmount(uint256 s) public onlyOwner{
    SubPresaleAmount = s;
  }

  function getSubPresaleAmount() public view returns(uint256){
    return SubPresaleAmount;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool NFC, ) = msg.sender.call{value: address(this).balance}("");
    require(NFC, "Transfer failed.");
  }
 
  function changeMintPrice(uint256 _newPrice) external onlyOwner
  {
      PRICE = _newPrice;
  }
  function changeMAX_PER_Transaction(uint256 q) external onlyOwner
  {
      MAX_PER_Transaction = q;
  }
}
// File: contracts/AngrySheepDistribution.sol



/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

pragma solidity ^0.8.13; 



contract AngrySheepDistribution is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;

    bytes32 public merkleRoot = 0xaa9136a6ec80bd5d14f08b5f186e7ef2ae0c5b78d512e282f8b6234d19e54a51;
    address OGMintersPoolAddress = 0x94A995B8d15Bc8962E17e26064634C7751D693F3;
    mapping(address => mapping(uint256 => bool)) public claimuserStatus;
    bool isclaimRewardPaused       = false;
    bool iscontractDepositPaused   = false;

    uint256 public  newTokenId;
    AngrySheepClub ascContract = AngrySheepClub(0x29012E3FEb21B19B0db3051481c435484298a03e);


     constructor() ERC721A("AngrySheepClub-Distribution","ascd", 100, 15001) {
  }
        
        function flipcontractDeposit()public onlyOwner{
        iscontractDepositPaused=!iscontractDepositPaused;}

        function flipclaimReward()public onlyOwner{
        isclaimRewardPaused=!isclaimRewardPaused;}

        function deposit()public payable {
        require(iscontractDepositPaused==false,"deposit is paused");
        require(msg.value>0,"send some ether");}


       function claimHolderMemberRewardM(uint256 _tokenId, bytes32[] calldata merkleproof )public{
          newTokenId = 5001 + _tokenId;
            if(_tokenId > 9999){
              newTokenId = 10000 - _tokenId;
            }
        require(isclaimRewardPaused==false,"claimReward is paused");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify( merkleproof, merkleRoot, leaf),"Not whitelisted");
        require(claimuserStatus[msg.sender][newTokenId]==false,"already claimed");
        require(msg.sender==ascContract.ownerOf(newTokenId),"only Owner can claim");
        uint256 _userCut=address(this).balance/15000;
        payable(msg.sender).transfer(_userCut);
        claimuserStatus[msg.sender][newTokenId]=true;
        }

      
        function claimHolderMemberReward(uint256 _tokenId, bytes32[] calldata merkleproof)public{
          newTokenId = 5001 + _tokenId;
          if(_tokenId > 9999){
              newTokenId = 10000 - _tokenId;
            }
          require(isclaimRewardPaused==false,"claimReward is paused");
          bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
          require(MerkleProof.verify( merkleproof, merkleRoot, leaf),"Not whitelisted");
          require(claimuserStatus[msg.sender][newTokenId]==false,"already claimed");
          require(msg.sender==ascContract.ownerOf(newTokenId),"only Owner");
          uint256 _userCut=address(this).balance/15000;
          payable(msg.sender).transfer(_userCut);
          claimuserStatus[msg.sender][newTokenId]=true;
        }


  function withdrawMoney() external onlyOwner nonReentrant {
     
    (bool ogminterpool, ) = payable(OGMintersPoolAddress).call{value: address(this).balance * 50 / 100}("");
    require(ogminterpool); //First deploy the ogminterpool contract and then add that contracts address above.
    (bool nfc, ) = payable(0xa91EbE0e365B5cdfC5599a60d41D7bF8d93aEe06).call{value: address(this).balance * 20 / 100}("");
    require(nfc);
    (bool artist, ) = payable(0x2b838Ed253f393466D1330e34Fcb78e4F77d12a8).call{value: address(this).balance * 10 / 100}(""); 
    require(artist);
    
  }

  
    function setOGMinterspoolAddress(address _OGMinterspoolAddress) public onlyOwner {
        OGMintersPoolAddress = _OGMinterspoolAddress;
    }
    
    function setDistributionMerkleRoot(bytes32 m) public onlyOwner{
            merkleRoot = m;
    }
    
    function getDistributionMerkleRoot() public view returns(bytes32){
            return merkleRoot;
    }
}