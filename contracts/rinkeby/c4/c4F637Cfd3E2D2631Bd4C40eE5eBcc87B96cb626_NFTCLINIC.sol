// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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


    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
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


interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
  using Address for address;
  using Strings for uint256;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev Returns next token ID to be mint
   */
  uint256 public nextId = 1;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection. It
   *      also sets a `maxTotalSupply` variable to cap the tokens to ever be created
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");

    uint256 count = 0;

    for(uint256 i = 1; _exists(i); i++) {
      if(_owners[i] == owner) {
        count++;
        if(_owners[i + 1] == address(0) && _exists(i + 1)) count++;
      }
    }

    return count;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    return _owners[tokenId] != address(0) ? _owners[tokenId] : _owners[tokenId - 1];
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";    
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721A: transfer caller is not owner nor approved");

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721A: transfer caller is not owner nor approved");
    _safeTransfer(from, to, tokenId, _data);
  }


  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721A: transfer to non ERC721Receiver implementer");
  }


  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId != 0 && tokenId < nextId;
  }


  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    require(_exists(tokenId), "ERC721A: operator query for nonexistent token");
    address owner = ownerOf(tokenId);
    return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
  }


  function _safeMint(address to, uint256 amount) internal virtual {
    _safeMint(to, amount, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(address to, uint256 amount, bytes memory _data) internal virtual {
    _mint(to, amount);    

    for(uint256 i = 0; i < amount; i++) {
      require(
        _checkOnERC721Received(address(0), to, nextId - i - 1, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
    }
  }


  function _mint(address to, uint256 tokenId) internal virtual {
    // The below calculations do not depend on user input and
    // are very hard to overflow (nextId must be >= 2^256-2 for
    // that to happen) so using `unchecked` as a means of saving
    // gas is safe here
    unchecked {
      require(to != address(0), "ERC721A: mint to the zero address");      
      _owners[tokenId] = to;

      _beforeTokenTransfer(address(0), to, tokenId);
      emit Transfer(address(0), to, tokenId);  
      nextId = nextId + 1;          
    }
  }


  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    // The below calculations are very hard to overflow (nextId must
    // be = 2^256-1 for that to happen) so using `unchecked` as
    // a means of saving gas is safe here
    unchecked {
      require(
        ownerOf(tokenId) == from,
        "ERC721A: transfer of token that is not own"
      );
      require(to != address(0), "ERC721A: transfer to the zero address");

      _beforeTokenTransfer(from, to, tokenId);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId);

      if(_owners[tokenId] == address(0)) {
        _owners[tokenId] = to;
      } else {
        _owners[tokenId] = to;

        if(_owners[tokenId + 1] == address(0)) {
          _owners[tokenId + 1] = from;
        }
      }

      emit Transfer(from, to, tokenId);
    }
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ownerOf(tokenId), to, tokenId);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    require(owner != operator, "ERC721A: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }


  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
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


  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
   * @dev See {IEnumerableERC721-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return nextId - 1;
  }

  /**
   * @dev See {IEnumerableERC721-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) external view returns (uint256) {
    require(_exists(index + 1), "ERC721A: global index out of bounds");

    return index + 1;
  }

  /**
   * @dev See {IEnumerableERC721-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");

    uint256 count = 0;
    uint256 i = 1;

    for(; _exists(i) && count < index + 1; i++) {
      if(_owners[i] == owner) {
        count++;
        if(_owners[i + 1] == address(0) && count < index + 1 && _exists(i + 1)) {
          count++;
          i++;
        }
      }
    }

    if(count == index + 1) return i - 1;
    else revert("ERC721A: owner index out of bounds");
  }
}

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

library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

library Counters {
    struct Counter {
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

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract NFTCLINIC is ERC721A, ReentrancyGuard, Ownable {
  // Use OZ MerkleProof Library to verify Merkle proofs
  using MerkleProof for bytes32[];
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  uint256 public Bronze_price =    0.09 ether; // 0.05 Ether
  uint256 public Bronzewl_price = 0.07 ether; // 0.045 Ether
  uint256 public Silver_price =    0.18 ether; // 0.1 Ether
  uint256 public Gold_price =     0.46 ether; // 0.25 Ether
  uint256 public Platinum_price = 0.92 ether; // 0.5 Ether
  uint256 public maxTotalSupply = 3000;    
  uint256 public MAX_Platinum_SUPPLY = 250;
  uint256 public MAX_Gold_SUPPLY = 500;
  uint256 public MAX_Silver_SUPPLY = 750;
  uint256 public MAX_Bronze_SUPPLY = 1500;  
  uint256 public MAX_PER_WALLET = 30;
  bool private _isPresaleActive;
  bool private _isMainSaleActive;

  mapping(address => uint256) private mints;
  string private theBaseURI;
  bytes32 public root;

  address[10] public fundRecipients = [
    0x67eCB9E74580DC02CA62F1085E0Cf50e7918D974, //owner1
    0xa0eE4F43918aCa49662037671c0ad82F971aa388, //owner2
    0x13FfDC8F649bfD43D54b35CDF1a08b85E133E87e, //owner3
    0x91B1b5f2F153cC12f056793e39C6d60f818E0087, //investor
    0x3b7cf36B6BeACA538BEf989a9DDE239189fDBD26, //Horseman
    0x5369b26e2da6D9e33D0a802B922f2F6Fb0bd5522, //Charity
    0xb3234A21cF04aAFAF92a75196001523e52BA442b, //Dev
    0xD158fBD4762ace2e94D86DA3EFE4D3c0BAE01fCB, //Liquid
    0xD8D4D4f7E7637D75Dd3729396567b30bFfc7E8f1, //Marketing
    0x8dF1c9fa4c097a4177ad19e66a5F5FFdd2f2eADd  //Teachers
  ];
  uint256[] public receivePercentagePt = [25, 25, 25, 5, 5, 3, 3, 3, 3, 3];   //distribution in basis points

  constructor() ERC721A("NFTCLINIC", "NTC") { 
  }

  Counters.Counter private BronzeSupplyCounter;
  Counters.Counter private SilverSupplyCounter;
  Counters.Counter private GoldSupplyCounter;
  Counters.Counter private PlatinumSupplyCounter;

  function totalBronzeSupply() public view returns (uint256) {
    return BronzeSupplyCounter.current();
  }

  function totalSilverSupply() public view returns (uint256) {
    return SilverSupplyCounter.current();
  }

  function totalGoldSupply() public view returns (uint256) {
    return GoldSupplyCounter.current();
  }

  function totalPlatinumSupply() public view returns (uint256) {
    return PlatinumSupplyCounter.current();
  }

  function mint(uint256 amount, bytes32[] memory _proof) public payable {        
    require(msg.value >= Bronzewl_price * amount, "incorrect price");
    require(nextId <= maxTotalSupply, "not enough tokens");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET, "mint limit reached");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(_proof.verify(root, leaf), "invalid proof");

    mints[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {         
      _mint(msg.sender, MAX_Platinum_SUPPLY + MAX_Gold_SUPPLY + MAX_Silver_SUPPLY + totalBronzeSupply());
      BronzeSupplyCounter.increment();
    }
  }

  function BronzeMint(uint256 amount) public payable nonReentrant {
    require(msg.value >= Bronze_price * amount, "incorrect price");
    require(totalBronzeSupply() + amount - 1 < MAX_Bronze_SUPPLY, "Exceeds max supply");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET, "mint limit reached");        

    mints[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {         
      _mint(msg.sender, MAX_Platinum_SUPPLY + MAX_Gold_SUPPLY + MAX_Silver_SUPPLY + totalBronzeSupply());
      BronzeSupplyCounter.increment();
    }    
  }

  function SilverMint(uint256 amount) public payable nonReentrant {     
    require(msg.value >= Silver_price * amount, "incorrect price");
    require(totalSilverSupply() + amount - 1 < MAX_Silver_SUPPLY, "Exceeds max supply");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET, "mint limit reached");        

    mints[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {
      _mint(msg.sender, MAX_Platinum_SUPPLY + MAX_Gold_SUPPLY + totalSilverSupply());
      SilverSupplyCounter.increment();
    } 
  }

  function GoldMint(uint256 amount) public payable nonReentrant {    
    require(msg.value >= Gold_price * amount, "incorrect price");
    require(totalGoldSupply() + amount - 1 < MAX_Gold_SUPPLY, "Exceeds max supply");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET, "mint limit reached");        

    mints[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {
      _mint(msg.sender, MAX_Platinum_SUPPLY + totalGoldSupply());
      GoldSupplyCounter.increment();
    }
  }

  function PlatinumMint(uint256 amount) public payable nonReentrant {
    require(msg.value >= Platinum_price * amount, "incorrect price");
    require(totalPlatinumSupply() + amount - 1 < MAX_Platinum_SUPPLY, "Exceeds max supply");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET, "mint limit reached");        

    mints[msg.sender] += amount;
    for (uint256 i = 0; i < amount; i++) {
      _mint(msg.sender, totalPlatinumSupply());
      PlatinumSupplyCounter.increment();      
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return theBaseURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    theBaseURI = _newBaseURI;
  }

  function setRoot(bytes32 _newRoot) public onlyOwner {
    root = _newRoot;
  }

  function freegift(address _to, uint256 amount) public onlyOwner {        
    require(nextId <= maxTotalSupply, "not enough tokens");

    _mint(_to, amount);
  }

  function SetNftPerLimit(uint256 _limit) public onlyOwner {
    MAX_PER_WALLET = _limit;
  }

  function SetBronzeCost(uint256 _newCost) public onlyOwner {
    Bronze_price = _newCost;
  }

  function SetSilverCost(uint256 _newCost) public onlyOwner {
    Silver_price = _newCost;
  } 

  function SetGoldCost(uint256 _newCost) public onlyOwner {
    Gold_price = _newCost;
  }

  function SetPlatinumCost(uint256 _newCost) public onlyOwner {
    Platinum_price = _newCost;
  }   

  function withdrawFund() public onlyOwner {
      uint256 currentBal = address(this).balance;
      require(currentBal > 0);
      for (uint256 i = 0; i < fundRecipients.length-1; i++) {
      _withdraw(fundRecipients[i], currentBal.mul(receivePercentagePt[i]).div(100));
      }
      //final address receives remainder to prevent ether dust
      _withdraw(fundRecipients[fundRecipients.length-1], address(this).balance);
  }

  function _withdraw(address _addr, uint256 _amt) private {
      (bool success,) = _addr.call{value: _amt}("");
      require(success, "Transfer failed");
  }
}