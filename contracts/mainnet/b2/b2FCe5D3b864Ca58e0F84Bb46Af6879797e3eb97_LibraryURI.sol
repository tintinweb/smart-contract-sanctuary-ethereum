/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

pragma solidity ^0.8.17;

//       ___           ___                       ___                    ___           ___           ___           ___
//      /\  \         |\__\          ___        /\  \                  /\__\         /\__\         /\__\         /\  \          ___
//     /::\  \        |:|  |        /\  \      /::\  \                /::|  |       /:/  /        /::|  |       /::\  \        /\  \
//    /:/\:\  \       |:|  |        \:\  \    /:/\ \  \              /:|:|  |      /:/  /        /:|:|  |      /:/\:\  \       \:\  \
//   /::\~\:\  \      |:|__|__      /::\__\  _\:\~\ \  \            /:/|:|__|__   /:/  /  ___   /:/|:|  |__   /:/  \:\__\      /::\__\
//  /:/\:\ \:\__\ ____/::::\__\  __/:/\/__/ /\ \:\ \ \__\          /:/ |::::\__\ /:/__/  /\__\ /:/ |:| /\__\ /:/__/ \:|__|  __/:/\/__/
//  \/__\:\/:/  / \::::/~~/~    /\/:/  /    \:\ \:\ \/__/          \/__/~~/:/  / \:\  \ /:/  / \/__|:|/:/  / \:\  \ /:/  / /\/:/  /
//       \::/  /   ~~|:|~~|     \::/__/      \:\ \:\__\                  /:/  /   \:\  /:/  /      |:/:/  /   \:\  /:/  /  \::/__/
//       /:/  /      |:|  |      \:\__\       \:\/:/  /                 /:/  /     \:\/:/  /       |::/  /     \:\/:/  /    \:\__\
//      /:/  /       |:|  |       \/__/        \::/  /                 /:/  /       \::/  /        /:/  /       \::/__/      \/__/
//      \/__/         \|__|                     \/__/                  \/__/         \/__/         \/__/         ~~


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

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

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// Ownable From OpenZeppelin Contracts v4.4.1 (Ownable.sol)

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(msg.sender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
}

/// @title ERC721 Library
/// @notice ERC721 library-bound tokens with lore permanently stored on-chain
/// @author Mauro

struct HeroLore {
    address fullLore; //option to enter the loreOnChain
    bytes32 name;
    uint8 loreType;
    uint8 loreExtra;
}

contract LibraryURI {
    function constructURI(uint256 tokenId, HeroLore calldata lore)
        public
        view
        returns (string memory)
    {
        bytes memory temp = SSTORE2.read(lore.fullLore);

        uint256 loreLength = temp.length;

        // max characters per line
        uint256 maxLineLength = 112;

        string
            memory output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 1000 1200"><style>.base { fill: black; font-family: monospace; font-size: 14px; }</style>';

        // check standard lore or librarian lore to decide BG colour
        string memory currentName;
        if (lore.loreType == 0) {
            output = string(
                abi.encodePacked(
                    output,
                    '<rect width="100%" height="100%" fill="#f1eee8" />'
                )
            );
            currentName = string(
                abi.encodePacked(
                    '"Hero #',
                    toString(tokenId),
                    " - ",
                    bytes32ToString(lore.name)
                )
            );
        } else {
            output = string(
                abi.encodePacked(
                    output,
                    '<rect width="100%" height="100%" fill="#f5bd04" />'
                )
            );
            currentName = string(
                abi.encodePacked(
                    '"',
                    bytes32ToString(lore.name)
                )
            );
        }

        uint256 offset = 60;

        output = string(
            abi.encodePacked(
                output,
                '<text text-anchor="middle" x="500" y="',
                toString(offset),
                '" class="base">'
            )
        );

        uint256 currentLineNr = 0;
        uint256 lineIdx = 0;
        uint256 lineStart = 0;

        bytes memory currentLine = new bytes(maxLineLength);

        for (uint256 l = 1; l <= loreLength; l++) {
            currentLine[lineIdx] = temp[l - 1];
            lineIdx++;

            // if(((l - lineStart) >= maxLineLength - 15 && bytes1(temp[l-1]) == 0x20) || l == loreLength || bytes1(temp[l-1]) == 0x0a) { //0x0a is \n
            if (
                (l - lineStart) == maxLineLength ||
                l == loreLength ||
                bytes1(temp[l - 1]) == 0x0a
            ) {
                //0x0a is \n
                // if(l == loreLength || bytes1(temp[l-1]) == 0x0a) { //0x0a is \n
                uint256 thisLength = l - lineStart;

                // if(temp[l-1] == "/") {
                //     thisLength--;
                // }

                assembly {
                    mstore(currentLine, thisLength)
                }

                lineStart = l;
                output = string(
                    abi.encodePacked(output, string(currentLine), "</text>")
                );
                currentLineNr++;
                offset = currentLineNr * 24 + 60;
                output = string(
                    abi.encodePacked(
                        output,
                        '<text text-anchor="middle" x="500" y="',
                        toString(offset),
                        '" class="base">'
                    )
                );
                lineIdx = 0;
                // if(loreLength - l < maxLineLength) {
                //     currentLine = new bytes(loreLength - l);
                // }
                // else {
                //     currentLine = new bytes(maxLineLength);
                // }
                currentLine = new bytes(maxLineLength);
            }
        }

        //end of last line
        output = string(abi.encodePacked(output, "</text>"));

        output = string(abi.encodePacked(output, "</svg>"));

        //create metadata JSON and encode base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": ',
                        currentName,
                        '", "description": "Lore entry stored in Axis Mundi, the World Tree library, a 1/1 NFT by toomuchlag.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    // converts uint to string
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
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

    // converts bytes32 to string
    function bytes32ToString(bytes32 data)
        internal
        pure
        returns (string memory)
    {
        uint256 i = 0;
        while (i < 32 && uint8(data[i]) != 0) {
            ++i;
        }
        bytes memory result = new bytes(i);
        i = 0;
        while (i < 32 && data[i] != 0) {
            result[i] = data[i];
            ++i;
        }
        return string(result);
    }
}

contract TheLibrary is Ownable {

    //////////////////
    // EVENTS
    //////////////////

    // Events ERC721
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Events Library
    event LoreUpdated(uint256 indexed heroId, address newLoreData);

    //////////////////
    // STORAGE
    //////////////////

    // main Superare NFT
    address public constant SUPERRARE =
        0xb932a70A57673d89f4acfFBE830E8ed7f75Fb9e0;
    uint256 public constant LIBRARY_ID = 39020;

    // Le Anime WRAPPER contract
    address public constant WRAPPER =
        0x03BEbcf3D62C1e7465f8a095BFA08a79CA2892A1;

    // NFT contract metadata
    string public name;

    string public symbol;

    // Mapping heroId to Lore
    mapping(uint256 => HeroLore) public loreAndName;

    // library URI contract
    address public customURI;

    // library extension
    address public extension;

    // freeze library
    bool public frozen;

    // Mapping owner address to token count - only one owner allowed: this contract
    uint256 private _balance;

    constructor() {
        name = "Axis Mundi";
        symbol = "AXM";

        customURI = address(new LibraryURI());
    }

    //////////////////
    // MODIFIERS
    //////////////////

    modifier onlyLibrarian() {
        _checkLibrarian();
        _;
    }

    function _checkLibrarian() internal view virtual {
        require(
            IERC721(SUPERRARE).ownerOf(LIBRARY_ID) == msg.sender,
            "Not the librarian"
        );
    }

    //////////////////
    // ERC165
    //////////////////

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 = 0x01ffc9a7
            interfaceId == 0x80ac58cd || // ERC721 = 0x80ac58cd
            interfaceId == 0x5b5e139f; // ERC721 Metadata = 0x5b5e139f
    }

    //////////////////
    // ERC721
    //////////////////

    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        if (owner == address(this)) {
            return _balance;
        } else {
            return 0;
        }
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return address(this);
    }

    function approve(address to, uint256 tokenId) public {
        revert();
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return address(0);
    }

    function setApprovalForAll(address operator, bool approved) public {
        revert();
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        returns (bool)
    {
        return false;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        revert();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        revert();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        revert();
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return loreAndName[tokenId].fullLore != address(0);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");

        _balance += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        _balance -= 1;
        delete loreAndName[tokenId];
        emit Transfer(address(this), address(0), tokenId);
    }

    //////////////////
    // URI SECTION
    //////////////////

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            LibraryURI(customURI).constructURI(tokenId, loreAndName[tokenId]);
    }

    function setCustomURI(address contractURI) public onlyOwner {
        customURI = contractURI;
    }

    //////////////////
    // LIBRARY ANIME HOLDERS FUNCTIONS
    //////////////////

    function storeLoreAndNameSSTORE(
        uint256 heroId,
        string calldata newName,
        bytes calldata loreData
    ) public {
        require(
            IERC721(WRAPPER).ownerOf(heroId + 100000) == msg.sender,
            "Not the owner"
        );
        require(!frozen, "Library closed");

        if (!_exists(heroId)) {
            _mint(address(this), heroId);
        }

        loreAndName[heroId].name = bytes32(abi.encodePacked(newName));

        address newLore = SSTORE2.write(loreData);
        loreAndName[heroId].fullLore = newLore;

        emit LoreUpdated(heroId, newLore);
    }
    
    function changeName(uint256 heroId, string calldata newName) public {
        require(
            IERC721(WRAPPER).ownerOf(heroId + 100000) == msg.sender,
            "Not the owner"
        );
        require(!frozen, "Library closed");
        loreAndName[heroId].name = bytes32(abi.encodePacked(newName));
    }

    //////////////////
    // LIBRARIAN FUNCTIONS
    //////////////////

    
    function storeLibrarianLore(bytes calldata loreData) public onlyLibrarian {
        if (!_exists(0)) {
            _mint(address(this), 0);
        }
        loreAndName[0].name = "Librarian's Lore";

        address librarianData = SSTORE2.write(loreData);
        loreAndName[0].fullLore = librarianData;

        loreAndName[0].loreType = 1;

        emit LoreUpdated(0, librarianData);
    }
    
    function freezeLibrary(bool newState) public onlyLibrarian {
        frozen = newState;
    }

    //////////////////
    // LIBRARY ORIGIN LORE SETUP
    //////////////////

    function mintBatch(uint256[] calldata tokenId) public onlyOwner {
        for (uint256 i = 0; i < tokenId.length; i++) {
            emit Transfer(address(0), address(this), tokenId[i]);
        }
        _balance += tokenId.length;
    }

    function burnBatch(uint256[] calldata tokenId) public onlyOwner {
        for (uint256 i = 0; i < tokenId.length; i++) {
            _burn(tokenId[i]);   
        }
    }

    function storeFullLoreBatch(
        uint256[] calldata tokenId,
        string[] calldata newName,
        bytes[] calldata loreData
    ) public onlyOwner {
        for (uint256 i = 0; i < tokenId.length; i++) {
            loreAndName[tokenId[i]].name = bytes32(
                abi.encodePacked(newName[i])
            );

            address newLore = SSTORE2.write(loreData[i]);
            loreAndName[tokenId[i]].fullLore = newLore;

            emit LoreUpdated(tokenId[i], newLore);
        }
    }

    //////////////////
    // LIBRARY EXTENSION
    //////////////////

    function setExtension(address extension_) public onlyOwner {
        extension = extension_;
    }

    function burnBatchExtension(uint256[] calldata tokenId) public {
        require(extension == msg.sender, "Not allowed");

        for (uint256 i = 0; i < tokenId.length; i++) {
            if (_exists(tokenId[i])) {
                _burn(tokenId[i]);
            }
        }
        
    }

    function storeFullLoreBatchExtension(
        uint256[] calldata tokenId,
        HeroLore[] calldata lores
    ) public {
        require(extension == msg.sender, "Not allowed");

        for (uint256 i = 0; i < tokenId.length; i++) {
            if (!_exists(tokenId[i])) {
                _mint(address(this), tokenId[i]);
            }

            loreAndName[tokenId[i]] = lores[i];

            emit LoreUpdated(tokenId[i], lores[i].fullLore);
        }
    }
}