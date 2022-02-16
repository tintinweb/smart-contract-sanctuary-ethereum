// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Ownable.sol";
import "./Address.sol";
import "./ECDSA.sol";
import "./SafeCast.sol";
import "./ERC721.sol";
import "./TheTreasury.sol";
import "./ERC2981.sol";

contract CryptoQueenz is Ownable, ERC721, ERC2981, TheTreasury {
  using Address for address;
  using SafeCast for uint256;
  using ECDSA for bytes32;

  // EVENTS ****************************************************
  event StartingIndexSet(uint256 _value);
  event PresaleConfigUpdated();
  event DutchAuctionConfigUpdated();
  event ProvenanceHashUpdated(uint256 _hash);
  event WhitelistSignerUpdated(address _signer);
  event BaseUriUpdated(string _uri);

  // MEMBERS ****************************************************

struct PresaleConfig {
  uint32 startTime;
  uint32 endTime;
  uint32 supplyLimit;
  uint256 mintPrice;
}

struct DutchAuctionConfig {
  uint32 txLimit;
  uint32 startTime;
  uint32 bottomTime;
  uint32 stepInterval;
  uint256 startPrice;
  uint256 bottomPrice;
  uint256 priceStep;
}

  PresaleConfig public presaleConfig;
  DutchAuctionConfig public dutchAuctionConfig;

  uint256 public constant MAX_OWNER_RESERVE = 100;
  uint256 public constant CRYPTO_QUEENZ_SUPPLY = 9900;

  uint256 public totalSupply = 0;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;


  string public baseURI;
  address public whitelistSigner;

  uint256 public PROVENANCE_HASH;
  uint256 public randomizedStartIndex;

  mapping(address => uint256) private presaleMinted;
  mapping(address => uint256) private presaleMintedFree;

  bytes32 private DOMAIN_SEPARATOR;
  bytes32 private constant PRESALE_TYPEHASH =
    keccak256("presale(address buyer,uint256 limit)");

  bytes32 private constant FREEMINT_TYPEHASH =
    keccak256("freeMint(address buyer,uint256 limit)");

  address[] private mintPayees = [
    0xFD1da21BC769C37E3D445AA0A4D428a496E46Fb2, //Boy Account2
    0x8218Af9ea6B3F9FC6d3987aC9755bD96eF2534d3, //Boy2 Account3
    0x74E1aed0e0603DaaC6A49A0F8ED6EE0209f3Fe6f //Dev Account4
  ];

  uint256[] private mintShares = [50, 45, 5];

  TheTreasury public royaltyRecipient;

  // CONSTRUCTOR **************************************************

  constructor(string memory initialBaseUri)
    ERC721("CryptoQueenz by Boy George", "QUEENZ")
    TheTreasury(mintPayees, mintShares)
    {
    baseURI = initialBaseUri;

    presaleConfig = PresaleConfig({
      startTime: 1644916078, // Tuesday, 15 February 2022
      endTime: 1645348073, // Sunday, 20 February 2022 09:07:53
      supplyLimit: 8000,
      mintPrice: 0.00088 ether
    });

    dutchAuctionConfig = DutchAuctionConfig({
      txLimit: 3,
      startTime: 1644916078, // Tuesday, 15 February 2022
      bottomTime: 1645348073, // Sunday, 20 February 2022 09:07:53
      stepInterval: 600, // 1 minute
      startPrice: 0.001 ether,
      bottomPrice: 0.0001 ether,
      priceStep: 0.00005 ether
    });

    address[] memory royaltyPayees = new address[](2);
    royaltyPayees[0] = 0xFD1da21BC769C37E3D445AA0A4D428a496E46Fb2; //Boy  Account2
    royaltyPayees[1] = 0x8218Af9ea6B3F9FC6d3987aC9755bD96eF2534d3; //Boy2 Account3

    uint256[] memory royaltyShares = new uint256[](2);
    royaltyShares[0] = 70;
    royaltyShares[1] = 30;
    
    royaltyRecipient = new TheTreasury(royaltyPayees, royaltyShares);

    _setRoyalties(address(royaltyRecipient), 750); // 7.5% royalties

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256(
          "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        ),
        keccak256(bytes("CryptoQueenz")),
        keccak256(bytes("1")),
        chainId,
        address(this)
      )
    );
  }

  // PUBLIC METHODS ****************************************************
  /// @notice Allows users to buy during presale, only whitelisted addresses may call this function.
  ///         Whitelisting is enforced by requiring a signature from the whitelistSigner address
  /// @dev Whitelist signing is performed off chain, via the CryptoQueenz website backend
  /// @param signature signed data authenticating the validity of this transaction
  /// @param numberOfTokens number of NFTs to buy
  /// @param approvedLimit the total number of NFTs this address is permitted to buy during presale, this number is also encoded in the signature
  function buyPresale(
    bytes calldata signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable{

    PresaleConfig memory _config = presaleConfig; 

    require(block.timestamp >= _config.startTime && block.timestamp < _config.endTime,"Presale not active");    
    require(whitelistSigner != address(0), "Whitelist signer has not set");
    require((totalSupply + numberOfTokens) <= _config.supplyLimit,"Not enough remaining");
    require(msg.value == (_config.mintPrice * numberOfTokens),"Incorrect payment");
    require((presaleMinted[msg.sender] + numberOfTokens) <= approvedLimit,"Mint limit exceeded");
   
    presaleMinted[msg.sender] = presaleMinted[msg.sender] + numberOfTokens;

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(PRESALE_TYPEHASH, msg.sender, approvedLimit))
      )
    );
    
    address signer = digest.recover(signature);
    require(signer != address(0) && signer == whitelistSigner,"Invalid signature");

    mint(msg.sender, numberOfTokens);
  }

  /// @notice Allows users to buy during presale for free, only whitelisted addresses may call this function.
  ///         Whitelisting is enforced by requiring a signature from the whitelistSigner address
  /// @dev Whitelist signing is performed off chain, via the CryptoQueenz website backend
  /// @param signature signed data authenticating the validity of this transaction
  /// @param numberOfTokens number of NFTs to buy
  /// @param approvedLimit the total number of NFTs this address is permitted to buy during presale, this number is also encoded in the signature
  
  function buyPresaleFree(
    bytes calldata signature,
    uint256 numberOfTokens,
    uint256 approvedLimit
  ) external payable{

    PresaleConfig memory _config = presaleConfig;

    require(block.timestamp >= _config.startTime && block.timestamp < _config.endTime,"Presale not active");
    require(whitelistSigner != address(0), "Whitelist signer has not set");
    require((totalSupply + numberOfTokens) <= _config.supplyLimit,"Not enough remaining");
    require((presaleMintedFree[msg.sender] + numberOfTokens) <= approvedLimit,"Mint limit exceeded");

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(FREEMINT_TYPEHASH, msg.sender, approvedLimit))
      )
    );

    presaleMintedFree[msg.sender] = presaleMintedFree[msg.sender] + numberOfTokens;

    address signer = digest.recover(signature);
    require(signer != address(0) && signer == whitelistSigner,"Invalid signature");

    mint(msg.sender, numberOfTokens);

  }

  /// @notice Allows users to buy during public sale, pricing follows a dutch auction format
  /// @dev Preventing contract buys has some downsides, but it seems to be what the NFT market generally wants as a bot mitigation measure
  /// @param numberOfTokens the number of NFTs to buy
  function buyPublic(uint256 numberOfTokens) external payable {
    // disallow contracts from buying
    require(
      (!msg.sender.isContract() && msg.sender == tx.origin),
      "Contract buys not allowed"
    );

    DutchAuctionConfig memory _config = dutchAuctionConfig;

    require(
      (totalSupply + numberOfTokens) <= CRYPTO_QUEENZ_SUPPLY,
      "Not enough remaining"
    );
    require(block.timestamp >= _config.startTime, "Sale not active");
    require(numberOfTokens <= _config.txLimit, "Tx limit exceeded");

    uint256 mintPrice = getCurrentAuctionPrice() * numberOfTokens;
    require(msg.value >= mintPrice, "Insufficient payment");

    // refund if customer paid more than the cost to mint
    if (msg.value > mintPrice) {
      Address.sendValue(payable(msg.sender), msg.value - mintPrice);
    }

    mint(msg.sender, numberOfTokens);
  }

  /// @notice Gets an array of tokenIds owned by a wallet
  /// @param wallet wallet address to query contents for
  /// @return an array of tokenIds owned by wallett
  function tokensOwnedBy(address wallet)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for (uint256 i = 0; i < tokenCount; i++) {
      ownedTokenIds[i] = _ownedTokens[wallet][i];
    }

    return ownedTokenIds;
  }

  /// @inheritdoc ERC165
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  //Returns the number of remaining tokens available for mint
  function totalMinted() view external returns(uint256){
    return CRYPTO_QUEENZ_SUPPLY - totalSupply;
  }

  

  // OWNER METHODS *********************************************************

  /// @notice Allows the contract owner to update start and end time for the presale
  function configurePresale(uint256 startTime, uint256 endTime)
    external
    onlyOwner
  {
    uint32 _startTime = startTime.toUint32();
    uint32 _endTime = endTime.toUint32();

    require(0 < _startTime, "Invalid time");
    require(_startTime < _endTime, "Invalid time");
    require(_endTime <= dutchAuctionConfig.startTime, "Invalid time");

    presaleConfig.startTime = _startTime;
    presaleConfig.endTime = _endTime;

    emit PresaleConfigUpdated();
  }

  /// @notice Allows the contract owner to update config for the public dutch auction
  function configureDutchAuction(
    uint256 startTime,
    uint256 bottomTime,
    uint256 stepInterval,
    uint256 startPrice,
    uint256 bottomPrice,
    uint256 priceStep
  ) external onlyOwner {
    uint32 _startTime = startTime.toUint32();
    uint32 _bottomTime = bottomTime.toUint32();
    uint32 _stepInterval = stepInterval.toUint32();

    require(presaleConfig.endTime <= _startTime, "Invalid time");
    require(_startTime < _bottomTime, "Invalid time");
    require(0 < stepInterval, "0 step interval");
    require(bottomPrice < startPrice, "Invalid start price");
    require(0 < bottomPrice, "Invalid bottom price");
    require(0 < priceStep && priceStep < startPrice, "Invalid price step");

    dutchAuctionConfig.startTime = _startTime;
    dutchAuctionConfig.bottomTime = _bottomTime;
    dutchAuctionConfig.stepInterval = _stepInterval;
    dutchAuctionConfig.startPrice = startPrice;
    dutchAuctionConfig.bottomPrice = bottomPrice;
    dutchAuctionConfig.priceStep = priceStep;

    emit DutchAuctionConfigUpdated();
  }

  /// @notice Gets the current price for the duction auction, based on current block timestamp
  /// @dev Dutch auction parameters configured via dutchAuctionConfig
  /// @return currentPrice Current mint price per NFT
  function getCurrentAuctionPrice() public view returns (uint256 currentPrice) {
    DutchAuctionConfig memory _config = dutchAuctionConfig;

    uint256 timestamp = block.timestamp;
    //TODO after auction ends we will set a fixed price for public sale
    // if(timestamp > _config.bottomTime)
    //   return 0.5 ether;

    if (timestamp < _config.startTime) {
      currentPrice = _config.startPrice;
    } 
    else if (timestamp >= _config.bottomTime) {
      currentPrice = _config.bottomPrice;
    } 
    else {
      uint256 elapsedIntervals = (timestamp - _config.startTime) /_config.stepInterval;

      if(_config.startPrice > (elapsedIntervals * _config.priceStep) && 
      ((_config.startPrice - (elapsedIntervals * _config.priceStep)) >= _config.bottomPrice))
        currentPrice =_config.startPrice - (elapsedIntervals * _config.priceStep);
      else{
        currentPrice = _config.bottomPrice;
      }
    }

    return currentPrice;
  }

  /// @notice Allows the contract owner to reserve NFTs for team members or promotional purposes
  /// @dev This should be called before presale or public sales start, as only the first MAX_OWNER_RESERVE tokens can be reserved
  /// @param to address for the reserved NFTs to be minted to
  /// @param numberOfTokens number of NFTs to reserve
  function reserve(address to, uint256 numberOfTokens) external onlyOwner {
    require(
      (totalSupply + numberOfTokens) <= MAX_OWNER_RESERVE,
      "Exceeds owner reserve limit"
    );

    mint(to, numberOfTokens);
  }

  /// @notice Allows the owner to roll a pseudo-random number once, which will be used as the starting index for the token metadata.
  ///         This is used to prove randomness and fairness in the metadata distribution, in conjunction with the PROVENANCE_HASH
  /// @dev The starting index can only be set once, only after the start of the public sale, and only if the PROVENANCE_HASH has been set
  function rollStartIndex() external onlyOwner {
    require(PROVENANCE_HASH != 0, "Provenance hash not set");
    require(randomizedStartIndex == 0, "Index already set");
    require(
      block.timestamp >= dutchAuctionConfig.startTime,
      "Too early to roll"
    );

    uint256 number = uint256(
      keccak256(
        abi.encodePacked(
          blockhash(block.number - 1),
          block.coinbase,
          block.difficulty,
          block.timestamp
        )
      )
    );

    randomizedStartIndex = (number % CRYPTO_QUEENZ_SUPPLY) + 1;

    emit StartingIndexSet(randomizedStartIndex);
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    emit BaseUriUpdated(newBaseUri);
    baseURI = newBaseUri;
  }

  function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
    emit WhitelistSignerUpdated(newWhitelistSigner);
    whitelistSigner = newWhitelistSigner;
  }

  function setProvenance(uint256 provenanceHash) external onlyOwner {
    require(randomizedStartIndex == 0, "Starting index already set");

    emit ProvenanceHashUpdated(provenanceHash);
    PROVENANCE_HASH = provenanceHash;
  }

  // PRIVATE/INTERNAL METHODS ****************************************************

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function mint(address to, uint256 numberOfTokens) private {
    uint256 newId = totalSupply;

    for (uint256 i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(to, newId);
    }
    totalSupply = newId;
  }

  // ************************************************************************************************************************
  // The following methods are borrowed from OpenZeppelin's ERC721Enumerable contract, to make it easier to query a wallet's
  // contents without incurring the extra storage gas costs of the full ERC721Enumerable extension
  // ************************************************************************************************************************

  /**
   * @dev Private function to add a token to ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = ERC721.balanceOf(to);
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
    private
  {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from != address(0)) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to != address(0)) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }
}