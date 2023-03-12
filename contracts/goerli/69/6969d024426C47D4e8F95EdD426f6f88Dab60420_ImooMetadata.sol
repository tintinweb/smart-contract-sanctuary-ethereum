// SPDX-License-Identifier: BUSL1.1
pragma solidity 0.8.19;

import "./IMetadataStore.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IImooXtension.sol";
import "./ComposeThis/IEPS_CT.sol";

contract ImooMetadata is Ownable, IMetadataStore, IERC721Receiver {
  using Strings for uint256;
  using Strings for uint32;
  using Strings for address;

  uint256 public constant TRAITS_SLICE_LENGTH = 2;

  uint256 public constant SLICE_COLOR = 1; // image
  uint256 public constant SLICE_FEATURE = 2; // image
  uint256 public constant SLICE_MONOGRAM = 3; // image
  uint256 public constant SLICE_STRIPES = 4; // image
  uint256 public constant SLICE_DESPAIR = 5; // trait only
  uint256 public constant SLICE_REGRET = 6; // trait only
  uint256 public constant SLICE_PERSPECTIVE = 7; // trait only
  uint256 public constant SLICE_ETHEREAL = 8; // ??

  uint256 constant IMOO_COUNTER_BASE =
    100000000000000000000000000000000000000000000000000000000000000000;

  address public imooGovernor;

  uint32 public coolDownInHours = 24;

  IERC721 public imoo;

  IEPS_CT public composeThis;

  struct Award {
    // xemplar
    string trait;
    string value;
  }

  struct Background {
    address backgroundAddress;
    uint96 backgroundTokenId;
  }

  mapping(uint256 => uint16[]) public accessories;

  mapping(address => bool) public awarder;

  mapping(uint256 => uint32[]) public tokenToAwards;

  mapping(uint256 => mapping(uint16 => uint256)) ownedAccessory;

  mapping(uint256 => Award) public awardCodeToAward;

  mapping(uint256 => address) public accessoryCodeToAddress;

  mapping(address => uint256) public accessoryAddressToCode;

  mapping(address => bool) public backgroundAddress;

  mapping(address => string) public backgroundName;

  mapping(uint256 => Background) public tokenIdToBackground;

  mapping(uint256 => uint256) public tokenIdCoolDownExpiry;

  event AccessoryAdded(
    uint256 tokenId,
    address accessoryToken,
    uint256 accessoryTokenId
  );

  event AccessoryRemoved(
    uint256 tokenId,
    address accessoryToken,
    uint256 accessoryTokenId
  );

  event BackgroundAdded(
    uint256 tokenId,
    address accessoryToken,
    uint256 accessoryTokenId
  );

  event BackgroundRemoved(
    uint256 tokenId,
    address backgroundToken,
    uint256 backgroundTokenId
  );

  event ImageCompositorUpdated();

  error imooSet();
  error CallerIsNotAnAuthorisedAwarder();
  error NotTokenOwner();
  error AccessoryAlreadyAdded();
  error AccessoryNotFound();
  error NotAValidAccessoryOrBackgroundToken();
  error NotAValidAccessoryToken();
  error NotAValidBackgroundToken();
  error NoBackgroundForToken();
  error OnlyOwnerOrCommunity();

  constructor() {
    transferOwnership(0xD2FbC918728282907fd26422EAEB0d8C8797B703);
  }

  /**
   * @dev onlyOwnerOrCommunity:
   */
  modifier onlyOwnerOrCommunity() {
    if (msg.sender != owner() && msg.sender != imooGovernor) {
      revert OnlyOwnerOrCommunity();
    }
    _;
  }

  /**
   * @dev serveTokenURI
   */
  function serveTokenURI(
    uint256 tokenId_
  ) external view returns (string memory) {
    string memory json;
    (
      address imooContract,
      uint256 imooAttributes,
      uint256 imooId
    ) = _decodeTokenId(tokenId_);

    (string memory traits, string memory image) = _decodeAttributes(
      imooContract,
      [tokenId_, imooId, imooAttributes]
    );

    json = Base64.encode(
      bytes(
        string.concat(
          '{"name":"',
          "imoo ",
          imooId.toString(),
          '", ',
          '"image_data":"',
          image,
          '", ',
          '"attributes":[',
          traits,
          "]}"
        )
      )
    );

    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  /**
   * @dev _sliceTraitsInteger:
   */
  function _sliceTraitsInteger(
    uint256 attributesInteger_,
    uint256 position_
  ) internal pure returns (uint256) {
    uint256 exponent = (10 ** (position_ * TRAITS_SLICE_LENGTH));
    uint256 divisor;
    if (position_ == 1) {
      divisor = 1;
    } else {
      divisor = (10 ** ((position_ - 1) * TRAITS_SLICE_LENGTH));
    }

    return ((attributesInteger_ % exponent) / divisor);
  }

  /**
   * @dev _decodeTokenId:
   */
  function _decodeTokenId(
    uint256 tokenId_
  )
    public
    pure
    returns (
      address imooCollection_,
      uint256 imooMetadata_,
      uint256 imooCounter_
    )
  {
    // Number of attribute pairs: 8 (therefore 16 digits required)
    // Max uint160:                              1461501637330902918203684832716283019655932542975
    // Max uint256: 115792089237316195423570985008687907853269984665640564039457584007913129639935
    // tokenId:     |--counter--||---metadata---||----------------imoo collection ---------------|
    return (
      imooCollection(tokenId_),
      imooMetadataInteger(tokenId_),
      imooCounter(tokenId_)
    );
  }

  /**
   * @dev _decodeAttributes:
   */
  function _decodeAttributes(
    address imooContract_,
    uint256[3] memory ids_ // [0] tokenId, [1] imooId // [2] traitInteger
  )
    internal
    view
    returns (string memory stringTraits_, string memory stringImages_)
  {
    // 0 = Trait, 1 = Images
    uint256[2] memory currentIndexes;

    (uint256 traitCount, uint256 imageCount) = _getAccessoryTraitAndImageCount(
      ids_[0]
    );

    AddedTrait[] memory traits = new AddedTrait[](12 + traitCount);
    string[] memory images = new string[](10 + imageCount);

    (traits, images, currentIndexes) = _getAttributes1(
      traits,
      images,
      currentIndexes,
      ids_[2],
      imooContract_,
      _parentChain(imooParentChain(ids_[0]))
    );

    (traits, images, currentIndexes) = _getAttributes2(
      traits,
      images,
      currentIndexes,
      ids_[2]
    );

    (traits, images, currentIndexes) = _getAttributes3(
      traits,
      images,
      currentIndexes,
      ids_[0]
    );

    return (
      composeThis.composeTraitsAndImage(
        imooBackground(ids_[0]),
        1,
        images,
        imooContract_,
        ids_[1],
        traits
      )
    );
  }

  /**
   * @dev _getAttributes1:
   */
  function _getAttributes1(
    AddedTrait[] memory traitsIn_,
    string[] memory imagesIn_,
    uint256[2] memory indexes_,
    uint256 traitInteger_,
    address imooContract_,
    string memory parentChain_
  )
    internal
    pure
    returns (
      AddedTrait[] memory traits_,
      string[] memory images_,
      uint256[2] memory returnedIndexes_
    )
  {
    uint256 currentTraitIndex = indexes_[0];
    uint256 currentImageIndex = indexes_[1];

    traits_ = traitsIn_;
    images_ = imagesIn_;

    string memory color = _decodeColor(
      _sliceTraitsInteger(traitInteger_, SLICE_COLOR)
    );

    string memory feature = _decodeFeature(
      _sliceTraitsInteger(traitInteger_, SLICE_FEATURE)
    );

    string memory monogram = _decodeMonogram(
      _sliceTraitsInteger(traitInteger_, SLICE_MONOGRAM)
    );

    string memory stripes = _decodeStripes(
      _sliceTraitsInteger(traitInteger_, SLICE_STRIPES)
    );

    traits_[currentTraitIndex] = AddedTrait(
      "imooCollection",
      ValueType.chainAddress,
      0,
      "",
      imooContract_
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Parent_Chain",
      ValueType.characterString,
      0,
      parentChain_,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Color",
      ValueType.characterString,
      0,
      color,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Feature",
      ValueType.characterString,
      0,
      feature,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Monogram",
      ValueType.characterString,
      0,
      monogram,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Stripes",
      ValueType.characterString,
      0,
      stripes,
      address(0)
    );
    currentTraitIndex += 1;

    images_[currentImageIndex] = string.concat(color, feature);
    currentImageIndex += 1;

    images_[currentImageIndex] = monogram;
    currentImageIndex += 1;

    images_[currentImageIndex] = stripes;
    currentImageIndex += 1;

    images_[currentImageIndex] = parentChain_;
    currentImageIndex += 1;

    return (traits_, images_, [currentTraitIndex, currentImageIndex]);
  }

  /**
   *
   * @dev _getAttributes2:
   *
   */
  function _getAttributes2(
    AddedTrait[] memory traitsIn_,
    string[] memory imagesIn_,
    uint256[2] memory indexes_,
    uint256 traitInteger_
  )
    internal
    pure
    returns (
      AddedTrait[] memory traits_,
      string[] memory images_,
      uint256[2] memory returnedIndexes_
    )
  {
    uint256 currentTraitIndex = indexes_[0];
    uint256 currentImageIndex = indexes_[1];

    traits_ = traitsIn_;
    images_ = imagesIn_;

    string memory despair = _decodeDespair(
      _sliceTraitsInteger(traitInteger_, SLICE_DESPAIR)
    );

    string memory regret = _decodeRegret(
      _sliceTraitsInteger(traitInteger_, SLICE_REGRET)
    );

    string memory perspective = _decodePerspective(
      _sliceTraitsInteger(traitInteger_, SLICE_PERSPECTIVE)
    );

    string memory ethereal = _decodeEthereal(
      _sliceTraitsInteger(traitInteger_, SLICE_ETHEREAL)
    );

    string memory outlook = _decodeOutlook();

    traits_[currentTraitIndex] = AddedTrait(
      "Despair",
      ValueType.characterString,
      0,
      despair,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Regret",
      ValueType.characterString,
      0,
      regret,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Perspective",
      ValueType.characterString,
      0,
      perspective,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Ethereal",
      ValueType.characterString,
      0,
      ethereal,
      address(0)
    );
    currentTraitIndex += 1;

    traits_[currentTraitIndex] = AddedTrait(
      "Outlook",
      ValueType.characterString,
      0,
      outlook,
      address(0)
    );
    currentTraitIndex += 1;

    images_[currentImageIndex] = despair;
    currentImageIndex += 1;

    images_[currentImageIndex] = regret;
    currentImageIndex += 1;

    images_[currentImageIndex] = perspective;
    currentImageIndex += 1;

    images_[currentImageIndex] = ethereal;
    currentImageIndex += 1;

    images_[currentImageIndex] = outlook;
    currentImageIndex += 1;

    return (traits_, images_, [currentTraitIndex, currentImageIndex]);
  }

  /**
   *
   * @dev _getAttributes3:
   *
   */
  function _getAttributes3(
    AddedTrait[] memory traitsIn_,
    string[] memory imagesIn_,
    uint256[2] memory indexes_,
    uint256 tokenId_
  )
    internal
    view
    returns (
      AddedTrait[] memory traits_,
      string[] memory images_,
      uint256[2] memory returnedIndexes_
    )
  {
    uint256 currentTraitIndex = indexes_[0];
    uint256 currentImageIndex = indexes_[1];

    traits_ = traitsIn_;
    images_ = imagesIn_;

    string memory chainLocation;

    if (imoo.ownerOf(tokenId_) == address(imoo)) {
      chainLocation = "off-chain";
    } else {
      chainLocation = "on-chain";
    }

    traits_[currentTraitIndex] = AddedTrait(
      "Dimension",
      ValueType.characterString,
      0,
      chainLocation,
      address(0)
    );
    currentTraitIndex += 1;

    images_[currentImageIndex] = chainLocation;
    currentImageIndex += 1;

    for (uint256 i; i < tokenToAwards[tokenId_].length; ++i) {
      traits_[currentTraitIndex] = AddedTrait(
        awardCodeToAward[tokenToAwards[tokenId_][i]].trait,
        ValueType.characterString,
        0,
        awardCodeToAward[tokenToAwards[tokenId_][i]].value,
        address(0)
      );
      currentTraitIndex += 1;

      images_[currentImageIndex] = string.concat(
        "aw_",
        tokenToAwards[tokenId_][i].toString()
      );
      currentImageIndex += 1;
    }

    for (uint256 index = 0; index < accessories[tokenId_].length; ) {
      uint16 accessoryCode = accessories[tokenId_][index];
      address accessoryAddress = accessoryCodeToAddress[accessoryCode];
      uint256 accessoryTokenId = ownedAccessory[tokenId_][accessoryCode];

      (
        string[] memory imageTags,
        string memory traitType,
        string memory value
      ) = IImooXtension(accessoryAddress).imooTraitTypeValueAndImageTags(
          accessoryTokenId
        );

      traits_[currentTraitIndex] = AddedTrait(
        traitType,
        ValueType.characterString,
        0,
        value,
        address(0)
      );
      currentTraitIndex += 1;

      for (uint256 i = 0; i < imageTags.length; ) {
        images_[currentImageIndex] = imageTags[i];
        currentImageIndex += 1;
        unchecked {
          ++i;
        }
      }

      unchecked {
        ++index;
      }
    }

    return (traits_, images_, [currentTraitIndex, currentImageIndex]);
  }

  /**
   *
   * @dev _getAccessoryTraitAndImageCount:
   *
   */
  function _getAccessoryTraitAndImageCount(
    uint256 tokenId_
  ) internal view returns (uint256 traitCount_, uint256 imageCount_) {
    for (uint256 index = 0; index < accessories[tokenId_].length; ) {
      uint16 accessoryCode = accessories[tokenId_][index];
      address accessoryAddress = accessoryCodeToAddress[accessoryCode];

      imageCount_ += IImooXtension(accessoryAddress)
        .getImagesAndTraitCountIncludingBase();

      traitCount_ += 1;

      unchecked {
        ++index;
      }
    }

    return (
      traitCount_ + tokenToAwards[tokenId_].length,
      imageCount_ + tokenToAwards[tokenId_].length
    );
  }

  /**
   *
   * @dev tokenCooldown
   *
   */
  function tokenCooldown(uint256 tokenId_) external view returns (uint256) {
    return tokenIdCoolDownExpiry[tokenId_];
  }

  /**
   *
   * @dev imooBackground
   *
   */
  function imooBackground(
    uint256 tokenId_
  ) public view returns (string memory) {
    if (tokenIdToBackground[tokenId_].backgroundAddress != address(0)) {
      return (backgroundName[tokenIdToBackground[tokenId_].backgroundAddress]);
    } else {
      return ("base");
    }
  }

  /**
   *
   * @dev imooCollection
   *
   */
  function imooCollection(
    uint256 tokenId_
  ) public pure returns (address imooCollection_) {
    imooCollection_ = address(
      uint160(
        uint256(tokenId_ % 10000000000000000000000000000000000000000000000000)
      )
    );

    return (imooCollection_);
  }

  /**
   *
   * @dev imooMetadata
   *
   */
  function imooMetadataInteger(
    uint256 tokenId_
  ) public pure returns (uint256 imooMetadataInteger_) {
    imooMetadataInteger_ =
      (tokenId_ %
        100000000000000000000000000000000000000000000000000000000000000000) /
      1000000000000000000000000000000000000000000000000;

    return (imooMetadataInteger_);
  }

  /**
   *
   * @dev imooCounter
   *
   */
  function imooCounter(
    uint256 tokenId_
  ) public pure returns (uint256 imooCounter_) {
    imooCounter_ =
      tokenId_ /
      100000000000000000000000000000000000000000000000000000000000000000;

    return (imooCounter_);
  }

  /**
   *
   * @dev imooParentChain
   *
   */
  function imooParentChain(
    uint256 tokenId_
  ) public pure returns (uint256 imooParentChain_) {
    imooParentChain_ =
      tokenId_ /
      1000000000000000000000000000000000000000000000000000000000000000000000;

    return (imooParentChain_);
  }

  /**
   *
   * @dev _parentChain
   *
   */
  function _parentChain(
    uint256 chainId_
  ) internal pure returns (string memory) {
    if (chainId_ == 1) return ("Ethereum");
    if (chainId_ == 5) return ("Goerli");
    if (chainId_ == 11155111) return ("Sepolia");
    if (chainId_ == 56) return ("BSC");
    if (chainId_ == 42161) return ("Arbitrum");
    if (chainId_ == 137) return ("Polygon");
    if (chainId_ == 43114) return ("Avalanche");
    if (chainId_ == 10) return ("Optimism");
    if (chainId_ == 250) return ("Fantom");
    if (chainId_ == 25) return ("Cronos");
    if (chainId_ == 2222) return ("Kava");
    if (chainId_ == 8217) return ("Klaytn");
    if (chainId_ == 32659) return ("Fusion");
    if (chainId_ == 100) return ("Gnosis");
    if (chainId_ == 7700) return ("Canto");
    if (chainId_ == 42220) return ("Celo");
    if (chainId_ == 1284) return ("Moonbeam");
    if (chainId_ == 128) return ("Huobi");
    if (chainId_ == 66) return ("OKXChain");
    if (chainId_ == 30) return ("RSK");
    if (chainId_ == 321) return ("KCC");
    if (chainId_ == 1088) return ("Metis");
    if (chainId_ == 40) return ("Telos");
    if (chainId_ == 1285) return ("Moonriver");
    else return chainId_.toString();
  }

  /**
   *
   * @dev imooColor
   *
   */
  function imooColor(uint256 tokenId_) external pure returns (string memory) {
    return
      _decodeColor(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_COLOR)
      );
  }

  /**
   *
   * @dev _decodeColor
   *
   */
  function _decodeColor(uint256 trait_) internal pure returns (string memory) {
    if (trait_ == 99) return ("picotop"); // 1%, pink
    if (trait_ > 96) return ("coinfession"); //  2% yellow
    if (trait_ > 92) return ("uponly"); // 4% green
    if (trait_ > 84) return ("buythedip"); // 8% red
    if (trait_ > 68) return ("seablue");
    // 16% blue
    else return ("techbrah"); // 69% grey
  }

  /**
   *
   * @dev imooDespair
   *
   */
  function imooDespair(uint256 tokenId_) external pure returns (string memory) {
    return
      _decodeDespair(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_DESPAIR)
      );
  }

  /**
   *
   * @dev _decodeDespair
   *
   */
  function _decodeDespair(
    uint256 trait_
  ) internal pure returns (string memory) {
    if (trait_ == 99) return ("EffTeaEx"); // 1%
    if (trait_ > 96) return ("notsize"); // 2%
    if (trait_ > 92) return ("3rdarrow"); // 4%
    if (trait_ > 84) return ("gigarekt"); // 8%
    if (trait_ > 68) return ("downbad");
    // 16%
    else return ("oof"); // 69%
  }

  /**
   *
   * @dev imooSelfLoating
   *
   */
  function imooRegret(uint256 tokenId_) external pure returns (string memory) {
    return
      _decodeRegret(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_REGRET)
      );
  }

  /**
   *
   * @dev _decodeRegret
   *
   */
  function _decodeRegret(uint256 trait_) internal pure returns (string memory) {
    if (trait_ == 99) return ("silence"); // 1%
    if (trait_ > 96) return ("maxcopium"); // 2%
    if (trait_ > 92) return ("boatingaccident"); // 4%
    if (trait_ > 84) return ("whywhy"); // 8%
    if (trait_ > 68) return ("why");
    // 16%
    else return ("taketheL"); // 69%
  }

  /**
   *
   * @dev imooPerspective
   *
   */
  function imooPerspective(
    uint256 tokenId_
  ) external pure returns (string memory) {
    return
      _decodePerspective(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_PERSPECTIVE)
      );
  }

  /**
   *
   * @dev _decodePerspective
   *
   */
  function _decodePerspective(
    uint256 trait_
  ) internal pure returns (string memory) {
    if (trait_ == 99) return ("flourishing"); // 1%
    if (trait_ > 96) return ("focussed"); // 2%
    if (trait_ > 92) return ("inmylane"); // 4%
    if (trait_ > 84) return ("happy"); // 8%
    if (trait_ > 68) return ("moisturized");
    //16%
    else return ("unbothered"); // 69%
  }

  /**
   *
   * @dev imooFeature
   *
   */
  function imooStripes(uint256 tokenId_) external pure returns (string memory) {
    return
      _decodeStripes(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_STRIPES)
      );
  }

  /**
   *
   * @dev _decodeStripes
   *
   */
  function _decodeStripes(
    uint256 trait_
  ) internal pure returns (string memory) {
    if (trait_ > 97) return ("logo"); // 2%
    if (trait_ > 93) return ("triple"); // 4%
    if (trait_ > 83) return ("double"); // 10%
    if (trait_ > 68) return ("single");
    // 15%
    // 25%
    else return ("none"); // 69%
  }

  /**
   *
   * @dev imooFeature
   *
   */
  function imooFeature(uint256 tokenId_) external pure returns (string memory) {
    return
      _decodeFeature(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_FEATURE)
      );
  }

  /**
   *
   * @dev _decodeFeature
   *
   */
  function _decodeFeature(
    uint256 trait_
  ) internal pure returns (string memory) {
    if (trait_ > 97) return ("polo_pocket"); // 2%
    if (trait_ > 93) return ("polo"); // 4%
    if (trait_ > 68) return ("pocket");
    // 25%
    else return ("featureless"); // 69%
  }

  /**
   *
   * @dev imooMonogram
   *
   */
  function imooMonogram(
    uint256 tokenId_
  ) external pure returns (string memory) {
    return
      _decodeMonogram(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_MONOGRAM)
      );
  }

  /**
   *
   * @dev _decodeMonogram
   *
   */
  function _decodeMonogram(
    uint256 trait_
  ) internal pure returns (string memory) {
    if (trait_ == 99) return ("imoo"); // 1%
    if (trait_ > 88) return ("eth");
    // 10%
    else return ("none");
  }

  /**
   *
   * @dev imooEthereal
   *
   */
  function imooEthereal(
    uint256 tokenId_
  ) external pure returns (string memory) {
    return
      _decodeEthereal(
        _sliceTraitsInteger(imooMetadataInteger(tokenId_), SLICE_ETHEREAL)
      );
  }

  /**
   *
   * @dev _decodeEthereal
   *
   */
  function _decodeEthereal(
    uint256 trait_
  ) internal pure returns (string memory) {
    if (trait_ == 99) return ("truth");
    else return ("beauty");
  }

  /**
   *
   * @dev imooOutlook
   *
   */
  function imooOutlook() external pure returns (string memory) {
    return _decodeOutlook();
  }

  /**
   *
   * @dev _decodeOutlook
   *
   */
  function _decodeOutlook() internal pure returns (string memory) {
    return ("positive");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(IERC165) returns (bool) {
    return interfaceId == type(IMetadataStore).interfaceId;
  }

  /** =====================================================
   *
   *
   * Admin and Governance functions
   *
   *
   * =====================================================
   */

  /**
   *
   * @dev initialiseNFT set the NFT address:
   *
   */
  function initialiseNFT(address imoo_) external onlyOwnerOrCommunity {
    if (address(imoo) != address(0)) {
      revert imooSet();
    }
    imoo = IERC721(imoo_);
  }

  /**
   *
   * @dev setGovernor set the governor address:
   *
   */
  function setGovernor(address imooGovernor_) external onlyOwnerOrCommunity {
    imooGovernor = imooGovernor_;
  }

  /**
   *
   * @dev setComposeThisAddress
   *
   */
  function setComposeThisAddress(
    address composeThis_
  ) external onlyOwnerOrCommunity {
    composeThis = IEPS_CT(composeThis_);
    emit ImageCompositorUpdated();
  }

  /**
   *
   * @dev addAwarder
   *
   */
  function addAwarder(address awarder_) external onlyOwnerOrCommunity {
    awarder[awarder_] = true;
  }

  /**
   *
   * @dev removeAwarder
   *
   */
  function removeAwarder(address awarder_) external onlyOwnerOrCommunity {
    awarder[awarder_] = false;
  }

  /**
   *
   * @dev addAccessory
   *
   */
  function addAccessory(
    address accessoryAddress_,
    uint16 accessoryCode_
  ) external onlyOwnerOrCommunity {
    accessoryAddressToCode[accessoryAddress_] = accessoryCode_;

    accessoryCodeToAddress[accessoryCode_] = accessoryAddress_;
  }

  /**
   *
   * @dev addBackground
   *
   */
  function addBackground(
    address backgroundAddress_,
    string memory backgroundName_
  ) external onlyOwnerOrCommunity {
    backgroundAddress[backgroundAddress_] = true;
    backgroundName[backgroundAddress_] = backgroundName_;
  }

  /**
   *
   * @dev addAward
   *
   */
  function addAward(
    uint32 awardCode_,
    string memory traitDescription_,
    string memory valueDescription_
  ) external onlyOwnerOrCommunity {
    awardCodeToAward[awardCode_] = Award(traitDescription_, valueDescription_);
  }

  /**
   *
   * @dev setCooldown
   *
   */
  function setCooldown(uint32 coolDownInHours_) external onlyOwnerOrCommunity {
    coolDownInHours = coolDownInHours_;
  }

  /** =====================================================
   *
   *
   * Awards
   *
   *
   * =====================================================
   */
  /**
   *
   * @dev receive Award
   *
   */
  function receiveAward(uint256 tokenId_, uint32 awardCode_) external {
    if (
      (msg.sender != address(imoo)) &&
      (!awarder[msg.sender]) &&
      (msg.sender != imooGovernor)
    ) {
      revert CallerIsNotAnAuthorisedAwarder();
    }

    tokenToAwards[tokenId_].push(awardCode_);

    composeThis.triggerMetadataUpdate(1, address(imoo), tokenId_, 0);
  }

  // ===================================
  // ERC4883 - Accessories
  // ===================================

  /**
   *
   * @dev onERC721Received: Accessories are attached by sending the accessory
   * token to the contract (no approval required)
   *
   */
  function onERC721Received(
    address,
    address from_,
    uint256 tokenId_,
    bytes memory data_
  ) external override returns (bytes4) {
    address tokenContract = msg.sender;

    uint256 ownedTokenId = abi.decode(data_, (uint256));

    if (imoo.ownerOf(ownedTokenId) != from_) {
      revert NotTokenOwner();
    }

    // See if this is an accessory or a background:
    if (backgroundAddress[tokenContract]) {
      // This is a background:
      _attachBackground(ownedTokenId, tokenContract, uint96(tokenId_));
    } else {
      // See if this is an accessory:
      uint16 accessoryCode = uint16(accessoryAddressToCode[tokenContract]);
      if (accessoryCode != 0) {
        // This is an accessory
        _attachAccessory(
          ownedTokenId,
          tokenContract,
          accessoryCode,
          uint96(tokenId_)
        );
      } else {
        revert NotAValidAccessoryOrBackgroundToken();
      }
    }

    return this.onERC721Received.selector;
  }

  /**
   *
   * @dev _setCoolDown (when removing accessories or backgrounds there is a configured cooldown
   * period during which this asset canot be sold)
   *
   */
  function _setTokenCoolDown(uint256 tokenId_) internal {
    tokenIdCoolDownExpiry[tokenId_] =
      block.timestamp +
      (coolDownInHours * 1 hours);
  }

  /**
   *
   * @dev _attachAccessory
   *
   */
  function _attachAccessory(
    uint256 tokenId_,
    address accessoryTokenAddress_,
    uint16 accessoryCode_,
    uint96 accessoryTokenId_
  ) internal {
    uint256 accessoryCount = accessories[tokenId_].length;

    // check if accessory already added
    for (uint256 index = 0; index < accessoryCount; ) {
      if (accessories[tokenId_][index] == accessoryCode_) {
        revert AccessoryAlreadyAdded();
      }

      unchecked {
        ++index;
      }
    }

    // add accessory
    accessories[tokenId_].push(accessoryCode_);

    // Record which accessory Id is owned by this tokenId:
    ownedAccessory[tokenId_][accessoryCode_] = accessoryTokenId_;

    emit AccessoryAdded(tokenId_, accessoryTokenAddress_, accessoryTokenId_);

    composeThis.triggerMetadataUpdate(1, address(imoo), tokenId_, 0);
  }

  /**
   *
   * @dev _attachBackgroud
   *
   */
  function _attachBackground(
    uint256 tokenId_,
    address backgroundTokenAddress_,
    uint96 backgroundTokenId_
  ) internal {
    if (!backgroundAddress[backgroundTokenAddress_]) {
      revert NotAValidBackgroundToken();
    }

    // If this tokenID already has a background, swap it out
    if (tokenIdToBackground[tokenId_].backgroundAddress != address(0)) {
      removeBackground(tokenId_);
    }

    // Add the new background
    tokenIdToBackground[tokenId_] = Background(
      backgroundTokenAddress_,
      backgroundTokenId_
    );

    emit BackgroundAdded(tokenId_, backgroundTokenAddress_, backgroundTokenId_);

    composeThis.triggerMetadataUpdate(1, address(imoo), tokenId_, 0);
  }

  /**
   *
   * @dev removeBackground
   *
   */
  function removeBackground(uint256 tokenId_) public {
    if (imoo.ownerOf(tokenId_) != msg.sender) {
      revert NotTokenOwner();
    }

    IERC721(tokenIdToBackground[tokenId_].backgroundAddress).safeTransferFrom(
      address(this),
      msg.sender,
      tokenIdToBackground[tokenId_].backgroundTokenId
    );

    delete tokenIdToBackground[tokenId_];

    _setTokenCoolDown(tokenId_);

    emit BackgroundRemoved(
      tokenId_,
      tokenIdToBackground[tokenId_].backgroundAddress,
      tokenIdToBackground[tokenId_].backgroundTokenId
    );

    composeThis.triggerMetadataUpdate(1, address(imoo), tokenId_, 0);
  }

  /**
   *
   * @dev removeAccessory
   *
   */
  function removeAccessory(
    uint256 tokenId_,
    address accessoryTokenAddress_
  ) public {
    if (imoo.ownerOf(tokenId_) != msg.sender) {
      revert NotTokenOwner();
    }

    (uint256 accessoryTokenId, ) = _detachAccessory(
      tokenId_,
      accessoryTokenAddress_
    );

    IERC721(accessoryTokenAddress_).safeTransferFrom(
      address(this),
      msg.sender,
      accessoryTokenId
    );
  }

  /**
   *
   * @dev removeAllAccessories
   *
   */
  function removeAllAccessories(uint256 tokenId_) public {
    uint256 numberOfAccessories = accessories[tokenId_].length;

    // Remove backwards for efficiency:
    for (uint256 i; i < numberOfAccessories; ) {
      removeAccessory(
        tokenId_,
        accessoryCodeToAddress[
          accessories[tokenId_][numberOfAccessories - (i + 1)]
        ]
      );

      unchecked {
        ++i;
      }
    }
  }

  /**
   *
   * @dev raiseToTop
   *
   */
  function raiseToTop(uint256 tokenId_, uint16 accessoryToRaise_) public {
    if (imoo.ownerOf(tokenId_) != msg.sender) {
      revert NotTokenOwner();
    }

    (uint256 accessoryTokenId, ) = _detachAccessory(
      tokenId_,
      accessoryCodeToAddress[accessoryToRaise_]
    );

    _attachAccessory(
      tokenId_,
      accessoryCodeToAddress[accessoryToRaise_],
      accessoryToRaise_,
      uint96(accessoryTokenId)
    );
  }

  /**
   *
   * @dev _detachAccessory
   *
   */
  function _detachAccessory(
    uint256 tokenId_,
    address accessoryTokenAddress_
  ) internal returns (uint256, uint16) {
    uint16 accessoryCode = uint16(
      accessoryAddressToCode[accessoryTokenAddress_]
    );

    if (accessoryCode == 0) {
      revert NotAValidAccessoryToken();
    }

    uint256 accessoryTokenId = ownedAccessory[tokenId_][accessoryCode];

    // find accessory
    uint256 accessoryCount = accessories[tokenId_].length;
    bool accessoryFound = false;
    uint256 index = 0;
    for (; index < accessoryCount; ) {
      if (accessories[tokenId_][index] == accessoryCode) {
        accessoryFound = true;
        break;
      }

      unchecked {
        ++index;
      }
    }

    if (!accessoryFound) {
      revert AccessoryNotFound();
    }

    // remove accessory
    for (uint256 i = index; i < accessoryCount - 1; ) {
      accessories[tokenId_][i] = accessories[tokenId_][i + 1];

      unchecked {
        ++i;
      }
    }
    accessories[tokenId_].pop();
    delete ownedAccessory[tokenId_][accessoryCode];
    _setTokenCoolDown(tokenId_);

    emit AccessoryRemoved(tokenId_, accessoryTokenAddress_, accessoryTokenId);

    composeThis.triggerMetadataUpdate(1, address(imoo), tokenId_, 0);

    return (accessoryTokenId, accessoryCode);
  }

  /**
   *
   * @dev tradeAccessory
   *
   */
  function tradeAccessory(
    uint256 tokenId_,
    address accessoryTokenAddress_,
    uint256 newTokenId_
  ) external {
    if (imoo.ownerOf(tokenId_) != msg.sender) {
      revert NotTokenOwner();
    }

    (uint256 accessoryTokenId, uint16 accessoryCode) = _detachAccessory(
      tokenId_,
      accessoryTokenAddress_
    );

    _attachAccessory(
      newTokenId_,
      accessoryTokenAddress_,
      accessoryCode,
      uint96(accessoryTokenId)
    );
  }

  /**
   *
   * @dev tradeBackground
   *
   */
  function tradeBackground(uint256 tokenId_, uint256 newTokenId_) public {
    if (imoo.ownerOf(tokenId_) != msg.sender) {
      revert NotTokenOwner();
    }

    Background memory currentBackground = tokenIdToBackground[tokenId_];

    if (currentBackground.backgroundAddress == address(0)) {
      revert NoBackgroundForToken();
    }

    delete tokenIdToBackground[tokenId_];
    _setTokenCoolDown(tokenId_);

    tokenIdToBackground[newTokenId_] = currentBackground;
  }
}

// SPDX-License-Identifier: MIT
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//* IEPS_CT: EPS ComposeThis Interface
//* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// EPS Contracts v2.0.0

pragma solidity 0.8.19;

enum ValueType {
  none,
  characterString,
  number,
  date,
  chainAddress
}

struct AddedTrait {
  string trait;
  ValueType valueType;
  uint256 valueInteger;
  string valueString;
  address valueAddress;
}

interface IEPS_CT {
  event MetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  );

  event ENSReverseRegistrarSet(address ensReverseRegistrarAddress);

  function composeURIFromBaseURI(
    string memory baseString_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeURIFromLookup(
    uint256 baseURIChain_,
    address baseURIContract_,
    uint256 baseURITokenId_,
    AddedTrait[] memory addedTraits_,
    uint256 startImageTag_,
    string[] memory imageTags_
  ) external view returns (string memory composedString_);

  function composeTraitsFromArray(
    AddedTrait[] memory addedTraits_
  ) external view returns (string memory composedImageURL_);

  function composeImageFromBase(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress,
    uint256 id
  ) external view returns (string memory composedImageURL_);

  function composeTraitsAndImage(
    string memory baseImage_,
    uint256 startImageTag_,
    string[] memory imageTags_,
    address contractAddress_,
    uint256 id_,
    AddedTrait[] memory addedTraits_
  )
    external
    view
    returns (string memory composedImageURL_, string memory composedTraits_);

  function triggerMetadataUpdate(
    uint256 chain,
    address tokenContract,
    uint256 tokenId,
    uint256 futureExecutionDate
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IImooXtension is IERC165 {
  function imooTraitTypeValueAndImageTags(
    uint256 tokenId_
  )
    external
    view
    returns (
      string[] memory images_,
      string memory traitType_,
      string memory traitValue_
    );

  function getImagesAndTraitCountIncludingBase()
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IMetadataStore is IERC165 {
  function serveTokenURI(
    uint256 tokenId_
  ) external view returns (string memory);

  function receiveAward(uint256 tokenId_, uint32 awardCode_) external;

  function tokenCooldown(uint256 tokenId_) external view returns (uint256);

  function imooBackground(
    uint256 tokenId_
  ) external view returns (string memory);

  function imooCollection(
    uint256 tokenId_
  ) external pure returns (address imooCollection_);

  function imooMetadataInteger(
    uint256 tokenId_
  ) external pure returns (uint256 imooMetadataInteger_);

  function imooCounter(
    uint256 tokenId_
  ) external pure returns (uint256 imooCounter_);

  function imooColor(uint256 tokenId_) external pure returns (string memory);

  function imooDespair(uint256 tokenId_) external pure returns (string memory);

  function imooRegret(uint256 tokenId_) external pure returns (string memory);

  function imooPerspective(
    uint256 tokenId_
  ) external pure returns (string memory);

  function imooStripes(uint256 tokenId_) external pure returns (string memory);

  function imooFeature(uint256 tokenId_) external pure returns (string memory);

  function imooMonogram(uint256 tokenId_) external pure returns (string memory);

  function imooEthereal(uint256 tokenId_) external pure returns (string memory);

  function imooOutlook() external pure returns (string memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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