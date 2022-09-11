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

  function animationURI(uint256 dna) external view returns (bytes memory) {
    AssetStrings memory assetStrings;
    TraitOptions memory traitOptions;

    {
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
      traitOptions.eyes = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.EYES,
        dna
      );
      traitOptions.faceAccessory = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.FACE_ACCESSORY,
        dna
      );
    }
    {
      traitOptions.footwear = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.FOOTWEAR,
        dna
      );
      traitOptions.hat = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.HAT,
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
      traitOptions.mouth = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.MOUTH,
        dna
      );
      traitOptions.nose = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.NOSE,
        dna
      );
      traitOptions.species = ITraitsUtility(traitsUtility).getOption(
        TraitDefs.SPECIES,
        dna
      );
    }

    {
      assetStrings.background = divWithBackground(
        UtilAssets.getAssetBackground(traitOptions.background)
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
      assetStrings.head = divWithBackground(
        fetchAssetString(
          LayerOrder.HEAD,
          UtilAssets.getAssetHead(traitOptions.species, traitOptions.locale)
        )
      );
    }
    {
      assetStrings.eyes = divWithBackground(
        fetchAssetString(
          LayerOrder.EYES,
          UtilAssets.getAssetEyes(traitOptions.eyes)
        )
      );
    }
    {
      assetStrings.mouth = divWithBackground(
        fetchAssetString(
          LayerOrder.MOUTH,
          UtilAssets.getAssetMouth(traitOptions.mouth)
        )
      );
    }
    {
      assetStrings.nose = divWithBackground(
        fetchAssetString(
          LayerOrder.NOSE,
          UtilAssets.getAssetNose(traitOptions.nose)
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
    {
      assetStrings.hat = divWithBackground(
        fetchAssetString(
          LayerOrder.HAT,
          UtilAssets.getAssetHat(traitOptions.hat)
        )
      );
    }
    {
      assetStrings.faceAccessory = divWithBackground(
        fetchAssetString(
          LayerOrder.FACE,
          UtilAssets.getAssetFaceAccessory(traitOptions.faceAccessory)
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

    // might need to add special face layer for honey drip
    // fetchAssetString(LayerOrder.EYES, UtilAssets.getAssetEyes(UtilTraits.getOptionEyes(dna)))
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
                '<div class="b h">',
                /***/ assetStrings.head,
                /***/ assetStrings.eyes,
                /***/ assetStrings.mouth,
                /***/ assetStrings.nose,
                '</div>',
                assetStrings.jewelry,
                assetStrings.hat,
                // assetStrings.faceAccessory,
                // assetStrings.accessory,

                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.belly, ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.arms, ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.feet, ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.footwear, ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.clothing, ')"></div>',
                // '<div class="b h">',
                  // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.head, ')"></div>',
                  // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.eyes, ')"></div>',
                  // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.mouth, ')"></div>',
                  // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.nose, ')"></div>',
                // '</div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.jewelry, ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', assetStrings.hat, ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', fetchAssetString(LayerOrder.FACE, UtilAssets.getAssetFaceAccessory(UtilTraits.getOptionFaceAccessory(dna))), ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', fetchAssetString(LayerOrder.SPECIAL_CLOTHING, UtilAssets.getAssetBelly(UtilTraits.getOptionSpecies(dna), UtilTraits.getOptionBelly(dna))), ')"></div>',
                // '<div class="b" style="background-image:url(data:image/png;base64,', fetchAssetString(LayerOrder.ACCESSORIES, UtilAssets.getAssetAccessories(UtilTraits.getOptionAccessories(dna))), ')"></div>',
              '</div>',
            '</body></html>'
          )
        )
      );
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