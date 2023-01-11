// SPDX-License-Identifier: The Unlicense
pragma solidity =0.8.17;

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

library libAncestors {

    uint256 public constant INITIAL_PRICE = 1 ether; 

    function getDepth(uint256 parentId) internal pure returns (uint256 depth) {
        unchecked{
            while (parentId != 0) {
                depth++;
                parentId >>= 1;
            }
        }
        return depth;
    }

    function getParent(uint256 id) internal pure returns(uint256 parentId) {
        return uint256(id >> 1);
    }

    function getFullAncestors(uint256 id) internal pure returns (uint256[] memory) {
        uint256 depth = getDepth(getParent(id));
        uint256[] memory ancestorIds = new uint256[](depth);

        uint256 ancestor = id;

        unchecked{
            for(uint256 i = 0; i<depth; i++) {
                ancestor >>= 1; 
                ancestorIds[i] = ancestor;
            }
        }

        return ancestorIds;
    }

    function calculatePrice(uint256 parentId) internal pure returns (uint256 price) {
        price = INITIAL_PRICE;

        uint256 depth = getDepth(parentId);
        
        unchecked{
            for(uint256 i=0; i<depth; ++i) {
                price = price * 9_900_000_000_000_000 / 10_000_000_000_000_000;
            }
        }
    }

}

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

library libUri {

    string constant DEFS = '<defs><filter id="carved" color-interpolation-filters="sRGB"><feTurbulence baseFrequency="0.15 0.275" numOctaves="5" seed="50" /><feColorMatrix result="colorSplit" values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 2 0 " /><feComposite in="SourceGraphic" in2="colorSplit" operator="in" /><feMorphology operator="dilate" radius="0.65" result="dilated" /><feTurbulence baseFrequency="0.05 0.09" numOctaves="7" seed="25" type="fractalNoise" /><feGaussianBlur result="edges" stdDeviation="1" /><feDisplacementMap in="dilated" in2="edges" result="blurredEdges1" scale="5" xChannelSelector="R" yChannelSelector="G" /><feFlood flood-color="rgb(255,255,255)" /><feComposite in2="blurredEdges1" k1="0.7" k3="0.7" operator="arithmetic" result="blurredEdges2" /><feComposite in="blurredEdges2" in2="SourceAlpha" k1="1" k2="1" operator="arithmetic" result="blurredEdges3" /><feBlend in="blurredEdges3" in2="blurredEdges3" mode="multiply" result="fbSourceGraphic" /><feColorMatrix in="fbSourceGraphic" result="fbSourceGraphicAlpha" values="0 0 0 -1 0 0 0 0 -1 0 0 0 0 -1 0 0 0 0 1 0" /><feGaussianBlur in="fbSourceGraphic" result="blur" stdDeviation="0.6" /><feComposite in="fbSourceGraphic" in2="blur" operator="in" result="composite1" /><feComposite in="composite1" in2="composite1" k2="1" operator="in" result="composite2" /></filter><filter id="roughpaper" x="0" y="0" width="1" height="1"><feTurbulence baseFrequency="0.35 0.2" numOctaves="5" result="noise" type="fractalNoise" /><feDiffuseLighting lighting-color="#E0BFA0" in="noise" surfaceScale="1"><feDistantLight azimuth="45" elevation="60" /></feDiffuseLighting><feComposite operator="in"></feComposite><feMorphology operator="dilate" radius="0.65" result="dilated"></feMorphology><feTurbulence basefrequency="0.05 0.09" numoctaves="7" seed="25" type="fractalNoise"></feTurbulence><feGaussianBlur result="edges" stddeviation="1"></feGaussianBlur><feDisplacementMap in="dilated" in2="edges" scale="10" xchannelselector="R" ychannelselector="G"></feDisplacementMap></filter></defs>';
    string constant STATIC_BACKGROUND = unicode'<g><rect width="100%" height="100%" filter="url(#carved)" fill="#7d6a59"/><rect x="1%" y="1%" width="98%" height="98%" filter="url(#roughpaper)"/><g filter="url(#carved)" fill="#7d6a59"><text x="40" y="75" font-size="60">𓅃 Ramses Scamses 𓁚</text><line x1="40" y1="90" x2="610" y2="90" stroke="#7d6a59" stroke-width="4"/><polygon points="325,245 585,465 65,465" fill="#9c8876"/><ellipse cx= "325" cy= "250" rx= "15" ry= "15" fill= "gold"/></g></g>';

    function _getNthBit(uint256 input, uint256 idx) private pure returns (bool) {
        uint8 shifted = uint8(input * 2**(idx-1));

        return (input & shifted) != 0;

    }

    function _getCult(uint256 id) private pure returns (string memory cult) {
        uint256 valDepth = libAncestors.getDepth(id);

        cult = _getNthBit(id,2)? "Horus" : "Osiris";
        if(valDepth>2){
            cult = _getNthBit(id,3)? string.concat(cult, " at Thebes") : string.concat(cult, " at Giza");
            if(valDepth>3){
                cult = _getNthBit(id,4)? string.concat("Ramses sect of ", cult) : string.concat("Nefertiti sect of ", cult);
                if(valDepth<8){
                    cult = valDepth<6? string.concat("High Priest of the ", cult) : string.concat("Priest of the ", cult);
                }
            }
            if(valDepth>12){
                    cult = string.concat("Lower ", cult);
            }
        }
    }

    function _formatETHValue(uint256 val, uint256 precision) private pure returns (string memory) {
        require(precision < 17);
        uint256 whole = val / 10**18;
        uint256 decimal = (val - (whole * 10**18)) / 10**(17-precision);

        return string.concat(
            LibString.toString(whole),
            ".",
            LibString.toString(decimal)
        );
    }

    function _translateGameState(uint8 gameState) private pure returns (string memory) {
        string memory _gameState;

        if(gameState == 0) {
            _gameState = unicode'𓀛𓉴𓈶𓇀𓃈';
        } else if(gameState == 1) {
            _gameState = unicode"𓍝𓈞𓆋𓁿";
        } if(gameState == 2) {
            _gameState = unicode"𓁲𓈬𓂶";
        } else {
            _gameState = unicode"𓁨𓈝𓆣";
        }

        return string.concat(
            '<text x="40" y="220" font-size="30">Game State: ',
            _gameState,
            '</text>'
        );
    }
    
    function _getText(uint256 id, uint256 accrued, uint8 gameState) private pure returns (string memory) {

        return string.concat(
            '<g filter="url(#carved)" fill="#7d6a59">',
            string.concat(
                '<text x="40" y="130" font-size="30">Cult: ',
                _getCult(id),
                '</text>'
            ),
            string.concat(
                '<text x="40" y="160" font-size="30">Ancestor: ',
                LibString.toString(id>>1),
                '</text>'
            ),
            string.concat(
                '<text x="40" y="190" font-size="30">Accrued Loot: ',
                _formatETHValue(accrued, 6),
                '</text>'
            ),
            _translateGameState(gameState)
        );

    }

    function _getXCoordinates(uint256 id) private pure returns (uint256[] memory) {
        uint256 valDepth = libAncestors.getDepth(id);

        uint256[] memory xCoordinates = new uint256[](valDepth);
        // we start the top dot with the midpoint
        xCoordinates[0] = 325;

        if(valDepth > 1) {
            xCoordinates[1] = (id) % 2 == 0? xCoordinates[0]-40: xCoordinates[0]+40;
            if(valDepth >2){
                unchecked {
                    for(uint256 i = 2; i<valDepth; i++) {
                        xCoordinates[i] = (id>>(valDepth-i-1)) % 2 == 0? xCoordinates[i-1]-12: xCoordinates[i-1]+12;
                    }
                }
            }
        }
        return xCoordinates;
    }

    function _getNodes(uint256 id) private pure returns (string memory pyramidText) {
        uint256[] memory xCoordinates = _getXCoordinates(id);

        unchecked {
            for(uint256 i = 1; i<xCoordinates.length; i++) {
                pyramidText = string.concat(
                    pyramidText,
                    '<ellipse rx= "',
                    i == xCoordinates.length-1? '7' : '5',
                    '" ry= "',
                    i == xCoordinates.length-1? '7' : '5',
                    '" cx="',
                    LibString.toString(xCoordinates[i]),
                    '" cy="',
                    LibString.toString(270 + i*10),
                    '" fill="#',
                    i == xCoordinates.length-1? '03d3fc' : '696969',
                    '"/>'
                );
            }
        }
        
        return string.concat(
            pyramidText,          
            '</g>'
        );
    }

    function getRawUri(uint256 id, uint256 accrued, uint8 gameState) internal pure returns (string memory) {

        return string.concat(
            '<svg width="650" height="500" xmlns="http://www.w3.org/2000/svg"><style>text{font-family: Georgia}</style>',
            DEFS,
            STATIC_BACKGROUND,
            _getText(id, accrued, gameState),
            _getNodes(id),
            '</svg>'
        );
    }

    function _getAttributes(uint256 id, uint256 accrued, uint256 totalBalance) private pure returns (string memory) {

        return string.concat(
            ', "attributes": [{"trait_type": "Cult", "value": "',
            _getCult(id),
            '"}, {"trait_type": "Level", "value": "',
            LibString.toString(libAncestors.getDepth(id)),
            '"}, {"display_type": "number", "trait_type": "Loot Accrued", "value": ',
            _formatETHValue(accrued, 6),
            ', "max_value": ',
            _formatETHValue(totalBalance, 6),
            '}]'
        );

    }

    function getTokenUri(uint256 id, uint256 accrued, uint8 gameState, uint256 totalBalance) internal pure returns (string memory) {

        string memory encodedSVG = Base64.encode(
            bytes(string.concat(
                '<svg width="650" height="500" xmlns="http://www.w3.org/2000/svg"><style>text{font-family: Georgia}</style>',
                DEFS,
                STATIC_BACKGROUND,
                _getText(id, accrued, gameState),
                _getNodes(id),
                '</svg>'
            ))
        );

        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                bytes(string.concat(
                        '{"name": "Ramses Scamses #',
                        LibString.toString(id),
                        '" , "description": "Multi-level Monument - The pyramid scheme game. We are sad to report that our pharaoh King Tutanconman has passed away. Luckily he will enter the afterlife as long as we carefully follow the death ritual he left behind.", "image" :"data:image/svg+xml;base64,',
                        encodedSVG,
                        '" ',
                        _getAttributes(id, accrued, totalBalance),
                        '}'
                ))
            )
        );

    }

}

/// @notice Library to encode strings in Base64.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory result) {
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Write the length of the string.
                mstore(result, encodedLength)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, "ghijklmnopqrstuvwxyz0123456789+/")

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                // prettier-ignore
                for {} iszero(eq(ptr, end)) {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 characters. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                }

                // Offset `ptr` and pad with '='. We can simply write over the end.
                // The `byte(...)` part is equivalent to `[0, 2, 1][dataLength % 3]`.
                mstore(sub(ptr, byte(mod(dataLength, 3), "\x00\x02\x01")), "==")

                // Allocate the memory for the string.
                // Add 31 and mask with `not(0x1f)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(0x1f)))
            }
        }
    }
}

library Hieroglyphs {
    // len = 1062
    string public constant allGlyphs = unicode"𓀀𓀁𓀂𓀃𓀄𓀅𓀆𓀇𓀈𓀉𓀊𓀋𓀌𓀍𓀎𓀏𓀐𓀑𓀒𓀓𓀔𓀕𓀖𓀗𓀘𓀙𓀚𓀛𓀜𓀝𓀞𓀟𓀠𓀡𓀢𓀣𓀤𓀥𓀦𓀧𓀨𓀩𓀪𓀫𓀬𓀭𓀮𓀯𓀰𓀱𓀲𓀳𓀴𓀵𓀶𓀷𓀸𓀹𓀺𓀻𓀼𓀽𓀾𓀿𓁀𓁁𓁂𓁃𓁄𓁅𓁆𓁇𓁈𓁉𓁊𓁋𓁌𓁍𓁎𓁏𓁐𓁑𓁒𓁓𓁔𓁕𓁖𓁗𓁘𓁙𓁚𓁛𓁜𓁝𓁞𓁟𓁠𓁡𓁢𓁣𓁤𓁥𓁦𓁧𓁨𓁩𓁪𓁫𓁬𓁭𓁮𓁯𓁰𓁱𓁲𓁳𓁴𓁵𓁶𓁷𓁸𓁹𓁺𓁻𓁼𓁽𓁾𓁿𓂀𓂁𓂂𓂃𓂄𓂅𓂆𓂇𓂈𓂉𓂊𓂋𓂌𓂍𓂎𓂏𓂐𓂑𓂒𓂓𓂔𓂕𓂖𓂗𓂘𓂙𓂚𓂛𓂜𓂝𓂞𓂟𓂠𓂡𓂢𓂣𓂤𓂥𓂦𓂧𓂨𓂩𓂪𓂫𓂬𓂭𓂷𓂸𓂹𓂺𓂻𓂼𓂽𓂾𓂿𓃀𓃁𓃂𓃃𓃄𓃅𓃆𓃇𓃈𓃉𓃊𓃋𓃌𓃍𓃎𓃏𓃐𓃑𓃒𓃓𓃔𓃕𓃖𓃗𓃘𓃙𓃚𓃛𓃜𓃝𓃞𓃟𓃠𓃡𓃢𓃣𓃤𓃥𓃦𓃧𓃨𓃩𓃪𓃫𓃬𓃭𓃮𓃯𓃰𓃱𓃲𓃳𓃴𓃵𓃶𓃷𓃸𓃹𓃺𓃻𓃼𓃽𓃾𓃿𓄀𓄁𓄂𓄃𓄄𓄅𓄆𓄇𓄈𓄉𓄊𓄋𓄌𓄍𓄎𓄏𓄐𓄑𓄒𓄓𓄔𓄕𓄖𓄗𓄘𓄙𓄚𓄛𓄜𓄝𓄞𓄟𓄠𓄡𓄢𓄣𓄤𓄥𓄦𓄧𓄨𓄩𓄪𓄫𓄬𓄭𓄮𓄯𓄰𓄱𓄲𓄳𓄴𓄵𓄶𓄷𓄸𓄹𓄺𓄻𓄼𓄽𓄾𓄿𓅀𓅁𓅂𓅃𓅄𓅅𓅆𓅇𓅈𓅉𓅊𓅋𓅌𓅍𓅎𓅏𓅐𓅑𓅒𓅓𓅔𓅕𓅖𓅗𓅘𓅙𓅚𓅛𓅜𓅝𓅞𓅟𓅠𓅡𓅢𓅣𓅤𓅥𓅦𓅧𓅨𓅩𓅪𓅫𓅬𓅭𓅮𓅯𓅰𓅱𓅲𓅳𓅴𓅵𓅶𓅷𓅸𓅹𓅺𓅻𓅼𓅽𓅾𓅿𓆀𓆁𓆂𓆃𓆄𓆅𓆆𓆇𓆈𓆉𓆊𓆋𓆌𓆍𓆎𓆏𓆐𓆑𓆒𓆓𓆔𓆕𓆖𓆗𓆘𓆙𓆚𓆛𓆜𓆝𓆞𓆟𓆠𓆡𓆢𓆣𓆤𓆥𓆦𓆧𓆨𓆩𓆪𓆫𓆬𓆭𓆮𓆯𓆰𓆱𓆲𓆳𓆴𓆵𓆶𓆷𓆸𓆹𓆺𓆻𓆼𓆽𓆾𓆿𓇀𓇁𓇂𓇃𓇄𓇅𓇆𓇇𓇈𓇉𓇊𓇋𓇌𓇍𓇎𓇏𓇐𓇑𓇒𓇓𓇔𓇕𓇖𓇗𓇘𓇙𓇚𓇛𓇜𓇝𓇞𓇟𓇠𓇡𓇢𓇣𓇤𓇥𓇦𓇧𓇨𓇩𓇪𓇫𓇬𓇭𓇮𓇯𓇰𓇱𓇲𓇳𓇴𓇵𓇶𓇷𓇸𓇹𓇺𓇻𓇼𓇽𓇾𓇿𓈀𓈁𓈂𓈃𓈄𓈅𓈆𓈇𓈈𓈉𓈊𓈋𓈌𓈍𓈎𓈏𓈐𓈑𓈒𓈓𓈔𓈕𓈖𓈗𓈘𓈙𓈚𓈛𓈜𓈝𓈞𓈟𓈠𓈡𓈢𓈣𓈤𓈥𓈦𓈧𓈨𓈩𓈪𓈫𓈬𓈭𓈮𓈯𓈰𓈱𓈲𓈳𓈴𓈵𓈶𓈷𓈸𓈹𓈺𓈻𓈼𓈽𓈾𓈿𓉀𓉁𓉂𓉃𓉄𓉅𓉆𓉇𓉈𓉉𓉊𓉋𓉌𓉍𓉎𓉏𓉐𓉑𓉒𓉓𓉔𓉕𓉖𓉗𓉘𓉙𓉚𓉛𓉜𓉝𓉞𓉟𓉠𓉡𓉢𓉣𓉤𓉥𓉦𓉧𓉨𓉩𓉪𓉫𓉬𓉭𓉮𓉯𓉰𓉱𓉲𓉳𓉴𓉵𓉶𓉷𓉸𓉹𓉺𓉻𓉼𓉽𓉾𓉿𓊀𓊁𓊂𓊃𓊄𓊅𓊆𓊇𓊈𓊉𓊊𓊋𓊌𓊍𓊎𓊏𓊐𓊑𓊒𓊓𓊔𓊕𓊖𓊗𓊘𓊙𓊚𓊛𓊜𓊝𓊞𓊟𓊠𓊡𓊢𓊣𓊤𓊥𓊦𓊧𓊨𓊩𓊪𓊫𓊬𓊭𓊮𓊯𓊰𓊱𓊲𓊳𓊴𓊵𓊶𓊷𓊸𓊹𓊺𓊻𓊼𓊽𓊾𓊿𓋀𓋁𓋂𓋃𓋄𓋅𓋆𓋇𓋈𓋉𓋊𓋋𓋌𓋍𓋎𓋏𓋐𓋑𓋒𓋓𓋔𓋕𓋖𓋗𓋘𓋙𓋚𓋛𓋜𓋝𓋞𓋟𓋠𓋡𓋢𓋣𓋤𓋥𓋦𓋧𓋨𓋩𓋪𓋫𓋬𓋭𓋮𓋯𓋰𓋱𓋲𓋳𓋴𓋵𓋶𓋷𓋸𓋹𓋺𓋻𓋼𓋽𓋾𓋿𓌀𓌁𓌂𓌃𓌄𓌅𓌆𓌇𓌈𓌉𓌊𓌋𓌌𓌍𓌎𓌏𓌐𓌑𓌒𓌓𓌔𓌕𓌖𓌗𓌘𓌙𓌚𓌛𓌜𓌝𓌞𓌟𓌠𓌡𓌢𓌣𓌤𓌥𓌦𓌧𓌨𓌩𓌪𓌫𓌬𓌭𓌮𓌯𓌰𓌱𓌲𓌳𓌴𓌵𓌶𓌷𓌸𓌹𓌺𓌻𓌼𓌽𓌾𓌿𓍀𓍁𓍂𓍃𓍄𓍅𓍆𓍇𓍈𓍉𓍊𓍋𓍌𓍍𓍎𓍏𓍐𓍑𓍒𓍓𓍔𓍕𓍖𓍗𓍘𓍙𓍚𓍛𓍜𓍝𓍞𓍟𓍠𓍡𓍢𓍣𓍤𓍥𓍦𓍧𓍨𓍩𓍪𓍫𓍬𓍭𓍮𓍯𓍰𓍱𓍲𓍳𓍴𓍵𓍶𓍷𓍸𓍹𓍺𓍻𓍼𓍽𓍾𓍿𓎀𓎁𓎂𓎃𓎄𓎅𓎆𓎇𓎈𓎉𓎊𓎋𓎌𓎍𓎎𓎏𓎐𓎑𓎒𓎓𓎔𓎕𓎖𓎗𓎘𓎙𓎚𓎛𓎜𓎝𓎞𓎟𓎠𓎡𓎢𓎣𓎤𓎥𓎦𓎧𓎨𓎩𓎪𓎫𓎬𓎭𓎮𓎯𓎰𓎱𓎲𓎳𓎴𓎵𓎶𓎷𓎸𓎹𓎺𓎻𓎼𓎽𓎾𓎿𓏀𓏁𓏂𓏃𓏄𓏅𓏆𓏇𓏈𓏉𓏊𓏋𓏌𓏍𓏎𓏏𓏐𓏑𓏒𓏓𓏔𓏕𓏖𓏗𓏘𓏙𓏚𓏛𓏜𓏝𓏞𓏟𓏠𓏡𓏢𓏣𓏤𓏥𓏦𓏧𓏨𓏩𓏪𓏫𓏬𓏭𓏮𓏯𓏰𓏱𓏲𓏳𓏴𓏵𓏶𓏷𓏸𓏹𓏺𓏻𓏼𓏽𓏾𓏿𓐀𓐁𓐂𓐃𓐄𓐅𓐆𓐇𓐈𓐉𓐊𓐋𓐌𓐍𓐎𓐏𓐐𓐑𓐒𓐓𓐔𓐕𓐖𓐗𓐘𓐙𓐚𓐛𓐜𓐝𓐞𓐟𓐠𓐡𓐢𓐣𓐤𓐥𓐦𓐧𓐨𓐩𓐪𓐫𓐬𓐭𓐮";

    function getSingle(uint256 index) internal pure returns (string memory) {
        bytes memory fullList = bytes(allGlyphs);

        return string(abi.encodePacked(fullList[index*4],fullList[index*4+1],fullList[index*4+2],fullList[index*4+3]));
    }

}

contract dummyRamses is ERC721("dummy Ramses", "RAMSES") {

    //getTokenUri(uint256 id, uint256 accrued, uint8 gameState)
    uint8 gameState;

    mapping(uint256 => uint256) public accrued;

    function mint(uint256 id) public {
        _mint(msg.sender, id);
    }

    function setAccrued(uint256 id, uint256 amt) public {
        accrued[id] = amt;
    }

    function setGameState(uint8 newState) public {
        gameState = newState;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        //@todo put all logic into dedicated lib
        return libUri.getTokenUri(id, accrued[id], gameState, 696969.1234567 ether);
    }

    constructor(){
        _mint(msg.sender, 1);
        _mint(msg.sender, 2);
        _mint(msg.sender, 321343);

        accrued[1]      = 123.456789 ether;
        accrued[2]      = 420.000690 ether;
        accrued[321343] = 123.0000001 ether;
    }

}