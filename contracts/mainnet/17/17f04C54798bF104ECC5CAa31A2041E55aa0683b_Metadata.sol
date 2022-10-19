// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


interface IStreets {
    function getStreetData(uint256 tokenId) external view returns (uint16[5] memory condoIds, uint16 background, bytes20 name);
}

/*
 * @title CondoMini Metadata
 * @author Ponderware Ltd
 * @dev Metadata assembly contract for CondoMini Streets NFT
 */
contract Metadata {
    // IMoonCatSVGS MoonCatSVGS = IMoonCatSVGS(0xB39C61fe6281324A23e079464f7E697F8Ba6968f);
    IStreets Streets;

    string BASE_IMAGE_URI = "https://condomini.io/api/street/";
    string public IPFS_URI_Prefix = "https://ponderware.mypinata.cloud/ipfs/";
    string public CONDOS_TOKEN_URI = ""; // "ipfs://ipfs-cid/{id}.json"
    string public CONDOS_IPFS_CID = "";
    string public STREETS_PREREVEAL_URI = "";
    string public BACKGROUNDS_IPFS_CID = "";
    uint16 public totalBackgrounds = 20;

    address public owner;
    address public condosAddress;
    address public streetsAddress;

    bool public revealed = false;
    bool public frozen = false;

    string internal description = "It's a beautiful day in your neighborhood.";

    string[] internal BackgroundNames =
        ["Crisp Autumn",
         "Deep Cave",
         "Deep Impact",
         "Fireworks",
         "Gods Are Angry",
         "Good Morning",
         "Heavy Rain",
         "Mars Colony",
         "Retrowave",
         "Sand Dunes",
         "Serene Afternoon",
         "Snowy Fields",
         "Sp00ky",
         "Starry Night",
         "Stormy Weather",
         "Tea Time",
         "Thick Fog",
         "Thicket",
         "To the Moon",
         "Under the Sea"
         ];

    string[145] internal CondoNames =
        ["NYC Apartment",
         "Gacha Office",
         unicode"Parisien Cafè",
         "Mountain House",
         "Honey Factory",
         "Coffee Pool",
         "TV Studio",
         "Greenhouse",
         "Post Office",
         "Desert House",
         "Lounge Bar",
         "Detective's Snowball",
         "Stilt House",
         "Vintage Arcade",
         "Bronko's Stadium",
         "Nomad Trailer",
         "Stargazer Observatory",
         "Maiden's Tower",
         "Shopping Centre",
         "Underhill House",
         "Noire Movie Set",
         "MoonCats Shelter",
         "Konbini",
         "Library",
         "Modular Spaces",
         "Birthday Cake",
         "Rocky Camp Tent",
         "Amanita House",
         "City Hall",
         "Rue Hall",
         "Barn",
         "Lighthouse",
         "Transistor Radio",
         "Boat House",
         "Fish Tank",
         "Toaster",
         "Loudspeaker",
         "Snail Shell",
         "Fire Hydrant",
         "Modern House",
         "Death Ball",
         "Brick House",
         "Safe Bank",
         "Gas Station",
         "Sappy Igloo",
         "Medieval House",
         "Pet Care",
         "Academy",
         "Trolley Gate",
         "Gum Parlor",
         "Games Palace",
         "Victorian Manor",
         "STARKADE Arena",
         "Construction Site",
         "Pizzeria",
         "Cyber Condo",
         "Lunar Plots Platform",
         "Pirate Island",
         "Worldwide Webb Apartment",
         "Legion Arena",
         "Curio Castle",
         "Rice Onsen",
         "Belfry Ruins",
         "Curio Coffee Shop",
         "Pixelmap House",
         "Dog House",
         "Plant Frens Shop",
         "Weapons Chest",
         "Realms of Ether Castle",
         "PunyCodes House",
         "Western Saloon",
         "Isotile Building",
         "MoonCats' Fort of Boxes",
         "Mausoleum",
         "Fast Food Truck",
         "Grain Mill",
         "Empire Skyscraper",
         "Mecha House",
         "NYC Condo",
         "Pachinko Parlor",
         "Parisien Atelier",
         "Winter House",
         "Candles Factory",
         "News Studio",
         "Mystic House",
         "Santa's Factory",
         "Bazaar",
         "Organic Bar",
         "Reader's Snowball",
         "Bayou House",
         "Esports Arcade",
         "Rugby Arena",
         "Peace Van",
         "Alien Research Facility",
         "Clock Tower",
         "Grochery Store",
         "Epic Movie Set",
         "Diner",
         "Typography",
         "Docks Containers",
         "Rainbow Cake",
         "Pine Ridge Tent",
         "Bolete House",
         "Town Hall",
         "Stables",
         "Medieval Beacon",
         "Stadio Radio",
         "Pirate House",
         "Potty Tank",
         "Toast Burner",
         "Concert Venue",
         "Seashell",
         "Fire Station",
         "Korean Estate",
         "Hal-0",
         "MOC House",
         "Piggy Bank",
         "Petrol Station",
         "Tent Igloo",
         "Medieval Smith",
         "Hospital",
         "Boiler Room",
         "Luggage Airport",
         "Candy Shop",
         "Flipper Playroom",
         "Haunted Manor",
         "Empty Lot",
         "Pizza Take Away",
         "Dystopic Tower",
         "Saint's Ruins",
         "Wizard's Chest",
         "Western Emporium",
         "Waterfall Mill",
         "Capsule Tower",
         "Mecha HQ",
         "Tokyo Tower",
         "UFO Crash",
         "Fountain",
         "Railroad",
         "City Park",
         "Planes Gate",
         "Y-Rex",
         "Ferry Wheel",
         "Woods",
         "City Gate"
         ];


    /**
     * @dev Encode a key/value pair as a JSON trait property, where the value is a string item (needs quotes around it)
     */
    function encodeStringAttribute(string memory key, string memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":\"",value,"\"}");
    }
   /**
     * @dev Convert an integer/numeric value into a string of that number's decimal value.
     */
    function uint2str (uint value) public pure returns (string memory) {
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
     * @dev Encode a key/value pair as a JSON trait property, where the value is a number item (doesn't need quotes)
     */
    function encodeLevelAttribute (string memory key, uint256 value) internal pure returns (bytes memory) {
        return abi.encodePacked("{\"trait_type\":\"", key,"\",\"value\":",uint2str(value),",\"max_value\":5}");
    }

    function getCondoNameAttribute (uint256 condoId) internal view returns (bytes memory) {
        if (condoId < 135) {
            return encodeStringAttribute("Condo", CondoNames[condoId]);
        } else {
            if (condoId < 270) {
                return encodeStringAttribute("Condo", string(abi.encodePacked("Gold ", CondoNames[condoId - 135])));
            } else {
                return encodeStringAttribute("Landmark", CondoNames[condoId - 135]);
            }
        }
    }



    function getStreetAttributes (uint16[5] memory condoIds, uint16 background) internal view returns (bytes memory) {

        uint golds = 0;
        uint landmarks = 0;

        for (uint i = 0; i < 5; i++) {
            uint condoId = condoIds[i];
            if (condoId >= 135) {
                if (condoId < 270) {
                    golds++;
                } else {
                    landmarks++;
                }
            }
        }

        bytes memory special;

        if (golds == 5) {
            special = abi.encodePacked(encodeStringAttribute("Special", "Gilded"), ",");
        } else if (landmarks == 5) {
            special = abi.encodePacked(encodeStringAttribute("Special", "Monumental"), ",");
        }

        return abi.encodePacked(getCondoNameAttribute(condoIds[0]), ",",
                                getCondoNameAttribute(condoIds[1]), ",",
                                getCondoNameAttribute(condoIds[2]), ",",
                                getCondoNameAttribute(condoIds[3]), ",",
                                getCondoNameAttribute(condoIds[4]), ",",
                                encodeLevelAttribute("Golds", golds), ",",
                                encodeLevelAttribute("Landmarks", landmarks), ",",
                                special,
                                encodeStringAttribute("Background", BackgroundNames[background])
                                );
    }

    function decodeName (bytes20 name) internal pure returns (bytes memory) {
        uint nameLength = 0;
        for (; nameLength < 20; nameLength++) {
            if (name[nameLength] == 0) {
                break;
            }
        }
        if (nameLength == 0) {
            return bytes("CondoMini Neighborhood");
        } else {
            bytes memory outputName;
            for (uint i = 0; i < nameLength; i++) {
                outputName = abi.encodePacked(outputName, name[i]);
            }
            return outputName;
        }
    }

    /**
     * @dev Update metadata description string
     */
    function updateDescription (string calldata newDescription) public onlyOwner {
        description = newDescription;
    }

    /**
     * @dev Assemble the imageURI for the given attributes
     */
    function imageURI(uint16[5] memory condoIds, uint16 background) internal view returns (bytes memory) {
        bytes memory uri = bytes(BASE_IMAGE_URI);
        for (uint i = 0; i < 5; i++) {
            uri = abi.encodePacked(uri, uint2str(condoIds[i]), "-");
        }
        return abi.encodePacked(uri, uint2str(background), ".png");
    }

    /**
     * @dev Generate full BASE64-encoded JSON metadata
     */
    function streetMetadata(uint256 tokenId) public view returns (string memory) {
        (uint16[5] memory condoIds, uint16 background, bytes20 name) = IStreets(streetsAddress).getStreetData(tokenId);
        string memory tokenIdString = uint2str(tokenId);
        bytes memory img = imageURI(condoIds, background);

        bytes memory json = abi.encodePacked(
            '{"attributes":[',
                            getStreetAttributes(condoIds, background),
                            ",", encodeStringAttribute("tokenId", tokenIdString),
            '], "name":"',
            decodeName(name),
            '", "description":"',
            description,
            '","image":"',
            img,
            '","external_url": "https://condomini.io"}'
                                             );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json)));
    }

    /**
     * @dev Set the baseURI for the image generator (images can also be assembled on-chain in the main contract)
     */
    function setBaseImageURI(string calldata baseUri) public onlyOwner {
        BASE_IMAGE_URI = baseUri;
    }

    function setIpfsURIPrefix(string calldata ipfsURIPrefix) public onlyOwner {
        IPFS_URI_Prefix = ipfsURIPrefix;
    }

    function setCondosMeta(string calldata tokenUri, string calldata ipfsCid) public onlyOwner {
        require(frozen == false, "Metadata frozen");
        CONDOS_TOKEN_URI = tokenUri;
        CONDOS_IPFS_CID = ipfsCid;
    }

    function updateBackground(string calldata ipfsCid) public onlyOwner {
        BACKGROUNDS_IPFS_CID = ipfsCid;
    }

    function addBackground(string calldata ipfsCid, string calldata backgroundName) public onlyOwner {
        BACKGROUNDS_IPFS_CID = ipfsCid;
        BackgroundNames[totalBackgrounds] = backgroundName;
        totalBackgrounds++;
    }

    function setCondosAddress(address contractAddress) public onlyOwner {
        require(condosAddress == address(0), "Condos address already set");
        condosAddress = contractAddress;
    }

    function setStreetsAddress(address contractAddress) public onlyOwner {
        require(streetsAddress == address(0), "Streets address already set");
        streetsAddress = contractAddress;
    }

    function reveal(string calldata tokenUri, string calldata ipfsCid) public onlyOwner {
        require(revealed == false, "Already revealed");
        setCondosMeta(tokenUri, ipfsCid);
        revealed = true;
    }

    function freeze() public onlyOwner {
        frozen = true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    constructor(string memory condosUri, string memory streetsUri) {
        owner = msg.sender;
        CONDOS_TOKEN_URI = condosUri;
        STREETS_PREREVEAL_URI = streetsUri;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    /* Rescuers */
    /**
     * @dev Rescue ETH sent directly to this contract.
     */
    function withdraw() public {
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), owner, tokenId);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
                let resultPtr := add(result, 32)

                for {
                     let i := 0
                } lt(i, len) {

            } {
            i := add(i, 3)
            let input := and(mload(add(data, i)), 0xffffff)

            let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
            out := shl(8, out)
            out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
            out := shl(224, out)

            mstore(resultPtr, out)

            resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
                          case 1 {
                                  mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
            case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
                }

        return string(result);
    }
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