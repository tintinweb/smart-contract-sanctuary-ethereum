// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './tokens/ERC721A.sol';
import './libraries/SSTORE2Map.sol';

import './SigmoidThreshold.sol';
import './RarityCompositingEngine.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract Merge is ERC721A, ERC2981, Ownable {
  using Strings for uint256;
  uint256 public MAX_MINTING_PER_BLOCK = 3;

  uint256 public deployDate;
  bool public isActive;
  SigmoidThreshold public curve;

  // Price Vars
  uint256 public a0;
  uint256 public b0;
  uint256 public c0;
  uint256 public d0;

  // Rarity Vars
  uint256 public a1;
  uint256 public b1;
  uint256 public c1;
  uint256 public d1;

  address public treasury;
  address public boostToken;

  // RCE
  RarityCompositingEngine public rce;

  uint256 public boostTokenBaseAmount = 1000;
  mapping(uint256 => uint256) public rarityTokenMap; // tokenID => rarityScore

  bool public emergencyShutdown = false;
  mapping(bytes32 => uint256) public blockMintingGuardMap; // hash(address + block number) => numMinted
  mapping(address => bool) public blacklistMap; // hash(address) => boolean

  event ChangedIsActive(bool isActive);
  event ChangedEmergencyShutdown(bool shutdown);

  struct DeployMergeNFTConfig {
    string name;
    string symbol;
    address treasury;
    address boostToken;
    address rce;
    address curve;
    uint256 a0;
    uint256 b0;
    uint256 c0;
    uint256 d0;
    uint256 a1;
    uint256 b1;
    uint256 c1;
    uint256 d1;
  }

  struct SetCurveParams {
    uint256 a0;
    uint256 b0;
    uint256 c0;
    uint256 d0;
    uint256 a1;
    uint256 b1;
    uint256 c1;
    uint256 d1;
  }

  constructor(DeployMergeNFTConfig memory config) ERC721A() {
    _name = config.name;
    _symbol = config.symbol;
    a0 = config.a0;
    b0 = config.b0;
    c0 = config.c0;
    d0 = config.d0;
    a1 = config.a1;
    b1 = config.b1;
    c1 = config.c1;
    d1 = config.d1;
    boostToken = config.boostToken;
    curve = SigmoidThreshold(config.curve);
    deployDate = block.timestamp;
    treasury = config.treasury;
    rce = RarityCompositingEngine(config.rce);
    //_transferOwnership(config.treasury);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721A, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function getTokenBalance(address token, address userAddress)
    public
    view
    returns (uint256)
  {
    return IERC721(token).balanceOf(userAddress);
  }

  function currentIndex() public view returns (uint256) {
    return _currentIndex;
  }

  function setIsActive(bool _isActive) public onlyOwner {
    isActive = _isActive;
    emit ChangedIsActive(isActive);
  }

  function setEmergencyShutdown(bool shutdown) public onlyOwner {
    emergencyShutdown = shutdown;
    emit ChangedEmergencyShutdown(shutdown);
  }

  function setBlacklist(address[] memory _list) public onlyOwner {
    for (uint256 i = 0; i < _list.length; ++i) {
      blacklistMap[_list[i]] = true;
    }
  }

  function setRoyalty(uint96 newRoyaltyFraction) public onlyOwner {
    _setDefaultRoyalty(treasury, newRoyaltyFraction);
  }

  function setMaxMinting(uint256 _max) public onlyOwner {
    MAX_MINTING_PER_BLOCK = _max;
  }

  function setDeployDate(uint256 _date) public onlyOwner {
    deployDate = _date;
  }

  function setBoostToken(address _boostToken) public onlyOwner {
    boostToken = _boostToken;
  }

  function setBoostTokenBaseAmount(uint256 _amount) public onlyOwner {
    boostTokenBaseAmount = _amount;
  }

  function setTreasury(address _treasury) public onlyOwner {
    treasury = _treasury;
  }

  function setRCE(address _rce) public onlyOwner {
    rce = RarityCompositingEngine(_rce);
  }

  function setCurve(address _curve) public onlyOwner {
    curve = SigmoidThreshold(_curve);
  }

  function setCurveParams(SetCurveParams memory config) public onlyOwner {
    a0 = config.a0;
    b0 = config.b0;
    c0 = config.c0;
    a1 = config.a1;
    b1 = config.b1;
    c1 = config.c1;
  }

  // X variable in graph. Curve is tuned to
  function numSecondsSinceDeploy() public view returns (uint256) {
    return (block.timestamp - deployDate);
  }

  function isMergeByDifficulty() public view virtual returns (bool) {
    return (block.difficulty > (2**64)) || (block.difficulty == 0);
  }

  modifier onlyIsActive() {
    require(isActive, 'minting needs to be active to mint');
    _;
  }

  modifier onlyIsNotShutdown() {
    require(!emergencyShutdown, 'emergency shutdown is in place');
    _;
  }

  modifier onlyIsNotMerge() {
    require(
      !isMergeByDifficulty(),
      'minting needs to be done before Proof of Stake'
    );
    _;
  }

  function getBoostScore(address userAddress) external view returns (uint256) {
    uint256 balance = getTokenBalance(boostToken, userAddress);
    uint256 maxBalance = balance >= 16 ? 16 : balance;
    return maxBalance * boostTokenBaseAmount;
  }

  function getRarityScoreForToken(uint256 tokenId)
    public
    view
    returns (uint256)
  {
    uint256 curr = tokenId;
    if (_startTokenId() <= curr && curr < _currentIndex) {
      while (true) {
        if (rarityTokenMap[curr] != 0) {
          return rarityTokenMap[curr];
        }
        curr--;
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  function getCurrentRarityScore(address userAddress)
    public
    view
    returns (uint256)
  {
    SigmoidThreshold.CurveParams memory config;
    config._x = numSecondsSinceDeploy();
    config.minX = a1;
    config.maxX = b1;
    config.minY = c1;
    config.maxY = d1;
    uint256 rarity = curve.getY(config);
    try this.getBoostScore(userAddress) returns (uint256 boost) {
      return rarity + boost;
    } catch {
      return rarity;
    }
  }

  function getCurrentPrice() public view returns (uint256) {
    SigmoidThreshold.CurveParams memory config;
    config._x = numSecondsSinceDeploy();
    config.minX = a0;
    config.maxX = b0;
    config.minY = c0;
    config.maxY = d0;
    uint256 price = curve.getY(config);
    return price; // in GWEI
  }

  function contractURI() public view returns (string memory) {
    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              _name,
              '", "description": "A Proof of Beauty project. Fully on-chain generative statues to remember the MERGE.',
              '", "external_link": "https://merge.pob.studio/',
              '", "image": "https://merge.pob.studio/assets/logo.png" }'
            )
          )
        )
      );
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(_exists(tokenId), 'URI query for nonexistent token');
    uint256 rarityScore = getRarityScoreForToken(tokenId);
    bytes memory seed = abi.encodePacked(rarityScore, tokenId);
    (, uint16[] memory attributeIndexes) = rce.getRarity(rarityScore, seed);
    string memory image = rce.getRender(attributeIndexes);

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name": "Statue #',
              tokenId.toString(),
              '", "description": "',
              'A Proof of Beauty project. Fully on-chain generative statues to remember the MERGE.',
              '", "image": "',
              image,
              '", "aspect_ratio": "1',
              '", "attributes": ',
              rce.getAttributesJSON(attributeIndexes),
              '}'
            )
          )
        )
      );
  }

  function mint(address to, uint256 numMints)
    public
    payable
    onlyIsActive
    onlyIsNotMerge
    onlyIsNotShutdown
  {
    bytes32 blockNumHash = keccak256(abi.encode(block.number, msg.sender));
    require(
      blockMintingGuardMap[blockNumHash] + numMints <= MAX_MINTING_PER_BLOCK,
      'exceeded max number of mints'
    );
    require(!blacklistMap[msg.sender], 'caller is blacklisted');
    uint256 totalPrice = getCurrentPrice() * numMints;
    require(totalPrice <= msg.value, 'insufficient funds to pay for mint');
    uint256 currentRarityScore = getCurrentRarityScore(msg.sender);
    rarityTokenMap[_currentIndex] = currentRarityScore;
    blockMintingGuardMap[blockNumHash] =
      blockMintingGuardMap[blockNumHash] +
      numMints;
    _mint(to, numMints, '', false);
    treasury.call{value: totalPrice}('');
    payable(msg.sender).transfer(msg.value - totalPrice);
  }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerQueryForNonexistentToken();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata {
  using Address for address;
  using Strings for uint256;

  // Compiler will pack this into a single 256bit word.
  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
  }

  // Compiler will pack this into a single 256bit word.
  struct AddressData {
    // Realistically, 2**64-1 is more than enough.
    uint64 balance;
    // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberMinted;
    // Keeps track of burn count with minimal overhead for tokenomics.
    uint64 numberBurned;
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
  }

  // The tokenId of the next token to be minted.
  uint256 internal _currentIndex;

  // The number of tokens burned.
  uint256 internal _burnCounter;

  // Token name
  string internal _name;

  // Token symbol
  string internal _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) internal _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  constructor() {
    _currentIndex = _startTokenId();
  }

  /**
   * To change the starting tokenId, please override this function.
   */
  function _startTokenId() internal view virtual returns (uint256) {
    return 0;
  }

  /**
   * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
   */
  function totalSupply() public view returns (uint256) {
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than _currentIndex - _startTokenId() times
    unchecked {
      return _currentIndex - _burnCounter - _startTokenId();
    }
  }

  /**
   * Returns the total amount of tokens minted in the contract.
   */
  function _totalMinted() internal view returns (uint256) {
    // Counter underflow is impossible as _currentIndex does not decrement,
    // and it is initialized to _startTokenId()
    unchecked {
      return _currentIndex - _startTokenId();
    }
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
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    if (owner == address(0)) revert BalanceQueryForZeroAddress();
    return uint256(_addressData[owner].balance);
  }

  /**
   * Returns the number of tokens minted by `owner`.
   */
  function _numberMinted(address owner) internal view returns (uint256) {
    return uint256(_addressData[owner].numberMinted);
  }

  /**
   * Returns the number of tokens burned by or on behalf of `owner`.
   */
  function _numberBurned(address owner) internal view returns (uint256) {
    return uint256(_addressData[owner].numberBurned);
  }

  /**
   * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
   */
  function _getAux(address owner) internal view returns (uint64) {
    return _addressData[owner].aux;
  }

  /**
   * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
   * If there are multiple variables, please pack them into a uint64.
   */
  function _setAux(address owner, uint64 aux) internal {
    _addressData[owner].aux = aux;
  }

  /**
   * Gas spent here starts off proportional to the maximum mint batch size.
   * It gradually moves to O(1) as tokens get transferred around in the collection over time.
   */
  function _ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    uint256 curr = tokenId;

    unchecked {
      if (_startTokenId() <= curr && curr < _currentIndex) {
        TokenOwnership memory ownership = _ownerships[curr];
        if (!ownership.burned) {
          if (ownership.addr != address(0)) {
            return ownership;
          }
          // Invariant:
          // There will always be an ownership that has an address and is not burned
          // before an ownership that does not have an address and is not burned.
          // Hence, curr will not underflow.
          while (true) {
            curr--;
            ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
              return ownership;
            }
          }
        }
      }
    }
    revert OwnerQueryForNonexistentToken();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _ownershipOf(tokenId).addr;
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
    if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length != 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : '';
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return '';
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert ApprovalCallerNotOwnerNorApproved();
    }

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    if (operator == _msgSender()) revert ApproveToCaller();

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
    safeTransferFrom(from, to, tokenId, '');
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
    if (
      to.isContract() &&
      !_checkContractOnERC721Received(from, to, tokenId, _data)
    ) {
      revert TransferToNonERC721ReceiverImplementer();
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return
      _startTokenId() <= tokenId &&
      tokenId < _currentIndex &&
      !_ownerships[tokenId].burned;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, '');
  }

  /**
   * @dev Safely mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    _mint(to, quantity, _data, true);
  }

  /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `quantity` must be greater than 0.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 quantity,
    bytes memory _data,
    bool safe
  ) internal {
    uint256 startTokenId = _currentIndex;
    if (to == address(0)) revert MintToZeroAddress();
    if (quantity == 0) revert MintZeroQuantity();

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    // Overflows are incredibly unrealistic.
    // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
    // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
    unchecked {
      _addressData[to].balance += uint64(quantity);
      _addressData[to].numberMinted += uint64(quantity);

      _ownerships[startTokenId].addr = to;
      _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

      uint256 updatedIndex = startTokenId;
      uint256 end = updatedIndex + quantity;

      if (safe && to.isContract()) {
        do {
          emit Transfer(address(0), to, updatedIndex);
          if (
            !_checkContractOnERC721Received(
              address(0),
              to,
              updatedIndex++,
              _data
            )
          ) {
            revert TransferToNonERC721ReceiverImplementer();
          }
        } while (updatedIndex != end);
        // Reentrancy protection
        if (_currentIndex != startTokenId) revert();
      } else {
        do {
          emit Transfer(address(0), to, updatedIndex++);
        } while (updatedIndex != end);
      }
      _currentIndex = updatedIndex;
    }
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
  ) private {
    TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

    if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

    bool isApprovedOrOwner = (_msgSender() == from ||
      isApprovedForAll(from, _msgSender()) ||
      getApproved(tokenId) == _msgSender());

    if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    if (to == address(0)) revert TransferToZeroAddress();

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;

      TokenOwnership storage currSlot = _ownerships[tokenId];
      currSlot.addr = to;
      currSlot.startTimestamp = uint64(block.timestamp);

      // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      TokenOwnership storage nextSlot = _ownerships[nextTokenId];
      if (nextSlot.addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId != _currentIndex) {
          nextSlot.addr = from;
          nextSlot.startTimestamp = prevOwnership.startTimestamp;
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev This is equivalent to _burn(tokenId, false)
   */
  function _burn(uint256 tokenId) internal virtual {
    _burn(tokenId, false);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
    TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

    address from = prevOwnership.addr;

    if (approvalCheck) {
      bool isApprovedOrOwner = (_msgSender() == from ||
        isApprovedForAll(from, _msgSender()) ||
        getApproved(tokenId) == _msgSender());

      if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    // Underflow of the sender's balance is impossible because we check for
    // ownership above and the recipient's balance can't realistically overflow.
    // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
    unchecked {
      AddressData storage addressData = _addressData[from];
      addressData.balance -= 1;
      addressData.numberBurned += 1;

      // Keep track of who burned the token, and the timestamp of burning.
      TokenOwnership storage currSlot = _ownerships[tokenId];
      currSlot.addr = from;
      currSlot.startTimestamp = uint64(block.timestamp);
      currSlot.burned = true;

      // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      TokenOwnership storage nextSlot = _ownerships[nextTokenId];
      if (nextSlot.addr == address(0)) {
        // This will suffice for checking _exists(nextTokenId),
        // as a burned slot cannot contain the zero address.
        if (nextTokenId != _currentIndex) {
          nextSlot.addr = from;
          nextSlot.startTimestamp = prevOwnership.startTimestamp;
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
      _burnCounter++;
    }
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

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkContractOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try
      IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
    returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert TransferToNonERC721ReceiverImplementer();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   * And also called before burning one token.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, `tokenId` will be burned by `from`.
   * - `from` and `to` are never both zero.
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
   * And also called after one token has been burned.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
   * transferred to `to`.
   * - When `from` is zero, `tokenId` has been minted for `to`.
   * - When `to` is zero, `tokenId` has been burned by `from`.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './Create3.sol';

import './Bytecode.sol';

/**
  @title A write-once key-value storage for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>
  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2Map {
  error WriteError();

  //                                         keccak256(bytes('@0xSequence.SSTORE2Map.slot'))
  bytes32 private constant SLOT_KEY_PREFIX =
    0xd351a9253491dfef66f53115e9e3afda3b5fdef08a1de6937da91188ec553be5;

  function internalKey(bytes32 _key) internal pure returns (bytes32) {
    // Mutate the key so it doesn't collide
    // if the contract is also using CREATE3 for other things
    return keccak256(abi.encode(SLOT_KEY_PREFIX, _key));
  }

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data To be written
    @param _key unique string key for accessing the written data (can only be used once)
    @return pointer Pointer to the written `_data`
  */
  function write(string memory _key, bytes memory _data)
    internal
    returns (address pointer)
  {
    return write(keccak256(bytes(_key)), _data);
  }

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @param _key unique bytes32 key for accessing the written data (can only be used once)
    @return pointer Pointer to the written `_data`
  */
  function write(bytes32 _key, bytes memory _data)
    internal
    returns (address pointer)
  {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(hex'00', _data)
    );

    // Deploy contract using create3
    pointer = Create3.create3(internalKey(_key), code);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key string key that constains the data
    @return data read from contract associated with `_key`
  */
  function read(string memory _key) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)));
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key string key that constains the data
    @param _start number of bytes to skip
    @return data read from contract associated with `_key`
  */
  function read(string memory _key, uint256 _start)
    internal
    view
    returns (bytes memory)
  {
    return read(keccak256(bytes(_key)), _start);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key string key that constains the data
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from contract associated with `_key`
  */
  function read(
    string memory _key,
    uint256 _start,
    uint256 _end
  ) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start, _end);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key bytes32 key that constains the data
    @return data read from contract associated with `_key`
  */
  function read(bytes32 _key) internal view returns (bytes memory) {
    return
      Bytecode.codeAt(
        Create3.addressOf(internalKey(_key)),
        1,
        type(uint256).max
      );
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key bytes32 key that constains the data
    @param _start number of bytes to skip
    @return data read from contract associated with `_key`
  */
  function read(bytes32 _key, uint256 _start)
    internal
    view
    returns (bytes memory)
  {
    return
      Bytecode.codeAt(
        Create3.addressOf(internalKey(_key)),
        _start + 1,
        type(uint256).max
      );
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key bytes32 key that constains the data
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from contract associated with `_key`
  */
  function read(
    bytes32 _key,
    uint256 _start,
    uint256 _end
  ) internal view returns (bytes memory) {
    return
      Bytecode.codeAt(
        Create3.addressOf(internalKey(_key)),
        _start + 1,
        _end + 1
      );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract SigmoidThreshold {
  using SafeMath for uint256;
  using SafeMath for uint64;

  struct CurveParams {
    uint256 _x;
    uint256 minX;
    uint256 maxX;
    uint256 minY;
    uint256 maxY;
  }

  uint256[23] private slots;

  constructor() {
    slots[0] = 1000000000000000000;
    slots[1] = 994907149075715143;
    slots[2] = 988513057369406817;
    slots[3] = 982013790037908452;
    slots[4] = 970687769248643639;
    slots[5] = 952574126822433143;
    slots[6] = 924141819978756551;
    slots[7] = 880797077977882314;
    slots[8] = 817574476193643651;
    slots[9] = 731058578630004896;
    slots[10] = 622459331201854593;
    slots[11] = 500000000000000000;
    slots[12] = 377540668798145407;
    slots[13] = 268941421369995104;
    slots[14] = 182425523806356349;
    slots[15] = 119202922022117574;
    slots[16] = 75858180021243560;
    slots[17] = 47425873177566788;
    slots[18] = 29312230751356326;
    slots[19] = 17986209962091562;
    slots[20] = 11486942630593183;
    slots[21] = 5092850924284857;
    slots[22] = 0;
  }

  function getY(CurveParams memory config) public view returns (uint256) {
    if (config._x <= config.minX) {
      return config.minY;
    }
    if (config._x >= config.maxX) {
      return config.maxY;
    }

    uint256 slotWidth = config.maxX.sub(config.minX).div(slots.length);
    uint256 xa = config._x.sub(config.minX).div(slotWidth);
    uint256 xb = Math.min(xa.add(1), slots.length.sub(1));

    uint256 slope = slots[xa].sub(slots[xb]).mul(1e18).div(slotWidth);
    uint256 wy = slots[xa].add(slope.mul(slotWidth.mul(xa)).div(1e18));

    uint256 percentage = 0;
    if (wy > slope.mul(config._x).div(1e18)) {
      percentage = wy.sub(slope.mul(config._x).div(1e18));
    } else {
      percentage = slope.mul(config._x).div(1e18).sub(wy);
    }

    uint256 result = config.minY.add(
      config.maxY.sub(config.minY).mul(percentage).div(1e18)
    );

    return config.maxY.sub(result); // inverse curve to be LOW => HIGH
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './RendererPropsStorage.sol';
import './ChunkedDataStorage.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract RarityCompositingEngine is Ownable {
  uint256 public constant MAX_UINT_16 = 0xFFFF;
  uint256 public constant RARITY_DATA_TUPLE_NUM_BYTES = 4;

  address public immutable COMPOSITING_RENDERER;
  address public immutable ATTRIBUTE_RENDERER;
  uint256 public immutable MAX_LAYERS;
  bytes public GLOBAL_ATTRIBUTE_PREFIX;

  // storage contracts
  RendererPropsStorage public rendererPropsStorage;
  ChunkedDataStorage public layerStorage;
  ChunkedDataStorage public attributeStorage;

  uint256 constant NUM_DECIMALS = 2; // units are in bps
  uint256 constant ONE_UNIT = 10**NUM_DECIMALS; // represents 0.01x
  uint256 constant ONE_HUNDRED_PERCENT = 100 * ONE_UNIT; // represents 1.00x

  struct LayerData {
    uint8 layerType;
    bytes rarityData;
  }

  struct AttributeData {
    bool shouldShowInAttributes;
    bool shouldShowInRendererProps;
    uint16 rendererDataIndex;
    string key;
    string value;
    bytes prefix;
  }

  constructor(
    uint256 _maxLayers,
    address _compositingRenderer,
    address _attributeRenderer,
    bytes memory _globalAttributePrefix,
    address _rendererPropsStorage,
    address _layerStorage,
    address _attributeStorage
  ) {
    MAX_LAYERS = _maxLayers;
    COMPOSITING_RENDERER = _compositingRenderer;
    ATTRIBUTE_RENDERER = _attributeRenderer;
    GLOBAL_ATTRIBUTE_PREFIX = _globalAttributePrefix;
    rendererPropsStorage = RendererPropsStorage(_rendererPropsStorage);
    layerStorage = ChunkedDataStorage(_layerStorage);
    attributeStorage = ChunkedDataStorage(_attributeStorage);
  }

  function setRendererPropsStorage(address _rendererPropsStorage)
    public
    onlyOwner
  {
    rendererPropsStorage = RendererPropsStorage(_rendererPropsStorage);
  }

  function setLayerStorage(address _layerStorage) public onlyOwner {
    layerStorage = ChunkedDataStorage(_layerStorage);
  }

  function setAttributeStorage(address _attributeStorage) public onlyOwner {
    attributeStorage = ChunkedDataStorage(_attributeStorage);
  }

  function decodeLayerData(bytes memory data)
    public
    pure
    returns (LayerData memory ld)
  {
    if (data.length != 0) {
      ld.layerType = uint8(data[0]);
      ld.rarityData = BytesUtils.slice(data, 1, data.length - 1);
    }
  }

  function decodeAttributeData(bytes memory data)
    public
    pure
    returns (AttributeData memory ad)
  {
    if (data.length != 0) {
      ad.shouldShowInAttributes = uint8(data[0]) == 1;
      ad.shouldShowInRendererProps = uint8(data[1]) == 1;
      ad.rendererDataIndex = BytesUtils.toUint16(data, 2);
      uint8 keyLength = uint8(data[4]);
      ad.key = string(BytesUtils.slice(data, 5, keyLength));
      uint8 valueLength = uint8(data[5 + keyLength]);
      ad.value = string(BytesUtils.slice(data, 6 + keyLength, valueLength));
      ad.prefix = BytesUtils.slice(
        data,
        6 + keyLength + valueLength,
        data.length - (6 + keyLength + valueLength)
      );
    }
  }

  function resolveLayerIndex(
    uint16[] memory attributeIndexes,
    uint256 layerIndex
  ) public view returns (uint256) {
    require(
      layerIndex != 0,
      'RarityCompositingEngine: layerIndex can not be zero'
    );
    LayerData memory layerData = decodeLayerData(
      layerStorage.indexToData(layerIndex)
    );
    if (layerData.layerType == 1) {
      uint16 rootAttributeIndex = attributeIndexes[
        BytesUtils.toUint16(layerData.rarityData, 0)
      ];
      require(
        rootAttributeIndex != 0,
        'RarityCompositingEngine: Root attribute has not been set yet'
      );
      uint256 dependentLayerIndex = 0;
      for (uint256 j = 2; j < layerData.rarityData.length; j += 4) {
        if (
          BytesUtils.toUint16(layerData.rarityData, j) == rootAttributeIndex
        ) {
          dependentLayerIndex = BytesUtils.toUint16(
            layerData.rarityData,
            j + 2
          );
          break;
        }
      }
      require(
        dependentLayerIndex != 0,
        'RarityCompositingEngine: No dependent layerIndex was found'
      );
      return resolveLayerIndex(attributeIndexes, dependentLayerIndex);
    } else if (layerData.layerType == 0) {
      return layerIndex;
    }
    return 0;
  }

  function applyRarityMultiplier(
    uint256 rarityMultiplier,
    uint256[] memory rarityData
  )
    public
    pure
    returns (
      uint256 appliedRaritySum,
      uint256[] memory appliedRarityData,
      uint256[] memory rarityMultipliers
    )
  {
    rarityMultipliers = new uint256[](rarityData.length);

    if (rarityData.length == 0) {
      return (0, rarityData, rarityMultipliers);
    }

    if (rarityData.length == 2) {
      return (rarityData[1], rarityData, rarityMultipliers);
    }

    // sum the current rarity values
    uint256 highestRarityWeight = rarityData[1];
    uint256 lowestRarityWeight = rarityData[rarityData.length - 1];

    if (highestRarityWeight - lowestRarityWeight == 0) {
      for (uint256 i = 1; i < rarityData.length; i += 2) {
        appliedRaritySum += rarityData[i];
      }
      return (appliedRaritySum, rarityData, rarityMultipliers);
    }

    appliedRarityData = rarityData;

    uint256 a = (rarityMultiplier * ONE_UNIT) /
      ((highestRarityWeight - lowestRarityWeight)**2);

    for (uint256 i = 1; i < rarityData.length; i += 2) {
      uint256 scaledRarityMultiplier = (a *
        (highestRarityWeight - rarityData[i])**2) / ONE_UNIT;
      uint256 appliedRarity = ((ONE_HUNDRED_PERCENT + scaledRarityMultiplier) *
        rarityData[i]) / ONE_UNIT;
      rarityMultipliers[i] = scaledRarityMultiplier;
      appliedRarityData[i] = appliedRarity;
      appliedRaritySum += appliedRarityData[i];
    }
  }

  function getRarity(uint256 rarityMultiplier, bytes memory seed)
    public
    view
    returns (uint256[] memory layerIndexes, uint16[] memory attributeIndexes)
  {
    // attributeIndexes are the keys to the actual visual output data for a specific layer index
    attributeIndexes = new uint16[](MAX_LAYERS);

    // layerIndexes are the keys to the actual layer and its corresponding rarity data
    layerIndexes = new uint256[](MAX_LAYERS);
    // set default layer indexes
    for (uint16 i = 0; i < MAX_LAYERS; ++i) {
      layerIndexes[i] = i + 1;
    }

    for (uint16 i = 0; i < MAX_LAYERS; ++i) {
      layerIndexes[i] = resolveLayerIndex(attributeIndexes, layerIndexes[i]);
      LayerData memory layerData = decodeLayerData(
        layerStorage.indexToData(layerIndexes[i])
      );
      uint256 randomSource = uint256(keccak256(abi.encodePacked(seed, i)));

      uint256[] memory rarityData = new uint256[](
        (layerData.rarityData.length) / 2
      );
      for (uint256 j = 0; j < layerData.rarityData.length; j += 2) {
        rarityData[j / 2] = BytesUtils.toUint16(layerData.rarityData, j);
      }

      (
        uint256 appliedRaritySum,
        uint256[] memory appliedRarityData,

      ) = applyRarityMultiplier(rarityMultiplier, rarityData);
      // get attribute for this layer
      uint16 attributeIndex = 0;
      uint256 rarityValue = randomSource % appliedRaritySum;
      uint256 acc = 0;
      for (uint256 j = 1; j < appliedRarityData.length; j += 2) {
        acc += appliedRarityData[j];
        if (acc >= rarityValue) {
          attributeIndex = uint16(appliedRarityData[j - 1]);
          break;
        }
      }
      require(
        attributeIndex != 0,
        'RarityCompositingEngine: No attribute was found for layer.'
      );
      attributeIndexes[i] = attributeIndex;
    }
  }

  function getRendererProps(uint16[] memory attributeIndexes)
    public
    view
    returns (address[] memory renderers, bytes[] memory rendererProps)
  {
    uint256 numNonrendereredAttributes = 0;
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      AttributeData memory ad = decodeAttributeData(
        attributeStorage.indexToData(attributeIndexes[i])
      );
      if (!ad.shouldShowInRendererProps) {
        numNonrendereredAttributes++;
      }
    }

    renderers = new address[](
      attributeIndexes.length - numNonrendereredAttributes
    );
    rendererProps = new bytes[](
      attributeIndexes.length - numNonrendereredAttributes
    );

    uint256 numRenderersStored = 0;
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      AttributeData memory ad = decodeAttributeData(
        attributeStorage.indexToData(attributeIndexes[i])
      );
      if (ad.shouldShowInRendererProps) {
        uint256 rendererIndex = attributeIndexes.length -
          numNonrendereredAttributes -
          1 -
          numRenderersStored;
        renderers[rendererIndex] = ATTRIBUTE_RENDERER;
        rendererProps[rendererIndex] = abi.encodePacked(
          GLOBAL_ATTRIBUTE_PREFIX,
          ad.prefix,
          rendererPropsStorage.indexToRendererProps(ad.rendererDataIndex)
        );
        numRenderersStored++;
      }
    }
  }

  function getAttributesJSON(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    bytes memory attributes = '[';
    for (uint256 i = 0; i < attributeIndexes.length; ++i) {
      AttributeData memory ad = decodeAttributeData(
        attributeStorage.indexToData(attributeIndexes[i])
      );
      if (ad.shouldShowInAttributes) {
        attributes = abi.encodePacked(
          attributes,
          (attributes.length == 1) ? '' : ',',
          '{"value":"',
          ad.value,
          '","trait_type":"',
          ad.key,
          '"}'
        );
      }
    }
    attributes = abi.encodePacked(attributes, ']');
    return string(attributes);
  }

  function getRender(uint16[] memory attributeIndexes)
    public
    view
    returns (string memory)
  {
    LayerCompositeRenderer renderer = LayerCompositeRenderer(
      COMPOSITING_RENDERER
    );
    (
      address[] memory renderers,
      bytes[] memory rendererProps
    ) = getRendererProps(attributeIndexes);
    return renderer.render(renderer.encodeProps(renderers, rendererProps));
  }

  function getRenderRaw(uint16[] memory attributeIndexes)
    public
    view
    returns (bytes memory)
  {
    LayerCompositeRenderer renderer = LayerCompositeRenderer(
      COMPOSITING_RENDERER
    );
    (
      address[] memory renderers,
      bytes[] memory rendererProps
    ) = getRendererProps(attributeIndexes);
    return renderer.renderRaw(renderer.encodeProps(renderers, rendererProps));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address
  0x67363d3d37363d34f03d5260086018f3:
      0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
      0x02  0x52  0x52                  MSTORE
      0x03  0x60  0x6008                PUSH1 08        8
      0x04  0x60  0x6018                PUSH1 18        24 8
      0x05  0xf3  0xf3                  RETURN
  0x363d3d37363d34f0:
      0x00  0x36  0x36                  CALLDATASIZE    cds
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                  CALLDATACOPY
      0x04  0x36  0x36                  CALLDATASIZE    cds
      0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x06  0x34  0x34                  CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                  CREATE          addr
  */

  bytes internal constant PROXY_CHILD_BYTECODE =
    hex'67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3';

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE =
    0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly {
      size := extcodesize(_addr)
    }
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode)
    internal
    returns (address addr)
  {
    return create3(_salt, _creationCode, 0);
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @param _value In WEI of ETH to be forwarded to child contract
    @return addr of the deployed contract, reverts on error
  */
  function create3(
    bytes32 _salt,
    bytes memory _creationCode,
    uint256 _value
  ) internal returns (address addr) {
    // Creation code
    bytes memory creationCode = PROXY_CHILD_BYTECODE;

    // Get target final address
    addr = addressOf(_salt);
    if (codeSize(addr) != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    address proxy;
    assembly {
      proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)
    }
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    (bool success, ) = proxy.call{value: _value}(_creationCode);
    if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
  }

  /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error
    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return
      address(
        uint160(
          uint256(keccak256(abi.encodePacked(hex'd6_94', proxy, hex'01')))
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code)
    internal
    pure
    returns (bytes memory)
  {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return
      abi.encodePacked(
        hex'63',
        uint32(_code.length),
        hex'80_60_0E_60_00_39_60_00_F3',
        _code
      );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly {
      size := extcodesize(_addr)
    }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode
    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(
    address _addr,
    uint256 _start,
    uint256 _end
  ) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes('');

    if (_start > csize) return bytes('');
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './libraries/SSTORE2Map.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/renderers/LayerCompositeRenderer.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract RendererPropsStorage is Ownable {
  uint256 public constant MAX_UINT_16 = 0xFFFF;

  // index starts from zero, useful to use the 0th index as a empty case.
  uint16 public currentMaxRendererPropsIndex = 0;

  constructor() {}

  function batchAddRendererProps(bytes[] calldata rendererProps)
    public
    onlyOwner
  {
    for (uint16 i = 0; i < rendererProps.length; ++i) {
      SSTORE2Map.write(
        bytes32(uint256(currentMaxRendererPropsIndex + i)),
        rendererProps[i]
      );
    }
    currentMaxRendererPropsIndex += uint16(rendererProps.length);
    require(
      currentMaxRendererPropsIndex <= MAX_UINT_16,
      'RendererPropsStorage: Exceeds storage limit'
    );
  }

  function indexToRendererProps(uint16 index)
    public
    view
    returns (bytes memory)
  {
    return SSTORE2Map.read(bytes32(uint256(index)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import './libraries/SSTORE2Map.sol';

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@abf-monorepo/protocol/contracts/libraries/BytesUtils.sol';

contract ChunkedDataStorage is Ownable {
  uint256 public constant MAX_UINT_16 = 0xFFFF;

  mapping(uint256 => uint256) public numLayerDataInChunk;

  uint256 public currentMaxChunksIndex = 0;

  constructor() {}

  function batchAddChunkedData(bytes[] calldata data) public onlyOwner {
    numLayerDataInChunk[currentMaxChunksIndex] = data.length;

    bytes memory chunkedLayerData = '';

    for (uint256 i = 0; i < data.length; ++i) {
      require(
        data[i].length <= MAX_UINT_16,
        'ChunkedDataStorage: data exceeds size of 0xFFFF'
      );
      chunkedLayerData = abi.encodePacked(
        chunkedLayerData,
        uint16(data[i].length),
        data[i]
      );
    }
    SSTORE2Map.write(bytes32(currentMaxChunksIndex), chunkedLayerData);
    currentMaxChunksIndex++;
  }

  function indexToData(uint256 index) public view returns (bytes memory) {
    uint256 currentChunkIndex = 0;
    uint256 currentIndex = 0;
    do {
      currentIndex += numLayerDataInChunk[currentChunkIndex];
      currentChunkIndex++;
      if (numLayerDataInChunk[currentChunkIndex] == 0) {
        break;
      }
    } while (currentIndex <= index);
    currentChunkIndex--;
    currentIndex -= numLayerDataInChunk[currentChunkIndex];
    uint256 localChunkIndex = index - currentIndex;
    bytes memory chunkedData = SSTORE2Map.read(bytes32(currentChunkIndex));
    uint256 localChunkIndexPointer = 0;
    for (uint256 i = 0; i < chunkedData.length; i += 0) {
      if (localChunkIndexPointer == localChunkIndex) {
        return
          BytesUtils.slice(
            chunkedData,
            i + 2,
            BytesUtils.toUint16(chunkedData, i)
          );
      }
      i += BytesUtils.toUint16(chunkedData, i) + 2;
      localChunkIndexPointer++;
    }

    return '';
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "../interfaces/IRenderer.sol";
import "../libraries/BytesUtils.sol";
import "../libraries/SvgUtils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/utils/Base64.sol";

contract LayerCompositeRenderer is IRenderer, Ownable, ERC165 {
  using Strings for uint256;

  function owner() public override(Ownable, IRenderer) view returns (address) {
    return super.owner();
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IRenderer).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function propsSize() external override pure returns (uint256) {
    return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
  }
  function additionalMetadataURI() external override pure returns (string memory) {
    return "ipfs://bafkreigjwztwrolwcbkbz3ombzkvxg2767bckeobrfwdjfohvxgozbepv4";
  }
  
  function renderAttributeKey() external override pure returns (string memory) {
    return "image";
  }
  
  function name() public override pure returns (string memory) {
    return 'Layer Composite';
  }

  function encodeProps(address[] memory renderers, bytes[] memory rendererProps) public pure returns (bytes memory output) {
    for (uint i = 0; i < renderers.length; ++i) {
      output = abi.encodePacked(output, renderers[i], rendererProps[i].length, rendererProps[i]);
    }
  }

  function renderRaw(bytes calldata props) public override view returns (bytes memory) {
    bytes memory backgroundImages;

    for (uint i = 0; i < props.length; i += 0) {
      IRenderer destinationRenderer = IRenderer(BytesUtils.toAddress(props, i));
      uint start = i + 20 + 32;
      uint end = start + BytesUtils.toUint256(props, i + 20); 
      backgroundImages = abi.encodePacked(backgroundImages, i == 0  ? '' : ',', 'url(', 
      destinationRenderer.render(props[start:end])
      ,')');
      i = end;
    }

    return abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="1200" style="',
      'background-image:', backgroundImages, ';background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;">',
      '</svg>'
    );
  }

  function render(bytes calldata props) external override view returns (string memory) {
        return string(
      abi.encodePacked(
        'data:image/svg+xml;base64,',
        Base64.encode(renderRaw(props)) 
      )
    );
  }

  function attributes(bytes calldata) external override pure returns (string memory) {
    return ""; 
  }
}

// SPDX-License-Identifier: MIT
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity ^0.8.4;

library BytesUtils {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IRenderer is IERC165 {
  function name() external view returns (string memory);
  function owner() external view returns (address);
  function propsSize() external view returns (uint256);
  function additionalMetadataURI() external view returns (string memory);
  function renderAttributeKey() external view returns (string memory);
  function renderRaw(bytes calldata props) external view returns (bytes memory);
  function render(bytes calldata props) external view returns (string memory);
  function attributes(bytes calldata props) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";

library SvgUtils {
  using Strings for uint256;

  uint public constant DECIMALS = 4;
  uint public constant ONE_UNIT = 10 ** DECIMALS;

  function padZeros(string memory s, uint len) public pure returns (string memory) {
    uint local_len = bytes(s).length;
    string memory local_s = s;
    while(local_len < len) {
      local_s = string(abi.encodePacked('0', local_s));
      local_len++;
    }
    return local_s;
  }

  function wholeNumber(uint n) public pure returns (uint) {
    return n / ONE_UNIT;
  }

  function decimals(uint n) public pure returns (uint) {
    return n % ONE_UNIT;
  }

  function toDecimalString(uint n) public pure returns (string memory s) {
    if (n == 0) return '0';

    s = string(abi.encodePacked(
      (n / (ONE_UNIT)).toString(), '.' , padZeros((n % ONE_UNIT).toString(), DECIMALS)
    ));
  }

  function lerpWithDecimals(uint min, uint max, bytes1 scale) public pure returns (uint) {
    if (scale == 0x0) return min * ONE_UNIT;
    if (scale == 0xff) return max * ONE_UNIT;
    uint delta = ((max - min) * ONE_UNIT * uint(uint8(scale))) / 255; 
    return (min * ONE_UNIT) + delta;
  }

  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

  function toColorHexString(uint256 value) public pure returns (string memory) {
      bytes memory buffer = new bytes(2 * 3 + 1);
      buffer[0] = "#";
      for (uint256 i = 2 * 3; i > 0; --i) {
          buffer[i] = _HEX_SYMBOLS[value & 0xf];
          value >>= 4;
      }
      require(value == 0, "Strings: hex length insufficient");
      return string(buffer);
  }

  function toColorHexStringByBytes(bytes1 r, bytes1 g, bytes1 b) public pure returns (string memory) {
    bytes memory buffer = new bytes(7);
    buffer[0] = "#";
    buffer[2] = _HEX_SYMBOLS[uint8(r) & 0xf];
    r >>= 4;
    buffer[1] = _HEX_SYMBOLS[uint8(r) & 0xf];
    buffer[4] = _HEX_SYMBOLS[uint8(g) & 0xf];
    g >>= 4;
    buffer[3] = _HEX_SYMBOLS[uint8(g) & 0xf];
    buffer[6] = _HEX_SYMBOLS[uint8(b) & 0xf];
    b >>= 4;
    buffer[5] = _HEX_SYMBOLS[uint8(b) & 0xf];
    return string(buffer);
  }
  
  function toColorHexStringByBytes3(bytes3 rgb) public pure returns (string memory) {
    return toColorHexStringByBytes(rgb[0], rgb[1], rgb[2]);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}