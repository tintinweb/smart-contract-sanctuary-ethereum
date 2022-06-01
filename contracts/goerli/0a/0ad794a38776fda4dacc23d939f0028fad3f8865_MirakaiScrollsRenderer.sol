//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

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