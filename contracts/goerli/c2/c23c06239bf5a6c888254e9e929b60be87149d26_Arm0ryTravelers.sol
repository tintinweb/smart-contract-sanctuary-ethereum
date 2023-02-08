/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                msg.sender == getApproved[id] ||
                isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

//// @title Arm0ry Travelers
/// @notice NFTs for Arm0ry participants.
/// credit: z0r0z.eth https://gist.github.com/z0r0z/6ca37df326302b0ec8635b8796a4fdbb
/// credit: simondlr https://github.com/Untitled-Frontier/tlatc/blob/master/packages/hardhat/contracts/AnchorCertificates.sol

contract Arm0ryTravelers is ERC721 {

    /// -----------------------------------------------------------------------
    /// Custom Error
    /// -----------------------------------------------------------------------

    error NotAuthorized();

    /// -----------------------------------------------------------------------
    /// Traveler Storage
    /// -----------------------------------------------------------------------

    address payable public arm0ry; 

    IArm0ryQuests public quests;

    IArm0ryMission public mission;

    uint256 public travelerCount;

    // 16 palettes
    string[4][16] palette = [
        ["#eca3f5", "#fdbaf9", "#b0efeb", "#edffa9"],
        ["#75cfb8", "#bbdfc8", "#f0e5d8", "#ffc478"],
        ["#ffab73", "#ffd384", "#fff9b0", "#ffaec0"],
        ["#94b4a4", "#d2f5e3", "#e5c5b5", "#f4d9c6"],
        ["#f4f9f9", "#ccf2f4", "#a4ebf3", "#aaaaaa"],
        ["#caf7e3", "#edffec", "#f6dfeb", "#e4bad4"],
        ["#f4f9f9", "#f1d1d0", "#fbaccc", "#f875aa"],
        ["#fdffbc", "#ffeebb", "#ffdcb8", "#ffc1b6"],
        ["#f0e4d7", "#f5c0c0", "#ff7171", "#9fd8df"],
        ["#e4fbff", "#b8b5ff", "#7868e6", "#edeef7"],
        ["#ffcb91", "#ffefa1", "#94ebcd", "#6ddccf"],
        ["#bedcfa", "#98acf8", "#b088f9", "#da9ff9"],
        ["#bce6eb", "#fdcfdf", "#fbbedf", "#fca3cc"],
        ["#ff75a0", "#fce38a", "#eaffd0", "#95e1d3"],
        ["#fbe0c4", "#8ab6d6", "#2978b5", "#0061a8"],
        ["#dddddd", "#f9f3f3", "#f7d9d9", "#f25287"]
    ];

    constructor(address payable _arm0ry) ERC721("Arm0ry Travelers", "ART") {
        arm0ry = _arm0ry;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        string memory name = string(
            abi.encodePacked(
                "Arm0ry Traveler #",
                Strings.toString(tokenId)
            )
        );
        string memory description = "Arm0ry Travelers";
        string memory image = generateBase64Image(tokenId);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                description,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateBase64Image(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        return Base64.encode(bytes(generateImage(tokenId)));
    }

    function generateImage(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        // Retrieve seeds
        address traveler = address(uint160(tokenId));
        uint8 questId = this.getActiveQuest(traveler);
        uint8 missionId = quests.getQuestMissionId(traveler, questId);

        // Calculate Quest data
        string memory title = mission.missions(missionId).title;
        uint8 reviewerXpNeeded = quests.getQuestReviewXpNeeded(traveler, questId);

        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 pIndex = toUint8(hash, 0) / 16; // 16 palettes

        string memory paletteSection = generatePaletteSection(tokenId, pIndex);

        return
            string(
                abi.encodePacked(
                    '<svg class="svgBody" width="300" height="300" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">',
                    paletteSection,
                    '<text x="20" y="120" class="score" stroke="black" stroke-width="2">',Strings.toString(quests.getQuestProgress(traveler, questId)),'</text>',
                    '<text x="112" y="120" class="tiny" stroke="black">% Progress</text>',
                    '<text x="180" y="120" class="score" stroke="black" stroke-width="2">',Strings.toString(quests.getQuestXp(traveler, questId)),'</text>',
                    '<text x="272" y="120" class="tiny" stroke="black">Xp</text>',
                    '<text x="15" y="170" class="medium" stroke="black">QUEST: </text>',
                    '<rect x="15" y="175" width="205" height="40" style="fill:white;opacity:0.5"/>',
                    '<text x="20" y="190" class="medium" stroke="black">',title,'</text>',
                    '<text x="15" y="245" class="small" stroke="black">REVIEW XP:</text>',
                    '<text x="20" y="190" class="medium" stroke="black">',reviewerXpNeeded,'</text>',
                    // '<text x="15" y="260" style="font-size:8px" stroke="black">',addressToHexString(quests.getQuestBuddyOne(traveler, nonce)),'</text>',
                    // '<text x="15" y="275" style="font-size:8px" stroke="black">',addressToHexString(quests.getQuestBuddyTwo(traveler, nonce)),'</text>',
                    '<style>.svgBody {font-family: "Courier New" } .tiny {font-size:8px; } .small {font-size: 12px;}.medium {font-size: 18px;}.score {font-size: 70px;}</style>',
                    "</svg>"
                )
            );
    }

    function generatePaletteSection(uint256 tokenId, uint256 pIndex)
        internal
        view
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<rect width="300" height="300" rx="10" style="fill:',
                    palette[pIndex][0],
                    '" />',
                    '<rect y="205" width="300" height="80" rx="10" style="fill:',
                    palette[pIndex][3],
                    '" />',
                    '<rect y="60" width="300" height="90" style="fill:',
                    palette[pIndex][1],
                    '"/>',
                    '<rect y="150" width="300" height="75" style="fill:',
                    palette[pIndex][2],
                    '" />',
                    '<text x="15" y="25" class="medium">Traveler ID#</text>',
                    '<text x="17" y="50" class="small" opacity="0.5">',
                    substring(Strings.toString(tokenId), 0, 24),
                    "</text>",
                    '<g filter="url(#a)">',
                    '<path stroke="#FFBE0B" stroke-linecap="round" stroke-width="2.1" d="M207 48.3c12.2-8.5 65-24.8 87.5-21.6" fill="none"/></g><path fill="#000" d="M220.2 38h-.8l-2.2-.4-1 4.6-2.9-.7 1.5-6.4 1.6-8.3c1.9-.4 3.9-.6 6-.8l1.9 8.5 1.5 7.4-3 .5-1.4-7.3-1.2-6.1c-.5 0-1 0-1.5.2l-1 6 3.1.1-.4 2.6h-.2Zm8-5.6v-2.2l2.6-.3.5 1.9 1.8-2.1h1.5l.6 2.9-2 .4-1.8.4-.2 8.5-2.8.2-.2-9.7Zm8.7-2.2 2.6-.3.4 1.9 2.2-2h2.4c.3 0 .6.3 1 .6.4.4.7.9.7 1.3l2.1-1.8h3l.6.3.6.6.2.5-.4 10.7-2.8.2v-9.4a4.8 4.8 0 0 0-2.2.2l-1 .3-.3 8.7-2.7.2v-9.4a5 5 0 0 0-2.3.2l-.9.3-.3 8.6-2.7.2-.2-11.9Zm28.6 3.5a19.1 19.1 0 0 1-.3 4.3 15.4 15.4 0 0 1-.8 3.6c-.1.3-.3.4-.5.5l-.8.2h-2.3c-2 0-3.2-.2-3.6-.6-.4-.5-.8-2.1-1-5a25.7 25.7 0 0 1 0-5.6l.4-.5c.1-.2.5-.4 1-.5 2.3-.5 4.8-.8 7.4-.8h.4l.3 3-.6-.1h-.5a23.9 23.9 0 0 0-5.3.5 25.1 25.1 0 0 0 .3 7h2.4c.2-1.2.4-2.8.5-4.9v-.7l3-.4Zm3.7-1.3v-2.2l2.6-.3.5 1.9 1.9-2.1h1.4l.6 2.9-1.9.4-2 .4V42l-2.9.2-.2-9.7Zm8.5-2.5 3-.6.2 10 .8.1h.9l1.5-.6V30l2.8-.3.2 13.9c0 .4-.3.8-.8 1.1l-3 2-1.8 1.2-1.6.9-1.5-2.7 6-3-.1-3.1-1.9 2h-3.1c-.3 0-.5-.1-.8-.4-.4-.3-.6-.6-.6-1l-.2-10.7Z"/>',
                    "<defs>",
                    '<filter id="a" width="91.743" height="26.199" x="204.898" y="24.182" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse">',
                    '<feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>',
                    "</filter>",
                    "</defs>"
                )
            );
    }

    function mintTravelerPass() external payable returns (uint256 tokenId) {
        travelerCount += 1;

        tokenId = uint256(uint160(msg.sender));

        _mint(msg.sender, tokenId);
    }

    /// -----------------------------------------------------------------------
    /// Arm0ry Functions
    /// -----------------------------------------------------------------------

    function updateContracts(IArm0ryQuests _quests, IArm0ryMission _mission) external payable {
        if (msg.sender != arm0ry) revert NotAuthorized();
        quests = _quests;
        mission = _mission;
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
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

    function addressToHexString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    function getActiveQuest(address traveler) external view returns (uint8) {
        return quests.activeQuests(traveler);
    }

    function getMissionLength(uint8 missionId) external view returns (uint256) {
        return mission.getMissionLength(missionId);
    }

    function getMissionTitle(uint8 missionId) external view returns (string memory) {
        return mission.missions(missionId).title;
    }
}

/// @notice Safe ETH and ERC-20 transfer library that gracefully handles missing return values
/// @author Modified from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// License-Identifier: AGPL-3.0-only
library SafeTransferLib {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    error ETHtransferFailed();
    error TransferFailed();
    error TransferFromFailed();

    /// -----------------------------------------------------------------------
    /// ETH Logic
    /// -----------------------------------------------------------------------

    function _safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // transfer the ETH and store if it succeeded or not
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }
        if (!success) revert ETHtransferFailed();
    }

    /// -----------------------------------------------------------------------
    /// ERC-20 Logic
    /// -----------------------------------------------------------------------

    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // we'll write our calldata to this slot below, but restore it later
            let memPointer := mload(0x40)
            // write the abi-encoded calldata into memory, beginning with the function selector
            mstore(
                0,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(4, to) // append the 'to' argument
            mstore(36, amount) // append the 'amount' argument

            success := and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // we use 68 because that's the total length of our calldata (4 + 32 * 2)
                // - counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // restore the zero slot to zero
            mstore(0x40, memPointer) // restore the memPointer
        }
        if (!success) revert TransferFailed();
    }

    function _safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // we'll write our calldata to this slot below, but restore it later
            let memPointer := mload(0x40)
            // write the abi-encoded calldata into memory, beginning with the function selector
            mstore(
                0,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(4, from) // append the 'from' argument
            mstore(36, to) // append the 'to' argument
            mstore(68, amount) // append the 'amount' argument

            success := and(
                // set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
                // we use 100 because that's the total length of our calldata (4 + 32 * 3)
                // - counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // restore the zero slot to zero
            mstore(0x40, memPointer) // restore the memPointer
        }
        if (!success) revert TransferFromFailed();
    }
}

/// @notice Kali DAO share manager interface
interface IKaliShareManager {
    function mintShares(address to, uint256 amount) external payable;

    function burnShares(address from, uint256 amount) external payable;
}

interface IArm0ryTravelers {
    function ownerOf(uint256 id) external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external payable;
}

// IERC20
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IArm0ryMission {
    function missions(uint8 missionId) external view returns (Mission calldata);

    function tasks(uint8 taskId) external view returns (Task calldata);

    function isTaskInMission(uint8 missionId, uint8 taskId)
        external
        returns (bool);

    function getTaskXp(uint16 taskId) external view returns (uint8);

    function getTaskExpiration(uint16 taskId) external view returns (uint40);

    function getTaskCreator(uint16 taskId) external view returns (address);

    function getMissionTasks(uint8 missionId) external view returns (uint8[] calldata);

    function getMissionLength(uint8 missionId) external view returns (uint256);
}

/// @title Arm0ry Mission
/// @notice A list of Arm0ry missions and tasks.
/// @author audsssy.eth

struct Mission {
    uint40 expiration;
    uint8[] taskIds;
    string details;
    string title;
}

struct Task {
    uint8 xp;
    uint40 expiration;
    address creator;
    string details;
}

contract Arm0ryMission {

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event MissionSet(uint8 missionId, uint8[] indexed taskIds, string details);

    event TaskSet(
        uint40 expiration,
        uint8 points,
        address creator,
        string details
    );

    event TasksUpdated(
        uint40 expiration,
        uint8 points,
        address creator,
        string details
    );

    event PermissionUpdated(
        address indexed caller,
        address indexed admin,
        address[] indexed managers
    );

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error NotAuthorized();

    error LengthMismatch();

    error InvalidMission();

    /// -----------------------------------------------------------------------
    /// Task Storage
    /// -----------------------------------------------------------------------

    address public admin;

    address[] public managers;

    // Status indicating if an address is a Manager
    mapping(address => bool) isManager;

    uint8 public taskId;

    mapping(uint8 => Task) public tasks;

    uint8 public missionId;

    mapping(uint8 => Mission) public missions;

    // Status indicating if a Task is part of a Mission
    mapping(uint8 => mapping(uint8 => bool)) public isTaskInMission;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _admin) {
        admin = _admin;
    }

    /// -----------------------------------------------------------------------
    /// Mission / Task Logic
    /// -----------------------------------------------------------------------

    /// @notice Create tasks
    /// @param taskData Encoded data to store as Task
    /// @dev
    function setTasks(bytes[] calldata taskData) external payable {
        if (msg.sender != admin && !isManager[msg.sender])
            revert NotAuthorized();

        uint256 length = taskData.length;

        for (uint256 i = 0; i < length; ) {
            unchecked {
                ++taskId;
            }

            (
                uint8 xp,
                uint40 expiration,
                address creator,
                string memory details
            ) = abi.decode(taskData[i], (uint8, uint40, address, string));

            tasks[taskId].xp = xp;
            tasks[taskId].expiration = expiration;
            tasks[taskId].creator = creator;
            tasks[taskId].details = details;

            emit TaskSet(expiration, xp, creator, details);

            // Unchecked because the only math done is incrementing
            // the array index counter which cannot possibly overflow.
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Update tasks
    /// @param ids Identifiers of tasks to be updated
    /// @param taskData Encoded data to update as Task
    /// @dev
    function updateTasks(uint8[] calldata ids, bytes[] calldata taskData)
        external
        payable
    {
        if (msg.sender != admin && !isManager[msg.sender])
            revert NotAuthorized();

        uint256 length = ids.length;

        if (length != taskData.length) revert LengthMismatch();

        for (uint256 i = 0; i < length; ) {
            (
                uint40 expiration,
                uint8 xp,
                address creator,
                string memory details
            ) = abi.decode(taskData[i], (uint40, uint8, address, string));

            tasks[ids[i]].expiration = expiration;
            tasks[ids[i]].xp = xp;
            tasks[ids[i]].creator = creator;
            tasks[ids[i]].details = details;

            emit TasksUpdated(expiration, xp, creator, details);

            // Unchecked because the only math done is incrementing
            // the array index counter which cannot possibly overflow.
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Create missions
    /// @param _taskIds Identifiers of tasks to be added to a Mission
    /// @param _details Docs of a Mission
    /// @param _title Title of a Mission
    /// @dev
    function setMission(
        uint8[] calldata _taskIds,
        string calldata _details,
        string calldata _title
    ) external payable {
        if (msg.sender != admin && !isManager[msg.sender])
            revert NotAuthorized();

        if (missionId == 0) {
            missions[missionId] = Mission({
                expiration: 2524626000, // 01/01/2050
                taskIds: _taskIds,
                details: _details,
                title: _title
            });
        } else {
            uint40 expiration;
            for (uint256 i = 0; i < _taskIds.length; ) {
                // Aggregate Task duration to create Mission duration
                uint40 _expiration = this.getTaskExpiration(_taskIds[i]);
                expiration += _expiration;

                // Update task status
                isTaskInMission[missionId][_taskIds[i]] = true;

                // cannot possibly overflow
                unchecked {
                    ++i;
                }
            }
        
            missions[missionId] = Mission({
                expiration: expiration,
                taskIds: _taskIds,
                details: _details,
                title: _title
            });
        }

        emit MissionSet(missionId, _taskIds, _details);
    }

    /// @notice Update missions
    /// @param _missionId Identifiers of Mission to be updated
    /// @param _taskIds Identifiers of tasks to be updated
    /// @param _details Docs of a Mission
    /// @param _title Title of a Mission
    /// @dev
    function updateMission(
        uint8 _missionId, 
        uint8[] calldata _taskIds,
        string calldata _details,
        string calldata _title
    ) external payable {
        if (missions[_missionId].taskIds.length == 0) revert InvalidMission();
        
        this.setMission(_taskIds, _details, _title);
    }

    /// @notice Update missions
    /// @param _admin The address to update admin to
    /// @dev
    function updateAdmin(address _admin)
        external
        payable
    {
        if (admin != msg.sender) revert NotAuthorized();

        if (_admin != admin) {
            admin = _admin;
        }

        emit PermissionUpdated(msg.sender, admin, managers);
    }

    /// @notice Update missions
    /// @param _managers The addresses to update managers to
    /// @dev
    function updateManagers(address[] calldata _managers)
        external
        payable
    {
        if (admin != msg.sender) revert NotAuthorized();

        delete managers;

        for (uint8 i = 0 ; i < _managers.length;) {

            if (_managers[i] != address(0)) {
                managers.push(_managers[i]);
                isManager[_managers[i]] = true;
            }

            unchecked {
                ++i;
            }
        }

        emit PermissionUpdated(msg.sender, admin, managers);
    }

    /// -----------------------------------------------------------------------
    /// Getter Functions
    /// -----------------------------------------------------------------------

    function getTaskXp(uint8 _taskId) external view returns (uint8) {
        return tasks[_taskId].xp;
    }

    function getTaskExpiration(uint8 _taskId) external view returns (uint40) {
        return tasks[_taskId].expiration;
    }

    function getTaskCreator(uint8 _taskId) external view returns (address) {
        return tasks[_taskId].creator;
    }

    function getMissionTitle(uint8 _missionId) external view returns (string memory){
        return missions[_missionId].title;
    }

    function getMissionTasks(uint8 _missionId)
        external
        view
        returns (uint8[] memory)
    {
        return missions[_missionId].taskIds;
    }

    function getMissionLength(uint8 _missionId)
        external
        view
        returns (uint256)
    {
        return missions[_missionId].taskIds.length;
    }
}

interface IArm0ryQuests {
    function questNonce(address traveler) external view returns (uint8);

    function activeQuests(address traveler) external view returns (uint8);

    function reviewerXp(address traveler) external view returns (uint8);

    function getQuestMissionId(address traveler, uint8 questId) external view returns (uint8);

    function getQuestXp(address traveler, uint8 questId) external view returns (uint8);

    function getQuestStartTime(address traveler, uint8 questId) external view returns (uint40);

    function getQuestProgress(address traveler, uint8 questId) external view returns (uint8);

    function getQuestReviewXpNeeded(address traveler, uint8 questId) external view returns (uint8);
}

/// @title Arm0ry Quests
/// @notice Quest-to-Earn RPG.
/// @author audsssy.eth

struct Quest {
    uint256 staked;
    uint40 start;
    uint40 duration;
    uint8 missionId;
    uint8 completed;
    uint8 progress;
    uint8 xp;
    uint8 claimed;
}

struct Deliverable {
    uint16 taskId;
    string deliverable;
    bool[] results;
}

contract Arm0ryQuests {
    using SafeTransferLib for address;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event QuestStarted(address indexed traveler, uint8 missionId);
    
    event QuestPaused(address indexed traveler, uint8 questId);

    event QuestResumed(address indexed traveler, uint8 questId);

    event QuestCompleted(address indexed traveler, uint8 questId);

    event TaskSubmitted(address indexed traveler, uint8 questId, uint8 taskId, string indexed homework);

    event TaskReviewed(address indexed reviewer, address indexed traveler, uint8 questId, uint16 taskId, uint8 review);

    event TravelerRewardClaimed(address indexed creator, uint256 amount);

    event CreatorRewardClaimed(address indexed creator, uint256 amount);

    event FastPassUpdated(uint256 amount);

    event ContractsUpdated(IArm0ryTravelers indexed travelers, IArm0ryMission indexed mission);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error NotAuthorized();

    error InvalidTraveler();

    error NothingToClaim();

    error QuestInactive();

    error QuestActive();

    error QuestExpired();

    error InvalidReviewer();

    error InsufficientReviewerXp();

    error InvalidReview();

    error AlreadyReviewed();

    error TaskNotReadyForReview();

    error TaskAlreadyCompleted();

    error AlreadyClaimed();

    error LengthMismatch();

    error NeedMoreCoins();

    /// -----------------------------------------------------------------------
    /// Quest Storage
    /// -----------------------------------------------------------------------

    uint256 public immutable THRESHOLD = 10 * 1e18;
    
    uint256 public fastPass;

    address public arm0ry;

    IArm0ryTravelers public travelers;

    IArm0ryMission public mission;

    // Traveler's history of quests
    mapping(address => mapping(uint256 => Quest)) public quests;

    // Counter indicating Quest count per Traveler
    mapping(address => uint8) public questNonce;

    // Homework per Task of an active Quest
    mapping(address => mapping(uint256 => string)) public taskHomework;

    // Status indicating if a Task of an active Quest is ready for review
    mapping(address => mapping(uint256 => bool)) public taskReadyForReview;

    // Review results of a Task of a Quest
    // 0 - not yet reviewed
    // 1 - reviewed with a check
    // 2 - reviewed with an x
    mapping(address => mapping(uint256 => mapping(address => uint8))) public taskReviews;

    // Xp per reviewer
    mapping(address => uint8) public reviewerXp;

    // Status indicating if a Task of an active Quest is completed
    mapping(address => mapping(uint256 => bool)) public isTaskCompleted;

    // Rewards per creators
    mapping(address => uint256) public taskCreatorRewards;

    // Active quests per Traveler, one active quest per Traveler
    mapping(address => uint8) public activeQuests;

    // Travelers per mission ID
    mapping(uint8 => address[]) public missionTravelers;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        IArm0ryTravelers _travelers,
        IArm0ryMission _mission,
        uint256 _fastPass
    ) {
        travelers = _travelers;
        mission = _mission;
        fastPass = _fastPass;

        emit ContractsUpdated(travelers, mission);
        emit FastPassUpdated(fastPass);
    }

    /// -----------------------------------------------------------------------
    /// Quest Logic
    /// -----------------------------------------------------------------------

    /// @notice Traveler to start a new Quest.
    /// @param missionId Identifier of a Mission.
    /// @dev 
    function startQuest(uint8 missionId)
        external
        payable
    {
        uint256 id = uint256(uint160(msg.sender));
        uint8[] memory _taskIds = mission.missions(missionId).taskIds;

        // Lock Traveler Pass and if Traveler picked a non-BASIC path, 
        // i.e., missionId = 0, Traveler is required to stake token
        if (missionId == 0) {
            travelers.safeTransferFrom(msg.sender, address(this), id);
        } else {
            if (
                IERC20(arm0ry).balanceOf(msg.sender) < THRESHOLD ||
                msg.value >= fastPass
            ) revert NeedMoreCoins();
            IERC20(arm0ry).transferFrom(msg.sender, address(this), THRESHOLD);
            travelers.safeTransferFrom(msg.sender, address(this), id);
        }

        // Initialize tasks review status
        for (uint256 i = 0; i < _taskIds.length; ) {
            taskReadyForReview[msg.sender][_taskIds[i]] = false;

            unchecked {
                ++i;
            }
        }

        // Initialize reviewer xp
        if (questNonce[msg.sender] == 0) {
            reviewerXp[msg.sender] = 5;
        }

        // Record Quest
        quests[msg.sender][questNonce[msg.sender]] = Quest({
            staked: missionId == 0 ? 0 : THRESHOLD,
            start: uint40(block.timestamp),
            duration: mission.missions(missionId).expiration,
            missionId: missionId,
            completed: 0,
            progress: 0,
            xp: 0,
            claimed: 0
        });

        // Record mission participants
        missionTravelers[missionId].push(msg.sender);

        // Mark active quest for Traveler
        activeQuests[msg.sender] = questNonce[msg.sender];
        
        // Update nonce
        unchecked {
            ++questNonce[msg.sender];
        }

        emit QuestStarted(msg.sender, missionId);
    }

    /// @notice Traveler to continue an existing but inactive Quest.
    /// @param questId Identifier of a Quest.
    /// @dev 
    function resumeQuest(uint8 questId) external payable {
        // Confirm Quest has been paused
        uint40 questStart = quests[msg.sender][questId].start;
        if (questStart > 0) revert QuestActive();

        // Confirm Traveler owns Traveler's Pass to prevent double-questing
        if (travelers.balanceOf(msg.sender) == 0) revert InvalidTraveler();

        // Lock Traveler Pass
        uint256 id = uint256(uint160(msg.sender));
        travelers.safeTransferFrom(msg.sender, address(this), id);
        
        // Mark Quest as active
        activeQuests[msg.sender] = questId;

        // Update Quest start time
        quests[msg.sender][questId].start = uint40(block.timestamp);

        emit QuestResumed(msg.sender, questId);
    }

    /// @notice Traveler to pause an active Quest.
    /// @param questId Identifier of a Quest.
    /// @dev 
    function pauseQuest(uint8 questId) external payable {
        // Confirm Quest is active
        if (questId != activeQuests[msg.sender]) revert QuestInactive();

        // Confirm Quest has not expired
        uint40 questStart = quests[msg.sender][questId].start;
        uint40 questDuration = quests[msg.sender][questId].duration;
        if (uint40(block.timestamp) > questStart + questDuration) revert QuestExpired();

        // Use max value to mark Quest as paused
        activeQuests[msg.sender] = type(uint8).max;

        // Return portions of staked token based on tasks completion
        uint8 progress = quests[msg.sender][questId].progress;
        uint8 missionId = quests[msg.sender][questId].missionId;
        if (missionId != 0) {
            uint256 stakeToReturn = THRESHOLD * progress / 100;
            quests[msg.sender][questId].staked -= stakeToReturn;
            IERC20(arm0ry).transfer(msg.sender, stakeToReturn);

            // Update Quest start time and duration
            uint40 diff;
            unchecked { 
                 diff = uint40(block.timestamp) - questStart;
            }
            quests[msg.sender][questId].start = 0;
            quests[msg.sender][questId].duration = diff;
        }

        // Return locked NFT when pausing a Quest
        uint256 id = uint256(uint160(msg.sender));
        travelers.transferFrom(address(this), msg.sender, id);

        emit QuestPaused(msg.sender, questId);
    }

    /// @notice Traveler to submit Homework for Task completion.
    /// @param questId Identifier of a Quest.
    /// @param taskId Identifier of a Task.
    /// @param homework Task homework to turn in.
    /// @dev 
    function submitTasks(
        uint8 questId,
        uint8 taskId,
        string calldata homework
    ) external payable {
        // Confirm Quest is active
        if (questId != activeQuests[msg.sender]) revert QuestInactive();

        // Confirm Task not already completed
        if (isTaskCompleted[msg.sender][taskId]) revert TaskAlreadyCompleted();
        
        // Traveler must have at least 1 reviewer xp
        if (reviewerXp[msg.sender] == 0) revert InsufficientReviewerXp();

        // Confirm Quest has not expired
        uint40 questStart = quests[msg.sender][questId].start;
        uint40 questDuration = quests[msg.sender][questId].duration;
        if (uint40(block.timestamp) > questStart + questDuration) revert QuestExpired();

        // Update Homework
        taskHomework[msg.sender][taskId] = homework;

        // Mark Task ready for review
        taskReadyForReview[msg.sender][taskId] = true;

        emit TaskSubmitted(msg.sender, questId, taskId, homework);
    }

    /// -----------------------------------------------------------------------
    /// Review Functions
    /// -----------------------------------------------------------------------

    /// @notice Reviewer to submit review of task completion.
    /// @param traveler Identifier of a Traveler.
    /// @param questId Identifier of a Quest.
    /// @param taskId Identifier of a Task.
    /// @param review Result of review, i.e., 0, 1, or 2.
    /// @dev 
    function reviewTasks(
        address traveler,
        uint8 questId,
        uint16 taskId,
        uint8 review
    ) external payable {
        // Reviewer must have completed 2 quests
        if (questNonce[msg.sender] < 2) revert InvalidReviewer();

        // Reviewer must provide valid review data
        if (review == 0) revert InvalidReview();

        // Traveler must mark task for review ahead of time
        if (!taskReadyForReview[traveler][taskId]) revert TaskNotReadyForReview();

        // Reviewer must not have already reviewed instant Task
        if (taskReviews[traveler][taskId][msg.sender] != 0) revert AlreadyReviewed();

        // Record review
        taskReviews[traveler][taskId][msg.sender] = review;

        // Update reviewer xp
        reviewerXp[traveler]--;
        reviewerXp[msg.sender]++;

        if (review == 1) {
            // Mark Task completion
            isTaskCompleted[traveler][taskId] = true;
            taskReadyForReview[traveler][taskId] = false;

            // Retrieve to update Task reward
            uint8 xp = mission.getTaskXp(taskId);
            
            // Retrieve to record task creator rewards
            address creator = mission.getTaskCreator(taskId);

            // Retrieve to update Task completion and progress
            uint8 _completed = quests[traveler][questId].completed;
            uint8 missionId = this.getQuestMissionId(traveler, questId);
            uint8 totalTaskCount = uint8(mission.missions(missionId).taskIds.length);

            // cannot possibly overflow
            uint8 progress;
            unchecked { 
                ++_completed;

                // Increment Task completion count
                quests[traveler][questId].completed = _completed;

                // Update Quest progress
                progress = (_completed / totalTaskCount) * 100;
                quests[traveler][questId].progress = progress;

                // Update Task reward
                quests[traveler][questId].xp += xp;

                // Record task creator rewards
                taskCreatorRewards[creator] += xp;
            }

            // Update Quest progress
            if (progress == 100) {
                finalizeQuest(traveler, questId);
            }
        } 

        emit TaskReviewed(msg.sender, traveler, questId, taskId, review);
    }

    /// -----------------------------------------------------------------------
    /// Claim Rewards Functions
    /// -----------------------------------------------------------------------

    /// @notice Task creator to claim rewards.
    /// @dev 
    function claimTravelerReward(uint8 questId) external payable {
        // Retrieve to inspect reward availability
        uint8 earned = quests[msg.sender][questId].xp;
        uint8 claimed = quests[msg.sender][questId].claimed;
        if (earned == 0) revert NothingToClaim();
        if (earned <= claimed) revert NothingToClaim();

        // Calculate reward
        uint8 reward;
        unchecked {
            reward = earned - claimed;
        }

        // Update Quest claim 
        quests[msg.sender][questId].claimed = earned;

        // Mint rewards
        IKaliShareManager(arm0ry).mintShares(msg.sender, reward * 1e18);

        emit TravelerRewardClaimed(msg.sender, reward * 1e18);
    }

    /// @notice Task creator to claim rewards.
    /// @dev 
    function claimCreatorReward() external payable {
        if (taskCreatorRewards[msg.sender] == 0) revert NothingToClaim();

        uint256 reward = taskCreatorRewards[msg.sender];

        taskCreatorRewards[msg.sender] = 0;

        IKaliShareManager(arm0ry).mintShares(msg.sender, reward * 1e18);

        emit CreatorRewardClaimed(msg.sender, reward * 1e18);
    }

    /// -----------------------------------------------------------------------
    /// Arm0ry Functions
    /// -----------------------------------------------------------------------

    /// @notice Update price of lightning pass.
    /// @param _fastPass Amount required to skip BASIC mission.
    /// @dev 
    function updateFastPass(uint256 _fastPass) external payable {
        if (msg.sender != arm0ry) revert NotAuthorized();
        fastPass = _fastPass;

        emit FastPassUpdated(fastPass);
    }

    /// @notice Update Arm0ry contracts.
    /// @param _travelers Contract address of Arm0ryTraveler.sol.
    /// @param _mission Contract address of Arm0ryMission.sol.
    /// @dev 
    function updateContracts(IArm0ryTravelers _travelers, IArm0ryMission _mission) external payable {
        if (msg.sender != arm0ry) revert NotAuthorized();
        travelers = _travelers;
        mission = _mission;

        emit ContractsUpdated(travelers, mission);
    }

    function updateReviewerXp(address reviewer) external payable {

    }

    /// -----------------------------------------------------------------------
    /// Getter Functions
    /// -----------------------------------------------------------------------

    function getQuestMissionId(address _traveler, uint8 _questId) external view returns (uint8) {
        return quests[_traveler][_questId].missionId;
    }

    function getQuestXp(address _traveler, uint8 _questId) external view returns (uint8) {
        return quests[_traveler][_questId].xp;
    }

    function getQuestStartTime(address _traveler, uint8 _questId) external view returns (uint40) {
        return quests[_traveler][_questId].start;
    }
    
    function getQuestProgress(address _traveler, uint8 _questId) external view returns (uint8) {
        return quests[_traveler][_questId].progress;
    }

    function getQuestReviewXpNeeded(address _traveler, uint8 _questId) external view returns (uint8) {
        uint8 progress = quests[_traveler][_questId].progress;
        uint8 missionId = quests[_traveler][_questId].missionId;
        uint8 totalTaskCount = uint8(mission.missions(missionId).taskIds.length);
        uint8 reviewerXpCurrent = reviewerXp[_traveler];
        uint8 reviewerXpRequired = totalTaskCount * (100 - progress) / 100;

        uint8 reviewerXpNeeded;
        
        // cannot possibly overflow
        unchecked {
            reviewerXpNeeded = (reviewerXpCurrent >= reviewerXpRequired) ? 0 : reviewerXpRequired - reviewerXpCurrent;
        } 

        return reviewerXpNeeded;
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    function finalizeQuest(address traveler, uint8 questId) internal {
        // Return locked NFT & arm0ry token
        uint256 staked = quests[traveler][questId].staked;
        uint8 missionId = quests[traveler][questId].missionId;
        
        // Return any staked amount
        if (missionId != 0) {
            IERC20(arm0ry).transfer(traveler, staked);
        }

        // Return Traveler NFT
        travelers.transferFrom(
            address(this),
            traveler,
            uint256(uint160(traveler))
        );

        // Mark Quest inactive
        quests[traveler][questId].start = 0;
        activeQuests[msg.sender] = type(uint8).max;

        emit QuestCompleted(traveler, questId);
    }
}