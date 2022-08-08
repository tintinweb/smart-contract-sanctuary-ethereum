//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/*
.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。

                                                       s                                            _                                 
                         ..                           :8                                           u                                  
             .u    .    @L           .d``            .88           u.                       u.    88Nu.   u.                u.    u.  
      .    .d88B :@8c  9888i   .dL   @8Ne.   .u     :888ooo  ...ue888b           .    ...ue888b  '88888.o888c      .u     [email protected] [email protected]
 .udR88N  ="8888f8888r `Y888k:*888.  %8888:[email protected]  -*8888888  888R Y888r     .udR88N   888R Y888r  ^8888  8888   ud8888.  ^"8888""8888"
<888'888k   4888>'88"    888E  888I   `888I  888.   8888     888R I888>    <888'888k  888R I888>   8888  8888 :888'8888.   8888  888R 
9888 'Y"    4888> '      888E  888I    888I  888I   8888     888R I888>    9888 'Y"   888R I888>   8888  8888 d888 '88%"   8888  888R 
9888        4888>        888E  888I    888I  888I   8888     888R I888>    9888       888R I888>   8888  8888 8888.+"      8888  888R 
9888       .d888L .+     888E  888I  uW888L  888'  .8888Lu= u8888cJ888     9888      u8888cJ888   .8888b.888P 8888L        8888  888R 
?8888u../  ^"8888*"     x888N><888' '*88888Nu88P   ^%888*    "*888*P"      ?8888u../  "*888*P"     ^Y8888*""  '8888c. .+  "*88*" 8888"
 "8888P'      "Y"        "88"  888  ~ '88888F`       'Y"       'Y"          "8888P'     'Y"          `Y"       "88888%      ""   'Y"  
   "P'                         88F     888 ^                                  "P'                                "YP'                 
                              98"      *8E                                                                                            
                            ./"        '8>                                                                                            
                           ~`           "                                                                                             


.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。.・。.・゜✭・.・✫・゜・。..・。.・゜✭・.・✫・゜・。.✭・.・✫・゜・。..・✫・゜・。
*/

import "./interfaces/INarratorsHutMetadata.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "base64-sol/base64.sol";

contract NarratorsHutMetadata is INarratorsHutMetadata, Ownable {
    string private baseExternalURI;
    string private baseImageURI;
    string private baseExperienceURI;

    mapping(uint256 => Artifact) public artifacts;

    constructor(
        string memory _baseExternalURI,
        string memory _baseImageURI,
        string memory _baseExperienceURI
    ) {
        baseExternalURI = _baseExternalURI;
        baseImageURI = _baseImageURI;
        baseExperienceURI = _baseExperienceURI;
    }

    // ============ ACCESS CONTROL/SANITY MODIFIERS ============

    modifier artifactExists(uint256 artifactId) {
        if (artifactId == 0 || bytes(artifacts[artifactId].name).length == 0) {
            revert ArtifactDoesNotExist();
        }
        _;
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============

    function getArtifactForToken(
        uint256 artifactId,
        uint256 preassignedIndex,
        uint256 tokenId,
        uint256 witchId
    ) public view returns (ArtifactManifestation memory) {
        Artifact memory artifact = artifacts[artifactId];

        AttributeManifestation[]
            memory attributes = pickManifestationsForAttributes(
                artifact,
                preassignedIndex,
                tokenId,
                witchId
            );
        AttunementManifestation[] memory attunements = pickAttunementModifiers(
            artifact,
            tokenId,
            witchId
        );

        return
            ArtifactManifestation({
                name: artifact.name,
                description: artifact.descriptions[preassignedIndex],
                attributes: attributes,
                attunements: attunements,
                witchId: witchId,
                artifactId: artifactId
            });
    }

    function tokenURI(
        uint256 artifactId,
        uint256 preassignedIndex,
        uint256 tokenId,
        uint256 witchId
    ) external view artifactExists(artifactId) returns (string memory) {
        ArtifactManifestation
            memory artifactManifestation = getArtifactForToken(
                artifactId,
                preassignedIndex,
                tokenId,
                witchId
            );

        string memory json = Base64.encode(
            abi.encodePacked(
                "{",
                getHeaderMetadata(artifactManifestation),
                getAttributesMetadata(artifactManifestation),
                getCovenMetadata(artifactManifestation),
                "}"
            )
        );

        return string.concat("data:application/json;base64,", json);
    }

    function canMintArtifact(uint256 artifactId)
        external
        view
        artifactExists(artifactId)
        returns (bool)
    {
        return artifacts[artifactId].mintable == true;
    }

    // ============ INTERNAL HELPER FUNCTIONS ============

    function pickManifestationsForAttributes(
        Artifact memory artifact,
        uint256 preassignedIndex,
        uint256 tokenId,
        uint256 witchId
    ) internal pure returns (AttributeManifestation[] memory) {
        AttributeManifestation[]
            memory manifestations = new AttributeManifestation[](
                artifact.attributes.length
            );
        for (uint256 i = 0; i < artifact.attributes.length; i++) {
            manifestations[i] = pickManifestation(
                artifact.attributes[i],
                preassignedIndex,
                tokenId,
                witchId
            );
        }
        return manifestations;
    }

    function pickManifestation(
        Attribute memory attribute,
        uint256 preassignedIndex,
        uint256 tokenId,
        uint256 witchId
    ) internal pure returns (AttributeManifestation memory) {
        if (attribute.isPreassigned) {
            return
                AttributeManifestation({
                    name: attribute.name,
                    value: attribute.manifestations[preassignedIndex]
                });
        }
        uint256 rand = randomFromSeed(
            string.concat(
                attribute.name,
                Strings.toString(tokenId),
                Strings.toString(witchId)
            )
        );
        return
            AttributeManifestation({
                name: attribute.name,
                value: attribute.manifestations[
                    rand % attribute.manifestations.length
                ]
            });
    }

    function pickAttunementModifiers(
        Artifact memory artifact,
        uint256 tokenId,
        uint256 witchId
    ) internal pure returns (AttunementManifestation[] memory) {
        AttunementManifestation[]
            memory attunementModifiers = new AttunementManifestation[](
                artifact.attunements.length
            );
        for (uint256 i = 0; i < artifact.attunements.length; i++) {
            attunementModifiers[i] = pickAttunementModifier(
                artifact.attunements[i],
                tokenId,
                witchId
            );
        }
        return attunementModifiers;
    }

    function pickAttunementModifier(
        string memory attunement,
        uint256 tokenId,
        uint256 witchId
    ) internal pure returns (AttunementManifestation memory) {
        string memory seed = string.concat(
            attunement,
            Strings.toString(tokenId),
            Strings.toString(witchId)
        );

        uint256 rand = randomFromSeed(seed);
        bool isNegative = randomFromSeed(string.concat(seed, "sign")) % 4 == 0;
        uint256 rarity = rand % 100;

        int256 attunementModifier;
        if (rarity <= 14) {
            attunementModifier = 0;
        } else if (rarity <= 81) {
            attunementModifier = 1;
        } else if (rarity <= 96) {
            attunementModifier = 2;
        } else {
            attunementModifier = 3;
        }

        attunementModifier = isNegative
            ? -attunementModifier
            : attunementModifier;

        return
            AttunementManifestation({
                name: attunement,
                value: attunementModifier
            });
    }

    function randomFromSeed(string memory input)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getHeaderMetadata(
        ArtifactManifestation memory artifactManifestation
    ) internal view returns (string memory) {
        return
            string.concat(
                '"name": "',
                artifactManifestation.name,
                '", "description": "',
                artifactManifestation.description,
                '", "external_url":"',
                getExternalURI(artifactManifestation),
                '", "image": "',
                getImageURI(artifactManifestation),
                '", "animation_url": "',
                getExperienceURI(artifactManifestation),
                '",'
            );
    }

    function getAttributesMetadata(
        ArtifactManifestation memory artifactManifestation
    ) internal pure returns (string memory) {
        string memory output = string.concat('"attributes": [');

        output = string.concat(
            output,
            '{"trait_type": "Artifact", "value": "',
            artifactManifestation.name,
            '"},'
        );

        if (artifactManifestation.witchId > 0) {
            output = string.concat(
                output,
                '{"trait_type": "Witch ID", "value": ',
                Strings.toString(artifactManifestation.witchId),
                "},"
            );
        }

        for (uint256 i; i < artifactManifestation.attributes.length; i++) {
            output = string.concat(
                output,
                '{"trait_type": "',
                artifactManifestation.attributes[i].name,
                '", "value": "',
                artifactManifestation.attributes[i].value,
                '"}'
            );

            if (i < artifactManifestation.attributes.length - 1) {
                output = string.concat(output, ",");
            }
        }

        if (artifactManifestation.attunements.length > 0) {
            output = string.concat(output, ",");
        }

        for (uint256 i; i < artifactManifestation.attunements.length; i++) {
            output = string.concat(
                output,
                '{"display_type": "boost_number", "trait_type": "',
                artifactManifestation.attunements[i].name,
                '", "value": ',
                stringifyAttunementModifier(
                    artifactManifestation.attunements[i].value
                ),
                "}"
            );

            if (i < artifactManifestation.attunements.length - 1) {
                output = string.concat(output, ",");
            }
        }
        return string.concat(output, "],");
    }

    function getCovenMetadata(
        ArtifactManifestation memory artifactManifestation
    ) internal pure returns (string memory) {
        return
            string.concat(
                '"coven": {"name": "',
                artifactManifestation.name,
                '", "description": "',
                artifactManifestation.description,
                '", "witchId": ',
                artifactManifestation.witchId > 0
                    ? Strings.toString(artifactManifestation.witchId)
                    : "null",
                ', "artifactId": ',
                Strings.toString(artifactManifestation.artifactId),
                ", ",
                getCovenAttributesMetadata(artifactManifestation),
                ", ",
                getCovenAttunementsMetadata(artifactManifestation),
                "}"
            );
    }

    function getCovenAttributesMetadata(
        ArtifactManifestation memory artifactManifestation
    ) internal pure returns (string memory) {
        string memory output = string.concat('"attributes": {');
        for (uint256 i; i < artifactManifestation.attributes.length; i++) {
            output = string.concat(
                output,
                '"',
                urlify(artifactManifestation.attributes[i].name),
                '": "',
                urlify(artifactManifestation.attributes[i].value),
                '"'
            );

            if (i < artifactManifestation.attributes.length - 1) {
                output = string.concat(output, ",");
            }
        }
        output = string.concat(output, "}");
        return output;
    }

    function getCovenAttunementsMetadata(
        ArtifactManifestation memory artifactManifestation
    ) internal pure returns (string memory) {
        string memory output = string.concat('"attunements": {');
        for (uint256 i; i < artifactManifestation.attunements.length; i++) {
            output = string.concat(
                output,
                '"',
                urlify(artifactManifestation.attunements[i].name),
                '": ',
                stringifyAttunementModifier(
                    artifactManifestation.attunements[i].value
                )
            );

            if (i < artifactManifestation.attunements.length - 1) {
                output = string.concat(output, ",");
            }
        }
        output = string.concat(output, "}");
        return output;
    }

    function getExternalURI(ArtifactManifestation memory artifactManifestation)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                baseExternalURI,
                "/",
                urlify(artifactManifestation.name),
                getQueryParams(artifactManifestation)
            );
    }

    function getExperienceURI(
        ArtifactManifestation memory artifactManifestation
    ) internal view returns (string memory) {
        return
            string.concat(
                baseExperienceURI,
                "/",
                urlify(artifactManifestation.name),
                getQueryParams(artifactManifestation)
            );
    }

    function getImageURI(ArtifactManifestation memory artifactManifestation)
        internal
        view
        returns (string memory)
    {
        return
            string.concat(
                baseImageURI,
                "/",
                urlify(artifactManifestation.name),
                "_",
                concatenateAttributesAndAttunements(artifactManifestation, "_"),
                ".png"
            );
    }

    function getQueryParams(ArtifactManifestation memory artifactManifestation)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "?",
                concatenateAttributesAndAttunements(artifactManifestation, "&")
            );
    }

    function concatenateAttributesAndAttunements(
        ArtifactManifestation memory artifactManifestation,
        string memory separator
    ) internal pure returns (string memory) {
        string memory output = "";

        if (artifactManifestation.witchId > 0) {
            output = string.concat(
                output,
                "witch-id=",
                Strings.toString(artifactManifestation.witchId),
                separator
            );
        }

        for (uint256 i; i < artifactManifestation.attributes.length; i++) {
            output = string.concat(
                output,
                urlify(artifactManifestation.attributes[i].name),
                "=",
                urlify(artifactManifestation.attributes[i].value),
                separator
            );
        }

        for (uint256 i; i < artifactManifestation.attunements.length; i++) {
            output = string.concat(
                output,
                urlify(artifactManifestation.attunements[i].name),
                "=",
                stringifyAttunementModifier(
                    artifactManifestation.attunements[i].value
                )
            );

            if (i < artifactManifestation.attunements.length - 1) {
                output = string.concat(output, separator);
            }
        }

        return output;
    }

    function stringifyAttunementModifier(int256 attunementModifier)
        internal
        pure
        returns (string memory)
    {
        if (attunementModifier < 0) {
            return
                string.concat(
                    "-",
                    Strings.toString(uint256(-attunementModifier))
                );
        }

        return Strings.toString(uint256(attunementModifier));
    }

    function urlify(string memory a) internal pure returns (string memory) {
        bytes memory b = bytes(a);
        bytes memory result = new bytes(0);

        for (uint256 i; i < b.length; i++) {
            if (b[i] > 0x40 && b[i] < 0x5B) {
                // lowercase any uppercase letters
                result = abi.encodePacked(result, b[i] ^ 0x20);
            } else if (b[i] == 0x20) {
                // remove spaces
                result = abi.encodePacked(result, bytes1(0x2D));
            } else if (
                (b[i] > 0x60 && b[i] < 0x7B) || (b[i] > 0x2F && b[i] < 0x3A)
            ) {
                // add any lowercase letters or numbers without modifications
                result = abi.encodePacked(result, b[i]);
            }
        }

        return string(result);
    }

    // ============ OWNER-ONLY ADMIN FUNCTIONS ============

    function craftArtifact(CraftArtifactData calldata data) external onlyOwner {
        if (bytes(artifacts[data.id].name).length > 0) {
            revert ArtifactHasAlreadyBeenCrafted();
        }
        Artifact storage artifact = artifacts[data.id];
        artifact.name = data.name;

        for (uint256 i; i < data.descriptions.length; ) {
            artifact.descriptions.push(data.descriptions[i]);

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < data.attributes.length; ) {
            artifact.attributes.push(data.attributes[i]);

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < data.attunements.length; ) {
            artifact.attunements.push(data.attunements[i]);

            unchecked {
                ++i;
            }
        }

        artifact.mintable = true;
    }

    function getArtifact(uint256 artifactId)
        external
        view
        onlyOwner
        returns (Artifact memory)
    {
        return artifacts[artifactId];
    }

    function lockArtifacts(uint256[] calldata artifactIds) external onlyOwner {
        for (uint256 i = 0; i < artifactIds.length; i++) {
            artifacts[artifactIds[i]].mintable = false;
        }
    }

    function setBaseExternalURI(string calldata _baseExternalURI)
        external
        onlyOwner
    {
        baseExternalURI = _baseExternalURI;
    }

    function setBaseImageURI(string calldata _baseImageURI) external onlyOwner {
        baseImageURI = _baseImageURI;
    }

    function setBaseExperienceURI(string calldata _baseExperienceURI)
        external
        onlyOwner
    {
        baseExperienceURI = _baseExperienceURI;
    }

    // ============ ERRORS ============

    error ArtifactDoesNotExist();
    error ArtifactHasAlreadyBeenCrafted();
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

struct CraftArtifactData {
    uint256 id;
    string name;
    string[] descriptions;
    string[] attunements;
    Attribute[] attributes;
}

struct Artifact {
    bool mintable;
    string name;
    string[] descriptions;
    string[] attunements;
    Attribute[] attributes;
}

struct ArtifactManifestation {
    string name;
    string description;
    AttunementManifestation[] attunements;
    AttributeManifestation[] attributes;
    uint256 witchId;
    uint256 artifactId;
}

struct Attribute {
    string name;
    bool isPreassigned;
    string[] manifestations;
}

struct AttributeManifestation {
    string name;
    string value;
}

struct AttunementManifestation {
    string name;
    int256 value;
}

interface INarratorsHutMetadata {
    function getArtifactForToken(
        uint256 artifactId,
        uint256 preassignedIndex,
        uint256 tokenId,
        uint256 witchId
    ) external view returns (ArtifactManifestation memory);

    function tokenURI(
        uint256 artifactId,
        uint256 preassignedAttributeIndex,
        uint256 tokenId,
        uint256 witchId
    ) external view returns (string memory);

    function canMintArtifact(uint256 artifactId) external view returns (bool);

    function craftArtifact(CraftArtifactData calldata data) external;

    function getArtifact(uint256 artifactId)
        external
        view
        returns (Artifact memory);

    function lockArtifacts(uint256[] calldata artifactIds) external;

    function setBaseExternalURI(string calldata _baseExternalURI) external;

    function setBaseImageURI(string calldata _baseImageURI) external;

    function setBaseExperienceURI(string calldata _baseExperienceURI) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

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