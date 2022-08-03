// SPDX-License-Identifier: MPL-2.0

/*
CrypToadz Created By:
  ___  ____  ____  __  __  ____  __    ____  _  _ 
 / __)(  _ \( ___)(  \/  )(  _ \(  )  (_  _)( \( )
( (_-. )   / )__)  )    (  )___/ )(__  _)(_  )  ( 
 \___/(_)\_)(____)(_/\/\_)(__)  (____)(____)(_)\_) 
(https://cryptoadz.io)

CrypToadzChained Programmed By:
 __      __         __    __                 
/  \    /  \_____ _/  |__/  |_  _________.__.
\   \/\/   /\__  \\   __\   __\/  ___<   |  |
 \        /  / __ \|  |  |  |  \___ \ \___  |
  \__/\  /  (____  /__|  |__| /____  >/ ____|
       \/        \/                \/ \/     
(https://wattsy.art)
*/

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@divergencetech/ethier/contracts/random/PRNG.sol";

import "./IERC721.sol";
import "./ICrypToadzStrings.sol";
import "./ICrypToadzBuilder.sol";
import "./ICrypToadzMetadata.sol";
import "./ICrypToadzCustomImages.sol";
import "./ICrypToadzCustomAnimations.sol";

import "./PixelRenderer.sol";
import "./Presentation.sol";

contract CrypToadzChained is Ownable, IERC721, IERC165 {
    using ERC165Checker for address;

    bytes private constant JSON_URI_PREFIX = "data:application/json;base64,";
    bytes private constant PNG_URI_PREFIX = "data:image/png;base64,";
    bytes private constant GIF_URI_PREFIX = "data:image/gif;base64,";
    bytes private constant SVG_URI_PREFIX = "data:image/svg+xml;base64,";

    bytes private constant DESCRIPTION = "A small, warty, amphibious creature that resides in the metaverse.";
    bytes private constant EXTERNAL_URL = "https://cryptoadz.io";
    bytes private constant NAME = "CrypToadz";

    string private constant LEGACY_URI_NOT_FOUND = "ERC721Metadata: URI query for nonexistent token";

    /** @notice Contract responsible for building non-custom toadz images. */
    ICrypToadzBuilder public builder;

    /**
    @notice Flag to disable use of setBuilder().
     */
    bool public builderLocked = false;

    /**
    @notice Permanently sets the builderLocked flag to true.
     */
    function lockBuilder() external onlyOwner {
        require(
            address(builder).supportsInterface(
                type(ICrypToadzBuilder).interfaceId
            ),
            "Not ICrypToadzBuilder"
        );
        builderLocked = true;
    }

    /**
    @notice Sets the address of the builder contract.
    @dev No checks are performed when setting, but lockBuilder() ensures that
    the final address implements the ICrypToadzBuilder interface.
     */
    function setBuilder(address _builder) external onlyOwner {
        require(!builderLocked, "Builder locked");
        builder = ICrypToadzBuilder(_builder);
    }

    /** @notice Contract responsible for looking up metadata. */
    ICrypToadzMetadata public metadata;

    /**
    @notice Flag to disable use of setMetadata().
     */
    bool public metadataLocked = false;

    /**
    @notice Permanently sets the metadataLocked flag to true.
     */
    function lockMetadata() external onlyOwner {
        require(
            address(metadata).supportsInterface(
                type(ICrypToadzMetadata).interfaceId
            ),
            "Not ICrypToadzMetadata"
        );
        metadataLocked = true;
    }

    /**
    @notice Sets the address of the metadata provider contract.
    @dev No checks are performed when setting, but lockMetadata() ensures that
    the final address implements the ICrypToadzMetadata interface.
     */
    function setMetadata(address _metadata) external onlyOwner {
        require(!metadataLocked, "Metadata locked");
        metadata = ICrypToadzMetadata(_metadata);
    }

    /** @notice Contract responsible for looking up strings. */
    ICrypToadzStrings public strings;

    /**
    @notice Flag to disable use of setStrings().
     */
    bool public stringsLocked = false;

    /**
    @notice Permanently sets the stringsLocked flag to true.
     */
    function lockStrings() external onlyOwner {
        require(
            address(strings).supportsInterface(
                type(ICrypToadzStrings).interfaceId
            ),
            "Not ICrypToadzStrings"
        );
        stringsLocked = true;
    }

    /**
    @notice Sets the address of the string provider contract.
    @dev No checks are performed when setting, but lockStrings() ensures that
    the final address implements the ICrypToadzStrings interface.
     */
    function setStrings(address _strings) external onlyOwner {
        require(!stringsLocked, "Strings locked");
        strings = ICrypToadzStrings(_strings);
    }

    /** @notice Contract responsible for rendering custom images. */
    ICrypToadzCustomImages public customImages;

    /**
    @notice Flag to disable use of setCustomImages().
     */
    bool public customImagesLocked = false;

    /**
    @notice Permanently sets the customImagesLocked flag to true.
     */
    function lockCustomImages() external onlyOwner {
        require(
            address(customImages).supportsInterface(
                type(ICrypToadzCustomImages).interfaceId
            ),
            "Not ICrypToadzCustomImages"
        );
        customImagesLocked = true;
    }

    /**
    @notice Sets the address of the custom images contract.
    @dev No checks are performed when setting, but lockCustomImages() ensures that
    the final address implements the ICrypToadzCustomImages interface.
     */
    function setCustomImages(address _customImages) external onlyOwner {
        require(!customImagesLocked, "CustomImages locked");
        customImages = ICrypToadzCustomImages(_customImages);
    }

    /** @notice Contract responsible for rendering custom animations. */
    ICrypToadzCustomAnimations public customAnimations;

    /**
    @notice Flag to disable use of setCustomAnimations().
     */
    bool public customAnimationsLocked = false;

    /**
    @notice Permanently sets the customAnimationsLocked flag to true.
     */
    function lockCustomAnimations() external onlyOwner {
        require(
            address(customAnimations).supportsInterface(
                type(ICrypToadzCustomAnimations).interfaceId
            ),
            "Not ICrypToadzCustomAnimations"
        );
        customAnimationsLocked = true;
    }

    /**
    @notice Sets the address of the custom animations contract.
    @dev No checks are performed when setting, but lockCustomAnimations() ensures that
    the final address implements the ICrypToadzCustomAnimations interface.
     */
    function setCustomAnimations(address _customAnimations) external onlyOwner {
        require(!customAnimationsLocked, "CustomAnimations locked");
        customAnimations = ICrypToadzCustomAnimations(_customAnimations);
    }

    /** @notice Contract responsible for encoding GIF images */
    IGIFEncoder public encoder;

    /**
    @notice Flag to disable use of setEncoder().
     */
    bool public encoderLocked = false;

    /**
    @notice Permanently sets the encoderLocked flag to true.
     */
    function lockEncoder() external onlyOwner {
        require(
            address(builder).supportsInterface(
                type(IGIFEncoder).interfaceId
            ),
            "Not IGIFEncoder"
        );
        encoderLocked = true;
    }

    /**
    @notice Sets the address of the encoder contract.
    @dev No checks are performed when setting, but lockEncoder() ensures that
    the final address implements the GIFEncoder interface.
     */
    function setEncoder(address _encoder) external onlyOwner {
        require(!builderLocked, "Encoder locked");
        encoder = IGIFEncoder(_encoder);
    }

    address immutable _stop;

    constructor() {
        _stop = SSTORE2.write(hex"7b2274726169745f74797065223a22437573746f6d222c2276616c7565223a22312f31227d2c7b2274726169745f74797065223a224e616d65222c2276616c7565223a22467265616b792046726f677a227d2c7b2274726169745f74797065223a222320547261697473222c2276616c7565223a327d");
    }

    /**
    @notice Retrieves the image data URI for a given token ID. This includes only the image itself, not the metadata.
    @param tokenId Token ID referring to an existing CrypToadz NFT Token ID
    */
    function imageURI(uint256 tokenId) external view returns (string memory) {
        (uint8[] memory meta) = metadata.getMetadata(tokenId);
        require (meta.length > 0, LEGACY_URI_NOT_FOUND);
        return _getImageURI(tokenId, meta);
    }

    /**
    @notice Retrieves the token data URI for a given token ID. Includes both the image and its accompanying metadata.
    @param tokenId Token ID referring to an existing CrypToadz NFT Token ID
    */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _getTokenURI(tokenId, Presentation.Image);
    }

    /**
    @notice Retrieves the token data URI for a given token ID, with a given presentation style. Includes both the image and its accompanying metadata.
    @param tokenId Token ID referring to an existing CrypToadz NFT Token ID
    @param presentation Image (tokenURI has image data URI), ImageData (tokenURI has image_data SVG data URI that scales to its container), or Both (tokenURI has both image representations)
    */
    function tokenURIWithPresentation(uint256 tokenId, Presentation presentation) external view returns (string memory) {
        return _getTokenURI(tokenId, presentation);
    }

    /**
    @notice Retrieves a random token data URI. This generates a completely new CrypToadz, not officially part of the collection.    
    */
    function randomTokenURI() external view returns (string memory) {
        return _randomTokenURI(uint64(uint(keccak256(abi.encodePacked(address(this), address(msg.sender), block.coinbase, block.number)))));
    }

    /**
    @notice Retrieves a random token data URI from a given seed. This generates a completely new CrypToadz, not officially part of the collection.
    @param seed An unsigned 64-bit integer representing the image. To recreate a random token made without a seed, pass the CrypToadz # supplied by its tokenURI
    */
    function randomTokenURIFromSeed(uint64 seed) external view returns (string memory) {
        return _randomTokenURI(seed);
    }

    /**
    @notice Retrieves a random image data URI. This generates a completely new CrypToadz image, not officially part of the collection.
    */
    function randomImageURI() external view returns (string memory imageUri) {
        (imageUri,) = _randomImageURI(uint64(uint(keccak256(abi.encodePacked(address(this), address(msg.sender), block.coinbase, block.number)))));
    }

    /**
    @notice Retrieves a random image data URI from a given seed. This generates a completely new CrypToadz image, not officially part of the collection.
    @param seed An unsigned 64-bit integer representing the image. To recreate a random token made without a seed, pass the CrypToadz # supplied by its tokenURI
    */
    function randomImageURIFromSeed(uint64 seed) external view returns (string memory imageUri) {
        (imageUri,) = _randomImageURI(seed);
    }

    function _randomTokenURI(uint64 seed) private view returns (string memory) {        
        (string memory imageUri, uint8[] memory meta) = _randomImageURI(seed);        
        string memory json = _getJsonPreamble(seed);
        json = string(
            abi.encodePacked(
                json,
                '"image":"', imageUri, '",',
                '"image_data":"', _getWrappedImage(imageUri), '",',
                _getAttributes(meta),
                "}"
            )
        );
        return _encodeJson(json);
    }

    function _randomImageURI(uint64 seed) private view returns (string memory imageUri, uint8[] memory meta) {
        meta = _randomMeta(seed);
        imageUri = IGIFEncoder(encoder).getDataUri(builder.getImage(meta));
        return (imageUri, meta);
    }

    function _randomMeta(uint64 seed) private pure returns (uint8[] memory meta) {
        PRNG.Source src = PRNG.newSource(keccak256(abi.encodePacked(seed)));

        uint8 traits = 2 + uint8(PRNG.readLessThan(src, 6, 8));            
        if(traits < 2 || traits > 7) revert BadTraitCount(traits);
        
        meta = new uint8[](1 + traits + 1);
        meta[0] = uint8(PRNG.readBool(src) ? 120 : 119);     // Size
        meta[1] = uint8(PRNG.readLessThan(src, 17, 8));      // Background
        meta[2] = 17 + uint8(PRNG.readLessThan(src, 34, 8)); // Body

        if(meta[0] == 120) {
            if(meta[2] == 19 || meta[2] == 36 || meta[2] == 44 || meta[2] == 45 || meta[2] == 47 || meta[2] == 50) {
                meta[0] = 119; // these body types are exclusively short
            }
        }

        uint8 picked;
        uint8 count;
        uint8 maxCount = 30;
        bool[] memory flags = new bool[](6);
        while(picked < traits - 2) {
            if(!flags[0] && (PRNG.readBool(src) || count > maxCount)) {
                flags[0] = true;
                picked++;
            } else if(!flags[1] && (PRNG.readBool(src) || count > maxCount)) {
                flags[1] = true;
                picked++;
            } else if(!flags[2] && (PRNG.readBool(src) || count > maxCount)) {
                flags[2] = true;
                picked++;
            } else if(!flags[3] && (PRNG.readBool(src) || count > maxCount)) {
                flags[3] = true;
                picked++;
            } else if(!flags[4] && (PRNG.readBool(src) || count > maxCount)) {
                flags[4] = true;
                picked++;
            } else if(!flags[5] && (PRNG.readBool(src) || count > maxCount)) {
                flags[5] = true;
                picked++;
            }
            count++;
        }

        if(flags[1] && flags[3]) {
            flags[1] = false; // clothes cancel heads
        }

        uint8 index = 3;
        if(flags[0]) {            
            uint8 mouth = uint8(121) + uint8(PRNG.readLessThan(src, 18 + 1, 8));
            if(mouth < 121 || mouth > 139) revert TraitOutOfRange(mouth);
            if(mouth == 139) mouth = 55; // Vampire
            meta[index++] = mouth;
        }
        if(flags[1]) {
            uint8 head = uint8(51) + uint8(PRNG.readLessThan(src, 53 + 1, 8));
            if(head < 51 || head > 104) revert TraitOutOfRange(head);
            if(head == 104) head = 249; // Vampire
            meta[index++] = head;
        }
        if(flags[2]) {
            uint8 eyes = uint8(139) + uint8(PRNG.readLessThan(src, 29 + 3, 8));
            if(eyes < 139 || eyes > 170) revert TraitOutOfRange(eyes);
            if(eyes == 168) eyes = 250; // Vampire
            if(eyes == 169) eyes = 252; // Undead
            if(eyes == 170) eyes = 253; // Creep            
            meta[index++] = eyes;
        }
        if(flags[3]) {
            uint8 clothes = uint8(246) + uint8(PRNG.readLessThan(src, 3, 8));
            if(clothes < 246 || clothes > 248) revert TraitOutOfRange(clothes);
            meta[index++] = clothes;
        }
        if(flags[4]) {
            uint8 accessoryII = uint8(104) + uint8(PRNG.readLessThan(src, 8, 8));
            if(accessoryII < 104 || accessoryII > 111) revert TraitOutOfRange(accessoryII);
            meta[index++] = accessoryII;
        }
        if(flags[5]) {
            uint8 accessoryI = uint8(237) + uint8(PRNG.readLessThan(src, 9, 8));            
            while((flags[1] || flags[3]) && accessoryI == 245) {                
                // if we have a head or clothes, don't pick the hoodie
                accessoryI = uint8(237) + uint8(PRNG.readLessThan(src, 9, 8));
            }
            if(accessoryI < 237 || accessoryI > 245) revert TraitOutOfRange(accessoryI);
            meta[index++] = accessoryI;
        }
        
        // # Traits
        if(traits == 2) {
            meta[index++] = 114;
        } else if(traits == 3) {
            meta[index++] = 116;
        } else if(traits == 4) {
            meta[index++] = 112;
        } else if(traits == 5) {
            meta[index++] = 113;
        } else if(traits == 6) {
            meta[index++] = 115;
        } else if(traits == 7) {
            meta[index++] = 118;
        } else { 
            revert BadTraitCount(traits);
        }
    }

    function _getTokenURI(uint256 tokenId, Presentation presentation) private view returns (string memory) {
        (uint8[] memory meta) = metadata.getMetadata(tokenId);
        require (meta.length > 0, LEGACY_URI_NOT_FOUND);

        string memory imageUri = _getImageURI(tokenId, meta);
        string memory imageDataUri;
        if(presentation == Presentation.ImageData || presentation == Presentation.Both) {
            imageDataUri = _getWrappedImage(imageUri);
        }

        string memory json = _getJsonPreamble(tokenId);

        if(presentation == Presentation.Image || presentation == Presentation.Both) {
            json = string(abi.encodePacked(json, '"image":"', imageUri, '",'));
        }

        if(presentation == Presentation.ImageData || presentation == Presentation.Both) {
            json = string(abi.encodePacked(json, '"image_data":"', imageDataUri, '",'));
        }

        return _encodeJson(string(abi.encodePacked(json, _getAttributes(meta), '}')));   
    }

    function _getImageURI(uint tokenId, uint8[] memory meta) private view returns (string memory imageUri) {
        if (customImages.isCustomImage(tokenId)) {
            bytes memory customImage = customImages.getCustomImage(tokenId);
            imageUri = string(
                abi.encodePacked(
                    PNG_URI_PREFIX,
                    Base64.encode(customImage, customImage.length)
                )
            );
        } else if (customAnimations.isCustomAnimation(tokenId)) {
            bytes memory customAnimation = customAnimations.getCustomAnimation(
                tokenId
            );
            imageUri = string(
                abi.encodePacked(
                    GIF_URI_PREFIX,
                    Base64.encode(customAnimation, customAnimation.length)
                )
            );
        } else {
            GIF memory gif = builder.getImage(meta, tokenId);
            imageUri = IGIFEncoder(encoder).getDataUri(gif);
        }
    }

    function _getJsonPreamble(uint tokenId) private pure returns (string memory json) {
        json = string(
            abi.encodePacked(
                '{"description":"', DESCRIPTION,
                '","external_url":"', EXTERNAL_URL,
                '","name":"', NAME, " #", Strings.toString(tokenId),
                '",'
            )
        );
    }

    function _getWrappedImage(string memory imageUri) private pure returns (string memory imageDataUri) {
        string memory imageData = string(abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 100 100" style="enable-background:new 0 0 100 100;" xml:space="preserve">',
            '<image style="image-rendering:-moz-crisp-edges;image-rendering:-webkit-crisp-edges;image-rendering:pixelated;" width="100" height="100" xlink:href="', 
            imageUri, '"/></svg>'));
            
        imageDataUri = string(abi.encodePacked(SVG_URI_PREFIX, Base64.encode(bytes(imageData), bytes(imageData).length)));
    }

    function _encodeJson(string memory json) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    JSON_URI_PREFIX,
                    Base64.encode(bytes(json), bytes(json).length)
                )
            );
    }

    function _getAttributes(uint8[] memory meta)
        private
        view
        returns (string memory attributes)
    {
        attributes = string(abi.encodePacked('"attributes":['));
        if(meta[0] == 255) return string(abi.encodePacked(attributes, SSTORE2.read(_stop), "]"));
        uint8 numberOfTraits;
        for (uint8 i = 1; i < meta.length; i++) {
            uint8 value = meta[i];            
            if(value == 254) continue; // stop byte            
            string memory traitName = getTraitName(value);
            
            string memory label = strings.getString(
                // Undead
                value == 249 ? 55 : 
                value == 250 ? 55 : 
                // Creep
                value == 252 ? 37 : 
                value == 253 ? 20 : value);

            (string memory a, uint8 t) = _appendTrait(
                value >= 112 && value < 119,
                attributes,
                traitName,
                label,
                numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }
        attributes = string(abi.encodePacked(attributes, "]"));
    }

    function _appendTrait(
        bool isNumber,
        string memory attributes,
        string memory trait_type,
        string memory value,
        uint8 numberOfTraits
    ) private pure returns (string memory, uint8) {
        if (bytes(value).length > 0) {
            numberOfTraits++;

            if (isNumber) {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        numberOfTraits > 1 ? "," : "",
                        '{"trait_type":"',
                        trait_type,
                        '","value":',
                        value,
                        "}"
                    )
                );
            } else {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        numberOfTraits > 1 ? "," : "",
                        '{"trait_type":"',
                        trait_type,
                        '","value":"',
                        value,
                        '"}'
                    )
                );
            }
        }
        return (attributes, numberOfTraits);
    }

    function getTraitName(uint8 traitValue)
        internal
        pure
        returns (string memory)
    {
        if (traitValue >= 0 && traitValue < 17) {
            return "Background";
        }
        if (traitValue >= 17 && traitValue < 51) {
            return "Body";
        }
        if (traitValue >= 51 && traitValue < 104) {
            if(traitValue == 55) return "Mouth"; // Vampire
            return "Head";
        }
        if (traitValue >= 104 && traitValue < 112) {
            return "Accessory II";
        }
        if (traitValue >= 112 && traitValue < 119) {
            return "# Traits";
        }
        if (traitValue >= 119 && traitValue < 121) {
            return "Size";
        }
        if (traitValue >= 121 && traitValue < 138) {
            return "Mouth";
        }
        if (traitValue >= 138 && traitValue < 168) {
            return "Eyes";
        }
        if (traitValue >= 168 && traitValue < 174) {
            return "Custom";
        }
        if (traitValue >= 174 && traitValue < 237) {
            return "Name";
        }
        if (traitValue >= 237 && traitValue < 246) {
            return "Accessory I";
        }
        if (traitValue >= 246 && traitValue < 249) {
            return "Clothes";
        }

        if(traitValue == 249) return "Head"; // Vampire
        if(traitValue == 250) return "Eyes"; // Vampire

        if(traitValue == 251) return "Size";

        if(traitValue == 252) return "Eyes"; // Undead
        if(traitValue == 253) return "Eyes"; // Creep  

        revert TraitOutOfRange(traitValue);
    }

    /**
    @notice Adds ERC2981 interface to the set of already-supported interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)
pragma solidity >=0.8.9 <0.9.0;

library PRNG {
    /**
    @notice A source of random numbers.
    @dev Pointer to a 2-word buffer of {carry || number, remaining unread
    bits}. however, note that this is abstracted away by the API and SHOULD NOT
    be used. This layout MUST NOT be considered part of the public API and
    therefore not relied upon even within stable versions.
     */
    type Source is uint256;

    /// @notice The biggest safe prime for modulus 2**128
    uint256 private constant MWC_FACTOR = 2**128 - 10408;

    /// @notice Layout within the buffer. 0x00 is the current (carry || number)
    uint256 private constant REMAIN = 0x20;

    /// @notice Mask for the 128 least significant bits
    uint256 private constant MASK_128_BITS = 0xffffffffffffffffffffffffffffffff;

    /**
    @notice Returns a new deterministic Source, differentiated only by the seed.
    @dev Use of PRNG.Source does NOT provide any unpredictability as generated
    numbers are entirely deterministic. Either a verifiable source of randomness
    such as Chainlink VRF, or a commit-and-reveal protocol MUST be used if
    unpredictability is required. The latter is only appropriate if the contract
    owner can be trusted within the specified threat model.
    @dev The 256bit seed is used to initialize carry || number
     */
    function newSource(bytes32 seed) internal pure returns (Source src) {
        assembly {
            src := mload(0x40)
            mstore(0x40, add(src, 0x40))
            mstore(src, seed)
            mstore(add(src, REMAIN), 128)
        }
        // DO NOT call _refill() on the new Source as newSource() is also used
        // by loadSource(), which implements its own state modifications. The
        // first call to read() on a fresh Source will induce a call to
        // _refill().
    }

    /**
    @dev Computes the next PRN in entropy using a lag-1 multiply-with-carry
    algorithm and resets the remaining bits to 128.
    `nextNumber = (factor * number + carry) mod 2**128`
    `nextCarry  = (factor * number + carry) //  2**128`
     */
    function _refill(Source src) private pure {
        assembly {
            let carryAndNumber := mload(src)
            let rand := and(carryAndNumber, MASK_128_BITS)
            let carry := shr(128, carryAndNumber)
            mstore(src, add(mul(MWC_FACTOR, rand), carry))
            mstore(add(src, REMAIN), 128)
        }
    }

    /**
    @notice Returns the specified number of bits <= 128 from the Source.
    @dev It is safe to cast the returned value to a uint<bits>.
     */
    function read(Source src, uint256 bits)
        internal
        pure
        returns (uint256 sample)
    {
        require(bits <= 128, "PRNG: max 128 bits");

        uint256 remain;
        assembly {
            remain := mload(add(src, REMAIN))
        }
        if (remain > bits) {
            return readWithSufficient(src, bits);
        }

        uint256 extra = bits - remain;
        sample = readWithSufficient(src, remain);
        assembly {
            sample := shl(extra, sample)
        }

        _refill(src);
        sample = sample | readWithSufficient(src, extra);
    }

    /**
    @notice Returns the specified number of bits, assuming that there is
    sufficient entropy remaining. See read() for usage.
     */
    function readWithSufficient(Source src, uint256 bits)
        private
        pure
        returns (uint256 sample)
    {
        assembly {
            let ent := mload(src)
            let rem := add(src, REMAIN)
            let remain := mload(rem)
            sample := shr(sub(256, bits), shl(sub(256, remain), ent))
            mstore(rem, sub(remain, bits))
        }
    }

    /// @notice Returns a random boolean.
    function readBool(Source src) internal pure returns (bool) {
        return read(src, 1) == 1;
    }

    /**
    @notice Returns the number of bits needed to encode n.
    @dev Useful for calling readLessThan() multiple times with the same upper
    bound.
     */
    function bitLength(uint256 n) internal pure returns (uint16 bits) {
        assembly {
            for {
                let _n := n
            } gt(_n, 0) {
                _n := shr(1, _n)
            } {
                bits := add(bits, 1)
            }
        }
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling.
    @dev If the size of n is known, prefer readLessThan(Source, uint, uint16) as
    it skips the bit counting performed by this version; see bitLength().
     */
    function readLessThan(Source src, uint256 n)
        internal
        pure
        returns (uint256)
    {
        return readLessThan(src, n, bitLength(n));
    }

    /**
    @notice Returns a uniformly random value in [0,n) with rejection sampling
    from the range [0,2^bits).
    @dev For greatest efficiency, the value of bits should be the smallest
    number of bits required to capture n; if this is not known, use
    readLessThan(Source, uint) or bitLength(). Although rejections are reduced
    by using twice the number of bits, this increases the rate at which the
    entropy pool must be refreshed with a call to `_refill`.

    TODO: benchmark higher number of bits for rejection vs hashing gas cost.
     */
    function readLessThan(
        Source src,
        uint256 n,
        uint16 bits
    ) internal pure returns (uint256 result) {
        // Discard results >= n and try again because using % will bias towards
        // lower values; e.g. if n = 13 and we read 4 bits then {13, 14, 15}%13
        // will select {0, 1, 2} twice as often as the other values.
        // solhint-disable-next-line no-empty-blocks
        for (result = n; result >= n; result = read(src, bits)) {}
    }

    /**
    @notice Returns the internal state of the Source.
    @dev MUST NOT be considered part of the API and is subject to change without
    deprecation nor warning. Only exposed for testing.
     */
    function state(Source src)
        internal
        pure
        returns (uint256 entropy, uint256 remain)
    {
        assembly {
            entropy := mload(src)
            remain := mload(add(src, REMAIN))
        }
    }

    /**
    @notice Stores the state of the Source in a 2-word buffer. See loadSource().
    @dev The layout of the stored state MUST NOT be considered part of the
    public API, and is subject to change without warning. It is therefore only
    safe to rely on stored Sources _within_ contracts, but not _between_ them.
     */
    function store(Source src, uint256[2] storage stored) internal {
        uint256 carryAndNumber;
        uint256 remain;
        assembly {
            carryAndNumber := mload(src)
            remain := mload(add(src, REMAIN))
        }
        stored[0] = carryAndNumber;
        stored[1] = remain;
    }

    /**
    @notice Recreates a Source from the state stored with store().
     */
    function loadSource(uint256[2] storage stored)
        internal
        view
        returns (Source)
    {
        Source src = newSource(bytes32(stored[0]));
        uint256 carryAndNumber = stored[0];
        uint256 remain = stored[1];

        assembly {
            mstore(src, carryAndNumber)
            mstore(add(src, REMAIN), remain)
        }
        return src;
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

interface IERC721 {
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

interface ICrypToadzStrings {
    function getString(uint8 key) external view returns (string memory);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzBuilder {
    function getImage(uint8[] memory metadata, uint256 tokenId) external view returns (GIF memory gif);
    function getImage(uint8[] memory metadata) external view returns (GIF memory gif);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzMetadata {
    function isTall(uint256 tokenId) external view returns (bool);
    function getMetadata(uint256 tokenId) external view returns (uint8[] memory metadata);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzCustomImages {
    function isCustomImage(uint256 tokenId) external view returns (bool);
    function getCustomImage(uint256 tokenId) external view returns (bytes memory buffer);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIFEncoder.sol";

interface ICrypToadzCustomAnimations {
    function isCustomAnimation(uint256 tokenId) external view returns (bool);
    function getCustomAnimation(uint256 tokenId) external view returns (bytes memory buffer);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./IPixelRenderer.sol";
import "./BufferUtils.sol";
import "./Errors.sol";

/** @notice Pixel renderer using basic drawing instructions: fill, line, and dot. */
contract PixelRenderer is IPixelRenderer {

    struct Point2D {
        int32 x;
        int32 y;
    }

    struct Line2D {
        Point2D v0;
        Point2D v1;
        uint32 color;
    }

    function drawFrameWithOffsets(DrawFrame memory f) external pure returns (uint32[] memory buffer, uint) {       
        
        (uint32 instructionCount, uint position) = BufferUtils.readUInt32(f.position, f.buffer);
        f.position = position;
        
        for(uint32 i = 0; i < instructionCount; i++) {

            uint8 instructionType = uint8(f.buffer[f.position++]);                   

            if(instructionType == 0) {   
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                for (uint16 x = 0; x < f.frame.width; x++) {
                    for (uint16 y = 0; y < f.frame.height; y++) {
                        f.frame.buffer[f.frame.width * y + x] = color;
                    }
                }
            }
            else if(instructionType == 1)
            {                
                uint32 color = f.colors[uint8(f.buffer[f.position++])];

                int32 x0 = int8(uint8(f.buffer[f.position++]));                
                int32 y0 = int8(uint8(f.buffer[f.position++]));                
                int32 x1 = int8(uint8(f.buffer[f.position++]));
                int32 y1 = int8(uint8(f.buffer[f.position++]));

                x0 += int8(f.ox);
                y0 += int8(f.oy);
                x1 += int8(f.ox);
                y1 += int8(f.oy);

                line(f.frame, PixelRenderer.Line2D(
                    PixelRenderer.Point2D(x0, y0), 
                    PixelRenderer.Point2D(x1, y1),
                    color), f.blend);
            }
            else if(instructionType == 2)
            {   
                uint32 color = f.colors[uint8(f.buffer[f.position++])];
                
                int32 x = int8(uint8(f.buffer[f.position++]));
                int32 y = int8(uint8(f.buffer[f.position++]));
                x += int8(f.ox);
                y += int8(f.oy);

                dot(f.frame, x, y, color, f.blend);
            } else {
                revert UnsupportedDrawInstruction(instructionType);
            }
        }

        return (f.frame.buffer, f.position);
    }
    
    function getColorTable(bytes memory buffer, uint position) external pure returns(uint32[] memory colors, uint) {
        
        uint8 colorCount = uint8(buffer[position++]);
        colors = new uint32[](1 + colorCount);
        colors[0] = 0xFF000000;
        
        for(uint8 i = 0; i < colorCount; i++) {
            uint32 a = uint32(uint8(buffer[position++]));
            uint32 r = uint32(uint8(buffer[position++]));
            uint32 g = uint32(uint8(buffer[position++]));
            uint32 b = uint32(uint8(buffer[position++]));
            uint32 color = 0;
            color |= a << 24;
            color |= r << 16;
            color |= g << 8;
            color |= b << 0;

            if(color == colors[0]) {
                revert DoNotAddBlackToColorTable();
            }
             
            colors[i + 1] = color;                   
        }

        return (colors, position);
    }

    function dot(
        GIFFrame memory frame,
        int32 x,
        int32 y,
        uint32 color,
        bool blend
    ) private pure {
        uint32 p = uint32(int16(frame.width) * y + x);
        frame.buffer[p] = blend ? blendPixel(frame.buffer[p], color) : color;
    }

    function line(GIFFrame memory frame, Line2D memory f, bool blend)
        private
        pure
    {
        int256 x0 = f.v0.x;
        int256 x1 = f.v1.x;
        int256 y0 = f.v0.y;
        int256 y1 = f.v1.y;

        int256 dx = BufferUtils.abs(x1 - x0);
        int256 dy = BufferUtils.abs(y1 - y0);

        int256 err = (dx > dy ? dx : -dy) / 2;

        for (;;) {
            if (
                x0 <= int32(0) + int16(frame.width) - 1 &&
                x0 >= int32(0) &&
                y0 <= int32(0) + int16(frame.height) - 1 &&
                y0 >= int32(0)
            ) {
                uint256 p = uint256(int16(frame.width) * y0 + x0);
                frame.buffer[p] = blend ? blendPixel(frame.buffer[p], f.color) : f.color;
            }

            if (x0 == x1 && y0 == y1) break;
            int256 e2 = err;
            if (e2 > -dx) {
                err -= dy;
                x0 += x0 < x1 ? int8(1) : -1;
            }
            if (e2 < dy) {
                err += dx;
                y0 += y0 < y1 ? int8(1) : -1;
            }
        }
    }

    function blendPixel(uint32 bg, uint32 fg) private pure returns (uint32) {
        uint32 r1 = bg >> 16;
        uint32 g1 = bg >> 8;
        uint32 b1 = bg;
        
        uint32 a2 = fg >> 24;
        uint32 r2 = fg >> 16;
        uint32 g2 = fg >> 8;
        uint32 b2 = fg;
        
        uint32 alpha = (a2 & 0xFF) + 1;
        uint32 inverseAlpha = 257 - alpha;

        uint32 r = (alpha * (r2 & 0xFF) + inverseAlpha * (r1 & 0xFF)) >> 8;
        uint32 g = (alpha * (g2 & 0xFF) + inverseAlpha * (g1 & 0xFF)) >> 8;
        uint32 b = (alpha * (b2 & 0xFF) + inverseAlpha * (b1 & 0xFF)) >> 8;

        uint32 rgb = 0;
        rgb |= uint32(0xFF) << 24;
        rgb |= r << 16;
        rgb |= g << 8;
        rgb |= b;

        return rgb;
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

enum Presentation {
    Image,
    ImageData,
    Both
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

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./lib/Base64.sol";
import "./IGIFEncoder.sol";
import "./GIF.sol";

/** @notice Encodes image data in GIF format. GIF is much more compact than SVG, allows for animation (SVG does as well), and also represents images that are already rastered. 
            This is important if the art shouldn't change fundamentally depending on which process is doing the SVG rendering, such as a browser or custom application.
 */
contract GIFEncoder is IGIFEncoder {
    
    uint32 private constant MASK = (1 << 12) - 1;
    uint32 private constant CLEAR_CODE = 256;
    uint32 private constant END_CODE = 257;
    uint16 private constant CODE_START = 258;
    uint16 private constant TREE_TABLE_LENGTH = 4096;
    uint16 private constant CODE_TABLE_LENGTH = TREE_TABLE_LENGTH - CODE_START;

    bytes private constant HEADER = hex"474946383961";
    bytes private constant NETSCAPE = hex"21FF0b4E45545343415045322E300301000000";
    bytes private constant GIF_URI_PREFIX = "data:image/gif;base64,";

    struct GCT {
        uint32 start;
        uint32 count;
    }

    struct LZW {
        uint16 codeCount;
        int32 codeBitsUsed;
        uint32 activePrefix;
        uint32 activeSuffix;
        uint32[CODE_TABLE_LENGTH] codeTable;
        uint16[TREE_TABLE_LENGTH] treeRoots;
        Pending pending;
    }

    struct Pending {
        uint32 value;
        int32 bits;
        uint32 chunkSize;
    }

    function getDataUri(GIF memory gif) external pure returns (string memory) {
        (bytes memory buffer, uint length) = encode(gif);
        string memory base64 = Base64.encode(buffer, length);
        return string(abi.encodePacked(GIF_URI_PREFIX, base64));
    }

    function encode(GIF memory gif) private pure returns (bytes memory buffer, uint length) {
        buffer = new bytes(gif.width * gif.height * 3);
        uint32 position = 0;

        // header
        position = writeBuffer(buffer, position, HEADER);

        // logical screen descriptor
        {
            position = writeUInt16(buffer, position, gif.width);
            position = writeUInt16(buffer, position, gif.height);

            uint8 packed = 0;
            packed |= 1 << 7;
            packed |= 7 << 4;
            packed |= 0 << 3;
            packed |= 7 << 0;

            position = writeByte(buffer, position, packed);
            position = writeByte(buffer, position, 0);
            position = writeByte(buffer, position, 0);
        }

        // global color table
        GCT memory gct;
        gct.start = position;
        gct.count = 1;
        {
            for (uint256 i = 0; i < 768; i++) {
                position = writeByte(buffer, position, 0);
            }
        }

        if (gif.frameCount > 1) {
            // netscape extension block
            position = writeBuffer(buffer, position, NETSCAPE);
        }

        uint32[CODE_TABLE_LENGTH] memory codeTable;

        for (uint256 i = 0; i < gif.frameCount; i++) {
            // graphic control extension
            {
                position = writeByte(buffer, position, 0x21);
                position = writeByte(buffer, position, 0xF9);
                position = writeByte(buffer, position, 0x04);

                uint8 packed = 0;
                packed |= (gif.frameCount > 1 ? 2 : 0) << 2;
                packed |= 0 << 1;
                packed |= 1 << 0;
                position = writeByte(buffer, position, packed);

                position = writeUInt16(buffer, position, gif.frameCount > 1 ? gif.frames[i].delay : uint16(0));                
                position = writeByte(buffer, position, 0);
                position = writeByte(buffer, position, 0);
            }

            // image descriptor
            {
                position = writeByte(buffer, position, 0x2C);
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, uint16(0));
                position = writeUInt16(buffer, position, gif.frames[i].width);
                position = writeUInt16(buffer, position, gif.frames[i].height);

                uint8 packed = 0;
                packed |= 0 << 7;
                packed |= 0 << 6;
                packed |= 0 << 5;
                packed |= 0 << 0;
                position = writeByte(buffer, position, packed);
            }

            // image data
            {
                uint16[TREE_TABLE_LENGTH] memory treeRoots;

                (uint32 p, uint32 c) = writeImageData(
                    buffer,
                    position,
                    gct,
                    gif.frames[i],
                    LZW(0, 9, 0, 0, codeTable, treeRoots, Pending(0, 0, 0))
                );
                position = p;
                gct.count = c;
            }
        }

        // trailer
        position = writeByte(buffer, position, 0x3B);

        return (buffer, position);
    }

    function writeBuffer(
        bytes memory buffer,
        uint32 position,
        bytes memory value
    ) private pure returns (uint32) {
        for (uint256 i = 0; i < value.length; i++)
            buffer[position++] = bytes1(value[i]);
        return position;
    }

    function writeByte(
        bytes memory buffer,
        uint32 position,
        uint8 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(value);
        return position;
    }

    function writeUInt16(
        bytes memory buffer,
        uint32 position,
        uint16 value
    ) private pure returns (uint32) {
        buffer[position++] = bytes1(uint8(uint16(value >> 0)));
        buffer[position++] = bytes1(uint8(uint16(value >> 8)));
        return position;
    }

    function writeImageData(
        bytes memory buffer,
        uint32 position,
        GCT memory gct,
        GIFFrame memory frame,
        LZW memory lzw
    ) private pure returns (uint32, uint32) {
                
        position = writeByte(buffer, position, 8);
        position = writeByte(buffer, position, 0);

        lzw.codeCount = 0;
        lzw.codeBitsUsed = 9;

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                CLEAR_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[0]
            );
            gct.count = c;
            lzw.activePrefix = p;
        }        

        for (uint32 i = 1; i < frame.width * frame.height; i++) {

            (uint32 c, uint32 p) = getColorTableIndex(
                buffer,
                gct.start,
                gct.count,
                frame.buffer[i]
            );
            gct.count = c;
            lzw.activeSuffix = p;

            position = writeColor(buffer, position, lzw);
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                lzw.activePrefix,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        {
            (uint32 p, Pending memory pending) = writeVariableBitsChunked(
                buffer,
                position,
                END_CODE,
                lzw.codeBitsUsed,
                lzw.pending
            );
            position = p;
            lzw.pending = pending;
        }

        if (lzw.pending.bits > 0) {
            position = writeChunked(
                buffer,
                position,
                uint8(lzw.pending.value & 0xFF),
                lzw.pending
            );
            lzw.pending.value = 0;
            lzw.pending.bits = 0;
        }

        if (lzw.pending.chunkSize > 0) {
            buffer[position - lzw.pending.chunkSize - 1] = bytes1(
                uint8(uint32(lzw.pending.chunkSize))
            );
            lzw.pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return (position, gct.count);
    }

    function writeColor(bytes memory buffer, uint32 position, LZW memory lzw) private pure returns (uint32) {
        uint32 lastTreePosition = 0;
        uint32 foundSuffix = 0;

        bool found = false;
        {
            uint32 treePosition = lzw.treeRoots[lzw.activePrefix];
            while (treePosition != 0) {
                lastTreePosition = treePosition;
                foundSuffix = lzw.codeTable[treePosition - CODE_START] & 0xFF;

                if (lzw.activeSuffix == foundSuffix) {
                    lzw.activePrefix = treePosition;
                    found = true;
                    break;
                } else if (lzw.activeSuffix < foundSuffix) {
                    treePosition = (lzw.codeTable[treePosition - CODE_START] >> 8) & MASK;
                } else {
                    treePosition = lzw.codeTable[treePosition - CODE_START] >> 20;
                }
            }
        }

        if (!found) {
            {
                (
                    uint32 p,
                    Pending memory pending
                ) = writeVariableBitsChunked(
                        buffer,
                        position,
                        lzw.activePrefix,
                        lzw.codeBitsUsed,
                        lzw.pending
                    );
                position = p;
                lzw.pending = pending;
            }

            if (lzw.codeCount == CODE_TABLE_LENGTH) {
                {
                    (
                        uint32 p,
                        Pending memory pending
                    ) = writeVariableBitsChunked(
                            buffer,
                            position,
                            CLEAR_CODE,
                            lzw.codeBitsUsed,
                            lzw.pending
                        );
                    position = p;
                    lzw.pending = pending;
                }

                for (uint16 j = 0; j < TREE_TABLE_LENGTH; j++) {
                    lzw.treeRoots[j] = 0;
                }
                lzw.codeCount = 0;
                lzw.codeBitsUsed = 9;
            } else {
                if (lastTreePosition == 0)
                    lzw.treeRoots[lzw.activePrefix] = uint16(CODE_START + lzw.codeCount);
                else if (lzw.activeSuffix < foundSuffix)
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 8)) | (uint32(CODE_START + lzw.codeCount) << 8);
                else {
                    lzw.codeTable[lastTreePosition - CODE_START] = (lzw.codeTable[lastTreePosition - CODE_START] & ~(MASK << 20)) | (uint32(CODE_START + lzw.codeCount) << 20);
                }

                if (uint32(CODE_START + lzw.codeCount) == (uint32(1) << uint32(lzw.codeBitsUsed))) {
                    lzw.codeBitsUsed++;
                }

                lzw.codeTable[lzw.codeCount++] = lzw.activeSuffix;
            }

            lzw.activePrefix = lzw.activeSuffix;
        }

        return position;
    }    

    function writeVariableBitsChunked(
        bytes memory buffer,
        uint32 position,
        uint32 value,
        int32 bits,
        Pending memory pending
    ) private pure returns (uint32, Pending memory) {
        while (bits > 0) {
            int32 takeBits = min(bits, 8 - pending.bits);
            uint32 takeMask = uint32((uint32(1) << uint32(takeBits)) - 1);

            pending.value |= ((value & takeMask) << uint32(pending.bits));

            pending.bits += takeBits;
            bits -= takeBits;
            value >>= uint32(takeBits);

            if (pending.bits == 8) {
                position = writeChunked(
                    buffer,
                    position,
                    uint8(pending.value & 0xFF),
                    pending
                );
                pending.value = 0;
                pending.bits = 0;
            }
        }

        return (position, pending);
    }

    function writeChunked(
        bytes memory buffer,
        uint32 position,
        uint8 value,
        Pending memory pending
    ) private pure returns (uint32) {
        position = writeByte(buffer, position, value);
        pending.chunkSize++;

        if (pending.chunkSize == 255) {
            buffer[position - 256] = bytes1(uint8(255));
            pending.chunkSize = 0;
            position = writeByte(buffer, position, 0);
        }

        return position;
    }

    function getColorTableIndex(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32, uint32) {
        if (target >> 24 != 0xFF) return (colorCount, 0);

        uint32 i = 1;
        for (; i < colorCount; i++) {
            if (uint8(buffer[colorTableStart + i * 3 + 0]) != uint8(target >> 16)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 1]) != uint8(target >> 8)
            ) continue;
            if (uint8(buffer[colorTableStart + i * 3 + 2]) != uint8(target >> 0)
            ) continue;
            return (colorCount, i);
        }

        if (colorCount == 256) {
            return (
                colorCount,
                getColorTableBestMatch(
                    buffer,
                    colorTableStart,
                    colorCount,
                    target
                )
            );
        } else {
            buffer[colorTableStart + colorCount * 3 + 0] = bytes1(uint8(target >> 16));
            buffer[colorTableStart + colorCount * 3 + 1] = bytes1(uint8(target >> 8));
            buffer[colorTableStart + colorCount * 3 + 2] = bytes1(uint8(target >> 0));
            return (colorCount + 1, colorCount);
        }
    }

    function getColorTableBestMatch(
        bytes memory buffer,
        uint32 colorTableStart,
        uint32 colorCount,
        uint32 target
    ) private pure returns (uint32) {
        uint32 bestDistance = type(uint32).max;
        uint32 bestIndex = 0;

        for (uint32 i = 1; i < colorCount; i++) {
            uint32 distance;
            {
                uint8 rr = uint8(buffer[colorTableStart + i * 3 + 0]) - uint8(target >> 16);
                uint8 gg = uint8(buffer[colorTableStart + i * 3 + 1]) - uint8(target >> 8);
                uint8 bb = uint8(buffer[colorTableStart + i * 3 + 2]) - uint8(target >> 0);
                distance = rr * rr + gg * gg + bb * bb;
            }
            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = i;
            }
        }

        return bestIndex;
    }

    function max(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 >= val2) ? val1 : val2;
    }

    function min(uint32 val1, uint32 val2) private pure returns (uint32) {
        return (val1 <= val2) ? val1 : val2;
    }

    function min(int32 val1, int32 val2) private pure returns (int32) {
        return (val1 <= val2) ? val1 : val2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data, uint length) internal pure returns (string memory) {
        if (data.length == 0 || length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((length + 2) / 3);

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIF.sol";

interface IGIFEncoder {
    function getDataUri(GIF memory gif) external pure returns (string memory);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";

struct GIF {
    uint32 frameCount;
    GIFFrame[] frames;
    uint16 width;
    uint16 height;
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

struct GIFFrame {
    uint32[] buffer;
    uint16 delay;
    uint16 width;
    uint16 height;
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./DrawFrame.sol";

interface IPixelRenderer {
    function drawFrameWithOffsets(DrawFrame memory f) external pure returns (uint32[] memory buffer, uint);
    function getColorTable(bytes memory buffer, uint position) external pure returns(uint32[] memory colors, uint);
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./lib/InflateLib.sol";
import "./lib/SSTORE2.sol";
import "./Errors.sol";

library BufferUtils {
    function decompress(address compressed, uint256 decompressedLength)
        internal
        view
        returns (bytes memory)
    {
        (InflateLib.ErrorCode code, bytes memory buffer) = InflateLib.puff(
            SSTORE2.read(compressed),
            decompressedLength
        );
        if (code != InflateLib.ErrorCode.ERR_NONE)
            revert FailedToDecompress(uint256(code));
        if (buffer.length != decompressedLength)
            revert InvalidDecompressionLength(
                decompressedLength,
                buffer.length
            );
        return buffer;
    }

    function advanceToTokenPosition(uint256 tokenId, bytes memory buffer)
        internal
        pure
        returns (uint256 position, uint8 length)
    {
        uint256 id;
        while (id != tokenId) {
            (id, position) = BufferUtils.readUInt32(position, buffer);
            (length, position) = BufferUtils.readByte(position, buffer);
            if (id != tokenId) {
                position += length;
                if (position >= buffer.length) return (position, 0);
            }
        }
        return (position, length);
    }

    function advanceToTokenPositionDelta(uint256 tokenId, bytes memory buffer)
        internal
        pure
        returns (uint256 position, uint32 length)
    {
        uint256 id;
        while (id != tokenId) {
            (id, position) = BufferUtils.readUInt32(position, buffer);
            (length, position) = BufferUtils.readUInt32(position, buffer);
            if (id != tokenId) {
                position += length;
                if (position >= buffer.length) return (position, 0);
            }
        }
        return (position, length);
    }

    function readUInt32(uint256 position, bytes memory buffer)
        internal
        pure
        returns (uint32, uint256)
    {
        uint8 d1 = uint8(buffer[position++]);
        uint8 d2 = uint8(buffer[position++]);
        uint8 d3 = uint8(buffer[position++]);
        uint8 d4 = uint8(buffer[position++]);
        return ((16777216 * d4) + (65536 * d3) + (256 * d2) + d1, position);
    }

    function readByte(uint256 position, bytes memory buffer)
        internal
        pure
        returns (uint8, uint256)
    {
        uint8 value = uint8(buffer[position++]);
        return (value, position);
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

error UnsupportedDrawInstruction(uint8 instructionType);
error DoNotAddBlackToColorTable();
error InvalidDrawOrder(uint8 featureId);
error FailedToDecompress(uint errorCode);
error InvalidDecompressionLength(uint expected, uint actual);
error ImageFileOutOfRange(uint value);
error TraitOutOfRange(uint value);
error BadTraitCount(uint8 value);

// SPDX-License-Identifier: MPL-2.0

pragma solidity ^0.8.13;

import "./GIFFrame.sol";

struct DrawFrame {
    bytes buffer;
    uint position;
    GIFFrame frame;
    uint32[] colors;
    uint8 ox;
    uint8 oy;
    bool blend;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/// @notice Based on https://github.com/madler/zlib/blob/master/contrib/puff
library InflateLib {
    // Maximum bits in a code
    uint256 constant MAXBITS = 15;
    // Maximum number of literal/length codes
    uint256 constant MAXLCODES = 286;
    // Maximum number of distance codes
    uint256 constant MAXDCODES = 30;
    // Maximum codes lengths to read
    uint256 constant MAXCODES = (MAXLCODES + MAXDCODES);
    // Number of fixed literal/length codes
    uint256 constant FIXLCODES = 288;

    // Error codes
    enum ErrorCode {
        ERR_NONE, // 0 successful inflate
        ERR_NOT_TERMINATED, // 1 available inflate data did not terminate
        ERR_OUTPUT_EXHAUSTED, // 2 output space exhausted before completing inflate
        ERR_INVALID_BLOCK_TYPE, // 3 invalid block type (type == 3)
        ERR_STORED_LENGTH_NO_MATCH, // 4 stored block length did not match one's complement
        ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES, // 5 dynamic block code description: too many length or distance codes
        ERR_CODE_LENGTHS_CODES_INCOMPLETE, // 6 dynamic block code description: code lengths codes incomplete
        ERR_REPEAT_NO_FIRST_LENGTH, // 7 dynamic block code description: repeat lengths with no first length
        ERR_REPEAT_MORE, // 8 dynamic block code description: repeat more than specified lengths
        ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS, // 9 dynamic block code description: invalid literal/length code lengths
        ERR_INVALID_DISTANCE_CODE_LENGTHS, // 10 dynamic block code description: invalid distance code lengths
        ERR_MISSING_END_OF_BLOCK, // 11 dynamic block code description: missing end-of-block code
        ERR_INVALID_LENGTH_OR_DISTANCE_CODE, // 12 invalid literal/length or distance code in fixed or dynamic block
        ERR_DISTANCE_TOO_FAR, // 13 distance is too far back in fixed or dynamic block
        ERR_CONSTRUCT // 14 internal: error in construct()
    }

    // Input and output state
    struct State {
        //////////////////
        // Output state //
        //////////////////
        // Output buffer
        bytes output;
        // Bytes written to out so far
        uint256 outcnt;
        /////////////////
        // Input state //
        /////////////////
        // Input buffer
        bytes input;
        // Bytes read so far
        uint256 incnt;
        ////////////////
        // Temp state //
        ////////////////
        // Bit buffer
        uint256 bitbuf;
        // Number of bits in bit buffer
        uint256 bitcnt;
        //////////////////////////
        // Static Huffman codes //
        //////////////////////////
        Huffman lencode;
        Huffman distcode;
    }

    // Huffman code decoding tables
    struct Huffman {
        uint256[] counts;
        uint256[] symbols;
    }

    function bits(State memory s, uint256 need)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Bit accumulator (can use up to 20 bits)
        uint256 val;

        // Load at least need bits into val
        val = s.bitbuf;
        while (s.bitcnt < need) {
            if (s.incnt == s.input.length) {
                // Out of input
                return (ErrorCode.ERR_NOT_TERMINATED, 0);
            }

            // Load eight bits
            val |= uint256(uint8(s.input[s.incnt++])) << s.bitcnt;
            s.bitcnt += 8;
        }

        // Drop need bits and update buffer, always zero to seven bits left
        s.bitbuf = val >> need;
        s.bitcnt -= need;

        // Return need bits, zeroing the bits above that
        uint256 ret = (val & ((1 << need) - 1));
        return (ErrorCode.ERR_NONE, ret);
    }

    function _stored(State memory s) private pure returns (ErrorCode) {
        // Length of stored block
        uint256 len;

        // Discard leftover bits from current byte (assumes s.bitcnt < 8)
        s.bitbuf = 0;
        s.bitcnt = 0;

        // Get length and check against its one's complement
        if (s.incnt + 4 > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        len = uint256(uint8(s.input[s.incnt++]));
        len |= uint256(uint8(s.input[s.incnt++])) << 8;

        if (
            uint8(s.input[s.incnt++]) != (~len & 0xFF) ||
            uint8(s.input[s.incnt++]) != ((~len >> 8) & 0xFF)
        ) {
            // Didn't match complement!
            return ErrorCode.ERR_STORED_LENGTH_NO_MATCH;
        }

        // Copy len bytes from in to out
        if (s.incnt + len > s.input.length) {
            // Not enough input
            return ErrorCode.ERR_NOT_TERMINATED;
        }
        if (s.outcnt + len > s.output.length) {
            // Not enough output space
            return ErrorCode.ERR_OUTPUT_EXHAUSTED;
        }
        while (len != 0) {
            // Note: Solidity reverts on underflow, so we decrement here
            len -= 1;
            s.output[s.outcnt++] = s.input[s.incnt++];
        }

        // Done with a valid stored block
        return ErrorCode.ERR_NONE;
    }

    function _decode(State memory s, Huffman memory h)
        private
        pure
        returns (ErrorCode, uint256)
    {
        // Current number of bits in code
        uint256 len;
        // Len bits being decoded
        uint256 code = 0;
        // First code of length len
        uint256 first = 0;
        // Number of codes of length len
        uint256 count;
        // Index of first code of length len in symbol table
        uint256 index = 0;
        // Error code
        ErrorCode err;

        for (len = 1; len <= MAXBITS; len++) {
            // Get next bit
            uint256 tempCode;
            (err, tempCode) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, 0);
            }
            code |= tempCode;
            count = h.counts[len];

            // If length len, return symbol
            if (code < first + count) {
                return (ErrorCode.ERR_NONE, h.symbols[index + (code - first)]);
            }
            // Else update for next length
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
        }

        // Ran out of codes
        return (ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE, 0);
    }

    function _construct(
        Huffman memory h,
        uint256[] memory lengths,
        uint256 n,
        uint256 start
    ) private pure returns (ErrorCode) {
        // Current symbol when stepping through lengths[]
        uint256 symbol;
        // Current length when stepping through h.counts[]
        uint256 len;
        // Number of possible codes left of current length
        uint256 left;
        // Offsets in symbol table for each length
        uint256[MAXBITS + 1] memory offs;

        // Count number of codes of each length
        for (len = 0; len <= MAXBITS; len++) {
            h.counts[len] = 0;
        }
        for (symbol = 0; symbol < n; symbol++) {
            // Assumes lengths are within bounds
            h.counts[lengths[start + symbol]]++;
        }
        // No codes!
        if (h.counts[0] == n) {
            // Complete, but decode() will fail
            return (ErrorCode.ERR_NONE);
        }

        // Check for an over-subscribed or incomplete set of lengths

        // One possible code of zero length
        left = 1;

        for (len = 1; len <= MAXBITS; len++) {
            // One more bit, double codes left
            left <<= 1;
            if (left < h.counts[len]) {
                // Over-subscribed--return error
                return ErrorCode.ERR_CONSTRUCT;
            }
            // Deduct count from possible codes

            left -= h.counts[len];
        }

        // Generate offsets into symbol table for each length for sorting
        offs[1] = 0;
        for (len = 1; len < MAXBITS; len++) {
            offs[len + 1] = offs[len] + h.counts[len];
        }

        // Put symbols in table sorted by length, by symbol order within each length
        for (symbol = 0; symbol < n; symbol++) {
            if (lengths[start + symbol] != 0) {
                h.symbols[offs[lengths[start + symbol]]++] = symbol;
            }
        }

        // Left > 0 means incomplete
        return left > 0 ? ErrorCode.ERR_CONSTRUCT : ErrorCode.ERR_NONE;
    }

    function _codes(
        State memory s,
        Huffman memory lencode,
        Huffman memory distcode
    ) private pure returns (ErrorCode) {
        // Decoded symbol
        uint256 symbol;
        // Length for copy
        uint256 len;
        // Distance for copy
        uint256 dist;
        // TODO Solidity doesn't support constant arrays, but these are fixed at compile-time
        // Size base for length codes 257..285
        uint16[29] memory lens =
            [
                3,
                4,
                5,
                6,
                7,
                8,
                9,
                10,
                11,
                13,
                15,
                17,
                19,
                23,
                27,
                31,
                35,
                43,
                51,
                59,
                67,
                83,
                99,
                115,
                131,
                163,
                195,
                227,
                258
            ];
        // Extra bits for length codes 257..285
        uint8[29] memory lext =
            [
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                0,
                1,
                1,
                1,
                1,
                2,
                2,
                2,
                2,
                3,
                3,
                3,
                3,
                4,
                4,
                4,
                4,
                5,
                5,
                5,
                5,
                0
            ];
        // Offset base for distance codes 0..29
        uint16[30] memory dists =
            [
                1,
                2,
                3,
                4,
                5,
                7,
                9,
                13,
                17,
                25,
                33,
                49,
                65,
                97,
                129,
                193,
                257,
                385,
                513,
                769,
                1025,
                1537,
                2049,
                3073,
                4097,
                6145,
                8193,
                12289,
                16385,
                24577
            ];
        // Extra bits for distance codes 0..29
        uint8[30] memory dext =
            [
                0,
                0,
                0,
                0,
                1,
                1,
                2,
                2,
                3,
                3,
                4,
                4,
                5,
                5,
                6,
                6,
                7,
                7,
                8,
                8,
                9,
                9,
                10,
                10,
                11,
                11,
                12,
                12,
                13,
                13
            ];
        // Error code
        ErrorCode err;

        // Decode literals and length/distance pairs
        while (symbol != 256) {
            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return err;
            }

            if (symbol < 256) {
                // Literal: symbol is the byte
                // Write out the literal
                if (s.outcnt == s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                s.output[s.outcnt] = bytes1(uint8(symbol));
                s.outcnt++;
            } else if (symbol > 256) {
                uint256 tempBits;
                // Length
                // Get and compute length
                symbol -= 257;
                if (symbol >= 29) {
                    // Invalid fixed code
                    return ErrorCode.ERR_INVALID_LENGTH_OR_DISTANCE_CODE;
                }

                (err, tempBits) = bits(s, lext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                len = lens[symbol] + tempBits;

                // Get and check distance
                (err, symbol) = _decode(s, distcode);
                if (err != ErrorCode.ERR_NONE) {
                    // Invalid symbol
                    return err;
                }
                (err, tempBits) = bits(s, dext[symbol]);
                if (err != ErrorCode.ERR_NONE) {
                    return err;
                }
                dist = dists[symbol] + tempBits;
                if (dist > s.outcnt) {
                    // Distance too far back
                    return ErrorCode.ERR_DISTANCE_TOO_FAR;
                }

                // Copy length bytes from distance bytes back
                if (s.outcnt + len > s.output.length) {
                    return ErrorCode.ERR_OUTPUT_EXHAUSTED;
                }
                while (len != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    len -= 1;
                    s.output[s.outcnt] = s.output[s.outcnt - dist];
                    s.outcnt++;
                }
            } else {
                s.outcnt += len;
            }
        }

        // Done with a valid fixed or dynamic block
        return ErrorCode.ERR_NONE;
    }

    function _build_fixed(State memory s) private pure returns (ErrorCode) {
        // Build fixed Huffman tables
        // TODO this is all a compile-time constant
        uint256 symbol;
        uint256[] memory lengths = new uint256[](FIXLCODES);

        // Literal/length table
        for (symbol = 0; symbol < 144; symbol++) {
            lengths[symbol] = 8;
        }
        for (; symbol < 256; symbol++) {
            lengths[symbol] = 9;
        }
        for (; symbol < 280; symbol++) {
            lengths[symbol] = 7;
        }
        for (; symbol < FIXLCODES; symbol++) {
            lengths[symbol] = 8;
        }

        _construct(s.lencode, lengths, FIXLCODES, 0);

        // Distance table
        for (symbol = 0; symbol < MAXDCODES; symbol++) {
            lengths[symbol] = 5;
        }

        _construct(s.distcode, lengths, MAXDCODES, 0);

        return ErrorCode.ERR_NONE;
    }

    function _fixed(State memory s) private pure returns (ErrorCode) {
        // Decode data until end-of-block code
        return _codes(s, s.lencode, s.distcode);
    }

    function _build_dynamic_lengths(State memory s)
        private
        pure
        returns (ErrorCode, uint256[] memory)
    {
        uint256 ncode;
        // Index of lengths[]
        uint256 index;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Error code
        ErrorCode err;
        // Permutation of code length codes
        uint8[19] memory order =
            [16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15];

        (err, ncode) = bits(s, 4);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lengths);
        }
        ncode += 4;

        // Read code length code lengths (really), missing lengths are zero
        for (index = 0; index < ncode; index++) {
            (err, lengths[order[index]]) = bits(s, 3);
            if (err != ErrorCode.ERR_NONE) {
                return (err, lengths);
            }
        }
        for (; index < 19; index++) {
            lengths[order[index]] = 0;
        }

        return (ErrorCode.ERR_NONE, lengths);
    }

    function _build_dynamic(State memory s)
        private
        pure
        returns (
            ErrorCode,
            Huffman memory,
            Huffman memory
        )
    {
        // Number of lengths in descriptor
        uint256 nlen;
        uint256 ndist;
        // Index of lengths[]
        uint256 index;
        // Error code
        ErrorCode err;
        // Descriptor code lengths
        uint256[] memory lengths = new uint256[](MAXCODES);
        // Length and distance codes
        Huffman memory lencode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXLCODES));
        Huffman memory distcode =
            Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES));
        uint256 tempBits;

        // Get number of lengths in each table, check lengths
        (err, nlen) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        nlen += 257;
        (err, ndist) = bits(s, 5);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }
        ndist += 1;

        if (nlen > MAXLCODES || ndist > MAXDCODES) {
            // Bad counts
            return (
                ErrorCode.ERR_TOO_MANY_LENGTH_OR_DISTANCE_CODES,
                lencode,
                distcode
            );
        }

        (err, lengths) = _build_dynamic_lengths(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, lencode, distcode);
        }

        // Build huffman table for code lengths codes (use lencode temporarily)
        err = _construct(lencode, lengths, 19, 0);
        if (err != ErrorCode.ERR_NONE) {
            // Require complete code set here
            return (
                ErrorCode.ERR_CODE_LENGTHS_CODES_INCOMPLETE,
                lencode,
                distcode
            );
        }

        // Read length/literal and distance code length tables
        index = 0;
        while (index < nlen + ndist) {
            // Decoded value
            uint256 symbol;
            // Last length to repeat
            uint256 len;

            (err, symbol) = _decode(s, lencode);
            if (err != ErrorCode.ERR_NONE) {
                // Invalid symbol
                return (err, lencode, distcode);
            }

            if (symbol < 16) {
                // Length in 0..15
                lengths[index++] = symbol;
            } else {
                // Repeat instruction
                // Assume repeating zeros
                len = 0;
                if (symbol == 16) {
                    // Repeat last length 3..6 times
                    if (index == 0) {
                        // No last length!
                        return (
                            ErrorCode.ERR_REPEAT_NO_FIRST_LENGTH,
                            lencode,
                            distcode
                        );
                    }
                    // Last length
                    len = lengths[index - 1];
                    (err, tempBits) = bits(s, 2);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else if (symbol == 17) {
                    // Repeat zero 3..10 times
                    (err, tempBits) = bits(s, 3);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 3 + tempBits;
                } else {
                    // == 18, repeat zero 11..138 times
                    (err, tempBits) = bits(s, 7);
                    if (err != ErrorCode.ERR_NONE) {
                        return (err, lencode, distcode);
                    }
                    symbol = 11 + tempBits;
                }

                if (index + symbol > nlen + ndist) {
                    // Too many lengths!
                    return (ErrorCode.ERR_REPEAT_MORE, lencode, distcode);
                }
                while (symbol != 0) {
                    // Note: Solidity reverts on underflow, so we decrement here
                    symbol -= 1;

                    // Repeat last or zero symbol times
                    lengths[index++] = len;
                }
            }
        }

        // Check for end-of-block code -- there better be one!
        if (lengths[256] == 0) {
            return (ErrorCode.ERR_MISSING_END_OF_BLOCK, lencode, distcode);
        }

        // Build huffman table for literal/length codes
        err = _construct(lencode, lengths, nlen, 0);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                nlen != lencode.counts[0] + lencode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_LITERAL_LENGTH_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        // Build huffman table for distance codes
        err = _construct(distcode, lengths, ndist, nlen);
        if (
            err != ErrorCode.ERR_NONE &&
            (err == ErrorCode.ERR_NOT_TERMINATED ||
                err == ErrorCode.ERR_OUTPUT_EXHAUSTED ||
                ndist != distcode.counts[0] + distcode.counts[1])
        ) {
            // Incomplete code ok only for single length 1 code
            return (
                ErrorCode.ERR_INVALID_DISTANCE_CODE_LENGTHS,
                lencode,
                distcode
            );
        }

        return (ErrorCode.ERR_NONE, lencode, distcode);
    }

    function _dynamic(State memory s) private pure returns (ErrorCode) {
        // Length and distance codes
        Huffman memory lencode;
        Huffman memory distcode;
        // Error code
        ErrorCode err;

        (err, lencode, distcode) = _build_dynamic(s);
        if (err != ErrorCode.ERR_NONE) {
            return err;
        }

        // Decode data until end-of-block code
        return _codes(s, lencode, distcode);
    }

    function puff(bytes memory source, uint256 destlen)
        internal
        pure
        returns (ErrorCode, bytes memory)
    {
        // Input/output state
        State memory s =
            State(
                new bytes(destlen),
                0,
                source,
                0,
                0,
                0,
                Huffman(new uint256[](MAXBITS + 1), new uint256[](FIXLCODES)),
                Huffman(new uint256[](MAXBITS + 1), new uint256[](MAXDCODES))
            );
        // Temp: last bit
        uint256 last;
        // Temp: block type bit
        uint256 t;
        // Error code
        ErrorCode err;

        // Build fixed Huffman tables
        err = _build_fixed(s);
        if (err != ErrorCode.ERR_NONE) {
            return (err, s.output);
        }

        // Process blocks until last block or error
        while (last == 0) {
            // One if last block
            (err, last) = bits(s, 1);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            // Block type 0..3
            (err, t) = bits(s, 2);
            if (err != ErrorCode.ERR_NONE) {
                return (err, s.output);
            }

            err = (
                t == 0
                    ? _stored(s)
                    : (
                        t == 1
                            ? _fixed(s)
                            : (
                                t == 2
                                    ? _dynamic(s)
                                    : ErrorCode.ERR_INVALID_BLOCK_TYPE
                            )
                    )
            );
            // type == 3, invalid

            if (err != ErrorCode.ERR_NONE) {
                // Return with error
                break;
            }
        }

        return (err, s.output);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
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

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
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
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
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