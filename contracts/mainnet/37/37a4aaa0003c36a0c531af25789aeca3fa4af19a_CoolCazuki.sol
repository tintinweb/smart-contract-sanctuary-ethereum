/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File sol-temple/src/tokens/[email protected]

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC721
 * @notice A complete ERC721 implementation including metadata and enumerable
 * functions. Completely gas optimized and extensible.
 */
abstract contract ERC721 {

  /// @notice See {ERC721-Transfer}.
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  /// @notice See {ERC721-Approval}.
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  /// @notice See {ERC721-ApprovalForAll}.
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  /// @notice See {ERC721Metadata-name}.
  string public name;
  /// @notice See {ERC721Metadata-symbol}.
  string public symbol;

  /// @notice See {ERC721Enumerable-totalSupply}.
  uint256 public totalSupply;

  /// @notice Array of all owners.
  address[] private _owners;
  /// @notice Mapping of all balances.
  mapping(address => uint256) private _balanceOf;
  /// @notice Mapping from token Id to it's approved address.
  mapping(uint256 => address) private _tokenApprovals;
  /// @notice Mapping of approvals between owner and operator.
  mapping(address => mapping(address => bool)) private _isApprovedForAll;

  constructor(string memory name_, string memory symbol_) {
    name = name_;
    symbol = symbol_;
  }

  /// @notice See {ERC721-balanceOf}.
  function balanceOf(address account_) public view virtual returns (uint256) {
    require(account_ != address(0), "ERC721: balance query for the zero address");
    return _balanceOf[account_];
  }

  /// @notice See {ERC721-ownerOf}.
  function ownerOf(uint256 tokenId_) public view virtual returns (address) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId_];
    return owner;
  }

  /// @notice See {ERC721Metadata-tokenURI}.
  function tokenURI(uint256) public view virtual returns (string memory);

  /// @notice See {ERC721-approve}.
  function approve(address to_, uint256 tokenId_) public virtual {
    address owner = ownerOf(tokenId_);
    require(to_ != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || _isApprovedForAll[owner][msg.sender],
      "ERC721: caller is not owner nor approved for all"
    );

    _approve(to_, tokenId_);
  }

  /// @notice See {ERC721-getApproved}.
  function getApproved(uint256 tokenId_) public view virtual returns (address) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId_];
  }

  /// @notice See {ERC721-setApprovalForAll}.
  function setApprovalForAll(address operator_, bool approved_) public virtual {
    _setApprovalForAll(msg.sender, operator_, approved_);
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address account_, address operator_) public view virtual returns (bool) {
    return _isApprovedForAll[account_][operator_];
  }

  /// @notice See {ERC721-transferFrom}.
  function transferFrom(
    address from_,
    address to_,
    uint256 tokenId_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
    _transfer(from_, to_, tokenId_);
  }

  /// @notice See {ERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 tokenId_
  ) public virtual {
    safeTransferFrom(from_, to_, tokenId_, "");
  }

  /// @notice See {ERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from_, to_, tokenId_, data_);
  }

  /// @notice See {ERC721Enumerable.tokenOfOwnerByIndex}.
  function tokenOfOwnerByIndex(address account_, uint256 index_) public view returns (uint256 tokenId) {
    require(index_ < balanceOf(account_), "ERC721Enumerable: Index out of bounds");
    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (account_ == _owners[i]) {
        if (count == index_) return i;
        else count++;
      }
    }
    revert("ERC721Enumerable: Index out of bounds");
  }

  /// @notice See {ERC721Enumerable.tokenByIndex}.
  function tokenByIndex(uint256 index_) public view virtual returns (uint256) {
    require(index_ < _owners.length, "ERC721Enumerable: Index out of bounds");
    return index_;
  }

  /// @notice Returns a list of all token Ids owned by `owner`.
  function walletOfOwner(address account_) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(account_);
    uint256[] memory ids = new uint256[](balance);
    for (uint256 i = 0; i < balance; i++) {
      ids[i] = tokenOfOwnerByIndex(account_, i);
    }
    return ids;
  }

   /**
   * @notice Safely transfers `tokenId_` token from `from_` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   */
  function _safeTransfer(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) internal virtual {
    _transfer(from_, to_, tokenId_);
    _checkOnERC721Received(from_, to_, tokenId_, data_);
  }

  /// @notice Returns whether `tokenId_` exists.
  function _exists(uint256 tokenId_) internal view virtual returns (bool) {
    return tokenId_ < _owners.length && _owners[tokenId_] != address(0);
  }

  /// @notice Returns whether `spender_` is allowed to manage `tokenId`.
  function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId_];
    return (spender_ == owner || getApproved(tokenId_) == spender_ || isApprovedForAll(owner, spender_));
  }

  /// @notice Safely mints `tokenId_` and transfers it to `to`.
  function _safeMint(address to_, uint256 tokenId_) internal virtual {
    _safeMint(to_, tokenId_, "");
  }

  /**
   * @notice Same as {_safeMint}, but with an additional `data_` parameter which is
   * forwarded in {ERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) internal virtual {
    _mint(to_, tokenId_);
    _checkOnERC721Received(address(0), to_, tokenId_, data_);
  }

  /// @notice Mints `tokenId_` and transfers it to `to_`.
  function _mint(address to_, uint256 tokenId_) internal virtual {
    require(!_exists(tokenId_), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to_, tokenId_);

    _owners.push(to_);
    totalSupply++;
    unchecked {
      _balanceOf[to_]++;
    }

    emit Transfer(address(0), to_, tokenId_);
    _afterTokenTransfer(address(0), to_, tokenId_);
  }

  /// @notice Destroys `tokenId`. The approval is cleared when the token is burned.
  function _burn(uint256 tokenId_) internal virtual {
    address owner = ownerOf(tokenId_);

    _beforeTokenTransfer(owner, address(0), tokenId_);

    // Clear approvals
    _approve(address(0), tokenId_);
    delete _owners[tokenId_];
    totalSupply--;
    _balanceOf[owner]--;

    emit Transfer(owner, address(0), tokenId_);
    _afterTokenTransfer(owner, address(0), tokenId_);
  }

  /// @notice Transfers `tokenId_` from `from_` to `to`.
  function _transfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {
    require(_owners[tokenId_] == from_, "ERC721: transfer of token that is not own");

    _beforeTokenTransfer(from_, to_, tokenId_);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId_);

    _owners[tokenId_] = to_;
    unchecked {
      _balanceOf[from_]--;
      _balanceOf[to_]++;
    }

    emit Transfer(from_, to_, tokenId_);
    _afterTokenTransfer(from_, to_, tokenId_);
  }

  /// @notice Approve `to_` to operate on `tokenId_`
  function _approve(address to_, uint256 tokenId_) internal virtual {
    _tokenApprovals[tokenId_] = to_;
    emit Approval(_owners[tokenId_], to_, tokenId_);
  }

  /// @notice Approve `operator_` to operate on all of `account_` tokens.
  function _setApprovalForAll(
    address account_,
    address operator_,
    bool approved_
  ) internal virtual {
    require(account_ != operator_, "ERC721: approve to caller");
    _isApprovedForAll[account_][operator_] = approved_;
    emit ApprovalForAll(account_, operator_, approved_);
  }

  /// @notice ERC721Receiver callback checking and calling helper.
  function _checkOnERC721Received(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) private {
    if (to_.code.length > 0) {
      try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 returned) {
        require(returned == 0x150b7a02, "ERC721: safe transfer to non ERC721Receiver implementation");
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: safe transfer to non ERC721Receiver implementation");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /// @notice Hook that is called before any token transfer.
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {}

  /// @notice Hook that is called after any token transfer.
  function _afterTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {}


  /// @notice See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId_) public view virtual returns (bool) {
    return
      interfaceId_ == 0x80ac58cd || // ERC721
      interfaceId_ == 0x5b5e139f || // ERC721Metadata
      interfaceId_ == 0x780e9d63 || // ERC721Enumerable
      interfaceId_ == 0x01ffc9a7; // ERC165
  }
}

interface IERC721Receiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes memory data
  ) external returns (bytes4);
}


// File sol-temple/src/utils/[email protected]

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Auth
 * @notice Just a simple authing system.
 */
abstract contract Auth {


  /// @notice Emitted when the ownership is transfered.
  event OwnershipTransfered(address indexed from, address indexed to);

  /// @notice Contract's owner address.
  address public owner;

  /// @notice A simple modifier just to check whether the sender is the owner.
  modifier onlyOwner() {
    require(msg.sender == owner, "Auth: sender is not the owner");
    _;
  }



  constructor() {
    _transferOwnership(msg.sender);
  }

  /// @notice Set the owner address to `owner_`.
  function transferOwnership(address owner_) public onlyOwner {
    require(owner != owner_, "Auth: transfering ownership to current owner");
    _transferOwnership(owner_);
  }

  /// @notice Set the owner address to `owner_`. Does not require anything
  function _transferOwnership(address owner_) internal {
    address oldOwner = owner;
    owner = owner_;

    emit OwnershipTransfered(oldOwner, owner_);
  }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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


// File contracts/CoolCazuki.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract CoolCazuki is Auth, ERC721 {
  using Strings for uint256;

  /// @notice Max supply.
  uint256 public constant SUPPLY_MAX = 5000;
  /// @notice Max amount per claim.
  uint256 public constant SUPPLY_PER_TX = 10;

  /// @notice 0 = CLOSED, 1 = PUBLIC.
  uint256 public saleState;

  /// @notice OpenSea proxy registry.
  address public opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
  /// @notice LooksRare marketplace transfer manager.
  address public looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved = true;

  /// @notice Unrevelead URI.
  string public unrevealedURI;
  /// @notice Metadata base URI.
  string public baseURI;
  /// @notice Metadata base file extension.
  string public baseExtension;

  constructor(string memory newUnrevealedURI) ERC721("Cool Cazuki", "CoolCazuki") {
    unrevealedURI = newUnrevealedURI;
  }

  /// @notice Claim one or more tokens.
  function mint(uint256 amount) external payable {
    uint256 supply = totalSupply;
    require(supply + amount <= SUPPLY_MAX, "Max supply exceeded");
    if (msg.sender != owner) {
      require(saleState == 1, "Public sale is not open");
      require(amount > 0 && amount <= SUPPLY_PER_TX, "Invalid claim amount");
      if (supply <= 1000) require(msg.value == 0, "Invalid ether amount");
      else require(msg.value == amount * 0.01 ether, "Invalid ether amount");
    }

    for (uint256 i = 0; i < amount; i++) _safeMint(msg.sender, supply++);
  }

  /// @notice See {IERC721-tokenURI}.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "ERC721Metadata: query for nonexisting token");

    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, id.toString(), baseExtension));
  }

  /// @notice Set baseURI to `newBaseURI`.
  function setBaseURI(string memory newBaseURI, string memory newBaseExtension) external onlyOwner {
    baseURI = newBaseURI;
    baseExtension = newBaseExtension;
    delete unrevealedURI;
  }

  /// @notice Set unrevealedURI to `newUnrevealedURI`.
  function setUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
    unrevealedURI = newUnrevealedURI;
    
  }

  /// @notice Set saleState to `newSaleState`.
  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set opensea to `newOpensea`.
  function setOpensea(address newOpensea) external onlyOwner {
    opensea = newOpensea;
  }

  /// @notice Set looksrare to `newLooksrare`.
  function setLooksrare(address newLooksrare) external onlyOwner {
    looksrare = newLooksrare;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /// @notice Withdraw `value` of ether to the sender.
  function withdraw(address payable to, uint256 amount) external onlyOwner {
    to.transfer(amount);
  }

  /// @notice Withdraw `value` of `token` to the sender.
  function withdrawERC20(IERC20 token, uint256 value) external onlyOwner {
    token.transfer(msg.sender, value);
  }

  /// @notice Withdraw `id` of `token` to the sender.
  function withdrawERC721(IERC721 token, uint256 id) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, id);
  }

  /// @notice Withdraw `id` with `value` from `token` to the sender.
  function withdrawERC1155(
    IERC1155 token,
    uint256 id,
    uint256 value
  ) external onlyOwner {
    token.safeTransferFrom(address(this), msg.sender, id, value, "");
  }

  /// @dev Modified for opensea and looksrare pre-approve so users can make truly gasless sales.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (!marketplacesApproved) return super.isApprovedForAll(owner, operator);

    return
      operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}