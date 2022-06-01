//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMirakaiDnaParser {
    function splitDna(uint256 dna) external pure returns (uint256[10] memory);

    function getTraitIndexes(uint256 dna)
        external
        view
        returns (uint256[10] memory);

    function getTraitName(uint256 categoryIndex, uint256 traitIndex)
        external
        view
        returns (string memory);

    function getTraitNames(uint256[10] memory traitIndexes)
        external
        view
        returns (string[10] memory);

    function cc0Traits(uint256 scrollDna) external pure returns (uint256);

    function categories(uint256 index) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IMirakaiScrollsRenderer.sol";
import "./interfaces/IMirakaiDnaParser.sol";

// import {console} from "forge-std/console.sol";

contract MirakaiScrollsRenderer is Ownable, IMirakaiScrollsRenderer {
    address public mirakaDnaParser;

    string private fontUrl;
    string private pixelScroll =
        "000111111111111111110000001222222222222222221000001233333333333333321000000111111111111111110000000433333333333333340000000422222222222222340000000422222222222222340000000122222222222222340000000422222222222222340000000122222222222222340000000122222222222222340000000012222222222222340000000122222222222222340000000122222222222222310000000422222222222222340000000122222222222222310000000422222222222222100000000422222222222222310000000422222222222222310000000422222222222223340000000111111111111111110000001222222222222222221000001233333333333333321000000111111111111111110000";

    struct Cursor {
        uint8 x;
        uint8 y;
        string colorOne;
        string colorTwo;
        string colorThree;
        string colorFour;
    }

    uint256 public constant NUM_TRAITS = 10;

    uint256[][NUM_TRAITS] public WEIGHTS;
    string[][NUM_TRAITS] public TRAITS;
    string[NUM_TRAITS] public categories;
    uint256[NUM_TRAITS] public yIndexes;

    constructor() {
        yIndexes[0] = 7; // 0 + 7
        yIndexes[1] = 9; // 1 + 7 + 1
        yIndexes[2] = 11; // 2 + 7 + 2
        yIndexes[3] = 13; // 3 + 7 + 4
        yIndexes[4] = 7; // 4 + 7 - 4
        yIndexes[5] = 9;
        yIndexes[6] = 11;
        yIndexes[7] = 13;
        yIndexes[8] = 15;
    }

    function setmirakaiDnaParser(address _mirakaDnaParser) external onlyOwner {
        mirakaDnaParser = _mirakaDnaParser;
    }

    function setFontUrl(string calldata _fontUrl) external onlyOwner {
        fontUrl = _fontUrl;
    }

    // TODO: maybe can make return array uint16, also switch this back to internal
    // function splitDna(uint256 dna)
    //     public
    //     view
    //     returns (uint256[NUM_TRAITS] memory traitDnas)
    // {
    //     IMirakaiDnaParser(mirakaDnaParser).splitDna(dna);
    // }

    function formatTraits(uint256[NUM_TRAITS] memory traitIndexes)
        internal
        view
        returns (string memory)
    {
        string memory attributes;
        string[NUM_TRAITS] memory traitNames = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitNames(traitIndexes);

        for (uint256 i = 0; i < traitIndexes.length; i++) {
            attributes = string(
                abi.encodePacked(
                    attributes,
                    "{'trait_type':'",
                    IMirakaiDnaParser(mirakaDnaParser).categories(i),
                    "','value':'",
                    // IMirakaiDnaParser(mirakaDnaParser).getTraitName(
                    //     i,
                    //     traitIndexes[i]
                    // ),
                    traitNames[i],
                    "'}"
                )
            );

            if (i != 8) attributes = string(abi.encodePacked(attributes, ","));
        }

        return string(abi.encodePacked("[", attributes, "]"));
    }

    function tokenURI(uint256 tokenId, uint256 dna)
        external
        view
        returns (
            // uint256 cc0Trait
            string memory
        )
    {
        uint256[NUM_TRAITS] memory traitIndexes = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitIndexes(dna);
        // return formatTraits(traitIndexes);

        //todo: grab cc0 trait

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{'name': 'Scroll",
                                toString(tokenId),
                                "', 'description': 'description x', 'image': 'data:image/svg+xml;base64,",
                                render(tokenId, dna),
                                "', 'attributes':",
                                formatTraits(traitIndexes),
                                "}"
                            )
                        )
                    )
                )
            );
        // return Base64.encode(bytes(formatTraits(traitIndexes))); -- hella inefficient
    }

    // todo: b/c of how we use it, we should replace with a simpler charAt.
    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toString(uint256 value) internal pure returns (string memory) {
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

    function pixelFour(string[24] memory lookup, Cursor memory cursor)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<rect class='c",
                    cursor.colorOne,
                    "' x='",
                    lookup[cursor.x],
                    "' y='",
                    lookup[cursor.y],
                    "' width='1' height='1' />",
                    "<rect class='c",
                    cursor.colorTwo,
                    "' x='",
                    lookup[cursor.x + 1],
                    "' y='",
                    lookup[cursor.y],
                    "' width='1' height='1' />",
                    string(
                        abi.encodePacked(
                            "<rect class='c",
                            cursor.colorThree,
                            "' x='",
                            lookup[cursor.x + 2],
                            "' y='",
                            lookup[cursor.y],
                            "' width='1' height='1' />",
                            "<rect class='c",
                            cursor.colorFour,
                            "' x='",
                            lookup[cursor.x + 3],
                            "' y='",
                            lookup[cursor.y],
                            "' width='1' height='1' />"
                        )
                    )
                )
            );
    }

    function setCursorColors(
        Cursor memory cursor,
        uint16 i,
        uint16 offset
    ) internal view {
        cursor.colorOne = substring(
            pixelScroll,
            4 * i + offset,
            (4 * i) + 1 + offset
        );
        cursor.colorTwo = substring(
            pixelScroll,
            4 * i + 1 + offset,
            (4 * i) + 2 + offset
        );
        cursor.colorThree = substring(
            pixelScroll,
            4 * i + 2 + offset,
            (4 * i) + 3 + offset
        );
        cursor.colorFour = substring(
            pixelScroll,
            4 * i + 3 + offset,
            (4 * i) + 4 + offset
        );
    }

    function drawScroll(string[24] memory lookup)
        internal
        view
        returns (string memory)
    {
        string memory svgScrollString;
        string[6] memory p;

        Cursor memory cursor;
        cursor.y = 0;

        for (uint16 i = 0; i < 144; i += 6) {
            cursor.x = 0;

            // 0-3
            setCursorColors(cursor, i, 0);
            p[0] = pixelFour(lookup, cursor); // 0 - 3
            cursor.x += 4;

            // 4-7
            setCursorColors(cursor, i, 4);
            p[1] = pixelFour(lookup, cursor); // 4 - 7
            cursor.x += 4;

            // 8-11
            setCursorColors(cursor, i, 8);
            p[2] = pixelFour(lookup, cursor); // 8 - 11
            cursor.x += 4;

            // 12-15
            setCursorColors(cursor, i, 12);
            p[3] = pixelFour(lookup, cursor); // 12 - 15
            cursor.x += 4;

            // 16-19
            setCursorColors(cursor, i, 16);
            p[4] = pixelFour(lookup, cursor); // 16 - 19
            cursor.x += 4;

            // 20-23
            setCursorColors(cursor, i, 20);
            p[5] = pixelFour(lookup, cursor); // 20 - 23

            svgScrollString = string(
                abi.encodePacked(
                    svgScrollString,
                    p[0],
                    p[1],
                    p[2],
                    p[3],
                    p[4],
                    p[5]
                )
            );

            cursor.y++;
        }
        return svgScrollString;
    }

    function drawItems(string[24] memory lookup, uint256 dna)
        internal
        view
        returns (string memory, uint256)
    {
        string memory extraTag;
        uint256 numRareTraits;

        uint256[NUM_TRAITS] memory traitIndexes = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitIndexes(dna);

        string[NUM_TRAITS] memory traitNames = IMirakaiDnaParser(
            mirakaDnaParser
        ).getTraitNames(traitIndexes);

        string memory svgItemsScroll;
        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            // todo: see how jason wants to do the mapping of tokenId / tokenData to item names.

            // todo: should read from probability rather than index
            if (traitIndexes[i] < 5) {
                extraTag = "fill='#87E8FC'";
                ++numRareTraits;
            }

            svgItemsScroll = string(
                abi.encodePacked(
                    svgItemsScroll,
                    "<text font-family='Silkscreen' class='t",
                    lookup[i],
                    "' ",
                    extraTag,
                    " x='5.5' y='",
                    // lookup[7 + ((i % 3) * 2)],
                    // lookup[yIndexes[i]],
                    lookup[7 + ((i % 5) * 2)],
                    "'>",
                    traitNames[i],
                    "</text>"
                )
            );
        }
        return (svgItemsScroll, numRareTraits);
    }

    function render(uint256 tokenId, uint256 dna)
        public
        view
        returns (string memory)
    {
        // 0. Init
        string[24] memory lookup = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23"
        ];

        // todo: no color for no cc0

        string
            memory svgString = "<rect height='100%' width='100%' fill='#050A24' /><g class='floating'>";

        // 1. Draw the scroll.
        svgString = string(abi.encodePacked(svgString, drawScroll(lookup)));

        string memory drawnItems;
        uint256 rareItems;

        (drawnItems, rareItems) = drawItems(lookup, dna);

        // 2. Draw the letters.
        // svgString = string(abi.encodePacked(svgString, drawItems(lookup, dna)));
        svgString = string(abi.encodePacked(svgString, drawnItems));
        svgString = string(abi.encodePacked(svgString, "</g>"));

        // 3. Draw the title.
        svgString = string(
            abi.encodePacked(
                svgString,
                "<text x='50%' y='33' dominant-baseline='middle' text-anchor='middle' class='title'>SCROLL #",
                toString(tokenId),
                "</text>"
            )
        );

        string memory extraStyle;

        if (rareItems >= 2) {
            extraStyle = "<style>@keyframes floating{from{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.25px rgba(120, 120, 180, .85));}50%{transform: translate(6.5px,5px); filter: drop-shadow(0px 0px 2.5px rgba(120, 120, 190, 1));}to{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.25px rgba(120, 120, 180,.85));}}</style>";
        }

        if (rareItems >= 3) {
            extraStyle = "<style>@keyframes floating{from{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.75px rgba(135,232,252,0.8));}50%{transform: translate(6.5px,5px); filter: drop-shadow(0px 0px 3.5px rgba(135,232,252,1));}to{transform: translate(6.5px,3.5px); filter: drop-shadow(0px 0px 1.75px rgba(135,232,252,0.8));}}</style>";
        }

        // string
        //     memory fontUrl = "https://mirakai.mypinata.cloud/ipfs/QmPe7GxgMAxprEXRx88pXyeXA9x9bJxiive9U9Emz9VEVy";

        // 4. Close the SVG.
        svgString = string(
            abi.encodePacked(
                "<svg version='1.1' width='550' height='550' viewBox='0 0 36 36' xmlns='http://www.w3.org/2000/svg' shape-rendering='crispEdges'>",
                svgString,
                "<style>@font-face{font-family:Silkscreen;font-style:normal;src:local('Silkscreen'),url('",
                fontUrl,
                "') format('woff')}.title{font-family:Silkscreen;font-size:2px;fill:white}.floating{animation:floating 4s ease-in-out infinite alternate}@keyframes floating{from{transform:translate(6.5px,3.5px);filter:drop-shadow(0px 0px 1.25px rgba(239, 91, 91, .65))}50%{transform:translate(6.5px,5px);filter:drop-shadow(0px 0px 2.5px rgba(239, 91, 91, 1))}to{transform:translate(6.5px,3.5px);filter:drop-shadow(0px 0px 1.25px rgba(239, 91, 91, .65))}}.t0,.t1,.t2,.t3,.t4,.t5,.t6,.t7,.t8,.t9{font-family:Silkscreen;font-size:1.15px;color:#000;animation:textOneAnim 10.5s ease-in-out infinite forwards;opacity:0;animation-delay:.25s}.t5,.t6,.t7,.t8,.t9{animation-name:textTwoAnim}.t1{animation-delay:1.5s}.t2{animation-delay:2.5s}.t3{animation-delay:3.5s}.t4{animation-delay:4.5s}.t5{animation-delay:5.5s}.t6{animation-delay:6.5s}.t7{animation-delay:7.5s}.t8{animation-delay:8.5s}.t9{animation-delay:9.5s}@keyframes textOneAnim{from{opacity:0}10%{opacity:1}42.5%{opacity:1}50%{opacity:0}to{opacity:0}}@keyframes textTwoAnim{from{opacity:0}22.5%{opacity:1}30%{opacity:1}40%{opacity:1}50%{opacity:0}to{opacity:0}}.c0{fill:transparent}.c1{fill:#8b3615}.c2{fill:#d49443}.c3{fill:#c57032}.c4{fill:#76290c}</style>",
                extraStyle,
                "</svg>"
            )
        );

        return Base64.encode(bytes(svgString));
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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
pragma solidity ^0.8.0;

interface IMirakaiScrollsRenderer {
    // function splitDna(uint256 dna) external view returns (uint256[9] memory);

    function render(uint256 tokenId, uint256 dna)
        external
        view
        returns (string memory);

    function tokenURI(uint256 tokenId, uint256 dna)
        external
        view
        returns (string memory);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/ds-test/src/test.sol";
import {console} from "lib/forge-std/src/console.sol";
import {stdError} from "lib/forge-std/src/stdlib.sol";
import {MirakaiScrolls} from "../MirakaiScrolls.sol";
import {MirakaiScrollsRenderer} from "../MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../MirakaiDnaParser.sol";
import {OrbsToken} from "../OrbsToken/OrbsToken.sol";
import {TestVm} from "./TestVm.sol";

contract MirakaiScrollsTest is DSTest, TestVm {
    MirakaiScrolls private mirakaiScrolls;
    MirakaiScrollsRenderer private mirakaiScrollsRenderer;
    MirakaiDnaParser private mirakaiDnaParser;
    OrbsToken private orbs;

    // public/private key for signatures
    address signer = 0x4A455783fC9022800FC6C03A73399d5bEB4065e8;
    uint256 signerPk =
        0x3532c806834d0a952c89f8954e2f3c417e3d6a5ad0d985c4a87a545da0ca722a;

    address user1 = 0x2Af416FDA8d86fAabDe21758aEea6c1BA5Da1f38;
    address user2 = 0x4b3d0D71A31F1f5e28B79bc0222bFEef4449B479;
    address user3 = 0xdb3f55B9559566c57987e523Be1aFb09Dd5df59c;

    // weights[0] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[1] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[2] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[3] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[4] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[5] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[6] = [1000, 1000, 1000, 1000, 1000, 5000];
    // weights[7] = [1, 1000, 1000, 1000, 1000, 5999]; // weapon
    // weights[8] = [1, 1000, 2000, 2000, 2000, 2999]; // markings

    // traits[0] = [
    //     "arcadia",
    //     "babalys",
    //     "titties",
    //     "bera",
    //     "zena",
    //     "draconia"
    // ];
    // traits[1] = [
    //     "balck",
    //     "less black",
    //     "light skin",
    //     "white",
    //     "pale",
    //     "goth"
    // ];
    // traits[2] = [
    //     "big ass head",
    //     "5 head",
    //     "forbidden helmet",
    //     "beanie",
    //     "mask",
    //     "bucket hat"
    // ];
    // traits[3] = [
    //     "blue eyes",
    //     "sunglasses",
    //     "gold eyes",
    //     "brown eyes",
    //     "laser",
    //     "angry eyes"
    // ];
    // traits[4] = [
    //     "toothbick",
    //     "blow job",
    //     "smiling",
    //     "grinning",
    //     "surprised",
    //     "teeeeth"
    // ];
    // traits[5] = [
    //     "elemental armour",
    //     "hoodie",
    //     "robe",
    //     "divine shirt",
    //     "sweater",
    //     "jersey"
    // ];
    // traits[6] = [
    //     "jeans",
    //     "armor pants",
    //     "shorts",
    //     "underwear",
    //     "swimsuit",
    //     "boxers"
    // ];
    // traits[7] = [
    //     "divine bow",
    //     "fire sword",
    //     "spear",
    //     "icicle",
    //     "doodoo sword",
    //     "weaponless"
    // ];
    // traits[8] = [
    //     "bandaid",
    //     "priple scar",
    //     "sunburn",
    //     "gold triange",
    //     "freckles",
    //     "unmarked"
    // ];
    // categories = [
    //     "clan",
    //     "genus",
    //     "head",
    //     "eyes",
    //     "mouth",
    //     "upper",
    //     "lower",
    //     "weapon",
    //     "markings"
    // ];

    function setUp() public {
        mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiDnaParser = new MirakaiDnaParser();
        mirakaiScrolls = new MirakaiScrolls();
        orbs = new OrbsToken("mock", "mock", 18, 10);

        mirakaiScrolls.initialize(
            address(mirakaiScrollsRenderer),
            address(orbs),
            signer,
            0, // basePrice
            0, // cc0TraitsProbability
            0, // rerollTraitCost
            0 // seed
        );
        mirakaiScrollsRenderer.setmirakaiDnaParser(address(mirakaiDnaParser));
        orbs.setmirakaiScrolls(address(mirakaiScrolls));
        setDnaParserTraitsAndWeights();
    }

    // should mint tokens
    function testPublicMint() public {
        mirakaiScrolls.flipMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        assertEq(mirakaiScrolls.balanceOf(user1), 5);
        assertEq(mirakaiScrolls.totalSupply(), 5);

        console.log(mirakaiScrolls.tokenURI(0));
        console.log(mirakaiDnaParser.weights(0, 0));
        console.log(mirakaiDnaParser.weights(0, 0));
        console.log(mirakaiDnaParser.weights(0, 4));
    }

    function testTeamMint() public {
        mirakaiScrolls.teamMint(25);
        mirakaiScrolls.teamMint(25);

        assertEq(mirakaiScrolls.balanceOf(address(this)), 50);
        assertEq(mirakaiScrolls.totalSupply(), 50);

        vm.expectRevert(MirakaiScrolls.TeamMintOver.selector);
        mirakaiScrolls.teamMint(1);
    }

    // should revert if mint is not active
    function testPublicMintRevert() public {
        vm.startPrank(user1, user1);
        vm.expectRevert(MirakaiScrolls.MintNotActive.selector);
        mirakaiScrolls.publicMint(5);
    }

    // should mint tokens for valid sigs
    function testAllowListMint() public {
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.allowListMint(signMessage(user1, 1, 0));

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);
    }

    // should revert for invalid sigs
    function testAllowListMintRevertInvalidSig() public {
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user2, 1, 0);
        vm.expectRevert(MirakaiScrolls.InvalidSignature.selector);
        mirakaiScrolls.allowListMint(signature);
    }

    // wallet cannot mint multiple times
    function testAllowListMultipleMintRevert() public {
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 0);
        mirakaiScrolls.allowListMint(signature);

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        vm.expectRevert(MirakaiScrolls.WalletAlreadyMinted.selector);
        mirakaiScrolls.allowListMint(signature);
    }

    // should revert if mint is not active
    function testAllowListMintRevertNotActive() public {
        // flip incorrect flag
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 0);
        vm.expectRevert(MirakaiScrolls.MintNotActive.selector);
        mirakaiScrolls.allowListMint(signature);
    }

    // should mint token with cc0 trait
    function testCC0Mint() public {
        mirakaiScrolls.flipCC0Mint();

        // set cc0TraitProbability to 100%
        mirakaiScrolls.setCc0TraitsProbability(100);

        vm.startPrank(user1, user1);

        // mint token with cc0Trait 1
        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        // check that cc0Index was properly set for token
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        // logic below is to make sure we can reroll a trait, but the cc0Trait remain unaffected
        uint256[10] memory oldDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(0)
        );

        // reroll trait 3 for token 0
        mirakaiScrolls.rerollTrait(0, 3);

        uint256[10] memory newDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(0)
        );

        assertEq(oldDnaIndexes[0], newDnaIndexes[0]);
        assertEq(oldDnaIndexes[1], newDnaIndexes[1]);
        assertEq(oldDnaIndexes[2], newDnaIndexes[2]);
        // the correct trait got rerolled
        require(oldDnaIndexes[3] != newDnaIndexes[3]);
        assertEq(oldDnaIndexes[4], newDnaIndexes[4]);
        assertEq(oldDnaIndexes[5], newDnaIndexes[5]);
        assertEq(oldDnaIndexes[6], newDnaIndexes[6]);
        assertEq(oldDnaIndexes[7], newDnaIndexes[7]);
        assertEq(oldDnaIndexes[8], newDnaIndexes[8]);

        // ensure cc0 trait stayed the same
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
    }

    // should revert for valid sigs
    function testCc0MintRevertInvalidSig() public {
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user2, 1, 0);
        vm.expectRevert(MirakaiScrolls.InvalidSignature.selector);
        mirakaiScrolls.cc0Mint(1, signature);
    }

    // wallet cannot mint multiple times
    function testCc0ListMultipleMintRevert() public {
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 1);
        mirakaiScrolls.cc0Mint(1, signature);

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        vm.expectRevert(MirakaiScrolls.WalletAlreadyMinted.selector);
        mirakaiScrolls.cc0Mint(1, signature);
    }

    // should revert if mint is not active
    function testCc0MintRevertNotActive() public {
        // flip incorrect flag
        mirakaiScrolls.flipAllowListMint();

        vm.startPrank(user1, user1);
        bytes memory signature = signMessage(user1, 1, 0);
        vm.expectRevert(MirakaiScrolls.MintNotActive.selector);
        mirakaiScrolls.cc0Mint(1, signature);
    }

    // set base price for cc0 mint
    function testBasePrice() public {
        vm.deal(user1, 10 ether);

        mirakaiScrolls.setBasePrice(0.05 ether);
        mirakaiScrolls.flipCC0Mint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.cc0Mint{value: 0.05 ether}(
            1,
            (signMessage(user1, 1, 1))
        );

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);
        assertEq(user1.balance, 9.95 ether);

        vm.stopPrank();

        // revert if not enough ether sent
        vm.deal(user2, 10 ether);
        vm.startPrank(user2, user2);
        bytes memory signature = (signMessage(user2, 1, 1));
        vm.expectRevert(MirakaiScrolls.IncorrectEtherValue.selector);
        mirakaiScrolls.cc0Mint{value: 0.03 ether}(1, signature);
    }

    // set mint price for AL and public mint
    function testMintPrice() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        mirakaiScrolls.setMintPrice(0.1 ether);
        mirakaiScrolls.flipAllowListMint();
        mirakaiScrolls.flipMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.allowListMint{value: 0.1 ether}(
            (signMessage(user1, 1, 0))
        );

        mirakaiScrolls.publicMint{value: 0.5 ether}(5);

        assertEq(mirakaiScrolls.balanceOf(user1), 6);
        assertEq(mirakaiScrolls.totalSupply(), 6);

        vm.stopPrank();

        // revert if not enough ether sent
        vm.startPrank(user2, user2);
        bytes memory signature = (signMessage(user2, 1, 0));
        vm.expectRevert(MirakaiScrolls.IncorrectEtherValue.selector);
        mirakaiScrolls.allowListMint{value: 0.03 ether}(signature);

        vm.expectRevert(MirakaiScrolls.IncorrectEtherValue.selector);
        mirakaiScrolls.publicMint{value: 0.03 ether}(5);
    }

    // should reroll trait 2
    function testRerollTrait() public {
        mirakaiScrolls.flipMint();
        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        uint256 tokenid = 0;
        uint256 traitBitshift = 2;

        uint256[10] memory oldDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        // warp timestamp since its used as value in the pseudo-rand number
        vm.warp(3);

        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);

        uint256[10] memory newDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        assertEq(oldDnaIndexes[0], newDnaIndexes[0]);
        assertEq(oldDnaIndexes[1], newDnaIndexes[1]);
        // require correc trait rerolled
        require(oldDnaIndexes[2] != newDnaIndexes[2]);
        assertEq(oldDnaIndexes[3], newDnaIndexes[3]);
        assertEq(oldDnaIndexes[4], newDnaIndexes[4]);
        assertEq(oldDnaIndexes[5], newDnaIndexes[5]);
        assertEq(oldDnaIndexes[6], newDnaIndexes[6]);
        assertEq(oldDnaIndexes[7], newDnaIndexes[7]);
        assertEq(oldDnaIndexes[8], newDnaIndexes[8]);
    }

    // should burn $ORBS for re-roll
    function testRerollTraitCost() public {
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setRerollCost(10e18); // 10 $ORBS cost per re-roll
        orbs.mint(user1, 20e18); // mint 20 $ORBS

        assertEq(orbs.balanceOf(user1), 20e18);

        vm.startPrank(user1, user1);

        // approve $ORBS spending
        orbs.approve(address(mirakaiScrolls), type(uint256).max);

        mirakaiScrolls.publicMint(5);

        uint256 tokenid = 0;
        uint256 traitBitshift = 1;

        uint256[10] memory oldDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        // warp timestamp since its used as value in the pseudo-rand number
        vm.warp(3);

        // should burn 10 $ORBS
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
        assertEq(orbs.balanceOf(user1), 10e18);

        // new trait to roll
        traitBitshift = 8;

        // warp to diff timestamp
        vm.warp(10);

        // should burn 10 $ORBS
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
        assertEq(orbs.balanceOf(user1), 0);

        uint256[10] memory newDnaIndexes = mirakaiDnaParser.getTraitIndexes(
            mirakaiScrolls.dna(tokenid)
        );

        assertEq(oldDnaIndexes[0], newDnaIndexes[0]);
        require(oldDnaIndexes[1] != newDnaIndexes[1]);
        assertEq(oldDnaIndexes[2], newDnaIndexes[2]);
        assertEq(oldDnaIndexes[3], newDnaIndexes[3]);
        assertEq(oldDnaIndexes[4], newDnaIndexes[4]);
        assertEq(oldDnaIndexes[5], newDnaIndexes[5]);
        assertEq(oldDnaIndexes[6], newDnaIndexes[6]);
        assertEq(oldDnaIndexes[7], newDnaIndexes[7]);
        require(oldDnaIndexes[8] != newDnaIndexes[8]);

        // should revert since no more $ORBS
        vm.expectRevert(stdError.arithmeticError);
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
    }

    // should revert, cant reroll trait 0
    function testRerollTraitRevert() public {
        mirakaiScrolls.flipMint();

        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        uint256 tokenid = 0;
        uint256 traitBitshift = 0; //clan index

        vm.expectRevert(MirakaiScrolls.ClanIsUnrollableTrait.selector);
        mirakaiScrolls.rerollTrait(tokenid, traitBitshift);
    }

    // test the $ORBS are dripping properly to wallets
    function testOrbsDripping() public {
        mirakaiScrolls.flipMint();

        // need to start from block num > 0
        vm.roll(1);

        vm.startPrank(user1, user1);
        mirakaiScrolls.publicMint(5);

        // roll forward 4 blocks
        vm.roll(5);

        // $ORBS drip 10 per scroll per block, 4 blocks have passed
        assertEq(orbs.balanceOf(user1), 10 * 5 * 4);
        assertEq(orbs.totalSupply(), 10 * 5 * 4);

        // transfer scroll to user2
        mirakaiScrolls.transferFrom(user1, user2, 0);

        // balances should not change since no blocks have progressed
        assertEq(orbs.balanceOf(user1), 10 * 5 * 4);
        assertEq(orbs.balanceOf(user2), 0);
        assertEq(orbs.totalSupply(), 10 * 5 * 4);

        // roll forward 5 blocks
        vm.roll(10);

        // user1 should have accumuated original tokens + 10 $ORBS * 4 scrolls * 5 blocks
        // user2 accumulated 10 $ORBS * 1 scroll * 5 blocks
        assertEq(orbs.balanceOf(user1), (10 * 5 * 4) + (10 * 4 * 5));
        assertEq(orbs.balanceOf(user2), 10 * 1 * 5);
        assertEq(
            orbs.totalSupply(),
            ((10 * 5 * 4) + (10 * 4 * 5)) + (10 * 1 * 5)
        );
    }

    function testBurn() public {
        // need to start from block num > 0
        vm.roll(1);

        mirakaiScrolls.flipCC0Mint();

        // set cc0TraitProbability to 100%
        mirakaiScrolls.setCc0TraitsProbability(100);

        vm.startPrank(user1, user1);
        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));

        assertEq(mirakaiScrolls.balanceOf(user1), 1);
        // check that cc0Index was properly set for token
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 1);

        mirakaiScrolls.burn(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 0);
        // check that cc0 index is zeroed out
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 0);
        // check dna is zeroed out
        assertEq(mirakaiScrolls.dna(0), 0);
        assertEq(mirakaiScrolls.totalSupply(), 0);
    }

    // --- utils ---
    function signMessage(
        address minter,
        uint256 quantity,
        uint256 cc0Index
    ) internal returns (bytes memory) {
        bytes32 messageHash = mirakaiScrolls.getMessageHash(
            minter,
            quantity,
            cc0Index
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPk,
            ethSignedMessageHash
        );
        return abi.encodePacked(r, s, v);
    }

    function setDnaParserTraitsAndWeights() internal {
        MirakaiDnaParser.TraitWeights[]
            memory tw = new MirakaiDnaParser.TraitWeights[](10);

        uint256[] memory weights = new uint256[](6);
        weights[0] = 1000;
        weights[1] = 1000;
        weights[2] = 1000;
        weights[3] = 1000;
        weights[4] = 1000;
        weights[5] = 5000;

        string[] memory clans = new string[](6);
        clans[0] = "clan 1";
        clans[1] = "clan 2";
        clans[2] = "clan 3";
        clans[3] = "clan 4";
        clans[4] = "clan 5";
        clans[5] = "clan 6";

        string[] memory genus = new string[](6);
        genus[0] = "genus 1";
        genus[1] = "genus 2";
        genus[2] = "genus 3";
        genus[3] = "genus 4";
        genus[4] = "genus 5";
        genus[5] = "genus 6";

        string[] memory heads = new string[](6);
        heads[0] = "head 1";
        heads[1] = "head 2";
        heads[2] = "head 3";
        heads[3] = "head 4";
        heads[4] = "head 5";
        heads[5] = "head 6";

        string[] memory eyes = new string[](6);
        eyes[0] = "eye 1";
        eyes[1] = "eye 2";
        eyes[2] = "eye 3";
        eyes[3] = "eye 4";
        eyes[4] = "eye 5";
        eyes[5] = "eye 6";

        string[] memory mouths = new string[](6);
        mouths[0] = "mouth 1";
        mouths[1] = "mouth 2";
        mouths[2] = "mouth 3";
        mouths[3] = "mouth 4";
        mouths[4] = "mouth 5";
        mouths[5] = "mouth 6";

        string[] memory tops = new string[](6);
        tops[0] = "top 1";
        tops[1] = "top 2";
        tops[2] = "top 3";
        tops[3] = "top 4";
        tops[4] = "top 5";
        tops[5] = "top 6";

        string[] memory bottoms = new string[](6);
        bottoms[0] = "bottom 1";
        bottoms[1] = "bottom 2";
        bottoms[2] = "bottom 3";
        bottoms[3] = "bottom 4";
        bottoms[4] = "bottom 5";
        bottoms[5] = "bottom 6";

        string[] memory weapons = new string[](6);
        weapons[0] = "weapons 1";
        weapons[1] = "weapons 2";
        weapons[2] = "weapons 3";
        weapons[3] = "weapons 4";
        weapons[4] = "weapons 5";
        weapons[5] = "weapons 6";

        string[] memory markings = new string[](6);
        markings[0] = "markings 1";
        markings[1] = "markings 2";
        markings[2] = "markings 3";
        markings[3] = "markings 4";
        markings[4] = "markings 5";
        markings[5] = "markings 6";

        string[] memory cc0s = new string[](6);
        cc0s[0] = "cc0 1";
        cc0s[1] = "cc0 2";
        cc0s[2] = "cc0 3";
        cc0s[3] = "cc0 4";
        cc0s[4] = "cc0 5";
        cc0s[5] = "No cc0";

        tw[0] = MirakaiDnaParser.TraitWeights(0, clans, weights);
        tw[1] = MirakaiDnaParser.TraitWeights(1, genus, weights);
        tw[2] = MirakaiDnaParser.TraitWeights(2, heads, weights);
        tw[3] = MirakaiDnaParser.TraitWeights(3, eyes, weights);
        tw[4] = MirakaiDnaParser.TraitWeights(4, mouths, weights);
        tw[5] = MirakaiDnaParser.TraitWeights(5, tops, weights);
        tw[6] = MirakaiDnaParser.TraitWeights(6, bottoms, weights);
        tw[7] = MirakaiDnaParser.TraitWeights(7, weapons, weights);
        tw[8] = MirakaiDnaParser.TraitWeights(8, markings, weights);
        tw[9] = MirakaiDnaParser.TraitWeights(9, cc0s, weights);

        mirakaiDnaParser.setTraitsAndWeights(tw);
    }
}

// uint256 private constant CLAN_BITSHIFT_MULTIPLE = 0;
// uint256 private constant GENUS_BITSHIFT_MULTIPLE = 1;
// uint256 private constant HEAD_BITSHIFT_MULTIPLE = 2;
// uint256 private constant EYES_BITSHIFT_MULTIPLE = 3;
// uint256 private constant MOUTH_BITSHIFT_MULTIPLE = 4;
// uint256 private constant UPPER_BITSHIFT_MULTIPLE = 5;
// uint256 private constant LOWER_BITSHIFT_MULTIPLE = 6;
// uint256 private constant WEAPON_BITSHIFT_MULTIPLE = 7;
// uint256 private constant MARKING_BITSHIFT_MULTIPLE = 8;
// uint256 private constant PET_BITSHIFT_MULTIPLE = 9;

// SPDX-License-Identifier: GPL-3.0-or-later

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSTest {
    event log                    (string);
    event logs                   (bytes);

    event log_address            (address);
    event log_bytes32            (bytes32);
    event log_int                (int);
    event log_uint               (uint);
    event log_bytes              (bytes);
    event log_string             (string);

    event log_named_address      (string key, address val);
    event log_named_bytes32      (string key, bytes32 val);
    event log_named_decimal_int  (string key, int val, uint decimals);
    event log_named_decimal_uint (string key, uint val, uint decimals);
    event log_named_int          (string key, int val);
    event log_named_uint         (string key, uint val);
    event log_named_bytes        (string key, bytes val);
    event log_named_string       (string key, string val);

    bool public IS_TEST = true;
    bool public failed;

    address constant HEVM_ADDRESS =
        address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    modifier mayRevert() { _; }
    modifier testopts(string memory) { _; }

    function fail() internal {
        failed = true;
    }

    modifier logs_gas() {
        uint startGas = gasleft();
        _;
        uint endGas = gasleft();
        emit log_named_uint("gas", startGas - endGas);
    }

    function assertTrue(bool condition) internal {
        if (!condition) {
            emit log("Error: Assertion Failed");
            fail();
        }
    }

    function assertTrue(bool condition, string memory err) internal {
        if (!condition) {
            emit log_named_string("Error", err);
            assertTrue(condition);
        }
    }

    function assertEq(address a, address b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [address]");
            emit log_named_address("  Expected", b);
            emit log_named_address("    Actual", a);
            fail();
        }
    }
    function assertEq(address a, address b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }

    function assertEq(bytes32 a, bytes32 b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [bytes32]");
            emit log_named_bytes32("  Expected", b);
            emit log_named_bytes32("    Actual", a);
            fail();
        }
    }
    function assertEq(bytes32 a, bytes32 b, string memory err) internal {
        if (a != b) {
            emit log_named_string ("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq32(bytes32 a, bytes32 b) internal {
        assertEq(a, b);
    }
    function assertEq32(bytes32 a, bytes32 b, string memory err) internal {
        assertEq(a, b, err);
    }

    function assertEq(int a, int b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [int]");
            emit log_named_int("  Expected", b);
            emit log_named_int("    Actual", a);
            fail();
        }
    }
    function assertEq(int a, int b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEq(uint a, uint b) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [uint]");
            emit log_named_uint("  Expected", b);
            emit log_named_uint("    Actual", a);
            fail();
        }
    }
    function assertEq(uint a, uint b, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }
    function assertEqDecimal(int a, int b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal int]");
            emit log_named_decimal_int("  Expected", b, decimals);
            emit log_named_decimal_int("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals) internal {
        if (a != b) {
            emit log("Error: a == b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Expected", b, decimals);
            emit log_named_decimal_uint("    Actual", a, decimals);
            fail();
        }
    }
    function assertEqDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a != b) {
            emit log_named_string("Error", err);
            assertEqDecimal(a, b, decimals);
        }
    }

    function assertGt(uint a, uint b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGt(uint a, uint b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGt(int a, int b) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGt(int a, int b, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGt(a, b);
        }
    }
    function assertGtDecimal(int a, int b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals) internal {
        if (a <= b) {
            emit log("Error: a > b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a <= b) {
            emit log_named_string("Error", err);
            assertGtDecimal(a, b, decimals);
        }
    }

    function assertGe(uint a, uint b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertGe(uint a, uint b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGe(int a, int b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertGe(int a, int b, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGe(a, b);
        }
    }
    function assertGeDecimal(int a, int b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertGeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a < b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertLt(uint a, uint b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLt(uint a, uint b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLt(int a, int b) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLt(int a, int b, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLt(a, b);
        }
    }
    function assertLtDecimal(int a, int b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals) internal {
        if (a >= b) {
            emit log("Error: a < b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLtDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a >= b) {
            emit log_named_string("Error", err);
            assertLtDecimal(a, b, decimals);
        }
    }

    function assertLe(uint a, uint b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            fail();
        }
    }
    function assertLe(uint a, uint b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLe(int a, int b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            fail();
        }
    }
    function assertLe(int a, int b, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLe(a, b);
        }
    }
    function assertLeDecimal(int a, int b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal int]");
            emit log_named_decimal_int("  Value a", a, decimals);
            emit log_named_decimal_int("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(int a, int b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertLeDecimal(a, b, decimals);
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [decimal uint]");
            emit log_named_decimal_uint("  Value a", a, decimals);
            emit log_named_decimal_uint("  Value b", b, decimals);
            fail();
        }
    }
    function assertLeDecimal(uint a, uint b, uint decimals, string memory err) internal {
        if (a > b) {
            emit log_named_string("Error", err);
            assertGeDecimal(a, b, decimals);
        }
    }

    function assertEq(string memory a, string memory b) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log("Error: a == b not satisfied [string]");
            emit log_named_string("  Value a", a);
            emit log_named_string("  Value b", b);
            fail();
        }
    }
    function assertEq(string memory a, string memory b, string memory err) internal {
        if (keccak256(abi.encodePacked(a)) != keccak256(abi.encodePacked(b))) {
            emit log_named_string("Error", err);
            assertEq(a, b);
        }
    }

    function checkEq0(bytes memory a, bytes memory b) internal pure returns (bool ok) {
        ok = true;
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    ok = false;
                }
            }
        } else {
            ok = false;
        }
    }
    function assertEq0(bytes memory a, bytes memory b) internal {
        if (!checkEq0(a, b)) {
            emit log("Error: a == b not satisfied [bytes]");
            emit log_named_bytes("  Expected", a);
            emit log_named_bytes("    Actual", b);
            fail();
        }
    }
    function assertEq0(bytes memory a, bytes memory b, string memory err) internal {
        if (!checkEq0(a, b)) {
            emit log_named_string("Error", err);
            assertEq0(a, b);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int)", p0));
    }

    function logUint(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
    }

    function log(uint p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
    }

    function log(uint p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
    }

    function log(uint p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
    }

    function log(string memory p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
    }

    function log(uint p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
    }

    function log(uint p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
    }

    function log(uint p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
    }

    function log(uint p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
    }

    function log(uint p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
    }

    function log(uint p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
    }

    function log(uint p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
    }

    function log(uint p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
    }

    function log(uint p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
    }

    function log(uint p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
    }

    function log(uint p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
    }

    function log(uint p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
    }

    function log(bool p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
    }

    function log(bool p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
    }

    function log(bool p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
    }

    function log(address p0, uint p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
    }

    function log(address p0, uint p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
    }

    function log(address p0, uint p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import "./Vm.sol";

// Wrappers around Cheatcodes to avoid footguns
abstract contract stdCheats {
    using stdStorage for StdStorage;

    // we use custom names that are unlikely to cause collisions so this contract
    // can be inherited easily
    Vm private constant vm_std_cheats = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));
    StdStorage private std_store_std_cheats;

    // Skip forward or rewind time by the specified number of seconds
    function skip(uint256 time) public {
        vm_std_cheats.warp(block.timestamp + time);
    }

    function rewind(uint256 time) public {
        vm_std_cheats.warp(block.timestamp - time);
    }

    // Setup a prank from an address that has some ether
    function hoax(address who) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.prank(who);
    }

    function hoax(address who, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.prank(who);
    }

    function hoax(address who, address origin) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.prank(who, origin);
    }

    function hoax(address who, address origin, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.prank(who, origin);
    }

    // Start perpetual prank from an address that has some ether
    function startHoax(address who) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.startPrank(who);
    }

    function startHoax(address who, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.startPrank(who);
    }

    // Start perpetual prank from an address that has some ether
    // tx.origin is set to the origin parameter
    function startHoax(address who, address origin) public {
        vm_std_cheats.deal(who, 1 << 128);
        vm_std_cheats.startPrank(who, origin);
    }

    function startHoax(address who, address origin, uint256 give) public {
        vm_std_cheats.deal(who, give);
        vm_std_cheats.startPrank(who, origin);
    }

    // Allows you to set the balance of an account for a majority of tokens
    // Be careful not to break something!
    function tip(address token, address to, uint256 give) public {
        std_store_std_cheats
            .target(token)
            .sig(0x70a08231)
            .with_key(to)
            .checked_write(give);
    }

    // Deploys a contract by fetching the contract bytecode from
    // the artifacts directory
    // e.g deployCode(code, abi.encode(arg1,arg2,arg3))
    function deployCode(string memory what, bytes memory args)
        public
        returns (address addr)
    {
        bytes memory bytecode = abi.encodePacked(vm_std_cheats.getCode(what), args);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }

    function deployCode(string memory what)
        public
        returns (address addr)
    {
        bytes memory bytecode = vm_std_cheats.getCode(what);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
    }
}


library stdError {
    bytes public constant assertionError = abi.encodeWithSignature("Panic(uint256)", 0x01);
    bytes public constant arithmeticError = abi.encodeWithSignature("Panic(uint256)", 0x11);
    bytes public constant divisionError = abi.encodeWithSignature("Panic(uint256)", 0x12);
    bytes public constant enumConversionError = abi.encodeWithSignature("Panic(uint256)", 0x21);
    bytes public constant encodeStorageError = abi.encodeWithSignature("Panic(uint256)", 0x22);
    bytes public constant popError = abi.encodeWithSignature("Panic(uint256)", 0x31);
    bytes public constant indexOOBError = abi.encodeWithSignature("Panic(uint256)", 0x32);
    bytes public constant memOverflowError = abi.encodeWithSignature("Panic(uint256)", 0x41);
    bytes public constant zeroVarError = abi.encodeWithSignature("Panic(uint256)", 0x51);
    bytes public constant lowLevelError = bytes(""); // `0x`
}

struct StdStorage {
    mapping (address => mapping(bytes4 => mapping(bytes32 => uint256))) slots;
    mapping (address => mapping(bytes4 =>  mapping(bytes32 => bool))) finds;
    
    bytes32[] _keys;
    bytes4 _sig;
    uint256 _depth;
    address _target;
    bytes32 _set;
}


library stdStorage {
    event SlotFound(address who, bytes4 fsig, bytes32 keysHash, uint slot);
    event WARNING_UninitedSlot(address who, uint slot);
    
    Vm private constant vm_std_store = Vm(address(uint160(uint256(keccak256('hevm cheat code')))));

    function sigs(
        string memory sigStr
    )
        internal
        pure
        returns (bytes4)
    {
        return bytes4(keccak256(bytes(sigStr)));
    }

    /// @notice find an arbitrary storage slot given a function sig, input data, address of the contract and a value to check against
    // slot complexity:
    //  if flat, will be bytes32(uint256(uint));
    //  if map, will be keccak256(abi.encode(key, uint(slot)));
    //  if deep map, will be keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))));
    //  if map struct, will be bytes32(uint256(keccak256(abi.encode(key1, keccak256(abi.encode(key0, uint(slot)))))) + structFieldDepth);
    function find(
        StdStorage storage self
    ) 
        internal 
        returns (uint256)
    {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        // calldata to test against
        if (self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
        }
        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        vm_std_store.record();
        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }
        
        (bytes32[] memory reads, ) = vm_std_store.accesses(address(who));
        if (reads.length == 1) {
            bytes32 curr = vm_std_store.load(who, reads[0]);
            if (curr == bytes32(0)) {
                emit WARNING_UninitedSlot(who, uint256(reads[0]));
            }
            if (fdat != curr) {
                require(false, "Packed slot. This would cause dangerous overwriting and currently isnt supported");
            }
            emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[0]));
            self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[0]);
            self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
        } else if (reads.length > 1) {
            for (uint256 i = 0; i < reads.length; i++) {
                bytes32 prev = vm_std_store.load(who, reads[i]);
                if (prev == bytes32(0)) {
                    emit WARNING_UninitedSlot(who, uint256(reads[i]));
                }
                // store
                vm_std_store.store(who, reads[i], bytes32(hex"1337"));
                bool success;
                bytes memory rdat;
                {
                    (success, rdat) = who.staticcall(cald);
                    fdat = bytesToBytes32(rdat, 32*field_depth);
                }
                
                if (success && fdat == bytes32(hex"1337")) {
                    // we found which of the slots is the actual one
                    emit SlotFound(who, fsig, keccak256(abi.encodePacked(ins, field_depth)), uint256(reads[i]));
                    self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = uint256(reads[i]);
                    self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))] = true;
                    vm_std_store.store(who, reads[i], prev);
                    break;
                }
                vm_std_store.store(who, reads[i], prev);
            }
        } else {
            require(false, "No storage use detected for target");
        }

        require(self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))], "NotFound");

        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth; 

        return self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))];
    }

    function target(StdStorage storage self, address _target) internal returns (StdStorage storage) {
        self._target = _target;
        return self;
    }

    function sig(StdStorage storage self, bytes4 _sig) internal returns (StdStorage storage) {
        self._sig = _sig;
        return self;
    }

    function sig(StdStorage storage self, string memory _sig) internal returns (StdStorage storage) {
        self._sig = sigs(_sig);
        return self;
    }

    function with_key(StdStorage storage self, address who) internal returns (StdStorage storage) {
        self._keys.push(bytes32(uint256(uint160(who))));
        return self;
    }

    function with_key(StdStorage storage self, uint256 amt) internal returns (StdStorage storage) {
        self._keys.push(bytes32(amt));
        return self;
    }
    function with_key(StdStorage storage self, bytes32 key) internal returns (StdStorage storage) {
        self._keys.push(key);
        return self;
    }

    function depth(StdStorage storage self, uint256 _depth) internal returns (StdStorage storage) {
        self._depth = _depth;
        return self;
    }

    function checked_write(StdStorage storage self, address who) internal {
        checked_write(self, bytes32(uint256(uint160(who))));
    }

    function checked_write(StdStorage storage self, uint256 amt) internal {
        checked_write(self, bytes32(amt));
    }

    function checked_write(StdStorage storage self, bool write) internal {
        bytes32 t;
        assembly {
            t := write
        }
        checked_write(self, t);
    }

    function checked_write(
        StdStorage storage self,
        bytes32 set
    ) internal {
        address who = self._target;
        bytes4 fsig = self._sig;
        uint256 field_depth = self._depth;
        bytes32[] memory ins = self._keys;

        bytes memory cald = abi.encodePacked(fsig, flatten(ins));
        if (!self.finds[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]) {
            find(self);
        }
        bytes32 slot = bytes32(self.slots[who][fsig][keccak256(abi.encodePacked(ins, field_depth))]);

        bytes32 fdat;
        {
            (, bytes memory rdat) = who.staticcall(cald);
            fdat = bytesToBytes32(rdat, 32*field_depth);
        }
        bytes32 curr = vm_std_store.load(who, slot);

        if (fdat != curr) {
            require(false, "Packed slot. This would cause dangerous overwriting and currently isnt supported");
        }
        vm_std_store.store(who, slot, set);
        delete self._target;
        delete self._sig;
        delete self._keys;
        delete self._depth; 
    }

    function bytesToBytes32(bytes memory b, uint offset) public pure returns (bytes32) {
        bytes32 out;

        uint256 max = b.length > 32 ? 32 : b.length;
        for (uint i = 0; i < max; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function flatten(bytes32[] memory b) private pure returns (bytes memory)
    {
        bytes memory result = new bytes(b.length * 32);
        for (uint256 i = 0; i < b.length; i++) {
            bytes32 k = b[i];
            assembly {
                mstore(add(result, add(32, mul(32, i))), k)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: UNLICENSED
// constructor

// receive function (if exists)

// fallback function (if exists)

// external

// public

// internal

// private

// Within a grouping, place the view and pure functions last.
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "./interfaces/IMirakaiScrollsRenderer.sol";
import "./interfaces/IOrbsToken.sol";

import {console} from "lib/forge-std/src/console.sol";

contract MirakaiScrolls is Ownable, ERC721 {
    error CallerIsContract();
    error InvalidSignature();
    error MintNotActive();
    error NotEnoughSupply();
    error IncorrectEtherValue();
    error MintQuantityTooHigh();
    error TeamMintOver();
    error NotTokenOwner();
    error ClanIsUnrollableTrait();
    error TokenDoesNotExist();
    error WalletAlreadyMinted();

    using ECDSA for bytes32;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant TEAM_RESERVE = 50;
    // this is 14 bits of 1s - the size of a trait 'slot' in the dna
    uint256 constant BIT_MASK = 2**14 - 1;

    address public scrollsRenderer;
    address public orbsToken;

    uint256 public basePrice;
    uint256 public mintprice;
    uint256 public cc0TraitsProbability;
    uint256 public totalSupply;
    // cost in ORBS to reroll trait
    uint256 public rerollTraitCost;
    uint256 public numTeamMints;

    bool public mintIsActive;
    bool public cc0MintIsActive;
    bool public allowListMintIsActive;

    // tokenId to dna
    mapping(uint256 => uint256) public dna;

    // for pseudo-rng
    uint256 private _seed;
    // public key for sig verification
    address private _signer;

    mapping(address => uint256) private allowListMinted;
    mapping(address => uint256) private cc0ListMinted;

    constructor() ERC721("Mirakai Scrolls", "MIRIKAI_SCROLLS") {}

    /**
     * @dev can be called more than once, but most likely wont be
     */
    function initialize(
        address _scrollsRenderer,
        address _orbsToken,
        address _signerAddr,
        uint256 _basePrice,
        uint256 _cc0TraitsProbability,
        uint256 _rerollTraitCost,
        uint256 _seedNum
    ) external onlyOwner {
        scrollsRenderer = _scrollsRenderer;
        orbsToken = _orbsToken;
        _signer = _signerAddr;
        basePrice = _basePrice;
        cc0TraitsProbability = _cc0TraitsProbability;
        rerollTraitCost = _rerollTraitCost;
        _seed = _seedNum;
    }

    function setscrollsRenderer(address _scrollsRenderer) external onlyOwner {
        scrollsRenderer = _scrollsRenderer;
    }

    function setOrbsTokenAddress(address _orbsToken) external onlyOwner {
        orbsToken = _orbsToken;
    }

    function setSigner(address signer) external onlyOwner {
        _signer = signer;
    }

    function setBasePrice(uint256 _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }

    function setCc0TraitsProbability(uint256 _cc0TraitsProbability)
        external
        onlyOwner
    {
        cc0TraitsProbability = _cc0TraitsProbability;
    }

    function setRerollCost(uint256 _rerollTraitCost) external onlyOwner {
        rerollTraitCost = _rerollTraitCost;
    }

    function flipMint() external onlyOwner {
        mintIsActive = !mintIsActive;
    }

    function flipCC0Mint() external onlyOwner {
        cc0MintIsActive = !cc0MintIsActive;
    }

    function flipAllowListMint() external onlyOwner {
        allowListMintIsActive = !allowListMintIsActive;
    }

    function setSeed(uint256 seed) external onlyOwner {
        _seed = seed;
    }

    /**
     * @notice anyone can increment seed, attempts to add more entropy
     */
    function incrementSeed() external {
        // overflows are okay
        unchecked {
            ++_seed;
        }
    }

    function teamMint(uint256 quantity) external onlyOwner {
        uint256 currSupply = totalSupply;

        if (
            quantity > (TEAM_RESERVE - numTeamMints) ||
            numTeamMints > TEAM_RESERVE
        ) revert TeamMintOver();
        // check MAX_SUPPLY incase we try to mint after we open public mints
        if (currSupply + quantity >= MAX_SUPPLY) revert NotEnoughSupply();

        unchecked {
            for (uint256 i = 0; i < quantity; i++) {
                ++numTeamMints;
                mint(currSupply++);
            }
        }

        totalSupply = currSupply;
    }

    /**
     * @notice public mint
     * @param quantity self-explanatory lmao
     */
    function publicMint(uint256 quantity) external payable {
        uint256 currSupply = totalSupply;

        if (tx.origin != msg.sender) revert CallerIsContract();
        if (!mintIsActive) revert MintNotActive();
        if (currSupply + quantity >= MAX_SUPPLY) revert NotEnoughSupply();
        if (quantity > 5) revert MintQuantityTooHigh();
        if (quantity * mintprice != msg.value) revert IncorrectEtherValue();
        unchecked {
            for (uint256 i = 0; i < quantity; ++i) {
                mint(currSupply++);
            }
        }

        totalSupply = currSupply;
    }

    /**
     * @notice allowlist mint. 1 per address
     * @param signature signature used for verification
     */
    function allowListMint(bytes calldata signature) external payable {
        uint256 currSupply = totalSupply;

        if (tx.origin != msg.sender) revert CallerIsContract();
        if (!allowListMintIsActive) revert MintNotActive();
        if (currSupply + 1 >= MAX_SUPPLY) revert NotEnoughSupply();
        if (msg.value != mintprice) revert IncorrectEtherValue();
        if (allowListMinted[msg.sender] > 0) revert WalletAlreadyMinted();
        if (!verify(getMessageHash(msg.sender, 1, 0), signature))
            revert InvalidSignature();

        allowListMinted[msg.sender] = 1;
        unchecked {
            mint(currSupply++);
        }
        totalSupply = currSupply;
    }

    // price set after cc0 mint
    function setMintPrice(uint256 price) external onlyOwner {
        mintprice = price;
    }

    /**
     * @notice mint a scroll with a possibility to have 'borrowed' cc0 trait
     * @param cc0Index the index for the cc0 trait
     * @param signature signature for verification
     */
    function cc0Mint(uint256 cc0Index, bytes calldata signature)
        external
        payable
    {
        uint256 currSupply = totalSupply;

        if (tx.origin != msg.sender) revert CallerIsContract();
        if (!cc0MintIsActive) revert MintNotActive();
        if (currSupply + 1 >= MAX_SUPPLY) revert NotEnoughSupply();
        if (msg.value < basePrice) revert IncorrectEtherValue();
        if (cc0ListMinted[msg.sender] > 0) revert WalletAlreadyMinted();
        if (!verify(getMessageHash(msg.sender, 1, cc0Index), signature))
            revert InvalidSignature();

        unchecked {
            uint256 tokenDna = uint256(
                keccak256(
                    abi.encodePacked(
                        currSupply,
                        msg.sender,
                        block.difficulty,
                        block.timestamp,
                        _seed++
                    )
                )
            );

            if ((tokenDna << (14 * 10)) % 100 < cc0TraitsProbability) {
                tokenDna = setDna(tokenDna, cc0Index);
            } else {
                tokenDna = setDna(tokenDna, 0);
            }

            cc0ListMinted[msg.sender] = 1;
            dna[currSupply] = tokenDna;

            _mint(msg.sender, currSupply++);
        }

        totalSupply = currSupply;
    }

    function mint(uint256 tokenId) internal {
        unchecked {
            dna[tokenId] = setDna(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            tokenId,
                            msg.sender,
                            block.difficulty,
                            block.timestamp,
                            _seed++
                        )
                    )
                ),
                0 // no cc0Trait
            );
        }

        _mint(msg.sender, tokenId);
    }

    /**
     * @dev dna is split into 14 bit 'slots'. Reroll works by 'zeroing' out the desired
     * slot and replacing it with pseudo-random 14 bits.
     * @param tokenId scrollId
     * @param traitBitShiftMultiplier the trait 'slot'. ie 2 means slot 2 (shift 2*14 bits to the slot).
     */
    function rerollTrait(uint256 tokenId, uint256 traitBitShiftMultiplier)
        external
    {
        // prevent contract calls to try to mitigate gaming the pseudo-rng
        if (tx.origin != msg.sender) revert CallerIsContract();
        if (ownerOf(tokenId) != msg.sender) revert NotTokenOwner();
        if (traitBitShiftMultiplier == 0) revert ClanIsUnrollableTrait();

        IOrbsToken(orbsToken).burn(msg.sender, rerollTraitCost);

        uint256 currDna = dna[tokenId];

        unchecked {
            uint256 newTraitDna = (uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        block.difficulty,
                        block.timestamp,
                        _seed++,
                        tokenId
                    )
                )
            ) % 10000) << (14 * traitBitShiftMultiplier);

            uint256 newBitMask = ~(BIT_MASK << (14 * traitBitShiftMultiplier));

            currDna &= newBitMask;
            currDna |= newTraitDna;
        }

        dna[tokenId] = currDna;
    }

    /**
     * @dev sets the 10th 'slot' to 0 (no cc0 trait) or a cc0 index
     * @param scrollDna dna
     * @param cc0TraitIndex 0 or a cc0 index
     */
    function setDna(uint256 scrollDna, uint256 cc0TraitIndex)
        internal
        pure
        returns (uint256)
    {
        uint256 newBitMask = ~(BIT_MASK << (14 * 10));
        return (scrollDna & newBitMask) | (cc0TraitIndex << (14 * 10));
    }

    /**
     * @dev returns empty string if no renderer is set
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert TokenDoesNotExist();

        if (scrollsRenderer == address(0)) {
            return "";
        }

        return
            IMirakaiScrollsRenderer(scrollsRenderer).tokenURI(
                _tokenId,
                dna[_tokenId]
            );
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        _burn(tokenId);
        delete dna[tokenId];

        unchecked {
            totalSupply--;
        }
    }

    /**
     * @dev should ONLY be called off-chain. Used for displaying wallet's scrolls
     */
    function walletOfOwner(address addr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count;
        uint256 tokenBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](tokenBalance);

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }
        }
        return tokens;
    }

    /**
     * @dev override to add/remove token dripping on transfers/burns
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from != address(0)) {
            IOrbsToken(orbsToken).stopDripping(from, 1);
        }

        if (to != address(0)) {
            IOrbsToken(orbsToken).startDripping(to, 1);
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    function verify(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        return
            messageHash.toEthSignedMessageHash().recover(signature) == _signer;
    }

    function getMessageHash(
        address account,
        uint256 quantity,
        uint256 cc0TraitIndex
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, quantity, cc0TraitIndex));
    }
}

// uint256 private constant CLAN_BITSHIFT_MULTIPLE = 0;
// uint256 private constant GENUS_BITSHIFT_MULTIPLE = 1;
// uint256 private constant HEAD_BITSHIFT_MULTIPLE = 2;
// uint256 private constant EYES_BITSHIFT_MULTIPLE = 3;
// uint256 private constant MOUTH_BITSHIFT_MULTIPLE = 4;
// uint256 private constant UPPER_BITSHIFT_MULTIPLE = 5;
// uint256 private constant LOWER_BITSHIFT_MULTIPLE = 6;
// uint256 private constant WEAPON_BITSHIFT_MULTIPLE = 7;
// uint256 private constant MARKING_BITSHIFT_MULTIPLE = 8;
// uint256 private constant PET_BITSHIFT_MULTIPLE = 9;

// uint256 private constant CHAIN_RUNNER_CC0_INDEX = 1;
// uint256 private constant BLITMAP_CC0_INDEX = 2;
// uint256 private constant CRYPTOADZ_CC0_INDEX = 3;
// uint256 private constant ANONYMICE_CC0_INDEX = 4;
// enum Traits {
//     Clan,
//     Genus,
//     Head,
//     Eyes,
//     Mouth,
//     Upper,
//     Lower,
//     Weapon,
//     Markings
// }
// 10011010010110 - 9878
// 10011011101100 - 9964

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {console} from "lib/forge-std/src/console.sol";

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IMirakaiDnaParser.sol";

//todo: write a description here about how the weight logic works

contract MirakaiDnaParser is Ownable, IMirakaiDnaParser {
    // this is 14 bits of 1s - the size of a trait 'slot' in the dna
    uint256 private constant BIT_MASK = 2**14 - 1;
    uint256 public constant NUM_TRAITS = 10;

    uint256[][NUM_TRAITS] public weights;
    string[][NUM_TRAITS] public traits;
    string[NUM_TRAITS] public categories;

    struct TraitWeights {
        uint256 index;
        string[] traitNames;
        uint256[] traitWeights;
    }

    constructor() {
        // weights[0] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[1] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[2] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[3] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[4] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[5] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[6] = [1000, 1000, 1000, 1000, 1000, 5000];
        // weights[7] = [1, 1000, 1000, 1000, 1000, 5999]; // weapon
        // weights[8] = [1, 1000, 2000, 2000, 2000, 2999]; // markings
        // // traits[0] = [
        // //     "arcadia",
        // //     "babalys",
        // //     "titties",
        // //     "bera",
        // //     "zena",
        // //     "draconia"
        // // ];
        // traits[1] = [
        //     "balck",
        //     "less black",
        //     "light skin",
        //     "white",
        //     "pale",
        //     "goth"
        // ];
        // traits[2] = [
        //     "big ass head",
        //     "5 head",
        //     "forbidden helmet",
        //     "beanie",
        //     "mask",
        //     "bucket hat"
        // ];
        // traits[3] = [
        //     "blue eyes",
        //     "sunglasses",
        //     "gold eyes",
        //     "brown eyes",
        //     "laser",
        //     "angry eyes"
        // ];
        // traits[4] = [
        //     "toothbick",
        //     "blow job",
        //     "smiling",
        //     "grinning",
        //     "surprised",
        //     "teeeeth"
        // ];
        // traits[5] = [
        //     "elemental armour",
        //     "hoodie",
        //     "robe",
        //     "divine shirt",
        //     "sweater",
        //     "jersey"
        // ];
        // traits[6] = [
        //     "jeans",
        //     "armor pants",
        //     "shorts",
        //     "underwear",
        //     "swimsuit",
        //     "boxers"
        // ];
        // traits[7] = [
        //     "divine bow",
        //     "fire sword",
        //     "spear",
        //     "icicle",
        //     "doodoo sword",
        //     "weaponless"
        // ];
        // traits[8] = [
        //     "bandaid",
        //     "priple scar",
        //     "sunburn",
        //     "gold triange",
        //     "freckles",
        //     "unmarked"
        // ];
        categories = [
            "clan",
            "genus",
            "head",
            "eyes",
            "mouth",
            "upper",
            "lower",
            "weapon",
            "markings",
            "cc0s"
        ];
    }

    function returnWeights()
        external
        view
        returns (uint256[][NUM_TRAITS] memory)
    {
        return weights;
    }

    function returnTraits()
        external
        view
        returns (string[][NUM_TRAITS] memory)
    {
        return traits;
    }

    function setTraitsAndWeights(TraitWeights[] calldata input)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < input.length; i++) {
            delete traits[input[i].index];
            delete weights[input[i].index];
            for (uint256 j = 0; j < input[i].traitNames.length; j++) {
                traits[input[i].index].push(input[i].traitNames[j]);
                weights[input[i].index].push(input[i].traitWeights[j]);
            }
        }
    }

    /**
     * @dev splits dna into its 14 bit trait slots, then mods it to get a number < 10k
     */
    function splitDna(uint256 dna)
        public
        pure
        returns (uint256[NUM_TRAITS] memory traitDnas)
    {
        for (uint256 i = 0; i < NUM_TRAITS; i++) {
            unchecked {
                traitDnas[i] = (dna & BIT_MASK) % 10000;
                dna >>= 14;
            }
        }
    }

    function cc0Traits(uint256 scrollDna) external pure returns (uint256) {
        return ((scrollDna >> (14 * 10)) & BIT_MASK) % 10;
    }

    /**
     * @dev returns the trait index given the trait slot (the number < 10k)
     */
    function getTraitIndex(uint256 traitDna, uint256 index)
        public
        view
        returns (uint256)
    {
        uint256 lowerBound;
        uint256 percentage;
        for (uint8 i; i < weights[index].length; i++) {
            percentage = weights[index][i];
            if (traitDna >= lowerBound && traitDna < lowerBound + percentage) {
                return i;
            }
            unchecked {
                lowerBound += percentage;
            }
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return weights[index].length;
    }

    /**
     * @dev given dna, split it into its slots and return the indexes in the weights array
     */
    function getTraitIndexes(uint256 dna)
        external
        view
        returns (uint256[NUM_TRAITS] memory traitIndexes)
    {
        uint256[NUM_TRAITS] memory traitDnas = splitDna(dna);

        for (uint256 i = 0; i < NUM_TRAITS; i++) {
            uint256 traitIndex = getTraitIndex(traitDnas[i], i);
            traitIndexes[i] = traitIndex;
        }
    }

    /**
     * @dev return the trait name string given the trait index
     */
    function getTraitName(uint256 categoryIndex, uint256 traitIndex)
        external
        view
        returns (string memory)
    {
        return traits[categoryIndex][traitIndex];
    }

    /**
     * @dev return an array of trait name strings given an array of trait indexes
     */
    function getTraitNames(uint256[NUM_TRAITS] memory traitIndexes)
        external
        view
        returns (string[NUM_TRAITS] memory traitNames)
    {
        for (uint8 i = 0; i < NUM_TRAITS; i++) {
            traitNames[i] = traits[i][traitIndexes[i]];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {GIGADRIP20} from "lib/DRIP20/src/GIGADRIP20.sol";
import {console} from "lib/forge-std/src/console.sol";

contract OrbsToken is Ownable, GIGADRIP20 {
    error NotOwnerOrScrollsContract();

    address public mirakaiScrolls;

    function setmirakaiScrolls(address mirakaiScrollsAddress) external {
        mirakaiScrolls = mirakaiScrollsAddress;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) GIGADRIP20(_name, _symbol, _decimals, _emissionRatePerBlock) {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function startDripping(address addr, uint256 multiplier) external {
        if (msg.sender != mirakaiScrolls && msg.sender != owner())
            revert NotOwnerOrScrollsContract();

        _startDripping(addr, multiplier);
    }

    function stopDripping(address addr, uint256 multiplier) external {
        if (msg.sender != mirakaiScrolls && msg.sender != owner())
            revert NotOwnerOrScrollsContract();

        _stopDripping(addr, multiplier);
    }

    function burn(address from, uint256 value) external {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - value;

        console.log("burning", value);

        _burn(from, value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;

    // Set block.height (newHeight)
    function roll(uint256) external;

    // Set block.basefee (newBasefee)
    function fee(uint256) external;

    // Loads a storage slot from an address (who, slot)
    function load(address, bytes32) external returns (bytes32);

    // Stores a value to an address' storage slot, (who, slot, value)
    function store(
        address,
        bytes32,
        bytes32
    ) external;

    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256, bytes32)
        external
        returns (
            uint8,
            bytes32,
            bytes32
        );

    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);

    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);

    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called,
    // and the tx.origin to be the second input
    function startPrank(address, address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;

    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;

    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;

    // Expects an error on next call
    function expectRevert(bytes calldata) external;

    function expectRevert(bytes4) external;

    // Record all storage reads and writes
    function record() external;

    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address)
        external
        returns (bytes32[] memory reads, bytes32[] memory writes);

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(
        bool,
        bool,
        bool,
        bool
    ) external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(
        address,
        bytes calldata,
        bytes calldata
    ) external;

    // Clears all mocked calls
    function clearMockedCalls() external;

    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address, bytes calldata) external;

    // Fetches the contract bytecode from its artifact file
    function getCode(string calldata) external returns (bytes memory);
}

contract TestVm {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

interface Vm {
    // Set block.timestamp (newTimestamp)
    function warp(uint256) external;
    // Set block.height (newHeight)
    function roll(uint256) external;
    // Set block.basefee (newBasefee)
    function fee(uint256) external;
    // Loads a storage slot from an address (who, slot)
    function load(address,bytes32) external returns (bytes32);
    // Stores a value to an address' storage slot, (who, slot, value)
    function store(address,bytes32,bytes32) external;
    // Signs data, (privateKey, digest) => (v, r, s)
    function sign(uint256,bytes32) external returns (uint8,bytes32,bytes32);
    // Gets address for a given private key, (privateKey) => (address)
    function addr(uint256) external returns (address);
    // Performs a foreign function call via terminal, (stringInputs) => (result)
    function ffi(string[] calldata) external returns (bytes memory);
    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address,address) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address,address) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance, (who, newBalance)
    function deal(address, uint256) external;
    // Sets an address' code, (who, newCode)
    function etch(address, bytes calldata) external;
    // Expects an error on next call
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;
    function expectRevert() external;
    // Record all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool,bool,bool,bool) external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address,bytes calldata,bytes calldata) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address,bytes calldata) external;
    // Gets the code from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata) external returns (bytes memory);
    // Labels an address in call traces
    function label(address, string calldata) external;
    // If the condition is false, discard this run's fuzz inputs and generate new ones
    function assume(bool) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IOrbsToken is IERC20 {
    function mint(uint256 amount) external;

    function startDripping(address addr, uint256 multiplier) external;

    function stopDripping(address addr, uint256 multiplier) external;

    function burn(address from, uint256 value) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///@author 0xBeans
///@notice This is a beefed up ERC20 implementation of DRIP20 that supports emission multipliers.
///@notice Multipliers are useful when certain users should accrue larger emissions. For example,
///@notice if an NFT drips 10 tokens per block to a user, and the user has 3 NFTs, then the user
///@notice should accrue 3 times as many tokens per block. This user would have a multiplier of 3.
///@notice shout out to solmate (@t11s) for the slim and efficient ERC20 implementation!
///@notice shout out to superfluid and UBI for the dripping inspiration!

abstract contract GIGADRIP20 {
    /*==============================================================
    ==                            EVENTS                          ==
    ==============================================================*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /*==============================================================
    ==                      METADATA STORAGE                      ==
    ==============================================================*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*==============================================================
    ==                       ERC20 STORAGE                        ==
    ==============================================================*/

    mapping(address => mapping(address => uint256)) public allowance;

    /*==============================================================
    ==                        DRIP STORAGE                        ==
    ==============================================================*/

    struct Accruer {
        uint256 multiplier;
        uint256 balance;
        uint256 accrualStartBlock;
    }

    // immutable token emission rate per block
    uint256 public immutable emissionRatePerBlock;

    // wallets currently getting dripped tokens
    mapping(address => Accruer) private _accruers;

    // these are all for calculating totalSupply()
    uint256 private _currAccrued;
    uint256 private _currEmissionBlockNum;
    uint256 private _currEmissionMultiple;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _emissionRatePerBlock
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        emissionRatePerBlock = _emissionRatePerBlock;
    }

    /*==============================================================
    ==                        ERC20 IMPL                          ==
    ==============================================================*/

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender];

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        _transfer(from, to, amount);

        return true;
    }

    function balanceOf(address addr) public view returns (uint256) {
        Accruer memory accruer = _accruers[addr];

        if (accruer.accrualStartBlock == 0) {
            return accruer.balance;
        }

        return
            ((block.number - accruer.accrualStartBlock) *
                emissionRatePerBlock) *
            accruer.multiplier +
            accruer.balance;
    }

    function totalSupply() public view returns (uint256) {
        return
            _currAccrued +
            (block.number - _currEmissionBlockNum) *
            emissionRatePerBlock *
            _currEmissionMultiple;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "ERC20: transfer to the zero address");

        Accruer storage fromAccruer = _accruers[from];
        Accruer storage toAccruer = _accruers[to];

        fromAccruer.balance = balanceOf(from) - amount;

        unchecked {
            toAccruer.balance += amount;
        }

        if (fromAccruer.accrualStartBlock != 0) {
            fromAccruer.accrualStartBlock = block.number;
        }

        emit Transfer(from, to, amount);
    }

    /*==============================================================
    ==                        DRIP LOGIC                          ==
    ==============================================================*/

    /**
     * @dev Add an address to start dripping tokens to.
     * @dev We need to update _currAccrued whenever we add a new dripper or INCREASE a dripper multiplier to properly update totalSupply()
     * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will INCREASE the multiplier
     * @param addr address to drip to
     * @param multiplier used to increase token drip. ie if 1 NFT drips 10 tokens per block and this address has 3 NFTs,
     * the user would need to get dripped 30 tokens per block - multipler would multiply emissions by 3
     */
    function _startDripping(address addr, uint256 multiplier) internal virtual {
        Accruer storage accruer = _accruers[addr];

        _currAccrued = totalSupply();
        _currEmissionBlockNum = block.number;
        accruer.accrualStartBlock = block.number;

        // should not overflow unless you have >2**256-1 items...
        unchecked {
            _currEmissionMultiple += multiplier;
            accruer.multiplier += multiplier;
        }

        // need to update the balance to start "fresh"
        // from the updated block and updated multiplier if the addr was already accruing
        if (accruer.accrualStartBlock != 0) {
            accruer.balance = balanceOf(addr);
        } else {
            // emit Transfer event when new address starts dripping
            emit Transfer(address(0), addr, 0);
        }
    }

    /**
     * @dev Add an address to stop dripping tokens to.
     * @dev We need to update _currAccrued whenever we remove a dripper or DECREASE a dripper multiplier to properly update totalSupply()
     * @dev IMPORTANT: Everytime you call this with an addr already getting dripped to, it will DECREASE the multiplier
     * @dev IMPORTANT: Decrease the multiplier to 0 to completely stop the address from getting dripped to
     * @param addr address to stop dripping to
     * @param multiplier used to decrease token drip. ie if addr has a multiplier of 3 already, passing in a value of 1 would decrease
     * the multiplier to 2
     */
    function _stopDripping(address addr, uint256 multiplier) internal virtual {
        Accruer storage accruer = _accruers[addr];

        // should I check for 0 multiplier too
        require(accruer.accrualStartBlock != 0, "user not accruing");

        accruer.balance = balanceOf(addr);
        _currAccrued = totalSupply();
        _currEmissionBlockNum = block.number;

        // will revert if underflow occurs
        _currEmissionMultiple -= multiplier;
        accruer.multiplier -= multiplier;

        if (accruer.multiplier == 0) {
            accruer.accrualStartBlock = 0;
        } else {
            accruer.accrualStartBlock = block.number;
        }
    }

    /*==============================================================
    ==                         MINT/BURN                          ==
    ==============================================================*/

    function _mint(address to, uint256 amount) internal virtual {
        Accruer storage accruer = _accruers[to];

        unchecked {
            _currAccrued += amount;
            accruer.balance += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        Accruer storage accruer = _accruers[from];

        // have to update supply before burning
        _currAccrued = totalSupply();
        _currEmissionBlockNum = block.number;

        accruer.balance = balanceOf(from) - amount;

        // Cannot underflow because amount can
        // never be greater than the totalSupply()
        unchecked {
            _currAccrued -= amount;
        }

        // update accruers block number if user was accruing
        if (accruer.accrualStartBlock != 0) {
            accruer.accrualStartBlock = block.number;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/ds-test/src/test.sol";
import {console} from "lib/forge-std/src/console.sol";
import {stdError} from "lib/forge-std/src/stdlib.sol";
import {MirakaiHeroes} from "../MirakaiHeroes.sol";
import {MirakaiHeroesRenderer} from "../MirakaiHeroesRenderer.sol";
import {MirakaiScrolls} from "../MirakaiScrolls.sol";
import {MirakaiScrollsRenderer} from "../MirakaiScrollsRenderer.sol";
import {MirakaiDnaParser} from "../MirakaiDnaParser.sol";
import {OrbsToken} from "../OrbsToken/OrbsToken.sol";
import {TestVm} from "./TestVm.sol";

contract MirakaiHeroesTest is DSTest, TestVm {
    MirakaiHeroes private mirakaiHeroes;
    MirakaiHeroesRenderer private mirakaiHeroesRenderer;
    MirakaiScrolls private mirakaiScrolls;
    MirakaiScrollsRenderer private mirakaiScrollsRenderer;
    MirakaiDnaParser private mirakaiDnaParser;
    OrbsToken private orbs;
    // public/private key for sigs
    address signer = 0x4A455783fC9022800FC6C03A73399d5bEB4065e8;
    uint256 signerPk =
        0x3532c806834d0a952c89f8954e2f3c417e3d6a5ad0d985c4a87a545da0ca722a;

    address user1 = 0x2Af416FDA8d86fAabDe21758aEea6c1BA5Da1f38;
    address user2 = 0x4b3d0D71A31F1f5e28B79bc0222bFEef4449B479;
    address user3 = 0xdb3f55B9559566c57987e523Be1aFb09Dd5df59c;

    function setUp() public {
        mirakaiHeroes = new MirakaiHeroes();
        mirakaiHeroesRenderer = new MirakaiHeroesRenderer("mock.com/");
        mirakaiScrollsRenderer = new MirakaiScrollsRenderer();
        mirakaiDnaParser = new MirakaiDnaParser();
        mirakaiScrolls = new MirakaiScrolls();
        orbs = new OrbsToken("mock", "mock", 18, 10);

        mirakaiHeroes.initialize(
            address(mirakaiHeroesRenderer),
            address(mirakaiDnaParser),
            address(orbs),
            address(mirakaiScrolls),
            0 // sumomCost
        );

        mirakaiScrolls.initialize(
            address(mirakaiScrollsRenderer),
            address(orbs),
            signer,
            0, // basePrice
            0, // cc0TraitsProbability
            0, // rerollTraitCost
            0 // seed
        );

        mirakaiScrollsRenderer.setmirakaiDnaParser(address(mirakaiDnaParser));
        orbs.setmirakaiScrolls(address(mirakaiScrolls));
        setDnaParserTraitsAndWeights();
    }

    // should burn scroll and summon hero
    function testSummon() public {
        // need to start block num > 0
        vm.roll(1);

        // flip all flags
        mirakaiHeroes.flipSummon();
        mirakaiScrolls.flipCC0Mint();
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setCc0TraitsProbability(100);

        mirakaiHeroes.setSummonCost(50e18); // 50 $ORBS

        // mint $ORBS to user
        orbs.mint(user1, 50e18);
        assertEq(orbs.balanceOf(user1), 50e18);

        vm.startPrank(user1, user1);
        orbs.approve(address(mirakaiHeroes), type(uint256).max);

        // mint 6 tokens total
        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));
        mirakaiScrolls.publicMint(5);

        // dna
        uint256 scrollDna = mirakaiScrolls.dna(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 6);
        // check that cc0Index was properly set for token
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 6);

        mirakaiScrolls.setApprovalForAll(address(mirakaiHeroes), true);
        mirakaiHeroes.summon(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 5);
        // check that dna was zeroed
        assertEq(mirakaiScrolls.dna(0), 0);
        assertEq(mirakaiScrolls.totalSupply(), 5);

        assertEq(mirakaiHeroes.totalSupply(), 1);
        assertEq(mirakaiHeroes.balanceOf(user1), 1);
        assertEq(mirakaiHeroes.ownerOf(0), user1);
        // check cc0 and dna were properly set for heroes
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiHeroes.dna(0)), 1);
        assertEq(mirakaiHeroes.dna(0), scrollDna);
        assertEq(orbs.balanceOf(user1), 0);

        // should revert since no more $ORBS
        vm.expectRevert(stdError.arithmeticError);
        mirakaiHeroes.summon(4);
    }

    // should mint tokens
    function testBatchSummon() public {
        // need to start block num > 0
        vm.roll(1);

        // flip all flags
        mirakaiHeroes.flipSummon();
        mirakaiScrolls.flipCC0Mint();
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setCc0TraitsProbability(100);

        mirakaiHeroes.setSummonCost(50e18); // 50 $ORBS

        // mint enoug $ORBS for 3 summons
        orbs.mint(user1, 150e18);
        assertEq(orbs.balanceOf(user1), 150e18);

        vm.startPrank(user1, user1);
        orbs.approve(address(mirakaiHeroes), type(uint256).max);

        // mint 6 tokens total
        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));
        mirakaiScrolls.publicMint(5);

        // dna
        uint256 scrollDna = mirakaiScrolls.dna(0);

        assertEq(mirakaiScrolls.balanceOf(user1), 6);
        // check that cc0Index was properly set for scroll 0
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 1);
        assertEq(mirakaiScrolls.totalSupply(), 6);

        mirakaiScrolls.setApprovalForAll(address(mirakaiHeroes), true);

        uint256[] memory tokensTosummon = new uint256[](3);
        tokensTosummon[0] = 0;
        tokensTosummon[1] = 1;
        tokensTosummon[2] = 2;
        mirakaiHeroes.batchSummon(tokensTosummon);

        assertEq(mirakaiScrolls.balanceOf(user1), 3);
        // check cc0 and dna were zeroed out for scroll 0
        assertEq(mirakaiDnaParser.cc0Traits(mirakaiScrolls.dna(0)), 0);
        assertEq(mirakaiScrolls.dna(0), 0);
        assertEq(mirakaiScrolls.totalSupply(), 3);

        assertEq(mirakaiHeroes.totalSupply(), 3);
        assertEq(mirakaiHeroes.balanceOf(user1), 3);
        // check dna was zeroed
        assertEq(mirakaiHeroes.dna(0), scrollDna);
        assertEq(orbs.balanceOf(user1), 0);
        // check that proper tokenIDs got summoned
        assertEq(mirakaiHeroes.ownerOf(0), user1);
        assertEq(mirakaiHeroes.ownerOf(1), user1);
        assertEq(mirakaiHeroes.ownerOf(2), user1);

        // should revert since no more $ORBS
        vm.expectRevert(stdError.arithmeticError);
        mirakaiHeroes.summon(4);
    }

    // should burn
    function testBurn() public {
        // cant start at block 0 or else it messes up $ORBS dripping
        vm.roll(1);
        // flip all flags
        mirakaiHeroes.flipSummon();
        mirakaiScrolls.flipCC0Mint();
        mirakaiScrolls.flipMint();
        mirakaiScrolls.setCc0TraitsProbability(100);

        mirakaiHeroes.setSummonCost(50e18); // 50 $ORBS

        // mint $ORBS to user
        orbs.mint(user1, 50e18);
        assertEq(orbs.balanceOf(user1), 50e18);

        vm.startPrank(user1, user1);
        orbs.approve(address(mirakaiHeroes), type(uint256).max);

        mirakaiScrolls.cc0Mint(1, (signMessage(user1, 1, 1)));

        assertEq(orbs.balanceOf(user1), 50e18);

        mirakaiScrolls.setApprovalForAll(address(mirakaiHeroes), true);
        mirakaiHeroes.summon(0);
        mirakaiHeroes.burn(0);

        assertEq(mirakaiHeroes.totalSupply(), 0);
        assertEq(mirakaiHeroes.balanceOf(user1), 0);
        // check dna is zero
        assertEq(mirakaiHeroes.dna(0), 0);
        assertEq(orbs.balanceOf(user1), 0);

        // should stop dripping after burn
        vm.roll(10);
        assertEq(orbs.balanceOf(user1), 0);
    }

    // --- utils ---
    function signMessage(
        address minter,
        uint256 quantity,
        uint256 cc0Index
    ) internal returns (bytes memory) {
        bytes32 messageHash = mirakaiScrolls.getMessageHash(
            minter,
            quantity,
            cc0Index
        );
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPk,
            ethSignedMessageHash
        );
        return abi.encodePacked(r, s, v);
    }

    function setDnaParserTraitsAndWeights() internal {
        MirakaiDnaParser.TraitWeights[]
            memory tw = new MirakaiDnaParser.TraitWeights[](10);

        uint256[] memory weights = new uint256[](6);
        weights[0] = 1000;
        weights[1] = 1000;
        weights[2] = 1000;
        weights[3] = 1000;
        weights[4] = 1000;
        weights[5] = 5000;

        string[] memory clans = new string[](6);
        clans[0] = "clan 1";
        clans[1] = "clan 2";
        clans[2] = "clan 3";
        clans[3] = "clan 4";
        clans[4] = "clan 5";
        clans[5] = "clan 6";

        string[] memory genus = new string[](6);
        genus[0] = "genus 1";
        genus[1] = "genus 2";
        genus[2] = "genus 3";
        genus[3] = "genus 4";
        genus[4] = "genus 5";
        genus[5] = "genus 6";

        string[] memory heads = new string[](6);
        heads[0] = "head 1";
        heads[1] = "head 2";
        heads[2] = "head 3";
        heads[3] = "head 4";
        heads[4] = "head 5";
        heads[5] = "head 6";

        string[] memory eyes = new string[](6);
        eyes[0] = "eye 1";
        eyes[1] = "eye 2";
        eyes[2] = "eye 3";
        eyes[3] = "eye 4";
        eyes[4] = "eye 5";
        eyes[5] = "eye 6";

        string[] memory mouths = new string[](6);
        mouths[0] = "mouth 1";
        mouths[1] = "mouth 2";
        mouths[2] = "mouth 3";
        mouths[3] = "mouth 4";
        mouths[4] = "mouth 5";
        mouths[5] = "mouth 6";

        string[] memory tops = new string[](6);
        tops[0] = "top 1";
        tops[1] = "top 2";
        tops[2] = "top 3";
        tops[3] = "top 4";
        tops[4] = "top 5";
        tops[5] = "top 6";

        string[] memory bottoms = new string[](6);
        bottoms[0] = "bottom 1";
        bottoms[1] = "bottom 2";
        bottoms[2] = "bottom 3";
        bottoms[3] = "bottom 4";
        bottoms[4] = "bottom 5";
        bottoms[5] = "bottom 6";

        string[] memory weapons = new string[](6);
        weapons[0] = "weapons 1";
        weapons[1] = "weapons 2";
        weapons[2] = "weapons 3";
        weapons[3] = "weapons 4";
        weapons[4] = "weapons 5";
        weapons[5] = "weapons 6";

        string[] memory markings = new string[](6);
        markings[0] = "markings 1";
        markings[1] = "markings 2";
        markings[2] = "markings 3";
        markings[3] = "markings 4";
        markings[4] = "markings 5";
        markings[5] = "markings 6";

        string[] memory cc0s = new string[](6);
        cc0s[0] = "cc0 1";
        cc0s[1] = "cc0 2";
        cc0s[2] = "cc0 3";
        cc0s[3] = "cc0 4";
        cc0s[4] = "cc0 5";
        cc0s[5] = "No cc0";

        tw[0] = MirakaiDnaParser.TraitWeights(0, clans, weights);
        tw[1] = MirakaiDnaParser.TraitWeights(1, genus, weights);
        tw[2] = MirakaiDnaParser.TraitWeights(2, heads, weights);
        tw[3] = MirakaiDnaParser.TraitWeights(3, eyes, weights);
        tw[4] = MirakaiDnaParser.TraitWeights(4, mouths, weights);
        tw[5] = MirakaiDnaParser.TraitWeights(5, tops, weights);
        tw[6] = MirakaiDnaParser.TraitWeights(6, bottoms, weights);
        tw[7] = MirakaiDnaParser.TraitWeights(7, weapons, weights);
        tw[8] = MirakaiDnaParser.TraitWeights(8, markings, weights);
        tw[9] = MirakaiDnaParser.TraitWeights(9, cc0s, weights);

        mirakaiDnaParser.setTraitsAndWeights(tw);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./interfaces/IOrbsToken.sol";
import "./interfaces/IMirakaiDnaParser.sol";
import "./interfaces/IMirakaiScrolls.sol";
import "./interfaces/IMirakaiHeroesRenderer.sol";

// import {console} from "forge-std/console.sol";

contract MirakaiHeroes is Ownable, ERC721 {
    error SummonNotActive();

    uint256 public constant MAX_SUPPLY = 10000;
    bool public summonActive;

    address public heroesRenderer;
    address public orbsToken;
    address public mirakaiScrolls;
    address public dnaParser;

    // cost to summon
    uint256 public summonCost;
    uint256 public totalSupply;

    // tokenId to dna
    mapping(uint256 => uint256) public dna;

    string private _tokenBaseURI;

    constructor() ERC721("Mirakai Heroes", "MIRIKAI_HEROES") {}

    function initialize(
        address _heroesRenderer,
        address _dnaParser,
        address _orbsToken,
        address _scrolls,
        uint256 _summonCost
    ) external onlyOwner {
        heroesRenderer = _heroesRenderer;
        dnaParser = _dnaParser;
        orbsToken = _orbsToken;
        mirakaiScrolls = _scrolls;
        summonCost = _summonCost;
    }

    function setHeroesRenderer(address _heroesRenderer) external onlyOwner {
        heroesRenderer = _heroesRenderer;
    }

    function setDnaParser(address _dnaParser) external onlyOwner {
        dnaParser = _dnaParser;
    }

    function setOrbsTokenAddress(address _orbsTokenAddress) external onlyOwner {
        orbsToken = _orbsTokenAddress;
    }

    function setScrollsAddress(address _mirakaiScrolls) external onlyOwner {
        mirakaiScrolls = _mirakaiScrolls;
    }

    function setSummonCost(uint256 _summonCost) external onlyOwner {
        summonCost = _summonCost;
    }

    function flipSummon() external onlyOwner {
        summonActive = !summonActive;
    }

    /**
     * @notice summon a single hero from scroll
     * @param scrollId self-explanatory
     */
    function summon(uint256 scrollId) external {
        if (!summonActive) revert SummonNotActive();

        // set dna on this contract, it will get deleted on the scrolls contracts
        dna[scrollId] = IMirakaiScrolls(mirakaiScrolls).dna(scrollId);

        //burn scroll
        IMirakaiScrolls(mirakaiScrolls).burn(scrollId);
        //burn orbs
        IOrbsToken(orbsToken).burn(msg.sender, summonCost);

        unchecked {
            ++totalSupply;
        }
        _mint(msg.sender, scrollId);
    }

    /**
     * @notice batch summon heroes
     * @param scrollIds array of scrollIds
     */
    function batchSummon(uint256[] calldata scrollIds) external {
        uint256 currSupply = totalSupply;

        if (!summonActive) revert SummonNotActive();

        for (uint256 i = 0; i < scrollIds.length; ++i) {
            uint256 scrollId = scrollIds[i];

            // set dna on this contract, it will get deleted on the scrolls contracts
            dna[scrollId] = IMirakaiScrolls(mirakaiScrolls).dna(scrollId);

            //burn scroll
            IMirakaiScrolls(mirakaiScrolls).burn(scrollId);
            //burn orbs
            IOrbsToken(orbsToken).burn(msg.sender, summonCost);

            unchecked {
                ++currSupply;
            }
            _mint(msg.sender, scrollId);
        }

        totalSupply = currSupply;
    }

    /**
     * @dev returns empty string if no renderer is set
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (heroesRenderer == address(0)) {
            return "";
        }
        return
            IMirakaiHeroesRenderer(heroesRenderer).tokenURI(
                tokenId,
                dna[tokenId]
            );
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    /**
     * @dev should ONLY be called off-chain. Used for displaying wallet's scrolls
     */
    function walletOfOwner(address addr)
        external
        view
        returns (uint256[] memory)
    {
        uint256 count;
        uint256 tokenBalance = balanceOf(addr);
        uint256[] memory tokens = new uint256[](tokenBalance);

        for (uint256 i = 0; i < MAX_SUPPLY; i++) {
            // exists will prevent throw if burned token
            if (_exists(i) && ownerOf(i) == addr) {
                tokens[count] = i;
                count++;
            }
        }
        return tokens;
    }

    function burn(uint256 tokenId) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );

        _burn(tokenId);
        delete dna[tokenId];

        unchecked {
            totalSupply--;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract MirakaiHeroesRenderer is Ownable {
    string public baseTokenUri;

    using Strings for uint256;

    constructor(string memory _baseTokenUri) {
        baseTokenUri = _baseTokenUri;
    }

    function setBaseTokenUri(string memory _baseTokenUri) external onlyOwner {
        baseTokenUri = _baseTokenUri;
    }

    function tokenURI(uint256 _tokenId, uint256 dna)
        external
        view
        returns (
            // uint256 cc0Trait
            string memory
        )
    {
        return
            string(
                abi.encodePacked(
                    baseTokenUri,
                    _tokenId.toString(),
                    "?dna=",
                    dna.toString()
                )
            );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMirakaiScrolls {
    function dna(uint256 tokenId) external view returns (uint256);

    function cc0Traits(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IMirakaiHeroesRenderer {
    function tokenURI(uint256 _tokenId, uint256 dna)
        external
        view
        returns (string memory);
}