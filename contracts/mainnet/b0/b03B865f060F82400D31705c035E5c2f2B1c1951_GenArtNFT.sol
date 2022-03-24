// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "./NFTDescriptor.sol";

contract GenArtNFT is ERC721 {
    uint256 internal constant MAX_SUPPLY = 3000;

    bool public mintable;
    uint16 public dimensionLimits;
    uint24 public totalSupply;
    address public tokenDescriptor;
    address public owner;
    uint128[MAX_SUPPLY] public tokenData;

    constructor() ERC721(unicode"███", unicode"███") {
        owner = msg.sender;
        dimensionLimits = 0x6166;
    }

    function mint(uint128 data) external {
        require(mintable, "Minting disabled");
        uint256 ncol = (data >> 0) & 0x7;
        uint256 nrow = (data >> 3) & 0x7;
        uint256 dim = dimensionLimits;
        //prettier-ignore
        require(
            ncol >= ((dim >> 0)  & 0xF) &&
            ncol <= ((dim >> 4)  & 0xF) &&
            nrow >= ((dim >> 8)  & 0xF) &&
            nrow <= ((dim >> 12) & 0xF),
            "Invalid Data"
        );
        uint256 tokenId = ++totalSupply;
        require(tokenId <= MAX_SUPPLY, "Exceed max supply");
        uint256 rand = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, tokenId))) % 8;
        tokenData[tokenId] = (uint128(rand) << 120) | uint120(data);
        _mint(msg.sender, tokenId);
    }

    function _getData(uint256 tokenId)
        internal
        view
        returns (
            uint256 ncol,
            uint256 nrow,
            uint256 result,
            uint256 salt
        )
    {
        uint256 data = tokenData[tokenId];
        require(data != 0, "Token not exists");
        ncol = (data >> 0) & 0x7;
        nrow = (data >> 3) & 0x7;
        result = uint120(data) >> 6;
        salt = data;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (tokenDescriptor != address(0)) {
            return IERC721Descriptor(tokenDescriptor).tokenURI(tokenId);
        }
        (uint256 ncol, uint256 nrow, uint256 result, uint256 salt) = _getData(tokenId);
        return NFTDescriptor.constructTokenURI(tokenId, result, ncol, nrow, salt, name);
    }

    function imageURI(uint256 tokenId) external view returns (string memory) {
        (uint256 ncol, uint256 nrow, uint256 result, uint256 salt) = _getData(tokenId);
        return NFTDescriptor.makeImageURI(result, ncol, nrow, salt);
    }

    function squares(uint256 tokenId) external view returns (string memory) {
        (uint256 ncol, uint256 nrow, uint256 result, ) = _getData(tokenId);
        return NFTDescriptor.makeSquares(result, ncol, nrow);
    }

    // ----------

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setInfo(string calldata _name, string calldata _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;
    }

    function setMintable(bool _mintable) external onlyOwner {
        mintable = _mintable;
    }

    function setDimensionLimit(uint16 _dimensionLimits) external onlyOwner {
        dimensionLimits = _dimensionLimits;
    }

    // only in case we need to patch the art logic
    function setTokenDescriptor(address _descriptor) external onlyOwner {
        tokenDescriptor = _descriptor;
    }
}

interface IERC721Descriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
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
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
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
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./NFTArt.sol";
import "base64-sol/base64.sol";

library NFTDescriptor {
    function constructTokenURI(
        uint256 tokenId,
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt,
        string memory collectionName
    ) internal pure returns (string memory) {
        string memory image = Base64.encode(NFTArt.drawSVG(result, ncol, nrow, salt));
        bytes memory metadata = abi.encodePacked(
            '{"name":"',
            collectionName,
            " #",
            uintToString(tokenId),
            '", "description":"',
            "Completely on-chain generative art collection. Art is uniquely generated based on the minter's result in our rebranding game. Limited edition. \\n\\nThe minter's result:\\n",
            makeSquares(result, ncol, nrow),
            '", "image": "',
            "data:image/svg+xml;base64,",
            image,
            '"}'
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function makeSquares(
        uint256 result,
        uint256 ncol,
        uint256 nrow
    ) internal pure returns (string memory) {
        unchecked {
            bytes[8] memory rows;
            for (uint256 q = 0; q < nrow; ++q) {
                string[8] memory strs;
                for (uint256 p = ncol - 1; p != type(uint256).max; --p) {
                    uint256 res = result % 3;
                    strs[p] = res == 0 ? hex"e2ac9cefb88f" : res == 1 ? hex"f09f9fa8" : hex"f09f9fa9";
                    result /= 3;
                }
                rows[q] = abi.encodePacked(strs[0], strs[1], strs[2], strs[3], strs[4], strs[5], strs[6], strs[7], "\\n");
            }
            return string(abi.encodePacked(rows[0], rows[1], rows[2], rows[3], rows[4], rows[5], rows[6], rows[7]));
        }
    }

    function makeImageURI(
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt
    ) internal pure returns (string memory) {
        string memory image = Base64.encode(NFTArt.drawSVG(result, ncol, nrow, salt));
        return string(abi.encodePacked("data:image/svg+xml;base64,", image));
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

import "./RNG.sol";

library NFTArt {
    using RNG for RNG.Data;

    uint256 internal constant W_BASE = 30;
    uint256 internal constant W_RAND = 30;
    uint256 internal constant L_BASE = 30;
    uint256 internal constant L_RAND = 30;
    uint256 internal constant H_BASE = 20;
    uint256 internal constant H_RAND = 40;
    uint256 internal constant LAST_ROW_MIN_L = 55;
    uint256 internal constant FIRST_COL_MIN_W = 25;

    bytes6 internal constant FRAME_COLOR = "332E22";
    bytes6 internal constant COLOR1 = "E8E4DC";
    bytes internal constant COLOR2 = "6688EE6688EEFCBC18FDBD2EFE514EF2532DE7AC52EC6B2558C9EDEC6B25457DB6FCD265999999C3B89FF4AB13208793";
    bytes internal constant COLOR3 = "EE6666EE666628A7914561CC6CC2820B9594639AA0639AA0EF8FA3623A53DC5357DC505355555550978E9FBBC1C92B28";
    bytes internal constant BG_COLOR = "FBF5E9FBF5E9FBECE9F7F2E6ECEBE8EAEAEAF5EEE6";

    int256 internal constant LOGO_LENGTH = 112 * 35; // logo scale: 35
    int256 internal constant SCALE = 100;
    int256 internal constant OFFSET_X = ((600 / 2) + 0) * SCALE;
    int256 internal constant OFFSET_Y = ((600 / 2) + 20) * SCALE;
    int256 internal constant COS_30 = 86602540;
    int256 internal constant SIN_30 = 50000000;

    /**
     * w:       block width
     * l:       block length
     * h:       block height
     * (p, q):  block position in virtual plane
     * (x, y):  block position in projected plane
     */

    function isometric(int256 p, int256 q) internal pure returns (int256 x, int256 y) {
        unchecked {
            x = ((p + q) * COS_30) / 1e8 + OFFSET_X;
            y = ((q - p) * SIN_30) / 1e8 + OFFSET_Y;
        }
    }

    function intToString(int256 value) internal pure returns (bytes5 buffer) {
        assert(value >= 0 && value <= 99999);
        unchecked {
            // prettier-ignore
            buffer = bytes5(0x3030303030 + uint40(
                ((((uint256(value) / 1e0) % 10)) << 0) |
                ((((uint256(value) / 1e1) % 10)) << 8) |
                ((((uint256(value) / 1e2) % 10)) << 16) |
                ((((uint256(value) / 1e3) % 10)) << 24) |
                ((((uint256(value) / 1e4) % 10)) << 32)
            ));
        }
    }

    function pickColor(bytes memory choices, uint256 rand) internal pure returns (bytes6 picked) {
        unchecked {
            uint256 i = (rand % (choices.length / 6)) * 6;
            assembly {
                picked := mload(add(add(choices, 32), i))
            }
        }
    }

    struct Plane {
        int256 ax;
        int256 ay;
        int256 bx;
        int256 by;
        int256 cx;
        int256 cy;
        int256 dx;
        int256 dy;
    }

    function makeBlock(
        int256 p,
        int256 q,
        int256 w,
        int256 l,
        int256 h,
        bytes6 color,
        bool addLogo
    ) internal pure returns (bytes memory blk) {
        unchecked {
            Plane memory ground;
            (ground.ax, ground.ay) = isometric(p, q);
            (ground.bx, ground.by) = isometric(p + w, q);
            (ground.cx, ground.cy) = isometric(p + w, q + l);
            (ground.dx, ground.dy) = isometric(p, q + l);

            Plane memory cover = Plane({
                ax: ground.ax,
                ay: ground.ay - h,
                bx: ground.bx,
                by: ground.by - h,
                cx: ground.cx,
                cy: ground.cy - h,
                dx: ground.dx,
                dy: ground.dy - h
            });

            // prettier-ignore
            bytes memory coverCode = abi.encodePacked(
                '<path d="M', intToString(cover.ax), ",", intToString(cover.ay),
                "L", intToString(cover.bx), ",", intToString(cover.by),
                "L", intToString(cover.cx), ",", intToString(cover.cy),
                "L", intToString(cover.dx), ",", intToString(cover.dy), 'Z" fill="#', color, '"/>'
            );
            // prettier-ignore
            bytes memory sides = abi.encodePacked(
                '<path d="M', intToString(cover.ax), ",", intToString(cover.ay),
                "L", intToString(cover.dx), ",", intToString(cover.dy),
                "L", intToString(cover.cx), ",", intToString(cover.cy),
                "V", intToString(ground.cy),
                "L", intToString(ground.dx), ",", intToString(ground.dy),
                "L", intToString(ground.ax), ",", intToString(ground.ay), 'Z"/>'
            );
            blk = abi.encodePacked(sides, coverCode);

            if (addLogo) {
                (int256 x, int256 y) = isometric(p + w / 2, q + (l - LOGO_LENGTH) / 2);
                blk = abi.encodePacked(blk, '<use href="#logo" x="', intToString(x), '" y="', intToString(y - h), '"/>');
            }
        }
    }

    function makeBlocks(Config memory cfg) internal pure returns (bytes[8] memory rows) {
        unchecked {
            int256 qMemo = 0;
            for (uint256 q = 0; q < cfg.nrow; q++) {
                bytes[8] memory bs;
                int256 l = int256(cfg.ls[q]);

                uint256 i = 0;
                for (uint256 p = cfg.ncol - 1; p != type(uint256).max; --p) {
                    bytes6 color = cfg.colors[cfg.result % 3];
                    int256 w = int256(cfg.ws[p]);
                    int256 h = int256(cfg.hs[q][p]);
                    int256 pAdjusted = cfg.offsetP + int256(p == 0 ? 0 : cfg.wsCumSum[p - 1]);
                    int256 qAdjusted = cfg.offsetQ + qMemo;
                    bool addLogo = q == cfg.nrow - 1 && p == 0;

                    bs[i++] = makeBlock(pAdjusted, qAdjusted, w, l, h, color, addLogo);
                    cfg.result /= 3;
                }
                rows[q] = abi.encodePacked(bs[0], bs[1], bs[2], bs[3], bs[4], bs[5], bs[6], bs[7]);
                qMemo += l;
            }
        }
    }

    function makeSvg(Config memory cfg) internal pure returns (bytes memory svg) {
        bytes[8] memory rows = makeBlocks(cfg);
        svg = abi.encodePacked(
            '<svg viewBox="0 0 60000 60000" xmlns="http://www.w3.org/2000/svg">'
            '<def><g id="logo" fill="#332E22" stroke-width="0" transform="scale(35)">'
            '<path d="M18 20c2 1 2.3 2.3.6 3.2S14 24 12 23c-2-1-2.2-2.4-.6-3.2s4.6-1 6.6.1zm5.3 12.6c1.7-1 1.4-2.3-.6-3.2s-5-1-6.5-.2-1.3 2.3.6 3.2c2 1 4.8 1 6.5.2z"/>'
            '<path fill-rule="evenodd" d="M80 19.5C84.6 1 29.2-3.6 11 8-8.7 17.8 1 48 35.7 44.4c.2.2.5.3.8.4l23 9.8c1.8.8 4.3.7 6-.2L99.8 35c1.6-1 1.6-2.2.1-3.2l-19-12c-.3-.2-.6-.3-1-.4zM48.6 34C16.5 51-6.8 22.3 16 10.5 10 22 78 15.4 48.6 34zm45.2-.6l-13 7.4c-3-1-9.8-6.7-13.5-4.3-4.4 2 6.6 5.5 8.6 7L71 46.3c-3-1-11-6.5-14-4-3.8 2 7.4 5.2 9.5 6.6l-4 2.3L42.8 43l35-19.7 16 10.2z"/>'
            "</g></def>"
            '<rect width="60000" height="60000" fill="#',
            cfg.frameColor,
            '"/>'
            '<rect x="2500" y="2500" width="55000" height="55000" stroke="#332E22" stroke-width="200" fill="#',
            cfg.bgColor,
            '"/>'
            '<g fill="#332E22" stroke="#332E22" stroke-width="100">'
        );
        svg = abi.encodePacked(svg, rows[0], rows[1], rows[2], rows[3], rows[4], rows[5], rows[6], rows[7], "</g></svg>");
    }

    // ------- config -------

    struct Config {
        uint256 result;
        uint256 ncol;
        uint256 nrow;
        int256 offsetP;
        int256 offsetQ;
        uint256[8] ws;
        uint256[8] ls;
        uint256[8][8] hs;
        uint256[8] wsCumSum;
        bytes6[3] colors;
        bytes6 bgColor;
        bytes6 frameColor;
    }

    function generateConfig(
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt
    ) internal pure returns (Config memory cfg) {
        RNG.Data memory rng = RNG.Data(salt, 0);

        cfg.result = result;
        cfg.ncol = ncol;
        cfg.nrow = nrow;

        cfg.colors[0] = COLOR1;
        cfg.colors[1] = pickColor(COLOR2, rng.rand());
        cfg.colors[2] = pickColor(COLOR3, rng.rand());
        cfg.bgColor = pickColor(BG_COLOR, rng.rand());
        cfg.frameColor = FRAME_COLOR;

        while (true) {
            // generate widths
            unchecked {
                uint256[8] memory ws = cfg.ws;
                uint256[8] memory wsCumSum = cfg.wsCumSum;
                uint256 rand = rng.rand();
                uint256 memo = 0;
                for (uint256 p = 0; p < ncol; ++p) {
                    uint256 w = (W_BASE + ((rand >> (8 * p)) % W_RAND)) * uint256(SCALE);
                    if (p == 0 && w < FIRST_COL_MIN_W) w = FIRST_COL_MIN_W;
                    wsCumSum[p] = (memo += (ws[p] = w));
                }
                cfg.offsetP = -int256(memo) / 2;
            }

            // generate lengths
            unchecked {
                uint256[8] memory ls = cfg.ls;
                uint256 rand = rng.rand();
                uint256 memo = 0;
                for (uint256 q = 0; q < nrow; ++q) {
                    uint256 l = (L_BASE + ((rand >> (8 * q)) % L_RAND)) * uint256(SCALE);
                    if (q == nrow - 1 && l < LAST_ROW_MIN_L) l = LAST_ROW_MIN_L;
                    memo += (ls[q] = l);
                }
                cfg.offsetQ = -int256(memo) / 2;
            }

            // ensure no "out of canvas"
            (int256 x0, ) = isometric(cfg.offsetP, cfg.offsetQ);
            if (x0 >= 3000) break;
        }

        // generate heights
        unchecked {
            uint256[8][8] memory hs = cfg.hs;
            for (uint256 q = 0; q < nrow; ++q) {
                uint256 rand = rng.rand();
                for (uint256 p = 0; p < ncol; ++p) {
                    hs[q][p] = (H_BASE + ((rand >> (8 * p)) % H_RAND)) * uint256(SCALE);
                }
            }
        }
    }

    // ------- entry point -------

    function drawSVG(
        uint256 result,
        uint256 ncol,
        uint256 nrow,
        uint256 salt
    ) internal pure returns (bytes memory svg) {
        return makeSvg(generateConfig(result, ncol, nrow, salt));
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.10;

library RNG {
    struct Data {
        uint256 seed;
        uint256 i;
    }

    function rand(Data memory rng) internal pure returns (uint256) {
        unchecked {
            return uint256(keccak256(abi.encode(rng.seed, rng.i++)));
        }
    }
}