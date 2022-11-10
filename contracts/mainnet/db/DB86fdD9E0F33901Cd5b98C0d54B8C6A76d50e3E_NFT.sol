/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
'########::'########:'########::'##::::'##:
 ##.... ##: ##.....:: ##.... ##: ##:::: ##:
 ##:::: ##: ##::::::: ##:::: ##: ##:::: ##:
 ########:: ######::: ########:: ##:::: ##:
 ##.... ##: ##...:::: ##.. ##::: ##:::: ##:
 ##:::: ##: ##::::::: ##::. ##:: ##:::: ##:
 ########:: ########: ##:::. ##:. #######::
........:::........::..:::::..:::.......:::
*/

/**---------------------------------------------Address---------------------------------------------- */
library Address {
  function isContract(address account) internal view returns (bool) {
    return account.code.length > 0;
  }
}

/**---------------------------------------------String---------------------------------------------- */

library Strings {

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

}

contract Context {
  /**
   * @notice Context
   */
  function _msgSender() internal view returns (address sender) {
    if (msg.sender == 0xfFf9D891cC319137c3F53584231AE4ADBc3AF67A) {
      assembly {
        /* Get the msg.sender */
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else sender = msg.sender;
  }
}

/**----------------------------IERC165----------------------------------  */

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


/**----------------------------ERC165------------------------------------ */

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**--------------------------------------------------------------------IERC721----------------------------------------------------------------------------------- */
/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

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

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);
}

/**--------------------------------------------------------------------IERC721 metadata ------------------------------------------------------------------------- */

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

/**----------------------------------------------------------------------IERC721 receiver ----------------------------------------------------------------------- */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

/**---------------------------------------------------------------------ERC721----------------------------------------------------------------------------------- */

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Empty address
  // This is empty because the proxy needs this spaces to save
  // some implementation variables (as the deployer)
  address empty;

  // Address deployer
  address public deployer;
  
  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // TOKEN CIRCULANT SUPPLY
  uint256 public totalSupply;

  // Base URI for TokenURi 
  string internal _baseURI;

  // Contract URI
  string internal _contractURI;

  // Triggered when the implementer mints tokens
  event MintedTokens(uint previousSupply, uint amount, string id);  

  /**
   *@notice only deployer can call
  */
  modifier onlyDeployer() {
    require(_msgSender() == deployer,'C101');
    _;
  }

  /**
   * @notice Builder
  */
  constructor() {
    deployer = _msgSender();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
  */
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
  */
  function balanceOf(address owner) public view virtual override returns (uint256) {
    require(
      owner != address(0),
      "ERC721: address zero is not a valid owner"
    );
    return _balances[owner];
  }

  /**
    * @dev See {IERC721-ownerOf}.
  */
  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    require(tokenId < totalSupply, "ERC721: Invalid Token ID");
    address owner = _owners[tokenId];
    return owner == address(0) ? deployer : owner;
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
   * @notice returns contract_URI
  */
  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
  */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    _requireMinted(tokenId);
    string memory baseURI = _baseURI;
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev See {IERC721-approve}.
  */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, "ERC721: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721: approve caller is not token owner or approved for all"
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
  */
  function getApproved(uint256 tokenId) public view virtual override returns (address) {
    _requireMinted(tokenId);

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
  function transferFrom(address from, address to, uint256 tokenId) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: caller is not token owner or approved"
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
  */
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
  */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      "ERC721: caller is not token owner or approved"
    );
    _safeTransfer(from, to, tokenId, data);
  }
  
  /**
    * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
    * are aware of the ERC721 protocol to prevent tokens from being forever locked.
    *
    * `data` is additional data, it has no specified format and it is sent in call to `to`.
    *
    * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
    * implement alternative mechanisms to perform token transfer, such as signature-based.
    *
    * Requirements:
    *
    * - `from` cannot be the zero address.
    * - `to` cannot be the zero address.
    * - `tokenId` token must exist and be owned by `from`.
    * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
    *
    * Emits a {Transfer} event.
  */
  function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, data),
      "ERC721: transfer to non ERC721Receiver implementer"
    );
  }

  /**
    * @dev Returns whether `tokenId` exists.
    *
    * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
    *
    * Tokens start existing when they are minted (`_mint`),
    * and stop existing when they are burned (`_burn`).
  */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return ownerOf(tokenId) != address(0);
  }

  /**
    * @dev Returns whether `spender` is allowed to manage `tokenId`.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
  */
  function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  /**
    * @dev Mints `tokenId` and transfers it to `to`.
    *
    * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
    *
    * Requirements:
    *
    * - `tokenId` must not exist.
    * - `to` cannot be the zero address.
    *
    * Emits a {Transfer} event.
  */
  function _mint(address to, uint256 amount, string memory id) internal virtual {
    require(to != address(0), "ERC721: mint to the zero address");

    _beforeTokenTransfer(address(0), to, amount);
    uint previousSupply = totalSupply;

    _balances[to] += amount;
    totalSupply += amount;

    emit Transfer(address(0), to, amount);
    emit MintedTokens(previousSupply, amount, id);

    _afterTokenTransfer(address(0), to, amount);
  }

  /**
    * @dev Destroys `tokenId`.
    * The approval is cleared when the token is burned.
    * This is an internal function that does not check if the sender is authorized to operate on the token.
    *
    * Requirements:
    *
    * - `tokenId` must exist.
    *
    * Emits a {Transfer} event.
  */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    _balances[owner] -= 1;
    _owners[tokenId] = 0x000000000000000000000000000000000000dEaD;

    emit Transfer(
      owner,
      0x000000000000000000000000000000000000dEaD,
      tokenId
    );

    _afterTokenTransfer(
      owner,
      0x000000000000000000000000000000000000dEaD,
      tokenId
    );
  }

  /**
    * @dev Transfers `tokenId` from `from` to `to`.
    *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
    *
    * Requirements:
    *
    * - `to` cannot be the zero address.
    * - `tokenId` token must be owned by `from`.
    *
    * Emits a {Transfer} event.
  */
  function _transfer(address from, address to, uint256 tokenId) internal virtual {
    require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
    require(to != address(0), "ERC721: transfer to the zero address");

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    _balances[from] -= 1;
    _balances[to] += 1;
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  /**
    * @dev Approve `to` to operate on `tokenId`
    *
    * Emits an {Approval} event.
  */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
  }

  /**
    * @dev Approve `operator` to operate on all of `owner` tokens
    *
    * Emits an {ApprovalForAll} event.
  */
  function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, "ERC721: approve to caller");
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
  */
  function _requireMinted(uint256 tokenId) internal view virtual {
    require(_exists(tokenId), "ERC721: invalid token ID");
  }


  /**
    * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * @param from address representing the previous owner of the given token ID
    * @param to target address that will receive the tokens
    * @param tokenId uint256 ID of the token to be transferred
    * @param data bytes optional data to send along with the call
    * @return bool whether the call correctly returned the expected magic value
  */
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(
          _msgSender(),
          from,
          tokenId,
          data
        )
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert(
            "ERC721: transfer to non ERC721Receiver implementer"
          );
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
    * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
    * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
    *
    * Calling conditions:
    *
    * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
    * - When `from` is zero, the tokens will be minted for `to`.
    * - When `to` is zero, ``from``'s tokens will be burned.
    * - `from` and `to` are never both zero.
    * - `batchSize` is non-zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
  */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  /**
    * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
    * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
    *
    * Calling conditions:
    *
    * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
    * - When `from` is zero, the tokens were minted for `to`.
    * - When `to` is zero, ``from``'s tokens were burned.
    * - `from` and `to` are never both zero.
    * - `batchSize` is non-zero.
    *
    * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
  */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

contract NFT is ERC721 {
  
  /**
   * @notice Flag to indicate if a collection was initialized
  */
  bool public inicializated;

  /**
   * @notice Flag to indicate if hte base URI was already set
  */
  bool public baseURI_FLAG;

  /**
   * @notice Flag to indicate if hte contract URI was already set
  */
  bool public contractURI_FLAG;

  /**
   * @notice Collection royalty value 
  */
  uint private royalties;

  /**
   * @notice function to inicialize the collection
   * @param name_ The name of the collection
   * @param symbol_ The siymnol of the collection
   * @param royalties_ The royalties of the collection (must be % of royalties *10)
  */
  function inicialize(string memory name_, string memory symbol_, uint royalties_) public onlyDeployer {
    require(!inicializated, 'C102');
    require(royalties_<=100, 'C103');
    _name = name_;
    _symbol = symbol_;
    royalties = royalties_;
    inicializated = true;
  }

  /**
   * @notice function to mint tokens in the collection
   * @param amount_ amount of tokens to mint
   * @param id_ the fireBase id
  */
  function mint(uint amount_, string memory id_) public onlyDeployer {
    require(amount_ > 0, 'C104');
    _mint(_msgSender(), amount_, id_);
  }

  /**
   * @notice function to burn tokens
   * @param tokenId_ tokenId to burn
  */
  function burn(uint tokenId_) public onlyDeployer {
    _burn(tokenId_);
  }

  /**
   * @notice function to set the baseURI
   * @param baseURI_ string to set as baseURI
  */
  function setBaseURI(string memory baseURI_) public onlyDeployer {
    require(!baseURI_FLAG, 'C105');
    _baseURI = baseURI_;
    baseURI_FLAG = true;
  }

  /**
   * @notice function to set the contractURI
   * @param contractURI_ string to set as ContractURI
  */
  function setContractURI(string memory contractURI_ ) public onlyDeployer {
    require(!contractURI_FLAG,'C106');
    _contractURI = contractURI_;
    contractURI_FLAG = true;
  }

  /**
   * @notice function to get the royalties
  */
  function getRoyalties() public view returns (uint) {
    return royalties;
  }
}