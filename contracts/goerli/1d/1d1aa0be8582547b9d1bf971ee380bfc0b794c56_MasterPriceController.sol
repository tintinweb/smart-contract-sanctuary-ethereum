/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-08-31
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // ==============================
    //        IERC721Metadata
    // ==============================

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

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

contract Ownable {
  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


/**
 * @dev One contract to manage multiple OmniHorse NFT contracts
 * main point of entry for NFT contracts will be getPrice
 */
contract MasterPriceController is Ownable {
  /**
   * @dev horsePriceArray maps address of horse contract to price array
   * horsePriceArray[_horseAddress][0] -> default price
   * horsePriceArray[_horseAddress][1] -> whitelist price
   * horsePriceArray[_horseAddress][2] -> discount price
   */
  mapping(address => uint256[]) public horsePriceArray;

  /**
   * @dev start and end mappings use timestamps in terms of seconds
   */
  mapping(address => uint256) public publicSaleStart;
  mapping(address => uint256) public publicSaleEnd;
  mapping(address => uint256) public wlSaleStart;
  mapping(address => uint256) public wlSaleEnd;

  /**
   * @dev wl and freeWl map horse contract address to user address to boolean
   * if(wl[horseAddress][userAddress] == true) -> user is whitelisted for that horse
   */
  mapping(address => mapping(address => bool)) public wl;
  mapping(address => mapping(address => bool)) public freeWl;

  /**
   * @dev maps a horse NFT address to a token to be used for promotions
   * Owners of the promotionToken will be treated as whitelisted
   */
  mapping(address => IERC721A) public promotionToken;
  mapping(address => address) public ptAddress;
  /**
   * @dev used for onlyContract() modifier
   */
  mapping(address => bool) public horseInitialized;
  /**
   * @dev if horseInitialized[contractAddress] == false -> the call is coming from a non-omni horse contract or a non-contract address
   */
  modifier onlyContract() {
    require(horseInitialized[msg.sender], "Only accessable through nftContract");
    _;
  }

  /**
   * @dev initializes an instance of a horse contract
   * and all associated variables
   * mappings can be updated after initialization using the various 'set' functions below
   * @param _priceArray should be initialized with this structure:
   * _priceArray[0] -> default price
   * _priceArray[1] -> whitelist price
   * _priceArray[2] -> discount price
   */
  function addHorse(address _address, uint256[] calldata _priceArray, uint256 wlStart, uint256 wlEnd, uint256 pubSaleStart, uint256 pubSaleEnd) external onlyOwner {
    require(wlStart < wlEnd && pubSaleStart < pubSaleEnd, 'Start times cannot be later than end times');
    horsePriceArray[_address] = _priceArray;
    wlSaleStart[_address] = wlStart;
    wlSaleEnd[_address] = wlEnd;
    publicSaleStart[_address] = pubSaleStart;
    publicSaleEnd[_address] = pubSaleEnd;
    horseInitialized[_address] = true;
  }

  function setPromotionToken(address _horseAddress, address _promotionToken) external onlyOwner {
    promotionToken[_horseAddress] = IERC721A(_promotionToken);
    ptAddress[_horseAddress] = _promotionToken;
  }

  /**
   * @dev updates the price array associated with a horse contract
   * all prices are in Wei
   */
  function setPrice(address _address, uint256[] calldata _priceArray) external onlyOwner {
    horsePriceArray[_address] = _priceArray;
  }

  /**
   * @dev @param _address is address of horse contract, @param pubSaleStart is timestamp (in seconds) of desired public sale start
   */
  function setPublicSaleStart(address _address, uint256 pubSaleStart) external onlyOwner {
    publicSaleStart[_address] = pubSaleStart;
  }

  /**
   * @dev [email protected] address is address of horse contract, @param pubSaleEnd is timestamp (in seconds) of desired public sale end
   */
  function setPublicSaleEnd(address _address, uint256 pubSaleEnd) external onlyOwner {
    publicSaleEnd[_address] = pubSaleEnd;
  }

  /**
   * @dev @param _address is address of horse contract, @param wlStart is timestamp (in seconds) of desired whitelist sale start
   */
  function setwlSaleStart(address _address, uint256 wlStart) external onlyOwner {
    wlSaleStart[_address] = wlStart;
  }

  /**
   * @dev @param _address is address of horse contract, @param wlEnd is timestamp (in seconds) of desired whitelist sale end
   */
  function setwlSaleEnd(address _address, uint256 wlEnd) external onlyOwner {
    wlSaleEnd[_address] = wlEnd;
  }

  /**
   * @dev adds array of addresses (@param user_) to whitelist mapping associated with horse contract (@param _horseAddress)
   */
  function addWhitelist(address _horseAddress, address[] calldata user_) external onlyOwner {
    for(uint256 i=0; user_.length != i;) {
      wl[_horseAddress][user_[i]] = true;
      ++i;
    }
  }

  /**
   * @dev adds array of addresses (@param user_) to free whitelist mapping associated with horse contract (@param _horseAddress)
   */
  function addFreeWhitelist(address _horseAddress, address[] calldata user_) external onlyOwner {
    for(uint256 i=0; user_.length != i;) {
      wl[_horseAddress][user_[i]] = true;
      freeWl[_horseAddress][user_[i]] = true;
      ++i;
    }
  }

  /**
   * @dev checks if current timestamp is between the public sale start and end times associated with given @param  _horseAddress
   */
  function saleEnabled(address _horseAddress) public view returns(bool) {
    return block.timestamp >= wlSaleStart[_horseAddress] && block.timestamp <= publicSaleEnd[_horseAddress];
  }

  /**
   * @dev checks if current timestamp is between the whitelist sale start and end times with given @param _horseAddress
   */
  function whitelistSale(address _horseAddress) public view returns(bool) {
    return block.timestamp >= wlSaleStart[_horseAddress] && block.timestamp <= wlSaleEnd[_horseAddress];
  }

  /**
   * @dev returns whether @param user_ is whitelisted for given @param _horseAddress
   */
  function isWhitelisted(address _horseAddress, address user_) public view returns(bool) {
    return wl[_horseAddress][user_];
  }

  /**
   * @dev returns the price to be charged to tx.origin for minting @param amount_ NFTs
   * changes state, should only be used from within an Omni Horse NFT contract
   */
  function getPrice(uint256 amount_) external onlyContract returns(uint256) {
    require(saleEnabled(msg.sender), "offline");
    if(freeWl[msg.sender][tx.origin]) {
      freeWl[msg.sender][tx.origin] = false;
      return --amount_ * horsePriceArray[msg.sender][1] + horsePriceArray[msg.sender][2];
    }
    if(whitelistSale(msg.sender)) {
      if(wl[msg.sender][tx.origin] || (address(promotionToken[msg.sender]) != address(0) && promotionToken[msg.sender].balanceOf(tx.origin) > 0)) {
        return amount_ * horsePriceArray[msg.sender][1];
      }
      revert("WL Only");
    }
    return amount_ * horsePriceArray[msg.sender][0];
  }

  /**
   * @dev returns the price @param user_ would be charged for minting @param amount_ of NFTs from @param horseContract
   * Read only, does not change state
   * Can be called on frontend to read correct price to charge user
   */
  function getPriceOnly(address horseContract, address user_, uint256 amount_) external view returns(uint256) {
    if(whitelistSale(horseContract)) {
      if(freeWl[horseContract][user_]) {
        return --amount_ * horsePriceArray[horseContract][1] + horsePriceArray[horseContract][2];
      }
      if(wl[horseContract][tx.origin] || (address(promotionToken[horseContract]) != address(0) && promotionToken[horseContract].balanceOf(tx.origin) > 0)) {
        return amount_ * horsePriceArray[horseContract][1];
      }
    }
    return amount_ * horsePriceArray[horseContract][0];
  }

  /**
   * @dev returns current timestamp in seconds
   */
  function getCurrentTimestamp() public view returns(uint256) {
    return block.timestamp;
  }
}