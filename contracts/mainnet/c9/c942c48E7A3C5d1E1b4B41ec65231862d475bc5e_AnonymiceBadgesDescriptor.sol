/* solhint-disable quotes */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnonymiceBadgesData.sol";
import "./IAnonymiceBadges.sol";
import "./POAPLibrary.sol";

contract AnonymiceBadgesDescriptor is Ownable {
    address public anonymiceBadgesDataAddress;
    address public anonymiceBadgesAddress;

    function tokenURI(uint256 id) public view returns (string memory) {
        string memory name = string(
            abi.encodePacked('{"name": "Anonymice Collector Card #', POAPLibrary._toString(id))
        );

        address wallet = IAnonymiceBadges(anonymiceBadgesAddress).ownerOf(id);
        uint256[] memory poaps = IAnonymiceBadges(anonymiceBadgesAddress).getBoardPOAPs(wallet);
        uint256 boardId = IAnonymiceBadges(anonymiceBadgesAddress).currentBoard(wallet);
        string memory boardName = IAnonymiceBadges(anonymiceBadgesAddress).boardNames(wallet);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    POAPLibrary.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    name,
                                    '", "image": "data:image/svg+xml;base64,',
                                    POAPLibrary.encode(bytes(buildSvg(boardId, poaps, boardName, false))),
                                    '","attributes": [',
                                    buildAttributes(poaps),
                                    "],",
                                    '"description": "Soulbound Collector Cards and Unlockable Badges. 100% on-chain, no APIs, no IPFS, no transfers. Just code."',
                                    "}"
                                )
                            )
                        )
                    )
                )
            );
    }

    function buildSvg(
        uint256 boardId,
        uint256[] memory poaps,
        string memory boardName,
        bool isPreview
    ) public view returns (string memory) {
        POAPLibrary.Board memory board = IAnonymiceBadges(anonymiceBadgesAddress).getBoard(boardId);

        string memory viewBox = string(
            abi.encodePacked("0 0 ", POAPLibrary._toString(board.width), " ", POAPLibrary._toString(board.height))
        );
        string memory svg = '<svg id="board" width="100%" height="100%" version="1.1" viewBox="';

        svg = string(
            abi.encodePacked(
                svg,
                viewBox,
                '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">'
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                '<image x="0" y="0" width="100%" height="100%" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBoardImage(board.id),
                '" />'
            )
        );
        for (uint256 index = 0; index < board.slots.length; index++) {
            svg = string(
                abi.encodePacked(
                    svg,
                    '<g transform="translate(',
                    POAPLibrary._toString(board.slots[index].x),
                    ", ",
                    POAPLibrary._toString(board.slots[index].y),
                    ")"
                )
            );
            uint32 scale = board.slots[index].scale;
            if (scale != 0) {
                uint32 base = scale / 100;
                uint32 decimals = scale % 100;
                svg = string(
                    abi.encodePacked(
                        svg,
                        " scale(",
                        POAPLibrary._toString(base),
                        ".",
                        POAPLibrary._toString(decimals),
                        ")"
                    )
                );
            }
            if (isPreview && poaps[index] == 0) {
                svg = string(abi.encodePacked(svg, '">', _getSlotPlaceholder(index + 1), "</g>"));
            } else {
                svg = string(abi.encodePacked(svg, '">', _getBadgeImage(poaps[index]), "</g>"));
            }
        }
        svg = string(
            abi.encodePacked(
                svg,
                '<text x="50%" y="40" text-anchor="middle" font-weight="bold" font-size="32" font-family="Pixeled">',
                boardName,
                "</text>"
            )
        );
        svg = string(
            abi.encodePacked(
                svg,
                "<style>",
                "@font-face {font-family: Pixeled;font-style: normal;src: url(",
                IAnonymiceBadgesData(anonymiceBadgesDataAddress).getFontSource(),
                ") format('truetype')}",
                "</style>"
            )
        );
        svg = string(abi.encodePacked(svg, "</svg>"));
        return svg;
    }

    function buildAttributes(uint256[] memory poaps) public view returns (string memory) {
        string memory svg = "";
        bool hasAny = false;
        for (uint256 index = 0; index < poaps.length; index++) {
            if (poaps[index] != 0) {
                string memory badgeName = _getBadgeName(poaps[index]);
                svg = string(abi.encodePacked(svg, '{"value": "', badgeName, '"},'));
                hasAny = true;
            }
        }
        // if has any, remove the last comma
        if (hasAny) {
            svg = POAPLibrary.substring(svg, 0, bytes(svg).length - 1);
        }

        return svg;
    }

    function badgeImages(uint256 badgeId) external view returns (string memory) {
        return IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadge(badgeId).image;
    }

    function boardImages(uint256 badgeId) external view returns (string memory) {
        return IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBoardImage(badgeId);
    }

    function _getBadgeImage(uint256 badgeId) internal view returns (string memory) {
        IAnonymiceBadgesData.Badge memory badge = IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadge(badgeId);

        return
            string(
                abi.encodePacked(
                    '<image width="128" height="128" image-rendering="pixelated" preserveAspectRatio="xMinYMin" xlink:href="',
                    badge.image,
                    '" />',
                    '<text x="64" fill="white" y="142" text-anchor="middle" font-weight="bold" font-family="Pixeled">',
                    badge.nameLine1,
                    "</text>",
                    '<text x="64" fill="white" y="158" text-anchor="middle" font-weight="bold" font-family="Pixeled">',
                    badge.nameLine2,
                    "</text>"
                )
            );
    }

    function _getBadgeName(uint256 badgeId) internal view returns (string memory) {
        IAnonymiceBadgesData.Badge memory badge = IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadge(badgeId);

        return string(abi.encodePacked(badge.nameLine1, " ", badge.nameLine2));
    }

    function _getSlotPlaceholder(uint256 slot) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    IAnonymiceBadgesData(anonymiceBadgesDataAddress).getBadgePlaceholder(),
                    '<text x="64" y="70" text-anchor="middle" id="slot" fill="white" font-weight="bold" font-size="16px" font-family="Pixeled">Slot ',
                    POAPLibrary._toString(slot),
                    "</text>"
                )
            );
    }

    function setAnonymiceBadgesAddress(address _anonymiceBadgesAddress) external onlyOwner {
        anonymiceBadgesAddress = _anonymiceBadgesAddress;
    }

    function setAnonymiceBadgesDataAddress(address _anonymiceBadgesDataAddress) external onlyOwner {
        anonymiceBadgesDataAddress = _anonymiceBadgesDataAddress;
    }
}
/* solhint-enable quotes */

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

pragma solidity ^0.8.7;

interface IAnonymiceBadgesData {
    struct Badge {
        string image;
        string nameLine1;
        string nameLine2;
    }

    function getBadgePlaceholder() external view returns (string memory);

    function getFontSource() external view returns (string memory);

    function getBoardImage(uint256 badgeId) external view returns (string memory);

    function getBadge(uint256 badgeId) external view returns (Badge memory);

    function getBadgeRaw(uint256 badgeId)
        external
        view
        returns (
            string memory,
            string memory,
            string memory
        );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./POAPLibrary.sol";

interface IAnonymiceBadges {
    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function getAllPOAPs(address wallet) external view returns (uint256[] memory);

    function getBoardPOAPs(address wallet) external view returns (uint256[] memory);

    function currentBoard(address wallet) external view returns (uint256);

    function boardNames(address wallet) external view returns (string memory);

    function getBoard(uint256 boardId) external view returns (POAPLibrary.Board memory);

    function externalClaimPOAP(uint256 id, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library POAPLibrary {
    struct Slot {
        uint32 x;
        uint32 y;
        uint32 scale;
    }
    struct Board {
        uint128 id;
        uint64 width;
        uint64 height;
        Slot[] slots;
    }

    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
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
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
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

    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

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