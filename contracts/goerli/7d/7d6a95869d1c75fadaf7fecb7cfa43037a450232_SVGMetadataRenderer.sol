// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IMetadataRenderer } from "../interfaces/IMetadataRenderer.sol";
import { ICuratorInfo, IERC721Metadata } from "../interfaces/ICuratorInfo.sol";
import { IZoraDrop } from "../interfaces/IZoraDrop.sol";
import { ICurator } from "../interfaces/ICurator.sol";

import { CurationMetadataBuilder } from "./CurationMetadataBuilder.sol";
import { MetadataBuilder } from "micro-onchain-metadata-utils/MetadataBuilder.sol";
import { MetadataJSONKeys } from "micro-onchain-metadata-utils/MetadataJSONKeys.sol";

contract SVGMetadataRenderer is IMetadataRenderer {
    function initializeWithData(bytes memory initData) public {}

    enum RenderingType {
        CURATION,
        NFT,
        EDITION,
        CONTRACT,
        ADDRESS
    }

    function makeHSL(
        uint16 h,
        uint16 s,
        uint16 l
    ) internal pure returns (string memory) {
        return string.concat("hsl(", Strings.toString(h), ",", Strings.toString(s), "%,", Strings.toString(l), "%)");
    }

    function _getTotalSupplySaturation(address nft) public view returns (uint16) {
        try ICurator(nft).totalSupply() returns (uint256 supply) {
            if (supply > 10000) {
                return 100;
            }
            if (supply > 1000) {
                return 75;
            }
            if (supply > 100) {
                return 50;
            }
        } catch {}
        return 10;
    }

    function _getEditionPercentMintedSaturationSquareDensity(address nft) internal view returns (uint16 saturation, uint256 density) {
        try IZoraDrop(nft).saleDetails() returns (IZoraDrop.SaleDetails memory saleDetails) {
            uint256 bpsMinted = (saleDetails.totalMinted * 10000) / saleDetails.maxSupply;
            if (bpsMinted > 7500) {
                return (100, 20);
            }
            if (bpsMinted > 5000) {
                return (75, 50);
            }
            if (bpsMinted > 2500) {
                return (50, 70);
            }
        } catch {}
        return (10, 100);
    }

    function generateGridForAddress(
        address target,
        RenderingType types,
        address owner
    ) public view returns (string memory) {
        uint16 saturationOuter = 25;

        uint256 squares = 0;
        uint256 freqDiv = 23;
        uint256 hue = 0;

        if (types == RenderingType.NFT) {
            squares = 4;
            freqDiv = 23;
            hue = 168;
            saturationOuter = _getTotalSupplySaturation(owner);
        }

        if (types == RenderingType.EDITION) {
            (saturationOuter, freqDiv) = _getEditionPercentMintedSaturationSquareDensity(owner);
            hue = 317;
        }

        if (types == RenderingType.ADDRESS) {
            hue = 317;
        }

        if (types == RenderingType.CURATION) {
            hue = 120;
        }

        string memory svgInner = string.concat(
            CurationMetadataBuilder._makeSquare({ size: 720, x: 0, y: 0, color: makeHSL({ h: 317, s: saturationOuter, l: 30 }) }),
            CurationMetadataBuilder._makeSquare({ size: 600, x: 30, y: 98, color: makeHSL({ h: 317, s: saturationOuter, l: 50 }) }),
            CurationMetadataBuilder._makeSquare({ size: 480, x: 60, y: 180, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) }),
            CurationMetadataBuilder._makeSquare({ size: 60, x: 90, y: 270, color: makeHSL({ h: 317, s: saturationOuter, l: 70 }) })
        );

        uint256 addr = uint160(uint160(owner));
        for (uint256 i = 0; i < squares * squares; i++) {
            addr /= freqDiv;
            if (addr % 3 == 0) {
                uint256 size = 720 / squares;
                svgInner = string.concat(
                    svgInner,
                    CurationMetadataBuilder._makeSquare({ size: size, x: (i % squares) * size, y: (i / squares) * size, color: "rgba(0, 0, 0, 0.4)" })
                );
            }
        }

        return MetadataBuilder.generateEncodedSVG(svgInner, "0 0 720 720", "720", "720");
    }

    function contractURI() external view override returns (string memory) {
        ICuratorInfo curation = ICuratorInfo(msg.sender);
        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](3);

        string memory curationName = "Untitled NFT";

        try curation.curationPass().name() returns (string memory result) {
            curationName = result;
        } catch {}

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat("Curator: ", curation.name());
        items[0].quote = true;

        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This is a curation NFT owned by ",
            Strings.toHexString(curation.owner()),
            "\\n\\nThe NFTs in this collection mark curators curating this collection."
            "The curation pass for this NFT is ",
            curationName,
            "\\n\\nThese NFTs only mark curations and are non-transferrable."
            "\\n\\nView or manage this curation at: "
            "https://public---assembly.com/curation/",
            Strings.toHexString(msg.sender),
            "\\n\\nA project of public assembly."
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].quote = true;
        items[2].value = generateGridForAddress(msg.sender, RenderingType.CURATION, address(0x0));

        return MetadataBuilder.generateEncodedJSON(items);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        ICurator curator = ICurator(msg.sender);

        MetadataBuilder.JSONItem[] memory items = new MetadataBuilder.JSONItem[](4);
        MetadataBuilder.JSONItem[] memory properties = new MetadataBuilder.JSONItem[](0);
        ICurator.Listing memory listing = curator.getListing(tokenId);

        string memory curationName = "Untitled NFT";
        string memory curationType = "Generic";
        RenderingType renderingType = RenderingType.ADDRESS;
        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_ITEM()) {
            renderingType = RenderingType.NFT;
            properties = new MetadataBuilder.JSONItem[](3);
            properties[0].key = "type";
            properties[0].value = "nft item";
            properties[0].quote = true;
            properties[1].key = "contract";
            properties[1].value = Strings.toHexString(listing.curatedAddress);
            properties[1].quote = true;
            if (listing.hasTokenId) {
                properties[2].key = "token id";
                properties[2].value = Strings.toString(uint256(listing.selectedTokenId));
                properties[2].quote = true;
            }
        } else if (listing.curationTargetType == curator.CURATION_TYPE_NFT_CONTRACT()) {
            renderingType = RenderingType.CONTRACT;
            properties[0].key = "type";
            properties[0].value = "nft contract";
            properties[0].quote = true;
            properties[1].key = "contract";
            properties[1].value = Strings.toHexString(listing.curatedAddress);
            properties[1].quote = true;
        } else if (listing.curationTargetType == curator.CURATION_TYPE_ZORA_EDITION()) {
            properties = new MetadataBuilder.JSONItem[](2);
            properties[0].key = "type";
            properties[0].value = "zora edition";
            properties[0].quote = true;
            properties[1].key = "contract";
            properties[1].value = Strings.toHexString(listing.curatedAddress);
            properties[1].quote = true;
            renderingType = RenderingType.EDITION;
        } else if (listing.curationTargetType == curator.CURATION_TYPE_CURATION_CONTRACT()) {
            renderingType = RenderingType.CONTRACT;
            properties = new MetadataBuilder.JSONItem[](2);
            properties[0].key = "type";
            properties[0].value = "curation";
            properties[0].quote = true;
            properties[1].key = "contract";
            properties[1].value = Strings.toHexString(listing.curatedAddress);
            properties[1].quote = true;
        }

        if (listing.curationTargetType == curator.CURATION_TYPE_NFT_CONTRACT() || listing.curationTargetType == curator.CURATION_TYPE_NFT_ITEM()) {
            if (listing.curatedAddress.code.length > 0) {
                try ICuratorInfo(listing.curatedAddress).name() returns (string memory result) {
                    curationName = result;
                } catch {}
            }
        }

        items[0].key = MetadataJSONKeys.keyName;
        items[0].value = string.concat("Curation #", Strings.toString(tokenId), ": ", curationName);
        items[0].quote = true;
        items[1].key = MetadataJSONKeys.keyDescription;
        items[1].value = string.concat(
            "This is an item curated by ",
            Strings.toHexString(listing.curator),
            "\\n\\nTo remove this curation, burn the NFT. "
            "\\n\\nThis NFT is non-transferrable. "
            "\\n\\nView or manage this curation at: "
            "https://public---assembly.com/curation/",
            Strings.toHexString(msg.sender)
        );
        items[1].quote = true;
        items[2].key = MetadataJSONKeys.keyImage;
        items[2].value = generateGridForAddress(msg.sender, renderingType, listing.curatedAddress);
        items[2].quote = true;
        items[3].key = MetadataJSONKeys.keyProperties;
        items[3].value = MetadataBuilder.generateJSON(properties);
        items[3].quote = false;

        return MetadataBuilder.generateEncodedJSON(items);
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
pragma solidity ^0.8.15;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface ICuratorInfo {
    function name() external view returns (string memory);

    function curationPass() external view returns (IERC721Metadata);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IZoraDrop {
    /// @notice Function to return the global sales details for the given drop
    function saleDetails() external view returns (SaleDetails memory);

    /// @notice Return value for sales details to use with front-ends
    struct SaleDetails {
        // Synthesized status variables for sale and presale
        bool publicSaleActive;
        bool presaleActive;
        // Price for public sale
        uint256 publicSalePrice;
        // Timed sale actions for public sale
        uint64 publicSaleStart;
        uint64 publicSaleEnd;
        // Timed sale actions for presale
        uint64 presaleStart;
        uint64 presaleEnd;
        // Merkle root (includes address, quantity, and price data for each entry)
        bytes32 presaleMerkleRoot;
        // Limit public sale to a specific number of mints per wallet
        uint256 maxSalePurchasePerAddress;
        // Information about the rest of the supply
        // Total that have been minted
        uint256 totalMinted;
        // The total supply available
        uint256 maxSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * Curator interfaces
 */
interface ICurator {
    /// @notice Convience getter for Generic/unknown types (default 0). Used for metadata as well.
    function CURATION_TYPE_GENERIC() external view returns (uint16);
    /// @notice Convience getter for NFT contract types. Used for metadata as well.
    function CURATION_TYPE_NFT_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for generic contract types. Used for metadata as well.
    function CURATION_TYPE_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for curation contract types. Used for metadata as well.
    function CURATION_TYPE_CURATION_CONTRACT() external view returns (uint16);
    /// @notice Convience getter for NFT item types. Used for metadata as well.
    function CURATION_TYPE_NFT_ITEM() external view returns (uint16);
    /// @notice Convience getter for wallet types. Used for metadata as well.
    function CURATION_TYPE_WALLET() external view returns (uint16);
    /// @notice Convience getter for ZORA drops contract types. Used for metadata as well.
    function CURATION_TYPE_ZORA_EDITION() external view returns (uint16);

    /// @notice Shared listing struct for both access and storage.
    struct Listing {
        /// @notice Address that is curated
        address curatedAddress;
        /// @notice Token ID that is selected (see `hasTokenId` to see if this applies)
        uint96 selectedTokenId;
        /// @notice Address that curated this entry
        address curator;
        /// @notice Curation type (see public getters on contract for list of types)
        uint16 curationTargetType;
        /// @notice Optional sort order, can be negative. Utilized optionally like css z-index for sorting.
        int32 sortOrder;
        /// @notice If the token ID applies to the curation (can be whole contract or a specific tokenID)
        bool hasTokenId;
        /// @notice ChainID for curated contract
        uint16 chainId;
    }

    /// @notice Getter for a single listing id
    function getListing(uint256 listingIndex) external view returns (Listing memory);

    /// @notice Getter for a all listings
    function getListings() external view returns (Listing[] memory activeListings);

    /// @notice Total supply getter for number of active listings
    function totalSupply() external view returns (uint256);

    /// @notice Removes a list of listings. Same as `burn` but supports multiple listings.
    function removeListings(uint256[] calldata listingIds) external;

    /// @notice Removes a single listing. Named for ERC721 de-facto compat
    function burn(uint256 listingId) external;

    /// @notice Emitted when a listing is added
    event ListingAdded(address indexed curator, Listing listing);

    /// @notice Emitted when a listing is removed
    event ListingRemoved(address indexed curator, Listing listing);

    /// @notice The token pass has been updated for the curation
    /// @dev Any users that have already curated something still can delete their curation.
    event TokenPassUpdated(address indexed owner, address tokenPass);

    /// @notice A new renderer is set
    event SetRenderer(address);

    /// @notice Curation Pause has been udpated.
    event CurationPauseUpdated(address indexed owner, bool isPaused);

    /// @notice Curation limit has beeen updated
    event UpdatedCurationLimit(uint256 newLimit);

    /// @notice Sort order has been updated
    event UpdatedSortOrder(uint256[] ids, int32[] sorts, address updatedBy);

    /// @notice This contract is scheduled to be frozen
    event ScheduledFreeze(uint256 timestamp);

    /// @notice Pass is required to manage curation but not held by attempted updater.
    error PASS_REQUIRED();

    /// @notice Only the curator of a listing (or owner) can manage that curation
    error ONLY_CURATOR();

    /// @notice Wrong curator for the listing when attempting to access the listing.
    error WRONG_CURATOR_FOR_LISTING(address setCurator, address expectedCurator);

    /// @notice Action is unable to complete because the curation is paused.
    error CURATION_PAUSED();

    /// @notice The pause state needs to be toggled and cannot be set to it's current value.
    error CANNOT_SET_SAME_PAUSED_STATE();

    /// @notice Error attempting to update the curation after it has been frozen
    error CURATION_FROZEN();

    /// @notice The curation has gone above the curation limit
    error TOO_MANY_ENTRIES();

    /// @notice Access not allowed by given user
    error ACCESS_NOT_ALLOWED();

    /// @notice attempt to get owner of an unowned / burned token
    error TOKEN_HAS_NO_OWNER();

    /// @notice Array input lengths don't match for sort orders
    error INVALID_INPUT_LENGTH();

    /// @notice Curation limit can only be increased, not decreased.
    error CANNOT_UPDATE_CURATION_LIMIT_DOWN();

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _tokenPass,
        bool _pause,
        uint256 _curationLimit,
        address _renderer,
        bytes memory _rendererInitializer,
        Listing[] memory _initialListings
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Strings } from "micro-onchain-metadata-utils/lib/Strings.sol";

/// @title CurationMetadataBuilder
/// @author Iain Nash
/// @notice Curation Metadata Builder Tools
library CurationMetadataBuilder {
    /// @notice Arduino-style map function that takes x from a range and maps to a range of y.
    function map(
        uint256 x,
        uint256 xMax,
        uint256 xMin,
        uint256 yMin,
        uint256 yMax
    ) internal pure returns (uint256) {
        return ((x - xMin) * (yMax - yMin)) / (xMax - xMin) + yMin;
    }

    /// @notice Makes a SVG square rect with the given parameters
    function _makeSquare(
        uint256 size,
        uint256 x,
        uint256 y,
        string memory color
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<rect x="',
                Strings.toString(x),
                '" y="',
                Strings.toString(y),
                '" width="',
                Strings.toString(size),
                '" height="',
                Strings.toString(size),
                '" style="fill: ',
                color,
                '" />'
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base64} from "./lib/Base64.sol";
import {Strings} from "./lib/Strings.sol";
import {MetadataMIMETypes} from "./MetadataMIMETypes.sol";

library MetadataBuilder {
    struct JSONItem {
        string key;
        string value;
        bool quote;
    }

    function generateSVG(
        string memory contents,
        string memory viewBox,
        string memory width,
        string memory height
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<svg viewBox="',
                viewBox,
                '" xmlns="http://www.w3.org/2000/svg" width="',
                width,
                '" height="',
                height,
                '">',
                contents,
                "</svg>"
            );
    }

    function generateEncodedSVG(
        string memory contents,
        string memory viewBox,
        string memory width,
        string memory height
    ) internal pure returns (string memory) {
        return
            encodeURI(
                MetadataMIMETypes.mimeSVG,
                generateSVG(contents, viewBox, width, height)
            );
    }

    function encodeURI(string memory uriType, string memory result)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "data:",
                uriType,
                ";base64,",
                string(Base64.encode(bytes(result)))
            );
    }

    function generateJSONArray(JSONItem[] memory items)
        internal
        pure
        returns (string memory result)
    {
        result = "[";
        uint256 added = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (bytes(items[i].value).length == 0) {
                continue;
            }
            if (items[i].quote) {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    '"',
                    items[i].value,
                    '"'
                );
            } else {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    items[i].value
                );
            }
            added += 1;
        }
        result = string.concat(result, "]");
    }

    function generateJSON(JSONItem[] memory items)
        internal
        pure
        returns (string memory result)
    {
        result = "{";
        uint256 added = 0;
        for (uint256 i = 0; i < items.length; i++) {
            if (bytes(items[i].value).length == 0) {
                continue;
            }
            if (items[i].quote) {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    '"',
                    items[i].key,
                    '": "',
                    items[i].value,
                    '"'
                );
            } else {
                result = string.concat(
                    result,
                    added == 0 ? "" : ",",
                    '"',
                    items[i].key,
                    '": ',
                    items[i].value
                );
            }
            added += 1;
        }
        result = string.concat(result, "}");
    }

    function generateEncodedJSON(JSONItem[] memory items)
        internal
        pure
        returns (string memory)
    {
        return encodeURI(MetadataMIMETypes.mimeJSON, generateJSON(items));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library MetadataJSONKeys {
   string constant keyName = "name";
   string constant keyDescription = "description";
   string constant keyImage = "image";
   string constant keyAnimationURL = "animation_url";
   string constant keyAttributes = "attributes";
   string constant keyProperties = "properties";
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
pragma solidity 0.8.15;

library MetadataMIMETypes {
    string constant mimeJSON = "application/json";
    string constant mimeSVG = "image/svg+xml";
    string constant mimeTextPlain = "text/plain";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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