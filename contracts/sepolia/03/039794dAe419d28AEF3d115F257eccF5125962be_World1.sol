/// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import './interfaces/INFTPlatform.sol';
import './interfaces/IVerse.sol';

import 'truffle/Console.sol';

/// @custom:oz-upgrades-unsafe-allow external-library-linking
contract World1 is AccessControlUpgradeable, PausableUpgradeable, ERC721URIStorageUpgradeable {
  // World EVENTS
  event CreateNFT(string indexed _worldId, address indexed _creator, uint256 _nftId, uint256 _price);
  event SellNFT(string indexed _worldId, address indexed _seller, uint256 _nftId, uint256 _price);
  event CancelSellNFT(string indexed _worldId, address indexed _seller, uint256 _nftId);
  event BuyNFT(string indexed _worldId, address indexed _seller, address indexed _buyer, uint256 _nftId, uint256 _sellingPrice);
  event UpdateWorldData(address indexed _sender, string _worldData);
  event UpdatePlatformFees(uint32 platformFeeCreator, uint32 platformFeeSellBuy);
  event UpdateVerseFees(uint32 verseFeeCreator, uint32 verseFeeSellBuy);
  event UpdateWorldFees(uint256 worldFeeCreator, uint32 worldFeeSellBuy);

  // WORLD CONSTANTS
  uint32 public constant PRECISION_DECIMALS = 10 ** 4; // 10_000; 100% = 1 = 1.0000 ; 1%= 0,01 = 100; 0,01% = 0,0001 = 1
  bytes32 public constant DATA_UPDATE_ROLE = keccak256('DATA_UPDATE_ROLE');
  bytes32 public constant NFT_CREATOR_ROLE = keccak256('NFT_CREATOR_ROLE');

  struct MainData {
    address payable platform; // Platform this world is part of 0x0...
    address payable verse; // Verse this world is part part of 0x0...
    string worldId; // e.g. 'World_1'
    string worldData; // https://ipfs.io/world1DataJSON
    bytes32 worldDataHash; // 0x0...
    bool onlyNFTCreatorRole; // true: only NFT_CREATOR_ROLE can create NFTs; false = anybody can create NFTs
    bool updateURIallowed; // true: Token URI update is allowed; false = Update Token URI is not allowed
    uint256 nftIDs; // total amount of NFTs in this world
    mapping(uint256 => Nft) nfts;
  }

  struct Nft {
    uint256 prevPrice;
    uint256 price;
    uint256 sellingPrice;
    address payable creator;
    bytes32 uriHash;
    uint32 creatorFeeRoyalty;
  }

  struct Fees {
    // World fee (in Wei) for creating a new NFT  inside the World paid by creator
    uint256 worldFeeCreator;
    // Verse Fee [%]: a % taken from worldFeeCreator
    uint32 verseFeeCreator; // 0% - 50%
    // Platform Fee [%]: a % taken from worldFeeCreator
    uint32 platformFeeCreator; // 0% - 50%
    // World fee (% of the price difference) when selling (realized when buying)
    uint32 worldFeeSellBuy; // 0% - 50% of price difference between (SellingPrice - Price)
    uint32 verseFeeSellBuy; // 0% - 50% of value of worldFeeSellBuy
    uint32 platformFeeSellBuy; // 0% - 50% of value of worldFeeSellBuy
    // Tracking total accumulated fees that owner can claim
    uint256 totalPlatformFee;
    uint256 totalVerseFee;
    uint256 totalWorldFee;
  }

  MainData private mainData;
  Fees private fees;

  modifier whenNftExists(uint256 _nftID) {
    require(_exists(_nftID), 'UnknownNftId');
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  fallback() external payable {}

  receive() external payable {}

  function initialize(
    string memory _worldId,
    string memory _worldSymbol,
    string memory _worldData,
    address payable _verse,
    address payable _platform,
    bool _onlyNFTCreatorRole,
    bool _updateURIallowed
  ) external initializer {
    __ERC721_init_unchained(_worldId, _worldSymbol);
    __ERC721URIStorage_init_unchained();
    __Pausable_init_unchained();
    __Context_init_unchained();
    __AccessControl_init_unchained();
    _pause();

    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

    _updateWorldData(_worldData);

    mainData.worldId = _worldId;
    mainData.verse = _verse;
    mainData.platform = _platform;
    mainData.onlyNFTCreatorRole = _onlyNFTCreatorRole;
    mainData.updateURIallowed = _updateURIallowed;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
    // return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
    return super.supportsInterface(interfaceId);
  }

  /// @dev Check whether only the wallet with the NFT_CREATOR_ROLE is allowed to create new NFTs or not
  /// @return true: only wallet with the NFT_CREATOR_ROLE is allowed to create new NFTs
  /// false: all wallets are allowed to create new NFTs
  function getOnlyNFTCreatorRole() external view returns (bool) {
    return mainData.onlyNFTCreatorRole;
  }

  /// @dev Check whether the update of the Token URI is allowed by the NFT (true) or not (false)
  /// @return true: the update of the Token URI is allowed
  /// false: update of the Token URI is not allowed
  function getUpdateURIallowed() external view returns (bool) {
    return mainData.updateURIallowed;
  }

  /// @dev Get the unique identifier to the World JSON data file (e.g. "https://uniknft.de/data/worldDataJSON" in IPFS)
  /// @return Unique identifier to the JSON data file including the world data
  /// @return a unique hash that can be used to prove that the link to JSON data file is correct
  function getWorldData() external view returns (string memory, bytes32) {
    return (mainData.worldData, mainData.worldDataHash);
  }

  /// @dev Update the unique identifier to the World JSON data file
  /// @param _worldData unique identifier to the World JSON data file
  function updateWorldData(string memory _worldData) external onlyRole(DATA_UPDATE_ROLE) {
    _updateWorldData(_worldData);
  }

  function _updateWorldData(string memory _worldData) private {
    mainData.worldData = _worldData;
    mainData.worldDataHash = keccak256(abi.encodePacked(mainData.worldData));
    emit UpdateWorldData(msg.sender, _worldData);
  }

  /// @dev NFT owner can update the TokenURI of the NFT.
  /// Although this is normally not allowed, in this world it's a feature
  /// @param _tokenId the NFT id for which to update the token URI
  /// @param _tokenURI the new token URI
  function setTokenURI(uint256 _tokenId, string memory _tokenURI) external {
    require(mainData.updateURIallowed, 'UpdateURInotAllowed');
    require(_exists(_tokenId), 'UnknownNftId');
    require(msg.sender == ownerOf(_tokenId), 'OnlyNFTowner');

    mainData.nfts[_tokenId].uriHash = keccak256(abi.encodePacked(_tokenURI));
    _setTokenURI(_tokenId, _tokenURI);
  }

  /// @dev Get the type of this world contract
  /// different world contracts have different feature sets. required to chose the correct world contract ABI
  /// @return The type of this world contract ('World1','World2','World3',etc..)
  function getWorldType() external pure returns (string memory) {
    return 'World1';
  }

  /// @dev Get the unique World ID of this World contract
  function getWorldId() external view returns (string memory) {
    return mainData.worldId;
  }

  /// @dev Get the address of the Verse in which this World is registered
  /// @return The address of the Verse
  function getVerse() external view returns (address) {
    return mainData.verse;
  }

  /// @dev Get the address of the NFT platform in which this World (via the Verse) is registered
  /// @return The address of the NFT platform
  function getPlatform() external view returns (address) {
    return mainData.platform;
  }

  /// @dev Get the amount of NFTs registered in this world contract
  /// @return amount of registered NFTs
  function getNftCount() external view returns (uint256) {
    return mainData.nftIDs;
  }

  /// @dev Get NFT Data
  /// @param _nftId the unique NFT id for which to get the data from
  /// @return an array including the following items:
  /// uint256 prevPrice;
  /// uint256 price;
  /// uint256 sellingPrice;
  /// address payable creator;
  /// uint32 creatorFeeRoyalty;
  /// bytes32 uriHash;
  function getNft(uint256 _nftId) public view whenNftExists(_nftId) returns (Nft memory) {
    return mainData.nfts[_nftId];
  }

  /// @dev Get the fees for creating, selling, cancel selling and buying an NFT of this world
  /// @return array of all the fees
  function getFees() public view returns (Fees memory) {
    return fees;
  }

  function createNFT(uint256 _nftItemPriceWei, uint32 _creatorFeeRoyaltyPercentage, string memory _tokenURI) external payable whenNotPaused {
    require(_nftItemPriceWei != 0, 'ZeroNftPriceNotAllowed');
    require(_creatorFeeRoyaltyPercentage <= (50 * PRECISION_DECIMALS) / 100, 'IncorrectRoyaltyFee');
    if (mainData.onlyNFTCreatorRole) {
      require(hasRole(NFT_CREATOR_ROLE, _msgSender()), 'OnlyNftCreator');
    }
    require(msg.value == fees.worldFeeCreator, 'IncorrectWorldFee');

    mainData.nftIDs++;

    Nft storage nft = mainData.nfts[mainData.nftIDs];

    // nftWorldItem.prevPrice = 0; // is by default zero
    nft.price = _nftItemPriceWei;
    // nftWorldItem.sellingPrice = 0; // is by default zero
    nft.creator = payable(msg.sender);
    nft.creatorFeeRoyalty = _creatorFeeRoyaltyPercentage;
    nft.uriHash = keccak256(abi.encodePacked(_tokenURI));

    uint256 platformFee = ((fees.worldFeeCreator * uint256(fees.platformFeeCreator)) / PRECISION_DECIMALS);
    uint256 verseFee = ((fees.worldFeeCreator * uint256(fees.verseFeeCreator)) / PRECISION_DECIMALS);

    fees.totalPlatformFee += platformFee;
    fees.totalVerseFee += verseFee;
    fees.totalWorldFee += fees.worldFeeCreator - platformFee - verseFee;

    _safeMint(msg.sender, mainData.nftIDs);

    _setTokenURI(mainData.nftIDs, _tokenURI);
    emit CreateNFT(mainData.worldId, msg.sender, mainData.nftIDs, _nftItemPriceWei);
  }

  function sellNFT(uint256 _nftId, uint256 _nftItemPriceWei) external whenNotPaused whenNftExists(_nftId) {
    // require(_nftItemPriceWei >= getMinSellPrice(_nftId), 'UseGetMinSellPrice');
    Nft storage nft = mainData.nfts[_nftId];
    require(_nftItemPriceWei > nft.price, 'SellingPriceMustBeHigherThanPrice');

    require(msg.sender == ownerOf(_nftId), 'OnlyNFTowner');
    require(nft.sellingPrice == 0, 'NftAlreadyForSale');

    nft.sellingPrice = _nftItemPriceWei;

    emit SellNFT(mainData.worldId, msg.sender, _nftId, _nftItemPriceWei);
  }

  function cancelSellNFT(uint256 _nftId) external whenNotPaused whenNftExists(_nftId) {
    require(msg.sender == ownerOf(_nftId), 'OnlyNFTowner');
    require(mainData.nfts[_nftId].sellingPrice != 0, 'NFTnotForSale');

    mainData.nfts[_nftId].sellingPrice = 0;

    emit CancelSellNFT(mainData.worldId, msg.sender, _nftId);
  }

  function buyNFT(uint256 _nftId) external payable whenNotPaused whenNftExists(_nftId) {
    Nft storage nft = mainData.nfts[_nftId];

    require(nft.sellingPrice != 0, 'NFTnotForSale');
    require(msg.value == nft.sellingPrice, 'ValueMustEqualSellingPrice');

    address payable seller = payable(ownerOf(_nftId));
    address buyer = msg.sender;

    require(seller != buyer, 'SellerMustNotBeTheBuyer');
    console.log('test', nft.sellingPrice);
    _buyNftProcessFees(seller, nft);

    // requires previous approval by seller
    this.safeTransferFrom(seller, buyer, _nftId);

    emit BuyNFT(mainData.worldId, seller, buyer, _nftId, nft.sellingPrice);

    nft.prevPrice = nft.price;
    nft.price = nft.sellingPrice;
    nft.sellingPrice = 0;
  }

  function _buyNftProcessFees(address payable _seller, Nft storage nft) private {
    uint256 priceDiff = nft.prevPrice == 0 ? nft.sellingPrice : (nft.sellingPrice - nft.price);

    // uint256 priceDiff = nft.sellingPrice - nft.price;
    uint256 worldFeeSellBuyWei = (priceDiff * uint256(fees.worldFeeSellBuy)) / PRECISION_DECIMALS;

    //Process Platform nftFees
    uint256 platformFee = (worldFeeSellBuyWei * uint256(fees.platformFeeSellBuy)) / PRECISION_DECIMALS;
    fees.totalPlatformFee += platformFee;

    //Process VersePlatform Fees
    uint256 verseFee = (worldFeeSellBuyWei * uint256(fees.verseFeeSellBuy)) / PRECISION_DECIMALS;
    fees.totalVerseFee += verseFee;

    fees.totalWorldFee += (worldFeeSellBuyWei - platformFee - verseFee); 

    //Process Royalty Fee
    uint256 sellerProfitWithoutRoyalty = priceDiff - worldFeeSellBuyWei;

    uint256 creatorProfit;
    if (nft.creator != _seller) {
      creatorProfit = (sellerProfitWithoutRoyalty * uint256(nft.creatorFeeRoyalty)) / PRECISION_DECIMALS;
      if (creatorProfit > 0) {
        nft.creator.transfer(creatorProfit);
      }
    }

    //Process Seller Profit
    // uint256 sellerProfit = sellerProfitWithoutRoyalty - creatorProfit;    
    uint256 toTransfer = nft.prevPrice == 0 ? (sellerProfitWithoutRoyalty - creatorProfit) : (nft.price + sellerProfitWithoutRoyalty - creatorProfit);

    if (toTransfer > 0) {
      _seller.transfer(toTransfer);
    }
  }

  function updatePlatformFees(uint32 _platformFeeCreator, uint32 _platformFeeSellBuy) external {
    require(INFTPlatform(mainData.platform).hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'OnlyPlatformAdmin');
    require(_platformFeeCreator <= (50 * PRECISION_DECIMALS) / 100, 'IncorrectPlatformFeeCreator');
    require(_platformFeeSellBuy <= (50 * PRECISION_DECIMALS) / 100, 'IncorrectPlatformFeeSellBuy');

    fees.platformFeeCreator = _platformFeeCreator;
    fees.platformFeeSellBuy = _platformFeeSellBuy;
    emit UpdatePlatformFees(fees.platformFeeCreator, fees.platformFeeSellBuy);
  }

  function updateVerseFees(uint32 _verseFeeCreator, uint32 _verseFeeSellBuy) external {
    require(IVerse(mainData.verse).hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'OnlyVerseAdmin');
    require(_verseFeeCreator <= (50 * PRECISION_DECIMALS) / 100, 'IncorrectVerseFeeCreator');
    require(_verseFeeSellBuy <= (50 * PRECISION_DECIMALS) / 100, 'IncorrectVerseFeeSellBuy');

    fees.verseFeeCreator = _verseFeeCreator;
    fees.verseFeeSellBuy = _verseFeeSellBuy;
    emit UpdateVerseFees(fees.verseFeeCreator, fees.verseFeeSellBuy);
  }

  function updateWorldFees(uint256 _worldFeeCreator, uint32 _worldFeeSellBuy) external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'OnlyWorldAdmin');
    require(_worldFeeSellBuy <= (50 * PRECISION_DECIMALS) / 100, 'IncorrectWorldFeeSellBuy');

    fees.worldFeeCreator = _worldFeeCreator;
    fees.worldFeeSellBuy = _worldFeeSellBuy;
    emit UpdateWorldFees(fees.worldFeeCreator, fees.worldFeeSellBuy);
  }

  function claimPlatformFee() external {
    require(INFTPlatform(mainData.platform).hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'OnlyPlatformAdmin');
    require(fees.totalPlatformFee > 0, 'ZeroPlatformFees');
    uint256 feesToSend = fees.totalPlatformFee;
    fees.totalPlatformFee = 0;
    payable(_msgSender()).transfer(feesToSend);
  }

  function claimVerseFee() external {
    require(IVerse(mainData.verse).hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'OnlyVerseAdmin');
    require(fees.totalVerseFee > 0, 'ZeroVerseFees');

    uint256 feesToSend = fees.totalVerseFee;
    fees.totalVerseFee = 0;
    payable(_msgSender()).transfer(feesToSend);
  }

  function claimWorldFee() external {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'OnlyWorldAdmin');
    require(fees.totalWorldFee > 0, 'ZeroWorldFees');

    uint256 feesToSend = fees.totalWorldFee;
    fees.totalWorldFee = 0;
    payable(_msgSender()).transfer(feesToSend);
  }

  function withdrawEther(address payable _recipient) external onlyRole(DEFAULT_ADMIN_ROLE) {
    uint256 _AmountOfWeiRemainInContract = fees.totalWorldFee + fees.totalVerseFee + fees.totalPlatformFee;
    if (_AmountOfWeiRemainInContract < address(this).balance) {
      uint256 _AmountOfWeiToWithdraw = address(this).balance - _AmountOfWeiRemainInContract;
      _recipient.transfer(_AmountOfWeiToWithdraw);
    } else revert('Not enough ETH in contract');
  }

  /// @dev Admin can pause the World. Check functions with whenPaused/whenNotPaused modifier
  function pauseWorld() external whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
    super._pause();
  }

  /// @dev Admin can unpause the World. Check functions with whenPaused/whenNotPaused modifier
  function unpauseWorld() external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
    super._unpause();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let argumentsLength := mload(payload)
            let argumentsOffset := add(payload, 32)
            pop(staticcall(gas(), consoleAddress, argumentsOffset, argumentsLength, 0, 0))
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logAddress(address value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", value));
    }

    function logBool(bool value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", value));
    }

    function logString(string memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", value));
    }

    function logUint256(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function logUint(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function logBytes(bytes memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", value));
    }

    function logInt256(int256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", value));
    }

    function logInt(int256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", value));
    }

    function logBytes1(bytes1 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", value));
    }

    function logBytes2(bytes2 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", value));
    }

    function logBytes3(bytes3 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", value));
    }

    function logBytes4(bytes4 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", value));
    }

    function logBytes5(bytes5 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", value));
    }

    function logBytes6(bytes6 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", value));
    }

    function logBytes7(bytes7 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", value));
    }

    function logBytes8(bytes8 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", value));
    }

    function logBytes9(bytes9 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", value));
    }

    function logBytes10(bytes10 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", value));
    }

    function logBytes11(bytes11 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", value));
    }

    function logBytes12(bytes12 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", value));
    }

    function logBytes13(bytes13 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", value));
    }

    function logBytes14(bytes14 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", value));
    }

    function logBytes15(bytes15 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", value));
    }

    function logBytes16(bytes16 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", value));
    }

    function logBytes17(bytes17 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", value));
    }

    function logBytes18(bytes18 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", value));
    }

    function logBytes19(bytes19 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", value));
    }

    function logBytes20(bytes20 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", value));
    }

    function logBytes21(bytes21 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", value));
    }

    function logBytes22(bytes22 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", value));
    }

    function logBytes23(bytes23 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", value));
    }

    function logBytes24(bytes24 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", value));
    }

    function logBytes25(bytes25 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", value));
    }

    function logBytes26(bytes26 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", value));
    }

    function logBytes27(bytes27 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", value));
    }

    function logBytes28(bytes28 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", value));
    }

    function logBytes29(bytes29 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", value));
    }

    function logBytes30(bytes30 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", value));
    }

    function logBytes31(bytes31 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", value));
    }

    function logBytes32(bytes32 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", value));
    }

    function log(address value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", value));
    }

    function log(bool value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", value));
    }

    function log(string memory value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", value));
    }

    function log(uint256 value) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", value));
    }

    function log(address value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", value1, value2));
    }

    function log(address value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", value1, value2));
    }

    function log(address value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", value1, value2));
    }

    function log(address value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", value1, value2));
    }

    function log(bool value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", value1, value2));
    }

    function log(bool value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", value1, value2));
    }

    function log(bool value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", value1, value2));
    }

    function log(bool value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", value1, value2));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", value1, value2));
    }

    function log(uint256 value1, address value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", value1, value2));
    }

    function log(uint256 value1, bool value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", value1, value2));
    }

    function log(uint256 value1, string memory value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", value1, value2));
    }

    function log(uint256 value1, uint256 value2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", value1, value2));
    }

    function log(address value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", value1, value2, value3));
    }

    function log(address value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", value1, value2, value3));
    }

    function log(address value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", value1, value2, value3));
    }

    function log(address value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", value1, value2, value3));
    }

    function log(address value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", value1, value2, value3));
    }

    function log(address value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", value1, value2, value3));
    }

    function log(address value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", value1, value2, value3));
    }

    function log(address value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", value1, value2, value3));
    }

    function log(address value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", value1, value2, value3));
    }

    function log(address value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", value1, value2, value3));
    }

    function log(address value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", value1, value2, value3));
    }

    function log(address value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", value1, value2, value3));
    }

    function log(address value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", value1, value2, value3));
    }

    function log(bool value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", value1, value2, value3));
    }

    function log(bool value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", value1, value2, value3));
    }

    function log(bool value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", value1, value2, value3));
    }

    function log(bool value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", value1, value2, value3));
    }

    function log(bool value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", value1, value2, value3));
    }

    function log(bool value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", value1, value2, value3));
    }

    function log(bool value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", value1, value2, value3));
    }

    function log(bool value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", value1, value2, value3));
    }

    function log(bool value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", value1, value2, value3));
    }

    function log(bool value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", value1, value2, value3));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", value1, value2, value3));
    }

    function log(uint256 value1, address value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", value1, value2, value3));
    }

    function log(uint256 value1, bool value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", value1, value2, value3));
    }

    function log(uint256 value1, string memory value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, address value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, bool value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, string memory value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", value1, value2, value3));
    }

    function log(uint256 value1, uint256 value2, uint256 value3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", value1, value2, value3));
    }

    function log(address value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(address value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(bool value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", value1, value2, value3, value4));
    }

    /**
    * Prints to `stdout` with newline. Multiple arguments can be passed, with the
    * first used as the primary message and all additional used as substitution
    * values similar to [`printf(3)`](http://man7.org/linux/man-pages/man3/printf.3.html) (the arguments are all passed to `util.format()`).
    *
    * ```solidity
    * uint256 count = 5;
    * console.log('count: %d', count);
    * // Prints: count: 5, to stdout
    * console.log('count:', count);
    * // Prints: count: 5, to stdout
    * ```
    *
    * See `util.format()` for more information.
    */
    function log(string memory value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, address value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, bool value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, string memory value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, address value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, bool value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, string memory value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, address value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, bool value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, string memory value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", value1, value2, value3, value4));
    }

    function log(uint256 value1, uint256 value2, uint256 value3, uint256 value4) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", value1, value2, value3, value4));
    }
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
interface IVerse is IAccessControlUpgradeable {
    // VERSE EVENTS
    event RegisterWorld(address indexed _sender, string indexed _worldId, address _worldAddress);    
    event Deposit(address indexed _sender, uint256 _value, uint256 _newBalance);
    event UpdateVerseData(address indexed _sender, string _verseData);
    event UpdateWorldAddress(address indexed _sender, string indexed _worldId, address _worldAddress, string _worldType);
    
    // Public
    function getPlatform() external view returns(address);
    function getVerseData() external view returns (string memory, bytes32);
    function getVerseId() external view returns(string memory);
    function getWorldIds() external view returns (string[] memory);
    function getWorldAddress(string calldata _worldId) external view returns (address, string memory);    

    // only Admin
    function updateVerseData(string memory _verseData) external;
    function updateWorldAddress(address _worldAddress, string calldata _worldType, string calldata _worldId) external ;
    function registerWorld(address _worldAddress, string memory _worldData, string memory _worldType) external;
    function pauseVerse() external;
    function unpauseVerse() external;
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";

interface INFTPlatform is IAccessControlUpgradeable {
    // NFT PLATFORM EVENTS
    event RegisterVerse(address indexed _sender, string indexed _verseId, address _verseAddress);
    event Deposit(address indexed _sender, uint256 _value, uint256 _newBalance);
    event UpdatePlatformData(address indexed _sender, string _platformData);
    event UpdateVerseAddress(address indexed _sender, string indexed _verseId, address _verseAddress);
      
    // Public
    function getPlatformData() external view returns (string memory, bytes32);
    function getVerseIds() external view returns (string[] memory);
    function getVerseAddress(string calldata _verseId) external view returns (address);
    
    // only Admin
    function updatePlatformData(string memory _platformData) external;
    function updateVerseAddress(address _verseAddress) external;
    function registerVerse(address _verseAddress) external;
    function killContract() external returns (bool);
    function getEther(address payable _recipient, uint256 _amountWei) external;
    function pausePlatform() external;
    function unpausePlatform() external;
    
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

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
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}