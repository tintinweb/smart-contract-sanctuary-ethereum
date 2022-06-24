// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {libImg} from "../src/libImg.sol";
import {png} from "../src/png.sol";
import {json} from "../src/JSON.sol";

interface IBasedGhouls {
    function ownerOf(uint256 id) external view returns (address owner);
}

contract ghoulBalls is ERC721, Owned(msg.sender) {

    uint32 constant WIDTH_AND_HEIGHT = 128;
    int256 constant CIRCLE_RADIUS = 69;

    IBasedGhouls ghouls = IBasedGhouls(0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90);

    mapping(uint256 => bytes) internal colours;

    function _hash(bytes memory SAUCE) internal pure returns(bytes memory) {
        return abi.encodePacked(keccak256(SAUCE));
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        require(_bytes.length >= 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(_bytes, 0x20))
        }

        return tempUint;
    }

    // Each RGB is 3 bytes, determine number of balls that will be in the PNG then generate the colours
    function _generateColour(uint256 id) internal view returns(bytes memory) {
        uint256 randomish = toUint256(_hash(abi.encodePacked(id, msg.sender, block.timestamp)));

        if((randomish % 69) > 60) {
            return abi.encodePacked((uint144(randomish))); //6
        } else if((randomish % 69) > 50) {
            return abi.encodePacked((uint96(randomish))); //4
        } else if((randomish % 69) > 40) {
            return abi.encodePacked((uint48(randomish))); //2
        } else {
            return abi.encodePacked((uint24(randomish))); //1
        }
        
    }

    function mint_the_ball(uint256 id) public {
        require(id < 10000, "invalid ball.");
        if (id<6666) {
            require(ghouls.ownerOf(id) == msg.sender, "not your ghoul.");
        }
        require(_ownerOf[id] == address(0), "someone else got this ghoulBall.");

        colours[id] = _generateColour(id);

        _mint(msg.sender, id);
    }

    function click_for_utility(uint256 id) public {
        _burn(id);
    }

    function getPalette(uint256 id) internal view returns (bytes3[] memory) {
        bytes memory _coloursArr = colours[id];

        bytes3[] memory palette = new bytes3[](_coloursArr.length/3);

        for(uint256 i = 0; i<palette.length; i++) {
            palette[i] = 
                bytes3(
                    bytes.concat(
                        _coloursArr[i*3],
                        _coloursArr[i*3+1],
                        _coloursArr[i*3+2]
                    )
                );
        }

        return palette;
    }

    function tokenPNG(uint256 id) public view returns (string memory) {
        bytes3[] memory _palette = getPalette(id);

        libImg.IMAGE memory imgPixels = libImg.IMAGE(
            WIDTH_AND_HEIGHT,
            WIDTH_AND_HEIGHT,
            new bytes(WIDTH_AND_HEIGHT*WIDTH_AND_HEIGHT+1)
        );
        
        return png.encodedPNG(WIDTH_AND_HEIGHT, WIDTH_AND_HEIGHT, _palette, libImg.drawImage(imgPixels, _palette.length), true);

    }

    function tokenAttributes(uint256 id) internal view returns (string memory) {
        bytes memory plte = colours[id];

        string memory palettes;
        bool last;

        for (uint256 i = 0; i<plte.length/3; i++) {
            last = (i == (plte.length/3-1)) ? true : false;

            palettes = string.concat(
                palettes,
                json._attr(
                    string.concat('ball ', json.toString(i+1)),
                    string.concat(
                        json.toString(uint8(plte[i*3])),
                        ', ',
                        json.toString(uint8(plte[i*3+1])),
                        ', ',
                        json.toString(uint8(plte[i*3+2]))
                    ),
                    last
                )
            );
        }

        // we attach the number of balls, and colour palette to the ERC721 JSON
        return string.concat(
            json._attr('ball count', json.toString(plte.length/3)),
            palettes
        );

    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return json.formattedMetadata(
            'ghoulBalls',
            "ghoulBalls are fully onchain PNGs that evolve with every block, absolutely rugging the right-click savers after everyblock. No roadmap, no development, no utility, no marketing, and nothing more. They promise nothing and deliver even less. They're just PNGs.",
            tokenPNG(id),
            tokenAttributes(id)
        );
    }

    //never know if they'll rug us again with a v3
    function updateGhoulAddr(address ghoulAddr) public onlyOwner {
        ghouls = IBasedGhouls(ghoulAddr);
    }
    
    constructor() ERC721("ghoulBalls", unicode"🎊"){}

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

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

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

library libImg {

    struct IMAGE{
        uint256 width;
        uint256 height;
        bytes pixels;
    }

    function toIndex(int256 _x, int256 _y, uint256 _width) internal pure returns (uint256 index){
        unchecked{
            index = uint256(_y) * (_width +1) + uint256(_x) + 1;
        }
        
    }

    function assignMidPoint(uint256 seed, uint256 width, uint256 height) internal pure returns (int256 x, int256 y) {

        x = int256(
                (
                    ((seed >> 2*8) % width) +
                    (width / 2)
                ) /2
            );

        y = int256(
                (
                    ((seed) % height) +
                    (height / 2)

                ) /2
            );


    }

    function rasterFilledCircle(IMAGE memory img, int256 xMid, int256 yMid, int256 r, bytes1 idxColour) internal pure returns (IMAGE memory) {

        int256 xSym;
        int256 ySym;
        int256 x = 0;
        int256 y = int(r);

        unchecked {
            for (x = xMid - r ; x <= xMid; x++) {
                for (y = yMid - r ; y <= yMid; y++) {
                    if ((x - xMid)*(x - xMid) + (y - yMid)*(y - yMid) <= r*r) 
                    {
                        xSym = xMid - (x - xMid);
                        ySym = yMid - (y - yMid);
                        // (x, y), (x, ySym), (xSym , y), (xSym, ySym) are in the circle
                        if (x >= 0 && y >= 0) {
                            img.pixels[toIndex(x, y,img.width)] = idxColour;
                        }
                        if (x >= 0 && ySym >= 0) {
                            img.pixels[toIndex(x, ySym,img.width)] = idxColour;
                        }
                        if (xSym >= 0 && y >= 0) {
                            img.pixels[toIndex(xSym, y,img.width)] = idxColour;
                        }
                        if (xSym >= 0 && ySym >= 0) {
                            img.pixels[toIndex(xSym, ySym,img.width)] = idxColour;
                        }
                    }
                }
            }
        }
        return img;
    }

    function drawImage(IMAGE memory img, uint256 circleCount) internal view returns (bytes memory){

        IMAGE memory tempImg;
        int256 xMid;
        int256 yMid;
        uint256 randoSeed;

        for (uint8 i = 0; i<circleCount; i++) {
            randoSeed = uint256(keccak256(abi.encodePacked(block.timestamp, i)));
            (xMid, yMid) = assignMidPoint(randoSeed, img.width, img.height);

            tempImg = rasterFilledCircle(img, xMid, yMid, int256(18), bytes1(i+1));
        }
        
        return tempImg.pixels;

    }

}

// SPDX-License-Identifier: Unlicense
/*
 * @title Onchain PNGs
 * @author Colin Platt <[email protected]>
 *
 * @dev PNG encoding tools written in Solidity for producing read-only onchain PNG files.
 */

pragma solidity =0.8.13;

library png {
    
    struct RGBA {
        bytes1 red;
        bytes1 green;
        bytes1 blue;
    }

    function rgbToPalette(bytes1 red, bytes1 green, bytes1 blue) internal pure returns (bytes3) {
        return bytes3(abi.encodePacked(red, green, blue));
    }

    function rgbToPalette(RGBA memory _rgb) internal pure returns (bytes3) {
        return bytes3(abi.encodePacked(_rgb.red, _rgb.green, _rgb.blue));
    }

    function calculateBitDepth(uint256 _length) internal pure returns (uint256) {
        if (_length < 3) {
            return 2;
        } else if(_length < 5) {
            return 4;
        } else if(_length < 17) {
            return 16;
        } else {
            return 256;
        }
    }

    function formatPalette(bytes3[] memory _palette, bool _8bit) internal pure returns (bytes memory) {
        require(_palette.length <= 256, "PNG: Palette too large.");

        uint256 depth = _8bit? uint256(256) : calculateBitDepth(_palette.length);
        bytes memory paletteObj;

        for (uint i = 0; i<_palette.length; i++) {
            paletteObj = abi.encodePacked(paletteObj, _palette[i]);
        }

        for (uint i = _palette.length; i<depth-1; i++) {
            paletteObj = abi.encodePacked(paletteObj, bytes3(0x000000));
        }

        return abi.encodePacked(
            uint32(depth*3),
            'PLTE',
            bytes3(0x000000),
            paletteObj
        );
    }

    function _tRNS(uint256 _bitDepth, uint256 _palette) internal pure returns (bytes memory) {

        bytes memory tRNSObj = abi.encodePacked(bytes1(0x00));

        for (uint i = 0; i<_palette; i++) {
            tRNSObj = abi.encodePacked(tRNSObj, bytes1(0xFF));
        }

        for (uint i = _palette; i<_bitDepth-1; i++) {
            tRNSObj = abi.encodePacked(tRNSObj, bytes1(0x00));
        }

        return abi.encodePacked(
            uint32(_bitDepth),
            'tRNS',
            tRNSObj
        );
    }

    function rawPNG(uint32 width, uint32 height, bytes3[] memory palette, bytes memory pixels, bool force8bit) internal pure returns (bytes memory) {

        uint256[256] memory crcTable = calcCrcTable();

        // Write PLTE
        bytes memory plte = formatPalette(palette, force8bit);

        // Write tRNS
        bytes memory tRNS = png._tRNS(
            force8bit ? 256 : calculateBitDepth(palette.length),
            palette.length
            );

        // Write IHDR
        bytes21 header = bytes21(abi.encodePacked(
                uint32(13),
                'IHDR',
                width,
                height,
                bytes5(0x0803000000)
            )
        );

        bytes7 deflate = bytes7(
            abi.encodePacked(
                bytes2(0x78DA),
                pixels.length > 65535 ? bytes1(0x00) :  bytes1(0x01),
                png.byte2lsb(uint16(pixels.length)),
                ~png.byte2lsb(uint16(pixels.length))
            )
        );

        bytes memory zlib = abi.encodePacked('IDAT', deflate, pixels, _adler32(pixels));

        return abi.encodePacked(
            bytes8(0x89504E470D0A1A0A),
            header, 
            _CRC(crcTable, abi.encodePacked(header),4),
            plte, 
            _CRC(crcTable, abi.encodePacked(plte),4),
            tRNS, 
            _CRC(crcTable, abi.encodePacked(tRNS),4),
            uint32(zlib.length-4),
            zlib,
            _CRC(crcTable, abi.encodePacked(zlib), 0), 
            bytes12(0x0000000049454E44AE426082)
        );

    }

    function encodedPNG(uint32 width, uint32 height, bytes3[] memory palette, bytes memory pixels, bool force8bit) internal pure returns (string memory) {
        return string.concat('data:image/png;base64,', base64encode(rawPNG(width, height, palette, pixels, force8bit)));
    }






    // @dev Does not check out of bounds
    function coordinatesToIndex(uint256 _x, uint256 _y, uint256 _width) internal pure returns (uint256 index) {
            index = _y * (_width + 1) + _x + 1;
	}

    

    








    /////////////////////////// 
    /// Checksums

    // need to check faster ways to do this
    function calcCrcTable() internal pure returns (uint256[256] memory crcTable) {
        uint256 c;

        unchecked{
            for(uint256 n = 0; n < 256; n++) {
                c = n;
                for (uint256 k = 0; k < 8; k++) {
                    if(c & 1 == 1) {
                        c = 0xedb88320 ^ (c >>1);
                    } else {
                        c = c >> 1;
                    }
                }
                crcTable[n] = c;
            }
        }
    }

    function _CRC(uint256[256] memory crcTable, bytes memory chunk, uint256 offset) internal pure returns (bytes4) {

        uint256 len = chunk.length;

        uint32 c = uint32(0xffffffff);
        unchecked{
            for(uint256 n = offset; n < len; n++) {
                c = uint32(crcTable[(c^uint8(chunk[n])) & 0xff] ^ (c >> 8));
            }
        }
        return bytes4(c)^0xffffffff;

    }

    
    function _adler32(bytes memory _data) internal pure returns (bytes4) {
        uint32 a = 1;
        uint32 b = 0;

        uint256 _len = _data.length;

        unchecked {
            for (uint256 i = 0; i < _len; i++) {
                a = (a + uint8(_data[i])) % 65521; //may need to convert to uint32
                b = (b + a) % 65521;
            }
        }

        return bytes4((b << 16) | a);

    }

    /////////////////////////// 
    /// Utilities

    function byte2lsb(uint16 _input) internal pure returns (bytes2) {

        return byte2lsb(bytes2(_input));

    }

    function byte2lsb(bytes2 _input) internal pure returns (bytes2) {

        return bytes2(abi.encodePacked(bytes1(_input << 8), bytes1(_input)));

    }

    function _toBuffer(bytes memory _bytes) internal pure returns (bytes1[] memory) {

        uint256 _length = _bytes.length;

        bytes1[] memory byteArray = new bytes1[](_length);
        bytes memory tempBytes;

        unchecked{
            for (uint256 i = 0; i<_length; i++) {
                assembly {
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
                    let lengthmod := and(1, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, 1)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), i)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, 1)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }

                byteArray[i] = bytes1(tempBytes);

            }
        }
        
        return byteArray;
    }

    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function base64encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }



}

//SPDX-License-Identifier: Unlicense
/*
 * @title ERC721 JSON metadata
 * @author Colin Platt <[email protected]>
 *
 * @dev JSON utilities for base64 encoded ERC721 JSON metadata schema
 */
pragma solidity ^0.8.12;

library json {
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// @dev JSON requires that double quotes be escaped or JSONs will not build correctly
    /// string.concat also requires an escape, use \\" or the constant DOUBLE_QUOTES to represent " in JSON
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////

    string constant DOUBLE_QUOTES = '\\"';

    function formattedMetadata(
        string memory name,
        string memory description,
        string memory pngImg,
        string memory attributes
    )   internal
        pure
        returns (string memory)
    {
        return string.concat(
            'data:application/json;base64,',
            encode(
                bytes(
                    string.concat(
                    '{',
                    _prop('name', name),
                    _prop('description', description),
                    _xmlImage(pngImg),
                    _objectSq('attributes', attributes),
                    '}'
                    )
                )
            )
        );
    }
    
    function _xmlImage(string memory _pngImg)
        internal
        pure
        returns (string memory) 
    {
        return _prop(
                        'image',
                        string.concat(
                            'data:image/svg+xml;base64,',
                            encode(
                                bytes(string.concat(
                                    '<svg width="100%" height="100%" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">  <image x="0" y="0" width="128" height="128" preserveAspectRatio="xMidYMid" xlink:href="',
                                    _pngImg,
                                    '"/></svg>'
                                ))
                            )
                        ),
                        false
        );
    }

    function _prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '"', _val, '", ');
    }

    function _prop(string memory _key, string memory _val, bool last)
        internal
        pure
        returns (string memory)
    {
        if(last) {
            return string.concat('"', _key, '": ', '"', _val, '"');
        } else {
            return string.concat('"', _key, '": ', '"', _val, '", ');
        }
        
    }

    function _object(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '{', _val, '}');
    }

    function _objectSq(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '": ', '[', _val, ']');
    }

    function _attr(string memory _trait_type, string memory _value)
        internal
        pure
        returns (string memory)
    {
        return string.concat('{"trait_type": "', _trait_type, '", ', '"value" : "', _value, '"}, ');
    }

    function _attr(string memory _trait_type, string memory _value, bool last)
        internal
        pure
        returns (string memory)
    {
        if (last) {
            return string.concat('{"trait_type": "', _trait_type, '", ', '"value" : "', _value, '"}');
        } else {
            return string.concat('{"trait_type": "', _trait_type, '", ', '"value" : "', _value, '"}, ');
        }
        
    }

     
     /**
     * taken from Openzeppelin
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }

    /**
     * taken from Openzeppelin
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

}