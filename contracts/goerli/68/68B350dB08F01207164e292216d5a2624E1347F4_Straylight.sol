//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./metadata.sol";
import "./EnumerableMate.sol";

contract Straylight is EnumerableMate, Metadata {
    //need Mintevent that has board id and agent type
    event turmiteReprogramm(uint256 indexed tokenId, bytes12 indexed newrule);
    event turmiteMint(uint256 indexed tokenId, bytes12 indexed rule, uint256 boardId);

    uint256 public constant mint_price = 80000000000000000 wei;
    uint256 public boardcounter = 0;
    uint256 private turmitecounter = 0;
    uint256 private maxnumbturmites = 1024;
    uint256[4] startx = [36, 72, 72, 108];
    uint256[4] starty = [72, 36, 108, 72];
    address minterContract;

    constructor(address _minterContract) EnumerableMate("Straylight", "STR") {
        minterContract = _minterContract;
    }

    function publicmint(bytes12 rule, uint256 moves) external {
        require(turmitecounter < maxnumbturmites, "MINT_OVER");
        require(validateNewRule(rule) == true, "INVALID_RULE");
        require(msg.sender == minterContract, "ONLY_MINTABLE_FROM_MINT_CONTRACT");

        boardcounter = turmitecounter / 4;
        uint256 startposx = startx[turmitecounter % 4];
        uint256 startposy = starty[turmitecounter % 4];
        _addTokenToOwnerEnumeration(tx.origin, turmitecounter);
        _addTokenToAllTokensEnumeration(turmitecounter);
        _mint(tx.origin, turmitecounter);
        createTurmite(turmitecounter, uint8(startposx), uint8(startposy), 1, uint8(boardcounter), rule);
        emit turmiteMint(turmitecounter, rule, boardcounter);
        getDirectionTurmite(turmitecounter, moves);
        turmitecounter = turmitecounter + 1;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            fullMetadata(
                id,
                turmites[id].boardnumber,
                turmites[id].rule,
                turmites[id].state,
                turmites[id].turposx,
                turmites[id].turposy,
                turmites[id].orientation
            );
    }

    function renderBoard(uint8 number) public view returns (string memory) {
        return getSvg(number, 0, 0, false);
    }

    function moveTurmite(uint256 id, uint256 moves) external {
        require(msg.sender == ownerOf(id), "NOT_AUTHORIZED");
        getDirectionTurmite(id, moves);
    }

    function validateNewRule(bytes12 rule) public pure returns (bool allowed) {
        //Normal Format: 0xff0801ff0201ff0000000001
        //we dont test against direction bc direction never writes
        //bool firstbit = (rule[0] == 0xFF || rule[0] == 0x00);
        //bool secondbit = (rule[3] == 0xFF || rule[3] == 0x00);
        bool colorfieldbit = ((rule[0] == 0xFF || rule[0] == 0x00) &&
            (rule[3] == 0xFF || rule[3] == 0x00) &&
            (rule[6] == 0xFF || rule[6] == 0x00) &&
            (rule[9] == 0xFF || rule[9] == 0x00));
        bool statebit = ((rule[2] == 0x01 || rule[2] == 0x00) &&
            (rule[5] == 0x01 || rule[5] == 0x00) &&
            (rule[8] == 0x01 || rule[8] == 0x00) &&
            (rule[11] == 0x01 || rule[11] == 0x00));
        return bool(statebit && colorfieldbit);
    }

    function reprogrammTurmite(uint256 id, bytes12 rule) external {
        require(msg.sender == ownerOf(id), "NOT_AUTHORIZED");
        require(validateNewRule(rule) == true, "INVALID_RULE");
        turmites[id].rule = rule;
        emit turmiteReprogramm(id, rule);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./turmitev4.sol";

contract Metadata is Turmite {
    function fullMetadata(
        uint256 tokenId,
        uint8 boardNumber,
        bytes12 rule,
        bytes1 state,
        uint8 turposx,
        uint8 turposy,
        uint8 orientation
    ) internal view returns (string memory) {
        //string memory name = generateName(tokenId, boardNumber);
        //string memory description = "On-chain generative turingcomplete ERC721 Turmite Multiverse";
        //string memory image = getSvg(boardNumber, turposx, turposy, true);
        //string memory attributes = generateAttributes(boardNumber, rule, state, turposx, turposy, orientation);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            //"data:text/plain,"
                            //"data:application/json,"
                            '{"name":"',
                            generateName(tokenId, boardNumber),
                            '", "description":"',
                            "On-chain generative turingcomplete ERC721 Turmite Multiverse",
                            '", "image": "',
                            getSvg(boardNumber, turposx, turposy, true),
                            '",',
                            '"attributes": ',
                            generateAttributes(boardNumber, rule, state, turposx, turposy, orientation),
                            "}"
                        )
                    )
                )
            );
    }

    function generateName(uint256 tokenId, uint8 boardNumber) internal pure returns (string memory) {
        return
            string(abi.encodePacked("Turmite ", Strings.toString(tokenId), " World ", Strings.toString(boardNumber)));
    }

    function generateAttributes(
        uint8 boardNumber,
        bytes12 rule,
        bytes1 state,
        uint8 turposx,
        uint8 turposy,
        uint8 orientation
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    '{"trait_type":"Board / World",',
                    '"value":"',
                    Strings.toString(boardNumber),
                    '"},',
                    '{"trait_type":"Ruleset",',
                    '"value":"',
                    bytes12ToString(rule),
                    '"},',
                    '{"trait_type":"State",',
                    '"value":"',
                    bytes1ToString(state),
                    '"},',
                    '{"trait_type":"POS X",',
                    '"value":"',
                    Strings.toString(turposx),
                    '"},',
                    '{"trait_type":"POS Y",',
                    '"value":"',
                    Strings.toString(turposy),
                    '"},',
                    '{"trait_type":"Direction",',
                    '"value":"',
                    Strings.toString(orientation),
                    '"}',
                    "]"
                )
            );
    }

    function bytes1ToString(bytes1 _bytes1) internal pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(2);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes1[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes1[i / 2] >> 4);

            bytesArray[i] = toByte(_l);
            i = i + 1;
            bytesArray[i] = toByte(_f);
        }
        return string(bytesArray);
    }

    function bytes12ToString(bytes12 _bytes12) internal pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(24);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes12[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes12[i / 2] >> 4);

            bytesArray[i] = toByte(_l);
            i = i + 1;
            bytesArray[i] = toByte(_f);
        }
        return string(bytesArray);
    }

    function toByte(uint8 _uint8) internal pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@rari-capital/solmate/src/tokens/ERC721.sol";

// This is a slightly reduced version of ERC721Enumerable.sol - mainly optimizing the transfer function

abstract contract EnumerableMate is ERC721 {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    constructor(string memory name, string memory s) ERC721(name, s) {}

    /// getter
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < EnumerableMate.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) internal {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) internal {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) internal {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) internal {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];
        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
        super.transferFrom(from, to, tokenId);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./gameboard.sol";
// import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Turmite is Gameboard {
    using Base64 for string;

    mapping(uint256 => turmite) public turmites;

    event turmiteMove(uint256 indexed tokenId, uint8 indexed boardnumber);

    // THIS NEEDS TO BE THE MAIN STRUCT VERSION!!!
    // 0x000000000000000000000000000000 ff0801ff0201ff0000000001 01 01 01 32 3a
    struct turmite {
        uint8 turposx;
        uint8 turposy;
        uint8 orientation;
        uint8 boardnumber;
        bytes1 state;
        bytes12 rule;
    }

    function createTurmite(
        uint256 id,
        uint8 posx,
        uint8 posy,
        uint8 startdirection,
        uint8 boardnumber,
        bytes12 rule
    ) internal {
        bytes1 state = hex"00";
        turmites[id] = turmite(posx, posy, startdirection, boardnumber, state, rule);
    }

    function getDirectionTurmite(uint256 id, uint256 loop) public {
        bytes1 colorField;
        uint8 _x;
        uint8 _y;
        uint8 _boardNumber;
        bytes32 sour;

        turmite storage data = turmites[id];
        assembly {
            sour := sload(data.slot)
        }
        for (uint256 z = 0; z < loop; ) {
            assembly {
                _x := and(sour, 0xFF)
                _y := and(shr(8, sour), 0xFF)
                _boardNumber := shr(24, sour)
            }

            bytes1 stateOfField = getBit(_x, _y, _boardNumber);

            assembly {
                // ff0801 ff0201 ff0000 000001
                // c d s  c d s

                let maskedRule := and(sour, 0x000000000000000000000000000000ffffffffffffffffffffffff0000000000)

                let _orientation := and(
                    shr(16, sour),
                    0x00000000000000000000000000000000000000000000000000000000000000ff
                )

                let newState
                let newDirection

                if and(
                    eq(shr(248, stateOfField), 0x00),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x00)
                ) {
                    colorField := shl(120, maskedRule)
                    newDirection := and(shr(120, maskedRule), 0xFF)
                    newState := and(shr(112, maskedRule), 0xFF)
                }
                if and(
                    eq(shr(248, stateOfField), 0xff),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x00)
                ) {
                    colorField := shl(144, maskedRule)
                    newDirection := and(shr(96, maskedRule), 0xFF)
                    newState := and(shr(88, maskedRule), 0xFF)
                }
                if and(
                    eq(shr(248, stateOfField), 0x00),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x01)
                ) {
                    colorField := shl(168, maskedRule)
                    newDirection := and(shr(72, maskedRule), 0xFF)
                    newState := and(shr(64, maskedRule), 0xFF)
                }
                if and(
                    eq(shr(248, stateOfField), 0xff),
                    eq(shr(32, and(sour, 0x000000000000000000000000000000000000000000000000000000ff00000000)), 0x01)
                ) {
                    colorField := shl(192, maskedRule)
                    newDirection := and(shr(48, maskedRule), 0xFF)
                    newState := and(shr(40, maskedRule), 0xFF)
                }

                let newOrientation
                switch newDirection
                case 0x02 {
                    newOrientation := addmod(_orientation, 1, 4)
                }
                case 0x08 {
                    switch _orientation
                    case 0 {
                        newOrientation := 3
                    }
                    default {
                        newOrientation := mod(sub(_orientation, 1), 4)
                    }
                }
                case 0x04 {
                    newOrientation := mod(add(_orientation, 2), 4)
                }
                default {
                    newOrientation := _orientation
                }

                let buffer := mload(0x40)

                switch newOrientation
                case 0x00 {
                    mstore8(add(buffer, 31), addmod(_x, 1, 144))
                    mstore8(add(buffer, 30), _y)
                }
                case 0x02 {
                    switch _x
                    case 0 {
                        mstore8(add(buffer, 31), 143)
                        mstore8(add(buffer, 30), _y)
                    }
                    default {
                        mstore8(add(buffer, 31), sub(_x, 1))
                        mstore8(add(buffer, 30), _y)
                    }
                }
                case 0x03 {
                    mstore8(add(buffer, 31), _x)
                    mstore8(add(buffer, 30), addmod(_y, 1, 144))
                }
                case 0x01 {
                    switch _y
                    case 0 {
                        mstore8(add(buffer, 31), _x)
                        mstore8(add(buffer, 30), 143)
                    }
                    default {
                        mstore8(add(buffer, 31), _x)
                        mstore8(add(buffer, 30), sub(_y, 1))
                    }
                }

                //  128   120  112  104   96   88   80   72   64   56   48  40
                //0xff    08   01   ff   02   01   ff   00   00   00   44  21

                mstore8(add(buffer, 29), newOrientation)
                mstore8(add(buffer, 28), _boardNumber)
                mstore8(add(buffer, 27), newState)
                sour := or(mload(buffer), maskedRule)
            }

            // note that we pass here the "old" x & y
            setBit(_x, _y, colorField, _boardNumber);
            unchecked {
                z += 1;
            }
        }
        assembly {
            sstore(data.slot, sour)
        }
        emit turmiteMove(id, _boardNumber);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "solidity-bytes-utils/contracts/BytesLib.sol";
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Gameboard is Ownable {
    using BytesLib for bytes;
    mapping(uint256 => gameboard) gameboards;

    struct gameboard {
        bytes1[144][144] board;
    }

    function getBit(
        uint256 x,
        uint256 y,
        uint256 board
    ) public view returns (bytes1) {
        return gameboards[board].board[x][y];
    }

    function setBit(
        uint256 x,
        uint256 y,
        bytes1 value,
        uint256 board
    ) internal {
        gameboards[board].board[x][y] = value;
    }

    function getBitmapBase64(
        uint8 boardNumber,
        uint8 posx,
        uint8 posy,
        bool renderTurmite
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/bmp;base64,",
                    Base64.encode(getBitmap(boardNumber, posx, posy, renderTurmite))
                )
            );
    }

    function getSvg(
        uint8 boardNumber,
        uint8 posx,
        uint8 posy,
        bool renderTurmite
    ) public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500">',
                            '<image width="500" height="500" image-rendering="pixelated" xlink:href="',
                            getBitmapBase64(boardNumber, posx, posy, renderTurmite),
                            '"  />',
                            "</svg>"
                        )
                    )
                )
            );
    }

    function getBitmap(
        uint8 boardNumber,
        uint8 posx,
        uint8 posy,
        bool renderTurmite
    ) public view returns (bytes memory) {
        bytes
            memory headers = hex"424D385500000000000036040000280000009000000090000000010008000000000002510000120B0000120B00000000000000000000000000000101010002020200030303000404040005050500060606000707070008080800090909000A0A0A000B0B0B000C0C0C000D0D0D000E0E0E000F0F0F00101010001111110012121200131313001414140015151500161616001717170018181800191919001A1A1A001B1B1B001C1C1C001D1D1D001E1E1E001F1F1F00202020002121210022222200232323002424240025252500262626002727270028282800292929002A2A2A002B2B2B002C2C2C002D2D2D002E2E2E002F2F2F00303030003131310032323200333333003434340035353500363636003737370038383800393939003A3A3A003B3B3B003C3C3C003D3D3D003E3E3E003F3F3F00404040004141410042424200434343004444440045454500464646004747470048484800494949004A4A4A004B4B4B004C4C4C004D4D4D004E4E4E004F4F4F00505050005151510052525200535353005454540055555500565656005757570058585800595959005A5A5A005B5B5B005C5C5C005D5D5D005E5E5E005F5F5F00606060006161610062626200636363006464640065656500666666006767670068686800696969006A6A6A006B6B6B006C6C6C006D6D6D006E6E6E006F6F6F00707070007171710072727200737373007474740075757500767676007777770078787800797979007A7A7A007B7B7B007C7C7C007D7D7D007E7E7E007F7F7F00808080008181810082828200838383008484840085858500868686008787870088888800898989008A8A8A008B8B8B008C8C8C008D8D8D008E8E8E008F8F8F00909090009191910092929200939393009494940095959500969696009797970098989800999999009A9A9A009B9B9B009C9C9C009D9D9D009E9E9E009F9F9F00A0A0A000A1A1A100A2A2A200A3A3A300A4A4A400A5A5A500A6A6A600A7A7A700A8A8A800A9A9A900AAAAAA00ABABAB00ACACAC00ADADAD00AEAEAE00AFAFAF00B0B0B000B1B1B100B2B2B200B3B3B300B4B4B400B5B5B500B6B6B600B7B7B700B8B8B800B9B9B900BABABA00BBBBBB00BCBCBC00BDBDBD00BEBEBE00BFBFBF00C0C0C000C1C1C100C2C2C200C3C3C300C4C4C400C5C5C500C6C6C600C7C7C700C8C8C800C9C9C900CACACA00CBCBCB00CCCCCC00CDCDCD00CECECE00CFCFCF00D0D0D000D1D1D100D2D2D200D3D3D300D4D4D400D5D5D500D6D6D600D7D7D700D8D8D800D9D9D900DADADA00DBDBDB00DCDCDC00DDDDDD00DEDEDE00DFDFDF00E0E0E000E1E1E100E2E2E200E3E3E300E4E4E400E5E5E500E6E6E600E7E7E700E8E8E800E9E9E900EAEAEA00EBEBEB00ECECEC00EDEDED00EEEEEE00EFEFEF00F0F0F000F1F1F100F2F2F200F3F3F300F4F4F400F5F5F500F6F6F600F7F7F700F8F8F800F9F9F900FAFAFA00FBFBFB00FCFCFC00FDFDFD00FEFEFE00FFFFFF00";
        bytes memory returngameboard = new bytes(20736);
        for (uint256 xFill = 0; xFill < 144; ++xFill) {
            for (uint256 yFill = 0; yFill < 144; ++yFill) {
                uint256 index = xFill + 144 * yFill;
                returngameboard[index] = gameboards[boardNumber].board[xFill][yFill];
            }
        }
        if (renderTurmite == true) {
            uint256 index2 = uint256(posx) + 144 * uint256(posy);
            returngameboard[index2] = bytes1(uint8(190));
        }
        return headers.concat(returngameboard);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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