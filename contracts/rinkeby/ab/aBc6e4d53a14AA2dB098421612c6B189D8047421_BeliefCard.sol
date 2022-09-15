/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Beliefcard.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

pragma solidity >=0.8.0 <0.9.0;

abstract contract ERC1155 is IERC165, IERC1155, IERC1155MetadataURI {

  mapping(address => mapping(uint256 => uint256)) public balanceOf;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  mapping(uint256 => uint256) public totalSupply;

  function uri(uint256) public view virtual returns (string memory);

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    returns (uint256[] memory)
  {
    require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

    uint256[] memory batchBalances = new uint256[](accounts.length);
    for (uint256 i = 0; i < accounts.length; i++) batchBalances[i] = balanceOf[accounts[i]][ids[i]];

    return batchBalances;
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    _setApprovalForAll(msg.sender, operator, approved);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    require(from == msg.sender || isApprovedForAll[from][msg.sender], "ERC1155: caller is not owner nor approved");
    _safeTransferFrom(from, to, id, amount, data);
  }

  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    require(
      from == msg.sender || isApprovedForAll[from][msg.sender],
      "ERC1155: transfer caller is not owner nor approved"
    );
    _safeBatchTransferFrom(from, to, ids, amounts, data);
  }

  function exists(uint256 id) public view virtual returns (bool) {
    return totalSupply[id] > 0;
  }

  function _safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: transfer to the zero address");

    _trackSupplyBeforeTransfer(from, to, _asSingletonArray(id), _asSingletonArray(amount));

    _beforeTokenTransfer(msg.sender, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

    require(balanceOf[from][id] >= amount, "ERC1155: insufficient balance for transfer");
    unchecked {
      balanceOf[from][id] -= amount;
    }
    balanceOf[to][id] += amount;

    emit TransferSingle(msg.sender, from, to, id, amount);
    _checkOnERC1155Received(msg.sender, from, to, id, amount, data);
    _afterTokenTransfer(msg.sender, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
  }

  function _safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
    require(to != address(0), "ERC1155: transfer to the zero address");

    _trackSupplyBeforeTransfer(from, to, ids, amounts);

    _beforeTokenTransfer(msg.sender, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; ++i) {
      require(balanceOf[from][ids[i]] >= amounts[i], "ERC1155: insufficient balance for transfer");
      unchecked {
        balanceOf[from][ids[i]] -= amounts[i];
        balanceOf[to][ids[i]] += amounts[i];
      }
    }

    emit TransferBatch(msg.sender, from, to, ids, amounts);
    _checkOnERC1155BatchReceived(msg.sender, from, to, ids, amounts, data);
    _afterTokenTransfer(msg.sender, from, to, ids, amounts, data);
  }

  function _mint(
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");

    _trackSupplyBeforeTransfer(address(0), to, _asSingletonArray(id), _asSingletonArray(amount));

    _beforeTokenTransfer(msg.sender, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

    balanceOf[to][id] += amount;
    emit TransferSingle(msg.sender, address(0), to, id, amount);
    _checkOnERC1155Received(msg.sender, address(0), to, id, amount, data);
    _afterTokenTransfer(msg.sender, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
  }

  function _mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    require(to != address(0), "ERC1155: mint to the zero address");
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    _trackSupplyBeforeTransfer(address(0), to, ids, amounts);

    _beforeTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      balanceOf[to][ids[i]] += amounts[i];
    }

    emit TransferBatch(msg.sender, address(0), to, ids, amounts);
    _checkOnERC1155BatchReceived(msg.sender, address(0), to, ids, amounts, data);
    _afterTokenTransfer(msg.sender, address(0), to, ids, amounts, data);
  }

  function _burn(
    address from,
    uint256 id,
    uint256 amount
  ) internal virtual {
    _trackSupplyBeforeTransfer(from, address(0), _asSingletonArray(id), _asSingletonArray(amount));

    _beforeTokenTransfer(msg.sender, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

    require(balanceOf[from][id] >= amount, "ERC1155: burn amount exceeds balance");
    unchecked {
      balanceOf[from][id] -= amount;
    }

    emit TransferSingle(msg.sender, from, address(0), id, amount);
    _afterTokenTransfer(msg.sender, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
  }

  function _burnBatch(
    address from,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

    _trackSupplyBeforeTransfer(from, address(0), ids, amounts);

    _beforeTokenTransfer(msg.sender, from, address(0), ids, amounts, "");

    for (uint256 i = 0; i < ids.length; i++) {
      require(balanceOf[from][ids[i]] >= amounts[i], "ERC1155: burn amount exceeds balance");
      unchecked {
        balanceOf[from][ids[i]] -= amounts[i];
      }
    }

    emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    _afterTokenTransfer(msg.sender, from, address(0), ids, amounts, "");
  }

  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC1155: setting approval status for self");
    isApprovedForAll[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _afterTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _trackSupplyBeforeTransfer(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts
  ) private {
    if (from == address(0)) {
      for (uint256 i = 0; i < ids.length; i++) {
        totalSupply[ids[i]] += amounts[i];
      }
    }

    if (to == address(0)) {
      for (uint256 i = 0; i < ids.length; i++) {
        totalSupply[ids[i]] -= amounts[i];
      }
    }
  }

  function _checkOnERC1155Received(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 returnValue) {
        require(returnValue == 0xf23a6e61, "ERC1155: transfer to non ERC1155Receiver implementer");
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _checkOnERC1155BatchReceived(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (to.code.length > 0) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 returnValue) {
        require(returnValue == 0xbc197c81, "ERC1155: transfer to non ERC1155Receiver implementer");
      } catch {
        revert("ERC1155: transfer to non ERC1155Receiver implementer");
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;

    return array;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
    return
      interfaceId == type(IERC1155).interfaceId || // ERC1155
      interfaceId == type(IERC1155MetadataURI).interfaceId || // ERC1155MetadataURI
      interfaceId == type(IERC165).interfaceId; // ERC165
  }
}

interface IERC1155Receiver {
  function onERC1155Received(
    address operator,
    address from,
    uint256 id,
    uint256 value,
    bytes calldata data
  ) external returns (bytes4);

  function onERC1155BatchReceived(
    address operator,
    address from,
    uint256[] calldata ids,
    uint256[] calldata values,
    bytes calldata data
  ) external returns (bytes4);
}

abstract contract PrimeProof {
    bytes32 internal _merkleRootPrime;
    function _setPrime(bytes32 merkleRoot_) internal virtual {
        _merkleRootPrime = merkleRoot_;
    }
    function isPrime(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRootPrime;
    }
}

abstract contract CompositeProof {
    bytes32 internal _merkleRootComposite;
    function _setComposite(bytes32 merkleRoot_) internal virtual {
        _merkleRootComposite = merkleRoot_;
    }
    function isComposite(address address_, bytes32[] memory proof_) public view returns (bool) {
        bytes32 _leaf = keccak256(abi.encodePacked(address_));
        for (uint256 i = 0; i < proof_.length; i++) {
            _leaf = _leaf < proof_[i] ? keccak256(abi.encodePacked(_leaf, proof_[i])) : keccak256(abi.encodePacked(proof_[i], _leaf));
        }
        return _leaf == _merkleRootComposite;
    }
}

//////////////////////////////////////////////////////////////////////////////////////
//    dBBBBb   dBBBP  dBP    dBP dBBBP  dBBBBP    dBBBP dBBBBBb   dBBBBBb    dBBBBb //
//       dBP                                                 BB       dBP       dB' //
//   dBBBK'  dBBP   dBP    dBP dBBP   dBBBP     dBP      dBP BB   dBBBBK'  dBP dB'  //
//  dB' db  dBP    dBP    dBP dBP    dBP       dBP      dBP  BB  dBP  BB  dBP dB'   //
// dBBBBP' dBBBBP dBBBBP dBP dBBBBP dBP       dBBBBP   dBBBBBBB dBP  dB' dBBBBB'    //
//                                                                                  //
//                       NYT-TDNR BELIEF CARD by 0xSumo                             //
//////////////////////////////////////////////////////////////////////////////////////

contract BeliefCard is ERC1155, Ownable, PrimeProof, CompositeProof {

    using Strings for uint256;
    string public baseURI;
    string public baseExtension;
    uint256 private maxMintsPerP = 3;
    uint256 private maxMintsPerC = 1;
    uint256 public _maxSupply = 3003;
    bool public primeEnabled = false;
    bool public compositeEnabled = false;
    mapping(address => uint256) public pMinted;
    mapping(address => uint256) public cMinted;

   constructor(
    string memory newBaseURI,
    string memory newBaseExtension
   )  {
    baseURI = newBaseURI;
    baseExtension = newBaseExtension;
   }

   function giftCard(address _address, uint256 belief, uint256 _amount) external onlyOwner { //gift always good
    require(belief == 1 || belief == 2 || belief == 3, "Query for nonexisting cards");
    require(totalSupply[1] + totalSupply[2] + totalSupply[3] + 1 < maxSuppply(), "No more cards");

    _mint(_address, belief, _amount, "");
   }

   //Prime101 Sale//
   function getCardPrime(uint256 belief, bytes32[] memory proof_) external {
    require(primeEnabled, "Prime paused");
    require(isPrime(msg.sender, proof_), "You are not in prime");
    require(maxMintsPerP >= pMinted[msg.sender] + 1, "You have no Prime Mint left");
    require(belief == 1 || belief == 2 || belief == 3, "Query for nonexisting cards");
    require(totalSupply[1] + totalSupply[2] + totalSupply[3] + 1 < maxSuppply(), "No more cards");

    pMinted[msg.sender]++;
    cMinted[msg.sender]++;
    _mint(msg.sender, belief, 1, "");
  }

  //Composite Sale//
   function getCardComposite(uint256 belief, bytes32[] memory proof_) external {
    require(compositeEnabled, "Composite paused");
    require(isComposite(msg.sender, proof_), "You are not in composite");
    require(cMinted[msg.sender] == 0, "You have no Composite Mint left");
    require(belief == 1 || belief == 2 || belief == 3, "Query for nonexisting cards");
    require(totalSupply[1] + totalSupply[2] + totalSupply[3] + 1 < maxSuppply(), "No more cards");

    pMinted[msg.sender]++;
    cMinted[msg.sender]++;
    _mint(msg.sender, belief, 1, "");
  }

  function maxSuppply() public view returns (uint256) {
    return _maxSupply;
  }

  function setPrimeClaim(bool bool_) external onlyOwner {
    primeEnabled = bool_;
  }

  function setCompositeClaim(bool bool_) external onlyOwner {
    compositeEnabled = bool_;
  }

  function setPrimeRoot(bytes32 merkleRoot_) external onlyOwner {
    _setPrime(merkleRoot_);
  }

  function setCompositeRoot(bytes32 merkleRoot_) external onlyOwner {
    _setComposite(merkleRoot_);
  }

  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function setBaseExtension(string memory newBaseExtension) external onlyOwner {
    baseExtension = newBaseExtension;
  }

  function uri(uint256 id) public view override returns (string memory) {
    require(super.exists(id), "Query for nonexisting cards");
    return string(abi.encodePacked(baseURI, id.toString(), baseExtension));
  }
}