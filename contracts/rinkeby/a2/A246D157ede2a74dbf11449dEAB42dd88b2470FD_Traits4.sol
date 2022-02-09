// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ITraits.sol";
import "IPoliceAndThief.sol";
import "IThiefUpgrading.sol";

contract Traits4 is Ownable {
    uint256 private alphaTypeIndex = 17;

    // struct to store each trait's data for metadata and rendering
    struct Trait {
        string name;
        string png;
    }

    string policeBody;
    string thiefBody;

    // mapping from trait type (index) to its name
    string[9] traitTypes = [
        "Uniform",
        "Clothes",
        "Hair",
        "Facial Hair",
        "Eyes",
        "Headgear",
        "Accessory",
        "Neck Gear",
        "Alpha"
    ];
    // storage of each traits name and base64 PNG data
    mapping(uint8 => mapping(uint8 => Trait)) public traitData;
    mapping(uint8 => uint8) public traitCountForType;
    // mapping from alphaIndex to its score
    string[4] _alphas = ["8", "7", "6", "5"];

    address public policeAndThief;
    ITraits old;
    IThiefUpgrading public upgrading;

    function selectTrait(uint16 seed, uint8 traitType)
        external
        view
        returns (uint8)
    {
        if (traitType == alphaTypeIndex) {
            uint256 m = seed % 100;
            if (m > 95) {
                return 0;
            } else if (m > 80) {
                return 1;
            } else if (m > 50) {
                return 2;
            } else {
                return 3;
            }
        }
        uint8 modOf = traitCountForType[traitType] > 0
            ? traitCountForType[traitType]
            : 10;
        return uint8(seed % modOf);
    }

    /***ADMIN */

    function uploadBodies(string calldata _police, string calldata _thief)
        external
        onlyOwner
    {
        policeBody = _police;
        thiefBody = _thief;
    }

    /**
     * administrative to upload the names and images associated with each trait
     * @param traitType the trait type to upload the traits for (see traitTypes for a mapping)
     * @param traits the names and base64 encoded PNGs for each trait
     */
    function uploadTraits(
        uint8 traitType,
        uint8[] calldata traitIds,
        Trait[] calldata traits
    ) external onlyOwner {
        require(traitIds.length == traits.length, "Mismatched inputs");

        for (uint256 i = 0; i < traits.length; i++) {
            traitData[traitType][traitIds[i]] = Trait(
                traits[i].name,
                traits[i].png
            );
        }
    }

    function setTraitCountForType(uint8[] memory _tType, uint8[] memory _len)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tType.length; i++) {
            traitCountForType[_tType[i]] = _len[i];
        }
    }

    /***RENDER */

    /**
     * generates an <image> element using base64 encoded PNGs
     * @param trait the trait storing the PNG data
     * @return the <image> element
     */
    function drawTrait(Trait memory trait)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    trait.png,
                    '"/>'
                )
            );
    }

    function draw(string memory png) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<image x="4" y="4" width="32" height="32" image-rendering="pixelated" preserveAspectRatio="xMidYMid" xlink:href="data:image/png;base64,',
                    png,
                    '"/>'
                )
            );
    }

    /**
     * generates an entire SVG by composing multiple <image> elements of PNGs
     * @param tokenId the ID of the token to generate an SVG for
     * @return a valid SVG of the Thief / Police
     */
    function drawSVG(uint256 tokenId) public view returns (string memory) {
        IPoliceAndThief.ThiefPolice memory s = IPoliceAndThief(policeAndThief)
            .getTokenTraits(tokenId);
        uint8 level = upgrading.levelOf(tokenId);
        uint8 shift = s.isThief ? 0 : 10;

        string memory svgString = string(
            abi.encodePacked(
                s.isThief ? draw(thiefBody) : draw(policeBody),
                s.isThief && level > 0 ? drawTrait(traitData[7][level]) : "",
                drawTrait(
                    traitData[0 + shift][
                        s.uniform % traitCountForType[0 + shift]
                    ]
                ),
                drawTrait(
                    traitData[1 + shift][s.hair % traitCountForType[1 + shift]]
                ),
                drawTrait(
                    traitData[2 + shift][
                        s.facialHair % traitCountForType[2 + shift]
                    ]
                ),
                drawTrait(
                    traitData[3 + shift][s.eyes % traitCountForType[3 + shift]]
                ),
                drawTrait(
                    traitData[4 + shift][
                        s.accessory % traitCountForType[4 + shift]
                    ]
                ),
                s.isThief
                    ? drawTrait(
                        traitData[5 + shift][
                            s.headgear % traitCountForType[5 + shift]
                        ]
                    )
                    : drawTrait(traitData[5 + shift][s.alphaIndex]),
                !s.isThief
                    ? drawTrait(
                        traitData[6 + shift][
                            s.neckGear % traitCountForType[6 + shift]
                        ]
                    )
                    : ""
            )
        );

        return
            string(
                abi.encodePacked(
                    '<svg id="policeAndThiefP2" width="100%" height="100%" version="1.1" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    svgString,
                    "</svg>"
                )
            );
    }

    /**
     * generates an attribute for the attributes array in the ERC721 metadata standard
     * @param traitType the trait type to reference as the metadata key
     * @param value the token's trait associated with the key
     * @return a JSON dictionary for the single attribute
     */
    function attributeForTypeAndValue(
        string memory traitType,
        string memory value
    ) internal pure returns (string memory) {
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

    /**
     * generates an array composed of all the individual traits and values
     * @param tokenId the ID of the token to compose the metadata for
     * @return a JSON array of all of the attributes for given token ID
     */
    function compileAttributes(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        IPoliceAndThief.ThiefPolice memory s = IPoliceAndThief(policeAndThief)
            .getTokenTraits(tokenId);
        uint8 level = upgrading.levelOf(tokenId);

        string memory traits;
        if (s.isThief) {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        traitTypes[1],
                        traitData[0][s.uniform % traitCountForType[0]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[2],
                        traitData[1][s.hair % traitCountForType[1]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[3],
                        traitData[2][s.facialHair % traitCountForType[2]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[4],
                        traitData[3][s.eyes % traitCountForType[3]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[6],
                        traitData[4][s.accessory % traitCountForType[4]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[5],
                        traitData[5][s.headgear % traitCountForType[5]].name
                    ),
                    ",",
                    attributeForTypeAndValue("Level", toString(uint256(level))),
                    ","
                )
            );
        } else {
            traits = string(
                abi.encodePacked(
                    attributeForTypeAndValue(
                        traitTypes[0],
                        traitData[10][s.uniform % traitCountForType[10]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[2],
                        traitData[11][s.hair % traitCountForType[11]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[3],
                        traitData[12][s.facialHair % traitCountForType[12]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[4],
                        traitData[13][s.eyes % traitCountForType[13]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[6],
                        traitData[14][s.accessory % traitCountForType[14]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[5],
                        traitData[15][s.alphaIndex % traitCountForType[15]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        traitTypes[7],
                        traitData[16][s.neckGear % traitCountForType[16]].name
                    ),
                    ",",
                    attributeForTypeAndValue(
                        "Alpha Score",
                        _alphas[s.alphaIndex]
                    ),
                    ","
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    "[",
                    traits,
                    '{"trait_type":"Generation","value":',
                    tokenId <= IPoliceAndThief(policeAndThief).getPaidTokens()
                        ? '"Gen 0"'
                        : '"Gen 1"',
                    '},{"trait_type":"Type","value":',
                    s.isThief ? '"Thief"' : '"Police"',
                    "}]"
                )
            );
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        IPoliceAndThief.ThiefPolice memory s = IPoliceAndThief(policeAndThief)
            .getTokenTraits(tokenId);

        string memory metadata = string(
            abi.encodePacked(
                '{"name": "',
                s.isThief ? "Thief #" : "Police #",
                toString(tokenId),
                '", "description": "Police & Thief Game is a new generation play-to-earn NFT game on Avalanche that incorporates probability-based derivatives alongside NFTs. Through a vast array of choices and decision-making possibilities, Police & Thief Game promises to instil excitement and curiosity amongst the community as every individual adopts different strategies to do better than one another and to come out on top. The real question is, are you #TeamThief or #TeamPolice? Choose wisely or watch the other get rich!", "image": "data:image/svg+xml;base64,',
                base64(bytes(drawSVG(tokenId))),
                '", "attributes":',
                compileAttributes(tokenId),
                "}"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    base64(bytes(metadata))
                )
            );
    }

    /***BASE 64 - Written by Brech Devos */

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
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

    function moveData(
        uint8 id,
        uint8 startFrom,
        uint8 till,
        bool counts
    ) public onlyOwner {
        for (uint8 i = startFrom; i < till; i++) {
            if (bytes(traitData[id][i].name).length != 0) {
                continue;
            }

            (traitData[id][i].name, traitData[id][i].png) = old.traitData(
                id,
                i
            );
        }

        if (counts) {
            for (uint8 i = 0; i < 20; i++) {
                traitCountForType[i] = old.traitCountForType(i);
            }
        }
    }

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

    function setThiefUpgrading(IThiefUpgrading _upgrading) public onlyOwner {
        upgrading = _upgrading;
    }

    function setOldTraits(ITraits _old) public onlyOwner {
        old = _old;
    }

    function setGame(address _policeAndThief) public onlyOwner {
        policeAndThief = _policeAndThief;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
    function selectTrait(uint16 seed, uint8 traitType) external view returns(uint8);
    function drawSVG(uint256 tokenId) external view returns (string memory);
    function traitData(uint8, uint8) external view returns (string memory, string memory);
    function traitCountForType(uint8) external view returns (uint8);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;


interface IPoliceAndThief {

    // struct to store each token's traits
    struct ThiefPolice {
        bool isThief;
        uint8 uniform;
        uint8 hair;
        uint8 eyes;
        uint8 facialHair;
        uint8 headgear;
        uint8 neckGear;
        uint8 accessory;
        uint8 alphaIndex;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getPaidTokens() external view returns (uint256);
    function getTokenTraits(uint256 tokenId) external view returns (ThiefPolice memory);
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IThiefUpgrading {
    function levelOf(uint256) external view returns(uint8);
}