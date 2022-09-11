// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// External
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Assets & Layers
import "./lib_constants/AssetContracts.sol";
import "./lib_constants/LayerOrder.sol";
import "./lib_env/Rinkeby.sol";

// Utilities
import "./lib_utilities/UtilAssets.sol";
import "./lib_utilities/UtilTraits.sol";

// Internal Extensions
import "./extensions/Owner.sol";

interface IAssetLibrary {
  function getAsset(uint256) external pure returns (string memory);
}

interface IAnimationUtility {
  function animationURI(uint256 dna) external view returns (bytes memory);
}

// adding comment
contract MergeBears is ERC721A, Owner {
  using Strings for uint256;

  // TODO: Simplify this if possible
  uint256 public randomNumber =
    112251241738492409971660691241763937113569996400635104450295902338183133602781; // default random
  mapping(uint256 => uint256) public tokenIdToDNA;

  // mapping(uint8 => address) public assetContracts;
  address animationUtility;

  constructor() ERC721A("Merge Bears", "MRGBEARS") {
    _owner = msg.sender;

    animationUtility = Rinkeby.Animation;
    
    // pre-link asset contracts
    // assetContracts[AssetContracts.ACCESSORIES] = Rinkeby.ACCESSORIES;
    // assetContracts[AssetContracts.ARMS] = Rinkeby.ARMS;
    // assetContracts[AssetContracts.BELLY] = Rinkeby.BELLY;
    // assetContracts[AssetContracts.CLOTHINGA] = Rinkeby.CLOTHINGA;
    // assetContracts[AssetContracts.CLOTHINGB] = Rinkeby.CLOTHINGB;
    // assetContracts[AssetContracts.EYES] = Rinkeby.EYES;
    // assetContracts[AssetContracts.FACE] = Rinkeby.FACE;
    // assetContracts[AssetContracts.FEET] = Rinkeby.FEET;
    // assetContracts[AssetContracts.FOOTWEAR] = Rinkeby.FOOTWEAR;
    // assetContracts[AssetContracts.HAT] = Rinkeby.HAT;
    // assetContracts[AssetContracts.HEAD] = Rinkeby.HEAD;
    // assetContracts[AssetContracts.JEWELRY] = Rinkeby.JEWELRY;
    // assetContracts[AssetContracts.MOUTH] = Rinkeby.MOUTH;
    // assetContracts[AssetContracts.NOSE] = Rinkeby.NOSE;
    // assetContracts[AssetContracts.SPECIAL_CLOTHING] = Rinkeby.SPECIAL_CLOTHING;
    // assetContracts[AssetContracts.SPECIAL_FACE] = Rinkeby.SPECIAL_FACE;
  }

  function setAnimationUtility(address animationContract) external onlyOwner {
    animationUtility = animationContract;
  }

  // function setLayer(uint8 layer, address layerContract) external onlyOwner {
  //   assetContracts[layer] = layerContract;
  // }

  function mint() external payable {
    tokenIdToDNA[_nextTokenId()] = uint256(
      keccak256(abi.encode(randomNumber, _nextTokenId() + block.number))
    );
    _mint(msg.sender, 1);
  }

  // struct AssetStrings {
  //   string background;
  //   string belly;
  //   string arms;
  //   string feet;
  //   string footwear;
  //   string clothing;
  //   string head;
  //   string eyes;
  //   string mouth;
  //   string nose;
  //   string jewelry;
  //   string hat;
  //   string faceAccessory;
  //   string accessory;
  // }

  // function divWithBackground(string memory dataURI)
  //   internal
  //   pure
  //   returns (string memory)
  // {
  //   return
  //     string.concat(
  //       '<div class="b" style="background-image:url(data:image/png;base64,',
  //       dataURI,
  //       ')"></div>'
  //     );
  // }

  // function animationURI(uint256 tokenId) public view returns (bytes memory) {
  //   uint256 dna = tokenIdToDNA[tokenId];

  //   AssetStrings memory assetStrings;
  //   // AssetStrings memory htmlStrings;

  //   {
  //     assetStrings.background = divWithBackground(
  //       UtilAssets.getAssetBackground(UtilTraits.getOptionBackground(dna))
  //     );
  //   }
  //   {
  //     assetStrings.belly = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.BELLY,
  //         UtilAssets.getAssetBelly(
  //           UtilTraits.getOptionSpecies(dna),
  //           UtilTraits.getOptionBelly(dna)
  //         )
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.arms = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.ARMS,
  //         UtilAssets.getAssetArms(UtilTraits.getOptionSpecies(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.feet = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.FEET,
  //         UtilAssets.getAssetFeet(UtilTraits.getOptionSpecies(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.footwear = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.FOOTWEAR,
  //         UtilAssets.getAssetFootwear(UtilTraits.getOptionFootwear(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.clothing = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.CLOTHING,
  //         UtilAssets.getAssetClothing(UtilTraits.getOptionClothing(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.head = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.HEAD,
  //         UtilAssets.getAssetHead(
  //           UtilTraits.getOptionSpecies(dna),
  //           UtilTraits.getOptionLocale(dna)
  //         )
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.eyes = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.EYES,
  //         UtilAssets.getAssetEyes(UtilTraits.getOptionEyes(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.mouth = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.MOUTH,
  //         UtilAssets.getAssetMouth(UtilTraits.getOptionMouth(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.nose = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.NOSE,
  //         UtilAssets.getAssetNose(UtilTraits.getOptionNose(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.jewelry = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.JEWELRY,
  //         UtilAssets.getAssetJewelry(UtilTraits.getOptionJewelry(dna))
  //       )
  //     );
  //   }
  //   {
  //     assetStrings.hat = divWithBackground(
  //       fetchAssetString(
  //         LayerOrder.HAT,
  //         UtilAssets.getAssetHat(UtilTraits.getOptionHat(dna))
  //       )
  //     );
  //   }
  //   // {
  //   //   assetStrings.faceAccessory = divWithBackground(
  //   //     fetchAssetString(
  //   //       LayerOrder.FACE,
  //   //       UtilAssets.getAssetFaceAccessory(
  //   //         UtilTraits.getOptionFaceAccessory(dna)
  //   //       )
  //   //     )
  //   //   );
  //   // }
  //   // {
  //   //   assetStrings.accessory = divWithBackground(
  //   //     fetchAssetString(
  //   //       LayerOrder.ACCESSORIES,
  //   //       UtilAssets.getAssetAccessories(UtilTraits.getOptionAccessories(dna))
  //   //     )
  //   //   );
  //   // }

  //   // might need to add special face layer for honey drip
  //   // fetchAssetString(LayerOrder.EYES, UtilAssets.getAssetEyes(UtilTraits.getOptionEyes(dna)))
  //   // prettier-ignore
  //   return
  //     abi.encodePacked(
  //       "data:text/html;base64,",
  //       Base64.encode(
  //         abi.encodePacked(
  //           '<html><head><style>body,html{margin:0;display:flex;justify-content:center;align-items:center;background:', assetStrings.background, ';overflow:hidden}.a{width:min(100vw,100vh);height:min(100vw,100vh);position:relative}.b{width:100%;height:100%;background:100%/100%;image-rendering:pixelated;position:absolute}.h{animation:1s ease-in-out infinite d}@keyframes d{0%,100%{transform:translate3d(-1%,0,0)}25%,75%{transform:translate3d(0,2%,0)}50%{transform:translate3d(1%,0,0)}}</style></head><body>',
  //             '<div class="a">',
  //               assetStrings.belly,
  //               assetStrings.arms,
  //               assetStrings.feet,
  //               assetStrings.footwear,
  //               assetStrings.clothing,
  //               '<div class="b h">',
  //               /***/ assetStrings.head,
  //               /***/ assetStrings.eyes,
  //               /***/ assetStrings.mouth,
  //               /***/ assetStrings.nose,
  //               '</div>',
  //               assetStrings.jewelry,
  //               assetStrings.hat,
  //               // assetStrings.faceAccessory,
  //               // assetStrings.accessory,

  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.belly, ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.arms, ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.feet, ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.footwear, ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.clothing, ')"></div>',
  //               // '<div class="b h">',
  //                 // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.head, ')"></div>',
  //                 // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.eyes, ')"></div>',
  //                 // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.mouth, ')"></div>',
  //                 // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.nose, ')"></div>',
  //               // '</div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.jewelry, ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.hat, ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', fetchAssetString(LayerOrder.FACE, UtilAssets.getAssetFaceAccessory(UtilTraits.getOptionFaceAccessory(dna))), ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', fetchAssetString(LayerOrder.SPECIAL_CLOTHING, UtilAssets.getAssetBelly(UtilTraits.getOptionSpecies(dna), UtilTraits.getOptionBelly(dna))), ')"></div>',
  //               // '<div class="b" style="background-image:url(data:image/png;base64,', fetchAssetString(LayerOrder.ACCESSORIES, UtilAssets.getAssetAccessories(UtilTraits.getOptionAccessories(dna))), ')"></div>',
  //             '</div>',
  //           '</body></html>'
  //         )
  //       )
  //     );
  // }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory)
  {
    uint256 dna = tokenIdToDNA[tokenId];
    require(dna != 0, "Not found");

    // prettier-ignore
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              "{",
                '"name":"MergeBears #', tokenId.toString(), '",',
                '"external_url":"https://mergebears.com",',
                '"image":"ipfs://bafybeigfzu63a7q5psnow6l2kvp4xp4n3c76n6amf7whsuenpj5hdxm3eq",'
                '"animation_url":"', IAnimationUtility(animationUtility).animationURI(dna), '"',
              "}"
            )
          )
        )
      );
  }

  // function fetchAssetString(uint8 layer, uint256 assetNum)
  //   internal
  //   view
  //   returns (string memory)
  // {
  //   // iterating in LayerOrder
  //   if (layer == LayerOrder.BELLY) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.BELLY]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.ARMS) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.ARMS]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.FEET) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.FEET]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.FOOTWEAR) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.FOOTWEAR]).getAsset(
  //         assetNum
  //       );
  //     // special logic for clothing since we had to deploy two contracts to fit
  //   } else if (layer == LayerOrder.CLOTHING) {
  //     if (assetNum < 54) {
  //       return
  //         IAssetLibrary(assetContracts[AssetContracts.CLOTHINGA]).getAsset(
  //           assetNum
  //         );
  //     } else {
  //       return
  //         IAssetLibrary(assetContracts[AssetContracts.CLOTHINGB]).getAsset(
  //           assetNum
  //         );
  //     }
  //   } else if (layer == LayerOrder.HEAD) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.HEAD]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.SPECIAL_FACE) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.SPECIAL_FACE]).getAsset(
  //         assetNum
  //       );
  //   } else if (layer == LayerOrder.EYES) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.EYES]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.MOUTH) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.MOUTH]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.NOSE) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.NOSE]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.JEWELRY) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.JEWELRY]).getAsset(
  //         assetNum
  //       );
  //   } else if (layer == LayerOrder.HAT) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.HAT]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.FACE) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.FACE]).getAsset(assetNum);
  //   } else if (layer == LayerOrder.SPECIAL_CLOTHING) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.SPECIAL_CLOTHING]).getAsset(
  //         assetNum
  //       );
  //   } else if (layer == LayerOrder.ACCESSORIES) {
  //     return
  //       IAssetLibrary(assetContracts[AssetContracts.ACCESSORIES]).getAsset(
  //         assetNum
  //       );
  //   }
  //   return "";
  // }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
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

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
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

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
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
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
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

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
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
pragma solidity ^0.8.9;

library AssetContracts {
  uint8 constant ACCESSORIES = 0;
  uint8 constant ARMS = 1;
  uint8 constant BELLY = 2;
  uint8 constant CLOTHINGA = 3;
  uint8 constant CLOTHINGB = 4;
  uint8 constant EYES = 5;
  uint8 constant FACE = 6;
  uint8 constant FEET = 7;
  uint8 constant FOOTWEAR = 8;
  uint8 constant HAT = 9;
  uint8 constant HEAD = 10;
  uint8 constant JEWELRY = 11;
  uint8 constant MOUTH = 12;
  uint8 constant NOSE = 13;
  uint8 constant SPECIAL_CLOTHING = 14;
  uint8 constant SPECIAL_FACE = 15;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LayerOrder {
  uint8 constant BG = 0;
  uint8 constant BELLY = 1;
  uint8 constant ARMS = 2;
  uint8 constant FEET = 3;
  uint8 constant FOOTWEAR = 4;
  uint8 constant CLOTHING = 5;
  uint8 constant HEAD = 6;
  uint8 constant SPECIAL_FACE = 7; // (NOT USED)
  uint8 constant EYES = 8;
  uint8 constant MOUTH = 9;
  uint8 constant NOSE = 10;
  uint8 constant JEWELRY = 11;
  // uint8 constant EARWEAR = 12; (NOT USED)
  uint8 constant HAT = 13;
  uint8 constant FACE = 14;
  uint8 constant SPECIAL_CLOTHING = 15;
  uint8 constant ACCESSORIES = 16;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Rinkeby {
  address constant ACCESSORIES = 0x4acDa10ff43430Ae90eF328555927e9FcFd4904A;
  address constant ARMS = 0xfAD91b20182Ad3907074E0043c1212EaE1F7dfaE;
  address constant BELLY = 0x435B753316d4bfeF7BB755c3f4fAC202aACaA209;
  address constant CLOTHINGA = 0x220d2C51332aafd76261E984e4DA1a43C361A62f;
  address constant CLOTHINGB = 0x8f69858BD253AcedFFd99479C05Aa37305919ec1;
  address constant EYES = 0x13c0B8289bEb260145e981c3201CC2A046F1b83D;
  address constant FACE = 0xcb03ebEabc285616CF4aEa7de1333D53f0789141;
  address constant FEET = 0x03774BA2E684D0872dA02a7da98AfcbebF9E61b2;
  address constant FOOTWEAR = 0x9FAe2ceBDbfDA7EAeEC3647c16FAE2a4e715e5CA;
  address constant HAT = 0x5438ae4D244C4a8eAc6Cf9e64D211c19B5835a91;
  address constant HEAD = 0x31b2E83d6fb1d7b9d5C4cdb5ec295167d3525eFF;
  address constant JEWELRY = 0x1097750D85A2132CAf2DE3be2B97fE56C7DB0bCA;
  address constant MOUTH = 0xF0B8294279a35bE459cfc257776521A5E46Da0d1;
  address constant NOSE = 0xa0F6DdB7B3F114F18073867aE4B740D0AF786721;
  address constant SPECIAL_CLOTHING =
    0xf7C17dB875d8C4ccE301E2c6AF07ab7621204223;
  address constant SPECIAL_FACE = 0x07E0b24A4070bC0e8198154e430dC9B2FB9B4721;

  // Deployed Trait Options Contracts
  address constant OptionAccessories =
    0xBC2D1FF30cF861081521C14f63acBEcB292C6f7A;
  address constant OptionBackground =
    0x8E1ca38c557f12dA069D2cc8dBAD810aa6438b7F;
  address constant OptionBelly = 0x4BE43551f349147f5fF1641Ba59BDB451E016956;
  address constant OptionClothing = 0xA8e7384eF936B9Bd01d165E55919513A7D2A9e22;
  address constant OptionEyes = 0x3a4CF675d3DdfA65aBBE0C5c1bfafA0F7cc69CE8;
  address constant OptionFaceAccessory =
    0xdf038D99d41D3F38803fEC558C5E6401E61dCA91;
  address constant OptionFootwear = 0xA18EFD67AC4383D94B6FD68b627ACF89AdA412fB;
  address constant OptionHat = 0x3dCFAa025847A02b385940284aD803bca5deCD23;
  address constant OptionJewelry = 0x02FEF28743b63E80DEf13f70618a6F2ad2bD65aE;
  address constant OptionLocale = 0x7582801c4e57fd0eA21B9A474E5144C436998C71;
  address constant OptionMouth = 0xc278A76EDB76E0F26e3365354061D12Dadd5950C;
  address constant OptionNose = 0x1A494C15474987A9633B0E21735A5130ff6939C8;
  address constant OptionSpecies = 0x72581cEA263688bE9278507b9361E18dca19c65c;

  // Utility Contracts
  address constant TraitsUtility = 0xD6E6d9A4065a3f4A20e049753d4fcdc5844b644e;
  address constant Animation = 0x1b9aDeACe896a3ab7876D921da59c28FaF5ea6C4;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../lib_constants/trait_options/TraitOptionsBelly.sol";
import "../lib_constants/trait_options/TraitOptionsLocale.sol";
import "../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../lib_assets/AssetMappings.sol";

library UtilAssets {
  function getAssetBackground(uint8 optionBackground)
    internal
    pure
    returns (string memory)
  {
    if (optionBackground == 0) {
      return "red";
    } else if (optionBackground == 1) {
      return "blue";
    } else if (optionBackground == 2) {
      return "green";
    } else if (optionBackground == 3) {
      return "yellow";
    }
    return "red";
  }

  function getAssetBelly(uint8 optionSpecies, uint8 optionBelly)
    internal
    pure
    returns (uint256)
  {
    if (optionSpecies == TraitOptionsSpecies.GOLD_PANDA) {
      return 0; // BELLY_BELLY___GOLD_PANDA
    } else if (
      optionSpecies == TraitOptionsSpecies.PANDA &&
      optionBelly == TraitOptionsBelly.LARGE
    ) {
      return 1; // BELLY_BELLY___LARGE_PANDA;
    } else if (
      optionSpecies == TraitOptionsSpecies.POLAR &&
      optionBelly == TraitOptionsBelly.LARGE
    ) {
      return 2; // BELLY_BELLY___LARGE_POLAR;
    } else if (
      optionSpecies == TraitOptionsSpecies.BLACK &&
      optionBelly == TraitOptionsBelly.LARGE
    ) {
      return 3; // BELLY_BELLY___LARGE;
    } else if (optionSpecies == TraitOptionsSpecies.REVERSE_PANDA) {
      return 4; // BELLY_BELLY___REVERSE_PANDA;
    } else if (
      optionSpecies == TraitOptionsSpecies.PANDA &&
      optionBelly == TraitOptionsBelly.SMALL
    ) {
      return 5; // BELLY_BELLY___SMALL_PANDA;
    } else if (
      optionSpecies == TraitOptionsSpecies.POLAR &&
      optionBelly == TraitOptionsBelly.SMALL
    ) {
      return 6; // BELLY_BELLY___SMALL_POLAR;
    } else if (
      optionSpecies == TraitOptionsSpecies.BLACK &&
      optionBelly == TraitOptionsBelly.SMALL
    ) {
      return 7; // BELLY_BELLY___SMALL;
    }
    return 2; // BELLY_BELLY___LARGE_POLAR;
  }

  function getAssetArms(uint8 optionSpecies) internal pure returns (uint256) {
    if (
      optionSpecies == TraitOptionsSpecies.POLAR ||
      optionSpecies == TraitOptionsSpecies.REVERSE_PANDA
    ) {
      return 0; // ARMS_ARMS___AVERAGE_POLAR
    } else if (optionSpecies == TraitOptionsSpecies.GOLD_PANDA) {
      return 2; // ARMS_ARMS___GOLD_PANDA;
    }
    return 1; // ARMS_ARMS___AVERAGE; (black)
  }

  function getAssetFeet(uint8 optionSpecies) internal pure returns (uint256) {
    if (optionSpecies == TraitOptionsSpecies.GOLD_PANDA) {
      return 0; // FEET_FEET___GOLD_PANDA
    } else if (
      optionSpecies == TraitOptionsSpecies.POLAR ||
      optionSpecies == TraitOptionsSpecies.REVERSE_PANDA
    ) {
      return 1; // FEET_FEET___SMALL_PANDA; (polar or inverse panda)
    } else if (
      optionSpecies == TraitOptionsSpecies.BLACK ||
      optionSpecies == TraitOptionsSpecies.PANDA
    ) {
      return 2; // FEET_FEET___SMALL; (black or panda)
    }
    return 2; // FEET_FEET___SMALL; (black)
  }

  function getAssetHead(uint8 optionSpecies, uint8 optionLocale)
    internal
    pure
    returns (uint256)
  {
    // GOLD PANDA
    if (optionSpecies == TraitOptionsSpecies.GOLD_PANDA) {
      return AssetMappingsHead.HEAD_HEAD___GOLD_PANDA;
    }
    // REVERSE PANDA
    if (optionSpecies == TraitOptionsSpecies.REVERSE_PANDA) {
      return AssetMappingsHead.HEAD_HEAD___REVERSE_PANDA_BEAR;
    }
    // PANDA
    if (optionSpecies == TraitOptionsSpecies.PANDA) {
      if (optionLocale == TraitOptionsLocale.NORTH_AMERICAN) {
        return AssetMappingsHead.HEAD_HEAD___ALASKAN_PANDA_BEAR;
      } else if (optionLocale == TraitOptionsLocale.SOUTH_AMERICAN) {
        return AssetMappingsHead.HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR;
      } else if (optionLocale == TraitOptionsLocale.ASIAN) {
        return AssetMappingsHead.HEAD_HEAD___HIMALAYAN_PANDA_BEAR;
      } else if (optionLocale == TraitOptionsLocale.EUROPEAN) {
        return AssetMappingsHead.HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR;
      }
    }
    // POLAR
    if (optionSpecies == TraitOptionsSpecies.POLAR) {
      if (optionLocale == TraitOptionsLocale.NORTH_AMERICAN) {
        return AssetMappingsHead.HEAD_HEAD___ALASKAN_POLAR_BEAR;
      } else if (optionLocale == TraitOptionsLocale.SOUTH_AMERICAN) {
        return AssetMappingsHead.HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR;
      } else if (optionLocale == TraitOptionsLocale.ASIAN) {
        return AssetMappingsHead.HEAD_HEAD___HIMALAYAN_POLAR_BEAR;
      } else if (optionLocale == TraitOptionsLocale.EUROPEAN) {
        return AssetMappingsHead.HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR;
      }
    }
    // BLACK
    if (optionSpecies == TraitOptionsSpecies.BLACK) {
      if (optionLocale == TraitOptionsLocale.NORTH_AMERICAN) {
        return AssetMappingsHead.HEAD_HEAD___ALASKAN_BLACK_BEAR;
      } else if (optionLocale == TraitOptionsLocale.SOUTH_AMERICAN) {
        return AssetMappingsHead.HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR;
      } else if (optionLocale == TraitOptionsLocale.ASIAN) {
        return AssetMappingsHead.HEAD_HEAD___HIMALAYAN_BLACK_BEAR;
      } else if (optionLocale == TraitOptionsLocale.EUROPEAN) {
        return AssetMappingsHead.HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR;
      }
    }

    // return BLACK ALASKAN as default
    return AssetMappingsHead.HEAD_HEAD___ALASKAN_BLACK_BEAR;
  }

  function getAssetEyes(uint8 optionEyes) internal pure returns (uint256) {
    // since eye options are 1:1 with assets and align perfectly, just convert to uint256
    return uint256(optionEyes);
  }

  function getAssetMouth(uint8 optionMouth) internal pure returns (uint256) {
    // since mouth options are 1:1 with assets and align perfectly, just convert to uint256
    return uint256(optionMouth);
  }

  function getAssetNose(uint8 optionNose) internal pure returns (uint256) {
    // since nose options are 1:1 with assets and align perfectly, just convert to uint256
    return uint256(optionNose);
  }

  function getAssetFootwear(uint8 optionFootwear)
    internal
    pure
    returns (uint256)
  {
    return uint256(optionFootwear);
  }

  function getAssetHat(uint8 optionHat) internal pure returns (uint256) {
    return uint256(optionHat);
  }

  function getAssetClothing(uint8 optionClothing)
    internal
    pure
    returns (uint256)
  {
    return uint256(optionClothing);
  }

  function getAssetJewelry(uint8 optionJewelry)
    internal
    pure
    returns (uint256)
  {
    return uint256(optionJewelry);
  }

  function getAssetAccessories(uint8 optionAccessory)
    internal
    pure
    returns (uint256)
  {
    return uint256(optionAccessory);
  }

  function getAssetFaceAccessory(uint8 optionFaceAccessory)
    internal
    pure
    returns (uint256)
  {
    return uint256(optionFaceAccessory);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../lib_constants/TraitDefs.sol";
import "../lib_constants/trait_options/TraitOptionsBackground.sol";
import "../lib_constants/trait_options/TraitOptionsBelly.sol";
import "../lib_constants/trait_options/TraitOptionsLocale.sol";
import "../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../lib_constants/trait_options/TraitOptionsEyes.sol";
import "../lib_constants/trait_options/TraitOptionsMouth.sol";
import "../lib_constants/trait_options/TraitOptionsNose.sol";
import "../lib_constants/trait_options/TraitOptionsFootwear.sol";
import "../lib_constants/trait_options/TraitOptionsHat.sol";
import "../lib_constants/trait_options/TraitOptionsClothing.sol";
import "../lib_constants/trait_options/TraitOptionsJewelry.sol";
import "../lib_constants/trait_options/TraitOptionsAccessories.sol";
import "../lib_constants/trait_options/TraitOptionsFaceAccessory.sol";

library UtilTraits {
  function getGene(uint8 traitDef, uint256 dna) internal pure returns (uint16) {
    // type(uint16).max
    // right shift traitDef * 16, then bitwise & with the max 16 bit number
    return uint16((dna >> (traitDef * 16)) & uint256(type(uint16).max));
  }

  function getOptionBackground(uint256 dna) internal pure returns (uint8) {
    uint16 bg = getGene(TraitDefs.BACKGROUND, dna);
    uint16 variant = bg % 4;

    if (variant == 0) {
      return TraitOptionsBackground.RED;
    } else if (variant == 1) {
      return TraitOptionsBackground.BLUE;
    } else if (variant == 2) {
      return TraitOptionsBackground.GREEN;
    } else if (variant == 3) {
      return TraitOptionsBackground.YELLOW;
    }
    return TraitOptionsBackground.RED;
  }

  function getOptionSpecies(uint256 dna) internal pure returns (uint8) {
    uint16 species = getGene(TraitDefs.SPECIES, dna);
    uint16 variant = species % 5;

    if (variant == 0) {
      return TraitOptionsSpecies.BLACK;
    } else if (variant == 1) {
      return TraitOptionsSpecies.POLAR;
    } else if (variant == 2) {
      return TraitOptionsSpecies.PANDA;
    } else if (variant == 3) {
      return TraitOptionsSpecies.REVERSE_PANDA;
    } else if (variant == 4) {
      return TraitOptionsSpecies.GOLD_PANDA;
    }
    return TraitOptionsSpecies.BLACK;
  }

  function getOptionBelly(uint256 dna) internal pure returns (uint8) {
    uint16 belly = getGene(TraitDefs.BELLY, dna);
    uint16 variant = belly % 5;

    if (variant == 0) {
      return TraitOptionsBelly.LARGE;
    } else if (variant == 1) {
      return TraitOptionsBelly.SMALL;
    }
    return TraitOptionsBelly.LARGE;
  }

  function getOptionLocale(uint256 dna) internal pure returns (uint8) {
    uint16 locale = getGene(TraitDefs.LOCALE, dna);
    uint16 variant = locale % 4;

    if (variant == 0) {
      return TraitOptionsLocale.NORTH_AMERICAN;
    } else if (variant == 1) {
      return TraitOptionsLocale.SOUTH_AMERICAN;
    } else if (variant == 2) {
      return TraitOptionsLocale.ASIAN;
    } else if (variant == 3) {
      return TraitOptionsLocale.EUROPEAN;
    }
    return TraitOptionsLocale.NORTH_AMERICAN;
  }

  function getOptionEyes(uint256 dna) internal pure returns (uint8) {
    uint16 eyes = getGene(TraitDefs.EYES, dna);
    uint16 variant = eyes % 20;

    if (variant == 0) {
      return TraitOptionsEyes.ANNOYED_BLUE_EYES;
    } else if (variant == 1) {
      return TraitOptionsEyes.ANNOYED_BROWN_EYES;
    } else if (variant == 2) {
      return TraitOptionsEyes.ANNOYED_GREEN_EYES;
    } else if (variant == 3) {
      return TraitOptionsEyes.BEADY_EYES;
    } else if (variant == 4) {
      return TraitOptionsEyes.BEADY_RED_EYES;
    } else if (variant == 5) {
      return TraitOptionsEyes.BORED_BLUE_EYES;
    } else if (variant == 6) {
      return TraitOptionsEyes.BORED_BROWN_EYES;
    } else if (variant == 7) {
      return TraitOptionsEyes.BORED_GREEN_EYES;
    } else if (variant == 8) {
      return TraitOptionsEyes.DILATED_BLUE_EYES;
    } else if (variant == 9) {
      return TraitOptionsEyes.DILATED_BROWN_EYES;
    } else if (variant == 10) {
      return TraitOptionsEyes.DILATED_GREEN_EYES;
    } else if (variant == 11) {
      return TraitOptionsEyes.NEUTRAL_BLUE_EYES;
    } else if (variant == 12) {
      return TraitOptionsEyes.NEUTRAL_BROWN_EYES;
    } else if (variant == 13) {
      return TraitOptionsEyes.NEUTRAL_GREEN_EYES;
    } else if (variant == 14) {
      return TraitOptionsEyes.SQUARE_BLUE_EYES;
    } else if (variant == 15) {
      return TraitOptionsEyes.SQUARE_BROWN_EYES;
    } else if (variant == 16) {
      return TraitOptionsEyes.SQUARE_GREEN_EYES;
    } else if (variant == 17) {
      return TraitOptionsEyes.SURPRISED_BLUE_EYES;
    } else if (variant == 18) {
      return TraitOptionsEyes.SURPRISED_BROWN_EYES;
    } else if (variant == 19) {
      return TraitOptionsEyes.SURPRISED_GREEN_EYES;
    }
    return TraitOptionsEyes.BORED_BLUE_EYES;
  }

  function getOptionMouth(uint256 dna) internal pure returns (uint8) {
    uint16 mouth = getGene(TraitDefs.MOUTH, dna);
    uint16 variant = mouth % 18;

    if (variant == 0) {
      return TraitOptionsMouth.ANXIOUS;
    } else if (variant == 1) {
      return TraitOptionsMouth.BABY_TOOTH_SMILE;
    } else if (variant == 2) {
      return TraitOptionsMouth.BLUE_LIPSTICK;
    } else if (variant == 3) {
      return TraitOptionsMouth.FULL_MOUTH;
    } else if (variant == 4) {
      return TraitOptionsMouth.MISSING_BOTTOM_TOOTH;
    } else if (variant == 5) {
      return TraitOptionsMouth.NERVOUS_MOUTH;
    } else if (variant == 6) {
      return TraitOptionsMouth.OPEN_MOUTH;
    } else if (variant == 7) {
      return TraitOptionsMouth.PINK_LIPSTICK;
    } else if (variant == 8) {
      return TraitOptionsMouth.RED_LIPSTICK;
    } else if (variant == 9) {
      return TraitOptionsMouth.SAD_FROWN;
    } else if (variant == 10) {
      return TraitOptionsMouth.SMILE_WITH_BUCK_TEETH;
    } else if (variant == 11) {
      return TraitOptionsMouth.SMILE_WITH_PIPE;
    } else if (variant == 12) {
      return TraitOptionsMouth.SMILE;
    } else if (variant == 13) {
      return TraitOptionsMouth.SMIRK;
    } else if (variant == 14) {
      return TraitOptionsMouth.TINY_FROWN;
    } else if (variant == 15) {
      return TraitOptionsMouth.TINY_SMILE;
    } else if (variant == 16) {
      return TraitOptionsMouth.TONGUE_OUT;
    } else if (variant == 17) {
      return TraitOptionsMouth.TOOTHY_SMILE;
    }
    return TraitOptionsMouth.SMILE;
  }

  function getOptionNose(uint256 dna) internal pure returns (uint8) {
    uint16 nose = getGene(TraitDefs.NOSE, dna);
    uint16 variant = nose % 10;

    if (variant == 0) {
      return TraitOptionsNose.BLACK_NOSTRILS_SNIFFER;
    } else if (variant == 1) {
      return TraitOptionsNose.BLACK_SNIFFER;
    } else if (variant == 2) {
      return TraitOptionsNose.BLUE_NOSTRILS_SNIFFER;
    } else if (variant == 3) {
      return TraitOptionsNose.PINK_NOSTRILS_SNIFFER;
    } else if (variant == 4) {
      return TraitOptionsNose.RUNNY_BLACK_NOSE;
    } else if (variant == 5) {
      return TraitOptionsNose.SMALL_BLUE_SNIFFER;
    } else if (variant == 6) {
      return TraitOptionsNose.SMALL_PINK_NOSE;
    } else if (variant == 7) {
      return TraitOptionsNose.WIDE_BLACK_SNIFFER;
    } else if (variant == 8) {
      return TraitOptionsNose.WIDE_BLUE_SNIFFER;
    } else if (variant == 9) {
      return TraitOptionsNose.WIDE_PINK_SNIFFER;
    }
    return TraitOptionsNose.BLACK_NOSTRILS_SNIFFER;
  }

  // RULES FROM SPECIES
  function getOptionFootwear(uint256 dna) internal pure returns (uint8) {
    uint16 footwear = getGene(TraitDefs.FOOTWEAR, dna);
    uint16 variant = footwear % 29;

    if (variant == 0) {
      return TraitOptionsFootwear.BLACK_GLADIATOR_SANDALS;
    } else if (variant == 1) {
      return TraitOptionsFootwear.BLACK_SNEAKERS;
    } else if (variant == 2) {
      return TraitOptionsFootwear.BLACK_AND_BLUE_SNEAKERS;
    } else if (variant == 3) {
      return TraitOptionsFootwear.BLACK_AND_WHITE_SNEAKERS;
    } else if (variant == 4) {
      return TraitOptionsFootwear.BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE;
    } else if (variant == 5) {
      return TraitOptionsFootwear.BLUE_CROCS;
    } else if (variant == 6) {
      return TraitOptionsFootwear.BLUE_FLIP_FLOPS;
    } else if (variant == 7) {
      return TraitOptionsFootwear.BLUE_HIGH_HEELS;
    } else if (variant == 8) {
      return TraitOptionsFootwear.BLUE_SNEAKERS;
    } else if (variant == 9) {
      return TraitOptionsFootwear.BLUE_TOENAIL_POLISH;
    } else if (variant == 10) {
      return TraitOptionsFootwear.BLUE_WORK_BOOTS;
    } else if (variant == 11) {
      return TraitOptionsFootwear.BLUE_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (variant == 12) {
      return TraitOptionsFootwear.PINK_HIGH_HEELS;
    } else if (variant == 13) {
      return TraitOptionsFootwear.PINK_TOENAIL_POLISH;
    } else if (variant == 14) {
      return TraitOptionsFootwear.PINK_WORK_BOOTS;
    } else if (variant == 15) {
      return TraitOptionsFootwear.RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE;
    } else if (variant == 16) {
      return TraitOptionsFootwear.RED_CROCS;
    } else if (variant == 17) {
      return TraitOptionsFootwear.RED_FLIP_FLOPS;
    } else if (variant == 18) {
      return TraitOptionsFootwear.RED_HIGH_HEELS;
    } else if (variant == 19) {
      return TraitOptionsFootwear.RED_TOENAIL_POLISH;
    } else if (variant == 20) {
      return TraitOptionsFootwear.RED_WORK_BOOTS;
    } else if (variant == 21) {
      return TraitOptionsFootwear.RED_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (variant == 22) {
      return TraitOptionsFootwear.STEPPED_IN_A_PUMPKIN;
    } else if (variant == 23) {
      return TraitOptionsFootwear.TAN_COWBOY_BOOTS;
    } else if (variant == 24) {
      return TraitOptionsFootwear.TAN_WORK_BOOTS;
    } else if (variant == 25) {
      return TraitOptionsFootwear.WATERMELON_SHOES;
    } else if (variant == 26) {
      return TraitOptionsFootwear.WHITE_SNEAKERS;
    } else if (variant == 27) {
      return TraitOptionsFootwear.WHITE_AND_RED_SNEAKERS;
    } else if (variant == 28) {
      return TraitOptionsFootwear.YELLOW_RAIN_BOOTS;
    }
    return TraitOptionsFootwear.BLACK_SNEAKERS;
  }

  function getOptionHat(uint256 dna) internal pure returns (uint8) {
    uint16 hat = getGene(TraitDefs.HAT, dna);
    uint16 variant = hat % 39;

    if (variant == 0) {
      return TraitOptionsHat.ASTRONAUT_HELMET;
    } else if (variant == 1) {
      return TraitOptionsHat.BAG_OF_ETHEREUM;
    } else if (variant == 2) {
      return TraitOptionsHat.BLACK_BOWLER_HAT;
    } else if (variant == 3) {
      return TraitOptionsHat.BLACK_TOP_HAT;
    } else if (variant == 4) {
      return TraitOptionsHat.BLACK_AND_WHITE_STRIPED_JAIL_CAP;
    } else if (variant == 5) {
      return TraitOptionsHat.BLACK_WITH_BLUE_HEADPHONES;
    } else if (variant == 6) {
      return TraitOptionsHat.BLACK_WITH_BLUE_TOP_HAT;
    } else if (variant == 7) {
      return TraitOptionsHat.BLUE_BASEBALL_CAP;
    } else if (variant == 8) {
      return TraitOptionsHat.BLUE_UMBRELLA_HAT;
    } else if (variant == 9) {
      return TraitOptionsHat.BULB_HELMET;
    } else if (variant == 10) {
      return TraitOptionsHat.CHERRY_ON_TOP;
    } else if (variant == 11) {
      return TraitOptionsHat.CRYPTO_INFLUENCER_BLUEBIRD;
    } else if (variant == 12) {
      return TraitOptionsHat.GIANT_SUNFLOWER;
    } else if (variant == 13) {
      return TraitOptionsHat.GOLD_CHALICE;
    } else if (variant == 14) {
      return TraitOptionsHat.GRADUATION_CAP_WITH_BLUE_TASSEL;
    } else if (variant == 15) {
      return TraitOptionsHat.GRADUATION_CAP_WITH_RED_TASSEL;
    } else if (variant == 16) {
      return TraitOptionsHat.GREEN_GOO;
    } else if (variant == 17) {
      return TraitOptionsHat.NODE_OPERATORS_YELLOW_HARDHAT;
    } else if (variant == 18) {
      return TraitOptionsHat.NONE;
    } else if (variant == 19) {
      return TraitOptionsHat.PINK_BUTTERFLY;
    } else if (variant == 20) {
      return TraitOptionsHat.PINK_SUNHAT;
    } else if (variant == 21) {
      return TraitOptionsHat.POLICE_CAP;
    } else if (variant == 22) {
      return TraitOptionsHat.RED_ASTRONAUT_HELMET;
    } else if (variant == 23) {
      return TraitOptionsHat.RED_BASEBALL_CAP;
    } else if (variant == 24) {
      return TraitOptionsHat.RED_DEFI_WIZARD_HAT;
    } else if (variant == 25) {
      return TraitOptionsHat.RED_SHOWER_CAP;
    } else if (variant == 26) {
      return TraitOptionsHat.RED_SPORTS_HELMET;
    } else if (variant == 27) {
      return TraitOptionsHat.RED_UMBRELLA_HAT;
    } else if (variant == 28) {
      return TraitOptionsHat.TAN_COWBOY_HAT;
    } else if (variant == 29) {
      return TraitOptionsHat.TAN_SUNHAT;
    } else if (variant == 30) {
      return TraitOptionsHat.TINY_BLUE_HAT;
    } else if (variant == 31) {
      return TraitOptionsHat.TINY_RED_HAT;
    } else if (variant == 32) {
      return TraitOptionsHat.WHITE_BOWLER_HAT;
    } else if (variant == 33) {
      return TraitOptionsHat.WHITE_TOP_HAT;
    } else if (variant == 34) {
      return TraitOptionsHat.WHITE_AND_RED_BASEBALL_CAP;
    } else if (variant == 35) {
      return TraitOptionsHat.WHITE_WITH_RED_HEADPHONES;
    } else if (variant == 36) {
      return TraitOptionsHat.WHITE_WITH_RED_TOP_HAT;
    } else if (variant == 37) {
      return TraitOptionsHat.SHIRT_BLACK_AND_BLUE_BASEBALL_CAP;
    } else if (variant == 38) {
      return TraitOptionsHat.SHIRT_RED_UMBRELLA_HAT;
    }
    return TraitOptionsHat.BLACK_BOWLER_HAT;
  }

  function getOptionClothing(uint256 dna) internal pure returns (uint8) {
    uint16 clothes = getGene(TraitDefs.CLOTHING, dna);
    uint16 variant = clothes % 106;

    if (variant == 0) {
      return TraitOptionsClothing.BLUE_ERC20_SHIRT;
    } else if (variant == 1) {
      return TraitOptionsClothing.BLUE_FOX_WALLET_TANKTOP;
    } else if (variant == 2) {
      return TraitOptionsClothing.BLUE_GRADIENT_DIAMOND_SHIRT;
    } else if (variant == 3) {
      return TraitOptionsClothing.BLUE_LINK_SHIRT;
    } else if (variant == 4) {
      return TraitOptionsClothing.BLUE_WEB3_SAFE_SHIRT;
    } else if (variant == 5) {
      return TraitOptionsClothing.RED_ERC20_SHIRT;
    } else if (variant == 6) {
      return TraitOptionsClothing.RED_FOX_WALLET_TANKTOP;
    } else if (variant == 7) {
      return TraitOptionsClothing.RED_GRADIENT_DIAMOND_SHIRT;
    } else if (variant == 8) {
      return TraitOptionsClothing.RED_LINK_SHIRT;
    } else if (variant == 9) {
      return TraitOptionsClothing.RED_WEB3_SAFE_SHIRT;
    } else if (variant == 10) {
      return TraitOptionsClothing.ADAMS_LEAF;
    } else if (variant == 11) {
      return TraitOptionsClothing.BLACK_BELT;
    } else if (variant == 12) {
      return TraitOptionsClothing.BLACK_LEATHER_JACKET;
    } else if (variant == 13) {
      return TraitOptionsClothing.BLACK_TUXEDO;
    } else if (variant == 14) {
      return TraitOptionsClothing.BLACK_AND_BLUE_STRIPED_BIB;
    } else if (variant == 15) {
      return TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
    } else if (variant == 16) {
      return TraitOptionsClothing.BLACK_WITH_BLUE_DRESS;
    } else if (variant == 17) {
      return TraitOptionsClothing.BLACK_WITH_BLUE_STRIPES_TANKTOP;
    } else if (variant == 18) {
      return TraitOptionsClothing.BLUE_BEAR_LOVE_SHIRT;
    } else if (variant == 19) {
      return TraitOptionsClothing.BLUE_BEAR_MARKET_SHIRT;
    } else if (variant == 20) {
      return TraitOptionsClothing.BLUE_BULL_MARKET_SHIRT;
    } else if (variant == 21) {
      return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_DOTS;
    } else if (variant == 22) {
      return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_LACE;
    } else if (variant == 23) {
      return TraitOptionsClothing.BLUE_DRESS;
    } else if (variant == 24) {
      return TraitOptionsClothing.BLUE_ETH_SHIRT;
    } else if (variant == 25) {
      return TraitOptionsClothing.BLUE_FANNY_PACK;
    } else if (variant == 26) {
      return TraitOptionsClothing.BLUE_HOOLA_HOOP;
    } else if (variant == 27) {
      return TraitOptionsClothing.BLUE_HOOT_SHIRT;
    } else if (variant == 28) {
      return TraitOptionsClothing.BLUE_JESTERS_COLLAR;
    } else if (variant == 29) {
      return TraitOptionsClothing.BLUE_KNIT_SWEATER;
    } else if (variant == 30) {
      return TraitOptionsClothing.BLUE_LEG_WARMERS;
    } else if (variant == 31) {
      return TraitOptionsClothing.BLUE_OVERALLS;
    } else if (variant == 32) {
      return TraitOptionsClothing.BLUE_PINK_UNICORN_DEX_TANKTOP;
    } else if (variant == 33) {
      return TraitOptionsClothing.BLUE_PONCHO;
    } else if (variant == 34) {
      return TraitOptionsClothing.BLUE_PORTAL_SHIRT;
    } else if (variant == 35) {
      return TraitOptionsClothing.BLUE_PROOF_OF_STAKE_SHIRT;
    } else if (variant == 36) {
      return TraitOptionsClothing.BLUE_PROOF_OF_WORK_SHIRT;
    } else if (variant == 37) {
      return TraitOptionsClothing.BLUE_PUFFY_VEST;
    } else if (variant == 38) {
      return TraitOptionsClothing.BLUE_REKT_SHIRT;
    } else if (variant == 39) {
      return TraitOptionsClothing.BLUE_RASPBERRY_PI_NODE_TANKTOP;
    } else if (variant == 40) {
      return TraitOptionsClothing.BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
    } else if (variant == 41) {
      return TraitOptionsClothing.BLUE_SKIRT;
    } else if (variant == 42) {
      return TraitOptionsClothing.BLUE_STRIPED_NECKTIE;
    } else if (variant == 43) {
      return TraitOptionsClothing.BLUE_SUIT_JACKET_WITH_GOLD_TIE;
    } else if (variant == 44) {
      return TraitOptionsClothing.BLUE_TANKTOP;
    } else if (variant == 45) {
      return TraitOptionsClothing.BLUE_TOGA;
    } else if (variant == 46) {
      return TraitOptionsClothing.BLUE_TUBE_TOP;
    } else if (variant == 47) {
      return TraitOptionsClothing.BLUE_VEST;
    } else if (variant == 48) {
      return TraitOptionsClothing.BLUE_WAGMI_SHIRT;
    } else if (variant == 49) {
      return TraitOptionsClothing.BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
    } else if (variant == 50) {
      return TraitOptionsClothing.BLUE_WITH_PINK_AND_GREEN_DRESS;
    } else if (variant == 51) {
      return TraitOptionsClothing.BLUE_WITH_WHITE_APRON;
    } else if (variant == 52) {
      return TraitOptionsClothing.BORAT_SWIMSUIT;
    } else if (variant == 53) {
      return TraitOptionsClothing.BUTTERFLY_WINGS;
    } else if (variant == 54) {
      return TraitOptionsClothing.DUSTY_MAROON_MINERS_GARB;
    } else if (variant == 55) {
      return TraitOptionsClothing.DUSTY_NAVY_MINERS_GARB;
    } else if (variant == 56) {
      return TraitOptionsClothing.GRASS_SKIRT;
    } else if (variant == 57) {
      return TraitOptionsClothing.LEDERHOSEN;
    } else if (variant == 58) {
      return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
    } else if (variant == 59) {
      return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_RED_CAPE;
    } else if (variant == 60) {
      return TraitOptionsClothing.NAKEY;
    } else if (variant == 61) {
      return TraitOptionsClothing.NODE_OPERATORS_VEST;
    } else if (variant == 62) {
      return TraitOptionsClothing.ORANGE_INFLATABLE_WATER_WINGS;
    } else if (variant == 63) {
      return TraitOptionsClothing.ORANGE_PRISON_UNIFORM;
    } else if (variant == 64) {
      return TraitOptionsClothing.PINK_TUTU;
    } else if (variant == 65) {
      return TraitOptionsClothing.PINK_AND_TEAL_DEFI_LENDING_TANKTOP;
    } else if (variant == 66) {
      return TraitOptionsClothing.RED_BEAR_LOVE_SHIRT;
    } else if (variant == 67) {
      return TraitOptionsClothing.RED_BEAR_MARKET_SHIRT;
    } else if (variant == 68) {
      return TraitOptionsClothing.RED_BULL_MARKET_SHIRT;
    } else if (variant == 69) {
      return TraitOptionsClothing.RED_DRESS_WITH_WHITE_DOTS;
    } else if (variant == 70) {
      return TraitOptionsClothing.RED_DRESS_WITH_WHITE_LACE;
    } else if (variant == 71) {
      return TraitOptionsClothing.RED_DRESS;
    } else if (variant == 72) {
      return TraitOptionsClothing.RED_ETH_SHIRT;
    } else if (variant == 73) {
      return TraitOptionsClothing.RED_FANNY_PACK;
    } else if (variant == 74) {
      return TraitOptionsClothing.RED_HOOLA_HOOP;
    } else if (variant == 75) {
      return TraitOptionsClothing.RED_HOOT_SHIRT;
    } else if (variant == 76) {
      return TraitOptionsClothing.RED_JESTERS_COLLAR;
    } else if (variant == 77) {
      return TraitOptionsClothing.RED_KNIT_SWEATER;
    } else if (variant == 78) {
      return TraitOptionsClothing.RED_LEG_WARMERS;
    } else if (variant == 79) {
      return TraitOptionsClothing.RED_OVERALLS;
    } else if (variant == 80) {
      return TraitOptionsClothing.RED_PINK_UNICORN_DEX_TANKTOP;
    } else if (variant == 81) {
      return TraitOptionsClothing.RED_PONCHO;
    } else if (variant == 82) {
      return TraitOptionsClothing.RED_PORTAL_SHIRT;
    } else if (variant == 83) {
      return TraitOptionsClothing.RED_PROOF_OF_STAKE_SHIRT;
    } else if (variant == 84) {
      return TraitOptionsClothing.RED_PROOF_OF_WORK_SHIRT;
    } else if (variant == 85) {
      return TraitOptionsClothing.RED_PUFFY_VEST;
    } else if (variant == 86) {
      return TraitOptionsClothing.RED_REKT_SHIRT;
    } else if (variant == 87) {
      return TraitOptionsClothing.RED_RASPBERRY_PI_NODE_TANKTOP;
    } else if (variant == 88) {
      return TraitOptionsClothing.RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
    } else if (variant == 89) {
      return TraitOptionsClothing.RED_SKIRT;
    } else if (variant == 90) {
      return TraitOptionsClothing.RED_STRIPED_NECKTIE;
    } else if (variant == 91) {
      return TraitOptionsClothing.RED_SUIT_JACKET_WITH_GOLD_TIE;
    } else if (variant == 92) {
      return TraitOptionsClothing.RED_TANKTOP;
    } else if (variant == 93) {
      return TraitOptionsClothing.RED_TOGA;
    } else if (variant == 94) {
      return TraitOptionsClothing.RED_TUBE_TOP;
    } else if (variant == 95) {
      return TraitOptionsClothing.RED_VEST;
    } else if (variant == 96) {
      return TraitOptionsClothing.RED_WAGMI_SHIRT;
    } else if (variant == 97) {
      return TraitOptionsClothing.RED_WITH_PINK_AND_GREEN_DRESS;
    } else if (variant == 98) {
      return TraitOptionsClothing.RED_WITH_WHITE_APRON;
    } else if (variant == 99) {
      return TraitOptionsClothing.RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
    } else if (variant == 100) {
      return TraitOptionsClothing.TAN_CARGO_SHORTS;
    } else if (variant == 101) {
      return TraitOptionsClothing.VAMPIRE_BAT_WINGS;
    } else if (variant == 102) {
      return TraitOptionsClothing.WHITE_TUXEDO;
    } else if (variant == 103) {
      return TraitOptionsClothing.WHITE_AND_RED_STRIPED_BIB;
    } else if (variant == 104) {
      return TraitOptionsClothing.WHITE_WITH_RED_DRESS;
    } else if (variant == 105) {
      return TraitOptionsClothing.WHITE_WITH_RED_STRIPES_TANKTOP;
    }
    return TraitOptionsClothing.RED_ETH_SHIRT;
  }

  // JEWELRY
  function getOptionJewelry(uint256 dna) internal pure returns (uint8) {
    uint16 jewelry = getGene(TraitDefs.JEWELRY, dna);
    uint16 variant = jewelry % 18;

    if (variant == 0) {
      return TraitOptionsJewelry.BLUE_BRACELET;
    } else if (variant == 1) {
      return TraitOptionsJewelry.BLUE_SPORTS_WATCH;
    } else if (variant == 2) {
      return
        TraitOptionsJewelry.DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION;
    } else if (variant == 3) {
      return TraitOptionsJewelry.DOUBLE_GOLD_CHAINS;
    } else if (variant == 4) {
      return TraitOptionsJewelry.DOUBLE_SILVER_CHAINS;
    } else if (variant == 5) {
      return TraitOptionsJewelry.GOLD_CHAIN_WITH_MEDALLION;
    } else if (variant == 6) {
      return TraitOptionsJewelry.GOLD_CHAIN_WITH_RED_RUBY;
    } else if (variant == 7) {
      return TraitOptionsJewelry.GOLD_CHAIN;
    } else if (variant == 8) {
      return TraitOptionsJewelry.GOLD_STUD_EARRINGS;
    } else if (variant == 9) {
      return TraitOptionsJewelry.GOLD_WATCH_ON_LEFT_WRIST;
    } else if (variant == 10) {
      return TraitOptionsJewelry.LEFT_HAND_GOLD_RINGS;
    } else if (variant == 11) {
      return TraitOptionsJewelry.LEFT_HAND_SILVER_RINGS;
    } else if (variant == 12) {
      return TraitOptionsJewelry.RED_BRACELET;
    } else if (variant == 13) {
      return TraitOptionsJewelry.RED_SPORTS_WATCH;
    } else if (variant == 14) {
      return TraitOptionsJewelry.SILVER_CHAIN_WITH_MEDALLION;
    } else if (variant == 15) {
      return TraitOptionsJewelry.SILVER_CHAIN_WITH_RED_RUBY;
    } else if (variant == 16) {
      return TraitOptionsJewelry.SILVER_CHAIN;
    } else if (variant == 17) {
      return TraitOptionsJewelry.SILVER_STUD_EARRINGS;
    }

    return TraitOptionsJewelry.GOLD_CHAIN;
  }

  // Accessories
  function getOptionAccessories(uint256 dna) internal pure returns (uint8) {
    uint16 accessory = getGene(TraitDefs.ACCESSORIES, dna);
    uint16 variant = accessory % 40;

    if (variant == 0) {
      return TraitOptionsAccessories.BALL_AND_CHAIN;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BAMBOO_SWORD;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BANHAMMER;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BASKET_OF_EXCESS_USED_GRAPHICS_CARDS;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BEEHIVE_ON_A_STICK;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_BALLOON;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_BOXING_GLOVES;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_FINGERNAIL_POLISH;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_GARDENER_TROWEL;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_MERGE_BEARS_FOAM_FINGER;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_PURSE;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BLUE_SPATULA;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BUCKET_OF_BLUE_PAINT;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BUCKET_OF_RED_PAINT;
    } else if (variant == 0) {
      return TraitOptionsAccessories.BURNED_OUT_GRAPHICS_CARD;
    } else if (variant == 0) {
      return TraitOptionsAccessories.COLD_STORAGE_WALLET;
    } else if (variant == 0) {
      return TraitOptionsAccessories.DOUBLE_DUMBBELLS;
    } else if (variant == 0) {
      return TraitOptionsAccessories.FRESH_SALMON;
    } else if (variant == 0) {
      return TraitOptionsAccessories.HAND_IN_A_BLUE_COOKIE_JAR;
    } else if (variant == 0) {
      return TraitOptionsAccessories.HAND_IN_A_RED_COOKIE_JAR;
    } else if (variant == 0) {
      return TraitOptionsAccessories.HOT_WALLET;
    } else if (variant == 0) {
      return TraitOptionsAccessories.MINERS_PICKAXE;
    } else if (variant == 0) {
      return TraitOptionsAccessories.NINJA_SWORDS;
    } else if (variant == 0) {
      return TraitOptionsAccessories.NONE;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PHISHING_NET;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PHISHING_ROD;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PINK_FINGERNAIL_POLISH;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PINK_PURSE;
    } else if (variant == 0) {
      return TraitOptionsAccessories.PROOF_OF_RIBEYE_STEAK;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_BALLOON;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_BOXING_GLOVES;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_FINGERNAIL_POLISH;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_GARDENER_TROWEL;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_MERGE_BEARS_FOAM_FINGER;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_PURSE;
    } else if (variant == 0) {
      return TraitOptionsAccessories.RED_SPATULA;
    } else if (variant == 0) {
      return TraitOptionsAccessories.TOILET_PAPER;
    } else if (variant == 0) {
      return TraitOptionsAccessories.WOODEN_WALKING_CANE;
    }
    return TraitOptionsAccessories.FRESH_SALMON;
  }

  // Face Accessory
  function getOptionFaceAccessory(uint256 dna) internal pure returns (uint8) {
    uint16 faceAccessory = getGene(TraitDefs.FACE_ACCESSORY, dna);
    uint16 variant = faceAccessory % 24;

    if (variant == 0) {
      return TraitOptionsFaceAccessory.BLACK_NINJA_MASK;
    } else if (variant == 1) {
      return TraitOptionsFaceAccessory.BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
    } else if (variant == 2) {
      return TraitOptionsFaceAccessory.BLUE_FRAMED_GLASSES;
    } else if (variant == 3) {
      return TraitOptionsFaceAccessory.BLUE_MEDICAL_MASK;
    } else if (variant == 4) {
      return TraitOptionsFaceAccessory.BLUE_NINJA_MASK;
    } else if (variant == 5) {
      return TraitOptionsFaceAccessory.BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (variant == 6) {
      return TraitOptionsFaceAccessory.BLUE_VERBS_GLASSES;
    } else if (variant == 7) {
      return TraitOptionsFaceAccessory.BLUE_AND_BLACK_CHECKERED_BANDANA;
    } else if (variant == 8) {
      return TraitOptionsFaceAccessory.BROWN_FRAMED_GLASSES;
    } else if (variant == 9) {
      return TraitOptionsFaceAccessory.CANDY_CANE;
    } else if (variant == 10) {
      return TraitOptionsFaceAccessory.GOLD_FRAMED_MONOCLE;
    } else if (variant == 11) {
      return TraitOptionsFaceAccessory.GRAY_BEARD;
    } else if (variant == 12) {
      return TraitOptionsFaceAccessory.NONE;
    } else if (variant == 13) {
      return TraitOptionsFaceAccessory.RED_FRAMED_GLASSES;
    } else if (variant == 14) {
      return TraitOptionsFaceAccessory.RED_MEDICAL_MASK;
    } else if (variant == 15) {
      return TraitOptionsFaceAccessory.RED_NINJA_MASK;
    } else if (variant == 16) {
      return TraitOptionsFaceAccessory.RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (variant == 17) {
      return TraitOptionsFaceAccessory.RED_VERBS_GLASSES;
    } else if (variant == 18) {
      return TraitOptionsFaceAccessory.RED_AND_WHITE_CHECKERED_BANDANA;
    } else if (variant == 19) {
      return TraitOptionsFaceAccessory.WHITE_NINJA_MASK;
    } else if (variant == 20) {
      return TraitOptionsFaceAccessory.WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
    } else if (variant == 21) {
      return TraitOptionsFaceAccessory.HEAD_CONE;
    } else if (variant == 22) {
      return TraitOptionsFaceAccessory.CLOWN_FACE_PAINT; // special
    } else if (variant == 23) {
      return TraitOptionsFaceAccessory.DRIPPING_HONEY; // special
    }

    return TraitOptionsFaceAccessory.NONE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Owner {
  address _owner;

  modifier setOwner(address owner_) {
    require(msg.sender == _owner);
    _owner = _owner;
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
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
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
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

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsBelly {
  uint8 constant LARGE = 0;
  uint8 constant SMALL = 1;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsLocale {
  uint8 constant NORTH_AMERICAN = 0;
  uint8 constant SOUTH_AMERICAN = 1;
  uint8 constant ASIAN = 2;
  uint8 constant EUROPEAN = 3;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsSpecies {
  uint8 constant BLACK = 0;
  uint8 constant POLAR = 1;
  uint8 constant PANDA = 2;
  uint8 constant REVERSE_PANDA = 3;
  uint8 constant GOLD_PANDA = 4;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library AssetMappingsHead {
  uint256 constant HEAD_HEAD___ALASKAN_BLACK_BEAR = 0;
  uint256 constant HEAD_HEAD___ALASKAN_PANDA_BEAR = 1;
  uint256 constant HEAD_HEAD___ALASKAN_POLAR_BEAR = 2;
  uint256 constant HEAD_HEAD___GOLD_PANDA = 3;
  uint256 constant HEAD_HEAD___HIMALAYAN_BLACK_BEAR = 4;
  uint256 constant HEAD_HEAD___HIMALAYAN_PANDA_BEAR = 5;
  uint256 constant HEAD_HEAD___HIMALAYAN_POLAR_BEAR = 6;
  uint256 constant HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR = 7;
  uint256 constant HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR = 8;
  uint256 constant HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR = 9;
  uint256 constant HEAD_HEAD___REVERSE_PANDA_BEAR = 10;
  uint256 constant HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR = 11;
  uint256 constant HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR = 12;
  uint256 constant HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR = 13;
}

// library AssetMappingsEyes {
//   uint256 constant EYES_EYES___ANNOYED_BLUE_EYES = 0;
//   uint256 constant EYES_EYES___ANNOYED_BROWN_EYES = 1;
//   uint256 constant EYES_EYES___ANNOYED_GREEN_EYES = 2;
//   uint256 constant EYES_EYES___BEADY_EYES = 3;
//   uint256 constant EYES_EYES___BEADY_RED_EYES = 4;
//   uint256 constant EYES_EYES___BORED_BLUE_EYES = 5;
//   uint256 constant EYES_EYES___BORED_BROWN_EYES = 6;
//   uint256 constant EYES_EYES___BORED_GREEN_EYES = 7;
//   uint256 constant EYES_EYES___DILATED_BLUE_EYES = 8;
//   uint256 constant EYES_EYES___DILATED_BROWN_EYES = 9;
//   uint256 constant EYES_EYES___DILATED_GREEN_EYES = 10;
//   uint256 constant EYES_EYES___NEUTRAL_BLUE_EYES = 11;
//   uint256 constant EYES_EYES___NEUTRAL_BROWN_EYES = 12;
//   uint256 constant EYES_EYES___NEUTRAL_GREEN_EYES = 13;
//   uint256 constant EYES_EYES___SQUARE_BLUE_EYES = 14;
//   uint256 constant EYES_EYES___SQUARE_BROWN_EYES = 15;
//   uint256 constant EYES_EYES___SQUARE_GREEN_EYES = 16;
//   uint256 constant EYES_EYES___SURPRISED_BLUE_EYES = 17;
//   uint256 constant EYES_EYES___SURPRISED_BROWN_EYES = 18;
//   uint256 constant EYES_EYES___SURPRISED_GREEN_EYES = 19;
// }

library AssetMappingsMouth {

}

library AssetMappingsNose {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitDefs {
  uint8 constant SPECIES = 0;
  uint8 constant LOCALE = 1;
  uint8 constant BELLY = 2;
  uint8 constant ARMS = 3;
  uint8 constant EYES = 4;
  uint8 constant MOUTH = 5;
  uint8 constant NOSE = 6;
  uint8 constant CLOTHING = 7;
  uint8 constant HAT = 8;
  uint8 constant JEWELRY = 9;
  uint8 constant FOOTWEAR = 10;
  uint8 constant ACCESSORIES = 11;
  uint8 constant FACE_ACCESSORY = 12;
  uint8 constant BACKGROUND = 13;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsBackground {
  uint8 constant RED = 0;
  uint8 constant BLUE = 1;
  uint8 constant GREEN = 2;
  uint8 constant YELLOW = 3;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsEyes {
  uint8 constant ANNOYED_BLUE_EYES = 0;
  uint8 constant ANNOYED_BROWN_EYES = 1;
  uint8 constant ANNOYED_GREEN_EYES = 2;
  uint8 constant BEADY_EYES = 3;
  uint8 constant BEADY_RED_EYES = 4;
  uint8 constant BORED_BLUE_EYES = 5;
  uint8 constant BORED_BROWN_EYES = 6;
  uint8 constant BORED_GREEN_EYES = 7;
  uint8 constant DILATED_BLUE_EYES = 8;
  uint8 constant DILATED_BROWN_EYES = 9;
  uint8 constant DILATED_GREEN_EYES = 10;
  uint8 constant NEUTRAL_BLUE_EYES = 11;
  uint8 constant NEUTRAL_BROWN_EYES = 12;
  uint8 constant NEUTRAL_GREEN_EYES = 13;
  uint8 constant SQUARE_BLUE_EYES = 14;
  uint8 constant SQUARE_BROWN_EYES = 15;
  uint8 constant SQUARE_GREEN_EYES = 16;
  uint8 constant SURPRISED_BLUE_EYES = 17;
  uint8 constant SURPRISED_BROWN_EYES = 18;
  uint8 constant SURPRISED_GREEN_EYES = 19;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsMouth {
  uint8 constant ANXIOUS = 0;
  uint8 constant BABY_TOOTH_SMILE = 1;
  uint8 constant BLUE_LIPSTICK = 2;
  uint8 constant FULL_MOUTH = 3;
  uint8 constant MISSING_BOTTOM_TOOTH = 4;
  uint8 constant NERVOUS_MOUTH = 5;
  uint8 constant OPEN_MOUTH = 6;
  uint8 constant PINK_LIPSTICK = 7;
  uint8 constant RED_LIPSTICK = 8;
  uint8 constant SAD_FROWN = 9;
  uint8 constant SMILE_WITH_BUCK_TEETH = 10;
  uint8 constant SMILE_WITH_PIPE = 11;
  uint8 constant SMILE = 12;
  uint8 constant SMIRK = 13;
  uint8 constant TINY_FROWN = 14;
  uint8 constant TINY_SMILE = 15;
  uint8 constant TONGUE_OUT = 16;
  uint8 constant TOOTHY_SMILE = 17;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsNose {
  uint8 constant BLACK_NOSTRILS_SNIFFER = 0;
  uint8 constant BLACK_SNIFFER = 1;
  uint8 constant BLUE_NOSTRILS_SNIFFER = 2;
  uint8 constant PINK_NOSTRILS_SNIFFER = 3;
  uint8 constant RUNNY_BLACK_NOSE = 4;
  uint8 constant SMALL_BLUE_SNIFFER = 5;
  uint8 constant SMALL_PINK_NOSE = 6;
  uint8 constant WIDE_BLACK_SNIFFER = 7;
  uint8 constant WIDE_BLUE_SNIFFER = 8;
  uint8 constant WIDE_PINK_SNIFFER = 9;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsFootwear {
  uint8 constant BLACK_GLADIATOR_SANDALS = 0;
  uint8 constant BLACK_SNEAKERS = 1;
  uint8 constant BLACK_AND_BLUE_SNEAKERS = 2;
  uint8 constant BLACK_AND_WHITE_SNEAKERS = 3;
  uint8 constant BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE = 4;
  uint8 constant BLUE_CROCS = 5;
  uint8 constant BLUE_FLIP_FLOPS = 6;
  uint8 constant BLUE_HIGH_HEELS = 7;
  uint8 constant BLUE_SNEAKERS = 8;
  uint8 constant BLUE_TOENAIL_POLISH = 9;
  uint8 constant BLUE_WORK_BOOTS = 10;
  uint8 constant BLUE_AND_GRAY_BASKETBALL_SNEAKERS = 11;
  uint8 constant PINK_HIGH_HEELS = 12;
  uint8 constant PINK_TOENAIL_POLISH = 13;
  uint8 constant PINK_WORK_BOOTS = 14;
  uint8 constant RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE = 15;
  uint8 constant RED_CROCS = 16;
  uint8 constant RED_FLIP_FLOPS = 17;
  uint8 constant RED_HIGH_HEELS = 18;
  uint8 constant RED_TOENAIL_POLISH = 19;
  uint8 constant RED_WORK_BOOTS = 20;
  uint8 constant RED_AND_GRAY_BASKETBALL_SNEAKERS = 21;
  uint8 constant STEPPED_IN_A_PUMPKIN = 22;
  uint8 constant TAN_COWBOY_BOOTS = 23;
  uint8 constant TAN_WORK_BOOTS = 24;
  uint8 constant WATERMELON_SHOES = 25;
  uint8 constant WHITE_SNEAKERS = 26;
  uint8 constant WHITE_AND_RED_SNEAKERS = 27;
  uint8 constant YELLOW_RAIN_BOOTS = 28;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsHat {
  uint8 constant ASTRONAUT_HELMET = 0;
  uint8 constant BAG_OF_ETHEREUM = 1;
  uint8 constant BLACK_BOWLER_HAT = 2;
  uint8 constant BLACK_TOP_HAT = 3;
  uint8 constant BLACK_AND_WHITE_STRIPED_JAIL_CAP = 4;
  uint8 constant BLACK_WITH_BLUE_HEADPHONES = 5;
  uint8 constant BLACK_WITH_BLUE_TOP_HAT = 6;
  uint8 constant BLUE_BASEBALL_CAP = 7;
  uint8 constant BLUE_UMBRELLA_HAT = 8;
  uint8 constant BULB_HELMET = 9;
  uint8 constant CHERRY_ON_TOP = 10;
  uint8 constant CRYPTO_INFLUENCER_BLUEBIRD = 11;
  uint8 constant GIANT_SUNFLOWER = 12;
  uint8 constant GOLD_CHALICE = 13;
  uint8 constant GRADUATION_CAP_WITH_BLUE_TASSEL = 14;
  uint8 constant GRADUATION_CAP_WITH_RED_TASSEL = 15;
  uint8 constant GREEN_GOO = 16;
  uint8 constant NODE_OPERATORS_YELLOW_HARDHAT = 17;
  uint8 constant NONE = 18;
  uint8 constant PINK_BUTTERFLY = 19;
  uint8 constant PINK_SUNHAT = 20;
  uint8 constant POLICE_CAP = 21;
  uint8 constant RED_ASTRONAUT_HELMET = 22;
  uint8 constant RED_BASEBALL_CAP = 23;
  uint8 constant RED_DEFI_WIZARD_HAT = 24;
  uint8 constant RED_SHOWER_CAP = 25;
  uint8 constant RED_SPORTS_HELMET = 26;
  uint8 constant RED_UMBRELLA_HAT = 27;
  uint8 constant TAN_COWBOY_HAT = 28;
  uint8 constant TAN_SUNHAT = 29;
  uint8 constant TINY_BLUE_HAT = 30;
  uint8 constant TINY_RED_HAT = 31;
  uint8 constant WHITE_BOWLER_HAT = 32;
  uint8 constant WHITE_TOP_HAT = 33;
  uint8 constant WHITE_AND_RED_BASEBALL_CAP = 34;
  uint8 constant WHITE_WITH_RED_HEADPHONES = 35;
  uint8 constant WHITE_WITH_RED_TOP_HAT = 36;
  uint8 constant SHIRT_BLACK_AND_BLUE_BASEBALL_CAP = 37;
  uint8 constant SHIRT_RED_UMBRELLA_HAT = 38;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsClothing {
  uint8 constant BLUE_ERC20_SHIRT = 0;
  uint8 constant BLUE_FOX_WALLET_TANKTOP = 1;
  uint8 constant BLUE_GRADIENT_DIAMOND_SHIRT = 2;
  uint8 constant BLUE_LINK_SHIRT = 3;
  uint8 constant BLUE_WEB3_SAFE_SHIRT = 4;
  uint8 constant RED_ERC20_SHIRT = 5;
  uint8 constant RED_FOX_WALLET_TANKTOP = 6;
  uint8 constant RED_GRADIENT_DIAMOND_SHIRT = 7;
  uint8 constant RED_LINK_SHIRT = 8;
  uint8 constant RED_WEB3_SAFE_SHIRT = 9;
  uint8 constant ADAMS_LEAF = 10;
  uint8 constant BLACK_BELT = 11;
  uint8 constant BLACK_LEATHER_JACKET = 12;
  uint8 constant BLACK_TUXEDO = 13;
  uint8 constant BLACK_AND_BLUE_STRIPED_BIB = 14;
  uint8 constant BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM = 15;
  uint8 constant BLACK_WITH_BLUE_DRESS = 16;
  uint8 constant BLACK_WITH_BLUE_STRIPES_TANKTOP = 17;
  uint8 constant BLUE_BEAR_LOVE_SHIRT = 18;
  uint8 constant BLUE_BEAR_MARKET_SHIRT = 19;
  uint8 constant BLUE_BULL_MARKET_SHIRT = 20;
  uint8 constant BLUE_DRESS_WITH_WHITE_DOTS = 21;
  uint8 constant BLUE_DRESS_WITH_WHITE_LACE = 22;
  uint8 constant BLUE_DRESS = 23;
  uint8 constant BLUE_ETH_SHIRT = 24;
  uint8 constant BLUE_FANNY_PACK = 25;
  uint8 constant BLUE_HOOLA_HOOP = 26;
  uint8 constant BLUE_HOOT_SHIRT = 27;
  uint8 constant BLUE_JESTERS_COLLAR = 28;
  uint8 constant BLUE_KNIT_SWEATER = 29;
  uint8 constant BLUE_LEG_WARMERS = 30;
  uint8 constant BLUE_OVERALLS = 31;
  uint8 constant BLUE_PINK_UNICORN_DEX_TANKTOP = 32;
  uint8 constant BLUE_PONCHO = 33;
  uint8 constant BLUE_PORTAL_SHIRT = 34;
  uint8 constant BLUE_PROOF_OF_STAKE_SHIRT = 35;
  uint8 constant BLUE_PROOF_OF_WORK_SHIRT = 36;
  uint8 constant BLUE_PUFFY_VEST = 37;
  uint8 constant BLUE_REKT_SHIRT = 38;
  uint8 constant BLUE_RASPBERRY_PI_NODE_TANKTOP = 39;
  uint8 constant BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS = 40;
  uint8 constant BLUE_SKIRT = 41;
  uint8 constant BLUE_STRIPED_NECKTIE = 42;
  uint8 constant BLUE_SUIT_JACKET_WITH_GOLD_TIE = 43;
  uint8 constant BLUE_TANKTOP = 44;
  uint8 constant BLUE_TOGA = 45;
  uint8 constant BLUE_TUBE_TOP = 46;
  uint8 constant BLUE_VEST = 47;
  uint8 constant BLUE_WAGMI_SHIRT = 48;
  uint8 constant BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY = 49;
  uint8 constant BLUE_WITH_PINK_AND_GREEN_DRESS = 50;
  uint8 constant BLUE_WITH_WHITE_APRON = 51;
  uint8 constant BORAT_SWIMSUIT = 52;
  uint8 constant BUTTERFLY_WINGS = 53;
  uint8 constant DUSTY_MAROON_MINERS_GARB = 54;
  uint8 constant DUSTY_NAVY_MINERS_GARB = 55;
  uint8 constant GRASS_SKIRT = 56;
  uint8 constant LEDERHOSEN = 57;
  uint8 constant MAGICIAN_UNIFORM_WITH_BLUE_CAPE = 58;
  uint8 constant MAGICIAN_UNIFORM_WITH_RED_CAPE = 59;
  uint8 constant NAKEY = 60;
  uint8 constant NODE_OPERATORS_VEST = 61;
  uint8 constant ORANGE_INFLATABLE_WATER_WINGS = 62;
  uint8 constant ORANGE_PRISON_UNIFORM = 63;
  uint8 constant PINK_TUTU = 64;
  uint8 constant PINK_AND_TEAL_DEFI_LENDING_TANKTOP = 65;
  uint8 constant RED_BEAR_LOVE_SHIRT = 66;
  uint8 constant RED_BEAR_MARKET_SHIRT = 67;
  uint8 constant RED_BULL_MARKET_SHIRT = 68;
  uint8 constant RED_DRESS_WITH_WHITE_DOTS = 69;
  uint8 constant RED_DRESS_WITH_WHITE_LACE = 70;
  uint8 constant RED_DRESS = 71;
  uint8 constant RED_ETH_SHIRT = 72;
  uint8 constant RED_FANNY_PACK = 73;
  uint8 constant RED_HOOLA_HOOP = 74;
  uint8 constant RED_HOOT_SHIRT = 75;
  uint8 constant RED_JESTERS_COLLAR = 76;
  uint8 constant RED_KNIT_SWEATER = 77;
  uint8 constant RED_LEG_WARMERS = 78;
  uint8 constant RED_OVERALLS = 79;
  uint8 constant RED_PINK_UNICORN_DEX_TANKTOP = 80;
  uint8 constant RED_PONCHO = 81;
  uint8 constant RED_PORTAL_SHIRT = 82;
  uint8 constant RED_PROOF_OF_STAKE_SHIRT = 83;
  uint8 constant RED_PROOF_OF_WORK_SHIRT = 84;
  uint8 constant RED_PUFFY_VEST = 85;
  uint8 constant RED_REKT_SHIRT = 86;
  uint8 constant RED_RASPBERRY_PI_NODE_TANKTOP = 87;
  uint8 constant RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS = 88;
  uint8 constant RED_SKIRT = 89;
  uint8 constant RED_STRIPED_NECKTIE = 90;
  uint8 constant RED_SUIT_JACKET_WITH_GOLD_TIE = 91;
  uint8 constant RED_TANKTOP = 92;
  uint8 constant RED_TOGA = 93;
  uint8 constant RED_TUBE_TOP = 94;
  uint8 constant RED_VEST = 95;
  uint8 constant RED_WAGMI_SHIRT = 96;
  uint8 constant RED_WITH_PINK_AND_GREEN_DRESS = 97;
  uint8 constant RED_WITH_WHITE_APRON = 98;
  uint8 constant RED_WITH_WHITE_STRIPES_SOCCER_JERSEY = 99;
  uint8 constant TAN_CARGO_SHORTS = 100;
  uint8 constant VAMPIRE_BAT_WINGS = 101;
  uint8 constant WHITE_TUXEDO = 102;
  uint8 constant WHITE_AND_RED_STRIPED_BIB = 103;
  uint8 constant WHITE_WITH_RED_DRESS = 104;
  uint8 constant WHITE_WITH_RED_STRIPES_TANKTOP = 105;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsJewelry {
  uint8 constant BLUE_BRACELET = 0;
  uint8 constant BLUE_SPORTS_WATCH = 1;
  uint8 constant DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION = 2;
  uint8 constant DOUBLE_GOLD_CHAINS = 3;
  uint8 constant DOUBLE_SILVER_CHAINS = 4;
  uint8 constant GOLD_CHAIN_WITH_MEDALLION = 5;
  uint8 constant GOLD_CHAIN_WITH_RED_RUBY = 6;
  uint8 constant GOLD_CHAIN = 7;
  uint8 constant GOLD_STUD_EARRINGS = 8;
  uint8 constant GOLD_WATCH_ON_LEFT_WRIST = 9;
  uint8 constant LEFT_HAND_GOLD_RINGS = 10;
  uint8 constant LEFT_HAND_SILVER_RINGS = 11;
  uint8 constant RED_BRACELET = 12;
  uint8 constant RED_SPORTS_WATCH = 13;
  uint8 constant SILVER_CHAIN_WITH_MEDALLION = 14;
  uint8 constant SILVER_CHAIN_WITH_RED_RUBY = 15;
  uint8 constant SILVER_CHAIN = 16;
  uint8 constant SILVER_STUD_EARRINGS = 17;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsAccessories {
  uint8 constant BALL_AND_CHAIN = 0;
  uint8 constant BAMBOO_SWORD = 1;
  uint8 constant BANHAMMER = 2;
  uint8 constant BASKET_OF_EXCESS_USED_GRAPHICS_CARDS = 3;
  uint8 constant BEEHIVE_ON_A_STICK = 4;
  uint8 constant BLUE_BALLOON = 5;
  uint8 constant BLUE_BOXING_GLOVES = 6;
  uint8 constant BLUE_FINGERNAIL_POLISH = 7;
  uint8 constant BLUE_GARDENER_TROWEL = 8;
  uint8 constant BLUE_MERGE_BEARS_FOAM_FINGER = 9;
  uint8 constant BLUE_PURSE = 10;
  uint8 constant BLUE_SPATULA = 11;
  uint8 constant BUCKET_OF_BLUE_PAINT = 12;
  uint8 constant BUCKET_OF_RED_PAINT = 13;
  uint8 constant BURNED_OUT_GRAPHICS_CARD = 14;
  uint8 constant COLD_STORAGE_WALLET = 15;
  uint8 constant DOUBLE_DUMBBELLS = 16;
  uint8 constant FRESH_SALMON = 17;
  uint8 constant HAND_IN_A_BLUE_COOKIE_JAR = 18;
  uint8 constant HAND_IN_A_RED_COOKIE_JAR = 19;
  uint8 constant HOT_WALLET = 20;
  uint8 constant MINERS_PICKAXE = 21;
  uint8 constant NINJA_SWORDS = 22;
  uint8 constant NONE = 23;
  uint8 constant PHISHING_NET = 24;
  uint8 constant PHISHING_ROD = 25;
  uint8 constant PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET = 26;
  uint8 constant PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET = 27;
  uint8 constant PINK_FINGERNAIL_POLISH = 28;
  uint8 constant PINK_PURSE = 29;
  uint8 constant PROOF_OF_RIBEYE_STEAK = 30;
  uint8 constant RED_BALLOON = 31;
  uint8 constant RED_BOXING_GLOVES = 32;
  uint8 constant RED_FINGERNAIL_POLISH = 33;
  uint8 constant RED_GARDENER_TROWEL = 34;
  uint8 constant RED_MERGE_BEARS_FOAM_FINGER = 35;
  uint8 constant RED_PURSE = 36;
  uint8 constant RED_SPATULA = 37;
  uint8 constant TOILET_PAPER = 38;
  uint8 constant WOODEN_WALKING_CANE = 39;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsFaceAccessory {
  uint8 constant BLACK_NINJA_MASK = 0;
  uint8 constant BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL = 1;
  uint8 constant BLUE_FRAMED_GLASSES = 2;
  uint8 constant BLUE_MEDICAL_MASK = 3;
  uint8 constant BLUE_NINJA_MASK = 4;
  uint8 constant BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES = 5;
  uint8 constant BLUE_VERBS_GLASSES = 6;
  uint8 constant BLUE_AND_BLACK_CHECKERED_BANDANA = 7;
  uint8 constant BROWN_FRAMED_GLASSES = 8;
  uint8 constant CANDY_CANE = 9;
  uint8 constant GOLD_FRAMED_MONOCLE = 10;
  uint8 constant GRAY_BEARD = 11;
  uint8 constant NONE = 12;
  uint8 constant RED_FRAMED_GLASSES = 13;
  uint8 constant RED_MEDICAL_MASK = 14;
  uint8 constant RED_NINJA_MASK = 15;
  uint8 constant RED_STRAIGHT_BOTTOM_FRAMED_GLASSES = 16;
  uint8 constant RED_VERBS_GLASSES = 17;
  uint8 constant RED_AND_WHITE_CHECKERED_BANDANA = 18;
  uint8 constant WHITE_NINJA_MASK = 19;
  uint8 constant WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL = 20;
  uint8 constant HEAD_CONE = 21;
  uint8 constant CLOWN_FACE_PAINT = 22;
  uint8 constant DRIPPING_HONEY = 23;
}