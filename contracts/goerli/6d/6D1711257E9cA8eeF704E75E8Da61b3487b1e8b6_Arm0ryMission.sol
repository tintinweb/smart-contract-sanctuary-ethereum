/**
 *Submitted for verification at Etherscan.io on 2023-02-03
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
        address traveler = address(uint160(tokenId));
        uint8 nonce = this.getQuestNonce(traveler);
        string memory title = this.getMissionTitle(traveler, nonce);

        bytes memory hash = abi.encodePacked(bytes32(tokenId));
        uint256 pIndex = toUint8(hash, 0) / 16; // 16 palettes

        string memory paletteSection = generatePaletteSection(tokenId, pIndex);

        return
            string(
                abi.encodePacked(
                    '<svg class="svgBody" width="300" height="300" viewBox="0 0 300 300" xmlns="http://www.w3.org/2000/svg">',
                    paletteSection,
                    '<text x="20" y="120" class="score" stroke="black" stroke-width="2">',Strings.toString(quests.getQuestProgress(traveler, nonce)),'</text>',
                    '<text x="112" y="120" class="tiny" stroke="black">% Progress</text>',
                    '<text x="180" y="120" class="score" stroke="black" stroke-width="2">',Strings.toString(quests.getQuestXp(traveler, nonce)),'</text>',
                    '<text x="272" y="120" class="tiny" stroke="black">Xp</text>',
                    '<text x="15" y="170" class="medium" stroke="black">QUEST: </text>',
                    '<rect x="15" y="175" width="205" height="40" style="fill:white;opacity:0.5"/>',
                    '<text x="20" y="190" class="medium" stroke="black">',title,'</text>',
                    '<text x="15" y="245" class="small" stroke="black">BUDDIES:</text>',
                    '<text x="15" y="260" style="font-size:8px" stroke="black">',addressToHexString(quests.getQuestBuddyOne(traveler, nonce)),'</text>',
                    '<text x="15" y="275" style="font-size:8px" stroke="black">',addressToHexString(quests.getQuestBuddyTwo(traveler, nonce)),'</text>',
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

    function getQuestNonce(address traveler) external view returns (uint8) {
        return quests.questNonce(traveler);
    }

    function getMissionTitle(address traveler, uint8 nonce) external view returns (string memory) {
        uint8 missionId = quests.getQuestMissionId(traveler, nonce);

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
}

/// @title Arm0ry tasks
/// @notice A list of tasks.
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

    /// -----------------------------------------------------------------------
    /// Task Storage
    /// -----------------------------------------------------------------------

    address public admin;

    address[] public managers;

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

    function setMission(
        uint8 _missionId,
        uint8[] calldata _taskIds,
        string calldata _details,
        string calldata _title
    ) external payable {
        if (msg.sender != admin && !isManager[msg.sender])
            revert NotAuthorized();

        if (_missionId == 0) {
            missions[_missionId] = Mission({
                expiration: 2524626000, // 01/01/2050
                taskIds: _taskIds,
                details: _details,
                title: _title
            });
        } else {
            uint40 expiration;
            for (uint256 i = 0; i < _taskIds.length; ) {
                // Calculate expiration
                uint40 _expiration = this.getTaskExpiration(_taskIds[i]);
                expiration = (_expiration > expiration)
                    ? _expiration
                    : expiration;

                // Update task status
                isTaskInMission[_missionId][_taskIds[i]] = true;

                // cannot possibly overflow
                unchecked {
                    ++i;
                }
            }

            missions[_missionId] = Mission({
                expiration: expiration,
                taskIds: _taskIds,
                details: _details,
                title: _title
            });
        }

        emit MissionSet(_missionId, _taskIds, _details);
    }

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
}

interface IArm0ryQuests {
    function questNonce(address traveler) external view returns (uint8);

    function getQuestMissionId(address traveler, uint8 questId) external view returns (uint8);

    function getQuestXp(address traveler, uint8 questId) external view returns (uint8);

    function getQuestExpiration(address traveler, uint8 questId) external view returns (uint40);

    function getQuestProgress(address traveler, uint8 questId) external view returns (uint8);

    function getQuestBuddyOne(address traveler, uint8 questId) external view returns (address);

    function getQuestBuddyTwo(address traveler, uint8 questId) external view returns (address);
}

/// @title Arm0ry Quests
/// @notice .
/// @author audsssy.eth

enum Status {
    ACTIVE,
    INACTIVE
}

struct Quest {
    Status status;
    uint8 progress;
    uint8 xp;
    address[2] buddies;
    uint8 missionId;
    uint40 expiration;
    uint256 claimed;
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

    event QuestCancelled(address indexed traveler, uint8 missionId);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error NotAuthorized();

    error InvalidTraveler();

    error InvalidClaim();

    error InactiveQuest();

    error ActiveQuest();

    error InvalidBuddy();

    error InvalidReview();

    error TaskNotReadyForReview();

    error TaskNotActive();

    error IncompleteTask();

    error AlreadyClaimed();

    error LengthMismatch();

    error NeedMoreCoins();

    /// -----------------------------------------------------------------------
    /// Quest Storage

    uint256 public immutable THRESHOLD = 10 * 1e18;
    
    uint256 public lightningPass;

    address public arm0ry;

    IArm0ryTravelers public travelers;

    IArm0ryMission public mission;

    // Traveler's history of quests
    mapping(address => mapping(uint256 => Quest)) public quests;

    // Counter indicating Quest count per Traveler
    mapping(address => uint8) public questNonce;

    // Status indicating if an address belongs to a Buddy of an active Quest
    mapping(address => mapping(address => bool)) public isQuestBuddy;

    // Deliverable per Task of an active Quest
    mapping(address => mapping(uint256 => string)) public taskDeliverables;

    // Status indicating if a Task of an active Quest is ready for review
    mapping(address => mapping(uint256 => bool)) public taskReadyForReview;

    // Review results of a Task of an active Quest
    // 0 - not yet reviewed
    // 1 - reviewed with a check
    // 2 - reviewed with an x
    mapping(address => mapping(uint256 => mapping(address => uint8))) taskReviews;

    // Status indicating if a Task of an active Quest is completed
    mapping(address => mapping(uint256 => bool)) isTaskCompleted;

    // Rewards per creators
    mapping(address => uint256) taskCreatorRewards;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(
        IArm0ryTravelers _travelers,
        IArm0ryMission _mission,
        uint256 _lightningPass
    ) {
        travelers = _travelers;
        mission = _mission;
        lightningPass = _lightningPass;
    }

    /// -----------------------------------------------------------------------
    /// Quest Logic
    /// -----------------------------------------------------------------------

    function startQuest(address[2] calldata buddies, uint8 missionId)
        external
        payable
    {
        if (travelers.balanceOf(msg.sender) == 0) revert InvalidTraveler();
        uint256 id = uint256(uint160(msg.sender));
        uint8[] memory _taskIds = mission.missions(missionId).taskIds;
        uint40 _expiration = mission.missions(missionId).expiration;

        // Lock Traveler's NFT
        if (missionId == 0) {
            travelers.transferFrom(msg.sender, address(this), id);
        } else {
            if (
                IERC20(arm0ry).balanceOf(msg.sender) < THRESHOLD ||
                msg.value >= lightningPass
            ) revert NeedMoreCoins();
            IERC20(arm0ry).transferFrom(msg.sender, address(this), THRESHOLD);
            travelers.transferFrom(msg.sender, address(this), id);
        }

        // Update tasks review status
        for (uint256 i = 0; i < _taskIds.length; ) {
            taskReadyForReview[msg.sender][_taskIds[i]] = false;

            unchecked {
                ++i;
            }
        }

        // Update buddies
        bool haveBuddies;
        for (uint256 i = 0; i < buddies.length; ) {
            if (buddies[i] == address(0)) {
                haveBuddies = false;
            }

            haveBuddies = true;
            isQuestBuddy[msg.sender][buddies[i]] = true;

            unchecked {
                ++i;
            }
        }

        // Create a Quest
        quests[msg.sender][questNonce[msg.sender]] = Quest({
            status: Status.ACTIVE,
            progress: 0,
            xp: 0,
            buddies: haveBuddies ? buddies : [arm0ry, address(0)],
            missionId: missionId,
            expiration: _expiration,
            claimed: 0
        });

        // Cannot possibly overflow.
        unchecked {
            ++questNonce[msg.sender];
        }
    }

    function continueQuest(uint8 _missionId) external payable {
        if (travelers.balanceOf(msg.sender) == 0) revert InvalidTraveler();
        if (quests[msg.sender][_missionId].status == Status.ACTIVE)
            revert ActiveQuest();

        // Mark Quest as active
        quests[msg.sender][_missionId].status = Status.ACTIVE;
    }

    function leaveQuest(uint8 _missionId) external payable {
        uint256 id = uint256(uint160(msg.sender));
        if (travelers.ownerOf(id) != address(this)) revert InvalidTraveler();
        if (quests[msg.sender][_missionId].status == Status.INACTIVE)
            revert InactiveQuest();

        // Mark Quest as inactive
        quests[msg.sender][_missionId].status = Status.INACTIVE;

        // Airdrop any unclaimed rewards
        uint8 reward = quests[msg.sender][_missionId].xp;
        if (reward != 0) {
            IERC20(arm0ry).transfer(msg.sender, reward * 1e18);
            quests[msg.sender][_missionId].claimed += reward;
        }

        // Return locked NFT & arm0ry token when cancelling a Quest
        if (questNonce[msg.sender] != 0) {
            IERC20(arm0ry).transfer(msg.sender, THRESHOLD);
        }
        travelers.transferFrom(address(this), msg.sender, id);

        emit QuestCancelled(msg.sender, _missionId);
    }

    function updateBuddies(uint8 _missionId, address[2] calldata newBuddies)
        external
        payable
    {
        uint256 id = uint256(uint160(msg.sender));
        if (travelers.ownerOf(id) != address(this)) revert InvalidTraveler();

        // Remove previous buddies
        for (uint256 i = 0; i < 2; ) {
            address buddy = quests[msg.sender][_missionId].buddies[i];
            isQuestBuddy[msg.sender][buddy] = false;

            unchecked {
                ++i;
            }
        }

        // Add new buddies
        for (uint256 i = 0; i < 2; ) {
            isQuestBuddy[msg.sender][newBuddies[i]] = true;

            unchecked {
                ++i;
            }
        }

        quests[msg.sender][_missionId].buddies = newBuddies;
    }

    function submitTasks(
        uint8 _missionId,
        uint8 _taskId,
        string calldata deliverable
    ) external payable {
        uint256 id = uint256(uint160(msg.sender));
        if (travelers.ownerOf(id) != address(this)) revert InvalidTraveler();
        if (!mission.isTaskInMission(_missionId, _taskId))
            revert TaskNotActive();
        if (!isTaskCompleted[msg.sender][_taskId]) revert IncompleteTask();
        if (quests[msg.sender][_missionId].status == Status.INACTIVE)
            revert InactiveQuest();

        taskDeliverables[msg.sender][_taskId] = deliverable;
        taskReadyForReview[msg.sender][_taskId] = true;
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

    function getQuestExpiration(address _traveler, uint8 _questId) external view returns (uint40) {
        return quests[_traveler][_questId].expiration;
    }
    
    function getQuestProgress(address _traveler, uint8 _questId) external view returns (uint8) {
        return quests[_traveler][_questId].progress;
    }

    function getQuestBuddyOne(address _traveler, uint8 _questId) external view returns(address) {
        return quests[_traveler][_questId].buddies[0];    
    }

    function getQuestBuddyTwo(address _traveler, uint8 _questId) external view returns(address) {
        return quests[_traveler][_questId].buddies[1];
            
    }

    /// -----------------------------------------------------------------------
    /// Arm0ry Functions
    /// -----------------------------------------------------------------------

    function updatePass(uint256 _lightningPass) external payable {
        if (msg.sender != arm0ry) revert NotAuthorized();
        lightningPass = _lightningPass;
    }

    function updateContracts(IArm0ryTravelers _travelers, IArm0ryMission _mission) external payable {
        if (msg.sender != arm0ry) revert NotAuthorized();
        travelers = _travelers;
        mission = _mission;
    }

    /// -----------------------------------------------------------------------
    /// Reward Functions
    /// -----------------------------------------------------------------------

    function claimCreatorReward() external payable {
        if (taskCreatorRewards[msg.sender] == 0) revert InvalidClaim();

        uint256 reward = taskCreatorRewards[msg.sender];

        taskCreatorRewards[msg.sender] = 0;

        IKaliShareManager(arm0ry).mintShares(msg.sender, reward * 1e18);
    }

    /// -----------------------------------------------------------------------
    /// Review Functions
    /// -----------------------------------------------------------------------

    function reviewTasks(
        address traveler,
        uint16 taskId,
        uint8 review
    ) external payable {
        if (!isQuestBuddy[traveler][msg.sender]) revert InvalidBuddy();
        if (!taskReadyForReview[msg.sender][taskId])
            revert TaskNotReadyForReview();
        if (review == 0) revert InvalidReview();

        taskReviews[traveler][taskId][msg.sender] = review;

        Quest memory quest = quests[traveler][questNonce[traveler]];
        address[2] memory buddies = quest.buddies;
        bool check;

        if (review == 1) {
            for (uint256 i = 0; i < 2; ) {
                if (buddies[i] == msg.sender) {
                    continue;
                }

                if (taskReviews[traveler][taskId][buddies[i]] != 1) {
                    check = false;
                    break;
                }

                check = true;

                // cannot possibly overflow in array loop
                unchecked {
                    ++i;
                }
            }
        }

        if (check) {
            isTaskCompleted[msg.sender][taskId] = true;
            taskReadyForReview[traveler][taskId] = false;

            updateQuestProgress(traveler);

            uint8 xp = mission.getTaskXp(taskId);

            // Record task creator rewards
            address creator = mission.getTaskCreator(taskId);
            taskCreatorRewards[creator] += xp;

            // Distribute task rewards
            IKaliShareManager(arm0ry).mintShares(traveler, xp * 1e18);
        }
    }

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    function updateQuestProgress(address traveler) internal {
        uint8[] memory _taskIds = mission
            .missions(uint8(questNonce[traveler]))
            .taskIds;

        uint8 completedTasksCount;
        uint8 incompleteTasksCount;
        uint8 progress;
        uint8 xpEarned;

        for (uint256 i = 0; i < _taskIds.length; ) {
            uint8 xp = mission.getTaskXp(_taskIds[i]);

            if (!isTaskCompleted[traveler][_taskIds[i]]) {
                // cannot possibly overflow
                unchecked {
                    ++incompleteTasksCount;
                }
            } else {
                // cannot possibly overflow
                unchecked {
                    ++completedTasksCount;
                    xpEarned += xp;
                }
            }

            // cannot possibly overflow in array loop
            unchecked {
                ++i;
            }
        }

        // cannot possibly overflow
        unchecked {
            progress =
                (completedTasksCount /
                    (completedTasksCount + incompleteTasksCount)) *
                100;
        }

        // Update progress and xp
        quests[msg.sender][questNonce[msg.sender]].progress = progress;
        quests[msg.sender][questNonce[msg.sender]].xp = xpEarned;

        uint256 claimed = quests[msg.sender][questNonce[msg.sender]].claimed;
        uint256 reward = (xpEarned - claimed) * 1e18;
        // Return locked NFT & arm0ry token when Quest is completed
        if (progress == 100) {
            if (questNonce[traveler] != 0) {
                IERC20(arm0ry).transfer(traveler, THRESHOLD);
            }

            IERC20(arm0ry).transfer(traveler, reward);
            travelers.transferFrom(
                address(this),
                traveler,
                uint256(uint160(traveler))
            );
        }
    }
}