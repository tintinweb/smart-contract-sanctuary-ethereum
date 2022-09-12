// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Owner {
  address _owner;

  constructor() {
    _owner = msg.sender;
  }

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
  // Deployed Asset Contracts
  address constant ACCESSORIES = 0x4d20e1c16D1B682e1972d616A4C5Ae6144e1EB48;
  address constant ARMS = 0xcC1c5af22e12e2F9D8FE25094c86Ea7971aB7857;
  address constant BELLY = 0x739c928bB9a35C39BEEcB26E863bAa005b2AbB24;
  address constant CLOTHINGA = 0xc94ED19F6FEA7C17705e7a9EB8c1c0885aD231E0;
  address constant CLOTHINGB = 0xbC05b01D610aECbF9E3844DD49fE9CdEC4358eB0;
  address constant EYES = 0x034567BD47eFf40C90e8D94962ADE9FAD822812a;
  address constant FACE = 0xC8471bf4aE5A575b705B265bF589b25DA4f1d50c;
  address constant FEET = 0x0FFaF8cdCb6ed98C1Ac186968659Ee142393d47d;
  address constant FOOTWEAR = 0x900D8B89D84238263E4F31101F4Ee95DC5EEd3d5;
  address constant HAT = 0x6Bcd4673e96afAeBe92804F9cf657A29Dab34caC;
  address constant HEAD = 0x8F74098889a97c567fcA45ED0CB0Fec4CBa5250F;
  address constant JEWELRY = 0x521cc91292f345de8a0B60f6156d0b4750FAD126;
  address constant MOUTH = 0x6b6145C68407bD94fFc76068ffC31795956F7440;
  address constant NOSE = 0x89509fa32E296Bc26F283C3a7048F7dB7Fa1f734;
  address constant SPECIAL_CLOTHING =
    0xf7C17dB875d8C4ccE301E2c6AF07ab7621204223;
  address constant SPECIAL_FACE = 0x7eaB4aDf19635047FE48E889995E616a7536b794;

  // Deployed Trait Options Contracts
  address constant OptionSpecies = 0x72581cEA263688bE9278507b9361E18dca19c65c;
  address constant OptionAccessories =
    0xd70D73f7AE4fF34833Ef9a909A17ac66f810477e;
  address constant OptionClothing = 0xf009bd1177578F6bD0eAD52bBB8a974e089F3379;
  address constant OptionLocale = 0x329B830f93d34abef67A054EE2262E1a968F91da;
  address constant OptionFaceAccessory =
    0xB6F29F40c498152cEA2786c7bb016B36829923a0;
  address constant OptionFootwear = 0xB9b3611f83aCe113259aFD2cF00d0FE1d6223cEa;
  address constant OptionHat = 0x9E5Cb1B891cC16FB1a97A1C99BbaaA63E8B2De98;
  address constant OptionJewelry = 0xf2eA41D7843f66312a7A148bF3b8046FFB5F8973;
  address constant OptionBackground =
    0x8FCc1e62B2FB4F9AC56b48d3A80EF5691eF66f8b;
  address constant OptionBelly = 0x7f6A3b13ca2EfE9E799bFa4CFE99232194A77C96;
  address constant OptionEyes = 0xFA158A97861c264CFB08a2686C3a25CFa3288Bc9;
  address constant OptionMouth = 0x88A071eeD69432b4890c122B74fD97C68D209a1d;
  address constant OptionNose = 0x4062976523518d3D01bd227f1410fE3bebd21347;

  // Utility Contracts
  address constant TraitsUtility = 0x6788eca19Af34b5517B57997a784a5D0A2ab3d5B;
  address constant Animation = 0x698D6aDed6d01e7FC99Ff8718Dda5C4b0A716386;
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
pragma solidity ^0.8.12;

import "../lib_constants/TraitDefs.sol";
import "../extensions/Owner.sol";
import "../lib_env/Rinkeby.sol";

interface IOptionsContract {
  function getOption(uint256) external pure returns (uint8);
}

contract TraitsUtility is Owner {
  mapping(uint8 => address) optionsContracts;

  constructor() {
    _owner = msg.sender;

    // once optionContracts are live, initialize automatically here
    optionsContracts[TraitDefs.SPECIES] = Rinkeby.OptionSpecies;
    optionsContracts[TraitDefs.LOCALE] = Rinkeby.OptionLocale;
    optionsContracts[TraitDefs.BELLY] = Rinkeby.OptionBelly;
    optionsContracts[TraitDefs.EYES] = Rinkeby.OptionEyes;
    optionsContracts[TraitDefs.MOUTH] = Rinkeby.OptionMouth;
    optionsContracts[TraitDefs.NOSE] = Rinkeby.OptionNose;
    optionsContracts[TraitDefs.CLOTHING] = Rinkeby.OptionClothing;
    optionsContracts[TraitDefs.HAT] = Rinkeby.OptionHat;
    optionsContracts[TraitDefs.JEWELRY] = Rinkeby.OptionJewelry;
    optionsContracts[TraitDefs.FOOTWEAR] = Rinkeby.OptionFootwear;
    optionsContracts[TraitDefs.ACCESSORIES] = Rinkeby.OptionAccessories;
    optionsContracts[TraitDefs.FACE_ACCESSORY] = Rinkeby.OptionFaceAccessory;
    optionsContracts[TraitDefs.BACKGROUND] = Rinkeby.OptionBackground;
  }

  function setOptionContract(uint8 traitDef, address optionContract)
    external
    onlyOwner
  {
    optionsContracts[traitDef] = optionContract;
  }

  function getOption(uint8 traitDef, uint256 dna)
    external
    view
    returns (uint8)
  {
    return IOptionsContract(optionsContracts[traitDef]).getOption(dna);
  }
}

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
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsNose.sol";
import "../Gene.sol";

library OptionNose {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 nose = Gene.getGene(TraitDefs.NOSE, dna);
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
pragma solidity ^0.8.12;

library Gene {
  function getGene(uint8 traitDef, uint256 dna) internal pure returns (uint16) {
    // type(uint16).max
    // right shift traitDef * 16, then bitwise & with the max 16 bit number
    return uint16((dna >> (traitDef * 16)) & uint256(type(uint16).max));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsMouth.sol";
import "../Gene.sol";

library OptionMouth {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 mouth = Gene.getGene(TraitDefs.MOUTH, dna);
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
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsJewelry.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../../lib_constants/trait_options/TraitOptionsClothing.sol";
import "./OptionSpecies.sol";
import "./OptionClothing.sol";
import "../Gene.sol";

library OptionJewelry {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 jewelry = Gene.getGene(TraitDefs.JEWELRY, dna);
    // uint16 variant = jewelry % 18;

    uint8 species = OptionSpecies.getOption(dna);
    uint8 clothing = OptionClothing.getOption(dna);

    // no silver for B&W striped jail uniform (clothing)
    // no red for black, no blue for white

    // 1 (1000), 7(100), 5(50), 6(25)
    // 1000 + 700 + 250 + 150
    // 2100

    uint16 rarityRoll = jewelry % 2100;

    if (rarityRoll < 1000) {
      return TraitOptionsJewelry.NONE;
    } else if (rarityRoll >= 1000 && rarityRoll < 1700) {
      // weight 100
      uint16 variant = rarityRoll % 5;

      if (variant == 0) {
        return TraitOptionsJewelry.DOUBLE_GOLD_CHAINS;
      } else if (
        variant == 1 &&
        clothing != TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM
      ) {
        return TraitOptionsJewelry.DOUBLE_SILVER_CHAINS;
      } else if (variant == 2) {
        return TraitOptionsJewelry.GOLD_CHAIN;
      } else if (variant == 3) {
        return TraitOptionsJewelry.GOLD_WATCH_ON_LEFT_WRIST;
      } else if (
        variant == 4 &&
        clothing != TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM
      ) {
        return TraitOptionsJewelry.SILVER_CHAIN;
      }
    } else if (rarityRoll >= 1700 && rarityRoll < 1950) {
      // weight 50
      uint16 variant = rarityRoll % 5;

      if (variant == 0) {
        return TraitOptionsJewelry.GOLD_CHAIN_WITH_MEDALLION;
      } else if (
        variant == 1 &&
        clothing != TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM
      ) {
        return TraitOptionsJewelry.SILVER_CHAIN_WITH_MEDALLION;
      } else if (
        variant == 2 &&
        clothing != TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM
      ) {
        return TraitOptionsJewelry.SILVER_CHAIN_WITH_RED_RUBY;
      } else if (variant == 3 && species != TraitOptionsSpecies.POLAR) {
        return TraitOptionsJewelry.BLUE_SPORTS_WATCH;
      } else if (variant == 4 && species != TraitOptionsSpecies.BLACK) {
        return TraitOptionsJewelry.RED_SPORTS_WATCH;
      }
    } else if (rarityRoll >= 1950 && rarityRoll < 2100) {
      // weight 25
      uint16 variant = rarityRoll % 6;

      // blue bracelet looks weird
      // if (variant == 0 && species != TraitOptionsSpecies.POLAR) {
      //   return TraitOptionsJewelry.BLUE_BRACELET;
      // }
      if (variant == 1) {
        return
          TraitOptionsJewelry.DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION;
      } else if (variant == 2) {
        return TraitOptionsJewelry.GOLD_CHAIN_WITH_RED_RUBY;
      } else if (variant == 3) {
        return TraitOptionsJewelry.LEFT_HAND_GOLD_RINGS;
      } else if (
        variant == 4 &&
        clothing != TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM
      ) {
        return TraitOptionsJewelry.LEFT_HAND_SILVER_RINGS;
      } else if (variant == 5 && species != TraitOptionsSpecies.BLACK) {
        return TraitOptionsJewelry.RED_BRACELET;
      }
    }

    return TraitOptionsJewelry.NONE;
  }
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
  // uint8 constant GOLD_STUD_EARRINGS = 8;
  uint8 constant GOLD_WATCH_ON_LEFT_WRIST = 9;
  uint8 constant LEFT_HAND_GOLD_RINGS = 10;
  uint8 constant LEFT_HAND_SILVER_RINGS = 11;
  uint8 constant RED_BRACELET = 12;
  uint8 constant RED_SPORTS_WATCH = 13;
  uint8 constant SILVER_CHAIN_WITH_MEDALLION = 14;
  uint8 constant SILVER_CHAIN_WITH_RED_RUBY = 15;
  uint8 constant SILVER_CHAIN = 16;
  // uint8 constant SILVER_STUD_EARRINGS = 17;
  uint8 constant NONE = 18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library TraitOptionsSpecies {
  uint8 constant BLACK = 1;
  uint8 constant POLAR = 2;
  uint8 constant PANDA = 3;
  uint8 constant REVERSE_PANDA = 4;
  uint8 constant GOLD_PANDA = 5;
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
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../Gene.sol";

library OptionSpecies {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 species = Gene.getGene(TraitDefs.SPECIES, dna);
    // this gene is hard-coded at "mint" or at "merge"
    // 1 is black
    // 2 is polar
    // 3 is panda
    // 4 is reverse panda
    // 5 is gold panda

    if (species == 1) {
      return TraitOptionsSpecies.BLACK;
    } else if (species == 2) {
      return TraitOptionsSpecies.POLAR;
    } else if (species == 3) {
      return TraitOptionsSpecies.PANDA;
    } else if (species == 4) {
      return TraitOptionsSpecies.REVERSE_PANDA;
    } else if (species == 5) {
      return TraitOptionsSpecies.GOLD_PANDA;
    }
    return TraitOptionsSpecies.BLACK;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsClothing.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../Gene.sol";
import "./OptionSpecies.sol";

/**
 * TRs are set on 5 Species, 2 Locales
 * 5 Species
 *  - Black Bear
 *    - Exc
 *      - Clothing
 *        - All Red assets, Black Tuxedo
 *      - Hat
 *        - All Red Assets
 *        - All Black (only) Assets
 *      - Accessories
 *        - All red
 *        - Basked of used Graphics cards
 *        - Burned out graphics card
 *        - Proof of Ribeye Steak
*       - Face accessory
          - All Reds
        - Jewelry
          - All reds
          - RPL medallion
*   - White Bear
      - Exc
        - Clothing
          - (similar )

    - Pandas
      - Exc
        - Clothing
          - POW Shirts (2)
          - Miners Garbs (2)
          - 
        - Accessories
          - Pickaxe
     Locales
      - NA
        - Face Accessory
          - Blk Ninja Mask
          - Blue Ninja
          - Red Ninja
          - White Ninja
      - Asian
        - Hat
          - Pink Sunhat
          - Tan Sunhat
 * X Clothing
 * - B&W Striped Jail Uniform (excludes some Jewelry)
 * - Black Tuxedo (ex Accessory Dumbbells)
 * - Ghost (incl only "NONE" for Accessory, FaceAccessory)
 * X Hat
 * - Blue Astronaut Helmet (exc some face Accessories)
 * - Red Astronaut Helmet (exc some face Accessories)
 * 
 * 
 *  - Will need rules on Clothing, Hat, Accessories, Face Accessory, Jewelry
 * 
 *  - Clothing rules from: Species
 *  - Hat rules from: Species, Locales
 *  - Jewelry rules from: Species, Clothing
 *  - Footwear rules from: Species
 *  - Accessories rules from: Species, Clothing
 *  - Face Accessory rules from: Species, Locales, Clothing, Hat
 */

/**
 * TR deps from Species,
 */
library OptionClothing {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 clothes = Gene.getGene(TraitDefs.CLOTHING, dna);
    uint16 variant = clothes % 2078; // multiplier configured from weights
    // trait dependencies
    uint8 species = OptionSpecies.getOption(dna); //Gene.getGene(TraitDefs.SPECIES, dna);

    // BLUE CLOTHES
    if (species == TraitOptionsSpecies.BLACK) {
      if (variant >= 0 && variant < 80) {
        return TraitOptionsClothing.BLUE_ERC20_SHIRT;
      } else if (variant >= 80 && variant < 160) {
        return TraitOptionsClothing.BLUE_FOX_WALLET_TANKTOP;
      } else if (variant >= 160 && variant < 240) {
        return TraitOptionsClothing.BLUE_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 240 && variant < 320) {
        return TraitOptionsClothing.BLUE_LINK_SHIRT;
      } else if (variant >= 320 && variant < 400) {
        return TraitOptionsClothing.BLUE_WEB3_SAFE_SHIRT;
      } else if (variant >= 400 && variant < 420) {
        return TraitOptionsClothing.BLACK_AND_BLUE_STRIPED_BIB;
      } else if (variant >= 420 && variant < 430) {
        return TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
      } else if (variant >= 430 && variant < 470) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_DRESS;
      } else if (variant >= 470 && variant < 510) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_STRIPES_TANKTOP;
      } else if (variant >= 510 && variant < 550) {
        return TraitOptionsClothing.BLUE_BEAR_LOVE_SHIRT;
      } else if (variant >= 550 && variant < 590) {
        return TraitOptionsClothing.BLUE_BEAR_MARKET_SHIRT;
      } else if (variant >= 590 && variant < 630) {
        return TraitOptionsClothing.BLUE_BULL_MARKET_SHIRT;
      } else if (variant >= 630 && variant < 670) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 670 && variant < 710) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 710 && variant < 750) {
        return TraitOptionsClothing.BLUE_DRESS;
      } else if (variant >= 750 && variant < 790) {
        return TraitOptionsClothing.BLUE_ETH_SHIRT;
      } else if (variant >= 790 && variant < 830) {
        return TraitOptionsClothing.BLUE_FANNY_PACK;
      } else if (variant >= 830 && variant < 840) {
        return TraitOptionsClothing.BLUE_HOOLA_HOOP;
      } else if (variant >= 840 && variant < 880) {
        return TraitOptionsClothing.BLUE_HOOT_SHIRT;
      } else if (variant >= 880 && variant < 890) {
        return TraitOptionsClothing.BLUE_JESTERS_COLLAR;
      } else if (variant >= 890 && variant < 910) {
        return TraitOptionsClothing.BLUE_KNIT_SWEATER;
      } else if (variant >= 910 && variant < 914) {
        return TraitOptionsClothing.BLUE_LEG_WARMERS;
      } else if (variant >= 914 && variant < 954) {
        return TraitOptionsClothing.BLUE_OVERALLS;
      } else if (variant >= 954 && variant < 1034) {
        return TraitOptionsClothing.BLUE_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 1034 && variant < 1054) {
        return TraitOptionsClothing.BLUE_PONCHO;
      } else if (variant >= 1054 && variant < 1094) {
        return TraitOptionsClothing.BLUE_PORTAL_SHIRT;
      } else if (variant >= 1094 && variant < 1134) {
        return TraitOptionsClothing.DUSTY_NAVY_MINERS_GARB;
      } else if (variant >= 1134 && variant < 1174) {
        return TraitOptionsClothing.BLUE_PROOF_OF_WORK_SHIRT;
      } else if (variant >= 1174 && variant < 1214) {
        return TraitOptionsClothing.BLUE_PUFFY_VEST;
      } else if (variant >= 1214 && variant < 1254) {
        return TraitOptionsClothing.BLUE_REKT_SHIRT;
      } else if (variant >= 1254 && variant < 1334) {
        return TraitOptionsClothing.BLUE_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 1334 && variant < 1374) {
        return TraitOptionsClothing.BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 1374 && variant < 1414) {
        return TraitOptionsClothing.BLUE_SKIRT;
      } else if (variant >= 1414 && variant < 1454) {
        return TraitOptionsClothing.BLUE_STRIPED_NECKTIE;
      } else if (variant >= 1454 && variant < 1464) {
        return TraitOptionsClothing.BLUE_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 1464 && variant < 1504) {
        return TraitOptionsClothing.BLUE_TANKTOP;
      } else if (variant >= 1504 && variant < 1524) {
        return TraitOptionsClothing.BLUE_TOGA;
      } else if (variant >= 1524 && variant < 1564) {
        return TraitOptionsClothing.BLUE_TUBE_TOP;
      } else if (variant >= 1564 && variant < 1604) {
        return TraitOptionsClothing.BLUE_VEST;
      } else if (variant >= 1604 && variant < 1644) {
        return TraitOptionsClothing.BLUE_WAGMI_SHIRT;
      } else if (variant >= 1644 && variant < 1664) {
        return TraitOptionsClothing.BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 1664 && variant < 1674) {
        return TraitOptionsClothing.BLUE_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 1674 && variant < 1694) {
        return TraitOptionsClothing.BLUE_WITH_WHITE_APRON;
      } else if (variant >= 1694 && variant < 1704) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
      } // END BLACK BEAR BLUE ASSETS
    } else if (species == TraitOptionsSpecies.POLAR) {
      // RED CLOTHES
      if (variant >= 0 && variant < 80) {
        return TraitOptionsClothing.RED_ERC20_SHIRT;
      } else if (variant >= 80 && variant < 160) {
        return TraitOptionsClothing.RED_FOX_WALLET_TANKTOP;
      } else if (variant >= 160 && variant < 240) {
        return TraitOptionsClothing.RED_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 240 && variant < 320) {
        return TraitOptionsClothing.RED_LINK_SHIRT;
      } else if (variant >= 320 && variant < 400) {
        return TraitOptionsClothing.RED_WEB3_SAFE_SHIRT;
      } else if (variant >= 400 && variant < 420) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_RED_CAPE;
      } else if (variant >= 420 && variant < 430) {
        return TraitOptionsClothing.RED_BEAR_LOVE_SHIRT;
      } else if (variant >= 430 && variant < 470) {
        return TraitOptionsClothing.RED_BEAR_MARKET_SHIRT;
      } else if (variant >= 470 && variant < 510) {
        return TraitOptionsClothing.RED_BULL_MARKET_SHIRT;
      } else if (variant >= 510 && variant < 550) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 550 && variant < 590) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 590 && variant < 630) {
        return TraitOptionsClothing.RED_DRESS;
      } else if (variant >= 630 && variant < 670) {
        return TraitOptionsClothing.RED_ETH_SHIRT;
      } else if (variant >= 670 && variant < 710) {
        return TraitOptionsClothing.RED_FANNY_PACK;
      } else if (variant >= 710 && variant < 750) {
        return TraitOptionsClothing.RED_HOOLA_HOOP;
      } else if (variant >= 750 && variant < 790) {
        return TraitOptionsClothing.RED_HOOT_SHIRT;
      } else if (variant >= 790 && variant < 830) {
        return TraitOptionsClothing.RED_JESTERS_COLLAR;
      } else if (variant >= 830 && variant < 840) {
        return TraitOptionsClothing.RED_KNIT_SWEATER;
      } else if (variant >= 840 && variant < 880) {
        return TraitOptionsClothing.RED_LEG_WARMERS;
      } else if (variant >= 880 && variant < 890) {
        return TraitOptionsClothing.RED_OVERALLS;
      } else if (variant >= 890 && variant < 910) {
        return TraitOptionsClothing.RED_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 910 && variant < 914) {
        return TraitOptionsClothing.RED_PONCHO;
      } else if (variant >= 914 && variant < 954) {
        return TraitOptionsClothing.RED_PORTAL_SHIRT;
      } else if (variant >= 954 && variant < 1034) {
        return TraitOptionsClothing.RED_PROOF_OF_WORK_SHIRT;
      } else if (variant >= 1034 && variant < 1054) {
        return TraitOptionsClothing.RED_PUFFY_VEST;
      } else if (variant >= 1054 && variant < 1094) {
        return TraitOptionsClothing.RED_REKT_SHIRT;
      }
      // gap between 1094 and 1134
      else if (variant >= 1134 && variant < 1174) {
        return TraitOptionsClothing.RED_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 1174 && variant < 1214) {
        return TraitOptionsClothing.RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 1214 && variant < 1254) {
        return TraitOptionsClothing.RED_SKIRT;
      } else if (variant >= 1254 && variant < 1334) {
        return TraitOptionsClothing.RED_STRIPED_NECKTIE;
      } else if (variant >= 1334 && variant < 1374) {
        return TraitOptionsClothing.RED_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 1374 && variant < 1414) {
        return TraitOptionsClothing.RED_TANKTOP;
      } else if (variant >= 1414 && variant < 1454) {
        return TraitOptionsClothing.RED_TOGA;
      } else if (variant >= 1454 && variant < 1464) {
        return TraitOptionsClothing.RED_TUBE_TOP;
      } else if (variant >= 1464 && variant < 1504) {
        return TraitOptionsClothing.RED_VEST;
      } else if (variant >= 1504 && variant < 1524) {
        return TraitOptionsClothing.RED_WAGMI_SHIRT;
      } else if (variant >= 1524 && variant < 1564) {
        return TraitOptionsClothing.RED_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 1564 && variant < 1604) {
        return TraitOptionsClothing.RED_WITH_WHITE_APRON;
      } else if (variant >= 1604 && variant < 1644) {
        return TraitOptionsClothing.RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 1644 && variant < 1664) {
        return TraitOptionsClothing.WHITE_AND_RED_STRIPED_BIB;
      } else if (variant >= 1664 && variant < 1674) {
        return TraitOptionsClothing.WHITE_WITH_RED_DRESS;
      } else if (variant >= 1674 && variant < 1694) {
        return TraitOptionsClothing.WHITE_WITH_RED_STRIPES_TANKTOP;
      } else if (variant >= 1694 && variant < 1704) {
        return TraitOptionsClothing.DUSTY_MAROON_MINERS_GARB;
      }
    }
    // END POLAR RED ASSETS
    else {
      // BEGIN PANDA COLORED ASSET CHECK
      // BLUES (remove POW stuff)
      if (variant >= 0 && variant < 40) {
        return TraitOptionsClothing.BLUE_ERC20_SHIRT;
      } else if (variant >= 40 && variant < 80) {
        return TraitOptionsClothing.BLUE_FOX_WALLET_TANKTOP;
      } else if (variant >= 80 && variant < 120) {
        return TraitOptionsClothing.BLUE_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 120 && variant < 160) {
        return TraitOptionsClothing.BLUE_LINK_SHIRT;
      } else if (variant >= 160 && variant < 200) {
        return TraitOptionsClothing.BLUE_WEB3_SAFE_SHIRT;
      } else if (variant >= 200 && variant < 210) {
        return TraitOptionsClothing.BLACK_AND_BLUE_STRIPED_BIB;
      } else if (variant >= 210 && variant < 215) {
        return TraitOptionsClothing.BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
      } else if (variant >= 215 && variant < 235) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_DRESS;
      } else if (variant >= 235 && variant < 255) {
        return TraitOptionsClothing.BLACK_WITH_BLUE_STRIPES_TANKTOP;
      } else if (variant >= 255 && variant < 275) {
        return TraitOptionsClothing.BLUE_BEAR_LOVE_SHIRT;
      } else if (variant >= 275 && variant < 295) {
        return TraitOptionsClothing.BLUE_BEAR_MARKET_SHIRT;
      } else if (variant >= 295 && variant < 315) {
        return TraitOptionsClothing.BLUE_BULL_MARKET_SHIRT;
      } else if (variant >= 315 && variant < 335) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 335 && variant < 355) {
        return TraitOptionsClothing.BLUE_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 355 && variant < 375) {
        return TraitOptionsClothing.BLUE_DRESS;
      } else if (variant >= 375 && variant < 395) {
        return TraitOptionsClothing.BLUE_ETH_SHIRT;
      } else if (variant >= 395 && variant < 415) {
        return TraitOptionsClothing.BLUE_FANNY_PACK;
      } else if (variant >= 415 && variant < 420) {
        return TraitOptionsClothing.BLUE_HOOLA_HOOP;
      } else if (variant >= 420 && variant < 440) {
        return TraitOptionsClothing.BLUE_HOOT_SHIRT;
      } else if (variant >= 440 && variant < 445) {
        return TraitOptionsClothing.BLUE_JESTERS_COLLAR;
      } else if (variant >= 445 && variant < 455) {
        return TraitOptionsClothing.BLUE_KNIT_SWEATER;
      } else if (variant >= 455 && variant < 457) {
        return TraitOptionsClothing.BLUE_LEG_WARMERS;
      } else if (variant >= 457 && variant < 477) {
        return TraitOptionsClothing.BLUE_OVERALLS;
      } else if (variant >= 477 && variant < 517) {
        return TraitOptionsClothing.BLUE_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 517 && variant < 527) {
        return TraitOptionsClothing.BLUE_PONCHO;
      } else if (variant >= 527 && variant < 547) {
        return TraitOptionsClothing.BLUE_PORTAL_SHIRT;
      }
      // gap between 547 and 567
      else if (variant >= 567 && variant < 587) {
        return TraitOptionsClothing.BLUE_PROOF_OF_WORK_SHIRT;
      } else if (variant >= 587 && variant < 607) {
        return TraitOptionsClothing.BLUE_PUFFY_VEST;
      } else if (variant >= 607 && variant < 627) {
        return TraitOptionsClothing.BLUE_REKT_SHIRT;
      } else if (variant >= 627 && variant < 667) {
        return TraitOptionsClothing.BLUE_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 667 && variant < 687) {
        return TraitOptionsClothing.BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 687 && variant < 707) {
        return TraitOptionsClothing.BLUE_SKIRT;
      } else if (variant >= 707 && variant < 727) {
        return TraitOptionsClothing.BLUE_STRIPED_NECKTIE;
      } else if (variant >= 727 && variant < 732) {
        return TraitOptionsClothing.BLUE_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 732 && variant < 752) {
        return TraitOptionsClothing.BLUE_TANKTOP;
      } else if (variant >= 752 && variant < 762) {
        return TraitOptionsClothing.BLUE_TOGA;
      } else if (variant >= 762 && variant < 782) {
        return TraitOptionsClothing.BLUE_TUBE_TOP;
      } else if (variant >= 782 && variant < 802) {
        return TraitOptionsClothing.BLUE_VEST;
      } else if (variant >= 802 && variant < 822) {
        return TraitOptionsClothing.BLUE_WAGMI_SHIRT;
      } else if (variant >= 822 && variant < 832) {
        return TraitOptionsClothing.BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 832 && variant < 837) {
        return TraitOptionsClothing.BLUE_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 837 && variant < 847) {
        return TraitOptionsClothing.BLUE_WITH_WHITE_APRON;
      } else if (variant >= 847 && variant < 852) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
      }

      // BEGIN RED PANDA ASSETS
      if (variant >= 852 && variant < 892) {
        return TraitOptionsClothing.RED_ERC20_SHIRT;
      } else if (variant >= 892 && variant < 932) {
        return TraitOptionsClothing.RED_FOX_WALLET_TANKTOP;
      } else if (variant >= 932 && variant < 972) {
        return TraitOptionsClothing.RED_GRADIENT_DIAMOND_SHIRT;
      } else if (variant >= 972 && variant < 1012) {
        return TraitOptionsClothing.RED_LINK_SHIRT;
      } else if (variant >= 1012 && variant < 1052) {
        return TraitOptionsClothing.RED_WEB3_SAFE_SHIRT;
      } else if (variant >= 1052 && variant < 1062) {
        return TraitOptionsClothing.MAGICIAN_UNIFORM_WITH_RED_CAPE;
      } else if (variant >= 1062 && variant < 1067) {
        return TraitOptionsClothing.RED_BEAR_LOVE_SHIRT;
      } else if (variant >= 1067 && variant < 1087) {
        return TraitOptionsClothing.RED_BEAR_MARKET_SHIRT;
      } else if (variant >= 1087 && variant < 1107) {
        return TraitOptionsClothing.RED_BULL_MARKET_SHIRT;
      } else if (variant >= 1107 && variant < 1127) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_DOTS;
      } else if (variant >= 1127 && variant < 1147) {
        return TraitOptionsClothing.RED_DRESS_WITH_WHITE_LACE;
      } else if (variant >= 1147 && variant < 1167) {
        return TraitOptionsClothing.RED_DRESS;
      } else if (variant >= 1167 && variant < 1187) {
        return TraitOptionsClothing.RED_ETH_SHIRT;
      } else if (variant >= 1187 && variant < 1207) {
        return TraitOptionsClothing.RED_FANNY_PACK;
      } else if (variant >= 1207 && variant < 1227) {
        return TraitOptionsClothing.RED_HOOLA_HOOP;
      } else if (variant >= 1227 && variant < 1247) {
        return TraitOptionsClothing.RED_HOOT_SHIRT;
      } else if (variant >= 1247 && variant < 1267) {
        return TraitOptionsClothing.RED_JESTERS_COLLAR;
      } else if (variant >= 1267 && variant < 1272) {
        return TraitOptionsClothing.RED_KNIT_SWEATER;
      } else if (variant >= 1272 && variant < 1292) {
        return TraitOptionsClothing.RED_LEG_WARMERS;
      } else if (variant >= 1292 && variant < 1297) {
        return TraitOptionsClothing.RED_OVERALLS;
      } else if (variant >= 1297 && variant < 1307) {
        return TraitOptionsClothing.RED_PINK_UNICORN_DEX_TANKTOP;
      } else if (variant >= 1307 && variant < 1309) {
        return TraitOptionsClothing.RED_PONCHO;
      } else if (variant >= 1309 && variant < 1329) {
        return TraitOptionsClothing.RED_PORTAL_SHIRT;
      } else if (variant >= 1329 && variant < 1369) {
        // PANDA ONLY
        return TraitOptionsClothing.BLUE_PROOF_OF_STAKE_SHIRT;
      } else if (variant >= 1369 && variant < 1399) {
        return TraitOptionsClothing.RED_PUFFY_VEST;
      } else if (variant >= 1399 && variant < 1409) {
        return TraitOptionsClothing.RED_REKT_SHIRT;
      }
      // Pandas Only
      else if (variant >= 1409 && variant < 1419) {
        return TraitOptionsClothing.NODE_OPERATORS_VEST;
      } else if (variant >= 1419 && variant < 1439) {
        return TraitOptionsClothing.RED_PROOF_OF_STAKE_SHIRT;
      } else if (variant >= 1439 && variant < 1459) {
        return TraitOptionsClothing.RED_RASPBERRY_PI_NODE_TANKTOP;
      } else if (variant >= 1459 && variant < 1479) {
        return TraitOptionsClothing.RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
      } else if (variant >= 1479 && variant < 1519) {
        return TraitOptionsClothing.RED_SKIRT;
      } else if (variant >= 1519 && variant < 1539) {
        return TraitOptionsClothing.RED_STRIPED_NECKTIE;
      } else if (variant >= 1539 && variant < 1559) {
        return TraitOptionsClothing.RED_SUIT_JACKET_WITH_GOLD_TIE;
      } else if (variant >= 1559 && variant < 1579) {
        return TraitOptionsClothing.RED_TANKTOP;
      } else if (variant >= 1579 && variant < 1584) {
        return TraitOptionsClothing.RED_TOGA;
      } else if (variant >= 1584 && variant < 1604) {
        return TraitOptionsClothing.RED_TUBE_TOP;
      } else if (variant >= 1604 && variant < 1614) {
        return TraitOptionsClothing.RED_VEST;
      } else if (variant >= 1614 && variant < 1634) {
        return TraitOptionsClothing.RED_WAGMI_SHIRT;
      } else if (variant >= 1634 && variant < 1654) {
        return TraitOptionsClothing.RED_WITH_PINK_AND_GREEN_DRESS;
      } else if (variant >= 1654 && variant < 1674) {
        return TraitOptionsClothing.RED_WITH_WHITE_APRON;
      } else if (variant >= 1674 && variant < 1684) {
        return TraitOptionsClothing.RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
      } else if (variant >= 1684 && variant < 1689) {
        return TraitOptionsClothing.WHITE_AND_RED_STRIPED_BIB;
      } else if (variant >= 1689 && variant < 1699) {
        return TraitOptionsClothing.WHITE_WITH_RED_DRESS;
      } else if (variant >= 1699 && variant < 1704) {
        return TraitOptionsClothing.WHITE_WITH_RED_STRIPES_TANKTOP;
      }
    } // end panda

    // 1704 - 2078
    if (variant >= 1704 && variant < 1714) {
      return TraitOptionsClothing.ADAMS_LEAF;
    } else if (variant >= 1714 && variant < 1724) {
      return TraitOptionsClothing.BLACK_BELT;
    } else if (variant >= 1724 && variant < 1744) {
      return TraitOptionsClothing.BLACK_LEATHER_JACKET;
    } else if (variant >= 1744 && variant < 1784) {
      return TraitOptionsClothing.BLACK_TUXEDO;
    } else if (variant >= 1784 && variant < 1804) {
      return TraitOptionsClothing.BORAT_SWIMSUIT;
    } else if (variant >= 1804 && variant < 1810) {
      return TraitOptionsClothing.BUTTERFLY_WINGS;
    } else if (variant >= 1810 && variant < 1830) {
      return TraitOptionsClothing.GRASS_SKIRT;
    } else if (variant >= 1830 && variant < 1850) {
      return TraitOptionsClothing.LEDERHOSEN;
    } else if (variant >= 1850 && variant < 1855) {
      return TraitOptionsClothing.ORANGE_INFLATABLE_WATER_WINGS;
    } else if (variant >= 1855 && variant < 1865) {
      return TraitOptionsClothing.ORANGE_PRISON_UNIFORM;
    } else if (variant >= 1865 && variant < 1870) {
      return TraitOptionsClothing.PINK_TUTU;
    } else if (variant >= 1870 && variant < 1890) {
      return TraitOptionsClothing.PINK_AND_TEAL_DEFI_LENDING_TANKTOP;
    } else if (variant >= 1890 && variant < 1900) {
      return TraitOptionsClothing.TAN_CARGO_SHORTS;
    } else if (variant >= 1900 && variant < 1904) {
      return TraitOptionsClothing.VAMPIRE_BAT_WINGS;
    } else if (variant >= 1904 && variant < 1944) {
      return TraitOptionsClothing.WHITE_TUXEDO;
    } else if (variant >= 1944 && variant < 2078) {
      return TraitOptionsClothing.NAKEY;
    }

    return TraitOptionsClothing.NAKEY;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsHat.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../../lib_constants/trait_options/TraitOptionsLocale.sol";
import "../Gene.sol";
import "./OptionSpecies.sol";
import "./OptionLocale.sol";

library OptionHat {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 hat = Gene.getGene(TraitDefs.HAT, dna);
    // uint16 variant = hat % 39;

    uint8 species = OptionSpecies.getOption(dna);
    uint8 locale = OptionLocale.getOption(dna);

    // 1(1000), 21(100), 6(50), 7(25), 5(10), 3(5)
    // 1000   , 2100,  300,  175, 50, 15
    // 3640

    uint16 rarityRoll = hat % 3640;

    if (rarityRoll < 1000) {
      // return none
      return TraitOptionsHat.NONE;
    } else if (rarityRoll >= 1000 && rarityRoll < 3100) {
      // return a weight 100 option

      uint16 variant = rarityRoll % 14;

      if (species != TraitOptionsSpecies.POLAR && rarityRoll % 2 == 0) {
        // BLUES
        if (variant == 0) {
          return TraitOptionsHat.BLACK_WITH_BLUE_HEADPHONES;
        } else if (variant == 1) {
          return TraitOptionsHat.BLACK_WITH_BLUE_TOP_HAT;
        } else if (variant == 2) {
          return TraitOptionsHat.BLUE_BASEBALL_CAP;
        } else if (variant == 3) {
          return TraitOptionsHat.TINY_BLUE_HAT;
        } else if (variant == 4) {
          return TraitOptionsHat.SHIRT_BLACK_AND_BLUE_BASEBALL_CAP;
        }
      }

      if (species != TraitOptionsSpecies.BLACK && rarityRoll % 2 == 1) {
        // REDS
        if (variant == 0) {
          return TraitOptionsHat.RED_BASEBALL_CAP;
        } else if (variant == 1) {
          return TraitOptionsHat.RED_SHOWER_CAP;
        } else if (variant == 2) {
          return TraitOptionsHat.TINY_RED_HAT;
        } else if (variant == 3) {
          return TraitOptionsHat.WHITE_AND_RED_BASEBALL_CAP;
        } else if (variant == 4) {
          return TraitOptionsHat.WHITE_WITH_RED_HEADPHONES;
        } else if (variant == 5) {
          return TraitOptionsHat.WHITE_WITH_RED_TOP_HAT;
        } else if (variant == 6) {
          return TraitOptionsHat.SHIRT_RED_UMBRELLA_HAT;
        }
      }

      if (variant == 7) {
        return TraitOptionsHat.BLACK_BOWLER_HAT;
      } else if (variant == 8) {
        return TraitOptionsHat.BLACK_TOP_HAT;
      } else if (variant == 9 && locale != TraitOptionsLocale.ASIAN) {
        return TraitOptionsHat.PINK_SUNHAT;
      } else if (variant == 10) {
        return TraitOptionsHat.TAN_COWBOY_HAT;
      } else if (variant == 11 && locale != TraitOptionsLocale.ASIAN) {
        return TraitOptionsHat.TAN_SUNHAT;
      } else if (variant == 12) {
        return TraitOptionsHat.WHITE_BOWLER_HAT;
      } else if (variant == 13) {
        return TraitOptionsHat.WHITE_TOP_HAT;
      }
    } else if (rarityRoll >= 3100 && rarityRoll < 3400) {
      // return a weight 50 option

      if (species == TraitOptionsSpecies.BLACK) {
        return TraitOptionsHat.GRADUATION_CAP_WITH_BLUE_TASSEL;
      } else if (species == TraitOptionsSpecies.POLAR) {
        return TraitOptionsHat.GRADUATION_CAP_WITH_RED_TASSEL;
      } else {
        if (rarityRoll % 2 == 0) {
          return TraitOptionsHat.RED_DEFI_WIZARD_HAT;
        } else {
          return TraitOptionsHat.RED_SPORTS_HELMET;
        }
      }
    } else if (rarityRoll >= 3400 && rarityRoll < 3575) {
      // return weight 25
      uint16 variant = rarityRoll % 4;
      if (
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        variant = rarityRoll % 5;
      }

      if (variant == 0) {
        return TraitOptionsHat.BLACK_AND_WHITE_STRIPED_JAIL_CAP;
      } else if (variant == 1) {
        if (species == TraitOptionsSpecies.BLACK) {
          return TraitOptionsHat.BLUE_UMBRELLA_HAT;
        } else if (species == TraitOptionsSpecies.POLAR) {
          return TraitOptionsHat.RED_UMBRELLA_HAT;
        } else {
          // is a panda
          if (rarityRoll % 2 == 0) {
            return TraitOptionsHat.BLUE_UMBRELLA_HAT;
          } else {
            return TraitOptionsHat.RED_UMBRELLA_HAT;
          }
        }
      } else if (variant == 2) {
        return TraitOptionsHat.PINK_BUTTERFLY;
      }
      if (variant == 3) {
        if (species == TraitOptionsSpecies.BLACK) {
          return TraitOptionsHat.ASTRONAUT_HELMET; // Blue
        } else if (species == TraitOptionsSpecies.POLAR) {
          return TraitOptionsHat.RED_ASTRONAUT_HELMET;
        } else {
          // is a panda
          if (rarityRoll % 2 == 0) {
            return TraitOptionsHat.ASTRONAUT_HELMET;
          } else {
            return TraitOptionsHat.RED_ASTRONAUT_HELMET;
          }
        }
      } else if (variant == 4) {
        return TraitOptionsHat.NODE_OPERATORS_YELLOW_HARDHAT;
      }
    } else if (rarityRoll >= 3575 && rarityRoll < 3625) {
      // return weight 10
      uint16 variant = rarityRoll % 3;
      if (
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        variant = rarityRoll % 5;
      }

      if (variant == 0) {
        return TraitOptionsHat.CHERRY_ON_TOP;
      } else if (variant == 1) {
        return TraitOptionsHat.GREEN_GOO;
      } else if (variant == 2) {
        return TraitOptionsHat.POLICE_CAP;
      } else if (variant == 3) {
        // !B!W
        return TraitOptionsHat.CRYPTO_INFLUENCER_BLUEBIRD;
      } else if (variant == 4) {
        // !B!W
        return TraitOptionsHat.BULB_HELMET;
      }
    } else {
      // return a weight 5 option
      if (
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        uint16 variant = rarityRoll % 3;
        if (variant == 0) {
          return TraitOptionsHat.GIANT_SUNFLOWER;
        } else if (variant == 1) {
          return TraitOptionsHat.GOLD_CHALICE;
        } else if (variant == 2) {
          return TraitOptionsHat.BAG_OF_ETHEREUM;
        }
        return TraitOptionsHat.BAG_OF_ETHEREUM;
      }
    }

    return TraitOptionsHat.NONE;
  }
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

library TraitOptionsLocale {
  uint8 constant NORTH_AMERICAN = 0;
  uint8 constant SOUTH_AMERICAN = 1;
  uint8 constant ASIAN = 2;
  uint8 constant EUROPEAN = 3;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsLocale.sol";
import "../Gene.sol";

library OptionLocale {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 locale = Gene.getGene(TraitDefs.LOCALE, dna);
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsFaceAccessory.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../../lib_constants/trait_options/TraitOptionsLocale.sol";
import "./OptionSpecies.sol";
import "./OptionLocale.sol";
import "../Gene.sol";

library OptionFaceAccessory {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 faceAccessory = Gene.getGene(TraitDefs.FACE_ACCESSORY, dna);
    // uint16 variant = faceAccessory % 24;
    uint16 rarityRoll = faceAccessory % 3575;
    uint8 species = OptionSpecies.getOption(dna);
    uint8 locale = OptionLocale.getOption(dna);

    // 1(2000) + 11(100) + 8(50) + 3(25)
    // 2000 + 1100 + 400 + 75
    // 3575

    if (rarityRoll < 2000) {
      // none
      return TraitOptionsFaceAccessory.NONE;
    } else if (rarityRoll >= 2000 && rarityRoll < 3100) {
      // 100 weight
      uint16 coinFlip = rarityRoll % 2;
      uint16 variant = rarityRoll % 7;

      // if black or panda == 0
      if (species != TraitOptionsSpecies.POLAR && coinFlip == 0) {
        if (variant == 0) {
          return
            TraitOptionsFaceAccessory.BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
        } else if (variant == 1) {
          return TraitOptionsFaceAccessory.BLUE_FRAMED_GLASSES;
        } else if (variant == 2) {
          return TraitOptionsFaceAccessory.BLUE_MEDICAL_MASK;
        } else if (variant == 3) {
          return TraitOptionsFaceAccessory.BLUE_NINJA_MASK;
        } else if (variant == 4) {
          return TraitOptionsFaceAccessory.BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
        } else if (variant == 5) {
          return TraitOptionsFaceAccessory.BLUE_VERBS_GLASSES;
        } else if (variant == 6) {
          return TraitOptionsFaceAccessory.BLUE_AND_BLACK_CHECKERED_BANDANA;
        }
      }
      // if polar or panda
      if (species != TraitOptionsSpecies.BLACK && coinFlip == 1) {
        if (variant == 0) {
          return TraitOptionsFaceAccessory.RED_FRAMED_GLASSES;
        } else if (variant == 1) {
          return TraitOptionsFaceAccessory.RED_MEDICAL_MASK;
        } else if (variant == 2) {
          return TraitOptionsFaceAccessory.RED_NINJA_MASK;
        } else if (variant == 3) {
          return TraitOptionsFaceAccessory.RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
        } else if (variant == 4) {
          return TraitOptionsFaceAccessory.RED_VERBS_GLASSES;
        } else if (variant == 5) {
          return TraitOptionsFaceAccessory.RED_AND_WHITE_CHECKERED_BANDANA;
        } else if (variant == 6) {
          return
            TraitOptionsFaceAccessory.WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
        }
      }
    } else if (rarityRoll >= 3100 && rarityRoll < 3500) {
      uint16 variant = rarityRoll % 4;

      // 50 weight
      if (variant == 0 && locale != TraitOptionsLocale.NORTH_AMERICAN) {
        return TraitOptionsFaceAccessory.BLACK_NINJA_MASK;
      } else if (variant == 1 && locale != TraitOptionsLocale.NORTH_AMERICAN) {
        return TraitOptionsFaceAccessory.WHITE_NINJA_MASK;
      } else if (variant == 2) {
        return TraitOptionsFaceAccessory.CANDY_CANE;
      } else if (variant == 3) {
        return TraitOptionsFaceAccessory.BROWN_FRAMED_GLASSES;
      }
    } else if (rarityRoll >= 3500) {
      uint16 variant = rarityRoll % 4;

      // 25 weight
      if (variant == 0) {
        return TraitOptionsFaceAccessory.GOLD_FRAMED_MONOCLE;
      } else if (variant == 1) {
        return TraitOptionsFaceAccessory.GRAY_BEARD;
      } else if (variant == 2) {
        return TraitOptionsFaceAccessory.HEAD_CONE;
        // } else if (variant == 3) {
        // return TraitOptionsFaceAccessory.CLOWN_FACE_PAINT; // special
      } else if (variant == 3) {
        return TraitOptionsFaceAccessory.DRIPPING_HONEY; // special
      }
    }

    return TraitOptionsFaceAccessory.NONE;
  }
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
  // uint8 constant CLOWN_FACE_PAINT = 22;
  uint8 constant DRIPPING_HONEY = 23;
  // moved from jewelry
  // uint8 constant GOLD_STUD_EARRINGS = 24;
  // uint8 constant SILVER_STUD_EARRINGS = 24;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "../../lib_constants/trait_options/TraitOptionsFootwear.sol";
import "./OptionSpecies.sol";
import "../Gene.sol";

library OptionFootwear {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 footwear = Gene.getGene(TraitDefs.FOOTWEAR, dna);
    uint16 rarityRoll = footwear % 29;
    uint8 species = OptionSpecies.getOption(dna);

    if (
      species != TraitOptionsSpecies.POLAR &&
      species != TraitOptionsSpecies.REVERSE_PANDA
    ) {
      if (rarityRoll == 0) {
        return TraitOptionsFootwear.BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE;
      } else if (rarityRoll == 1) {
        return TraitOptionsFootwear.BLUE_CROCS;
      } else if (rarityRoll == 2) {
        return TraitOptionsFootwear.BLUE_FLIP_FLOPS;
      } else if (rarityRoll == 3) {
        return TraitOptionsFootwear.BLUE_HIGH_HEELS;
      } else if (rarityRoll == 4) {
        return TraitOptionsFootwear.BLUE_SNEAKERS;
      } else if (rarityRoll == 5) {
        return TraitOptionsFootwear.BLUE_TOENAIL_POLISH;
      } else if (rarityRoll == 6) {
        return TraitOptionsFootwear.BLUE_WORK_BOOTS;
      } else if (rarityRoll == 7) {
        return TraitOptionsFootwear.BLUE_AND_GRAY_BASKETBALL_SNEAKERS;
      }
    }

    if (species != TraitOptionsSpecies.BLACK) {
      if (rarityRoll == 0) {
        return TraitOptionsFootwear.RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE;
      } else if (rarityRoll == 1) {
        return TraitOptionsFootwear.RED_CROCS;
      } else if (rarityRoll == 2) {
        return TraitOptionsFootwear.RED_FLIP_FLOPS;
      } else if (rarityRoll == 3) {
        return TraitOptionsFootwear.RED_HIGH_HEELS;
      } else if (rarityRoll == 6) {
        return TraitOptionsFootwear.RED_WORK_BOOTS;
      } else if (rarityRoll == 7) {
        return TraitOptionsFootwear.RED_AND_GRAY_BASKETBALL_SNEAKERS;
      }
    }

    if (rarityRoll == 8) {
      return TraitOptionsFootwear.BLACK_GLADIATOR_SANDALS;
    } else if (rarityRoll == 9) {
      return TraitOptionsFootwear.BLACK_SNEAKERS;
    } else if (rarityRoll == 10) {
      return TraitOptionsFootwear.BLACK_AND_BLUE_SNEAKERS;
    } else if (rarityRoll == 11) {
      return TraitOptionsFootwear.BLACK_AND_WHITE_SNEAKERS;
    } else if (rarityRoll == 12) {
      return TraitOptionsFootwear.PINK_HIGH_HEELS;
    } else if (rarityRoll == 13) {
      return TraitOptionsFootwear.PINK_TOENAIL_POLISH;
    } else if (rarityRoll == 14) {
      return TraitOptionsFootwear.PINK_WORK_BOOTS;
    } else if (rarityRoll == 15) {
      return TraitOptionsFootwear.TAN_COWBOY_BOOTS;
    } else if (rarityRoll == 16) {
      return TraitOptionsFootwear.TAN_WORK_BOOTS;
    } else if (rarityRoll == 17) {
      return TraitOptionsFootwear.WHITE_SNEAKERS;
    } else if (rarityRoll == 18) {
      return TraitOptionsFootwear.WHITE_AND_RED_SNEAKERS;
    } else if (rarityRoll == 19) {
      return TraitOptionsFootwear.YELLOW_RAIN_BOOTS;
    }

    // if panda
    if (
      rarityRoll == 20 &&
      species != TraitOptionsSpecies.BLACK &&
      species != TraitOptionsSpecies.POLAR
    ) {
      return TraitOptionsFootwear.STEPPED_IN_A_PUMPKIN;
    } else if (
      rarityRoll == 21 &&
      species != TraitOptionsSpecies.BLACK &&
      species != TraitOptionsSpecies.POLAR
    ) {
      return TraitOptionsFootwear.WATERMELON_SHOES;
    }

    return TraitOptionsFootwear.NONE;
  }
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
  uint8 constant NONE = 29;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsAccessories.sol";
import "../../lib_constants/trait_options/TraitOptionsSpecies.sol";
import "./OptionSpecies.sol";
import "../Gene.sol";

library OptionAccessories {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 accessory = Gene.getGene(TraitDefs.ACCESSORIES, dna);
    // uint16 variant = accessory % 40;
    uint16 rarityRoll = accessory % 4050;
    uint8 species = OptionSpecies.getOption(dna);

    // 1(1000) + 22(100) + 12(50) + 5(50)
    // 1000 + 2200 + 600 + 250
    // 4050

    if (rarityRoll < 1000) {
      return TraitOptionsAccessories.NONE;
    } else if (rarityRoll >= 1000 && rarityRoll < 3200) {
      // return 100 weight
      uint16 coinFlip = rarityRoll % 2;
      uint16 variant = rarityRoll % 17;

      // if BLACK or panda
      if (species != TraitOptionsSpecies.POLAR && coinFlip == 0) {
        if (variant == 0) {
          return TraitOptionsAccessories.BLUE_BALLOON;
        } else if (variant == 1) {
          return TraitOptionsAccessories.BLUE_BOXING_GLOVES;
        } else if (variant == 2) {
          return TraitOptionsAccessories.BLUE_FINGERNAIL_POLISH;
        } else if (variant == 3) {
          return TraitOptionsAccessories.BLUE_GARDENER_TROWEL;
        } else if (variant == 4) {
          return TraitOptionsAccessories.BLUE_MERGE_BEARS_FOAM_FINGER;
        } else if (variant == 5) {
          return TraitOptionsAccessories.BLUE_PURSE;
        } else if (variant == 6) {
          return TraitOptionsAccessories.BLUE_SPATULA;
        } else if (variant == 7) {
          return TraitOptionsAccessories.BUCKET_OF_BLUE_PAINT;
        } else if (variant == 8) {
          return TraitOptionsAccessories.HAND_IN_A_BLUE_COOKIE_JAR;
        } else if (variant == 9) {
          return
            TraitOptionsAccessories.PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET;
        }
      }

      if (species != TraitOptionsSpecies.BLACK && coinFlip == 1) {
        // if polar or panda
        if (variant == 0) {
          return TraitOptionsAccessories.BUCKET_OF_RED_PAINT;
        } else if (variant == 1) {
          return TraitOptionsAccessories.HAND_IN_A_RED_COOKIE_JAR;
        } else if (variant == 2) {
          return
            TraitOptionsAccessories.PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET;
        } else if (variant == 3) {
          return TraitOptionsAccessories.RED_BALLOON;
        } else if (variant == 4) {
          return TraitOptionsAccessories.RED_BOXING_GLOVES;
        } else if (variant == 5) {
          return TraitOptionsAccessories.RED_FINGERNAIL_POLISH;
        } else if (variant == 6) {
          return TraitOptionsAccessories.RED_GARDENER_TROWEL;
        } else if (variant == 7) {
          return TraitOptionsAccessories.RED_MERGE_BEARS_FOAM_FINGER;
        } else if (variant == 8) {
          return TraitOptionsAccessories.RED_PURSE;
        } else if (variant == 9) {
          return TraitOptionsAccessories.RED_SPATULA;
        }
      }

      if (variant == 10) {
        return TraitOptionsAccessories.PINK_FINGERNAIL_POLISH;
      } else if (variant == 11) {
        return TraitOptionsAccessories.PINK_PURSE;
      } else if (variant == 12) {
        return TraitOptionsAccessories.BANHAMMER;
      } else if (variant == 13) {
        return TraitOptionsAccessories.BEEHIVE_ON_A_STICK;
      } else if (variant == 14) {
        return TraitOptionsAccessories.DOUBLE_DUMBBELLS;
      } else if (variant == 15) {
        return TraitOptionsAccessories.TOILET_PAPER;
      } else if (variant == 16) {
        return TraitOptionsAccessories.WOODEN_WALKING_CANE;
      }
    } else if (rarityRoll >= 3200 && rarityRoll < 3800) {
      uint16 variant = rarityRoll % 17;

      // return 50 weight
      if (variant == 0) {
        return TraitOptionsAccessories.BALL_AND_CHAIN;
      } else if (variant == 1) {
        return TraitOptionsAccessories.BAMBOO_SWORD;
      }
      if (
        variant == 2 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.BASKET_OF_EXCESS_USED_GRAPHICS_CARDS;
      } else if (
        variant == 3 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.BURNED_OUT_GRAPHICS_CARD;
      } else if (
        variant == 4 &&
        species != TraitOptionsSpecies.PANDA &&
        species != TraitOptionsSpecies.REVERSE_PANDA &&
        species != TraitOptionsSpecies.GOLD_PANDA
      ) {
        return TraitOptionsAccessories.MINERS_PICKAXE;
      } else if (variant == 5) {
        return TraitOptionsAccessories.NINJA_SWORDS;
      } else if (
        variant == 6 &&
        species != TraitOptionsSpecies.BLACK &&
        species != TraitOptionsSpecies.POLAR
      ) {
        return TraitOptionsAccessories.PROOF_OF_RIBEYE_STEAK;
      } else if (variant == 7) {
        return TraitOptionsAccessories.FRESH_SALMON;
      }
    } else if (rarityRoll >= 3800) {
      uint16 variant = rarityRoll % 4;

      // return 25 weight
      if (variant == 0) {
        return TraitOptionsAccessories.PHISHING_NET;
      } else if (variant == 1) {
        return TraitOptionsAccessories.PHISHING_ROD;
      }
      if (variant == 2) {
        return TraitOptionsAccessories.COLD_STORAGE_WALLET;
      } else if (variant == 3) {
        return TraitOptionsAccessories.HOT_WALLET;
      }
    }
    return TraitOptionsAccessories.NONE;
  }
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
    // TODO: Map NONE to Accessories' NONE to avoid redeployment
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

library TraitOptionsBelly {
  uint8 constant LARGE = 0;
  uint8 constant SMALL = 1;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsBelly.sol";
import "../Gene.sol";

library OptionBelly {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 belly = Gene.getGene(TraitDefs.BELLY, dna);
    uint16 variant = belly % 5;

    if (variant == 0) {
      return TraitOptionsBelly.LARGE;
    } else if (variant == 1) {
      return TraitOptionsBelly.SMALL;
    }
    return TraitOptionsBelly.LARGE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Assets & Layers
import "../lib_constants/AssetContracts.sol";
import "../lib_constants/LayerOrder.sol";
import "../lib_constants/TraitDefs.sol";
import "../lib_env/Rinkeby.sol";

// Utilities
import "../lib_utilities/UtilAssets.sol";

// Internal Extensions
import "../extensions/Owner.sol";

interface IAssetLibrary {
  function getAsset(uint256) external pure returns (string memory);
}

interface ITraitsUtility {
  function getOption(uint8 traitDef, uint256 dna) external pure returns (uint8);
}

contract Animation is Owner {
  using Strings for uint256;

  mapping(uint8 => address) public assetContracts;
  address traitsUtility;

  constructor() {
    // pre-link asset contracts
    assetContracts[AssetContracts.ACCESSORIES] = Rinkeby.ACCESSORIES;
    assetContracts[AssetContracts.ARMS] = Rinkeby.ARMS;
    assetContracts[AssetContracts.BELLY] = Rinkeby.BELLY;
    assetContracts[AssetContracts.CLOTHINGA] = Rinkeby.CLOTHINGA;
    assetContracts[AssetContracts.CLOTHINGB] = Rinkeby.CLOTHINGB;
    assetContracts[AssetContracts.EYES] = Rinkeby.EYES;
    assetContracts[AssetContracts.FACE] = Rinkeby.FACE;
    assetContracts[AssetContracts.FEET] = Rinkeby.FEET;
    assetContracts[AssetContracts.FOOTWEAR] = Rinkeby.FOOTWEAR;
    assetContracts[AssetContracts.HAT] = Rinkeby.HAT;
    assetContracts[AssetContracts.HEAD] = Rinkeby.HEAD;
    assetContracts[AssetContracts.JEWELRY] = Rinkeby.JEWELRY;
    assetContracts[AssetContracts.MOUTH] = Rinkeby.MOUTH;
    assetContracts[AssetContracts.NOSE] = Rinkeby.NOSE;
    assetContracts[AssetContracts.SPECIAL_CLOTHING] = Rinkeby.SPECIAL_CLOTHING;
    assetContracts[AssetContracts.SPECIAL_FACE] = Rinkeby.SPECIAL_FACE;

    // Utility linker
    traitsUtility = Rinkeby.TraitsUtility;
  }

  function setAssetContract(uint8 assetId, address assetContract)
    external
    onlyOwner
  {
    assetContracts[assetId] = assetContract;
  }

  function setTraitsUtility(address traitsUtilityContract) external onlyOwner {
    traitsUtility = traitsUtilityContract;
  }

  function divWithBackground(string memory dataURI)
    internal
    pure
    returns (string memory)
  {
    return
      string.concat(
        '<div class="b" style="background-image:url(data:image/png;base64,',
        dataURI,
        ')"></div>'
      );
  }

  function fetchAssetString(uint8 layer, uint256 assetNum)
    internal
    view
    returns (string memory)
  {
    // iterating in LayerOrder
    if (layer == LayerOrder.BELLY) {
      return
        IAssetLibrary(assetContracts[AssetContracts.BELLY]).getAsset(assetNum);
    } else if (layer == LayerOrder.ARMS) {
      return
        IAssetLibrary(assetContracts[AssetContracts.ARMS]).getAsset(assetNum);
    } else if (layer == LayerOrder.FEET) {
      return
        IAssetLibrary(assetContracts[AssetContracts.FEET]).getAsset(assetNum);
    } else if (layer == LayerOrder.FOOTWEAR) {
      return
        IAssetLibrary(assetContracts[AssetContracts.FOOTWEAR]).getAsset(
          assetNum
        );
      // special logic for clothing since we had to deploy two contracts to fit
    } else if (layer == LayerOrder.CLOTHING) {
      if (assetNum < 54) {
        return
          IAssetLibrary(assetContracts[AssetContracts.CLOTHINGA]).getAsset(
            assetNum
          );
      } else {
        return
          IAssetLibrary(assetContracts[AssetContracts.CLOTHINGB]).getAsset(
            assetNum
          );
      }
    } else if (layer == LayerOrder.HEAD) {
      return
        IAssetLibrary(assetContracts[AssetContracts.HEAD]).getAsset(assetNum);
    } else if (layer == LayerOrder.SPECIAL_FACE) {
      return
        IAssetLibrary(assetContracts[AssetContracts.SPECIAL_FACE]).getAsset(
          assetNum
        );
    } else if (layer == LayerOrder.EYES) {
      return
        IAssetLibrary(assetContracts[AssetContracts.EYES]).getAsset(assetNum);
    } else if (layer == LayerOrder.MOUTH) {
      return
        IAssetLibrary(assetContracts[AssetContracts.MOUTH]).getAsset(assetNum);
    } else if (layer == LayerOrder.NOSE) {
      return
        IAssetLibrary(assetContracts[AssetContracts.NOSE]).getAsset(assetNum);
    } else if (layer == LayerOrder.JEWELRY) {
      return
        IAssetLibrary(assetContracts[AssetContracts.JEWELRY]).getAsset(
          assetNum
        );
    } else if (layer == LayerOrder.HAT) {
      return
        IAssetLibrary(assetContracts[AssetContracts.HAT]).getAsset(assetNum);
    } else if (layer == LayerOrder.FACE) {
      return
        IAssetLibrary(assetContracts[AssetContracts.FACE]).getAsset(assetNum);
    } else if (layer == LayerOrder.SPECIAL_CLOTHING) {
      return
        IAssetLibrary(assetContracts[AssetContracts.SPECIAL_CLOTHING]).getAsset(
          assetNum
        );
    } else if (layer == LayerOrder.ACCESSORIES) {
      return
        IAssetLibrary(assetContracts[AssetContracts.ACCESSORIES]).getAsset(
          assetNum
        );
    }
    return "";
  }

  struct TraitOptions {
    uint8 accessories;
    uint8 background;
    uint8 belly;
    uint8 clothing;
    uint8 eyes;
    uint8 faceAccessory;
    uint8 footwear;
    uint8 hat;
    uint8 jewelry;
    uint8 locale;
    uint8 mouth;
    uint8 nose;
    uint8 species;
  }

  struct AssetStrings {
    string background;
    string belly;
    string arms;
    string feet;
    string footwear;
    string clothing;
    string head;
    string eyes;
    string mouth;
    string nose;
    string jewelry;
    string hat;
    string faceAccessory;
    string accessory;
  }

  struct AssetStringsBody {
    string background;
    string belly;
    string arms;
    string feet;
    string footwear;
    string clothing;
    string jewelry;
    string accessory;
  }

  struct AssetStringsHead {
    string head;
    string eyes;
    string mouth;
    string nose;
    string hat;
    string faceAccessory;
  }

  struct TraitOptionsHead {
    uint8 eyes;
    uint8 faceAccessory;
    uint8 hat;
    uint8 jewelry;
    uint8 mouth;
    uint8 nose;
  }

  function getHeadHTML(TraitOptions memory traitOptions)
    internal
    view
    returns (string memory)
  {
    AssetStringsHead memory headAssetStrings;

    headAssetStrings.head = divWithBackground(
      fetchAssetString(
        LayerOrder.HEAD,
        UtilAssets.getAssetHead(traitOptions.species, traitOptions.locale)
      )
    );
    headAssetStrings.eyes = divWithBackground(
      fetchAssetString(
        LayerOrder.EYES,
        UtilAssets.getAssetEyes(traitOptions.eyes)
      )
    );
    headAssetStrings.mouth = divWithBackground(
      fetchAssetString(
        LayerOrder.MOUTH,
        UtilAssets.getAssetMouth(traitOptions.mouth)
      )
    );
    headAssetStrings.nose = divWithBackground(
      fetchAssetString(
        LayerOrder.NOSE,
        UtilAssets.getAssetNose(traitOptions.nose)
      )
    );
    headAssetStrings.hat = divWithBackground(
      fetchAssetString(LayerOrder.HAT, UtilAssets.getAssetHat(traitOptions.hat))
    );
    headAssetStrings.faceAccessory = divWithBackground(
      fetchAssetString(
        LayerOrder.FACE,
        UtilAssets.getAssetFaceAccessory(traitOptions.faceAccessory)
      )
    );

    // return them
    return
      string.concat(
        '<div class="b h">',
        headAssetStrings.head,
        // insert special face accessories here
        headAssetStrings.eyes,
        headAssetStrings.mouth,
        headAssetStrings.nose,
        headAssetStrings.hat,
        headAssetStrings.faceAccessory,
        "</div>"
      );
  }

  function getTraitOptions(uint256 dna)
    internal
    view
    returns (TraitOptions memory)
  {
    TraitOptions memory traitOptions;

    traitOptions.eyes = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.EYES,
      dna
    );

    traitOptions.faceAccessory = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.FACE_ACCESSORY,
      dna
    );

    traitOptions.hat = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.HAT,
      dna
    );
    traitOptions.mouth = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.MOUTH,
      dna
    );
    traitOptions.nose = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.NOSE,
      dna
    );

    traitOptions.accessories = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.ACCESSORIES,
      dna
    );

    traitOptions.background = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.BACKGROUND,
      dna
    );

    traitOptions.belly = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.BELLY,
      dna
    );

    traitOptions.clothing = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.CLOTHING,
      dna
    );

    traitOptions.footwear = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.FOOTWEAR,
      dna
    );

    traitOptions.jewelry = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.JEWELRY,
      dna
    );

    traitOptions.locale = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.LOCALE,
      dna
    );

    traitOptions.species = ITraitsUtility(traitsUtility).getOption(
      TraitDefs.SPECIES,
      dna
    );

    return traitOptions;
  }

  function animationURI(uint256 dna) external view returns (bytes memory) {
    AssetStringsBody memory assetStrings;
    TraitOptions memory traitOptions = getTraitOptions(dna);

    {
      assetStrings.background = UtilAssets.getAssetBackground(
        traitOptions.background
      );
    }
    {
      assetStrings.belly = divWithBackground(
        fetchAssetString(
          LayerOrder.BELLY,
          UtilAssets.getAssetBelly(traitOptions.species, traitOptions.belly)
        )
      );
    }
    {
      assetStrings.arms = divWithBackground(
        fetchAssetString(
          LayerOrder.ARMS,
          UtilAssets.getAssetArms(traitOptions.species)
        )
      );
    }
    {
      assetStrings.feet = divWithBackground(
        fetchAssetString(
          LayerOrder.FEET,
          UtilAssets.getAssetFeet(traitOptions.species)
        )
      );
    }
    {
      assetStrings.footwear = divWithBackground(
        fetchAssetString(
          LayerOrder.FOOTWEAR,
          UtilAssets.getAssetFootwear(traitOptions.footwear)
        )
      );
    }
    {
      assetStrings.clothing = divWithBackground(
        fetchAssetString(
          LayerOrder.CLOTHING,
          UtilAssets.getAssetClothing(traitOptions.clothing)
        )
      );
    }
    {
      assetStrings.accessory = divWithBackground(
        fetchAssetString(
          LayerOrder.ACCESSORIES,
          UtilAssets.getAssetAccessories(traitOptions.accessories)
        )
      );
    }
    {
      assetStrings.jewelry = divWithBackground(
        fetchAssetString(
          LayerOrder.JEWELRY,
          UtilAssets.getAssetJewelry(traitOptions.jewelry)
        )
      );
    }

    // TODO: Honey drip, clown face, earrings should be in face accessory
    // prettier-ignore
    return
      abi.encodePacked(
        "data:text/html;base64,",
        Base64.encode(
          abi.encodePacked(
            '<html><head><style>body,html{margin:0;display:flex;justify-content:center;align-items:center;background:', assetStrings.background, ';overflow:hidden}.a{width:min(100vw,100vh);height:min(100vw,100vh);position:relative}.b{width:100%;height:100%;background:100%/100%;image-rendering:pixelated;position:absolute}.h{animation:1s ease-in-out infinite d}@keyframes d{0%,100%{transform:translate3d(-1%,0,0)}25%,75%{transform:translate3d(0,2%,0)}50%{transform:translate3d(1%,0,0)}}</style></head><body>',
              '<div class="a">',
                assetStrings.belly,
                assetStrings.arms,
                assetStrings.feet,
                assetStrings.footwear,
                assetStrings.clothing,
                assetStrings.jewelry,
                getHeadHTML(traitOptions),
                assetStrings.accessory,
              '</div>',
            '</body></html>'
          )
        )
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Special_Face {
  using Strings for uint256;
  string constant SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////5TMxUGv/////saxS2QAAAAR0Uk5T////AEAqqfQAAABrSURBVHja7NTLCoAwDETRSfz/f5aAaDbRkqJUuNm1MIc2fWibLAEALA/orB4gjQgayt8ICwPSmKAy7znupVDOuychBp8DsWo7qrOFaKLZJah1Cimv3j14zr/6mPiRAAAAAAAAAAD+C+wCDACP0C3R4VTJFQAAAABJRU5ErkJggg==";

  string constant SPECIAL_FACE_FACE_SPECIAL___DRIPPING_HONEY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAaUlEQVR42uzTSw6AIAwA0en9L22wJrpRaUlcmGFDAu2j/IjFhoCAgMDnANVxJhe6B7gGQbWCkZRljFyonwEpHF19C3suSTQriDiJoHWN5DSPYZNA+yHxGsbqK/U7CwgICAgICPwQ2AQYAHSlD8A9jYRxAAAAAElFTkSuQmCC";

  string constant SPECIAL_FACE_FACE_SPECIAL___HEAD_CONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////////VXz1bAAAAAJ0Uk5T/wDltzBKAAAAdElEQVR42uyUMQrAMAwD7f9/uluhIDkKIdDhMjq6G+w41YenECC4Jqidqgo6gaqXiumkvqiUd1eXBKbhieC4B2/wG5XFaYzuZA9ph++p3wlvdiHne5xYwNttTHm/ziE//gdrmj8RAQIECBAgQIDgp4JHgAEAXLkO+5ppVzQAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT;
    } else if (assetNum == 1) {
      return SPECIAL_FACE_FACE_SPECIAL___DRIPPING_HONEY;
    } else if (assetNum == 2) {
      return SPECIAL_FACE_FACE_SPECIAL___HEAD_CONE;
    }
    return SPECIAL_FACE_FACE_SPECIAL___CLOWN_FACE_PAINT;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Special_Clothing {
  using Strings for uint256;

  string constant SPECIAL_CLOTHING_SHIRT___GHOST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAAzs7O////E2eUFAAAAAR0Uk5T////AEAqqfQAAADsSURBVHja7NfhDoMgDATga/f+77woaEBLvcpEY8YfiHqfrdmM4NM58G5A1nEKEME6HANEPBExYBOfiQhg5FvCQwEz3xCuBKaz1SIIpNPlYhwgsFswBfDPsBtQFpD5YlZ4IlDltQYMIQKYJZiAohPY5/NCCUDgAfsSQBXglACqAKcEkP+DOKAmgCNAintxQgtQ/BoACzQ6iALtvA8QHWwFEB3oaUDvAzZJDQBmsp7OA3lmAHhQB5DmW4CqhyHA7hdU9jACUOetfDGQBReQg9f6NPIWYfnkr49Rn3nLdcV+pbVxefmu7Q+MAr4CDACcJh9f/5NQsQAAAABJRU5ErkJggg==";

  function getAsset(uint256 headNum) external pure returns (string memory) {
    if (headNum == 0) {
      return SPECIAL_CLOTHING_SHIRT___GHOST;
    }
    return SPECIAL_CLOTHING_SHIRT___GHOST;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Nose {
  using Strings for uint256;
  string constant NOSE_NOSE___BLACK_NOSTRILS_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOUlEQVR42uzRwQkAMAwDMWf/pVu6gqGf6AYQGGfKAgAAAH+AvBrgEpNqQuJGAAAAAAAAAMBO4AgwAI81D/VRpyjKAAAAAElFTkSuQmCC";

  string constant NOSE_NOSE___BLACK_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAANUlEQVR42uzRwQkAMAwDsev+Szc75FWqG0AY3FkWAAAAvAI07RaUFwAAAAAAAAAAfwJXgAEA1IYP+9jVtBMAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___BLUE_NOSTRILS_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFQFbNOk65////QZQLLAAAAAN0Uk5T//8A18oNQQAAADlJREFUeNrs0UEKACAQAkDr/48u+oKwl0Y8D4jZZQIAAAAzQF4aYOW2mpC4EQAAAAAAAADwJ3AEGAD3kR/nhgLxZAAAAABJRU5ErkJggg==";

  string constant NOSE_NOSE___PINK_NOSTRILS_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6Jr/yqLV////hVu2pwAAAAN0Uk5T//8A18oNQQAAADlJREFUeNrs0UEKACAQAkDr/48u+oKwl0Y8D4jZZQIAAAAzQF4aYOW2mpC4EQAAAAAAAADwJ3AEGAD3kR/nhgLxZAAAAABJRU5ErkJggg==";

  string constant NOSE_NOSE___RUNNY_BLACK_NOSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAUf9a////Kts8ygAAAAN0Uk5T//8A18oNQQAAADpJREFUeNrs0sEJADAMAzGn+w9dyAqBhoJuAD2Mc4YFAAAA3gDpNoEWarpB+QEAAAAAAAAA4EPgCjAAnvkf31y6WrwAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___SMALL_BLUE_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFQFbN////mfWZAQAAAAJ0Uk5T/wDltzBKAAAANUlEQVR42uzRwQkAMAwDsev+Szc75FWqG0AY3FkWAAAAvAI07RaUFwAAAAAAAAAAfwJXgAEA1IYP+9jVtBMAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___SMALL_PINK_NOSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6Jr/////Gn0/cgAAAAJ0Uk5T/wDltzBKAAAANUlEQVR42uzRwQkAMAwDsev+Szc75FWqG0AY3FkWAAAAvAI07RaUFwAAAAAAAAAAfwJXgAEA1IYP+9jVtBMAAAAASUVORK5CYII=";

  string constant NOSE_NOSE___WIDE_BLACK_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzRsQkAMAwDQXn/pQNZIIUhBnPf6xqlmgUAAAD+ALlNAvXcuxEAAAAAAAAAsBU4AgwAYoUP8bYcFD0AAAAASUVORK5CYII=";

  string constant NOSE_NOSE___WIDE_BLUE_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFQFbNOk65////QZQLLAAAAAN0Uk5T//8A18oNQQAAADxJREFUeNrs0bEJACAQA8Do/kMrLmARsJALqY9/klkmAAAA8AbISQOM7DYvXA8wIwAAAAAAAADgV2AJMADLYx/j6hglmQAAAABJRU5ErkJggg==";

  string constant NOSE_NOSE___WIDE_PINK_SNIFFER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6Jr/yqLV////hVu2pwAAAAN0Uk5T//8A18oNQQAAADxJREFUeNrs0bEJACAQA8Do/kMrLmARsJALqY9/klkmAAAA8AbISQOM7DYvXA8wIwAAAAAAAADgV2AJMADLYx/j6hglmQAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return NOSE_NOSE___BLACK_NOSTRILS_SNIFFER;
    } else if (assetNum == 1) {
      return NOSE_NOSE___BLACK_SNIFFER;
    } else if (assetNum == 2) {
      return NOSE_NOSE___BLUE_NOSTRILS_SNIFFER;
    } else if (assetNum == 3) {
      return NOSE_NOSE___PINK_NOSTRILS_SNIFFER;
    } else if (assetNum == 4) {
      return NOSE_NOSE___RUNNY_BLACK_NOSE;
    } else if (assetNum == 5) {
      return NOSE_NOSE___SMALL_BLUE_SNIFFER;
    } else if (assetNum == 6) {
      return NOSE_NOSE___SMALL_PINK_NOSE;
    } else if (assetNum == 7) {
      return NOSE_NOSE___WIDE_BLACK_SNIFFER;
    } else if (assetNum == 8) {
      return NOSE_NOSE___WIDE_BLUE_SNIFFER;
    } else if (assetNum == 9) {
      return NOSE_NOSE___WIDE_PINK_SNIFFER;
    }
    return NOSE_NOSE___BLACK_NOSTRILS_SNIFFER;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Mouth {
  using Strings for uint256;
  string constant MOUTH_MOUTH___ANXIOUS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAP0lEQVR42uzRMQoAMAgEsPP/n+7QxaW02DUHTkJUTH0mAAAAAHgCdi/JeIO0mp1wme6NAAAAAAAAAIBTlgADAK4vD/cR1jg5AAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___BABY_TOOTH_SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAADpJREFUeNrs0TEKADAIBMEz/390wD5gsJ1tlQExZ1kAAAAAMAMy33lNu+UJ5Y0AAAAAAAAAgP+uAAMAa4of8AL3yZMAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___BLUE_LIPSTICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/S2Le////rt5oUQAAAAN0Uk5T//8A18oNQQAAADtJREFUeNrs0cEJACEQBMH28g9aAxBO2G91AMXA9A0LAAAAAM9AjYDWqcmC+pvgRgAAAAAAAADArS3AAE2zH+2klLMNAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___FULL_MOUTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFNTU1AAAA////0A2dowAAAAN0Uk5T//8A18oNQQAAAEBJREFUeNrs0iEOACAMA8DC/x8NjpBgBpKrmWhzaumPCQAAAPwBJPutAqmuTlWbuQZWF38AAAAAAAAAAChmCDAAHnkf6fOp8jgAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___MISSING_BOTTOM_TOOTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAADhJREFUeNrs0cEJACAQA8HE/ov2YwN64Gu2gCGQrGEBAAAAwCcgp/cFadN4AQAAAAAAAABw3RZgABpJH+jnE47kAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___NERVOUS_MOUTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRsQkAIAADwXf/pQVxARWs7iHtNWk8FgAAAAA+AdXaPbAJLwAAAAAAAAAATpsCDACa4Q/1sglxFAAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___OPEN_MOUTH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzRsQkAMAwDQWX/pQOuDSkEqe57HwLnlAUAAAAAv4BMzYLnvS8AAAAAAAAAANauAAMAr3QP90EGRPYAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___PINK_LIPSTICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF4GDl////yw5CGAAAAAJ0Uk5T/wDltzBKAAAAOUlEQVR42uzRsQkAMAwDQXn/pQOpAw6ove99CJwpCwAAAAC+gaQCcmsWrPfeCAAAAAAAAAB4dgQYAJnfD/XVqKI6AAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___RED_LIPSTICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZ3ktT////91YocAAAAAN0Uk5T//8A18oNQQAAADtJREFUeNrs0cEJACEQBMH28g9aAxBO2G91AMXA9A0LAAAAAM9AjYDWqcmC+pvgRgAAAAAAAADArS3AAE2zH+2klLMNAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___SAD_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzRsQkAMAwDQXn/pQPp0pkYXN3X4hqlhgUAAAAAW0Bu/0D6Gy8AAAAAAAAAAJ6OAAMAxAUP+bDZ4t4AAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___SMILE_WITH_BUCK_TEETH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAADpJREFUeNrs0TEKADAIBMEz/390IH1AtJ1tlQExZ1kAAAAA0APS3/lNX6sTqrwRAAAAAAAAADDoCjAAYUAf7yk/D1EAAAAASUVORK5CYII=";

  string constant MOUTH_MOUTH___SMILE_WITH_PIPE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFzs7OiW8+AAAA////Igr54gAAAAR0Uk5T////AEAqqfQAAABYSURBVHja7NNLCsAgEATRGr3/nYMLdxpCGiKB6o2recwH6WEQEPgfABlABrBs4DkA4Q44fQXCDsiBbIR9/T3Q5lP1coltpEb8zgICAgICAgICAt8ClwADAGw7L7BSiUgtAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRMQoAMAgDwPj/TwvdC4LgdFkTbklqmQAAAABgBmS++bUvXgAAAAAAAAAA3AMtwADDAQ/5B23EaQAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___SMIRK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAPElEQVR42uzRwQkAIAADsXP/pcUNREEQ0nebTxuXCQAAAP4C6hBoo9bGvgugFTcCAAAAAAAAAN4DU4ABAIuXD/QMyW3bAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___TINY_FROWN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRsQkAMAwDQWX/peMBDCkEqe5rcY1yygIAAACAj0CmDnhsvAAAAAAAAAAA2LoCDADZJA/7BAcUuAAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___TINY_SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAN0lEQVR42uzRsQ0AMAgDQbP/0skEERES1X1rdA2pYQEAAADAGpDOxXO++QIAAAAAAAAA4L8jwADZmg/7DSgAAAAAAABJRU5ErkJggg==";

  string constant MOUTH_MOUTH___TONGUE_OUT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA4GDl////7QoSFwAAAAN0Uk5T//8A18oNQQAAADhJREFUeNrs0YEJACAMA8G0+w8tzlCwCPcDHIGkhwUAAAAAz4DcZguqehlwIwAAAAAAAMCPwBFgAI13H/PplSVCAAAAAElFTkSuQmCC";

  string constant MOUTH_MOUTH___TOOTHY_SMILE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA////////c3ilYwAAAAN0Uk5T//8A18oNQQAAAD1JREFUeNrs0TEKADAIA8C0/390oUO3guJ6GVwMB2L2MAEAAABADUi989veDE5Yb3gjAAAAAAAAAKCVI8AAYUAf76VMPZsAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return MOUTH_MOUTH___ANXIOUS;
    } else if (assetNum == 1) {
      return MOUTH_MOUTH___BABY_TOOTH_SMILE;
    } else if (assetNum == 2) {
      return MOUTH_MOUTH___BLUE_LIPSTICK;
    } else if (assetNum == 3) {
      return MOUTH_MOUTH___FULL_MOUTH;
    } else if (assetNum == 4) {
      return MOUTH_MOUTH___MISSING_BOTTOM_TOOTH;
    } else if (assetNum == 5) {
      return MOUTH_MOUTH___NERVOUS_MOUTH;
    } else if (assetNum == 6) {
      return MOUTH_MOUTH___OPEN_MOUTH;
    } else if (assetNum == 7) {
      return MOUTH_MOUTH___PINK_LIPSTICK;
    } else if (assetNum == 8) {
      return MOUTH_MOUTH___RED_LIPSTICK;
    } else if (assetNum == 9) {
      return MOUTH_MOUTH___SAD_FROWN;
    } else if (assetNum == 10) {
      return MOUTH_MOUTH___SMILE_WITH_BUCK_TEETH;
    } else if (assetNum == 11) {
      return MOUTH_MOUTH___SMILE_WITH_PIPE;
    } else if (assetNum == 12) {
      return MOUTH_MOUTH___SMILE;
    } else if (assetNum == 13) {
      return MOUTH_MOUTH___SMIRK;
    } else if (assetNum == 14) {
      return MOUTH_MOUTH___TINY_FROWN;
    } else if (assetNum == 15) {
      return MOUTH_MOUTH___TINY_SMILE;
    } else if (assetNum == 16) {
      return MOUTH_MOUTH___TONGUE_OUT;
    } else if (assetNum == 17) {
      return MOUTH_MOUTH___TOOTHY_SMILE;
    }
    return MOUTH_MOUTH___ANXIOUS;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Jewelry {
  using Strings for uint256;
  string constant JEWELRY_JEWELRY___BLUE_BRACELET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/5eXl////qSQL7QAAAAN0Uk5T//8A18oNQQAAAEJJREFUeNrs0rENACAMxEA/+w+NFLEAgQrsMsUVrzAOQ0BAQEBAQEDgfYBd+TqQdSDdDUKV/oipfCQBAQGBP4EpwABFQB/f2QegEQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___BLUE_SPORTS_WATCH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFOk65AAAA5eXlS2Le////5FMLwAAAAAV0Uk5T/////wD7tg5TAAAAR0lEQVR42uzSsQ0AIAwDQdth/5mBBSiSguZ/gJNiRWuYAAAAAAAAAAB+A54AOvUB26qaA2kDSe4JoxGPER4JAAAAAODZFmAArBE/opL70I0AAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF97Z08dGH159l////5eXl6sU3////nCw5OwAAAAd0Uk5T////////ABpLA0YAAACGSURBVHja7NTBCsAwCANQq3b//8kT28MusyWFwSBhlx3ykE2U6zBCgAABAgQIbAH99eU3gD9K3ZGP2HcGqIAYoWWqAcrf6E0yzcE9mP0QMGD0zawUVoAdAtGOR1HAMqowILOPAzr6IOAtqmMAeJFUV/36oPhYZccvkmd4lQkQIEDgK+AWYAAcfV2fh6w3wAAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___DOUBLE_GOLD_CHAINS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6sU35eXl////NFtlvAAAAAN0Uk5T//8A18oNQQAAAF9JREFUeNrs08EKACEIRdH3/P+PLiIKhkHKWc51JSQHzVJ8DAEAAAAAABwBKpQ9TvSSXgCW52FPXLkDdWOE86qkhfCISBpIt7BHqK5xjVB+B3ME/gIAAAAAAMCvgCbAAFrpH7EtfnnrAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___DOUBLE_SILVER_CHAINS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7O5eXl////R8rVTwAAAAN0Uk5T//8A18oNQQAAAF9JREFUeNrs08EKACEIRdH3/P+PLiIKhkHKWc51JSQHzVJ8DAEAAAAAABwBKpQ9TvSSXgCW52FPXLkDdWOE86qkhfCISBpIt7BHqK5xjVB+B3ME/gIAAAAAAMCvgCbAAFrpH7EtfnnrAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN_WITH_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6sU35eXl////NFtlvAAAAAN0Uk5T//8A18oNQQAAAGxJREFUeNrs1EEOgCAMRNEZ7n9oJcbEjVMBjZvfLcxLQxvUFksAAAAAAACPAE1cexfw5UieeQON3rpvITQQp3AKKZ/HeAgxX+xBF3K+WiSryFeA9loBpFL4GHDP//uIzeZLAwAAAAAYqE2AAQAhyB+fAJ91QQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN_WITH_RED_RUBY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6sU35eXlnjMz3ZGRhSgo////gYUuFQAAAAZ0Uk5T//////8As7+kvwAAAHJJREFUeNrs1MEOgDAIA9AW2P//shpj4kVww8RLdx19IbAMo3kgQIAAAQIEvAKwUPYtwNsVuDIDzFY9t5A0kG7hErJ8vsZTSPPFOziEPF89JKLIVwDc0QHgZoYOsOejAxARPw9xkPrSBAgQIEDAxNkEGADT6U8SwyRYtgAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___GOLD_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF6sU35eXl////NFtlvAAAAAN0Uk5T//8A18oNQQAAAFNJREFUeNrs00EKACAIRNGZ7n/oQAjaJGXt+rPNHpKmdhkBAAAAAABsASqUvQU8HcmVN9Bp1bqFpIF0CkPI7udjtCKu74Ej/AUAAAAAAIC/gC7AAGtpH89tNxW/AAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___GOLD_STUD_EARRINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAMklEQVR42uzQoREAAAwCMbr/0jXdAFOR11wEmbIAAJ+BNEsnAgAAAAAAAAAAAMC1AgwA/SYP/+cPiukAAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___GOLD_WATCH_ON_LEFT_WRIST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6sU32btH5eXlAAAA////M7UYqgAAAAV0Uk5T/////wD7tg5TAAAASElEQVR42uzSsREAMAhCUcTsP3PMAimk/di/O1SdMAIAAAAAAAAACIFOgeoA0GQPlGYqB7zege1XIbrCGOYTAQAAAAC+uQIMAErLP5ROwBakAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___LEFT_HAND_GOLD_RINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAAM0lEQVR42uzRwQkAMAwDscv+S2eIUvKRBxCGax4XAAAAAAAAAAAwdfigVAAAAIDfwAowAAE2D/3g10aZAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___LEFT_HAND_SILVER_RINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFzs7O////TowvlgAAAAJ0Uk5T/wDltzBKAAAAM0lEQVR42uzRwQkAMAwDscv+S2eIUvKRBxCGax4XAAAAAAAAAAAwdfigVAAAAIDfwAowAAE2D/3g10aZAAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___RED_BRACELET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZ5eXl////buXvrwAAAAN0Uk5T//8A18oNQQAAAEJJREFUeNrs0rENACAMxEA/+w+NFLEAgQrsMsUVrzAOQ0BAQEBAQEDgfYBd+TqQdSDdDUKV/oipfCQBAQGBP4EpwABFQB/f2QegEQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___RED_SPORTS_WATCH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFuTpBAAAA5eXl3ktT////lr6DwQAAAAV0Uk5T/////wD7tg5TAAAAR0lEQVR42uzSsQ0AIAwDQdth/5mBBSiSguZ/gJNiRWuYAAAAAAAAAAB+A54AOvUB26qaA2kDSe4JoxGPER4JAAAAAODZFmAArBE/opL70I0AAAAASUVORK5CYII=";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN_WITH_MEDALLION =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7O5eXl////R8rVTwAAAAN0Uk5T//8A18oNQQAAAGxJREFUeNrs1EEOgCAMRNEZ7n9oJcbEjVMBjZvfLcxLQxvUFksAAAAAAACPAE1cexfw5UieeQON3rpvITQQp3AKKZ/HeAgxX+xBF3K+WiSryFeA9loBpFL4GHDP//uIzeZLAwAAAAAYqE2AAQAhyB+fAJ91QQAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN_WITH_RED_RUBY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFzs7O5eXlnjMz3ZGRhSgo////PAEFCgAAAAZ0Uk5T//////8As7+kvwAAAHJJREFUeNrs1MEOgDAIA9AW2P//shpj4kVww8RLdx19IbAMo3kgQIAAAQIEvAKwUPYtwNsVuDIDzFY9t5A0kG7hErJ8vsZTSPPFOziEPF89JKLIVwDc0QHgZoYOsOejAxARPw9xkPrSBAgQIEDAxNkEGADT6U8SwyRYtgAAAABJRU5ErkJggg==";

  string constant JEWELRY_JEWELRY___SILVER_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7O5eXl////R8rVTwAAAAN0Uk5T//8A18oNQQAAAFNJREFUeNrs00EKACAIRNGZ7n/oQAjaJGXt+rPNHpKmdhkBAAAAAABsASqUvQU8HcmVN9Bp1bqFpIF0CkPI7udjtCKu74Ej/AUAAAAAAIC/gC7AAGtpH89tNxW/AAAAAElFTkSuQmCC";

  string constant JEWELRY_JEWELRY___SILVER_STUD_EARRINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFzs7O////TowvlgAAAAJ0Uk5T/wDltzBKAAAAMklEQVR42uzQoREAAAwCMbr/0jXdAFOR11wEmbIAAJ+BNEsnAgAAAAAAAAAAAMC1AgwA/SYP/+cPiukAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return JEWELRY_JEWELRY___BLUE_BRACELET;
    } else if (assetNum == 1) {
      return JEWELRY_JEWELRY___BLUE_SPORTS_WATCH;
    } else if (assetNum == 2) {
      return
        JEWELRY_JEWELRY___DECENTRALIZED_ETHEREUM_STAKING_PROTOCOL_MEDALLION;
    } else if (assetNum == 3) {
      return JEWELRY_JEWELRY___DOUBLE_GOLD_CHAINS;
    } else if (assetNum == 4) {
      return JEWELRY_JEWELRY___DOUBLE_SILVER_CHAINS;
    } else if (assetNum == 5) {
      return JEWELRY_JEWELRY___GOLD_CHAIN_WITH_MEDALLION;
    } else if (assetNum == 6) {
      return JEWELRY_JEWELRY___GOLD_CHAIN_WITH_RED_RUBY;
    } else if (assetNum == 7) {
      return JEWELRY_JEWELRY___GOLD_CHAIN;
    } else if (assetNum == 8) {
      return JEWELRY_JEWELRY___GOLD_STUD_EARRINGS;
    } else if (assetNum == 9) {
      return JEWELRY_JEWELRY___GOLD_WATCH_ON_LEFT_WRIST;
    } else if (assetNum == 10) {
      return JEWELRY_JEWELRY___LEFT_HAND_GOLD_RINGS;
    } else if (assetNum == 11) {
      return JEWELRY_JEWELRY___LEFT_HAND_SILVER_RINGS;
    } else if (assetNum == 12) {
      return JEWELRY_JEWELRY___RED_BRACELET;
    } else if (assetNum == 13) {
      return JEWELRY_JEWELRY___RED_SPORTS_WATCH;
    } else if (assetNum == 14) {
      return JEWELRY_JEWELRY___SILVER_CHAIN_WITH_MEDALLION;
    } else if (assetNum == 15) {
      return JEWELRY_JEWELRY___SILVER_CHAIN_WITH_RED_RUBY;
    } else if (assetNum == 16) {
      return JEWELRY_JEWELRY___SILVER_CHAIN;
    } else if (assetNum == 17) {
      return JEWELRY_JEWELRY___SILVER_STUD_EARRINGS;
    }
    return JEWELRY_JEWELRY___BLUE_BRACELET;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Head {
  using Strings for uint256;
  string constant HEAD_HEAD___ALASKAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFNTU1AAAAMjIyLS0t8vLyAAAAAAAAAAAAtxDBtwAAAAZ0Uk5T//////8As7+kvwAAAIhJREFUeNrs1EsKgDAMBNDQocz9b6zEKn6wmhZEZbJoyWIeJYVY7iwT8GKAZKW9Bmhm9JxHSxsEjH7OdxCA7QoMzgD38ufA/gVPA4d8dAY/AIqQvNq/MaVFiAPYAAgDLqwA5i4ADcAooAio5GsbiSMxFdm40sh5o2itCxAgQIAAAQIEfAsYBBgA7DJMPObFMC4AAAAASUVORK5CYII=";

  string constant HEAD_HEAD___ALASKAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6+vrAAAANTU139/fLS0t////1ThdQQAAAAZ0Uk5T//////8As7+kvwAAAKdJREFUeNrs1NsKw0AIBFBnTf7/l2NEm0sx1IRCCzMPIfvgYS+izA8jBH4YgKVafQJgWOCFVhqrNjAgnli0AdmlD0xWv24/v2NC8xJj50CcpXuJefJILXwJgLwDih4Qbwfki94B4I3gxC0A2QXrv7YAF7D1EcoNlIDKMardRjoJivkRoG3ABN2Vl/UXEwlGZMpxcj3S8ArHOgECBAgQIECAwJ8BiwADAObUSq790lmUAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___ALASKAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF6+vrAAAA39/f09PTAAAAAAAAAAAAAAAAQ0p3MgAAAAV0Uk5T/////wD7tg5TAAAAiElEQVR42uzUSwqAMAwE0NApzP1vrMQqfrCaFkRlsmjJYh4lhVjuLBPwYoBkpb0GaGb0nEdLGwSMfs53EIDtCgzOAPfy58D+BU8Dh3x0Bj8AipC82r8xpUWIA9gACAMurADmLgANwCigCKjkaxuJIzEV2bjSyHmjaK0LECBAgAABAgR8CxgEGADgdT14PqqFJgAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF/+2o+dZOAAAA//jb5dWX2sNE////eqq0CwAAAAd0Uk5T////////ABpLA0YAAADASURBVHja7JThDoMgDITba/H9H1laUMMS0G7JsiW9HxZJ7qtScrR9KErA7wIA3GysARBhc8BlVUTwHADhKnEbEVn19+cA8zO52yTkGwFAMT/5o9r7uiBwBoXdyFeZ+KdT6MbW2yu27wKa/QIwBe/B2fj8BMUbgDbF5T9MAOpHcNyDhooC7P4Mio1RaQBIeAo6NBeKAl4JsxksAgWqJ6MuEU+kGgTaNU2Tu0gDjkTJWE9AAhKQgAQkIAEJ+C/ALsAAye1ZNeftIgsAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAMjIyLS0t////rVsosQAAAAV0Uk5T/////wD7tg5TAAAAlUlEQVR42uzUUQqEMAwE0EzH+59ZV+ua0m0wCuLC5EsK8yCpjU03ywS8FgBw4mgMwMywhdZyR+cBW4JWq34mANK6IpGZQScwM4O9iyafu0b0LeBR4Ed+1MTLgVIr+A3CIZbiBF64BQ8wCbRCkB8DPIRPPg34B8UgH2yk5UF9C7i00gC3UbTWBQgQIECAAAEC/gmYBRgAiy87enMCjCoAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6+vrAAAANTU139/fLS0t////1ThdQQAAAAZ0Uk5T//////8As7+kvwAAALJJREFUeNrs1OsKwyAMBeAcY9//lZfEC6PF1sNgbJD8sUjPV6sSOT4sSeB3AQAPE/cASimeQJSPPrEP+OsuQKKAPkEC8lYsUFs+1tAWYhMVxB7U4kn7qA3+MyZUUKcQwQG08fgy0Dde5gN3D1pubGIACg6QeQ36Iw2ciwP0mlfuGHVzAduAksBZWObXDQWqOtPr/E1HsrPTXstu8tTSgNFRsq0nkEACCSSQQAIJ/BfwEmAACepKTP4xsMkAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___HIMALAYAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAA39/f09PT////sy0tfgAAAAV0Uk5T/////wD7tg5TAAAAlUlEQVR42uzUUQqEMAwE0EzH+59ZV+ua0m0wCuLC5EsK8yCpjU03ywS8FgBw4mgMwMywhdZyR+cBW4JWq34mANK6IpGZQScwM4O9iyafu0b0LeBR4Ed+1MTLgVIr+A3CIZbiBF64BQ8wCbRCkB8DPIRPPg34B8UgH2yk5UF9C7i00gC3UbTWBQgQIECAAAEC/gmYBRgAiy87enMCjCoAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAMjIyLS0t////rVsosQAAAAV0Uk5T/////wD7tg5TAAAAkUlEQVR42uzU0QqAIAwF0Dvn/39zZmUqKc4gDO59ER92UGuDfxkQWBiQkNZuBBABQo3EXDsTAOw1wL0aAUUVNQK1oMYreBk8QPcNysinwEN96xKrAy7mqDcBp+DcLejMV8gA1ZkfKQfE2s5avIGagSBk3dCu70yk0E8pzXHSH2mSwrFOgAABAgQIECDwM2ATYAAAhzt+t498NwAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6+vrAAAANTU139/fLS0t////1ThdQQAAAAZ0Uk5T//////8As7+kvwAAAKNJREFUeNrs1MEOwyAMA9A4Yf//y2PJqESldjXdYZOcC3DwEyIo9rhZJuCHAQAnx88A3B2Zy+j7SAIOWBbqxAHNbarWQL5B2Ov2dYG+BthHtLq3jZUGMrcBvtKFCVjqwheAesTcNrqN8z/g24gRH52k2zgX/w9iztPATjjMXwRiAehCbPHj/NlEQieqgMWRBoyJorEuQIAAAQIECBDwX8BTgAEA4sVLMdWBDS4AAAAASUVORK5CYII=";

  string constant HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAA39/f09PT////sy0tfgAAAAV0Uk5T/////wD7tg5TAAAAkUlEQVR42uzU0QqAIAwF0Dvn/39zZmUqKc4gDO59ER92UGuDfxkQWBiQkNZuBBABQo3EXDsTAOw1wL0aAUUVNQK1oMYreBk8QPcNysinwEN96xKrAy7mqDcBp+DcLejMV8gA1ZkfKQfE2s5avIGagSBk3dCu70yk0E8pzXHSH2mSwrFOgAABAgQIECDwM2ATYAAAhzt+t498NwAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___REVERSE_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU16+vrAAAALS0t39/f////w0HIeQAAAAZ0Uk5T//////8As7+kvwAAAK5JREFUeNrs1NEOwyAIBVDuxf3/L49ZNbSLjdiXLYEXW9N7kopBXg9LEvhZgOTC1hwgAB6hWm5rHYAFpZU9IgaUYt+LK3sthZEzKKipFhaxOENdYA0CfVHG2tjzGOtMWAYkBIw83ANDAK4A9oDWhU8pN35hXIL5Kd4eortG4S6onEuDwJcQvUhXQMOACeri0/zNRKIRvcitkUa6iZJjPYEEEkgggQQSSOCfgLcAAwCFo0qCYOUzAAAAAABJRU5ErkJggg==";

  string constant HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAMjIyLS0t////rVsosQAAAAV0Uk5T/////wD7tg5TAAAAk0lEQVR42uzU4QqAIAwE4J3X+z9zKQYlOZ39Kbj9MaR9oJOz7WWZgO8CAAYbPgAzyx0olde8MQ/k3wvRrFGgrQDAp34icAec7e9OYfIA3wUwPQQfSLVWgZSuAl8CXBjjHQhOgc0dMAjcBK+/Hyggz/d8fHX7nUQ6goC1umkyijTgTBTFugABAgQIECBAwL+AXYABAN5nO1o/F1OGAAAAAElFTkSuQmCC";

  string constant HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU1AAAA6+vr09PTLS0t////LI6PZwAAAAZ0Uk5T//////8As7+kvwAAAKxJREFUeNrs1EsOwyAMBFBPcO9/5RoCqVMJlGk2qTTe8FHmEWEJe90sE/BYAMCFrTkAM8MeapW2rgMWwa1XTI0D3OP7LVUs3cHcgXs7uJ8fgjN3UIkI1r/+DFwbe9DySAItdwAxoYCUS5NfAMMYaWAIR54GslDXBWQXvoDCduEmcBYW+TlQTkChgRDKABzz/OJFqilvtcqvnjSk0rMuQIAAAQIECBDwX8BbgAEAgw5KgqceTiQAAAAASUVORK5CYII=";

  string constant HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAA39/f09PT////sy0tfgAAAAV0Uk5T/////wD7tg5TAAAAk0lEQVR42uzU4QqAIAwE4J3X+z9zKQYlOZ39Kbj9MaR9oJOz7WWZgO8CAAYbPgAzyx0olde8MQ/k3wvRrFGgrQDAp34icAec7e9OYfIA3wUwPQQfSLVWgZSuAl8CXBjjHQhOgc0dMAjcBK+/Hyggz/d8fHX7nUQ6goC1umkyijTgTBTFugABAgQIECBAwL+AXYABAN5nO1o/F1OGAAAAAElFTkSuQmCC";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return HEAD_HEAD___ALASKAN_BLACK_BEAR;
    } else if (assetNum == 1) {
      return HEAD_HEAD___ALASKAN_PANDA_BEAR;
    } else if (assetNum == 2) {
      return HEAD_HEAD___ALASKAN_POLAR_BEAR;
    } else if (assetNum == 3) {
      return HEAD_HEAD___GOLD_PANDA;
    } else if (assetNum == 4) {
      return HEAD_HEAD___HIMALAYAN_BLACK_BEAR;
    } else if (assetNum == 5) {
      return HEAD_HEAD___HIMALAYAN_PANDA_BEAR;
    } else if (assetNum == 6) {
      return HEAD_HEAD___HIMALAYAN_POLAR_BEAR;
    } else if (assetNum == 7) {
      return HEAD_HEAD___NEW_ENGLAND_BLACK_BEAR;
    } else if (assetNum == 8) {
      return HEAD_HEAD___NEW_ENGLAND_PANDA_BEAR;
    } else if (assetNum == 9) {
      return HEAD_HEAD___NEW_ENGLAND_POLAR_BEAR;
    } else if (assetNum == 10) {
      return HEAD_HEAD___REVERSE_PANDA_BEAR;
    } else if (assetNum == 11) {
      return HEAD_HEAD___SASKATCHEWAN_BLACK_BEAR;
    } else if (assetNum == 12) {
      return HEAD_HEAD___SASKATCHEWAN_PANDA_BEAR;
    } else if (assetNum == 13) {
      return HEAD_HEAD___SASKATCHEWAN_POLAR_BEAR;
    }
    return HEAD_HEAD___ALASKAN_BLACK_BEAR;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Hat {
  using Strings for uint256;
  string constant HAT_HAT___ASTRONAUT_HELMET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFQFbNs7vrAAAAS2LeOk65UGv/6Ov5////kv0KBAAAAAh0Uk5T/////////wDeg71ZAAAA00lEQVR42uzV2w7CIAyA4bYDfP83lnKYBS3SmV2YtJfG/7ObGYPHjwO3AtTmIkB0tFkR8D2HPDqhAZzHGGteCBtAnMMwZAE+9JoAy77+CUtBAUpPhJgQsRPbAC/A38faM6ELoC4g+i4YgKlvwj5wVOBFJDMw9XUFMyB6IzDegoTXgKFnIFg3kL0ZEMLZbwPTCssFdGC8CHUB7XEGISx79UCRwqrXjzQK/Tigcv3WIy0/j6EN8O8bj7T8+duY3wtb+d2vNgcccMABBxxwwIH/BJ4CDADNMmO1DGqiPwAAAABJRU5ErkJggg==";

  string constant HAT_HAT___BAG_OF_ETHEREUM =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFspJTAAAAjH9/f3JyMiMV////vWa9KwAAAAZ0Uk5T//////8As7+kvwAAAGJJREFUeNrs0EkOgDAMQ9EM7f2vTAv7GuEd+tlGfnISU0zmeR8qH5EOsPJCUMAY6TTQBc7AnTdO2PlSggCqygO62gDmatC7wfwOPD9wgLCANwMAAAAAAAAAAAAAAPBj4BJgAB87Towu1B9ZAAAAAElFTkSuQmCC";

  string constant HAT_HAT___BLACK_BOWLER_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAPElEQVR42uzSsQkAIBAEwfv+mxaMPhOUD4TZAiba1GMBTAPZ3QPJWZgE0vIBAAAAAAAAAAAAAPwJLAEGADaZD98VtpqsAAAAAElFTkSuQmCC";

  string constant HAT_HAT___BLACK_TOP_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAOElEQVR42uzSsQkAMAwEsff+S6dJkd4EY9ANoOpSzfIVyA2wGMjT1EgAAAAAAAAAAAAAAOh1BBgAMcgPvRKkebAAAAAASUVORK5CYII=";

  string constant HAT_HAT___BLACK_AND_WHITE_STRIPED_JAIL_CAP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAA////zs7O////IzDhUgAAAAR0Uk5T////AEAqqfQAAABkSURBVHja7NJBDoAwCETRgd7/ziqa6MY2GRYu/JN0RfqgDRrNaF6t2IAUlSmhVfvVEO8l5X0/5QCRcSVNYO9csSc4PvE83wDjCbiLVO/Pxia2VxkAAAAAAAAAAAAAAODfwCbAABLfLurW3p3aAAAAAElFTkSuQmCC";

  string constant HAT_HAT___BLACK_WITH_BLUE_HEADPHONES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAUGv/////v7SHiAAAAAN0Uk5T//8A18oNQQAAAFVJREFUeNrs0zEKwCAQBdHR+x86nSCYZY2NxvmlMK9YkLo4tgZo+wTQbR7ookAg00cCqT4QyPXvwvCVMgIKNwHLR/zPbxQQEBAQEBAQEBAQOBp4BBgAApMfXVc0ju8AAAAASUVORK5CYII=";

  string constant HAT_HAT___BLACK_WITH_BLUE_TOP_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAAUGv/S2Le////GFS2BwAAAAR0Uk5T////AEAqqfQAAAA9SURBVHja7NKhEQAgEASx5+i/ZxAI/A+DyRYQtTWb1VOgToAGkGTs8guoq18jAQAAAAAAAAAAAACg1xJgAMovL02Jgj8HAAAAAElFTkSuQmCC";

  string constant HAT_HAT___BLUE_BASEBALL_CAP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFSGz/AAAAOlfV////hul92gAAAAR0Uk5T////AEAqqfQAAABWSURBVHja7NNBDgAQDETRDve/sxhrKrWTXyI289I0RH+s+B2Qqw4o2lyqAjPvrRrgfCpElvd5EHJgtbAd5iXgix7eQaUD/gIAAAAAAAAAAAAAAMAQYABuYy8sFMG46QAAAABJRU5ErkJggg==";

  string constant HAT_HAT___BLUE_UMBRELLA_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NPRCsAgCAXQq/3/P09TNgYzZL1scH3IIu6BojA2C98GNOsdYEERgQBYGSjjgHjYERtKAou4572FUxCPgJ65mKSkXUCvVAJpaQ+45ROoBTzmdVhkbtvCuwHzYNoB4rpyAxJd4mq1dYTFy/rdXyBAgAABAgQIECBAgACBnToEGABRVi6KAJCJVwAAAABJRU5ErkJggg==";

  string constant HAT_HAT___BULB_HELMET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFq6KZfW1tAAAA9vOZW2mA//7gLzYz////cFdYaAAAAAh0Uk5T/////////wDeg71ZAAAAk0lEQVR42uzUzQqAIBAE4G0ye/83biejH1AxPXRo5tCC4Ye6oq2DsfpveEYALB70A1hmBj8GgLin2ogaYGe6AHvkPWDWJlh+8wQmD6emmkbbAN6/6PNC4MyjxsKdzABg6xwIHgKpxkJDsysoAWg+A37S0q96DL+4Bzy8e+16D4YfFAECBAgQIECAAAECBHwGbAIMAJDFa9/XI/3JAAAAAElFTkSuQmCC";

  string constant HAT_HAT___CHERRY_ON_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFgCEgAAAAbpZw1VdW////VaIaLQAAAAV0Uk5T/////wD7tg5TAAAAUUlEQVR42uzSsQ2AUAwDUV9g/5nZgHzJSDSXOnlO4dzlZN2ADmCGBmC6D3iPXwEyoQDIlYQGyBdA1YP1/qBIAgICAgICAgICAgICAv8BjwADAHRiP3omvhMlAAAAAElFTkSuQmCC";

  string constant HAT_HAT___CRYPTO_INFLUENCER_BLUEBIRD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFW6zhAAAAUaHW6sU3////ODu4hwAAAAV0Uk5T/////wD7tg5TAAAAWklEQVR42uzSQQ7AIAhE0Rno/c9calzbBNJ08//eF0V0DdOngD0DLHkCOK1wH3CmClg1b1BP2Lk9g1W4/QvxHD/P4WUPovpzkQAAAAAAAAAAAAAAAABm3QIMAMaXP0tNIpWYAAAAAElFTkSuQmCC";

  string constant HAT_HAT___GIANT_SUNFLOWER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6sU3AAAA07M2a1cx////BrLbjgAAAAV0Uk5T/////wD7tg5TAAABQElEQVR42uyW3RaEIAiEYfT9n3n9Qa0OINvupV500povZIii7A4uw7+DfD0Rgb8GzMdW/SQYwZD+WOInYK3uAF3V7mXCANyC2QIghKWSxRgAJDFILEW2zkI5aIRyWDJbr7sgMUCOcPR6HdwJffdWQeiF1AlpDrILyqjESkhJJo1gFaRRiUUw9Q1RcxqrRBbPrvpKEGd5B+CRtnRfTyOj7AOG4wpg+MEegJd3KkCJgfQAoAEQAADuFioF7OZgIp4uYMh5ayP6SI8A2uLeRuldjxBaGeg9jaxeeiW0UlYbmg3AhSBlGAfM/jFeRpBNIEdPyzqbYDZVIE8OckVAJVhtHe0irXMYIRgA9It9G32CMABDIiGMCaJtvWw4a4DLevjrLCl8/3kXO94Dcn2BfvnBCIwDOIADOIADOIAD+DPgI8AAbcQ3unsV8Z4AAAAASUVORK5CYII=";

  string constant HAT_HAT___GOLD_CHALICE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFAAAA0bA73sdfq5Qzj0Eq////NS+KlAAAAAZ0Uk5T//////8As7+kvwAAAGBJREFUeNrs0UEOwCAIRFGmyP2vXFr3kEi66h+WmoegRRXbKa+Uh1dGcjsHlrLOgRTUPOBr4BG86RGN4F2LDtAQCMUMyB2MgPcXZiPEcAQAAAAAAAAAAAAAAIA/A7cAAwALG08jVMTV2QAAAABJRU5ErkJggg==";

  string constant HAT_HAT___GRADUATION_CAP_WITH_BLUE_TASSEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAANTU1UGv/////Wu4LrwAAAAR0Uk5T////AEAqqfQAAABZSURBVHja7NLRCoBACAXRUf//n1s26DFCCQrmgk/iQVBqGN4GYASw0wa40gPgiXDTyukGWXGOR3UBYhGr+sAepw8Mz5jfeGUBAQEBAQEBAQEBAYEfA4cAAwBT9i8xSenp1QAAAABJRU5ErkJggg==";

  string constant HAT_HAT___GRADUATION_CAP_WITH_RED_TASSEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAANTU1/1BZ////DFVn2gAAAAR0Uk5T////AEAqqfQAAABZSURBVHja7NLRCoBACAXRUf//n1s26DFCCQrmgk/iQVBqGN4GYASw0wa40gPgiXDTyukGWXGOR3UBYhGr+sAepw8Mz5jfeGUBAQEBAQEBAQEBAYEfA4cAAwBT9i8xSenp1QAAAABJRU5ErkJggg==";

  string constant HAT_HAT___GREEN_GOO =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUf9aV9RdAAAA////8OJe4gAAAAR0Uk5T////AEAqqfQAAABZSURBVHja7NMxDsAwCATBA/7/54DdpwDFLrInWgYkhGIYAXwOeGYCuCTz8C6w+lOQ9YDqrso0N1DY3mFwhZqu0Rlfx58B4jbANwIAAAAAAAAAAAD8FngEGACpVi+IuGeNiwAAAABJRU5ErkJggg==";

  string constant HAT_HAT___NODE_OPERATORS_YELLOW_HARDHAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6sU32rg0AAAA6sU2////adQM4wAAAAV0Uk5T/////wD7tg5TAAAAZklEQVR42uzSQQoAIQxD0bZ6/zNPI4K7LjrIMPADXeYRRJsvY3eBWOkDYSvRBcJcfS+FEsi+65qABqheT6gWHGB+A+T7DQEjr7lgx739kVQu69e/MgAAAAAAAAAAAAAAwK+BR4ABAHTtPsbMRIz4AAAAAElFTkSuQmCC";

  string constant HAT_HAT___NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  string constant HAT_HAT___PINK_BUTTERFLY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFyqLVwkvlRUVF////T//+XQAAAAR0Uk5T////AEAqqfQAAABZSURBVHja7NMxCgAgDEPRtN7/zmpxF5pNv6BOPpqAGubS40Ce3QSk9Tr31QUilPtoR5Ai4zLApcQ1gVViTWAAqg6MCBXf64C/AAAAAAAAAAAAAADwNzAFGACPxy+cXbN/7gAAAABJRU5ErkJggg==";

  string constant HAT_HAT___PINK_SUNHAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6Jr/AAAAyqLV////Ci+i2QAAAAR0Uk5T////AEAqqfQAAABiSURBVHja7NNBCoAwDETRmXj/O7uwIBUTagsi8ie7Qh5DS7UtRt8G3DIJ2IpjKiIHHDrHz4FuvxByoNsPv9mgXf2lQfYeuulexMMNho/1878AAAAAAAAAAAAAAACwkl2AAQAHsi65WX3y4QAAAABJRU5ErkJggg==";

  string constant HAT_HAT___POLICE_CAP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFKjFYAAAA////////dNMazAAAAAR0Uk5T////AEAqqfQAAABUSURBVHja7NIxDgAgCENRqve/sxsyMdRBTX6ZeYnFmIeJpwFlPECRkQOU/U7ogLHHAWbZD6uD+gSvxGxBunPGJD7+ygAAAAAAAAAAAAAAAHeBJcAASGsvC6AT5bIAAAAASUVORK5CYII=";

  string constant HAT_HAT___RED_ASTRONAUT_HELMET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFzUBI67O2AAAA3ktTuTpB+ejp/1BZ////IcbzjgAAAAh0Uk5T/////////wDeg71ZAAAA00lEQVR42uzV2w7CIAyA4bYDfP83lnKYBS3SmV2YtJfG/7ObGYPHjwO3AtTmIkB0tFkR8D2HPDqhAZynlGpeCBtAnMMwZAE+9JoAy77+CUtBAUpPhBgRsRPbAC/A38faM6ELoC4g+i4YgKlvwj5wVOBFRDMw9XUFMyB6IzDegojXgKFnIFg3kL0ZEMLZbwPTCssFdGC8CHUB7XEGISx79UCRwqrXjzQK/Tigcv3WIy0/j6EN8O8bj7T8+duY3wtb+d2vNgcccMABBxxwwIH/BJ4CDADjCWO1fTN4AwAAAABJRU5ErkJggg==";

  string constant HAT_HAT___RED_BASEBALL_CAP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZAAAAzUBI////ldQ1tgAAAAR0Uk5T////AEAqqfQAAABcSURBVHja7NJBCsAgDETRjL3/ncVxbVPiQik/iriZRwiJZ7PickCuOqBo46gKjLyvaoDzqRBZ3u+LkAOzheUwPwL+aGMPKh38ZJUBAAAAAAAAAAAAAABOAl2AAQA4Ti8sNA+R7wAAAABJRU5ErkJggg==";

  string constant HAT_HAT___RED_DEFI_WIZARD_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZAAAAzUBI6sU3////FtBcqgAAAAV0Uk5T/////wD7tg5TAAAAaklEQVR42uzSMQ7AMAgDQAP5/5vrkJ1Wzlh7DhcsgXUZfHgTzAUQASRCBSIKBcgb8Pd5/gU48yUDXD9JTPMjwPlOqkDX3w2WDOwGRFSg+3ODlC8xT65P2YABAwYMGDBgwIABAwb+CjwCDACqJj7wsv4GLgAAAABJRU5ErkJggg==";

  string constant HAT_HAT___RED_SHOWER_CAP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZzUBI////gty5ygAAAAN0Uk5T//8A18oNQQAAAIBJREFUeNrs00sOgCAMBNCp9z8031ai1lCIcTOgiTHOQ1vBsTnwLQAIsArUcD7quQBYviNBICd0cRUkAoxvb1cyD5xpU8T7DAdoSR1vdfCBEuxTjUANyvK4zkgRW2TsifdHOW28PR5s49Nt/LKZCBAgQIAAAQIECBAgQGBjJAEGAIGBHsa3dBv/AAAAAElFTkSuQmCC";

  string constant HAT_HAT___RED_SPORTS_HELMET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAA/1BZ3ktTNTU1////BJreHQAAAAV0Uk5T/////wD7tg5TAAAAcUlEQVR42uzVQQ6AIBBD0c/A/c+sgsadizJGje16eAkJU2iT4eUAPTpA6UEF9vMl0ABKHUC9Eu4F9hvEBBAjEoAwlgqgzeUByIMG8oDn30HCLrSzDNHW+WiEkDtxzVYG3/5YDBgwYMCAAQMG/gksAgwAPmU+k3i4SEUAAAAASUVORK5CYII=";

  string constant HAT_HAT___RED_UMBRELLA_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZ3ktTAAAA////hP6nfQAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NPRCsAgCAXQq/3/P09TNgYzZL1scH3IIu6BojA2C98GNOsdYEERgQBYGSjjgHjYERtKAou4572FUxCPgJ65mKSkXUCvVAJpaQ+45ROoBTzmdVhkbtvCuwHzYNoB4rpyAxJd4mq1dYTFy/rdXyBAgAABAgQIECBAgACBnToEGABRVi6KAJCJVwAAAABJRU5ErkJggg==";

  string constant HAT_HAT___TAN_COWBOY_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFnIFNAAAAiW8+////s4CSSAAAAAR0Uk5T////AEAqqfQAAAB7SURBVHja7NNLCsAgDATQmfT+d64frNkYia4Kk01AmYemFc9lIdgj6VoeIAB+LQ/UIIytBcIGgFl3joFeJ4DPl3MwB5TB03zeuPoWCK4/48EgEJ/ebMRXArb3nxIzM6hbrsZa7le+fgsCBAgQIECAAAECBAgQ8HPgFWAAHsIuMYdXW0IAAAAASUVORK5CYII=";

  string constant HAT_HAT___TAN_SUNHAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFnIFNAAAAiW8+////s4CSSAAAAAR0Uk5T////AEAqqfQAAABiSURBVHja7NNBCoAwDETRmXj/O7uwIBUTagsi8ie7Qh5DS7UtRt8G3DIJ2IpjKiIHHDrHz4FuvxByoNsPv9mgXf2lQfYeuulexMMNho/1878AAAAAAAAAAAAAAACwkl2AAQAHsi65WX3y4QAAAABJRU5ErkJggg==";

  string constant HAT_HAT___TINY_BLUE_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAAUGv/S2Le////GFS2BwAAAAR0Uk5T////AEAqqfQAAABBSURBVHja7NLBCQAgEAPBnPbfs2IDgveT2QKGPJLZLIALkFMHqF0DSMbYQN6BqusEPwAAAAAAAAAAAACAr4ElwABPPi+9mXrDgwAAAABJRU5ErkJggg==";

  string constant HAT_HAT___TINY_RED_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZAAAA3ktT////4F6kDAAAAAR0Uk5T////AEAqqfQAAABASURBVHja7NKxDQAwCANBIPvvHJQFKOii+wFOLhxnWQAmILsNkNHlBqhaAW/AIPgBAAAAAAAAAAAAAHwNXAEGAORLL8ds9TzwAAAAAElFTkSuQmCC";

  string constant HAT_HAT___WHITE_BOWLER_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAA5eXl////vy5XywAAAAR0Uk5T////AEAqqfQAAABNSURBVHja7NIxCgAgDATBO/3/n4UgwSpCLGx2+wxXRPMxAVwAR33AitwF9n0tqNqfgDtAntcbigXjiE8EAAAAAAAAAAAAAAD4AiwBBgASDy9vioThbAAAAABJRU5ErkJggg==";

  string constant HAT_HAT___WHITE_TOP_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAA5eXl////vy5XywAAAAR0Uk5T////AEAqqfQAAABLSURBVHja7NIhDgAgDEPRFe5/Z8wCqIpNIPi1y14qGrOZcEdlqoAiI4BngA6gCrDffQfTYFwpLrE9ZQAAAAAAAAAAAAAAgM+BJcAAxBQu9Xnq5qoAAAAASUVORK5CYII=";

  string constant HAT_HAT___WHITE_AND_RED_BASEBALL_CAP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF////AAAAzUBI5eXl////AWgimgAAAAV0Uk5T/////wD7tg5TAAAAXklEQVR42uzSQQrAIAxE0Yn1/mcWgxQX1UDc1T+Ku7wEVfUw+jtgnjxgKn1ZFuj1vi0HeH0oKKr3cyNofXkDCEbQd/O3dw4Yz/dMufcrAwAAAAAAAAAAAAAAHKQJMACYKT7BzliRQQAAAABJRU5ErkJggg==";

  string constant HAT_HAT___WHITE_WITH_RED_HEADPHONES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAA/1BZ////kuAAcAAAAAR0Uk5T////AEAqqfQAAABrSURBVHja7NPRCoAgEETRHfv/fy6EJHB3s8SXuvOmOEcR1rbJ2EpALa8AyVoSIgQu9Uo8BVTvPZMIlvTD5T3QFWLBBVS644dQNArIfMB9w0eB6U+sUzCwtX4aAQAAAAAAAAAAAAD+DewCDADEWi6TIEdx5AAAAABJRU5ErkJggg==";

  string constant HAT_HAT___WHITE_WITH_RED_TOP_HAT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF////AAAA5eXl3ktT/1BZ////42DItQAAAAZ0Uk5T//////8As7+kvwAAAFJJREFUeNrs0jEOwDAIBEHOOP//slOgOBXFufRuizQCiXgOi26oygUUlQB8IDPnW5qANiAH+A7oj2g2GL/MTzx+ZQAAAAAAAAAAAAAAgMuBJcAAz8NOWX9yyCQAAAAASUVORK5CYII=";

  // TODO: Will need to remap hats & OptionsHats
  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return HAT_HAT___ASTRONAUT_HELMET;
    } else if (assetNum == 1) {
      return HAT_HAT___BAG_OF_ETHEREUM;
    } else if (assetNum == 2) {
      return HAT_HAT___BLACK_BOWLER_HAT;
    } else if (assetNum == 3) {
      return HAT_HAT___BLACK_TOP_HAT;
    } else if (assetNum == 4) {
      return HAT_HAT___BLACK_AND_WHITE_STRIPED_JAIL_CAP;
    } else if (assetNum == 5) {
      return HAT_HAT___BLACK_WITH_BLUE_HEADPHONES;
    } else if (assetNum == 6) {
      return HAT_HAT___BLACK_WITH_BLUE_TOP_HAT;
    } else if (assetNum == 7) {
      return HAT_HAT___BLUE_BASEBALL_CAP;
    } else if (assetNum == 8) {
      return HAT_HAT___BLUE_UMBRELLA_HAT;
    } else if (assetNum == 9) {
      return HAT_HAT___BULB_HELMET;
    } else if (assetNum == 10) {
      return HAT_HAT___CHERRY_ON_TOP;
    } else if (assetNum == 11) {
      return HAT_HAT___CRYPTO_INFLUENCER_BLUEBIRD;
    } else if (assetNum == 12) {
      return HAT_HAT___GIANT_SUNFLOWER;
    } else if (assetNum == 13) {
      return HAT_HAT___GOLD_CHALICE;
    } else if (assetNum == 14) {
      return HAT_HAT___GRADUATION_CAP_WITH_BLUE_TASSEL;
    } else if (assetNum == 15) {
      return HAT_HAT___GRADUATION_CAP_WITH_RED_TASSEL;
    } else if (assetNum == 16) {
      return HAT_HAT___GREEN_GOO;
    } else if (assetNum == 17) {
      return HAT_HAT___NODE_OPERATORS_YELLOW_HARDHAT;
    } else if (assetNum == 18) {
      return HAT_HAT___NONE;
    } else if (assetNum == 19) {
      return HAT_HAT___PINK_BUTTERFLY;
    } else if (assetNum == 20) {
      return HAT_HAT___PINK_SUNHAT;
    } else if (assetNum == 21) {
      return HAT_HAT___POLICE_CAP;
    } else if (assetNum == 22) {
      return HAT_HAT___RED_ASTRONAUT_HELMET;
    } else if (assetNum == 23) {
      return HAT_HAT___RED_BASEBALL_CAP;
    } else if (assetNum == 24) {
      return HAT_HAT___RED_DEFI_WIZARD_HAT;
    } else if (assetNum == 25) {
      return HAT_HAT___RED_SHOWER_CAP;
    } else if (assetNum == 26) {
      return HAT_HAT___RED_SPORTS_HELMET;
    } else if (assetNum == 27) {
      return HAT_HAT___RED_UMBRELLA_HAT;
    } else if (assetNum == 28) {
      return HAT_HAT___TAN_COWBOY_HAT;
    } else if (assetNum == 29) {
      return HAT_HAT___TAN_SUNHAT;
    } else if (assetNum == 30) {
      return HAT_HAT___TINY_BLUE_HAT;
    } else if (assetNum == 31) {
      return HAT_HAT___TINY_RED_HAT;
    } else if (assetNum == 32) {
      return HAT_HAT___WHITE_BOWLER_HAT;
    } else if (assetNum == 33) {
      return HAT_HAT___WHITE_TOP_HAT;
    } else if (assetNum == 34) {
      return HAT_HAT___WHITE_AND_RED_BASEBALL_CAP;
    } else if (assetNum == 35) {
      return HAT_HAT___WHITE_WITH_RED_HEADPHONES;
    } else if (assetNum == 36) {
      return HAT_HAT___WHITE_WITH_RED_TOP_HAT;
    }
    return HAT_HAT___ASTRONAUT_HELMET;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Footwear {
  using Strings for uint256;
  string constant FOOTWEAR_FOOTWEAR___BEARFOOT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___BLACK_GLADIATOR_SANDALS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAf0lEQVR42uyTUQrAIAxDn/e/9GCC2jpniwz2EUWQWF5DipTDhQACCCCAAAIIIIAAAgggQBZAf2RX96zXba9xAP3w7uEzB/gMIDsF5yAVInc/TBULD6w0yuigaREAQ9fqx6QRALTqBsC+BAGd5IVtBrjySYhMwYQ+CX/6zpcAAwBGVg+X6K8IkgAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___BLACK_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAANTU1////eV5mqQAAAAN0Uk5T//8A18oNQQAAAHdJREFUeNrs09EKgCAQRNG7/f9HZyppou5CL0Fj6MPgHKyQ4+VAgAABAgQIECBAgAABAn4LENmxiaFMf+eYYnktQCYM4kDqp4cG1CAKtL5dgG0FZn26ficwExZA17+FOGDP/ixxvoHlwS7x/sJ43NULfOEunAIMAEFDHt/2yl1PAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___BLACK_AND_BLUE_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAQFbNNTU1Ok65////ExF1mwAAAAV0Uk5T/////wD7tg5TAAAAh0lEQVR42uyTSwrAQAhDo/b+Z26dTztQUoRuWogrDfiSEQbby4IAAggggAACCCCAAAIIIMDfAMiiYwXg7qBjNUG3Xdo6oDkiJuBoaARw/8jFHFrDMoD4+1gbCaJrNcB8c1w3CH4H8PsdZQmwVakAzgUzdMFWYCGBjZp+d6V2AzxK3/lMuwADAMKEPN0rbdJFAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___BLACK_AND_WHITE_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAARUVFzs7O////PUlx0AAAAAR0Uk5T////AEAqqfQAAAB9SURBVHja7NPBCoAwDAPQpP7/P1u76YZIV/AimI15CM07bIjt5YIAAQIECBAgQIAAAQIE/BZAZSKJgXbWk/cUjG8DgiBQB7zvGwPoQRUYfR4AU+Ehg9nUnwTPq4CPXv1TiLQG0GKYGEnUjSjeAWMhS1av0N8uSb7zL+wCDAB7aS5pEKrMVwAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/AAAAQFbNOk65/////WvZMQAAAAV0Uk5T/////wD7tg5TAAAAiklEQVR42uzTwQ6AIAwD0Hbz/79Zl6lw2YLxokl3EQi8VYzYXhYECBAgQIAAAQIECBAg4GcAETXtiuIjwN1nIKZ8nCC7zuNVIAOATOB41hFQ9+cAWGdA0d/zWL5CDL3IgCbAuIMmApobBCwAG/NF4Dphxpzb5C1domXx3M97YfkzZjULX/qZdgEGAOgYPSkdBXNjAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___BLUE_CROCS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/QFbNAAAA////e4+K7QAAAAR0Uk5T////AEAqqfQAAACHSURBVHja7NLRDoAgCAVQuP3/P5eAs9LEVo+XhzaYHtCU7WMIAQIECBAgQIAAAQIECBB4CUBKnFaVwDrg+5sQKVYBqKgDtgUOHEWsAYj10fSW5gDqAMen9IRKzXUgyOgAtaPP3BVyQK9n7ivJHcTMbbXNoMMBHv6CBWaV5B1YzCu/PeVdgAEAOP4uMXpWMqcAAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___BLUE_FLIP_FLOPS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/AAAAOk65////ucZOEwAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NLbCsAgDAPQpPv/f571LhQsDPaUgkNCeyZzeD4WBAgQIECAAAECBAgQIEDAzwDjXmYB4hiZc2AO4Ep9ZHIIz4D4/WUBGIBva2dwhgjo0+VpDljdtjQLtLTOD8Fbk4DhmN+EmVw+YhFK2eqm9YjJazQvbt3sUfpH8rpGrV4BBgDn0y7rApH2nwAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___BLUE_HIGH_HEELS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/AAAAS2Le////23idyAAAAAR0Uk5T////AEAqqfQAAACESURBVHja7NJRDoAgDAPQrt7/zsrGYjS4zPBb/mzoywBxbC4IECBAgAABAgQIECBAgICfgC1iWB8wzJh2Y1gLqPoIoBRQ9ROoBHxewNVjAEyiB8wBRt8CsBR8og4Qi5aACxF1AN/NGN+DkZF5pMYdcLTtsff6JFf99TO+2lW6/yufAgwARaQus8v8p3AAAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___BLUE_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/AAAAOk65QFbN////MeuL8wAAAAV0Uk5T/////wD7tg5TAAAAgklEQVR42uzTwQ6AIAwD0Hbz/79ZQAQ0iku8mNh5gFT7DhiwvBwIECBAgAABAgQIECBAwO8A9pWnKASwxuBxHwUIWH6HDUD+yHAt4KafHnSgBowB9Na3DFgTnEHAh/4geBxIROvvQk6DgHkhjD0pdTcGD9HKcJY8/MYy8+Q7d2EVYADA/D4NHRs+PQAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___BLUE_TOENAIL_POLISH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAAOklEQVR42uzRwQkAMAwCQLP/0h2gUCg+c34jB8FMmQAAAAAAAAAAAAAAAPALpO+2L+Q65FFdP+MRYAAP/w/7AEwtVAAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___BLUE_WORK_BOOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAQFbNOk65RUVF////MzCQEAAAAAV0Uk5T/////wD7tg5TAAAAh0lEQVR42uzTUQ6AIAwD0Lpx/zO7sUlMBJH4p+0PgvaFLBHlZUCAAAECBAgQIECAAAECfwOwWdRir+Gr77ECaABIwEFdAKyvDiAAW2w3EDDsW0QckPo8EnDbPwMDAb0BatYTkHaHziAvJ4jPvYyYgSeNKk5vIBErH0BBO3w0g8zs7DP/wi7AAOl7PabgxTbJAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___BLUE_AND_GRAY_BASKETBALL_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/AAAANTU1RUVF////D76rVwAAAAV0Uk5T/////wD7tg5TAAAAiklEQVR42uzTUQqAMAwD0LTx/md2tRUUtuHwS0n/Npa3oAzby4EAAQIECBAgQIAAAQIEfAwwxFxOxdgS4PQrEEtbbgCwhYy1WACywA0YVsDkftAD8LNCV0AvzyxAT+AQ2hZ7AoYF2PIFODms0AN4xv0IhJAE7eE3YMXrvBVBe/wXciYbv3pMuwADAJnjPcGRET9iAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___PINK_HIGH_HEELS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6Jr/AAAAyqLV////Ci+i2QAAAAR0Uk5T////AEAqqfQAAACESURBVHja7NJRDoAgDAPQrt7/zsrGYjS4zPBb/mzoywBxbC4IECBAgAABAgQIECBAgICfgC1iWB8wzJh2Y1gLqPoIoBRQ9ROoBHxewNVjAEyiB8wBRt8CsBR8og4Qi5aACxF1AN/NGN+DkZF5pMYdcLTtsff6JFf99TO+2lW6/yufAgwARaQus8v8p3AAAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___PINK_TOENAIL_POLISH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6Jr/////Gn0/cgAAAAJ0Uk5T/wDltzBKAAAAOklEQVR42uzRwQkAMAwCQLP/0h2gUCg+c34jB8FMmQAAAAAAAAAAAAAAAPALpO+2L+Q65FFdP+MRYAAP/w/7AEwtVAAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___PINK_WORK_BOOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF6Jr/RUVFAAAAyqLVNTU1////dtmZGgAAAAZ0Uk5T//////8As7+kvwAAAJFJREFUeNrs09sKgCAQBNC99f+/3GxaKGQWvQTNEKWLezAjWV5GCBAgQIAAAQIECBAgQOBvgAmiiGGcT0zdngBagKhA5PQBgH5NIAoQAUAHggz7c9e5bfNtPBLkor8HBoKcHeDR3wFZtjlwrPf2K3izpRmgXoLuHcC1F+3GK2iNLbYtx72p3TnEmlntK//CKsAA7JRMfn/jYOMAAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZAAAAzUBIuTpB////////WeF5aAAAAAZ0Uk5T//////8As7+kvwAAAItJREFUeNrs00sOgCAMBNDpx/tfWZuqdFOCcaPJdCMQeB0xYntZIECAAAECBAgQIECAAIGfAYKositKHgFmVoGYyuME2bWOV4EMAPcEjmcfAX1/H4D3GdD0tzyWrxBDazJgEmDcwSQCJjcIaAA65ovAdUJVcq7FW7pEzZJzv9wLy58xa7LwpZ9pF2AAy2hMgyGvO7sAAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___RED_CROCS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZzUBIAAAA////KQANqwAAAAR0Uk5T////AEAqqfQAAACHSURBVHja7NLRDoAgCAVQuP3/P5eAs9LEVo+XhzaYHtCU7WMIAQIECBAgQIAAAQIECBB4CUBKnFaVwDrg+5sQKVYBqKgDtgUOHEWsAYj10fSW5gDqAMen9IRKzXUgyOgAtaPP3BVyQK9n7ivJHcTMbbXNoMMBHv6CBWaV5B1YzCu/PeVdgAEAOP4uMXpWMqcAAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___RED_FLIP_FLOPS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZAAAAuTpB////yw3NhQAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NLbCsAgDAPQpPv/f571LhQsDPaUgkNCeyZzeD4WBAgQIECAAAECBAgQIEDAzwDjXmYB4hiZc2AO4Ep9ZHIIz4D4/WUBGIBva2dwhgjo0+VpDljdtjQLtLTOD8Fbk4DhmN+EmVw+YhFK2eqm9YjJazQvbt3sUfpH8rpGrV4BBgDn0y7rApH2nwAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___RED_HIGH_HEELS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZAAAA////KfmcOwAAAAN0Uk5T//8A18oNQQAAAHdJREFUeNrs0lEKwCAMA9Bk9z+0qC3O0ZWKv/EzmGdR8VwuCBAgQIAAAQIECBAgQICAQ4BBDNYBAqvkGGIBaX8CqYC0b0Am4PcCgAUYUQNsgFGfAF2IRggBW3TgFZ0AvTyCPStdYj9928s5BYvP+Gln6f1XbgIMAMdTHwvim8UAAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___RED_TOENAIL_POLISH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAAOklEQVR42uzRwQkAMAwCQLP/0h2gUCg+c34jB8FMmQAAAAAAAAAAAAAAAPALpO+2L+Q65FFdP+MRYAAP/w/7AEwtVAAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___RED_WORK_BOOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF////zUBIAAAAuTpB////MVcWZQAAAAV0Uk5T/////wD7tg5TAAAAi0lEQVR42uzTUQ6AIAwD0Lpx/zM7YBIiIBB/TGw/FAl90SUivAwIECBAgAABAgQIECBA4G+AHBZYxNbxHp9lB0ALYAOwPu4ABgKGfYtqBDStRwIe+zUwENAbILzugJZ36AyyASQft1Y9AzeSOAOgOda+AEHZlIVPgEeCpON2rfZWhuiZ7X3lXzgFGAB/uz1t//AxWQAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___RED_AND_GRAY_BASKETBALL_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZAAAAysrKurq6////////Vgjz/AAAAAZ0Uk5T//////8As7+kvwAAAJVJREFUeNrs08EKxDAIBFB13P//5cZqSgtJSdjLLow3Jb4MLZHPlyUECBAgQIAAAQIECBAg8GeAStTtVJRuAQa7A9HqdgIRtCVFNRtABngA0wjycr/AArAeYSjIaB8ZAJbAKbQRRoJMA6DtF2DANMIIQF83D8CtE1gEHLXumn0RcF38iJ6ldV6vwfJvzHoZ/NJjOgQYAATZTNMRijgsAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___STEPPED_IN_A_PUMPKIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF3H4xxnErAAAAv7+/////OtLG0AAAAAV0Uk5T/////wD7tg5TAAAAZ0lEQVR42uzTuwrAMAxDUVnu/39zncdYKDiULldDPOmAwdF1GAEAAAAAAAAAAAAAAABU7DMgJbcAR65+PAp670tZqREK94DQfppAtbdxBAzjF6CEWR4LhFt34CJm7O4heeWbv3ALMAASoT6VYD0TNgAAAABJRU5ErkJggg==";

  string constant FOOTWEAR_FOOTWEAR___TAN_COWBOY_BOOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFnIFNiW8+AAAA////ushiWgAAAAR0Uk5T////AEAqqfQAAACUSURBVHja7NPBDoAgDAPQdv7/P6swFMMQ0YuH7qDJQp8DIpaPBQECBAgQIECAAAECBAiYAwAMGveAkdcAQNoMAC//eCqbncBDjr2ZgAXg7ATGnGcGmIV4BMR5tgBjAd18s4VYQLR/ojr540YcHAHVeqaTt/2N7l32gS1dADuFBwBL2WJp+fasm+MzKDVs/uR3XgUYABTXLYHfBa9KAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___TAN_WORK_BOOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFnIFNiW8+AAAA////ushiWgAAAAR0Uk5T////AEAqqfQAAACFSURBVHja7NNRDoAgDAPQrtz/zg5FgggC8cfE7kNxoS/KIsLLggABAgQIECBAgAABAgT8DSC8zIu+jvf4zBXA7oAtAJ63GrCOgG4e6bWZlh0Bj/kS6AhoHWDOX4DY5hgo9ldTQHMUaA7gyPMEmAXjxCdYKgbu2/1a9GYOMdWo95V/YRNgAGtrLe9GZ97wAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___WATERMELON_SHOES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUf9aAAAA4YGAV9Rd////GtyL9AAAAAV0Uk5T/////wD7tg5TAAAAnElEQVR42uzTUQrEIAwE0Jmk9z/zGqPSLQpZ9rMjRZtgnoFaXH8OCBAgQIAAAQIECBAgQMDLALKe3QH0lWV/xlZnDSDM1ivpMzADK0Cr4BDMnI3LsshuBGwbiM0xIQCfcXglwG2UIAGsuAok0dYOxNqPxw8AkDMz7kgViK+4Sh4Ai/cAswneWtrXH27iAHhvycH6v8Ach/BrfAQYALQTPWXGbH2RAAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___WHITE_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAAysrK////8hTnlQAAAAR0Uk5T////AEAqqfQAAAB4SURBVHja7NPBDoAwCAPQgv//zzqcyhJkGC8mlnlYqn2HLWJ5OSBAgAABAgQIECBAgACB3wJiz7GtA9JjyLivAgJoe4cdQPtIEQu46W8LF9ADqQGurw3QVIgB13fCE8D1T6EO6NiPkskhqo1kyeQabfLkO//CKsAAfD8uc7Djs80AAAAASUVORK5CYII=";

  string constant FOOTWEAR_FOOTWEAR___WHITE_AND_RED_SNEAKERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF////AAAAzUBIysrKuTpB////qhKu4wAAAAZ0Uk5T//////8As7+kvwAAAIxJREFUeNrs00sOgDAIBUCgeP8rC5IqG/qJG00ebiixA5JIx8sgAAAAAAAAAAAAAAAAAPgZwOSR3vLgLaC1lgE/8vYE0TXnq0AMQNoBS8oRqO6v9lyAJ+UMVPRvca1PoFHjFeD+Zn12oPUeBoCFOCCpsATcF0Q4CpLBOWAXIpirymSJPYal7/xMpwADAEnqTCfSnHo6AAAAAElFTkSuQmCC";

  string constant FOOTWEAR_FOOTWEAR___YELLOW_RAIN_BOOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6sU3AAAAz68x/+ue////5D3IEgAAAAV0Uk5T/////wD7tg5TAAAAbUlEQVR42uzT0QqAIAyF4ePs/Z+5JkUJuSFBUPznagzOBypqeRgBAAAAAAAAAAAAAAC8DBRVeUo3fgzQCWgeOEpXYCAoOoDMAduGOhSU9TNBwQFsLzRhCrCuf7NI78A8JVikr+AJF3/6jasAAwA9LD1hKIBN8gAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return FOOTWEAR_FOOTWEAR___BLACK_GLADIATOR_SANDALS;
    } else if (assetNum == 1) {
      return FOOTWEAR_FOOTWEAR___BLACK_SNEAKERS;
    } else if (assetNum == 2) {
      return FOOTWEAR_FOOTWEAR___BLACK_AND_BLUE_SNEAKERS;
    } else if (assetNum == 3) {
      return FOOTWEAR_FOOTWEAR___BLACK_AND_WHITE_SNEAKERS;
    } else if (assetNum == 4) {
      return FOOTWEAR_FOOTWEAR___BLUE_BASKETBALL_SNEAKERS_WITH_BLACK_STRIPE;
    } else if (assetNum == 5) {
      return FOOTWEAR_FOOTWEAR___BLUE_CROCS;
    } else if (assetNum == 6) {
      return FOOTWEAR_FOOTWEAR___BLUE_FLIP_FLOPS;
    } else if (assetNum == 7) {
      return FOOTWEAR_FOOTWEAR___BLUE_HIGH_HEELS;
    } else if (assetNum == 8) {
      return FOOTWEAR_FOOTWEAR___BLUE_SNEAKERS;
    } else if (assetNum == 9) {
      return FOOTWEAR_FOOTWEAR___BLUE_TOENAIL_POLISH;
    } else if (assetNum == 10) {
      return FOOTWEAR_FOOTWEAR___BLUE_WORK_BOOTS;
    } else if (assetNum == 11) {
      return FOOTWEAR_FOOTWEAR___BLUE_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (assetNum == 12) {
      return FOOTWEAR_FOOTWEAR___PINK_HIGH_HEELS;
    } else if (assetNum == 13) {
      return FOOTWEAR_FOOTWEAR___PINK_TOENAIL_POLISH;
    } else if (assetNum == 14) {
      return FOOTWEAR_FOOTWEAR___PINK_WORK_BOOTS;
    } else if (assetNum == 15) {
      return FOOTWEAR_FOOTWEAR___RED_BASKETBALL_SNEAKERS_WITH_WHITE_STRIPE;
    } else if (assetNum == 16) {
      return FOOTWEAR_FOOTWEAR___RED_CROCS;
    } else if (assetNum == 17) {
      return FOOTWEAR_FOOTWEAR___RED_FLIP_FLOPS;
    } else if (assetNum == 18) {
      return FOOTWEAR_FOOTWEAR___RED_HIGH_HEELS;
    } else if (assetNum == 19) {
      return FOOTWEAR_FOOTWEAR___RED_TOENAIL_POLISH;
    } else if (assetNum == 20) {
      return FOOTWEAR_FOOTWEAR___RED_WORK_BOOTS;
    } else if (assetNum == 21) {
      return FOOTWEAR_FOOTWEAR___RED_AND_GRAY_BASKETBALL_SNEAKERS;
    } else if (assetNum == 22) {
      return FOOTWEAR_FOOTWEAR___STEPPED_IN_A_PUMPKIN;
    } else if (assetNum == 23) {
      return FOOTWEAR_FOOTWEAR___TAN_COWBOY_BOOTS;
    } else if (assetNum == 24) {
      return FOOTWEAR_FOOTWEAR___TAN_WORK_BOOTS;
    } else if (assetNum == 25) {
      return FOOTWEAR_FOOTWEAR___WATERMELON_SHOES;
    } else if (assetNum == 26) {
      return FOOTWEAR_FOOTWEAR___WHITE_SNEAKERS;
    } else if (assetNum == 27) {
      return FOOTWEAR_FOOTWEAR___WHITE_AND_RED_SNEAKERS;
    } else if (assetNum == 28) {
      return FOOTWEAR_FOOTWEAR___YELLOW_RAIN_BOOTS;
    }
    return FOOTWEAR_FOOTWEAR___BEARFOOT;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Feet {
  using Strings for uint256;
  string constant FEET_FEET___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF+dZOAAAA7MtK//jb1bY+8vLy8uvQ////Czaq5AAAAAh0Uk5T/////////wDeg71ZAAAAn0lEQVR42uzU0Q6CMAwF0Hvbov//x66AwBQMlcQHc5s9NEt6Nkoz3C8GBAgQIECAAAECBAgQ8FNgsNcdGyoArUVX3oIVALDVsClqgAMjwrzMnFZ68BTYpd8CY14G1lN5HUihBkz1HYBboYl0bPs2c86zQKuPdyD2hV0A4bkWwOCRi4VP2NQvAs/3ABbd5LVxjINRPPgLGR83/ulFeggwAFg0aqXdA+GjAAAAAElFTkSuQmCC";

  string constant FEET_FEET___SMALL_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vrAAAAyMjI2dnZ////Kx1DFwAAAAV0Uk5T/////wD7tg5TAAAAjUlEQVR42uzU2wqAIAwG4B16/2eupVkjD43AIP5d6WgfTke0vAwCAAAAAAAAAAAAAADAVEBknOkBLOILbM8RgEhOQ1IEAQurssPkZeQODoHdcj6QivgLwB273wMN68uW+CmwFegd0LpQB3T/vgBCKcOBFvTadBY4cAeibvK2cdTGKDZewaKb+NMfaRVgALO8PRmJ8eR8AAAAAElFTkSuQmCC";

  string constant FEET_FEET___SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFNTU1AAAALS0t////vgF0DAAAAAR0Uk5T////AEAqqfQAAACGSURBVHja7NRZCsAgDATQZLz/nduQVgl1pWChTL6MMA83lPSyhAABAgQIECBAgAABAlsBYDzTAxSIAet1BRBBMeC1CFhZyhZzDVfO4BY0DPcDHtIvgLDs/h5kmM+t6CxwBvQJaF2oA05kAB6fBlLMF2HhDKDh5VnXeIqNW7DqTvzpRzoEGADxri3xIUc9nwAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return FEET_FEET___GOLD_PANDA;
    } else if (assetNum == 1) {
      return FEET_FEET___SMALL_PANDA; // polar / reverse_panda
    } else if (assetNum == 2) {
      return FEET_FEET___SMALL; // black / panda
    }
    return FEET_FEET___SMALL;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Face {
  using Strings for uint256;
  string constant FACE_FACE___BLACK_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAASUlEQVR42uzSMQoAIAgAQPv/p5uiooSiLc5FETlEjPIYAQD8DMQ2boFWTI0zYBjvORFyYN3gFjg7gkcCAAAAAAAAAAC+BaoAAwDHFQ+pl0nn5AAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAucDmOk65UGv/////My4rFgAAAAV0Uk5T/////wD7tg5TAAAAc0lEQVR42uzVQQqAMAxE0W/q/c9sg12IiNgOFNTJJqs8pqEQVrF4CwAaQAkM/BPgWN1ADi1Ze0uA7gQnoCsBVwkYSdAgYYmt+ydKQIQGUAoaEFWoyvgTUriZf7BEohbKXQD4wGkzYMCAAQMGDBiYCGwCDACWwT2pFgiN1AAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAASklEQVR42uzSsQoAIAgA0ev/f7qGhgiEIiGHc9BFHorSHgMBgeoAI9Z6CzATB235APv4hHtUXSHlCr6ygICAgICAgICAwF+gCzAA1YwP02ZX02sAAAAASUVORK5CYII=";

  string constant FACE_FACE___BLUE_MEDICAL_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAABkSURBVHja7NNBCsAgDETRabz/nVsGUbowSrorP0s1z1FU7WMJAAAAIAUi+qzrPXaYwMul6ykLi/bsCBEatWzP78D7O0PxEmeCMtADVIF2EGDzDvb9/AUAAAAAAAAAgH8CtwADAK54LzvaZ+K/AAAAAElFTkSuQmCC";

  string constant FACE_FACE___BLUE_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NI5DgAgCERRwPvf2UjiEpeC2OmfhoLMCwWSLiMAAC8DJmvUooCv+4wArV+adepeOAPTBRoHvDTGeCQAAAAAAAAAAACAr4AswAA8xC8j72kkzQAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAATUlEQVR42uzSsQoAIAgA0ev/f7pBCIdKqi0uEBd9KkR7fAgI/A8AKZ0DRFBXzYeTAZZrVBsM5+aE6N5M9yMJCAgICAgICAgIfA10AQYAPLEP28WFfGsAAAAASUVORK5CYII=";

  string constant FACE_FACE___BLUE_VERBS_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAASUlEQVR42uzSMQoAIAgAQPv/p4MIImgoDII4B13kFDFKMgIA+B2IFqOeAz3FRtt6/FSPgfQGWeDGEX0iAAAAAAAAAADwFqgCDADOpQ/SPOt3XwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___BLUE_AND_BLACK_CHECKERED_BANDANA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/AAAA////7jh4eQAAAAN0Uk5T//8A18oNQQAAAGdJREFUeNrslEEOwCAMw5r9/9HjjLYmFZq0g+EG2EJtoK7DUQgQIPi14HFVkxsoPvm2rG1DpVkNlmGb0yKGfNOFjO/aGPFtDhK+D1LAmyR63kXZ8vYtOJ7/AAECBAgQIECA4AvBLcAAr1ofa+nN+qcAAAAASUVORK5CYII=";

  string constant FACE_FACE___BROWN_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFnIFNiW8+////JxjFGwAAAAN0Uk5T//8A18oNQQAAAFJJREFUeNrs0ssKABAYROEZ7//QlOtGEcXi/Auz4WuEwuEIAOB3QGnG3AVUFi1suw+k0s4H3dJ+cgX33H+F2nranq8MAAAAAAAAAAAA8DUQBRgAaWIfthnfdg4AAAAASUVORK5CYII=";

  string constant FACE_FACE___CANDY_CANE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF////sSop////+TKYjgAAAAN0Uk5T//8A18oNQQAAADlJREFUeNrs0cEJADAMAkDT/YcOZIQG+unp/xDMWSYAAADwHZDaLsg9UJl6AQAAAAAAAADwFGgBBgB/px/yKoiShgAAAABJRU5ErkJggg==";

  string constant FACE_FACE___GOLD_FRAMED_MONOCLE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6sU3////Xg8AigAAAAJ0Uk5T/wDltzBKAAAARUlEQVR42uzR0QkAIAwD0XP/pZ1AKRwIwvU7PELDkkdAQMAUABTAPTUE0A3QP8CuoIFTMuDpCgEBAQEBAQEBAR8BW4ABABTSD+vMiGP9AAAAAElFTkSuQmCC";

  string constant FACE_FACE___GRAY_BEARD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFzs7OsrKy////iqjJwAAAAAN0Uk5T//8A18oNQQAAAGBJREFUeNrs07sOACEIRNEZ//+jdddHaXahMl4tLAhHQkAleQQAAABwBKARtGKA1DPn+xvwt282wIrJwR4414MGvFdhoIx0x+egl5AZpKeE5CSabQQAAAAAAAC4D6gCDADi5h+wR5SUKwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAASklEQVR42uzSsQoAIAgA0ev/f7qGhgiEIiGHc9BFHorSHgMBgeoAI9Z6CzATB235APv4hHtUXSHlCr6ygICAgICAgICAwF+gCzAA1YwP02ZX02sAAAAASUVORK5CYII=";

  string constant FACE_FACE___RED_MEDICAL_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ1jc/5eXl////////y3PFlwAAAAV0Uk5T/////wD7tg5TAAAAaklEQVR42uzTyw6AIAxE0XHK/3+z2hCNCx7iztwugR5KAZWPIQAAAIAuEFFnM55jU4Cdy6XtiBQi7FdHOAld0Uzv9cDO/bOGZnq/iXcFi7egWsIyUCYKGLyDcT5/AQAAAAAAAADgn8AuwADAQj7f1e8yxAAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZ3ktTAAAA////hP6nfQAAAAR0Uk5T////AEAqqfQAAABQSURBVHja7NI5DgAgCERRwPvf2UjiEpeC2OmfhoLMCwWSLiMAAC8DJmvUooCv+4wArV+adepeOAPTBRoHvDTGeCQAAAAAAAAAAACAr4AswAA8xC8j72kkzQAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_STRAIGHT_BOTTOM_FRAMED_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAATUlEQVR42uzSsQoAIAgA0ev/f7pBCIdKqi0uEBd9KkR7fAgI/A8AKZ0DRFBXzYeTAZZrVBsM5+aE6N5M9yMJCAgICAgICAgIfA10AQYAPLEP28WFfGsAAAAASUVORK5CYII=";

  string constant FACE_FACE___RED_VERBS_GLASSES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAASUlEQVR42uzSMQoAIAgAQPv/p4MIImgoDII4B13kFDFKMgIA+B2IFqOeAz3FRtt6/FSPgfQGWeDGEX0iAAAAAAAAAADwFqgCDADOpQ/SPOt3XwAAAABJRU5ErkJggg==";

  string constant FACE_FACE___RED_AND_WHITE_CHECKERED_BANDANA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/////1BZ////FD2rYAAAAAN0Uk5T//8A18oNQQAAAGRJREFUeNrslDEOACEMw1L+/+hjZmhSnZAYDGttiTZF6+cRAgQInhZUXqrYW6MnlI56lWY92IbjTpsY8s0UMr4bY8S3OUj4PkgBb5LoeRdly9tdcDz/AQIECBAgQIAAwQ3BJ8AAr5ofa9Y/gbkAAAAASUVORK5CYII=";

  string constant FACE_FACE___WHITE_NINJA_MASK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////5eXlAAAA////EjtCTgAAAAR0Uk5T////AEAqqfQAAABRSURBVHja7NJBCgAgCERRs/vfOQqMIIWkVfFn40J8iCj1MgIA8DOg4kSzwGgvNQHM+T5pNRBiYNsgDZwdwQVKED4RAAAAAAAAAAAA4CWgCTAA+WUu3beAbwkAAAAASUVORK5CYII=";

  string constant FACE_FACE___WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFAAAA/////1BZ+E9Y8djZ5eXl2MHD////GegMIgAAAAh0Uk5T/////////wDeg71ZAAAAiUlEQVR42uzV0QqAIAwF0LvZ6v//uM0KoodIB0F574M+7TiHIJZk8BUAyAHQAgJjAnJKOxBVc2TbApAmwMxkikjdArAWoPZ9AUQaADs62KHagXUN0aGuIe5dxKmxDv6UVXMAVJEDiguu9F8hhJv6B0NE8SDzLwDAD742AgQIECBAgACBF4FVgAEAzaxr1bnIEfoAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return FACE_FACE___BLACK_NINJA_MASK;
    } else if (assetNum == 1) {
      return FACE_FACE___BLACK_SWIMMING_GOGGLES_WITH_BLUE_SNORKEL;
    } else if (assetNum == 2) {
      return FACE_FACE___BLUE_FRAMED_GLASSES;
    } else if (assetNum == 3) {
      return FACE_FACE___BLUE_MEDICAL_MASK;
    } else if (assetNum == 4) {
      return FACE_FACE___BLUE_NINJA_MASK;
    } else if (assetNum == 5) {
      return FACE_FACE___BLUE_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (assetNum == 6) {
      return FACE_FACE___BLUE_VERBS_GLASSES;
    } else if (assetNum == 7) {
      return FACE_FACE___BLUE_AND_BLACK_CHECKERED_BANDANA;
    } else if (assetNum == 8) {
      return FACE_FACE___BROWN_FRAMED_GLASSES;
    } else if (assetNum == 9) {
      return FACE_FACE___CANDY_CANE;
    } else if (assetNum == 10) {
      return FACE_FACE___GOLD_FRAMED_MONOCLE;
    } else if (assetNum == 11) {
      return FACE_FACE___GRAY_BEARD;
    } else if (assetNum == 12) {
      return FACE_FACE___NONE;
    } else if (assetNum == 13) {
      return FACE_FACE___RED_FRAMED_GLASSES;
    } else if (assetNum == 14) {
      return FACE_FACE___RED_MEDICAL_MASK;
    } else if (assetNum == 15) {
      return FACE_FACE___RED_NINJA_MASK;
    } else if (assetNum == 16) {
      return FACE_FACE___RED_STRAIGHT_BOTTOM_FRAMED_GLASSES;
    } else if (assetNum == 17) {
      return FACE_FACE___RED_VERBS_GLASSES;
    } else if (assetNum == 18) {
      return FACE_FACE___RED_AND_WHITE_CHECKERED_BANDANA;
    } else if (assetNum == 19) {
      return FACE_FACE___WHITE_NINJA_MASK;
    } else if (assetNum == 20) {
      return FACE_FACE___WHITE_SWIMMING_GOGGLES_WITH_RED_SNORKEL;
    }
    return FACE_FACE___NONE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Eyes {
  using Strings for uint256;
  string constant EYES_EYES___ANNOYED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9ETHn5lVoIAAAAAnRSTlMADQgisYUAAAAqSURBVDjLY2AYgUA0gDUERSD7ifRLFAGpCWxLUARYHRgDGEbBKBgFKAAA8DgE/MaIEywAAAAASUVORK5CYII=";

  string constant EYES_EYES___ANNOYED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///+bf0dKSlCeAAAAAnRSTlMADQgisYUAAAAqSURBVDjLY2AYgUA0gDUERSD7ifRLFAGpCWxLUARYHRgDGEbBKBgFKAAA8DgE/MaIEywAAAAASUVORK5CYII=";

  string constant EYES_EYES___ANNOYED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9+qYA3AXdfAAAAAnRSTlMADQgisYUAAAAqSURBVDjLY2AYgUA0gDUERSD7ifRLFAGpCWxLUARYHRgDGEbBKBgFKAAA8DgE/MaIEywAAAAASUVORK5CYII=";

  string constant EYES_EYES___BEADY_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEwAAACfKoRRAAAAAXRSTlMAQObYZgAAABNJREFUKM9jYBg0gEOAYRQMNQAAKygAGbA5S5AAAAAASUVORK5CYII=";

  string constant EYES_EYES___BEADY_RED_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAQMAAACQp+OdAAAABlBMVEVHcEz/AAAhsrC8AAAAAXRSTlMAQObYZgAAABNJREFUKM9jYBg0gEOAYRQMNQAAKygAGbA5S5AAAAAASUVORK5CYII=";

  string constant EYES_EYES___BORED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9ETHn5lVoIAAAAAnRSTlMADQgisYUAAAAqSURBVDjLY2AY/oA1gDUARUDqifQS/AJsE9gmoAgwOjA6MIyCUTAKUAAA0S8F07R2nfUAAAAASUVORK5CYII=";

  string constant EYES_EYES___BORED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///+bf0dKSlCeAAAAAnRSTlMADQgisYUAAAAqSURBVDjLY2AY/oA1gDUARUDqifQS/AJsE9gmoAgwOjA6MIyCUTAKUAAA0S8F07R2nfUAAAAASUVORK5CYII=";

  string constant EYES_EYES___BORED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9+qYA3AXdfAAAAAnRSTlMADQgisYUAAAAqSURBVDjLY2AY/oA1gDUARUDqifQS/AJsE9gmoAgwOjA6MIyCUTAKUAAA0S8F07R2nfUAAAAASUVORK5CYII=";

  string constant EYES_EYES___DILATED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///88Q2qgUT7xAAAAAnRSTlMADQgisYUAAAAtSURBVDjLY2AYdoDVgTEARUBqAtsSFIHsJVIvUQSylkitxK8Fw9BRMApGAQMAIA8HuAY9e90AAAAASUVORK5CYII=";

  string constant EYES_EYES___DILATED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///+Jbz428/xJAAAAAnRSTlMADQgisYUAAAAtSURBVDjLY2AYdoDVgTEARUBqAtsSFIHsJVIvUQSylkitxK8Fw9BRMApGAQMAIA8HuAY9e90AAAAASUVORK5CYII=";

  string constant EYES_EYES___DILATED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9ulnDORAwPAAAAAnRSTlMADQgisYUAAAAtSURBVDjLY2AYdoDVgTEARUBqAtsSFIHsJVIvUQSylkitxK8Fw9BRMApGAQMAIA8HuAY9e90AAAAASUVORK5CYII=";

  string constant EYES_EYES___NEUTRAL_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9ETHn5lVoIAAAAAnRSTlMADQgisYUAAAAlSURBVDjLY2AYdoDRgdEBRYBtAtsEVIEL7AQEMMwYBaNgFGACAI9hBQup5K61AAAAAElFTkSuQmCC";

  string constant EYES_EYES___NEUTRAL_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///+bf0dKSlCeAAAAAnRSTlMADQgisYUAAAAlSURBVDjLY2AYdoDRgdEBRYBtAtsEVIEL7AQEMMwYBaNgFGACAI9hBQup5K61AAAAAElFTkSuQmCC";

  string constant EYES_EYES___NEUTRAL_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAACVBMVEVHcEz///9ulnDTmdmoAAAAAXRSTlMAQObYZgAAAB1JREFUOMtjYBj+gNGB0QFVoIGJgMAoGAWjgAgAAK0XAgmsoENdAAAAAElFTkSuQmCC";

  string constant EYES_EYES___SQUARE_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9ETHn5lVoIAAAAAnRSTlMADQgisYUAAAAnSURBVDjLY2AYdoAxgNUBRYBtidQEVIEn0oQE0LVgGDoKRsEoYAAAw60G/009t7UAAAAASUVORK5CYII=";

  string constant EYES_EYES___SQUARE_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///+bf0dKSlCeAAAAAnRSTlMADQgisYUAAAAnSURBVDjLY2AYdoAxgNUBRYBtidQEVIEn0oQE0LVgGDoKRsEoYAAAw60G/009t7UAAAAASUVORK5CYII=";

  string constant EYES_EYES___SQUARE_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9+qYA3AXdfAAAAAnRSTlMADQgisYUAAAAlSURBVDjLY2AYdoDRgdEBRYBtAtsEVIEL7AQEMMwYBaNgFGACAI9hBQup5K61AAAAAElFTkSuQmCC";

  string constant EYES_EYES___SURPRISED_BLUE_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///8/Rm+vCoBiAAAAAnRSTlMADQgisYUAAAApSURBVDjLY2AY6oDRgdEBRYBtAtsEFAHpJ9JPSBTAMAPDllEwCkYBAwCyRglXzEqydAAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SURPRISED_BROWN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///+PdEFb8ifMAAAAAnRSTlMADQgisYUAAAApSURBVDjLY2AY6oDRgdEBRYBtAtsEFAHpJ9JPSBTAMAPDllEwCkYBAwCyRglXzEqydAAAAABJRU5ErkJggg==";

  string constant EYES_EYES___SURPRISED_GREEN_EYES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABAAgMAAADXB5lNAAAADFBMVEVHcEwAAAD///9znHVQPyApAAAAAnRSTlMADQgisYUAAAApSURBVDjLY2AY6oDRgdEBRYBtAtsEFAHpJ9JPSBTAMAPDllEwCkYBAwCyRglXzEqydAAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return EYES_EYES___ANNOYED_BLUE_EYES;
    } else if (assetNum == 1) {
      return EYES_EYES___ANNOYED_BROWN_EYES;
    } else if (assetNum == 2) {
      return EYES_EYES___ANNOYED_GREEN_EYES;
    } else if (assetNum == 3) {
      return EYES_EYES___BEADY_EYES;
    } else if (assetNum == 4) {
      return EYES_EYES___BEADY_RED_EYES;
    } else if (assetNum == 5) {
      return EYES_EYES___BORED_BLUE_EYES;
    } else if (assetNum == 6) {
      return EYES_EYES___BORED_BROWN_EYES;
    } else if (assetNum == 7) {
      return EYES_EYES___BORED_GREEN_EYES;
    } else if (assetNum == 8) {
      return EYES_EYES___DILATED_BLUE_EYES;
    } else if (assetNum == 9) {
      return EYES_EYES___DILATED_BROWN_EYES;
    } else if (assetNum == 10) {
      return EYES_EYES___DILATED_GREEN_EYES;
    } else if (assetNum == 11) {
      return EYES_EYES___NEUTRAL_BLUE_EYES;
    } else if (assetNum == 12) {
      return EYES_EYES___NEUTRAL_BROWN_EYES;
    } else if (assetNum == 13) {
      return EYES_EYES___NEUTRAL_GREEN_EYES;
    } else if (assetNum == 14) {
      return EYES_EYES___SQUARE_BLUE_EYES;
    } else if (assetNum == 15) {
      return EYES_EYES___SQUARE_BROWN_EYES;
    } else if (assetNum == 16) {
      return EYES_EYES___SQUARE_GREEN_EYES;
    } else if (assetNum == 17) {
      return EYES_EYES___SURPRISED_BLUE_EYES;
    } else if (assetNum == 18) {
      return EYES_EYES___SURPRISED_BROWN_EYES;
    } else if (assetNum == 19) {
      return EYES_EYES___SURPRISED_GREEN_EYES;
    }
    return EYES_EYES___NEUTRAL_GREEN_EYES;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library ClothingB {
  using Strings for uint256;

  string constant CLOTHING_SHIRT___DUSTY_MAROON_MINERS_GARB =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFZy0tZDg4XU9PUUJCAAAAWykpYSoq////qxctYgAAAAh0Uk5T/////////wDeg71ZAAABHElEQVR42uyV227EIAxExxfI//9xx4aCVKEG2qeqEGWzkJ3jwQYWzy8bLuACLuACLuAPAPx14FuAO768ANy3Ae5mBsgcEbDJErEAMLooCaGKvoUY8QnfAXgLp6EShHlAmx7qO4D4PaWK3iRw7Cl9bQA8NJay9qURsmMLCwtABLMe/fM52g4gVDb00j2gPk9lJd4BkT56LX0SPQ2FhLrjoNWQkCIzh2xFdD0HrHIoqYhMdAp52jOyBQjLVNv0QAKahz0AIqLNCcCUjkiQ7SmUsfqyrLDSl4O/74VEFMwllNbbwMGBUuNujFwXxycSy17HDJjQc4BCtW2BvE4BGVo0M5CbE+eALOG45QenMlW9Evef6QIu4AL+B+BDgAEAZxpjq8iVcncAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___DUSTY_NAVY_MINERS_GARB =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFNThePkFdUVJbREVPAAAAMDNUMjVZ////rgUluAAAAAh0Uk5T/////////wDeg71ZAAABHElEQVR42uyV227EIAxExxfI//9xx4aCVKEG2qeqEGWzkJ3jwQYWzy8bLuACLuACLuAPAPx14FuAO768ANy3Ae5mBsgcEbDJErEAMLooCaGKvoUY8QnfAXgLp6EShHlAmx7qO4D4PaWK3iRw7Cl9bQA8NJay9qURsmMLCwtABLMe/fM52g4gVDb00j2gPk9lJd4BkT56LX0SPQ2FhLrjoNWQkCIzh2xFdD0HrHIoqYhMdAp52jOyBQjLVNv0QAKahz0AIqLNCcCUjkiQ7SmUsfqyrLDSl4O/74VEFMwllNbbwMGBUuNujFwXxycSy17HDJjQc4BCtW2BvE4BGVo0M5CbE+eALOG45QenMlW9Evef6QIu4AL+B+BDgAEAZxpjq8iVcncAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___GRASS_SKIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFd6N5bpZwAAAA////lmA8jwAAAAR0Uk5T////AEAqqfQAAACESURBVHja7NPbCoAgEATQmfH//zkXQxEU1noSpqUbNselDOXnBgMGDBgwYMCAAQMGrgIIYneXAVATjFgU2uUBoJZAP7RSFhCnHDukHKA+d9sHt+oBq/63pVwH6on5BKVfosrIjumV/4xiDHH0Hg9ChyuRdVAxL1/101KWf2cDdwCPAAMAME0uEEJObu0AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___LEDERHOSEN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFd2A1aVUviW8+AAAARUVFnIFN6sU3////x3O6tgAAAAh0Uk5T/////////wDeg71ZAAAAhElEQVR42uzWwQrDMAwDUEt21///47ZJ2AZpIXEPY5uUiyD4QcCH2HozJkCAAAECBIwBb1fIAeibgA8AS0keWB48DtMAWYX8E1iiPfhmIKJv4wDMIqzlaJgD9iVkBFtKwwTgYA8QPg7YWf4WwKulALg/5yeAJtQZr+1iXv8DAb8CbAIMAKlkaHxLDpaNAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___MAGICIAN_UNIFORM_WITH_BLUE_CAPE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFAAAANTU1UGv/////QFbNQkJCzs7O////Ekul9gAAAAh0Uk5T/////////wDeg71ZAAAA90lEQVR42uzW2w6DIAwA0LbU+f9/PEBuxQlFkyUm7RMUeyyyOGF/GGCAAQYYYMALALh9YUojbu18Q4QVAHzg1gSGjB6AFA5juDzXAlCAFDAQYFCfhSbxFwCgE0RiBaACjJ7CNUB0CFG53QF0O1AAMIlVAPEh8MoO3Kf9+ZUOYvLj1O+JfXZnLVA6WH6lgbKFUx4lUE9BLI8AvjqLkGcN4KMK7SisTAFMQCoUA2aiOcAZ2Mu+88DXKwB/UQLqWhqoAeLfJ0ZqgKjMuWL8FIgLiGMAOyA8eAHQGPD1x79ZWyTxGdC1KBJhctrD4gfG6Q72kWVAjK8AAwCK/V6NGr5TOAAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___MAGICIAN_UNIFORM_WITH_RED_CAPE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF////AAAAzUBIzs7O/1BZ5eXl////InmUiQAAAAd0Uk5T////////ABpLA0YAAAEDSURBVHja7NbRDoMgDAXQFgr//8kDCkhhQpnJEhP6BOg9FueM4B8WHOAABzjAAV4A4HJhDqC1tp2HKe4ACABWVFhAPRDzsZDDdaoFSgAwF0wEmOSL0Mz/AjTnsyDmOwBVYHYX7gEiFpLycwcgd6ABZGAo3AXSM/gEeGUHVjx+tQNetah+I/WX3n6l9R3sAuPutQBK4PoVbl6NI0DfG2CBNEAo70rKXSMfjywBZMDnoPPZcmFEZMwaIAY46MQg5BVAOImBEHReDNSAoRwsi3lg1IAxdZ67KQ08AtIBxDmAHRBvvADMHAh5/te1IYmvgK5FsRAnwx42PzCGK5yPrAOk+ggwAPeDURokxlaxAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___NAKEY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___NODE_OPERATORS_VEST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/40Szs7O9f+I////uL3xVwAAAAR0Uk5T////AEAqqfQAAABwSURBVHja7NXRCsAgCAXQq/3/P08XtMVgmIPcw71PRnQQfQjtY0CAAAECBAhEAKiI9tIr5ADMVQVg1ygGPATKAFW9ADssA+KvRkQSwJz9wNn3SGIGNrtbsLwFPLIZAKLCywxCDfBjIUCAwI+AQ4ABAJbLLS7e3N1BAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___ORANGE_INFLATABLE_WATER_WINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF3H4xUGv/xnErS2LeAAAA////zib4ZAAAAAZ0Uk5T//////8As7+kvwAAAHJJREFUeNrs08EKgDAMA9Atxv//ZYV1tFaxB/EyEnYK7YMN1vaPaQIECBAgQMDqAN/GWQNsI0hzFlbA3E+Ct/wZOPe7nQRYjSxkoHtiH+oC2DyxD3UBYN4VlyuEmsUjAg/7QwDu+/pMAgQIECBgNeAQYAAqtE1Z1OYJ4QAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___ORANGE_PRISON_UNIFORM =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF234x3H4xxnErAAAA////////5Dpp5wAAAAZ0Uk5T//////8As7+kvwAAARFJREFUeNrs1ssSgyAMBdDkhv7/LzdAEDqmvJyuShYITnOMFlB6PQw6wAEOcIAD/AEgIoMTXUCEYrAGYsNp6BMeYOlJAFPMN2IOEPs5U6nATrgCeflcSwDXAlxhDqAFIOaz5WuDZhBbmQGaKyoQJAQpw1mgGmAJIqHc0kIFyEetQAsIOpy8BSF7higO1SM7j/EbAPoEUmcKsGnzceUGwLiCNHfhAen8EIDFDbD4OVDiDizuSLDZ9BRg8C5gawhcVtUagLgK44yyo65rrOyJKNtA3hDTvnj/A3oA572U21gB2Is9AA8BoOnOA5egSdIvYATI1ccOgApgB8AFuOtw9HovSXmBb34fyNWcb6QDdOMtwAAwBkOSOdCqnAAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___PINK_TUTU =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6Jr/yqLVAAAA////nUtfkwAAAAR0Uk5T////AEAqqfQAAAB1SURBVHja7NPbDoAgDAPQrv7/P3vFjDiSqk+aEnDhYaeRAKaXAwYMGDBgwIABAwYMfAoIIEY7BUBgbWoFY6EE2LpPYCtUAabYNGsBVf8ley8ARaDPTYvqL1TA8qF8iIyu8YjnzYuUgcc3kaxz/RoN/A6YBRgA8LsuBJvLa3cAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___PINK_AND_TEAL_DEFI_LENDING_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRFTt7x6Jr/qYK1acfT////Td7x////zF+RrAAAAAd0Uk5T////////ABpLA0YAAACTSURBVHja7NXLCoUwDATQyUP//5OtpdyqCyEJKHInuyzmkD5osRYLBAgQIEDgHwAVvWkfAU6R1kSB9QqEN9FkhlQyAGTM3VaTA7DntMeTAORQYQDognsJQIv7ywBKgO81hAywtAGAAoAOoAD4byfrgCZPAeM+xQG7AtH3wM6CJoApmGkc6MQs5c9EgACBDwCbAAMA7P1aN3IM5KEAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_BEAR_LOVE_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZAAAA6Jr/zUBI////////Xe6vrQAAAAZ0Uk5T//////8As7+kvwAAAL1JREFUeNrs1eEKgzAMBOCk6d7/lZdcW+dYRBP3Y4MEQQXvw+qJ9Lg5VEABBRRQwO8DbHN4egowk83uKhuf8IARd4avAYd5V6BI3hMolHcEiuU/ha8DmyDUdOwIe7m6hPXWLa/lUQE7FeStGedVHsCc1iT8LdidayOxtSTAC+A8cGcJeHrcOwBKAkj3LAChd+RzAM2nYHXKASjhqGMYmNVdeS1iFNiEmY8D8voCReIAiN3Ur62AAgr4A+ApwABAkkgVO3f5jwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_BEAR_MARKET_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZzUBIAAAAmzIxUf9a////2KNKwgAAAAZ0Uk5T//////8As7+kvwAAAJtJREFUeNrs1VEOQDAQBNCdlvtfmS0VjS22/UDMfEgk5qWrFTJ2RggQIECAwPuBoKneXgIhiGb3lMYmLGCpGwn3gGrfFMTTtwRx9Q1BfP2jcALEJmATUAq4O0LedaQlDPN1WAUUJ+P6KC9DqJEWAve3kN9DJ6AD9AF5O54FVPgjACkFwAsUQkQDsBPQACRiSwR/bQQIEPgAMAkwAPh8R1rI3W1LAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_BULL_MARKET_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZzUBIAAAAUf9amzIx////0InoVwAAAAZ0Uk5T//////8As7+kvwAAAJxJREFUeNrs1esKgCAMhuFN6/5vOVQ8L3Taj4RvEKHwPlQU0b05BAAAAAAA/g8YN6/LIWAMuckb1i1lQgJCXo4NJzMH9H0EJIFm+gQIAql6QaCJvgQ64XMgCVz3PHsLfq/uwwUwV2/G+FXOcejV30Lsrx3AbgKuJn8sA3lWgLJffognA9wCrAW46fUAV7ka8EQx+LUBAADgAOARYAAlv0dYQnwcWwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_DRESS_WITH_WHITE_DOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIAAAA////////n3wz5QAAAAV0Uk5T/////wD7tg5TAAAAy0lEQVR42uyWgQ6DIAxEr+f+/5snKKEUgtWFJVvaIKSVPq6AiXh9aAhAAAIQgAAE4GsA+Of8KQDKngCwQbUnALgkLAXoGu4DAJ+ElYDmFPCDJWzw3aRlCgAnAc4K7gIAr4RBmDVHDIMOAJkUyy5aUhMUN/fkBYDMywrKIFpJ8i0CbXpNroDq5MEg0KRn1YAqAqOIRkDtnaBZS/s2xBGgvLx89o7DEopEUXLFBI/G8SYyWye3Wf6YM71IJ8YC+tT5t8DO4g8lABN7CzAA6/03ZRYRDFwAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_DRESS_WITH_WHITE_LACE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIAAAA////////n3wz5QAAAAV0Uk5T/////wD7tg5TAAAAx0lEQVR42uzWiw7CIAwF0Nvq/3+zsldfyEgXXWKKYwaye+iYJsPzYkMBBRRQQAEF/AzA/DV/CuAhnwyg8wPhM2DyuKMCXKwA0AKQAlQ+CUg+Cxz5NLDn8wDuAoBJ4VsAMCt0plky5AyeAJj3JLWDFPQ+M58ALU4qb4Bl7AnYuIQFkMHy5QiYuM1vPc5oAmrvCGYtPfZT3AMI6BUQe6uhewt2URjw2FByjxNmD1sL5Zrl12uGP6SN8UCMjv8LHFq9oRQwaC8BBgC4cTc9RVw6OQAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_DRESS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ3ktTAAAA901W////rqJ+JAAAAAV0Uk5T/////wD7tg5TAAAAkklEQVR42uzVwQrEIAxF0ZvY///misN0LE0hWkrL8LIJaN5BdCHLxUKAAAECBAjIAYxOvQ/47bE8BbDvw3fAJ1mbzQD0ZVcBHgAofb4wCRS+fRyg1Grh1ieA3CX8MQBJ4S4AskK47FHezLPAST4WGMiHwhHwOhimYyE6gXsbPqbds6/QBq2rbVG/swABdwGrAAMAEJk6iXr20NwAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_ETH_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIuTpBAAAA////fW8e6gAAAAV0Uk5T/////wD7tg5TAAAArklEQVR42uzV2wrDIBAE0JnY///mZtW22phuNgbawuxDQHAO3pbgNlkQIECAAAG/DySr3aELpASrZpbVmBgBJT6odAzYzQ8FOPmFjgAnv9AR8Hn9G2AjwFnACjAEPAWWvAGsw0NbeNw60QPI38hTrvkMrFmGe+EKoD3Ekyso1zizBXuJE1swAfUav3IGFwCvXggDfGtnMgr0LcQTALt4GMhEU/q1CRAg4A+AuwADAKHIOZyruYN8AAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_FANNY_PACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ////3ktT5eXl////yoEvZAAAAAV0Uk5T/////wD7tg5TAAAAS0lEQVR42uzSsQoAIAgAUbP+/5sTxXYNnO42hx4iyflMAAAAAAAAAAAAAOaA5UmmMZcB7QPb01fM9RvkAv0j2mOLjwQAADADXAEGALEnPyE1LjVAAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_HOOLA_HOOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAA/1BZ////6Q/r/QAAAAN0Uk5T//8A18oNQQAAAHxJREFUeNrs08sOgCAMRNFb//+j1SIRjbVNiCvHHaE9Di+WyQ8BAgQIECBAgAABfwCYawDLAIMYwCxPcKvhMkdhS7aUxEBp20LAI5D9n3gJvsDdIGz2grdTaSWOjEwbHzPZuffSzlzHxZs4tj0lKt68M4GeswAB3wOrAAMAE1AfEcd7K6MAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_HOOT_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZuTpBzUBIAAAA////v/zfjgAAAAV0Uk5T/////wD7tg5TAAAAlUlEQVR42uzV6QqAIBAE4HXs/Z+5tAOPFd0KLJixfgTN16GRLA8jBAgQIEDg+4APaR52Ae8lJDkrRCc0YK8r8WNAs68KYulrgpj6iiC2fi28DlwC8h5GH+GcdZRXBrKV0V/KTrbhrh3mbyECx9i2GYCbfgfJS7wFlLP4PwDVQrQCKPp2AFndDEQiCX9tBAgQ+AGwCjAAvKk5Zh18qpkAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_JESTERS_COLLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIAAAA6sU3////lA/GAwAAAAV0Uk5T/////wD7tg5TAAAAgElEQVR42uzT2wrAIAwD0Cb1/7953hCcbqvsNYUhBnIEcZZ+jgkQIECAgA+AjGVPAG0TmzEK5P4qlIwxoPbvQssYAXp/IkbEI2AzIQBmwNotGRi6RCB/tYJRNbQ8BHiqAFJ3xs5PXmI/Dm3dHv4O+Ly6fmcBAgQIECBAQHQuAQYAMAI9ysAZ6R4AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_KNIT_SWEATER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF/1BZ////uTpB3ktT6sU3bpZwAAAA////6RWwuQAAAAh0Uk5T/////////wDeg71ZAAAAt0lEQVR42uyVSw7DMAhEx8El979x1cSOYgMxqLsWZmWkefJAPti/LCQgAQlIQAL+AMC87jwAmAs+6ufzpCM0AKPoYh/A9KsEKP6XKWIPYIMpD+DJrxEQSaBlkIA2LxrnR63ruUE9RLXcRa27BFwJaPBXsjLAl8DOACuBmL+RQQB6gnmDLYPjBkcRzU8xne0l4KpxhqWGPyiTv4QB8xaiAPkWBAHCv8UA6Mu4Vf5YEpCABPw84C3AAJMLZQNVCsV6AAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_LEG_WARMERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZ3ktTAAAA////hP6nfQAAAAR0Uk5T////AEAqqfQAAABeSURBVHja7NLBCgAhCEVRn/P//zwpFszSghbDdfUQPFRmz2EZAAAAAAAAAAAAAADAXcBnW+5asQVk3yyAyj1gTEXFUGU1AZ0BefwPoI0tqK49X6G/Ri2Ar/x34BVgAAYBLzkR21hbAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_OVERALLS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ3ktTAAAAzs7O////A2UrSAAAAAV0Uk5T/////wD7tg5TAAAApElEQVR42uzW6wrDIAwF4HNi3/+Z11nj6GWRpJQxzPkVaPNBaxSx3AwSSCCBBBKYBID3rdMjnKsEpgMIUPu18gGlbH1AKQGAaxtalHICpAJrFQH2CQFsiQPtC/4T4BGgF8ABgA9oM7BjHID0GdJFrKU4AFzEA+AyvwEYAj4CRez+IVDPI+MfDoB3k5ir+H0v9CYxJ9k4E+sQ9anMK04CzwIvAQYATmg55uy4GY8AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_PINK_UNICORN_DEX_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZzUBI23z46Jr//1Nc////nSBtUwAAAAZ0Uk5T//////8As7+kvwAAAJ9JREFUeNrs1cEKwzAMA1DZXv7/l5c6KW16GFiBwZh8KMlBDzspLdpmQYAAAQIE/ANgsA/brwBLpG+qQHsCrQ5cIXtxwOzbckkBB2FzUQZ6yB1XMcAh+BaQQsRGB/mIJKgzAAJnCwRwju9kBx5zijEDA8S4SLaDnnbEEOhrHAD9JiJvgQQMaxnxQVnzdcDu6TqQxK30ZxIgQMAPAG8BBgCraErGJlXB6QAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_PONCHO =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/8rN/6uwAAAA/9PV////SH0e4QAAAAV0Uk5T/////wD7tg5TAAAAxUlEQVR42uzWUQ6DIBAE0Jmx9z9z1aplFWTBmrTNzpdA9kUBUTwuBgEEEEAAAXw/INV7TgAJ2A2MHXkiB0zlMMTSIR+w1o/h1Oa7LQ+Q1M8C07bqgKkfBdq2WoF9qkBaT49wH0ALsAdIBS8glICSgJMbMJe/AwxcslVwnYRXBlVWYc0e2Ea8J5JZBgLNR9pVwEwdgaJwF4AjAD+gdPXSPaCmQ/V4Cz0A0Q+YDcxeAJ8CGh9he6NsBvm/jfnEH0oAfww8BRgAtJ80z7xqP48AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_PORTAL_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIuTpBAAAA////fW8e6gAAAAV0Uk5T/////wD7tg5TAAAAv0lEQVR42uzV7Q6DMAgFUCi+/zNPPqzTYC34RxNoolmye4oOJywPCwoooIACCng/QFyXH28BIuD6+xaXT3iAxp2iOeAy7woQyXsChPKOAKM8ag2FEYCn8xTQBeScNYA7QjM/457fGhDrMBn3o9xbUAzDz4IF7djSAEJb1wNA0utKAhxXIg5suzfJZwDb3I4JQIUmLWRuYt9fewgDMoSyud4GxCigY2xXwBMZBvD0WIf/1vFQ9WoroIACPgD8BBgAbXU5ezvoUlYAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_PROOF_OF_STAKE_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIuTpBAAAA////fW8e6gAAAAV0Uk5T/////wD7tg5TAAAAoUlEQVR42uzV4QqDMAwE4LvU939ml24VqxFN3Y/JLqIgeF+jrRTTzYIAAQIECPh9oHgd3p4CpcBr9ZRXTETAOx5UuQYc5kMBmXwkIJUPBOTye+HrwCKwz/HqK7RZ53ZkslsZ50sZMLN61gvT/8IrtxzewAhgn7h3MdYB2vg2DrTvMAL0k/CHAHcLMQtwk88D7OJpoBKr0tYmQICABwCzAAMAOEc5SWQl0jUAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_PROOF_OF_WORK_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIuTpBAAAA////fW8e6gAAAAV0Uk5T/////wD7tg5TAAAAmklEQVR42uzVUQ5AMBAE0Jmt+5+ZaojWCls+iJnGh8S8VlqB4WYgQIAAAQLeD6Scw9tTICXkbJ7K8QkPKHUn6Rpw2HcFRPqegFDfERDr74XHgVVg3ePVV1h2ne3MZHUyzo8yzKxcU9HA8LcAW0cvYHeBubiMXmBaRVlEB9Bswg8B7g5iFGDTjwOs6mFgJjbRr02AAAEfAEYBBgBGbTlL5pGu5gAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_PUFFY_VEST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ3ktTzUBIAAAA/////8GG7wAAAAV0Uk5T/////wD7tg5TAAAAqElEQVR42uzV4QrDIAwE4Fzi+z/z2lo37YblImMMLn+KQj5iatDKYpgAAQIECPgDIG435kCYoV/DLBhgyx8E7OtgKvgEFBZ4CUd+AmhCzc8AVTjzOaAT5vl3gKHlZwHLAu4j4E5X4DVQP+PFzByBBcoFAD3OrQmYt2BWQd+DRAXLR/h5D3DpAf0bsXgP8D4LIIAAnlPYmrhFcO8ChtDbKECAgO8DDwEGAGFxOu854dqRAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_REKT_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZuTpBzUBIAAAA////v/zfjgAAAAV0Uk5T/////wD7tg5TAAAArklEQVR42uzVUQ6EIAwE0HbY+5/ZILsgyBaoH2oyjTExkWc7YpTPxRICBAgQIPB8IMT6ezkEQpBYh7ti9YkekJZ3KswBeb2msgWxn6/7YQli998CZ0GM9bF91UEOMhvgLJAF1ClidoTfW0dJIA0BVDtjvJUbAMvfQjO6Eygh+DvQSx1I3gneEfL5rhBLDv4Mvq9hGUDbAVYB1BE4AFTLl4GdOBR/bQQIEHgBsAkwAO/eOWmD0pTuAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_RASPBERRY_PI_NODE_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF/1BZzUBIXRpwhy6hV9RdR65N/1Nc////iFJznwAAAAh0Uk5T/////////wDeg71ZAAAAl0lEQVR42uzVwQoDIQwE0EzU+v9/3MYKWg8FR2hZdsIiepinqKxWD8sECBAgQMAdABi+DH8CfEReg12grkDdB0YIDw7o60brUkAQ6J1twJaigJxHSwElsjkXGgih50nAPCU/2APzAJwHWryv4T/AO+6JB5K3j7+JHvM7dZWxHCOIH8pcIADM6X2gEVPpZRIgQMAFgKcAAwAYqWiyvHTVtwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZAAAAzUBI////3ktT////mG+gsQAAAAZ0Uk5T//////8As7+kvwAAAJ9JREFUeNrslNsOgyAQRGeG7f//chHshXZtIMY+zQY38sA5Iyq4nSwYYIABBhhggAEGGGDAPwHgOC+xCtjqfbIIQAGIsS8ACOG7xFkAM7/AlIADfx+7+tEzArL1dSQZkGZIANqlwhhFiODcI3Rb7WMWBSc3UXgGeGWJzH/0Gtl2vdvV7kOFXPiQyE2pam2tXvnyHz8TP8oHigGXAu4CDADJ9kuCLqH6NAAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_SKIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIAAAA3ktT////sXbtHwAAAAV0Uk5T/////wD7tg5TAAAAkUlEQVR42uzUSw6AIAwE0Gnr/c8siAHE1kCMrqZRJDHzil9sLwsECBAgQIAAAQIECPwJYDgBWwbQjDxfBHAvWwAU4giis4Cbl0BAkC9bzcYCwnwz2ugIDiDogbYUgZnOXQKuRj2YTt5EwSVcpub1jx5jt4gTstReF14k1dxSUtdjSLsff/iYdCj+UAh8CuwCDACVWzxGrh3vrwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_STRIPED_NECKTIE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZuTpB////3AVB+QAAAAN0Uk5T//8A18oNQQAAAElJREFUeNrs1MEJADAIBMG99F900oGPAyGw/h08QTllISAgICAgsAgQ0k0w9Y9A6IBQRnj9tEvECEaoI9S34EsTEBAQ+Au4AgwAeycfqdWs1wcAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_SUIT_JACKET_WITH_GOLD_TIE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF/1BZzUBI////AAAA6sU38uOpuTpB////Z6itygAAAAh0Uk5T/////////wDeg71ZAAAA1ElEQVR42uzV2w6EIAwE0E6p6///8XJRAsqt7OO2L0SSORkxQTp/HDLAAAMMMOAPAOfmOwPAOQrDLMchcjDHxzbRAlI8CkU+EGtAznuAQz4DLYEG+VihKNAUJkA4AyVQ5onCGVQbTgn4vAeEtwFKedkAcL8Dffzcj3MgF0DdBL0KNC7wFrSAb19tYBFApwHmAK55NbhmCrBwnGeDtCvsVi+UZwP1jfRsoAXodQabQP4IWgBUfU+ogTMlESn086Nr3RNIaz8++S+gWuzfaIABBoznK8AAFZ1h2q7B4g8AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBIAAAA/1Nc////dXX3mQAAAAV0Uk5T/////wD7tg5TAAAAeUlEQVR42uzVwQrAIAwD0Kbr/3/z3JBtKmyk7iKkp+bQh4JUi8kyAQIECBCwAODuL/EbcBieuUTnTjAC5BXQjJTAAtEDwQP3ELYcUM+Ns00BB4HaJIGreMC6EiDgD4B+iegBzAFAYiM14/xGCjSlr02AAAELALsAAwAOWzttt1K3WAAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_TOGA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZ3ktTAAAA////hP6nfQAAAAR0Uk5T////AEAqqfQAAACXSURBVHja7NXLDoAgDETRW/z/f1ZRHguD0FkZy4KwmRNoKLCJgwACCCCAAH4JJA0wLCmAgSk7GOSnAI4DoACj/AyACOS8AJxpGUAA7rwboADOe1DzToA2XAAigAj0aQ9AK6AL6PN5tfoeYNYMB2BWky/CI5C6HHUnz6/iHHBNabGI5QTjdmKij9zd2G5SfK4BBPABYBdgAJjYLNcRmxqrAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_TUBE_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRF/1BZzUBI////gty5ygAAAAN0Uk5T//8A18oNQQAAAEVJREFUeNrs1CEOACAMQ9GW+x+aBMUyA5lq8r+q2ZPTGiYAAAAAAIBHwG0AxAHWXSLgCvgfqPcTwCceCgAAAABABrAFGADpGR9PORU0BwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___RED_VEST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZ3ktTAAAA////6sU3////v5SXtwAAAAZ0Uk5T//////8As7+kvwAAAKZJREFUeNrs1eEKgzAMBOBLur7/Ky86GKmoJVf3Y3BF0CL3kVaN6IsDAgQIECDgDwB3v5nOAQeGOzH1CrDlYUMe5pUKzoDaHgyRm/zvAEshMMAuZKAzwEeIcyMAJKC1RgKbsOdpIIg4YvDAy8BtIlIJTwC2ugTj3oOVCh4DyCX4oYDLfjID7LubNSDlZwKm3xLbDw4dqf4Uutn5tX6uAgQIuBhvAQYAPXNKJwyo5N0AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___RED_WAGMI_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZuTpBzUBIAAAA////v/zfjgAAAAV0Uk5T/////wD7tg5TAAAAqElEQVR42uzVUQqEMAwE0Enq/c+81qhra0QTBXdh4kcRnFfbRsRws0CAAAECBH4fKLUOb0+BUlBr81Qtn/AAiztVrgGHeVdAJO8JCOUdAbH8XngcWAVtc3p1Ccupaz+zatMZ560MGQMCGwQa/hbG5PfCDUBsTABT1ubPLaHbwxRg7yCSBeYNFLwIYD6HBKC7RowC2uXjgDbxMDARm+KvjQABAn8AfAQYAJGeOWKplSgTAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_WITH_PINK_AND_GREEN_DRESS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ4YGAiP/EAAAA////ujlt4QAAAAV0Uk5T/////wD7tg5TAAABF0lEQVR42uzW4W7DIAwE4PN57//MA84mI01pwqT9mEBViarwYYxBxdcvGzawgQ1sYAMb+DMA99/5pwABGFi/sAKUYewAlwCrQA2DkxA+AG0VqwDr9GyALQBlbAL1iYuArQMswwh9sAQYNb1SuQQoAW0B77dhAsQeNsCeAy36yOQKELEfgD0GKAAK5CnQTpHSnwBuAw6dIRFKJrQivwG4MwpQZaSHpNw/AO7Q+CwhOzTl5EzgPHsv3gCYncIoykjgNLsNC/gxuO8JbSAw5I5H5HEMiX4kFZXq0y+BvMJyzVlGfSvzesAlUENA33nmZRhbOgp+nURvLRGtPvLJ/FXvTAspmMhedKV/GTo/C/7S9j+UDUzatwADACJGOA0u6TEiAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_WITH_WHITE_APRON =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZzUBI////AAAA////kusZyQAAAAV0Uk5T/////wD7tg5TAAAAb0lEQVR42uzW0QqAIAyF4X/V+z9zKgnpVW6RCeeI7MZ9iKDIEQwCBAgQIEDAQ4ChRQJ+CRj3rAi0/dj3wEYzHDvohOlngAOwHGoZBlInZV5lBkDZei0eIHaIAt4Aopep68fzKqfsKfpgCFgBOAUYAEoBOwJog1HxAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___RED_WITH_WHITE_STRIPES_SOCCER_JERSEY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ////zUBIAAAA////IGP2JgAAAAV0Uk5T/////wD7tg5TAAAAoUlEQVR42uzVgQrDIAwE0FzS///mLWnpRM2mtbAN7oSCaJ9RLJVtMUKAAAECBH4fME/a/QiYCUSKoWcX0id6gMX8IyiajQGGDICNACY50KlBkvUDAGqgrUGS9RHvt0BTwxsAl4BzC+qPF6CjW/D4TG3OwImZq1wBOv0t3AAgTnGpguIiEfgGoDWgs4AuA1oAOg8E4cHe+GsjQIDAHwAPAQYAFo45yJHUSk0AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___TAN_CARGO_SHORTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRFnIFNiW8+AAAA5eXlkXhIzs7O////c7ZgkwAAAAd0Uk5T////////ABpLA0YAAACWSURBVHja7NRLDoMwDARQe+xy/yPXIQlEKh+nlSoWE7EwEfNiGYEsPy4hQIAAAQIECBAgQOCfgHz9YN9Xubi9ByQS5aqr1hMAVFtO5NULVWQByHD60IUgC+gxoGkg2v0EYgvpGewd+NAB8m8B2oIO9Op4hmdAPxh1pJF3nwEWM1tTBfCixcbst2DWQlvB/wGBBwNvAQYAwvNbbtiELhUAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___VAMPIRE_BAT_WINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFRUVFAAAANTU1////uJgBVgAAAAR0Uk5T////AEAqqfQAAAD1SURBVHja7NZbDoQgDAXQW9z/nseCBugLyDiJmeAPiaXHAoLi+PLCBjawgd8ARHF/FRcApRQKOo5jRTCirwMIIwDhHBAQCZwPIUDmj4FegMw/AU848zPQCVD5iAAoASrfHUQpQArQ+TwIC7gGIIQeKMHkTWKqD1FAkx9sUGjBAMLNGwLDAtoSBDBZgFEClgowSngImFsDcx2wVoAu4RlgfgR6DC8CrvxJoE7CvwAs3ECK81MFxItUI+HzHYC/SM36YLSVuZG7kUmaA0o/EidSvsMOhz2ACHc/daSVO7khD6C+nzjWm8b7Msl++z9xAxt4E/ARYAD+xijnidMGgQAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___WHITE_TUXEDO =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF////AAAA5eXlysrK8vLy////254sTwAAAAZ0Uk5T//////8As7+kvwAAAMBJREFUeNrsldsOxCAIRGFs//+Xt6TiramKzW6aLL5ICXMYGyO0P1zkAAc4wAEO+AMA8zjTATCTrLhR+pwFRN0hqbYjmAOkelFK9yIxA8jlIpdVJn4AKMtPQp1YAjAvA86f+BRgOkKq32rhdkf4OiCERUBjICesAHUwD+BwuX7FpQzMsw9K68D8IrUOrABqHdAiYGiBBvrsgEwAqAo5sh0hCqEswDwXoF1x374/WKAydPTdyYRL4NPZAQ54MeAjwABY+ETG7RBcCQAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___WHITE_AND_RED_STRIPED_BIB =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/////1BZ5eXl////FQoEIgAAAAR0Uk5T////AEAqqfQAAABLSURBVHja7NMxEgAgDAJBxP//2UYzloqWR53ZUCTqjxEAAAAAAMAZoNup/0CrhMAWGoQNXBXk7BK99js9Zc/wzgAAAAAAAOcZAgwAumcvAQiUdHgAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___WHITE_WITH_RED_DRESS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////uTpBAAAA////6oRj4QAAAAR0Uk5T////AEAqqfQAAAB9SURBVHja7NXhCoAgEAPg3Xz/dy6SSkNpElHC5g/l5D4EQZEeBgYMGDBgwIAGRHM5FXC2RfoIAOp5FABy5z6PAqgyIwBogoE/A4AovAUAqgC1vUe0iuwB1AAG8iiTK1SAo781KJ2AHWPdUG+BvChbYfRNZBF/7wYM3GURYAAQMCu/Csc6bQAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___WHITE_WITH_RED_STRIPES_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////uTpB5eXl////rZgQdQAAAAR0Uk5T////AEAqqfQAAABfSURBVHja7NVBCoAwDAXRSXr/O7tQkHShtCIinb8KhDzIJqE9DAICAgICKwBQOgQfAJT5UaD1QJsAOOtJYCfgYoM74EgQAgKLAvQAvwMyK5A5fNazxNcmICDwPrAJMADHnix+v0+20gAAAABJRU5ErkJggg==";

  // duplicate this in both clothingA & B
  string constant NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 54) {
      return CLOTHING_SHIRT___DUSTY_MAROON_MINERS_GARB;
    } else if (assetNum == 55) {
      return CLOTHING_SHIRT___DUSTY_NAVY_MINERS_GARB;
    } else if (assetNum == 56) {
      return CLOTHING_SHIRT___GRASS_SKIRT;
    } else if (assetNum == 57) {
      return CLOTHING_SHIRT___LEDERHOSEN;
    } else if (assetNum == 58) {
      return CLOTHING_SHIRT___MAGICIAN_UNIFORM_WITH_BLUE_CAPE;
    } else if (assetNum == 59) {
      return CLOTHING_SHIRT___MAGICIAN_UNIFORM_WITH_RED_CAPE;
    } else if (assetNum == 60) {
      return CLOTHING_SHIRT___NAKEY;
    } else if (assetNum == 61) {
      return CLOTHING_SHIRT___NODE_OPERATORS_VEST;
    } else if (assetNum == 62) {
      return CLOTHING_SHIRT___ORANGE_INFLATABLE_WATER_WINGS;
    } else if (assetNum == 63) {
      return CLOTHING_SHIRT___ORANGE_PRISON_UNIFORM;
    } else if (assetNum == 64) {
      return CLOTHING_SHIRT___PINK_TUTU;
    } else if (assetNum == 65) {
      return CLOTHING_SHIRT___PINK_AND_TEAL_DEFI_LENDING_TANKTOP;
    } else if (assetNum == 66) {
      return CLOTHING_SHIRT___RED_BEAR_LOVE_SHIRT;
    } else if (assetNum == 67) {
      return CLOTHING_SHIRT___RED_BEAR_MARKET_SHIRT;
    } else if (assetNum == 68) {
      return CLOTHING_SHIRT___RED_BULL_MARKET_SHIRT;
    } else if (assetNum == 69) {
      return CLOTHING_SHIRT___RED_DRESS_WITH_WHITE_DOTS;
    } else if (assetNum == 70) {
      return CLOTHING_SHIRT___RED_DRESS_WITH_WHITE_LACE;
    } else if (assetNum == 71) {
      return CLOTHING_SHIRT___RED_DRESS;
    } else if (assetNum == 72) {
      return CLOTHING_SHIRT___RED_ETH_SHIRT;
    } else if (assetNum == 73) {
      return CLOTHING_SHIRT___RED_FANNY_PACK;
    } else if (assetNum == 74) {
      return CLOTHING_SHIRT___RED_HOOLA_HOOP;
    } else if (assetNum == 75) {
      return CLOTHING_SHIRT___RED_HOOT_SHIRT;
    } else if (assetNum == 76) {
      return CLOTHING_SHIRT___RED_JESTERS_COLLAR;
    } else if (assetNum == 77) {
      return CLOTHING_SHIRT___RED_KNIT_SWEATER;
    } else if (assetNum == 78) {
      return CLOTHING_SHIRT___RED_LEG_WARMERS;
    } else if (assetNum == 79) {
      return CLOTHING_SHIRT___RED_OVERALLS;
    } else if (assetNum == 80) {
      return CLOTHING_SHIRT___RED_PINK_UNICORN_DEX_TANKTOP;
    } else if (assetNum == 81) {
      return CLOTHING_SHIRT___RED_PONCHO;
    } else if (assetNum == 82) {
      return CLOTHING_SHIRT___RED_PORTAL_SHIRT;
    } else if (assetNum == 83) {
      return CLOTHING_SHIRT___RED_PROOF_OF_STAKE_SHIRT;
    } else if (assetNum == 84) {
      return CLOTHING_SHIRT___RED_PROOF_OF_WORK_SHIRT;
    } else if (assetNum == 85) {
      return CLOTHING_SHIRT___RED_PUFFY_VEST;
    } else if (assetNum == 86) {
      return CLOTHING_SHIRT___RED_REKT_SHIRT;
    } else if (assetNum == 87) {
      return CLOTHING_SHIRT___RED_RASPBERRY_PI_NODE_TANKTOP;
    } else if (assetNum == 88) {
      return CLOTHING_SHIRT___RED_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
    } else if (assetNum == 89) {
      return CLOTHING_SHIRT___RED_SKIRT;
    } else if (assetNum == 90) {
      return CLOTHING_SHIRT___RED_STRIPED_NECKTIE;
    } else if (assetNum == 91) {
      return CLOTHING_SHIRT___RED_SUIT_JACKET_WITH_GOLD_TIE;
    } else if (assetNum == 92) {
      return CLOTHING_SHIRT___RED_TANKTOP;
    } else if (assetNum == 93) {
      return CLOTHING_SHIRT___RED_TOGA;
    } else if (assetNum == 94) {
      return CLOTHING_SHIRT___RED_TUBE_TOP;
    } else if (assetNum == 95) {
      return CLOTHING_SHIRT___RED_VEST;
    } else if (assetNum == 96) {
      return CLOTHING_SHIRT___RED_WAGMI_SHIRT;
    } else if (assetNum == 97) {
      return CLOTHING_SHIRT___RED_WITH_PINK_AND_GREEN_DRESS;
    } else if (assetNum == 98) {
      return CLOTHING_SHIRT___RED_WITH_WHITE_APRON;
    } else if (assetNum == 99) {
      return CLOTHING_SHIRT___RED_WITH_WHITE_STRIPES_SOCCER_JERSEY;
    } else if (assetNum == 100) {
      return CLOTHING_SHIRT___TAN_CARGO_SHORTS;
    } else if (assetNum == 101) {
      return CLOTHING_SHIRT___VAMPIRE_BAT_WINGS;
    } else if (assetNum == 102) {
      return CLOTHING_SHIRT___WHITE_TUXEDO;
    } else if (assetNum == 103) {
      return CLOTHING_SHIRT___WHITE_AND_RED_STRIPED_BIB;
    } else if (assetNum == 104) {
      return CLOTHING_SHIRT___WHITE_WITH_RED_DRESS;
    } else if (assetNum == 105) {
      return CLOTHING_SHIRT___WHITE_WITH_RED_STRIPES_TANKTOP;
    }
    return NONE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library ClothingA {
  using Strings for uint256;
  string constant CLOTHING_CLOTHING___BLUE_ERC20_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/QFbN3v8AAAAA/+QA////Znr5FAAAAAZ0Uk5T//////8As7+kvwAAALZJREFUeNrs1YsOhSAIBmBAev9XTrCaOrSws51zNnDdtv6vi7Rge1kQQAABBBDA7wNJanh4C6QEUtVZUjZhASVuVHoGDPOmAJ68JcA4T0R50Z2JAOPra1bH7B5mAB2LC7gEBM5r1qGHDx/hnPUcYD7iLARi0xn3rdy9fnR/Cx8BqklcAqhMo07D6iN8HSB4B5RW0s0SwNJKpY38APZ9gF4Au7wfwCbuBpSoKn5tAQQQwB8AuwADACjoR71QLaovAAAAAElFTkSuQmCC";

  string constant CLOTHING_CLOTHING___BLUE_FOX_WALLET_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFUGv/QFbNyWojdj4aAAAA1b+yFhYW////s0sOyAAAAAh0Uk5T/////////wDeg71ZAAAAp0lEQVR42uzVywrEIAwF0CRG/f8/bqr2oQMz5M6iFBIKNYt7iGAt1T+LAggggAACeAGgql/a34Ay8b23Vn0TfALOLfAUscYL1BWofuAK3dceYMzNbQkBO8FjAQJn+QELifRweyNA6oJIQgET9ko4kHoeBeiYgEDAsqU9ggOjHgRyKRkHSChbkSAncTnJ/vtg/RQYuJGmuP9GqjxV/NoCCCCAFwCbAAMATJRopFHCgyYAAAAASUVORK5CYII=";

  string constant CLOTHING_CLOTHING___BLUE_GRADIENT_DIAMOND_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFUGv/QFbN/8hGAAAA1nfb73qd/5Nt////gNwLKgAAAAh0Uk5T/////////wDeg71ZAAAAq0lEQVR42uzV0Q6CMAyF4dPOzfd/Y23nkGEJtBqjSc8dxP8LxBlxfXNIIIEEEkjg94Ei2708BEqBbPUpmU1YQM+NlXPAbm8K8PSWAFdvCPD1r8LHgUUg4NLXWtPLc68wvvWpZ77foOlkHB/l3teqPTO5fwv6BFUA6REBIH1l7WMAnn0QwNJHAYw+DODRx4Gx7wO0BcgL0Kb3AzTlbkCJ1fKvLYEEEvgD4CbAAINIZIz+nTBKAAAAAElFTkSuQmCC";

  string constant CLOTHING_CLOTHING___BLUE_LINK_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/////QFbNAAAA////ElYvGQAAAAV0Uk5T/////wD7tg5TAAAAr0lEQVR42uzV2w6EIAwE0F72/79ZqYu2BijUF006DyQmzkkKGOH3MJBAAgkkkMD7AS7pProAM5Sot0raRAs46o3wHNDtNwVw+oiOAMM+SoYCOP3/0hdGQG0agWdHoL14SvI4N0I9dQILAJG5Gf5VvgG0/C3c9iAE6FOIAeoeBIFrjDBQEwBQth+PBeMAPgWEwPURSI5PjUCrANk9DABk6suAECr5a0sggQQ+AGwCDABRpjl7XdftpgAAAABJRU5ErkJggg==";

  string constant CLOTHING_CLOTHING___BLUE_WEB3_SAFE_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/BJp9QFbNAAAA////5DqGRQAAAAV0Uk5T/////wD7tg5TAAAAoklEQVR42uzV4QqAIAwE4Ln1/s8cS7JZy5xCFNz9qaD7yFxEy2QIAAAAAAB8HxDN7eUjIEIac5fGJzwg151IH3DbdwWK9D2BQn1HoGY/adpCE0jpKkjvErj0N4F7l7Dvuu1ngavJeB7lDNB+4PC3UAA9mQLmnqC8gxGg3oURwM7BGGAmcRA48j7AZ4CjAJ/6cYCrehjYCBP82gAAAPADYBVgAONaOYs9mUpXAAAAAElFTkSuQmCC";

  string constant CLOTHING_CLOTHING___RED_ERC20_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZzUBI3v8AAAAA/+QA////Zr8gVAAAAAZ0Uk5T//////8As7+kvwAAALZJREFUeNrs1YsOhSAIBmBAev9XTrCaOrSws51zNnDdtv6vi7Rge1kQQAABBBDA7wNJanh4C6QEUtVZUjZhASVuVHoGDPOmAJ68JcA4T0R50Z2JAOPra1bH7B5mAB2LC7gEBM5r1qGHDx/hnPUcYD7iLARi0xn3rdy9fnR/Cx8BqklcAqhMo07D6iN8HSB4B5RW0s0SwNJKpY38APZ9gF4Au7wfwCbuBpSoKn5tAQQQwB8AuwADACjoR71QLaovAAAAAElFTkSuQmCC";

  string constant CLOTHING_CLOTHING___RED_FOX_WALLET_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF/1BZzUBIyWojdj4aAAAA1b+yFhYW////eWUHuAAAAAh0Uk5T/////////wDeg71ZAAAAp0lEQVR42uzVywrEIAwF0CRG/f8/bqr2oQMz5M6iFBIKNYt7iGAt1T+LAggggAACeAGgql/a34Ay8b23Vn0TfALOLfAUscYL1BWofuAK3dceYMzNbQkBO8FjAQJn+QELifRweyNA6oJIQgET9ko4kHoeBeiYgEDAsqU9ggOjHgRyKRkHSChbkSAncTnJ/vtg/RQYuJGmuP9GqjxV/NoCCCCAFwCbAAMATJRopFHCgyYAAAAASUVORK5CYII=";

  string constant CLOTHING_CLOTHING___RED_GRADIENT_DIAMOND_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRF/1BZzUBI/8hGAAAA1nfb73qd/5Nt////SvICWgAAAAh0Uk5T/////////wDeg71ZAAAAq0lEQVR42uzV0Q6CMAyF4dPOzfd/Y23nkGEJtBqjSc8dxP8LxBlxfXNIIIEEEkjg94Ei2708BEqBbPUpmU1YQM+NlXPAbm8K8PSWAFdvCPD1r8LHgUUg4NLXWtPLc68wvvWpZ77foOlkHB/l3teqPTO5fwv6BFUA6REBIH1l7WMAnn0QwNJHAYw+DODRx4Gx7wO0BcgL0Kb3AzTlbkCJ1fKvLYEEEvgD4CbAAINIZIz+nTBKAAAAAElFTkSuQmCC";

  string constant CLOTHING_CLOTHING___RED_LINK_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZ////zUBIAAAA////IGP2JgAAAAV0Uk5T/////wD7tg5TAAAAr0lEQVR42uzV2w6EIAwE0F72/79ZqYu2BijUF006DyQmzkkKGOH3MJBAAgkkkMD7AS7pProAM5Sot0raRAs46o3wHNDtNwVw+oiOAMM+SoYCOP3/0hdGQG0agWdHoL14SvI4N0I9dQILAJG5Gf5VvgG0/C3c9iAE6FOIAeoeBIFrjDBQEwBQth+PBeMAPgWEwPURSI5PjUCrANk9DABk6suAECr5a0sggQQ+AGwCDABRpjl7XdftpgAAAABJRU5ErkJggg==";

  string constant CLOTHING_CLOTHING___RED_WEB3_SAFE_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZBJp9zUBIAAAA////1g9fegAAAAV0Uk5T/////wD7tg5TAAAAoklEQVR42uzV4QqAIAwE4Ln1/s8cS7JZy5xCFNz9qaD7yFxEy2QIAAAAAAB8HxDN7eUjIEIac5fGJzwg151IH3DbdwWK9D2BQn1HoGY/adpCE0jpKkjvErj0N4F7l7Dvuu1ngavJeB7lDNB+4PC3UAA9mQLmnqC8gxGg3oURwM7BGGAmcRA48j7AZ4CjAJ/6cYCrehjYCBP82gAAAPADYBVgAONaOYs9mUpXAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___ADAMS_LEAF =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFbpZw////ol6D2wAAAAJ0Uk5T/wDltzBKAAAARklEQVR42uzSwQkAMAgEwbX/pgM2YMiBn6z4UwcUqTAQEBAQEBAQEBAQ+BQgrTP0MPB0vgMdyQoxUNP81RF9ZQGBDeAIMACv4Q/oMKQQ5gAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLACK_BELT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFAAAA////pdmf3QAAAAJ0Uk5T/wDltzBKAAAAT0lEQVR42uzUMQoAIAxD0fT+l1YcRdohWBF+9j6aDlWYEQAAAAAAAAAAAEAfoGO+AnbLOeKcTgXVCyzEAOI5YFawjxhFgx6AhwJwHxgCDAAzUQ+aPiEm0gAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLACK_LEATHER_JACKET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFGRkZAAAAzs7O////QbMmzgAAAAR0Uk5T////AEAqqfQAAACQSURBVHja7NVLDoAgDARQptz/zpqS8FOgSJSYzKzQ2EfLAp1fjCNAgAABAj8AMHzRBQBxGv1EI4AZ0HIpAWkRN0AqzzsIhA2I5cGIK3EmAHn1WeTzR0wB0MwCKLdPZ9AQmgDKQ8TnAOoRYATKBq7ARXgXkD0dSA+QMYDFEapRMmD2RtoO8L9AgAABAg9yCDAAHAEqvf7vD8EAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLACK_TUXEDO =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAA////NTU1zs7O////OlAWfgAAAAV0Uk5T/////wD7tg5TAAAAnElEQVR42uzV3QqAIAwF4HOq93/msB8zi80pBMHZjSHta5pMLIMBAQIECBAgwAeQgkQ5BgAcwdvwTsDIT5np6xlAG4AruEUx8QkAVMJtog8gu4F9E0eB2BLgxOfANP2wAs58HJ/zUM5Ecz+oKwg3FG/tHvDcg07ALQFOfvEX+ioon4JdOWeZe2i19Zxm5Zv3AkIv6W4UIODvwCrAAJXUN44Ur7szAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLACK_AND_BLUE_STRIPED_BIB =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAUGv/////v7SHiAAAAAN0Uk5T//8A18oNQQAAAERJREFUeNrs0yESACAIBED0/4+2qU1F4l5mlgsQ/TMBAAAAAMAdEK9T9UCbSQJbNEg2WBUie4nn/b4RAAAAAIByYAgwACjmH2vCPwVJAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAA////zs7ORUVF////YpJ5pAAAAAV0Uk5T/////wD7tg5TAAAA2UlEQVR42uyW2xKDIAxEl6X//80Vq8idpY59adYXcCZHNwlRvG4KBjCAAQxggD8AAG7TuQtrYAWwh5eCDkBQER2kAtCVBkB8YqaOC2j++3lA00Aaw6CYBxGQit7T97OAhoMSsF0xD1AAnzc/LfjdAntJQLsHE0C2hQIYawaAG8cTU8BRu7IDeNzHtIzkVfmyHUh5Hkjn4FEAK60CqnP0YwvNFoI+0tiaBVwAuLsAfSQ+BaiO8aKFi0BgHD8tY7b8AlCudUDy1hg5GHze4/QIANovjgGeBbwFGACILzY2oNeE/QAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLACK_WITH_BLUE_DRESS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAOk65////oYUMIQAAAAN0Uk5T//8A18oNQQAAAHNJREFUeNrs1UEKwCAMRNGv9z90FyKtYHFCDW1hkkVEmLfIQqkPCwMGDBgwYEADyvT4K+CMlfoSAOOMAtCSfUYBhooDoAmI+VshCwBV+CoAsmAgCwBdSAEKra/VbjSg52etLlFNL571Vda/swEDO4FDgAEAVf0c8UOq3HwAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLACK_WITH_BLUE_STRIPES_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAOk65////oYUMIQAAAAN0Uk5T//8A18oNQQAAAFlJREFUeNrs1TEKwDAMBMGV/v9oFw4EuUiwUwTjvUogbkCVyI9BQEBAQOAEAMqG4AeA0p8FcgRyAeCeF4FOwMMFb8CVIAQEDgUYAbYDKhH4mQQEBDYAmgADAG0xHcIUImbIAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_BEAR_LOVE_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/////6Jr/QFbNAAAA////1efoqQAAAAZ0Uk5T//////8As7+kvwAAALxJREFUeNrs1eEKgzAMBOCkyd7/lddcW+dYRBP3Y4Mcggreh9WI9LgZKqCAAgoo4PcBtRyengKqZNldZfEJDxh1J3oNOOy7AkX6nkChviNQrP8pfB3YBKHWY0fYy9UlrLdufWbuAnZdkLfJOB/lAcy0JuFvwe6cmbC1JMAL4DxwZwl4eqwKgJIA2poFIKiinwNoPgUbpxyAIRzjGAbm6K5+H8QosAmzHwfk9QWKxAEQu9SvrYACCvgD4CnAAGgrSGlS/YzpAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_BEAR_MARKET_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/QFbNAAAA/1JRUf9a////grSvdAAAAAZ0Uk5T//////8As7+kvwAAAJtJREFUeNrs1VEOQDAQBNCdlvtfmS0VjS22/UDMfEgk5qWrFTJ2RggQIECAwPuBoKneXgIhiGb3lMYmLGCpGwn3gGrfFMTTtwRx9Q1BfP2jcALEJmATUAq4O0LedaQlDPN1WAUUJ+P6KC9DqJEWAve3kN9DJ6AD9AF5O54FVPgjACkFwAsUQkQDsBPQACRiSwR/bQQIEPgAMAkwAPh8R1rI3W1LAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_BULL_MARKET_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/QFbNAAAAUf9a/1NR////3F3VpQAAAAZ0Uk5T//////8As7+kvwAAAJxJREFUeNrs1esKgCAMhuFN6/5vOVQ8L3Taj4RvEKHwPlQU0b05BAAAAAAA/g8YN6/LIWAMuckb1i1lQgJCXo4NJzMH9H0EJIFm+gQIAql6QaCJvgQ64XMgCVz3PHsLfq/uwwUwV2/G+FXOcejV30Lsrx3AbgKuJn8sA3lWgLJffognA9wCrAW46fUAV7ka8EQx+LUBAADgAOARYAAlv0dYQnwcWwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_DRESS_WITH_WHITE_DOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNAAAA////////4q5S+AAAAAV0Uk5T/////wD7tg5TAAAAy0lEQVR42uyWgQ6DIAxEr+f+/5snKKEUgtWFJVvaIKSVPq6AiXh9aAhAAAIQgAAE4GsA+Of8KQDKngCwQbUnALgkLAXoGu4DAJ+ElYDmFPCDJWzw3aRlCgAnAc4K7gIAr4RBmDVHDIMOAJkUyy5aUhMUN/fkBYDMywrKIFpJ8i0CbXpNroDq5MEg0KRn1YAqAqOIRkDtnaBZS/s2xBGgvLx89o7DEopEUXLFBI/G8SYyWye3Wf6YM71IJ8YC+tT5t8DO4g8lABN7CzAA6/03ZRYRDFwAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_DRESS_WITH_WHITE_LACE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNAAAA////////4q5S+AAAAAV0Uk5T/////wD7tg5TAAAAx0lEQVR42uzWiw7CIAwF0Nvq/3+zsldfyEgXXWKKYwaye+iYJsPzYkMBBRRQQAEF/AzA/DV/CuAhnwyg8wPhM2DyuKMCXKwA0AKQAlQ+CUg+Cxz5NLDn8wDuAoBJ4VsAMCt0plky5AyeAJj3JLWDFPQ+M58ALU4qb4Bl7AnYuIQFkMHy5QiYuM1vPc5oAmrvCGYtPfZT3AMI6BUQe6uhewt2URjw2FByjxNmD1sL5Zrl12uGP6SN8UCMjv8LHFq9oRQwaC8BBgC4cTc9RVw6OQAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_DRESS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/S2LeAAAATWf3////tNYCwwAAAAV0Uk5T/////wD7tg5TAAAAkklEQVR42uzVwQrEIAxF0ZvY///misN0LE0hWkrL8LIJaN5BdCHLxUKAAAECBAjIAYxOvQ/47bE8BbDvw3fAJ1mbzQD0ZVcBHgAofb4wCRS+fRyg1Grh1ieA3CX8MQBJ4S4AskK47FHezLPAST4WGMiHwhHwOhimYyE6gXsbPqbds6/QBq2rbVG/swABdwGrAAMAEJk6iXr20NwAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_ETH_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNOk65AAAA////IO6oqQAAAAV0Uk5T/////wD7tg5TAAAArklEQVR42uzV2wrDIBAE0JnY///mZtW22phuNgbawuxDQHAO3pbgNlkQIECAAAG/DySr3aELpASrZpbVmBgBJT6odAzYzQ8FOPmFjgAnv9AR8Hn9G2AjwFnACjAEPAWWvAGsw0NbeNw60QPI38hTrvkMrFmGe+EKoD3Ekyso1zizBXuJE1swAfUav3IGFwCvXggDfGtnMgr0LcQTALt4GMhEU/q1CRAg4A+AuwADAKHIOZyruYN8AAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_FANNY_PACK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/AAAAS2Le////23idyAAAAAR0Uk5T////AEAqqfQAAABMSURBVHja7NJBCgAgCAVRs/vfuUhsGfQLVzO7Fr1CtP6YAQAAAAAAAAAAANQBbWWZx/kacB2IfKfOID+gD3FePr/PIgEAAHwEhgADAEFtL3Hj35rhAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_HOOLA_HOOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAUGv/////v7SHiAAAAAN0Uk5T//8A18oNQQAAAHxJREFUeNrs08sOgCAMRNFb//+j1SIRjbVNiCvHHaE9Di+WyQ8BAgQIECBAgAABfwCYawDLAIMYwCxPcKvhMkdhS7aUxEBp20LAI5D9n3gJvsDdIGz2grdTaSWOjEwbHzPZuffSzlzHxZs4tj0lKt68M4GeswAB3wOrAAMAE1AfEcd7K6MAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_HOOT_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/Ok65QFbNAAAA////1/BWvQAAAAV0Uk5T/////wD7tg5TAAAAlUlEQVR42uzV6QqAIBAE4HXs/Z+5tAOPFd0KLJixfgTN16GRLA8jBAgQIEDg+4APaR52Ae8lJDkrRCc0YK8r8WNAs68KYulrgpj6iiC2fi28DlwC8h5GH+GcdZRXBrKV0V/KTrbhrh3mbyECx9i2GYCbfgfJS7wFlLP4PwDVQrQCKPp2AFndDEQiCX9tBAgQ+AGwCjAAvKk5Zh18qpkAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_JESTERS_COLLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNAAAA6sU3////6d2nHgAAAAV0Uk5T/////wD7tg5TAAAAgElEQVR42uzT2wrAIAwD0Cb1/7953hCcbqvsNYUhBnIEcZZ+jgkQIECAgA+AjGVPAG0TmzEK5P4qlIwxoPbvQssYAXp/IkbEI2AzIQBmwNotGRi6RCB/tYJRNbQ8BHiqAFJ3xs5PXmI/Dm3dHv4O+Ly6fmcBAgQIECBAQHQuAQYAMAI9ysAZ6R4AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_KNIT_SWEATER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFUGv/////Ok65S2Le6sU3bpZwAAAA////Z+jJUAAAAAh0Uk5T/////////wDeg71ZAAAAt0lEQVR42uyVSw7DMAhEx8El979x1cSOYgMxqLsWZmWkefJAPti/LCQgAQlIQAL+AMC87jwAmAs+6ufzpCM0AKPoYh/A9KsEKP6XKWIPYIMpD+DJrxEQSaBlkIA2LxrnR63ruUE9RLXcRa27BFwJaPBXsjLAl8DOACuBmL+RQQB6gnmDLYPjBkcRzU8xne0l4KpxhqWGPyiTv4QB8xaiAPkWBAHCv8UA6Mu4Vf5YEpCABPw84C3AAJMLZQNVCsV6AAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_LEG_WARMERS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAABeSURBVHja7NLBCgAhCEVRn/P//zwpFszSghbDdfUQPFRmz2EZAAAAAAAAAAAAAADAXcBnW+5asQVk3yyAyj1gTEXFUGU1AZ0BefwPoI0tqK49X6G/Ri2Ar/x34BVgAAYBLzkR21hbAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_OVERALLS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/S2LeAAAAzs7O////3OYueQAAAAV0Uk5T/////wD7tg5TAAAAn0lEQVR42uzWSwqAMAwE0JnU+5/ZahvFD8KkCxEzq4DmgWkoYhoMEkgggQQS+AkA9a3LI1yrBH4HEKD3e6UBpbQ+oJQAwNqGHqdEgHSgVhHgmBDAnjjQv+CbAM8AVQBjQN+BAyMAtu2QH+JamgDgJgqA27wCkCFgE+rg9nnYFABsnygHAUpAuwhbkz0u4sOduCyR+VZELtX8xUlAyCzAAHgcOfOmJR/pAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_PINK_UNICORN_DEX_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/QFbN23z46Jr/U27/////9VSvWgAAAAZ0Uk5T//////8As7+kvwAAAJ9JREFUeNrs1cEKwzAMA1DZXv7/l5c6KW16GFiBwZh8KMlBDzspLdpmQYAAAQIE/ANgsA/brwBLpG+qQHsCrQ5cIXtxwOzbckkBB2FzUQZ6yB1XMcAh+BaQQsRGB/mIJKgzAAJnCwRwju9kBx5zijEDA8S4SLaDnnbEEOhrHAD9JiJvgQQMaxnxQVnzdcDu6TqQxK30ZxIgQMAPAG8BBgCraErGJlXB6QAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_PONCHO =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFytL/q7j/AAAA09r/////ULoMdwAAAAV0Uk5T/////wD7tg5TAAAAxUlEQVR42uzWUQ6DIBAE0Jmx9z9z1aplFWTBmrTNzpdA9kUBUTwuBgEEEEAAAXw/INV7TgAJ2A2MHXkiB0zlMMTSIR+w1o/h1Oa7LQ+Q1M8C07bqgKkfBdq2WoF9qkBaT49wH0ALsAdIBS8glICSgJMbMJe/AwxcslVwnYRXBlVWYc0e2Ea8J5JZBgLNR9pVwEwdgaJwF4AjAD+gdPXSPaCmQ/V4Cz0A0Q+YDcxeAJ8CGh9he6NsBvm/jfnEH0oAfww8BRgAtJ80z7xqP48AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_PORTAL_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNOk65AAAA////IO6oqQAAAAV0Uk5T/////wD7tg5TAAAAv0lEQVR42uzV7Q6DMAgFUCi+/zNPPqzTYC34RxNoolmye4oOJywPCwoooIACCng/QFyXH28BIuD6+xaXT3iAxp2iOeAy7woQyXsChPKOAKM8ag2FEYCn8xTQBeScNYA7QjM/457fGhDrMBn3o9xbUAzDz4IF7djSAEJb1wNA0utKAhxXIg5suzfJZwDb3I4JQIUmLWRuYt9fewgDMoSyud4GxCigY2xXwBMZBvD0WIf/1vFQ9WoroIACPgD8BBgAbXU5ezvoUlYAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_PROOF_OF_STAKE_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNOk65AAAA////IO6oqQAAAAV0Uk5T/////wD7tg5TAAAAoUlEQVR42uzV4QqDMAwE4LvU939ml24VqxFN3Y/JLqIgeF+jrRTTzYIAAQIECPh9oHgd3p4CpcBr9ZRXTETAOx5UuQYc5kMBmXwkIJUPBOTye+HrwCKwz/HqK7RZ53ZkslsZ50sZMLN61gvT/8IrtxzewAhgn7h3MdYB2vg2DrTvMAL0k/CHAHcLMQtwk88D7OJpoBKr0tYmQICABwCzAAMAOEc5SWQl0jUAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_PROOF_OF_WORK_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNOk65AAAA////IO6oqQAAAAV0Uk5T/////wD7tg5TAAAAmklEQVR42uzVUQ5AMBAE0Jmt+5+ZaojWCls+iJnGh8S8VlqB4WYgQIAAAQLeD6Scw9tTICXkbJ7K8QkPKHUn6Rpw2HcFRPqegFDfERDr74XHgVVg3ePVV1h2ne3MZHUyzo8yzKxcU9HA8LcAW0cvYHeBubiMXmBaRVlEB9Bswg8B7g5iFGDTjwOs6mFgJjbRr02AAAEfAEYBBgBGbTlL5pGu5gAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_PUFFY_VEST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/S2LeQFbNAAAA////16KZPwAAAAV0Uk5T/////wD7tg5TAAAAqElEQVR42uzV4QrDIAwE4Fzi+z/z2lo37YblImMMLn+KQj5iatDKYpgAAQIECPgDIG435kCYoV/DLBhgyx8E7OtgKvgEFBZ4CUd+AmhCzc8AVTjzOaAT5vl3gKHlZwHLAu4j4E5X4DVQP+PFzByBBcoFAD3OrQmYt2BWQd+DRAXLR/h5D3DpAf0bsXgP8D4LIIAAnlPYmrhFcO8ChtDbKECAgO8DDwEGAGFxOu854dqRAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_REKT_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/Ok65QFbNAAAA////1/BWvQAAAAV0Uk5T/////wD7tg5TAAAArklEQVR42uzVUQ6EIAwE0HbY+5/ZILsgyBaoH2oyjTExkWc7YpTPxRICBAgQIPB8IMT6ezkEQpBYh7ti9YkekJZ3KswBeb2msgWxn6/7YQli998CZ0GM9bF91UEOMhvgLJAF1ClidoTfW0dJIA0BVDtjvJUbAMvfQjO6Eygh+DvQSx1I3gneEfL5rhBLDv4Mvq9hGUDbAVYB1BE4AFTLl4GdOBR/bQQIEHgBsAkwAO/eOWmD0pTuAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_RASPBERRY_PI_NODE_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFUGv/QFbNXRpwhy6hV9RdR65NU27/////Ks1hpgAAAAh0Uk5T/////////wDeg71ZAAAAl0lEQVR42uzVwQoDIQwE0EzU+v9/3MYKWg8FR2hZdsIiepinqKxWD8sECBAgQMAdABi+DH8CfEReg12grkDdB0YIDw7o60brUkAQ6J1twJaigJxHSwElsjkXGgih50nAPCU/2APzAJwHWryv4T/AO+6JB5K3j7+JHvM7dZWxHCOIH8pcIADM6X2gEVPpZRIgQMAFgKcAAwAYqWiyvHTVtwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/AAAAQFbN////S2Le////L1gcOAAAAAZ0Uk5T//////8As7+kvwAAAJ9JREFUeNrslNsOgyAQRGeG7f//chHshXZtIMY+zQY38sA5Iyq4nSwYYIABBhhggAEGGGDAPwHgOC+xCtjqfbIIQAGIsS8ACOG7xFkAM7/AlIADfx+7+tEzArL1dSQZkGZIANqlwhhFiODcI3Rb7WMWBSc3UXgGeGWJzH/0Gtl2vdvV7kOFXPiQyE2pam2tXvnyHz8TP8oHigGXAu4CDADJ9kuCLqH6NAAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_SKIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNAAAAS2Le////Uu0oYQAAAAV0Uk5T/////wD7tg5TAAAAkUlEQVR42uzUSw6AIAwE0Gnr/c8siAHE1kCMrqZRJDHzil9sLwsECBAgQIAAAQIECPwJYDgBWwbQjDxfBHAvWwAU4giis4Cbl0BAkC9bzcYCwnwz2ugIDiDogbYUgZnOXQKuRj2YTt5EwSVcpub1jx5jt4gTstReF14k1dxSUtdjSLsff/iYdCj+UAh8CuwCDACVWzxGrh3vrwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_STRIPED_NECKTIE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/Ok65////zGC7igAAAAN0Uk5T//8A18oNQQAAAElJREFUeNrs1MEJADAIBMG99F900oGPAyGw/h08QTllISAgICAgsAgQ0k0w9Y9A6IBQRnj9tEvECEaoI9S34EsTEBAQ+Au4AgwAeycfqdWs1wcAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_SUIT_JACKET_WITH_GOLD_TIE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFUGv/QFbN////AAAA6sU38uOpOk65////eiK6iwAAAAh0Uk5T/////////wDeg71ZAAAA1ElEQVR42uzV2w6EIAwE0E6p6///8XJRAsqt7OO2L0SSORkxQTp/HDLAAAMMMOAPAOfmOwPAOQrDLMchcjDHxzbRAlI8CkU+EGtAznuAQz4DLYEG+VihKNAUJkA4AyVQ5onCGVQbTgn4vAeEtwFKedkAcL8Dffzcj3MgF0DdBL0KNC7wFrSAb19tYBFApwHmAK55NbhmCrBwnGeDtCvsVi+UZwP1jfRsoAXodQabQP4IWgBUfU+ogTMlESn086Nr3RNIaz8++S+gWuzfaIABBoznK8AAFZ1h2q7B4g8AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_TANKTOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbNAAAAU27/////YBaNzQAAAAV0Uk5T/////wD7tg5TAAAAeUlEQVR42uzVwQrAIAwD0Kbr/3/z3JBtKmyk7iKkp+bQh4JUi8kyAQIECBCwAODuL/EbcBieuUTnTjAC5BXQjJTAAtEDwQP3ELYcUM+Ns00BB4HaJIGreMC6EiDgD4B+iegBzAFAYiM14/xGCjSlr02AAAELALsAAwAOWzttt1K3WAAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_TOGA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/S2LeAAAA////rmvP5AAAAAR0Uk5T////AEAqqfQAAACXSURBVHja7NXLDoAgDETRW/z/f1ZRHguD0FkZy4KwmRNoKLCJgwACCCCAAH4JJA0wLCmAgSk7GOSnAI4DoACj/AyACOS8AJxpGUAA7rwboADOe1DzToA2XAAigAj0aQ9AK6AL6PN5tfoeYNYMB2BWky/CI5C6HHUnz6/iHHBNabGI5QTjdmKij9zd2G5SfK4BBPABYBdgAJjYLNcRmxqrAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_TUBE_TOP =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFUGv/QFbN////0hR+pQAAAAN0Uk5T//8A18oNQQAAAEVJREFUeNrs1CEOACAMQ9GW+x+aBMUyA5lq8r+q2ZPTGiYAAAAAAIBHwG0AxAHWXSLgCvgfqPcTwCceCgAAAABABrAFGADpGR9PORU0BwAAAABJRU5ErkJggg==";

  string constant CLOTHING_SHIRT___BLUE_VEST =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/S2LeAAAA////6sU3////k/s+EAAAAAZ0Uk5T//////8As7+kvwAAAKZJREFUeNrs1eEKgzAMBOBLur7/Ky86GKmoJVf3Y3BF0CL3kVaN6IsDAgQIECDgDwB3v5nOAQeGOzH1CrDlYUMe5pUKzoDaHgyRm/zvAEshMMAuZKAzwEeIcyMAJKC1RgKbsOdpIIg4YvDAy8BtIlIJTwC2ugTj3oOVCh4DyCX4oYDLfjID7LubNSDlZwKm3xLbDw4dqf4Uutn5tX6uAgQIuBhvAQYAPXNKJwyo5N0AAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_WAGMI_SHIRT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/Ok65QFbNAAAA////1/BWvQAAAAV0Uk5T/////wD7tg5TAAAAqElEQVR42uzVUQqEMAwE0Enq/c+81qhra0QTBXdh4kcRnFfbRsRws0CAAAECBH4fKLUOb0+BUlBr81Qtn/AAiztVrgGHeVdAJO8JCOUdAbH8XngcWAVtc3p1Ccupaz+zatMZ560MGQMCGwQa/hbG5PfCDUBsTABT1ubPLaHbwxRg7yCSBeYNFLwIYD6HBKC7RowC2uXjgDbxMDARm+KvjQABAn8AfAQYAJGeOWKplSgTAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/AAAAQFbN////p7KLPAAAAAR0Uk5T////AEAqqfQAAACfSURBVHja7NXhDoMgDATg3u3931nphKGAwlgyTa78USifBSXaazJMgAABAgTcH0CI5u0lABjMsiELHXWiBni2bYG89QFoA+gBYnYNqNRgjec7sF4fAVwBn9wwvwSKGk4AfAWkJdALTgB7lxCrYLEH7H6N28Ae4PBZ+AHgB2CuguxDEvAPgEeAowCnAWYAxwEnQuDd9GsTIEDAA4BFgAEAbp0rblZPrXIAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BLUE_WITH_PINK_AND_GREEN_DRESS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/4YGAiP/EAAAA////f+yuPwAAAAV0Uk5T/////wD7tg5TAAABF0lEQVR42uzW4W7DIAwE4PN57//MA84mI01pwqT9mEBViarwYYxBxdcvGzawgQ1sYAMb+DMA99/5pwABGFi/sAKUYewAlwCrQA2DkxA+AG0VqwDr9GyALQBlbAL1iYuArQMswwh9sAQYNb1SuQQoAW0B77dhAsQeNsCeAy36yOQKELEfgD0GKAAK5CnQTpHSnwBuAw6dIRFKJrQivwG4MwpQZaSHpNw/AO7Q+CwhOzTl5EzgPHsv3gCYncIoykjgNLsNC/gxuO8JbSAw5I5H5HEMiX4kFZXq0y+BvMJyzVlGfSvzesAlUENA33nmZRhbOgp+nURvLRGtPvLJ/FXvTAspmMhedKV/GTo/C/7S9j+UDUzatwADACJGOA0u6TEiAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BLUE_WITH_WHITE_APRON =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/QFbN////AAAA////7zl41AAAAAV0Uk5T/////wD7tg5TAAAAb0lEQVR42uzW0QqAIAyF4X/V+z9zKgnpVW6RCeeI7MZ9iKDIEQwCBAgQIEDAQ4ChRQJ+CRj3rAi0/dj3wEYzHDvohOlngAOwHGoZBlInZV5lBkDZei0eIHaIAt4Aopep68fzKqfsKfpgCFgBOAUYAEoBOwJog1HxAAAAAElFTkSuQmCC";

  string constant CLOTHING_SHIRT___BORAT_SWIMSUIT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUf9aAAAAV9Rd////ch20ZQAAAAR0Uk5T////AEAqqfQAAABsSURBVHja7NVBDoAgDETR3/b+d3ZlMCamSKMEHRZsZvICCyhRXAgQIECAgD8AdgqwuydgrHeVEBOAY0RMAVpGrArsIbEwQNvHXiOdlQcBshtkHwo9DQFJDB8AvDaZ3IujzUzjXYCAd4BNgAEAI00vP0Y++BgAAAAASUVORK5CYII=";

  string constant CLOTHING_SHIRT___BUTTERFLY_WINGS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFwkvlyqLVAAAAodj5////5GyjhQAAAAV0Uk5T/////wD7tg5TAAABa0lEQVR42uyX6w7DIAiFEfb+z7y2auWOybJkWepPdviqBo4MXh8ueAB/BUDE/Swmhhlpre0ihLgDzsi5tghSDDy0swlkYgGAY21s4kof2hsw81k4y5fSATgCtEG48+mSSsAZppzQ84nmFlxAQhjfDwAj2gk+YJ3/kjs7GJiI0GW0PuQA5k9xPlchq4N1tusmXYCQgCokUL+6+Rmg8Us4ltO3UiBKmRPmB5x8InMDEkAMQBpADMDrDWSNTo3rPWt7rNocAIU2BxQCxC0kBmibFmyjphZqWhZMq+QA025gmq1wcd2uYOyqAqh2B2N4OcDYJhjLrQDKuPWOa1v//+f90zvAVgG054N2/hLQ8IsALCv5SEgqEXebCRMAVX5AMWA9UORnkzJkH+B6unT2ADAOEL5s99smDwHOCeLn3TmDAvQnI54PGpsMAlNt+YTSClPNZ0V0BlJjqvmo2RGxqeLOpIr4/GN5AL8HeAswAG+JNKIGEK8PAAAAAElFTkSuQmCC";

  // duplicate this in both clothingA & B
  string constant NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return CLOTHING_CLOTHING___BLUE_ERC20_SHIRT;
    } else if (assetNum == 1) {
      return CLOTHING_CLOTHING___BLUE_FOX_WALLET_TANKTOP;
    } else if (assetNum == 2) {
      return CLOTHING_CLOTHING___BLUE_GRADIENT_DIAMOND_SHIRT;
    } else if (assetNum == 3) {
      return CLOTHING_CLOTHING___BLUE_LINK_SHIRT;
    } else if (assetNum == 4) {
      return CLOTHING_CLOTHING___BLUE_WEB3_SAFE_SHIRT;
    } else if (assetNum == 5) {
      return CLOTHING_CLOTHING___RED_ERC20_SHIRT;
    } else if (assetNum == 6) {
      return CLOTHING_CLOTHING___RED_FOX_WALLET_TANKTOP;
    } else if (assetNum == 7) {
      return CLOTHING_CLOTHING___RED_GRADIENT_DIAMOND_SHIRT;
    } else if (assetNum == 8) {
      return CLOTHING_CLOTHING___RED_LINK_SHIRT;
    } else if (assetNum == 9) {
      return CLOTHING_CLOTHING___RED_WEB3_SAFE_SHIRT;
    } else if (assetNum == 10) {
      return CLOTHING_SHIRT___ADAMS_LEAF;
    } else if (assetNum == 11) {
      return CLOTHING_SHIRT___BLACK_BELT;
    } else if (assetNum == 12) {
      return CLOTHING_SHIRT___BLACK_LEATHER_JACKET;
    } else if (assetNum == 13) {
      return CLOTHING_SHIRT___BLACK_TUXEDO;
    } else if (assetNum == 14) {
      return CLOTHING_SHIRT___BLACK_AND_BLUE_STRIPED_BIB;
    } else if (assetNum == 15) {
      return CLOTHING_SHIRT___BLACK_AND_WHITE_STRIPED_JAIL_UNIFORM;
    } else if (assetNum == 16) {
      return CLOTHING_SHIRT___BLACK_WITH_BLUE_DRESS;
    } else if (assetNum == 17) {
      return CLOTHING_SHIRT___BLACK_WITH_BLUE_STRIPES_TANKTOP;
    } else if (assetNum == 18) {
      return CLOTHING_SHIRT___BLUE_BEAR_LOVE_SHIRT;
    } else if (assetNum == 19) {
      return CLOTHING_SHIRT___BLUE_BEAR_MARKET_SHIRT;
    } else if (assetNum == 20) {
      return CLOTHING_SHIRT___BLUE_BULL_MARKET_SHIRT;
    } else if (assetNum == 21) {
      return CLOTHING_SHIRT___BLUE_DRESS_WITH_WHITE_DOTS;
    } else if (assetNum == 22) {
      return CLOTHING_SHIRT___BLUE_DRESS_WITH_WHITE_LACE;
    } else if (assetNum == 23) {
      return CLOTHING_SHIRT___BLUE_DRESS;
    } else if (assetNum == 24) {
      return CLOTHING_SHIRT___BLUE_ETH_SHIRT;
    } else if (assetNum == 25) {
      return CLOTHING_SHIRT___BLUE_FANNY_PACK;
    } else if (assetNum == 26) {
      return CLOTHING_SHIRT___BLUE_HOOLA_HOOP;
    } else if (assetNum == 27) {
      return CLOTHING_SHIRT___BLUE_HOOT_SHIRT;
    } else if (assetNum == 28) {
      return CLOTHING_SHIRT___BLUE_JESTERS_COLLAR;
    } else if (assetNum == 29) {
      return CLOTHING_SHIRT___BLUE_KNIT_SWEATER;
    } else if (assetNum == 30) {
      return CLOTHING_SHIRT___BLUE_LEG_WARMERS;
    } else if (assetNum == 31) {
      return CLOTHING_SHIRT___BLUE_OVERALLS;
    } else if (assetNum == 32) {
      return CLOTHING_SHIRT___BLUE_PINK_UNICORN_DEX_TANKTOP;
    } else if (assetNum == 33) {
      return CLOTHING_SHIRT___BLUE_PONCHO;
    } else if (assetNum == 34) {
      return CLOTHING_SHIRT___BLUE_PORTAL_SHIRT;
    } else if (assetNum == 35) {
      return CLOTHING_SHIRT___BLUE_PROOF_OF_STAKE_SHIRT;
    } else if (assetNum == 36) {
      return CLOTHING_SHIRT___BLUE_PROOF_OF_WORK_SHIRT;
    } else if (assetNum == 37) {
      return CLOTHING_SHIRT___BLUE_PUFFY_VEST;
    } else if (assetNum == 38) {
      return CLOTHING_SHIRT___BLUE_REKT_SHIRT;
    } else if (assetNum == 39) {
      return CLOTHING_SHIRT___BLUE_RASPBERRY_PI_NODE_TANKTOP;
    } else if (assetNum == 40) {
      return CLOTHING_SHIRT___BLUE_SKIRT_WITH_BLACK_AND_WHITE_DOTS;
    } else if (assetNum == 41) {
      return CLOTHING_SHIRT___BLUE_SKIRT;
    } else if (assetNum == 42) {
      return CLOTHING_SHIRT___BLUE_STRIPED_NECKTIE;
    } else if (assetNum == 43) {
      return CLOTHING_SHIRT___BLUE_SUIT_JACKET_WITH_GOLD_TIE;
    } else if (assetNum == 44) {
      return CLOTHING_SHIRT___BLUE_TANKTOP;
    } else if (assetNum == 45) {
      return CLOTHING_SHIRT___BLUE_TOGA;
    } else if (assetNum == 46) {
      return CLOTHING_SHIRT___BLUE_TUBE_TOP;
    } else if (assetNum == 47) {
      return CLOTHING_SHIRT___BLUE_VEST;
    } else if (assetNum == 48) {
      return CLOTHING_SHIRT___BLUE_WAGMI_SHIRT;
    } else if (assetNum == 49) {
      return CLOTHING_SHIRT___BLUE_WITH_BLACK_STRIPES_SOCCER_JERSEY;
    } else if (assetNum == 50) {
      return CLOTHING_SHIRT___BLUE_WITH_PINK_AND_GREEN_DRESS;
    } else if (assetNum == 51) {
      return CLOTHING_SHIRT___BLUE_WITH_WHITE_APRON;
    } else if (assetNum == 52) {
      return CLOTHING_SHIRT___BORAT_SWIMSUIT;
    } else if (assetNum == 53) {
      return CLOTHING_SHIRT___BUTTERFLY_WINGS;
    }
    return NONE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Belly {
  using Strings for uint256;
  string constant BELLY_BELLY___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/+2o+dZOAAAA8uGf//jb////NLhWdwAAAAZ0Uk5T//////8As7+kvwAAAKRJREFUeNrs1UsOgCAMBNCxrfe/solCRKHqQHRjZz+PT0LBPBgEEEAAAQTwE0CKdAAiUxGf8IBDfSU4YOub3Qu46j/ZA54doBcwK05BADKdrsB8AZdXgDVZYIFUTwQP5LJZJjhgXx5ZoACgFhgAaAg0YP3AqZ8yCigLYADQVp8AmoJSr/EFQCmgFry+P1RVD3UVfqxrEX6sj38s8TsHEMDHwCLAACSDRysbj8dQAAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___LARGE_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF2dnZ6+vrNTU1AAAA09PT////FNnvdQAAAAZ0Uk5T//////8As7+kvwAAAJRJREFUeNrs1dEKgCAMheHZ1vu/ciAamzXpJArRzv3/4UUp7YOjAAIIIIAAfgKw2guAeVPzCQ8weSYw4NK7Aj3tPWEukMpggE1+EgwBuaO8SiBAUn0REgLYvgooQNQIqwGiVvg+ICsBuQEEAK6Ce4CpgP2UBQIaodP7l6qI+p3F7XvXuqjh1/r4wxKvcwABLAYOAQYAmr1IGcCKtUIAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___LARGE_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vr4ODgAAAA09PT////omcZtAAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVwQ7AIAgDULD7/29eshM4IaKZl7X3vnixyLUZIUCAAAECPwGayQLQmpjERAS4+kPUgFc/FGS2HwkfA/qkDvh+LmSAqheqgGonnAZUe4HAPoCTAAYACsBAiB4wC8gK4D8TSkAnJP14VAEzKAj72azDpD7r+4eF15kAgcPALcAA+cg5Kmqq9loAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___LARGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1RUVFAAAALS0t////IsSZNwAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVwQ7AIAgDULD7/29eshM4IaKZl7X3vnixyLUZIUCAAAECPwGayQLQmpjERAS4+kPUgFc/FGS2HwkfA/qkDvh+LmSAqheqgGonnAZUe4HAPoCTAAYACsBAiB4wC8gK4D8TSkAnJP14VAEzKAj72azDpD7r+4eF15kAgcPALcAA+cg5Kmqq9loAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___REVERSE_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU12dnZ6+vrAAAALS0t////gYpa6wAAAAZ0Uk5T//////8As7+kvwAAAJhJREFUeNrs1UsOgDAIBFAUvP+VTfoLRGkcmzYxMvt57aIFOgZDAQQQQAAB/ARglRcA867iEx5g6onAgEvfFehp3xPmAlQCA2zqjWAISL38CCqBAPlc3lK43AIATL8JKND6VVgNqH4Rvg/ISkBuAAGAi+BfYCpgn7JAgBV6fX+oiqjvLG6/N9ZFBR/r44sltnMAASwGTgEGAPSqSIkvuflUAAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___SMALL_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFNTU12dnZ6+vrAAAALS0t////gYpa6wAAAAZ0Uk5T//////8As7+kvwAAAKFJREFUeNrs1UsOgCAMBFAs9f5X9oemVYc4EtnY2c9LILSksTEpgAACCCCAnwDZ5AWQczLBBAJcfSU44NKHQnraR8LHgKzhAd+vCzVAxAsssDSHOYdAAqVeCB4w/V3oC7h+EboCcgWkGdCegN7cgRLALNwA1DSqnN8BC7hbEHwCuNI24Rgm2MdLVdWMs8J+ba2rCb/W2z+W+J0DCKAzMAkwAHmJSDOoQJz8AAAAAElFTkSuQmCC";

  string constant BELLY_BELLY___SMALL_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF6+vr4ODgAAAA09PT////omcZtAAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVSwrAIBAD0BnT+5+54KJYNaWjIJYm+7zVfOyYjAkQIECAgJ8AqcgAkJIV4QQDbvVMxICmTwV722fCpkC3T4TdAc8ZBvzKGOBeCUHAvRa+D2AlgA6AAJCFBghtI9o5mAUQAmqB9/lRBYplAu0/nXUUiZ/1+cei7yxAwGLgFGAAl2w4/zBwQbEAAAAASUVORK5CYII=";

  string constant BELLY_BELLY___SMALL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1RUVFAAAALS0t////IsSZNwAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzVSwrAIBAD0BnT+5+54KJYNaWjIJYm+7zVfOyYjAkQIECAgJ8AqcgAkJIV4QQDbvVMxICmTwV722fCpkC3T4TdAc8ZBvzKGOBeCUHAvRa+D2AlgA6AAJCFBghtI9o5mAUQAmqB9/lRBYplAu0/nXUUiZ/1+cei7yxAwGLgFGAAl2w4/zBwQbEAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return BELLY_BELLY___GOLD_PANDA;
    } else if (assetNum == 1) {
      return BELLY_BELLY___LARGE_PANDA;
    } else if (assetNum == 2) {
      return BELLY_BELLY___LARGE_POLAR;
    } else if (assetNum == 3) {
      return BELLY_BELLY___LARGE;
    } else if (assetNum == 4) {
      return BELLY_BELLY___REVERSE_PANDA;
    } else if (assetNum == 5) {
      return BELLY_BELLY___SMALL_PANDA;
    } else if (assetNum == 6) {
      return BELLY_BELLY___SMALL_POLAR;
    } else if (assetNum == 7) {
      return BELLY_BELLY___SMALL;
    }
    return BELLY_BELLY___GOLD_PANDA;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Arms {
  using Strings for uint256;
  string constant ARMS_ARMS___AVERAGE_POLAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF6+vrAAAA2dnZ////Lc7C2wAAAAR0Uk5T////AEAqqfQAAACJSURBVHja7NXBCoAwDAPQJv7/Pyuo4Fw6KqIHzW5t6aM7dIvp5gkDBgwYMPALAEASlAAg4lBagoyItP0EZIQC1vamsmZQA7Z+ASjhAWDvV4AQojTAYIQUYJvle8B+Aw30QtQGyEcwIAHmAIsANcALAPutYRGYMAJQWufkBdR5fywGDBj4EDALMADp8SzvRmf/1gAAAABJRU5ErkJggg==";

  string constant ARMS_ARMS___AVERAGE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFNTU1AAAAKioqMDAw////xGf92wAAAAV0Uk5T/////wD7tg5TAAAAl0lEQVR42uzVyQrDMAwEUM2o///N2RqokxEohPTQjn2ybD1k8BKvmy0MGDBgwMBfAACKQQsAIj6m5kFFRJl+ACpCAVv6MLNF0APe+QJQwgPAnq8AIZRAjtG8CiTHKPNrwL4DDZyF6BVQl2BAAqwBNgFqgD0gl3U835o1nGicRKYGcu5oXWeA6u2hfBn9sRgwYOCHgEmAAQAuljwQRH1rwAAAAABJRU5ErkJggg==";

  string constant ARMS_ARMS___GOLD_PANDA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF+dZOAAAA1bY+7MtK//jb8uvQ////JJEdSwAAAAd0Uk5T////////ABpLA0YAAACsSURBVHja7NXhCsIwDATgXFJ9/0e2pgh2u8DBEEGz/Vra+2hgbe1+8bEGGmiggQb+AgBQfEgAMOxtyMwqwor4zO9ARTBgxbeRFAY0ABknABU4wFcwu1CAV54BRCCAJRB7NZaqAZn3vepxGciyAGA1WwBnoQCO+RREYHwdsE8BNxnwGnARcA64BsRznp93TZYDwp/owYGYL6TtDDg7e5yejH2xNNBAAz8EPAQYAFoHWgaq+LesAAAAAElFTkSuQmCC";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return ARMS_ARMS___AVERAGE_POLAR;
    } else if (assetNum == 1) {
      return ARMS_ARMS___AVERAGE;
    } else if (assetNum == 2) {
      return ARMS_ARMS___GOLD_PANDA;
    }
    return ARMS_ARMS___AVERAGE_POLAR;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";

library Accessories {
  using Strings for uint256;
  string constant ACCESSORIES_ACCESSORY___BALL_AND_CHAIN =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAANTU1////eV5mqQAAAAN0Uk5T//8A18oNQQAAAGhJREFUeNrs08sKgDAMRNGb/v9HK7EtLgRDBFc3y8Achj4YHwcBAQEBAQEBAQEBAYFfAaj7PO6WQB0gZ8fgvigAEDEDV6qa30BECtm/c4irAQNGD5idaV4j9VN7adB+SN28v/GcQ4ABAHvcH0/tVeZ+AAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___BAMBOO_SWORD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFAAAAobSMbpZwNTU1//PC////9rlm+AAAAAZ0Uk5T//////8As7+kvwAAAIxJREFUeNrs1EEOwjAMRNHvabj/lWlZhG4sHEdCIE32fpbHSXhsHgwYMGDAgAED/wjAHkAEGwDEceQCn8tjB7jKQ+sjcGsvaTlEXh0r5RmgUyiVpyNotu9dJDRK7fMtMKJUngMaovcWmCm0HtOV3XsR68AtetQDNFfXHKGYfR4i/OSXZsCAgS8ATwEGAJ4MTc47vCuHAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___BANHAMMER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFAAAARUVFiW8+nIFNNTU1////WEZNygAAAAZ0Uk5T//////8As7+kvwAAAF1JREFUeNrs0zEOACEIBdEvsPe/8pK4ayxVCpuZjuZFjOopJgAAAAAAAAAAgBNAWQVQy3Qf0LzQvNMi4P6P3tMmYGbfaL1NIMahdbZClC4xMt18SPxGAACAxV4BBgAzOE6RHSKDeAAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___BASKET_OF_EXCESS_USED_GRAPHICS_CARDS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFjGw9AAAAnIFNX19fNTU1i3hVUf9a////bzuQfgAAAAh0Uk5T/////////wDeg71ZAAAAc0lEQVR42uzUMQ6AMAwDwLhuy/9/TIKQKLDQILFgL5l88tLa8jImQIAAAQIECBAgQMCXQEMSQNnvU+EOeJFEFgArQIZAJIDoVtIcCGQa8FZ3wTal+5jMghAm+lfAxmSAMqRpQcssOE1A7i0c0Zf2I2AVYAC0CWwMgkb27wAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___BEEHIVE_ON_A_STICK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFOjYo2btHxKc3lcWT5ckmiW8+cVw0////0AhlCAAAAAh0Uk5T/////////wDeg71ZAAAAoElEQVR42uyUsRZDIQhDCUT6/39csKfja19x6RAGHdRLDKI9DsMEEEAAAQQQQAABBJgAIo4BMQFE5LojwT6kzVzrBXnPPwH21AxbKzNnHvQ5wB243Gjf/AdR4ZgoaB9QAG8JPgLUeiUHauTwHdRpeksYA7hN4OgKO9gGlIrpUzZ2GZ2wqYJ2kNdFuNFMJYBuJ93YFh5+KNSnKsDfA54CDABcam2fLMsYLAAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___BLUE_BALLOON =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFUGv/AAAA////S2Lewcv/////3UEM/gAAAAZ0Uk5T//////8As7+kvwAAAIhJREFUeNrs1ksKwCAMBNCMn/tfuUpxIcGFGfDTJmvngSQRJZMlc8dRiwAgtWAG3nwvyFw+KWEOSMIA7QK9cCsQYe2Cyq8FmhBhH+VYC9QyBWqZihCQtwIq/0Ngfxd4QAkO3Ah8YRIdOAEwv4kgP5oIHKCf88XAOH8NMGyiYZAccMCBU4FHgAEALcxMUDaINK4AAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___BLUE_BOXING_GLOVES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFS2LeAAAAQFbNOk65UGv/////l5XVcAAAAAZ0Uk5T//////8As7+kvwAAAIBJREFUeNrs09sOgCAMA9C1zP//ZcFbIgxZ4mv72IyTqWjbz5gAAQIECBAgQICANQCy1GDsS9hbdhAlC7gdQaoegXtwBjgygLMXWs1whXiDJryBet5zwPUEJLpvM3kJM8A6wDyqvzZA2HMJnJNkCIx1dJVxJlnrdxYgQMCTXYABAJm2TLsHrFsVAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___BLUE_FINGERNAIL_POLISH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRFUGv/////mbDXhwAAAAJ0Uk5T/wDltzBKAAAAPUlEQVR42uzRMQoAMAgDwPj/Txc6l1IQHMrpGi+DqeYEAAAAAAAAAACYAdKNZ+/xOI99F8AbAQDA18ASYADZ2w/1RrYn5QAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___BLUE_GARDENER_TROWEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAzs7Or6+vUGv/////pnagNQAAAAV0Uk5T/////wD7tg5TAAAAXklEQVR42uzSQQrAMAhE0VFz/zPXQLtoVrEJgcKflaunqGqLEQAAAAAAAAAAwK8AZVYAWWaC0Nj2BSRRAxRxVxGeMXNVJ9BT9P7u+r6DPkF9BxuvwCsDAAAcBy4BBgBd/D9Pz6sdCgAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___BLUE_MERGE_BEARS_FOAM_FINGER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFUGv/AAAAQFbN////p7KLPAAAAAR0Uk5T////AEAqqfQAAABpSURBVHja7NRBDoAgDETRMt7/zoKNQVeaDhvjn7DlpVBobGYCAAAAAAAAAADgAWi3VIC4pAao71RIKgM61lCqFcisII/gVGDewYou5Poq0N+yCZzfwQBmN34ODKF5I+3lPGKsA2R2AQYAuGQuEx6LJBMAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___BLUE_PURSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAUGv/QFbN6sU3////+r7FoQAAAAV0Uk5T/////wD7tg5TAAAAUElEQVR42uzUIQ4AIAwEwaPl/28mIQ0KAycQ7PpOTlXdTAAAAAAAAAAAAH8DMgGFByi0PzgElvMEmN0DrXKATBPwFkT1bEFXxT8AANg3BBgAk4k+6UUWSXYAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___BLUE_SPATULA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAzs7OUGv/S2Le////To9UdgAAAAV0Uk5T/////wD7tg5TAAAAY0lEQVR42uzTMRKAMAhE0RVy/zMrGR21XOJYfapt8sJAorFYAgAAAAAAAAAA8ADN6gPaZskAHvepgAoOoIi4chyY3cELqLN2B5l5xsxOB+MeulozWN/Cx++AzwQAAPAvsAswAL6sPuEHbd5dAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___BUCKET_OF_BLUE_PAINT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRFAAAA////tLS0UGv/zs7OS2Le////pdOoIQAAAAd0Uk5T////////ABpLA0YAAABzSURBVHja7NRRCsAwCAPQGGvvf+TVwS5gYFBIKBSEPvTDYouBAQMGDBgwYMCAAQN/AsQQAL8bU+CtQAHYEQDmSXEOVL+vGgPB6nCNgTxDMEMA4hwFiAZC6yB0QByhG5gCG6uTC+NtRCchrnP6S7sKeAQYAOTbXaqRV41fAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___BUCKET_OF_RED_PAINT =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRFAAAA////tLS0/1BZzs7O3ktT////nvWR5QAAAAd0Uk5T////////ABpLA0YAAABzSURBVHja7NRRCsAwCAPQGGvvf+TVwS5gYFBIKBSEPvTDYouBAQMGDBgwYMCAAQN/AsQQAL8bU+CtQAHYEQDmSXEOVL+vGgPB6nCNgTxDMEMA4hwFiAZC6yB0QByhG5gCG6uTC+NtRCchrnP6S7sKeAQYAOTbXaqRV41fAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___BURNED_OUT_GRAPHICS_CARD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRF3H4x+sZdX19f3GIxNTU1Uf9a////weq1yAAAAAd0Uk5T////////ABpLA0YAAABiSURBVHja7NNBCoAwDETRGcfm/ke2BbciNrj7A1nmNSRU1YwAAAAAAAAAAL4DvmsbkMvaB1yS1QBkK9PYB9b7eR7hfQezO0kDcHLMdK6QY4wWoOYEpXOF3wgAAADwP3AJMAA5rl7xWBKYYwAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___COLD_STORAGE_WALLET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFkd//csHiv+z/////mxaC1QAAAAR0Uk5T////AEAqqfQAAABHSURBVHja7NPRCcBACATR0eu/55C0MHAQGPf/sYJy5BAQEBAQEBAQEPAnYBcwAHhgDTC2wfBGrfBFAvIO6BcCAgLuAo8AAwA73i+oUn+EFAAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___DOUBLE_DUMBBELLS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAAzs7OwsLC////pe1aBAAAAAR0Uk5T////AEAqqfQAAABeSURBVHja7NOxCoAwDEXRm/j//ywZulRNER0Ubqa8DAcepWwPBwEBAQEBAQEBgQUA9/a3AWpOwtV9BoiAGKn2oLsfgUzIkWpPuntfgbkC6wofeAX/goCAwM+BXYABAKA/LrfTSt8OAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___FRESH_SALMON =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFAAAA05eWwYmJ////R5N01QAAAAR0Uk5T////AEAqqfQAAABwSURBVHja7NPRDoAgCIXhH3r/dw5qqdxF3dXxwo1NPpgo28uFAAECBAgQIEDAf4FyDroA2EyIwOgBkTEAi8CbHWTFCdT8O0DWtxWge4lA6cDoTgH30YJn8GAK7lf+EdB/B+fs112fSYAAAZ8DdgEGANnjL0UHvmSiAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___HAND_IN_A_BLUE_COOKIE_JAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFUGv/AAAAiW8+QFbN////OG/BHwAAAAV0Uk5T/////wD7tg5TAAAAbUlEQVR42uzUQQrAIAxE0Yzp/c9csWIXFqoJtJs/Kzc+Ehm0IxkDAAAAAAAAAAB4BTQd9gDZiJKAK7iC9/y0QrtfataFGSjqQhioUVl+xSdAbQLPTJACrG8QB64exYC7Rx5u4gg/EgDAt8ApwABVnz4SpDFC8gAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___HAND_IN_A_RED_COOKIE_JAR =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRF/1BZAAAAiW8+zUBI////arMh7AAAAAV0Uk5T/////wD7tg5TAAAAbUlEQVR42uzUQQrAIAxE0Yzp/c9csWIXFqoJtJs/Kzc+Ehm0IxkDAAAAAAAAAAB4BTQd9gDZiJKAK7iC9/y0QrtfataFGSjqQhioUVl+xSdAbQLPTJACrG8QB64exYC7Rx5u4gg/EgDAt8ApwABVnz4SpDFC8gAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___HOT_WALLET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF3H4xnIFN3GIxiW8++sZd////EWHDYAAAAAZ0Uk5T//////8As7+kvwAAAGFJREFUeNrs00kOwCAMQ1E3hPtfuYm6RkC9/VaW8GQxaJoRAAAAAAAAAMA5oJkWkOoxACl1UELrAlHEvsNyQe+vcYCIEn6fwXgqEWkCMhvIuMYPMB7S6PAbAQAAAO7yCjAADUtPC7EwRw0AAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___MINERS_PICKAXE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABVQTFRFAAAAoKCgnIFNiW8+gICAzs7O////i+d05QAAAAd0Uk5T////////ABpLA0YAAACnSURBVHja7NVLDoAwCATQabHe/8gWNcakP1pWmunOKC8IiNidBwQIECBAgMAXAAAuACklI9HMIBiJ5jMISniKiC0T8HRBhQBPG01C974KDgAQQwrtLiDGKNs6EPXI+CV6gAg8gIafdVwE5BrkDPSnCa1rPCM9A+TSV2bBDmjnSsEMnJ3PtStSMAJ3eLEEZoBK+HBtvoB6+MTnjKUNzT8TAQK/AQ4BBgCyFV0iMuGRkwAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___NINJA_SWORDS =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRFRUVFWlpaAAAA////5iQ6MgAAAAR0Uk5T////AEAqqfQAAAB3SURBVHja7NNLDoAgDADRAe5/Z0FXQhsxJq6GJW0f5Uf7OBAQEBCIgLrFUVOAHWFKor0U5hSCMIky5pclWBaopF0wok+30OtLBhTuBxgCvb4kQg+s3RHUEwtngKctcCXGGxgwGy8xPwN/o4CAgICAgIDAP8AhwABhiC9FBnlWjwAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___NONE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF////AAAAVcLTfgAAAAF0Uk5TAEDm2GYAAAAdSURBVHja7MGBAAAAAMOg+VPf4ARVAQAAAHwTYAAQQAABpAJfkQAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___PHISHING_NET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAzs7OiW8+nIFN////17HmAwAAAAV0Uk5T/////wD7tg5TAAAAhklEQVR42uzUMQ7AIAxDURNy/zM3JAwtUzETkpn5T64qAT88EHAngDgnAHoc8AC6NTcDC2QfAgvMvh0A2dMLYkD1PDD7RgOzd/4TqucXmGVPLhh9/QVuwat3FoAfLBgDsPYbQPaOpd8DxmV8+/9ADaj3hHyRDHqVBQgQIECAAAECbgEeAQYAIro+ZrPFMXwAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___PHISHING_ROD =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABhQTFRFAAAAiW8+nIFN////pqam6Jr/lpaW////PqdPKAAAAAh0Uk5T/////////wDeg71ZAAAA30lEQVR42uzWQRbCIAxF0QdS2f+OhYJWWlqTcJwonf+blAAH4uDHBCYwgb8GgBEAvHOYgRT3jpsZyHGHGSjdE61AjUcjkMvX5bcAzdobgHXtt5QWaEevB8rsohnI5Zu8DuA1PBtwaF8JHNtXAb32NUC3fTlAv30xUA9utALn5WUA5+VlgD8vLwMu86JfuJ6v/VL9PsAgkHbPELDuvgEg50PADJS8ROgDa/8h3IUAe6CeviSIABZa4Hl5wGeAZTkAb5ePIE8m2l/AXR+fHbCdFXrvHs3Daj40J/AjwEOAAQAGmmh85Os/qAAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFAAAAnIFNiW8+UGv/////////nmBe/wAAAAZ0Uk5T//////8As7+kvwAAAIFJREFUeNrs1EsOgDAIBNCBtve/slTwk7iRstLMGBM2vE4aI0YxIECAAAECBAgQIPBlAKgBEC0Bto8YsAbE/jWkG2AUGgB2cGQOWQCtN7HXH5uQBXpT1difUxpoMuPnW5C/A93j56suAOLxJusNjuSBs8KzwOsP6Rb+kQj8EtgEGABWyU2k+mn+MgAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFAAAAnIFNiW8+/1BZ////////WaG6vQAAAAZ0Uk5T//////8As7+kvwAAAIFJREFUeNrs1EsOgDAIBNCBtve/slTwk7iRstLMGBM2vE4aI0YxIECAAAECBAgQIPBlAKgBEC0Bto8YsAbE/jWkG2AUGgB2cGQOWQCtN7HXH5uQBXpT1difUxpoMuPnW5C/A93j56suAOLxJusNjuSBs8KzwOsP6Rb+kQj8EtgEGABWyU2k+mn+MgAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___PINK_FINGERNAIL_POLISH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF6Jr/////Gn0/cgAAAAJ0Uk5T/wDltzBKAAAAPUlEQVR42uzRMQoAMAgDwPj/Txc6l1IQHMrpGi+DqeYEAAAAAAAAAACYAdKNZ+/xOI99F8AbAQDA18ASYADZ2w/1RrYn5QAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___PINK_PURSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAA6Jr/6sU3yqLV////gFKrOAAAAAV0Uk5T/////wD7tg5TAAAAUElEQVR42uzUIQ4AIAwEwaPw/zeTkAZVAycQ7PpOTlXDTAAAAAAAAAAAAH8DMgGFByhUHxwC23kCrO6BljlAhAl4C3r2bMFQxj8AAKibAgwAqFQ+700k2ukAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___PROOF_OF_RIBEYE_STEAK =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRFAAAAlkBAjVhNq3Jy4dzH////6hv7jQAAAAZ0Uk5T//////8As7+kvwAAAGJJREFUeNrs0zEOACEIRNEB9P5XXuyJIVJs86F1Xoio9rAEAAAAAAAAAAAA8CugGSD5CJC7WX1cvXyYRbY/AxaHKPL9CVY9QHuClV3l25eY+Qlw1uBlvv2QlMVvBAC41CfAACltTwmqMus0AAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___RED_BALLOON =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF/1BZAAAA////3ktT/8HF////KJQlUAAAAAZ0Uk5T//////8As7+kvwAAAIhJREFUeNrs1ksKwCAMBNCMn/tfuUpxIcGFGfDTJmvngSQRJZMlc8dRiwAgtWAG3nwvyFw+KWEOSMIA7QK9cCsQYe2Cyq8FmhBhH+VYC9QyBWqZihCQtwIq/0Ngfxd4QAkO3Ah8YRIdOAEwv4kgP5oIHKCf88XAOH8NMGyiYZAccMCBU4FHgAEALcxMUDaINK4AAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___RED_BOXING_GLOVES =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAABJQTFRF3ktTAAAAuTpBzUBI/1BZ////5XnPCAAAAAZ0Uk5T//////8As7+kvwAAAHlJREFUeNrs0zsOwCAMA9AYp/e/cilIHSCUoK72aEVPER+7fsYECBAgQIAAAQIE7AGQpQZzX8LesoMoWcB6kKpnAP4NOHZAm+IoPDXDFUKgCSNAPwDqODHcjdsRMG2wOJs1sDhEInmNRKqOnjJ6krW+swABAt7cAgwAkflMjo47aC0AAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___RED_FINGERNAIL_POLISH =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAZQTFRF/1BZ////zwu78gAAAAJ0Uk5T/wDltzBKAAAAPUlEQVR42uzRMQoAMAgDwPj/Txc6l1IQHMrpGi+DqeYEAAAAAAAAAACYAdKNZ+/xOI99F8AbAQDA18ASYADZ2w/1RrYn5QAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___RED_GARDENER_TROWEL =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAzs7Or6+v/1BZ////8M3MQAAAAAV0Uk5T/////wD7tg5TAAAAXklEQVR42uzSQQrAMAhE0VFz/zPXQLtoVrEJgcKflaunqGqLEQAAAAAAAAAAwK8AZVYAWWaC0Nj2BSRRAxRxVxGeMXNVJ9BT9P7u+r6DPkF9BxuvwCsDAAAcBy4BBgBd/D9Pz6sdCgAAAABJRU5ErkJggg==";

  string constant ACCESSORIES_ACCESSORY___RED_MERGE_BEARS_FOAM_FINGER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF/1BZAAAAzUBI////ldQ1tgAAAAR0Uk5T////AEAqqfQAAABpSURBVHja7NRBDoAgDETRMt7/zoKNQVeaDhvjn7DlpVBobGYCAAAAAAAAAADgAWi3VIC4pAao71RIKgM61lCqFcisII/gVGDewYou5Poq0N+yCZzfwQBmN34ODKF5I+3lPGKsA2R2AQYAuGQuEx6LJBMAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___RED_PURSE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAA/1BZzUBI6sU3////qDFC5wAAAAV0Uk5T/////wD7tg5TAAAAUElEQVR42uzUIQ4AIAwEwaPl/28mIQ0KAycQ7PpOTlXdTAAAAAAAAAAAAH8DMgGFByi0PzgElvMEmN0DrXKATBPwFkT1bEFXxT8AANg3BBgAk4k+6UUWSXYAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___RED_SPATULA =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAA9QTFRFAAAAzs7O/1BZ3ktT////FwcUVwAAAAV0Uk5T/////wD7tg5TAAAAY0lEQVR42uzTMRKAMAhE0RVy/zMrGR21XOJYfapt8sJAorFYAgAAAAAAAAAA8ADN6gPaZskAHvepgAoOoIi4chyY3cELqLN2B5l5xsxOB+MeulozWN/Cx++AzwQAAPAvsAswAL6sPuEHbd5dAAAAAElFTkSuQmCC";

  string constant ACCESSORIES_ACCESSORY___TOILET_PAPER =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAxQTFRF////AAAAzs7O////E2eUFAAAAAR0Uk5T////AEAqqfQAAABjSURBVHja7NQxDsAwCENRTO9/55auoVIcpkrfO8+EIXENEwAAAAAAAAAAAAAGoCkQmgK7wgcQeQ4oKhMgX2HwBGXl/Ihy+hvg6XfmG8BbYAFqfv8AK+D2NxtU+A8A/gfcAgwAZUAvUaKkyVoAAAAASUVORK5CYII=";

  string constant ACCESSORIES_ACCESSORY___WOODEN_WALKING_CANE =
    "iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAAlQTFRFAAAAiW8+////sfTlzAAAAAN0Uk5T//8A18oNQQAAAElJREFUeNrs1DEOACAIBMGF/z/aGD+goJVLQcckR3FkcxAQEBAQEBAQEBD4BCDmDqoA65Rt4RWQ3Qj1JwoICFwCjjuu3YlDgAEA4kIfmE6EbaEAAAAASUVORK5CYII=";

  function getAsset(uint256 assetNum) external pure returns (string memory) {
    if (assetNum == 0) {
      return ACCESSORIES_ACCESSORY___BALL_AND_CHAIN;
    } else if (assetNum == 1) {
      return ACCESSORIES_ACCESSORY___BAMBOO_SWORD;
    } else if (assetNum == 2) {
      return ACCESSORIES_ACCESSORY___BANHAMMER;
    } else if (assetNum == 3) {
      return ACCESSORIES_ACCESSORY___BASKET_OF_EXCESS_USED_GRAPHICS_CARDS;
    } else if (assetNum == 4) {
      return ACCESSORIES_ACCESSORY___BEEHIVE_ON_A_STICK;
    } else if (assetNum == 5) {
      return ACCESSORIES_ACCESSORY___BLUE_BALLOON;
    } else if (assetNum == 6) {
      return ACCESSORIES_ACCESSORY___BLUE_BOXING_GLOVES;
    } else if (assetNum == 7) {
      return ACCESSORIES_ACCESSORY___BLUE_FINGERNAIL_POLISH;
    } else if (assetNum == 8) {
      return ACCESSORIES_ACCESSORY___BLUE_GARDENER_TROWEL;
    } else if (assetNum == 9) {
      return ACCESSORIES_ACCESSORY___BLUE_MERGE_BEARS_FOAM_FINGER;
    } else if (assetNum == 10) {
      return ACCESSORIES_ACCESSORY___BLUE_PURSE;
    } else if (assetNum == 11) {
      return ACCESSORIES_ACCESSORY___BLUE_SPATULA;
    } else if (assetNum == 12) {
      return ACCESSORIES_ACCESSORY___BUCKET_OF_BLUE_PAINT;
    } else if (assetNum == 13) {
      return ACCESSORIES_ACCESSORY___BUCKET_OF_RED_PAINT;
    } else if (assetNum == 14) {
      return ACCESSORIES_ACCESSORY___BURNED_OUT_GRAPHICS_CARD;
    } else if (assetNum == 15) {
      return ACCESSORIES_ACCESSORY___COLD_STORAGE_WALLET;
    } else if (assetNum == 16) {
      return ACCESSORIES_ACCESSORY___DOUBLE_DUMBBELLS;
    } else if (assetNum == 17) {
      return ACCESSORIES_ACCESSORY___FRESH_SALMON;
    } else if (assetNum == 18) {
      return ACCESSORIES_ACCESSORY___HAND_IN_A_BLUE_COOKIE_JAR;
    } else if (assetNum == 19) {
      return ACCESSORIES_ACCESSORY___HAND_IN_A_RED_COOKIE_JAR;
    } else if (assetNum == 20) {
      return ACCESSORIES_ACCESSORY___HOT_WALLET;
    } else if (assetNum == 21) {
      return ACCESSORIES_ACCESSORY___MINERS_PICKAXE;
    } else if (assetNum == 22) {
      return ACCESSORIES_ACCESSORY___NINJA_SWORDS;
    } else if (assetNum == 23) {
      return ACCESSORIES_ACCESSORY___NONE;
    } else if (assetNum == 24) {
      return ACCESSORIES_ACCESSORY___PHISHING_NET;
    } else if (assetNum == 25) {
      return ACCESSORIES_ACCESSORY___PHISHING_ROD;
    } else if (assetNum == 26) {
      return ACCESSORIES_ACCESSORY___PICNIC_BASKET_WITH_BLUE_AND_WHITE_BLANKET;
    } else if (assetNum == 27) {
      return ACCESSORIES_ACCESSORY___PICNIC_BASKET_WITH_RED_AND_WHITE_BLANKET;
    } else if (assetNum == 28) {
      return ACCESSORIES_ACCESSORY___PINK_FINGERNAIL_POLISH;
    } else if (assetNum == 29) {
      return ACCESSORIES_ACCESSORY___PINK_PURSE;
    } else if (assetNum == 30) {
      return ACCESSORIES_ACCESSORY___PROOF_OF_RIBEYE_STEAK;
    } else if (assetNum == 31) {
      return ACCESSORIES_ACCESSORY___RED_BALLOON;
    } else if (assetNum == 32) {
      return ACCESSORIES_ACCESSORY___RED_BOXING_GLOVES;
    } else if (assetNum == 33) {
      return ACCESSORIES_ACCESSORY___RED_FINGERNAIL_POLISH;
    } else if (assetNum == 34) {
      return ACCESSORIES_ACCESSORY___RED_GARDENER_TROWEL;
    } else if (assetNum == 35) {
      return ACCESSORIES_ACCESSORY___RED_MERGE_BEARS_FOAM_FINGER;
    } else if (assetNum == 36) {
      return ACCESSORIES_ACCESSORY___RED_PURSE;
    } else if (assetNum == 37) {
      return ACCESSORIES_ACCESSORY___RED_SPATULA;
    } else if (assetNum == 38) {
      return ACCESSORIES_ACCESSORY___TOILET_PAPER;
    } else if (assetNum == 39) {
      return ACCESSORIES_ACCESSORY___WOODEN_WALKING_CANE;
    }
    return ACCESSORIES_ACCESSORY___NONE;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsEyes.sol";
import "../Gene.sol";

library OptionEyes {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 eyes = Gene.getGene(TraitDefs.EYES, dna);
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
pragma solidity ^0.8.12;

import "../../lib_constants/TraitDefs.sol";
import "../../lib_constants/trait_options/TraitOptionsBackground.sol";
import "../Gene.sol";

library OptionBackground {
  function getOption(uint256 dna) public pure returns (uint8) {
    uint16 bg = Gene.getGene(TraitDefs.BACKGROUND, dna);
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

library Mainnet {
  address constant ACCESSORIES = 0xa1Bdb3a53686845b399A6d750aC7f0E19AfDb1C0;
  address constant ARMS = 0xb6292ac946E484b8244d41631df06aaD4fe4532b;
  address constant BELLY = 0x784dE9Fc2C9339aFA512818A0e8be88a875D2De1;
  address constant CLOTHINGA = 0x3137f21f8122774a833a4e9A6d97449C9e99b598;
  address constant CLOTHINGB = 0x5F08F899a2DA00f55d825e1BC6eC1b838BdC1362;
  address constant EYES = 0xFae24D1315a8504E38b5236450df125cf135AF05;
  address constant FACE = 0xCFeA75270D63D788ec31AE36e64f84764B52740f;
  address constant FEET = 0x00c2411A35553d9FC65f941e730d3AD3902DB785;
  address constant FOOTWEAR = 0x4384ccFf9bf4e1448976310045144e3B7d17e851;
  address constant HAT = 0xBfbEcfFCa8Df3eaDC73F08d75eB3ac6d5A752bF5;
  address constant HEAD = 0x7262c8A28B614f60BFC2658E30eC9a83159470c6;
  address constant JEWELRY = 0x0ECaC2BA81eC53f5E90Fe639525f16f2B6FC2684;
  address constant MOUTH = 0x132A0d52Ba9BAA55d100d9CD35C477d2558603e2;
  address constant NOSE = 0xE4b59512Ab5c00147a83a6f1Fd9dc7e6aDdd25c6;
  address constant SPECIAL_CLOTHING =
    0x228dc46360537d24139Ee81AFb9235FA2C0CdA07;
  address constant SPECIAL_FACE = 0x44DEdbC44f66a8f36bc89504C342D978D6f876e5;
}