// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes private constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory result) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen;
        unchecked {
            // We assume reaching overflow is unfeasible in our use cases.
            encodedLen = 4 * ((len + 2) / 3);
        }

        // Add some extra buffer at the end
        unchecked {
            result = new string(encodedLen + 32);
        }

        // Until constants are supported in inline assembly.
        bytes memory table = TABLE;

        assembly ("memory-safe") {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for { let i := 0 } lt(i, len) {} {
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
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

function packTokenId(uint256 challengeId, uint32 solutionId) pure returns (uint256) {
    return (challengeId << 32) | solutionId;
}

function unpackTokenId(uint256 tokenId) pure returns (uint256 challengeId, uint32 solutionId) {
    challengeId = tokenId >> 32;
    solutionId = uint32(tokenId);
}

// This file is derived from https://github.com/Uniswap/v3-periphery/blob/b771ff9a20a0fd7c3233df0eb70d4fa084766cde/contracts/libraries/HexStrings.sol
// which in turn originates from OpenZeppelin under an MIT license.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library HexString {
    /// Provided length is insufficient to store the value.
    error HexLengthInsufficient();

    bytes16 private constant ALPHABET = "0123456789abcdef";

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        unchecked {
            for (uint256 i = buffer.length; i > 0; --i) {
                buffer[i - 1] = ALPHABET[value & 0xf];
                value >>= 4;
            }
        }
        if (value != 0) revert HexLengthInsufficient();
        return string(buffer);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = ALPHABET[value & 0xf];
                value >>= 4;
            }
        }
        if (value != 0) revert HexLengthInsufficient();
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChallenge {
    /// Execute a given solution, using the seed to generate inputs. The actual
    /// implementation is specific to the challenge.
    /// @return The amount of gas consumed by the solution.
    function run(address target, uint256 seed) external view returns (uint32);

    /// @return An SVG snippet, which is embedded in the main NFT.
    function svg(uint256 tokenId) external view returns (string memory);

    /// @return The name of the challenge.
    function name() external view returns (string memory);

    /// @return The description of the challenge.
    /// @notice Should not have line breaks.
    function description() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IPurityChecker {
    /// @return True if the code of the given account satisfies the code purity requirements.
    function check(address account) external view returns (bool);
}

// This file is derived from https://github.com/Uniswap/v3-periphery/blob/b771ff9a20a0fd7c3233df0eb70d4fa084766cde/contracts/libraries/NFTSVG.sol

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

import {Base64} from "src/Base64.sol";
import {HexString} from "src/HexString.sol";

import {LibString} from "solmate/utils/LibString.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Uniswap NFT
library NFTSVG {
    struct SVGParams {
        string projectName;
        string challengeName;
        string solverAddr;
        string challengeAddr;
        uint256 gasUsed;
        uint256 gasOpti;
        uint256 tokenId;
        uint32 rank;
        uint32 participants;
        string color;
        uint256 x1;
        uint256 y1;
        uint256 x2;
        uint256 y2;
        uint256 x3;
        uint256 y3;
    }

    function generateSVG(SVGParams memory params, string memory challengeSVG)
        internal
        pure
        returns (string memory svg)
    {
        return string.concat(
            generateSVGDefs(params),
            generateSVGBorderText(params.projectName, params.challengeName, params.solverAddr, params.challengeAddr),
            generateSVGCardMantle(params.challengeName, params.rank, params.participants),
            generateRankBorder(params.rank),
            generateSvgCurve(challengeSVG),
            generateSVGPositionDataAndLocationCurve(LibString.toString(params.tokenId), params.gasUsed, params.gasOpti),
            generateOptimizorIcon(),
            "</svg>"
        );
    }

    function generateSVGDefs(SVGParams memory params) private pure returns (string memory svg) {
        svg = string.concat(
            '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
            "<defs>"
            '<filter id="icon"><feImage result="icon" xlink:href="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTY2LjU5NyIgaGVpZ2h0PSIxMjguOTQxIiB2aWV3Qm94PSIwIDAgNDQuMDc5IDM0LjExNiIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMjAuNzkzIDEzLjMyMWgtLjYyM1YxMi43aC02LjIyNXYuNjIyaC42MjJ2LjYyM2gtLjYyMnYuNjIyaC0uNjIzdi0uNjIySDEyLjd2Ni4yMjVoLjYyMnYuNjIzaC42MjN2LjYyMmg2LjIyNXYtLjYyMmguNjIzdi0uNjIzaC42MjJ2LTYuMjI1aC0uNjIyem0tMy43MzUgNS42MDN2LTQuMzU4aDEuODY3djQuMzU4em0xMy42OTgtNi4yMjVoLTYuODQ4di42MjJoLjYyM3YuNjIzaC0uNjIzdi42MjJoLS42MjJ2LS42MjJoLS42MjN2Ni4yMjVoLjYyM3YuNjIzaC42MjJ2LjYyMmg2Ljg0OHYtLjYyMmguNjIydi0xLjI0NWgtLjYyMnYtLjYyM0gyNy4wMnYtNC4zNThoMy43MzV2LS42MjJoLjYyMnYtLjYyM2gtLjYyMnoiIHN0eWxlPSJmaWxsOiM2NjYiLz48L3N2Zz4="/></filter>'
            '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290' height='500' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                        LibString.toString(params.x1),
                        "' cy='",
                        LibString.toString(params.y1),
                        "' r='120' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                        LibString.toString(params.x2),
                        "' cy='",
                        LibString.toString(params.y2),
                        "' r='120' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '" />',
            '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                        LibString.toString(params.x3),
                        "' cy='",
                        LibString.toString(params.y3),
                        "' r='100' fill='#",
                        params.color,
                        "'/></svg>"
                    )
                )
            ),
            '"/><feBlend mode="overlay" in="p0" in2="p1"/><feBlend mode="exclusion" in2="p2"/><feBlend mode="overlay" in2="p3" result="blendOut"/><feGaussianBlur '
            'in="blendOut" stdDeviation="42"/></filter><clipPath id="corners"><rect width="290" height="500" rx="42" ry="42"/></clipPath>'
            '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z"/>'
            '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463"/>'
            '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24"/></filter>'
            '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="#fff" stop-opacity="1"/>'
            '<stop offset=".9" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="#fff" stop-opacity="1"/><stop offset="0.9" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)"/></mask>'
            '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)"/></mask>'
            '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="#fff"/></mask>'
            '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="#fff" stop-opacity="1"/><stop offset=".95" stop-color="#fff" stop-opacity="0"/></linearGradient>'
            '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290" height="200" fill="url(#grad-symbol)"/></mask></defs>'
            '<g clip-path="url(#corners)">' '<rect fill="',
            params.color,
            '" x="0" y="0" width="290" height="500"/>'
            '<rect style="filter: url(#f1)" x="0" y="0" width="290" height="500"/>'
            '<g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">'
            '<rect fill="none" x="0" y="0" width="290" height="500"/>'
            '<ellipse cx="50%" cy="0" rx="180" ry="120" fill="#000" opacity="0.85"/></g>'
            '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"/></g>'
        );
    }

    function generateSVGBorderText(
        string memory projectName,
        string memory challengeName,
        string memory solverAddr,
        string memory challengeAddr
    ) private pure returns (string memory svg) {
        svg = string.concat(
            '<text text-rendering="optimizeSpeed">'
            '<textPath startOffset="-100%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            challengeName,
            unicode" • ",
            challengeAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>'
            '</textPath> <textPath startOffset="0%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            challengeName,
            unicode" • ",
            challengeAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath>'
            '<textPath startOffset="50%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            projectName,
            unicode" • ",
            solverAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"'
            ' repeatCount="indefinite"/></textPath><textPath startOffset="-50%" fill="#fff" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
            projectName,
            unicode" • ",
            solverAddr,
            '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/></textPath></text>'
        );
    }

    function generateSVGCardMantle(string memory challengeName, uint32 rank, uint32 participants)
        private
        pure
        returns (string memory svg)
    {
        svg = string.concat(
            '<g mask="url(#fade-symbol)"><rect fill="none" x="0" y="0" width="290" height="200"/><text y="70" x="32" fill="#fff" font-family="\'Courier New\', monospace" font-weight="200" font-size="28px">',
            challengeName,
            '</text><text y="115" x="32" fill="#fff" font-family="\'Courier New\', monospace" font-weight="200" font-size="20px">'
            "Rank ",
            LibString.toString(rank),
            " of ",
            LibString.toString(participants),
            "</text></g>"
        );
    }

    function generateRankBorder(uint32 rank) private pure returns (string memory svg) {
        string memory color;
        if (rank == 1) {
            // Golden accent.
            color = "rgba(255,215,0,1.0)";
        } else if (rank == 2) {
            // Silver accent.
            color = "rgba(255,255,255,1.0)";
        } else if (rank == 3) {
            // Bronze accent.
            color = "rgba(205,127,50,1.0)";
        } else {
            // Default (grey) accent. Assuming rank 0 is invalid, this case is for rank > 3.
            color = "rgba(255,255,255,0.2)";
        }
        svg = string.concat(
            '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="', color, '"/>'
        );
    }

    function generateSvgCurve(string memory challengeSVG) private pure returns (string memory svg) {
        svg = string.concat('<g mask="url(#none)"', ' style="transform:translate(30px,130px)">', challengeSVG, "</g>");
    }

    function generateSVGPositionDataAndLocationCurve(string memory tokenId, uint256 gasUsed, uint256 gasOpti)
        private
        pure
        returns (string memory svg)
    {
        string memory gasUsedStr = LibString.toString(gasUsed);
        string memory gasOptiStr = LibString.toString(gasOpti);
        uint256 str1length = bytes(tokenId).length + 4;
        uint256 str2length = bytes(gasUsedStr).length + 10;
        uint256 str3length = bytes(gasOptiStr).length + 14;
        svg = string.concat(
            '<g font-family="\'Courier New\', monospace" font-size="12" fill="#fff">'
            '<g style="transform:translate(29px, 384px)">' '<rect width="',
            LibString.toString(uint256(7 * (str1length + 4))),
            '" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)"/>' '<text x="12" y="17"><tspan fill="#999">ID: </tspan>',
            tokenId,
            "</text></g>" '<g style="transform:translate(29px, 414px)">' '<rect width="',
            LibString.toString(uint256(7 * (str2length + 4))),
            '" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)"/>'
            '<text x="12" y="17"><tspan fill="#999">Gas used: </tspan>',
            gasUsedStr,
            "</text></g>" '<g style="transform:translate(29px, 444px)">' '<rect width="',
            LibString.toString(uint256(7 * (str3length + 4))),
            '" height="26" rx="8" ry="8" fill="rgba(0,0,0,0.6)"/>'
            '<text x="12" y="17"><tspan fill="#999">Improvement: </tspan>',
            gasOptiStr,
            "%" "</text></g></g>"
        );
    }

    function generateOptimizorIcon() private pure returns (string memory svg) {
        return
        '<g style="transform:translate(180px, 365px)"><rect style="filter: url(#icon)" x="0" y="0" width="83" height="64"/></g>';
    }

    // This picks a "random number" out of a tokenAddress/offset/tokenId tuple.
    // Assumes offset <= 158.
    function getCircleCoord(address tokenAddress, uint256 offset, uint256 tokenId) internal pure returns (uint8) {
        unchecked {
            // This can wrap around by design.
            return uint8((((uint256(uint160(tokenAddress)) >> offset) & 0xFF) * tokenId) % 255);
        }
    }
}

//
//
//               .+++++++++++++++++++            +++++++++++++++++++++.
//               .+++++++++++++++++++            +++++++++++++++++++++.
//                  +++++++++++++++++++.           +++++++++++++++++++++
//                  +++++++++++++++++++.           +++++++++++++++++++-:
//            +: .+++++++++++++++++++++++    +=  +++++++++++++++++++++.
//            +-.:+++++++++=======+++++++    +=..+++++++++============.
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++:     :+++++++    +++++++++++++:
//            +++++++++++++++++++++++++++    +++++++++++++++++++++++++.
//            +++++++++++++++++++++++++++    +++++++++++++++++++++++++.
//            +++++++++++++++++++++++++++    +++++++++++++++++++++++++++
//            +++++++++++++++++++++++++++    +++++++++++++++++++++++++++
//             .+++++++++++++++++++++++.       +++++++++++++++++++++++++
//             .+++++++++++++++++++++++.       +++++++++++++++++++++++++
//               .+++++++++++++++++++            +++++++++++++++++++++.
//               .+++++++++++++++++++            +++++++++++++++++++++.
//
//
// The Optimizor Club NFT collection rewards gas efficient people and machines by
// minting new items whenever a cheaper solution is submitted for a certain challenge.
//

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OptimizorAdmin, OptimizorNFT} from "src/OptimizorAdmin.sol";
import {IPurityChecker} from "src/IPurityChecker.sol";
import {packTokenId} from "src/DataHelpers.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

uint256 constant EPOCH = 64;

contract Optimizor is OptimizorAdmin {
    struct Submission {
        address sender;
        uint96 blockNumber;
    }

    /// Maps a submitted key to its sender and submission block number.
    mapping(bytes32 => Submission) public submissions;

    // Commit errors
    error CodeAlreadySubmitted();
    error TooEarlyToChallenge();

    // Input filtering
    error InvalidRecipient();
    error CodeNotSubmitted();
    error NotPure();

    // Sadness
    error NotOptimizor();

    constructor(IPurityChecker _purityChecker) OptimizorAdmin(_purityChecker) {}

    /// Commit a `key` derived using
    /// `keccak256(abi.encode(sender, codehash, salt))`
    /// where
    /// - `sender`: the `msg.sender` for the call to `challenge(...)`,
    /// - `target`: the address of your solution contract,
    /// - `salt`: `uint256` secret number.
    function commit(bytes32 key) external {
        if (submissions[key].sender != address(0)) {
            revert CodeAlreadySubmitted();
        }
        submissions[key] = Submission({sender: msg.sender, blockNumber: uint96(block.number)});
    }

    /// After committing and waiting for at least 256 blocks, challenge can be
    /// called to claim an Optimizor Club NFT, if it beats the previous solution
    /// in terms of runtime gas.
    ///
    /// @param id The unique identifier for the challenge.
    /// @param target The address of your solution contract.
    /// @param recipient The address that receives the Optimizor Club NFT.
    /// @param salt The secret number used for deriving the committed key.
    function challenge(uint256 id, address target, address recipient, uint256 salt) external {
        ChallengeInfo storage chl = challenges[id];

        bytes32 key = keccak256(abi.encode(msg.sender, target.codehash, salt));

        // Frontrunning cannot steal the submission, but can block
        // it for users at the expense of the frontrunner's gas.
        // We consider that a non-issue.
        if (submissions[key].blockNumber + EPOCH >= block.number) {
            revert TooEarlyToChallenge();
        }

        if (submissions[key].sender == address(0)) {
            revert CodeNotSubmitted();
        }

        if (address(chl.target) == address(0)) {
            revert ChallengeNotFound(id);
        }

        if (recipient == address(0)) {
            revert InvalidRecipient();
        }

        if (!purityChecker.check(target)) {
            revert NotPure();
        }

        uint32 gas = chl.target.run(target, block.difficulty);

        uint256 leaderTokenId = packTokenId(id, chl.solutions);
        uint32 leaderGas = extraDetails[leaderTokenId].gas;

        if ((leaderGas != 0) && (leaderGas <= gas)) {
            revert NotOptimizor();
        }

        unchecked {
            ++chl.solutions;
        }

        uint256 tokenId = packTokenId(id, chl.solutions);
        ERC721._mint(recipient, tokenId);
        extraDetails[tokenId] = ExtraDetails(target, recipient, gas);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {OptimizorNFT} from "src/OptimizorNFT.sol";
import {IPurityChecker} from "src/IPurityChecker.sol";
import {IChallenge} from "src/IChallenge.sol";

import {Owned} from "solmate/auth/Owned.sol";

contract OptimizorAdmin is OptimizorNFT, Owned {
    /// The address of the currently used purity checker.
    IPurityChecker public purityChecker;

    error ChallengeExists(uint256 challengeId);

    event PurityCheckerUpdated(IPurityChecker newPurityChecker);
    event ChallengeAdded(uint256 challengeId, IChallenge);

    constructor(IPurityChecker _purityChecker) Owned(msg.sender) {
        updatePurityChecker(_purityChecker);
    }

    /// @dev Purity checker may need to be updated when there are EVM changes.
    function updatePurityChecker(IPurityChecker _purityChecker) public onlyOwner {
        purityChecker = _purityChecker;

        emit PurityCheckerUpdated(_purityChecker);
    }

    function addChallenge(uint256 id, IChallenge challenge) external onlyOwner {
        ChallengeInfo storage chl = challenges[id];
        if (address(chl.target) != address(0)) {
            revert ChallengeExists(id);
        }

        chl.target = challenge;

        emit ChallengeAdded(id, challenge);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IChallenge} from "src/IChallenge.sol";
import {Base64} from "src/Base64.sol";
import {packTokenId, unpackTokenId} from "src/DataHelpers.sol";
import {NFTSVG} from "src/NFTSVG.sol";
import {TokenDetails} from "src/TokenDetails.sol";
import {HexString} from "src/HexString.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract OptimizorNFT is ERC721 {
    // Invalid inputs
    error InvalidSolutionId(uint256 challengeId, uint32 solutionId);

    // Challenge id errors
    error ChallengeNotFound(uint256 challengeId);

    struct ChallengeInfo {
        /// The address of the challenge contract.
        IChallenge target;
        /// The number of valid solutions so far.
        uint32 solutions;
    }

    struct ExtraDetails {
        /// The address of the solution contract.
        address code;
        /// The address of the challenger who called `challenge`.
        address solver;
        /// The amount of gas spent by this solution.
        uint32 gas;
    }

    /// Maps challenge ids to their contracts and amount of solutions.
    mapping(uint256 => ChallengeInfo) public challenges;

    /// Maps token ids to extra details about the solution.
    mapping(uint256 => ExtraDetails) public extraDetails;

    constructor() ERC721("Optimizor Club", "OC") {}

    function contractURI() external pure returns (string memory) {
        return
        "data:application/json;base64,eyJuYW1lIjoiT3B0aW1pem9yIENsdWIiLCJkZXNjcmlwdGlvbiI6IlRoZSBPcHRpbWl6b3IgQ2x1YiBORlQgY29sbGVjdGlvbiByZXdhcmRzIGdhcyBlZmZpY2llbnQgcGVvcGxlIGFuZCBtYWNoaW5lcyBieSBtaW50aW5nIG5ldyBpdGVtcyB3aGVuZXZlciBhIGNoZWFwZXIgc29sdXRpb24gaXMgc3VibWl0dGVkIGZvciBhIGNlcnRhaW4gY2hhbGxlbmdlLiIsImltYWdlIjoiZGF0YTppbWFnZS9zdmcreG1sO2Jhc2U2NCxQSE4yWnlCM2FXUjBhRDBpTVRZMkxqVTVOeUlnYUdWcFoyaDBQU0l4TWpndU9UUXhJaUIyYVdWM1FtOTRQU0l3SURBZ05EUXVNRGM1SURNMExqRXhOaUlnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajQ4Y0dGMGFDQmtQU0pOTWpBdU56a3pJREV6TGpNeU1XZ3RMall5TTFZeE1pNDNhQzAyTGpJeU5YWXVOakl5YUM0Mk1qSjJMall5TTJndExqWXlNbll1TmpJeWFDMHVOakl6ZGkwdU5qSXlTREV5TGpkMk5pNHlNalZvTGpZeU1uWXVOakl6YUM0Mk1qTjJMall5TW1nMkxqSXlOWFl0TGpZeU1tZ3VOakl6ZGkwdU5qSXphQzQyTWpKMkxUWXVNakkxYUMwdU5qSXllbTB0TXk0M016VWdOUzQyTUROMkxUUXVNelU0YURFdU9EWTNkalF1TXpVNGVtMHhNeTQyT1RndE5pNHlNalZvTFRZdU9EUTRkaTQyTWpKb0xqWXlNM1l1TmpJemFDMHVOakl6ZGk0Mk1qSm9MUzQyTWpKMkxTNDJNakpvTFM0Mk1qTjJOaTR5TWpWb0xqWXlNM1l1TmpJemFDNDJNakoyTGpZeU1tZzJMamcwT0hZdExqWXlNbWd1TmpJeWRpMHhMakkwTldndExqWXlNbll0TGpZeU0wZ3lOeTR3TW5ZdE5DNHpOVGhvTXk0M016VjJMUzQyTWpKb0xqWXlNbll0TGpZeU0yZ3RMall5TW5vaUlITjBlV3hsUFNKbWFXeHNPaU0yTmpZaUx6NDhMM04yWno0PSIsImV4dGVybmFsX2xpbmsiOiJodHRwczovL29wdGltaXpvci5jbHViLyJ9";
    }

    function tokenDetails(uint256 tokenId) public view returns (TokenDetails memory) {
        (uint256 challengeId, uint32 solutionId) = unpackTokenId(tokenId);
        if (solutionId == 0) revert InvalidSolutionId(challengeId, solutionId);

        ChallengeInfo storage chl = challenges[challengeId];
        if (address(chl.target) == address(0)) revert ChallengeNotFound(challengeId);
        if (solutionId > chl.solutions) revert InvalidSolutionId(challengeId, solutionId);

        ExtraDetails storage details = extraDetails[tokenId];

        uint256 leaderTokenId = packTokenId(challengeId, chl.solutions);
        ExtraDetails storage leaderDetails = extraDetails[leaderTokenId];

        uint32 leaderSolutionId = chl.solutions;
        uint32 rank = leaderSolutionId - solutionId + 1;

        // This means the first holder will have a 0% improvement.
        uint32 percentage = 0;
        if (solutionId > 1) {
            ExtraDetails storage prevDetails = extraDetails[tokenId - 1];
            percentage = (details.gas * 100) / prevDetails.gas;
        }

        return TokenDetails({
            challengeId: challengeId,
            challenge: chl.target,
            leaderGas: leaderDetails.gas,
            leaderSolutionId: leaderSolutionId,
            leaderSolver: leaderDetails.solver,
            leaderOwner: _ownerOf[leaderTokenId],
            leaderSubmission: leaderDetails.code,
            gas: details.gas,
            solutionId: solutionId,
            rank: rank,
            improvementPercentage: percentage,
            solver: details.solver,
            owner: _ownerOf[tokenId],
            submission: details.code
        });
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        TokenDetails memory details = tokenDetails(tokenId);

        string memory description = string.concat(details.challenge.description(), "\\n\\n", leaderboardString(tokenId));

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name":"Optimizor Club: ',
                        details.challenge.name(),
                        '","description":"',
                        description,
                        '","attributes":',
                        attributesJSON(details),
                        ',"image":"data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg(tokenId, details))),
                        '"}'
                    )
                )
            )
        );
    }

    function leaderboard(uint256 tokenId) public view returns (address[] memory board) {
        (uint256 challengeId,) = unpackTokenId(tokenId);
        uint32 winners = challenges[challengeId].solutions;
        board = new address[](winners);
        unchecked {
            for (uint32 i = 1; i <= winners; ++i) {
                ExtraDetails storage details = extraDetails[packTokenId(challengeId, i)];
                board[i - 1] = details.solver;
            }
        }
    }

    function leaderboardString(uint256 tokenId) private view returns (string memory) {
        address[] memory leaders = leaderboard(tokenId);
        string memory leadersStr = "";
        uint256 lIdx = leaders.length;
        unchecked {
            for (uint256 i = 0; i < leaders.length; ++i) {
                leadersStr = string.concat(
                    "\\n",
                    LibString.toString(lIdx),
                    ". ",
                    HexString.toHexString(uint256(uint160(leaders[i])), 20),
                    leadersStr
                );
                --lIdx;
            }
        }
        return string.concat("Leaderboard:\\n", leadersStr);
    }

    function attributesJSON(TokenDetails memory details) private view returns (string memory attributes) {
        uint32 rank = details.rank;

        attributes = string.concat(
            '[{"trait_type":"Challenge","value":"',
            details.challenge.name(),
            '"},{"trait_type":"Gas used","value":',
            LibString.toString(details.gas),
            ',"display_type":"number"},{"trait_type":"Code size","value":',
            LibString.toString(details.submission.code.length),
            ',"display_type":"number"},{"trait_type":"Improvement percentage","value":"',
            LibString.toString(details.improvementPercentage),
            '%"},{"trait_type":"Solver","value":"',
            HexString.toHexString(uint256(uint160(details.solver)), 20),
            '"},{"trait_type":"Rank","value":',
            LibString.toString(rank),
            ',"display_type":"number"},{"trait_type":"Leader","value":"',
            (rank == 1) ? "Yes" : "No",
            '"},{"trait_type":"Top 3","value":"',
            (rank <= 3) ? "Yes" : "No",
            '"},{"trait_type":"Top 10","value":"',
            (rank <= 10) ? "Yes" : "No",
            '"}]'
        );
    }

    // This scales the value from [0,255] to [minOut,maxOut].
    // Assumes 255*maxOut <= 2^256-1.
    function scale(uint8 value, uint256 minOut, uint256 maxOut) private pure returns (uint256) {
        unchecked {
            return ((uint256(value) * (maxOut - minOut)) / 255) + minOut;
        }
    }

    function svg(uint256 tokenId, TokenDetails memory details) private view returns (string memory) {
        uint256 gradRgb = 0;
        if (details.rank > 10) {
            gradRgb = 0xbebebe;
        } else if (details.rank > 3) {
            uint256 fRank;
            uint256 init = 40;
            uint256 factor = 15;
            unchecked {
                fRank = init + details.rank * factor;
            }
            gradRgb = (uint256(fRank) << 16) | (uint256(fRank) << 8) | uint256(fRank);
        }

        NFTSVG.SVGParams memory svgParams = NFTSVG.SVGParams({
            projectName: "Optimizor Club",
            challengeName: details.challenge.name(),
            solverAddr: HexString.toHexString(uint256(uint160(address(details.owner))), 20),
            challengeAddr: HexString.toHexString(uint256(uint160(address(details.challenge))), 20),
            gasUsed: details.gas,
            gasOpti: details.improvementPercentage,
            tokenId: tokenId,
            rank: details.rank,
            // The leader is the last player, e.g. its solution id equals the number of players.
            participants: details.leaderSolutionId,
            color: HexString.toHexStringNoPrefix(gradRgb, 3),
            x1: scale(NFTSVG.getCircleCoord(address(details.challenge), 16, tokenId), 16, 274),
            y1: scale(NFTSVG.getCircleCoord(address(details.solver), 16, tokenId), 100, 484),
            x2: scale(NFTSVG.getCircleCoord(address(details.challenge), 32, tokenId), 16, 274),
            y2: scale(NFTSVG.getCircleCoord(address(details.solver), 32, tokenId), 100, 484),
            x3: scale(NFTSVG.getCircleCoord(address(details.challenge), 48, tokenId), 16, 274),
            y3: scale(NFTSVG.getCircleCoord(address(details.solver), 48, tokenId), 100, 484)
        });

        return NFTSVG.generateSVG(svgParams, details.challenge.svg(tokenId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IChallenge} from "src/IChallenge.sol";

struct TokenDetails {
    /// The ID of the challenge.
    uint256 challengeId;
    /// The address of the challenge contract.
    IChallenge challenge;
    /// Details of the leader (aka rank 1).
    uint32 leaderGas;
    uint32 leaderSolutionId;
    address leaderSolver;
    address leaderOwner;
    address leaderSubmission;
    /// Details of the current token (can be the same as the leader).
    uint32 gas;
    uint32 solutionId;
    uint32 rank;
    /// Improvement percentage compared to the previous rank.
    uint32 improvementPercentage;
    address solver;
    address owner;
    address submission;
}