// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledUtils.sol";
import "./ShackledStructs.sol";
import "./ShackledRenderer.sol";
import "./ShackledGenesis.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Shackled is ERC721Enumerable, Ownable {
    /// minting parameters for the Genesis collection
    bytes32 public mintState;
    bytes32 public publicMintState = keccak256(abi.encodePacked("public_mint"));
    bytes32 public presaleMintState = keccak256(abi.encodePacked("presale"));
    uint256 public maxSupply = 1024;
    uint256 public mintPrice = 0.15 ether;
    uint256 public reservedTokens = 20;
    uint256 public txnQtyLimit = 5;
    mapping(uint256 => bytes32) public tokenSeedHashes;

    /// rendering engine parameters
    int256 public canvasDim = 128;
    uint256 public outputHeight = 512;
    uint256 public outputWidth = 512;
    bool public returnSVG = true;

    event Received(address, uint256);

    constructor() ERC721("Shackled", "SHACKLED") {}

    /** @dev Mint allocated token IDs assigned to active Dawn Key holders.
     * @param quantity The amount to mint
     * @param allowlistMintIds The allocated ids to mint at mintPrice
     * @param dawnKeyMintIds The allocated ids to mint free
     * @param signature The signature to verify
     */
    function presaleMint(
        uint256 quantity,
        uint256[] calldata allowlistMintIds,
        uint256[] calldata dawnKeyMintIds,
        bytes calldata signature
    ) public payable {
        require(presaleMintState == mintState, "Presale mint is not active");

        /// verify the signature to confirm valid paramaters have been sent
        require(
            checkSignature(signature, allowlistMintIds, dawnKeyMintIds),
            "Invalid signature"
        );

        uint256 nMintableIds = allowlistMintIds.length + dawnKeyMintIds.length;

        /// check that the current balance indicates tokens are still mintable
        /// to raise an error and stop the transaction that wont lead to any mints
        /// note that this doesnt guarantee tokens haven't been minted
        /// as they may have been transfered out of the holder's wallet
        require(
            quantity + balanceOf(msg.sender) <= nMintableIds,
            "Quantity requested is too high"
        );

        /// determine how many allowlistMints are being made
        /// and that sufficient value has been sent to cover this
        uint256 dawnKeyMintsRequested;
        for (uint256 i = 0; i < dawnKeyMintIds.length; i++) {
            if (!_exists(dawnKeyMintIds[i])) {
                if (dawnKeyMintsRequested < quantity) {
                    dawnKeyMintsRequested++;
                } else {
                    break;
                }
            }
        }

        uint256 allowListMintsRequested = quantity - dawnKeyMintsRequested;

        require(
            msg.value >= mintPrice * allowListMintsRequested,
            "Insufficient value to mint"
        );

        /// iterate through all mintable ids (dawn key mints first)
        /// and mint up to the requested quantity
        uint16 numMinted;
        for (uint256 i = 0; i < nMintableIds; ++i) {
            if (numMinted == quantity) {
                break;
            }

            bool dawnKeyMint = i < dawnKeyMintIds.length;

            uint256 tokenId = dawnKeyMint
                ? dawnKeyMintIds[i]
                : allowlistMintIds[i - dawnKeyMintIds.length];

            /// check that this specific token is mintable
            /// prevents minting, transfering out of the wallet, and minting again
            if (_exists(tokenId)) {
                continue;
            }

            _safeMint(msg.sender, tokenId);
            storeSeedHash(tokenId);
            ++numMinted;
        }
        require(numMinted == quantity, "Requested quantity not minted");
    }

    /** @dev Mints a token during the public mint phase
     * @param quantity The quantity of tokens to mint
     */
    function publicMint(uint256 quantity) public payable {
        require(mintState == publicMintState, "Public mint is not active");
        require(quantity <= txnQtyLimit, "Quantity exceeds txn limit");

        // check the txn value
        require(
            msg.value >= mintPrice * quantity,
            "Insufficient value to mint"
        );

        /// Disallow transactions that would exceed the maxSupply
        require(
            totalSupply() + quantity <= maxSupply,
            "Insufficient supply remaining"
        );

        /// mint the requested quantity
        /// go through the whole supply to find tokens
        /// as some may not have been minted in presale
        uint256 minted;
        for (uint256 tokenId = 0; tokenId < maxSupply; tokenId++) {
            if (!_exists(tokenId)) {
                _safeMint(msg.sender, tokenId);
                storeSeedHash(tokenId);
                minted++;
            }
            if (minted == quantity) {
                break;
            }
        }
    }

    /** @dev Store the seedhash for a tokenId */
    function storeSeedHash(uint256 tokenId) internal {
        require(_exists(tokenId), "TokenId does not exist");
        require(tokenSeedHashes[tokenId] == 0, "Seed hash already set");
        /// create a hash that will be used to seed each Genesis piece
        /// use a range of parameters to reduce predictability and gamification
        tokenSeedHashes[tokenId] = keccak256(
            abi.encodePacked(
                block.timestamp,
                block.difficulty,
                msg.sender,
                tokenId
            )
        );
    }

    /** @dev Set the contract's mint state
     */
    function setMintState(string memory newMintState) public onlyOwner {
        mintState = keccak256(abi.encodePacked(newMintState));
    }

    /** @dev validate a signature
     */
    function checkSignature(
        bytes memory signature,
        uint256[] calldata allowlistMintIds,
        uint256[] calldata dawnKeyMintIds
    ) public view returns (bool) {
        bytes32 payloadHash = keccak256(
            abi.encode(this, msg.sender, allowlistMintIds, dawnKeyMintIds)
        );
        address actualSigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(payloadHash),
            signature
        );
        address owner = owner();
        return (owner == actualSigner);
    }

    /**
     * @dev Set some tokens aside for the team
     */
    function reserveTokens() public onlyOwner {
        for (uint256 i = 0; i < reservedTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
            storeSeedHash(tokenId);
        }
    }

    /**
     * @dev Withdraw ether to owner's wallet
     */
    function withdrawEth() public onlyOwner {
        uint256 balance = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw failed");
    }

    /** @dev run the rendering engine on any given renderParams */
    function render(
        ShackledStructs.RenderParams memory renderParams,
        int256 canvasDim_,
        bool returnSVG
    ) public view returns (string memory) {
        return ShackledRenderer.render(renderParams, canvasDim_, returnSVG);
    }

    /** generate a genesis piece from a given tokenHash */
    function generateGenesisPiece(bytes32 tokenHash)
        public
        view
        returns (
            ShackledStructs.RenderParams memory,
            ShackledStructs.Metadata memory
        )
    {
        return ShackledGenesis.generateGenesisPiece(tokenHash);
    }

    /** @dev render the art for a Shackled Genesis NFT and get the 'raw' metadata
     */
    function renderGenesis(uint256 tokenId, int256 canvasDim_)
        public
        view
        returns (
            string memory,
            ShackledStructs.RenderParams memory,
            ShackledStructs.Metadata memory
        )
    {
        /// get the hash created when this token was minted
        bytes32 tokenHash = tokenSeedHashes[tokenId];

        /// generate the geometry and color of this genesis piece
        (
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        ) = ShackledGenesis.generateGenesisPiece(tokenHash);

        // run the rendering engine and return an encoded image
        string memory image = ShackledRenderer.render(
            renderParams,
            canvasDim_,
            returnSVG
        );

        return (image, renderParams, metadata);
    }

    /** @dev run the rendering engine and return a token's final metadata
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

        (
            string memory image,
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        ) = renderGenesis(tokenId, canvasDim);

        // construct and encode the metadata json
        return ShackledUtils.getEncodedMetadata(image, metadata, tokenId);
    }

    /** @dev change the canvas size to render on
     */
    function updateCanvasDim(int256 _canvasDim) public onlyOwner {
        canvasDim = _canvasDim;
    }

    /** @dev change the desired output width to interpolate to in the svg container
     */
    function updateOutputWidth(uint256 _outputWidth) public onlyOwner {
        outputWidth = _outputWidth;
    }

    /** @dev change the desired output height to interpolate to in the svg container
     */
    function updateOutputHeight(uint256 _outputHeight) public onlyOwner {
        outputHeight = _outputHeight;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledStructs.sol";

library ShackledUtils {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /** @dev Flatten 3d tris array into 2d verts */
    function flattenTris(int256[3][3][] memory tris)
        internal
        pure
        returns (int256[3][] memory)
    {
        /// initialize a dynamic in-memory array
        int256[3][] memory flattened = new int256[3][](3 * tris.length);

        for (uint256 i = 0; i < tris.length; i++) {
            /// tris.length == N
            // add values to specific index, as cannot push to array in memory
            flattened[(i * 3) + 0] = tris[i][0];
            flattened[(i * 3) + 1] = tris[i][1];
            flattened[(i * 3) + 2] = tris[i][2];
        }
        return flattened;
    }

    /** @dev Unflatten 2d verts array into 3d tries (inverse of flattenTris function) */
    function unflattenVertsToTris(int256[3][] memory verts)
        internal
        pure
        returns (int256[3][3][] memory)
    {
        /// initialize an array with length = 1/3 length of verts
        int256[3][3][] memory tris = new int256[3][3][](verts.length / 3);

        for (uint256 i = 0; i < verts.length; i += 3) {
            tris[i / 3] = [verts[i], verts[i + 1], verts[i + 2]];
        }
        return tris;
    }

    /** @dev clip an array to a certain length (to trim empty tail slots) */
    function clipArray12ToLength(int256[12][] memory arr, uint256 desiredLen)
        internal
        pure
        returns (int256[12][] memory)
    {
        uint256 nToCull = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), nToCull))
        }
        return arr;
    }

    /** @dev convert an unsigned int to a string */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /** @dev get the hex encoding of various powers of 2 (canvas size options) */
    function getHex(uint256 _i) internal pure returns (bytes memory _hex) {
        if (_i == 8) {
            return hex"08_00_00_00";
        } else if (_i == 16) {
            return hex"10_00_00_00";
        } else if (_i == 32) {
            return hex"20_00_00_00";
        } else if (_i == 64) {
            return hex"40_00_00_00";
        } else if (_i == 128) {
            return hex"80_00_00_00";
        } else if (_i == 256) {
            return hex"00_01_00_00";
        } else if (_i == 512) {
            return hex"00_02_00_00";
        }
    }

    /** @dev create an svg container for a bitmap (for display on svg-only platforms) */
    function getSVGContainer(
        string memory encodedBitmap,
        int256 canvasDim,
        uint256 outputHeight,
        uint256 outputWidth
    ) internal view returns (string memory) {
        uint256 canvasDimUnsigned = uint256(canvasDim);
        // construct some elements in memory prior to return string to avoid stack too deep
        bytes memory imgSize = abi.encodePacked(
            "width='",
            ShackledUtils.uint2str(canvasDimUnsigned),
            "' height='",
            ShackledUtils.uint2str(canvasDimUnsigned),
            "'"
        );
        bytes memory canvasSize = abi.encodePacked(
            "width='",
            ShackledUtils.uint2str(outputWidth),
            "' height='",
            ShackledUtils.uint2str(outputHeight),
            "'"
        );
        bytes memory scaleStartTag = abi.encodePacked(
            "<g transform='scale(",
            ShackledUtils.uint2str(outputWidth / canvasDimUnsigned),
            ")'>"
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' ",
                            "shape-rendering='crispEdges' ",
                            canvasSize,
                            ">",
                            scaleStartTag,
                            "<image ",
                            imgSize,
                            " style='image-rendering: pixelated; image-rendering: crisp-edges;' ",
                            "href='",
                            encodedBitmap,
                            "'/></g></svg>"
                        )
                    )
                )
            );
    }

    /** @dev converts raw metadata into */
    function getAttributes(ShackledStructs.Metadata memory metadata)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                "{",
                '"Structure": "',
                metadata.geomSpec,
                '", "Chroma": "',
                metadata.colorScheme,
                '", "Pseudosymmetry": "',
                metadata.pseudoSymmetry,
                '", "Wireframe": "',
                metadata.wireframe,
                '", "Inversion": "',
                metadata.inversion,
                '", "Prisms": "',
                uint2str(metadata.nPrisms),
                '"}'
            );
    }

    /** @dev create and encode the token's metadata */
    function getEncodedMetadata(
        string memory image,
        ShackledStructs.Metadata memory metadata,
        uint256 tokenId
    ) internal view returns (string memory) {
        /// get attributes and description here to avoid stack too deep
        string
            memory description = '"description": "Shackled is the first general-purpose 3D renderer'
            " running on the Ethereum blockchain."
            ' Each piece represents a leap forward in on-chain computer graphics, and the collection itself is an NFT first."';
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Shackled Genesis #',
                                    uint2str(tokenId),
                                    '", ',
                                    description,
                                    ', "attributes":',
                                    getAttributes(metadata),
                                    ', "image":"',
                                    image,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    // fragment =
    // [ canvas_x, canvas_y, depth, col_x, col_y, col_z, normal_x, normal_y, normal_z, world_x, world_y, world_z ],
    /** @dev get an encoded 2d bitmap by combining the object and background fragments */
    function getEncodedBitmap(
        int256[12][] memory fragments,
        int256[5][] memory background,
        int256 canvasDim,
        bool invert
    ) internal view returns (string memory) {
        uint256 canvasDimUnsigned = uint256(canvasDim);
        bytes memory fileHeader = abi.encodePacked(
            hex"42_4d", // BM
            hex"36_04_00_00", // size of the bitmap file in bytes (14 (file header) + 40 (info header) + size of raw data (1024))
            hex"00_00_00_00", // 2x2 bytes reserved
            hex"36_00_00_00" // offset of pixels in bytes
        );
        bytes memory infoHeader = abi.encodePacked(
            hex"28_00_00_00", // size of the header in bytes (40)
            getHex(canvasDimUnsigned), // width in pixels 32
            getHex(canvasDimUnsigned), // height in pixels 32
            hex"01_00", // number of color plans (must be 1)
            hex"18_00", // number of bits per pixel (24)
            hex"00_00_00_00", // type of compression (none)
            hex"00_04_00_00", // size of the raw bitmap data (1024)
            hex"C4_0E_00_00", // horizontal resolution
            hex"C4_0E_00_00", // vertical resolution
            hex"00_00_00_00", // number of used colours
            hex"05_00_00_00" // number of important colours
        );
        bytes memory headers = abi.encodePacked(fileHeader, infoHeader);

        /// create a container for the bitmap's bytes
        bytes memory bytesArray = new bytes(3 * canvasDimUnsigned**2);

        /// write the background first so it is behind the fragments
        bytesArray = writeBackgroundToBytesArray(
            background,
            bytesArray,
            canvasDimUnsigned,
            invert
        );
        bytesArray = writeFragmentsToBytesArray(
            fragments,
            bytesArray,
            canvasDimUnsigned,
            invert
        );

        return
            string(
                abi.encodePacked(
                    "data:image/bmp;base64,",
                    Base64.encode(BytesUtils.MergeBytes(headers, bytesArray))
                )
            );
    }

    /** @dev write the fragments to the bytes array */
    function writeFragmentsToBytesArray(
        int256[12][] memory fragments,
        bytes memory bytesArray,
        uint256 canvasDimUnsigned,
        bool invert
    ) internal pure returns (bytes memory) {
        /// loop through each fragment
        /// and write it's color into bytesArray in its canvas equivelant position
        for (uint256 i = 0; i < fragments.length; i++) {
            /// check if x and y are both greater than 0
            if (
                uint256(fragments[i][0]) >= 0 && uint256(fragments[i][1]) >= 0
            ) {
                /// calculating the starting bytesArray ix for this fragment's colors
                uint256 flatIx = ((canvasDimUnsigned -
                    uint256(fragments[i][1]) -
                    1) *
                    canvasDimUnsigned +
                    (canvasDimUnsigned - uint256(fragments[i][0]) - 1)) * 3;

                /// red
                uint256 r = fragments[i][3] > 255
                    ? 255
                    : uint256(fragments[i][3]);

                /// green
                uint256 g = fragments[i][4] > 255
                    ? 255
                    : uint256(fragments[i][4]);

                /// blue
                uint256 b = fragments[i][5] > 255
                    ? 255
                    : uint256(fragments[i][5]);

                if (invert) {
                    r = 255 - r;
                    g = 255 - g;
                    b = 255 - b;
                }

                bytesArray[flatIx + 0] = bytes1(uint8(b));
                bytesArray[flatIx + 1] = bytes1(uint8(g));
                bytesArray[flatIx + 2] = bytes1(uint8(r));
            }
        }
        return bytesArray;
    }

    /** @dev write the fragments to the bytes array 
    using a separate function from above to account for variable input size
    */
    function writeBackgroundToBytesArray(
        int256[5][] memory background,
        bytes memory bytesArray,
        uint256 canvasDimUnsigned,
        bool invert
    ) internal pure returns (bytes memory) {
        /// loop through each fragment
        /// and write it's color into bytesArray in its canvas equivelant position
        for (uint256 i = 0; i < background.length; i++) {
            /// check if x and y are both greater than 0
            if (
                uint256(background[i][0]) >= 0 && uint256(background[i][1]) >= 0
            ) {
                /// calculating the starting bytesArray ix for this fragment's colors
                uint256 flatIx = (uint256(background[i][1]) *
                    canvasDimUnsigned +
                    uint256(background[i][0])) * 3;

                // red
                uint256 r = background[i][2] > 255
                    ? 255
                    : uint256(background[i][2]);

                /// green
                uint256 g = background[i][3] > 255
                    ? 255
                    : uint256(background[i][3]);

                // blue
                uint256 b = background[i][4] > 255
                    ? 255
                    : uint256(background[i][4]);

                if (invert) {
                    r = 255 - r;
                    g = 255 - g;
                    b = 255 - b;
                }

                bytesArray[flatIx + 0] = bytes1(uint8(b));
                bytesArray[flatIx + 1] = bytes1(uint8(g));
                bytesArray[flatIx + 2] = bytes1(uint8(r));
            }
        }
        return bytesArray;
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal view returns (string memory) {
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

library BytesUtils {
    function char(bytes1 b) internal view returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function bytes32string(bytes32 b32)
        internal
        view
        returns (string memory out)
    {
        bytes memory s = new bytes(64);
        for (uint32 i = 0; i < 32; i++) {
            bytes1 b = bytes1(b32[i]);
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[i * 2] = char(hi);
            s[i * 2 + 1] = char(lo);
        }
        out = string(s);
    }

    function hach(string memory value) internal view returns (string memory) {
        return bytes32string(sha256(abi.encodePacked(value)));
    }

    function MergeBytes(bytes memory a, bytes memory b)
        internal
        pure
        returns (bytes memory c)
    {
        // Store the length of the first array
        uint256 alen = a.length;
        // Store the length of BOTH arrays
        uint256 totallen = alen + b.length;
        // Count the loops required for array a (sets of 32 bytes)
        uint256 loopsa = (a.length + 31) / 32;
        // Count the loops required for array b (sets of 32 bytes)
        uint256 loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            // Load the length of both arrays to the head of the new bytes array
            mstore(m, totallen)
            // Add the contents of a to the array
            for {
                let i := 0
            } lt(i, loopsa) {
                i := add(1, i)
            } {
                mstore(
                    add(m, mul(32, add(1, i))),
                    mload(add(a, mul(32, add(1, i))))
                )
            }
            // Add the contents of b to the array
            for {
                let i := 0
            } lt(i, loopsb) {
                i := add(1, i)
            } {
                mstore(
                    add(m, add(mul(32, add(1, i)), alen)),
                    mload(add(b, mul(32, add(1, i))))
                )
            }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library ShackledStructs {
    struct Metadata {
        string colorScheme; /// name of the color scheme
        string geomSpec; /// name of the geometry specification
        uint256 nPrisms; /// number of prisms made
        string pseudoSymmetry; /// horizontal, vertical, diagonal
        string wireframe; /// enabled or disabled
        string inversion; /// enabled or disabled
    }

    struct RenderParams {
        uint256[3][] faces; /// index of verts and colorss used for each face (triangle)
        int256[3][] verts; /// x, y, z coordinates used in the geometry
        int256[3][] cols; /// colors of each vert
        int256[3] objPosition; /// position to place the object
        int256 objScale; /// scalar for the object
        int256[3][2] backgroundColor; /// color of the background (gradient)
        LightingParams lightingParams; /// parameters for the lighting
        bool perspCamera; /// true = perspective camera, false = orthographic
        bool backfaceCulling; /// whether to implement backface culling (saves gas!)
        bool invert; /// whether to invert colors in the final encoding stage
        bool wireframe; /// whether to only render edges
    }

    /// struct for testing lighting
    struct LightingParams {
        bool applyLighting; /// true = apply lighting, false = don't apply lighting
        int256 lightAmbiPower; /// power of the ambient light
        int256 lightDiffPower; /// power of the diffuse light
        int256 lightSpecPower; /// power of the specular light
        uint256 inverseShininess; /// shininess of the material
        int256[3] lightPos; /// position of the light
        int256[3] lightColSpec; /// color of the specular light
        int256[3] lightColDiff; /// color of the diffuse light
        int256[3] lightColAmbi; /// color of the ambient light
    }
}

// // SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledCoords.sol";
import "./ShackledRasteriser.sol";
import "./ShackledUtils.sol";
import "./ShackledStructs.sol";

library ShackledRenderer {
    uint256 constant outputHeight = 512;
    uint256 constant outputWidth = 512;

    /** @dev take any geometry, render it, and return a bitmap image inside an SVG 
    this can be called to render the Shackled art collection (the output of ShackledGenesis.sol)
    or any other custom made geometry

    */
    function render(
        ShackledStructs.RenderParams memory renderParams,
        int256 canvasDim,
        bool returnSVG
    ) public view returns (string memory) {
        /// prepare the fragments
        int256[12][3][] memory trisFragments = prepareGeometryForRender(
            renderParams,
            canvasDim
        );

        /// run Bresenham's line algorithm to rasterize the fragments
        int256[12][] memory fragments = ShackledRasteriser.rasterise(
            trisFragments,
            canvasDim,
            renderParams.wireframe
        );

        fragments = ShackledRasteriser.depthTesting(fragments, canvasDim);

        if (renderParams.lightingParams.applyLighting) {
            /// apply lighting (Blinn phong)
            fragments = ShackledRasteriser.lightScene(
                fragments,
                renderParams.lightingParams
            );
        }

        /// get the background
        int256[5][] memory background = ShackledRasteriser.getBackground(
            canvasDim,
            renderParams.backgroundColor
        );

        /// place each fragment in an encoded bitmap
        string memory encodedBitmap = ShackledUtils.getEncodedBitmap(
            fragments,
            background,
            canvasDim,
            renderParams.invert
        );

        if (returnSVG) {
            /// insert the bitmap into an encoded svg (to be accepted by OpenSea)
            return
                ShackledUtils.getSVGContainer(
                    encodedBitmap,
                    canvasDim,
                    outputHeight,
                    outputWidth
                );
        } else {
            return encodedBitmap;
        }
    }

    /** @dev prepare the triangles and colors for rasterization
     */
    function prepareGeometryForRender(
        ShackledStructs.RenderParams memory renderParams,
        int256 canvasDim
    ) internal view returns (int256[12][3][] memory) {
        /// convert geometry and colors from PLY standard into Shackled format
        /// create the final triangles and colors that will be rendered
        /// by pulling the numbers out of the faces array
        /// and using them to index into the verts and colors arrays
        /// make copies of each coordinate and color
        int256[3][3][] memory tris = new int256[3][3][](
            renderParams.faces.length
        );
        int256[3][3][] memory trisCols = new int256[3][3][](
            renderParams.faces.length
        );

        for (uint256 i = 0; i < renderParams.faces.length; i++) {
            for (uint256 j = 0; j < 3; j++) {
                for (uint256 k = 0; k < 3; k++) {
                    /// copy the values from verts and cols arrays
                    /// using the faces lookup array to index into them
                    tris[i][j][k] = renderParams.verts[
                        renderParams.faces[i][j]
                    ][k];
                    trisCols[i][j][k] = renderParams.cols[
                        renderParams.faces[i][j]
                    ][k];
                }
            }
        }

        /// convert the fragments from model to world space
        int256[3][] memory vertsWorldSpace = ShackledCoords
            .convertToWorldSpaceWithModelTransform(
                tris,
                renderParams.objScale,
                renderParams.objPosition
            );

        /// convert the vertices back to triangles in world space
        int256[3][3][] memory trisWorldSpace = ShackledUtils
            .unflattenVertsToTris(vertsWorldSpace);

        /// implement backface culling
        if (renderParams.backfaceCulling) {
            (trisWorldSpace, trisCols) = ShackledCoords.backfaceCulling(
                trisWorldSpace,
                trisCols
            );
        }

        /// update vertsWorldSpace
        vertsWorldSpace = ShackledUtils.flattenTris(trisWorldSpace);

        /// convert the fragments from world to camera space
        int256[3][] memory vertsCameraSpace = ShackledCoords
            .convertToCameraSpaceViaVertexShader(
                vertsWorldSpace,
                canvasDim,
                renderParams.perspCamera
            );

        /// convert the vertices back to triangles in camera space
        int256[3][3][] memory trisCameraSpace = ShackledUtils
            .unflattenVertsToTris(vertsCameraSpace);

        int256[12][3][] memory trisFragments = ShackledRasteriser
            .initialiseFragments(
                trisCameraSpace,
                trisWorldSpace,
                trisCols,
                canvasDim
            );

        return trisFragments;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledStructs.sol";
import "./ShackledMath.sol";
import "./Trigonometry.sol";

/* 
dir codes:
    0: right-left
    1: left-right
    2: up-down
    3: down-up

 sel codes:
    0: random
    1: biggest-first
    2: smallest-first
*/

library ShackledGenesis {
    uint256 constant MAX_N_ATTEMPTS = 150; // max number of attempts to find a valid triangle
    int256 constant ROT_XY_MAX = 12; // max amount of rotation in xy plane
    int256 constant MAX_CANVAS_SIZE = 32000; // max size of canvas

    /// a struct to hold vars in makeFacesVertsCols() to prevent StackTooDeep
    struct FacesVertsCols {
        uint256[3][] faces;
        int256[3][] verts;
        int256[3][] cols;
        uint256 nextColIdx;
        uint256 nextVertIdx;
        uint256 nextFaceIdx;
    }

    /** @dev generate all parameters required for the shackled renderer from a seed hash
    @param tokenHash a hash of the tokenId to be used in 'random' number generation
    */
    function generateGenesisPiece(bytes32 tokenHash)
        external
        view
        returns (
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        )
    {
        /// initial model paramaters
        renderParams.objScale = 1;
        renderParams.objPosition = [int256(0), 0, -2500];

        /// generate the geometry and colors
        (
            FacesVertsCols memory vars,
            ColorUtils.ColScheme memory colScheme,
            GeomUtils.GeomSpec memory geomSpec,
            GeomUtils.GeomVars memory geomVars
        ) = generateGeometryAndColors(tokenHash, renderParams.objPosition);

        renderParams.faces = vars.faces;
        renderParams.verts = vars.verts;
        renderParams.cols = vars.cols;

        /// use a perspective camera
        renderParams.perspCamera = true;

        if (geomSpec.id == 3) {
            renderParams.wireframe = false;
            renderParams.backfaceCulling = true;
        } else {
            /// determine wireframe trait (5% chance)
            if (GeomUtils.randN(tokenHash, "wireframe", 1, 100) > 95) {
                renderParams.wireframe = true;
                renderParams.backfaceCulling = false;
            } else {
                renderParams.wireframe = false;
                renderParams.backfaceCulling = true;
            }
        }

        if (
            colScheme.id == 2 ||
            colScheme.id == 3 ||
            colScheme.id == 7 ||
            colScheme.id == 8
        ) {
            renderParams.invert = false;
        } else {
            /// inversion (40% chance)
            renderParams.invert =
                GeomUtils.randN(tokenHash, "invert", 1, 10) > 6;
        }

        /// background colors
        renderParams.backgroundColor = [
            colScheme.bgColTop,
            colScheme.bgColBottom
        ];

        /// lighting parameters
        renderParams.lightingParams = ShackledStructs.LightingParams({
            applyLighting: true,
            lightAmbiPower: 0,
            lightDiffPower: 2000,
            lightSpecPower: 3000,
            inverseShininess: 10,
            lightColSpec: colScheme.lightCol,
            lightColDiff: colScheme.lightCol,
            lightColAmbi: colScheme.lightCol,
            lightPos: [int256(-50), 0, 0]
        });

        /// create the metadata
        metadata.colorScheme = colScheme.name;
        metadata.geomSpec = geomSpec.name;
        metadata.nPrisms = geomVars.nPrisms;

        if (geomSpec.isSymmetricX) {
            if (geomSpec.isSymmetricY) {
                metadata.pseudoSymmetry = "Diagonal";
            } else {
                metadata.pseudoSymmetry = "Horizontal";
            }
        } else if (geomSpec.isSymmetricY) {
            metadata.pseudoSymmetry = "Vertical";
        } else {
            metadata.pseudoSymmetry = "Scattered";
        }

        if (renderParams.wireframe) {
            metadata.wireframe = "Enabled";
        } else {
            metadata.wireframe = "Disabled";
        }

        if (renderParams.invert) {
            metadata.inversion = "Enabled";
        } else {
            metadata.inversion = "Disabled";
        }
    }

    /** @dev run a generative algorithm to create 3d geometries (prisms) and colors to render with Shackled
    also returns the faces and verts, which can be used to build a .obj file for in-browser rendering
     */
    function generateGeometryAndColors(
        bytes32 tokenHash,
        int256[3] memory objPosition
    )
        internal
        view
        returns (
            FacesVertsCols memory vars,
            ColorUtils.ColScheme memory colScheme,
            GeomUtils.GeomSpec memory geomSpec,
            GeomUtils.GeomVars memory geomVars
        )
    {
        /// get this geom's spec
        geomSpec = GeomUtils.generateSpec(tokenHash);

        /// create the triangles
        (
            int256[3][3][] memory tris,
            int256[] memory zFronts,
            int256[] memory zBacks
        ) = create2dTris(tokenHash, geomSpec);

        /// prismify
        geomVars = prismify(tokenHash, tris, zFronts, zBacks);

        /// generate colored faces
        /// get a color scheme
        colScheme = ColorUtils.getScheme(tokenHash, tris);

        /// get faces, verts and colors
        vars = makeFacesVertsCols(
            tokenHash,
            tris,
            geomVars,
            colScheme,
            objPosition
        );
    }

    /** @dev 'randomly' create an array of 2d triangles that will define each eventual 3d prism  */
    function create2dTris(bytes32 tokenHash, GeomUtils.GeomSpec memory geomSpec)
        internal
        view
        returns (
            int256[3][3][] memory, /// tris
            int256[] memory, /// zFronts
            int256[] memory /// zBacks
        )
    {
        /// initiate vars that will be used to store the triangle info
        GeomUtils.TriVars memory triVars;
        triVars.tris = new int256[3][3][]((geomSpec.maxPrisms + 5) * 2);
        triVars.zFronts = new int256[]((geomSpec.maxPrisms + 5) * 2);
        triVars.zBacks = new int256[]((geomSpec.maxPrisms + 5) * 2);

        /// 'randomly' initiate the starting radius
        int256 initialSize;

        if (geomSpec.forceInitialSize == 0) {
            initialSize = GeomUtils.randN(
                tokenHash,
                "size",
                geomSpec.minTriRad,
                geomSpec.maxTriRad
            );
        } else {
            initialSize = geomSpec.forceInitialSize;
        }

        /// 50% chance of 30deg rotation, 50% chance of 210deg rotation
        int256 initialRot = GeomUtils.randN(tokenHash, "rot", 0, 1) == 0
            ? int256(30)
            : int256(210);

        /// create the first triangle
        int256[3][3] memory currentTri = GeomUtils.makeTri(
            [int256(0), 0, 0],
            initialSize,
            initialRot
        );

        /// save it
        triVars.tris[0] = currentTri;

        /// calculate the first triangle's zs
        triVars.zBacks[0] = GeomUtils.calculateZ(
            currentTri,
            tokenHash,
            triVars.nextTriIdx,
            geomSpec,
            false
        );
        triVars.zFronts[0] = GeomUtils.calculateZ(
            currentTri,
            tokenHash,
            triVars.nextTriIdx,
            geomSpec,
            true
        );

        /// get the position to add the next triangle

        if (geomSpec.isSymmetricY) {
            /// override the first tri, since it is not symmetrical
            /// but temporarily save it as its needed as a reference tri
            triVars.nextTriIdx = 0;
        } else {
            triVars.nextTriIdx = 1;
        }

        /// make new triangles
        for (uint256 i = 0; i < MAX_N_ATTEMPTS; i++) {
            /// get a reference to a previous triangle
            uint256 refIdx = uint256(
                GeomUtils.randN(
                    tokenHash,
                    string(abi.encodePacked("refIdx", i)),
                    0,
                    int256(triVars.nextTriIdx) - 1
                )
            );

            /// ensure that the 'random' number generated is different in each while loop
            /// by incorporating the nAttempts and nextTriIdx into the seed modifier
            if (
                GeomUtils.randN(
                    tokenHash,
                    string(abi.encodePacked("adj", i, triVars.nextTriIdx)),
                    0,
                    100
                ) <= geomSpec.probVertOpp
            ) {
                /// attempt to recursively add vertically opposite triangles
                triVars = GeomUtils.makeVerticallyOppositeTriangles(
                    tokenHash,
                    i, // attemptNum (to create unique random seeds)
                    refIdx,
                    triVars,
                    geomSpec,
                    -1,
                    -1,
                    0 // depth (to create unique random seeds within recursion)
                );
            } else {
                /// attempt to recursively add adjacent triangles
                triVars = GeomUtils.makeAdjacentTriangles(
                    tokenHash,
                    i, // attemptNum (to create unique random seeds)
                    refIdx,
                    triVars,
                    geomSpec,
                    -1,
                    -1,
                    0 // depth (to create unique random seeds within recursion)
                );
            }

            /// can't have this many triangles
            if (triVars.nextTriIdx >= geomSpec.maxPrisms) {
                break;
            }
        }

        /// clip all the arrays to the actual number of triangles
        triVars.tris = GeomUtils.clipTrisToLength(
            triVars.tris,
            triVars.nextTriIdx
        );
        triVars.zBacks = GeomUtils.clipZsToLength(
            triVars.zBacks,
            triVars.nextTriIdx
        );
        triVars.zFronts = GeomUtils.clipZsToLength(
            triVars.zFronts,
            triVars.nextTriIdx
        );

        return (triVars.tris, triVars.zBacks, triVars.zFronts);
    }

    /** @dev prismify the initial 2d triangles output */
    function prismify(
        bytes32 tokenHash,
        int256[3][3][] memory tris,
        int256[] memory zFronts,
        int256[] memory zBacks
    ) internal view returns (GeomUtils.GeomVars memory) {
        /// initialise a struct to hold the vars we need
        GeomUtils.GeomVars memory geomVars;

        /// record the num of prisms
        geomVars.nPrisms = uint256(tris.length);

        /// figure out what point to put in the middle
        geomVars.extents = GeomUtils.getExtents(tris); // mins[3], maxs[3]

        /// scale the tris to fit in the canvas
        geomVars.width = geomVars.extents[1][0] - geomVars.extents[0][0];
        geomVars.height = geomVars.extents[1][1] - geomVars.extents[0][1];
        geomVars.extent = ShackledMath.max(geomVars.width, geomVars.height);
        geomVars.scaleNum = 2000;

        /// multiple all tris by the scale, then divide by the extent
        for (uint256 i = 0; i < tris.length; i++) {
            tris[i] = [
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][0],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                ),
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][1],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                ),
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][2],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                )
            ];
        }

        /// we may like to do some rotation, this means we get the shapes in the middle
        /// arrow up, down, left, right

        // 50% chance of x, y rotation being positive or negative
        geomVars.rotX = (GeomUtils.randN(tokenHash, "rotX", 0, 1) == 0)
            ? ROT_XY_MAX
            : -ROT_XY_MAX;

        geomVars.rotY = (GeomUtils.randN(tokenHash, "rotY", 0, 1) == 0)
            ? ROT_XY_MAX
            : -ROT_XY_MAX;

        // 50% chance to z rotation being 0 or 30
        geomVars.rotZ = (GeomUtils.randN(tokenHash, "rotZ", 0, 1) == 0)
            ? int256(0)
            : int256(30);

        /// rotate all tris around facing (z) axis
        for (uint256 i = 0; i < tris.length; i++) {
            tris[i] = GeomUtils.triRotHelp(2, tris[i], geomVars.rotZ);
        }

        geomVars.trisBack = GeomUtils.copyTris(tris);
        geomVars.trisFront = GeomUtils.copyTris(tris);

        /// front triangles need to come forward, back triangles need to go back
        for (uint256 i = 0; i < tris.length; i++) {
            for (uint256 j = 0; j < 3; j++) {
                for (uint256 k = 0; k < 3; k++) {
                    if (k == 2) {
                        /// get the z values (make sure the scale is applied)
                        geomVars.trisFront[i][j][k] = zFronts[i];
                        geomVars.trisBack[i][j][k] = zBacks[i];
                    } else {
                        /// copy the x and y values
                        geomVars.trisFront[i][j][k] = tris[i][j][k];
                        geomVars.trisBack[i][j][k] = tris[i][j][k];
                    }
                }
            }
        }

        /// rotate - order is import here (must come after prism splitting, and is dependant on z rotation)
        if (geomVars.rotZ == 0) {
            /// x then y
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                0,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotX
            );
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                1,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotY
            );
        } else {
            /// y then x
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                1,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotY
            );
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                0,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotX
            );
        }

        return geomVars;
    }

    /** @dev create verts and faces out of the geom and get their colors */
    function makeFacesVertsCols(
        bytes32 tokenHash,
        int256[3][3][] memory tris,
        GeomUtils.GeomVars memory geomVars,
        ColorUtils.ColScheme memory scheme,
        int256[3] memory objPosition
    ) internal view returns (FacesVertsCols memory vars) {
        /// the tris defined thus far are those at the front of each prism
        /// we need to calculate how many tris will then be in the final prisms (3 sides have 2 tris each, plus the front tri, = 7)
        uint256 numTrisPrisms = tris.length * 7; /// 7 tris per 3D prism (not inc. back)

        vars.faces = new uint256[3][](numTrisPrisms); /// array that holds indexes of verts needed to make each final triangle
        vars.verts = new int256[3][](tris.length * 6); /// the vertices for all final triangles
        vars.cols = new int256[3][](tris.length * 6); /// 1 col per final tri
        vars.nextColIdx = 0;
        vars.nextVertIdx = 0;
        vars.nextFaceIdx = 0;

        /// get some number of highlight triangles
        geomVars.hltPrismIdx = ColorUtils.getHighlightPrismIdxs(
            tris,
            tokenHash,
            scheme.hltNum,
            scheme.hltVarCode,
            scheme.hltSelCode
        );

        int256[3][2] memory frontExtents = GeomUtils.getExtents(
            geomVars.trisFront
        ); // mins[3], maxs[3]
        int256[3][2] memory backExtents = GeomUtils.getExtents(
            geomVars.trisBack
        ); // mins[3], maxs[3]
        int256[3][2] memory meanExtents = [
            [
                (frontExtents[0][0] + backExtents[0][0]) / 2,
                (frontExtents[0][1] + backExtents[0][1]) / 2,
                (frontExtents[0][2] + backExtents[0][2]) / 2
            ],
            [
                (frontExtents[1][0] + backExtents[1][0]) / 2,
                (frontExtents[1][1] + backExtents[1][1]) / 2,
                (frontExtents[1][2] + backExtents[1][2]) / 2
            ]
        ];

        /// apply translations such that we're at the center
        geomVars.center = ShackledMath.vector3DivScalar(
            ShackledMath.vector3Add(meanExtents[0], meanExtents[1]),
            2
        );

        geomVars.center[2] = 0;

        for (uint256 i = 0; i < tris.length; i++) {
            int256[3][6] memory prismCols;
            ColorUtils.SubScheme memory subScheme = ColorUtils.inArray(
                geomVars.hltPrismIdx,
                i
            )
                ? scheme.hlt
                : scheme.pri;

            /// get the colors for the prism
            prismCols = ColorUtils.getColForPrism(
                tokenHash,
                geomVars.trisFront[i],
                subScheme,
                meanExtents
            );

            /// save the colors (6 per prism)
            for (uint256 j = 0; j < 6; j++) {
                vars.cols[vars.nextColIdx] = prismCols[j];
                vars.nextColIdx++;
            }

            /// add 3 points (back)
            for (uint256 j = 0; j < 3; j++) {
                vars.verts[vars.nextVertIdx] = [
                    geomVars.trisBack[i][j][0],
                    geomVars.trisBack[i][j][1],
                    -geomVars.trisBack[i][j][2] /// flip the Z
                ];
                vars.nextVertIdx += 1;
            }

            /// add 3 points (front)
            for (uint256 j = 0; j < 3; j++) {
                vars.verts[vars.nextVertIdx] = [
                    geomVars.trisFront[i][j][0],
                    geomVars.trisFront[i][j][1],
                    -geomVars.trisFront[i][j][2] /// flip the Z
                ];
                vars.nextVertIdx += 1;
            }

            /// create the faces
            uint256 ii = i * 6;

            /// the orders are all important here (back is not visible)

            /// front
            vars.faces[vars.nextFaceIdx] = [ii + 3, ii + 4, ii + 5];

            /// side 1 flat
            vars.faces[vars.nextFaceIdx + 1] = [ii + 4, ii + 3, ii + 0];
            vars.faces[vars.nextFaceIdx + 2] = [ii + 0, ii + 1, ii + 4];

            /// side 2 rhs
            vars.faces[vars.nextFaceIdx + 3] = [ii + 5, ii + 4, ii + 1];
            vars.faces[vars.nextFaceIdx + 4] = [ii + 1, ii + 2, ii + 5];

            /// side 3 lhs
            vars.faces[vars.nextFaceIdx + 5] = [ii + 2, ii + 0, ii + 3];
            vars.faces[vars.nextFaceIdx + 6] = [ii + 3, ii + 5, ii + 2];

            vars.nextFaceIdx += 7;
        }

        for (uint256 i = 0; i < vars.verts.length; i++) {
            vars.verts[i] = ShackledMath.vector3Sub(
                vars.verts[i],
                geomVars.center
            );
        }
    }
}

/** Hold some functions useful for coloring in the prisms  */
library ColorUtils {
    /// a struct to hold vars within the main color scheme
    /// which can be used for both highlight (hlt) an primar (pri) colors
    struct SubScheme {
        int256[3] colA; // either the entire solid color, or one side of the gradient
        int256[3] colB; // either the same as A (solid), or different (gradient)
        bool isInnerGradient; // whether the gradient spans the triangle (true) or canvas (false)
        int256 dirCode; // which direction should the gradient be interpolated
        int256[3] jiggle; // how much to randomly jiffle the color space
        bool isJiggleInner; // does each inner vertiex get a jiggle, or is it triangle wide
        int256[3] backShift; // how much to take off the back face colors
    }

    /// a struct for each piece's color scheme
    struct ColScheme {
        string name;
        uint256 id;
        /// the primary color
        SubScheme pri;
        /// the highlight color
        SubScheme hlt;
        /// remaining parameters (not common to hlt and pri)
        uint256 hltNum;
        int256 hltSelCode;
        int256 hltVarCode;
        /// other scene colors
        int256[3] lightCol;
        int256[3] bgColTop;
        int256[3] bgColBottom;
    }

    /** @dev calculate the color of a prism
    returns an array of 6 colors (for each vertex of a prism) 
     */
    function getColForPrism(
        bytes32 tokenHash,
        int256[3][3] memory triFront,
        SubScheme memory subScheme,
        int256[3][2] memory extents
    ) external view returns (int256[3][6] memory cols) {
        if (
            subScheme.colA[0] == subScheme.colB[0] &&
            subScheme.colA[1] == subScheme.colB[1] &&
            subScheme.colA[2] == subScheme.colB[2]
        ) {
            /// just use color A (as B is the same, so there's no gradient)
            for (uint256 i = 0; i < 6; i++) {
                cols[i] = copyColor(subScheme.colA);
            }
        } else {
            /// get the colors according to the direction code
            int256[3][3] memory triFrontCopy = GeomUtils.copyTri(triFront);
            int256[3][3] memory frontTriCols = applyDirHelp(
                triFrontCopy,
                subScheme.colA,
                subScheme.colB,
                subScheme.dirCode,
                subScheme.isInnerGradient,
                extents
            );

            /// write in the same front colors as the back colors
            for (uint256 i = 0; i < 3; i++) {
                cols[i] = copyColor(frontTriCols[i]);
                cols[i + 3] = copyColor(frontTriCols[i]);
            }
        }

        /// perform the jiggling
        int256[3] memory jiggle;

        if (!subScheme.isJiggleInner) {
            /// get one set of jiggle values to use for all colors created
            jiggle = getJiggle(subScheme.jiggle, tokenHash, 0);
        }

        for (uint256 i = 0; i < 6; i++) {
            if (subScheme.isJiggleInner) {
                // jiggle again per col to create
                // use the last jiggle res in the random seed to get diff jiggles for each prism
                jiggle = getJiggle(subScheme.jiggle, tokenHash, jiggle[0]);
            }

            /// convert to hsv prior to jiggle
            int256[3] memory colHsv = rgb2hsv(
                cols[i][0],
                cols[i][1],
                cols[i][2]
            );

            /// add the jiggle to the colors in hsv space
            colHsv[0] = colHsv[0] + jiggle[0];
            colHsv[1] = colHsv[1] + jiggle[1];
            colHsv[2] = colHsv[2] + jiggle[2];

            /// convert back to rgb
            int256[3] memory colRgb = hsv2rgb(colHsv[0], colHsv[1], colHsv[2]);
            cols[i][0] = colRgb[0];
            cols[i][1] = colRgb[1];
            cols[i][2] = colRgb[2];
        }

        /// perform back shifting
        for (uint256 i = 0; i < 3; i++) {
            cols[i][0] -= subScheme.backShift[0];
            cols[i][1] -= subScheme.backShift[1];
            cols[i][2] -= subScheme.backShift[2];
        }

        /// ensure that we're in 255 range
        for (uint256 i = 0; i < 6; i++) {
            cols[i][0] = ShackledMath.max(0, ShackledMath.min(255, cols[i][0]));
            cols[i][1] = ShackledMath.max(0, ShackledMath.min(255, cols[i][1]));
            cols[i][2] = ShackledMath.max(0, ShackledMath.min(255, cols[i][2]));
        }

        return cols;
    }

    /** @dev roll a schemeId given a list of weightings */
    function getSchemeId(bytes32 tokenHash, int256[2][10] memory weightings)
        internal
        view
        returns (uint256)
    {
        int256 n = GeomUtils.randN(
            tokenHash,
            "schemedId",
            weightings[0][0],
            weightings[weightings.length - 1][1]
        );
        for (uint256 i = 0; i < weightings.length; i++) {
            if (weightings[i][0] <= n && n <= weightings[i][1]) {
                return i;
            }
        }
    }

    /** @dev make a copy of a color */
    function copyColor(int256[3] memory c)
        internal
        view
        returns (int256[3] memory)
    {
        return [c[0], c[1], c[2]];
    }

    /** @dev get a color scheme */
    function getScheme(bytes32 tokenHash, int256[3][3][] memory tris)
        external
        view
        returns (ColScheme memory colScheme)
    {
        /// 'randomly' select 1 of the 9 schemes
        uint256 schemeId = getSchemeId(
            tokenHash,
            [
                [int256(0), 1500],
                [int256(1500), 2500],
                [int256(2500), 3000],
                [int256(3000), 3100],
                [int256(3100), 5500],
                [int256(5500), 6000],
                [int256(6000), 6500],
                [int256(6500), 8000],
                [int256(8000), 9500],
                [int256(9500), 10000]
            ]
        );

        // int256 schemeId = GeomUtils.randN(tokenHash, "schemeID", 1, 9);

        /// define the color scheme to use for this piece
        /// all arrays are on the order of 1000 to remain accurate as integers
        /// will require division by 1000 later when in use

        if (schemeId == 0) {
            /// plain / beigey with a highlight, and a matching background colour
            colScheme = ColScheme({
                name: "Accentuated",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(60), 30, 25],
                    colB: [int256(205), 205, 205],
                    isInnerGradient: false,
                    dirCode: 0,
                    jiggle: [int256(13), 13, 13],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 0, 0],
                    colB: [int256(255), 50, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "hltDir", 0, 3), /// get a 'random' dir code
                    jiggle: [int256(50), 50, 50],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: uint256(GeomUtils.randN(tokenHash, "hltNum", 3, 5)), /// get a 'random' number of highlights between 3 and 5
                hltSelCode: 1, /// 'biggest' selection code
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(1), 1, 1]
            });
        } else if (schemeId == 1) {
            /// neutral overall
            colScheme = ColScheme({
                name: "Emergent",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(0), 77, 255],
                    colB: [int256(0), 255, 25],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "priDir", 2, 3), /// get a 'random' dir code (2 or 3)
                    jiggle: [int256(60), 60, 60],
                    isJiggleInner: false,
                    backShift: [int256(-255), -255, -255]
                }),
                hlt: SubScheme({
                    colA: [int256(0), 77, 255],
                    colB: [int256(0), 255, 25],
                    isInnerGradient: true,
                    dirCode: 3,
                    jiggle: [int256(60), 60, 60],
                    isJiggleInner: false,
                    backShift: [int256(-255), -255, -255]
                }),
                hltNum: uint256(GeomUtils.randN(tokenHash, "hltNum", 4, 6)), /// get a 'random' number of highlights between 4 and 6
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(255), 255, 255],
                bgColBottom: [int256(255), 255, 255]
            });
        } else if (schemeId == 2) {
            /// vaporwave
            int256 maxHighlights = ShackledMath.max(0, int256(tris.length) - 8);
            int256 minHighlights = ShackledMath.max(
                0,
                int256(maxHighlights) - 2
            );
            colScheme = ColScheme({
                name: "Sunset",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(179), 0, 179],
                    colB: [int256(0), 0, 255],
                    isInnerGradient: false,
                    dirCode: 2, /// up-down
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: [int256(0), 0, 0],
                    colB: [int256(0), 0, 0],
                    isInnerGradient: true,
                    dirCode: 3, /// down-up
                    jiggle: [int256(15), 0, 15],
                    isJiggleInner: true,
                    backShift: [int256(0), 0, 0]
                }),
                hltNum: uint256(
                    GeomUtils.randN(
                        tokenHash,
                        "hltNum",
                        minHighlights,
                        maxHighlights
                    )
                ), /// get a 'random' number of highlights between minHighlights and maxHighlights
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(250), 103, 247],
                bgColBottom: [int256(157), 104, 250]
            });
        } else if (schemeId == 3) {
            /// gold
            int256 priDirCode = GeomUtils.randN(tokenHash, "pirDir", 0, 1); /// get a 'random' dir code (0 or 1)
            colScheme = ColScheme({
                name: "Stone & Gold",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(50), 50, 50],
                    colB: [int256(100), 100, 100],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(10), 10, 10],
                    isJiggleInner: true,
                    backShift: [int256(128), 128, 128]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 197, 0],
                    colB: [int256(255), 126, 0],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(64), 64, 64]
                }),
                hltNum: 1,
                hltSelCode: 1, /// biggest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 4) {
            /// random pastel colors (sometimes black)
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Denatured",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 1), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: GeomUtils.randN(tokenHash, "hlt", 0, 1), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(127), 127, 127]
                }),
                hltNum: tris.length / 2,
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 5) {
            /// inter triangle random colors ('chameleonic')

            /// pri dir code is anything (0, 1, 2, 3)
            /// hlt dir code is oppose to pri dir code (rl <-> lr, up <-> du)
            int256 priDirCode = GeomUtils.randN(tokenHash, "pri", 0, 3); /// get a 'random' dir code (0 or 1)
            int256 hltDirCode;
            if (priDirCode == 0 || priDirCode == 1) {
                hltDirCode = priDirCode == 0 ? int256(1) : int256(0);
            } else {
                hltDirCode = priDirCode == 2 ? int256(3) : int256(2);
            }
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Chameleonic",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(0), 0, 0]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: true,
                    dirCode: hltDirCode,
                    jiggle: [int256(255), 255, 255],
                    isJiggleInner: true,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: 12,
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 6) {
            /// each prism is a different colour with some randomisation

            /// pri dir code is anything (0, 1, 2, 3)
            /// hlt dir code is oppose to pri dir code (rl <-> lr, up <-> du)
            int256 priDirCode = GeomUtils.randN(tokenHash, "pri", 0, 1); /// get a 'random' dir code (0 or 1)
            int256 hltDirCode;
            if (priDirCode == 0 || priDirCode == 1) {
                hltDirCode = priDirCode == 0 ? int256(1) : int256(0);
            } else {
                hltDirCode = priDirCode == 2 ? int256(3) : int256(2);
            }
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Gradiated",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: priDirCode,
                    jiggle: [int256(127), 127, 127],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: hltDirCode,
                    jiggle: [int256(127), 127, 127],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: 12, /// get a 'random' number of highlights between 4 and 6
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 7) {
            /// feature colour on white primary, with feature colour background
            /// calculate the feature color in hsv
            int256[3] memory hsv = [
                GeomUtils.randN(tokenHash, "hsv", 0, 255),
                230,
                255
            ];
            int256[3] memory hltColA = hsv2rgb(hsv[0], hsv[1], hsv[2]);

            colScheme = ColScheme({
                name: "Vivid Alabaster",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(255), 255, 255],
                    colB: [int256(255), 255, 255],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: hltColA,
                    colB: copyColor(hltColA), /// same as A
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// same as priDirCode
                    jiggle: [int256(25), 50, 50],
                    isJiggleInner: true,
                    backShift: [int256(180), 180, 180]
                }),
                hltNum: tris.length % 2 == 1
                    ? (tris.length / 2) + 1
                    : tris.length / 2,
                hltSelCode: GeomUtils.randN(tokenHash, "hltSel", 0, 2),
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: hsv2rgb(
                    ShackledMath.mod((hsv[0] - 9), 255),
                    105,
                    255
                ),
                bgColBottom: hsv2rgb(
                    ShackledMath.mod((hsv[0] + 9), 255),
                    105,
                    255
                )
            });
        } else if (schemeId == 8) {
            /// feature colour on black primary, with feature colour background
            /// calculate the feature color in hsv
            int256[3] memory hsv = [
                GeomUtils.randN(tokenHash, "hsv", 0, 255),
                245,
                190
            ];

            int256[3] memory hltColA = hsv2rgb(hsv[0], hsv[1], hsv[2]);

            colScheme = ColScheme({
                name: "Vivid Ink",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(0), 0, 0],
                    colB: [int256(0), 0, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: false,
                    backShift: [int256(-60), -60, -60]
                }),
                hlt: SubScheme({
                    colA: hltColA,
                    colB: copyColor(hltColA), /// same as A
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// same as priDirCode
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(-60), -60, -60]
                }),
                hltNum: tris.length % 2 == 1
                    ? (tris.length / 2) + 1
                    : tris.length / 2,
                hltSelCode: GeomUtils.randN(tokenHash, "hltSel", 0, 2),
                hltVarCode: GeomUtils.randN(tokenHash, "hltVar", 0, 2),
                lightCol: [int256(255), 255, 255],
                bgColTop: hsv2rgb(
                    ShackledMath.mod((hsv[0] - 9), 255),
                    105,
                    255
                ),
                bgColBottom: hsv2rgb(
                    ShackledMath.mod((hsv[0] + 9), 255),
                    105,
                    255
                )
            });
        } else if (schemeId == 9) {
            colScheme = ColScheme({
                name: "Pigmented",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(50), 30, 25],
                    colB: [int256(205), 205, 205],
                    isInnerGradient: false,
                    dirCode: 0,
                    jiggle: [int256(13), 13, 13],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 0, 0],
                    colB: [int256(255), 50, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "hltDir", 0, 3), /// get a 'random' dir code
                    jiggle: [int256(255), 50, 50],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: tris.length / 3,
                hltSelCode: 1, /// 'biggest' selection code
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(7), 7, 7]
            });
        } else {
            revert("invalid scheme id");
        }

        return colScheme;
    }

    /** @dev convert hsv to rgb color
    assume h, s and v and in range [0, 255]
    outputs rgb in range [0, 255]
     */
    function hsv2rgb(
        int256 h,
        int256 s,
        int256 v
    ) internal view returns (int256[3] memory res) {
        /// ensure range 0, 255
        h = ShackledMath.max(0, ShackledMath.min(255, h));
        s = ShackledMath.max(0, ShackledMath.min(255, s));
        v = ShackledMath.max(0, ShackledMath.min(255, v));

        int256 h2 = (((h % 255) * 1e3) / 255) * 360; /// convert to degress
        int256 v2 = (v * 1e3) / 255;
        int256 s2 = (s * 1e3) / 255;

        /// calculate c, x and m while scaling all by 1e3
        /// otherwise x will be too small and round to 0
        int256 c = (v2 * s2) / 1e3;

        int256 x = (c *
            (1 * 1e3 - ShackledMath.abs(((h2 / 60) % (2 * 1e3)) - (1 * 1e3))));

        x = x / 1e3;

        int256 m = v2 - c;

        if (0 <= h2 && h2 < 60000) {
            res = [c + m, x + m, m];
        } else if (60000 <= h2 && h2 < 120000) {
            res = [x + m, c + m, m];
        } else if (120000 < h2 && h2 < 180000) {
            res = [m, c + m, x + m];
        } else if (180000 < h2 && h2 < 240000) {
            res = [m, x + m, c + m];
        } else if (240000 < h2 && h2 < 300000) {
            res = [x + m, m, c + m];
        } else if (300000 < h2 && h2 < 360000) {
            res = [c + m, m, x + m];
        } else {
            res = [int256(0), 0, 0];
        }

        /// scale into correct range
        return [
            (res[0] * 255) / 1e3,
            (res[1] * 255) / 1e3,
            (res[2] * 255) / 1e3
        ];
    }

    /** @dev convert rgb to hsv 
        expects rgb to be in range [0, 255]
        outputs hsv in range [0, 255]
    */
    function rgb2hsv(
        int256 r,
        int256 g,
        int256 b
    ) internal view returns (int256[3] memory) {
        int256 r2 = (r * 1e3) / 255;
        int256 g2 = (g * 1e3) / 255;
        int256 b2 = (b * 1e3) / 255;
        int256 max = ShackledMath.max(ShackledMath.max(r2, g2), b2);
        int256 min = ShackledMath.min(ShackledMath.min(r2, g2), b2);
        int256 delta = max - min;

        /// calculate hue
        int256 h;
        if (delta != 0) {
            if (max == r2) {
                int256 _h = ((g2 - b2) * 1e3) / delta;
                h = 60 * ShackledMath.mod(_h, 6000);
            } else if (max == g2) {
                h = 60 * (((b2 - r2) * 1e3) / delta + (2000));
            } else if (max == b2) {
                h = 60 * (((r2 - g2) * 1e3) / delta + (4000));
            }
        }

        h = (h % (360 * 1e3)) / 360;

        /// calculate saturation
        int256 s;
        if (max != 0) {
            s = (delta * 1e3) / max;
        }

        /// calculate value
        int256 v = max;

        return [(h * 255) / 1e3, (s * 255) / 1e3, (v * 255) / 1e3];
    }

    /** @dev get vector of three numbers that can be used to jiggle a color */
    function getJiggle(
        int256[3] memory jiggle,
        bytes32 randomSeed,
        int256 seedModifier
    ) internal view returns (int256[3] memory) {
        return [
            jiggle[0] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("0", seedModifier)),
                    -jiggle[0],
                    jiggle[0]
                ),
            jiggle[1] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("1", seedModifier)),
                    -jiggle[1],
                    jiggle[1]
                ),
            jiggle[2] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("2", seedModifier)),
                    -jiggle[2],
                    jiggle[2]
                )
        ];
    }

    /** @dev check if a uint is in an array */
    function inArray(uint256[] memory array, uint256 value)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /** @dev a helper function to apply the direction code in interpolation */
    function applyDirHelp(
        int256[3][3] memory triFront,
        int256[3] memory colA,
        int256[3] memory colB,
        int256 dirCode,
        bool isInnerGradient,
        int256[3][2] memory extents
    ) internal view returns (int256[3][3] memory triCols) {
        uint256[3] memory order;
        if (isInnerGradient) {
            /// perform the simple 3 sort - always color by the front
            order = getOrderedPointIdxsInDir(triFront, dirCode);
        } else {
            /// order irrelevant in other case
            order = [uint256(0), 1, 2];
        }

        /// axis is 0 (horizontal) if dir code is left-right or right-left
        /// 1 (vertical) otherwise
        uint256 axis = (dirCode == 0 || dirCode == 1) ? 0 : 1;

        int256 length;
        if (axis == 0) {
            length = extents[1][0] - extents[0][0];
        } else {
            length = extents[1][1] - extents[0][1];
        }

        /// if we're interpolating across the triangle (inner)
        /// then do so by calculating the color at each point in the triangle
        for (uint256 i = 0; i < 3; i++) {
            triCols[order[i]] = interpColHelp(
                colA,
                colB,
                (isInnerGradient)
                    ? triFront[order[0]][axis]
                    : int256(-length / 2),
                (isInnerGradient)
                    ? triFront[order[2]][axis]
                    : int256(length / 2),
                triFront[order[i]][axis]
            );
        }
    }

    /** @dev a helper function to order points by index in a desired direction
     */
    function getOrderedPointIdxsInDir(int256[3][3] memory tri, int256 dirCode)
        internal
        view
        returns (uint256[3] memory)
    {
        // flip if dir is left-right or down-up
        bool flip = (dirCode == 1 || dirCode == 3) ? true : false;

        // axis is 0 if horizontal (left-right or right-left), 1 otherwise (vertical)
        uint256 axis = (dirCode == 0 || dirCode == 1) ? 0 : 1;

        /// get the values of each point in the tri (flipped as required)
        int256 f = (flip) ? int256(-1) : int256(1);
        int256 a = f * tri[0][axis];
        int256 b = f * tri[1][axis];
        int256 c = f * tri[2][axis];

        /// get the ordered indices
        uint256[3] memory ixOrd = [uint256(0), 1, 2];

        /// simplest way to sort 3 numbers
        if (a > b) {
            (a, b) = (b, a);
            (ixOrd[0], ixOrd[1]) = (ixOrd[1], ixOrd[0]);
        }
        if (a > c) {
            (a, c) = (c, a);
            (ixOrd[0], ixOrd[2]) = (ixOrd[2], ixOrd[0]);
        }
        if (b > c) {
            (b, c) = (c, b);
            (ixOrd[1], ixOrd[2]) = (ixOrd[2], ixOrd[1]);
        }
        return ixOrd;
    }

    /** @dev a helper function for linear interpolation betweet two colors*/
    function interpColHelp(
        int256[3] memory colA,
        int256[3] memory colB,
        int256 low,
        int256 high,
        int256 val
    ) internal view returns (int256[3] memory result) {
        int256 ir;
        int256 lerpScaleFactor = 1e3;
        if (high - low == 0) {
            ir = 1;
        } else {
            ir = ((val - low) * lerpScaleFactor) / (high - low);
        }

        for (uint256 i = 0; i < 3; i++) {
            /// dont allow interpolation to go below 0
            result[i] = ShackledMath.max(
                0,
                colA[i] + ((colB[i] - colA[i]) * ir) / lerpScaleFactor
            );
        }
    }

    /** @dev get indexes of the prisms to use highlight coloring*/
    function getHighlightPrismIdxs(
        int256[3][3][] memory tris,
        bytes32 tokenHash,
        uint256 nHighlights,
        int256 varCode,
        int256 selCode
    ) internal view returns (uint256[] memory idxs) {
        nHighlights = nHighlights < tris.length ? nHighlights : tris.length;

        ///if we just want random triangles then there's no need to sort
        if (selCode == 0) {
            idxs = ShackledMath.randomIdx(
                tokenHash,
                uint256(nHighlights),
                tris.length - 1
            );
        } else {
            idxs = getSortedTrisIdxs(tris, nHighlights, varCode, selCode);
        }
    }

    /** @dev return the index of the tris sorted by sel code
    @param selCode will be 1 (biggest first) or 2 (smallest first)
    */
    function getSortedTrisIdxs(
        int256[3][3][] memory tris,
        uint256 nHighlights,
        int256 varCode,
        int256 selCode
    ) internal view returns (uint256[] memory) {
        // determine the sort order
        int256 orderFactor = (selCode == 2) ? int256(1) : int256(-1);
        /// get the list of triangle sizes
        int256[] memory sizes = new int256[](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            if (varCode == 0) {
                // use size
                sizes[i] = GeomUtils.getRadiusLen(tris[i]) * orderFactor;
            } else if (varCode == 1) {
                // use x
                sizes[i] = GeomUtils.getCenterVec(tris[i])[0] * orderFactor;
            } else if (varCode == 2) {
                // use y
                sizes[i] = GeomUtils.getCenterVec(tris[i])[1] * orderFactor;
            }
        }
        /// initialise the index array
        uint256[] memory idxs = new uint256[](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            idxs[i] = i;
        }
        /// run a boilerplate insertion sort over the index array
        for (uint256 i = 1; i < tris.length; i++) {
            int256 key = sizes[i];
            uint256 j = i - 1;
            while (j > 0 && key < sizes[j]) {
                sizes[j + 1] = sizes[j];
                idxs[j + 1] = idxs[j];
                j--;
            }
            sizes[j + 1] = key;
            idxs[j + 1] = i;
        }

        uint256 nToCull = tris.length - nHighlights;
        assembly {
            mstore(idxs, sub(mload(idxs), nToCull))
        }

        return idxs;
    }
}

/**
Hold some functions externally to reduce contract size for mainnet deployment
 */
library GeomUtils {
    /// misc constants
    int256 constant MIN_INT = type(int256).min;
    int256 constant MAX_INT = type(int256).max;

    /// constants for doing trig
    int256 constant PI = 3141592653589793238; // pi as an 18 decimal value (wad)

    /// parameters that control geometry creation
    struct GeomSpec {
        string name;
        int256 id;
        int256 forceInitialSize;
        uint256 maxPrisms;
        int256 minTriRad;
        int256 maxTriRad;
        bool varySize;
        int256 depthMultiplier;
        bool isSymmetricX;
        bool isSymmetricY;
        int256 probVertOpp;
        int256 probAdjRec;
        int256 probVertOppRec;
    }

    /// variables uses when creating the initial 2d triangles
    struct TriVars {
        uint256 nextTriIdx;
        int256[3][3][] tris;
        int256[3][3] tri;
        int256 zBackRef;
        int256 zFrontRef;
        int256[] zFronts;
        int256[] zBacks;
        bool recursiveAttempt;
    }

    /// variables used when creating 3d prisms
    struct GeomVars {
        int256 rotX;
        int256 rotY;
        int256 rotZ;
        int256[3][2] extents;
        int256[3] center;
        int256 width;
        int256 height;
        int256 extent;
        int256 scaleNum;
        uint256[] hltPrismIdx;
        int256[3][3][] trisBack;
        int256[3][3][] trisFront;
        uint256 nPrisms;
    }

    /** @dev generate parameters that will control how the geometry is built */
    function generateSpec(bytes32 tokenHash)
        external
        view
        returns (GeomSpec memory spec)
    {
        //  'randomly' select 1 of possible geometry specifications
        uint256 specId = getSpecId(
            tokenHash,
            [
                [int256(0), 1000],
                [int256(1000), 3000],
                [int256(3000), 3500],
                [int256(3500), 4500],
                [int256(4500), 5000],
                [int256(5000), 6000],
                [int256(6000), 8000]
            ]
        );

        bool isSymmetricX = GeomUtils.randN(tokenHash, "symmX", 0, 2) > 0;
        bool isSymmetricY = GeomUtils.randN(tokenHash, "symmY", 0, 2) > 0;

        int256 defaultDepthMultiplier = randN(tokenHash, "depthMult", 80, 120);
        int256 defaultMinTriRad = 4800;
        int256 defaultMaxTriRad = defaultMinTriRad * 3;
        uint256 defaultMaxPrisms = uint256(
            randN(tokenHash, "maxPrisms", 8, 16)
        );

        if (specId == 0) {
            /// all vertically opposite
            spec = GeomSpec({
                id: 0,
                name: "Verticalized",
                forceInitialSize: (defaultMinTriRad * 5) / 2,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 100,
                probVertOppRec: 100,
                probAdjRec: 0,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 1) {
            /// fully adjacent
            spec = GeomSpec({
                id: 1,
                name: "Adjoint",
                forceInitialSize: (defaultMinTriRad * 5) / 2,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 0,
                probVertOppRec: 0,
                probAdjRec: 100,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 2) {
            /// few but big
            spec = GeomSpec({
                id: 2,
                name: "Cetacean",
                forceInitialSize: 0,
                maxPrisms: 8,
                minTriRad: defaultMinTriRad * 3,
                maxTriRad: defaultMinTriRad * 4,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 3) {
            /// lots but small
            spec = GeomSpec({
                id: 3,
                name: "Swarm",
                forceInitialSize: 0,
                maxPrisms: 16,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMinTriRad * 2,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 0,
                probAdjRec: 0,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 4) {
            /// all same size
            spec = GeomSpec({
                id: 4,
                name: "Isomorphic",
                forceInitialSize: 0,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: false,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 5) {
            /// trains
            spec = GeomSpec({
                id: 5,
                name: "Extruded",
                forceInitialSize: 0,
                maxPrisms: 10,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 6) {
            /// flatpack
            spec = GeomSpec({
                id: 6,
                name: "Uniform",
                forceInitialSize: 0,
                maxPrisms: 12,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else {
            revert("invalid specId");
        }
    }

    /** @dev make triangles to the side of a reference triangle */
    function makeAdjacentTriangles(
        bytes32 tokenHash,
        uint256 attemptNum,
        uint256 refIdx,
        TriVars memory triVars,
        GeomSpec memory geomSpec,
        int256 overrideSideIdx,
        int256 overrideScale,
        int256 depth
    ) public view returns (TriVars memory) {
        /// get the side index (0, 1 or 2)
        int256 sideIdx;
        if (overrideSideIdx == -1) {
            sideIdx = randN(
                tokenHash,
                string(abi.encodePacked("sideIdx", attemptNum, depth)),
                0,
                2
            );
        } else {
            sideIdx = overrideSideIdx;
        }

        /// get the scale
        /// this value is scaled up by 1e3 (desired range is 0.333 to 0.8)
        /// the scale will be divided out when used
        int256 scale;
        if (geomSpec.varySize) {
            if (overrideScale == -1) {
                scale = randN(
                    tokenHash,
                    string(abi.encodePacked("scaleAdj", attemptNum, depth)),
                    333,
                    800
                );
            } else {
                scale = overrideScale;
            }
        } else {
            scale = 1e3;
        }

        /// make a new triangle
        int256[3][3] memory newTri = makeTriAdjacent(
            tokenHash,
            geomSpec,
            attemptNum,
            triVars.tris[refIdx],
            sideIdx,
            scale,
            depth
        );

        /// set the zbackref and frontbackref
        triVars.zBackRef = -1; /// calculate a new z back
        triVars.zFrontRef = -1; /// calculate a new z ftont

        // try to add the triangle, and use the reference z height
        triVars.recursiveAttempt = false;
        bool wasAdded = attemptToAddTri(newTri, tokenHash, triVars, geomSpec);

        if (wasAdded) {
            // run again
            if (
                randN(
                    tokenHash,
                    string(
                        abi.encodePacked("addAdjRecursive", attemptNum, depth)
                    ),
                    0,
                    100
                ) <= geomSpec.probAdjRec
            ) {
                triVars = makeAdjacentTriangles(
                    tokenHash,
                    attemptNum,
                    triVars.nextTriIdx - 1,
                    triVars,
                    geomSpec,
                    sideIdx,
                    666, /// always make the next one 2/3 scale
                    depth + 1
                );
            }
        }
        return triVars;
    }

    /** @dev make triangles vertically opposite a reference triangle */
    function makeVerticallyOppositeTriangles(
        bytes32 tokenHash,
        uint256 attemptNum,
        uint256 refIdx,
        TriVars memory triVars,
        GeomSpec memory geomSpec,
        int256 overrideSideIdx,
        int256 overrideScale,
        int256 depth
    ) public view returns (TriVars memory) {
        /// get the side index (0, 1 or 2)
        int256 sideIdx;
        if (overrideSideIdx == -1) {
            sideIdx = randN(
                tokenHash,
                string(abi.encodePacked("vertOppSideIdx", attemptNum, depth)),
                0,
                2
            );
        } else {
            sideIdx = overrideSideIdx;
        }

        /// get the scale
        /// this value is scaled up by 1e3
        /// use attemptNum in seedModifier to ensure unique values each attempt
        int256 scale;
        if (geomSpec.varySize) {
            if (overrideScale == -1) {
                if (
                    // prettier-ignore
                    randN(
                        tokenHash,
                        string(abi.encodePacked("vertOppScale1", attemptNum, depth)),
                        0,
                        100
                    ) > 33
                ) {
                    // prettier-ignore
                    if (
                        randN(
                            tokenHash,
                            string(abi.encodePacked("vertOppScale2", attemptNum, depth)  ),
                            0,
                            100
                        ) > 50
                    ) {
                        scale = 1000; /// desired = 1 (same scale)
                    } else {
                        scale = 500; /// desired = 0.5 (half scale)
                    }
                } else {
                    scale = 2000; /// desired = 2 (double scale)
                }
            } else {
                scale = overrideScale;
            }
        } else {
            scale = 1e3;
        }

        /// make a new triangle
        int256[3][3] memory newTri = makeTriVertOpp(
            triVars.tris[refIdx],
            geomSpec,
            sideIdx,
            scale
        );

        /// set the zbackref and frontbackref
        triVars.zBackRef = -1; /// calculate a new z back
        triVars.zFrontRef = triVars.zFronts[refIdx];

        // try to add the triangle, and use the reference z height
        triVars.recursiveAttempt = false;
        bool wasAdded = attemptToAddTri(newTri, tokenHash, triVars, geomSpec);

        if (wasAdded) {
            /// run again
            if (
                randN(
                    tokenHash,
                    string(
                        abi.encodePacked("recursiveVertOpp", attemptNum, depth)
                    ),
                    0,
                    100
                ) <= geomSpec.probVertOppRec
            ) {
                triVars = makeVerticallyOppositeTriangles(
                    tokenHash,
                    attemptNum,
                    refIdx,
                    triVars,
                    geomSpec,
                    sideIdx,
                    666, /// always make the next one 2/3 scale
                    depth + 1
                );
            }
        }

        return triVars;
    }

    /** @dev place a triangle vertically opposite over the given point 
    @param refTri the reference triangle to base the new triangle on
    */
    function makeTriVertOpp(
        int256[3][3] memory refTri,
        GeomSpec memory geomSpec,
        int256 sideIdx,
        int256 scale
    ) internal view returns (int256[3][3] memory) {
        /// calculate the center of the reference triangle
        /// add and then divide by 1e3 (the factor by which scale is scaled up)
        int256 centerDist = (getRadiusLen(refTri) * (1e3 + scale)) / 1e3;

        /// get the new triangle's direction
        int256 newAngle = sideIdx *
            120 +
            60 +
            (isTriPointingUp(refTri) ? int256(60) : int256(0));

        int256 spacing = 64;

        /// calculate the true offset
        int256[3] memory offset = vector3RotateZ(
            [int256(0), centerDist + spacing, 0],
            newAngle
        );

        int256[3] memory centerVec = getCenterVec(refTri);
        int256[3] memory newCentre = ShackledMath.vector3Add(centerVec, offset);
        /// return the new triangle (div by 1e3 to account for scale)
        int256 newRadius = (scale * getRadiusLen(refTri)) / 1e3;
        newRadius = ShackledMath.min(geomSpec.maxTriRad, newRadius);
        newAngle -= 210;
        return makeTri(newCentre, newRadius, newAngle);
    }

    /** @dev make a new adjacent triangle
     */
    function makeTriAdjacent(
        bytes32 tokenHash,
        GeomSpec memory geomSpec,
        uint256 attemptNum,
        int256[3][3] memory refTri,
        int256 sideIdx,
        int256 scale,
        int256 depth
    ) internal view returns (int256[3][3] memory) {
        /// calculate the center of the new triangle
        /// add and then divide by 1e3 (the factor by which scale is scaled up)

        int256 centerDist = (getPerpLen(refTri) * (1e3 + scale)) / 1e3;

        /// get the new triangle's direction
        int256 newAngle = sideIdx *
            120 +
            (isTriPointingUp(refTri) ? int256(60) : int256(0));

        /// determine the direction of the offset offset
        /// get a unique random seed each attempt to ensure variation

        // prettier-ignore
        int256 offsetDirection = randN(
            tokenHash,
            string(abi.encodePacked("lateralOffset", attemptNum, depth)),
            0, 
            1
        ) 
        * 2 - 1;

        /// put if off to one side of the triangle if it's smaller
        /// scale is on order of 1e3
        int256 lateralOffset = (offsetDirection *
            (1e3 - scale) *
            getSideLen(refTri)) / 1e3;

        /// make a gap between the triangles
        int256 spacing = 6000;

        /// calculate the true offset
        int256[3] memory offset = vector3RotateZ(
            [lateralOffset, centerDist + spacing, 0],
            newAngle
        );

        int256[3] memory newCentre = ShackledMath.vector3Add(
            getCenterVec(refTri),
            offset
        );

        /// return the new triangle (div by 1e3 to account for scale)
        int256 newRadius = (scale * getRadiusLen(refTri)) / 1e3;
        newRadius = ShackledMath.min(geomSpec.maxTriRad, newRadius);
        newAngle -= 30;
        return makeTri(newCentre, newRadius, newAngle);
    }

    /** @dev  
    create a triangle centered at centre, 
    with length from centre to point of radius
    */
    function makeTri(
        int256[3] memory centre,
        int256 radius,
        int256 angle
    ) internal view returns (int256[3][3] memory tri) {
        /// create a vector to rotate around 3 times
        int256[3] memory offset = [radius, 0, 0];

        /// make 3 points of the tri
        for (uint256 i = 0; i < 3; i++) {
            int256 armAngle = 120 * int256(i);
            int256[3] memory offsetVec = vector3RotateZ(
                offset,
                armAngle + angle
            );

            tri[i] = ShackledMath.vector3Add(centre, offsetVec);
        }
    }

    /** @dev rotate a vector around x */
    function vector3RotateX(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new y and z (scaling down to account for trig scaling)
        int256 y = ((v[1] * cos) - (v[2] * sin)) / 1e18;
        int256 z = ((v[1] * sin) + (v[2] * cos)) / 1e18;
        return [v[0], y, z];
    }

    /** @dev rotate a vector around y */
    function vector3RotateY(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new x and z (scaling down to account for trig scaling)
        int256 x = ((v[0] * cos) - (v[2] * sin)) / 1e18;
        int256 z = ((v[0] * sin) + (v[2] * cos)) / 1e18;
        return [x, v[1], z];
    }

    /** @dev rotate a vector around z */
    function vector3RotateZ(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new x and y (scaling down to account for trig scaling)
        int256 x = ((v[0] * cos) - (v[1] * sin)) / 1e18;
        int256 y = ((v[0] * sin) + (v[1] * cos)) / 1e18;
        return [x, y, v[2]];
    }

    /** @dev calculate sin and cos of an angle */
    function trigHelper(int256 deg)
        internal
        view
        returns (int256 cos, int256 sin)
    {
        /// deal with negative degrees here, since Trigonometry.sol can't
        int256 n360 = (ShackledMath.abs(deg) / 360) + 1;
        deg = (deg + (360 * n360)) % 360;
        uint256 rads = uint256((deg * PI) / 180);
        /// calculate radians (in 1e18 space)
        cos = Trigonometry.cos(rads);
        sin = Trigonometry.sin(rads);
    }

    /** @dev Get the 3d vector at the center of a triangle */
    function getCenterVec(int256[3][3] memory tri)
        internal
        view
        returns (int256[3] memory)
    {
        return
            ShackledMath.vector3DivScalar(
                ShackledMath.vector3Add(
                    ShackledMath.vector3Add(tri[0], tri[1]),
                    tri[2]
                ),
                3
            );
    }

    /** @dev Get the length from the center of a triangle to point*/
    function getRadiusLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        return
            ShackledMath.vector3Len(
                ShackledMath.vector3Sub(getCenterVec(tri), tri[0])
            );
    }

    /** @dev Get the length from any point on triangle to other point (equilateral)*/
    function getSideLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        // len * 0.886
        return (getRadiusLen(tri) * 8660) / 10000;
    }

    /** @dev Get the shortes length from center of triangle to side */
    function getPerpLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        return getRadiusLen(tri) / 2;
    }

    /** @dev Determine if a triangle is pointing up*/
    function isTriPointingUp(int256[3][3] memory tri)
        internal
        view
        returns (bool)
    {
        int256 centerY = getCenterVec(tri)[1];
        /// count how many verts are above this y value
        int256 nAbove = 0;
        for (uint256 i = 0; i < 3; i++) {
            if (tri[i][1] > centerY) {
                nAbove++;
            }
        }
        return nAbove == 1;
    }

    /** @dev check if two triangles are close */
    function areTrisClose(int256[3][3] memory tri1, int256[3][3] memory tri2)
        internal
        view
        returns (bool)
    {
        int256 lenBetweenCenters = ShackledMath.vector3Len(
            ShackledMath.vector3Sub(getCenterVec(tri1), getCenterVec(tri2))
        );
        return lenBetweenCenters < (getPerpLen(tri1) + getPerpLen(tri2));
    }

    /** @dev check if two triangles have overlapping points*/
    function areTrisPointsOverlapping(
        int256[3][3] memory tri1,
        int256[3][3] memory tri2
    ) internal view returns (bool) {
        /// check triangle a against b
        if (
            isPointInTri(tri1, tri2[0]) ||
            isPointInTri(tri1, tri2[1]) ||
            isPointInTri(tri1, tri2[2])
        ) {
            return true;
        }

        /// check triangle b against a
        if (
            isPointInTri(tri2, tri1[0]) ||
            isPointInTri(tri2, tri1[1]) ||
            isPointInTri(tri2, tri1[2])
        ) {
            return true;
        }

        /// otherwise they mustn't be overlapping
        return false;
    }

    /** @dev calculate if a point is in a tri*/
    function isPointInTri(int256[3][3] memory tri, int256[3] memory p)
        internal
        view
        returns (bool)
    {
        int256[3] memory p1 = tri[0];
        int256[3] memory p2 = tri[1];
        int256[3] memory p3 = tri[2];
        int256 alphaNum = (p2[1] - p3[1]) *
            (p[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p[1] - p3[1]);

        int256 alphaDenom = (p2[1] - p3[1]) *
            (p1[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p1[1] - p3[1]);

        int256 betaNum = (p3[1] - p1[1]) *
            (p[0] - p3[0]) +
            (p1[0] - p3[0]) *
            (p[1] - p3[1]);

        int256 betaDenom = (p2[1] - p3[1]) *
            (p1[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p1[1] - p3[1]);

        if (alphaDenom == 0 || betaDenom == 0) {
            return false;
        } else {
            int256 alpha = (alphaNum * 1e6) / alphaDenom;
            int256 beta = (betaNum * 1e6) / betaDenom;

            int256 gamma = 1e6 - alpha - beta;
            return alpha > 0 && beta > 0 && gamma > 0;
        }
    }

    /** @dev check all points of the tri to see if it overlaps with any other tris
     */
    function isTriOverlappingWithTris(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx
    ) internal view returns (bool) {
        /// check against all other tris added thus fat
        for (uint256 i = 0; i < nextTriIdx; i++) {
            if (
                areTrisClose(tri, tris[i]) ||
                areTrisPointsOverlapping(tri, tris[i])
            ) {
                return true;
            }
        }
        return false;
    }

    function isPointCloseToLine(
        int256[3] memory p,
        int256[3] memory l1,
        int256[3] memory l2
    ) internal view returns (bool) {
        int256 x0 = p[0];
        int256 y0 = p[1];
        int256 x1 = l1[0];
        int256 y1 = l1[1];
        int256 x2 = l2[0];
        int256 y2 = l2[1];
        int256 distanceNum = ShackledMath.abs(
            (x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)
        );
        int256 distanceDenom = ShackledMath.hypot((x2 - x1), (y2 - y1));
        int256 distance = distanceNum / distanceDenom;
        if (distance < 8) {
            return true;
        }
    }

    /** compare a triangles points against the lines of other tris */
    function isTrisPointsCloseToLines(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx
    ) internal view returns (bool) {
        for (uint256 i = 0; i < nextTriIdx; i++) {
            for (uint256 p = 0; p < 3; p++) {
                if (isPointCloseToLine(tri[p], tris[i][0], tris[i][1])) {
                    return true;
                }
                if (isPointCloseToLine(tri[p], tris[i][1], tris[i][2])) {
                    return true;
                }
                if (isPointCloseToLine(tri[p], tris[i][2], tris[i][0])) {
                    return true;
                }
            }
        }
    }

    /** @dev check if tri to add meets certain criteria */
    function isTriLegal(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx,
        int256 minTriRad
    ) internal view returns (bool) {
        // check radius first as point checks will fail
        // if the radius is too small
        if (getRadiusLen(tri) < minTriRad) {
            return false;
        }
        return (!isTriOverlappingWithTris(tri, tris, nextTriIdx) &&
            !isTrisPointsCloseToLines(tri, tris, nextTriIdx));
    }

    /** @dev helper function to add triangles */
    function attemptToAddTri(
        int256[3][3] memory tri,
        bytes32 tokenHash,
        TriVars memory triVars,
        GeomSpec memory geomSpec
    ) internal view returns (bool added) {
        bool isLegal = isTriLegal(
            tri,
            triVars.tris,
            triVars.nextTriIdx,
            geomSpec.minTriRad
        );
        if (isLegal && triVars.nextTriIdx < geomSpec.maxPrisms) {
            // add the triangle
            triVars.tris[triVars.nextTriIdx] = tri;
            added = true;

            // add the new zs
            if (triVars.zBackRef == -1) {
                /// z back ref is not provided, calculate it
                triVars.zBacks[triVars.nextTriIdx] = calculateZ(
                    tri,
                    tokenHash,
                    triVars.nextTriIdx,
                    geomSpec,
                    false
                );
            } else {
                /// use the provided z back (from the ref)
                triVars.zBacks[triVars.nextTriIdx] = triVars.zBackRef;
            }
            if (triVars.zFrontRef == -1) {
                /// z front ref is not provided, calculate it
                triVars.zFronts[triVars.nextTriIdx] = calculateZ(
                    tri,
                    tokenHash,
                    triVars.nextTriIdx,
                    geomSpec,
                    true
                );
            } else {
                /// use the provided z front (from the ref)
                triVars.zFronts[triVars.nextTriIdx] = triVars.zFrontRef;
            }

            // increment the tris counter
            triVars.nextTriIdx += 1;

            // if we're using any type of symmetry then attempt to add a symmetric triangle
            // only do this recursively once
            if (
                (geomSpec.isSymmetricX || geomSpec.isSymmetricY) &&
                (!triVars.recursiveAttempt)
            ) {
                int256[3][3] memory symTri = copyTri(tri);

                if (geomSpec.isSymmetricX) {
                    symTri[0][0] = -symTri[0][0];
                    symTri[1][0] = -symTri[1][0];
                    symTri[2][0] = -symTri[2][0];
                    // symCenter[0] = -symCenter[0];
                }

                if (geomSpec.isSymmetricY) {
                    symTri[0][1] = -symTri[0][1];
                    symTri[1][1] = -symTri[1][1];
                    symTri[2][1] = -symTri[2][1];
                    // symCenter[1] = -symCenter[1];
                }

                if (
                    (geomSpec.isSymmetricX || geomSpec.isSymmetricY) &&
                    !(geomSpec.isSymmetricX && geomSpec.isSymmetricY)
                ) {
                    symTri = [symTri[2], symTri[1], symTri[0]];
                }

                triVars.recursiveAttempt = true;
                triVars.zBackRef = triVars.zBacks[triVars.nextTriIdx - 1];
                triVars.zFrontRef = triVars.zFronts[triVars.nextTriIdx - 1];
                attemptToAddTri(symTri, tokenHash, triVars, geomSpec);
            }
        }
    }

    /** @dev rotate a triangle by x, y, or z 
    @param axis 0 = x, 1 = y, 2 = z
    */
    function triRotHelp(
        int256 axis,
        int256[3][3] memory tri,
        int256 rot
    ) internal view returns (int256[3][3] memory) {
        if (axis == 0) {
            return [
                vector3RotateX(tri[0], rot),
                vector3RotateX(tri[1], rot),
                vector3RotateX(tri[2], rot)
            ];
        } else if (axis == 1) {
            return [
                vector3RotateY(tri[0], rot),
                vector3RotateY(tri[1], rot),
                vector3RotateY(tri[2], rot)
            ];
        } else if (axis == 2) {
            return [
                vector3RotateZ(tri[0], rot),
                vector3RotateZ(tri[1], rot),
                vector3RotateZ(tri[2], rot)
            ];
        }
    }

    /** @dev a helper to run rotation functions on back/front triangles */
    function triBfHelp(
        int256 axis,
        int256[3][3][] memory trisBack,
        int256[3][3][] memory trisFront,
        int256 rot
    ) internal view returns (int256[3][3][] memory, int256[3][3][] memory) {
        int256[3][3][] memory trisBackNew = new int256[3][3][](trisBack.length);
        int256[3][3][] memory trisFrontNew = new int256[3][3][](
            trisFront.length
        );

        for (uint256 i = 0; i < trisBack.length; i++) {
            trisBackNew[i] = triRotHelp(axis, trisBack[i], rot);
            trisFrontNew[i] = triRotHelp(axis, trisFront[i], rot);
        }

        return (trisBackNew, trisFrontNew);
    }

    /** @dev get the maximum extent of the geometry (vertical or horizontal) */
    function getExtents(int256[3][3][] memory tris)
        internal
        view
        returns (int256[3][2] memory)
    {
        int256 minX = MAX_INT;
        int256 maxX = MIN_INT;
        int256 minY = MAX_INT;
        int256 maxY = MIN_INT;
        int256 minZ = MAX_INT;
        int256 maxZ = MIN_INT;

        for (uint256 i = 0; i < tris.length; i++) {
            for (uint256 j = 0; j < tris[i].length; j++) {
                minX = ShackledMath.min(minX, tris[i][j][0]);
                maxX = ShackledMath.max(maxX, tris[i][j][0]);
                minY = ShackledMath.min(minY, tris[i][j][1]);
                maxY = ShackledMath.max(maxY, tris[i][j][1]);
                minZ = ShackledMath.min(minZ, tris[i][j][2]);
                maxZ = ShackledMath.max(maxZ, tris[i][j][2]);
            }
        }
        return [[minX, minY, minZ], [maxX, maxY, maxZ]];
    }

    /** @dev go through each triangle and apply a 'height' */
    function calculateZ(
        int256[3][3] memory tri,
        bytes32 tokenHash,
        uint256 nextTriIdx,
        GeomSpec memory geomSpec,
        bool front
    ) internal view returns (int256) {
        int256 h;
        string memory seedMod = string(abi.encodePacked("calcZ", nextTriIdx));
        if (front) {
            if (geomSpec.id == 6) {
                h = 1;
            } else {
                if (randN(tokenHash, seedMod, 0, 10) > 9) {
                    if (randN(tokenHash, seedMod, 0, 10) > 3) {
                        h = 10;
                    } else {
                        h = 22;
                    }
                } else {
                    if (randN(tokenHash, seedMod, 0, 10) > 5) {
                        h = 8;
                    } else {
                        h = 1;
                    }
                }
            }
        } else {
            if (geomSpec.id == 6) {
                h = -1;
            } else {
                if (geomSpec.id == 5) {
                    h = -randN(tokenHash, seedMod, 2, 20);
                } else {
                    h = -2;
                }
            }
        }
        if (geomSpec.id == 5) {
            h += 10;
        }
        return h * geomSpec.depthMultiplier;
    }

    /** @dev roll a specId given a list of weightings */
    function getSpecId(bytes32 tokenHash, int256[2][7] memory weightings)
        internal
        view
        returns (uint256)
    {
        int256 n = GeomUtils.randN(
            tokenHash,
            "specId",
            weightings[0][0],
            weightings[weightings.length - 1][1]
        );
        for (uint256 i = 0; i < weightings.length; i++) {
            if (weightings[i][0] <= n && n <= weightings[i][1]) {
                return i;
            }
        }
    }

    /** @dev get a random number between two numbers
    with a uniform probability distribution
    @param randomSeed a hash that we can use to 'randomly' get a number 
    @param seedModifier some string to make the result unique for this tokenHash
    @param min the minimum number (inclusive)
    @param max the maximum number (inclusive)

    examples:
        to get binary output (0 or 1), set min as 0 and max as 1
        
     */
    function randN(
        bytes32 randomSeed,
        string memory seedModifier,
        int256 min,
        int256 max
    ) internal view returns (int256) {
        /// use max() to ensure modulo != 0
        return
            int256(
                uint256(keccak256(abi.encodePacked(randomSeed, seedModifier))) %
                    uint256(ShackledMath.max(1, (max + 1 - min)))
            ) + min;
    }

    /** @dev clip an array of tris to a certain length (to trim empty tail slots) */
    function clipTrisToLength(int256[3][3][] memory arr, uint256 desiredLen)
        internal
        view
        returns (int256[3][3][] memory)
    {
        uint256 n = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), n))
        }
        return arr;
    }

    /** @dev clip an array of Z values to a certain length (to trim empty tail slots) */
    function clipZsToLength(int256[] memory arr, uint256 desiredLen)
        internal
        view
        returns (int256[] memory)
    {
        uint256 n = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), n))
        }
        return arr;
    }

    /** @dev make a copy of a triangle */
    function copyTri(int256[3][3] memory tri)
        internal
        view
        returns (int256[3][3] memory)
    {
        return [
            [tri[0][0], tri[0][1], tri[0][2]],
            [tri[1][0], tri[1][1], tri[1][2]],
            [tri[2][0], tri[2][1], tri[2][2]]
        ];
    }

    /** @dev make a copy of an array of triangles */
    function copyTris(int256[3][3][] memory tris)
        internal
        view
        returns (int256[3][3][] memory)
    {
        int256[3][3][] memory newTris = new int256[3][3][](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            newTris[i] = copyTri(tris[i]);
        }
        return newTris;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

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

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledUtils.sol";
import "./ShackledMath.sol";

library ShackledCoords {
    /** @dev scale and translate the verts
    this can be effectively disabled with a scale of 1 and translate of [0, 0, 0]
     */
    function convertToWorldSpaceWithModelTransform(
        int256[3][3][] memory tris,
        int256 scale,
        int256[3] memory position
    ) external view returns (int256[3][] memory) {
        int256[3][] memory verts = ShackledUtils.flattenTris(tris);

        // Scale model matrices are easy, just multiply through by the scale value
        int256[3][] memory scaledVerts = new int256[3][](verts.length);

        for (uint256 i = 0; i < verts.length; i++) {
            scaledVerts[i][0] = verts[i][0] * scale + position[0];
            scaledVerts[i][1] = verts[i][1] * scale + position[1];
            scaledVerts[i][2] = verts[i][2] * scale + position[2];
        }
        return scaledVerts;
    }

    /** @dev run backfaceCulling to save future operations on faces that aren't seen by the camera*/
    function backfaceCulling(
        int256[3][3][] memory trisWorldSpace,
        int256[3][3][] memory trisCols
    )
        external
        view
        returns (
            int256[3][3][] memory culledTrisWorldSpace,
            int256[3][3][] memory culledTrisCols
        )
    {
        culledTrisWorldSpace = new int256[3][3][](trisWorldSpace.length);
        culledTrisCols = new int256[3][3][](trisCols.length);

        uint256 nextIx;

        for (uint256 i = 0; i < trisWorldSpace.length; i++) {
            int256[3] memory v1 = trisWorldSpace[i][0];
            int256[3] memory v2 = trisWorldSpace[i][1];
            int256[3] memory v3 = trisWorldSpace[i][2];
            int256[3] memory norm = ShackledMath.crossProduct(
                ShackledMath.vector3Sub(v1, v2),
                ShackledMath.vector3Sub(v2, v3)
            );
            /// since shackled has a static positioned camera at the origin,
            /// the points are already in view space, relaxing the backfaceCullingCond
            int256 backfaceCullingCond = ShackledMath.vector3Dot(v1, norm);
            if (backfaceCullingCond < 0) {
                culledTrisWorldSpace[nextIx] = trisWorldSpace[i];
                culledTrisCols[nextIx] = trisCols[i];
                nextIx++;
            }
        }
        /// remove any empty slots
        uint256 nToCull = culledTrisWorldSpace.length - nextIx;
        /// cull uneeded tris
        assembly {
            mstore(
                culledTrisWorldSpace,
                sub(mload(culledTrisWorldSpace), nToCull)
            )
        }
        /// cull uneeded cols
        assembly {
            mstore(culledTrisCols, sub(mload(culledTrisCols), nToCull))
        }
    }

    /**@dev calculate verts in camera space */
    function convertToCameraSpaceViaVertexShader(
        int256[3][] memory vertsWorldSpace,
        int256 canvasDim,
        bool perspCamera
    ) external view returns (int256[3][] memory) {
        // get the camera matrix as a numerator and denominator
        int256[4][4][2] memory cameraMatrix;
        if (perspCamera) {
            cameraMatrix = getCameraMatrixPersp();
        } else {
            cameraMatrix = getCameraMatrixOrth(canvasDim);
        }

        int256[4][4] memory nM = cameraMatrix[0]; // camera matrix numerator
        int256[4][4] memory dM = cameraMatrix[1]; // camera matrix denominator

        int256[3][] memory verticesCameraSpace = new int256[3][](
            vertsWorldSpace.length
        );

        for (uint256 i = 0; i < vertsWorldSpace.length; i++) {
            // Convert from 3D to 4D homogenous coordinate system
            int256[3] memory vert = vertsWorldSpace[i];

            // Make a copy of vert ("homoVertex")
            int256[] memory hv = new int256[](vert.length + 1);

            for (uint256 j = 0; j < vert.length; j++) {
                hv[j] = vert[j];
            }

            // Insert 1 at final position in copy of vert
            hv[hv.length - 1] = 1;

            int256 x = ((hv[0] * nM[0][0]) / dM[0][0]) +
                ((hv[1] * nM[0][1]) / dM[0][1]) +
                ((hv[2] * nM[0][2]) / dM[0][2]) +
                (nM[0][3] / dM[0][3]);

            int256 y = ((hv[0] * nM[1][0]) / dM[1][0]) +
                ((hv[1] * nM[1][1]) / dM[1][1]) +
                ((hv[2] * nM[1][2]) / dM[1][2]) +
                (nM[1][3] / dM[1][0]);

            int256 z = ((hv[0] * nM[2][0]) / dM[2][0]) +
                ((hv[1] * nM[2][1]) / dM[2][1]) +
                ((hv[2] * nM[2][2]) / dM[2][2]) +
                (nM[2][3] / dM[2][3]);

            int256 w = ((hv[0] * nM[3][0]) / dM[3][0]) +
                ((hv[1] * nM[3][1]) / dM[3][1]) +
                ((hv[2] * nM[3][2]) / dM[3][2]) +
                (nM[3][3] / dM[3][3]);

            if (w != 1) {
                x = (x * 1e3) / w;
                y = (y * 1e3) / w;
                z = (z * 1e3) / w;
            }

            // Turn it back into a 3-vector
            // Add it to the ordered list
            verticesCameraSpace[i] = [x, y, z];
        }

        return verticesCameraSpace;
    }

    /** @dev generate an orthographic camera matrix */
    function getCameraMatrixOrth(int256 canvasDim)
        internal
        pure
        returns (int256[4][4][2] memory)
    {
        int256 canvasHalf = canvasDim / 2;

        // Left, right, top, bottom
        int256 r = ShackledMath.abs(canvasHalf);
        int256 l = -canvasHalf;
        int256 t = ShackledMath.abs(canvasHalf);
        int256 b = -canvasHalf;

        // Z settings (near and far)
        /// multiplied by 1e3
        int256 n = 1;
        int256 f = 1024;

        // Get the orthographic transform matrix
        // as a numerator and denominator

        int256[4][4] memory cameraMatrixNum = [
            [int256(2), 0, 0, -(r + l)],
            [int256(0), 2, 0, -(t + b)],
            [int256(0), 0, -2, -(f + n)],
            [int256(0), 0, 0, 1]
        ];

        int256[4][4] memory cameraMatrixDen = [
            [int256(r - l), 1, 1, (r - l)],
            [int256(1), (t - b), 1, (t - b)],
            [int256(1), 1, (f - n), (f - n)],
            [int256(1), 1, 1, 1]
        ];

        int256[4][4][2] memory cameraMatrix = [
            cameraMatrixNum,
            cameraMatrixDen
        ];

        return cameraMatrix;
    }

    /** @dev generate a perspective camera matrix */
    function getCameraMatrixPersp()
        internal
        pure
        returns (int256[4][4][2] memory)
    {
        // Z settings (near and far)
        /// multiplied by 1e3
        int256 n = 500;
        int256 f = 501;

        // Get the perspective transform matrix
        // as a numerator and denominator

        // parameter = 1 / tan(fov in degrees / 2)
        // 0.1763 = 1 / tan(160 / 2)
        // 1.428 = 1 / tan(70 / 2)
        // 1.732 = 1 / tan(60 / 2)
        // 2.145 = 1 / tan(50 / 2)

        int256[4][4] memory cameraMatrixNum = [
            [int256(2145), 0, 0, 0],
            [int256(0), 2145, 0, 0],
            [int256(0), 0, f, -f * n],
            [int256(0), 0, 1, 0]
        ];

        int256[4][4] memory cameraMatrixDen = [
            [int256(1000), 1, 1, 1],
            [int256(1), 1000, 1, 1],
            [int256(1), 1, f - n, f - n],
            [int256(1), 1, 1, 1]
        ];

        int256[4][4][2] memory cameraMatrix = [
            cameraMatrixNum,
            cameraMatrixDen
        ];

        return cameraMatrix;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledUtils.sol";
import "./ShackledMath.sol";
import "./ShackledStructs.sol";

library ShackledRasteriser {
    /// define some constant lighting parameters
    int256 constant fidelity = int256(100); /// an extra paramater to improve numeric resolution
    int256 constant lightAmbiPower = int256(1); // Base light colour // was 0.5
    int256 constant lightDiffPower = int256(3e9); // Diffused light on surface relative strength
    int256 constant lightSpecPower = int256(1e7); // Specular reflection on surface relative strength
    uint256 constant inverseShininess = 10; // 'sharpness' of specular light on surface

    /// define a scale factor to use in lerp to avoid rounding errors
    int256 constant lerpScaleFactor = 1e3;

    /// storing variables used in the fragment lighting
    struct LightingVars {
        int256[3] fragCol;
        int256[3] fragNorm;
        int256[3] fragPos;
        int256[3] V;
        int256 vMag;
        int256[3] N;
        int256 nMag;
        int256[3] L;
        int256 lMag;
        int256 falloff;
        int256 lnDot;
        int256 lambertian;
    }

    /// store variables used in Bresenham's line algorithm
    struct BresenhamsVars {
        int256 x;
        int256 y;
        int256 dx;
        int256 dy;
        int256 sx;
        int256 sy;
        int256 err;
        int256 e2;
    }

    /// store variables used when running the scanline algorithm
    struct ScanlineVars {
        int256 left;
        int256 right;
        int256[12] leftFrag;
        int256[12] rightFrag;
        int256 dx;
        int256 ir;
        int256 newFragRow;
        int256 newFragCol;
    }

    /** @dev initialise the fragments
        fragments are defined as:
        [
            canvas_x, canvas_y, depth,
            col_x, col_y, col_z,
            normal_x, normal_y, normal_z,
            world_x, world_y, world_z
        ]
        
     */
    function initialiseFragments(
        int256[3][3][] memory trisCameraSpace,
        int256[3][3][] memory trisWorldSpace,
        int256[3][3][] memory trisCols,
        int256 canvasDim
    ) external view returns (int256[12][3][] memory) {
        /// make an array containing the fragments of each triangle (groups of 3 frags)
        int256[12][3][] memory trisFragments = new int256[12][3][](
            trisCameraSpace.length
        );

        // First convert from camera space to screen space within each triangle
        for (uint256 t = 0; t < trisCameraSpace.length; t++) {
            int256[3][3] memory tri = trisCameraSpace[t];

            /// initialise an array for three fragments, each of len 9
            int256[12][3] memory triFragments;

            // First calculate the fragments that belong to defined vertices
            for (uint256 v = 0; v < 3; v++) {
                int256[12] memory fragment;

                // first convert to screen space
                // mapping from -1e3 -> 1e3 to account for the original geom being on order of 1e3
                fragment[0] = ShackledMath.mapRangeToRange(
                    tri[v][0],
                    -1e3,
                    1e3,
                    0,
                    canvasDim
                );
                fragment[1] = ShackledMath.mapRangeToRange(
                    tri[v][1],
                    -1e3,
                    1e3,
                    0,
                    canvasDim
                );

                fragment[2] = tri[v][2];

                // Now calculate the normal using the cross product of the edge vectors. This needs to be
                // done in world space coordinates
                int256[3] memory thisV = trisWorldSpace[t][(v + 0) % 3];
                int256[3] memory nextV = trisWorldSpace[t][(v + 1) % 3];
                int256[3] memory prevV = trisWorldSpace[t][(v + 2) % 3];

                int256[3] memory norm = ShackledMath.crossProduct(
                    ShackledMath.vector3Sub(prevV, thisV),
                    ShackledMath.vector3Sub(thisV, nextV)
                );

                // Now attach the colour (in 0 -> 255 space)
                fragment[3] = (trisCols[t][v][0]);
                fragment[4] = (trisCols[t][v][1]);
                fragment[5] = (trisCols[t][v][2]);

                // And the normal (inverted)
                fragment[6] = -norm[0];
                fragment[7] = -norm[1];
                fragment[8] = -norm[2];

                // And the world position of this vertex to the frag
                fragment[9] = thisV[0];
                fragment[10] = thisV[1];
                fragment[11] = thisV[2];

                // These are just the fragments attached to
                // the given vertices
                triFragments[v] = fragment;
            }

            trisFragments[t] = triFragments;
        }

        return trisFragments;
    }

    /** @dev rasterize fragments onto a canvas
     */
    function rasterise(
        int256[12][3][] memory trisFragments,
        int256 canvasDim,
        bool wireframe
    ) external view returns (int256[12][] memory) {
        /// determine the upper limits of the inner Bresenham's result
        uint256 canvasHypot = uint256(ShackledMath.hypot(canvasDim, canvasDim));

        /// initialise a new array
        /// for each trisFragments we will get 3 results from bresenhams
        /// maximum of 1 per pixel (canvasDim**2)
        int256[12][] memory fragments = new int256[12][](
            3 * uint256(canvasDim)**2
        );
        uint256 nextFragmentsIx = 0;

        for (uint256 t = 0; t < trisFragments.length; t++) {
            // prepare the variables required
            int256[12] memory fa;
            int256[12] memory fb;
            uint256 nextBresTriFragmentIx = 0;

            /// create an array to hold the bresenham results
            /// this may cause an out of bounds error if there are a very large number of fragments
            /// (e.g. many that are 'off screen')
            int256[12][] memory bresTriFragments = new int256[12][](
                canvasHypot * 10
            );

            // for each pair of fragments, run bresenhams and extend bresTriFragments with the output
            // this replaces the three push(...modified_bresenhams_algorhtm) statements in JS
            for (uint256 i = 0; i < 3; i++) {
                if (i == 0) {
                    fa = trisFragments[t][0];
                    fb = trisFragments[t][1];
                } else if (i == 1) {
                    fa = trisFragments[t][1];
                    fb = trisFragments[t][2];
                } else {
                    fa = trisFragments[t][2];
                    fb = trisFragments[t][0];
                }

                // run the bresenhams algorithm
                (
                    bresTriFragments,
                    nextBresTriFragmentIx
                ) = runBresenhamsAlgorithm(
                    fa,
                    fb,
                    canvasDim,
                    bresTriFragments,
                    nextBresTriFragmentIx
                );
            }

            bresTriFragments = ShackledUtils.clipArray12ToLength(
                bresTriFragments,
                nextBresTriFragmentIx
            );

            if (wireframe) {
                /// only store the edges
                for (uint256 j = 0; j < bresTriFragments.length; j++) {
                    fragments[nextFragmentsIx] = bresTriFragments[j];
                    nextFragmentsIx++;
                }
            } else {
                /// fill the triangle
                (fragments, nextFragmentsIx) = runScanline(
                    bresTriFragments,
                    fragments,
                    nextFragmentsIx,
                    canvasDim
                );
            }
        }

        fragments = ShackledUtils.clipArray12ToLength(
            fragments,
            nextFragmentsIx
        );

        return fragments;
    }

    /** @dev run Bresenham's line algorithm on a pair of fragments
     */
    function runBresenhamsAlgorithm(
        int256[12] memory f1,
        int256[12] memory f2,
        int256 canvasDim,
        int256[12][] memory bresTriFragments,
        uint256 nextBresTriFragmentIx
    ) internal view returns (int256[12][] memory, uint256) {
        /// initiate a new set of vars
        BresenhamsVars memory vars;

        int256[12] memory fa;
        int256[12] memory fb;

        /// determine which fragment has a greater magnitude
        /// and set it as the destination (always order a given pair of edges the same)
        if (
            (f1[0]**2 + f1[1]**2 + f1[2]**2) < (f2[0]**2 + f2[1]**2 + f2[2]**2)
        ) {
            fa = f1;
            fb = f2;
        } else {
            fa = f2;
            fb = f1;
        }

        vars.x = fa[0];
        vars.y = fa[1];

        vars.dx = ShackledMath.abs(fb[0] - fa[0]);
        vars.dy = -ShackledMath.abs(fb[1] - fa[1]);
        int256 mag = ShackledMath.hypot(vars.dx, -vars.dy);

        if (fa[0] < fb[0]) {
            vars.sx = 1;
        } else {
            vars.sx = -1;
        }

        if (fa[1] < fb[1]) {
            vars.sy = 1;
        } else {
            vars.sy = -1;
        }

        vars.err = vars.dx + vars.dy;
        vars.e2 = 0;

        // get the bresenhams output for this fragment pair (fa & fb)

        if (mag == 0) {
            bresTriFragments[nextBresTriFragmentIx] = fa;
            bresTriFragments[nextBresTriFragmentIx + 1] = fb;
            nextBresTriFragmentIx += 2;
        } else {
            // when mag is not 0,
            // the length of the result will be max of upperLimitInner
            // but will be clipped to remove any empty slots
            (bresTriFragments, nextBresTriFragmentIx) = bresenhamsInner(
                vars,
                mag,
                fa,
                fb,
                canvasDim,
                bresTriFragments,
                nextBresTriFragmentIx
            );
        }
        return (bresTriFragments, nextBresTriFragmentIx);
    }

    /** @dev run the inner loop of Bresenham's line algorithm on a pair of fragments
     * (preventing stack too deep)
     */
    function bresenhamsInner(
        BresenhamsVars memory vars,
        int256 mag,
        int256[12] memory fa,
        int256[12] memory fb,
        int256 canvasDim,
        int256[12][] memory bresTriFragments,
        uint256 nextBresTriFragmentIx
    ) internal view returns (int256[12][] memory, uint256) {
        // define variables to be used in the inner loop
        int256 ir;
        int256 h;

        /// loop through all fragments
        while (!(vars.x == fb[0] && vars.y == fb[1])) {
            /// get hypotenuse length of fragment a
            h = ShackledMath.hypot(fa[0] - vars.x, fa[1] - vars.y);
            assembly {
                ir := div(mul(lerpScaleFactor, h), mag)
            }

            // only add the fragment if it falls within the canvas

            /// create a new fragment by linear interpolation between a and b
            int256[12] memory newFragment = ShackledMath.vector12Lerp(
                fa,
                fb,
                ir,
                lerpScaleFactor
            );
            newFragment[0] = vars.x;
            newFragment[1] = vars.y;

            /// save this fragment
            bresTriFragments[nextBresTriFragmentIx] = newFragment;
            ++nextBresTriFragmentIx;

            /// update variables to use in next iteration
            vars.e2 = 2 * vars.err;
            if (vars.e2 >= vars.dy) {
                vars.err += vars.dy;
                vars.x += vars.sx;
            }
            if (vars.e2 <= vars.dx) {
                vars.err += vars.dx;
                vars.y += vars.sy;
            }
        }

        /// save fragment 2
        bresTriFragments[nextBresTriFragmentIx] = fb;
        ++nextBresTriFragmentIx;

        return (bresTriFragments, nextBresTriFragmentIx);
    }

    /** @dev run the scan line algorithm to fill the raster
     */
    function runScanline(
        int256[12][] memory bresTriFragments,
        int256[12][] memory fragments,
        uint256 nextFragmentsIx,
        int256 canvasDim
    ) internal view returns (int256[12][] memory, uint256) {
        /// make a 2d array with length = num of output rows

        (
            int256[][] memory rowFragIndices,
            uint256[] memory nextIxFragRows
        ) = getRowFragIndices(bresTriFragments, canvasDim);

        /// initialise a struct to hold the scanline vars
        ScanlineVars memory slVars;

        // Now iterate through the list of fragments that live in a single row
        for (uint256 i = 0; i < rowFragIndices.length; i++) {
            /// Get the left most fragment
            slVars.left = 4096;

            /// Get the right most fragment
            slVars.right = -4096;

            /// loop through the fragments in this row
            /// and check that a fragment was written to this row
            for (uint256 j = 0; j < nextIxFragRows[i]; j++) {
                /// What's the current fragment that we're looking at
                int256 fragX = bresTriFragments[uint256(rowFragIndices[i][j])][
                    0
                ];

                // if it's lefter than our current most left frag then its the new left frag
                if (fragX < slVars.left) {
                    slVars.left = fragX;
                    slVars.leftFrag = bresTriFragments[
                        uint256(rowFragIndices[i][j])
                    ];
                }
                // if it's righter than our current most right frag then its the new right frag
                if (fragX > slVars.right) {
                    slVars.right = fragX;
                    slVars.rightFrag = bresTriFragments[
                        uint256(rowFragIndices[i][j])
                    ];
                }
            }

            /// now we need to scan from the left to the right fragment
            /// and interpolate as we go
            slVars.dx = slVars.right - slVars.left + 1;

            /// get the row that we're on
            slVars.newFragRow = slVars.leftFrag[1];

            /// check that the new frag's row will be in the canvas bounds
            if (slVars.newFragRow >= 0 && slVars.newFragRow < canvasDim) {
                if (slVars.dx > int256(0)) {
                    for (int256 j = 0; j < slVars.dx; j++) {
                        /// calculate the column of the new fragment (its position in the scan)
                        slVars.newFragCol = slVars.leftFrag[0] + j;

                        /// check that the new frag's column will be in the canvas bounds
                        if (
                            slVars.newFragCol >= 0 &&
                            slVars.newFragCol < canvasDim
                        ) {
                            slVars.ir = (j * lerpScaleFactor) / slVars.dx;

                            /// make a new fragment by linear interpolation between left and right frags
                            fragments[nextFragmentsIx] = ShackledMath
                                .vector12Lerp(
                                    slVars.leftFrag,
                                    slVars.rightFrag,
                                    slVars.ir,
                                    lerpScaleFactor
                                );
                            /// update its position
                            fragments[nextFragmentsIx][0] = slVars.newFragCol;
                            fragments[nextFragmentsIx][1] = slVars.newFragRow;
                            nextFragmentsIx++;
                        }
                    }
                }
            }
        }

        return (fragments, nextFragmentsIx);
    }

    /** @dev get the row indices of each fragment in preparation for the scanline alg
     */
    function getRowFragIndices(
        int256[12][] memory bresTriFragments,
        int256 canvasDim
    )
        internal
        view
        returns (int256[][] memory, uint256[] memory nextIxFragRows)
    {
        uint256 canvasDimUnsigned = uint256(canvasDim);

        // define the length of each outer array so we can push items into it using nextIxFragRows
        int256[][] memory rowFragIndices = new int256[][](canvasDimUnsigned);

        // the inner rows can't be longer than bresTriFragments
        for (uint256 i = 0; i < canvasDimUnsigned; i++) {
            rowFragIndices[i] = new int256[](bresTriFragments.length);
        }

        // make an array the tracks for each row how many items have been pushed into it
        uint256[] memory nextIxFragRows = new uint256[](canvasDimUnsigned);

        for (uint256 f = 0; f < bresTriFragments.length; f++) {
            // get the row index
            uint256 rowIx = uint256(bresTriFragments[f][1]); // canvas_y

            if (rowIx >= 0 && rowIx < canvasDimUnsigned) {
                // get the ix of the next item to be added to the row

                rowFragIndices[rowIx][nextIxFragRows[rowIx]] = int256(f);
                ++nextIxFragRows[rowIx];
            }
        }
        return (rowFragIndices, nextIxFragRows);
    }

    /** @dev run depth-testing on all fragments
     */
    function depthTesting(int256[12][] memory fragments, int256 canvasDim)
        external
        view
        returns (int256[12][] memory)
    {
        uint256 canvasDimUnsigned = uint256(canvasDim);
        /// create a 2d array to hold the zValues of the fragments
        int256[][] memory zValues = ShackledMath.get2dArray(
            canvasDimUnsigned,
            canvasDimUnsigned,
            0
        );

        /// create a 2d array to hold the fragIndex of the fragments
        /// as their depth is compared
        int256[][] memory fragIndex = ShackledMath.get2dArray(
            canvasDimUnsigned,
            canvasDimUnsigned,
            -1 /// -1 so we can check if a fragment was written to this location
        );

        int256[12][] memory culledFrags = new int256[12][](fragments.length);
        uint256 nextFragIx = 0;

        /// iterate through all fragments
        /// and store the index of the fragment with the largest z value
        /// at each x, y coordinate

        for (uint256 i = 0; i < fragments.length; i++) {
            int256[12] memory frag = fragments[i];

            /// x and y must be uint for indexing
            uint256 fragX = uint256(frag[0]);
            uint256 fragY = uint256(frag[1]);

            // console.log("checking frag", i, "z:");
            // console.logInt(frag[2]);

            if (
                (fragX < canvasDimUnsigned) &&
                (fragY < canvasDimUnsigned) &&
                fragX >= 0 &&
                fragY >= 0
            ) {
                // if this is the first fragment seen at (fragX, fragY), ie if fragIndex == 0, add it
                // or if this frag is closer (lower z value) than the current frag at (fragX, fragY), add it
                if (
                    fragIndex[fragX][fragY] == -1 ||
                    frag[2] >= zValues[fragX][fragY]
                ) {
                    zValues[fragX][fragY] = frag[2];
                    fragIndex[fragX][fragY] = int256(i);
                }
            }
        }

        /// save only the fragments with prefered z values
        for (uint256 x = 0; x < canvasDimUnsigned; x++) {
            for (uint256 y = 0; y < canvasDimUnsigned; y++) {
                int256 fragIx = fragIndex[x][y];
                /// ensure we have a valid index
                if (fragIndex[x][y] != -1) {
                    culledFrags[nextFragIx] = fragments[uint256(fragIx)];
                    nextFragIx++;
                }
            }
        }

        return ShackledUtils.clipArray12ToLength(culledFrags, nextFragIx);
    }

    /** @dev apply lighting to the scene and update fragments accordingly
     */
    function lightScene(
        int256[12][] memory fragments,
        ShackledStructs.LightingParams memory lp
    ) external view returns (int256[12][] memory) {
        /// create a struct for the variables to prevent stack too deep
        LightingVars memory lv;

        // calculate a constant lighting vector and its magniture
        lv.L = lp.lightPos;
        lv.lMag = ShackledMath.vector3Len(lv.L);

        for (uint256 f = 0; f < fragments.length; f++) {
            /// get the fragment's color, norm and position
            lv.fragCol = [fragments[f][3], fragments[f][4], fragments[f][5]];
            lv.fragNorm = [fragments[f][6], fragments[f][7], fragments[f][8]];
            lv.fragPos = [fragments[f][9], fragments[f][10], fragments[f][11]];

            /// calculate the direction to camera / viewer and its magnitude
            lv.V = ShackledMath.vector3MulScalar(lv.fragPos, -1);
            lv.vMag = ShackledMath.vector3Len(lv.V);

            /// calculate the direction of the fragment normaland its magnitude
            lv.N = lv.fragNorm;
            lv.nMag = ShackledMath.vector3Len(lv.N);

            /// calculate the light vector per-fragment
            // lv.L = ShackledMath.vector3Sub(lp.lightPos, lv.fragPos);
            // lv.lMag = ShackledMath.vector3Len(lv.L);
            lv.falloff = lv.lMag**2; /// lighting intensity fall over the scene
            lv.lnDot = ShackledMath.vector3Dot(lv.L, lv.N);

            /// implement double-side rendering to account for flipped normals
            lv.lambertian = ShackledMath.abs(lv.lnDot);

            int256 specular;

            if (lv.lambertian > 0) {
                int256[3] memory normedL = ShackledMath.vector3NormX(
                    lv.L,
                    fidelity
                );
                int256[3] memory normedV = ShackledMath.vector3NormX(
                    lv.V,
                    fidelity
                );

                int256[3] memory H = ShackledMath.vector3Add(normedL, normedV);

                int256 hnDot = int256(
                    ShackledMath.vector3Dot(
                        ShackledMath.vector3NormX(H, fidelity),
                        ShackledMath.vector3NormX(lv.N, fidelity)
                    )
                );

                specular = calculateSpecular(
                    lp.lightSpecPower,
                    hnDot,
                    fidelity,
                    lp.inverseShininess
                );
            }

            // Calculate the colour and write it into the fragment
            int256[3] memory colAmbi = ShackledMath.vector3Add(
                lv.fragCol,
                ShackledMath.vector3MulScalar(
                    lp.lightColAmbi,
                    lp.lightAmbiPower
                )
            );

            /// finalise and color the diffuse lighting
            int256[3] memory colDiff = ShackledMath.vector3MulScalar(
                lp.lightColDiff,
                ((lp.lightDiffPower * lv.lambertian) / (lv.lMag * lv.nMag)) /
                    lv.falloff
            );

            /// finalise and color the specular lighting
            int256[3] memory colSpec = ShackledMath.vector3DivScalar(
                ShackledMath.vector3MulScalar(lp.lightColSpec, specular),
                lv.falloff
            );

            // add up the colour components
            int256[3] memory col = ShackledMath.vector3Add(
                ShackledMath.vector3Add(colAmbi, colDiff),
                colSpec
            );

            /// update the fragment's colour in place
            fragments[f][3] = col[0];
            fragments[f][4] = col[1];
            fragments[f][5] = col[2];
        }
        return fragments;
    }

    /** @dev calculate the specular lighting parameter */
    function calculateSpecular(
        int256 lightSpecPower,
        int256 hnDot,
        int256 fidelity,
        uint256 inverseShininess
    ) internal pure returns (int256 specular) {
        int256 specAngle = hnDot > int256(0) ? hnDot : int256(0);
        assembly {
            specular := sdiv(
                mul(lightSpecPower, exp(specAngle, inverseShininess)),
                exp(fidelity, mul(inverseShininess, 2))
            )
        }
    }

    /** @dev get background gradient that fills the canvas */
    function getBackground(
        int256 canvasDim,
        int256[3][2] memory backgroundColor
    ) external view returns (int256[5][] memory) {
        int256[5][] memory background = new int256[5][](uint256(canvasDim**2));

        int256 w = canvasDim;
        uint256 nextIx = 0;

        for (int256 i = 0; i < canvasDim; i++) {
            for (int256 j = 0; j < canvasDim; j++) {
                // / write coordinates of background pixel
                background[nextIx][0] = j; /// x
                background[nextIx][1] = i; /// y

                // / write colours of background pixel
                // / get weighted average of top and bottom color according to row (i)
                background[nextIx][2] = /// r
                    ((backgroundColor[0][0] * i) +
                        (backgroundColor[1][0] * (w - i))) /
                    w;

                background[nextIx][3] = /// g
                    ((backgroundColor[0][1] * i) +
                        (backgroundColor[1][1] * (w - i))) /
                    w;

                background[nextIx][4] = /// b
                    ((backgroundColor[0][2] * i) +
                        (backgroundColor[1][2] * (w - i))) /
                    w;

                ++nextIx;
            }
        }
        return background;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library ShackledMath {
    /** @dev Get the minimum of two numbers */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /** @dev Get the maximum of two numbers */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /** @dev perform a modulo operation, with support for negative numbers */
    function mod(int256 n, int256 m) internal pure returns (int256) {
        if (n < 0) {
            return ((n % m) + m) % m;
        } else {
            return n % m;
        }
    }

    /** @dev 'randomly' select n numbers between 0 and m 
    (useful for getting a randomly sampled index)
    */
    function randomIdx(
        bytes32 seedModifier,
        uint256 n, // number of elements to select
        uint256 m // max value of elements
    ) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            result[i] =
                uint256(keccak256(abi.encodePacked(seedModifier, i))) %
                m;
        }
        return result;
    }

    /** @dev create a 2d array and fill with a single value */
    function get2dArray(
        uint256 m,
        uint256 q,
        int256 value
    ) internal pure returns (int256[][] memory) {
        /// Create a matrix of values with dimensions (m, q)
        int256[][] memory rows = new int256[][](m);
        for (uint256 i = 0; i < m; i++) {
            int256[] memory row = new int256[](q);
            for (uint256 j = 0; j < q; j++) {
                row[j] = value;
            }
            rows[i] = row;
        }
        return rows;
    }

    /** @dev get the absolute of a number
     */
    function abs(int256 x) internal pure returns (int256) {
        assembly {
            if slt(x, 0) {
                x := sub(0, x)
            }
        }
        return x;
    }

    /** @dev get the square root of a number
     */
    function sqrt(int256 y) internal pure returns (int256 z) {
        assembly {
            if sgt(y, 3) {
                z := y
                let x := add(div(y, 2), 1)
                for {

                } slt(x, z) {

                } {
                    z := x
                    x := div(add(div(y, x), x), 2)
                }
            }
            if and(slt(y, 4), sgt(y, 0)) {
                z := 1
            }
        }
    }

    /** @dev get the hypotenuse of a triangle given the length of 2 sides
     */
    function hypot(int256 x, int256 y) internal pure returns (int256) {
        int256 sumsq;
        assembly {
            let xsq := mul(x, x)
            let ysq := mul(y, y)
            sumsq := add(xsq, ysq)
        }

        return sqrt(sumsq);
    }

    /** @dev addition between two vectors (size 3)
     */
    function vector3Add(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, add(mload(v1), mload(v2)))
            mstore(
                add(result, 0x20),
                add(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
            )
            mstore(
                add(result, 0x40),
                add(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev subtraction between two vectors (size 3)
     */
    function vector3Sub(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, sub(mload(v1), mload(v2)))
            mstore(
                add(result, 0x20),
                sub(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
            )
            mstore(
                add(result, 0x40),
                sub(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev multiply a vector (size 3) by a constant
     */
    function vector3MulScalar(int256[3] memory v, int256 a)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, mul(mload(v), a))
            mstore(add(result, 0x20), mul(mload(add(v, 0x20)), a))
            mstore(add(result, 0x40), mul(mload(add(v, 0x40)), a))
        }
    }

    /** @dev divide a vector (size 3) by a constant
     */
    function vector3DivScalar(int256[3] memory v, int256 a)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, sdiv(mload(v), a))
            mstore(add(result, 0x20), sdiv(mload(add(v, 0x20)), a))
            mstore(add(result, 0x40), sdiv(mload(add(v, 0x40)), a))
        }
    }

    /** @dev get the length of a vector (size 3)
     */
    function vector3Len(int256[3] memory v) internal pure returns (int256) {
        int256 res;
        assembly {
            let x := mload(v)
            let y := mload(add(v, 0x20))
            let z := mload(add(v, 0x40))
            res := add(add(mul(x, x), mul(y, y)), mul(z, z))
        }
        return sqrt(res);
    }

    /** @dev scale and then normalise a vector (size 3)
     */
    function vector3NormX(int256[3] memory v, int256 fidelity)
        internal
        pure
        returns (int256[3] memory result)
    {
        int256 l = vector3Len(v);
        assembly {
            mstore(result, sdiv(mul(fidelity, mload(add(v, 0x40))), l))
            mstore(
                add(result, 0x20),
                sdiv(mul(fidelity, mload(add(v, 0x20))), l)
            )
            mstore(add(result, 0x40), sdiv(mul(fidelity, mload(v)), l))
        }
    }

    /** @dev get the dot-product of two vectors (size 3)
     */
    function vector3Dot(int256[3] memory v1, int256[3] memory v2)
        internal
        view
        returns (int256 result)
    {
        assembly {
            result := add(
                add(
                    mul(mload(v1), mload(v2)),
                    mul(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
                ),
                mul(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev get the cross product of two vectors (size 3)
     */
    function crossProduct(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(
                result,
                sub(
                    mul(mload(add(v1, 0x20)), mload(add(v2, 0x40))),
                    mul(mload(add(v1, 0x40)), mload(add(v2, 0x20)))
                )
            )
            mstore(
                add(result, 0x20),
                sub(
                    mul(mload(add(v1, 0x40)), mload(v2)),
                    mul(mload(v1), mload(add(v2, 0x40)))
                )
            )
            mstore(
                add(result, 0x40),
                sub(
                    mul(mload(v1), mload(add(v2, 0x20))),
                    mul(mload(add(v1, 0x20)), mload(v2))
                )
            )
        }
    }

    /** @dev linearly interpolate between two vectors (size 12)
     */
    function vector12Lerp(
        int256[12] memory v1,
        int256[12] memory v2,
        int256 ir,
        int256 scaleFactor
    ) internal view returns (int256[12] memory result) {
        int256[12] memory vd = vector12Sub(v2, v1);
        // loop through all 12 items
        assembly {
            let ix
            for {
                let i := 0
            } lt(i, 0xC) {
                // (i < 12)
                i := add(i, 1)
            } {
                /// get index of the next element
                ix := mul(i, 0x20)

                /// store into the result array
                mstore(
                    add(result, ix),
                    add(
                        // v1[i] + (ir * vd[i]) / 1e3
                        mload(add(v1, ix)),
                        sdiv(mul(ir, mload(add(vd, ix))), 1000)
                    )
                )
            }
        }
    }

    /** @dev subtraction between two vectors (size 12)
     */
    function vector12Sub(int256[12] memory v1, int256[12] memory v2)
        internal
        view
        returns (int256[12] memory result)
    {
        // loop through all 12 items
        assembly {
            let ix
            for {
                let i := 0
            } lt(i, 0xC) {
                // (i < 12)
                i := add(i, 1)
            } {
                /// get index of the next element
                ix := mul(i, 0x20)
                /// store into the result array
                mstore(
                    add(result, ix),
                    sub(
                        // v1[ix] - v2[ix]
                        mload(add(v1, ix)),
                        mload(add(v2, ix))
                    )
                )
            }
        }
    }

    /** @dev map a number from one range into another
     */
    function mapRangeToRange(
        int256 num,
        int256 inMin,
        int256 inMax,
        int256 outMin,
        int256 outMax
    ) internal pure returns (int256 res) {
        assembly {
            res := add(
                sdiv(
                    mul(sub(outMax, outMin), sub(num, inMin)),
                    sub(inMax, inMin)
                ),
                outMin
            )
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * @notice Solidity library offering basic trigonometry functions where inputs and outputs are
 * integers. Inputs are specified in radians scaled by 1e18, and similarly outputs are scaled by 1e18.
 *
 * This implementation is based off the Solidity trigonometry library written by Lefteris Karapetsas
 * which can be found here: https://github.com/Sikorkaio/sikorka/blob/e75c91925c914beaedf4841c0336a806f2b5f66d/contracts/trigonometry.sol
 *
 * Compared to Lefteris' implementation, this version makes the following changes:
 *   - Uses a 32 bits instead of 16 bits for improved accuracy
 *   - Updated for Solidity 0.8.x
 *   - Various gas optimizations
 *   - Change inputs/outputs to standard trig format (scaled by 1e18) instead of requiring the
 *     integer format used by the algorithm
 *
 * Lefertis' implementation is based off Dave Dribin's trigint C library
 *     http://www.dribin.org/dave/trigint/
 *
 * Which in turn is based from a now deleted article which can be found in the Wayback Machine:
 *     http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 */

pragma solidity ^0.8.0;

library Trigonometry {
    // Table index into the trigonometric table
    uint256 constant INDEX_WIDTH = 8;
    // Interpolation between successive entries in the table
    uint256 constant INTERP_WIDTH = 16;
    uint256 constant INDEX_OFFSET = 28 - INDEX_WIDTH;
    uint256 constant INTERP_OFFSET = INDEX_OFFSET - INTERP_WIDTH;
    uint32 constant ANGLES_IN_CYCLE = 1073741824;
    uint32 constant QUADRANT_HIGH_MASK = 536870912;
    uint32 constant QUADRANT_LOW_MASK = 268435456;
    uint256 constant SINE_TABLE_SIZE = 256;

    // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
    // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
    uint256 constant PI = 3141592653589793238;
    uint256 constant TWO_PI = 2 * PI;
    uint256 constant PI_OVER_TWO = PI / 2;

    // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
    // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
    // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
    // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
    // 256 defined above)
    uint8 constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
    uint256 constant entry_mask = ((1 << (8 * entry_bytes)) - 1); // mask used to cast bytes32 -> lookup table entry
    bytes constant sin_table =
        hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

    /**
     * @notice Return the sine of a value, specified in radians scaled by 1e18
     * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
     * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
     * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
     * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
     * range of -1 to 1, again scaled by 1e18
     * @param _angle Angle to convert
     * @return Result scaled by 1e18
     */
    function sin(uint256 _angle) internal pure returns (int256) {
        unchecked {
            // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
            // of 0 to 1,073,741,824
            _angle = (ANGLES_IN_CYCLE * (_angle % TWO_PI)) / TWO_PI;

            // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
            // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
            // and the offset is the offset of the bits (in bits) we want to extract. The result is an
            // integer containing _width bits of _value starting at the offset bit
            uint256 interp = (_angle >> INTERP_OFFSET) &
                ((1 << INTERP_WIDTH) - 1);
            uint256 index = (_angle >> INDEX_OFFSET) & ((1 << INDEX_WIDTH) - 1);

            // The lookup table only contains data for one quadrant (since sin is symmetric around both
            // axes), so here we figure out which quadrant we're in, then we lookup the values in the
            // table then modify values accordingly
            bool is_odd_quadrant = (_angle & QUADRANT_LOW_MASK) == 0;
            bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

            if (!is_odd_quadrant) {
                index = SINE_TABLE_SIZE - 1 - index;
            }

            bytes memory table = sin_table;
            // We are looking for two consecutive indices in our lookup table
            // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
            // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
            uint256 offset1_2 = (index + 2) * entry_bytes;

            // This following snippet will function for any entry_bytes <= 15
            uint256 x1_2;
            assembly {
                // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
                x1_2 := mload(add(table, offset1_2))
            }

            // We now read the last two numbers of size entry_bytes from x1_2
            // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
            // therefore: entry_mask = 0xFFFFFFFF

            // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
            // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
            uint256 x1 = (x1_2 >> (8 * entry_bytes)) & entry_mask;
            // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
            uint256 x2 = x1_2 & entry_mask;

            // Approximate angle by interpolating in the table, accounting for the quadrant
            uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
            int256 sine = is_odd_quadrant
                ? int256(x1) + int256(approximation)
                : int256(x2) - int256(approximation);
            if (is_negative_quadrant) {
                sine *= -1;
            }

            // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
            // This can never overflow because sine is bounded by the above values
            return (sine * 1e18) / 2_147_483_647;
        }
    }

    /**
     * @notice Return the cosine of a value, specified in radians scaled by 1e18
     * @dev This is identical to the sin() method, and just computes the value by delegating to the
     * sin() method using the identity cos(x) = sin(x + pi/2)
     * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
     * @param _angle Angle to convert
     * @return Result scaled by 1e18
     */
    function cos(uint256 _angle) internal pure returns (int256) {
        unchecked {
            return sin(_angle + PI_OVER_TWO);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Shackled.sol";

contract XShackled is Shackled {
    constructor() {}

    function xstoreSeedHash(uint256 tokenId) external {
        return super.storeSeedHash(tokenId);
    }

    function x_transferOwnership(address newOwner) external {
        return super._transferOwnership(newOwner);
    }

    function x_beforeTokenTransfer(address from,address to,uint256 tokenId) external {
        return super._beforeTokenTransfer(from,to,tokenId);
    }

    function x_baseURI() external view returns (string memory) {
        return super._baseURI();
    }

    function x_safeTransfer(address from,address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeTransfer(from,to,tokenId,_data);
    }

    function x_exists(uint256 tokenId) external view returns (bool) {
        return super._exists(tokenId);
    }

    function x_isApprovedOrOwner(address spender,uint256 tokenId) external view returns (bool) {
        return super._isApprovedOrOwner(spender,tokenId);
    }

    function x_safeMint(address to,uint256 tokenId) external {
        return super._safeMint(to,tokenId);
    }

    function x_safeMint(address to,uint256 tokenId,bytes calldata _data) external {
        return super._safeMint(to,tokenId,_data);
    }

    function x_mint(address to,uint256 tokenId) external {
        return super._mint(to,tokenId);
    }

    function x_burn(uint256 tokenId) external {
        return super._burn(tokenId);
    }

    function x_transfer(address from,address to,uint256 tokenId) external {
        return super._transfer(from,to,tokenId);
    }

    function x_approve(address to,uint256 tokenId) external {
        return super._approve(to,tokenId);
    }

    function x_setApprovalForAll(address owner,address operator,bool approved) external {
        return super._setApprovalForAll(owner,operator,approved);
    }

    function x_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function x_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledCoords.sol";

contract XShackledCoords {
    constructor() {}

    function xconvertToWorldSpaceWithModelTransform(int256[3][3][] calldata tris,int256 scale,int256[3] calldata position) external view returns (int256[3][] memory) {
        return ShackledCoords.convertToWorldSpaceWithModelTransform(tris,scale,position);
    }

    function xbackfaceCulling(int256[3][3][] calldata trisWorldSpace,int256[3][3][] calldata trisCols) external view returns (int256[3][3][] memory, int256[3][3][] memory) {
        return ShackledCoords.backfaceCulling(trisWorldSpace,trisCols);
    }

    function xconvertToCameraSpaceViaVertexShader(int256[3][] calldata vertsWorldSpace,int256 canvasDim,bool perspCamera) external view returns (int256[3][] memory) {
        return ShackledCoords.convertToCameraSpaceViaVertexShader(vertsWorldSpace,canvasDim,perspCamera);
    }

    function xgetCameraMatrixOrth(int256 canvasDim) external pure returns (int256[4][4][2] memory) {
        return ShackledCoords.getCameraMatrixOrth(canvasDim);
    }

    function xgetCameraMatrixPersp() external pure returns (int256[4][4][2] memory) {
        return ShackledCoords.getCameraMatrixPersp();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledGenesis.sol";

contract XShackledGenesis {
    constructor() {}

    function xgenerateGenesisPiece(bytes32 tokenHash) external view returns (ShackledStructs.RenderParams memory, ShackledStructs.Metadata memory) {
        return ShackledGenesis.generateGenesisPiece(tokenHash);
    }

    function xgenerateGeometryAndColors(bytes32 tokenHash,int256[3] calldata objPosition) external view returns (ShackledGenesis.FacesVertsCols memory, ColorUtils.ColScheme memory, GeomUtils.GeomSpec memory, GeomUtils.GeomVars memory) {
        return ShackledGenesis.generateGeometryAndColors(tokenHash,objPosition);
    }

    function xcreate2dTris(bytes32 tokenHash,GeomUtils.GeomSpec calldata geomSpec) external view returns (int256[3][3][] memory, int256[] memory, int256[] memory) {
        return ShackledGenesis.create2dTris(tokenHash,geomSpec);
    }

    function xprismify(bytes32 tokenHash,int256[3][3][] calldata tris,int256[] calldata zFronts,int256[] calldata zBacks) external view returns (GeomUtils.GeomVars memory) {
        return ShackledGenesis.prismify(tokenHash,tris,zFronts,zBacks);
    }

    function xmakeFacesVertsCols(bytes32 tokenHash,int256[3][3][] calldata tris,GeomUtils.GeomVars calldata geomVars,ColorUtils.ColScheme calldata scheme,int256[3] calldata objPosition) external view returns (ShackledGenesis.FacesVertsCols memory) {
        return ShackledGenesis.makeFacesVertsCols(tokenHash,tris,geomVars,scheme,objPosition);
    }
}

contract XColorUtils {
    constructor() {}

    function xgetColForPrism(bytes32 tokenHash,int256[3][3] calldata triFront,ColorUtils.SubScheme calldata subScheme,int256[3][2] calldata extents) external view returns (int256[3][6] memory) {
        return ColorUtils.getColForPrism(tokenHash,triFront,subScheme,extents);
    }

    function xgetSchemeId(bytes32 tokenHash,int256[2][10] calldata weightings) external view returns (uint256) {
        return ColorUtils.getSchemeId(tokenHash,weightings);
    }

    function xcopyColor(int256[3] calldata c) external view returns (int256[3] memory) {
        return ColorUtils.copyColor(c);
    }

    function xgetScheme(bytes32 tokenHash,int256[3][3][] calldata tris) external view returns (ColorUtils.ColScheme memory) {
        return ColorUtils.getScheme(tokenHash,tris);
    }

    function xhsv2rgb(int256 h,int256 s,int256 v) external view returns (int256[3] memory) {
        return ColorUtils.hsv2rgb(h,s,v);
    }

    function xrgb2hsv(int256 r,int256 g,int256 b) external view returns (int256[3] memory) {
        return ColorUtils.rgb2hsv(r,g,b);
    }

    function xgetJiggle(int256[3] calldata jiggle,bytes32 randomSeed,int256 seedModifier) external view returns (int256[3] memory) {
        return ColorUtils.getJiggle(jiggle,randomSeed,seedModifier);
    }

    function xinArray(uint256[] calldata array,uint256 value) external view returns (bool) {
        return ColorUtils.inArray(array,value);
    }

    function xapplyDirHelp(int256[3][3] calldata triFront,int256[3] calldata colA,int256[3] calldata colB,int256 dirCode,bool isInnerGradient,int256[3][2] calldata extents) external view returns (int256[3][3] memory) {
        return ColorUtils.applyDirHelp(triFront,colA,colB,dirCode,isInnerGradient,extents);
    }

    function xgetOrderedPointIdxsInDir(int256[3][3] calldata tri,int256 dirCode) external view returns (uint256[3] memory) {
        return ColorUtils.getOrderedPointIdxsInDir(tri,dirCode);
    }

    function xinterpColHelp(int256[3] calldata colA,int256[3] calldata colB,int256 low,int256 high,int256 val) external view returns (int256[3] memory) {
        return ColorUtils.interpColHelp(colA,colB,low,high,val);
    }

    function xgetHighlightPrismIdxs(int256[3][3][] calldata tris,bytes32 tokenHash,uint256 nHighlights,int256 varCode,int256 selCode) external view returns (uint256[] memory) {
        return ColorUtils.getHighlightPrismIdxs(tris,tokenHash,nHighlights,varCode,selCode);
    }

    function xgetSortedTrisIdxs(int256[3][3][] calldata tris,uint256 nHighlights,int256 varCode,int256 selCode) external view returns (uint256[] memory) {
        return ColorUtils.getSortedTrisIdxs(tris,nHighlights,varCode,selCode);
    }
}

contract XGeomUtils {
    constructor() {}

    function xgenerateSpec(bytes32 tokenHash) external view returns (GeomUtils.GeomSpec memory) {
        return GeomUtils.generateSpec(tokenHash);
    }

    function xmakeAdjacentTriangles(bytes32 tokenHash,uint256 attemptNum,uint256 refIdx,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec,int256 overrideSideIdx,int256 overrideScale,int256 depth) external view returns (GeomUtils.TriVars memory) {
        return GeomUtils.makeAdjacentTriangles(tokenHash,attemptNum,refIdx,triVars,geomSpec,overrideSideIdx,overrideScale,depth);
    }

    function xmakeVerticallyOppositeTriangles(bytes32 tokenHash,uint256 attemptNum,uint256 refIdx,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec,int256 overrideSideIdx,int256 overrideScale,int256 depth) external view returns (GeomUtils.TriVars memory) {
        return GeomUtils.makeVerticallyOppositeTriangles(tokenHash,attemptNum,refIdx,triVars,geomSpec,overrideSideIdx,overrideScale,depth);
    }

    function xmakeTriVertOpp(int256[3][3] calldata refTri,GeomUtils.GeomSpec calldata geomSpec,int256 sideIdx,int256 scale) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTriVertOpp(refTri,geomSpec,sideIdx,scale);
    }

    function xmakeTriAdjacent(bytes32 tokenHash,GeomUtils.GeomSpec calldata geomSpec,uint256 attemptNum,int256[3][3] calldata refTri,int256 sideIdx,int256 scale,int256 depth) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTriAdjacent(tokenHash,geomSpec,attemptNum,refTri,sideIdx,scale,depth);
    }

    function xmakeTri(int256[3] calldata centre,int256 radius,int256 angle) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTri(centre,radius,angle);
    }

    function xvector3RotateX(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateX(v,deg);
    }

    function xvector3RotateY(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateY(v,deg);
    }

    function xvector3RotateZ(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateZ(v,deg);
    }

    function xtrigHelper(int256 deg) external view returns (int256, int256) {
        return GeomUtils.trigHelper(deg);
    }

    function xgetCenterVec(int256[3][3] calldata tri) external view returns (int256[3] memory) {
        return GeomUtils.getCenterVec(tri);
    }

    function xgetRadiusLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getRadiusLen(tri);
    }

    function xgetSideLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getSideLen(tri);
    }

    function xgetPerpLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getPerpLen(tri);
    }

    function xisTriPointingUp(int256[3][3] calldata tri) external view returns (bool) {
        return GeomUtils.isTriPointingUp(tri);
    }

    function xareTrisClose(int256[3][3] calldata tri1,int256[3][3] calldata tri2) external view returns (bool) {
        return GeomUtils.areTrisClose(tri1,tri2);
    }

    function xareTrisPointsOverlapping(int256[3][3] calldata tri1,int256[3][3] calldata tri2) external view returns (bool) {
        return GeomUtils.areTrisPointsOverlapping(tri1,tri2);
    }

    function xisPointInTri(int256[3][3] calldata tri,int256[3] calldata p) external view returns (bool) {
        return GeomUtils.isPointInTri(tri,p);
    }

    function xisTriOverlappingWithTris(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx) external view returns (bool) {
        return GeomUtils.isTriOverlappingWithTris(tri,tris,nextTriIdx);
    }

    function xisPointCloseToLine(int256[3] calldata p,int256[3] calldata l1,int256[3] calldata l2) external view returns (bool) {
        return GeomUtils.isPointCloseToLine(p,l1,l2);
    }

    function xisTrisPointsCloseToLines(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx) external view returns (bool) {
        return GeomUtils.isTrisPointsCloseToLines(tri,tris,nextTriIdx);
    }

    function xisTriLegal(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx,int256 minTriRad) external view returns (bool) {
        return GeomUtils.isTriLegal(tri,tris,nextTriIdx,minTriRad);
    }

    function xattemptToAddTri(int256[3][3] calldata tri,bytes32 tokenHash,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec) external view returns (bool) {
        return GeomUtils.attemptToAddTri(tri,tokenHash,triVars,geomSpec);
    }

    function xtriRotHelp(int256 axis,int256[3][3] calldata tri,int256 rot) external view returns (int256[3][3] memory) {
        return GeomUtils.triRotHelp(axis,tri,rot);
    }

    function xtriBfHelp(int256 axis,int256[3][3][] calldata trisBack,int256[3][3][] calldata trisFront,int256 rot) external view returns (int256[3][3][] memory, int256[3][3][] memory) {
        return GeomUtils.triBfHelp(axis,trisBack,trisFront,rot);
    }

    function xgetExtents(int256[3][3][] calldata tris) external view returns (int256[3][2] memory) {
        return GeomUtils.getExtents(tris);
    }

    function xcalculateZ(int256[3][3] calldata tri,bytes32 tokenHash,uint256 nextTriIdx,GeomUtils.GeomSpec calldata geomSpec,bool front) external view returns (int256) {
        return GeomUtils.calculateZ(tri,tokenHash,nextTriIdx,geomSpec,front);
    }

    function xgetSpecId(bytes32 tokenHash,int256[2][7] calldata weightings) external view returns (uint256) {
        return GeomUtils.getSpecId(tokenHash,weightings);
    }

    function xrandN(bytes32 randomSeed,string calldata seedModifier,int256 min,int256 max) external view returns (int256) {
        return GeomUtils.randN(randomSeed,seedModifier,min,max);
    }

    function xclipTrisToLength(int256[3][3][] calldata arr,uint256 desiredLen) external view returns (int256[3][3][] memory) {
        return GeomUtils.clipTrisToLength(arr,desiredLen);
    }

    function xclipZsToLength(int256[] calldata arr,uint256 desiredLen) external view returns (int256[] memory) {
        return GeomUtils.clipZsToLength(arr,desiredLen);
    }

    function xcopyTri(int256[3][3] calldata tri) external view returns (int256[3][3] memory) {
        return GeomUtils.copyTri(tri);
    }

    function xcopyTris(int256[3][3][] calldata tris) external view returns (int256[3][3][] memory) {
        return GeomUtils.copyTris(tris);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledMath.sol";

contract XShackledMath {
    constructor() {}

    function xmin(int256 a,int256 b) external pure returns (int256) {
        return ShackledMath.min(a,b);
    }

    function xmax(int256 a,int256 b) external pure returns (int256) {
        return ShackledMath.max(a,b);
    }

    function xmod(int256 n,int256 m) external pure returns (int256) {
        return ShackledMath.mod(n,m);
    }

    function xrandomIdx(bytes32 seedModifier,uint256 n,uint256 m) external pure returns (uint256[] memory) {
        return ShackledMath.randomIdx(seedModifier,n,m);
    }

    function xget2dArray(uint256 m,uint256 q,int256 value) external pure returns (int256[][] memory) {
        return ShackledMath.get2dArray(m,q,value);
    }

    function xabs(int256 x) external pure returns (int256) {
        return ShackledMath.abs(x);
    }

    function xsqrt(int256 y) external pure returns (int256) {
        return ShackledMath.sqrt(y);
    }

    function xhypot(int256 x,int256 y) external pure returns (int256) {
        return ShackledMath.hypot(x,y);
    }

    function xvector3Add(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.vector3Add(v1,v2);
    }

    function xvector3Sub(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.vector3Sub(v1,v2);
    }

    function xvector3MulScalar(int256[3] calldata v,int256 a) external pure returns (int256[3] memory) {
        return ShackledMath.vector3MulScalar(v,a);
    }

    function xvector3DivScalar(int256[3] calldata v,int256 a) external pure returns (int256[3] memory) {
        return ShackledMath.vector3DivScalar(v,a);
    }

    function xvector3Len(int256[3] calldata v) external pure returns (int256) {
        return ShackledMath.vector3Len(v);
    }

    function xvector3NormX(int256[3] calldata v,int256 fidelity) external pure returns (int256[3] memory) {
        return ShackledMath.vector3NormX(v,fidelity);
    }

    function xvector3Dot(int256[3] calldata v1,int256[3] calldata v2) external view returns (int256) {
        return ShackledMath.vector3Dot(v1,v2);
    }

    function xcrossProduct(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.crossProduct(v1,v2);
    }

    function xvector12Lerp(int256[12] calldata v1,int256[12] calldata v2,int256 ir,int256 scaleFactor) external view returns (int256[12] memory) {
        return ShackledMath.vector12Lerp(v1,v2,ir,scaleFactor);
    }

    function xvector12Sub(int256[12] calldata v1,int256[12] calldata v2) external view returns (int256[12] memory) {
        return ShackledMath.vector12Sub(v1,v2);
    }

    function xmapRangeToRange(int256 num,int256 inMin,int256 inMax,int256 outMin,int256 outMax) external pure returns (int256) {
        return ShackledMath.mapRangeToRange(num,inMin,inMax,outMin,outMax);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledRasteriser.sol";

contract XShackledRasteriser {
    constructor() {}

    function xinitialiseFragments(int256[3][3][] calldata trisCameraSpace,int256[3][3][] calldata trisWorldSpace,int256[3][3][] calldata trisCols,int256 canvasDim) external view returns (int256[12][3][] memory) {
        return ShackledRasteriser.initialiseFragments(trisCameraSpace,trisWorldSpace,trisCols,canvasDim);
    }

    function xrasterise(int256[12][3][] calldata trisFragments,int256 canvasDim,bool wireframe) external view returns (int256[12][] memory) {
        return ShackledRasteriser.rasterise(trisFragments,canvasDim,wireframe);
    }

    function xrunBresenhamsAlgorithm(int256[12] calldata f1,int256[12] calldata f2,int256 canvasDim,int256[12][] calldata bresTriFragments,uint256 nextBresTriFragmentIx) external view returns (int256[12][] memory, uint256) {
        return ShackledRasteriser.runBresenhamsAlgorithm(f1,f2,canvasDim,bresTriFragments,nextBresTriFragmentIx);
    }

    function xbresenhamsInner(ShackledRasteriser.BresenhamsVars calldata vars,int256 mag,int256[12] calldata fa,int256[12] calldata fb,int256 canvasDim,int256[12][] calldata bresTriFragments,uint256 nextBresTriFragmentIx) external view returns (int256[12][] memory, uint256) {
        return ShackledRasteriser.bresenhamsInner(vars,mag,fa,fb,canvasDim,bresTriFragments,nextBresTriFragmentIx);
    }

    function xrunScanline(int256[12][] calldata bresTriFragments,int256[12][] calldata fragments,uint256 nextFragmentsIx,int256 canvasDim) external view returns (int256[12][] memory, uint256) {
        return ShackledRasteriser.runScanline(bresTriFragments,fragments,nextFragmentsIx,canvasDim);
    }

    function xgetRowFragIndices(int256[12][] calldata bresTriFragments,int256 canvasDim) external view returns (int256[][] memory, uint256[] memory) {
        return ShackledRasteriser.getRowFragIndices(bresTriFragments,canvasDim);
    }

    function xdepthTesting(int256[12][] calldata fragments,int256 canvasDim) external view returns (int256[12][] memory) {
        return ShackledRasteriser.depthTesting(fragments,canvasDim);
    }

    function xlightScene(int256[12][] calldata fragments,ShackledStructs.LightingParams calldata lp) external view returns (int256[12][] memory) {
        return ShackledRasteriser.lightScene(fragments,lp);
    }

    function xcalculateSpecular(int256 lightSpecPower,int256 hnDot,int256 fidelity,uint256 inverseShininess) external pure returns (int256) {
        return ShackledRasteriser.calculateSpecular(lightSpecPower,hnDot,fidelity,inverseShininess);
    }

    function xgetBackground(int256 canvasDim,int256[3][2] calldata backgroundColor) external view returns (int256[5][] memory) {
        return ShackledRasteriser.getBackground(canvasDim,backgroundColor);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledRenderer.sol";

contract XShackledRenderer {
    constructor() {}

    function xrender(ShackledStructs.RenderParams calldata renderParams,int256 canvasDim,bool returnSVG) external view returns (string memory) {
        return ShackledRenderer.render(renderParams,canvasDim,returnSVG);
    }

    function xprepareGeometryForRender(ShackledStructs.RenderParams calldata renderParams,int256 canvasDim) external view returns (int256[12][3][] memory) {
        return ShackledRenderer.prepareGeometryForRender(renderParams,canvasDim);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledStructs.sol";

contract XShackledStructs {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledUtils.sol";

contract XShackledUtils {
    constructor() {}

    function xflattenTris(int256[3][3][] calldata tris) external pure returns (int256[3][] memory) {
        return ShackledUtils.flattenTris(tris);
    }

    function xunflattenVertsToTris(int256[3][] calldata verts) external pure returns (int256[3][3][] memory) {
        return ShackledUtils.unflattenVertsToTris(verts);
    }

    function xclipArray12ToLength(int256[12][] calldata arr,uint256 desiredLen) external pure returns (int256[12][] memory) {
        return ShackledUtils.clipArray12ToLength(arr,desiredLen);
    }

    function xuint2str(uint256 _i) external pure returns (string memory) {
        return ShackledUtils.uint2str(_i);
    }

    function xgetHex(uint256 _i) external pure returns (bytes memory) {
        return ShackledUtils.getHex(_i);
    }

    function xgetSVGContainer(string calldata encodedBitmap,int256 canvasDim,uint256 outputHeight,uint256 outputWidth) external view returns (string memory) {
        return ShackledUtils.getSVGContainer(encodedBitmap,canvasDim,outputHeight,outputWidth);
    }

    function xgetAttributes(ShackledStructs.Metadata calldata metadata) external pure returns (bytes memory) {
        return ShackledUtils.getAttributes(metadata);
    }

    function xgetEncodedMetadata(string calldata image,ShackledStructs.Metadata calldata metadata,uint256 tokenId) external view returns (string memory) {
        return ShackledUtils.getEncodedMetadata(image,metadata,tokenId);
    }

    function xgetEncodedBitmap(int256[12][] calldata fragments,int256[5][] calldata background,int256 canvasDim,bool invert) external view returns (string memory) {
        return ShackledUtils.getEncodedBitmap(fragments,background,canvasDim,invert);
    }

    function xwriteFragmentsToBytesArray(int256[12][] calldata fragments,bytes calldata bytesArray,uint256 canvasDimUnsigned,bool invert) external pure returns (bytes memory) {
        return ShackledUtils.writeFragmentsToBytesArray(fragments,bytesArray,canvasDimUnsigned,invert);
    }

    function xwriteBackgroundToBytesArray(int256[5][] calldata background,bytes calldata bytesArray,uint256 canvasDimUnsigned,bool invert) external pure returns (bytes memory) {
        return ShackledUtils.writeBackgroundToBytesArray(background,bytesArray,canvasDimUnsigned,invert);
    }
}

contract XBase64 {
    constructor() {}

    function xencode(bytes calldata data) external view returns (string memory) {
        return Base64.encode(data);
    }
}

contract XBytesUtils {
    constructor() {}

    function xchar(bytes1 b) external view returns (bytes1) {
        return BytesUtils.char(b);
    }

    function xbytes32string(bytes32 b32) external view returns (string memory) {
        return BytesUtils.bytes32string(b32);
    }

    function xhach(string calldata value) external view returns (string memory) {
        return BytesUtils.hach(value);
    }

    function xMergeBytes(bytes calldata a,bytes calldata b) external pure returns (bytes memory) {
        return BytesUtils.MergeBytes(a,b);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Trigonometry.sol";

contract XTrigonometry {
    constructor() {}

    function xsin(uint256 _angle) external pure returns (int256) {
        return Trigonometry.sin(_angle);
    }

    function xcos(uint256 _angle) external pure returns (int256) {
        return Trigonometry.cos(_angle);
    }
}