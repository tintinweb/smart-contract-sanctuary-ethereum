// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

// Assets & Layers
import "../lib_constants/TraitDefs.sol";
import "../lib_env/Mainnet.sol";

// Internal Extensions
import "../extensions/Owner.sol";

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

interface IAnimationUtility {
  function animationURI(uint256 dna) external view returns (bytes memory);
}

interface ITraitsUtility {
  function getOption(uint8 traitDef, uint256 dna) external pure returns (uint8);
}

interface ITraitOptionsLabel {
  function getLabel(uint8 optionNum) external pure returns (string memory);
}

contract Metadata is Owner {
  using Strings for uint256;

  mapping(uint8 => address) public traitOptionLabelContracts;
  address traitsUtility;
  address animationUtility;

  string baseImageURI = "https://www.mergebears.com/api/bears/";

  constructor() {
    // pre-link traitOptionLabel contracts
    traitOptionLabelContracts[TraitDefs.ACCESSORIES] = Mainnet
      .TraitOptionLabelsAccessories;
    traitOptionLabelContracts[TraitDefs.BACKGROUND] = Mainnet
      .TraitOptionLabelsBackground;
    traitOptionLabelContracts[TraitDefs.BELLY] = Mainnet.TraitOptionLabelsBelly;
    traitOptionLabelContracts[TraitDefs.CLOTHING] = Mainnet
      .TraitOptionLabelsClothing;
    traitOptionLabelContracts[TraitDefs.EYES] = Mainnet.TraitOptionLabelsEyes;
    traitOptionLabelContracts[TraitDefs.FACE_ACCESSORY] = Mainnet
      .TraitOptionLabelsFaceAccessory;
    traitOptionLabelContracts[TraitDefs.FOOTWEAR] = Mainnet
      .TraitOptionLabelsFootwear;
    traitOptionLabelContracts[TraitDefs.HAT] = Mainnet.TraitOptionLabelsHat;
    traitOptionLabelContracts[TraitDefs.JEWELRY] = Mainnet
      .TraitOptionLabelsJewelry;
    traitOptionLabelContracts[TraitDefs.LOCALE] = Mainnet
      .TraitOptionLabelsLocale;
    traitOptionLabelContracts[TraitDefs.MOUTH] = Mainnet.TraitOptionLabelsMouth;
    traitOptionLabelContracts[TraitDefs.NOSE] = Mainnet.TraitOptionLabelsNose;
    traitOptionLabelContracts[TraitDefs.SPECIES] = Mainnet
      .TraitOptionLabelsSpecies;

    // Utility linker
    traitsUtility = Mainnet.TraitsUtility;
    animationUtility = Mainnet.Animation;
  }

  function setTraitOptionLabelContract(
    uint8 traitDefId,
    address traitOptionLabelContract
  ) external onlyOwner {
    traitOptionLabelContracts[traitDefId] = traitOptionLabelContract;
  }

  function setTraitsUtility(address traitsUtilityContract) external onlyOwner {
    traitsUtility = traitsUtilityContract;
  }

  function setAnimationUtility(address animationContract) external onlyOwner {
    animationUtility = animationContract;
  }

  function setBaseImageURI(string memory newURI) external onlyOwner {
    baseImageURI = newURI;
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

  function getAttribute(uint8 traitDefId, uint8 traitOptionNum)
    internal
    view
    returns (string memory)
  {
    string memory traitType;
    string memory value = ITraitOptionsLabel(
      traitOptionLabelContracts[traitDefId]
    ).getLabel(traitOptionNum);

    if (traitDefId == TraitDefs.SPECIES) {
      traitType = "Species";
    } else if (traitDefId == TraitDefs.LOCALE) {
      traitType = "Locale";
    } else if (traitDefId == TraitDefs.BELLY) {
      traitType = "Belly";
    } else if (traitDefId == TraitDefs.EYES) {
      traitType = "Eyes";
    } else if (traitDefId == TraitDefs.MOUTH) {
      traitType = "Mouth";
    } else if (traitDefId == TraitDefs.NOSE) {
      traitType = "Nose";
    } else if (traitDefId == TraitDefs.CLOTHING) {
      traitType = "Clothing";
    } else if (traitDefId == TraitDefs.HAT) {
      traitType = "Hat";
    } else if (traitDefId == TraitDefs.JEWELRY) {
      traitType = "Jewelry";
    } else if (traitDefId == TraitDefs.FOOTWEAR) {
      traitType = "Footwear";
    } else if (traitDefId == TraitDefs.ACCESSORIES) {
      traitType = "Accessories";
    } else if (traitDefId == TraitDefs.FACE_ACCESSORY) {
      traitType = "Face Accessory";
    } else if (traitDefId == TraitDefs.BACKGROUND) {
      traitType = "Background";
    }

    return
      string.concat(
        '{ "trait_type": "',
        traitType,
        '",',
        '"value":"',
        value,
        '"}'
      );
  }

  function getAttributes(uint256 dna) internal view returns (string memory) {
    string memory attributes = "";
    // get trait defs from dna
    TraitOptions memory traitOptions = getTraitOptions(dna);

    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.SPECIES, traitOptions.species),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.LOCALE, traitOptions.locale),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.BELLY, traitOptions.belly),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.EYES, traitOptions.eyes),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.MOUTH, traitOptions.mouth),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.NOSE, traitOptions.nose),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.CLOTHING, traitOptions.clothing),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.HAT, traitOptions.hat),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.JEWELRY, traitOptions.jewelry),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.FOOTWEAR, traitOptions.footwear),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.ACCESSORIES, traitOptions.accessories),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.FACE_ACCESSORY, traitOptions.faceAccessory),
      ","
    );
    attributes = string.concat(
      attributes,
      getAttribute(TraitDefs.BACKGROUND, traitOptions.background)
    );

    //must return JSONified array
    return string.concat("[", attributes, "]");
  }

  function getAnimationURI(uint256 dna) public view returns (string memory) {
    return string(IAnimationUtility(animationUtility).animationURI(dna));
  }

  function getMetadataFromDNA(uint256 dna, uint256 tokenId)
    public
    view
    returns (string memory)
  {
    // prettier-ignore
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            abi.encodePacked(
              "{",
                '"name":"MergeBears #', tokenId.toString(), '",',
                '"external_url":"https://www.mergebears.com",',
                '"image":', string.concat('"', baseImageURI, tokenId.toString(), '",'),
                '"animation_url":"', IAnimationUtility(animationUtility).animationURI(dna), '",',
                '"attributes":', getAttributes(dna),
              "}"
            )
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

library Mainnet {
  address constant ACCESSORIES = 0x72b7596E59CfB97661D68024b3c5C587fBc3F0D3;
  address constant ARMS = 0x7e10747a91E45F0fD0C97b763BCcB61030806a69;
  address constant BELLY = 0xf398b7504F01c198942D278EAB8715f0A03D55cb;
  address constant CLOTHINGA = 0x324E15FbDaC47DaF13EaB1fD06C4467D4C7008f9;
  address constant CLOTHINGB = 0x927858Ed8FF2F3E9a09CE9Ca5E9B13523e574fa2;
  address constant EYES = 0x12b538733eFc80BD5D25769AF34B2dA63911BEf8;
  address constant FACE = 0xa8cA38F3BBE56001bE7E3F9768C6e4A0fC2D79cF;
  address constant FEET = 0xE6d17Ff2D51c02f49005B5046f499715aE7E6FF3;
  address constant FOOTWEAR = 0x4384ccFf9bf4e1448976310045144e3B7d17e851;
  address constant HAT = 0xB1A63A1a745E49417BB6E3B226C47af7319664cB;
  address constant HEAD = 0x76Bcf1b35632f59693f8E7D348FcC293aE90f888;
  address constant JEWELRY = 0x151E97911b357fF8EF690107Afbcf6ecBd52D982;
  address constant MOUTH = 0x16Ba2C192391A400b6B6Ee5E46901C737d83Df9D;
  address constant NOSE = 0x6f3cdF8dc2D1915aaAE804325d2c550b959E6B47;
  address constant SPECIAL_CLOTHING =
    0x228dc46360537d24139Ee81AFb9235FA2C0CdA07;
  address constant SPECIAL_FACE = 0x7713D096937d98CDA86Fc80EF10dcAb77367068c;

  // Trait Option Labels
  address constant TraitOptionLabelsAccessories =
    0x7db2Ae5Da12b6891ED08944690B3f4468F68AA71;
  address constant TraitOptionLabelsBackground =
    0x1Dea31e5497f80dE9F4802508D98288ffF834cd9;
  address constant TraitOptionLabelsBelly =
    0xDa97bDb87956fE1D370ab279eF5327c7751D0Bd4;
  address constant TraitOptionLabelsClothing =
    0x42C328934037521E1E08ee3c3E0142aB7E9e8534;
  address constant TraitOptionLabelsEyes =
    0x4acDa10ff43430Ae90eF328555927e9FcFd4904A;
  address constant TraitOptionLabelsFaceAccessory =
    0xfAD91b20182Ad3907074E0043c1212EaE1F7dfaE;
  address constant TraitOptionLabelsFootwear =
    0x435B753316d4bfeF7BB755c3f4fAC202aACaA209;
  address constant TraitOptionLabelsHat =
    0x220d2C51332aafd76261E984e4DA1a43C361A62f;
  address constant TraitOptionLabelsJewelry =
    0x8f69858BD253AcedFFd99479C05Aa37305919ec1;
  address constant TraitOptionLabelsLocale =
    0x13c0B8289bEb260145e981c3201CC2A046F1b83D;
  address constant TraitOptionLabelsMouth =
    0xcb03ebEabc285616CF4aEa7de1333D53f0789141;
  address constant TraitOptionLabelsNose =
    0x03774BA2E684D0872dA02a7da98AfcbebF9E61b2;
  address constant TraitOptionLabelsSpecies =
    0x9FAe2ceBDbfDA7EAeEC3647c16FAE2a4e715e5CA;

  address constant OptionSpecies = 0x5438ae4D244C4a8eAc6Cf9e64D211c19B5835a91;
  address constant OptionAccessories =
    0x1097750D85A2132CAf2DE3be2B97fE56C7DB0bCA;
  address constant OptionClothing = 0xF0B8294279a35bE459cfc257776521A5E46Da0d1;
  address constant OptionLocale = 0xa0F6DdB7B3F114F18073867aE4B740D0AF786721;
  address constant OptionHat = 0xf7C17dB875d8C4ccE301E2c6AF07ab7621204223;
  address constant OptionFaceAccessory =
    0x07E0b24A4070bC0e8198154e430dC9B2FB9B4721;
  address constant OptionFootwear = 0x31b2E83d6fb1d7b9d5C4cdb5ec295167d3525eFF;
  address constant OptionJewelry = 0x9ba79b1fa5A19d31E6cCeEA7De6712992080644B;

  address constant OptionBackground =
    0xC3c5a361d09C54C59340a8aB069b0796C962D2AE;
  address constant OptionBelly = 0xEDf3bAdbb0371bb95dedF567E1a947a0841C5Cc5;
  address constant OptionEyes = 0x4aBeBaBb4F4Fb7A9440E05cBebc55E5Cd160A3aA;
  address constant OptionMouth = 0x9801A9da73fBe2D889c4847BCE25C751Ce334332;
  address constant OptionNose = 0x22116E7ff81752f7b61b4c1d3E0966033939b50f;

  // Utility Contracts
  address constant TraitsUtility = 0xc81Ee07619c8ff65f0E19A214e43b1fd55051FE2;
  address constant Animation = 0x30490f71D70da2C4a96fCCe3C0DBf26eA9B257E3;

  address constant Metadata = 0xA75A58a87BC9Bf862291a2788aeccab8b83E2771;
}

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