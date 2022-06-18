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

    // if (!revealed) {
    //   return notRevealedUri;
    // } else {
    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    // }
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


  function _mint(address to, uint256 amount) internal virtual {
    // The below calculations do not depend on user input and
    // are very hard to overflow (nextId must be >= 2^256-2 for
    // that to happen) so using `unchecked` as a means of saving
    // gas is safe here
    unchecked {
      require(to != address(0), "ERC721A: mint to the zero address");      
      _owners[nextId] = to;

      for(uint256 i = 0; i < amount; i++) {
        _beforeTokenTransfer(address(0), to, nextId + i);
        emit Transfer(address(0), to, nextId + i);
      }

      nextId += amount;
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

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
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

contract MetaApeSociety is ERC721A, Ownable {
  // Use OZ MerkleProof Library to verify Merkle proofs
  using MerkleProof for bytes32[];

  uint256 public presale_price = 100000000000000000; // 0.1 Ether
  uint256 public public_price = 100000000000000000; // 0.1 Ether
  uint256 public maxTotalSupply = 10000;  
  uint256 public adminMintCount = 500;
  uint256 public MAX_PER_WALLET1 = 2;
  uint256 public MAX_PER_WALLET2 = 3;
  bool private _isPresaleActive;
  bool private _isMainSaleActive;
  string public notRevealedUri;
  bool public revealed = false;

  mapping(address => uint256) private mints;

  string private theBaseURI;

  bytes32 public root;

  constructor() ERC721A("MetaApeSociety", "MAS") {
    _isPresaleActive = false;
    _isMainSaleActive = true;    
  }

  function mint(uint256 amount, bytes32[] memory _proof) public payable {    
    require(_isPresaleActive && !_isMainSaleActive, "Presale must be active to mint tokens");  
    require(msg.sender == tx.origin, "mint from contract not allowed");
    require(msg.value >= presale_price * amount, "incorrect price");
    require(nextId <= maxTotalSupply, "not enough tokens");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET1, "mint limit reached");

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(_proof.verify(root, leaf), "invalid proof");

    mints[msg.sender] += amount;

    _mint(msg.sender, amount);
  }

  function PublicMint(uint256 amount) public payable {    
    require(!_isPresaleActive && _isMainSaleActive, "Main sale must be active to mint.");
    require(msg.sender == tx.origin, "mint from contract not allowed");
    require(msg.value >= public_price * amount, "incorrect price");
    require(nextId <= maxTotalSupply, "not enough tokens");
    require(mints[msg.sender] + amount <= MAX_PER_WALLET2, "mint limit reached");        

    mints[msg.sender] += amount;

    _mint(msg.sender, amount);
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
    adminMintCount += amount;

    require(nextId <= maxTotalSupply, "not enough tokens");

    _mint(_to, amount);
  }

  function SetNftPerLimitPreSale(uint256 _limit) public onlyOwner {
    MAX_PER_WALLET1 = _limit;
  }

  function SetNftPerLimit(uint256 _limit) public onlyOwner {
    MAX_PER_WALLET2 = _limit;
  }

  function SetPresaleCost(uint256 _newCost) public onlyOwner {
    presale_price = _newCost;
  }

  function SetPublicCost(uint256 _newCost) public onlyOwner {
    public_price = _newCost;
  }

  function flipPresaleState() external onlyOwner {
    _isPresaleActive = !_isPresaleActive;
  }

  function flipMainSaleState() external onlyOwner {
    _isMainSaleActive = !_isMainSaleActive;
  }
    
  function reveal() public onlyOwner {
    revealed = false;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function withdraw() public {
    address payable addr1 = payable(0xa9b32085810dDa2a7aBB5B2a7B193AA5ea14ddf8);
    address payable addr2 = payable(0xDFD540C447F1C9f56bc5273E677C4434d74D74f2);
    address payable addr3 = payable(0x020F2ce4a627186c8eC1AAd5A32210175C59F0dC);

    require(msg.sender == owner() || msg.sender == addr1 || msg.sender == addr2 || msg.sender == addr3, "access denied");

    uint256 balance = address(this).balance;
    uint256 value1 = balance * 6 / 10;
    uint256 value2 = balance * 3 / 10;
    uint256 value3 = balance - value1 - value2;

    addr1.transfer(value1);
    addr2.transfer(value2);
    addr3.transfer(value3);
  }
}