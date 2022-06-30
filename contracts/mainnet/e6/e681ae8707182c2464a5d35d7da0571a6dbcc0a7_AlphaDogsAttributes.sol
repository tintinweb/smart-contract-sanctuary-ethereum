// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Strings} from "@openzeppelin/utils/Strings.sol";
import {MetadataHelpers} from "./libraries/MetadataHelpers.sol";
import {Base64} from "./libraries/Base64.sol";
import {Gene} from "./libraries/Gene.sol";
import {IAlphaDogsAttributes} from "./interfaces/IAlphaDogsAttributes.sol";
import {IAlphaDogs} from "./interfaces/IAlphaDogs.sol";

// Generated code. Do not modify!
contract AlphaDogsAttributes is IAlphaDogsAttributes, Ownable {
    using Strings for uint256;
    using Gene for uint256;

    error NotChanged();

    bytes32 private constant EMPTY_STRING = keccak256("");

    /// @notice the base URI of the nft image
    string public imageBaseURI;

    constructor(string memory _imageBaseURI) {
        imageBaseURI = _imageBaseURI;
    }

    function setBaseURI(string calldata _imageBaseURI) external onlyOwner {
        if (keccak256(bytes(_imageBaseURI)) == keccak256(bytes(imageBaseURI)))
            revert NotChanged();
        imageBaseURI = _imageBaseURI;
    }

    function tokenURI(
        uint256 gene,
        bytes memory name,
        string memory lore
    ) public view override returns (string memory) {
        string memory metadata = makeMetadata(gene, name, lore);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(metadata))
                )
            );
    }

    function makeMetadata(
        uint256 gene,
        bytes memory name,
        string memory lore
    ) internal view returns (string memory) {
        if (keccak256(bytes(name)) == EMPTY_STRING) {
            name = defaultName(gene);
        }

        return
            MetadataHelpers.makeMetadata(
                name,
                lore,
                abi.encodePacked(imageBaseURI, gene.toString()),
                makeAttributes(gene)
            );
    }

    function makeAttributes(uint256 gene)
        internal
        pure
        returns (string memory)
    {
        string[] memory attributes = new string[](8);
        attributes[0] = MetadataHelpers.makeAttributeJSON(
            "Generation",
            gene.isPuppy() ? "Puppy" : "Genesis"
        );

        attributes[1] = MetadataHelpers.makeAttributeJSON(
            "Background",
            getBackgroundValue(gene)
        );
        attributes[2] = MetadataHelpers.makeAttributeJSON(
            "Fur",
            getFurValue(gene)
        );
        attributes[3] = MetadataHelpers.makeAttributeJSON(
            "Neck",
            getNeckValue(gene)
        );
        attributes[4] = MetadataHelpers.makeAttributeJSON(
            "Eyes",
            getEyesValue(gene)
        );
        attributes[5] = MetadataHelpers.makeAttributeJSON(
            "Hat",
            getHatValue(gene)
        );
        attributes[6] = MetadataHelpers.makeAttributeJSON(
            "Mouth",
            getMouthValue(gene)
        );
        attributes[7] = MetadataHelpers.makeAttributeJSON(
            "Nosering",
            getNoseringValue(gene)
        );

        return MetadataHelpers.makeAttributeListJSON(attributes);
    }

    function defaultName(uint256 gene) internal pure returns (bytes memory) {
        if (gene.isPuppy()) {
            // Ignore puppy flag
            return
                abi.encodePacked(
                    "Puppy #",
                    (gene & 0xFFFFFFFFFFFFFF).toHexString()
                );
        }

        return abi.encodePacked("Genesis #", gene.toHexString());
    }

    function getBackgroundValue(uint256 gene)
        public
        pure
        returns (string memory)
    {
        uint256 chromossome = gene.getBackground();
        if (chromossome == 0) {
            return "Winter";
        }
        if (chromossome == 1) {
            return "Space";
        }
        if (chromossome == 2) {
            return "Night Forest";
        }
        if (chromossome == 3) {
            return "Dreams";
        }
        if (chromossome == 4) {
            return "Snowy Mountains";
        }
        if (chromossome == 5) {
            return "Stars";
        }
        if (chromossome == 6) {
            return "Inferno";
        }
        if (chromossome == 7) {
            return "Woods";
        }
        if (chromossome == 8) {
            return "Alpha System";
        }
        if (chromossome == 9) {
            return "Red Moon";
        }
        if (chromossome == 10) {
            return "Castle";
        }
        if (chromossome == 11) {
            return "Evening";
        }
        if (chromossome == 12) {
            return "Lightining";
        }
        if (chromossome == 13) {
            return "Pink Clouds";
        }
        if (chromossome == 14) {
            return "Night City";
        }
        if (chromossome == 15) {
            return "Underwater";
        }
        if (chromossome == 16) {
            return "Cute Sky";
        }
        if (chromossome == 17) {
            return "Alpha City";
        }
        if (chromossome == 18) {
            return "Cozy Room";
        }
        if (chromossome == 19) {
            return "Clouds";
        }
        if (chromossome == 20) {
            return "Crystal Cave";
        }
        return "";
    }

    function getFurValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getFur();
        if (chromossome == 0) {
            return "Golden";
        }
        if (chromossome == 1) {
            return "Red";
        }
        if (chromossome == 2) {
            return "Snow";
        }
        if (chromossome == 3) {
            return "Brown";
        }
        if (chromossome == 4) {
            return "Grey";
        }
        if (chromossome == 5) {
            return "Radioactive";
        }
        if (chromossome == 6) {
            return "Pink";
        }
        if (chromossome == 7) {
            return "Purple";
        }
        if (chromossome == 8) {
            return "Orange";
        }
        if (chromossome == 9) {
            return "Black";
        }
        if (chromossome == 10) {
            return "Blue";
        }
        if (chromossome == 11) {
            return "Dark";
        }
        return "";
    }

    function getNeckValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getNeck();
        if (chromossome == 0) {
            return "White Polo";
        }
        if (chromossome == 1) {
            return "Black Hoodie";
        }
        if (chromossome == 2) {
            return "Purple Hoodie";
        }
        if (chromossome == 3) {
            return "Blue Sports Hoodie";
        }
        if (chromossome == 4) {
            return "None";
        }
        if (chromossome == 5) {
            return "Blue Bowtie";
        }
        if (chromossome == 6) {
            return "Green Jacket";
        }
        if (chromossome == 7) {
            return "Stars";
        }
        if (chromossome == 8) {
            return "Red Scarf";
        }
        if (chromossome == 9) {
            return "Red Hoodie";
        }
        if (chromossome == 10) {
            return "Bronze Medal";
        }
        if (chromossome == 11) {
            return "Pattern";
        }
        if (chromossome == 12) {
            return "Silver Chain";
        }
        if (chromossome == 13) {
            return "Caesar";
        }
        if (chromossome == 14) {
            return "Golden Bowtie";
        }
        if (chromossome == 15) {
            return "Half Hoodie";
        }
        if (chromossome == 16) {
            return "Golden Chain";
        }
        if (chromossome == 17) {
            return "AD Golden Chain";
        }
        if (chromossome == 18) {
            return "Dog Tag";
        }
        if (chromossome == 19) {
            return "Golden Spikes";
        }
        if (chromossome == 20) {
            return "Silver Medal";
        }
        if (chromossome == 21) {
            return "Red Bowtie";
        }
        if (chromossome == 22) {
            return "Army Hoddie";
        }
        if (chromossome == 23) {
            return "Anime";
        }
        if (chromossome == 24) {
            return "Brown Jacket";
        }
        if (chromossome == 25) {
            return "Fire Hoodie";
        }
        if (chromossome == 26) {
            return "Leonhart Jacket";
        }
        if (chromossome == 27) {
            return "Red Polo";
        }
        if (chromossome == 28) {
            return "Red Jacket";
        }
        if (chromossome == 29) {
            return "Golden Medal";
        }
        if (chromossome == 30) {
            return "Tie Dye Hoddie";
        }
        if (chromossome == 31) {
            return "Emo Hoodie";
        }
        if (chromossome == 32) {
            return "AD Silver Chain";
        }
        if (chromossome == 33) {
            return "Purple Scarf";
        }
        return "";
    }

    function getEyesValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getEyes();
        if (chromossome == 0) {
            return "3D Glasses";
        }
        if (chromossome == 1) {
            return "ET Sunglasses";
        }
        if (chromossome == 2) {
            return "Embarrassed";
        }
        if (chromossome == 3) {
            return "Laser";
        }
        if (chromossome == 4) {
            return "Normal";
        }
        if (chromossome == 5) {
            return "Not Happy";
        }
        if (chromossome == 6) {
            return "Yellow Glasses";
        }
        if (chromossome == 7) {
            return "Purple";
        }
        if (chromossome == 8) {
            return "Gimme Food";
        }
        if (chromossome == 9) {
            return "Very Happy";
        }
        if (chromossome == 10) {
            return "Green Visor";
        }
        if (chromossome == 11) {
            return "Sweat Drop";
        }
        if (chromossome == 12) {
            return "Closed";
        }
        if (chromossome == 13) {
            return "Looking Up";
        }
        if (chromossome == 14) {
            return "Rainbow Glasses";
        }
        if (chromossome == 15) {
            return "Shy";
        }
        if (chromossome == 16) {
            return "Golden Monocle";
        }
        if (chromossome == 17) {
            return "Slim Green Glasses";
        }
        if (chromossome == 18) {
            return "Red Visor";
        }
        if (chromossome == 19) {
            return "High";
        }
        if (chromossome == 20) {
            return "Red Eyes";
        }
        if (chromossome == 21) {
            return "Golden Glasses";
        }
        if (chromossome == 22) {
            return "Angry";
        }
        if (chromossome == 23) {
            return "Shades";
        }
        if (chromossome == 24) {
            return "Crying";
        }
        if (chromossome == 25) {
            return "Golden Sunglasses";
        }
        if (chromossome == 26) {
            return "White Eyes";
        }
        if (chromossome == 27) {
            return "Edgy";
        }
        if (chromossome == 28) {
            return "Purple Glasses";
        }
        if (chromossome == 29) {
            return "Big Eyes";
        }
        if (chromossome == 30) {
            return "Slim Pink Glasses";
        }
        if (chromossome == 31) {
            return "Heart Glasses";
        }
        if (chromossome == 32) {
            return "Moon";
        }
        if (chromossome == 33) {
            return "Black Rim";
        }
        if (chromossome == 34) {
            return "Sleeping";
        }
        if (chromossome == 35) {
            return "Heart Eyes";
        }
        if (chromossome == 36) {
            return "Robot";
        }
        if (chromossome == 37) {
            return "Red Glasses";
        }
        if (chromossome == 38) {
            return "Distrust";
        }
        if (chromossome == 39) {
            return "Anime";
        }
        if (chromossome == 40) {
            return "Eye Patch";
        }
        if (chromossome == 41) {
            return "Scott's";
        }
        if (chromossome == 42) {
            return "VR";
        }
        return "";
    }

    function getHatValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getHat();
        if (chromossome == 0) {
            return "Airforce";
        }
        if (chromossome == 1) {
            return "Magical Crown";
        }
        if (chromossome == 2) {
            return "Blue Pirate";
        }
        if (chromossome == 3) {
            return "Poke Cap";
        }
        if (chromossome == 4) {
            return "Aviator";
        }
        if (chromossome == 5) {
            return "Purple Cap";
        }
        if (chromossome == 6) {
            return "Pink Pocker";
        }
        if (chromossome == 7) {
            return "Bitten";
        }
        if (chromossome == 8) {
            return "Purple Beanie";
        }
        if (chromossome == 9) {
            return "Goggles";
        }
        if (chromossome == 10) {
            return "Silver Earring";
        }
        if (chromossome == 11) {
            return "None";
        }
        if (chromossome == 12) {
            return "Alpha Cap";
        }
        if (chromossome == 13) {
            return "Trainer Cap";
        }
        if (chromossome == 14) {
            return "Creepy Mage";
        }
        if (chromossome == 15) {
            return "Black Bucket Hat";
        }
        if (chromossome == 16) {
            return "AD Cap";
        }
        if (chromossome == 17) {
            return "Red Mohawk";
        }
        if (chromossome == 18) {
            return "White Bucket Hat";
        }
        if (chromossome == 19) {
            return "Pink Cloth";
        }
        if (chromossome == 20) {
            return "Angel";
        }
        if (chromossome == 21) {
            return "Navy";
        }
        if (chromossome == 22) {
            return "Classic Witch";
        }
        if (chromossome == 23) {
            return "Straw Hat";
        }
        if (chromossome == 24) {
            return "Black Pocker";
        }
        if (chromossome == 25) {
            return "Red Dog Bucket";
        }
        if (chromossome == 26) {
            return "Ninja Bandana";
        }
        if (chromossome == 27) {
            return "Golden Skull";
        }
        if (chromossome == 28) {
            return "Caesar";
        }
        if (chromossome == 29) {
            return "Leprechaun";
        }
        if (chromossome == 30) {
            return "Black Fedora";
        }
        if (chromossome == 31) {
            return "Top Hat";
        }
        if (chromossome == 32) {
            return "Pirate";
        }
        if (chromossome == 33) {
            return "Black Cap";
        }
        if (chromossome == 34) {
            return "Concussion";
        }
        if (chromossome == 35) {
            return "Arrow";
        }
        if (chromossome == 36) {
            return "BrownGreen Cap";
        }
        if (chromossome == 37) {
            return "Yellow Beanie";
        }
        if (chromossome == 38) {
            return "Gray Fedora";
        }
        if (chromossome == 39) {
            return "Fairy";
        }
        if (chromossome == 40) {
            return "Wizzard";
        }
        if (chromossome == 41) {
            return "Red Pocker";
        }
        if (chromossome == 42) {
            return "Frankie";
        }
        if (chromossome == 43) {
            return "BlackRed Cap";
        }
        if (chromossome == 44) {
            return "Blue Cap";
        }
        if (chromossome == 45) {
            return "Black Beanie";
        }
        if (chromossome == 46) {
            return "White Fedora";
        }
        if (chromossome == 47) {
            return "Cowboy";
        }
        if (chromossome == 48) {
            return "Red Beanie";
        }
        if (chromossome == 49) {
            return "Green Beanie";
        }
        if (chromossome == 50) {
            return "Robin";
        }
        if (chromossome == 51) {
            return "Destroyed";
        }
        if (chromossome == 52) {
            return "Red Crown";
        }
        if (chromossome == 53) {
            return "Purple Pocker";
        }
        if (chromossome == 54) {
            return "Black Cloth";
        }
        if (chromossome == 55) {
            return "Golden Earring";
        }
        if (chromossome == 56) {
            return "Officer";
        }
        if (chromossome == 57) {
            return "Blue Beanie";
        }
        if (chromossome == 58) {
            return "Blue Bucket Hat";
        }
        if (chromossome == 59) {
            return "Green Mohawk";
        }
        if (chromossome == 60) {
            return "Red Pirate";
        }
        if (chromossome == 61) {
            return "Golden Egg";
        }
        if (chromossome == 62) {
            return "Green Pocker";
        }
        if (chromossome == 63) {
            return "Big Crown";
        }
        if (chromossome == 64) {
            return "Army Cap";
        }
        if (chromossome == 65) {
            return "Tie Dye Bucket Hat";
        }
        if (chromossome == 66) {
            return "Half Bucket hat";
        }
        if (chromossome == 67) {
            return "Anime Bucket Hat";
        }
        return "";
    }

    function getMouthValue(uint256 gene) public pure returns (string memory) {
        uint256 chromossome = gene.getMouth();
        if (chromossome == 0) {
            return "Biscuit";
        }
        if (chromossome == 1) {
            return "Sticking Tongue";
        }
        if (chromossome == 2) {
            return "None";
        }
        if (chromossome == 3) {
            return "Premium Cigar";
        }
        if (chromossome == 4) {
            return "Tiny Fang";
        }
        if (chromossome == 5) {
            return "Smoking Pipe";
        }
        if (chromossome == 6) {
            return "Homemade";
        }
        if (chromossome == 7) {
            return "Blood Fangs";
        }
        if (chromossome == 8) {
            return "Ball";
        }
        if (chromossome == 9) {
            return "Vape";
        }
        if (chromossome == 10) {
            return "Coin";
        }
        if (chromossome == 11) {
            return "Steak";
        }
        if (chromossome == 12) {
            return "Bone";
        }
        if (chromossome == 13) {
            return "Drooling";
        }
        if (chromossome == 14) {
            return "Donut";
        }
        if (chromossome == 15) {
            return "Frisbee";
        }
        if (chromossome == 16) {
            return "Fang";
        }
        if (chromossome == 17) {
            return "Cigarrete";
        }
        return "";
    }

    function getNoseringValue(uint256 gene)
        public
        pure
        returns (string memory)
    {
        uint256 chromossome = gene.getNosering();
        if (chromossome == 0) {
            return "None";
        }
        if (chromossome == 1) {
            return "Golden";
        }
        if (chromossome == 2) {
            return "Bronze";
        }
        if (chromossome == 3) {
            return "Silver";
        }
        return "";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

// solhint-disable quotes
library MetadataHelpers {
    function makeMetadata(
        bytes memory name,
        string memory description,
        bytes memory image,
        string memory attributes
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    name,
                    '","description":"',
                    description,
                    '","image":"',
                    image,
                    '","attributes":',
                    attributes,
                    "}"
                )
            );
    }

    function makeAttributeJSON(string memory traitType, string memory value)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '{"trait_type":"',
                    traitType,
                    '","value":"',
                    value,
                    '"}'
                )
            );
    }

    function makeAttributeListJSON(string[] memory attributes)
        internal
        pure
        returns (string memory)
    {
        bytes memory attributeListBytes = "[";

        for (uint256 i = 0; i < attributes.length; i++) {
            attributeListBytes = abi.encodePacked(
                attributeListBytes,
                attributes[i],
                i != attributes.length - 1 ? "," : "]"
            );
        }

        return string(attributeListBytes);
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
///         Source: https://github.com/Brechtpd/base64/blob/4d85607b18d981acff392d2e99ba654305552a97/base64.sol
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

/// @title  AlphaDogs Gene Library
/// @author Aleph Retamal <github.com/alephao>
/// @notice Library containing functions for querying info about a gene.
library Gene {
    /// @notice A gene is puppy if its 8th byte is greater than 0
    function isPuppy(uint256 gene) internal pure returns (bool) {
        return (gene & 0xFF00000000000000) > 0;
    }

    /// @notice Get a specific chromossome in a gene, first position is 0
    function getChromossome(uint256 gene, uint32 position)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint32 shift = 8 * position;
            return (gene & (0xFF << shift)) >> shift;
        }
    }

    function getBackground(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 6);
    }

    function getFur(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 5);
    }

    function getNeck(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 4);
    }

    function getEyes(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 3);
    }

    function getHat(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 2);
    }

    function getMouth(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 1);
    }

    function getNosering(uint256 gene) internal pure returns (uint256) {
        return getChromossome(gene, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsAttributes {
    function tokenURI(
        uint256 id,
        bytes memory name,
        string memory lore
    ) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

import {IAlphaDogsEvents} from "./IAlphaDogsEvents.sol";
import {IAlphaDogsErrors} from "./IAlphaDogsErrors.sol";

interface IAlphaDogs is IAlphaDogsEvents, IAlphaDogsErrors {
    struct CustomMetadata {
        string name;
        string lore;
    }

    struct Stake {
        address owner;
        uint96 stakedAt;
    }

    // mapping(uint256 => CustomMetadata) getMetadata;
    function getMetadata(uint256 id)
        external
        view
        returns (CustomMetadata memory);

    function setName(uint256 id, string calldata newName) external;

    function setLore(uint256 id, string calldata newLore) external;

    function stake(uint256[] calldata tokenIds) external;

    function unstake(uint256[] calldata tokenIds) external;

    function claim(uint256[] calldata tokenIds) external;

    function premint(bytes32[] calldata proof) external;

    function mint() external;

    function breed(uint256 mom, uint256 dad) external;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsEvents {
    event NameChanged(uint256 indexed id, string name);
    event LoreChanged(uint256 indexed id, string lore);
    event Breeded(uint256 indexed child, uint256 mom, uint256 dad);
    event Staked(uint256 indexed id);
    event Unstaked(uint256 indexed id, uint256 amount);
    event ClaimedTokens(uint256 indexed id, uint256 amount);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IAlphaDogsErrors {
    /// @dev 0x2783839d
    error InsufficientTokensAvailable();
    /// @dev 0x154e0758
    error InsufficientReservedTokensAvailable();
    /// @dev 0x8152a42e
    error InsufficientNonReservedTokensAvailable();
    /// @dev 0x53bb24f9
    error TokenLimitReached();
    /// @dev 0xb05e92fa
    error InvalidMerkleProof();
    /// @dev 0x2c5211c6
    error InvalidAmount();
    /// @dev 0x50e55ae1
    error InvalidAmountToClaim();
    /// @dev 0x6aa2a937
    error InvalidTokenID();
    /// @dev 0x1ae3550b
    error InvalidNameLength();
    /// @dev 0x8a0fcaee
    error InvalidSameValue();
    /// @dev 0x2a7c6b6e
    error InvalidTokenOwner();
    /// @dev 0x8e8ede30
    error FusionWithSameParentsForbidden();
    /// @dev 0x6d074376
    error FusionWithPuppyForbidden();
    /// @dev 0x36a1c33f
    error NotChanged();
    /// @dev 0x80cb55e2
    error NotActive();
    /// @dev 0xb4fa3fb3
    error InvalidInput();
    /// @dev 0xddb5de5e
    error InvalidSender();
    /// @dev 0x21029e82
    error InvalidChar();
}