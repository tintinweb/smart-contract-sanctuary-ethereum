/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

/*

Coming Soon: https://4my.io/
                                                                                                                  
===================================================================================================================

 ______  _____  _____  ____  ____       _    _    ____    ____  ____  ____       ________  _________  ____  ____  
|_   _ \|_   _||_   _||_  _||_  _|     | |  | |  |_   \  /   _||_  _||_  _|     |_   __  ||  _   _  ||_   ||   _| 
  | |_) | | |    | |    \ \  / /       | |__| |_   |   \/   |    \ \  / /         | |_ \_||_/ | | \_|  | |__| |   
  |  __'. | '    ' |     \ \/ /        |____   _|  | |\  /| |     \ \/ /          |  _| _     | |      |  __  |   
 _| |__) | \ \__/ /      _|  |_     _      _| |_  _| |_\/_| |_    _|  |_     _   _| |__/ |   _| |_    _| |  | |_  
|_______/   `.__.'      |______|   (_)    |_____||_____||_____|  |______|   (_) |________|  |_____|  |____||____| 
     ______  _____  _____  ______   ______      ___   ____    ____       _       _____  ____  _____   ______      
   .' ____ \|_   _||_   _||_   _ \ |_   _ `.  .'   `.|_   \  /   _|     / \     |_   _||_   \|_   _|.' ____ \     
   | (___ \_| | |    | |    | |_) |  | | `. \/  .-.  \ |   \/   |      / _ \      | |    |   \ | |  | (___ \_|    
    _.____`.  | '    ' |    |  __'.  | |  | || |   | | | |\  /| |     / ___ \     | |    | |\ \| |   _.____`.     
   | \____) |  \ \__/ /    _| |__) |_| |_.' /\  `-'  /_| |_\/_| |_  _/ /   \ \_  _| |_  _| |_\   |_ | \____) |    
    \______.'   `.__.'    |_______/|______.'  `.___.'|_____||_____||____| |____||_____||_____|\____| \______.'    
                                                                                                                  
===================================================================================================================

 Ever wish you could passively monetize your subdomains? Stake them in our contract then transfer ownership to 
 start passively getting royalties by selling subdomain registrations on your ENS domain names.You might be wondering 
 why you'd want to do this intead of just selling them yourself? Well, with tools like Icy.Tools you can now get 
 flagged when you mint an NFT. This will mint NFTs and promote both the 4my.eth brand AND your subdomain/base domains. 
 Using ERC721A to massively optimize minting, it costs almost nothing in gas for users to register your subdomains.

 - Step One: Call stakeDomain(domain, node, enabled, price, unlockTimestamp) on this contract using Etherscan or the UI.
   - The domain is the domain name (E.G. for 4my.eth it would be "4my").
   - Enabled can be toggled using setEnabled at anytime, but if it is false people can't mint your domain.
   - Price (IN WEI) that you want to charge for your subdomains, use the following converter:
       https://eth-converter.com/
   - Unlock date, this is to prevent people from listing their domains for subdomains then taking them back and rugging.
     - You can provide 0 if you want it to start unlocked, but know people likely won't want to pay for these.
     - Use this converter to get your timestamp: https://www.epochconverter.com/
   - Example: stakeDomain("4my", 0x...., true, 10000000000000000, 1751429469) would list 4my.eth subdomains for 0.01E for 3 years.
   - Once again, to unstake call unstake(domainId), it will unstake it if you are the owner of it AND it is unlocked.

 - Step Two: Goto the ENS contract (or to the ENS control panel) and transfer ownership of your subdomain.
   - You need to transfer it to **this contract address**, when you do it will be locked here until you unstake.
   - By staking it, you won't see it in your wallet anymore and can't make changes on ENS.
   - To unstake it, call unstake(domainId), it will return to you and everthing will be as it was before you staked.
   - NOBODY else, not even the OWNER OF THE CONTRACT can remove your staked ENS domain. Only the wallet that staked it.
     - If you doubt this claim, please read the code.

 - Step Three: Instruct people to use registerDomain("domain-prefix", domainIndex) and send the price you provided.
   - They will recieve an NFT representing their purchase, and as long as you don't unstake it will remain active.
   - If they transfer the NFT ownership of the subdomain will transfer, same goes for sales.

 If you do these steps and leave it there, we will have a UI up and running soon enough on 4my.io that allows for the 
 browsing of staked domains. This project is 100% on-chain and all data for these interactions happens on chain. No 
 external APIs are used. Until the UI is completed, you can have anyone use ETHERSCAN to register a domain name with
 you, and you will recieve 50% of the minting price. The rest will go into the contract for development.
*/

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
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

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
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

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
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

  /**
   * @dev See {IERC165-supportsInterface}.
   */
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

  /**
   * @dev See {IERC721-balanceOf}.
   */
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

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
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
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
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
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
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
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

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

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
   
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) public {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (tx.origin == prevOwnership.addr ||
      getApproved(tokenId) == tx.origin ||
      isApprovedForAll(prevOwnership.addr, tx.origin)) ||
      ownerOf(tokenId) == tx.origin;

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

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
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

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
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

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
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

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IENS {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
    function setAddr(bytes32 node, address a) external;
    function addr(bytes32 node) external view returns (address payable);
    function setAddr(bytes32 node, uint coinType, bytes memory a) external;
}

contract SubdomainRegistrar is Ownable, ERC721A {
    constructor() ERC721A("4My Subdomains", "4MY", 1, 9999999) {}

    bytes public domainSuffix = 'eth';
    
    uint256 public royalties = 2; // 50 Percent

    mapping(uint256 => string) public prefixMap;
    mapping(string => uint256) public prefixIndexMap;
    mapping(uint256 => uint256) public domainIndexMap;

    uint256 domainCount = 1;

    mapping(uint256 => string) public domainMap;
    mapping(string => uint256) public domainLabelMap;
    mapping(string => mapping(string => uint256)) public domainPrefixMap;
    mapping(uint256 => bool) public domainEnabledMap;
    mapping(uint256 => bool) public domainStakedMap;
    mapping(uint256 => uint256) public domainUnlockMap;
    mapping(uint256 => address) public domainOwnerMap;
    mapping(uint256 => uint256) public domainPriceMap;
    mapping(uint256 => mapping(address => uint256)) public domainContractAllowlistMap;

    // 0xf6305c19e814d2a75429Fd637d01F7ee0E77d615 - Rinkeby
    // 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41 - Default mainnet
    address public ensResolverAddress = 0xf6305c19e814d2a75429Fd637d01F7ee0E77d615;

    // 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e - Rinkeby and Mainnet
    IENS public ensContract = IENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    function setEnsResovler(address addr) external onlyOwner {
        ensResolverAddress = addr;
    }

    function setEnsContract(address addr) external onlyOwner {
        ensContract = IENS(addr);
    }

    function stakeDomain (string memory domain, bool enabled, uint256 price, uint256 unlockUnixTimestamp) external {
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 suffixHash = keccak256(abi.encodePacked(node, keccak256(domainSuffix)));
        bytes32 domainHash = keccak256(abi.encodePacked(suffixHash, keccak256(bytes(domain))));

        address nodeOwner = ensContract.owner(domainHash);
        require(msg.sender == nodeOwner, "You don't own this domain.");

        // if it hasn't been staked before...
        if (domainLabelMap[domain] == 0) {
            domainMap[domainCount] = domain;
            domainLabelMap[domain] = domainCount;
            domainEnabledMap[domainCount] = enabled;
            domainStakedMap[domainCount] = true;
            domainUnlockMap[domainCount] = unlockUnixTimestamp;
            domainOwnerMap[domainCount] = msg.sender;
            domainPriceMap[domainCount] = price;

            // Transfers ownership to the contract. 
            // Read unstakeDomain, you can get it back.
            // ONLY you can, owner cannot unstake your domains.
            ensContract.setOwner(node, address(this));
            // Can't be done, will likely be done on JS web3 side as second TRX.

            domainCount = domainCount + 1;

        // if it has been staked before...
        } else {
            uint256 domainIndex = domainLabelMap[domain];
            domainEnabledMap[domainIndex] = enabled;
            domainStakedMap[domainIndex] = true;
            domainUnlockMap[domainIndex] = unlockUnixTimestamp;
            domainOwnerMap[domainIndex] = msg.sender;
            domainPriceMap[domainIndex] = price;

            // Transfers ownership to the contract. 
            // Read unstakeDomain, you can get it back.
            // ONLY you can, owner cannot unstake your domains.
            ensContract.setOwner(node, address(this));
            // Can't be done, will likely be done on JS web3 side as second TRX.
        }
    }

    function unstakeDomain (uint256 domainIndex) external {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        require(domainOwnerMap[domainIndex] == msg.sender, 'You do not own this domain.');
        require(domainUnlockMap[domainIndex] < block.timestamp, "Not alllowed to unlock yet.");
        domainEnabledMap[domainIndex] = false;
        domainStakedMap[domainIndex] = false;
        domainOwnerMap[domainIndex] = address(0);
        
        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 suffixHash = keccak256(abi.encodePacked(node, keccak256(domainSuffix)));
        bytes32 domainHash = keccak256(abi.encodePacked(suffixHash, keccak256(bytes(domainMap[domainIndex]))));
        require(ensContract.owner(domainHash) == address(this), "Contract does not own the ENS name.");

        // Transfers ownership from the contract BACK TO YOU. 
        // ONLY you can, owner cannot unstake your domains to himself.
        ensContract.setOwner(domainHash, domainOwnerMap[domainIndex]);
        // Needed or else domain is trapped in contract.
        // Does NOT use msg.sender, so admin override is fine.
        // See: forceUnstake(domainIndex) onlyOwner
        // Note: It will return to domainOwnerMap[domainIndex] NOT msg.sender.
    }

    function forceUnstakeDomain (uint256 domainIndex) external onlyOwner {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        domainEnabledMap[domainIndex] = false;
        domainStakedMap[domainIndex] = false;
        domainOwnerMap[domainIndex] = address(0);

        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 suffixHash = keccak256(abi.encodePacked(node, keccak256(domainSuffix)));
        bytes32 domainHash = keccak256(abi.encodePacked(suffixHash, keccak256(bytes(domainMap[domainIndex]))));

        // Transfers ownership from the contract BACK TO YOU. 
        ensContract.setOwner(domainHash, domainOwnerMap[domainIndex]);
        // Admins should also be able to unstake contracts at their discretion to return 
        // them to their owners in the case of a mistaken staking.
        // Note: It will return to domainOwnerMap[domainIndex] NOT msg.sender.
    }

    function editDomain (uint256 domainIndex, string memory domain, bool enabled) external {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        require(domainOwnerMap[domainIndex] == msg.sender, 'You do not own this domain.');
        domainMap[domainIndex] = domain;
        domainEnabledMap[domainIndex] = enabled;
    }

    function enableDomain(uint256 domainIndex) external {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        require(domainOwnerMap[domainIndex] == msg.sender, 'Not owner of domain.');
        domainEnabledMap[domainIndex] = true;
    }

    function disableDomain(uint256 domainIndex) external {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        require(domainOwnerMap[domainIndex] == msg.sender, 'Not owner of domain.');
        domainEnabledMap[domainIndex] = true;
    }

    function setPrice (uint256 domainIndex, uint256 amount) external {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        require(domainOwnerMap[domainIndex] == msg.sender, 'Not owner of domain.');
        domainPriceMap[domainIndex] = amount;
    }

    function setDomainSuffix (bytes memory suffix) external onlyOwner {
        domainSuffix = suffix;
    }

    function setRoyalties (uint256 amount) external onlyOwner {
        royalties = amount;
    }

    function registerSubdomain(string memory label, uint256 domainIndex) external payable {
        require(bytes(domainMap[domainIndex]).length != 0, 'Invalid domain index.');
        require(domainPriceMap[domainIndex] == msg.value, 'Invalid ETH amount sent.');

        string memory domain = domainMap[domainIndex];

        require(domainPrefixMap[domain][label] == 0, 'Subdomain already registered.');

        address domainOwner = domainOwnerMap[domainIndex];

        uint256 supply = totalSupply();

        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 suffixHash = keccak256(abi.encodePacked(node, keccak256(domainSuffix)));
        bytes32 domainHash = keccak256(abi.encodePacked(suffixHash, keccak256(bytes(domain))));
        require(ensContract.owner(domainHash) == address(this), "Contract does not own the ENS name.");

        bytes32 subdomainHash = keccak256(abi.encodePacked(domainHash, keccak256(bytes(label))));
        
        ensContract.setSubnodeRecord(domainHash, keccak256(bytes(label)), address(this), ensResolverAddress, 0);

        IAddrResolver ensResolver = IAddrResolver(ensResolverAddress);
        ensResolver.setAddr(subdomainHash, msg.sender);
        ensResolver.setAddr(subdomainHash, 60, addressToBytes(msg.sender));

        // Set prefix.
        prefixMap[supply] = string(label);
        prefixIndexMap[string(label)] = supply;
        domainIndexMap[supply] = domainIndex;
        domainPrefixMap[domain][label] = 1;
        _safeMint(msg.sender, 1);

        payable(domainOwner).transfer(domainPriceMap[domainIndex] / royalties);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory prefix = prefixMap[tokenId];
        uint256 domainIndex = domainIndexMap[tokenId];
        address domainOwner = domainOwnerMap[domainIndex];

        string[17] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        parts[1] = 'Domain Registered:';
        parts[2] = '</text><text x="20" y="40" class="base">';
        parts[3] = prefix;
        parts[4] = '.';
        parts[5] = string(domainMap[domainIndex]);
        parts[6] = '.';
        parts[7] = string(domainSuffix);
        parts[8] = '</text><text x="10" y="60" class="base">Base Domain Owner:</text><text x="20" y="80" class="base">';
        parts[9] = Strings.toHexString(uint256(uint160(domainOwner)), 20);
        parts[10] = '</text><text x="10" y="100" class="base">Base Domain Staked: ';
        parts[11] = domainStakedMap[domainIndex] ? (block.timestamp < domainUnlockMap[domainIndex] ? 'Locked and Staked' : 'Unlocked but Staked') : 'Unstaked *';
        parts[12] = '</text><text x="10" y="120" class="base">Minting Enabled: ';
        parts[13] = domainEnabledMap[domainIndex] ? 'Enabled' : 'Disabled **';
        parts[14] = '</text><text x="10" y="300" class="base">* If unstaked, may not be valid.</text>';
        parts[15] = '<text x="10" y="320" class="base">** If minting disabled, cannot make more.</text>';
        parts[16] = '</svg>';

        string memory subdomain = string(abi.encodePacked(parts[3], parts[4], parts[5], parts[6], parts[7]));
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
        output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15], parts[16]));
        bytes memory jsonA = abi.encodePacked('{"name": "', subdomain, ' (#', toString(tokenId), ')", "description": "Subdomains by 4my.io, get your 4my.eth domain today.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)));
        jsonA = abi.encodePacked(jsonA, '", "attributes": [{"trait_type":"prefix","value":"', prefix, '"},{"trait_type":"base_domain","value":"', string(domainMap[domainIndex]), '"},{"trait_type":"base_price","value":', toString(domainPriceMap[domainIndex]), '},{"trait_type":"domain_index","value":"');
        jsonA = abi.encodePacked(jsonA, toString(domainIndex), '"},{"trait_type":"base_owner","value":"', parts[9], '"},{"trait_type":"base_staked","value":', domainStakedMap[domainIndex] ? '"Staked"' : '"Unstaked"', '},{"trait_type":"base_mintable","value":', domainEnabledMap[domainIndex] ? '"Enabled"' : '"Disabled"', '}');
        jsonA = abi.encodePacked(jsonA, ',{"trait_type":"unlock_date","value":', toString(domainUnlockMap[domainIndex]), '}', ']}');
        string memory json = Base64.encode(bytes(string(jsonA)));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setAddr(uint256 tokenId, uint coin, address a) public {
        require (ownerOf(tokenId) == msg.sender, "Do not own token.");

        string memory label = prefixMap[tokenId];
        uint256 domainIndex = domainIndexMap[tokenId];
        string memory domain = domainMap[domainIndex];

        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 suffixHash = keccak256(abi.encodePacked(node, keccak256(domainSuffix)));
        bytes32 domainHash = keccak256(abi.encodePacked(suffixHash, keccak256(bytes(domain))));
        bytes32 subdomainHash = keccak256(abi.encodePacked(domainHash, keccak256(bytes(label))));
        
        IAddrResolver ensResolver = IAddrResolver(ensResolverAddress);
        ensResolver.setAddr(subdomainHash, coin, addressToBytes(a));
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        string memory label = prefixMap[tokenId];
        uint256 domainIndex = domainIndexMap[tokenId];
        string memory domain = domainMap[domainIndex];

        bytes32 node = 0x0000000000000000000000000000000000000000000000000000000000000000;
        bytes32 suffixHash = keccak256(abi.encodePacked(node, keccak256(domainSuffix)));
        bytes32 domainHash = keccak256(abi.encodePacked(suffixHash, keccak256(bytes(domain))));
        bytes32 subdomainHash = keccak256(abi.encodePacked(domainHash, keccak256(bytes(label))));

        IAddrResolver ensResolver = IAddrResolver(ensResolverAddress);
        ensResolver.setAddr(subdomainHash, to);
        ensResolver.setAddr(subdomainHash, 60, addressToBytes(to));

        this._transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _data;
       transferFrom(from, to, tokenId);
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";
        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}